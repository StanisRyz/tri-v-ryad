extends Node

## Stage 69.1: Yandex Games SDK bridge. This is the ONLY script in the
## project allowed to call JavaScriptBridge.eval / create_callback /
## get_interface("window"). Everything else (including WebYandexPlatform)
## must go through the public methods/signals below.
##
## The Web page hosting the game must load the Yandex SDK and set
## window.ysdk / window.ysdkReady BEFORE the game starts making SDK calls.
## See docs/YANDEX_PLATFORM.md for the exact shell requirements.

signal yandex_sdk_ready

signal rewarded_ad_opened
signal rewarded_ad_rewarded
signal rewarded_ad_closed(was_shown: bool)
signal rewarded_ad_error(message: String)

signal fullscreen_ad_opened
signal fullscreen_ad_closed(was_shown: bool)
signal fullscreen_ad_error(message: String)

signal payment_purchase_started(product_id: String)
signal payment_purchase_success(product_id: String, purchase_token: String)
signal payment_purchase_cancelled(product_id: String)
signal payment_purchase_error(product_id: String, message: String)
signal payment_consume_success(purchase_token: String)
signal payment_consume_error(purchase_token: String, message: String)
signal payment_catalog_loaded(products: Array)
signal payment_catalog_error(message: String)
signal unprocessed_purchase_found(product_id: String, purchase_token: String)
signal unprocessed_purchase_check_completed
signal unprocessed_purchase_check_error(message: String)

const SDK_POLL_INTERVAL := 0.5
const SDK_POLL_TIMEOUT := 20.0
const REWARDED_AD_TIMEOUT := 30.0
const FULLSCREEN_AD_TIMEOUT := 20.0
const CATALOG_LOAD_TIMEOUT := 15.0

var _is_web := false
var _sdk_ready := false
var _ad_in_progress := false
var _payment_catalog_cache: Dictionary = {}
var _purchase_platform_id := ""

var _sdk_poll_timer: Timer
var _sdk_poll_elapsed := 0.0
var _rewarded_timeout_timer: Timer
var _rewarded_was_rewarded := false
var _fullscreen_timeout_timer: Timer
var _catalog_timeout_timer: Timer

# Kept as instance vars so the JavaScriptObject callbacks stay referenced
# for the lifetime of the in-flight JS call.
var _cb_rewarded_open: JavaScriptObject
var _cb_rewarded_rewarded: JavaScriptObject
var _cb_rewarded_close: JavaScriptObject
var _cb_rewarded_error: JavaScriptObject
var _cb_fullscreen_open: JavaScriptObject
var _cb_fullscreen_close: JavaScriptObject
var _cb_fullscreen_error: JavaScriptObject
var _cb_purchase_success: JavaScriptObject
var _cb_purchase_error: JavaScriptObject
var _cb_consume_success: JavaScriptObject
var _cb_consume_error: JavaScriptObject
var _cb_catalog_success: JavaScriptObject
var _cb_catalog_error: JavaScriptObject
var _cb_unprocessed_found: JavaScriptObject
var _cb_unprocessed_done: JavaScriptObject
var _cb_unprocessed_error: JavaScriptObject


func _ready() -> void:
	_is_web = OS.has_feature("web")
	if not _is_web:
		return
	_start_sdk_ready_poll()


## Safe runtime debug state for diagnostics/manual inspection.
func get_debug_state() -> Dictionary:
	return {
		"is_web": _is_web,
		"sdk_ready": _sdk_ready,
		"ad_in_progress": _ad_in_progress,
		"catalog_product_count": _payment_catalog_cache.size(),
	}


func is_sdk_ready() -> bool:
	return _sdk_ready


func is_ad_in_progress() -> bool:
	return _ad_in_progress


# ---------------------------------------------------------------------------
# SDK readiness
# ---------------------------------------------------------------------------


func refresh_yandex_sdk_ready() -> bool:
	if not _is_web:
		return false
	var result = _eval_js("(function(){ return (typeof window.ysdkReady !== 'undefined' && window.ysdkReady === true && typeof window.ysdk !== 'undefined') ? 1 : 0; })()")
	if _to_bool(result) and not _sdk_ready:
		_sdk_ready = true
		yandex_sdk_ready.emit()
	return _sdk_ready


func _start_sdk_ready_poll() -> void:
	_sdk_poll_elapsed = 0.0
	_sdk_poll_timer = Timer.new()
	_sdk_poll_timer.wait_time = SDK_POLL_INTERVAL
	_sdk_poll_timer.one_shot = false
	add_child(_sdk_poll_timer)
	_sdk_poll_timer.timeout.connect(_on_sdk_poll_tick)
	_sdk_poll_timer.start()


func _on_sdk_poll_tick() -> void:
	if refresh_yandex_sdk_ready():
		_sdk_poll_timer.stop()
		return
	_sdk_poll_elapsed += SDK_POLL_INTERVAL
	if _sdk_poll_elapsed >= SDK_POLL_TIMEOUT:
		_sdk_poll_timer.stop()


func get_yandex_language() -> String:
	if not _is_web or not _sdk_ready:
		return ""
	var result = _eval_js("(function(){ try { return window.ysdk.environment.i18n.lang; } catch(e) { return ''; } })()")
	return _to_string_safe(result)


# ---------------------------------------------------------------------------
# Lifecycle (LoadingAPI / GameplayAPI)
# ---------------------------------------------------------------------------


func game_ready() -> void:
	if not _is_web or not _sdk_ready:
		return
	_eval_js("try { window.ysdk.features.LoadingAPI.ready(); } catch(e) {}")


func gameplay_start(_attempt: int = 0) -> void:
	if not _is_web or not _sdk_ready:
		return
	_eval_js("try { window.ysdk.features.GameplayAPI.start(); } catch(e) {}")


func gameplay_stop() -> void:
	if not _is_web or not _sdk_ready:
		return
	_eval_js("try { window.ysdk.features.GameplayAPI.stop(); } catch(e) {}")


# ---------------------------------------------------------------------------
# Rewarded ad
# ---------------------------------------------------------------------------


func show_rewarded_ad(_placement_id: String = "") -> void:
	if not _is_web or not _sdk_ready:
		rewarded_ad_error.emit("sdk_not_ready")
		return
	if _ad_in_progress:
		rewarded_ad_error.emit("ad_already_in_progress")
		return
	_ad_in_progress = true
	_rewarded_was_rewarded = false
	_cb_rewarded_open = JavaScriptBridge.create_callback(_on_rewarded_open)
	_cb_rewarded_rewarded = JavaScriptBridge.create_callback(_on_rewarded_rewarded)
	_cb_rewarded_close = JavaScriptBridge.create_callback(_on_rewarded_closed)
	_cb_rewarded_error = JavaScriptBridge.create_callback(_on_rewarded_error)
	var window := JavaScriptBridge.get_interface("window")
	window.__godot_rewarded_open = _cb_rewarded_open
	window.__godot_rewarded_rewarded = _cb_rewarded_rewarded
	window.__godot_rewarded_close = _cb_rewarded_close
	window.__godot_rewarded_error = _cb_rewarded_error
	_eval_js("""
		try {
			window.ysdk.adv.showRewardedVideo({
				callbacks: {
					onOpen: function() { window.__godot_rewarded_open(); },
					onRewarded: function() { window.__godot_rewarded_rewarded(); },
					onClose: function() { window.__godot_rewarded_close(); },
					onError: function(e) { window.__godot_rewarded_error(String(e)); }
				}
			});
		} catch (e) {
			window.__godot_rewarded_error(String(e));
		}
	""")
	_start_rewarded_timeout()


func _on_rewarded_open(_args: Array) -> void:
	rewarded_ad_opened.emit()


func _on_rewarded_rewarded(_args: Array) -> void:
	_rewarded_was_rewarded = true
	rewarded_ad_rewarded.emit()


func _on_rewarded_closed(_args: Array) -> void:
	_stop_rewarded_timeout()
	_ad_in_progress = false
	rewarded_ad_closed.emit(_rewarded_was_rewarded)


func _on_rewarded_error(args: Array) -> void:
	_stop_rewarded_timeout()
	_ad_in_progress = false
	var message := _to_string_safe(args[0]) if args.size() > 0 else "unknown_error"
	rewarded_ad_error.emit(message)


func _start_rewarded_timeout() -> void:
	_stop_rewarded_timeout()
	_rewarded_timeout_timer = Timer.new()
	_rewarded_timeout_timer.wait_time = REWARDED_AD_TIMEOUT
	_rewarded_timeout_timer.one_shot = true
	add_child(_rewarded_timeout_timer)
	_rewarded_timeout_timer.timeout.connect(_on_rewarded_timeout)
	_rewarded_timeout_timer.start()


func _on_rewarded_timeout() -> void:
	if not _ad_in_progress:
		return
	_ad_in_progress = false
	rewarded_ad_error.emit("timeout")


func _stop_rewarded_timeout() -> void:
	if _rewarded_timeout_timer != null:
		_rewarded_timeout_timer.stop()
		_rewarded_timeout_timer.queue_free()
		_rewarded_timeout_timer = null


# ---------------------------------------------------------------------------
# Fullscreen (interstitial) ad
# ---------------------------------------------------------------------------


func show_fullscreen_ad(_placement_id: String = "") -> void:
	if not _is_web or not _sdk_ready:
		fullscreen_ad_error.emit("sdk_not_ready")
		return
	if _ad_in_progress:
		fullscreen_ad_error.emit("ad_already_in_progress")
		return
	_ad_in_progress = true
	_cb_fullscreen_open = JavaScriptBridge.create_callback(_on_fullscreen_open)
	_cb_fullscreen_close = JavaScriptBridge.create_callback(_on_fullscreen_closed)
	_cb_fullscreen_error = JavaScriptBridge.create_callback(_on_fullscreen_error)
	var window := JavaScriptBridge.get_interface("window")
	window.__godot_fullscreen_open = _cb_fullscreen_open
	window.__godot_fullscreen_close = _cb_fullscreen_close
	window.__godot_fullscreen_error = _cb_fullscreen_error
	_eval_js("""
		try {
			window.ysdk.adv.showFullscreenAdv({
				callbacks: {
					onOpen: function() { window.__godot_fullscreen_open(); },
					onClose: function(wasShown) { window.__godot_fullscreen_close(!!wasShown); },
					onError: function(e) { window.__godot_fullscreen_error(String(e)); }
				}
			});
		} catch (e) {
			window.__godot_fullscreen_error(String(e));
		}
	""")
	_start_fullscreen_timeout()


func _on_fullscreen_open(_args: Array) -> void:
	fullscreen_ad_opened.emit()


func _on_fullscreen_closed(args: Array) -> void:
	_stop_fullscreen_timeout()
	_ad_in_progress = false
	var was_shown := _to_bool(args[0]) if args.size() > 0 else false
	fullscreen_ad_closed.emit(was_shown)


func _on_fullscreen_error(args: Array) -> void:
	_stop_fullscreen_timeout()
	_ad_in_progress = false
	var message := _to_string_safe(args[0]) if args.size() > 0 else "unknown_error"
	fullscreen_ad_error.emit(message)


func _start_fullscreen_timeout() -> void:
	_stop_fullscreen_timeout()
	_fullscreen_timeout_timer = Timer.new()
	_fullscreen_timeout_timer.wait_time = FULLSCREEN_AD_TIMEOUT
	_fullscreen_timeout_timer.one_shot = true
	add_child(_fullscreen_timeout_timer)
	_fullscreen_timeout_timer.timeout.connect(_on_fullscreen_timeout)
	_fullscreen_timeout_timer.start()


func _on_fullscreen_timeout() -> void:
	if not _ad_in_progress:
		return
	_ad_in_progress = false
	fullscreen_ad_error.emit("timeout")


func _stop_fullscreen_timeout() -> void:
	if _fullscreen_timeout_timer != null:
		_fullscreen_timeout_timer.stop()
		_fullscreen_timeout_timer.queue_free()
		_fullscreen_timeout_timer = null


# ---------------------------------------------------------------------------
# Payments
# ---------------------------------------------------------------------------

## Stage 69.3: every getPayments() call below intentionally omits
## `{ signed: true }`. Signed mode is for server-side purchase verification;
## this project has no purchase-verification server, so it stays in plain
## client-side mode, which is what returns usable `productID`/`purchaseToken`
## fields directly to `purchase()`/`getPurchases()` callers here.


func purchase_product(platform_product_id: String, _local_product_id: String = "") -> void:
	if not _is_web or not _sdk_ready:
		payment_purchase_error.emit(platform_product_id, "sdk_not_ready")
		return
	_purchase_platform_id = platform_product_id
	payment_purchase_started.emit(platform_product_id)
	_cb_purchase_success = JavaScriptBridge.create_callback(_on_purchase_success)
	_cb_purchase_error = JavaScriptBridge.create_callback(_on_purchase_error)
	var window := JavaScriptBridge.get_interface("window")
	window.__godot_purchase_success = _cb_purchase_success
	window.__godot_purchase_error = _cb_purchase_error
	var escaped_id := platform_product_id.replace("'", "")
	var js := "try { window.ysdk.getPayments().then(function(payments){ return payments.purchase({ id: '%s' }); }).then(function(purchase){ window.__godot_purchase_success(purchase.productID || '%s', purchase.purchaseToken || ''); }).catch(function(e){ var msg = (e && e.code === 'PURCHASE_CANCELED') ? 'cancelled' : String(e); window.__godot_purchase_error('%s', msg); }); } catch (e) { window.__godot_purchase_error('%s', String(e)); }" % [escaped_id, escaped_id, escaped_id, escaped_id]
	_eval_js(js)


func _on_purchase_success(args: Array) -> void:
	var product_id := _to_string_safe(args[0]) if args.size() > 0 else _purchase_platform_id
	var token := _to_string_safe(args[1]) if args.size() > 1 else ""
	payment_purchase_success.emit(product_id, token)


func _on_purchase_error(args: Array) -> void:
	var product_id := _to_string_safe(args[0]) if args.size() > 0 else _purchase_platform_id
	var message := _to_string_safe(args[1]) if args.size() > 1 else "unknown_error"
	if message == "cancelled":
		payment_purchase_cancelled.emit(product_id)
	else:
		payment_purchase_error.emit(product_id, message)


func consume_purchase(purchase_token: String) -> void:
	if purchase_token == "":
		payment_consume_error.emit(purchase_token, "invalid_token")
		return
	if not _is_web or not _sdk_ready:
		payment_consume_error.emit(purchase_token, "sdk_not_ready")
		return
	_cb_consume_success = JavaScriptBridge.create_callback(_on_consume_success)
	_cb_consume_error = JavaScriptBridge.create_callback(_on_consume_error)
	var window := JavaScriptBridge.get_interface("window")
	window.__godot_consume_success = _cb_consume_success
	window.__godot_consume_error = _cb_consume_error
	var escaped_token := purchase_token.replace("'", "")
	var js := "try { window.ysdk.getPayments().then(function(payments){ return payments.consumePurchase('%s'); }).then(function(){ window.__godot_consume_success('%s'); }).catch(function(e){ window.__godot_consume_error('%s', String(e)); }); } catch (e) { window.__godot_consume_error('%s', String(e)); }" % [escaped_token, escaped_token, escaped_token, escaped_token]
	_eval_js(js)


func _on_consume_success(args: Array) -> void:
	var token := _to_string_safe(args[0]) if args.size() > 0 else ""
	payment_consume_success.emit(token)


func _on_consume_error(args: Array) -> void:
	var token := _to_string_safe(args[0]) if args.size() > 0 else ""
	var message := _to_string_safe(args[1]) if args.size() > 1 else "unknown_error"
	payment_consume_error.emit(token, message)


func check_unprocessed_purchases() -> void:
	if not _is_web or not _sdk_ready:
		unprocessed_purchase_check_completed.emit()
		return
	_cb_unprocessed_found = JavaScriptBridge.create_callback(_on_unprocessed_purchase_found)
	_cb_unprocessed_done = JavaScriptBridge.create_callback(_on_unprocessed_purchase_done)
	_cb_unprocessed_error = JavaScriptBridge.create_callback(_on_unprocessed_purchase_error)
	var window := JavaScriptBridge.get_interface("window")
	window.__godot_unprocessed_found = _cb_unprocessed_found
	window.__godot_unprocessed_done = _cb_unprocessed_done
	window.__godot_unprocessed_error = _cb_unprocessed_error
	_eval_js("""
		try {
			window.ysdk.getPayments().then(function(payments){
				return payments.getPurchases();
			}).then(function(purchases){
				(purchases || []).forEach(function(p){
					window.__godot_unprocessed_found(p.productID || '', p.purchaseToken || '');
				});
				window.__godot_unprocessed_done();
			}).catch(function(e){
				window.__godot_unprocessed_error(String(e));
			});
		} catch (e) {
			window.__godot_unprocessed_error(String(e));
		}
	""")


func _on_unprocessed_purchase_found(args: Array) -> void:
	var product_id := _to_string_safe(args[0]) if args.size() > 0 else ""
	var token := _to_string_safe(args[1]) if args.size() > 1 else ""
	unprocessed_purchase_found.emit(product_id, token)


func _on_unprocessed_purchase_done(_args: Array) -> void:
	unprocessed_purchase_check_completed.emit()


func _on_unprocessed_purchase_error(args: Array) -> void:
	var message := _to_string_safe(args[0]) if args.size() > 0 else "unknown_error"
	unprocessed_purchase_check_error.emit(message)


func load_payment_catalog() -> void:
	if not _is_web or not _sdk_ready:
		payment_catalog_error.emit("sdk_not_ready")
		return
	_cb_catalog_success = JavaScriptBridge.create_callback(_on_catalog_loaded)
	_cb_catalog_error = JavaScriptBridge.create_callback(_on_catalog_error)
	var window := JavaScriptBridge.get_interface("window")
	window.__godot_catalog_success = _cb_catalog_success
	window.__godot_catalog_error = _cb_catalog_error
	_eval_js("""
		try {
			window.ysdk.getPayments().then(function(payments){
				return payments.getCatalog();
			}).then(function(products){
				window.__godot_catalog_success(JSON.stringify(products || []));
			}).catch(function(e){
				window.__godot_catalog_error(String(e));
			});
		} catch (e) {
			window.__godot_catalog_error(String(e));
		}
	""")
	_start_catalog_timeout()


func _on_catalog_loaded(args: Array) -> void:
	_stop_catalog_timeout()
	var json_text := _to_string_safe(args[0]) if args.size() > 0 else "[]"
	var parsed = JSON.parse_string(json_text)
	var products: Array = parsed if parsed is Array else []
	_payment_catalog_cache.clear()
	for product in products:
		if typeof(product) != TYPE_DICTIONARY:
			continue
		var product_id := _to_string_safe(product.get("id", ""))
		if product_id == "":
			continue
		_payment_catalog_cache[product_id] = {
			"id": product_id,
			"title": _to_string_safe(product.get("title", "")),
			"description": _to_string_safe(product.get("description", "")),
			"price": _to_string_safe(product.get("price", "")),
			"priceValue": _to_string_safe(product.get("priceValue", "")),
			"priceCurrencyCode": _to_string_safe(product.get("priceCurrencyCode", "")),
			"priceCurrencyImage": product.get("priceCurrencyImage", {}),
		}
	payment_catalog_loaded.emit(_payment_catalog_cache.values())


func _on_catalog_error(args: Array) -> void:
	_stop_catalog_timeout()
	_payment_catalog_cache.clear()
	var message := _to_string_safe(args[0]) if args.size() > 0 else "unknown_error"
	payment_catalog_error.emit(message)


func _start_catalog_timeout() -> void:
	_stop_catalog_timeout()
	_catalog_timeout_timer = Timer.new()
	_catalog_timeout_timer.wait_time = CATALOG_LOAD_TIMEOUT
	_catalog_timeout_timer.one_shot = true
	add_child(_catalog_timeout_timer)
	_catalog_timeout_timer.timeout.connect(_on_catalog_timeout)
	_catalog_timeout_timer.start()


func _on_catalog_timeout() -> void:
	payment_catalog_error.emit("timeout")


func _stop_catalog_timeout() -> void:
	if _catalog_timeout_timer != null:
		_catalog_timeout_timer.stop()
		_catalog_timeout_timer.queue_free()
		_catalog_timeout_timer = null


func get_cached_payment_catalog() -> Dictionary:
	return _payment_catalog_cache.duplicate(true)


func get_catalog_product(local_product_id: String) -> Dictionary:
	return _payment_catalog_cache.get(local_product_id, {})


# ---------------------------------------------------------------------------
# JavaScriptBridge helpers (the only place these APIs are touched)
# ---------------------------------------------------------------------------


func _eval_js(code: String) -> Variant:
	if not _is_web:
		return null
	return JavaScriptBridge.eval(code, true)


func _to_bool(value) -> bool:
	if value == null:
		return false
	match typeof(value):
		TYPE_BOOL:
			return value
		TYPE_INT, TYPE_FLOAT:
			return value != 0
		TYPE_STRING:
			return value == "true" or value == "1"
		_:
			return bool(value)


func _to_string_safe(value) -> String:
	if value == null:
		return ""
	return str(value)

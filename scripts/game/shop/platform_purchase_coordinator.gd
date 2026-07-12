extends RefCounted
class_name PlatformPurchaseCoordinator

## Stage 69.3.1: single owner of the Yandex payment purchase lifecycle from
## the moment Platform reports an outcome through to a confirmed consume.
## ShopScreen only starts a purchase (Platform.purchase_product()) and reacts
## to this coordinator's UI-facing signals; neither ShopScreen nor App apply
## rewards, mark tokens, or call Platform.consume_purchase() themselves
## anymore — see ProgressManager.apply_platform_purchase_atomic().

signal purchase_reward_granted(item_id: String)
signal purchase_already_granted(item_id: String)
signal purchase_cancelled(item_id: String)
signal purchase_failed(item_id: String, message: String)
signal purchase_consume_pending(item_id: String)
signal purchase_completed(item_id: String)

const PLATFORM_KEY_YANDEX := "yandex"

var _shop_catalog
var _progress_manager
var _platform
var _active_foreground_item_id := ""

## Stage 69.3.1: dedupes consume requests within one session — a token stays
## in here from the moment consume is requested until its terminal signal
## (payment_consume_success/error) arrives, so the same token is never asked
## to consume twice concurrently, and retry_pending_consume_tokens() can't
## spin on a request that's already in flight.
var _consume_in_flight: Dictionary = {}

## Stage 69.4: tokens whose purchase was foreground (a screen was actively
## waiting on it) at the moment consume was requested, kept until that
## token's consume reaches a terminal signal — independent of
## _active_foreground_item_id, which is cleared immediately after starting
## consume so the UI can unlock right away. Without this separate record,
## LocalDebugPlatform's synchronous consume (which resolves before
## _active_foreground_item_id is cleared) could emit purchase_completed,
## while a real Yandex async consume (which always resolves after) never
## could — this makes both paths behave the same.
var _foreground_consume_tokens: Dictionary = {}


func _init(shop_catalog = null, progress_manager = null) -> void:
	_shop_catalog = shop_catalog
	_progress_manager = progress_manager


func set_shop_catalog(shop_catalog) -> void:
	_shop_catalog = shop_catalog


func set_progress_manager(progress_manager) -> void:
	_progress_manager = progress_manager


## Connects to Platform's payment signals. Idempotent — safe to call more
## than once (e.g. if both App and a screen hold a reference and call it).
func connect_platform(platform) -> void:
	if platform == null:
		return
	_platform = platform
	if not platform.payment_purchase_success.is_connected(_on_payment_purchase_success):
		platform.payment_purchase_success.connect(_on_payment_purchase_success)
	if not platform.payment_purchase_cancelled.is_connected(_on_payment_purchase_cancelled):
		platform.payment_purchase_cancelled.connect(_on_payment_purchase_cancelled)
	if not platform.payment_purchase_error.is_connected(_on_payment_purchase_error):
		platform.payment_purchase_error.connect(_on_payment_purchase_error)
	if not platform.payment_consume_success.is_connected(_on_payment_consume_success):
		platform.payment_consume_success.connect(_on_payment_consume_success)
	if not platform.payment_consume_error.is_connected(_on_payment_consume_error):
		platform.payment_consume_error.connect(_on_payment_consume_error)
	if not platform.unprocessed_purchase_found.is_connected(_on_unprocessed_purchase_found):
		platform.unprocessed_purchase_found.connect(_on_unprocessed_purchase_found)


## Marks item_id as the purchase a screen is actively waiting on, so the
## UI-facing signals above only fire for that item — a restored/background
## purchase for a different item (or one found by check_unprocessed_purchases()
## with no screen watching) stays silent, matching "show feedback only for
## active foreground purchases".
func start_foreground_purchase(item_id: String) -> void:
	_active_foreground_item_id = item_id


func clear_foreground_purchase() -> void:
	_active_foreground_item_id = ""


## Attempts every token still recorded as granted-but-unconfirmed. Intended
## to run once after platform bootstrap; _consume_in_flight already prevents
## a token from being requested twice concurrently within the session.
func retry_pending_consume_tokens() -> void:
	if _progress_manager == null:
		return
	var pending: Dictionary = _progress_manager.get_pending_consume_tokens()
	for token in pending.keys():
		_request_consume(str(token))


func _on_payment_purchase_success(product_id: String, purchase_token: String) -> void:
	var item = _resolve_item(product_id)
	if item == null:
		# Unknown product id: never grant or consume blind.
		return
	var result: Dictionary = _progress_manager.apply_platform_purchase_atomic(item, purchase_token, product_id)
	_handle_grant_result(result, item.item_id, purchase_token)


func _on_unprocessed_purchase_found(product_id: String, purchase_token: String) -> void:
	var item = _resolve_item(product_id)
	if item == null:
		return
	var result: Dictionary = _progress_manager.apply_platform_purchase_atomic(item, purchase_token, product_id)
	_handle_grant_result(result, item.item_id, purchase_token)


func _on_payment_purchase_cancelled(product_id: String) -> void:
	var item_id := _resolve_item_id(product_id)
	if item_id != "" and item_id == _active_foreground_item_id:
		purchase_cancelled.emit(item_id)
	_clear_foreground_if_matches(item_id)


func _on_payment_purchase_error(product_id: String, message: String) -> void:
	var item_id := _resolve_item_id(product_id)
	if item_id != "" and item_id == _active_foreground_item_id:
		purchase_failed.emit(item_id, message)
	_clear_foreground_if_matches(item_id)


func _on_payment_consume_success(purchase_token: String) -> void:
	_consume_in_flight.erase(purchase_token)
	var was_foreground := _foreground_consume_tokens.has(purchase_token)
	_foreground_consume_tokens.erase(purchase_token)
	if _progress_manager == null:
		return
	var entry: Dictionary = _progress_manager.get_pending_consume_tokens().get(purchase_token, {})
	var item_id := str(entry.get("item_id", ""))
	_progress_manager.remove_pending_consume_token(purchase_token)
	# was_foreground records that some screen was actively waiting on this
	# purchase when consume started; if that screen has since closed, its
	# signal connections were freed with it (ScreenRouter.change_screen()),
	# so emitting here is safe even with nothing left listening.
	if item_id != "" and was_foreground:
		purchase_completed.emit(item_id)


## Consume failed — the token stays in pending_consume_tokens (nothing to
## undo, the reward was already granted and saved) so retry_pending_consume_tokens()
## can try again on the next launch, or the next time the same purchase is
## reported by check_unprocessed_purchases().
func _on_payment_consume_error(purchase_token: String, _message: String) -> void:
	_consume_in_flight.erase(purchase_token)
	_foreground_consume_tokens.erase(purchase_token)


## Note on ordering: _request_consume() can — for LocalDebugPlatform, which
## resolves synchronously — trigger _on_payment_consume_success() before
## this function returns. Every "will be foreground" signal, and recording
## the token into _foreground_consume_tokens, therefore happens BEFORE
## _request_consume() is called, so both a synchronous and an async consume
## resolve to the same signal order: reward_granted/already_granted ->
## consume_pending -> (sync or later async) completed.
func _handle_grant_result(result: Dictionary, item_id: String, purchase_token: String) -> void:
	var status := str(result.get("status", ""))
	var is_foreground := item_id == _active_foreground_item_id
	match status:
		"granted":
			if is_foreground:
				purchase_reward_granted.emit(item_id)
				purchase_consume_pending.emit(item_id)
				_foreground_consume_tokens[purchase_token] = item_id
			_request_consume(purchase_token)
			_clear_foreground_if_matches(item_id)
		"already_granted":
			if is_foreground:
				purchase_already_granted.emit(item_id)
				purchase_consume_pending.emit(item_id)
				_foreground_consume_tokens[purchase_token] = item_id
			_request_consume(purchase_token)
			_clear_foreground_if_matches(item_id)
		_:
			if is_foreground:
				purchase_failed.emit(item_id, status)
			_clear_foreground_if_matches(item_id)


func _request_consume(purchase_token: String) -> void:
	if purchase_token == "" or _consume_in_flight.has(purchase_token):
		return
	_consume_in_flight[purchase_token] = true
	if _platform != null:
		_platform.consume_purchase(purchase_token)


func _resolve_item(product_id: String):
	if _shop_catalog == null or product_id == "":
		return null
	return _shop_catalog.get_item_by_platform_product_id(PLATFORM_KEY_YANDEX, product_id)


func _resolve_item_id(product_id: String) -> String:
	var item = _resolve_item(product_id)
	return item.item_id if item != null else ""


func _clear_foreground_if_matches(item_id: String) -> void:
	if item_id != "" and _active_foreground_item_id == item_id:
		_active_foreground_item_id = ""

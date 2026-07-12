extends PlatformServices

## Stage 69.1: Web/Yandex adapter. Delegates every call to the YandexBridge
## autoload and forwards its signals. Contains no raw JavaScriptBridge calls
## itself — YandexBridge is the only script allowed to touch that API.

var _bridge: Node


func _init() -> void:
	_bridge = Engine.get_main_loop().root.get_node_or_null("/root/YandexBridge")
	if _bridge == null:
		return
	_bridge.yandex_sdk_ready.connect(func(): sdk_ready.emit())
	_bridge.rewarded_ad_opened.connect(func(): rewarded_ad_opened.emit())
	_bridge.rewarded_ad_rewarded.connect(func(): rewarded_ad_rewarded.emit())
	_bridge.rewarded_ad_closed.connect(func(was_shown): rewarded_ad_closed.emit(was_shown))
	_bridge.rewarded_ad_error.connect(func(message): rewarded_ad_error.emit(message))
	_bridge.fullscreen_ad_opened.connect(func(): fullscreen_ad_opened.emit())
	_bridge.fullscreen_ad_closed.connect(func(was_shown): fullscreen_ad_closed.emit(was_shown))
	_bridge.fullscreen_ad_error.connect(func(message): fullscreen_ad_error.emit(message))
	_bridge.payment_purchase_started.connect(func(product_id): payment_purchase_started.emit(product_id))
	_bridge.payment_purchase_success.connect(func(product_id, token): payment_purchase_success.emit(product_id, token))
	_bridge.payment_purchase_cancelled.connect(func(product_id): payment_purchase_cancelled.emit(product_id))
	_bridge.payment_purchase_error.connect(func(product_id, message): payment_purchase_error.emit(product_id, message))
	_bridge.payment_catalog_loaded.connect(func(products): payment_catalog_loaded.emit(products))
	_bridge.payment_catalog_error.connect(func(message): payment_catalog_error.emit(message))
	_bridge.unprocessed_purchase_found.connect(func(product_id, token): unprocessed_purchase_found.emit(product_id, token))
	_bridge.unprocessed_purchase_check_completed.connect(func(): unprocessed_purchase_check_completed.emit())
	_bridge.unprocessed_purchase_check_error.connect(func(message): unprocessed_purchase_check_error.emit(message))


func game_ready() -> void:
	if _bridge != null:
		_bridge.game_ready()


func gameplay_start(attempt: int = 0) -> void:
	if _bridge != null:
		_bridge.gameplay_start(attempt)


func gameplay_stop() -> void:
	if _bridge != null:
		_bridge.gameplay_stop()


func refresh_platform_ready() -> bool:
	return _bridge.refresh_yandex_sdk_ready() if _bridge != null else false


func get_platform_key() -> String:
	return "yandex"


func get_platform_language() -> String:
	return _bridge.get_yandex_language() if _bridge != null else ""


func show_rewarded_ad(placement_id: String = "") -> void:
	if _bridge != null:
		_bridge.show_rewarded_ad(placement_id)
	else:
		rewarded_ad_error.emit("bridge_unavailable")


func show_fullscreen_ad(placement_id: String = "") -> void:
	if _bridge != null:
		_bridge.show_fullscreen_ad(placement_id)
	else:
		fullscreen_ad_error.emit("bridge_unavailable")


func purchase_product(platform_product_id: String, local_product_id: String = "") -> void:
	if _bridge != null:
		_bridge.purchase_product(platform_product_id, local_product_id)
	else:
		payment_purchase_error.emit(platform_product_id, "bridge_unavailable")


func consume_purchase(purchase_token: String) -> void:
	if _bridge != null:
		_bridge.consume_purchase(purchase_token)


func check_unprocessed_purchases() -> void:
	if _bridge != null:
		_bridge.check_unprocessed_purchases()
	else:
		unprocessed_purchase_check_completed.emit()


func load_payment_catalog() -> void:
	if _bridge != null:
		_bridge.load_payment_catalog()
	else:
		payment_catalog_error.emit("bridge_unavailable")


func get_cached_payment_catalog() -> Dictionary:
	return _bridge.get_cached_payment_catalog() if _bridge != null else {}


func get_catalog_product(local_product_id: String) -> Dictionary:
	return _bridge.get_catalog_product(local_product_id) if _bridge != null else {}


func is_ad_in_progress() -> bool:
	return _bridge.is_ad_in_progress() if _bridge != null else false

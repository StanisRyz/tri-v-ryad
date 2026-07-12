extends Node

## Stage 69.1: unified platform entry point. All game code (screens, shop,
## ads, localization, future cloud save) must call Platform, never
## YandexBridge or JavaScriptBridge directly. Platform picks WebYandexPlatform
## on Web exports and LocalDebugPlatform everywhere else, and forwards every
## PlatformServices signal so callers don't care which one is active.

signal sdk_ready
signal platform_language_changed(language_code: String)

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

signal cloud_save_loaded(data: Dictionary)
signal cloud_save_load_error(message: String)
signal cloud_save_completed
signal cloud_save_error(message: String)

const WEB_YANDEX_PLATFORM_SCRIPT := preload("res://scripts/platform/WebYandexPlatform.gd")
const LOCAL_DEBUG_PLATFORM_SCRIPT := preload("res://scripts/platform/LocalDebugPlatform.gd")

var _impl: PlatformServices


func _ready() -> void:
	_impl = WEB_YANDEX_PLATFORM_SCRIPT.new() if OS.has_feature("web") else LOCAL_DEBUG_PLATFORM_SCRIPT.new()
	_impl.sdk_ready.connect(func(): sdk_ready.emit())
	_impl.sdk_ready.connect(sync_language_to_localization)
	_impl.rewarded_ad_opened.connect(func(): rewarded_ad_opened.emit())
	_impl.rewarded_ad_rewarded.connect(func(): rewarded_ad_rewarded.emit())
	_impl.rewarded_ad_closed.connect(func(was_shown): rewarded_ad_closed.emit(was_shown))
	_impl.rewarded_ad_error.connect(func(message): rewarded_ad_error.emit(message))
	_impl.fullscreen_ad_opened.connect(func(): fullscreen_ad_opened.emit())
	_impl.fullscreen_ad_closed.connect(func(was_shown): fullscreen_ad_closed.emit(was_shown))
	_impl.fullscreen_ad_error.connect(func(message): fullscreen_ad_error.emit(message))
	_impl.payment_purchase_started.connect(func(product_id): payment_purchase_started.emit(product_id))
	_impl.payment_purchase_success.connect(func(product_id, token): payment_purchase_success.emit(product_id, token))
	_impl.payment_purchase_cancelled.connect(func(product_id): payment_purchase_cancelled.emit(product_id))
	_impl.payment_purchase_error.connect(func(product_id, message): payment_purchase_error.emit(product_id, message))
	_impl.payment_consume_success.connect(func(purchase_token): payment_consume_success.emit(purchase_token))
	_impl.payment_consume_error.connect(func(purchase_token, message): payment_consume_error.emit(purchase_token, message))
	_impl.payment_catalog_loaded.connect(func(products): payment_catalog_loaded.emit(products))
	_impl.payment_catalog_error.connect(func(message): payment_catalog_error.emit(message))
	_impl.unprocessed_purchase_found.connect(func(product_id, token): unprocessed_purchase_found.emit(product_id, token))
	_impl.unprocessed_purchase_check_completed.connect(func(): unprocessed_purchase_check_completed.emit())
	_impl.unprocessed_purchase_check_error.connect(func(message): unprocessed_purchase_check_error.emit(message))
	_impl.cloud_save_loaded.connect(func(data): cloud_save_loaded.emit(data))
	_impl.cloud_save_load_error.connect(func(message): cloud_save_load_error.emit(message))
	_impl.cloud_save_completed.connect(func(): cloud_save_completed.emit())
	_impl.cloud_save_error.connect(func(message): cloud_save_error.emit(message))


func game_ready() -> void:
	_impl.game_ready()


func gameplay_start(attempt: int = 0) -> void:
	_impl.gameplay_start(attempt)


func gameplay_stop() -> void:
	_impl.gameplay_stop()


func refresh_platform_ready() -> bool:
	return _impl.refresh_platform_ready()


func get_platform_key() -> String:
	return _impl.get_platform_key()


func get_platform_language() -> String:
	return _impl.get_platform_language()


func show_rewarded_ad(placement_id: String = "") -> void:
	_impl.show_rewarded_ad(placement_id)


func show_fullscreen_ad(placement_id: String = "") -> void:
	_impl.show_fullscreen_ad(placement_id)


func purchase_product(platform_product_id: String, local_product_id: String = "") -> void:
	_impl.purchase_product(platform_product_id, local_product_id)


func consume_purchase(purchase_token: String) -> void:
	_impl.consume_purchase(purchase_token)


func check_unprocessed_purchases() -> void:
	_impl.check_unprocessed_purchases()


func load_payment_catalog() -> void:
	_impl.load_payment_catalog()


func get_cached_payment_catalog() -> Dictionary:
	return _impl.get_cached_payment_catalog()


func get_catalog_product(local_product_id: String) -> Dictionary:
	return _impl.get_catalog_product(local_product_id)


func is_ad_in_progress() -> bool:
	return _impl.is_ad_in_progress()


func is_cloud_save_available() -> bool:
	return _impl.is_cloud_save_available()


func load_cloud_save() -> void:
	_impl.load_cloud_save()


func save_cloud_save(data: Dictionary, flush: bool = false) -> void:
	_impl.save_cloud_save(data, flush)


## Stage 69.1: refreshes Platform's language from the active implementation
## and applies it to LocalizationManager if a supported language is returned.
## Called once at startup and again whenever the Yandex SDK becomes ready
## (its language is only known once window.ysdk.environment is available).
func sync_language_to_localization() -> void:
	var language := get_platform_language()
	if language == "":
		return
	var localization_manager := get_node_or_null("/root/LocalizationManager")
	if localization_manager != null and localization_manager.has_method("set_language"):
		localization_manager.set_language(language)
	platform_language_changed.emit(language)

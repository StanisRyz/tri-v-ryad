class_name PlatformServices
extends RefCounted

## Stage 69.1: common platform interface. Game code (screens, shop, ads,
## localization, save) must only ever call the `Platform` autoload, which
## holds an instance of a PlatformServices subclass (WebYandexPlatform or
## LocalDebugPlatform). This base class defines the full interface and fails
## safely everywhere so callers never need to null-check or branch on which
## platform implementation is active.

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

## Optional cloud save placeholders. No stage currently implements cloud
## save; these signals exist so future stages have a stable place to hook
## into without another autoload/interface change.
signal cloud_save_loaded(data: Dictionary)
signal cloud_save_load_error(message: String)
signal cloud_save_completed
signal cloud_save_error(message: String)


func game_ready() -> void:
	pass


func gameplay_start(_attempt: int = 0) -> void:
	pass


func gameplay_stop() -> void:
	pass


func refresh_platform_ready() -> bool:
	return false


func get_platform_key() -> String:
	return "base"


func get_platform_language() -> String:
	return "en"


func show_rewarded_ad(_placement_id: String = "") -> void:
	rewarded_ad_error.emit("not_supported")


func show_fullscreen_ad(_placement_id: String = "") -> void:
	fullscreen_ad_error.emit("not_supported")


func purchase_product(platform_product_id: String, _local_product_id: String = "") -> void:
	payment_purchase_error.emit(platform_product_id, "not_supported")


func consume_purchase(purchase_token: String) -> void:
	payment_consume_error.emit(purchase_token, "not_supported")


func check_unprocessed_purchases() -> void:
	unprocessed_purchase_check_completed.emit()


func load_payment_catalog() -> void:
	payment_catalog_error.emit("not_supported")


func get_cached_payment_catalog() -> Dictionary:
	return {}


func get_catalog_product(_local_product_id: String) -> Dictionary:
	return {}


func is_ad_in_progress() -> bool:
	return false


## Optional cloud save placeholders (not implemented by any subclass yet).
func load_cloud_save() -> void:
	cloud_save_load_error.emit("not_supported")


func save_cloud_save(_data: Dictionary) -> void:
	cloud_save_error.emit("not_supported")

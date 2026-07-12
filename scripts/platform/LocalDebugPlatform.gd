extends PlatformServices

## Stage 69.1: editor/local-build platform. Keeps manual testing possible
## without a Yandex SDK by simulating ad flows with short timers and never
## touching any web-only API.

const DEBUG_AD_OPEN_DELAY := 0.3
const DEBUG_AD_RESULT_DELAY := 0.6

## Stage 69.3: mock catalog product ids, matching ShopCatalog's Yandex
## product id mapping (see shop_catalog.gd), so debug_purchases_enabled can
## exercise the full ShopScreen purchase flow (catalog -> buy -> success ->
## grant -> consume) end-to-end with no Yandex SDK. Prices are placeholder
## text only, never real money.
const MOCK_CATALOG_PRODUCT_IDS := [
	"gems_50", "gems_150", "gems_250", "gems_500",
	"bundle_small", "bundle_medium", "bundle_large", "bundle_mega",
	"offer_gems", "offer_mega_gems", "offer_boosters",
]

var _ad_in_progress := false
var debug_purchases_enabled := false
var _mock_payment_catalog: Dictionary = {}

## Stage 69.3.1: consume_purchase() simulates success by default. Set true
## (manual/ad-hoc editor testing only) to exercise the pending-consume retry
## path instead.
var debug_consume_should_fail := false


func game_ready() -> void:
	pass


func gameplay_start(_attempt: int = 0) -> void:
	pass


func gameplay_stop() -> void:
	pass


func refresh_platform_ready() -> bool:
	return true


func is_sdk_ready() -> bool:
	return true


func get_platform_key() -> String:
	return "debug"


func get_platform_language() -> String:
	var loop := Engine.get_main_loop()
	if loop is SceneTree:
		var localization_manager: Node = (loop as SceneTree).root.get_node_or_null("/root/LocalizationManager")
		if localization_manager != null and localization_manager.has_method("get_language"):
			var language: String = localization_manager.get_language()
			if language != "":
				return language
	return "en"


func show_rewarded_ad(_placement_id: String = "") -> void:
	if _ad_in_progress:
		rewarded_ad_error.emit("ad_already_in_progress")
		return
	_ad_in_progress = true
	_simulate_rewarded_ad()


func _simulate_rewarded_ad() -> void:
	var loop := Engine.get_main_loop()
	if not (loop is SceneTree):
		_ad_in_progress = false
		rewarded_ad_error.emit("no_scene_tree")
		return
	var tree: SceneTree = loop
	rewarded_ad_opened.emit()
	await tree.create_timer(DEBUG_AD_OPEN_DELAY).timeout
	rewarded_ad_rewarded.emit()
	await tree.create_timer(DEBUG_AD_RESULT_DELAY).timeout
	_ad_in_progress = false
	rewarded_ad_closed.emit(true)


func show_fullscreen_ad(_placement_id: String = "") -> void:
	if _ad_in_progress:
		fullscreen_ad_error.emit("ad_already_in_progress")
		return
	_ad_in_progress = true
	_simulate_fullscreen_ad()


func _simulate_fullscreen_ad() -> void:
	var loop := Engine.get_main_loop()
	if not (loop is SceneTree):
		_ad_in_progress = false
		fullscreen_ad_error.emit("no_scene_tree")
		return
	var tree: SceneTree = loop
	fullscreen_ad_opened.emit()
	await tree.create_timer(DEBUG_AD_RESULT_DELAY).timeout
	_ad_in_progress = false
	fullscreen_ad_closed.emit(true)


func purchase_product(platform_product_id: String, _local_product_id: String = "") -> void:
	if not debug_purchases_enabled:
		payment_purchase_error.emit(platform_product_id, "debug_purchases_disabled")
		return
	payment_purchase_started.emit(platform_product_id)
	payment_purchase_success.emit(platform_product_id, "debug_token_%s" % platform_product_id)


func consume_purchase(purchase_token: String) -> void:
	if purchase_token == "":
		payment_consume_error.emit(purchase_token, "invalid_token")
		return
	if debug_consume_should_fail:
		payment_consume_error.emit(purchase_token, "debug_consume_failure")
		return
	payment_consume_success.emit(purchase_token)


func check_unprocessed_purchases() -> void:
	unprocessed_purchase_check_completed.emit()


func load_payment_catalog() -> void:
	if debug_purchases_enabled:
		_mock_payment_catalog = _build_mock_payment_catalog()
	else:
		_mock_payment_catalog = {}
	payment_catalog_loaded.emit(_mock_payment_catalog.values())


func _build_mock_payment_catalog() -> Dictionary:
	var catalog := {}
	for product_id in MOCK_CATALOG_PRODUCT_IDS:
		catalog[product_id] = {
			"id": product_id,
			"title": product_id,
			"description": "",
			"price": "Debug",
			"priceValue": "0",
			"priceCurrencyCode": "",
			"priceCurrencyImage": {},
		}
	return catalog


func get_cached_payment_catalog() -> Dictionary:
	return _mock_payment_catalog.duplicate(true)


func get_catalog_product(local_product_id: String) -> Dictionary:
	return _mock_payment_catalog.get(local_product_id, {})


func is_ad_in_progress() -> bool:
	return _ad_in_progress


# ---------------------------------------------------------------------------
# Cloud save (debug backend)
# ---------------------------------------------------------------------------

## Stage 69.4: a separate file from the real local save (user://save_v1.json)
## so debug cloud testing never touches actual progress. Manual editor
## testing scenarios: delete this file for "no cloud save"; hand-edit its
## save_revision/last_save_unix_time to be higher/lower/equal to the local
## save's for "cloud newer"/"local newer"/"equal snapshots"; write invalid
## JSON into it for "malformed cloud JSON"; flip the debug flags below for
## "cloud unavailable" or simulated load/save failure.
const DEBUG_CLOUD_SAVE_PATH := "user://debug_cloud_save_v1.json"

var debug_cloud_available_override := true
var debug_cloud_load_should_fail := false
var debug_cloud_save_should_fail := false


func is_cloud_save_available() -> bool:
	return debug_cloud_available_override


func load_cloud_save() -> void:
	if debug_cloud_load_should_fail:
		cloud_save_load_error.emit("debug_cloud_load_failure")
		return

	if not FileAccess.file_exists(DEBUG_CLOUD_SAVE_PATH):
		cloud_save_loaded.emit({})
		return

	var file := FileAccess.open(DEBUG_CLOUD_SAVE_PATH, FileAccess.READ)
	if file == null:
		cloud_save_loaded.emit({})
		return

	var json_text := file.get_as_text()
	var parser := JSON.new()
	if parser.parse(json_text) != OK:
		cloud_save_load_error.emit("malformed_cloud_json")
		return

	var parsed = parser.data
	cloud_save_loaded.emit(parsed if parsed is Dictionary else {})


func save_cloud_save(data: Dictionary, _flush: bool = false) -> void:
	if debug_cloud_save_should_fail:
		cloud_save_error.emit("debug_cloud_save_failure")
		return

	var file := FileAccess.open(DEBUG_CLOUD_SAVE_PATH, FileAccess.WRITE)
	if file == null:
		cloud_save_error.emit("file_open_failed")
		return

	file.store_string(JSON.stringify(data, "\t"))
	file.flush()
	file.close()
	cloud_save_completed.emit()

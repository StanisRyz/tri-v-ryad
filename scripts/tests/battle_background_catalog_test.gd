extends SceneTree

const BATTLE_BACKGROUND_CATALOG_SCRIPT := "res://scripts/game/config/battle_background_catalog.gd"
const GAME_ASSET_CATALOG := preload("res://scripts/game/config/game_asset_catalog.gd")

var _failures := 0


func _initialize() -> void:
	print("Running battle background catalog tests...")

	var catalog = load(BATTLE_BACKGROUND_CATALOG_SCRIPT).new()
	_test_has_exactly_five_backgrounds(catalog)
	_test_ids_are_unique(catalog)
	_test_all_backgrounds_valid(catalog)
	_test_default_background_exists(catalog)
	_test_get_background_returns_expected(catalog)
	_test_background_asset_keys(catalog)
	_test_has_background_works(catalog)
	_test_unknown_background_returns_null(catalog)

	if _failures == 0:
		print("Battle background catalog tests passed.")
		quit(0)
	else:
		push_error("Battle background catalog tests failed: %d" % _failures)
		quit(1)


func _test_has_exactly_five_backgrounds(catalog) -> void:
	_expect_equal(catalog.get_all_backgrounds().size(), 5, "catalog contains exactly 5 backgrounds")
	print("ok - catalog has 5 backgrounds")


func _test_ids_are_unique(catalog) -> void:
	var seen_ids := {}
	var duplicate_found := false
	for background_config in catalog.get_all_backgrounds():
		if seen_ids.has(background_config.background_id):
			duplicate_found = true
		seen_ids[background_config.background_id] = true

	_expect_false(duplicate_found, "background ids are unique")
	print("ok - background ids are unique")


func _test_all_backgrounds_valid(catalog) -> void:
	var all_valid := true
	for background_config in catalog.get_all_backgrounds():
		if not catalog.is_valid_background(background_config):
			all_valid = false

	_expect_true(all_valid, "all backgrounds are valid")
	print("ok - all backgrounds are valid")


func _test_default_background_exists(catalog) -> void:
	var default_background = catalog.get_default_background()
	_expect_true(default_background != null, "default background exists")
	_expect_true(catalog.is_valid_background(default_background), "default background is valid")
	print("ok - default background exists and is valid")


func _test_get_background_returns_expected(catalog) -> void:
	var background_config = catalog.get_background("background_3")
	_expect_true(background_config != null, "get_background returns expected background")
	_expect_equal(background_config.background_id, "background_3", "get_background returns matching id")
	print("ok - get_background returns expected background")


func _test_background_asset_keys(catalog) -> void:
	for background_config in catalog.get_all_backgrounds():
		_expect_equal(background_config.asset_key, background_config.background_id, "background asset key matches id")
		_expect_true(GAME_ASSET_CATALOG.has_asset_key(background_config.asset_key), "background asset key exists in asset catalog")
	print("ok - background asset keys are mapped")


func _test_has_background_works(catalog) -> void:
	_expect_true(catalog.has_background("background_1"), "has_background true for known id")
	_expect_false(catalog.has_background("background_unknown"), "has_background false for unknown id")
	print("ok - has_background works")


func _test_unknown_background_returns_null(catalog) -> void:
	var background_config = catalog.get_background("background_unknown")
	_expect_true(background_config == null, "unknown background id returns null")
	print("ok - unknown background id returns null")


func _expect_true(value: bool, message: String) -> void:
	if value:
		return

	_failures += 1
	push_error("FAILED: %s" % message)


func _expect_false(value: bool, message: String) -> void:
	_expect_true(not value, message)


func _expect_equal(actual, expected, message: String) -> void:
	if actual == expected:
		return

	_failures += 1
	push_error("FAILED: %s | expected=%s actual=%s" % [message, expected, actual])

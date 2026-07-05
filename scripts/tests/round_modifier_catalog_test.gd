extends SceneTree

const ROUND_MODIFIER_CATALOG_SCRIPT := "res://scripts/game/config/round_modifier_catalog.gd"

var _failures := 0


func _initialize() -> void:
	print("Running round modifier catalog tests...")

	_test_catalog_contains_expected_modifiers()
	_test_modifier_ids_are_unique()
	_test_all_modifiers_are_valid()
	_test_default_modifier_exists_and_is_valid()
	_test_missing_color_defaults_to_x1()
	_test_red_x3_only_buffs_red()
	_test_all_x2_buffs_every_color()

	if _failures == 0:
		print("Round modifier catalog tests passed.")
		quit(0)
	else:
		push_error("Round modifier catalog tests failed: %d" % _failures)
		quit(1)


func _test_catalog_contains_expected_modifiers() -> void:
	var catalog = load(ROUND_MODIFIER_CATALOG_SCRIPT).new()
	var expected_ids := ["red_x3", "blue_x3", "green_x3", "yellow_x3", "purple_x3", "all_x2"]
	for modifier_id in expected_ids:
		_expect_true(catalog.has_modifier(modifier_id), "catalog contains %s" % modifier_id)
	print("ok - catalog contains expected modifiers")


func _test_modifier_ids_are_unique() -> void:
	var catalog = load(ROUND_MODIFIER_CATALOG_SCRIPT).new()
	var seen := {}
	for modifier in catalog.get_all_modifiers():
		_expect_true(not seen.has(modifier.modifier_id), "modifier id %s is unique" % modifier.modifier_id)
		seen[modifier.modifier_id] = true
	print("ok - modifier ids are unique")


func _test_all_modifiers_are_valid() -> void:
	var catalog = load(ROUND_MODIFIER_CATALOG_SCRIPT).new()
	for modifier in catalog.get_all_modifiers():
		_expect_true(catalog.is_valid_modifier(modifier), "modifier %s is valid" % modifier.modifier_id)
	print("ok - all catalog modifiers are valid")


func _test_default_modifier_exists_and_is_valid() -> void:
	var catalog = load(ROUND_MODIFIER_CATALOG_SCRIPT).new()
	var default_modifier = catalog.get_default_modifier()
	_expect_true(default_modifier != null, "default modifier exists")
	_expect_true(catalog.is_valid_modifier(default_modifier), "default modifier is valid")
	print("ok - default modifier exists and is valid")


func _test_missing_color_defaults_to_x1() -> void:
	var catalog = load(ROUND_MODIFIER_CATALOG_SCRIPT).new()
	var red_modifier = catalog.get_modifier("red_x3")
	_expect_equal(red_modifier.get_multiplier(TileType.BLUE), 1.0, "missing color defaults to x1")
	print("ok - missing color multiplier defaults to x1")


func _test_red_x3_only_buffs_red() -> void:
	var catalog = load(ROUND_MODIFIER_CATALOG_SCRIPT).new()
	var red_modifier = catalog.get_modifier("red_x3")
	_expect_equal(red_modifier.get_multiplier(TileType.RED), 3.0, "red_x3 makes red multiplier x3")
	_expect_equal(red_modifier.get_multiplier(TileType.BLUE), 1.0, "red_x3 keeps blue at x1")
	_expect_equal(red_modifier.get_multiplier(TileType.GREEN), 1.0, "red_x3 keeps green at x1")
	print("ok - red_x3 only buffs red")


func _test_all_x2_buffs_every_color() -> void:
	var catalog = load(ROUND_MODIFIER_CATALOG_SCRIPT).new()
	var all_modifier = catalog.get_modifier("all_x2")
	for tile_type in TileType.get_all_types():
		_expect_equal(all_modifier.get_multiplier(tile_type), 2.0, "all_x2 doubles tile type %d" % tile_type)
	print("ok - all_x2 buffs every color")


func _expect_true(value: bool, message: String) -> void:
	if value:
		return

	_failures += 1
	push_error("FAILED: %s" % message)


func _expect_equal(actual, expected, message: String) -> void:
	if actual == expected:
		return

	_failures += 1
	push_error("FAILED: %s | expected=%s actual=%s" % [message, expected, actual])

extends SceneTree

const LEVEL_CATALOG_SCRIPT := "res://scripts/game/config/level_catalog.gd"

var _failures := 0


func _initialize() -> void:
	print("Running level config tests...")

	var catalog = load(LEVEL_CATALOG_SCRIPT).new()
	_test_default_level(catalog)
	_test_level_count(catalog)
	_test_expected_level_ids(catalog)
	_test_unknown_level_fallback(catalog)
	_test_level_five_is_harder(catalog)
	_test_level_contents(catalog)

	if _failures == 0:
		print("Level config tests passed.")
		quit(0)
	else:
		push_error("Level config tests failed: %d" % _failures)
		quit(1)


func _test_default_level(catalog) -> void:
	_expect_equal(catalog.get_default_level_id(), "level_1", "default level id")
	_expect_equal(catalog.get_level(catalog.get_default_level_id()).level_id, "level_1", "default level exists")
	print("ok - catalog returns default level")


func _test_level_count(catalog) -> void:
	_expect_equal(catalog.get_all_levels().size(), 100, "level count")
	print("ok - catalog returns 100 levels")


func _test_expected_level_ids(catalog) -> void:
	for index in range(1, 101):
		_expect_true(catalog.has_level("level_%d" % index), "catalog has level_%d" % index)
	_expect_false(catalog.has_level("level_101"), "catalog does not have level_101")
	print("ok - catalog has level_1 through level_100")


func _test_unknown_level_fallback(catalog) -> void:
	_expect_equal(catalog.get_level("missing_level").level_id, catalog.get_default_level_id(), "unknown level falls back to default")
	print("ok - unknown level fallback is predictable")


func _test_level_five_is_harder(catalog) -> void:
	var level_1 = catalog.get_level("level_1")
	var level_100 = catalog.get_level("level_100")
	_expect_true(level_1.moves >= level_100.moves, "level 100 moves are not more forgiving than level 1")
	_expect_true(level_100.reward_upgrade_points >= level_1.reward_upgrade_points, "level 100 reward is not lower than level 1")
	print("ok - placeholder campaign curve trends across 100 levels")


func _test_level_contents(catalog) -> void:
	var expected_level_number := 1
	for level_config in catalog.get_all_levels():
		_expect_equal(level_config.hero_configs.size(), 3, "%s has 3 heroes" % level_config.level_id)
		_expect_true(level_config.moves > 0, "%s has positive moves" % level_config.level_id)
		_expect_true(level_config.display_name != "", "%s has display name" % level_config.level_id)
		_expect_equal(level_config.display_name, "Level %d" % expected_level_number, "%s has numbers-only display name" % level_config.level_id)
		_expect_false(level_config.display_name.contains(":"), "%s display name has no subtitle separator" % level_config.level_id)
		_expect_true(level_config.enemy_config != null, "%s has enemy config" % level_config.level_id)
		_expect_true(level_config.enemy_config.max_hp > 0, "%s enemy has hp" % level_config.level_id)
		_expect_true(level_config.reward_upgrade_points >= 0, "%s has non-negative reward" % level_config.level_id)
		expected_level_number += 1
	print("ok - each level has heroes, moves, and enemy config")


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

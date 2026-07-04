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
	_expect_equal(catalog.get_all_levels().size(), 5, "level count")
	print("ok - catalog returns 5 levels")


func _test_expected_level_ids(catalog) -> void:
	for index in range(1, 6):
		_expect_true(catalog.has_level("level_%d" % index), "catalog has level_%d" % index)
	print("ok - catalog has level_1 through level_5")


func _test_unknown_level_fallback(catalog) -> void:
	_expect_equal(catalog.get_level("missing_level").level_id, catalog.get_default_level_id(), "unknown level falls back to default")
	print("ok - unknown level fallback is predictable")


func _test_level_five_is_harder(catalog) -> void:
	var level_1 = catalog.get_level("level_1")
	var level_5 = catalog.get_level("level_5")
	_expect_true(level_5.enemy_config.max_hp > level_1.enemy_config.max_hp or level_5.enemy_config.attack > level_1.enemy_config.attack, "level 5 harder than level 1")
	print("ok - level 5 is harder than level 1")


func _test_level_contents(catalog) -> void:
	for level_config in catalog.get_all_levels():
		_expect_equal(level_config.hero_configs.size(), 3, "%s has 3 heroes" % level_config.level_id)
		_expect_true(level_config.moves > 0, "%s has positive moves" % level_config.level_id)
		_expect_true(level_config.enemy_config != null, "%s has enemy config" % level_config.level_id)
		_expect_true(level_config.enemy_config.max_hp > 0, "%s enemy has hp" % level_config.level_id)
	print("ok - each level has heroes, moves, and enemy config")


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

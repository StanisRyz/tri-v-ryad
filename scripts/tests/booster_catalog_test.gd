extends SceneTree

const BOOSTER_CATALOG_SCRIPT := preload("res://scripts/game/config/booster_catalog.gd")
const BOOSTER_CONFIG_SCRIPT := preload("res://scripts/game/config/booster_config.gd")

var _failures := 0


func _initialize() -> void:
	print("Running booster catalog tests...")

	var catalog = BOOSTER_CATALOG_SCRIPT.new()
	_expect_equal(catalog.get_all_boosters().size(), 3, "catalog has three boosters")
	for booster_id in ["hammer", "freeze_time", "rocket_barrage"]:
		_expect_true(catalog.has_booster(booster_id), "%s exists" % booster_id)
		var booster = catalog.get_booster(booster_id)
		_expect_true(catalog.is_valid_booster(booster), "%s is valid" % booster_id)
		_expect_true(booster.asset_key != "", "%s has asset key" % booster_id)
		_expect_equal(booster.uses_per_battle, 1, "%s has one use" % booster_id)

	_expect_equal(catalog.get_booster("hammer").targeting_mode, BOOSTER_CONFIG_SCRIPT.TARGETING_TARGET_CELL, "hammer targets a cell")
	_expect_equal(catalog.get_booster("freeze_time").targeting_mode, BOOSTER_CONFIG_SCRIPT.TARGETING_NONE, "freeze has no target")
	_expect_equal(catalog.get_booster("rocket_barrage").targeting_mode, BOOSTER_CONFIG_SCRIPT.TARGETING_TARGET_CELL, "rocket targets a cell")

	_finish()


func _finish() -> void:
	if _failures == 0:
		print("Booster catalog tests passed.")
		quit(0)
	else:
		push_error("Booster catalog tests failed: %d" % _failures)
		quit(1)


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

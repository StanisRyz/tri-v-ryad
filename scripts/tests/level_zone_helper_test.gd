extends SceneTree

const LEVEL_ZONE_HELPER := preload("res://scripts/game/config/level_zone_helper.gd")

var _failures := 0


func _initialize() -> void:
	print("Running level zone helper tests...")

	_expect_equal(LEVEL_ZONE_HELPER.get_zone_count(100), 10, "100 levels with zone size 10 gives 10 zones")
	_expect_equal(LEVEL_ZONE_HELPER.get_level_range_for_zone(0, 100), Vector2i(1, 10), "zone 1 range is 1-10")
	_expect_equal(LEVEL_ZONE_HELPER.get_level_range_for_zone(1, 100), Vector2i(11, 20), "zone 2 range is 11-20")
	_expect_equal(LEVEL_ZONE_HELPER.get_level_range_for_zone(9, 100), Vector2i(91, 100), "zone 10 range is 91-100")
	_expect_equal(LEVEL_ZONE_HELPER.get_zone_index_for_level_id("level_1"), 0, "level_1 maps to zone 1")
	_expect_equal(LEVEL_ZONE_HELPER.get_zone_index_for_level_id("level_10"), 0, "level_10 maps to zone 1")
	_expect_equal(LEVEL_ZONE_HELPER.get_zone_index_for_level_id("level_11"), 1, "level_11 maps to zone 2")
	_expect_equal(LEVEL_ZONE_HELPER.get_zone_index_for_level_id("level_100"), 9, "level_100 maps to zone 10")
	_expect_equal(LEVEL_ZONE_HELPER.get_zone_unlock_level_id(0), "", "zone 1 has no unlock requirement")
	_expect_equal(LEVEL_ZONE_HELPER.get_zone_unlock_level_id(1), "level_10", "zone 2 unlock requirement is level_10")
	_expect_equal(LEVEL_ZONE_HELPER.get_zone_unlock_level_id(2), "level_20", "zone 3 unlock requirement is level_20")
	_expect_equal(LEVEL_ZONE_HELPER.get_zone_unlock_level_id(9), "level_90", "zone 10 unlock requirement is level_90")
	_expect_equal(LEVEL_ZONE_HELPER.format_zone_label(0, 1, 10), "Zone 1: Levels 1-10", "zone 1 label is formatted")
	_expect_equal(LEVEL_ZONE_HELPER.format_zone_label(9, 91, 100), "Zone 10: Levels 91-100", "zone 10 label is formatted")
	_expect_equal(LEVEL_ZONE_HELPER.get_zone_index_for_level_id("level_alpha"), -1, "malformed numeric suffix is safe")
	_expect_equal(LEVEL_ZONE_HELPER.get_zone_index_for_level_id("boss_1"), -1, "malformed prefix is safe")
	_expect_equal(LEVEL_ZONE_HELPER.get_zone_index_for_level_id(""), -1, "empty level id is safe")

	if _failures == 0:
		print("Level zone helper tests passed.")
		quit(0)
	else:
		push_error("Level zone helper tests failed: %d" % _failures)
		quit(1)


func _expect_equal(actual, expected, message: String) -> void:
	if actual == expected:
		return

	_failures += 1
	push_error("FAILED: %s | expected=%s actual=%s" % [message, expected, actual])

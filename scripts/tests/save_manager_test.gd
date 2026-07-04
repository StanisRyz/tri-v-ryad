extends SceneTree

const SAVE_MANAGER_SCRIPT := "res://scripts/game/save/save_manager.gd"
const PLAYER_PROGRESS_SCRIPT := "res://scripts/game/progression/player_progress.gd"

const TEST_SAVE_PATH := "user://test_save_v1.json"
const TEST_TEMP_SAVE_PATH := "user://test_save_v1.tmp"

var _failures := 0


func _initialize() -> void:
	print("Running save manager tests...")

	_cleanup()
	var save_manager = load(SAVE_MANAGER_SCRIPT).new(TEST_SAVE_PATH, TEST_TEMP_SAVE_PATH)

	var missing_progress = save_manager.load_progress()
	_expect_equal(missing_progress.upgrade_points, 0, "missing save loads default progress")
	_expect_true(missing_progress.hero_upgrades.has("hero_1"), "missing save default has hero_1")

	var progress = load(PLAYER_PROGRESS_SCRIPT).create_default()
	progress.add_upgrade_points(3)
	progress.get_hero_upgrade("hero_1").attack_level = 2
	progress.get_hero_upgrade("hero_2").hp_level = 1
	var level_state = progress.ensure_level_progress("level_1")
	level_state.completed = true
	level_state.stars = 3
	level_state.best_moves_left = 12
	progress.set_level_progress("level_1", level_state)
	_expect_true(save_manager.save_progress(progress), "save_progress succeeds")

	var loaded = save_manager.load_progress()
	_expect_equal(loaded.upgrade_points, 3, "saved progress loads with upgrade points")
	_expect_equal(loaded.get_hero_upgrade("hero_1").attack_level, 2, "saved attack upgrade loads correctly")
	_expect_equal(loaded.get_hero_upgrade("hero_2").hp_level, 1, "saved hp upgrade loads correctly")
	_expect_equal(loaded.get_level_stars("level_1"), 3, "saved level stars load correctly")
	_expect_equal(loaded.get_level_progress("level_1").best_moves_left, 12, "saved best moves load correctly")

	var old_save_file := FileAccess.open(TEST_SAVE_PATH, FileAccess.WRITE)
	old_save_file.store_string(JSON.stringify({
		"save_version": 1,
		"upgrade_points": 4,
		"hero_upgrades": {
			"hero_1": {
				"hero_id": "hero_1",
				"attack_level": 2,
				"hp_level": 0,
			},
		},
		"completed_levels": {
			"level_2": true,
		},
	}))
	old_save_file.close()
	var old_loaded = save_manager.load_progress()
	_expect_equal(old_loaded.get_hero_upgrade("hero_1").attack_level, 2, "old save keeps hero upgrade data")
	_expect_true(old_loaded.is_level_completed("level_2"), "old save without level_progress loads completed level")
	_expect_equal(old_loaded.get_level_stars("level_2"), 1, "old save without level_progress migrates stars")

	var file := FileAccess.open(TEST_SAVE_PATH, FileAccess.WRITE)
	file.store_string("{invalid json")
	file.close()
	var invalid_loaded = save_manager.load_progress()
	_expect_equal(invalid_loaded.upgrade_points, 0, "invalid JSON loads default progress safely")

	progress.add_upgrade_points(5)
	save_manager.save_progress(progress)
	var reset_progress = save_manager.reset_progress()
	_expect_equal(reset_progress.upgrade_points, 0, "reset_progress returns default")
	_expect_equal(save_manager.load_progress().upgrade_points, 0, "reset_progress saves default")

	_cleanup()
	if _failures == 0:
		print("Save manager tests passed.")
		quit(0)
	else:
		push_error("Save manager tests failed: %d" % _failures)
		quit(1)


func _cleanup() -> void:
	if FileAccess.file_exists(TEST_SAVE_PATH):
		DirAccess.remove_absolute(TEST_SAVE_PATH)
	if FileAccess.file_exists(TEST_TEMP_SAVE_PATH):
		DirAccess.remove_absolute(TEST_TEMP_SAVE_PATH)


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

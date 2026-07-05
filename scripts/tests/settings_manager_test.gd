extends SceneTree

const SETTINGS_MANAGER_SCRIPT := "res://scripts/game/settings/settings_manager.gd"

const TEST_SETTINGS_PATH := "user://test_settings_v1.json"
const TEST_TEMP_SETTINGS_PATH := "user://test_settings_v1.tmp"

var _failures := 0


func _initialize() -> void:
	print("Running settings manager tests...")

	_cleanup()
	var player_save_existed_before := FileAccess.file_exists("user://save_v1.json")
	var settings_manager = load(SETTINGS_MANAGER_SCRIPT).new(TEST_SETTINGS_PATH, TEST_TEMP_SETTINGS_PATH)

	var missing_settings = settings_manager.get_settings()
	_expect_true(missing_settings.animations_enabled, "default animations_enabled is true")
	_expect_false(missing_settings.reduced_motion_enabled, "default reduced_motion_enabled is false")
	_expect_false(missing_settings.debug_labels_enabled, "default debug_labels_enabled is false")
	_expect_true(missing_settings.music_enabled, "default music_enabled is true")
	_expect_true(missing_settings.sound_effects_enabled, "default sound_effects_enabled is true")

	settings_manager.load()
	var loaded_missing = settings_manager.get_settings()
	_expect_true(loaded_missing.animations_enabled, "missing settings file loads defaults")

	settings_manager.set_animations_enabled(false)
	settings_manager.set_reduced_motion_enabled(true)
	settings_manager.set_debug_labels_enabled(true)
	settings_manager.set_music_enabled(false)
	settings_manager.set_sound_effects_enabled(false)

	var fresh_manager = load(SETTINGS_MANAGER_SCRIPT).new(TEST_SETTINGS_PATH, TEST_TEMP_SETTINGS_PATH)
	fresh_manager.load()
	var loaded = fresh_manager.get_settings()
	_expect_false(loaded.animations_enabled, "animations_enabled persists across load")
	_expect_true(loaded.reduced_motion_enabled, "reduced_motion_enabled persists across load")
	_expect_true(loaded.debug_labels_enabled, "debug_labels_enabled persists across load")
	_expect_false(loaded.music_enabled, "music_enabled persists across load")
	_expect_false(loaded.sound_effects_enabled, "sound_effects_enabled persists across load")

	var corrupt_file := FileAccess.open(TEST_SETTINGS_PATH, FileAccess.WRITE)
	corrupt_file.store_string("{invalid json")
	corrupt_file.close()
	var corrupt_manager = load(SETTINGS_MANAGER_SCRIPT).new(TEST_SETTINGS_PATH, TEST_TEMP_SETTINGS_PATH)
	corrupt_manager.load()
	var corrupt_loaded = corrupt_manager.get_settings()
	_expect_true(corrupt_loaded.animations_enabled, "invalid JSON falls back to default animations_enabled")
	_expect_false(corrupt_loaded.reduced_motion_enabled, "invalid JSON falls back to default reduced_motion_enabled")

	var non_dict_file := FileAccess.open(TEST_SETTINGS_PATH, FileAccess.WRITE)
	non_dict_file.store_string(JSON.stringify([1, 2, 3]))
	non_dict_file.close()
	var non_dict_manager = load(SETTINGS_MANAGER_SCRIPT).new(TEST_SETTINGS_PATH, TEST_TEMP_SETTINGS_PATH)
	non_dict_manager.load()
	_expect_true(non_dict_manager.get_settings().animations_enabled, "non-dictionary JSON falls back to defaults safely")

	fresh_manager.reset_settings_to_defaults()
	var reset_settings = fresh_manager.get_settings()
	_expect_true(reset_settings.animations_enabled, "reset_settings_to_defaults restores animations_enabled")
	_expect_false(reset_settings.reduced_motion_enabled, "reset_settings_to_defaults restores reduced_motion_enabled")
	_expect_false(reset_settings.debug_labels_enabled, "reset_settings_to_defaults restores debug_labels_enabled")
	_expect_true(reset_settings.music_enabled, "reset_settings_to_defaults restores music_enabled")
	_expect_true(reset_settings.sound_effects_enabled, "reset_settings_to_defaults restores sound_effects_enabled")

	var reload_after_reset = load(SETTINGS_MANAGER_SCRIPT).new(TEST_SETTINGS_PATH, TEST_TEMP_SETTINGS_PATH)
	reload_after_reset.load()
	_expect_true(reload_after_reset.get_settings().animations_enabled, "reset settings persist to disk")

	_expect_equal(FileAccess.file_exists("user://save_v1.json"), player_save_existed_before, "settings tests leave the player save file untouched")

	_cleanup()
	if _failures == 0:
		print("Settings manager tests passed.")
		quit(0)
	else:
		push_error("Settings manager tests failed: %d" % _failures)
		quit(1)


func _cleanup() -> void:
	if FileAccess.file_exists(TEST_SETTINGS_PATH):
		DirAccess.remove_absolute(TEST_SETTINGS_PATH)
	if FileAccess.file_exists(TEST_TEMP_SETTINGS_PATH):
		DirAccess.remove_absolute(TEST_TEMP_SETTINGS_PATH)


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

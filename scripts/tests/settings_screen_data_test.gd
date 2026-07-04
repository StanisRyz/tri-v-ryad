extends SceneTree

const SETTINGS_SCREEN := preload("res://scenes/screens/SettingsScreen.tscn")
const SETTINGS_MANAGER_SCRIPT := preload("res://scripts/game/settings/settings_manager.gd")

const TEST_SETTINGS_PATH := "user://test_settings_screen_v1.json"
const TEST_TEMP_SETTINGS_PATH := "user://test_settings_screen_v1.tmp"

var _failures := 0


func _initialize() -> void:
	print("Running settings screen data tests...")
	_run()


func _run() -> void:
	_cleanup()
	await _test_signals_and_no_reset_progress()
	await _test_receives_settings_manager_and_reads_current_settings()
	await _test_toggling_updates_settings_manager()
	_cleanup()

	if _failures == 0:
		print("Settings screen data tests passed.")
		quit(0)
	else:
		push_error("Settings screen data tests failed: %d" % _failures)
		quit(1)


func _test_signals_and_no_reset_progress() -> void:
	var screen := SETTINGS_SCREEN.instantiate()
	root.add_child(screen)
	await process_frame

	_expect_true(screen.has_signal("back_pressed"), "settings screen exposes back_pressed")
	_expect_true(screen.has_method("set_settings_manager"), "settings screen can receive a settings manager")
	_expect_false(screen.has_signal("reset_progress_pressed"), "settings screen has no reset progress signal")
	_expect_false(screen.has_node("%ResetProgressButton"), "settings screen has no reset progress button")

	var back_signals: Array = []
	screen.back_pressed.connect(func(): back_signals.append(true))
	screen.get_node("%BackButton").pressed.emit()
	_expect_equal(back_signals.size(), 1, "settings screen back button emits back_pressed")

	screen.queue_free()


func _test_receives_settings_manager_and_reads_current_settings() -> void:
	var settings_manager = _make_settings_manager()
	settings_manager.set_reduced_motion_enabled(true)
	settings_manager.set_debug_labels_enabled(true)

	var screen := SETTINGS_SCREEN.instantiate()
	root.add_child(screen)
	await process_frame
	screen.set_settings_manager(settings_manager)

	_expect_true(screen.get_node("%AnimationsToggle").button_pressed, "animations toggle reflects loaded settings")
	_expect_true(screen.get_node("%ReducedMotionToggle").button_pressed, "reduced motion toggle reflects loaded settings")
	_expect_true(screen.get_node("%DebugLabelsToggle").button_pressed, "debug labels toggle reflects loaded settings")

	screen.queue_free()


func _test_toggling_updates_settings_manager() -> void:
	var settings_manager = _make_settings_manager()

	var screen := SETTINGS_SCREEN.instantiate()
	root.add_child(screen)
	await process_frame
	screen.set_settings_manager(settings_manager)

	screen.get_node("%AnimationsToggle").button_pressed = false
	screen.get_node("%AnimationsToggle").toggled.emit(false)
	_expect_false(settings_manager.get_settings().animations_enabled, "toggling animations updates settings manager")

	screen.get_node("%MusicToggle").button_pressed = false
	screen.get_node("%MusicToggle").toggled.emit(false)
	_expect_false(settings_manager.get_settings().music_enabled, "toggling music updates settings manager")

	screen.get_node("%SoundEffectsToggle").button_pressed = false
	screen.get_node("%SoundEffectsToggle").toggled.emit(false)
	_expect_false(settings_manager.get_settings().sound_effects_enabled, "toggling sound effects updates settings manager")

	var reloaded = _make_settings_manager()
	reloaded.load()
	_expect_false(reloaded.get_settings().animations_enabled, "toggled settings are saved to disk")

	screen.queue_free()


func _make_settings_manager():
	var settings_manager = SETTINGS_MANAGER_SCRIPT.new(TEST_SETTINGS_PATH, TEST_TEMP_SETTINGS_PATH)
	settings_manager.load()
	return settings_manager


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

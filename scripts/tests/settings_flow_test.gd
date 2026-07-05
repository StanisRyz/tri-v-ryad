extends SceneTree

const APP_SCENE := preload("res://scenes/app/App.tscn")
const LEVEL_SELECT_PATH := "res://scenes/screens/LevelSelectScreen.tscn"
const SETTINGS_PATH := "res://scenes/screens/SettingsScreen.tscn"

var _failures := 0


func _initialize() -> void:
	print("Running settings flow tests...")
	_run()


func _run() -> void:
	await _test_settings_from_level_select_returns_to_level_select()

	if _failures == 0:
		print("Settings flow tests passed.")
		quit(0)
	else:
		push_error("Settings flow tests failed: %d" % _failures)
		quit(1)


func _test_settings_from_level_select_returns_to_level_select() -> void:
	var app: Node = APP_SCENE.instantiate()
	root.add_child(app)
	await process_frame

	_expect_equal(_current_screen_path(app), LEVEL_SELECT_PATH, "app starts at LevelSelect")
	app._router._current_screen.get_node("%SettingsButton").pressed.emit()
	await process_frame
	_expect_equal(_current_screen_path(app), SETTINGS_PATH, "LevelSelect Settings opens SettingsScreen")

	var settings_screen: Node = app._router._current_screen
	_expect_true(settings_screen.get_node("%AnimationsToggle") is CheckButton, "settings toggles remain available")
	_expect_true(settings_screen.get_node("%ReducedMotionToggle") is CheckButton, "reduced motion toggle remains available")
	_expect_true(settings_screen.get_node("%DebugLabelsToggle") is CheckButton, "debug labels toggle remains available")
	_expect_true(settings_screen.get_node("%MusicToggle") is CheckButton, "music toggle remains available")
	_expect_true(settings_screen.get_node("%SoundEffectsToggle") is CheckButton, "sound effects toggle remains available")

	settings_screen.get_node("%BackButton").pressed.emit()
	await process_frame
	_expect_equal(_current_screen_path(app), LEVEL_SELECT_PATH, "Settings Back returns to LevelSelect")

	app.queue_free()


func _current_screen_path(app: Node) -> String:
	if app._router == null or app._router._current_screen == null:
		return ""
	return app._router._current_screen.get_scene_file_path()


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

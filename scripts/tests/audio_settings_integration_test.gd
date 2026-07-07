extends SceneTree

const APP_SCENE := preload("res://scenes/app/App.tscn")
const SETTINGS_SCREEN := preload("res://scenes/screens/SettingsScreen.tscn")
const SETTINGS_MANAGER_SCRIPT := preload("res://scripts/game/settings/settings_manager.gd")
const AUDIO_MANAGER_SCRIPT := preload("res://autoload/AudioManager.gd")

const TEST_SETTINGS_PATH := "user://test_audio_settings_v1.json"
const TEST_TEMP_SETTINGS_PATH := "user://test_audio_settings_v1.tmp"

var _failures := 0


func _initialize() -> void:
	print("Running audio settings integration tests...")
	_run()


func _run() -> void:
	_cleanup()
	await _test_app_applies_loaded_settings_to_audio_manager()
	await _test_settings_screen_toggles_music_audio_manager()
	await _test_settings_screen_toggles_sound_effects_audio_manager()
	await _test_settings_back_returns_to_level_select()
	_cleanup()

	if _failures == 0:
		print("Audio settings integration tests passed.")
		quit(0)
	else:
		push_error("Audio settings integration tests failed: %d" % _failures)
		quit(1)


func _test_app_applies_loaded_settings_to_audio_manager() -> void:
	var app := APP_SCENE.instantiate()
	root.add_child(app)
	await process_frame

	app._settings_manager.set_music_enabled(false)
	app._settings_manager.set_sound_effects_enabled(false)
	app._apply_audio_settings()

	var audio_manager = root.get_node_or_null("AudioManager")
	_expect_true(audio_manager != null, "AudioManager autoload exists")
	_expect_false(audio_manager.is_music_enabled(), "app applies music_enabled to AudioManager")
	_expect_false(audio_manager.is_sound_effects_enabled(), "app applies sound_effects_enabled to AudioManager")
	audio_manager.set_music_enabled(true)
	audio_manager.set_sound_effects_enabled(true)
	app.queue_free()
	print("ok - app applies loaded audio settings")


func _test_settings_screen_toggles_music_audio_manager() -> void:
	var audio_manager = _make_local_audio_manager()
	var settings_manager = _make_settings_manager()
	var screen := SETTINGS_SCREEN.instantiate()
	root.add_child(screen)
	await process_frame
	screen.set_settings_manager(settings_manager)

	screen.get_node("%MusicToggle").button_pressed = false
	screen.get_node("%MusicToggle").toggled.emit(false)
	audio_manager.set_music_enabled(settings_manager.get_settings().music_enabled)
	_expect_false(settings_manager.get_settings().music_enabled, "music toggle updates settings manager")
	_expect_false(audio_manager.is_music_enabled(), "music setting can apply to AudioManager")

	screen.queue_free()
	audio_manager.queue_free()
	print("ok - music toggle updates audio state")


func _test_settings_screen_toggles_sound_effects_audio_manager() -> void:
	var audio_manager = _make_local_audio_manager()
	var settings_manager = _make_settings_manager()
	var screen := SETTINGS_SCREEN.instantiate()
	root.add_child(screen)
	await process_frame
	screen.set_settings_manager(settings_manager)

	screen.get_node("%SoundEffectsToggle").button_pressed = false
	screen.get_node("%SoundEffectsToggle").toggled.emit(false)
	audio_manager.set_sound_effects_enabled(settings_manager.get_settings().sound_effects_enabled)
	_expect_false(settings_manager.get_settings().sound_effects_enabled, "sound effects toggle updates settings manager")
	_expect_false(audio_manager.is_sound_effects_enabled(), "sound effects setting can apply to AudioManager")

	screen.queue_free()
	audio_manager.queue_free()
	print("ok - sound effects toggle updates audio state")


func _test_settings_back_returns_to_level_select() -> void:
	var app := APP_SCENE.instantiate()
	root.add_child(app)
	await process_frame

	app._router._current_screen.get_node("%LevelSelectButton").pressed.emit()
	await process_frame
	app._router._current_screen.get_node("%SettingsButton").pressed.emit()
	await process_frame
	app._router._current_screen.get_node("%BackButton").pressed.emit()
	await process_frame

	_expect_equal(app._router._current_screen.get_scene_file_path(), "res://scenes/screens/LevelSelectScreen.tscn", "Settings Back returns to LevelSelect")
	app.queue_free()
	print("ok - settings back returns to LevelSelect")


func _make_settings_manager():
	var settings_manager = SETTINGS_MANAGER_SCRIPT.new(TEST_SETTINGS_PATH, TEST_TEMP_SETTINGS_PATH)
	settings_manager.load()
	return settings_manager


func _make_local_audio_manager():
	var audio_manager = AUDIO_MANAGER_SCRIPT.new()
	root.add_child(audio_manager)
	return audio_manager


func _cleanup() -> void:
	if FileAccess.file_exists(TEST_SETTINGS_PATH):
		DirAccess.remove_absolute(TEST_SETTINGS_PATH)
	if FileAccess.file_exists(TEST_TEMP_SETTINGS_PATH):
		DirAccess.remove_absolute(TEST_TEMP_SETTINGS_PATH)
	var audio_manager = root.get_node_or_null("AudioManager")
	if audio_manager != null:
		audio_manager.set_music_enabled(true)
		audio_manager.set_sound_effects_enabled(true)


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

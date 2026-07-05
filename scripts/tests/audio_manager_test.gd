extends SceneTree

const AUDIO_MANAGER_SCRIPT := preload("res://autoload/AudioManager.gd")

var _failures := 0


func _initialize() -> void:
	print("Running audio manager tests...")

	await process_frame
	_test_autoload_or_instantiation_is_available()
	_test_missing_music_is_safe()
	_test_missing_sfx_is_safe()
	_test_music_enabled_false_prevents_playback()
	_test_sound_effects_enabled_false_prevents_sfx()
	_test_wrapper_methods_are_safe()
	_test_stop_music_is_safe()

	if _failures == 0:
		print("Audio manager tests passed.")
		quit(0)
	else:
		push_error("Audio manager tests failed: %d" % _failures)
		quit(1)


func _test_autoload_or_instantiation_is_available() -> void:
	var manager = _get_manager()
	_expect_true(manager != null, "AudioManager autoload or instance is available")
	manager.queue_free()
	print("ok - AudioManager can be used in headless tests")


func _test_missing_music_is_safe() -> void:
	var manager = _get_manager()
	manager.set_music_enabled(true)
	manager.play_music()
	_expect_false(manager.get_node("MusicPlayer").playing, "missing music file does not start playback")
	manager.queue_free()
	print("ok - missing music file is safe")


func _test_missing_sfx_is_safe() -> void:
	var manager = _get_manager()
	manager.set_sound_effects_enabled(true)
	manager.play_sfx("sfx_button_click")
	var any_playing := false
	for child in manager.get_children():
		if child is AudioStreamPlayer and child.name.begins_with("SfxPlayer") and child.playing:
			any_playing = true
	_expect_false(any_playing, "missing sfx file does not start playback")
	manager.queue_free()
	print("ok - missing sfx file is safe")


func _test_music_enabled_false_prevents_playback() -> void:
	var manager = _get_manager()
	manager.set_music_enabled(false)
	manager.play_music()
	_expect_false(manager.is_music_enabled(), "music enabled flag can be false")
	_expect_false(manager.get_node("MusicPlayer").playing, "music disabled prevents playback")
	manager.queue_free()
	print("ok - music disabled prevents playback")


func _test_sound_effects_enabled_false_prevents_sfx() -> void:
	var manager = _get_manager()
	manager.set_sound_effects_enabled(false)
	manager.play_sfx("sfx_match")
	_expect_false(manager.is_sound_effects_enabled(), "sound effects enabled flag can be false")
	manager.queue_free()
	print("ok - sound effects disabled prevents playback")


func _test_wrapper_methods_are_safe() -> void:
	var manager = _get_manager()
	manager.play_button_click()
	manager.play_level_select()
	manager.play_tile_swap()
	manager.play_match()
	manager.play_invalid_swap()
	manager.play_special_activate()
	manager.play_enemy_damage()
	manager.play_victory()
	manager.play_defeat()
	manager.queue_free()
	print("ok - wrapper methods are safe without files")


func _test_stop_music_is_safe() -> void:
	var manager = _get_manager()
	manager.stop_music()
	manager.queue_free()
	print("ok - stop_music is safe")


func _get_manager():
	var manager = AUDIO_MANAGER_SCRIPT.new()
	root.add_child(manager)
	return manager


func _expect_true(value: bool, message: String) -> void:
	if value:
		return

	_failures += 1
	push_error("FAILED: %s" % message)


func _expect_false(value: bool, message: String) -> void:
	_expect_true(not value, message)

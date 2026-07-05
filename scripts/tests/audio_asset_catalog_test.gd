extends SceneTree

const AUDIO_ASSET_CATALOG := preload("res://scripts/game/audio/audio_asset_catalog.gd")

const EXPECTED_AUDIO_PATHS := {
	"music_main": "res://assets/audio/music/main_theme.ogg",
	"sfx_button_click": "res://assets/audio/sfx/button_click.wav",
	"sfx_level_select": "res://assets/audio/sfx/level_select.wav",
	"sfx_tile_swap": "res://assets/audio/sfx/tile_swap.wav",
	"sfx_match": "res://assets/audio/sfx/match.wav",
	"sfx_invalid_swap": "res://assets/audio/sfx/invalid_swap.wav",
	"sfx_special_activate": "res://assets/audio/sfx/special_activate.wav",
	"sfx_enemy_damage": "res://assets/audio/sfx/enemy_damage.wav",
	"sfx_victory": "res://assets/audio/sfx/victory.wav",
	"sfx_defeat": "res://assets/audio/sfx/defeat.wav",
}

var _failures := 0


func _initialize() -> void:
	print("Running audio asset catalog tests...")

	_test_known_keys_exist()
	_test_expected_paths()
	_test_unknown_key_is_safe()
	_test_missing_files_return_null()
	_test_cached_missing_audio_is_safe()
	_test_clear_audio_cache()
	_test_known_keys_are_unique()
	_test_audio_map_is_non_empty()

	if _failures == 0:
		print("Audio asset catalog tests passed.")
		quit(0)
	else:
		push_error("Audio asset catalog tests failed: %d" % _failures)
		quit(1)


func _test_known_keys_exist() -> void:
	for audio_key in EXPECTED_AUDIO_PATHS.keys():
		_expect_true(AUDIO_ASSET_CATALOG.has_audio_key(audio_key), "audio key exists: %s" % audio_key)
	print("ok - expected audio keys exist")


func _test_expected_paths() -> void:
	for audio_key in EXPECTED_AUDIO_PATHS.keys():
		_expect_equal(AUDIO_ASSET_CATALOG.get_audio_path(audio_key), EXPECTED_AUDIO_PATHS[audio_key], "stable audio path: %s" % audio_key)
	print("ok - expected audio paths are stable")


func _test_unknown_key_is_safe() -> void:
	_expect_false(AUDIO_ASSET_CATALOG.has_audio_key("missing_key"), "unknown key is not known")
	_expect_equal(AUDIO_ASSET_CATALOG.get_audio_path("missing_key"), "", "unknown key returns empty path")
	_expect_equal(AUDIO_ASSET_CATALOG.try_load_audio_stream("missing_key"), null, "unknown key returns null stream")
	print("ok - unknown audio keys are safe")


func _test_missing_files_return_null() -> void:
	_expect_equal(AUDIO_ASSET_CATALOG.try_load_audio_stream("music_main"), null, "missing music returns null")
	_expect_equal(AUDIO_ASSET_CATALOG.try_load_audio_stream("sfx_button_click"), null, "missing sfx returns null")
	print("ok - missing optional audio files return null")


func _test_cached_missing_audio_is_safe() -> void:
	AUDIO_ASSET_CATALOG.clear_audio_cache()
	_expect_equal(AUDIO_ASSET_CATALOG.try_load_audio_stream_cached("missing_key"), null, "cached unknown key returns null")
	_expect_equal(AUDIO_ASSET_CATALOG.try_load_audio_stream_cached("music_main"), null, "cached missing music returns null")
	_expect_equal(AUDIO_ASSET_CATALOG.try_load_audio_stream_cached("sfx_match"), null, "cached missing sfx returns null")
	print("ok - cached loading is safe for missing audio")


func _test_clear_audio_cache() -> void:
	AUDIO_ASSET_CATALOG.try_load_audio_stream_cached("music_main")
	AUDIO_ASSET_CATALOG.clear_audio_cache()
	_expect_equal(AUDIO_ASSET_CATALOG.try_load_audio_stream_cached("music_main"), null, "clear_audio_cache leaves missing audio safe")
	print("ok - audio cache can be cleared")


func _test_known_keys_are_unique() -> void:
	var seen := {}
	for audio_key in AUDIO_ASSET_CATALOG.get_known_audio_keys():
		_expect_false(seen.has(audio_key), "audio key is unique: %s" % audio_key)
		seen[audio_key] = true
	print("ok - known audio keys are unique")


func _test_audio_map_is_non_empty() -> void:
	var audio_map := AUDIO_ASSET_CATALOG.get_audio_map()
	_expect_true(not audio_map.is_empty(), "audio map is non-empty")
	_expect_true(audio_map.has("music_main"), "audio map contains music_main")
	print("ok - audio map is non-empty")


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

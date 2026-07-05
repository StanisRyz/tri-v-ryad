extends RefCounted
class_name AudioAssetCatalog

const AUDIO_MAP := {
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

static var _stream_cache: Dictionary = {}
static var _missing_stream_keys: Dictionary = {}


static func get_audio_path(audio_key: String) -> String:
	return AUDIO_MAP.get(audio_key, "")


static func has_audio_key(audio_key: String) -> bool:
	return AUDIO_MAP.has(audio_key)


static func try_load_audio_stream(audio_key: String) -> AudioStream:
	var audio_path := get_audio_path(audio_key)
	if audio_path == "":
		return null
	if not ResourceLoader.exists(audio_path):
		return null

	var resource := ResourceLoader.load(audio_path)
	if resource is AudioStream:
		return resource

	return null


static func try_load_audio_stream_cached(audio_key: String) -> AudioStream:
	if audio_key == "":
		return null
	if _stream_cache.has(audio_key):
		return _stream_cache[audio_key]
	if _missing_stream_keys.has(audio_key):
		return null

	var stream := try_load_audio_stream(audio_key)
	if stream == null:
		_missing_stream_keys[audio_key] = true
		return null

	_stream_cache[audio_key] = stream
	return stream


static func clear_audio_cache() -> void:
	_stream_cache.clear()
	_missing_stream_keys.clear()


static func get_known_audio_keys() -> Array[String]:
	var keys: Array[String] = []
	for audio_key in AUDIO_MAP.keys():
		keys.append(audio_key)
	keys.sort()
	return keys


static func get_audio_map() -> Dictionary:
	return AUDIO_MAP.duplicate()

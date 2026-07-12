extends RefCounted
class_name AudioAssetCatalog

## Stage 68.1: kept as a compatibility layer for any caller that still looks
## audio up by key (AudioManager.play_sfx(key)/play_music(key)). New paths
## come from AudioConfig so there is one source of truth for real file
## locations; legacy keys (sfx_match, sfx_special_activate) are aliased onto
## the new crystal-burst/special-crystal files rather than removed.
const AUDIO_MAP := {
	"music_main": AudioConfig.MUSIC_TRACK_PATHS[0],
	"sfx_button_click": AudioConfig.SFX_BUTTON_CLICK,
	"sfx_level_select": "res://assets/audio/sfx/level_select.wav",
	"sfx_tile_swap": AudioConfig.SFX_TILE_SWAP,
	"sfx_crystal_burst": AudioConfig.SFX_CRYSTAL_BURST,
	"sfx_match": AudioConfig.SFX_CRYSTAL_BURST,
	"sfx_invalid_swap": AudioConfig.SFX_INVALID_SWAP,
	"sfx_special_crystal": AudioConfig.SFX_SPECIAL_CRYSTAL,
	"sfx_special_activate": AudioConfig.SFX_SPECIAL_CRYSTAL,
	"sfx_booster_hammer": AudioConfig.SFX_BOOSTER_HAMMER,
	"sfx_booster_rocket_barrage": AudioConfig.SFX_BOOSTER_ROCKET_BARRAGE,
	"sfx_booster_freeze_time": AudioConfig.SFX_BOOSTER_FREEZE_TIME,
	"sfx_enemy_hit": AudioConfig.SFX_ENEMY_HIT,
	"sfx_enemy_damage": AudioConfig.SFX_ENEMY_HIT,
	"sfx_victory": AudioConfig.SFX_VICTORY,
	"sfx_defeat": AudioConfig.SFX_DEFEAT,
	"sfx_lose_continue": AudioConfig.SFX_LOSE_CONTINUE,
	"sfx_purchase_success": AudioConfig.SFX_PURCHASE_SUCCESS,
	"sfx_purchase_error": AudioConfig.SFX_PURCHASE_ERROR,
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

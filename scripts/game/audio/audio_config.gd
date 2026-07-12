extends RefCounted
class_name AudioConfig

## Stage 68.1: central audio path/config constants. AudioManager and
## AudioAssetCatalog read from here so every audio path/tuning value has one
## source of truth. Paths are read lazily through ResourceLoader.exists(),
## so listing a path here is always safe even before the real file exists.

const MUSIC_TRACK_PATHS: Array[String] = [
	"res://assets/audio/music/track_01.ogg",
	"res://assets/audio/music/track_02.ogg",
	"res://assets/audio/music/track_03.ogg",
	"res://assets/audio/music/track_04.ogg",
	"res://assets/audio/music/track_05.ogg",
]

const SFX_BUTTON_CLICK := "res://assets/audio/sfx/ui/button_click.ogg"
const SFX_CRYSTAL_BURST := "res://assets/audio/sfx/game/crystal_burst.ogg"
const SFX_TILE_SWAP := "res://assets/audio/sfx/game/tile_swap.ogg"
const SFX_INVALID_SWAP := "res://assets/audio/sfx/game/invalid_swap.ogg"
const SFX_SPECIAL_CRYSTAL := "res://assets/audio/sfx/game/special_crystal.ogg"
const SFX_ENEMY_HIT := "res://assets/audio/sfx/game/enemy_hit.ogg"
const SFX_BOOSTER_HAMMER := "res://assets/audio/sfx/boosters/hammer.ogg"
const SFX_BOOSTER_ROCKET_BARRAGE := "res://assets/audio/sfx/boosters/rocket_barrage.ogg"
const SFX_BOOSTER_FREEZE_TIME := "res://assets/audio/sfx/boosters/freeze_time.ogg"
const SFX_VICTORY := "res://assets/audio/sfx/result/victory.ogg"
const SFX_DEFEAT := "res://assets/audio/sfx/result/defeat.ogg"
const SFX_LOSE_CONTINUE := "res://assets/audio/sfx/result/lose_continue.ogg"
const SFX_PURCHASE_SUCCESS := "res://assets/audio/sfx/shop/purchase_success.ogg"
const SFX_PURCHASE_ERROR := "res://assets/audio/sfx/shop/purchase_error.ogg"

const DEFAULT_MUSIC_VOLUME_DB := -8.0
const DEFAULT_SFX_VOLUME_DB := 0.0

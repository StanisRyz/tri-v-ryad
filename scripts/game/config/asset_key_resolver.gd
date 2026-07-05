extends RefCounted
class_name AssetKeyResolver

const TILE_TYPE_SCRIPT := preload("res://scripts/game/board/tile_type.gd")

const BACKGROUND_ASSET_KEYS := {
	"background_1": "background_1",
	"background_2": "background_2",
	"background_3": "background_3",
	"background_4": "background_4",
	"background_5": "background_5",
}

const ENEMY_ASSET_KEYS := {
	"training_dummy": "enemy_training_dummy",
	"small_slime": "enemy_small_slime",
	"goblin_scout": "enemy_goblin_scout",
	"goblin_fighter": "enemy_goblin_fighter",
	"armored_goblin": "enemy_armored_goblin",
	"wild_wolf": "enemy_wild_wolf",
	"bandit": "enemy_bandit",
	"orc_brute": "enemy_orc_brute",
	"cave_shaman": "enemy_cave_shaman",
	"gatekeeper": "enemy_gatekeeper",
}

const TILE_ASSET_KEYS := {
	TILE_TYPE_SCRIPT.RED: "tile_red",
	TILE_TYPE_SCRIPT.BLUE: "tile_blue",
	TILE_TYPE_SCRIPT.GREEN: "tile_green",
	TILE_TYPE_SCRIPT.YELLOW: "tile_yellow",
	TILE_TYPE_SCRIPT.PURPLE: "tile_purple",
}


static func get_background_asset_key(background_id: String) -> String:
	return BACKGROUND_ASSET_KEYS.get(background_id, "")


static func get_enemy_asset_key(enemy_id: String) -> String:
	return ENEMY_ASSET_KEYS.get(enemy_id, "")


static func get_tile_asset_key(tile_type: int) -> String:
	return TILE_ASSET_KEYS.get(tile_type, "")

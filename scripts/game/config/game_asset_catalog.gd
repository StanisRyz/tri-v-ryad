extends RefCounted
class_name GameAssetCatalog

const ASSET_MAP := {
	"background_1": "res://assets/images/backgrounds/background_1.png",
	"background_2": "res://assets/images/backgrounds/background_2.png",
	"background_3": "res://assets/images/backgrounds/background_3.png",
	"background_4": "res://assets/images/backgrounds/background_4.png",
	"background_5": "res://assets/images/backgrounds/background_5.png",
	"enemy_training_dummy": "res://assets/images/enemies/enemy_training_dummy.png",
	"enemy_small_slime": "res://assets/images/enemies/enemy_small_slime.png",
	"enemy_goblin_scout": "res://assets/images/enemies/enemy_goblin_scout.png",
	"enemy_goblin_fighter": "res://assets/images/enemies/enemy_goblin_fighter.png",
	"enemy_armored_goblin": "res://assets/images/enemies/enemy_armored_goblin.png",
	"enemy_wild_wolf": "res://assets/images/enemies/enemy_wild_wolf.png",
	"enemy_bandit": "res://assets/images/enemies/enemy_bandit.png",
	"enemy_orc_brute": "res://assets/images/enemies/enemy_orc_brute.png",
	"enemy_cave_shaman": "res://assets/images/enemies/enemy_cave_shaman.png",
	"enemy_gatekeeper": "res://assets/images/enemies/enemy_gatekeeper.png",
	"tile_red": "res://assets/images/tiles/tile_red.png",
	"tile_blue": "res://assets/images/tiles/tile_blue.png",
	"tile_green": "res://assets/images/tiles/tile_green.png",
	"tile_yellow": "res://assets/images/tiles/tile_yellow.png",
	"tile_purple": "res://assets/images/tiles/tile_purple.png",
	"ui_level_select_panel": "res://assets/images/ui/level_select_panel.png",
	"ui_battle_panel": "res://assets/images/ui/battle_panel.png",
	"ui_enemy_panel": "res://assets/images/ui/enemy_panel.png",
	"ui_result_panel": "res://assets/images/ui/result_panel.png",
	"ui_round_modifier_panel": "res://assets/images/ui/round_modifier_panel.png",
	"hero_1_portrait": "res://assets/images/heroes/hero_1_portrait.png",
	"hero_2_portrait": "res://assets/images/heroes/hero_2_portrait.png",
	"hero_3_portrait": "res://assets/images/heroes/hero_3_portrait.png",
	"hero_4_portrait": "res://assets/images/heroes/hero_4_portrait.png",
	"hero_5_portrait": "res://assets/images/heroes/hero_5_portrait.png",
}

static var _texture_cache: Dictionary = {}
static var _missing_texture_keys: Dictionary = {}


static func get_asset_path(asset_key: String) -> String:
	return ASSET_MAP.get(asset_key, "")


static func has_asset_key(asset_key: String) -> bool:
	return ASSET_MAP.has(asset_key)


static func try_load_texture(asset_key: String) -> Texture2D:
	var asset_path := get_asset_path(asset_key)
	if asset_path == "":
		return null
	if not ResourceLoader.exists(asset_path):
		return null

	var resource := ResourceLoader.load(asset_path)
	if resource is Texture2D:
		return resource

	return null


static func try_load_texture_cached(asset_key: String) -> Texture2D:
	if asset_key == "":
		return null
	if _texture_cache.has(asset_key):
		return _texture_cache[asset_key]
	if _missing_texture_keys.has(asset_key):
		return null

	var texture := try_load_texture(asset_key)
	if texture == null:
		_missing_texture_keys[asset_key] = true
		return null

	_texture_cache[asset_key] = texture
	return texture


static func clear_texture_cache() -> void:
	_texture_cache.clear()
	_missing_texture_keys.clear()


static func get_known_asset_keys() -> Array[String]:
	var keys: Array[String] = []
	for asset_key in ASSET_MAP.keys():
		keys.append(asset_key)
	keys.sort()
	return keys


static func get_asset_map() -> Dictionary:
	return ASSET_MAP.duplicate()

extends SceneTree

const ASSET_KEY_RESOLVER := preload("res://scripts/game/config/asset_key_resolver.gd")
const GAME_ASSET_CATALOG := preload("res://scripts/game/config/game_asset_catalog.gd")

const BACKGROUND_IDS := ["background_1", "background_2", "background_3", "background_4", "background_5"]
const ENEMY_ID_TO_KEY := {
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
const TILE_TYPE_TO_KEY := {
	TileType.RED: "tile_red",
	TileType.BLUE: "tile_blue",
	TileType.GREEN: "tile_green",
	TileType.YELLOW: "tile_yellow",
	TileType.PURPLE: "tile_purple",
}

var _failures := 0


func _initialize() -> void:
	print("Running asset key resolver tests...")

	_test_background_mappings()
	_test_enemy_mappings()
	_test_tile_mappings()
	_test_unknown_values_are_safe()

	if _failures == 0:
		print("Asset key resolver tests passed.")
		quit(0)
	else:
		push_error("Asset key resolver tests failed: %d" % _failures)
		quit(1)


func _test_background_mappings() -> void:
	for background_id in BACKGROUND_IDS:
		var asset_key := ASSET_KEY_RESOLVER.get_background_asset_key(background_id)
		_expect_equal(asset_key, background_id, "background maps to same asset key: %s" % background_id)
		_expect_true(GAME_ASSET_CATALOG.has_asset_key(asset_key), "background asset key exists: %s" % asset_key)
	print("ok - background ids map to asset keys")


func _test_enemy_mappings() -> void:
	for enemy_id in ENEMY_ID_TO_KEY.keys():
		var asset_key := ASSET_KEY_RESOLVER.get_enemy_asset_key(enemy_id)
		_expect_equal(asset_key, ENEMY_ID_TO_KEY[enemy_id], "enemy maps to expected asset key: %s" % enemy_id)
		_expect_true(GAME_ASSET_CATALOG.has_asset_key(asset_key), "enemy asset key exists: %s" % asset_key)
	print("ok - enemy ids map to asset keys")


func _test_tile_mappings() -> void:
	for tile_type in TILE_TYPE_TO_KEY.keys():
		var asset_key := ASSET_KEY_RESOLVER.get_tile_asset_key(tile_type)
		_expect_equal(asset_key, TILE_TYPE_TO_KEY[tile_type], "tile type maps to expected asset key")
		_expect_true(GAME_ASSET_CATALOG.has_asset_key(asset_key), "tile asset key exists: %s" % asset_key)
	print("ok - tile types map to asset keys")


func _test_unknown_values_are_safe() -> void:
	_expect_equal(ASSET_KEY_RESOLVER.get_background_asset_key("unknown_background"), "", "unknown background returns empty key")
	_expect_equal(ASSET_KEY_RESOLVER.get_enemy_asset_key("unknown_enemy"), "", "unknown enemy returns empty key")
	_expect_equal(ASSET_KEY_RESOLVER.get_tile_asset_key(999), "", "unknown tile type returns empty key")
	print("ok - unknown values return empty asset keys")


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

extends SceneTree

const GAME_ASSET_CATALOG := preload("res://scripts/game/config/game_asset_catalog.gd")

const BACKGROUND_KEYS := ["background_1", "background_2", "background_3", "background_4", "background_5"]
const ENEMY_KEYS := [
	"enemy_training_dummy",
	"enemy_small_slime",
	"enemy_goblin_scout",
	"enemy_goblin_fighter",
	"enemy_armored_goblin",
	"enemy_wild_wolf",
	"enemy_bandit",
	"enemy_orc_brute",
	"enemy_cave_shaman",
	"enemy_gatekeeper",
]
const TILE_KEYS := ["tile_red", "tile_blue", "tile_green", "tile_yellow", "tile_purple"]
const UI_KEYS := ["ui_level_select_panel", "ui_battle_panel", "ui_enemy_panel", "ui_result_panel", "ui_round_modifier_panel"]
const HERO_KEYS := ["hero_1_portrait", "hero_2_portrait", "hero_3_portrait", "hero_4_portrait", "hero_5_portrait"]

var _failures := 0


func _initialize() -> void:
	print("Running game asset catalog tests...")

	_test_known_keys_exist()
	_test_expected_paths()
	_test_unknown_key_is_safe()
	_test_missing_files_return_null()
	_test_cached_loading_is_safe()
	_test_clear_texture_cache()
	_test_known_keys_are_unique()
	_test_asset_map_is_non_empty()

	if _failures == 0:
		print("Game asset catalog tests passed.")
		quit(0)
	else:
		push_error("Game asset catalog tests failed: %d" % _failures)
		quit(1)


func _test_known_keys_exist() -> void:
	_expect_true(GAME_ASSET_CATALOG.has_asset_key("background_1"), "background_1 key exists")
	for asset_key in BACKGROUND_KEYS:
		_expect_true(GAME_ASSET_CATALOG.has_asset_key(asset_key), "background key exists: %s" % asset_key)
	for asset_key in ENEMY_KEYS:
		_expect_true(GAME_ASSET_CATALOG.has_asset_key(asset_key), "enemy key exists: %s" % asset_key)
	for asset_key in TILE_KEYS:
		_expect_true(GAME_ASSET_CATALOG.has_asset_key(asset_key), "tile key exists: %s" % asset_key)
	for asset_key in UI_KEYS:
		_expect_true(GAME_ASSET_CATALOG.has_asset_key(asset_key), "ui key exists: %s" % asset_key)
	for asset_key in HERO_KEYS:
		_expect_true(GAME_ASSET_CATALOG.has_asset_key(asset_key), "future hero key exists: %s" % asset_key)
	print("ok - expected asset keys exist")


func _test_expected_paths() -> void:
	_expect_equal(GAME_ASSET_CATALOG.get_asset_path("background_1"), "res://assets/images/backgrounds/background_1.png", "background_1 path")
	_expect_equal(GAME_ASSET_CATALOG.get_asset_path("enemy_small_slime"), "res://assets/images/enemies/enemy_small_slime.png", "enemy path")
	_expect_equal(GAME_ASSET_CATALOG.get_asset_path("tile_red"), "res://assets/images/tiles/tile_red.png", "tile path")
	_expect_equal(GAME_ASSET_CATALOG.get_asset_path("ui_enemy_panel"), "res://assets/images/ui/enemy_panel.png", "ui path")
	_expect_equal(GAME_ASSET_CATALOG.get_asset_path("hero_5_portrait"), "res://assets/images/heroes/hero_5_portrait.png", "future hero path")
	print("ok - expected asset paths are stable")


func _test_unknown_key_is_safe() -> void:
	_expect_false(GAME_ASSET_CATALOG.has_asset_key("missing_key"), "unknown key is not known")
	_expect_equal(GAME_ASSET_CATALOG.get_asset_path("missing_key"), "", "unknown key returns empty path")
	_expect_equal(GAME_ASSET_CATALOG.try_load_texture("missing_key"), null, "unknown key returns null texture")
	print("ok - unknown keys are safe")


func _test_missing_files_return_null() -> void:
	_expect_equal(GAME_ASSET_CATALOG.try_load_texture("background_1"), null, "missing background texture returns null")
	_expect_equal(GAME_ASSET_CATALOG.try_load_texture("enemy_small_slime"), null, "missing enemy texture returns null")
	print("ok - missing optional files return null")


func _test_cached_loading_is_safe() -> void:
	GAME_ASSET_CATALOG.clear_texture_cache()
	_expect_equal(GAME_ASSET_CATALOG.try_load_texture_cached("missing_key"), null, "cached unknown key returns null")
	_expect_equal(GAME_ASSET_CATALOG.try_load_texture_cached("background_1"), null, "cached missing background returns null")
	_expect_equal(GAME_ASSET_CATALOG.try_load_texture_cached("enemy_small_slime"), null, "cached missing enemy returns null")
	print("ok - cached loading is safe for missing assets")


func _test_clear_texture_cache() -> void:
	GAME_ASSET_CATALOG.try_load_texture_cached("background_1")
	GAME_ASSET_CATALOG.clear_texture_cache()
	_expect_equal(GAME_ASSET_CATALOG.try_load_texture_cached("background_1"), null, "clear_texture_cache leaves missing assets safe")
	print("ok - texture cache can be cleared")


func _test_known_keys_are_unique() -> void:
	var seen := {}
	for asset_key in GAME_ASSET_CATALOG.get_known_asset_keys():
		_expect_false(seen.has(asset_key), "asset key is unique: %s" % asset_key)
		seen[asset_key] = true
	print("ok - known asset keys are unique")


func _test_asset_map_is_non_empty() -> void:
	var asset_map := GAME_ASSET_CATALOG.get_asset_map()
	_expect_true(not asset_map.is_empty(), "asset map is non-empty")
	_expect_true(asset_map.has("background_1"), "asset map contains background_1")
	print("ok - asset map is non-empty")


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

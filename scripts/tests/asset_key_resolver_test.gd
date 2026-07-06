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
	_test_special_tile_mappings()
	_test_ui_mappings()
	_test_booster_mappings()
	_test_level_button_mappings()
	_test_star_mappings()
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


func _test_special_tile_mappings() -> void:
	_expect_asset_key(ASSET_KEY_RESOLVER.get_special_tile_asset_key(SpecialTileType.LINE_HORIZONTAL), "tile_special_horizontal", "horizontal special key")
	_expect_asset_key(ASSET_KEY_RESOLVER.get_special_tile_asset_key(SpecialTileType.LINE_VERTICAL), "tile_special_vertical", "vertical special key")
	_expect_asset_key(ASSET_KEY_RESOLVER.get_special_tile_asset_key(SpecialTileType.COLOR_BOMB), "tile_color_bomb", "color bomb key")
	print("ok - special tile types map to asset keys")


func _test_ui_mappings() -> void:
	for ui_id in ["board_frame", "battle_hud_panel", "enemy_panel", "round_modifier_panel", "status_panel", "result_panel", "level_select_background", "level_select_panel", "zone_selector_panel", "settings_background", "settings_panel", "toggle_on", "toggle_off", "booster_panel", "booster_button_ready", "booster_button_disabled", "booster_button_selected"]:
		var asset_key := ASSET_KEY_RESOLVER.get_ui_asset_key(ui_id)
		_expect_true(asset_key != "", "ui id maps to key: %s" % ui_id)
		_expect_true(GAME_ASSET_CATALOG.has_asset_key(asset_key), "ui asset key exists: %s" % asset_key)
	print("ok - UI ids map to asset keys")


func _test_booster_mappings() -> void:
	_expect_asset_key(ASSET_KEY_RESOLVER.get_booster_asset_key("hammer"), "booster_hammer", "hammer key")
	_expect_asset_key(ASSET_KEY_RESOLVER.get_booster_asset_key("freeze_time"), "booster_freeze_time", "freeze_time key")
	_expect_asset_key(ASSET_KEY_RESOLVER.get_booster_asset_key("rocket_barrage"), "booster_rocket_barrage", "rocket_barrage key")
	print("ok - booster ids map to asset keys")


func _test_level_button_mappings() -> void:
	_expect_asset_key(ASSET_KEY_RESOLVER.get_level_button_asset_key("open"), "ui_level_button_open", "open level button key")
	_expect_asset_key(ASSET_KEY_RESOLVER.get_level_button_asset_key("locked"), "ui_level_button_locked", "locked level button key")
	_expect_asset_key(ASSET_KEY_RESOLVER.get_level_button_asset_key("completed"), "ui_level_button_completed", "completed level button key")
	print("ok - level button states map to asset keys")


func _test_star_mappings() -> void:
	_expect_asset_key(ASSET_KEY_RESOLVER.get_star_asset_key(true), "ui_star_filled", "filled star key")
	_expect_asset_key(ASSET_KEY_RESOLVER.get_star_asset_key(false), "ui_star_empty", "empty star key")
	print("ok - star states map to asset keys")


func _test_unknown_values_are_safe() -> void:
	_expect_equal(ASSET_KEY_RESOLVER.get_background_asset_key("unknown_background"), "", "unknown background returns empty key")
	_expect_equal(ASSET_KEY_RESOLVER.get_enemy_asset_key("unknown_enemy"), "", "unknown enemy returns empty key")
	_expect_equal(ASSET_KEY_RESOLVER.get_tile_asset_key(999), "", "unknown tile type returns empty key")
	_expect_equal(ASSET_KEY_RESOLVER.get_special_tile_asset_key(999), "", "unknown special type returns empty key")
	_expect_equal(ASSET_KEY_RESOLVER.get_ui_asset_key("unknown_ui"), "", "unknown UI id returns empty key")
	_expect_equal(ASSET_KEY_RESOLVER.get_booster_asset_key("unknown_booster"), "", "unknown booster id returns empty key")
	_expect_equal(ASSET_KEY_RESOLVER.get_level_button_asset_key("unknown_state"), "", "unknown level state returns empty key")
	print("ok - unknown values return empty asset keys")


func _expect_asset_key(actual: String, expected: String, message: String) -> void:
	_expect_equal(actual, expected, message)
	_expect_true(GAME_ASSET_CATALOG.has_asset_key(actual), "asset key exists: %s" % actual)


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

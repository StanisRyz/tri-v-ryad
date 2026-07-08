extends RefCounted
class_name AssetKeyResolver

const TILE_TYPE_SCRIPT := preload("res://scripts/game/board/tile_type.gd")
const SPECIAL_TILE_TYPE_SCRIPT := preload("res://scripts/game/board/special_tile_type.gd")

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

const SPECIAL_TILE_ASSET_KEYS := {
	SPECIAL_TILE_TYPE_SCRIPT.LINE_HORIZONTAL: "tile_special_horizontal",
	SPECIAL_TILE_TYPE_SCRIPT.LINE_VERTICAL: "tile_special_vertical",
	SPECIAL_TILE_TYPE_SCRIPT.COLOR_BOMB: "tile_color_bomb",
}

const UI_ASSET_KEYS := {
	"board_frame": "ui_board_frame",
	"battle_hud_panel": "ui_battle_hud_panel",
	"enemy_panel": "ui_enemy_panel",
	"level_select_background": "ui_level_select_background",
	"level_select_panel": "ui_level_select_panel",
	"result_panel": "ui_result_panel",
	"round_modifier_panel": "ui_round_modifier_panel",
	"settings_background": "ui_settings_background",
	"settings_panel": "ui_settings_panel",
	"settings_window": "ui_settings_window",
	"shared_background": "ui_shared_background",
	"shared_back_button_default": "ui_shared_back_button_default",
	"shared_back_button_pressed": "ui_shared_back_button_pressed",
	"status_panel": "ui_status_panel",
	"toggle_off": "ui_toggle_off",
	"toggle_on": "ui_toggle_on",
	"zone_selector_panel": "ui_zone_selector_panel",
	"booster_panel": "ui_booster_panel",
	"booster_button_ready": "ui_booster_button_ready",
	"booster_button_disabled": "ui_booster_button_disabled",
	"booster_button_selected": "ui_booster_button_selected",
}

const BOOSTER_ASSET_KEYS := {
	"hammer": "booster_hammer",
	"freeze_time": "booster_freeze_time",
	"rocket_barrage": "booster_rocket_barrage",
}

const LEVEL_BUTTON_ASSET_KEYS := {
	"open": "ui_level_button_open",
	"locked": "ui_level_button_locked",
	"completed": "ui_level_button_completed",
}

const MAIN_MENU_BACKGROUND_ASSET_KEY := "main_menu_background"

const MAIN_MENU_BUTTON_ASSET_KEYS := {
	"play": {"default": "main_menu_button_play_default", "pressed": "main_menu_button_play_pressed"},
	"level_select": {"default": "main_menu_button_level_select_default", "pressed": "main_menu_button_level_select_pressed"},
	"shop": {"default": "main_menu_button_shop_default", "pressed": "main_menu_button_shop_pressed"},
	"settings": {"default": "main_menu_button_settings_default", "pressed": "main_menu_button_settings_pressed"},
}


static func get_background_asset_key(background_id: String) -> String:
	return BACKGROUND_ASSET_KEYS.get(background_id, "")


static func get_enemy_asset_key(enemy_id: String) -> String:
	return ENEMY_ASSET_KEYS.get(enemy_id, "")


static func get_tile_asset_key(tile_type: int) -> String:
	return TILE_ASSET_KEYS.get(tile_type, "")


static func get_special_tile_asset_key(special_type: int) -> String:
	return SPECIAL_TILE_ASSET_KEYS.get(special_type, "")


static func get_ui_asset_key(ui_id: String) -> String:
	return UI_ASSET_KEYS.get(ui_id, "")


static func get_booster_asset_key(booster_id: String) -> String:
	return BOOSTER_ASSET_KEYS.get(booster_id, "")


static func get_level_button_asset_key(state: String) -> String:
	return LEVEL_BUTTON_ASSET_KEYS.get(state, "")


static func get_star_asset_key(filled: bool) -> String:
	return "ui_star_filled" if filled else "ui_star_empty"


static func get_main_menu_background_asset_key() -> String:
	return MAIN_MENU_BACKGROUND_ASSET_KEY


static func get_main_menu_button_asset_key(button_id: String, state: String) -> String:
	var entry: Dictionary = MAIN_MENU_BUTTON_ASSET_KEYS.get(button_id, {})
	return entry.get(state, "")

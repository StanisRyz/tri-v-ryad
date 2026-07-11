extends RefCounted
class_name AssetKeyResolver

const TILE_TYPE_SCRIPT := preload("res://scripts/game/board/tile_type.gd")
const SPECIAL_TILE_TYPE_SCRIPT := preload("res://scripts/game/board/special_tile_type.gd")

const BACKGROUND_ASSET_KEYS := {
	"background_1": "background_1",
}

const ENEMY_ASSET_KEYS := {
	"enemy_1": "enemy_1_normal",
	"enemy_2": "enemy_2_normal",
	"enemy_3": "enemy_3_normal",
	"enemy_4": "enemy_4_normal",
	"enemy_5": "enemy_5_normal",
	"enemy_6": "enemy_6_normal",
	"enemy_7": "enemy_7_normal",
	"enemy_8": "enemy_8_normal",
	"enemy_9": "enemy_9_normal",
	"enemy_10": "enemy_10_normal",
}

const ENEMY_STATE_ASSET_KEYS := {
	"enemy_1": {"normal": "enemy_1_normal", "damaged": "enemy_1_damaged"},
	"enemy_2": {"normal": "enemy_2_normal", "damaged": "enemy_2_damaged"},
	"enemy_3": {"normal": "enemy_3_normal", "damaged": "enemy_3_damaged"},
	"enemy_4": {"normal": "enemy_4_normal", "damaged": "enemy_4_damaged"},
	"enemy_5": {"normal": "enemy_5_normal", "damaged": "enemy_5_damaged"},
	"enemy_6": {"normal": "enemy_6_normal", "damaged": "enemy_6_damaged"},
	"enemy_7": {"normal": "enemy_7_normal", "damaged": "enemy_7_damaged"},
	"enemy_8": {"normal": "enemy_8_normal", "damaged": "enemy_8_damaged"},
	"enemy_9": {"normal": "enemy_9_normal", "damaged": "enemy_9_damaged"},
	"enemy_10": {"normal": "enemy_10_normal", "damaged": "enemy_10_damaged"},
}

const ENEMY_PANEL_BACKGROUND_ASSET_KEYS := [
	"enemy_background_1",
	"enemy_background_2",
	"enemy_background_3",
	"enemy_background_4",
	"enemy_background_5",
]

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

## Stage 64.18 v0.1: ice obstacle overlay art — one texture for weak (1-layer)
## ice, one for strong (2-layer) ice. Same "key exists but PNG may not yet"
## pattern as every other not-yet-shipped asset here: GameAssetCatalog.
## try_load_texture_cached() safely returns null until real art is dropped in,
## so callers (TileView/BoardView) keep falling back to the existing
## placeholder color overlay until then.
const ICE_OVERLAY_ASSET_KEYS := {
	"weak": "tile_ice_overlay_weak",
	"strong": "tile_ice_overlay_strong",
}

## Stage 64.9 v0.1: per-base-color special crystal art — 3 special types x 5
## tile colors = 15 dedicated asset keys, one per (special_type, tile_type)
## pair. get_special_tile_asset_key() prefers this table when a tile_type is
## given and mapped; SPECIAL_TILE_ASSET_KEYS above remains the color-agnostic
## fallback for when a color-specific texture is missing or no tile_type is
## known.
const SPECIAL_TILE_COLOR_ASSET_KEYS := {
	SPECIAL_TILE_TYPE_SCRIPT.LINE_HORIZONTAL: {
		TILE_TYPE_SCRIPT.RED: "tile_special_horizontal_red",
		TILE_TYPE_SCRIPT.BLUE: "tile_special_horizontal_blue",
		TILE_TYPE_SCRIPT.GREEN: "tile_special_horizontal_green",
		TILE_TYPE_SCRIPT.YELLOW: "tile_special_horizontal_yellow",
		TILE_TYPE_SCRIPT.PURPLE: "tile_special_horizontal_purple",
	},
	SPECIAL_TILE_TYPE_SCRIPT.LINE_VERTICAL: {
		TILE_TYPE_SCRIPT.RED: "tile_special_vertical_red",
		TILE_TYPE_SCRIPT.BLUE: "tile_special_vertical_blue",
		TILE_TYPE_SCRIPT.GREEN: "tile_special_vertical_green",
		TILE_TYPE_SCRIPT.YELLOW: "tile_special_vertical_yellow",
		TILE_TYPE_SCRIPT.PURPLE: "tile_special_vertical_purple",
	},
	SPECIAL_TILE_TYPE_SCRIPT.COLOR_BOMB: {
		TILE_TYPE_SCRIPT.RED: "tile_color_bomb_red",
		TILE_TYPE_SCRIPT.BLUE: "tile_color_bomb_blue",
		TILE_TYPE_SCRIPT.GREEN: "tile_color_bomb_green",
		TILE_TYPE_SCRIPT.YELLOW: "tile_color_bomb_yellow",
		TILE_TYPE_SCRIPT.PURPLE: "tile_color_bomb_purple",
	},
}

## Stage 64.8 v0.1: line blast is a single shared texture — horizontal and
## vertical clears both use "effect_line_blast", with the vertical
## orientation produced by rotating the same texture 90 degrees at render
## time (see BoardView._create_line_blast_highlight()), not a second asset.
const EFFECT_ASSET_KEYS := {
	"line_blast": "effect_line_blast",
}

const UI_ASSET_KEYS := {
	"board_frame": "ui_board_frame",
	"board_background": "ui_board_background",
	"battle_hud_panel": "ui_battle_hud_panel",
	"enemy_panel": "ui_enemy_panel",
	"level_select_background": "ui_level_select_background",
	"level_select_panel": "ui_level_select_panel",
	"level_button_default": "ui_level_button_default",
	"level_button_locked": "ui_level_button_locked",
	"level_button_completed": "ui_level_button_completed",
	"level_button_locked_overlay": "ui_level_button_locked_overlay",
	"level_button_completed_overlay": "ui_level_button_completed_overlay",
	"level_button_pressed": "ui_level_button_pressed",
	"level_info_window": "ui_level_info_window",
	"level_info_window_0_stars": "ui_level_info_window_0_stars",
	"level_info_window_1_star": "ui_level_info_window_1_star",
	"level_info_window_2_stars": "ui_level_info_window_2_stars",
	"level_info_window_3_stars": "ui_level_info_window_3_stars",
	"result_panel": "ui_result_panel",
	"round_modifier_panel": "ui_round_modifier_panel",
	"settings_background": "ui_settings_background",
	"settings_panel": "ui_settings_panel",
	"settings_window": "ui_settings_window",
	"shop_window": "ui_shop_window",
	"shop_tab_default": "ui_shop_tab_default",
	"shop_tab_pressed": "ui_shop_tab_pressed",
	"shared_background": "ui_shared_background",
	"shared_back_button_default": "ui_shared_back_button_default",
	"shared_back_button_pressed": "ui_shared_back_button_pressed",
	"status_panel": "ui_status_panel",
	"toggle_off": "ui_toggle_off",
	"toggle_on": "ui_toggle_on",
	"zone_selector_panel": "ui_zone_selector_panel",
	"booster_panel": "ui_booster_panel",
	"booster_panel_background": "ui_booster_panel_background",
	"booster_button_ready": "ui_booster_button_ready",
	"booster_button_disabled": "ui_booster_button_disabled",
	"booster_button_selected": "ui_booster_button_selected",
	"lose_continue_window": "ui_lose_continue_window",
}

## Stage 65.17 v0.1: one square icon per LoseContinuePopup button, shown
## above the button itself (170x170, matching the button's 170px width).
const LOSE_CONTINUE_ICON_ASSET_KEYS := {
	"watch_ad": "lose_continue_icon_watch_ad",
	"buy_moves": "lose_continue_icon_buy_moves",
	"close": "lose_continue_icon_close",
}

const BOOSTER_ASSET_KEYS := {
	"hammer": "booster_hammer",
	"freeze_time": "booster_freeze_time",
	"rocket_barrage": "booster_rocket_barrage",
}

const LEVEL_BUTTON_ASSET_KEYS := {
	"open": "ui_level_button_default",
	"locked": "ui_level_button_locked",
	"completed": "ui_level_button_completed",
	"pressed": "ui_level_button_pressed",
}

const SHOP_BOOSTER_ICON_ASSET_KEYS := {
	"hammer": "shop_icon_booster_hammer",
	"freeze_time": "shop_icon_booster_freeze_time",
	"rocket_barrage": "shop_icon_booster_rocket_barrage",
}

## Dedicated Shop-tile-only booster icons (Stage 65.13) — separate from
## SHOP_BOOSTER_ICON_ASSET_KEYS above, which `BoosterPanel` (in-game) also
## reads; these live under ui/shop/boosters/ and are used only by
## `ShopBoosterTile`, so shop and in-game booster art can differ later.
const SHOP_BOOSTER_TILE_ICON_ASSET_KEYS := {
	"hammer": "shop_booster_tile_icon_hammer",
	"freeze_time": "shop_booster_tile_icon_freeze_time",
	"rocket_barrage": "shop_booster_tile_icon_rocket_barrage",
}

const SHOP_GEM_PRODUCT_ICON_ASSET_KEYS := {
	"gems_50": "shop_icon_gems_50",
	"gems_150": "shop_icon_gems_150",
	"gems_250": "shop_icon_gems_250",
	"gems_500": "shop_icon_gems_500",
}

const SHOP_BUNDLE_ICON_ASSET_KEYS := {
	"bundle_small": "shop_icon_bundle_small",
	"bundle_medium": "shop_icon_bundle_medium",
	"bundle_large": "shop_icon_bundle_large",
	"bundle_mega": "shop_icon_bundle_mega",
}

const SHOP_OFFER_ICON_ASSET_KEYS := {
	"offer_watch_ad": "shop_icon_offer_watch_ad",
	"offer_gems": "shop_icon_offer_gems",
	"offer_mega_gems": "shop_icon_offer_mega_gems",
	"offer_boosters": "shop_icon_offer_boosters",
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


static func get_enemy_normal_asset_key(enemy_id: String) -> String:
	return ENEMY_STATE_ASSET_KEYS.get(enemy_id, {}).get("normal", "")


static func get_enemy_damaged_asset_key(enemy_id: String) -> String:
	return ENEMY_STATE_ASSET_KEYS.get(enemy_id, {}).get("damaged", "")


static func get_enemy_panel_background_asset_keys() -> Array:
	return ENEMY_PANEL_BACKGROUND_ASSET_KEYS.duplicate()


static func get_tile_asset_key(tile_type: int) -> String:
	return TILE_ASSET_KEYS.get(tile_type, "")


## tile_type defaults to -1 (unknown/omitted): callers that only pass
## special_type keep getting the color-agnostic key (old behavior,
## unchanged). When a real tile_type is passed and it has a dedicated
## per-color entry in SPECIAL_TILE_COLOR_ASSET_KEYS, that key is preferred;
## otherwise this still falls back to the color-agnostic key.
static func get_special_tile_asset_key(special_type: int, tile_type: int = -1) -> String:
	if tile_type != -1:
		var color_keys: Dictionary = SPECIAL_TILE_COLOR_ASSET_KEYS.get(special_type, {})
		if color_keys.has(tile_type):
			return color_keys[tile_type]

	return SPECIAL_TILE_ASSET_KEYS.get(special_type, "")


static func get_ice_overlay_asset_key(is_strong: bool) -> String:
	return ICE_OVERLAY_ASSET_KEYS.get("strong" if is_strong else "weak", "")


static func get_effect_asset_key(effect_id: String) -> String:
	return EFFECT_ASSET_KEYS.get(effect_id, "")


static func get_ui_asset_key(ui_id: String) -> String:
	return UI_ASSET_KEYS.get(ui_id, "")


static func get_booster_asset_key(booster_id: String) -> String:
	return BOOSTER_ASSET_KEYS.get(booster_id, "")


static func get_level_button_asset_key(state: String) -> String:
	return LEVEL_BUTTON_ASSET_KEYS.get(state, "")


static func get_star_asset_key(filled: bool) -> String:
	return "ui_star_filled" if filled else "ui_star_empty"


static func get_shop_booster_icon_asset_key(booster_id: String) -> String:
	return SHOP_BOOSTER_ICON_ASSET_KEYS.get(booster_id, "")


static func get_shop_booster_tile_icon_asset_key(booster_id: String) -> String:
	return SHOP_BOOSTER_TILE_ICON_ASSET_KEYS.get(booster_id, "")


static func get_shop_gem_product_icon_asset_key(product_id: String) -> String:
	return SHOP_GEM_PRODUCT_ICON_ASSET_KEYS.get(product_id, "")


static func get_shop_bundle_icon_asset_key(bundle_id: String) -> String:
	return SHOP_BUNDLE_ICON_ASSET_KEYS.get(bundle_id, "")


static func get_shop_offer_icon_asset_key(offer_id: String) -> String:
	return SHOP_OFFER_ICON_ASSET_KEYS.get(offer_id, "")


static func get_main_menu_background_asset_key() -> String:
	return MAIN_MENU_BACKGROUND_ASSET_KEY


static func get_main_menu_button_asset_key(button_id: String, state: String) -> String:
	var entry: Dictionary = MAIN_MENU_BUTTON_ASSET_KEYS.get(button_id, {})
	return entry.get(state, "")


static func get_lose_continue_icon_asset_key(icon_id: String) -> String:
	return LOSE_CONTINUE_ICON_ASSET_KEYS.get(icon_id, "")

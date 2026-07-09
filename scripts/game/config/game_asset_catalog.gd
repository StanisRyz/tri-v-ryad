extends RefCounted
class_name GameAssetCatalog

const ASSET_MAP := {
	"background_1": "res://assets/images/backgrounds/background_1.png",
	"background_2": "res://assets/images/backgrounds/background_2.png",
	"background_3": "res://assets/images/backgrounds/background_3.png",
	"background_4": "res://assets/images/backgrounds/background_4.png",
	"background_5": "res://assets/images/backgrounds/background_5.png",
	"enemy_1_normal": "res://assets/images/ui/game/enemies/enemy_1_normal.png",
	"enemy_1_damaged": "res://assets/images/ui/game/enemies/enemy_1_damaged.png",
	"enemy_2_normal": "res://assets/images/ui/game/enemies/enemy_2_normal.png",
	"enemy_2_damaged": "res://assets/images/ui/game/enemies/enemy_2_damaged.png",
	"enemy_3_normal": "res://assets/images/ui/game/enemies/enemy_3_normal.png",
	"enemy_3_damaged": "res://assets/images/ui/game/enemies/enemy_3_damaged.png",
	"enemy_4_normal": "res://assets/images/ui/game/enemies/enemy_4_normal.png",
	"enemy_4_damaged": "res://assets/images/ui/game/enemies/enemy_4_damaged.png",
	"enemy_5_normal": "res://assets/images/ui/game/enemies/enemy_5_normal.png",
	"enemy_5_damaged": "res://assets/images/ui/game/enemies/enemy_5_damaged.png",
	"enemy_6_normal": "res://assets/images/ui/game/enemies/enemy_6_normal.png",
	"enemy_6_damaged": "res://assets/images/ui/game/enemies/enemy_6_damaged.png",
	"enemy_7_normal": "res://assets/images/ui/game/enemies/enemy_7_normal.png",
	"enemy_7_damaged": "res://assets/images/ui/game/enemies/enemy_7_damaged.png",
	"enemy_8_normal": "res://assets/images/ui/game/enemies/enemy_8_normal.png",
	"enemy_8_damaged": "res://assets/images/ui/game/enemies/enemy_8_damaged.png",
	"enemy_9_normal": "res://assets/images/ui/game/enemies/enemy_9_normal.png",
	"enemy_9_damaged": "res://assets/images/ui/game/enemies/enemy_9_damaged.png",
	"enemy_10_normal": "res://assets/images/ui/game/enemies/enemy_10_normal.png",
	"enemy_10_damaged": "res://assets/images/ui/game/enemies/enemy_10_damaged.png",
	"enemy_background_1": "res://assets/images/ui/game/enemy_panel/backgrounds/enemy_background_1.png",
	"enemy_background_2": "res://assets/images/ui/game/enemy_panel/backgrounds/enemy_background_2.png",
	"enemy_background_3": "res://assets/images/ui/game/enemy_panel/backgrounds/enemy_background_3.png",
	"enemy_background_4": "res://assets/images/ui/game/enemy_panel/backgrounds/enemy_background_4.png",
	"enemy_background_5": "res://assets/images/ui/game/enemy_panel/backgrounds/enemy_background_5.png",
	"tile_red": "res://assets/images/tiles/tile_red.png",
	"tile_blue": "res://assets/images/tiles/tile_blue.png",
	"tile_green": "res://assets/images/tiles/tile_green.png",
	"tile_yellow": "res://assets/images/tiles/tile_yellow.png",
	"tile_purple": "res://assets/images/tiles/tile_purple.png",
	"tile_special_horizontal": "res://assets/images/tiles/tile_special_horizontal.png",
	"tile_special_vertical": "res://assets/images/tiles/tile_special_vertical.png",
	"tile_color_bomb": "res://assets/images/tiles/tile_color_bomb.png",
	"ui_board_frame": "res://assets/images/ui/board_frame.png",
	"ui_battle_hud_panel": "res://assets/images/ui/battle_hud_panel.png",
	"ui_level_select_panel": "res://assets/images/ui/level_select_panel.png",
	"ui_level_select_background": "res://assets/images/ui/level_select/background.png",
	"ui_zone_selector_panel": "res://assets/images/ui/zone_selector_panel.png",
	"ui_level_button_default": "res://assets/images/ui/level_select/buttons/level_default.png",
	"ui_level_button_locked": "res://assets/images/ui/level_select/buttons/level_locked.png",
	"ui_level_button_completed": "res://assets/images/ui/level_select/buttons/level_completed.png",
	"ui_level_button_locked_overlay": "res://assets/images/ui/level_select/buttons/level_locked_overlay.png",
	"ui_level_button_completed_overlay": "res://assets/images/ui/level_select/buttons/level_completed_overlay.png",
	"ui_level_button_pressed": "res://assets/images/ui/level_select/buttons/level_pressed.png",
	"ui_level_info_window": "res://assets/images/ui/level_select/level_info_window.png",
	"ui_level_info_window_0_stars": "res://assets/images/ui/level_select/popup/level_info_0_stars.png",
	"ui_level_info_window_1_star": "res://assets/images/ui/level_select/popup/level_info_1_star.png",
	"ui_level_info_window_2_stars": "res://assets/images/ui/level_select/popup/level_info_2_stars.png",
	"ui_level_info_window_3_stars": "res://assets/images/ui/level_select/popup/level_info_3_stars.png",
	"ui_star_empty": "res://assets/images/ui/star_empty.png",
	"ui_star_filled": "res://assets/images/ui/star_filled.png",
	"ui_enemy_panel": "res://assets/images/ui/enemy_panel.png",
	"ui_result_panel": "res://assets/images/ui/result_panel.png",
	"ui_round_modifier_panel": "res://assets/images/ui/round_modifier_panel.png",
	"ui_status_panel": "res://assets/images/ui/status_panel.png",
	"ui_settings_background": "res://assets/images/ui/settings_background.png",
	"ui_settings_panel": "res://assets/images/ui/settings_panel.png",
	"ui_settings_window": "res://assets/images/ui/settings/settings_window.png",
	"ui_shop_window": "res://assets/images/ui/shop/shop_window.png",
	"ui_shop_tab_default": "res://assets/images/ui/shop/tabs/tabs_default.png",
	"ui_shop_tab_pressed": "res://assets/images/ui/shop/tabs/tabs_pressed.png",
	"shop_icon_booster_hammer": "res://assets/images/ui/icons/boosters/hammer.png",
	"shop_icon_booster_freeze_time": "res://assets/images/ui/icons/boosters/freeze_time.png",
	"shop_icon_booster_rocket_barrage": "res://assets/images/ui/icons/boosters/rocket_barrage.png",
	"shop_icon_gems_50": "res://assets/images/ui/shop/gems/gems_50.png",
	"shop_icon_gems_150": "res://assets/images/ui/shop/gems/gems_150.png",
	"shop_icon_gems_250": "res://assets/images/ui/shop/gems/gems_250.png",
	"shop_icon_gems_500": "res://assets/images/ui/shop/gems/gems_500.png",
	"shop_icon_bundle_small": "res://assets/images/ui/shop/bundles/bundle_small.png",
	"shop_icon_bundle_medium": "res://assets/images/ui/shop/bundles/bundle_medium.png",
	"shop_icon_bundle_large": "res://assets/images/ui/shop/bundles/bundle_large.png",
	"shop_icon_bundle_mega": "res://assets/images/ui/shop/bundles/bundle_mega.png",
	"ui_shared_background": "res://assets/images/ui/shared/background.png",
	"ui_shared_back_button_default": "res://assets/images/ui/shared/buttons/back_default.png",
	"ui_shared_back_button_pressed": "res://assets/images/ui/shared/buttons/back_pressed.png",
	"ui_toggle_on": "res://assets/images/ui/toggle_on.png",
	"ui_toggle_off": "res://assets/images/ui/toggle_off.png",
	"ui_booster_panel": "res://assets/images/ui/booster_panel.png",
	"ui_booster_panel_background": "res://assets/images/ui/game/booster_panel/background.png",
	"ui_booster_button_ready": "res://assets/images/ui/booster_button_ready.png",
	"ui_booster_button_disabled": "res://assets/images/ui/booster_button_disabled.png",
	"ui_booster_button_selected": "res://assets/images/ui/booster_button_selected.png",
	"booster_hammer": "res://assets/images/boosters/booster_hammer.png",
	"booster_freeze_time": "res://assets/images/boosters/booster_freeze_time.png",
	"booster_rocket_barrage": "res://assets/images/boosters/booster_rocket_barrage.png",
	"hero_1_portrait": "res://assets/images/heroes/hero_1_portrait.png",
	"hero_2_portrait": "res://assets/images/heroes/hero_2_portrait.png",
	"hero_3_portrait": "res://assets/images/heroes/hero_3_portrait.png",
	"hero_4_portrait": "res://assets/images/heroes/hero_4_portrait.png",
	"hero_5_portrait": "res://assets/images/heroes/hero_5_portrait.png",
	"main_menu_background": "res://assets/images/ui/main_menu/background.png",
	"main_menu_button_play_default": "res://assets/images/ui/main_menu/buttons/play_default.png",
	"main_menu_button_play_pressed": "res://assets/images/ui/main_menu/buttons/play_pressed.png",
	"main_menu_button_level_select_default": "res://assets/images/ui/main_menu/buttons/level_select_default.png",
	"main_menu_button_level_select_pressed": "res://assets/images/ui/main_menu/buttons/level_select_pressed.png",
	"main_menu_button_shop_default": "res://assets/images/ui/main_menu/buttons/shop_default.png",
	"main_menu_button_shop_pressed": "res://assets/images/ui/main_menu/buttons/shop_pressed.png",
	"main_menu_button_settings_default": "res://assets/images/ui/main_menu/buttons/settings_default.png",
	"main_menu_button_settings_pressed": "res://assets/images/ui/main_menu/buttons/settings_pressed.png",
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

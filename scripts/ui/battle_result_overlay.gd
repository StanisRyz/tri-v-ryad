extends Control
class_name BattleResultOverlay

## Stage 64.17 v0.1: reworked to match LevelInfoPopup's visual style — a
## star-dependent background window (ResultWindow, a FallbackImageSlot reusing
## the same level_info_window_{0,1,2,3}_stars art/asset keys) behind a top
## text area and two PressableTextureButtons that reuse the same shared
## back-button texture pair LevelInfoPopup's Start/Back buttons use.

signal restart_pressed
signal menu_pressed
signal next_level_pressed

const LEVEL_REWARD_FORMATTER_SCRIPT := preload("res://scripts/game/presentation/level_reward_formatter.gd")
const ASSET_KEY_RESOLVER_SCRIPT := preload("res://scripts/game/config/asset_key_resolver.gd")
const GAME_ASSET_CATALOG_SCRIPT := preload("res://scripts/game/config/game_asset_catalog.gd")
const TEXT_STYLE_APPLIER_SCRIPT := preload("res://scripts/ui/text/text_style_applier.gd")

@onready var top_label: Label = %TopLabel
@onready var result_window: FallbackImageSlot = %ResultWindow
@onready var retry_button: PressableTextureButton = %RetryButton
@onready var next_button: PressableTextureButton = %NextButton
@onready var menu_button: PressableTextureButton = %MenuButton


func _ready() -> void:
	_bind_shared_button_textures(retry_button)
	_bind_shared_button_textures(next_button)
	_bind_shared_button_textures(menu_button)
	retry_button.delayed_pressed.connect(_on_retry_button_pressed)
	next_button.delayed_pressed.connect(_on_next_button_pressed)
	menu_button.delayed_pressed.connect(_on_menu_button_pressed)
	hide_result()
	_localize_ui()
	_apply_text_styles()
	var localization_manager := get_node_or_null("/root/LocalizationManager")
	if localization_manager != null:
		localization_manager.language_changed.connect(_localize_ui)


func _apply_text_styles() -> void:
	TEXT_STYLE_APPLIER_SCRIPT.apply_to_label(top_label, "result.reward")
	TEXT_STYLE_APPLIER_SCRIPT.apply_to_child_label(retry_button, "TextMargin/Label", "result.button")
	TEXT_STYLE_APPLIER_SCRIPT.apply_to_child_label(next_button, "TextMargin/Label", "result.button")
	TEXT_STYLE_APPLIER_SCRIPT.apply_to_child_label(menu_button, "TextMargin/Label", "result.button")


func _localize_ui() -> void:
	var localization_manager := get_node_or_null("/root/LocalizationManager")
	if localization_manager == null:
		return
	retry_button.button_text = localization_manager.tr_key("ui.result.retry")
	next_button.button_text = localization_manager.tr_key("ui.result.next")
	menu_button.button_text = localization_manager.tr_key("ui.result.menu")


func show_victory_result(data: Dictionary) -> void:
	var stars_earned: int = clampi(int(data.get("stars_earned", 0)), 0, 3)
	var next_level_id := str(data.get("next_level_id", ""))
	var milestone_rewards: Array = data.get("milestone_rewards", [])

	_apply_result_window_texture(stars_earned)
	top_label.text = _format_victory_top_text(milestone_rewards)
	retry_button.visible = true
	next_button.visible = next_level_id != ""
	next_button.disabled = next_level_id == ""
	menu_button.visible = false
	menu_button.disabled = true
	visible = true


func show_defeat_result(_data: Dictionary) -> void:
	_apply_result_window_texture(0)
	top_label.text = ""
	retry_button.visible = true
	next_button.visible = false
	next_button.disabled = true
	menu_button.visible = true
	menu_button.disabled = false
	visible = true


func hide_result() -> void:
	visible = false


func _format_victory_top_text(milestone_rewards: Array) -> String:
	var localization_manager := get_node_or_null("/root/LocalizationManager")
	return LEVEL_REWARD_FORMATTER_SCRIPT.format_rewards_text(milestone_rewards, localization_manager)


## Mirrors LevelSelectScreen._get_popup_window_asset_id()/_apply_popup_window_texture()
## exactly, reusing the same level_info_window_{n}_stars asset keys/art so the
## result panel matches LevelInfoPopup's star-dependent background 1:1.
func _apply_result_window_texture(stars: int) -> void:
	result_window.texture = GAME_ASSET_CATALOG_SCRIPT.try_load_texture_cached(ASSET_KEY_RESOLVER_SCRIPT.get_ui_asset_key(_get_result_window_ui_id(stars)))


func _get_result_window_ui_id(stars: int) -> String:
	var clamped_stars: int = clampi(stars, 0, 3)
	match clamped_stars:
		0:
			return "level_info_window_0_stars"
		1:
			return "level_info_window_1_star"
		2:
			return "level_info_window_2_stars"
		_:
			return "level_info_window_3_stars"


func _bind_shared_button_textures(button: PressableTextureButton) -> void:
	if button.normal_texture == null:
		var normal_texture := GAME_ASSET_CATALOG_SCRIPT.try_load_texture_cached(ASSET_KEY_RESOLVER_SCRIPT.get_ui_asset_key("shared_back_button_default"))
		if normal_texture != null:
			button.set_normal_texture(normal_texture)

	if button.pressed_texture == null:
		var pressed_texture := GAME_ASSET_CATALOG_SCRIPT.try_load_texture_cached(ASSET_KEY_RESOLVER_SCRIPT.get_ui_asset_key("shared_back_button_pressed"))
		if pressed_texture != null:
			button.set_pressed_texture(pressed_texture)


func _on_retry_button_pressed() -> void:
	restart_pressed.emit()


func _on_next_button_pressed() -> void:
	next_level_pressed.emit()


func _on_menu_button_pressed() -> void:
	menu_pressed.emit()

extends Control

const GAME_ASSET_CATALOG := preload("res://scripts/game/config/game_asset_catalog.gd")
const ASSET_KEY_RESOLVER_SCRIPT := preload("res://scripts/game/config/asset_key_resolver.gd")
const CURRENCY_TYPE_SCRIPT := preload("res://scripts/game/economy/currency_type.gd")

signal play_pressed
signal level_select_pressed
signal shop_pressed
signal heroes_pressed
signal settings_pressed

@onready var background_rect: TextureRect = %Background
@onready var gold_label: Label = %GoldLabel
@onready var gems_label: Label = %GemsLabel
@onready var play_button: PressableTextureButton = %PlayButton
@onready var level_select_button: PressableTextureButton = %LevelSelectButton
@onready var shop_button: PressableTextureButton = %ShopButton
@onready var heroes_button: Button = %HeroesButton
@onready var settings_button: PressableTextureButton = %SettingsButton

var _progress_manager


func _ready() -> void:
	_apply_background_texture()
	_bind_button_textures()

	play_button.delayed_pressed.connect(_on_play_button_delayed_pressed)
	level_select_button.delayed_pressed.connect(_on_level_select_button_delayed_pressed)
	shop_button.delayed_pressed.connect(_on_shop_button_delayed_pressed)
	heroes_button.pressed.connect(_on_heroes_button_pressed)
	settings_button.delayed_pressed.connect(_on_settings_button_delayed_pressed)
	heroes_button.visible = FeatureFlags.HERO_SYSTEMS_ENABLED

	_refresh_wallet_labels()
	_localize_ui()
	var localization_manager := get_node_or_null("/root/LocalizationManager")
	if localization_manager != null:
		localization_manager.language_changed.connect(_localize_ui)


func set_progress_manager(progress_manager) -> void:
	_progress_manager = progress_manager
	if is_inside_tree():
		_refresh_wallet_labels()


func refresh_progress_state() -> void:
	_refresh_wallet_labels()


func _apply_background_texture() -> void:
	if background_rect == null or background_rect.texture != null:
		return
	var texture := GAME_ASSET_CATALOG.try_load_texture_cached(ASSET_KEY_RESOLVER_SCRIPT.get_main_menu_background_asset_key())
	if texture != null:
		background_rect.texture = texture


func _bind_button_textures() -> void:
	_bind_button_texture(play_button, "play")
	_bind_button_texture(level_select_button, "level_select")
	_bind_button_texture(shop_button, "shop")
	_bind_button_texture(settings_button, "settings")


func _bind_button_texture(button: PressableTextureButton, button_id: String) -> void:
	if button.normal_texture == null:
		var normal_key := ASSET_KEY_RESOLVER_SCRIPT.get_main_menu_button_asset_key(button_id, "default")
		var normal_texture := GAME_ASSET_CATALOG.try_load_texture_cached(normal_key)
		if normal_texture != null:
			button.set_normal_texture(normal_texture)

	if button.pressed_texture == null:
		var pressed_key := ASSET_KEY_RESOLVER_SCRIPT.get_main_menu_button_asset_key(button_id, "pressed")
		var pressed_texture := GAME_ASSET_CATALOG.try_load_texture_cached(pressed_key)
		if pressed_texture != null:
			button.set_pressed_texture(pressed_texture)


func _localize_ui() -> void:
	var localization_manager := get_node_or_null("/root/LocalizationManager")
	if localization_manager == null:
		return
	play_button.button_text = localization_manager.tr_key("ui.main.play")
	level_select_button.button_text = localization_manager.tr_key("ui.main.level_select")
	shop_button.button_text = localization_manager.tr_key("ui.main.shop")
	settings_button.button_text = localization_manager.tr_key("ui.main.settings")


func _refresh_wallet_labels() -> void:
	if gold_label == null or gems_label == null:
		return

	var gold := 0
	var gems := 0
	if _progress_manager != null:
		gold = _progress_manager.get_currency(CURRENCY_TYPE_SCRIPT.GOLD)
		gems = _progress_manager.get_currency(CURRENCY_TYPE_SCRIPT.GEMS)

	var localization_manager := get_node_or_null("/root/LocalizationManager")
	if localization_manager != null:
		gold_label.text = localization_manager.format_key("ui.common.gold", {"gold": gold})
		gems_label.text = localization_manager.format_key("ui.common.gems", {"gems": gems})
	else:
		gold_label.text = "Gold: %d" % gold
		gems_label.text = "Gems: %d" % gems


func _on_play_button_delayed_pressed() -> void:
	play_pressed.emit()


func _on_level_select_button_delayed_pressed() -> void:
	level_select_pressed.emit()


func _on_shop_button_delayed_pressed() -> void:
	shop_pressed.emit()


func _on_heroes_button_pressed() -> void:
	heroes_pressed.emit()


func _on_settings_button_delayed_pressed() -> void:
	settings_pressed.emit()

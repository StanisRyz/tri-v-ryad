extends Control
class_name LoseContinuePopup

## Stage 64.12/65.17 v0.1: shown before the normal 0-star defeat result when
## the player runs out of moves. Offers a placeholder rewarded-ad continue
## (+3 moves) or a gem-purchased continue (+5 moves for 5 gems), or lets the
## player close through to the existing defeat result unchanged.

signal watch_ad_pressed
signal buy_moves_pressed
signal close_pressed

const ASSET_KEY_RESOLVER_SCRIPT := preload("res://scripts/game/config/asset_key_resolver.gd")
const GAME_ASSET_CATALOG_SCRIPT := preload("res://scripts/game/config/game_asset_catalog.gd")

const TITLE_TEXT := "Проигрыш"

@onready var window: FallbackImageSlot = %Window
@onready var title_label: Label = %TitleLabel
@onready var feedback_label: Label = %FeedbackLabel
@onready var watch_ad_icon: FallbackImageSlot = %WatchAdIcon
@onready var buy_moves_icon: FallbackImageSlot = %BuyMovesIcon
@onready var close_icon: FallbackImageSlot = %CloseIcon
@onready var watch_ad_button: PressableTextureButton = %WatchAdButton
@onready var buy_moves_button: PressableTextureButton = %BuyMovesButton
@onready var close_button: PressableTextureButton = %CloseButton


func _ready() -> void:
	_bind_window_texture()
	_bind_icon_texture(watch_ad_icon, "watch_ad")
	_bind_icon_texture(buy_moves_icon, "buy_moves")
	_bind_icon_texture(close_icon, "close")
	_bind_shared_button_textures(watch_ad_button)
	_bind_shared_button_textures(buy_moves_button)
	_bind_shared_button_textures(close_button)
	watch_ad_button.delayed_pressed.connect(_on_watch_ad_button_pressed)
	buy_moves_button.delayed_pressed.connect(_on_buy_moves_button_pressed)
	close_button.delayed_pressed.connect(_on_close_button_pressed)
	title_label.text = TITLE_TEXT
	hide_popup()


func show_popup() -> void:
	feedback_label.text = ""
	visible = true


func hide_popup() -> void:
	visible = false


func show_feedback(message: String) -> void:
	feedback_label.text = message


func _bind_window_texture() -> void:
	if window.has_texture():
		return
	var texture := GAME_ASSET_CATALOG_SCRIPT.try_load_texture_cached(ASSET_KEY_RESOLVER_SCRIPT.get_ui_asset_key("lose_continue_window"))
	if texture != null:
		window.set_texture(texture)


func _bind_icon_texture(icon_slot: FallbackImageSlot, icon_id: String) -> void:
	if icon_slot.has_texture():
		return
	var texture := GAME_ASSET_CATALOG_SCRIPT.try_load_texture_cached(ASSET_KEY_RESOLVER_SCRIPT.get_lose_continue_icon_asset_key(icon_id))
	if texture != null:
		icon_slot.set_texture(texture)


func _bind_shared_button_textures(button: PressableTextureButton) -> void:
	if button.normal_texture == null:
		var normal_texture := GAME_ASSET_CATALOG_SCRIPT.try_load_texture_cached(ASSET_KEY_RESOLVER_SCRIPT.get_ui_asset_key("shared_back_button_default"))
		if normal_texture != null:
			button.set_normal_texture(normal_texture)

	if button.pressed_texture == null:
		var pressed_texture := GAME_ASSET_CATALOG_SCRIPT.try_load_texture_cached(ASSET_KEY_RESOLVER_SCRIPT.get_ui_asset_key("shared_back_button_pressed"))
		if pressed_texture != null:
			button.set_pressed_texture(pressed_texture)


func _on_watch_ad_button_pressed() -> void:
	watch_ad_pressed.emit()


func _on_buy_moves_button_pressed() -> void:
	buy_moves_pressed.emit()


func _on_close_button_pressed() -> void:
	close_pressed.emit()

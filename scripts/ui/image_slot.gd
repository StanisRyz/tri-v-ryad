extends ColorRect
class_name ImageSlot

const GAME_ASSET_CATALOG := preload("res://scripts/game/config/game_asset_catalog.gd")

@export var asset_key := ""
@export var placeholder_color := Color(0.25, 0.25, 0.3, 1.0)
@export var show_fallback_behind_texture := false
@export var expand_mode := TextureRect.EXPAND_IGNORE_SIZE
@export var stretch_mode := TextureRect.STRETCH_KEEP_ASPECT_CENTERED

var _texture_rect: TextureRect = null


func _ready() -> void:
	_ensure_texture_rect()
	refresh()


func set_asset_key(new_asset_key: String) -> void:
	asset_key = new_asset_key
	refresh()


func get_asset_key() -> String:
	return asset_key


func set_texture(texture: Texture2D) -> void:
	_ensure_texture_rect()
	_texture_rect.texture = texture
	_update_visual_state()


func clear_texture() -> void:
	_ensure_texture_rect()
	_texture_rect.texture = null
	_update_visual_state()


func set_placeholder_color(new_color: Color) -> void:
	placeholder_color = new_color
	_update_visual_state()


func set_show_fallback_behind_texture(value: bool) -> void:
	show_fallback_behind_texture = value
	_update_visual_state()


func refresh() -> void:
	_ensure_texture_rect()
	if asset_key == "":
		clear_texture()
		return

	set_texture(GAME_ASSET_CATALOG.try_load_texture(asset_key))


func has_texture() -> bool:
	_ensure_texture_rect()
	return _texture_rect.texture != null


func _ensure_texture_rect() -> void:
	if _texture_rect != null and is_instance_valid(_texture_rect):
		return

	_texture_rect = TextureRect.new()
	_texture_rect.name = "Texture"
	_texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_texture_rect.expand_mode = expand_mode
	_texture_rect.stretch_mode = stretch_mode
	_texture_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_texture_rect.offset_left = 0.0
	_texture_rect.offset_top = 0.0
	_texture_rect.offset_right = 0.0
	_texture_rect.offset_bottom = 0.0
	add_child(_texture_rect)


func _update_visual_state() -> void:
	_ensure_texture_rect()
	_texture_rect.expand_mode = expand_mode
	_texture_rect.stretch_mode = stretch_mode
	_texture_rect.visible = _texture_rect.texture != null
	color = placeholder_color if not has_texture() or show_fallback_behind_texture else Color(0.0, 0.0, 0.0, 0.0)

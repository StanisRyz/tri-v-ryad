@tool
extends Control
class_name FallbackImageSlot

## Reusable image slot: shows `texture` when assigned, otherwise a solid
## `placeholder_color` fallback rect. Works in the editor (via @tool) and at
## runtime, so scenes that reference not-yet-created art stay visibly
## editable instead of rendering blank.
##
## Child lookup/creation only happens once, from _ready(), never from an
## exported-property setter, mirroring PressableTextureButton: this avoids
## racing tscn-declared children during scene instantiation.

@export var texture: Texture2D:
	set(value):
		texture = value
		_update_visual()

@export var placeholder_color: Color = Color(0.2, 0.22, 0.3, 1.0):
	set(value):
		placeholder_color = value
		_update_visual()

@export var expand_mode: TextureRect.ExpandMode = TextureRect.EXPAND_IGNORE_SIZE:
	set(value):
		expand_mode = value
		_update_visual()

@export var stretch_mode: TextureRect.StretchMode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED:
	set(value):
		stretch_mode = value
		_update_visual()

var _fallback_rect: ColorRect
var _texture_rect: TextureRect
var _ready_done := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ensure_children()
	_ready_done = true
	_update_visual()


func set_texture(value: Texture2D) -> void:
	texture = value


func has_texture() -> bool:
	return texture != null


func _ensure_children() -> void:
	if _fallback_rect == null:
		_fallback_rect = get_node_or_null("Fallback") as ColorRect
		if _fallback_rect == null:
			_fallback_rect = ColorRect.new()
			_fallback_rect.name = "Fallback"
			_fallback_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_fallback_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
			add_child(_fallback_rect)
			_own_created_node(_fallback_rect)

	if _texture_rect == null:
		_texture_rect = get_node_or_null("TextureDisplay") as TextureRect
		if _texture_rect == null:
			_texture_rect = TextureRect.new()
			_texture_rect.name = "TextureDisplay"
			_texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_texture_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
			add_child(_texture_rect)
			_own_created_node(_texture_rect)


func _own_created_node(node: Node) -> void:
	if not Engine.is_editor_hint():
		return
	if not is_inside_tree():
		return
	var edited_root := get_tree().edited_scene_root
	node.owner = edited_root if edited_root != null else owner


func _update_visual() -> void:
	if not _ready_done:
		return
	_texture_rect.texture = texture
	_texture_rect.expand_mode = expand_mode
	_texture_rect.stretch_mode = stretch_mode
	_fallback_rect.color = placeholder_color
	_fallback_rect.visible = texture == null

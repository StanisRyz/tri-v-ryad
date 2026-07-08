@tool
extends Button
class_name LevelMapButton

## Reusable level-map button: shows the texture for the current `state`
## (locked/open/completed) and falls back to a solid fallback_*_color rect
## when that state's texture is missing, so a button never renders blank.
## `pressed_texture` is reserved for a future press animation and is not
## swapped in during this stage.
##
## Mirrors ShopTabButton's structure/lifecycle: children are only ever
## looked up/created once from _ready(), never from an exported-property
## setter, so tscn-declared children are never raced/renamed. Existing
## scene Label Inspector settings stay the source of truth once the Label
## node exists; only a freshly-created Label gets the v0.1 defaults.

const STATE_LOCKED := "locked"
const STATE_OPEN := "open"
const STATE_COMPLETED := "completed"

@export var locked_texture: Texture2D:
	set(value):
		locked_texture = value
		_update_visual()

@export var open_texture: Texture2D:
	set(value):
		open_texture = value
		_update_visual()

@export var completed_texture: Texture2D:
	set(value):
		completed_texture = value
		_update_visual()

@export var pressed_texture: Texture2D

@export var level_text: String = "":
	set(value):
		level_text = value
		_update_label()

@export_enum("locked", "open", "completed") var state: String = STATE_LOCKED:
	set(value):
		state = value
		_update_visual()

@export var fallback_locked_color: Color = Color(0.22, 0.24, 0.32, 1.0):
	set(value):
		fallback_locked_color = value
		_update_visual()

@export var fallback_open_color: Color = Color(0.24, 0.42, 0.3, 1.0):
	set(value):
		fallback_open_color = value
		_update_visual()

@export var fallback_completed_color: Color = Color(0.55, 0.45, 0.16, 1.0):
	set(value):
		fallback_completed_color = value
		_update_visual()

@export var fallback_pressed_color: Color = Color(0.35, 0.5, 0.32, 1.0)

@export var text_font_size: int = 26:
	set(value):
		text_font_size = value
		_update_label_font_size()

const LABEL_FONT_COLOR := Color(1, 1, 1, 1)
const LABEL_OUTLINE_COLOR := Color(0, 0, 0, 1)
const LABEL_OUTLINE_SIZE := 4

var _fallback_rect: ColorRect
var _texture_rect: TextureRect
var _text_zone: MarginContainer
var _label: Label
var _ready_done := false


func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	flat = true
	_clear_button_visuals()
	_ensure_children()
	_ready_done = true
	_update_visual()
	_update_label()
	_update_label_font_size()


func set_level_state(value: String) -> void:
	state = value


func set_level_text(value: String) -> void:
	level_text = value


func _clear_button_visuals() -> void:
	var empty_style := StyleBoxEmpty.new()
	add_theme_stylebox_override("normal", empty_style)
	add_theme_stylebox_override("hover", empty_style)
	add_theme_stylebox_override("pressed", empty_style)
	add_theme_stylebox_override("disabled", empty_style)
	add_theme_stylebox_override("focus", empty_style)
	add_theme_color_override("font_color", Color(0, 0, 0, 0))
	add_theme_color_override("font_hover_color", Color(0, 0, 0, 0))
	add_theme_color_override("font_pressed_color", Color(0, 0, 0, 0))
	add_theme_color_override("font_focus_color", Color(0, 0, 0, 0))
	add_theme_color_override("font_disabled_color", Color(0, 0, 0, 0))
	text = ""


func _ensure_children() -> void:
	if _fallback_rect == null:
		_fallback_rect = get_node_or_null("Fallback") as ColorRect
		if _fallback_rect == null:
			_fallback_rect = ColorRect.new()
			_fallback_rect.name = "Fallback"
			_fallback_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_fallback_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
			add_child(_fallback_rect)
			move_child(_fallback_rect, 0)
			_own_created_node(_fallback_rect)

	if _texture_rect == null:
		_texture_rect = get_node_or_null("ButtonTexture") as TextureRect
		if _texture_rect == null:
			_texture_rect = TextureRect.new()
			_texture_rect.name = "ButtonTexture"
			_texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			_texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
			_texture_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
			add_child(_texture_rect)
			_own_created_node(_texture_rect)

	if _text_zone == null:
		_text_zone = get_node_or_null("TextMargin") as MarginContainer
		if _text_zone == null:
			_text_zone = MarginContainer.new()
			_text_zone.name = "TextMargin"
			_text_zone.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_text_zone.set_anchors_preset(Control.PRESET_FULL_RECT)
			add_child(_text_zone)
			_own_created_node(_text_zone)

	if _label == null:
		_label = _text_zone.get_node_or_null("Label") as Label
		if _label == null:
			_label = Label.new()
			_label.name = "Label"
			_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
			_label.add_theme_color_override("font_color", LABEL_FONT_COLOR)
			_label.add_theme_color_override("font_outline_color", LABEL_OUTLINE_COLOR)
			_label.add_theme_constant_override("outline_size", LABEL_OUTLINE_SIZE)
			_text_zone.add_child(_label)
			_own_created_node(_label)


func _own_created_node(node: Node) -> void:
	if not Engine.is_editor_hint():
		return
	if not is_inside_tree():
		return
	var edited_root := get_tree().edited_scene_root
	node.owner = edited_root if edited_root != null else owner


func _get_active_texture() -> Texture2D:
	match state:
		STATE_OPEN:
			return open_texture
		STATE_COMPLETED:
			return completed_texture
		_:
			return locked_texture


func _get_active_fallback_color() -> Color:
	match state:
		STATE_OPEN:
			return fallback_open_color
		STATE_COMPLETED:
			return fallback_completed_color
		_:
			return fallback_locked_color


func _update_visual() -> void:
	if not _ready_done:
		return
	var active_texture := _get_active_texture()
	_texture_rect.texture = active_texture
	_fallback_rect.color = _get_active_fallback_color()
	_fallback_rect.visible = active_texture == null


func _update_label() -> void:
	if not _ready_done:
		return
	_label.text = level_text


func _update_label_font_size() -> void:
	if not _ready_done:
		return
	_label.add_theme_font_size_override("font_size", text_font_size)

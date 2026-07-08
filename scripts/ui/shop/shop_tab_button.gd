@tool
extends Button
class_name ShopTabButton

## Reusable shop tab button: shows default_texture when inactive and
## selected_texture persistently while is_selected is true (not a temporary
## press animation like PressableTextureButton). Falls back to a solid
## placeholder color — fallback_default_color/fallback_selected_color — when
## the relevant texture is missing, so a tab never renders blank.
##
## Child lookup/creation only ever happens once, from _ready(), mirroring
## PressableTextureButton, so tscn-declared children are never raced/renamed.
## Label settings from the Inspector are the source of truth once the
## Label node exists in the scene; only a freshly-created Label gets the
## v0.1 defaults.

@export var default_texture: Texture2D:
	set(value):
		default_texture = value
		_update_visual()

@export var selected_texture: Texture2D:
	set(value):
		selected_texture = value
		_update_visual()

@export var button_text: String = "":
	set(value):
		button_text = value
		_update_label()

@export var is_selected: bool = false:
	set(value):
		is_selected = value
		_update_visual()

@export var fallback_default_color: Color = Color(0.22, 0.24, 0.32, 1.0):
	set(value):
		fallback_default_color = value
		_update_visual()

@export var fallback_selected_color: Color = Color(0.35, 0.5, 0.32, 1.0):
	set(value):
		fallback_selected_color = value
		_update_visual()

@export var text_font_size: int = 20:
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


func set_selected(value: bool) -> void:
	is_selected = value


func set_button_text(value: String) -> void:
	button_text = value


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


func _update_visual() -> void:
	if not _ready_done:
		return
	var active_texture := selected_texture if is_selected else default_texture
	_texture_rect.texture = active_texture
	_fallback_rect.color = fallback_selected_color if is_selected else fallback_default_color
	_fallback_rect.visible = active_texture == null


func _update_label() -> void:
	if not _ready_done:
		return
	_label.text = button_text


func _update_label_font_size() -> void:
	if not _ready_done:
		return
	_label.add_theme_font_size_override("font_size", text_font_size)

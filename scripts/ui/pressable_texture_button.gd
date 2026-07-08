@tool
extends Button
class_name PressableTextureButton

## Reusable image button: shows normal_texture, swaps to pressed_texture for
## press_duration seconds on click, then emits delayed_pressed after restoring
## normal_texture. Falls back to a solid placeholder color when a texture is
## missing so the button never renders blank or crashes.
##
## Button art (ButtonTexture) and button text (TextMargin/Label) are separate
## child nodes so texture assets stay art-only and text stays a real Label.
## @tool lets the editor build/preview these children and normal_texture
## without running the game, so the scene can be laid out and saved with the
## child nodes present. Because TextMargin/Label are children of the button
## (not screen-level nodes), text always follows the button when it is moved
## or resized in the Inspector.

signal delayed_pressed

@export var normal_texture: Texture2D:
	set(value):
		normal_texture = value
		_update_visual()

@export var pressed_texture: Texture2D:
	set(value):
		pressed_texture = value

@export var press_duration: float = 0.2

@export var button_text: String = "":
	set(value):
		button_text = value
		_update_label()

@export var placeholder_color: Color = Color(0.22, 0.24, 0.32, 1.0):
	set(value):
		placeholder_color = value
		_update_visual()

@export var text_font_size: int = 30:
	set(value):
		text_font_size = value
		_update_label_font_size()

@export var text_margin_left: float = 0.0:
	set(value):
		text_margin_left = value
		_update_text_margins()

@export var text_margin_top: float = 0.0:
	set(value):
		text_margin_top = value
		_update_text_margins()

@export var text_margin_right: float = 0.0:
	set(value):
		text_margin_right = value
		_update_text_margins()

@export var text_margin_bottom: float = 0.0:
	set(value):
		text_margin_bottom = value
		_update_text_margins()

@export var pressed_text_offset: Vector2 = Vector2(0, 3)

var _placeholder_rect: ColorRect
var _texture_rect: TextureRect
var _text_zone: MarginContainer
var _label: Label
var _animation_pending := false


func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	flat = true
	_clear_button_visuals()
	_ensure_children()
	_update_visual()
	_update_label()
	_update_label_font_size()
	_update_text_margins()
	if not Engine.is_editor_hint():
		pressed.connect(_on_pressed)


func set_normal_texture(texture: Texture2D) -> void:
	normal_texture = texture


func set_pressed_texture(texture: Texture2D) -> void:
	pressed_texture = texture


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
	if _placeholder_rect == null:
		_placeholder_rect = get_node_or_null("Placeholder") as ColorRect
		if _placeholder_rect == null:
			_placeholder_rect = ColorRect.new()
			_placeholder_rect.name = "Placeholder"
			_placeholder_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_placeholder_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
			add_child(_placeholder_rect)
			move_child(_placeholder_rect, 0)
			_own_created_node(_placeholder_rect)

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
	_ensure_children()
	_texture_rect.texture = normal_texture
	_placeholder_rect.color = placeholder_color
	_placeholder_rect.visible = normal_texture == null


func _update_label() -> void:
	_ensure_children()
	_label.text = button_text


func _update_label_font_size() -> void:
	_ensure_children()
	_label.add_theme_font_size_override("font_size", text_font_size)


func _update_text_margins() -> void:
	_ensure_children()
	_text_zone.add_theme_constant_override("margin_left", int(text_margin_left))
	_text_zone.add_theme_constant_override("margin_top", int(text_margin_top))
	_text_zone.add_theme_constant_override("margin_right", int(text_margin_right))
	_text_zone.add_theme_constant_override("margin_bottom", int(text_margin_bottom))


func _on_pressed() -> void:
	if _animation_pending:
		return
	_animation_pending = true
	_play_pressed_animation()


func _play_pressed_animation() -> void:
	_ensure_children()
	_texture_rect.texture = pressed_texture if pressed_texture != null else normal_texture
	_placeholder_rect.visible = pressed_texture == null and normal_texture == null
	var text_zone_base_position := _text_zone.position
	_text_zone.position = text_zone_base_position + pressed_text_offset

	await get_tree().create_timer(press_duration).timeout

	_texture_rect.texture = normal_texture
	_placeholder_rect.visible = normal_texture == null
	_text_zone.position = text_zone_base_position
	_animation_pending = false
	delayed_pressed.emit()

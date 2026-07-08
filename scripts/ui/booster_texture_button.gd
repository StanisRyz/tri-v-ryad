@tool
extends Button
class_name BoosterTextureButton

## Square, texture-based booster control. Shows `default_texture` normally,
## swapping to `selected_texture`/`disabled_texture` for those states (falling
## back to a colored rect plus a `StateFilter` tint when a texture is missing),
## with `CountLabel` always rendered as a bottom-center overlay.

@export var booster_id: String = ""

@export var default_texture: Texture2D:
	set(value):
		default_texture = value
		_update_visual()

@export var disabled_texture: Texture2D:
	set(value):
		disabled_texture = value
		_update_visual()

@export var selected_texture: Texture2D:
	set(value):
		selected_texture = value
		_update_visual()

@export var count_text: String = "x0":
	set(value):
		count_text = value
		_update_visual()

@export var is_selected: bool = false:
	set(value):
		is_selected = value
		_update_visual()

@export var is_disabled_state: bool = false:
	set(value):
		is_disabled_state = value
		_update_visual()

@export var fallback_ready_color: Color = Color(0.18, 0.2, 0.24, 1.0):
	set(value):
		fallback_ready_color = value
		_update_visual()

@export var fallback_disabled_color: Color = Color(0.12, 0.12, 0.14, 1.0):
	set(value):
		fallback_disabled_color = value
		_update_visual()

@export var fallback_selected_color: Color = Color(0.22, 0.26, 0.16, 1.0):
	set(value):
		fallback_selected_color = value
		_update_visual()

@export var disabled_filter_color: Color = Color(0.0, 0.0, 0.0, 0.45):
	set(value):
		disabled_filter_color = value
		_update_visual()

@export var selected_filter_color: Color = Color(1.0, 0.85, 0.3, 0.35):
	set(value):
		selected_filter_color = value
		_update_visual()

var _fallback: ColorRect
var _button_texture: TextureRect
var _state_filter: ColorRect
var _count_label: Label
var _ready_done := false
var _feedback_tween: Tween


func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	_ensure_children()
	_ready_done = true
	_update_visual()


func set_count(value: int) -> void:
	count_text = "x%d" % maxi(value, 0)


func play_feedback(animations_enabled: bool = true, reduced_motion_enabled: bool = false) -> void:
	if _feedback_tween != null:
		_feedback_tween.kill()
		_feedback_tween = null

	pivot_offset = size * 0.5
	if not animations_enabled:
		return

	var pulse_scale := Vector2(1.05, 1.05) if reduced_motion_enabled else Vector2(1.10, 1.10)
	var base_scale := Vector2(1.04, 1.04) if is_selected else Vector2.ONE
	var pulse_duration := 0.05 if reduced_motion_enabled else 0.08
	var settle_duration := 0.08 if reduced_motion_enabled else 0.12
	_feedback_tween = create_tween()
	_feedback_tween.tween_property(self, "scale", pulse_scale, pulse_duration)
	_feedback_tween.parallel().tween_property(self, "modulate", Color(1.0, 0.92, 0.42, 1.0), pulse_duration)
	_feedback_tween.tween_property(self, "scale", base_scale, settle_duration)
	_feedback_tween.parallel().tween_property(self, "modulate", Color.WHITE, settle_duration)
	_feedback_tween.finished.connect(func() -> void:
		_feedback_tween = null
	)


func _ensure_children() -> void:
	if _fallback == null:
		_fallback = get_node_or_null("Fallback") as ColorRect
		if _fallback == null:
			_fallback = ColorRect.new()
			_fallback.name = "Fallback"
			_fallback.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_fallback.set_anchors_preset(Control.PRESET_FULL_RECT)
			add_child(_fallback)
			_own_created_node(_fallback)

	if _button_texture == null:
		_button_texture = get_node_or_null("ButtonTexture") as TextureRect
		if _button_texture == null:
			_button_texture = TextureRect.new()
			_button_texture.name = "ButtonTexture"
			_button_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_button_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			_button_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			_button_texture.set_anchors_preset(Control.PRESET_FULL_RECT)
			add_child(_button_texture)
			_own_created_node(_button_texture)

	if _state_filter == null:
		_state_filter = get_node_or_null("StateFilter") as ColorRect
		if _state_filter == null:
			_state_filter = ColorRect.new()
			_state_filter.name = "StateFilter"
			_state_filter.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_state_filter.set_anchors_preset(Control.PRESET_FULL_RECT)
			add_child(_state_filter)
			_own_created_node(_state_filter)

	if _count_label == null:
		_count_label = get_node_or_null("CountLabel") as Label
		if _count_label == null:
			_count_label = Label.new()
			_count_label.name = "CountLabel"
			_count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_count_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
			_count_label.offset_top = -22.0
			_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			_count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			_count_label.add_theme_font_size_override("font_size", 16)
			add_child(_count_label)
			_own_created_node(_count_label)


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

	var active_texture: Texture2D = default_texture
	var fallback_color := fallback_ready_color
	if is_selected and selected_texture != null:
		active_texture = selected_texture
	elif is_disabled_state and disabled_texture != null:
		active_texture = disabled_texture

	if is_disabled_state:
		fallback_color = fallback_disabled_color
	elif is_selected:
		fallback_color = fallback_selected_color

	_button_texture.texture = active_texture
	_fallback.color = fallback_color
	_fallback.visible = active_texture == null

	if is_disabled_state:
		_state_filter.color = disabled_filter_color
		_state_filter.visible = true
	elif is_selected:
		_state_filter.color = selected_filter_color
		_state_filter.visible = true
	else:
		_state_filter.visible = false

	_count_label.text = count_text

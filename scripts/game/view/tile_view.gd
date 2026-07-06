extends Button
class_name TileView

signal tile_pressed(cell: Vector2i)
signal tile_drag_released(cell: Vector2i, drag_delta: Vector2)

const SPECIAL_TILE_DATA_SCRIPT := preload("res://scripts/game/board/special_tile_data.gd")
const SPECIAL_TILE_TYPE_SCRIPT := preload("res://scripts/game/board/special_tile_type.gd")
const ASSET_KEY_RESOLVER_SCRIPT := preload("res://scripts/game/config/asset_key_resolver.gd")
const GAME_ASSET_CATALOG := preload("res://scripts/game/config/game_asset_catalog.gd")

const TILE_COLORS := {
	TileType.RED: Color(0.86, 0.22, 0.22, 1.0),
	TileType.BLUE: Color(0.18, 0.42, 0.88, 1.0),
	TileType.GREEN: Color(0.16, 0.66, 0.36, 1.0),
	TileType.YELLOW: Color(0.92, 0.76, 0.20, 1.0),
	TileType.PURPLE: Color(0.56, 0.28, 0.82, 1.0),
}

static var _animations_enabled := true
static var _reduced_motion_enabled := false

var board_cell := Vector2i.ZERO
var tile_type := BoardModel.EMPTY
var special_tile_data
var _is_selected := false
var _is_highlighted := false
var _is_invalid_feedback := false
var _press_start_position := Vector2.ZERO
var _has_press_start := false
var _suppress_next_pressed := false
var _active_tween: Tween


static func configure_presentation(animations_enabled: bool, reduced_motion_enabled: bool) -> void:
	_animations_enabled = animations_enabled
	_reduced_motion_enabled = reduced_motion_enabled


func _ready() -> void:
	custom_minimum_size = Vector2(48, 48)
	focus_mode = Control.FOCUS_NONE
	expand_icon = true
	gui_input.connect(_on_gui_input)
	if not pressed.is_connected(_on_pressed):
		pressed.connect(_on_pressed)
	_apply_visuals()


func set_tile(cell: Vector2i, new_tile_type: int) -> void:
	board_cell = cell
	tile_type = new_tile_type
	_apply_visuals()


func set_special_tile(special_data) -> void:
	if special_data is SPECIAL_TILE_DATA_SCRIPT:
		special_tile_data = special_data.duplicate_data()
	else:
		special_tile_data = null
	_apply_visuals()


func set_selected(selected: bool) -> void:
	_is_selected = selected
	_apply_visuals()


func set_highlighted(enabled: bool) -> void:
	_is_highlighted = enabled
	if enabled:
		_is_invalid_feedback = false
	_apply_visuals()


func set_invalid_feedback(enabled: bool) -> void:
	_is_invalid_feedback = enabled
	if enabled:
		_is_highlighted = false
	_apply_visuals()


func play_flash() -> void:
	set_highlighted(true)
	_play_flash_tween(Color(1.25, 1.25, 1.25, 1.0), Vector2(1.07, 1.07))


func play_invalid_flash() -> void:
	set_invalid_feedback(true)
	_play_flash_tween(Color(1.25, 0.55, 0.55, 1.0), Vector2(1.04, 1.04))


func play_swap_pulse() -> void:
	_play_flash_tween(Color(1.18, 1.18, 1.18, 1.0), Vector2(1.08, 1.08))


func play_invalid_pulse() -> void:
	set_invalid_feedback(true)
	_play_flash_tween(Color(1.30, 0.48, 0.45, 1.0), Vector2(0.94, 0.94))


func play_match_fade() -> void:
	_stop_active_tween()
	visible = true
	pivot_offset = size * 0.5
	modulate = Color.WHITE
	scale = Vector2.ONE
	var fade_scale := _adjust_scale(Vector2(0.88, 0.88))
	var step_duration := _adjust_duration(0.10)
	_active_tween = create_tween()
	_active_tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 0.22), step_duration)
	_active_tween.parallel().tween_property(self, "scale", fade_scale, step_duration)
	_active_tween.tween_property(self, "modulate", Color.WHITE, step_duration)
	_active_tween.parallel().tween_property(self, "scale", Vector2.ONE, step_duration)


func play_match_clear(duration: float = 0.16) -> void:
	_stop_active_tween()
	visible = true
	pivot_offset = size * 0.5
	modulate = Color.WHITE
	scale = Vector2.ONE
	var step_duration: float = _adjust_duration(maxf(duration / 3.0, 0.01))
	var clear_scale := _adjust_scale(Vector2(1.14, 1.14))
	var fade_scale := _adjust_scale(Vector2(0.72, 0.72))
	modulate = _adjust_color(Color(1.35, 1.35, 1.35, 1.0))
	scale = clear_scale
	_active_tween = create_tween()
	_active_tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 0.18), step_duration)
	_active_tween.parallel().tween_property(self, "scale", fade_scale, step_duration)
	_active_tween.tween_property(self, "modulate", Color.WHITE, step_duration)
	_active_tween.parallel().tween_property(self, "scale", Vector2.ONE, step_duration)


func play_special_flash() -> void:
	set_highlighted(true)
	_play_flash_tween(Color(1.35, 1.08, 0.45, 1.0), Vector2(1.12, 1.12))


func play_special_clear(duration: float = 0.18) -> void:
	set_highlighted(true)
	_stop_active_tween()
	visible = true
	pivot_offset = size * 0.5
	modulate = Color.WHITE
	scale = Vector2.ONE
	var step_duration: float = _adjust_duration(maxf(duration / 3.0, 0.01))
	var burst_scale := _adjust_scale(Vector2(1.20, 1.20))
	var fade_scale := _adjust_scale(Vector2(0.78, 0.78))
	modulate = _adjust_color(Color(1.45, 1.18, 0.42, 1.0))
	scale = burst_scale
	_active_tween = create_tween()
	_active_tween.tween_property(self, "modulate", Color(1.0, 0.92, 0.46, 0.26), step_duration)
	_active_tween.parallel().tween_property(self, "scale", fade_scale, step_duration)
	_active_tween.tween_property(self, "modulate", Color.WHITE, step_duration)
	_active_tween.parallel().tween_property(self, "scale", Vector2.ONE, step_duration)


func play_invalid_bounce(_offset: Vector2, step_duration: float = 0.04) -> void:
	set_invalid_feedback(true)
	_stop_active_tween()
	visible = true
	pivot_offset = size * 0.5
	modulate = Color.WHITE
	scale = Vector2.ONE
	var invalid_scale := _adjust_scale(Vector2(0.94, 0.94))
	var adjusted_duration := _adjust_duration(step_duration)
	_active_tween = create_tween()
	_active_tween.tween_property(self, "modulate", _adjust_color(Color(1.30, 0.48, 0.45, 1.0)), adjusted_duration)
	_active_tween.parallel().tween_property(self, "scale", invalid_scale, adjusted_duration)
	_active_tween.tween_property(self, "modulate", Color.WHITE, adjusted_duration)
	_active_tween.parallel().tween_property(self, "scale", Vector2.ONE, adjusted_duration)


func play_refill_appear() -> void:
	_stop_active_tween()
	visible = true
	pivot_offset = size * 0.5
	modulate = Color(1.0, 1.0, 1.0, 0.45)
	scale = _adjust_scale(Vector2(0.90, 0.90))
	var duration := _adjust_duration(0.12)
	_active_tween = create_tween()
	_active_tween.tween_property(self, "modulate", Color.WHITE, duration)
	_active_tween.parallel().tween_property(self, "scale", Vector2.ONE, duration)


func reset_visual_state() -> void:
	_stop_active_tween()
	visible = true
	modulate = Color.WHITE
	scale = Vector2.ONE
	position = Vector2.ZERO
	_is_invalid_feedback = false
	_apply_visuals()


func clear_transient_feedback_state() -> void:
	_stop_active_tween()
	modulate = Color.WHITE
	scale = Vector2.ONE
	_is_invalid_feedback = false
	_apply_visuals()


func get_tile_asset_key() -> String:
	return ASSET_KEY_RESOLVER_SCRIPT.get_tile_asset_key(tile_type)


func get_special_tile_asset_key() -> String:
	if special_tile_data is SPECIAL_TILE_DATA_SCRIPT:
		return ASSET_KEY_RESOLVER_SCRIPT.get_special_tile_asset_key(special_tile_data.special_type)

	return ""


func get_marker_text() -> String:
	return _get_special_marker_text()


func has_tile_texture() -> bool:
	return icon != null


func _on_pressed() -> void:
	if _suppress_next_pressed:
		_suppress_next_pressed = false
		return

	tile_pressed.emit(board_cell)


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.pressed:
			_start_pointer(mouse_event.position)
		else:
			_release_pointer(mouse_event.position)
	elif event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		if touch_event.pressed:
			_start_pointer(touch_event.position)
		else:
			_release_pointer(touch_event.position)


func _start_pointer(pointer_position: Vector2) -> void:
	_press_start_position = pointer_position
	_has_press_start = true


func _release_pointer(pointer_position: Vector2) -> void:
	if not _has_press_start:
		return

	var drag_delta := pointer_position - _press_start_position
	_has_press_start = false
	if drag_delta.length() > 0.0:
		_suppress_next_pressed = true
		tile_drag_released.emit(board_cell, drag_delta)


func _apply_visuals() -> void:
	var base_color: Color = TILE_COLORS.get(tile_type, Color(0.20, 0.22, 0.26, 1.0))
	var style := StyleBoxFlat.new()
	style.bg_color = base_color.lightened(0.22) if _is_selected or _is_highlighted else base_color
	var border_width := 1
	var border_color := Color(0.05, 0.06, 0.08, 0.8)
	if _is_invalid_feedback:
		border_width = 4
		border_color = Color(1.0, 0.18, 0.16, 1.0)
	elif _is_selected:
		border_width = 4
		border_color = Color(1.0, 1.0, 1.0, 1.0)
	elif _is_highlighted:
		border_width = 3
		border_color = Color(1.0, 0.86, 0.20, 1.0)

	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.border_color = border_color
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	add_theme_stylebox_override("normal", style)
	add_theme_stylebox_override("hover", style)
	add_theme_stylebox_override("pressed", style)
	icon = GAME_ASSET_CATALOG.try_load_texture_cached(get_tile_asset_key())
	text = _get_special_marker_text()
	add_theme_color_override("font_color", Color.WHITE)
	add_theme_color_override("font_hover_color", Color.WHITE)
	add_theme_color_override("font_pressed_color", Color.WHITE)
	add_theme_font_size_override("font_size", 24 if _get_special_marker_text() == "B" else 22)


func _get_special_marker_text() -> String:
	if special_tile_data is SPECIAL_TILE_DATA_SCRIPT:
		return SPECIAL_TILE_TYPE_SCRIPT.get_marker_text(special_tile_data.special_type)

	return ""


func _play_flash_tween(flash_modulate: Color, flash_scale: Vector2) -> void:
	_stop_active_tween()
	visible = true
	modulate = Color.WHITE
	scale = Vector2.ONE
	pivot_offset = size * 0.5
	var adjusted_modulate := _adjust_color(flash_modulate)
	var adjusted_scale := _adjust_scale(flash_scale)
	var flash_duration := _adjust_duration(0.06)
	var settle_duration := _adjust_duration(0.14)
	_active_tween = create_tween()
	_active_tween.tween_property(self, "modulate", adjusted_modulate, flash_duration)
	_active_tween.parallel().tween_property(self, "scale", adjusted_scale, flash_duration)
	_active_tween.tween_property(self, "modulate", Color.WHITE, settle_duration)
	_active_tween.parallel().tween_property(self, "scale", Vector2.ONE, settle_duration)


func _adjust_duration(base_duration: float) -> float:
	return base_duration if _animations_enabled else 0.01


func _adjust_scale(base_scale: Vector2) -> Vector2:
	return base_scale.lerp(Vector2.ONE, 0.6) if _reduced_motion_enabled else base_scale


func _adjust_color(base_color: Color) -> Color:
	return base_color.lerp(Color.WHITE, 0.5) if _reduced_motion_enabled else base_color


func _stop_active_tween() -> void:
	if _active_tween != null:
		_active_tween.kill()
		_active_tween = null

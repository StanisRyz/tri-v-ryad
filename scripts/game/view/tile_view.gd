extends Button
class_name TileView

signal tile_pressed(cell: Vector2i)
signal tile_drag_released(cell: Vector2i, drag_delta: Vector2)

const TILE_COLORS := {
	TileType.RED: Color(0.86, 0.22, 0.22, 1.0),
	TileType.BLUE: Color(0.18, 0.42, 0.88, 1.0),
	TileType.GREEN: Color(0.16, 0.66, 0.36, 1.0),
	TileType.YELLOW: Color(0.92, 0.76, 0.20, 1.0),
	TileType.PURPLE: Color(0.56, 0.28, 0.82, 1.0),
}

var board_cell := Vector2i.ZERO
var tile_type := BoardModel.EMPTY
var _is_selected := false
var _press_start_position := Vector2.ZERO
var _has_press_start := false
var _suppress_next_pressed := false


func _ready() -> void:
	custom_minimum_size = Vector2(48, 48)
	focus_mode = Control.FOCUS_NONE
	gui_input.connect(_on_gui_input)
	if not pressed.is_connected(_on_pressed):
		pressed.connect(_on_pressed)
	_apply_visuals()


func set_tile(cell: Vector2i, new_tile_type: int) -> void:
	board_cell = cell
	tile_type = new_tile_type
	_apply_visuals()


func set_selected(selected: bool) -> void:
	_is_selected = selected
	_apply_visuals()


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
	style.bg_color = base_color.lightened(0.18) if _is_selected else base_color
	style.border_width_left = 4 if _is_selected else 1
	style.border_width_top = 4 if _is_selected else 1
	style.border_width_right = 4 if _is_selected else 1
	style.border_width_bottom = 4 if _is_selected else 1
	style.border_color = Color(1.0, 1.0, 1.0, 1.0) if _is_selected else Color(0.05, 0.06, 0.08, 0.8)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	add_theme_stylebox_override("normal", style)
	add_theme_stylebox_override("hover", style)
	add_theme_stylebox_override("pressed", style)
	text = ""

extends RefCounted
class_name BoardInputController

signal swap_requested(from_cell: Vector2i, to_cell: Vector2i)
signal selection_changed(cell: Vector2i)
signal selection_cleared
signal invalid_input(reason: String)

const MIN_DRAG_DISTANCE := 24.0
const BOARD_WIDTH := 9
const BOARD_HEIGHT := 9

var selected_cell := Vector2i(-1, -1)
var _input_enabled := true


func handle_tile_pressed(cell: Vector2i) -> void:
	if not _input_enabled:
		invalid_input.emit("input_locked")
		return

	if selected_cell == Vector2i(-1, -1):
		selected_cell = cell
		selection_changed.emit(cell)
		return

	if selected_cell == cell:
		clear_selection()
		return

	if _are_neighbors(selected_cell, cell):
		var from_cell := selected_cell
		clear_selection()
		swap_requested.emit(from_cell, cell)
		return

	selected_cell = cell
	selection_changed.emit(cell)


func handle_tile_drag_released(cell: Vector2i, drag_delta: Vector2) -> void:
	if not _input_enabled:
		invalid_input.emit("input_locked")
		return

	if drag_delta.length() < MIN_DRAG_DISTANCE:
		invalid_input.emit("swipe_too_short")
		return

	var target_cell := cell + _get_drag_direction(drag_delta)
	if not _is_inside_board(target_cell):
		clear_selection()
		invalid_input.emit("outside_board")
		return

	clear_selection()
	swap_requested.emit(cell, target_cell)


func set_input_enabled(enabled: bool) -> void:
	_input_enabled = enabled
	if not _input_enabled:
		clear_selection()


func clear_selection() -> void:
	if selected_cell == Vector2i(-1, -1):
		return

	selected_cell = Vector2i(-1, -1)
	selection_cleared.emit()


func _are_neighbors(a: Vector2i, b: Vector2i) -> bool:
	return abs(a.x - b.x) + abs(a.y - b.y) == 1


func _get_drag_direction(drag_delta: Vector2) -> Vector2i:
	if absf(drag_delta.x) > absf(drag_delta.y):
		return Vector2i.RIGHT if drag_delta.x > 0.0 else Vector2i.LEFT

	return Vector2i.DOWN if drag_delta.y > 0.0 else Vector2i.UP


func _is_inside_board(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < BOARD_WIDTH and cell.y < BOARD_HEIGHT

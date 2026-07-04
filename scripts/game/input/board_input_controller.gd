extends RefCounted
class_name BoardInputController

signal swap_requested(from_cell: Vector2i, to_cell: Vector2i)
signal selection_changed(cell: Vector2i)
signal selection_cleared

var selected_cell := Vector2i(-1, -1)
var _input_enabled := true


func handle_tile_pressed(cell: Vector2i) -> void:
	if not _input_enabled:
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

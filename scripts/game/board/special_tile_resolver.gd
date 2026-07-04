extends RefCounted
class_name SpecialTileResolver

const SPECIAL_TILE_TYPE_SCRIPT := preload("res://scripts/game/board/special_tile_type.gd")


func should_create_special(match_result: MatchResult) -> bool:
	return match_result != null and match_result.length() >= 4


func get_special_type_for_match(match_result: MatchResult) -> int:
	if match_result == null:
		return SPECIAL_TILE_TYPE_SCRIPT.NONE

	match match_result.direction:
		MatchResult.Direction.HORIZONTAL:
			return SPECIAL_TILE_TYPE_SCRIPT.LINE_HORIZONTAL
		MatchResult.Direction.VERTICAL:
			return SPECIAL_TILE_TYPE_SCRIPT.LINE_VERTICAL
		_:
			return SPECIAL_TILE_TYPE_SCRIPT.NONE


func choose_special_cell(match_result: MatchResult) -> Vector2i:
	if match_result == null or match_result.cells.is_empty():
		return Vector2i(-1, -1)

	return match_result.cells[match_result.cells.size() / 2]


func get_line_clear_cells(board: BoardModel, cell: Vector2i, special_data) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	if board == null or special_data == null or special_data.is_empty() or not board.is_inside(cell):
		return cells

	if special_data.is_horizontal_line():
		for x in range(board.width):
			cells.append(Vector2i(x, cell.y))
	elif special_data.is_vertical_line():
		for y in range(board.height):
			cells.append(Vector2i(cell.x, y))

	return cells


func collect_special_activation_cells(board: BoardModel, clear_cells: Array[Vector2i]) -> Array[Vector2i]:
	var seen := {}
	var activation_cells: Array[Vector2i] = []
	if board == null:
		return activation_cells

	for cell in clear_cells:
		if seen.has(cell):
			continue
		seen[cell] = true
		if board.has_special_tile(cell):
			activation_cells.append(cell)

	return activation_cells

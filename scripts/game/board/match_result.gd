extends RefCounted
class_name MatchResult

enum Direction {
	HORIZONTAL,
	VERTICAL,
}

var cells: Array[Vector2i] = []
var tile_type: int
var direction: Direction


func _init(match_cells: Array[Vector2i] = [], matched_tile_type: int = BoardModel.EMPTY, match_direction: Direction = Direction.HORIZONTAL) -> void:
	cells = match_cells.duplicate()
	tile_type = matched_tile_type
	direction = match_direction


func length() -> int:
	return cells.size()


func contains_cell(cell: Vector2i) -> bool:
	return cell in cells


func to_dictionary() -> Dictionary:
	return {
		"cells": cells,
		"tile_type": tile_type,
		"direction": direction,
	}

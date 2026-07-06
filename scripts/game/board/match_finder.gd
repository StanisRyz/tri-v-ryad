extends RefCounted
class_name MatchFinder


func find_matches(board: BoardModel) -> Array[MatchResult]:
	var matches: Array[MatchResult] = []
	matches.append_array(_find_horizontal_matches(board))
	matches.append_array(_find_vertical_matches(board))
	return matches


func has_matches(board: BoardModel) -> bool:
	return not find_matches(board).is_empty()


## Stage 52 v0.1: inactive cells (future holes) always break a run, the same
## way an EMPTY cell does, and are never appended to run_cells/MatchResult.
func _find_horizontal_matches(board: BoardModel) -> Array[MatchResult]:
	var matches: Array[MatchResult] = []

	for y in range(board.height):
		var run_cells: Array[Vector2i] = []
		var run_tile := BoardModel.EMPTY

		for x in range(board.width):
			var cell := Vector2i(x, y)
			if not board.is_playable_cell(cell):
				_append_match_if_valid(matches, run_cells, run_tile, MatchResult.Direction.HORIZONTAL)
				run_tile = BoardModel.EMPTY
				run_cells.clear()
				continue

			var tile := board.get_tile(cell)
			if tile != BoardModel.EMPTY and tile == run_tile:
				run_cells.append(cell)
			else:
				_append_match_if_valid(matches, run_cells, run_tile, MatchResult.Direction.HORIZONTAL)
				run_tile = tile
				run_cells.clear()
				if tile != BoardModel.EMPTY:
					run_cells.append(cell)

		_append_match_if_valid(matches, run_cells, run_tile, MatchResult.Direction.HORIZONTAL)

	return matches


func _find_vertical_matches(board: BoardModel) -> Array[MatchResult]:
	var matches: Array[MatchResult] = []

	for x in range(board.width):
		var run_cells: Array[Vector2i] = []
		var run_tile := BoardModel.EMPTY

		for y in range(board.height):
			var cell := Vector2i(x, y)
			if not board.is_playable_cell(cell):
				_append_match_if_valid(matches, run_cells, run_tile, MatchResult.Direction.VERTICAL)
				run_tile = BoardModel.EMPTY
				run_cells.clear()
				continue

			var tile := board.get_tile(cell)
			if tile != BoardModel.EMPTY and tile == run_tile:
				run_cells.append(cell)
			else:
				_append_match_if_valid(matches, run_cells, run_tile, MatchResult.Direction.VERTICAL)
				run_tile = tile
				run_cells.clear()
				if tile != BoardModel.EMPTY:
					run_cells.append(cell)

		_append_match_if_valid(matches, run_cells, run_tile, MatchResult.Direction.VERTICAL)

	return matches


func _append_match_if_valid(matches: Array[MatchResult], run_cells: Array[Vector2i], tile_type: int, direction: MatchResult.Direction) -> void:
	if tile_type == BoardModel.EMPTY or run_cells.size() < 3:
		return

	matches.append(MatchResult.new(run_cells, tile_type, direction))

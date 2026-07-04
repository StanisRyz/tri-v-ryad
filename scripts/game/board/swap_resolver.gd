extends RefCounted
class_name SwapResolver

var _match_finder := MatchFinder.new()


func try_swap(board: BoardModel, from_cell: Vector2i, to_cell: Vector2i) -> SwapResult:
	if not board.is_inside(from_cell) or not board.is_inside(to_cell):
		return SwapResult.new(false, from_cell, to_cell, [], "out_of_bounds")

	if not _are_adjacent(from_cell, to_cell):
		return SwapResult.new(false, from_cell, to_cell, [], "not_adjacent")

	board.swap_tiles(from_cell, to_cell)
	var matches := _match_finder.find_matches(board)

	if matches.is_empty():
		board.swap_tiles(from_cell, to_cell)
		return SwapResult.new(false, from_cell, to_cell, [], "no_match")

	return SwapResult.new(true, from_cell, to_cell, matches, "")


func _are_adjacent(a: Vector2i, b: Vector2i) -> bool:
	return abs(a.x - b.x) + abs(a.y - b.y) == 1

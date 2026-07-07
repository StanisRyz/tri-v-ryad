extends RefCounted
class_name SwapResolver

var _match_finder := MatchFinder.new()


func try_swap(board: BoardModel, from_cell: Vector2i, to_cell: Vector2i) -> SwapResult:
	if not board.is_inside(from_cell) or not board.is_inside(to_cell):
		return SwapResult.new(false, from_cell, to_cell, [], "out_of_bounds")

	if not board.is_cell_active(from_cell) or not board.is_cell_active(to_cell):
		return SwapResult.new(false, from_cell, to_cell, [], "inactive_cell")

	## Stage 62.1.1 hotfix: ice is a cell obstacle/debuff, not just a visual
	## overlay, so an iced cell must be rejected as a swap endpoint before
	## adjacency/match checks even run. This is the single shared enforcement
	## point — normal player swaps, AvailableMoveFinder's trial swaps on
	## duplicated boards, and BoardShuffleResolver's post-shuffle move check
	## all call try_swap(), so all three automatically respect ice.
	if board.is_cell_iced(from_cell) or board.is_cell_iced(to_cell):
		return SwapResult.new(false, from_cell, to_cell, [], "iced_cell")

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

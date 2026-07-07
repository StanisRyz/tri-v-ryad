extends RefCounted
class_name AvailableMoveFinder

## Stage 59 v0.1: read-only runtime helper that answers "does the settled
## board have at least one valid player move?" using the exact same swap/
## match rules real gameplay uses (SwapResolver.try_swap() -> MatchFinder),
## so a board this reports as "has a move" is guaranteed swappable by the
## player and vice versa. Mirrors the scan BattlePresenter._has_valid_move()
## already used for initial board generation (Stage 52), extracted into a
## standalone, reusable helper so BoardShuffleResolver and any post-cascade
## runtime check can share it.
##
## Only active/playable cells are scanned; inactive (hole) cells are never a
## swap endpoint (SwapResolver already rejects them via is_cell_active()).
## Stage 62.1.1 hotfix: iced cells are likewise never a valid swap endpoint —
## SwapResolver rejects them (via is_cell_iced()) before adjacency/match
## checks, so a candidate swap that would move a crystal into or out of an
## iced cell is never reported as an available move.
## Every trial swap runs against a duplicated BoardModel
## (BoardModel.duplicate_board()), so the board passed in is never mutated.

const SWAP_RESOLVER_SCRIPT := preload("res://scripts/game/board/swap_resolver.gd")

var _swap_resolver := SWAP_RESOLVER_SCRIPT.new()


## Returns true if at least one adjacent swap on an active cell would create
## a match. Right/down offsets are enough to cover every adjacent pair exactly
## once, since swap adjacency is symmetric.
func has_available_move(board: BoardModel) -> bool:
	if board == null:
		return false

	for cell in board.get_active_cells():
		for offset in [Vector2i.RIGHT, Vector2i.DOWN]:
			var neighbor: Vector2i = cell + offset
			if not board.is_inside(neighbor) or not board.is_cell_active(neighbor):
				continue

			var candidate: BoardModel = board.duplicate_board()
			if _swap_resolver.try_swap(candidate, cell, neighbor).accepted:
				return true

	return false

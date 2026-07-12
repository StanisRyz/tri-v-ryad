extends RefCounted
class_name SpecialTileResolver

const SPECIAL_TILE_TYPE_SCRIPT := preload("res://scripts/game/board/special_tile_type.gd")


func should_create_special(match_result: MatchResult) -> bool:
	return match_result != null and match_result.length() >= 4


func get_special_type_for_match(match_result: MatchResult) -> int:
	if match_result == null:
		return SPECIAL_TILE_TYPE_SCRIPT.NONE
	if match_result.length() < 4:
		return SPECIAL_TILE_TYPE_SCRIPT.NONE
	if match_result.length() >= 5:
		return SPECIAL_TILE_TYPE_SCRIPT.COLOR_BOMB

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

	return match_result.cells[floori(float(match_result.cells.size()) / 2.0)]


## preferred_cells is tried in order (e.g. [swapped_target_cell, swapped_source_cell])
## so a player-created special lands on the cell the player actually swapped
## into/out of; falls back to the deterministic center cell for
## cascade/gravity-created specials or when no preferred cell is part of the match.
func choose_special_cell_for_match(match_result: MatchResult, preferred_cells: Array[Vector2i] = []) -> Vector2i:
	if match_result == null or match_result.cells.is_empty():
		return Vector2i(-1, -1)

	for preferred_cell in preferred_cells:
		if match_result.contains_cell(preferred_cell):
			return preferred_cell

	return choose_special_cell(match_result)


## Stage 52 v0.1: inactive cells (future holes) never appear in the returned
## cells, so a line/color-bomb activation can never sweep through a hole.
func get_line_clear_cells(board: BoardModel, cell: Vector2i, special_data) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	if board == null or special_data == null or special_data.is_empty() or not board.is_inside(cell):
		return cells

	if special_data.is_horizontal_line():
		for x in range(board.width):
			var candidate := Vector2i(x, cell.y)
			if board.is_playable_cell(candidate):
				cells.append(candidate)
	elif special_data.is_vertical_line():
		for y in range(board.height):
			var candidate := Vector2i(cell.x, y)
			if board.is_playable_cell(candidate):
				cells.append(candidate)

	return cells


func get_color_bomb_clear_cells(board: BoardModel, cell: Vector2i, special_data) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	if board == null or special_data == null or special_data.is_empty() or not board.is_inside(cell):
		return cells
	if not special_data.is_color_bomb():
		return cells

	var target_tile_type := board.get_tile(cell)
	if target_tile_type == BoardModel.EMPTY or not TileType.is_valid_tile_type(target_tile_type):
		return cells

	for board_cell in board.get_all_cells():
		if board.is_playable_cell(board_cell) and board.get_tile(board_cell) == target_tile_type:
			cells.append(board_cell)

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
		if board.is_playable_cell(cell) and board.has_special_tile(cell):
			activation_cells.append(cell)

	return activation_cells


## Stage 67.1 v0.1: canonical special-activation chain resolver, shared by
## BoardResolver, StepwiseBoardResolver, and BoosterResolver so every clear
## path (match cascade, line/color-bomb blast, or booster clear) triggers
## specials the same way.
##
## initial_cells is the set of cells already being cleared this step (a
## match, a booster's target area, or another special's blast). Any of those
## cells that already carry a pre-existing special tile is queued for
## activation. protected_cells (typically the cell(s) a special was *just*
## created on this same step) are never cleared and never activated - this is
## what keeps a freshly created special from instantly detonating itself.
##
## Activating a special clears its line/color-bomb cells, which are folded
## into the returned cleared_cells; if one of those newly-cleared cells also
## carries a pre-existing special tile, it is queued too, so chains of
## special-triggers-special keep resolving until the queue is empty. Each
## cell activates at most once (processed set), which also bounds the loop.
##
## Returns {"cleared_cells", "activated_special_tiles", "special_cleared_cells"}.
func resolve_special_activation_chain(board: BoardModel, initial_cells: Array[Vector2i], protected_cells: Dictionary = {}) -> Dictionary:
	var cleared_cells: Array[Vector2i] = []
	var clear_seen := {}
	if board != null:
		for cell in initial_cells:
			if protected_cells.has(cell):
				continue
			_add_unique_cell(cleared_cells, clear_seen, cell)

	var activated_special_tiles: Array[Dictionary] = []
	var special_cleared_cells: Array[Vector2i] = []
	var special_cleared_seen := {}

	if board == null:
		return {
			"cleared_cells": cleared_cells,
			"activated_special_tiles": activated_special_tiles,
			"special_cleared_cells": special_cleared_cells,
		}

	var processed := {}
	var queued := {}
	var queue: Array[Vector2i] = []

	for cell in cleared_cells:
		_enqueue_special(board, cell, protected_cells, processed, queued, queue)

	while not queue.is_empty():
		var activation_cell: Vector2i = queue.pop_front()
		if processed.has(activation_cell):
			continue
		processed[activation_cell] = true

		var special_data = board.get_special_tile(activation_cell)
		if special_data == null:
			continue

		activated_special_tiles.append({
			"cell": activation_cell,
			"special_type": special_data.special_type,
		})

		var special_cells: Array[Vector2i] = []
		var base_tile_type := BoardModel.EMPTY
		if special_data.is_color_bomb():
			base_tile_type = board.get_tile(activation_cell)
			special_cells = get_color_bomb_clear_cells(board, activation_cell, special_data)
		else:
			special_cells = get_line_clear_cells(board, activation_cell, special_data)

		var affected_cells: Array[Vector2i] = []
		for special_cell in special_cells:
			if protected_cells.has(special_cell):
				continue
			affected_cells.append(special_cell)
			_add_unique_cell(cleared_cells, clear_seen, special_cell)
			_add_unique_cell(special_cleared_cells, special_cleared_seen, special_cell)
			_enqueue_special(board, special_cell, protected_cells, processed, queued, queue)

		var activation_data: Dictionary = activated_special_tiles[activated_special_tiles.size() - 1]
		activation_data["affected_cells"] = affected_cells.duplicate()
		activation_data["base_tile_type"] = base_tile_type

	return {
		"cleared_cells": cleared_cells,
		"activated_special_tiles": activated_special_tiles,
		"special_cleared_cells": special_cleared_cells,
	}


func _enqueue_special(board: BoardModel, cell: Vector2i, protected_cells: Dictionary, processed: Dictionary, queued: Dictionary, queue: Array[Vector2i]) -> void:
	if protected_cells.has(cell) or processed.has(cell) or queued.has(cell):
		return
	if not board.is_playable_cell(cell) or not board.has_special_tile(cell):
		return
	queued[cell] = true
	queue.append(cell)


func _add_unique_cell(cells: Array[Vector2i], seen: Dictionary, cell: Vector2i) -> void:
	if seen.has(cell):
		return
	seen[cell] = true
	cells.append(cell)

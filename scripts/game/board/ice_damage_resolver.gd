extends RefCounted
class_name IceDamageResolver

## Stage 56 v0.1: computes ice obstacle damage for a single clear event (a
## batch of cells cleared together by a match, cascade, special activation,
## or booster). A cell's ice takes exactly one hit for the event if it was
## either cleared directly or is an orthogonal (non-diagonal) neighbor of a
## cleared cell, even if it qualifies both ways.

const CELL_OBSTACLE_TYPE_SCRIPT := preload("res://scripts/game/board/cell_obstacle_type.gd")


## Mutates board obstacle state for the given clear event and returns one
## event dictionary per damaged ice cell: {"cell", "obstacle_type",
## "previous_layers", "new_layers", "broken"}.
func apply_ice_damage(board: BoardModel, cleared_cells: Array[Vector2i]) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	for cell in _collect_target_cells(board, cleared_cells):
		var result := board.damage_cell_obstacle(cell, 1)
		if not result.is_empty():
			events.append(result)
	return events


## Read-only prediction of apply_ice_damage()'s outcome for the same board
## state and cleared_cells, used by animated presentation flows that must
## know which cells will be damaged/broken before the board is actually
## mutated so ice feedback can play before the tile clear fade.
func preview_ice_damage(board: BoardModel, cleared_cells: Array[Vector2i]) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	for cell in _collect_target_cells(board, cleared_cells):
		var previous_layers := board.get_cell_obstacle_layers(cell)
		var new_layers := maxi(previous_layers - 1, 0)
		events.append({
			"cell": cell,
			"obstacle_type": board.get_cell_obstacle(cell),
			"previous_layers": previous_layers,
			"new_layers": new_layers,
			"broken": new_layers <= 0,
		})
	return events


static func extract_damaged_cells(events: Array) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for event in events:
		var cell = (event as Dictionary).get("cell")
		if cell is Vector2i:
			cells.append(cell)
	return cells


static func extract_broken_cells(events: Array) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for event in events:
		var data := event as Dictionary
		var cell = data.get("cell")
		if cell is Vector2i and bool(data.get("broken", false)):
			cells.append(cell)
	return cells


## Deduplicated set of cells to damage this event: every cleared cell that
## carries ice, plus every orthogonal neighbor of a cleared cell that carries
## ice. A cell appears at most once even if it qualifies both ways.
func _collect_target_cells(board: BoardModel, cleared_cells: Array[Vector2i]) -> Array[Vector2i]:
	var seen := {}
	var target_cells: Array[Vector2i] = []

	for cell in cleared_cells:
		if not seen.has(cell) and board.is_cell_iced(cell):
			seen[cell] = true
			target_cells.append(cell)

		for neighbor in _orthogonal_neighbors(cell):
			if seen.has(neighbor):
				continue
			if board.is_playable_cell(neighbor) and board.is_cell_iced(neighbor):
				seen[neighbor] = true
				target_cells.append(neighbor)

	return target_cells


func _orthogonal_neighbors(cell: Vector2i) -> Array[Vector2i]:
	return [
		Vector2i(cell.x, cell.y - 1),
		Vector2i(cell.x, cell.y + 1),
		Vector2i(cell.x - 1, cell.y),
		Vector2i(cell.x + 1, cell.y),
	]

extends RefCounted
class_name GravityResolver

## Stage 54.2 v0.1: gravity/refill treats each column as one pass-through
## gravity lane again (replacing Stage 53's per-active-segment "wall"
## behavior): inactive cells are skipped as storage rather than walled off,
## so a tile above one or more inactive cells can fall all the way down into
## the next active cell below the gap, and refill only ever targets active
## cells. Inactive cells are never read from or written to during gravity,
## so they always stay inactive and EMPTY with no special metadata. With a
## full active mask (current normal/ice gameplay) every column has no
## inactive cells at all, so this reduces to exactly the original
## whole-column algorithm — full 9x9 behavior is unchanged.

var rng: RandomNumberGenerator


func _init(random_number_generator: RandomNumberGenerator = null) -> void:
	rng = random_number_generator if random_number_generator != null else RandomNumberGenerator.new()
	if random_number_generator == null:
		rng.randomize()


func apply_gravity_and_refill(board: BoardModel) -> Dictionary:
	var spawned_cells: Array[Vector2i] = []
	var fall_movements: Array[Dictionary] = []
	var refill_cells: Array[Dictionary] = []

	for x in range(board.width):
		_resolve_column(board, x, spawned_cells, fall_movements, refill_cells)

	return {
		"spawned_cells": spawned_cells,
		"fall_movements": fall_movements,
		"refill_cells": refill_cells,
	}


## Scans column x bottom-to-top, skipping inactive cells entirely (they are
## never read from or written to — pass-through space, not storage) and
## collecting every active cell's tile/special data in scan order. Falling
## tiles are written back starting at the lowest active cell in the column,
## so a tile can fall straight through any number of inactive cells into the
## next active cell below the gap. Remaining active cells (the ones nearer
## the top of the column once falling tiles are placed) are refilled with
## brand-new tiles.
func _resolve_column(
	board: BoardModel,
	x: int,
	spawned_cells: Array[Vector2i],
	fall_movements: Array[Dictionary],
	refill_cells: Array[Dictionary]
) -> void:
	var active_cells_desc: Array[Vector2i] = []
	var falling_tiles: Array[Dictionary] = []

	for y in range(board.height - 1, -1, -1):
		var cell := Vector2i(x, y)
		if not board.is_cell_active(cell):
			continue

		active_cells_desc.append(cell)
		var tile := board.get_tile(cell)
		if tile != BoardModel.EMPTY:
			falling_tiles.append({
				"tile": tile,
				"special": board.get_special_tile(cell),
				"from": cell,
			})
		board.set_tile(cell, BoardModel.EMPTY)
		board.clear_special_tile(cell)

	for i in range(falling_tiles.size()):
		var tile_data: Dictionary = falling_tiles[i]
		var target_cell: Vector2i = active_cells_desc[i]
		board.set_tile(target_cell, tile_data.get("tile", BoardModel.EMPTY))
		board.set_special_tile(target_cell, tile_data.get("special", null))

		var from_cell: Vector2i = tile_data.get("from")
		var fall_distance: int = target_cell.y - from_cell.y
		if fall_distance > 0:
			var crossed_inactive_cells := _get_crossed_inactive_cells(board, x, from_cell.y, target_cell.y)
			fall_movements.append({
				"from": from_cell,
				"to": target_cell,
				"tile_type": tile_data.get("tile", BoardModel.EMPTY),
				"special_data": tile_data.get("special", null),
				"fall_distance": fall_distance,
				"crossed_inactive_cells": crossed_inactive_cells,
				"crosses_inactive_gap": not crossed_inactive_cells.is_empty(),
			})

	var column_spawn_index := 0
	for i in range(falling_tiles.size(), active_cells_desc.size()):
		var spawned_cell: Vector2i = active_cells_desc[i]
		var tile_type := _get_random_tile_type()
		board.set_tile(spawned_cell, tile_type)
		board.clear_special_tile(spawned_cell)
		spawned_cells.append(spawned_cell)
		refill_cells.append({
			"spawn_index": column_spawn_index,
			"to": spawned_cell,
			"tile_type": tile_type,
			"special_data": null,
			"column_active_index": i,
			"column_spawn_index": column_spawn_index,
		})
		column_spawn_index += 1


## Lists the inactive cells strictly between from_y and to_y in column x —
## always inactive cells by construction, since active_cells_desc already
## accounts for every active cell in scan order. Reserved for a later visual
## pass so BoardView/AnimationLayer can hide a falling ghost while it crosses
## an inactive gap instead of visibly sliding over a hole.
func _get_crossed_inactive_cells(board: BoardModel, x: int, from_y: int, to_y: int) -> Array[Vector2i]:
	var crossed_inactive_cells: Array[Vector2i] = []
	for cross_y in range(from_y + 1, to_y):
		var cross_cell := Vector2i(x, cross_y)
		if not board.is_cell_active(cross_cell):
			crossed_inactive_cells.append(cross_cell)
	return crossed_inactive_cells


func _get_random_tile_type() -> int:
	var tile_types := TileType.get_all_types()
	return tile_types[rng.randi_range(0, tile_types.size() - 1)]

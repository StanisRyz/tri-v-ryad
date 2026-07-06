extends RefCounted
class_name GravityResolver

## Stage 53 v0.1: gravity/refill runs per contiguous active column segment
## instead of treating a whole column as one fall lane, so inactive cells
## (future holes) behave like walls — tiles never fall through them and
## refill never targets them. With a full active mask (current gameplay)
## every column is exactly one segment spanning the whole board, so behavior
## is identical to the pre-Stage-53 whole-column algorithm.

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
		var segments := _get_active_segments_for_column(board, x)
		for segment_index in range(segments.size()):
			_resolve_segment(board, x, segments[segment_index], segment_index, spawned_cells, fall_movements, refill_cells)

	return {
		"spawned_cells": spawned_cells,
		"fall_movements": fall_movements,
		"refill_cells": refill_cells,
	}


## Scans column x top-to-bottom (y=0 is top, increasing y is down) and groups
## contiguous active cells into segments; an inactive cell always ends the
## current segment. Returns only non-empty segments, ordered top-to-bottom.
func _get_active_segments_for_column(board: BoardModel, x: int) -> Array[Dictionary]:
	var segments: Array[Dictionary] = []
	var segment_top := -1

	for y in range(board.height):
		if board.is_cell_active(Vector2i(x, y)):
			if segment_top == -1:
				segment_top = y
			continue

		if segment_top != -1:
			segments.append({"top": segment_top, "bottom": y - 1})
			segment_top = -1

	if segment_top != -1:
		segments.append({"top": segment_top, "bottom": board.height - 1})

	return segments


## Applies the same fall/refill algorithm as the pre-Stage-53 whole-column
## version, but bounded to [segment.top, segment.bottom] so tiles/refills
## never cross into an inactive cell or another segment.
func _resolve_segment(
	board: BoardModel,
	x: int,
	segment: Dictionary,
	segment_index: int,
	spawned_cells: Array[Vector2i],
	fall_movements: Array[Dictionary],
	refill_cells: Array[Dictionary]
) -> void:
	var segment_top: int = segment["top"]
	var segment_bottom: int = segment["bottom"]
	var falling_tiles: Array[Dictionary] = []

	for y in range(segment_bottom, segment_top - 1, -1):
		var cell := Vector2i(x, y)
		var tile := board.get_tile(cell)
		if tile != BoardModel.EMPTY:
			falling_tiles.append({
				"tile": tile,
				"special": board.get_special_tile(cell),
				"from": cell,
			})
		board.set_tile(cell, BoardModel.EMPTY)
		board.clear_special_tile(cell)

	var write_y := segment_bottom
	for tile_data in falling_tiles:
		var target_cell := Vector2i(x, write_y)
		board.set_tile(target_cell, tile_data.get("tile", BoardModel.EMPTY))
		board.set_special_tile(target_cell, tile_data.get("special", null))
		var from_cell: Vector2i = tile_data.get("from")
		var fall_distance: int = target_cell.y - from_cell.y
		if fall_distance > 0:
			fall_movements.append({
				"from": from_cell,
				"to": target_cell,
				"tile_type": tile_data.get("tile", BoardModel.EMPTY),
				"special_data": tile_data.get("special", null),
				"fall_distance": fall_distance,
				"segment_index": segment_index,
				"segment_top": segment_top,
				"segment_bottom": segment_bottom,
			})
		write_y -= 1

	var segment_spawn_index := 0
	while write_y >= segment_top:
		var spawned_cell := Vector2i(x, write_y)
		var tile_type := _get_random_tile_type()
		board.set_tile(spawned_cell, tile_type)
		board.clear_special_tile(spawned_cell)
		spawned_cells.append(spawned_cell)
		refill_cells.append({
			"spawn_index": segment_spawn_index,
			"to": spawned_cell,
			"tile_type": tile_type,
			"special_data": null,
			"segment_index": segment_index,
			"segment_top": segment_top,
			"segment_bottom": segment_bottom,
			"segment_spawn_index": segment_spawn_index,
		})
		segment_spawn_index += 1
		write_y -= 1


func _get_random_tile_type() -> int:
	var tile_types := TileType.get_all_types()
	return tile_types[rng.randi_range(0, tile_types.size() - 1)]

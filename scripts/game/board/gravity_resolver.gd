extends RefCounted
class_name GravityResolver

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
		var falling_tiles: Array[Dictionary] = []

		for y in range(board.height - 1, -1, -1):
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

		var write_y := board.height - 1
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
				})
			write_y -= 1

		var column_spawn_index := 0
		while write_y >= 0:
			var spawned_cell := Vector2i(x, write_y)
			var tile_type := _get_random_tile_type()
			board.set_tile(spawned_cell, tile_type)
			board.clear_special_tile(spawned_cell)
			spawned_cells.append(spawned_cell)
			refill_cells.append({
				"spawn_index": column_spawn_index,
				"to": spawned_cell,
				"tile_type": tile_type,
				"special_data": null,
			})
			column_spawn_index += 1
			write_y -= 1

	return {
		"spawned_cells": spawned_cells,
		"fall_movements": fall_movements,
		"refill_cells": refill_cells,
	}


func _get_random_tile_type() -> int:
	var tile_types := TileType.get_all_types()
	return tile_types[rng.randi_range(0, tile_types.size() - 1)]

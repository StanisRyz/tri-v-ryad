extends RefCounted
class_name GravityResolver

var rng: RandomNumberGenerator


func _init(random_number_generator: RandomNumberGenerator = null) -> void:
	rng = random_number_generator if random_number_generator != null else RandomNumberGenerator.new()
	if random_number_generator == null:
		rng.randomize()


func apply_gravity_and_refill(board: BoardModel) -> Dictionary:
	var spawned_cells: Array[Vector2i] = []

	for x in range(board.width):
		var falling_tiles: Array[Dictionary] = []

		for y in range(board.height - 1, -1, -1):
			var cell := Vector2i(x, y)
			var tile := board.get_tile(cell)
			if tile != BoardModel.EMPTY:
				falling_tiles.append({
					"tile": tile,
					"special": board.get_special_tile(cell),
				})
			board.set_tile(cell, BoardModel.EMPTY)
			board.clear_special_tile(cell)

		var write_y := board.height - 1
		for tile_data in falling_tiles:
			var target_cell := Vector2i(x, write_y)
			board.set_tile(target_cell, tile_data.get("tile", BoardModel.EMPTY))
			board.set_special_tile(target_cell, tile_data.get("special", null))
			write_y -= 1

		while write_y >= 0:
			var spawned_cell := Vector2i(x, write_y)
			board.set_tile(spawned_cell, _get_random_tile_type())
			board.clear_special_tile(spawned_cell)
			spawned_cells.append(spawned_cell)
			write_y -= 1

	return {
		"spawned_cells": spawned_cells,
	}


func _get_random_tile_type() -> int:
	var tile_types := TileType.get_all_types()
	return tile_types[rng.randi_range(0, tile_types.size() - 1)]

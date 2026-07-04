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
		var filled_tiles: Array[int] = []

		for y in range(board.height - 1, -1, -1):
			var tile := board.get_tile(Vector2i(x, y))
			if tile != BoardModel.EMPTY:
				filled_tiles.append(tile)

		var write_y := board.height - 1
		for tile in filled_tiles:
			board.set_tile(Vector2i(x, write_y), tile)
			write_y -= 1

		while write_y >= 0:
			var spawned_cell := Vector2i(x, write_y)
			board.set_tile(spawned_cell, _get_random_tile_type())
			spawned_cells.append(spawned_cell)
			write_y -= 1

	return {
		"spawned_cells": spawned_cells,
	}


func _get_random_tile_type() -> int:
	var tile_types := TileType.get_all_types()
	return tile_types[rng.randi_range(0, tile_types.size() - 1)]

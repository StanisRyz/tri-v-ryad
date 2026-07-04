extends RefCounted
class_name BoardGenerator

var rng: RandomNumberGenerator


func _init(random_number_generator: RandomNumberGenerator = null) -> void:
	rng = random_number_generator if random_number_generator != null else RandomNumberGenerator.new()
	if random_number_generator == null:
		rng.randomize()


func generate(width: int = BoardModel.DEFAULT_WIDTH, height: int = BoardModel.DEFAULT_HEIGHT) -> BoardModel:
	var board := BoardModel.new(width, height)
	var tile_types := TileType.get_all_types()

	for y in range(height):
		for x in range(width):
			var cell := Vector2i(x, y)
			var options := tile_types.duplicate()
			_remove_starting_match_options(board, cell, options)
			board.set_tile(cell, options[rng.randi_range(0, options.size() - 1)])

	return board


func _remove_starting_match_options(board: BoardModel, cell: Vector2i, options: Array[int]) -> void:
	if cell.x >= 2:
		var left_1 := board.get_tile(Vector2i(cell.x - 1, cell.y))
		var left_2 := board.get_tile(Vector2i(cell.x - 2, cell.y))
		if left_1 == left_2:
			options.erase(left_1)

	if cell.y >= 2:
		var up_1 := board.get_tile(Vector2i(cell.x, cell.y - 1))
		var up_2 := board.get_tile(Vector2i(cell.x, cell.y - 2))
		if up_1 == up_2:
			options.erase(up_1)

extends RefCounted
class_name BoardGenerator

var rng: RandomNumberGenerator


func _init(random_number_generator: RandomNumberGenerator = null) -> void:
	rng = random_number_generator if random_number_generator != null else RandomNumberGenerator.new()
	if random_number_generator == null:
		rng.randomize()


## Stage 52 v0.1: mask is optional and uses the GeneratedBoardChallenge.board_mask
## shape (Array of height rows of width bool-ish values). An empty/invalid mask
## keeps the board fully active, so existing full-9x9 callers are unaffected.
func generate(width: int = BoardModel.DEFAULT_WIDTH, height: int = BoardModel.DEFAULT_HEIGHT, mask: Array = []) -> BoardModel:
	var board := BoardModel.new(width, height)
	if not mask.is_empty():
		board.set_active_mask(mask)

	var tile_types := TileType.get_all_types()

	for y in range(height):
		for x in range(width):
			var cell := Vector2i(x, y)
			if not board.is_playable_cell(cell):
				continue

			var options := tile_types.duplicate()
			_remove_starting_match_options(board, cell, options)
			board.set_tile(cell, options[rng.randi_range(0, options.size() - 1)])

	return board


func generate_with_mask(mask: Array, width: int = BoardModel.DEFAULT_WIDTH, height: int = BoardModel.DEFAULT_HEIGHT) -> BoardModel:
	return generate(width, height, mask)


func _remove_starting_match_options(board: BoardModel, cell: Vector2i, options: Array[int]) -> void:
	if cell.x >= 2:
		var left_1 := Vector2i(cell.x - 1, cell.y)
		var left_2 := Vector2i(cell.x - 2, cell.y)
		if board.is_playable_cell(left_1) and board.is_playable_cell(left_2):
			var left_tile_1 := board.get_tile(left_1)
			var left_tile_2 := board.get_tile(left_2)
			if left_tile_1 == left_tile_2:
				options.erase(left_tile_1)

	if cell.y >= 2:
		var up_1 := Vector2i(cell.x, cell.y - 1)
		var up_2 := Vector2i(cell.x, cell.y - 2)
		if board.is_playable_cell(up_1) and board.is_playable_cell(up_2):
			var up_tile_1 := board.get_tile(up_1)
			var up_tile_2 := board.get_tile(up_2)
			if up_tile_1 == up_tile_2:
				options.erase(up_tile_1)

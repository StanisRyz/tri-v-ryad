extends SceneTree

const GRAVITY_RESOLVER_SCRIPT := preload("res://scripts/game/board/gravity_resolver.gd")

var _failures := 0


func _initialize() -> void:
	print("Running board gravity animation data test...")

	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var resolver = GRAVITY_RESOLVER_SCRIPT.new(rng)
	var board := _make_board_with_gap()

	var result: Dictionary = resolver.apply_gravity_and_refill(board)
	var fall_movements: Array = result.get("fall_movements", [])
	var refill_cells: Array = result.get("refill_cells", [])

	_expect_true(not fall_movements.is_empty(), "gravity result exposes fall_movements when tiles fall")
	_expect_true(not refill_cells.is_empty(), "gravity result exposes refill_cells for spawned tiles")

	var found_expected_fall := false
	for movement in fall_movements:
		var data := movement as Dictionary
		_expect_true(data.has("from"), "fall movement has from cell")
		_expect_true(data.has("to"), "fall movement has to cell")
		_expect_true(int(data.get("fall_distance", 0)) > 0, "fall movement has positive fall_distance")
		var to_cell: Vector2i = data.get("to")
		var from_cell: Vector2i = data.get("from")
		_expect_true(to_cell.y > from_cell.y, "fall movement moves tile downward")
		if from_cell == Vector2i(0, 0) and to_cell == Vector2i(0, 1):
			found_expected_fall = true
			_expect_equal(data.get("tile_type"), TileType.RED, "fall movement preserves tile type")

	_expect_true(found_expected_fall, "gap in column 0 produces expected fall movement")

	for refill_item in refill_cells:
		var data := refill_item as Dictionary
		_expect_true(data.has("spawn_index"), "refill cell has spawn_index")
		_expect_true(data.has("to"), "refill cell has target cell")
		_expect_true(TileType.is_valid_tile_type(data.get("tile_type", -1)), "refill cell has valid tile type")

	_expect_false(board.has_empty_cells(), "board has no empty cells after gravity and refill")

	_finish()


func _make_board_with_gap() -> BoardModel:
	var board := BoardModel.new()
	for y in range(BoardModel.DEFAULT_HEIGHT):
		for x in range(BoardModel.DEFAULT_WIDTH):
			board.set_tile(Vector2i(x, y), TileType.RED)

	board.set_tile(Vector2i(0, 1), BoardModel.EMPTY)
	return board


func _finish() -> void:
	if _failures == 0:
		print("Board gravity animation data test passed.")
		quit(0)
	else:
		push_error("Board gravity animation data test failed: %d" % _failures)
		quit(1)


func _expect_true(value: bool, message: String) -> void:
	if value:
		return
	_failures += 1
	push_error("FAILED: %s" % message)


func _expect_false(value: bool, message: String) -> void:
	_expect_true(not value, message)


func _expect_equal(actual, expected, message: String) -> void:
	if actual == expected:
		return
	_failures += 1
	push_error("FAILED: %s | expected=%s actual=%s" % [message, expected, actual])

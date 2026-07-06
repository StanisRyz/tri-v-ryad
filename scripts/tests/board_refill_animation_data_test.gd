extends SceneTree

const GRAVITY_RESOLVER_SCRIPT := preload("res://scripts/game/board/gravity_resolver.gd")
const BOARD_RESOLVER_SCRIPT := preload("res://scripts/game/board/board_resolver.gd")

var _failures := 0


func _initialize() -> void:
	print("Running board refill animation data test...")

	_test_refill_spawn_index_ordering()
	_test_board_resolver_exposes_fall_and_refill_data()

	_finish()


func _test_refill_spawn_index_ordering() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var resolver = GRAVITY_RESOLVER_SCRIPT.new(rng)
	var board := BoardModel.new()
	for y in range(BoardModel.DEFAULT_HEIGHT):
		for x in range(BoardModel.DEFAULT_WIDTH):
			board.set_tile(Vector2i(x, y), BoardModel.EMPTY)

	var result: Dictionary = resolver.apply_gravity_and_refill(board)
	var refill_cells: Array = result.get("refill_cells", [])
	_expect_equal(refill_cells.size(), BoardModel.DEFAULT_WIDTH * BoardModel.DEFAULT_HEIGHT, "empty board refills every cell")

	var column_cells: Array = []
	for refill_item in refill_cells:
		var data := refill_item as Dictionary
		var to_cell: Vector2i = data.get("to")
		if to_cell.x == 0:
			column_cells.append(data)

	column_cells.sort_custom(func(a, b): return int(a.get("spawn_index")) < int(b.get("spawn_index")))
	for index in range(column_cells.size()):
		_expect_equal(column_cells[index].get("spawn_index"), index, "spawn_index increases from bottom to top of the empty run")
		var to_cell: Vector2i = column_cells[index].get("to")
		_expect_equal(to_cell.y, BoardModel.DEFAULT_HEIGHT - 1 - index, "refill cell fills board from bottom upward")


func _test_board_resolver_exposes_fall_and_refill_data() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 13
	var resolver = BOARD_RESOLVER_SCRIPT.new(GRAVITY_RESOLVER_SCRIPT.new(rng))
	var board := _make_board_with_match_and_fall()

	var board_result = resolver.resolve_board(board)
	_expect_true(board_result.total_cleared >= 3, "board resolver clears the matched cells")
	_expect_true(not board_result.fall_movements.is_empty(), "board resolver exposes aggregated fall_movements")
	_expect_true(not board_result.refill_cells.is_empty(), "board resolver exposes aggregated refill_cells")
	_expect_true(not board_result.cascade_steps.is_empty(), "board resolver exposes cascade_steps")
	_expect_equal(board_result.cascade_steps[0].get("cascade_index"), 0, "first cascade step has index 0")


func _make_board_with_match_and_fall() -> BoardModel:
	var board := BoardModel.new()
	for y in range(BoardModel.DEFAULT_HEIGHT):
		for x in range(BoardModel.DEFAULT_WIDTH):
			board.set_tile(Vector2i(x, y), (x + y) % 5)

	board.set_tile(Vector2i(0, 8), TileType.RED)
	board.set_tile(Vector2i(1, 8), TileType.RED)
	board.set_tile(Vector2i(2, 8), TileType.RED)
	return board


func _finish() -> void:
	if _failures == 0:
		print("Board refill animation data test passed.")
		quit(0)
	else:
		push_error("Board refill animation data test failed: %d" % _failures)
		quit(1)


func _expect_true(value: bool, message: String) -> void:
	if value:
		return
	_failures += 1
	push_error("FAILED: %s" % message)


func _expect_equal(actual, expected, message: String) -> void:
	if actual == expected:
		return
	_failures += 1
	push_error("FAILED: %s | expected=%s actual=%s" % [message, expected, actual])

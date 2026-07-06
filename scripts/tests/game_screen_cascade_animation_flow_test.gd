extends SceneTree

var _failures := 0


func _initialize() -> void:
	print("Running game screen cascade animation flow test...")
	_run()
	_finish()


## Stage 46: cascades are no longer replayed from precomputed
## TurnPresentationData.cascade_steps fixtures; StepwiseBoardResolver must
## find and resolve a real cascade (a match only revealed once gravity
## settles) directly against a live BoardModel, one clear+gravity phase at a
## time, exactly like AnimatedTurnFlow drives it during a real turn.
func _run() -> void:
	var board := _build_cascade_board()
	var resolver := StepwiseBoardResolver.new()

	var cascade_count := 0
	var all_cleared_cells: Array[Vector2i] = []
	var matches := resolver.find_current_matches(board)
	_expect_true(not matches.is_empty(), "board has an initial match before any clearing")

	while not matches.is_empty() and cascade_count < 50:
		var step := resolver.build_clear_step(board, matches, cascade_count)
		resolver.apply_clear_step(board, step)
		resolver.apply_gravity_step(board, step)
		all_cleared_cells.append_array(step.cleared_cells)
		cascade_count += 1
		matches = resolver.find_current_matches(board)

	_expect_true(cascade_count < 50, "cascade loop terminates instead of hitting the safety cap")
	_expect_true(cascade_count >= 2, "clearing the initial match reveals a cascade match after gravity settles")
	_expect_true(Vector2i(0, 1) in all_cleared_cells, "initial vertical match cells are cleared")
	_expect_true(Vector2i(0, 4) in all_cleared_cells, "cascade match cell that fell into place is cleared")
	_expect_false(MatchFinder.new().has_matches(board), "board is stable once the cascade loop stops")
	_expect_false(board.has_empty_cells(), "board is fully refilled once the cascade loop stops")


func _build_cascade_board() -> BoardModel:
	var board := BoardModel.new()
	for y in range(board.height):
		for x in range(board.width):
			board.set_tile(Vector2i(x, y), (x + y) % 5)

	# Column 0: an initial vertical RED match at y=1..3, with a BLUE tile
	# above it (y=0) and two more BLUE tiles already sitting below it
	# (y=4..5). Clearing the RED match and settling gravity drops the BLUE
	# tile straight into a new vertical match, without needing another
	# player swap to trigger it.
	board.set_tile(Vector2i(0, 0), TileType.BLUE)
	board.set_tile(Vector2i(0, 1), TileType.RED)
	board.set_tile(Vector2i(0, 2), TileType.RED)
	board.set_tile(Vector2i(0, 3), TileType.RED)
	board.set_tile(Vector2i(0, 4), TileType.BLUE)
	board.set_tile(Vector2i(0, 5), TileType.BLUE)
	board.set_tile(Vector2i(0, 6), TileType.GREEN)
	board.set_tile(Vector2i(0, 7), TileType.YELLOW)
	board.set_tile(Vector2i(0, 8), TileType.PURPLE)
	return board


func _finish() -> void:
	if _failures == 0:
		print("Game screen cascade animation flow test passed.")
		quit(0)
	else:
		push_error("Game screen cascade animation flow test failed: %d" % _failures)
		quit(1)


func _expect_true(value: bool, message: String) -> void:
	if value:
		return
	_failures += 1
	push_error("FAILED: %s" % message)


func _expect_false(value: bool, message: String) -> void:
	_expect_true(not value, message)

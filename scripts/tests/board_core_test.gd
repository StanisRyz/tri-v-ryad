extends SceneTree

const GENERATION_COUNT := 100

var _failures := 0


func _initialize() -> void:
	print("Running board core tests...")

	_test_generate_boards_without_starting_matches()
	_test_horizontal_match_detection()
	_test_vertical_match_detection()
	_test_long_line_detected_as_one_match()
	_test_valid_adjacent_swap_accepted()
	_test_diagonal_swap_rejected()
	_test_no_match_swap_rejected_and_rolled_back()
	_test_swap_from_iced_cell_rejected()
	_test_swap_to_iced_cell_rejected()
	_test_inactive_cell_rejected_before_iced_cell()
	_test_clear_cells_creates_empty_cells()
	_test_gravity_refill_removes_empty_cells()
	_test_board_resolve_ends_full_and_stable()
	_test_resolve_records_step_for_starting_match()

	if _failures == 0:
		print("Board core tests passed.")
		quit(0)
	else:
		push_error("Board core tests failed: %d" % _failures)
		quit(1)


func _test_generate_boards_without_starting_matches() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1001
	var generator := BoardGenerator.new(rng)
	var finder := MatchFinder.new()

	for index in range(GENERATION_COUNT):
		var board := generator.generate()
		_expect_equal(board.width, BoardModel.DEFAULT_WIDTH, "generated board width")
		_expect_equal(board.height, BoardModel.DEFAULT_HEIGHT, "generated board height")
		_expect_false(board.has_empty_cells(), "generated board has no empty cells")
		_expect_false(finder.has_matches(board), "generated board %d has no starting matches" % index)

	print("ok - generated %d boards without starting matches" % GENERATION_COUNT)


func _test_horizontal_match_detection() -> void:
	var board := BoardModel.new()
	board.set_tile(Vector2i(1, 2), TileType.RED)
	board.set_tile(Vector2i(2, 2), TileType.RED)
	board.set_tile(Vector2i(3, 2), TileType.RED)

	var matches := MatchFinder.new().find_matches(board)
	_expect_equal(matches.size(), 1, "horizontal match count")
	_expect_equal(matches[0].direction, MatchResult.Direction.HORIZONTAL, "horizontal match direction")
	_expect_equal(matches[0].length(), 3, "horizontal match length")
	_expect_true(matches[0].contains_cell(Vector2i(2, 2)), "horizontal match contains center cell")

	print("ok - horizontal match detection")


func _test_vertical_match_detection() -> void:
	var board := BoardModel.new()
	board.set_tile(Vector2i(4, 1), TileType.BLUE)
	board.set_tile(Vector2i(4, 2), TileType.BLUE)
	board.set_tile(Vector2i(4, 3), TileType.BLUE)

	var matches := MatchFinder.new().find_matches(board)
	_expect_equal(matches.size(), 1, "vertical match count")
	_expect_equal(matches[0].direction, MatchResult.Direction.VERTICAL, "vertical match direction")
	_expect_equal(matches[0].length(), 3, "vertical match length")

	print("ok - vertical match detection")


func _test_long_line_detected_as_one_match() -> void:
	var board := BoardModel.new()
	for x in range(5):
		board.set_tile(Vector2i(x, 5), TileType.GREEN)

	var matches := MatchFinder.new().find_matches(board)
	_expect_equal(matches.size(), 1, "long line match count")
	_expect_equal(matches[0].length(), 5, "long line match length")

	print("ok - 4+ line detected as one match")


func _test_valid_adjacent_swap_accepted() -> void:
	var board := _create_stable_pattern_board()
	board.set_tile(Vector2i(0, 0), TileType.RED)
	board.set_tile(Vector2i(1, 0), TileType.BLUE)
	board.set_tile(Vector2i(2, 0), TileType.RED)
	board.set_tile(Vector2i(1, 1), TileType.RED)

	var result := SwapResolver.new().try_swap(board, Vector2i(1, 0), Vector2i(1, 1))
	_expect_true(result.accepted, "valid adjacent swap accepted")
	_expect_equal(result.reason, "", "accepted swap has no rejection reason")
	_expect_false(result.matches.is_empty(), "accepted swap reports matches")
	_expect_equal(board.get_tile(Vector2i(1, 0)), TileType.RED, "accepted swap remains applied")

	print("ok - valid adjacent swap accepted")


func _test_diagonal_swap_rejected() -> void:
	var board := _create_stable_pattern_board()
	var result := SwapResolver.new().try_swap(board, Vector2i(0, 0), Vector2i(1, 1))
	_expect_false(result.accepted, "diagonal swap rejected")
	_expect_equal(result.reason, "not_adjacent", "diagonal swap reason")

	print("ok - diagonal swap rejected")


func _test_no_match_swap_rejected_and_rolled_back() -> void:
	var board := _create_stable_pattern_board()
	var before := board.to_debug_string()

	var result := SwapResolver.new().try_swap(board, Vector2i(0, 0), Vector2i(1, 0))
	_expect_false(result.accepted, "no-match swap rejected")
	_expect_equal(result.reason, "no_match", "no-match swap reason")
	_expect_equal(board.to_debug_string(), before, "no-match swap rolled back")

	print("ok - adjacent no-match swap rejected and rolled back")


func _test_swap_from_iced_cell_rejected() -> void:
	var board := _create_stable_pattern_board()
	board.set_tile(Vector2i(0, 0), TileType.RED)
	board.set_tile(Vector2i(1, 0), TileType.BLUE)
	board.set_tile(Vector2i(2, 0), TileType.RED)
	board.set_tile(Vector2i(1, 1), TileType.RED)
	board.set_cell_obstacle(Vector2i(1, 0), CellObstacleType.ICE)

	var result := SwapResolver.new().try_swap(board, Vector2i(1, 0), Vector2i(1, 1))
	_expect_false(result.accepted, "swap from iced cell rejected")
	_expect_equal(result.reason, "iced_cell", "swap from iced cell reason")
	_expect_equal(board.get_tile(Vector2i(1, 0)), TileType.BLUE, "iced from-cell swap left unapplied")

	print("ok - swap from iced cell rejected")


func _test_swap_to_iced_cell_rejected() -> void:
	var board := _create_stable_pattern_board()
	board.set_tile(Vector2i(0, 0), TileType.RED)
	board.set_tile(Vector2i(1, 0), TileType.BLUE)
	board.set_tile(Vector2i(2, 0), TileType.RED)
	board.set_tile(Vector2i(1, 1), TileType.RED)
	board.set_cell_obstacle(Vector2i(1, 1), CellObstacleType.ICE)

	var result := SwapResolver.new().try_swap(board, Vector2i(1, 0), Vector2i(1, 1))
	_expect_false(result.accepted, "swap to iced cell rejected")
	_expect_equal(result.reason, "iced_cell", "swap to iced cell reason")
	_expect_equal(board.get_tile(Vector2i(1, 1)), TileType.RED, "iced to-cell swap left unapplied")

	print("ok - swap to iced cell rejected")


func _test_inactive_cell_rejected_before_iced_cell() -> void:
	var board := _create_stable_pattern_board()
	board.set_cell_active(Vector2i(1, 1), false)
	board.set_cell_obstacle(Vector2i(1, 0), CellObstacleType.ICE)

	var result := SwapResolver.new().try_swap(board, Vector2i(1, 0), Vector2i(1, 1))
	_expect_false(result.accepted, "inactive cell swap rejected")
	_expect_equal(result.reason, "inactive_cell", "inactive cell takes priority over iced_cell")

	print("ok - inactive cell rejected before iced cell")


func _test_clear_cells_creates_empty_cells() -> void:
	var board := _create_stable_pattern_board()
	board.clear_cells([Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)])
	_expect_true(board.has_empty_cells(), "clear cells creates empty cells")
	_expect_equal(board.get_tile(Vector2i(1, 0)), BoardModel.EMPTY, "cleared cell is empty")

	print("ok - clearing cells creates empty cells")


func _test_gravity_refill_removes_empty_cells() -> void:
	var board := _create_stable_pattern_board()
	board.clear_cells([Vector2i(0, 8), Vector2i(0, 7), Vector2i(2, 4)])

	var rng := RandomNumberGenerator.new()
	rng.seed = 2002
	var result := GravityResolver.new(rng).apply_gravity_and_refill(board)
	_expect_false(board.has_empty_cells(), "gravity refill removes empty cells")
	_expect_equal(result.get("spawned_cells", []).size(), 3, "gravity result spawned cell count")

	print("ok - gravity/refill removes empty cells")


func _test_board_resolve_ends_full_and_stable() -> void:
	var board := _create_board_with_starting_match()
	var rng := RandomNumberGenerator.new()
	rng.seed = 3003
	var resolver := BoardResolver.new(GravityResolver.new(rng))
	var result := resolver.resolve_board(board)

	_expect_false(board.has_empty_cells(), "resolved board has no empty cells")
	_expect_false(MatchFinder.new().has_matches(board), "resolved board has no immediate matches")
	_expect_true(result.total_cleared >= 3, "resolve cleared at least one match")

	print("ok - board resolve ends with full stable board")


func _test_resolve_records_step_for_starting_match() -> void:
	var board := _create_board_with_starting_match()
	var rng := RandomNumberGenerator.new()
	rng.seed = 4004
	var result := BoardResolver.new(GravityResolver.new(rng)).resolve_board(board)

	_expect_true(result.steps.size() >= 1, "resolve records at least one step")
	_expect_true(result.steps[0].get("cleared_cells", []).size() >= 3, "resolve step records cleared cells")
	_expect_true(result.steps[0].get("spawned_cells", []).size() >= 1, "resolve step records spawned cells")

	print("ok - resolve records step data")


func _create_stable_pattern_board() -> BoardModel:
	var board := BoardModel.new()
	var tile_types := TileType.get_all_types()

	for y in range(board.height):
		for x in range(board.width):
			board.set_tile(Vector2i(x, y), tile_types[(x + y * 2) % tile_types.size()])

	return board


func _create_board_with_starting_match() -> BoardModel:
	var board := _create_stable_pattern_board()
	board.set_tile(Vector2i(0, 0), TileType.YELLOW)
	board.set_tile(Vector2i(1, 0), TileType.YELLOW)
	board.set_tile(Vector2i(2, 0), TileType.YELLOW)
	return board


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

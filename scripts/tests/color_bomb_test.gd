extends SceneTree

const SpecialTileData := preload("res://scripts/game/board/special_tile_data.gd")
const SpecialTileResolver := preload("res://scripts/game/board/special_tile_resolver.gd")
const SpecialTileType := preload("res://scripts/game/board/special_tile_type.gd")

var _failures := 0


func _initialize() -> void:
	print("Running color bomb tests...")

	_test_color_bomb_type_helpers()
	_test_color_bomb_metadata()
	_test_match_length_special_priority()
	_test_board_resolver_creates_color_bomb_for_match_5()
	_test_color_bomb_activation_clears_target_type()
	_test_board_remains_full_and_stable_after_color_bomb()
	_test_existing_line_special_behavior_still_works()

	if _failures == 0:
		print("Color bomb tests passed.")
		quit(0)
	else:
		push_error("Color bomb tests failed: %d" % _failures)
		quit(1)


func _test_color_bomb_type_helpers() -> void:
	_expect_true(SpecialTileType.is_valid(SpecialTileType.COLOR_BOMB), "COLOR_BOMB is valid")
	_expect_false(SpecialTileType.is_line(SpecialTileType.COLOR_BOMB), "COLOR_BOMB is not a line special")
	_expect_true(SpecialTileType.is_color_bomb(SpecialTileType.COLOR_BOMB), "COLOR_BOMB helper returns true")
	_expect_true(SpecialTileType.get_marker_text(SpecialTileType.COLOR_BOMB) != "", "COLOR_BOMB marker is visible")

	print("ok - color bomb type helpers")


func _test_color_bomb_metadata() -> void:
	var data = SpecialTileData.from_type(SpecialTileType.COLOR_BOMB)
	var copy = data.duplicate_data()

	_expect_false(data.is_empty(), "color bomb metadata is not empty")
	_expect_true(data.is_color_bomb(), "color bomb metadata helper")
	_expect_false(data.is_horizontal_line(), "color bomb is not horizontal line")
	_expect_false(data.is_vertical_line(), "color bomb is not vertical line")
	_expect_true(copy.is_color_bomb(), "duplicate preserves color bomb metadata")

	print("ok - color bomb metadata")


func _test_match_length_special_priority() -> void:
	var resolver := SpecialTileResolver.new()
	var match_3 := _match([Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)])
	var match_4 := _match([Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1)])
	var match_5 := _match([Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2), Vector2i(4, 2)])

	_expect_equal(resolver.get_special_type_for_match(match_3), SpecialTileType.NONE, "match 3 creates no special")
	_expect_equal(resolver.get_special_type_for_match(match_4), SpecialTileType.LINE_HORIZONTAL, "match 4 creates a line special")
	_expect_equal(resolver.get_special_type_for_match(match_5), SpecialTileType.COLOR_BOMB, "match 5 creates a color bomb")
	_expect_false(SpecialTileType.is_line(resolver.get_special_type_for_match(match_5)), "match 5 does not create a line special")

	print("ok - match length special priority")


func _test_board_resolver_creates_color_bomb_for_match_5() -> void:
	var board := _create_stable_pattern_board()
	for x in range(5):
		board.set_tile(Vector2i(x, 0), TileType.RED)

	var result := _resolve_with_seed(board, 1818)

	_expect_equal(result.created_special_tiles.size(), 1, "match 5 created one special")
	_expect_equal(result.created_special_tiles[0].get("special_type"), SpecialTileType.COLOR_BOMB, "match 5 created color bomb")
	_expect_true(_board_has_special_type(board, SpecialTileType.COLOR_BOMB), "created color bomb remains on board after resolve")

	print("ok - BoardResolver creates color bomb for match 5")


func _test_color_bomb_activation_clears_target_type() -> void:
	var board := _create_color_bomb_activation_board()
	var target_cells := _collect_cells_with_tile(board, TileType.RED)

	var result := _resolve_with_seed(board, 1819)

	_expect_true(_has_activated_special_type(result, SpecialTileType.COLOR_BOMB), "color bomb activation recorded")
	for cell in target_cells:
		_expect_true(cell in result.special_cleared_cells, "color bomb records target cell %s as special-cleared" % [cell])

	print("ok - color bomb activation clears target tile type")


func _test_board_remains_full_and_stable_after_color_bomb() -> void:
	var board := _create_color_bomb_activation_board()

	_resolve_with_seed(board, 1820)

	_expect_false(board.has_empty_cells(), "board remains full after color bomb resolve")
	_expect_false(MatchFinder.new().has_matches(board), "board remains stable after color bomb resolve")

	print("ok - board remains full and stable after color bomb")


func _test_existing_line_special_behavior_still_works() -> void:
	var board := _create_stable_pattern_board()
	for x in range(3):
		board.set_tile(Vector2i(x, 0), TileType.YELLOW)
	board.set_special_tile(Vector2i(1, 0), SpecialTileData.from_type(SpecialTileType.LINE_HORIZONTAL))

	var result := _resolve_with_seed(board, 1821)

	_expect_true(_has_activated_special_type(result, SpecialTileType.LINE_HORIZONTAL), "line special still activates")
	_expect_true(Vector2i(8, 0) in result.special_cleared_cells, "line special still clears row")

	print("ok - existing line special behavior still works")


func _create_color_bomb_activation_board() -> BoardModel:
	var board := _create_stable_pattern_board()
	for x in range(3):
		board.set_tile(Vector2i(x, 0), TileType.RED)
	board.set_special_tile(Vector2i(1, 0), SpecialTileData.from_type(SpecialTileType.COLOR_BOMB))
	return board


func _resolve_with_seed(board: BoardModel, seed_value: int) -> BoardResolveResult:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return BoardResolver.new(GravityResolver.new(rng)).resolve_board(board)


func _create_stable_pattern_board() -> BoardModel:
	var board := BoardModel.new()
	var tile_types := TileType.get_all_types()

	for y in range(board.height):
		for x in range(board.width):
			board.set_tile(Vector2i(x, y), tile_types[(x + y * 2) % tile_types.size()])

	return board


func _collect_cells_with_tile(board: BoardModel, tile_type: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for cell in board.get_all_cells():
		if board.get_tile(cell) == tile_type:
			cells.append(cell)
	return cells


func _board_has_special_type(board: BoardModel, special_type: int) -> bool:
	for cell in board.get_special_cells():
		var special_data = board.get_special_tile(cell)
		if special_data != null and special_data.special_type == special_type:
			return true

	return false


func _has_activated_special_type(result: BoardResolveResult, special_type: int) -> bool:
	for activated_special in result.activated_special_tiles:
		if activated_special.get("special_type") == special_type:
			return true

	return false


func _match(raw_cells: Array, direction: MatchResult.Direction = MatchResult.Direction.HORIZONTAL) -> MatchResult:
	var cells: Array[Vector2i] = []
	for cell in raw_cells:
		cells.append(cell)
	return MatchResult.new(cells, TileType.RED, direction)


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

extends SceneTree

const SpecialTileData := preload("res://scripts/game/board/special_tile_data.gd")
const SpecialTileResolver := preload("res://scripts/game/board/special_tile_resolver.gd")
const SpecialTileType := preload("res://scripts/game/board/special_tile_type.gd")

var _failures := 0


func _initialize() -> void:
	print("Running special tile tests...")

	_test_special_tile_type_helpers()
	_test_board_model_special_metadata()
	_test_board_model_swaps_special_metadata()
	_test_clear_cells_removes_special_metadata()
	_test_duplicate_board_copies_special_metadata()
	_test_gravity_moves_special_metadata()
	_test_special_resolver_match_rules()
	_test_line_clear_cells()
	_test_board_resolver_creates_line_special_for_match_4()
	_test_board_resolver_does_not_create_special_for_match_3()
	_test_board_resolver_activates_horizontal_line()
	_test_board_resolver_activates_vertical_line()
	_test_board_resolver_leaves_board_full_after_specials()
	_test_existing_match_3_behavior_still_clears()

	if _failures == 0:
		print("Special tile tests passed.")
		quit(0)
	else:
		push_error("Special tile tests failed: %d" % _failures)
		quit(1)


func _test_special_tile_type_helpers() -> void:
	_expect_true(SpecialTileType.is_valid(SpecialTileType.NONE), "NONE is valid")
	_expect_true(SpecialTileType.is_valid(SpecialTileType.LINE_HORIZONTAL), "horizontal line is valid")
	_expect_true(SpecialTileType.is_valid(SpecialTileType.LINE_VERTICAL), "vertical line is valid")
	_expect_true(SpecialTileType.is_valid(SpecialTileType.COLOR_BOMB), "color bomb is valid")
	_expect_false(SpecialTileType.is_valid(99), "unknown special type is invalid")
	_expect_true(SpecialTileType.is_line(SpecialTileType.LINE_HORIZONTAL), "horizontal line helper")
	_expect_false(SpecialTileType.is_line(SpecialTileType.COLOR_BOMB), "color bomb is not line")
	_expect_true(SpecialTileType.is_color_bomb(SpecialTileType.COLOR_BOMB), "color bomb helper")
	_expect_equal(SpecialTileType.get_marker_text(SpecialTileType.LINE_VERTICAL), "V", "vertical marker text")
	_expect_equal(SpecialTileType.get_marker_text(SpecialTileType.COLOR_BOMB), "B", "color bomb marker text")

	print("ok - SpecialTileType helpers")


func _test_board_model_special_metadata() -> void:
	var board := BoardModel.new()
	var cell := Vector2i(2, 2)
	board.set_special_tile(cell, SpecialTileData.from_type(SpecialTileType.LINE_HORIZONTAL))

	_expect_true(board.has_special_tile(cell), "board has special metadata")
	_expect_true(board.get_special_tile(cell).is_horizontal_line(), "board returns horizontal line metadata")

	board.clear_special_tile(cell)
	_expect_false(board.has_special_tile(cell), "clear special metadata")

	print("ok - BoardModel set/get/clear special metadata")


func _test_board_model_swaps_special_metadata() -> void:
	var board := _create_stable_pattern_board()
	var a := Vector2i(0, 0)
	var b := Vector2i(1, 0)
	board.set_special_tile(a, SpecialTileData.from_type(SpecialTileType.LINE_VERTICAL))

	board.swap_tiles(a, b)

	_expect_false(board.has_special_tile(a), "swap clears special from source")
	_expect_true(board.has_special_tile(b), "swap moves special to target")
	_expect_true(board.get_special_tile(b).is_vertical_line(), "swap preserves special type")

	print("ok - BoardModel swaps special metadata")


func _test_clear_cells_removes_special_metadata() -> void:
	var board := _create_stable_pattern_board()
	var cell := Vector2i(3, 3)
	board.set_special_tile(cell, SpecialTileData.from_type(SpecialTileType.LINE_HORIZONTAL))

	board.clear_cells([cell])

	_expect_equal(board.get_tile(cell), BoardModel.EMPTY, "clear cells empties base tile")
	_expect_false(board.has_special_tile(cell), "clear cells removes special metadata")

	print("ok - BoardModel clear_cells removes special metadata")


func _test_duplicate_board_copies_special_metadata() -> void:
	var board := _create_stable_pattern_board()
	var cell := Vector2i(4, 4)
	board.set_special_tile(cell, SpecialTileData.from_type(SpecialTileType.LINE_VERTICAL))

	var copy := board.duplicate_board()
	board.clear_special_tile(cell)

	_expect_false(board.has_special_tile(cell), "source special can be changed after duplicate")
	_expect_true(copy.has_special_tile(cell), "duplicate keeps copied special")
	_expect_true(copy.get_special_tile(cell).is_vertical_line(), "duplicate preserves special type")

	print("ok - duplicate_board copies special metadata safely")


func _test_gravity_moves_special_metadata() -> void:
	var board := _create_stable_pattern_board()
	var source := Vector2i(0, 0)
	board.set_special_tile(source, SpecialTileData.from_type(SpecialTileType.LINE_HORIZONTAL))
	board.clear_cells([Vector2i(0, 8)])

	var rng := RandomNumberGenerator.new()
	rng.seed = 101
	var result := GravityResolver.new(rng).apply_gravity_and_refill(board)

	_expect_true(board.has_special_tile(Vector2i(0, 1)), "gravity moves special metadata down with tile")
	_expect_false(board.has_special_tile(source), "refilled cell has no special metadata")
	_expect_true(Vector2i(0, 0) in result.get("spawned_cells", []), "top refill cell recorded")

	print("ok - GravityResolver moves special metadata and refills clean tiles")


func _test_special_resolver_match_rules() -> void:
	var resolver := SpecialTileResolver.new()
	var horizontal := MatchResult.new([Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)], TileType.RED, MatchResult.Direction.HORIZONTAL)
	var vertical := MatchResult.new([Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2), Vector2i(1, 3)], TileType.BLUE, MatchResult.Direction.VERTICAL)
	var short := MatchResult.new([Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)], TileType.GREEN, MatchResult.Direction.HORIZONTAL)
	var long := MatchResult.new([Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2), Vector2i(4, 2)], TileType.YELLOW, MatchResult.Direction.HORIZONTAL)

	_expect_true(resolver.should_create_special(horizontal), "match 4 creates special")
	_expect_false(resolver.should_create_special(short), "match 3 does not create special")
	_expect_equal(resolver.get_special_type_for_match(horizontal), SpecialTileType.LINE_HORIZONTAL, "horizontal match creates horizontal line")
	_expect_equal(resolver.get_special_type_for_match(vertical), SpecialTileType.LINE_VERTICAL, "vertical match creates vertical line")
	_expect_equal(resolver.get_special_type_for_match(short), SpecialTileType.NONE, "match 3 returns no special type")
	_expect_equal(resolver.get_special_type_for_match(long), SpecialTileType.COLOR_BOMB, "match 5 creates color bomb")
	_expect_equal(resolver.choose_special_cell(horizontal), Vector2i(2, 0), "middle cell chosen deterministically")

	print("ok - SpecialTileResolver match rules")


func _test_line_clear_cells() -> void:
	var board := BoardModel.new(5, 4)
	var resolver := SpecialTileResolver.new()
	var horizontal_cells := resolver.get_line_clear_cells(board, Vector2i(2, 1), SpecialTileData.from_type(SpecialTileType.LINE_HORIZONTAL))
	var vertical_cells := resolver.get_line_clear_cells(board, Vector2i(2, 1), SpecialTileData.from_type(SpecialTileType.LINE_VERTICAL))

	_expect_equal(horizontal_cells.size(), 5, "horizontal line clears row width")
	_expect_true(Vector2i(0, 1) in horizontal_cells and Vector2i(4, 1) in horizontal_cells, "horizontal line row endpoints")
	_expect_equal(vertical_cells.size(), 4, "vertical line clears column height")
	_expect_true(Vector2i(2, 0) in vertical_cells and Vector2i(2, 3) in vertical_cells, "vertical line column endpoints")

	print("ok - line clear cell collection")


func _test_board_resolver_creates_line_special_for_match_4() -> void:
	var board := _create_stable_pattern_board()
	for x in range(4):
		board.set_tile(Vector2i(x, 0), TileType.RED)

	var result := _resolve_with_seed(board, 202)

	_expect_equal(result.created_special_tiles.size(), 1, "match 4 created one special")
	_expect_equal(result.created_special_tiles[0].get("special_type"), SpecialTileType.LINE_HORIZONTAL, "match 4 created horizontal line")
	_expect_true(board.get_special_cells().size() >= 1, "created special remains on board after resolve")

	print("ok - BoardResolver creates line special for match 4")


func _test_board_resolver_does_not_create_special_for_match_3() -> void:
	var board := _create_stable_pattern_board()
	for x in range(3):
		board.set_tile(Vector2i(x, 0), TileType.BLUE)

	var result := _resolve_with_seed(board, 303)

	_expect_equal(result.created_special_tiles.size(), 0, "match 3 creates no special")

	print("ok - BoardResolver keeps match 3 special-free")


func _test_board_resolver_activates_horizontal_line() -> void:
	var board := _create_stable_pattern_board()
	for x in range(3):
		board.set_tile(Vector2i(x, 0), TileType.YELLOW)
	board.set_special_tile(Vector2i(1, 0), SpecialTileData.from_type(SpecialTileType.LINE_HORIZONTAL))

	var result := _resolve_with_seed(board, 404)

	_expect_true(result.activated_special_tiles.size() >= 1, "horizontal special activated")
	_expect_true(_has_activated_special_type(result, SpecialTileType.LINE_HORIZONTAL), "activated horizontal special type")
	_expect_true(Vector2i(8, 0) in result.special_cleared_cells, "horizontal activation clears row")

	print("ok - BoardResolver activates horizontal line")


func _test_board_resolver_activates_vertical_line() -> void:
	var board := _create_stable_pattern_board()
	for y in range(3):
		board.set_tile(Vector2i(0, y), TileType.PURPLE)
	board.set_special_tile(Vector2i(0, 1), SpecialTileData.from_type(SpecialTileType.LINE_VERTICAL))

	var result := _resolve_with_seed(board, 505)

	_expect_true(result.activated_special_tiles.size() >= 1, "vertical special activated")
	_expect_true(_has_activated_special_type(result, SpecialTileType.LINE_VERTICAL), "activated vertical special type")
	_expect_true(Vector2i(0, 8) in result.special_cleared_cells, "vertical activation clears column")

	print("ok - BoardResolver activates vertical line")


func _test_board_resolver_leaves_board_full_after_specials() -> void:
	var board := _create_stable_pattern_board()
	for x in range(3):
		board.set_tile(Vector2i(x, 0), TileType.GREEN)
	board.set_special_tile(Vector2i(1, 0), SpecialTileData.from_type(SpecialTileType.LINE_HORIZONTAL))

	_resolve_with_seed(board, 606)

	_expect_false(board.has_empty_cells(), "resolved special board has no empty cells")
	_expect_false(MatchFinder.new().has_matches(board), "resolved special board is stable")

	print("ok - BoardResolver leaves board full after specials")


func _test_existing_match_3_behavior_still_clears() -> void:
	var board := _create_stable_pattern_board()
	for x in range(3):
		board.set_tile(Vector2i(x, 0), TileType.RED)

	var result := _resolve_with_seed(board, 707)

	_expect_true(result.total_cleared >= 3, "match 3 still clears cells")
	_expect_equal(result.created_special_tiles.size(), 0, "match 3 still creates no special")

	print("ok - existing match 3 behavior still works")


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


func _has_activated_special_type(result: BoardResolveResult, special_type: int) -> bool:
	for activated_special in result.activated_special_tiles:
		if activated_special.get("special_type") == special_type:
			return true

	return false


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

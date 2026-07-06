extends SceneTree

const BOARD_VIEW := preload("res://scenes/game/BoardView.tscn")

var _failures := 0


func _initialize() -> void:
	print("Running board visual snapshot test...")
	_run()


func _run() -> void:
	_expect_true(BoardVisualSnapshot.from_board_view(null).is_empty(), "snapshot is safe and empty when BoardView is null")

	var board_view: BoardView = BOARD_VIEW.instantiate()
	board_view.size = Vector2(664, 664)
	root.add_child(board_view)
	await process_frame
	board_view.set_board(_create_board())
	await process_frame

	var snapshot := BoardVisualSnapshot.from_board_view(board_view)
	_expect_equal(snapshot.size(), 81, "snapshot captures all 81 board cells")
	_expect_false(snapshot.is_empty(), "snapshot with data is not empty")

	var cell := Vector2i(2, 3)
	_expect_true(snapshot.has_cell(cell), "snapshot has a captured cell")
	var data := snapshot.get_cell_data(cell)
	_expect_equal(data.get("tile_type"), board_view.get_tile_view(cell).tile_type, "snapshot cell tile_type matches TileView")
	_expect_true(data.has("global_position"), "snapshot cell data has global_position")
	_expect_true(data.has("local_position"), "snapshot cell data has local_position")
	_expect_true(data.has("size"), "snapshot cell data has size")

	_expect_true(snapshot.get_cell_data(Vector2i(-5, -5)).is_empty(), "snapshot returns empty data for a missing cell safely")
	_expect_false(snapshot.has_cell(Vector2i(-5, -5)), "snapshot reports missing cell as absent")
	_expect_equal(snapshot.get_cells().size(), 81, "get_cells returns all captured cells")

	var tile_type_before: int = board_view.get_tile_view(cell).tile_type
	snapshot = BoardVisualSnapshot.from_board_view(board_view)
	_expect_equal(board_view.get_tile_view(cell).tile_type, tile_type_before, "capturing a snapshot does not mutate BoardView")

	board_view.free()
	_finish()


func _create_board() -> BoardModel:
	var board := BoardModel.new()
	for y in range(BoardModel.DEFAULT_HEIGHT):
		for x in range(BoardModel.DEFAULT_WIDTH):
			board.set_tile(Vector2i(x, y), (x + y) % 5)
	return board


func _finish() -> void:
	if _failures == 0:
		print("Board visual snapshot test passed.")
		quit(0)
	else:
		push_error("Board visual snapshot test failed: %d" % _failures)
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

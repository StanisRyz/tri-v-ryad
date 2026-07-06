extends SceneTree

const BOARD_VIEW := preload("res://scenes/game/BoardView.tscn")

var _failures := 0


func _initialize() -> void:
	print("Running board invalid swap animation test...")
	_run()


func _run() -> void:
	var board_view: BoardView = BOARD_VIEW.instantiate()
	board_view.size = Vector2(664, 664)
	root.add_child(board_view)
	await process_frame
	var board := _create_board()
	board_view.set_board(board)
	await process_frame

	var before_from: int = board.get_tile(Vector2i(0, 0))
	var before_to: int = board.get_tile(Vector2i(1, 0))
	board_view.play_invalid_swap_animation(Vector2i(0, 0), Vector2i(1, 0), 0.06)
	await process_frame
	_expect_equal(board.get_tile(Vector2i(0, 0)), before_from, "invalid animation does not change from tile")
	_expect_equal(board.get_tile(Vector2i(1, 0)), before_to, "invalid animation does not change to tile")
	_expect_true(board_view.get_tile_view(Vector2i(0, 0)).visible, "invalid animation keeps first tile visible")
	_expect_true(board_view.get_tile_view(Vector2i(1, 0)).visible, "invalid animation keeps second tile visible")

	await create_timer(0.12).timeout
	_expect_equal(board_view.get_tile_view(Vector2i(0, 0)).position, Vector2.ZERO, "invalid animation returns first tile position")
	_expect_equal(board_view.get_tile_view(Vector2i(1, 0)).position, Vector2.ZERO, "invalid animation returns second tile position")

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
		print("Board invalid swap animation test passed.")
		quit(0)
	else:
		push_error("Board invalid swap animation test failed: %d" % _failures)
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

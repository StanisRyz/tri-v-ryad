extends SceneTree

const BOARD_VIEW := preload("res://scenes/game/BoardView.tscn")

var _failures := 0


func _initialize() -> void:
	print("Running board swap animation test...")
	_run()


func _run() -> void:
	var board_view: BoardView = BOARD_VIEW.instantiate()
	board_view.size = Vector2(664, 664)
	root.add_child(board_view)
	await process_frame
	board_view.set_board(_create_board())
	await process_frame

	_expect_true(board_view.get_animation_layer() != null, "board view has animation layer")
	board_view.play_swap_animation(Vector2i(0, 0), Vector2i(1, 0), 0.05)
	_expect_equal(board_view.get_animation_layer().get_child_count(), 2, "swap creates two ghost tiles")
	_expect_false(board_view.get_tile_view(Vector2i(0, 0)).visible, "swap hides first original tile")
	_expect_false(board_view.get_tile_view(Vector2i(1, 0)).visible, "swap hides second original tile")

	await create_timer(0.20).timeout
	_expect_equal(board_view.get_animation_layer().get_child_count(), 0, "swap cleans ghost tiles")
	_expect_true(board_view.get_tile_view(Vector2i(0, 0)).visible, "swap restores first original tile")
	_expect_true(board_view.get_tile_view(Vector2i(1, 0)).visible, "swap restores second original tile")

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
		print("Board swap animation test passed.")
		quit(0)
	else:
		push_error("Board swap animation test failed: %d" % _failures)
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

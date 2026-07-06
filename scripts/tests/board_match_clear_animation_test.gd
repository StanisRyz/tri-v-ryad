extends SceneTree

const BOARD_VIEW := preload("res://scenes/game/BoardView.tscn")

var _failures := 0


func _initialize() -> void:
	print("Running board match clear animation test...")
	_run()


func _run() -> void:
	var board_view: BoardView = BOARD_VIEW.instantiate()
	board_view.size = Vector2(664, 664)
	root.add_child(board_view)
	await process_frame
	board_view.set_board(_create_board())
	await process_frame

	var cells: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)]
	board_view.play_match_clear_animation(cells, 0.06)
	_expect_true(board_view.get_tile_view(Vector2i(0, 0)).scale != Vector2.ONE or board_view.get_tile_view(Vector2i(0, 0)).modulate != Color.WHITE, "match clear starts visible effect")
	await create_timer(0.12).timeout
	_expect_equal(board_view.get_tile_view(Vector2i(0, 0)).scale, Vector2.ONE, "match clear restores scale")
	_expect_equal(board_view.get_tile_view(Vector2i(0, 0)).modulate, Color.WHITE, "match clear restores color")

	board_view.play_special_clear_animation(cells, 0.06)
	_expect_true(board_view.get_tile_view(Vector2i(1, 0)).scale != Vector2.ONE or board_view.get_tile_view(Vector2i(1, 0)).modulate != Color.WHITE, "special clear starts stronger placeholder effect")
	await create_timer(0.12).timeout
	_expect_equal(board_view.get_tile_view(Vector2i(1, 0)).scale, Vector2.ONE, "special clear restores scale")
	_expect_equal(board_view.get_tile_view(Vector2i(1, 0)).modulate, Color.WHITE, "special clear restores color")

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
		print("Board match clear animation test passed.")
		quit(0)
	else:
		push_error("Board match clear animation test failed: %d" % _failures)
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

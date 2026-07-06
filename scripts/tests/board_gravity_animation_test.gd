extends SceneTree

const BOARD_VIEW := preload("res://scenes/game/BoardView.tscn")

var _failures := 0


func _initialize() -> void:
	print("Running board gravity animation test...")
	_run()


func _run() -> void:
	var board_view: BoardView = BOARD_VIEW.instantiate()
	board_view.size = Vector2(664, 664)
	root.add_child(board_view)
	await process_frame
	board_view.set_board(_create_board())
	await process_frame

	var to_tile_start_position: Vector2 = board_view.get_tile_view(Vector2i(0, 1)).position

	board_view.play_gravity_fall_animation([], 0.1)
	_expect_equal(board_view.get_animation_layer().get_child_count(), 0, "empty movements do not create ghosts")

	var movements: Array = [{"from": Vector2i(0, 0), "to": Vector2i(0, 1), "tile_type": TileType.RED, "special_data": null, "fall_distance": 1}]
	board_view.play_gravity_fall_animation(movements, 0.05)
	_expect_equal(board_view.get_animation_layer().get_child_count(), 1, "gravity fall creates a ghost per movement")
	_expect_false(board_view.get_tile_view(Vector2i(0, 0)).visible, "gravity fall hides source tile visual")
	_expect_false(board_view.get_tile_view(Vector2i(0, 1)).visible, "gravity fall hides target tile visual")

	await create_timer(0.25).timeout
	_expect_equal(board_view.get_animation_layer().get_child_count(), 0, "gravity fall cleans up ghosts")
	_expect_true(board_view.get_tile_view(Vector2i(0, 0)).visible, "gravity fall restores source tile visual")
	_expect_true(board_view.get_tile_view(Vector2i(0, 1)).visible, "gravity fall restores target tile visual")
	_expect_equal(board_view.get_tile_view(Vector2i(0, 1)).position, to_tile_start_position, "real TileView node keeps its container-managed position")

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
		print("Board gravity animation test passed.")
		quit(0)
	else:
		push_error("Board gravity animation test failed: %d" % _failures)
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

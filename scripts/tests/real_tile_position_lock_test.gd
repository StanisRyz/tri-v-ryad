extends SceneTree

const BOARD_VIEW := preload("res://scenes/game/BoardView.tscn")

var _failures := 0


func _initialize() -> void:
	print("Running real tile position lock test...")
	_run()


func _run() -> void:
	var board_view: BoardView = BOARD_VIEW.instantiate()
	board_view.size = Vector2(664, 664)
	root.add_child(board_view)
	await process_frame
	board_view.set_board(_create_board())
	await process_frame

	var start_positions: Dictionary = {}
	for cell in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(4, 4)]:
		start_positions[cell] = board_view.get_tile_view(cell).position

	# Legacy (non-overlay) swap must not move the real TileView node.
	board_view.play_swap_animation(Vector2i(0, 0), Vector2i(1, 0), 0.05)
	for cell in [Vector2i(0, 0), Vector2i(1, 0)]:
		_expect_equal(board_view.get_tile_view(cell).position, start_positions[cell], "real tile position unchanged mid-swap: %s" % cell)
	await create_timer(0.2).timeout
	for cell in [Vector2i(0, 0), Vector2i(1, 0)]:
		_expect_equal(board_view.get_tile_view(cell).position, start_positions[cell], "real tile position unchanged after swap: %s" % cell)

	# Legacy gravity fall must not move the real TileView node.
	var movements: Array = [{"from": Vector2i(0, 0), "to": Vector2i(0, 1), "tile_type": TileType.RED, "special_data": null, "fall_distance": 1}]
	board_view.play_gravity_fall_animation(movements, 0.05)
	_expect_equal(board_view.get_tile_view(Vector2i(0, 1)).position, start_positions[Vector2i(0, 1)], "real tile position unchanged mid-fall")
	await create_timer(0.2).timeout
	_expect_equal(board_view.get_tile_view(Vector2i(0, 1)).position, start_positions[Vector2i(0, 1)], "real tile position unchanged after fall")

	# Overlay-mode swap must also never move the real TileView node (only the
	# ghost in AnimationLayer moves).
	var snapshot := BoardVisualSnapshot.from_board_view(board_view)
	board_view.enter_animation_overlay_mode(snapshot)
	board_view.play_swap_animation(Vector2i(4, 4), Vector2i(5, 4), 0.05)
	_expect_equal(board_view.get_tile_view(Vector2i(4, 4)).position, start_positions.get(Vector2i(4, 4), board_view.get_tile_view(Vector2i(4, 4)).position), "real tile position unchanged during overlay swap")
	await create_timer(0.2).timeout
	board_view.exit_animation_overlay_mode()
	_expect_equal(board_view.get_tile_view(Vector2i(4, 4)).position, start_positions[Vector2i(4, 4)], "real tile position unchanged after overlay swap exit")

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
		print("Real tile position lock test passed.")
		quit(0)
	else:
		push_error("Real tile position lock test failed: %d" % _failures)
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

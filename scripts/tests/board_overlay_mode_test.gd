extends SceneTree

const BOARD_VIEW := preload("res://scenes/game/BoardView.tscn")

var _failures := 0


func _initialize() -> void:
	print("Running board overlay mode test...")
	_run()


func _run() -> void:
	var board_view: BoardView = BOARD_VIEW.instantiate()
	board_view.size = Vector2(664, 664)
	root.add_child(board_view)
	await process_frame
	board_view.set_board(_create_board())
	await process_frame

	_expect_false(board_view.is_animation_overlay_mode(), "board view starts outside overlay mode")

	var snapshot := BoardVisualSnapshot.from_board_view(board_view)
	board_view.enter_animation_overlay_mode(snapshot)
	_expect_true(board_view.is_animation_overlay_mode(), "enter_animation_overlay_mode enables overlay mode")
	_expect_equal(board_view.get_animation_layer().get_child_count(), 81, "overlay mode builds a full-board ghost layer")

	for cell in [Vector2i(0, 0), Vector2i(4, 4), Vector2i(8, 8)]:
		_expect_false(board_view.get_tile_view(cell).visible, "overlay mode hides real tile at %s" % cell)

	# Repeated enter calls are safe and do not leak ghosts.
	board_view.enter_animation_overlay_mode(snapshot)
	_expect_equal(board_view.get_animation_layer().get_child_count(), 81, "repeated enter_animation_overlay_mode does not duplicate ghosts")

	board_view.exit_animation_overlay_mode()
	_expect_false(board_view.is_animation_overlay_mode(), "exit_animation_overlay_mode disables overlay mode")
	_expect_equal(board_view.get_animation_layer().get_child_count(), 0, "exit_animation_overlay_mode clears ghosts")
	for cell in [Vector2i(0, 0), Vector2i(4, 4), Vector2i(8, 8)]:
		_expect_true(board_view.get_tile_view(cell).visible, "exit_animation_overlay_mode restores real tile at %s" % cell)

	# Repeated exit calls are safe.
	board_view.exit_animation_overlay_mode()
	_expect_false(board_view.is_animation_overlay_mode(), "repeated exit_animation_overlay_mode stays safe")

	# force_reset_animation_state clears overlay, ghosts, and tile visual drift.
	board_view.enter_animation_overlay_mode(snapshot)
	var some_tile := board_view.get_tile_view(Vector2i(1, 1))
	some_tile.scale = Vector2(2.0, 2.0)
	some_tile.modulate = Color(1, 0, 0, 0.2)
	some_tile.position = Vector2(999, 999)
	board_view.force_reset_animation_state()
	_expect_false(board_view.is_animation_overlay_mode(), "force_reset_animation_state exits overlay mode")
	_expect_equal(board_view.get_animation_layer().get_child_count(), 0, "force_reset_animation_state clears AnimationLayer")
	_expect_true(some_tile.visible, "force_reset_animation_state restores tile visibility")
	_expect_equal(some_tile.scale, Vector2.ONE, "force_reset_animation_state restores tile scale")
	_expect_equal(some_tile.modulate, Color.WHITE, "force_reset_animation_state restores tile modulate")
	_expect_equal(some_tile.position, Vector2.ZERO, "force_reset_animation_state restores tile position safety")

	# Animations-disabled path must never leave the board hidden: entering with a
	# null/empty snapshot must not hide the real board.
	board_view.enter_animation_overlay_mode(null)
	_expect_false(board_view.is_animation_overlay_mode(), "entering overlay mode with a null snapshot is a no-op")
	for cell in [Vector2i(0, 0), Vector2i(4, 4)]:
		_expect_true(board_view.get_tile_view(cell).visible, "board stays visible when overlay entry is skipped")

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
		print("Board overlay mode test passed.")
		quit(0)
	else:
		push_error("Board overlay mode test failed: %d" % _failures)
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

extends SceneTree

const BOARD_VIEW := preload("res://scenes/game/BoardView.tscn")

var _failures := 0


func _initialize() -> void:
	print("Running board animation cleanup test...")
	_run()


func _run() -> void:
	var board_view: BoardView = BOARD_VIEW.instantiate()
	board_view.size = Vector2(664, 664)
	root.add_child(board_view)
	await process_frame
	board_view.set_board(_create_board())
	await process_frame

	# Cleanup during a legacy (non-overlay) in-flight swap tween.
	board_view.play_swap_animation(Vector2i(0, 0), Vector2i(1, 0), 5.0)
	_expect_true(board_view.get_animation_layer().get_child_count() > 0, "swap animation is mid-flight before cleanup")
	board_view.force_reset_animation_state()
	_expect_equal(board_view.get_animation_layer().get_child_count(), 0, "force reset clears AnimationLayer during in-flight swap")
	_expect_true(board_view.get_tile_view(Vector2i(0, 0)).visible, "force reset restores hidden tile after in-flight swap")
	_expect_true(board_view.get_tile_view(Vector2i(1, 0)).visible, "force reset restores second hidden tile after in-flight swap")

	# Cleanup during an overlay-mode swap tween.
	var snapshot := BoardVisualSnapshot.from_board_view(board_view)
	board_view.enter_animation_overlay_mode(snapshot)
	board_view.play_swap_animation(Vector2i(2, 2), Vector2i(3, 2), 5.0)
	_expect_true(board_view.is_animation_overlay_mode(), "overlay mode active during swap")
	board_view.force_reset_animation_state()
	_expect_false(board_view.is_animation_overlay_mode(), "force reset exits overlay mode mid-swap")
	_expect_equal(board_view.get_animation_layer().get_child_count(), 0, "force reset clears overlay ghosts mid-swap")
	for cell in [Vector2i(2, 2), Vector2i(3, 2)]:
		_expect_true(board_view.get_tile_view(cell).visible, "force reset restores real tiles after overlay swap cleanup")

	# Idempotent: calling force reset again on a clean board does nothing bad.
	board_view.force_reset_animation_state()
	_expect_false(board_view.is_animation_overlay_mode(), "repeated force reset stays safe")
	_expect_equal(board_view.get_animation_layer().get_child_count(), 0, "repeated force reset keeps AnimationLayer empty")

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
		print("Board animation cleanup test passed.")
		quit(0)
	else:
		push_error("Board animation cleanup test failed: %d" % _failures)
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

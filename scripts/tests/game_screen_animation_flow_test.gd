extends SceneTree

const GAME_SCREEN := preload("res://scenes/screens/GameScreen.tscn")

var _failures := 0


func _initialize() -> void:
	print("Running game screen animation flow test...")
	_run()


func _run() -> void:
	var screen = GAME_SCREEN.instantiate()
	root.add_child(screen)
	await process_frame

	_expect_true(screen._board_animation_controller != null, "game screen creates board animation controller")
	_expect_true(screen._board_animation_sequence_builder != null, "game screen creates sequence builder")

	var swap := _find_valid_swap(screen._presenter.board)
	_expect_true(not swap.is_empty(), "game screen board has valid swap")
	if not swap.is_empty():
		screen._on_swap_requested(swap["from"], swap["to"])
		_expect_false(screen._input_controller._input_enabled, "input is locked during animated turn flow")
		await create_timer(2.0).timeout
		_expect_false(screen._feedback_active, "turn animation and feedback finish")
		if not screen._presenter.is_battle_finished():
			_expect_true(screen._input_controller._input_enabled, "input unlocks after animation and feedback")

	screen.queue_free()
	await process_frame
	_finish()


func _find_valid_swap(board) -> Dictionary:
	var swap_resolver = SwapResolver.new()
	for cell in board.get_all_cells():
		for offset in [Vector2i.RIGHT, Vector2i.DOWN]:
			var neighbor: Vector2i = cell + offset
			if not board.is_inside(neighbor):
				continue
			var copy = board.duplicate_board()
			if swap_resolver.try_swap(copy, cell, neighbor).accepted:
				return {"from": cell, "to": neighbor}
	return {}


func _finish() -> void:
	if _failures == 0:
		print("Game screen animation flow test passed.")
		quit(0)
	else:
		push_error("Game screen animation flow test failed: %d" % _failures)
		quit(1)


func _expect_true(value: bool, message: String) -> void:
	if value:
		return
	_failures += 1
	push_error("FAILED: %s" % message)


func _expect_false(value: bool, message: String) -> void:
	_expect_true(not value, message)

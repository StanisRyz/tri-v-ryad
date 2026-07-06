extends SceneTree

const GAME_SCREEN := preload("res://scenes/screens/GameScreen.tscn")

var _failures := 0


func _initialize() -> void:
	print("Running swap no double layer test...")
	_run()


func _run() -> void:
	var screen = GAME_SCREEN.instantiate()
	root.add_child(screen)
	await process_frame

	var swap := _find_valid_swap(screen._presenter.board)
	_expect_true(not swap.is_empty(), "game screen board has valid swap")
	if not swap.is_empty():
		screen._on_swap_requested(swap["from"], swap["to"])

		# Exactly one visual source of truth mid-swap: the real board is hidden
		# and only the overlay ghost layer is visible, so the pre-swap and
		# post-swap boards can never be seen stacked on top of each other.
		_expect_true(screen.board_view.is_animation_overlay_mode(), "board enters overlay mode for swap animation")
		_expect_false(screen.board_view.get_tile_view(swap["from"]).visible, "real from-tile is hidden during swap overlay")
		_expect_false(screen.board_view.get_tile_view(swap["to"]).visible, "real to-tile is hidden during swap overlay")
		_expect_true(screen.board_view.get_animation_layer().get_child_count() > 0, "overlay ghost layer is populated during swap")

		await create_timer(4.0).timeout

		_expect_false(screen.board_view.is_animation_overlay_mode(), "board exits overlay mode after full turn flow")
		_expect_equal(screen.board_view.get_animation_layer().get_child_count(), 0, "no leftover ghosts remain after turn flow")
		_expect_true(screen.board_view.get_tile_view(swap["from"]).visible, "real from-tile is restored after turn flow")
		_expect_true(screen.board_view.get_tile_view(swap["to"]).visible, "real to-tile is restored after turn flow")

	screen.queue_free()
	await process_frame
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
		print("Swap no double layer test passed.")
		quit(0)
	else:
		push_error("Swap no double layer test failed: %d" % _failures)
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

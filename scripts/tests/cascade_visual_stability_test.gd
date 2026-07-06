extends SceneTree

const BOARD_VIEW := preload("res://scenes/game/BoardView.tscn")

var _failures := 0


func _initialize() -> void:
	print("Running cascade visual stability test...")
	_run()


func _run() -> void:
	var board_view: BoardView = BOARD_VIEW.instantiate()
	board_view.size = Vector2(664, 664)
	root.add_child(board_view)
	await process_frame
	board_view.set_board(_create_board())
	await process_frame

	var snapshot := BoardVisualSnapshot.from_board_view(board_view)
	board_view.enter_animation_overlay_mode(snapshot)
	_expect_equal(board_view.get_animation_layer().get_child_count(), 81, "overlay starts with one ghost per cell")

	var matched_cells: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)]
	board_view.play_match_clear_animation(matched_cells, 0.05)
	await create_timer(0.15).timeout
	_expect_equal(board_view.get_animation_layer().get_child_count(), 78, "match clear fades matched ghosts without leaving stray nodes")

	# Stage 46: gravity fall now really relocates the overlay ghost from its
	# source cell to its target cell (no ghost is created or destroyed by the
	# move itself), so the ghost count must stay unchanged right after it.
	board_view.play_gravity_fall_animation([{"from": Vector2i(0, 1), "to": Vector2i(0, 0), "tile_type": TileType.RED, "special_data": null, "fall_distance": 1}], 0.05)
	_expect_equal(board_view.get_animation_layer().get_child_count(), 78, "gravity fall relocates a ghost without changing the overlay ghost count")

	# (0, 1) is now the vacated source cell of the tile that fell into (0, 0),
	# so it needs its own refill spawn alongside the two other matched cells.
	var refill_cells: Array = [
		{"spawn_index": 0, "to": Vector2i(0, 0), "tile_type": TileType.BLUE, "special_data": null},
		{"spawn_index": 0, "to": Vector2i(1, 0), "tile_type": TileType.GREEN, "special_data": null},
		{"spawn_index": 0, "to": Vector2i(2, 0), "tile_type": TileType.YELLOW, "special_data": null},
		{"spawn_index": 1, "to": Vector2i(0, 1), "tile_type": TileType.RED, "special_data": null},
	]
	board_view.play_refill_animation(refill_cells, 0.05)
	await create_timer(0.15).timeout
	_expect_equal(board_view.get_animation_layer().get_child_count(), 81, "refill repopulates cleared cells back to a full board with no empty-looking gaps")

	# No cell should ever end up with more than one ghost (which would look
	# stretched/merged) after clear + refill.
	for cell in matched_cells:
		_expect_true(board_view.get_overlay_ghost(cell) != null, "refilled cell has exactly one ghost restored: %s" % cell)

	board_view.exit_animation_overlay_mode()
	_expect_equal(board_view.get_animation_layer().get_child_count(), 0, "exiting overlay after cascade leaves no leftover ghosts")

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
		print("Cascade visual stability test passed.")
		quit(0)
	else:
		push_error("Cascade visual stability test failed: %d" % _failures)
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

extends SceneTree

const GAME_SCREEN := preload("res://scenes/screens/GameScreen.tscn")

var _failures := 0


func _initialize() -> void:
	print("Running battle effect cleanup test...")
	_run()


func _run() -> void:
	var screen = GAME_SCREEN.instantiate()
	root.add_child(screen)
	await process_frame

	# Simulate leftover ghosts/particles/overlay state from an interrupted turn.
	var snapshot := BoardVisualSnapshot.from_board_view(screen.board_view)
	screen.board_view.enter_animation_overlay_mode(snapshot)
	_expect_true(screen.board_view.is_animation_overlay_mode(), "board enters overlay mode before simulated interruption")

	var stray_particle := ColorRect.new()
	screen.battle_effect_layer.add_child(stray_particle)
	_expect_equal(screen.battle_effect_layer.get_child_count(), 1, "battle effect layer has a stray particle before cleanup")

	screen._pending_board_for_animation = screen._presenter.board
	screen._defer_board_update_for_turn = true

	# Restart clears ghosts and particles.
	screen._on_restart_pressed()
	await process_frame
	_expect_false(screen.board_view.is_animation_overlay_mode(), "restart exits board overlay mode")
	_expect_equal(screen.board_view.get_animation_layer().get_child_count(), 0, "restart clears leftover AnimationLayer ghosts")
	_expect_equal(screen.battle_effect_layer.get_child_count(), 0, "restart clears leftover battle effect particles")
	_expect_true(screen._pending_board_for_animation == null, "restart clears pending board state")
	_expect_false(screen._defer_board_update_for_turn, "restart clears deferred board update flag")

	# Menu/back clears ghosts and particles too.
	screen.board_view.enter_animation_overlay_mode(BoardVisualSnapshot.from_board_view(screen.board_view))
	var stray_particle_2 := ColorRect.new()
	screen.battle_effect_layer.add_child(stray_particle_2)
	screen._on_menu_button_pressed()
	await process_frame
	_expect_false(screen.board_view.is_animation_overlay_mode(), "menu press exits board overlay mode")
	_expect_equal(screen.battle_effect_layer.get_child_count(), 0, "menu press clears leftover battle effect particles")

	screen.queue_free()
	await process_frame
	await process_frame
	_finish()


func _finish() -> void:
	if _failures == 0:
		print("Battle effect cleanup test passed.")
		quit(0)
	else:
		push_error("Battle effect cleanup test failed: %d" % _failures)
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

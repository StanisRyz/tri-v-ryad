extends SceneTree

const GAME_SCREEN := preload("res://scenes/screens/GameScreen.tscn")

var _failures := 0


func _initialize() -> void:
	print("Running booster animation flow test...")
	_run()


func _run() -> void:
	var screen = GAME_SCREEN.instantiate()
	root.add_child(screen)
	await process_frame

	var booster_panel = screen.get_node("%BoosterPanel")
	screen._on_booster_pressed("hammer")
	await process_frame
	_expect_equal(screen._input_mode, "booster_targeting", "hammer enters targeting mode")

	screen._on_board_tile_pressed(Vector2i(4, 4))
	_expect_equal(screen._input_mode, "normal", "targeted booster exits targeting mode")
	_expect_false(screen._input_controller._input_enabled, "input locks during booster animation flow")
	await create_timer(2.2).timeout

	_expect_false(screen._feedback_active, "booster animation flow finishes")
	_expect_true(booster_panel.visible, "booster panel remains visible")
	_expect_equal(screen._presenter.state.get("booster_state").get_uses_left("hammer"), 0, "hammer booster is marked used")
	if not screen._presenter.is_battle_finished():
		_expect_true(screen._input_controller._input_enabled, "input unlocks after booster animation")

	screen.queue_free()
	await process_frame
	_finish()


func _finish() -> void:
	if _failures == 0:
		print("Booster animation flow test passed.")
		quit(0)
	else:
		push_error("Booster animation flow test failed: %d" % _failures)
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

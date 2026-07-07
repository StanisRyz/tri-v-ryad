extends SceneTree

const GAME_SCREEN := preload("res://scenes/screens/GameScreen.tscn")
const PROGRESS_MANAGER_SCRIPT := preload("res://scripts/game/progression/progress_manager.gd")
const SAVE_MANAGER_SCRIPT := preload("res://scripts/game/save/save_manager.gd")

const TEST_SAVE_PATH := "user://test_booster_animation_flow_save_v1.json"
const TEST_TEMP_SAVE_PATH := "user://test_booster_animation_flow_save_v1.tmp"

var _failures := 0


func _initialize() -> void:
	print("Running booster animation flow test...")
	_run()


func _run() -> void:
	_cleanup()
	var screen = GAME_SCREEN.instantiate()
	root.add_child(screen)
	await process_frame

	# Stage 62.2 v0.1: booster activation now needs a global inventory count.
	var progress_manager = _make_progress_manager()
	progress_manager.add_booster("hammer", 3)
	screen.set_progress_manager(progress_manager)
	await process_frame

	var booster_panel = screen.get_node("%BoosterPanel")
	screen._on_booster_pressed("hammer")
	await process_frame
	_expect_equal(screen._input_mode, "booster_targeting", "hammer enters targeting mode")

	screen._on_board_tile_pressed(Vector2i(4, 4))
	_expect_equal(screen._input_mode, "normal", "targeted booster exits targeting mode")
	_expect_false(screen._input_controller._input_enabled, "input locks during booster animation flow")
	await _wait_for_feedback_to_finish(screen, 8.0)

	_expect_false(screen._feedback_active, "booster animation flow finishes")
	_expect_true(booster_panel.visible, "booster panel remains visible")
	_expect_equal(screen._presenter.state.get("booster_state").get_uses_left("hammer"), 0, "hammer booster is marked used")
	_expect_false(screen.board_view.is_animation_overlay_mode(), "booster flow exits overlay mode")
	_expect_equal(screen.board_view.get_animation_layer().get_child_count(), 0, "booster flow leaves no overlay ghosts")
	_expect_equal(screen.board_view._highlighted_cells.size(), 0, "booster flow leaves no match highlights")
	_expect_equal(screen.board_view._invalid_feedback_cells.size(), 0, "booster flow leaves no invalid highlights")
	if not screen._presenter.is_battle_finished():
		_expect_true(screen._input_controller._input_enabled, "input unlocks after booster animation")

	_expect_equal(progress_manager.get_booster_count("hammer"), 2, "successful hammer use spends 1 global booster")

	screen.queue_free()
	await process_frame
	_cleanup()
	_finish()


func _wait_for_feedback_to_finish(screen, timeout_seconds: float) -> void:
	var elapsed := 0.0
	while screen._feedback_active and elapsed < timeout_seconds:
		await create_timer(0.1).timeout
		elapsed += 0.1


func _make_progress_manager():
	var save_manager = SAVE_MANAGER_SCRIPT.new(TEST_SAVE_PATH, TEST_TEMP_SAVE_PATH)
	var progress_manager = PROGRESS_MANAGER_SCRIPT.new(save_manager)
	progress_manager.load()
	return progress_manager


func _cleanup() -> void:
	if FileAccess.file_exists(TEST_SAVE_PATH):
		DirAccess.remove_absolute(TEST_SAVE_PATH)
	if FileAccess.file_exists(TEST_TEMP_SAVE_PATH):
		DirAccess.remove_absolute(TEST_TEMP_SAVE_PATH)


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

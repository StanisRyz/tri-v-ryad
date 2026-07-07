extends SceneTree

const GAME_SCREEN := preload("res://scenes/screens/GameScreen.tscn")
const PROGRESS_MANAGER_SCRIPT := preload("res://scripts/game/progression/progress_manager.gd")
const SAVE_MANAGER_SCRIPT := preload("res://scripts/game/save/save_manager.gd")

const TEST_SAVE_PATH := "user://test_booster_damage_effect_flow_save_v1.json"
const TEST_TEMP_SAVE_PATH := "user://test_booster_damage_effect_flow_save_v1.tmp"

var _failures := 0


func _initialize() -> void:
	print("Running booster damage effect flow test...")
	_cleanup()
	_run()


func _run() -> void:
	await _test_hammer_triggers_damage_particles()
	await _test_time_freeze_triggers_no_particles()
	_cleanup()
	_finish()


func _test_hammer_triggers_damage_particles() -> void:
	var screen = GAME_SCREEN.instantiate()
	root.add_child(screen)
	await process_frame

	# Stage 62.2 v0.1: booster activation now needs a global inventory count.
	var progress_manager = _make_progress_manager()
	progress_manager.add_booster("hammer", 3)
	screen.set_progress_manager(progress_manager)
	await process_frame

	var starting_hp: int = screen._presenter.state.enemy.current_hp
	screen._on_booster_pressed("hammer")
	await process_frame
	_expect_equal(screen._input_mode, "booster_targeting", "hammer enters targeting mode")

	screen._on_board_tile_pressed(Vector2i(4, 4))
	await process_frame
	_expect_true(screen._feedback_active, "booster resolution locks feedback state while pending")

	await create_timer(3.0).timeout
	_expect_true(screen._presenter.state.enemy.current_hp < starting_hp, "hammer booster deals damage to the enemy")
	_expect_false(screen._feedback_active, "booster damage particle flow finishes")
	_expect_equal(screen.battle_effect_layer.get_child_count(), 0, "battle effect layer is cleared after booster damage particles finish")

	screen.queue_free()
	await process_frame


func _test_time_freeze_triggers_no_particles() -> void:
	var screen = GAME_SCREEN.instantiate()
	root.add_child(screen)
	await process_frame

	# Stage 62.2 v0.1: booster activation now needs a global inventory count.
	var progress_manager = _make_progress_manager()
	progress_manager.add_booster("freeze_time", 3)
	screen.set_progress_manager(progress_manager)
	await process_frame

	var starting_hp: int = screen._presenter.state.enemy.current_hp
	screen._on_booster_pressed("freeze_time")
	await process_frame
	await create_timer(1.0).timeout

	_expect_equal(screen._presenter.state.enemy.current_hp, starting_hp, "time freeze does not damage the enemy")
	_expect_equal(screen.battle_effect_layer.get_child_count(), 0, "time freeze spawns no damage particles")
	_expect_false(screen._feedback_active, "time freeze flow finishes cleanly")

	screen.queue_free()
	await process_frame


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
		print("Booster damage effect flow test passed.")
		quit(0)
	else:
		push_error("Booster damage effect flow test failed: %d" % _failures)
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

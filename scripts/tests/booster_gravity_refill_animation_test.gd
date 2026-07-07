extends SceneTree

const BOOSTER_CATALOG_SCRIPT := preload("res://scripts/game/config/booster_catalog.gd")
const BOOSTER_RESOLVER_SCRIPT := preload("res://scripts/game/battle/booster_resolver.gd")
const BUILDER_SCRIPT := preload("res://scripts/game/presentation/board_animation_sequence_builder.gd")
const REQUEST_SCRIPT := preload("res://scripts/game/presentation/board_animation_request.gd")
const GAME_SCREEN := preload("res://scenes/screens/GameScreen.tscn")
const PROGRESS_MANAGER_SCRIPT := preload("res://scripts/game/progression/progress_manager.gd")
const SAVE_MANAGER_SCRIPT := preload("res://scripts/game/save/save_manager.gd")

const TEST_SAVE_PATH := "user://test_booster_gravity_refill_save_v1.json"
const TEST_TEMP_SAVE_PATH := "user://test_booster_gravity_refill_save_v1.tmp"

var _failures := 0


func _initialize() -> void:
	print("Running booster gravity/refill animation test...")
	_cleanup()
	_run()


func _run() -> void:
	_test_hammer_produces_gravity_and_refill_data()
	await _test_game_screen_defers_board_during_booster_animation()
	_finish()


func _test_hammer_produces_gravity_and_refill_data() -> void:
	var resolver = BOOSTER_RESOLVER_SCRIPT.new()
	var board := BoardModel.new()
	for y in range(BoardModel.DEFAULT_HEIGHT):
		for x in range(BoardModel.DEFAULT_WIDTH):
			board.set_tile(Vector2i(x, y), (x + y) % 5)

	var battle_state := BattleState.new([], EnemyConfig.training_dummy().to_enemy_data(), EnemyConfig.training_dummy().to_enemy_intent(), 10)
	battle_state.board = board
	battle_state.get("booster_state").setup_from_catalog(BOOSTER_CATALOG_SCRIPT.new())

	var result = resolver.resolve_targeted_booster(battle_state, "hammer", Vector2i(4, 4), null)
	_expect_true(result.is_valid, "hammer resolves against a mid-board target")
	_expect_true(not result.fall_movements.is_empty(), "hammer result exposes fall_movements")
	_expect_true(not result.refill_cells.is_empty(), "hammer result exposes refill_cells")

	var builder = BUILDER_SCRIPT.new()
	var sequence = builder.build_from_booster_result(result)
	var types: Array[String] = []
	for request in sequence.get_requests():
		types.append(request.animation_type)

	_expect_true(types.has(REQUEST_SCRIPT.TYPE_BOOSTER_CLEAR), "booster sequence includes booster_clear")
	_expect_true(types.has(REQUEST_SCRIPT.TYPE_GRAVITY_FALL), "booster sequence includes gravity_fall")
	_expect_true(types.has(REQUEST_SCRIPT.TYPE_REFILL), "booster sequence includes refill")
	_expect_true(types.find(REQUEST_SCRIPT.TYPE_BOOSTER_CLEAR) < types.find(REQUEST_SCRIPT.TYPE_GRAVITY_FALL), "booster_clear plays before gravity_fall")
	_expect_true(types.find(REQUEST_SCRIPT.TYPE_GRAVITY_FALL) < types.find(REQUEST_SCRIPT.TYPE_REFILL), "gravity_fall plays before refill")


func _test_game_screen_defers_board_during_booster_animation() -> void:
	var screen = GAME_SCREEN.instantiate()
	root.add_child(screen)
	await process_frame

	# Stage 62.2 v0.1: booster activation now needs a global inventory count.
	var progress_manager = _make_progress_manager()
	progress_manager.add_booster("hammer", 3)
	screen.set_progress_manager(progress_manager)
	await process_frame

	screen._on_booster_pressed("hammer")
	await process_frame
	_expect_equal(screen._input_mode, "booster_targeting", "hammer enters targeting mode")

	screen._on_board_tile_pressed(Vector2i(4, 4))
	_expect_true(screen._pending_board_for_animation == null, "board is not resolved yet while the stepwise booster flow is still running")
	_expect_false(screen._input_controller._input_enabled, "input stays locked during booster gravity/refill animation")

	await create_timer(2.2).timeout
	_expect_true(screen._pending_board_for_animation == null, "pending board applies once booster animation finishes")
	if not screen._presenter.is_battle_finished():
		_expect_true(screen._input_controller._input_enabled, "input unlocks after booster animation flow")

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
	_cleanup()
	if _failures == 0:
		print("Booster gravity/refill animation test passed.")
		quit(0)
	else:
		push_error("Booster gravity/refill animation test failed: %d" % _failures)
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

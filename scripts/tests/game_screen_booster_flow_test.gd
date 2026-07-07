extends SceneTree

const GAME_SCREEN := preload("res://scenes/screens/GameScreen.tscn")
const PROGRESS_MANAGER_SCRIPT := preload("res://scripts/game/progression/progress_manager.gd")
const SAVE_MANAGER_SCRIPT := preload("res://scripts/game/save/save_manager.gd")

const TEST_SAVE_PATH := "user://test_game_screen_booster_flow_save_v1.json"
const TEST_TEMP_SAVE_PATH := "user://test_game_screen_booster_flow_save_v1.tmp"

var _failures := 0


func _initialize() -> void:
	print("Running game screen booster flow test...")
	_run()


func _run() -> void:
	_cleanup()
	var screen := GAME_SCREEN.instantiate()
	root.add_child(screen)
	await process_frame

	# Stage 62.2 v0.1: booster activation is now gated on the global
	# cross-battle inventory (ProgressManager.has_booster()), so this test
	# needs a ProgressManager with real booster counts wired in before any
	# booster press can succeed - a screen with no ProgressManager at all is
	# covered separately by the "fails safely" case below.
	var progress_manager = _make_progress_manager()
	progress_manager.add_booster("hammer", 3)
	progress_manager.add_booster("freeze_time", 3)
	progress_manager.add_booster("rocket_barrage", 3)
	screen.set_progress_manager(progress_manager)
	await process_frame

	var booster_panel = screen.get_node("%BoosterPanel")
	var hero_party_panel: Control = screen.get_node("%HeroPartyPanel")
	_expect_true(booster_panel != null, "game screen has BoosterPanel")
	_expect_true(booster_panel.visible, "booster panel is visible in direct mode")
	_expect_equal(booster_panel.get_button_count(), 3, "game screen booster panel has 3 buttons")
	_expect_true(not hero_party_panel.visible, "hero party panel remains hidden")

	var starting_moves: int = screen._presenter.state.moves_left
	screen._on_booster_pressed("freeze_time")
	await process_frame
	_expect_equal(screen._presenter.state.moves_left, starting_moves, "freeze button does not consume moves")
	_expect_equal(screen._presenter.state.get("booster_state").freeze_turns_left, 3, "freeze button adds turns")
	_expect_equal(progress_manager.get_booster_count("freeze_time"), 2, "successful time freeze spends 1 global freeze_time")

	screen._on_booster_pressed("hammer")
	await process_frame
	_expect_equal(screen._input_mode, "booster_targeting", "hammer enters targeting mode")
	screen.board_view.set_selected_cell(Vector2i(4, 4))
	var highlight_cells: Array[Vector2i] = [Vector2i(4, 4)]
	screen.board_view.highlight_cells(highlight_cells)
	screen._on_booster_pressed("hammer")
	await process_frame
	_expect_equal(screen._input_mode, "normal", "repeated hammer press cancels targeting")
	_expect_equal(screen.board_view._selected_cell, Vector2i(-1, -1), "cancelled booster targeting clears selected cell")
	_expect_equal(screen.board_view._highlighted_cells.size(), 0, "cancelled booster targeting clears target highlights")
	_expect_equal(progress_manager.get_booster_count("hammer"), 3, "cancelling hammer targeting does not spend a global booster")

	screen.queue_free()
	await _test_missing_progress_manager_blocks_boosters()
	_cleanup()
	_finish()


## Stage 62.2 v0.1: with no ProgressManager attached, every global booster
## count must read as 0 and every booster press must fail safely (no crash,
## no activation) rather than assume unlimited/legacy per-battle-only uses.
func _test_missing_progress_manager_blocks_boosters() -> void:
	var screen := GAME_SCREEN.instantiate()
	root.add_child(screen)
	await process_frame

	var starting_freeze_turns: int = screen._presenter.state.get("booster_state").freeze_turns_left
	screen._on_booster_pressed("freeze_time")
	await process_frame
	_expect_equal(screen._presenter.state.get("booster_state").freeze_turns_left, starting_freeze_turns, "freeze button is blocked without a ProgressManager")
	_expect_equal(screen._input_mode, "normal", "booster press without a ProgressManager never enters targeting mode")

	screen.queue_free()


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
		print("Game screen booster flow test passed.")
		quit(0)
	else:
		push_error("Game screen booster flow test failed: %d" % _failures)
		quit(1)


func _expect_true(value: bool, message: String) -> void:
	if value:
		return
	_failures += 1
	push_error("FAILED: %s" % message)


func _expect_equal(actual, expected, message: String) -> void:
	if actual == expected:
		return
	_failures += 1
	push_error("FAILED: %s | expected=%s actual=%s" % [message, expected, actual])

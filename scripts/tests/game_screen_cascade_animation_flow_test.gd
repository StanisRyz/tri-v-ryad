extends SceneTree

const GAME_SCREEN := preload("res://scenes/screens/GameScreen.tscn")
const TURN_PRESENTATION_DATA_SCRIPT := preload("res://scripts/game/presentation/turn_presentation_data.gd")

var _failures := 0


func _initialize() -> void:
	print("Running game screen cascade animation flow test...")
	_run()


func _run() -> void:
	var screen = GAME_SCREEN.instantiate()
	root.add_child(screen)
	await process_frame

	var matches: Array[MatchResult] = [MatchResult.new([Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)], TileType.RED)]
	var battle_result := BattleTurnResult.new()
	battle_result.total_damage_to_enemy = 3
	battle_result.total_tiles_cleared = 3
	var data = TURN_PRESENTATION_DATA_SCRIPT.from_valid_turn(Vector2i(0, 0), Vector2i(1, 0), matches, battle_result)
	var fall_movements: Array[Dictionary] = [{"from": Vector2i(0, 0), "to": Vector2i(0, 1), "tile_type": TileType.RED, "special_data": null, "fall_distance": 1}]
	var refill_cells: Array[Dictionary] = [{"spawn_index": 0, "to": Vector2i(0, 0), "tile_type": TileType.BLUE, "special_data": null}]
	var cascade_steps: Array[Dictionary] = [
		{
			"cascade_index": 1,
			"matched_cells": [Vector2i(3, 3), Vector2i(4, 3), Vector2i(5, 3)],
			"special_cleared_cells": [],
			"fall_movements": [{"from": Vector2i(3, 2), "to": Vector2i(3, 3), "tile_type": TileType.GREEN, "special_data": null, "fall_distance": 1}],
			"refill_cells": [{"spawn_index": 0, "to": Vector2i(3, 0), "tile_type": TileType.YELLOW, "special_data": null}],
			"damage": 2,
		},
	]
	data.fall_movements = fall_movements
	data.refill_cells = refill_cells
	data.cascade_steps = cascade_steps

	_input_lock_active(screen)
	screen._on_turn_presentation_ready(data)
	_expect_true(not screen._input_controller._input_enabled, "input stays locked while cascade animation flow plays")

	await create_timer(5.0).timeout

	_expect_false(screen._feedback_active, "cascade animation and feedback flow finishes")
	if not screen._presenter.is_battle_finished():
		_expect_true(screen._input_controller._input_enabled, "input unlocks after cascade animation flow completes")

	screen.queue_free()
	await process_frame
	_finish()


func _input_lock_active(screen) -> void:
	screen._input_controller.set_input_enabled(false)


func _finish() -> void:
	if _failures == 0:
		print("Game screen cascade animation flow test passed.")
		quit(0)
	else:
		push_error("Game screen cascade animation flow test failed: %d" % _failures)
		quit(1)


func _expect_true(value: bool, message: String) -> void:
	if value:
		return
	_failures += 1
	push_error("FAILED: %s" % message)


func _expect_false(value: bool, message: String) -> void:
	_expect_true(not value, message)

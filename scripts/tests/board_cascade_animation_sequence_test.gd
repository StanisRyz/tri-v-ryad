extends SceneTree

const BOARD_RESOLVE_RESULT_SCRIPT := preload("res://scripts/game/board/board_resolve_result.gd")
const BUILDER_SCRIPT := preload("res://scripts/game/presentation/board_animation_sequence_builder.gd")
const REQUEST_SCRIPT := preload("res://scripts/game/presentation/board_animation_request.gd")
const TURN_PRESENTATION_DATA_SCRIPT := preload("res://scripts/game/presentation/turn_presentation_data.gd")

var _failures := 0


func _initialize() -> void:
	print("Running board cascade animation sequence test...")

	_test_cascade_steps_preserve_order()
	_test_sequence_builder_orders_cascade_requests()

	_finish()


func _test_cascade_steps_preserve_order() -> void:
	var result = BOARD_RESOLVE_RESULT_SCRIPT.new()
	var matches: Array[MatchResult] = [MatchResult.new([Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)], TileType.RED)]

	for step_index in range(3):
		var cleared: Array[Vector2i] = [Vector2i(step_index, 0)]
		var gravity_result := {
			"spawned_cells": [Vector2i(step_index, 0)],
			"fall_movements": [{"from": Vector2i(step_index, 0), "to": Vector2i(step_index, 1), "tile_type": TileType.RED, "special_data": null, "fall_distance": 1}],
			"refill_cells": [{"spawn_index": 0, "to": Vector2i(step_index, 0), "tile_type": TileType.BLUE, "special_data": null}],
		}
		result.add_step(matches, cleared, gravity_result)

	_expect_equal(result.cascade_steps.size(), 3, "three resolve steps produce three cascade steps")
	for index in range(3):
		_expect_equal(result.cascade_steps[index].get("cascade_index"), index, "cascade_index matches resolve order")
	_expect_equal(result.fall_movements.size(), 3, "aggregated fall_movements collects every step")
	_expect_equal(result.refill_cells.size(), 3, "aggregated refill_cells collects every step")


func _test_sequence_builder_orders_cascade_requests() -> void:
	var builder = BUILDER_SCRIPT.new()
	var matches: Array[MatchResult] = [MatchResult.new([Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)], TileType.RED)]
	var battle_result := BattleTurnResult.new()
	var data = TURN_PRESENTATION_DATA_SCRIPT.from_valid_turn(Vector2i(0, 0), Vector2i(1, 0), matches, battle_result)
	var fall_movements: Array[Dictionary] = [{"from": Vector2i(0, 0), "to": Vector2i(0, 1), "tile_type": TileType.RED, "special_data": null, "fall_distance": 1}]
	var refill_cells: Array[Dictionary] = [{"spawn_index": 0, "to": Vector2i(0, 0), "tile_type": TileType.BLUE, "special_data": null}]
	var cascade_steps: Array[Dictionary] = [
		{"cascade_index": 1, "matched_cells": [Vector2i(3, 3)], "special_cleared_cells": [], "fall_movements": [], "refill_cells": [], "damage": 0},
		{"cascade_index": 2, "matched_cells": [Vector2i(4, 4)], "special_cleared_cells": [], "fall_movements": [], "refill_cells": [], "damage": 0},
	]
	data.fall_movements = fall_movements
	data.refill_cells = refill_cells
	data.cascade_steps = cascade_steps

	var sequence = builder.build_from_turn_presentation(data)
	var cascade_indices: Array[int] = []
	for request in sequence.get_requests():
		if request.animation_type == REQUEST_SCRIPT.TYPE_CASCADE_STEP:
			cascade_indices.append(int(request.payload.get("cascade_index", -1)))

	_expect_equal(cascade_indices, [1, 2], "cascade_step requests appear in cascade order")


func _finish() -> void:
	if _failures == 0:
		print("Board cascade animation sequence test passed.")
		quit(0)
	else:
		push_error("Board cascade animation sequence test failed: %d" % _failures)
		quit(1)


func _expect_equal(actual, expected, message: String) -> void:
	if actual == expected:
		return
	_failures += 1
	push_error("FAILED: %s | expected=%s actual=%s" % [message, expected, actual])

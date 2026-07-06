extends SceneTree

const REQUEST_SCRIPT := "res://scripts/game/presentation/board_animation_request.gd"
const BUILDER_SCRIPT := "res://scripts/game/presentation/board_animation_sequence_builder.gd"
const TURN_PRESENTATION_DATA_SCRIPT := "res://scripts/game/presentation/turn_presentation_data.gd"

var _failures := 0


func _initialize() -> void:
	print("Running board animation sequence builder tests...")

	var builder = load(BUILDER_SCRIPT).new()
	var turn_sequence = builder.build_from_turn_presentation(_create_valid_turn_data())
	_expect_true(turn_sequence.size() >= 2, "valid turn builds multiple requests")
	_expect_equal(turn_sequence.get_requests()[0].animation_type, load(REQUEST_SCRIPT).TYPE_SWAP, "valid turn starts with swap")
	_expect_equal(turn_sequence.get_requests()[0].duration, 0.4, "valid swap duration is exactly 0.4 seconds")
	_expect_equal(turn_sequence.get_requests()[1].animation_type, load(REQUEST_SCRIPT).TYPE_MATCH_CLEAR, "valid turn includes match clear")
	_expect_equal(turn_sequence.get_requests()[1].payload["cells_count"], 3, "match clear payload stores cell count")

	var invalid_sequence = builder.build_invalid_swap(Vector2i(1, 1), Vector2i(2, 1), "no_match")
	_expect_equal(invalid_sequence.size(), 1, "invalid swap builds one request")
	_expect_equal(invalid_sequence.get_requests()[0].animation_type, load(REQUEST_SCRIPT).TYPE_INVALID_SWAP, "invalid swap request type")

	var booster_result := BoosterResolveResult.new()
	booster_result.is_valid = true
	booster_result.booster_id = "hammer"
	booster_result.cleared_cells = [Vector2i(4, 4), Vector2i(4, 5)]
	var booster_sequence = builder.build_from_booster_result(booster_result)
	_expect_equal(booster_sequence.size(), 1, "booster clear builds one request")
	_expect_equal(booster_sequence.get_requests()[0].animation_type, load(REQUEST_SCRIPT).TYPE_BOOSTER_CLEAR, "booster clear request type")

	_expect_true(builder.build_from_turn_presentation(null).is_empty(), "null turn data returns empty sequence")
	_expect_true(builder.build_from_booster_result(null).is_empty(), "null booster result returns empty sequence")

	_test_gravity_refill_and_cascade_requests(builder)
	_test_booster_gravity_and_refill_requests(builder)

	_finish()


func _test_gravity_refill_and_cascade_requests(builder) -> void:
	var data = _create_valid_turn_data()
	var fall_movements: Array[Dictionary] = [{"from": Vector2i(0, 0), "to": Vector2i(0, 1), "tile_type": TileType.RED, "special_data": null, "fall_distance": 1}]
	var refill_cells: Array[Dictionary] = [{"spawn_index": 0, "to": Vector2i(0, 0), "tile_type": TileType.BLUE, "special_data": null}]
	var cascade_steps: Array[Dictionary] = [{
		"cascade_index": 1,
		"matched_cells": [Vector2i(2, 2), Vector2i(3, 2), Vector2i(4, 2)],
		"special_cleared_cells": [],
		"fall_movements": [{"from": Vector2i(2, 1), "to": Vector2i(2, 2), "tile_type": TileType.GREEN, "special_data": null, "fall_distance": 1}],
		"refill_cells": [{"spawn_index": 0, "to": Vector2i(2, 0), "tile_type": TileType.YELLOW, "special_data": null}],
		"damage": 2,
	}]
	data.fall_movements = fall_movements
	data.refill_cells = refill_cells
	data.cascade_steps = cascade_steps

	var sequence = builder.build_from_turn_presentation(data)
	var types: Array[String] = []
	for request in sequence.get_requests():
		types.append(request.animation_type)

	var request_script = load(REQUEST_SCRIPT)
	_expect_true(types.has(request_script.TYPE_GRAVITY_FALL), "sequence includes gravity_fall request")
	_expect_true(types.has(request_script.TYPE_REFILL), "sequence includes refill request")
	_expect_true(types.has(request_script.TYPE_CASCADE_STEP), "sequence includes cascade_step request")

	var gravity_index := types.find(request_script.TYPE_GRAVITY_FALL)
	var refill_index := types.find(request_script.TYPE_REFILL)
	var cascade_index := types.find(request_script.TYPE_CASCADE_STEP)
	_expect_true(gravity_index < refill_index, "gravity_fall is added before refill")
	_expect_true(refill_index < cascade_index, "refill is added before cascade_step")
	_expect_true(types.count(request_script.TYPE_GRAVITY_FALL) >= 2, "cascade step contributes its own gravity_fall request")
	_expect_true(types.count(request_script.TYPE_REFILL) >= 2, "cascade step contributes its own refill request")


func _test_booster_gravity_and_refill_requests(builder) -> void:
	var booster_result := BoosterResolveResult.new()
	booster_result.is_valid = true
	booster_result.booster_id = "hammer"
	booster_result.cleared_cells = [Vector2i(4, 4)]
	booster_result.fall_movements = [{"from": Vector2i(4, 3), "to": Vector2i(4, 4), "tile_type": TileType.RED, "special_data": null, "fall_distance": 1}]
	booster_result.refill_cells = [{"spawn_index": 0, "to": Vector2i(4, 0), "tile_type": TileType.BLUE, "special_data": null}]

	var sequence = builder.build_from_booster_result(booster_result)
	var request_script = load(REQUEST_SCRIPT)
	var types: Array[String] = []
	for request in sequence.get_requests():
		types.append(request.animation_type)

	_expect_true(types.has(request_script.TYPE_GRAVITY_FALL), "booster sequence includes gravity_fall when data exists")
	_expect_true(types.has(request_script.TYPE_REFILL), "booster sequence includes refill when data exists")


func _create_valid_turn_data():
	var matches: Array[MatchResult] = [
		MatchResult.new([Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)], TileType.RED),
	]
	var result := BattleTurnResult.new()
	result.total_damage_to_enemy = 3
	result.total_tiles_cleared = 3
	return load(TURN_PRESENTATION_DATA_SCRIPT).from_valid_turn(Vector2i(0, 0), Vector2i(1, 0), matches, result)


func _finish() -> void:
	if _failures == 0:
		print("Board animation sequence builder tests passed.")
		quit(0)
	else:
		push_error("Board animation sequence builder tests failed: %d" % _failures)
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

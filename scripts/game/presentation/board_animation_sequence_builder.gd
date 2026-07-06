extends RefCounted
class_name BoardAnimationSequenceBuilder

const REQUEST_SCRIPT := preload("res://scripts/game/presentation/board_animation_request.gd")
const SEQUENCE_SCRIPT := preload("res://scripts/game/presentation/board_animation_sequence.gd")

const SWAP_ANIMATION_DURATION := 0.4
const GRAVITY_ANIMATION_DURATION := 0.35
const REFILL_ANIMATION_DURATION := 0.30
const CASCADE_STEP_DURATION := 0.20
const INVALID_SWAP_ANIMATION_DURATION := 0.24
const SPECIAL_CREATE_ANIMATION_DURATION := 0.22


func build_from_turn_presentation(data):
	var sequence := SEQUENCE_SCRIPT.new()
	if data == null:
		return sequence

	if not data.is_valid:
		return build_invalid_swap(data.swapped_from, data.swapped_to, data.invalid_reason)

	sequence.add_request(REQUEST_SCRIPT.new_request(REQUEST_SCRIPT.TYPE_SWAP)
		.with_swap(data.swapped_from, data.swapped_to)
		.with_duration(SWAP_ANIMATION_DURATION)
		.with_payload({"source": "turn"}))

	if not data.matched_cells.is_empty():
		sequence.add_request(REQUEST_SCRIPT.new_request(REQUEST_SCRIPT.TYPE_MATCH_CLEAR)
			.with_cells(data.matched_cells)
			.with_duration(0.16)
			.with_payload({
				"source": "turn",
				"total_tiles_cleared": data.total_tiles_cleared,
				"cells_count": data.matched_cells.size(),
			}))

	if not data.special_cleared_cells.is_empty():
		sequence.add_request(REQUEST_SCRIPT.new_request(REQUEST_SCRIPT.TYPE_SPECIAL_CLEAR)
			.with_cells(data.special_cleared_cells)
			.with_duration(0.18)
			.with_payload({
				"source": "turn",
				"activated_special_tiles": data.activated_special_tiles.duplicate(true),
				"cells_count": data.special_cleared_cells.size(),
			}))

	_add_gravity_and_refill_requests(sequence, data.fall_movements, data.refill_cells)

	for cascade_step in data.cascade_steps:
		_add_cascade_step_requests(sequence, cascade_step)

	if data.total_damage_to_enemy > 0:
		sequence.add_request(REQUEST_SCRIPT.new_request(REQUEST_SCRIPT.TYPE_ENEMY_HIT)
			.with_duration(0.04)
			.with_payload({"damage": data.total_damage_to_enemy}))

	return sequence


func build_from_booster_result(result):
	var sequence := SEQUENCE_SCRIPT.new()
	if result == null:
		return sequence
	if not result.is_valid:
		return sequence
	if result.cleared_cells.is_empty():
		return sequence

	sequence.add_request(REQUEST_SCRIPT.new_request(REQUEST_SCRIPT.TYPE_BOOSTER_CLEAR)
		.with_cells(result.cleared_cells)
		.with_duration(0.08)
		.with_payload({
			"booster_id": result.booster_id,
			"damage_to_enemy": result.damage_to_enemy,
			"affected_tile_types": result.affected_tile_types.duplicate(),
		}))

	_add_gravity_and_refill_requests(sequence, result.fall_movements, result.refill_cells)

	for cascade_step in result.cascade_steps:
		_add_cascade_step_requests(sequence, cascade_step)

	return sequence


func build_swap_sequence(from_cell: Vector2i, to_cell: Vector2i):
	var sequence := SEQUENCE_SCRIPT.new()
	sequence.add_request(REQUEST_SCRIPT.new_request(REQUEST_SCRIPT.TYPE_SWAP)
		.with_swap(from_cell, to_cell)
		.with_duration(SWAP_ANIMATION_DURATION)
		.with_payload({"source": "turn"}))
	return sequence


func build_clear_sequence(step):
	var sequence := SEQUENCE_SCRIPT.new()
	if step == null:
		return sequence

	var source := "cascade" if step.cascade_index > 0 else "turn"

	# step.matched_cells includes any cell protected from clearing because it
	# is about to become a special tile (see StepwiseBoardResolver.build_clear_step).
	# The visual clear must only target step.cleared_cells, or the creation
	# cell would fade out even though it should transform into a special tile.
	if not step.cleared_cells.is_empty():
		sequence.add_request(REQUEST_SCRIPT.new_request(REQUEST_SCRIPT.TYPE_MATCH_CLEAR)
			.with_cells(step.cleared_cells)
			.with_duration(0.16)
			.with_payload({
				"source": source,
				"cascade_index": step.cascade_index,
				"cells_count": step.cleared_cells.size(),
			}))

	if not step.created_special_tiles.is_empty():
		sequence.add_request(REQUEST_SCRIPT.new_request(REQUEST_SCRIPT.TYPE_SPECIAL_CREATE)
			.with_cells(_special_creation_cells(step.created_special_tiles))
			.with_duration(SPECIAL_CREATE_ANIMATION_DURATION)
			.with_payload({
				"source": source,
				"cascade_index": step.cascade_index,
				"created_special_tiles": step.created_special_tiles.duplicate(true),
			}))

	if not step.special_cleared_cells.is_empty():
		sequence.add_request(REQUEST_SCRIPT.new_request(REQUEST_SCRIPT.TYPE_SPECIAL_CLEAR)
			.with_cells(step.special_cleared_cells)
			.with_duration(0.18)
			.with_payload({
				"source": source,
				"activated_special_tiles": step.activated_special_tiles.duplicate(true),
				"cells_count": step.special_cleared_cells.size(),
			}))

	return sequence


func build_gravity_refill_sequence(step):
	var sequence := SEQUENCE_SCRIPT.new()
	if step == null:
		return sequence

	_add_gravity_and_refill_requests(sequence, step.fall_movements, step.refill_cells)
	return sequence


func build_booster_clear_sequence(cleared_cells: Array[Vector2i], booster_id: String, damage_to_enemy: int, affected_tile_types: Array):
	var sequence := SEQUENCE_SCRIPT.new()
	if cleared_cells.is_empty():
		return sequence

	sequence.add_request(REQUEST_SCRIPT.new_request(REQUEST_SCRIPT.TYPE_BOOSTER_CLEAR)
		.with_cells(cleared_cells)
		.with_duration(0.08)
		.with_payload({
			"booster_id": booster_id,
			"damage_to_enemy": damage_to_enemy,
			"affected_tile_types": affected_tile_types.duplicate(),
		}))
	return sequence


func build_invalid_swap(from_cell: Vector2i, to_cell: Vector2i, reason: String = ""):
	var sequence := SEQUENCE_SCRIPT.new()
	sequence.add_request(REQUEST_SCRIPT.new_request(REQUEST_SCRIPT.TYPE_INVALID_SWAP)
		.with_swap(from_cell, to_cell)
		.with_duration(INVALID_SWAP_ANIMATION_DURATION)
		.with_payload({"reason": reason}))
	return sequence


func _add_gravity_and_refill_requests(sequence, fall_movements: Array, refill_cells: Array) -> void:
	if not fall_movements.is_empty():
		sequence.add_request(REQUEST_SCRIPT.new_request(REQUEST_SCRIPT.TYPE_GRAVITY_FALL)
			.with_duration(GRAVITY_ANIMATION_DURATION)
			.with_payload({"movements": (fall_movements as Array).duplicate(true)}))

	if not refill_cells.is_empty():
		sequence.add_request(REQUEST_SCRIPT.new_request(REQUEST_SCRIPT.TYPE_REFILL)
			.with_duration(REFILL_ANIMATION_DURATION)
			.with_payload({"refill_cells": (refill_cells as Array).duplicate(true)}))


func _add_cascade_step_requests(sequence, cascade_step: Dictionary) -> void:
	var matched_cells := _to_vector2i_array(cascade_step.get("matched_cells", []))
	sequence.add_request(REQUEST_SCRIPT.new_request(REQUEST_SCRIPT.TYPE_CASCADE_STEP)
		.with_cells(matched_cells)
		.with_duration(CASCADE_STEP_DURATION)
		.with_payload({
			"cascade_index": cascade_step.get("cascade_index", 0),
			"matched_cells": matched_cells,
			"damage": cascade_step.get("damage", 0),
		}))

	_add_gravity_and_refill_requests(sequence, cascade_step.get("fall_movements", []), cascade_step.get("refill_cells", []))


func _to_vector2i_array(values: Array) -> Array[Vector2i]:
	var typed_values: Array[Vector2i] = []
	for value in values:
		typed_values.append(value as Vector2i)
	return typed_values


func _special_creation_cells(created_special_tiles: Array) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for item in created_special_tiles:
		var cell = (item as Dictionary).get("cell", Vector2i(-1, -1))
		if cell is Vector2i:
			cells.append(cell)
	return cells

extends RefCounted
class_name BoardAnimationSequenceBuilder

const REQUEST_SCRIPT := preload("res://scripts/game/presentation/board_animation_request.gd")
const SEQUENCE_SCRIPT := preload("res://scripts/game/presentation/board_animation_sequence.gd")

const SWAP_ANIMATION_DURATION := 0.4
const GRAVITY_ANIMATION_DURATION := 0.35
const REFILL_ANIMATION_DURATION := 0.30
const CASCADE_STEP_DURATION := 0.20
const INVALID_SWAP_ANIMATION_DURATION := 0.24
const SPECIAL_ACTIVATION_ANIMATION_DURATION := 0.22
const BOOSTER_ACTIVATION_ANIMATION_DURATION := 0.18
## Covers the matched-crystal gather-into-creation-cell phase plus the
## creation-cell pulse/flash phase; see BoardView._play_overlay_special_create().
const SPECIAL_CREATE_ANIMATION_DURATION := 0.36
const ICE_EVENT_ANIMATION_DURATION := 0.14


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

	_add_ice_event_request(sequence, data.ice_events, "turn", 0)

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
		_add_special_activation_requests(sequence, data.activated_special_tiles, data.special_cleared_cells, "turn", 0)
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

	_add_booster_activation_request(sequence, result.cleared_cells, result.booster_id, result.target_cell, result.affected_tile_types)
	_add_ice_event_request(sequence, result.ice_events, "booster", 0)
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
	# Cells that instead gather into a creation cell (see below) are excluded
	# here too, so they animate as a gather-in rather than a plain fade-out.
	var gather_source_cells := _special_gather_source_cells(step.created_special_tiles)
	var special_clear_cells := _cell_lookup(step.special_cleared_cells)
	var direct_clear_cells: Array[Vector2i] = []
	for cell in step.cleared_cells:
		if not gather_source_cells.has(cell):
			if special_clear_cells.has(cell):
				continue
			direct_clear_cells.append(cell)

	_add_ice_event_request(sequence, step.ice_events, source, step.cascade_index)

	if not direct_clear_cells.is_empty():
		sequence.add_request(REQUEST_SCRIPT.new_request(REQUEST_SCRIPT.TYPE_MATCH_CLEAR)
			.with_cells(direct_clear_cells)
			.with_duration(0.16)
			.with_payload({
				"source": source,
				"cascade_index": step.cascade_index,
				"cells_count": direct_clear_cells.size(),
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
		_add_special_activation_requests(sequence, step.activated_special_tiles, step.special_cleared_cells, source, step.cascade_index)
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

	_add_booster_activation_request(sequence, cleared_cells, booster_id, Vector2i(-1, -1), affected_tile_types)
	sequence.add_request(REQUEST_SCRIPT.new_request(REQUEST_SCRIPT.TYPE_BOOSTER_CLEAR)
		.with_cells(cleared_cells)
		.with_duration(0.08)
		.with_payload({
			"booster_id": booster_id,
			"damage_to_enemy": damage_to_enemy,
			"affected_tile_types": affected_tile_types.duplicate(),
		}))
	return sequence


func build_booster_activation_and_clear_sequence(cleared_cells: Array[Vector2i], booster_id: String, target_cell: Vector2i, damage_to_enemy: int, affected_tile_types: Array, ice_events: Array = []):
	var sequence := SEQUENCE_SCRIPT.new()
	if cleared_cells.is_empty():
		return sequence

	_add_booster_activation_request(sequence, cleared_cells, booster_id, target_cell, affected_tile_types)
	_add_ice_event_request(sequence, ice_events, "booster", 0)
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


func _add_booster_activation_request(sequence, cleared_cells: Array[Vector2i], booster_id: String, target_cell: Vector2i, affected_tile_types: Array) -> void:
	var resolved_target := target_cell
	if resolved_target == Vector2i(-1, -1) and not cleared_cells.is_empty():
		resolved_target = cleared_cells[0]

	sequence.add_request(REQUEST_SCRIPT.new_request(REQUEST_SCRIPT.TYPE_BOOSTER_ACTIVATION)
		.with_cells(cleared_cells)
		.with_duration(BOOSTER_ACTIVATION_ANIMATION_DURATION)
		.with_payload({
			"booster_id": booster_id,
			"target_cell": resolved_target,
			"affected_tile_types": affected_tile_types.duplicate(),
		}))


func _add_cascade_step_requests(sequence, cascade_step: Dictionary) -> void:
	var cascade_index: int = cascade_step.get("cascade_index", 0)
	_add_ice_event_request(sequence, cascade_step.get("ice_events", []), "cascade", cascade_index)

	var matched_cells := _to_vector2i_array(cascade_step.get("matched_cells", []))
	sequence.add_request(REQUEST_SCRIPT.new_request(REQUEST_SCRIPT.TYPE_CASCADE_STEP)
		.with_cells(matched_cells)
		.with_duration(CASCADE_STEP_DURATION)
		.with_payload({
			"cascade_index": cascade_index,
			"matched_cells": matched_cells,
			"damage": cascade_step.get("damage", 0),
		}))

	_add_gravity_and_refill_requests(sequence, cascade_step.get("fall_movements", []), cascade_step.get("refill_cells", []))


## Stage 56 v0.1: ice damage/break feedback is queued before the tile clear
## fade it accompanies, per the expected visual order (ice feedback, then
## tile clear, then gravity/refill).
func _add_ice_event_request(sequence, ice_events: Array, source: String, cascade_index: int) -> void:
	if ice_events.is_empty():
		return

	var cells: Array[Vector2i] = []
	for event in ice_events:
		var cell = (event as Dictionary).get("cell")
		if cell is Vector2i:
			cells.append(cell)

	sequence.add_request(REQUEST_SCRIPT.new_request(REQUEST_SCRIPT.TYPE_ICE_EVENT)
		.with_cells(cells)
		.with_duration(ICE_EVENT_ANIMATION_DURATION)
		.with_payload({
			"source": source,
			"cascade_index": cascade_index,
			"ice_events": (ice_events as Array).duplicate(true),
		}))


func _add_special_activation_requests(sequence, activated_special_tiles: Array, fallback_cells: Array[Vector2i], source: String, cascade_index: int) -> void:
	for item in activated_special_tiles:
		var data := item as Dictionary
		var cell = data.get("cell", Vector2i(-1, -1))
		if not (cell is Vector2i):
			continue
		var affected_cells := _to_vector2i_array(data.get("affected_cells", fallback_cells))
		if affected_cells.is_empty():
			affected_cells = fallback_cells.duplicate()
		sequence.add_request(REQUEST_SCRIPT.new_request(REQUEST_SCRIPT.TYPE_SPECIAL_ACTIVATION)
			.with_cells(affected_cells)
			.with_duration(SPECIAL_ACTIVATION_ANIMATION_DURATION)
			.with_payload({
				"source": source,
				"cascade_index": cascade_index,
				"cell": cell,
				"special_type": int(data.get("special_type", -1)),
				"affected_cells": affected_cells,
				"base_tile_type": int(data.get("base_tile_type", BoardModel.EMPTY)),
			}))


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


## Matched cells that gather into a created special's creation cell instead of
## fading out in place with the rest of the plain match clear.
func _special_gather_source_cells(created_special_tiles: Array) -> Dictionary:
	var cells := {}
	for item in created_special_tiles:
		var data := item as Dictionary
		var creation_cell = data.get("cell", Vector2i(-1, -1))
		for source_cell in data.get("source_cells", []):
			if source_cell != creation_cell:
				cells[source_cell] = true
	return cells


func _cell_lookup(cells: Array[Vector2i]) -> Dictionary:
	var lookup := {}
	for cell in cells:
		lookup[cell] = true
	return lookup

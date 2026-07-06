extends RefCounted
class_name BoardAnimationSequenceBuilder

const REQUEST_SCRIPT := preload("res://scripts/game/presentation/board_animation_request.gd")
const SEQUENCE_SCRIPT := preload("res://scripts/game/presentation/board_animation_sequence.gd")


func build_from_turn_presentation(data):
	var sequence := SEQUENCE_SCRIPT.new()
	if data == null:
		return sequence

	if not data.is_valid:
		return build_invalid_swap(data.swapped_from, data.swapped_to, data.invalid_reason)

	sequence.add_request(REQUEST_SCRIPT.new_request(REQUEST_SCRIPT.TYPE_SWAP)
		.with_swap(data.swapped_from, data.swapped_to)
		.with_duration(0.06)
		.with_payload({"source": "turn"}))

	if not data.matched_cells.is_empty():
		sequence.add_request(REQUEST_SCRIPT.new_request(REQUEST_SCRIPT.TYPE_MATCH_CLEAR)
			.with_cells(data.matched_cells)
			.with_duration(0.08)
			.with_payload({"total_tiles_cleared": data.total_tiles_cleared}))

	if not data.special_cleared_cells.is_empty():
		sequence.add_request(REQUEST_SCRIPT.new_request(REQUEST_SCRIPT.TYPE_SPECIAL_CLEAR)
			.with_cells(data.special_cleared_cells)
			.with_duration(0.08)
			.with_payload({"activated_special_tiles": data.activated_special_tiles.duplicate(true)}))

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

	return sequence


func build_invalid_swap(from_cell: Vector2i, to_cell: Vector2i, reason: String = ""):
	var sequence := SEQUENCE_SCRIPT.new()
	sequence.add_request(REQUEST_SCRIPT.new_request(REQUEST_SCRIPT.TYPE_INVALID_SWAP)
		.with_swap(from_cell, to_cell)
		.with_duration(0.06)
		.with_payload({"reason": reason}))
	return sequence

extends RefCounted
class_name TurnPresentationData

const SCRIPT_PATH := "res://scripts/game/presentation/turn_presentation_data.gd"

var is_valid := false
var invalid_reason := ""
var swapped_from := Vector2i(-1, -1)
var swapped_to := Vector2i(-1, -1)
var initial_matches: Array[MatchResult] = []
var matched_cells: Array[Vector2i] = []
var lane_activations: Dictionary = {}
var damage_events: Array[Dictionary] = []
var total_damage_to_enemy := 0
var total_tiles_cleared := 0
var damage_breakdown: Array = []
var ability_charge_events: Array[Dictionary] = []
var enemy_action: Dictionary = {}
var battle_status := BattleState.Status.IN_PROGRESS
var created_special_tiles: Array[Dictionary] = []
var activated_special_tiles: Array[Dictionary] = []
var special_cleared_cells: Array[Vector2i] = []
var fall_movements: Array[Dictionary] = []
var refill_cells: Array[Dictionary] = []
var cascade_steps: Array[Dictionary] = []


static func from_valid_turn(from_cell: Vector2i, to_cell: Vector2i, matches: Array[MatchResult], result: BattleTurnResult, board_result: BoardResolveResult = null):
	var data = load(SCRIPT_PATH).new()
	data.is_valid = true
	data.swapped_from = from_cell
	data.swapped_to = to_cell
	data.initial_matches = matches.duplicate()
	data.matched_cells = data._extract_matched_cells(matches)
	data.lane_activations = result.lane_activations.duplicate()
	data.damage_events = result.damage_events.duplicate()
	data.total_damage_to_enemy = result.total_damage_to_enemy
	data.total_tiles_cleared = result.total_tiles_cleared
	data.damage_breakdown = result.damage_breakdown.duplicate()
	data.ability_charge_events = result.ability_charge_events.duplicate()
	data.enemy_action = result.enemy_action.duplicate()
	data.battle_status = result.battle_status
	if board_result != null:
		data.created_special_tiles = board_result.created_special_tiles.duplicate()
		data.activated_special_tiles = board_result.activated_special_tiles.duplicate()
		data.special_cleared_cells = board_result.special_cleared_cells.duplicate()
		var first_step: Dictionary = board_result.get_step(0)
		data.fall_movements = data._to_dictionary_array(first_step.get("fall_movements", []))
		data.refill_cells = data._to_dictionary_array(first_step.get("refill_cells", []))
		if board_result.cascade_steps.size() > 1:
			data.cascade_steps = data._to_dictionary_array(board_result.cascade_steps.slice(1))
	return data


static func from_invalid_turn(from_cell: Vector2i, to_cell: Vector2i, reason: String):
	var data = load(SCRIPT_PATH).new()
	data.is_valid = false
	data.invalid_reason = reason
	data.swapped_from = from_cell
	data.swapped_to = to_cell
	return data


func to_dictionary() -> Dictionary:
	return {
		"is_valid": is_valid,
		"invalid_reason": invalid_reason,
		"swapped_from": swapped_from,
		"swapped_to": swapped_to,
		"initial_matches": initial_matches.duplicate(),
		"matched_cells": matched_cells.duplicate(),
		"lane_activations": lane_activations.duplicate(),
		"damage_events": damage_events.duplicate(),
		"total_damage_to_enemy": total_damage_to_enemy,
		"total_tiles_cleared": total_tiles_cleared,
		"damage_breakdown": damage_breakdown.duplicate(),
		"ability_charge_events": ability_charge_events.duplicate(),
		"enemy_action": enemy_action.duplicate(),
		"battle_status": battle_status,
		"created_special_tiles": created_special_tiles.duplicate(),
		"activated_special_tiles": activated_special_tiles.duplicate(),
		"special_cleared_cells": special_cleared_cells.duplicate(),
		"fall_movements": fall_movements.duplicate(),
		"refill_cells": refill_cells.duplicate(),
		"cascade_steps": cascade_steps.duplicate(),
	}


func _to_dictionary_array(values: Array) -> Array[Dictionary]:
	var typed_values: Array[Dictionary] = []
	for value in values:
		typed_values.append(value as Dictionary)
	return typed_values


func _extract_matched_cells(matches: Array[MatchResult]) -> Array[Vector2i]:
	var seen := {}
	var cells: Array[Vector2i] = []

	for match_result in matches:
		for cell in match_result.cells:
			if seen.has(cell):
				continue

			seen[cell] = true
			cells.append(cell)

	return cells

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
var ability_charge_events: Array[Dictionary] = []
var enemy_action: Dictionary = {}
var battle_status := BattleState.Status.IN_PROGRESS


static func from_valid_turn(from_cell: Vector2i, to_cell: Vector2i, matches: Array[MatchResult], result: BattleTurnResult):
	var data = load(SCRIPT_PATH).new()
	data.is_valid = true
	data.swapped_from = from_cell
	data.swapped_to = to_cell
	data.initial_matches = matches.duplicate()
	data.matched_cells = data._extract_matched_cells(matches)
	data.lane_activations = result.lane_activations.duplicate()
	data.damage_events = result.damage_events.duplicate()
	data.total_damage_to_enemy = result.total_damage_to_enemy
	data.ability_charge_events = result.ability_charge_events.duplicate()
	data.enemy_action = result.enemy_action.duplicate()
	data.battle_status = result.battle_status
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
		"ability_charge_events": ability_charge_events.duplicate(),
		"enemy_action": enemy_action.duplicate(),
		"battle_status": battle_status,
	}


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

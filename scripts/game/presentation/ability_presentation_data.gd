extends RefCounted
class_name AbilityPresentationData

const SCRIPT_PATH := "res://scripts/game/presentation/ability_presentation_data.gd"

var result
var accepted := false
var reason := ""
var hero_id := ""
var lane_index := -1
var ability_id := ""
var display_name := ""
var damage_to_enemy := 0
var healed_heroes: Array[Dictionary] = []
var cleared_cells: Array[Vector2i] = []
var board_changed := false
var battle_status := BattleState.Status.IN_PROGRESS


static func from_result(ability_result):
	var data = load(SCRIPT_PATH).new()
	data.result = ability_result
	data.accepted = ability_result.accepted
	data.reason = ability_result.reason
	data.hero_id = ability_result.hero_id
	data.lane_index = ability_result.lane_index
	data.ability_id = ability_result.ability_id
	data.display_name = ability_result.display_name
	data.damage_to_enemy = ability_result.damage_to_enemy
	data.healed_heroes = ability_result.healed_heroes.duplicate()
	data.cleared_cells = ability_result.cleared_cells.duplicate()
	data.board_changed = ability_result.board_changed
	data.battle_status = ability_result.battle_status
	return data


func to_dictionary() -> Dictionary:
	return {
		"accepted": accepted,
		"reason": reason,
		"hero_id": hero_id,
		"lane_index": lane_index,
		"ability_id": ability_id,
		"display_name": display_name,
		"damage_to_enemy": damage_to_enemy,
		"healed_heroes": healed_heroes.duplicate(),
		"cleared_cells": cleared_cells.duplicate(),
		"board_changed": board_changed,
		"battle_status": battle_status,
	}

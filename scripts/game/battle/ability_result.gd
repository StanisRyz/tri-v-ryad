extends RefCounted
class_name AbilityResult

const SCRIPT_PATH := "res://scripts/game/battle/ability_result.gd"

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


static func accepted_result(hero: HeroData, ability, status: int):
	var result = load(SCRIPT_PATH).new()
	result.accepted = true
	result.hero_id = hero.id
	result.lane_index = hero.lane_index
	result.ability_id = ability.id
	result.display_name = ability.display_name
	result.battle_status = status
	return result


static func rejected_result(rejected_hero_id: String, rejected_lane_index: int, reject_reason: String):
	var result = load(SCRIPT_PATH).new()
	result.accepted = false
	result.reason = reject_reason
	result.hero_id = rejected_hero_id
	result.lane_index = rejected_lane_index
	return result


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

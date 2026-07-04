extends RefCounted
class_name BattleTurnResult

var lane_activations: Dictionary = {}
var damage_events: Array[Dictionary] = []
var total_damage_to_enemy := 0
var ability_charge_events: Array[Dictionary] = []
var enemy_action: Dictionary = {}
var battle_status := BattleState.Status.IN_PROGRESS


func to_dictionary() -> Dictionary:
	return {
		"lane_activations": lane_activations.duplicate(),
		"damage_events": damage_events.duplicate(),
		"total_damage_to_enemy": total_damage_to_enemy,
		"ability_charge_events": ability_charge_events.duplicate(),
		"enemy_action": enemy_action.duplicate(),
		"battle_status": battle_status,
	}

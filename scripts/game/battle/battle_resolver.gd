extends RefCounted
class_name BattleResolver

var _hero_lane_resolver := HeroLaneResolver.new()
var _damage_resolver := DamageResolver.new()
var _ability_charge_resolver := AbilityChargeResolver.new()
var _enemy_action_resolver := EnemyActionResolver.new()


func resolve_player_matches(state: BattleState, matches: Array[MatchResult]) -> BattleTurnResult:
	var turn_result := BattleTurnResult.new()

	if state.is_finished():
		turn_result.battle_status = state.status
		return turn_result

	turn_result.lane_activations = _hero_lane_resolver.resolve_matches(matches)

	var damage_result := _damage_resolver.apply_hero_damage(state, turn_result.lane_activations)
	turn_result.damage_events = damage_result.get("damage_events", [])
	turn_result.total_damage_to_enemy = damage_result.get("total_damage", 0)
	turn_result.ability_charge_events = _ability_charge_resolver.apply_ability_charge(state, turn_result.lane_activations)

	state.moves_left = max(0, state.moves_left - 1)
	state.turn_number += 1
	state.update_status()

	if not state.is_finished():
		turn_result.enemy_action = _enemy_action_resolver.resolve_enemy_action(state)
		state.update_status()
	else:
		turn_result.enemy_action = _empty_enemy_action()

	turn_result.battle_status = state.status
	return turn_result


func _empty_enemy_action() -> Dictionary:
	return {
		"acted": false,
		"target_lane": -1,
		"target_hero_id": "",
		"damage": 0,
	}

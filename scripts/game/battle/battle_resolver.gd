extends RefCounted
class_name BattleResolver

var _hero_lane_resolver := HeroLaneResolver.new()
var _damage_resolver := DamageResolver.new()
var _ability_charge_resolver := AbilityChargeResolver.new()
var _enemy_action_resolver := EnemyActionResolver.new()
var _direct_damage_resolver := DirectMatchDamageResolver.new()
var _round_modifier = null


func set_round_modifier(round_modifier) -> void:
	_round_modifier = round_modifier


func resolve_player_matches(state: BattleState, matches: Array[MatchResult], board_result: BoardResolveResult = null) -> BattleTurnResult:
	var turn_result := BattleTurnResult.new()

	if state.is_finished():
		turn_result.battle_status = state.status
		return turn_result

	if FeatureFlags.HERO_SYSTEMS_ENABLED:
		_resolve_hero_path(state, matches, turn_result)
	else:
		_resolve_direct_damage_path(state, matches, board_result, _round_modifier, turn_result)

	var booster_state = state.get("booster_state")
	if booster_state != null and booster_state.consume_freeze_turn():
		pass
	else:
		state.moves_left = max(0, state.moves_left - 1)
	state.turn_number += 1
	state.update_status()

	if not state.is_finished() and FeatureFlags.HERO_SYSTEMS_ENABLED:
		turn_result.enemy_action = _enemy_action_resolver.resolve_enemy_action(state)
		state.update_status()
	else:
		turn_result.enemy_action = _empty_enemy_action()

	turn_result.battle_status = state.status
	return turn_result


func _resolve_hero_path(state: BattleState, matches: Array[MatchResult], turn_result: BattleTurnResult) -> void:
	turn_result.lane_activations = _hero_lane_resolver.resolve_matches(matches)

	var damage_result := _damage_resolver.apply_hero_damage(state, turn_result.lane_activations)
	turn_result.damage_events = damage_result.get("damage_events", [])
	turn_result.total_damage_to_enemy = damage_result.get("total_damage", 0)
	turn_result.ability_charge_events = _ability_charge_resolver.apply_ability_charge(state, turn_result.lane_activations)


func _resolve_direct_damage_path(state: BattleState, matches: Array[MatchResult], board_result: BoardResolveResult, round_modifier, turn_result: BattleTurnResult) -> void:
	var damage_info := _calculate_direct_damage(matches, board_result, round_modifier)
	var damage: int = damage_info.get("damage", 0)
	var tile_count: int = damage_info.get("tile_count", 0)

	turn_result.total_damage_to_enemy = damage
	turn_result.total_tiles_cleared = tile_count
	turn_result.damage_breakdown = damage_info.get("breakdown", [])
	turn_result.damage_events = [{
		"lane_index": -1,
		"hero_id": "",
		"tile_count": tile_count,
		"damage": damage,
	}]

	if state.enemy != null:
		state.enemy.take_damage(damage)


func _calculate_direct_damage(matches: Array[MatchResult], board_result: BoardResolveResult, round_modifier) -> Dictionary:
	if board_result != null:
		var damage: int = _direct_damage_resolver.calculate_damage_for_board_result(board_result, round_modifier)
		var breakdown: Array = _direct_damage_resolver.build_damage_breakdown(matches, board_result, round_modifier)
		return {"damage": damage, "tile_count": board_result.total_cleared, "breakdown": breakdown}

	var result: Dictionary = _direct_damage_resolver.calculate_damage_for_matches(matches, round_modifier)
	return {
		"damage": result.get("total_damage", 0),
		"tile_count": result.get("tile_count", 0),
		"breakdown": result.get("breakdown", []),
	}


func _empty_enemy_action() -> Dictionary:
	return {
		"acted": false,
		"target_lane": -1,
		"target_hero_id": "",
		"damage": 0,
	}

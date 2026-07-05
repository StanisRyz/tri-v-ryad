extends RefCounted
class_name BattleResolver

var _hero_lane_resolver := HeroLaneResolver.new()
var _damage_resolver := DamageResolver.new()
var _ability_charge_resolver := AbilityChargeResolver.new()
var _enemy_action_resolver := EnemyActionResolver.new()
var _direct_damage_resolver := DirectMatchDamageResolver.new()


func resolve_player_matches(state: BattleState, matches: Array[MatchResult], board_result: BoardResolveResult = null) -> BattleTurnResult:
	var turn_result := BattleTurnResult.new()

	if state.is_finished():
		turn_result.battle_status = state.status
		return turn_result

	if FeatureFlags.HERO_SYSTEMS_ENABLED:
		_resolve_hero_path(state, matches, turn_result)
	else:
		_resolve_direct_damage_path(state, matches, board_result, turn_result)

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


func _resolve_direct_damage_path(state: BattleState, matches: Array[MatchResult], board_result: BoardResolveResult, turn_result: BattleTurnResult) -> void:
	var cleared_cell_count := _count_cleared_cells(matches, board_result)
	var damage := cleared_cell_count

	turn_result.total_damage_to_enemy = damage
	turn_result.damage_events = [{
		"lane_index": -1,
		"hero_id": "",
		"tile_count": cleared_cell_count,
		"damage": damage,
	}]

	if state.enemy != null:
		state.enemy.take_damage(damage)


func _count_cleared_cells(matches: Array[MatchResult], board_result: BoardResolveResult) -> int:
	if board_result != null:
		return _direct_damage_resolver.calculate_damage_from_turn_result(board_result)

	var cells: Array[Vector2i] = []
	var seen := {}
	for match_result in matches:
		for cell in match_result.cells:
			if seen.has(cell):
				continue
			seen[cell] = true
			cells.append(cell)

	return _direct_damage_resolver.calculate_damage(cells)


func _empty_enemy_action() -> Dictionary:
	return {
		"acted": false,
		"target_lane": -1,
		"target_hero_id": "",
		"damage": 0,
	}

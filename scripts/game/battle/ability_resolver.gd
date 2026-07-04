extends RefCounted
class_name AbilityResolver

const ABILITY_DATA_SCRIPT := preload("res://scripts/game/battle/ability_data.gd")
const ABILITY_RESULT_SCRIPT := preload("res://scripts/game/battle/ability_result.gd")


func resolve_ability(state: BattleState, board: BoardModel, lane_index: int):
	if state == null or board == null:
		return ABILITY_RESULT_SCRIPT.rejected_result("", lane_index, "invalid_state")

	if state.is_finished():
		return ABILITY_RESULT_SCRIPT.rejected_result("", lane_index, "battle_finished")

	var hero := state.get_hero_by_lane(lane_index)
	if hero == null:
		return ABILITY_RESULT_SCRIPT.rejected_result("", lane_index, "hero_missing")

	if not hero.is_alive():
		return ABILITY_RESULT_SCRIPT.rejected_result(hero.id, lane_index, "hero_dead")

	if not hero.is_ability_ready():
		return ABILITY_RESULT_SCRIPT.rejected_result(hero.id, lane_index, "ability_not_ready")

	var ability = ABILITY_DATA_SCRIPT.get_for_ability(hero.ability_id, hero.id)
	if ability.id == "" or ability.damage_multiplier <= 0:
		return ABILITY_RESULT_SCRIPT.rejected_result(hero.id, lane_index, "unknown_ability")

	var result = ABILITY_RESULT_SCRIPT.accepted_result(hero, ability, state.status)
	_apply_damage_ability(state, hero, ability, result)

	hero.ability_charge = 0
	state.update_status()
	result.battle_status = state.status
	return result


func _apply_damage_ability(state: BattleState, hero: HeroData, ability: AbilityData, result) -> void:
	var damage := hero.get_attack() * ability.damage_multiplier
	state.enemy.take_damage(damage)
	result.damage_to_enemy = damage
	result.board_changed = false

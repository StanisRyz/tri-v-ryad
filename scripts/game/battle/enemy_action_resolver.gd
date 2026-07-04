extends RefCounted
class_name EnemyActionResolver


func resolve_enemy_action(state: BattleState) -> Dictionary:
	var result := {
		"acted": false,
		"target_lane": -1,
		"target_hero_id": "",
		"damage": 0,
	}

	if state.is_finished():
		return result

	if not state.enemy_intent.tick():
		return result

	var target := _get_target_hero(state)
	if target == null:
		state.enemy_intent.reset()
		return result

	target.take_damage(state.enemy.attack)
	state.enemy_intent.reset()

	result["acted"] = true
	result["target_lane"] = target.lane_index
	result["target_hero_id"] = target.id
	result["damage"] = state.enemy.attack
	return result


func _get_target_hero(state: BattleState) -> HeroData:
	var primary_target := state.get_hero_by_lane(state.enemy_intent.target_lane)
	if primary_target != null and primary_target.is_alive():
		return primary_target

	var alive_heroes := state.get_alive_heroes()
	if alive_heroes.is_empty():
		return null

	return alive_heroes[0]

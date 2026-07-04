extends RefCounted
class_name DamageResolver


func apply_hero_damage(state: BattleState, lane_activations: Dictionary) -> Dictionary:
	var damage_events: Array[Dictionary] = []
	var total_damage := 0

	for lane_index in lane_activations.keys():
		var tile_count: int = lane_activations[lane_index]
		var hero := state.get_hero_by_lane(lane_index)
		var hero_id := ""
		var damage := 0

		if hero != null:
			hero_id = hero.id
			if hero.is_alive():
				damage = hero.get_attack() * tile_count

		total_damage += damage
		damage_events.append({
			"lane_index": lane_index,
			"hero_id": hero_id,
			"tile_count": tile_count,
			"damage": damage,
		})

	state.enemy.take_damage(total_damage)

	return {
		"damage_events": damage_events,
		"total_damage": total_damage,
	}

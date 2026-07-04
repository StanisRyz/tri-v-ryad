extends RefCounted
class_name AbilityChargeResolver


func apply_ability_charge(state: BattleState, lane_activations: Dictionary) -> Array[Dictionary]:
	var charge_events: Array[Dictionary] = []

	for lane_index in lane_activations.keys():
		var charge_added: int = lane_activations[lane_index]
		var hero := state.get_hero_by_lane(lane_index)
		if hero == null or not hero.is_alive():
			continue

		hero.add_ability_charge(charge_added)
		charge_events.append({
			"lane_index": lane_index,
			"hero_id": hero.id,
			"charge_added": charge_added,
			"current_charge": hero.ability_charge,
			"ability_ready": hero.is_ability_ready(),
		})

	return charge_events

extends RefCounted
class_name BattleFactory


func create_state(level_config, progress = null) -> BattleState:
	var heroes: Array[HeroData] = []
	for hero_config in level_config.get_hero_configs():
		var hero_data: HeroData = hero_config.to_hero_data()
		if progress != null:
			var upgrade_state = progress.get_hero_upgrade(hero_config.hero_id)
			hero_data.attack_level = upgrade_state.attack_level
			hero_data.hp_level = upgrade_state.hp_level
			hero_data.heal_to_full()
		heroes.append(hero_data)

	var enemy_config = level_config.get_enemy_config()
	return BattleState.new(
		heroes,
		enemy_config.to_enemy_data(),
		enemy_config.to_enemy_intent(),
		level_config.moves
	)

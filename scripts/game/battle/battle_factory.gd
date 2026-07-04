extends RefCounted
class_name BattleFactory


func create_state(level_config) -> BattleState:
	var heroes: Array[HeroData] = []
	for hero_config in level_config.get_hero_configs():
		heroes.append(hero_config.to_hero_data())

	var enemy_config = level_config.get_enemy_config()
	return BattleState.new(
		heroes,
		enemy_config.to_enemy_data(),
		enemy_config.to_enemy_intent(),
		level_config.moves
	)

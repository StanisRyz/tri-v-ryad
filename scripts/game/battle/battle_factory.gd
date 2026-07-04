extends RefCounted
class_name BattleFactory


const TEAM_SELECTION_RESOLVER_SCRIPT := preload("res://scripts/game/progression/team_selection_resolver.gd")


func create_state(level_config, progress = null, hero_catalog: HeroCatalog = null) -> BattleState:
	var heroes: Array[HeroData] = []
	var hero_configs := _get_battle_hero_configs(level_config, progress, hero_catalog)
	for index in range(hero_configs.size()):
		var hero_config = hero_configs[index]
		var hero_data: HeroData = hero_config.to_hero_data()
		hero_data.lane_index = index
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


func _get_battle_hero_configs(level_config, progress, hero_catalog: HeroCatalog) -> Array:
	if progress == null or hero_catalog == null:
		return level_config.get_hero_configs()

	var resolver = TEAM_SELECTION_RESOLVER_SCRIPT.new()
	var selected_ids: Array[String] = resolver.normalize_team(progress.get_selected_team_ids(), hero_catalog)
	var selected_heroes := hero_catalog.get_heroes(selected_ids)
	if selected_heroes.size() == 3:
		return selected_heroes

	return level_config.get_hero_configs()

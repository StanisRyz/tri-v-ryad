extends RefCounted
class_name LevelCatalog

const HERO_CONFIG_SCRIPT := preload("res://scripts/game/config/hero_config.gd")
const ENEMY_CONFIG_SCRIPT := preload("res://scripts/game/config/enemy_config.gd")
const LEVEL_CONFIG_SCRIPT := preload("res://scripts/game/config/level_config.gd")

var _levels: Dictionary = {}
var _level_order: Array[String] = []


func _init() -> void:
	_register_levels()


func get_level(level_id: String):
	if has_level(level_id):
		return _levels[level_id]

	return _levels[get_default_level_id()]


func get_all_levels() -> Array:
	var levels: Array = []
	for level_id in _level_order:
		levels.append(_levels[level_id])
	return levels


func has_level(level_id: String) -> bool:
	return _levels.has(level_id)


func get_default_level_id() -> String:
	return "level_1"


func _register_levels() -> void:
	var heroes := HERO_CONFIG_SCRIPT.get_default_party()
	_add_level("level_1", "Level 1", ENEMY_CONFIG_SCRIPT.training_dummy(), 24, heroes, 1)
	_add_level("level_2", "Level 2", ENEMY_CONFIG_SCRIPT.small_slime(), 24, heroes, 1)
	_add_level("level_3", "Level 3", ENEMY_CONFIG_SCRIPT.goblin_scout(), 23, heroes, 1)
	_add_level("level_4", "Level 4", ENEMY_CONFIG_SCRIPT.goblin_fighter(), 23, heroes, 2)
	_add_level("level_5", "Level 5", ENEMY_CONFIG_SCRIPT.armored_goblin(), 22, heroes, 2)
	_add_level("level_6", "Level 6", ENEMY_CONFIG_SCRIPT.wild_wolf(), 22, heroes, 2)
	_add_level("level_7", "Level 7", ENEMY_CONFIG_SCRIPT.bandit(), 21, heroes, 2)
	_add_level("level_8", "Level 8", ENEMY_CONFIG_SCRIPT.orc_brute(), 21, heroes, 2)
	_add_level("level_9", "Level 9", ENEMY_CONFIG_SCRIPT.cave_shaman(), 20, heroes, 2)
	_add_level("level_10", "Level 10", ENEMY_CONFIG_SCRIPT.gatekeeper(), 22, heroes, 3)


func _add_level(level_id: String, display_name: String, enemy_config, moves: int, hero_configs: Array, reward_upgrade_points: int) -> void:
	_levels[level_id] = LEVEL_CONFIG_SCRIPT.new(level_id, display_name, enemy_config, moves, hero_configs, reward_upgrade_points)
	_level_order.append(level_id)

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
	_add_level("level_1", "Level 1: Training Yard", ENEMY_CONFIG_SCRIPT.training_dummy(), 20, heroes, 1)
	_add_level("level_2", "Level 2: Slime Trail", ENEMY_CONFIG_SCRIPT.weak_slime(), 18, heroes, 1)
	_add_level("level_3", "Level 3: Guard Post", ENEMY_CONFIG_SCRIPT.armored_guard(), 21, heroes, 2)
	_add_level("level_4", "Level 4: Wild Path", ENEMY_CONFIG_SCRIPT.wild_beast(), 19, heroes, 2)
	_add_level("level_5", "Level 5: First Boss", ENEMY_CONFIG_SCRIPT.first_boss(), 24, heroes, 3)


func _add_level(level_id: String, display_name: String, enemy_config, moves: int, hero_configs: Array, reward_upgrade_points: int) -> void:
	_levels[level_id] = LEVEL_CONFIG_SCRIPT.new(level_id, display_name, enemy_config, moves, hero_configs, reward_upgrade_points)
	_level_order.append(level_id)

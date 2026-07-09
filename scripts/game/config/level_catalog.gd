extends RefCounted
class_name LevelCatalog

const HERO_CONFIG_SCRIPT := preload("res://scripts/game/config/hero_config.gd")
const ENEMY_CONFIG_SCRIPT := preload("res://scripts/game/config/enemy_config.gd")
const ENEMY_CATALOG_SCRIPT := preload("res://scripts/game/config/enemy_catalog.gd")
const LEVEL_CONFIG_SCRIPT := preload("res://scripts/game/config/level_config.gd")
const UPGRADE_ECONOMY_CONFIG := preload("res://scripts/game/progression/upgrade_economy_config.gd")
const DIRECT_BATTLE_BALANCE_SCRIPT := preload("res://scripts/game/config/direct_battle_balance.gd")

const CAMPAIGN_LEVEL_COUNT := 100

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
	for level_number in range(1, CAMPAIGN_LEVEL_COUNT + 1):
		_add_level(
			_get_level_id(level_number),
			_get_display_name(level_number),
			_get_fallback_enemy_for_level(level_number),
			_get_moves_for_level(level_number),
			heroes,
			_get_reward_for_level(level_number)
		)


func _add_level(level_id: String, display_name: String, enemy_config, moves: int, hero_configs: Array, reward_upgrade_points: int) -> void:
	_levels[level_id] = LEVEL_CONFIG_SCRIPT.new(level_id, display_name, enemy_config, moves, hero_configs, reward_upgrade_points)
	_level_order.append(level_id)


func _get_level_id(level_number: int) -> String:
	return "level_%d" % level_number


func _get_display_name(level_number: int) -> String:
	return "Level %d" % level_number


func _get_moves_for_level(level_number: int) -> int:
	return DIRECT_BATTLE_BALANCE_SCRIPT.get_moves_for_level(level_number)


func _get_reward_for_level(level_number: int) -> int:
	return UPGRADE_ECONOMY_CONFIG.get_level_reward(level_number)


func _get_fallback_enemy_for_level(level_number: int):
	var enemies: Array = ENEMY_CATALOG_SCRIPT.new().get_all_enemies()
	if enemies.is_empty():
		return ENEMY_CONFIG_SCRIPT.enemy_1()

	var enemy_index := (level_number - 1) % enemies.size()
	return enemies[enemy_index]

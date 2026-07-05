extends RefCounted
class_name EnemyCatalog

const ENEMY_CONFIG_SCRIPT := preload("res://scripts/game/config/enemy_config.gd")

var _enemies: Dictionary = {}
var _enemy_order: Array[String] = []


func _init() -> void:
	_register_enemies()


func get_all_enemies() -> Array:
	var enemies: Array = []
	for enemy_id in _enemy_order:
		enemies.append(_enemies[enemy_id])
	return enemies


func get_enemy(enemy_id: String):
	if has_enemy(enemy_id):
		return _enemies[enemy_id]

	return null


func has_enemy(enemy_id: String) -> bool:
	return _enemies.has(enemy_id)


func get_default_enemy():
	return get_enemy("training_dummy")


func is_valid_enemy(enemy_config) -> bool:
	if enemy_config == null:
		return false
	if enemy_config.enemy_id == "":
		return false
	if enemy_config.display_name == "":
		return false
	if enemy_config.max_hp <= 0:
		return false
	if enemy_config.attack < 0:
		return false
	if enemy_config.intent_turns <= 0:
		return false
	if enemy_config.target_lane < 0 or enemy_config.target_lane > 2:
		return false

	return true


func _register_enemies() -> void:
	_add_enemy(ENEMY_CONFIG_SCRIPT.training_dummy())
	_add_enemy(ENEMY_CONFIG_SCRIPT.small_slime())
	_add_enemy(ENEMY_CONFIG_SCRIPT.goblin_scout())
	_add_enemy(ENEMY_CONFIG_SCRIPT.goblin_fighter())
	_add_enemy(ENEMY_CONFIG_SCRIPT.armored_goblin())
	_add_enemy(ENEMY_CONFIG_SCRIPT.wild_wolf())
	_add_enemy(ENEMY_CONFIG_SCRIPT.bandit())
	_add_enemy(ENEMY_CONFIG_SCRIPT.orc_brute())
	_add_enemy(ENEMY_CONFIG_SCRIPT.cave_shaman())
	_add_enemy(ENEMY_CONFIG_SCRIPT.gatekeeper())


func _add_enemy(enemy_config) -> void:
	if enemy_config == null or enemy_config.enemy_id == "" or _enemies.has(enemy_config.enemy_id):
		return

	_enemies[enemy_config.enemy_id] = enemy_config
	_enemy_order.append(enemy_config.enemy_id)

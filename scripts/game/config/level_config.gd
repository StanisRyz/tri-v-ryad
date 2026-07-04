extends RefCounted
class_name LevelConfig

var level_id := ""
var display_name := ""
var enemy_config
var moves := 20
var hero_configs: Array = []
var reward_upgrade_points := 0


func _init(config_level_id: String = "", config_display_name: String = "", config_enemy_config = null, config_moves: int = 20, config_hero_configs: Array = [], config_reward_upgrade_points: int = 0) -> void:
	level_id = config_level_id
	display_name = config_display_name
	enemy_config = config_enemy_config
	moves = config_moves
	hero_configs = config_hero_configs.duplicate()
	reward_upgrade_points = config_reward_upgrade_points


func get_enemy_config():
	return enemy_config


func get_hero_configs() -> Array:
	return hero_configs.duplicate()

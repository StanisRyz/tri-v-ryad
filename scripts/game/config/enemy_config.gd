extends RefCounted
class_name EnemyConfig

const SCRIPT_PATH := "res://scripts/game/config/enemy_config.gd"

var enemy_id := ""
var display_name := ""
var max_hp := 0
var attack := 0
var intent_turns := 3
var target_lane := 1


func _init(config_enemy_id: String = "", config_display_name: String = "", config_max_hp: int = 0, config_attack: int = 0, config_intent_turns: int = 3, config_target_lane: int = 1) -> void:
	enemy_id = config_enemy_id
	display_name = config_display_name
	max_hp = config_max_hp
	attack = config_attack
	intent_turns = config_intent_turns
	target_lane = config_target_lane


func to_enemy_data() -> EnemyData:
	return EnemyData.new(enemy_id, display_name, max_hp, attack)


func to_enemy_intent() -> EnemyIntent:
	return EnemyIntent.new(intent_turns, target_lane)


static func enemy_1():
	return load(SCRIPT_PATH).new("enemy_1", "Enemy 1", 220, 10, 4, 1)


static func enemy_2():
	return load(SCRIPT_PATH).new("enemy_2", "Enemy 2", 260, 12, 4, 0)


static func enemy_3():
	return load(SCRIPT_PATH).new("enemy_3", "Enemy 3", 310, 15, 3, 2)


static func enemy_4():
	return load(SCRIPT_PATH).new("enemy_4", "Enemy 4", 360, 18, 3, 1)


static func enemy_5():
	return load(SCRIPT_PATH).new("enemy_5", "Enemy 5", 430, 20, 3, 2)


static func enemy_6():
	return load(SCRIPT_PATH).new("enemy_6", "Enemy 6", 470, 24, 2, 0)


static func enemy_7():
	return load(SCRIPT_PATH).new("enemy_7", "Enemy 7", 540, 27, 2, 1)


static func enemy_8():
	return load(SCRIPT_PATH).new("enemy_8", "Enemy 8", 620, 30, 2, 2)


static func enemy_9():
	return load(SCRIPT_PATH).new("enemy_9", "Enemy 9", 680, 32, 3, 1)


static func enemy_10():
	return load(SCRIPT_PATH).new("enemy_10", "Enemy 10", 820, 38, 2, 1)

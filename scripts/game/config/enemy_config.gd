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


static func training_dummy():
	return load(SCRIPT_PATH).new("training_dummy", "Training Dummy", 260, 16, 3, 1)


static func weak_slime():
	return load(SCRIPT_PATH).new("weak_slime", "Weak Slime", 220, 14, 4, 0)


static func armored_guard():
	return load(SCRIPT_PATH).new("armored_guard", "Armored Guard", 340, 22, 3, 2)


static func wild_beast():
	return load(SCRIPT_PATH).new("wild_beast", "Wild Beast", 390, 26, 2, 1)


static func first_boss():
	return load(SCRIPT_PATH).new("first_boss", "First Boss", 520, 32, 2, 1)

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
	return load(SCRIPT_PATH).new("training_dummy", "Training Dummy", 220, 10, 4, 1)


static func small_slime():
	return load(SCRIPT_PATH).new("small_slime", "Small Slime", 260, 12, 4, 0)


static func goblin_scout():
	return load(SCRIPT_PATH).new("goblin_scout", "Goblin Scout", 310, 15, 3, 2)


static func goblin_fighter():
	return load(SCRIPT_PATH).new("goblin_fighter", "Goblin Fighter", 360, 18, 3, 1)


static func armored_goblin():
	return load(SCRIPT_PATH).new("armored_goblin", "Armored Goblin", 430, 20, 3, 2)


static func wild_wolf():
	return load(SCRIPT_PATH).new("wild_wolf", "Wild Wolf", 470, 24, 2, 0)


static func bandit():
	return load(SCRIPT_PATH).new("bandit", "Bandit", 540, 27, 2, 1)


static func orc_brute():
	return load(SCRIPT_PATH).new("orc_brute", "Orc Brute", 620, 30, 2, 2)


static func cave_shaman():
	return load(SCRIPT_PATH).new("cave_shaman", "Cave Shaman", 680, 32, 3, 1)


static func gatekeeper():
	return load(SCRIPT_PATH).new("gatekeeper", "Gatekeeper", 820, 38, 2, 1)

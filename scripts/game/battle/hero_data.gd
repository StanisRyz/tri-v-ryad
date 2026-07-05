extends RefCounted
class_name HeroData

const ECONOMY_CONFIG := preload("res://scripts/game/progression/upgrade_economy_config.gd")

var id := ""
var display_name := ""
var lane_index := 0
var base_attack := 0
var base_max_hp := 0
var attack_level := 0
var hp_level := 0
var current_hp := 0
var ability_charge := 0
var ability_charge_required := 10
var ability_id := ""


func _init(
	hero_id: String = "",
	hero_display_name: String = "",
	hero_lane_index: int = 0,
	hero_base_attack: int = 0,
	hero_base_max_hp: int = 0,
	hero_attack_level: int = 0,
	hero_hp_level: int = 0,
	required_charge: int = 10,
	hero_ability_id: String = ""
) -> void:
	id = hero_id
	display_name = hero_display_name
	lane_index = hero_lane_index
	base_attack = hero_base_attack
	base_max_hp = hero_base_max_hp
	attack_level = hero_attack_level
	hp_level = hero_hp_level
	ability_charge_required = max(1, required_charge)
	ability_id = hero_ability_id
	heal_to_full()


func get_attack() -> int:
	return ECONOMY_CONFIG.get_attack_for_level(base_attack, attack_level)


func get_max_hp() -> int:
	return ECONOMY_CONFIG.get_max_hp_for_level(base_max_hp, hp_level)


func is_alive() -> bool:
	return current_hp > 0


func is_ability_ready() -> bool:
	return ability_charge >= ability_charge_required


func take_damage(amount: int) -> void:
	current_hp = clampi(current_hp - max(0, amount), 0, get_max_hp())


func heal_to_full() -> void:
	current_hp = get_max_hp()


func heal(amount: int) -> int:
	var previous_hp := current_hp
	current_hp = clampi(current_hp + max(0, amount), 0, get_max_hp())
	return current_hp - previous_hp


func add_ability_charge(amount: int) -> void:
	ability_charge = clampi(ability_charge + max(0, amount), 0, ability_charge_required)

extends RefCounted
class_name HeroConfig

const SCRIPT_PATH := "res://scripts/game/config/hero_config.gd"

var hero_id := ""
var display_name := ""
var lane_index := 0
var base_attack := 0
var base_max_hp := 0
var ability_charge_required := 10
var ability_id := ""


func _init(config_hero_id: String = "", config_display_name: String = "", config_lane_index: int = 0, config_base_attack: int = 0, config_base_max_hp: int = 0, config_ability_charge_required: int = 10, config_ability_id: String = "") -> void:
	hero_id = config_hero_id
	display_name = config_display_name
	lane_index = config_lane_index
	base_attack = config_base_attack
	base_max_hp = config_base_max_hp
	ability_charge_required = config_ability_charge_required
	ability_id = config_ability_id


func to_hero_data() -> HeroData:
	return HeroData.new(hero_id, display_name, lane_index, base_attack, base_max_hp, 0, 0, ability_charge_required, ability_id)


static func hero_1():
	return load(SCRIPT_PATH).new("hero_1", "Warrior", 0, 10, 100, 10, "warrior_strike")


static func hero_2():
	return load(SCRIPT_PATH).new("hero_2", "Guardian", 1, 8, 120, 10, "guardian_strike")


static func hero_3():
	return load(SCRIPT_PATH).new("hero_3", "Healer", 2, 12, 80, 10, "healer_strike")


static func get_default_party() -> Array:
	return [hero_1(), hero_2(), hero_3()]

extends RefCounted
class_name HeroConfig

const SCRIPT_PATH := "res://scripts/game/config/hero_config.gd"

var hero_id := ""
var display_name := ""
var lane_index := 0
var base_attack := 0
var base_max_hp := 0
var ability_charge_required := 10


func _init(config_hero_id: String = "", config_display_name: String = "", config_lane_index: int = 0, config_base_attack: int = 0, config_base_max_hp: int = 0, config_ability_charge_required: int = 10) -> void:
	hero_id = config_hero_id
	display_name = config_display_name
	lane_index = config_lane_index
	base_attack = config_base_attack
	base_max_hp = config_base_max_hp
	ability_charge_required = config_ability_charge_required


func to_hero_data() -> HeroData:
	return HeroData.new(hero_id, display_name, lane_index, base_attack, base_max_hp, 0, 0, ability_charge_required)


static func hero_1():
	return load(SCRIPT_PATH).new("hero_1", "Hero 1", 0, 10, 100, 10)


static func hero_2():
	return load(SCRIPT_PATH).new("hero_2", "Hero 2", 1, 8, 120, 10)


static func hero_3():
	return load(SCRIPT_PATH).new("hero_3", "Hero 3", 2, 12, 80, 10)


static func get_default_party() -> Array:
	return [hero_1(), hero_2(), hero_3()]

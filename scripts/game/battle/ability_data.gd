extends RefCounted
class_name AbilityData

const SCRIPT_PATH := "res://scripts/game/battle/ability_data.gd"
const WARRIOR_STRIKE := "warrior_strike"
const GUARDIAN_STRIKE := "guardian_strike"
const HEALER_STRIKE := "healer_strike"
const MAGE_STRIKE := "mage_strike"
const RANGER_STRIKE := "ranger_strike"

var id := ""
var display_name := ""
var description := ""
var hero_id := ""
var damage_multiplier := 0


func _init(ability_id: String = "", ability_display_name: String = "", ability_description: String = "", owner_hero_id: String = "", ability_damage_multiplier: int = 0) -> void:
	id = ability_id
	display_name = ability_display_name
	description = ability_description
	hero_id = owner_hero_id
	damage_multiplier = ability_damage_multiplier


static func warrior_strike(owner_hero_id: String = ""):
	return load(SCRIPT_PATH).new(WARRIOR_STRIKE, "Warrior Strike", "Deal hero attack x5 damage to the enemy.", owner_hero_id, 5)


static func guardian_strike(owner_hero_id: String = ""):
	return load(SCRIPT_PATH).new(GUARDIAN_STRIKE, "Guardian Strike", "Deal hero attack x4 damage to the enemy.", owner_hero_id, 4)


static func healer_strike(owner_hero_id: String = ""):
	return load(SCRIPT_PATH).new(HEALER_STRIKE, "Healer Strike", "Deal hero attack x3 damage to the enemy.", owner_hero_id, 3)


static func mage_strike(owner_hero_id: String = ""):
	return load(SCRIPT_PATH).new(MAGE_STRIKE, "Mage Strike", "Deal hero attack x6 damage to the enemy.", owner_hero_id, 6)


static func ranger_strike(owner_hero_id: String = ""):
	return load(SCRIPT_PATH).new(RANGER_STRIKE, "Ranger Strike", "Deal hero attack x4 damage to the enemy.", owner_hero_id, 4)


static func get_for_hero(owner_hero_id: String):
	match owner_hero_id:
		"hero_1":
			return warrior_strike(owner_hero_id)
		"hero_2":
			return guardian_strike(owner_hero_id)
		"hero_3":
			return healer_strike(owner_hero_id)
		"hero_4":
			return mage_strike(owner_hero_id)
		"hero_5":
			return ranger_strike(owner_hero_id)
		_:
			return load(SCRIPT_PATH).new()


static func get_for_ability(ability_id: String, owner_hero_id: String = ""):
	match ability_id:
		WARRIOR_STRIKE:
			return warrior_strike(owner_hero_id)
		GUARDIAN_STRIKE:
			return guardian_strike(owner_hero_id)
		HEALER_STRIKE:
			return healer_strike(owner_hero_id)
		MAGE_STRIKE:
			return mage_strike(owner_hero_id)
		RANGER_STRIKE:
			return ranger_strike(owner_hero_id)
		_:
			return load(SCRIPT_PATH).new()

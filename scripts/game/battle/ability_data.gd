extends RefCounted
class_name AbilityData

const SCRIPT_PATH := "res://scripts/game/battle/ability_data.gd"
const POWER_STRIKE := "power_strike"
const LINE_BREAK := "line_break"
const RALLY_HEAL := "rally_heal"

var id := ""
var display_name := ""
var description := ""
var hero_id := ""


func _init(ability_id: String = "", ability_display_name: String = "", ability_description: String = "", owner_hero_id: String = "") -> void:
	id = ability_id
	display_name = ability_display_name
	description = ability_description
	hero_id = owner_hero_id


static func power_strike(owner_hero_id: String = ""):
	return load(SCRIPT_PATH).new(POWER_STRIKE, "Power Strike", "Deal hero attack x5 damage to the enemy.", owner_hero_id)


static func line_break(owner_hero_id: String = ""):
	return load(SCRIPT_PATH).new(LINE_BREAK, "Line Break", "Clear the center row and stabilize the board.", owner_hero_id)


static func rally_heal(owner_hero_id: String = ""):
	return load(SCRIPT_PATH).new(RALLY_HEAL, "Rally Heal", "Heal all alive heroes by 30 HP.", owner_hero_id)


static func get_for_hero(owner_hero_id: String):
	match owner_hero_id:
		"hero_1":
			return power_strike(owner_hero_id)
		"hero_2":
			return line_break(owner_hero_id)
		"hero_3":
			return rally_heal(owner_hero_id)
		_:
			return load(SCRIPT_PATH).new()


static func get_for_ability(ability_id: String, owner_hero_id: String = ""):
	match ability_id:
		POWER_STRIKE:
			return power_strike(owner_hero_id)
		LINE_BREAK:
			return line_break(owner_hero_id)
		RALLY_HEAL:
			return rally_heal(owner_hero_id)
		_:
			return load(SCRIPT_PATH).new()

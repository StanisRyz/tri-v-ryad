extends RefCounted
class_name HeroUpgradeState

const SCRIPT_PATH := "res://scripts/game/progression/hero_upgrade_state.gd"

var hero_id := ""
var attack_level := 0
var hp_level := 0


func _init(upgrade_hero_id: String = "", upgrade_attack_level: int = 0, upgrade_hp_level: int = 0) -> void:
	hero_id = upgrade_hero_id
	attack_level = max(0, upgrade_attack_level)
	hp_level = max(0, upgrade_hp_level)


func to_dictionary() -> Dictionary:
	return {
		"hero_id": hero_id,
		"attack_level": attack_level,
		"hp_level": hp_level,
	}


static func from_dictionary(data: Dictionary, fallback_hero_id: String) -> HeroUpgradeState:
	var resolved_hero_id := str(data.get("hero_id", fallback_hero_id))
	if resolved_hero_id == "":
		resolved_hero_id = fallback_hero_id

	return load(SCRIPT_PATH).new(
		resolved_hero_id,
		int(data.get("attack_level", 0)),
		int(data.get("hp_level", 0))
	)

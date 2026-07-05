extends RefCounted
class_name UpgradeResolver

const ECONOMY_CONFIG := preload("res://scripts/game/progression/upgrade_economy_config.gd")

const STAT_ATTACK := "attack"
const STAT_HP := "hp"


func get_upgrade_cost(progress, hero_id: String, stat: String) -> int:
	if not _is_supported_stat(stat):
		return -1
	if hero_id == "":
		return -1
	if progress == null:
		return -1

	var hero_upgrade = _get_upgrade_state(progress, hero_id)
	if stat == STAT_ATTACK:
		return ECONOMY_CONFIG.get_attack_upgrade_cost(hero_upgrade.attack_level)
	return ECONOMY_CONFIG.get_hp_upgrade_cost(hero_upgrade.hp_level)


func can_upgrade(progress, hero_id: String, stat: String) -> bool:
	return bool(get_upgrade_result(progress, hero_id, stat)["accepted"])


func upgrade(progress, hero_id: String, stat: String) -> bool:
	return bool(upgrade_with_result(progress, hero_id, stat)["accepted"])


func upgrade_with_result(progress, hero_id: String, stat: String) -> Dictionary:
	var result := get_upgrade_result(progress, hero_id, stat)
	if not bool(result["accepted"]):
		return result

	var hero_upgrade = _get_upgrade_state(progress, hero_id)
	progress.upgrade_points -= int(result["cost"])
	if stat == STAT_ATTACK:
		hero_upgrade.attack_level += 1
		result["current_level"] = hero_upgrade.attack_level
	elif stat == STAT_HP:
		hero_upgrade.hp_level += 1
		result["current_level"] = hero_upgrade.hp_level

	return result


func get_upgrade_result(progress, hero_id: String, stat: String) -> Dictionary:
	var result := {
		"accepted": false,
		"reason": "",
		"cost": -1,
		"current_level": 0,
		"max_level": 0,
		"stat": stat,
		"hero_id": hero_id,
	}

	if progress == null:
		result["reason"] = "invalid_hero"
		return result
	if hero_id == "":
		result["reason"] = "invalid_hero"
		return result
	if not _is_supported_stat(stat):
		result["reason"] = "invalid_upgrade_type"
		return result

	var hero_upgrade = _get_upgrade_state(progress, hero_id)
	if stat == STAT_ATTACK:
		result["current_level"] = hero_upgrade.attack_level
		result["max_level"] = ECONOMY_CONFIG.MAX_ATTACK_LEVEL
		result["cost"] = ECONOMY_CONFIG.get_attack_upgrade_cost(hero_upgrade.attack_level)
	else:
		result["current_level"] = hero_upgrade.hp_level
		result["max_level"] = ECONOMY_CONFIG.MAX_HP_LEVEL
		result["cost"] = ECONOMY_CONFIG.get_hp_upgrade_cost(hero_upgrade.hp_level)

	if int(result["current_level"]) >= int(result["max_level"]):
		result["reason"] = "max_level"
		return result
	if progress.upgrade_points < int(result["cost"]):
		result["reason"] = "not_enough_points"
		return result

	result["accepted"] = true
	result["reason"] = "accepted"
	return result


func _is_supported_stat(stat: String) -> bool:
	return stat == STAT_ATTACK or stat == STAT_HP


func _get_upgrade_state(progress, hero_id: String):
	return progress.ensure_hero(hero_id)

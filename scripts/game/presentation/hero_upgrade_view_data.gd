extends RefCounted
class_name HeroUpgradeViewData

const ECONOMY_CONFIG := preload("res://scripts/game/progression/upgrade_economy_config.gd")

var hero_id := ""
var display_name := ""
var ability_id := ""
var attack_level := 0
var hp_level := 0
var current_attack := 0
var next_attack := 0
var current_max_hp := 0
var next_max_hp := 0
var attack_cost := -1
var hp_cost := -1
var max_attack_level := 0
var max_hp_level := 0
var attack_status := ""
var hp_status := ""
var can_upgrade_attack := false
var can_upgrade_hp := false


static func from_config(hero_config: HeroConfig, progress: PlayerProgress, progress_manager: ProgressManager) -> HeroUpgradeViewData:
	var data := HeroUpgradeViewData.new()
	if hero_config == null:
		return data

	data.hero_id = hero_config.hero_id
	data.display_name = hero_config.display_name
	data.ability_id = hero_config.ability_id

	var upgrade_state: HeroUpgradeState = null
	if progress_manager != null and progress_manager.has_method("get_hero_upgrade"):
		upgrade_state = progress_manager.get_hero_upgrade(hero_config.hero_id)
	elif progress != null:
		upgrade_state = progress.get_hero_upgrade(hero_config.hero_id)

	if upgrade_state != null:
		data.attack_level = upgrade_state.attack_level
		data.hp_level = upgrade_state.hp_level

	data.max_attack_level = ECONOMY_CONFIG.MAX_ATTACK_LEVEL
	data.max_hp_level = ECONOMY_CONFIG.MAX_HP_LEVEL
	data.current_attack = ECONOMY_CONFIG.get_attack_for_level(hero_config.base_attack, data.attack_level)
	data.next_attack = ECONOMY_CONFIG.get_attack_for_level(hero_config.base_attack, min(data.attack_level + 1, data.max_attack_level))
	data.current_max_hp = ECONOMY_CONFIG.get_max_hp_for_level(hero_config.base_max_hp, data.hp_level)
	data.next_max_hp = ECONOMY_CONFIG.get_max_hp_for_level(hero_config.base_max_hp, min(data.hp_level + 1, data.max_hp_level))
	data.attack_cost = ECONOMY_CONFIG.get_attack_upgrade_cost(data.attack_level)
	data.hp_cost = ECONOMY_CONFIG.get_hp_upgrade_cost(data.hp_level)
	data.attack_status = _get_status_text(data.attack_level, data.max_attack_level, data.attack_cost, progress)
	data.hp_status = _get_status_text(data.hp_level, data.max_hp_level, data.hp_cost, progress)

	if progress_manager != null:
		data.can_upgrade_attack = progress_manager.can_upgrade(hero_config.hero_id, "attack")
		data.can_upgrade_hp = progress_manager.can_upgrade(hero_config.hero_id, "hp")
		if progress_manager.has_method("get_upgrade_result"):
			var attack_result: Dictionary = progress_manager.get_upgrade_result(hero_config.hero_id, "attack")
			var hp_result: Dictionary = progress_manager.get_upgrade_result(hero_config.hero_id, "hp")
			data.attack_status = _get_status_from_result(attack_result)
			data.hp_status = _get_status_from_result(hp_result)

	return data


static func _get_status_text(current_level: int, max_level: int, cost: int, progress: PlayerProgress) -> String:
	if current_level >= max_level:
		return "Max level"
	if progress != null and progress.upgrade_points < cost:
		return "Not enough points"
	return "Cost: %d" % cost


static func _get_status_from_result(result: Dictionary) -> String:
	if str(result.get("reason", "")) == "max_level":
		return "Max level"
	if str(result.get("reason", "")) == "not_enough_points":
		return "Not enough points"
	return "Cost: %d" % int(result.get("cost", 0))

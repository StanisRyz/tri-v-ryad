extends RefCounted
class_name PlayerProgress

const SAVE_VERSION := 1
const SCRIPT_PATH := "res://scripts/game/progression/player_progress.gd"
const HERO_UPGRADE_STATE_SCRIPT := preload("res://scripts/game/progression/hero_upgrade_state.gd")
const DEFAULT_HERO_IDS := ["hero_1", "hero_2", "hero_3"]

var save_version := SAVE_VERSION
var upgrade_points := 0
var hero_upgrades: Dictionary = {}
var completed_levels: Dictionary = {}


static func create_default() -> PlayerProgress:
	var progress = load(SCRIPT_PATH).new()
	progress.save_version = SAVE_VERSION
	progress.upgrade_points = 0
	for hero_id in DEFAULT_HERO_IDS:
		progress.ensure_hero(hero_id)
	return progress


func get_hero_upgrade(hero_id: String) -> HeroUpgradeState:
	return ensure_hero(hero_id)


func ensure_hero(hero_id: String) -> HeroUpgradeState:
	if not hero_upgrades.has(hero_id) or hero_upgrades[hero_id] == null:
		hero_upgrades[hero_id] = HERO_UPGRADE_STATE_SCRIPT.new(hero_id)
	return hero_upgrades[hero_id]


func add_upgrade_points(amount: int) -> void:
	upgrade_points = max(0, upgrade_points + max(0, amount))


func mark_level_completed(level_id: String) -> void:
	if level_id == "":
		return
	completed_levels[level_id] = true


func is_level_completed(level_id: String) -> bool:
	return bool(completed_levels.get(level_id, false))


func to_dictionary() -> Dictionary:
	var upgrade_data := {}
	for hero_id in hero_upgrades.keys():
		var upgrade = hero_upgrades[hero_id]
		if upgrade != null and upgrade.has_method("to_dictionary"):
			upgrade_data[hero_id] = upgrade.to_dictionary()

	return {
		"save_version": save_version,
		"upgrade_points": upgrade_points,
		"hero_upgrades": upgrade_data,
		"completed_levels": completed_levels.duplicate(),
	}


static func from_dictionary(data: Dictionary) -> PlayerProgress:
	var progress = create_default()
	progress.save_version = int(data.get("save_version", SAVE_VERSION))
	progress.upgrade_points = max(0, int(data.get("upgrade_points", 0)))

	var raw_upgrades = data.get("hero_upgrades", {})
	if raw_upgrades is Dictionary:
		for hero_id in raw_upgrades.keys():
			var raw_upgrade = raw_upgrades[hero_id]
			if raw_upgrade is Dictionary:
				progress.hero_upgrades[str(hero_id)] = HERO_UPGRADE_STATE_SCRIPT.from_dictionary(raw_upgrade, str(hero_id))

	for hero_id in DEFAULT_HERO_IDS:
		progress.ensure_hero(hero_id)

	var raw_completed = data.get("completed_levels", {})
	progress.completed_levels = {}
	if raw_completed is Dictionary:
		for level_id in raw_completed.keys():
			progress.completed_levels[str(level_id)] = bool(raw_completed[level_id])

	return progress

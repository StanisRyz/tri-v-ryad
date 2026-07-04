extends RefCounted
class_name PlayerProgress

const SAVE_VERSION := 1
const SCRIPT_PATH := "res://scripts/game/progression/player_progress.gd"
const HERO_UPGRADE_STATE_SCRIPT := preload("res://scripts/game/progression/hero_upgrade_state.gd")
const LEVEL_PROGRESS_STATE_SCRIPT := preload("res://scripts/game/progression/level_progress_state.gd")
const TEAM_SELECTION_STATE_SCRIPT := preload("res://scripts/game/progression/team_selection_state.gd")
const DEFAULT_HERO_IDS := ["hero_1", "hero_2", "hero_3"]

var save_version := SAVE_VERSION
var upgrade_points := 0
var hero_upgrades: Dictionary = {}
var completed_levels: Dictionary = {}
var level_progress: Dictionary = {}
var team_selection: TeamSelectionState


static func create_default() -> PlayerProgress:
	var progress = load(SCRIPT_PATH).new()
	progress.save_version = SAVE_VERSION
	progress.upgrade_points = 0
	progress.team_selection = TEAM_SELECTION_STATE_SCRIPT.create_default(DEFAULT_HERO_IDS)
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
	var state = ensure_level_progress(level_id)
	state.completed = true
	state.stars = max(state.stars, 1)
	set_level_progress(level_id, state)


func is_level_completed(level_id: String) -> bool:
	if level_progress.has(level_id):
		var state = level_progress[level_id]
		return state != null and bool(state.completed)
	return bool(completed_levels.get(level_id, false))


func get_level_progress(level_id: String):
	return ensure_level_progress(level_id)


func ensure_level_progress(level_id: String):
	if not level_progress.has(level_id) or level_progress[level_id] == null:
		level_progress[level_id] = LEVEL_PROGRESS_STATE_SCRIPT.new(level_id)
	return level_progress[level_id]


func set_level_progress(level_id: String, state) -> void:
	if level_id == "" or state == null:
		return
	level_progress[level_id] = state
	completed_levels[level_id] = bool(state.completed)


func get_team_selection() -> TeamSelectionState:
	if team_selection == null:
		team_selection = TEAM_SELECTION_STATE_SCRIPT.create_default(DEFAULT_HERO_IDS)
	return team_selection


func set_team_selection(team_state: TeamSelectionState) -> void:
	if team_state == null:
		return
	team_selection = team_state


func get_selected_team_ids() -> Array[String]:
	return get_team_selection().selected_hero_ids.duplicate()


func get_level_stars(level_id: String) -> int:
	if level_progress.has(level_id):
		var state = level_progress[level_id]
		if state != null:
			return int(state.stars)
	return 1 if bool(completed_levels.get(level_id, false)) else 0


func to_dictionary() -> Dictionary:
	var upgrade_data := {}
	for hero_id in hero_upgrades.keys():
		var upgrade = hero_upgrades[hero_id]
		if upgrade != null and upgrade.has_method("to_dictionary"):
			upgrade_data[hero_id] = upgrade.to_dictionary()

	var level_progress_data := {}
	for level_id in level_progress.keys():
		var state = level_progress[level_id]
		if state != null and state.has_method("to_dictionary"):
			level_progress_data[level_id] = state.to_dictionary()

	return {
		"save_version": save_version,
		"upgrade_points": upgrade_points,
		"hero_upgrades": upgrade_data,
		"completed_levels": completed_levels.duplicate(),
		"level_progress": level_progress_data,
		"team_selection": get_team_selection().to_dictionary(),
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

	progress.level_progress = {}
	var raw_level_progress = data.get("level_progress", {})
	if raw_level_progress is Dictionary:
		for level_id in raw_level_progress.keys():
			var raw_state = raw_level_progress[level_id]
			if raw_state is Dictionary:
				progress.level_progress[str(level_id)] = LEVEL_PROGRESS_STATE_SCRIPT.from_dictionary(raw_state, str(level_id))

	for level_id in progress.completed_levels.keys():
		if bool(progress.completed_levels[level_id]) and not progress.level_progress.has(level_id):
			progress.level_progress[level_id] = LEVEL_PROGRESS_STATE_SCRIPT.new(level_id, true, 1, 0)

	var raw_team_selection = data.get("team_selection", {})
	if raw_team_selection is Dictionary:
		progress.team_selection = TEAM_SELECTION_STATE_SCRIPT.from_dictionary(raw_team_selection, DEFAULT_HERO_IDS)
	else:
		progress.team_selection = TEAM_SELECTION_STATE_SCRIPT.create_default(DEFAULT_HERO_IDS)

	return progress

extends RefCounted
class_name TeamSelectionState

const SCRIPT_PATH := "res://scripts/game/progression/team_selection_state.gd"

var selected_hero_ids: Array[String] = []


func _init(hero_ids: Array = []) -> void:
	selected_hero_ids = []
	for hero_id in hero_ids:
		selected_hero_ids.append(str(hero_id))


static func create_default(default_team_ids: Array) -> TeamSelectionState:
	return load(SCRIPT_PATH).new(default_team_ids)


func is_complete() -> bool:
	return selected_hero_ids.size() == 3


func has_duplicates() -> bool:
	var seen := {}
	for hero_id in selected_hero_ids:
		if seen.has(hero_id):
			return true
		seen[hero_id] = true
	return false


func to_dictionary() -> Dictionary:
	return {
		"selected_hero_ids": selected_hero_ids.duplicate(),
	}


static func from_dictionary(data: Dictionary, default_team_ids: Array) -> TeamSelectionState:
	if not data.has("selected_hero_ids") or not data["selected_hero_ids"] is Array:
		return create_default(default_team_ids)

	var hero_ids: Array[String] = []
	for hero_id in data["selected_hero_ids"]:
		hero_ids.append(str(hero_id))
	return load(SCRIPT_PATH).new(hero_ids)

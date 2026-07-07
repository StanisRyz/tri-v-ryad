extends RefCounted
class_name LevelBoostDatabase

## Stage 60.3 v0.1: loads data/levels/deterministic_level_boosts.json and
## exposes deterministic LevelBoostConfig entries by level_number.
## LevelBoostResolver uses this so every level 1-500 gets a fixed, reproducible
## boost instead of Stage 60.2's always-"none" placeholder; a missing/invalid
## database or a missing/invalid individual entry simply leaves that level
## without a stored boost, and callers (LevelBoostResolver) fall back to
## LevelBoostConfig.none() - this loader never blocks battle startup.

const LEVEL_BOOST_CONFIG_SCRIPT := preload("res://scripts/game/config/level_boost_config.gd")
const DEFAULT_DATABASE_PATH := "res://data/levels/deterministic_level_boosts.json"

var version := ""
var generator_version := ""
var level_count := 0

var _boosts_by_level: Dictionary = {}
var _loaded := false
var _load_error := ""


func _init(database_path: String = DEFAULT_DATABASE_PATH) -> void:
	_load(database_path)


func is_loaded() -> bool:
	return _loaded


func get_load_error() -> String:
	return _load_error


func has_boost(level_number: int) -> bool:
	return _boosts_by_level.has(level_number)


func get_boost(level_number: int) -> LevelBoostConfig:
	if has_boost(level_number):
		return _boosts_by_level[level_number]

	return LEVEL_BOOST_CONFIG_SCRIPT.none()


func get_boost_count() -> int:
	return _boosts_by_level.size()


func get_all_level_numbers() -> Array[int]:
	var numbers: Array[int] = []
	for level_number in _boosts_by_level.keys():
		numbers.append(level_number)
	numbers.sort()
	return numbers


func _load(database_path: String) -> void:
	if not FileAccess.file_exists(database_path):
		_load_error = "database_file_not_found"
		return

	var file := FileAccess.open(database_path, FileAccess.READ)
	if file == null:
		_load_error = "database_file_unreadable"
		return

	var text := file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(text)
	if not (parsed is Dictionary):
		_load_error = "database_invalid_json"
		return

	var data: Dictionary = parsed
	version = String(data.get("version", ""))
	generator_version = String(data.get("generator_version", ""))
	level_count = int(data.get("level_count", 0))

	var levels_data = data.get("levels", [])
	if not (levels_data is Array):
		_load_error = "database_missing_levels"
		return

	for entry in levels_data:
		if not (entry is Dictionary):
			continue

		var level_number := int(entry.get("level_number", 0))
		if level_number <= 0:
			continue

		var boost_data = entry.get("boost", {})
		if not (boost_data is Dictionary):
			continue

		var boost: LevelBoostConfig = LEVEL_BOOST_CONFIG_SCRIPT.from_dict(boost_data)
		if not boost.is_valid():
			continue

		_boosts_by_level[level_number] = boost

	if _boosts_by_level.is_empty():
		_load_error = "database_empty"
		return

	_loaded = true

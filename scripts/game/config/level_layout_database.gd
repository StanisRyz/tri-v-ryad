extends RefCounted
class_name LevelLayoutDatabase

## Stage 58 v0.1: loads data/levels/deterministic_level_layouts.json and
## exposes deterministic LevelLayout entries by level_number.
## BoardChallengeGenerator uses this so a level with a saved deterministic
## layout no longer needs procedural generation every playthrough; a missing
## or invalid database simply leaves has_layout() false everywhere and every
## level falls back to procedural generation, so this loader never blocks
## gameplay.

const LEVEL_LAYOUT_SCRIPT := preload("res://scripts/game/config/level_layout.gd")
const DEFAULT_DATABASE_PATH := "res://data/levels/deterministic_level_layouts.json"

var version := ""
var board_size := 9
var generator_version := ""

var _layouts_by_level: Dictionary = {}
var _loaded := false
var _load_error := ""


func _init(database_path: String = DEFAULT_DATABASE_PATH) -> void:
	_load(database_path)


func is_loaded() -> bool:
	return _loaded


func get_load_error() -> String:
	return _load_error


func has_layout(level_number: int) -> bool:
	return _layouts_by_level.has(level_number)


func get_layout(level_number: int) -> LevelLayout:
	return _layouts_by_level.get(level_number)


func get_layout_count() -> int:
	return _layouts_by_level.size()


func get_all_level_numbers() -> Array[int]:
	var numbers: Array[int] = []
	for level_number in _layouts_by_level.keys():
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
	board_size = int(data.get("board_size", 9))
	generator_version = String(data.get("generator_version", ""))

	var levels_data = data.get("levels", [])
	if not (levels_data is Array):
		_load_error = "database_missing_levels"
		return

	for entry in levels_data:
		if not (entry is Dictionary):
			continue
		var layout: LevelLayout = LEVEL_LAYOUT_SCRIPT.from_dict(entry)
		if layout.level_number <= 0:
			continue
		_layouts_by_level[layout.level_number] = layout

	if _layouts_by_level.is_empty():
		_load_error = "database_empty"
		return

	_loaded = true

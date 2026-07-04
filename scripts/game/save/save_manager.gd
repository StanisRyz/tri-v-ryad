extends RefCounted
class_name SaveManager

const PLAYER_PROGRESS_SCRIPT := preload("res://scripts/game/progression/player_progress.gd")
const DEFAULT_SAVE_PATH := "user://save_v1.json"
const DEFAULT_TEMP_SAVE_PATH := "user://save_v1.tmp"

var save_path := DEFAULT_SAVE_PATH
var temp_save_path := DEFAULT_TEMP_SAVE_PATH


func _init(progress_save_path: String = DEFAULT_SAVE_PATH, progress_temp_save_path: String = DEFAULT_TEMP_SAVE_PATH) -> void:
	save_path = progress_save_path
	temp_save_path = progress_temp_save_path


func load_progress():
	if not FileAccess.file_exists(save_path):
		return PLAYER_PROGRESS_SCRIPT.create_default()

	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		return PLAYER_PROGRESS_SCRIPT.create_default()

	var json_text := file.get_as_text()
	var parser := JSON.new()
	if parser.parse(json_text) != OK:
		return PLAYER_PROGRESS_SCRIPT.create_default()

	var parsed = parser.data
	if not parsed is Dictionary:
		return PLAYER_PROGRESS_SCRIPT.create_default()

	return PLAYER_PROGRESS_SCRIPT.from_dictionary(parsed)


func save_progress(progress) -> bool:
	if progress == null:
		return false

	var file := FileAccess.open(temp_save_path, FileAccess.WRITE)
	if file == null:
		return false

	file.store_string(JSON.stringify(progress.to_dictionary(), "\t"))
	file.flush()
	file.close()

	if FileAccess.file_exists(save_path):
		var remove_error := DirAccess.remove_absolute(save_path)
		if remove_error != OK:
			return false

	var rename_error := DirAccess.rename_absolute(temp_save_path, save_path)
	if rename_error != OK:
		return false

	return true


func reset_progress():
	var progress = PLAYER_PROGRESS_SCRIPT.create_default()
	save_progress(progress)
	return progress

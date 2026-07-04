extends RefCounted
class_name SettingsManager

const PLAYER_SETTINGS_SCRIPT := preload("res://scripts/game/settings/player_settings.gd")
const DEFAULT_SETTINGS_PATH := "user://settings_v1.json"
const DEFAULT_TEMP_SETTINGS_PATH := "user://settings_v1.tmp"
const MUSIC_BUS_NAME := "Music"
const SFX_BUS_NAME := "SFX"

var settings_path := DEFAULT_SETTINGS_PATH
var temp_settings_path := DEFAULT_TEMP_SETTINGS_PATH
var settings: PlayerSettings


func _init(manager_settings_path: String = DEFAULT_SETTINGS_PATH, manager_temp_settings_path: String = DEFAULT_TEMP_SETTINGS_PATH) -> void:
	settings_path = manager_settings_path
	temp_settings_path = manager_temp_settings_path
	settings = PLAYER_SETTINGS_SCRIPT.create_default()


func load() -> void:
	settings = _load_from_disk()
	_apply_audio_bus_state()


func save() -> bool:
	if settings == null:
		return false

	var file := FileAccess.open(temp_settings_path, FileAccess.WRITE)
	if file == null:
		return false

	file.store_string(JSON.stringify(settings.to_dictionary(), "\t"))
	file.flush()
	file.close()

	if FileAccess.file_exists(settings_path):
		var remove_error := DirAccess.remove_absolute(settings_path)
		if remove_error != OK:
			return false

	var rename_error := DirAccess.rename_absolute(temp_settings_path, settings_path)
	if rename_error != OK:
		return false

	return true


func get_settings() -> PlayerSettings:
	return settings


func set_animations_enabled(value: bool) -> void:
	settings.animations_enabled = value
	save()


func set_reduced_motion_enabled(value: bool) -> void:
	settings.reduced_motion_enabled = value
	save()


func set_debug_labels_enabled(value: bool) -> void:
	settings.debug_labels_enabled = value
	save()


func set_music_enabled(value: bool) -> void:
	settings.music_enabled = value
	_apply_music_bus_state()
	save()


func set_sound_effects_enabled(value: bool) -> void:
	settings.sound_effects_enabled = value
	_apply_sfx_bus_state()
	save()


func reset_settings_to_defaults() -> void:
	settings = PLAYER_SETTINGS_SCRIPT.create_default()
	_apply_audio_bus_state()
	save()


func _load_from_disk() -> PlayerSettings:
	if not FileAccess.file_exists(settings_path):
		return PLAYER_SETTINGS_SCRIPT.create_default()

	var file := FileAccess.open(settings_path, FileAccess.READ)
	if file == null:
		return PLAYER_SETTINGS_SCRIPT.create_default()

	var json_text := file.get_as_text()
	var parser := JSON.new()
	if parser.parse(json_text) != OK:
		return PLAYER_SETTINGS_SCRIPT.create_default()

	var parsed = parser.data
	if not parsed is Dictionary:
		return PLAYER_SETTINGS_SCRIPT.create_default()

	return PLAYER_SETTINGS_SCRIPT.from_dictionary(parsed)


func _apply_audio_bus_state() -> void:
	_apply_music_bus_state()
	_apply_sfx_bus_state()


func _apply_music_bus_state() -> void:
	_set_bus_mute(MUSIC_BUS_NAME, not settings.music_enabled)


func _apply_sfx_bus_state() -> void:
	_set_bus_mute(SFX_BUS_NAME, not settings.sound_effects_enabled)


func _set_bus_mute(bus_name: String, muted: bool) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		return
	AudioServer.set_bus_mute(bus_index, muted)

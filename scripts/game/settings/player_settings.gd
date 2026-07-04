extends RefCounted
class_name PlayerSettings

const SETTINGS_VERSION := 1

var save_version := SETTINGS_VERSION
var animations_enabled := true
var reduced_motion_enabled := false
var debug_labels_enabled := false
var music_enabled := true
var sound_effects_enabled := true


static func create_default() -> PlayerSettings:
	var settings := PlayerSettings.new()
	settings.save_version = SETTINGS_VERSION
	settings.animations_enabled = true
	settings.reduced_motion_enabled = false
	settings.debug_labels_enabled = false
	settings.music_enabled = true
	settings.sound_effects_enabled = true
	return settings


func to_dictionary() -> Dictionary:
	return {
		"save_version": save_version,
		"animations_enabled": animations_enabled,
		"reduced_motion_enabled": reduced_motion_enabled,
		"debug_labels_enabled": debug_labels_enabled,
		"music_enabled": music_enabled,
		"sound_effects_enabled": sound_effects_enabled,
	}


static func from_dictionary(data: Dictionary) -> PlayerSettings:
	var settings := create_default()
	settings.save_version = int(data.get("save_version", SETTINGS_VERSION))
	settings.animations_enabled = bool(data.get("animations_enabled", true))
	settings.reduced_motion_enabled = bool(data.get("reduced_motion_enabled", false))
	settings.debug_labels_enabled = bool(data.get("debug_labels_enabled", false))
	settings.music_enabled = bool(data.get("music_enabled", true))
	settings.sound_effects_enabled = bool(data.get("sound_effects_enabled", true))
	return settings

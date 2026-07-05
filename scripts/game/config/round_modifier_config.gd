extends RefCounted
class_name RoundModifierConfig

## Stage 33 v0.1: a single per-battle color damage modifier. Positive buffs only.

const DEFAULT_MULTIPLIER := 1.0

var modifier_id := ""
var display_name := ""
var description := ""
var color_multipliers: Dictionary = {}


func _init(config_modifier_id: String = "", config_display_name: String = "", config_description: String = "", config_color_multipliers: Dictionary = {}) -> void:
	modifier_id = config_modifier_id
	display_name = config_display_name
	description = config_description
	color_multipliers = config_color_multipliers.duplicate()


func get_multiplier(tile_type: int) -> float:
	if color_multipliers.has(tile_type):
		return float(color_multipliers[tile_type])

	return DEFAULT_MULTIPLIER


func is_valid() -> bool:
	if modifier_id == "":
		return false
	if display_name == "":
		return false
	if description == "":
		return false

	for tile_type in color_multipliers.keys():
		var multiplier = color_multipliers[tile_type]
		if not (multiplier is float or multiplier is int):
			return false
		if float(multiplier) <= 0.0:
			return false

	return true

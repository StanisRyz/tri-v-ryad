extends RefCounted
class_name LevelBoostConfig

## Stage 60.2 v0.1: a single deterministic level boost. Pure data - all boost
## rule logic lives in LevelBoostResolver so this stays a plain, JSON-friendly
## record (Stage 60.3 will load 500 of these from a level boost database).

const SCRIPT_PATH := "res://scripts/game/config/level_boost_config.gd"

var boost_id := ""
var boost_type := LevelBoostType.NONE
var display_name := ""
var description := ""
var tile_type := -1
var color_multiplier := 1.0
var match_4_multiplier := 1.0
var match_5_multiplier := 1.0
var extra_moves := 0


func _init(
	config_boost_id: String = "none",
	config_boost_type: int = LevelBoostType.NONE,
	config_display_name: String = "No Boost",
	config_description: String = "No level boost is active.",
	config_tile_type: int = -1,
	config_color_multiplier: float = 1.0,
	config_match_4_multiplier: float = 1.0,
	config_match_5_multiplier: float = 1.0,
	config_extra_moves: int = 0
) -> void:
	boost_id = config_boost_id
	boost_type = config_boost_type
	display_name = config_display_name
	description = config_description
	tile_type = config_tile_type
	color_multiplier = config_color_multiplier
	match_4_multiplier = config_match_4_multiplier
	match_5_multiplier = config_match_5_multiplier
	extra_moves = config_extra_moves


func is_none() -> bool:
	return boost_type == LevelBoostType.NONE


func is_valid() -> bool:
	if boost_id == "":
		return false
	if not LevelBoostType.is_valid_type(boost_type):
		return false

	match boost_type:
		LevelBoostType.COLOR_DAMAGE_MULTIPLIER:
			return TileType.is_valid_tile_type(tile_type) and color_multiplier > 0.0
		LevelBoostType.LARGE_MATCH_MULTIPLIER:
			return match_4_multiplier > 0.0 and match_5_multiplier > 0.0
		LevelBoostType.EXTRA_MOVES:
			return extra_moves > 0
		_:
			return true


static func none() -> LevelBoostConfig:
	return load(SCRIPT_PATH).new("none", LevelBoostType.NONE, "No Boost", "No level boost is active.")


static func color_damage(tile_type_value: int, multiplier: float = 2.0) -> LevelBoostConfig:
	var boost_id := "color_damage_%d" % tile_type_value
	return load(SCRIPT_PATH).new(
		boost_id,
		LevelBoostType.COLOR_DAMAGE_MULTIPLIER,
		"Color Boost",
		"Selected tile color deals bonus damage.",
		tile_type_value,
		multiplier
	)


static func large_match(match_4_multiplier_value: float = 2.0, match_5_multiplier_value: float = 3.0) -> LevelBoostConfig:
	return load(SCRIPT_PATH).new(
		"large_match",
		LevelBoostType.LARGE_MATCH_MULTIPLIER,
		"Large Match Boost",
		"Match 4 deals bonus damage; match 5+ deals even more.",
		-1,
		1.0,
		match_4_multiplier_value,
		match_5_multiplier_value
	)


static func extra_moves_boost(bonus_moves: int = 3) -> LevelBoostConfig:
	return load(SCRIPT_PATH).new(
		"extra_moves",
		LevelBoostType.EXTRA_MOVES,
		"Extra Moves Boost",
		"Grants additional moves for this level.",
		-1,
		1.0,
		1.0,
		1.0,
		bonus_moves
	)

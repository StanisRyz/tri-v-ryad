extends RefCounted
class_name LevelBoostConfig

## Stage 60.2 v0.1: a single deterministic level boost. Pure data - all boost
## rule logic lives in LevelBoostResolver so this stays a plain, JSON-friendly
## record.
## Stage 60.3 v0.1: from_dict()/to_dict() (plus the boost_type/tile_type
## string helpers) are the JSON <-> LevelBoostConfig bridge used by
## LevelBoostDatabase to load data/levels/deterministic_level_boosts.json.

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
	var generated_boost_id := "color_damage_%d" % tile_type_value
	return load(SCRIPT_PATH).new(
		generated_boost_id,
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


## Parses a JSON-friendly Dictionary (data/levels/deterministic_level_boosts.json
## entry's "boost" object) into a LevelBoostConfig. Unknown/missing fields fall
## back to safe "none" defaults; callers should still check is_valid() before
## trusting the result (LevelBoostDatabase does this).
static func from_dict(data: Dictionary) -> LevelBoostConfig:
	var parsed_boost_type := boost_type_from_string(String(data.get("boost_type", "none")))
	var parsed_tile_type := tile_type_from_string(String(data.get("tile_type", "")))

	return load(SCRIPT_PATH).new(
		String(data.get("boost_id", "none")),
		parsed_boost_type,
		String(data.get("display_name", "No Boost")),
		String(data.get("description", "No level boost is active.")),
		parsed_tile_type,
		float(data.get("color_multiplier", 1.0)),
		float(data.get("match_4_multiplier", 1.0)),
		float(data.get("match_5_multiplier", 1.0)),
		int(data.get("extra_moves", 0))
	)


## Compact serialization - only writes the fields relevant to boost_type, so
## the database stays readable (a large_match entry never carries an unused
## tile_type/color_multiplier, etc).
func to_dict() -> Dictionary:
	var data := {
		"boost_id": boost_id,
		"boost_type": boost_type_to_string(boost_type),
		"display_name": display_name,
		"description": description,
	}

	match boost_type:
		LevelBoostType.COLOR_DAMAGE_MULTIPLIER:
			data["tile_type"] = tile_type_to_string(tile_type)
			data["color_multiplier"] = color_multiplier
		LevelBoostType.LARGE_MATCH_MULTIPLIER:
			data["match_4_multiplier"] = match_4_multiplier
			data["match_5_multiplier"] = match_5_multiplier
		LevelBoostType.EXTRA_MOVES:
			data["extra_moves"] = extra_moves

	return data


static func boost_type_from_string(value: String) -> int:
	match value:
		"color_damage_multiplier":
			return LevelBoostType.COLOR_DAMAGE_MULTIPLIER
		"large_match_multiplier":
			return LevelBoostType.LARGE_MATCH_MULTIPLIER
		"extra_moves":
			return LevelBoostType.EXTRA_MOVES
		_:
			return LevelBoostType.NONE


static func boost_type_to_string(value: int) -> String:
	match value:
		LevelBoostType.COLOR_DAMAGE_MULTIPLIER:
			return "color_damage_multiplier"
		LevelBoostType.LARGE_MATCH_MULTIPLIER:
			return "large_match_multiplier"
		LevelBoostType.EXTRA_MOVES:
			return "extra_moves"
		_:
			return "none"


static func tile_type_from_string(value: String) -> int:
	match value:
		"red":
			return TileType.RED
		"blue":
			return TileType.BLUE
		"green":
			return TileType.GREEN
		"yellow":
			return TileType.YELLOW
		"purple":
			return TileType.PURPLE
		_:
			return -1


static func tile_type_to_string(value: int) -> String:
	match value:
		TileType.RED:
			return "red"
		TileType.BLUE:
			return "blue"
		TileType.GREEN:
			return "green"
		TileType.YELLOW:
			return "yellow"
		TileType.PURPLE:
			return "purple"
		_:
			return ""

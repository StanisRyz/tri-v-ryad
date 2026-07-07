extends RefCounted
class_name LevelBoostFormatter

## Stage 60.2 v0.1: debug/status/UI label formatting for level boosts. Kept
## separate from LevelBoostConfig/LevelBoostResolver so display strings can
## change without touching boost rule data or logic.


static func format_label(boost) -> String:
	if boost == null or boost.is_none():
		return "No Boost"

	match boost.boost_type:
		LevelBoostType.COLOR_DAMAGE_MULTIPLIER:
			return "%s x%s" % [_tile_color_name(boost.tile_type), _format_multiplier(boost.color_multiplier)]
		LevelBoostType.LARGE_MATCH_MULTIPLIER:
			return "Match 4 x%s / Match 5+ x%s" % [_format_multiplier(boost.match_4_multiplier), _format_multiplier(boost.match_5_multiplier)]
		LevelBoostType.EXTRA_MOVES:
			return "+%d Moves" % boost.extra_moves
		_:
			return "No Boost"


static func format_debug_label(boost) -> String:
	if boost == null:
		return "boost: none"

	return "boost_id: %s, boost_type: %s, label: %s" % [boost.boost_id, LevelBoostType.get_type_name(boost.boost_type), format_label(boost)]


## Stage 60.3 v0.1: formats the raw debug_info Dictionary BattlePresenter's
## get_current_level_boost_debug_info() builds (boost_source, boost_id,
## boost_type, boost_label, boost_database_loaded, boost_fallback_used,
## boost_load_error) into a single compact status-line string. Makes it easy
## to confirm which boost a given level actually resolved to (database vs.
## fallback) straight from the Debug Labels status line.
static func format_debug_info_label(debug_info: Dictionary) -> String:
	var label := "boost_source: %s, boost_id: %s, boost_type: %s, label: %s, db_loaded: %s, fallback: %s" % [
		String(debug_info.get("boost_source", "")),
		String(debug_info.get("boost_id", "")),
		LevelBoostType.get_type_name(int(debug_info.get("boost_type", LevelBoostType.NONE))),
		String(debug_info.get("boost_label", "")),
		bool(debug_info.get("boost_database_loaded", false)),
		bool(debug_info.get("boost_fallback_used", false)),
	]

	var load_error := String(debug_info.get("boost_load_error", ""))
	if load_error != "":
		label += ", load_error: %s" % load_error

	return label


static func _format_multiplier(multiplier: float) -> String:
	if is_equal_approx(multiplier, roundf(multiplier)):
		return str(int(round(multiplier)))
	return str(multiplier)


static func _tile_color_name(tile_type: int) -> String:
	match tile_type:
		TileType.RED:
			return "Red"
		TileType.BLUE:
			return "Blue"
		TileType.GREEN:
			return "Green"
		TileType.YELLOW:
			return "Yellow"
		TileType.PURPLE:
			return "Purple"
		_:
			return "Color"

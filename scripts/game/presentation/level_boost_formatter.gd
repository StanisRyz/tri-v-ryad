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

extends RefCounted
class_name LevelBoostResolver

## Stage 60.2 v0.1: resolves the deterministic level boost for a level and
## applies its rules to moves/damage. get_boost_for_level() always returns
## "none" in this stage - Stage 60.3 will replace it with a lookup into a
## deterministic 500-level boost database, without changing this contract.

const LEVEL_BOOST_CONFIG_SCRIPT := preload("res://scripts/game/config/level_boost_config.gd")


func get_boost_for_level(level_number: int) -> LevelBoostConfig:
	return LEVEL_BOOST_CONFIG_SCRIPT.none()


func apply_moves_bonus(base_moves: int, boost) -> int:
	if boost == null or boost.is_none():
		return base_moves

	if boost.boost_type == LevelBoostType.EXTRA_MOVES:
		return base_moves + boost.extra_moves

	return base_moves


## Returns the damage multiplier for a cleared tile of tile_type belonging to
## a match of match_size (match_size defaults to 1 for cells with no owning
## match, e.g. booster clears). Returns x1 when boost is none/null or the
## boost's rule does not match the given tile_type/match_size.
func get_damage_multiplier_for_tile(tile_type: int, match_size: int, boost) -> float:
	if boost == null or boost.is_none():
		return 1.0

	match boost.boost_type:
		LevelBoostType.COLOR_DAMAGE_MULTIPLIER:
			if tile_type == boost.tile_type:
				return boost.color_multiplier
			return 1.0
		LevelBoostType.LARGE_MATCH_MULTIPLIER:
			if match_size >= 5:
				return boost.match_5_multiplier
			if match_size == 4:
				return boost.match_4_multiplier
			return 1.0
		_:
			return 1.0

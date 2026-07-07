extends RefCounted
class_name LevelBoostType

## Stage 60.2 v0.1: typed boost categories for the deterministic level boost
## system. Stage 60.3 will assign one of these per level via a 500-level
## boost database; Stage 60.2 only wires the architecture and defaults every
## level to NONE.

const NONE := 0
const COLOR_DAMAGE_MULTIPLIER := 1
const LARGE_MATCH_MULTIPLIER := 2
const EXTRA_MOVES := 3


static func get_all_types() -> Array[int]:
	return [NONE, COLOR_DAMAGE_MULTIPLIER, LARGE_MATCH_MULTIPLIER, EXTRA_MOVES]


static func is_valid_type(value: int) -> bool:
	return value in get_all_types()


static func get_type_name(boost_type: int) -> String:
	match boost_type:
		NONE:
			return "None"
		COLOR_DAMAGE_MULTIPLIER:
			return "Color Damage Multiplier"
		LARGE_MATCH_MULTIPLIER:
			return "Large Match Multiplier"
		EXTRA_MOVES:
			return "Extra Moves"
		_:
			return "Unknown"

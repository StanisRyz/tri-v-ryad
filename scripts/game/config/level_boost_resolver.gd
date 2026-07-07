extends RefCounted
class_name LevelBoostResolver

## Stage 60.2 v0.1: resolves the deterministic level boost for a level and
## applies its rules to moves/damage.
## Stage 60.3 v0.1: get_boost_for_level() now queries LevelBoostDatabase
## (data/levels/deterministic_level_boosts.json) instead of always returning
## "none". The public contract from Stage 60.2 is unchanged - same method
## name/signature/return type - so BattlePresenter needed no rewrite. A
## missing/invalid database, or a level with no stored boost, safely falls
## back to LevelBoostConfig.none() (never crashes, never blocks battle start).
## The database itself is lazily loaded on first use so a LevelBoostResolver
## instance that only ever calls apply_moves_bonus()/get_damage_multiplier_for_tile()
## (e.g. the one DirectMatchDamageResolver owns internally) never touches disk.

const LEVEL_BOOST_CONFIG_SCRIPT := preload("res://scripts/game/config/level_boost_config.gd")
const LEVEL_BOOST_DATABASE_SCRIPT := preload("res://scripts/game/config/level_boost_database.gd")

var _database
var _database_load_attempted := false


func _init(database = null) -> void:
	if database != null:
		_database = database
		_database_load_attempted = true


func get_boost_for_level(level_number: int) -> LevelBoostConfig:
	_ensure_database_loaded()

	if _database != null and _database.is_loaded() and _database.has_boost(level_number):
		var boost: LevelBoostConfig = _database.get_boost(level_number)
		if boost != null and boost.is_valid():
			return boost

	return LEVEL_BOOST_CONFIG_SCRIPT.none()


## True once a real database entry (not the none() fallback) was used for
## level_number's most recent get_boost_for_level() call.
func was_fallback_used(level_number: int) -> bool:
	_ensure_database_loaded()
	return not (_database != null and _database.is_loaded() and _database.has_boost(level_number))


func is_database_loaded() -> bool:
	_ensure_database_loaded()
	return _database != null and _database.is_loaded()


func get_database_load_error() -> String:
	_ensure_database_loaded()
	return _database.get_load_error() if _database != null else "database_not_initialized"


func _ensure_database_loaded() -> void:
	if _database_load_attempted:
		return

	_database_load_attempted = true
	_database = LEVEL_BOOST_DATABASE_SCRIPT.new()


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

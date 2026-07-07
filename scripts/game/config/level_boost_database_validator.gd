extends RefCounted
class_name LevelBoostDatabaseValidator

## Stage 60.3 v0.1: validates the deterministic 500-level boost database
## (LevelBoostDatabase / data/levels/deterministic_level_boosts.json) against
## the Stage 60.3 distribution rules: exactly 500 unique, continuous levels;
## every level has a boost; every boost type is known; color_damage_multiplier
## has a valid tile_type and color_multiplier == 2.0; large_match_multiplier
## has match_4_multiplier == 2.0 and match_5_multiplier == 3.0; extra_moves has
## extra_moves == 3. Distribution counts (roughly a third of levels per boost
## type, colors spread evenly) are checked as warnings rather than hard errors
## so a hand-tuned future database isn't blocked by this rule of thumb.

const TOTAL_LEVELS := 500
const EXPECTED_COLOR_MULTIPLIER := 2.0
const EXPECTED_MATCH_4_MULTIPLIER := 2.0
const EXPECTED_MATCH_5_MULTIPLIER := 3.0
const EXPECTED_EXTRA_MOVES := 3
const VALID_COLORS := ["red", "blue", "green", "yellow", "purple"]


## Validates every boost in a LevelBoostDatabase. Returns a structured result
## Dictionary: {valid, errors, warnings, total_levels, counts_by_boost_type,
## counts_by_color}. `valid` is keyed off `errors` only.
func validate_database(database: LevelBoostDatabase) -> Dictionary:
	var errors: Array[String] = []
	var warnings: Array[String] = []
	var counts_by_boost_type: Dictionary = {}
	var counts_by_color: Dictionary = {}

	if database == null or not database.is_loaded():
		errors.append("database_not_loaded: %s" % (database.get_load_error() if database != null else "null_database"))
		return _build_result(errors, warnings, 0, counts_by_boost_type, counts_by_color)

	var level_numbers := database.get_all_level_numbers()
	var total_levels := level_numbers.size()

	if total_levels != TOTAL_LEVELS:
		errors.append("expected_%d_levels_found_%d" % [TOTAL_LEVELS, total_levels])

	var seen_levels := {}
	for level_number in level_numbers:
		if seen_levels.has(level_number):
			errors.append("duplicate_level_number: %d" % level_number)
		seen_levels[level_number] = true

	for expected_level_number in range(1, TOTAL_LEVELS + 1):
		if not database.has_boost(expected_level_number):
			errors.append("missing_level: %d" % expected_level_number)
			continue

		var boost: LevelBoostConfig = database.get_boost(expected_level_number)
		_validate_boost(expected_level_number, boost, errors, warnings, counts_by_boost_type, counts_by_color)

	_validate_distribution(total_levels, counts_by_boost_type, warnings)

	return _build_result(errors, warnings, total_levels, counts_by_boost_type, counts_by_color)


func _validate_boost(level_number: int, boost: LevelBoostConfig, errors: Array[String], warnings: Array[String], counts_by_boost_type: Dictionary, counts_by_color: Dictionary) -> void:
	if boost == null:
		errors.append("level_%d_missing_boost" % level_number)
		return

	if not LevelBoostType.is_valid_type(boost.boost_type):
		errors.append("level_%d_unknown_boost_type: %s" % [level_number, boost.boost_type])
		return

	var type_name := LevelBoostConfig.boost_type_to_string(boost.boost_type)
	counts_by_boost_type[type_name] = int(counts_by_boost_type.get(type_name, 0)) + 1

	match boost.boost_type:
		LevelBoostType.COLOR_DAMAGE_MULTIPLIER:
			var color_name := LevelBoostConfig.tile_type_to_string(boost.tile_type)
			if not (color_name in VALID_COLORS):
				errors.append("level_%d_invalid_color: %s" % [level_number, color_name])
			else:
				counts_by_color[color_name] = int(counts_by_color.get(color_name, 0)) + 1

			if not is_equal_approx(boost.color_multiplier, EXPECTED_COLOR_MULTIPLIER):
				errors.append("level_%d_unexpected_color_multiplier: %s" % [level_number, boost.color_multiplier])

		LevelBoostType.LARGE_MATCH_MULTIPLIER:
			if not is_equal_approx(boost.match_4_multiplier, EXPECTED_MATCH_4_MULTIPLIER):
				errors.append("level_%d_unexpected_match_4_multiplier: %s" % [level_number, boost.match_4_multiplier])
			if not is_equal_approx(boost.match_5_multiplier, EXPECTED_MATCH_5_MULTIPLIER):
				errors.append("level_%d_unexpected_match_5_multiplier: %s" % [level_number, boost.match_5_multiplier])

		LevelBoostType.EXTRA_MOVES:
			if boost.extra_moves != EXPECTED_EXTRA_MOVES:
				errors.append("level_%d_unexpected_extra_moves: %d" % [level_number, boost.extra_moves])

		LevelBoostType.NONE:
			warnings.append("level_%d_has_none_boost" % level_number)


## Distribution rule-of-thumb: level % 3 == 1/2/0 splits roughly into thirds
## across 500 levels (167/167/166). A meaningfully skewed distribution is
## flagged as a warning, not an error, so a future hand-tuned database isn't
## blocked by this heuristic.
func _validate_distribution(total_levels: int, counts_by_boost_type: Dictionary, warnings: Array[String]) -> void:
	if total_levels == 0:
		return

	var expected_share := total_levels / 3.0
	for type_name in ["color_damage_multiplier", "large_match_multiplier", "extra_moves"]:
		var actual := int(counts_by_boost_type.get(type_name, 0))
		if absf(actual - expected_share) > expected_share * 0.5:
			warnings.append("boost_type_%s_count_%d_far_from_expected_%.1f" % [type_name, actual, expected_share])


func _build_result(errors: Array[String], warnings: Array[String], total_levels: int, counts_by_boost_type: Dictionary, counts_by_color: Dictionary) -> Dictionary:
	return {
		"valid": errors.is_empty(),
		"errors": errors,
		"warnings": warnings,
		"total_levels": total_levels,
		"counts_by_boost_type": counts_by_boost_type,
		"counts_by_color": counts_by_color,
	}


## Builds the full report Dictionary written by the generation/validation
## tools - validate_database()'s result plus a generator_version/generated_at
## stamp so the report is self-describing on its own.
func build_report(database: LevelBoostDatabase) -> Dictionary:
	var result := validate_database(database)
	result["generator_version"] = database.generator_version if database != null else ""
	result["generated_at"] = Time.get_datetime_string_from_system(true)
	return result

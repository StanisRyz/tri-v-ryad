extends RefCounted
class_name LevelLayoutValidator

## Stage 58 v0.1: validates the deterministic 500-level layout database
## (LevelLayoutDatabase / data/levels/deterministic_level_layouts.json)
## against the rules laid out for Stage 58: exactly 500 unique, continuous
## levels; correct mask lengths/characters; normal/ice/holes archetypes each
## matching their expected board_mask/ice_mask shape; holes masks passing the
## same BoardMaskValidator/HoleGenerationRules tier rules the procedural
## generator itself validates against; ice cell counts/variants respecting
## IceGenerationRules; and metadata carrying archetype/variant/cycle_position/
## seed/layout_source. Structural problems (wrong mask length, wrong active
## board for a normal/ice level, ice on an inactive cell, etc.) are errors;
## looser rule-of-thumb checks (density/tier bounds "where applicable") are
## warnings so a hand-tuned layout can still be intentionally atypical.

const LEVEL_LAYOUT_MASK_CODEC_SCRIPT := preload("res://scripts/game/config/level_layout_mask_codec.gd")
const CHALLENGE_ARCHETYPE_SCRIPT := preload("res://scripts/game/config/challenge_archetype.gd")
const CHALLENGE_ARCHETYPE_RESOLVER_SCRIPT := preload("res://scripts/game/config/challenge_archetype_resolver.gd")
const ICE_VARIANT_SCRIPT := preload("res://scripts/game/config/ice_variant.gd")
const ICE_VARIANT_RESOLVER_SCRIPT := preload("res://scripts/game/config/ice_variant_resolver.gd")
const ICE_GENERATION_RULES_SCRIPT := preload("res://scripts/game/config/ice_generation_rules.gd")
const HOLE_GENERATION_RULES_SCRIPT := preload("res://scripts/game/config/hole_generation_rules.gd")
const BOARD_MASK_VALIDATOR_SCRIPT := preload("res://scripts/game/board/board_mask_validator.gd")
const DIFFICULTY_BUDGET_RESOLVER_SCRIPT := preload("res://scripts/game/config/difficulty_budget_resolver.gd")

const TOTAL_LEVELS := 500
const REQUIRED_MASK_LENGTH := 81

var _challenge_archetype_resolver := CHALLENGE_ARCHETYPE_RESOLVER_SCRIPT.new()
var _difficulty_budget_resolver := DIFFICULTY_BUDGET_RESOLVER_SCRIPT.new()
var _board_mask_validator := BOARD_MASK_VALIDATOR_SCRIPT.new()


## Validates every layout in a LevelLayoutDatabase. Returns a structured
## result Dictionary: {valid, errors, warnings, total_levels,
## counts_by_archetype, counts_by_variant}.
func validate_database(database: LevelLayoutDatabase) -> Dictionary:
	var errors: Array[String] = []
	var warnings: Array[String] = []
	var counts_by_archetype: Dictionary = {}
	var counts_by_variant: Dictionary = {}

	if database == null or not database.is_loaded():
		errors.append("database_not_loaded: %s" % (database.get_load_error() if database != null else "null_database"))
		return _build_result(errors, warnings, 0, counts_by_archetype, counts_by_variant)

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
		if not database.has_layout(expected_level_number):
			errors.append("missing_level: %d" % expected_level_number)

	for level_number in level_numbers:
		var layout := database.get_layout(level_number)
		var layout_errors := validate_layout(layout)
		for error_text in layout_errors:
			errors.append("level %d: %s" % [level_number, error_text])

		var layout_warnings := _warnings_for_layout(layout)
		for warning_text in layout_warnings:
			warnings.append("level %d: %s" % [level_number, warning_text])

		counts_by_archetype[layout.archetype] = int(counts_by_archetype.get(layout.archetype, 0)) + 1
		counts_by_variant[layout.variant] = int(counts_by_variant.get(layout.variant, 0)) + 1

	return _build_result(errors, warnings, total_levels, counts_by_archetype, counts_by_variant)


## Validates a single LevelLayout. Returns an Array of error strings (empty
## means the layout is structurally valid).
func validate_layout(layout: LevelLayout) -> Array[String]:
	var errors: Array[String] = []

	if not LEVEL_LAYOUT_MASK_CODEC_SCRIPT.is_valid_mask_string(layout.board_mask, LEVEL_LAYOUT_MASK_CODEC_SCRIPT.BOARD_MASK_CHARS):
		errors.append("invalid_board_mask: length=%d" % layout.board_mask.length())
		return errors

	if not LEVEL_LAYOUT_MASK_CODEC_SCRIPT.is_valid_mask_string(layout.ice_mask, LEVEL_LAYOUT_MASK_CODEC_SCRIPT.ICE_MASK_CHARS):
		errors.append("invalid_ice_mask: length=%d" % layout.ice_mask.length())
		return errors

	errors.append_array(_validate_metadata(layout))

	var expected_cycle_position := layout.level_number % 5
	if layout.cycle_position != expected_cycle_position:
		errors.append("cycle_position_mismatch: stored=%d expected=%d" % [layout.cycle_position, expected_cycle_position])

	var expected_archetype := _challenge_archetype_resolver.resolve_for_level(layout.level_number)
	if layout.archetype != expected_archetype:
		errors.append("archetype_mismatch: stored=%s expected=%s" % [layout.archetype, expected_archetype])

	var active_count := LEVEL_LAYOUT_MASK_CODEC_SCRIPT.count_char(layout.board_mask, "1")
	var ice_count := REQUIRED_MASK_LENGTH - LEVEL_LAYOUT_MASK_CODEC_SCRIPT.count_char(layout.ice_mask, "0")
	var weak_count := LEVEL_LAYOUT_MASK_CODEC_SCRIPT.count_char(layout.ice_mask, "1")
	var strong_count := LEVEL_LAYOUT_MASK_CODEC_SCRIPT.count_char(layout.ice_mask, "2")

	errors.append_array(_validate_ice_never_on_inactive_cell(layout))

	match layout.archetype:
		CHALLENGE_ARCHETYPE_SCRIPT.NORMAL:
			if active_count != REQUIRED_MASK_LENGTH:
				errors.append("normal_level_not_full_board: active=%d" % active_count)
			if ice_count != 0:
				errors.append("normal_level_has_ice: ice_cells=%d" % ice_count)
		CHALLENGE_ARCHETYPE_SCRIPT.ICE:
			if active_count != REQUIRED_MASK_LENGTH:
				errors.append("ice_level_not_full_board: active=%d" % active_count)
			var expected_variant := ICE_VARIANT_RESOLVER_SCRIPT.resolve_for_level(layout.level_number)
			if expected_variant == ICE_VARIANT_SCRIPT.WEAK:
				if strong_count != 0:
					errors.append("weak_ice_level_has_strong_ice: strong_cells=%d" % strong_count)
				if weak_count == 0:
					errors.append("weak_ice_level_has_no_ice")
			elif expected_variant == ICE_VARIANT_SCRIPT.STRONG:
				if weak_count != 0:
					errors.append("strong_ice_level_has_weak_ice: weak_cells=%d" % weak_count)
				if strong_count == 0:
					errors.append("strong_ice_level_has_no_ice")
		CHALLENGE_ARCHETYPE_SCRIPT.HOLES:
			if active_count >= REQUIRED_MASK_LENGTH:
				errors.append("holes_level_has_no_inactive_cells")
			if ice_count != 0:
				errors.append("holes_level_has_ice: ice_cells=%d" % ice_count)
			errors.append_array(_validate_hole_mask(layout))
		_:
			errors.append("unknown_archetype: %s" % layout.archetype)

	return errors


func _validate_metadata(layout: LevelLayout) -> Array[String]:
	var errors: Array[String] = []
	var required_keys := ["archetype", "variant", "cycle_position", "generation_seed", "layout_source"]
	for key in required_keys:
		if not layout.metadata.has(key):
			errors.append("metadata_missing_%s" % key)
	return errors


func _validate_ice_never_on_inactive_cell(layout: LevelLayout) -> Array[String]:
	var errors: Array[String] = []
	for index in range(REQUIRED_MASK_LENGTH):
		var is_active := layout.board_mask[index] == "1"
		var has_ice := layout.ice_mask[index] != "0"
		if has_ice and not is_active:
			errors.append("ice_on_inactive_cell: index=%d" % index)
	return errors


## Reuses BoardMaskValidator with the same tier-scoped HoleGenerationRules the
## procedural generator itself validates candidates against (resolved from
## the level's own difficulty tier), so a holes layout in the database must
## meet exactly the bar the generator already enforced when it built it.
func _validate_hole_mask(layout: LevelLayout) -> Array[String]:
	var errors: Array[String] = []
	var mask := LEVEL_LAYOUT_MASK_CODEC_SCRIPT.board_mask_from_string(layout.board_mask)
	var tier: String = _difficulty_budget_resolver.calculate_for_level(layout.level_number).difficulty_tier
	var rules := HOLE_GENERATION_RULES_SCRIPT.for_tier(tier)
	var validation := _board_mask_validator.validate(mask, rules)
	if not validation.valid:
		for reason in validation.reasons:
			errors.append("hole_mask_validation_failed: %s" % reason)
	return errors


func _warnings_for_layout(layout: LevelLayout) -> Array[String]:
	var warnings: Array[String] = []
	if layout.archetype != CHALLENGE_ARCHETYPE_SCRIPT.ICE:
		return warnings

	var ice_count := REQUIRED_MASK_LENGTH - LEVEL_LAYOUT_MASK_CODEC_SCRIPT.count_char(layout.ice_mask, "0")
	if ice_count < ICE_GENERATION_RULES_SCRIPT.MIN_ICE_CELLS or ice_count > ICE_GENERATION_RULES_SCRIPT.ABSOLUTE_RECTANGULAR_MAX_ICE_CELLS:
		warnings.append("ice_cell_count_outside_density_range: count=%d expected=[%d,%d]" % [
			ice_count, ICE_GENERATION_RULES_SCRIPT.MIN_ICE_CELLS, ICE_GENERATION_RULES_SCRIPT.ABSOLUTE_RECTANGULAR_MAX_ICE_CELLS,
		])

	return warnings


func _build_result(errors: Array[String], warnings: Array[String], total_levels: int, counts_by_archetype: Dictionary, counts_by_variant: Dictionary) -> Dictionary:
	return {
		"valid": errors.is_empty(),
		"errors": errors,
		"warnings": warnings,
		"total_levels": total_levels,
		"counts_by_archetype": counts_by_archetype,
		"counts_by_variant": counts_by_variant,
	}

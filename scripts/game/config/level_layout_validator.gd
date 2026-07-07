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
##
## Stage 59 v0.1: adds QA-only "review_candidates" — layouts that are still
## structurally valid (no errors) but suspicious enough to warrant a manual
## look: too few/many holes, ice density outside range, duplicate holes/ice
## masks reused across levels, a fallback layout captured into the database,
## or metadata whose archetype/variant/cycle_position/seed disagrees with the
## layout's own fields. These never fail validate_database()/validate_layout()
## (valid stays keyed off errors only) — they are purely advisory, surfaced in
## the QA report (see build_report()) for a human to skim.

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

## Stage 59 v0.1 QA thresholds: a holes layout below/above these counts is
## still a structurally valid, playable board (BoardMaskValidator/
## HoleGenerationRules already enforce the hard tier-scoped bounds in
## _validate_hole_mask()) but is unusual enough to flag for a human look.
const HOLES_QA_MIN_HOLE_CELLS := 8
const HOLES_QA_MAX_HOLE_CELLS := 24

var _challenge_archetype_resolver := CHALLENGE_ARCHETYPE_RESOLVER_SCRIPT.new()
var _difficulty_budget_resolver := DIFFICULTY_BUDGET_RESOLVER_SCRIPT.new()
var _board_mask_validator := BOARD_MASK_VALIDATOR_SCRIPT.new()


## Validates every layout in a LevelLayoutDatabase. Returns a structured
## result Dictionary: {valid, errors, warnings, review_candidates,
## total_levels, counts_by_archetype, counts_by_variant, hole_count_stats,
## ice_count_stats, fallback_layout_count, duplicate_layout_warnings}.
## `valid` is keyed off `errors` only — review_candidates/duplicate_layout_
## warnings are QA-only advisories and never fail validation.
func validate_database(database: LevelLayoutDatabase) -> Dictionary:
	var errors: Array[String] = []
	var warnings: Array[String] = []
	var review_candidates: Array[String] = []
	var duplicate_layout_warnings: Array[String] = []
	var counts_by_archetype: Dictionary = {}
	var counts_by_variant: Dictionary = {}
	var hole_counts: Array[int] = []
	var ice_counts: Array[int] = []
	var fallback_layout_count := 0

	if database == null or not database.is_loaded():
		errors.append("database_not_loaded: %s" % (database.get_load_error() if database != null else "null_database"))
		return _build_result(errors, warnings, review_candidates, duplicate_layout_warnings, 0, counts_by_archetype, counts_by_variant, hole_counts, ice_counts, fallback_layout_count)

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

	var seen_hole_masks := {}
	var seen_ice_masks := {}

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

		if layout.archetype == CHALLENGE_ARCHETYPE_SCRIPT.HOLES:
			var hole_count := REQUIRED_MASK_LENGTH - LEVEL_LAYOUT_MASK_CODEC_SCRIPT.count_char(layout.board_mask, "1")
			hole_counts.append(hole_count)
			if hole_count < HOLES_QA_MIN_HOLE_CELLS:
				review_candidates.append("level %d: holes_count_below_review_threshold: count=%d min=%d" % [level_number, hole_count, HOLES_QA_MIN_HOLE_CELLS])
			elif hole_count > HOLES_QA_MAX_HOLE_CELLS:
				review_candidates.append("level %d: holes_count_above_review_threshold: count=%d max=%d" % [level_number, hole_count, HOLES_QA_MAX_HOLE_CELLS])

			if seen_hole_masks.has(layout.board_mask):
				duplicate_layout_warnings.append("holes board_mask duplicate: level %d matches level %d" % [level_number, int(seen_hole_masks[layout.board_mask])])
			else:
				seen_hole_masks[layout.board_mask] = level_number

		elif layout.archetype == CHALLENGE_ARCHETYPE_SCRIPT.ICE:
			var ice_count := REQUIRED_MASK_LENGTH - LEVEL_LAYOUT_MASK_CODEC_SCRIPT.count_char(layout.ice_mask, "0")
			ice_counts.append(ice_count)
			if ice_count < ICE_GENERATION_RULES_SCRIPT.MIN_ICE_CELLS:
				review_candidates.append("level %d: ice_count_below_review_threshold: count=%d min=%d" % [level_number, ice_count, ICE_GENERATION_RULES_SCRIPT.MIN_ICE_CELLS])
			elif ice_count > ICE_GENERATION_RULES_SCRIPT.ABSOLUTE_RECTANGULAR_MAX_ICE_CELLS:
				review_candidates.append("level %d: ice_count_above_review_threshold: count=%d max=%d" % [level_number, ice_count, ICE_GENERATION_RULES_SCRIPT.ABSOLUTE_RECTANGULAR_MAX_ICE_CELLS])

			if seen_ice_masks.has(layout.ice_mask):
				duplicate_layout_warnings.append("ice ice_mask duplicate: level %d matches level %d" % [level_number, int(seen_ice_masks[layout.ice_mask])])
			else:
				seen_ice_masks[layout.ice_mask] = level_number

		if bool(layout.metadata.get("fallback_used", false)):
			fallback_layout_count += 1
			review_candidates.append("level %d: fallback_layout_stored_in_database" % level_number)

		review_candidates.append_array(_metadata_consistency_review_candidates(layout))

	review_candidates.append_array(duplicate_layout_warnings)

	return _build_result(errors, warnings, review_candidates, duplicate_layout_warnings, total_levels, counts_by_archetype, counts_by_variant, hole_counts, ice_counts, fallback_layout_count)


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


## Stage 59 v0.1: flags a layout whose metadata disagrees with its own
## top-level fields (archetype/variant/cycle_position/generation_seed) as a
## review candidate. Presence of these keys is already an error-level check
## (_validate_metadata); this is the softer "present but inconsistent" check.
func _metadata_consistency_review_candidates(layout: LevelLayout) -> Array[String]:
	var candidates: Array[String] = []
	if not (layout.metadata.has("archetype") and layout.metadata.has("variant") and layout.metadata.has("cycle_position") and layout.metadata.has("generation_seed")):
		return candidates

	if String(layout.metadata.get("archetype", "")) != layout.archetype:
		candidates.append("level %d: metadata_archetype_mismatch: metadata=%s layout=%s" % [layout.level_number, layout.metadata.get("archetype", ""), layout.archetype])
	if String(layout.metadata.get("variant", "")) != layout.variant:
		candidates.append("level %d: metadata_variant_mismatch: metadata=%s layout=%s" % [layout.level_number, layout.metadata.get("variant", ""), layout.variant])
	if int(layout.metadata.get("cycle_position", -1)) != layout.cycle_position:
		candidates.append("level %d: metadata_cycle_position_mismatch: metadata=%d layout=%d" % [layout.level_number, int(layout.metadata.get("cycle_position", -1)), layout.cycle_position])
	if int(layout.metadata.get("generation_seed", 0)) != layout.generation_seed:
		candidates.append("level %d: metadata_generation_seed_mismatch: metadata=%d layout=%d" % [layout.level_number, int(layout.metadata.get("generation_seed", 0)), layout.generation_seed])

	return candidates


func _stats_for_counts(counts: Array[int]) -> Dictionary:
	if counts.is_empty():
		return {"min": 0, "max": 0, "avg": 0.0}

	var total := 0
	var lowest: int = counts[0]
	var highest: int = counts[0]
	for value in counts:
		total += value
		lowest = mini(lowest, value)
		highest = maxi(highest, value)

	return {"min": lowest, "max": highest, "avg": float(total) / float(counts.size())}


func _build_result(errors: Array[String], warnings: Array[String], review_candidates: Array[String], duplicate_layout_warnings: Array[String], total_levels: int, counts_by_archetype: Dictionary, counts_by_variant: Dictionary, hole_counts: Array[int], ice_counts: Array[int], fallback_layout_count: int) -> Dictionary:
	return {
		"valid": errors.is_empty(),
		"errors": errors,
		"warnings": warnings,
		"review_candidates": review_candidates,
		"total_levels": total_levels,
		"counts_by_archetype": counts_by_archetype,
		"counts_by_variant": counts_by_variant,
		"hole_count_stats": _stats_for_counts(hole_counts),
		"ice_count_stats": _stats_for_counts(ice_counts),
		"fallback_layout_count": fallback_layout_count,
		"duplicate_layout_warnings": duplicate_layout_warnings,
	}


## Stage 59 v0.1: builds the full QA report Dictionary written to
## data/levels/deterministic_level_layout_report.json — validate_database()'s
## result plus a generator_version/generated_at stamp so the report is
## self-describing on its own.
func build_report(database: LevelLayoutDatabase) -> Dictionary:
	var result := validate_database(database)
	result["generator_version"] = database.generator_version if database != null else ""
	result["generated_at"] = Time.get_datetime_string_from_system(true)
	return result

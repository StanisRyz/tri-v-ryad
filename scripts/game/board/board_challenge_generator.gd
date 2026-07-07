extends RefCounted
class_name BoardChallengeGenerator

## Stage 54.1 v0.1: produces a GeneratedBoardChallenge for a level/archetype/
## difficulty/seed combination. normal and ice archetypes still return a
## full 9x9 active board placeholder (real ice behavior is a later stage);
## holes generates a real symmetrical, validated inactive-cell mask via
## BoardMaskGenerator (using tier-scoped HoleGenerationRules from
## HoleGenerationRules.for_tier() for varied block sizes and center-aware
## shapes), falling back to a full board when no safe candidate is found
## within the attempt budget.
##
## Stage 58 v0.1: generate() now checks LevelLayoutDatabase first. When a
## deterministic layout exists for level_number, its board_mask/ice_mask are
## decoded and used directly (metadata["layout_source"] =
## "deterministic_database") instead of re-running procedural generation —
## the same 5-level archetype/variant cycle still applies, it's just captured
## once instead of re-rolled every playthrough. Procedural generation (below)
## remains the fallback for any level without a saved layout, and stays
## fully intact for tools/future modes.
##
## Stage 59 v0.1: generate() no longer trusts a database hit blindly — the
## single matched layout is run through LevelLayoutValidator.validate_layout()
## (a cheap single-layout check, not the full 500-level database sweep) before
## it is used. An invalid layout, or a database that failed to load at all,
## falls back to the same procedural generation path used for levels outside
## the database, with metadata explaining why (layout_source =
## "procedural_fallback_invalid_layout"/"procedural_fallback_database_error",
## deterministic_layout_used = false, plus deterministic_layout_error /
## invalid_layout_reasons / database_load_error for debugging).

const GENERATED_BOARD_CHALLENGE_SCRIPT := preload("res://scripts/game/board/generated_board_challenge.gd")
const BOARD_MASK_GENERATOR_SCRIPT := preload("res://scripts/game/board/board_mask_generator.gd")
const HOLE_GENERATION_RULES_SCRIPT := preload("res://scripts/game/config/hole_generation_rules.gd")
const ICE_GENERATION_RULES_SCRIPT := preload("res://scripts/game/config/ice_generation_rules.gd")
const ICE_PATTERN_GENERATOR_SCRIPT := preload("res://scripts/game/board/ice_pattern_generator.gd")
const ICE_VARIANT_RESOLVER_SCRIPT := preload("res://scripts/game/config/ice_variant_resolver.gd")
const CHALLENGE_ARCHETYPE_SCRIPT := preload("res://scripts/game/config/challenge_archetype.gd")
const LEVEL_LAYOUT_DATABASE_SCRIPT := preload("res://scripts/game/config/level_layout_database.gd")
const LEVEL_LAYOUT_VALIDATOR_SCRIPT := preload("res://scripts/game/config/level_layout_validator.gd")

var _board_mask_generator := BOARD_MASK_GENERATOR_SCRIPT.new()
var _ice_pattern_generator := ICE_PATTERN_GENERATOR_SCRIPT.new()
var _level_layout_database := LEVEL_LAYOUT_DATABASE_SCRIPT.new()
var _level_layout_validator := LEVEL_LAYOUT_VALIDATOR_SCRIPT.new()


func generate(level_id: String, level_number: int, archetype: String, difficulty_budget, generation_seed: int) -> GeneratedBoardChallenge:
	var fallback_metadata_overrides: Dictionary = {}

	if not _level_layout_database.is_loaded():
		fallback_metadata_overrides = {
			"layout_source": "procedural_fallback_database_error",
			"deterministic_layout_used": false,
			"database_load_error": _level_layout_database.get_load_error(),
		}
	elif _level_layout_database.has_layout(level_number):
		var layout := _level_layout_database.get_layout(level_number)
		var layout_errors := _level_layout_validator.validate_layout(layout)
		if layout_errors.is_empty():
			return _generate_from_layout(layout, level_id, level_number, difficulty_budget, generation_seed)

		fallback_metadata_overrides = {
			"layout_source": "procedural_fallback_invalid_layout",
			"deterministic_layout_used": false,
			"deterministic_layout_error": "invalid_layout",
			"invalid_layout_reasons": layout_errors,
		}

	var board_mask: Array
	var metadata: Dictionary
	var frozen_cells: Array = []

	if archetype == CHALLENGE_ARCHETYPE_SCRIPT.HOLES:
		## Seeding from generation_seed keeps hole layout reproducible for a
		## given battle-start seed, matching the debug/reproducibility intent
		## generation_seed was introduced for in Stage 51.
		var mask_rng := RandomNumberGenerator.new()
		mask_rng.seed = generation_seed
		## Stage 54.1: HoleGenerationRules.for_tier() is the single source of
		## truth for tier -> active/hole cap mapping — no rule values are
		## duplicated here.
		var tier: String = difficulty_budget.difficulty_tier if difficulty_budget != null else DifficultyBudget.TIER_EARLY
		var rules := HOLE_GENERATION_RULES_SCRIPT.for_tier(tier)
		var generation_result := _board_mask_generator.generate_holes_mask_with_metadata(mask_rng, difficulty_budget, rules)
		board_mask = generation_result.get("mask", _board_mask_generator.build_full_active_mask())
		metadata = generation_result.get("metadata", {})
		## Stage 57: holes and ice are not mixed in this stage, so a holes
		## challenge still gets no frozen cells.
	elif archetype == CHALLENGE_ARCHETYPE_SCRIPT.ICE:
		## Stage 57 v0.1: `ice` still uses a full active 9x9 mask (no holes);
		## the board_mask is only passed to IcePatternGenerator so frozen
		## cells are never placed on an inactive cell, in case a future stage
		## combines archetypes.
		board_mask = _board_mask_generator.build_full_active_mask()
		var ice_rng := RandomNumberGenerator.new()
		ice_rng.seed = generation_seed
		var ice_tier: String = difficulty_budget.difficulty_tier if difficulty_budget != null else DifficultyBudget.TIER_EARLY
		## Stage 57.2 v0.1: level_number resolves a weak/strong ice cycle
		## variant (level_number % 5 == 2 -> weak, == 4 -> strong) — `ice`
		## only ever lands on those two cycle positions, so every ice level
		## always resolves to exactly one of them. The variant is stored
		## directly on the rules object so IcePatternGenerator can force
		## every generated cell's layer count deterministically.
		var ice_variant := ICE_VARIANT_RESOLVER_SCRIPT.resolve_for_level(level_number)
		var ice_rules := ICE_GENERATION_RULES_SCRIPT.for_tier(ice_tier, ice_variant)
		var ice_result := _ice_pattern_generator.generate_frozen_cells(ice_rng, board_mask, difficulty_budget, ice_rules)
		frozen_cells = ice_result.get("frozen_cells", [])
		metadata = ice_result.get("metadata", {})
	else:
		board_mask = _board_mask_generator.build_full_active_mask()
		metadata = {
			"generator_version": "0.1",
			"layout_source": "placeholder_full_board",
		}

	if not fallback_metadata_overrides.is_empty():
		metadata.merge(fallback_metadata_overrides, true)

	var difficulty_score: float = difficulty_budget.difficulty_score if difficulty_budget != null else 0.0
	var difficulty_tier: String = difficulty_budget.difficulty_tier if difficulty_budget != null else DifficultyBudget.TIER_EARLY

	return GENERATED_BOARD_CHALLENGE_SCRIPT.new(
		archetype,
		level_id,
		level_number,
		difficulty_score,
		difficulty_tier,
		generation_seed,
		board_mask,
		frozen_cells,
		metadata
	)


## Stage 58 v0.1: builds a GeneratedBoardChallenge straight from a stored
## LevelLayout — no RNG, no BoardMaskGenerator/IcePatternGenerator involved.
## The layout's own generation_seed is preserved on the returned challenge
## (rather than the battle-time generation_seed argument) so debug output
## always reflects the seed the saved layout was actually built from.
func _generate_from_layout(layout: LevelLayout, level_id: String, level_number: int, difficulty_budget, generation_seed: int) -> GeneratedBoardChallenge:
	var board_mask := layout.get_board_mask_array()
	var frozen_cells := layout.get_frozen_cells()

	var metadata: Dictionary = layout.metadata.duplicate(true)
	metadata["layout_source"] = "deterministic_database"
	metadata["deterministic_layout_used"] = true
	if layout.archetype == CHALLENGE_ARCHETYPE_SCRIPT.ICE:
		metadata["ice_variant"] = layout.variant

	var difficulty_score: float = difficulty_budget.difficulty_score if difficulty_budget != null else 0.0
	var difficulty_tier: String = difficulty_budget.difficulty_tier if difficulty_budget != null else DifficultyBudget.TIER_EARLY

	return GENERATED_BOARD_CHALLENGE_SCRIPT.new(
		layout.archetype,
		level_id,
		level_number,
		difficulty_score,
		difficulty_tier,
		layout.generation_seed if layout.generation_seed != 0 else generation_seed,
		board_mask,
		frozen_cells,
		metadata
	)

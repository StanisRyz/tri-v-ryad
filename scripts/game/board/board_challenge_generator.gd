extends RefCounted
class_name BoardChallengeGenerator

## Stage 54 v0.1: produces a GeneratedBoardChallenge for a level/archetype/
## difficulty/seed combination. normal and ice archetypes still return a
## full 9x9 active board placeholder (real ice behavior is a later stage);
## holes now generates a real symmetrical, validated inactive-cell mask via
## BoardMaskGenerator, falling back to a full board when no safe candidate
## is found within the attempt budget.

const GENERATED_BOARD_CHALLENGE_SCRIPT := preload("res://scripts/game/board/generated_board_challenge.gd")
const BOARD_MASK_GENERATOR_SCRIPT := preload("res://scripts/game/board/board_mask_generator.gd")
const HOLE_GENERATION_RULES_SCRIPT := preload("res://scripts/game/config/hole_generation_rules.gd")
const CHALLENGE_ARCHETYPE_SCRIPT := preload("res://scripts/game/config/challenge_archetype.gd")

var _board_mask_generator := BOARD_MASK_GENERATOR_SCRIPT.new()
var _hole_generation_rules := HOLE_GENERATION_RULES_SCRIPT.new()


func generate(level_id: String, level_number: int, archetype: String, difficulty_budget, generation_seed: int) -> GeneratedBoardChallenge:
	var board_mask: Array
	var metadata: Dictionary

	if archetype == CHALLENGE_ARCHETYPE_SCRIPT.HOLES:
		## Seeding from generation_seed keeps hole layout reproducible for a
		## given battle-start seed, matching the debug/reproducibility intent
		## generation_seed was introduced for in Stage 51.
		var mask_rng := RandomNumberGenerator.new()
		mask_rng.seed = generation_seed
		var generation_result := _board_mask_generator.generate_holes_mask_with_metadata(mask_rng, difficulty_budget, _hole_generation_rules)
		board_mask = generation_result.get("mask", _board_mask_generator.build_full_active_mask())
		metadata = generation_result.get("metadata", {})
	else:
		board_mask = _board_mask_generator.build_full_active_mask()
		metadata = {
			"generator_version": "0.1",
			"layout_source": "placeholder_full_board",
		}

	var frozen_cells: Array = []

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

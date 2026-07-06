extends RefCounted
class_name BoardChallengeGenerator

## Stage 51 v0.1: produces a GeneratedBoardChallenge for a level/archetype/
## difficulty/seed combination. For this stage every archetype returns a
## full 9x9 active board placeholder (board_mask all true, no frozen cells)
## with only the archetype and debug metadata differing; real hole/ice
## layout generation arrives in later stages.

const GENERATED_BOARD_CHALLENGE_SCRIPT := preload("res://scripts/game/board/generated_board_challenge.gd")


func generate(level_id: String, level_number: int, archetype: String, difficulty_budget, generation_seed: int) -> GeneratedBoardChallenge:
	var board_mask := _build_full_board_mask()
	var frozen_cells: Array = []
	var metadata := {
		"generator_version": "0.1",
		"layout_source": "placeholder_full_board",
	}

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


func _build_full_board_mask(width: int = BoardModel.DEFAULT_WIDTH, height: int = BoardModel.DEFAULT_HEIGHT) -> Array:
	var mask: Array = []
	for y in range(height):
		var row: Array = []
		for x in range(width):
			row.append(true)
		mask.append(row)
	return mask

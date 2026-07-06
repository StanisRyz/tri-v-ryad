extends RefCounted
class_name DifficultyBudgetResolver

## Stage 51 v0.1: derives a DifficultyBudget from a level number. Keeps early
## levels gentle by scaling every budgeted value off a normalized 0..1
## progress value that only approaches 1.0 near the end of the campaign.

const DIFFICULTY_BUDGET_SCRIPT := preload("res://scripts/game/config/difficulty_budget.gd")

const SCORE_STEP_PER_LEVEL := 0.85
const SCORE_NORMALIZATION_RANGE := 100.0

const MEDIUM_TIER_LEVEL := 25
const HARD_TIER_LEVEL := 55
const VERY_HARD_TIER_LEVEL := 85

const MAX_ICE_DENSITY := 0.35
const MAX_HOLE_COUNT := 10
const MAX_BLOCKER_COUNT := 8
const BASE_VALIDATION_ATTEMPTS := 20
const MAX_VALIDATION_ATTEMPTS := 60


func calculate_for_level(level_number: int) -> DifficultyBudget:
	var safe_level_number: int = max(1, level_number)
	var difficulty_score := _calculate_difficulty_score(safe_level_number)
	var difficulty_tier := _resolve_tier(safe_level_number)
	var normalized: float = clamp(difficulty_score / SCORE_NORMALIZATION_RANGE, 0.0, 1.0)

	return DIFFICULTY_BUDGET_SCRIPT.new(
		safe_level_number,
		difficulty_score,
		difficulty_tier,
		normalized * MAX_ICE_DENSITY,
		int(round(normalized * MAX_HOLE_COUNT)),
		int(round(normalized * MAX_BLOCKER_COUNT)),
		BASE_VALIDATION_ATTEMPTS + int(round(normalized * (MAX_VALIDATION_ATTEMPTS - BASE_VALIDATION_ATTEMPTS))),
		normalized
	)


func _calculate_difficulty_score(level_number: int) -> float:
	return float(level_number - 1) * SCORE_STEP_PER_LEVEL


func _resolve_tier(level_number: int) -> String:
	if level_number >= VERY_HARD_TIER_LEVEL:
		return DIFFICULTY_BUDGET_SCRIPT.TIER_VERY_HARD
	if level_number >= HARD_TIER_LEVEL:
		return DIFFICULTY_BUDGET_SCRIPT.TIER_HARD
	if level_number >= MEDIUM_TIER_LEVEL:
		return DIFFICULTY_BUDGET_SCRIPT.TIER_MEDIUM
	return DIFFICULTY_BUDGET_SCRIPT.TIER_EARLY

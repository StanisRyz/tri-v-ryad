extends RefCounted
class_name BoardMaskGenerator

## Stage 54 v0.1: generates real symmetrical, validated procedural hole masks
## using HoleGenerationRules + BoardMaskSymmetry (via HoleBlockPlacer) +
## BoardMaskValidator. Candidates place quadrant-mirrored 2x2/2x3/3x2 blocks
## anchored in the board's upper-left quadrant (never touching the center
## row/column), so the center cell is protected by construction as well as
## by HoleBlockPlacer's own check. Falls back to a full-active mask whenever
## no valid candidate is found within the attempt budget.

const HOLE_GENERATION_RULES_SCRIPT := preload("res://scripts/game/config/hole_generation_rules.gd")
const HOLE_BLOCK_PLACER_SCRIPT := preload("res://scripts/game/board/hole_block_placer.gd")
const BOARD_MASK_VALIDATOR_SCRIPT := preload("res://scripts/game/board/board_mask_validator.gd")

const DEFAULT_VALIDATION_ATTEMPTS := 20

var _hole_block_placer := HOLE_BLOCK_PLACER_SCRIPT.new()
var _validator := BOARD_MASK_VALIDATOR_SCRIPT.new()


## Convenience entry point returning only the mask. Kept as a thin wrapper
## around generate_holes_mask_with_metadata() so existing callers that only
## need the mask (and the Stage 53.1 signature) keep working unchanged.
func generate_holes_mask(rng: RandomNumberGenerator = null, difficulty_budget = null, rules: HoleGenerationRules = null) -> Array:
	var result := generate_holes_mask_with_metadata(rng, difficulty_budget, rules)
	return result.get("mask", build_full_active_mask())


## Stage 54 entry point that also reports generation metadata (attempts
## used, fallback state, validation reasons, active/hole counts) so callers
## like BoardChallengeGenerator can attach rich debug info without having to
## re-run/re-validate generation themselves.
func generate_holes_mask_with_metadata(rng: RandomNumberGenerator = null, difficulty_budget = null, rules: HoleGenerationRules = null) -> Dictionary:
	var safe_rng := rng
	if safe_rng == null:
		safe_rng = RandomNumberGenerator.new()
		safe_rng.randomize()

	var safe_rules: HoleGenerationRules = rules if rules != null else HOLE_GENERATION_RULES_SCRIPT.new()
	var max_attempts := _resolve_attempt_budget(difficulty_budget)
	var block_count := _resolve_block_count(difficulty_budget)

	var last_validation = null
	var attempts_used := 0

	for attempt in range(max_attempts):
		attempts_used = attempt + 1
		var candidate := _build_candidate_mask(safe_rng, block_count, safe_rules)
		var validation := _validator.validate(candidate, safe_rules)
		last_validation = validation
		if validation.valid:
			return {
				"mask": candidate,
				"metadata": _build_metadata(attempts_used, false, validation),
			}

	var fallback_mask := build_full_active_mask()
	var fallback_validation := _validator.validate(fallback_mask, safe_rules)
	return {
		"mask": fallback_mask,
		"metadata": _build_metadata(attempts_used, true, last_validation if last_validation != null else fallback_validation),
	}


func build_full_active_mask(width: int = BoardModel.DEFAULT_WIDTH, height: int = BoardModel.DEFAULT_HEIGHT) -> Array:
	var mask: Array = []
	for y in range(height):
		var row: Array = []
		for x in range(width):
			row.append(true)
		mask.append(row)
	return mask


## Places up to block_count quadrant-mirrored hole blocks (2x2/2x3/3x2)
## anchored in the upper-left quadrant [0, width/2) x [0, height/2), which
## on a 9x9 board never includes the center row/column (index 4), so
## mirrored copies can never collide with the center cell or each other.
## A candidate anchor that HoleBlockPlacer rejects is simply skipped; the
## outer attempt loop in generate_holes_mask_with_metadata() retries a whole
## fresh candidate rather than retrying single placements forever.
func _build_candidate_mask(rng: RandomNumberGenerator, block_count: int, rules: HoleGenerationRules) -> Array:
	var mask := build_full_active_mask()
	if block_count <= 0:
		return mask

	var width := BoardModel.DEFAULT_WIDTH
	var height := BoardModel.DEFAULT_HEIGHT
	@warning_ignore("integer_division")
	var quadrant_width := width / 2
	@warning_ignore("integer_division")
	var quadrant_height := height / 2

	var placed_count := 0
	var placement_attempts := 0
	var max_placement_attempts := block_count * 10

	while placed_count < block_count and placement_attempts < max_placement_attempts:
		placement_attempts += 1
		var block_size := _pick_block_size(rng, rules)
		var block_width: int = block_size.x
		var block_height: int = block_size.y

		var max_top_left_x := quadrant_width - block_width
		var max_top_left_y := quadrant_height - block_height
		if max_top_left_x < 0 or max_top_left_y < 0:
			continue

		var top_left := Vector2i(rng.randi_range(0, max_top_left_x), rng.randi_range(0, max_top_left_y))
		if _hole_block_placer.try_place_hole_block(mask, top_left, block_width, block_height, rules):
			placed_count += 1

	return mask


## Allowed v0.1 block sizes are 2x2, 2x3, and 3x2, clamped to the rules'
## configured min/max so HoleGenerationRules stays the single source of
## truth for block sizing.
func _pick_block_size(rng: RandomNumberGenerator, rules: HoleGenerationRules) -> Vector2i:
	var sizes: Array[Vector2i] = [Vector2i(2, 2), Vector2i(2, 3), Vector2i(3, 2)]
	var picked: Vector2i = sizes[rng.randi_range(0, sizes.size() - 1)]
	return Vector2i(
		clampi(picked.x, rules.min_block_width, rules.max_block_width),
		clampi(picked.y, rules.min_block_height, rules.max_block_height)
	)


## Suggested v0.1 difficulty curve: early -> 1 mirrored block, medium -> 1-2,
## hard -> 2, very_hard -> 2-3, nudged by layout_complexity within a tier.
## Rules (min_active_cells/max_hole_cells via HoleBlockPlacer/BoardMaskValidator)
## always override this — it only decides how many blocks to attempt.
func _resolve_block_count(difficulty_budget) -> int:
	if difficulty_budget == null:
		return 1

	var tier: String = difficulty_budget.difficulty_tier if "difficulty_tier" in difficulty_budget else DifficultyBudget.TIER_EARLY
	var layout_complexity: float = float(difficulty_budget.layout_complexity) if "layout_complexity" in difficulty_budget else 0.0

	match tier:
		DifficultyBudget.TIER_MEDIUM:
			return 2 if layout_complexity >= 0.5 else 1
		DifficultyBudget.TIER_HARD:
			return 2
		DifficultyBudget.TIER_VERY_HARD:
			return 3 if layout_complexity >= 0.5 else 2
		_:
			return 1


func _resolve_attempt_budget(difficulty_budget) -> int:
	if difficulty_budget != null and "validation_attempts" in difficulty_budget and int(difficulty_budget.validation_attempts) > 0:
		return int(difficulty_budget.validation_attempts)

	return DEFAULT_VALIDATION_ATTEMPTS


func _build_metadata(attempts_used: int, fallback_used: bool, validation) -> Dictionary:
	var metadata := {
		"generator_version": "0.1",
		"layout_source": "fallback_full_board" if fallback_used else "procedural_holes",
		"attempts_used": attempts_used,
		"fallback_used": fallback_used,
	}

	if validation != null:
		metadata["active_cell_count"] = validation.active_cell_count
		metadata["hole_cell_count"] = validation.hole_cell_count
		metadata["last_validation_reasons"] = (validation.reasons as Array).duplicate()

	return metadata

extends RefCounted
class_name BoardMaskGenerator

## Stage 53.1 v0.1: prepares the API surface Stage 54 will use to generate
## real procedural hole masks from HoleGenerationRules, BoardMaskSymmetry,
## HoleBlockPlacer, and BoardMaskValidator. For this stage generate_holes_mask()
## always returns a safe, validated full-active 9x9 mask — no real holes are
## enabled in active battle generation yet (BattlePresenter/BoardChallengeGenerator
## are untouched).

const HOLE_GENERATION_RULES_SCRIPT := preload("res://scripts/game/config/hole_generation_rules.gd")
const HOLE_BLOCK_PLACER_SCRIPT := preload("res://scripts/game/board/hole_block_placer.gd")
const BOARD_MASK_VALIDATOR_SCRIPT := preload("res://scripts/game/board/board_mask_validator.gd")

var _hole_block_placer := HOLE_BLOCK_PLACER_SCRIPT.new()
var _validator := BOARD_MASK_VALIDATOR_SCRIPT.new()


## Future-facing Stage 54 entry point. rng/difficulty_budget are accepted
## now so Stage 54 can wire real block placement without changing this
## method's signature; for v0.1 they are unused and a full-active mask is
## returned (validated against rules, falling back to full-active again if
## that somehow failed).
func generate_holes_mask(rng: RandomNumberGenerator = null, difficulty_budget = null, rules: HoleGenerationRules = null) -> Array:
	var safe_rules: HoleGenerationRules = rules if rules != null else HOLE_GENERATION_RULES_SCRIPT.new()
	var mask := build_full_active_mask()

	var validation := _validator.validate(mask, safe_rules)
	if not validation.valid:
		return build_full_active_mask()

	return mask


func build_full_active_mask(width: int = BoardModel.DEFAULT_WIDTH, height: int = BoardModel.DEFAULT_HEIGHT) -> Array:
	var mask: Array = []
	for y in range(height):
		var row: Array = []
		for x in range(width):
			row.append(true)
		mask.append(row)
	return mask

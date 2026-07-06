extends RefCounted
class_name HoleGenerationRules

## Stage 53.1 v0.1: rule set for future procedural hole mask generation
## (Stage 54). Nothing in this stage consumes these rules to generate real
## holes yet — they exist so HoleBlockPlacer/BoardMaskValidator/BoardMaskGenerator
## have a shared, typed contract to build against.

const SYMMETRY_QUADRANT_MIRROR := "quadrant_mirror"

## 9x9 board has 81 cells; the v0.1 default keeps at least 65 active,
## leaving at most 16 as holes.
const DEFAULT_BOARD_CELLS := 81
const DEFAULT_MIN_ACTIVE_CELLS := 65

var min_block_width := 2
var min_block_height := 2
var max_block_width := 3
var max_block_height := 3
var min_active_cells := DEFAULT_MIN_ACTIVE_CELLS
var max_hole_cells := DEFAULT_BOARD_CELLS - DEFAULT_MIN_ACTIVE_CELLS
var symmetry_mode := SYMMETRY_QUADRANT_MIRROR
var keep_center_active := true
var require_connected_active_area := true
var reject_enclosed_active_pockets := true
var reject_single_cell_holes := true


func _init(
	config_min_block_width: int = 2,
	config_min_block_height: int = 2,
	config_max_block_width: int = 3,
	config_max_block_height: int = 3,
	config_min_active_cells: int = DEFAULT_MIN_ACTIVE_CELLS,
	config_max_hole_cells: int = DEFAULT_BOARD_CELLS - DEFAULT_MIN_ACTIVE_CELLS,
	config_symmetry_mode: String = SYMMETRY_QUADRANT_MIRROR,
	config_keep_center_active: bool = true,
	config_require_connected_active_area: bool = true,
	config_reject_enclosed_active_pockets: bool = true,
	config_reject_single_cell_holes: bool = true
) -> void:
	min_block_width = config_min_block_width
	min_block_height = config_min_block_height
	max_block_width = config_max_block_width
	max_block_height = config_max_block_height
	min_active_cells = config_min_active_cells
	max_hole_cells = config_max_hole_cells
	symmetry_mode = config_symmetry_mode
	keep_center_active = config_keep_center_active
	require_connected_active_area = config_require_connected_active_area
	reject_enclosed_active_pockets = config_reject_enclosed_active_pockets
	reject_single_cell_holes = config_reject_single_cell_holes


static func default_rules() -> HoleGenerationRules:
	return HoleGenerationRules.new()


## Stage 54.1 v0.1: tier-scoped safe hole/active-cell caps. Structural
## settings (block sizes, symmetry mode, center/connectivity/enclosed/
## single-cell toggles) stay the v0.1 defaults; only the numeric active/hole
## ceiling grows with difficulty tier, so harder levels have enough hole
## budget for 2x3/3x2 blocks and center shapes without ever allowing a
## nearly-empty board. This is the single source of truth for the tier ->
## cap mapping — callers (BoardMaskGenerator, BoardChallengeGenerator)
## should call this instead of hardcoding per-tier numbers themselves.
static func for_tier(tier: String) -> HoleGenerationRules:
	var tier_max_hole_cells := _max_hole_cells_for_tier(tier)
	var tier_min_active_cells := DEFAULT_BOARD_CELLS - tier_max_hole_cells
	return HoleGenerationRules.new(2, 2, 3, 3, tier_min_active_cells, tier_max_hole_cells)


static func _max_hole_cells_for_tier(tier: String) -> int:
	match tier:
		DifficultyBudget.TIER_MEDIUM:
			return 20
		DifficultyBudget.TIER_HARD:
			return 24
		DifficultyBudget.TIER_VERY_HARD:
			return 28
		_:
			return 16

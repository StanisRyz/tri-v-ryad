extends RefCounted
class_name IceGenerationRules

## Stage 57 v0.1: rule set for procedural ice (frozen cell) generation. Mirrors
## HoleGenerationRules' shape — a typed, tier-scoped contract that
## IcePatternGenerator/BoardChallengeGenerator build against rather than
## hardcoding per-tier numbers themselves.
##
## Stage 57.1 v0.1: added symmetric/center-shape generation fields
## (center_ice_chance, allowed_center_shape_types, allowed_symmetric_shape_types,
## prefer_symmetry, max_center_ice_cells).
##
## Stage 57.2 v0.1: every ice level, regardless of difficulty tier, now
## targets the same dense 32-40 frozen-cell range (min_ice_cells/max_ice_cells
## are no longer tier-scaled — MIN_ICE_CELLS/MAX_ICE_CELLS below are the only
## values used by for_tier()), superseding Stage 57/57.1's tier-scaled "gentle
## early / denser later" counts. allowed_center_shape_types/
## allowed_symmetric_shape_types are likewise the full preset lists for every
## tier now, since even the largest single shape is well under the new
## per-level target and needs topping up regardless of tier. Also adds
## ice_variant (IceVariant.WEAK/STRONG/NONE), set on the returned rules object
## by for_tier() rather than threaded through the constructor, so
## IcePatternGenerator can force every generated cell to 1-layer (weak) or
## 2-layer (strong) ice deterministically instead of the old probability-based
## double_ice_chance/max_double_ice_cells (kept only for IceVariant.NONE
## backward compatibility).

const ICE_SHAPE_PRESET_SCRIPT := preload("res://scripts/game/board/ice_shape_preset.gd")
const ICE_VARIANT_SCRIPT := preload("res://scripts/game/config/ice_variant.gd")

const PATTERN_SMALL_CLUSTER := "small_cluster"
const PATTERN_EDGE_PATCH := "edge_patch"
const PATTERN_CENTER_PATCH := "center_patch"
const PATTERN_DIAGONAL_BAND := "diagonal_band"

const DEFAULT_VALIDATION_ATTEMPTS := 20
## Stage 57.2: every ice level targets this same dense range regardless of
## difficulty tier. 40 stays safely under half of an 81-cell 9x9 board.
const MIN_ICE_CELLS := 32
const MAX_ICE_CELLS := 40

var min_ice_cells := MIN_ICE_CELLS
var max_ice_cells := MAX_ICE_CELLS
var max_double_ice_cells := 0
var double_ice_chance := 0.0
var cluster_size_min := 2
var cluster_size_max := 3
var allowed_pattern_types: Array[String] = [PATTERN_SMALL_CLUSTER]
var validation_attempts := DEFAULT_VALIDATION_ATTEMPTS
## Stage 57.1 fields below.
var center_ice_chance := 0.0
var allowed_center_shape_types: Array[String] = []
var allowed_symmetric_shape_types: Array[String] = []
var prefer_symmetry := true
var max_center_ice_cells := 0
## Stage 57.2 field: which cycle variant (see IceVariant) this rules object
## was resolved for. Set directly by for_tier(), not via the constructor.
var ice_variant: String = ICE_VARIANT_SCRIPT.NONE


func _init(
	config_min_ice_cells: int = MIN_ICE_CELLS,
	config_max_ice_cells: int = MAX_ICE_CELLS,
	config_max_double_ice_cells: int = 0,
	config_double_ice_chance: float = 0.0,
	config_cluster_size_min: int = 2,
	config_cluster_size_max: int = 3,
	config_allowed_pattern_types: Array[String] = [PATTERN_SMALL_CLUSTER],
	config_validation_attempts: int = DEFAULT_VALIDATION_ATTEMPTS,
	config_center_ice_chance: float = 0.0,
	config_allowed_center_shape_types: Array[String] = [],
	config_allowed_symmetric_shape_types: Array[String] = [],
	config_prefer_symmetry: bool = true,
	config_max_center_ice_cells: int = 0
) -> void:
	min_ice_cells = config_min_ice_cells
	max_ice_cells = config_max_ice_cells
	max_double_ice_cells = config_max_double_ice_cells
	double_ice_chance = config_double_ice_chance
	cluster_size_min = config_cluster_size_min
	cluster_size_max = config_cluster_size_max
	allowed_pattern_types = config_allowed_pattern_types.duplicate()
	validation_attempts = config_validation_attempts
	center_ice_chance = config_center_ice_chance
	allowed_center_shape_types = config_allowed_center_shape_types.duplicate()
	allowed_symmetric_shape_types = config_allowed_symmetric_shape_types.duplicate()
	prefer_symmetry = config_prefer_symmetry
	max_center_ice_cells = config_max_center_ice_cells if config_max_center_ice_cells > 0 else config_max_ice_cells


static func default_rules() -> IceGenerationRules:
	return IceGenerationRules.new()


## Stage 57.2: min_ice_cells/max_ice_cells and the center/symmetric shape
## pools are now the same dense, full set for every tier — only
## center_ice_chance, validation_attempts, and the scattered-pattern
## top-up pool/cluster sizes still vary by tier. variant (IceVariant.WEAK/
## STRONG/NONE) is resolved by the caller (BoardChallengeGenerator, via
## IceVariantResolver) and stored directly on the returned rules object so
## IcePatternGenerator can force every generated cell's layer count
## deterministically instead of rolling double_ice_chance per cell.
static func for_tier(tier: String, variant: String = ICE_VARIANT_SCRIPT.NONE) -> IceGenerationRules:
	var tier_validation_attempts := DEFAULT_VALIDATION_ATTEMPTS
	var tier_center_ice_chance := 0.5
	var tier_cluster_min := 2
	var tier_cluster_max := 3
	var tier_pattern_pool: Array[String] = [PATTERN_SMALL_CLUSTER, PATTERN_EDGE_PATCH, PATTERN_CENTER_PATCH]

	match tier:
		DifficultyBudget.TIER_MEDIUM:
			tier_validation_attempts = 25
			tier_cluster_min = 2
			tier_cluster_max = 4
		DifficultyBudget.TIER_HARD:
			tier_validation_attempts = 30
			tier_cluster_min = 3
			tier_cluster_max = 5
			tier_pattern_pool.append(PATTERN_DIAGONAL_BAND)
		DifficultyBudget.TIER_VERY_HARD:
			tier_validation_attempts = 35
			tier_cluster_min = 3
			tier_cluster_max = 6
			tier_pattern_pool.append(PATTERN_DIAGONAL_BAND)
		_:
			tier_validation_attempts = 20
			tier_center_ice_chance = 0.35
			tier_cluster_min = 2
			tier_cluster_max = 3

	var rules := IceGenerationRules.new(
		MIN_ICE_CELLS, MAX_ICE_CELLS, 0, 0.0, tier_cluster_min, tier_cluster_max,
		tier_pattern_pool,
		tier_validation_attempts,
		tier_center_ice_chance,
		ICE_SHAPE_PRESET_SCRIPT.get_center_shape_types(),
		ICE_SHAPE_PRESET_SCRIPT.get_mirrored_block_shape_types(),
		true,
		MAX_ICE_CELLS
	)
	rules.ice_variant = variant if ICE_VARIANT_SCRIPT.is_valid(variant) else ICE_VARIANT_SCRIPT.NONE
	return rules

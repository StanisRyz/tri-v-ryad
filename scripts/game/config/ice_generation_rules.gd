extends RefCounted
class_name IceGenerationRules

## Stage 57 v0.1: rule set for procedural ice (frozen cell) generation. Mirrors
## HoleGenerationRules' shape — a typed, tier-scoped contract that
## IcePatternGenerator/BoardChallengeGenerator build against rather than
## hardcoding per-tier numbers themselves.

const PATTERN_SMALL_CLUSTER := "small_cluster"
const PATTERN_EDGE_PATCH := "edge_patch"
const PATTERN_CENTER_PATCH := "center_patch"
const PATTERN_DIAGONAL_BAND := "diagonal_band"

const DEFAULT_VALIDATION_ATTEMPTS := 20

var min_ice_cells := 3
var max_ice_cells := 6
var max_double_ice_cells := 0
var double_ice_chance := 0.0
var cluster_size_min := 2
var cluster_size_max := 3
var allowed_pattern_types: Array[String] = [PATTERN_SMALL_CLUSTER]
var validation_attempts := DEFAULT_VALIDATION_ATTEMPTS


func _init(
	config_min_ice_cells: int = 3,
	config_max_ice_cells: int = 6,
	config_max_double_ice_cells: int = 0,
	config_double_ice_chance: float = 0.0,
	config_cluster_size_min: int = 2,
	config_cluster_size_max: int = 3,
	config_allowed_pattern_types: Array[String] = [PATTERN_SMALL_CLUSTER],
	config_validation_attempts: int = DEFAULT_VALIDATION_ATTEMPTS
) -> void:
	min_ice_cells = config_min_ice_cells
	max_ice_cells = config_max_ice_cells
	max_double_ice_cells = config_max_double_ice_cells
	double_ice_chance = config_double_ice_chance
	cluster_size_min = config_cluster_size_min
	cluster_size_max = config_cluster_size_max
	allowed_pattern_types = config_allowed_pattern_types.duplicate()
	validation_attempts = config_validation_attempts


static func default_rules() -> IceGenerationRules:
	return IceGenerationRules.new()


## Tier-scoped ice caps: early stays small and single-hit only; medium adds
## more cells and a rare double-ice cell; hard grows both further with a
## real double-ice budget; very_hard is densest but still capped well below
## board saturation. Rules are the single source of truth here — callers
## (IcePatternGenerator, BoardChallengeGenerator) should call this instead of
## hardcoding per-tier numbers themselves.
static func for_tier(tier: String) -> IceGenerationRules:
	match tier:
		DifficultyBudget.TIER_MEDIUM:
			return IceGenerationRules.new(
				5, 9, 1, 0.15, 2, 4,
				[PATTERN_SMALL_CLUSTER, PATTERN_EDGE_PATCH],
				25
			)
		DifficultyBudget.TIER_HARD:
			return IceGenerationRules.new(
				7, 12, 3, 0.30, 3, 5,
				[PATTERN_SMALL_CLUSTER, PATTERN_EDGE_PATCH, PATTERN_CENTER_PATCH],
				30
			)
		DifficultyBudget.TIER_VERY_HARD:
			return IceGenerationRules.new(
				9, 16, 5, 0.45, 3, 6,
				[PATTERN_SMALL_CLUSTER, PATTERN_EDGE_PATCH, PATTERN_CENTER_PATCH, PATTERN_DIAGONAL_BAND],
				35
			)
		_:
			return IceGenerationRules.new(
				3, 6, 0, 0.0, 2, 3,
				[PATTERN_SMALL_CLUSTER],
				20
			)

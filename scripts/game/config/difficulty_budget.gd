extends RefCounted
class_name DifficultyBudget

## Stage 51 v0.1: lightweight difficulty budget for generated challenges.
## Later generators can read ice_density / hole_count / blocker_count /
## validation_attempts / layout_complexity to tune generated boards.

const TIER_EARLY := "early"
const TIER_MEDIUM := "medium"
const TIER_HARD := "hard"
const TIER_VERY_HARD := "very_hard"

var level_number := 1
var difficulty_score := 0.0
var difficulty_tier := TIER_EARLY
var ice_density := 0.0
var hole_count := 0
var blocker_count := 0
var validation_attempts := 20
var layout_complexity := 0.0


func _init(
	config_level_number: int = 1,
	config_difficulty_score: float = 0.0,
	config_difficulty_tier: String = TIER_EARLY,
	config_ice_density: float = 0.0,
	config_hole_count: int = 0,
	config_blocker_count: int = 0,
	config_validation_attempts: int = 20,
	config_layout_complexity: float = 0.0
) -> void:
	level_number = config_level_number
	difficulty_score = config_difficulty_score
	difficulty_tier = config_difficulty_tier
	ice_density = config_ice_density
	hole_count = config_hole_count
	blocker_count = config_blocker_count
	validation_attempts = config_validation_attempts
	layout_complexity = config_layout_complexity

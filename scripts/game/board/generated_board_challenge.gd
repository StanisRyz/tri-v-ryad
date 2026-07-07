extends RefCounted
class_name GeneratedBoardChallenge

## Stage 51 v0.1: data object describing a procedurally generated level
## challenge. Extend this object rather than bolting new fields onto
## BattleState when adding masks, blockers, or per-zone tuning.
## Stage 54 gave `holes` archetype levels a real board_mask; Stage 57 gives
## `ice` archetype levels real frozen_cells (still a full active board_mask).
## `normal` still returns a full active board_mask and empty frozen_cells.

const CHALLENGE_ARCHETYPE_SCRIPT := preload("res://scripts/game/config/challenge_archetype.gd")
const DIFFICULTY_BUDGET_SCRIPT := preload("res://scripts/game/config/difficulty_budget.gd")

var archetype: String = CHALLENGE_ARCHETYPE_SCRIPT.NORMAL
var level_id := ""
var level_number := 1
var difficulty_score := 0.0
var difficulty_tier: String = DIFFICULTY_BUDGET_SCRIPT.TIER_EARLY
var generation_seed := 0
var board_mask: Array = []
var frozen_cells: Array = []
var metadata: Dictionary = {}


func _init(
	config_archetype: String = CHALLENGE_ARCHETYPE_SCRIPT.NORMAL,
	config_level_id: String = "",
	config_level_number: int = 1,
	config_difficulty_score: float = 0.0,
	config_difficulty_tier: String = DIFFICULTY_BUDGET_SCRIPT.TIER_EARLY,
	config_generation_seed: int = 0,
	config_board_mask: Array = [],
	config_frozen_cells: Array = [],
	config_metadata: Dictionary = {}
) -> void:
	archetype = config_archetype
	level_id = config_level_id
	level_number = config_level_number
	difficulty_score = config_difficulty_score
	difficulty_tier = config_difficulty_tier
	generation_seed = config_generation_seed
	board_mask = config_board_mask.duplicate(true)
	frozen_cells = config_frozen_cells.duplicate(true)
	metadata = config_metadata.duplicate(true)


## Stage 54 v0.1: reports active/hole counts out of total board_mask cells,
## and flags when generation fell back to a full board (see
## BoardMaskGenerator/BoardChallengeGenerator metadata["fallback_used"]).
## Stage 57 v0.1: also appends ice/double-ice counts (and an ice fallback
## flag) for an `ice` archetype challenge, e.g.
## "Challenge: ice, seed: 12345, active: 81/81, holes: 0, ice: 12, double: 2".
func get_debug_label() -> String:
	var active_count := _count_active_cells()
	var total_count := _count_total_cells()
	var hole_count := total_count - active_count
	var label := "Challenge: %s, seed: %d, active: %d/%d, holes: %d" % [archetype, generation_seed, active_count, total_count, hole_count]

	if bool(metadata.get("fallback_used", false)):
		label += ", fallback: true"

	if archetype == CHALLENGE_ARCHETYPE_SCRIPT.ICE:
		label += ", ice: %d, double: %d" % [int(metadata.get("ice_cell_count", 0)), int(metadata.get("double_ice_cell_count", 0))]
		if bool(metadata.get("ice_fallback_used", false)):
			label += ", ice_fallback: true"

	return label


func _count_active_cells() -> int:
	var count := 0
	for row in board_mask:
		for value in row:
			if value:
				count += 1
	return count


func _count_total_cells() -> int:
	var count := 0
	for row in board_mask:
		count += (row as Array).size()
	return count

extends RefCounted
class_name GeneratedBoardChallenge

## Stage 51 v0.1: data object describing a procedurally generated level
## challenge. board_mask/frozen_cells are placeholders for this stage (full
## 9x9 active board, no frozen cells) and will carry real hole/ice/blocker
## data in later stages. Extend this object rather than bolting new fields
## onto BattleState when adding masks, blockers, or per-zone tuning.

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


## Stage 52 v0.1: reports active-cell count out of total board_mask cells so
## the debug label reflects real hole counts once later stages generate them.
func get_debug_label() -> String:
	return "Challenge: %s, seed: %d, active: %d/%d" % [archetype, generation_seed, _count_active_cells(), _count_total_cells()]


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

extends RefCounted
class_name DirectBattleBalance

## Stage 60.1 v0.1: fixed baseline for direct-mode battles. Every enemy enters
## a battle with the same HP, and the move count follows a simple linear
## curve that decreases by 1 per level down to a floor. This replaces
## DirectBalanceConfig's per-level HP/moves formulas as the active balance
## source for direct-mode battles; DirectBalanceConfig's damage-related
## helpers are unaffected. Level boosts (color x2, match-size x2/x3, +3
## moves) are intentionally not part of this baseline - BattlePresenter
## applies LevelBoostResolver.apply_moves_bonus() on top of
## get_moves_for_level() at battle start (Stage 60.2), and every level
## resolves to the "none" boost until Stage 60.3 adds the deterministic
## 500-level boost database.

const FIXED_ENEMY_HP := 130
const STARTING_MOVES := 30
const MIN_MOVES := 20


static func get_moves_for_level(level_number: int) -> int:
	var safe_level: int = max(1, level_number)
	return max(MIN_MOVES, STARTING_MOVES + 1 - safe_level)


## Compact dev-facing summary for debug labels/logs. final_moves_before_boosts
## equals base_moves_for_level in Stage 60.1 since level boosts (+3 moves,
## Stage 60.2/60.3) are not implemented yet.
static func get_debug_label(level_number: int) -> String:
	var base_moves := get_moves_for_level(level_number)
	return "enemy_hp: %d, base_moves_for_level: %d, final_moves_before_boosts: %d" % [
		FIXED_ENEMY_HP, base_moves, base_moves,
	]

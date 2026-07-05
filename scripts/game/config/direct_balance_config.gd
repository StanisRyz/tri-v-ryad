extends RefCounted
class_name DirectBalanceConfig

## Stage 34 v0.1: centralizes direct match-3 balance numbers (enemy HP, moves,
## and safety checkpoints) so LevelCatalog/EnemyScalingResolver/tests share one
## source of truth instead of scattering magic numbers. Formulas are
## intentionally linear/stepwise (no pow/exp) and are expected to be re-tuned
## after playtesting.

const LEVEL_LABEL_FORMATTER_SCRIPT := preload("res://scripts/game/config/level_label_formatter.gd")

## Moves curve: forgiving early levels, mild stepwise drop across the campaign.
const MOVES_START := 24
const MOVES_FLOOR := 19

## Expected damage a reasonably played move deals, including occasional
## boosted-color matches from Stage 33 round modifiers. Grows mildly (not
## exponentially) as later levels expect better board play.
const EXPECTED_DAMAGE_BASE := 4.0
const EXPECTED_DAMAGE_STEP := 0.2
const EXPECTED_DAMAGE_STEP_LEVELS := 10.0

## Target enemy HP grows linearly with level. At level 1 (24 moves), required
## damage/move is ~1.7, far below the ~4.0 expected damage/move -- an easy
## clear. At level 100 (19 moves), required damage/move is ~5.2, close to the
## ~5.8 expected damage/move -- harder, but still clearable with good boosted
## color play. This is the main direct-mode difficulty driver.
const HP_TARGET_BASE := 40.0
const HP_TARGET_STEP_PER_LEVEL := 0.6

## Enemy base_hp (from EnemyCatalog) still nudges HP a little so different
## enemies keep some identity, but it is clamped so level number stays the
## dominant difficulty driver.
const BASELINE_BASE_HP := 470.0
const MIN_BASE_HP_FACTOR := 0.85
const MAX_BASE_HP_FACTOR := 1.15

const BALANCE_CHECKPOINT_LEVELS: Array[int] = [1, 5, 10, 20, 30, 50, 75, 100]


static func get_level_number(level_id: String) -> int:
	var level_number := LEVEL_LABEL_FORMATTER_SCRIPT.extract_level_number(level_id)
	return level_number if level_number > 0 else 1


static func get_moves_for_level(level_number: int) -> int:
	var safe_level_number: int = max(1, level_number)
	if safe_level_number <= 10:
		return MOVES_START - int(floor(float(safe_level_number - 1) / 4.0))
	if safe_level_number <= 30:
		return 23 - int(floor(float(safe_level_number - 11) / 7.0))
	if safe_level_number <= 60:
		return 22 - int(floor(float(safe_level_number - 31) / 10.0))
	return max(MOVES_FLOOR, 21 - int(floor(float(safe_level_number - 61) / 14.0)))


static func get_expected_damage_per_move(level_number: int) -> float:
	var safe_level_number: int = max(1, level_number)
	var step_count: float = floor(float(safe_level_number - 1) / EXPECTED_DAMAGE_STEP_LEVELS)
	return EXPECTED_DAMAGE_BASE + step_count * EXPECTED_DAMAGE_STEP


static func get_enemy_hp_for_level(base_hp: int, level_number: int) -> int:
	var safe_level_number: int = max(1, level_number)
	var target_hp: float = HP_TARGET_BASE + HP_TARGET_STEP_PER_LEVEL * float(safe_level_number - 1)

	var safe_base_hp: float = max(1.0, float(base_hp))
	var base_hp_factor: float = clamp(safe_base_hp / BASELINE_BASE_HP, MIN_BASE_HP_FACTOR, MAX_BASE_HP_FACTOR)

	return max(1, int(round(target_hp * base_hp_factor)))


static func get_required_damage_per_move(enemy_hp: int, moves: int) -> float:
	var safe_moves: int = max(1, moves)
	return float(enemy_hp) / float(safe_moves)


static func get_balance_checkpoint_levels() -> Array[int]:
	return BALANCE_CHECKPOINT_LEVELS.duplicate()


static func is_wall_level(level_number: int) -> bool:
	var safe_level_number: int = max(1, level_number)
	return safe_level_number % 10 == 0

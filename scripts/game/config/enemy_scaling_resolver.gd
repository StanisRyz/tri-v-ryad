extends RefCounted
class_name EnemyScalingResolver

const ENEMY_CONFIG_SCRIPT := preload("res://scripts/game/config/enemy_config.gd")
const ENEMY_CATALOG_SCRIPT := preload("res://scripts/game/config/enemy_catalog.gd")
const LEVEL_LABEL_FORMATTER_SCRIPT := preload("res://scripts/game/config/level_label_formatter.gd")
const DIRECT_BALANCE_CONFIG_SCRIPT := preload("res://scripts/game/config/direct_balance_config.gd")

const HP_STEP_PER_LEVEL := 0.014
const ATTACK_STEP_PER_LEVEL := 0.010
const HP_WALL_STEP := 0.015
const ATTACK_WALL_STEP := 0.008


func scale_enemy_for_level(enemy_config, level_config):
	var level_number := 1
	if level_config != null and "level_id" in level_config:
		level_number = LEVEL_LABEL_FORMATTER_SCRIPT.extract_level_number(level_config.level_id)
	return scale_enemy(enemy_config, level_number)


func scale_enemy(enemy_config, level_number: int):
	var base_enemy = enemy_config if enemy_config != null else ENEMY_CATALOG_SCRIPT.new().get_default_enemy()
	var safe_level_number: int = max(1, level_number)

	if not FeatureFlags.HERO_SYSTEMS_ENABLED:
		return _scale_enemy_direct(base_enemy, safe_level_number)

	return _scale_enemy_hero(base_enemy, safe_level_number)


## Stage 34 v0.1: HP is tuned against DirectBalanceConfig's per-level required
## damage curve. Attack is left untouched since enemy actions are neutralized
## in direct mode (BattleResolver skips enemy actions when hero systems are
## frozen), so it must not factor into direct-mode difficulty.
func _scale_enemy_direct(base_enemy, level_number: int):
	var scaled_hp: int = DIRECT_BALANCE_CONFIG_SCRIPT.get_enemy_hp_for_level(base_enemy.max_hp, level_number)

	return ENEMY_CONFIG_SCRIPT.new(
		base_enemy.enemy_id,
		base_enemy.display_name,
		scaled_hp,
		base_enemy.attack,
		base_enemy.intent_turns,
		base_enemy.target_lane
	)


func _scale_enemy_hero(base_enemy, level_number: int):
	var hp_multiplier := get_hp_multiplier(level_number)
	var attack_multiplier := get_attack_multiplier(level_number)
	var scaled_hp: int = max(1, int(round(float(base_enemy.max_hp) * hp_multiplier)))
	var scaled_attack: int = max(1, int(round(float(base_enemy.attack) * attack_multiplier)))

	return ENEMY_CONFIG_SCRIPT.new(
		base_enemy.enemy_id,
		base_enemy.display_name,
		scaled_hp,
		scaled_attack,
		base_enemy.intent_turns,
		base_enemy.target_lane
	)


func get_hp_multiplier(level_number: int) -> float:
	var safe_level_number: int = max(1, level_number)
	return 1.0 + float(safe_level_number - 1) * HP_STEP_PER_LEVEL + get_wall_level_bonus(safe_level_number) * HP_WALL_STEP


func get_attack_multiplier(level_number: int) -> float:
	var safe_level_number: int = max(1, level_number)
	return 1.0 + float(safe_level_number - 1) * ATTACK_STEP_PER_LEVEL + get_wall_level_bonus(safe_level_number) * ATTACK_WALL_STEP


func get_wall_level_bonus(level_number: int) -> float:
	var safe_level_number: int = max(1, level_number)
	return floor(float(safe_level_number) / 10.0)

extends RefCounted
class_name UpgradeEconomyConfig

const ATTACK_BASE_COST := 1
const ATTACK_COST_STEP := 1
const HP_BASE_COST := 1
const HP_COST_STEP := 1

const ATTACK_GROWTH_PER_LEVEL := 2
const HP_GROWTH_PER_LEVEL := 10

const MAX_ATTACK_LEVEL := 20
const MAX_HP_LEVEL := 20

const LEVEL_REWARD_BASE := 1
const LEVEL_REWARD_STEP := 8
const LEVEL_WALL_REWARD_STEP := 1
const LEVEL_REWARD_MAX := 23


static func get_attack_upgrade_cost(attack_level: int) -> int:
	return max(0, ATTACK_BASE_COST + max(0, attack_level) * ATTACK_COST_STEP)


static func get_hp_upgrade_cost(hp_level: int) -> int:
	return max(0, HP_BASE_COST + max(0, hp_level) * HP_COST_STEP)


static func get_attack_for_level(base_attack: int, attack_level: int) -> int:
	var effective_level: int = clampi(attack_level, 0, MAX_ATTACK_LEVEL)
	return max(0, base_attack + effective_level * ATTACK_GROWTH_PER_LEVEL)


static func get_max_hp_for_level(base_max_hp: int, hp_level: int) -> int:
	var effective_level: int = clampi(hp_level, 0, MAX_HP_LEVEL)
	return max(1, base_max_hp + effective_level * HP_GROWTH_PER_LEVEL)


static func get_level_reward(level_number: int) -> int:
	var safe_level_number: int = max(1, level_number)
	var linear_bonus := int(floor(float(safe_level_number - 1) / float(LEVEL_REWARD_STEP)))
	var wall_bonus := int(floor(float(safe_level_number) / 10.0)) * LEVEL_WALL_REWARD_STEP
	return clampi(LEVEL_REWARD_BASE + linear_bonus + wall_bonus, 0, LEVEL_REWARD_MAX)

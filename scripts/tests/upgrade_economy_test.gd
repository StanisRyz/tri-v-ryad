extends SceneTree

const ECONOMY_CONFIG := preload("res://scripts/game/progression/upgrade_economy_config.gd")
const PLAYER_PROGRESS_SCRIPT := "res://scripts/game/progression/player_progress.gd"
const UPGRADE_RESOLVER_SCRIPT := "res://scripts/game/progression/upgrade_resolver.gd"
const HERO_DATA_SCRIPT := "res://scripts/game/battle/hero_data.gd"

var _failures := 0


func _initialize() -> void:
	print("Running upgrade economy tests...")

	var resolver = load(UPGRADE_RESOLVER_SCRIPT).new()
	_test_attack_upgrade_cost_is_linear()
	_test_hp_upgrade_cost_is_linear()
	_test_attack_stat_growth_is_linear()
	_test_hp_stat_growth_is_linear()
	_test_spending_and_single_stat_mutation(resolver)
	_test_insufficient_points_rejects(resolver)
	_test_max_attack_level_is_enforced(resolver)
	_test_max_hp_level_is_enforced(resolver)
	_test_invalid_inputs_reject(resolver)
	_test_no_negative_costs_or_growth()

	if _failures == 0:
		print("Upgrade economy tests passed.")
		quit(0)
	else:
		push_error("Upgrade economy tests failed: %d" % _failures)
		quit(1)


func _test_attack_upgrade_cost_is_linear() -> void:
	var level_0_cost := ECONOMY_CONFIG.get_attack_upgrade_cost(0)
	var level_1_cost := ECONOMY_CONFIG.get_attack_upgrade_cost(1)
	var level_8_cost := ECONOMY_CONFIG.get_attack_upgrade_cost(8)
	var level_9_cost := ECONOMY_CONFIG.get_attack_upgrade_cost(9)
	_expect_equal(level_0_cost, ECONOMY_CONFIG.ATTACK_BASE_COST, "attack base cost")
	_expect_equal(level_1_cost - level_0_cost, ECONOMY_CONFIG.ATTACK_COST_STEP, "attack first cost step")
	_expect_equal(level_9_cost - level_8_cost, ECONOMY_CONFIG.ATTACK_COST_STEP, "attack later cost step")
	print("ok - attack upgrade cost is linear")


func _test_hp_upgrade_cost_is_linear() -> void:
	var level_0_cost := ECONOMY_CONFIG.get_hp_upgrade_cost(0)
	var level_1_cost := ECONOMY_CONFIG.get_hp_upgrade_cost(1)
	var level_8_cost := ECONOMY_CONFIG.get_hp_upgrade_cost(8)
	var level_9_cost := ECONOMY_CONFIG.get_hp_upgrade_cost(9)
	_expect_equal(level_0_cost, ECONOMY_CONFIG.HP_BASE_COST, "hp base cost")
	_expect_equal(level_1_cost - level_0_cost, ECONOMY_CONFIG.HP_COST_STEP, "hp first cost step")
	_expect_equal(level_9_cost - level_8_cost, ECONOMY_CONFIG.HP_COST_STEP, "hp later cost step")
	print("ok - hp upgrade cost is linear")


func _test_attack_stat_growth_is_linear() -> void:
	var hero = load(HERO_DATA_SCRIPT).new("hero", "Hero", 0, 10, 100, 0, 0)
	hero.attack_level = 1
	var level_1_attack: int = hero.get_attack()
	hero.attack_level = 2
	var level_2_attack: int = hero.get_attack()
	hero.attack_level = 9
	var level_9_attack: int = hero.get_attack()
	hero.attack_level = 10
	var level_10_attack: int = hero.get_attack()
	_expect_equal(level_1_attack, 10 + ECONOMY_CONFIG.ATTACK_GROWTH_PER_LEVEL, "attack level 1 growth")
	_expect_equal(level_2_attack - level_1_attack, ECONOMY_CONFIG.ATTACK_GROWTH_PER_LEVEL, "attack first growth step")
	_expect_equal(level_10_attack - level_9_attack, ECONOMY_CONFIG.ATTACK_GROWTH_PER_LEVEL, "attack later growth step")
	print("ok - attack stat growth is linear")


func _test_hp_stat_growth_is_linear() -> void:
	var hero = load(HERO_DATA_SCRIPT).new("hero", "Hero", 0, 10, 100, 0, 0)
	hero.hp_level = 1
	var level_1_hp: int = hero.get_max_hp()
	hero.hp_level = 2
	var level_2_hp: int = hero.get_max_hp()
	hero.hp_level = 9
	var level_9_hp: int = hero.get_max_hp()
	hero.hp_level = 10
	var level_10_hp: int = hero.get_max_hp()
	_expect_equal(level_1_hp, 100 + ECONOMY_CONFIG.HP_GROWTH_PER_LEVEL, "hp level 1 growth")
	_expect_equal(level_2_hp - level_1_hp, ECONOMY_CONFIG.HP_GROWTH_PER_LEVEL, "hp first growth step")
	_expect_equal(level_10_hp - level_9_hp, ECONOMY_CONFIG.HP_GROWTH_PER_LEVEL, "hp later growth step")
	print("ok - hp stat growth is linear")


func _test_spending_and_single_stat_mutation(resolver) -> void:
	var progress = load(PLAYER_PROGRESS_SCRIPT).create_default()
	progress.upgrade_points = 10
	var attack_result: Dictionary = resolver.upgrade_with_result(progress, "hero_1", "attack")
	_expect_true(attack_result["accepted"], "attack upgrade accepted")
	_expect_equal(int(attack_result["cost"]), ECONOMY_CONFIG.ATTACK_BASE_COST, "attack upgrade reports exact cost")
	_expect_equal(progress.upgrade_points, 9, "attack upgrade subtracts exact cost")
	_expect_equal(progress.get_hero_upgrade("hero_1").attack_level, 1, "attack level increased")
	_expect_equal(progress.get_hero_upgrade("hero_1").hp_level, 0, "hp level unchanged")

	var next_hp_cost := ECONOMY_CONFIG.get_hp_upgrade_cost(0)
	var hp_result: Dictionary = resolver.upgrade_with_result(progress, "hero_1", "hp")
	_expect_true(hp_result["accepted"], "hp upgrade accepted")
	_expect_equal(int(hp_result["cost"]), next_hp_cost, "hp upgrade reports exact cost")
	_expect_equal(progress.upgrade_points, 9 - next_hp_cost, "hp upgrade subtracts exact cost")
	_expect_equal(progress.get_hero_upgrade("hero_1").attack_level, 1, "attack level unchanged after hp upgrade")
	_expect_equal(progress.get_hero_upgrade("hero_1").hp_level, 1, "hp level increased")
	print("ok - spending is exact and mutates only requested stat")


func _test_insufficient_points_rejects(resolver) -> void:
	var progress = load(PLAYER_PROGRESS_SCRIPT).create_default()
	progress.upgrade_points = ECONOMY_CONFIG.get_attack_upgrade_cost(0) - 1
	var result: Dictionary = resolver.upgrade_with_result(progress, "hero_1", "attack")
	_expect_false(result["accepted"], "insufficient points rejected")
	_expect_equal(result["reason"], "not_enough_points", "insufficient points reason")
	_expect_equal(progress.get_hero_upgrade("hero_1").attack_level, 0, "insufficient points does not mutate")
	print("ok - insufficient points reject upgrade")


func _test_max_attack_level_is_enforced(resolver) -> void:
	var progress = load(PLAYER_PROGRESS_SCRIPT).create_default()
	progress.upgrade_points = 999
	progress.get_hero_upgrade("hero_1").attack_level = ECONOMY_CONFIG.MAX_ATTACK_LEVEL
	var result: Dictionary = resolver.upgrade_with_result(progress, "hero_1", "attack")
	_expect_false(result["accepted"], "max attack level rejected")
	_expect_equal(result["reason"], "max_level", "max attack level reason")
	_expect_equal(progress.get_hero_upgrade("hero_1").attack_level, ECONOMY_CONFIG.MAX_ATTACK_LEVEL, "max attack level unchanged")
	print("ok - max attack level is enforced")


func _test_max_hp_level_is_enforced(resolver) -> void:
	var progress = load(PLAYER_PROGRESS_SCRIPT).create_default()
	progress.upgrade_points = 999
	progress.get_hero_upgrade("hero_1").hp_level = ECONOMY_CONFIG.MAX_HP_LEVEL
	var result: Dictionary = resolver.upgrade_with_result(progress, "hero_1", "hp")
	_expect_false(result["accepted"], "max hp level rejected")
	_expect_equal(result["reason"], "max_level", "max hp level reason")
	_expect_equal(progress.get_hero_upgrade("hero_1").hp_level, ECONOMY_CONFIG.MAX_HP_LEVEL, "max hp level unchanged")
	print("ok - max hp level is enforced")


func _test_invalid_inputs_reject(resolver) -> void:
	var progress = load(PLAYER_PROGRESS_SCRIPT).create_default()
	progress.upgrade_points = 999
	var invalid_hero_result: Dictionary = resolver.upgrade_with_result(progress, "", "attack")
	var invalid_type_result: Dictionary = resolver.upgrade_with_result(progress, "hero_1", "speed")
	_expect_false(invalid_hero_result["accepted"], "invalid hero rejected")
	_expect_equal(invalid_hero_result["reason"], "invalid_hero", "invalid hero reason")
	_expect_false(invalid_type_result["accepted"], "invalid upgrade type rejected")
	_expect_equal(invalid_type_result["reason"], "invalid_upgrade_type", "invalid upgrade type reason")
	print("ok - invalid inputs reject")


func _test_no_negative_costs_or_growth() -> void:
	_expect_true(ECONOMY_CONFIG.ATTACK_GROWTH_PER_LEVEL > 0, "attack growth is positive")
	_expect_true(ECONOMY_CONFIG.HP_GROWTH_PER_LEVEL > 0, "hp growth is positive")
	for level in range(0, ECONOMY_CONFIG.MAX_ATTACK_LEVEL + 1):
		_expect_true(ECONOMY_CONFIG.get_attack_upgrade_cost(level) > 0, "attack cost level %d is positive" % level)
	for level in range(0, ECONOMY_CONFIG.MAX_HP_LEVEL + 1):
		_expect_true(ECONOMY_CONFIG.get_hp_upgrade_cost(level) > 0, "hp cost level %d is positive" % level)
	print("ok - costs and stat growth stay positive")


func _expect_true(value: bool, message: String) -> void:
	if value:
		return

	_failures += 1
	push_error("FAILED: %s" % message)


func _expect_false(value: bool, message: String) -> void:
	_expect_true(not value, message)


func _expect_equal(actual, expected, message: String) -> void:
	if actual == expected:
		return

	_failures += 1
	push_error("FAILED: %s | expected=%s actual=%s" % [message, expected, actual])

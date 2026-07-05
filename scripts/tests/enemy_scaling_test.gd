extends SceneTree

const ENEMY_CATALOG_SCRIPT := "res://scripts/game/config/enemy_catalog.gd"
const ENEMY_SCALING_RESOLVER_SCRIPT := "res://scripts/game/config/enemy_scaling_resolver.gd"
const LEVEL_CATALOG_SCRIPT := "res://scripts/game/config/level_catalog.gd"
const LEVEL_CONFIG_SCRIPT := "res://scripts/game/config/level_config.gd"

var _failures := 0


func _initialize() -> void:
	print("Running enemy scaling tests...")

	var catalog = load(ENEMY_CATALOG_SCRIPT).new()
	var resolver = load(ENEMY_SCALING_RESOLVER_SCRIPT).new()
	var base_enemy = catalog.get_enemy("gatekeeper")
	_test_level_one_keeps_base_stats(resolver, base_enemy)
	_test_stats_grow_across_campaign(resolver, base_enemy)
	_test_multipliers_are_linear(resolver)
	_test_scaled_values_are_positive(resolver, base_enemy)
	_test_identity_and_intent_are_preserved(resolver, base_enemy)
	_test_base_enemy_is_not_mutated(resolver, base_enemy)
	_test_malformed_level_id_uses_level_one(resolver, base_enemy)
	_test_null_enemy_uses_default(resolver, catalog)
	_test_wall_bonus_is_mild_and_deterministic(resolver)

	if _failures == 0:
		print("Enemy scaling tests passed.")
		quit(0)
	else:
		push_error("Enemy scaling tests failed: %d" % _failures)
		quit(1)


func _test_level_one_keeps_base_stats(resolver, base_enemy) -> void:
	var scaled = resolver.scale_enemy(base_enemy, 1)
	_expect_equal(scaled.max_hp, base_enemy.max_hp, "level 1 hp matches base")
	_expect_equal(scaled.attack, base_enemy.attack, "level 1 attack matches base")
	print("ok - level 1 scaling keeps base stats")


func _test_stats_grow_across_campaign(resolver, base_enemy) -> void:
	var level_1 = resolver.scale_enemy(base_enemy, 1)
	var level_10 = resolver.scale_enemy(base_enemy, 10)
	var level_50 = resolver.scale_enemy(base_enemy, 50)
	var level_100 = resolver.scale_enemy(base_enemy, 100)
	_expect_true(level_10.max_hp > level_1.max_hp, "level 10 hp grows")
	_expect_true(level_10.attack > level_1.attack, "level 10 attack grows")
	_expect_true(level_50.max_hp > level_10.max_hp, "level 50 hp grows")
	_expect_true(level_50.attack > level_10.attack, "level 50 attack grows")
	_expect_true(level_100.max_hp > level_50.max_hp, "level 100 hp grows")
	_expect_true(level_100.attack > level_50.attack, "level 100 attack grows")
	print("ok - enemy stats grow from level 1 to level 100")


func _test_multipliers_are_linear(resolver) -> void:
	var hp_delta_2_to_3: float = resolver.get_hp_multiplier(3) - resolver.get_hp_multiplier(2)
	var hp_delta_7_to_8: float = resolver.get_hp_multiplier(8) - resolver.get_hp_multiplier(7)
	var attack_delta_2_to_3: float = resolver.get_attack_multiplier(3) - resolver.get_attack_multiplier(2)
	var attack_delta_7_to_8: float = resolver.get_attack_multiplier(8) - resolver.get_attack_multiplier(7)
	_expect_nearly_equal(hp_delta_2_to_3, hp_delta_7_to_8, 0.0001, "hp non-wall deltas are linear")
	_expect_nearly_equal(attack_delta_2_to_3, attack_delta_7_to_8, 0.0001, "attack non-wall deltas are linear")
	print("ok - multiplier deltas are linear between non-wall levels")


func _test_scaled_values_are_positive(resolver, base_enemy) -> void:
	for level_number in [0, -5, 1, 10, 50, 100]:
		var scaled = resolver.scale_enemy(base_enemy, level_number)
		_expect_true(scaled.max_hp > 0, "level %s hp stays positive" % level_number)
		_expect_true(scaled.attack > 0, "level %s attack stays positive" % level_number)
	print("ok - scaled hp and attack stay positive")


func _test_identity_and_intent_are_preserved(resolver, base_enemy) -> void:
	var scaled = resolver.scale_enemy(base_enemy, 100)
	_expect_equal(scaled.enemy_id, base_enemy.enemy_id, "enemy id is preserved")
	_expect_equal(scaled.display_name, base_enemy.display_name, "display name is preserved")
	_expect_equal(scaled.intent_turns, base_enemy.intent_turns, "intent turns are preserved")
	_expect_equal(scaled.target_lane, base_enemy.target_lane, "target lane is preserved")
	print("ok - scaling preserves enemy identity and intent")


func _test_base_enemy_is_not_mutated(resolver, base_enemy) -> void:
	var original_hp: int = base_enemy.max_hp
	var original_attack: int = base_enemy.attack
	var original_intent_turns: int = base_enemy.intent_turns
	var original_target_lane: int = base_enemy.target_lane
	var scaled = resolver.scale_enemy(base_enemy, 100)
	_expect_true(scaled != base_enemy, "scaling returns a separate config")
	_expect_equal(base_enemy.max_hp, original_hp, "base hp is unchanged")
	_expect_equal(base_enemy.attack, original_attack, "base attack is unchanged")
	_expect_equal(base_enemy.intent_turns, original_intent_turns, "base intent turns are unchanged")
	_expect_equal(base_enemy.target_lane, original_target_lane, "base target lane is unchanged")
	print("ok - base enemy config is not mutated")


func _test_malformed_level_id_uses_level_one(resolver, base_enemy) -> void:
	var malformed_level = load(LEVEL_CONFIG_SCRIPT).new("not_a_level", "Bad Level", base_enemy, 20, [], 0)
	var scaled = resolver.scale_enemy_for_level(base_enemy, malformed_level)
	_expect_equal(scaled.max_hp, base_enemy.max_hp, "malformed level id hp uses level 1")
	_expect_equal(scaled.attack, base_enemy.attack, "malformed level id attack uses level 1")
	print("ok - malformed level ids scale as level 1")


func _test_null_enemy_uses_default(resolver, catalog) -> void:
	var scaled = resolver.scale_enemy(null, 1)
	_expect_equal(scaled.enemy_id, catalog.get_default_enemy().enemy_id, "null enemy uses default enemy")
	_expect_equal(scaled.max_hp, catalog.get_default_enemy().max_hp, "null enemy default hp at level 1")
	print("ok - null enemy uses safe default")


func _test_wall_bonus_is_mild_and_deterministic(resolver) -> void:
	var first_wall_bonus: float = resolver.get_wall_level_bonus(10)
	var second_wall_bonus: float = resolver.get_wall_level_bonus(10)
	var hp_delta_8_to_9: float = resolver.get_hp_multiplier(9) - resolver.get_hp_multiplier(8)
	var hp_delta_9_to_10: float = resolver.get_hp_multiplier(10) - resolver.get_hp_multiplier(9)
	var hp_delta_99_to_100: float = resolver.get_hp_multiplier(100) - resolver.get_hp_multiplier(99)
	var attack_delta_8_to_9: float = resolver.get_attack_multiplier(9) - resolver.get_attack_multiplier(8)
	var attack_delta_9_to_10: float = resolver.get_attack_multiplier(10) - resolver.get_attack_multiplier(9)
	var attack_delta_99_to_100: float = resolver.get_attack_multiplier(100) - resolver.get_attack_multiplier(99)
	_expect_equal(first_wall_bonus, second_wall_bonus, "wall bonus is deterministic")
	_expect_true(hp_delta_9_to_10 > hp_delta_8_to_9, "level 10 hp has a small wall bump")
	_expect_true(attack_delta_9_to_10 > attack_delta_8_to_9, "level 10 attack has a small wall bump")
	_expect_true(hp_delta_9_to_10 < 0.05, "level 9 to 10 hp bump is mild")
	_expect_true(attack_delta_9_to_10 < 0.03, "level 9 to 10 attack bump is mild")
	_expect_true(hp_delta_99_to_100 < 0.05, "level 99 to 100 hp bump is mild")
	_expect_true(attack_delta_99_to_100 < 0.03, "level 99 to 100 attack bump is mild")
	print("ok - wall-level bonus is mild and deterministic")


func _expect_true(value: bool, message: String) -> void:
	if value:
		return

	_failures += 1
	push_error("FAILED: %s" % message)


func _expect_equal(actual, expected, message: String) -> void:
	if actual == expected:
		return

	_failures += 1
	push_error("FAILED: %s | expected=%s actual=%s" % [message, expected, actual])


func _expect_nearly_equal(actual: float, expected: float, tolerance: float, message: String) -> void:
	if abs(actual - expected) <= tolerance:
		return

	_failures += 1
	push_error("FAILED: %s | expected=%s actual=%s tolerance=%s" % [message, expected, actual, tolerance])

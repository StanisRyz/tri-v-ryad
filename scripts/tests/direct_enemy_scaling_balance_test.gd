extends SceneTree

const ENEMY_CATALOG_SCRIPT := "res://scripts/game/config/enemy_catalog.gd"
const ENEMY_SCALING_RESOLVER_SCRIPT := "res://scripts/game/config/enemy_scaling_resolver.gd"
const DIRECT_BALANCE_CONFIG_SCRIPT := "res://scripts/game/config/direct_balance_config.gd"
const LEVEL_CATALOG_SCRIPT := "res://scripts/game/config/level_catalog.gd"

var _failures := 0


func _initialize() -> void:
	print("Running direct enemy scaling balance tests...")

	_test_hero_systems_frozen()
	_test_scaled_hp_matches_direct_balance_config()
	_test_scaled_hp_positive_for_all_roster_enemies()
	_test_enemy_roster_unchanged()
	_test_enemy_catalog_base_stats_not_mutated()
	_test_checkpoint_hp_is_safe()

	if _failures == 0:
		print("Direct enemy scaling balance tests passed.")
		quit(0)
	else:
		push_error("Direct enemy scaling balance tests failed: %d" % _failures)
		quit(1)


func _test_hero_systems_frozen() -> void:
	_expect_true(not FeatureFlags.HERO_SYSTEMS_ENABLED, "hero systems remain frozen so enemy scaling uses direct mode")
	print("ok - hero systems remain frozen for direct enemy scaling")


func _test_scaled_hp_matches_direct_balance_config() -> void:
	var resolver = load(ENEMY_SCALING_RESOLVER_SCRIPT).new()
	var catalog = load(ENEMY_CATALOG_SCRIPT).new()
	var base_enemy = catalog.get_enemy("gatekeeper")

	for level_number in [1, 10, 50, 100]:
		var scaled = resolver.scale_enemy(base_enemy, level_number)
		var expected_hp: int = load(DIRECT_BALANCE_CONFIG_SCRIPT).get_enemy_hp_for_level(base_enemy.max_hp, level_number)
		_expect_equal(scaled.max_hp, expected_hp, "level %d scaled hp matches DirectBalanceConfig" % level_number)
	print("ok - EnemyScalingResolver delegates direct-mode hp to DirectBalanceConfig")


func _test_scaled_hp_positive_for_all_roster_enemies() -> void:
	var resolver = load(ENEMY_SCALING_RESOLVER_SCRIPT).new()
	var catalog = load(ENEMY_CATALOG_SCRIPT).new()

	for enemy_config in catalog.get_all_enemies():
		for level_number in [1, 50, 100]:
			var scaled = resolver.scale_enemy(enemy_config, level_number)
			_expect_true(scaled.max_hp > 0, "%s stays positive hp at level %d" % [enemy_config.enemy_id, level_number])
	print("ok - every roster enemy scales to a positive hp across the campaign")


func _test_enemy_roster_unchanged() -> void:
	var catalog = load(ENEMY_CATALOG_SCRIPT).new()
	var expected_ids := [
		"training_dummy", "small_slime", "goblin_scout", "goblin_fighter", "armored_goblin",
		"wild_wolf", "bandit", "orc_brute", "cave_shaman", "gatekeeper",
	]
	_expect_equal(catalog.get_all_enemies().size(), expected_ids.size(), "enemy roster size is unchanged")
	for enemy_id in expected_ids:
		_expect_true(catalog.has_enemy(enemy_id), "roster still contains %s" % enemy_id)
	print("ok - enemy roster is unchanged by the balance pass")


func _test_enemy_catalog_base_stats_not_mutated() -> void:
	var resolver = load(ENEMY_SCALING_RESOLVER_SCRIPT).new()
	var catalog = load(ENEMY_CATALOG_SCRIPT).new()
	var base_enemy = catalog.get_enemy("training_dummy")
	var original_hp: int = base_enemy.max_hp
	var original_attack: int = base_enemy.attack

	resolver.scale_enemy(base_enemy, 100)

	_expect_equal(base_enemy.max_hp, original_hp, "EnemyCatalog base hp is not mutated by scaling")
	_expect_equal(base_enemy.attack, original_attack, "EnemyCatalog base attack is not mutated by scaling")
	print("ok - EnemyCatalog base stats stay untouched after scaling")


func _test_checkpoint_hp_is_safe() -> void:
	var resolver = load(ENEMY_SCALING_RESOLVER_SCRIPT).new()
	var level_catalog = load(LEVEL_CATALOG_SCRIPT).new()
	var enemy_catalog = load(ENEMY_CATALOG_SCRIPT).new()
	var checkpoints: Array[int] = load(DIRECT_BALANCE_CONFIG_SCRIPT).get_balance_checkpoint_levels()

	for level_number in checkpoints:
		var level_config = level_catalog.get_level("level_%d" % level_number)
		var base_enemy = enemy_catalog.get_default_enemy()
		var scaled = resolver.scale_enemy_for_level(base_enemy, level_config)
		var required: float = load(DIRECT_BALANCE_CONFIG_SCRIPT).get_required_damage_per_move(scaled.max_hp, level_config.moves)
		var expected_damage: float = load(DIRECT_BALANCE_CONFIG_SCRIPT).get_expected_damage_per_move(level_number)
		_expect_true(required <= expected_damage, "checkpoint level %d required damage stays at or below expected damage" % level_number)
	print("ok - checkpoint levels stay within safe required-damage range")


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

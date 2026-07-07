extends SceneTree

const LEVEL_CATALOG_SCRIPT := "res://scripts/game/config/level_catalog.gd"
const DIRECT_BATTLE_BALANCE_SCRIPT := "res://scripts/game/config/direct_battle_balance.gd"
const DIRECT_BALANCE_CONFIG_SCRIPT := "res://scripts/game/config/direct_balance_config.gd"
const ENEMY_SCALING_RESOLVER_SCRIPT := "res://scripts/game/config/enemy_scaling_resolver.gd"
const ENEMY_CATALOG_SCRIPT := "res://scripts/game/config/enemy_catalog.gd"

var _failures := 0


func _initialize() -> void:
	print("Running direct level balance tests...")

	var catalog = load(LEVEL_CATALOG_SCRIPT).new()
	_test_moves_delegate_to_direct_battle_balance(catalog)
	_test_level_count_and_ids_unchanged(catalog)
	_test_checkpoint_levels_are_safe(catalog)
	_test_early_levels_forgiving(catalog)
	_test_late_levels_harder_but_plausible(catalog)

	if _failures == 0:
		print("Direct level balance tests passed.")
		quit(0)
	else:
		push_error("Direct level balance tests failed: %d" % _failures)
		quit(1)


## Stage 60.1 v0.1: LevelCatalog moves now delegate to DirectBattleBalance's
## fixed linear curve (30 at level 1, down to a floor of 20) instead of
## DirectBalanceConfig's old stepwise curve.
func _test_moves_delegate_to_direct_battle_balance(catalog) -> void:
	for level_number in [1, 10, 50, 100]:
		var level_config = catalog.get_level("level_%d" % level_number)
		var expected_moves: int = load(DIRECT_BATTLE_BALANCE_SCRIPT).get_moves_for_level(level_number)
		_expect_equal(level_config.moves, expected_moves, "level_%d moves match DirectBattleBalance" % level_number)
	_expect_equal(catalog.get_level("level_1").moves, 30, "level_1 starts at 30 moves")
	_expect_equal(catalog.get_level("level_2").moves, 29, "level_2 has 29 moves")
	_expect_equal(catalog.get_level("level_3").moves, 28, "level_3 has 28 moves")
	_expect_equal(catalog.get_level("level_100").moves, 20, "level_100 is floored at 20 moves")
	print("ok - LevelCatalog moves delegate to DirectBattleBalance")


func _test_level_count_and_ids_unchanged(catalog) -> void:
	_expect_equal(catalog.get_all_levels().size(), 100, "catalog still returns exactly 100 levels")
	_expect_true(catalog.has_level("level_1"), "level_1 still exists")
	_expect_true(catalog.has_level("level_100"), "level_100 still exists")
	_expect_false(catalog.has_level("level_101"), "level_101 still does not exist")
	for level_number in range(1, 101):
		var level_config = catalog.get_level("level_%d" % level_number)
		_expect_equal(level_config.display_name, "Level %d" % level_number, "level_%d keeps numbers-only display name" % level_number)
	print("ok - 100 levels with level_1..level_100 ids remain intact")


func _test_checkpoint_levels_are_safe(catalog) -> void:
	var checkpoints: Array[int] = load(DIRECT_BALANCE_CONFIG_SCRIPT).get_balance_checkpoint_levels()
	var enemy_catalog = load(ENEMY_CATALOG_SCRIPT).new()
	var resolver = load(ENEMY_SCALING_RESOLVER_SCRIPT).new()

	for level_number in checkpoints:
		var level_config = catalog.get_level("level_%d" % level_number)
		_expect_true(level_config.moves > 0, "checkpoint level %d has positive moves" % level_number)

		var base_enemy = enemy_catalog.get_default_enemy()
		var scaled_enemy = resolver.scale_enemy_for_level(base_enemy, level_config)
		_expect_true(scaled_enemy.max_hp > 0, "checkpoint level %d scaled enemy hp is positive" % level_number)

		var required: float = load(DIRECT_BALANCE_CONFIG_SCRIPT).get_required_damage_per_move(scaled_enemy.max_hp, level_config.moves)
		_expect_true(required > 0.0, "checkpoint level %d required damage per move is positive" % level_number)
	print("ok - checkpoint levels have valid moves, enemy hp, and required damage")


func _test_early_levels_forgiving(catalog) -> void:
	var level_1 = catalog.get_level("level_1")
	var level_10 = catalog.get_level("level_10")
	_expect_true(level_1.moves >= level_10.moves, "level 1 gives at least as many moves as level 10")
	print("ok - early levels stay forgiving on moves")


func _test_late_levels_harder_but_plausible(catalog) -> void:
	var level_1 = catalog.get_level("level_1")
	var level_100 = catalog.get_level("level_100")
	_expect_true(level_1.moves >= level_100.moves, "level 100 is not more forgiving on moves than level 1")
	_expect_true(level_100.moves >= 15, "level 100 moves stay plausible, not absurdly low")
	print("ok - level 100 is harder than level 1 but still plausible")


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

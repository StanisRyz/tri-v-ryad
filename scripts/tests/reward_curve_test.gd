extends SceneTree

const LEVEL_CATALOG := preload("res://scripts/game/config/level_catalog.gd")
const ECONOMY_CONFIG := preload("res://scripts/game/progression/upgrade_economy_config.gd")

var _failures := 0


func _initialize() -> void:
	print("Running reward curve tests...")

	var catalog := LEVEL_CATALOG.new()
	_test_all_rewards_are_valid(catalog)
	_test_rewards_are_deterministic()
	_test_rewards_grow_gradually(catalog)
	_test_wall_rewards_are_mild(catalog)
	_test_reward_range_stays_safe(catalog)

	if _failures == 0:
		print("Reward curve tests passed.")
		quit(0)
	else:
		push_error("Reward curve tests failed: %d" % _failures)
		quit(1)


func _test_all_rewards_are_valid(catalog) -> void:
	var levels: Array = catalog.get_all_levels()
	_expect_equal(levels.size(), 100, "catalog has 100 levels")
	for level_config in levels:
		_expect_true(level_config.reward_upgrade_points >= 0, "%s reward is non-negative" % level_config.level_id)
	print("ok - all rewards are valid")


func _test_rewards_are_deterministic() -> void:
	var first_catalog := LEVEL_CATALOG.new()
	var second_catalog := LEVEL_CATALOG.new()
	for level_number in range(1, 101):
		var level_id := "level_%d" % level_number
		_expect_equal(
			first_catalog.get_level(level_id).reward_upgrade_points,
			second_catalog.get_level(level_id).reward_upgrade_points,
			"%s reward is deterministic" % level_id
		)
	print("ok - rewards are deterministic")


func _test_rewards_grow_gradually(catalog) -> void:
	var level_1 = catalog.get_level("level_1")
	var level_100 = catalog.get_level("level_100")
	_expect_true(level_100.reward_upgrade_points >= level_1.reward_upgrade_points, "level 100 reward is at least level 1 reward")
	for level_number in range(2, 101):
		var previous_reward: int = catalog.get_level("level_%d" % (level_number - 1)).reward_upgrade_points
		var current_reward: int = catalog.get_level("level_%d" % level_number).reward_upgrade_points
		_expect_true(current_reward >= previous_reward, "level %d reward does not decrease" % level_number)
		_expect_true(current_reward - previous_reward <= 2, "level %d reward has no large spike" % level_number)
	print("ok - rewards grow gradually")


func _test_wall_rewards_are_mild(catalog) -> void:
	for level_number in range(10, 101, 10):
		var previous_reward: int = catalog.get_level("level_%d" % (level_number - 1)).reward_upgrade_points
		var wall_reward: int = catalog.get_level("level_%d" % level_number).reward_upgrade_points
		_expect_true(wall_reward >= previous_reward, "level %d wall reward is not lower" % level_number)
		_expect_true(wall_reward - previous_reward <= 2, "level %d wall reward bonus is mild" % level_number)
	print("ok - wall rewards are mild")


func _test_reward_range_stays_safe(catalog) -> void:
	_expect_equal(catalog.get_level("level_1").reward_upgrade_points, ECONOMY_CONFIG.LEVEL_REWARD_BASE, "level 1 reward uses base")
	_expect_equal(catalog.get_level("level_100").reward_upgrade_points, ECONOMY_CONFIG.LEVEL_REWARD_MAX, "level 100 reward reaches documented max")
	for level_config in catalog.get_all_levels():
		_expect_true(level_config.reward_upgrade_points <= ECONOMY_CONFIG.LEVEL_REWARD_MAX, "%s reward is within max" % level_config.level_id)
	print("ok - reward range stays within documented safe bounds")


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

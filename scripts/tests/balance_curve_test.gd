extends SceneTree

const LEVEL_CATALOG_SCRIPT := "res://scripts/game/config/level_catalog.gd"

const EXPECTED_LEVEL_COUNT := 10
const MIN_TOTAL_REWARD := 12
const MAX_TOTAL_REWARD := 20

var _failures := 0


func _initialize() -> void:
	print("Running balance curve tests...")

	var catalog = load(LEVEL_CATALOG_SCRIPT).new()
	var levels: Array = catalog.get_all_levels()

	_test_catalog_size(levels)
	_test_level_invariants(levels)
	_test_reward_range(levels)
	_test_difficulty_curve(catalog, levels)

	if _failures == 0:
		print("Balance curve tests passed.")
		quit(0)
	else:
		push_error("Balance curve tests failed: %d" % _failures)
		quit(1)


func _test_catalog_size(levels: Array) -> void:
	_expect_equal(levels.size(), EXPECTED_LEVEL_COUNT, "catalog returns exactly 10 levels")
	print("ok - catalog size is 10")


func _test_level_invariants(levels: Array) -> void:
	var seen_ids := {}
	for level_config in levels:
		_expect_true(level_config.level_id != "", "level id is not empty")
		_expect_false(seen_ids.has(level_config.level_id), "%s is unique" % level_config.level_id)
		seen_ids[level_config.level_id] = true
		_expect_true(level_config.display_name != "", "%s has display name" % level_config.level_id)
		_expect_true(level_config.enemy_config != null, "%s has enemy config" % level_config.level_id)
		if level_config.enemy_config != null:
			_expect_true(level_config.enemy_config.enemy_id != "", "%s enemy has id" % level_config.level_id)
			_expect_true(level_config.enemy_config.display_name != "", "%s enemy has display name" % level_config.level_id)
			_expect_true(level_config.enemy_config.max_hp > 0, "%s enemy hp is positive" % level_config.level_id)
			_expect_true(level_config.enemy_config.attack >= 0, "%s enemy attack is non-negative" % level_config.level_id)
		_expect_true(level_config.moves > 0, "%s has positive moves" % level_config.level_id)
		_expect_true(level_config.reward_upgrade_points >= 0, "%s has non-negative reward" % level_config.level_id)
	print("ok - all levels have valid content data")


func _test_reward_range(levels: Array) -> void:
	var total_reward := 0
	for level_config in levels:
		total_reward += level_config.reward_upgrade_points
	_expect_true(total_reward >= MIN_TOTAL_REWARD, "total rewards are high enough for early upgrades")
	_expect_true(total_reward <= MAX_TOTAL_REWARD, "total rewards stay in early-game range")
	print("ok - total reward range is reasonable")


func _test_difficulty_curve(catalog, levels: Array) -> void:
	var first_level = catalog.get_level("level_1")
	var final_level = catalog.get_level("level_10")
	_expect_true(final_level.enemy_config.max_hp > first_level.enemy_config.max_hp, "level 10 hp is higher than level 1")
	_expect_true(final_level.enemy_config.attack >= first_level.enemy_config.attack, "level 10 attack is at least level 1")

	var first_raw_stats: int = first_level.enemy_config.max_hp + first_level.enemy_config.attack
	for index in range(1, levels.size()):
		var enemy = levels[index].enemy_config
		var raw_stats: int = enemy.max_hp + enemy.attack
		_expect_true(raw_stats >= first_raw_stats, "%s is not obviously easier than level 1" % levels[index].level_id)
	print("ok - early campaign difficulty grows by broad raw stats")


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

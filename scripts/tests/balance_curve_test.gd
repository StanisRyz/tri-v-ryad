extends SceneTree

const LEVEL_CATALOG_SCRIPT := "res://scripts/game/config/level_catalog.gd"

const EXPECTED_LEVEL_COUNT := 100
const MIN_MOVES := 19
const MAX_MOVES := 24
const MIN_REWARD := 1
const MAX_REWARD := 5

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
	_expect_equal(levels.size(), EXPECTED_LEVEL_COUNT, "catalog returns exactly 100 levels")
	print("ok - catalog size is 100")


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
		_expect_true(level_config.moves >= MIN_MOVES, "%s moves stay above safe minimum" % level_config.level_id)
		_expect_true(level_config.moves <= MAX_MOVES, "%s moves stay below safe maximum" % level_config.level_id)
		_expect_true(level_config.reward_upgrade_points >= 0, "%s has non-negative reward" % level_config.level_id)
		_expect_true(level_config.reward_upgrade_points >= MIN_REWARD, "%s reward stays above placeholder minimum" % level_config.level_id)
		_expect_true(level_config.reward_upgrade_points <= MAX_REWARD, "%s reward stays below placeholder maximum" % level_config.level_id)
	print("ok - all levels have valid content data")


func _test_reward_range(levels: Array) -> void:
	var level_1 = levels[0]
	var level_100 = levels[levels.size() - 1]
	_expect_true(level_100.reward_upgrade_points >= level_1.reward_upgrade_points, "rewards grow across the campaign")
	print("ok - reward range is a safe placeholder curve")


func _test_difficulty_curve(catalog, levels: Array) -> void:
	var first_level = catalog.get_level("level_1")
	var final_level = catalog.get_level("level_100")
	_expect_true(final_level.moves <= first_level.moves, "level 100 moves are no higher than level 1")
	_expect_true(catalog.has_level("level_100"), "level_100 exists")
	_expect_false(catalog.has_level("level_101"), "level_101 does not exist")
	print("ok - campaign placeholder curve uses moves/rewards, not enemy scaling")


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

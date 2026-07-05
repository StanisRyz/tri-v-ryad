extends SceneTree

const PLAYER_PROGRESS_SCRIPT := "res://scripts/game/progression/player_progress.gd"
const LEVEL_CATALOG_SCRIPT := "res://scripts/game/config/level_catalog.gd"
const LEVEL_COMPLETION_RESOLVER_SCRIPT := "res://scripts/game/progression/level_completion_resolver.gd"

var _failures := 0


func _initialize() -> void:
	print("Running level completion tests...")

	var progress = load(PLAYER_PROGRESS_SCRIPT).create_default()
	var catalog = load(LEVEL_CATALOG_SCRIPT).new()
	var resolver = load(LEVEL_COMPLETION_RESOLVER_SCRIPT).new()
	var level_1 = catalog.get_level("level_1")

	_expect_equal(resolver.calculate_stars(level_1, 0), 1, "low moves victory gives 1 star")
	_expect_equal(resolver.calculate_stars(level_1, int(ceil(level_1.moves * 0.25))), 2, "25 percent moves gives 2 stars")
	_expect_equal(resolver.calculate_stars(level_1, int(ceil(level_1.moves * 0.5))), 3, "50 percent moves gives 3 stars")

	var two_star_moves := int(ceil(level_1.moves * 0.25))
	var three_star_moves := int(ceil(level_1.moves * 0.5))
	var result = resolver.apply_victory_result(progress, level_1, two_star_moves)
	_expect_true(result.completed, "victory marks level completed")
	_expect_equal(result.stars, 2, "victory stores stars")
	_expect_equal(result.best_moves_left, two_star_moves, "victory stores best moves")

	resolver.apply_victory_result(progress, level_1, 0)
	_expect_equal(progress.get_level_stars("level_1"), 2, "worse replay does not downgrade stars")
	_expect_equal(progress.get_level_progress("level_1").best_moves_left, two_star_moves, "worse replay preserves best moves")

	resolver.apply_victory_result(progress, level_1, three_star_moves)
	_expect_equal(progress.get_level_stars("level_1"), 3, "better replay upgrades stars")
	_expect_equal(progress.get_level_progress("level_1").best_moves_left, three_star_moves, "better replay improves best moves")

	var fresh_progress = load(PLAYER_PROGRESS_SCRIPT).create_default()
	_expect_true(resolver.is_level_unlocked(fresh_progress, catalog, "level_1"), "level_1 is unlocked by default")
	_expect_false(resolver.is_level_unlocked(fresh_progress, catalog, "level_2"), "level_2 is locked before level_1 completion")

	resolver.apply_victory_result(fresh_progress, catalog.get_level("level_1"), 0)
	_expect_true(resolver.is_level_unlocked(fresh_progress, catalog, "level_2"), "level_2 unlocks after level_1 completion")
	_expect_false(resolver.is_level_unlocked(fresh_progress, catalog, "level_5"), "level_5 remains locked without prior completions")

	for index in range(2, 5):
		resolver.apply_victory_result(fresh_progress, catalog.get_level("level_%d" % index), 0)
	_expect_true(resolver.is_level_unlocked(fresh_progress, catalog, "level_5"), "level_5 unlocks through prior completions")
	_expect_false(resolver.is_level_unlocked(fresh_progress, catalog, "level_100"), "level_100 remains locked until level_99 completion")

	var late_progress = load(PLAYER_PROGRESS_SCRIPT).create_default()
	for index in range(1, 100):
		resolver.apply_victory_result(late_progress, catalog.get_level("level_%d" % index), 0)
	_expect_true(resolver.is_level_unlocked(late_progress, catalog, "level_100"), "level_100 unlocks after level_99 completion")
	_expect_false(resolver.is_level_unlocked(late_progress, catalog, "level_101"), "level_101 is not unlockable")

	if _failures == 0:
		print("Level completion tests passed.")
		quit(0)
	else:
		push_error("Level completion tests failed: %d" % _failures)
		quit(1)


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

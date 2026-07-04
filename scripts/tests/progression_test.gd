extends SceneTree

const PLAYER_PROGRESS_SCRIPT := "res://scripts/game/progression/player_progress.gd"
const UPGRADE_RESOLVER_SCRIPT := "res://scripts/game/progression/upgrade_resolver.gd"

var _failures := 0


func _initialize() -> void:
	print("Running progression tests...")

	var progress = load(PLAYER_PROGRESS_SCRIPT).create_default()
	var resolver = load(UPGRADE_RESOLVER_SCRIPT).new()

	_expect_equal(progress.upgrade_points, 0, "default progress has 0 upgrade points")
	for hero_id in ["hero_1", "hero_2", "hero_3"]:
		_expect_true(progress.hero_upgrades.has(hero_id), "default progress has %s upgrade record" % hero_id)

	progress.add_upgrade_points(2)
	_expect_equal(progress.upgrade_points, 2, "add_upgrade_points increases points")

	var empty_progress = load(PLAYER_PROGRESS_SCRIPT).create_default()
	_expect_false(resolver.upgrade(empty_progress, "hero_1", "attack"), "upgrade without points fails")
	_expect_equal(empty_progress.get_hero_upgrade("hero_1").attack_level, 0, "failed attack upgrade does not mutate")

	_expect_true(resolver.upgrade(progress, "hero_1", "attack"), "attack upgrade with points succeeds")
	_expect_equal(progress.get_hero_upgrade("hero_1").attack_level, 1, "attack upgrade increases attack level")
	_expect_equal(progress.upgrade_points, 1, "attack upgrade spends 1 point")

	_expect_true(resolver.upgrade(progress, "hero_1", "hp"), "hp upgrade with points succeeds")
	_expect_equal(progress.get_hero_upgrade("hero_1").hp_level, 1, "hp upgrade increases hp level")
	_expect_equal(progress.upgrade_points, 0, "hp upgrade spends 1 point")

	progress.add_upgrade_points(1)
	var before_points: int = progress.upgrade_points
	var before_attack: int = progress.get_hero_upgrade("hero_1").attack_level
	_expect_false(resolver.upgrade(progress, "hero_1", "speed"), "invalid stat fails")
	_expect_equal(progress.upgrade_points, before_points, "invalid stat does not spend points")
	_expect_equal(progress.get_hero_upgrade("hero_1").attack_level, before_attack, "invalid stat does not mutate attack")

	progress.mark_level_completed("level_1")
	_expect_true(progress.is_level_completed("level_1"), "completed level can be checked")
	_expect_false(progress.is_level_completed("level_2"), "uncompleted level remains false")

	if _failures == 0:
		print("Progression tests passed.")
		quit(0)
	else:
		push_error("Progression tests failed: %d" % _failures)
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

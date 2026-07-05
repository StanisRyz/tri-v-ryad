extends SceneTree

const LEVEL_CATALOG := preload("res://scripts/game/config/level_catalog.gd")
const LEVEL_LABEL_FORMATTER := preload("res://scripts/game/config/level_label_formatter.gd")
const ENEMY_CATALOG := preload("res://scripts/game/config/enemy_catalog.gd")
const BATTLE_FACTORY := preload("res://scripts/game/battle/battle_factory.gd")
const BATTLE_PRESENTER := preload("res://scripts/game/presentation/battle_presenter.gd")
const PLAYER_PROGRESS := preload("res://scripts/game/progression/player_progress.gd")
const LEVEL_COMPLETION_RESOLVER := preload("res://scripts/game/progression/level_completion_resolver.gd")
const ECONOMY_CONFIG := preload("res://scripts/game/progression/upgrade_economy_config.gd")

var _failures := 0


func _initialize() -> void:
	print("Running 100-level campaign tests...")

	var catalog := LEVEL_CATALOG.new()
	_test_catalog_identity(catalog)
	_test_economy_curves(catalog)
	_test_level_100_battle_creation(catalog)
	_test_level_100_presenter_start()
	_test_late_unlocks(catalog)

	if _failures == 0:
		print("100-level campaign tests passed.")
		quit(0)
	else:
		push_error("100-level campaign tests failed: %d" % _failures)
		quit(1)


func _test_catalog_identity(catalog) -> void:
	var levels: Array = catalog.get_all_levels()
	var seen_ids := {}
	_expect_equal(levels.size(), 100, "catalog returns exactly 100 levels")
	_expect_true(catalog.has_level("level_1"), "level_1 exists")
	_expect_true(catalog.has_level("level_100"), "level_100 exists")
	_expect_false(catalog.has_level("level_101"), "level_101 does not exist")
	_expect_equal(catalog.get_default_level_id(), "level_1", "default level is level_1")
	_expect_equal(LEVEL_LABEL_FORMATTER.format_level_label("level_100"), "Level 100", "formatter supports level_100")

	for index in range(levels.size()):
		var level_number := index + 1
		var level_config = levels[index]
		_expect_false(seen_ids.has(level_config.level_id), "%s is unique" % level_config.level_id)
		seen_ids[level_config.level_id] = true
		_expect_equal(level_config.level_id, "level_%d" % level_number, "level id is sequential")
		_expect_equal(level_config.display_name, "Level %d" % level_number, "display name is sequential")
		_expect_false(level_config.display_name.contains(":"), "%s display name has no subtitle separator" % level_config.level_id)
		_expect_false(_contains_old_level_name(level_config.display_name), "%s has no old location-style name" % level_config.level_id)


func _test_economy_curves(catalog) -> void:
	for level_config in catalog.get_all_levels():
		_expect_true(level_config.moves > 0, "%s moves are positive" % level_config.level_id)
		_expect_true(level_config.moves >= 19, "%s moves stay in safe minimum range" % level_config.level_id)
		_expect_true(level_config.moves <= 24, "%s moves stay in safe maximum range" % level_config.level_id)
		_expect_true(level_config.reward_upgrade_points >= 0, "%s reward is non-negative" % level_config.level_id)
		_expect_true(level_config.reward_upgrade_points <= ECONOMY_CONFIG.LEVEL_REWARD_MAX, "%s reward stays in safe economy range" % level_config.level_id)


func _test_level_100_battle_creation(catalog) -> void:
	var level_100 = catalog.get_level("level_100")
	var state = BATTLE_FACTORY.new().create_state(level_100)
	var enemy_catalog := ENEMY_CATALOG.new()
	_expect_true(state != null, "level_100 creates battle state")
	_expect_true(enemy_catalog.has_enemy(state.enemy.id), "level_100 fallback enemy exists in EnemyCatalog")
	_expect_equal(state.moves_left, level_100.moves, "level_100 state uses level moves")


func _test_level_100_presenter_start() -> void:
	var presenter = BATTLE_PRESENTER.new()
	var enemy_catalog := ENEMY_CATALOG.new()
	presenter.set_enemy_rng_seed(100)
	presenter.start_level("level_100")
	_expect_equal(presenter.current_level_id, "level_100", "presenter starts level_100")
	_expect_true(presenter.state != null, "presenter creates level_100 state")
	_expect_true(enemy_catalog.has_enemy(presenter.state.enemy.id), "presenter selected level_100 enemy from EnemyCatalog")
	var base_enemy = enemy_catalog.get_enemy(presenter.state.enemy.id)
	_expect_true(presenter.state.enemy.max_hp >= base_enemy.max_hp, "presenter level_100 enemy hp scales from base")
	_expect_true(presenter.state.enemy.attack >= base_enemy.attack, "presenter level_100 enemy attack scales from base")


func _test_late_unlocks(catalog) -> void:
	var progress = PLAYER_PROGRESS.create_default()
	var resolver = LEVEL_COMPLETION_RESOLVER.new()
	_expect_false(resolver.is_level_unlocked(progress, catalog, "level_100"), "level_100 is locked by default")
	for index in range(1, 100):
		resolver.apply_victory_result(progress, catalog.get_level("level_%d" % index), 0)
	_expect_true(resolver.is_level_unlocked(progress, catalog, "level_100"), "level_100 unlocks after level_99")
	_expect_false(resolver.is_level_unlocked(progress, catalog, "level_101"), "level_101 remains unavailable")


func _contains_old_level_name(value: String) -> bool:
	var old_level_names := [
		"%s %s" % ["Training", "Yard"],
		"%s %s" % ["Slime", "Trail"],
		"%s %s" % ["Scout", "Post"],
		"%s %s" % ["Fighter", "Camp"],
		"%s %s" % ["Armored", "Watch"],
		"%s %s" % ["Wild", "Path"],
		"%s %s" % ["Bandit", "Road"],
		"%s %s" % ["Brute", "Cave"],
		"%s %s" % ["Shaman", "Hollow"],
		"%s%s" % ["Gate", "keeper"],
	]
	for old_name in old_level_names:
		if value.contains(old_name):
			return true
	return false


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

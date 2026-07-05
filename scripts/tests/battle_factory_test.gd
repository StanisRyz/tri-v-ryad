extends SceneTree

const LEVEL_CATALOG_SCRIPT := "res://scripts/game/config/level_catalog.gd"
const BATTLE_FACTORY_SCRIPT := "res://scripts/game/battle/battle_factory.gd"
const ENEMY_CATALOG_SCRIPT := "res://scripts/game/config/enemy_catalog.gd"

var _failures := 0


func _initialize() -> void:
	print("Running battle factory tests...")

	var level_config = load(LEVEL_CATALOG_SCRIPT).new().get_level("level_3")
	var factory = load(BATTLE_FACTORY_SCRIPT).new()
	var state = factory.create_state(level_config)

	_expect_true(state != null, "factory creates BattleState")
	_expect_equal(state.heroes.size(), 3, "state has 3 heroes")
	_expect_equal(state.heroes[0].lane_index, 0, "hero lane 0")
	_expect_equal(state.heroes[1].lane_index, 1, "hero lane 1")
	_expect_equal(state.heroes[2].lane_index, 2, "hero lane 2")
	_expect_equal(state.enemy.id, level_config.enemy_config.enemy_id, "enemy id matches config")
	_expect_equal(state.enemy.display_name, level_config.enemy_config.display_name, "enemy name matches config")
	_expect_equal(state.enemy.attack, level_config.enemy_config.attack, "enemy attack matches config")
	_expect_equal(state.enemy_intent.reset_turns, level_config.enemy_config.intent_turns, "enemy intent turns match config")
	_expect_equal(state.enemy_intent.target_lane, level_config.enemy_config.target_lane, "enemy target lane matches config")
	_expect_equal(state.moves_left, level_config.moves, "moves match config")
	_expect_equal(state.status, BattleState.Status.IN_PROGRESS, "state starts in progress")
	_test_enemy_override(factory, level_config)

	if _failures == 0:
		print("Battle factory tests passed.")
		quit(0)
	else:
		push_error("Battle factory tests failed: %d" % _failures)
		quit(1)


func _test_enemy_override(factory, level_config) -> void:
	var enemy_override = load(ENEMY_CATALOG_SCRIPT).new().get_enemy("gatekeeper")
	var state = factory.create_state(level_config, null, null, enemy_override)
	_expect_equal(state.enemy.id, enemy_override.enemy_id, "enemy override id is used")
	_expect_equal(state.enemy.display_name, enemy_override.display_name, "enemy override display name is used")
	_expect_equal(state.enemy.attack, enemy_override.attack, "enemy override attack is used")
	_expect_equal(state.enemy_intent.reset_turns, enemy_override.intent_turns, "enemy override intent turns are used")
	_expect_equal(state.enemy_intent.target_lane, enemy_override.target_lane, "enemy override target lane is used")
	_expect_equal(state.moves_left, level_config.moves, "enemy override keeps level moves")


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

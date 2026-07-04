extends SceneTree

const LEVEL_CATALOG_SCRIPT := "res://scripts/game/config/level_catalog.gd"
const BATTLE_FACTORY_SCRIPT := "res://scripts/game/battle/battle_factory.gd"

var _failures := 0


func _initialize() -> void:
	print("Running battle factory tests...")

	var level_config = load(LEVEL_CATALOG_SCRIPT).new().get_level("level_3")
	var state = load(BATTLE_FACTORY_SCRIPT).new().create_state(level_config)

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

	if _failures == 0:
		print("Battle factory tests passed.")
		quit(0)
	else:
		push_error("Battle factory tests failed: %d" % _failures)
		quit(1)


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

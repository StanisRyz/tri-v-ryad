extends MainLoop

const LEVEL_CATALOG_SCRIPT := "res://scripts/game/config/level_catalog.gd"
const BATTLE_FACTORY_SCRIPT := "res://scripts/game/battle/battle_factory.gd"
const PLAYER_PROGRESS_SCRIPT := "res://scripts/game/progression/player_progress.gd"
const HERO_CATALOG_SCRIPT := "res://scripts/game/config/hero_catalog.gd"
const TEAM_SELECTION_STATE_SCRIPT := "res://scripts/game/progression/team_selection_state.gd"

var _failures := 0
var _ran := false


func _process(_delta: float) -> bool:
	if _ran:
		return true
	_ran = true
	_run()
	return true


func _run() -> void:
	print("Running battle factory team tests...")

	var level_config = load(LEVEL_CATALOG_SCRIPT).new().get_level("level_1")
	var factory = load(BATTLE_FACTORY_SCRIPT).new()
	var progress = load(PLAYER_PROGRESS_SCRIPT).create_default()
	var catalog = load(HERO_CATALOG_SCRIPT).new()

	progress.set_team_selection(load(TEAM_SELECTION_STATE_SCRIPT).new(["hero_5", "hero_4", "hero_2"]))
	progress.get_hero_upgrade("hero_5").attack_level = 2
	progress.get_hero_upgrade("hero_5").hp_level = 1
	var hero_5_config = catalog.get_hero("hero_5")
	var original_lane = hero_5_config.lane_index

	var state = factory.create_state(level_config, progress, catalog)
	_expect_equal(state.heroes.size(), 3, "selected team creates 3 heroes")
	_expect_equal(state.heroes[0].id, "hero_5", "first selected hero is in lane 0")
	_expect_equal(state.heroes[1].id, "hero_4", "second selected hero is in lane 1")
	_expect_equal(state.heroes[2].id, "hero_2", "third selected hero is in lane 2")
	_expect_equal(state.heroes[0].lane_index, 0, "first selected hero maps to lane 0")
	_expect_equal(state.heroes[1].lane_index, 1, "second selected hero maps to lane 1")
	_expect_equal(state.heroes[2].lane_index, 2, "third selected hero maps to lane 2")
	_expect_equal(state.heroes[0].attack_level, 2, "selected hero attack upgrade is applied")
	_expect_equal(state.heroes[0].hp_level, 1, "selected hero hp upgrade is applied")
	_expect_equal(state.heroes[0].ability_id, "ranger_strike", "selected hero ability_id is applied")
	_expect_equal(hero_5_config.lane_index, original_lane, "HeroConfig lane is not mutated")

	progress.set_team_selection(load(TEAM_SELECTION_STATE_SCRIPT).new(["hero_5", "hero_5", "unknown"]))
	var fallback_state = factory.create_state(level_config, progress, catalog)
	_expect_equal(fallback_state.heroes[0].id, "hero_1", "invalid team falls back to default hero 1")
	_expect_equal(fallback_state.heroes[1].id, "hero_2", "invalid team falls back to default hero 2")
	_expect_equal(fallback_state.heroes[2].id, "hero_3", "invalid team falls back to default hero 3")

	var level_fallback_state = factory.create_state(level_config, progress)
	_expect_equal(level_fallback_state.heroes[0].id, level_config.hero_configs[0].hero_id, "missing catalog falls back to level config")

	if _failures == 0:
		print("Battle factory team tests passed.")
	else:
		push_error("Battle factory team tests failed: %d" % _failures)


func _expect_equal(actual, expected, message: String) -> void:
	if actual == expected:
		return
	_failures += 1
	push_error("FAILED: %s | expected=%s actual=%s" % [message, expected, actual])

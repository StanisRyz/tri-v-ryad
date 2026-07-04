extends MainLoop

const HERO_CATALOG_SCRIPT := "res://scripts/game/config/hero_catalog.gd"
const TEAM_SELECTION_RESOLVER_SCRIPT := "res://scripts/game/progression/team_selection_resolver.gd"
const TEAM_SELECTION_STATE_SCRIPT := "res://scripts/game/progression/team_selection_state.gd"
const PLAYER_PROGRESS_SCRIPT := "res://scripts/game/progression/player_progress.gd"

var _failures := 0
var _ran := false


func _process(_delta: float) -> bool:
	if _ran:
		return true
	_ran = true
	_run()
	return true


func _run() -> void:
	print("Running team selection tests...")

	var catalog = load(HERO_CATALOG_SCRIPT).new()
	var resolver = load(TEAM_SELECTION_RESOLVER_SCRIPT).new()
	var default_team: Array = catalog.get_default_team_ids()

	_expect_true(resolver.is_valid_team(["hero_1", "hero_4", "hero_5"], catalog), "valid team passes")
	_expect_false(resolver.is_valid_team(["hero_1", "hero_1", "hero_2"], catalog), "duplicate team fails")
	_expect_false(resolver.is_valid_team(["hero_1", "hero_2"], catalog), "short team fails")
	_expect_false(resolver.is_valid_team(["hero_1", "hero_2", "hero_3", "hero_4"], catalog), "long team fails")
	_expect_false(resolver.is_valid_team(["hero_1", "unknown", "hero_3"], catalog), "unknown hero fails")
	_expect_equal(resolver.normalize_team(["hero_1"], catalog), default_team, "invalid team normalizes to default")

	var state = load(TEAM_SELECTION_STATE_SCRIPT).new(["hero_5", "hero_4", "hero_1"])
	var restored = load(TEAM_SELECTION_STATE_SCRIPT).from_dictionary(state.to_dictionary(), default_team)
	_expect_equal(restored.selected_hero_ids, ["hero_5", "hero_4", "hero_1"], "team state serializes selected ids")

	var old_progress = load(PLAYER_PROGRESS_SCRIPT).from_dictionary({
		"save_version": 1,
		"upgrade_points": 0,
		"hero_upgrades": {},
		"completed_levels": {},
	})
	_expect_equal(old_progress.get_selected_team_ids(), default_team, "old progress without team selection falls back safely")

	if _failures == 0:
		print("Team selection tests passed.")
	else:
		push_error("Team selection tests failed: %d" % _failures)


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

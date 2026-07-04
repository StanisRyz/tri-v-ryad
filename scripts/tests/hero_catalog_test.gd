extends MainLoop

const HERO_CATALOG_SCRIPT := "res://scripts/game/config/hero_catalog.gd"

var _failures := 0
var _ran := false


func _process(_delta: float) -> bool:
	if _ran:
		return true
	_ran = true
	_run()
	return true


func _run() -> void:
	print("Running hero catalog tests...")

	var catalog = load(HERO_CATALOG_SCRIPT).new()
	var valid_ability_ids := ["power_strike", "line_break", "rally_heal"]

	_expect_equal(catalog.get_all_heroes().size(), 5, "catalog returns 5 heroes")
	_expect_equal(catalog.get_default_team_ids().size(), 3, "default team has 3 heroes")
	for hero_id in catalog.get_default_team_ids():
		_expect_true(catalog.has_hero(hero_id), "default team hero exists: %s" % hero_id)

	for hero_config in catalog.get_all_heroes():
		_expect_true(hero_config.base_attack > 0, "%s has positive attack" % hero_config.hero_id)
		_expect_true(hero_config.base_max_hp > 0, "%s has positive hp" % hero_config.hero_id)
		_expect_true(valid_ability_ids.has(hero_config.ability_id), "%s has valid ability id" % hero_config.hero_id)

	_expect_true(catalog.get_hero("unknown") == null, "unknown hero returns null")
	_expect_equal(catalog.get_heroes(["hero_1", "hero_5"]).size(), 2, "get_heroes returns known configs")

	if _failures == 0:
		print("Hero catalog tests passed.")
	else:
		push_error("Hero catalog tests failed: %d" % _failures)


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

extends SceneTree

const ABILITY_PRESENTATION_DATA_SCRIPT := "res://scripts/game/presentation/ability_presentation_data.gd"
const ABILITY_RESULT_SCRIPT := "res://scripts/game/battle/ability_result.gd"
const ABILITY_DATA_SCRIPT := "res://scripts/game/battle/ability_data.gd"

var _failures := 0


func _initialize() -> void:
	print("Running ability presentation data tests...")

	_test_accepted_result_is_copied()
	_test_rejected_reason_is_copied()
	_test_damage_fields_are_copied()
	_test_legacy_effect_fields_stay_empty()
	_test_board_changed_stays_false()

	if _failures == 0:
		print("Ability presentation data tests passed.")
		quit(0)
	else:
		push_error("Ability presentation data tests failed: %d" % _failures)
		quit(1)


func _test_accepted_result_is_copied() -> void:
	var data = _create_accepted_data()
	_expect_true(data.accepted, "accepted copied")
	_expect_equal(data.hero_id, "hero_1", "hero id copied")
	_expect_equal(data.ability_id, "warrior_strike", "ability id copied")
	print("ok - accepted result is copied")


func _test_rejected_reason_is_copied() -> void:
	var result = load(ABILITY_RESULT_SCRIPT).rejected_result("hero_1", 0, "ability_not_ready")
	var data = load(ABILITY_PRESENTATION_DATA_SCRIPT).from_result(result)
	_expect_false(data.accepted, "rejected copied")
	_expect_equal(data.reason, "ability_not_ready", "rejected reason copied")
	print("ok - rejected reason is copied")


func _test_damage_fields_are_copied() -> void:
	var data = _create_accepted_data()
	_expect_equal(data.damage_to_enemy, 50, "damage copied")
	print("ok - damage fields are copied")


func _test_legacy_effect_fields_stay_empty() -> void:
	var data = _create_accepted_data()
	_expect_equal(data.healed_heroes.size(), 0, "healed heroes empty")
	_expect_equal(data.cleared_cells.size(), 0, "cleared cells empty")
	print("ok - legacy effect fields stay empty")


func _test_board_changed_stays_false() -> void:
	var data = _create_accepted_data()
	_expect_false(data.board_changed, "board changed false")
	print("ok - board_changed stays false")


func _create_accepted_data():
	var hero := HeroData.new("hero_1", "Hero 1", 0, 10, 100, 0, 0, 10)
	var ability = load(ABILITY_DATA_SCRIPT).warrior_strike("hero_1")
	var result = load(ABILITY_RESULT_SCRIPT).accepted_result(hero, ability, BattleState.Status.IN_PROGRESS)
	result.damage_to_enemy = 50
	result.board_changed = false
	return load(ABILITY_PRESENTATION_DATA_SCRIPT).from_result(result)


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

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
	_test_healed_heroes_are_copied()
	_test_cleared_cells_are_copied()
	_test_board_changed_is_copied()

	if _failures == 0:
		print("Ability presentation data tests passed.")
		quit(0)
	else:
		push_error("Ability presentation data tests failed: %d" % _failures)
		quit(1)


func _test_accepted_result_is_copied() -> void:
	var data = _create_accepted_data()
	_expect_true(data.accepted, "accepted copied")
	_expect_equal(data.hero_id, "hero_2", "hero id copied")
	_expect_equal(data.ability_id, "line_break", "ability id copied")
	print("ok - accepted result is copied")


func _test_rejected_reason_is_copied() -> void:
	var result = load(ABILITY_RESULT_SCRIPT).rejected_result("hero_1", 0, "ability_not_ready")
	var data = load(ABILITY_PRESENTATION_DATA_SCRIPT).from_result(result)
	_expect_false(data.accepted, "rejected copied")
	_expect_equal(data.reason, "ability_not_ready", "rejected reason copied")
	print("ok - rejected reason is copied")


func _test_damage_fields_are_copied() -> void:
	var data = _create_accepted_data()
	_expect_equal(data.damage_to_enemy, 40, "damage copied")
	print("ok - damage fields are copied")


func _test_healed_heroes_are_copied() -> void:
	var data = _create_accepted_data()
	_expect_equal(data.healed_heroes[0]["amount"], 30, "healed heroes copied")
	print("ok - healed heroes are copied")


func _test_cleared_cells_are_copied() -> void:
	var data = _create_accepted_data()
	_expect_equal(data.cleared_cells.size(), 2, "cleared cells copied")
	print("ok - cleared cells are copied")


func _test_board_changed_is_copied() -> void:
	var data = _create_accepted_data()
	_expect_true(data.board_changed, "board changed copied")
	print("ok - board_changed is copied")


func _create_accepted_data():
	var hero := HeroData.new("hero_2", "Hero 2", 1, 8, 120, 0, 0, 10)
	var ability = load(ABILITY_DATA_SCRIPT).line_break()
	var result = load(ABILITY_RESULT_SCRIPT).accepted_result(hero, ability, BattleState.Status.IN_PROGRESS)
	result.damage_to_enemy = 40
	result.healed_heroes.append({"hero_id": "hero_3", "amount": 30, "current_hp": 70})
	result.cleared_cells.append(Vector2i(0, 4))
	result.cleared_cells.append(Vector2i(1, 4))
	result.board_changed = true
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

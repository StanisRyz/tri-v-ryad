extends SceneTree

const BOOSTER_CATALOG_SCRIPT := preload("res://scripts/game/config/booster_catalog.gd")
const BOOSTER_STATE_SCRIPT := preload("res://scripts/game/battle/booster_state.gd")

var _failures := 0


func _initialize() -> void:
	print("Running booster state tests...")

	var state = BOOSTER_STATE_SCRIPT.new()
	state.setup_from_catalog(BOOSTER_CATALOG_SCRIPT.new())

	for booster_id in ["hammer", "freeze_time", "rocket_barrage"]:
		_expect_equal(state.get_uses_left(booster_id), 1, "%s starts with one use" % booster_id)
		_expect_true(state.can_use(booster_id), "%s can be used" % booster_id)

	state.consume_use("hammer")
	_expect_equal(state.get_uses_left("hammer"), 0, "hammer use is consumed")
	_expect_true(not state.can_use("hammer"), "hammer cannot be used with zero uses")
	_expect_true(not state.consume_use("unknown"), "unknown booster cannot be consumed")

	state.set_active_booster("rocket_barrage")
	_expect_equal(state.get_active_booster_id(), "rocket_barrage", "active booster is tracked")
	state.clear_active_booster()
	_expect_equal(state.get_active_booster_id(), "", "active booster clears")

	state.add_freeze_turns(3)
	_expect_equal(state.freeze_turns_left, 3, "freeze turns are added")
	_expect_true(state.consume_freeze_turn(), "freeze turn consumes")
	_expect_equal(state.freeze_turns_left, 2, "freeze turn count decrements")

	_finish()


func _finish() -> void:
	if _failures == 0:
		print("Booster state tests passed.")
		quit(0)
	else:
		push_error("Booster state tests failed: %d" % _failures)
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

extends SceneTree

const BOOSTER_PANEL := preload("res://scenes/ui/BoosterPanel.tscn")
const BOOSTER_CATALOG_SCRIPT := preload("res://scripts/game/config/booster_catalog.gd")
const BOOSTER_STATE_SCRIPT := preload("res://scripts/game/battle/booster_state.gd")

var _failures := 0


func _initialize() -> void:
	print("Running booster panel tests...")
	_run()


func _run() -> void:
	var panel = BOOSTER_PANEL.instantiate()
	root.add_child(panel)
	await process_frame

	var state = BOOSTER_STATE_SCRIPT.new()
	state.setup_from_catalog(BOOSTER_CATALOG_SCRIPT.new())
	panel.setup_boosters(BOOSTER_CATALOG_SCRIPT.new())
	panel.set_booster_state(state)
	# Stage 62.2 v0.1: buttons are now also gated on the global inventory
	# count, so a non-zero count must be supplied for a fresh/unused booster
	# to read as enabled.
	panel.set_booster_counts({"hammer": 3, "freeze_time": 3, "rocket_barrage": 3})
	await process_frame

	_expect_equal(panel.get_button_count(), 3, "booster panel shows 3 buttons")
	panel.set_selected_booster("hammer")
	await process_frame

	var hammer_button: BoosterButton = panel.get_node("Content/ButtonRow/HammerButton")
	_expect_true(hammer_button != null, "hammer button exists")
	_expect_true(not hammer_button.disabled, "hammer button starts enabled")
	_expect_equal(hammer_button.get_button_state_asset_key(), "ui_booster_button_selected", "selected state is applied")

	state.consume_use("hammer")
	panel.refresh()
	await process_frame
	_expect_true(hammer_button.disabled, "used booster button disables")
	_expect_equal(hammer_button.get_button_state_asset_key(), "ui_booster_button_disabled", "disabled state is applied")

	panel.queue_free()
	_finish()


func _finish() -> void:
	if _failures == 0:
		print("Booster panel tests passed.")
		quit(0)
	else:
		push_error("Booster panel tests failed: %d" % _failures)
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

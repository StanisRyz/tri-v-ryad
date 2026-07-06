extends SceneTree

const BOOSTER_BUTTON_SCENE := preload("res://scenes/ui/BoosterButton.tscn")

var _failures := 0


func _initialize() -> void:
	print("Running booster button asset stub test...")
	_run()


func _run() -> void:
	var button := BOOSTER_BUTTON_SCENE.instantiate()
	root.add_child(button)
	await process_frame

	button.set_booster_id("hammer")
	button.set_uses_left(3)
	await process_frame
	_expect_equal(button.get_booster_id(), "hammer", "booster id stored")
	_expect_equal(button.get_icon_asset_key(), "booster_hammer", "hammer icon asset key applied")
	_expect_equal(button.get_node("%UsesLabel").text, "x3", "uses label updates")
	_expect_false(button.get_node("%IconSlot").has_texture(), "missing booster icon keeps placeholder")
	_expect_equal(button.get_button_state_asset_key(), "ui_booster_button_ready", "ready state asset key")

	button.set_selected(true)
	_expect_equal(button.get_button_state_asset_key(), "ui_booster_button_selected", "selected state asset key")

	button.set_disabled_state(true)
	_expect_true(button.disabled, "disabled state updates Button.disabled")
	_expect_equal(button.get_button_state_asset_key(), "ui_booster_button_disabled", "disabled state asset key")

	button.set_booster_id("unknown")
	_expect_equal(button.get_icon_asset_key(), "", "unknown booster clears icon asset key safely")
	button.queue_free()

	if _failures == 0:
		print("Booster button asset stub test passed.")
		quit(0)
	else:
		push_error("Booster button asset stub test failed: %d" % _failures)
		quit(1)


func _expect_false(value: bool, message: String) -> void:
	_expect_true(not value, message)


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

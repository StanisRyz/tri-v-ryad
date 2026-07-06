extends SceneTree

const GAME_SCREEN := preload("res://scenes/screens/GameScreen.tscn")

var _failures := 0


func _initialize() -> void:
	print("Running game screen booster flow test...")
	_run()


func _run() -> void:
	var screen := GAME_SCREEN.instantiate()
	root.add_child(screen)
	await process_frame

	var booster_panel = screen.get_node("%BoosterPanel")
	var hero_party_panel: Control = screen.get_node("%HeroPartyPanel")
	_expect_true(booster_panel != null, "game screen has BoosterPanel")
	_expect_true(booster_panel.visible, "booster panel is visible in direct mode")
	_expect_equal(booster_panel.get_button_count(), 3, "game screen booster panel has 3 buttons")
	_expect_true(not hero_party_panel.visible, "hero party panel remains hidden")

	var starting_moves: int = screen._presenter.state.moves_left
	screen._on_booster_pressed("freeze_time")
	await process_frame
	_expect_equal(screen._presenter.state.moves_left, starting_moves, "freeze button does not consume moves")
	_expect_equal(screen._presenter.state.get("booster_state").freeze_turns_left, 3, "freeze button adds turns")

	screen._on_booster_pressed("hammer")
	await process_frame
	_expect_equal(screen._input_mode, "booster_targeting", "hammer enters targeting mode")
	screen._on_booster_pressed("hammer")
	await process_frame
	_expect_equal(screen._input_mode, "normal", "repeated hammer press cancels targeting")

	screen.queue_free()
	_finish()


func _finish() -> void:
	if _failures == 0:
		print("Game screen booster flow test passed.")
		quit(0)
	else:
		push_error("Game screen booster flow test failed: %d" % _failures)
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

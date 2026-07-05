extends SceneTree

const HERO_PARTY_PANEL_SCENE := preload("res://scenes/ui/HeroPartyPanel.tscn")

var _failures := 0


func _initialize() -> void:
	print("Running hero party panel tests...")
	HeroCard.set_debug_labels_enabled(false)
	HeroCard.set_presentation_settings(false, false)

	await _test_instantiates_three_cards()
	await _test_set_heroes_updates_cards()
	await _test_card_press_forwards_ability_requested()

	if _failures == 0:
		print("Hero party panel tests passed.")
		quit(0)
	else:
		push_error("Hero party panel tests failed: %d" % _failures)
		quit(1)


func _make_heroes() -> Array[HeroData]:
	var heroes: Array[HeroData] = []
	for lane_index in range(3):
		var hero := HeroData.new("hero_%d" % (lane_index + 1), "Hero", lane_index, 10, 100, 0, 0, 10)
		hero.current_hp = 100
		heroes.append(hero)
	return heroes


func _make_panel():
	var panel = HERO_PARTY_PANEL_SCENE.instantiate()
	root.add_child(panel)
	return panel


func _test_instantiates_three_cards() -> void:
	var panel = _make_panel()
	_expect_equal(panel.get_child_count(), 3, "party panel has three hero cards")
	panel.queue_free()
	await process_frame


func _test_set_heroes_updates_cards() -> void:
	var panel = _make_panel()
	var heroes := _make_heroes()
	heroes[1].current_hp = 40
	panel.set_heroes(heroes)
	await process_frame

	var second_card := panel.get_child(1) as HeroCard
	var hp_bar := second_card.get_node("%HpBar") as ProgressBar
	_expect_equal(hp_bar.value, 0.4, "hero party panel forwards hero data to hero cards")
	panel.queue_free()
	await process_frame


func _test_card_press_forwards_ability_requested() -> void:
	var panel = _make_panel()
	var heroes := _make_heroes()
	heroes[2].ability_charge = 10
	panel.set_heroes(heroes)
	await process_frame

	var requested_lanes: Array = []
	panel.ability_requested.connect(func(lane_index: int): requested_lanes.append(lane_index))

	var third_card := panel.get_child(2) as HeroCard
	var portrait_button := third_card.get_node("%PortraitButton") as Button
	portrait_button.pressed.emit()

	_expect_equal(requested_lanes, [2], "hero party panel forwards portrait press as ability_requested")
	panel.queue_free()
	await process_frame


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

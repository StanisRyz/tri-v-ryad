extends SceneTree

const HERO_CARD_SCENE := preload("res://scenes/ui/HeroCard.tscn")

var _failures := 0


func _initialize() -> void:
	print("Running hero card presentation tests...")
	HeroCard.set_debug_labels_enabled(false)
	HeroCard.set_presentation_settings(false, false)

	await _test_instantiates()
	await _test_hp_bar_reflects_hero_hp()
	await _test_charge_bar_reflects_hero_charge()
	await _test_full_charge_is_ready()
	await _test_partial_charge_is_not_ready()
	await _test_dead_hero_is_down()
	await _test_press_emits_ability_pressed_with_lane_index()
	await _test_null_hero_disables_press()
	await _test_zero_max_values_are_safe()

	if _failures == 0:
		print("Hero card presentation tests passed.")
		quit(0)
	else:
		push_error("Hero card presentation tests failed: %d" % _failures)
		quit(1)


func _make_hero(lane_index: int, current_hp: int, max_hp: int, charge: int, charge_required: int) -> HeroData:
	var hero := HeroData.new("hero_%d" % (lane_index + 1), "Hero", lane_index, 10, max_hp, 0, 0, charge_required)
	hero.current_hp = current_hp
	hero.ability_charge = charge
	return hero


func _make_card() -> HeroCard:
	var card := HERO_CARD_SCENE.instantiate() as HeroCard
	root.add_child(card)
	return card


func _test_instantiates() -> void:
	var card := _make_card()
	_expect_true(card != null, "hero card instantiates")
	card.queue_free()
	await process_frame


func _test_hp_bar_reflects_hero_hp() -> void:
	var card := _make_card()
	var hero := _make_hero(0, 50, 100, 0, 10)
	card.set_hero(hero)
	var hp_bar := card.get_node("%HpBar") as ProgressBar
	_expect_equal(hp_bar.value, 0.5, "hp bar reflects half health")
	card.queue_free()
	await process_frame


func _test_charge_bar_reflects_hero_charge() -> void:
	var card := _make_card()
	var hero := _make_hero(0, 100, 100, 5, 10)
	card.set_hero(hero)
	var charge_bar := card.get_node("%ChargeBar") as ProgressBar
	_expect_equal(charge_bar.value, 0.5, "charge bar reflects half charge")
	card.queue_free()
	await process_frame


func _test_full_charge_is_ready() -> void:
	var card := _make_card()
	var hero := _make_hero(0, 100, 100, 10, 10)
	card.set_hero(hero)
	_expect_true(card.is_ready_state(), "full charge enables ready state")
	card.queue_free()
	await process_frame


func _test_partial_charge_is_not_ready() -> void:
	var card := _make_card()
	var hero := _make_hero(0, 100, 100, 9, 10)
	card.set_hero(hero)
	_expect_false(card.is_ready_state(), "partial charge does not enable ready state")
	card.queue_free()
	await process_frame


func _test_dead_hero_is_down() -> void:
	var card := _make_card()
	var hero := _make_hero(0, 0, 100, 10, 10)
	card.set_hero(hero)
	_expect_true(card.is_down_state(), "defeated hero shows down state")
	_expect_false(card.is_ready_state(), "defeated hero is never ready")
	var hp_bar := card.get_node("%HpBar") as ProgressBar
	_expect_equal(hp_bar.value, 0.0, "defeated hero shows empty hp bar")
	card.queue_free()
	await process_frame


func _test_press_emits_ability_pressed_with_lane_index() -> void:
	var card := _make_card()
	var hero := _make_hero(2, 100, 100, 3, 10)
	card.set_hero(hero)

	var pressed_lanes: Array = []
	card.ability_pressed.connect(func(lane_index: int): pressed_lanes.append(lane_index))

	var portrait_button := card.get_node("%PortraitButton") as Button
	portrait_button.pressed.emit()
	_expect_equal(pressed_lanes, [2], "portrait press emits ability_pressed with lane index")
	card.queue_free()
	await process_frame


func _test_null_hero_disables_press() -> void:
	var card := _make_card()
	card.set_hero(null)
	var portrait_button := card.get_node("%PortraitButton") as Button
	_expect_true(portrait_button.disabled, "empty slot disables portrait press")
	card.queue_free()
	await process_frame


func _test_zero_max_values_are_safe() -> void:
	var card := _make_card()
	var hero := _make_hero(0, 0, 0, 0, 0)
	card.set_hero(hero)
	var hp_bar := card.get_node("%HpBar") as ProgressBar
	var charge_bar := card.get_node("%ChargeBar") as ProgressBar
	_expect_equal(hp_bar.value, 0.0, "zero max hp is handled safely")
	_expect_equal(charge_bar.value, 0.0, "zero max charge is handled safely")
	card.queue_free()
	await process_frame


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

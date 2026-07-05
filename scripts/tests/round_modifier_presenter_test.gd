extends SceneTree

const BATTLE_PRESENTER_SCRIPT := "res://scripts/game/presentation/battle_presenter.gd"
const ROUND_MODIFIER_CATALOG_SCRIPT := "res://scripts/game/config/round_modifier_catalog.gd"

var _failures := 0


func _initialize() -> void:
	print("Running round modifier presenter tests...")

	var modifier_catalog = load(ROUND_MODIFIER_CATALOG_SCRIPT).new()

	var presenter = load(BATTLE_PRESENTER_SCRIPT).new()
	presenter.set_enemy_rng_seed(24)
	presenter.set_background_rng_seed(24)
	presenter.set_round_modifier_rng_seed(24)
	presenter.start_level("level_1")

	_expect_true(presenter.get_current_round_modifier() != null, "start_level selects a round modifier")
	_expect_true(modifier_catalog.has_modifier(presenter.get_current_round_modifier().modifier_id), "selected modifier exists in catalog")

	var emitted_modifiers: Array = []
	presenter.round_modifier_changed.connect(func(modifier): emitted_modifiers.append(modifier))
	presenter.start_level("level_2")
	_expect_equal(emitted_modifiers.size(), 1, "round_modifier_changed is emitted on start_level")
	_expect_equal(emitted_modifiers[0].modifier_id, presenter.get_current_round_modifier().modifier_id, "emitted modifier matches current_round_modifier")

	var first_presenter = load(BATTLE_PRESENTER_SCRIPT).new()
	first_presenter.set_round_modifier_rng_seed(555)
	first_presenter.set_enemy_rng_seed(1)
	first_presenter.start_level("level_1")

	var second_presenter = load(BATTLE_PRESENTER_SCRIPT).new()
	second_presenter.set_round_modifier_rng_seed(555)
	second_presenter.set_enemy_rng_seed(1)
	second_presenter.start_level("level_1")

	_expect_equal(first_presenter.get_current_round_modifier().modifier_id, second_presenter.get_current_round_modifier().modifier_id, "seeded round modifier RNG is reproducible")

	presenter.start_level("level_100")
	_expect_true(presenter.get_current_round_modifier() != null, "start_level(level_100) selects a valid round modifier")
	_expect_true(modifier_catalog.has_modifier(presenter.get_current_round_modifier().modifier_id), "level_100 modifier exists in catalog")

	_test_modifier_selection_independent_from_enemy_and_background()

	if _failures == 0:
		print("Round modifier presenter tests passed.")
		quit(0)
	else:
		push_error("Round modifier presenter tests failed: %d" % _failures)
		quit(1)


func _test_modifier_selection_independent_from_enemy_and_background() -> void:
	var enemy_only_presenter = load(BATTLE_PRESENTER_SCRIPT).new()
	enemy_only_presenter.set_enemy_rng_seed(99)
	enemy_only_presenter.set_background_rng_seed(1)
	enemy_only_presenter.set_round_modifier_rng_seed(42)
	enemy_only_presenter.start_level("level_1")

	var other_enemy_presenter = load(BATTLE_PRESENTER_SCRIPT).new()
	other_enemy_presenter.set_enemy_rng_seed(12345)
	other_enemy_presenter.set_background_rng_seed(1)
	other_enemy_presenter.set_round_modifier_rng_seed(42)
	other_enemy_presenter.start_level("level_1")

	_expect_equal(enemy_only_presenter.get_current_round_modifier().modifier_id, other_enemy_presenter.get_current_round_modifier().modifier_id, "round modifier selection does not depend on enemy RNG seed")
	print("ok - round modifier selection is independent from enemy and background selection")


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

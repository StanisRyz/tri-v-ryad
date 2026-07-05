extends SceneTree

const BATTLE_PRESENTER_SCRIPT := "res://scripts/game/presentation/battle_presenter.gd"
const BATTLE_BACKGROUND_CATALOG_SCRIPT := "res://scripts/game/config/battle_background_catalog.gd"
const ENEMY_CATALOG_SCRIPT := "res://scripts/game/config/enemy_catalog.gd"

var _failures := 0


func _initialize() -> void:
	print("Running battle background presenter tests...")

	var background_catalog = load(BATTLE_BACKGROUND_CATALOG_SCRIPT).new()
	var enemy_catalog = load(ENEMY_CATALOG_SCRIPT).new()

	var presenter = load(BATTLE_PRESENTER_SCRIPT).new()
	presenter.set_enemy_rng_seed(24)
	presenter.set_background_rng_seed(24)
	presenter.start_level("level_1")

	_expect_true(presenter.get_current_background() != null, "start_level selects a background")
	_expect_true(background_catalog.has_background(presenter.get_current_background().background_id), "selected background exists in catalog")
	_expect_true(enemy_catalog.has_enemy(presenter.state.enemy.id), "enemy selection still works")

	var moves_before: int = presenter.state.moves_left
	var background_before_id: String = presenter.get_current_background().background_id
	_expect_equal(presenter.state.moves_left, moves_before, "background selection does not change moves")
	_expect_equal(presenter.get_current_background().background_id, background_before_id, "background is stable after read")

	var first_presenter = load(BATTLE_PRESENTER_SCRIPT).new()
	first_presenter.set_background_rng_seed(555)
	first_presenter.set_enemy_rng_seed(1)
	first_presenter.start_level("level_1")

	var second_presenter = load(BATTLE_PRESENTER_SCRIPT).new()
	second_presenter.set_background_rng_seed(555)
	second_presenter.set_enemy_rng_seed(1)
	second_presenter.start_level("level_1")

	_expect_equal(first_presenter.get_current_background().background_id, second_presenter.get_current_background().background_id, "seeded background RNG is reproducible")

	presenter.start_level("level_100")
	_expect_true(presenter.get_current_background() != null, "level_100 selects a valid background")
	_expect_true(background_catalog.has_background(presenter.get_current_background().background_id), "level_100 background exists in catalog")
	_expect_true(enemy_catalog.has_enemy(presenter.state.enemy.id), "level_100 enemy still valid")

	if _failures == 0:
		print("Battle background presenter tests passed.")
		quit(0)
	else:
		push_error("Battle background presenter tests failed: %d" % _failures)
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

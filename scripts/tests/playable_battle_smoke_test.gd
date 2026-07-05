extends SceneTree

const BATTLE_PRESENTER_SCRIPT := "res://scripts/game/presentation/battle_presenter.gd"
const ENEMY_CATALOG_SCRIPT := "res://scripts/game/config/enemy_catalog.gd"
const BATTLE_BACKGROUND_CATALOG_SCRIPT := "res://scripts/game/config/battle_background_catalog.gd"

var _failures := 0


func _initialize() -> void:
	print("Running playable battle smoke test...")

	var presenter = load(BATTLE_PRESENTER_SCRIPT).new()
	var enemy_catalog = load(ENEMY_CATALOG_SCRIPT).new()
	var background_catalog = load(BATTLE_BACKGROUND_CATALOG_SCRIPT).new()
	presenter.set_enemy_rng_seed(24)
	presenter.set_background_rng_seed(24)
	presenter.start_new_battle()

	_expect_true(presenter.board != null, "presenter created board")
	_expect_true(presenter.state != null, "presenter created battle state")
	_expect_true(enemy_catalog.has_enemy(presenter.state.enemy.id), "presenter selected enemy from catalog")
	_expect_true(background_catalog.has_background(presenter.get_current_background().background_id), "presenter selected background from catalog")
	_expect_false(presenter.board.has_empty_cells(), "presenter board is full")

	var swap := _find_valid_swap(presenter.board)
	_expect_true(not swap.is_empty(), "presenter board has at least one valid swap")

	if not swap.is_empty():
		var starting_moves: int = presenter.state.moves_left
		var starting_enemy_hp: int = presenter.state.enemy.current_hp
		presenter.request_swap(swap["from"], swap["to"])
		_expect_equal(presenter.state.moves_left, starting_moves - 1, "valid swap consumes one move")
		_expect_true(presenter.state.enemy.current_hp < starting_enemy_hp, "valid swap damages enemy")
		_expect_false(presenter.board.has_empty_cells(), "board remains full after turn")

	presenter.start_level("level_2")
	_expect_equal(presenter.current_level_id, "level_2", "presenter starts requested level")
	_expect_true(enemy_catalog.has_enemy(presenter.state.enemy.id), "level 2 selected enemy exists in catalog")
	_expect_equal(presenter.state.moves_left, presenter.current_level_config.moves, "level 2 moves count")

	presenter.start_level("level_100")
	_expect_equal(presenter.current_level_id, "level_100", "presenter starts level_100")
	_expect_true(presenter.board != null, "level_100 created board")
	_expect_true(presenter.state != null, "level_100 created battle state")
	_expect_false(presenter.board.has_empty_cells(), "level_100 board is full")
	_expect_true(enemy_catalog.has_enemy(presenter.state.enemy.id), "level_100 selected enemy exists in catalog")
	var base_enemy = enemy_catalog.get_enemy(presenter.state.enemy.id)
	_expect_true(presenter.state.enemy.max_hp >= base_enemy.max_hp, "level_100 enemy hp is at least base hp")
	_expect_true(presenter.state.enemy.attack >= base_enemy.attack, "level_100 enemy attack is at least base attack")
	_expect_equal(presenter.state.moves_left, presenter.current_level_config.moves, "level_100 moves count")

	if _failures == 0:
		print("Playable battle smoke test passed.")
		quit(0)
	else:
		push_error("Playable battle smoke test failed: %d" % _failures)
		quit(1)


func _find_valid_swap(board) -> Dictionary:
	var swap_resolver = SwapResolver.new()

	for cell in board.get_all_cells():
		for offset in [Vector2i.RIGHT, Vector2i.DOWN]:
			var neighbor: Vector2i = cell + offset
			if not board.is_inside(neighbor):
				continue

			var copy = board.duplicate_board()
			if swap_resolver.try_swap(copy, cell, neighbor).accepted:
				return {
					"from": cell,
					"to": neighbor,
				}

	return {}


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

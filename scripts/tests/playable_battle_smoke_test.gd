extends SceneTree

const BATTLE_PRESENTER_SCRIPT := "res://scripts/game/presentation/battle_presenter.gd"

var _failures := 0


func _initialize() -> void:
	print("Running playable battle smoke test...")

	var presenter = load(BATTLE_PRESENTER_SCRIPT).new()
	presenter.start_new_battle()

	_expect_true(presenter.board != null, "presenter created board")
	_expect_true(presenter.state != null, "presenter created battle state")
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

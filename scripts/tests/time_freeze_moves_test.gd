extends SceneTree

const BATTLE_PRESENTER_SCRIPT := preload("res://scripts/game/presentation/battle_presenter.gd")

var _failures := 0


func _initialize() -> void:
	print("Running time freeze moves tests...")

	var presenter = BATTLE_PRESENTER_SCRIPT.new()
	presenter.set_enemy_rng_seed(40)
	presenter.set_background_rng_seed(40)
	presenter.set_round_modifier_rng_seed(40)
	presenter.start_new_battle()

	var starting_moves: int = presenter.state.moves_left
	presenter.request_booster_activation("freeze_time")
	_expect_equal(presenter.state.moves_left, starting_moves, "freeze activation does not consume moves")
	_expect_equal(presenter.state.get("booster_state").freeze_turns_left, 3, "freeze adds three free turns")

	var invalid_from := Vector2i(0, 0)
	var invalid_to := Vector2i(8, 8)
	presenter.request_swap(invalid_from, invalid_to)
	_expect_equal(presenter.state.get("booster_state").freeze_turns_left, 3, "invalid swap does not consume freeze turn")
	_expect_equal(presenter.state.moves_left, starting_moves, "invalid swap does not consume moves")

	for index in range(3):
		var swap := _find_valid_swap(presenter.board)
		_expect_true(not swap.is_empty(), "valid swap exists for freeze turn %d" % index)
		if swap.is_empty():
			break
		presenter.request_swap(swap["from"], swap["to"])
		_expect_equal(presenter.state.moves_left, starting_moves, "freeze turn keeps moves unchanged")

	_expect_equal(presenter.state.get("booster_state").freeze_turns_left, 0, "three successful turns consume freeze")
	var next_swap := _find_valid_swap(presenter.board)
	if not next_swap.is_empty():
		presenter.request_swap(next_swap["from"], next_swap["to"])
		_expect_equal(presenter.state.moves_left, starting_moves - 1, "moves decrement after freeze ends")

	_finish()


func _find_valid_swap(board) -> Dictionary:
	var swap_resolver := SwapResolver.new()
	for cell in board.get_all_cells():
		for offset in [Vector2i.RIGHT, Vector2i.DOWN]:
			var neighbor: Vector2i = cell + offset
			if not board.is_inside(neighbor):
				continue
			var copy: BoardModel = board.duplicate_board()
			if swap_resolver.try_swap(copy, cell, neighbor).accepted:
				return {"from": cell, "to": neighbor}
	return {}


func _finish() -> void:
	if _failures == 0:
		print("Time freeze moves tests passed.")
		quit(0)
	else:
		push_error("Time freeze moves tests failed: %d" % _failures)
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

extends SceneTree

const BOOSTER_CATALOG_SCRIPT := preload("res://scripts/game/config/booster_catalog.gd")
const BOOSTER_RESOLVER_SCRIPT := preload("res://scripts/game/battle/booster_resolver.gd")

var _failures := 0


func _initialize() -> void:
	print("Running booster resolver tests...")

	var resolver = BOOSTER_RESOLVER_SCRIPT.new()
	var board := _make_board()
	_expect_equal(resolver.get_hammer_cells(board, Vector2i(4, 4)).size(), 9, "hammer center clears 9 cells")
	_expect_equal(resolver.get_hammer_cells(board, Vector2i(0, 0)).size(), 4, "hammer corner clears 4 cells")
	_expect_equal(resolver.get_hammer_cells(board, Vector2i(0, 4)).size(), 6, "hammer edge clears 6 cells")
	_expect_equal(resolver.get_rocket_cells(board, Vector2i(0, 0)).size(), 16, "rocket clears all selected color cells")

	var battle_state := _make_battle_state(board)
	var invalid = resolver.resolve_targeted_booster(battle_state, "hammer", Vector2i(-1, -1), null)
	_expect_true(not invalid.is_valid, "invalid target fails safely")
	_expect_equal(battle_state.get("booster_state").get_uses_left("hammer"), 1, "invalid target does not consume use")

	var result = resolver.resolve_targeted_booster(battle_state, "hammer", Vector2i(4, 4), null)
	_expect_true(result.is_valid, "hammer resolves")
	_expect_equal(result.cleared_cells.size(), 9, "hammer result tracks cleared cells")
	_expect_equal(result.damage_to_enemy, 9, "hammer damage equals cleared cells without modifier")
	_expect_true(not battle_state.board.has_empty_cells(), "board refills after hammer")
	_expect_equal(battle_state.get("booster_state").get_uses_left("hammer"), 0, "hammer use consumed")

	var second = resolver.resolve_targeted_booster(battle_state, "hammer", Vector2i(4, 4), null)
	_expect_true(not second.is_valid, "booster cannot be used with zero uses")

	_finish()


func _make_board() -> BoardModel:
	var board := BoardModel.new()
	var tile_types := TileType.get_all_types()
	for cell in board.get_all_cells():
		board.set_tile(cell, tile_types[(cell.x + cell.y) % tile_types.size()])
	return board


func _make_battle_state(board: BoardModel) -> BattleState:
	var state := BattleState.new([], EnemyConfig.training_dummy().to_enemy_data(), EnemyConfig.training_dummy().to_enemy_intent(), 10)
	state.board = board
	state.get("booster_state").setup_from_catalog(BOOSTER_CATALOG_SCRIPT.new())
	return state


func _finish() -> void:
	if _failures == 0:
		print("Booster resolver tests passed.")
		quit(0)
	else:
		push_error("Booster resolver tests failed: %d" % _failures)
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

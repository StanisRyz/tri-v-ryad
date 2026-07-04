extends RefCounted
class_name BattlePresenter

signal board_changed(board: BoardModel)
signal battle_state_changed(state: BattleState)
signal turn_resolved(result: BattleTurnResult)
signal invalid_swap(reason: String)
signal battle_finished(status: int)

var board: BoardModel
var state: BattleState

var _board_generator := BoardGenerator.new()
var _swap_resolver := SwapResolver.new()
var _board_resolver := BoardResolver.new()
var _battle_resolver := BattleResolver.new()


func start_new_battle() -> void:
	board = _generate_playable_board()
	state = _create_test_battle_state()
	board_changed.emit(board)
	battle_state_changed.emit(state)


func request_swap(from_cell: Vector2i, to_cell: Vector2i) -> void:
	if board == null or state == null or is_battle_finished():
		return

	var swap_result := _swap_resolver.try_swap(board, from_cell, to_cell)
	if not swap_result.accepted:
		invalid_swap.emit(swap_result.reason)
		board_changed.emit(board)
		return

	var battle_result := _battle_resolver.resolve_player_matches(state, swap_result.matches)
	_board_resolver.resolve_board(board)

	board_changed.emit(board)
	battle_state_changed.emit(state)
	turn_resolved.emit(battle_result)

	if state.is_finished():
		battle_finished.emit(state.status)


func is_battle_finished() -> bool:
	return state != null and state.is_finished()


func _create_test_battle_state() -> BattleState:
	var heroes: Array[HeroData] = [
		HeroData.new("hero_1", "Hero 1", 0, 10, 100, 0, 0, 10),
		HeroData.new("hero_2", "Hero 2", 1, 8, 120, 0, 0, 10),
		HeroData.new("hero_3", "Hero 3", 2, 12, 80, 0, 0, 10),
	]
	var enemy := EnemyData.new("enemy_training", "Training Enemy", 300, 20)
	var enemy_intent := EnemyIntent.new(3, 1)
	return BattleState.new(heroes, enemy, enemy_intent, 20)


func _generate_playable_board() -> BoardModel:
	for attempt in range(100):
		var candidate := _board_generator.generate()
		if _has_valid_move(candidate):
			return candidate

	return _board_generator.generate()


func _has_valid_move(candidate: BoardModel) -> bool:
	for cell in candidate.get_all_cells():
		for offset in [Vector2i.RIGHT, Vector2i.DOWN]:
			var neighbor: Vector2i = cell + offset
			if not candidate.is_inside(neighbor):
				continue

			var copy: BoardModel = candidate.duplicate_board()
			if _swap_resolver.try_swap(copy, cell, neighbor).accepted:
				return true

	return false

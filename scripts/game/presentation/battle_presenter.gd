extends RefCounted
class_name BattlePresenter

const TURN_PRESENTATION_DATA_SCRIPT := preload("res://scripts/game/presentation/turn_presentation_data.gd")
const ABILITY_PRESENTER_DATA_SCRIPT := preload("res://scripts/game/presentation/ability_presentation_data.gd")
const ABILITY_RESULT_SCRIPT := preload("res://scripts/game/battle/ability_result.gd")
const ABILITY_RESOLVER_SCRIPT := preload("res://scripts/game/battle/ability_resolver.gd")

signal board_changed(board: BoardModel)
signal battle_state_changed(state: BattleState)
signal turn_resolved(result: BattleTurnResult)
signal turn_presentation_ready(data)
signal ability_presentation_ready(data)
signal invalid_swap(reason: String)
signal battle_finished(status: int)

var board: BoardModel
var state: BattleState

var _board_generator := BoardGenerator.new()
var _swap_resolver := SwapResolver.new()
var _board_resolver := BoardResolver.new()
var _battle_resolver := BattleResolver.new()
var _ability_resolver = ABILITY_RESOLVER_SCRIPT.new()


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
		turn_presentation_ready.emit(TURN_PRESENTATION_DATA_SCRIPT.from_invalid_turn(from_cell, to_cell, swap_result.reason))
		invalid_swap.emit(swap_result.reason)
		board_changed.emit(board)
		return

	var battle_result := _battle_resolver.resolve_player_matches(state, swap_result.matches)
	var presentation_data = TURN_PRESENTATION_DATA_SCRIPT.from_valid_turn(from_cell, to_cell, swap_result.matches, battle_result)
	_board_resolver.resolve_board(board)

	board_changed.emit(board)
	battle_state_changed.emit(state)
	turn_resolved.emit(battle_result)
	turn_presentation_ready.emit(presentation_data)

	if state.is_finished():
		battle_finished.emit(state.status)


func request_ability(lane_index: int) -> void:
	var result
	if board == null or state == null:
		result = ABILITY_RESULT_SCRIPT.rejected_result("", lane_index, "invalid_state")
	elif state.is_finished():
		result = ABILITY_RESULT_SCRIPT.rejected_result("", lane_index, "battle_finished")
	else:
		result = _ability_resolver.resolve_ability(state, board, lane_index)

	ability_presentation_ready.emit(ABILITY_PRESENTER_DATA_SCRIPT.from_result(result))

	if result.board_changed:
		board_changed.emit(board)

	if state != null:
		battle_state_changed.emit(state)
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

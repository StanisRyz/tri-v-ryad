extends RefCounted
class_name AnimatedTurnFlow

## Stage 46 v0.1: orchestrates a single player turn (swap or targeted booster)
## so the board only advances one phase at a time, in lockstep with its
## animation: play swap -> check current matches -> clear -> gravity/refill ->
## check cascades -> repeat until stable -> only then hand off accumulated
## results to BattlePresenter for damage/battle-state/result flow.
##
## The board view is expected to already be in animation overlay mode (see
## BoardView.enter_animation_overlay_mode) for the whole duration of the flow;
## this class never calls board_view.set_board() mid-flow, it only plays
## animation requests that keep the overlay ghosts in sync with the
## BoardModel mutations applied here.

signal _step_finished

var _stepwise_resolver := StepwiseBoardResolver.new()
var _direct_damage_resolver := DirectMatchDamageResolver.new()
var _board_view: Control
var _board_animation_controller
var _sequence_builder
var _generation := 0
var _running := false


func configure(board_view: Control, board_animation_controller, sequence_builder) -> void:
	_board_view = board_view
	_board_animation_controller = board_animation_controller
	_sequence_builder = sequence_builder


func is_running() -> bool:
	return _running


func cancel() -> void:
	_generation += 1
	_running = false
	_step_finished.emit()


func start_swap_turn(board: BoardModel, presenter, from_cell: Vector2i, to_cell: Vector2i, matches: Array) -> void:
	var generation := _begin()

	await _play_sequence(_sequence_builder.build_swap_sequence(from_cell, to_cell))
	if not _is_current(generation):
		return

	var board_result := BoardResolveResult.new()
	var cascade_index := 0
	var current_matches := _stepwise_resolver.find_current_matches(board)
	# Only the first (player-swap) resolve step prefers the swapped cells for
	# special-tile placement; cascade/gravity-created specials fall back to
	# StepwiseBoardResolver's deterministic center-cell logic.
	var preferred_cells: Array[Vector2i] = [to_cell, from_cell]

	while not current_matches.is_empty():
		var step := _stepwise_resolver.build_clear_step(board, current_matches, cascade_index, preferred_cells)
		await _play_sequence(_sequence_builder.build_clear_sequence(step))
		if not _is_current(generation):
			return

		_stepwise_resolver.apply_clear_step(board, step)
		_stepwise_resolver.apply_gravity_step(board, step)
		await _play_sequence(_sequence_builder.build_gravity_refill_sequence(step))
		if not _is_current(generation):
			return

		board_result.add_step(
			step.matches,
			step.cleared_cells,
			{"fall_movements": step.fall_movements, "refill_cells": step.refill_cells},
			step.created_special_tiles,
			step.activated_special_tiles,
			step.special_cleared_cells
		)

		cascade_index += 1
		current_matches = _stepwise_resolver.find_current_matches(board)
		preferred_cells = []

	_end(generation)
	presenter.finalize_swap_turn(from_cell, to_cell, matches, board_result)


func start_booster_clear(board: BoardModel, presenter, result) -> void:
	var generation := _begin()

	await _play_sequence(_sequence_builder.build_booster_activation_and_clear_sequence(result.cleared_cells, result.booster_id, result.target_cell, result.damage_to_enemy, result.affected_tile_types))
	if not _is_current(generation):
		return

	await _play_sequence(_sequence_builder.build_gravity_refill_sequence(result))
	if not _is_current(generation):
		return

	var cascade_index := 0
	var extra_cleared: Array[Vector2i] = []
	var extra_fall_movements: Array[Dictionary] = []
	var extra_refill_cells: Array[Dictionary] = []
	var extra_cascade_steps: Array[Dictionary] = []
	var merged_tile_types: Dictionary = {}
	var current_matches := _stepwise_resolver.find_current_matches(board)

	while not current_matches.is_empty():
		var step := _stepwise_resolver.build_clear_step(board, current_matches, cascade_index)
		await _play_sequence(_sequence_builder.build_clear_sequence(step))
		if not _is_current(generation):
			return

		_stepwise_resolver.apply_clear_step(board, step)
		_stepwise_resolver.apply_gravity_step(board, step)
		await _play_sequence(_sequence_builder.build_gravity_refill_sequence(step))
		if not _is_current(generation):
			return

		extra_cleared.append_array(step.cleared_cells)
		extra_fall_movements.append_array(step.fall_movements)
		extra_refill_cells.append_array(step.refill_cells)
		merged_tile_types.merge(step.damage_tile_types)
		extra_cascade_steps.append({
			"cascade_index": cascade_index,
			"matched_cells": step.cleared_cells.duplicate(),
			"special_cleared_cells": step.special_cleared_cells.duplicate(),
			"fall_movements": step.fall_movements.duplicate(true),
			"refill_cells": step.refill_cells.duplicate(true),
			"damage": 0,
		})

		cascade_index += 1
		current_matches = _stepwise_resolver.find_current_matches(board)

	if not extra_cleared.is_empty():
		_apply_cascade_damage(presenter, result, extra_cleared, extra_fall_movements, extra_refill_cells, extra_cascade_steps, merged_tile_types)

	_end(generation)
	presenter.finalize_booster_turn(result)


func _apply_cascade_damage(presenter, result, extra_cleared: Array[Vector2i], extra_fall_movements: Array[Dictionary], extra_refill_cells: Array[Dictionary], extra_cascade_steps: Array[Dictionary], merged_tile_types: Dictionary) -> void:
	var damage_info := _direct_damage_resolver.calculate_damage_for_typed_cells(extra_cleared, merged_tile_types, presenter.get_current_round_modifier())
	var extra_damage := int(damage_info.get("total_damage", 0))

	if extra_damage > 0 and presenter.state != null and presenter.state.enemy != null:
		presenter.state.enemy.take_damage(extra_damage)
		presenter.state.update_status()
		result.damage_to_enemy += extra_damage

	result.cleared_cells.append_array(extra_cleared)
	result.fall_movements.append_array(extra_fall_movements)
	result.refill_cells.append_array(extra_refill_cells)
	result.cascade_steps = extra_cascade_steps
	for cell in extra_cleared:
		if merged_tile_types.has(cell):
			result.cleared_cell_tile_types[cell] = merged_tile_types[cell]


func _begin() -> int:
	_generation += 1
	_running = true
	return _generation


func _end(generation: int) -> void:
	if _generation == generation:
		_running = false


func _is_current(generation: int) -> bool:
	return _generation == generation


func _play_sequence(sequence) -> void:
	if _board_animation_controller == null or _board_view == null:
		return

	# Array is a reference type, so this box is safely mutated by the
	# closure below even though it fires after this function has already
	# moved past the call (GDScript lambdas capture locals by value, so a
	# plain bool would not observe a synchronous finish).
	var finished_box := [false]
	_board_animation_controller.play_sequence(sequence, _board_view, func() -> void:
		finished_box[0] = true
		_step_finished.emit()
	)
	if not finished_box[0]:
		await _step_finished

extends RefCounted
class_name StepwiseBoardResolver

## Same clear/gravity/special rules as BoardResolver, but exposed one phase at
## a time so presentation code can animate between finding matches, clearing
## them, and applying gravity/refill instead of precomputing the whole board.

const SPECIAL_TILE_DATA_SCRIPT := preload("res://scripts/game/board/special_tile_data.gd")
const SPECIAL_TILE_RESOLVER_SCRIPT := preload("res://scripts/game/board/special_tile_resolver.gd")
const SPECIAL_TILE_TYPE_SCRIPT := preload("res://scripts/game/board/special_tile_type.gd")
const BOARD_RESOLVE_STEP_SCRIPT := preload("res://scripts/game/board/board_resolve_step.gd")

var _match_finder := MatchFinder.new()
var _gravity_resolver: GravityResolver
var _special_tile_resolver := SPECIAL_TILE_RESOLVER_SCRIPT.new()


func _init(gravity_resolver: GravityResolver = null) -> void:
	_gravity_resolver = gravity_resolver if gravity_resolver != null else GravityResolver.new()


func find_current_matches(board: BoardModel) -> Array[MatchResult]:
	return _match_finder.find_matches(board)


func build_clear_step(board: BoardModel, matches: Array[MatchResult], cascade_index: int, preferred_cells: Array[Vector2i] = []) -> BoardResolveStep:
	var step := BOARD_RESOLVE_STEP_SCRIPT.new()
	step.cascade_index = cascade_index
	step.matches = matches.duplicate()

	var clear_seen := {}
	var protected_special_cells := {}
	var matched_seen := {}

	for match_result in matches:
		var creation_cell := Vector2i(-1, -1)
		if _special_tile_resolver.should_create_special(match_result):
			creation_cell = _special_tile_resolver.choose_special_cell_for_match(match_result, preferred_cells)
			var special_type := _special_tile_resolver.get_special_type_for_match(match_result)
			if board.is_inside(creation_cell) and SPECIAL_TILE_TYPE_SCRIPT.is_valid(special_type) and special_type != SPECIAL_TILE_TYPE_SCRIPT.NONE:
				board.set_special_tile(creation_cell, SPECIAL_TILE_DATA_SCRIPT.from_type(special_type))
				protected_special_cells[creation_cell] = true
				step.created_special_tiles.append({
					"cell": creation_cell,
					"special_type": special_type,
					"source_cells": match_result.cells.duplicate(),
					"tile_type": match_result.tile_type,
				})

		for cell in match_result.cells:
			_add_unique_cell(step.matched_cells, matched_seen, cell)
			step.damage_tile_types[cell] = match_result.tile_type
			if protected_special_cells.has(cell):
				continue
			_add_unique_cell(step.cleared_cells, clear_seen, cell)

	var activation_cells := _special_tile_resolver.collect_special_activation_cells(board, step.cleared_cells)
	var special_cleared_seen := {}

	for activation_cell in activation_cells:
		var special_data = board.get_special_tile(activation_cell)
		if special_data == null:
			continue

		step.activated_special_tiles.append({
			"cell": activation_cell,
			"special_type": special_data.special_type,
		})
		var special_cells: Array[Vector2i] = []
		var base_tile_type := BoardModel.EMPTY
		if special_data.is_color_bomb():
			base_tile_type = board.get_tile(activation_cell)
			special_cells = _special_tile_resolver.get_color_bomb_clear_cells(board, activation_cell, special_data)
		else:
			special_cells = _special_tile_resolver.get_line_clear_cells(board, activation_cell, special_data)

		var affected_cells: Array[Vector2i] = []

		for special_cell in special_cells:
			if protected_special_cells.has(special_cell):
				continue
			affected_cells.append(special_cell)
			_add_unique_cell(step.cleared_cells, clear_seen, special_cell)
			_add_unique_cell(step.special_cleared_cells, special_cleared_seen, special_cell)

		var activation_data: Dictionary = step.activated_special_tiles[step.activated_special_tiles.size() - 1]
		activation_data["affected_cells"] = affected_cells.duplicate()
		activation_data["base_tile_type"] = base_tile_type

	return step


func apply_clear_step(board: BoardModel, step: BoardResolveStep) -> void:
	board.clear_cells(step.cleared_cells)


func apply_gravity_step(board: BoardModel, step: BoardResolveStep) -> void:
	var gravity_result := _gravity_resolver.apply_gravity_and_refill(board)
	step.fall_movements = _to_dictionary_array(gravity_result.get("fall_movements", []))
	step.refill_cells = _to_dictionary_array(gravity_result.get("refill_cells", []))


func resolve_next_step(board: BoardModel, cascade_index: int) -> BoardResolveStep:
	var matches := find_current_matches(board)
	if matches.is_empty():
		return BOARD_RESOLVE_STEP_SCRIPT.stable_step(cascade_index)

	var step := build_clear_step(board, matches, cascade_index)
	apply_clear_step(board, step)
	apply_gravity_step(board, step)
	return step


func _add_unique_cell(cells: Array[Vector2i], seen: Dictionary, cell: Vector2i) -> void:
	if seen.has(cell):
		return

	seen[cell] = true
	cells.append(cell)


func _to_dictionary_array(values: Array) -> Array[Dictionary]:
	var typed_values: Array[Dictionary] = []
	for value in values:
		typed_values.append(value as Dictionary)
	return typed_values

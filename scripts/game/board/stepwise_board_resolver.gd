extends RefCounted
class_name StepwiseBoardResolver

## Same clear/gravity/special rules as BoardResolver, but exposed one phase at
## a time so presentation code can animate between finding matches, clearing
## them, and applying gravity/refill instead of precomputing the whole board.

const SPECIAL_TILE_DATA_SCRIPT := preload("res://scripts/game/board/special_tile_data.gd")
const SPECIAL_TILE_RESOLVER_SCRIPT := preload("res://scripts/game/board/special_tile_resolver.gd")
const SPECIAL_TILE_TYPE_SCRIPT := preload("res://scripts/game/board/special_tile_type.gd")
const BOARD_RESOLVE_STEP_SCRIPT := preload("res://scripts/game/board/board_resolve_step.gd")
const ICE_DAMAGE_RESOLVER_SCRIPT := preload("res://scripts/game/board/ice_damage_resolver.gd")

var _match_finder := MatchFinder.new()
var _gravity_resolver: GravityResolver
var _special_tile_resolver := SPECIAL_TILE_RESOLVER_SCRIPT.new()
var _ice_damage_resolver := ICE_DAMAGE_RESOLVER_SCRIPT.new()


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
			if board.is_playable_cell(creation_cell) and SPECIAL_TILE_TYPE_SCRIPT.is_valid(special_type) and special_type != SPECIAL_TILE_TYPE_SCRIPT.NONE:
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

	## Stage 67.1 v0.1: resolve_special_activation_chain() replaces a single
	## activation pass with a queue that keeps draining as long as a special's
	## blast sweeps up another pre-existing special tile, so chains like
	## "line special hits color bomb hits line special" fully resolve within
	## this one clear step instead of silently clearing the later specials
	## without triggering them.
	var chain: Dictionary = _special_tile_resolver.resolve_special_activation_chain(board, step.cleared_cells, protected_special_cells)
	step.cleared_cells = chain.get("cleared_cells", step.cleared_cells)
	step.activated_special_tiles = chain.get("activated_special_tiles", [])
	step.special_cleared_cells = chain.get("special_cleared_cells", [])
	step.damage_counted_cells = _union_cells(step.matched_cells, step.special_cleared_cells)

	## Preview only: the board hasn't been mutated by this step yet, so this
	## reads pre-clear obstacle state to predict what apply_clear_step() will
	## do, letting presentation play ice feedback before the tile clear fade.
	step.ice_events = _ice_damage_resolver.preview_ice_damage(board, step.cleared_cells)

	return step


func apply_clear_step(board: BoardModel, step: BoardResolveStep) -> void:
	board.clear_cells(step.cleared_cells)
	_ice_damage_resolver.apply_ice_damage(board, step.cleared_cells)


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


func _union_cells(a: Array[Vector2i], b: Array[Vector2i]) -> Array[Vector2i]:
	var seen := {}
	var result: Array[Vector2i] = []
	for cell in a:
		if seen.has(cell):
			continue
		seen[cell] = true
		result.append(cell)
	for cell in b:
		if seen.has(cell):
			continue
		seen[cell] = true
		result.append(cell)
	return result


func _to_dictionary_array(values: Array) -> Array[Dictionary]:
	var typed_values: Array[Dictionary] = []
	for value in values:
		typed_values.append(value as Dictionary)
	return typed_values

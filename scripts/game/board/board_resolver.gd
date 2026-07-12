extends RefCounted
class_name BoardResolver

const SPECIAL_TILE_DATA_SCRIPT := preload("res://scripts/game/board/special_tile_data.gd")
const SPECIAL_TILE_RESOLVER_SCRIPT := preload("res://scripts/game/board/special_tile_resolver.gd")
const SPECIAL_TILE_TYPE_SCRIPT := preload("res://scripts/game/board/special_tile_type.gd")
const ICE_DAMAGE_RESOLVER_SCRIPT := preload("res://scripts/game/board/ice_damage_resolver.gd")

const MAX_CASCADE_STEPS := 50

var _match_finder := MatchFinder.new()
var _gravity_resolver: GravityResolver
var _special_tile_resolver := SPECIAL_TILE_RESOLVER_SCRIPT.new()
var _ice_damage_resolver := ICE_DAMAGE_RESOLVER_SCRIPT.new()


func _init(gravity_resolver: GravityResolver = null) -> void:
	_gravity_resolver = gravity_resolver if gravity_resolver != null else GravityResolver.new()


func resolve_board(board: BoardModel) -> BoardResolveResult:
	var result := BoardResolveResult.new()

	for step_index in range(MAX_CASCADE_STEPS):
		var matches := _match_finder.find_matches(board)
		if matches.is_empty():
			break

		var step_data := _build_clear_step_data(board, matches)
		var cleared_cells := _to_vector2i_array(step_data.get("cleared_cells", []))
		board.clear_cells(cleared_cells)
		var ice_events := _ice_damage_resolver.apply_ice_damage(board, cleared_cells)
		var gravity_result := _gravity_resolver.apply_gravity_and_refill(board)
		result.add_step(
			matches,
			cleared_cells,
			gravity_result,
			_to_dictionary_array(step_data.get("created_special_tiles", [])),
			_to_dictionary_array(step_data.get("activated_special_tiles", [])),
			_to_vector2i_array(step_data.get("special_cleared_cells", [])),
			ice_events,
			_to_vector2i_array(step_data.get("matched_cells", []))
		)

	if board.has_empty_cells():
		push_error("BoardResolver finished with empty cells.")

	if _match_finder.has_matches(board):
		push_error("BoardResolver reached cascade safety limit before board became stable.")

	return result


## Stage 67.1 v0.1: canonical damage rule support. matched_cells is the full
## original match set (every cell in every MatchResult this step, including
## the cell that becomes a special crystal and therefore stays on the board);
## cleared_cells is the actually-removed set (matched_cells minus the special
## creation cell, plus whatever a chained special activation swept up).
## DirectMatchDamageResolver counts matched_cells + special_cleared_cells for
## damage, not cleared_cells, so a match that creates a special still deals
## full original-match-size damage. See special_tile_resolver.gd's
## resolve_special_activation_chain() for the special-triggers-special queue.
func _build_clear_step_data(board: BoardModel, matches: Array[MatchResult]) -> Dictionary:
	var clear_seen := {}
	var matched_seen := {}
	var protected_special_cells := {}
	var cleared_cells: Array[Vector2i] = []
	var matched_cells: Array[Vector2i] = []
	var created_special_tiles: Array[Dictionary] = []

	for match_result in matches:
		var creation_cell := Vector2i(-1, -1)
		if _special_tile_resolver.should_create_special(match_result):
			creation_cell = _special_tile_resolver.choose_special_cell(match_result)
			var special_type := _special_tile_resolver.get_special_type_for_match(match_result)
			if board.is_playable_cell(creation_cell) and SPECIAL_TILE_TYPE_SCRIPT.is_valid(special_type) and special_type != SPECIAL_TILE_TYPE_SCRIPT.NONE:
				board.set_special_tile(creation_cell, SPECIAL_TILE_DATA_SCRIPT.from_type(special_type))
				protected_special_cells[creation_cell] = true
				created_special_tiles.append({
					"cell": creation_cell,
					"special_type": special_type,
				})

		for cell in match_result.cells:
			_add_unique_cell(matched_cells, matched_seen, cell)
			if protected_special_cells.has(cell):
				continue
			_add_unique_cell(cleared_cells, clear_seen, cell)

	var chain: Dictionary = _special_tile_resolver.resolve_special_activation_chain(board, cleared_cells, protected_special_cells)
	cleared_cells = chain.get("cleared_cells", cleared_cells)

	return {
		"cleared_cells": cleared_cells,
		"matched_cells": matched_cells,
		"created_special_tiles": created_special_tiles,
		"activated_special_tiles": chain.get("activated_special_tiles", []),
		"special_cleared_cells": chain.get("special_cleared_cells", []),
	}


func _add_unique_cell(cells: Array[Vector2i], seen: Dictionary, cell: Vector2i) -> void:
	if seen.has(cell):
		return

	seen[cell] = true
	cells.append(cell)


func _to_vector2i_array(values: Array) -> Array[Vector2i]:
	var typed_values: Array[Vector2i] = []
	for value in values:
		typed_values.append(value as Vector2i)
	return typed_values


func _to_dictionary_array(values: Array) -> Array[Dictionary]:
	var typed_values: Array[Dictionary] = []
	for value in values:
		typed_values.append(value as Dictionary)
	return typed_values

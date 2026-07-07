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
			ice_events
		)

	if board.has_empty_cells():
		push_error("BoardResolver finished with empty cells.")

	if _match_finder.has_matches(board):
		push_error("BoardResolver reached cascade safety limit before board became stable.")

	return result


func _build_clear_step_data(board: BoardModel, matches: Array[MatchResult]) -> Dictionary:
	var clear_seen := {}
	var protected_special_cells := {}
	var cleared_cells: Array[Vector2i] = []
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
			if protected_special_cells.has(cell):
				continue
			_add_unique_cell(cleared_cells, clear_seen, cell)

	var activation_cells := _special_tile_resolver.collect_special_activation_cells(board, cleared_cells)
	var activated_special_tiles: Array[Dictionary] = []
	var special_cleared_seen := {}
	var special_cleared_cells: Array[Vector2i] = []

	for activation_cell in activation_cells:
		var special_data = board.get_special_tile(activation_cell)
		if special_data == null:
			continue

		activated_special_tiles.append({
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
			_add_unique_cell(cleared_cells, clear_seen, special_cell)
			_add_unique_cell(special_cleared_cells, special_cleared_seen, special_cell)

		var activation_data: Dictionary = activated_special_tiles[activated_special_tiles.size() - 1]
		activation_data["affected_cells"] = affected_cells.duplicate()
		activation_data["base_tile_type"] = base_tile_type

	return {
		"cleared_cells": cleared_cells,
		"created_special_tiles": created_special_tiles,
		"activated_special_tiles": activated_special_tiles,
		"special_cleared_cells": special_cleared_cells,
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

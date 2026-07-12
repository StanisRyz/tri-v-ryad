extends RefCounted
class_name BoosterResolver

const BOOSTER_CATALOG_SCRIPT := preload("res://scripts/game/config/booster_catalog.gd")
const BOOSTER_RESULT_SCRIPT := preload("res://scripts/game/battle/booster_resolve_result.gd")
const ICE_DAMAGE_RESOLVER_SCRIPT := preload("res://scripts/game/board/ice_damage_resolver.gd")
const SPECIAL_TILE_RESOLVER_SCRIPT := preload("res://scripts/game/board/special_tile_resolver.gd")

const FREEZE_TURNS := 3

var _gravity_resolver := GravityResolver.new()
var _direct_damage_resolver := DirectMatchDamageResolver.new()
var _ice_damage_resolver := ICE_DAMAGE_RESOLVER_SCRIPT.new()
var _special_tile_resolver := SPECIAL_TILE_RESOLVER_SCRIPT.new()


func can_use_booster(battle_state: BattleState, booster_id: String) -> bool:
	if battle_state == null:
		return false
	var booster_state = battle_state.get("booster_state")
	return booster_state != null and booster_state.can_use(booster_id)


func activate_booster(battle_state: BattleState, booster_id: String):
	var result = _new_result(booster_id)
	if booster_id != BOOSTER_CATALOG_SCRIPT.FREEZE_TIME:
		result.message = "Select a crystal first."
		return result
	if not can_use_booster(battle_state, booster_id):
		result.message = "Booster already used."
		return result

	var booster_state = battle_state.get("booster_state")
	booster_state.consume_use(booster_id)
	booster_state.add_freeze_turns(FREEZE_TURNS)
	result.is_valid = true
	result.freeze_turns_added = FREEZE_TURNS
	result.message = "Time Freeze active: next 3 moves are free."
	return result


func resolve_targeted_booster(battle_state: BattleState, booster_id: String, target_cell: Vector2i, round_modifier = null, level_boost = null):
	var result = _new_result(booster_id)
	if battle_state == null or battle_state.enemy == null:
		result.message = "Booster unavailable."
		return result
	if battle_state.is_finished():
		result.message = "Battle is already over."
		return result
	if not can_use_booster(battle_state, booster_id):
		result.message = "Booster already used."
		return result

	var board: BoardModel = battle_state.board
	if board == null or not board.is_inside(target_cell):
		result.message = "Select a crystal on the board."
		return result
	if not board.is_playable_cell(target_cell) or board.get_tile(target_cell) == BoardModel.EMPTY:
		result.message = "Select a crystal on the board."
		return result

	var cells: Array[Vector2i] = []
	match booster_id:
		BOOSTER_CATALOG_SCRIPT.HAMMER:
			cells = get_hammer_cells(board, target_cell)
		BOOSTER_CATALOG_SCRIPT.ROCKET_BARRAGE:
			cells = get_rocket_cells(board, target_cell)
		_:
			result.message = "Booster unavailable."
			return result

	if cells.is_empty():
		result.message = "No crystals cleared."
		return result

	# Stage 67.1 v0.1: a Hammer/Rocket clear that lands on a pre-existing
	# special crystal now activates it through the same queue-based chain
	# match resolution uses, instead of silently wiping the special tile with
	# no effect. Boosters never create specials themselves, so there are no
	# protected_cells to exclude.
	var chain: Dictionary = _special_tile_resolver.resolve_special_activation_chain(board, cells)
	var all_cleared_cells: Array[Vector2i] = chain.get("cleared_cells", cells)
	var activated_special_tiles: Array[Dictionary] = chain.get("activated_special_tiles", [])
	var special_cleared_cells: Array[Vector2i] = chain.get("special_cleared_cells", [])

	var tile_types := _read_tile_types(board, all_cleared_cells)
	var damage_info := _direct_damage_resolver.calculate_damage_for_typed_cells(all_cleared_cells, tile_types, round_modifier, level_boost)
	var damage: int = damage_info.get("total_damage", 0)
	board.clear_cells(all_cleared_cells)
	var ice_events := _ice_damage_resolver.apply_ice_damage(board, all_cleared_cells)
	var gravity_result: Dictionary = _gravity_resolver.apply_gravity_and_refill(board)
	var booster_state = battle_state.get("booster_state")
	booster_state.consume_use(booster_id)
	booster_state.clear_active_booster()
	battle_state.enemy.take_damage(damage)
	battle_state.update_status()

	result.is_valid = true
	result.target_cell = target_cell
	result.cleared_cells = all_cleared_cells.duplicate()
	result.ice_events = ice_events
	result.damage_to_enemy = damage
	result.affected_tile_types = _unique_tile_types(tile_types)
	result.cleared_cell_tile_types = tile_types.duplicate()
	result.activated_special_tiles = activated_special_tiles
	result.special_cleared_cells = special_cleared_cells
	result.message = _build_message(booster_id, all_cleared_cells.size(), damage, target_cell, tile_types)
	result.fall_movements = (gravity_result.get("fall_movements", []) as Array).duplicate(true)
	result.refill_cells = (gravity_result.get("refill_cells", []) as Array).duplicate(true)
	return result


## Stage 52 v0.1: inactive cells (future holes) are never affected by Hammer
## or Rocket, since both only collect cells that are is_playable_cell().
func get_hammer_cells(board: BoardModel, target_cell: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	if board == null:
		return cells

	for y in range(target_cell.y - 1, target_cell.y + 2):
		for x in range(target_cell.x - 1, target_cell.x + 2):
			var cell := Vector2i(x, y)
			if board.is_playable_cell(cell) and board.get_tile(cell) != BoardModel.EMPTY:
				cells.append(cell)
	return cells


func get_rocket_cells(board: BoardModel, target_cell: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	if board == null or not board.is_inside(target_cell):
		return cells

	var target_tile_type := board.get_tile(target_cell)
	if target_tile_type == BoardModel.EMPTY or not TileType.is_valid_tile_type(target_tile_type):
		return cells

	for cell in board.get_all_cells():
		if board.is_playable_cell(cell) and board.get_tile(cell) == target_tile_type:
			cells.append(cell)
	return cells


func _new_result(booster_id: String):
	var result := BOOSTER_RESULT_SCRIPT.new()
	result.booster_id = booster_id
	return result


func _read_tile_types(board: BoardModel, cells: Array[Vector2i]) -> Dictionary:
	var tile_types := {}
	for cell in cells:
		tile_types[cell] = board.get_tile(cell)
	return tile_types


func _unique_tile_types(tile_types: Dictionary) -> Array[int]:
	var seen := {}
	var values: Array[int] = []
	for tile_type in tile_types.values():
		if not TileType.is_valid_tile_type(tile_type):
			continue
		if seen.has(tile_type):
			continue
		seen[tile_type] = true
		values.append(tile_type)
	return values


func _build_message(booster_id: String, tile_count: int, damage: int, target_cell: Vector2i, tile_types: Dictionary) -> String:
	match booster_id:
		BOOSTER_CATALOG_SCRIPT.HAMMER:
			return "Hammer cleared %d tiles: %d damage." % [tile_count, damage]
		BOOSTER_CATALOG_SCRIPT.ROCKET_BARRAGE:
			var color_name := _tile_color_name(int(tile_types.get(target_cell, -1)))
			return "Rocket cleared %d %s tiles: %d damage." % [tile_count, color_name, damage]
		_:
			return "Booster used."


func _tile_color_name(tile_type: int) -> String:
	match tile_type:
		TileType.RED:
			return "red"
		TileType.BLUE:
			return "blue"
		TileType.GREEN:
			return "green"
		TileType.YELLOW:
			return "yellow"
		TileType.PURPLE:
			return "purple"
		_:
			return "colored"

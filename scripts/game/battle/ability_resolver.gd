extends RefCounted
class_name AbilityResolver

const ABILITY_DATA_SCRIPT := preload("res://scripts/game/battle/ability_data.gd")
const ABILITY_RESULT_SCRIPT := preload("res://scripts/game/battle/ability_result.gd")

const CENTER_ROW := 4
const RALLY_HEAL_AMOUNT := 30

var _gravity_resolver := GravityResolver.new()
var _board_resolver := BoardResolver.new()


func resolve_ability(state: BattleState, board: BoardModel, lane_index: int):
	if state == null or board == null:
		return ABILITY_RESULT_SCRIPT.rejected_result("", lane_index, "invalid_state")

	if state.is_finished():
		return ABILITY_RESULT_SCRIPT.rejected_result("", lane_index, "battle_finished")

	var hero := state.get_hero_by_lane(lane_index)
	if hero == null:
		return ABILITY_RESULT_SCRIPT.rejected_result("", lane_index, "hero_missing")

	if not hero.is_alive():
		return ABILITY_RESULT_SCRIPT.rejected_result(hero.id, lane_index, "hero_dead")

	if not hero.is_ability_ready():
		return ABILITY_RESULT_SCRIPT.rejected_result(hero.id, lane_index, "ability_not_ready")

	var ability = ABILITY_DATA_SCRIPT.get_for_hero(hero.id)
	var result = ABILITY_RESULT_SCRIPT.accepted_result(hero, ability, state.status)

	match ability.id:
		ABILITY_DATA_SCRIPT.POWER_STRIKE:
			_apply_power_strike(state, hero, result)
		ABILITY_DATA_SCRIPT.LINE_BREAK:
			_apply_line_break(board, result)
		ABILITY_DATA_SCRIPT.RALLY_HEAL:
			_apply_rally_heal(state, result)
		_:
			return ABILITY_RESULT_SCRIPT.rejected_result(hero.id, lane_index, "ability_unavailable")

	hero.ability_charge = 0
	state.update_status()
	result.battle_status = state.status
	return result


func _apply_power_strike(state: BattleState, hero: HeroData, result) -> void:
	var damage := hero.get_attack() * 5
	state.enemy.take_damage(damage)
	result.damage_to_enemy = damage
	result.board_changed = false


func _apply_line_break(board: BoardModel, result) -> void:
	var cleared_cells: Array[Vector2i] = []
	for x in range(board.width):
		cleared_cells.append(Vector2i(x, CENTER_ROW))

	board.clear_cells(cleared_cells)
	_gravity_resolver.apply_gravity_and_refill(board)
	_board_resolver.resolve_board(board)
	result.cleared_cells = cleared_cells
	result.board_changed = true


func _apply_rally_heal(state: BattleState, result) -> void:
	for hero in state.heroes:
		if not hero.is_alive():
			continue

		var amount := hero.heal(RALLY_HEAL_AMOUNT)
		result.healed_heroes.append({
			"hero_id": hero.id,
			"amount": amount,
			"current_hp": hero.current_hp,
		})

	result.board_changed = false

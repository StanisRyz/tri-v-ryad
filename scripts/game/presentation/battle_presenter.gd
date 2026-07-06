extends RefCounted
class_name BattlePresenter

const TURN_PRESENTATION_DATA_SCRIPT := preload("res://scripts/game/presentation/turn_presentation_data.gd")
const ABILITY_PRESENTER_DATA_SCRIPT := preload("res://scripts/game/presentation/ability_presentation_data.gd")
const ABILITY_RESULT_SCRIPT := preload("res://scripts/game/battle/ability_result.gd")
const ABILITY_RESOLVER_SCRIPT := preload("res://scripts/game/battle/ability_resolver.gd")
const LEVEL_CATALOG_SCRIPT := preload("res://scripts/game/config/level_catalog.gd")
const ENEMY_CATALOG_SCRIPT := preload("res://scripts/game/config/enemy_catalog.gd")
const ENEMY_SELECTION_RESOLVER_SCRIPT := preload("res://scripts/game/config/enemy_selection_resolver.gd")
const ENEMY_SCALING_RESOLVER_SCRIPT := preload("res://scripts/game/config/enemy_scaling_resolver.gd")
const BATTLE_FACTORY_SCRIPT := preload("res://scripts/game/battle/battle_factory.gd")
const BATTLE_BACKGROUND_CATALOG_SCRIPT := preload("res://scripts/game/config/battle_background_catalog.gd")
const BATTLE_BACKGROUND_SELECTION_RESOLVER_SCRIPT := preload("res://scripts/game/config/battle_background_selection_resolver.gd")
const ROUND_MODIFIER_CATALOG_SCRIPT := preload("res://scripts/game/config/round_modifier_catalog.gd")
const ROUND_MODIFIER_SELECTION_RESOLVER_SCRIPT := preload("res://scripts/game/config/round_modifier_selection_resolver.gd")
const BOOSTER_CATALOG_SCRIPT := preload("res://scripts/game/config/booster_catalog.gd")
const BOOSTER_RESOLVER_SCRIPT := preload("res://scripts/game/battle/booster_resolver.gd")
const LEVEL_LABEL_FORMATTER_SCRIPT := preload("res://scripts/game/config/level_label_formatter.gd")
const CHALLENGE_ARCHETYPE_RESOLVER_SCRIPT := preload("res://scripts/game/config/challenge_archetype_resolver.gd")
const DIFFICULTY_BUDGET_RESOLVER_SCRIPT := preload("res://scripts/game/config/difficulty_budget_resolver.gd")
const BOARD_CHALLENGE_GENERATOR_SCRIPT := preload("res://scripts/game/board/board_challenge_generator.gd")

signal board_changed(board: BoardModel)
signal battle_state_changed(state: BattleState)
signal level_changed(level_config)
signal turn_resolved(result: BattleTurnResult)
signal turn_presentation_ready(data)
signal ability_presentation_ready(data)
signal invalid_swap(reason: String)
signal battle_finished(status: int)
signal battle_background_changed(background_config)
signal round_modifier_changed(modifier)
signal booster_state_changed(booster_state)
signal booster_resolved(result)
signal swap_accepted(from_cell: Vector2i, to_cell: Vector2i, matches: Array)
signal targeted_booster_accepted(result)
signal generated_challenge_changed(challenge)

var board: BoardModel
var state: BattleState
var current_level_config
var current_level_id := ""
var progress
var hero_catalog: HeroCatalog
var current_background
var current_generated_challenge

var _board_generator := BoardGenerator.new()
var _swap_resolver := SwapResolver.new()
var _board_resolver := BoardResolver.new()
var _battle_resolver := BattleResolver.new()
var _ability_resolver = ABILITY_RESOLVER_SCRIPT.new()
var _level_catalog = LEVEL_CATALOG_SCRIPT.new()
var _enemy_catalog = ENEMY_CATALOG_SCRIPT.new()
var _enemy_selection_resolver = ENEMY_SELECTION_RESOLVER_SCRIPT.new()
var _enemy_scaling_resolver = ENEMY_SCALING_RESOLVER_SCRIPT.new()
var _enemy_rng := RandomNumberGenerator.new()
var _battle_factory = BATTLE_FACTORY_SCRIPT.new()
var _background_catalog = BATTLE_BACKGROUND_CATALOG_SCRIPT.new()
var _background_selection_resolver = BATTLE_BACKGROUND_SELECTION_RESOLVER_SCRIPT.new()
var _background_rng := RandomNumberGenerator.new()
var _round_modifier_catalog = ROUND_MODIFIER_CATALOG_SCRIPT.new()
var _round_modifier_selection_resolver = ROUND_MODIFIER_SELECTION_RESOLVER_SCRIPT.new()
var _round_modifier_rng := RandomNumberGenerator.new()
var _booster_catalog = BOOSTER_CATALOG_SCRIPT.new()
var _booster_resolver = BOOSTER_RESOLVER_SCRIPT.new()
var current_round_modifier
var _challenge_archetype_resolver = CHALLENGE_ARCHETYPE_RESOLVER_SCRIPT.new()
var _difficulty_budget_resolver = DIFFICULTY_BUDGET_RESOLVER_SCRIPT.new()
var _board_challenge_generator = BOARD_CHALLENGE_GENERATOR_SCRIPT.new()
var _challenge_rng := RandomNumberGenerator.new()


func _init() -> void:
	_enemy_rng.randomize()
	_background_rng.randomize()
	_round_modifier_rng.randomize()
	_challenge_rng.randomize()


func start_new_battle() -> void:
	var level_id := current_level_id if current_level_id != "" else _level_catalog.get_default_level_id()
	start_level(level_id)


func start_level(level_id: String) -> void:
	var resolved_level_id := level_id if _level_catalog.has_level(level_id) else _level_catalog.get_default_level_id()
	current_level_config = _level_catalog.get_level(resolved_level_id)
	current_level_id = current_level_config.level_id
	current_generated_challenge = _generate_board_challenge(current_level_id)
	board = _generate_playable_board(current_generated_challenge.board_mask)
	var selected_enemy = _enemy_selection_resolver.select_enemy_for_level(current_level_config, _enemy_catalog, _enemy_rng)
	var scaled_enemy = _enemy_scaling_resolver.scale_enemy_for_level(selected_enemy, current_level_config)
	current_background = _background_selection_resolver.select_background(_background_catalog, _background_rng)
	current_round_modifier = _round_modifier_selection_resolver.select_modifier(_round_modifier_catalog, _round_modifier_rng)
	state = _battle_factory.create_state(current_level_config, progress, hero_catalog, scaled_enemy)
	state.board = board
	state.get("booster_state").setup_from_catalog(_booster_catalog)
	level_changed.emit(current_level_config)
	board_changed.emit(board)
	battle_state_changed.emit(state)
	booster_state_changed.emit(state.get("booster_state"))
	battle_background_changed.emit(current_background)
	round_modifier_changed.emit(current_round_modifier)
	generated_challenge_changed.emit(current_generated_challenge)


func set_progress(player_progress) -> void:
	progress = player_progress


func set_hero_catalog(catalog: HeroCatalog) -> void:
	hero_catalog = catalog


func set_enemy_catalog(catalog) -> void:
	_enemy_catalog = catalog


func set_enemy_rng_seed(rng_seed: int) -> void:
	_enemy_rng.seed = rng_seed


func set_enemy_rng(rng: RandomNumberGenerator) -> void:
	if rng != null:
		_enemy_rng = rng


func set_battle_background_catalog(catalog) -> void:
	_background_catalog = catalog


func set_background_rng_seed(rng_seed: int) -> void:
	_background_rng.seed = rng_seed


func set_background_rng(rng: RandomNumberGenerator) -> void:
	if rng != null:
		_background_rng = rng


func get_current_background():
	return current_background


func set_round_modifier_catalog(catalog) -> void:
	_round_modifier_catalog = catalog


func set_round_modifier_rng_seed(rng_seed: int) -> void:
	_round_modifier_rng.seed = rng_seed


func set_round_modifier_rng(rng: RandomNumberGenerator) -> void:
	if rng != null:
		_round_modifier_rng = rng


func get_current_round_modifier():
	return current_round_modifier


func set_challenge_rng_seed(rng_seed: int) -> void:
	_challenge_rng.seed = rng_seed


func set_challenge_rng(rng: RandomNumberGenerator) -> void:
	if rng != null:
		_challenge_rng = rng


func get_current_generated_challenge():
	return current_generated_challenge


func get_booster_catalog():
	return _booster_catalog


func request_booster_activation(booster_id: String) -> void:
	if state == null or is_battle_finished():
		return

	var result = _booster_resolver.activate_booster(state, booster_id)
	booster_state_changed.emit(state.get("booster_state"))
	battle_state_changed.emit(state)
	booster_resolved.emit(result)


## defer_resolution lets an animated caller (GameScreen + AnimatedTurnFlow)
## receive targeted_booster_accepted and drive the stepwise clear/gravity/
## cascade animation before finalize_booster_turn() runs. Callers that never
## hook targeted_booster_accepted (headless tests, tools) keep the original
## fully synchronous contract by leaving this false.
func request_targeted_booster(booster_id: String, target_cell: Vector2i, defer_resolution: bool = false) -> void:
	if board == null or state == null or is_battle_finished():
		return

	var result = _booster_resolver.resolve_targeted_booster(state, booster_id, target_cell, current_round_modifier)
	if not result.is_valid:
		booster_resolved.emit(result)
		return

	if defer_resolution:
		targeted_booster_accepted.emit(result)
		return

	finalize_booster_turn(result)


func finalize_booster_turn(result) -> void:
	board_changed.emit(board)
	booster_state_changed.emit(state.get("booster_state"))
	battle_state_changed.emit(state)
	booster_resolved.emit(result)
	if state.is_finished():
		battle_finished.emit(state.status)


## defer_resolution lets an animated caller (GameScreen + AnimatedTurnFlow)
## receive swap_accepted and drive the stepwise clear/gravity/cascade
## animation before finalize_swap_turn() runs. Callers that never hook
## swap_accepted (headless tests, tools) keep the original fully synchronous
## contract by leaving this false.
func request_swap(from_cell: Vector2i, to_cell: Vector2i, defer_resolution: bool = false) -> void:
	if board == null or state == null or is_battle_finished():
		return

	var swap_result := _swap_resolver.try_swap(board, from_cell, to_cell)
	if not swap_result.accepted:
		turn_presentation_ready.emit(TURN_PRESENTATION_DATA_SCRIPT.from_invalid_turn(from_cell, to_cell, swap_result.reason))
		invalid_swap.emit(swap_result.reason)
		board_changed.emit(board)
		return

	if defer_resolution:
		swap_accepted.emit(from_cell, to_cell, swap_result.matches)
		return

	resolve_accepted_swap_immediately(from_cell, to_cell, swap_result.matches)


func resolve_accepted_swap_immediately(from_cell: Vector2i, to_cell: Vector2i, matches: Array) -> void:
	var board_result := _board_resolver.resolve_board(board)
	_finalize_swap(from_cell, to_cell, matches, board_result)


func finalize_swap_turn(from_cell: Vector2i, to_cell: Vector2i, matches: Array, board_result: BoardResolveResult) -> void:
	_finalize_swap(from_cell, to_cell, matches, board_result)


func _finalize_swap(from_cell: Vector2i, to_cell: Vector2i, matches: Array, board_result: BoardResolveResult) -> void:
	if _battle_resolver.has_method("set_round_modifier"):
		_battle_resolver.set_round_modifier(current_round_modifier)
	var battle_result := _battle_resolver.resolve_player_matches(state, matches, board_result)
	var presentation_data = TURN_PRESENTATION_DATA_SCRIPT.from_valid_turn(from_cell, to_cell, matches, battle_result, board_result)

	board_changed.emit(board)
	battle_state_changed.emit(state)
	booster_state_changed.emit(state.get("booster_state"))
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


## Stage 51 v0.1: builds the procedural challenge foundation for a battle
## start. board_mask/frozen_cells are placeholders for now (full 9x9 active
## board); the resolved archetype/difficulty/seed already flow through so
## later stages can generate real holes/ice without touching this wiring.
func _generate_board_challenge(level_id: String) -> GeneratedBoardChallenge:
	var level_number := LEVEL_LABEL_FORMATTER_SCRIPT.extract_level_number(level_id)
	var safe_level_number: int = max(1, level_number)
	var archetype := _challenge_archetype_resolver.resolve_for_level(safe_level_number)
	var difficulty_budget := _difficulty_budget_resolver.calculate_for_level(safe_level_number)
	var generation_seed := _challenge_rng.randi()
	return _board_challenge_generator.generate(level_id, safe_level_number, archetype, difficulty_budget, generation_seed)


## Stage 52 v0.1: mask defaults to the Stage 51 full-9x9 placeholder shape
## (Array of height rows of width bool-ish values) via BoardGenerator/BoardModel
## falling back to fully active on an empty/invalid mask.
func _generate_playable_board(mask: Array = []) -> BoardModel:
	for attempt in range(100):
		var candidate := _board_generator.generate(BoardModel.DEFAULT_WIDTH, BoardModel.DEFAULT_HEIGHT, mask)
		if _has_valid_move(candidate):
			return candidate

	return _board_generator.generate(BoardModel.DEFAULT_WIDTH, BoardModel.DEFAULT_HEIGHT, mask)


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

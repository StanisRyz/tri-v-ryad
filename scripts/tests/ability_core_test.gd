extends SceneTree

const ABILITY_RESOLVER_SCRIPT := "res://scripts/game/battle/ability_resolver.gd"

var _failures := 0


func _initialize() -> void:
	print("Running ability core tests...")

	_test_rejected_when_not_ready()
	_test_rejected_when_hero_dead()
	_test_rejected_when_battle_finished()
	_test_power_strike_damage()
	_test_power_strike_resets_charge()
	_test_line_break_refills_board()
	_test_line_break_result_data()
	_test_line_break_does_not_reduce_moves()
	_test_rally_heal_heals_alive_heroes()
	_test_rally_heal_does_not_overheal()
	_test_rally_heal_resets_charge()
	_test_ability_does_not_tick_enemy_intent()
	_test_power_strike_can_win()

	if _failures == 0:
		print("Ability core tests passed.")
		quit(0)
	else:
		push_error("Ability core tests failed: %d" % _failures)
		quit(1)


func _test_rejected_when_not_ready() -> void:
	var state := _create_state()
	var board := _create_board()
	var result = _create_resolver().resolve_ability(state, board, 0)
	_expect_false(result.accepted, "not-ready ability rejected")
	_expect_equal(result.reason, "ability_not_ready", "not-ready rejection reason")
	print("ok - ability rejected when not ready")


func _test_rejected_when_hero_dead() -> void:
	var state := _create_state()
	var board := _create_board()
	var hero := state.get_hero_by_lane(0)
	hero.ability_charge = hero.ability_charge_required
	hero.take_damage(999)
	var result = _create_resolver().resolve_ability(state, board, 0)
	_expect_false(result.accepted, "dead hero ability rejected")
	_expect_equal(result.reason, "hero_dead", "dead hero rejection reason")
	print("ok - ability rejected when hero is dead")


func _test_rejected_when_battle_finished() -> void:
	var state := _create_state()
	var board := _create_board()
	state.enemy.take_damage(999)
	state.update_status()
	var result = _create_resolver().resolve_ability(state, board, 0)
	_expect_false(result.accepted, "finished battle ability rejected")
	_expect_equal(result.reason, "battle_finished", "finished battle rejection reason")
	print("ok - ability rejected when battle is finished")


func _test_power_strike_damage() -> void:
	var state := _create_state()
	var board := _create_board()
	_ready_hero(state, 0)
	var result = _create_resolver().resolve_ability(state, board, 0)
	_expect_true(result.accepted, "power strike accepted")
	_expect_equal(result.damage_to_enemy, state.get_hero_by_lane(0).get_attack() * 5, "power strike damage")
	_expect_equal(state.enemy.current_hp, 250, "enemy hp after power strike")
	print("ok - Power Strike deals attack x5 damage")


func _test_power_strike_resets_charge() -> void:
	var state := _create_state()
	var board := _create_board()
	var hero := _ready_hero(state, 0)
	_create_resolver().resolve_ability(state, board, 0)
	_expect_equal(hero.ability_charge, 0, "power strike resets charge")
	print("ok - Power Strike resets charge")


func _test_line_break_refills_board() -> void:
	var state := _create_state()
	var board := _create_board()
	_ready_hero(state, 1)
	_create_resolver().resolve_ability(state, board, 1)
	_expect_false(board.has_empty_cells(), "line break leaves board full")
	print("ok - Line Break leaves board full after stabilization")


func _test_line_break_result_data() -> void:
	var state := _create_state()
	var board := _create_board()
	_ready_hero(state, 1)
	var result = _create_resolver().resolve_ability(state, board, 1)
	_expect_true(result.board_changed, "line break board changed")
	_expect_equal(result.cleared_cells.size(), BoardModel.DEFAULT_WIDTH, "line break cleared cell count")
	print("ok - Line Break sets board_changed and stores cleared cells")


func _test_line_break_does_not_reduce_moves() -> void:
	var state := _create_state()
	var board := _create_board()
	_ready_hero(state, 1)
	var starting_moves := state.moves_left
	_create_resolver().resolve_ability(state, board, 1)
	_expect_equal(state.moves_left, starting_moves, "line break does not reduce moves")
	print("ok - Line Break does not reduce moves")


func _test_rally_heal_heals_alive_heroes() -> void:
	var state := _create_state()
	var board := _create_board()
	_ready_hero(state, 2)
	state.get_hero_by_lane(0).take_damage(40)
	state.get_hero_by_lane(1).take_damage(20)
	var result = _create_resolver().resolve_ability(state, board, 2)
	_expect_true(result.accepted, "rally heal accepted")
	_expect_equal(state.get_hero_by_lane(0).current_hp, 90, "hero 1 healed")
	_expect_equal(state.get_hero_by_lane(1).current_hp, 120, "hero 2 clamped to max")
	print("ok - Rally Heal heals alive heroes")


func _test_rally_heal_does_not_overheal() -> void:
	var state := _create_state()
	var board := _create_board()
	_ready_hero(state, 2)
	_create_resolver().resolve_ability(state, board, 2)
	_expect_equal(state.get_hero_by_lane(0).current_hp, state.get_hero_by_lane(0).get_max_hp(), "rally heal no overheal")
	print("ok - Rally Heal does not heal above max HP")


func _test_rally_heal_resets_charge() -> void:
	var state := _create_state()
	var board := _create_board()
	var hero := _ready_hero(state, 2)
	_create_resolver().resolve_ability(state, board, 2)
	_expect_equal(hero.ability_charge, 0, "rally heal resets charge")
	print("ok - Rally Heal resets charge")


func _test_ability_does_not_tick_enemy_intent() -> void:
	var state := _create_state()
	var board := _create_board()
	_ready_hero(state, 0)
	var intent_before := state.enemy_intent.turns_until_action
	_create_resolver().resolve_ability(state, board, 0)
	_expect_equal(state.enemy_intent.turns_until_action, intent_before, "ability does not tick enemy intent")
	print("ok - ability use does not tick enemy intent")


func _test_power_strike_can_win() -> void:
	var state := _create_state()
	var board := _create_board()
	_ready_hero(state, 0)
	state.enemy.current_hp = 20
	var result = _create_resolver().resolve_ability(state, board, 0)
	_expect_true(result.accepted, "winning power strike accepted")
	_expect_equal(state.status, BattleState.Status.VICTORY, "power strike victory status")
	_expect_equal(result.battle_status, BattleState.Status.VICTORY, "power strike result victory status")
	print("ok - victory can occur from Power Strike")


func _create_state() -> BattleState:
	var heroes: Array[HeroData] = [
		HeroData.new("hero_1", "Hero 1", 0, 10, 100, 0, 0, 10),
		HeroData.new("hero_2", "Hero 2", 1, 8, 120, 0, 0, 10),
		HeroData.new("hero_3", "Hero 3", 2, 12, 80, 0, 0, 10),
	]
	return BattleState.new(heroes, EnemyData.new("enemy_training", "Training Enemy", 300, 20), EnemyIntent.new(3, 1), 20)


func _create_resolver():
	return load(ABILITY_RESOLVER_SCRIPT).new()


func _create_board() -> BoardModel:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5101
	return BoardGenerator.new(rng).generate()


func _ready_hero(state: BattleState, lane_index: int) -> HeroData:
	var hero := state.get_hero_by_lane(lane_index)
	hero.ability_charge = hero.ability_charge_required
	return hero


func _expect_true(value: bool, message: String) -> void:
	if value:
		return

	_failures += 1
	push_error("FAILED: %s" % message)


func _expect_false(value: bool, message: String) -> void:
	_expect_true(not value, message)


func _expect_equal(actual, expected, message: String) -> void:
	if actual == expected:
		return

	_failures += 1
	push_error("FAILED: %s | expected=%s actual=%s" % [message, expected, actual])

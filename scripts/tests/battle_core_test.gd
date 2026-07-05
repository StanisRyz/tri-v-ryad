extends SceneTree

var _failures := 0


func _initialize() -> void:
	print("Running battle core tests...")

	# These tests exercise the frozen hero battle path directly (Stage 32 defaults
	# FeatureFlags.HERO_SYSTEMS_ENABLED to false for the active direct-damage flow).
	var previous_hero_systems_enabled := FeatureFlags.HERO_SYSTEMS_ENABLED
	FeatureFlags.HERO_SYSTEMS_ENABLED = true

	_test_lane_zero_activation()
	_test_cross_lane_activation()
	_test_lane_one_activation()
	_test_vertical_lane_two_activation()
	_test_overlapping_cells_not_double_counted()
	_test_damage_formula()
	_test_dead_heroes_deal_zero_damage()
	_test_ability_charge()
	_test_ability_ready()
	_test_enemy_hp_decreases()
	_test_enemy_attacks_when_intent_triggers()
	_test_victory_when_enemy_hp_zero()
	_test_defeat_when_moves_left_zero()
	_test_defeat_when_all_heroes_dead()
	_test_battle_resolver_returns_turn_result()
	_test_direct_damage_path_used_when_hero_systems_disabled()

	FeatureFlags.HERO_SYSTEMS_ENABLED = previous_hero_systems_enabled

	if _failures == 0:
		print("Battle core tests passed.")
		quit(0)
	else:
		push_error("Battle core tests failed: %d" % _failures)
		quit(1)


func _test_lane_zero_activation() -> void:
	var matches: Array[MatchResult] = [_match([Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)])]
	var activations := HeroLaneResolver.new().resolve_matches(matches)
	_expect_equal(activations[0], 3, "lane 0 activation count")
	_expect_equal(activations[1], 0, "lane 1 not activated")
	_expect_equal(activations[2], 0, "lane 2 not activated")
	print("ok - columns 0,1,2 activate lane 0")


func _test_cross_lane_activation() -> void:
	var matches: Array[MatchResult] = [_match([Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)])]
	var activations := HeroLaneResolver.new().resolve_matches(matches)
	_expect_equal(activations[0], 2, "cross-lane lane 0 count")
	_expect_equal(activations[1], 1, "cross-lane lane 1 count")
	print("ok - columns 1,2,3 split across lanes 0 and 1")


func _test_lane_one_activation() -> void:
	var matches: Array[MatchResult] = [_match([Vector2i(3, 0), Vector2i(4, 0), Vector2i(5, 0)])]
	var activations := HeroLaneResolver.new().resolve_matches(matches)
	_expect_equal(activations[0], 0, "lane 0 not activated")
	_expect_equal(activations[1], 3, "lane 1 activation count")
	_expect_equal(activations[2], 0, "lane 2 not activated")
	print("ok - columns 3,4,5 activate lane 1")


func _test_vertical_lane_two_activation() -> void:
	var matches: Array[MatchResult] = [_match(
		[Vector2i(7, 0), Vector2i(7, 1), Vector2i(7, 2)],
		MatchResult.Direction.VERTICAL
	)]
	var activations := HeroLaneResolver.new().resolve_matches(matches)
	_expect_equal(activations[2], 3, "vertical column 7 activates lane 2")
	print("ok - vertical match in column 7 activates lane 2")


func _test_overlapping_cells_not_double_counted() -> void:
	var matches: Array[MatchResult] = [
		_match([Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)]),
		_match([Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2)], MatchResult.Direction.VERTICAL),
	]
	var activations := HeroLaneResolver.new().resolve_matches(matches)
	_expect_equal(activations[0], 5, "overlapping cell counted once")
	print("ok - overlapping cells are not double-counted")


func _test_damage_formula() -> void:
	var state := BattleTestFactory.create_default_state()
	var result := DamageResolver.new().apply_hero_damage(state, {0: 3, 1: 2, 2: 0})
	_expect_equal(result["total_damage"], 46, "damage formula")
	_expect_equal(state.enemy.current_hp, 254, "enemy hp after damage formula")
	print("ok - damage formula uses attack times lane tile count")


func _test_dead_heroes_deal_zero_damage() -> void:
	var state := BattleTestFactory.create_default_state()
	state.get_hero_by_lane(0).take_damage(999)
	var result := DamageResolver.new().apply_hero_damage(state, {0: 3})
	_expect_equal(result["total_damage"], 0, "dead hero damage is zero")
	_expect_equal(state.enemy.current_hp, 300, "enemy hp unchanged from dead hero")
	print("ok - dead heroes deal zero damage")


func _test_ability_charge() -> void:
	var state := BattleTestFactory.create_default_state()
	var events := AbilityChargeResolver.new().apply_ability_charge(state, {0: 3})
	var hero := state.get_hero_by_lane(0)
	_expect_equal(hero.ability_charge, 3, "hero ability charge increased")
	_expect_equal(events[0]["charge_added"], 3, "charge event amount")
	print("ok - ability charge increases by matched tile count")


func _test_ability_ready() -> void:
	var state := BattleTestFactory.create_default_state()
	var hero := state.get_hero_by_lane(1)
	hero.ability_charge_required = 3
	var events := AbilityChargeResolver.new().apply_ability_charge(state, {1: 3})
	_expect_true(hero.is_ability_ready(), "hero ability ready")
	_expect_true(events[0]["ability_ready"], "charge event ability ready")
	print("ok - ability_ready becomes true")


func _test_enemy_hp_decreases() -> void:
	var state := BattleTestFactory.create_default_state()
	DamageResolver.new().apply_hero_damage(state, {2: 4})
	_expect_equal(state.enemy.current_hp, 252, "enemy hp decreases after hero damage")
	print("ok - enemy hp decreases after damage")


func _test_enemy_attacks_when_intent_triggers() -> void:
	var state := BattleTestFactory.create_default_state()
	state.enemy_intent.turns_until_action = 1
	state.enemy_intent.target_lane = 1
	var hero := state.get_hero_by_lane(1)
	var action := EnemyActionResolver.new().resolve_enemy_action(state)
	_expect_true(action["acted"], "enemy action triggered")
	_expect_equal(action["target_lane"], 1, "enemy target lane")
	_expect_equal(hero.current_hp, 100, "enemy dealt damage to target hero")
	_expect_equal(state.enemy_intent.turns_until_action, state.enemy_intent.reset_turns, "enemy intent reset")
	print("ok - enemy attacks when intent triggers")


func _test_victory_when_enemy_hp_zero() -> void:
	var state := BattleTestFactory.create_default_state()
	state.enemy.take_damage(999)
	state.update_status()
	_expect_equal(state.status, BattleState.Status.VICTORY, "victory status")
	print("ok - victory occurs when enemy hp reaches zero")


func _test_defeat_when_moves_left_zero() -> void:
	var state := BattleTestFactory.create_default_state()
	state.moves_left = 0
	state.update_status()
	_expect_equal(state.status, BattleState.Status.DEFEAT, "defeat from moves left")
	print("ok - defeat occurs when moves reach zero")


func _test_defeat_when_all_heroes_dead() -> void:
	var state := BattleTestFactory.create_default_state()
	for hero in state.heroes:
		hero.take_damage(999)
	state.update_status()
	_expect_equal(state.status, BattleState.Status.DEFEAT, "defeat from all heroes dead")
	print("ok - defeat occurs when all heroes are dead")


func _test_battle_resolver_returns_turn_result() -> void:
	var state := BattleTestFactory.create_default_state()
	state.enemy_intent.turns_until_action = 1
	var matches: Array[MatchResult] = [_match([Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)])]

	var result := BattleResolver.new().resolve_player_matches(state, matches)
	var result_dictionary := result.to_dictionary()

	_expect_equal(result.lane_activations[0], 3, "turn result lane activation")
	_expect_equal(result.total_damage_to_enemy, 30, "turn result damage")
	_expect_equal(result.ability_charge_events[0]["current_charge"], 3, "turn result charge event")
	_expect_true(result.enemy_action["acted"], "turn result enemy action")
	_expect_equal(state.moves_left, 19, "turn consumes one move")
	_expect_equal(state.turn_number, 1, "turn number increments")
	_expect_true(result_dictionary.has("battle_status"), "turn result dictionary has status")
	print("ok - BattleResolver returns useful BattleTurnResult")


func _test_direct_damage_path_used_when_hero_systems_disabled() -> void:
	var previous_hero_systems_enabled := FeatureFlags.HERO_SYSTEMS_ENABLED
	FeatureFlags.HERO_SYSTEMS_ENABLED = false

	var state := BattleTestFactory.create_default_state()
	var matches: Array[MatchResult] = [_match([Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)])]
	var starting_enemy_hp: int = state.enemy.current_hp

	var result := BattleResolver.new().resolve_player_matches(state, matches)

	_expect_equal(result.total_damage_to_enemy, 3, "direct damage path deals 1 damage per cleared cell")
	_expect_equal(state.enemy.current_hp, starting_enemy_hp - 3, "direct damage path reduces enemy hp by cleared cell count")
	_expect_true(not result.enemy_action.get("acted", false), "direct damage path does not run enemy attacks")

	FeatureFlags.HERO_SYSTEMS_ENABLED = previous_hero_systems_enabled
	print("ok - direct damage path is used when hero systems are disabled")


func _match(raw_cells: Array, direction: MatchResult.Direction = MatchResult.Direction.HORIZONTAL) -> MatchResult:
	var cells: Array[Vector2i] = []
	for cell in raw_cells:
		cells.append(cell)
	return MatchResult.new(cells, TileType.RED, direction)


func _expect_true(value: bool, message: String) -> void:
	if value:
		return

	_failures += 1
	push_error("FAILED: %s" % message)


func _expect_equal(actual, expected, message: String) -> void:
	if actual == expected:
		return

	_failures += 1
	push_error("FAILED: %s | expected=%s actual=%s" % [message, expected, actual])

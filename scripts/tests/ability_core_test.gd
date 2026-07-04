extends SceneTree

const ABILITY_DATA_SCRIPT := "res://scripts/game/battle/ability_data.gd"
const ABILITY_RESOLVER_SCRIPT := "res://scripts/game/battle/ability_resolver.gd"
const HERO_CATALOG_SCRIPT := "res://scripts/game/config/hero_catalog.gd"

var _failures := 0


func _initialize() -> void:
	print("Running ability core tests...")

	_test_rejected_when_not_ready()
	_test_rejected_when_hero_dead()
	_test_rejected_when_battle_finished()
	_test_all_roster_abilities_resolve_to_damage()
	_test_all_roster_abilities_deal_damage_only()
	_test_ability_can_win()
	_test_unknown_ability_rejects_without_spending_charge()

	if _failures == 0:
		print("Ability core tests passed.")
		quit(0)
	else:
		push_error("Ability core tests failed: %d" % _failures)
		quit(1)


func _test_rejected_when_not_ready() -> void:
	var state := _create_state("hero_1", "Hero 1", 10, 100, "warrior_strike")
	var board := _create_board()
	var result = _create_resolver().resolve_ability(state, board, 0)
	_expect_false(result.accepted, "not-ready ability rejected")
	_expect_equal(result.reason, "ability_not_ready", "not-ready rejection reason")
	print("ok - ability rejected when not ready")


func _test_rejected_when_hero_dead() -> void:
	var state := _create_state("hero_1", "Hero 1", 10, 100, "warrior_strike")
	var board := _create_board()
	var hero := _ready_hero(state)
	hero.take_damage(999)
	var result = _create_resolver().resolve_ability(state, board, 0)
	_expect_false(result.accepted, "dead hero ability rejected")
	_expect_equal(result.reason, "hero_dead", "dead hero rejection reason")
	print("ok - ability rejected when hero is dead")


func _test_rejected_when_battle_finished() -> void:
	var state := _create_state("hero_1", "Hero 1", 10, 100, "warrior_strike")
	var board := _create_board()
	state.enemy.take_damage(1000)
	state.update_status()
	var result = _create_resolver().resolve_ability(state, board, 0)
	_expect_false(result.accepted, "finished battle ability rejected")
	_expect_equal(result.reason, "battle_finished", "finished battle rejection reason")
	print("ok - ability rejected when battle is finished")


func _test_all_roster_abilities_resolve_to_damage() -> void:
	var catalog = load(HERO_CATALOG_SCRIPT).new()
	for hero_config in catalog.get_all_heroes():
		var ability = load(ABILITY_DATA_SCRIPT).get_for_ability(hero_config.ability_id, hero_config.hero_id)
		_expect_true(ability.id != "", "%s ability resolves" % hero_config.hero_id)
		_expect_equal(ability.hero_id, hero_config.hero_id, "%s ability owner is set" % hero_config.hero_id)
		_expect_true(ability.display_name != "", "%s ability has display name" % hero_config.hero_id)
		_expect_true(ability.description != "", "%s ability has description" % hero_config.hero_id)
		_expect_true(ability.damage_multiplier > 0, "%s ability has positive damage multiplier" % hero_config.hero_id)
	print("ok - all roster abilities resolve to damage data")


func _test_all_roster_abilities_deal_damage_only() -> void:
	var catalog = load(HERO_CATALOG_SCRIPT).new()
	for hero_config in catalog.get_all_heroes():
		var state := _create_state(hero_config.hero_id, hero_config.display_name, hero_config.base_attack, hero_config.base_max_hp, hero_config.ability_id)
		var board := _create_board()
		var hero := _ready_hero(state)
		var ability = load(ABILITY_DATA_SCRIPT).get_for_ability(hero.ability_id, hero.id)
		var board_before := board.to_debug_string()
		var hero_hp_before := hero.current_hp
		var moves_before := state.moves_left
		var intent_before := state.enemy_intent.turns_until_action
		var enemy_hp_before := state.enemy.current_hp

		var result = _create_resolver().resolve_ability(state, board, 0)

		_expect_true(result.accepted, "%s ability accepted" % hero_config.hero_id)
		_expect_equal(result.damage_to_enemy, hero.get_attack() * ability.damage_multiplier, "%s damage uses multiplier" % hero_config.hero_id)
		_expect_equal(state.enemy.current_hp, enemy_hp_before - result.damage_to_enemy, "%s damages enemy" % hero_config.hero_id)
		_expect_equal(hero.ability_charge, 0, "%s ability resets charge" % hero_config.hero_id)
		_expect_equal(state.moves_left, moves_before, "%s ability does not spend moves" % hero_config.hero_id)
		_expect_equal(state.enemy_intent.turns_until_action, intent_before, "%s ability does not tick enemy intent" % hero_config.hero_id)
		_expect_equal(hero.current_hp, hero_hp_before, "%s ability does not heal hero" % hero_config.hero_id)
		_expect_equal(board.to_debug_string(), board_before, "%s ability does not change board" % hero_config.hero_id)
		_expect_false(result.board_changed, "%s result does not mark board changed" % hero_config.hero_id)
		_expect_equal(result.healed_heroes.size(), 0, "%s result has no healed heroes" % hero_config.hero_id)
		_expect_equal(result.cleared_cells.size(), 0, "%s result has no cleared cells" % hero_config.hero_id)
	print("ok - all roster abilities deal enemy damage only")


func _test_ability_can_win() -> void:
	var state := _create_state("hero_1", "Hero 1", 10, 100, "warrior_strike")
	var board := _create_board()
	_ready_hero(state)
	state.enemy.current_hp = 20
	var result = _create_resolver().resolve_ability(state, board, 0)
	_expect_true(result.accepted, "winning ability accepted")
	_expect_equal(state.status, BattleState.Status.VICTORY, "damage ability victory status")
	_expect_equal(result.battle_status, BattleState.Status.VICTORY, "damage ability result victory status")
	print("ok - victory can occur from damage ability")


func _test_unknown_ability_rejects_without_spending_charge() -> void:
	var state := _create_state("hero_1", "Hero 1", 10, 100, "missing_ability")
	var board := _create_board()
	var hero := _ready_hero(state)
	var starting_charge := hero.ability_charge
	var result = _create_resolver().resolve_ability(state, board, 0)
	_expect_false(result.accepted, "unknown ability rejected")
	_expect_equal(result.reason, "unknown_ability", "unknown ability reason")
	_expect_equal(hero.ability_charge, starting_charge, "unknown ability keeps charge")
	print("ok - unknown ability rejects without spending charge")


func _create_state(hero_id: String, display_name: String, attack: int, max_hp: int, ability_id: String) -> BattleState:
	var heroes: Array[HeroData] = [
		HeroData.new(hero_id, display_name, 0, attack, max_hp, 0, 0, 10, ability_id),
	]
	return BattleState.new(heroes, EnemyData.new("enemy_training", "Training Enemy", 1000, 20), EnemyIntent.new(3, 1), 20)


func _create_resolver():
	return load(ABILITY_RESOLVER_SCRIPT).new()


func _create_board() -> BoardModel:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5101
	return BoardGenerator.new(rng).generate()


func _ready_hero(state: BattleState) -> HeroData:
	var hero := state.get_hero_by_lane(0)
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

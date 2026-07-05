extends SceneTree

const BATTLE_MESSAGE_FORMATTER_SCRIPT := "res://scripts/game/presentation/battle_message_formatter.gd"
const TURN_PRESENTATION_DATA_SCRIPT := "res://scripts/game/presentation/turn_presentation_data.gd"
const ABILITY_PRESENTATION_DATA_SCRIPT := "res://scripts/game/presentation/ability_presentation_data.gd"
const ABILITY_RESULT_SCRIPT := "res://scripts/game/battle/ability_result.gd"
const ABILITY_DATA_SCRIPT := "res://scripts/game/battle/ability_data.gd"

var _failures := 0
var _formatter


func _initialize() -> void:
	print("Running battle message formatter tests...")
	_formatter = load(BATTLE_MESSAGE_FORMATTER_SCRIPT)

	_test_single_hero_damage_message()
	_test_multi_hero_damage_message()
	_test_no_damage_message()
	_test_enemy_action_message()
	_test_enemy_idle_message()
	_test_invalid_swap_messages()
	_test_invalid_input_messages()
	_test_lane_activation_messages()
	_test_special_activation_messages()
	_test_ability_start_message()
	_test_ability_damage_message()
	_test_ability_rejected_messages()
	_test_victory_message()
	_test_defeat_message()
	_test_debug_labels_include_ids()
	_test_unknown_data_uses_safe_fallback()
	_test_direct_damage_messages()
	_test_enemy_defeated_message()

	if _failures == 0:
		print("Battle message formatter tests passed.")
		quit(0)
	else:
		push_error("Battle message formatter tests failed: %d" % _failures)
		quit(1)


func _test_single_hero_damage_message() -> void:
	var data = _turn_data({0: 3}, [{"lane_index": 0, "hero_id": "hero_1", "damage": 30}], 30)
	_expect_equal(_formatter.format_damage_message(data), "Hero 1 dealt 30 damage", "single hero damage message")
	print("ok - single hero damage message")


func _test_multi_hero_damage_message() -> void:
	var data = _turn_data({0: 3, 1: 2}, [
		{"lane_index": 0, "hero_id": "hero_1", "damage": 30},
		{"lane_index": 1, "hero_id": "hero_2", "damage": 16},
	], 46)
	_expect_equal(_formatter.format_damage_message(data), "2 heroes attacked for 46 total damage", "multi hero damage message")
	print("ok - multi hero damage message")


func _test_no_damage_message() -> void:
	var data = _turn_data({0: 0}, [{"lane_index": 0, "hero_id": "hero_1", "damage": 0}], 0)
	_expect_equal(_formatter.format_damage_message(data), "No damage dealt", "no damage message")
	print("ok - no damage message")


func _test_enemy_action_message() -> void:
	var enemy_action := {"acted": true, "target_hero_id": "hero_2", "damage": 18}
	_expect_equal(_formatter.format_enemy_action_message(enemy_action), "Enemy attacked Hero 2 for 18 damage", "enemy action message")
	print("ok - enemy action message")


func _test_enemy_idle_message() -> void:
	var enemy_action := {"acted": false}
	_expect_equal(_formatter.format_enemy_action_message(enemy_action), "Enemy is preparing an attack", "enemy idle message")
	print("ok - enemy idle message")


func _test_invalid_swap_messages() -> void:
	_expect_equal(_formatter.format_invalid_swap_message("no_match"), "Swap must create a match", "no_match message")
	_expect_equal(_formatter.format_invalid_swap_message("not_adjacent"), "Choose a neighboring tile", "not_adjacent message")
	_expect_equal(_formatter.format_invalid_swap_message("invalid_swap"), "Choose a neighboring tile", "invalid_swap message")
	print("ok - invalid swap messages")


func _test_invalid_input_messages() -> void:
	_expect_equal(_formatter.format_invalid_input_message("swipe_too_short"), "Swipe a little farther", "swipe_too_short message")
	_expect_equal(_formatter.format_invalid_input_message("outside_board"), "Stay inside the board", "outside_board message")
	_expect_equal(_formatter.format_invalid_input_message("input_locked"), "Wait until the turn finishes", "input_locked message")
	print("ok - invalid input messages")


func _test_lane_activation_messages() -> void:
	_expect_equal(_formatter.format_lane_activation_message({0: 3, 1: 0, 2: 0}), "Left lane activated", "single lane activation message")
	_expect_equal(_formatter.format_lane_activation_message({0: 3, 1: 2, 2: 0}), "2 lanes activated", "multi lane activation message")
	_expect_equal(_formatter.format_lane_activation_message({0: 0, 1: 0, 2: 0}), "", "no lane activation message")
	_expect_equal(_formatter.format_lane_name(0), "Left", "lane 0 name")
	_expect_equal(_formatter.format_lane_name(1), "Center", "lane 1 name")
	_expect_equal(_formatter.format_lane_name(2), "Right", "lane 2 name")
	print("ok - lane activation and name messages")


func _test_special_activation_messages() -> void:
	var data = load(TURN_PRESENTATION_DATA_SCRIPT).new()
	var activated: Array[Dictionary] = [{"cell": Vector2i(1, 0), "special_type": SpecialTileType.NONE}]
	data.activated_special_tiles = activated
	var cleared: Array[Vector2i] = []
	data.special_cleared_cells = cleared
	_expect_equal(_formatter.format_special_activation_message(data), "Special tile activated", "unknown special type uses safe fallback")

	var empty_data = load(TURN_PRESENTATION_DATA_SCRIPT).new()
	_expect_equal(_formatter.format_special_activation_message(empty_data), "", "no special activation returns empty message")
	print("ok - special activation messages")


func _test_ability_start_message() -> void:
	var data = _accepted_ability_data()
	_expect_equal(_formatter.format_ability_start_message(data), "Warrior Strike activated", "ability start message")
	print("ok - ability start message")


func _test_ability_damage_message() -> void:
	var data = _accepted_ability_data()
	_expect_equal(_formatter.format_ability_damage_message(data), "Warrior Strike dealt 50 damage", "ability damage message")
	print("ok - ability damage message")


func _test_ability_rejected_messages() -> void:
	_expect_equal(_formatter.format_ability_rejected_message("ability_not_ready"), "Ability is not ready yet", "ability_not_ready message")
	_expect_equal(_formatter.format_ability_rejected_message("hero_dead"), "This hero is down", "hero_dead message")
	_expect_equal(_formatter.format_ability_rejected_message("battle_finished"), "Battle is already over", "battle_finished message")
	_expect_equal(_formatter.format_ability_rejected_message("something_else"), "Ability unavailable", "unknown reason message")
	print("ok - ability rejected messages")


func _test_victory_message() -> void:
	_expect_equal(_formatter.format_victory_message(0, 0), "Victory!", "victory message with no reward")
	_expect_equal(_formatter.format_victory_message(10, 2), "Victory! +10 points (2/3 stars)", "victory message with reward")
	print("ok - victory message")


func _test_defeat_message() -> void:
	_expect_equal(_formatter.format_defeat_message(), "Defeat — upgrade heroes or try again", "defeat message")
	print("ok - defeat message")


func _test_debug_labels_include_ids() -> void:
	var data = _turn_data({0: 3}, [{"lane_index": 0, "hero_id": "hero_1", "damage": 30}], 30)
	_expect_equal(_formatter.format_damage_message(data, true), "Hero 1 (hero_1) dealt 30 damage", "debug damage message includes hero id")

	var ability_data = _accepted_ability_data()
	_expect_equal(_formatter.format_ability_start_message(ability_data, true), "Warrior Strike (warrior_strike) activated", "debug ability message includes ability id")
	print("ok - debug labels include useful ids")


func _test_unknown_data_uses_safe_fallback() -> void:
	_expect_equal(_formatter.format_damage_message(null), "No damage dealt", "null turn data uses safe fallback")
	_expect_equal(_formatter.format_ability_start_message(null), "Ability activated", "null ability data uses safe fallback")
	_expect_equal(_formatter.format_hero_name(""), "Hero", "empty hero id uses safe fallback")
	_expect_equal(_formatter.format_lane_name(99), "Lane", "unknown lane index uses safe fallback")
	print("ok - unknown or missing data uses safe fallback")


func _test_direct_damage_messages() -> void:
	var matched_data = load(TURN_PRESENTATION_DATA_SCRIPT).new()
	matched_data.total_damage_to_enemy = 3
	_expect_equal(_formatter.format_direct_damage_message(matched_data), "Matched 3 tiles: 3 damage", "matched tiles damage message")

	var five_data = load(TURN_PRESENTATION_DATA_SCRIPT).new()
	five_data.total_damage_to_enemy = 5
	_expect_equal(_formatter.format_direct_damage_message(five_data), "Matched 5 tiles: 5 damage", "5 tile matched damage message")

	var special_data = load(TURN_PRESENTATION_DATA_SCRIPT).new()
	special_data.total_damage_to_enemy = 9
	var special_cells: Array[Vector2i] = [Vector2i(0, 0)]
	special_data.special_cleared_cells = special_cells
	_expect_equal(_formatter.format_direct_damage_message(special_data), "Special cleared 9 tiles: 9 damage", "special clear damage message")

	var no_damage_data = load(TURN_PRESENTATION_DATA_SCRIPT).new()
	_expect_equal(_formatter.format_direct_damage_message(no_damage_data), "No damage dealt", "no direct damage message")
	_expect_equal(_formatter.format_direct_damage_message(null), "No damage dealt", "null direct damage data uses safe fallback")
	print("ok - direct damage messages")


func _test_enemy_defeated_message() -> void:
	_expect_equal(_formatter.format_enemy_defeated_message(), "Enemy defeated!", "enemy defeated message")
	print("ok - enemy defeated message")


func _turn_data(lane_activations: Dictionary, damage_events: Array, total_damage: int):
	var data = load(TURN_PRESENTATION_DATA_SCRIPT).new()
	data.lane_activations = lane_activations
	var typed_events: Array[Dictionary] = []
	for event in damage_events:
		typed_events.append(event)
	data.damage_events = typed_events
	data.total_damage_to_enemy = total_damage
	return data


func _accepted_ability_data():
	var hero := HeroData.new("hero_1", "Hero 1", 0, 10, 100, 0, 0, 10)
	var ability = load(ABILITY_DATA_SCRIPT).warrior_strike("hero_1")
	var result = load(ABILITY_RESULT_SCRIPT).accepted_result(hero, ability, BattleState.Status.IN_PROGRESS)
	result.damage_to_enemy = 50
	return load(ABILITY_PRESENTATION_DATA_SCRIPT).from_result(result)


func _expect_equal(actual, expected, message: String) -> void:
	if actual == expected:
		return

	_failures += 1
	push_error("FAILED: %s | expected=%s actual=%s" % [message, expected, actual])

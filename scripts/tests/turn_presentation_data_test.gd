extends SceneTree

const TURN_PRESENTATION_DATA_SCRIPT := "res://scripts/game/presentation/turn_presentation_data.gd"

var _failures := 0


func _initialize() -> void:
	print("Running turn presentation data tests...")

	_test_valid_turn_stores_swapped_cells()
	_test_matched_cells_are_extracted()
	_test_duplicate_matched_cells_are_not_duplicated()
	_test_lane_activations_are_copied()
	_test_damage_fields_are_copied()
	_test_enemy_action_is_copied()
	_test_invalid_turn_stores_reason()

	if _failures == 0:
		print("Turn presentation data tests passed.")
		quit(0)
	else:
		push_error("Turn presentation data tests failed: %d" % _failures)
		quit(1)


func _test_valid_turn_stores_swapped_cells() -> void:
	var data = _create_valid_data()
	_expect_true(data.is_valid, "valid turn flag")
	_expect_equal(data.swapped_from, Vector2i(1, 1), "valid turn swapped_from")
	_expect_equal(data.swapped_to, Vector2i(2, 1), "valid turn swapped_to")
	print("ok - valid turn stores swapped cells")


func _test_matched_cells_are_extracted() -> void:
	var data = _create_valid_data()
	_expect_true(Vector2i(0, 0) in data.matched_cells, "matched cells include first cell")
	_expect_true(Vector2i(2, 0) in data.matched_cells, "matched cells include third cell")
	print("ok - matched cells are extracted from matches")


func _test_duplicate_matched_cells_are_not_duplicated() -> void:
	var data = _create_valid_data()
	_expect_equal(data.matched_cells.size(), 5, "duplicate matched cells are unique")
	print("ok - duplicate matched cells are not duplicated")


func _test_lane_activations_are_copied() -> void:
	var data = _create_valid_data()
	_expect_equal(data.lane_activations[0], 3, "lane 0 activation copied")
	_expect_equal(data.lane_activations[1], 2, "lane 1 activation copied")
	print("ok - lane activations are copied")


func _test_damage_fields_are_copied() -> void:
	var data = _create_valid_data()
	_expect_equal(data.total_damage_to_enemy, 46, "total damage copied")
	_expect_equal(data.damage_events[0]["damage"], 30, "damage event copied")
	print("ok - damage fields are copied")


func _test_enemy_action_is_copied() -> void:
	var data = _create_valid_data()
	_expect_true(data.enemy_action["acted"], "enemy action acted copied")
	_expect_equal(data.enemy_action["target_hero_id"], "hero_2", "enemy action target copied")
	print("ok - enemy action is copied")


func _test_invalid_turn_stores_reason() -> void:
	var data = load(TURN_PRESENTATION_DATA_SCRIPT).from_invalid_turn(Vector2i(3, 3), Vector2i(4, 3), "no_match")
	_expect_false(data.is_valid, "invalid turn flag")
	_expect_equal(data.invalid_reason, "no_match", "invalid reason copied")
	_expect_equal(data.swapped_from, Vector2i(3, 3), "invalid swapped_from")
	_expect_equal(data.swapped_to, Vector2i(4, 3), "invalid swapped_to")
	print("ok - invalid turn stores invalid reason")


func _create_valid_data():
	var matches: Array[MatchResult] = [
		_match([Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)]),
		_match([Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2)], MatchResult.Direction.VERTICAL),
	]
	var result := BattleTurnResult.new()
	result.lane_activations = {0: 3, 1: 2, 2: 0}
	result.damage_events = [
		{"lane_index": 0, "hero_id": "hero_1", "tile_count": 3, "damage": 30},
		{"lane_index": 1, "hero_id": "hero_2", "tile_count": 2, "damage": 16},
	]
	result.total_damage_to_enemy = 46
	result.ability_charge_events = [{"lane_index": 0, "hero_id": "hero_1", "charge_added": 3}]
	result.enemy_action = {"acted": true, "target_lane": 1, "target_hero_id": "hero_2", "damage": 20}
	result.battle_status = BattleState.Status.IN_PROGRESS
	return load(TURN_PRESENTATION_DATA_SCRIPT).from_valid_turn(Vector2i(1, 1), Vector2i(2, 1), matches, result)


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


func _expect_false(value: bool, message: String) -> void:
	_expect_true(not value, message)


func _expect_equal(actual, expected, message: String) -> void:
	if actual == expected:
		return

	_failures += 1
	push_error("FAILED: %s | expected=%s actual=%s" % [message, expected, actual])

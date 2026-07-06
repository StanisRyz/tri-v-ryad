extends SceneTree

const BUILDER_SCRIPT := "res://scripts/game/presentation/damage_particle_event_builder.gd"
const TURN_PRESENTATION_DATA_SCRIPT := "res://scripts/game/presentation/turn_presentation_data.gd"
const BOOSTER_CATALOG_SCRIPT := "res://scripts/game/config/booster_catalog.gd"

var _failures := 0


func _initialize() -> void:
	print("Running damage particle event builder tests...")

	var builder = load(BUILDER_SCRIPT).new()

	_expect_true(builder.build_from_turn_presentation(null).is_empty(), "null turn data returns empty array")
	_expect_true(builder.build_from_booster_result(null).is_empty(), "null booster result returns empty array")

	var no_damage_data = _create_turn_data(0, [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)])
	_expect_true(builder.build_from_turn_presentation(no_damage_data).is_empty(), "turn data without damage builds no particle events")

	var damage_data = _create_turn_data(3, [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)])
	var turn_events: Array = builder.build_from_turn_presentation(damage_data)
	_expect_true(not turn_events.is_empty(), "turn data with damage builds particle events")
	var turn_total := 0
	for event in turn_events:
		_expect_true(event.has("cell"), "turn event has cell")
		_expect_true(event.has("tile_type"), "turn event has tile_type")
		_expect_true(event.has("damage"), "turn event has damage")
		_expect_true(event.has("multiplier"), "turn event has multiplier")
		_expect_true(event.has("is_boosted"), "turn event has is_boosted")
		_expect_true(event.has("source"), "turn event has source")
		turn_total += int(event.damage)
	_expect_equal(turn_total, 3, "turn particle event damage sums to total damage")

	var invalid_data = load(TURN_PRESENTATION_DATA_SCRIPT).from_invalid_turn(Vector2i(0, 0), Vector2i(1, 0), "no_match")
	_expect_true(builder.build_from_turn_presentation(invalid_data).is_empty(), "invalid turn data returns empty array safely")

	var hammer_result = _create_booster_result(BOOSTER_CATALOG_SCRIPT_CONST().HAMMER, [Vector2i(4, 4), Vector2i(4, 5)], 2)
	var hammer_events: Array = builder.build_from_booster_result(hammer_result)
	_expect_true(not hammer_events.is_empty(), "hammer booster result with damage builds particle events")
	for event in hammer_events:
		_expect_true(event.is_boosted, "hammer particle events are marked boosted")

	var rocket_result = _create_booster_result(BOOSTER_CATALOG_SCRIPT_CONST().ROCKET_BARRAGE, [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2)], 3)
	var rocket_events: Array = builder.build_from_booster_result(rocket_result)
	_expect_true(not rocket_events.is_empty(), "rocket booster result with damage builds particle events")

	var freeze_result = _create_booster_result(BOOSTER_CATALOG_SCRIPT_CONST().FREEZE_TIME, [], 0)
	freeze_result.freeze_turns_added = 3
	_expect_true(builder.build_from_booster_result(freeze_result).is_empty(), "time freeze builds no particle events")

	var invalid_booster_result = load("res://scripts/game/battle/booster_resolve_result.gd").new()
	invalid_booster_result.is_valid = false
	_expect_true(builder.build_from_booster_result(invalid_booster_result).is_empty(), "invalid booster result returns empty array safely")

	var no_damage_booster_result = _create_booster_result(BOOSTER_CATALOG_SCRIPT_CONST().HAMMER, [Vector2i(2, 2)], 0)
	_expect_true(builder.build_from_booster_result(no_damage_booster_result).is_empty(), "booster result without damage builds no particle events")

	var large_data = _create_turn_data(30, _make_cell_line(30))
	var large_events: Array = builder.build_from_turn_presentation(large_data)
	_expect_true(large_events.size() <= 30, "builder does not fabricate more events than cleared cells")

	_finish()


func BOOSTER_CATALOG_SCRIPT_CONST():
	return load(BOOSTER_CATALOG_SCRIPT)


func _make_cell_line(count: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for i in range(count):
		cells.append(Vector2i(i % 9, int(i / 9.0)))
	return cells


func _create_turn_data(total_damage: int, matched_cells: Array[Vector2i]):
	var matches: Array[MatchResult] = [MatchResult.new(matched_cells, TileType.RED)]
	var result := BattleTurnResult.new()
	result.total_damage_to_enemy = total_damage
	result.total_tiles_cleared = matched_cells.size()
	return load(TURN_PRESENTATION_DATA_SCRIPT).from_valid_turn(matched_cells[0], matched_cells[0], matches, result)


func _create_booster_result(booster_id: String, cleared_cells: Array[Vector2i], damage: int):
	var result = load("res://scripts/game/battle/booster_resolve_result.gd").new()
	result.is_valid = true
	result.booster_id = booster_id
	result.cleared_cells = cleared_cells
	result.damage_to_enemy = damage
	var tile_types := {}
	for cell in cleared_cells:
		tile_types[cell] = TileType.RED
	result.cleared_cell_tile_types = tile_types
	return result


func _finish() -> void:
	if _failures == 0:
		print("Damage particle event builder tests passed.")
		quit(0)
	else:
		push_error("Damage particle event builder tests failed: %d" % _failures)
		quit(1)


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

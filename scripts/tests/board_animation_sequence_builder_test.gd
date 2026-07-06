extends SceneTree

const REQUEST_SCRIPT := "res://scripts/game/presentation/board_animation_request.gd"
const BUILDER_SCRIPT := "res://scripts/game/presentation/board_animation_sequence_builder.gd"
const TURN_PRESENTATION_DATA_SCRIPT := "res://scripts/game/presentation/turn_presentation_data.gd"

var _failures := 0


func _initialize() -> void:
	print("Running board animation sequence builder tests...")

	var builder = load(BUILDER_SCRIPT).new()
	var turn_sequence = builder.build_from_turn_presentation(_create_valid_turn_data())
	_expect_true(turn_sequence.size() >= 2, "valid turn builds multiple requests")
	_expect_equal(turn_sequence.get_requests()[0].animation_type, load(REQUEST_SCRIPT).TYPE_SWAP, "valid turn starts with swap")
	_expect_equal(turn_sequence.get_requests()[1].animation_type, load(REQUEST_SCRIPT).TYPE_MATCH_CLEAR, "valid turn includes match clear")
	_expect_equal(turn_sequence.get_requests()[1].payload["cells_count"], 3, "match clear payload stores cell count")

	var invalid_sequence = builder.build_invalid_swap(Vector2i(1, 1), Vector2i(2, 1), "no_match")
	_expect_equal(invalid_sequence.size(), 1, "invalid swap builds one request")
	_expect_equal(invalid_sequence.get_requests()[0].animation_type, load(REQUEST_SCRIPT).TYPE_INVALID_SWAP, "invalid swap request type")

	var booster_result := BoosterResolveResult.new()
	booster_result.is_valid = true
	booster_result.booster_id = "hammer"
	booster_result.cleared_cells = [Vector2i(4, 4), Vector2i(4, 5)]
	var booster_sequence = builder.build_from_booster_result(booster_result)
	_expect_equal(booster_sequence.size(), 1, "booster clear builds one request")
	_expect_equal(booster_sequence.get_requests()[0].animation_type, load(REQUEST_SCRIPT).TYPE_BOOSTER_CLEAR, "booster clear request type")

	_expect_true(builder.build_from_turn_presentation(null).is_empty(), "null turn data returns empty sequence")
	_expect_true(builder.build_from_booster_result(null).is_empty(), "null booster result returns empty sequence")

	_finish()


func _create_valid_turn_data():
	var matches: Array[MatchResult] = [
		MatchResult.new([Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)], TileType.RED),
	]
	var result := BattleTurnResult.new()
	result.total_damage_to_enemy = 3
	result.total_tiles_cleared = 3
	return load(TURN_PRESENTATION_DATA_SCRIPT).from_valid_turn(Vector2i(0, 0), Vector2i(1, 0), matches, result)


func _finish() -> void:
	if _failures == 0:
		print("Board animation sequence builder tests passed.")
		quit(0)
	else:
		push_error("Board animation sequence builder tests failed: %d" % _failures)
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

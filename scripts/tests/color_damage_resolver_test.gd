extends SceneTree

const ROUND_MODIFIER_CATALOG_SCRIPT := "res://scripts/game/config/round_modifier_catalog.gd"

var _failures := 0
var _catalog


func _initialize() -> void:
	print("Running color damage resolver tests...")
	_catalog = load(ROUND_MODIFIER_CATALOG_SCRIPT).new()

	_test_three_red_tiles_with_red_x3_deal_nine_damage()
	_test_three_blue_tiles_with_red_x3_deal_three_damage()
	_test_five_red_tiles_with_red_x3_deal_fifteen_damage()
	_test_all_x2_doubles_mixed_colors()
	_test_null_modifier_matches_stage_32_behavior()
	_test_board_result_cascade_applies_modifier_per_step()
	_test_board_result_special_cleared_cells_fall_back_to_x1()

	if _failures == 0:
		print("Color damage resolver tests passed.")
		quit(0)
	else:
		push_error("Color damage resolver tests failed: %d" % _failures)
		quit(1)


func _test_three_red_tiles_with_red_x3_deal_nine_damage() -> void:
	var red_x3 = _catalog.get_modifier("red_x3")
	var matches: Array[MatchResult] = [_match([Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)], TileType.RED)]
	var result := DirectMatchDamageResolver.new().calculate_damage_for_matches(matches, red_x3)
	_expect_equal(result.get("total_damage"), 9, "3 red tiles with red_x3 deal 9 damage")
	print("ok - 3 red tiles with red_x3 deal 9 damage")


func _test_three_blue_tiles_with_red_x3_deal_three_damage() -> void:
	var red_x3 = _catalog.get_modifier("red_x3")
	var matches: Array[MatchResult] = [_match([Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)], TileType.BLUE)]
	var result := DirectMatchDamageResolver.new().calculate_damage_for_matches(matches, red_x3)
	_expect_equal(result.get("total_damage"), 3, "3 blue tiles with red_x3 deal 3 damage")
	print("ok - 3 blue tiles with red_x3 deal 3 damage")


func _test_five_red_tiles_with_red_x3_deal_fifteen_damage() -> void:
	var red_x3 = _catalog.get_modifier("red_x3")
	var cells: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(4, 0)]
	var matches: Array[MatchResult] = [_match(cells, TileType.RED)]
	var result := DirectMatchDamageResolver.new().calculate_damage_for_matches(matches, red_x3)
	_expect_equal(result.get("total_damage"), 15, "5 red tiles with red_x3 deal 15 damage")
	print("ok - 5 red tiles with red_x3 deal 15 damage")


func _test_all_x2_doubles_mixed_colors() -> void:
	var all_x2 = _catalog.get_modifier("all_x2")
	var matches: Array[MatchResult] = [
		_match([Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)], TileType.RED),
		_match([Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)], TileType.BLUE),
	]
	var result := DirectMatchDamageResolver.new().calculate_damage_for_matches(matches, all_x2)
	_expect_equal(result.get("total_damage"), 12, "all_x2 doubles mixed-color matches (6 tiles -> 12 damage)")
	print("ok - all_x2 doubles mixed colors correctly")


func _test_null_modifier_matches_stage_32_behavior() -> void:
	var matches: Array[MatchResult] = [_match([Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)], TileType.RED)]
	var resolver := DirectMatchDamageResolver.new()
	var result := resolver.calculate_damage_for_matches(matches, null)
	_expect_equal(result.get("total_damage"), 3, "null modifier keeps 1 cleared crystal = 1 damage")

	var board_result := BoardResolveResult.new()
	board_result.add_step(matches, matches[0].cells, {})
	_expect_equal(resolver.calculate_damage_from_turn_result(board_result), 3, "null modifier board result damage matches Stage 32 behavior")
	print("ok - null modifier preserves Stage 32 direct damage behavior")


func _test_board_result_cascade_applies_modifier_per_step() -> void:
	var red_x3 = _catalog.get_modifier("red_x3")
	var resolver := DirectMatchDamageResolver.new()
	var board_result := BoardResolveResult.new()

	var step_one_matches: Array[MatchResult] = [_match([Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)], TileType.RED)]
	board_result.add_step(step_one_matches, step_one_matches[0].cells, {})

	var step_two_matches: Array[MatchResult] = [_match([Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)], TileType.BLUE)]
	board_result.add_step(step_two_matches, step_two_matches[0].cells, {})

	var damage := resolver.calculate_damage_for_board_result(board_result, red_x3)
	_expect_equal(damage, 12, "cascade steps apply the modifier per-step (3 red x3 + 3 blue x1 = 12)")
	print("ok - cascade steps apply the round modifier using each step's match colors")


func _test_board_result_special_cleared_cells_fall_back_to_x1() -> void:
	var red_x3 = _catalog.get_modifier("red_x3")
	var resolver := DirectMatchDamageResolver.new()
	var board_result := BoardResolveResult.new()

	var matches: Array[MatchResult] = [_match([Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)], TileType.RED)]
	var special_cleared: Array[Vector2i] = [Vector2i(5, 5), Vector2i(6, 5)]
	var cleared_cells: Array[Vector2i] = matches[0].cells.duplicate()
	cleared_cells.append_array(special_cleared)
	board_result.add_step(matches, cleared_cells, {}, [], [], special_cleared)

	var damage := resolver.calculate_damage_for_board_result(board_result, red_x3)
	_expect_equal(damage, 11, "special-cleared cells without color data fall back to x1 (3 red x3 + 2 special x1 = 11)")
	print("ok - special-cleared cells without color data fall back to x1 damage")


func _match(raw_cells: Array, tile_type: int) -> MatchResult:
	var cells: Array[Vector2i] = []
	for cell in raw_cells:
		cells.append(cell)
	return MatchResult.new(cells, tile_type, MatchResult.Direction.HORIZONTAL)


func _expect_equal(actual, expected, message: String) -> void:
	if actual == expected:
		return

	_failures += 1
	push_error("FAILED: %s | expected=%s actual=%s" % [message, expected, actual])

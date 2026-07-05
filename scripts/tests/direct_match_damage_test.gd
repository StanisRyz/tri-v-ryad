extends SceneTree

var _failures := 0


func _initialize() -> void:
	print("Running direct match damage tests...")

	_test_three_cleared_cells_deal_three_damage()
	_test_five_cleared_cells_deal_five_damage()
	_test_duplicate_cells_not_double_counted()
	_test_no_cells_deal_no_damage()
	_test_multiple_groups_sum_total_cells()
	_test_calculate_damage_from_board_resolve_result()
	_test_calculate_damage_from_turn_presentation_data()

	if _failures == 0:
		print("Direct match damage tests passed.")
		quit(0)
	else:
		push_error("Direct match damage tests failed: %d" % _failures)
		quit(1)


func _test_three_cleared_cells_deal_three_damage() -> void:
	var cells: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)]
	_expect_equal(DirectMatchDamageResolver.new().calculate_damage(cells), 3, "3 cleared cells deal 3 damage")
	print("ok - 3 cleared cells deal 3 damage")


func _test_five_cleared_cells_deal_five_damage() -> void:
	var cells: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(4, 0)]
	_expect_equal(DirectMatchDamageResolver.new().calculate_damage(cells), 5, "5 cleared cells deal 5 damage")
	print("ok - 5 cleared cells deal 5 damage")


func _test_duplicate_cells_not_double_counted() -> void:
	var cells: Array[Vector2i] = [Vector2i(0, 0), Vector2i(0, 0), Vector2i(1, 0)]
	var resolver := DirectMatchDamageResolver.new()
	_expect_equal(resolver.count_unique_cleared_cells(cells), 2, "duplicate cells are counted once")
	_expect_equal(resolver.calculate_damage(cells), 2, "duplicate cells do not inflate damage")
	print("ok - duplicate cleared cells are not double-counted")


func _test_no_cells_deal_no_damage() -> void:
	var cells: Array[Vector2i] = []
	_expect_equal(DirectMatchDamageResolver.new().calculate_damage(cells), 0, "no cleared cells deal no damage")
	print("ok - no cleared cells deal no damage")


func _test_multiple_groups_sum_total_cells() -> void:
	var cells: Array[Vector2i] = [
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0),
		Vector2i(5, 5), Vector2i(6, 5), Vector2i(7, 5), Vector2i(8, 5),
	]
	_expect_equal(DirectMatchDamageResolver.new().calculate_damage(cells), 7, "multiple cleared groups sum to total cleared cells")
	print("ok - multiple cleared groups sum total damage")


func _test_calculate_damage_from_board_resolve_result() -> void:
	var board_result := BoardResolveResult.new()
	var matches: Array[MatchResult] = []
	var cleared_cells: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)]
	board_result.add_step(matches, cleared_cells, {})
	_expect_equal(DirectMatchDamageResolver.new().calculate_damage_from_turn_result(board_result), 3, "board resolve result damage uses total_cleared")
	print("ok - calculate_damage_from_turn_result reads BoardResolveResult.total_cleared")


func _test_calculate_damage_from_turn_presentation_data() -> void:
	var data := TurnPresentationData.new()
	data.matched_cells = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)]
	data.special_cleared_cells = [Vector2i(3, 0), Vector2i(0, 0)]
	_expect_equal(DirectMatchDamageResolver.new().calculate_damage_from_turn_result(data), 4, "turn presentation data damage counts matched + special cells uniquely")
	print("ok - calculate_damage_from_turn_result reads matched + special cleared cells")


func _expect_equal(actual, expected, message: String) -> void:
	if actual == expected:
		return

	_failures += 1
	push_error("FAILED: %s | expected=%s actual=%s" % [message, expected, actual])

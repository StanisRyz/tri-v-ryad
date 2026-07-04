extends SceneTree

const BOARD_INPUT_CONTROLLER_SCRIPT := "res://scripts/game/input/board_input_controller.gd"

var _failures := 0
var _swap_events: Array[Dictionary] = []
var _selection_events: Array[Vector2i] = []
var _selection_cleared_count := 0
var _invalid_reasons: Array[String] = []


func _initialize() -> void:
	print("Running board input controller tests...")

	_test_short_drag_does_not_request_swap()
	_test_right_drag_requests_right_neighbor()
	_test_left_drag_requests_left_neighbor()
	_test_up_drag_requests_up_neighbor()
	_test_down_drag_requests_down_neighbor()
	_test_disabled_input_ignores_drag_and_click()
	_test_two_click_neighbor_requests_swap()
	_test_non_neighbor_click_changes_selection()
	_test_same_cell_click_clears_selection()

	if _failures == 0:
		print("Board input controller tests passed.")
		quit(0)
	else:
		push_error("Board input controller tests failed: %d" % _failures)
		quit(1)


func _test_short_drag_does_not_request_swap() -> void:
	var controller = _create_controller()
	controller.handle_tile_drag_released(Vector2i(4, 4), Vector2(8, 2))
	_expect_equal(_swap_events.size(), 0, "short drag emits no swap")
	_expect_equal(_invalid_reasons[0], "swipe_too_short", "short drag reason")
	print("ok - short drag does not request swap")


func _test_right_drag_requests_right_neighbor() -> void:
	var controller = _create_controller()
	controller.handle_tile_drag_released(Vector2i(4, 4), Vector2(40, 3))
	_expect_swap(Vector2i(4, 4), Vector2i(5, 4), "right drag swap")
	print("ok - right drag requests right neighbor")


func _test_left_drag_requests_left_neighbor() -> void:
	var controller = _create_controller()
	controller.handle_tile_drag_released(Vector2i(4, 4), Vector2(-40, 3))
	_expect_swap(Vector2i(4, 4), Vector2i(3, 4), "left drag swap")
	print("ok - left drag requests left neighbor")


func _test_up_drag_requests_up_neighbor() -> void:
	var controller = _create_controller()
	controller.handle_tile_drag_released(Vector2i(4, 4), Vector2(3, -40))
	_expect_swap(Vector2i(4, 4), Vector2i(4, 3), "up drag swap")
	print("ok - up drag requests upward neighbor")


func _test_down_drag_requests_down_neighbor() -> void:
	var controller = _create_controller()
	controller.handle_tile_drag_released(Vector2i(4, 4), Vector2(3, 40))
	_expect_swap(Vector2i(4, 4), Vector2i(4, 5), "down drag swap")
	print("ok - down drag requests downward neighbor")


func _test_disabled_input_ignores_drag_and_click() -> void:
	var controller = _create_controller()
	controller.set_input_enabled(false)
	controller.handle_tile_pressed(Vector2i(1, 1))
	controller.handle_tile_drag_released(Vector2i(1, 1), Vector2(40, 0))
	_expect_equal(_swap_events.size(), 0, "disabled input emits no swap")
	_expect_equal(_selection_events.size(), 0, "disabled input emits no selection")
	_expect_equal(_invalid_reasons.size(), 2, "disabled input reports invalid attempts")
	print("ok - disabled input ignores drag and click")


func _test_two_click_neighbor_requests_swap() -> void:
	var controller = _create_controller()
	controller.handle_tile_pressed(Vector2i(2, 2))
	controller.handle_tile_pressed(Vector2i(3, 2))
	_expect_swap(Vector2i(2, 2), Vector2i(3, 2), "two-click neighbor swap")
	_expect_equal(_selection_cleared_count, 1, "two-click swap clears selection")
	print("ok - two-click input still requests swap")


func _test_non_neighbor_click_changes_selection() -> void:
	var controller = _create_controller()
	controller.handle_tile_pressed(Vector2i(2, 2))
	controller.handle_tile_pressed(Vector2i(6, 6))
	_expect_equal(_swap_events.size(), 0, "non-neighbor click emits no swap")
	_expect_equal(_selection_events[1], Vector2i(6, 6), "non-neighbor click changes selection")
	print("ok - non-neighbor click changes selection")


func _test_same_cell_click_clears_selection() -> void:
	var controller = _create_controller()
	controller.handle_tile_pressed(Vector2i(2, 2))
	controller.handle_tile_pressed(Vector2i(2, 2))
	_expect_equal(_swap_events.size(), 0, "same-cell click emits no swap")
	_expect_equal(_selection_cleared_count, 1, "same-cell click clears selection")
	print("ok - same-cell click clears selection")


func _create_controller():
	_swap_events.clear()
	_selection_events.clear()
	_selection_cleared_count = 0
	_invalid_reasons.clear()

	var controller = load(BOARD_INPUT_CONTROLLER_SCRIPT).new()
	controller.swap_requested.connect(_on_swap_requested)
	controller.selection_changed.connect(_on_selection_changed)
	controller.selection_cleared.connect(_on_selection_cleared)
	controller.invalid_input.connect(_on_invalid_input)
	return controller


func _on_swap_requested(from_cell: Vector2i, to_cell: Vector2i) -> void:
	_swap_events.append({
		"from": from_cell,
		"to": to_cell,
	})


func _on_selection_changed(cell: Vector2i) -> void:
	_selection_events.append(cell)


func _on_selection_cleared() -> void:
	_selection_cleared_count += 1


func _on_invalid_input(reason: String) -> void:
	_invalid_reasons.append(reason)


func _expect_swap(from_cell: Vector2i, to_cell: Vector2i, message: String) -> void:
	_expect_equal(_swap_events.size(), 1, "%s count" % message)
	if _swap_events.is_empty():
		return

	_expect_equal(_swap_events[0]["from"], from_cell, "%s from cell" % message)
	_expect_equal(_swap_events[0]["to"], to_cell, "%s to cell" % message)


func _expect_equal(actual, expected, message: String) -> void:
	if actual == expected:
		return

	_failures += 1
	push_error("FAILED: %s | expected=%s actual=%s" % [message, expected, actual])

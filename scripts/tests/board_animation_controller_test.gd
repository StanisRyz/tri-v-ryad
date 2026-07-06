extends SceneTree

const REQUEST_SCRIPT := "res://scripts/game/presentation/board_animation_request.gd"
const SEQUENCE_SCRIPT := "res://scripts/game/presentation/board_animation_sequence.gd"
const CONTROLLER_SCRIPT := "res://scripts/game/view/board_animation_controller.gd"

var _failures := 0
var _callback_count := 0


class RecordingBoardView:
	extends Control

	var swap_calls := 0
	var invalid_calls := 0
	var match_calls := 0
	var special_calls := 0
	var gravity_calls := 0
	var refill_calls := 0
	var cascade_calls := 0
	var last_gravity_movements: Array = []
	var last_refill_cells: Array = []
	var last_cascade_payload: Dictionary = {}

	func play_swap_animation(_from_cell: Vector2i, _to_cell: Vector2i, _duration: float) -> void:
		swap_calls += 1

	func play_invalid_swap_animation(_from_cell: Vector2i, _to_cell: Vector2i, _duration: float) -> void:
		invalid_calls += 1

	func play_match_clear_animation(_cells: Array[Vector2i], _duration: float) -> void:
		match_calls += 1

	func play_special_clear_animation(_cells: Array[Vector2i], _duration: float) -> void:
		special_calls += 1

	func play_gravity_fall_animation(movements: Array, _duration: float) -> void:
		gravity_calls += 1
		last_gravity_movements = movements

	func play_refill_animation(refill_cells: Array, _duration: float) -> void:
		refill_calls += 1
		last_refill_cells = refill_cells

	func play_cascade_step_animation(payload: Dictionary, _duration: float) -> void:
		cascade_calls += 1
		last_cascade_payload = payload


func _initialize() -> void:
	print("Running board animation controller tests...")
	_run()


func _run() -> void:
	_test_disabled_finishes_immediately()
	_test_empty_sequence_finishes_safely()
	_test_null_board_view_finishes_safely()
	await _test_reduced_motion_shortens_duration_and_calls_once()
	await _test_request_types_call_concrete_paths()
	_finish()


func _test_disabled_finishes_immediately() -> void:
	_callback_count = 0
	var controller = load(CONTROLLER_SCRIPT).new()
	controller.configure_settings(false, false)
	controller.play_requests([_request(0.2)], null, Callable(self, "_on_callback"))
	_expect_equal(_callback_count, 1, "disabled animations call callback")
	_expect_false(controller.is_playing(), "disabled animations do not stay playing")


func _test_empty_sequence_finishes_safely() -> void:
	_callback_count = 0
	var controller = load(CONTROLLER_SCRIPT).new()
	controller.play_sequence(load(SEQUENCE_SCRIPT).new(), null, Callable(self, "_on_callback"))
	_expect_equal(_callback_count, 1, "empty sequence calls callback")
	_expect_false(controller.is_playing(), "empty sequence does not stay playing")


func _test_null_board_view_finishes_safely() -> void:
	_callback_count = 0
	var controller = load(CONTROLLER_SCRIPT).new()
	controller.play_requests([_request(0.2)], null, Callable(self, "_on_callback"))
	_expect_equal(_callback_count, 1, "null board view calls callback")
	_expect_false(controller.is_playing(), "null board view does not stay playing")


func _test_reduced_motion_shortens_duration_and_calls_once() -> void:
	_callback_count = 0
	var board_view := Control.new()
	root.add_child(board_view)
	await process_frame
	var controller = load(CONTROLLER_SCRIPT).new()
	controller.configure_settings(true, true)
	controller.play_requests([_request(0.2)], board_view, Callable(self, "_on_callback"))
	await process_frame
	_expect_true(controller.is_playing(), "enabled controller starts playing")
	_expect_true(controller.last_effective_duration < 0.2, "reduced motion shortens duration")
	await create_timer(0.15).timeout
	_expect_equal(_callback_count, 1, "enabled controller calls callback once")
	_expect_false(controller.is_playing(), "enabled controller finishes playing")
	board_view.free()


func _request(duration: float):
	return load(REQUEST_SCRIPT).new_request(load(REQUEST_SCRIPT).TYPE_MATCH_CLEAR).with_duration(duration)


func _test_request_types_call_concrete_paths() -> void:
	_callback_count = 0
	var request_script = load(REQUEST_SCRIPT)
	var board_view := RecordingBoardView.new()
	root.add_child(board_view)
	await process_frame
	var controller = load(CONTROLLER_SCRIPT).new()
	var one_cell: Array[Vector2i] = [Vector2i(0, 0)]
	var movements: Array = [{"from": Vector2i(0, 1), "to": Vector2i(0, 2), "tile_type": 0, "special_data": null, "fall_distance": 1}]
	var refill_cells: Array = [{"spawn_index": 0, "to": Vector2i(0, 0), "tile_type": 0, "special_data": null}]
	controller.play_requests([
		request_script.new_request(request_script.TYPE_SWAP).with_swap(Vector2i(0, 0), Vector2i(1, 0)).with_duration(0.01),
		request_script.new_request(request_script.TYPE_INVALID_SWAP).with_swap(Vector2i(0, 0), Vector2i(1, 0)).with_duration(0.01),
		request_script.new_request(request_script.TYPE_MATCH_CLEAR).with_cells(one_cell).with_duration(0.01),
		request_script.new_request(request_script.TYPE_SPECIAL_CLEAR).with_cells(one_cell).with_duration(0.01),
		request_script.new_request(request_script.TYPE_GRAVITY_FALL).with_duration(0.01).with_payload({"movements": movements}),
		request_script.new_request(request_script.TYPE_REFILL).with_duration(0.01).with_payload({"refill_cells": refill_cells}),
		request_script.new_request(request_script.TYPE_CASCADE_STEP).with_cells(one_cell).with_duration(0.01).with_payload({"cascade_index": 1, "matched_cells": one_cell, "damage": 1}),
	], board_view, Callable(self, "_on_callback"))
	await create_timer(0.15).timeout
	_expect_equal(board_view.swap_calls, 1, "swap request calls swap animation path")
	_expect_equal(board_view.invalid_calls, 1, "invalid request calls invalid animation path")
	_expect_equal(board_view.match_calls, 1, "match request calls match clear path")
	_expect_equal(board_view.special_calls, 1, "special request calls special clear path")
	_expect_equal(board_view.gravity_calls, 1, "gravity_fall request calls gravity animation path")
	_expect_equal(board_view.last_gravity_movements.size(), 1, "gravity_fall request passes movements payload")
	_expect_equal(board_view.refill_calls, 1, "refill request calls refill animation path")
	_expect_equal(board_view.last_refill_cells.size(), 1, "refill request passes refill_cells payload")
	_expect_equal(board_view.cascade_calls, 1, "cascade_step request calls cascade animation path")
	_expect_equal(board_view.last_cascade_payload.get("cascade_index", -1), 1, "cascade_step request passes cascade_index payload")
	_expect_equal(_callback_count, 1, "concrete path playback calls callback once")
	board_view.free()


func _on_callback() -> void:
	_callback_count += 1


func _finish() -> void:
	if _failures == 0:
		print("Board animation controller tests passed.")
		quit(0)
	else:
		push_error("Board animation controller tests failed: %d" % _failures)
		quit(1)


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

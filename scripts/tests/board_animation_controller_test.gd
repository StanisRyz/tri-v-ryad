extends SceneTree

const REQUEST_SCRIPT := "res://scripts/game/presentation/board_animation_request.gd"
const SEQUENCE_SCRIPT := "res://scripts/game/presentation/board_animation_sequence.gd"
const CONTROLLER_SCRIPT := "res://scripts/game/view/board_animation_controller.gd"

var _failures := 0
var _callback_count := 0


func _initialize() -> void:
	print("Running board animation controller tests...")
	_run()


func _run() -> void:
	_test_disabled_finishes_immediately()
	_test_empty_sequence_finishes_safely()
	_test_null_board_view_finishes_safely()
	await _test_reduced_motion_shortens_duration_and_calls_once()
	_finish()


func _test_disabled_finishes_immediately() -> void:
	_callback_count = 0
	var controller = load(CONTROLLER_SCRIPT).new()
	controller.configure_settings(false, false)
	controller.play_requests([_request(0.2)], Control.new(), Callable(self, "_on_callback"))
	_expect_equal(_callback_count, 1, "disabled animations call callback")
	_expect_false(controller.is_playing(), "disabled animations do not stay playing")


func _test_empty_sequence_finishes_safely() -> void:
	_callback_count = 0
	var controller = load(CONTROLLER_SCRIPT).new()
	controller.play_sequence(load(SEQUENCE_SCRIPT).new(), Control.new(), Callable(self, "_on_callback"))
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

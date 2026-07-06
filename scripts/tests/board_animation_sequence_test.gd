extends SceneTree

const REQUEST_SCRIPT := "res://scripts/game/presentation/board_animation_request.gd"
const SEQUENCE_SCRIPT := "res://scripts/game/presentation/board_animation_sequence.gd"

var _failures := 0


func _initialize() -> void:
	print("Running board animation sequence tests...")

	var sequence = load(SEQUENCE_SCRIPT).new()
	_expect_true(sequence.is_empty(), "new sequence is empty")
	_expect_equal(sequence.size(), 0, "new sequence size is zero")

	var request = load(REQUEST_SCRIPT).new_request(load(REQUEST_SCRIPT).TYPE_SWAP)
	sequence.add_request(request)
	_expect_false(sequence.is_empty(), "sequence stores request")
	_expect_equal(sequence.size(), 1, "sequence counts request")
	_expect_equal(sequence.get_requests().size(), 1, "sequence returns requests")

	sequence.add_requests([
		load(REQUEST_SCRIPT).new_request(load(REQUEST_SCRIPT).TYPE_MATCH_CLEAR),
		null,
		load(REQUEST_SCRIPT).new(),
	])
	_expect_equal(sequence.size(), 2, "sequence ignores null and invalid requests")

	var exported: Array = sequence.get_requests()
	exported.clear()
	_expect_equal(sequence.size(), 2, "returned request array is duplicated")

	sequence.clear()
	_expect_true(sequence.is_empty(), "sequence clears requests")

	_finish()


func _finish() -> void:
	if _failures == 0:
		print("Board animation sequence tests passed.")
		quit(0)
	else:
		push_error("Board animation sequence tests failed: %d" % _failures)
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

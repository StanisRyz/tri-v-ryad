extends SceneTree

const REQUEST_SCRIPT := "res://scripts/game/presentation/board_animation_request.gd"

var _failures := 0


func _initialize() -> void:
	print("Running board animation request tests...")

	var request = load(REQUEST_SCRIPT).new_request("match_clear")
	request.with_cells([Vector2i(1, 2), Vector2i(2, 2)])
	request.with_swap(Vector2i(0, 0), Vector2i(1, 0))
	request.with_duration(0.25)
	request.with_payload({"damage": 3})

	_expect_true(request.is_valid(), "request with type is valid")
	_expect_equal(request.animation_type, "match_clear", "request stores type")
	_expect_equal(request.cells.size(), 2, "request stores cells")
	_expect_equal(request.from_cell, Vector2i(0, 0), "request stores from cell")
	_expect_equal(request.to_cell, Vector2i(1, 0), "request stores to cell")
	_expect_equal(request.duration, 0.25, "request stores duration")
	_expect_equal(request.payload["damage"], 3, "request stores payload")

	var exported: Dictionary = request.to_dictionary()
	_expect_equal(exported["animation_type"], "match_clear", "request exports type")
	_expect_equal(exported["cells"].size(), 2, "request exports cells")

	var empty_request = load(REQUEST_SCRIPT).new()
	_expect_false(empty_request.is_valid(), "empty request is invalid")

	_finish()


func _finish() -> void:
	if _failures == 0:
		print("Board animation request tests passed.")
		quit(0)
	else:
		push_error("Board animation request tests failed: %d" % _failures)
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

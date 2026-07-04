extends RefCounted
class_name BoardMotionAnimator

signal animation_finished

const SWAP_DURATION := 0.14
const INVALID_DURATION := 0.18
const CLEAR_DURATION := 0.20
const REFILL_DURATION := 0.18
const REFRESH_DURATION := 0.16


func play_valid_swap_feedback(board_view: BoardView, from_cell: Vector2i, to_cell: Vector2i) -> void:
	if board_view != null:
		board_view.play_swap_feedback(from_cell, to_cell)

	await _wait(board_view, SWAP_DURATION)
	animation_finished.emit()


func play_invalid_swap_feedback(board_view: BoardView, from_cell: Vector2i, to_cell: Vector2i) -> void:
	if board_view != null:
		board_view.play_invalid_swap_feedback(from_cell, to_cell)

	await _wait(board_view, INVALID_DURATION)
	animation_finished.emit()


func play_match_clear_feedback(board_view: BoardView, cells: Array[Vector2i]) -> void:
	if board_view != null:
		board_view.play_match_clear_feedback(cells)

	await _wait(board_view, CLEAR_DURATION)
	animation_finished.emit()


func play_refill_feedback(board_view: BoardView, cells: Array[Vector2i] = []) -> void:
	if board_view != null:
		board_view.play_refill_feedback(cells)

	await _wait(board_view, REFILL_DURATION)
	animation_finished.emit()


func play_board_refresh_feedback(board_view: BoardView) -> void:
	if board_view != null:
		board_view.play_refill_feedback()

	await _wait(board_view, REFRESH_DURATION)
	animation_finished.emit()


func _wait(board_view: BoardView, duration: float) -> void:
	if board_view == null or board_view.get_tree() == null:
		return

	await board_view.get_tree().create_timer(duration).timeout

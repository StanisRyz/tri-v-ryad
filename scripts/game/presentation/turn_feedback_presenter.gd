extends RefCounted
class_name TurnFeedbackPresenter

signal feedback_finished

const BOARD_MOTION_ANIMATOR_SCRIPT := preload("res://scripts/game/view/board_motion_animator.gd")
const BATTLE_MESSAGE_FORMATTER_SCRIPT := preload("res://scripts/game/presentation/battle_message_formatter.gd")
const SHORT_DELAY := 0.12
const MEDIUM_DELAY := 0.24
const LONG_DELAY := 0.34
const MINIMAL_DELAY := 0.01

var _board_motion_animator := BOARD_MOTION_ANIMATOR_SCRIPT.new()
var _animations_enabled := true
var _debug_labels_enabled := false


func configure_settings(animations_enabled: bool, reduced_motion_enabled: bool = false, debug_labels_enabled: bool = false) -> void:
	_animations_enabled = animations_enabled
	_debug_labels_enabled = debug_labels_enabled
	_board_motion_animator.configure_settings(animations_enabled, reduced_motion_enabled)


func play_turn_feedback(data, board_view: BoardView, status_callback: Callable) -> void:
	if data.is_valid:
		await _play_valid_feedback(data, board_view, status_callback)
	else:
		await _play_invalid_feedback(data, board_view, status_callback)

	feedback_finished.emit()


func _play_valid_feedback(data, board_view: BoardView, status_callback: Callable) -> void:
	await _board_motion_animator.play_valid_swap_feedback(board_view, data.swapped_from, data.swapped_to)

	board_view.highlight_cells(data.matched_cells)
	await _wait(board_view, SHORT_DELAY)

	await _board_motion_animator.play_match_clear_feedback(board_view, data.matched_cells)
	if not data.special_cleared_cells.is_empty():
		await _board_motion_animator.play_special_clear_feedback(board_view, data.special_cleared_cells, _get_activation_cells(data.activated_special_tiles))
		var special_message := BATTLE_MESSAGE_FORMATTER_SCRIPT.format_special_activation_message(data, _debug_labels_enabled)
		if special_message != "":
			status_callback.call(special_message)
			await _wait(board_view, SHORT_DELAY)

	await _board_motion_animator.play_board_refresh_feedback(board_view)

	board_view.highlight_lanes(data.lane_activations)
	var lane_message := BATTLE_MESSAGE_FORMATTER_SCRIPT.format_lane_activation_message(data.lane_activations)
	if lane_message != "":
		status_callback.call(lane_message)
	await _wait(board_view, SHORT_DELAY)

	status_callback.call(BATTLE_MESSAGE_FORMATTER_SCRIPT.format_damage_message(data, _debug_labels_enabled))
	await _wait(board_view, MEDIUM_DELAY)

	if data.enemy_action.get("acted", false):
		status_callback.call(BATTLE_MESSAGE_FORMATTER_SCRIPT.format_enemy_action_message(data.enemy_action, _debug_labels_enabled))
		await _wait(board_view, LONG_DELAY)

	board_view.clear_lane_highlights()
	board_view.clear_cell_highlights()


func _play_invalid_feedback(data, board_view: BoardView, status_callback: Callable) -> void:
	await _board_motion_animator.play_invalid_swap_feedback(board_view, data.swapped_from, data.swapped_to)
	status_callback.call(BATTLE_MESSAGE_FORMATTER_SCRIPT.format_invalid_swap_message(data.invalid_reason))
	await _wait(board_view, MEDIUM_DELAY)
	board_view.clear_cell_highlights()


func _get_activation_cells(activated_special_tiles: Array[Dictionary]) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for activated_special in activated_special_tiles:
		var cell = activated_special.get("cell", Vector2i(-1, -1))
		if cell is Vector2i:
			cells.append(cell)

	return cells


func _wait(board_view: BoardView, duration: float) -> void:
	if board_view == null or board_view.get_tree() == null:
		return

	var effective_duration := duration if _animations_enabled else MINIMAL_DELAY
	await board_view.get_tree().create_timer(effective_duration).timeout

extends RefCounted
class_name AbilityFeedbackPresenter

signal feedback_finished

const BATTLE_MESSAGE_FORMATTER_SCRIPT := preload("res://scripts/game/presentation/battle_message_formatter.gd")
const SHORT_DELAY := 0.18
const MEDIUM_DELAY := 0.32
const MINIMAL_DELAY := 0.01

var _animations_enabled := true
var _debug_labels_enabled := false
var _localization_manager = null


func configure_settings(animations_enabled: bool, _reduced_motion_enabled: bool = false, debug_labels_enabled: bool = false) -> void:
	_animations_enabled = animations_enabled
	_debug_labels_enabled = debug_labels_enabled


func set_localization_manager(localization_manager) -> void:
	_localization_manager = localization_manager


func play_ability_feedback(data, board_view: BoardView, status_callback: Callable) -> void:
	if data.accepted:
		await _play_accepted_feedback(data, board_view, status_callback)
	else:
		await _play_rejected_feedback(data, board_view, status_callback)

	feedback_finished.emit()


func _play_accepted_feedback(data, board_view: BoardView, status_callback: Callable) -> void:
	status_callback.call(BATTLE_MESSAGE_FORMATTER_SCRIPT.format_ability_start_message(data, _debug_labels_enabled, _localization_manager))
	await _wait(board_view, SHORT_DELAY)

	var damage_message := BATTLE_MESSAGE_FORMATTER_SCRIPT.format_ability_damage_message(data, _debug_labels_enabled, _localization_manager)
	if damage_message != "":
		status_callback.call(damage_message)
		await _wait(board_view, MEDIUM_DELAY)


func _play_rejected_feedback(data, board_view: BoardView, status_callback: Callable) -> void:
	status_callback.call(BATTLE_MESSAGE_FORMATTER_SCRIPT.format_ability_rejected_message(data.reason, _localization_manager))
	await _wait(board_view, SHORT_DELAY)


func _wait(board_view: BoardView, duration: float) -> void:
	if board_view == null or board_view.get_tree() == null:
		return

	var effective_duration := duration if _animations_enabled else MINIMAL_DELAY
	await board_view.get_tree().create_timer(effective_duration).timeout

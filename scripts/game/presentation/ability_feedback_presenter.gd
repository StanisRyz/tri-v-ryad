extends RefCounted
class_name AbilityFeedbackPresenter

signal feedback_finished

const SHORT_DELAY := 0.18
const MEDIUM_DELAY := 0.32
const MINIMAL_DELAY := 0.01

var _animations_enabled := true


func configure_settings(animations_enabled: bool, _reduced_motion_enabled: bool = false) -> void:
	_animations_enabled = animations_enabled


func play_ability_feedback(data, board_view: BoardView, status_callback: Callable) -> void:
	if data.accepted:
		await _play_accepted_feedback(data, board_view, status_callback)
	else:
		await _play_rejected_feedback(data, board_view, status_callback)

	feedback_finished.emit()


func _play_accepted_feedback(data, board_view: BoardView, status_callback: Callable) -> void:
	status_callback.call("%s!" % data.display_name)
	await _wait(board_view, SHORT_DELAY)

	if data.damage_to_enemy > 0:
		status_callback.call("%s dealt %d damage" % [data.display_name, data.damage_to_enemy])
		await _wait(board_view, MEDIUM_DELAY)


func _play_rejected_feedback(data, board_view: BoardView, status_callback: Callable) -> void:
	status_callback.call(_build_rejected_message(data.reason))
	await _wait(board_view, SHORT_DELAY)


func _build_rejected_message(reason: String) -> String:
	match reason:
		"ability_not_ready":
			return "Ability not ready"
		"hero_dead":
			return "Hero is down"
		"battle_finished":
			return "Battle finished"
		_:
			return "Ability unavailable"


func _wait(board_view: BoardView, duration: float) -> void:
	if board_view == null or board_view.get_tree() == null:
		return

	var effective_duration := duration if _animations_enabled else MINIMAL_DELAY
	await board_view.get_tree().create_timer(effective_duration).timeout

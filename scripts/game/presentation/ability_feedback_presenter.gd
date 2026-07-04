extends RefCounted
class_name AbilityFeedbackPresenter

signal feedback_finished

const SHORT_DELAY := 0.18
const MEDIUM_DELAY := 0.32


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

	if not data.healed_heroes.is_empty():
		status_callback.call(_build_heal_message(data))
		await _wait(board_view, MEDIUM_DELAY)

	if not data.cleared_cells.is_empty():
		board_view.highlight_cells(data.cleared_cells)
		board_view.flash_cells(data.cleared_cells)
		status_callback.call("%s cleared a row" % data.display_name)
		await _wait(board_view, MEDIUM_DELAY)
		board_view.clear_cell_highlights()


func _play_rejected_feedback(data, board_view: BoardView, status_callback: Callable) -> void:
	status_callback.call(_build_rejected_message(data.reason))
	await _wait(board_view, SHORT_DELAY)


func _build_heal_message(data) -> String:
	var total_heal := 0
	for event in data.healed_heroes:
		total_heal += event.get("amount", 0) as int
	return "%s healed %d HP" % [data.display_name, total_heal]


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

	await board_view.get_tree().create_timer(duration).timeout

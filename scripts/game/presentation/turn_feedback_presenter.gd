extends RefCounted
class_name TurnFeedbackPresenter

signal feedback_finished

const SHORT_DELAY := 0.12
const MEDIUM_DELAY := 0.24
const LONG_DELAY := 0.34


func play_turn_feedback(data, board_view: BoardView, status_callback: Callable) -> void:
	if data.is_valid:
		await _play_valid_feedback(data, board_view, status_callback)
	else:
		await _play_invalid_feedback(data, board_view, status_callback)

	feedback_finished.emit()


func _play_valid_feedback(data, board_view: BoardView, status_callback: Callable) -> void:
	board_view.flash_cells(board_view.get_valid_cells_from_pair(data.swapped_from, data.swapped_to))
	await _wait(board_view, SHORT_DELAY)

	board_view.highlight_cells(data.matched_cells)
	board_view.flash_cells(data.matched_cells)
	status_callback.call(_build_damage_message(data))
	await _wait(board_view, MEDIUM_DELAY)

	board_view.highlight_lanes(data.lane_activations)
	await _wait(board_view, SHORT_DELAY)

	if data.enemy_action.get("acted", false):
		status_callback.call(_build_enemy_action_message(data.enemy_action))
		await _wait(board_view, LONG_DELAY)

	board_view.clear_cell_highlights()


func _play_invalid_feedback(data, board_view: BoardView, status_callback: Callable) -> void:
	board_view.flash_invalid_cells(board_view.get_valid_cells_from_pair(data.swapped_from, data.swapped_to))
	status_callback.call(_build_invalid_message(data.invalid_reason))
	await _wait(board_view, MEDIUM_DELAY)
	board_view.clear_cell_highlights()


func _build_damage_message(data) -> String:
	if data.total_damage_to_enemy <= 0:
		return "Turn resolved"

	var first_event := _get_first_damage_event(data.damage_events)
	if first_event.is_empty():
		return "Heroes dealt %d damage" % data.total_damage_to_enemy

	if data.damage_events.size() > 1:
		return "Heroes dealt %d damage" % data.total_damage_to_enemy

	return "%s dealt %d damage" % [_format_hero_id(first_event.get("hero_id", "Hero")), first_event.get("damage", 0)]


func _build_enemy_action_message(enemy_action: Dictionary) -> String:
	return "Enemy attacked %s for %d" % [
		_format_hero_id(enemy_action.get("target_hero_id", "Hero")),
		enemy_action.get("damage", 0),
	]


func _build_invalid_message(reason: String) -> String:
	return "No match" if reason == "no_match" else "Invalid swap"


func _get_first_damage_event(events: Array[Dictionary]) -> Dictionary:
	for event in events:
		if event.get("damage", 0) > 0:
			return event

	return {}


func _format_hero_id(hero_id: String) -> String:
	match hero_id:
		"hero_1":
			return "Hero 1"
		"hero_2":
			return "Hero 2"
		"hero_3":
			return "Hero 3"
		_:
			return hero_id.capitalize()


func _wait(board_view: BoardView, duration: float) -> void:
	if board_view == null or board_view.get_tree() == null:
		return

	await board_view.get_tree().create_timer(duration).timeout

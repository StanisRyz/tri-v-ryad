extends RefCounted
class_name BoardAnimationController

const REQUEST_SCRIPT := preload("res://scripts/game/presentation/board_animation_request.gd")
const SEQUENCE_SCRIPT := preload("res://scripts/game/presentation/board_animation_sequence.gd")
const MINIMAL_DURATION := 0.01
const REDUCED_MOTION_SCALE := 0.35

var _animations_enabled := true
var _reduced_motion_enabled := false
var _playing := false
var _playback_generation := 0
var last_effective_duration := 0.0


func configure_settings(animations_enabled: bool, reduced_motion_enabled: bool) -> void:
	_animations_enabled = animations_enabled
	_reduced_motion_enabled = reduced_motion_enabled


func is_playing() -> bool:
	return _playing


func clear_queue() -> void:
	_playback_generation += 1
	_playing = false


func play_sequence(sequence, board_view: Control, finished_callback: Callable = Callable()) -> void:
	if sequence == null or not sequence.has_method("get_requests"):
		_finish_immediately(finished_callback)
		return

	play_requests(sequence.get_requests(), board_view, finished_callback)


func play_requests(requests: Array, board_view: Control, finished_callback: Callable = Callable()) -> void:
	if not _animations_enabled:
		_finish_immediately(finished_callback)
		return
	if requests.is_empty():
		_finish_immediately(finished_callback)
		return
	if board_view == null or board_view.get_tree() == null:
		_finish_immediately(finished_callback)
		return

	_playback_generation += 1
	var generation := _playback_generation
	_playing = true
	_play_requests_async(requests.duplicate(), board_view, finished_callback, generation)


func _play_requests_async(requests: Array, board_view: Control, finished_callback: Callable, generation: int) -> void:
	for request in requests:
		if generation != _playback_generation:
			return
		if request == null or not request.has_method("is_valid"):
			continue
		if not request.is_valid():
			continue

		_apply_placeholder_request(request, board_view)
		var effective_duration := _get_effective_duration(request.duration)
		last_effective_duration = effective_duration
		await board_view.get_tree().create_timer(effective_duration).timeout

	if generation != _playback_generation:
		return

	_playing = false
	_call_finished(finished_callback)


func _apply_placeholder_request(request, board_view: Control) -> void:
	match request.animation_type:
		REQUEST_SCRIPT.TYPE_SWAP:
			if board_view.has_method("pulse_cells"):
				board_view.pulse_cells(_get_swap_cells(request), request.duration)
			elif board_view.has_method("play_swap_feedback"):
				board_view.play_swap_feedback(request.from_cell, request.to_cell)
		REQUEST_SCRIPT.TYPE_INVALID_SWAP:
			if board_view.has_method("play_invalid_swap_feedback"):
				board_view.play_invalid_swap_feedback(request.from_cell, request.to_cell)
			elif board_view.has_method("flash_cells"):
				board_view.flash_cells(_get_swap_cells(request), request.duration)
		REQUEST_SCRIPT.TYPE_MATCH_CLEAR:
			if board_view.has_method("flash_cells"):
				board_view.flash_cells(request.cells, request.duration)
		REQUEST_SCRIPT.TYPE_SPECIAL_CLEAR:
			if board_view.has_method("pulse_cells"):
				board_view.pulse_cells(request.cells, request.duration)
		REQUEST_SCRIPT.TYPE_BOOSTER_CLEAR:
			if board_view.has_method("flash_cells"):
				board_view.flash_cells(request.cells, request.duration)
		REQUEST_SCRIPT.TYPE_REFILL:
			if board_view.has_method("pulse_cells"):
				board_view.pulse_cells(request.cells, request.duration)
		_:
			if board_view.has_method("flash_cells"):
				board_view.flash_cells(request.cells, request.duration)


func _get_swap_cells(request) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	cells.append(request.from_cell)
	if request.to_cell != request.from_cell:
		cells.append(request.to_cell)
	return cells


func _get_effective_duration(duration: float) -> float:
	var safe_duration: float = maxf(duration, MINIMAL_DURATION)
	if _reduced_motion_enabled:
		return maxf(safe_duration * REDUCED_MOTION_SCALE, MINIMAL_DURATION)
	return safe_duration


func _finish_immediately(finished_callback: Callable) -> void:
	_playback_generation += 1
	_playing = false
	last_effective_duration = 0.0
	_call_finished(finished_callback)


func _call_finished(finished_callback: Callable) -> void:
	if finished_callback.is_valid():
		finished_callback.call()

extends RefCounted
class_name BoardAnimationController

const REQUEST_SCRIPT := preload("res://scripts/game/presentation/board_animation_request.gd")
const SEQUENCE_SCRIPT := preload("res://scripts/game/presentation/board_animation_sequence.gd")
const SPECIAL_TILE_TYPE_SCRIPT := preload("res://scripts/game/board/special_tile_type.gd")
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

		var effective_duration := _get_effective_duration(request.duration)
		last_effective_duration = effective_duration
		_play_request(request, board_view, effective_duration)
		await board_view.get_tree().create_timer(effective_duration).timeout

		if request.animation_type == REQUEST_SCRIPT.TYPE_SWAP and board_view.has_method("finalize_pending_overlay_swap"):
			board_view.finalize_pending_overlay_swap()

	if generation != _playback_generation:
		return

	_playing = false
	_call_finished(finished_callback)


func _play_request(request, board_view: Control, effective_duration: float) -> void:
	match request.animation_type:
		REQUEST_SCRIPT.TYPE_SWAP:
			_play_swap_request(request, board_view, effective_duration)
		REQUEST_SCRIPT.TYPE_INVALID_SWAP:
			_play_invalid_swap_request(request, board_view, effective_duration)
		REQUEST_SCRIPT.TYPE_MATCH_CLEAR:
			_play_match_clear_request(request, board_view, effective_duration)
		REQUEST_SCRIPT.TYPE_SPECIAL_CLEAR:
			_play_special_clear_request(request, board_view, effective_duration)
		REQUEST_SCRIPT.TYPE_SPECIAL_ACTIVATION:
			_play_special_activation_request(request, board_view, effective_duration)
		REQUEST_SCRIPT.TYPE_SPECIAL_CREATE:
			_play_special_create_request(request, board_view, effective_duration)
		REQUEST_SCRIPT.TYPE_BOOSTER_ACTIVATION:
			_play_booster_activation_request(request, board_view, effective_duration)
		REQUEST_SCRIPT.TYPE_BOOSTER_CLEAR:
			_play_booster_clear_request(request, board_view, effective_duration)
		REQUEST_SCRIPT.TYPE_GRAVITY_FALL:
			if board_view.has_method("play_gravity_fall_animation"):
				board_view.play_gravity_fall_animation(request.payload.get("movements", []), effective_duration)
		REQUEST_SCRIPT.TYPE_REFILL:
			if board_view.has_method("play_refill_animation"):
				board_view.play_refill_animation(request.payload.get("refill_cells", []), effective_duration)
			elif board_view.has_method("pulse_cells"):
				board_view.pulse_cells(request.cells, effective_duration)
		REQUEST_SCRIPT.TYPE_CASCADE_STEP:
			if board_view.has_method("play_cascade_step_animation"):
				board_view.play_cascade_step_animation(request.payload, effective_duration)
			elif board_view.has_method("flash_cells"):
				board_view.flash_cells(request.cells, effective_duration)
		_:
			if board_view.has_method("flash_cells"):
				board_view.flash_cells(request.cells, effective_duration)


func _play_swap_request(request, board_view: Control, effective_duration: float) -> void:
	if board_view.has_method("play_swap_animation"):
		board_view.play_swap_animation(request.from_cell, request.to_cell, effective_duration)
	elif board_view.has_method("pulse_cells"):
		board_view.pulse_cells(_get_swap_cells(request), effective_duration)


func _play_invalid_swap_request(request, board_view: Control, effective_duration: float) -> void:
	if board_view.has_method("play_invalid_swap_animation"):
		board_view.play_invalid_swap_animation(request.from_cell, request.to_cell, effective_duration)
	elif board_view.has_method("play_invalid_swap_feedback"):
		board_view.play_invalid_swap_feedback(request.from_cell, request.to_cell)


func _play_match_clear_request(request, board_view: Control, effective_duration: float) -> void:
	if board_view.has_method("play_match_clear_animation"):
		board_view.play_match_clear_animation(request.cells, effective_duration)
	elif board_view.has_method("flash_cells"):
		board_view.flash_cells(request.cells, effective_duration)


func _play_special_clear_request(request, board_view: Control, effective_duration: float) -> void:
	if board_view.has_method("play_special_clear_animation"):
		board_view.play_special_clear_animation(request.cells, effective_duration)
	elif board_view.has_method("pulse_cells"):
		board_view.pulse_cells(request.cells, effective_duration)


func _play_special_activation_request(request, board_view: Control, effective_duration: float) -> void:
	var cell: Vector2i = request.payload.get("cell", Vector2i(-1, -1))
	var special_type: int = int(request.payload.get("special_type", SPECIAL_TILE_TYPE_SCRIPT.NONE))
	var affected_cells: Array[Vector2i] = _to_vector2i_array(request.payload.get("affected_cells", request.cells))
	if affected_cells.is_empty():
		affected_cells = request.cells.duplicate()

	match special_type:
		SPECIAL_TILE_TYPE_SCRIPT.LINE_HORIZONTAL:
			if board_view.has_method("play_horizontal_line_special_activation"):
				board_view.play_horizontal_line_special_activation(cell, affected_cells, effective_duration)
			else:
				_play_special_clear_request(request, board_view, effective_duration)
		SPECIAL_TILE_TYPE_SCRIPT.LINE_VERTICAL:
			if board_view.has_method("play_vertical_line_special_activation"):
				board_view.play_vertical_line_special_activation(cell, affected_cells, effective_duration)
			else:
				_play_special_clear_request(request, board_view, effective_duration)
		SPECIAL_TILE_TYPE_SCRIPT.COLOR_BOMB:
			if board_view.has_method("play_color_bomb_special_activation"):
				board_view.play_color_bomb_special_activation(cell, affected_cells, int(request.payload.get("base_tile_type", BoardModel.EMPTY)), effective_duration)
			else:
				_play_special_clear_request(request, board_view, effective_duration)
		_:
			_play_special_clear_request(request, board_view, effective_duration)


func _play_special_create_request(request, board_view: Control, effective_duration: float) -> void:
	if board_view.has_method("play_special_create_animation"):
		board_view.play_special_create_animation(request.payload.get("created_special_tiles", []), effective_duration)
	elif board_view.has_method("pulse_cells"):
		board_view.pulse_cells(request.cells, effective_duration)


func _play_booster_clear_request(request, board_view: Control, effective_duration: float) -> void:
	if board_view.has_method("play_booster_clear_animation"):
		board_view.play_booster_clear_animation(request.cells, effective_duration)
	elif board_view.has_method("flash_cells"):
		board_view.flash_cells(request.cells, effective_duration)


func _play_booster_activation_request(request, board_view: Control, effective_duration: float) -> void:
	if board_view.has_method("play_booster_activation_animation"):
		board_view.play_booster_activation_animation(
			String(request.payload.get("booster_id", "")),
			request.payload.get("target_cell", Vector2i(-1, -1)),
			request.cells,
			request.payload.get("affected_tile_types", []),
			effective_duration
		)
	elif board_view.has_method("pulse_cells"):
		board_view.pulse_cells(request.cells, effective_duration)


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


func _to_vector2i_array(values: Array) -> Array[Vector2i]:
	var typed_values: Array[Vector2i] = []
	for value in values:
		if value is Vector2i:
			typed_values.append(value as Vector2i)
	return typed_values


func _finish_immediately(finished_callback: Callable) -> void:
	_playback_generation += 1
	_playing = false
	last_effective_duration = 0.0
	_call_finished(finished_callback)


func _call_finished(finished_callback: Callable) -> void:
	if finished_callback.is_valid():
		finished_callback.call()

extends Control
class_name BoardView

signal tile_pressed(cell: Vector2i)
signal tile_drag_released(cell: Vector2i, drag_delta: Vector2)

const TILE_VIEW_SCENE := preload("res://scenes/game/TileView.tscn")
const SPECIAL_TILE_DATA_SCRIPT := preload("res://scripts/game/board/special_tile_data.gd")
const SPECIAL_TILE_TYPE_SCRIPT := preload("res://scripts/game/board/special_tile_type.gd")
const ASSET_KEY_RESOLVER_SCRIPT := preload("res://scripts/game/config/asset_key_resolver.gd")
const GAME_ASSET_CATALOG := preload("res://scripts/game/config/game_asset_catalog.gd")
const BOARD_SIZE := 9
const LANE_WIDTH := 3
const DEFAULT_BOARD_SIZE := 664.0

@onready var tile_grid: GridContainer = %TileGrid
@onready var animation_layer: Control = %AnimationLayer

var _board: BoardModel
var _tile_views: Dictionary = {}
var _selected_cell := Vector2i(-1, -1)
var _lane_activations: Dictionary = {}
var _highlighted_cells: Array[Vector2i] = []
var _invalid_feedback_cells: Array[Vector2i] = []
var _hidden_animation_cells: Array[Vector2i] = []
var _active_board_animation_tween: Tween
var _overlay_mode := false
var _overlay_ghosts: Dictionary = {}
var _overlay_snapshot: BoardVisualSnapshot


func _ready() -> void:
	custom_minimum_size = Vector2(DEFAULT_BOARD_SIZE, DEFAULT_BOARD_SIZE)
	tile_grid.columns = BOARD_SIZE
	_create_tiles()
	_update_grid_rect()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_update_grid_rect()
		queue_redraw()


func set_board(board: BoardModel) -> void:
	if _overlay_mode:
		exit_animation_overlay_mode()
	restore_hidden_tile_visuals()
	clear_animation_layer()
	_board = board
	refresh_all_tiles()


func refresh_all_tiles() -> void:
	if _board == null:
		return

	for cell in _board.get_all_cells():
		var tile := _tile_views.get(cell) as TileView
		if tile != null:
			tile.set_tile(cell, _board.get_tile(cell))
			tile.set_special_tile(_board.get_special_tile(cell))
			tile.set_selected(cell == _selected_cell)
			tile.set_highlighted(cell in _highlighted_cells)
			tile.set_invalid_feedback(cell in _invalid_feedback_cells)


func set_selected_cell(cell: Vector2i) -> void:
	_selected_cell = cell
	refresh_all_tiles()


func clear_selected_cell() -> void:
	_selected_cell = Vector2i(-1, -1)
	refresh_all_tiles()


func highlight_lanes(lane_activations: Dictionary) -> void:
	_lane_activations = lane_activations.duplicate()
	queue_redraw()


func clear_lane_highlights() -> void:
	_lane_activations.clear()
	queue_redraw()


func highlight_cells(cells: Array[Vector2i]) -> void:
	_highlighted_cells = cells.duplicate()
	_invalid_feedback_cells.clear()
	refresh_all_tiles()


func clear_cell_highlights() -> void:
	_highlighted_cells.clear()
	_invalid_feedback_cells.clear()
	refresh_all_tiles()


func flash_cells(cells: Array[Vector2i], _duration: float = 0.08) -> void:
	for cell in cells:
		var tile := get_tile_view(cell)
		if tile != null:
			tile.play_flash()


func flash_invalid_cells(cells: Array[Vector2i]) -> void:
	_invalid_feedback_cells = cells.duplicate()
	_highlighted_cells.clear()
	refresh_all_tiles()
	for cell in cells:
		var tile := _tile_views.get(cell) as TileView
		if tile != null:
			tile.play_invalid_flash()


func get_tile_view(cell: Vector2i) -> TileView:
	return _tile_views.get(cell) as TileView


func get_cell_global_center(cell: Vector2i) -> Vector2:
	var tile := get_tile_view(cell)
	if tile == null:
		return Vector2.ZERO

	return tile.global_position + tile.size * 0.5


func get_tile_views(cells: Array[Vector2i]) -> Array:
	var views := []
	for cell in cells:
		var tile := get_tile_view(cell)
		if tile != null:
			views.append(tile)
	return views


func pulse_cells(cells: Array[Vector2i], _duration: float = 0.08) -> void:
	for tile in get_tile_views(cells):
		tile.play_swap_pulse()


func get_animation_layer() -> Control:
	return animation_layer


func clear_animation_layer() -> void:
	_overlay_ghosts.clear()
	if animation_layer == null:
		return

	for child in animation_layer.get_children():
		child.free()


func restore_hidden_tile_visuals() -> void:
	show_tile_visuals(_hidden_animation_cells)
	_hidden_animation_cells.clear()


func cancel_active_board_animation() -> void:
	if _active_board_animation_tween != null:
		_active_board_animation_tween.kill()
		_active_board_animation_tween = null
	if _overlay_mode:
		return
	restore_hidden_tile_visuals()
	clear_animation_layer()


func is_animation_overlay_mode() -> bool:
	return _overlay_mode


func hide_real_board_tiles() -> void:
	for cell in _tile_views.keys():
		hide_tile_visual(cell)


func show_real_board_tiles() -> void:
	restore_hidden_tile_visuals()


func enter_animation_overlay_mode(snapshot: BoardVisualSnapshot) -> void:
	if snapshot == null or snapshot.is_empty() or animation_layer == null:
		return

	if _overlay_mode:
		exit_animation_overlay_mode()

	_overlay_mode = true
	_overlay_snapshot = snapshot
	hide_real_board_tiles()
	build_full_board_ghosts(snapshot)


func exit_animation_overlay_mode() -> void:
	if not _overlay_mode:
		return

	_overlay_mode = false
	_overlay_snapshot = null
	if _active_board_animation_tween != null:
		_active_board_animation_tween.kill()
		_active_board_animation_tween = null
	clear_animation_layer()
	show_real_board_tiles()


## Seamless final-board handoff: updates the real (currently hidden) TileView
## data to the resolved board while overlay ghosts are still covering the
## board, then exits overlay mode so the real board is already showing the
## correct final state the instant it becomes visible. This avoids a frame
## where the real board is shown with its stale pre-turn data (or blank)
## before refresh_all_tiles() catches up.
func apply_board_under_overlay(board: BoardModel) -> void:
	if not _overlay_mode:
		set_board(board)
		return

	_board = board
	refresh_all_tiles()
	exit_animation_overlay_mode()


func build_full_board_ghosts(snapshot: BoardVisualSnapshot) -> void:
	_overlay_ghosts.clear()
	if animation_layer == null or snapshot == null:
		return

	for cell in snapshot.get_cells():
		var data := snapshot.get_cell_data(cell)
		var ghost := create_tile_ghost_from_data(
			data.get("tile_type", BoardModel.EMPTY),
			data.get("special_data"),
			data.get("local_position", Vector2.ZERO),
			data.get("size", Vector2(48, 48))
		)
		if ghost != null:
			_overlay_ghosts[cell] = ghost


func get_overlay_ghost(cell: Vector2i) -> Control:
	return _get_valid_overlay_ghost(cell)


func force_reset_animation_state() -> void:
	if _active_board_animation_tween != null:
		_active_board_animation_tween.kill()
		_active_board_animation_tween = null

	_overlay_mode = false
	_overlay_snapshot = null
	clear_animation_layer()
	_hidden_animation_cells.clear()

	for tile in _tile_views.values():
		if tile == null:
			continue
		tile.visible = true
		tile.scale = Vector2.ONE
		tile.modulate = Color.WHITE
		tile.position = Vector2.ZERO


func create_tile_ghost(cell: Vector2i) -> Control:
	var tile := get_tile_view(cell)
	if tile == null or animation_layer == null:
		return null

	var ghost := Button.new()
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ghost.focus_mode = Control.FOCUS_NONE
	ghost.disabled = true
	ghost.size = tile.size
	ghost.position = tile.global_position - animation_layer.global_position
	ghost.pivot_offset = tile.size * 0.5
	ghost.icon = tile.icon
	ghost.text = tile.text
	ghost.expand_icon = true
	for state in ["normal", "hover", "pressed", "disabled"]:
		var style = tile.get_theme_stylebox("normal")
		if style != null:
			ghost.add_theme_stylebox_override(state, style.duplicate())
	ghost.add_theme_color_override("font_color", Color.WHITE)
	ghost.add_theme_color_override("font_disabled_color", Color.WHITE)
	ghost.add_theme_font_size_override("font_size", tile.get_theme_font_size("font_size"))
	animation_layer.add_child(ghost)
	return ghost


func create_tile_ghost_from_data(tile_type: int, special_data, ghost_position: Vector2, ghost_size: Vector2) -> Control:
	if animation_layer == null:
		return null

	var ghost := Button.new()
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ghost.focus_mode = Control.FOCUS_NONE
	ghost.disabled = true
	ghost.size = ghost_size
	ghost.position = ghost_position
	ghost.pivot_offset = ghost_size * 0.5
	ghost.expand_icon = true
	ghost.icon = GAME_ASSET_CATALOG.try_load_texture_cached(ASSET_KEY_RESOLVER_SCRIPT.get_tile_asset_key(tile_type))
	var style := StyleBoxFlat.new()
	style.bg_color = TileView.TILE_COLORS.get(tile_type, Color(0.20, 0.22, 0.26, 1.0))
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.05, 0.06, 0.08, 0.8)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	for state in ["normal", "hover", "pressed", "disabled"]:
		ghost.add_theme_stylebox_override(state, style.duplicate())
	ghost.add_theme_color_override("font_color", Color.WHITE)
	ghost.add_theme_color_override("font_disabled_color", Color.WHITE)
	ghost.add_theme_font_size_override("font_size", 22)
	if special_data is SPECIAL_TILE_DATA_SCRIPT:
		ghost.text = SPECIAL_TILE_TYPE_SCRIPT.get_marker_text(special_data.special_type)
	animation_layer.add_child(ghost)
	return ghost


func hide_tile_visual(cell: Vector2i) -> void:
	var tile := get_tile_view(cell)
	if tile != null:
		tile.visible = false
		if not cell in _hidden_animation_cells:
			_hidden_animation_cells.append(cell)


func show_tile_visual(cell: Vector2i) -> void:
	var tile := get_tile_view(cell)
	if tile != null:
		tile.visible = true


func show_tile_visuals(cells: Array[Vector2i]) -> void:
	for cell in cells:
		show_tile_visual(cell)
	_hidden_animation_cells = _hidden_animation_cells.filter(func(hidden_cell: Vector2i) -> bool:
		return not hidden_cell in cells
	)


func play_swap_animation(from_cell: Vector2i, to_cell: Vector2i, duration: float) -> void:
	var cells := get_valid_cells_from_pair(from_cell, to_cell)
	if cells.size() != 2 or animation_layer == null:
		restore_hidden_tile_visuals()
		play_swap_feedback(from_cell, to_cell)
		return

	if _overlay_mode and _get_valid_overlay_ghost(from_cell) != null and _get_valid_overlay_ghost(to_cell) != null:
		_play_overlay_swap(from_cell, to_cell, duration)
		return

	cancel_active_board_animation()
	var from_tile := get_tile_view(from_cell)
	var to_tile := get_tile_view(to_cell)
	if from_tile == null or to_tile == null:
		restore_hidden_tile_visuals()
		play_swap_feedback(from_cell, to_cell)
		return

	var from_position: Vector2 = from_tile.global_position - animation_layer.global_position
	var to_position: Vector2 = to_tile.global_position - animation_layer.global_position
	var from_ghost := create_tile_ghost(from_cell)
	var to_ghost := create_tile_ghost(to_cell)
	if from_ghost == null or to_ghost == null:
		restore_hidden_tile_visuals()
		clear_animation_layer()
		play_swap_feedback(from_cell, to_cell)
		return

	from_ghost.position = from_position
	to_ghost.position = to_position
	hide_tile_visual(from_cell)
	hide_tile_visual(to_cell)
	_active_board_animation_tween = create_tween()
	_active_board_animation_tween.tween_property(from_ghost, "position", to_position, duration)
	_active_board_animation_tween.parallel().tween_property(to_ghost, "position", from_position, duration)
	_active_board_animation_tween.finished.connect(func() -> void:
		_active_board_animation_tween = null
		restore_hidden_tile_visuals()
		clear_animation_layer()
	)


func _play_overlay_swap(from_cell: Vector2i, to_cell: Vector2i, duration: float) -> void:
	if _active_board_animation_tween != null:
		_active_board_animation_tween.kill()
		_active_board_animation_tween = null

	var from_ghost := _get_valid_overlay_ghost(from_cell)
	var to_ghost := _get_valid_overlay_ghost(to_cell)
	if from_ghost == null or to_ghost == null:
		return
	var from_position: Vector2 = from_ghost.position
	var to_position: Vector2 = to_ghost.position

	# The board model is already post-swap by the time this animation plays,
	# so _overlay_ghosts must flip to the new cell identities immediately
	# (not in tween.finished) or a match-clear request queued right after can
	# read the stale pre-swap mapping and fade the wrong ghost. See Stage 46
	# hotfix notes.
	_swap_overlay_ghost_mapping(from_cell, to_cell)

	_active_board_animation_tween = create_tween()
	_active_board_animation_tween.tween_property(from_ghost, "position", to_position, duration)
	_active_board_animation_tween.parallel().tween_property(to_ghost, "position", from_position, duration)
	_active_board_animation_tween.finished.connect(func() -> void:
		_active_board_animation_tween = null
		_finalize_overlay_swap(from_cell, to_cell)
	)


## Flips which ghost is considered "at" from_cell/to_cell so overlay lookups
## reflect the post-swap board identity as soon as the swap begins, rather
## than only once the tween finishes.
func _swap_overlay_ghost_mapping(from_cell: Vector2i, to_cell: Vector2i) -> void:
	if not _overlay_mode:
		return

	var from_ghost := _get_valid_overlay_ghost(from_cell)
	var to_ghost := _get_valid_overlay_ghost(to_cell)

	if to_ghost != null:
		_overlay_ghosts[from_cell] = to_ghost
	else:
		_overlay_ghosts.erase(from_cell)

	if from_ghost != null:
		_overlay_ghosts[to_cell] = from_ghost
	else:
		_overlay_ghosts.erase(to_cell)


## Called when the swap tween completes; the mapping was already flipped in
## _swap_overlay_ghost_mapping, so this only prunes ghosts that were freed or
## invalidated (e.g. overlay mode cancelled mid-tween) while it was running.
func _finalize_overlay_swap(from_cell: Vector2i, to_cell: Vector2i) -> void:
	if not _overlay_mode:
		return

	if _get_valid_overlay_ghost(from_cell) == null:
		_overlay_ghosts.erase(from_cell)
	if _get_valid_overlay_ghost(to_cell) == null:
		_overlay_ghosts.erase(to_cell)


func finalize_pending_overlay_swap() -> void:
	if _active_board_animation_tween != null:
		_active_board_animation_tween.kill()
		_active_board_animation_tween = null


func _get_valid_overlay_ghost(cell: Vector2i) -> Control:
	var ghost = _overlay_ghosts.get(cell)
	if ghost == null:
		return null
	if not is_instance_valid(ghost):
		_overlay_ghosts.erase(cell)
		return null
	return ghost as Control


func _play_overlay_fade(cells: Array[Vector2i], duration: float) -> void:
	var step_duration := maxf(duration, 0.01)
	for cell in cells:
		var ghost := _get_valid_overlay_ghost(cell)
		if ghost == null:
			continue
		var tween := create_tween()
		tween.tween_property(ghost, "modulate:a", 0.0, step_duration)
		tween.tween_callback(func() -> void:
			if is_instance_valid(ghost) and _overlay_ghosts.get(cell) == ghost:
				_overlay_ghosts.erase(cell)
			if is_instance_valid(ghost):
				ghost.free()
		)


func _play_overlay_refill(refill_cells: Array, duration: float) -> void:
	var cell_size: float = _get_board_rect().size.x / float(BOARD_SIZE)
	var safe_duration := maxf(duration, 0.01)
	for refill_item in refill_cells:
		var refill_data := refill_item as Dictionary
		var to_cell: Vector2i = refill_data.get("to", Vector2i(-1, -1))
		var existing := _get_valid_overlay_ghost(to_cell)
		if existing != null:
			existing.free()
			_overlay_ghosts.erase(to_cell)

		var reference_tile := get_tile_view(to_cell)
		var to_size: Vector2 = reference_tile.size if reference_tile != null else Vector2(cell_size, cell_size)
		var to_position: Vector2
		if _overlay_snapshot != null and _overlay_snapshot.has_cell(to_cell):
			to_position = _overlay_snapshot.get_cell_data(to_cell).get("local_position", Vector2.ZERO)
		elif reference_tile != null and animation_layer != null:
			to_position = reference_tile.global_position - animation_layer.global_position
		else:
			continue

		# Match the non-overlay play_refill_animation() start position so
		# refill crystals fall in from above the board instead of appearing
		# directly in their target cell.
		var spawn_index: int = int(refill_data.get("spawn_index", 0))
		var start_position: Vector2 = to_position - Vector2(0, cell_size * float(spawn_index + 1))

		var ghost := create_tile_ghost_from_data(refill_data.get("tile_type", BoardModel.EMPTY), refill_data.get("special_data"), start_position, to_size)
		if ghost == null:
			continue

		ghost.modulate = Color(1.0, 1.0, 1.0, 0.0)
		_overlay_ghosts[to_cell] = ghost
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(ghost, "position", to_position, safe_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(ghost, "modulate", Color.WHITE, minf(safe_duration, 0.12))


func _play_overlay_gravity_fall(movements: Array, duration: float) -> void:
	var max_distance := 1
	for movement in movements:
		max_distance = maxi(max_distance, int((movement as Dictionary).get("fall_distance", 1)))

	var tween := create_tween()
	tween.set_parallel(true)
	var animated := false

	for movement in movements:
		var movement_data := movement as Dictionary
		var from_cell: Vector2i = movement_data.get("from", Vector2i(-1, -1))
		var to_cell: Vector2i = movement_data.get("to", Vector2i(-1, -1))
		var ghost := _get_valid_overlay_ghost(from_cell)
		var to_tile := get_tile_view(to_cell)
		if ghost == null or to_tile == null:
			continue

		var to_position: Vector2 = to_tile.global_position - animation_layer.global_position
		var distance_ratio: float = float(movement_data.get("fall_distance", 1)) / float(max_distance)
		var movement_duration := duration * clampf(0.6 + 0.4 * distance_ratio, 0.6, 1.0)
		tween.tween_property(ghost, "position", to_position, movement_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		_overlay_ghosts.erase(from_cell)
		_overlay_ghosts[to_cell] = ghost
		animated = true

	if not animated:
		tween.kill()


func play_gravity_fall_animation(movements: Array, duration: float) -> void:
	if movements.is_empty() or animation_layer == null:
		return

	if _overlay_mode:
		_play_overlay_gravity_fall(movements, duration)
		return

	cancel_active_board_animation()
	var ghosts: Array[Control] = []
	var targets: Array[Vector2] = []
	var durations: Array[float] = []
	var max_distance := 1
	for movement in movements:
		max_distance = maxi(max_distance, int((movement as Dictionary).get("fall_distance", 1)))

	for movement in movements:
		var movement_data := movement as Dictionary
		var from_cell: Vector2i = movement_data.get("from", Vector2i(-1, -1))
		var to_cell: Vector2i = movement_data.get("to", Vector2i(-1, -1))
		var from_tile := get_tile_view(from_cell)
		var to_tile := get_tile_view(to_cell)
		if from_tile == null or to_tile == null:
			continue

		var from_position: Vector2 = from_tile.global_position - animation_layer.global_position
		var to_position: Vector2 = to_tile.global_position - animation_layer.global_position
		var ghost := create_tile_ghost_from_data(movement_data.get("tile_type", BoardModel.EMPTY), movement_data.get("special_data"), from_position, from_tile.size)
		if ghost == null:
			continue

		var distance_ratio: float = float(movement_data.get("fall_distance", 1)) / float(max_distance)
		ghosts.append(ghost)
		targets.append(to_position)
		durations.append(duration * clampf(0.6 + 0.4 * distance_ratio, 0.6, 1.0))
		hide_tile_visual(from_cell)
		hide_tile_visual(to_cell)

	if ghosts.is_empty():
		restore_hidden_tile_visuals()
		return

	_active_board_animation_tween = create_tween()
	_active_board_animation_tween.set_parallel(true)
	for index in range(ghosts.size()):
		_active_board_animation_tween.tween_property(ghosts[index], "position", targets[index], durations[index]).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_active_board_animation_tween.finished.connect(func() -> void:
		_active_board_animation_tween = null
		restore_hidden_tile_visuals()
		clear_animation_layer()
	)


func play_refill_animation(refill_cells: Array, duration: float) -> void:
	if _overlay_mode:
		if not refill_cells.is_empty():
			_play_overlay_refill(refill_cells, duration)
		return

	if refill_cells.is_empty() or animation_layer == null:
		return

	cancel_active_board_animation()
	var ghosts: Array[Control] = []
	var targets: Array[Vector2] = []
	var cell_size: float = _get_board_rect().size.x / float(BOARD_SIZE)

	for refill_item in refill_cells:
		var refill_data := refill_item as Dictionary
		var to_cell: Vector2i = refill_data.get("to", Vector2i(-1, -1))
		var to_tile := get_tile_view(to_cell)
		if to_tile == null:
			continue

		var to_position: Vector2 = to_tile.global_position - animation_layer.global_position
		var spawn_index: int = int(refill_data.get("spawn_index", 0))
		var start_position: Vector2 = to_position - Vector2(0, cell_size * float(spawn_index + 1))
		var ghost := create_tile_ghost_from_data(refill_data.get("tile_type", BoardModel.EMPTY), refill_data.get("special_data"), start_position, to_tile.size)
		if ghost == null:
			continue

		ghosts.append(ghost)
		targets.append(to_position)
		hide_tile_visual(to_cell)

	if ghosts.is_empty():
		restore_hidden_tile_visuals()
		return

	_active_board_animation_tween = create_tween()
	_active_board_animation_tween.set_parallel(true)
	for index in range(ghosts.size()):
		_active_board_animation_tween.tween_property(ghosts[index], "position", targets[index], duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_active_board_animation_tween.finished.connect(func() -> void:
		_active_board_animation_tween = null
		restore_hidden_tile_visuals()
		clear_animation_layer()
	)


func play_cascade_step_animation(payload: Dictionary, duration: float) -> void:
	var matched_cells: Array[Vector2i] = []
	for cell in (payload.get("matched_cells", []) as Array):
		matched_cells.append(cell as Vector2i)

	if matched_cells.is_empty():
		return

	if _overlay_mode:
		_play_overlay_fade(matched_cells, maxf(duration, 0.01))
		return

	# Temporary flash only: highlight_cells() would leave _highlighted_cells
	# set after the cascade finishes, since nothing clears it automatically
	# once the flash tween ends. Callers are responsible for clearing
	# highlights once the whole turn/booster flow completes (see
	# GameScreen._on_feedback_finished()).
	for tile in get_tile_views(matched_cells):
		tile.play_flash()


func play_invalid_swap_animation(from_cell: Vector2i, to_cell: Vector2i, duration: float) -> void:
	var cells := get_valid_cells_from_pair(from_cell, to_cell)
	if cells.is_empty():
		return

	_invalid_feedback_cells = cells
	_highlighted_cells.clear()
	refresh_all_tiles()

	if cells.size() == 2 and _overlay_mode and _get_valid_overlay_ghost(from_cell) != null and _get_valid_overlay_ghost(to_cell) != null:
		_play_overlay_invalid_swap(from_cell, to_cell, duration)
		return

	if cells.size() != 2 or animation_layer == null:
		_play_invalid_swap_bounce(cells, from_cell, to_cell, duration)
		return

	cancel_active_board_animation()

	var from_tile := get_tile_view(from_cell)
	var to_tile := get_tile_view(to_cell)
	if from_tile == null or to_tile == null:
		restore_hidden_tile_visuals()
		play_invalid_swap_feedback(from_cell, to_cell)
		return

	var from_position: Vector2 = from_tile.global_position - animation_layer.global_position
	var to_position: Vector2 = to_tile.global_position - animation_layer.global_position
	var from_ghost := create_tile_ghost(from_cell)
	var to_ghost := create_tile_ghost(to_cell)
	if from_ghost == null or to_ghost == null:
		restore_hidden_tile_visuals()
		clear_animation_layer()
		play_invalid_swap_feedback(from_cell, to_cell)
		return

	from_ghost.position = from_position
	to_ghost.position = to_position
	hide_tile_visual(from_cell)
	hide_tile_visual(to_cell)

	var half_duration := maxf(duration * 0.5, 0.01)
	_active_board_animation_tween = create_tween()
	_active_board_animation_tween.tween_property(from_ghost, "position", to_position, half_duration)
	_active_board_animation_tween.parallel().tween_property(to_ghost, "position", from_position, half_duration)
	_active_board_animation_tween.chain().tween_property(from_ghost, "position", from_position, half_duration)
	_active_board_animation_tween.parallel().tween_property(to_ghost, "position", to_position, half_duration)
	_active_board_animation_tween.finished.connect(func() -> void:
		_active_board_animation_tween = null
		restore_hidden_tile_visuals()
		clear_animation_layer()
	)


## Overlay-mode variant of the invalid swap: the two matched full-board
## ghosts already represent from_cell/to_cell, so this animates them to swap
## and back in place without ever touching _overlay_ghosts, since the board
## model does not change on an invalid swap.
func _play_overlay_invalid_swap(from_cell: Vector2i, to_cell: Vector2i, duration: float) -> void:
	if _active_board_animation_tween != null:
		_active_board_animation_tween.kill()
		_active_board_animation_tween = null

	var from_ghost := _get_valid_overlay_ghost(from_cell)
	var to_ghost := _get_valid_overlay_ghost(to_cell)
	if from_ghost == null or to_ghost == null:
		return

	var from_position: Vector2 = from_ghost.position
	var to_position: Vector2 = to_ghost.position
	var half_duration := maxf(duration * 0.5, 0.01)

	_active_board_animation_tween = create_tween()
	_active_board_animation_tween.tween_property(from_ghost, "position", to_position, half_duration)
	_active_board_animation_tween.parallel().tween_property(to_ghost, "position", from_position, half_duration)
	_active_board_animation_tween.chain().tween_property(from_ghost, "position", from_position, half_duration)
	_active_board_animation_tween.parallel().tween_property(to_ghost, "position", to_position, half_duration)
	_active_board_animation_tween.finished.connect(func() -> void:
		_active_board_animation_tween = null
	)


## Fallback bounce used only when a real swap-and-return can't be built (e.g.
## a single-cell invalid input with no valid neighbor).
func _play_invalid_swap_bounce(cells: Array[Vector2i], from_cell: Vector2i, to_cell: Vector2i, duration: float) -> void:
	if animation_layer == null:
		play_invalid_swap_feedback(from_cell, to_cell)
		return

	cancel_active_board_animation()
	var direction := Vector2(to_cell - from_cell)
	if direction.length() <= 0.0:
		direction = Vector2.RIGHT
	direction = direction.normalized()
	var distance := minf(_get_board_rect().size.x / float(BOARD_SIZE) * 0.18, 18.0)
	var offset := direction * distance
	var step_duration := maxf(duration / 3.0, 0.01)
	var ghosts: Array[Control] = []
	for cell in cells:
		var ghost := create_tile_ghost(cell)
		if ghost != null:
			ghosts.append(ghost)
			hide_tile_visual(cell)

	if ghosts.is_empty():
		restore_hidden_tile_visuals()
		play_invalid_swap_feedback(from_cell, to_cell)
		return

	var start_positions: Array[Vector2] = []
	for ghost in ghosts:
		start_positions.append(ghost.position)
	_active_board_animation_tween = create_tween()
	_active_board_animation_tween.set_parallel(true)
	for index in range(ghosts.size()):
		var ghost := ghosts[index]
		var ghost_offset := offset if index == 0 else -offset * 0.35
		_active_board_animation_tween.tween_property(ghost, "position", start_positions[index] + ghost_offset, step_duration)
	_active_board_animation_tween.chain().set_parallel(true)
	for index in range(ghosts.size()):
		_active_board_animation_tween.tween_property(ghosts[index], "position", start_positions[index], step_duration)
	_active_board_animation_tween.finished.connect(func() -> void:
		_active_board_animation_tween = null
		restore_hidden_tile_visuals()
		clear_animation_layer()
	)


func play_match_clear_animation(cells: Array[Vector2i], duration: float) -> void:
	if _overlay_mode:
		_play_overlay_fade(cells, duration)
		return

	for tile in get_tile_views(cells):
		tile.play_match_clear(duration)


func play_special_clear_animation(cells: Array[Vector2i], duration: float) -> void:
	if _overlay_mode:
		_play_overlay_fade(cells, duration)
		return

	# No highlight_cells() here: it would persist _highlighted_cells past the
	# end of this temporary flash. tile.play_special_clear() already flashes
	# each tile directly; callers clear any lingering highlight state via
	# BoardView.clear_cell_highlights() once the whole turn/booster flow ends.
	for tile in get_tile_views(cells):
		tile.play_special_clear(duration)


func play_special_create_animation(created_special_tiles: Array, duration: float) -> void:
	if created_special_tiles.is_empty():
		return

	if _overlay_mode:
		_play_overlay_special_create(created_special_tiles, duration)
		return

	for item in created_special_tiles:
		var data := item as Dictionary
		var cell: Vector2i = data.get("cell", Vector2i(-1, -1))
		var special_type: int = int(data.get("special_type", SPECIAL_TILE_TYPE_SCRIPT.NONE))
		var tile := get_tile_view(cell)
		if tile == null:
			continue

		tile.set_special_tile(SPECIAL_TILE_DATA_SCRIPT.from_type(special_type))
		tile.play_special_flash()


## Overlay-mode special creation: the creation cell's ghost was never faded
## by the match-clear step (see build_clear_sequence(), which now animates
## only step.cleared_cells), so it should already exist here. Update its
## marker and pulse it in place instead of fading anything out.
func _play_overlay_special_create(created_special_tiles: Array, duration: float) -> void:
	var safe_duration := maxf(duration, 0.01)
	for item in created_special_tiles:
		var data := item as Dictionary
		var cell: Vector2i = data.get("cell", Vector2i(-1, -1))
		var special_type: int = int(data.get("special_type", SPECIAL_TILE_TYPE_SCRIPT.NONE))

		var ghost := _get_valid_overlay_ghost(cell)
		if ghost == null:
			ghost = _spawn_fallback_special_ghost(cell)
			if ghost == null:
				continue
			_overlay_ghosts[cell] = ghost

		ghost.text = SPECIAL_TILE_TYPE_SCRIPT.get_marker_text(special_type)

		var base_scale: Vector2 = ghost.scale if ghost.scale != Vector2.ZERO else Vector2.ONE
		var pulse_scale := base_scale * 1.12
		var half_duration := safe_duration * 0.5
		var flash_color := Color(1.35, 1.18, 0.55, 1.0)

		var tween := create_tween()
		tween.tween_property(ghost, "modulate", flash_color, half_duration)
		tween.parallel().tween_property(ghost, "scale", pulse_scale, half_duration)
		tween.chain().tween_property(ghost, "modulate", Color.WHITE, half_duration)
		tween.parallel().tween_property(ghost, "scale", base_scale, half_duration)


## Safety net for _play_overlay_special_create() if the creation-cell ghost
## was somehow already freed/missing; rebuilds one from live board/snapshot
## data so the creation cell is never left visually empty.
func _spawn_fallback_special_ghost(cell: Vector2i) -> Control:
	var cell_size: float = _get_board_rect().size.x / float(BOARD_SIZE)
	var reference_tile := get_tile_view(cell)
	var ghost_size: Vector2 = reference_tile.size if reference_tile != null else Vector2(cell_size, cell_size)
	var ghost_position: Vector2
	if _overlay_snapshot != null and _overlay_snapshot.has_cell(cell):
		ghost_position = _overlay_snapshot.get_cell_data(cell).get("local_position", Vector2.ZERO)
	elif reference_tile != null and animation_layer != null:
		ghost_position = reference_tile.global_position - animation_layer.global_position
	else:
		return null

	var tile_type: int = _board.get_tile(cell) if _board != null else BoardModel.EMPTY
	return create_tile_ghost_from_data(tile_type, null, ghost_position, ghost_size)


func play_swap_feedback(from_cell: Vector2i, to_cell: Vector2i) -> void:
	for tile in get_tile_views(get_valid_cells_from_pair(from_cell, to_cell)):
		tile.play_swap_pulse()


func play_invalid_swap_feedback(from_cell: Vector2i, to_cell: Vector2i) -> void:
	_invalid_feedback_cells = get_valid_cells_from_pair(from_cell, to_cell)
	_highlighted_cells.clear()
	refresh_all_tiles()
	for tile in get_tile_views(_invalid_feedback_cells):
		tile.play_invalid_pulse()


func play_match_clear_feedback(cells: Array[Vector2i]) -> void:
	for tile in get_tile_views(cells):
		tile.play_match_fade()


func play_special_clear_feedback(cells: Array[Vector2i], activation_cells: Array[Vector2i] = []) -> void:
	highlight_cells(cells)
	for tile in get_tile_views(cells):
		tile.play_special_flash()
	for tile in get_tile_views(activation_cells):
		tile.play_special_flash()


func play_refill_feedback(cells: Array[Vector2i] = []) -> void:
	var target_cells: Array[Vector2i] = cells.duplicate()
	if target_cells.is_empty():
		for cell in _tile_views.keys():
			target_cells.append(cell)

	for tile in get_tile_views(target_cells):
		tile.play_refill_appear()


func reset_tile_visuals() -> void:
	cancel_active_board_animation()
	for tile in _tile_views.values():
		if tile != null and tile.has_method("reset_visual_state"):
			tile.reset_visual_state()


func get_valid_cells_from_pair(a: Vector2i, b: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	if _tile_views.has(a):
		cells.append(a)
	if _tile_views.has(b) and b != a:
		cells.append(b)
	return cells


func _draw() -> void:
	var board_rect := _get_board_rect()
	var cell_size := board_rect.size.x / float(BOARD_SIZE)
	var lane_colors := [
		Color(0.12, 0.30, 0.62, 0.24),
		Color(0.10, 0.46, 0.30, 0.24),
		Color(0.56, 0.22, 0.20, 0.24),
	]

	for lane_index in range(3):
		if _lane_activations.get(lane_index, 0) <= 0:
			continue

		var lane_rect := Rect2(
			board_rect.position + Vector2(cell_size * LANE_WIDTH * lane_index, 0.0),
			Vector2(cell_size * LANE_WIDTH, board_rect.size.y)
		)
		var color: Color = lane_colors[lane_index]
		color = color.lightened(0.35)
		color.a = 0.38
		draw_rect(lane_rect, color, true)

	draw_rect(board_rect, Color(1, 1, 1, 0.85), false, 3.0)


func _create_tiles() -> void:
	for child in tile_grid.get_children():
		child.queue_free()

	_tile_views.clear()
	for y in range(BOARD_SIZE):
		for x in range(BOARD_SIZE):
			var cell := Vector2i(x, y)
			var tile := TILE_VIEW_SCENE.instantiate() as TileView
			tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			tile.size_flags_vertical = Control.SIZE_EXPAND_FILL
			tile.tile_pressed.connect(_on_tile_pressed)
			tile.tile_drag_released.connect(_on_tile_drag_released)
			tile_grid.add_child(tile)
			_tile_views[cell] = tile


func _on_tile_pressed(cell: Vector2i) -> void:
	tile_pressed.emit(cell)


func _on_tile_drag_released(cell: Vector2i, drag_delta: Vector2) -> void:
	tile_drag_released.emit(cell, drag_delta)


func _update_grid_rect() -> void:
	if tile_grid == null:
		return

	var board_rect := _get_board_rect()
	tile_grid.position = board_rect.position
	tile_grid.size = board_rect.size
	if animation_layer != null:
		animation_layer.position = board_rect.position
		animation_layer.size = board_rect.size


func _get_board_rect() -> Rect2:
	var board_size: float = minf(size.x, size.y)
	var origin: Vector2 = (size - Vector2.ONE * board_size) * 0.5
	return Rect2(origin, Vector2.ONE * board_size)

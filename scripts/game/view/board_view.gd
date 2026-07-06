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
const BOOSTER_TARGET_PREVIEW_COLOR := Color(1.0, 1.0, 1.0, 0.78)
const BOOSTER_TARGET_PREVIEW_INSET_RATIO := 0.06

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
var _special_activation_tweens: Array[Tween] = []
var _overlay_mode := false
var _overlay_ghosts: Dictionary = {}
var _overlay_snapshot: BoardVisualSnapshot
var _booster_preview_nodes: Array[Control] = []


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


## Stage 55 v0.1: the single choke point that syncs every TileView's active
## state from the board mask (set_cell_active() first, since TileView
## ignores tile/special/selected/highlighted/invalid state entirely while
## inactive). Covers initial render, full refresh, restart/next-level/retry
## (all route through GameScreen -> BattlePresenter.start_level() ->
## board_changed -> set_board()), and the post-overlay handoff in
## apply_board_under_overlay(), which also calls this.
func refresh_all_tiles() -> void:
	if _board == null:
		return

	for cell in _board.get_all_cells():
		var tile := _tile_views.get(cell) as TileView
		if tile != null:
			tile.set_cell_active(_board.is_cell_active(cell))
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


func clear_transient_visual_state() -> void:
	clear_booster_target_preview()
	_selected_cell = Vector2i(-1, -1)
	_lane_activations.clear()
	_highlighted_cells.clear()
	_invalid_feedback_cells.clear()
	queue_redraw()
	for tile in _tile_views.values():
		if tile != null and tile.has_method("clear_transient_feedback_state"):
			tile.clear_transient_feedback_state()
	refresh_all_tiles()


func flash_cells(cells: Array[Vector2i], _duration: float = 0.08) -> void:
	for tile in get_tile_views(cells):
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


## Stage 55 v0.1: filters out inactive cells so every transient-visual caller
## that gathers tiles this way (highlights, match/special/booster clear
## flashes, swap/invalid feedback, refill feedback, cascade flashes) safely
## skips holes without each caller having to remember to filter itself.
func get_tile_views(cells: Array[Vector2i]) -> Array:
	var views := []
	for cell in cells:
		if _board != null and not _board.is_cell_active(cell):
			continue
		var tile := get_tile_view(cell)
		if tile != null:
			views.append(tile)
	return views


func pulse_cells(cells: Array[Vector2i], _duration: float = 0.08) -> void:
	for tile in get_tile_views(cells):
		tile.play_swap_pulse()


func get_visible_tile_type(cell: Vector2i) -> int:
	var tile := get_tile_view(cell)
	if tile != null:
		return tile.tile_type
	if _board != null and _board.is_inside(cell):
		return _board.get_tile(cell)
	return BoardModel.EMPTY


func get_cells_with_visible_tile_type(tile_type: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	if not TileType.is_valid_tile_type(tile_type):
		return cells

	for cell in _tile_views.keys():
		if get_visible_tile_type(cell) == tile_type:
			cells.append(cell)
	return cells


## Stage 55 v0.1: Hammer's 3x3 preview and Rocket's same-color preview both
## route through here, so skipping inactive cells here is enough to keep
## either preview from ever drawing an overlay on a hole, regardless of what
## the caller's cell list contains.
func show_booster_target_preview(cells: Array[Vector2i], _preview_type: String) -> void:
	clear_booster_target_preview()
	if animation_layer == null:
		return

	for cell in cells:
		if _board != null and not _board.is_cell_active(cell):
			continue
		var preview := _create_booster_preview_cell(cell, BOOSTER_TARGET_PREVIEW_COLOR)
		if preview != null:
			_booster_preview_nodes.append(preview)


func clear_booster_target_preview() -> void:
	for preview in _booster_preview_nodes:
		if is_instance_valid(preview):
			preview.free()
	_booster_preview_nodes.clear()


func play_booster_activation_animation(booster_id: String, target_cell: Vector2i, affected_cells: Array[Vector2i], _affected_tile_types: Array, duration: float) -> void:
	clear_booster_target_preview()
	var safe_duration := maxf(duration, 0.01)
	if booster_id == "hammer":
		_play_activation_cell_pulse(target_cell, safe_duration, Color(1.45, 1.18, 0.38, 1.0))
		_play_booster_impact_flash(affected_cells, safe_duration, Color(1.0, 0.86, 0.18, 0.72))
	elif booster_id == "rocket_barrage":
		_play_activation_cell_pulse(target_cell, safe_duration, Color(1.35, 0.60, 0.44, 1.0))
		_play_booster_impact_flash(affected_cells, safe_duration, Color(1.0, 0.46, 0.30, 0.58))
	else:
		pulse_cells(affected_cells, safe_duration)


func get_animation_layer() -> Control:
	return animation_layer


func clear_animation_layer() -> void:
	_overlay_ghosts.clear()
	_booster_preview_nodes.clear()
	_clear_special_activation_tweens()
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
	_clear_special_activation_tweens()
	if _overlay_mode:
		return
	restore_hidden_tile_visuals()
	clear_animation_layer()


func is_animation_overlay_mode() -> bool:
	return _overlay_mode


## Stage 55 v0.1: inactive cells (holes) are never hidden here and never get
## an overlay ghost either (see build_full_board_ghosts()), since gravity
## never targets them (Stage 54.2) — their real TileView already shows the
## correct static "hole" look and simply stays visible underneath/alongside
## the ghost layer for the whole overlay session.
func hide_real_board_tiles() -> void:
	for cell in _tile_views.keys():
		var tile := _tile_views.get(cell) as TileView
		if tile != null and not tile.is_cell_active():
			continue
		hide_tile_visual(cell)


func show_real_board_tiles() -> void:
	restore_hidden_tile_visuals()


func enter_animation_overlay_mode(snapshot: BoardVisualSnapshot) -> void:
	if snapshot == null or snapshot.is_empty() or animation_layer == null:
		return

	if _overlay_mode:
		exit_animation_overlay_mode()

	clear_booster_target_preview()
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
	clear_transient_visual_state()
	refresh_all_tiles()
	exit_animation_overlay_mode()


## Stage 55 v0.1: no ghost is built for an inactive cell — its real TileView
## was left visible by hide_real_board_tiles() and already shows the correct
## hole look, and gravity/refill never target an inactive cell (Stage 54.2)
## so no ghost lookup for that cell is ever needed during the overlay
## session either.
func build_full_board_ghosts(snapshot: BoardVisualSnapshot) -> void:
	_overlay_ghosts.clear()
	if animation_layer == null or snapshot == null:
		return

	for cell in snapshot.get_cells():
		var data := snapshot.get_cell_data(cell)
		if not bool(data.get("is_active", true)):
			continue
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
	_clear_special_activation_tweens()

	_overlay_mode = false
	_overlay_snapshot = null
	clear_booster_target_preview()
	clear_animation_layer()
	_hidden_animation_cells.clear()
	_selected_cell = Vector2i(-1, -1)
	_lane_activations.clear()
	_highlighted_cells.clear()
	_invalid_feedback_cells.clear()
	queue_redraw()

	for tile in _tile_views.values():
		if tile == null:
			continue
		tile.reset_visual_state()
	refresh_all_tiles()


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


## Stage 55 v0.1: GravityResolver never emits a refill_cells entry whose
## "to" is inactive (Stage 54.2), so this is a defensive safety net rather
## than the primary guarantee.
func _play_overlay_refill(refill_cells: Array, duration: float) -> void:
	var cell_size: float = _get_board_rect().size.x / float(BOARD_SIZE)
	var safe_duration := maxf(duration, 0.01)
	for refill_item in refill_cells:
		var refill_data := refill_item as Dictionary
		var to_cell: Vector2i = refill_data.get("to", Vector2i(-1, -1))
		if _board != null and not _board.is_cell_active(to_cell):
			continue
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


## Stage 55 v0.1: a movement whose crosses_inactive_gap metadata (Stage 54.2)
## is true never visibly slides its ghost across the hole — it gets its own
## fade-out/jump/drop-in tween via _animate_overlay_pass_through_fall()
## instead of joining the shared parallel position tween below. Movements
## that don't cross a gap are completely unchanged.
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

		if bool(movement_data.get("crosses_inactive_gap", false)):
			_animate_overlay_pass_through_fall(ghost, to_position, movement_duration)
		else:
			tween.tween_property(ghost, "position", to_position, movement_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

		_overlay_ghosts.erase(from_cell)
		_overlay_ghosts[to_cell] = ghost
		animated = true

	if not animated:
		tween.kill()


## Safe v0.1 pass-through visual: fade the ghost out near the source, jump
## it straight to just above the target (no visible motion over the hole),
## then drop/fade it in at the target. Runs on its own tween (registered
## for cleanup) rather than the shared parallel tween above, since it needs
## its own fade-then-move-then-fade sequence.
func _animate_overlay_pass_through_fall(ghost: Control, to_position: Vector2, duration: float) -> void:
	var fade_out_duration := maxf(duration * 0.3, 0.01)
	var drop_duration := maxf(duration - fade_out_duration, 0.01)
	var drop_start_position := to_position - Vector2(0, ghost.size.y * 0.6)

	var pass_through_tween := create_tween()
	_register_special_activation_tween(pass_through_tween)
	pass_through_tween.tween_property(ghost, "modulate:a", 0.0, fade_out_duration)
	pass_through_tween.tween_callback(func() -> void:
		if is_instance_valid(ghost):
			ghost.position = drop_start_position
	)
	pass_through_tween.tween_property(ghost, "position", to_position, drop_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	pass_through_tween.parallel().tween_property(ghost, "modulate:a", 1.0, minf(drop_duration, 0.12))


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
		if _board != null and not _board.is_cell_active(to_cell):
			continue
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


func play_horizontal_line_special_activation(activation_cell: Vector2i, affected_cells: Array[Vector2i], duration: float) -> void:
	_clear_special_activation_tweens()
	_play_line_special_activation(activation_cell, affected_cells, duration, true)


func play_vertical_line_special_activation(activation_cell: Vector2i, affected_cells: Array[Vector2i], duration: float) -> void:
	_clear_special_activation_tweens()
	_play_line_special_activation(activation_cell, affected_cells, duration, false)


func play_color_bomb_special_activation(activation_cell: Vector2i, affected_cells: Array[Vector2i], base_tile_type: int, duration: float) -> void:
	_clear_special_activation_tweens()
	var safe_duration := maxf(duration, 0.01)
	var sorted_cells := affected_cells.duplicate()
	sorted_cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return a.y < b.y if a.y != b.y else a.x < b.x
	)

	_play_activation_cell_pulse(activation_cell, safe_duration, Color(1.45, 1.20, 0.50, 1.0))
	var highlight_color: Color = TileView.TILE_COLORS.get(base_tile_type, Color(1.0, 0.90, 0.35, 1.0))
	_play_affected_cell_highlights(sorted_cells, safe_duration, highlight_color.lightened(0.22), 0.62)


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


func play_booster_clear_animation(cells: Array[Vector2i], duration: float) -> void:
	if _overlay_mode:
		_play_overlay_fade(cells, duration)
		return

	for tile in get_tile_views(cells):
		tile.play_flash()


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

		# Real TileView nodes inside GridContainer are never moved manually, so
		# outside overlay mode the gathered source crystals just fade in place
		# via their own existing match-clear fade rather than sliding.
		for source_cell in data.get("source_cells", []):
			if source_cell == cell:
				continue
			var source_tile := get_tile_view(source_cell)
			if source_tile != null:
				source_tile.play_match_clear(duration)

		var tile := get_tile_view(cell)
		if tile == null:
			continue

		tile.set_special_tile(SPECIAL_TILE_DATA_SCRIPT.from_type(special_type))
		tile.play_special_flash()


## Overlay-mode special creation: the creation cell's ghost was never faded
## by the match-clear step (see build_clear_sequence(), which excludes both the
## creation cell and its gather-source cells from the plain match clear), so it
## should already exist here. The other matched crystals' ghosts visually
## gather into the creation cell (slide, shrink, fade), then the creation-cell
## ghost's marker updates and pulses/flashes in place.
func _play_overlay_special_create(created_special_tiles: Array, duration: float) -> void:
	var safe_duration := maxf(duration, 0.01)
	var gather_duration := safe_duration * 0.55
	var pulse_duration := maxf(safe_duration - gather_duration, 0.01)

	for item in created_special_tiles:
		var data := item as Dictionary
		var cell: Vector2i = data.get("cell", Vector2i(-1, -1))
		var special_type: int = int(data.get("special_type", SPECIAL_TILE_TYPE_SCRIPT.NONE))
		var source_cells: Array = data.get("source_cells", [])

		var ghost := _get_valid_overlay_ghost(cell)
		if ghost == null:
			ghost = _spawn_fallback_special_ghost(cell)
			if ghost == null:
				continue
			_overlay_ghosts[cell] = ghost

		var creation_position: Vector2 = ghost.position

		var gather_ghosts: Array[Control] = []
		for source_cell_variant in source_cells:
			var source_cell: Vector2i = source_cell_variant
			if source_cell == cell:
				continue
			var gather_ghost := _get_valid_overlay_ghost(source_cell)
			if gather_ghost == null:
				continue
			gather_ghosts.append(gather_ghost)
			_overlay_ghosts.erase(source_cell)

		if not gather_ghosts.is_empty():
			var gather_tween := create_tween()
			gather_tween.set_parallel(true)
			for gather_ghost in gather_ghosts:
				gather_tween.tween_property(gather_ghost, "position", creation_position, gather_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
				gather_tween.tween_property(gather_ghost, "scale", Vector2.ZERO, gather_duration)
				gather_tween.tween_property(gather_ghost, "modulate:a", 0.0, gather_duration)
			gather_tween.chain().tween_callback(func() -> void:
				for gather_ghost in gather_ghosts:
					if is_instance_valid(gather_ghost):
						gather_ghost.free()
			)

		ghost.text = SPECIAL_TILE_TYPE_SCRIPT.get_marker_text(special_type)

		var base_scale: Vector2 = ghost.scale if ghost.scale != Vector2.ZERO else Vector2.ONE
		var pulse_scale := base_scale * 1.12
		var half_pulse_duration := pulse_duration * 0.5
		var flash_color := Color(1.35, 1.18, 0.55, 1.0)

		var pulse_tween := create_tween()
		if not gather_ghosts.is_empty():
			pulse_tween.tween_interval(gather_duration)
		pulse_tween.tween_property(ghost, "modulate", flash_color, half_pulse_duration)
		pulse_tween.parallel().tween_property(ghost, "scale", pulse_scale, half_pulse_duration)
		pulse_tween.chain().tween_property(ghost, "modulate", Color.WHITE, half_pulse_duration)
		pulse_tween.parallel().tween_property(ghost, "scale", base_scale, half_pulse_duration)


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


func _play_line_special_activation(activation_cell: Vector2i, affected_cells: Array[Vector2i], duration: float, horizontal: bool) -> void:
	var safe_duration := maxf(duration, 0.01)
	var sorted_cells := affected_cells.duplicate()
	if horizontal:
		sorted_cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
			return a.x < b.x
		)
	else:
		sorted_cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
			return a.y < b.y
		)

	_play_activation_cell_pulse(activation_cell, safe_duration, Color(1.45, 1.20, 0.50, 1.0))
	_play_line_sweep(sorted_cells, safe_duration, horizontal)


func _play_activation_cell_pulse(cell: Vector2i, duration: float, color: Color) -> void:
	var target := _get_animation_control_for_cell(cell)
	if target == null:
		return

	var base_scale: Vector2 = target.scale if target.scale != Vector2.ZERO else Vector2.ONE
	var pulse_scale := base_scale * 1.16
	var half_duration := maxf(duration * 0.28, 0.01)
	var tween := create_tween()
	_register_special_activation_tween(tween)
	tween.tween_property(target, "modulate", color, half_duration)
	tween.parallel().tween_property(target, "scale", pulse_scale, half_duration)
	tween.chain().tween_property(target, "modulate", Color.WHITE, half_duration)
	tween.parallel().tween_property(target, "scale", base_scale, half_duration)


func _play_line_sweep(cells: Array[Vector2i], duration: float, horizontal: bool) -> void:
	if cells.is_empty():
		return

	var sweep_color := Color(1.0, 0.86, 0.22, 0.0)
	var total_duration := maxf(duration, 0.01)
	var cell_duration := maxf(total_duration * 0.46, 0.04)
	var step_delay := maxf((total_duration - cell_duration) / maxf(float(cells.size()), 1.0), 0.0)

	for index in range(cells.size()):
		var cell := cells[index]
		var highlight := _create_cell_highlight(cell, horizontal, sweep_color)
		if highlight == null:
			continue

		var delay := step_delay * float(index)
		var tween := create_tween()
		_register_special_activation_tween(tween)
		if delay > 0.0:
			tween.tween_interval(delay)
		tween.tween_property(highlight, "modulate:a", 0.72, cell_duration * 0.35)
		tween.tween_property(highlight, "modulate:a", 0.0, cell_duration * 0.65)
		tween.tween_callback(func() -> void:
			if is_instance_valid(highlight):
				highlight.free()
		)


func _play_affected_cell_highlights(cells: Array[Vector2i], duration: float, color: Color, alpha: float) -> void:
	if cells.is_empty():
		return

	var total_duration := maxf(duration, 0.01)
	var cell_duration := maxf(total_duration * 0.55, 0.04)
	var step_delay := maxf((total_duration - cell_duration) / maxf(float(cells.size()), 1.0), 0.0)

	for index in range(cells.size()):
		var cell := cells[index]
		var highlight := _create_cell_highlight(cell, false, Color(color.r, color.g, color.b, 0.0))
		var target := _get_animation_control_for_cell(cell)
		if target != null:
			var base_scale: Vector2 = target.scale if target.scale != Vector2.ZERO else Vector2.ONE
			var pulse_tween := create_tween()
			_register_special_activation_tween(pulse_tween)
			pulse_tween.tween_interval(step_delay * float(index))
			pulse_tween.tween_property(target, "modulate", color, cell_duration * 0.35)
			pulse_tween.parallel().tween_property(target, "scale", base_scale * 1.06, cell_duration * 0.35)
			pulse_tween.chain().tween_property(target, "modulate", Color.WHITE, cell_duration * 0.65)
			pulse_tween.parallel().tween_property(target, "scale", base_scale, cell_duration * 0.65)

		if highlight == null:
			continue

		var tween := create_tween()
		_register_special_activation_tween(tween)
		tween.tween_interval(step_delay * float(index))
		tween.tween_property(highlight, "modulate:a", alpha, cell_duration * 0.35)
		tween.tween_property(highlight, "modulate:a", 0.0, cell_duration * 0.65)
		tween.tween_callback(func() -> void:
			if is_instance_valid(highlight):
				highlight.free()
		)


func _create_cell_highlight(cell: Vector2i, horizontal: bool, color: Color) -> ColorRect:
	if animation_layer == null:
		return null

	var rect := _get_animation_cell_rect(cell)
	if rect.size == Vector2.ZERO:
		return null

	var highlight := ColorRect.new()
	highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	highlight.color = Color(color.r, color.g, color.b, 1.0)
	highlight.modulate = Color(1.0, 1.0, 1.0, color.a)
	if horizontal:
		highlight.position = rect.position + Vector2(0.0, rect.size.y * 0.36)
		highlight.size = Vector2(rect.size.x, maxf(rect.size.y * 0.28, 4.0))
	else:
		highlight.position = rect.position + Vector2(rect.size.x * 0.36, 0.0)
		highlight.size = Vector2(maxf(rect.size.x * 0.28, 4.0), rect.size.y)
	animation_layer.add_child(highlight)
	highlight.move_to_front()
	return highlight


func _create_booster_preview_cell(cell: Vector2i, color: Color) -> ColorRect:
	if animation_layer == null:
		return null

	var rect := _get_animation_cell_rect(cell)
	if rect.size == Vector2.ZERO:
		return null

	var preview := ColorRect.new()
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.position = rect.position + rect.size * BOOSTER_TARGET_PREVIEW_INSET_RATIO
	preview.size = rect.size * (1.0 - BOOSTER_TARGET_PREVIEW_INSET_RATIO * 2.0)
	preview.color = color
	preview.modulate = Color(1.0, 1.0, 1.0, 0.0)
	animation_layer.add_child(preview)
	preview.move_to_front()

	var tween := create_tween()
	tween.tween_property(preview, "modulate:a", 1.0, 0.05)
	return preview


func _play_booster_impact_flash(cells: Array[Vector2i], duration: float, color: Color) -> void:
	for cell in cells:
		if _board != null and not _board.is_cell_active(cell):
			continue
		var highlight := _create_booster_preview_cell(cell, color)
		if highlight == null:
			continue

		var tween := create_tween()
		_register_special_activation_tween(tween)
		tween.tween_property(highlight, "modulate:a", 1.0, duration * 0.38)
		tween.tween_property(highlight, "modulate:a", 0.0, duration * 0.62)
		tween.tween_callback(func() -> void:
			if is_instance_valid(highlight):
				highlight.free()
		)


func _get_animation_cell_rect(cell: Vector2i) -> Rect2:
	var control := _get_animation_control_for_cell(cell)
	if control != null:
		return Rect2(control.position, control.size)

	var tile := get_tile_view(cell)
	if tile == null or animation_layer == null:
		return Rect2()

	return Rect2(tile.global_position - animation_layer.global_position, tile.size)


func _get_animation_control_for_cell(cell: Vector2i) -> Control:
	if _overlay_mode:
		var ghost := _get_valid_overlay_ghost(cell)
		if ghost != null:
			return ghost

	return get_tile_view(cell)


func _register_special_activation_tween(tween: Tween) -> void:
	if tween != null:
		_special_activation_tweens.append(tween)


func _clear_special_activation_tweens() -> void:
	for tween in _special_activation_tweens:
		if tween != null and tween.is_valid():
			tween.kill()
	_special_activation_tweens.clear()


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

extends Button
class_name TileView

signal tile_pressed(cell: Vector2i)
signal tile_drag_released(cell: Vector2i, drag_delta: Vector2)

const SPECIAL_TILE_DATA_SCRIPT := preload("res://scripts/game/board/special_tile_data.gd")
const SPECIAL_TILE_TYPE_SCRIPT := preload("res://scripts/game/board/special_tile_type.gd")
const CELL_OBSTACLE_TYPE_SCRIPT := preload("res://scripts/game/board/cell_obstacle_type.gd")
const ASSET_KEY_RESOLVER_SCRIPT := preload("res://scripts/game/config/asset_key_resolver.gd")
const GAME_ASSET_CATALOG := preload("res://scripts/game/config/game_asset_catalog.gd")

const TILE_COLORS := {
	TileType.RED: Color(0.86, 0.22, 0.22, 1.0),
	TileType.BLUE: Color(0.18, 0.42, 0.88, 1.0),
	TileType.GREEN: Color(0.16, 0.66, 0.36, 1.0),
	TileType.YELLOW: Color(0.92, 0.76, 0.20, 1.0),
	TileType.PURPLE: Color(0.56, 0.28, 0.82, 1.0),
}

## Stage 56 v0.1: placeholder ice overlay colors, separate from tile color
## and special marker.
## Stage 57.1 v0.1: strengthened for readability — normal (1-layer) ice is
## now a strong near-white frost so it reads clearly on every tile color;
## double (2-layer) ice is a strong, clearly blue frost (distinct hue, not
## just more opacity) plus a second inset overlay so it also reads as
## visually "thicker" than normal ice.
const ICE_OVERLAY_COLOR := Color(0.96, 0.98, 1.0, 0.58)
const ICE_OVERLAY_COLOR_DOUBLE := Color(0.20, 0.55, 0.95, 0.72)
const ICE_OVERLAY_INNER_COLOR := Color(0.10, 0.40, 0.85, 0.55)
const ICE_OVERLAY_INSET := 5.0

## Stage 57.3 v0.1: temporary, strong manual-testing visibility filter for
## procedural ice generation (Stage 57.2 targets 32-40 frozen cells per ice
## level, but the Stage 57.1 frost tint above was still too subtle to
## confirm density at a glance). While enabled, every iced cell — weak or
## strong — gets a strong white overlay as bold as the booster target
## preview (BoardView.BOOSTER_TARGET_PREVIEW_COLOR); strong (double) ice
## additionally keeps a strong blue inner layer so it still reads as
## distinct from weak ice. This is a placeholder debug aid, not final art —
## flip this back to false (or delete the debug branch in
## resolve_ice_overlay_color()/resolve_ice_overlay_inner_color()) once real
## ice art ships.
const ICE_DEBUG_VISIBILITY_ENABLED := true
const ICE_DEBUG_OVERLAY_COLOR := Color(1.0, 1.0, 1.0, 0.78)
const ICE_DEBUG_OVERLAY_COLOR_DOUBLE_INNER := Color(0.10, 0.35, 1.0, 0.85)

## Stage 55 v0.1: inactive cells (holes) render as a mostly-transparent dark
## inset with no border, no icon, and no marker text, so they read as "not
## playable" rather than "empty but playable".
const INACTIVE_CELL_BACKGROUND_COLOR := Color(0.04, 0.045, 0.06, 0.55)

static var _animations_enabled := true
static var _reduced_motion_enabled := false

var board_cell := Vector2i.ZERO
var tile_type := BoardModel.EMPTY
var special_tile_data
var _obstacle_type := CELL_OBSTACLE_TYPE_SCRIPT.NONE
var _obstacle_layers := 0
var _ice_overlay: ColorRect
var _ice_overlay_inner: ColorRect
var _ice_tween: Tween
var _is_selected := false
var _is_highlighted := false
var _is_invalid_feedback := false
## Stage 55 v0.1: true for a normal playable cell, false for an inactive
## cell (hole). While false, _apply_visuals() always renders the inactive
## look regardless of tile_type/special_tile_data/selected/highlighted/
## invalid-feedback state, so no later call can accidentally make an
## inactive cell look active/playable again.
var _is_active := true
var _press_start_position := Vector2.ZERO
var _has_press_start := false
var _suppress_next_pressed := false
var _active_tween: Tween


static func configure_presentation(animations_enabled: bool, reduced_motion_enabled: bool) -> void:
	_animations_enabled = animations_enabled
	_reduced_motion_enabled = reduced_motion_enabled


func _ready() -> void:
	custom_minimum_size = Vector2(48, 48)
	focus_mode = Control.FOCUS_NONE
	expand_icon = true
	gui_input.connect(_on_gui_input)
	if not pressed.is_connected(_on_pressed):
		pressed.connect(_on_pressed)
	_create_ice_overlays()
	_apply_visuals()


## Stage 56 v0.1: two plain ColorRect children drawn on top of the Button's
## own icon/text/stylebox rendering (children of a CanvasItem paint after
## their parent), so they read as a frost layer over the tile without
## touching tile_type/special_tile_data. The inner rect is only shown for
## double (2-layer) ice, giving it a visually "thicker" look.
func _create_ice_overlays() -> void:
	_ice_overlay = ColorRect.new()
	_ice_overlay.name = "IceOverlay"
	_ice_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ice_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ice_overlay.visible = false
	add_child(_ice_overlay)

	_ice_overlay_inner = ColorRect.new()
	_ice_overlay_inner.name = "IceOverlayInner"
	_ice_overlay_inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ice_overlay_inner.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ice_overlay_inner.offset_left = ICE_OVERLAY_INSET
	_ice_overlay_inner.offset_top = ICE_OVERLAY_INSET
	_ice_overlay_inner.offset_right = -ICE_OVERLAY_INSET
	_ice_overlay_inner.offset_bottom = -ICE_OVERLAY_INSET
	_ice_overlay_inner.color = ICE_OVERLAY_INNER_COLOR
	_ice_overlay_inner.visible = false
	add_child(_ice_overlay_inner)


## Stage 55 v0.1: switches this tile between normal playable rendering and
## the inactive "hole" look. Deactivating clears every transient visual
## state (selection, highlight, invalid feedback, in-flight tween) so
## nothing lingers once the cell stops being playable; input is also cut
## off at the source (mouse_filter) in addition to the _is_active guards in
## _on_gui_input()/_on_pressed().
func set_cell_active(active: bool) -> void:
	if _is_active == active:
		return

	_is_active = active
	if not _is_active:
		_stop_active_tween()
		_is_selected = false
		_is_highlighted = false
		_is_invalid_feedback = false
		visible = true
		modulate = Color.WHITE
		scale = Vector2.ONE
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	else:
		mouse_filter = Control.MOUSE_FILTER_STOP

	_apply_visuals()


func is_cell_active() -> bool:
	return _is_active


func set_tile(cell: Vector2i, new_tile_type: int) -> void:
	board_cell = cell
	tile_type = new_tile_type
	_apply_visuals()


func set_special_tile(special_data) -> void:
	if special_data is SPECIAL_TILE_DATA_SCRIPT:
		special_tile_data = special_data.duplicate_data()
	else:
		special_tile_data = null
	_apply_visuals()


## Stage 56 v0.1: syncs this tile's ice overlay from BoardModel's obstacle
## layer. layers <= 0 or a non-ice obstacle_type both mean "no ice".
func set_cell_obstacle(obstacle_type: int, layers: int = 0) -> void:
	_obstacle_type = obstacle_type
	_obstacle_layers = layers
	_apply_visuals()


func get_obstacle_type() -> int:
	return _obstacle_type


func get_obstacle_layers() -> int:
	return _obstacle_layers


func is_iced() -> bool:
	return CELL_OBSTACLE_TYPE_SCRIPT.is_ice(_obstacle_type) and _obstacle_layers > 0


func set_selected(selected: bool) -> void:
	_is_selected = selected
	_apply_visuals()


func set_highlighted(enabled: bool) -> void:
	_is_highlighted = enabled
	if enabled:
		_is_invalid_feedback = false
	_apply_visuals()


func set_invalid_feedback(enabled: bool) -> void:
	_is_invalid_feedback = enabled
	if enabled:
		_is_highlighted = false
	_apply_visuals()


func play_flash() -> void:
	if not _is_active:
		return
	set_highlighted(true)
	_play_flash_tween(Color(1.25, 1.25, 1.25, 1.0), Vector2(1.07, 1.07))


func play_invalid_flash() -> void:
	if not _is_active:
		return
	set_invalid_feedback(true)
	_play_flash_tween(Color(1.25, 0.55, 0.55, 1.0), Vector2(1.04, 1.04))


func play_swap_pulse() -> void:
	if not _is_active:
		return
	_play_flash_tween(Color(1.18, 1.18, 1.18, 1.0), Vector2(1.08, 1.08))


func play_invalid_pulse() -> void:
	if not _is_active:
		return
	set_invalid_feedback(true)
	_play_flash_tween(Color(1.30, 0.48, 0.45, 1.0), Vector2(0.94, 0.94))


## Stage 55 v0.1: transient tint/scale effects (match/special/invalid/refill
## feedback) are all guarded the same way — an inactive cell (hole) never
## plays them, even if a caller mistakenly targets one directly.
func play_match_fade() -> void:
	if not _is_active:
		return
	_stop_active_tween()
	visible = true
	pivot_offset = size * 0.5
	modulate = Color.WHITE
	scale = Vector2.ONE
	var fade_scale := _adjust_scale(Vector2(0.88, 0.88))
	var step_duration := _adjust_duration(0.10)
	_active_tween = create_tween()
	_active_tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 0.22), step_duration)
	_active_tween.parallel().tween_property(self, "scale", fade_scale, step_duration)
	_active_tween.tween_property(self, "modulate", Color.WHITE, step_duration)
	_active_tween.parallel().tween_property(self, "scale", Vector2.ONE, step_duration)


func play_match_clear(duration: float = 0.16) -> void:
	if not _is_active:
		return
	_stop_active_tween()
	visible = true
	pivot_offset = size * 0.5
	modulate = Color.WHITE
	scale = Vector2.ONE
	var step_duration: float = _adjust_duration(maxf(duration / 3.0, 0.01))
	var clear_scale := _adjust_scale(Vector2(1.14, 1.14))
	var fade_scale := _adjust_scale(Vector2(0.72, 0.72))
	modulate = _adjust_color(Color(1.35, 1.35, 1.35, 1.0))
	scale = clear_scale
	_active_tween = create_tween()
	_active_tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 0.18), step_duration)
	_active_tween.parallel().tween_property(self, "scale", fade_scale, step_duration)
	_active_tween.tween_property(self, "modulate", Color.WHITE, step_duration)
	_active_tween.parallel().tween_property(self, "scale", Vector2.ONE, step_duration)


func play_special_flash() -> void:
	if not _is_active:
		return
	set_highlighted(true)
	_play_flash_tween(Color(1.35, 1.08, 0.45, 1.0), Vector2(1.12, 1.12))


func play_special_clear(duration: float = 0.18) -> void:
	if not _is_active:
		return
	set_highlighted(true)
	_stop_active_tween()
	visible = true
	pivot_offset = size * 0.5
	modulate = Color.WHITE
	scale = Vector2.ONE
	var step_duration: float = _adjust_duration(maxf(duration / 3.0, 0.01))
	var burst_scale := _adjust_scale(Vector2(1.20, 1.20))
	var fade_scale := _adjust_scale(Vector2(0.78, 0.78))
	modulate = _adjust_color(Color(1.45, 1.18, 0.42, 1.0))
	scale = burst_scale
	_active_tween = create_tween()
	_active_tween.tween_property(self, "modulate", Color(1.0, 0.92, 0.46, 0.26), step_duration)
	_active_tween.parallel().tween_property(self, "scale", fade_scale, step_duration)
	_active_tween.tween_property(self, "modulate", Color.WHITE, step_duration)
	_active_tween.parallel().tween_property(self, "scale", Vector2.ONE, step_duration)


func play_invalid_bounce(_offset: Vector2, step_duration: float = 0.04) -> void:
	if not _is_active:
		return
	set_invalid_feedback(true)
	_stop_active_tween()
	visible = true
	pivot_offset = size * 0.5
	modulate = Color.WHITE
	scale = Vector2.ONE
	var invalid_scale := _adjust_scale(Vector2(0.94, 0.94))
	var adjusted_duration := _adjust_duration(step_duration)
	_active_tween = create_tween()
	_active_tween.tween_property(self, "modulate", _adjust_color(Color(1.30, 0.48, 0.45, 1.0)), adjusted_duration)
	_active_tween.parallel().tween_property(self, "scale", invalid_scale, adjusted_duration)
	_active_tween.tween_property(self, "modulate", Color.WHITE, adjusted_duration)
	_active_tween.parallel().tween_property(self, "scale", Vector2.ONE, adjusted_duration)


## Stage 56 v0.1: a brief cold-white flash on the ice overlay for a hit that
## damaged but did not break the ice. Callers are expected to call this (or
## play_ice_break()) before the obstacle state is synced via
## set_cell_obstacle(), since _apply_ice_overlay() re-applies the current
## (pre-animation) overlay once the flash settles.
func play_ice_damage() -> void:
	if not _is_active or _ice_overlay == null or not is_iced():
		return

	_stop_ice_tween()
	_ice_overlay.visible = true
	var flash_color := Color(1.30, 1.45, 1.60, 1.0)
	_ice_tween = create_tween()
	_ice_tween.tween_property(_ice_overlay, "modulate", flash_color, _adjust_duration(0.06))
	_ice_tween.tween_property(_ice_overlay, "modulate", Color.WHITE, _adjust_duration(0.12))
	_ice_tween.tween_callback(_apply_ice_overlay)


## Stage 56 v0.1: fades the ice overlay(s) out for a hit that fully breaks
## the ice. See play_ice_damage() for call-order expectations.
func play_ice_break() -> void:
	if not _is_active or _ice_overlay == null or not is_iced():
		return

	_stop_ice_tween()
	var duration := _adjust_duration(0.16)
	_ice_tween = create_tween()
	_ice_tween.tween_property(_ice_overlay, "modulate:a", 0.0, duration)
	if _ice_overlay_inner != null:
		_ice_tween.parallel().tween_property(_ice_overlay_inner, "modulate:a", 0.0, duration)
	_ice_tween.tween_callback(func() -> void:
		_ice_overlay.modulate = Color.WHITE
		if _ice_overlay_inner != null:
			_ice_overlay_inner.modulate = Color.WHITE
		_apply_ice_overlay()
	)


func play_refill_appear() -> void:
	if not _is_active:
		return
	_stop_active_tween()
	visible = true
	pivot_offset = size * 0.5
	modulate = Color(1.0, 1.0, 1.0, 0.45)
	scale = _adjust_scale(Vector2(0.90, 0.90))
	var duration := _adjust_duration(0.12)
	_active_tween = create_tween()
	_active_tween.tween_property(self, "modulate", Color.WHITE, duration)
	_active_tween.parallel().tween_property(self, "scale", Vector2.ONE, duration)


func reset_visual_state() -> void:
	_stop_active_tween()
	visible = true
	modulate = Color.WHITE
	scale = Vector2.ONE
	_is_invalid_feedback = false
	_apply_visuals()


func clear_transient_feedback_state() -> void:
	_stop_active_tween()
	modulate = Color.WHITE
	scale = Vector2.ONE
	_is_invalid_feedback = false
	_apply_visuals()


func get_tile_asset_key() -> String:
	return ASSET_KEY_RESOLVER_SCRIPT.get_tile_asset_key(tile_type)


func get_special_tile_asset_key() -> String:
	if special_tile_data is SPECIAL_TILE_DATA_SCRIPT:
		return ASSET_KEY_RESOLVER_SCRIPT.get_special_tile_asset_key(special_tile_data.special_type)

	return ""


func get_marker_text() -> String:
	return _get_special_marker_text()


func has_tile_texture() -> bool:
	return icon != null


func _on_pressed() -> void:
	if not _is_active:
		return

	if _suppress_next_pressed:
		_suppress_next_pressed = false
		return

	tile_pressed.emit(board_cell)


## Stage 55 v0.1: inactive cells never select/drag, even if mouse_filter
## somehow still let an event through — guarded explicitly rather than
## relying only on mouse_filter/disabled semantics.
func _on_gui_input(event: InputEvent) -> void:
	if not _is_active:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.pressed:
			_start_pointer(mouse_event.position)
		else:
			_release_pointer(mouse_event.position)
	elif event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		if touch_event.pressed:
			_start_pointer(touch_event.position)
		else:
			_release_pointer(touch_event.position)


func _start_pointer(pointer_position: Vector2) -> void:
	_press_start_position = pointer_position
	_has_press_start = true


func _release_pointer(pointer_position: Vector2) -> void:
	if not _has_press_start:
		return

	var drag_delta := pointer_position - _press_start_position
	_has_press_start = false
	if drag_delta.length() > 0.0:
		_suppress_next_pressed = true
		tile_drag_released.emit(board_cell, drag_delta)


func _apply_visuals() -> void:
	if not _is_active:
		_apply_inactive_visuals()
		return

	disabled = false
	var base_color: Color = TILE_COLORS.get(tile_type, Color(0.20, 0.22, 0.26, 1.0))
	var style := StyleBoxFlat.new()
	style.bg_color = base_color.lightened(0.22) if _is_selected or _is_highlighted else base_color
	var border_width := 1
	var border_color := Color(0.05, 0.06, 0.08, 0.8)
	if _is_invalid_feedback:
		border_width = 4
		border_color = Color(1.0, 0.18, 0.16, 1.0)
	elif _is_selected:
		border_width = 4
		border_color = Color(1.0, 1.0, 1.0, 1.0)
	elif _is_highlighted:
		border_width = 3
		border_color = Color(1.0, 0.86, 0.20, 1.0)

	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.border_color = border_color
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	add_theme_stylebox_override("normal", style)
	add_theme_stylebox_override("hover", style)
	add_theme_stylebox_override("pressed", style)
	icon = GAME_ASSET_CATALOG.try_load_texture_cached(get_tile_asset_key())
	text = _get_special_marker_text()
	add_theme_color_override("font_color", Color.WHITE)
	add_theme_color_override("font_hover_color", Color.WHITE)
	add_theme_color_override("font_pressed_color", Color.WHITE)
	add_theme_font_size_override("font_size", 24 if _get_special_marker_text() == "B" else 22)
	_apply_ice_overlay()


## Stage 55 v0.1: inactive cells never show a tile texture/color, a special
## marker, or any selected/highlight/invalid border — just a low, mostly
## transparent inset so the 9x9 GridContainer layout stays stable while the
## cell clearly reads as "not playable" rather than an empty playable cell.
## Stage 56 v0.1: inactive cells never show an ice overlay either, matching
## the BoardModel rule that an inactive cell can never carry an obstacle.
func _apply_inactive_visuals() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = INACTIVE_CELL_BACKGROUND_COLOR
	style.border_width_left = 0
	style.border_width_top = 0
	style.border_width_right = 0
	style.border_width_bottom = 0
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	add_theme_stylebox_override("normal", style)
	add_theme_stylebox_override("hover", style)
	add_theme_stylebox_override("pressed", style)
	add_theme_stylebox_override("disabled", style)
	icon = null
	text = ""
	disabled = true
	if _ice_overlay != null:
		_ice_overlay.visible = false
	if _ice_overlay_inner != null:
		_ice_overlay_inner.visible = false


## Stage 57.3 v0.1: single source of truth for the ice overlay color at a
## given layer count, so both this class and BoardView's overlay-mode ghosts
## (create_tile_ghost_from_data()) automatically pick up the same debug/final
## visual with no duplicated branching.
static func resolve_ice_overlay_color(layers: int) -> Color:
	if ICE_DEBUG_VISIBILITY_ENABLED:
		return ICE_DEBUG_OVERLAY_COLOR
	return ICE_OVERLAY_COLOR_DOUBLE if layers >= 2 else ICE_OVERLAY_COLOR


static func resolve_ice_overlay_inner_color() -> Color:
	return ICE_DEBUG_OVERLAY_COLOR_DOUBLE_INNER if ICE_DEBUG_VISIBILITY_ENABLED else ICE_OVERLAY_INNER_COLOR


## Stage 56 v0.1: shows/hides the ice overlay(s) to match current obstacle
## state. Called from _apply_visuals() (active cells) and after an ice
## damage/break tween settles, so the overlay always ends up matching
## set_cell_obstacle()'s last value once any transient animation finishes.
func _apply_ice_overlay() -> void:
	if _ice_overlay == null:
		return

	if not is_iced():
		_ice_overlay.visible = false
		if _ice_overlay_inner != null:
			_ice_overlay_inner.visible = false
		return

	_ice_overlay.visible = true
	_ice_overlay.color = resolve_ice_overlay_color(_obstacle_layers)
	if _ice_overlay_inner != null:
		_ice_overlay_inner.visible = _obstacle_layers >= 2
		_ice_overlay_inner.color = resolve_ice_overlay_inner_color()


func _get_special_marker_text() -> String:
	if special_tile_data is SPECIAL_TILE_DATA_SCRIPT:
		return SPECIAL_TILE_TYPE_SCRIPT.get_marker_text(special_tile_data.special_type)

	return ""


func _play_flash_tween(flash_modulate: Color, flash_scale: Vector2) -> void:
	_stop_active_tween()
	visible = true
	modulate = Color.WHITE
	scale = Vector2.ONE
	pivot_offset = size * 0.5
	var adjusted_modulate := _adjust_color(flash_modulate)
	var adjusted_scale := _adjust_scale(flash_scale)
	var flash_duration := _adjust_duration(0.06)
	var settle_duration := _adjust_duration(0.14)
	_active_tween = create_tween()
	_active_tween.tween_property(self, "modulate", adjusted_modulate, flash_duration)
	_active_tween.parallel().tween_property(self, "scale", adjusted_scale, flash_duration)
	_active_tween.tween_property(self, "modulate", Color.WHITE, settle_duration)
	_active_tween.parallel().tween_property(self, "scale", Vector2.ONE, settle_duration)


func _adjust_duration(base_duration: float) -> float:
	return base_duration if _animations_enabled else 0.01


func _adjust_scale(base_scale: Vector2) -> Vector2:
	return base_scale.lerp(Vector2.ONE, 0.6) if _reduced_motion_enabled else base_scale


func _adjust_color(base_color: Color) -> Color:
	return base_color.lerp(Color.WHITE, 0.5) if _reduced_motion_enabled else base_color


func _stop_active_tween() -> void:
	if _active_tween != null:
		_active_tween.kill()
		_active_tween = null


func _stop_ice_tween() -> void:
	if _ice_tween != null:
		_ice_tween.kill()
		_ice_tween = null

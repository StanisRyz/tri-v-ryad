extends Control
class_name BoardView

signal tile_pressed(cell: Vector2i)
signal tile_drag_released(cell: Vector2i, drag_delta: Vector2)

const TILE_VIEW_SCENE := preload("res://scenes/game/TileView.tscn")
const BOARD_SIZE := 9
const LANE_WIDTH := 3
const DEFAULT_BOARD_SIZE := 664.0

@onready var tile_grid: GridContainer = %TileGrid

var _board: BoardModel
var _tile_views: Dictionary = {}
var _selected_cell := Vector2i(-1, -1)
var _lane_activations: Dictionary = {}
var _highlighted_cells: Array[Vector2i] = []
var _invalid_feedback_cells: Array[Vector2i] = []


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


func _get_board_rect() -> Rect2:
	var board_size: float = minf(size.x, size.y)
	var origin: Vector2 = (size - Vector2.ONE * board_size) * 0.5
	return Rect2(origin, Vector2.ONE * board_size)

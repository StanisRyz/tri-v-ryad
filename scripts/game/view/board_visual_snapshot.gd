extends RefCounted
class_name BoardVisualSnapshot

const CELL_OBSTACLE_TYPE_SCRIPT := preload("res://scripts/game/board/cell_obstacle_type.gd")

# Captures a read-only copy of BoardView's visible per-cell state at a point in
# time (pre-turn), so animation phases have one safe, immutable source of
# truth to build ghost overlays from instead of reading a BoardView that is
# being mutated mid-sequence.

var _cells: Dictionary = {}


static func from_board_view(board_view: BoardView) -> BoardVisualSnapshot:
	var snapshot := BoardVisualSnapshot.new()
	if board_view == null:
		return snapshot

	var animation_layer: Control = board_view.get_animation_layer() if board_view.has_method("get_animation_layer") else null

	for y in range(BoardView.BOARD_SIZE):
		for x in range(BoardView.BOARD_SIZE):
			var cell := Vector2i(x, y)
			var tile := board_view.get_tile_view(cell)
			if tile == null:
				continue

			var local_position: Vector2 = tile.global_position
			if animation_layer != null:
				local_position -= animation_layer.global_position

			snapshot._cells[cell] = {
				"cell": cell,
				"tile_type": tile.tile_type,
				"special_data": tile.special_tile_data.duplicate_data() if tile.special_tile_data != null else null,
				"global_position": tile.global_position,
				"local_position": local_position,
				"size": tile.size,
				"asset_key": tile.get_tile_asset_key() if tile.has_method("get_tile_asset_key") else "",
				"placeholder_color": TileView.TILE_COLORS.get(tile.tile_type, Color(0.20, 0.22, 0.26, 1.0)),
				"marker_text": tile.get_marker_text() if tile.has_method("get_marker_text") else "",
				## Stage 55 v0.1: lets build_full_board_ghosts() skip inactive
				## cells entirely (their real TileView stays visible instead).
				"is_active": tile.is_cell_active() if tile.has_method("is_cell_active") else true,
				## Stage 56 v0.1: lets build_full_board_ghosts() render an ice
				## overlay on the ghost for a frozen cell.
				"obstacle_type": tile.get_obstacle_type() if tile.has_method("get_obstacle_type") else CELL_OBSTACLE_TYPE_SCRIPT.NONE,
				"obstacle_layers": tile.get_obstacle_layers() if tile.has_method("get_obstacle_layers") else 0,
			}

	return snapshot


func has_cell(cell: Vector2i) -> bool:
	return _cells.has(cell)


func get_cell_data(cell: Vector2i) -> Dictionary:
	return _cells.get(cell, {})


func get_cells() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for cell in _cells.keys():
		result.append(cell)
	return result


func size() -> int:
	return _cells.size()


func is_empty() -> bool:
	return _cells.is_empty()

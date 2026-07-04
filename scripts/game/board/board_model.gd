extends RefCounted
class_name BoardModel

const SPECIAL_TILE_DATA_SCRIPT := preload("res://scripts/game/board/special_tile_data.gd")
const SPECIAL_TILE_TYPE_SCRIPT := preload("res://scripts/game/board/special_tile_type.gd")

const DEFAULT_WIDTH := 9
const DEFAULT_HEIGHT := 9
const EMPTY := -1

var width: int
var height: int
var _tiles: Array[int] = []
var _special_tiles: Dictionary = {}


func _init(board_width: int = DEFAULT_WIDTH, board_height: int = DEFAULT_HEIGHT) -> void:
	width = board_width
	height = board_height
	_tiles.resize(width * height)
	_tiles.fill(EMPTY)


func is_inside(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < width and cell.y < height


func get_tile(cell: Vector2i) -> int:
	if not is_inside(cell):
		return EMPTY

	return _tiles[_to_index(cell)]


func set_tile(cell: Vector2i, tile_type: int) -> void:
	if not is_inside(cell):
		push_error("Cannot set tile outside board: %s" % [cell])
		return

	_tiles[_to_index(cell)] = tile_type
	if tile_type == EMPTY:
		clear_special_tile(cell)


func has_special_tile(cell: Vector2i) -> bool:
	return is_inside(cell) and _special_tiles.has(cell)


func get_special_tile(cell: Vector2i):
	if not has_special_tile(cell):
		return null

	var special_data = _special_tiles[cell]
	if special_data is SPECIAL_TILE_DATA_SCRIPT:
		return special_data.duplicate_data()

	return null


func set_special_tile(cell: Vector2i, special_data) -> void:
	if not is_inside(cell):
		push_error("Cannot set special tile outside board: %s" % [cell])
		return

	if special_data == null or not (special_data is SPECIAL_TILE_DATA_SCRIPT) or special_data.is_empty():
		clear_special_tile(cell)
		return

	_special_tiles[cell] = special_data.duplicate_data()


func clear_special_tile(cell: Vector2i) -> void:
	if _special_tiles.has(cell):
		_special_tiles.erase(cell)


func clear_special_tiles(cells: Array) -> void:
	for cell in cells:
		clear_special_tile(cell as Vector2i)


func get_special_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for cell in _special_tiles.keys():
		cells.append(cell)
	return cells


func swap_tiles(a: Vector2i, b: Vector2i) -> void:
	if not is_inside(a) or not is_inside(b):
		push_error("Cannot swap tiles outside board: %s <-> %s" % [a, b])
		return

	var a_index := _to_index(a)
	var b_index := _to_index(b)
	var a_tile := _tiles[a_index]
	var a_special = get_special_tile(a)
	var b_special = get_special_tile(b)
	_tiles[a_index] = _tiles[b_index]
	_tiles[b_index] = a_tile
	clear_special_tile(a)
	clear_special_tile(b)
	set_special_tile(a, b_special)
	set_special_tile(b, a_special)


func clear_cells(cells: Array) -> void:
	for cell in cells:
		var typed_cell := cell as Vector2i
		if is_inside(typed_cell):
			set_tile(typed_cell, EMPTY)
			clear_special_tile(typed_cell)


func has_empty_cells() -> bool:
	return EMPTY in _tiles


func get_all_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y in range(height):
		for x in range(width):
			cells.append(Vector2i(x, y))
	return cells


func duplicate_board() -> BoardModel:
	var copy := BoardModel.new(width, height)
	copy._tiles = _tiles.duplicate()
	for cell in _special_tiles.keys():
		copy.set_special_tile(cell, _special_tiles[cell])
	return copy


func clone() -> BoardModel:
	return duplicate_board()


func to_debug_string() -> String:
	var lines: Array[String] = []
	for y in range(height):
		var values: Array[String] = []
		for x in range(width):
			var cell := Vector2i(x, y)
			var value := str(get_tile(cell))
			if has_special_tile(cell):
				value += SPECIAL_TILE_TYPE_SCRIPT.get_marker_text(_special_tiles[cell].special_type)
			values.append(value)
		lines.append(" ".join(values))
	return "\n".join(lines)


func _to_index(cell: Vector2i) -> int:
	return cell.y * width + cell.x

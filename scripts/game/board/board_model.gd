extends RefCounted
class_name BoardModel

const DEFAULT_WIDTH := 9
const DEFAULT_HEIGHT := 9
const EMPTY := -1

var width: int
var height: int
var _tiles: Array[int] = []


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


func swap_tiles(a: Vector2i, b: Vector2i) -> void:
	if not is_inside(a) or not is_inside(b):
		push_error("Cannot swap tiles outside board: %s <-> %s" % [a, b])
		return

	var a_index := _to_index(a)
	var b_index := _to_index(b)
	var a_tile := _tiles[a_index]
	_tiles[a_index] = _tiles[b_index]
	_tiles[b_index] = a_tile


func clear_cells(cells: Array) -> void:
	for cell in cells:
		var typed_cell := cell as Vector2i
		if is_inside(typed_cell):
			set_tile(typed_cell, EMPTY)


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
	return copy


func clone() -> BoardModel:
	return duplicate_board()


func to_debug_string() -> String:
	var lines: Array[String] = []
	for y in range(height):
		var values: Array[String] = []
		for x in range(width):
			values.append(str(get_tile(Vector2i(x, y))))
		lines.append(" ".join(values))
	return "\n".join(lines)


func _to_index(cell: Vector2i) -> int:
	return cell.y * width + cell.x

extends RefCounted
class_name BoardMaskSymmetry

## Stage 53.1 v0.1: mirrors cells/blocks around a board's center so future
## procedural hole masks (Stage 54) are symmetrical and readable instead of
## random noise. quadrant_mirror is the only supported mode for v0.1.

const QUADRANT_MIRROR := "quadrant_mirror"


## For a cell (x, y) on a width x height board, quadrant_mirror produces
## (x, y), (width-1-x, y), (x, height-1-y), and (width-1-x, height-1-y),
## deduplicated (a cell already on an axis of symmetry mirrors onto itself).
static func get_mirrored_cells(cell: Vector2i, width: int, height: int, symmetry_mode: String = QUADRANT_MIRROR) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var seen := {}
	_add_unique(cells, seen, cell)

	if symmetry_mode == QUADRANT_MIRROR:
		_add_unique(cells, seen, Vector2i(width - 1 - cell.x, cell.y))
		_add_unique(cells, seen, Vector2i(cell.x, height - 1 - cell.y))
		_add_unique(cells, seen, Vector2i(width - 1 - cell.x, height - 1 - cell.y))

	return cells


## Mirrors every cell of a rectangular block (not just its anchor corner),
## so a hole block placed in one quadrant produces correctly mirrored
## rectangles in the other three quadrants. Returns the deduplicated union
## of all cells across all mirrored copies.
static func get_mirrored_block_cells(top_left: Vector2i, block_width: int, block_height: int, width: int, height: int, symmetry_mode: String = QUADRANT_MIRROR) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var seen := {}

	for local_y in range(block_height):
		for local_x in range(block_width):
			var cell := Vector2i(top_left.x + local_x, top_left.y + local_y)
			for mirrored_cell in get_mirrored_cells(cell, width, height, symmetry_mode):
				_add_unique(cells, seen, mirrored_cell)

	return cells


static func _add_unique(cells: Array[Vector2i], seen: Dictionary, cell: Vector2i) -> void:
	if seen.has(cell):
		return

	seen[cell] = true
	cells.append(cell)

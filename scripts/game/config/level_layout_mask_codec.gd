extends RefCounted
class_name LevelLayoutMaskCodec

## Stage 58 v0.1: converts between the deterministic layout database's
## compact 81-character mask strings and the Array/Vector2i shapes the rest
## of the game already uses (GeneratedBoardChallenge.board_mask,
## BoardModel.apply_frozen_cells()). Row-major indexing: index = y * width + x,
## matching BoardModel's mask shape (an Array of height rows, each an Array
## of width values).
##
## board_mask string: "1" = active cell, "0" = inactive/hole cell.
## ice_mask string: "0" = no ice, "1" = weak (1-layer) ice, "2" = strong
## (2-layer) ice. Ice is only ever meaningful on an active cell; callers are
## expected to keep ice_mask "0" wherever board_mask is "0" (Stage 58 never
## mixes holes and ice).

const BOARD_WIDTH := 9
const BOARD_HEIGHT := 9
const BOARD_CELL_COUNT := BOARD_WIDTH * BOARD_HEIGHT

const BOARD_MASK_CHARS := "01"
const ICE_MASK_CHARS := "012"


static func board_mask_to_string(mask: Array) -> String:
	var chars := PackedStringArray()
	chars.resize(BOARD_CELL_COUNT)
	for y in range(BOARD_HEIGHT):
		var row: Array = mask[y] if y < mask.size() else []
		for x in range(BOARD_WIDTH):
			var active := bool(row[x]) if x < row.size() else true
			chars[y * BOARD_WIDTH + x] = "1" if active else "0"
	return "".join(chars)


## Any mask string that isn't exactly BOARD_CELL_COUNT chars long falls back
## to a full active board, mirroring BoardModel.set_active_mask()'s own
## invalid-shape fallback.
static func board_mask_from_string(mask_string: String) -> Array:
	var mask: Array = []
	var valid := is_valid_mask_string(mask_string, BOARD_MASK_CHARS)
	for y in range(BOARD_HEIGHT):
		var row: Array = []
		for x in range(BOARD_WIDTH):
			if not valid:
				row.append(true)
				continue
			var index := y * BOARD_WIDTH + x
			row.append(mask_string[index] == "1")
		mask.append(row)
	return mask


## Stage 56 frozen_cells shape: an Array of bare Vector2i (1-layer) or
## {"cell": Vector2i, "layers": int} Dictionaries. Cells outside the board or
## with layers <= 0 are skipped.
static func frozen_cells_to_ice_mask_string(frozen_cells: Array) -> String:
	var layers_by_index := {}
	for entry in frozen_cells:
		var cell: Vector2i
		var layers := 1

		if entry is Vector2i:
			cell = entry
		elif entry is Dictionary and entry.get("cell") is Vector2i:
			cell = entry["cell"]
			layers = int(entry.get("layers", 1))
		else:
			continue

		if cell.x < 0 or cell.y < 0 or cell.x >= BOARD_WIDTH or cell.y >= BOARD_HEIGHT or layers <= 0:
			continue

		layers_by_index[cell.y * BOARD_WIDTH + cell.x] = clampi(layers, 0, 2)

	var chars := PackedStringArray()
	chars.resize(BOARD_CELL_COUNT)
	for i in range(BOARD_CELL_COUNT):
		chars[i] = str(layers_by_index.get(i, 0))
	return "".join(chars)


## Returns a frozen_cells array compatible with BoardModel.apply_frozen_cells().
## An invalid-length ice_mask string yields no frozen cells at all rather than
## guessing.
static func ice_mask_string_to_frozen_cells(ice_mask_string: String) -> Array:
	var frozen_cells: Array = []
	if not is_valid_mask_string(ice_mask_string, ICE_MASK_CHARS):
		return frozen_cells

	for y in range(BOARD_HEIGHT):
		for x in range(BOARD_WIDTH):
			var index := y * BOARD_WIDTH + x
			var layers := int(ice_mask_string[index])
			if layers <= 0:
				continue
			frozen_cells.append({"cell": Vector2i(x, y), "layers": layers})

	return frozen_cells


static func is_valid_mask_string(value: String, allowed_chars: String) -> bool:
	if value.length() != BOARD_CELL_COUNT:
		return false

	for i in range(value.length()):
		if not allowed_chars.contains(value[i]):
			return false

	return true


static func count_char(value: String, target_char: String) -> int:
	var count := 0
	for i in range(value.length()):
		if value[i] == target_char:
			count += 1
	return count

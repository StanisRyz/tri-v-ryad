extends RefCounted
class_name TileType

const RED := 0
const BLUE := 1
const GREEN := 2
const YELLOW := 3
const PURPLE := 4


static func get_all_types() -> Array[int]:
	return [RED, BLUE, GREEN, YELLOW, PURPLE]


static func is_valid_tile_type(value: int) -> bool:
	return value in get_all_types()

extends RefCounted
class_name SpecialTileData

const SPECIAL_TILE_TYPE_SCRIPT := preload("res://scripts/game/board/special_tile_type.gd")

var special_type := SPECIAL_TILE_TYPE_SCRIPT.NONE


func _init(new_special_type: int = SPECIAL_TILE_TYPE_SCRIPT.NONE) -> void:
	special_type = new_special_type if SPECIAL_TILE_TYPE_SCRIPT.is_valid(new_special_type) else SPECIAL_TILE_TYPE_SCRIPT.NONE


func is_empty() -> bool:
	return special_type == SPECIAL_TILE_TYPE_SCRIPT.NONE


func is_horizontal_line() -> bool:
	return special_type == SPECIAL_TILE_TYPE_SCRIPT.LINE_HORIZONTAL


func is_vertical_line() -> bool:
	return special_type == SPECIAL_TILE_TYPE_SCRIPT.LINE_VERTICAL


func duplicate_data():
	return get_script().new(special_type)


func to_dictionary() -> Dictionary:
	return {
		"special_type": special_type,
	}


static func from_type(special_type: int):
	return load("res://scripts/game/board/special_tile_data.gd").new(special_type)

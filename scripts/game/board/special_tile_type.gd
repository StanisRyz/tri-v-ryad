extends RefCounted
class_name SpecialTileType

const NONE := 0
const LINE_HORIZONTAL := 1
const LINE_VERTICAL := 2


static func is_valid(value: int) -> bool:
	return value == NONE or value == LINE_HORIZONTAL or value == LINE_VERTICAL


static func is_line(value: int) -> bool:
	return value == LINE_HORIZONTAL or value == LINE_VERTICAL


static func get_marker_text(value: int) -> String:
	match value:
		LINE_HORIZONTAL:
			return "H"
		LINE_VERTICAL:
			return "V"
		_:
			return ""

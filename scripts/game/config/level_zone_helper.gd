extends RefCounted
class_name LevelZoneHelper

const ZONE_SIZE := 10


static func get_zone_count(total_levels: int, zone_size: int = ZONE_SIZE) -> int:
	if total_levels <= 0 or zone_size <= 0:
		return 0
	return int(ceil(float(total_levels) / float(zone_size)))


static func get_zone_index_for_level_number(level_number: int, zone_size: int = ZONE_SIZE) -> int:
	if level_number <= 0 or zone_size <= 0:
		return -1
	return int(floor(float(level_number - 1) / float(zone_size)))


static func get_zone_index_for_level_id(level_id: String, zone_size: int = ZONE_SIZE) -> int:
	var level_number := _extract_level_number(level_id)
	if level_number <= 0:
		return -1
	return get_zone_index_for_level_number(level_number, zone_size)


static func get_level_range_for_zone(zone_index: int, total_levels: int, zone_size: int = ZONE_SIZE) -> Vector2i:
	if zone_index < 0 or total_levels <= 0 or zone_size <= 0:
		return Vector2i.ZERO

	var start_level := zone_index * zone_size + 1
	if start_level > total_levels:
		return Vector2i.ZERO

	var end_level: int = min(start_level + zone_size - 1, total_levels)
	return Vector2i(start_level, end_level)


static func format_zone_label(zone_index: int, start_level: int, end_level: int) -> String:
	return "Zone %d: Levels %d-%d" % [zone_index + 1, start_level, end_level]


static func get_zone_unlock_level_id(zone_index: int, zone_size: int = ZONE_SIZE) -> String:
	if zone_index <= 0 or zone_size <= 0:
		return ""
	return "level_%d" % (zone_index * zone_size)


static func _extract_level_number(level_id: String) -> int:
	var prefix := "level_"
	if not level_id.begins_with(prefix):
		return -1

	var level_number_text := level_id.substr(prefix.length())
	if not level_number_text.is_valid_int():
		return -1

	var level_number := int(level_number_text)
	if level_number <= 0:
		return -1

	return level_number

extends RefCounted
class_name LevelLabelFormatter


static func format_level_label(level_id: String, fallback_display_name: String = "") -> String:
	var level_number := extract_level_number(level_id)
	if level_number > 0:
		return "Level %d" % level_number

	if fallback_display_name != "":
		return fallback_display_name

	return "Level"


static func extract_level_number(level_id: String) -> int:
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

extends RefCounted
class_name LocalizationDataGenerator

# Stage 66.1: Localization Foundation.
# Reads res://localization/game_text.csv and regenerates
# res://scripts/game/localization/localization_data.gd as a plain
# built-in fallback dictionary (en/ru).

const CSV_PATH := "res://localization/game_text.csv"
const OUTPUT_PATH := "res://scripts/game/localization/localization_data.gd"

const CSV_COLUMN_KEY := 0
const CSV_COLUMN_EN := 1
const CSV_COLUMN_RU := 2

const SUPPORTED_LANGUAGES: Array[String] = ["en", "ru"]


static func generate() -> bool:
	if not FileAccess.file_exists(CSV_PATH):
		push_error("LocalizationDataGenerator: CSV not found at %s" % CSV_PATH)
		return false
	var file: FileAccess = FileAccess.open(CSV_PATH, FileAccess.READ)
	if file == null:
		push_error("LocalizationDataGenerator: failed to open %s" % CSV_PATH)
		return false
	var raw_text: String = file.get_as_text()
	file.close()

	var translations: Dictionary = {"en": {}, "ru": {}}
	var rows: Array = _parse_csv(raw_text)
	for row_index in range(1, rows.size()):
		var row: Array = rows[row_index]
		if row.size() <= CSV_COLUMN_EN:
			continue
		var key: String = String(row[CSV_COLUMN_KEY]).strip_edges()
		if key.is_empty():
			continue
		var en_text: String = String(row[CSV_COLUMN_EN])
		if not en_text.is_empty():
			translations["en"][key] = en_text
		if row.size() > CSV_COLUMN_RU:
			var ru_text: String = String(row[CSV_COLUMN_RU])
			if not ru_text.is_empty():
				translations["ru"][key] = ru_text

	var output_file: FileAccess = FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if output_file == null:
		push_error("LocalizationDataGenerator: failed to open %s for writing" % OUTPUT_PATH)
		return false
	output_file.store_string(_render_script(translations))
	output_file.close()
	return true


static func _render_script(translations: Dictionary) -> String:
	var lines: PackedStringArray = []
	lines.append("extends RefCounted")
	lines.append("class_name LocalizationData")
	lines.append("")
	lines.append("# AUTO-GENERATED FILE — DO NOT EDIT BY HAND.")
	lines.append("# Generated from res://localization/game_text.csv")
	lines.append("# by res://scripts/tools/LocalizationDataGenerator.gd")
	lines.append("# Regenerate with: godot --headless --script res://scripts/tools/GenerateLocalizationData.gd")
	lines.append("")
	lines.append("static func get_translations() -> Dictionary:")
	lines.append("\treturn {")
	for language_code in SUPPORTED_LANGUAGES:
		lines.append("\t\t\"%s\": {" % language_code)
		var table: Dictionary = translations.get(language_code, {})
		for key in table.keys():
			lines.append("\t\t\t\"%s\": %s," % [key, _quote(String(table[key]))])
		lines.append("\t\t},")
	lines.append("\t}")
	lines.append("")
	return "\n".join(lines)


static func _quote(text: String) -> String:
	var escaped: String = text.replace("\\", "\\\\").replace("\"", "\\\"")
	return "\"%s\"" % escaped


static func _parse_csv(raw_text: String) -> Array:
	var rows: Array = []
	var normalized_text: String = raw_text.replace("\r\n", "\n").replace("\r", "\n")
	var lines: PackedStringArray = normalized_text.split("\n")
	for line in lines:
		if line.strip_edges().is_empty():
			continue
		rows.append(_parse_csv_line(line))
	return rows


static func _parse_csv_line(line: String) -> Array:
	var fields: Array = []
	var current_field: String = ""
	var in_quotes: bool = false
	var index: int = 0
	var length: int = line.length()
	while index < length:
		var character: String = line[index]
		if in_quotes:
			if character == "\"":
				if index + 1 < length and line[index + 1] == "\"":
					current_field += "\""
					index += 1
				else:
					in_quotes = false
			else:
				current_field += character
		else:
			if character == "\"":
				in_quotes = true
			elif character == ",":
				fields.append(current_field)
				current_field = ""
			else:
				current_field += character
		index += 1
	fields.append(current_field)
	return fields

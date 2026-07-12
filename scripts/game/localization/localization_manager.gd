extends Node

# Stage 66.1: Localization Foundation.
# Loads built-in translation data first, then overrides it with
# res://localization/game_text.csv if that file is present and readable.

signal language_changed

const LOCALIZATION_DATA_SCRIPT := preload("res://scripts/game/localization/localization_data.gd")

const CSV_PATH := "res://localization/game_text.csv"
const DEFAULT_LANGUAGE := "en"
const SUPPORTED_LANGUAGES: Array[String] = ["en", "ru"]

const CSV_COLUMN_KEY := 0
const CSV_COLUMN_EN := 1
const CSV_COLUMN_RU := 2

var _translations: Dictionary = {}
var _language: String = DEFAULT_LANGUAGE
var _csv_loaded: bool = false


func _ready() -> void:
	_load_built_in_data()
	_load_csv_override()


func tr_key(key: String) -> String:
	var current_table: Dictionary = _translations.get(_language, {})
	if current_table.has(key):
		var current_text: String = String(current_table[key])
		if not current_text.is_empty():
			return current_text
	var fallback_table: Dictionary = _translations.get(DEFAULT_LANGUAGE, {})
	if fallback_table.has(key):
		var fallback_text: String = String(fallback_table[key])
		if not fallback_text.is_empty():
			return fallback_text
	if OS.is_debug_build():
		push_warning("LocalizationManager: missing localization key '%s'" % key)
	return key


func format_key(key: String, values: Dictionary = {}) -> String:
	var text: String = tr_key(key)
	for placeholder_key in values.keys():
		var placeholder: String = "{%s}" % str(placeholder_key)
		text = text.replace(placeholder, str(values[placeholder_key]))
	return text


func set_language(language_code: String) -> void:
	var normalized: String = normalize_supported_language(language_code)
	if normalized == _language:
		return
	_language = normalized
	language_changed.emit()


func get_language() -> String:
	return _language


func get_available_languages() -> Array[String]:
	return SUPPORTED_LANGUAGES.duplicate()


func normalize_supported_language(language_code: String) -> String:
	var lowered: String = language_code.to_lower().strip_edges()
	if SUPPORTED_LANGUAGES.has(lowered):
		return lowered
	return DEFAULT_LANGUAGE


func has_loaded_translations() -> bool:
	return _csv_loaded


func get_loaded_translation_count(language_code: String = "en") -> int:
	var normalized: String = normalize_supported_language(language_code)
	var table: Dictionary = _translations.get(normalized, {})
	return table.size()


func _load_built_in_data() -> void:
	var built_in: Dictionary = LOCALIZATION_DATA_SCRIPT.get_translations()
	_translations = {}
	for language_code in SUPPORTED_LANGUAGES:
		var source_table: Dictionary = built_in.get(language_code, {})
		_translations[language_code] = source_table.duplicate()


func _load_csv_override() -> void:
	_csv_loaded = false
	if not FileAccess.file_exists(CSV_PATH):
		return
	var file: FileAccess = FileAccess.open(CSV_PATH, FileAccess.READ)
	if file == null:
		return
	var raw_text: String = file.get_as_text()
	file.close()
	var rows: Array = _parse_csv(raw_text)
	if rows.is_empty():
		return
	for row_index in range(1, rows.size()):
		var row: Array = rows[row_index]
		if row.size() <= CSV_COLUMN_EN:
			continue
		var key: String = String(row[CSV_COLUMN_KEY]).strip_edges()
		if key.is_empty():
			continue
		var en_text: String = String(row[CSV_COLUMN_EN])
		if not en_text.is_empty():
			_translations[DEFAULT_LANGUAGE][key] = en_text
		if row.size() > CSV_COLUMN_RU:
			var ru_text: String = String(row[CSV_COLUMN_RU])
			if not ru_text.is_empty():
				_translations["ru"][key] = ru_text
	_csv_loaded = true


func _parse_csv(raw_text: String) -> Array:
	var rows: Array = []
	var normalized_text: String = raw_text.replace("\r\n", "\n").replace("\r", "\n")
	var lines: PackedStringArray = normalized_text.split("\n")
	for line in lines:
		if line.strip_edges().is_empty():
			continue
		rows.append(_parse_csv_line(line))
	return rows


func _parse_csv_line(line: String) -> Array:
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

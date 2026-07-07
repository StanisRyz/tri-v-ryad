extends SceneTree

## Stage 59 v0.1: standalone QA tool — validates the already-generated
## deterministic 500-level layout database (data/levels/deterministic_level_layouts.json)
## without regenerating it, and writes the QA report
## (data/levels/deterministic_level_layout_report.json). Safe to run any time
## as a pure read-only check; never mutates the layout database. Run headless
## from the project root:
##   godot --headless --script res://tools/validate_deterministic_levels.gd

const LEVEL_LAYOUT_DATABASE_SCRIPT := preload("res://scripts/game/config/level_layout_database.gd")
const LEVEL_LAYOUT_VALIDATOR_SCRIPT := preload("res://scripts/game/config/level_layout_validator.gd")

const DATABASE_PATH := "res://data/levels/deterministic_level_layouts.json"
const REPORT_OUTPUT_PATH := "res://data/levels/deterministic_level_layout_report.json"


func _initialize() -> void:
	var database := LEVEL_LAYOUT_DATABASE_SCRIPT.new(DATABASE_PATH)
	var validator := LEVEL_LAYOUT_VALIDATOR_SCRIPT.new()
	var result := validator.build_report(database)

	_write_report(result)
	_print_summary(result)

	quit(0 if bool(result["valid"]) else 1)


func _write_report(result: Dictionary) -> void:
	var file := FileAccess.open(REPORT_OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open %s for writing (error %d)" % [REPORT_OUTPUT_PATH, FileAccess.get_open_error()])
		return
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print("Wrote QA report -> %s" % REPORT_OUTPUT_PATH)


func _print_summary(result: Dictionary) -> void:
	print("Validation: valid=%s total_levels=%d errors=%d warnings=%d review_candidates=%d" % [
		result["valid"], result["total_levels"], (result["errors"] as Array).size(), (result["warnings"] as Array).size(), (result["review_candidates"] as Array).size(),
	])
	print("Counts by archetype: %s" % [result["counts_by_archetype"]])
	print("Counts by variant: %s" % [result["counts_by_variant"]])
	print("Hole count stats: %s" % [result["hole_count_stats"]])
	print("Ice count stats: %s" % [result["ice_count_stats"]])
	print("Fallback layouts stored: %d" % int(result["fallback_layout_count"]))
	print("Duplicate layout warnings: %d" % (result["duplicate_layout_warnings"] as Array).size())

	for error_text in result["errors"]:
		printerr("  error: %s" % error_text)
	for warning_text in result["warnings"]:
		print("  warning: %s" % warning_text)
	for review_text in result["review_candidates"]:
		print("  review: %s" % review_text)

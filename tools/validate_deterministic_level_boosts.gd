extends SceneTree

## Stage 60.3 v0.1: standalone QA tool - validates the already-generated
## deterministic 500-level boost database
## (data/levels/deterministic_level_boosts.json) without regenerating it, and
## writes the QA report (data/levels/deterministic_level_boost_report.json).
## Safe to run any time as a pure read-only check; never mutates the boost
## database or any other gameplay file. Run headless from the project root:
##   godot --headless --script res://tools/validate_deterministic_level_boosts.gd

const LEVEL_BOOST_DATABASE_SCRIPT := preload("res://scripts/game/config/level_boost_database.gd")
const LEVEL_BOOST_DATABASE_VALIDATOR_SCRIPT := preload("res://scripts/game/config/level_boost_database_validator.gd")

const DATABASE_PATH := "res://data/levels/deterministic_level_boosts.json"
const REPORT_OUTPUT_PATH := "res://data/levels/deterministic_level_boost_report.json"


func _initialize() -> void:
	var database := LEVEL_BOOST_DATABASE_SCRIPT.new(DATABASE_PATH)
	var validator := LEVEL_BOOST_DATABASE_VALIDATOR_SCRIPT.new()
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
	print("Wrote boost QA report -> %s" % REPORT_OUTPUT_PATH)


func _print_summary(result: Dictionary) -> void:
	print("Validation: valid=%s total_levels=%d errors=%d warnings=%d" % [
		result["valid"], result["total_levels"], (result["errors"] as Array).size(), (result["warnings"] as Array).size(),
	])
	print("Counts by boost type: %s" % [result["counts_by_boost_type"]])
	print("Counts by color: %s" % [result["counts_by_color"]])

	for error_text in result["errors"]:
		printerr("  error: %s" % error_text)
	for warning_text in result["warnings"]:
		print("  warning: %s" % warning_text)

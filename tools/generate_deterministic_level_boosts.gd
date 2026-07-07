extends SceneTree

## Stage 60.3 v0.1: builds the deterministic 500-level boost database
## (data/levels/deterministic_level_boosts.json) using the fixed, predictable
## distribution rule: level % 3 == 1 -> color_damage_multiplier (tile color
## cycling red/blue/green/yellow/purple across those levels), level % 3 == 2
## -> large_match_multiplier (x2 at match 4, x3 at match 5+), level % 3 == 0
## -> extra_moves (+3). This script only writes the database file; it never
## runs as part of normal gameplay. Run headless from the project root:
##   godot --headless --script res://tools/generate_deterministic_level_boosts.gd

const LEVEL_BOOST_CONFIG_SCRIPT := preload("res://scripts/game/config/level_boost_config.gd")
const LEVEL_BOOST_DATABASE_SCRIPT := preload("res://scripts/game/config/level_boost_database.gd")
const LEVEL_BOOST_DATABASE_VALIDATOR_SCRIPT := preload("res://scripts/game/config/level_boost_database_validator.gd")

const TOTAL_LEVELS := 500
const GENERATOR_VERSION := "0.1"
const OUTPUT_PATH := "res://data/levels/deterministic_level_boosts.json"
const REPORT_OUTPUT_PATH := "res://data/levels/deterministic_level_boost_report.json"
const COLOR_CYCLE: Array[int] = [TileType.RED, TileType.BLUE, TileType.GREEN, TileType.YELLOW, TileType.PURPLE]


func _initialize() -> void:
	var levels: Array = []
	var color_index := 0

	for level_number in range(1, TOTAL_LEVELS + 1):
		var cycle_position := level_number % 3
		var boost: LevelBoostConfig
		match cycle_position:
			1:
				boost = LEVEL_BOOST_CONFIG_SCRIPT.color_damage(COLOR_CYCLE[color_index % COLOR_CYCLE.size()])
				color_index += 1
			2:
				boost = LEVEL_BOOST_CONFIG_SCRIPT.large_match()
			_:
				boost = LEVEL_BOOST_CONFIG_SCRIPT.extra_moves_boost()

		levels.append({
			"level_number": level_number,
			"boost": boost.to_dict(),
		})

	var database := {
		"version": "1.0",
		"generator_version": GENERATOR_VERSION,
		"level_count": TOTAL_LEVELS,
		"levels": levels,
	}

	var project_dir := DirAccess.open("res://")
	if project_dir != null:
		project_dir.make_dir_recursive("data/levels")

	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open %s for writing (error %d)" % [OUTPUT_PATH, FileAccess.get_open_error()])
		quit(1)
		return

	file.store_string(JSON.stringify(database, "\t"))
	file.close()

	print("Generated %d deterministic level boosts -> %s" % [levels.size(), OUTPUT_PATH])
	_validate_and_report()
	quit()


func _validate_and_report() -> void:
	var database := LEVEL_BOOST_DATABASE_SCRIPT.new(OUTPUT_PATH)
	var validator := LEVEL_BOOST_DATABASE_VALIDATOR_SCRIPT.new()
	var result := validator.build_report(database)

	_write_report(result)
	_print_summary(result)


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

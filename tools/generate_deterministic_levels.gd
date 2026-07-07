extends SceneTree

## Stage 58 v0.1: builds the deterministic 500-level layout database
## (data/levels/deterministic_level_layouts.json) by driving the existing
## procedural generators (BoardMaskGenerator for holes, IcePatternGenerator
## for ice) with stable, reproducible per-level seeds instead of the
## battle-time random seed. This script only writes the database file; it
## never runs as part of normal gameplay. Run headless from the project root:
##   godot --headless --script res://tools/generate_deterministic_levels.gd
##
## Preserves the existing ChallengeArchetypeResolver/IceVariantResolver
## 5-level cycle (1 normal, 2 ice weak, 3 holes, 4 ice strong, 5/0 holes) so
## the deterministic database matches what procedural generation would have
## produced for the same level/tier, just captured once instead of re-rolled
## every playthrough. Holes and ice are never mixed in this stage.

const BOARD_MASK_GENERATOR_SCRIPT := preload("res://scripts/game/board/board_mask_generator.gd")
const ICE_PATTERN_GENERATOR_SCRIPT := preload("res://scripts/game/board/ice_pattern_generator.gd")
const HOLE_GENERATION_RULES_SCRIPT := preload("res://scripts/game/config/hole_generation_rules.gd")
const ICE_GENERATION_RULES_SCRIPT := preload("res://scripts/game/config/ice_generation_rules.gd")
const DIFFICULTY_BUDGET_RESOLVER_SCRIPT := preload("res://scripts/game/config/difficulty_budget_resolver.gd")
const CHALLENGE_ARCHETYPE_SCRIPT := preload("res://scripts/game/config/challenge_archetype.gd")
const ICE_VARIANT_SCRIPT := preload("res://scripts/game/config/ice_variant.gd")
const LEVEL_LAYOUT_MASK_CODEC_SCRIPT := preload("res://scripts/game/config/level_layout_mask_codec.gd")
const LEVEL_LAYOUT_SCRIPT := preload("res://scripts/game/config/level_layout.gd")
const LEVEL_LAYOUT_DATABASE_SCRIPT := preload("res://scripts/game/config/level_layout_database.gd")
const LEVEL_LAYOUT_VALIDATOR_SCRIPT := preload("res://scripts/game/config/level_layout_validator.gd")

const TOTAL_LEVELS := 500
const GENERATOR_VERSION := "0.1"
const OUTPUT_PATH := "res://data/levels/deterministic_level_layouts.json"
## Deterministic per-level seed base. Only needs to be stable/reproducible
## per level_number, not globally unique in any cryptographic sense.
const BASE_SEED := 9_000_000
## A holes candidate occasionally falls back to a full board when no valid
## shape validates within its normal attempt budget; retrying with a
## different-but-still-deterministic seed (stride is a large prime so
## retried seeds stay well spread out) guarantees every holes level in the
## database actually has holes, per Stage 58's validation rules.
const MAX_HOLE_SEED_ATTEMPTS := 25
const HOLE_SEED_STRIDE := 104_729

var _board_mask_generator := BOARD_MASK_GENERATOR_SCRIPT.new()
var _ice_pattern_generator := ICE_PATTERN_GENERATOR_SCRIPT.new()
var _difficulty_budget_resolver := DIFFICULTY_BUDGET_RESOLVER_SCRIPT.new()


func _initialize() -> void:
	var levels: Array = []
	for level_number in range(1, TOTAL_LEVELS + 1):
		levels.append(_generate_level(level_number).to_dict())

	var database := {
		"version": "1.0",
		"board_size": 9,
		"generator_version": GENERATOR_VERSION,
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

	print("Generated %d deterministic level layouts -> %s" % [levels.size(), OUTPUT_PATH])
	_validate_and_report()
	quit()


func _validate_and_report() -> void:
	var database := LEVEL_LAYOUT_DATABASE_SCRIPT.new(OUTPUT_PATH)
	var validator := LEVEL_LAYOUT_VALIDATOR_SCRIPT.new()
	var result := validator.validate_database(database)

	print("Validation: valid=%s total_levels=%d errors=%d warnings=%d" % [
		result["valid"], result["total_levels"], (result["errors"] as Array).size(), (result["warnings"] as Array).size(),
	])
	print("Counts by archetype: %s" % [result["counts_by_archetype"]])
	print("Counts by variant: %s" % [result["counts_by_variant"]])

	for error_text in result["errors"]:
		printerr("  error: %s" % error_text)
	for warning_text in result["warnings"]:
		print("  warning: %s" % warning_text)


func _generate_level(level_number: int) -> LevelLayout:
	var cycle_position := level_number % 5
	var seed_value := BASE_SEED + level_number

	match cycle_position:
		1:
			return _build_normal_level(level_number, cycle_position, seed_value)
		2:
			return _build_ice_level(level_number, cycle_position, seed_value, ICE_VARIANT_SCRIPT.WEAK)
		3:
			return _build_holes_level(level_number, cycle_position, seed_value, "holes_a")
		4:
			return _build_ice_level(level_number, cycle_position, seed_value, ICE_VARIANT_SCRIPT.STRONG)
		_:
			return _build_holes_level(level_number, cycle_position, seed_value, "holes_b")


func _build_normal_level(level_number: int, cycle_position: int, seed_value: int) -> LevelLayout:
	var mask := _board_mask_generator.build_full_active_mask()
	var board_mask_string := LEVEL_LAYOUT_MASK_CODEC_SCRIPT.board_mask_to_string(mask)
	var ice_mask_string := LEVEL_LAYOUT_MASK_CODEC_SCRIPT.frozen_cells_to_ice_mask_string([])

	var metadata := _build_base_metadata(CHALLENGE_ARCHETYPE_SCRIPT.NORMAL, "default", cycle_position, seed_value)
	metadata["active_cell_count"] = 81
	metadata["hole_cell_count"] = 0
	metadata["ice_cell_count"] = 0
	metadata["weak_ice_cell_count"] = 0
	metadata["strong_ice_cell_count"] = 0
	metadata["fallback_used"] = false

	return LEVEL_LAYOUT_SCRIPT.new(level_number, CHALLENGE_ARCHETYPE_SCRIPT.NORMAL, "default", cycle_position, board_mask_string, ice_mask_string, seed_value, GENERATOR_VERSION, metadata)


func _build_ice_level(level_number: int, cycle_position: int, seed_value: int, ice_variant: String) -> LevelLayout:
	var difficulty_budget := _difficulty_budget_resolver.calculate_for_level(level_number)
	var tier: String = difficulty_budget.difficulty_tier
	var board_mask := _board_mask_generator.build_full_active_mask()

	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var rules := ICE_GENERATION_RULES_SCRIPT.for_tier(tier, ice_variant)
	var result := _ice_pattern_generator.generate_frozen_cells(rng, board_mask, difficulty_budget, rules)
	var frozen_cells: Array = result.get("frozen_cells", [])
	var generation_metadata: Dictionary = result.get("metadata", {})

	var board_mask_string := LEVEL_LAYOUT_MASK_CODEC_SCRIPT.board_mask_to_string(board_mask)
	var ice_mask_string := LEVEL_LAYOUT_MASK_CODEC_SCRIPT.frozen_cells_to_ice_mask_string(frozen_cells)

	var variant := "weak" if ice_variant == ICE_VARIANT_SCRIPT.WEAK else "strong"
	var metadata := _build_base_metadata(CHALLENGE_ARCHETYPE_SCRIPT.ICE, variant, cycle_position, seed_value)
	metadata["active_cell_count"] = 81
	metadata["hole_cell_count"] = 0
	metadata["ice_cell_count"] = int(generation_metadata.get("ice_cell_count", 0))
	metadata["weak_ice_cell_count"] = int(generation_metadata.get("weak_ice_cell_count", 0))
	metadata["strong_ice_cell_count"] = int(generation_metadata.get("strong_ice_cell_count", 0))
	metadata["fallback_used"] = bool(generation_metadata.get("ice_fallback_used", false))
	metadata["procedural_layout_source"] = String(generation_metadata.get("layout_source", ""))
	metadata["selected_shape_types"] = (generation_metadata.get("selected_ice_shape_types", []) as Array).duplicate()

	return LEVEL_LAYOUT_SCRIPT.new(level_number, CHALLENGE_ARCHETYPE_SCRIPT.ICE, variant, cycle_position, board_mask_string, ice_mask_string, seed_value, GENERATOR_VERSION, metadata)


func _build_holes_level(level_number: int, cycle_position: int, base_seed_value: int, variant: String) -> LevelLayout:
	var difficulty_budget := _difficulty_budget_resolver.calculate_for_level(level_number)
	var tier: String = difficulty_budget.difficulty_tier
	var rules := HOLE_GENERATION_RULES_SCRIPT.for_tier(tier)

	var used_seed := base_seed_value
	var mask: Array = _board_mask_generator.build_full_active_mask()
	var generation_metadata: Dictionary = {}

	for attempt in range(MAX_HOLE_SEED_ATTEMPTS):
		used_seed = base_seed_value + attempt * HOLE_SEED_STRIDE
		var rng := RandomNumberGenerator.new()
		rng.seed = used_seed
		var result := _board_mask_generator.generate_holes_mask_with_metadata(rng, difficulty_budget, rules)
		mask = result.get("mask", mask)
		generation_metadata = result.get("metadata", {})
		if not bool(generation_metadata.get("fallback_used", false)):
			break

	var board_mask_string := LEVEL_LAYOUT_MASK_CODEC_SCRIPT.board_mask_to_string(mask)
	var ice_mask_string := LEVEL_LAYOUT_MASK_CODEC_SCRIPT.frozen_cells_to_ice_mask_string([])

	var active_count := int(generation_metadata.get("active_cell_count", LEVEL_LAYOUT_MASK_CODEC_SCRIPT.count_char(board_mask_string, "1")))
	var hole_count := 81 - active_count

	var metadata := _build_base_metadata(CHALLENGE_ARCHETYPE_SCRIPT.HOLES, variant, cycle_position, used_seed)
	metadata["active_cell_count"] = active_count
	metadata["hole_cell_count"] = hole_count
	metadata["ice_cell_count"] = 0
	metadata["weak_ice_cell_count"] = 0
	metadata["strong_ice_cell_count"] = 0
	metadata["fallback_used"] = bool(generation_metadata.get("fallback_used", false))
	metadata["procedural_layout_source"] = String(generation_metadata.get("layout_source", ""))
	metadata["selected_shape_types"] = (generation_metadata.get("selected_shape_types", []) as Array).duplicate()

	return LEVEL_LAYOUT_SCRIPT.new(level_number, CHALLENGE_ARCHETYPE_SCRIPT.HOLES, variant, cycle_position, board_mask_string, ice_mask_string, used_seed, GENERATOR_VERSION, metadata)


func _build_base_metadata(archetype: String, variant: String, cycle_position: int, seed_value: int) -> Dictionary:
	return {
		"layout_source": "deterministic_database",
		"generator_version": GENERATOR_VERSION,
		"generation_seed": seed_value,
		"archetype": archetype,
		"variant": variant,
		"cycle_position": cycle_position,
	}

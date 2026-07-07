extends RefCounted
class_name LevelLayout

## Stage 58 v0.1: data model for one entry in the deterministic 500-level
## layout database (data/levels/deterministic_level_layouts.json). Board size
## is always 9x9 (81 cells). board_mask/ice_mask are the compact 81-character
## strings decoded by LevelLayoutMaskCodec; see that script for the exact
## encoding.

const LEVEL_LAYOUT_MASK_CODEC_SCRIPT := preload("res://scripts/game/config/level_layout_mask_codec.gd")

var level_number := 1
var archetype := ""
var variant := ""
var cycle_position := 0
var board_mask := ""
var ice_mask := ""
var generation_seed := 0
var generator_version := ""
var metadata: Dictionary = {}


func _init(
	config_level_number: int = 1,
	config_archetype: String = "",
	config_variant: String = "",
	config_cycle_position: int = 0,
	config_board_mask: String = "",
	config_ice_mask: String = "",
	config_generation_seed: int = 0,
	config_generator_version: String = "",
	config_metadata: Dictionary = {}
) -> void:
	level_number = config_level_number
	archetype = config_archetype
	variant = config_variant
	cycle_position = config_cycle_position
	board_mask = config_board_mask
	ice_mask = config_ice_mask
	generation_seed = config_generation_seed
	generator_version = config_generator_version
	metadata = config_metadata.duplicate(true)


static func from_dict(data: Dictionary) -> LevelLayout:
	var metadata_value = data.get("metadata", {})
	return LevelLayout.new(
		int(data.get("level_number", 1)),
		String(data.get("archetype", "")),
		String(data.get("variant", "")),
		int(data.get("cycle_position", 0)),
		String(data.get("board_mask", "")),
		String(data.get("ice_mask", "")),
		int(data.get("generation_seed", 0)),
		String(data.get("generator_version", "")),
		metadata_value if metadata_value is Dictionary else {}
	)


func to_dict() -> Dictionary:
	return {
		"level_number": level_number,
		"archetype": archetype,
		"variant": variant,
		"cycle_position": cycle_position,
		"board_mask": board_mask,
		"ice_mask": ice_mask,
		"generation_seed": generation_seed,
		"generator_version": generator_version,
		"metadata": metadata.duplicate(true),
	}


## Returns the GeneratedBoardChallenge.board_mask shape: an Array of 9 rows,
## each an Array of 9 bool values.
func get_board_mask_array() -> Array:
	return LEVEL_LAYOUT_MASK_CODEC_SCRIPT.board_mask_from_string(board_mask)


## Returns a frozen_cells array compatible with BoardModel.apply_frozen_cells().
func get_frozen_cells() -> Array:
	return LEVEL_LAYOUT_MASK_CODEC_SCRIPT.ice_mask_string_to_frozen_cells(ice_mask)

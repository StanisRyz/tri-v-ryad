extends RefCounted
class_name BoosterConfig

const TARGETING_NONE := "none"
const TARGETING_TARGET_CELL := "target_cell"

var booster_id := ""
var display_name := ""
var description := ""
var asset_key := ""
var uses_per_battle := 0
var targeting_mode := TARGETING_NONE


func _init(
	config_booster_id: String = "",
	config_display_name: String = "",
	config_description: String = "",
	config_asset_key: String = "",
	config_uses_per_battle: int = 0,
	config_targeting_mode: String = TARGETING_NONE
) -> void:
	booster_id = config_booster_id
	display_name = config_display_name
	description = config_description
	asset_key = config_asset_key
	uses_per_battle = config_uses_per_battle
	targeting_mode = config_targeting_mode


func is_targeted() -> bool:
	return targeting_mode == TARGETING_TARGET_CELL


func is_valid() -> bool:
	if booster_id == "":
		return false
	if display_name == "":
		return false
	if description == "":
		return false
	if asset_key == "":
		return false
	if uses_per_battle <= 0:
		return false
	return targeting_mode in [TARGETING_NONE, TARGETING_TARGET_CELL]

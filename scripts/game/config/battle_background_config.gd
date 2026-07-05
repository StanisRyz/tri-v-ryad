extends RefCounted
class_name BattleBackgroundConfig

var background_id := ""
var display_name := ""
var placeholder_color := Color.BLACK
var texture_path := ""


func _init(config_background_id: String = "", config_display_name: String = "", config_placeholder_color: Color = Color.BLACK, config_texture_path: String = "") -> void:
	background_id = config_background_id
	display_name = config_display_name
	placeholder_color = config_placeholder_color
	texture_path = config_texture_path

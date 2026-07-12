extends Control

## Stage 69.0: portrait-only orientation policy. Shows a full-screen
## rotate-device overlay whenever the viewport is wider than it is tall,
## and blocks input underneath it while visible.

const TEXT_STYLE_APPLIER_SCRIPT := preload("res://scripts/ui/text/text_style_applier.gd")
const MESSAGE_STYLE_ID := "orientation_guard.message"
const MESSAGE_KEY := "ui.orientation.rotate_device"

@onready var _message_label: Label = %MessageLabel


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	TEXT_STYLE_APPLIER_SCRIPT.apply_to_label(_message_label, MESSAGE_STYLE_ID)
	_refresh_message()
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	var localization_manager := get_node_or_null("/root/LocalizationManager")
	if localization_manager != null:
		localization_manager.language_changed.connect(_on_language_changed)
	_update_visibility()


func _on_viewport_size_changed() -> void:
	_update_visibility()


func _on_language_changed() -> void:
	_refresh_message()


func _refresh_message() -> void:
	var localization_manager := get_node_or_null("/root/LocalizationManager")
	if localization_manager != null:
		_message_label.text = localization_manager.tr_key(MESSAGE_KEY)


func _is_landscape() -> bool:
	var viewport_size := get_viewport().get_visible_rect().size
	return viewport_size.x > viewport_size.y


func _update_visibility() -> void:
	var landscape := _is_landscape()
	visible = landscape
	mouse_filter = Control.MOUSE_FILTER_STOP if landscape else Control.MOUSE_FILTER_IGNORE

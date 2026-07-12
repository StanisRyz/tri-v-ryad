extends RefCounted
class_name ScreenRouter

var _host: Control
var _current_screen: Node


func _init(host: Control) -> void:
	_host = host


## Stage 69.4: lets App refresh whichever screen is currently visible (e.g.
## after cloud reconciliation replaces local progress) without recreating it.
func get_current_screen() -> Node:
	return _current_screen if _current_screen != null and is_instance_valid(_current_screen) else null


func change_screen(screen_scene: PackedScene) -> Node:
	if _current_screen != null and is_instance_valid(_current_screen):
		_current_screen.queue_free()

	_current_screen = screen_scene.instantiate()
	_host.add_child(_current_screen)

	if _current_screen is Control:
		var control := _current_screen as Control
		control.set_anchors_preset(Control.PRESET_FULL_RECT)
		control.offset_left = 0.0
		control.offset_top = 0.0
		control.offset_right = 0.0
		control.offset_bottom = 0.0

	return _current_screen

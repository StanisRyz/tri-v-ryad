extends RefCounted
class_name LayoutManager

signal layout_changed(mode: int)

const PORTRAIT := 0
const LANDSCAPE := 1

var _viewport: Viewport
var _current_mode := PORTRAIT


func _init(viewport: Viewport) -> void:
	_viewport = viewport
	_current_mode = get_layout_mode()

	if _viewport != null:
		_viewport.size_changed.connect(_on_viewport_size_changed)


func get_layout_mode() -> int:
	if _viewport == null:
		return PORTRAIT

	var viewport_size := _viewport.get_visible_rect().size
	return LANDSCAPE if viewport_size.x > viewport_size.y else PORTRAIT


func is_portrait() -> bool:
	return get_layout_mode() == PORTRAIT


func is_landscape() -> bool:
	return get_layout_mode() == LANDSCAPE


func _on_viewport_size_changed() -> void:
	var new_mode := get_layout_mode()
	if new_mode == _current_mode:
		return

	_current_mode = new_mode
	layout_changed.emit(_current_mode)

extends Button
class_name TileView

signal tile_pressed(cell: Vector2i)

const TILE_COLORS := {
	TileType.RED: Color(0.86, 0.22, 0.22, 1.0),
	TileType.BLUE: Color(0.18, 0.42, 0.88, 1.0),
	TileType.GREEN: Color(0.16, 0.66, 0.36, 1.0),
	TileType.YELLOW: Color(0.92, 0.76, 0.20, 1.0),
	TileType.PURPLE: Color(0.56, 0.28, 0.82, 1.0),
}

var board_cell := Vector2i.ZERO
var tile_type := BoardModel.EMPTY
var _is_selected := false


func _ready() -> void:
	custom_minimum_size = Vector2(48, 48)
	focus_mode = Control.FOCUS_NONE
	if not pressed.is_connected(_on_pressed):
		pressed.connect(_on_pressed)
	_apply_visuals()


func set_tile(cell: Vector2i, new_tile_type: int) -> void:
	board_cell = cell
	tile_type = new_tile_type
	_apply_visuals()


func set_selected(selected: bool) -> void:
	_is_selected = selected
	_apply_visuals()


func _on_pressed() -> void:
	tile_pressed.emit(board_cell)


func _apply_visuals() -> void:
	var base_color: Color = TILE_COLORS.get(tile_type, Color(0.20, 0.22, 0.26, 1.0))
	var style := StyleBoxFlat.new()
	style.bg_color = base_color.lightened(0.18) if _is_selected else base_color
	style.border_width_left = 4 if _is_selected else 1
	style.border_width_top = 4 if _is_selected else 1
	style.border_width_right = 4 if _is_selected else 1
	style.border_width_bottom = 4 if _is_selected else 1
	style.border_color = Color(1.0, 1.0, 1.0, 1.0) if _is_selected else Color(0.05, 0.06, 0.08, 0.8)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	add_theme_stylebox_override("normal", style)
	add_theme_stylebox_override("hover", style)
	add_theme_stylebox_override("pressed", style)
	text = ""

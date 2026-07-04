extends Control

const COLUMNS := 9
const ROWS := 9
const HERO_LANE_WIDTH := 3

var _lane_colors: Array[Color] = [
	Color(0.16, 0.34, 0.64, 0.32),
	Color(0.18, 0.50, 0.34, 0.32),
	Color(0.62, 0.30, 0.24, 0.32),
]


func _ready() -> void:
	custom_minimum_size = Vector2(560, 560)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	var board_size: float = minf(size.x, size.y)
	var origin: Vector2 = (size - Vector2.ONE * board_size) * 0.5
	var cell_size: float = board_size / float(COLUMNS)
	var board_rect := Rect2(origin, Vector2.ONE * board_size)

	draw_rect(board_rect, Color(0.06, 0.08, 0.12, 1.0), true)

	for lane_index in range(3):
		var lane_rect := Rect2(
			origin + Vector2(cell_size * HERO_LANE_WIDTH * lane_index, 0.0),
			Vector2(cell_size * HERO_LANE_WIDTH, board_size)
		)
		draw_rect(lane_rect, _lane_colors[lane_index], true)

	for column in range(COLUMNS + 1):
		var x: float = origin.x + cell_size * column
		var is_lane_separator := column == 3 or column == 6
		var is_outer_edge := column == 0 or column == COLUMNS
		var line_width := 4.0 if is_lane_separator or is_outer_edge else 1.0
		var line_color := Color(0.96, 0.98, 1.0, 0.95) if is_lane_separator or is_outer_edge else Color(0.96, 0.98, 1.0, 0.36)
		draw_line(Vector2(x, origin.y), Vector2(x, origin.y + board_size), line_color, line_width)

	for row in range(ROWS + 1):
		var y: float = origin.y + cell_size * row
		var line_width := 3.0 if row == 0 or row == ROWS else 1.0
		var line_color := Color(0.96, 0.98, 1.0, 0.95) if row == 0 or row == ROWS else Color(0.96, 0.98, 1.0, 0.36)
		draw_line(Vector2(origin.x, y), Vector2(origin.x + board_size, y), line_color, line_width)

	_draw_lane_labels(origin, cell_size, board_size)


func _draw_lane_labels(origin: Vector2, cell_size: float, board_size: float) -> void:
	var labels := ["Hero 1\nCols 1-3", "Hero 2\nCols 4-6", "Hero 3\nCols 7-9"]
	var font := ThemeDB.fallback_font
	var font_size := 18

	for lane_index in range(3):
		var center_x := origin.x + cell_size * (float(lane_index) * HERO_LANE_WIDTH + 1.5)
		var label_position := Vector2(center_x - 52.0, origin.y + board_size - 44.0)
		draw_multiline_string(font, label_position, labels[lane_index], HORIZONTAL_ALIGNMENT_CENTER, 104.0, font_size, 2, Color(1.0, 1.0, 1.0, 0.88))

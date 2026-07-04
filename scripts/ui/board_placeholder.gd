extends Control

const COLUMNS := 9
const ROWS := 9
const HERO_LANE_WIDTH := 3

var _lane_colors: Array[Color] = [
	Color(0.18, 0.33, 0.58, 0.35),
	Color(0.20, 0.48, 0.36, 0.35),
	Color(0.58, 0.28, 0.26, 0.35),
]


func _ready() -> void:
	custom_minimum_size = Vector2(560, 560)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	var board_size: float = minf(size.x, size.y)
	var origin: Vector2 = (size - Vector2.ONE * board_size) * 0.5
	var cell: float = board_size / float(COLUMNS)
	var board_rect := Rect2(origin, Vector2.ONE * board_size)

	for lane_index in range(3):
		var lane_rect := Rect2(
			origin + Vector2(cell * HERO_LANE_WIDTH * lane_index, 0.0),
			Vector2(cell * HERO_LANE_WIDTH, board_size)
		)
		draw_rect(lane_rect, _lane_colors[lane_index], true)

	draw_rect(board_rect, Color(0.92, 0.95, 1.0, 0.9), false, 3.0)

	for column in range(COLUMNS + 1):
		var x: float = origin.x + cell * column
		var line_width := 3.0 if column % HERO_LANE_WIDTH == 0 else 1.0
		var line_color := Color(0.88, 0.91, 0.96, 1.0) if column % HERO_LANE_WIDTH == 0 else Color(0.88, 0.91, 0.96, 0.55)
		draw_line(Vector2(x, origin.y), Vector2(x, origin.y + board_size), line_color, line_width)

	for row in range(ROWS + 1):
		var y: float = origin.y + cell * row
		draw_line(Vector2(origin.x, y), Vector2(origin.x + board_size, y), Color(0.88, 0.91, 0.96, 0.55), 1.0)

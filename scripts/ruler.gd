extends Node2D
class_name Ruler

var ground_y: float = 0.0
var step_height: float = 64.0
var count: int = 50
var tick_length: float = 14.0
var line_color: Color = Color(1, 1, 1, 0.6)
var font_size: int = 16

func configure(new_ground_y: float, new_step_height: float, new_count: int) -> void:
	ground_y = new_ground_y
	step_height = new_step_height
	count = new_count
	queue_redraw()

func _draw() -> void:
	if step_height <= 0.0:
		return
	var font: Font = ThemeDB.fallback_font
	for i in range(count + 1):
		var y: float = ground_y - i * step_height
		draw_line(Vector2(0, y), Vector2(tick_length, y), line_color, 2.0)
		draw_string(font, Vector2(tick_length + 6, y + font_size / 2.0 - 2), str(i), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, line_color)

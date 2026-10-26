extends Control

var level := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(240, 28)

func _draw() -> void:
	for i in range(24):
		var rect := Rect2(i * size.x / 24.0, 0, size.x / 24.0 - 3, size.y)
		draw_rect(rect, Color("263343"))
		var color := Color("4cdb92")
		if i >= 15: color = Color("f4cf58")
		if i >= 20: color = Color("f46a65")
		var fill := clampf(level * 24.0 - i, 0.0, 1.0)
		rect.size.x *= fill
		draw_rect(rect, color)

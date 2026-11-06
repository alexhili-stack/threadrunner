class_name ThreadMeter
extends Control

var value: float = 0.0:
	set(amount):
		value = clampf(amount, 0, 100)
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), ThreadStyle.LINE)
	if value > 0:
		draw_rect(Rect2(Vector2.ZERO, Vector2(size.x * value / 100, size.y)), ThreadStyle.THREAD)

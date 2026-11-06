extends Control

var mode: String = "hero"
var clock: float = 0.0
var reduced_effects: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	if not reduced_effects:
		clock += delta
		queue_redraw()


func _draw() -> void:
	if mode == "diamond":
		draw_colored_polygon(
			PackedVector2Array([Vector2(4, 0), Vector2(8, 4), Vector2(4, 8), Vector2(0, 4)]),
			ThreadStyle.GOLD
		)
		return
	var points: PackedVector2Array = PackedVector2Array()
	if mode == "hero":
		for i in 121:
			var t: float = float(i) / 120.0
			var y: float = 140 + sin(t * TAU * 1.15 - 0.8) * 43
			y += sin(t * PI) * sin(clock * 0.45) * 3
			points.append(Vector2(42 + t * 220, y))
		draw_polyline(points, ThreadStyle.THREAD, 3, true)
		# A still frame of the in-game courier, enlarged with the same visual grammar.
		var pose: Transform2D = Transform2D(-0.13, Vector2(42, 140))
		draw_circle(pose * (Vector2(2, -8) * 4.4), 14.52, ThreadStyle.PAPER, true, -1, true)
		_limb(PackedVector2Array([Vector2(2, -4), Vector2(0, 3), Vector2(-6, 9)]), pose, 2.1)
		_limb(PackedVector2Array([Vector2(0, 3), Vector2(5, 5), Vector2(9, 0)]), pose, 1.8)
		_limb(PackedVector2Array([Vector2(1, -2), Vector2(5, 0), Vector2(8, -4)]), pose, 1.5)
		_limb(PackedVector2Array([Vector2(1, -2), Vector2(-4, -3), Vector2(-7, 0)]), pose, 1.5)
		draw_line(Vector2(-8, 209), Vector2(95, 209), ThreadStyle.PAPER, 1.5, true)
		draw_line(Vector2(145, 237), Vector2(271, 237), ThreadStyle.LINE, 1, true)
		return
	for strand in 2:
		points.clear()
		for i in 97:
			var t: float = float(i) / 96.0 * TAU
			points.append(Vector2(72, 72) + Vector2(sin(t + strand * PI) * 47, sin(t * 2) * 27))
		draw_polyline(points, Color(ThreadStyle.THREAD, 0.8 if strand == 0 else 0.28), 2, true)
	draw_circle(Vector2(72, 72), 4, ThreadStyle.PAPER)


func _limb(points: PackedVector2Array, pose: Transform2D, width: float) -> void:
	for i in points.size():
		points[i] = pose * (points[i] * 4.4)
	draw_polyline(points, ThreadStyle.PAPER, width * 4.4, true)
	for point: Vector2 in points:
		draw_circle(point, width * 2.2, ThreadStyle.PAPER, true, -1, true)

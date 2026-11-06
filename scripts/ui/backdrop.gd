extends Node2D

var chapter: int = 0
var menu_mode: bool = true
var reduced_effects: bool = false


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var bases: Array[Color] = [
		Color("09171e"), Color("0b1c23"), Color("201d23"), Color("171d2d"), Color("242329")
	]
	var trims: Array[Color] = [
		Color("213941"), Color("23444a"), Color("51413b"), Color("393b58"), Color("655748")
	]
	var palette: int = 0 if menu_mode else mini(chapter, 4)
	var trim: Color = trims[palette]
	draw_rect(Rect2(0, 0, 640, 360), bases[palette])
	if chapter == 0 or menu_mode:
		draw_polygon(
			PackedVector2Array(
				[Vector2(318, 0), Vector2(640, 0), Vector2(640, 360), Vector2(448, 360)]
			),
			PackedColorArray([Color("0d222a")])
		)
		draw_line(Vector2(318, 0), Vector2(448, 360), Color(trim, 0.5), 1, true)
		return
	for x in [86, 310, 552]:
		draw_rect(Rect2(x, 72, 34, 254), Color(trim, 0.16))
		draw_line(Vector2(x, 76), Vector2(x, 326), Color(trim, 0.28), 1)
	if chapter == 1:
		for i in 3:
			var y: float = 121 + i * 82
			draw_polyline(
				PackedVector2Array(
					[Vector2(0, y), Vector2(96, y), Vector2(130, y + 23), Vector2(640, y + 23)]
				),
				Color(trim, 0.33),
				1,
				true
			)
	elif chapter == 2:
		# Solid mechanism silhouettes cannot be mistaken for toothed coral saws.
		for i in 3:
			var center: Vector2 = Vector2(110 + i * 229, 148 + (i % 2) * 70)
			draw_circle(center, 52, Color(trim, 0.15))
			draw_arc(center, 39, 0, TAU, 48, Color(trim, 0.25), 1, true)
			draw_line(center - Vector2(0, 52), center + Vector2(0, 52), Color(trim, 0.2), 2)
	else:
		var horizon: Color = Color("62566b") if chapter == 3 else Color("9b7961")
		for i in 6:
			var y: float = 180 + i * 25
			draw_rect(Rect2(0, y, 640, 25), Color(horizon, 0.012 + i * 0.005))
		for i in 4:
			var x: float = 170 + i * 150
			draw_line(Vector2(x, 75), Vector2(x, 300), Color(trim, 0.35), 1)
			draw_line(Vector2(x - 24, 114), Vector2(x + 24, 114), Color(horizon, 0.18), 1)

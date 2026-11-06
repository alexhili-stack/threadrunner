extends Node2D
## Presentation only. Hazard cores and collision bounds remain in LevelRoot.

const HAZE: Texture2D = preload("res://assets/art/foundry/electric_haze.png")
var room: LevelRoot


func _ready() -> void:
	room = get_parent()
	z_index = -1


func _process(_delta: float) -> void:
	queue_redraw()


func mist(rect: Rect2, tint: Color, strength: float = 0.4) -> void:
	var breath: float = 0.92 + sin(room.elapsed * 0.8 + rect.position.x * 0.01) * 0.08
	draw_texture_rect(HAZE, rect, false, Color(tint, strength * breath))


func _draw() -> void:
	if not is_instance_valid(room) or room.reduced_effects:
		return
	for rect: Rect2 in room.spikes:
		mist(
			Rect2(rect.position - Vector2(10, 42), Vector2(rect.size.x + 20, 46)),
			ThreadStyle.DANGER
		)
	for rect: Rect2 in room.ceiling_spikes:
		mist(
			Rect2(rect.position - Vector2(8, 4), rect.size + Vector2(16, 28)),
			ThreadStyle.DANGER,
			0.3
		)
	for point: Vector2 in room.mover_positions:
		mist(Rect2(point - Vector2(36, 38), Vector2(72, 72)), ThreadStyle.SAW, 0.5)
	for rect: Rect2 in room.gates:
		if not room.gate_is_open():
			mist(
				Rect2(rect.position - Vector2(24, 8), rect.size + Vector2(48, 16)),
				ThreadStyle.DANGER
			)
	for rect: Rect2 in room.vents:
		if room.vent_is_active():
			mist(
				Rect2(rect.position - Vector2(10, 10), rect.size + Vector2(20, 14)),
				ThreadStyle.HEAT,
				0.65
			)

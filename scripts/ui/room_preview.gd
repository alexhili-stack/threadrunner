extends Control

var room_index: int = 0
var geometry: Array[Rect2] = []
var hazards: Array[Rect2] = []
var teeth: Array[Rect2] = []
var beams: Array[Rect2] = []
var fragment: Vector2
var exit_position: Vector2
var spawn: Vector2
var world_size: Vector2
var movers: Array[Vector4] = []
var anchors: Array[Vector2] = []
var stitch_pairs: Array[Vector4] = []


func set_room(index: int) -> void:
	room_index = index
	var room: LevelRoot = LevelCatalog.entry(index).scene.instantiate()
	geometry = room.platforms.duplicate()
	hazards = room.spikes.duplicate()
	hazards.append_array(room.vents)
	teeth = room.ceiling_spikes.duplicate()
	beams = room.gates.duplicate()
	fragment = room.fragment_position
	exit_position = room.exit_position
	spawn = room.spawn
	world_size = room.world_size
	movers = room.movers.duplicate()
	anchors = room.thread_anchors.duplicate()
	stitch_pairs = room.stitch_pairs.duplicate()
	room.free()
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), ThreadStyle.INK)
	if world_size.x <= 0:
		return
	var factor: float = minf((size.x - 12) / world_size.x, (size.y - 12) / world_size.y)
	var scale_factor: Vector2 = Vector2.ONE * factor
	var origin: Vector2 = (size - world_size * factor) * 0.5
	draw_set_transform(origin)
	for rect: Rect2 in geometry:
		draw_rect(
			Rect2(rect.position * scale_factor, rect.size * scale_factor), ThreadStyle.SECONDARY
		)
	for rect: Rect2 in hazards + teeth:
		draw_rect(Rect2(rect.position * scale_factor, rect.size * scale_factor), ThreadStyle.DANGER)
	for rect: Rect2 in beams:
		draw_rect(Rect2(rect.position * scale_factor, rect.size * scale_factor), ThreadStyle.DANGER)
	for mover: Vector4 in movers:
		draw_line(
			Vector2(mover.x, mover.y) * factor,
			Vector2(mover.x, mover.y + mover.z) * factor,
			Color(ThreadStyle.DANGER, 0.4),
			1
		)
		draw_circle(
			Vector2(mover.x, mover.y) * factor, maxf(2, 16 * factor), ThreadStyle.DANGER, false, 1
		)
	var f: Vector2 = fragment * scale_factor
	for anchor: Vector2 in anchors:
		draw_circle(anchor * factor, 1.8, ThreadStyle.THREAD, false, 1)
	for pair: Vector4 in stitch_pairs:
		var from: Vector2 = Vector2(pair.x, pair.y) * factor
		var to: Vector2 = Vector2(pair.z, pair.w) * factor
		draw_line(from, to, Color(ThreadStyle.THREAD, 0.35), 1)
		draw_rect(Rect2(from - Vector2.ONE * 2, Vector2.ONE * 4), ThreadStyle.THREAD, false, 1)
		draw_rect(Rect2(to - Vector2.ONE * 2, Vector2.ONE * 4), ThreadStyle.THREAD, false, 1)
	draw_colored_polygon(
		PackedVector2Array(
			[f + Vector2(0, -3), f + Vector2(2, 0), f + Vector2(0, 3), f + Vector2(-2, 0)]
		),
		ThreadStyle.GOLD
	)
	draw_circle(spawn * scale_factor, 2, ThreadStyle.PAPER)
	draw_rect(
		Rect2((exit_position - Vector2(10, 18)) * scale_factor, Vector2(20, 36) * scale_factor),
		ThreadStyle.THREAD,
		false,
		1
	)
	draw_set_transform(Vector2.ZERO)
	for corner: Vector2 in [Vector2.ZERO, Vector2(size.x, 0), size, Vector2(0, size.y)]:
		var direction: Vector2 = Vector2(1 if corner.x == 0 else -1, 1 if corner.y == 0 else -1)
		draw_line(corner, corner + Vector2(direction.x * 10, 0), ThreadStyle.LINE, 1)
		draw_line(corner, corner + Vector2(0, direction.y * 10), ThreadStyle.LINE, 1)

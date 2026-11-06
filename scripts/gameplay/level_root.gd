class_name LevelRoot
extends Node2D

@export var level_id: String = ""
@export var spawn: Vector2 = Vector2(40, 317)
@export var exit_position: Vector2 = Vector2(600, 308)
@export var fragment_position: Vector2 = Vector2(320, 240)
@export var platforms: Array[Rect2] = []
@export var spikes: Array[Rect2] = []
@export var ceiling_spikes: Array[Rect2] = []
@export var vents: Array[Rect2] = []
@export var vent_period: float = 3.8
@export var movers: Array[Vector4] = []
@export var gates: Array[Rect2] = []
@export var gate_period: float = 2.8
@export var gate_open_time: float = 1.5
@export var route: Array[Vector2] = []
@export var purpose: String = ""
@export var chapter: int = 1
@export var required_skill: String = "jump"
@export var route_markers: Array[Vector2] = []
@export var world_size: Vector2 = Vector2(640, 360)
@export var thread_anchors: Array[Vector2] = []
@export var stitch_pairs: Array[Vector4] = []
@export var thread_goal: String = ""
@export var thread_checkpoint: Vector2 = Vector2(-1, -1)
var thread_tool: ThreadTool
var player: PlayerController
var elapsed: float = 0.0
var fragment_collected: bool = false
var mover_positions: Array[Vector2] = []
var decorative_time: float = 0.0
var reduced_effects: bool = false
var camera: Camera2D
var fragment_pulse: float = 0.0
var exit_pulse: float = 0.0


func _ready() -> void:
	for rect: Rect2 in platforms:
		var body: StaticBody2D = StaticBody2D.new()
		var collision: CollisionShape2D = CollisionShape2D.new()
		var shape: RectangleShape2D = RectangleShape2D.new()
		shape.size = rect.size
		collision.shape = shape
		body.position = rect.get_center()
		body.add_child(collision)
		add_child(body)
	player = preload("res://scenes/player/player.tscn").instantiate()
	player.name = "Player"
	add_child(player)
	if world_size.x > 640 or world_size.y > 360:
		camera = Camera2D.new()
		camera.position_smoothing_enabled = false
		camera.limit_left = 0
		camera.limit_top = 0
		camera.limit_right = int(world_size.x)
		camera.limit_bottom = int(world_size.y)
		player.add_child(camera)
	thread_tool = ThreadTool.new()
	thread_tool.name = "ThreadTool"
	add_child(thread_tool)
	thread_tool.setup(self)
	reset_for_attempt()


func reset_for_attempt() -> void:
	elapsed = 0.0
	fragment_collected = false
	fragment_pulse = 0.0
	exit_pulse = 0.0
	player.reset_for_attempt(spawn)
	if is_instance_valid(thread_tool):
		thread_tool.reset()
	update_hazards()
	queue_redraw()


func advance(delta: float) -> void:
	elapsed += delta
	update_hazards()
	queue_redraw()


func update_hazards() -> void:
	mover_positions.clear()
	for mover: Vector4 in movers:
		var phase: float = (sin(elapsed * TAU / mover.w - PI / 2.0) + 1.0) * 0.5
		mover_positions.append(Vector2(mover.x, mover.y + phase * mover.z))


func gate_is_open() -> bool:
	if is_instance_valid(thread_tool) and thread_tool.relay_powered():
		return true
	return fmod(elapsed, gate_period) < gate_open_time


func vent_is_warning() -> bool:
	var phase: float = fmod(elapsed, vent_period)
	return phase >= 2.0 and phase < 2.6


func vent_is_active() -> bool:
	return fmod(elapsed, vent_period) >= 2.6


func _process(delta: float) -> void:
	if fragment_pulse > 0 or exit_pulse > 0:
		fragment_pulse = maxf(0, fragment_pulse - delta)
		exit_pulse = maxf(0, exit_pulse - delta)
		queue_redraw()


func lethal_at_player() -> bool:
	var hitbox: Rect2 = Rect2(player.position - Vector2(4, 9), Vector2(8, 18))
	if (
		player.position.y > world_size.y + 20
		or player.position.x < 8.0
		or player.position.x > world_size.x - 8
	):
		return true
	if rect_hazard_overlap(hitbox, spikes, 2.0) or rect_hazard_overlap(hitbox, ceiling_spikes, 1.0):
		return true
	if vent_is_active():
		for rect: Rect2 in vents:
			if hitbox.intersects(rect.grow(-2.0)):
				return true
	for point: Vector2 in mover_positions:
		if hitbox.get_center().distance_to(point) < 16.0:
			return true
	if not gate_is_open():
		for rect: Rect2 in gates:
			if hitbox.intersects(rect.grow(-1.0)):
				return true
	return false


func rect_hazard_overlap(hitbox: Rect2, hazards: Array[Rect2], inset: float) -> bool:
	for rect: Rect2 in hazards:
		if hitbox.intersects(rect.grow(-inset)):
			return true
	return false


func at_exit() -> bool:
	return (
		Rect2(exit_position - Vector2(13, 20), Vector2(26, 40)).has_point(player.position)
		and (not is_instance_valid(thread_tool) or thread_tool.goal_met())
	)


func touching_fragment() -> bool:
	return not fragment_collected and player.position.distance_to(fragment_position) < 17.0


func _draw() -> void:
	var pale: Color = Color("b9cecc")
	for rect: Rect2 in platforms:
		draw_rect(rect, Color("1b343d"))
		draw_line(rect.position, rect.position + Vector2(rect.size.x, 0), pale, 1.5)
		draw_line(rect.position, Vector2(rect.position.x, rect.end.y), Color("42606a"), 1)
		draw_line(Vector2(rect.end.x, rect.position.y), rect.end, Color("42606a"), 1)
		if rect.size.x > 40:
			draw_line(
				rect.position + Vector2(4, 4), rect.position + Vector2(12, 4), Color("37535d"), 1
			)
			draw_line(
				Vector2(rect.end.x - 12, rect.position.y + 4),
				Vector2(rect.end.x - 4, rect.position.y + 4),
				Color("37535d"),
				1
			)
	for rect: Rect2 in spikes:
		for x: int in range(int(rect.position.x), int(rect.end.x), 8):
			draw_colored_polygon(
				PackedVector2Array(
					[
						Vector2(x, rect.end.y),
						Vector2(x + 4, rect.position.y),
						Vector2(x + 8, rect.end.y)
					]
				),
				ThreadStyle.DANGER
			)
	for rect: Rect2 in ceiling_spikes:
		for x: int in range(int(rect.position.x), int(rect.end.x), 8):
			draw_colored_polygon(
				PackedVector2Array(
					[
						Vector2(x, rect.position.y),
						Vector2(x + 4, rect.end.y),
						Vector2(x + 8, rect.position.y)
					]
				),
				ThreadStyle.DANGER
			)
	for marker: Vector2 in route_markers:
		var direction: float = -1.0 if marker.y > 200 and marker.y < 270 else 1.0
		var color: Color = Color(0.25, 0.85, 0.76, 0.25)
		draw_polyline(
			PackedVector2Array(
				[marker + Vector2(-4 * direction, -3), marker, marker + Vector2(-4 * direction, 3)]
			),
			color,
			1.0,
			true
		)
	for mover: Vector4 in movers:
		var start: Vector2 = Vector2(mover.x, mover.y)
		var end: Vector2 = start + Vector2(0, mover.z)
		draw_line(start, end, Color(ThreadStyle.DANGER, 0.23), 1, true)
		draw_circle(start, 2, Color(ThreadStyle.DANGER, 0.4), false, 1, true)
		draw_circle(end, 2, Color(ThreadStyle.DANGER, 0.4), false, 1, true)
	for point: Vector2 in mover_positions:
		var teeth: PackedVector2Array = PackedVector2Array()
		for i in 24:
			var angle: float = float(i) * TAU / 24.0 + elapsed * 2.0
			teeth.append(point + Vector2.from_angle(angle) * (16 if i % 2 == 0 else 10.5))
		draw_colored_polygon(teeth, Color("663c3e"))
		teeth.append(teeth[0])
		draw_polyline(teeth, ThreadStyle.DANGER, 1.5, true)
		draw_circle(point, 4, ThreadStyle.DANGER, false, 1.5, true)
		draw_circle(point, 1.3, ThreadStyle.PAPER)
	for vent: Rect2 in vents:
		var active: bool = vent_is_active()
		var warning: bool = vent_is_warning()
		var tint: Color = (
			ThreadStyle.DANGER if active else ThreadStyle.GOLD if warning else Color("8bafbc")
		)
		draw_line(Vector2(vent.position.x, vent.end.y - 2), vent.end - Vector2(0, 2), tint, 3)
		for x in range(int(vent.position.x) + 4, int(vent.end.x), 8):
			draw_line(Vector2(x, vent.end.y - 6), Vector2(x + 3, vent.end.y - 3), tint, 1)
			if active:
				draw_polyline(
					PackedVector2Array(
						[
							Vector2(x, vent.end.y - 7),
							Vector2(x - 2, vent.position.y + 10),
							Vector2(x + 2, vent.position.y)
						]
					),
					Color(tint, 0.7),
					2,
					true
				)
		if warning:
			draw_circle(Vector2(vent.get_center().x, vent.end.y - 11), 3, tint)
	for rect: Rect2 in gates:
		var open: bool = gate_is_open()
		draw_rect(rect, Color(0.25, 0.85, 0.76, 0.07) if open else Color(1, 0.35, 0.3, 0.22))
		var closing: bool = (
			open
			and not thread_tool.relay_powered()
			and fmod(elapsed, gate_period) > gate_open_time - 0.4
		)
		var color: Color = (
			ThreadStyle.GOLD if closing else ThreadStyle.THREAD if open else ThreadStyle.DANGER
		)
		draw_line(rect.position, rect.position + Vector2(rect.size.x, 0), color, 3.0)
		draw_line(Vector2(rect.position.x, rect.end.y), rect.end, color, 3.0)
		if not open:
			for y: int in range(int(rect.position.y) + 6, int(rect.end.y), 10):
				var bottom: float = minf(y + 7, rect.end.y)
				draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, bottom), color, 1.0)
				draw_line(Vector2(rect.end.x, y), Vector2(rect.position.x, bottom), color, 1.0)
		var fraction: float = (
			1.0 if thread_tool.relay_powered() else fmod(elapsed, gate_period) / gate_period
		)
		draw_line(
			rect.position - Vector2(10, 8), rect.position + Vector2(20, -8), Color("25424d"), 2.0
		)
		draw_line(
			rect.position - Vector2(10, 8),
			rect.position + Vector2(-10 + fraction * 30, -8),
			color,
			2.0
		)
	var e: Vector2 = exit_position
	var exit_tint: Color = ThreadStyle.THREAD if thread_tool.goal_met() else ThreadStyle.SECONDARY
	draw_rect(Rect2(e - Vector2(12, 20), Vector2(24, 40)), Color(exit_tint, 0.07))
	for side in [-1, 1]:
		var x: float = side * 12
		draw_polyline(
			PackedVector2Array(
				[e + Vector2(x, 20), e + Vector2(x, -20), e + Vector2(x - side * 7, -20)]
			),
			exit_tint,
			2,
			true
		)
		draw_line(e + Vector2(x, 20), e + Vector2(x - side * 6, 20), ThreadStyle.PAPER, 1.5)
	var knot: PackedVector2Array = PackedVector2Array()
	for i in 33:
		var t: float = float(i) / 32 * TAU
		knot.append(e + Vector2(sin(t) * 7, sin(t * 2) * 4))
	draw_polyline(knot, exit_tint, 1.5, true)
	if not thread_tool.goal_met():
		var objective: String = (
			{
				"stitch": "STITCH",
				"relay": "RELAY",
				"grapple": "SWING",
				"rewind": "REWIND",
				"all": "WEAVE"
			}
			. get(thread_goal, "")
		)
		draw_string(
			ThreadStyle.DISPLAY,
			e + Vector2(-14, -26),
			objective,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			9,
			exit_tint
		)
	if not fragment_collected:
		var f: Vector2 = fragment_position
		var diamond: PackedVector2Array = PackedVector2Array(
			[f + Vector2(0, -9), f + Vector2(7, 0), f + Vector2(0, 9), f + Vector2(-7, 0)]
		)
		draw_colored_polygon(diamond, ThreadStyle.GOLD)
		draw_line(f + Vector2(0, -4), f + Vector2(0, 4), Color("493d32"), 1.5)
		draw_line(f + Vector2(-11, 0), f + Vector2(-14, 0), Color(ThreadStyle.GOLD, 0.4), 1)
		draw_line(f + Vector2(11, 0), f + Vector2(14, 0), Color(ThreadStyle.GOLD, 0.4), 1)
	if fragment_pulse > 0 and not reduced_effects:
		draw_arc(
			fragment_position,
			8 + (0.4 - fragment_pulse) * 44,
			0,
			TAU,
			24,
			Color(0.96, 0.8, 0.5, fragment_pulse * 2),
			1.5,
			true
		)
	if exit_pulse > 0 and not reduced_effects:
		draw_arc(
			exit_position,
			12 + (0.5 - exit_pulse) * 50,
			0,
			TAU,
			24,
			Color(0.25, 0.85, 0.76, exit_pulse),
			2,
			true
		)

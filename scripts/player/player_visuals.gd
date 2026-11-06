extends Node2D

var phase: float = 0.0
var trail: Array[Vector2] = []
var ribbon: Array[Vector2] = []
var pulses: Array[Dictionary] = []
var reduced_effects: bool = false
var death_age: float = 0.0


func _ready() -> void:
	var player: PlayerController = get_parent()
	player.feedback.connect(on_feedback)


func on_feedback(event: String) -> void:
	if reduced_effects or event not in ["jump", "wall_jump", "land"]:
		return
	var player: PlayerController = get_parent()
	pulses.append({"origin": player.position + Vector2(0, 10), "age": 0.0})
	if pulses.size() > 6:
		pulses.pop_front()


func reset_visuals() -> void:
	trail.clear()
	ribbon.clear()
	pulses.clear()


func _process(delta: float) -> void:
	var player: PlayerController = get_parent()
	phase += delta * (15.0 if absf(player.velocity.x) > 5.0 else 3.0)
	death_age = death_age + delta if player.dead else 0.0
	for pulse: Dictionary in pulses:
		pulse.age += delta
	pulses = pulses.filter(func(pulse: Dictionary) -> bool: return pulse.age < 0.18)
	if not reduced_effects and player.active and absf(player.velocity.x) > 180:
		trail.append(player.position)
		if trail.size() > 12:
			trail.pop_front()
	else:
		trail.clear()
	for i in 8:
		var sway: float = (
			0.0 if reduced_effects else sin(phase * 0.45 - i * 0.65) * (0.7 + i * 0.25)
		)
		var lift: float = clampf(-player.velocity.y * 0.012, -3.0, 3.0) * float(i) / 7.0
		var target: Vector2 = (
			player.position
			+ Vector2(-player.facing * (2 + i * 3.5), -6 + sway + minf(i * i * 0.08, 4) + lift)
		)
		if ribbon.size() <= i:
			ribbon.append(target)
		else:
			ribbon[i] = ribbon[i].lerp(target, minf(1, delta * (32 - i * 2)))
	queue_redraw()


func _draw() -> void:
	var p: PlayerController = get_parent()
	var white: Color = ThreadStyle.PAPER
	var direction: float = p.facing
	var run: float = sin(phase) * minf(absf(p.velocity.x) / 30.0, 5.0)
	var lean: float = p.velocity.x / 100.0
	var airborne: bool = p.motion != PlayerController.Motion.GROUNDED
	if airborne:
		run = 3.0 if p.velocity.y < 0 else -2.0
	if p.motion == PlayerController.Motion.WALL_SLIDING:
		lean = direction * 3.0
		run = -1.0
	for i in range(1, trail.size()):
		draw_line(
			trail[i - 1] - p.position + Vector2(0, -6),
			trail[i] - p.position + Vector2(0, -6),
			Color(ThreadStyle.THREAD, float(i) / trail.size() * 0.12),
			1,
			true
		)
	for pulse: Dictionary in pulses:
		var spread: float = 3 + float(pulse.age) * 55.0
		var origin: Vector2 = pulse.origin - p.position
		var tint: Color = Color(0.55, 0.7, 0.73, (1 - float(pulse.age) / 0.18) * 0.5)
		draw_line(origin - Vector2(spread, 0), origin - Vector2(spread + 3, 2), tint, 1.0)
		draw_line(origin + Vector2(spread, 0), origin + Vector2(spread + 3, 2), tint, 1.0)
	if p.dead:
		for i in 8:
			var ray: Vector2 = Vector2.from_angle(float(i) * TAU / 8)
			var radius: float = 4 + death_age * 70
			draw_line(ray * radius, ray * (radius + 3), ThreadStyle.DANGER, 1.5, true)
		return
	for i in range(1, ribbon.size()):
		draw_line(
			ribbon[i - 1] - p.position,
			ribbon[i] - p.position,
			ThreadStyle.THREAD,
			3.2 - i * 0.32,
			true
		)
	draw_circle(Vector2(-direction * 2, -6), 1.7, ThreadStyle.THREAD)
	draw_circle(Vector2(lean, -8), 3.3, white)
	draw_line(Vector2(lean, -4), Vector2(0, 3), white, 2.0, true)
	draw_polyline(
		PackedVector2Array(
			[
				Vector2(0, -2),
				Vector2(-4 * direction, 1 + run * 0.5),
				Vector2(-7 * direction, -1 + run)
			]
		),
		white,
		1.5,
		true
	)
	draw_polyline(
		PackedVector2Array(
			[
				Vector2(0, -2),
				Vector2(4 * direction, 1 - run * 0.5),
				Vector2(7 * direction, -2 - run)
			]
		),
		white,
		1.5,
		true
	)
	draw_line(Vector2(0, 3), Vector2(-3 - run, 10), white, 1.8, true)
	draw_line(Vector2(0, 3), Vector2(3 + run, 10 - (3.0 if airborne else 0.0)), white, 1.8, true)

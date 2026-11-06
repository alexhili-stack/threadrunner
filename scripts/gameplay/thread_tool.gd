class_name ThreadTool
extends Node2D

var room: LevelRoot
var player: PlayerController
var history: Array[Vector2] = []
var bridges: Array[StaticBody2D] = []
var stitched: Array[bool] = []
var grapple_index: int = -1
var candidate: int = -1
var rope_length: float = 0.0
var rewinding: bool = false
var rewound_distance: float = 0.0
var has_stitched: bool = false
var has_grappled: bool = false
var checkpoint_reached: bool = false
var message: String = ""
var message_left: float = 0.0


func setup(level: LevelRoot) -> void:
	room = level
	player = room.player
	player.thread_tool = self
	z_index = 1
	for pair: Vector4 in room.stitch_pairs:
		var from: Vector2 = Vector2(pair.x, pair.y)
		var to: Vector2 = Vector2(pair.z, pair.w)
		var bridge: StaticBody2D = StaticBody2D.new()
		var collision: CollisionShape2D = CollisionShape2D.new()
		var shape: RectangleShape2D = RectangleShape2D.new()
		shape.size = Vector2(from.distance_to(to), 4)
		collision.shape = shape
		collision.disabled = true
		bridge.position = (from + to) * 0.5 + Vector2(0, 2)
		bridge.rotation = (to - from).angle()
		bridge.add_child(collision)
		add_child(bridge)
		bridges.append(bridge)
		stitched.append(false)
	reset()


func reset() -> void:
	history.clear()
	grapple_index = -1
	candidate = -1
	rewinding = false
	rewound_distance = 0.0
	has_stitched = false
	has_grappled = false
	checkpoint_reached = false
	message = ""
	message_left = 0.0
	for i in bridges.size():
		stitched[i] = false
		bridges[i].get_child(0).set_deferred("disabled", true)
	queue_redraw()


func handle_input(stitch: bool, grapple: bool, rewind: bool, delta: float) -> void:
	message_left = maxf(0, message_left - delta)
	if message_left <= 0:
		message = ""
	if grapple_index >= 0 and not line_clear(player.position, anchor()):
		grapple_index = -1
		_notify("Thread caught on a solid edge")
	candidate = nearest_anchor()
	rewinding = rewind
	if rewind:
		grapple_index = -1
		if history.size() <= 3:
			_notify("No thread left to rewind")
		return
	if stitch:
		stitch_nearby()
	if grapple:
		if grapple_index >= 0:
			grapple_index = -1
		elif candidate >= 0:
			grapple_index = candidate
			rope_length = maxf(32, player.position.distance_to(anchor()))
			has_grappled = true
			player.feedback.emit("fragment")
		else:
			_notify("Move beneath a visible round anchor")
	queue_redraw()


func _notify(value: String) -> void:
	message = value
	message_left = 1.4


func anchor() -> Vector2:
	return room.thread_anchors[grapple_index] if grapple_index >= 0 else Vector2.ZERO


func nearest_anchor() -> int:
	var found: int = -1
	var score: float = INF
	for i in room.thread_anchors.size():
		var offset: Vector2 = room.thread_anchors[i] - player.position
		if offset.y > -16 or offset.length() > player.config.thread_grapple_reach:
			continue
		if not line_clear(player.position, room.thread_anchors[i]):
			continue
		var rank: float = offset.length() + (65.0 if offset.x * player.facing < -32 else 0.0)
		if rank < score:
			score = rank
			found = i
	return found


func line_clear(from: Vector2, to: Vector2) -> bool:
	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(from, to)
	query.exclude = [player.get_rid()]
	return player.get_world_2d().direct_space_state.intersect_ray(query).is_empty()


func stitch_nearby() -> void:
	var found: int = -1
	var closest: float = player.config.thread_stitch_reach
	for i in room.stitch_pairs.size():
		var pair: Vector4 = room.stitch_pairs[i]
		for endpoint: Vector2 in [Vector2(pair.x, pair.y), Vector2(pair.z, pair.w)]:
			var distance: float = player.position.distance_to(endpoint)
			if distance < closest and line_clear(player.position, endpoint - Vector2(0, 3)):
				closest = distance
				found = i
	if found < 0:
		_notify("Move beside a square stitch terminal")
		return
	stitched[found] = not stitched[found]
	bridges[found].get_child(0).set_deferred("disabled", not stitched[found])
	has_stitched = has_stitched or stitched[found]
	player.feedback.emit("fragment")
	_notify("Thread bridge woven / relays powered" if stitched[found] else "Thread bridge released")


func relay_powered() -> bool:
	return stitched.has(true)


func goal_met() -> bool:
	match room.thread_goal:
		"stitch", "relay":
			return relay_powered()
		"grapple":
			return has_grappled
		"rewind":
			return checkpoint_reached and rewound_distance >= 40
		"all":
			return (
				relay_powered() and has_grappled and checkpoint_reached and rewound_distance >= 40
			)
	return true


func record_position() -> void:
	if room.thread_checkpoint.x >= 0 and player.position.distance_to(room.thread_checkpoint) < 22:
		if not checkpoint_reached:
			player.feedback.emit("fragment")
			_notify("Relay reached / rewind your thread")
		checkpoint_reached = true
	if not rewinding:
		history.append(player.position)
		if history.size() > int(player.config.thread_history_seconds * 60):
			history.pop_front()
	queue_redraw()


func rewind_target() -> Vector2:
	var target: Vector2 = player.position
	for i in player.config.thread_rewind_steps:
		if not history.is_empty():
			target = history.pop_back()
	return target


func finish_rewind_step(previous: Vector2, blocked: bool) -> void:
	rewound_distance += previous.distance_to(player.position)
	if blocked:
		history.clear()
		rewinding = false
		_notify("Thread blocked by a solid surface")
	queue_redraw()


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if not is_instance_valid(player):
		return
	# A bounded six-second trail is the real rewind route, not a predicted path.
	var stride: int = maxi(1, history.size() / 80)
	for i in range(stride, history.size(), stride):
		var alpha: float = (0.7 if rewinding else 0.38) * (0.45 + 0.55 * float(i) / history.size())
		draw_line(history[i - stride], history[i], Color(ThreadStyle.THREAD, alpha), 1, true)
	for i in room.stitch_pairs.size():
		var pair: Vector4 = room.stitch_pairs[i]
		var from: Vector2 = Vector2(pair.x, pair.y)
		var to: Vector2 = Vector2(pair.z, pair.w)
		var color: Color = ThreadStyle.THREAD if stitched[i] else Color("9bb7bc")
		if stitched[i]:
			draw_line(from, to, ThreadStyle.THREAD, 3, true)
			for x in range(8, int(from.distance_to(to)), 12):
				var point: Vector2 = from.move_toward(to, x)
				draw_line(
					point + Vector2(-2, -2), point + Vector2(2, 2), ThreadStyle.PAPER, 1, true
				)
		else:
			for x in range(8, int(from.distance_to(to)), 10):
				var point: Vector2 = from.move_toward(to, x)
				draw_line(point, point.move_toward(to, 3), Color(ThreadStyle.THREAD, 0.22), 1)
		for endpoint: Vector2 in [from, to]:
			draw_rect(Rect2(endpoint - Vector2(4, 4), Vector2(8, 8)), ThreadStyle.INK)
			draw_rect(Rect2(endpoint - Vector2(4, 4), Vector2(8, 8)), color, false, 1.5)
			draw_circle(endpoint, 1, color)
	for i in room.thread_anchors.size():
		var point: Vector2 = room.thread_anchors[i]
		var color: Color = (
			ThreadStyle.THREAD if i == candidate or i == grapple_index else Color("799ba6")
		)
		draw_line(point - Vector2(0, 9), point - Vector2(0, 4), Color(color, 0.5), 1)
		draw_circle(point, 4, ThreadStyle.INK)
		draw_circle(point, 4, color, false, 1.5, true)
		draw_circle(point, 1, color)
		if i == candidate:
			draw_arc(point, 8, -PI * 0.8, PI * 0.8, 20, Color(color, 0.6), 1, true)
	if room.thread_checkpoint.x >= 0:
		var point: Vector2 = room.thread_checkpoint
		var color: Color = ThreadStyle.THREAD if checkpoint_reached else ThreadStyle.PAPER
		draw_rect(Rect2(point - Vector2(7, 12), Vector2(14, 24)), Color(color, 0.08))
		draw_rect(Rect2(point - Vector2(7, 12), Vector2(14, 24)), color, false, 1)
		draw_line(point - Vector2(4, 0), point + Vector2(4, 0), color, 1.5)
	if grapple_index >= 0:
		draw_line(player.position + Vector2(0, -4), anchor(), ThreadStyle.THREAD, 1.6, true)
		draw_circle(anchor(), 6, ThreadStyle.PAPER, false, 1, true)

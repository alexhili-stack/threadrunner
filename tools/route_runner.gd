extends SceneTree

var results: Array[Dictionary] = []
var room: LevelRoot
var run: RunController
var recording: Array = []
var mode: String = "record"
var selected: int = -1
var require_fragment: bool = true
var fixture_root: String = "res://tests/fixtures"
var indices: Array[int] = []
var trace: bool = false
var action_counts: Dictionary = {"jump": 0, "wall_jump": 0, "releases": 0, "short_releases": 0}


func _initialize() -> void:
	InputService.new().configure()
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--mode="):
			mode = arg.trim_prefix("--mode=")
		if arg.begins_with("--index="):
			selected = int(arg.trim_prefix("--index="))
		if arg.begins_with("--indices="):
			for value: String in arg.trim_prefix("--indices=").split(","):
				indices.append(int(value))
		if arg == "--trace":
			trace = true
	require_fragment = not mode.contains("normal") and mode != "bypass"
	if not require_fragment:
		fixture_root += "/normal"
	call_deferred("execute")


func step(axis: float, jump: bool, held: bool = false) -> void:
	if jump and room.player.test_held:
		room.player.drive_input(axis, false, false)
		action_counts.releases += 1
		recording.append([axis, false, false])
		await physics_frame
	if room.player.test_held and not held:
		action_counts.releases += 1
		if room.player.velocity.y < -250:
			action_counts.short_releases += 1
	room.player.drive_input(axis, jump, held)
	recording.append([axis, jump, held])
	await physics_frame


func new_room(index: int) -> void:
	room = load(LevelCatalog.scene_path(index)).instantiate()
	root.add_child(room)
	room.player.synthetic = true
	room.player.feedback.connect(
		func(event: String) -> void:
			if event in ["jump", "wall_jump"]:
				action_counts[event] += 1
	)
	run = RunController.new()
	root.add_child(run)
	run.begin(room)
	recording = []
	for tick in 6:
		await step(0, false)


func execute() -> void:
	var failed: int = 0
	for index in LevelCatalog.BASE_COUNT:
		if selected >= 0 and index != selected:
			continue
		if not indices.is_empty() and not index in indices:
			continue
		await new_room(index)
		var passed: bool = false
		var attempt_deaths: int = 0
		if mode == "bypass":
			for tick in 900:
				await step(1.0, false, false)
			passed = run.state != RunController.State.COMPLETED
		elif mode.begins_with("replay"):
			var path: String = fixture_root.path_join(LevelCatalog.id_for(index) + ".json")
			if FileAccess.file_exists(path):
				var fixture: Array = JSON.parse_string(FileAccess.get_file_as_string(path))
				for repeat in 3:
					run.restart()
					var previous_deaths: int = run.deaths
					action_counts = {"jump": 0, "wall_jump": 0, "releases": 0, "short_releases": 0}
					for input: Array in fixture:
						await step(float(input[0]), bool(input[1]), bool(input[2]))
					passed = (
						run.state == RunController.State.COMPLETED
						and (room.fragment_collected or not require_fragment)
					)
					attempt_deaths = run.deaths - previous_deaths
					passed = passed and attempt_deaths == 0
					if room.required_skill == "wall":
						passed = passed and action_counts.wall_jump > 0
					if room.required_skill == "variable_jump":
						passed = passed and action_counts.short_releases > 0
					if not passed:
						break
		else:
			for delay in range(0, 1 if trace else 181, 15):
				run.restart()
				var previous_deaths: int = run.deaths
				recording = []
				action_counts = {"jump": 0, "wall_jump": 0, "releases": 0, "short_releases": 0}
				for wait_tick in 6 + delay:
					await step(0, false)
				passed = await guide()
				attempt_deaths = run.deaths - previous_deaths
				if passed:
					break
			if passed:
				DirAccess.make_dir_recursive_absolute(fixture_root)
				var file: FileAccess = FileAccess.open(
					fixture_root.path_join(room.level_id + ".json"), FileAccess.WRITE
				)
				file.store_string(JSON.stringify(recording))
				file.close()
		var result: Dictionary = {
			"room": index + 1,
			"id": room.level_id,
			"pass": passed,
			"fragment": room.fragment_collected,
			"repetitions": 3 if mode.begins_with("replay") else 1,
			"route_type": "fragment" if require_fragment else "normal",
			"frames": recording.size(),
			"time": run.attempt_time,
			"deaths": attempt_deaths,
			"search_deaths": run.deaths,
			"position": str(room.player.position),
			"actions": action_counts.duplicate()
		}
		results.append(result)
		print(JSON.stringify(result))
		if not passed:
			failed += 1
		run.free()
		room.free()
		await process_frame
	var output: FileAccess = FileAccess.open(
		"res://artifacts/routes_%s.json" % mode, FileAccess.WRITE
	)
	output.store_string(JSON.stringify(results, "\t"))
	output.close()
	quit(0 if failed == 0 else 1)


func guide() -> bool:
	var targets: Array[Vector2] = room.route.duplicate()
	# Add an actual detour to the collectible, then use the normal exit route.
	var nearest: int = 0
	var distance: float = INF
	for i in targets.size() - 1:
		var closest: Vector2 = Geometry2D.get_closest_point_to_segment(
			room.fragment_position, targets[i], targets[i + 1]
		)
		var gap: float = closest.distance_to(room.fragment_position)
		if gap < distance:
			distance = gap
			nearest = i
	if require_fragment:
		targets.insert(nearest + 1, room.fragment_position)
	else:
		nearest = -2
	targets.append(room.exit_position)
	var waypoint: int = 0
	var cooldown: int = 0
	var stuck: int = 0
	var last: Vector2 = room.player.position
	var held_ticks: int = 0
	var tap_jump: bool = false
	for tick in 3600:
		if run.state == RunController.State.COMPLETED:
			return room.fragment_collected or not require_fragment
		if run.state == RunController.State.DYING:
			return false
		var p: PlayerController = room.player
		var target: Vector2 = targets[waypoint]
		var landing: bool = false
		for platform: Rect2 in room.platforms:
			if (
				absf(target.y - (platform.position.y - 11)) < 1
				and target.x >= platform.position.x
				and target.x <= platform.end.x
			):
				landing = true
		var tolerance: float = 5.0 if landing else 18.0
		var reached: bool = (
			p.position.distance_to(target) < tolerance and (not landing or p.is_on_floor())
		)
		if not landing and absf(p.position.x - target.x) < 18 and p.position.y <= target.y + 14:
			reached = true
		if (
			(waypoint != nearest + 1 and reached)
			or (waypoint == nearest + 1 and room.fragment_collected)
		):
			if trace:
				print(
					"waypoint ",
					waypoint,
					" ",
					target,
					" reached at ",
					p.position,
					" time ",
					run.attempt_time
				)
			waypoint = mini(waypoint + 1, targets.size() - 1)
			target = targets[waypoint]
		var dx: float = target.x - p.position.x
		var dy: float = target.y - p.position.y
		var axis: float = clampf(dx / 16.0, -1, 1)
		if p.is_on_floor() and absf(dy) < 12:
			axis = signf(dx)
		var jump: bool = false
		# A waypoint beside a tall wall requires actual contact to wall-jump.
		if dy < -25 and absf(dx) < 24:
			for platform: Rect2 in room.platforms:
				if (
					platform.size.y > 60
					and absf(platform.position.x - p.position.x) < 36
					and platform.position.x > p.position.x
				):
					axis = 1.0
		cooldown = maxi(0, cooldown - 1)
		if p.position.distance_to(last) < 0.2:
			stuck += 1
		else:
			stuck = 0
		last = p.position
		if cooldown == 0:
			if p.is_on_floor() and (dy < -18 or landing):
				var at_edge: bool = false
				for platform: Rect2 in room.platforms:
					if (
						absf(p.position.y + 11 - platform.position.y) < 2
						and p.position.x >= platform.position.x - 5
						and p.position.x <= platform.end.x + 5
					):
						if dx > 0 and platform.end.x - p.position.x < 8:
							at_edge = true
						if dx < 0 and p.position.x - platform.position.x < 8:
							at_edge = true
				if (dy < -18 and absf(dx) < 138) or at_edge:
					jump = true
			if p.is_on_wall() and not p.is_on_floor() and dy < -15:
				jump = true
			if stuck > 12 and p.is_on_floor():
				jump = true
		if jump:
			if trace:
				print("jump at ", p.position, " velocity ", p.velocity, " target ", target)
			cooldown = 12
			held_ticks = 0
			tap_jump = false
			for teeth: Rect2 in room.ceiling_spikes:
				if p.position.y > teeth.end.y and absf(p.position.x - teeth.get_center().x) < 100:
					tap_jump = true
		held_ticks += 1
		var held: bool = (held_ticks <= 2 if tap_jump else p.velocity.y < 0) or jump
		# Wait on the safe side of a closed gate, without changing its cycle.
		for gate: Rect2 in room.gates:
			var in_front: bool = (
				(p.position.x < gate.position.x and dx > 0)
				or (p.position.x > gate.end.x and dx < 0)
			)
			if (
				in_front
				and absf(gate.get_center().x - p.position.x) < 45
				and p.position.y > gate.position.y - 15
				and p.position.y < gate.end.y + 12
			):
				var phase: float = fmod(room.elapsed, room.gate_period)
				if phase > room.gate_open_time - 0.35:
					axis = 0
					jump = false
		for point: Vector2 in room.mover_positions:
			if (
				p.is_on_floor()
				and dx * (point.x - p.position.x) > 0
				and absf(point.x - p.position.x) < 60
			):
				if absf(point.y - p.position.y) < 23:
					axis = 0
					jump = false
		for vent: Rect2 in room.vents:
			if (
				p.is_on_floor()
				and dx * (vent.get_center().x - p.position.x) > 0
				and absf(vent.get_center().x - p.position.x) < 65
			):
				if (
					p.position.y > vent.position.y - 12
					and p.position.y < vent.end.y + 12
					and (room.vent_is_warning() or room.vent_is_active())
				):
					axis = 0
					jump = false
		if not jump and p.is_on_floor():
			held = false
		await step(axis, jump, held)
	return false

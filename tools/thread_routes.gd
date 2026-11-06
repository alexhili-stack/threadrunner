extends SceneTree

var room: LevelRoot
var run: RunController
var recording: Array = []
var results: Array[Dictionary] = []
var record: bool = false
var trace: bool = false


func _initialize() -> void:
	InputService.new().configure()
	for arg: String in OS.get_cmdline_user_args():
		record = record or arg == "--record"
		trace = trace or arg == "--trace"
	call_deferred("execute")


func step(
	axis: float = 0,
	jump: bool = false,
	held: bool = false,
	stitch: bool = false,
	grapple: bool = false,
	rewind: bool = false
) -> void:
	room.player.drive_input(axis, jump, held)
	room.player.drive_tools(stitch, grapple, rewind)
	recording.append([axis, jump, held, stitch, grapple, rewind])
	await physics_frame
	if trace and recording.size() % 30 == 0:
		print(
			"Frame ",
			recording.size(),
			" at ",
			room.player.position,
			" v ",
			room.player.velocity,
			" tether ",
			room.thread_tool.grapple_index,
			" deaths ",
			run.deaths
		)


func walk_to(x: float) -> void:
	for tick in 400:
		if run.state == RunController.State.COMPLETED or run.deaths > 0:
			break
		if room.player.position.x >= x:
			break
		await step(1)


func rewind_to(x: float) -> void:
	for tick in 180:
		if run.state == RunController.State.COMPLETED or run.deaths > 0:
			break
		if room.player.position.x <= x:
			break
		await step(0, false, false, false, false, true)
	await step()


func guide(index: int) -> void:
	for tick in 6:
		await step()
	match index:
		40:
			await walk_to(150)
			await step(0, false, false, true)
			for tick in 3:
				await step()
			await walk_to(600)
		41:
			await walk_to(200)
			await step(1, false, false, false, true)
			await walk_to(380)
			await step(1, true, true)
			for tick in 18:
				await step(1, false, true)
			await step(1)
			await walk_to(600)
		42:
			await walk_to(108)
			await step(0, false, false, true)
			await walk_to(600)
		43:
			await walk_to(548)
			await rewind_to(110)
		44:
			await walk_to(150)
			await step(0, false, false, true)
			await walk_to(700)
			await rewind_to(615)
			await walk_to(750)
			await step(1, false, false, false, true)
			await walk_to(930)
			await step(1, true, true)
			for tick in 18:
				await step(1, false, true)
			await step(1)
			await walk_to(1220)
	for tick in 3:
		await step()


func execute() -> void:
	for index in range(LevelCatalog.BASE_COUNT, LevelCatalog.COUNT):
		room = LevelCatalog.entry(index).scene.instantiate()
		root.add_child(room)
		room.player.synthetic = true
		run = RunController.new()
		root.add_child(run)
		run.begin(room)
		recording = []
		var path: String = "res://tests/fixtures/%s.json" % room.level_id
		if record:
			await guide(index)
			if (
				run.state == RunController.State.COMPLETED
				and room.fragment_collected
				and run.deaths == 0
			):
				var fixture: FileAccess = FileAccess.open(path, FileAccess.WRITE)
				fixture.store_string(JSON.stringify(recording))
				fixture.close()
		var passed: bool = FileAccess.file_exists(path)
		var count: int = 0
		if passed:
			var inputs: Array = JSON.parse_string(FileAccess.get_file_as_string(path))
			for repeat in 3:
				run.deaths = 0
				run.restart()
				recording = []
				for frame: Array in inputs:
					await step(
						float(frame[0]),
						bool(frame[1]),
						bool(frame[2]),
						bool(frame[3]),
						bool(frame[4]),
						bool(frame[5])
					)
				passed = (
					run.state == RunController.State.COMPLETED
					and room.fragment_collected
					and run.deaths == 0
				)
				if not passed:
					break
				count += 1
		var result: Dictionary = {
			"room": index + 1,
			"id": room.level_id,
			"pass": passed,
			"repetitions": count,
			"time": run.attempt_time,
			"deaths": run.deaths,
			"position": str(room.player.position),
			"fragment": room.fragment_collected,
			"stitch": room.thread_tool.has_stitched,
			"grapple": room.thread_tool.has_grappled,
			"rewound_pixels": room.thread_tool.rewound_distance,
			"checkpoint": room.thread_tool.checkpoint_reached
		}
		# A separate real walk without tool input must not complete these lessons.
		run.restart()
		for tick in 240:
			await step(1)
		result["no_tool_rejected"] = run.state != RunController.State.COMPLETED
		result.pass = result.pass and result.no_tool_rejected
		results.append(result)
		print(JSON.stringify(result))
		run.free()
		room.free()
		await process_frame
	var report: Dictionary = {
		"rooms": results, "pass": results.all(func(r: Dictionary) -> bool: return r.pass)
	}
	var file: FileAccess = FileAccess.open("res://artifacts/thread_routes.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	quit(0 if report.pass else 1)

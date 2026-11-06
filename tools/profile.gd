extends SceneTree

var app: Node2D
var results: Array[Dictionary] = []
var samples: Array[float] = []
var previous_frame: int = 0
var collecting: bool = false


func _initialize() -> void:
	process_frame.connect(record_frame)
	call_deferred("execute")


func record_frame() -> void:
	var now: int = Time.get_ticks_usec()
	if collecting:
		samples.append(float(now - previous_frame) / 1000.0)
	previous_frame = now


func execute() -> void:
	Engine.max_fps = 120
	app = load("res://scenes/app/main.tscn").instantiate()
	root.add_child(app)
	for index: int in [0, 29, 39, 44]:
		app.start_level(index)
		app.level.player.synthetic = true
		var fixture: Array = JSON.parse_string(
			FileAccess.get_file_as_string(
				"res://tests/fixtures/%s.json" % LevelCatalog.id_for(index)
			)
		)
		samples = []
		var started: int = Time.get_ticks_usec()
		var last: int = started
		previous_frame = started
		collecting = true
		var position: int = 0
		while Time.get_ticks_usec() - started < 10000000:
			var input: Array = fixture[position]
			app.level.player.drive_input(float(input[0]), bool(input[1]), bool(input[2]))
			if input.size() >= 6:
				app.level.player.drive_tools(bool(input[3]), bool(input[4]), bool(input[5]))
			await physics_frame
			var now: int = Time.get_ticks_usec()
			last = now
			position += 1
			if position >= fixture.size():
				position = 0
				app.run.restart()
				app.complete_pending = false
				app.show_hud()
		collecting = false
		var frame_ms: Array[float] = samples.duplicate()
		frame_ms.sort()
		results.append(
			{
				"room": index + 1,
				"frames": frame_ms.size(),
				"seconds": float(last - started) / 1000000.0,
				"median_frame_ms": frame_ms[frame_ms.size() / 2],
				"p95_frame_ms": frame_ms[int(float(frame_ms.size()) * .95)],
				"worst_frame_ms": frame_ms[-1],
				"process_ms": Performance.get_monitor(Performance.TIME_PROCESS) * 1000,
				"physics_ms": Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000,
				"nodes": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
				"static_bytes": int(Performance.get_monitor(Performance.MEMORY_STATIC))
			}
		)
	var report: Dictionary = {
		"engine": Engine.get_version_info().string,
		"os": OS.get_name(),
		"cpu": OS.get_processor_name(),
		"logical_cpus": OS.get_processor_count(),
		"gpu": RenderingServer.get_video_adapter_name(),
		"resolution": str(DisplayServer.window_get_size()),
		"renderer": "gl_compatibility",
		"build": "editor runtime",
		"background_load": "simultaneous real-time headless soak",
		"rooms": results,
		"method":
		(
			"10s process-frame intervals, 120 FPS cap, fixture input at 60 Hz; "
			+ "GPU presentation timing not measured"
		)
	}
	var file: FileAccess = FileAccess.open("res://artifacts/profile.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	app.set_process(false)
	app.audio.stop_all(true)
	await create_timer(0.12).timeout
	app.queue_free()
	for frame in 4:
		await process_frame
	quit()

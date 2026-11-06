extends SceneTree

var app: Node2D
var samples: Array[Dictionary] = []
var started: int
var duration: float = 900.0
var cycles: int = 0
var failures: Array[String] = []


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--duration="):
			duration = float(arg.trim_prefix("--duration="))
	call_deferred("execute")


func execute() -> void:
	app = load("res://scenes/app/main.tscn").instantiate()
	root.add_child(app)
	started = Time.get_ticks_usec()
	var next_sample: float = 0.0
	while float(Time.get_ticks_usec() - started) / 1000000.0 < duration:
		var index: int = cycles % LevelCatalog.COUNT
		app.start_level(index)
		app.level.player.synthetic = true
		var fixture: Array = JSON.parse_string(
			FileAccess.get_file_as_string(
				"res://tests/fixtures/%s.json" % LevelCatalog.id_for(index)
			)
		)
		app.run.die()
		while app.run.state == RunController.State.DYING:
			await physics_frame
		app.show_pause()
		var clock: float = app.run.attempt_time
		for tick in 5:
			await physics_frame
		if app.run.attempt_time != clock:
			failures.append("Paused timer advanced")
		app.show_hud()
		app.run.restart()
		for input: Array in fixture:
			app.level.player.drive_input(float(input[0]), bool(input[1]), bool(input[2]))
			if input.size() >= 6:
				app.level.player.drive_tools(bool(input[3]), bool(input[4]), bool(input[5]))
			await physics_frame
		if app.run.state != RunController.State.COMPLETED or not app.level.fragment_collected:
			failures.append("Route failed: " + str(index + 1))
		cycles += 1
		await process_frame
		var elapsed: float = float(Time.get_ticks_usec() - started) / 1000000.0
		if elapsed >= next_sample:
			samples.append(
				{
					"seconds": elapsed,
					"cycles": cycles,
					"nodes": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
					"orphans": int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)),
					"static_bytes": int(Performance.get_monitor(Performance.MEMORY_STATIC)),
					"process_seconds": Performance.get_monitor(Performance.TIME_PROCESS),
					"physics_seconds": Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)
				}
			)
			next_sample += 30.0
			print(
				"Soak ", int(elapsed), "s / ", cycles, " room cycles / failures ", failures.size()
			)
	var report: Dictionary = {
		"duration_seconds": float(Time.get_ticks_usec() - started) / 1000000.0,
		"cycles": cycles,
		"failures": failures,
		"samples": samples,
		"headless": true
	}
	var file: FileAccess = FileAccess.open("res://artifacts/soak.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	app.set_process(false)
	app.run.set_paused(true)
	app.audio.stop_all(true)
	await create_timer(0.10).timeout
	app.queue_free()
	for frame in 4:
		await process_frame
	quit(0 if failures.is_empty() else 1)

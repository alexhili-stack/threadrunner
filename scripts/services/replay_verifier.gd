extends RefCounted
## Opt-in external-input verification for standalone builds. Never used by menus.


static func execute(app: Node2D, fixture_path: String, output_path: String) -> void:
	var parser: JSON = JSON.new()
	var valid: bool = parser.parse(FileAccess.get_file_as_string(fixture_path)) == OK
	var bundle: Variant = parser.data if valid else null
	if not bundle is Dictionary or not bundle.get("routes") is Array:
		push_error("Invalid external input fixture")
		app.get_tree().quit(2)
		return
	var checks: Array[Dictionary] = []
	var accelerated: bool = OS.has_feature("web") and bool(bundle.get("accelerated", false))
	if accelerated:
		Engine.physics_ticks_per_second = 480
		Engine.time_scale = 8.0
		# Browser automation may throttle rendering; let fixed physics catch up.
		Engine.max_physics_steps_per_frame = 4096
		app.saves.data.settings.mute = true
		app.apply_settings()
	var repetitions: int = clampi(int(bundle.get("repetitions", 1)), 1, 3)
	checks.append({"name": "release starts at menu", "pass": app.page == "menu"})
	checks.append({"name": "debug overlay off", "pass": not app.debug})
	checks.append(
		{
			"name": "fresh-process saved progress",
			"pass":
			(
				not bundle.get("expect_completed", false)
				or app.saves.data.completed.has(LevelCatalog.id_for(0))
			)
		}
	)
	for route: Dictionary in bundle.routes:
		var index: int = int(route.index)
		if index < 0 or index >= LevelCatalog.COUNT or not route.get("inputs") is Array:
			app.get_tree().quit(2)
			return
		for repetition in repetitions:
			app.start_level(index)
			app.level.player.synthetic = true
			for input: Array in route.inputs:
				app.level.player.drive_input(float(input[0]), bool(input[1]), bool(input[2]))
				if input.size() >= 6:
					app.level.player.drive_tools(bool(input[3]), bool(input[4]), bool(input[5]))
				await app.get_tree().physics_frame
			checks.append(
				{
					"name": "room %02d clear and fragment" % (index + 1),
					"pass":
					(
						app.run.state == RunController.State.COMPLETED
						and app.level.fragment_collected
						and app.run.deaths == 0
					)
				}
			)
			await app.get_tree().process_frame
			# process_frame precedes Node._process; allow the pending UI to render.
			await app.get_tree().process_frame
			checks.append(
				{"name": "room %02d completion UI" % (index + 1), "pass": app.page == "complete"}
			)
			app.run.restart()
			checks.append(
				{
					"name": "room %02d restart" % (index + 1),
					"pass":
					(
						app.run.state == RunController.State.PLAYING
						and not app.level.fragment_collected
					)
				}
			)
	var saved: SaveService = SaveService.new(app.saves.directory)
	saved.load_save()
	var records_match: bool = saved.data.completed.size() == app.saves.data.completed.size()
	var largest_delta: float = 0.0
	for key: String in app.saves.data.completed:
		if not saved.data.completed.has(key):
			records_match = false
			continue
		var difference: float = absf(
			float(saved.data.completed[key]) - float(app.saves.data.completed[key])
		)
		largest_delta = maxf(largest_delta, difference)
		records_match = records_match and difference <= 0.000001
	checks.append({"name": "save round trip within one microsecond", "pass": records_match})
	checks.append(
		{
			"name": "test addon excluded",
			"pass": not ResourceLoader.exists("res://addons/gdUnit4/plugin.gd")
		}
	)
	var report: Dictionary = {
		"checks": checks,
		"accelerated": accelerated,
		"repetitions": repetitions,
		"physics_step_seconds": Engine.time_scale / float(Engine.physics_ticks_per_second),
		"pass": checks.all(func(item: Dictionary) -> bool: return item.pass),
		"engine": Engine.get_version_info().string,
		"debug_build": OS.is_debug_build(),
		"memory_completed": app.saves.data.completed.duplicate(),
		"reloaded_completed": saved.data.completed.duplicate(),
		"largest_record_delta_seconds": largest_delta
	}
	var file: FileAccess = FileAccess.open(output_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	if OS.has_feature("web"):
		JavaScriptBridge.get_interface("ThreadrunnerHost").verificationComplete(
			JSON.stringify(report)
		)
	app.audio.stop_all(true)
	await app.get_tree().create_timer(0.06).timeout
	app.get_tree().quit(0 if report.pass else 1)

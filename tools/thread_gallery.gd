extends SceneTree

var app: Node2D


func _initialize() -> void:
	call_deferred("execute")


func capture(name: String) -> void:
	app.run.set_paused(true)
	for frame in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/captures/%s.png" % name)
	app.run.set_paused(false)


func execute() -> void:
	app = load("res://scenes/app/main.tscn").instantiate()
	root.add_child(app)
	app.saves.data.settings.mute = true
	app.audio.apply_settings(app.saves.data.settings)
	for index in range(40, 45):
		app.start_level(index)
		app.level.player.synthetic = true
		await capture("thread_%02d_start" % (index + 1))
		var fixture: Array = JSON.parse_string(
			FileAccess.get_file_as_string("res://tests/fixtures/%s.json" % app.level.level_id)
		)
		var captured: bool = false
		for input: Array in fixture:
			app.level.player.drive_input(float(input[0]), bool(input[1]), bool(input[2]))
			app.level.player.drive_tools(bool(input[3]), bool(input[4]), bool(input[5]))
			await physics_frame
			var x: float = app.level.player.position.x
			var tool: ThreadTool = app.level.thread_tool
			var ready: bool = (
				(index == 40 and x > 300 and tool.relay_powered())
				or (index == 41 and x > 310 and tool.grapple_index >= 0)
				or (index == 42 and x > 350)
				or (index == 43 and x < 420 and tool.rewinding)
				or (index == 44 and x > 1000)
			)
			if ready and not captured:
				captured = true
				await capture("thread_%02d_action" % (index + 1))
		if not captured:
			push_error("No action capture for lesson " + str(index + 1))
	app.set_process(false)
	app.audio.stop_all(true)
	await create_timer(0.12).timeout
	app.queue_free()
	for frame in 4:
		await process_frame
	quit()

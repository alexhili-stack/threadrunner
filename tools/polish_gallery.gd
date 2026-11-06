extends SceneTree

var app: Node2D


func _initialize() -> void:
	call_deferred("execute")


func capture(name: String) -> void:
	for frame in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/captures/%s.png" % name)


func execute() -> void:
	app = load("res://scenes/app/main.tscn").instantiate()
	root.add_child(app)
	app.saves.data.settings.mute = true
	app.audio.apply_settings(app.saves.data.settings)
	for index: int in [0, 3, 7, 12, 29]:
		app.start_level(index)
		app.level.player.synthetic = true
		await capture("pilot_%02d_start" % (index + 1))
		var fixture: Array = JSON.parse_string(
			FileAccess.get_file_as_string(
				"res://tests/fixtures/%s.json" % LevelCatalog.id_for(index)
			)
		)
		for tick in fixture.size() / 2:
			var input: Array = fixture[tick]
			app.level.player.drive_input(float(input[0]), bool(input[1]), bool(input[2]))
			await physics_frame
		app.run.set_paused(true)
		await capture("pilot_%02d_mid" % (index + 1))
	app.start_level(20)
	app.level.player.synthetic = true
	while app.level.elapsed < 2.2:
		await physics_frame
	app.run.set_paused(true)
	await capture("vent_warning")
	app.run.set_paused(false)
	while app.level.elapsed < 2.8:
		await physics_frame
	app.run.set_paused(true)
	await capture("vent_active")
	app.set_process(false)
	app.audio.stop_all(true)
	await create_timer(0.12).timeout
	app.queue_free()
	for frame in 4:
		await process_frame
	quit()

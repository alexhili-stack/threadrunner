extends SceneTree

var app: Node2D


func _initialize() -> void:
	call_deferred("execute")


func snap(name: String) -> void:
	app.run.set_paused(true)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/foundry/" + name + ".png")


func execute() -> void:
	DirAccess.make_dir_recursive_absolute("res://artifacts/foundry")
	app = load("res://scenes/app/main.tscn").instantiate()
	root.add_child(app)
	root.size = Vector2i(1672, 941)
	app.saves.data.settings.mute = true
	app.apply_settings()
	for index in [3, 29, 39, 41, 44]:
		app.start_level(index)
		app.level.player.synthetic = true
		var fixture: Array = JSON.parse_string(
			FileAccess.get_file_as_string(
				"res://tests/fixtures/%s.json" % LevelCatalog.id_for(index)
			)
		)
		var limit: int = 110
		if index == 41:
			for tick in fixture.size():
				if fixture[tick].size() >= 6 and bool(fixture[tick][4]):
					limit = tick + 13
					break
		for tick in mini(limit, fixture.size()):
			var input: Array = fixture[tick]
			app.level.player.drive_input(float(input[0]), bool(input[1]), bool(input[2]))
			if input.size() >= 6:
				app.level.player.drive_tools(bool(input[3]), bool(input[4]), bool(input[5]))
			await physics_frame
		await snap("room_%02d" % (index + 1))
		print("Captured ", index + 1, " tether ", app.level.thread_tool.grapple_index)
	app.show_help("pause")
	await snap("help")
	app.show_settings("pause")
	await snap("settings-selected-toggle")
	app.selected_chapter = 4
	app.show_select()
	await snap("chapter-selected")
	app.show_menu()
	await snap("menu")
	var reference: Image = Image.new()
	reference.load_png_from_buffer(
		FileAccess.get_file_as_bytes("res://docs/design/electric_foundry_reference.png")
	)
	var actual: Image = Image.load_from_file("res://artifacts/foundry/room_42.png")
	reference.convert(Image.FORMAT_RGBA8)
	actual.convert(Image.FORMAT_RGBA8)
	var comparison: Image = Image.create(
		reference.get_width() + actual.get_width(),
		maxi(reference.get_height(), actual.get_height()),
		false,
		Image.FORMAT_RGBA8
	)
	comparison.fill(Color("08090b"))
	comparison.blit_rect(reference, Rect2i(Vector2i.ZERO, reference.get_size()), Vector2i.ZERO)
	comparison.blit_rect(
		actual, Rect2i(Vector2i.ZERO, actual.get_size()), Vector2i(reference.get_width(), 0)
	)
	comparison.save_png("res://artifacts/foundry/reference-and-game.png")
	app.set_process(false)
	app.audio.stop_all(true)
	app.queue_free()
	for frame in 4:
		await process_frame
	quit()

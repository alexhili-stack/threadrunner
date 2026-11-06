extends SceneTree

var app: Node2D
var checks: Array[Dictionary] = []


func _initialize() -> void:
	call_deferred("execute")


func check(label: String, passed: bool) -> void:
	checks.append({"name": label, "pass": passed})
	print(label, ": ", passed)


func frames(count: int = 3) -> void:
	for tick in count:
		await process_frame


func capture(name: String) -> void:
	await frames(3)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/captures/%s.png" % name)


func key(code: int) -> void:
	var event: InputEventKey = InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	# GUI input needs render processing; gameplay polling also needs physics ticks.
	await frames(2)
	for tick in 3:
		await physics_frame
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	await frames(2)
	for tick in 3:
		await physics_frame


func execute() -> void:
	DirAccess.make_dir_recursive_absolute("res://artifacts/captures")
	app = load("res://scenes/app/main.tscn").instantiate()
	root.add_child(app)
	await frames()
	check("main menu focus", root.gui_get_focus_owner() is Button)
	await capture("menu_1280")
	await key(KEY_ENTER)
	check("keyboard confirm starts gameplay", app.page == "game")
	check("player uses configured jump action", InputMap.has_action("jump"))
	check("rewind meter stays within compact HUD", app.thread_meter.size.y <= 3)
	check(
		"gameplay has no instruction or timer overlays",
		not app.hint.visible and not app.hud.visible and app.control_hint == null
	)
	var visible_game_text: bool = false
	for child: Node in app.ui.get_children():
		if child is Label and child.visible and not child.text.is_empty():
			visible_game_text = true
	check("playing canvas contains no visible text labels", not visible_game_text)
	await capture("gameplay_1280")
	await key(KEY_ESCAPE)
	check("keyboard pause", app.page == "pause" and app.run.paused)
	await capture("pause_1280")
	app.show_settings("pause")
	await frames()
	check("settings visible focus", root.gui_get_focus_owner() is Button)
	await capture("settings_1280")
	for child: Node in app.ui.get_children():
		if child is Button and child.text == "Controls":
			child.grab_focus()
			break
	await key(KEY_ENTER)
	check("keyboard switches settings tabs", app.settings_tab == "Controls")
	await capture("controls_1280")
	check(
		"controls tab exposes remapping",
		app.ui.get_children().any(
			func(child: Node) -> bool: return child is Button and "Jump" in child.text
		)
	)
	app.controls_group = "Thread"
	app.show_settings("pause")
	await capture("thread_controls_1280")
	check(
		"thread bindings visible",
		app.ui.get_children().any(
			func(child: Node) -> bool: return child is Button and "Grapple" in child.text
		)
	)
	app.controls_group = "Movement"
	app.settings_tab = "Display"
	app.show_settings("pause")
	await capture("display_1280")
	check(
		"display tab exposes reset confirmation",
		app.ui.get_children().any(
			func(child: Node) -> bool: return child is Button and child.text == "Reset progress..."
		)
	)
	app.settings_tab = "Controls"
	app.show_settings("pause")
	app.binding_action = "jump"
	await key(KEY_J)
	check("synthetic key remapping", app.inputs.label_for("jump") == "J")
	app.inputs.configure()
	app.saves.data.settings.bindings = app.inputs.bindings
	app.settings_back()
	await key(KEY_ESCAPE)
	check("back resumes paused game", app.page == "game" and not app.run.paused)
	app.show_pause()
	var location: Vector2 = app.level.player.position
	await key(KEY_D)
	check("menu does not move player", app.level.player.position == location)
	app.show_select()
	await capture("select_1280")
	app.start_level(19)
	app.level.player.synthetic = true
	await capture("clockwork_1280")
	app.show_menu()
	DisplayServer.window_set_size(Vector2i(640, 360))
	await capture("menu_640")
	app.settings_tab = "Sound"
	app.show_settings("menu")
	await capture("settings_640")
	app.settings_tab = "Controls"
	app.show_settings("menu")
	await capture("controls_640")
	app.settings_tab = "Display"
	app.show_settings("menu")
	await capture("display_640")
	app.start_level(0)
	app.level.player.synthetic = true
	var fixture: Array = JSON.parse_string(
		FileAccess.get_file_as_string("res://tests/fixtures/chapter_01_room_01.json")
	)
	for input: Array in fixture:
		app.level.player.drive_input(float(input[0]), bool(input[1]), bool(input[2]))
		await physics_frame
	await frames()
	print(
		"UI ROUTE STATE ",
		app.page,
		" / ",
		app.run.state,
		" at ",
		app.level.player.position,
		" deaths ",
		app.run.deaths,
		" time ",
		app.run.attempt_time,
		" jump lock ",
		app.level.player.require_jump_release,
		" active ",
		app.level.player.active
	)
	check("actual gameplay completion reaches clear page", app.page == "complete")
	await capture("completion_640")
	app.saves.data.settings.mute = true
	app.audio.apply_settings(app.saves.data.settings)
	check("mute routes to master", AudioServer.is_bus_mute(0))
	for repeat in 100:
		app.audio.play("death")
	check(
		"sound overlap bounded",
		(
			app.audio.voices.size() == 8
			and app.audio.music_voices.size() == 2
			and app.audio.get_child_count() == 10
		)
	)
	app.audio.play("missing-event")
	app.audio.stop_all()
	check("restart audio cleanup", not app.audio.voices[0].playing)
	app.show_credits()
	await capture("credits_640")
	app.start_level(0)
	var axis: InputEventJoypadMotion = InputEventJoypadMotion.new()
	axis.axis = JOY_AXIS_LEFT_X
	axis.axis_value = 1.0
	Input.parse_input_event(axis)
	for tick in 10:
		await physics_frame
	check("synthetic controller movement", app.level.player.position.x > 50)
	axis = axis.duplicate()
	axis.axis_value = 0
	Input.parse_input_event(axis)
	var jump: InputEventJoypadButton = InputEventJoypadButton.new()
	jump.button_index = JOY_BUTTON_A
	jump.pressed = true
	Input.parse_input_event(jump)
	for tick in 3:
		await physics_frame
	check("synthetic controller jump", app.level.player.position.y < 310)
	jump = jump.duplicate()
	jump.pressed = false
	Input.parse_input_event(jump)
	var pause: InputEventJoypadButton = InputEventJoypadButton.new()
	pause.button_index = JOY_BUTTON_START
	pause.pressed = true
	Input.parse_input_event(pause)
	await frames()
	check("synthetic controller pause", app.page == "pause")
	pause = pause.duplicate()
	pause.pressed = false
	Input.parse_input_event(pause)
	app.show_hud()
	app._on_controller_change(0, false)
	check("disconnect handler pauses safely", app.page == "pause")
	app.show_hud()
	app._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	check("focus loss pauses safely", app.page == "pause")
	app.saves.data.settings.reduced_effects = true
	app.apply_settings()
	check("reduced effects reaches visuals", app.level.player.get_node("Visuals").reduced_effects)
	app.saves.data.settings.fullscreen = true
	app.apply_settings()
	await frames(5)
	check(
		"fullscreen transition",
		DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	)
	app.saves.data.settings.fullscreen = false
	app.apply_settings()
	await frames(5)
	check(
		"windowed transition", DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED
	)
	check("four original chapter loops", app.audio.music_tracks.size() == 4)
	app.show_select()
	app.select_preview(39)
	check(
		"large-room preview and title",
		app.preview.world_size.x == 1280 and "40" in app.preview_title.text
	)
	await capture("select_large_640")
	app.start_level(39)
	check(
		"large room installs bounded camera",
		is_instance_valid(app.level.camera) and app.level.camera.limit_right == 1280
	)
	app.level.player.synthetic = true
	await capture("afterlight_640")
	var large_fixture: Array = JSON.parse_string(
		FileAccess.get_file_as_string("res://tests/fixtures/chapter_04_room_10.json")
	)
	for input: Array in large_fixture:
		app.level.player.drive_input(float(input[0]), bool(input[1]), bool(input[2]))
		await physics_frame
		if app.level.player.position.x > 800:
			break
	await frames()
	check("camera follows actual traversal", app.level.camera.get_screen_center_position().x > 640)
	await capture("afterlight_scrolling_640")
	app.start_level(40)
	var move: InputEventKey = InputEventKey.new()
	move.keycode = KEY_D
	move.physical_keycode = KEY_D
	move.pressed = true
	Input.parse_input_event(move)
	for tick in 31:
		await physics_frame
	move = move.duplicate()
	move.pressed = false
	Input.parse_input_event(move)
	await key(KEY_E)
	check("keyboard stitch creates a bridge", app.level.thread_tool.relay_powered())
	await key(KEY_SHIFT)
	check("keyboard rewind moves along history", app.level.thread_tool.rewound_distance > 0)
	app.inputs.rebind("thread_stitch", KEY_G)
	app.start_level(40)
	await frames(3)
	check("lesson instructions stay off the playfield", not app.hint.visible)
	app.show_help("pause")
	await frames(3)
	check("help follows thread remapping", "G  Stitch" in app.help_text.text)
	check("help keeps gameplay paused", app.run.paused and app.page == "help")
	app._help_back()
	check("help returns to pause", app.page == "pause")
	app.inputs.configure()
	app.start_level(41)
	move = move.duplicate()
	move.pressed = true
	Input.parse_input_event(move)
	for tick in 42:
		await physics_frame
	move = move.duplicate()
	move.pressed = false
	Input.parse_input_event(move)
	var grapple: InputEventJoypadButton = InputEventJoypadButton.new()
	grapple.button_index = JOY_BUTTON_B
	grapple.pressed = true
	Input.parse_input_event(grapple)
	await frames(4)
	check(
		"controller B grapples without opening pause",
		app.page == "game" and app.level.thread_tool.grapple_index >= 0
	)
	grapple = grapple.duplicate()
	grapple.pressed = false
	Input.parse_input_event(grapple)
	app.selected_chapter = 4
	app.show_select()
	await capture("thread_select_640")
	var file: FileAccess = FileAccess.open("res://artifacts/ui.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(checks, "\t"))
	file.close()
	var failed: bool = checks.any(func(item: Dictionary) -> bool: return not item.pass)
	app.set_process(false)
	app.audio.stop_all(true)
	await create_timer(0.12).timeout
	app.queue_free()
	await frames(4)
	quit(1 if failed else 0)

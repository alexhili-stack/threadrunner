extends Node2D

const INK: Color = ThreadStyle.PAPER
const MUTED: Color = ThreadStyle.SECONDARY
const ACCENT: Color = ThreadStyle.THREAD
var saves: SaveService
var inputs: InputService = InputService.new()
var audio: AudioService
var run: RunController
var level: LevelRoot
var level_container: Node2D
var canvas: CanvasLayer
var ui: Control
var hud: Label
var hint: Label
var page: String = "menu"
var return_page: String = "menu"
var level_index: int = 0
var binding_action: String = ""
var notice: Label
var debug: bool = false
var debug_label: Label
var shake_left: float = 0.0
var complete_pending: bool = false
var backdrop: Node2D
var control_hint: Label
var last_input_controller: bool = false
var last_input_touch: bool = false
var previous_best: float = 0.0
var preview: Control
var preview_title: Label
var preview_details: Label
var preview_index: int = 0
var hud_status: Label
var settings_tab: String = "Sound"
var controls_group: String = "Movement"
var selected_chapter: int = 0
var thread_status: Label
var thread_meter: ThreadMeter


func _ready() -> void:
	get_tree().auto_accept_quit = false
	var save_dir: String = "user://"
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--save-dir="):
			save_dir = arg.trim_prefix("--save-dir=")
	saves = SaveService.new(save_dir)
	saves.load_save()
	inputs.configure(saves.data.settings.bindings, saves.data.settings.deadzone)
	var background_layer: CanvasLayer = CanvasLayer.new()
	background_layer.layer = -1
	add_child(background_layer)
	backdrop = preload("res://scripts/ui/backdrop.gd").new()
	background_layer.add_child(backdrop)
	level_container = Node2D.new()
	level_container.name = "LevelContainer"
	add_child(level_container)
	run = RunController.new()
	run.name = "RunController"
	add_child(run)
	run.player_died.connect(_on_death)
	run.collectible_touched.connect(func() -> void: audio.play("fragment"))
	run.attempt_finished.connect(_on_clear)
	canvas = CanvasLayer.new()
	add_child(canvas)
	ui = Control.new()
	ui.theme = ThreadStyle.make_theme()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(ui)
	audio = AudioService.new()
	add_child(audio)
	apply_settings()
	Input.joy_connection_changed.connect(_on_controller_change)
	show_menu()
	if OS.has_feature("web"):
		add_child(preload("res://scripts/services/browser_bridge.gd").new())
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--room="):
			start_level(clampi(int(arg.trim_prefix("--room=")) - 1, 0, LevelCatalog.COUNT - 1))
	var fixture: String = ""
	var output: String = ""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--qa-fixture="):
			fixture = arg.trim_prefix("--qa-fixture=")
		if arg.begins_with("--qa-output="):
			output = arg.trim_prefix("--qa-output=")
	if not fixture.is_empty() and not output.is_empty():
		preload("res://scripts/services/replay_verifier.gd").execute.call_deferred(
			self, fixture, output
		)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		quit_game()
	if (
		what == NOTIFICATION_APPLICATION_FOCUS_OUT
		and not OS.has_feature("web")
		and page == "game"
		and is_instance_valid(run)
	):
		show_pause()


func clear_ui() -> void:
	for child: Node in ui.get_children():
		ui.remove_child(child)
		child.queue_free()
	hud = null
	hint = null
	debug_label = null
	control_hint = null
	hud_status = null
	thread_status = null
	thread_meter = null


func text_at(
	value: String, position: Vector2, size: int = 12, color: Color = INK, width: float = 560
) -> Label:
	var label: Label = Label.new()
	label.text = value
	label.position = position
	label.size.x = width
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	if size >= 20:
		label.add_theme_font_override("font", ThreadStyle.DISPLAY)
	ui.add_child(label)
	return label


func button(
	value: String, position: Vector2, callback: Callable, width: float = 200, enabled: bool = true
) -> Button:
	var control: Button = Button.new()
	control.text = value
	control.position = position
	control.size = Vector2(width, 30)
	control.disabled = not enabled
	control.alignment = HORIZONTAL_ALIGNMENT_LEFT
	control.add_theme_font_size_override("font_size", 12)
	if width < 40:
		control.alignment = HORIZONTAL_ALIGNMENT_CENTER
		for state: String in ["normal", "hover", "pressed", "disabled"]:
			var box: StyleBoxFlat = ui.theme.get_stylebox(state, "Button").duplicate()
			box.content_margin_left = 0
			box.content_margin_right = 0
			control.add_theme_stylebox_override(state, box)
	control.pressed.connect(
		func() -> void:
			audio.play("menu")
			callback.call()
	)
	ui.add_child(control)
	control.focus_entered.connect(func() -> void: audio.play("menu"))
	return control


func footer(value: String = "A / D  MOVE     SPACE  JUMP     R  RETRY     ESC  PAUSE") -> void:
	var lesson: bool = page == "game" and not level.thread_goal.is_empty()
	if page == "game" and not lesson:
		_rule(Vector2(0, 345), Vector2(640, 15), Color("09171e"))
	control_hint = text_at(
		value, Vector2(24, 73 if lesson else 346 if page == "game" else 338), 9, MUTED, 600
	)


func _rule(position: Vector2, extent: Vector2, color: Color = ThreadStyle.LINE) -> void:
	var line: ColorRect = ColorRect.new()
	line.position = position
	line.size = extent
	line.color = color
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(line)


func _artwork(position: Vector2, mode: String = "hero") -> Control:
	var art: Control = preload("res://scripts/ui/signal_art.gd").new()
	art.position = position
	art.mode = mode
	art.reduced_effects = saves.data.settings.reduced_effects
	ui.add_child(art)
	return art


func _heading(value: String, back: Callable) -> void:
	text_at(value, Vector2(24, 14), 34)
	button("Back", Vector2(532, 24), back, 84).grab_focus()
	_rule(Vector2(24, 64), Vector2(592, 1))


func show_menu() -> void:
	page = "menu"
	backdrop.chapter = 0
	audio.set_context(1, true)
	run.set_paused(true)
	level_container.visible = false
	clear_ui()
	var title: Label = text_at("THREAD\nRUNNER", Vector2(28, 13), 76, INK, 300)
	title.add_theme_constant_override("line_spacing", -18)
	_rule(Vector2(32, 100), Vector2(230, 2), ACCENT)
	text_at("Carry the last signal.", Vector2(33, 182), 15)
	_artwork(Vector2(346, 29))
	var next: int = 0
	while next < LevelCatalog.COUNT - 1 and saves.data.completed.has(LevelCatalog.id_for(next)):
		next += 1
	var resume: Button = button(
		(
			"Begin the run"
			if saves.data.completed.is_empty()
			else "Continue   /   Room %02d" % (next + 1)
		),
		Vector2(33, 219),
		func() -> void: start_level(next),
		242
	)
	ThreadStyle.primary(resume)
	resume.grab_focus()
	button("Room select", Vector2(33, 258), show_select, 117)
	button("Thread lessons", Vector2(158, 258), func() -> void: start_level(40), 117)
	if OS.has_feature("web"):
		button("Settings", Vector2(33, 294), func() -> void: show_settings("menu"), 117)
		button("Credits", Vector2(158, 294), show_credits, 117)
	else:
		button("Settings", Vector2(33, 294), func() -> void: show_settings("menu"), 75)
		button("Credits", Vector2(116, 294), show_credits, 76)
		button("Quit", Vector2(200, 294), quit_game, 75)
	text_at("40 rooms. Five thread lessons.", Vector2(352, 279), 12, MUTED, 270)
	text_at(
		(
			"%02d cleared    /    %02d fragments"
			% [saves.data.completed.size(), saves.data.fragments.size()]
		),
		Vector2(352, 303),
		10,
		MUTED,
		270
	)
	footer("KEYBOARD OR CONTROLLER     /     ENTER TO CONFIRM     /     ESC TO GO BACK")


func show_select() -> void:
	page = "select"
	run.set_paused(true)
	level_container.visible = false
	audio.set_context(selected_chapter + 1, true)
	clear_ui()
	_heading("ROOM SELECT", show_menu)
	for i in LevelCatalog.CHAPTERS.size():
		var chapter_button: Button = button(
			["Boot", "Clockwork", "Last thread", "Afterlight", "Threadwork"][i],
			Vector2(24 + i * 120, 78),
			func() -> void:
				selected_chapter = i
				show_select(),
			112
		)
		if i == selected_chapter:
			chapter_button.add_theme_stylebox_override("normal", ThreadStyle.panel(Color("23464a")))
			chapter_button.add_theme_color_override("font_color", ACCENT)
	text_at(LevelCatalog.CHAPTERS[selected_chapter], Vector2(25, 123), 26, INK, 305)
	preview_title = text_at("", Vector2(352, 126), 24, INK, 264)
	preview_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	preview = preload("res://scripts/ui/room_preview.gd").new()
	preview.position = Vector2(352, 185)
	preview.size = Vector2(264, 108)
	ui.add_child(preview)
	preview_details = text_at("", Vector2(352, 301), 9, MUTED, 264)
	preview_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var first: int = selected_chapter * 10
	for slot in mini(10, LevelCatalog.COUNT - first):
		var index: int = first + slot
		var id: String = LevelCatalog.id_for(index)
		var unlocked: bool = id in saves.data.unlocked or index == LevelCatalog.BASE_COUNT
		var position: Vector2 = Vector2(25 + (slot % 5) * 60, 174 + (slot / 5) * 57)
		var b: Button = button(
			"%02d" % (index + 1), position, func() -> void: start_level(index), 52, unlocked
		)
		b.alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.focus_entered.connect(func() -> void: select_preview(index))
		b.mouse_entered.connect(func() -> void: select_preview(index))
		b.tooltip_text = LevelCatalog.entry(index).display_name
		if saves.data.completed.has(id):
			_rule(position + Vector2(6, 30), Vector2(40, 2), ACCENT)
		if id in saves.data.fragments:
			_artwork(position + Vector2(43, -3), "diamond")
		if slot == 0 and unlocked:
			b.grab_focus()
	select_preview(first)
	var note: Label = text_at(
		(
			"Five lessons in stitching, swinging and rewinding."
			if selected_chapter == 4
			else "Follow the route. Find the fragment. Carry the signal."
		),
		Vector2(25, 286),
		11,
		MUTED,
		285
	)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	footer("UNDERLINE: CLEARED     /     GOLD DIAMOND: FRAGMENT     /     DIMMED: LOCKED")


func select_preview(index: int) -> void:
	preview_index = index
	preview.set_room(index)
	var definition: LevelDefinition = LevelCatalog.entry(index)
	preview_title.text = "%02d / %s" % [index + 1, definition.display_name]
	var id: String = definition.stable_id
	var best: float = float(saves.data.completed.get(id, 0.0))
	var record: String = (
		"Best %.2f s" % best
		if best > 0
		else ("Cleared / no current record" if saves.data.completed.has(id) else "No record yet")
	)
	preview_details.text = (
		"%s   /   %s\n%s"
		% [
			record,
			"Fragment secured" if id in saves.data.fragments else "Fragment available",
			"1280 x 360 / scrolling" if preview.world_size.x > 640 else "640 x 360 / single screen"
		]
	)
	backdrop.chapter = definition.chapter


func refresh_control_hint() -> void:
	if page != "game" or not is_instance_valid(control_hint):
		return
	if last_input_touch:
		control_hint.text = (
			"TOUCH CONTROLS BELOW   /   JUMP RELEASES A GRAPPLE   /   " + "HOLD REWIND TO RETURN"
		)
	elif last_input_controller:
		control_hint.text = (
			"STICK MOVE   A JUMP   X STITCH   B GRAPPLE   " + "LB REWIND   Y RETRY   START PAUSE"
		)
	else:
		control_hint.text = (
			("%s/%s MOVE   %s JUMP   %s STITCH   " + "%s GRAPPLE   %s REWIND   %s RETRY   %s PAUSE")
			% [
				inputs.label_for("move_left"),
				inputs.label_for("move_right"),
				inputs.label_for("jump"),
				inputs.label_for("thread_stitch"),
				inputs.label_for("thread_grapple"),
				inputs.label_for("thread_rewind"),
				inputs.label_for("restart"),
				inputs.label_for("pause")
			]
		)
	control_hint.add_theme_font_size_override("font_size", 8)


func _room_hint() -> String:
	if last_input_touch:
		return (
			level
			. purpose
			. replace("E beside", "Stitch beside")
			. replace("F grabs", "Grapple grabs")
			. replace("Hold Shift", "Hold Rewind")
		)
	return (
		level
		. purpose
		. replace(
			"E beside", "%s beside" % inputs.label_for("thread_stitch", last_input_controller)
		)
		. replace("F grabs", "%s grabs" % inputs.label_for("thread_grapple", last_input_controller))
		. replace(
			"Hold Shift", "Hold %s" % inputs.label_for("thread_rewind", last_input_controller)
		)
	)


func quit_game() -> void:
	if OS.has_feature("web"):
		saves.write_save()
		show_menu()
		return
	set_process(false)
	saves.write_save()
	audio.stop_all(true)
	await get_tree().create_timer(0.06).timeout
	get_tree().quit()


func start_level(index: int) -> void:
	if is_instance_valid(level):
		level_container.remove_child(level)
		level.queue_free()
	audio.stop_all()
	level_index = index
	selected_chapter = index / 10
	backdrop.chapter = index / 10 + 1
	audio.set_context(index / 10 + 1)
	level = load(LevelCatalog.scene_path(index)).instantiate()
	level_container.add_child(level)
	level.player.feedback.connect(audio.play)
	level.reduced_effects = saves.data.settings.reduced_effects
	level.player.get_node("Visuals").reduced_effects = saves.data.settings.reduced_effects
	level_container.visible = true
	run.begin(level)
	show_hud()


func show_hud() -> void:
	page = "game"
	level_container.visible = true
	clear_ui()
	text_at(
		"%02d / %s" % [level_index + 1, LevelCatalog.entry(level_index).display_name.to_upper()],
		Vector2(19, 4),
		22,
		INK,
		390
	)
	text_at(LevelCatalog.CHAPTERS[level_index / 10], Vector2(20, 31), 9, ACCENT, 350)
	hud = text_at("", Vector2(476, 3), 23, INK, 104)
	hud_status = text_at("", Vector2(476, 32), 9, MUTED, 144)
	thread_status = text_at("", Vector2(476, 48), 8, ACCENT, 150)
	thread_meter = ThreadMeter.new()
	thread_meter.position = Vector2(476, 61)
	thread_meter.size = Vector2(140, 2)
	thread_meter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(thread_meter)
	button("Pause", Vector2(581, 6), show_pause, 45).add_theme_font_size_override("font_size", 9)
	hint = text_at(level.purpose, Vector2(20, 48), 9, MUTED, 440)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	debug_label = text_at("", Vector2(20, 69), 9, ThreadStyle.GOLD)
	footer()
	run.set_paused(false)
	audio.set_context(level_index / 10 + 1)
	refresh_control_hint()


func overlay(title: String, subtitle: String) -> void:
	clear_ui()
	_rule(Vector2.ZERO, Vector2(640, 360), Color(0.025, 0.065, 0.085, 0.94))
	text_at(title, Vector2(86, 47), 44, INK, 490)
	var sub: Label = text_at(subtitle, Vector2(88, 106), 12, MUTED, 464)
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_rule(Vector2(88, 137), Vector2(464, 1))


func show_pause() -> void:
	if not is_instance_valid(level):
		return
	page = "pause"
	audio.set_context(level_index / 10 + 1, true)
	run.set_paused(true)
	audio.stop_all()
	overlay("PAUSED", "Take a breath. Hold the thread.")
	var resume: Button = button("Resume", Vector2(88, 157), show_hud, 240)
	ThreadStyle.primary(resume)
	resume.grab_focus()
	button(
		"Restart room",
		Vector2(88, 194),
		func() -> void:
			run.restart()
			show_hud(),
		240
	)
	button("Settings", Vector2(88, 231), func() -> void: show_settings("pause"), 116)
	button("Room select", Vector2(212, 231), show_select, 116)
	button("Main menu", Vector2(88, 268), show_menu, 240)
	text_at("%02d" % (level_index + 1), Vector2(404, 145), 64, ACCENT, 160)
	var room_name: Label = text_at(
		LevelCatalog.entry(level_index).display_name, Vector2(404, 220), 20, INK, 164
	)
	room_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_at("%02d retries this room" % run.deaths, Vector2(404, 281), 10, MUTED, 180)
	footer("ESC / START TO RESUME")


func _on_death() -> void:
	saves.data.deaths += 1
	saves.write_save()
	audio.play("death")
	if saves.data.settings.shake and not saves.data.settings.reduced_effects:
		shake_left = 0.10


func _on_clear(seconds: float, fragment: bool) -> void:
	previous_best = float(saves.data.completed.get(level.level_id, 0.0))
	saves.record_clear(level.level_id, seconds, fragment)
	saves.write_save()
	audio.play("clear")
	complete_pending = true


func show_complete() -> void:
	page = "complete"
	var final: bool = level_index == LevelCatalog.COUNT - 1
	overlay("YOU'RE OUT." if final else "SIGNAL DELIVERED", "")
	text_at("%.2f s" % run.attempt_time, Vector2(88, 102), 34, INK, 220)
	text_at("%02d retries" % run.deaths, Vector2(257, 122), 10, MUTED, 100)
	var record_text: String = "First record on this layout"
	if previous_best > 0:
		record_text = (
			"New best / %.2f s faster" % (previous_best - run.attempt_time)
			if run.attempt_time < previous_best
			else "%.2f s behind your best" % (run.attempt_time - previous_best)
		)
	text_at(record_text, Vector2(88, 151), 10, ACCENT, 300)
	text_at(
		"Fragment secured" if level.fragment_collected else "Fragment waiting. Return for it.",
		Vector2(88, 174),
		11,
		ThreadStyle.GOLD,
		330
	)
	var next: Button = button(
		"Return to the beginning" if final else "Next room   /   %02d" % (level_index + 2),
		Vector2(88, 211),
		show_menu if final else func() -> void: start_level(level_index + 1),
		280
	)
	ThreadStyle.primary(next)
	next.grab_focus()
	button(
		"Retry for a better time",
		Vector2(88, 248),
		func() -> void:
			run.restart()
			show_hud(),
		280
	)
	button("Room select", Vector2(88, 285), show_select, 280)
	_artwork(Vector2(401, 158), "seal")
	text_at(
		"%02d / %02d" % [level_index + 1, LevelCatalog.COUNT], Vector2(435, 296), 13, MUTED, 120
	)
	if not saves.last_error.is_empty():
		text_at(saves.last_error, Vector2(24, 338), 10, ThreadStyle.DANGER)


func show_settings(origin: String) -> void:
	return_page = origin
	page = "settings"
	level_container.visible = false
	clear_ui()
	_heading("SETTINGS", settings_back)
	for i in 3:
		var tab: String = ["Sound", "Controls", "Display"][i]
		var control: Button = button(
			tab,
			Vector2(24 + i * 200, 78),
			func() -> void:
				settings_tab = tab
				show_settings(return_page),
			192
		)
		if tab == settings_tab:
			control.add_theme_stylebox_override("normal", ThreadStyle.panel(Color("23464a")))
			control.add_theme_color_override("font_color", ACCENT)
	match settings_tab:
		"Sound":
			_settings_sound()
		"Controls":
			_settings_controls()
		"Display":
			_settings_display()
	notice = text_at("Changes save automatically.   /   ESC to return", Vector2(25, 338), 9, MUTED)


func _toggle_setting(key: String, position: Vector2, width: float = 110) -> void:
	var toggle: Button = button(
		"On" if saves.data.settings[key] else "Off", position, func() -> void: pass, width
	)
	toggle.toggle_mode = true
	toggle.button_pressed = saves.data.settings[key]
	toggle.toggled.connect(
		func(value: bool) -> void:
			toggle.text = "On" if value else "Off"
			saves.data.settings[key] = value
			apply_settings()
			saves.write_save()
	)
	toggle.add_theme_stylebox_override("pressed", ThreadStyle.panel(Color("23464a"), ACCENT))


func _settings_sound() -> void:
	text_at("Sound", Vector2(36, 124), 28)
	text_at("Mute all", Vector2(399, 139), 12, MUTED, 100)
	_toggle_setting("mute", Vector2(504, 133), 100)
	var row: int = 0
	for key: String in ["master", "music", "effects"]:
		var y: float = 183 + row * 42
		text_at(key.capitalize(), Vector2(36, y - 3), 13, INK, 155)
		var amount: Label = text_at(
			"%d%%" % (saves.data.settings[key] * 100), Vector2(547, y), 11, MUTED, 60
		)
		var slider: HSlider = HSlider.new()
		slider.position = Vector2(212, y)
		slider.size = Vector2(302, 18)
		slider.max_value = 1
		slider.step = 0.05
		slider.value = saves.data.settings[key]
		ui.add_child(slider)
		slider.value_changed.connect(
			func(value: float) -> void:
				amount.text = "%d%%" % (value * 100)
				saves.data.settings[key] = value
				apply_settings()
				saves.write_save()
		)
		row += 1
	text_at("Four chapter soundscapes. Every movement has a voice.", Vector2(36, 309), 10, MUTED)


func _settings_controls() -> void:
	for group_index in 2:
		var group: String = ["Movement", "Thread"][group_index]
		var tab: Button = button(
			group,
			Vector2(36 + group_index * 136, 124),
			func() -> void:
				controls_group = group
				show_settings(return_page),
			130
		)
		if group == controls_group:
			tab.add_theme_color_override("font_color", ACCENT)
	var row: int = 0
	for action: String in InputService.DEFAULT_KEYS:
		if action.begins_with("thread_") != (controls_group == "Thread"):
			continue
		button(
			"%s   /   %s" % [InputService.LABELS[action], inputs.label_for(action)],
			Vector2(36, 166 + row * 31),
			func() -> void:
				binding_action = action
				notice.text = "Press a key for %s. Escape cancels." % InputService.LABELS[action],
			266
		)
		row += 1
	text_at("Controller", Vector2(348, 123), 26, INK, 240)
	text_at("Stick deadzone", Vector2(348, 163), 12, MUTED, 240)
	var deadzone: HSlider = HSlider.new()
	deadzone.position = Vector2(348, 190)
	deadzone.size = Vector2(242, 18)
	deadzone.min_value = 0.05
	deadzone.max_value = 0.55
	deadzone.step = 0.05
	deadzone.value = saves.data.settings.deadzone
	ui.add_child(deadzone)
	deadzone.value_changed.connect(
		func(value: float) -> void:
			saves.data.settings.deadzone = value
			inputs.configure(saves.data.settings.bindings, value)
			saves.write_save()
	)
	text_at(
		(
			"Stick / D-pad to move\nA jump   /   Y retry   /   Start pause\n"
			+ "X stitch   /   B grapple   /   LB rewind"
		),
		Vector2(348, 223),
		10,
		MUTED,
		250
	)
	button(
		"Restore default keys",
		Vector2(348, 276),
		func() -> void:
			inputs.configure({}, saves.data.settings.deadzone)
			saves.data.settings.bindings = inputs.bindings
			saves.write_save()
			show_settings(return_page),
		242
	)


func _settings_display() -> void:
	var keys: Array[String] = ["fullscreen", "shake", "reduced_effects"]
	var names: Array[String] = ["Fullscreen", "Screen shake", "Reduced effects"]
	var details: Array[String] = [
		"Fill the screen. F11 also toggles fullscreen.",
		"A brief nudge when the thread breaks.",
		"Reduce decorative trails, pulses and menu motion."
	]
	if OS.has_feature("web"):
		keys.remove_at(0)
		names.remove_at(0)
		details.remove_at(0)
		text_at("Use Fullscreen above the game to fill your display.", Vector2(36, 258), 10, MUTED)
	for i in keys.size():
		var y: float = 130 + i * 51
		text_at(names[i], Vector2(36, y), 15, INK, 390)
		text_at(details[i], Vector2(36, y + 24), 10, MUTED, 430)
		_toggle_setting(keys[i], Vector2(480, y + 3))
	var reset: Button = button("Reset progress...", Vector2(36, 290), confirm_reset, 180)
	reset.add_theme_color_override("font_color", ThreadStyle.DANGER)
	text_at("Cleared rooms, fragments and records.", Vector2(238, 298), 10, MUTED, 360)


func settings_back() -> void:
	binding_action = ""
	if return_page == "pause":
		level_container.visible = true
		show_pause()
	else:
		show_menu()


func confirm_reset() -> void:
	page = "reset_confirm"
	overlay(
		"RESET PROGRESS?", "Cleared rooms, fragments and records will be removed. Settings stay."
	)
	var keep: Button = button(
		"Keep my progress", Vector2(88, 176), func() -> void: show_settings(return_page), 464
	)
	ThreadStyle.primary(keep)
	keep.grab_focus()
	var reset: Button = button(
		"Reset local progress",
		Vector2(88, 218),
		func() -> void:
			saves.reset_progress()
			saves.write_save()
			show_settings(return_page),
		464
	)
	reset.add_theme_color_override("font_color", ThreadStyle.DANGER)


func apply_settings() -> void:
	audio.apply_settings(saves.data.settings)
	backdrop.reduced_effects = saves.data.settings.reduced_effects
	if is_instance_valid(level):
		level.reduced_effects = saves.data.settings.reduced_effects
		level.player.get_node("Visuals").reduced_effects = saves.data.settings.reduced_effects
	if DisplayServer.get_name() != "headless" and not OS.has_feature("web"):
		DisplayServer.window_set_mode(
			(
				DisplayServer.WINDOW_MODE_FULLSCREEN
				if saves.data.settings.fullscreen
				else DisplayServer.WINDOW_MODE_WINDOWED
			)
		)


func show_credits() -> void:
	page = "credits"
	level_container.visible = false
	clear_ui()
	_heading("THREADRUNNER", show_menu)
	text_at("An original precision platformer for Alexander Hili.", Vector2(32, 87), 15)
	text_at(
		(
			"Design & implementation\nAlexander Hili with Codex\n\n"
			+ "Art & sound\nOriginal vector drawing and synthesis\n\n"
			+ "Type\nBarlow Condensed & Manrope / SIL OFL 1.1"
		),
		Vector2(33, 132),
		11,
		MUTED,
		355
	)
	_artwork(Vector2(419, 119), "seal")
	text_at("Godot 4.7.2 / MIT\nGdUnit4 & gdtoolkit / MIT", Vector2(412, 279), 10, MUTED, 220)
	footer("LOCAL WINDOWS BUILD   /   ENGLISH   /   FULL LICENSES IN third_party/")


func _on_controller_change(_device: int, connected: bool) -> void:
	if not connected and page == "game":
		show_pause()


func _input(event: InputEvent) -> void:
	if event is InputEventKey or event is InputEventJoypadButton or event is InputEventJoypadMotion:
		last_input_touch = false
	if event is InputEventJoypadButton and event.pressed:
		last_input_controller = true
	elif event is InputEventJoypadMotion and absf(event.axis_value) > saves.data.settings.deadzone:
		last_input_controller = true
	elif event is InputEventKey and event.pressed:
		last_input_controller = false
	if page == "game":
		refresh_control_hint()
	if (
		not binding_action.is_empty()
		and event is InputEventKey
		and event.pressed
		and not event.echo
	):
		if event.physical_keycode != KEY_ESCAPE:
			if not inputs.rebind(binding_action, event.physical_keycode):
				notice.text = "Key already used or reserved. Choose another key."
				get_viewport().set_input_as_handled()
				return
			saves.data.settings.bindings = inputs.bindings.duplicate()
			saves.write_save()
		binding_action = ""
		get_viewport().set_input_as_handled()
		show_settings(return_page)
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F2:
			debug = not debug if OS.is_debug_build() else false
		if event.keycode == KEY_F11 and not OS.has_feature("web"):
			saves.data.settings.fullscreen = not saves.data.settings.fullscreen
			apply_settings()
			saves.write_save()
	if page == "game" and event.is_action_pressed("restart"):
		run.restart()
		audio.stop_all()
	elif (
		event.is_action_pressed("pause")
		or (page != "game" and event.is_action_pressed("ui_cancel"))
	):
		get_viewport().set_input_as_handled()
		match page:
			"game":
				show_pause()
			"pause":
				show_hud()
			"settings", "reset_confirm":
				settings_back()
			"select", "credits", "complete":
				show_menu()


func _process(delta: float) -> void:
	backdrop.menu_mode = page != "game"
	if complete_pending:
		complete_pending = false
		show_complete()
	if page == "game" and is_instance_valid(hud):
		hud.text = "%05.2f s" % run.attempt_time
		hud_status.text = (
			"%02d retries%s" % [run.deaths, " / fragment" if level.fragment_collected else ""]
		)
		debug_label.visible = debug
		debug_label.text = (
			"state %s | v %s | floor %s | coyote %.3f | buffer %.3f"
			% [
				level.player.motion,
				level.player.velocity,
				level.player.is_on_floor(),
				level.player.coyote,
				level.player.buffer
			]
		)
		var tool: ThreadTool = level.thread_tool
		thread_status.text = (
			"%.1f s rewind%s"
			% [float(tool.history.size()) / 60, " / tied" if tool.grapple_index >= 0 else ""]
		)
		thread_meter.value = (
			float(tool.history.size()) / (level.player.config.thread_history_seconds * 60) * 100
		)
		hint.text = tool.message if not tool.message.is_empty() else _room_hint()
		hint.visible = (
			not tool.message.is_empty() or run.attempt_time < 8 or not level.thread_goal.is_empty()
		)
	if shake_left > 0.0:
		shake_left -= delta
		level_container.position = Vector2(sin(shake_left * 260.0), cos(shake_left * 170.0)) * 1.5
	else:
		level_container.position = Vector2.ZERO

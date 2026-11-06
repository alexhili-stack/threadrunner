extends Node
## Browser-only presentation/input adapter. Movement stays in PlayerController.

var app: Node2D
var host: JavaScriptObject
var input_callback: JavaScriptObject
var pause_callback: JavaScriptObject
var clock: float = 0.0


func _ready() -> void:
	if not OS.has_feature("web"):
		set_process(false)
		return
	app = get_parent()
	host = JavaScriptBridge.get_interface("ThreadrunnerHost")
	if host == null:
		set_process(false)
		return
	input_callback = JavaScriptBridge.create_callback(_on_touch_input)
	pause_callback = JavaScriptBridge.create_callback(_on_browser_pause)
	host.connectInput(input_callback, pause_callback)


func _on_touch_input(args: Array) -> void:
	if args.size() != 2 or not args[0] is String or not args[1] is bool:
		return
	var action: String = args[0]
	if not InputService.DEFAULT_KEYS.has(action):
		return
	# Always accept releases; page transitions must never leave a held action stuck.
	if bool(args[1]) and app.page != "game" and action != "pause":
		return
	app.last_input_touch = true
	app.last_input_controller = false
	var event: InputEventAction = InputEventAction.new()
	event.action = action
	event.pressed = bool(args[1])
	Input.parse_input_event(event)
	app.refresh_control_hint()


func _on_browser_pause(_args: Array) -> void:
	if app.page == "game":
		app.show_pause()
	app.saves.write_save()


func _process(delta: float) -> void:
	clock += delta
	if clock < 0.1:
		return
	clock = 0.0
	var data: Dictionary = {
		"page": app.page,
		"room": app.level_index + 1,
		"completed": app.saves.data.completed.size(),
		"fragments": app.saves.data.fragments.size(),
		"persistent": OS.is_userfs_persistent(),
		"touch": app.last_input_touch
	}
	if is_instance_valid(app.level):
		data["name"] = LevelCatalog.entry(app.level_index).display_name
		data["x"] = app.level.player.position.x
		data["y"] = app.level.player.position.y
		data["retries"] = app.run.deaths
		data["time"] = app.run.attempt_time
		data["fragment"] = app.level.fragment_collected
		data["bridge"] = app.level.thread_tool.relay_powered()
		data["tether"] = app.level.thread_tool.grapple_index >= 0
		data["rewound"] = app.level.thread_tool.rewound_distance
	host.setStatus(JSON.stringify(data))

class_name InputService
extends RefCounted

const DEFAULT_KEYS: Dictionary = {
	"move_left": KEY_A,
	"move_right": KEY_D,
	"jump": KEY_SPACE,
	"restart": KEY_R,
	"pause": KEY_ESCAPE,
	"thread_stitch": KEY_E,
	"thread_grapple": KEY_F,
	"thread_rewind": KEY_SHIFT
}
const LABELS: Dictionary = {
	"move_left": "Move left",
	"move_right": "Move right",
	"jump": "Jump",
	"restart": "Restart",
	"pause": "Pause / back",
	"thread_stitch": "Stitch bridge",
	"thread_grapple": "Grapple / release",
	"thread_rewind": "Rewind trail"
}
var bindings: Dictionary = {}
var configured_deadzone: float = 0.25


func configure(saved: Dictionary = {}, deadzone: float = 0.25) -> void:
	configured_deadzone = clampf(deadzone, 0.05, 0.55)
	bindings = DEFAULT_KEYS.duplicate()
	var used: Array[int] = []
	for action: String in DEFAULT_KEYS:
		var key: int = (
			int(saved.get(action, DEFAULT_KEYS[action]))
			if (saved.get(action, DEFAULT_KEYS[action]) is int or saved.get(action) is float)
			else DEFAULT_KEYS[action]
		)
		if action.begins_with("thread_") and not saved.has(action) and key in used:
			for alternative: int in [KEY_Q, KEY_C, KEY_V, KEY_G, KEY_T, KEY_CTRL]:
				if not alternative in used:
					key = alternative
					break
		if key <= 0 or key in used or key == KEY_F2 or key == KEY_F11:
			bindings = DEFAULT_KEYS.duplicate()
			break
		bindings[action] = key
		used.append(key)
	for action: String in DEFAULT_KEYS:
		if not InputMap.has_action(action):
			InputMap.add_action(action, 0.25)
		InputMap.action_erase_events(action)
		InputMap.action_set_deadzone(action, clampf(deadzone, 0.05, 0.55))
		var event: InputEventKey = InputEventKey.new()
		event.physical_keycode = bindings[action]
		InputMap.action_add_event(action, event)
		if action == "move_left" or action == "move_right":
			var axis: InputEventJoypadMotion = InputEventJoypadMotion.new()
			axis.axis = JOY_AXIS_LEFT_X
			axis.axis_value = -1.0 if action == "move_left" else 1.0
			InputMap.action_add_event(action, axis)
		var button: InputEventJoypadButton = InputEventJoypadButton.new()
		button.button_index = {
			"move_left": JOY_BUTTON_DPAD_LEFT,
			"move_right": JOY_BUTTON_DPAD_RIGHT,
			"jump": JOY_BUTTON_A,
			"restart": JOY_BUTTON_Y,
			"pause": JOY_BUTTON_START,
			"thread_stitch": JOY_BUTTON_X,
			"thread_grapple": JOY_BUTTON_B,
			"thread_rewind": JOY_BUTTON_LEFT_SHOULDER
		}[action]
		InputMap.action_add_event(action, button)
		if action in ["move_left", "move_right", "jump"]:
			var extra: InputEventKey = InputEventKey.new()
			extra.physical_keycode = {
				"move_left": KEY_LEFT, "move_right": KEY_RIGHT, "jump": KEY_UP
			}[action]
			InputMap.action_add_event(action, extra)


func rebind(action: String, key: int) -> bool:
	if not action in bindings or key in [KEY_F2, KEY_F11, KEY_LEFT, KEY_RIGHT, KEY_UP]:
		return false
	for other: String in bindings:
		if other != action and bindings[other] == key:
			return false
	var changed: Dictionary = bindings.duplicate()
	changed[action] = key
	configure(changed, configured_deadzone)
	return true


func label_for(action: String, controller: bool = false) -> String:
	if controller:
		return (
			{
				"move_left": "Stick / D-pad",
				"move_right": "Stick / D-pad",
				"jump": "A",
				"restart": "Y",
				"pause": "Start",
				"thread_stitch": "X",
				"thread_grapple": "B",
				"thread_rewind": "LB"
			}
			. get(action, "A")
		)
	return OS.get_keycode_string(bindings.get(action, DEFAULT_KEYS.get(action, KEY_SPACE)))

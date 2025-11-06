extends Node
#class_name InputMgr

signal listening_started(action_name: String)
signal listening_canceled(action_name: String)
signal action_rebound(action_name: String, events: Array) # events: Array[InputEvent]

const SAVE_PATH := "user://input_map.json"
const JOY_AXIS_THRESHOLD := 0.5

var _is_listening := false
var _listening_action := ""
var _captured_from_button: WeakRef = null # optional: to tell which UI asked

func _ready() -> void:
	# Optional: ensure actions exist (idempotent)
	var required_actions := ["up", "down", "left", "right", "rotate left", "rotate right", "fire"]
	for a in required_actions:
		if not InputMap.has_action(a):
			InputMap.add_action(a)
	# Load saved bindings, if any
	load_bindings()

func start_listening_for(action_name: String, caller: Object = null) -> void:
	if _is_listening:
		return
	_is_listening = true
	_listening_action = action_name
	_captured_from_button = caller as WeakRef if caller else null
	emit_signal("listening_started", action_name)

func cancel_listening() -> void:
	if not _is_listening:
		return
	var action := _listening_action
	_is_listening = false
	_listening_action = ""
	_captured_from_button = null
	emit_signal("listening_canceled", action)

func _unhandled_input(event: InputEvent) -> void:
	if not _is_listening:
		return

	# Let ESC cancel, Delete/Backspace clear
	if event is InputEventKey and event.pressed and not event.echo:
		var key := event as InputEventKey
		if key.physical_keycode == KEY_ESCAPE:
			cancel_listening()
			get_viewport().set_input_as_handled()
			return
		if key.physical_keycode in [KEY_DELETE, KEY_BACKSPACE]:
			_apply_rebind(_listening_action, [])
			get_viewport().set_input_as_handled()
			return

	var ev := _filter_capture(event)
	if ev == null:
		return

	# For this example we store a single event per action; adjust if you want multiples.
	_apply_rebind(_listening_action, [ev])
	get_viewport().set_input_as_handled()

func _filter_capture(event: InputEvent) -> InputEvent:
	# We only accept "pressed" events for clarity, ignore motion/etc.
	if event is InputEventKey:
		var e := event as InputEventKey
		if e.pressed and not e.echo:
			# Normalize keyboard: prefer physical_keycode for layout stability.
			var k := InputEventKey.new()
			k.physical_keycode = e.physical_keycode
			k.alt_pressed = e.alt_pressed
			k.shift_pressed = e.shift_pressed
			k.ctrl_pressed = e.ctrl_pressed
			k.meta_pressed = e.meta_pressed
			return k

	if event is InputEventMouseButton:
		var m := event as InputEventMouseButton
		if m.pressed:
			var mb := InputEventMouseButton.new()
			mb.button_index = m.button_index
			return mb

	if event is InputEventJoypadButton:
		var jb := event as InputEventJoypadButton
		if jb.pressed:
			var jj := InputEventJoypadButton.new()
			jj.button_index = jb.button_index
			jj.device = jb.device
			return jj

	if event is InputEventJoypadMotion:
		var jm := event as InputEventJoypadMotion
		# Turn an axis movement past threshold into a virtual "axis direction" binding.
		if absf(jm.axis_value) >= JOY_AXIS_THRESHOLD:
			var dir := signf(jm.axis_value) # -1 or +1
			# We'll store direction in 'pressure' for reconstruction.
			var jn := InputEventJoypadMotion.new()
			jn.axis = jm.axis
			jn.axis_value = dir # store direction, not raw value
			jn.device = jm.device
			return jn

	return null

func _apply_rebind(action_name: String, events: Array) -> void:
	# Remove this event from any other action to avoid conflicts (optional but nice).
	for other_action in InputMap.get_actions():
		if other_action == action_name:
			continue
		for ev in events:
			InputMap.action_erase_event(other_action, ev)

	# Clear current and apply new
	for ev_old in InputMap.action_get_events(action_name):
		InputMap.action_erase_event(action_name, ev_old)
	for ev in events:
		InputMap.action_add_event(action_name, ev)

	# End listening
	#var ended_action = _listening_action
	_is_listening = false
	_listening_action = ""
	_captured_from_button = null

	# Persist
	save_bindings()

	emit_signal("action_rebound", action_name, events)

# ---------- Persistence ----------

func save_bindings() -> void:
	var all := {}
	for action in InputMap.get_actions():
		var arr := []
		for ev in InputMap.action_get_events(action):
			arr.append(_event_to_dict(ev))
		all[action] = arr

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(all, "  "))
		file.close()

func load_bindings() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var text: String = file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return

	for action in parsed.keys():
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		# Clear current
		for ev_old in InputMap.action_get_events(action):
			InputMap.action_erase_event(action, ev_old)
		# Rebuild
		for evd in parsed[action]:
			var ev := _dict_to_event(evd)
			if ev:
				InputMap.action_add_event(action, ev)

# Convert supported events to a portable dict
func _event_to_dict(ev: InputEvent) -> Dictionary:
	if ev is InputEventKey:
		var k := ev as InputEventKey
		return {
			"type": "key",
			"physical": k.physical_keycode,
			"alt": k.alt_pressed,
			"shift": k.shift_pressed,
			"ctrl": k.ctrl_pressed,
			"meta": k.meta_pressed
		}
	if ev is InputEventMouseButton:
		var mb := ev as InputEventMouseButton
		return {
			"type": "mouse_button",
			"button": mb.button_index
		}
	if ev is InputEventJoypadButton:
		var jb := ev as InputEventJoypadButton
		return {
			"type": "joy_button",
			"button": jb.button_index,
			"device": jb.device
		}
	if ev is InputEventJoypadMotion:
		var jm := ev as InputEventJoypadMotion
		return {
			"type": "joy_axis",
			"axis": jm.axis,
			"dir": signf(jm.axis_value), # -1 or +1
			"device": jm.device
		}
	return {"type": "unknown"}

func _dict_to_event(d: Dictionary) -> InputEvent:
	match d.get("type", ""):
		"key":
			var k := InputEventKey.new()
			k.physical_keycode = int(d.get("physical", 0)) as Key
			k.alt_pressed = bool(d.get("alt", false))
			k.shift_pressed = bool(d.get("shift", false))
			k.ctrl_pressed = bool(d.get("ctrl", false))
			k.meta_pressed = bool(d.get("meta", false))
			return k
		"mouse_button":
			var mb := InputEventMouseButton.new()
			mb.button_index = int(d.get("button", 1)) as MouseButton
			return mb
		"joy_button":
			var jb := InputEventJoypadButton.new()
			jb.button_index = int(d.get("button", 0)) as JoyButton
			jb.device = int(d.get("device", 0))
			return jb
		"joy_axis":
			var jm := InputEventJoypadMotion.new()
			jm.axis = int(d.get("axis", 0)) as JoyAxis
			jm.axis_value = float(d.get("dir", 1.0)) # store sign to know direction
			jm.device = int(d.get("device", 0))
			return jm
		_:
			return null

# ---------- Utility for UI text ----------

func events_to_label(events: Array[InputEvent]) -> String:
	if events.is_empty():
		return "Unassigned"
	var ev := events[0]
	if ev is InputEventKey:
		var k := ev as InputEventKey
		# Show physical scancode name
		return OS.get_keycode_string(k.physical_keycode)
	if ev is InputEventMouseButton:
		return "Mouse %d" % (ev as InputEventMouseButton).button_index
	if ev is InputEventJoypadButton:
		return "Pad Btn %d" % (ev as InputEventJoypadButton).button_index
	if ev is InputEventJoypadMotion:
		var jm := ev as InputEventJoypadMotion
		return "Pad Axis %d %s" % [jm.axis, "+" if jm.axis_value > 0.0 else "-"]
	return "Unknown"

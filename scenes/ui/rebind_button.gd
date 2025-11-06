class_name RebindButton
extends Button

@export var action_name: String

var _listening := false

func _ready() -> void:
	text = _current_label()
	pressed.connect(_on_pressed)
	InputMgr.connect("listening_started", Callable(self, "_on_listening_started"))
	InputMgr.connect("listening_canceled", Callable(self, "_on_listening_canceled"))
	InputMgr.connect("action_rebound", Callable(self, "_on_action_rebound"))

func _on_pressed() -> void:
	if _listening:
		return
	InputMgr.start_listening_for(action_name, weakref(self))
	_listening = true
	text = "Press a key/button… (Esc=cancel, Del=clear)"

func _on_listening_started(a: String) -> void:
	if a == action_name:
		_listening = true
		text = "Press a key/button… (Esc=cancel, Del=clear)"

func _on_listening_canceled(a: String) -> void:
	if a == action_name:
		_listening = false
		text = _current_label()

func _on_action_rebound(a: String, _events: Array) -> void:
	if a == action_name:
		_listening = false
		text = _current_label()

func _current_label() -> String:
	var events := InputMap.action_get_events(action_name)
	return "%s: %s" % [action_name, InputMgr.events_to_label(events)]

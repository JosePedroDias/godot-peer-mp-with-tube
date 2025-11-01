class_name JoystickControl
extends Control

const threshold: float = 0.3

@onready var background: Control = $Background
@onready var knob: Control = $Knob

var is_pressed: bool = false
var center_position: Vector2
var max_distance: float = 50.0
var current_direction: Vector2 = Vector2.ZERO
var x_action: String = ""
var y_action: String = ""

#signal direction_changed(direction: Vector2)

func _ready() -> void:
	# Ensure proper mouse filtering for child nodes
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	knob.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Calculate center based on the control's size
	center_position = size / 2

	# Set background size and position
	background.size = Vector2(max_distance * 2, max_distance * 2)
	background.position = center_position - background.size / 2

	# Position knob at center initially
	knob.position = center_position - knob.size / 2

	#print("Joystick initialized - Size: ", size, " Center: ", center_position)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch_event = event as InputEventScreenTouch
		#print("Touch event: pressed=", touch_event.pressed, " pos=", touch_event.position)
		if touch_event.pressed: _start_drag(touch_event.position)
		else: _end_drag()
	elif event is InputEventScreenDrag and is_pressed:
		#print("Touch drag: pos=", event.position)
		_update_drag(event.position)
	elif event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			#print("Mouse button: pressed=", mouse_event.pressed, " pos=", mouse_event.position)
			if mouse_event.pressed: _start_drag(mouse_event.position)
			else: _end_drag()
	elif event is InputEventMouseMotion and is_pressed:
		#print("Mouse drag: pos=", event.position)
		_update_drag(event.position)

func _start_drag(pos: Vector2) -> void:
	is_pressed = true
	_update_drag(pos)

func _update_drag(pos: Vector2) -> void:
	var offset = pos - center_position
	var distance = offset.length()
	
	if distance > max_distance:
		offset = offset.normalized() * max_distance
	
	knob.position = center_position + offset - knob.size / 2
	
	current_direction = offset / max_distance
	_update_input_actions()
	#direction_changed.emit(current_direction)

func _end_drag() -> void:
	is_pressed = false
	knob.position = center_position - knob.size / 2
	current_direction = Vector2.ZERO
	_update_input_actions()
	#direction_changed.emit(current_direction)

func _update_input_actions() -> void:
	var new_x_action: String = ""
	var new_y_action: String = ""
	
	if   current_direction.y < -threshold: new_y_action = "up"
	elif current_direction.y >  threshold: new_y_action = "down"
	
	if   current_direction.x < -threshold: new_x_action = "left"
	elif current_direction.x >  threshold: new_x_action = "right"
	
	if new_x_action != x_action:
		if x_action: Input.action_release(x_action)
		if new_x_action: Input.action_press(new_x_action)
		
	if new_y_action != y_action:
		if y_action: Input.action_release(y_action)
		if new_y_action: Input.action_press(new_y_action)
	
	x_action = new_x_action
	y_action = new_y_action

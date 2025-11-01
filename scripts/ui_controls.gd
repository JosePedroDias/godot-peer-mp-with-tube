class_name UiControls
extends Control

@onready var joystick = $JoystickControl
@onready var le_btn: Button = $Le2Btn
@onready var ri_btn: Button = $Ri2Btn
@onready var fire_btn: Button = $FireBtn

func _ready() -> void:
	# Rotation buttons
	le_btn.button_down.connect(func(): Input.action_press("rotate_right"))
	le_btn.button_up.connect(  func(): Input.action_release("rotate_right"))

	ri_btn.button_down.connect(func(): Input.action_press("rotate_left"))
	ri_btn.button_up.connect(  func(): Input.action_release("rotate_left"))

	# Fire button
	fire_btn.button_down.connect(func(): Input.action_press("fire"))
	fire_btn.button_up.connect(  func(): Input.action_release("fire"))

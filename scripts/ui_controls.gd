class_name UiControls
extends Control

@onready var fw_btn: Button = $FwBtn
@onready var bw_btn: Button = $BwBtn

@onready var le_btn: Button = $LeBtn
@onready var ri_btn: Button = $RiBtn

@onready var le2_btn: Button = $Le2Btn
@onready var ri2_btn: Button = $Ri2Btn

@onready var fire_btn: Button = $FireBtn

func _ready() -> void:
	# Forward/Backward buttons
	fw_btn.button_down.connect(func():
		Input.action_press("up"))
	fw_btn.button_up.connect(func():
		Input.action_release("up"))

	bw_btn.button_down.connect(func():
		Input.action_press("down"))
	bw_btn.button_up.connect(func():
		Input.action_release("down"))

	# Left/Right movement buttons
	le_btn.button_down.connect(func():
		Input.action_press("left"))
	le_btn.button_up.connect(func():
		Input.action_release("left"))

	ri_btn.button_down.connect(func():
		Input.action_press("right"))
	ri_btn.button_up.connect(func():
		Input.action_release("right"))

	# Rotation buttons
	le2_btn.button_down.connect(func():
		Input.action_press("rotate_left"))
	le2_btn.button_up.connect(func():
		Input.action_release("rotate_left"))

	ri2_btn.button_down.connect(func():
		Input.action_press("rotate_right"))
	ri2_btn.button_up.connect(func():
		Input.action_release("rotate_right"))

	# Fire button
	fire_btn.button_down.connect(func():
		Input.action_press("fire"))
	fire_btn.button_up.connect(func():
		Input.action_release("fire"))

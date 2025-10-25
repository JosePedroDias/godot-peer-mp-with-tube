class_name Tank
extends StaticBody2D

@onready var body_spr: Sprite2D = $TBody
@onready var barrel_spr: Sprite2D = $TBody/TBarrel

var barrel_rot: float = 0

func _ready() -> void:
	#print("tank ready")
	pass

func set_theme(th: String):
	#print("set theme " + th)
	body_spr.texture = load("res://textures/tanks/" + th + "/bodyo.png")
	barrel_spr.texture = load("res://textures/tanks/" + th + "/b1o.png")

func rotate_barrel():
	pass

func move():
	pass

#func _physics_process(delta: float) -> void:
#	pass

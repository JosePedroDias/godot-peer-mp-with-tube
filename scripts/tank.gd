class_name Tank
extends StaticBody2D

@onready var body_spr: Sprite2D = $TBody
@onready var barrel_spr: Sprite2D = $TBody/TBarrel

var barrel_rot: float = 0
var peer_id: String = ""

func set_theme(th: String):
	body_spr.texture = load("res://textures/tanks/" + th + "/bodyo.png")
	barrel_spr.texture = load("res://textures/tanks/" + th + "/b1o.png")

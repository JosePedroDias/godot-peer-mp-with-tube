class_name Tank
extends CharacterBody2D

@onready var body_spr: Sprite2D = $TBody
@onready var barrel_spr: Sprite2D = $TBarrel

var barrel_rot: float = 0
var peer_id: String = ""

func set_theme(th: String) -> void:
	body_spr.texture = load("res://textures/tanks/" + th + "/bodyo.png")
	barrel_spr.texture = load("res://textures/tanks/" + th + "/b1o.png")

func rotate_tank(r: float) -> void:
	body_spr.rotation = r

func rotate_barrel(r: float) -> void:
	barrel_spr.rotation = r
	
func get_barrel_rotation() -> float:
	return barrel_spr.rotation

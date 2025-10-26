class_name Tank
extends CharacterBody2D

@onready var body_spr: Sprite2D = $TBody
@onready var barrel_spr: Sprite2D = $TBarrel
@onready var health_bar_rect: ColorRect = $HealthPnl/HealthBarRect

const MAX_HEALTH:float = 100
const MAX_HEALTH_PIXELS:float = 40
const NINETY_RAD: float = PI / 2

var peer_id: String = ""
var theme: String = ""
var energy: float = MAX_HEALTH

func _ready() -> void:
	if theme.length() > 0: _set_theme(theme)

func _set_theme(th: String) -> void:
	body_spr.texture = load("res://textures/tanks/" + th + "/bodyo.png")
	barrel_spr.texture = load("res://textures/tanks/" + th + "/b1o.png")

func move_forward(vel: float) -> void:
	var d_pos = Vector2.from_angle(body_spr.rotation + NINETY_RAD) * vel
	move_and_collide(d_pos)

func rotate_body(dr: float) -> void:
	body_spr.rotation += dr

func rotate_barrel(dr: float) -> void:
	barrel_spr.rotation += dr
	
func get_barrel_rotation() -> float:
	return barrel_spr.rotation

func remove_health(energy_to_remove: float) -> void:
	energy = max(0, energy - energy_to_remove)
	health_bar_rect.size.x = energy / MAX_HEALTH * MAX_HEALTH_PIXELS

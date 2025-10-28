class_name Tank
extends CharacterBody2D

@onready var body_spr: Sprite2D = $TBody
@onready var barrel_spr: Sprite2D = $TBarrel
@onready var health_bar_rect: ColorRect = $HealthPnl/HealthBarRect

const MAX_HEALTH:float = 100
const MAX_HEALTH_PIXELS:float = 40
const FW_SPEED: float = 130
const BW_SPEED: float = 80
const BODY_R_SPEED: float = 1.2
const BARREL_R_SPEED: float = 5
const TRACKS_MIN_DIST: float = 40.0
const NINETY_RAD: float = PI / 2
const THEMES: Array[String] = ["1blue", "2green", "3red", "4sand"]

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

func rotate_body(dr: float, vel: float = 1.0) -> float:
	var res = dr * vel
	body_spr.rotation += res
	return res

func rotate_barrel(dr: float) -> void:
	barrel_spr.rotation += dr

func get_body_rotation() -> float:
	return body_spr.rotation
	
func get_barrel_rotation() -> float:
	return barrel_spr.rotation

func remove_health(energy_to_remove: float) -> void:
	energy = max(0, energy - energy_to_remove)
	health_bar_rect.size.x = energy / MAX_HEALTH * MAX_HEALTH_PIXELS

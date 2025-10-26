class_name Tank
extends CharacterBody2D

@onready var body_spr: Sprite2D = $TBody
@onready var barrel_spr: Sprite2D = $TBarrel
@onready var health_bar_rect: ColorRect = $HealthPnl/HealthBarRect

const MAX_HEALTH:float = 100
const MAX_HEALTH_PIXELS:float = 40

var barrel_rot: float = 0
var peer_id: String = ""
var theme: String = ""

func _ready() -> void:
	if theme.length() > 0: _set_theme(theme)

func _set_theme(th: String) -> void:
	body_spr.texture = load("res://textures/tanks/" + th + "/bodyo.png")
	barrel_spr.texture = load("res://textures/tanks/" + th + "/b1o.png")

func rotate_tank(r: float) -> void:
	body_spr.rotation = r

func rotate_barrel(r: float) -> void:
	barrel_spr.rotation = r
	
func get_barrel_rotation() -> float:
	return barrel_spr.rotation

func set_health(h: float) -> void:
	health_bar_rect.size.x = h / MAX_HEALTH * MAX_HEALTH_PIXELS

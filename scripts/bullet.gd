extends Area2D
class_name Bullet

const LIFE: float = 3
const SPEED: float = 8

var owner_id: String
var time_left: float = LIFE
var speed: float = SPEED
var dir: Vector2

var _terrain: Terrain = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body is Tank:
		var tank = body as Tank
		if tank.peer_id != owner_id:
			print("Bullet from ", owner_id, " has hit tank ", tank.peer_id)
			time_left = 0
			if _terrain != null: 
				tank.remove_health(10)
				print("tank " + tank.peer_id + "'s energy: ", str(tank.energy))

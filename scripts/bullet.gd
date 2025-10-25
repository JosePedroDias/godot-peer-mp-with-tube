extends Area2D
class_name Bullet

var owner_id: String
var time_left: float
var dir: Vector2
var speed: float = 8.0
var terrain: Terrain

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body is Tank:
		var tank = body as Tank
		if tank.peer_id != owner_id:
			print("BOOM! Bullet from ", owner_id, " hit tank ", tank.peer_id)
			time_left = 0

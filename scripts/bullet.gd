extends Area2D
class_name Bullet

const LIFE: float = 3
const SPEED: float = 8

var owner_id: String
var time_left: float = LIFE
var dir: Vector2

var _terrain: Terrain = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body is Tank:
		var tank = body as Tank
		if tank.peer_id != owner_id:
			#print("Bullet from ", owner_id, " has hit tank ", tank.peer_id)
			time_left = 0
			if _terrain != null:
				tank.remove_health(10)
				_terrain._spawn_sys.spawn_explosion(position)
				queue_free()
				#print("tank " + tank.peer_id + "'s energy: ", str(tank.energy))
	elif body is StaticBody2D:
		# Hit a crate, tree, or other static obstacle
		#print("Bullet from ", owner_id, " has hit obstacle: ", body.name)
		time_left = 0
		if _terrain != null:
			_terrain._spawn_sys.spawn_explosion(position)
			queue_free()

func _to_string() -> String:
	return "owner: " + owner_id + ", dir: " + str(dir)

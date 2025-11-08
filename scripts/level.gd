class_name Level
extends Node

var _spawn_positions: Array[Vector2] = []

func _ready() -> void:
	for node in get_children():
		if node.get_class() == "Node2D":
			_spawn_positions.append(node.position)

func get_spawn_position() -> Vector2:
	if _spawn_positions.is_empty():
		push_error("Level: No spawn positions available, returning zero position")
		return Vector2.ZERO
	var index = randi() % _spawn_positions.size()
	return _spawn_positions[index]

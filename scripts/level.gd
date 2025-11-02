class_name Level
extends Node

var _spawn_positions: Array[Vector2] = []

func _ready() -> void:
	for node in get_children():
		if node.get_class() == "Node2D":
			_spawn_positions.append(node.position)

func get_spawn_position() -> Vector2:
	var index = randi() % _spawn_positions.size()
	return _spawn_positions[index]

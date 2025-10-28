class_name Smoke
extends Sprite2D

const MAX_TIME: float = 0.5

var time_left: float = MAX_TIME

func _process(delta: float) -> void:
	time_left -= delta
	scale = Vector2.ONE * (0.5 - time_left)
	modulate.a = time_left / MAX_TIME
	
	if not multiplayer.is_server(): return
	if time_left < 0: queue_free()

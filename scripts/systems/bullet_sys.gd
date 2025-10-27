class_name BulletSys
extends RefCounted

var _terrain: Terrain = null
var _bullets: Array[Bullet] = []

func _init(terr: Terrain) -> void:
	_terrain = terr
	
func add_bullet(bullet: Bullet) -> void:
	_bullets.append(bullet)

func process(delta: float) -> void:
	var bullets_to_remove = []
	
	for bu in _bullets:
		#if not is_instance_valid(bu):
		#	print("removing invalid instance of bullet!") # TODO is this necessary?
		#	bullets_to_remove.append(bu)
		#	continue

		bu.time_left -= delta
		var d_pos = bu.dir * Bullet.SPEED
		bu.position += d_pos

		if bu.time_left < 0:
			bullets_to_remove.append(bu)
			bu.queue_free()
	
	for bu in bullets_to_remove:
		_bullets.erase(bu)

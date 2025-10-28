class_name BulletSys
extends RefCounted

const DELTA_SMOKE: float = 0.05

var _terrain: Terrain = null
var _bullets: Array[Bullet] = []
var _last_smoke_t: float = DELTA_SMOKE

func _init(terr: Terrain) -> void:
	_terrain = terr
	
func add_bullet(bullet: Bullet) -> void:
	_bullets.append(bullet)

func process(delta: float) -> void:
	var bullets_to_remove = []
	
	var needs_smoke: bool = _last_smoke_t < 0
	_last_smoke_t -= delta
	
	for bu in _bullets:
		bu.time_left -= delta
		var d_pos = bu.dir * Bullet.SPEED
		bu.position += d_pos

		if bu.time_left < 0:
			bullets_to_remove.append(bu)
			bu.queue_free()
		elif needs_smoke:
			_terrain._spawn_sys.spawn_smoke(bu.position)
			
	if needs_smoke:
		_last_smoke_t = DELTA_SMOKE
	
	for bu in bullets_to_remove:
		_bullets.erase(bu)

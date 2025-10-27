class_name TankSys
extends RefCounted

const POSITIONS = [
	Vector2(100, 100),
	Vector2(200, 100),
	Vector2(100, 200),
	Vector2(200, 200)
]

var _terrain: Terrain = null
var _tanks_map: Dictionary[String, Tank]

func _init(terr: Terrain) -> void:
	_terrain = terr

func process(delta: float) -> void:
	for id in _tanks_map:
		var t: Tank = _tanks_map.get(id)
		if t == null: return
		if t.energy <= 0:
			_terrain._spawn_sys.despawn_tank(t.peer_id)
			return
		var pd: PeerData = _terrain.peer_data.get(id)
		if t != null and pd != null:
			var vel: float = pd.thrust * delta * Tank.SPEED
			if pd.body_drot != 0:
				t.rotate_body(pd.body_drot * delta * Tank.BODY_R_SPEED, vel)
			if pd.barrel_drot != 0:
				t.rotate_barrel(pd.barrel_drot * delta * Tank.BARREL_R_SPEED)
			if pd.thrust != 0:
				t.move_forward(vel)

func get_theme() -> String:
	return Tank.THEMES[ _tanks_map.size() % Tank.THEMES.size() ]

func get_spawn_position() -> Vector2:
	var index = _tanks_map.size() % POSITIONS.size()
	return POSITIONS[index]

func set_tank(id: String, tank: Tank) -> void:
	_tanks_map.set(id, tank)
	
func get_tank(id: String) -> Tank:
	return _tanks_map.get(id)

func has_tank(id: String) -> bool:
	return _tanks_map.has(id)

func erase_tank(id: String) -> void:
	_tanks_map.erase(id)

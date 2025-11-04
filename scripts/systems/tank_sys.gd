class_name TankSys
extends RefCounted

var _terrain: Terrain = null
var _tanks_map: Dictionary[String, Tank]

func _init(terr: Terrain) -> void:
	_terrain = terr

func process(delta: float) -> void:
	for id in _tanks_map:
		var t: Tank = _tanks_map.get(id)
		if t == null: return
		if t.energy <= 0:
			_terrain._spawn_sys.despawn_tank(t.peer_id, true)
			return
		var pd: PeerData = _terrain.peer_data.get(id)
		if t != null and pd != null:
			pd.bump()
			var vel: float = pd.thrust * delta * (Tank.FW_SPEED if pd.thrust > 0 else Tank.BW_SPEED)
			if pd.body_drot != 0:
				t.rotate_body(pd.body_drot * delta * Tank.BODY_R_SPEED, vel)
			if pd.barrel_drot != 0:
				t.rotate_barrel(pd.barrel_drot * delta * Tank.BARREL_R_SPEED)
			if pd.thrust != 0:
				t.move_forward(vel)
				var dist: float = pd.last_tracks_pos.distance_to(t.position)
				if dist > Tank.TRACKS_MIN_DIST:
					_terrain._spawn_sys.spawn_tracks(t.position, t.get_body_rotation())
					pd.last_tracks_pos = Vector2(t.position)

func get_theme() -> String:
	var themes = Tank.THEMES
	var index = randi() % themes.size()
	return themes[index]

func set_tank(id: String, tank: Tank) -> void:
	_tanks_map.set(id, tank)
	
func get_tank(id: String) -> Tank:
	return _tanks_map.get(id)

func has_tank(id: String) -> bool:
	return _tanks_map.has(id)

func erase_tank(id: String) -> void:
	_tanks_map.erase(id)

class_name SpawnSys
extends RefCounted

var _terrain: Terrain = null
var _tank_scene = load("res://scenes/tank.tscn")
var _bullet_scene = load("res://scenes/bullet.tscn")

func _init(terr: Terrain) -> void:
	_terrain = terr
	
func assign_spawner() -> void:
	_terrain.spawner.spawn_function = _custom_spawn_function
	
func spawn_tank(peer_id: String) -> void:
	if _terrain._tank_sys.has_tank(peer_id):
		print("Tank already exists for peer: ", peer_id)
		return

	var tank = _terrain.spawner.spawn({
		"type": "tank",
		"peer_id": peer_id,
		"theme": _terrain._tank_sys.get_theme(),
		"pos": _terrain._tank_sys.get_spawn_position()
	})
	if not tank: return
	_terrain._tank_sys.set_tank(peer_id, tank)
	
func despawn_tank(peer_id: String) -> void:
	var tank = _terrain._tank_sys.get_tank(peer_id)
	if not tank: return
	_terrain._tank_sys.erase_tank(peer_id)
	tank.queue_free()
	print("Despawned tank for peer: ", peer_id)

func spawn_bullet(id: String) -> void:
	var pd: PeerData = _terrain.peer_data.get(id)
	if pd == null: return
	var t: Tank = _terrain._tank_sys.get_tank(id)
	if t == null: return

	var b_rot = t.get_barrel_rotation() - PI / 2
	var p = Vector2(t.position)
	var b_dir = Vector2.from_angle(b_rot)
	p += b_dir * Bullet.SPEED * 3

	var bullet = _terrain.spawner.spawn({
		"type": "bullet",
		"owner_id": id,
		"pos": p,
		"dir": b_dir,
		"rotation": b_rot,
		"terrain": _terrain
	})
	if not bullet: return
	_terrain._bullet_sys.add_bullet(bullet)

func _custom_spawn_function(d: Variant) -> Node:
	if d is Dictionary:
		var data = d as Dictionary
		if data.has("type") and data["type"] == "tank":
			var tank = _tank_scene.instantiate()
			if data.has("peer_id"): tank.peer_id = data["peer_id"]
			if data.has("pos"):     tank.position = data["pos"]
			if data.has("theme"):   tank.theme = data["theme"]
			_terrain._tank_sys.set_tank(tank.peer_id, tank)
			return tank
		elif data.has("type") and data["type"] == "bullet":
			var bullet = _bullet_scene.instantiate()
			if data.has("owner_id"): bullet.owner_id = data["owner_id"]
			if data.has("pos"):      bullet.position = data["pos"]
			if data.has("dir"):      bullet.dir = data["dir"]
			if data.has("rotation"): bullet.rotation = data["rotation"]
			if data.has("terrain"):  bullet._terrain = data["terrain"]
			_terrain._bullet_sys.add_bullet(bullet)
			return bullet
	return null

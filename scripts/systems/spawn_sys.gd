class_name SpawnSys
extends RefCounted

const RESPAWN_AFTER_SECS: float = 3.0

var _terrain: Terrain = null
var _tank_scene = load("res://scenes/tank.tscn")
var _bullet_scene = load("res://scenes/bullet.tscn")
var _explosion_scene = load("res://scenes/explosion.tscn")
var _fire_scene = load("res://scenes/fire.tscn")
var _smoke_scene = load("res://scenes/smoke.tscn")
var _tracks_scene = load("res://scenes/tracks.tscn")

func _init(terr: Terrain) -> void:
	_terrain = terr
	
func assign_spawner() -> void:
	_terrain.spawner.spawn_function = _custom_spawn_function

func spawn_tank(peer_id: String) -> void:
	_terrain.spawner.spawn({
		"type": "tank",
		"peer_id": peer_id,
		"theme": _terrain._tank_sys.get_theme(),
		"position": _terrain._tank_sys.get_spawn_position()
	})
	
func spawn_explosion(pos: Vector2) -> void:
	_terrain.spawner.spawn({
		"type": "explosion",
		"position": Vector2(pos)
	})

func spawn_fire(pos: Vector2, rotation: float) -> void:
	_terrain.spawner.spawn({
		"type": "fire",
		"position": Vector2(pos),
		"rotation": rotation
	})

func spawn_smoke(pos: Vector2) -> void:
	_terrain.spawner.spawn({
		"type": "smoke",
		"position": Vector2(pos)
	})

func spawn_tracks(pos: Vector2, rotation: float) -> void:
	_terrain.spawner.spawn({
		"type": "tracks",
		"position": Vector2(pos),
		"rotation": rotation
	})
	
func despawn_tank(peer_id: String) -> void:
	var tank = _terrain._tank_sys.get_tank(peer_id)
	if not tank: return
	_terrain._tank_sys.erase_tank(peer_id)
	tank.queue_free()
	#print("Despawned tank for peer: ", peer_id)

	var respawn_timer = Timer.new()
	respawn_timer.wait_time = RESPAWN_AFTER_SECS
	respawn_timer.one_shot = true
	_terrain.add_child(respawn_timer)
	respawn_timer.timeout.connect(_on_respawn_timer_timeout.bind(peer_id, respawn_timer))
	respawn_timer.start()

func _on_respawn_timer_timeout(peer_id: String, timer: Timer) -> void:
	spawn_tank(peer_id)
	timer.queue_free()

func spawn_bullet(id: String) -> void:
	var pd: PeerData = _terrain.peer_data.get(id)
	if pd == null: return
	var t: Tank = _terrain._tank_sys.get_tank(id)
	if t == null: return

	var b_rot = t.get_barrel_rotation() - PI / 2
	var p = Vector2(t.position)
	var b_dir = Vector2.from_angle(b_rot)
	p += b_dir * Bullet.SPEED * 3

	_terrain.spawner.spawn({
		"type": "bullet",
		"owner_id": id,
		"position": p,
		"dir": b_dir,
		"rotation": b_rot,
		"terrain": _terrain
	})

func _custom_spawn_function(d: Variant) -> Node:
	if d is Dictionary and d.has("type"):
		var data = d as Dictionary
		if data["type"] == "tank":
			var tank: Tank = _tank_scene.instantiate()
			if data.has("peer_id"):  tank.peer_id  = data["peer_id"]
			if data.has("theme"):    tank.theme    = data["theme"]
			if data.has("position"): tank.position = data["position"]
			var rotation = randf() * 2.0 * PI
			tank.rotate_body(rotation)
			tank.rotate_barrel(rotation)
			_terrain._tank_sys.set_tank(tank.peer_id, tank)
			return tank
		elif data["type"] == "bullet":
			var bullet: Bullet = _bullet_scene.instantiate()
			if data.has("owner_id"): bullet.owner_id = data["owner_id"]
			if data.has("dir"):      bullet.dir      = data["dir"]
			if data.has("terrain"):  bullet._terrain = data["terrain"]
			if data.has("position"): bullet.position = data["position"]
			if data.has("rotation"): bullet.rotation = data["rotation"]
			_terrain._bullet_sys.add_bullet(bullet)
			_terrain._sfx_sys.play(SfxSys.Sfx.FIRE)
			return bullet
		elif data["type"] == "explosion":
			var expl = _explosion_scene.instantiate()
			if data.has("position"): expl.position = data["position"]
			_terrain._sfx_sys.play(SfxSys.Sfx.HIT)
			return expl
		elif data["type"] == "fire":
			var fire = _fire_scene.instantiate()
			if data.has("position"): fire.position = data["position"]
			if data.has("rotation"): fire.rotation = data["rotation"]
			return fire
		elif data["type"] == "smoke":
			var smoke = _smoke_scene.instantiate()
			if data.has("position"): smoke.position = data["position"]
			return smoke
		elif data["type"] == "tracks":
			var tracks = _tracks_scene.instantiate()
			if data.has("position"): tracks.position = data["position"]
			if data.has("rotation"): tracks.rotation = data["rotation"]
			call_deferred("_node_to_bottom", tracks)
			return tracks
	return null

func _node_to_bottom(nd: Node) -> void:
	var parent = nd.get_parent()
	if parent == null: return
	parent.move_child(nd, 0)

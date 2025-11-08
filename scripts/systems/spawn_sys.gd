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

# Respawn system
var _respawn_timer: Timer = null
var _peers_waiting_respawn: Array[Dictionary] = []

func _init(terr: Terrain) -> void:
	_terrain = terr

func _setup_respawn_timer() -> void:
	if _respawn_timer != null: return
	_respawn_timer = Timer.new()
	_respawn_timer.wait_time = 0.25  # Check every 250ms
	_respawn_timer.timeout.connect(_on_respawn_timer_timeout)
	_terrain.add_child(_respawn_timer)
	_respawn_timer.start()

func assign_spawner() -> void:
	_terrain.spawner.spawn_function = _custom_spawn_function
	_setup_respawn_timer()  # Set up timer when terrain is ready

func spawn_tank(peer_id: String) -> void:
	_terrain.spawner.spawn({
		"type": "tank",
		"peer_id": peer_id,
		"theme": _terrain._tank_sys.get_theme_for_peer(peer_id),
		#"position": Vector2(_terrain._level.get_spawn_position()),
		"position": Vector2(_terrain._tank_sys.get_safe_spawn_position()),
		"rotation": randf() * 2.0 * PI
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
	
func despawn_tank(peer_id: String, respawn: bool) -> void:
	var tank = _terrain._tank_sys.get_tank(peer_id)
	if not tank: return
	_terrain._tank_sys.erase_tank(peer_id)
	tank.queue_free()
	#print("Despawned tank for peer: ", peer_id)
	if not respawn: return

	var respawn_time = Time.get_unix_time_from_system() + RESPAWN_AFTER_SECS
	_peers_waiting_respawn.append({
		"peer_id": peer_id,
		"respawn_time": respawn_time
	})

func _on_respawn_timer_timeout() -> void:
	if _peers_waiting_respawn.is_empty(): return

	var current_time = Time.get_unix_time_from_system()
	var peers_to_respawn: Array[int] = []
	for i in range(_peers_waiting_respawn.size()):
		var respawn_data = _peers_waiting_respawn[i]
		if current_time >= respawn_data.respawn_time:
			spawn_tank(respawn_data.peer_id)
			peers_to_respawn.append(i)

	for i in range(peers_to_respawn.size() - 1, -1, -1):
		_peers_waiting_respawn.remove_at(peers_to_respawn[i])

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
			var rot: float = 0.0
			if data.has("rotation"): rot = data["rotation"]
			tank.rotate_body.call_deferred(rot)
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

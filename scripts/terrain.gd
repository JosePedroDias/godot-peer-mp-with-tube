class_name Terrain
extends Node2D

@onready var spawner: MultiplayerSpawner = $MultiplayerSpawner

var _themes = ["1blue", "2green", "3red", "4sand"]
var peer_data: Dictionary[String, PeerData]
var tanks_map: Dictionary[String, Tank]
var bullets: Array[Bullet] = []
var my_id: String
var _tank_scene = load("res://scenes/tank.tscn")
var _bullet_scene = load("res://scenes/bullet.tscn")

const TANK_SPEED: float = 80
const TANK_R_SPEED: float = 5
const BULLET_SPEED: float = 8
const BULLET_LIFE: float = 3

func _ready() -> void:
	spawner.spawn_function = _custom_spawn_function
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

func _input(ev: InputEvent) -> void:
	if my_id.length() == 0: return
	
	var pd: PeerData = peer_data.get(my_id)
	if pd == null: return
	
	var dx: float = pd.dx
	var dy: float = pd.dy
	
	if ev.is_action_pressed("up"): dy = -1
	elif ev.is_action_released("up"): dy = 0
	
	if ev.is_action_pressed("down"): dy = 1
	elif ev.is_action_released("down"): dy = 0
	
	if ev.is_action_pressed("left"): dx = -1
	elif ev.is_action_released("left"): dx = 0
	
	if ev.is_action_pressed("right"): dx = 1
	elif ev.is_action_released("right"): dx = 0
	
	if ev.is_action_pressed("rotate_left"): send_rot.rpc(-1)
	elif ev.is_action_released("rotate_left"): send_rot.rpc(0)
	
	if ev.is_action_pressed("rotate_right"): send_rot.rpc(1)
	elif ev.is_action_released("rotate_right"): send_rot.rpc(0)
		
	if ev.is_action_pressed("fire"): return send_fire.rpc()
	
	if pd.dx != dx or pd.dy != dy: send_move_dir.rpc(dx, dy)

@rpc("any_peer", "call_local", "reliable")
func send_move_dir(dx: float, dy: float):
	var id = str(multiplayer.get_remote_sender_id())
	var pd: PeerData = peer_data.get(id)
	if pd == null: return
	pd.dx = dx
	pd.dy = dy

@rpc("any_peer", "call_local", "reliable")
func send_rot(dr: float):
	var id = str(multiplayer.get_remote_sender_id())
	var pd: PeerData = peer_data.get(id)
	if pd == null: return
	pd.dr = dr

@rpc("any_peer", "call_local", "reliable")
func send_fire():
	if not multiplayer.is_server(): return

	var id = str(multiplayer.get_remote_sender_id())
	var pd: PeerData = peer_data.get(id)
	if pd == null: return
	var t: Tank = tanks_map.get(id)
	if t == null: return

	var b_rot = t.get_barrel_rotation() - PI / 2
	var p = Vector2(t.position)
	var b_dir = Vector2.from_angle(b_rot)
	p += b_dir * BULLET_SPEED * 3

	spawner.spawn({
		"type": "bullet",
		"owner_id": id,
		"pos": p,
		"dir": b_dir,
		"rotation": b_rot,
		"terrain": self
	})

func _physics_process(delta: float) -> void:
	if not multiplayer.is_server(): return

	var bullets_to_remove = []
	for bu in bullets:
		if not is_instance_valid(bu):
			bullets_to_remove.append(bu)
			continue

		bu.time_left -= delta
		var d_pos = bu.dir * BULLET_SPEED
		bu.position += d_pos

		if bu.time_left < 0:
			bullets_to_remove.append(bu)
			bu.queue_free()

	for bu in bullets_to_remove:
		bullets.erase(bu)
		
	for id in tanks_map:
		var t: Tank = tanks_map.get(id)
		if t == null: return
		var pd: PeerData = peer_data.get(id)
		if t != null and pd != null:
			var dx = pd.dx * delta * TANK_SPEED
			var dy = pd.dy * delta * TANK_SPEED
			var dr = pd.dr * delta * TANK_R_SPEED

			var motion = Vector2(dx, dy)
			if motion.length() > 0:
				var collision = t.move_and_collide(motion)
				if collision:
					print("Tank ", id, " collision detected")
			t.rotate_barrel(t.get_barrel_rotation() + dr)

func _on_peer_connected(id: int) -> void:
	print("Terrain: Peer connected: ", id)
	if multiplayer.is_server(): spawn_tank_for_peer(str(id))

func _on_peer_disconnected(id: int) -> void:
	print("Terrain: Peer disconnected: ", id)
	if multiplayer.is_server(): despawn_tank_for_peer(str(id))

func _custom_spawn_function(spawn_data: Variant) -> Node:
	if spawn_data is Dictionary:
		var data = spawn_data as Dictionary
		if data.has("type") and data["type"] == "tank":
			var tank = _tank_scene.instantiate()
			if data.has("peer_id"): tank.peer_id = data["peer_id"]
			if data.has("pos"):     tank.position = data["pos"]
			if data.has("theme"):   tank.theme = data["theme"]
			return tank
		elif data.has("type") and data["type"] == "bullet":
			var bullet = _bullet_scene.instantiate()
			if data.has("owner_id"): bullet.owner_id = data["owner_id"]
			if data.has("pos"):      bullet.position = data["pos"]
			if data.has("dir"):      bullet.dir = data["dir"]
			if data.has("rotation"): bullet.rotation = data["rotation"]
			if data.has("terrain"):  bullet.terrain = data["terrain"]
			bullet.time_left = BULLET_LIFE
			bullets.append(bullet)
			return bullet
	return null

func spawn_tank_for_peer(peer_id: String) -> void:
	if not multiplayer.is_server(): return

	if tanks_map.has(peer_id):
		print("Tank already exists for peer: ", peer_id)
		return

	var theme = _themes[ tanks_map.size() % _themes.size() ]
	var pos = get_spawn_position()

	var tank = spawner.spawn({
		"type": "tank",
		"peer_id": peer_id,
		"theme": theme,
		"pos": pos
	})
	if not tank: return
	tanks_map[peer_id] = tank

func despawn_tank_for_peer(peer_id: String) -> void:
	if not multiplayer.is_server(): return
	var tank = tanks_map.get(peer_id)
	if not tank: return
	tanks_map.erase(peer_id)
	tank.queue_free()
	print("Despawned tank for peer: ", peer_id)

func get_spawn_position() -> Vector2:
	var spawn_positions = [
		Vector2(100, 100),
		Vector2(200, 100),
		Vector2(100, 200),
		Vector2(200, 200)
	]
	var index = tanks_map.size() % spawn_positions.size()
	return spawn_positions[index]

func spawn_tank_for_server() -> void:
	if multiplayer.is_server() and my_id != "":
		spawn_tank_for_peer(my_id)

func apply_tank_damage(id: String, energy_to_remove: float) -> void:
	var pd: PeerData = peer_data.get(id)
	if pd == null: return
	pd.energy_left = max(0, pd.energy_left - energy_to_remove)
	print("tank " + id + "'s energy: ", pd.energy_left)
	var tank: Tank = tanks_map.get(id)
	if tank:
		tank.set_health(pd.energy_left)

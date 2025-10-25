class_name Terrain
extends Node2D

@onready var spawner: MultiplayerSpawner = $MultiplayerSpawner

var _colors = ["1blue", "2green", "3red", "4sand"]
var peer_data: Dictionary[String, PeerData]
var tanks_map: Dictionary[String, Tank]
var my_id: String
var _tank_scene = load("res://scenes/tank.tscn")

func _ready() -> void:
	spawner.spawn_function = _custom_spawn_function
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

func _input(ev: InputEvent) -> void:
	#if not ev.is_action_type() == InputEventAction: return
	
	if my_id == "": return
	var pd: PeerData = PeerData.new() #peer_data.get(my_id)
	if pd == null: return
	
	if ev.is_action_pressed("up"):
		pd.dy = -1
	elif ev.is_action_released("up"):
		pd.dy = 0
	elif ev.is_action_pressed("down"):
		pd.dy = 1
	elif ev.is_action_released("down"):
		pd.dy = 0
	elif ev.is_action_pressed("left"):
		pd.dx = -1
	elif ev.is_action_released("left"):
		pd.dx = 0
	elif ev.is_action_pressed("right"):
		pd.dx = 1
	elif ev.is_action_released("right"):
		pd.dx = 0
	elif ev.is_action_pressed("fire"):
		#print("FIRE!") # TODO
		return
	else:
		return
	#print(pd)
	send_inputs.rpc(pd.dx, pd.dy)

@rpc("any_peer", "call_local", "reliable")
func send_inputs(dx: float, dy: float):
	var id = str(multiplayer.get_remote_sender_id())
	var pd: PeerData = peer_data.get(id)
	if pd == null: return
	pd.dx = dx
	pd.dy = dy

func _physics_process(delta: float) -> void:
	if not multiplayer.is_server(): return

	for id in tanks_map:
		var t: Tank = tanks_map.get(id)
		if t == null:
			print("early abort from process")
			return
		var pd: PeerData = peer_data.get(id)
		if t != null and pd != null:
			var dx = pd.dx * delta * 50
			var dy = pd.dy * delta * 50
			t.position.x += dx
			t.position.y += dy

func _on_peer_connected(id: int) -> void:
	print("Terrain: Peer connected: ", id)
	if multiplayer.is_server():
		spawn_tank_for_peer(str(id))

func _on_peer_disconnected(id: int) -> void:
	print("Terrain: Peer disconnected: ", id)
	if multiplayer.is_server():
		despawn_tank_for_peer(str(id))

# Custom spawn function called by MultiplayerSpawner
func _custom_spawn_function(spawn_data: Variant) -> Node:
	var tank = _tank_scene.instantiate()

	if spawn_data is Dictionary:
		var data = spawn_data as Dictionary
		if data.has("peer_id"):
			tank.peer_id = data["peer_id"]
			tank.name = "Tank_" + data["peer_id"]
		if data.has("position"):
			tank.position = data["position"]
		if data.has("color"):
			tank.set_theme(data["color"])

	return tank

func spawn_tank_for_peer(peer_id: String) -> void:
	if not multiplayer.is_server():
		return

	if tanks_map.has(peer_id):
		print("Tank already exists for peer: ", peer_id)
		return

	var color_index = tanks_map.size() % _colors.size()
	var tank_color = _colors[color_index]
	var spawn_pos = get_spawn_position()

	var spawn_data = {
		"peer_id": peer_id,
		"color": tank_color,
		"position": spawn_pos
	}

	var tank = spawner.spawn(spawn_data)

	if tank:
		tanks_map[peer_id] = tank
		print("Spawned tank for peer ", peer_id, " with color ", tank_color, " at ", spawn_pos)

func despawn_tank_for_peer(peer_id: String) -> void:
	if not multiplayer.is_server():
		return

	var tank = tanks_map.get(peer_id)
	if tank:
		tanks_map.erase(peer_id)
		# Remove the tank from the scene
		tank.queue_free()
		print("Despawned tank for peer: ", peer_id)

func get_spawn_position() -> Vector2:
	# Simple spawn positioning - you can make this more sophisticated
	var spawn_positions = [
		Vector2(100, 100),
		Vector2(200, 100),
		Vector2(100, 200),
		Vector2(200, 200)
	]
	var index = tanks_map.size() % spawn_positions.size()
	return spawn_positions[index]

# Function to spawn tank for server/host player
func spawn_tank_for_server() -> void:
	if multiplayer.is_server() and my_id != "":
		spawn_tank_for_peer(my_id)

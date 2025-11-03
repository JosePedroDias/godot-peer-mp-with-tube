class_name Terrain
extends Node2D

@onready var spawner: MultiplayerSpawner = $MultiplayerSpawner
var peer_data: Dictionary[String, PeerData]
var my_id: String
var is_connected_to_server: bool = false

var _bullet_sys: BulletSys
var _spawn_sys: SpawnSys
var _tank_sys: TankSys
var _sfx_sys: SfxSys
var _level: Level

var _previous_action_states: Dictionary = {
	"up": false,
	"down": false,
	"left": false,
	"right": false,
	"rotate_left": false,
	"rotate_right": false,
	"fire": false
}

func _init() -> void:
	_bullet_sys = BulletSys.new(self)
	_tank_sys = TankSys.new(self)
	_spawn_sys = SpawnSys.new(self)
	
	var sfx_scene = load("res://scenes/sfx_sys.tscn")
	_sfx_sys = sfx_scene.instantiate()
	
	var level_scene = load("res://scenes/maps/level_01.tscn")
	_level = level_scene.instantiate()

func _ready() -> void:
	add_child(_sfx_sys)
	add_child(_level)
	_spawn_sys.assign_spawner()
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

func _process(_delta: float) -> void:
	if my_id.length() == 0: return

	var pd: PeerData = peer_data.get(my_id)
	if pd == null: return

	# Check for action state changes (handles both keyboard and UI button input)
	_check_action_state_change("up",           1, 0, send_thrust)
	_check_action_state_change("down",        -1, 0, send_thrust)
	_check_action_state_change("left",        -1, 0, send_body_drot)
	_check_action_state_change("right",        1, 0, send_body_drot)
	_check_action_state_change("rotate_left", -1, 0, send_barrel_rot)
	_check_action_state_change("rotate_right", 1, 0, send_barrel_rot)

	# Fire is special - it's a single action, not continuous
	if Input.is_action_just_pressed("fire"):
		send_fire.rpc()

func _check_action_state_change(action: String, press_value: float, release_value: float, rpc_method: Callable) -> void:
	var current_state = Input.is_action_pressed(action)
	var previous_state = _previous_action_states.get(action, false)
	if current_state != previous_state:
		if current_state: rpc_method.rpc(press_value)
		else: rpc_method.rpc(release_value)
		_previous_action_states[action] = current_state

@rpc("any_peer", "call_local", "reliable")
func send_thrust(thrust: float) -> void:
	var id = str(multiplayer.get_remote_sender_id())
	var pd: PeerData = peer_data.get(id)
	if pd == null: return
	pd.thrust = thrust
	
@rpc("any_peer", "call_local", "reliable")
func send_body_drot(body_drot: float) -> void:
	var id = str(multiplayer.get_remote_sender_id())
	var pd: PeerData = peer_data.get(id)
	if pd == null: return
	pd.body_drot = body_drot

@rpc("any_peer", "call_local", "reliable")
func send_barrel_rot(barrel_drot: float) -> void:
	var id = str(multiplayer.get_remote_sender_id())
	var pd: PeerData = peer_data.get(id)
	if pd == null: return
	pd.barrel_drot = barrel_drot

@rpc("any_peer", "call_local", "reliable")
func send_fire() -> void:
	var id = str(multiplayer.get_remote_sender_id())

	if multiplayer.is_server():
		_spawn_sys.spawn_bullet(id)
		var tank = _tank_sys.get_tank(id)
		if tank == null: return
		_spawn_sys.spawn_fire(tank.position, tank.get_barrel_rotation())

@rpc("any_peer", "call_local", "reliable")
func set_players(s: String) -> void:
	DisplayServer.window_set_title("players: " + s)

func _physics_process(delta: float) -> void:
	if not multiplayer.is_server(): return
	_bullet_sys.process(delta)
	_tank_sys.process(delta)

func _update_players() -> void:
	var players = ""
	for id_ in peer_data.keys():
		players += "," + id_
	set_players.rpc(players.substr(1))
	

func _on_peer_connected(id: int) -> void:
	#print("Terrain: Peer connected: ", id)
	if multiplayer.is_server():
		_spawn_sys.spawn_tank(str(id))
		_update_players()

func _on_peer_disconnected(id: int) -> void:
	#print("Terrain: Peer disconnected: ", id)
	if multiplayer.is_server():
		_spawn_sys.despawn_tank(str(id), false)
		_update_players()

func spawn_tank_for_server() -> void:
	if multiplayer.is_server() and my_id != "":
		_spawn_sys.spawn_tank(my_id)
		is_connected_to_server = true  # Server is always "connected" to itself

func get_spawned_instances() -> int:
	return spawner.get_child_count()
	
func get_max_spawned_instances() -> int:
	return spawner.spawn_limit

class_name Terrain
extends Node2D

@onready var spawner: MultiplayerSpawner = $MultiplayerSpawner
var peer_data: Dictionary[String, PeerData]
var my_id: String

var _bullet_sys: BulletSys
var _spawn_sys: SpawnSys
var _tank_sys: TankSys

func _init() -> void:
	_bullet_sys = BulletSys.new(self)
	_tank_sys = TankSys.new(self)
	_spawn_sys = SpawnSys.new(self)

func _ready() -> void:
	_spawn_sys.assign_spawner()
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

func _input(ev: InputEvent) -> void:
	if my_id.length() == 0: return
	
	var pd: PeerData = peer_data.get(my_id)
	if pd == null: return
	
	if ev.is_action_pressed("up"): send_thrust.rpc(1)
	elif ev.is_action_released("up"): send_thrust.rpc(0)
	
	if ev.is_action_pressed("down"): send_thrust.rpc(-1)
	elif ev.is_action_released("down"): send_thrust.rpc(0)
	
	if ev.is_action_pressed("left"): send_body_drot.rpc(-1)
	elif ev.is_action_released("left"): send_body_drot.rpc(0)
	
	if ev.is_action_pressed("right"): send_body_drot.rpc(1)
	elif ev.is_action_released("right"): send_body_drot.rpc(0)
	
	if ev.is_action_pressed("rotate_left"): send_barrel_rot.rpc(-1)
	elif ev.is_action_released("rotate_left"): send_barrel_rot.rpc(0)
	
	if ev.is_action_pressed("rotate_right"): send_barrel_rot.rpc(1)
	elif ev.is_action_released("rotate_right"): send_barrel_rot.rpc(0)
		
	if ev.is_action_pressed("fire"): return send_fire.rpc()

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

func _physics_process(delta: float) -> void:
	if not multiplayer.is_server(): return
	_bullet_sys.process(delta)
	_tank_sys.process(delta)

func _on_peer_connected(id: int) -> void:
	print("Terrain: Peer connected: ", id)
	if multiplayer.is_server(): _spawn_sys.spawn_tank(str(id))

func _on_peer_disconnected(id: int) -> void:
	print("Terrain: Peer disconnected: ", id)
	if multiplayer.is_server(): _spawn_sys.despawn_tank(str(id))

func spawn_tank_for_server() -> void:
	if multiplayer.is_server() and my_id != "": _spawn_sys.spawn_tank(my_id)

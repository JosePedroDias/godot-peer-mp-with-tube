class_name Main
extends Node2D

@onready var tube_client: TubeClient = $TubeClient
@onready var form: P2pform = $P2Pform
@onready var terrain: Terrain = $Terrain

var peer_data: Dictionary[String, PeerData] = {}

func _ready() -> void:
	form.peer_data = peer_data
	form.set_tube_client(tube_client)	
	tube_client.session_created.connect(_on_session_created)
	tube_client.session_joined.connect(_on_session_joined)
	tube_client.peer_connected.connect(_on_peer_connected)
	terrain.peer_data = peer_data

func _on_session_created():
	var id = str(tube_client.peer_id)
	print("_on_session_created: ", id)
	terrain.my_id = id
	peer_data.set(id, PeerData.new())
	print("assigning myid: ", id)
	print("peer_data: ", str(peer_data))
	terrain.add_tank(id)

func _on_session_joined():
	var id = str(tube_client.peer_id)
	print("_on_session_joined: ", id)
	if terrain.my_id.length() > 0: return
	terrain.my_id = id
	peer_data.set(id, PeerData.new())
	print("assigning myid: ", id)
	print("peer_data: ", str(peer_data))
	terrain.add_tank(id) # TODO TEMP

func _on_peer_connected(_id):
	var id = str(_id)
	print("_on_peer_connected: ", id)
	peer_data.set(id, PeerData.new())
	terrain.add_tank(id) # TODO TEMP

func _on_peer_disconnected(id):
	terrain.remove_tank(str(id))

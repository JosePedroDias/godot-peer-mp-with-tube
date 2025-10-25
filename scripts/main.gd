class_name Main
extends Node2D

@onready var serve_btn: Button = $ServeButton
@onready var join_btn: Button = $JoinButton
@onready var send_btn: Button = $SendButton

@onready var serve_lbl: Label = $ServeLabel
@onready var log_lbl: Label = $LogLabel

@onready var send_ed: LineEdit = $SendLineEdit
@onready var client_ed: LineEdit = $ClientLineEdit

@onready var tube_client: TubeClient = $TubeClient

var peers: Array = []
var peer_names: Dictionary = {}
	
func _ready() -> void:
	serve_btn.pressed.connect(_on_serve_btn_pressed)
	join_btn.pressed.connect(_on_join_btn_pressed)
	send_btn.pressed.connect(_on_send_btn_pressed)
	send_ed.text_submitted.connect(_on_send_ed_text_submitted)
	
	tube_client.session_created.connect(_on_session_created)
	tube_client.session_joined.connect(_on_session_joined)
	tube_client.session_left.connect(_on_session_left)
	tube_client.peer_connected.connect(_on_peer_connected)
	tube_client.peer_disconnected.connect(_on_peer_disconnected)

func _on_serve_btn_pressed():
	"""player decided to host. will set a session for others to join to"""
	tube_client.create_session()
	serve_lbl.text = tube_client.session_id
	DisplayServer.clipboard_set(tube_client.session_id)
	DisplayServer.window_set_title("hosting session: " + tube_client.session_id)

func _on_join_btn_pressed():
	"""player decided to be a client and join a session from elsewhere"""
	var session_id: String = client_ed.text
	if session_id.length() > 0:
		tube_client.join_session(session_id)
	else:
		OS.alert("fill the session id first!")

func _on_peer_connected(id):
	"""fired on all players"""
	peers.append(id)
	peer_names[id] = str(id)
	print("peer connected: ", str(id), ", connected now to ", str(peers.size()), " peers")

func _on_peer_disconnected(id):
	"""fired on all players"""
	var their_name = peer_names[id] if peer_names[id] else str(id)
	peers.remove_at( peers.find(id) )
	peer_names.erase(id)
	print("peer disconnected: ", their_name, " (", str(id), "), connected now to ", str(peers.size()), " peers")

func _on_send_btn_pressed():
	"""let's send a message (to everyone)"""
	var msg: String = send_ed.text
	transfer_some_input.rpc(msg)
	send_ed.text = ""

func _on_send_ed_text_submitted(msg: String):
	"""let's send a message (to everyone)"""
	transfer_some_input.rpc(msg)
	send_ed.text = ""

func _on_session_created():
	"""show be triggered on the host once session was obtained"""
	_log("(host) session created")
	_hide_forms()
	
func _on_session_joined():
	"""triggered on a client once they connect to the game"""
	_log("(client) session joined")
	DisplayServer.window_set_title("joined session: " + tube_client.session_id)
	_hide_forms()
	
func _on_session_left():
	"""never saw this happening?"""
	_log("session left")
	
func _log(msg: String):
	print(msg)
	log_lbl.text += "\n" + msg

func _hide_forms():
	serve_btn.visible = false
	join_btn.visible = false
	serve_lbl.visible = false # optional
	client_ed.visible = false

####

# call local is required if the server is also a player.
@rpc("any_peer", "call_local", "reliable")
func transfer_some_input(txt: String):
	"""everyone sends to everyone"""
	if txt.length() == 0: return
	var sender_id = multiplayer.get_remote_sender_id()
	if txt.begins_with("myname "):
		var myname = txt.substr(7)
		peer_names[sender_id] = myname
		print(str(sender_id), " renamed to '", myname, "'")
	
	var sender_name = peer_names[sender_id] if peer_names[sender_id] else "ME"
	_log(sender_name + ": " + txt)

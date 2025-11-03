class_name P2pform
extends PanelContainer

@onready var serve_btn: Button = $MarginContainer/GridContainer/ServeButton
@onready var join_btn: Button = $MarginContainer/GridContainer/JoinButton
@onready var send_btn: Button = $MarginContainer/GridContainer/SendButton
@onready var dismiss_btn: CheckButton = $MarginContainer/GridContainer/DismissButton

@onready var serve_lbl: Label = $MarginContainer/GridContainer/ServeLabel
@onready var scroll_ctn: ScrollContainer = $MarginContainer/GridContainer/ScrollContainer
@onready var log_lbl: Label = $MarginContainer/GridContainer/ScrollContainer/LogLabel

@onready var send_ed: LineEdit = $MarginContainer/GridContainer/SendLineEdit
@onready var client_ed: LineEdit = $MarginContainer/GridContainer/ClientLineEdit

var tube_client: TubeClient
var peer_data: Dictionary
var _skip_set_cb: bool = false
	
func _ready() -> void:
	serve_btn.pressed.connect(_on_serve_btn_pressed)
	join_btn.pressed.connect(_on_join_btn_pressed)
	send_btn.pressed.connect(_on_send_btn_pressed)
	send_ed.text_submitted.connect(_on_send_ed_text_submitted)
	dismiss_btn.toggled.connect(_on_dismiss_btn_toggled)

	# Initialize scroll container based on initial toggle state
	_on_dismiss_btn_toggled(dismiss_btn.button_pressed)
	
	if OS.get_name() == "Web":
		var join = JavaScriptBridge.eval("new URLSearchParams(location.search).get('join')", true)
		if join:
			client_ed.text = join
			#_on_join_btn_pressed.call_deferred()
			return
		var serve = JavaScriptBridge.eval("new URLSearchParams(location.search).get('serve')", true)
		if serve:
			_skip_set_cb = true
			tube_client.session_id = serve
			_on_serve_btn_pressed.call_deferred()

func set_tube_client(tc: TubeClient) -> void:
	tube_client = tc
	
	tube_client.session_created.connect(_on_session_created)
	tube_client.session_joined.connect(_on_session_joined)
	tube_client.session_left.connect(_on_session_left)
	tube_client.peer_connected.connect(_on_peer_connected)
	tube_client.peer_disconnected.connect(_on_peer_disconnected)

func _on_serve_btn_pressed() -> void:
	"""player decided to host. will set a session for others to join to"""
	serve_btn.release_focus()  # Remove focus to prevent space key from toggling button
	tube_client.create_session()
	serve_lbl.text = tube_client.session_id
	DisplayServer.window_set_title("hosting session: " + tube_client.session_id)
	if not _skip_set_cb:
		DisplayServer.clipboard_set(tube_client.session_id)
	

func _on_join_btn_pressed() -> void:
	"""player decided to be a client and join a session from elsewhere"""
	join_btn.release_focus()  # Remove focus to prevent space key from toggling button
	var session_id: String = client_ed.text
	if session_id.length() > 0:
		tube_client.join_session(session_id)
	else:
		OS.alert("fill the session id first!")

func _on_peer_connected(id: int) -> void:
	"""fired on all players"""
	peer_data.set(str(id), PeerData.new())
	#print("peer connected: ", str(id), ", connected now to ", str(peer_data.size()), " peers")

func _on_peer_disconnected(id: int) -> void:
	"""fired on all players"""
	peer_data.erase(str(id))
	#print("peer disconnected: ", str(id), " , connected now to ", str(peer_data.size()), " peers")

func _on_send_btn_pressed() -> void:
	"""let's send a message (to everyone)"""
	var msg: String = send_ed.text
	transfer_some_input.rpc(msg)
	send_ed.text = ""
	send_ed.grab_focus()  # Keep focus in the text field

func _on_send_ed_text_submitted(msg: String) -> void:
	"""let's send a message (to everyone)"""
	transfer_some_input.rpc(msg)
	send_ed.text = ""
	send_ed.grab_focus()  # Keep focus in the text field
	
func _on_dismiss_btn_toggled(mode: bool) -> void:
	dismiss_btn.release_focus()  # Remove focus to prevent space key from toggling button
	send_btn.visible = mode
	send_ed.visible = mode
	scroll_ctn.visible = mode

	# Adjust scroll container size flags based on toggle state
	if mode:
		scroll_ctn.size_flags_vertical = Control.SIZE_EXPAND_FILL  # Expand when visible
		scroll_ctn.custom_minimum_size = Vector2(0, 100)  # Set minimum height when expanded
	else:
		scroll_ctn.size_flags_vertical = Control.SIZE_SHRINK_CENTER  # Shrink when hidden
		scroll_ctn.custom_minimum_size = Vector2(0, 0)  # No minimum size when hidden

func _on_session_created() -> void:
	"""show be triggered on the host once session was obtained"""
	_log("(host) session created")
	_hide_forms()
	
func _on_session_joined() -> void:
	"""triggered on a client once they connect to the game"""
	_log("(client) session joined")
	DisplayServer.window_set_title("joined session: " + tube_client.session_id)
	_hide_forms()
	
func _on_session_left() -> void:
	"""never saw this happening?"""
	_log("session left")
	
func _log(msg: String) -> void:
	print(msg)
	log_lbl.text += "\n" + msg
	# Auto-scroll to bottom when new messages are added
	_page_down.call_deferred()

func _page_down() -> void:
	# Ensure scroll container scrolls to the bottom
	await get_tree().process_frame  # Wait for layout update
	if scroll_ctn.visible:
		var v_scroll = scroll_ctn.get_v_scroll_bar()
		if v_scroll:
			scroll_ctn.scroll_vertical = int(v_scroll.max_value)

func _hide_forms() -> void:
	serve_btn.visible = false
	join_btn.visible = false
	serve_lbl.visible = false # optional
	client_ed.visible = false

####

# call local is required if the server is also a player.
@rpc("any_peer", "call_local", "reliable")
func transfer_some_input(txt: String) -> void:
	"""everyone sends to everyone"""
	if txt.length() == 0: return
	var sender_id = str(multiplayer.get_remote_sender_id())
	_log(sender_id + ": " + txt)

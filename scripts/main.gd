class_name Main
extends Node2D

@onready var tube_client: TubeClient = $TubeClient
@onready var form: P2pform = $CanvasLayer/P2Pform
@onready var net_overlay: NetOverlay = $CanvasLayer/NetOverlay
@onready var terrain: Terrain = $Terrain
@onready var canvas_layer: CanvasLayer = $CanvasLayer
@onready var camera: Camera2D = $Camera2D

var peer_data: Dictionary[String, PeerData] = {}

func _ready() -> void:
	form.peer_data = peer_data
	form.set_tube_client(tube_client)
	net_overlay.set_terrain(terrain)
	tube_client.session_created.connect(_on_session_created)
	tube_client.session_joined.connect(_on_session_joined)
	tube_client.peer_connected.connect(_on_peer_connected)
	terrain.peer_data = peer_data

	# Add UI controls only on mobile devices (mobile OS or portrait orientation)
	if _is_mobile_device(): _add_ui_controls()

func _process(_delta: float) -> void:
	# Update camera to follow player's tank
	if terrain.my_id.length() > 0:
		var my_tank = terrain._tank_sys.get_tank(terrain.my_id)
		if my_tank != null:
			camera.position = my_tank.position

func _is_mobile_device() -> bool:
	var os_name = OS.get_name()
	if os_name == "Android" or os_name == "iOS": return true
	var viewport_size = get_viewport().get_visible_rect().size
	return viewport_size.y > viewport_size.x

func _add_ui_controls() -> void:
	var ui_controls_scene = preload("res://scenes/ui_controls.tscn")
	var ui_controls = ui_controls_scene.instantiate()
	ui_controls.anchors_preset = Control.PRESET_CENTER_BOTTOM
	ui_controls.anchor_right = 0.5
	ui_controls.offset_left = 0.0
	ui_controls.offset_top = 0.0
	ui_controls.offset_right = 0.0
	ui_controls.offset_bottom = 0.0
	ui_controls.grow_vertical = Control.GROW_DIRECTION_BEGIN
	ui_controls.scale = Vector2(2.5, 2.5)
	ui_controls.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ui_controls.size_flags_vertical = Control.SIZE_SHRINK_END
	canvas_layer.add_child(ui_controls)

func _on_session_created():
	var id = str(tube_client.peer_id)
	terrain.my_id = id
	peer_data.set(id, PeerData.new())
	terrain.spawn_tank_for_server()

func _on_session_joined():
	var id = str(tube_client.peer_id)
	if terrain.my_id.length() > 0: return
	terrain.my_id = id
	peer_data.set(id, PeerData.new())

func _on_peer_connected(_id):
	var id = str(_id)
	peer_data.set(id, PeerData.new())

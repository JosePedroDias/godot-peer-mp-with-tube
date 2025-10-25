class_name Terrain
extends Node2D

var _colors = ["1blue", "2green", "3red", "4sand"]
var _tank_scene = load("res://scenes/tank.tscn")
var peer_data: Dictionary[String, PeerData]
var tanks_map: Dictionary[String, Tank]
var my_id: String

func _ready() -> void:
	pass

func add_tank(id: String):
	var t: Tank = _tank_scene.instantiate()
	t.position.x = randf() * 300
	t.position.y = randf() * 300
	add_child(t)
	var nth = peer_data.size()
	t.set_theme(_colors[nth - 1])
	tanks_map.set(id, t)

func remove_tank(id: String):
	var t = tanks_map.get(id)
	remove_child(t)
	tanks_map.erase(id)

func _input(ev: InputEvent) -> void:
	#if not ev.is_action_type() == InputEventAction: return
	
	if my_id == "": return
	var pd: PeerData = peer_data.get(my_id)
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

@rpc("any_peer", "call_local", "reliable")
func send_inputs(_id, dx: float, dy: float):
	var id = str(_id)
	var pd: PeerData = peer_data.get(id)
	if pd == null: return
	pd.dx = dx
	pd.dy = dy

func _physics_process(delta: float) -> void:
	if my_id != "1": return
	#if TubeClient
	for id in tanks_map:
		var t: Tank = tanks_map.get(id)
		var pd: PeerData = peer_data.get(id)
		var dx = pd.dx * delta * 50
		var dy = pd.dy * delta * 50
		t.position.x += dx
		t.position.y += dy
		#print(str(t.position))

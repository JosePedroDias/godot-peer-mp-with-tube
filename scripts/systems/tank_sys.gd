class_name TankSys
extends RefCounted

# Constants for spawn collision detection
const TANK_COLLISION_RADIUS: float = 30.0  # Slightly larger than tank's 40x40 collision box
const MAX_SPAWN_ATTEMPTS: int = 10  # Maximum attempts before falling back to any position

var _terrain: Terrain = null
var _tanks_map: Dictionary[String, Tank]

func _init(terr: Terrain) -> void:
	_terrain = terr

func process(delta: float) -> void:
	var to_despawn: Array[String] = []
	for id in _tanks_map:
		var t: Tank = _tanks_map.get(id)
		if t == null: continue
		if t.energy <= 0:
			to_despawn.push_back(t.peer_id)
			continue
		var pd: PeerData = _terrain.peer_data.get(id)
		if t != null and pd != null:
			pd.bump()
			var vel: float = pd.thrust * delta * (Tank.FW_SPEED if pd.thrust > 0 else Tank.BW_SPEED)
			if pd.body_drot != 0:
				t.rotate_body(pd.body_drot * delta * Tank.BODY_R_SPEED, vel)
			if pd.barrel_drot != 0:
				t.rotate_barrel(pd.barrel_drot * delta * Tank.BARREL_R_SPEED)
			if pd.thrust != 0:
				t.move_forward(vel)
				var dist: float = pd.last_tracks_pos.distance_to(t.position)
				if dist > Tank.TRACKS_MIN_DIST:
					_terrain._spawn_sys.spawn_tracks(t.position, t.get_body_rotation())
					pd.last_tracks_pos = Vector2(t.position)
	for peer_id in to_despawn:
		_terrain._spawn_sys.despawn_tank(peer_id, true)

func get_theme() -> String:
	var themes = Tank.THEMES
	var index = randi() % themes.size()
	return themes[index]

func set_tank(id: String, tank: Tank) -> void:
	_tanks_map.set(id, tank)
	
func get_tank(id: String) -> Tank:
	return _tanks_map.get(id)

func has_tank(id: String) -> bool:
	return _tanks_map.has(id)

func erase_tank(id: String) -> void:
	_tanks_map.erase(id)

func get_safe_spawn_position() -> Vector2:
	if _terrain == null or _terrain._level == null:
		push_error("TankSys: Terrain or level is null when trying to get spawn position")
		return Vector2.ZERO

	for attempt in range(MAX_SPAWN_ATTEMPTS):
		var candidate_position = _terrain._level.get_spawn_position()
		if _is_position_clear_geo(candidate_position):
		#if _is_position_clear_physics(candidate_position):
			return candidate_position
	return _terrain._level.get_spawn_position()

func _is_position_clear_geo(position: Vector2) -> bool:
	"""using just geometry and _tanks_map structire"""
	for tank_id in _tanks_map:
		var tank: Tank = _tanks_map.get(tank_id)
		if tank != null:
			var distance = position.distance_to(tank.position)
			if distance < TANK_COLLISION_RADIUS: return false
	return true

func _is_position_clear_physics(position: Vector2) -> bool:
	"""using physics"""
	var world = _terrain.get_world_2d()
	if world == null:
		push_error("TankSys: Could not get physics world")
		return false

	var space_state = world.direct_space_state
	if space_state == null:
		push_error("TankSys: Could not get space state")
		return false

	# Create a circular query to check for physics bodies at the spawn position
	var query = PhysicsPointQueryParameters2D.new()
	query.position = position
	query.collision_mask = 2  # Check collision layer 2 (tanks and obstacles)
	query.collide_with_areas = false  # Don't check areas (bullets are Area2D)
	query.collide_with_bodies = true  # Check bodies (tanks and obstacles)

	# Perform the query - if any bodies are found, position is not clear
	var results = space_state.intersect_point(query)

	# If no bodies found at exact point, check in a radius around the position
	if results.is_empty():
		var shape_query = PhysicsShapeQueryParameters2D.new()
		var circle_shape = CircleShape2D.new()
		circle_shape.radius = TANK_COLLISION_RADIUS
		shape_query.shape = circle_shape
		shape_query.transform = Transform2D(0, position)
		shape_query.collision_mask = 2  # Check collision layer 2
		shape_query.collide_with_areas = false
		shape_query.collide_with_bodies = true

		results = space_state.intersect_shape(shape_query)

	return results.is_empty()

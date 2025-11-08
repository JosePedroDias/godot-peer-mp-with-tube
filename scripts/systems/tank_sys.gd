class_name TankSys
extends RefCounted

# Constants for spawn collision detection
const TANK_COLLISION_RADIUS: float = 30.0  # Slightly larger than tank's 40x40 collision box
const MAX_SPAWN_ATTEMPTS: int = 10  # Maximum attempts before falling back to any position

var _terrain: Terrain = null
var _tanks_map: Dictionary[String, Tank]
var _assigned_themes: Dictionary[String, String] = {}  # peer_id -> theme mapping

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

func get_theme_for_peer(peer_id: String) -> String:
	# If this peer already has a theme assigned, return it
	if _assigned_themes.has(peer_id):
		return _assigned_themes[peer_id]

	var themes = Tank.THEMES
	var used_themes: Array[String] = []

	# Collect all currently used themes
	for assigned_theme in _assigned_themes.values():
		if not used_themes.has(assigned_theme):
			used_themes.append(assigned_theme)

	# Find the first available theme
	for theme in themes:
		if not used_themes.has(theme):
			_assigned_themes[peer_id] = theme
			return theme

	# If all themes are used, assign randomly (fallback for more players than themes)
	var theme = themes[randi() % themes.size()]
	_assigned_themes[peer_id] = theme
	return theme

func get_assigned_themes() -> Dictionary[String, String]:
	"""Returns a copy of the current theme assignments for debugging"""
	return _assigned_themes.duplicate()

func get_available_themes() -> Array[String]:
	"""Returns list of themes that are not currently assigned to any player"""
	var themes = Tank.THEMES
	var used_themes: Array[String] = []

	# Collect all currently used themes
	for assigned_theme in _assigned_themes.values():
		if not used_themes.has(assigned_theme):
			used_themes.append(assigned_theme)

	var available: Array[String] = []
	for theme in themes:
		if not used_themes.has(theme):
			available.append(theme)

	return available

func set_tank(id: String, tank: Tank) -> void:
	_tanks_map.set(id, tank)
	
func get_tank(id: String) -> Tank:
	return _tanks_map.get(id)

func has_tank(id: String) -> bool:
	return _tanks_map.has(id)

func erase_tank(id: String) -> void:
	_tanks_map.erase(id)
	# Also remove the theme assignment when tank is removed
	_assigned_themes.erase(id)

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

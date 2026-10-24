class_name VillageWorld
extends Node3D

signal tile_clicked(cell: Vector2i)

const TILE_SIZE: float = 1.5
const WorldMaterials = preload("res://scripts/world/world_materials.gd")
const BuildingMeshFactory = preload("res://scripts/world/building_mesh_factory.gd")
const Pathfinder = preload("res://scripts/world/pathfinder.gd")
const M = WorldMaterials

var sim: VillageSimulation
var placement := ""
var overlay := false
var overlay_kind := "road"

# Camera Gimbal & Navigation
var gimbal: Node3D
var inner_gimbal: Node3D
var camera: Camera3D
var sun: DirectionalLight3D
var env_node: WorldEnvironment

var target_pan := Vector3(8.0 * TILE_SIZE, 0, 8.0 * TILE_SIZE)
var target_yaw := deg_to_rad(45.0)
var target_dist := 24.0
var min_dist := 10.0
var max_dist := 48.0

# Backward-compatibility properties
var pan: Vector2:
	get: return Vector2(target_pan.x, target_pan.z)
	set(v): target_pan = Vector3(v.x * 0.03, 0, v.y * 0.03)

var target_zoom: float:
	get: return 24.0 / target_dist
	set(v): target_dist = clampf(24.0 / maxf(0.1, v), min_dist, max_dist)

var zoom_factor: float = 1.0

# Input tracking
var dragging := false
var moved := false
var press_pos := Vector2.ZERO
var fingers: Dictionary = {}
var hover_cell := Vector2i(-1, -1)

# Scene nodes
var ground_root: Node3D
var building_root: Node3D
var foliage_root: Node3D
var npc_root: Node3D
var rain_root: Node3D
var overlay_root: Node3D
var hover_box: MeshInstance3D

var buildings_map: Dictionary = {}
var building_hash: int = 0
var cached_land: int = -1
var foliage_hash: int = -1
var clock: float = 0.0
var routes: Array = []
var route_hash: int = 0
var overlay_hash: int = -1

func _ready() -> void:
	_setup_lighting_and_sky()
	_setup_camera()
	_setup_scene_roots()
	_build_ground_grid()
	_build_natural_foliage()

func _setup_lighting_and_sky() -> void:
	# 1. Environment & Sky
	env_node = WorldEnvironment.new()
	var env := Environment.new()
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color("5aa3dc")
	sky_mat.sky_horizon_color = Color("d5dfd3")
	sky_mat.ground_bottom_color = Color("283b34")
	sky_mat.ground_horizon_color = Color("bdc7ae")
	sky_mat.sun_angle_max = 30.0
	sky.sky_material = sky_mat
	env.sky = sky
	env.background_mode = Environment.BG_SKY
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_sky_contribution = 0.45
	env.ambient_light_energy = 0.45
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env_node.environment = env
	add_child(env_node)

	# 2. Warm Sun Light with Soft Shadows
	sun = DirectionalLight3D.new()
	sun.light_color = Color(1.0, 0.91, 0.77)
	sun.light_energy = 0.75
	sun.shadow_enabled = true
	sun.shadow_blur = 1.3
	sun.rotation_degrees = Vector3(-38.0, 45.0, 0.0)
	add_child(sun)

func _setup_camera() -> void:
	gimbal = Node3D.new()
	gimbal.position = target_pan
	gimbal.rotation.y = target_yaw
	add_child(gimbal)

	inner_gimbal = Node3D.new()
	inner_gimbal.rotation_degrees.x = -36.0
	gimbal.add_child(inner_gimbal)

	camera = Camera3D.new()
	camera.position = Vector3(0, 0, target_dist)
	camera.fov = 32.0
	camera.current = true
	inner_gimbal.add_child(camera)

func _setup_scene_roots() -> void:
	ground_root = Node3D.new()
	add_child(ground_root)

	building_root = Node3D.new()
	add_child(building_root)

	foliage_root = Node3D.new()
	add_child(foliage_root)

	npc_root = Node3D.new()
	add_child(npc_root)

	rain_root = Node3D.new()
	add_child(rain_root)

	overlay_root = Node3D.new()
	add_child(overlay_root)

	# Hover selection preview box
	hover_box = MeshInstance3D.new()
	var hm := BoxMesh.new()
	hm.size = Vector3(TILE_SIZE * 0.96, 0.1, TILE_SIZE * 0.96)
	hover_box.mesh = hm
	hover_box.material_override = M.get_mat("hover_valid")
	hover_box.visible = false
	add_child(hover_box)

func _build_ground_grid() -> void:
	for c in ground_root.get_children():
		c.queue_free()

	if sim == null: return
	var land_size: int = int(sim.state.land)
	cached_land = land_size
	var positions := {"grass": [], "grass_alt": [], "grass_wild": [], "water": []}
	for x in range(40):
		for z in range(40):
			var is_unlocked := x < land_size and z < land_size
			var kind := "grass_wild"
			if is_unlocked:
				kind = "water" if sim.terrain(Vector2i(x,z))=="water" else ("grass_alt" if (x * 7 + z * 11) % 5 == 0 else "grass")
			positions[kind].append(Vector3(float(x) * TILE_SIZE, -0.18, float(z) * TILE_SIZE))
	for kind in positions:
		var cells: Array = positions[kind]
		if cells.is_empty(): continue
		var mesh := BoxMesh.new()
		mesh.size = Vector3(TILE_SIZE, 0.36, TILE_SIZE)
		var batch := MultiMesh.new()
		batch.transform_format = MultiMesh.TRANSFORM_3D
		batch.mesh = mesh
		batch.instance_count = cells.size()
		for i in cells.size(): batch.set_instance_transform(i, Transform3D(Basis.IDENTITY, cells[i]))
		var instance := MultiMeshInstance3D.new()
		instance.multimesh = batch
		instance.material_override = M.get_mat(kind)
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		ground_root.add_child(instance)

func _build_natural_foliage() -> void:
	for c in foliage_root.get_children():
		c.queue_free()
	if sim == null: return
	foliage_hash = hash([int(sim.state.land),sim.state.buildings.size()])
	var land_size := int(sim.state.land)
	for x in range(2,land_size-1):
		for z in range(2,land_size-1):
			var cell := Vector2i(x,z)
			if not sim.building_at(cell).is_empty() or sim.terrain(cell)=="water": continue
			if (x*17+z*23)%37!=0: continue
			var nearby_road := false
			for delta in [Vector2i.UP,Vector2i.DOWN,Vector2i.LEFT,Vector2i.RIGHT]:
				if sim.road_access.has(cell+delta): nearby_road = true
			if nearby_road: continue
			var tree_node: Node3D = BuildingMeshFactory.create_coconut_palm() if (x+z)%3==0 else BuildingMeshFactory.create_banyan_tree()
			tree_node.position = Vector3(float(x)*TILE_SIZE,0,float(z)*TILE_SIZE)
			tree_node.rotation.y = float(x*13+z*7)*0.2
			foliage_root.add_child(tree_node)
	for i in range(36):
		var x: int = posmod(i * 11 + 3, 38)
		var z: int = posmod(i * 17 + 5, 38)
		if x < land_size+3 or z < land_size+3: continue

		var tree_node: Node3D
		if i % 3 == 0:
			tree_node = BuildingMeshFactory.create_coconut_palm()
		else:
			tree_node = BuildingMeshFactory.create_banyan_tree()

		tree_node.position = Vector3(float(x) * TILE_SIZE, 0, float(z) * TILE_SIZE)
		tree_node.rotation.y = float(i) * 0.7
		foliage_root.add_child(tree_node)
	var grass_mesh := BoxMesh.new()
	grass_mesh.size = Vector3(0.035,0.16,0.035)
	var grass_positions: Array[Vector3] = []
	for x in range(1,land_size-1):
		for z in range(1,land_size-1):
			if (x*19+z*31)%4!=0: continue
			var cell := Vector2i(x,z)
			if not sim.building_at(cell).is_empty() or sim.terrain(cell)=="water": continue
			for tuft in range(3):
				grass_positions.append(Vector3((float(x)+float(tuft-1)*0.12)*TILE_SIZE,0.1,(float(z)+float((x+z+tuft)%3-1)*0.1)*TILE_SIZE))
	if not grass_positions.is_empty():
		var grass_batch := MultiMesh.new()
		grass_batch.transform_format = MultiMesh.TRANSFORM_3D
		grass_batch.mesh = grass_mesh
		grass_batch.instance_count = grass_positions.size()
		for i in grass_positions.size(): grass_batch.set_instance_transform(i,Transform3D(Basis.IDENTITY,grass_positions[i]))
		var grass_instance := MultiMeshInstance3D.new()
		grass_instance.multimesh = grass_batch
		grass_instance.material_override = M.get_mat("grass_detail")
		grass_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		foliage_root.add_child(grass_instance)

func rotate_camera(direction: int = 1) -> void:
	target_yaw += deg_to_rad(45.0 * float(direction))

func _process(dt: float) -> void:
	clock += dt

	gimbal.position = gimbal.position.lerp(target_pan, clampf(dt * 10.0, 0.0, 1.0))
	gimbal.rotation.y = lerp_angle(gimbal.rotation.y, target_yaw, clampf(dt * 8.0, 0.0, 1.0))
	camera.position.z = lerpf(camera.position.z, target_dist, clampf(dt * 10.0, 0.0, 1.0))
	zoom_factor = 24.0 / camera.position.z

	if sim == null: return

	if cached_land != int(sim.state.land):
		_build_ground_grid()
	if foliage_hash != hash([int(sim.state.land),sim.state.buildings.size()]):
		_build_natural_foliage()

	_sync_buildings()
	_sync_overlay()

	# Day/Night cycle
	var day_time: float = float(sim.state.time)
	var sun_phase: float = sin(day_time / 120.0 * TAU - PI * 0.5)
	var is_night: bool = sun_phase > 0.35
	if is_night:
		sun.light_color = Color(0.35, 0.45, 0.7)
		sun.light_energy = 0.3
		env_node.environment.ambient_light_energy = 0.45
	else:
		sun.light_color = Color(1.0, 0.94, 0.82)
		sun.light_energy = 0.75
		env_node.environment.ambient_light_energy = 0.45

	_sync_villagers(dt)
	_sync_weather()

func _sync_buildings() -> void:
	var cur_hash := hash([sim.state.buildings.size(), sim.state.money, int(clock)])
	if cur_hash == building_hash:
		return
	building_hash = cur_hash

	var existing_ids := buildings_map.keys()
	var current_ids: Array = []

	for b in sim.state.buildings:
		var b_id: int = int(b.id)
		current_ids.append(b_id)
		var bdef: Dictionary = sim.content.buildings[b.type]
		var footprint: Array = bdef.get("footprint", [1, 1])

		var center_x := (float(b.x) + (float(footprint[0]) - 1.0) * 0.5) * TILE_SIZE
		var center_z := (float(b.y) + (float(footprint[1]) - 1.0) * 0.5) * TILE_SIZE
		var b_pos := Vector3(center_x, 0, center_z)

		var node: Node3D
		if buildings_map.has(b_id):
			node = buildings_map[b_id]
			if node.get_meta("crop", "") != b.get("crop", "") or node.get_meta("upgrade", 1) != b.get("upgrade", 1):
				node.queue_free()
				node = BuildingMeshFactory.create_building_node(b, bdef)
				node.set_meta("crop", b.get("crop", ""))
				node.set_meta("upgrade", b.get("upgrade", 1))
				building_root.add_child(node)
				buildings_map[b_id] = node
		else:
			node = BuildingMeshFactory.create_building_node(b, bdef)
			node.set_meta("crop", b.get("crop", ""))
			node.set_meta("upgrade", b.get("upgrade", 1))
			building_root.add_child(node)
			buildings_map[b_id] = node

		node.position = b_pos

	for old_id in existing_ids:
		if not current_ids.has(old_id):
			if buildings_map.has(old_id) and is_instance_valid(buildings_map[old_id]):
				buildings_map[old_id].queue_free()
			buildings_map.erase(old_id)

func _sync_overlay() -> void:
	var coverage_sources: Array = []
	for building in sim.state.buildings:
		coverage_sources.append([building.get("type"),building.get("x"),building.get("y"),building.get("upgrade")])
	var state_hash := hash([overlay,overlay_kind,int(sim.state.land),coverage_sources,sim.road_access.keys()])
	if state_hash == overlay_hash: return
	overlay_hash = state_hash
	for child in overlay_root.get_children(): child.queue_free()
	if not overlay: return
	var cells: Array[Vector3] = []
	for x in int(sim.state.land):
		for z in int(sim.state.land):
			var cell := Vector2i(x,z)
			var covered := sim.road_access.has(cell) if overlay_kind=="road" else sim.infrastructure.coverage(cell,overlay_kind)>0
			if covered: cells.append(Vector3(float(x)*TILE_SIZE,0.035,float(z)*TILE_SIZE))
	if cells.is_empty(): return
	var mesh := BoxMesh.new()
	mesh.size = Vector3(TILE_SIZE*0.91,0.025,TILE_SIZE*0.91)
	var batch := MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.mesh = mesh
	batch.instance_count = cells.size()
	for i in cells.size(): batch.set_instance_transform(i,Transform3D(Basis.IDENTITY,cells[i]))
	var instance := MultiMeshInstance3D.new()
	instance.multimesh = batch
	instance.material_override = M.get_mat("overlay_road" if overlay_kind=="road" else "overlay_service")
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	overlay_root.add_child(instance)

func _sync_villagers(dt: float) -> void:
	if bool(sim.state.settings.get("reduced_motion", false)):
		for c in npc_root.get_children(): c.queue_free()
		return

	var pop := mini(12, int(sim.state.population))
	var child_count := npc_root.get_child_count()
	while child_count < pop:
		var npc := BuildingMeshFactory.create_villager()
		npc_root.add_child(npc)
		child_count += 1
	while child_count > pop:
		npc_root.get_child(child_count - 1).queue_free()
		child_count -= 1

	var roads: Array = sim.road_access.keys()
	if roads.is_empty(): return
	var new_route_hash := hash([roads, pop])
	if new_route_hash != route_hash:
		route_hash = new_route_hash
		routes.clear()
		for i in pop:
			var start_cell: Vector2i = roads[i % roads.size()]
			var end_cell: Vector2i = roads[(i * 3 + roads.size()/2) % roads.size()]
			var path: Array[Vector2i] = Pathfinder.find_path(start_cell,end_cell,sim.road_access)
			if path.is_empty(): path = [start_cell]
			routes.append(path)

	for i in range(pop):
		var npc: Node3D = npc_root.get_child(i)
		var path: Array[Vector2i] = routes[i]
		var travel := clock * 0.45 + float(i) * 1.7
		var segment := int(floorf(travel)) % maxi(1,(path.size()-1)*2)
		var forward := segment < path.size()-1
		var from_index := segment if forward else (path.size()-1)*2-segment
		var to_index := mini(path.size()-1,from_index+1) if forward else maxi(0,from_index-1)
		var road_cell: Vector2i = path[from_index]
		var next_cell: Vector2i = path[to_index]
		var t := fmod(travel,1.0)
		var current_p := Vector3(float(road_cell.x) * TILE_SIZE, 0.05, float(road_cell.y) * TILE_SIZE)
		var next_p := Vector3(float(next_cell.x) * TILE_SIZE, 0.05, float(next_cell.y) * TILE_SIZE)
		npc.position = current_p.lerp(next_p, t)
		npc.position.y += absf(sin(clock*8.0+float(i)))*0.018
		if current_p.distance_to(next_p) > 0.01:
			npc.look_at(next_p, Vector3.UP)

func _sync_weather() -> void:
	var is_raining: bool = not sim.state.event.is_empty() and sim.state.event.id == "rain"
	if is_raining and rain_root.get_child_count() == 0:
		for j in range(40):
			var rx := (randf() - 0.5) * 20.0
			var rz := (randf() - 0.5) * 20.0
			var ry := randf() * 8.0 + 2.0
			var drop := MeshInstance3D.new()
			var dm := BoxMesh.new()
			dm.size = Vector3(0.03, 0.6, 0.03)
			drop.mesh = dm
			drop.material_override = M.get_mat("water")
			drop.position = Vector3(rx, ry, rz)
			rain_root.add_child(drop)
	elif not is_raining and rain_root.get_child_count() > 0:
		for c in rain_root.get_children(): c.queue_free()

	if is_raining:
		rain_root.position = gimbal.position
		for drop in rain_root.get_children():
			drop.position.y -= 18.0 * get_process_delta_time()
			if drop.position.y < 0.2: drop.position.y = 8.0

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouse and event.device == -1: return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			target_dist = clampf(target_dist * 0.9, min_dist, max_dist)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			target_dist = clampf(target_dist * 1.1, min_dist, max_dist)
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			rotate_camera(1)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				dragging = true
				moved = false
				press_pos = event.position
			else:
				if dragging and not moved:
					var hit_cell := raycast_to_grid(event.position)
					if hit_cell.x >= 0:
						tile_clicked.emit(hit_cell)
				dragging = false

	elif event is InputEventMouseMotion:
		var hit_cell := raycast_to_grid(event.position)
		_update_hover(hit_cell)
		if dragging:
			if event.position.distance_to(press_pos) > 8:
				moved = true
			if moved:
				_pan_camera_by_screen_delta(event.relative)

	elif event is InputEventScreenTouch:
		if event.pressed:
			fingers[event.index] = event.position
			press_pos = event.position
			moved = false
		else:
			if fingers.size() == 1 and not moved:
				var hit_cell := raycast_to_grid(event.position)
				if hit_cell.x >= 0:
					tile_clicked.emit(hit_cell)
			fingers.erase(event.index)

	elif event is InputEventScreenDrag:
		moved = true
		if fingers.size() == 2:
			var keys: Array = fingers.keys()
			var other: Vector2 = fingers[keys[1] if keys[0] == event.index else keys[0]]
			var old_pos: Vector2 = fingers.get(event.index, event.position - event.relative)
			var old_dist: float = old_pos.distance_to(other)
			var new_dist: float = event.position.distance_to(other)
			if old_dist > 10.0 and new_dist > 10.0:
				target_dist = clampf(target_dist * (old_dist / new_dist), min_dist, max_dist)
		else:
			_pan_camera_by_screen_delta(event.relative)
		fingers[event.index] = event.position

func _pan_camera_by_screen_delta(rel: Vector2) -> void:
	var factor := (target_dist / 24.0) * 0.035
	var forward := -gimbal.transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var right := gimbal.transform.basis.x
	right.y = 0.0
	right = right.normalized()

	var delta := (-right * rel.x + forward * rel.y) * factor
	target_pan += delta
	var max_coord := 40.0 * TILE_SIZE
	target_pan.x = clampf(target_pan.x, -5.0, max_coord + 5.0)
	target_pan.z = clampf(target_pan.z, -5.0, max_coord + 5.0)

func raycast_to_grid(screen_pos: Vector2) -> Vector2i:
	if camera == null: return Vector2i(-1, -1)
	var ray_origin := camera.project_ray_origin(screen_pos)
	var ray_dir := camera.project_ray_normal(screen_pos)
	var ground_plane := Plane(Vector3.UP, 0.0)
	var hit = ground_plane.intersects_ray(ray_origin, ray_dir)
	if hit != null:
		var gx := int(round(hit.x / TILE_SIZE))
		var gz := int(round(hit.z / TILE_SIZE))
		if gx >= 0 and gx < 40 and gz >= 0 and gz < 40:
			return Vector2i(gx, gz)
	return Vector2i(-1, -1)

func _update_hover(cell: Vector2i) -> void:
	hover_cell = cell
	if cell.x < 0 or sim == null:
		hover_box.visible = false
		return

	if not placement.is_empty():
		var valid := sim.placement_error(placement, cell).is_empty()
		hover_box.material_override = M.get_mat("hover_valid" if valid else "hover_invalid")
		hover_box.position = Vector3(float(cell.x) * TILE_SIZE, 0.05, float(cell.y) * TILE_SIZE)
		hover_box.visible = true
	else:
		hover_box.visible = false

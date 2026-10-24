class_name BuildingMeshFactory
extends RefCounted

# Generates clean, stylized low-poly 3D models for Kampung Simulator.
# Produces high visual appeal with authentic Indonesian cultural details:
# Joglo roofs, bamboo weave, warung awnings, swimming aquaculture fish, terraced paddies, and palm trees.

const WorldMaterials = preload("res://scripts/world/world_materials.gd")
const M = WorldMaterials

static func box(size: Vector3, mat_id: String, offset: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	mi.mesh = b
	mi.material_override = M.get_mat(mat_id)
	mi.position = offset
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	return mi

static func cylinder(radius: float, height: float, mat_id: String, offset: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = radius
	c.bottom_radius = radius
	c.height = height
	c.radial_segments = 10
	mi.mesh = c
	mi.material_override = M.get_mat(mat_id)
	mi.position = offset
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	return mi

static func prism(size: Vector3, mat_id: String, offset: Vector3 = Vector3.ZERO, rot_y: float = 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var p := PrismMesh.new()
	p.size = size
	mi.mesh = p
	mi.material_override = M.get_mat(mat_id)
	mi.position = offset
	mi.rotation.y = rot_y
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	return mi

static func sphere(radius: float, mat_id: String, offset: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = radius
	s.height = radius * 2.0
	s.radial_segments = 10
	s.rings = 6
	mi.mesh = s
	mi.material_override = M.get_mat(mat_id)
	mi.position = offset
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	return mi

# Builds 3D model for any building definition
static func create_building_node(b: Dictionary, bdef: Dictionary) -> Node3D:
	var root := Node3D.new()
	var btype: String = b.type
	var category: String = bdef.get("category", "")
	var wide: bool = int(bdef.get("footprint", [1, 1])[0]) > 1

	match btype:
		"hall":
			# Balai Desa — Crown jewel of the village with authentic Joglo architecture
			_build_balai_desa(root, b)
		"warung":
			# Warung — Roadside stall with striped canvas awning
			_build_warung(root, b)
		"rice_field":
			# Sawah Padi — Sunken terraced basin with reflective water & 3D rice stalks
			_build_rice_paddy(root, b)
		"catfish", "tilapia":
			# Kolam Ikan — Stone aquaculture basin with swimming fish
			_build_fish_pond(root, b, btype)
		"bamboo":
			# Rumah Bambu — Traditional bamboo stilt hut with thatch roof
			_build_bamboo_house(root, b)
		"wood_house", "simple_house":
			# Rumah Kayu / Sederhana
			_build_timber_house(root, b)
		"permanent", "housing_estate", "apartment", "residence":
			# Rumah Bata & Perumahan
			_build_brick_house(root, b, wide)
		"clinic", "hospital":
			# Puskesmas & Rumah Sakit dengan lambang palang merah
			_build_medical_facility(root, b, btype=="hospital")
		"school":
			# Sekolah Desa dengan tiang bendera
			_build_school(root, b)
		"well", "water_tower":
			# Sumur / Menara Air
			_build_water_facility(root, b, btype)
		"power_station", "solar_park":
			# Pembangkit Listrik / PLTS
			_build_power_facility(root, b, btype)
		"mill", "tofu_factory", "tempe_factory", "flour_factory", "feed_mill", "weaving", "snack_factory", "canning_factory", "cold_storage":
			# Industri & Pengolahan
			_build_factory(root, b, btype, wide)
		"chicken", "duck", "goat", "cow":
			# Kandang Peternakan
			_build_livestock_pen(root, b, btype)
		"corn_field", "chili_field", "cassava_field", "soy_field", "coffee_plantation", "tea_plantation":
			# Ladang pertanian lainnya
			_build_dry_crop_field(root, b, btype)
		"road", "asphalt", "highway", "bridge":
			# Jalan
			_build_road(root, b, btype)
		_:
			# Default building fallback
			if category == "rumah":
				_build_bamboo_house(root, b)
			elif category == "tani":
				_build_rice_paddy(root, b)
			elif category == "niaga":
				_build_warung(root, b)
			elif category == "layanan":
				_build_school(root, b)
			elif category == "industri":
				_build_factory(root, b, btype, wide)
			elif category == "jalan":
				_build_road(root, b, btype)
			else:
				_build_generic_building(root, b, bdef)

	return root

# --- INDIVIDUAL 3D ARCHITECTURAL BUILDERS ---

static func _build_balai_desa(root: Node3D, b: Dictionary) -> void:
	# 1. Stone foundation terrace (Umpak & Batur)
	root.add_child(box(Vector3(2.6, 0.2, 2.6), "stone_plinth", Vector3(0, 0.1, 0)))
	root.add_child(box(Vector3(2.3, 0.15, 2.3), "wall_white", Vector3(0, 0.275, 0)))

	# 2. Four Main Pillars (Saka Guru)
	var pillar_coords = [
		Vector3(-0.7, 0.8, -0.7), Vector3(0.7, 0.8, -0.7),
		Vector3(-0.7, 0.8, 0.7), Vector3(0.7, 0.8, 0.7)
	]
	for p in pillar_coords:
		root.add_child(cylinder(0.065, 1.0, "wood_dark", p))

	# 3. Outer Perimeter Pillars (Saka Rawa)
	var outer_coords = [
		Vector3(-1.05, 0.75, -1.05), Vector3(1.05, 0.75, -1.05),
		Vector3(-1.05, 0.75, 1.05), Vector3(1.05, 0.75, 1.05),
		Vector3(0, 0.75, -1.05), Vector3(0, 0.75, 1.05),
		Vector3(-1.05, 0.75, 0), Vector3(1.05, 0.75, 0)
	]
	for op in outer_coords:
		root.add_child(cylinder(0.045, 0.9, "wood_light", op))

	# 4. Indonesian Joglo Tiered Roof (Atap Joglo Lambang Sari)
	# Lower broad flared eave:
	root.add_child(box(Vector3(2.7, 0.1, 2.7), "terracotta_roof", Vector3(0, 1.25, 0)))
	root.add_child(prism(Vector3(2.5, 0.5, 2.5), "terracotta_roof", Vector3(0, 1.55, 0), 0.0))
	# Upper steep pyramid crown (Atap Tajug):
	root.add_child(box(Vector3(1.4, 0.1, 1.4), "terracotta_dark", Vector3(0, 1.7, 0)))
	root.add_child(prism(Vector3(1.2, 0.8, 1.2), "terracotta_roof", Vector3(0, 2.1, 0), PI*0.25))
	# Crown pinnacle (Bubungan / Molo):
	root.add_child(cylinder(0.08, 0.3, "wood_dark", Vector3(0, 2.6, 0)))

	# 5. Hanging Center Golden Lantern
	root.add_child(sphere(0.12, "lantern_glow", Vector3(0, 1.1, 0)))

	# 6. Flagpole with Sang Saka Merah Putih
	root.add_child(cylinder(0.025, 1.8, "wall_white", Vector3(1.15, 0.9, 1.15)))
	root.add_child(box(Vector3(0.35, 0.12, 0.02), "flag_red", Vector3(1.33, 1.65, 1.15)))
	root.add_child(box(Vector3(0.35, 0.12, 0.02), "flag_white", Vector3(1.33, 1.53, 1.15)))

static func _build_warung(root: Node3D, b: Dictionary) -> void:
	# Wooden stall counter
	root.add_child(box(Vector3(1.1, 0.55, 0.9), "wood_light", Vector3(0, 0.275, 0)))
	# Display shelf
	root.add_child(box(Vector3(1.0, 0.15, 0.35), "bamboo_wall", Vector3(0, 0.45, 0.3)))
	# Vegetable crates
	root.add_child(box(Vector3(0.25, 0.18, 0.2), "corn_yellow", Vector3(-0.3, 0.6, 0.3)))
	root.add_child(box(Vector3(0.25, 0.18, 0.2), "chili_red", Vector3(0.3, 0.6, 0.3)))

	# Slanted Striped Canvas Awning (Tenda Warung Merah Putih)
	var awning := Node3D.new()
	awning.position = Vector3(0, 0.9, 0)
	awning.rotation.x = deg_to_rad(18.0)
	for i in range(5):
		var x_pos := -0.48 + float(i) * 0.24
		var mat_name := "awning_red" if i % 2 == 0 else "awning_cream"
		awning.add_child(box(Vector3(0.24, 0.05, 1.05), mat_name, Vector3(x_pos, 0, 0.1)))
	root.add_child(awning)

	# Thin wooden support poles
	root.add_child(cylinder(0.025, 0.9, "wood_dark", Vector3(-0.52, 0.45, 0.48)))
	root.add_child(cylinder(0.025, 0.9, "wood_dark", Vector3(0.52, 0.45, 0.48)))
	# Warm lantern bulb
	root.add_child(sphere(0.08, "lantern_glow", Vector3(0, 0.8, 0.1)))
	# A produce basket and the handcart make the stall readable from above.
	root.add_child(cylinder(0.16,0.12,"wood_dark",Vector3(-0.42,0.08,0.58)))
	for i in range(3): root.add_child(sphere(0.065,"corn_yellow",Vector3(-0.52+float(i)*0.1,0.17,0.58)))
	root.add_child(box(Vector3(0.45,0.07,0.26),"wood_light",Vector3(0.48,0.26,-0.52)))
	root.add_child(cylinder(0.11,0.05,"wood_dark",Vector3(0.28,0.12,-0.52)))
	root.add_child(cylinder(0.11,0.05,"wood_dark",Vector3(0.68,0.12,-0.52)))

static func _build_rice_paddy(root: Node3D, b: Dictionary) -> void:
	# 2x2 footprint terraced sawah basin
	# Raised mud embankment (Pematang Sawah)
	root.add_child(box(Vector3(2.85, 0.18, 2.85), "dirt_moist", Vector3(0, 0.09, 0)))
	# Sunken water surface reflecting sky
	root.add_child(box(Vector3(2.65, 0.08, 2.65), "water_paddy", Vector3(0, 0.14, 0)))

	# 3D Rice Stalks
	var crop_state: String = b.get("crop", "EMPTY")
	var is_ready: bool = crop_state == "READY"
	var is_planted: bool = crop_state in ["READY", "GROWING", "PLANTED"]

	if is_planted:
		var stalk_mat := "paddy_golden" if is_ready else "paddy_green"
		var height := 0.45 if is_ready else 0.28
		for rx in range(4):
			for rz in range(4):
				var px := -0.9 + float(rx) * 0.6
				var pz := -0.9 + float(rz) * 0.6
				var stalk_group := Node3D.new()
				stalk_group.position = Vector3(px, 0.18, pz)
				# 3 slender stalks per tuft
				stalk_group.add_child(box(Vector3(0.04, height, 0.04), stalk_mat, Vector3(0, height*0.5, 0)))
				stalk_group.add_child(box(Vector3(0.03, height*0.8, 0.03), stalk_mat, Vector3(0.05, height*0.4, 0.04)))
				stalk_group.add_child(box(Vector3(0.03, height*0.75, 0.03), stalk_mat, Vector3(-0.04, height*0.38, -0.03)))
				if is_ready:
					# Golden mature seed head
					stalk_group.add_child(sphere(0.07, "paddy_golden", Vector3(0, height, 0)))
				root.add_child(stalk_group)
	elif crop_state == "HARVESTED":
		# Short harvest stubble
		for rx in range(4):
			for rz in range(4):
				var px := -0.9 + float(rx) * 0.6
				var pz := -0.9 + float(rz) * 0.6
				root.add_child(cylinder(0.035, 0.08, "dirt", Vector3(px, 0.18, pz)))
	# A small irrigation gate and hoe distinguish the field from a flat pond.
	root.add_child(box(Vector3(0.24,0.18,0.12),"wood_light",Vector3(1.12,0.2,0)))
	var hoe := cylinder(0.025,0.72,"wood_dark",Vector3(1.16,0.52,0.72))
	hoe.rotation.z = deg_to_rad(20.0)
	root.add_child(hoe)
	root.add_child(box(Vector3(0.3,0.04,0.07),"road_border",Vector3(1.27,0.83,0.72)))

static func _build_fish_pond(root: Node3D, b: Dictionary, btype: String) -> void:
	# Stone basin perimeter
	root.add_child(box(Vector3(2.8, 0.25, 2.8), "stone_plinth", Vector3(0, 0.125, 0)))
	# Sunken deep sparkling water
	root.add_child(box(Vector3(2.5, 0.12, 2.5), "water", Vector3(0, 0.16, 0)))

	# Swimming 3D Fish
	var fish_mat := "fish_catfish" if btype == "catfish" else "fish_silver"
	for i in range(4):
		var angle := float(i) * TAU / 4.0
		var fx := cos(angle) * 0.7
		var fz := sin(angle) * 0.7
		var fish := Node3D.new()
		fish.position = Vector3(fx, 0.17, fz)
		fish.rotation.y = angle + PI*0.5
		# Fish body & tail
		fish.add_child(box(Vector3(0.08, 0.04, 0.24), fish_mat))
		fish.add_child(prism(Vector3(0.06, 0.08, 0.1), fish_mat, Vector3(0, 0, -0.16), PI))
		root.add_child(fish)

static func _build_bamboo_house(root: Node3D, b: Dictionary) -> void:
	# Stilt foundation
	var stilts = [
		Vector3(-0.45, 0.15, -0.45), Vector3(0.45, 0.15, -0.45),
		Vector3(-0.45, 0.15, 0.45), Vector3(0.45, 0.15, 0.45)
	]
	for sp in stilts:
		root.add_child(cylinder(0.04, 0.3, "wood_dark", sp))

	# Raised floor
	root.add_child(box(Vector3(1.15, 0.08, 1.15), "wood_light", Vector3(0, 0.32, 0)))

	# Woven bamboo walls (Gedek)
	root.add_child(box(Vector3(1.0, 0.65, 1.0), "bamboo_wall", Vector3(0, 0.68, 0)))

	# Thatched palm roof (Atap Rumbia / Ijuk)
	root.add_child(prism(Vector3(1.3, 0.7, 1.3), "thatch_roof", Vector3(0, 1.35, 0)))
	root.add_child(box(Vector3(0.22,0.48,0.025),"wood_dark",Vector3(0,0.53,0.52)))
	for x in [-0.28,0.28]:
		root.add_child(box(Vector3(0.15,0.16,0.025),"wood_dark",Vector3(x,0.8,0.52)))
	for i in range(4):
		root.add_child(box(Vector3(1.01,0.018,0.018),"wood_light",Vector3(0,0.43+float(i)*0.13,0.53)))
	root.add_child(box(Vector3(0.32,0.035,0.34),"wood_light",Vector3(0,0.3,0.7)))

	# Small front porch lantern
	root.add_child(sphere(0.06, "lantern_glow", Vector3(0, 0.75, 0.55)))

static func _build_timber_house(root: Node3D, b: Dictionary) -> void:
	root.add_child(box(Vector3(1.2, 0.15, 1.2), "stone_plinth", Vector3(0, 0.075, 0)))
	root.add_child(box(Vector3(1.05, 0.75, 1.05), "wood_light", Vector3(0, 0.525, 0)))
	# Terracotta pitched roof with overhang
	root.add_child(prism(Vector3(1.35, 0.65, 1.35), "terracotta_roof", Vector3(0, 1.2, 0)))
	root.add_child(box(Vector3(0.2, 0.45, 0.05), "wood_dark", Vector3(0, 0.38, 0.54)))
	root.add_child(sphere(0.06, "lantern_glow", Vector3(0.2, 0.65, 0.55)))

static func _build_brick_house(root: Node3D, b: Dictionary, wide: bool) -> void:
	var width := 2.2 if wide else 1.2
	var length := 2.2 if wide else 1.2
	var height := 1.2 if wide else 0.85
	root.add_child(box(Vector3(width+0.1, 0.15, length+0.1), "stone_plinth", Vector3(0, 0.075, 0)))
	root.add_child(box(Vector3(width, height, length), "wall_brick", Vector3(0, height*0.5+0.15, 0)))
	root.add_child(prism(Vector3(width+0.25, 0.75, length+0.25), "terracotta_roof", Vector3(0, height+0.5, 0)))
	# Front door & porch light
	root.add_child(box(Vector3(0.3, 0.55, 0.05), "wood_dark", Vector3(0, 0.45, length*0.5+0.02)))
	root.add_child(sphere(0.07, "lantern_glow", Vector3(0, 0.85, length*0.5+0.06)))

static func _build_medical_facility(root: Node3D, b: Dictionary, hospital: bool) -> void:
	var w := 2.4 if hospital else 1.3
	var l := 2.4 if hospital else 1.3
	var h := 1.4 if hospital else 0.9
	root.add_child(box(Vector3(w+0.1, 0.15, l+0.1), "stone_plinth", Vector3(0, 0.075, 0)))
	root.add_child(box(Vector3(w, h, l), "wall_white", Vector3(0, h*0.5+0.15, 0)))
	root.add_child(prism(Vector3(w+0.2, 0.6, l+0.2), "road_asphalt", Vector3(0, h+0.45, 0)))

	# 3D Red Cross Emblem
	var cross_y := h*0.5 + 0.3
	var cross_z := l*0.5 + 0.03
	root.add_child(box(Vector3(0.35, 0.12, 0.04), "cross_red", Vector3(0, cross_y, cross_z)))
	root.add_child(box(Vector3(0.12, 0.35, 0.04), "cross_red", Vector3(0, cross_y, cross_z)))

static func _build_school(root: Node3D, b: Dictionary) -> void:
	# School building with courtyard & bell tower
	root.add_child(box(Vector3(2.4, 0.15, 2.4), "stone_plinth", Vector3(0, 0.075, 0)))
	root.add_child(box(Vector3(2.0, 0.9, 1.2), "wall_white", Vector3(0, 0.6, -0.4)))
	root.add_child(prism(Vector3(2.2, 0.6, 1.4), "terracotta_roof", Vector3(0, 1.35, -0.4)))
	# Small bell / clock tower
	root.add_child(box(Vector3(0.5, 0.7, 0.5), "wall_white", Vector3(0, 1.7, -0.4)))
	root.add_child(prism(Vector3(0.7, 0.4, 0.7), "terracotta_dark", Vector3(0, 2.2, -0.4)))
	# Schoolyard flagpole
	root.add_child(cylinder(0.02, 1.5, "wall_white", Vector3(0.7, 0.75, 0.7)))
	root.add_child(box(Vector3(0.25, 0.09, 0.01), "flag_red", Vector3(0.83, 1.35, 0.7)))
	root.add_child(box(Vector3(0.25, 0.09, 0.01), "flag_white", Vector3(0.83, 1.26, 0.7)))

static func _build_water_facility(root: Node3D, b: Dictionary, btype: String) -> void:
	if btype == "well":
		# Circular stone village well
		root.add_child(cylinder(0.45, 0.5, "stone_plinth", Vector3(0, 0.25, 0)))
		root.add_child(cylinder(0.35, 0.1, "water", Vector3(0, 0.42, 0)))
		# Wooden A-frame roof over well
		root.add_child(cylinder(0.03, 0.8, "wood_dark", Vector3(-0.35, 0.7, 0)))
		root.add_child(cylinder(0.03, 0.8, "wood_dark", Vector3(0.35, 0.7, 0)))
		root.add_child(prism(Vector3(0.9, 0.35, 0.6), "terracotta_roof", Vector3(0, 1.2, 0)))
	else:
		# Water tower
		for p in [Vector3(-0.4, 1.0, -0.4), Vector3(0.4, 1.0, -0.4), Vector3(-0.4, 1.0, 0.4), Vector3(0.4, 1.0, 0.4)]:
			root.add_child(cylinder(0.04, 2.0, "road_border", p))
		root.add_child(cylinder(0.55, 0.9, "road_asphalt", Vector3(0, 2.4, 0)))

static func _build_power_facility(root: Node3D, b: Dictionary, btype: String) -> void:
	if btype == "solar_park":
		# Array of tilted solar panels
		for i in range(2):
			for j in range(2):
				var panel_node := Node3D.new()
				panel_node.position = Vector3(-0.45 + i*0.9, 0.35, -0.45 + j*0.9)
				panel_node.rotation.x = deg_to_rad(-25.0)
				panel_node.add_child(box(Vector3(0.75, 0.04, 0.6), "road_asphalt"))
				panel_node.add_child(cylinder(0.03, 0.4, "road_border", Vector3(0, -0.15, 0)))
				root.add_child(panel_node)
	else:
		root.add_child(box(Vector3(1.2, 0.9, 1.2), "wall_white", Vector3(0, 0.45, 0)))
		root.add_child(cylinder(0.04, 1.8, "road_border", Vector3(0, 0.9, 0)))

static func _build_factory(root: Node3D, b: Dictionary, btype: String, wide: bool) -> void:
	var w := 2.4 if wide else 1.3
	var l := 2.4 if wide else 1.3
	root.add_child(box(Vector3(w, 0.85, l), "wall_white", Vector3(0, 0.425, 0)))
	root.add_child(prism(Vector3(w+0.15, 0.6, l+0.15), "terracotta_roof", Vector3(0, 1.15, 0)))
	# Industrial smokestack / chimney
	root.add_child(cylinder(0.12, 1.6, "wall_brick", Vector3(w*0.35, 1.1, l*0.35)))
	# Grain silo or waterwheel
	root.add_child(cylinder(0.35, 1.2, "wood_light", Vector3(-w*0.35, 0.6, -l*0.35)))

static func _build_livestock_pen(root: Node3D, b: Dictionary, btype: String) -> void:
	# Dirt pen ground
	root.add_child(box(Vector3(1.3, 0.08, 1.3), "dirt", Vector3(0, 0.04, 0)))
	# Wooden fence posts
	var posts = [
		Vector3(-0.55, 0.25, -0.55), Vector3(0.55, 0.25, -0.55),
		Vector3(-0.55, 0.25, 0.55), Vector3(0.55, 0.25, 0.55)
	]
	for post in posts:
		root.add_child(cylinder(0.03, 0.5, "wood_dark", post))
	# Shelter coop
	root.add_child(box(Vector3(0.6, 0.5, 0.6), "bamboo_wall", Vector3(-0.25, 0.3, -0.25)))
	root.add_child(prism(Vector3(0.75, 0.35, 0.75), "thatch_roof", Vector3(-0.25, 0.7, -0.25)))

static func _build_dry_crop_field(root: Node3D, b: Dictionary, btype: String) -> void:
	# Soil bed
	root.add_child(box(Vector3(1.35, 0.12, 1.35), "dirt", Vector3(0, 0.06, 0)))
	# 3D plants based on type
	var mat_name := "corn_stalk"
	if "chili" in btype: mat_name = "chili_red"
	for i in range(3):
		for j in range(3):
			var plant := sphere(0.14, mat_name, Vector3(-0.35 + i*0.35, 0.22, -0.35 + j*0.35))
			root.add_child(plant)

static func _build_road(root: Node3D, b: Dictionary, btype: String) -> void:
	var mat_name := "road_dirt" if btype == "road" else "road_asphalt"
	# Slightly raised 3D road slab with stone borders
	root.add_child(box(Vector3(1.42, 0.07, 1.42), mat_name, Vector3(0, 0.035, 0)))
	# Stone curb borders
	root.add_child(box(Vector3(1.48, 0.09, 0.08), "road_border", Vector3(0, 0.045, -0.68)))
	root.add_child(box(Vector3(1.48, 0.09, 0.08), "road_border", Vector3(0, 0.045, 0.68)))

static func _build_generic_building(root: Node3D, b: Dictionary, bdef: Dictionary) -> void:
	root.add_child(box(Vector3(1.1, 0.7, 1.1), "wall_white", Vector3(0, 0.35, 0)))
	root.add_child(prism(Vector3(1.3, 0.5, 1.3), "terracotta_roof", Vector3(0, 0.95, 0)))

# --- NATURAL DECORATIONS (Coconut Palms, Banyan Trees) ---

static func create_coconut_palm() -> Node3D:
	var tree := Node3D.new()
	# Curved segmented trunk
	var segments := 5
	var prev_pos := Vector3.ZERO
	for i in range(segments):
		var y := float(i) * 0.35 + 0.18
		var lean := sin(float(i) * 0.4) * 0.12
		var seg := cylinder(0.08 - float(i)*0.008, 0.36, "palm_trunk", Vector3(lean, y, 0))
		seg.rotation.z = deg_to_rad(float(i)*3.5)
		tree.add_child(seg)

	var top_pos := Vector3(sin(float(segments-1)*0.4)*0.12, float(segments)*0.35, 0)

	# Coconuts cluster
	for ci in range(3):
		var ca := float(ci) * TAU / 3.0
		tree.add_child(sphere(0.08, "coconut", top_pos + Vector3(cos(ca)*0.12, -0.1, sin(ca)*0.12)))

	# 6 Arching Palm Fronds
	for fi in range(6):
		var fa := float(fi) * TAU / 6.0
		var frond := Node3D.new()
		frond.position = top_pos
		frond.rotation.y = fa
		frond.rotation.x = deg_to_rad(-25.0)
		# 2 segments per frond
		frond.add_child(box(Vector3(0.18, 0.03, 0.45), "palm_frond", Vector3(0, 0, 0.22)))
		var tip := box(Vector3(0.14, 0.02, 0.4), "palm_frond", Vector3(0, -0.1, 0.58))
		tip.rotation.x = deg_to_rad(-30.0)
		frond.add_child(tip)
		tree.add_child(frond)

	return tree

static func create_banyan_tree() -> Node3D:
	var tree := Node3D.new()
	# Thick sturdy trunk
	tree.add_child(cylinder(0.14, 0.9, "wood_dark", Vector3(0, 0.45, 0)))
	# Overlapping cloud-like canopy spheres
	tree.add_child(sphere(0.55, "tree_canopy", Vector3(0, 1.25, 0)))
	tree.add_child(sphere(0.45, "tree_canopy", Vector3(-0.35, 1.05, 0.2)))
	tree.add_child(sphere(0.48, "tree_canopy", Vector3(0.3, 1.1, -0.2)))
	return tree

# --- LIVING NPC VILLAGER (Warga dengan Caping) ---

static func create_villager() -> Node3D:
	var npc := Node3D.new()
	# Body with colorful sarong / shirt
	var colors = ["flag_red", "awning_red", "paddy_golden", "wood_light"]
	var c_mat: String = colors[randi() % colors.size()]
	npc.add_child(cylinder(0.09, 0.3, c_mat, Vector3(0, 0.27, 0)))
	for side in [-1.0,1.0]:
		var arm := cylinder(0.028,0.25,"villager_skin",Vector3(side*0.12,0.28,0))
		arm.rotation.z = side*deg_to_rad(24.0)
		npc.add_child(arm)
		npc.add_child(cylinder(0.035,0.18,"wood_dark",Vector3(side*0.05,0.045,0)))
	# Head
	npc.add_child(sphere(0.09, "villager_skin", Vector3(0, 0.45, 0)))
	# Conical Straw Farmer Hat (Caping)
	var caping := MeshInstance3D.new()
	var hat := CylinderMesh.new()
	hat.top_radius = 0.0
	hat.bottom_radius = 0.23
	hat.height = 0.18
	hat.radial_segments = 12
	caping.mesh = hat
	caping.material_override = M.get_mat("villager_caping")
	caping.position = Vector3(0,0.59,0)
	npc.add_child(caping)
	return npc

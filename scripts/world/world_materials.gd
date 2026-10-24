class_name WorldMaterials
extends RefCounted

# Centralized stylized PBR material library for Kampung Simulator 3D.
# Designed for warm, vibrant, eye-pleasing tropical village aesthetics.

static var _materials: Dictionary = {}

static func get_mat(id: String) -> StandardMaterial3D:
	if _materials.has(id):
		return _materials[id]
	var mat := StandardMaterial3D.new()
	mat.roughness = 0.85
	mat.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX

	match id:
		"grass":
			# Warm, lush, inviting tropical meadow green
			mat.albedo_color = Color("355b45")
			mat.roughness = 0.8
		"grass_alt":
			# Subtle checkerboard variation for tile definition
			mat.albedo_color = Color("3a6049")
			mat.roughness = 0.8
		"grass_wild":
			# Deep rainforest verge
			mat.albedo_color = Color("263f34")
			mat.roughness = 0.9
		"grass_detail":
			mat.albedo_color = Color("2b5c3c")
			mat.roughness = 1.0
		"dirt":
			# Rich warm Indonesian red-brown soil / pematang
			mat.albedo_color = Color("8c5e39")
			mat.roughness = 0.95
		"dirt_moist":
			# Dark saturated fertile irrigated soil
			mat.albedo_color = Color("5a3b22")
			mat.roughness = 0.6
		"road_dirt":
			# Packed village walking path
			mat.albedo_color = Color("bca37f")
			mat.roughness = 0.9
		"road_asphalt":
			# Paved village road
			mat.albedo_color = Color("4b5358")
			mat.roughness = 0.7
		"road_border":
			# River stone curb border
			mat.albedo_color = Color("766f68")
			mat.roughness = 0.8
		"water":
			# Translucent sparkling tropical river/pond water
			mat.albedo_color = Color(0.20, 0.68, 0.82, 0.78)
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.roughness = 0.15
			mat.metallic = 0.1
		"water_paddy":
			# Reflective shallow sawah water layer
			mat.albedo_color = Color(0.20, 0.39, 0.38, 0.86)
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.roughness = 0.1
		"wood_dark":
			# Polished dark teak / sonokeling timber pillars
			mat.albedo_color = Color("4a2d18")
			mat.roughness = 0.75
		"wood_light":
			# Bamboo poles / light timber
			mat.albedo_color = Color("c49a62")
			mat.roughness = 0.8
		"bamboo_wall":
			# Woven bamboo split weave (gedek)
			mat.albedo_color = Color("d4af6d")
			mat.roughness = 0.85
		"thatch_roof":
			# Traditional dark palm thatch (ijuk / rumbia)
			mat.albedo_color = Color("3d332a")
			mat.roughness = 0.95
		"terracotta_roof":
			# Traditional red clay tile roof (genteng tanah liat)
			mat.albedo_color = Color("a34b35")
			mat.roughness = 0.7
		"terracotta_dark":
			# Roof ridge tiles and caps
			mat.albedo_color = Color("8b3319")
			mat.roughness = 0.75
		"wall_white":
			# Clean whitewashed masonry
			mat.albedo_color = Color("ece8db")
			mat.roughness = 0.8
		"wall_brick":
			# Red rustic brick
			mat.albedo_color = Color("9c4b38")
			mat.roughness = 0.85
		"stone_plinth":
			# Carved stone foundation
			mat.albedo_color = Color("686c67")
			mat.roughness = 0.9
		"flag_red":
			mat.albedo_color = Color("d62828")
			mat.roughness = 0.6
		"flag_white":
			mat.albedo_color = Color("f4f4f4")
			mat.roughness = 0.6
		"awning_red":
			mat.albedo_color = Color("d03b32")
			mat.roughness = 0.7
		"awning_cream":
			mat.albedo_color = Color("f5edd6")
			mat.roughness = 0.7
		"paddy_green":
			# Young growing rice shoots
			mat.albedo_color = Color("88bf43")
			mat.roughness = 0.6
		"paddy_golden":
			# Ripe golden harvest grain
			mat.albedo_color = Color("f1c232")
			mat.roughness = 0.6
		"corn_stalk":
			mat.albedo_color = Color("6b9e3b")
			mat.roughness = 0.7
		"corn_yellow":
			mat.albedo_color = Color("f9cb42")
			mat.roughness = 0.6
		"chili_red":
			mat.albedo_color = Color("e02e24")
			mat.roughness = 0.5
		"palm_trunk":
			# Curved coconut palm trunk
			mat.albedo_color = Color("6d5641")
			mat.roughness = 0.85
		"palm_frond":
			# Lush coconut palm leaves
			mat.albedo_color = Color("3b6b39")
			mat.roughness = 0.7
		"coconut":
			mat.albedo_color = Color("5c4028")
			mat.roughness = 0.8
		"tree_canopy":
			# Shading banyan / mango tree foliage
			mat.albedo_color = Color("356340")
			mat.roughness = 0.85
		"fish_silver":
			mat.albedo_color = Color("c8dbe3")
			mat.roughness = 0.3
			mat.metallic = 0.5
		"fish_catfish":
			mat.albedo_color = Color("3a444a")
			mat.roughness = 0.4
		"lantern_glow":
			# Warm golden lantern light
			mat.albedo_color = Color("ffe17d")
			mat.emission_enabled = true
			mat.emission = Color("ffbe43")
			mat.emission_energy_multiplier = 2.5
		"cross_red":
			# Medical red cross emblem
			mat.albedo_color = Color("dc2626")
			mat.roughness = 0.4
		"villager_skin":
			mat.albedo_color = Color("e0ac69")
			mat.roughness = 0.8
		"villager_caping":
			# Conical straw farmer hat
			mat.albedo_color = Color("d9b87b")
			mat.roughness = 0.9
		"hover_valid":
			mat.albedo_color = Color(0.95, 0.85, 0.35, 0.55)
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		"hover_invalid":
			mat.albedo_color = Color(0.92, 0.25, 0.22, 0.65)
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		"overlay_road":
			mat.albedo_color = Color(0.95, 0.78, 0.25, 0.45)
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		"overlay_service":
			mat.albedo_color = Color(0.25, 0.75, 0.95, 0.4)
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_:
			mat.albedo_color = Color("888888")

	_materials[id] = mat
	return mat


class_name VillageSave
extends RefCounted

const SAVE_PATH := "user://village.json"
var recovered := false
var error_message := ""

func integer_value(value: Variant, minimum: int = 0, maximum: int = 9000000000000) -> bool:
	if not (value is int or value is float): return false
	return is_finite(float(value)) and float(value)==floorf(float(value)) and float(value)>=minimum and float(value)<=maximum

func nonnegative_number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value)>=0

func validate(data: Variant, sim: VillageSimulation) -> bool:
	if not data is Dictionary: return false
	for key in ["version","money","inventory","buildings","population","xp","level","land","time","last_seen"]:
		if not data.has(key): return false
	for key in ["version","money","population","xp","level","land","last_seen"]:
		if not integer_value(data[key]): return false
	if not data.inventory is Dictionary or not data.buildings is Array: return false
	if int(data.version)<1 or int(data.version)>3 or not nonnegative_number(data.time): return false
	if int(data.land)<16 or int(data.land)>40 or int(data.level)<1 or int(data.level)>300: return false
	for key in data.inventory:
		if not sim.content.products.has(key) or not integer_value(data.inventory[key]): return false
	for key in ["counters","quests","settings","event","event_history"]:
		if data.has(key) and not data[key] is Dictionary: return false
	for key in data.get("counters",{}):
		if not integer_value(data.counters[key]): return false
	for key in data.get("quests",{}):
		if not data.quests[key] is bool: return false
	for key in data.get("event_history",{}):
		if not nonnegative_number(data.event_history[key]): return false
	for key in ["research","achievements"]:
		if data.has(key) and not data[key] is Array: return false
	for id in data.get("research",[]):
		if not id is String or not sim.content.technologies.has(id): return false
	var settings: Dictionary = data.get("settings",{})
	for key in ["master","music","sfx","ambient"]:
		if settings.has(key) and (not nonnegative_number(settings[key]) or float(settings[key])>1): return false
	if settings.has("language") and settings.language not in ["id","en"]: return false
	if settings.has("reduced_motion") and not settings.reduced_motion is bool: return false
	var active: Dictionary = data.get("event",{})
	if not active.is_empty():
		for key in ["id","name","effect","multiplier","until"]:
			if not active.has(key): return false
		if not active.id is String or not active.name is String or not active.effect is String: return false
		if not nonnegative_number(active.multiplier) or not nonnegative_number(active.until): return false
	for key in ["day_accum","event_accum","happiness"]:
		if data.has(key) and not nonnegative_number(data[key]): return false
	for key in ["prestige","next_id","offline_seconds"]:
		if data.has(key) and not integer_value(data[key]): return false
	if data.has("profit") and not integer_value(data.profit,-9000000000000): return false
	var occupied: Dictionary = {}
	var ids: Dictionary = {}
	for b in data.buildings:
		if not b is Dictionary: return false
		for key in ["id","type","x","y","upgrade","construction","progress","crop"]:
			if not b.has(key): return false
		for key in ["id","x","y","upgrade"]:
			if not integer_value(b[key]): return false
		if not b.type is String or not sim.content.buildings.has(b.type) or ids.has(int(b.id)): return false
		ids[int(b.id)] = true
		if int(b.upgrade)<1 or int(b.upgrade)>5 or not nonnegative_number(b.construction) or not nonnegative_number(b.progress): return false
		if b.crop not in ["EMPTY","PLANTED","GROWING","READY","HARVESTED"]: return false
		for key in ["animals","stored"]:
			if b.has(key) and not integer_value(b[key],0,1000000): return false
		if b.has("moisture") and (not nonnegative_number(b.moisture) or float(b.moisture)>100): return false
		if b.has("health") and (not nonnegative_number(b.health) or float(b.health)>100): return false
		if b.has("fertilized") and not b.fertilized is bool: return false
		var size: Array = sim.content.buildings[b.type].footprint
		for x in range(int(size[0])):
			for y in range(int(size[1])):
				var p := Vector2i(int(b.x)+x,int(b.y)+y)
				if p.x<0 or p.y<0 or p.x>=int(data.land) or p.y>=int(data.land) or occupied.has(p): return false
				occupied[p] = true
	return true

func save_game(sim: VillageSimulation, path: String = SAVE_PATH) -> bool:
	error_message = ""
	if not validate(sim.state,sim):
		error_message = "Invalid simulation state"
		return false
	sim.state.last_seen = maxi(int(sim.state.last_seen),int(Time.get_unix_time_from_system()))
	var temp := path+".tmp"
	var file := FileAccess.open(temp,FileAccess.WRITE)
	if file == null: return false
	file.store_string(JSON.stringify(sim.state))
	file.flush()
	file.close()
	if FileAccess.file_exists(path):
		var old: Variant = parse_json(path)
		if validate(old,sim):
			if DirAccess.copy_absolute(path,path+".bak")!=OK: return false
	var code := DirAccess.rename_absolute(temp,path)
	return code==OK

func load_game(sim: VillageSimulation, path: String = SAVE_PATH, offline: bool = true) -> bool:
	recovered = false
	for candidate in [path,path+".bak",path+".tmp"]:
		if not FileAccess.file_exists(candidate): continue
		var parsed: Variant = parse_json(candidate)
		if not validate(parsed,sim): continue
		var defaults: Dictionary = sim.state.duplicate(true)
		defaults.merge(parsed,true)
		var merged_settings: Dictionary = sim.state.settings.duplicate(true)
		merged_settings.merge(defaults.settings,true)
		defaults.settings = merged_settings
		if not defaults.settings is Dictionary: continue
		for b in defaults.buildings:
			for key in {"animals":0,"health":100.0,"fertilized":false,"stored":0,"moisture":100.0}:
				if not b.has(key): b[key] = {"animals":0,"health":100.0,"fertilized":false,"stored":0,"moisture":100.0}[key]
		var previous_version := int(defaults.version)
		defaults.version = 3
		var max_id := 0
		for b in defaults.buildings: max_id = maxi(max_id,int(b.id))
		defaults.next_id = maxi(max_id+1,int(defaults.next_id))
		sim.state = defaults
		sim.connectivity_dirty = true
		sim.grid_dirty = true
		# v2 used a diagonal entrance seed. Add the missing connecting road when
		# upgrading that exact starter layout; never replace an occupied tile.
		if previous_version<3:
			var hall := sim.building_at(Vector2i(4,6))
			var entrance := sim.building_at(Vector2i(6,8))
			if hall.get("type","")=="hall" and entrance.get("type","")=="road" and sim.building_at(Vector2i(5,8)).is_empty():
				sim._add_building("road",Vector2i(5,8),true)
		sim.recompute()
		if offline:
			var now := int(Time.get_unix_time_from_system())
			var elapsed := clampi(now-int(sim.state.last_seen),0,int(sim.content.balance.offline_cap))
			sim.tick(elapsed)
			sim.state.offline_seconds = elapsed
			sim.state.last_seen = maxi(now,int(sim.state.last_seen))
		recovered = candidate!=path
		return true
	error_message = "No valid save or backup"
	return false

func parse_json(path: String) -> Variant:
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path))!=OK: return null
	return parser.data

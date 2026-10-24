class_name VillageSave
extends RefCounted

const SAVE_PATH := "user://village.json"
var recovered := false
var error_message := ""

func validate(data: Variant, sim: VillageSimulation) -> bool:
	if not data is Dictionary: return false
	for key in ["version","money","inventory","buildings","population","xp","level","land","time","last_seen"]:
		if not data.has(key): return false
	if not data.inventory is Dictionary or not data.buildings is Array: return false
	if int(data.version)<1 or int(data.version)>2 or int(data.money)<0 or int(data.population)<0: return false
	if int(data.land)<16 or int(data.land)>40 or int(data.level)<1 or int(data.level)>300: return false
	for key in data.inventory:
		if not sim.content.products.has(key) or not (data.inventory[key] is float or data.inventory[key] is int) or float(data.inventory[key])<0: return false
	var occupied: Dictionary = {}
	var ids: Dictionary = {}
	for b in data.buildings:
		if not b is Dictionary: return false
		for key in ["id","type","x","y","upgrade","construction","progress","crop"]:
			if not b.has(key): return false
		if not sim.content.buildings.has(b.type) or ids.has(int(b.id)): return false
		ids[int(b.id)] = true
		if int(b.upgrade)<1 or int(b.upgrade)>5 or float(b.construction)<0 or float(b.progress)<0: return false
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
	for candidate in [path,path+".bak"]:
		if not FileAccess.file_exists(candidate): continue
		var parsed: Variant = parse_json(candidate)
		if not validate(parsed,sim): continue
		var defaults: Dictionary = sim.state.duplicate(true)
		defaults.merge(parsed,true)
		if not defaults.settings is Dictionary: continue
		for b in defaults.buildings:
			for key in {"animals":0,"health":100.0,"fertilized":false,"stored":0}:
				if not b.has(key): b[key] = {"animals":0,"health":100.0,"fertilized":false,"stored":0}[key]
		defaults.version = 2
		sim.state = defaults
		sim.connectivity_dirty = true
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

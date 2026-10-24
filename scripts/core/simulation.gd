class_name VillageSimulation
extends RefCounted

signal feedback(kind: String)
signal changed
signal notification(message: String)

var content: Dictionary = {}
var state: Dictionary = {}
var rng := RandomNumberGenerator.new()
var metrics: Dictionary = {}
var road_access: Dictionary = {}
var connectivity_dirty := true
var grid := VillageGrid.new()
var grid_dirty := true
var infrastructure := VillageInfrastructure.new()

func _init(seed_value: int = 42) -> void:
	rng.seed = seed_value
	for file in ["buildings", "crops", "livestock", "products", "recipes", "quests", "levels", "technologies", "events", "balance"]:
		content[file] = JSON.parse_string(FileAccess.get_file_as_string("res://data/%s.json" % file))
	new_game()

func new_game() -> void:
	state = {"version":3,"money":int(content.balance.starting_money),"inventory":content.balance.starting_inventory.duplicate(true),"buildings":[],"next_id":1,"population":8,"happiness":60.0,"xp":0,"level":1,"land":16,"time":0.0,"day_accum":0.0,"event_accum":0.0,"event":{},"event_history":{},"research":[],"quests":{},"counters":{},"achievements":[],"settings":{"language":"id","master":1.0,"music":0.35,"sfx":0.6,"ambient":0.3,"reduced_motion":false},"last_seen":int(Time.get_unix_time_from_system()),"profit":0,"prestige":0,"offline_seconds":0}
	for cell in [Vector2i(5,8),Vector2i(6,8),Vector2i(7,8),Vector2i(8,8),Vector2i(9,8),Vector2i(10,8),Vector2i(11,8)]:
		_add_building("road",cell,true)
	_add_building("bamboo",Vector2i(7,7),true)
	_add_building("bamboo",Vector2i(9,7),true)
	_add_building("rice_field",Vector2i(8,9),true)
	_add_building("hall",Vector2i(4,6),true)
	recompute()

func grid_to_iso(cell: Vector2) -> Vector2:
	return Vector2((cell.x-cell.y)*48.0,(cell.x+cell.y)*24.0)

func iso_to_grid(pos: Vector2) -> Vector2i:
	return Vector2i(floori(pos.x/96.0+pos.y/48.0+0.5),floori(pos.y/48.0-pos.x/96.0+0.5))

func terrain(cell: Vector2i) -> String:
	if cell.x < 0 or cell.y < 0 or cell.x >= int(content.balance.map_size) or cell.y >= int(content.balance.map_size):
		return "outside"
	if cell.x > 20 and absi(cell.y - (27 + int(sin(cell.x*0.3)*2))) <= 1:
		return "water"
	return "grass"

func building_at(cell: Vector2i) -> Dictionary:
	if grid_dirty:
		grid.rebuild(state.buildings,content.buildings)
		grid_dirty = false
	return grid.at(cell)

func placement_error(type: String, cell: Vector2i) -> String:
	if not content.buildings.has(type): return "Bangunan tidak dikenal"
	var d: Dictionary = content.buildings[type]
	if int(d.level) > int(state.level): return "Perlu level %d" % int(d.level)
	for x in range(int(d.footprint[0])):
		for y in range(int(d.footprint[1])):
			var p := cell+Vector2i(x,y)
			if p.x < 0 or p.y < 0 or p.x >= int(state.land) or p.y >= int(state.land): return "Di luar wilayah · perluas tanah"
			if terrain(p) != "grass" and not (type == "bridge" and terrain(p) == "water"): return "Medan tidak sesuai"
			if not building_at(p).is_empty(): return "Lahan sudah terisi"
	if not can_pay(int(d.price),d.resources): return "Rupiah / material tidak cukup"
	return ""

func can_pay(money: int, resources: Dictionary = {}) -> bool:
	if money < 0 or int(state.money) < money: return false
	for key in resources:
		if int(resources[key]) < 0 or int(state.inventory.get(key,0)) < int(resources[key]): return false
	return true

func pay(money: int, resources: Dictionary = {}) -> bool:
	if not can_pay(money,resources): return false
	state.money = int(state.money)-money
	for key in resources: state.inventory[key] = int(state.inventory.get(key,0))-int(resources[key])
	return true

func record(kind: String, target: String, amount: int) -> void:
	var key := kind+":"+target
	state.counters[key] = int(state.counters.get(key,0))+amount

func _add_building(type: String, cell: Vector2i, complete: bool = false) -> Dictionary:
	var b := {"id":int(state.next_id),"type":type,"x":cell.x,"y":cell.y,"upgrade":1,"construction":0.0 if complete else float(content.buildings[type].duration),"progress":0.0,"crop":"EMPTY","animals":0,"health":100.0,"fertilized":false,"stored":0,"moisture":100.0}
	state.next_id = int(state.next_id)+1
	state.buildings.append(b)
	grid_dirty = true
	record("build",type,1)
	connectivity_dirty = true
	return b

func build(type: String, cell: Vector2i) -> bool:
	var error := placement_error(type,cell)
	if not error.is_empty():
		notification.emit(error)
		return false
	var d: Dictionary = content.buildings[type]
	if not pay(int(d.price),d.resources): return false
	_add_building(type,cell)
	feedback.emit("construction")
	add_xp(25)
	recompute()
	changed.emit()
	return true

func add_xp(amount: int) -> void:
	state.xp = int(state.xp)+amount
	var old := int(state.level)
	state.level = 1
	for d in content.levels:
		if int(state.xp) >= int(d.xp): state.level = int(d.level)
	if int(state.level) > old:
		feedback.emit("levelup")
		notification.emit("Naik level %d!" % int(state.level))

func plant(b: Dictionary, fertilize: bool = false) -> bool:
	if not content.crops.has(b.get("type","")) or float(b.construction)>0 or b.crop not in ["EMPTY","HARVESTED"]: return false
	var cost := {"seed":1}
	if fertilize: cost.fertilizer = 1
	if not pay(0,cost): return false
	b.crop = "PLANTED"
	b.progress = 0.0
	b.fertilized = fertilize
	feedback.emit("plant")
	changed.emit()
	return true

func harvest(b: Dictionary) -> bool:
	if b.get("crop","") != "READY": return false
	var crop: Dictionary = content.crops[b.type]
	var amount := int(float(crop.yield)*(1.0+bonus("yield"))*(1.5 if b.fertilized else 1.0)*int(b.upgrade))
	if not fits({crop.product:amount}): return false
	give({crop.product:amount})
	b.crop = "HARVESTED"
	b.progress = 0.0
	record("harvest",crop.product,amount)
	add_xp(amount*3)
	feedback.emit("harvest")
	notification.emit("Panen +%d %s" % [amount,crop.product])
	changed.emit()
	return true

func acquire_animal(b: Dictionary) -> bool:
	if not content.livestock.has(b.type) or float(b.construction)>0: return false
	var d: Dictionary = content.livestock[b.type]
	if int(b.animals) >= int(d.capacity)*int(b.upgrade) or not pay(int(d.animal_cost)): return false
	b.animals = int(b.animals)+1
	return true

func collect(b: Dictionary) -> bool:
	if int(b.get("stored",0)) <= 0 or not content.livestock.has(b.type): return false
	var product: String = content.livestock[b.type].product
	var goods := {product:int(b.stored)}
	if not fits(goods): return false
	give(goods)
	record("produce",product,int(b.stored))
	b.stored = 0
	add_xp(15)
	return true

func upgrade(b: Dictionary) -> bool:
	var d: Dictionary = content.buildings[b.type]
	if int(b.upgrade) >= int(d.upgrade_levels) or float(b.construction)>0 or not pay(int(d.price)*int(b.upgrade),{"wood":int(b.upgrade)*2}): return false
	b.upgrade = int(b.upgrade)+1
	add_xp(50)
	recompute()
	return true

func demolish(b: Dictionary) -> bool:
	if not state.buildings.has(b) or b.type == "hall": return false
	state.money = int(state.money)+int(float(content.buildings[b.type].price)*0.35)
	state.buildings.erase(b)
	grid_dirty = true
	connectivity_dirty = true
	recompute()
	return true

func storage_capacity() -> int:
	var total := int(content.balance.storage)
	for b in state.buildings:
		if float(b.construction)<=0: total += int(content.buildings[b.type].storage)*int(b.upgrade)
	return total

func fits(goods: Dictionary, consumed: Dictionary = {}) -> bool:
	var total := 0
	for value in state.inventory.values(): total += int(value)
	for value in consumed.values(): total -= int(value)
	for value in goods.values(): total += int(value)
	return total <= storage_capacity()

func give(goods: Dictionary) -> void:
	for key in goods: state.inventory[key] = int(state.inventory.get(key,0))+int(goods[key])

func bonus(effect: String) -> float:
	var total := 0.0
	for id in state.research:
		if content.technologies[id].effect == effect: total += float(content.technologies[id].bonus)
	return total

func price(product: String) -> int:
	var scarcity := clampf(1.15-float(state.inventory.get(product,0))/500.0,0.75,1.2)
	var event_bonus := event_multiplier("price")
	return maxi(1,int(float(content.products[product].price)*scarcity*(1.0+bonus("price"))*event_bonus))

func trade(product: String, amount: int, buy: bool = false) -> bool:
	if amount <= 0 or not content.products.has(product): return false
	if buy:
		var cost := int(ceil(price(product)*float(content.balance.trade_buy_multiplier)))*amount
		if not fits({product:amount}) or not pay(cost): return false
		give({product:amount})
	else:
		if not pay(0,{product:amount}): return false
		var earnings := price(product)*amount
		state.money = int(state.money)+earnings
		state.profit = int(state.profit)+earnings
		record("sell",product,amount)
		add_xp(amount)
	feedback.emit("purchase")
	changed.emit()
	return true

func research(id: String) -> bool:
	if not content.technologies.has(id) or id in state.research: return false
	var d: Dictionary = content.technologies[id]
	if int(state.level)<int(d.level): return false
	for dep in d.dependencies:
		if dep not in state.research: return false
	if not pay(int(d.price),d.resources): return false
	state.research.append(id)
	record("research",id,1)
	add_xp(100)
	return true

func expand() -> bool:
	if int(state.land)>=40 or not pay(int(state.land)*300,{"wood":5}): return false
	state.land = mini(40,int(state.land)+4)
	record("expand","any",1)
	add_xp(100)
	return true

func recovery() -> bool:
	# Labor contract costs simulation time and restores a small, playable reserve.
	if int(state.money)>=800: return false
	state.money = int(state.money)+500
	if fits({"seed":5}): give({"seed":5})
	tick(30.0)
	return true

func refresh_connectivity() -> void:
	road_access.clear()
	var roads: Dictionary = {}
	var roots: Array[Vector2i] = []
	for b in state.buildings:
		if float(b.construction)>0: continue
		if b.type in ["road","asphalt","highway","bridge"]: roads[Vector2i(int(b.x),int(b.y))] = true
		if b.type == "hall":
			for dx in range(-1,3):
				for dy in range(-1,3):
					if (dx in [-1,2]) and (dy in [-1,2]): continue
					roots.append(Vector2i(int(b.x)+dx,int(b.y)+dy))
	var queue: Array[Vector2i] = []
	for p in roots:
		if roads.has(p): queue.append(p)
	var index := 0
	while index < queue.size():
		var p := queue[index]
		index += 1
		if road_access.has(p): continue
		road_access[p] = true
		for delta in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			if roads.has(p+delta) and not road_access.has(p+delta): queue.append(p+delta)
	connectivity_dirty = false

func connected(b: Dictionary) -> bool:
	if connectivity_dirty: refresh_connectivity()
	if not content.buildings[b.type].road_required or b.type == "hall": return true
	var size: Array = content.buildings[b.type].footprint
	for x in range(-1,int(size[0])+1):
		for y in range(-1,int(size[1])+1):
			if x >= 0 and x < int(size[0]) and y >= 0 and y < int(size[1]): continue
			if (x==-1 or x==int(size[0])) and (y==-1 or y==int(size[1])): continue
			if road_access.has(Vector2i(int(b.x)+x,int(b.y)+y)): return true
	return false

func recompute() -> void:
	var housing := 0
	var jobs := 0
	var happiness := 45.0+bonus("happiness")*100.0
	var services := {"health":30,"education":20,"security":30,"water":0,"power":0}
	var maintenance := 0
	var active_ids: Dictionary = {}
	for candidate in state.buildings:
		if float(candidate.construction)<=0 and connected(candidate): active_ids[int(candidate.id)] = true
	infrastructure.rebuild(state.buildings,active_ids)
	var residential_services := {"health":0.0,"education":0.0,"security":0.0,"happiness":0.0}
	for b in state.buildings:
		if float(b.construction)>0 or not connected(b): continue
		var d: Dictionary = content.buildings[b.type]
		housing += int(d.capacity)*int(b.upgrade)
		if int(d.capacity)>0:
			for kind in residential_services:
				residential_services[kind] += float(infrastructure.coverage(Vector2i(int(b.x),int(b.y)),kind))*int(d.capacity)*int(b.upgrade)
		jobs += int(d.jobs)*int(b.upgrade)
		happiness += float(d.happiness)*minf(2.0,float(b.upgrade))
		maintenance += int(d.maintenance)*int(b.upgrade)
		if b.type in ["clinic","hospital"]: services.health += 25*int(b.upgrade)
		if b.type in ["school","library"]: services.education += 25*int(b.upgrade)
		if b.type in ["police","fire"]: services.security += 25*int(b.upgrade)
		if b.type == "water": services.water += 50*int(b.upgrade)
		if b.type == "power": services.power += 50*int(b.upgrade)
	if int(state.inventory.get("rice",0))>0: happiness += 15
	else: happiness -= 15
	for kind in ["health","education","security"]:
		services[kind] = {"health":30,"education":20,"security":30}[kind]+int(float(residential_services[kind])/maxf(1.0,housing))
	happiness += float(residential_services.happiness)/maxf(1.0,housing)
	var workers := mini(int(float(state.population)*0.6),jobs)
	happiness += minf(10.0,float(workers))
	state.happiness = clampf(happiness,10.0,100.0)
	metrics = {"housing":housing,"jobs":jobs,"workers":workers,"maintenance":maintenance,"health":mini(100,services.health),"education":mini(100,services.education),"security":mini(100,services.security),"water":services.water,"power":services.power,"efficiency":clampf(float(workers)/maxf(1.0,jobs),0.25,1.0)}
	update_achievements()

func tick(seconds: float) -> void:
	if seconds<=0: return
	var remaining := seconds
	while remaining > 0:
		var step := minf(1.0,remaining)
		remaining -= step
		_step(step)
	changed.emit()

func _step(dt: float) -> void:
	state.time = float(state.time)+dt
	state.day_accum = float(state.day_accum)+dt
	state.event_accum = float(state.event_accum)+dt
	if not state.event.is_empty() and float(state.time)>=float(state.event.until): state.event = {}
	if float(state.event_accum)>=float(content.balance.event_interval):
		state.event_accum = 0.0
		choose_event()
	for b in state.buildings:
		if float(b.construction)>0:
			b.construction = maxf(0,float(b.construction)-dt)
			if float(b.construction)<=0: connectivity_dirty = true
			continue
		if not connected(b): continue
		var speed := (1.0+bonus("growth"))*event_multiplier("growth")
		if content.crops.has(b.type) and b.crop in ["PLANTED","GROWING"]:
			if event_multiplier("growth")>1.0 or infrastructure.coverage(Vector2i(int(b.x),int(b.y)),"water")>0: b.moisture = minf(100.0,float(b.get("moisture",100.0))+dt*2.0)
			b.moisture = maxf(0.0,float(b.get("moisture",100.0))-dt*(1.5 if event_multiplier("growth")<1.0 else 0.3))
			b.progress = float(b.progress)+dt*speed*(1.15 if infrastructure.coverage(Vector2i(int(b.x),int(b.y)),"water")>0 else 1.0)*(1.0 if float(b.moisture)>0 else 0.0)
			b.crop = "GROWING"
			if float(b.progress)>=float(content.crops[b.type].seconds): b.crop = "READY"
		elif content.recipes.has(b.type):
			var recipe: Dictionary = content.recipes[b.type]
			b.progress = minf(float(recipe.seconds),float(b.progress)+dt*float(metrics.get("efficiency",0.25))*int(b.upgrade)*(1.0+bonus("production"))*event_multiplier("production")*(1.2 if infrastructure.coverage(Vector2i(int(b.x),int(b.y)),"power")>0 else 1.0))
			if float(b.progress)>=float(recipe.seconds) and fits(recipe.output,recipe.input) and pay(0,recipe.input):
				give(recipe.output)
				for product in recipe.output: record("produce",product,int(recipe.output[product]))
				b.progress = 0.0
				add_xp(10)
		elif content.livestock.has(b.type) and int(b.animals)>0:
			var animal: Dictionary = content.livestock[b.type]
			b.progress = minf(float(animal.seconds),float(b.progress)+dt*event_multiplier("production"))
			if float(b.progress)>=float(animal.seconds) and int(b.stored)<100:
				if pay(0,{"feed":int(animal.feed)}):
					b.stored = mini(100,int(b.stored)+maxi(1,int(float(animal.yield)*int(b.animals)*float(b.health)/100.0)))
					b.health = minf(100,float(b.health)+10)
					b.progress = 0.0
				else: b.health = maxf(20,float(b.health)-dt)
	if float(state.day_accum)>=float(content.balance.daily_seconds):
		state.day_accum -= float(content.balance.daily_seconds)
		recompute()
		var food := maxi(1,int(ceil(float(state.population)*float(content.balance.food_per_resident))))
		var fed := pay(0,{"rice":food})
		var net := int(metrics.workers)*int(content.balance.tax_per_worker)-int(metrics.maintenance)
		state.money = maxi(0,int(state.money)+net)
		state.profit = int(state.profit)+net
		if fed and float(state.happiness)>=55: state.population = mini(int(metrics.housing),int(state.population)+maxi(1,int(state.population)/10))
		elif not fed: state.population = maxi(2,int(state.population)-1)
		record("days","any",1)
	recompute()

func event_multiplier(effect: String) -> float:
	if not state.event.is_empty() and state.event.get("effect","")==effect: return float(state.event.multiplier)
	return 1.0

func choose_event() -> void:
	var candidates: Array = []
	var total := 0
	for e in content.events:
		if int(state.level)<int(e.level) or float(state.time)-float(state.event_history.get(e.id,-10000))<float(e.cooldown): continue
		candidates.append(e)
		total += int(e.weight)
	if total==0: return
	var roll := rng.randi_range(1,total)
	for e in candidates:
		roll -= int(e.weight)
		if roll<=0:
			state.event = e.duplicate(true)
			state.event.until = float(state.time)+float(e.duration)
			state.event_history[e.id] = state.time
			notification.emit(e.name)
			return

func quest_progress(q: Dictionary) -> Array:
	var values: Array = []
	for objective in q.objectives:
		var value := int(state.counters.get(objective.kind+":"+objective.target,0))
		if objective.kind=="level": value = int(state.level)
		if objective.kind=="profit": value = int(state.profit)
		if objective.kind=="population": value = int(state.population)
		if objective.kind=="happiness": value = int(state.happiness)
		values.append(mini(value,int(objective.count)))
	return values

func quest_available(q: Dictionary) -> bool:
	for dep in q.prerequisites:
		if not state.quests.get(dep,false): return false
	return true

func quest_ready(q: Dictionary) -> bool:
	if state.quests.get(q.id,false) or not quest_available(q): return false
	var values := quest_progress(q)
	for i in q.objectives.size():
		if int(values[i])<int(q.objectives[i].count): return false
	return true

func claim_quest(id: String) -> bool:
	for q in content.quests:
		if q.id!=id or not quest_ready(q): continue
		state.quests[id] = true
		state.money = int(state.money)+int(q.rewards.money)
		add_xp(int(q.rewards.xp))
		feedback.emit("quest")
		notification.emit("Misi selesai · +Rp %d" % int(q.rewards.money))
		return true
	return false

func repeatable() -> Dictionary:
	var cycle := int(state.counters.get("contract:claimed",0))
	return {"id":"contract_%d"%cycle,"name":"Kontrak pasar #%d"%(cycle+1),"amount":10+mini(90,cycle*2),"product":["paddy","corn","rice"][cycle%3],"reward":500+cycle*75}

func claim_contract() -> bool:
	var d := repeatable()
	if not pay(0,{d.product:int(d.amount)}): return false
	state.money = int(state.money)+int(d.reward)
	record("contract","claimed",1)
	add_xp(100)
	return true

func prestige() -> bool:
	if int(state.level)<250: return false
	var count := int(state.prestige)+1
	var settings: Dictionary = state.settings.duplicate(true)
	new_game()
	state.prestige = count
	state.settings = settings
	state.money = int(state.money)+count*5000
	return true

func update_achievements() -> void:
	var conditions := {"First Harvest":int(state.counters.get("harvest:paddy",0))>0,"First Business":int(state.counters.get("build:warung",0))>0,"100 Residents":int(state.population)>=100,"First Factory":int(state.counters.get("build:mill",0))>0,"Millionaire Village":int(state.money)>=1000000,"Happy Village":float(state.happiness)>=90,"Industrial Leader":int(state.counters.get("build:industrial",0))>0,"Metropolitan Founder":int(state.level)>=221}
	for key in conditions:
		if conditions[key] and key not in state.achievements:
			state.achievements.append(key)
			notification.emit("Prestasi · "+key)

func water_field(b: Dictionary) -> bool:
	if not content.crops.has(b.get("type","")) or not pay(5): return false
	b.moisture = 100.0
	return true

extends SceneTree

var checks := 0
var failures := 0
var sim: VillageSimulation

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: "+description)

func _initialize() -> void:
	sim = VillageSimulation.new(123)
	world_tests()
	economy_tests()
	farm_tests()
	population_tests()
	infrastructure_tests()
	progression_tests()
	persistence_tests()
	malformed_save_tests()
	ads_tests()
	long_simulation()
	print("TEST RESULT: %d checks, %d failures"%[checks,failures])
	quit(1 if failures else 0)

func fresh() -> void:
	sim.new_game()

func world_tests() -> void:
	for x in range(40):
		for y in range(40):
			check(sim.iso_to_grid(sim.grid_to_iso(Vector2(x,y)))==Vector2i(x,y),"grid round trip")
	check(not sim.placement_error("bamboo",Vector2i(7,7)).is_empty(),"occupied")
	check(not sim.placement_error("rice_field",Vector2i(15,15)).is_empty(),"footprint boundary")
	check(not sim.placement_error("bamboo",Vector2i(-1,3)).is_empty(),"negative boundary")
	check(sim.build("road",Vector2i(12,8)),"road build")
	var road := sim.building_at(Vector2i(12,8))
	sim.tick(2)
	check(sim.connected(road),"road connectivity")
	check(sim.build("bamboo",Vector2i(12,7)),"house build")
	sim.tick(4)
	check(sim.connected(sim.building_at(Vector2i(12,7))),"house adjacent to connected road")
	check(sim.build("bamboo",Vector2i(1,1)),"isolated house placement permitted")
	sim.tick(4)
	check(not sim.connected(sim.building_at(Vector2i(1,1))),"isolated house inactive")
	check(not sim.demolish(sim.building_at(Vector2i(4,6))),"hall protected")

func economy_tests() -> void:
	fresh()
	var cash := int(sim.state.money)
	check(not sim.pay(cash+1),"insufficient cash")
	check(int(sim.state.money)==cash,"failed payment atomic")
	check(not sim.pay(0,{"wood":999}),"insufficient resource")
	check(not sim.pay(-1),"negative payment rejected")
	check(not sim.trade("rice",-4),"negative trade rejected")
	check(not sim.trade("rice",999),"oversell rejected")
	check(sim.trade("rice",5),"sale")
	check(int(sim.state.inventory.rice)==45,"sale removes goods")
	check(int(sim.state.money)>cash,"sale adds money")
	check(sim.trade("seed",5,true),"buy seeds")
	check(int(sim.state.inventory.seed)==45,"purchase adds goods")
	var mill := sim._add_building("mill",Vector2i(10,9),true)
	sim.give({"paddy":12})
	sim.tick(180)
	check(int(sim.state.counters.get("produce:rice",0))>0,"mill converts paddy")
	check(int(sim.state.inventory.paddy)<12,"mill consumes input")
	check(float(mill.progress)>=0,"production progress nonnegative")
	sim.state.inventory = {"rice":sim.storage_capacity()}
	check(not sim.trade("seed",5,true),"warehouse cap")
	check(not sim.fits({"wood":1}),"capacity protects output")

func farm_tests() -> void:
	fresh()
	var field := sim.building_at(Vector2i(8,9))
	check(sim.plant(field),"plant seeds")
	check(int(sim.state.inventory.seed)==39,"seed cost")
	check(not sim.plant(field),"no duplicate planting")
	sim.tick(25)
	check(field.crop=="READY","crop grows")
	check(sim.harvest(field),"harvest")
	check(int(sim.state.inventory.paddy)==8,"yield")
	check(not sim.harvest(field),"duplicate harvest blocked")
	check(sim.plant(field,true),"fertilizer planting")
	sim.tick(25)
	check(sim.harvest(field),"fertilized harvest")
	check(int(sim.state.inventory.paddy)==20,"fertilizer bonus")
	var animals := sim._add_building("chicken",Vector2i(10,9),true)
	check(sim.acquire_animal(animals),"animal purchase")
	sim.tick(40)
	check(int(animals.stored)>0,"livestock production")
	check(sim.collect(animals),"collect animal product")
	check(not sim.collect(animals),"no duplicate collection")

func population_tests() -> void:
	fresh()
	check(int(sim.metrics.housing)==12,"housing")
	check(int(sim.metrics.workers)<=int(sim.metrics.jobs),"jobs bounds")
	sim.tick(120)
	check(int(sim.state.population)>8,"migration")
	check(int(sim.state.population)<=int(sim.metrics.housing),"capacity bounds")
	check(int(sim.state.inventory.rice)<50,"food consumed")
	sim.state.inventory.rice = 0
	sim.recompute()
	var happiness := float(sim.state.happiness)
	sim.give({"rice":10})
	sim.recompute()
	check(float(sim.state.happiness)>happiness,"food affects happiness")

func infrastructure_tests() -> void:
	fresh()
	sim._add_building("water",Vector2i(10,9),true)
	sim._add_building("school",Vector2i(13,7),true)
	sim.recompute()
	check(sim.infrastructure.coverage(Vector2i(8,9),"water")>0,"water coverage near source")
	check(sim.infrastructure.coverage(Vector2i(35,35),"water")==0,"water radius bounded")
	check(sim.infrastructure.coverage(Vector2i(7,7),"education")==0,"isolated service inactive")
	sim._add_building("road",Vector2i(12,8),true)
	sim.recompute()
	check(sim.infrastructure.coverage(Vector2i(7,7),"education")>0,"connected service coverage")
	check(int(sim.metrics.education)>20,"education affects residents")

func progression_tests() -> void:
	fresh()
	check(sim.claim_quest("q01"),"first quest")
	var cash := int(sim.state.money)
	check(not sim.claim_quest("q01"),"duplicate quest blocked")
	check(int(sim.state.money)==cash,"no duplicate quest reward")
	check(not sim.claim_quest("q05"),"prerequisites")
	check(sim.claim_quest("q02"),"second quest")
	check(sim.research("seeds"),"research")
	check(not sim.research("seeds"),"duplicate research blocked")
	check(sim.bonus("yield")>0,"research effect")
	check(not sim.research("renewables"),"technology dependencies")
	sim.add_xp(400000)
	check(int(sim.state.level)>=250,"long progression")
	check(sim.expand(),"map expansion")
	check(int(sim.state.land)==20,"expanded bounds")
	check(sim.prestige(),"prestige")
	check(int(sim.state.prestige)==1 and int(sim.state.level)==1,"prestige resets progression")
	check(sim.content.quests.size()>=20,"quest count")

func persistence_tests() -> void:
	fresh()
	var saves := VillageSave.new()
	var path := "user://test_village.json"
	for suffix in ["",".bak",".tmp"]:
		if FileAccess.file_exists(path+suffix): DirAccess.remove_absolute(path+suffix)
	check(saves.save_game(sim,path),"save")
	var money := int(sim.state.money)
	sim.state.money = 123
	check(saves.load_game(sim,path,false),"load")
	check(int(sim.state.money)==money,"roundtrip cash")
	check(saves.save_game(sim,path),"second save backup")
	var file := FileAccess.open(path,FileAccess.WRITE)
	file.store_string("{broken")
	file.close()
	check(saves.load_game(sim,path,false),"backup recovery")
	check(saves.recovered,"recovery reported")
	sim.state.version = 1
	check(saves.save_game(sim,path),"v1 write")
	check(saves.load_game(sim,path,false) and int(sim.state.version)==3,"schema migration")
	sim.demolish(sim.building_at(Vector2i(5,8)))
	sim.state.version = 2
	check(saves.save_game(sim,path),"v2 migration fixture")
	check(saves.load_game(sim,path,false),"v2 entrance migration")
	check(sim.connected(sim.building_at(Vector2i(8,9))),"v2 access preserved on upgrade")
	var invalid: Dictionary = sim.state.duplicate(true)
	invalid.inventory.rice = -1
	check(not saves.validate(invalid,sim),"negative inventory save rejected")
	invalid = sim.state.duplicate(true)
	invalid.buildings.append(invalid.buildings[0].duplicate(true))
	check(not saves.validate(invalid,sim),"overlap duplicate save rejected")
	var field := sim.building_at(Vector2i(8,9))
	sim.plant(field)
	sim.state.last_seen = int(Time.get_unix_time_from_system())-100000
	# Write fixture directly because normal saving intentionally checkpoints wall time.
	file = FileAccess.open(path,FileAccess.WRITE)
	file.store_string(JSON.stringify(sim.state))
	file.close()
	check(saves.load_game(sim,path),"offline load")
	check(int(sim.state.offline_seconds)==int(sim.content.balance.offline_cap),"offline cap")
	check(sim.building_at(Vector2i(8,9)).crop=="READY","offline crop growth")
	sim.state.last_seen = int(Time.get_unix_time_from_system())+86400
	file = FileAccess.open(path,FileAccess.WRITE)
	file.store_string(JSON.stringify(sim.state))
	file.close()
	check(saves.load_game(sim,path) and int(sim.state.offline_seconds)==0,"clock rollback safe")
	for suffix in ["",".bak",".tmp"]:
		if FileAccess.file_exists(path+suffix): DirAccess.remove_absolute(path+suffix)

func malformed_save_tests() -> void:
	fresh()
	var saves := VillageSave.new()
	for key in ["money","population","level","last_seen","inventory","buildings","research","quests","settings","counters","event"]:
		var bad: Dictionary = sim.state.duplicate(true)
		bad[key] = "malformed"
		check(not saves.validate(bad,sim),"malformed field rejected: "+key)
	for bad_value in [-1.0,0.5,"5",null]:
		var bad: Dictionary = sim.state.duplicate(true)
		bad.inventory.rice = bad_value
		check(not saves.validate(bad,sim),"invalid stock type rejected")
	var bad: Dictionary = sim.state.duplicate(true)
	bad.buildings[0].x = "oops"
	check(not saves.validate(bad,sim),"malformed building coordinate rejected")
	bad = sim.state.duplicate(true)
	bad.research = ["unregistered"]
	check(not saves.validate(bad,sim),"unknown technology rejected")
	var path := "user://test_interrupt.json"
	var file := FileAccess.open(path+".tmp",FileAccess.WRITE)
	file.store_string(JSON.stringify(sim.state))
	file.close()
	check(saves.load_game(sim,path,false) and saves.recovered,"interrupted first save recovered")
	DirAccess.remove_absolute(path+".tmp")
	var field := sim.building_at(Vector2i(8,9))
	check(sim.plant(field),"dry field planting")
	field.moisture = 0.0
	sim.tick(5)
	check(float(field.progress)==0,"dry crops pause")
	check(sim.water_field(field),"manual watering")
	sim.tick(2)
	check(float(field.progress)>0,"water resumes crop growth")
	check(sim.building_at(Vector2i(5,8)).type=="road","hall access road")
	sim.demolish(sim.building_at(Vector2i(5,8)))
	check(not sim.connected(field),"removing hall road disconnects farms")
	check(sim.building_at(Vector2i(5,8)).is_empty(),"occupancy index invalidates")
	fresh()
	sim.state.level = 4
	var mill := sim._add_building("feed_mill",Vector2i(10,9),true)
	var initial_feed := int(sim.state.inventory.feed)
	sim.tick(110)
	check(int(sim.state.inventory.feed)>initial_feed,"corn-to-feed chain")
	check(sim.grid.chunks.size()>0,"chunk index populated")
	var walk_path := VillagePathfinder.find_path(Vector2i(5,8),Vector2i(11,8),sim.road_access)
	check(walk_path.size()==7,"road path length")
	check(VillagePathfinder.find_path(Vector2i(0,0),Vector2i(11,8),sim.road_access).is_empty(),"unwalkable endpoint rejected")

func ads_tests() -> void:
	var ads := VillageAds.new()
	check(ads.request_reward("coins").is_empty(),"offline ads unavailable")
	check(not ads.complete_reward("fake",true),"fake ad callback blocked")
	ads.native_ready = true
	ads.consent = true
	var token := ads.request_reward("coins")
	check(not ads.complete_reward(token,false),"unverified reward blocked")
	check(ads.complete_reward(token,true),"verified reward")
	check(not ads.complete_reward(token,true),"duplicate ad reward blocked")
	check(not ads.can_interstitial(100,false),"critical gameplay protected")

func long_simulation() -> void:
	fresh()
	var start := Time.get_ticks_msec()
	for day in range(60):
		var field := sim.building_at(Vector2i(8,9))
		if field.crop in ["EMPTY","HARVESTED"]: sim.plant(field)
		sim.tick(120)
		if field.crop=="READY": sim.harvest(field)
		if int(sim.state.inventory.get("paddy",0))>=5: sim.trade("paddy",5)
		if int(sim.state.money)<800: sim.recovery()
		for value in sim.state.inventory.values(): check(int(value)>=0,"60 day inventory nonnegative")
		check(int(sim.state.money)>=0,"60 day money nonnegative")
		check(int(sim.state.population)>=2,"recoverable population")
	print("60-day simulation: %d ms"%(Time.get_ticks_msec()-start))

class_name VillageWorld
extends Node2D

signal tile_clicked(cell: Vector2i)
var sim: VillageSimulation
var pan := Vector2(640,40)
var zoom_factor := 0.85
var target_zoom := 0.85
var hover := Vector2i(-1,-1)
var placement := ""
var overlay := false
var overlay_kind := "road"
var dragging := false
var moved := false
var press := Vector2.ZERO
var fingers: Dictionary = {}
var clock := 0.0
var font := ThemeDB.fallback_font
var terrain_chunks: Array[Node2D] = []
var cached_land := -1
var route_hash := 0
var routes: Array = []

func _ready() -> void:
	for x in range(5):
		for y in range(5):
			var node := VillageTerrainChunk.new()
			node.sim = sim
			node.chunk = Vector2i(x,y)
			node.show_behind_parent = true
			add_child(node)
			terrain_chunks.append(node)

func _process(dt: float) -> void:
	clock += dt
	zoom_factor = lerpf(zoom_factor,target_zoom,minf(1,dt*12))
	for chunk in terrain_chunks:
		chunk.position = pan
		chunk.scale = Vector2.ONE*zoom_factor
		if cached_land!=int(sim.state.land): chunk.queue_redraw()
	cached_land = int(sim.state.land)
	var current_hash := hash([sim.road_access,sim.state.buildings.size()])
	if current_hash!=route_hash:
		routes.clear()
		var roads: Array = sim.road_access.keys()
		for i in range(mini(12,roads.size())):
			var destinations: Array = []
			var purpose: String = ["rumah","niaga","tani","industri"][i%4]
			for b in sim.state.buildings:
				if sim.content.buildings[b.type].category==purpose: destinations.append(b)
			var destination: Vector2i = roads[(i*3+roads.size()-1)%roads.size()]
			if not destinations.is_empty():
				var target: Dictionary = destinations[i%destinations.size()]
				var best := 100000
				for cell in roads:
					var delta: Vector2i = cell-Vector2i(int(target.x),int(target.y))
					var distance := absi(delta.x)+absi(delta.y)
					if distance<best:
						best = distance
						destination = cell
			routes.append(VillagePathfinder.find_path(roads[i],destination,sim.road_access))
		route_hash = current_hash
	var night := maxf(0.0,sin(float(sim.state.time)/120.0*TAU-PI*0.5))
	modulate = Color(1.0-night*0.35,1.0-night*0.28,1.0-night*0.12)
	queue_redraw()

func world_point(p: Vector2) -> Vector2:
	return (p-pan)/zoom_factor

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouse and event.device == -1: return
	if event is InputEventMouseButton:
		if event.button_index==MOUSE_BUTTON_WHEEL_UP and event.pressed: target_zoom = clampf(target_zoom*1.12,0.3,1.7)
		if event.button_index==MOUSE_BUTTON_WHEEL_DOWN and event.pressed: target_zoom = clampf(target_zoom/1.12,0.3,1.7)
		if event.button_index==MOUSE_BUTTON_LEFT:
			if event.pressed:
				dragging = true
				moved = false
				press = event.position
			else:
				if dragging and not moved: tile_clicked.emit(sim.iso_to_grid(world_point(event.position)))
				dragging = false
	elif event is InputEventMouseMotion:
		hover = sim.iso_to_grid(world_point(event.position))
		if dragging:
			if event.position.distance_to(press)>8: moved = true
			if moved: pan += event.relative
	elif event is InputEventScreenTouch:
		if event.pressed:
			fingers[event.index] = event.position
			press = event.position
			moved = false
		else:
			if fingers.size()==1 and not moved: tile_clicked.emit(sim.iso_to_grid(world_point(event.position)))
			fingers.erase(event.index)
	elif event is InputEventScreenDrag:
		moved = true
		if fingers.size()==2:
			var keys: Array = fingers.keys()
			var other: Vector2 = fingers[keys[1] if keys[0]==event.index else keys[0]]
			var old_position: Vector2 = fingers.get(event.index,event.position-event.relative)
			var old_distance: float = old_position.distance_to(other)
			if old_distance>10: target_zoom = clampf(target_zoom*event.position.distance_to(other)/old_distance,0.3,1.7)
		else: pan += event.relative
		fingers[event.index] = event.position
	pan.x = clampf(pan.x,-2200,3200)
	pan.y = clampf(pan.y,-2200,900)

func diamond(p: Vector2, color: Color, sx: float=48.0, sy: float=24.0) -> void:
	draw_colored_polygon(PackedVector2Array([p+Vector2(0,-sy),p+Vector2(sx,0),p+Vector2(0,sy),p+Vector2(-sx,0)]),color)

func poly(points: Array, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array(points),color)

func _draw() -> void:
	if sim==null: return
	draw_set_transform(pan,0,Vector2.ONE*zoom_factor)
	var size := int(sim.content.balance.map_size)
	if overlay and overlay_kind!="road":
		for x in range(int(sim.state.land)):
			for y in range(int(sim.state.land)):
				if sim.infrastructure.coverage(Vector2i(x,y),overlay_kind)>0:
					diamond(sim.grid_to_iso(Vector2(x,y)),Color(0.2,0.8,0.85,0.24))
	var ordered: Array = sim.state.buildings.duplicate()
	ordered.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return int(a.x)+int(a.y)<int(b.x)+int(b.y))
	for i in range(85):
		var cell := Vector2i(posmod(i*7+2,38),posmod(i*13+3,38))
		if cell.x<12 and cell.y<12: continue
		if sim.terrain(cell)!="grass" or not sim.building_at(cell).is_empty(): continue
		ordered.append({"x":cell.x,"y":cell.y,"decoration":true,"palm":i%3==0})
	ordered.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return int(a.x)+int(a.y)<int(b.x)+int(b.y))
	for b in ordered:
		if not b.get("decoration",false):
			draw_building(b)
			continue
		var p := sim.grid_to_iso(Vector2(int(b.x),int(b.y)))
		draw_line(p,p-Vector2(0,38),Color("81644a"),4)
		if b.palm:
			for j in range(5):
				var angle := float(j)*TAU/5.0+0.4
				var tip := p+Vector2(cos(angle)*26,-38+sin(angle)*12)
				draw_line(p-Vector2(0,38),tip,Color("7eab56"),5)
				draw_line(tip,tip+Vector2(0,6),Color("4a854b"),3)
		else:
			for j in range(3): draw_circle(p+Vector2((j-1)*11,-35-abs(j-1)*3),15,Color("356747").lightened(j*0.03))
	if not bool(sim.state.settings.get("reduced_motion",false)):
		for i in range(mini(routes.size(),int(sim.state.population))):
			var path: Array = routes[i]
			if path.is_empty(): continue
			# Alternate purposeful trips and a brief idle at each endpoint.
			var trip := maxf(1.0,float(path.size()-1))
			var phase := fmod(clock*0.65+i*0.7,trip*2.0+2.0)
			var distance := clampf(phase if phase<=trip+1.0 else trip*2.0+1.0-phase,0.0,trip)
			var first := mini(path.size()-1,int(distance))
			var last := mini(path.size()-1,first+1)
			var cell := Vector2(path[first]).lerp(Vector2(path[last]),fmod(distance,1.0))
			var p := sim.grid_to_iso(cell)
			draw_circle(p+Vector2(0,-8),3.0,Color("ebbd8c"))
			draw_line(p+Vector2(0,-5),p+Vector2(0,2),[Color("efc369"),Color("d86f50"),Color("e7eee0")][i%3],4)

			if not sim.state.event.is_empty() and sim.state.event.id=="rain":
				for j in range(80):
					var p2 := Vector2(posmod(j*137,2000)-1000,fmod(clock*350+j*73,1300))
					draw_line(p2,p2+Vector2(-5,14),Color(0.7,0.86,0.95,0.4),1)
	if hover.x>=0 and hover.y>=0 and hover.x<size and hover.y<size:
		var p := sim.grid_to_iso(Vector2(hover))
		var valid := placement.is_empty() or sim.placement_error(placement,hover).is_empty()
		var footprint: Array = [1,1] if placement.is_empty() else sim.content.buildings[placement].footprint
		for x in range(int(footprint[0])):
			for y in range(int(footprint[1])): diamond(p+sim.grid_to_iso(Vector2(x,y)),Color(0.95,0.84,0.45,0.55) if valid else Color(0.95,0.3,0.25,0.6))

func draw_building(b: Dictionary) -> void:
	var d: Dictionary = sim.content.buildings[b.type]
	var p := sim.grid_to_iso(Vector2(float(b.x),float(b.y)))
	var category: String = d.category
	var wide := int(d.footprint[0])>1
	if category=="jalan" and b.type in ["road","asphalt","highway","bridge"]:
		diamond(p,Color("b8a082") if b.type=="road" else Color("69797b"),46,22)
		if b.type!="road": draw_line(p-Vector2(22,11),p+Vector2(22,11),Color("ead9a4"),2)
		return
	if wide: p.y += 24
	var w := 35.0 if not wide else 62.0
	var h := 36.0+float(b.upgrade)*5
	if category=="tani":
		if wide: diamond(p,Color("6b8350"),88,43)
		for row in range(4):
			for col in range(5):
				var crop_pos := p+Vector2((col-row)*12-7,(col+row)*6-18)
				var ready: bool = b.crop=="READY"
				var planted: bool = b.crop in ["READY","GROWING","PLANTED"]
				draw_line(crop_pos,crop_pos+Vector2(0,-11 if planted else -2),Color("edcb62") if ready else Color("bfd477"),3)
		if b.crop=="READY": draw_circle(p+Vector2(0,-32+sin(clock*3)*2),7,Color("ffda79"))
	elif category=="ternak":
		diamond(p,Color("c8b387"),85,42)
		for i in range(mini(int(b.animals),8)):
			var ap := p+Vector2(posmod(i*17,60)-25,posmod(i*13,30)-10)
			draw_circle(ap,6,Color("fff1c9"))
			draw_circle(ap+Vector2(4,-4),3,Color("dc7754"))
		poly([p+Vector2(-60,5),p+Vector2(-60,-22),p+Vector2(-18,-5),p+Vector2(-18,25)],Color("9c7954"))
	elif b.type=="park":
		diamond(p,Color("80aa60"),85,42)
		draw_circle(p+Vector2(0,-16),24,Color("437d50"))
		draw_line(p+Vector2(-35,10),p+Vector2(25,40),Color("e0cd95"),6)
	else:
		var colors := {"rumah":Color("e8cc99"),"niaga":Color("e9ab78"),"industri":Color("a6b4b0"),"layanan":Color("e4e4c5"),"jalan":Color("a5c8c4")}
		var wall: Color = colors.get(category,Color("e8cc99"))
		if b.type in ["apartment","condo","hotel","hospital"]: h += 70
		draw_ellipse_shadow(p,w)
		poly([p+Vector2(-w,0),p+Vector2(0,w*0.5),p+Vector2(0,w*0.5-h),p+Vector2(-w,-h)],wall.darkened(0.12))
		poly([p+Vector2(0,w*0.5),p+Vector2(w,0),p+Vector2(w,-h),p+Vector2(0,w*0.5-h)],wall)
		var roof := Color("bd6850") if category=="rumah" else Color("487b78")
		poly([p+Vector2(-w-5,-h),p+Vector2(0,-h-30),p+Vector2(w+5,-h),p+Vector2(0,-h+w*0.5)],roof)
		poly([p+Vector2(-w-5,-h),p+Vector2(0,-h-30),p+Vector2(0,-h+w*0.5)],roof.lightened(0.16))
		draw_line(p+Vector2(16,-2),p+Vector2(16,-24),Color("405b55"),12)
		for j in range(2): draw_line(p+Vector2(-w+12+j*18,-h+12),p+Vector2(-w+12+j*18,-h+24),Color("597d77"),8)
		if category=="niaga": draw_line(p+Vector2(3,-h+25),p+Vector2(w-2,-h+5),Color("f0cd77"),9)
		if category=="industri":
			draw_line(p+Vector2(25,-h-5),p+Vector2(25,-h-50),Color("929891"),12)
			if not bool(sim.state.settings.get("reduced_motion",false)):
				for i in range(3): draw_circle(p+Vector2(25+sin(clock+i)*6,-h-55-i*10-fmod(clock*6,10)),5+i*2,Color(0.9,0.9,0.85,0.3))
	if float(b.construction)>0:
		draw_line(p+Vector2(-w,-8),p+Vector2(w,-8),Color("ead681"),4)
		draw_string(font,p+Vector2(-24,-75),"%ds"%ceili(b.construction),HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("fff4cf"))
	if overlay:
		var covered: bool = sim.connected(b) if overlay_kind=="road" else sim.infrastructure.coverage(Vector2i(int(b.x),int(b.y)),overlay_kind)>0
		diamond(p,Color(0.2,0.85,0.6,0.4) if covered else Color(0.95,0.3,0.2,0.5),w+5,w*0.5+3)

func draw_ellipse_shadow(p: Vector2, width: float) -> void:
	draw_set_transform(pan+(p+Vector2(0,12))*zoom_factor,0,Vector2(zoom_factor,zoom_factor*0.45))
	draw_circle(Vector2.ZERO,width+5,Color(0.08,0.18,0.12,0.19))
	draw_set_transform(pan,0,Vector2.ONE*zoom_factor)

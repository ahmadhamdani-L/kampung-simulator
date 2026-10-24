class_name VillageTerrainChunk
extends Node2D

var sim: VillageSimulation
var chunk := Vector2i.ZERO

func diamond(p: Vector2, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([p+Vector2(0,-24),p+Vector2(48,0),p+Vector2(0,24),p+Vector2(-48,0)]),color)

func _draw() -> void:
	if sim==null: return
	var start := chunk*VillageGrid.CHUNK_SIZE
	for x in range(start.x,mini(start.x+VillageGrid.CHUNK_SIZE,40)):
		for y in range(start.y,mini(start.y+VillageGrid.CHUNK_SIZE,40)):
			var p := sim.grid_to_iso(Vector2(x,y))
			var variation := float(posmod(x*17+y*31,7))*0.009
			var color := Color(0.37+variation,0.57+variation,0.32+variation)
			if sim.terrain(Vector2i(x,y))=="water": color = Color(0.22,0.55+variation,0.64)
			if x>=int(sim.state.land) or y>=int(sim.state.land): color = color.darkened(0.42)
			diamond(p,color)
			if (x+y)%3==0 and sim.terrain(Vector2i(x,y))=="grass":
				draw_line(p+Vector2(-7,1),p+Vector2(-4,-3),color.lightened(0.1),1)
			if x==int(sim.state.land)-1 or y==int(sim.state.land)-1:
				draw_line(p+Vector2(48,0),p+Vector2(0,24),Color(0.9,0.78,0.46,0.5),2)

class_name VillageGrid
extends RefCounted

const CHUNK_SIZE := 8
var occupancy: Dictionary = {}
var chunks: Dictionary = {}

func rebuild(buildings: Array, definitions: Dictionary) -> void:
	occupancy.clear()
	chunks.clear()
	for b in buildings:
		var footprint: Array = definitions[b.type].footprint
		for x in range(int(footprint[0])):
			for y in range(int(footprint[1])):
				var cell := Vector2i(int(b.x)+x,int(b.y)+y)
				occupancy[cell] = b
		var chunk := Vector2i(int(b.x)/CHUNK_SIZE,int(b.y)/CHUNK_SIZE)
		if not chunks.has(chunk): chunks[chunk] = []
		chunks[chunk].append(b)

func at(cell: Vector2i) -> Dictionary:
	return occupancy.get(cell,{})

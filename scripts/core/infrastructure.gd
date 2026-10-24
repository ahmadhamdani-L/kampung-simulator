class_name VillageInfrastructure
extends RefCounted

const SERVICES := {
	"water":{"water":[7,50]},
	"power":{"power":[8,50]},
	"clinic":{"health":[6,25]},
	"hospital":{"health":[10,55]},
	"school":{"education":[7,25]},
	"library":{"education":[5,20]},
	"police":{"security":[8,35]},
	"fire":{"security":[7,20]},
	"park":{"happiness":[4,8]},
	"hall":{"security":[5,10]}
}
var sources: Dictionary = {}

func rebuild(buildings: Array, connected_ids: Dictionary) -> void:
	sources.clear()
	for b in buildings:
		if not connected_ids.has(int(b.id)) or not SERVICES.has(b.type): continue
		for kind in SERVICES[b.type]:
			if not sources.has(kind): sources[kind] = []
			var d: Array = SERVICES[b.type][kind]
			sources[kind].append({"cell":Vector2i(int(b.x),int(b.y)),"radius":int(d[0])+int(b.upgrade)-1,"value":int(d[1])*int(b.upgrade)})

func coverage(cell: Vector2i, kind: String) -> int:
	var total := 0
	for source in sources.get(kind,[]):
		var delta: Vector2i = cell-source.cell
		if absi(delta.x)+absi(delta.y)<=int(source.radius): total += int(source.value)
	return mini(100,total)

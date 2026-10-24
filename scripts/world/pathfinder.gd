class_name VillagePathfinder
extends RefCounted

static func find_path(start: Vector2i, goal: Vector2i, roads: Dictionary) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if not roads.has(start) or not roads.has(goal): return result
	var parents: Dictionary = {start:start}
	var queue: Array[Vector2i] = [start]
	var index := 0
	while index<queue.size():
		var cell := queue[index]
		index += 1
		if cell==goal: break
		for delta in [Vector2i.UP,Vector2i.DOWN,Vector2i.LEFT,Vector2i.RIGHT]:
			var next: Vector2i = cell+delta
			if roads.has(next) and not parents.has(next):
				parents[next] = cell
				queue.append(next)
	if not parents.has(goal): return result
	var cell := goal
	while cell!=start:
		result.push_front(cell)
		cell = parents[cell]
	result.push_front(start)
	return result

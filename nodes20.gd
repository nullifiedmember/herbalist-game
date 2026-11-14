extends Node
## Расставляет места добычи материалов (mats_db.NODES) по каждой области мира, когда она строится.

const MT = preload("res://mats_db.gd")
const WD = preload("res://world_data.gd")

var main: Node2D
var world: Node2D


func setup(m: Node2D, w: Node2D) -> void:
	main = m
	world = w
	(world.get("region_hooks") as Array).append(Callable(self, "populate"))


func _near_town(p: Vector2) -> bool:
	for tc in WD.TOWN_C.values():
		if p.distance_to(tc) < WD.TOWN_R + 60.0:
			return true
	return false


func populate(node: Node2D, r: Vector2i) -> void:
	var rect: Rect2 = WD.region_rect(r)
	var rb: int = WD.biome_of_region(r)
	if r == Vector2i.ZERO or rb < 0 or rb == WD.SEA:
		return
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = hash("nodes20/%d,%d" % [r.x, r.y])
	for k in MT.NODES.keys():
		var nd: Array = MT.NODES[k]
		var want: int = int((nd[2] as Dictionary).get(rb, 0))
		var made: int = 0
		var tries: int = 0
		while made < want and tries < want * 12:
			tries += 1
			var p: Vector2 = Vector2(rng.randf_range(rect.position.x + 50, rect.end.x - 50), rng.randf_range(rect.position.y + 60, rect.end.y - 40)).round()
			if WD.biome_at(p) != rb and not (nd[2] as Dictionary).has(WD.biome_at(p)):
				continue
			if _near_town(p) or not bool(world.call("free_at", p, 18.0, 30.0)):
				continue
			var s: Sprite2D = world.call("put", node, r, String(nd[1]), p, 0.0, 0.0, Color.WHITE, false)
			if String(k) in ["web", "clay", "peat", "sand", "black_sand", "quartz_sand", "salt"]:
				s.z_index = -6
			var n: Node2D = Node2D.new()
			n.set_script(load("res://mat_node.gd"))
			n.position = p
			node.add_child(n)
			n.call("setup", String(k), s)
			made += 1

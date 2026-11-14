extends Node
## v26: где живут бродячие коты разных окрасов.
## Деревня кошкодевочек — много котов и котят; в каждом городе по 1-3 кота; в диких краях изредка один.
## Каждый день коты другие (окрасы выпадают заново). Редкие и сказочные окрасы выпадают редко.

const DB = preload("res://cats26_db.gd")
const WD = preload("res://world_data.gd")
const CV = preload("res://cat_village.gd")

## место: [сколько котов от, до, шанс редкого окраса, шанс что кошка с котятами]
const PLACES: Dictionary = {
	"village": [6, 9, 0.06, 0.45],
	"town": [1, 3, 0.03, 0.25],
	"wild": [0, 1, 0.02, 0.2],
}
const WILD_CHANCE: float = 0.22       # в дикой области кот есть не всегда

var main: Node2D
var world: Node2D
var spawned: int = 0                  # для проверок
var rare_spawned: int = 0


func setup(m: Node2D, w: Node2D) -> void:
	main = m
	world = w
	add_to_group("stray_cats26_mgr")
	(world.get("region_hooks") as Array).append(Callable(self, "populate"))


func _place_of(r: Vector2i) -> Array:
	if r == CV.REGION:
		return ["village", CV.PLAZA, 360.0]
	for land in WD.TOWN_C:
		var c: Vector2 = WD.TOWN_C[land]
		if WD.region_of(c) == r:
			return ["village" if land == "cats" else "town", c, 420.0]
	return ["wild", WD.region_rect(r).get_center(), 800.0]


func populate(node: Node2D, r: Vector2i) -> void:
	if OS.get_cmdline_user_args().has("--nocats26"):
		return
	var rect: Rect2 = WD.region_rect(r)
	if not WD.in_world(rect.get_center()):
		return
	var biome: int = WD.biome_of_region(r)
	if biome == WD.SEA:
		return
	var pl: Array = _place_of(r)
	var kind: String = String(pl[0])
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = hash([r.x, r.y, Game.day, 2611])
	if kind == "wild" and (r == Vector2i.ZERO or rng.randf() > WILD_CHANCE):
		return
	var cfg: Array = PLACES[kind]
	var n: int = rng.randi_range(int(cfg[0]), int(cfg[1]))
	for i in range(n):
		var skin: String = DB.pick(rng, float(cfg[2]))
		var at: Vector2 = _spot(rng, pl[1] as Vector2, float(pl[2]), rect)
		if at.x < -1e8:
			continue
		var cat: Node2D = spawn(node, skin, at)
		if rng.randf() < float(cfg[3]):
			var kits: int = rng.randi_range(1, 3)
			for k in range(kits):
				# котята чаще в маму, иногда в папу — любого окраса
				var ks: String = skin if rng.randf() < 0.6 else DB.pick(rng, float(cfg[2]) * 0.5)
				var kat: Node2D = spawn(node, "kit_" + ks, at + Vector2(12 + k * 10, 6 + (k % 2) * 6))
				kat.set("mom", cat)
				kat.set("kit_off", Vector2(-14 + k * 12, 8 + (k % 2) * 5))


func spawn(node: Node, skin: String, at: Vector2) -> Node2D:
	var c: Node2D = Node2D.new()
	c.set_script(load("res://stray_cat26.gd"))
	c.set("skin", skin)
	c.set("main", main)
	c.set("home", at)
	c.position = at
	node.add_child(c)
	spawned += 1
	if DB.tier(skin) >= 2:
		rare_spawned += 1
	return c


func _spot(rng: RandomNumberGenerator, c: Vector2, rad: float, rect: Rect2) -> Vector2:
	for i in range(16):
		var a: float = rng.randf() * TAU
		var p: Vector2 = c + Vector2(cos(a), sin(a) * 0.75) * rng.randf_range(0.15, 1.0) * rad
		p.x = clampf(p.x, rect.position.x + 40.0, rect.end.x - 40.0)
		p.y = clampf(p.y, rect.position.y + 40.0, rect.end.y - 40.0)
		if not bool(main.call("is_blocked", p)) and not bool(world.call("under_crown", p)):
			return p.round()
	return Vector2(-1e9, -1e9)

extends Node
## Дикие края: звери и грибные места во всех областях, а также особые места без городов —
## поляны единорогов, пещеры со светящимися грибами, хижины отшельниц, стоянки изгоев,
## болотные лужи с камышом.

const WD = preload("res://world_data.gd")
const W = preload("res://wild_db.gd")

var main: Node2D
var world: Node2D


func setup(m: Node2D, w: Node2D) -> void:
	main = m
	world = w
	(world.get("region_hooks") as Array).append(Callable(self, "populate"))
	var tb: Dictionary = world.get("town_builders")
	for lm in WD.LANDMARKS:
		var kind: String = String(lm[2])
		if kind in ["unicorn", "cave", "hermit", "outcast"]:
			var p: Vector2 = Vector2(float(lm[0]), float(lm[1]))
			var r: Vector2i = WD.region_of(p)
			if not tb.has(r):
				tb[r] = Callable(self, "place_" + kind).bind(p)


func _put(node: Node2D, r: Vector2i, tex: String, p: Vector2, block: float = 0.0, cast: bool = true) -> Sprite2D:
	return world.call("put", node, r, tex, p, 0.0, block, Color.WHITE, cast)


## После природы — для каждой области: звери, мифические звери, грибные места, мелочи по биому
func populate(node: Node2D, r: Vector2i) -> void:
	var rng: RandomNumberGenerator = world.get("rng")
	var rect: Rect2 = WD.region_rect(r)
	var biome: int = WD.biome_of_region(r)
	if r == Vector2i.ZERO:
		return
	# особые мелочи биомов
	match biome:
		WD.SWAMP:
			# v19: окна воды с кувшинками, рогоз по берегам, кочки с клюквой, упавшие брёвна
			for i in range(14):
				var q: Vector2 = _spot(rng, rect, 80.0)
				if q.x > -1e8:
					var big: bool = i % 3 != 2
					_put(node, r, "bog_pool_a" if big else "bog_pool_b", q, 0.0, false)
					world.call("add_block", q + Vector2(0, -30 if big else -22), 52.0 if big else 34.0)
					if big:
						world.call("add_block", q + Vector2(-46, -30), 30.0)
						world.call("add_block", q + Vector2(46, -30), 30.0)
					for k in range(3):
						var side: float = -1.0 if k % 2 == 0 else 1.0
						_put(node, r, "cattails", q + Vector2(side * rng.randf_range(50, 90 if big else 60), rng.randf_range(-40, 8)), 0.0)
			for i6 in range(12):
				var qm: Vector2 = _spot(rng, rect, 24.0)
				if qm.x > -1e8:
					_put(node, r, "bog_mound", qm, 10.0)
			for i7 in range(4):
				var ql: Vector2 = _spot(rng, rect, 50.0)
				if ql.x > -1e8:
					_put(node, r, "bog_log", ql, 0.0)
					world.call("add_block", ql + Vector2(-20, -8), 16.0)
					world.call("add_block", ql + Vector2(20, -8), 16.0)
		WD.GROTTO:
			for i2 in range(2):
				var q2: Vector2 = _spot(rng, rect, 140.0)
				if q2.x > -1e8:
					_cave(node, r, q2, rng)
			for i3 in range(16):
				var q3: Vector2 = _spot(rng, rect, 30.0)
				if q3.x > -1e8:
					_put(node, r, "giant_shroom_blue" if i3 % 2 == 0 else "giant_shroom_pink", q3, 8.0)
					_glow(q3 + Vector2(0, -50), Color(0.5, 0.8, 1.0) if i3 % 2 == 0 else Color(1.0, 0.6, 0.9), 0.5)
		WD.UNICORN:
			for i4 in range(8):
				var q4: Vector2 = _spot(rng, rect, 30.0)
				if q4.x > -1e8:
					_put(node, r, "giant_shroom_pink", q4, 8.0)
					_glow(q4 + Vector2(0, -50), Color(1.0, 0.6, 0.9), 0.45)
		WD.FIELD:
			for i5 in range(10):
				var q5: Vector2 = _spot(rng, rect, 20.0)
				if q5.x > -1e8:
					_put(node, r, "hay_bale", q5, 9.0)
	# звери
	for fa in W.FAUNA.get(biome, []):
		for k2 in range(int(fa[1])):
			var ap: Vector2 = _spot(rng, rect, 10.0)
			if ap.x > -1e8:
				_animal(node, String(fa[0]), ap)
	for my in W.MYTHIC_SPAWN.get(biome, []):
		if rng.randf() < float(my[1]):
			var mp: Vector2 = _spot(rng, rect, 10.0)
			if mp.x > -1e8:
				_animal(node, String(my[0]), mp)
	# места диких трав: в каждом биоме свои травы, где-то их больше, где-то меньше
	var hopts: Array = preload("res://herbs_db.gd").wild_for(biome)
	if not hopts.is_empty():
		var hs: Array = HERB_SPOTS.get(biome, [12, 0.45])
		var wm: Material = main.call("wind_mat", 1.0)
		for kh in range(int(hs[0])):
			var hp: Vector2 = _herb_spot(rng, rect)
			if hp.x > -1e8:
				# на стыке биомов растут травы того края, где стоит место
				var lo: Array = preload("res://herbs_db.gd").wild_for(WD.biome_at(hp))
				var hn: Node2D = Node2D.new()
				hn.set_script(load("res://herb_spot.gd"))
				node.add_child(hn)
				hn.call("setup", hp, lo if not lo.is_empty() else hopts, float(hs[1]), wm)
		# у дома (если он не на родном лугу) — свой травяной круг: начинать всегда есть с чем
		if Game.home_pos != Vector2(960, 358) and WD.region_of(Game.home_pos) == r:
			for kh2 in range(22):
				var a: float = TAU * float(kh2) / 22.0 + rng.randf_range(-0.12, 0.12)
				var hp2: Vector2 = Game.home_pos + Vector2(cos(a) * rng.randf_range(260, 560), 200.0 + sin(a) * rng.randf_range(220, 420))
				if WD.road_value(hp2) < 14.0 or bool(main.call("is_blocked", hp2)) or not WD.region_rect(r).has_point(hp2):
					continue
				var lo2: Array = preload("res://herbs_db.gd").wild_for(WD.biome_at(hp2))
				var hn2: Node2D = Node2D.new()
				hn2.set_script(load("res://herb_spot.gd"))
				node.add_child(hn2)
				hn2.call("setup", hp2, lo2 if not lo2.is_empty() else hopts, 0.85, wm)
	# грибные места
	var opts: Array = W.shrooms_for(biome)
	if not opts.is_empty():
		var n: int = 36 if biome in WD.WILD else 18
		for k3 in range(n):
			var fp: Vector2 = _spot(rng, rect, 10.0)
			if fp.x > -1e8:
				var f: Node2D = Node2D.new()
				f.set_script(load("res://forage.gd"))
				node.add_child(f)
				f.call("setup", fp, opts)


## Сколько мест трав в области биома и как часто на них что-то вырастает
const HERB_SPOTS: Dictionary = {
	1: [96, 0.9], 16: [84, 0.85], 12: [74, 0.8], 9: [56, 0.75], 4: [54, 0.7], 13: [64, 0.7], 14: [64, 0.7],
	5: [54, 0.65], 6: [50, 0.65], 10: [54, 0.6], 17: [48, 0.6], 11: [44, 0.55], 15: [44, 0.55], 18: [40, 0.55],
	2: [40, 0.5], 3: [40, 0.5], 7: [40, 0.5], 8: [40, 0.5],
}


## Место для травы: не на дороге и не в преграде (можно и на поляне у дома)
func _herb_spot(rng: RandomNumberGenerator, rect: Rect2) -> Vector2:
	for i in range(16):
		var p: Vector2 = Vector2(rng.randf_range(rect.position.x + 30, rect.end.x - 30), rng.randf_range(rect.position.y + 30, rect.end.y - 30))
		if WD.road_value(p) < 14.0 or bool(main.call("is_blocked", p)) or bool(main.call("is_blocked", p + Vector2(0, -6))):
			continue
		if WD.biome_at(p) == WD.SEA or bool(world.call("under_crown", p)):
			continue
		return p
	return Vector2(-1e9, -1e9)


func _spot(rng: RandomNumberGenerator, rect: Rect2, rad: float) -> Vector2:
	for i in range(20):
		var p: Vector2 = Vector2(rng.randf_range(rect.position.x + 30, rect.end.x - 30), rng.randf_range(rect.position.y + 30, rect.end.y - 30))
		if bool(world.call("free_at", p, rad, 24.0)) and not bool(main.call("is_blocked", p)) and not bool(world.call("under_crown", p)):
			return p
	return Vector2(-1e9, -1e9)


func _animal(node: Node2D, kind: String, at: Vector2) -> void:
	var a: Node2D = Node2D.new()
	a.set_script(load("res://animal.gd"))
	node.add_child(a)
	a.call("setup", kind, at)
	a.set("blocked", Callable(main, "is_blocked"))
	main.call("add_caster", a.get("spr") as Sprite2D, true)


func _cave(node: Node2D, r: Vector2i, p: Vector2, rng: RandomNumberGenerator) -> void:
	world.call("reserve", Rect2(p - Vector2(160, 200), Vector2(320, 260)))
	_put(node, r, "cave_entrance", p, 0.0)
	world.call("add_block_rect", Rect2(p.x - 106, p.y - 90, 60, 84))
	world.call("add_block_rect", Rect2(p.x + 46, p.y - 90, 60, 84))
	world.call("add_block_rect", Rect2(p.x - 106, p.y - 150, 212, 70))
	_glow(p + Vector2(0, -30), Color(0.45, 0.9, 1.0), 0.9)
	# v19: вход в шахту
	var door: Node2D = Node2D.new()
	door.set_script(load("res://cave_door.gd"))
	door.position = p + Vector2(0, -4)
	node.add_child(door)
	for k in range(5):
		var q: Vector2 = p + Vector2(rng.randf_range(-150, 150), rng.randf_range(10, 60))
		_put(node, r, "giant_shroom_blue" if k % 2 == 0 else "giant_shroom_pink", q, 8.0)
		_glow(q + Vector2(0, -50), Color(0.5, 0.8, 1.0) if k % 2 == 0 else Color(1.0, 0.6, 0.9), 0.5)
	# у входа всегда есть светящиеся шляпки (ночью)
	for k2 in range(4):
		var f: Node2D = Node2D.new()
		f.set_script(load("res://forage.gd"))
		node.add_child(f)
		f.call("setup", p + Vector2(-60 + k2 * 40, 30 + (k2 % 2) * 14), ["glow_cap"])


func place_cave(node: Node2D, r: Vector2i, p: Vector2) -> void:
	_cave(node, r, p, world.get("rng"))
	for k in range(3):
		_put(node, r, "crystal_cluster", p + Vector2(-180 + k * 180, 90), 14.0)
		_glow(p + Vector2(-180 + k * 180, 66), Color(0.7, 0.5, 1.0), 0.45)


func place_unicorn(node: Node2D, r: Vector2i, p: Vector2) -> void:
	world.call("reserve", Rect2(p - Vector2(280, 200), Vector2(560, 380)))
	_put(node, r, "elf_spring", p, 0.0)
	world.call("add_block", p + Vector2(0, -38), 46.0)
	_glow(p + Vector2(0, -40), Color(1.0, 0.7, 0.95), 1.0)
	for k in range(3):
		_animal(node, "unicorn", p + Vector2(-160 + k * 160, 120))
	_animal(node, "sapphire_hare", p + Vector2(200, -60))
	for k2 in range(6):
		var a: float = TAU * k2 / 6.0
		_put(node, r, "giant_shroom_pink", p + Vector2(cos(a) * 240.0, sin(a) * 150.0 + 20.0), 8.0)


func place_hermit(node: Node2D, r: Vector2i, p: Vector2) -> void:
	world.call("reserve", Rect2(p - Vector2(200, 240), Vector2(400, 340)))
	_put(node, r, "hermit_hut", p, 0.0)
	world.call("add_block_rect", Rect2(p.x - 50, p.y - 52, 100, 50))
	_glow(p + Vector2(33, -38), Color(1.0, 0.75, 0.4), 0.35)
	_put(node, r, "stump_table", p + Vector2(-110, 40), 12.0)
	for k in range(4):
		_put(node, r, "lavender_3" if k % 2 == 0 else "mint_3", p + Vector2(80 + k * 22, 30), 0.0, false)
	var who: String = "hermit_agna" if p.x < 0 else "hermit_oda"
	_person(node, who, p + Vector2(-40, 70))


func place_outcast(node: Node2D, r: Vector2i, p: Vector2) -> void:
	world.call("reserve", Rect2(p - Vector2(240, 180), Vector2(480, 320)))
	for k in range(3):
		var tp: Vector2 = p + Vector2(-150 + k * 150, -60 + (k % 2) * 30)
		var s: Sprite2D = _put(node, r, "orc_tent", tp, 0.0)
		s.modulate = Color(0.7, 0.66, 0.75)
		world.call("add_block_rect", Rect2(tp.x - 44, tp.y - 36, 88, 32))
	_put(node, r, "campfire", p + Vector2(0, 60), 16.0)
	_glow(p + Vector2(0, 46), Color(1.0, 0.6, 0.3), 0.9)
	_person(node, "outcast_rin", p + Vector2(-50, 100))
	_person(node, "outcast_vex", p + Vector2(60, 110))


func _person(node: Node2D, name: String, at: Vector2) -> void:
	var c: Node2D = Node2D.new()
	c.set_script(load("res://catgirl.gd"))
	node.add_child(c)
	c.call("setup", name, at)
	c.set("roam", 90.0)
	c.set("blocked", Callable(main, "is_blocked"))
	var sp: Sprite2D = c.get("spr") as Sprite2D
	main.call("add_caster", sp, true)
	sp.material = main.call("char_light_mat", Vector2(8, 8), sp)
	var fm: ShaderMaterial = main.call("char_light_mat", Vector2(1, 1), sp)
	fm.set_shader_parameter("region_mode", true)
	(c.get("face") as Sprite2D).material = fm
	c.set("face_mat", fm)


func _glow(at: Vector2, col: Color, k: float) -> void:
	var s: Sprite2D = Sprite2D.new()
	s.texture = load("res://art/fx_glow.png")
	s.position = at
	s.scale = Vector2.ONE * k
	s.modulate = Color(col.r, col.g, col.b, 0.0)
	s.material = main.call("_additive")
	(main.get("fx_layer") as Node).add_child(s)
	(main.get("glows") as Array).append([s, 0.6])

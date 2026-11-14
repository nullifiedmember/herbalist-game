extends Node
## Целые города во всех землях: мощёные улицы сеткой, ряды домов вдоль улиц (дверью к улице),
## рыночная площадь с двумя лавками и торговками, фонари, жители гуляют по улицам.
## Лидеры земель стоят у главного здания земли.

const WD = preload("res://world_data.gd")

# земля: центр города, дома (картинка, ширина), лавки, жители, торговки, фонарь
const TOWNS: Dictionary = {
	# v25: Понивилль (пони в облике девушек)
	"ponies": {"c": Vector2(6100, -7000), "houses": [["pony_house_a", 160], ["pony_house_b", 160], ["pony_house_c", 160], ["pony_house_d", 160]],
		"stalls": ["stall_red", "stall_purple"], "people": ["pony_lyra", "pony_bonbon", "pony_derpy", "pony_vinyl", "pony_octavia", "pony_cheerilee", "pony_berry", "pony_carrot",
		"pony_minuette", "pony_twist", "pony_roseluck", "pony_daisy", "pony_lily", "pony_lemon", "pony_twinkle", "pony_amethyst", "pony_mayor"],
		"sellers": ["pony_roseluck", "pony_carrot"], "lamp": "lantern", "guard": "pony_fleetfoot"},
	"cats": {"c": Vector2(630, 4260), "houses": [["cat_house_a", 184], ["cat_house_b", 184], ["cat_house_c", 184], ["cat_house_d", 184], ["cat_house_e", 210], ["cat_house_f", 190]],
		"hall": ["cat_hall", 300], "stalls": ["stall_red", "stall_purple"], "people": ["catgirl_maple", "catgirl_vanilla", "catgirl_mira", "catgirl_ryzhik", "catgirl_snow", "catgirl_smoky", "catgirl_choco", "catgirl_cream"], "sellers": ["catgirl_choco", "catgirl_cream"], "lamp": "lantern", "guard": "catgirl_smoky"},
	"spider": {"c": Vector2(-2720, -380), "houses": [["cocoon_house", 110]], "stalls": ["stall_silk", "stall_purple"], "people": ["spidergirl_b", "spidergirl_c"], "sellers": ["spidergirl_b", "spidergirl_c"], "lamp": "", "spread": 0.75, "guard": "spidergirl_b"},
	"gothic": {"c": Vector2(1400, -4260), "houses": [["goth_house_a", 150], ["goth_house_b", 170]], "stalls": ["stall_purple", "stall_red"], "people": ["hunter_vesna", "hunter_morra", "vampire_carmilla", "vampire_mina", "werewolf_luna", "werewolf_rua"], "sellers": ["vampire_mina", "werewolf_rua"], "lamp": "goth_lamp", "guard": "hunter_morra"},
	"knights": {"c": Vector2(8620, 1660), "houses": [["town_house_a", 200], ["town_house_b", 170], ["town_house_c", 220]], "stalls": ["stall_red", "stall_blue"], "people": ["adv_rina", "adv_elma", "knight_aria", "knight_sera", "knight_vera", "squire_tilly"], "sellers": ["squire_tilly", "knight_sera"], "lamp": "lantern"},
	"elves": {"c": Vector2(-8540, 3120), "houses": [["elf_house", 160], ["elf_house_b", 160]], "stalls": ["stall_green", "stall_silk"], "people": ["elf_lirael", "elf_sylwen", "elf_thalia"], "sellers": ["elf_sylwen", "elf_thalia"], "lamp": "elf_lantern", "guard": "elf_thalia"},
	"mages": {"c": Vector2(10540, -3160), "houses": [["mage_house_a", 170], ["mage_house_b", 190]], "stalls": ["stall_blue", "stall_purple"], "people": ["mage_lisel", "mage_fenna", "mage_aurel", "mage_noa", "mage_ilka"], "sellers": ["mage_ilka", "mage_noa"], "lamp": "elf_lantern", "guard": "mage_noa"},
	"orcs": {"c": Vector2(6740, 5540), "houses": [["orc_hut", 130], ["orc_tent", 120]], "stalls": ["stall_brown", "stall_red"], "people": ["orc_brakka", "orc_grasha", "orc_ruzga"], "sellers": ["orc_ruzga", "orc_grasha"], "lamp": "totem", "guard": "orc_brakka"},
	"goblins": {"c": Vector2(10870, 5560), "houses": [["goblin_hut_a", 130], ["goblin_hut_b", 130], ["goblin_hut_c", 130]], "stalls": ["stall_green", "stall_brown"], "people": ["goblin_snik", "goblin_grub", "goblin_pip", "goblin_zix"], "sellers": ["goblin_zix", "goblin_pip"], "lamp": "lantern", "small": true, "guard": "goblin_zix"},
	"dwarves": {"c": Vector2(-8760, -3230), "houses": [["dwarf_house_a", 200], ["dwarf_house_b", 170]], "stalls": ["stall_brown", "stall_red"], "people": ["dwarf_berta", "dwarf_ingrid", "dwarf_hilda", "dwarf_greta", "dwarf_tova"], "sellers": ["dwarf_tova", "dwarf_hilda"], "lamp": "brazier", "small": true, "guard": "dwarf_greta"},
	"japan": {"c": Vector2(16320, 640), "houses": [["jp_house_a", 180], ["jp_house_b", 200], ["jp_house_c", 170]], "stalls": ["stall_jp_0", "stall_jp_1"], "people": ["kitsune_hana", "kitsune_aka", "kitsune_kuro"], "sellers": ["kitsune_hana", "kitsune_aka"], "lamp": "stone_lantern", "guard": "kitsune_kuro"},
}
const LEADERS: Dictionary = {
	"catgirl_queen": Vector2(0, 0),            # у ратуши — ставится в городе
	"knight_queen": Vector2(6720, 1940),
	"elf_queen": Vector2(-7020, 3100),
	"archmage": Vector2(8280, -3290),
	"orc_chief": Vector2(8990, 5330),
	"goblin_boss": Vector2(10130, 5420),
	"dwarf_queen": Vector2(-10560, -3210),
}

var main: Node2D
var world: Node2D
var plans: Dictionary = {}     # регион -> [[земля, ...]] что строить
var cobble: Texture2D
var keep_out: Array = []
var used_tex: Dictionary = {}  # какие жители уже стоят в городе, который сейчас строится


func setup(m: Node2D, w: Node2D) -> void:
	add_to_group("towns")
	main = m
	world = w
	cobble = load("res://art/wt_cobble.png")
	for land in TOWNS.keys():
		var c: Vector2 = (TOWNS[land] as Dictionary)["c"]
		_plan(WD.region_of(c), ["town", land])
	# лидеры теперь живут во дворцах своих городов (см. _zones)
	var tb: Dictionary = world.get("town_builders")
	for r in plans.keys():
		tb[r] = Callable(self, "build")


## В городе играет вальс
func _process(_delta: float) -> void:
	var pl: Node2D = main.get("player") as Node2D if main != null else null
	if pl == null:
		return
	var in_town: bool = false
	for land in TOWNS.keys():
		var c: Vector2 = (TOWNS[land] as Dictionary)["c"]
		if Rect2(c - Vector2(1000, 760), Vector2(2000, 1560)).has_point(pl.global_position):
			in_town = true
	Sound.forced = "music_town" if in_town else ""


func _plan(r: Vector2i, item: Array) -> void:
	if not plans.has(r):
		plans[r] = []
	(plans[r] as Array).append(item)


func build(node: Node2D, r: Vector2i) -> void:
	for it in plans.get(r, []):
		if String(it[0]) == "town":
			_town(node, r, String(it[1]))
		else:
			var n: String = String(it[1])
			_npc(node, n, LEADERS[n], 40.0, "")


## Свой рисунок улиц у каждой земли: лучи от площади, кольца, «гребёнка», кривые переулки.
## kind: spokes — лучи, ring — кольцо, comb — главная улица с отростками, grid — кривая сетка
const STYLE: Dictionary = {
	"ponies": {"res": "spokes", "wob": 12.0, "hw": 18.0, "plaza": "round", "edge": Color("8a6a8a")},
	"cats": {"res": "spokes", "wob": 10.0, "hw": 18.0, "plaza": "round", "edge": Color("8a5a62")},
	"spider": {"res": "lanes", "wob": 14.0, "hw": 14.0, "plaza": "round", "edge": Color("3a3448")},
	"gothic": {"res": "comb", "wob": 8.0, "hw": 22.0, "plaza": "square", "edge": Color("121018")},
	"knights": {"res": "grid", "wob": 12.0, "hw": 22.0, "plaza": "square", "edge": Color("34323e")},
	"elves": {"res": "ring", "wob": 16.0, "hw": 14.0, "plaza": "round", "edge": Color("2e3a20")},
	"mages": {"res": "spokes", "wob": 6.0, "hw": 18.0, "plaza": "square", "edge": Color("6a7090")},
	"orcs": {"res": "ring", "wob": 18.0, "hw": 18.0, "plaza": "round", "edge": Color("4a2a1a")},
	"goblins": {"res": "lanes", "wob": 22.0, "hw": 14.0, "plaza": "round", "edge": Color("22180e")},
	"dwarves": {"res": "comb", "wob": 6.0, "hw": 22.0, "plaza": "square", "edge": Color("26221e")},
	"japan": {"res": "grid", "wob": 4.0, "hw": 18.0, "plaza": "square", "edge": Color("4a3a32")},
}

# Занятия жителей у каждой земли: [предмет, занятие]
const STATIONS: Dictionary = {
	"ponies": [["flower_bed", "garden"], ["dessert_table", "dessert"], ["bake_oven", "bake"], ["wheat_patch", "farm"], ["flower_bed", "garden"], ["loom", "weave"]],
	"cats": [["bake_oven", "bake"], ["dessert_table", "dessert"], ["wheat_patch", "farm"], ["bake_oven", "bake"], ["wheat_patch", "farm"], ["dessert_table", "dessert"], ["yarn_basket", "knit"]],
	"spider": [["loom", "weave"], ["loom", "weave"], ["flower_bed", "garden"]],
	"gothic": [["goth_cauldron", "brew"], ["woodpile", "chop"], ["flower_bed", "garden"], ["goth_cauldron", "brew"]],
	"knights": [["forge", "smith"], ["training_dummy", "train"], ["grindstone", "sharpen"], ["training_dummy", "train"], ["sword_rack", "smith2"]],
	"elves": [["archery_target", "archer"], ["flower_bed", "garden"], ["loom", "weave"], ["archery_target", "archer"]],
	"mages": [["lectern", "read"], ["star_globe", "spell"], ["goth_cauldron", "brew"], ["lectern", "read"]],
	"orcs": [["woodpile", "chop"], ["grindstone", "sharpen"], ["roast_spit", "cook"], ["war_drum", "drum"]],
	"goblins": [["tinker_bench", "tinker"], ["junk_pile", "dig"], ["tinker_bench", "tinker"]],
	"dwarves": [["forge", "smith"], ["ale_barrels", "ale"], ["ore_cart", "mine"], ["forge", "smith"]],
	"japan": [["flower_bed", "garden"], ["loom", "weave"], ["archery_target", "archer"], ["dessert_table", "dessert"]],
}

var streets: Array = []          # улицы текущего города: [полуширина, PackedVector2Array]
var street_cells: Dictionary = {}
var house_rects: Array = []
var street_mat: Dictionary = {}
var zones: Array = []            # большие здания: [картинка, точка, вид, ширина]


## Улица с изломами: почти прямые отрезки, каждые ~110 пикселей — лёгкий поворот (не волна и не линейка)
func _kink(cp: Array, jit: float, rng: RandomNumberGenerator) -> PackedVector2Array:
	var out: PackedVector2Array = PackedVector2Array()
	for j in range(cp.size() - 1):
		var a: Vector2 = cp[j]
		var b: Vector2 = cp[j + 1]
		var n: int = maxi(1, int(a.distance_to(b) / 110.0))
		var nrm: Vector2 = (b - a).normalized().orthogonal()
		for k in range(n):
			var t: float = float(k) / float(n)
			var q: Vector2 = a.lerp(b, t)
			if k > 0:
				q += nrm * rng.randf_range(-jit, jit)
			out.append(q.round())
	out.append((cp[cp.size() - 1] as Vector2).round())
	return out


## Рисунок города: площадь в центре, дворец королевы на севере, таверна на западе,
## лавки на востоке, жилые улицы — по-своему у каждой земли; въезды — там, где подходят дороги мира
func _layout(land: String, c: Vector2, rng: RandomNumberGenerator) -> void:
	var st: Dictionary = STYLE[land]
	var hw: float = float(st["hw"])
	var jit: float = float(st["wob"])
	zones = []
	# главные улицы
	var north: PackedVector2Array = _kink([c + Vector2(0, -100), c + Vector2(0, -270)], 0.0, rng)
	var west: PackedVector2Array = _kink([c + Vector2(-140, 60), c + Vector2(-520, 70), c + Vector2(-900, 60 + rng.randf_range(-60, 60))], jit, rng)
	var east: PackedVector2Array = _kink([c + Vector2(140, 60), c + Vector2(520, 50), c + Vector2(900, 60 + rng.randf_range(-60, 60))], jit, rng)
	var south: PackedVector2Array = _kink([c + Vector2(0, 120), c + Vector2(rng.randf_range(-60, 60), 420), c + Vector2(rng.randf_range(-80, 80), 720)], jit, rng)
	streets.append([hw + 4.0, north])
	streets.append([hw, west])
	streets.append([hw, east])
	streets.append([hw, south])
	# зоны: дворец, таверна (развлечения), лавки (торговля)
	zones.append(["palace_" + land, c + Vector2(0, -270 - hw - 14), "palace", 300.0])
	zones.append(["tavern_" + land, c + Vector2(-420, 70 - hw - 16), "tavern", 230.0])
	if land == "cats":
		zones.append(["bakery_cats", c + Vector2(330, 50 - hw - 16), "bakery", 200.0])
	else:
		zones.append(["shop_" + land, c + Vector2(330, 50 - hw - 16), "shop", 170.0])
	zones.append(["shop_" + land, c + Vector2(560, 50 - hw - 16), "shop", 170.0])
	# v18: у каждого города своя тюрьма (prison_<земля>.png — tools/aseprite/gen_prison.lua)
	zones.append(["prison_" + land, c + Vector2(430, 330), "prison", 200.0])
	# v19: приют для животных (у кошек — кошачий)
	zones.append(["shelter_cats" if land == "cats" else "shelter_town", c + Vector2(-440, 330), "shelter", 200.0])
	# жилые улицы — у каждой земли свои
	var kind: String = String(st.get("res", "grid"))
	match kind:
		"grid":
			for yy in [300.0, 560.0]:
				streets.append([hw - 2.0, _kink([c + Vector2(-820, yy + rng.randf_range(-30, 30)), c + Vector2(820, yy + rng.randf_range(-30, 30))], jit, rng)])
			for xx in [-560.0, 560.0]:
				streets.append([hw - 2.0, _kink([c + Vector2(xx, 60), c + Vector2(xx + rng.randf_range(-40, 40), 680)], jit, rng)])
		"spokes":
			for sx in [-1.0, 1.0]:
				streets.append([hw - 2.0, _kink([c + Vector2(sx * 110, 110), c + Vector2(sx * 440, 380), c + Vector2(sx * 780, 640)], jit, rng)])
				streets.append([hw - 2.0, _kink([c + Vector2(sx * 520, 60), c + Vector2(sx * 620, -330), c + Vector2(sx * 760, -560)], jit, rng)])
			streets.append([hw - 2.0, _kink([c + Vector2(-440, 380), c + Vector2(440, 380)], jit, rng)])
		"comb":
			for i in range(5):
				var x0: float = -760.0 + i * 380.0
				if absf(x0) < 100.0:
					continue
				streets.append([hw - 4.0, _kink([c + Vector2(x0, 65), c + Vector2(x0 + rng.randf_range(-40, 40), 420), c + Vector2(x0 + rng.randf_range(-60, 60), 640)], jit, rng)])
				streets.append([hw - 4.0, _kink([c + Vector2(x0, 60), c + Vector2(x0 + rng.randf_range(-40, 40), -300)], jit, rng)])
		"ring":
			var cp: Array = []
			for k in range(13):
				var a: float = TAU * float(k) / 12.0
				cp.append(c + Vector2(cos(a) * 640.0, 120.0 + sin(a) * 440.0))
			streets.append([hw - 2.0, _kink(cp, jit, rng)])
			streets.append([hw - 2.0, _kink([c + Vector2(-640, 120), c + Vector2(-260, 400), c + Vector2(0, 560)], jit, rng)])
		"lanes":
			for k2 in range(5):
				var a2: float = rng.randf_range(0.2, PI - 0.2)
				var p0: Vector2 = c + Vector2(rng.randf_range(-500, 500), rng.randf_range(120, 300))
				streets.append([hw - 4.0, _kink([p0, p0 + Vector2(cos(a2), sin(a2)) * rng.randf_range(260, 420)], jit * 1.5, rng)])
	# въезды: дорога мира кончается у края города — дальше по городской улице до ближайшей улицы
	for cv in WD.road_curves():
		var pts: PackedVector2Array = cv[1]
		for i2 in range(pts.size() - 1):
			var d0: float = pts[i2].distance_to(c)
			var d1: float = pts[i2 + 1].distance_to(c)
			if (d0 - WD.TOWN_R) * (d1 - WD.TOWN_R) <= 0.0:
				var e: Vector2 = pts[i2] if absf(d0 - WD.TOWN_R) < absf(d1 - WD.TOWN_R) else pts[i2 + 1]
				var best: Vector2 = c
				var bd: float = 99999.0
				for s in streets:
					for q in (s[1] as PackedVector2Array):
						var dq: float = q.distance_to(e)
						if dq < bd and q.distance_to(c) < e.distance_to(c) - 100.0:
							bd = dq
							best = q
				streets.append([hw, _kink([e + (e - c).normalized() * 30.0, best], jit * 0.6, rng)])
	# клетки улиц (16 пикселей) — чтобы быстро проверять, не стоит ли дом на мостовой
	for s2 in streets:
		var h2: float = float(s2[0]) + 10.0
		var pts2: PackedVector2Array = s2[1]
		for i3 in range(pts2.size() - 1):
			var a3: Vector2 = pts2[i3]
			var b3: Vector2 = pts2[i3 + 1]
			var steps: int = int(a3.distance_to(b3) / 8.0) + 1
			for k3 in range(steps + 1):
				var p: Vector2 = a3.lerp(b3, float(k3) / steps)
				for dy in range(int(-h2 / 16.0) - 1, int(h2 / 16.0) + 2):
					for dx in range(int(-h2 / 16.0) - 1, int(h2 / 16.0) + 2):
						var q2: Vector2 = p + Vector2(dx * 16.0, dy * 16.0)
						if q2.distance_to(p) <= h2 + 8.0:
							street_cells[Vector2i(int(floor(q2.x / 16.0)), int(floor(q2.y / 16.0)))] = true
	# площадь — тоже «улица»
	for dy2 in range(-10, 11):
		for dx2 in range(-12, 13):
			var q3: Vector2 = c + Vector2(dx2 * 16.0, dy2 * 16.0)
			if _in_plaza(land, c, q3, 8.0):
				street_cells[Vector2i(int(floor(q3.x / 16.0)), int(floor(q3.y / 16.0)))] = true


func _in_plaza(land: String, c: Vector2, p: Vector2, grow: float) -> bool:
	var d: Vector2 = p - c
	if String(STYLE[land].get("plaza", "round")) == "square":
		return absf(d.x) < 170.0 + grow and absf(d.y) < 120.0 + grow
	return (d.x * d.x) / pow(170.0 + grow, 2.0) + (d.y * d.y) / pow(125.0 + grow, 2.0) < 1.0


func on_street(p: Vector2) -> bool:
	return _on_street(p)


func _on_street(p: Vector2) -> bool:
	return street_cells.has(Vector2i(int(floor(p.x / 16.0)), int(floor(p.y / 16.0))))


## Улицы: сначала все тёмные кромки, потом покрытие земли — перекрёстки без швов
func _draw_streets(node: Node2D, land: String, c: Vector2) -> void:
	var st: Dictionary = STYLE[land]
	var holder: Node2D = Node2D.new()
	holder.z_index = -10
	node.add_child(holder)
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = load("res://street.gdshader")
	mat.set_shader_parameter("cob", load("res://art/st10_%s.png" % land))
	mat.set_shader_parameter("size", 64.0)
	mat.set_shader_parameter("tint", Color(1, 1, 1))
	var edge_c: Color = st["edge"]
	for pass_i in range(2):
		for s in streets:
			var l: Line2D = Line2D.new()
			l.points = s[1]
			l.width = float(s[0]) * 2.0 + (5.0 if pass_i == 0 else 0.0)
			l.joint_mode = Line2D.LINE_JOINT_BEVEL
			l.begin_cap_mode = Line2D.LINE_CAP_BOX
			l.end_cap_mode = Line2D.LINE_CAP_BOX
			l.antialiased = false
			if pass_i == 0:
				l.default_color = edge_c
			else:
				l.default_color = Color.WHITE
				l.material = mat
			holder.add_child(l)
		var poly: Polygon2D = Polygon2D.new()
		var pts: PackedVector2Array = PackedVector2Array()
		var g: float = 3.0 if pass_i == 0 else 0.0
		if String(st.get("plaza", "round")) == "square":
			pts = PackedVector2Array([c + Vector2(-170 - g, -120 - g), c + Vector2(170 + g, -120 - g), c + Vector2(170 + g, 120 + g), c + Vector2(-170 - g, 120 + g)])
		else:
			for k in range(32):
				var a: float = TAU * float(k) / 32.0
				pts.append(c + Vector2(cos(a) * (170.0 + g), sin(a) * (125.0 + g)))
		poly.polygon = pts
		if pass_i == 0:
			poly.color = edge_c
		else:
			poly.material = mat
		holder.add_child(poly)


## Японский сад: пагода, пруд с карпами и мостиком, бамбук, фонари; лепестки сакуры над городом
func _japan_garden(node: Node2D, r: Vector2i, c: Vector2) -> void:
	var pg: Vector2 = c + Vector2(-560, -300)
	world.call("put", node, r, "jp_pagoda", pg, 0.0, 0.0, Color.WHITE, true)
	world.call("add_block_rect", Rect2(pg.x - 40, pg.y - 22, 80, 20))
	house_rects.append(Rect2(pg.x - 70, pg.y - 320, 140, 330))
	var pd: Vector2 = c + Vector2(560, -300)
	var pond: Sprite2D = world.call("put", node, r, "koi_pond", pd + Vector2(0, 60), 0.0, 0.0, Color.WHITE, false)
	pond.z_index = -9
	world.call("add_block_rect", Rect2(pd.x - 96, pd.y - 50, 192, 104))
	world.call("put", node, r, "jp_bridge", pd + Vector2(0, 40), 0.0, 0.0, Color.WHITE, true)
	house_rects.append(Rect2(pd.x - 120, pd.y - 70, 240, 140))
	for k in range(6):
		var lp: Vector2 = pd + Vector2(-140.0 + 56.0 * k, 92.0 + (k % 2) * 6.0)
		if k == 0 or k == 5:
			world.call("put", node, r, "stone_lantern", lp, 0.0, 7.0, Color.WHITE, true)
			_window_glow(lp + Vector2(0, -36))
	for b in [Vector2(-720, -120), Vector2(720, -80), Vector2(-760, 260), Vector2(760, 300), Vector2(-340, -420), Vector2(330, -440)]:
		var bp: Vector2 = c + (b as Vector2)
		world.call("put", node, r, "bamboo", bp, 0.6, 9.0, Color.WHITE, true)
		house_rects.append(Rect2(bp.x - 40, bp.y - 190, 80, 196))
	var pet: CPUParticles2D = CPUParticles2D.new()
	pet.texture = load("res://art/fx_petal.png")
	pet.amount = 70
	pet.lifetime = 9.0
	pet.preprocess = 9.0
	pet.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	pet.emission_rect_extents = Vector2(1100, 800)
	pet.position = c
	pet.gravity = Vector2(10, 14)
	pet.initial_velocity_min = 4.0
	pet.initial_velocity_max = 14.0
	pet.angular_velocity_min = -90.0
	pet.angular_velocity_max = 90.0
	pet.angle_max = 360.0
	pet.scale_amount_min = 0.7
	pet.scale_amount_max = 1.2
	pet.z_index = 40
	node.add_child(pet)


## Большие здания зон: дворец (у дверей всегда стража), таверна, лавки, пекарня
func _zones(node: Node2D, r: Vector2i, land: String, t: Dictionary, rng: RandomNumberGenerator) -> void:
	var people: Array = t["people"]
	var guard: String = String(t.get("guard", "knight_sera"))
	for z in zones:
		var tex: String = z[0]
		var p: Vector2 = z[1]
		if not ResourceLoader.exists("res://art/%s.png" % tex):
			continue
		var w: float = float(load("res://art/%s.png" % tex).get_width()) - 16.0
		var s: Sprite2D = world.call("put", node, r, tex, p, 0.0, 0.0, Color.WHITE, true)
		s.flip_h = false
		world.call("add_block_rect", Rect2(p.x - w / 2.0 + 10.0, p.y - 70.0, w - 20.0, 66.0))
		house_rects.append(Rect2(p.x - w / 2.0 - 10.0, p.y - 300.0, w + 20.0, 306.0))
		_window_glow(p + Vector2(-w * 0.25, -50))
		_window_glow(p + Vector2(w * 0.25, -50))
		var d: Node2D = Node2D.new()
		d.set_script(load("res://house_door.gd"))
		d.position = p + Vector2(0, -4)
		var kind: String = z[2]
		var owner: String = String(people[rng.randi_range(0, people.size() - 1)])
		if kind == "palace":
			owner = String(LEADER_OF.get(land, owner))
		elif kind == "bakery":
			owner = "catgirl_maple"
		elif kind == "prison":
			owner = guard
		elif kind == "shelter":
			owner = String(people[0])
		d.set("owner_tex", owner)
		d.set("owner_name", String(preload("res://npc_db.gd").person(owner)[0]))
		if kind == "prison":
			d.set("owner_name", String((preload("res://law.gd").PRISONS.get(land, {}) as Dictionary).get("jailer", "Тюремщица")))
		d.set("private", false)
		d.set("kind", kind)
		d.set("land", land)
		d.set("seed_k", int(p.x) * 7 + int(p.y))
		d.set("open_from", 7.0 if kind != "tavern" else 10.0)
		d.set("open_to", 20.0 if kind != "tavern" else 24.5)
		if kind == "prison":
			d.set("open_from", 0.0)
			d.set("open_to", 25.0)
		if kind == "shelter":
			d.set("open_from", 7.0)
			d.set("open_to", 21.0)
		node.add_child(d)
		if kind == "prison":
			# у ворот тюрьмы всегда дежурит стражница
			var pg: Node2D = _npc(node, guard, p + Vector2(w * 0.5 + 16.0, 12.0), 0.0, "стража")
			pg.set("row", 0)
			pg.set("job", "post")
		if kind == "palace":
			# стража у дверей дворца стоит всегда, а лидер — на крыльце днём
			for sx in [-1.0, 1.0]:
				var g: Node2D = _npc(node, guard, p + Vector2(sx * 44.0, 14.0), 0.0, "стража")
				g.set("row", 0)
				g.set("job", "post")
			if not (land in ["spider", "gothic"]):
				var ld: Node2D = _npc(node, String(LEADER_OF[land]), p + Vector2(0, 40), 30.0, "лидер")
				ld.set("role", "лидер")
		elif kind == "tavern":
			# у таверны отдыхают и болтают
			for k in range(2):
				var cp: Vector2 = p + Vector2(-50.0 + k * 100.0, 60.0)
				var a: Node2D = _npc(node, String(people[k % people.size()]), cp, 0.0, "")
				var b: Node2D = _npc(node, String(people[(k + 1) % people.size()]), cp + Vector2(22, 0), 0.0, "")
				a.set("job", "chat")
				a.set("row", 3)
				b.set("job", "chat")
				b.set("row", 2)
			world.call("put", node, r, "barrel", p + Vector2(w * 0.5 - 6.0, 6), 0.0, 9.0, Color.WHITE, true)


const LEADER_OF: Dictionary = {
	"cats": "catgirl_queen", "spider": "spidergirl", "gothic": "vampire_lilith", "knights": "knight_queen", "elves": "elf_queen",
	"mages": "archmage", "orcs": "orc_chief", "goblins": "goblin_boss", "dwarves": "dwarf_queen",
	"japan": "kitsune_sakura", "ponies": "pony_celestia",
}


## Город: улицы по стилю земли, площадь с лавками, дома вдоль улиц, занятия, стража
func _town(node: Node2D, r: Vector2i, land: String) -> void:
	used_tex.clear()      # в каждом городе — свои жители, без повторов
	var t: Dictionary = TOWNS[land]
	var c: Vector2 = t["c"]
	var rng: RandomNumberGenerator = world.get("rng")
	keep_out = (world.get("reserved") as Array).duplicate()   # чужие площади, замки, поляны
	streets = []
	street_cells = {}
	house_rects = []
	_layout(land, c, rng)
	# внутри города деревья не растут
	world.call("reserve", Rect2(c - Vector2(1000, 760), Vector2(2000, 1560)))
	_draw_streets(node, land, c)
	house_rects.append(Rect2(c - Vector2(180, 130), Vector2(360, 260)))   # площадь свободна
	# v16: старых лавок-прилавков на площади больше нет — торгуют только в лавках с полками
	_zones(node, r, land, t, rng)
	if land == "japan":
		for tp in [c + Vector2(0, 236), c + Vector2(-700, 236)]:
			world.call("put", node, r, "torii", tp, 0.0, 0.0, Color.WHITE, true)
			main.call("block_circle", tp + Vector2(-52, -4), 7.0)
			main.call("block_circle", tp + Vector2(52, -4), 7.0)
			house_rects.append(Rect2(tp.x - 70, tp.y - 110, 140, 116))
		_japan_garden(node, r, c)
	# дома вдоль улиц: перед дверью — улица
	var houses: Array = t["houses"]
	var made: int = 0
	_stations(node, r, land, t, rng)
	# места под дома: сетка по всему городу; перед дверью (чуть ниже) должна быть улица
	var cands: Array = []
	var gy: float = c.y - 760.0
	while gy < c.y + 800.0:
		var gx: float = c.x - 1000.0
		while gx < c.x + 1000.0:
			var q: Vector2 = Vector2(gx + rng.randf_range(-8, 8), gy).round()
			var ok: bool = false
			var lateral: bool = true
			for dd in [36.0, 52.0, 70.0]:
				if _on_street(q + Vector2(0, dd)):
					ok = true
					lateral = false
			# дом сбоку от переулка, идущего с севера на юг
			for sx in [-118.0, 118.0]:
				if _on_street(q + Vector2(sx, -20.0)) and _on_street(q + Vector2(sx, -60.0)):
					ok = true
			if ok:
				cands.append([q, lateral])
			gx += 24.0
		gy += 20.0
	cands.sort_custom(func(a, b): return (a[0] as Vector2).distance_to(c) < (b[0] as Vector2).distance_to(c))
	for cd in cands:
		var hp2: Vector2 = cd[0]
		var h: Array = houses[rng.randi_range(0, houses.size() - 1)]
		var w: float = float(h[1])
		if not _house_ok(hp2, w, bool(cd[1])):
			continue
		_place_house(node, r, String(h[0]), hp2, w)
		house_rects.append(Rect2(hp2.x - w / 2.0 - 10.0, hp2.y - 190.0, w + 20.0, 200.0))
		_door(node, land, hp2, made, rng)
		made += 1
		if made >= 24:
			break
	_finish(node, r, land, t, rng)


## Дом влезает: не на улице, не на другом доме, не на дороге и не на чужой постройке
func _house_ok(p: Vector2, w: float, strict: bool = false) -> bool:
	var body: Rect2 = Rect2(p.x - w / 2.0 + 6.0, p.y - 185.0, w - 12.0, 175.0)
	for hr in house_rects:
		if (hr as Rect2).intersects(body):
			return false
	# на улице не должно стоять основание дома (крыша может закрывать улицу позади — это нормально)
	body = Rect2(p.x - w / 2.0 + 10.0, p.y - (170.0 if strict else 64.0), w - 20.0, 160.0 if strict else 56.0)
	var yy: float = body.position.y
	while yy <= body.end.y:
		var xx: float = body.position.x
		while xx <= body.end.x:
			if _on_street(Vector2(xx, yy)):
				return false
			xx += 14.0
		yy += 14.0
	return _free_house(p, w)


## Свободная точка рядом с улицей для занятия (верстак, печь, грядка)
func _spot_near_streets(rng: RandomNumberGenerator, c: Vector2, rad: float, size: Vector2) -> Vector2:
	for i in range(80):
		var s: Array = streets[rng.randi_range(0, streets.size() - 1)]
		var pts: PackedVector2Array = s[1]
		var q: Vector2 = pts[rng.randi_range(0, pts.size() - 1)]
		var side: Vector2 = Vector2(rng.randf_range(-1, 1), rng.randf_range(-1, 1)).normalized()
		var p: Vector2 = (q + side * (float(s[0]) + size.x * 0.5 + 18.0)).round()
		if p.distance_to(c) > rad:
			continue
		var body: Rect2 = Rect2(p.x - size.x / 2.0, p.y - size.y, size.x, size.y + 40.0)
		var bad: bool = false
		for hr in house_rects:
			if (hr as Rect2).intersects(body):
				bad = true
				break
		if bad:
			continue
		var yy: float = body.position.y
		while yy <= body.end.y and not bad:
			var xx: float = body.position.x
			while xx <= body.end.x:
				if _on_street(Vector2(xx, yy)) or bool(main.call("is_blocked", Vector2(xx, yy))):
					bad = true
					break
				xx += 12.0
			yy += 12.0
		if bad or WD.road_value(p) < 16.0:
			continue
		house_rects.append(body)
		return p
	return Vector2.INF


## Рабочие места ставятся раньше домов, чтобы им хватило места у улиц
func _stations(node: Node2D, r: Vector2i, land: String, t: Dictionary, rng: RandomNumberGenerator) -> void:
	var c: Vector2 = t["c"]
	var people: Array = t["people"]
	# занятия: у каждого рабочего места — своя жительница
	var plan: Array = STATIONS.get(land, [])
	var wi: int = 0
	for st in plan:
		var tex: String = String(st[0])
		var sz: Vector2 = STATION_SIZE.get(tex, Vector2(70, 50))
		var sp: Vector2 = _spot_near_streets(rng, c, 900.0, sz)
		if sp == Vector2.INF:
			continue
		var s2: Sprite2D = world.call("put", node, r, tex, sp, 0.0, 0.0, Color.WHITE, true)
		s2.flip_h = false
		if tex != "wheat_patch" and tex != "flower_bed":
			world.call("add_block_rect", Rect2(sp.x - sz.x * 0.4, sp.y - 20, sz.x * 0.8, 18))
		var job: String = String(st[1])
		var wp: Vector2 = sp + Vector2(sz.x * 0.5 + 12.0, 6.0)
		var face_row: int = 2
		if job in ["farm", "garden"]:
			wp = sp + Vector2(0, 14)
			face_row = 1
		var who: Node2D = _npc(node, String(people[wi % people.size()]), wp, 0.0, JOB_ROLE.get(job, "житель"))
		who.set("job", job)
		who.set("row", face_row)
		who.set("job_at", sp)
		if job == "smith" and tex == "forge":
			world.call("add_block", sp + Vector2(25, -8), 12.0)
		if tex == "bake_oven" or tex == "forge" or tex == "roast_spit" or tex == "goth_cauldron":
			_glow(sp + Vector2(0, -22), 0.5)
		wi += 1


func _place_house(node: Node2D, r: Vector2i, tex: String, hp2: Vector2, w: float) -> void:
	var hs: Sprite2D = world.call("put", node, r, tex, hp2, 0.0, 0.0, Color.WHITE, true)
	hs.flip_h = false
	world.call("add_block_rect", Rect2(hp2.x - w / 2.0 + 16.0, hp2.y - 54.0, w - 32.0, 52.0))
	_window_glow(hp2 + Vector2(0, -44))


func _finish(node: Node2D, r: Vector2i, land: String, t: Dictionary, rng: RandomNumberGenerator) -> void:
	var c: Vector2 = t["c"]
	# аккуратный газон: ровная короткая травка между улицами и домами
	var lawn: Array = [[], [], []]
	var tint: Color = (world.get("GRASS_TINT") as Dictionary).get(WD.biome_at(c), Color(1, 1, 1))
	var gy: float = c.y - 720.0
	while gy < c.y + 760.0:
		var gx: float = c.x - 960.0
		while gx < c.x + 960.0:
			var q: Vector2 = Vector2(gx + rng.randf_range(-10, 10), gy + rng.randf_range(-6, 6))
			gx += 34.0
			if _on_street(q) or _on_street(q + Vector2(0, 8)) or bool(main.call("is_blocked", q)):
				continue
			var inside: bool = false
			for hr in house_rects:
				if Rect2((hr as Rect2).position + Vector2(0, (hr as Rect2).size.y - 40.0), Vector2((hr as Rect2).size.x, 40.0)).has_point(q):
					inside = true
					break
			if not inside:
				(lawn[rng.randi_range(0, 2)] as Array).append([q, tint])
		gy += 26.0
	for k in range(3):
		if not (lawn[k] as Array).is_empty():
			world.call("mm_batch", node, "grass_lawn%d" % k, lawn[k])
	var people: Array = t["people"]
	# фонари вдоль улиц
	var lamp: String = String(t["lamp"])
	if lamp != "":
		for s in streets:
			var pts: PackedVector2Array = s[1]
			var k: int = 6
			while k < pts.size():
				var a: Vector2 = pts[k]
				var nv: Vector2 = (pts[mini(k + 1, pts.size() - 1)] - pts[k - 1]).normalized().orthogonal()
				var lp: Vector2 = (a + nv * (float(s[0]) + 12.0) * (1.0 if k % 2 == 0 else -1.0)).round()
				if not _on_street(lp) and not bool(main.call("is_blocked", lp)) and not bool(main.call("is_blocked", lp + Vector2(0, -20))):
					var lr: Rect2 = Rect2(lp.x - 10, lp.y - 90, 20, 94)
					var ok: bool = true
					for hr in house_rects:
						if (hr as Rect2).intersects(lr):
							ok = false
							break
					if ok:
						world.call("put", node, r, lamp, lp, 0.0, 6.0, Color.WHITE, true)
						_glow(lp + Vector2(8, -46), 0.55)
				k += 12
	# жители гуляют по улицам
	var walkers: int = 16 if not bool(t.get("small", false)) else 10
	for i2 in range(walkers):
		var s3: Array = streets[i2 % streets.size()]
		var pts3: PackedVector2Array = s3[1]
		var pp: Vector2 = pts3[rng.randi_range(0, pts3.size() - 1)]
		_npc(node, String(people[i2 % people.size()]), pp, 160.0, "")
	# болтают парами у площади
	for k2 in range(2):
		var cp: Vector2 = c + Vector2(-160.0 + 300.0 * k2, 110.0)
		if bool(main.call("is_blocked", cp)) or bool(main.call("is_blocked", cp + Vector2(22, 0))):
			continue
		var a2: Node2D = _npc(node, String(people[k2 % people.size()]), cp, 0.0, "")
		var b2: Node2D = _npc(node, String(people[(k2 + 1) % people.size()]), cp + Vector2(22, 0), 0.0, "")
		a2.set("job", "chat")
		a2.set("row", 3)
		b2.set("job", "chat")
		b2.set("row", 2)
	# стража ходит дозором по улицам
	for g in range(2):
		var s4: Array = streets[(g * 2) % streets.size()]
		var pts4: PackedVector2Array = s4[1]
		var route: Array = []
		var j4: int = 0
		while j4 < pts4.size():
			route.append(pts4[j4] + Vector2(0, 6))
			j4 += 4
		route.append(pts4[pts4.size() - 1])
		var back: Array = route.duplicate()
		back.reverse()
		route.append_array(back)
		var gd: Node2D = _npc(node, String(t.get("guard", "knight_sera")), route[0], 0.0, "стража")
		gd.set("patrol", route)
	# заместитель лидера у площади
	_npc(node, String(people[people.size() - 1]), c + Vector2(-120, 80), 40.0, "заместитель")


const STATION_SIZE: Dictionary = {
	"bake_oven": Vector2(70, 70), "wheat_patch": Vector2(120, 50), "dessert_table": Vector2(80, 50),
	"forge": Vector2(90, 70), "training_dummy": Vector2(34, 60), "grindstone": Vector2(50, 46), "sword_rack": Vector2(60, 56),
	"goth_cauldron": Vector2(56, 50), "woodpile": Vector2(70, 46), "flower_bed": Vector2(100, 40),
	"archery_target": Vector2(44, 60), "loom": Vector2(60, 60), "lectern": Vector2(36, 56), "star_globe": Vector2(44, 64),
	"roast_spit": Vector2(70, 50), "war_drum": Vector2(44, 46), "tinker_bench": Vector2(80, 50), "junk_pile": Vector2(70, 46),
	"ale_barrels": Vector2(80, 56), "ore_cart": Vector2(70, 50), "yarn_basket": Vector2(40, 30),
}
const JOB_ROLE: Dictionary = {
	"bake": "пекарь", "farm": "фермер", "dessert": "кондитер", "knit": "вязальщица", "smith": "кузнец", "smith2": "кузнец",
	"train": "стража", "sharpen": "оружейник", "brew": "зельевар", "chop": "дровосек", "garden": "садовница",
	"archer": "лучница", "weave": "ткачиха", "read": "книжница", "spell": "чародейка", "cook": "повариха",
	"drum": "барабанщица", "tinker": "мастерица", "dig": "старьёвщица", "ale": "пивовар", "mine": "рудокоп",
}


## Дверь дома: хозяйка — одна из жительниц земли; каждый пятый дом — лавка или таверна
func _door(node: Node2D, land: String, hp: Vector2, idx: int, rng: RandomNumberGenerator) -> void:
	var t: Dictionary = TOWNS[land]
	var people: Array = t["people"]
	var d: Node2D = Node2D.new()
	d.set_script(load("res://house_door.gd"))
	d.position = hp + Vector2(0, -4)
	var tex: String = String(people[rng.randi_range(0, people.size() - 1)])
	d.set("owner_tex", tex)
	d.set("owner_name", String(preload("res://npc_db.gd").person(tex)[0]))
	d.set("private", idx % 5 != 2)
	d.set("land", land)
	d.set("seed_k", int(hp.x) * 7 + int(hp.y))
	d.set("open_from", rng.randf_range(7.0, 10.0))
	d.set("open_to", rng.randf_range(18.0, 21.0))
	node.add_child(d)


## Дом влезает: на месте нет другого дома/скалы/дороги мира
func _free_house(p: Vector2, w: float) -> bool:
	var body: Rect2 = Rect2(p.x - w / 2.0, p.y - 120.0, w, 120.0)
	for kr in keep_out:
		if (kr as Rect2).intersects(body):
			return false
	for dx in [-w / 2.0 + 20.0, 0.0, w / 2.0 - 20.0]:
		for dy in [-10.0, -40.0]:
			var q: Vector2 = p + Vector2(dx, dy)
			if WD.road_value(q) < 24.0:
				return false
			if bool(main.call("is_blocked", q)):
				return false
	return true


func _glow(at: Vector2, kk: float) -> void:
	var s: Sprite2D = Sprite2D.new()
	s.texture = load("res://art/fx_glow.png")
	s.position = at
	s.scale = Vector2.ONE * kk
	s.modulate = Color(1.0, 0.72, 0.38, 0.0)
	s.material = main.call("_additive")
	(main.get("fx_layer") as Node).add_child(s)
	(main.get("glows") as Array).append([s, 0.55])


func _window_glow(at: Vector2) -> void:
	_glow(at, 0.5)


## Один персонаж — одно имя на город: повтор заменяется ещё не занятым жителем той же земли,
## а если все уже на улицах — лишнего просто не ставим (стража и дозорные — не жители, им повторы можно).
func _npc(node: Node2D, name: String, at: Vector2, roam: float, role: String) -> Node2D:
	if role != "стража":
		if used_tex.has(name):
			var alt: String = ""
			for land in TOWNS.keys():
				var pool: Array = (TOWNS[land] as Dictionary)["people"]
				if pool.has(name):
					for cand in pool:
						if not used_tex.has(String(cand)) and String(cand) != String((TOWNS[land] as Dictionary).get("guard", "")):
							alt = String(cand)
							break
			if alt == "":
				var dummy: Node2D = Node2D.new()     # пустышка: вызывающий код только задаёт ей свойства
				dummy.queue_free()
				return dummy
			name = alt
		used_tex[name] = true
	var c: Node2D = Node2D.new()
	c.set_script(load("res://catgirl.gd"))
	node.add_child(c)
	c.call("setup", name, at)
	if role != "":
		c.set("role", role)
	c.set("roam", roam)
	c.set("blocked", Callable(main, "is_blocked"))
	var sp: Sprite2D = c.get("spr") as Sprite2D
	if name.begins_with("goblin") or name.begins_with("dwarf"):
		sp.scale = Vector2(0.27, 0.27) if name.begins_with("goblin") else Vector2(0.28, 0.28)
		c.set("interact_offset", Vector2(0, -22))
	main.call("add_caster", sp, true)
	sp.material = main.call("char_light_mat", Vector2(8, 8), sp)
	var fm: ShaderMaterial = main.call("char_light_mat", Vector2(1, 1), sp)
	fm.set_shader_parameter("region_mode", true)
	(c.get("face") as Sprite2D).material = fm
	c.set("face_mat", fm)
	return c


func _why(p: Vector2, w: float) -> String:
	var body: Rect2 = Rect2(p.x - w / 2.0 + 6.0, p.y - 170.0, w - 12.0, 160.0)
	for hr in house_rects:
		if (hr as Rect2).intersects(body):
			return "house"
	var yy: float = body.position.y
	while yy <= body.end.y:
		var xx: float = body.position.x
		while xx <= body.end.x:
			if _on_street(Vector2(xx, yy)):
				return "street"
			xx += 14.0
		yy += 14.0
	var b2: Rect2 = Rect2(p.x - w / 2.0, p.y - 200.0, w, 200.0)
	for kr in keep_out:
		if (kr as Rect2).intersects(b2):
			return "keep " + str(kr)
	return "road/block"

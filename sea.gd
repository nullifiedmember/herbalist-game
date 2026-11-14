extends Node
## Море: пляж с пальмами и ракушками, живая вода у берега, пирс с водолазным колоколом
## и подводный город русалочек «Жемчужная Бухта».
## Колокол на конце пирса опускает героиню на дно (далеко от мира, как комнаты домов),
## а жерло с пузырями на дне поднимает обратно на пирс. Под водой голубой свет, блики,
## лучи сверху, стайки рыбок, качаются водоросли, русалки плавают покачиваясь.

const WD = preload("res://world_data.gd")
const ORG: Vector2 = Vector2(0, 100000)          # где в мире лежит дно
const SIZE: Vector2 = Vector2(1920, 1280)
const SHORE_Y: float = 7592.0
const PIER_TOP: float = 7500.0
const PIER_END: Vector2 = Vector2(960, 8060)     # конец пирса: тут колокол
const PIER_HW: float = 50.0
const ARRIVE: Vector2 = Vector2(960, 1100)       # куда опускается колокол (на дне)

var main: Node2D
var world: Node2D
var blocks: Array = []        # прямоугольники (в координатах дна)
var circles: Array = []       # Vector3 круги (в координатах дна)
var diving: bool = false
var root: Node2D
var bubbles: CPUParticles2D
var hero_bubbles: CPUParticles2D
var rays: Array = []
var schools: Array = []       # [центр, радиус, скорость, фаза, [спрайты]]
var swimmers: Array = []      # русалки: [узел, фаза]
var t: float = 0.0


func setup(m: Node2D, w: Node2D) -> void:
	main = m
	world = w
	add_to_group("sea")
	_build_water()
	_build_pier()
	_build_under()
	(world.get("region_hooks") as Array).append(Callable(self, "_beach_region"))
	(world.get("region_hooks") as Array).append(Callable(self, "_open_sea_region"))
	_build_open_sea()


# ------------------------------------------------------------------ вода у берега

func _build_water() -> void:
	var x0: float = float(WD.GX0 * WD.RW) - 200.0
	var x1: float = x0 + float(WD.GRID[0].size() * WD.RW) + 400.0
	var poly: Polygon2D = Polygon2D.new()
	poly.polygon = PackedVector2Array([Vector2(x0, SHORE_Y - 120), Vector2(x1, SHORE_Y - 120), Vector2(x1, SHORE_Y + 1600), Vector2(x0, SHORE_Y + 1600)])
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = load("res://sea_water.gdshader")
	mat.set_shader_parameter("shore_y", SHORE_Y)
	poly.material = mat
	poly.z_index = -10
	main.add_child(poly)


## Украшения пляжа: пальмы рощицами, коряги, ракушки, камни с лужицами
func _beach_region(node: Node2D, r: Vector2i) -> void:
	if WD.biome_of_region(r) != WD.BEACH:
		return
	var rect: Rect2 = WD.region_rect(r)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = r.x * 7919 + r.y * 104729 + 31
	for i in range(34):
		var p: Vector2 = Vector2(rng.randf_range(rect.position.x + 20, rect.end.x - 20), rng.randf_range(rect.position.y + 20, minf(rect.end.y, SHORE_Y - 30.0)))
		if WD.biome_at(p) != WD.BEACH or WD.road_value(p) < 24.0 or absf(p.x - PIER_END.x) < 120.0:
			continue
		var k: float = rng.randf()
		if k < 0.3:
			world.call("put", node, r, "palm" if rng.randf() < 0.5 else "palm_b", p, 0.8, 6.0)
		elif k < 0.5:
			world.call("put", node, r, "beach_shells", p, 0.0, 0.0, Color.WHITE, false)
		elif k < 0.66:
			world.call("put", node, r, "driftwood", p, 0.0, 10.0)
		elif k < 0.76 and p.y > SHORE_Y - 400.0:
			world.call("put", node, r, "tide_rocks", p, 0.0, 22.0)


# ------------------------------------------------------------------ пирс

func _build_pier() -> void:
	# по доскам пирса можно ходить даже над морем
	(world.get("walk_rects") as Array).append(Rect2(PIER_END.x - PIER_HW, PIER_TOP, PIER_HW * 2.0, PIER_END.y - PIER_TOP + 30))
	var objs: Node2D = main.get("objects")
	var sh: Sprite2D = main.call("spr", "pier_shadow", Vector2(PIER_END.x + 6, PIER_END.y + 52), 0.0, false, main, false)
	sh.z_index = -9
	var p: Sprite2D = main.call("spr", "pier", Vector2(PIER_END.x, PIER_END.y + 40), 0.0, false, main, false)
	p.z_index = -8
	var bell: Node2D = Node2D.new()
	bell.set_script(load("res://sea_spot.gd"))
	bell.set("kind", "down")
	bell.set("sea", self)
	bell.position = PIER_END
	objs.add_child(bell)
	main.call("spr", "diving_bell", Vector2(0, 8), 0.0, false, bell, true)


# ------------------------------------------------------------------ дно

func _build_under() -> void:
	root = Node2D.new()
	root.y_sort_enabled = true
	(main.get("objects") as Node).add_child(root)
	# песчаное дно рябью
	var g: Sprite2D = Sprite2D.new()
	g.texture = load("res://art/seabed.png")
	g.centered = false
	g.region_enabled = true
	g.region_rect = Rect2(Vector2.ZERO, SIZE + Vector2(800, 600))
	g.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	g.position = ORG - Vector2(400, 300)
	g.z_index = -11
	main.add_child(g)
	# блики солнца на дне
	var cau: ColorRect = ColorRect.new()
	cau.position = ORG - Vector2(400, 300)
	cau.size = SIZE + Vector2(800, 600)
	var cm: ShaderMaterial = ShaderMaterial.new()
	cm.shader = load("res://caustics.gdshader")
	cau.material = cm
	cau.z_index = -10
	cau.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main.add_child(cau)
	# по краям — мягко уходящая в синеву глубина
	for k in range(6):
		var gr: float = float(k) * 40.0
		for r in [Rect2(-400, -300, SIZE.x + 800, 300 + 60 - gr * 0.0), Rect2(-400, SIZE.y - 20, SIZE.x + 800, 340), Rect2(-400, 0, 420, SIZE.y), Rect2(SIZE.x - 20, 0, 420, SIZE.y)]:
			var rr: Rect2 = (r as Rect2).grow(gr)
			var d: ColorRect = ColorRect.new()
			d.color = Color(0.03, 0.1, 0.2, 0.16)
			d.position = ORG + rr.position
			d.size = rr.size
			d.z_index = -9
			d.mouse_filter = Control.MOUSE_FILTER_IGNORE
			main.add_child(d)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 4242
	var towns: Node = main.get_node("Towns")
	# жемчужный дворец принцессы
	var pal: Vector2 = Vector2(960, 420)
	_put("pearl_palace", pal)
	blocks.append(Rect2(pal.x - 170, pal.y - 100, 340, 94))
	# домики полукругом: наутилусы, мозговики, башенки-рапаны
	var homes: Array = [[Vector2(380, 520), "coral_house_a"], [Vector2(1540, 520), "coral_house_b"], [Vector2(230, 860), "coral_house_c"],
		[Vector2(1690, 860), "coral_house_a"], [Vector2(560, 1060), "coral_house_b"], [Vector2(1360, 1060), "coral_house_c"], [Vector2(170, 300), "coral_house_b"], [Vector2(1750, 300), "coral_house_c"]]
	for h in homes:
		var hp: Vector2 = h[0]
		var tex: String = h[1]
		_put(tex, hp)
		var hw: float = 70.0 if tex != "coral_house_c" else 44.0
		blocks.append(Rect2(hp.x - hw, hp.y - 50, hw * 2.0, 46))
		_lamp(hp + Vector2(hw + 16.0, 6))
	# v16: старых лавок-прилавков нет; русалочки просто гуляют по площади
	for i2 in range(2):
		var sp: Vector2 = Vector2(800 + 320 * i2, 700)
		towns.call("_npc", root, "fishgirl_perla" if i2 == 0 else "fishgirl_koral", ORG + sp + Vector2(0, 26), 40.0, "")
	# площадь выложена ракушками по кругу
	for k2 in range(16):
		var a: float = TAU * float(k2) / 16.0 + 0.1
		_put("beach_shells", Vector2(960, 760) + Vector2(cos(a) * 250.0, sin(a) * 110.0))
	# водорослевые рощи и коралловые сады
	var props: Array = ["coral_0", "coral_1", "coral_2", "sea_fan", "tube_sponge", "anemone", "giant_clam", "sea_rock", "coral_0", "coral_2"]
	for i3 in range(150):
		var q: Vector2 = Vector2(rng.randf_range(60, SIZE.x - 60), rng.randf_range(150, SIZE.y - 50))
		if _near_built(q, 60.0) or q.distance_to(ARRIVE) < 110.0 or Rect2(560, 560, 800, 340).has_point(q):
			continue
		# водоросли гуще по краям, кораллы — ближе к домам
		var edge: float = minf(minf(q.x, SIZE.x - q.x), minf(q.y, SIZE.y - q.y))
		if rng.randf() < (0.75 if edge < 260.0 else 0.3):
			var kt: String = ["kelp", "kelp_1", "kelp_2"][rng.randi_range(0, 2)]
			var ks: Sprite2D = _put(kt, q)
			ks.material = main.call("wind_mat", 2.2)
			circles.append(Vector3(q.x, q.y - 2, 7))
		else:
			var pt: String = props[rng.randi_range(0, props.size() - 1)]
			_put(pt, q)
			circles.append(Vector3(q.x, q.y - 4, 22 if pt == "sea_rock" else 12))
	for i4 in range(6):
		_lamp(Vector2(600 + i4 * 144, 600 + (i4 % 2) * 260))
	# лучи света сверху
	for i5 in range(7):
		var ray: Sprite2D = Sprite2D.new()
		ray.texture = load("res://art/light_ray.png")
		ray.position = ORG + Vector2(160 + i5 * 270 + rng.randf_range(-40, 40), -20)
		ray.centered = false
		ray.offset = Vector2(-24, 0)
		ray.rotation = -0.32
		ray.scale = Vector2(rng.randf_range(1.2, 2.2), 3.4)
		ray.material = main.call("_additive")
		ray.z_index = 30
		main.add_child(ray)
		rays.append([ray, rng.randf() * TAU])
	# жерло с пузырями — дорога наверх
	var up: Node2D = Node2D.new()
	up.set_script(load("res://sea_spot.gd"))
	up.set("kind", "up")
	up.set("sea", self)
	up.position = ORG + ARRIVE + Vector2(0, 60)
	root.add_child(up)
	main.call("spr", "bubble_column", Vector2.ZERO, 0.0, false, up, false)
	circles.append(Vector3(ARRIVE.x, ARRIVE.y + 56, 18))
	var vent: CPUParticles2D = _bubble_fx(26, Vector2(8, 3), 2.6)
	vent.position = Vector2(0, -16)
	vent.emitting = true
	up.add_child(vent)
	# жительницы: принцесса у дворца, стража у дверей, остальные плавают по городу
	var ld: Node2D = towns.call("_npc", root, "fishgirl_marina", ORG + pal + Vector2(0, 60), 40.0, "лидер")
	ld.set("role", "лидер")
	swimmers.append([ld, 0.0])
	for sx in [-1.0, 1.0]:
		var gd: Node2D = towns.call("_npc", root, "fishgirl_tida", ORG + pal + Vector2(float(sx) * 70.0, 24.0), 0.0, "стража")
		gd.set("row", 0)
		gd.set("job", "post")
		swimmers.append([gd, rng.randf() * TAU])
	var walkers: Array = ["fishgirl_koral", "fishgirl_perla", "fishgirl_tida", "fishgirl_koral", "fishgirl_perla", "fishgirl_marina"]
	for i6 in range(walkers.size()):
		var wp: Vector2 = Vector2(rng.randf_range(300, 1600), rng.randf_range(620, 980))
		if is_blocked(ORG + wp):
			wp = Vector2(960, 900)
		var wn: Node2D = towns.call("_npc", root, String(walkers[i6]), ORG + wp, 220.0, "")
		swimmers.append([wn, rng.randf() * TAU])
	# стайки рыбок
	for i7 in range(5):
		var c: Vector2 = ORG + Vector2(rng.randf_range(300, 1620), rng.randf_range(250, 1050))
		var fl: Array = []
		var kind: int = rng.randi_range(0, 2)
		for j in range(rng.randi_range(6, 10)):
			var f: Sprite2D = Sprite2D.new()
			f.texture = load("res://art/sea_fish.png")
			f.region_enabled = true
			f.region_rect = Rect2(0, kind * 10, 16, 10)
			f.z_index = 25
			f.set_meta("off", Vector2(rng.randf_range(-26, 26), rng.randf_range(-14, 14)))
			f.set_meta("k", kind)
			main.add_child(f)
			fl.append(f)
		schools.append([c, rng.randf_range(90, 220), rng.randf_range(0.12, 0.25) * (1.0 if rng.randf() < 0.5 else -1.0), rng.randf() * TAU, fl])
	# пузырьки поднимаются со дна
	bubbles = _bubble_fx(70, SIZE / 2.0, 6.0)
	bubbles.position = ORG + SIZE / 2.0
	bubbles.z_index = 28
	main.add_child(bubbles)
	# пузырьки у героини
	hero_bubbles = _bubble_fx(5, Vector2(2, 1), 2.4)
	hero_bubbles.position = Vector2(4, -46)
	hero_bubbles.z_index = 3
	(main.get("player") as Node2D).add_child(hero_bubbles)
	for r in rays:
		(r[0] as Sprite2D).visible = false
	for sc in schools:
		for f in sc[4]:
			(f as Sprite2D).visible = false


func _bubble_fx(n: int, ext: Vector2, life: float) -> CPUParticles2D:
	var b: CPUParticles2D = CPUParticles2D.new()
	b.texture = load("res://art/fx_firefly.png")
	b.amount = n
	b.lifetime = life
	b.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	b.emission_rect_extents = ext
	b.gravity = Vector2(0, -22)
	b.initial_velocity_min = 2.0
	b.initial_velocity_max = 8.0
	b.direction = Vector2(0, -1)
	b.spread = 20.0
	b.scale_amount_min = 0.35
	b.scale_amount_max = 0.8
	b.color = Color(0.85, 0.97, 1.0, 0.7)
	b.emitting = false
	return b


func _process(delta: float) -> void:
	if not diving:
		return
	t += delta
	for r in rays:
		var s: Sprite2D = r[0]
		s.modulate.a = 0.45 + sin(t * 0.5 + float(r[1])) * 0.25
		s.rotation = -0.32 + sin(t * 0.21 + float(r[1])) * 0.03
	for sc in schools:
		var c: Vector2 = sc[0]
		var rad: float = sc[1]
		var sp: float = sc[2]
		sc[3] = float(sc[3]) + sp * delta
		var a: float = sc[3]
		var lead: Vector2 = c + Vector2(cos(a) * rad, sin(a) * rad * 0.5)
		var vel: Vector2 = Vector2(-sin(a), cos(a) * 0.5) * sp
		for f in sc[4]:
			var fs: Sprite2D = f
			var off: Vector2 = fs.get_meta("off")
			fs.position = (lead + off + Vector2(sin(t * 1.3 + off.x) * 3.0, cos(t * 1.1 + off.y) * 2.0)).round()
			fs.flip_h = vel.x > 0.0
			var fr: int = int(t * 6.0 + off.x) % 2
			fs.region_rect = Rect2(fr * 16, int(fs.get_meta("k")) * 10, 16, 10)
	# русалки плавают: покачиваются над дном
	for sw in swimmers:
		var nd: Node2D = sw[0]
		if not is_instance_valid(nd):
			continue
		var sp2: Sprite2D = nd.get("spr")
		if sp2 != null:
			sp2.offset.y = -157.0 - 4.0 + sin(t * 1.8 + float(sw[1])) * 2.0


func _put(tex: String, p: Vector2) -> Sprite2D:
	return main.call("spr", tex, ORG + p, 0.0, false, root, false)


func _lamp(p: Vector2) -> void:
	_put("shell_lamp", p)
	circles.append(Vector3(p.x, p.y - 2, 8))
	var s: Sprite2D = Sprite2D.new()
	s.texture = load("res://art/fx_glow.png")
	s.position = ORG + p + Vector2(0, -28)
	s.scale = Vector2.ONE * 0.6
	s.modulate = Color(1.0, 0.92, 0.6, 0.6)
	s.material = main.call("_additive")
	root.add_child(s)


func _near_built(q: Vector2, r: float) -> bool:
	for b in blocks:
		if (b as Rect2).grow(r).has_point(q):
			return true
	for c in circles:
		var cv: Vector3 = c
		if q.distance_to(Vector2(cv.x, cv.y)) < r * 0.5 + cv.z:
			return true
	return false


## Можно ли проплыть в точке p (координаты мира)
func is_blocked(p: Vector2) -> bool:
	var l: Vector2 = p - ORG
	if l.x < 60.0 or l.y < 150.0 or l.x > SIZE.x - 60.0 or l.y > SIZE.y - 50.0:
		return true
	for b in blocks:
		if (b as Rect2).has_point(l):
			return true
	for c in circles:
		var cv: Vector3 = c
		if (l.x - cv.x) * (l.x - cv.x) + (l.y - cv.y) * (l.y - cv.y) < cv.z * cv.z:
			return true
	return false


# ------------------------------------------------------------------ спуск и подъём

func dive() -> void:
	if diving or Game.busy:
		return
	Sound.play("water", -2.0)
	main.call("_transition", func() -> void:
		set_diving(true)
		var pl: Node2D = main.get("player")
		pl.position = ORG + ARRIVE
		pl.set("facing", 0)
		Sound.play("bubble", -4.0))


func surface() -> void:
	if not diving or Game.busy:
		return
	Sound.play("bubble", -2.0)
	main.call("_transition", func() -> void:
		set_diving(false)
		var pl: Node2D = main.get("player")
		pl.position = PIER_END + Vector2(0, -40)
		pl.set("facing", 3)
		Sound.play("water", -6.0))


func set_diving(on: bool) -> void:
	diving = on
	_limits(on)
	bubbles.emitting = on
	hero_bubbles.emitting = on
	for r in rays:
		(r[0] as Sprite2D).visible = on
	for sc in schools:
		for f in sc[4]:
			(f as Sprite2D).visible = on


func _limits(on: bool) -> void:
	var cam: Camera2D = main.get("cam")
	if on:
		cam.limit_left = int(ORG.x)
		cam.limit_top = int(ORG.y)
		cam.limit_right = int(ORG.x + SIZE.x)
		cam.limit_bottom = int(ORG.y + SIZE.y)
	else:
		main.call("_world_limits")
	cam.reset_smoothing()


# ------------------------------------------------------------------ v22: открытое море (плавать можно только в хвосте русалки)

## Травы по глубине: мелкие ближе к берегу, редкие — на глубине. [id, от какой глубины (0..1), до какой]
const DEPTH: Array = [
	["sea_lettuce", 0.0, 0.6], ["eelgrass", 0.0, 0.7], ["kelp_gold", 0.0, 0.8], ["sea_grape", 0.05, 0.8], ["storm_weed", 0.05, 0.9],
	["sea_anemone", 0.1, 0.9], ["pearl_moss", 0.15, 1.0], ["coral_bloom", 0.2, 1.0], ["star_coral", 0.3, 1.0], ["glow_algae", 0.25, 1.0],
	["ice_algae", 0.45, 1.0], ["mermaid_hair", 0.5, 1.0], ["abyss_kelp", 0.6, 1.0], ["siren_lily", 0.6, 1.0], ["tide_orchid", 0.7, 1.0], ["pearl_flower", 0.75, 1.0],
]
const OPEN_TOP: float = 7640.0
const OPEN_BOTTOM: float = 8960.0


func _depth_of(y: float) -> float:
	return clampf((y - OPEN_TOP) / (OPEN_BOTTOM - OPEN_TOP), 0.0, 1.0)


## Блики света на всём морском дне у берега: одна широкая полоса
func _build_open_sea() -> void:
	var x0: float = float(WD.GX0 * WD.RW)
	var cau: ColorRect = ColorRect.new()
	cau.position = Vector2(x0, OPEN_TOP)
	cau.size = Vector2(float(WD.GRID[0].size() * WD.RW), OPEN_BOTTOM - OPEN_TOP)
	var cm: ShaderMaterial = ShaderMaterial.new()
	cm.shader = load("res://caustics.gdshader")
	cau.material = cm
	cau.modulate = Color(1, 1, 1, 0.55)
	cau.z_index = -9
	cau.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main.add_child(cau)


func _open_sea_region(node: Node2D, r: Vector2i) -> void:
	if WD.biome_of_region(r) != WD.SEA:
		return
	var rect: Rect2 = WD.region_rect(r)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = r.x * 7331 + r.y * 90017 + 515
	var top: float = maxf(rect.position.y, OPEN_TOP) + 30.0
	var bot: float = minf(rect.end.y, OPEN_BOTTOM) - 40.0
	var tint: Color = Color(0.82, 0.96, 1.05, 0.95)
	var props: Array = ["kelp", "kelp_1", "kelp_2", "coral_0", "coral_1", "coral_2", "sea_fan", "tube_sponge", "anemone", "sea_rock", "kelp", "kelp_1"]
	# кораллы, водоросли и камни дна
	for i in range(150):
		var p: Vector2 = Vector2(rng.randf_range(rect.position.x + 20.0, rect.end.x - 20.0), rng.randf_range(top, bot)).round()
		if _near_pier(p):
			continue
		var tex: String = String(props[rng.randi_range(0, props.size() - 1)])
		var sp: Sprite2D = world.call("put", node, r, tex, p, 0.0, 0.0, tint, false)
		if tex.begins_with("kelp"):
			sp.material = main.call("wind_mat", 2.2)
	# жемчужницы: E — открыть, в них ракушки и жемчуг
	for i2 in range(9):
		var cp: Vector2 = Vector2(rng.randf_range(rect.position.x + 40.0, rect.end.x - 40.0), rng.randf_range(top + 60.0, bot)).round()
		if _near_pier(cp):
			continue
		var cs: Sprite2D = world.call("put", node, r, "giant_clam", cp, 0.0, 0.0, tint, false)
		var cn: Node2D = Node2D.new()
		cn.set_script(load("res://mat_node.gd"))
		cn.position = cp
		node.add_child(cn)
		cn.call("setup", "clam", cs)
	# места подводных трав: чем глубже, тем реже и ценнее
	var wm: Material = main.call("wind_mat", 1.6)
	for i3 in range(58):
		var hp: Vector2 = Vector2(rng.randf_range(rect.position.x + 30.0, rect.end.x - 30.0), rng.randf_range(top + 20.0, bot)).round()
		if _near_pier(hp):
			continue
		var dp: float = _depth_of(hp.y)
		var opts: Array = []
		for d in DEPTH:
			if dp >= float(d[1]) and dp <= float(d[2]):
				var w: float = float(preload("res://herbs_db.gd").DATA[String(d[0])].get("rare", 1.0))
				opts.append([String(d[0]), w])
		if opts.is_empty():
			continue
		var hn: Node2D = Node2D.new()
		hn.set_script(load("res://herb_spot.gd"))
		hn.set("sea_spot", true)
		node.add_child(hn)
		hn.call("setup", hp, opts, 0.85, wm)
	# стайки рыбок над дном
	for i4 in range(4):
		var fc: Vector2 = Vector2(rng.randf_range(rect.position.x + 150.0, rect.end.x - 150.0), rng.randf_range(top + 40.0, bot - 40.0))
		var fn: Node2D = Node2D.new()
		fn.set_script(load("res://sea_fish.gd"))
		node.add_child(fn)
		fn.call("setup", fc, rng.randi_range(0, 2), rng.randf_range(70.0, 160.0), rng.randi())


## Возле пирса не ставим ничего: с досок руками до дна не достать
func _near_pier(p: Vector2) -> bool:
	return absf(p.x - PIER_END.x) < 150.0 and p.y < PIER_END.y + 110.0

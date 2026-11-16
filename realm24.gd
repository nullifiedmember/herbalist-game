extends Node
## v24: два мира за порталами — Пеклоград (Ад, город демониц) и Облакоград (Рай, город ангелиц).
## Это не подземелье, а свои города: улицы, площадь с фонтаном, дворец владычицы, дома (в них можно зайти),
## таверна, лавки, жительницы с разговорами. Миры не дружат, но и не воюют — об этом говорят жительницы.
## Приколы: в Аду бесята воруют монетку (догони — вернёт с лихвой), лавовый фонтан «желаний наоборот»;
## в Раю — фонтан желаний (монетка → благословение) и облака-батуты.
## Вход: врата у Сумеречья (Ад) и у долины магов (Рай), и старый портал из пекла-подземелья.

const T = preload("res://talk24_db.gd")
const ORGS: Dictionary = {"hell": Vector2(0, -200000), "heaven": Vector2(0, -300000)}
const SIZE: Vector2 = Vector2(2800, 2000)
const GATES: Dictionary = {"hell": Vector2(2050, -3720), "heaven": Vector2(10000, -2620)}
const CENTER: Vector2 = Vector2(1400, 1050)

var main: Node2D
var roots: Dictionary = {}           # мир -> узел
var circles: Dictionary = {}         # мир -> [Vector3]
var rects: Dictionary = {}           # мир -> [Rect2]
var active: String = ""
var back_to: Vector2 = Vector2.ZERO
var imps: Array = []
var t: float = 0.0
var gates: Array = []


func setup(m: Node2D) -> void:
	main = m
	add_to_group("realm24")
	# врата в обычном мире
	for k in ([] if Game.SOLO else GATES.keys()):     # v29: врат в Ад и Рай пока нет
		var g: Node2D = Node2D.new()
		g.set_script(load("res://realm_gate24.gd"))
		g.position = GATES[k]
		g.set("realm", String(k))
		g.set("mgr", self)
		(main.get("objects") as Node).add_child(g)
		gates.append(g)


func org() -> Vector2:
	return ORGS.get(active, Vector2.ZERO)


func in_realm(p: Vector2) -> bool:
	return p.y < -150000.0


# ------------------------------------------------------------------ вход / выход

func enter(which: String, from: Vector2) -> void:
	if Game.busy:
		return
	if active == "":
		back_to = from
	if not roots.has(which):
		_build(which)
	await main.call("_transition", func() -> void:
		main.call("_leave_special_states")
		for k in roots.keys():
			(roots[k] as Node2D).visible = k == which
			(roots[k] as Node2D).process_mode = Node.PROCESS_MODE_INHERIT if k == which else Node.PROCESS_MODE_DISABLED
		active = which
		Game.realm = which
		var pl: Node2D = main.get("player")
		pl.position = ORGS[which] + Vector2(CENTER.x, SIZE.y - 230)
		pl.set("facing", 1)
		_cam())
	Sound.play("magic", -2.0)
	Game.toast.emit("Пеклоград" if which == "hell" else "Облакоград", load("res://art/realm_portal_%s.png" % which))
	if not Game.places_seen.has("realm_" + which):
		Game.places_seen["realm_" + which] = true
		Game.chron("Шагнула в портал и попала в %s." % ("Пеклоград — город демониц" if which == "hell" else "Облакоград — город ангелиц"), "travel")


func leave() -> void:
	if active == "" or Game.busy:
		return
	await main.call("_transition", func() -> void:
		var r: Node2D = roots[active]
		r.visible = false
		r.process_mode = Node.PROCESS_MODE_DISABLED
		active = ""
		Game.realm = ""
		var pl: Node2D = main.get("player")
		var w: Node = main.get("world")
		w.call("build_around", back_to)
		pl.position = main.call("free_near", back_to + Vector2(0, 40))
		pl.set("facing", 0)
		main.call("_world_limits")
		(main.get("cam") as Camera2D).reset_smoothing())
	Sound.play("magic", -6.0)


func _cam() -> void:
	var cam: Camera2D = main.get("cam")
	var o: Vector2 = org()
	cam.limit_left = int(o.x)
	cam.limit_top = int(o.y)
	cam.limit_right = int(o.x + SIZE.x)
	cam.limit_bottom = int(o.y + SIZE.y)
	cam.reset_smoothing()


# ------------------------------------------------------------------ преграды

func is_blocked(p: Vector2) -> bool:
	if active == "":
		return true
	var l: Vector2 = p - org()
	if l.x < 40.0 or l.y < 120.0 or l.x > SIZE.x - 40.0 or l.y > SIZE.y - 40.0:
		return true
	for r in rects.get(active, []):
		if (r as Rect2).has_point(l):
			return true
	for c in circles.get(active, []):
		var cv: Vector3 = c
		if (l.x - cv.x) * (l.x - cv.x) + (l.y - cv.y) * (l.y - cv.y) < cv.z * cv.z:
			return true
	return false


# ------------------------------------------------------------------ постройка мира

func _spr(root: Node2D, tex: String, at: Vector2, cast: bool = true) -> Sprite2D:
	return main.call("spr", tex, at, 0.0, false, root, cast) as Sprite2D


func _ground(root: Node2D, tex: String, r: Rect2, z: int) -> void:
	var s: Sprite2D = Sprite2D.new()
	s.texture = load("res://art/%s.png" % tex)
	s.centered = false
	s.region_enabled = true
	s.region_rect = Rect2(Vector2.ZERO, r.size)
	s.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	s.position = r.position
	s.z_index = z
	root.add_child(s)


func _build(which: String) -> void:
	var root: Node2D = Node2D.new()
	root.name = "Realm_" + which
	(main.get("objects") as Node).add_child(root)
	roots[which] = root
	circles[which] = []
	rects[which] = []
	var o: Vector2 = ORGS[which]
	var hell: bool = which == "hell"
	var rnd: RandomNumberGenerator = RandomNumberGenerator.new()
	rnd.seed = 24 if hell else 42
	_ground(root, "realm_hell_ground" if hell else "realm_heaven_ground", Rect2(o, SIZE), -20)
	# улицы: главная с юга на север и поперечная через площадь
	var st: String = "realm_hell_street" if hell else "realm_heaven_street"
	_ground(root, st, Rect2(o + Vector2(CENTER.x - 70, 380), Vector2(140, SIZE.y - 420)), -19)
	_ground(root, st, Rect2(o + Vector2(220, CENTER.y - 60), Vector2(SIZE.x - 440, 120)), -19)
	_ground(root, st, Rect2(o + CENTER - Vector2(260, 200), Vector2(520, 400)), -19)
	# дворец на севере
	var pal: String = "realm_%s_palace" % which
	_building(which, root, pal, o + Vector2(CENTER.x, 560), 240.0, "palace", "demon_mora" if hell else "angel_serafima")
	# фонтан в центре площади
	var fnt: Sprite2D = _spr(root, "realm_%s_fountain" % which, o + CENTER + Vector2(0, 30))
	(circles[which] as Array).append(Vector3(CENTER.x, CENTER.y + 22, 44))
	var fn: Node2D = Node2D.new()
	fn.set_script(load("res://realm_thing24.gd"))
	fn.position = o + CENTER + Vector2(0, 52)
	fn.set("kind", "fountain_" + which)
	fn.set("mgr", self)
	root.add_child(fn)
	main.call("add_glow", o + CENTER + Vector2(0, -10), 1.2, 0.6)
	# дома вдоль улиц
	var spots: Array = [Vector2(700, 760), Vector2(2100, 760), Vector2(560, 1420), Vector2(2240, 1420), Vector2(900, 1700), Vector2(1900, 1700), Vector2(420, 1060), Vector2(2380, 1060)]
	var tex_a: String = "realm_%s_house_a" % which
	var tex_b: String = "realm_%s_house_b" % which
	var looks: Array = ["demon_ruby", "demon_nyx", "demon_iskra", "demon_lavi", "demon_kira"] if hell else ["angel_lucia", "angel_mel", "angel_nimbi", "angel_celi", "angel_aurora"]
	for i in range(spots.size()):
		var sp: Vector2 = spots[i]
		var kind: String = "home"
		var tx: String = tex_a if i % 2 == 0 else tex_b
		if i == 6:
			tx = "realm_%s_tavern" % which
			kind = "tavern"
		_building(which, root, tx, o + sp, 120.0 if not tx.ends_with("tavern") else 150.0, kind, String(looks[i % looks.size()]))
	# лавки у площади
	var stall_tex: String = "realm_%s_stall" % which
	for k in range(2):
		var sx: float = CENTER.x + (-200.0 if k == 0 else 200.0)
		_spr(root, stall_tex, o + Vector2(sx, CENTER.y + 150))
		(rects[which] as Array).append(Rect2(sx - 30, CENTER.y + 136, 60, 14))
	# украшения
	for n in range(26):
		var p: Vector2 = Vector2(rnd.randf_range(120, SIZE.x - 120), rnd.randf_range(260, SIZE.y - 120))
		if absf(p.x - CENTER.x) < 140.0 or absf(p.y - CENTER.y) < 120.0 or p.distance_to(CENTER) < 330.0:
			continue
		if _near_building(which, p, 90.0):
			continue
		var roll: float = rnd.randf()
		if hell:
			if roll < 0.35:
				_spr(root, "realm_lava_pool", o + p, false).z_index = -15
				(circles[which] as Array).append(Vector3(p.x, p.y - 17, 30))
				main.call("add_glow", o + p - Vector2(0, 16), 1.0, 0.7)
			elif roll < 0.75:
				_spr(root, "realm_obsidian", o + p)
				(circles[which] as Array).append(Vector3(p.x, p.y - 2, 8))
			else:
				_spr(root, "realm_brazier", o + p)
				(circles[which] as Array).append(Vector3(p.x, p.y - 2, 7))
				main.call("add_glow", o + p - Vector2(0, 36), 0.7, 0.6)
		else:
			if roll < 0.45:
				var cb: Sprite2D = _spr(root, "realm_cloud_bush", o + p)
				var bn: Node2D = Node2D.new()
				bn.set_script(load("res://realm_thing24.gd"))
				bn.position = o + p + Vector2(0, 8)
				bn.set("kind", "cloud")
				bn.set("mgr", self)
				bn.set_meta("spr", cb)
				root.add_child(bn)
			elif roll < 0.7:
				_spr(root, "realm_crystal", o + p)
				(circles[which] as Array).append(Vector3(p.x, p.y - 2, 8))
			else:
				_spr(root, "realm_harp", o + p)
				(circles[which] as Array).append(Vector3(p.x, p.y - 2, 12))
	# фонари вдоль главной улицы
	for y in range(500, int(SIZE.y) - 200, 220):
		for sd in [-1.0, 1.0]:
			var lp: Vector2 = Vector2(CENTER.x + sd * 100.0, float(y))
			if absf(lp.y - CENTER.y) < 220.0:
				continue
			_spr(root, "realm_brazier" if hell else "elf_lantern", o + lp)
			main.call("add_glow", o + lp - Vector2(0, 36 if hell else 40), 0.6, 0.55)
	if not hell:
		var rb: Sprite2D = _spr(root, "realm_rainbow", o + Vector2(CENTER.x, 380), false)
		rb.z_index = -18
		rb.modulate.a = 0.55
	# портал назад
	var pt: Node2D = Node2D.new()
	pt.set_script(load("res://realm_thing24.gd"))
	pt.position = o + Vector2(CENTER.x, SIZE.y - 150)
	pt.set("kind", "portal_back")
	pt.set("mgr", self)
	root.add_child(pt)
	_spr(root, "realm_portal_%s" % which, pt.position)
	(circles[which] as Array).append(Vector3(CENTER.x, SIZE.y - 152, 22))
	main.call("add_glow", pt.position - Vector2(0, 46), 1.3, 0.7)
	# жительницы
	_people(which, root)
	if hell:
		for i in range(5):
			_imp(root, o + Vector2(rnd.randf_range(300, SIZE.x - 300), rnd.randf_range(500, SIZE.y - 300)))
	root.visible = false
	root.process_mode = Node.PROCESS_MODE_DISABLED


func _near_building(which: String, p: Vector2, pad: float) -> bool:
	for r in rects[which]:
		if (r as Rect2).grow(pad).has_point(p):
			return true
	return false


func _building(which: String, root: Node2D, tex: String, at: Vector2, w: float, kind: String, owner: String) -> void:
	_spr(root, tex, at)
	var o: Vector2 = ORGS[which]
	var l: Vector2 = at - o
	(rects[which] as Array).append(Rect2(l.x - w / 2.0, l.y - 46.0, w, 40.0))
	var d: Node2D = Node2D.new()
	d.set_script(load("res://house_door.gd"))
	d.position = at + Vector2(0, 6)
	d.set("kind", kind)
	d.set("private", false)
	d.set("land", which)
	d.set("open_from", 7.0)
	d.set("open_to", 23.0)
	d.set("seed_k", int(at.x) + int(at.y) * 3)
	d.set("owner_tex", owner)
	d.set("owner_name", String(preload("res://npc_db.gd").person(owner)[0]))
	root.add_child(d)


func _people(which: String, root: Node2D) -> void:
	var o: Vector2 = ORGS[which]
	var hell: bool = which == "hell"
	var list: Array = [
		["demon_mora" if hell else "angel_serafima", Vector2(CENTER.x, 640), "лидер", 40.0, []],
		["demon_iskra" if hell else "angel_mel", Vector2(CENTER.x - 200, CENTER.y + 182), "торговец", 10.0,
			["chocolate", "kebab", "pomegranate_juice", "toffee", "bell_pepper"] if hell else ["dew_honey", "flower_nectar", "star_tea", "cake_strawberry", "sugar_cookie"]],
		["demon_ruby" if hell else "angel_aurora", Vector2(CENTER.x + 200, CENTER.y + 182), "торговец", 10.0,
			["roast_meat", "gingerbread", "goblin_fizz", "cinnamon_bun"] if hell else ["yogurt", "mead", "pancakes", "berry_compote"]],
		["demon_nyx" if hell else "angel_lucia", CENTER + Vector2(-260, -160), "житель", 180.0, []],
		["demon_lavi" if hell else "angel_nimbi", CENTER + Vector2(300, 260), "житель", 220.0, []],
		["demon_kira" if hell else "angel_celi", Vector2(CENTER.x + 120, SIZE.y - 240), "стража", 60.0, []],
	]
	for e in list:
		var c: Node2D = Node2D.new()
		c.set_script(load("res://catgirl.gd"))
		root.add_child(c)
		c.call("setup", String(e[0]), o + (e[1] as Vector2))
		c.set("role", String(e[2]))
		c.set("roam", float(e[3]))
		c.set("land", which)
		c.set("blocked", Callable(main, "is_blocked"))
		c.set("home_door", o + (e[1] as Vector2) + Vector2(0, -10))
		c.set("bed_h", 25.0)        # в своих мирах не спят: ночь у них — как день
		c.set("wake_h", -1.0)
		if not (e[4] as Array).is_empty():
			c.set_meta("goods", e[4])
			c.set("job", "post")
		var sp: Sprite2D = c.get("spr") as Sprite2D
		main.call("add_caster", sp, true)
		sp.material = main.call("char_light_mat", Vector2(8, 8), sp)
		var fm: ShaderMaterial = main.call("char_light_mat", Vector2(1, 1), sp)
		fm.set_shader_parameter("region_mode", true)
		(c.get("face") as Sprite2D).material = fm
		c.set("face_mat", fm)


# ------------------------------------------------------------------ бесята-воришки (Ад)

func _imp(root: Node2D, at: Vector2) -> void:
	var s: Sprite2D = Sprite2D.new()
	s.texture = load("res://art/realm_imp.png")
	s.hframes = 4
	s.position = at
	s.offset = Vector2(0, -12)
	root.add_child(s)
	imps.append({"spr": s, "goal": at, "t": 0.0, "stole": 0, "cd": randf_range(10, 30)})


func _process(delta: float) -> void:
	if active == "":
		return
	t += delta
	if active == "hell":
		_imps(delta)


func _imps(delta: float) -> void:
	var pl: Node2D = main.get("player")
	for im in imps:
		var s: Sprite2D = im["spr"]
		im["cd"] = float(im["cd"]) - delta
		var goal: Vector2 = im["goal"]
		var near: float = s.position.distance_to(pl.global_position)
		if int(im["stole"]) > 0:
			# убегает от героини
			goal = s.position + (s.position - pl.global_position).normalized() * 80.0
			if near < 26.0:
				# поймала! монетка назад и ещё сверху
				Game.add_coins(int(im["stole"]) + randi_range(2, 6))
				Sound.play("squeak", -2.0, 0.2, s.position)
				Game.fx.emit(s.position + Vector2(0, -16), "sparkle")
				pl.call("react", "happy", 1.2)
				im["stole"] = 0
				im["cd"] = randf_range(40, 80)
		elif float(im["cd"]) <= 0.0 and near < 260.0:
			goal = pl.global_position
			if near < 18.0 and Game.coins > 0:
				var n: int = mini(Game.coins, randi_range(1, 4))
				Game.coins -= n
				Game.inventory_changed.emit()
				im["stole"] = n
				Sound.play("squeak", 0.0, 0.3, s.position)
				pl.call("react", "surprised", 1.4)
		elif s.position.distance_to(goal) < 6.0 or randf() < delta * 0.2:
			goal = s.position + Vector2(randf_range(-160, 160), randf_range(-120, 120))
		im["goal"] = goal
		var spd: float = 95.0 if int(im["stole"]) > 0 else 60.0
		var np: Vector2 = s.position.move_toward(goal, spd * delta)
		if not is_blocked(np):
			s.position = np
		else:
			im["goal"] = s.position + Vector2(randf_range(-100, 100), randf_range(-100, 100))
		s.frame = int(t * 10.0) % 4
		s.flip_h = goal.x < s.position.x
		s.z_index = 1


# ------------------------------------------------------------------ фонтаны, облака, портал

func use_thing(n: Node2D) -> void:
	var kind: String = String(n.get("kind"))
	var pl: Node2D = main.get("player")
	match kind:
		"portal_back":
			leave()
		"fountain_heaven":
			if Game.coins <= 0:
				pl.call("react", "sad", 1.0)
				return
			Game.coins -= 1
			Game.inventory_changed.emit()
			Sound.play("coin", -4.0)
			Game.fx.emit(n.global_position + Vector2(0, -30), "sparkle")
			var r: int = randi() % 4
			match r:
				0:
					Game.buff_t = maxf(Game.buff_t, 120.0)
					Game.toast.emit("Лёгкость! Ноги сами несут", load("res://art/fx_heart.png"))
				1:
					Game.fatigue = 0.0
					Game.toast.emit("Усталость как рукой сняло", load("res://art/fx_heart.png"))
				2:
					Game.add_item("food_dew_honey")
					Game.toast.emit("Из фонтана выплыла баночка мёда", load("res://art/fx_heart.png"))
				_:
					Game.add_coins(3)
					Game.toast.emit("Фонтан вернул монетку... и ещё две", load("res://art/coin.png"))
			pl.call("react", "happy", 1.4)
		"fountain_hell":
			Sound.play("fire", -4.0)
			Game.fx.emit(pl.global_position + Vector2(0, -50), "sparks")
			var r2: int = randi() % 4
			match r2:
				0:
					Game.toast.emit("Глотнула из лавового фонтана. Из ушей пошёл дымок!", load("res://art/realm_brazier.png"))
					pl.call("react", "surprised", 2.0)
					Game.fx.emit(pl.global_position + Vector2(0, -60), "steam")
				1:
					Game.thirst = minf(1.0, Game.thirst + 0.4)
					Game.toast.emit("Острое! Теперь очень хочется пить", load("res://art/realm_brazier.png"))
					pl.call("react", "pout", 2.0)
				2:
					Game.buff_t = maxf(Game.buff_t, 90.0)
					Game.toast.emit("Огонь в крови! Бежится быстрее", load("res://art/realm_brazier.png"))
					pl.call("react", "happy", 1.4)
				_:
					Game.add_item("food_chocolate")
					Game.toast.emit("Фонтан выплюнул шоколадку. Горячую.", load("res://art/realm_brazier.png"))
		"cloud":
			# облако-батут: подпрыгнуть высоко
			var spr: Sprite2D = pl.get("sprite")
			var tw: Tween = pl.create_tween()
			tw.tween_property(spr, "position:y", spr.position.y - 60.0, 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
			tw.tween_property(spr, "position:y", spr.position.y, 0.4).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BOUNCE)
			Sound.play("squeak", -6.0, 0.3)
			pl.call("react", "happy", 1.4)
			var cs: Sprite2D = n.get_meta("spr")
			if cs != null:
				var tw2: Tween = cs.create_tween()
				tw2.tween_property(cs, "scale", Vector2(1.15, 0.8), 0.12)
				tw2.tween_property(cs, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_ELASTIC)

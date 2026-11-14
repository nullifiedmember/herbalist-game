extends Node
## Клуб «Старлит» (отсылка на «Одинокого рокера»): у окраины деревни кошек — узкий проход,
## лестница вниз с неоновой вывеской. Внизу живой клуб: занавес, сцена, барабаны, усилители,
## бар. На сцене группа «Кизуна Бэнд» (Бокки, Нико, Рио, Икка), у бара хозяйка Сэйко,
## у пульта звукорежиссёр Пэй и подвыпившая Куки за столиком.
## Клуб лежит далеко от мира (как дно моря и комнаты домов); вход и выход — лестницы.

const WD = preload("res://world_data.gd")
const ORG: Vector2 = Vector2(-80000, 0)
const SIZE: Vector2 = Vector2(640, 360)
const ARRIVE: Vector2 = Vector2(320, 296)
const STAIRS_AT: Vector2 = Vector2(320, 330)
# кандидаты места входа (окраина деревни кошек, регион (0,3))
const CANDS: Array = [Vector2(1760, 4640), Vector2(1700, 4880), Vector2(1760, 4400), Vector2(240, 4940), Vector2(1180, 4980), Vector2(1760, 4180)]

static var ent_pos: Vector2 = Vector2.INF

var main: Node2D
var world: Node2D
var active: bool = false
var root: Node2D
var blocks: Array = []
var lights: Array = []          # [спрайт, фаза, база альфы]
var rockers: Array = []
var t: float = 0.0
var door_out: Node2D


func setup(m: Node2D, w: Node2D) -> void:
	main = m
	world = w
	add_to_group("livehouse")
	(world.get("region_hooks") as Array).append(Callable(self, "_region"))
	_build_room()


func is_blocked(p: Vector2) -> bool:
	var l: Vector2 = p - ORG
	if l.x < 16.0 or l.x > 624.0 or l.y < 176.0 or l.y > 336.0:
		return true
	for r in blocks:
		if (r as Rect2).has_point(l):
			return true
	return false


# ------------------------------------------------------------------ вход с улицы

func _region(node: Node2D, r: Vector2i) -> void:
	if ent_pos != Vector2.INF:
		return
	var home_r: Vector2i = Vector2i(int(floor((CANDS[0] as Vector2).x / float(WD.RW))), int(floor((CANDS[0] as Vector2).y / float(WD.RH))))
	if r != home_r:
		return
	var at: Vector2 = CANDS[0]
	for c in CANDS:
		var cv: Vector2 = c
		var ok: bool = true
		for o in [Vector2(-100, -60), Vector2(0, -60), Vector2(100, -60), Vector2(0, 0), Vector2(-100, 0), Vector2(100, 0)]:
			if not bool(world.call("free_at", cv + (o as Vector2), 50.0)):
				ok = false
				break
		if ok:
			at = cv
			break
	ent_pos = at
	_build_entrance(node, r, at)


func _build_entrance(node: Node2D, r: Vector2i, p: Vector2) -> void:
	world.call("reserve", Rect2(p - Vector2(150, 230), Vector2(300, 280)))
	var s: Sprite2D = world.call("put", node, r, "live_entrance", p, 0.0, 0.0, Color.WHITE, true) as Sprite2D
	s.flip_h = false
	world.call("add_block_rect", Rect2(p.x - 122, p.y - 200, 88, 186))
	world.call("add_block_rect", Rect2(p.x + 34, p.y - 200, 88, 186))
	world.call("add_block_rect", Rect2(p.x - 34, p.y - 200, 68, 186))
	world.call("add_block_rect", Rect2(p.x - 118, p.y - 60, 60, 60))   # доска-меню
	# неоновый отсвет вывески и окошко внутри
	_glow_at(node, p + Vector2(0, -160), Color(1.0, 0.3, 0.65), 0.9)
	_glow_at(node, p + Vector2(-34, -160), Color(0.3, 0.8, 1.0), 0.35)
	_glow_at(node, p + Vector2(34, -160), Color(1.0, 0.85, 0.3), 0.35)
	var d: Node2D = Node2D.new()
	d.set_script(load("res://live_door.gd"))
	d.position = p + Vector2(0, -2)
	d.set("kind", "down")
	d.set("club", self)
	node.add_child(d)


func _glow_at(node: Node2D, at: Vector2, col: Color, k: float) -> void:
	var s: Sprite2D = Sprite2D.new()
	s.texture = load("res://art/fx_glow.png")
	s.position = at
	s.scale = Vector2.ONE * k
	s.modulate = Color(col.r, col.g, col.b, 0.0)
	s.material = main.call("_additive")
	(main.get("fx_layer") as Node).add_child(s)
	(main.get("glows") as Array).append([s, 0.6])


# ------------------------------------------------------------------ клуб внутри

func _put(tex: String, p: Vector2) -> Sprite2D:
	return main.call("spr", tex, ORG + p, 0.0, false, null, false) as Sprite2D


func _build_room() -> void:
	root = Node2D.new()
	root.name = "LiveRoom"
	main.add_child(root)
	var void_r: ColorRect = ColorRect.new()
	void_r.color = Color("120c18")
	void_r.position = ORG + Vector2(-400, -300)
	void_r.size = Vector2(1440, 900)
	void_r.z_index = -11
	root.add_child(void_r)
	var fl: Sprite2D = Sprite2D.new()
	fl.texture = load("res://art/live_room.png")
	fl.centered = false
	fl.position = ORG
	fl.z_index = -10
	root.add_child(fl)
	# стена и сцена
	_put("live_neon", Vector2(60, 70))
	_put("live_poster_a", Vector2(30, 122))
	_put("live_poster_b", Vector2(72, 122))
	_put("live_poster_b", Vector2(572, 122))
	_put("live_poster_a", Vector2(612, 122))
	_put("live_drums", Vector2(205, 116))
	_put("live_amp_a", Vector2(124, 120))
	_put("live_amp_b", Vector2(150, 120))
	_put("live_amp_a", Vector2(514, 120))
	_put("live_guitar", Vector2(486, 124))
	_put("live_monitor", Vector2(270, 134))
	_put("live_monitor", Vector2(340, 136))
	_put("live_monitor", Vector2(410, 134))
	_put("live_mic", Vector2(350, 130))
	_put("live_mic", Vector2(300, 128))
	# бар слева, столики справа
	_put("live_bar", Vector2(95, 206))
	_put("live_table", Vector2(440, 240))
	_put("live_stool", Vector2(416, 246))
	_put("live_stool", Vector2(466, 248))
	_put("live_table", Vector2(540, 290))
	_put("live_stool", Vector2(516, 296))
	_put("live_table", Vector2(150, 290))
	_put("live_stool", Vector2(126, 296))
	_put("live_stool", Vector2(176, 298))
	_put("live_amp_b", Vector2(596, 204))     # пульт звукорежиссёра
	_put("live_stairs", Vector2(320, 360))
	blocks = [
		Rect2(96, 0, 448, 162),         # сцена
		Rect2(10, 150, 170, 62),        # бар
		Rect2(424, 226, 32, 16),
		Rect2(524, 276, 32, 16),
		Rect2(134, 276, 32, 16),
		Rect2(578, 170, 44, 38),        # пульт
	]
	# лестница вверх
	var d: Node2D = Node2D.new()
	d.set_script(load("res://live_door.gd"))
	d.position = ORG + STAIRS_AT
	d.set("kind", "up")
	d.set("club", self)
	root.add_child(d)
	door_out = d
	_lights()
	_people()


func _lights() -> void:
	# прожекторы над сценой: цветные пятна света, пульсируют в такт
	var cols: Array = [Color(1.0, 0.35, 0.7), Color(0.35, 0.7, 1.0), Color(1.0, 0.85, 0.35), Color(0.6, 1.0, 0.6)]
	var xs: Array = [190, 290, 390, 490]
	for i in range(4):
		var s: Sprite2D = Sprite2D.new()
		s.texture = load("res://art/live_spot.png")
		s.position = ORG + Vector2(float(xs[i]), 128.0)
		s.scale = Vector2(2.2, 1.3)
		s.modulate = Color(cols[i].r, cols[i].g, cols[i].b, 0.35)
		s.material = main.call("_additive")
		s.z_index = 8
		root.add_child(s)
		lights.append([s, float(i) * 1.3, 0.3])
	# неон над баром
	var n: Sprite2D = Sprite2D.new()
	n.texture = load("res://art/live_spot.png")
	n.position = ORG + Vector2(60, 60)
	n.scale = Vector2(1.8, 0.8)
	n.modulate = Color(1.0, 0.3, 0.6, 0.35)
	n.material = main.call("_additive")
	n.z_index = 8
	root.add_child(n)
	lights.append([n, 0.0, 0.3])
	# тёплый свет над залом
	var w2: Sprite2D = Sprite2D.new()
	w2.texture = load("res://art/live_spot.png")
	w2.position = ORG + Vector2(320, 250)
	w2.scale = Vector2(5.0, 2.4)
	w2.modulate = Color(1.0, 0.7, 0.45, 0.10)
	w2.material = main.call("_additive")
	w2.z_index = 8
	root.add_child(w2)


func _people() -> void:
	# группа на сцене
	_girl("rock_niko", Vector2(205, 108), 0.0, "")
	_girl("rock_rio", Vector2(290, 124), 0.0, "")
	_girl("rock_ikka", Vector2(350, 126), 0.0, "")
	_girl("rock_bokki", Vector2(430, 124), 0.0, "")
	# хозяйка за стойкой, звукорежиссёр у пульта, Куки за столиком
	var bar_girl: Node2D = _girl("rock_seiko", Vector2(96, 178), 12.0, "торговец")
	bar_girl.set_meta("goods", ["lemonade", "cocoa", "apple_juice", "star_tea", "muffin", "cookie"])
	_girl("rock_pei", Vector2(574, 214), 0.0, "")
	_girl("rock_kuki", Vector2(440, 252), 0.0, "")


func _girl(tex: String, at: Vector2, roam: float, role: String) -> Node2D:
	var c: Node2D = Node2D.new()
	c.set_script(load("res://catgirl.gd"))
	root.add_child(c)
	c.call("setup", tex, ORG + at)
	c.set("roam", roam)
	c.set("blocked", Callable(main, "is_blocked"))
	if role != "":
		c.set("role", role)
	c.set("prompt", "Поговорить")
	var sp: Sprite2D = c.get("spr") as Sprite2D
	sp.material = main.call("char_light_mat", Vector2(8, 8), sp)
	var fm: ShaderMaterial = main.call("char_light_mat", Vector2(1, 1), sp)
	fm.set_shader_parameter("region_mode", true)
	(c.get("face") as Sprite2D).material = fm
	c.set("face_mat", fm)
	if tex in ["rock_niko", "rock_rio", "rock_ikka", "rock_bokki"]:
		rockers.append(sp)
	return c


func _process(delta: float) -> void:
	t += delta
	if not active:
		return
	for l in lights:
		var s: Sprite2D = l[0]
		var k: float = 0.5 + 0.5 * sin(t * 4.2 + float(l[1]))
		s.modulate.a = float(l[2]) * (0.55 + 0.9 * k)
	# музыканты качаются в такт
	var beat: float = absf(sin(t * 4.2))
	var i: int = 0
	for sp in rockers:
		if is_instance_valid(sp):
			(sp as Sprite2D).position.y = -beat * (1.4 + 0.3 * float(i % 2)) if i != 0 else -absf(sin(t * 8.4)) * 1.2
		i += 1


# ------------------------------------------------------------------ вход и выход

func enter() -> void:
	if active or Game.busy:
		return
	Sound.play("door", -4.0)
	main.call("_transition", func() -> void:
		set_active(true)
		var pl: Node2D = main.get("player")
		pl.position = ORG + ARRIVE
		pl.set("facing", 1)
		pl.set("want_facing", 1))


func leave() -> void:
	if not active or Game.busy:
		return
	Sound.play("door", -4.0)
	main.call("_transition", func() -> void:
		set_active(false)
		var pl: Node2D = main.get("player")
		pl.position = (ent_pos if ent_pos != Vector2.INF else (CANDS[0] as Vector2)) + Vector2(0, 22)
		pl.set("facing", 3)
		pl.set("want_facing", 3))


func set_active(on: bool) -> void:
	active = on
	var cam: Camera2D = main.get("cam")
	if on:
		cam.limit_left = int(ORG.x)
		cam.limit_top = int(ORG.y)
		cam.limit_right = int(ORG.x + SIZE.x)
		cam.limit_bottom = int(ORG.y + SIZE.y)
	else:
		main.call("_world_limits")
	cam.reset_smoothing()

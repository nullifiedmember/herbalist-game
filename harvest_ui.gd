extends CanvasLayer
## Окно сбора трав (v16). E у травы или скопления — крупный план: растения в земле, справа корзинка.
##  • без ножа: схвати растение (зажми кнопку) и тяни мышью ВВЕРХ — вырвется с корешком; неси в корзинку;
##  • с ножом/серпом в руке: проведи лезвием поперёк стебля у самой земли — срежется; выше — испортишь цветок;
##  • у каждой травы своя особенность (harvest_db.gd): жжётся, кричит, тает, уворачивается, сидит пчела...
## Без надписей — всё видно по картинке. Esc / E — уйти (собранное — в сумку).

const DB = preload("res://herbs_db.gd")
const HDB = preload("res://harvest_db.gd")
const IT = preload("res://items_db.gd")
const PH = preload("res://phys2d.gd")
const PG27 = preload("res://plant_ground27.gd")
const WD = preload("res://world_data.gd")

const WIN: Rect2 = Rect2(300, 130, 1320, 780)
const GROUND_Y: float = 760.0
const BASKET: Rect2 = Rect2(1290, 560, 304, 208)
const SC: float = 5.0                 # во сколько раз крупнее значка травы
const CUT_LOW: float = 6.0            # зона среза над землёй (пиксели экрана)
const CUT_HIGH: float = 62.0

var root: Control
var ui: Control
var scene: Control
var top: Control
var is_open: bool = false
var source: Node = null
var plants: Array = []                # словари растений
var basket: Array = []                # id собранных (с добавкой ягод)
var mouse: Vector2 = Vector2.ZERO
var prev_mouse: Vector2 = Vector2.ZERO
var mspeed: float = 0.0
var held: bool = false
var grab: int = -1                    # какое растение в руке (индекс)
var t: float = 0.0
var done_t: float = 0.0               # v27: сколько всё уже собрано (автозакрытие)
var shake: float = 0.0
var stun: float = 0.0                 # оглушило криком мандрагоры
var dizzy: float = 0.0                # яд белладонны
var drowsy: float = 0.0               # дурманная пыльца
var glare: float = 0.0
var ouch: float = 0.0
var need_icon: String = ""            # чего не хватает (значок над растением)
var need_t: float = 0.0
var need_at: Vector2 = Vector2.ZERO
var kitten_x: float = -200.0
var tex: Dictionary = {}
var fx: Array = []                    # [позиция, скорость, цвет, жизнь]
var trail: Array = []                 # v19: последние положения мыши [позиция, время] — для броска
var base_back: Color = Color.WHITE    # v27: лунка и травинки под травой — цвет земли биома (как в мире)
var base_front: Color = Color.WHITE
var base_blades: bool = true
var plant_tone: Color = Color.WHITE
const FLOOR_Y: float = GROUND_Y + 8.0


func _ready() -> void:
	layer = 31
	add_to_group("harvest_ui")
	for n in ["hand_open", "hand_grab", "harvest_basket", "fx_bee", "fx_butterfly", "fx_kitten", "fx_web", "st_knife"]:
		tex[n] = load("res://art/%s.png" % n)
	root = Control.new()
	root.size = Vector2(1920, 1080)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)
	ui = Control.new()
	ui.size = Vector2(1920, 1080)
	ui.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(ui)
	ui.draw.connect(_draw_frame)
	ui.gui_input.connect(_on_input)
	scene = Control.new()
	scene.position = WIN.position
	scene.size = WIN.size
	scene.clip_contents = true
	scene.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(scene)
	scene.draw.connect(_draw_ui)
	top = Control.new()
	top.size = Vector2(1920, 1080)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(top)
	top.draw.connect(_draw_hand)
	root.visible = false


## v27: трава в земле — как в мире (herbw_* без кочки), иначе значок
func _wicon(id: String) -> Texture2D:
	if not tex.has("w_" + id):
		# v27d: своя картинка для окна сбора — без земли и без пучков травы (tools/herb_harvest27.py)
		var hp: String = "res://art/herbh_%s.png" % id
		if ResourceLoader.exists(hp):
			tex["w_" + id] = load(hp)
			return tex["w_" + id]
		var wp: String = "res://art/herbw_%s.png" % id
		var wt: Texture2D = load(wp) if ResourceLoader.exists(wp) else null
		tex["w_" + id] = _no_tufts(wt) if wt != null and wt.get_size() == Vector2(32, 48) else _icon(id)
	return tex["w_" + id]


## v27: цвета лунки/травинок/оттенка травы — те же, что даёт plant_ground27.gd в мире
func _base_colors(src: Node) -> void:
	var b: int = 1
	if src is Node2D and WD.in_world((src as Node2D).global_position):
		b = WD.biome_at((src as Node2D).global_position)
	var c: Color = PG27.COL.get(b, PG27.COL[1])
	base_back = Color(c.r * 0.5, c.g * 0.55, c.b * 0.5, 1.0)
	var gt: Color = PG27.GRASS_BASE * (PG27.GRASS_TINT.get(b, Color.WHITE) as Color)
	var fc: Color = c.lerp(gt, 0.45)
	base_front = Color(fc.r, fc.g, fc.b, 1.0)
	base_blades = not b in PG27.NO_BLADES
	var lum: float = (c.r + c.g + c.b) / 3.0
	var tone: Color = Color(c.r / maxf(lum, 0.01), c.g / maxf(lum, 0.01), c.b / maxf(lum, 0.01)) * clampf(0.75 + lum * 0.45, 0.8, 1.05)
	plant_tone = Color.WHITE.lerp(Color(tone.r, tone.g, tone.b, 1.0), 0.12)


## v27c: убрать пучки травинок у земли, нарисованные в картинке травы (отдельные кусочки внизу) —
## в окне сбора растение растёт прямо из земли одним стеблем. Картинки в мире не меняются.
func _no_tufts(t2: Texture2D) -> Texture2D:
	var im: Image = t2.get_image()
	if im == null:
		return t2
	im = im.duplicate()
	if im.is_compressed():
		im.decompress()
	im.convert(Image.FORMAT_RGBA8)
	var w: int = im.get_width()
	var h: int = im.get_height()
	var low: int = 0
	for y in range(h):
		for x in range(w):
			if im.get_pixel(x, y).a > 0.5:
				low = y
	# полупрозрачная тень-полоска под травой (она же склеивает пучки со стеблем) — убрать
	for y in range(maxi(0, low - 2), h):
		for x in range(w):
			if im.get_pixel(x, y).a <= 0.5:
				im.set_pixel(x, y, Color(0, 0, 0, 0))
	var seen: Dictionary = {}
	for y0 in range(h):
		for x0 in range(w):
			if seen.has(Vector2i(x0, y0)) or im.get_pixel(x0, y0).a <= 0.5:
				continue
			# связный кусочек (8 соседей)
			var part: Array = []
			var stack: Array = [Vector2i(x0, y0)]
			seen[Vector2i(x0, y0)] = true
			var top_y: int = y0
			while not stack.is_empty():
				var c: Vector2i = stack.pop_back()
				part.append(c)
				top_y = mini(top_y, c.y)
				for dy in range(-1, 2):
					for dx in range(-1, 2):
						var n: Vector2i = c + Vector2i(dx, dy)
						if n.x < 0 or n.y < 0 or n.x >= w or n.y >= h or seen.has(n):
							continue
						if im.get_pixel(n.x, n.y).a > 0.5:
							seen[n] = true
							stack.append(n)
			# маленький кусочек целиком у самой земли — это пучок травы
			if top_y >= low - 7 and part.size() < 40:
				for c2 in part:
					im.set_pixel(c2.x, c2.y, Color(0, 0, 0, 0))
	return ImageTexture.create_from_image(im)


## v27c: нижняя непрозрачная строка картинки (где у травы начинается стебель)
func _low_row(t2: Texture2D) -> int:
	var key: String = "low_%d" % t2.get_instance_id()
	if not tex.has(key):
		var im: Image = t2.get_image()
		var low: int = t2.get_height() - 1
		if im != null:
			if im.is_compressed():
				im.decompress()
			low = 0
			for y in range(im.get_height()):
				for x in range(im.get_width()):
					if im.get_pixel(x, y).a > 0.5:
						low = y
						break
		tex[key] = low
	return int(tex[key])


func _icon(id: String) -> Texture2D:
	if not tex.has("h_" + id):
		tex["h_" + id] = DB.icon(id)
	return tex["h_" + id]


# ============================================================ открыть / закрыть
func open(src: Node, ids: Array) -> void:
	if is_open or ids.is_empty():
		return
	if Game.tired():
		get_tree().call_group("player", "react", "sad", 1.6)
		Game.fx.emit((get_tree().get_first_node_in_group("player") as Node2D).global_position + Vector2(0, -60), "zzz")
		return
	source = src
	is_open = true
	_base_colors(src)
	Game.ui_open = true
	basket.clear()
	plants.clear()
	grab = -1
	stun = 0.0
	dizzy = 0.0
	drowsy = 0.0
	kitten_x = -200.0
	var n: int = ids.size()
	for i in range(n):
		var id: String = String(ids[i])
		var x: float = WIN.position.x + 140.0 + (860.0 / float(maxi(1, n))) * (float(i) + 0.5) + randf_range(-20, 20)
		var p: Dictionary = {"id": id, "x": x, "x0": x, "state": "ground", "pull": 0.0, "lift": 0.0, "berries": true,
			"hide": 0.0, "dodge_cd": 0.0, "web": 3 if HDB.has(id, "web") else 0, "bee": randf() * 6.0, "regrow": HDB.has(id, "regrow"),
			"stick": 0.0, "melt": 2.6, "held_t": 0.0, "pos": Vector2(x, GROUND_Y), "vel": Vector2.ZERO, "sneeze": 1.5 + randf() * 1.5, "fly": randf() * TAU}
		if HDB.has(id, "float"):
			p["state"] = "air"
			p["pos"] = Vector2(x, GROUND_Y - 300.0)
		plants.append(p)
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	root.visible = true
	root.modulate.a = 0.0
	var tw: Tween = create_tween()
	tw.tween_property(root, "modulate:a", 1.0, 0.12)
	# v24: без рывка скорости в первый кадр (иначе травы пугались/лопались от простого наведения)
	mouse = get_viewport().get_mouse_position()
	prev_mouse = mouse
	trail.clear()
	held = false
	done_t = 0.0


func close() -> void:
	if not is_open:
		return
	is_open = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if grab >= 0:
		_drop(grab)
	var got: Array = basket.duplicate()
	var left: Array = []
	for p in plants:
		if String(p["state"]) in ["ground", "loose", "air"]:
			left.append(String(p["id"]))
	# v20: одинокий кустик не оставляем — он уходит в корзину вместе с кучкой
	if not got.is_empty() and left.size() == 1:
		got.append(left[0])
		left.clear()
	for id in got:
		Game.add_item(String(id), 2 if randf() * 100.0 < Game.stat("herb") else 1)
		if DB.SEEDS.has(String(id)) and randf() * 100.0 < Game.stat("seed"):
			Game.seeds[String(id)] = int(Game.seeds.get(String(id), 0)) + 1
	if source != null and is_instance_valid(source):
		source.call("harvest_done", got, left)
	source = null
	var tw: Tween = create_tween()
	tw.tween_property(root, "modulate:a", 0.0, 0.08)
	tw.tween_callback(func() -> void:
		root.visible = false
		Game.ui_open = false)


## Для автотеста: всё, что можно взять, — сразу в корзину
func auto_collect_all() -> void:
	for p in plants:
		if HDB.missing(String(p["id"])) == "":
			p["state"] = "basket"
			basket.append(String(p["id"]))
	close()


func _input(event: InputEvent) -> void:
	if not is_open:
		return
	if event is InputEventKey and (event as InputEventKey).pressed and not (event as InputEventKey).echo:
		var k: Key = (event as InputEventKey).physical_keycode
		if k == KEY_ESCAPE or KB.is_key("interact", k):
			close()
			get_viewport().set_input_as_handled()


# ============================================================ растения: где и какого роста
func _size(id: String) -> Vector2:
	var ic: Texture2D = _icon(id)
	return Vector2(ic.get_width(), ic.get_height()) * SC


## Прямоугольник растения в земле (низ значка — под землёй на 5 пикселей значка)
func _rect(p: Dictionary) -> Rect2:
	var sz: Vector2 = _size(String(p["id"]))
	var c: Vector2 = p["pos"]
	if String(p["state"]) == "loose" and p.has("body"):
		var bc: Vector2 = (p["body"] as Dictionary)["pos"]
		return Rect2(bc - sz / 2.0, sz)
	if String(p["state"]) == "ground":
		c = Vector2(float(p["x"]), GROUND_Y - float(p["lift"]))
	return Rect2(c.x - sz.x / 2.0, c.y - sz.y + 4.0 * SC, sz.x, sz.y)


func _knife_mode() -> bool:
	return HDB.cutter() != ""


func _gloves() -> bool:
	return Game.worn("hands") != ""


func _hurt(p: Dictionary, kind: String) -> void:
	ouch = 0.6
	shake = 0.25
	Sound.play("hiss", -6.0)
	get_tree().call_group("player", "react", "sad", 1.4)
	for i in range(6):
		fx.append([mouse, Vector2(randf_range(-120, 120), randf_range(-200, -60)), Color("f05a3a") if kind != "bee" else Color("f8d040"), 0.6])


func _lose(i: int, why: String) -> void:
	var p: Dictionary = plants[i]
	if bool(p["regrow"]):
		# перо феникса: вспыхивает и вырастает из пепла
		p["regrow"] = false
		p["state"] = "ground"
		p["pull"] = 0.0
		p["lift"] = 0.0
		p["x"] = p["x0"]
		_burst(Vector2(float(p["x"]), GROUND_Y - 80.0), Color("f8a030"), 30)
		Sound.play("fire", -2.0)
		if grab == i:
			grab = -1
		return
	p["state"] = "lost"
	if grab == i:
		grab = -1
	var c: Color = Color("e0f4ff") if why == "melt" else (Color("f8f0c0") if why == "puff" else Color("6aa852"))
	_burst(Rect2(_rect(p)).get_center(), c, 26)
	Sound.play("chop" if why == "cut" else "pick", -6.0)
	shake = 0.15


func _burst(at: Vector2, c: Color, n: int) -> void:
	for k in range(n):
		fx.append([at, Vector2(randf_range(-220, 220), randf_range(-320, 40)), c, randf_range(0.5, 1.0)])


# ============================================================ ввод
func _on_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse = (event as InputEventMouseMotion).position
		trail.append([mouse, t])
		while trail.size() > 2 and t - float(trail[0][1]) > 0.1:
			trail.pop_front()
		return
	if not (event is InputEventMouseButton):
		return
	var mb: InputEventMouseButton = event
	if mb.button_index != MOUSE_BUTTON_LEFT:
		return
	mouse = mb.position
	if mb.pressed:
		held = true
		_press()
	else:
		held = false
		if grab >= 0:
			_drop(grab)


func _hand() -> Vector2:
	# Бездноцвет тянет руку к себе
	var h: Vector2 = mouse
	for p in plants:
		if HDB.has(String(p["id"]), "stare") and String(p["state"]) == "ground":
			var eye: Vector2 = Vector2(float(p["x"]), GROUND_Y - 150.0)
			var d: float = h.distance_to(eye)
			if d < 420.0:
				h = h.lerp(eye, 0.28 * (1.0 - d / 420.0))
	if dizzy > 0.0:
		h += Vector2(sin(t * 5.0) * 22.0, cos(t * 4.0) * 14.0) * minf(1.0, dizzy)
	return h


func _press() -> void:
	if stun > 0.0:
		return
	var h: Vector2 = _hand()
	# поймать / поднять лежащее или летающее
	for i in range(plants.size() - 1, -1, -1):
		var p: Dictionary = plants[i]
		var st: String = String(p["state"])
		var hit_it: bool = PH.has_point(p["body"], h, 14.0) if (st == "loose" and p.has("body")) else Rect2(_rect(p)).grow(10).has_point(h)
		if (st == "loose" or st == "air") and hit_it:
			if HDB.missing(String(p["id"])) != "":
				_show_need(String(p["id"]), h)
				return
			grab = i
			p["state"] = "held"
			Sound.play("pick", -6.0)
			return
	for i in range(plants.size()):
		var p2: Dictionary = plants[i]
		if String(p2["state"]) != "ground":
			continue
		var r: Rect2 = _rect(p2)
		if not r.grow(6).has_point(h):
			continue
		var id: String = String(p2["id"])
		# паутинку сперва сорвать
		if int(p2["web"]) > 0:
			p2["web"] = int(p2["web"]) - 1
			_burst(h, Color(1, 1, 1, 0.8), 6)
			Sound.play("knit", -8.0)
			return
		if _knife_mode() and not HDB.has(id, "crumble") and not HDB.has(id, "shovel") and not HDB.has(id, "trowel"):
			return     # с ножом — режут, а не тянут
		var miss: String = HDB.missing(id)
		if miss != "":
			_show_need(id, h)
			return
		if float(p2["hide"]) > 0.0:
			return
		if HDB.has(id, "dark") and bool(Game.get("light_on")):
			_show_need(id, h)
			return
		if HDB.has(id, "moon") and sin(t * 2.1 + float(p2["fly"])) < 0.0:
			return
		if HDB.has(id, "sting") and not _gloves():
			_hurt(p2, "sting")
			return
		if HDB.has(id, "thorn") and not _gloves() and h.y > r.position.y + r.size.y * 0.4:
			_hurt(p2, "thorn")
			return
		if (HDB.has(id, "bee") or HDB.has(id, "butterfly")) and _bug_on(p2):
			if HDB.has(id, "bee"):
				_hurt(p2, "bee")
			p2["bee"] = 3.2       # насекомое вспорхнуло — подожди
			return
		if HDB.has(id, "wave") and _wave() > 0.5:
			return
		if HDB.has(id, "poison") and not _gloves():
			dizzy = 3.0
		grab = i
		p2["stick"] = 0.8 if HDB.has(id, "sticky") else 0.0
		p2["grab_y"] = h.y
		Sound.play("pick", -10.0)
		return


## Растение становится телом: летит, крутится, падает и ложится (v19)
func _make_loose(p: Dictionary, center: Vector2, vel: Vector2) -> void:
	var sz: Vector2 = _size(String(p["id"]))
	p["state"] = "loose"
	p["body"] = PH.make(center, Vector2(sz.x * 0.5, sz.y * 0.78), vel, vel.x * 0.006 + randf_range(-1.5, 1.5), randf_range(-0.15, 0.15))
	p["pos"] = center
	p["vel"] = vel


func _show_need(id: String, at: Vector2) -> void:
	need_icon = HDB.missing(id)
	if need_icon == "" and HDB.has(id, "dark"):
		need_icon = "dark"
	need_t = 1.6
	need_at = at + Vector2(0, -90)
	shake = 0.2
	Sound.play("ui_click", -2.0)
	get_tree().call_group("player", "react", "sad", 1.2)


func _bug_on(p: Dictionary) -> bool:
	return fmod(float(p["bee"]), 7.0) < 4.0


func _wave() -> float:
	var ph: float = fmod(t, 6.0)
	return clampf(1.0 - absf(ph - 4.6) / 0.9, 0.0, 1.0)


func _drop(i: int) -> void:
	var p: Dictionary = plants[i]
	grab = -1
	if String(p["state"]) == "held":
		if BASKET.grow(30).has_point(mouse):
			p["state"] = "basket"
			basket.append(String(p["id"]))
			if bool(p["berries"]) and HDB.has(String(p["id"]), "berries"):
				basket.append(String(p["id"]))   # ягоды целы — вдвое больше
			Sound.play("pickup", -4.0)
			_burst(BASKET.get_center() + Vector2(0, -60), Color("c8e890"), 10)
		else:
			_make_loose(p, mouse + Vector2(0, _size(String(p["id"])).y * 0.15), PH.throw_vel(trail))
	# если растение тянули и отпустили — оседает обратно
	elif String(p["state"]) == "ground":
		pass


# ============================================================ кадр
func _process(delta: float) -> void:
	if not is_open:
		return
	t += delta
	# v27: всё собрано (или потеряно) — окно закрывается само
	var busy: bool = false
	for q in plants:
		if String(q["state"]) in ["ground", "loose", "air", "held"]:
			busy = true
	if busy or grab >= 0:
		done_t = 0.0
	else:
		done_t += delta
		if done_t > 0.2:
			done_t = 0.0
			close()
			return
	var h: Vector2 = _hand()
	mspeed = mouse.distance_to(prev_mouse) / maxf(delta, 0.001)
	var dy: float = prev_mouse.y - mouse.y           # вверх — положительно
	var dx_prev: float = prev_mouse.x
	shake = maxf(0.0, shake - delta)
	stun = maxf(0.0, stun - delta)
	dizzy = maxf(0.0, dizzy - delta)
	drowsy = maxf(0.0, drowsy - delta)
	ouch = maxf(0.0, ouch - delta)
	need_t = maxf(0.0, need_t - delta)
	glare = maxf(0.0, glare - delta)
	for i in range(plants.size()):
		var p: Dictionary = plants[i]
		var id: String = String(p["id"])
		var st: String = String(p["state"])
		p["bee"] = float(p["bee"]) + delta
		p["hide"] = maxf(0.0, float(p["hide"]) - delta)
		p["dodge_cd"] = maxf(0.0, float(p["dodge_cd"]) - delta)
		if st == "ground":
			var r: Rect2 = _rect(p)
			var near: float = h.distance_to(r.get_center())
			# v24: травы пугаются только когда рука хватает (ЛКМ зажата), а не от простого наведения
			# нажатие должно начаться уже в этом окне (held): кнопка, зажатая при открытии, пугала растения при наведении
			var lmb: bool = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and held
			if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				held = false
			if HDB.has(id, "sway"):
				# v29: пока рука рядом или держит растение — оно стоит спокойно и не «убегает» (шалфей)
				var sw: float = sin(t * 1.6 + float(p["fly"])) * 26.0
				if grab == i or near < 150.0:
					p["x0"] = float(p["x"]) - sw
				else:
					p["x"] = float(p["x0"]) + sw
			if HDB.has(id, "shy") and lmb and near < 120.0 and mspeed > 1400.0 and grab != i:
				p["hide"] = 2.0
			if HDB.has(id, "dodge") and lmb and near < 110.0 and mspeed > 700.0 and float(p["dodge_cd"]) <= 0.0 and grab != i:
				p["x0"] = clampf(float(p["x0"]) + (220.0 if h.x < float(p["x"]) else -220.0), WIN.position.x + 120.0, BASKET.position.x - 120.0)
				p["x"] = p["x0"]
				p["dodge_cd"] = 1.4
				Sound.play("squeak", -6.0)
			if HDB.has(id, "puff") and lmb and near < 90.0 and mspeed > 2200.0 and grab != i:
				_lose(i, "puff")
				continue
			if HDB.has(id, "glare") and fmod(t + float(p["fly"]), 3.5) < 0.05:
				glare = 0.6
			# нож: лезвие прошло поперёк стебля
			if _knife_mode() and held and lmb and grab < 0 and not HDB.has(id, "shovel") and not HDB.has(id, "trowel"):
				var sx: float = float(p["x"])
				if (dx_prev - sx) * (mouse.x - sx) < 0.0 and absf(mouse.x - dx_prev) > 4.0:
					var above: float = GROUND_Y - mouse.y
					if above >= -10.0 and above <= r.size.y:
						if HDB.missing(id) != "" or (HDB.has(id, "dark") and bool(Game.get("light_on"))):
							_show_need(id, mouse)
						elif int(p["web"]) > 0:
							p["web"] = 0
							_burst(mouse, Color(1, 1, 1, 0.8), 8)
						elif above < CUT_LOW:
							shake = 0.1
							Sound.play("tinker", -8.0)    # лезвие в землю — ничего
						elif above <= CUT_HIGH and not HDB.has(id, "crumble"):
							_make_loose(p, Vector2(sx, GROUND_Y - r.size.y * 0.45), Vector2(randf_range(-90, 90), -260))
							Sound.play("scythe", -4.0)
						else:
							_lose(i, "cut")     # срезала цветок — растение испорчено
							continue
		# тянет рукой
		if grab == i and st == "ground":
			var tug: float = maxf(0.3, float(HDB.q(id)["tug"]))
			var spd: float = float(HDB.q(id)["spd"])
			p["stick"] = maxf(0.0, float(p["stick"]) - delta)
			var up: float = maxf(0.0, dy) * (0.5 if drowsy > 0.0 else 1.0)
			var vs: float = up / maxf(delta, 0.001)
			if HDB.has(id, "berries") and vs > 700.0:
				p["berries"] = false
			if HDB.has(id, "scream") and vs > 520.0:
				stun = 1.6
				shake = 1.0
				grab = -1
				Sound.play("squeak", 2.0)
				for q in plants:
					if String(q["state"]) == "ground":
						q["hide"] = 1.5
				continue
			if spd > 0.0 and vs > spd:
				_lose(i, "tear")
				Sound.play("tinker" if HDB.has(id, "ring") else "pick", -2.0)
				continue
			if HDB.has(id, "sleepy") and vs > 600.0:
				drowsy = 3.0
			if HDB.has(id, "slip") and vs > 450.0 and randf() < delta * 3.0:
				grab = -1
				p["pull"] = float(p["pull"]) * 0.5
				shake = 0.15
				continue
			if HDB.has(id, "wave") and _wave() > 0.5:
				grab = -1
				p["pull"] = 0.0
				continue
			if HDB.has(id, "sneeze"):
				p["sneeze"] = float(p["sneeze"]) - delta
				if float(p["sneeze"]) <= 0.0:
					p["sneeze"] = 1.5 + randf() * 2.0
					p["pull"] = maxf(0.0, float(p["pull"]) - 0.25)
					shake = 0.35
					Sound.play("sniff", -2.0)
			if HDB.has(id, "kitten"):
				p["held_t"] = float(p["held_t"]) + delta
			if float(p["stick"]) <= 0.0:
				p["pull"] = float(p["pull"]) + up / (170.0 * tug)
			p["lift"] = minf(70.0, float(p["pull"]) * 70.0)
			if float(p["pull"]) >= 1.0:
				p["state"] = "held"
				p["held_t"] = 0.0
				Sound.play("dig" if HDB.has(id, "shovel") or HDB.has(id, "trowel") else "pick", -4.0)
				_burst(Vector2(float(p["x"]), GROUND_Y), Color("6e4828"), 14)
		elif st == "ground" and grab != i:
			p["pull"] = maxf(0.0, float(p["pull"]) - delta * 0.6)
			p["lift"] = minf(70.0, float(p["pull"]) * 70.0)
		# в руке: тает, котёнок
		if String(p["state"]) == "held":
			p["pos"] = h + Vector2(0, _size(id).y * 0.45)
			if HDB.has(id, "melt"):
				p["melt"] = float(p["melt"]) - delta
				if float(p["melt"]) <= 0.0:
					_lose(i, "melt")
					continue
		if HDB.has(id, "kitten") and (grab == i) and float(p["held_t"]) > 1.2:
			kitten_x = move_toward(kitten_x, h.x - 60.0, delta * 700.0)
			if absf(kitten_x - (h.x - 60.0)) < 10.0 and float(p["held_t"]) > 3.2:
				_lose(i, "cat")
				Sound.play("meow_1", -2.0)
				kitten_x = -200.0
				continue
		# лежит: падает на землю
		if String(p["state"]) == "loose" and p.has("body"):
			var bd: Dictionary = p["body"]
			if PH.step(bd, delta, FLOOR_Y, WIN.position.x + 8.0, WIN.end.x - 8.0):
				Sound.play("dig", -16.0, 0.2)
				_burst(Vector2(Vector2(bd["pos"]).x, FLOOR_Y - 4.0), Color("6e4828"), 4)
			p["pos"] = bd["pos"]
			# долетело до корзины — внутрь
			if BASKET.grow(-10).has_point(Vector2(bd["pos"])) and HDB.missing(id) == "":
				p["state"] = "basket"
				basket.append(id)
				if bool(p["berries"]) and HDB.has(id, "berries"):
					basket.append(id)
				Sound.play("pickup", -4.0)
				_burst(BASKET.get_center() + Vector2(0, -60), Color("c8e890"), 10)
				continue
			if HDB.has(id, "melt"):
				p["melt"] = float(p["melt"]) - delta * 0.5
				if float(p["melt"]) <= 0.0:
					_lose(i, "melt")
					continue
		# летает (Лист Великого древа)
		if String(p["state"]) == "air":
			p["fly"] = float(p["fly"]) + delta
			var f: float = float(p["fly"])
			p["pos"] = Vector2(WIN.position.x + 560.0 + sin(f * 0.7) * 420.0, GROUND_Y - 300.0 + sin(f * 1.9) * 120.0)
	if grab < 0:
		kitten_x = move_toward(kitten_x, -200.0, delta * 500.0)
	# лежащие толкают друг друга
	var bodies: Array = []
	for pq in plants:
		if String(pq["state"]) == "loose" and pq.has("body"):
			bodies.append(pq["body"])
	PH.collide_all(bodies)
	# частицы
	for k in range(fx.size() - 1, -1, -1):
		var e: Array = fx[k]
		e[1] = Vector2(e[1]) + Vector2(0, 600.0 * delta)
		e[0] = Vector2(e[0]) + Vector2(e[1]) * delta
		e[3] = float(e[3]) - delta
		if float(e[3]) <= 0.0:
			fx.remove_at(k)
	prev_mouse = mouse
	ui.queue_redraw()
	scene.queue_redraw()
	top.queue_redraw()


# ============================================================ рисование
func _draw_frame() -> void:
	ui.draw_rect(Rect2(0, 0, 1920, 1080), Color(0, 0, 0, 0.55))
	ui.draw_rect(WIN.grow(14), Color("3a2414"))
	ui.draw_rect(WIN.grow(8), Color("7a5230"))
	ui.draw_rect(WIN.grow(3), Color("2a1a0e"))


func _draw_ui() -> void:
	var off: Vector2 = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * 10.0 * shake
	scene.draw_set_transform(off - WIN.position, 0.0, Vector2.ONE)
	var W: Rect2 = WIN
	# небо: от времени суток
	var night: float = Game.night_factor()
	var sky_top: Color = Color("8ec8e8").lerp(Color("141a34"), night)
	var sky_bot: Color = Color("d8ecd0").lerp(Color("2a2e48"), night)
	for y in range(0, int(GROUND_Y - W.position.y), 8):
		var k: float = float(y) / (GROUND_Y - W.position.y)
		scene.draw_rect(Rect2(W.position.x, W.position.y + y, W.size.x, 8), sky_top.lerp(sky_bot, k))
	# облака
	for i in range(5):
		var cx: float = W.position.x + fmod(float(i) * 290.0 + t * (6.0 + float(i)), W.size.x + 200.0) - 100.0
		var cy: float = W.position.y + 60.0 + float(i % 3) * 50.0
		var cc: Color = Color(1, 1, 1, 0.85).lerp(Color(0.4, 0.45, 0.6, 0.5), night)
		for k in range(4):
			scene.draw_rect(Rect2(cx + float(k) * 22.0 - 10.0 * float(k % 2), cy - float(k % 2) * 12.0, 56, 18 + float(k % 2) * 10.0), cc)
		scene.draw_rect(Rect2(cx - 4, cy + 14, 100, 6), cc.darkened(0.08))
	# два ряда ёлок ярусами: дальний светлее
	for layer2 in range(2):
		var base_y: float = GROUND_Y - 24.0 - (40.0 if layer2 == 0 else 0.0)
		var col: Color = (Color("7aa88a") if layer2 == 0 else Color("3e6e4e")).lerp(Color("0e1420"), night * 0.8)
		for i in range(16):
			var x: float = W.position.x + float(i) * 88.0 + fmod(float(i * 53 + layer2 * 31), 40.0) - 20.0 + float(layer2) * 40.0
			var hgt: float = 150.0 + fmod(float(i * 71 + layer2 * 17), 90.0) - float(layer2) * 20.0
			var tiers: int = 5
			for k in range(tiers):
				var ty: float = base_y - hgt + float(k) * hgt / float(tiers)
				var w: float = 14.0 + float(k) * 11.0
				var pts: PackedVector2Array = PackedVector2Array([Vector2(x, ty - 10.0), Vector2(x + w, ty + hgt / float(tiers) + 8.0), Vector2(x - w, ty + hgt / float(tiers) + 8.0)])
				scene.draw_colored_polygon(pts, col)
				scene.draw_colored_polygon(PackedVector2Array([Vector2(x, ty - 10.0), Vector2(x, ty + hgt / float(tiers) + 8.0), Vector2(x - w, ty + hgt / float(tiers) + 8.0)]), col.lightened(0.08))
			scene.draw_rect(Rect2(x - 4, base_y, 8, 24), Color("3a2a1a").lerp(Color("0a0a10"), night))
	# земля: трава сверху, слои почвы, камешки и корешки
	scene.draw_rect(Rect2(W.position.x, GROUND_Y - 30.0, W.size.x, W.end.y - GROUND_Y + 30.0), Color("4a3222").lerp(Color("181210"), night * 0.6))
	for y in range(int(GROUND_Y), int(W.end.y), 6):
		for xi in range(0, int(W.size.x), 6):
			var hsh: float = fmod(float(xi * 73 + y * 151) * 0.618, 1.0)
			if hsh < 0.08:
				scene.draw_rect(Rect2(W.position.x + xi, y, 6, 6), Color("3a2618").lerp(Color("100c0a"), night * 0.6))
			elif hsh > 0.97:
				scene.draw_rect(Rect2(W.position.x + xi, y, 12, 6), Color("7a6a5a").lerp(Color("2a2420"), night * 0.6))
	scene.draw_rect(Rect2(W.position.x, GROUND_Y - 30.0, W.size.x, 22), Color("5a9a4a").lerp(Color("1a2a1a"), night * 0.7))
	scene.draw_rect(Rect2(W.position.x, GROUND_Y - 30.0, W.size.x, 6), Color("7ab85a").lerp(Color("223422"), night * 0.7))
	scene.draw_rect(Rect2(W.position.x, GROUND_Y - 8.0, W.size.x, 6), Color("3e6e34").lerp(Color("141e14"), night * 0.7))
	for i in range(110):
		var gx: float = W.position.x + fmod(float(i) * 97.3, W.size.x)
		var gh: float = 10.0 + fmod(float(i) * 7.0, 14.0)
		scene.draw_rect(Rect2(gx, GROUND_Y - 30.0 - gh, 4, gh), Color("6aaa52").lerp(Color("1a2a1a"), night * 0.7))
		scene.draw_rect(Rect2(gx + 4, GROUND_Y - 30.0 - gh * 0.6, 4, gh * 0.6), Color("4a8a3e").lerp(Color("142014"), night * 0.7))
	# волна (морские травы)
	var has_wave: bool = false
	for p in plants:
		if HDB.has(String(p["id"]), "wave"):
			has_wave = true
	if has_wave:
		var wv: float = _wave()
		if wv > 0.0:
			scene.draw_rect(Rect2(W.position.x, GROUND_Y - 120.0 * wv, W.size.x, 140.0 * wv), Color(0.45, 0.75, 0.9, 0.55 * wv))
			for i in range(30):
				scene.draw_rect(Rect2(W.position.x + float(i) * 44.0 + sin(t * 3.0 + i) * 8.0, GROUND_Y - 120.0 * wv, 24, 6), Color(1, 1, 1, 0.7 * wv))
	# корзинка
	scene.draw_texture_rect(tex["harvest_basket"], BASKET, false)
	for k in range(basket.size()):
		var bi: Texture2D = _icon(String(basket[k]))
		var bp: Vector2 = BASKET.position + Vector2(50.0 + float(k % 6) * 34.0, 40.0 - float(k / 6) * 16.0)
		scene.draw_texture_rect(bi, Rect2(bp - Vector2(24, 60), Vector2(64, 96)), false)
	# v29: передняя стенка корзинки начинается с самого края — трава за ней больше не просвечивает
	scene.draw_texture_rect_region(tex["harvest_basket"], Rect2(BASKET.position + Vector2(0, 48), Vector2(BASKET.size.x, BASKET.size.y - 48)),
		Rect2(0, 12, 76, 40))
	# растения
	for i in range(plants.size()):
		var p: Dictionary = plants[i]
		var st: String = String(p["state"])
		if st == "basket" or st == "lost" or (st == "held"):
			continue
		_draw_plant(p, i)
	# в руке — поверх всего
	if grab >= 0 and String(plants[grab]["state"]) == "held":
		_draw_plant(plants[grab], grab)
	# котёнок
	if kitten_x > -150.0:
		scene.draw_texture_rect(tex["fx_kitten"], Rect2(kitten_x - 45, GROUND_Y - 120, 90, 78), false)
	# частицы
	for e in fx:
		scene.draw_rect(Rect2(Vector2(e[0]), Vector2(6, 6)), Color(e[2], clampf(float(e[3]) * 2.0, 0.0, 1.0)))
	# чего не хватает: значок вещи и красный крест
	if need_t > 0.0 and need_icon != "":
		var a: float = minf(1.0, need_t)
		scene.draw_rect(Rect2(need_at - Vector2(44, 44), Vector2(88, 88)), Color(0.12, 0.07, 0.04, 0.85 * a))
		if need_icon == "dark":
			scene.draw_circle(need_at, 22.0, Color(1.0, 0.8, 0.4, a))
		else:
			scene.draw_texture_rect(IT.icon(need_icon), Rect2(need_at - Vector2(36, 36), Vector2(72, 72)), false, Color(1, 1, 1, a))
		scene.draw_line(need_at + Vector2(-40, -40), need_at + Vector2(40, 40), Color(0.9, 0.15, 0.1, a), 7.0)
	# пыльца, дурман, яд, ослепление
	if drowsy > 0.0:
		scene.draw_rect(Rect2(W.position, W.size), Color(0.35, 0.2, 0.45, 0.35 * minf(1.0, drowsy)))
	if glare > 0.0:
		scene.draw_rect(Rect2(W.position, W.size), Color(1.0, 0.98, 0.85, 0.7 * glare))
	if dizzy > 0.0:
		scene.draw_rect(Rect2(W.position, W.size), Color(0.3, 0.5, 0.2, 0.18 * minf(1.0, dizzy)))
	scene.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_plant(p: Dictionary, i: int) -> void:
	var id: String = String(p["id"])
	var st: String = String(p["state"])
	var ic: Texture2D = _wicon(id)
	var r: Rect2 = _rect(p)
	var mod: Color = Color.WHITE
	var night: float = Game.night_factor()
	if st != "held":
		mod = Color(1, 1, 1).lerp(Color(0.35, 0.38, 0.6), night * 0.7)
	if DB.DATA.has(id) and DB.DATA[id].has("hours") and night > 0.5:
		mod = Color(1.2, 1.2, 1.35)
	if HDB.has(id, "hot") or HDB.has(id, "glare"):
		mod = Color(1.25, 1.15, 1.0)
	# спрятался / закрылся
	var squash: float = 1.0
	if float(p["hide"]) > 0.0:
		squash = 0.62
	if HDB.has(id, "moon") and sin(t * 2.1 + float(p["fly"])) < 0.0 and st == "ground":
		mod = mod * Color(0.6, 0.6, 0.8)
	if HDB.has(id, "dark") and bool(Game.get("light_on")) and st == "ground":
		squash = 0.5
		mod = mod * Color(0.5, 0.45, 0.6)
	if HDB.has(id, "melt") and (st == "held" or st == "loose"):
		mod = mod * Color(1, 1, 1, clampf(float(p["melt"]) / 2.6, 0.25, 1.0))
	if st == "loose" and p.has("body"):
		var bdy: Dictionary = p["body"]
		scene.draw_set_transform(Vector2(bdy["pos"]) - WIN.position, float(bdy["ang"]), Vector2.ONE)
		scene.draw_texture_rect(ic, Rect2(-r.size.x / 2.0, -r.size.y * 0.58, r.size.x, r.size.y), false, mod)
		scene.draw_set_transform(-WIN.position, 0.0, Vector2.ONE)
		return
	if st == "loose":
		scene.draw_set_transform(Vector2(p["pos"]) + Vector2(0, -20) - WIN.position, -1.35, Vector2.ONE)
		scene.draw_texture_rect(ic, Rect2(-r.size.x / 2.0, -r.size.y / 2.0, r.size.x, r.size.y), false, mod)
		scene.draw_set_transform(-WIN.position, 0.0, Vector2.ONE)
		return
	var dst: Rect2 = Rect2(r.position.x, r.end.y - r.size.y * squash, r.size.x, r.size.y * squash)
	# тянут: стебель вытягивается, видны корешки
	if st == "ground" and float(p["lift"]) > 2.0:
		var lift: float = float(p["lift"])
		for k in range(5):
			var rx: float = float(p["x"]) + float(k - 2) * 8.0
			scene.draw_line(Vector2(rx, GROUND_Y - lift + 8.0), Vector2(rx + sin(float(k) * 1.7) * 10.0, GROUND_Y + 10.0), Color("e8dcc0"), 3.0)
	if st == "held" and HDB.has(id, "sticky") and float(p.get("stick", 0.0)) > 0.0:
		scene.draw_line(_hand(), Vector2(r.get_center().x, r.position.y + 40), Color(1, 1, 0.8, 0.7), 2.0)
	if st == "ground":
		# v27c: стебель начинается прямо из бурой земли — без лунки и без травинок: самый низ травы на кромке почвы
		var wic: Texture2D = _wicon(id)
		var low: int = _low_row(wic)
		var soil_y: float = GROUND_Y - 2.0 + 4.0      # кромка почвы + утопить на ~1 пиксель арта
		var sh: float = (soil_y - float(p["lift"])) - (dst.position.y + (float(low) + 1.0) / float(wic.get_height()) * dst.size.y)
		scene.draw_texture_rect(wic, Rect2(dst.position + Vector2(0, sh), dst.size), false, mod * plant_tone)
	else:
		scene.draw_texture_rect(ic, dst, false, mod)
	# огненные искры, свечение
	if HDB.has(id, "hot"):
		for k in range(4):
			var sy: float = fmod(t * 60.0 + float(k) * 30.0, 120.0)
			scene.draw_rect(Rect2(r.get_center().x + sin(t * 2.0 + k) * 30.0, r.position.y + 40 - sy, 6, 6), Color(1.0, 0.6, 0.15, 1.0 - sy / 120.0))
	# пчела / бабочка
	if st == "ground" and (HDB.has(id, "bee") or HDB.has(id, "butterfly")):
		var top: Vector2 = Vector2(float(p["x"]), r.position.y + 50.0)
		var bt: Texture2D = tex["fx_bee"] if HDB.has(id, "bee") else tex["fx_butterfly"]
		if _bug_on(p):
			scene.draw_texture_rect(bt, Rect2(top + Vector2(-24 + sin(t * 9.0) * 3.0, -20), Vector2(bt.get_width(), bt.get_height()) * 4.0), false)
		else:
			var away: float = fmod(float(p["bee"]), 7.0) - 4.0
			scene.draw_texture_rect(bt, Rect2(top + Vector2(120 * away + sin(t * 7.0) * 30.0, -60 - away * 50.0), Vector2(bt.get_width(), bt.get_height()) * 4.0), false)
	# паутинка
	if int(p["web"]) > 0 and st == "ground":
		for k in range(int(p["web"])):
			scene.draw_texture_rect(tex["fx_web"], Rect2(r.position + Vector2(float(k) * 18.0 - 10.0, 30.0 + float(k) * 40.0), Vector2(160, 160)), false, Color(1, 1, 1, 0.8))
	# глаз Бездноцвета следит за рукой
	if HDB.has(id, "stare") and st == "ground":
		var eye: Vector2 = Vector2(float(p["x"]), r.position.y + 80.0)
		var dir: Vector2 = (mouse - eye).normalized() * 6.0
		scene.draw_rect(Rect2(eye + dir - Vector2(3, 6), Vector2(6, 12)), Color.BLACK)


func _draw_hand() -> void:
	var h: Vector2 = _hand()
	if stun > 0.0:
		for k in range(3):
			var a: float = t * 5.0 + float(k) * TAU / 3.0
			top.draw_rect(Rect2(h + Vector2(cos(a) * 40.0, -60 + sin(a) * 14.0), Vector2(10, 10)), Color("f8e070"))
	var knife: bool = _knife_mode() and grab < 0
	if knife:
		top.draw_set_transform(h, -0.15, Vector2(3, 3))
		top.draw_texture(tex["st_knife"], Vector2(-6, -8))
		top.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return
	var ht: Texture2D = tex["hand_grab"] if grab >= 0 or held else tex["hand_open"]
	var tint: Color = Color(1, 0.7, 0.7) if ouch > 0.0 else Color.WHITE
	var gl: String = Game.worn("hands")
	if gl == "gloves_fire":
		tint = tint * Color(1.0, 0.55, 0.4)
	elif gl != "":
		tint = tint * Color(0.75, 0.65, 0.5)
	top.draw_texture_rect(ht, Rect2(h - Vector2(39, 30), Vector2(78, 78)), false, tint)

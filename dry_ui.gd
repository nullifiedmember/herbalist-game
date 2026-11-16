extends CanvasLayer
## Сушилка для трав (v19). Окно-сарай: жерди с крючками, корзина с травами из сумки.
##  • кликни траву в корзине — она в руке; поднеси к крючку и отпусти — повиснет на бечёвке и качается;
##  • махнёшь рукой сквозь пучки — раскачаются; брошенная мимо — летит, крутится и падает на пол;
##  • через 6 часов игры трава сохнет (буреет); сухую сними и брось в корзину — в сумке «сушёная трава».
## Пучки висят и когда окно закрыто (Game.dryer).

const DB = preload("res://herbs_db.gd")
const IT = preload("res://items_db.gd")
const PH = preload("res://phys2d.gd")
const WIN: Rect2 = Rect2(300, 130, 1320, 780)
const PX: float = 4.0
const POLES: Array = [40, 82, 124]
const HOOKS_PER: int = 8
const DRY_MIN: float = 6.0 * 60.0          # сколько игровых минут сохнет
const BASKET: Rect2 = Rect2(1290, 690, 304, 208)
const FLOOR_Y: float = WIN.position.y + 172.0 * PX
const SC: float = 3.0                      # масштаб пучка

var root: Control
var ui: Control
var is_open: bool = false
var tex: Dictionary = {}
var mouse: Vector2 = Vector2.ZERO
var prev_mouse: Vector2 = Vector2.ZERO
var held: bool = false
var t: float = 0.0
var carry: Dictionary = {}                 # {"id", "t0" (-1 — свежая)}
var swing: Dictionary = {}                 # крючок -> [угол, скорость]
var loose: Array = []                      # {"id", "t0", "body"}
var trail: Array = []
var page: int = 0


func _ready() -> void:
	layer = 31
	add_to_group("dry_ui")
	for n in ["hand_open", "hand_grab", "harvest_basket", "dry_room"]:
		tex[n] = load("res://art/%s.png" % n)
	root = Control.new()
	root.size = Vector2(1920, 1080)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.visible = false
	add_child(root)
	ui = Control.new()
	ui.size = Vector2(1920, 1080)
	ui.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(ui)
	ui.draw.connect(_draw)
	ui.gui_input.connect(_on_input)


static func abs_min() -> float:
	return float(Game.day) * 1440.0 + Game.minutes


static func hook_pos(k: int) -> Vector2:
	var row: int = k / HOOKS_PER
	var col: int = k % HOOKS_PER
	return WIN.position + Vector2(float(58 + col * 30) * PX + 2.0, float(int(POLES[row]) + 6) * PX)


static func hook_count() -> int:
	return POLES.size() * HOOKS_PER


## Насколько высохла трава на крючке (0..1)
static func dryness(t0: float) -> float:
	if t0 < 0.0:
		return 0.0
	return clampf((abs_min() - t0) / DRY_MIN, 0.0, 1.0)


func _hung_at(k: int) -> Dictionary:
	for h in Game.dryer:
		if int(h["hook"]) == k:
			return h
	return {}


## Повесить траву на крючок (зовёт и автотест). t0 < 0 — свежая, начинает сохнуть сейчас.
func hang(id: String, k: int, t0: float = -1.0) -> bool:
	if k < 0 or k >= hook_count() or not _hung_at(k).is_empty():
		return false
	Game.dryer.append({"id": id, "hook": k, "t0": t0 if t0 >= 0.0 else abs_min()})
	swing[k] = [randf_range(-0.5, 0.5), 0.0]
	return true


func unhang(k: int) -> Dictionary:
	var h: Dictionary = _hung_at(k)
	if not h.is_empty():
		Game.dryer.erase(h)
	return h


## Положить в сумку: сухую — как «сушёную», недосохшую — обратно свежей
func stash(id: String, t0: float) -> void:
	if dryness(t0) >= 1.0:
		Game.add_item("dry:" + id)
	else:
		Game.add_item(id)


func open() -> void:
	if is_open:
		return
	is_open = true
	Game.ui_open = true
	carry = {}
	loose.clear()
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	root.visible = true
	root.modulate.a = 0.0
	create_tween().tween_property(root, "modulate:a", 1.0, 0.25)


func close() -> void:
	if not is_open:
		return
	is_open = false
	if not carry.is_empty():
		stash(String(carry["id"]), float(carry["t0"]))
		carry = {}
	for lo in loose:
		stash(String(lo["id"]), float(lo["t0"]))
	loose.clear()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	var tw: Tween = create_tween()
	tw.tween_property(root, "modulate:a", 0.0, 0.18)
	tw.tween_callback(func() -> void:
		root.visible = false
		Game.ui_open = false)


func _input(event: InputEvent) -> void:
	if not is_open:
		return
	if event is InputEventKey and (event as InputEventKey).pressed and not (event as InputEventKey).echo:
		var k: Key = (event as InputEventKey).physical_keycode
		if k == KEY_ESCAPE or KB.is_key("interact", k):
			close()
			get_viewport().set_input_as_handled()


func _herbs() -> Array:
	var out: Array = []
	for id in DB.ORDER:
		if Game.get_count(String(id)) > 0:
			out.append(String(id))
	return out


func _slot_rect(i: int) -> Rect2:
	return Rect2(BASKET.position + Vector2(18.0 + float(i % 4) * 68.0, -150.0 + float(i / 4) * 0.0), Vector2(64, 150))


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
	mouse = mb.position
	if mb.pressed and (mb.button_index == MOUSE_BUTTON_WHEEL_DOWN or mb.button_index == MOUSE_BUTTON_WHEEL_UP):
		page = clampi(page + (1 if mb.button_index == MOUSE_BUTTON_WHEEL_DOWN else -1), 0, maxi(0, (_herbs().size() - 1) / 4))
		return
	if mb.button_index != MOUSE_BUTTON_LEFT:
		return
	if mb.pressed:
		held = true
		_press(mouse)
	else:
		held = false
		_release(mouse)


func _bundle_rect(k: int) -> Rect2:
	var hp: Vector2 = hook_pos(k)
	return Rect2(hp + Vector2(-34, 6), Vector2(68, 150))


func _press(p: Vector2) -> void:
	# висящие пучки
	for k in range(hook_count()):
		var h: Dictionary = _hung_at(k)
		if not h.is_empty() and _bundle_rect(k).has_point(p):
			unhang(k)
			carry = {"id": String(h["id"]), "t0": float(h["t0"])}
			Sound.play("pick", -8.0)
			return
	# лежащие на полу
	for i in range(loose.size() - 1, -1, -1):
		if PH.has_point(loose[i]["body"], p, 14.0):
			carry = {"id": String(loose[i]["id"]), "t0": float(loose[i]["t0"])}
			loose.remove_at(i)
			return
	# корзина: травы из сумки
	var hs: Array = _herbs()
	for i in range(4):
		var gi: int = page * 4 + i
		if gi < hs.size() and _slot_rect(i).has_point(p):
			var id: String = String(hs[gi])
			if Game.take_item(id):
				carry = {"id": id, "t0": -1.0}
				Sound.play("pick", -10.0)
			return


func _release(p: Vector2) -> void:
	if carry.is_empty():
		return
	var id: String = String(carry["id"])
	var t0: float = float(carry["t0"])
	carry = {}
	# к ближайшему свободному крючку
	var best: int = -1
	var bd: float = 70.0
	for k in range(hook_count()):
		var d: float = (hook_pos(k) + Vector2(0, 40)).distance_to(p)
		if d < bd and _hung_at(k).is_empty():
			bd = d
			best = k
	if best >= 0:
		hang(id, best, t0)
		swing[best] = [clampf((p.x - hook_pos(best).x) * 0.01, -0.8, 0.8), PH.throw_vel(trail).x * 0.004]
		Sound.play("knit", -10.0)
		return
	if BASKET.grow(30).has_point(p):
		stash(id, t0)
		return
	var ic: Texture2D = DB.icon(id)
	var sz: Vector2 = Vector2(ic.get_width(), ic.get_height()) * SC
	var vel: Vector2 = PH.throw_vel(trail)
	loose.append({"id": id, "t0": t0, "body": PH.make(p, Vector2(sz.x * 0.5, sz.y * 0.8), vel, vel.x * 0.006 + randf_range(-2, 2), PI + randf_range(-0.3, 0.3))})


func _process(delta: float) -> void:
	if not is_open:
		return
	t += delta
	var mv: Vector2 = (mouse - prev_mouse) / maxf(delta, 0.001)
	# маятники: качаются, затухают; рука задевает — толкает
	for k in range(hook_count()):
		if _hung_at(k).is_empty():
			continue
		if not swing.has(k):
			swing[k] = [0.0, 0.0]
		var s: Array = swing[k]
		var a: float = float(s[0])
		var w: float = float(s[1])
		w += (-16.0 * sin(a) - 1.6 * w) * delta
		if carry.is_empty() and _bundle_rect(k).grow(10).has_point(mouse) and absf(mv.x) > 250.0:
			w += mv.x * 0.0009
		a += w * delta
		s[0] = clampf(a, -1.4, 1.4)
		s[1] = w
	# брошенные: падают, крутятся; долетели до корзины — в сумку; задели крючок на лету — повисли
	var bodies: Array = []
	for i in range(loose.size() - 1, -1, -1):
		var lo: Dictionary = loose[i]
		var b: Dictionary = lo["body"]
		if PH.step(b, delta, FLOOR_Y, WIN.position.x + 10.0, WIN.end.x - 10.0):
			Sound.play("pick", -18.0, 0.25)
		var c: Vector2 = b["pos"]
		if BASKET.grow(-8).has_point(c):
			stash(String(lo["id"]), float(lo["t0"]))
			loose.remove_at(i)
			Sound.play("pickup", -6.0)
			continue
		bodies.append(b)
	PH.collide_all(bodies)
	prev_mouse = mouse
	ui.queue_redraw()


# ------------------------------------------------------------------ рисование

func _dry_mod(d: float) -> Color:
	return Color(1, 1, 1).lerp(Color(0.92, 0.76, 0.5), d)


func _draw_bundle(id: String, pivot: Vector2, ang: float, d: float) -> void:
	var ic: Texture2D = DB.icon(id)
	var sz: Vector2 = Vector2(ic.get_width(), ic.get_height()) * SC * (1.0 - 0.12 * d)
	# бечёвка от крючка
	var knot: Vector2 = pivot + Vector2(0, 26).rotated(ang)
	ui.draw_line(pivot, knot, Color("d8c890"), 3.0)
	# пучок вниз головой
	ui.draw_set_transform(knot, ang + PI, Vector2.ONE)
	ui.draw_texture_rect(ic, Rect2(-sz.x / 2.0, -sz.y + 4.0 * SC, sz.x, sz.y), false, _dry_mod(d))
	ui.draw_rect(Rect2(-8, -6, 16, 8), Color("8a6a40"))
	ui.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if d >= 1.0 and fmod(t + pivot.x * 0.01, 2.0) < 0.3:
		ui.draw_rect(Rect2(knot + Vector2(sin(t * 3.0) * 20.0, 60), Vector2(6, 6)), Color(1, 0.95, 0.7, 0.9))


func _draw() -> void:
	ui.draw_rect(Rect2(0, 0, 1920, 1080), Color(0, 0, 0, 0.55))
	ui.draw_rect(WIN.grow(14), Color("3a2414"))
	ui.draw_rect(WIN.grow(8), Color("7a5230"))
	ui.draw_texture_rect(tex["dry_room"], WIN, false)
	for k in range(hook_count()):
		var h: Dictionary = _hung_at(k)
		if h.is_empty():
			continue
		var s: Array = swing.get(k, [0.0, 0.0])
		_draw_bundle(String(h["id"]), hook_pos(k), float(s[0]), dryness(float(h["t0"])))
	# брошенные на полу
	for lo in loose:
		var b: Dictionary = lo["body"]
		var ic: Texture2D = DB.icon(String(lo["id"]))
		var sz: Vector2 = Vector2(ic.get_width(), ic.get_height()) * SC
		ui.draw_set_transform(Vector2(b["pos"]), float(b["ang"]), Vector2.ONE)
		ui.draw_texture_rect(ic, Rect2(-sz.x / 2.0, -sz.y * 0.58, sz.x, sz.y), false, _dry_mod(dryness(float(lo["t0"]))))
		ui.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# корзина с травами из сумки
	var hs: Array = _herbs()
	for i in range(4):
		var gi: int = page * 4 + i
		if gi >= hs.size():
			continue
		var r: Rect2 = _slot_rect(i)
		var ic2: Texture2D = DB.icon(String(hs[gi]))
		var isz: Vector2 = Vector2(ic2.get_width(), ic2.get_height()) * 3.0
		var lift: float = 6.0 if r.has_point(mouse) and carry.is_empty() else 0.0
		ui.draw_texture_rect(ic2, Rect2(r.position + Vector2((r.size.x - isz.x) / 2.0, r.size.y - isz.y + 60.0 - lift), isz), false)
	ui.draw_texture_rect(tex["harvest_basket"], BASKET, false)
	for i2 in range(4):
		var gi2: int = page * 4 + i2
		if gi2 < hs.size():
			var cnt: String = str(Game.get_count(String(hs[gi2])))
			ui.draw_string(ThemeDB.fallback_font, _slot_rect(i2).position + Vector2(40, 190), cnt, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("f4e8c8"))
	var pages: int = (hs.size() + 3) / 4
	if pages > 1:
		for pi in range(pages):
			ui.draw_rect(Rect2(BASKET.get_center().x - pages * 10 + pi * 20, BASKET.end.y + 6, 10, 10), Color("f0d8a0") if pi == page else Color(0.2, 0.12, 0.06, 0.8))
	# в руке
	if not carry.is_empty():
		var icc: Texture2D = DB.icon(String(carry["id"]))
		var cs: Vector2 = Vector2(icc.get_width(), icc.get_height()) * SC
		ui.draw_texture_rect(icc, Rect2(mouse - Vector2(cs.x / 2.0, cs.y * 0.2), cs), false, _dry_mod(dryness(float(carry["t0"]))))
	var ht: Texture2D = tex["hand_grab"] if (held or not carry.is_empty()) else tex["hand_open"]
	ui.draw_texture_rect(ht, Rect2(mouse - Vector2(39, 30), Vector2(78, 78)), false)

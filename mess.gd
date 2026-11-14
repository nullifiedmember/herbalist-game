extends Node2D
## Лужа или кучка после конфуза. Не привязаны к сетке: появляются там, где стояла героиня.
## Моча льётся понемногу из-под неё, капает и растекается блестящей лужей.
## Кучка шлёпается сверху. Мухи слетаются не сразу, а со временем.
## На улице лужа и кучка понемногу высыхают и становятся всё меньше; в доме лежат, пока не уберёшь шваброй.
## Не пропадают ни при заходе в дом, ни с новым днём.

const W: int = 64
const H: int = 44
const CX: float = 32.0
const CY: float = 18.0
const GROW_T: float = 4.2            # за сколько секунд растекается лужа
const PEE_LIFE: float = 600.0        # на улице лужа высыхает за ~10 игровых часов (за ночь сильно уменьшается)
const POO_LIFE: float = 1800.0       # кучка — за ~30 игровых часов (полтора дня)
const FLY_DELAY: float = 15.0        # первая муха прилетает через ~15 игровых минут
const FLY_EVERY: float = 12.0        # потом ещё по одной каждые ~12 минут
const POO_TEX: Array = ["res://art/puddle_poo.png", "res://art/poo_75.png", "res://art/poo_55.png", "res://art/poo_38.png"]

var kind: String = "pee"
var interact_offset: Vector2 = Vector2(0, 2)
var g: float = 0.0                   # растёкся ли (0..1)
var t: float = 0.0
var age_min: float = 0.0             # сколько игровых минут лежит
var amount: float = 1.0              # сколько осталось (1 — свежая, 0 — исчезла)
var indoor: bool = false
var cleaning: bool = false
var last_min: float = -1.0
var rendered_amount: float = -1.0
var img: Image
var tex: ImageTexture
var sa: float = 0.0
var sb: float = 0.0
var sc: float = 0.0
var drops: Array = []                # [позиция, скорость]
var drop_t: float = 0.0
var sparks: Array = []               # [позиция, фаза]
var poo_sprite: Sprite2D
var poo_stage: int = 0
var flies: Array = []                # [угол, радиус, скорость, высота, фаза, когда прилетела (t) или -1]
var over: Node2D


func _ready() -> void:
	add_to_group("messes")
	add_to_group("interactables")
	indoor = global_position.x > 3000.0
	z_index = -9
	sa = randf() * TAU
	sb = randf() * TAU
	sc = randf() * TAU
	last_min = Game.minutes
	over = Node2D.new()
	over.z_as_relative = false
	over.z_index = 6
	over.draw.connect(_draw_over)
	add_child(over)
	if kind == "pee":
		img = Image.create_empty(W, H, false, Image.FORMAT_RGBA8)
		tex = ImageTexture.create_from_image(img)
		for i in range(5):
			sparks.append([Vector2.ZERO, randf() * TAU])
	else:
		poo_sprite = Sprite2D.new()
		poo_sprite.texture = load(String(POO_TEX[0]))
		poo_sprite.centered = false
		poo_sprite.offset = Vector2(-10, -17)
		poo_sprite.visible = false
		add_child(poo_sprite)
		z_index = 1
		for i in range(7):
			flies.append([randf() * TAU, randf_range(5.0, 13.0), randf_range(3.0, 6.0) * (1.0 if randf() < 0.5 else -1.0), randf_range(4.0, 16.0), randf() * TAU, -1.0])


func get_prompt() -> String:
	return ""


## E со шваброй в руках — убрать
func interact() -> void:
	var m: Node = get_tree().current_scene
	if m != null and m.has_method("clean_mess"):
		m.call("clean_mess", self)


## Прошло игровое время (вызывается само каждый кадр; для проверок можно вызвать напрямую)
func advance(minutes: float) -> void:
	age_min += minutes
	if not indoor and not cleaning:
		var life: float = PEE_LIFE if kind == "pee" else POO_LIFE
		amount = clampf(1.0 - age_min / life, 0.0, 1.0)
		if amount <= 0.0:
			_vanish()


func _vanish() -> void:
	remove_from_group("interactables")
	remove_from_group("messes")
	queue_free()


## Сколько мух сейчас кружит: прилетают со временем, улетают, когда кучка почти высохла
func fly_count() -> int:
	if kind != "poo" or age_min < FLY_DELAY:
		return 0
	var n: int = 1 + int((age_min - FLY_DELAY) / FLY_EVERY)
	return mini(flies.size(), int(ceil(float(n) * clampf(amount * 1.4, 0.0, 1.0))))


func _process(delta: float) -> void:
	t += delta
	# игровое время: если наступил новый день (часы пошли сначала) — прошла ночь
	var now: float = Game.minutes
	if last_min >= 0.0:
		var dm: float = now - last_min
		if dm < -1.0:
			dm = (24.0 * 60.0 - last_min) + now
		if dm > 0.0:
			advance(dm)
	last_min = now
	if is_queued_for_deletion():
		return
	if kind == "pee":
		if g < 1.0:
			g = minf(1.0, g + delta / GROW_T)
			drop_t -= delta
			if g < 0.85 and drop_t <= 0.0:
				drop_t = 0.06
				drops.append([Vector2(randf_range(-2.0, 2.0), -13.0), Vector2(randf_range(-9.0, 9.0), randf_range(4.0, 14.0))])
		var ge: float = (1.0 - pow(1.0 - g, 2.2)) * (0.18 + 0.82 * sqrt(amount))
		if absf(ge - rendered_amount) > 0.015:
			rendered_amount = ge
			_render(ge, amount)
		var i: int = drops.size() - 1
		while i >= 0:
			var d: Array = drops[i]
			var v: Vector2 = d[1]
			v.y += 150.0 * delta
			d[1] = v
			d[0] = (d[0] as Vector2) + v * delta
			if (d[0] as Vector2).y > randf_range(-1.0, 3.0):
				drops.remove_at(i)
			i -= 1
		queue_redraw()
		over.queue_redraw()
	else:
		if t >= 0.6 and not poo_sprite.visible:
			poo_sprite.visible = true
		if poo_sprite.visible:
			var p: float = clampf((t - 0.6) / 0.35, 0.0, 1.0)
			poo_sprite.position.y = -14.0 * (1.0 - p * p)
			var s: float = clampf(1.0 - (t - 0.95) / 0.3, 0.0, 1.0)
			poo_sprite.scale = Vector2(1.0 + 0.14 * s, 1.0 - 0.14 * s)
			# высыхает: меньше и темнее (пиксельные размеры, без размытия)
			var st: int = 0 if amount > 0.75 else (1 if amount > 0.5 else (2 if amount > 0.25 else 3))
			if st != poo_stage:
				poo_stage = st
				poo_sprite.texture = load(String(POO_TEX[st]))
			var dry: float = 1.0 - 0.25 * (1.0 - amount)
			poo_sprite.modulate = Color(dry, dry * 0.97, dry * 0.95, 1.0)
		over.queue_redraw()


## Лужа пикселями: тёмная намокшая земля, светлый влажный край, глубокий центр, блики.
## Форма неровная и тянется вниз, как будто стекает. Подсыхая, бледнеет и уменьшается.
func _render(gr: float, amt: float) -> void:
	img.fill(Color(0, 0, 0, 0))
	var rx: float = 24.0 * gr
	var ry: float = 12.0 * gr
	if rx < 1.0:
		tex.update(img)
		return
	var fade: float = clampf(0.45 + 0.55 * amt, 0.0, 1.0)
	for y in range(H):
		for x in range(W):
			var dx: float = (float(x) + 0.5 - CX) / rx
			var dy: float = (float(y) + 0.5 - CY) / ry
			var ang: float = atan2(dy, dx)
			var wob: float = 1.0 + 0.11 * sin(ang * 3.0 + sa) + 0.07 * sin(ang * 5.0 + sb) + 0.04 * sin(ang * 7.0 + sc) + 0.14 * maxf(0.0, sin(ang))
			var d: float = sqrt(dx * dx + dy * dy) / wob
			if d > 1.2:
				continue
			var c: Color
			if d > 1.0:
				c = Color(0.30, 0.25, 0.09, 0.40)
			elif d > 0.9:
				c = Color("f6e9a0") if dy < 0.15 else Color("e8d070")
			elif d > 0.72:
				c = Color("d8b43a")
			elif d > 0.46:
				c = Color("bc9622")
			else:
				c = Color("9c7414")
			var h1: float = (dx + 0.34) / 0.42
			var h2: float = (dy + 0.32) / 0.16
			if h1 * h1 + h2 * h2 < 1.0:
				c = Color("fffdf0")
			else:
				var k1: float = (dx - 0.22) / 0.26
				var k2: float = (dy - 0.12) / 0.07
				var m1: float = (dx + 0.05) / 0.34
				var m2: float = (dy - 0.34) / 0.05
				if k1 * k1 + k2 * k2 < 1.0:
					c = Color("fff6bc")
				elif m1 * m1 + m2 * m2 < 1.0 and d < 0.85:
					c = Color("f2f0c0")
				elif d > 0.8 and d <= 0.9 and dy < -0.25:
					c = Color("fffbe2")
				elif d > 0.78 and d <= 0.86 and dy > 0.35 and dx > 0.1:
					c = Color("f0dc78")
			c.a *= fade
			img.set_pixel(x, y, c)
	tex.update(img)


func _draw() -> void:
	if kind != "pee" or tex == null:
		return
	draw_texture(tex, Vector2(-CX, -CY + 6.0))
	# искорки, как на воде пруда (на подсохшей луже реже)
	var rr: float = 20.0 * rendered_amount
	for s in sparks:
		var ph: float = float(s[1]) + t * 1.8
		var k: float = maxf(0.0, sin(ph)) * clampf(amount * 1.5, 0.0, 1.0)
		if k < 0.05:
			var a: float = randf() * TAU
			s[0] = Vector2(cos(a) * rr * 0.7, sin(a) * rr * 0.32 + 7.0)
		if k > 0.6:
			var sp: Vector2 = s[0]
			var x: float = floorf(sp.x)
			var y: float = floorf(sp.y)
			draw_rect(Rect2(x, y, 1, 1), Color(1, 1, 0.9, k))
			draw_rect(Rect2(x - 1, y, 1, 1), Color(1, 1, 0.8, k * 0.5))
			draw_rect(Rect2(x + 1, y, 1, 1), Color(1, 1, 0.8, k * 0.5))
			draw_rect(Rect2(x, y - 1, 1, 1), Color(1, 1, 0.8, k * 0.5))


## Поверх героини: струйка и капли; у кучки — мухи (прилетают издалека и кружат)
func _draw_over() -> void:
	if kind == "pee":
		if g < 0.9:
			var w: int = 2 if g < 0.5 else 1
			for yy in range(-13, 0):
				var jx: float = floorf(sin(t * 31.0 + float(yy) * 0.8) * 0.6)
				over.draw_rect(Rect2(jx - float(w) / 2.0, float(yy), float(w), 1), Color("e8c848"))
				if (yy + int(t * 18.0)) % 4 == 0:
					over.draw_rect(Rect2(jx, float(yy), 1, 1), Color("fff1a8"))
		for d in drops:
			var dp: Vector2 = d[0]
			over.draw_rect(Rect2(floorf(dp.x), floorf(dp.y), 1, 1), Color("f0d868"))
		return
	var n: int = fly_count()
	for i in range(flies.size()):
		var f: Array = flies[i]
		if i >= n:
			f[5] = -1.0
			continue
		if float(f[5]) < 0.0:
			f[5] = t
		var arrive: float = clampf(1.0 - (t - float(f[5])) / 2.0, 0.0, 1.0)
		f[0] = float(f[0]) + float(f[2]) * 0.016 * (1.0 + 0.6 * sin(t * 6.0 + float(f[4])))
		var rad: float = float(f[1]) * (0.75 + 0.45 * sin(t * 1.6 + float(f[4]) * 2.0)) + arrive * 70.0
		var fp: Vector2 = Vector2(cos(float(f[0])) * rad, sin(float(f[0])) * rad * 0.55 - 6.0 - float(f[3]) * (0.7 + 0.3 * sin(t * 2.3 + float(f[4]))) - arrive * 30.0)
		if int(t * 3.0 + float(f[4])) % 11 == 0:
			f[2] = -float(f[2])
		var fx: float = floorf(fp.x)
		var fy: float = floorf(fp.y)
		over.draw_rect(Rect2(fx, fy, 3, 2), Color("1c1620"))
		over.draw_rect(Rect2(fx + 1, fy, 1, 1), Color("3a3446"))
		var up: bool = int(t * 40.0 + float(i)) % 2 == 0
		over.draw_rect(Rect2(fx - 1, fy - (1 if up else 0), 1, 1), Color(0.82, 0.88, 0.98, 0.95))
		over.draw_rect(Rect2(fx + 3, fy - (1 if up else 0), 1, 1), Color(0.82, 0.88, 0.98, 0.95))

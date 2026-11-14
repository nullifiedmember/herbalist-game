extends SceneTree
## Пиксель-арт снаряжения и инвентаря (v14):
##   значки вещей gear_<id>.png 24×24 (инструменты, рюкзаки, одежда, кольца, амулеты, пояса),
##   панель инвентаря в духе Path of Exile (inv_bg, inv_slot, inv_cell, inv_crest, inv_plaque, inv_close, inv_lock),
##   полка лавки shelf14 и ценники (price_digits, price_coin).
## Запуск: godot --headless --path game --script res://tools/art_gear.gd
## Превью: screenshots/v14_gear.png (x6)

const OUT: String = "res://art/"
var LT: Vector3 = Vector3(-0.55, -0.7, 0.75).normalized()
var sheet: Array = []

# палитры: от тени к блику
var WOOD: Array = hx(["2a1a10", "3a2418", "54361e", "6e4a2a", "8a6038", "a67a4a", "c49a66"])
var IRON: Array = hx(["24242c", "30303a", "464652", "6e6e7c", "9a9aa6", "c8c8d0", "eeeef4"])
var GOLD: Array = hx(["4a3008", "6a4a0a", "9a6e14", "c8961e", "e8bc3a", "f8dc70", "fff4c0"])
var LEATHER: Array = hx(["2a1810", "3a2214", "5a3620", "7a4a2c", "9a643c", "b8824e", "d8a46a"])
var STRAW: Array = hx(["5a4010", "7a5a1a", "a07a2a", "c8a040", "e0c060", "f0d888", "fff0c0"])
var GREEN: Array = hx(["142a18", "1e3a26", "2e5a36", "3e7a46", "5a9a5a", "80b878", "b0d8a0"])
var RAG: Array = hx(["2a2018", "3a2c22", "54402e", "6e5640", "8a6e52", "a68a6a", "c4a888"])
var BLUE: Array = hx(["141c34", "1e2a4a", "2e3e6a", "3e568a", "5a74a8", "7e98c4", "b0c4e0"])
var WHITE: Array = hx(["4a4a54", "6a6a74", "8e8e98", "b0b0b8", "cfcfd6", "e8e8ee", "ffffff"])
var PURPLE: Array = hx(["1c1028", "2a1a3a", "42285a", "5a387a", "74509a", "9470b8", "b898d8"])
var CREAM: Array = hx(["6a5a3a", "8a7a5a", "a8987a", "c8b898", "e0d4b8", "f0e8d4", "fffaf0"])
var LEAF: Array = hx(["0e2a10", "1a4a1a", "2a6a2a", "3a8a3a", "5aaa4a", "8ac86a", "c0e8a0"])
var MOON: Array = hx(["2e3a5a", "4a5a8a", "6a7aaa", "8a9ac8", "b0c0e0", "d8e4f4", "ffffff"])
var AMBER: Array = hx(["4a2408", "6a3a0a", "9a5a10", "c8801a", "e8a83a", "f8cc6a", "ffecb0"])
var COPPER: Array = hx(["2a1608", "4a2a1a", "7a4220", "a85a2a", "c87a40", "e09a60", "f8c090"])
var RED: Array = hx(["3a0a0a", "6a1a1a", "9a2a22", "c43a2a", "e05a3a", "f08a6a", "fcb8a0"])
var WICKER: Array = hx(["3a2410", "5a3a18", "7a5424", "9a7034", "b88c48", "d4aa64", "ecc888"])
var STONE: Array = hx(["0e1214", "151b1e", "1c2427", "242e32", "2c383c", "364448", "425256"])


func hx(a: Array) -> Array:
	var r: Array = []
	for s in a:
		r.append(Color(String(s)))
	return r


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	if OS.get_cmdline_user_args().has("--sea"):
		gen_sea_herbs()
		print("SEA HERB ART DONE")
		quit()
		return
	if OS.get_cmdline_user_args().has("--herbs"):
		gen_herbs()
		print("HERB ART DONE")
		quit()
		return
	gen_icons()
	gen_ui()
	gen_shelf()
	_preview()
	print("GEAR ART DONE")
	quit()


# ------------------------------------------------------------------ основа рисования

func img(w: int, h: int) -> Image:
	return Image.create_empty(w, h, false, Image.FORMAT_RGBA8)


func px(im: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < im.get_width() and y < im.get_height():
		if c.a >= 1.0:
			im.set_pixel(x, y, c)
		else:
			im.set_pixel(x, y, im.get_pixel(x, y).blend(c))


func rect(im: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	for yy in range(y, y + h):
		for xx in range(x, x + w):
			px(im, xx, yy, c)


func line(im: Image, x0: int, y0: int, x1: int, y1: int, c: Color) -> void:
	var dx: int = absi(x1 - x0)
	var dy: int = -absi(y1 - y0)
	var sx: int = 1 if x0 < x1 else -1
	var sy: int = 1 if y0 < y1 else -1
	var err: int = dx + dy
	while true:
		px(im, x0, y0, c)
		if x0 == x1 and y0 == y1:
			break
		var e2: int = 2 * err
		if e2 >= dy:
			err += dy
			x0 += sx
		if e2 <= dx:
			err += dx
			y0 += sy


func h01(x: int, y: int, s: int = 0) -> float:
	var n: int = x * 374761393 + y * 668265263 + s * 982451653
	n = (n ^ (n >> 13)) * 1274126177
	n = n ^ (n >> 16)
	return float(n & 0xffff) / 65535.0


## Освещённый овал (как камешек/подушка): цвет по нормали, ступенями палитры
func blob(im: Image, cx: float, cy: float, rx: float, ry: float, ramp: Array, bias: float = 0.0) -> void:
	for y in range(int(floor(cy - ry)) - 1, int(ceil(cy + ry)) + 1):
		for x in range(int(floor(cx - rx)) - 1, int(ceil(cx + rx)) + 1):
			var nx: float = (x + 0.5 - cx) / rx
			var ny: float = (y + 0.5 - cy) / ry
			var d: float = nx * nx + ny * ny
			if d > 1.0:
				continue
			var n: Vector3 = Vector3(nx, ny, sqrt(maxf(0.0, 1.0 - d)))
			var l: float = clampf(-n.dot(Vector3(LT.x, LT.y, -LT.z)) * 0.5 + 0.5 + bias, 0.0, 0.999)
			l = clampf(n.dot(-Vector3(LT.x, LT.y, -LT.z)), -1.0, 1.0)
			var k: float = clampf(0.5 + 0.5 * (-nx * 0.55 - ny * 0.7 + n.z * 0.45) + bias, 0.0, 0.999)
			px(im, x, y, ramp[int(k * (ramp.size() - 1) + 0.5)])


## Толстая линия-цилиндр (рукоять, ремень): свет сверху-слева
func rod(im: Image, a: Vector2, b: Vector2, r: float, ramp: Array, base: int = 3) -> void:
	var ab: Vector2 = b - a
	var nrm: Vector2 = ab.normalized().orthogonal()
	if nrm.dot(Vector2(-0.6, -0.8)) < 0.0:
		nrm = -nrm
	var lo: Vector2 = Vector2(minf(a.x, b.x), minf(a.y, b.y)) - Vector2.ONE * (r + 1.0)
	var hi: Vector2 = Vector2(maxf(a.x, b.x), maxf(a.y, b.y)) + Vector2.ONE * (r + 1.0)
	for y in range(int(lo.y), int(hi.y) + 1):
		for x in range(int(lo.x), int(hi.x) + 1):
			var p: Vector2 = Vector2(x + 0.5, y + 0.5)
			var t: float = clampf((p - a).dot(ab) / maxf(0.001, ab.length_squared()), 0.0, 1.0)
			var q: Vector2 = a + ab * t
			var d: float = p.distance_to(q)
			if d > r:
				continue
			var side: float = (p - q).dot(nrm) / maxf(0.5, r)
			var k: int = clampi(base + int(round(side * 2.0)), 0, ramp.size() - 1)
			px(im, x, y, ramp[k])


## Заливка многоугольника; цвет — функция (x, y) -> Color
func poly(im: Image, pts: PackedVector2Array, col: Callable) -> void:
	var lo: Vector2 = pts[0]
	var hi: Vector2 = pts[0]
	for p in pts:
		lo = Vector2(minf(lo.x, p.x), minf(lo.y, p.y))
		hi = Vector2(maxf(hi.x, p.x), maxf(hi.y, p.y))
	for y in range(int(floor(lo.y)), int(ceil(hi.y)) + 1):
		for x in range(int(floor(lo.x)), int(ceil(hi.x)) + 1):
			if Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), pts):
				var c: Color = col.call(x, y)
				if c.a > 0.0:
					px(im, x, y, c)


## Плоская заливка многоугольника с тенью справа-снизу и светом слева-сверху
func shaded_poly(im: Image, pts: PackedVector2Array, ramp: Array, base: int = 3) -> void:
	var c: Vector2 = Vector2.ZERO
	for p in pts:
		c += p
	c /= float(pts.size())
	var lo: Vector2 = pts[0]
	var hi: Vector2 = pts[0]
	for p2 in pts:
		lo = Vector2(minf(lo.x, p2.x), minf(lo.y, p2.y))
		hi = Vector2(maxf(hi.x, p2.x), maxf(hi.y, p2.y))
	var sz: Vector2 = (hi - lo).max(Vector2.ONE)
	poly(im, pts, func(x: int, y: int) -> Color:
		var u: float = (float(x) + 0.5 - c.x) / sz.x
		var v: float = (float(y) + 0.5 - c.y) / sz.y
		var k: int = clampi(base + int(round(-(u * 1.6 + v * 2.0))), 0, ramp.size() - 1)
		return ramp[k])


## Обводка: прозрачный пиксель рядом с непрозрачным становится тёмным краем соседнего цвета
func outline(im: Image, strength: float = 0.6) -> void:
	var src: Image = im.duplicate()
	var w: int = im.get_width()
	var h: int = im.get_height()
	for y in range(h):
		for x in range(w):
			if src.get_pixel(x, y).a > 0.1:
				continue
			var best: Color = Color(0, 0, 0, 0)
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var q: Vector2i = Vector2i(x, y) + (d as Vector2i)
				if q.x < 0 or q.y < 0 or q.x >= w or q.y >= h:
					continue
				var c: Color = src.get_pixel(q.x, q.y)
				if c.a > 0.5:
					best = c
			if best.a > 0.0:
				var o: Color = best.darkened(strength)
				o = o.lerp(Color("1a1018"), 0.45)
				o.a = 1.0
				im.set_pixel(x, y, o)


func save(im: Image, name: String, show: bool = true) -> void:
	im.save_png(OUT + name + ".png")
	if show:
		sheet.append([name, im])


func _preview() -> void:
	var sc: int = 6
	var cols: int = 9
	var cw: int = 24 * sc + 12
	var big: Image = img(cols * cw + 12, 12 + (int(ceil(float(sheet.size()) / cols)) * (cw + 0)))
	big.fill(Color("3a3530"))
	var i: int = 0
	for it in sheet:
		var im: Image = (it[1] as Image).duplicate()
		if im.get_width() > 40:
			continue
		im.resize(im.get_width() * sc, im.get_height() * sc, Image.INTERPOLATE_NEAREST)
		var x: int = 12 + (i % cols) * cw
		var y: int = 12 + (i / cols) * cw
		big.blend_rect(im, Rect2i(0, 0, im.get_width(), im.get_height()), Vector2i(x, y))
		i += 1
	big.save_png(ProjectSettings.globalize_path("res://").path_join("../screenshots/v14_gear.png"))
	# крупные картинки интерфейса отдельно
	var ui: Image = img(1500, 1100)
	ui.fill(Color("3a3530"))
	var x2: int = 10
	var y2: int = 10
	var row: int = 0
	for it2 in sheet:
		var im2: Image = (it2[1] as Image).duplicate()
		if im2.get_width() <= 40:
			continue
		var s2: int = 2 if im2.get_width() > 120 else 4
		im2.resize(im2.get_width() * s2, im2.get_height() * s2, Image.INTERPOLATE_NEAREST)
		if x2 + im2.get_width() > 1490:
			x2 = 10
			y2 += row + 10
			row = 0
		ui.blend_rect(im2, Rect2i(0, 0, im2.get_width(), im2.get_height()), Vector2i(x2, y2))
		x2 += im2.get_width() + 10
		row = maxi(row, im2.get_height())
	ui.save_png(ProjectSettings.globalize_path("res://").path_join("../screenshots/v14_ui.png"))


# ------------------------------------------------------------------ значки вещей

func gen_icons() -> void:
	icon_axe()
	icon_sickle("sickle", IRON)
	icon_sickle("gold_sickle", GOLD)
	icon_knife()
	icon_trowel()
	icon_shovel()
	icon_lantern()
	icon_herbarium()
	icon_hat_straw()
	icon_wreath()
	icon_hood()
	icon_goggles()
	icon_witch_hat()
	icon_body("rags", RAG)
	icon_body("dress", GREEN)
	icon_cloak()
	icon_body("lab_coat", WHITE)
	icon_apron()
	icon_glove("gloves_garden", GREEN)
	icon_glove("gloves_leather", LEATHER)
	icon_boots("boots_old", RAG, false)
	icon_boots("boots_travel", LEATHER, true)
	icon_amulet("amulet_clover")
	icon_amulet("amulet_moon")
	icon_ring("ring_copper", COPPER, RED)
	icon_ring("ring_moss", WOOD, LEAF)
	icon_ring("ring_amber", GOLD, AMBER)
	icon_belt("belt_rope", STRAW, 3)
	icon_belt("belt_leather", LEATHER, 5)
	icon_pack_sack()
	icon_basket()
	icon_herb_bag()
	icon_creel()
	icon_alch_box()
	icon_travel_pack()


func icon_axe() -> void:
	var im: Image = img(24, 24)
	rod(im, Vector2(5, 21.5), Vector2(15.5, 4.5), 1.4, WOOD, 4)
	# обмотка рукояти
	for k in range(3):
		var p: Vector2 = Vector2(5, 21.5).lerp(Vector2(15.5, 4.5), 0.12 + k * 0.07)
		px(im, int(p.x), int(p.y), LEATHER[2])
		px(im, int(p.x) + 1, int(p.y), LEATHER[4])
	# лезвие: клин с дугой, кромка светлая
	var pts: PackedVector2Array = PackedVector2Array([Vector2(12, 4), Vector2(17, 2.5), Vector2(22, 1.5), Vector2(23, 6), Vector2(22, 11), Vector2(17, 9.5), Vector2(13, 9)])
	shaded_poly(im, pts, IRON, 3)
	for y in range(2, 11):
		px(im, 22, y, IRON[6] if y < 6 else IRON[5])
	line(im, 13, 5, 17, 4, IRON[5])
	px(im, 15, 6, IRON[1])
	px(im, 15, 7, IRON[2])
	outline(im)
	save(im, "gear_axe")


func icon_sickle(name: String, blade: Array) -> void:
	var im: Image = img(24, 24)
	# серп: дуга от рукояти (внизу слева) через верх к острию справа, к острию тоньше
	var c: Vector2 = Vector2(13.5, 11.0)
	var total: float = (PI - 2.25) + (PI + 0.45)
	for y in range(0, 22):
		for x in range(2, 24):
			var p: Vector2 = Vector2(x + 0.5, y + 0.5)
			var d: float = p.distance_to(c)
			var a: float = atan2(p.y - c.y, p.x - c.x)
			var s: float = -1.0
			if a >= 2.25:
				s = a - 2.25
			elif a <= 0.45:
				s = a + TAU - 2.25
			if s < 0.0:
				continue
			var thick: float = 3.0 * (1.0 - 0.8 * s / total)
			if d < 8.6 and d > 8.6 - thick:
				var edge: bool = d < 8.6 - thick + 1.0
				var lit: bool = a < -0.4 and a > -2.4
				px(im, x, y, blade[6] if edge else (blade[4] if lit else blade[3]))
	rod(im, Vector2(3.5, 23), Vector2(8.0, 18.0), 1.6, WOOD, 4)
	rect(im, 7, 16, 3, 3, blade[2])
	px(im, 7, 16, blade[5])
	if name == "gold_sickle":
		# зелёный листик-оберег на шнурке
		px(im, 6, 17, LEAF[5])
		px(im, 5, 18, LEAF[4])
		px(im, 6, 18, LEAF[3])
		px(im, 5, 19, LEAF[2])
		px(im, 7, 16, GOLD[4])
	outline(im)
	save(im, "gear_" + name)


func icon_knife() -> void:
	var im: Image = img(24, 24)
	rod(im, Vector2(4, 20), Vector2(10, 14), 1.9, WOOD, 4)
	rect(im, 9, 12, 3, 3, IRON[3])
	px(im, 10, 12, IRON[5])
	# короткое изогнутое лезвие грибника
	var pts: PackedVector2Array = PackedVector2Array([Vector2(11, 13), Vector2(15, 8), Vector2(19, 4), Vector2(21, 3.5), Vector2(19.5, 7), Vector2(16, 11), Vector2(12.5, 14.5)])
	shaded_poly(im, pts, IRON, 4)
	line(im, 12, 13, 19, 5, IRON[6])
	# щёточка на конце рукояти — счищать землю с грибов
	for k in range(4):
		line(im, 3 - (k % 2), 20 + k, 1, 21 + k, STRAW[3 + (k % 2)])
	outline(im)
	save(im, "gear_knife")


func icon_trowel() -> void:
	var im: Image = img(24, 24)
	rod(im, Vector2(3.5, 21), Vector2(9, 15.5), 2.0, RED, 3)
	rod(im, Vector2(9, 15.5), Vector2(11.5, 13), 0.8, IRON, 3)
	var pts: PackedVector2Array = PackedVector2Array([Vector2(10, 12), Vector2(16, 4), Vector2(21, 2), Vector2(22, 3), Vector2(20, 8), Vector2(12, 14)])
	shaded_poly(im, pts, IRON, 4)
	line(im, 12, 12, 19, 4, IRON[2])
	px(im, 20, 3, IRON[6])
	# комочек земли на совке
	px(im, 15, 9, WOOD[2])
	px(im, 16, 8, WOOD[3])
	outline(im)
	save(im, "gear_trowel")


func icon_shovel() -> void:
	var im: Image = img(24, 24)
	rod(im, Vector2(6, 17), Vector2(18.5, 3.5), 1.3, WOOD, 4)
	# D-ручка
	for a in range(0, 12):
		var ang: float = PI * float(a) / 11.0
		px(im, 19 + int(round(cos(ang - 0.8) * 2.5)), 2 + int(round(sin(ang - 0.8) * 2.5)), WOOD[5])
	var pts: PackedVector2Array = PackedVector2Array([Vector2(5, 13), Vector2(9, 17), Vector2(5, 23), Vector2(1.5, 22.5), Vector2(1, 18)])
	shaded_poly(im, pts, IRON, 3)
	line(im, 5, 14, 2, 18, IRON[5])
	outline(im)
	save(im, "gear_shovel")


func icon_lantern() -> void:
	var im: Image = img(24, 24)
	# кольцо
	for a in range(16):
		var ang: float = TAU * float(a) / 16.0
		px(im, 12 + int(round(cos(ang) * 2.5)), 3 + int(round(sin(ang) * 2.0)), IRON[4] if a > 8 else IRON[2])
	# крышка
	poly(im, PackedVector2Array([Vector2(7, 8), Vector2(12, 5), Vector2(17, 8)]), func(x: int, _y: int) -> Color: return IRON[4] if x < 12 else IRON[2])
	rect(im, 7, 8, 11, 1, IRON[3])
	# стекло со светом
	for y in range(9, 18):
		for x in range(8, 17):
			var d: float = Vector2(x + 0.5 - 12.5, y + 0.5 - 13.5).length()
			px(im, x, y, AMBER[6] if d < 1.8 else (AMBER[5] if d < 3.2 else AMBER[4]))
	# рамки
	for x in [7, 12, 17]:
		line(im, x, 9, x, 18, IRON[3] if x == 7 else IRON[1])
	px(im, 11, 12, Color("fff8e0"))
	rect(im, 6, 18, 13, 2, IRON[3])
	rect(im, 6, 18, 13, 1, IRON[4])
	rect(im, 8, 20, 9, 1, IRON[1])
	outline(im)
	save(im, "gear_lantern_hand")


func icon_herbarium() -> void:
	var im: Image = img(24, 24)
	# книга в три четверти: обложка, страницы снизу
	rect(im, 4, 18, 17, 3, CREAM[4])
	for x in range(4, 21):
		px(im, x, 19, CREAM[2] if x % 2 == 0 else CREAM[3])
	shaded_poly(im, PackedVector2Array([Vector2(3, 3), Vector2(20, 2), Vector2(21, 18), Vector2(4, 19)]), LEATHER, 3)
	rect(im, 3, 3, 2, 16, LEATHER[1])
	# прижатый лист на обложке
	var lc: Vector2 = Vector2(12.5, 10.5)
	for y in range(5, 17):
		for x in range(7, 19):
			var p: Vector2 = Vector2(x + 0.5, y + 0.5) - lc
			var r: Vector2 = Vector2(p.x * 0.7 - p.y * 0.7, p.x * 0.7 + p.y * 0.7)
			if (r.x / 6.0) * (r.x / 6.0) + (r.y / 2.6) * (r.y / 2.6) <= 1.0:
				px(im, x, y, LEAF[4] if r.y < 0 else LEAF[3])
	line(im, 9, 14, 16, 7, LEAF[1])
	# золотые уголки
	for c in [Vector2i(4, 3), Vector2i(19, 2), Vector2i(19, 17), Vector2i(5, 17)]:
		var cv: Vector2i = c
		rect(im, cv.x, cv.y, 2, 2, GOLD[4])
	outline(im)
	save(im, "gear_herbarium")


func icon_hat_straw() -> void:
	var im: Image = img(24, 24)
	# поля
	for y in range(10, 22):
		for x in range(1, 23):
			var d: float = Vector2((x + 0.5 - 12.0) / 11.0, (y + 0.5 - 16.0) / 5.2).length()
			if d <= 1.0:
				var k: int = 5 if y < 14 else (4 if d < 0.8 else 3)
				if (x + y * 2) % 4 == 0:
					k -= 1
				px(im, x, y, STRAW[k])
	# тулья
	blob(im, 12, 11, 6.5, 6, STRAW)
	for x in range(6, 18):
		if x % 3 == 0:
			px(im, x, 9 + (x % 2), STRAW[2])
	# лента с цветком
	rect(im, 6, 13, 13, 2, RED[3])
	rect(im, 6, 13, 13, 1, RED[4])
	px(im, 16, 12, Color("f8f0e0"))
	px(im, 17, 13, Color("f8f0e0"))
	px(im, 16, 14, Color("f8f0e0"))
	px(im, 15, 13, Color("f8f0e0"))
	px(im, 16, 13, GOLD[5])
	outline(im)
	save(im, "gear_hat_straw")


func icon_wreath() -> void:
	var im: Image = img(24, 24)
	var c: Vector2 = Vector2(12, 12.5)
	# плетёная основа
	for i in range(48):
		var a0: float = TAU * float(i) / 48.0
		px(im, int(c.x + cos(a0) * 8.0), int(c.y + sin(a0) * 6.6), WOOD[3])
	# листья внахлёст, каждый — маленький освещённый овал
	for i in range(16):
		var a: float = TAU * float(i) / 16.0
		var p: Vector2 = c + Vector2(cos(a) * 8.0, sin(a) * 6.6)
		var low: bool = sin(a) > 0.2
		blob(im, p.x, p.y, 2.3, 1.7, LEAF, -0.15 if low else 0.05)
	# цветочки
	for fa in [0.3, 1.9, 3.4, 4.8]:
		var fp: Vector2 = c + Vector2(cos(fa), sin(fa) * 0.8) * 7.5
		var col: Color = [Color("f8f0f8"), Color("f0a8c8"), Color("a8c0f8"), Color("f8e070")][int(fa) % 4]
		for d in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
			px(im, int(fp.x + (d as Vector2).x), int(fp.y + (d as Vector2).y), col)
		px(im, int(fp.x), int(fp.y), GOLD[5])
	outline(im)
	save(im, "gear_wreath")


func icon_hood() -> void:
	var im: Image = img(24, 24)
	var pts: PackedVector2Array = PackedVector2Array([Vector2(12, 1.5), Vector2(18, 5), Vector2(21, 12), Vector2(22, 21), Vector2(2, 21), Vector2(3, 12), Vector2(6, 5)])
	shaded_poly(im, pts, BLUE, 3)
	# проём для лица — тень внутри
	for y in range(7, 19):
		for x in range(6, 18):
			var d: float = Vector2((x + 0.5 - 12.0) / 5.0, (y + 0.5 - 13.0) / 6.0).length()
			if d <= 1.0:
				px(im, x, y, BLUE[0] if d < 0.75 else BLUE[1])
	# складки и кайма
	line(im, 3, 20, 21, 20, BLUE[5])
	line(im, 7, 6, 4, 14, BLUE[5])
	line(im, 18, 7, 20, 15, BLUE[1])
	px(im, 12, 20, GOLD[4])
	px(im, 11, 20, GOLD[5])
	outline(im)
	save(im, "gear_hood")


func icon_goggles() -> void:
	var im: Image = img(24, 24)
	# ремешок
	rod(im, Vector2(1, 9), Vector2(23, 9), 1.2, LEATHER, 3)
	for cx in [7.0, 17.0]:
		for y in range(5, 18):
			for x in range(1, 24):
				var d: float = Vector2(x + 0.5 - cx, y + 0.5 - 11.0).length()
				if d <= 5.4:
					if d > 4.0:
						px(im, x, y, GOLD[5] if (x + 0.5 - cx) + (y + 0.5 - 11.0) < 0 else GOLD[2])
					else:
						var k: float = (x + 0.5 - cx) * 0.6 + (y + 0.5 - 11.0)
						px(im, x, y, Color("9ad8d0") if k < -2.0 else (Color("5aa8a8") if k < 1.5 else Color("2e6a72")))
		px(im, int(cx) - 2, 8, Color("ffffff"))
		px(im, int(cx) - 1, 8, Color("e0fff8"))
	rect(im, 11, 10, 2, 2, GOLD[3])
	outline(im)
	save(im, "gear_goggles")


func icon_witch_hat() -> void:
	var im: Image = img(24, 24)
	for y in range(15, 23):
		for x in range(0, 24):
			var d: float = Vector2((x + 0.5 - 12.0) / 11.5, (y + 0.5 - 18.5) / 3.6).length()
			if d <= 1.0:
				px(im, x, y, PURPLE[4] if y < 18 else PURPLE[2])
	var pts: PackedVector2Array = PackedVector2Array([Vector2(6, 19), Vector2(9, 9), Vector2(13, 4), Vector2(19, 1), Vector2(16, 5), Vector2(15, 10), Vector2(18, 19)])
	shaded_poly(im, pts, PURPLE, 3)
	rect(im, 7, 15, 11, 3, Color("3a2a1a"))
	rect(im, 7, 15, 11, 1, Color("5a4228"))
	# пряжка-звезда
	rect(im, 11, 15, 3, 3, GOLD[4])
	px(im, 12, 16, GOLD[6])
	px(im, 18, 1, GOLD[5])
	outline(im)
	save(im, "gear_witch_hat")


func icon_body(name: String, ramp: Array) -> void:
	var im: Image = img(24, 24)
	var pts: PackedVector2Array
	if name == "dress":
		pts = PackedVector2Array([Vector2(8, 2), Vector2(16, 2), Vector2(20, 6), Vector2(18, 9), Vector2(16, 8), Vector2(16, 12), Vector2(21, 22), Vector2(3, 22), Vector2(8, 12), Vector2(8, 8), Vector2(6, 9), Vector2(4, 6)])
	else:
		pts = PackedVector2Array([Vector2(8, 2), Vector2(16, 2), Vector2(22, 6), Vector2(21, 11), Vector2(18, 10), Vector2(18, 22), Vector2(6, 22), Vector2(6, 10), Vector2(3, 11), Vector2(2, 6)])
	shaded_poly(im, pts, ramp, 3)
	# ворот
	for x in range(9, 16):
		px(im, x, 2 + int(absf(x - 12) < 2), ramp[1])
	px(im, 12, 4, ramp[1])
	match name:
		"rags":
			# заплатки и рваный подол
			rect(im, 8, 13, 4, 4, Color("6a5a7a"))
			for k in range(4):
				px(im, 8 + k, 13, Color("8a7a9a"))
			px(im, 9, 14, Color("d8d0c0"))
			px(im, 11, 16, Color("d8d0c0"))
			rect(im, 14, 7, 3, 3, Color("7a8a5a"))
			for x2 in range(6, 18):
				if x2 % 3 != 1:
					px(im, x2, 21, Color(0, 0, 0, 0))
					im.set_pixel(x2, 21, Color(0, 0, 0, 0))
				if x2 % 4 == 0:
					im.set_pixel(x2, 20, Color(0, 0, 0, 0))
			line(im, 13, 11, 15, 15, ramp[1])
		"dress":
			# белый фартучек и кармашек с листиком
			poly(im, PackedVector2Array([Vector2(9, 12), Vector2(15, 12), Vector2(17, 20), Vector2(7, 20)]), func(x: int, _y: int) -> Color: return CREAM[5] if x < 12 else CREAM[4])
			rect(im, 8, 11, 8, 1, CREAM[3])
			rect(im, 13, 15, 3, 3, CREAM[3])
			px(im, 14, 14, LEAF[5])
			px(im, 15, 13, LEAF[4])
		"lab_coat":
			line(im, 12, 4, 12, 21, ramp[1])
			for y2 in [7, 11, 15]:
				px(im, 11, y2, GOLD[4])
			rect(im, 14, 13, 3, 3, ramp[2])
			px(im, 15, 12, Color("5aa8a8"))
			px(im, 15, 11, IRON[4])
			line(im, 9, 3, 11, 7, ramp[6])
			line(im, 15, 3, 13, 7, ramp[2])
	outline(im)
	save(im, "gear_" + name)


func icon_cloak() -> void:
	var im: Image = img(24, 24)
	var pts: PackedVector2Array = PackedVector2Array([Vector2(9, 2), Vector2(15, 2), Vector2(19, 8), Vector2(22, 22), Vector2(2, 22), Vector2(5, 8)])
	shaded_poly(im, pts, BLUE, 3)
	# складки
	for fx in [7, 11, 15, 19]:
		line(im, 12 + int((fx - 12) * 0.4), 6, fx, 21, BLUE[2] if fx > 12 else BLUE[4])
	line(im, 2, 21, 21, 21, BLUE[1])
	# меховой ворот и застёжка-листик
	for x in range(7, 18):
		px(im, x, 3 + (x % 2), CREAM[4 + (x % 2)])
		px(im, x, 4, CREAM[3])
	rect(im, 11, 5, 3, 2, GOLD[4])
	px(im, 12, 5, GOLD[6])
	outline(im)
	save(im, "gear_cloak_travel")


func icon_apron() -> void:
	var im: Image = img(24, 24)
	# лямки
	line(im, 8, 1, 9, 6, LEATHER[3])
	line(im, 16, 1, 15, 6, LEATHER[3])
	var pts: PackedVector2Array = PackedVector2Array([Vector2(8, 5), Vector2(16, 5), Vector2(16, 10), Vector2(20, 11), Vector2(19, 22), Vector2(5, 22), Vector2(4, 11), Vector2(8, 10)])
	shaded_poly(im, pts, CREAM, 3)
	# завязки
	line(im, 4, 11, 1, 13, LEATHER[4])
	line(im, 20, 11, 23, 13, LEATHER[2])
	# пятна зелий всех цветов
	for s in [[7, 14, Color("9a6ad0")], [14, 17, Color("5cc08a")], [11, 19, Color("e0a040")], [16, 13, Color("c86a8a")]]:
		var sv: Array = s
		px(im, int(sv[0]), int(sv[1]), sv[2])
		px(im, int(sv[0]) + 1, int(sv[1]), (sv[2] as Color).darkened(0.2))
		px(im, int(sv[0]), int(sv[1]) + 1, (sv[2] as Color).darkened(0.3))
	# кармашек с пробиркой
	rect(im, 9, 15, 5, 4, CREAM[2])
	rect(im, 10, 12, 1, 4, Color("9ad8d0"))
	px(im, 10, 12, Color("ffffff"))
	outline(im)
	save(im, "gear_apron")


func icon_glove(name: String, ramp: Array) -> void:
	var im: Image = img(24, 24)
	# ладонь и пальцы
	blob(im, 11, 12, 6, 6.5, ramp)
	for i in range(4):
		var x0: float = 6.5 + i * 3.2
		rod(im, Vector2(x0, 9), Vector2(x0 + 0.4, 2.5 + absf(i - 1.5) * 0.8), 1.5, ramp, 4 - (i / 2))
	rod(im, Vector2(15.5, 13), Vector2(20, 9), 1.6, ramp, 3)
	# манжета
	rect(im, 6, 18, 11, 5, ramp[2])
	rect(im, 6, 18, 11, 1, ramp[4])
	for x in range(6, 17, 2):
		px(im, x, 20, ramp[1])
	if name == "gloves_garden":
		px(im, 9, 12, LEAF[6])
		px(im, 10, 11, LEAF[5])
		px(im, 10, 13, LEAF[4])
	else:
		line(im, 8, 13, 13, 13, ramp[1])
	outline(im)
	save(im, "gear_" + name)


func icon_boots(name: String, ramp: Array, tall: bool) -> void:
	var im: Image = img(24, 24)
	for b in [0, 1]:
		var ox: int = 2 + b * 9
		var oy: int = 1 + b * 2
		var top: int = oy + (2 if tall else 9)
		shaded_poly(im, PackedVector2Array([Vector2(ox + 1, top), Vector2(ox + 7, top), Vector2(ox + 7, oy + 15), Vector2(ox + 11, oy + 17), Vector2(ox + 11, oy + 20), Vector2(ox, oy + 20)]), ramp, 3 + b)
		rect(im, ox, oy + 19, 12, 2, ramp[0])
		if tall:
			rect(im, ox + 1, top, 6, 2, ramp[5])
			rect(im, ox + 2, oy + 9, 5, 1, IRON[2])
			px(im, ox + 4, oy + 9, GOLD[5])
		else:
			px(im, ox + 3, top + 2, RAG[1])
			px(im, ox + 8, oy + 18, Color("6a5a7a"))
			px(im, ox + 9, oy + 18, Color("6a5a7a"))
	outline(im)
	save(im, "gear_" + name)


func icon_amulet(name: String) -> void:
	var im: Image = img(24, 24)
	# цепочка
	for i in range(22):
		var a: float = PI * (0.08 + 0.84 * float(i) / 21.0)
		var p: Vector2 = Vector2(12, 1) + Vector2(-cos(a) * 9.0, sin(a) * 8.0)
		px(im, int(p.x), int(p.y), GOLD[5] if i % 2 == 0 else GOLD[3])
	if name == "amulet_clover":
		blob(im, 12, 15, 6, 6, GOLD)
		blob(im, 12, 15, 4.6, 4.6, hx(["101a10", "182818", "203020", "283828", "304030", "384838", "405040"]))
		for d in [Vector2(-1.4, -1.4), Vector2(1.4, -1.4), Vector2(-1.4, 1.4), Vector2(1.4, 1.4)]:
			blob(im, 12 + (d as Vector2).x, 15 + (d as Vector2).y, 1.7, 1.7, LEAF)
		px(im, 12, 15, LEAF[2])
		line(im, 12, 16, 13, 19, LEAF[2])
	else:
		# полумесяц из серебра, светится
		for y in range(8, 23):
			for x in range(4, 21):
				var d1: float = Vector2(x + 0.5 - 12.0, y + 0.5 - 15.0).length()
				var d2: float = Vector2(x + 0.5 - 15.0, y + 0.5 - 13.0).length()
				if d1 <= 6.2 and d2 > 5.0:
					px(im, x, y, MOON[6] if d1 > 5.0 and x < 12 else (MOON[5] if y < 15 else MOON[3]))
		px(im, 9, 12, Color("ffffff"))
		rect(im, 11, 8, 2, 2, GOLD[4])
	outline(im)
	save(im, "gear_" + name)


func icon_ring(name: String, band: Array, gem: Array) -> void:
	var im: Image = img(24, 24)
	for y in range(6, 22):
		for x in range(3, 21):
			var d: float = Vector2((x + 0.5 - 12.0) / 8.0, (y + 0.5 - 15.0) / 5.5).length()
			if d <= 1.0 and d >= 0.62:
				var k: int = 5 if (y < 14 and x < 12) else (4 if y < 15 else (2 if x > 13 else 3))
				px(im, x, y, band[k])
	if name == "ring_moss":
		# мох и листик вместо камня
		blob(im, 12, 9, 3.5, 2.6, LEAF)
		px(im, 14, 6, LEAF[5])
		px(im, 15, 5, LEAF[4])
		px(im, 10, 8, Color("e8f0a0"))
	else:
		rect(im, 9, 9, 7, 2, band[4])
		blob(im, 12.5, 7.5, 3.2, 3.2, gem)
		px(im, 11, 6, Color("ffffff"))
	outline(im)
	save(im, "gear_" + name)


func icon_belt(name: String, ramp: Array, loops: int) -> void:
	var im: Image = img(24, 24)
	# пояс свёрнут дугой
	for i in range(40):
		var a: float = PI * (0.95 + 1.1 * float(i) / 39.0)
		var p: Vector2 = Vector2(12, 12) + Vector2(cos(a) * 10.0, sin(a) * 6.0)
		for t in range(-1, 2):
			var k: int = clampi(3 - t + (0 if p.y < 12 else -1), 0, 6)
			px(im, int(p.x), int(p.y) + t, ramp[k])
			if name == "belt_rope" and (i + t) % 3 == 0:
				px(im, int(p.x), int(p.y) + t, ramp[1])
	rod(im, Vector2(2, 12), Vector2(22, 12), 1.6, ramp, 3)
	if name == "belt_rope":
		for x in range(2, 22):
			if x % 3 == 0:
				px(im, x, 12, ramp[1])
				px(im, x + 1, 11, ramp[5])
	else:
		# пряжка и кармашки
		rect(im, 10, 9, 5, 6, GOLD[3])
		rect(im, 11, 10, 3, 4, ramp[2])
		px(im, 10, 9, GOLD[5])
		for bx in [4, 17]:
			rect(im, bx, 13, 4, 5, ramp[3])
			rect(im, bx, 13, 4, 1, ramp[5])
			px(im, bx + 1, 15, GOLD[4])
	# петли для склянок с маленькими склянками
	for j in range(loops):
		var x0: int = 5 + j * (14 / maxi(1, loops - 1)) if loops > 1 else 12
		rect(im, x0, 16, 2, 5, Color("9ad8d0") if j % 2 == 0 else Color("e0a040"))
		px(im, x0, 16, Color("ffffff"))
		px(im, x0, 15, WOOD[4])
	outline(im)
	save(im, "gear_" + name)


func icon_pack_sack() -> void:
	var im: Image = img(24, 24)
	var bur: Array = hx(["3a2c1a", "54402a", "6e5638", "8a7048", "a68a5a", "c4a674", "dcc090"])
	blob(im, 12, 15, 8.5, 7.5, bur)
	# горловина, завязанная верёвкой
	poly(im, PackedVector2Array([Vector2(8, 9), Vector2(10, 4), Vector2(14, 4), Vector2(16, 9)]), func(x: int, _y: int) -> Color: return bur[4] if x < 12 else bur[3])
	rect(im, 9, 8, 7, 2, STRAW[3])
	rect(im, 9, 8, 7, 1, STRAW[5])
	# лямка
	line(im, 16, 9, 21, 18, LEATHER[3])
	line(im, 17, 9, 22, 18, LEATHER[5])
	# заплатка и текстура мешковины
	for y in range(10, 22):
		for x in range(5, 20):
			if (x + y) % 4 == 0 and im.get_pixel(x, y).a > 0.5:
				px(im, x, y, im.get_pixel(x, y).darkened(0.12))
	rect(im, 6, 16, 4, 3, Color("7a8a5a"))
	outline(im)
	save(im, "gear_pack_sack")


func _wicker(im: Image, x0: int, y0: int, w: int, h: int) -> void:
	for y in range(y0, y0 + h):
		for x in range(x0, x0 + w):
			var u: int = (x - x0)
			var v: int = (y - y0)
			var weave: bool = ((u / 2) + (v / 2)) % 2 == 0
			var k: int = 4 if weave else 3
			if u < w / 3:
				k += 1
			if v == 0:
				k = 5
			if u >= w * 2 / 3:
				k -= 1
			px(im, x, y, WICKER[clampi(k, 0, 6)])


func icon_basket() -> void:
	var im: Image = img(24, 24)
	# ручка
	for i in range(20):
		var a: float = PI * (1.0 + float(i) / 19.0)
		var p: Vector2 = Vector2(12, 12) + Vector2(cos(a) * 8.0, sin(a) * 9.0)
		px(im, int(p.x), int(p.y), WICKER[5] if i < 10 else WICKER[3])
		px(im, int(p.x), int(p.y) + 1, WICKER[2])
	# грибы в корзине
	for m in [[8, 11, RED], [13, 10, AMBER], [17, 12, RED]]:
		var mv: Array = m
		rect(im, int(mv[0]) - 1, int(mv[1]), 2, 3, CREAM[5])
		blob(im, float(mv[0]), float(mv[1]), 3.2, 2.2, mv[2])
		if mv[2] == RED:
			px(im, int(mv[0]) - 1, int(mv[1]) - 1, Color("fff8f0"))
			px(im, int(mv[0]) + 1, int(mv[1]), Color("fff8f0"))
	# корзина: шире сверху
	for y in range(13, 23):
		var inset: int = (y - 13) / 3
		for x in range(3 + inset, 21 - inset):
			var u: int = x - 3
			var weave: bool = ((u / 2) + ((y - 13) / 2)) % 2 == 0
			var k: int = (4 if weave else 3) + (1 if x < 9 else (-1 if x > 15 else 0))
			px(im, x, y, WICKER[clampi(k, 0, 6)])
	rect(im, 2, 13, 20, 2, WICKER[5])
	rect(im, 2, 14, 20, 1, WICKER[3])
	outline(im)
	save(im, "gear_pack_basket")


func icon_herb_bag() -> void:
	var im: Image = img(24, 24)
	# листья и цветы торчат из сумки
	for l in [[7, 5, -0.6], [11, 3, 0.0], [15, 4, 0.5], [18, 7, 0.9]]:
		var lv: Array = l
		rod(im, Vector2(float(lv[0]), float(lv[1])), Vector2(float(lv[0]) + float(lv[2]) * 2.0, float(lv[1]) + 7.0), 1.4, LEAF, 4)
	px(im, 11, 3, Color("b898d8"))
	px(im, 12, 2, Color("9470b8"))
	px(im, 10, 2, Color("b898d8"))
	px(im, 15, 3, Color("f8f0f0"))
	px(im, 16, 4, GOLD[5])
	# сумка с клапаном
	shaded_poly(im, PackedVector2Array([Vector2(3, 9), Vector2(21, 9), Vector2(20, 22), Vector2(4, 22)]), GREEN, 3)
	shaded_poly(im, PackedVector2Array([Vector2(3, 9), Vector2(21, 9), Vector2(20, 14), Vector2(12, 16), Vector2(4, 14)]), GREEN, 4)
	rect(im, 11, 14, 3, 3, GOLD[4])
	px(im, 12, 15, GOLD[2])
	# вышитый листик
	px(im, 7, 18, LEAF[6])
	px(im, 8, 17, LEAF[5])
	px(im, 8, 19, LEAF[5])
	px(im, 9, 18, LEAF[4])
	outline(im)
	save(im, "gear_pack_herb")


func icon_creel() -> void:
	var im: Image = img(24, 24)
	_wicker(im, 3, 8, 18, 14)
	# крышка и ремень
	rect(im, 2, 6, 20, 3, WOOD[4])
	rect(im, 2, 6, 20, 1, WOOD[6])
	rect(im, 9, 4, 6, 2, WOOD[2])
	line(im, 19, 6, 23, 15, LEATHER[4])
	# рыбий хвост из-под крышки: веер с лучами
	var fish: Array = hx(["2a4a6a", "3a6088", "5a88b0", "7aa8cc", "a8cce4", "d8f0ff", "ffffff"])
	rod(im, Vector2(13, 7), Vector2(15.5, 3), 1.6, fish, 3)
	poly(im, PackedVector2Array([Vector2(14, 3.5), Vector2(11, -0.5), Vector2(16, 1.5), Vector2(20, -0.5), Vector2(17, 4)]), func(x: int, _y: int) -> Color: return fish[5] if x < 15 else fish[3])
	line(im, 13, 1, 15, 3, fish[2])
	line(im, 18, 1, 16, 3, fish[1])
	outline(im)
	save(im, "gear_pack_creel")


func icon_alch_box() -> void:
	var im: Image = img(24, 24)
	# склянки в гнёздах
	var cols: Array = [Color("9a6ad0"), Color("5cc08a"), Color("e0a040")]
	for i in range(3):
		var x0: int = 5 + i * 5
		rect(im, x0, 3 + (i % 2), 3, 7, (cols[i] as Color))
		rect(im, x0, 3 + (i % 2), 1, 7, (cols[i] as Color).lightened(0.3))
		rect(im, x0, 2 + (i % 2), 3, 1, WOOD[5])
	# ларец
	shaded_poly(im, PackedVector2Array([Vector2(2, 9), Vector2(22, 9), Vector2(22, 22), Vector2(2, 22)]), WOOD, 3)
	rect(im, 2, 9, 20, 2, PURPLE[3])
	rect(im, 2, 9, 20, 1, PURPLE[5])
	for c in [2, 20]:
		rect(im, c, 11, 2, 11, GOLD[3])
	rect(im, 10, 14, 4, 4, GOLD[4])
	px(im, 11, 15, GOLD[1])
	px(im, 12, 16, GOLD[1])
	outline(im)
	save(im, "gear_pack_alch")


func icon_travel_pack() -> void:
	var im: Image = img(24, 24)
	# скатка сверху
	rod(im, Vector2(4, 4), Vector2(20, 4), 2.6, BLUE, 4)
	for x in [8, 16]:
		line(im, x, 1, x, 7, LEATHER[2])
	# рюкзак
	shaded_poly(im, PackedVector2Array([Vector2(4, 7), Vector2(20, 7), Vector2(21, 22), Vector2(3, 22)]), LEATHER, 4)
	# клапан
	shaded_poly(im, PackedVector2Array([Vector2(4, 7), Vector2(20, 7), Vector2(19, 13), Vector2(5, 13)]), LEATHER, 5)
	for bx in [8, 15]:
		line(im, bx, 11, bx, 15, LEATHER[1])
		rect(im, bx - 1, 14, 3, 2, GOLD[4])
	# карман и кружка сбоку
	rect(im, 7, 16, 10, 5, LEATHER[3])
	rect(im, 7, 16, 10, 1, LEATHER[5])
	rect(im, 20, 14, 3, 4, IRON[4])
	px(im, 22, 15, IRON[2])
	# рама
	line(im, 2, 6, 2, 23, WOOD[3])
	outline(im)
	save(im, "gear_pack_travel")


# ------------------------------------------------------------------ интерфейс в духе PoE

func gen_ui() -> void:
	# ---- фон панели 352×500 (на экране ×2)
	var W: int = 352
	var H: int = 500
	var bg: Image = img(W, H)
	for y in range(H):
		for x in range(W):
			# каменная кладка: блоки 22×14 со сдвигом рядов
			var row: int = y / 14
			var bx: int = (x + (11 if row % 2 == 1 else 0)) / 22
			var jx: int = (x + (11 if row % 2 == 1 else 0)) % 22
			var jy: int = y % 14
			var n: float = h01(bx, row, 3) * 0.6 + h01(x / 3, y / 3, 7) * 0.4
			var k: int = 3 + int(n * 2.2)
			if jx == 0 or jy == 0:
				k = 1
			elif jx == 1 or jy == 1:
				k = 4 if k < 4 else 5
			# виньетка: края темнее
			var e: float = minf(minf(float(x), float(W - 1 - x)), minf(float(y), float(H - 1 - y)))
			if e < 30:
				k -= 1
			if e < 12:
				k -= 1
			bg.set_pixel(x, y, STONE[clampi(k, 0, 6)])
	# барельефы: две статуи-травницы по бокам и древо в середине — едва видны, как на камне в PoE
	_relief_tree(bg, 176, 300)
	_relief_statue(bg, 40, 304, false)
	_relief_statue(bg, 312, 304, true)
	# сетка сумки — тёмное углубление
	for y2 in range(326, 474):
		for x2 in range(6, W - 6):
			bg.set_pixel(x2, y2, Color("0c0d0e").lerp(STONE[1], h01(x2, y2, 9) * 0.25))
	_frame(bg, Rect2i(6, 325, W - 12, 150), false)
	# толстая бронзовая рамка и золотые уголки
	_frame(bg, Rect2i(0, 0, W, H), true)
	for c in [Vector2i(0, 0), Vector2i(W - 18, 0), Vector2i(0, H - 18), Vector2i(W - 18, H - 18)]:
		_corner(bg, c, (c as Vector2i).x > 0, (c as Vector2i).y > 0)
	# полоса под гербом
	for x3 in range(4, W - 4):
		bg.set_pixel(x3, 44, GOLD[2])
		bg.set_pixel(x3, 45, GOLD[4] if x3 % 6 != 0 else GOLD[3])
		bg.set_pixel(x3, 46, Color("0a0806"))
	save(bg, "inv_bg")
	# ---- рамка слота 12×12 (9-сегментная)
	var s: Image = img(12, 12)
	for y4 in range(12):
		for x4 in range(12):
			var ed: int = mini(mini(x4, y4), mini(11 - x4, 11 - y4))
			var c4: Color
			if ed == 0:
				c4 = Color("0a0806")
			elif ed == 1:
				c4 = GOLD[4] if (x4 < 6 and y4 < 6) or y4 == 1 or x4 == 1 else GOLD[2]
			elif ed == 2:
				c4 = GOLD[1]
			elif ed == 3:
				c4 = Color("050606")
			else:
				c4 = Color("0d0f10")
			s.set_pixel(x4, y4, c4)
	save(s, "inv_slot", false)
	# ---- ячейка сетки 28×28: тёмная, тонкая рамка, едва видный цветок-узор
	var cimg: Image = img(28, 28)
	for y5 in range(28):
		for x5 in range(28):
			var c5: Color = Color("101213")
			if x5 == 0 or y5 == 0:
				c5 = Color("26292b")
			elif x5 == 27 or y5 == 27:
				c5 = Color("050606")
			else:
				var d: Vector2 = Vector2(x5 - 13.5, y5 - 13.5)
				var r: float = d.length()
				var ang: float = atan2(d.y, d.x)
				var petal: float = 4.5 + 2.2 * cos(ang * 4.0)
				if r < petal and r > petal - 1.2:
					c5 = Color("1a1d1f")
				if r < 1.6:
					c5 = Color("1c1f21")
			cimg.set_pixel(x5, y5, c5)
	save(cimg, "inv_cell", false)
	# ---- герб: золотые крылья-листья и круг с ступкой и листиком (200×50)
	var cr: Image = img(200, 50)
	for side in [-1, 1]:
		for f in range(9):
			var len: float = 72.0 - f * 6.0
			var a0: Vector2 = Vector2(100 + side * 18, 26)
			var ang2: float = deg_to_rad(-8.0 - f * 5.5)
			var tip: Vector2 = a0 + Vector2(cos(ang2) * side, sin(ang2)) * len
			var mid: Vector2 = a0.lerp(tip, 0.5) + Vector2(0, -5.0 + f * 0.8)
			_feather(cr, a0, mid, tip, 4.2 - f * 0.25)
	blob(cr, 100, 26, 20, 20, GOLD)
	blob(cr, 100, 26, 15.5, 15.5, hx(["1a0a08", "240e0a", "2e140e", "3a1a12", "461f16", "52261a", "5e2c1e"]))
	# ступка и пестик
	shaded_poly(cr, PackedVector2Array([Vector2(90, 26), Vector2(110, 26), Vector2(107, 35), Vector2(93, 35)]), GOLD, 3)
	rect(cr, 92, 35, 16, 2, GOLD[2])
	rod(cr, Vector2(104, 27), Vector2(111, 14), 1.6, GOLD, 4)
	# листик над ступкой
	for y6 in range(13, 26):
		for x6 in range(88, 101):
			var p: Vector2 = Vector2(x6 + 0.5 - 95.0, y6 + 0.5 - 20.0)
			var q: Vector2 = Vector2(p.x * 0.8 + p.y * 0.6, -p.x * 0.6 + p.y * 0.8)
			if (q.x / 2.6) * (q.x / 2.6) + (q.y / 6.0) * (q.y / 6.0) <= 1.0:
				px(cr, x6, y6, LEAF[5] if q.x < 0 else LEAF[3])
	outline(cr, 0.5)
	save(cr, "inv_crest")
	# ---- табличка с названием 130×22
	var pl: Image = img(130, 22)
	for y7 in range(22):
		for x7 in range(130):
			var u: float = (x7 + 0.5) / 130.0
			var cap: float = 11.0 - sqrt(maxf(0.0, 121.0 - pow(float(mini(x7, 129 - x7)) - 11.0, 2.0))) if mini(x7, 129 - x7) < 11 else 0.0
			if y7 < int(cap) or 21 - y7 < int(cap):
				continue
			var k7: int = 5 if y7 < 5 else (4 if y7 < 11 else (3 if y7 < 17 else 2))
			if y7 == 1:
				k7 = 6
			if h01(x7, y7, 2) < 0.08:
				k7 -= 1
			pl.set_pixel(x7, y7, STRAW[clampi(k7, 0, 6)].lerp(GOLD[k7], 0.35))
			if u < 0.03 or u > 0.97:
				pl.set_pixel(x7, y7, GOLD[2])
	outline(pl, 0.6)
	save(pl, "inv_plaque")
	# ---- кнопка «закрыть»: красный круг в золотом кольце с крестиком (16×16)
	var cl: Image = img(16, 16)
	blob(cl, 8, 8, 7.5, 7.5, GOLD)
	blob(cl, 8, 8, 5.5, 5.5, RED)
	for i in range(-3, 4):
		px(cl, 8 + i, 8 + i, Color("fff0e0"))
		px(cl, 7 + i, 8 + i, Color("f8d8c8"))
		px(cl, 8 + i, 8 - i, Color("fff0e0"))
		px(cl, 7 + i, 8 - i, Color("f8d8c8"))
	outline(cl, 0.5)
	save(cl, "inv_close", false)
	# ---- замочек закрытой ячейки (14×14)
	var lk: Image = img(14, 14)
	for a in range(14):
		var ang3: float = PI + PI * float(a) / 13.0
		px(lk, 7 + int(round(cos(ang3) * 3.5)), 6 + int(round(sin(ang3) * 4.0)), IRON[4])
	shaded_poly(lk, PackedVector2Array([Vector2(2, 6), Vector2(12, 6), Vector2(12, 13), Vector2(2, 13)]), GOLD, 3)
	rect(lk, 6, 8, 2, 3, Color("1a1008"))
	outline(lk, 0.5)
	save(lk, "inv_lock", false)


## Бронзовая рамка с фаской (свет сверху-слева)
func _frame(im: Image, r: Rect2i, thick: bool) -> void:
	var t: int = 4 if thick else 2
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			var ed: int = mini(mini(x - r.position.x, y - r.position.y), mini(r.end.x - 1 - x, r.end.y - 1 - y))
			if ed >= t:
				continue
			var lit: bool = (x - r.position.x) < (r.end.x - 1 - x) and (y - r.position.y) < (r.end.y - 1 - y)
			var c: Color
			if ed == 0:
				c = Color("080604")
			elif ed == t - 1:
				c = Color("060505")
			else:
				c = GOLD[4] if lit else GOLD[2]
				if thick and ed == 2:
					c = GOLD[3] if lit else GOLD[1]
			im.set_pixel(x, y, c)


## Золотой уголок-завиток 18×18
func _corner(im: Image, at: Vector2i, fx: bool, fy: bool) -> void:
	for y in range(18):
		for x in range(18):
			var lx: int = 17 - x if fx else x
			var ly: int = 17 - y if fy else y
			var d: float = Vector2(lx, ly).length()
			var on: bool = (lx < 4 or ly < 4) and (lx < 16 and ly < 16)
			var curl: float = Vector2(lx - 9, ly - 9).length()
			if curl > 3.5 and curl < 5.2 and lx > 4 and ly > 4:
				on = true
			if not on:
				continue
			var k: int = 5 if d < 8.0 else 4
			if lx == 0 or ly == 0:
				k = 2
			px(im, at.x + x, at.y + y, GOLD[k])
	px(im, at.x + (8 if not fx else 9), at.y + (8 if not fy else 9), GOLD[6])


## Перо-лист крыла герба: закруглённый клин от основания к кончику
func _feather(im: Image, a: Vector2, mid: Vector2, tip: Vector2, w: float) -> void:
	for i in range(60):
		var t: float = float(i) / 59.0
		var p: Vector2 = a.lerp(mid, t).lerp(mid.lerp(tip, t), t)
		var r: float = w * sin(PI * clampf(t * 0.9 + 0.1, 0.0, 1.0))
		for y in range(int(p.y - r) - 1, int(p.y + r) + 2):
			for x in range(int(p.x - r) - 1, int(p.x + r) + 2):
				var d: float = Vector2(x + 0.5, y + 0.5).distance_to(p)
				if d <= r:
					var k: int = 5 if (y + 0.5) < p.y - r * 0.3 else (4 if (y + 0.5) < p.y + r * 0.3 else 2)
					px(im, x, y, GOLD[k])


## Едва заметный барельеф (камень чуть светлее и темнее)
func _carve(im: Image, x: int, y: int, light: bool) -> void:
	if x < 0 or y < 0 or x >= im.get_width() or y >= im.get_height():
		return
	var c: Color = im.get_pixel(x, y)
	im.set_pixel(x, y, c.lightened(0.10) if light else c.darkened(0.25))


func _relief_tree(im: Image, cx: int, base: int) -> void:
	for y in range(base - 150, base):
		var t: float = float(base - y) / 150.0
		var w: float = 4.0 + (1.0 - t) * 4.0
		for x in range(int(cx - w), int(cx + w)):
			_carve(im, x, y, x < cx)
	for b in range(7):
		var a: float = PI * (0.12 + 0.76 * float(b) / 6.0)
		var p0: Vector2 = Vector2(cx, base - 100 - b * 4)
		for i in range(60):
			var p: Vector2 = p0 + Vector2(-cos(a), -sin(a) * 0.9) * float(i) * 1.6
			_carve(im, int(p.x), int(p.y), true)
			_carve(im, int(p.x), int(p.y) + 1, false)
			if i % 9 == 8:
				for dy in range(-3, 4):
					for dx in range(-4, 5):
						if dx * dx / 16.0 + dy * dy / 9.0 <= 1.0:
							_carve(im, int(p.x) + dx, int(p.y) + dy, dy < 0)


func _relief_statue(im: Image, cx: int, base: int, flip: bool) -> void:
	var s: float = -1.0 if flip else 1.0
	# постамент
	for y in range(base - 14, base):
		for x in range(cx - 22, cx + 22):
			_carve(im, x, y, y < base - 11)
	# фигура в плаще с посохом: силуэт из овалов
	var parts: Array = [[0, -40, 13, 26], [0, -74, 8, 9], [0, -60, 11, 9]]
	for pp in parts:
		var pv: Array = pp
		for y2 in range(-int(pv[3]), int(pv[3]) + 1):
			for x2 in range(-int(pv[2]), int(pv[2]) + 1):
				if float(x2 * x2) / pow(float(pv[2]), 2.0) + float(y2 * y2) / pow(float(pv[3]), 2.0) <= 1.0:
					_carve(im, cx + int(pv[0]) + x2, base - 14 + int(pv[1]) + y2, x2 * s < 0)
	for y3 in range(base - 112, base - 14):
		_carve(im, cx + int(16 * s), y3, true)
		_carve(im, cx + int(17 * s), y3, false)
	for a in range(12):
		var ang: float = TAU * float(a) / 12.0
		_carve(im, cx + int(16 * s + cos(ang) * 4.0), base - 116 + int(sin(ang) * 4.0), true)


# ------------------------------------------------------------------ полка лавки и ценники

func gen_shelf() -> void:
	var im: Image = img(84, 96)
	# задняя стенка: вертикальные доски
	for y in range(4, 92):
		for x in range(4, 80):
			var plank: int = (x - 4) / 11
			var k: int = 2 + int(h01(plank, y / 6, 4) * 1.6)
			if (x - 4) % 11 == 0:
				k = 1
			im.set_pixel(x, y, WOOD[k])
	# боковые стойки
	for sx in [0, 80]:
		for y2 in range(0, 96):
			for x2 in range(sx, sx + 4):
				im.set_pixel(x2, y2, WOOD[5 if x2 == sx + 1 else (4 if x2 < sx + 3 else 2)])
	# карниз
	for y3 in range(0, 6):
		for x3 in range(0, 84):
			im.set_pixel(x3, y3, WOOD[6 if y3 == 1 else (5 if y3 < 3 else 3)])
	# три доски: верх доски там, где стоят вещи (30, 58, 86)
	for by in [30, 58, 86]:
		for y4 in range(by, by + 5):
			for x4 in range(2, 82):
				var k4: int = 6 if y4 == by else (5 if y4 == by + 1 else (4 if y4 < by + 4 else 1))
				im.set_pixel(x4, y4, WOOD[k4])
		# тень под доской на стенке
		for x5 in range(4, 80):
			if by + 5 < 96:
				im.set_pixel(x5, by + 5, WOOD[0])
	# ножки
	# цоколь: тёмная планка понизу, ножки по краям
	for y6 in range(91, 96):
		for x6 in range(0, 84):
			im.set_pixel(x6, y6, WOOD[2] if (x6 < 6 or x6 > 77) else WOOD[1])
	for x7 in range(6, 78):
		im.set_pixel(x7, 91, WOOD[3])
	outline(im, 0.5)
	save(im, "shelf14")
	# цифры 3×5 для ценников
	var glyphs: Array = [
		"111101101101111", "010110010010111", "111001111100111", "111001111001111", "101101111001001",
		"111100111001111", "111100111101111", "111001010010010", "111101111101111", "111101111001111",
	]
	var dg: Image = img(30, 5)
	for d in range(10):
		var g: String = glyphs[d]
		for i in range(15):
			if g[i] == "1":
				dg.set_pixel(d * 3 + i % 3, i / 3, Color("3a2718"))
	save(dg, "price_digits", false)
	var cn: Image = img(5, 5)
	for y7 in range(5):
		for x7 in range(5):
			var d7: float = Vector2(x7 - 2.0, y7 - 2.0).length()
			if d7 <= 2.4:
				cn.set_pixel(x7, y7, GOLD[5] if (x7 + y7) < 4 else GOLD[3])
	cn.set_pixel(2, 2, GOLD[2])
	save(cn, "price_coin", false)


# ------------------------------------------------------------------ дикие травы (32×48, как mint_3)

var HG: Array = hx(["10261a", "1a3a22", "26522c", "346e38", "4a8a44", "6aa852", "96c870"])      # зелень трав
var HG2: Array = hx(["0e2418", "183828", "245034", "306a42", "448654", "62a46a", "8cc48a"])     # голубоватая
var HSIL: Array = hx(["2a3430", "3e4a44", "56645c", "728078", "8e9c92", "aebab0", "d0dad2"])    # серебристая
var HDK: Array = hx(["0a1a12", "12281a", "1c3824", "264a2e", "32603a", "427848", "5a9058"])     # тёмная
var HPUR: Array = hx(["1e0e1e", "321832", "4a2448", "62325e", "7c4478", "985a92", "b878b0"])    # пурпурная
var HPINK: Array = hx(["4a1e3a", "6a2e52", "8c446c", "b05c88", "d07aa4", "e8a0c0", "f8c8dc"])   # розовая
var HBLUE: Array = hx(["0e2a3a", "184050", "245a6a", "347888", "4c98a8", "70bccc", "a8e0ec"])   # светящаяся
var SOILH: Array = hx(["2a1810", "3e2616", "56361e", "6e4828", "8a5e36"])


## Кочка земли под травой, как у старых значков
func _soil(im: Image) -> void:
	for y in range(41, 47):
		for x in range(5, 27):
			var d: float = Vector2((x + 0.5 - 16.0) / 10.5, (y + 0.5 - 43.5) / 2.8).length()
			if d <= 1.0:
				var k: int = 3 if y < 43 else (2 if y < 45 else 1)
				if h01(x, y, 11) < 0.15:
					k -= 1
				px(im, x, y, SOILH[clampi(k, 0, 4)])
	for gx in [7, 10, 21, 24]:
		px(im, gx, 41, HG[4])
		px(im, gx, 40, HG[5])


## Лист: заострённый овал вдоль направления, светлее со стороны солнца, с прожилкой
func _leaf(im: Image, base: Vector2, dir: Vector2, length: float, width: float, ramp: Array, rib: bool = true) -> void:
	var d: Vector2 = dir.normalized()
	var n: Vector2 = d.orthogonal()
	var lo: Vector2 = base - Vector2.ONE * (length + width + 1.0)
	var hi: Vector2 = base + Vector2.ONE * (length + width + 1.0)
	for y in range(int(lo.y), int(hi.y) + 1):
		for x in range(int(lo.x), int(hi.x) + 1):
			var p: Vector2 = Vector2(x + 0.5, y + 0.5) - base
			var t: float = p.dot(d)
			if t < 0.0 or t > length:
				continue
			var s: float = p.dot(n)
			var w: float = width * pow(sin(PI * clampf(t / length, 0.0, 1.0)), 0.75)
			if absf(s) > w:
				continue
			var lit: float = -(n * signf(s)).dot(Vector2(-0.6, -0.8))
			var k: int = 4 if lit < -0.2 else (3 if lit < 0.3 else 2)
			if t / length > 0.75:
				k += 1
			if rib and absf(s) < 0.55 and t > 1.0:
				k = 2
			px(im, x, y, ramp[clampi(k, 0, ramp.size() - 1)])


func _stem(im: Image, a: Vector2, b: Vector2, col: Color) -> void:
	line(im, int(a.x), int(a.y), int(b.x), int(b.y), col)


func _daisy(im: Image, c: Vector2, r: float, petal: Color, mid: Color) -> void:
	for i in range(8):
		var a: float = TAU * float(i) / 8.0
		for k in range(1, int(r) + 1):
			var p: Vector2 = c + Vector2(cos(a), sin(a) * 0.8) * float(k)
			px(im, int(p.x), int(p.y), petal if a < PI else petal.darkened(0.15))
	blob(im, c.x, c.y, 1.3, 1.2, [mid.darkened(0.3), mid.darkened(0.15), mid, mid.lightened(0.2)])


func _ball(im: Image, c: Vector2, r: float, ramp: Array) -> void:
	blob(im, c.x, c.y, r, r * 1.05, ramp)
	for i in range(int(r * r)):
		var p: Vector2 = c + Vector2(h01(i, int(c.x), 3) - 0.5, h01(i, int(c.y), 5) - 0.5) * r * 1.6
		px(im, int(p.x), int(p.y), ramp[maxi(0, ramp.size() - 2)] if i % 2 == 0 else ramp[2])


func _bell(im: Image, top: Vector2, col: Array) -> void:
	px(im, int(top.x), int(top.y), col[2])
	rect(im, int(top.x) - 1, int(top.y) + 1, 3, 2, col[4])
	px(im, int(top.x) - 1, int(top.y) + 1, col[5])
	rect(im, int(top.x) - 2, int(top.y) + 3, 5, 1, col[3])
	px(im, int(top.x), int(top.y) + 3, col[1])


func _umbel(im: Image, c: Vector2, r: float, ramp: Array) -> void:
	for i in range(int(r * 3.0)):
		var a: float = PI + PI * float(i) / (r * 3.0 - 1.0)
		var p: Vector2 = c + Vector2(cos(a) * r, sin(a) * r * 0.45)
		_stem(im, c + Vector2(0, 2), p, HG[3])
		px(im, int(p.x), int(p.y), ramp[5] if i % 2 == 0 else ramp[4])
		px(im, int(p.x), int(p.y) - 1, ramp[6] if i % 3 == 0 else ramp[5])
	px(im, int(c.x), int(c.y) - int(r * 0.4), ramp[6])


func _berry(im: Image, c: Vector2, r: float, ramp: Array) -> void:
	blob(im, c.x, c.y, r, r, ramp)
	px(im, int(c.x - r * 0.4), int(c.y - r * 0.4), Color(1, 1, 1, 0.85))


func _star(im: Image, c: Vector2, col: Color) -> void:
	px(im, int(c.x), int(c.y), col.lightened(0.3))
	for d in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, -1), Vector2(1, 1), Vector2(-1, 1)]:
		px(im, int(c.x + (d as Vector2).x), int(c.y + (d as Vector2).y), col)


func _spike(im: Image, base: Vector2, top: Vector2, ramp: Array, w: int = 1) -> void:
	_stem(im, base, top, HG[3])
	var n: int = int(base.distance_to(top))
	for i in range(n):
		var p: Vector2 = base.lerp(top, float(i) / float(n))
		if float(i) / float(n) < 0.35:
			continue
		var k: int = 4 if i % 2 == 0 else 5
		for s in range(-w, w + 1):
			px(im, int(p.x) + s, int(p.y), ramp[k - absi(s)])


## Пучок листьев от земли веером
func _tuft(im: Image, n: int, length: float, width: float, ramp: Array, spread: float = 1.3, up: float = 1.0) -> void:
	for i in range(n):
		var a: float = -PI / 2.0 + spread * (float(i) / maxf(1.0, float(n - 1)) - 0.5) * 2.0
		_leaf(im, Vector2(16 + cos(a) * 1.5, 41), Vector2(cos(a), sin(a) * up), length * (0.8 + 0.2 * h01(i, n, 7)), width, ramp)


# ------------------------------------------------------------------ v22: подводные травы

var SGRN: Array = hx(["0a2a2a", "124a40", "1c6a52", "2c8a62", "46aa72", "72c890", "a8e8b8"])      # морская зелень
var SKELP: Array = hx(["2a1c08", "4a3210", "6e4c18", "946c24", "b8903a", "d8b458", "f0d888"])     # золотая ламинария
var SCOR: Array = hx(["4a1a2a", "722a40", "9a3e54", "c85a6a", "e8808a", "f8a8a8", "ffd4cc"])      # розовый коралл
var SICE: Array = hx(["143a5a", "205a82", "3a82aa", "62a8cc", "90cce4", "c0e6f4", "f0faff"])      # ледяная
var SDEEP: Array = hx(["06061a", "0c0e30", "141a4a", "1e2a68", "2c3e88", "4058a8", "6c80c8"])     # глубинная
var SLIL: Array = hx(["2a1448", "442468", "62388a", "8454ac", "a478c8", "c8a4e4", "ecd4fa"])      # сиреневая
var SPRL: Array = hx(["5a5a6a", "8a8a9c", "b4b4c4", "d4d4e0", "ecece8", "fffaf4", "ffffff"])      # жемчуг
var SSAND: Array = hx(["8a7448", "a68c5a", "c2a870", "d8c088", "e8d4a0"])


func _sand(im: Image) -> void:
	for y in range(41, 47):
		for x in range(4, 28):
			var d: float = Vector2((x + 0.5 - 16.0) / 11.5, (y + 0.5 - 43.5) / 2.9).length()
			if d <= 1.0:
				var k: int = 3 if y < 43 else (2 if y < 45 else 1)
				if h01(x, y, 17) < 0.2:
					k -= 1
				px(im, x, y, SSAND[clampi(k, 0, 4)])
	for gx in [8, 13, 20, 24]:
		px(im, gx, 41, SSAND[4])


## Лента, качающаяся вдоль течения: от основания вверх, с изгибом
func _ribbon(im: Image, x0: float, y0: float, x1: float, y1: float, bend: float, w: float, ramp: Array) -> void:
	var n: int = int(absf(y0 - y1)) + 1
	for i in range(n):
		var t: float = float(i) / float(n)
		var x: float = lerpf(x0, x1, t) + sin(t * PI) * bend
		var y: float = lerpf(y0, y1, t)
		var ww: float = w * (1.0 - t * 0.55)
		for s in range(int(-ww), int(ww) + 1):
			var k: int = 4 if s <= 0 else 3
			if t > 0.8:
				k += 1
			px(im, int(x) + s, int(y), ramp[clampi(k, 0, ramp.size() - 1)])


func _petals(im: Image, c: Vector2, n: int, length: float, width: float, ramp: Array, squash: float = 0.8, from_a: float = 0.0, span: float = TAU) -> void:
	for i in range(n):
		var a: float = from_a + span * float(i) / float(maxi(1, n - (1 if span < TAU else 0)))
		_leaf(im, c, Vector2(cos(a), sin(a) * squash), length, width, ramp, false)


func _pearl(im: Image, c: Vector2, r: float) -> void:
	blob(im, c.x, c.y, r, r, SPRL)
	px(im, int(c.x - r * 0.4), int(c.y - r * 0.45), Color(1, 1, 1, 1))


func gen_sea_herbs() -> void:
	var specs: Dictionary = {
		"sea_lettuce": func(im: Image) -> void:
			for a in [-2.6, -2.1, -1.6, -1.1, -0.6]:
				_leaf(im, Vector2(16, 41), Vector2(cos(a), sin(a) * 1.0), 24.0, 5.2, SGRN, false)
			for i in range(18):
				var p: Vector2 = Vector2(6.0 + h01(i, 1, 9) * 20.0, 14.0 + h01(i, 2, 9) * 22.0)
				px(im, int(p.x), int(p.y), SGRN[5]),
		"eelgrass": func(im: Image) -> void:
			for i in range(8):
				var bx: float = 8.0 + float(i) * 2.3
				_ribbon(im, bx, 42, bx + (float(i) - 3.5) * 1.6, 4.0 + h01(i, 3, 4) * 8.0, 4.0 * (1.0 if i % 2 == 0 else -1.0), 0.8, SGRN),
		"kelp_gold": func(im: Image) -> void:
			rod(im, Vector2(16, 42), Vector2(16, 12), 1.2, SKELP, 3)
			for i in range(5):
				var y: float = 38.0 - float(i) * 6.0
				var sd: float = 1.0 if i % 2 == 0 else -1.0
				_leaf(im, Vector2(16, y), Vector2(sd, -0.45), 12.0, 3.0, SKELP, false)
				_ball(im, Vector2(16 + sd * 2.0, y - 1.0), 1.5, SKELP)
			_leaf(im, Vector2(16, 14), Vector2(0.2, -1), 9.0, 2.6, SKELP, false),
		"sea_grape": func(im: Image) -> void:
			_stem(im, Vector2(5, 40), Vector2(14, 33), SGRN[3])
			_stem(im, Vector2(14, 33), Vector2(24, 24), SGRN[3])
			_stem(im, Vector2(24, 24), Vector2(21, 11), SGRN[3])
			for c in [Vector2(8, 38), Vector2(12, 34), Vector2(16, 32), Vector2(19, 28), Vector2(24, 22), Vector2(22, 17), Vector2(21, 12), Vector2(11, 36), Vector2(26, 26), Vector2(18, 24), Vector2(23, 28), Vector2(15, 37)]:
				_berry(im, c as Vector2, 2.2, hx(["124a30", "1e6a40", "34904c", "58b868", "88d890", "b8f0b8"])),
		"storm_weed": func(im: Image) -> void:
			for i in range(5):
				var tip: Vector2 = Vector2(6.0 + float(i) * 5.0, 8.0 + float(i % 2) * 8.0)
				_ribbon(im, 16, 42, tip.x, tip.y, 3.0 * (1.0 if i % 2 == 0 else -1.0), 1.2, SGRN.map(func(c: Color) -> Color: return c.lerp(Color("5a5a20"), 0.45)))
				_ball(im, tip + Vector2(0, 3), 1.8, SKELP)
				_ball(im, tip.lerp(Vector2(16, 42), 0.4), 1.5, SKELP),
		"sea_anemone": func(im: Image) -> void:
			rod(im, Vector2(16, 42), Vector2(16, 30), 3.2, SCOR, 3)
			var rim: Array = hx(["5a2410", "8a3c1a", "c85a2a", "f07a3a", "ffa860", "ffd09a", "fff0d0"])
			for i in range(15):
				var a: float = PI + PI * float(i) / 14.0
				var tip: Vector2 = Vector2(16, 30) + Vector2(cos(a) * 13.0, sin(a) * 20.0)
				_stem(im, Vector2(16 + cos(a) * 2.0, 31), tip, rim[3] if i % 2 == 0 else rim[2])
				px(im, int(tip.x), int(tip.y), rim[6])
				px(im, int(tip.x), int(tip.y) + 1, rim[5]),
		"pearl_moss": func(im: Image) -> void:
			blob(im, 16, 36, 12, 7, SGRN, 0.05)
			blob(im, 9, 38, 6, 4, SGRN)
			blob(im, 23, 38, 6, 4, SGRN)
			for i in range(40):
				px(im, int(5.0 + h01(i, 2, 5) * 22.0), int(30.0 + h01(i, 3, 5) * 11.0), SGRN[5] if i % 2 == 0 else SGRN[2])
			for c in [Vector2(11, 32), Vector2(17, 29), Vector2(22, 33), Vector2(14, 36), Vector2(20, 37), Vector2(9, 37)]:
				_pearl(im, c as Vector2, 1.9),
		"coral_bloom": func(im: Image) -> void:
			var branches: Array = [[Vector2(16, 42), Vector2(16, 24)], [Vector2(16, 30), Vector2(7, 18)], [Vector2(16, 30), Vector2(25, 16)], [Vector2(16, 24), Vector2(12, 8)], [Vector2(16, 24), Vector2(21, 7)], [Vector2(7, 18), Vector2(4, 8)], [Vector2(25, 16), Vector2(29, 8)]]
			for b in branches:
				rod(im, b[0] as Vector2, b[1] as Vector2, 1.5, SCOR, 3)
			for t in [Vector2(12, 8), Vector2(21, 7), Vector2(4, 8), Vector2(29, 8), Vector2(7, 18), Vector2(25, 16)]:
				_ball(im, t as Vector2, 2.2, hx(["722a40", "a03e58", "d8607a", "f88a96", "ffb4b8", "ffdcd8"]))
				px(im, int((t as Vector2).x), int((t as Vector2).y) - 1, Color("fff4e8")),
		"ice_algae": func(im: Image) -> void:
			for a in [-2.4, -1.95, -1.57, -1.2, -0.75]:
				_leaf(im, Vector2(16, 41), Vector2(cos(a), sin(a)), 24.0 + h01(int(a * 10.0), 1, 3) * 6.0, 4.0, SICE, true)
				var e: Vector2 = Vector2(16, 41) + Vector2(cos(a), sin(a)) * 12.0
				px(im, int(e.x) + 2, int(e.y), SICE[6])
			for e2 in [Vector2(6, 12), Vector2(26, 14), Vector2(15, 4)]:
				_star(im, e2 as Vector2, Color("d8f4ff")),
		"star_coral": func(im: Image) -> void:
			var ORG: Array = hx(["4a2010", "7a3a1c", "b0602c", "d88440", "f0a860", "fccc88", "fff0c0"])
			blob(im, 16, 33, 13, 10, ORG, 0.0)
			for i in range(22):
				var c: Vector2 = Vector2(6.0 + h01(i, 4, 6) * 20.0, 26.0 + h01(i, 5, 6) * 14.0)
				if Vector2((c.x - 16.0) / 13.0, (c.y - 33.0) / 10.0).length() < 0.85:
					_star(im, c, Color("ffe8b0") if i % 3 != 0 else Color("fff8e0")),
		"glow_algae": func(im: Image) -> void:
			var GL: Array = hx(["0a3a30", "106050", "1c8a6a", "34b888", "64e0a8", "a8ffd0", "e8fff4"])
			for i in range(6):
				var tx: float = 7.0 + float(i) * 3.6
				var ty: float = 8.0 + h01(i, 7, 2) * 12.0
				_ribbon(im, 16.0 + (float(i) - 2.5) * 1.2, 42, tx, ty, 3.0 * (1.0 if i % 2 == 0 else -1.0), 0.0, GL)
				for k in range(3):
					var p: Vector2 = Vector2(lerpf(16.0, tx, 0.3 + 0.25 * float(k)), lerpf(40.0, ty, 0.3 + 0.25 * float(k)))
					blob(im, p.x, p.y, 1.5, 1.5, [GL[3], GL[4], GL[5], GL[6]]),
		"mermaid_hair": func(im: Image) -> void:
			var HR: Array = hx(["0a3a3e", "14585c", "20787a", "34989a", "56b8b4", "88d8cc", "c0f4e4"])
			for i in range(9):
				var bx: float = 9.0 + float(i) * 1.8
				var wob: float = 5.0 + h01(i, 8, 3) * 4.0
				_ribbon(im, bx, 42, 4.0 + float(i) * 2.7, 3.0 + h01(i, 9, 3) * 9.0, wob * (1.0 if i % 2 == 0 else -1.0), 0.0, HR),
		"abyss_kelp": func(im: Image) -> void:
			for i in range(4):
				var bx: float = 9.0 + float(i) * 4.6
				_leaf(im, Vector2(bx, 42), Vector2((float(i) - 1.5) * 0.35, -1), 34.0, 4.6, SDEEP, true)
			for e in [Vector2(10, 22), Vector2(22, 14), Vector2(16, 30), Vector2(25, 28)]:
				px(im, int((e as Vector2).x), int((e as Vector2).y), Color("6ac0ff")),
		"siren_lily": func(im: Image) -> void:
			for y in range(34, 42):
				for x in range(3, 29):
					var d: float = Vector2((x + 0.5 - 16.0) / 13.0, (y + 0.5 - 38.0) / 4.2).length()
					if d <= 1.0 and not (x > 16 and x < 19 and y < 38):
						px(im, x, y, SGRN[3 if y < 38 else 2] if h01(x, y, 5) > 0.12 else SGRN[4])
			_petals(im, Vector2(16, 30), 7, 9.0, 2.6, SLIL, 0.85, PI, PI)
			_petals(im, Vector2(16, 31), 5, 6.0, 2.2, SLIL.map(func(c: Color) -> Color: return c.lightened(0.15)), 0.8, PI + 0.3, PI - 0.6)
			blob(im, 16, 29, 1.8, 1.6, [SLIL[4], SLIL[5], SLIL[6], Color.WHITE])
			for e in [Vector2(6, 16), Vector2(26, 12), Vector2(21, 6), Vector2(10, 7)]:
				_star(im, e as Vector2, Color("e0d0ff")),
		"tide_orchid": func(im: Image) -> void:
			var TO: Array = hx(["0a3a42", "14606a", "208690", "38aab0", "6ccccc", "a8ecea", "e8fffc"])
			for a in [-2.8, -2.3, -0.8, -0.35]:
				_leaf(im, Vector2(16, 41), Vector2(cos(a), sin(a) * 0.35), 11.0, 2.8, SGRN)
			_stem(im, Vector2(16, 40), Vector2(18, 12), SGRN[3])
			for c in [Vector2(18, 11), Vector2(12, 20), Vector2(22, 24)]:
				var cc: Vector2 = c as Vector2
				_stem(im, Vector2(17, 32), cc, SGRN[3])
				_petals(im, cc, 5, 4.6, 1.8, TO, 1.0, -PI / 2.0)
				blob(im, cc.x, cc.y + 1.0, 1.3, 1.4, [TO[2], TO[3], TO[4], Color("ffe0f0")])
			for e in [Vector2(7, 11), Vector2(26, 8)]:
				_star(im, e as Vector2, Color("c8fff4")),
		"pearl_flower": func(im: Image) -> void:
			var PF: Array = hx(["6a4a6a", "9a7a96", "c4a4bc", "e4cce0", "f8e8f4", "fff8fc", "ffffff"])
			_stem(im, Vector2(16, 42), Vector2(16, 28), SGRN[3])
			_petals(im, Vector2(16, 26), 9, 13.0, 3.6, PF, 0.7, PI, PI)
			_petals(im, Vector2(16, 27), 7, 9.0, 3.0, PF.map(func(c: Color) -> Color: return c.lightened(0.1)), 0.7, PI + 0.25, PI - 0.5)
			_pearl(im, Vector2(16, 24), 4.6)
			for e in [Vector2(5, 8), Vector2(27, 10), Vector2(16, 3), Vector2(4, 22), Vector2(28, 24)]:
				_star(im, e as Vector2, Color("fff4c8")),
	}
	for id in specs.keys():
		var im: Image = img(32, 48)
		_sand(im)
		(specs[id] as Callable).call(im)
		outline(im, 0.55)
		save(im, "herb14_" + String(id))


func gen_herbs() -> void:
	var specs: Dictionary = {
		"plantain": func(im: Image) -> void:
			for a in [-2.5, -1.9, -1.25, -0.65]:
				_leaf(im, Vector2(16, 40), Vector2(cos(a), sin(a) * 0.55), 11.0, 3.6, HG)
			for sx in [-1, 1]:
				_stem(im, Vector2(16 + sx * 2, 38), Vector2(16 + sx * 4, 14), HG[3])
				_spike(im, Vector2(16 + sx * 4, 24), Vector2(16 + sx * 4, 12), hx(["3a3020", "54482c", "6e623a", "8a7e4a", "a89a5a", "c8b874", "e0d498"]), 1),
		"clover": func(im: Image) -> void:
			for i in range(5):
				var lx: float = 9.0 + i * 3.5
				_stem(im, Vector2(16, 41), Vector2(lx, 26 + (i % 2) * 4), HG[3])
				for t in [0.0, 2.1, 4.2]:
					blob(im, lx + cos(t) * 2.0, 26 + (i % 2) * 4 + sin(t) * 1.4, 1.8, 1.5, HG)
				px(im, int(lx), 26 + (i % 2) * 4, HG[6])
			for c in [Vector2(11, 14), Vector2(19, 11), Vector2(22, 18)]:
				_stem(im, Vector2(16, 40), c as Vector2, HG[2])
				_ball(im, c as Vector2, 3.3, hx(["5a1a3a", "7a2a52", "a8406e", "c8588a", "e078a4", "f0a0c0", "fcd0e0"])),
		"dandelion": func(im: Image) -> void:
			for a in [-2.7, -2.1, -1.0, -0.4]:
				_leaf(im, Vector2(16, 40), Vector2(cos(a), sin(a) * 0.5), 11.0, 2.6, HG)
				var e: Vector2 = Vector2(16, 40) + Vector2(cos(a), sin(a) * 0.5) * 6.0
				px(im, int(e.x), int(e.y) - 2, Color(0, 0, 0, 0))
			_stem(im, Vector2(15, 39), Vector2(12, 14), HG[4])
			_daisy(im, Vector2(12, 13), 3.6, Color("f8d838"), Color("e8a020"))
			_stem(im, Vector2(17, 39), Vector2(21, 20), HG[4])
			for i in range(14):
				var a2: float = TAU * float(i) / 14.0
				px(im, 21 + int(round(cos(a2) * 4.0)), 18 + int(round(sin(a2) * 4.0)), Color("f4f4ec") if i % 2 == 0 else Color("d8d8d0"))
			px(im, 21, 18, Color("b8a890")),
		"yarrow": func(im: Image) -> void:
			for i in range(5):
				var x0: float = 10.0 + i * 3.0
				_stem(im, Vector2(16, 41), Vector2(x0, 16 + (i % 2) * 5), HG[3])
				for k in range(4):
					var yy: float = 36.0 - k * 4.0
					px(im, int(16 + (x0 - 16) * (41 - yy) / 25.0) + (1 if k % 2 == 0 else -1), int(yy), HG[5])
			_umbel(im, Vector2(12, 15), 4.0, hx(["8a8478", "a8a296", "c8c2b6", "dcd8cc", "eeeae0", "f8f6f0", "ffffff"]))
			_umbel(im, Vector2(20, 13), 4.5, hx(["8a8478", "a8a296", "c8c2b6", "dcd8cc", "eeeae0", "f8f6f0", "ffffff"])),
		"thyme": func(im: Image) -> void:
			for y in range(28, 42):
				for x in range(5, 27):
					var d: float = Vector2((x + 0.5 - 16.0) / 11.0, (y + 0.5 - 38.0) / 9.0).length()
					if d <= 1.0 and h01(x, y, 4) < 0.85:
						px(im, x, y, HG2[3 + int(h01(x, y, 8) * 2.5) - (1 if y > 36 else 0)])
			for i in range(16):
				var p: Vector2 = Vector2(7 + h01(i, 1, 2) * 18.0, 29 + h01(i, 2, 3) * 8.0)
				px(im, int(p.x), int(p.y), Color("c890d0"))
				px(im, int(p.x), int(p.y) - 1, Color("e8b8ec")),
		"calendula": func(im: Image) -> void:
			_tuft(im, 6, 10.0, 2.4, HG, 1.2, 0.8)
			for c in [Vector2(10, 16), Vector2(18, 12), Vector2(23, 20)]:
				_stem(im, Vector2(16, 38), c as Vector2, HG[3])
				_daisy(im, c as Vector2, 3.8, Color("f89828"), Color("b85818"))
				px(im, int((c as Vector2).x) - 2, int((c as Vector2).y) - 2, Color("fcc070")),
		"cornflower": func(im: Image) -> void:
			for c in [Vector2(11, 12), Vector2(19, 9), Vector2(22, 19), Vector2(13, 22)]:
				_stem(im, Vector2(16, 41), c as Vector2, HG2[3])
				for i in range(9):
					var a: float = TAU * float(i) / 9.0
					var p: Vector2 = (c as Vector2) + Vector2(cos(a), sin(a) * 0.8) * 3.0
					px(im, int(p.x), int(p.y), Color("3a6ae0") if i % 2 == 0 else Color("6a98f8"))
					px(im, int((p.x + (c as Vector2).x) / 2.0), int((p.y + (c as Vector2).y) / 2.0), Color("2848b0"))
				px(im, int((c as Vector2).x), int((c as Vector2).y), Color("8a3a9a"))
			_tuft(im, 4, 9.0, 1.4, HG2, 0.8),
		"poppy": func(im: Image) -> void:
			_tuft(im, 4, 8.0, 2.0, HG2, 1.1, 0.7)
			for c in [Vector2(11, 14), Vector2(21, 11)]:
				_stem(im, Vector2(16, 40), (c as Vector2) + Vector2(0, 3), HG2[4])
				blob(im, (c as Vector2).x, (c as Vector2).y, 4.6, 3.8, hx(["5a0a0a", "8a1414", "b82020", "d83228", "f04a3a", "f87a62", "fcaa90"]))
				blob(im, (c as Vector2).x, (c as Vector2).y + 0.5, 1.5, 1.2, hx(["101010", "1a1a1a", "2a2a2a", "3a3a3a"]))
			_stem(im, Vector2(15, 40), Vector2(8, 26), HG2[4])
			blob(im, 8, 25, 1.6, 2.2, HG2),
		"st_john": func(im: Image) -> void:
			for i in range(3):
				var x0: float = 11.0 + i * 5.0
				_stem(im, Vector2(16, 41), Vector2(x0, 12 + i * 3), HG[3])
				for k in range(4):
					var yy: float = 36.0 - k * 5.0
					var xx: float = 16 + (x0 - 16) * (41 - yy) / (29.0 - i * 3)
					_leaf(im, Vector2(xx, yy), Vector2(-1, -0.4), 3.5, 1.2, HG, false)
					_leaf(im, Vector2(xx, yy), Vector2(1, -0.4), 3.5, 1.2, HG, false)
				for f in range(3):
					_star(im, Vector2(x0 - 2 + f * 2, 11 + i * 3 + (f % 2) * 2), Color("f0c020")),
		"oregano": func(im: Image) -> void:
			_tuft(im, 5, 9.0, 2.6, HG, 1.0)
			for i in range(4):
				var c: Vector2 = Vector2(9 + i * 5, 14 + (i % 2) * 4)
				_stem(im, Vector2(16, 38), c, HG[3])
				_ball(im, c, 2.6, hx(["4a2048", "62305e", "7c4478", "985a92", "b878b0", "d498cc", "ecc0e4"])),
		"lungwort": func(im: Image) -> void:
			for a in [-2.6, -2.0, -1.1, -0.5]:
				_leaf(im, Vector2(16, 40), Vector2(cos(a), sin(a) * 0.6), 10.0, 3.2, HDK)
			for k in range(6):
				px(im, 9 + k * 3, 34 + (k % 2) * 2, Color("a8c8a0"))
			_stem(im, Vector2(16, 38), Vector2(15, 15), HDK[4])
			for f in [[12, 14, Color("e070a8")], [16, 12, Color("6a7ae0")], [19, 15, Color("b060c0")], [14, 18, Color("e888b8")], [18, 19, Color("7888e8")]]:
				var fv: Array = f
				_bell(im, Vector2(float(fv[0]), float(fv[1])), [(fv[2] as Color).darkened(0.5), (fv[2] as Color).darkened(0.35), (fv[2] as Color).darkened(0.2), (fv[2] as Color).darkened(0.05), fv[2], (fv[2] as Color).lightened(0.25)]),
		"lily_valley": func(im: Image) -> void:
			_leaf(im, Vector2(14, 41), Vector2(-0.35, -1), 24.0, 4.2, HG)
			_leaf(im, Vector2(18, 41), Vector2(0.3, -1), 22.0, 4.0, HG2)
			for k in range(6):
				var p: Vector2 = Vector2(17, 12).lerp(Vector2(24, 30), float(k) / 5.0)
				_bell(im, p + Vector2(1, 1), hx(["8a8a80", "a8a8a0", "c8c8c0", "e0e0d8", "f4f4ee", "ffffff"]))
			line(im, 16, 40, 17, 12, HG[4])
			line(im, 17, 12, 24, 30, HG[4]),
		"strawberry": func(im: Image) -> void:
			for c in [Vector2(10, 30), Vector2(16, 26), Vector2(22, 30), Vector2(13, 35), Vector2(20, 35)]:
				_stem(im, Vector2(16, 41), c as Vector2, HG[3])
				for t in [-0.9, 0.0, 0.9]:
					_leaf(im, c as Vector2, Vector2(sin(t), -cos(t)), 4.5, 1.8, HG)
			for b in [Vector2(9, 38), Vector2(24, 37), Vector2(18, 39)]:
				_berry(im, b as Vector2, 2.2, hx(["5a0a10", "8a1418", "b82424", "d83a32", "f05a48", "f88a78"]))
				px(im, int((b as Vector2).x), int((b as Vector2).y) - 2, HG[5])
			_daisy(im, Vector2(14, 20), 2.2, Color("f8f8f0"), Color("e8c040")),
		"lingonberry": func(im: Image) -> void:
			for i in range(4):
				var x0: float = 9.0 + i * 4.5
				_stem(im, Vector2(16, 41), Vector2(x0, 20 + (i % 2) * 4), HDK[3])
				for k in range(5):
					var p: Vector2 = Vector2(16, 41).lerp(Vector2(x0, 20 + (i % 2) * 4), float(k) / 4.5)
					blob(im, p.x + (1.6 if k % 2 == 0 else -1.6), p.y, 1.7, 1.2, HDK)
			for b in [Vector2(11, 22), Vector2(13, 24), Vector2(20, 19), Vector2(22, 21), Vector2(19, 23)]:
				_berry(im, b as Vector2, 1.5, hx(["5a0a10", "8a1418", "b82424", "d83a32", "f05a48", "f88a78"])),
		"fern": func(im: Image) -> void:
			for f in [[-0.55, 22.0], [0.0, 26.0], [0.55, 22.0], [-1.0, 16.0], [1.0, 16.0]]:
				var fv: Array = f
				var a: float = -PI / 2.0 + float(fv[0])
				var dir: Vector2 = Vector2(cos(a), sin(a))
				var tip: Vector2 = Vector2(16, 41) + dir * float(fv[1])
				_stem(im, Vector2(16, 41), tip, HG[2])
				var n: int = int(float(fv[1]) / 2.5)
				for k in range(2, n):
					var p: Vector2 = Vector2(16, 41) + dir * float(k) * 2.5
					var ln: float = 4.5 * (1.0 - float(k) / float(n)) + 1.0
					_leaf(im, p, dir.orthogonal() + dir * 0.4, ln, 1.1, HG, false)
					_leaf(im, p, -dir.orthogonal() + dir * 0.4, ln, 1.1, HG, false),
		"club_moss": func(im: Image) -> void:
			for i in range(5):
				var x0: float = 7.0 + i * 4.5
				var top: float = 18.0 + h01(i, 3, 1) * 10.0
				for y in range(int(top), 42):
					px(im, int(x0), y, HG2[4] if y % 2 == 0 else HG2[3])
					px(im, int(x0) - 1, y, HG2[2] if y % 3 == 0 else HG2[3])
					px(im, int(x0) + 1, y, HG2[5] if y % 3 == 1 else HG2[4])
				rect(im, int(x0) - 1, int(top) - 5, 2, 5, Color("d8c860"))
				px(im, int(x0) - 1, int(top) - 5, Color("f0e090")),
		"heather": func(im: Image) -> void:
			for i in range(6):
				var x0: float = 7.0 + i * 3.6
				var top: Vector2 = Vector2(x0 + (i - 2.5) * 0.8, 12 + (i % 3) * 3)
				_stem(im, Vector2(16, 41), top + Vector2(0, 10), HDK[3])
				_spike(im, top + Vector2(0, 12), top, hx(["3a1830", "58244a", "7a3466", "9a4884", "b862a2", "d888c0", "ecb0d8"]), 1)
			_tuft(im, 7, 7.0, 1.2, HDK, 1.4),
		"rosehip": func(im: Image) -> void:
			for i in range(3):
				var tip: Vector2 = Vector2(8 + i * 8, 10 + (i % 2) * 6)
				_stem(im, Vector2(16, 41), tip, WOOD[3])
				for k in range(4):
					var p: Vector2 = Vector2(16, 41).lerp(tip, 0.3 + k * 0.2)
					_leaf(im, p, Vector2(1 if k % 2 == 0 else -1, -0.6), 4.0, 1.6, HG, false)
					px(im, int(p.x) + 1, int(p.y), Color("c8a080"))
			for b in [Vector2(8, 12), Vector2(16, 18), Vector2(24, 11), Vector2(20, 24), Vector2(11, 25)]:
				_berry(im, b as Vector2, 2.0, hx(["5a1a08", "8a2a10", "c04018", "e05a20", "f88030", "fcb070"]))
				px(im, int((b as Vector2).x), int((b as Vector2).y) - 2, Color("3a2010")),
		"sage": func(im: Image) -> void:
			var sg: Array = hx(["243a2c", "36503e", "4c6a54", "64846c", "82a088", "a2bca6", "c8dccc"])
			_stem(im, Vector2(16, 41), Vector2(16, 8), sg[2])
			for k in range(4):
				var y0: float = 38.0 - k * 6.0
				for sx in [-1, 1]:
					_leaf(im, Vector2(16, y0), Vector2(float(sx), -0.55), 10.0 - k * 1.8, 2.4 - k * 0.3, sg)
			_spike(im, Vector2(16, 22), Vector2(16, 6), hx(["2a2050", "3a2e6a", "4e3e88", "6a54a8", "8a70c8", "aa90e0", "ccb8f4"]), 1),
		"valerian": func(im: Image) -> void:
			_tuft(im, 5, 10.0, 2.2, HG, 1.1)
			_stem(im, Vector2(16, 38), Vector2(15, 12), HG[4])
			_stem(im, Vector2(16, 30), Vector2(21, 16), HG[4])
			_umbel(im, Vector2(15, 11), 5.0, hx(["6a3a4a", "8a5068", "a8688a", "c888a8", "e0a8c4", "f0c8dc", "fce8f0"]))
			_umbel(im, Vector2(21, 15), 3.5, hx(["6a3a4a", "8a5068", "a8688a", "c888a8", "e0a8c4", "f0c8dc", "fce8f0"])),
		"wormwood": func(im: Image) -> void:
			for i in range(5):
				var tip: Vector2 = Vector2(8 + i * 4, 8 + (i % 2) * 5)
				_stem(im, Vector2(16, 41), tip, HSIL[3])
				for k in range(7):
					var p: Vector2 = Vector2(16, 41).lerp(tip, 0.2 + k * 0.12)
					px(im, int(p.x) - 1, int(p.y), HSIL[5])
					px(im, int(p.x) + 1, int(p.y) - 1, HSIL[4])
					px(im, int(p.x) + (2 if k % 2 == 0 else -2), int(p.y) + 1, HSIL[6] if k % 3 == 0 else HSIL[4])
				px(im, int(tip.x), int(tip.y), Color("d8c870")),
		"moonbloom": func(im: Image) -> void:
			_tuft(im, 5, 9.0, 2.2, HDK, 1.1)
			_stem(im, Vector2(16, 38), Vector2(16, 14), HDK[4])
			for i in range(6):
				var a: float = TAU * float(i) / 6.0 - PI / 2.0
				_leaf(im, Vector2(16, 13), Vector2(cos(a), sin(a)), 6.0, 2.2, MOON, false)
			blob(im, 16, 13, 2.0, 2.0, hx(["c8d8ff", "e0e8ff", "f0f4ff", "ffffff"]))
			for s in [Vector2(9, 8), Vector2(24, 10), Vector2(22, 4)]:
				px(im, int((s as Vector2).x), int((s as Vector2).y), Color("e8f0ff")),
		"unicorn_mane": func(im: Image) -> void:
			for i in range(9):
				var x0: float = 8.0 + i * 2.0
				var sway: float = sin(float(i) * 1.3) * 3.0
				for y in range(10 + (i % 3) * 3, 42):
					var t: float = float(42 - y) / 30.0
					var col: Color = Color.from_hsv(fmod(0.83 + float(i) * 0.04 + t * 0.12, 1.0), 0.28, 0.98)
					px(im, int(x0 + sway * t * t), y, col.darkened(0.2 if (i % 2 == 1) else 0.0))
			for s in [Vector2(11, 12), Vector2(19, 9)]:
				px(im, int((s as Vector2).x), int((s as Vector2).y), Color("ffffff")),
		"pink_clover": func(im: Image) -> void:
			for t in [0.0, 1.2, 2.4, 3.6, 4.8]:
				var c: Vector2 = Vector2(16 + cos(t) * 6.0, 34 + sin(t) * 3.0)
				blob(im, c.x, c.y, 2.4, 1.8, HG)
			for c2 in [Vector2(11, 17), Vector2(20, 13)]:
				_stem(im, Vector2(16, 36), c2 as Vector2, HG[3])
				_ball(im, c2 as Vector2, 4.6, HPINK),
		"glowmoss": func(im: Image) -> void:
			for y in range(26, 42):
				for x in range(4, 28):
					var d: float = Vector2((x + 0.5 - 16.0) / 12.0, (y + 0.5 - 40.0) / 13.0).length()
					if d <= 1.0 and h01(x, y, 6) < 0.9:
						var k: int = 2 + int(h01(x / 2, y / 2, 9) * 3.0) + (1 if y < 32 else 0)
						px(im, x, y, HBLUE[clampi(k, 0, 6)])
			for i in range(10):
				var p: Vector2 = Vector2(6 + h01(i, 7, 1) * 20.0, 28 + h01(i, 8, 2) * 10.0)
				px(im, int(p.x), int(p.y), Color("e8ffff"))
				px(im, int(p.x), int(p.y) - 1, HBLUE[6])
				px(im, int(p.x), int(p.y) - 2, HBLUE[5]),
		"stonecrop": func(im: Image) -> void:
			blob(im, 16, 37, 9.0, 5.0, STONE.map(func(c: Color) -> Color: return c.lightened(0.35)))
			for i in range(14):
				var p: Vector2 = Vector2(9 + h01(i, 3, 4) * 14.0, 31 + h01(i, 4, 5) * 6.0)
				blob(im, p.x, p.y, 1.3, 1.3, HG2)
			for i2 in range(6):
				_star(im, Vector2(9 + i2 * 3, 28 + (i2 % 2) * 2), Color("f8d020")),
		"crystal_root": func(im: Image) -> void:
			for r in [[-0.3, 14.0], [0.25, 12.0], [-1.0, 8.0], [0.9, 9.0]]:
				var rv: Array = r
				rod(im, Vector2(16, 40), Vector2(16, 40) + Vector2(sin(float(rv[0])), -cos(float(rv[0]))) * float(rv[1]) * 0.6, 1.4, WOOD, 4)
			var cr: Array = hx(["2a1a5a", "3e2a80", "5a42a8", "7a62c8", "a088e0", "c8b4f4", "f0e8ff"])
			for c in [[16, 10, 4.0, 14.0], [10, 20, 3.0, 9.0], [22, 18, 3.0, 11.0]]:
				var cv: Array = c
				var cx: float = float(cv[0])
				var ty: float = float(cv[1])
				var w: float = float(cv[2])
				var hgt: float = float(cv[3])
				shaded_poly(im, PackedVector2Array([Vector2(cx, ty), Vector2(cx + w, ty + 3), Vector2(cx + w, ty + hgt), Vector2(cx, ty + hgt + 2), Vector2(cx - w, ty + hgt), Vector2(cx - w, ty + 3)]), cr, 4)
				line(im, int(cx), int(ty) + 1, int(cx), int(ty + hgt), cr[6]),
		"calamus": func(im: Image) -> void:
			for i in range(6):
				var a: float = -PI / 2.0 + (float(i) - 2.5) * 0.14
				_leaf(im, Vector2(14 + i, 41), Vector2(cos(a), sin(a)), 30.0 - absf(i - 2.5) * 3.0, 1.6, HG, true)
			rod(im, Vector2(19, 28), Vector2(21, 18), 1.2, hx(["5a4a18", "7a6624", "9a8234", "baa048", "d4bc64"]), 3),
		"marsh_tea": func(im: Image) -> void:
			for i in range(4):
				var tip: Vector2 = Vector2(9 + i * 5, 13 + (i % 2) * 5)
				_stem(im, Vector2(16, 41), tip, WOOD[3])
				for k in range(5):
					var p: Vector2 = Vector2(16, 41).lerp(tip, 0.25 + k * 0.15)
					_leaf(im, p, Vector2(1 if k % 2 == 0 else -1, 0.4), 4.0, 0.9, HDK, false)
				_umbel(im, tip, 3.0, hx(["8a8478", "a8a296", "c8c2b6", "dcd8cc", "eeeae0", "f8f6f0", "ffffff"])),
		"sundew": func(im: Image) -> void:
			for i in range(8):
				var a: float = PI + PI * float(i) / 7.0
				var tip: Vector2 = Vector2(16, 38) + Vector2(cos(a) * 10.0, sin(a) * 7.0)
				_stem(im, Vector2(16, 39), tip, Color("6a8a3a"))
				blob(im, tip.x, tip.y, 2.0, 2.0, hx(["5a1010", "8a1c18", "b82e24", "d84838", "f06a50"]))
				for k in range(4):
					var g: Vector2 = tip + Vector2(cos(float(k) * 1.6), sin(float(k) * 1.6)) * 2.6
					px(im, int(g.x), int(g.y), Color("f8e0ff"))
			_stem(im, Vector2(16, 37), Vector2(17, 12), Color("6a8a3a"))
			_daisy(im, Vector2(17, 11), 1.8, Color("f8f8f8"), Color("f0e0a0")),
		"cloudberry": func(im: Image) -> void:
			for c in [Vector2(10, 32), Vector2(22, 32)]:
				_stem(im, Vector2(16, 41), c as Vector2, HG[3])
				blob(im, (c as Vector2).x, (c as Vector2).y, 4.6, 3.4, HG)
				for k in range(5):
					px(im, int((c as Vector2).x) - 3 + k * 2, int((c as Vector2).y) + 3, HG[1])
			_stem(im, Vector2(16, 41), Vector2(16, 18), HG[4])
			blob(im, 16, 15, 4.0, 4.4, AMBER)
			for k2 in range(6):
				px(im, 14 + (k2 % 3) * 2, 13 + (k2 / 3) * 3, AMBER[6])
			px(im, 16, 10, HG[5]),
		"sea_buckthorn": func(im: Image) -> void:
			for i in range(3):
				var tip: Vector2 = Vector2(8 + i * 8, 8 + (i % 2) * 6)
				_stem(im, Vector2(16, 41), tip, WOOD[2])
				for k in range(6):
					var p: Vector2 = Vector2(16, 41).lerp(tip, 0.15 + k * 0.14)
					_leaf(im, p, Vector2(1 if k % 2 == 0 else -1, -0.7), 5.0, 1.0, HSIL, false)
					if k > 1:
						_berry(im, p + Vector2(0, 1), 1.4, hx(["6a3008", "9a4a10", "d06a18", "f08a28", "f8b048", "fcd890"]))
						_berry(im, p + Vector2(2, 2), 1.3, hx(["6a3008", "9a4a10", "d06a18", "f08a28", "f8b048", "fcd890"])),
		"sea_lavender": func(im: Image) -> void:
			_tuft(im, 4, 7.0, 2.6, HSIL, 1.2, 0.6)
			for i in range(5):
				var tip: Vector2 = Vector2(8 + i * 4, 10 + (i % 2) * 6)
				_stem(im, Vector2(16, 37), tip + Vector2(0, 4), HSIL[3])
				for k in range(8):
					var p: Vector2 = tip + Vector2(h01(i, k, 1) * 6.0 - 3.0, h01(k, i, 2) * 5.0 - 2.0)
					px(im, int(p.x), int(p.y), Color("b090e0") if k % 2 == 0 else Color("d8c0f4")),
		"sea_kale": func(im: Image) -> void:
			for a in [-2.7, -2.1, -1.5, -0.9, -0.4]:
				blob(im, 16 + cos(a) * 8.0, 34 + sin(a) * 6.0, 5.0, 3.6, HG2.map(func(c: Color) -> Color: return c.lerp(Color("8ab0c0"), 0.4)))
			_stem(im, Vector2(16, 34), Vector2(16, 14), HG2[4])
			_umbel(im, Vector2(16, 13), 5.0, hx(["8a8478", "a8a296", "c8c2b6", "dcd8cc", "eeeae0", "f8f6f0", "ffffff"])),
		"nightshade": func(im: Image) -> void:
			for i in range(3):
				var tip: Vector2 = Vector2(9 + i * 7, 9 + (i % 2) * 5)
				_stem(im, Vector2(16, 41), tip, HPUR[3])
				_leaf(im, Vector2(16, 41).lerp(tip, 0.5), Vector2(1 if i % 2 == 0 else -1, -0.5), 7.0, 2.8, HDK)
				_leaf(im, tip, Vector2(0.3, -1), 5.0, 2.2, HDK)
			for b in [Vector2(10, 22), Vector2(22, 19), Vector2(15, 27)]:
				_berry(im, b as Vector2, 2.4, hx(["080808", "141018", "201828", "302438", "48385a", "6a5a80"]))
			_bell(im, Vector2(20, 12), HPUR.slice(1)),
		"mandrake": func(im: Image) -> void:
			# корень-человечек выглядывает из земли, сверху — большие листья
			blob(im, 16, 38, 4.0, 4.6, hx(["4a3018", "6a4624", "8a5e34", "a87a48", "c49862", "dcb880"]))
			px(im, 14, 37, Color("2a1a10"))
			px(im, 18, 37, Color("2a1a10"))
			px(im, 16, 40, Color("6a3a24"))
			for a in [-2.6, -2.0, -1.6, -1.1, -0.5]:
				_leaf(im, Vector2(16, 34), Vector2(cos(a), sin(a)), 13.0, 3.6, HDK)
			_ball(im, Vector2(16, 17), 2.6, HPUR),
		"elf_leaf": func(im: Image) -> void:
			for a in [-2.2, -1.57, -0.95]:
				_leaf(im, Vector2(16, 41), Vector2(cos(a), sin(a)), 26.0, 5.0, hx(["0a2a1e", "144030", "1e5a42", "2a7856", "3e986c", "62bc8c", "a0e4bc"]))
			for s in [Vector2(10, 14), Vector2(22, 12), Vector2(17, 7)]:
				px(im, int((s as Vector2).x), int((s as Vector2).y), Color("f8ffb0"))
				px(im, int((s as Vector2).x) + 1, int((s as Vector2).y), Color("d0f090")),
		"shiso": func(im: Image) -> void:
			for k in range(4):
				var y0: float = 38.0 - k * 7.0
				for sx in [-1, 1]:
					_leaf(im, Vector2(16, y0), Vector2(float(sx), -0.5), 9.0 - k * 1.5, 3.4 - k * 0.4, HPUR)
			_stem(im, Vector2(16, 41), Vector2(16, 10), HPUR[2]),
		"ginseng": func(im: Image) -> void:
			rod(im, Vector2(16, 38), Vector2(13, 44), 1.6, hx(["6a5030", "8a6c44", "aa8a5a", "c8aa76", "e0c896"]), 3)
			rod(im, Vector2(16, 38), Vector2(19, 44), 1.4, hx(["6a5030", "8a6c44", "aa8a5a", "c8aa76", "e0c896"]), 3)
			_stem(im, Vector2(16, 37), Vector2(16, 20), HG[3])
			for a in [-2.4, -1.57, -0.7]:
				for t in [-0.35, 0.0, 0.35]:
					_leaf(im, Vector2(16, 20), Vector2(cos(a + float(t)), sin(a + float(t))), 7.0, 1.7, HG, false)
			for b in [Vector2(15, 12), Vector2(17, 11), Vector2(16, 13)]:
				_berry(im, b as Vector2, 1.3, hx(["5a0a10", "8a1418", "b82424", "d83a32", "f05a48", "f88a78"])),
		"fire_pepper": func(im: Image) -> void:
			_tuft(im, 6, 11.0, 2.4, HG, 1.2)
			for p in [[10, 18, -0.3], [17, 14, 0.1], [23, 20, 0.4]]:
				var pv: Array = p
				var top: Vector2 = Vector2(float(pv[0]), float(pv[1]))
				rod(im, top, top + Vector2(sin(float(pv[2])) * 3.0, 8.0), 1.6, hx(["5a0a08", "8a1810", "c02818", "e84020", "f87030", "fcb060"]), 4)
				px(im, int(top.x), int(top.y) - 1, HG[5])
				px(im, int(top.x) - 1, int(top.y) + 2, Color("fff0a0")),
		"catnip": func(im: Image) -> void:
			for k in range(4):
				var y0: float = 39.0 - k * 6.0
				for sx in [-1, 1]:
					_leaf(im, Vector2(16, y0), Vector2(float(sx), -0.3), 7.0 - k, 2.8, HG2)
			_stem(im, Vector2(16, 41), Vector2(16, 13), HG2[4])
			_spike(im, Vector2(16, 20), Vector2(16, 9), hx(["6a6070", "8a8094", "aaa0b8", "c8bed8", "e0d8f0", "f4f0fc", "ffffff"]), 1),
		"star_bell": func(im: Image) -> void:
			_tuft(im, 4, 7.0, 1.8, HG2, 1.0, 0.7)
			for c in [Vector2(11, 13), Vector2(16, 9), Vector2(21, 14), Vector2(14, 21), Vector2(20, 22)]:
				_stem(im, Vector2(16, 38), (c as Vector2) + Vector2(0, -1), HG2[3])
				var bc: Vector2 = c as Vector2
				rect(im, int(bc.x) - 2, int(bc.y), 5, 3, Color("4a6ae0"))
				rect(im, int(bc.x) - 1, int(bc.y) - 1, 3, 1, Color("6a88f0"))
				px(im, int(bc.x) - 2, int(bc.y), Color("8aa8ff"))
				px(im, int(bc.x), int(bc.y) + 2, Color("fff8a0")),
		"web_grass": func(im: Image) -> void:
			for i in range(8):
				var a: float = -PI / 2.0 + (float(i) - 3.5) * 0.17
				_stem(im, Vector2(16, 41), Vector2(16, 41) + Vector2(cos(a), sin(a)) * (26.0 - absf(i - 3.5) * 2.0), HSIL[3] if i % 2 == 0 else HG[3])
			for k in range(5):
				var y: int = 18 + k * 4
				line(im, 9 + k, y, 23 - k, y + 2, Color(0.95, 0.95, 1.0, 0.75))
			line(im, 12, 16, 20, 34, Color(0.95, 0.95, 1.0, 0.6)),
		"arnica": func(im: Image) -> void:
			for a in [-2.5, -0.65]:
				_leaf(im, Vector2(16, 40), Vector2(cos(a), sin(a) * 0.5), 9.0, 3.0, HG)
			_stem(im, Vector2(16, 40), Vector2(14, 12), HG[4])
			_stem(im, Vector2(16, 30), Vector2(21, 19), HG[4])
			_daisy(im, Vector2(14, 11), 4.4, Color("f8b818"), Color("c87818"))
			_daisy(im, Vector2(21, 18), 3.2, Color("f8c828"), Color("c87818")),
		# ---- v16: особые и мега-редкие травы
		"fire_lily": func(im: Image) -> void:
			var FL: Array = hx(["4a0a04", "7a1a08", "b02a0a", "e04a10", "f87a20", "fcb040", "fff0a0"])
			for a in [-2.6, -0.55]:
				_leaf(im, Vector2(16, 40), Vector2(cos(a), sin(a) * 0.5), 10.0, 2.2, HDK)
			_stem(im, Vector2(16, 40), Vector2(16, 17), HG[3])
			_stem(im, Vector2(16, 30), Vector2(22, 24), HG[3])
			# крупная лилия: шесть загнутых лепестков, светится изнутри
			for i in range(6):
				var a2: float = -PI / 2.0 + (float(i) - 2.5) * 0.52
				var tip: Vector2 = Vector2(16, 16) + Vector2(cos(a2), sin(a2) * 0.9) * 8.0
				_leaf(im, Vector2(16, 17), (tip - Vector2(16, 17)).normalized(), 8.0, 2.0, FL, false)
			blob(im, 16, 16, 2.0, 1.6, [FL[4], FL[5], FL[6], Color("ffffff")])
			for i in range(3):
				px(im, 14 + i * 2, 11 - (i % 2), FL[6])
				px(im, 14 + i * 2, 12 - (i % 2), HG[2])
			for i in range(5):
				var a3: float = TAU * float(i) / 5.0
				_leaf(im, Vector2(22, 24), Vector2(cos(a3), sin(a3) * 0.8), 3.5, 1.2, FL, false)
			for e in [Vector2(9, 9), Vector2(24, 12), Vector2(19, 6), Vector2(7, 20)]:
				px(im, int((e as Vector2).x), int((e as Vector2).y), Color("ffd060")),
		"frost_lotus": func(im: Image) -> void:
			var ICE: Array = hx(["2a4a6a", "4a74a0", "6e9ac4", "96bee0", "bcdcf4", "e0f0fc", "ffffff"])
			# лист-кувшинка на воде
			for y in range(33, 42):
				for x in range(4, 29):
					var d: float = Vector2((x + 0.5 - 16.0) / 12.0, (y + 0.5 - 38.0) / 4.0).length()
					if d <= 1.0 and not (x > 16 and x < 20 and y < 38):
						px(im, x, y, HG2[3 if y < 37 else 2] if h01(x, y, 3) > 0.1 else HG2[4])
			for ring in [[9.0, 0.0], [6.0, 0.3], [3.5, 0.6]]:
				for i in range(7):
					var a2: float = PI + PI * (float(i) + float(ring[1])) / 6.0
					var tip: Vector2 = Vector2(16, 29) + Vector2(cos(a2), sin(a2) * 1.1) * float(ring[0])
					_leaf(im, Vector2(16, 30), (tip - Vector2(16, 30)).normalized(), float(ring[0]), 2.0, ICE, false)
			blob(im, 16, 28, 1.6, 1.4, [ICE[4], ICE[5], ICE[6], Color.WHITE])
			for e in [Vector2(6, 14), Vector2(25, 18), Vector2(20, 9)]:
				_star(im, e as Vector2, Color("d8f0ff")),
		"shadow_orchid": func(im: Image) -> void:
			var SH: Array = hx(["0a0410", "180a24", "2a1240", "40205c", "5a3480", "7a52a8", "a080d0"])
			for a in [-2.8, -2.3, -0.8, -0.35]:
				_leaf(im, Vector2(16, 40), Vector2(cos(a), sin(a) * 0.35), 10.0, 2.6, HDK)
			_stem(im, Vector2(16, 39), Vector2(18, 14), SH[2])
			for c in [Vector2(18, 13), Vector2(12, 21), Vector2(22, 25)]:
				var cc: Vector2 = c as Vector2
				_stem(im, Vector2(17, 30), cc, SH[2])
				for i in range(5):
					var a2: float = TAU * float(i) / 5.0 - PI / 2.0
					_leaf(im, cc, Vector2(cos(a2), sin(a2)), 4.2, 1.6, SH, false)
				blob(im, cc.x, cc.y + 1.0, 1.4, 1.6, [SH[0], SH[1], SH[2], SH[3]])
				px(im, int(cc.x), int(cc.y), Color("c8f080"))
			for e in [Vector2(8, 12), Vector2(25, 9)]:
				px(im, int((e as Vector2).x), int((e as Vector2).y), Color("9a7ad0")),
		"sunflower_gold": func(im: Image) -> void:
			var GD: Array = hx(["6a3a04", "9a5a08", "c88010", "e8a820", "f8cc40", "fce878", "fffcd8"])
			for a in [-2.5, -0.65]:
				_leaf(im, Vector2(16, 36), Vector2(cos(a), sin(a) * 0.6), 9.0, 3.4, HG)
			_stem(im, Vector2(16, 41), Vector2(16, 16), HG[4])
			_stem(im, Vector2(17, 41), Vector2(17, 16), HG[3])
			for i in range(16):
				var a2: float = TAU * float(i) / 16.0
				var tip: Vector2 = Vector2(16, 13) + Vector2(cos(a2), sin(a2)) * 9.5
				_leaf(im, Vector2(16, 13), (tip - Vector2(16, 13)).normalized(), 9.5, 1.5, GD, false)
			blob(im, 16, 13, 4.2, 4.2, hx(["2a1404", "3e2008", "5a300c", "7a4414", "9a5a1c"]))
			for i in range(10):
				var a3: float = TAU * float(i) / 10.0
				px(im, 16 + int(round(cos(a3) * 2.6)), 13 + int(round(sin(a3) * 2.6)), Color("c88a2a"))
			px(im, 14, 11, Color("fff4c0")),
		"dragon_root": func(im: Image) -> void:
			var DR: Array = hx(["2a0a06", "4a140a", "7a2410", "a83a18", "c85a28", "e08040", "f0b070"])
			_tuft(im, 5, 9.0, 2.0, HDK, 1.1, 0.9)
			# корень-ящер в разрезе земли: изогнутое тело в чешуйках
			for i in range(22):
				var t: float = float(i) / 21.0
				var c: Vector2 = Vector2(6.0 + t * 20.0, 33.0 + sin(t * 5.5) * 4.0)
				blob(im, c.x, c.y, 2.6 - t * 1.4, 2.4 - t * 1.2, DR)
			for i in range(9):
				var t2: float = float(i) / 8.0
				var c2: Vector2 = Vector2(7.0 + t2 * 17.0, 32.0 + sin(t2 * 5.5) * 4.0)
				px(im, int(c2.x), int(c2.y) - 1, DR[6] if i % 2 == 0 else DR[5])
			px(im, 6, 32, Color("f8e040"))
			for e in [Vector2(12, 14), Vector2(20, 16)]:
				px(im, int((e as Vector2).x), int((e as Vector2).y), Color("f87a20")),
		"void_bloom": func(im: Image) -> void:
			var VD: Array = hx(["020206", "08060e", "12101e", "1e1a30", "2e2848", "4a3e6c", "7a68a8"])
			for a in [-2.7, -2.2, -0.9, -0.45]:
				_leaf(im, Vector2(16, 40), Vector2(cos(a), sin(a) * 0.4), 11.0, 2.4, VD)
			_stem(im, Vector2(16, 40), Vector2(16, 18), VD[3])
			for i in range(8):
				var a2: float = TAU * float(i) / 8.0
				var tip: Vector2 = Vector2(16, 16) + Vector2(cos(a2), sin(a2) * 0.85) * 9.0
				_leaf(im, Vector2(16, 16), (tip - Vector2(16, 16)).normalized(), 9.0, 2.4, VD, false)
			# глаз в середине
			blob(im, 16, 16, 3.0, 2.2, hx(["3a0a4a", "6a1a7a", "a03ab0", "d070e0", "f0b0f8"]))
			rect(im, 16, 14, 1, 5, Color("000000"))
			px(im, 15, 15, Color("ffffff"))
			for e in [Vector2(5, 8), Vector2(27, 12), Vector2(22, 5), Vector2(8, 26)]:
				px(im, int((e as Vector2).x), int((e as Vector2).y), Color("b070f0")),
		"phoenix_grass": func(im: Image) -> void:
			var PH: Array = hx(["5a0a04", "9a1e08", "d0400c", "f07018", "f8a830", "fcd860", "fff8d0"])
			for i in range(7):
				var a2: float = -PI / 2.0 + (float(i) - 3.0) * 0.28
				var ln: float = 26.0 - absf(float(i) - 3.0) * 3.5
				var b0: Vector2 = Vector2(16 + (float(i) - 3.0) * 0.8, 41)
				_stem(im, b0, b0 + Vector2(cos(a2), sin(a2)) * ln, PH[2])
				# перья: бородки по обе стороны стебля
				for k in range(4, int(ln)):
					var p: Vector2 = b0 + Vector2(cos(a2), sin(a2)) * float(k)
					var side: Vector2 = Vector2(cos(a2), sin(a2)).orthogonal()
					var w: float = 1.0 + 1.6 * sin(PI * float(k) / ln)
					for s in [-1.0, 1.0]:
						var q: Vector2 = p + side * float(s) * w
						px(im, int(q.x), int(q.y), PH[clampi(2 + int(float(k) / ln * 4.5), 0, 6)])
			for e in [Vector2(6, 6), Vector2(26, 9), Vector2(16, 2), Vector2(4, 18), Vector2(28, 20)]:
				px(im, int((e as Vector2).x), int((e as Vector2).y), Color("fff0a0")),
		"world_leaf": func(im: Image) -> void:
			var WL: Array = hx(["0e3a2a", "16583e", "247a52", "3a9e68", "62c084", "9ae0a8", "e0fff0"])
			_stem(im, Vector2(16, 41), Vector2(16, 30), HG[2])
			# огромный лист с золотыми прожилками, будто висит в воздухе
			_leaf(im, Vector2(16, 34), Vector2(0, -1), 28.0, 9.0, WL, false)
			_stem(im, Vector2(16, 33), Vector2(16, 8), Color("f8e070"))
			for i in range(5):
				var y0: float = 30.0 - i * 4.5
				for sx in [-1.0, 1.0]:
					_stem(im, Vector2(16, y0), Vector2(16 + sx * (6.0 - i * 0.6), y0 - 4.0), Color("e8c860"))
			for e in [Vector2(5, 10), Vector2(27, 14), Vector2(24, 4), Vector2(6, 24)]:
				_star(im, e as Vector2, Color("f8f0b0")),
	}
	for id in specs.keys():
		var im: Image = img(32, 48)
		_soil(im)
		(specs[id] as Callable).call(im)
		outline(im, 0.55)
		save(im, "herb14_" + String(id))
	# превью трав x5
	var sc: int = 5
	var cols: int = 11
	var big: Image = img(cols * (32 * sc + 8) + 8, 8 + int(ceil(float(specs.size()) / cols)) * (48 * sc + 8))
	big.fill(Color("3a3530"))
	var i2: int = 0
	for it in sheet:
		var im2: Image = (it[1] as Image).duplicate()
		im2.resize(32 * sc, 48 * sc, Image.INTERPOLATE_NEAREST)
		big.blend_rect(im2, Rect2i(0, 0, im2.get_width(), im2.get_height()), Vector2i(8 + (i2 % cols) * (32 * sc + 8), 8 + (i2 / cols) * (48 * sc + 8)))
		i2 += 1
	big.save_png(ProjectSettings.globalize_path("res://").path_join("../screenshots/v15_herbs.png"))

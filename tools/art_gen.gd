extends SceneTree
## Генератор пиксель-арта «Лесного травника» (детальная версия, пиксель мира = 2x2 экрана).
## Запуск: godot --headless --path game --script res://tools/art_gen.gd
## Все картинки рисуются кодом и сохраняются в res://art/

const LAY = preload("res://world_layout.gd")
const OUT: String = "res://art/"

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var LT: Vector3 = Vector3(-0.5, -0.72, 0.85).normalized()

var GRASS: Array
var SAND: Array
var WATER: Array
var STONE: Array
var MOSS: Array
var TRUNK: Array
var TREE_A: Array
var TREE_B: Array
var TREE_C: Array
var PINE: Array
var BUSH: Array
var WOOD: Array
var THATCH: Array
var PLASTER: Array
var SOIL: Array
var SOIL_WET: Array
var MINT: Array
var SAGE: Array
var LAV: Array
var NETTLE: Array
var SKIN: Array
var HAIR: Array
var CLOAK: Array
var TUNIC: Array
var LEATHER: Array
var ORANGE: Array
var CREAM: Array
var GLASS: Array
var IVY: Array
var LEAF_GREEN: Array
var LEAF_LIME: Array
var LEAF_DEEP: Array
var BLOSSOM: Array
var AUTUMN: Array
var PINE5: Array
var BUSH5: Array
var STONE5: Array
var MINT5: Array
var MOSS5: Array
var IRON: Array
var PORCELAIN: Array
var RED: Array
var GOLD: Array

var OUT_DARK: Color = Color("2a2026")
var OUT_TREE: Color = Color("17271c")
var OUT_WOOD: Color = Color("2a1c15")
var OUT_STONE: Color = Color("2e2b30")

var preview_items: Array = []


func _init() -> void:
	_palettes()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var only: String = ""
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("--only="):
			only = String(a).substr(7)
	_palettes3()
	_palettes_hero()
	_palettes_v4()
	if only == "worldmaps":
		gen_world_maps()
		print("ART DONE")
		quit()
		return
	if only == "ponies25":
		gen_ponies25()
		print("ART DONE")
		quit()
		return
	if only == "ponies25_test":
		PONY_ONLY = ["pony_twilight", "pony_rainbow", "pony_rarity", "pony_celestia"]
		gen_ponies25()
		print("ART DONE")
		quit()
		return
	if only == "ponies25_bld":
		gen_pony_buildings25()
		print("ART DONE")
		quit()
		return
	if only == "v24":
		gen_realm_girls()
		print("ART DONE")
		quit()
		return
	if only == "swamp19":
		gen_swamp19()
		save_preview3()
		print("ART DONE")
		quit()
		return
	if only == "insects":
		gen_insects()
		print("ART DONE")
		quit()
		return
	if only == "interior":
		gen_interior()
		print("ART DONE")
		quit()
		return
	if only == "v13h":
		gen_home13()
		print("ART DONE")
		quit()
		return
	if only == "v13j":
		gen_japan13()
		print("ART DONE")
		quit()
		return
	if only == "v13s":
		gen_sea13()
		print("ART DONE")
		quit()
		return
	if only == "v13p":
		gen_people13()
		print("ART DONE")
		quit()
		return
	if only == "v12":
		gen_japan13()
		gen_sea13()
		print("ART DONE")
		quit()
		return
	if only == "v11":
		gen_home11()
		gen_home13()
		print("ART DONE")
		quit()
		return
	if only == "v10":
		gen_grass10()
		gen_streets10()
		gen_buildings10()
		print("ART DONE")
		quit()
		return
	if only == "critters":
		gen_critters()
		print("ART DONE")
		quit()
		return
	if only == "v9":
		gen_critters()
		gen_stations()
		gen_interiors9()
		print("ART DONE")
		quit()
		return
	if only == "wild":
		gen_wild()
		print("ART DONE")
		quit()
		return
	if only == "towns":
		gen_spidergirl()
		gen_towns()
		print("ART DONE")
		quit()
		return
	if only == "needs":
		gen_need_icons2()
		print("ART DONE")
		quit()
		return
	if only == "dwarves":
		gen_dwarves()
		print("ART DONE")
		quit()
		return
	if only == "orcs":
		gen_orcs()
		print("ART DONE")
		quit()
		return
	if only == "rock":
		gen_rock_girls()
		print("ART DONE")
		quit()
		return
	if only == "mages":
		gen_mages()
		print("ART DONE")
		quit()
		return
	if only == "elves":
		_palettes3()
		gen_elves()
		print("ART DONE")
		quit()
		return
	if only == "knights":
		gen_knights()
		print("ART DONE")
		quit()
		return
	if only == "gothic":
		gen_gothic()
		print("ART DONE")
		quit()
		return
	if only == "spider":
		gen_spider_forest()
		print("ART DONE")
		quit()
		return
	if only == "cats":
		gen_cats()
		print("ART DONE")
		quit()
		return
	if only == "world":
		gen_world()
		print("ART DONE")
		quit()
		return
	if only == "fish":
		gen_fish()
		print("ART DONE")
		quit()
		return
	if only == "v7":
		gen_player10()
		gen_v7()
		save_preview3()
		print("ART DONE")
		quit()
		return
	if only == "outfits":
		gen_outfits()
		quit()
		return
	if only == "hero":
		gen_player10()
		gen_cat5()
		gen_lineup()
		print("ART DONE")
		quit()
		return
	if only == "" or only == "ground":
		gen_ground()
	if only == "" or only == "props" or only == "v3":
		gen_v3()
	if only == "v3":
		save_preview3()
		print("ART DONE")
		quit()
		return
	if only == "" or only == "props":
		gen_flowers()
		gen_house()
		gen_well()
		gen_lantern()
		gen_fence()
		gen_pillar()
		gen_bench()
		gen_tea_table()
		gen_barrel()
		gen_sign()
		gen_small_props()
		gen_rock3()
		gen_mushrooms3()
		gen_plot_beds()
		gen_cat5()
		gen_v7()
		gen_player10()
		gen_fx()
		gen_ui()
		gen_fish()
		gen_interior()
		gen_insects()
	if only == "" or only == "book":
		gen_book()
	save_preview()
	print("ART DONE")
	quit()


# ================================================================== палитры

func hx(a: Array) -> Array:
	var r: Array = []
	for s in a:
		r.append(Color(String(s)))
	return r


func _palettes() -> void:
	GRASS = hx(["4f8a6a", "5f9a6e", "70aa72", "84b979", "98c780", "acd38a", "bfdd96", "d2e7a6", "e4f0bc"])
	SAND = hx(["a8866a", "c09e7c", "d4b68e", "e2c89e", "edd8b0", "f5e6c4", "fbf2dc"])
	WATER = hx(["3c6a96", "4a7fa8", "5a94ba", "6caacb", "82bfd9", "9dd2e4", "b9e2ec", "d4eff2", "eef9f8"])
	STONE = hx(["3e3c52", "555470", "6e6d88", "88879e", "a3a2b4", "bdbcc8", "d4d3da", "e8e7ea"])
	MOSS = hx(["3f6650", "578460", "72a06a", "92ba78", "b4d28c"])
	TRUNK = hx(["3a2832", "56383a", "754c42", "94654c", "b07f58", "c99a6a", "dcb682"])
	LEAF_GREEN = hx(["2a4a4e", "3b7466", "5fa46a", "93c876", "c8e494"])
	LEAF_LIME = hx(["2c5450", "3f8a72", "78c060", "a8da66", "dcf292"])
	LEAF_DEEP = hx(["243e48", "2f6262", "4a8a70", "74b282", "acd8a0"])
	BLOSSOM = hx(["6e3a5e", "c4709a", "eaa2bf", "f7cad8", "fff0f5"])
	AUTUMN = hx(["5e2e36", "b0563a", "e08c44", "f2bc5c", "fce394"])
	PINE5 = hx(["1e3a44", "2a5c5c", "3f8270", "62a682", "98cc9c"])
	BUSH5 = hx(["2a4a4e", "3f7a68", "6aac70", "9ccf7e", "d0ea9e"])
	STONE5 = hx(["3a3a52", "6a6a86", "9898ae", "c4c4d0", "e8e8ee"])
	MINT5 = hx(["204a3e", "2f7258", "4fa266", "84c878", "c2e89a"])
	MOSS5 = hx(["2e4a40", "4a7a58", "72a468", "a0c878", "cae49a"])
	TREE_A = hx(["15301f", "1d3f27", "27512f", "336539", "417a43", "52904d", "67a65a", "80bb69", "9fd07e", "c0e39a"])
	TREE_B = hx(["213a1e", "2c4b23", "3a5f29", "4b7430", "5e8a37", "74a142", "8db753", "a8cc68", "c5df86", "e0efaa"])
	TREE_C = hx(["13302c", "1b4038", "245245", "2f6553", "3c7a62", "4c8f71", "62a583", "7dbb96", "a0d2ae", "c6e6cc"])
	PINE = hx(["10261f", "16332a", "1e4335", "28553f", "33684a", "427c57", "568f66", "6fa478"])
	BUSH = hx(["1f3b22", "2a4e2c", "376237", "467743", "578c4f", "6aa15b", "82b66b", "a0cc82", "c2e2a2"])
	WOOD = hx(["2f1d13", "45291b", "5c3a24", "744b2f", "8c5f3b", "a4764a", "bb8d5e", "d0a676", "e2c095"])
	THATCH = hx(["5e3a14", "7a4c18", "96621f", "b07a28", "c89433", "dcac42", "ebc25a", "f4d77e", "fae9aa", "fdf5d6"])
	PLASTER = hx(["b8a27a", "c9b48c", "d8c59e", "e5d5b2", "efe2c6", "f7efdc"])
	SOIL = hx(["2c1b11", "3e2718", "52341f", "674328", "7c5433", "93673f", "aa7c4e"])
	SOIL_WET = hx(["1a0f09", "26170e", "332015", "41291b", "513422", "62412b", "765236"])
	MINT = hx(["17391f", "1f4a27", "295e30", "34733a", "418945", "54a051", "6db661", "8ccb78", "b0df98"])
	SAGE = hx(["2c3f33", "3a5141", "4a6450", "5d7962", "738f76", "8ca68c", "a8bea4"])
	LAV = hx(["2a1c4c", "3a2a66", "4c3a82", "5f4d9e", "7462b8", "8d7ccc", "a898dc", "c6b8ec", "e2d8f8"])
	NETTLE = hx(["11291a", "183622", "20452b", "2a5735", "356a40", "447e4c", "56935c"])
	SKIN = hx(["b8765a", "d4936f", "e8b08a", "f5c9a6", "fcdcc0", "ffeedd"])
	HAIR = hx(["4a1f14", "66291a", "843822", "a2492c", "bf5f38", "d67c4e"])
	CLOAK = hx(["17301f", "1f4129", "285334", "33663f", "40794b", "508d58", "64a268", "7db67c"])
	TUNIC = hx(["8f7650", "ab9168", "c6ad84", "dcc7a0", "eddcbc"])
	LEATHER = hx(["3a2216", "51311f", "6a4128", "835333", "9c6740", "b47e52"])
	ORANGE = hx(["6e2e14", "8e401c", "ae5626", "c86c32", "de8642", "eca25c", "f5bf82", "fbd9ae"])
	CREAM = hx(["b8a896", "d2c4b2", "e6dccc", "f4ede2", "fffaf2"])
	GLASS = hx(["9e5418", "c06e22", "dc8c30", "efaa44", "fcc660", "ffdc8a", "ffeeb8", "fff8e4"])
	IVY = hx(["15301c", "1d4226", "275631", "336b3c", "418048", "549657", "6cab68"])
	IRON = hx(["1e1c22", "2e2b33", "403c46", "56525c", "6e6a74", "8c8892"])
	PORCELAIN = hx(["8e9aa8", "b0bac6", "ccd4dc", "e2e8ee", "f4f7fa", "ffffff"])
	RED = hx(["5a1a22", "7a2430", "9c3240", "bc4652", "d65e68", "e8828a", "f4aab0"])
	GOLD = hx(["6a4a14", "8e661c", "b28828", "d0a83a", "e6c458", "f6e08a"])


# ================================================================== помощники

func new_img(w: int, h: int) -> Image:
	return Image.create_empty(w, h, false, Image.FORMAT_RGBA8)


func px(im: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < im.get_width() and y < im.get_height():
		im.set_pixel(x, y, c)


func bl(im: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < im.get_width() and y < im.get_height():
		var d: Color = im.get_pixel(x, y)
		if d.a < 0.01:
			return
		var r: Color = d.blend(c)
		r.a = d.a
		im.set_pixel(x, y, r)


func a_at(im: Image, x: int, y: int) -> float:
	if x < 0 or y < 0 or x >= im.get_width() or y >= im.get_height():
		return 0.0
	return im.get_pixel(x, y).a


func h01(x: int, y: int, s: int = 0) -> float:
	var n: int = x * 374761393 + y * 668265263 + s * 982451653
	n = (n ^ (n >> 13)) * 1274126177
	n = n ^ (n >> 16)
	return float(n & 0xFFFF) / 65535.0


func rect(im: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	for yy in range(y, y + h):
		for xx in range(x, x + w):
			px(im, xx, yy, c)


func disc(im: Image, cx: float, cy: float, r: float, c: Color) -> void:
	for y in range(int(floor(cy - r)) - 1, int(ceil(cy + r)) + 1):
		for x in range(int(floor(cx - r)) - 1, int(ceil(cx + r)) + 1):
			var dx: float = x + 0.5 - cx
			var dy: float = y + 0.5 - cy
			if dx * dx + dy * dy <= r * r:
				px(im, x, y, c)


func ell(im: Image, cx: float, cy: float, rx: float, ry: float, c: Color) -> void:
	for y in range(int(floor(cy - ry)) - 1, int(ceil(cy + ry)) + 1):
		for x in range(int(floor(cx - rx)) - 1, int(ceil(cx + rx)) + 1):
			var dx: float = (x + 0.5 - cx) / rx
			var dy: float = (y + 0.5 - cy) / ry
			if dx * dx + dy * dy <= 1.0:
				px(im, x, y, c)


func line(im: Image, x0: int, y0: int, x1: int, y1: int, c: Color) -> void:
	var dx: int = absi(x1 - x0)
	var dy: int = -absi(y1 - y0)
	var sx: int = 1 if x0 < x1 else -1
	var sy: int = 1 if y0 < y1 else -1
	var err: int = dx + dy
	var x: int = x0
	var y: int = y0
	var guard: int = 0
	while guard < 4000:
		guard += 1
		px(im, x, y, c)
		if x == x1 and y == y1:
			break
		var e2: int = 2 * err
		if e2 >= dy:
			err += dy
			x += sx
		if e2 <= dx:
			err += dx
			y += sy


func thick_line(im: Image, a: Vector2, b: Vector2, w: float, ramp: Array, v0: float) -> void:
	var mn: Vector2 = Vector2(minf(a.x, b.x) - w, minf(a.y, b.y) - w)
	var mx: Vector2 = Vector2(maxf(a.x, b.x) + w, maxf(a.y, b.y) + w)
	for y in range(int(mn.y), int(mx.y) + 1):
		for x in range(int(mn.x), int(mx.x) + 1):
			var p: Vector2 = Vector2(x + 0.5, y + 0.5)
			var d: float = LAY.seg_dist(p, a, b)
			if d <= w * 0.5:
				var v: float = v0 + 0.15 - d / w * 0.3
				var ab: Vector2 = (b - a).normalized()
				var nrm: Vector2 = Vector2(-ab.y, ab.x)
				var side: float = (p - a).dot(nrm)
				v += -side / w * 0.25
				px(im, x, y, pick(ramp, v, x, y))


## Выбор цвета из палитры: чёткие полосы, без шахматной ряби
func pick(ramp: Array, v: float, x: int, y: int) -> Color:
	var n: int = ramp.size()
	var f: float = clampf(v, 0.0, 0.9999) * float(n - 1)
	var i: int = int(round(f))
	return ramp[clampi(i, 0, n - 1)]


## Обводка цветом соседа (тёмный оттенок с уходом в сиреневый), как в аккуратном пиксель-арте
func outline_auto(im: Image, strength: float = 0.55) -> void:
	var src: Image = im.duplicate()
	var w: int = im.get_width()
	var h: int = im.get_height()
	var tint: Color = Color(0.16, 0.12, 0.24)
	for y in range(h):
		for x in range(w):
			if src.get_pixel(x, y).a > 0.5:
				continue
			var nb: Color = Color(0, 0, 0, 0)
			if y + 1 < h and src.get_pixel(x, y + 1).a > 0.5:
				nb = src.get_pixel(x, y + 1)
			elif x > 0 and src.get_pixel(x - 1, y).a > 0.5:
				nb = src.get_pixel(x - 1, y)
			elif x + 1 < w and src.get_pixel(x + 1, y).a > 0.5:
				nb = src.get_pixel(x + 1, y)
			elif y > 0 and src.get_pixel(x, y - 1).a > 0.5:
				nb = src.get_pixel(x, y - 1)
			if nb.a > 0.5:
				var c: Color = nb.darkened(strength).lerp(tint, 0.35)
				c.a = 1.0
				im.set_pixel(x, y, c)


## Листва комками, как на референсах: каждый комок — плоские полосы
## (тень / основной / свет / блик), волнистый край, тень от передних комков на задние.
## clumps: Vector4(cx, cy, rx, ry), задние раньше. ramp: [обводка, тень, основной, свет, блик]
func clusters(im: Image, clumps: Array, ramp: Array, seed_v: int, leafy: float = 0.10, marks: int = 3, k_lo: float = 5.0, k_hi: float = 8.0) -> void:
	var w: int = im.get_width()
	var h: int = im.get_height()
	var owner: PackedInt32Array = PackedInt32Array()
	owner.resize(w * h)
	owner.fill(-1)
	var tone: PackedByteArray = PackedByteArray()
	tone.resize(w * h)
	for i in range(clumps.size()):
		var c: Vector4 = clumps[i]
		var ph: float = h01(i, seed_v, 3) * TAU
		var k: float = floor(lerpf(k_lo, k_hi, h01(i, seed_v, 4)))
		var big: bool = minf(c.z, c.w) > 9.0
		for y in range(int(c.y - c.w * 1.3) - 2, int(c.y + c.w * 1.3) + 3):
			for x in range(int(c.x - c.z * 1.3) - 2, int(c.x + c.z * 1.3) + 3):
				if x < 0 or y < 0 or x >= w or y >= h:
					continue
				var dx: float = (x + 0.5 - c.x) / c.z
				var dy: float = (y + 0.5 - c.y) / c.w
				var d: float = sqrt(dx * dx + dy * dy)
				var th: float = atan2(dy, dx)
				var edge: float = 1.0 + leafy * sin(th * k + ph) * (0.65 + 0.35 * sin(th * 2.0 + ph * 1.7))
				if d > edge:
					continue
				var idx: int = y * w + x
				owner[idx] = i
				var mx: float = dx + 0.20
				var my: float = dy + 0.30
				var dm: float = sqrt(mx * mx + my * my)
				var lx: float = dx + 0.40
				var ly: float = dy + 0.52
				var dl: float = sqrt(lx * lx + ly * ly)
				var t: int = 1
				if dm < 0.84 * edge:
					t = 2
				if dl < 0.46 * edge:
					t = 3
				if big and dl < 0.16 * edge:
					t = 4
				tone[idx] = t
	# тень от переднего комка на задний (полоска над передним)
	var out_tone: PackedByteArray = tone.duplicate()
	for y in range(h):
		for x in range(w):
			var idx2: int = y * w + x
			var o: int = owner[idx2]
			if o < 0:
				continue
			for k2 in [1, 2]:
				var yy: int = y + int(k2)
				if yy < h:
					var o2: int = owner[yy * w + x]
					if o2 > o:
						out_tone[idx2] = mini(out_tone[idx2], 1)
	# листовые штрихи
	for i in range(clumps.size()):
		var c2: Vector4 = clumps[i]
		if minf(c2.z, c2.w) < 6.0:
			continue
		for m in range(marks):
			var px0: int = int(c2.x + rng.randf_range(-0.6, 0.6) * c2.z)
			var py0: int = int(c2.y + rng.randf_range(-0.3, 0.6) * c2.w)
			for o3 in [Vector2i(0, 0), Vector2i(1, 1), Vector2i(2, 0)]:
				var q: Vector2i = Vector2i(px0, py0) + o3
				if q.x < 0 or q.y < 0 or q.x >= w or q.y >= h:
					continue
				var qi: int = q.y * w + q.x
				if owner[qi] == i and out_tone[qi] == 2:
					out_tone[qi] = 1
				elif owner[qi] == i and out_tone[qi] == 3:
					out_tone[qi] = 2
	for y in range(h):
		for x in range(w):
			var idx3: int = y * w + x
			if owner[idx3] >= 0:
				im.set_pixel(x, y, ramp[out_tone[idx3]])


## Ствол с корнями: тёплый свет слева, сиреневая тень справа
func draw_trunk(im: Image, cx: float, t0: int, base: int, seed_v: int) -> void:
	for side in [-1.0, 1.0]:
		var s: float = float(side)
		for k in range(10):
			var t: float = k / 9.0
			var rxp: float = cx + s * (5.0 + t * 11.0)
			var ryp: float = base - 7.0 + t * 7.0
			var rr: float = 3.6 - t * 2.0
			for y in range(int(ryp - rr) - 1, int(ryp + rr) + 2):
				for x in range(int(rxp - rr) - 1, int(rxp + rr) + 2):
					if Vector2(x + 0.5, y + 0.5).distance_to(Vector2(rxp, ryp)) <= rr:
						var u: float = (x + 0.5 - (rxp - rr)) / (2.0 * rr)
						px(im, x, y, TRUNK[4] if u < 0.35 else (TRUNK[3] if u < 0.7 else TRUNK[2]))
	for y in range(t0, base + 1):
		var t2: float = float(y - t0) / float(base - t0)
		var hw: float = 7.5 + pow(t2, 3.0) * 6.5
		for x in range(int(cx - hw), int(cx + hw) + 1):
			var u2: float = (x + 0.5 - (cx - hw)) / (2.0 * hw)
			var i: int = 5 if u2 < 0.18 else (4 if u2 < 0.45 else (3 if u2 < 0.75 else 2))
			var col: int = x - int(cx)
			if (col == -2 or col == 3 or col == 6) and posmod(y + col * 3, 9) < 6:
				i -= 1
			if y < t0 + 6:
				i = maxi(1, i - 2)
			px(im, x, y, TRUNK[clampi(i, 0, TRUNK.size() - 1)])


func grass_tuft(im: Image, cx: float, base: int, wdt: float) -> void:
	for i in range(int(wdt * 1.2)):
		var x: int = int(cx + rng.randf_range(-wdt, wdt))
		var hgt: int = rng.randi_range(2, 5)
		for k in range(hgt):
			var c: Color = GRASS[7] if k == hgt - 1 else (GRASS[5] if k > 0 else GRASS[3])
			px(im, x, base - k, c)


func outline(im: Image, c: Color) -> void:
	var src: Image = im.duplicate()
	var w: int = im.get_width()
	var h: int = im.get_height()
	for y in range(h):
		for x in range(w):
			if src.get_pixel(x, y).a > 0.5:
				continue
			var hit: bool = false
			if x + 1 < w and src.get_pixel(x + 1, y).a > 0.5:
				hit = true
			elif x > 0 and src.get_pixel(x - 1, y).a > 0.5:
				hit = true
			elif y + 1 < h and src.get_pixel(x, y + 1).a > 0.5:
				hit = true
			elif y > 0 and src.get_pixel(x, y - 1).a > 0.5:
				hit = true
			if hit:
				im.set_pixel(x, y, c)


func shadow(im: Image, cx: float, cy: float, rx: float, ry: float, a: float = 0.3) -> void:
	for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
		for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
			var dx: float = (x + 0.5 - cx) / rx
			var dy: float = (y + 0.5 - cy) / ry
			var d: float = dx * dx + dy * dy
			if d <= 1.0 and a_at(im, x, y) < 0.05:
				var aa: float = (a if d < 0.6 else a * 0.7) * 0.6
				px(im, x, y, Color(0.20, 0.16, 0.32, aa))


func save(im: Image, name: String, show: bool = true) -> void:
	im.save_png(OUT + name + ".png")
	if show:
		preview_items.append([name, im])


## Шар/эллипс с объёмным светом
func ball(im: Image, cx: float, cy: float, rx: float, ry: float, ramp: Array, bias: float = 0.0, rough: float = 0.0, seed_v: int = 0) -> void:
	for y in range(int(floor(cy - ry)) - 1, int(ceil(cy + ry)) + 1):
		for x in range(int(floor(cx - rx)) - 1, int(ceil(cx + rx)) + 1):
			var nx: float = (x + 0.5 - cx) / rx
			var ny: float = (y + 0.5 - cy) / ry
			var d2: float = nx * nx + ny * ny
			if d2 > 1.0:
				continue
			var nv: Vector3 = Vector3(nx, ny, sqrt(1.0 - d2)).normalized()
			var v: float = 0.02 + maxf(0.0, nv.dot(LT)) * 1.0 + bias
			if rough > 0.0:
				v += (h01(x, y, seed_v) - 0.5) * rough
			px(im, x, y, pick(ramp, v, x, y))


## Объёмная листва по карте высот: круги (x, y, r) + мелкие бугорки-листья
func canopy(im: Image, circles: Array, ramp: Array, bumps: int, bump_r: Vector2, bias: float = 0.0, depth_k: float = 0.35, seed_v: int = 1) -> void:
	var w: int = im.get_width()
	var h: int = im.get_height()
	var hf: PackedFloat32Array = PackedFloat32Array()
	hf.resize(w * h)
	hf.fill(-1.0)
	var top: float = 1e9
	var bot: float = -1e9
	for c in circles:
		var cv: Vector3 = c
		top = minf(top, cv.y - cv.z)
		bot = maxf(bot, cv.y + cv.z)
		for y in range(int(cv.y - cv.z) - 1, int(cv.y + cv.z) + 2):
			for x in range(int(cv.x - cv.z) - 1, int(cv.x + cv.z) + 2):
				if x < 0 or y < 0 or x >= w or y >= h:
					continue
				var dx: float = x + 0.5 - cv.x
				var dy: float = y + 0.5 - cv.y
				var d2: float = dx * dx + dy * dy
				if d2 <= cv.z * cv.z:
					var z: float = sqrt(cv.z * cv.z - d2) + cv.y * depth_k
					var idx: int = y * w + x
					if z > hf[idx]:
						hf[idx] = z
	# бугорки-листья
	var placed: int = 0
	var tries: int = 0
	while placed < bumps and tries < bumps * 30:
		tries += 1
		var bx: int = rng.randi_range(0, w - 1)
		var by: int = rng.randi_range(0, h - 1)
		var bi: int = by * w + bx
		if hf[bi] < 0.0:
			continue
		placed += 1
		var rb: float = rng.randf_range(bump_r.x, bump_r.y)
		var base: float = hf[bi] - rb * 0.45
		for y in range(int(by - rb) - 1, int(by + rb) + 2):
			for x in range(int(bx - rb) - 1, int(bx + rb) + 2):
				if x < 0 or y < 0 or x >= w or y >= h:
					continue
				var i2: int = y * w + x
				if hf[i2] < 0.0:
					continue
				var dx2: float = x + 0.5 - bx
				var dy2: float = y + 0.5 - by
				var dd: float = dx2 * dx2 + dy2 * dy2
				if dd <= rb * rb:
					var z2: float = base + sqrt(rb * rb - dd) * 0.95
					if z2 > hf[i2]:
						hf[i2] = z2
	# свет
	for y in range(h):
		for x in range(w):
			var i: int = y * w + x
			var z: float = hf[i]
			if z < 0.0:
				continue
			var zl: float = hf[i - 1] if x > 0 and hf[i - 1] >= 0.0 else z - 2.2
			var zr: float = hf[i + 1] if x < w - 1 and hf[i + 1] >= 0.0 else z - 2.2
			var zu: float = hf[i - w] if y > 0 and hf[i - w] >= 0.0 else z - 2.2
			var zd: float = hf[i + w] if y < h - 1 and hf[i + w] >= 0.0 else z - 2.2
			var crease: float = 0.0
			if zu - z > 2.2:
				crease += 0.30
			if zl - z > 2.2:
				crease += 0.16
			if zr - z > 2.2:
				crease += 0.08
			if zd - z > 2.2:
				crease += 0.10
			var dzdx: float = clampf((zr - zl) * 0.5, -2.4, 2.4)
			var dzdy: float = clampf((zd - zu) * 0.5, -2.4, 2.4)
			var nv: Vector3 = Vector3(-dzdx, -dzdy, 1.0).normalized()
			var dif: float = maxf(0.0, nv.dot(LT))
			var v: float = -0.10 + dif * 1.02 + 0.20 * (1.0 - (y - top) / maxf(1.0, bot - top)) - crease + bias
			var r: float = h01(x, y, seed_v)
			if r < 0.05:
				v -= 0.10
			elif r > 0.96:
				v += 0.08
			px(im, x, y, pick(ramp, v, x, y))


## Камень-блок со скосом
func stone_block(im: Image, x: int, y: int, w: int, h: int, ramp: Array, tone: float, seed_v: int = 0) -> void:
	for yy in range(y, y + h):
		for xx in range(x, x + w):
			var corner: bool = (xx == x or xx == x + w - 1) and (yy == y or yy == y + h - 1)
			if corner:
				continue
			var v: float = tone + (h01(xx, yy, seed_v) - 0.5) * 0.10
			if yy == y or xx == x:
				v += 0.20
			elif yy == y + h - 1 or xx == x + w - 1:
				v -= 0.24
			elif yy == y + 1 and xx > x + 1:
				v += 0.07
			px(im, xx, yy, pick(ramp, v, xx, yy))


## Кладка из отдельных камней
func stone_wall(im: Image, r: Rect2i, ramp: Array, bh: int, bw_min: int, bw_max: int, mortar: Color, tone: float = 0.5) -> void:
	rect(im, r.position.x, r.position.y, r.size.x, r.size.y, mortar)
	var y: int = r.position.y
	var row: int = 0
	while y < r.end.y:
		var x: int = r.position.x - (rng.randi_range(0, bw_min) if row % 2 == 1 else 0)
		var hh: int = mini(bh, r.end.y - y)
		while x < r.end.x:
			var bw: int = rng.randi_range(bw_min, bw_max)
			var x0: int = maxi(x, r.position.x)
			var x1: int = mini(x + bw, r.end.x)
			if x1 - x0 >= 3:
				stone_block(im, x0, y, x1 - x0 - 1, hh - 1, ramp, tone + rng.randf_range(-0.13, 0.13), row * 31 + x)
			x += bw
		y += bh
		row += 1


## Доски с волокнами
func planks(im: Image, x: int, y: int, w: int, h: int, ramp: Array, vertical: bool, pw: int, tone: float, seed_v: int = 0) -> void:
	var across_len: int = w if vertical else h
	var along_len: int = h if vertical else w
	var n: int = int(ceil(float(across_len) / float(pw)))
	for k in range(n):
		var ptone: float = tone + (h01(k, seed_v, 5) - 0.5) * 0.16
		var g1: int = int(h01(k, seed_v, 7) * (pw - 2)) + 1
		var knot: int = int(h01(k, seed_v, 9) * along_len)
		for a in range(along_len):
			for c in range(pw):
				var ac: int = k * pw + c
				if ac >= across_len:
					continue
				var xx: int = x + (ac if vertical else a)
				var yy: int = y + (a if vertical else ac)
				var v: float = ptone
				if c == 0:
					v += 0.16
				elif c == pw - 1:
					v -= 0.30
				if c == g1 and h01(a / 3, k, seed_v) > 0.35:
					v -= 0.12
				v += sin(a * 0.21 + k * 2.1) * 0.035
				if absi(a - knot) <= 1 and absi(c - pw / 2) <= 1 and pw >= 5:
					v -= 0.22
				px(im, xx, yy, pick(ramp, v, xx, yy))


## Лист плюща 5 пикселей
func ivy_leaf(im: Image, x: int, y: int, tone: float) -> void:
	px(im, x, y - 1, pick(IVY, tone + 0.25, x, y - 1))
	px(im, x - 1, y, pick(IVY, tone + 0.15, x - 1, y))
	px(im, x, y, pick(IVY, tone + 0.05, x, y))
	px(im, x + 1, y, pick(IVY, tone - 0.1, x + 1, y))
	px(im, x, y + 1, pick(IVY, tone - 0.25, x, y + 1))


func draw_ivy(im: Image, x: int, y: int, height: int, spread: float = 1.0) -> void:
	var cx: float = float(x)
	for i in range(height):
		var yy: int = y - i
		cx += rng.randf_range(-0.6, 0.6) * spread
		px(im, int(cx), yy, IVY[0])
		if i % 2 == 0 and rng.randf() < 0.8:
			var side: int = -1 if (i / 2) % 2 == 0 else 1
			ivy_leaf(im, int(cx) + side * rng.randi_range(2, 3), yy, rng.randf_range(0.35, 0.7))
		if rng.randf() < 0.12:
			var bx: float = cx
			var dirx: int = -1 if rng.randf() < 0.5 else 1
			for j in range(rng.randi_range(4, 9)):
				bx += dirx * 0.8
				px(im, int(bx), yy - j / 2, IVY[1])
				if j % 2 == 1:
					ivy_leaf(im, int(bx), yy - j / 2 - 1, rng.randf_range(0.35, 0.7))


## Цветок 5x5: лепестки + серединка
func flower5(im: Image, x: int, y: int, petals: Array, center: Color) -> void:
	px(im, x, y - 2, petals[2])
	px(im, x - 1, y - 1, petals[2])
	px(im, x + 1, y - 1, petals[1])
	px(im, x - 2, y, petals[2])
	px(im, x + 2, y, petals[1])
	px(im, x - 1, y + 1, petals[1])
	px(im, x + 1, y + 1, petals[0])
	px(im, x, y + 2, petals[0])
	px(im, x, y - 1, petals[2])
	px(im, x - 1, y, petals[1])
	px(im, x + 1, y, petals[1])
	px(im, x, y + 1, petals[0])
	px(im, x, y, center)


func flower3(im: Image, x: int, y: int, petals: Array, center: Color) -> void:
	px(im, x, y - 1, petals[2])
	px(im, x - 1, y, petals[1])
	px(im, x + 1, y, petals[1])
	px(im, x, y + 1, petals[0])
	px(im, x, y, center)


# ================================================================== земля

func gen_ground() -> void:
	rng.seed = 1
	var w: int = LAY.W
	var h: int = LAY.H
	var im: Image = new_img(w, h)
	var nz: FastNoiseLite = FastNoiseLite.new()
	nz.seed = 3
	nz.frequency = 0.0045
	nz.fractal_octaves = 3
	var nz2: FastNoiseLite = FastNoiseLite.new()
	nz2.seed = 9
	nz2.frequency = 0.04
	var nz3: FastNoiseLite = FastNoiseLite.new()
	nz3.seed = 13
	nz3.frequency = 0.16
	var kinds: PackedByteArray = PackedByteArray()
	kinds.resize(w * h)
	for y in range(h):
		for x in range(w):
			var p: Vector2 = Vector2(x + 0.5, y + 0.5)
			var qv: float = LAY.pond_value(p)
			var c: Color
			var kind: int = 0
			if qv < 0.0:
				kind = 2
				var d: float = clampf(-qv / 0.8, 0.0, 1.0)
				var v: float = 0.80 - d * 0.66 + nz2.get_noise_2d(x, y) * 0.05
				if -qv < 0.016:
					v = 0.10
				elif -qv < 0.05:
					v += 0.22
				v += (1.0 - (p.y - (LAY.POND_C.y - LAY.POND_R.y)) / (LAY.POND_R.y * 2.0)) * 0.08
				c = pick(WATER, v, x, y)
			elif qv < 0.045:
				kind = 3
				c = pick(SAND, 0.18 + nz3.get_noise_2d(x, y) * 0.15, x, y)
			else:
				var pv: float = LAY.path_value(p)
				var n2: float = nz2.get_noise_2d(x, y)
				var n3: float = nz3.get_noise_2d(x, y)
				if pv < 0.0:
					kind = 1
					var v2: float = 0.60 + n2 * 0.10 + n3 * 0.05 + nz.get_noise_2d(x, y) * 0.06
					if pv > -3.0:
						v2 -= 0.34
					elif pv > -6.0:
						v2 -= 0.14
					c = pick(SAND, v2, x, y)
				else:
					var v3: float = 0.52 + nz.get_noise_2d(x, y) * 0.27 + n2 * 0.08 + n3 * 0.04
					if pv < 4.0:
						v3 -= 0.22
					elif pv < 7.0:
						v3 -= 0.08
					if qv < 0.11:
						v3 -= 0.06
					var ed: float = minf(minf(float(x), float(w - x)), minf(float(y) * 1.3, float(h - y)))
					if ed < 300.0:
						v3 -= pow(1.0 - ed / 300.0, 2.0) * 0.22
					if LAY.GARDEN_RECT.grow(8).has_point(p):
						v3 -= 0.06
					c = pick(GRASS, v3, x, y)
			kinds[y * w + x] = kind
			im.set_pixel(x, y, c)
	print("  ground base ok")
	# плоские камни у двери и вдоль тропы
	var flags: Array = []
	for i in range(26):
		var t: float = float(i) / 25.0
		flags.append(Vector2(960 + (14.0 if i % 2 == 0 else -14.0) + rng.randf_range(-3, 3), 420 + t * 760))
	for f in flags:
		var fp: Vector2 = f
		if LAY.path_value(fp) > -8.0:
			continue
		var rx: float = rng.randf_range(9, 13)
		var ry: float = rng.randf_range(5.5, 7.5)
		ell(im, fp.x, fp.y + 1, rx + 1, ry + 1, Color("8f7650"))
		ell(im, fp.x, fp.y, rx + 1, ry + 1, Color("6e5a40"))
		for y in range(int(fp.y - ry) - 1, int(fp.y + ry) + 2):
			for x in range(int(fp.x - rx) - 1, int(fp.x + rx) + 2):
				var dx: float = (x + 0.5 - fp.x) / rx
				var dy: float = (y + 0.5 - fp.y) / ry
				var dd: float = dx * dx + dy * dy
				if dd > 1.0:
					continue
				var v: float = 0.55 - dy * 0.12 - dx * 0.06 + (h01(x, y, 4) - 0.5) * 0.12
				if dd > 0.72 and (dy > 0.2 or dx > 0.5):
					v -= 0.2
				elif dd > 0.72:
					v += 0.12
				px(im, x, y, pick(STONE, v + 0.15, x, y))
	# камешки на тропе
	for i in range(3200):
		var x: int = rng.randi_range(3, w - 4)
		var y: int = rng.randi_range(3, h - 4)
		if kinds[y * w + x] != 1 or LAY.path_value(Vector2(x, y)) > -5.0:
			continue
		var r: float = rng.randf()
		if r < 0.55:
			px(im, x, y + 1, SAND[1])
			px(im, x + 1, y + 1, SAND[1])
			px(im, x, y, SAND[4])
			px(im, x + 1, y, SAND[3])
		elif r < 0.85:
			var tone: float = rng.randf_range(0.4, 0.7)
			ell(im, x + 1.5, y + 1.8, 2.6, 1.8, SAND[0])
			ball(im, x + 1.5, y + 1.2, 2.2, 1.6, STONE, tone - 0.25)
		else:
			px(im, x, y, SAND[2])
	# травинки-кустики
	for i in range(30000):
		var x: int = rng.randi_range(3, w - 4)
		var y: int = rng.randi_range(3, h - 4)
		if kinds[y * w + x] != 0:
			continue
		var base: Color = im.get_pixel(x, y)
		var hi: Color = base.lightened(0.15)
		var hi2: Color = base.lightened(0.28)
		var lo: Color = base.darkened(0.18)
		var t: int = rng.randi_range(0, 4)
		match t:
			0:
				px(im, x, y, hi2)
				px(im, x, y + 1, hi)
				px(im, x, y + 2, base)
				px(im, x - 1, y + 1, hi)
				px(im, x - 2, y, hi)
				px(im, x + 1, y + 1, hi)
				px(im, x + 2, y + 1, hi)
				px(im, x, y + 3, lo)
				px(im, x - 1, y + 3, lo)
				px(im, x + 1, y + 3, lo)
			1:
				px(im, x, y, hi)
				px(im, x, y + 1, hi)
				px(im, x + 1, y + 2, hi)
				px(im, x + 1, y + 3, lo)
			2:
				px(im, x, y, hi2)
				px(im, x + 1, y + 1, hi)
				px(im, x - 1, y + 1, hi)
				px(im, x, y + 2, lo)
			3:
				px(im, x, y, lo)
				px(im, x + 1, y, lo)
			_:
				px(im, x, y, hi)
				px(im, x - 1, y - 1, hi2)
				px(im, x + 1, y - 2, hi)
				px(im, x, y + 1, lo)
	# клевер
	for i in range(900):
		var x: int = rng.randi_range(4, w - 5)
		var y: int = rng.randi_range(4, h - 5)
		if kinds[y * w + x] != 0 or LAY.path_value(Vector2(x, y)) < 6.0:
			continue
		var base2: Color = im.get_pixel(x, y)
		for o in [Vector2i(0, -1), Vector2i(-1, 1), Vector2i(1, 1)]:
			var op: Vector2i = o
			px(im, x + op.x * 2, y + op.y * 2, base2.darkened(0.12))
			px(im, x + op.x * 2 + 1, y + op.y * 2, base2.lightened(0.10))
			px(im, x + op.x * 2, y + op.y * 2 + 1, base2.darkened(0.22))
			px(im, x + op.x * 2 + 1, y + op.y * 2 + 1, base2.darkened(0.08))
	# цветочки в траве
	var fsets: Array = [hx(["d8d0c0", "f6f0e4", "ffffff"]), hx(["d87a98", "f2a2bc", "fcd2e0"]), hx(["7a86d8", "a0b0f0", "d0d8fc"]), hx(["d8a02a", "f2cc48", "fff0a0"]), hx(["a88ad8", "c6b0ee", "e6dcfa"])]
	for i in range(2200):
		var x: int = rng.randi_range(4, w - 5)
		var y: int = rng.randi_range(4, h - 5)
		if kinds[y * w + x] != 0:
			continue
		var ed2: float = minf(minf(float(x), float(w - x)), minf(float(y), float(h - y)))
		if ed2 < 130.0 or LAY.path_value(Vector2(x, y)) < 8.0:
			continue
		var fs: Array = fsets[rng.randi_range(0, fsets.size() - 1)]
		px(im, x, y + 2, im.get_pixel(x, y + 2).darkened(0.25))
		if rng.randf() < 0.35:
			flower5(im, x, y, fs, Color("f6d24a") if fs != fsets[3] else Color("c8742a"))
		else:
			flower3(im, x, y, fs, Color("f6d24a") if fs != fsets[3] else Color("c8742a"))
	# опавшие листья у кромки леса
	var lcols: Array = hx(["c86c32", "de9a42", "e8be56", "a84a2a"])
	for i in range(700):
		var x: int = rng.randi_range(4, w - 5)
		var y: int = rng.randi_range(4, h - 5)
		var ed3: float = minf(minf(float(x), float(w - x)), minf(float(y), float(h - y)))
		if ed3 > 260.0 or kinds[y * w + x] > 1:
			continue
		var lc: Color = lcols[rng.randi_range(0, 3)]
		px(im, x, y, lc)
		px(im, x + 1, y, lc.darkened(0.2))
		px(im, x, y + 1, lc.darkened(0.35))
	# травка нависает над краем тропы
	for i in range(9000):
		var x: int = rng.randi_range(3, w - 4)
		var y: int = rng.randi_range(3, h - 4)
		var pv2: float = LAY.path_value(Vector2(x, y))
		if pv2 > 2.0 or pv2 < -3.0 or kinds[y * w + x] > 1:
			continue
		var g: Color = GRASS[rng.randi_range(3, 5)]
		px(im, x, y, g)
		px(im, x, y - 1, g.lightened(0.15))
		px(im, x + 1, y + 1, g.darkened(0.15))
	# берег: камни по кругу пруда
	var ang2: float = 0.0
	while ang2 < TAU:
		var wob: float = sin(ang2 * 3.0 + 0.6) * 0.07 + sin(ang2 * 5.0 + 2.0) * 0.04
		var rr: float = 1.0 + wob + 0.025
		var bp: Vector2 = LAY.POND_C + Vector2(cos(ang2) * LAY.POND_R.x * rr, sin(ang2) * LAY.POND_R.y * rr)
		var reeds: bool = (ang2 > 2.6 and ang2 < 3.5) or (ang2 > 5.3 and ang2 < 5.9) or (ang2 > 0.9 and ang2 < 1.25)
		if reeds:
			draw_reeds(im, bp + Vector2(0, -2))
		elif rng.randf() < 0.82:
			var r3: float = rng.randf_range(3.0, 7.0)
			ell(im, bp.x + 0.5, bp.y + 1.5, r3 + 1.2, r3 * 0.72 + 1.2, OUT_STONE)
			ball(im, bp.x, bp.y, r3, r3 * 0.72, STONE, rng.randf_range(0.0, 0.25), 0.15, int(ang2 * 100))
			if rng.randf() < 0.4:
				for k in range(int(r3)):
					px(im, int(bp.x - r3 * 0.4) + k, int(bp.y - r3 * 0.6), MOSS[3] if k % 2 == 0 else MOSS[2])
		ang2 += rng.randf_range(0.025, 0.05)
	# кувшинки
	var lily: Array = hx(["1f4a27", "295e30", "34733a", "418945", "54a051", "6db661", "8ccb78"])
	var lilies: Array = [Vector2(420, 820), Vector2(472, 902), Vector2(572, 838), Vector2(392, 898), Vector2(600, 904), Vector2(524, 792), Vector2(660, 870), Vector2(350, 850)]
	for k in range(lilies.size()):
		var lp: Vector2 = lilies[k]
		var r4: float = 12.0 if k % 3 == 0 else (9.5 if k % 3 == 1 else 7.5)
		var notch: float = rng.randf() * TAU
		ell(im, lp.x + 1, lp.y + 2, r4 + 1, r4 * 0.62 + 1, WATER[0])
		for y in range(int(lp.y - r4) - 1, int(lp.y + r4) + 2):
			for x in range(int(lp.x - r4) - 1, int(lp.x + r4) + 2):
				var dx: float = x + 0.5 - lp.x
				var dy: float = (y + 0.5 - lp.y) / 0.62
				var dd: float = sqrt(dx * dx + dy * dy)
				if dd > r4:
					continue
				var a: float = atan2(dy, dx)
				if absf(wrapf(a - notch, -PI, PI)) < 0.28:
					continue
				var v: float = 0.58 - dy / r4 * 0.2 - dx / r4 * 0.12
				if dd > r4 - 1.2:
					v -= 0.25
				elif dd > r4 - 2.4 and dy < 0.0:
					v += 0.18
				var vein: float = absf(wrapf(a * 5.0, -PI, PI))
				if vein < 0.22 and dd > 2.0:
					v -= 0.14
				px(im, x, y, pick(lily, v, x, y))
		if k % 2 == 0:
			draw_lotus(im, int(lp.x) - 2, int(lp.y) - 2)
	# блики на воде
	for i in range(420):
		var x: int = rng.randi_range(3, w - 12)
		var y: int = rng.randi_range(3, h - 4)
		if kinds[y * w + x] != 2 or LAY.pond_value(Vector2(x, y)) > -0.12:
			continue
		if im.get_pixel(x, y) == WATER[0] or im.get_pixel(x, y).g < 0.3:
			pass
		var ln: int = rng.randi_range(3, 9)
		for k in range(ln):
			var c2: Color = WATER[7] if k > 0 and k < ln - 1 else WATER[6]
			px(im, x + k, y, c2)
	# края двора растворяются: за ними начинается земля большого мира (рисуется под двором)
	for y in range(h):
		for x in range(w):
			var ed4: float = minf(minf(float(x), float(w - 1 - x)), minf(float(y), float(h - 1 - y)))
			if ed4 < 48.0 and h01(x / 2, y / 2, 99) * 0.85 + 0.15 > ed4 / 48.0:
				im.set_pixel(x, y, Color(0, 0, 0, 0))
	save(im, "ground", false)
	print("  ground ok")


func draw_reeds(im: Image, base: Vector2) -> void:
	var greens: Array = hx(["2a5735", "356a40", "447e4c", "5a9a58", "78b468"])
	for i in range(5):
		var x: float = base.x + rng.randf_range(-7, 7)
		var hgt: int = rng.randi_range(10, 24)
		var lean: float = rng.randf_range(-0.25, 0.25)
		for k in range(hgt):
			var xx: int = int(x + lean * k)
			var yy: int = int(base.y) - k
			px(im, xx, yy, greens[mini(4, 1 + k * 4 / hgt)])
			if k < 3:
				px(im, xx + 1, yy, greens[0])
		if rng.randf() < 0.45:
			var tx: int = int(x + lean * hgt)
			var ty: int = int(base.y) - hgt
			for k in range(5):
				px(im, tx, ty + k, Color("6a3a1e") if k > 0 else Color("8a5530"))
				px(im, tx + 1, ty + k, Color("4a2814"))
			px(im, tx, ty - 1, greens[3])


func draw_lotus(im: Image, x: int, y: int) -> void:
	var pk: Array = hx(["c25a7a", "e07a9a", "f2a6c0", "fcd6e4"])
	px(im, x - 3, y + 1, pk[1])
	px(im, x - 2, y + 1, pk[2])
	px(im, x + 3, y + 1, pk[0])
	px(im, x + 2, y + 1, pk[1])
	px(im, x - 2, y, pk[2])
	px(im, x + 2, y, pk[1])
	px(im, x - 1, y - 1, pk[3])
	px(im, x + 1, y - 1, pk[2])
	px(im, x, y - 2, pk[3])
	px(im, x - 1, y, pk[3])
	px(im, x + 1, y, pk[2])
	px(im, x, y - 1, pk[3])
	px(im, x, y, Color("f6d24a"))
	px(im, x - 1, y + 1, pk[1])
	px(im, x, y + 1, pk[0])
	px(im, x + 1, y + 1, pk[1])


# ================================================================== деревья и кусты (комками)

const TREE_LAYOUT: Array = [
	[0.0, -0.66, 0.50, 0.44], [-0.50, -0.30, 0.50, 0.44], [0.50, -0.34, 0.50, 0.44],
	[0.0, -0.10, 0.58, 0.48], [-0.72, 0.18, 0.42, 0.38], [0.72, 0.16, 0.42, 0.38],
	[-0.34, 0.34, 0.50, 0.40], [0.36, 0.36, 0.50, 0.40],
]


func gen_tree2(name: String, seed_v: int, w: int, h: int, leaf: Array, extra: String = "") -> void:
	rng.seed = seed_v
	var im: Image = new_img(w, h)
	var cx: float = w / 2.0
	var base: int = h - 8
	draw_trunk(im, cx, int(h * 0.58), base, seed_v)
	grass_tuft(im, cx, base + 1, 16.0)
	var R: float = w * 0.40
	var ccy: float = h * 0.47
	var cl: Array = []
	for L in TREE_LAYOUT:
		var a: Array = L
		cl.append(Vector4(cx + float(a[0]) * R + rng.randf_range(-2, 2), ccy + float(a[1]) * R + rng.randf_range(-2, 2), float(a[2]) * R * rng.randf_range(0.92, 1.06), float(a[3]) * R * rng.randf_range(0.92, 1.06)))
	cl.sort_custom(func(p: Vector4, q: Vector4) -> bool: return p.y < q.y)
	clusters(im, cl, leaf, seed_v, 0.09, 3)
	if extra == "apples":
		for i in range(11):
			var ax: int = int(cx + rng.randf_range(-R * 0.9, R * 0.9))
			var ay: int = int(ccy + rng.randf_range(-R * 0.6, R * 0.55))
			if a_at(im, ax, ay) > 0.5 and a_at(im, ax - 3, ay) > 0.5 and a_at(im, ax + 3, ay) > 0.5:
				disc(im, ax, ay, 2.6, Color("c84650"))
				px(im, ax - 1, ay - 1, Color("f4a0a0"))
				px(im, ax + 1, ay + 1, Color("8e2e40"))
				px(im, ax, ay - 3, Color("5a3a2a"))
	elif extra == "blossom":
		for i in range(40):
			var bx: int = int(cx + rng.randf_range(-R * 1.1, R * 1.1))
			var by: int = int(ccy + rng.randf_range(-R * 0.9, R * 0.7))
			if a_at(im, bx, by) > 0.5 and im.get_pixel(bx, by) != leaf[0]:
				px(im, bx, by, Color("fffafc"))
		for i in range(14):
			var fx: int = int(cx + rng.randf_range(-R * 1.2, R * 1.2))
			var fy: int = base + rng.randi_range(-3, 2)
			if a_at(im, fx, fy) < 0.1:
				px(im, fx, fy, leaf[3])
				px(im, fx + 1, fy, leaf[2])
	outline_auto(im)
	shadow(im, cx + 2.0, base + 2.0, w * 0.34, 5.0, 0.16)
	save(im, name)


func gen_pine2(name: String, seed_v: int, w: int, h: int) -> void:
	rng.seed = seed_v
	var im: Image = new_img(w, h)
	var cx: float = w / 2.0
	var base: int = h - 7
	draw_trunk(im, cx, h - 46, base, seed_v)
	grass_tuft(im, cx, base + 1, 12.0)
	var tiers: int = 6
	var cl: Array = []
	for t in range(tiers):
		var ty: float = 16.0 + t * (h - 64.0) / (tiers - 1)
		var W: float = 9.0 + t * (w * 0.40 - 9.0) / (tiers - 1)
		var H: float = 11.0 + t * 1.6
		cl.append(Vector4(cx - W * 0.42, ty + 2.0, W * 0.62, H * 0.55))
		cl.append(Vector4(cx + W * 0.42, ty + 3.0, W * 0.62, H * 0.55))
		cl.append(Vector4(cx, ty, W * 0.58, H * 0.62))
	clusters(im, cl, PINE5, seed_v, 0.20, 1, 9.0, 13.0)
	# макушка
	for k in range(6):
		px(im, int(cx), 6 + k, PINE5[3] if k < 3 else PINE5[2])
		if k > 2:
			px(im, int(cx) - 1, 6 + k, PINE5[2])
			px(im, int(cx) + 1, 6 + k, PINE5[1])
	outline_auto(im)
	shadow(im, cx + 2.0, base + 2.0, w * 0.38, 4.0, 0.16)
	save(im, name)


func gen_bush2(name: String, seed_v: int, flowers: int) -> void:
	rng.seed = seed_v
	var im: Image = new_img(60, 48)
	var cx: float = 30.0
	var cy: float = 27.0
	var R: float = 20.0
	var lay: Array = [[0.0, -0.42, 0.40, 0.36], [-0.45, -0.18, 0.38, 0.34], [0.45, -0.20, 0.38, 0.34], [-0.78, 0.14, 0.32, 0.30], [0.78, 0.12, 0.32, 0.30], [0.0, -0.02, 0.42, 0.36], [-0.38, 0.30, 0.38, 0.32], [0.36, 0.32, 0.38, 0.32]]
	var cl: Array = []
	for L in lay:
		var a: Array = L
		cl.append(Vector4(cx + float(a[0]) * R + rng.randf_range(-1, 1), cy + float(a[1]) * R, float(a[2]) * R, float(a[3]) * R))
	cl.sort_custom(func(p: Vector4, q: Vector4) -> bool: return p.y < q.y)
	clusters(im, cl, BUSH5, seed_v, 0.16, 2, 6.0, 9.0)
	if flowers > 0:
		var fs: Array = hx(["c2607e", "eb98b4", "fbd8e4"]) if flowers == 1 else hx(["d8d0d8", "f4f0f2", "ffffff"])
		var cc: Color = Color("f6d86a")
		var n: int = 0
		var tries: int = 0
		while n < 9 and tries < 300:
			tries += 1
			var x: int = rng.randi_range(8, 52)
			var y: int = rng.randi_range(10, 38)
			if a_at(im, x - 2, y) > 0.5 and a_at(im, x + 2, y) > 0.5 and a_at(im, x, y - 2) > 0.5 and a_at(im, x, y + 2) > 0.5:
				flower5(im, x, y, fs, cc)
				n += 1
	outline_auto(im)
	shadow(im, 31, 44, 24, 3.5, 0.16)
	save(im, name)


func gen_rock2() -> void:
	rng.seed = 44
	var im: Image = new_img(34, 28)
	clusters(im, [Vector4(18, 17, 13, 9.5), Vector4(11, 19, 7.5, 6)], STONE5, 7, 0.03, 0)
	# трещинки
	px(im, 21, 16, STONE5[1])
	px(im, 22, 17, STONE5[1])
	px(im, 22, 18, STONE5[1])
	px(im, 14, 20, STONE5[1])
	px(im, 15, 21, STONE5[1])
	# мох на макушке
	var moss: Image = new_img(34, 28)
	clusters(moss, [Vector4(15, 10, 6, 3.2), Vector4(21, 10, 4, 2.6)], MOSS5, 9, 0.25, 0, 6.0, 9.0)
	for y in range(28):
		for x in range(34):
			if moss.get_pixel(x, y).a > 0.5 and a_at(im, x, y) > 0.5:
				im.set_pixel(x, y, moss.get_pixel(x, y))
	outline_auto(im)
	shadow(im, 19, 25, 14, 2.5, 0.16)
	save(im, "rock")


func gen_tree(name: String, seed_v: int, w: int, h: int, ramp: Array) -> void:
	rng.seed = seed_v
	var im: Image = new_img(w, h)
	var cx: float = w / 2.0
	var base: int = h - 8
	var t0: int = int(h * 0.60)
	# корни
	for side in [-1, 1]:
		var s: float = float(side)
		thick_line(im, Vector2(cx + s * 5, base - 8), Vector2(cx + s * 15, base + 1), 5.0, TRUNK, 0.45 - s * 0.15)
	thick_line(im, Vector2(cx + 2, base - 6), Vector2(cx + 6, base + 2), 4.0, TRUNK, 0.35)
	# ствол
	var nb: FastNoiseLite = FastNoiseLite.new()
	nb.seed = seed_v
	nb.frequency = 0.25
	for y in range(t0, base + 1):
		var t: float = float(y - t0) / float(base - t0)
		var hw: float = 6.5 + pow(t, 3.0) * 6.0
		for x in range(int(cx - hw), int(cx + hw) + 1):
			var u: float = (x + 0.5 - (cx - hw)) / (2.0 * hw)
			var v: float = 0.80 - u * 0.62
			v += (1.0 - absf(u - 0.35) * 2.0) * 0.08
			var bark: float = nb.get_noise_2d(x * 2.2, y * 0.35)
			if bark > 0.35:
				v -= 0.26
			elif bark < -0.5:
				v += 0.10
			if y < t0 + 10:
				v -= (1.0 - float(y - t0) / 10.0) * 0.4
			px(im, x, y, pick(TRUNK, v, x, y))
	# дупло-сучок
	ell(im, cx + 1, t0 + 20, 2.2, 3.0, TRUNK[0])
	px(im, int(cx), t0 + 18, TRUNK[3])
	# крона
	var circles: Array = []
	var ccy: float = h * 0.38
	var rx: float = w * 0.33
	var ry: float = h * 0.23
	circles.append(Vector3(cx, ccy, minf(rx, ry) * 0.95))
	circles.append(Vector3(cx - rx * 0.5, ccy + ry * 0.4, rx * 0.55))
	circles.append(Vector3(cx + rx * 0.5, ccy + ry * 0.4, rx * 0.55))
	for i in range(18):
		var a: float = rng.randf() * TAU
		var d: float = sqrt(rng.randf())
		var rr: float = rng.randf_range(w * 0.11, w * 0.16)
		circles.append(Vector3(cx + cos(a) * d * rx, ccy + sin(a) * d * ry + 4.0, rr))
	circles.sort_custom(func(p: Vector3, q: Vector3) -> bool: return p.y < q.y)
	canopy(im, circles, ramp, int(w * 0.55), Vector2(4.0, 7.5), 0.0, 0.35, seed_v)
	outline(im, OUT_TREE)
	shadow(im, cx + 4.0, base + 2.0, w * 0.40, 6.0, 0.34)
	save(im, name)


func gen_pine(name: String, seed_v: int, w: int, h: int) -> void:
	rng.seed = seed_v
	var im: Image = new_img(w, h)
	var cx: float = w / 2.0
	var base: int = h - 7
	for y in range(base - 24, base + 1):
		for x in range(int(cx) - 4, int(cx) + 5):
			px(im, x, y, pick(TRUNK, 0.75 - (x - cx + 4) * 0.09 - (0.2 if h01(x, y / 3, 3) > 0.7 else 0.0), x, y))
	var tiers: int = 6
	for t in range(tiers):
		var ty: float = 6.0 + t * (h - 42.0) / tiers
		var th: float = 28.0 + t * 3.0
		var tw: float = 10.0 + t * 5.4
		for y in range(int(ty), int(ty + th)):
			var k: float = (y - ty) / th
			var hw: float = tw * pow(k, 0.85) + 1.5
			for x in range(int(cx - hw) - 2, int(cx + hw) + 3):
				var edge: float = absf(x + 0.5 - cx) / hw
				var lower: float = ty + th - (1.0 - edge) * 3.0 - sin(x * 0.9) * 2.0 * edge
				if edge > 1.0 + (0.12 if posmod(y + x, 4) == 0 else 0.0):
					continue
				if y > lower:
					continue
				var u: float = (x - (cx - hw)) / (2.0 * hw)
				var v: float = 0.80 - u * 0.55 - k * 0.22
				if y > lower - 3.0:
					v -= 0.24
				if h01(x + y, y, t) > 0.82:
					v -= 0.12
				if h01(x, y * 2, t + 9) > 0.93:
					v += 0.15
				px(im, x, y, pick(PINE, v, x, y))
	outline(im, OUT_TREE)
	shadow(im, cx + 3.0, base + 2.0, w * 0.42, 5.0, 0.32)
	save(im, name)


func gen_bush(name: String, seed_v: int, flowers: int) -> void:
	rng.seed = seed_v
	var w: int = 58
	var h: int = 46
	var im: Image = new_img(w, h)
	var circles: Array = [Vector3(29, 26, 15), Vector3(18, 30, 11), Vector3(40, 30, 11)]
	for i in range(10):
		circles.append(Vector3(rng.randf_range(12, 46), rng.randf_range(16, 32), rng.randf_range(6.5, 10.0)))
	circles.sort_custom(func(p: Vector3, q: Vector3) -> bool: return p.y < q.y)
	canopy(im, circles, BUSH, 36, Vector2(3.0, 5.0), 0.04, 0.3, seed_v)
	if flowers > 0:
		var fs: Array = hx(["c2506e", "e07a9a", "fcd2e0"]) if flowers == 1 else hx(["d8d0c0", "f6f0e4", "ffffff"])
		var cc: Color = Color("f6d24a") if flowers == 1 else Color("f2c230")
		for i in range(16):
			var x: int = rng.randi_range(8, 50)
			var y: int = rng.randi_range(10, 36)
			if a_at(im, x - 2, y) > 0.5 and a_at(im, x + 2, y) > 0.5 and a_at(im, x, y - 2) > 0.5 and a_at(im, x, y + 2) > 0.5:
				flower5(im, x, y, fs, cc)
	outline(im, OUT_TREE)
	shadow(im, 31, 42, 25, 4.0, 0.32)
	save(im, name)


func gen_flowers() -> void:
	var sets: Array = [
		["flowers_pink", hx(["c2506e", "e07a9a", "fcd2e0"]), Color("f6d24a")],
		["flowers_white", hx(["c8c0b0", "f0eadc", "ffffff"]), Color("f2c230")],
		["flowers_blue", hx(["4a5ac0", "7a8ae6", "c0cafa"]), Color("fff0a0")],
		["flowers_yellow", hx(["c88a1e", "f2c23a", "fff0a0"]), Color("a85a1e")],
	]
	for k in range(sets.size()):
		rng.seed = 100 + k
		var im: Image = new_img(32, 28)
		var cols: Array = sets[k][1]
		var heads: Array = []
		for i in range(7):
			var x: int = rng.randi_range(5, 26)
			var top: int = rng.randi_range(5, 14)
			var lean: float = rng.randf_range(-0.2, 0.2)
			for y in range(top + 2, 26):
				var xx: int = int(x + lean * (26 - y))
				px(im, xx, y, MINT[3] if y % 3 != 0 else MINT[2])
			var lx: int = int(x + lean * 8)
			px(im, lx - 1, top + 10, MINT[5])
			px(im, lx - 2, top + 9, MINT[6])
			px(im, lx + 1, top + 13, MINT[4])
			px(im, lx + 2, top + 12, MINT[5])
			heads.append(Vector2i(int(x + lean * (26 - top)), top))
		# листва у земли
		for i in range(14):
			var x2: int = rng.randi_range(4, 27)
			ivy_leaf(im, x2, rng.randi_range(22, 25), rng.randf_range(0.4, 0.8))
		for hd in heads:
			var hp: Vector2i = hd
			flower5(im, hp.x, hp.y, cols, sets[k][2])
		outline(im, OUT_TREE)
		save(im, String(sets[k][0]))


# ================================================================== дом

func gen_house() -> void:
	rng.seed = 77
	var W: int = 288
	var H: int = 256
	var im: Image = new_img(W, H)
	var cx: int = 144
	var wall_top: int = 124
	var wall_bot: int = 214
	# дымоход
	stone_wall(im, Rect2i(198, 12, 30, 90), STONE, 7, 8, 13, Color("3a3638"), 0.48)
	for x in range(194, 233):
		for y in range(6, 13):
			var v: float = 0.62 - (y - 6) * 0.05 - (x - 194) * 0.004
			if y == 6:
				v += 0.15
			if y == 12:
				v -= 0.3
			px(im, x, y, pick(STONE, v, x, y))
	# стены, штукатурка
	var npl: FastNoiseLite = FastNoiseLite.new()
	npl.seed = 4
	npl.frequency = 0.08
	for y in range(wall_top, wall_bot):
		for x in range(32, 257):
			var v2: float = 0.62 + npl.get_noise_2d(x, y) * 0.10 + (h01(x, y, 2) - 0.5) * 0.06 - (x - 32) * 0.0006
			if y < wall_top + 16:
				v2 -= 0.42 * pow(1.0 - (y - wall_top) / 16.0, 1.4)
			px(im, x, y, pick(PLASTER, v2, x, y))
	# трещинки
	for i in range(7):
		var x0: int = rng.randi_range(104, 186) if i < 3 else rng.randi_range(40, 250)
		var y0: int = rng.randi_range(150, 200)
		for k in range(rng.randi_range(4, 9)):
			px(im, x0, y0, PLASTER[0])
			x0 += rng.randi_range(-1, 1)
			y0 += 1
	# фахверк: стойки
	for bx in [32, 92, 188, 248]:
		planks(im, int(bx), wall_top, 9, wall_bot - wall_top, WOOD, true, 9, 0.42, int(bx))
	planks(im, 32, wall_top, 225, 7, WOOD, false, 7, 0.40, 1)
	planks(im, 32, wall_bot - 8, 225, 8, WOOD, false, 8, 0.38, 2)
	# Андреевские кресты под окнами
	for wx in [62, 226]:
		var x0: float = float(wx) - 20.0
		var x1: float = float(wx) + 20.0
		thick_line(im, Vector2(x0 + 2, wall_bot - 9), Vector2(x1 - 2, 186), 4.5, WOOD, 0.42)
		thick_line(im, Vector2(x1 - 2, wall_bot - 9), Vector2(x0 + 2, 186), 4.5, WOOD, 0.36)
	# раскосы у двери
	thick_line(im, Vector2(101, wall_top + 8), Vector2(118, wall_top + 30), 4.5, WOOD, 0.42)
	thick_line(im, Vector2(187, wall_top + 8), Vector2(170, wall_top + 30), 4.5, WOOD, 0.36)
	# фундамент
	stone_wall(im, Rect2i(26, wall_bot, 237, 20), STONE, 7, 11, 19, Color("39353a"), 0.50)
	# дверь
	draw_door(im, cx, wall_bot)
	# окна
	draw_window(im, 62, 158)
	draw_window(im, 226, 158)
	# крыша
	draw_roof(im, cx)
	# слуховое окно
	draw_dormer(im, cx, 74)
	# плющ
	draw_ivy(im, 35, wall_bot + 4, 74, 1.2)
	draw_ivy(im, 40, wall_bot + 2, 46, 1.0)
	draw_ivy(im, 252, wall_bot + 4, 66, 1.2)
	draw_ivy(im, 118, wall_bot - 2, 30, 0.8)
	draw_ivy(im, 171, wall_bot - 2, 26, 0.8)
	# пучки трав под стрехой
	var bundles: Array = [[106, MINT], [116, LAV], [174, LAV], [184, MINT], [126, SAGE]]
	for b in bundles:
		var bx2: int = int(b[0])
		var ramp: Array = b[1]
		var top: int = 140
		for y in range(top - 6, top + 1):
			px(im, bx2, y, Color("d8c49a"))
		rect(im, bx2 - 1, top + 1, 3, 2, Color("8a5a34"))
		for k in range(14):
			var lx: int = bx2 + rng.randi_range(-3, 3)
			var ly: int = top + 3 + rng.randi_range(0, 10)
			var v: float = 0.75 - (ly - top) * 0.04 - (lx - bx2) * 0.05
			px(im, lx, ly, pick(ramp, v, lx, ly))
			px(im, lx, ly + 1, pick(ramp, v - 0.2, lx, ly + 1))
	outline(im, OUT_WOOD)
	shadow(im, cx + 8, wall_bot + 22, 132, 8, 0.32)
	save(im, "house")
	var big: Image = im.duplicate()
	big.resize(W * 3, H * 3, Image.INTERPOLATE_NEAREST)
	big.save_png(ProjectSettings.globalize_path("res://").path_join("../screenshots/house_zoom.png"))


func draw_door(im: Image, cx: int, wall_bot: int) -> void:
	var acy: float = 172.0
	var r_in: float = 18.0
	var r_out: float = 24.0
	# каменная арка
	for y in range(int(acy - r_out) - 1, wall_bot):
		for x in range(cx - 25, cx + 26):
			var p: Vector2 = Vector2(x + 0.5, y + 0.5)
			var in_arch: bool
			var in_door: bool
			if y < acy:
				var d: float = p.distance_to(Vector2(cx, acy))
				in_arch = d <= r_out
				in_door = d <= r_in
			else:
				in_arch = absf(p.x - cx) <= r_out
				in_door = absf(p.x - cx) <= r_in
			if not in_arch or in_door:
				continue
			var seg: int
			if y < acy:
				var ang: float = atan2(p.y - acy, p.x - cx)
				seg = int(floor((ang + PI) / (PI / 7.0)))
				var frac: float = fposmod((ang + PI) / (PI / 7.0), 1.0)
				if frac < 0.08:
					px(im, x, y, Color("3a3638"))
					continue
			else:
				seg = 20 + int((y - acy) / 9.0)
				if posmod(int(y - acy), 9) == 8:
					px(im, x, y, Color("3a3638"))
					continue
			var tone: float = 0.5 + (h01(seg, 3, 1) - 0.5) * 0.25
			var v: float = tone - (p.x - cx) / r_out * 0.12 + (h01(x, y, 6) - 0.5) * 0.08
			px(im, x, y, pick(STONE, v, x, y))
	# полотно двери
	var x0: int = cx - 18
	var dw: int = 36
	var tmp: Image = new_img(dw, wall_bot - int(acy - r_in))
	planks(tmp, 0, 0, dw, tmp.get_height(), WOOD, true, 6, 0.52, 9)
	for y in range(tmp.get_height()):
		for x in range(dw):
			var p2: Vector2 = Vector2(x0 + x + 0.5, acy - r_in + y + 0.5)
			if p2.y < acy and p2.distance_to(Vector2(cx, acy)) > r_in:
				continue
			var c: Color = tmp.get_pixel(x, y)
			if p2.y < acy + 6 and p2.distance_to(Vector2(cx, acy)) > r_in - 2.0:
				c = c.darkened(0.35)
			px(im, x0 + x, int(acy - r_in) + y, c)
	# железные полосы
	for sy in [180, 202]:
		for x in range(x0 + 1, x0 + 30):
			px(im, x, int(sy), IRON[2])
			px(im, x, int(sy) + 1, IRON[3] if x % 2 == 0 else IRON[2])
			px(im, x, int(sy) + 2, IRON[1])
		for rx in [x0 + 4, x0 + 14, x0 + 24]:
			px(im, int(rx), int(sy) + 1, IRON[5])
	# кольцо-ручка
	for a in range(16):
		var ang2: float = a / 16.0 * TAU
		px(im, int(cx + 10 + cos(ang2) * 2.6), int(192 + sin(ang2) * 2.6), GOLD[2] if a < 8 else GOLD[4])
	px(im, cx + 10, 189, IRON[1])
	# венок из трав
	var wc: Vector2 = Vector2(cx, 165)
	for a in range(28):
		var ang3: float = a / 28.0 * TAU
		var pp: Vector2 = wc + Vector2(cos(ang3), sin(ang3)) * 6.0
		ivy_leaf(im, int(pp.x), int(pp.y), 0.45 + sin(ang3) * -0.2)
	for a in range(5):
		var ang4: float = a / 5.0 * TAU + 0.3
		var pp2: Vector2 = wc + Vector2(cos(ang4), sin(ang4)) * 6.0
		px(im, int(pp2.x), int(pp2.y), RED[4])
		px(im, int(pp2.x) + 1, int(pp2.y), RED[2])
	px(im, int(wc.x) - 1, int(wc.y) + 7, RED[3])
	px(im, int(wc.x) + 1, int(wc.y) + 7, RED[3])
	px(im, int(wc.x), int(wc.y) + 8, RED[2])
	# ступенька
	for y in range(wall_bot + 6, wall_bot + 22):
		for x in range(cx - 30, cx + 31):
			var dx: float = absf(x + 0.5 - cx) / 30.0
			var dy: float = (y - wall_bot - 6) / 16.0
			if dx > 1.0 - pow(dy, 4.0) * 0.1:
				continue
			var v: float = 0.68 - dy * 0.35 + (h01(x, y, 8) - 0.5) * 0.08
			if y == wall_bot + 6:
				v += 0.15
			if y > wall_bot + 18:
				v -= 0.25
			px(im, x, y, pick(STONE, v, x, y))


func draw_window(im: Image, wcx: int, wcy: int) -> void:
	var x0: int = wcx - 20
	var y0: int = wcy - 20
	# рама
	for y in range(y0, y0 + 41):
		for x in range(x0, x0 + 41):
			var edge: int = mini(mini(x - x0, x0 + 40 - x), mini(y - y0, y0 + 40 - y))
			if edge < 4:
				var v: float = 0.55
				if x - x0 < 4 or y - y0 < 4:
					v += 0.12
				else:
					v -= 0.15
				if edge == 0:
					v -= 0.25
				if edge == 3:
					v -= 0.3
				px(im, x, y, pick(WOOD, v + (h01(x, y, 3) - 0.5) * 0.08, x, y))
				continue
			# стекло: тёплый свет
			var gx: float = float(x - x0 - 4) / 32.0
			var gy: float = float(y - y0 - 4) / 32.0
			var v2: float = 0.78 - gx * 0.25 - gy * 0.30
			var diag: float = gx + gy
			if diag > 0.30 and diag < 0.42:
				v2 += 0.25
			if diag > 0.48 and diag < 0.52:
				v2 += 0.18
			var c: Color = pick(GLASS, v2, x, y)
			# занавески
			var lx: int = x - x0 - 4
			var rx: int = x0 + 36 - x
			var ly: int = y - y0 - 4
			var tie_y: int = 20
			var cw: float = 7.0 - absf(float(ly - tie_y)) * 0.0 if ly < tie_y else 7.0 - float(ly - tie_y) * 0.35
			if ly < tie_y:
				cw = 3.0 + float(ly) * 0.0 + float(tie_y - ly) * 0.0 + 4.0 * float(ly) / float(tie_y)
			if lx < int(cw) or rx < int(cw):
				var fold: int = lx if lx < int(cw) else rx
				var cv: float = 0.72 - (0.25 if fold % 3 == 2 else 0.0) - gy * 0.2
				c = pick(CREAM, cv, x, y)
				if ly == tie_y:
					c = RED[3]
			px(im, x, y, c)
	# крест ровно по центру проёма
	for k in range(x0 + 4, x0 + 37):
		px(im, k, wcy - 1, WOOD[4])
		px(im, k, wcy, WOOD[2])
	for k in range(y0 + 4, y0 + 37):
		px(im, wcx - 1, k, WOOD[4])
		px(im, wcx, k, WOOD[2])
	# подоконник и ящик с цветами
	planks(im, x0 - 4, y0 + 41, 49, 3, WOOD, false, 3, 0.62, 11)
	planks(im, x0 - 3, y0 + 46, 47, 9, WOOD, false, 3, 0.45, 12)
	var fl_sets: Array = [hx(["c2506e", "e07a9a", "fcd2e0"]), hx(["d65e68", "e8828a", "f4aab0"]), hx(["c8c0b0", "f0eadc", "ffffff"])]
	for x in range(x0 - 2, x0 + 43):
		var hgt: int = rng.randi_range(2, 5)
		for k in range(hgt):
			px(im, x, y0 + 46 - k, pick(MINT, 0.35 + k * 0.12 + (0.1 if x % 2 == 0 else 0.0), x, y0 + 46 - k))
	for k in range(9):
		var fx: int = x0 + 1 + k * 5 + rng.randi_range(-1, 1)
		flower5(im, fx, y0 + 41 - rng.randi_range(0, 2), fl_sets[k % 3], Color("f6d24a"))
	# свисающие листики
	for k in range(6):
		var tx: int = x0 + rng.randi_range(0, 40)
		for j in range(rng.randi_range(3, 7)):
			px(im, tx, y0 + 47 + j, MINT[3])
			if j % 2 == 1:
				px(im, tx + 1, y0 + 47 + j, MINT[5])


func draw_roof(im: Image, cx: int) -> void:
	var top_y: int = 18
	var eave_y: int = 142
	var nm: FastNoiseLite = FastNoiseLite.new()
	nm.seed = 8
	nm.frequency = 0.035
	var ch: float = 12.0
	for y in range(top_y - 2, eave_y + 8):
		var t: float = float(y - top_y) / float(eave_y - top_y)
		var hw: float = 36.0 + t * 106.0
		if y < top_y + 16:
			hw -= (1.0 - sqrt(clampf(float(y - top_y) / 16.0, 0.0, 1.0))) * 30.0
		for x in range(int(cx - hw), int(cx + hw) + 1):
			var eave: float = eave_y + sin(x * 0.31) * 2.2 + h01(x / 5, 0, 4) * 2.0
			if y > eave or y < top_y:
				continue
			var yy0: float = float(y - top_y)
			var course0: int = int(yy0 / ch)
			var yy: float = yy0 + sin(x * 0.42 + course0 * 1.7) * 2.2
			var course: int = int(floor(yy / ch))
			var ly: float = fposmod(yy, ch)
			var v: float = 0.88 - ly / ch * 0.40
			if ly > ch - 2.6:
				v -= 0.24
			var strand: float = h01(x, course, 11)
			v += (strand - 0.5) * 0.16
			if posmod(x + course * 2, 3) == 0:
				v -= 0.07
			if ly < 1.5 and h01(x, course, 12) > 0.5:
				v += 0.10
			v += (cx - x) / hw * 0.10
			if y > eave - 3.0:
				v -= 0.28
			var moss: float = nm.get_noise_2d(x, y)
			if moss > 0.42 and y > top_y + 20:
				px(im, x, y, pick(MOSS, v - 0.1, x, y))
				continue
			px(im, x, y, pick(THATCH, v, x, y))
	# конёк
	for y in range(top_y - 3, top_y + 9):
		var t2: float = float(y - top_y) / float(eave_y - top_y)
		var hw2: float = 36.0 + t2 * 106.0
		if y < top_y + 16:
			hw2 -= (1.0 - sqrt(clampf(float(y - top_y) / 16.0, 0.0, 1.0))) * 30.0
		for x in range(int(cx - hw2) + 2, int(cx + hw2) - 1):
			var v3: float = 0.58 - float(y - top_y + 3) * 0.03
			if posmod(x + y, 8) < 2:
				v3 -= 0.18
			if y == top_y - 3:
				v3 += 0.2
			if y >= top_y + 7:
				v3 -= 0.28
			px(im, x, y, pick(THATCH, v3, x, y))


func draw_dormer(im: Image, cx: int, cy: int) -> void:
	# соломенная «бровь»
	for y in range(cy - 26, cy + 4):
		for x in range(cx - 27, cx + 28):
			var d: float = Vector2(x + 0.5, y + 0.5).distance_to(Vector2(cx, cy + 2))
			if d > 26.0 or d < 17.0:
				continue
			var v: float = 0.82 - (d - 17.0) / 9.0 * 0.15 + (h01(x, int(d), 2) - 0.5) * 0.18
			if d > 24.5:
				v -= 0.28
			v += (cx - x) / 27.0 * 0.08
			px(im, x, y, pick(THATCH, v, x, y))
	# окно
	for y in range(cy - 17, cy + 18):
		for x in range(cx - 17, cx + 18):
			var d2: float = Vector2(x + 0.5, y + 0.5).distance_to(Vector2(cx, cy))
			if d2 > 16.5:
				continue
			if d2 > 13.0:
				var v2: float = 0.5 - (0.0 if (x < cx and y < cy) else 0.18)
				if d2 > 15.6:
					v2 -= 0.2
				px(im, x, y, pick(WOOD, v2, x, y))
			else:
				var g: float = 0.82 - (x - cx + 13) / 26.0 * 0.28 - (y - cy + 13) / 26.0 * 0.28
				var dg: float = (x - cx + 13) / 26.0 + (y - cy + 13) / 26.0
				if dg > 0.5 and dg < 0.66:
					g += 0.22
				px(im, x, y, pick(GLASS, g, x, y))
	for k in range(cx - 13, cx + 14):
		px(im, k, cy - 1, WOOD[4])
		px(im, k, cy, WOOD[2])
	for k in range(cy - 13, cy + 14):
		px(im, cx - 1, k, WOOD[4])
		px(im, cx, k, WOOD[2])


# ================================================================== предметы

func gen_well() -> void:
	rng.seed = 31
	var im: Image = new_img(76, 100)
	var cx: float = 38.0
	# крыша из дранки
	for y in range(4, 30):
		var t: float = float(y - 4) / 26.0
		var hw: float = 8.0 + t * 28.0
		var row: int = (y - 4) / 5
		for x in range(int(cx - hw), int(cx + hw) + 1):
			var col: int = int((x + (row % 2) * 4) / 8)
			var ly: int = (y - 4) % 5
			var v: float = 0.62 - ly * 0.07 + (h01(col, row, 3) - 0.5) * 0.18 + (cx - x) / hw * 0.08
			if ly == 4:
				v -= 0.25
			if posmod(x + (row % 2) * 4, 8) == 0:
				v -= 0.2
			px(im, x, y, pick(WOOD, v, x, y))
	planks(im, 2, 29, 72, 3, WOOD, false, 3, 0.35, 4)
	# столбы
	planks(im, 10, 32, 6, 34, WOOD, true, 6, 0.5, 5)
	planks(im, 60, 32, 6, 34, WOOD, true, 6, 0.42, 6)
	# ворот с верёвкой
	for x in range(16, 60):
		var v2: float = 0.55
		px(im, x, 38, pick(WOOD, v2 + 0.2, x, 38))
		px(im, x, 39, pick(WOOD, v2, x, 39))
		px(im, x, 40, pick(WOOD, v2 - 0.2, x, 40))
		px(im, x, 41, pick(WOOD, v2 - 0.35, x, 41))
	for x in range(28, 48):
		if x % 2 == 0:
			for y in range(38, 42):
				px(im, x, y, Color("d8c49a") if y < 40 else Color("a89064"))
	for y in range(42, 52):
		px(im, 38, y, Color("c8b48a"))
	# рукоять
	px(im, 66, 39, WOOD[4])
	px(im, 67, 39, WOOD[4])
	for y in range(39, 46):
		px(im, 68, y, WOOD[3])
	# каменный сруб
	stone_wall(im, Rect2i(10, 56, 56, 34), STONE, 6, 7, 12, Color("39353a"), 0.52)
	for y in range(56, 90):
		for x in range(10, 66):
			var u: float = (x + 0.5 - cx) / 28.0
			bl(im, x, y, Color(0, 0, 0, clampf(absf(u) * 0.45 if u > 0.0 else absf(u) * 0.2, 0.0, 0.5)))
	# верхний край
	for y in range(46, 64):
		for x in range(6, 70):
			var dx: float = (x + 0.5 - cx) / 31.0
			var dy: float = (y + 0.5 - 56.0) / 10.0
			var d: float = dx * dx + dy * dy
			if d > 1.0:
				continue
			var dxi: float = (x + 0.5 - cx) / 24.0
			var dyi: float = (y + 0.5 - 55.0) / 6.5
			if dxi * dxi + dyi * dyi < 1.0:
				var wv: float = 0.25 + dyi * 0.18
				if dyi < -0.3 and absf(dxi) < 0.6:
					wv = 0.08
				px(im, x, y, pick(WATER, wv, x, y))
				continue
			var ang: float = atan2(dy, dx)
			var seg: int = int(floor((ang + PI) / (TAU / 16.0)))
			if fposmod((ang + PI) / (TAU / 16.0), 1.0) < 0.1:
				px(im, x, y, Color("39353a"))
				continue
			var v3: float = 0.7 - dy * 0.25 + (h01(seg, 2, 9) - 0.5) * 0.2
			px(im, x, y, pick(STONE, v3, x, y))
	# ведро на краю
	for y in range(50, 62):
		for x in range(50, 61):
			var u2: float = (x - 50) / 10.0
			var v4: float = 0.7 - u2 * 0.4
			if y == 53 or y == 59:
				px(im, x, y, IRON[3] if x % 3 != 0 else IRON[5])
				continue
			if posmod(x - 50, 3) == 2:
				v4 -= 0.15
			px(im, x, y, pick(WOOD, v4, x, y))
	ell(im, 55.5, 50, 5.5, 1.6, WATER[2])
	for x in range(51, 61):
		px(im, x, 48 - int(sin((x - 50) / 10.0 * PI) * 4), IRON[4])
	# мох
	for i in range(30):
		var mx: int = rng.randi_range(12, 64)
		var my: int = rng.randi_range(80, 89)
		px(im, mx, my, MOSS[rng.randi_range(1, 3)])
	outline(im, OUT_DARK)
	shadow(im, cx + 3, 92, 32, 5, 0.32)
	save(im, "well")


func gen_lantern() -> void:
	var im: Image = new_img(32, 86)
	planks(im, 11, 18, 6, 62, WOOD, true, 6, 0.5, 2)
	stone_block(im, 7, 76, 14, 7, STONE, 0.5, 3)
	# кронштейн
	for x in range(11, 26):
		px(im, x, 16, IRON[3])
		px(im, x, 17, IRON[1])
	for k in range(6):
		px(im, 17 + k, 22 - k, IRON[2])
	px(im, 24, 18, IRON[2])
	px(im, 24, 19, IRON[2])
	# фонарь
	for y in range(20, 26):
		var hw: int = (y - 20) + 1
		for x in range(24 - hw, 25 + hw):
			px(im, x, y, pick(IRON, 0.65 - (x - 24 + hw) * 0.06, x, y))
	for y in range(26, 42):
		for x in range(18, 31):
			var edge: bool = x == 18 or x == 30 or x == 24 or y == 26 or y == 41
			if edge:
				px(im, x, y, IRON[2] if x < 24 else IRON[1])
			else:
				var v: float = 0.85 - absf(x - 21.0) * 0.06 - (y - 26) * 0.012
				if x > 24:
					v -= 0.18
				px(im, x, y, pick(GLASS, v, x, y))
	# свеча
	rect(im, 20, 35, 3, 6, CREAM[4])
	px(im, 21, 34, Color("ffffff"))
	px(im, 21, 33, Color("fff2a0"))
	px(im, 21, 32, Color("ffd060"))
	rect(im, 17, 42, 15, 2, IRON[2])
	px(im, 24, 44, IRON[1])
	px(im, 24, 19, GOLD[4])
	outline(im, OUT_DARK)
	shadow(im, 14, 82, 10, 2.5, 0.3)
	save(im, "lantern")


func gen_fence() -> void:
	var im: Image = new_img(32, 40)
	planks(im, 0, 13, 32, 5, WOOD, false, 5, 0.55, 1)
	planks(im, 0, 26, 32, 5, WOOD, false, 5, 0.50, 2)
	for px0 in [3]:
		var x0: int = int(px0)
		planks(im, x0, 6, 7, 30, WOOD, true, 7, 0.58, 3)
		for k in range(4):
			for x in range(x0 + k, x0 + 7 - k):
				px(im, x, 6 - k + (1 if k > 0 else 0) - 1, pick(WOOD, 0.75 - k * 0.05, x, 5 - k))
		px(im, x0 + 3, 15, IRON[4])
		px(im, x0 + 3, 28, IRON[4])
	outline(im, OUT_WOOD)
	save(im, "fence")


func gen_pillar() -> void:
	rng.seed = 12
	var im: Image = new_img(40, 88)
	stone_wall(im, Rect2i(8, 22, 24, 60), STONE, 8, 9, 13, Color("39353a"), 0.55)
	for y in range(22, 82):
		for x in range(8, 32):
			bl(im, x, y, Color(0, 0, 0, clampf((x - 8) / 24.0 * 0.3, 0.0, 0.3)))
	for y in range(13, 22):
		for x in range(3, 37):
			var v: float = 0.72 - (y - 13) * 0.04 - (x - 3) * 0.008
			if y == 13:
				v += 0.15
			if y == 21:
				v -= 0.35
			px(im, x, y, pick(STONE, v, x, y))
	ball(im, 20, 8, 6, 5.5, STONE, 0.1)
	draw_ivy(im, 12, 82, 54, 1.0)
	for i in range(24):
		px(im, rng.randi_range(5, 34), rng.randi_range(13, 15), MOSS[rng.randi_range(1, 4)])
	outline(im, OUT_DARK)
	shadow(im, 22, 84, 18, 3.5, 0.3)
	save(im, "pillar")


func gen_bench() -> void:
	var im: Image = new_img(72, 46)
	planks(im, 6, 3, 60, 12, WOOD, false, 4, 0.52, 1)
	planks(im, 4, 19, 64, 12, WOOD, false, 4, 0.62, 2)
	for lx in [8, 60]:
		planks(im, int(lx), 31, 5, 11, WOOD, true, 5, 0.32, 3)
	for lx in [8, 60]:
		planks(im, int(lx), 0, 5, 19, WOOD, true, 5, 0.44, 4)
	# подушечка
	for y in range(20, 27):
		for x in range(14, 32):
			var v: float = 0.65 - (y - 20) * 0.06 - (x - 14) * 0.01
			px(im, x, y, pick(hx(["4a5a8a", "5a6ca0", "7286b8", "92a4cc"]), v, x, y))
	outline(im, OUT_WOOD)
	shadow(im, 36, 42, 32, 4, 0.28)
	save(im, "bench")


func gen_tea_table() -> void:
	var im: Image = new_img(60, 60)
	# ножка
	for y in range(36, 54):
		for x in range(27, 34):
			px(im, x, y, pick(WOOD, 0.62 - (x - 27) * 0.06, x, y))
	ell(im, 30.5, 54, 10, 3, WOOD[2])
	ell(im, 30, 53.4, 9, 2.2, WOOD[4])
	# столешница
	ell(im, 30, 32, 27, 13.5, WOOD[1])
	for y in range(18, 46):
		for x in range(3, 58):
			var dx: float = (x + 0.5 - 30) / 26.0
			var dy: float = (y + 0.5 - 30) / 12.5
			var d: float = dx * dx + dy * dy
			if d > 1.0:
				continue
			var v: float = 0.62 - dy * 0.12 - dx * 0.08
			var ring: float = sin(sqrt(d) * 22.0)
			if ring > 0.85:
				v -= 0.08
			if d > 0.86:
				v += 0.12 if dy < 0 else -0.15
			px(im, x, y, pick(WOOD, v, x, y))
	# кружевная салфетка
	for y in range(22, 40):
		for x in range(14, 47):
			var dx2: float = (x + 0.5 - 30) / 15.0
			var dy2: float = (y + 0.5 - 30) / 7.5
			var d2: float = sqrt(dx2 * dx2 + dy2 * dy2)
			var ang: float = atan2(dy2, dx2)
			if d2 > 0.92 + sin(ang * 12.0) * 0.08:
				continue
			var lace: Color = CREAM[4]
			if d2 > 0.8:
				lace = CREAM[2] if posmod(int(ang * 12.0 / PI), 2) == 0 else CREAM[3]
			elif absf(d2 - 0.62) < 0.05:
				lace = CREAM[2]
			px(im, x, y, lace)
	# чайник
	ball(im, 24, 22, 9, 8, PORCELAIN, 0.12)
	for a in range(7):
		var fx: int = 18 + a * 2
		px(im, fx, 23 + int(sin(a) * 1.5), Color("4a6ab8"))
		px(im, fx + 1, 22 + int(sin(a) * 1.5), Color("7a9ae0"))
	for y in range(12, 15):
		for x in range(20, 29):
			px(im, x, y, pick(PORCELAIN, 0.8 - (y - 12) * 0.15, x, y))
	ball(im, 24, 11, 2, 1.5, GOLD, 0.2)
	for k in range(6):
		px(im, 14 - k, 20 - k / 2, PORCELAIN[3])
		px(im, 14 - k, 21 - k / 2, PORCELAIN[2])
	for k in range(7):
		var ang2: float = -PI * 0.5 + k / 6.0 * PI
		px(im, int(33 + cos(ang2) * 3.5), int(22 + sin(ang2) * 4.0), PORCELAIN[2])
	# чашки
	for cp in [Vector2(42, 28), Vector2(16, 34)]:
		var c2: Vector2 = cp
		ell(im, c2.x, c2.y + 3, 6, 2.2, PORCELAIN[2])
		for y in range(int(c2.y) - 2, int(c2.y) + 3):
			for x in range(int(c2.x) - 3, int(c2.x) + 4):
				px(im, x, y, pick(PORCELAIN, 0.85 - (x - c2.x + 3) * 0.08, x, y))
		ell(im, c2.x + 0.5, c2.y - 2, 3.5, 1.3, Color("9a5a2a"))
		px(im, int(c2.x) - 1, int(c2.y) - 2, Color("c88a4a"))
		px(im, int(c2.x) + 4, int(c2.y), PORCELAIN[2])
		px(im, int(c2.x) + 5, int(c2.y), PORCELAIN[1])
	# печенье
	ell(im, 38, 38, 7, 2.6, PORCELAIN[3])
	for cc in [Vector2(36, 37), Vector2(40, 38)]:
		var k2: Vector2 = cc
		ball(im, k2.x, k2.y, 2.6, 1.6, hx(["9a6a32", "c08a48", "dcaa66", "ecc890"]), 0.15)
		px(im, int(k2.x), int(k2.y), Color("5a3018"))
	outline(im, OUT_WOOD)
	shadow(im, 31, 56, 22, 4, 0.28)
	save(im, "tea_table")


func gen_barrel() -> void:
	var im: Image = new_img(36, 46)
	for y in range(8, 42):
		var bulge: float = 13.0 + sin((y - 8) / 34.0 * PI) * 2.5
		for x in range(int(18 - bulge), int(18 + bulge)):
			var u: float = (x + 0.5 - (18 - bulge)) / (2.0 * bulge)
			var v: float = 0.85 - u * 0.65 + sin(u * PI) * 0.1
			var stave: int = int(u * 7.0)
			v += (h01(stave, 1, 4) - 0.5) * 0.12
			if fposmod(u * 7.0, 1.0) < 0.12:
				v -= 0.22
			px(im, x, y, pick(WOOD, v, x, y))
		if y in [13, 14, 15, 33, 34, 35]:
			for x in range(int(18 - bulge), int(18 + bulge)):
				var u2: float = (x + 0.5 - (18 - bulge)) / (2.0 * bulge)
				var v2: float = 0.75 - u2 * 0.6 + (0.15 if y == 13 or y == 33 else 0.0) - (0.2 if y == 15 or y == 35 else 0.0)
				px(im, x, y, pick(IRON, v2, x, y))
	for rx in [8, 18, 28]:
		px(im, int(rx), 14, IRON[5])
		px(im, int(rx), 34, IRON[5])
	for y in range(3, 13):
		for x in range(5, 32):
			var dx: float = (x + 0.5 - 18) / 13.0
			var dy: float = (y + 0.5 - 8) / 4.6
			var d: float = dx * dx + dy * dy
			if d > 1.0:
				continue
			var v3: float = 0.6 - dy * 0.1
			if d > 0.7:
				v3 = 0.4 if dy < 0 else 0.25
			elif posmod(x, 5) == 0:
				v3 -= 0.15
			px(im, x, y, pick(WOOD, v3, x, y))
	outline(im, OUT_WOOD)
	shadow(im, 19, 43, 15, 3, 0.28)
	save(im, "barrel")


func gen_sign() -> void:
	var im: Image = new_img(48, 66)
	planks(im, 4, 6, 6, 56, WOOD, true, 6, 0.5, 1)
	planks(im, 4, 6, 40, 5, WOOD, false, 5, 0.55, 2)
	for chx in [17, 37]:
		for y in range(11, 19):
			px(im, int(chx), y, IRON[4] if y % 2 == 0 else IRON[2])
	planks(im, 12, 18, 32, 26, WOOD, false, 6, 0.6, 3)
	for x in range(12, 44):
		px(im, x, 18, WOOD[6])
		px(im, x, 43, WOOD[1])
	for y in range(18, 44):
		px(im, 12, y, WOOD[5])
		px(im, 43, y, WOOD[1])
	# ступка и пестик
	ell(im, 28, 35, 7, 4, LEATHER[0])
	ell(im, 28, 34, 6, 3, Color("5a4a40"))
	ell(im, 28, 33, 5, 1.4, Color("2a1e18"))
	for k in range(9):
		px(im, 30 + k / 2, 31 - k, Color("5a4a40"))
		px(im, 31 + k / 2, 31 - k, Color("3a2e28"))
	# листик
	for k in range(6):
		px(im, 19 + k / 2, 30 - k, MINT[4])
		px(im, 20 + k / 2, 30 - k, MINT[6])
		px(im, 21 + k / 2, 31 - k, MINT[3])
	px(im, 18, 31, MINT[2])
	outline(im, OUT_WOOD)
	shadow(im, 7, 62, 6, 2, 0.3)
	save(im, "sign")


func gen_small_props() -> void:
	# камень
	gen_rock2()
	# грибы
	var m: Image = new_img(28, 24)
	var caps: Array = hx(["5a1418", "7a1e22", "9c2a2c", "bc3a36", "d65448", "e8786a"])
	for g in [[7, 12, 4.5, 20], [18, 9, 6.0, 20], [23, 15, 3.5, 21]]:
		var gx: float = float(g[0])
		var gy: float = float(g[1])
		var r: float = float(g[2])
		var foot: int = int(g[3])
		for y in range(int(gy), foot):
			for x in range(int(gx) - 1, int(gx) + 2):
				px(m, x, y, pick(CREAM, 0.8 - (x - gx + 1) * 0.2, x, y))
		ball(m, gx, gy, r, r * 0.7, caps, 0.1)
		for k in range(3):
			px(m, int(gx - r * 0.4) + k * 2, int(gy - r * 0.3) + (k % 2), CREAM[4])
		px(m, int(gx), int(gy + r * 0.5), caps[0])
	outline(m, OUT_DARK)
	save(m, "mushrooms")
	# пень
	var s: Image = new_img(44, 34)
	thick_line(s, Vector2(8, 26), Vector2(3, 31), 4.0, TRUNK, 0.4)
	thick_line(s, Vector2(36, 26), Vector2(41, 31), 4.0, TRUNK, 0.3)
	for y in range(10, 30):
		for x in range(8, 36):
			var u: float = (x - 8) / 28.0
			var v: float = 0.78 - u * 0.6
			if h01(x, y / 4, 2) > 0.75:
				v -= 0.2
			px(s, x, y, pick(TRUNK, v, x, y))
	for y in range(4, 17):
		for x in range(8, 37):
			var dx: float = (x + 0.5 - 22) / 14.0
			var dy: float = (y + 0.5 - 10) / 5.6
			var d: float = sqrt(dx * dx + dy * dy)
			if d > 1.0:
				continue
			var v2: float = 0.72 - dy * 0.1
			if d > 0.86:
				v2 = 0.45
			elif posmod(int(d * 9.0), 2) == 0:
				v2 -= 0.12
			px(s, x, y, pick(WOOD, v2, x, y))
	ball(s, 33, 22, 3, 2.2, caps, 0.15)
	px(s, 33, 25, CREAM[3])
	outline(s, OUT_WOOD)
	shadow(s, 22, 31, 18, 2.5, 0.3)
	save(s, "stump")


# ================================================================== огород

func gen_plot_beds() -> void:
	for wet in [false, true]:
		rng.seed = 900
		var im: Image = new_img(80, 58)
		var ramp: Array = SOIL_WET if wet else SOIL
		# земля
		for y in range(8, 46):
			for x in range(8, 72):
				var ly: int = posmod(y - 9, 9)
				var v: float = 0.52 + (h01(x, y, 4) - 0.5) * 0.12
				if ly < 2:
					v += 0.20
				elif ly < 4:
					v += 0.08
				elif ly > 6:
					v -= 0.24
				px(im, x, y, pick(ramp, v, x, y))
		for i in range(40):
			var cx2: int = rng.randi_range(10, 69)
			var cy2: int = rng.randi_range(10, 43)
			ball(im, cx2, cy2, 1.6, 1.2, ramp, 0.2)
		if wet:
			for i in range(26):
				var x: int = rng.randi_range(10, 69)
				var y: int = rng.randi_range(10, 43)
				px(im, x, y, Color("8a7a6a"))
				px(im, x + 1, y, Color("5a4a40"))
		# рамка
		planks(im, 2, 2, 76, 7, WOOD, false, 7, 0.62, 1)
		planks(im, 2, 44, 76, 12, WOOD, false, 6, 0.42, 2)
		planks(im, 2, 8, 7, 37, WOOD, true, 7, 0.52, 3)
		planks(im, 71, 8, 7, 37, WOOD, true, 7, 0.36, 4)
		for cxp in [4, 72]:
			for y in range(0, 56):
				var v4: float = 0.6 - (0.25 if cxp == 72 else 0.0)
				if y < 2:
					v4 += 0.2
				px(im, int(cxp), y, pick(WOOD, v4 + 0.1, int(cxp), y))
				px(im, int(cxp) + 1, y, pick(WOOD, v4, int(cxp) + 1, y))
				px(im, int(cxp) + 2, y, pick(WOOD, v4 - 0.15, int(cxp) + 2, y))
		outline(im, OUT_WOOD)
		save(im, "bed_wet" if wet else "bed_dry")


## Растения 32x48, «ноги» в точке (16, 45)
func gen_crops() -> void:
	var crops: Array = ["mint", "lavender", "chamomile", "nettle"]
	for crop in crops:
		for stage in range(4):
			rng.seed = 500 + stage * 7 + crops.find(crop) * 31
			var im: Image = new_img(32, 48)
			draw_crop(im, String(crop), stage)
			outline(im, OUT_DARK)
			save(im, "%s_%d" % [crop, stage], stage == 3 or crop == "mint")


func draw_crop(im: Image, crop: String, stage: int) -> void:
	if stage == 0:
		ball(im, 16, 42, 9, 4, SOIL, 0.15)
		for k in range(4):
			px(im, 11 + k * 3, 41 + (k % 2), Color("e8d09a"))
			px(im, 12 + k * 3, 41 + (k % 2), Color("b89a62"))
		return
	if stage == 1:
		ball(im, 16, 43, 7, 3, SOIL, 0.1)
		for y in range(33, 43):
			px(im, 16, y, MINT[3])
			px(im, 17, y, MINT[2])
		ball(im, 12, 33, 4, 2.4, MINT, 0.15)
		ball(im, 21, 32, 4, 2.4, MINT, 0.2)
		px(im, 13, 32, MINT[8])
		px(im, 20, 31, MINT[8])
		return
	match crop:
		"mint":
			var cs: Array = []
			if stage == 2:
				cs = [Vector4(16, 30, 6.5, 6), Vector4(10, 36, 6, 5.5), Vector4(22, 36, 6, 5.5)]
			else:
				cs = [Vector4(16, 19, 6, 5.5), Vector4(11, 26, 6.5, 6), Vector4(21, 26, 6.5, 6), Vector4(16, 30, 7, 6.5), Vector4(8, 36, 7, 6), Vector4(24, 36, 7, 6), Vector4(16, 38, 8, 6.5)]
			for y in range(28, 44):
				px(im, 16, y, MINT5[1])
			clusters(im, cs, MINT5, 3 + stage, 0.22, 1, 6.0, 9.0)
			if stage == 3:
				for p in [Vector2i(9, 16), Vector2i(23, 18), Vector2i(16, 10)]:
					var pp: Vector2i = p
					for k in range(5):
						px(im, pp.x, pp.y + k, Color("c6b6f2") if k % 2 == 0 else Color("e8dcf6"))
						if k % 2 == 1:
							px(im, pp.x - 1, pp.y + k, Color("a898dc"))
							px(im, pp.x + 1, pp.y + k, Color("b8a8e8"))
		"lavender":
			for k in range(14):
				var ang0: float = PI + 0.25 + k / 13.0 * (PI - 0.5)
				var ln0: float = rng.randf_range(5.0, 9.0)
				for j in range(int(ln0)):
					var lxx: int = int(16 + cos(ang0) * j)
					var lyy: int = int(44 + sin(ang0) * j * 0.8)
					px(im, lxx, lyy, pick(SAGE, 0.35 + float(j) / ln0 * 0.5, lxx, lyy))
			var tops: Array = [Vector2i(10, 24), Vector2i(16, 20), Vector2i(22, 24)]
			if stage == 3:
				tops = [Vector2i(5, 12), Vector2i(10, 6), Vector2i(16, 3), Vector2i(22, 6), Vector2i(27, 12), Vector2i(13, 14), Vector2i(19, 13)]
			for tp in tops:
				var tv: Vector2i = tp
				var sx: float = 16.0
				var steps: int = 40 - (tv.y + 12)
				for k in range(maxi(1, steps)):
					var t: float = float(k) / float(maxi(1, steps))
					var xx: int = int(lerpf(sx, float(tv.x), t * t))
					px(im, xx, 38 - k, SAGE[3] if k % 3 != 0 else SAGE[2])
				if stage == 3:
					for y in range(tv.y, tv.y + 12):
						var v: float = 0.95 - (y - tv.y) * 0.06
						var bud: bool = posmod(y - tv.y, 2) == 0
						px(im, tv.x, y, pick(LAV, v, tv.x, y))
						if bud:
							px(im, tv.x - 1, y, pick(LAV, v - 0.22, tv.x - 1, y))
							px(im, tv.x + 1, y, pick(LAV, v - 0.05, tv.x + 1, y))
						else:
							px(im, tv.x - 1, y, pick(LAV, v - 0.35, tv.x - 1, y))
					px(im, tv.x, tv.y - 1, LAV[8])
				else:
					for y in range(tv.y + 6, tv.y + 12):
						px(im, tv.x, y, pick(SAGE, 0.6, tv.x, y))
					px(im, tv.x, tv.y + 6, LAV[4])
					px(im, tv.x, tv.y + 8, LAV[3])
		"chamomile":
			# перистые листья
			for k in range(10):
				var bx: int = 8 + k * 2 - (k % 2) * 1
				var hgt: int = rng.randi_range(6, 12)
				for j in range(hgt):
					px(im, bx + (j % 3) - 1, 44 - j, MINT[4 + (j % 3)])
			var heads: Array = [Vector2i(16, 24)]
			if stage == 3:
				heads = [Vector2i(8, 20), Vector2i(16, 12), Vector2i(24, 18), Vector2i(13, 27), Vector2i(21, 29)]
			for hpos in heads:
				var hp: Vector2i = hpos
				var steps2: int = 42 - hp.y
				for k in range(steps2):
					var t2: float = float(k) / float(steps2)
					px(im, int(lerpf(16.0, float(hp.x), t2)), 42 - k, MINT[3])
				if stage == 2:
					ball(im, hp.x, hp.y, 2.2, 2.0, MINT, 0.25)
					px(im, hp.x, hp.y - 1, Color("f2d24a"))
				else:
					for a in range(10):
						var ang: float = a / 10.0 * TAU
						var ex: int = hp.x + int(round(cos(ang) * 3.4))
						var ey: int = hp.y + int(round(sin(ang) * 2.6))
						px(im, ex, ey, CREAM[4] if sin(ang) < 0.3 else CREAM[2])
						var mx: int = hp.x + int(round(cos(ang) * 2.0))
						var my: int = hp.y + int(round(sin(ang) * 1.6))
						px(im, mx, my, CREAM[3])
					ball(im, hp.x, hp.y - 0.5, 1.8, 1.6, hx(["b8801a", "dca22a", "f2c43a", "fce070"]), 0.2)
		"nettle":
			var top2: int = 22 if stage == 2 else 5
			for y in range(top2, 45):
				px(im, 16, y, NETTLE[2])
				px(im, 17, y, NETTLE[1])
			var yy: int = top2 + 3
			var size: float = 2.5
			while yy < 40:
				for side in [-1, 1]:
					var s: int = int(side)
					var lc: Vector2 = Vector2(16.5 + s * (3.5 + size), yy + 2.0)
					for y in range(int(lc.y - 3), int(lc.y + 4)):
						for x in range(int(lc.x - size - 3), int(lc.x + size + 4)):
							var dx: float = (x + 0.5 - lc.x) / (size + 2.2)
							var dy: float = (y + 0.5 - lc.y) / 2.8
							var d: float = dx * dx + dy * dy
							if d > 1.0:
								continue
							if d > 0.7 and posmod(x + y, 2) == 0:
								continue
							var v: float = 0.78 - dy * 0.22 + (dx * -s) * 0.1
							if absf(dy) < 0.18:
								v -= 0.18
							px(im, x, y, pick(NETTLE, v, x, y))
				yy += 9
				size += 0.9
			ball(im, 16.5, top2, 2.5, 2.5, NETTLE, 0.3)


func gen_seed_pouch() -> void:
	var tints: Dictionary = {"mint": [Color("54a051"), Color("8ccb78")], "lavender": [Color("7462b8"), Color("a898dc")], "chamomile": [Color("dca22a"), Color("fce070")]}
	var sack: Array = hx(["6a4c2a", "86643a", "a2804c", "bc9a62", "d4b47e", "e6cc9c"])
	for k in tints.keys():
		var im: Image = new_img(32, 32)
		for y in range(9, 30):
			var hw: float = 7.0 + sin((y - 9) / 21.0 * PI) * 5.5
			for x in range(int(16 - hw), int(16 + hw)):
				var u: float = (x + 0.5 - (16 - hw)) / (2 * hw)
				var v: float = 0.82 - u * 0.55 - (y - 9) * 0.008 + sin(u * PI) * 0.08
				if posmod(x, 2) == posmod(y, 2):
					v -= 0.06
				px(im, x, y, pick(sack, v, x, y))
		for y in range(3, 9):
			for x in range(11 + (8 - y) / 2, 21 - (8 - y) / 2):
				px(im, x, y, pick(sack, 0.75 - (x - 11) * 0.04, x, y))
		for x in range(10, 23):
			px(im, x, 9, RED[2])
			px(im, x, 10, RED[1])
		px(im, 22, 11, RED[2])
		px(im, 23, 12, RED[3])
		# бирка
		for y in range(15, 25):
			for x in range(10, 22):
				var edge: bool = x == 10 or x == 21 or y == 15 or y == 24
				px(im, x, y, CREAM[1] if edge else CREAM[4])
		var tc: Array = tints[k]
		ball(im, 16, 20, 3, 3, hx([Color(tc[0]).darkened(0.4).to_html(), Color(tc[0]).to_html(), Color(tc[1]).to_html(), Color(tc[1]).lightened(0.3).to_html()]), 0.1)
		outline(im, OUT_WOOD)
		save(im, "seeds_%s" % k)


# ================================================================== герой 32x48

## Лист: 4 кадра x 4 направления (вниз, вверх, влево, вправо)
func gen_player() -> void:
	var sheet: Image = new_img(128, 192)
	for dir in range(3):
		for f in range(4):
			var cell: Image = new_img(32, 48)
			draw_hero(cell, dir, f)
			outline(cell, OUT_DARK)
			sheet.blit_rect(cell, Rect2i(0, 0, 32, 48), Vector2i(f * 32, dir * 48))
			if dir == 2:
				var m: Image = cell.duplicate()
				m.flip_x()
				sheet.blit_rect(m, Rect2i(0, 0, 32, 48), Vector2i(f * 32, 3 * 48))
	save(sheet, "player")
	var big: Image = sheet.duplicate()
	big.resize(512, 768, Image.INTERPOLATE_NEAREST)
	var dir2: String = ProjectSettings.globalize_path("res://").path_join("../screenshots")
	DirAccess.make_dir_recursive_absolute(dir2)
	big.save_png(dir2.path_join("player_zoom.png"))


func boot(im: Image, x0: int, y0: int, w: int, toe_left: bool) -> void:
	var b: Array = hx(["1e1418", "2e2026", "45303a", "5e4250"])
	for y in range(y0, y0 + 6):
		for x in range(x0, x0 + w):
			var v: float = 0.62 - float(x - x0) / w * 0.4
			if y == y0:
				v += 0.25
			if y == y0 + 5:
				v = 0.0
			px(im, x, y, pick(b, v, x, y))
	if toe_left:
		px(im, x0 - 1, y0 + 4, b[1])
		px(im, x0 - 1, y0 + 5, b[0])


func cloak_body(im: Image, cx: float, y0: int, y1: int, hw0: float, hw1: float, folds: bool) -> void:
	for y in range(y0, y1 + 1):
		var t: float = float(y - y0) / float(y1 - y0)
		var hw: float = lerpf(hw0, hw1, t)
		for x in range(int(cx - hw), int(cx + hw) + 1):
			var u: float = (x + 0.5 - (cx - hw)) / (2.0 * hw)
			var v: float = 0.80 - u * 0.55 + sin(u * PI) * 0.06
			if folds and t > 0.35:
				var f1: float = absf(u - 0.30)
				var f2: float = absf(u - 0.70)
				if f1 < 0.04 or f2 < 0.04:
					v -= 0.22
				elif (u > 0.30 and u < 0.36) or (u > 0.70 and u < 0.76):
					v += 0.08
			if y == y1:
				v -= 0.3
			elif y == y1 - 1:
				v = 0.85 if posmod(x, 2) == 0 else 0.7
				px(im, x, y, pick(GOLD, v, x, y))
				continue
			px(im, x, y, pick(CLOAK, v, x, y))


func hood(im: Image, cx: float, cy: float, r: float) -> void:
	ball(im, cx, cy, r, r * 0.98, CLOAK, 0.12)


func draw_hero(im: Image, dir: int, f: int) -> void:
	var bob: int = -1 if (f == 1 or f == 3) else 0
	var eye: Color = Color("2a1e2e")
	var eye_hi: Color = Color("ffffff")
	var blush: Color = Color("f29a96")
	var mouth: Color = Color("b0584e")
	if dir == 0 or dir == 1:
		var lift_l: int = -2 if f == 1 else 0
		var lift_r: int = -2 if f == 3 else 0
		boot(im, 10, 40 + lift_l, 6, false)
		boot(im, 17, 40 + lift_r, 6, false)
		cloak_body(im, 16.0, 22 + bob, 41, 7.5, 11.5, true)
		var hs: int = 1 if f == 1 else (-1 if f == 3 else 0)
		if dir == 0:
			# туника и пояс
			for y in range(27 + bob, 39):
				for x in range(14, 19):
					var v: float = 0.7 - (x - 14) * 0.08
					px(im, x, y, pick(TUNIC, v, x, y))
			for x in range(13, 20):
				px(im, x, 32 + bob, LEATHER[2])
				px(im, x, 33 + bob, LEATHER[1])
			px(im, 16, 32 + bob, GOLD[4])
			px(im, 17, 32 + bob, GOLD[3])
			px(im, 16, 33 + bob, GOLD[2])
			# ремень сумки
			for i in range(12):
				px(im, 9 + i, 23 + bob + i, LEATHER[3])
				px(im, 10 + i, 23 + bob + i, LEATHER[2])
			# сумка
			for y in range(33 + bob, 41 + bob):
				for x in range(20, 28):
					var v2: float = 0.75 - (x - 20) * 0.06 - (y - 33 - bob) * 0.03
					if y < 36 + bob:
						v2 += 0.12
					if y == 36 + bob:
						v2 -= 0.3
					px(im, x, y, pick(LEATHER, v2, x, y))
			px(im, 24, 37 + bob, GOLD[4])
			px(im, 24, 38 + bob, GOLD[2])
		else:
			for y in range(24 + bob, 39):
				px(im, 16, y, CLOAK[1])
			for i in range(12):
				px(im, 22 - i, 23 + bob + i, LEATHER[3])
				px(im, 23 - i, 23 + bob + i, LEATHER[2])
			for y in range(33 + bob, 40 + bob):
				for x in range(4, 10):
					px(im, x, y, pick(LEATHER, 0.65 - (x - 4) * 0.05, x, y))
		# рукава и руки
		for y in range(25 + bob, 33 + bob + hs):
			for x in range(5, 9):
				px(im, x, y, pick(CLOAK, 0.72 - (x - 5) * 0.08 - (y - 25) * 0.01, x, y))
		for y in range(25 + bob, 33 + bob - hs):
			for x in range(24, 28):
				px(im, x, y, pick(CLOAK, 0.42 - (x - 24) * 0.06, x, y))
		for x in range(5, 9):
			px(im, x, 32 + bob + hs, TUNIC[3])
		for x in range(24, 28):
			px(im, x, 32 + bob - hs, TUNIC[1])
		ball(im, 6.5, 34 + bob + hs, 2.2, 2.0, SKIN, 0.2)
		ball(im, 25.5, 34 + bob - hs, 2.2, 2.0, SKIN, 0.1)
		# капюшон и голова
		hood(im, 16, 14 + bob, 12.0)
		for k in range(4):
			px(im, 17 + k, 2 + bob - (k / 2), CLOAK[4 - k / 2])
			px(im, 17 + k, 3 + bob - (k / 2), CLOAK[3])
		if dir == 0:
			ell(im, 16, 17.5 + bob, 9.6, 9.0, CLOAK[0])
			ball(im, 16, 18 + bob, 8.2, 7.6, SKIN, 0.22)
			# чёлка: прядки разной длины, блик
			var fr: Array = [8, 7, 5, 4, 5, 3, 4, 2, 3, 4, 3, 5, 4, 3, 5, 6, 8]
			for i in range(17):
				var x: int = 8 + i
				var ln: int = int(fr[i])
				for k in range(ln + 1):
					var v3: float = 0.80 - k * 0.09 - absf(i - 5) * 0.012
					if k == 1 and i > 2 and i < 11:
						v3 += 0.2
					if k == ln:
						v3 -= 0.15
					px(im, x, 10 + bob + k, pick(HAIR, v3, x, 10 + k))
			for y in range(16 + bob, 25 + bob):
				px(im, 8, y, HAIR[2])
				px(im, 24, y, HAIR[1])
			for y in range(16 + bob, 21 + bob):
				px(im, 9, y, HAIR[3])
				px(im, 23, y, HAIR[2])
			# глаза
			for ex in [11, 20]:
				var e: int = int(ex)
				px(im, e, 17 + bob, eye)
				px(im, e + 1, 17 + bob, eye)
				px(im, e, 18 + bob, eye)
				px(im, e + 1, 18 + bob, Color("4a3a5a"))
				px(im, e, 19 + bob, Color("4a3a5a"))
				px(im, e + 1, 19 + bob, eye)
				px(im, e, 17 + bob, eye_hi)
			px(im, 10, 21 + bob, blush)
			px(im, 11, 21 + bob, blush)
			px(im, 21, 21 + bob, blush)
			px(im, 22, 21 + bob, blush)
			px(im, 15, 22 + bob, mouth)
			px(im, 16, 22 + bob, mouth)
			px(im, 16, 20 + bob, SKIN[2])
		else:
			for y in range(5 + bob, 24 + bob):
				px(im, 16, y, CLOAK[1])
			for y in range(23 + bob, 26 + bob):
				for x in range(12, 21):
					px(im, x, y, pick(HAIR, 0.5 - absf(x - 16) * 0.05, x, y))
	else:
		# профиль влево
		var front_dx: int = -3 if f == 1 else (3 if f == 3 else 0)
		boot(im, 17 - front_dx, 40, 6, true)
		boot(im, 12 + front_dx, 40 - (1 if f != 0 and f != 2 else 0), 6, true)
		cloak_body(im, 17.0, 22 + bob, 41, 6.5, 9.5, true)
		for y in range(31 + bob, 40 + bob):
			for x in range(22, 29):
				var v4: float = 0.7 - (x - 22) * 0.07 - (y - 31 - bob) * 0.02
				if y == 34 + bob:
					v4 -= 0.3
				px(im, x, y, pick(LEATHER, v4, x, y))
		px(im, 25, 35 + bob, GOLD[4])
		for y in range(23 + bob, 33 + bob):
			px(im, 19, y, LEATHER[3])
			px(im, 20, y, LEATHER[2])
		var hs2: int = 2 if f == 1 else (-2 if f == 3 else 0)
		thick_line(im, Vector2(14, 25 + bob), Vector2(10.5 + hs2, 31 + bob), 4.5, CLOAK, 0.55)
		ball(im, 10.0 + hs2, 33 + bob, 2.2, 2.0, SKIN, 0.2)
		hood(im, 17.5, 14 + bob, 12.0)
		for k in range(4):
			px(im, 22 + k, 3 + bob + k / 2, CLOAK[4 - k / 2])
		ell(im, 12, 17.5 + bob, 6.8, 8.8, CLOAK[0])
		ball(im, 11.5, 18 + bob, 5.8, 7.6, SKIN, 0.25)
		px(im, 5, 19 + bob, SKIN[3])
		px(im, 5, 20 + bob, SKIN[2])
		for x in range(6, 18):
			var ln2: int = 2 + int(h01(x, 2, 5) * 3.0)
			for k in range(ln2 + 1):
				px(im, x, 11 + bob + k, pick(HAIR, 0.75 - k * 0.12, x, 11 + k))
		for y in range(12 + bob, 25 + bob):
			px(im, 16, y, pick(HAIR, 0.5, 16, y))
			px(im, 17, y, pick(HAIR, 0.35, 17, y))
		px(im, 8, 17 + bob, eye_hi)
		px(im, 9, 17 + bob, eye)
		px(im, 8, 18 + bob, eye)
		px(im, 9, 18 + bob, Color("4a3a5a"))
		px(im, 8, 19 + bob, Color("4a3a5a"))
		px(im, 9, 19 + bob, eye)
		px(im, 10, 21 + bob, blush)
		px(im, 11, 21 + bob, blush)
		px(im, 7, 22 + bob, mouth)


# ================================================================== кот 36x30

func gen_cat() -> void:
	var sheet: Image = new_img(144, 30)
	for f in range(4):
		rng.seed = 60 + f
		var im: Image = new_img(36, 30)
		if f < 2:
			draw_cat_sit(im, f)
		else:
			draw_cat_sleep(im, f - 2)
		outline(im, OUT_DARK)
		sheet.blit_rect(im, Rect2i(0, 0, 36, 30), Vector2i(f * 36, 0))
	save(sheet, "cat")
	var big: Image = sheet.duplicate()
	big.resize(144 * 5, 30 * 5, Image.INTERPOLATE_NEAREST)
	big.save_png(ProjectSettings.globalize_path("res://").path_join("../screenshots/cat_zoom.png"))
	# подушка
	var cu: Image = new_img(54, 24)
	for y in range(2, 22):
		for x in range(2, 52):
			var dx: float = (x + 0.5 - 27) / 25.0
			var dy: float = (y + 0.5 - 12) / 9.5
			if dx * dx * dx * dx + dy * dy * dy * dy > 1.0:
				continue
			var nz2: float = sqrt(maxf(0.0, 1.0 - dx * dx * dx * dx - dy * dy * dy * dy))
			var v: float = 0.25 + nz2 * 0.5 - dy * 0.18 - dx * 0.08
			var pd: float = Vector2(dx * 25.0, dy * 9.5).length()
			if pd < 3.0:
				v -= 0.15
			px(cu, x, y, pick(RED, v, x, y))
	px(cu, 27, 12, GOLD[4])
	px(cu, 26, 12, GOLD[2])
	for t in [Vector2i(3, 4), Vector2i(50, 4), Vector2i(3, 19), Vector2i(50, 19)]:
		var tp: Vector2i = t
		px(cu, tp.x, tp.y, GOLD[4])
		px(cu, tp.x, tp.y + 1, GOLD[3])
		px(cu, tp.x + (1 if tp.x > 20 else -1), tp.y + 2, GOLD[2])
	outline(cu, OUT_DARK)
	shadow(cu, 28, 21, 24, 3, 0.25)
	save(cu, "cushion")


func cat_stripes(im: Image, pts: Array) -> void:
	for p in pts:
		var pp: Vector2i = p
		if a_at(im, pp.x, pp.y) > 0.5:
			px(im, pp.x, pp.y, ORANGE[1])


func draw_cat_sit(im: Image, f: int) -> void:
	# хвост
	var tail: Array = []
	for k in range(14):
		var t: float = float(k) / 13.0
		var tx: float = 26.0 + sin(t * 2.2) * 6.0
		var ty: float = 27.0 - t * 14.0
		if f == 1:
			tx += t * t * 3.0
			ty -= t * t * 2.0
		tail.append(Vector2(tx, ty))
	for k in range(tail.size()):
		var tp: Vector2 = tail[k]
		ball(im, tp.x, tp.y, 2.4, 2.4, ORANGE, 0.1)
		if k % 3 == 1:
			px(im, int(tp.x), int(tp.y), ORANGE[1])
			px(im, int(tp.x) + 1, int(tp.y), ORANGE[1])
	ball(im, 18, 21, 9.5, 8.2, ORANGE, 0.05)
	ball(im, 18, 23.5, 4.2, 5.0, CREAM, 0.15)
	ball(im, 14, 28, 2.8, 1.6, CREAM, 0.2)
	ball(im, 22, 28, 2.8, 1.6, CREAM, 0.1)
	cat_stripes(im, [Vector2i(10, 18), Vector2i(10, 19), Vector2i(11, 21), Vector2i(26, 18), Vector2i(26, 19), Vector2i(25, 21), Vector2i(10, 23), Vector2i(26, 23)])
	# голова
	ball(im, 18, 11, 9.2, 8.0, ORANGE, 0.12)
	for side in [-1, 1]:
		var s: int = int(side)
		for k in range(6):
			for j in range(6 - k):
				var ex: int = 18 + s * (5 + j) - (s * 1 if j > 3 else 0)
				var ey: int = 6 - k
				px(im, ex, ey, ORANGE[4] if s < 0 else ORANGE[3])
		px(im, 18 + s * 7, 4, Color("f2a0a0"))
		px(im, 18 + s * 7, 5, Color("f2a0a0"))
		px(im, 18 + s * 6, 5, Color("e88a8a"))
	cat_stripes(im, [Vector2i(16, 4), Vector2i(18, 4), Vector2i(20, 4), Vector2i(16, 5), Vector2i(18, 5), Vector2i(20, 5), Vector2i(17, 7), Vector2i(19, 7), Vector2i(10, 10), Vector2i(26, 10), Vector2i(10, 12), Vector2i(26, 12)])
	ball(im, 18, 14.5, 4.5, 3.2, CREAM, 0.2)
	for ex in [13, 21]:
		var e: int = int(ex)
		px(im, e, 10, Color("6aa040"))
		px(im, e + 1, 10, Color("8cc050"))
		px(im, e, 11, Color("4a7a2a"))
		px(im, e + 1, 11, Color("1e1a1e"))
		px(im, e, 12, Color("6aa040"))
		px(im, e + 1, 12, Color("6aa040"))
		px(im, e, 10, Color("ffffff"))
	px(im, 17, 13, Color("e07a8a"))
	px(im, 18, 13, Color("e07a8a"))
	px(im, 17, 15, Color("8a4a40"))
	px(im, 18, 16, Color("8a4a40"))
	px(im, 19, 15, Color("8a4a40"))
	for k in range(3):
		px(im, 9 + k, 14 + k % 2, CREAM[4])
		px(im, 25 + k, 14 + k % 2, CREAM[4])
	px(im, 12, 16, Color("f29a96"))
	px(im, 23, 16, Color("f29a96"))


func draw_cat_sleep(im: Image, f: int) -> void:
	var ry: float = 7.5 + f * 0.6
	ball(im, 20, 20.5 - f * 0.4, 14.5, ry, ORANGE, 0.05)
	cat_stripes(im, [Vector2i(14, 14), Vector2i(15, 14), Vector2i(19, 13), Vector2i(20, 13), Vector2i(24, 13), Vector2i(25, 14), Vector2i(29, 15), Vector2i(30, 16), Vector2i(14, 15), Vector2i(19, 14), Vector2i(24, 14)])
	# хвост вдоль низа
	for k in range(20):
		var tx: float = 33.0 - k * 1.2
		var ty: float = 26.0 + sin(k * 0.25) * 0.8
		ball(im, tx, ty, 2.3, 2.0, ORANGE, 0.05)
		if k % 4 == 2:
			px(im, int(tx), int(ty) - 1, ORANGE[1])
	# голова
	ball(im, 9, 19, 7.2, 6.4, ORANGE, 0.15)
	for k in range(4):
		for j in range(4 - k):
			px(im, 4 + j, 13 - k, ORANGE[4])
			px(im, 11 + j, 13 - k, ORANGE[3])
	px(im, 5, 12, Color("f2a0a0"))
	px(im, 12, 12, Color("f2a0a0"))
	cat_stripes(im, [Vector2i(8, 13), Vector2i(10, 13), Vector2i(9, 14)])
	ball(im, 8, 22, 3.8, 2.6, CREAM, 0.2)
	for ex in [5, 11]:
		var e: int = int(ex)
		px(im, e, 19, Color("2a1e2e"))
		px(im, e + 1, 20, Color("2a1e2e"))
		px(im, e - 1, 20, Color("2a1e2e"))
	px(im, 8, 21, Color("e07a8a"))
	px(im, 3, 22, Color("f29a96"))
	px(im, 13, 22, Color("f29a96"))


# ================================================================== эффекты и интерфейс

func gen_fx() -> void:
	var soft: Image = new_img(32, 32)
	for y in range(32):
		for x in range(32):
			var d: float = Vector2(x + 0.5 - 16, y + 0.5 - 16).length() / 16.0
			if d < 1.0:
				soft.set_pixel(x, y, Color(1, 1, 1, pow(1.0 - d, 1.6)))
	save(soft, "fx_soft", false)
	var glow: Image = new_img(256, 256)
	for y in range(256):
		for x in range(256):
			var d2: float = Vector2(x + 0.5 - 128, y + 0.5 - 128).length() / 128.0
			if d2 < 1.0:
				glow.set_pixel(x, y, Color(1, 1, 1, pow(1.0 - d2, 2.2)))
	save(glow, "fx_glow", false)
	var leaf: Image = new_img(8, 7)
	for p in [[3, 1, 6], [4, 1, 7], [2, 2, 5], [3, 2, 6], [4, 2, 6], [5, 2, 5], [2, 3, 4], [3, 3, 5], [4, 3, 4], [5, 3, 4], [3, 4, 3], [4, 4, 3], [1, 5, 2], [2, 4, 2]]:
		px(leaf, int(p[0]), int(p[1]), TREE_B[int(p[2])])
	save(leaf, "fx_leaf", false)
	var fly: Image = new_img(5, 5)
	px(fly, 2, 2, Color(1, 1, 0.85))
	for o in [Vector2i(1, 2), Vector2i(3, 2), Vector2i(2, 1), Vector2i(2, 3)]:
		var op: Vector2i = o
		px(fly, op.x, op.y, Color(1, 1, 0.6, 0.6))
	for o2 in [Vector2i(0, 2), Vector2i(4, 2), Vector2i(2, 0), Vector2i(2, 4)]:
		var op2: Vector2i = o2
		px(fly, op2.x, op2.y, Color(1, 1, 0.5, 0.2))
	save(fly, "fx_firefly", false)
	# бабочка 2 кадра 12x10
	var bf: Image = new_img(24, 10)
	var wing: Array = hx(["c87a1e", "eaa832", "f6d24a", "fff0a0"])
	for f in range(2):
		var ox: int = f * 12
		for y in range(2, 9):
			px(bf, ox + 6, y, Color("2a1e18") if y < 8 else Color("3a2a22"))
		px(bf, ox + 5, 1, Color("2a1e18"))
		px(bf, ox + 7, 1, Color("2a1e18"))
		if f == 0:
			ball(bf, ox + 3, 4, 2.8, 2.6, wing, 0.2)
			ball(bf, ox + 9, 4, 2.8, 2.6, wing, 0.1)
			ball(bf, ox + 3.5, 7.5, 1.8, 1.5, wing, 0.0)
			ball(bf, ox + 8.5, 7.5, 1.8, 1.5, wing, 0.0)
			px(bf, ox + 2, 3, Color("3a2a22"))
			px(bf, ox + 10, 3, Color("3a2a22"))
		else:
			ball(bf, ox + 4.5, 4, 1.4, 3.0, wing, 0.2)
			ball(bf, ox + 7.5, 4, 1.4, 3.0, wing, 0.1)
	save(bf, "fx_butterfly", false)
	var heart: Image = new_img(13, 12)
	for y in range(12):
		for x in range(13):
			var u: float = (x + 0.5 - 6.5) / 6.0
			var v: float = (y + 0.5 - 5.0) / 6.0
			var hv: float = pow(u * u + v * v - 0.35, 3.0) - u * u * pow(-v, 3.0) * 1.0
			if hv <= 0.0:
				px(heart, x, y, pick(RED, 0.8 - v * 0.3 - u * 0.1, x, y))
	px(heart, 3, 3, Color("ffd8de"))
	px(heart, 4, 3, Color("ffd8de"))
	outline(heart, Color("4a1420"))
	save(heart, "fx_heart", false)
	var drop: Image = new_img(5, 7)
	for p in [[2, 0], [2, 1], [1, 2], [2, 2], [3, 2], [1, 3], [2, 3], [3, 3], [1, 4], [2, 4], [3, 4], [2, 5]]:
		px(drop, int(p[0]), int(p[1]), WATER[6])
	px(drop, 1, 3, WATER[8])
	px(drop, 3, 4, WATER[3])
	save(drop, "fx_drop", false)
	# солнечные лучи (мягкие полосы из верхнего угла)
	rng.seed = 808
	var rays: Image = new_img(480, 270)
	var dv: Vector2 = Vector2(cos(deg_to_rad(58.0)), sin(deg_to_rad(58.0)))
	var nv: Vector2 = Vector2(-dv.y, dv.x)
	var beams: Array = []
	for i in range(9):
		beams.append(Vector3(rng.randf_range(-260, 160), rng.randf_range(7, 26), rng.randf_range(0.35, 1.0)))
	for y in range(270):
		for x in range(480):
			var p: Vector2 = Vector2(x, y)
			var along: float = p.dot(dv)
			var perp: float = p.dot(nv)
			var I: float = 0.0
			for b in beams:
				var bv: Vector3 = b
				var q: float = (perp - bv.x) / bv.y
				I += exp(-q * q) * bv.z
			var fade: float = pow(clampf(1.0 - along / 520.0, 0.0, 1.0), 1.3)
			rays.set_pixel(x, y, Color(1, 1, 1, clampf(I * fade * 0.8, 0.0, 1.0)))
	save(rays, "fx_rays", false)


func gen_ui() -> void:
	rng.seed = 5
	# пергаментная панель 40x40 (9-slice, поля 12)
	var p: Image = new_img(40, 40)
	var parch: Array = hx(["a88a5c", "c4a674", "dcc292", "eadab0", "f4e8c8", "fbf4e2"])
	for y in range(40):
		for x in range(40):
			var e: int = mini(mini(x, 39 - x), mini(y, 39 - y))
			var corner: int = mini(x, 39 - x) + mini(y, 39 - y)
			if corner < 3:
				continue
			if e == 0 or corner == 3:
				px(p, x, y, Color("3a2416"))
			elif e == 1:
				px(p, x, y, Color("8a5a34") if (x < 20 and y < 20) else Color("6a4026"))
			elif e == 2:
				px(p, x, y, Color("5a3a24"))
			elif e == 3:
				px(p, x, y, parch[5] if (x - 3 < 30 and y - 3 < 30 and (x == 3 or y == 3)) else parch[2])
			else:
				var v: float = 0.68 + (h01(x, y, 3) - 0.5) * 0.08
				if e < 6:
					v -= (6 - e) * 0.05
				px(p, x, y, pick(parch, v, x, y))
	for c in [Vector2i(5, 5), Vector2i(34, 5), Vector2i(5, 34), Vector2i(34, 34)]:
		var cp: Vector2i = c
		px(p, cp.x, cp.y, GOLD[4])
		px(p, cp.x + 1, cp.y, GOLD[2])
		px(p, cp.x, cp.y + 1, GOLD[2])
		px(p, cp.x + 1, cp.y + 1, GOLD[1])
	save(p, "ui_panel", false)
	# клавиша 22x22
	var k: Image = new_img(22, 22)
	for y in range(22):
		for x in range(22):
			var e2: int = mini(mini(x, 21 - x), mini(y, 21 - y))
			var corner2: int = mini(x, 21 - x) + mini(y, 21 - y)
			if corner2 < 2:
				continue
			if e2 == 0 or corner2 == 2:
				px(k, x, y, Color("3a2416"))
			elif y > 17:
				px(k, x, y, parch[0])
			elif e2 == 1:
				px(k, x, y, parch[5] if (x < 11 or y < 11) else parch[2])
			else:
				px(k, x, y, pick(parch, 0.72 - y * 0.008, x, y))
	save(k, "ui_key", false)
	# солнце 26x26
	var sun: Image = new_img(26, 26)
	for a in range(12):
		var ang: float = a / 12.0 * TAU
		for r in range(9, 12 + (1 if a % 2 == 0 else 0)):
			px(sun, int(13 + cos(ang) * r), int(13 + sin(ang) * r), GOLD[3] if a % 2 == 0 else GOLD[2])
	ball(sun, 13, 13, 7, 7, hx(["d07818", "e89a28", "f6c040", "fcdc6a", "fff2b0"]), 0.15)
	px(sun, 10, 13, Color("8a4a18"))
	px(sun, 15, 13, Color("8a4a18"))
	px(sun, 11, 16, Color("8a4a18"))
	px(sun, 12, 17, Color("8a4a18"))
	px(sun, 13, 17, Color("8a4a18"))
	px(sun, 14, 16, Color("8a4a18"))
	px(sun, 9, 15, Color("f29a6a"))
	px(sun, 16, 15, Color("f29a6a"))
	outline(sun, Color("5a3014"))
	save(sun, "ui_sun", false)
	var moon: Image = new_img(26, 26)
	ball(moon, 13, 13, 9, 9, hx(["7a7aa8", "a0a0c8", "c8c6e6", "e6e4f6", "fbfaff"]), 0.15)
	for y in range(26):
		for x in range(26):
			if Vector2(x + 0.5 - 17, y + 0.5 - 9.5).length() < 8.0:
				moon.set_pixel(x, y, Color(0, 0, 0, 0))
	px(moon, 8, 15, Color("a0a0c8"))
	px(moon, 10, 18, Color("a0a0c8"))
	px(moon, 20, 4, Color("fff4c0"))
	px(moon, 22, 14, Color("fff4c0"))
	outline(moon, Color("2a2a4a"))
	save(moon, "ui_moon", false)
	# стрелка над целью
	var ar: Image = new_img(15, 11)
	for i in range(6):
		for x in range(1 + i, 14 - i):
			px(ar, x, 1 + i, CREAM[4] if x < 7 else CREAM[2])
	for x in range(5, 10):
		px(ar, x, 0, CREAM[4])
	outline(ar, Color("3a2416"))
	save(ar, "ui_arrow", false)


func gen_book() -> void:
	var W: int = 1600
	var H: int = 920
	var im: Image = new_img(W, H)
	var nz: FastNoiseLite = FastNoiseLite.new()
	nz.seed = 21
	nz.frequency = 0.0035
	nz.fractal_octaves = 4
	var nz2: FastNoiseLite = FastNoiseLite.new()
	nz2.seed = 5
	nz2.frequency = 0.06
	rng.seed = 404
	var stains: Array = []
	for i in range(8):
		stains.append(Vector4(rng.randf_range(120, 1480), rng.randf_range(100, 820), rng.randf_range(40, 120), rng.randf_range(0.10, 0.22)))
	var page_l: Rect2 = Rect2(46, 30, 754, 860)
	var page_r: Rect2 = Rect2(800, 30, 754, 860)
	var paper: Color = Color("f1e2c0")
	var sepia: Color = Color("c9a46c")
	var burnt: Color = Color("8f6638")
	var leather: Color = Color("5a3220")
	for y in range(H):
		for x in range(W):
			var cxr: float = clampf(float(x), 28.0, float(W - 28))
			var cyr: float = clampf(float(y), 28.0, float(H - 28))
			if Vector2(x, y).distance_to(Vector2(cxr, cyr)) > 28.0:
				continue
			var p: Vector2 = Vector2(x, y)
			var bend: float = 10.0 * pow(1.0 - absf(x - 800.0) / 754.0, 3.0)
			var in_page: bool = (page_l.has_point(p) or page_r.has_point(p)) and y > 30 + bend and y < 890 - bend * 0.4
			var c: Color
			if in_page:
				var n: float = nz.get_noise_2d(x, y)
				var t: float = 0.18 + n * 0.22 + nz2.get_noise_2d(x, y) * 0.035
				for s in stains:
					var st: Vector4 = s
					var d: float = p.distance_to(Vector2(st.x, st.y)) / st.z
					if d < 1.0:
						t += st.w * 0.6 * (1.0 - d)
						if d > 0.84:
							t += st.w * 1.6 * (1.0 - absf(d - 0.92) / 0.08)
				var ex: float = absf(x - (46.0 if x < 800 else 1554.0))
				var ey: float = minf(y - 30.0 - bend, 890.0 - bend * 0.4 - y)
				var e: float = minf(ex, ey)
				t += pow(clampf(1.0 - e / 46.0, 0.0, 1.0), 2.0) * 0.55
				c = paper.lerp(sepia, clampf(t, 0.0, 1.0))
				if e < 4.0:
					c = c.lerp(burnt, 0.5)
				var dg: float = absf(x - 800.0)
				if dg < 110.0:
					c = c.lerp(Color("6e4c2c"), pow(1.0 - dg / 110.0, 2.2) * 0.62)
				if dg < 1.5:
					c = Color("5a3a22")
			else:
				var stack: bool = (x >= 36 and x < 46 or x >= 1554 and x < 1564) and y > 40 and y < 884
				if stack:
					c = Color("e2cfa4") if posmod(x, 3) != 0 else Color("a88a5c")
				else:
					var ln: float = nz.get_noise_2d(x * 3.0, y * 3.0)
					c = leather.lerp(Color("7a4630"), clampf(0.4 + ln * 0.6, 0.0, 1.0))
					var ed: float = minf(minf(float(x), float(W - x)), minf(float(y), float(H - y)))
					if ed < 6.0:
						c = c.darkened(0.35)
					if absf(ed - 13.0) < 1.2 and posmod(int((x + y) / 7.0), 2) == 0:
						c = Color("c9a36a")
			im.set_pixel(x, y, c)
	for corner in [Vector2i(0, 0), Vector2i(W, 0), Vector2i(0, H), Vector2i(W, H)]:
		var cp: Vector2i = corner
		for yy in range(0, 46):
			for xx in range(0, 46):
				if xx + yy > 46:
					continue
				var X: int = xx if cp.x == 0 else W - 1 - xx
				var Y: int = yy if cp.y == 0 else H - 1 - yy
				if im.get_pixel(X, Y).a < 0.5:
					continue
				var g: Color = Color("c9a24a").lerp(Color("f2d27a"), clampf(1.0 - (xx + yy) / 46.0, 0.0, 1.0))
				if xx + yy > 42:
					g = Color("7a5a20")
				im.set_pixel(X, Y, g)
	im.save_png(OUT + "book.png")


# ================================================================== превью

func save_preview() -> void:
	if preview_items.is_empty():
		return
	var cols: int = 6
	var cell: int = 200
	var rows: int = int(ceil(preview_items.size() / float(cols)))
	var sheet: Image = new_img(cols * cell, rows * cell)
	sheet.fill(Color("84bf62"))
	for i in range(preview_items.size()):
		var src: Image = preview_items[i][1]
		var s: Image = src.duplicate()
		var sc: int = maxi(1, mini(cell / maxi(s.get_width(), 1), cell / maxi(s.get_height(), 1)))
		sc = mini(sc, 4)
		s.resize(s.get_width() * sc, s.get_height() * sc, Image.INTERPOLATE_NEAREST)
		var ox: int = (i % cols) * cell + (cell - s.get_width()) / 2
		var oy: int = (i / cols) * cell + (cell - s.get_height()) / 2
		sheet.blend_rect(s, Rect2i(0, 0, s.get_width(), s.get_height()), Vector2i(ox, oy))
	var dir: String = ProjectSettings.globalize_path("res://").path_join("../screenshots")
	DirAccess.make_dir_recursive_absolute(dir)
	sheet.save_png(dir.path_join("art_preview.png"))


# ================================================================== v3: листва из листиков, гранёные камни
# Крона = крупные комки со светом (как на референсах), но поверх каждого комка
# лежат сотни маленьких заострённых листиков чешуёй: тело листа + тёмный край
# с теневой стороны + светлый край у освещённых. Так получается «реалистичная»
# листва без пупырышек: свет крупными пятнами, фактура мелкими листьями.

var L7_GREEN: Array
var L7_LIME: Array
var L7_DEEP: Array
var L7_AUTUMN: Array
var L7_BLOSSOM: Array
var L7_PINE: Array
var L7_BUSH: Array
var L7_MINT: Array
var L7_NETTLE: Array
var L7_SAGE: Array
var ROCK6: Array
var ROCK6_WARM: Array
var BARK7: Array
var v3_items: Array = []
const LT2: Vector2 = Vector2(-0.57, -0.82)


func _palettes3() -> void:
	L7_GREEN = hx(["1d3a44", "275656", "347464", "4a9466", "6eb462", "9ccf6a", "cde890"])
	L7_LIME = hx(["21444a", "2c6458", "3a865a", "5aa852", "88c64e", "b8de5c", "e6f28e"])
	L7_DEEP = hx(["1a3140", "224a52", "2c6460", "3c826a", "5aa070", "84bf82", "b8dca2"])
	L7_AUTUMN = hx(["4a2236", "783238", "a64e3a", "d07a3e", "e8a446", "f4c862", "fce79c"])
	L7_BLOSSOM = hx(["4e2c4e", "84466a", "b46488", "d888a4", "eeaec2", "f9d0dc", "fff1f5"])
	L7_PINE = hx(["142a38", "1b3e46", "245852", "2f7258", "438e5e", "66ac6a", "9ccc88"])
	L7_BUSH = hx(["1b3640", "24504e", "306c56", "468c58", "68ac5a", "96ca66", "c8e48a"])
	L7_MINT = hx(["163a36", "1f564a", "2b7454", "3f945a", "62b462", "94d07a", "cdeaa0"])
	L7_NETTLE = hx(["14302e", "1c443c", "265c46", "32764e", "47905a", "68ac68", "9ccc88"])
	L7_SAGE = hx(["2a3a3c", "3a504c", "4e675c", "66806c", "84997e", "a6b898", "ccd8bc"])
	ROCK6 = hx(["272536", "3c3a52", "56546e", "74728c", "9694aa", "bbbacb", "e0dfe8"])
	ROCK6_WARM = hx(["2e2630", "47394a", "625266", "7f6e82", "a0909f", "c3b6bf", "e6dde0"])
	BARK7 = hx(["2a1e2c", "41303a", "5c4044", "7a5548", "9a6e52", "ba8c62", "d8b07c"])


## Тон 0..6 по освещённости v (0..1)
func tone7(v: float) -> int:
	if v < 0.30:
		return 1
	if v < 0.44:
		return 2
	if v < 0.57:
		return 3
	if v < 0.70:
		return 4
	if v < 0.86:
		return 5
	return 6


## Один листик: заострённый овал вдоль dir. t — тон тела.
func draw_leaf(im: Image, c: Vector2, dir: Vector2, L: float, W: float, t: int, ramp: Array, vein: bool = false) -> void:
	var d: Vector2 = dir.normalized()
	var pp: Vector2 = Vector2(-d.y, d.x)
	var b: Vector2 = c - d * L * 0.45
	var n: int = ramp.size()
	var r: int = int(ceil(L)) + 1
	for y in range(int(c.y) - r, int(c.y) + r + 1):
		for x in range(int(c.x) - r, int(c.x) + r + 1):
			var q: Vector2 = Vector2(x + 0.5, y + 0.5) - b
			var u: float = q.dot(d) / L
			if u < 0.0 or u > 1.0:
				continue
			var vv: float = q.dot(pp)
			var half: float = W * 0.5 * pow(sin(PI * pow(u, 0.75)), 0.65)
			if absf(vv) > half:
				continue
			var edge: bool = absf(vv) > half - 1.0 or u > 0.86
			var lit: bool = (pp * signf(vv + 0.001)).dot(LT2) > 0.0
			var ti: int = t
			if edge and not lit:
				ti = t - 1
			elif edge and lit and t >= 4 and u > 0.25 and u < 0.8:
				ti = t + 1
			elif vein and absf(vv) < 0.5 and u > 0.15 and u < 0.8 and t >= 3:
				ti = t - 1
			px(im, x, y, ramp[clampi(ti, 0, n - 1)])


## Убирает одиночные «пиксели-пупырышки»: если у пикселя все 4 соседа другого
## цвета, а 3 из них одинаковые — красим его в цвет большинства.
func clean_specks(im: Image) -> void:
	var src: Image = im.duplicate()
	var w: int = im.get_width()
	var h: int = im.get_height()
	for y in range(1, h - 1):
		for x in range(1, w - 1):
			var c: Color = src.get_pixel(x, y)
			if c.a < 0.5:
				continue
			var nb: Array = [src.get_pixel(x - 1, y), src.get_pixel(x + 1, y), src.get_pixel(x, y - 1), src.get_pixel(x, y + 1)]
			var same: int = 0
			for o in nb:
				if Color(o).is_equal_approx(c):
					same += 1
			if same > 0:
				continue
			for o2 in nb:
				var oc: Color = o2
				if oc.a < 0.5:
					continue
				var cnt: int = 0
				for o3 in nb:
					if Color(o3).is_equal_approx(oc):
						cnt += 1
				if cnt >= 3:
					im.set_pixel(x, y, oc)
					break


## Крона из комков, покрытых листиками.
## clumps: Vector4(cx, cy, rx, ry) — задние раньше. under: рисует ветки поверх тёмной подложки.
## holes: Vector3(x, y, r) — просветы, где листьев нет (видны ветки).
func leaf_canopy(im: Image, clumps: Array, ramp: Array, seed_v: int, L: float, W: float, sp: float, droop: float, under: Callable = Callable(), holes: Array = [], vein: bool = false) -> void:
	var w: int = im.get_width()
	var h: int = im.get_height()
	var owner: PackedInt32Array = PackedInt32Array()
	owner.resize(w * h)
	owner.fill(-1)
	var vals: PackedFloat32Array = PackedFloat32Array()
	vals.resize(w * h)
	var nzs: PackedFloat32Array = PackedFloat32Array()
	nzs.resize(w * h)
	var top: float = 1e9
	var bot: float = -1e9
	var minx: float = 1e9
	var maxx: float = -1e9
	for c0 in clumps:
		var cc: Vector4 = c0
		top = minf(top, cc.y - cc.w)
		bot = maxf(bot, cc.y + cc.w)
		minx = minf(minx, cc.x - cc.z)
		maxx = maxf(maxx, cc.x + cc.z)
	var span: float = maxf(1.0, bot - top)
	for i in range(clumps.size()):
		var c: Vector4 = clumps[i]
		var ph: float = h01(i, seed_v, 3) * TAU
		var k: float = floor(lerpf(5.0, 8.0, h01(i, seed_v, 4)))
		for y in range(int(c.y - c.w) - 2, int(c.y + c.w) + 3):
			for x in range(int(c.x - c.z) - 2, int(c.x + c.z) + 3):
				if x < 0 or y < 0 or x >= w or y >= h:
					continue
				var dx: float = (x + 0.5 - c.x) / c.z
				var dy: float = (y + 0.5 - c.y) / c.w
				var d: float = sqrt(dx * dx + dy * dy)
				var edge: float = 1.0 + 0.07 * sin(atan2(dy, dx) * k + ph)
				if d > edge:
					continue
				var dd: float = minf(d / edge, 0.999)
				var nv: Vector3 = Vector3(dx / edge, dy / edge * 1.15, sqrt(1.0 - dd * dd) * 0.7).normalized()
				var v: float = 0.46 + 0.56 * nv.dot(LT)
				v += (0.30 - (y - top) / span) * 0.42
				var idx: int = y * w + x
				owner[idx] = i
				vals[idx] = v
				nzs[idx] = nv.z
	# впадина-тень над передним комком
	var vals2: PackedFloat32Array = vals.duplicate()
	for y in range(h):
		for x in range(w):
			var idx2: int = y * w + x
			var o: int = owner[idx2]
			if o < 0:
				continue
			for kk in range(1, 5):
				if y + kk >= h:
					break
				var o2: int = owner[(y + kk) * w + x]
				if o2 > o:
					vals2[idx2] -= 0.40 * (1.0 - (kk - 1) * 0.2)
					break
	# тёмная подложка (просветы между листьями)
	for y in range(h):
		for x in range(w):
			var idx3: int = y * w + x
			if owner[idx3] >= 0:
				var t0: int = tone7(vals2[idx3])
				px(im, x, y, ramp[clampi(t0 - 3, 0, 6)])
	if under.is_valid():
		under.call()
	# точки листьев
	var pts: Array = []
	var yy: float = top - 1.0
	var row: int = 0
	while yy < bot + 1.0:
		var xx: float = minx - 1.0 + (sp * 0.5 if row % 2 == 1 else 0.0)
		while xx < maxx + 1.0:
			var jx: float = xx + (h01(int(xx * 7.0), int(yy * 7.0), seed_v) - 0.5) * sp * 0.7
			var jy: float = yy + (h01(int(xx * 5.0), int(yy * 5.0), seed_v + 3) - 0.5) * sp * 0.7
			var ix: int = int(jx)
			var iy: int = int(jy)
			xx += sp
			if ix < 0 or iy < 0 or ix >= w or iy >= h:
				continue
			var id: int = iy * w + ix
			if owner[id] < 0:
				continue
			var skip: bool = false
			for hv in holes:
				var hh: Vector3 = hv
				if Vector2(jx, jy).distance_to(Vector2(hh.x, hh.y)) < hh.z:
					skip = true
			if skip:
				continue
			pts.append(Vector4(jx, jy, float(owner[id]) * 10.0 + nzs[id], vals2[id]))
		yy += sp * 0.78
		row += 1
	pts.sort_custom(func(p: Vector4, q: Vector4) -> bool: return p.z < q.z)
	for p0 in pts:
		var p: Vector4 = p0
		var cl: Vector4 = clumps[int(p.z / 10.0)]
		var out: Vector2 = Vector2(p.x - cl.x, (p.y - cl.y) * 0.8)
		var dir: Vector2 = out.normalized() * minf(1.0, out.length() / maxf(1.0, cl.z * 0.35)) + Vector2(0, droop)
		dir += Vector2(h01(int(p.x * 3.0), int(p.y * 3.0), seed_v + 9) - 0.5, 0.0) * 0.6
		if dir.length() < 0.1:
			dir = Vector2(0, 1)
		var t: int = tone7(p.w)
		draw_leaf(im, Vector2(p.x, p.y), dir, L * lerpf(0.85, 1.12, h01(int(p.x), int(p.y), seed_v + 5)), W, t, ramp, vein)


## Кора: вертикальные трещины, тёплый свет слева, сиреневая тень справа, корни
func draw_trunk3(im: Image, cx: float, t0: int, base: int, hw_top: float, seed_v: int) -> void:
	# корни
	for side in [-1.0, 1.0]:
		var s: float = float(side)
		for k in range(14):
			var t: float = k / 13.0
			var rxp: float = cx + s * (hw_top * 0.6 + t * hw_top * 1.6)
			var ryp: float = base - 6.0 + t * 6.0
			var rr: float = 3.8 - t * 2.4
			for y in range(int(ryp - rr) - 1, int(ryp + rr) + 2):
				for x in range(int(rxp - rr) - 1, int(rxp + rr) + 2):
					var dd: Vector2 = Vector2(x + 0.5 - rxp, y + 0.5 - ryp)
					if dd.length() <= rr:
						var ti: int = 4 if dd.y < -rr * 0.3 else 3
						if s > 0.0:
							ti -= 1
						if dd.y > rr * 0.5:
							ti = 1
						px(im, x, y, BARK7[ti])
	for y in range(t0, base + 1):
		var t2: float = float(y - t0) / float(maxi(1, base - t0))
		var hw: float = hw_top + pow(t2, 3.0) * hw_top * 0.9
		for x in range(int(cx - hw), int(cx + hw) + 1):
			var u: float = (x + 0.5 - (cx - hw)) / (2.0 * hw)
			var ti2: int = 5 if u < 0.2 else (4 if u < 0.45 else (3 if u < 0.72 else (2 if u < 0.9 else 1)))
			# трещины коры
			var col: float = (x - cx) / hw
			var crack: float = sin(col * 7.0 + sin(y * 0.35 + seed_v) * 0.8)
			if crack > 0.86:
				ti2 -= 2
			elif crack > 0.6 and h01(x, y / 3, seed_v) > 0.4:
				ti2 -= 1
			if y < t0 + 5:
				ti2 = maxi(1, ti2 - 2)
			px(im, x, y, BARK7[clampi(ti2, 0, 6)])
	# дупло-пятно и мох у основания
	ell(im, cx - hw_top * 0.2, t0 + (base - t0) * 0.45, 1.6, 2.4, BARK7[0])
	for k3 in range(10):
		var mx: int = int(cx + rng.randf_range(-hw_top * 1.2, hw_top * 1.2))
		var my: int = base - rng.randi_range(0, 4)
		if a_at(im, mx, my) > 0.5:
			px(im, mx, my, L7_GREEN[4])
			px(im, mx + 1, my, L7_GREEN[3])


func branch(im: Image, a: Vector2, b: Vector2, w0: float, w1: float) -> void:
	var n: int = int(a.distance_to(b)) + 1
	for i in range(n):
		var t: float = float(i) / float(n)
		var p: Vector2 = a.lerp(b, t)
		var r: float = lerpf(w0, w1, t) * 0.5
		for y in range(int(p.y - r) - 1, int(p.y + r) + 2):
			for x in range(int(p.x - r) - 1, int(p.x + r) + 2):
				var dx: float = x + 0.5 - p.x
				if absf(dx) <= r and absf(y + 0.5 - p.y) <= r:
					var u: float = (dx + r) / (2.0 * r + 0.01)
					px(im, x, y, BARK7[4] if u < 0.35 else (BARK7[3] if u < 0.7 else BARK7[2]))


## Пучки травы: тонкие травинки разной высоты
func grass_blades(im: Image, cx: float, base: int, spread: float, n: int, ramp: Array) -> void:
	for i in range(n):
		var x0: float = cx + rng.randf_range(-spread, spread)
		var hgt: int = rng.randi_range(3, 8)
		var lean: float = rng.randf_range(-0.5, 0.5)
		for k in range(hgt):
			var x: int = int(x0 + lean * k)
			var ti: int = 2 if k < 2 else (4 if k < hgt - 1 else 5)
			if lean > 0.2:
				ti -= 1
			px(im, x, base - k, ramp[clampi(ti, 0, ramp.size() - 1)])


func tree_clumps(cx: float, ccy: float, R: float) -> Array:
	var lay: Array = [
		[0.0, -0.74, 0.44, 0.36], [-0.42, -0.52, 0.42, 0.36], [0.44, -0.56, 0.42, 0.36],
		[-0.78, -0.12, 0.38, 0.36], [0.80, -0.14, 0.38, 0.36], [0.0, -0.26, 0.52, 0.42],
		[-0.52, 0.18, 0.46, 0.38], [0.52, 0.16, 0.46, 0.38], [0.0, 0.30, 0.50, 0.38],
		[-0.92, 0.36, 0.28, 0.26], [0.92, 0.34, 0.28, 0.26],
	]
	var cl: Array = []
	for L0 in lay:
		var a: Array = L0
		cl.append(Vector4(cx + float(a[0]) * R + rng.randf_range(-2, 2), ccy + float(a[1]) * R + rng.randf_range(-2, 2), float(a[2]) * R * rng.randf_range(0.92, 1.08), float(a[3]) * R * rng.randf_range(0.92, 1.08)))
	cl.sort_custom(func(p: Vector4, q: Vector4) -> bool: return p.y < q.y)
	return cl


func gen_tree3(name: String, seed_v: int, w: int, h: int, ramp: Array, extra: String = "") -> void:
	rng.seed = seed_v
	var im: Image = new_img(w, h)
	var cx: float = w / 2.0
	var base: int = h - 8
	var R: float = w * 0.40
	var ccy: float = h * 0.44
	var t0: int = int(ccy + R * 0.2)
	draw_trunk3(im, cx, t0, base, 6.5, seed_v)
	var cl: Array = tree_clumps(cx, ccy, R)
	var bA: Vector2 = Vector2(cx - R * 0.55, ccy + R * 0.02)
	var bB: Vector2 = Vector2(cx + R * 0.5, ccy - R * 0.1)
	var bC: Vector2 = Vector2(cx + 2.0, ccy - R * 0.45)
	var under: Callable = func() -> void:
		branch(im, Vector2(cx - 2, t0 + 6), bA, 6.0, 2.0)
		branch(im, Vector2(cx + 2, t0 + 2), bB, 6.0, 2.0)
		branch(im, Vector2(cx, t0 + 4), bC, 7.0, 2.5)
		for y in range(int(ccy + R * 0.1), t0 + 8):
			for x in range(int(cx - 5), int(cx + 6)):
				px(im, x, y, BARK7[2] if x < cx + 1 else BARK7[1])
	var holes: Array = [Vector3(bA.x * 0.5 + cx * 0.5 - 2, (bA.y + t0) * 0.5, 4.5), Vector3(bB.x * 0.5 + cx * 0.5 + 1, (bB.y + t0) * 0.5 - 2, 4.0)]
	leaf_canopy(im, cl, ramp, seed_v, 6.4, 4.8, 3.4, 0.55, under, holes)
	if extra == "apples":
		var n: int = 0
		var tries: int = 0
		while n < 12 and tries < 400:
			tries += 1
			var ax: int = int(cx + rng.randf_range(-R * 0.95, R * 0.95))
			var ay: int = int(ccy + rng.randf_range(-R * 0.55, R * 0.6))
			if a_at(im, ax - 3, ay) > 0.5 and a_at(im, ax + 3, ay) > 0.5 and a_at(im, ax, ay + 3) > 0.5:
				ball(im, ax + 0.5, ay + 0.5, 3.0, 3.0, hx(["6e1e30", "a0303c", "cc4a4a", "e8706a", "f8b0a0"]), 0.05)
				px(im, ax - 1, ay - 1, Color("fde0d4"))
				px(im, ax, ay - 3, Color("5c3a2c"))
				px(im, ax + 1, ay - 3, ramp[4])
				px(im, ax + 2, ay - 4, ramp[5])
				n += 1
	elif extra == "blossom":
		var m: int = 0
		var tries2: int = 0
		while m < 60 and tries2 < 900:
			tries2 += 1
			var fx: int = int(cx + rng.randf_range(-R * 1.1, R * 1.1))
			var fy: int = int(ccy + rng.randf_range(-R * 0.95, R * 0.7))
			if a_at(im, fx - 1, fy) > 0.5 and a_at(im, fx + 1, fy) > 0.5 and a_at(im, fx, fy - 1) > 0.5 and a_at(im, fx, fy + 1) > 0.5:
				var lit: bool = im.get_pixel(fx, fy).get_luminance() > Color(ramp[3]).get_luminance()
				if not lit and rng.randf() < 0.6:
					continue
				px(im, fx - 1, fy, Color("fff8fa"))
				px(im, fx + 1, fy, Color("fff8fa"))
				px(im, fx, fy - 1, Color("ffffff"))
				px(im, fx, fy + 1, Color("f6dce6"))
				px(im, fx, fy, Color("f6c85a"))
				m += 1
		for i in range(18):
			var gx: int = int(cx + rng.randf_range(-R * 1.2, R * 1.2))
			var gy: int = base + rng.randi_range(-3, 3)
			if a_at(im, gx, gy) < 0.1:
				px(im, gx, gy, ramp[5])
				px(im, gx + 1, gy, ramp[4])
	grass_blades(im, cx, base + 1, 18.0, 26, L7_GREEN)
	clean_specks(im)
	outline_auto(im, 0.5)
	shadow(im, cx + 2.0, base + 2.0, w * 0.34, 5.0, 0.16)
	save3(im, name)


func gen_pine3(name: String, seed_v: int, w: int, h: int) -> void:
	rng.seed = seed_v
	var im: Image = new_img(w, h)
	var cx: float = w / 2.0
	var base: int = h - 7
	draw_trunk3(im, cx, h - 50, base, 4.5, seed_v)
	var tiers: int = 7
	var cl: Array = []
	for t in range(tiers):
		var ty: float = 14.0 + t * (h - 62.0) / (tiers - 1)
		var W: float = 8.0 + t * (w * 0.43 - 8.0) / (tiers - 1)
		var H: float = 9.0 + t * 1.5
		cl.append(Vector4(cx - W * 0.45, ty + 3.0, W * 0.6, H * 0.6))
		cl.append(Vector4(cx + W * 0.45, ty + 3.5, W * 0.6, H * 0.6))
		cl.append(Vector4(cx, ty, W * 0.62, H * 0.7))
	var under: Callable = func() -> void:
		for y in range(20, h - 50):
			px(im, int(cx), y, BARK7[2])
			px(im, int(cx) + 1, y, BARK7[1])
	leaf_canopy(im, cl, L7_PINE, seed_v, 8.5, 2.8, 2.7, 1.25, under)
	# макушка
	for k in range(8):
		var ti: int = 5 if k < 3 else 4
		px(im, int(cx), 4 + k, L7_PINE[ti])
		if k > 3:
			px(im, int(cx) - 1, 4 + k, L7_PINE[4])
			px(im, int(cx) + 1, 4 + k, L7_PINE[2])
	# шишки
	for i in range(5):
		var sx: int = int(cx + rng.randf_range(-w * 0.3, w * 0.3))
		var sy: int = int(rng.randf_range(h * 0.35, h * 0.7))
		if a_at(im, sx - 2, sy) > 0.5 and a_at(im, sx + 2, sy) > 0.5:
			px(im, sx, sy, BARK7[4])
			px(im, sx, sy + 1, BARK7[3])
			px(im, sx + 1, sy + 1, BARK7[2])
			px(im, sx, sy + 2, BARK7[2])
	grass_blades(im, cx, base + 1, 14.0, 18, L7_GREEN)
	clean_specks(im)
	outline_auto(im, 0.5)
	shadow(im, cx + 2.0, base + 2.0, w * 0.38, 4.0, 0.16)
	save3(im, name)


func gen_bush3(name: String, seed_v: int, flowers: int) -> void:
	rng.seed = seed_v
	var im: Image = new_img(60, 48)
	var cx: float = 30.0
	var cy: float = 27.0
	var R: float = 21.0
	var lay: Array = [[0.0, -0.42, 0.42, 0.38], [-0.46, -0.20, 0.40, 0.36], [0.46, -0.22, 0.40, 0.36], [-0.80, 0.14, 0.30, 0.30], [0.80, 0.12, 0.30, 0.30], [0.0, 0.0, 0.46, 0.38], [-0.38, 0.30, 0.40, 0.32], [0.38, 0.32, 0.40, 0.32]]
	var cl: Array = []
	for L0 in lay:
		var a: Array = L0
		cl.append(Vector4(cx + float(a[0]) * R + rng.randf_range(-1, 1), cy + float(a[1]) * R, float(a[2]) * R, float(a[3]) * R))
	cl.sort_custom(func(p: Vector4, q: Vector4) -> bool: return p.y < q.y)
	leaf_canopy(im, cl, L7_BUSH, seed_v, 6.0, 3.8, 2.9, 0.35)
	if flowers > 0:
		var fs: Array = hx(["b0506e", "e488a8", "fbd2e0"]) if flowers == 1 else hx(["cfc6d8", "f2eef4", "ffffff"])
		var n: int = 0
		var tries: int = 0
		while n < 10 and tries < 400:
			tries += 1
			var x: int = rng.randi_range(8, 52)
			var y: int = rng.randi_range(9, 38)
			if a_at(im, x - 2, y) > 0.5 and a_at(im, x + 2, y) > 0.5 and a_at(im, x, y - 2) > 0.5 and a_at(im, x, y + 2) > 0.5:
				flower5(im, x, y, fs, Color("f6d86a"))
				n += 1
	clean_specks(im)
	outline_auto(im, 0.5)
	shadow(im, 31, 44, 24, 3.5, 0.16)
	save3(im, name)


## Гранёный камень: несколько глыб, у каждой плоские грани (как на референсе).
## chunks: Vector4(cx, cy, r, высота-приоритет)
func faceted(im: Image, chunks: Array, ramp: Array, seed_v: int) -> PackedInt32Array:
	var w: int = im.get_width()
	var h: int = im.get_height()
	var own: PackedInt32Array = PackedInt32Array()
	own.resize(w * h)
	own.fill(-1)
	var facet: PackedInt32Array = PackedInt32Array()
	facet.resize(w * h)
	var shade: PackedFloat32Array = PackedFloat32Array()
	shade.resize(w * h)
	var depth: PackedFloat32Array = PackedFloat32Array()
	depth.resize(w * h)
	depth.fill(-1e9)
	for i in range(chunks.size()):
		var c: Vector4 = chunks[i]
		var nf: int = 6
		var dirs: Array = []
		var slopes: Array = []
		for k in range(nf):
			var ang: float = (k + h01(i, k, seed_v) * 0.6) / nf * TAU
			dirs.append(Vector2(cos(ang), sin(ang) * 1.25))
			slopes.append(lerpf(0.7, 1.5, h01(k, i, seed_v + 1)))
		# верхняя плоская грань
		dirs.append(Vector2(0.15, -1.0).normalized())
		slopes.append(0.35)
		for y in range(int(c.y - c.z * 1.4), int(c.y + c.z * 1.2)):
			for x in range(int(c.x - c.z * 1.5), int(c.x + c.z * 1.5)):
				if x < 0 or y < 0 or x >= w or y >= h:
					continue
				var p: Vector2 = Vector2(x + 0.5 - c.x, y + 0.5 - c.y)
				var best: float = -1e9
				var bk: int = 0
				for k2 in range(dirs.size()):
					var dv: float = p.dot(dirs[k2]) * float(slopes[k2])
					if dv > best:
						best = dv
						bk = k2
				var z: float = c.z - best + c.w
				if best > c.z:
					continue
				var idx: int = y * w + x
				if z > depth[idx]:
					depth[idx] = z
					own[idx] = i
					facet[idx] = i * 16 + bk
					var g: Vector2 = Vector2(dirs[bk]) * float(slopes[bk])
					var nv: Vector3 = Vector3(g.x, g.y, 1.0).normalized()
					shade[idx] = 0.5 + 0.55 * nv.dot(LT)
	for y in range(h):
		for x in range(w):
			var idx2: int = y * w + x
			if own[idx2] < 0:
				continue
			var v: float = shade[idx2]
			var ti: int = clampi(int((v - 0.24) * 7.6), 1, 6)
			# фактура: короткие штрихи-сколы вдоль грани
			if h01(x / 3, y, facet[idx2]) > 0.90 and ti > 1:
				ti -= 1
			elif h01(x / 2, y, facet[idx2] + 50) > 0.96 and ti < 6:
				ti += 1
			# стык глыб — тёмная щель
			var crev: bool = false
			for o in [Vector2i(1, 0), Vector2i(0, 1)]:
				var q: Vector2i = Vector2i(x, y) + o
				if q.x < w and q.y < h:
					var oq: int = own[q.y * w + q.x]
					if oq >= 0 and oq != own[idx2] and depth[q.y * w + q.x] > depth[idx2]:
						crev = true
			# светлое ребро сверху грани
			if y > 0 and own[idx2 - w] == own[idx2] and facet[idx2 - w] != facet[idx2] and shade[idx2] > shade[idx2 - w] + 0.12:
				ti = mini(6, ti + 1)
			if crev:
				ti = 0
			px(im, x, y, ramp[ti])
	return own


func moss_patch(im: Image, cx: float, cy: float, rx: float, ry: float, seed_v: int) -> void:
	for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
		for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
			var dx: float = (x + 0.5 - cx) / rx
			var dy: float = (y + 0.5 - cy) / ry
			var d: float = dx * dx + dy * dy + (h01(x / 2, y / 2, seed_v) - 0.5) * 0.9
			if d < 1.0 and a_at(im, x, y) > 0.5:
				var ti: int = 4 if dy < -0.1 else 3
				if d > 0.7:
					ti = 2 if dy > -0.2 else 5
				if h01(x, y, seed_v + 1) > 0.85:
					ti += 1
				px(im, x, y, L7_LIME[clampi(ti, 1, 6)])
	# свисающие кончики
	for k in range(int(rx)):
		var x2: int = int(cx - rx + k * 2)
		if a_at(im, x2, int(cy + ry) + 1) > 0.5 and h01(x2, 1, seed_v) > 0.5:
			px(im, x2, int(cy + ry) + 1, L7_LIME[2])


func gen_rock3() -> void:
	rng.seed = 44
	var im: Image = new_img(48, 40)
	faceted(im, [Vector4(25, 22, 13, 4), Vector4(14, 27, 8, 6), Vector4(35, 29, 7, 7), Vector4(23, 31, 6, 9)], ROCK6, 5)
	moss_patch(im, 23, 12, 9, 3.2, 3)
	moss_patch(im, 12, 21, 4.5, 2.0, 4)
	grass_blades(im, 8, 36, 4.0, 7, L7_GREEN)
	grass_blades(im, 40, 36, 4.0, 6, L7_GREEN)
	grass_blades(im, 25, 37, 6.0, 6, L7_GREEN)
	clean_specks(im)
	outline_auto(im, 0.45)
	shadow(im, 25, 37, 19, 2.5, 0.16)
	save3(im, "rock")
	# крупная скала для разнообразия
	rng.seed = 45
	var im2: Image = new_img(64, 52)
	faceted(im2, [Vector4(30, 24, 17, 3), Vector4(44, 30, 11, 6), Vector4(17, 33, 10, 7), Vector4(32, 39, 8, 10), Vector4(52, 41, 5, 11)], ROCK6_WARM, 9)
	moss_patch(im2, 28, 10, 12, 3.6, 7)
	moss_patch(im2, 15, 25, 4, 2.0, 9)
	grass_blades(im2, 10, 47, 5.0, 9, L7_GREEN)
	grass_blades(im2, 34, 48, 9.0, 10, L7_GREEN)
	grass_blades(im2, 57, 47, 3.0, 5, L7_GREEN)
	clean_specks(im2)
	outline_auto(im2, 0.45)
	shadow(im2, 33, 48, 26, 3.0, 0.16)
	save3(im2, "rock_big")


## Гриб: глянцевая шляпка-купол, пластинки снизу, ножка с юбочкой
func mushroom(im: Image, x: float, top: float, r: float, stem_h: float, cap: Array, spots: bool) -> void:
	var cy: float = top + r * 0.75
	# ножка
	var stem: Array = hx(["8c7e8a", "b4a8b0", "d6ccd0", "eee6e4", "fffaf6"])
	for y in range(int(cy), int(cy + stem_h)):
		var hw: float = r * 0.32 + (y - cy) / stem_h * r * 0.08
		for xx in range(int(x - hw), int(x + hw) + 1):
			var u: float = (xx + 0.5 - (x - hw)) / (2.0 * hw)
			px(im, xx, y, stem[3] if u < 0.35 else (stem[2] if u < 0.7 else stem[1]))
	# юбочка
	for xx2 in range(int(x - r * 0.42), int(x + r * 0.42) + 1):
		px(im, xx2, int(cy + stem_h * 0.3), stem[4])
		px(im, xx2, int(cy + stem_h * 0.3) + 1, stem[1])
	# пластинки (низ шляпки)
	for xx3 in range(int(x - r * 0.95), int(x + r * 0.95) + 1):
		for y2 in range(int(cy), int(cy + r * 0.28) + 1):
			var dxx: float = (xx3 + 0.5 - x) / r
			if absf(dxx) > 0.95 - (y2 - cy) / r * 1.6:
				continue
			px(im, xx3, y2, stem[1] if posmod(xx3, 2) == 0 else stem[2])
	# шляпка
	for y3 in range(int(top) - 1, int(cy) + 1):
		for xx4 in range(int(x - r) - 1, int(x + r) + 2):
			var dx: float = (xx4 + 0.5 - x) / r
			var dy: float = (y3 + 0.5 - cy) / (r * 0.78)
			if dy > 0.0 or dx * dx + dy * dy > 1.0:
				continue
			var nv: Vector3 = Vector3(dx, dy, sqrt(maxf(0.0, 1.0 - dx * dx - dy * dy))).normalized()
			var v: float = 0.45 + 0.6 * nv.dot(LT)
			var ti: int = clampi(int(v * 5.0), 0, 4)
			if dy > -0.12:
				ti = maxi(0, ti - 1)
			px(im, xx4, y3, cap[ti])
	# блик-полоска
	for k in range(int(r * 0.7)):
		var bx: int = int(x - r * 0.55 + k)
		var by: int = int(top + r * 0.28 - sin(float(k) / (r * 0.7) * PI) * r * 0.16)
		px(im, bx, by, cap[5])
	if spots:
		for s in [Vector2(0.25, 0.35), Vector2(-0.15, 0.55), Vector2(0.62, 0.62), Vector2(-0.55, 0.62)]:
			var sv: Vector2 = s
			var sx: int = int(x + sv.x * r)
			var sy: int = int(top + sv.y * r * 0.78)
			px(im, sx, sy, Color("fff6ee"))
			px(im, sx + 1, sy, Color("eadcd6"))
			if r > 6.0:
				px(im, sx, sy + 1, Color("eadcd6"))


func gen_mushrooms3() -> void:
	rng.seed = 77
	var m: Image = new_img(36, 30)
	var red: Array = hx(["5e1a2a", "8e2a36", "bc4044", "dc6656", "f09078", "ffd2c0"])
	var pink: Array = hx(["5a2a4a", "8a4068", "b8608a", "da88aa", "f0b4cc", "fff0f6"])
	mushroom(m, 24, 4, 8.0, 12.0, red, true)
	mushroom(m, 11, 10, 5.5, 9.0, red, true)
	mushroom(m, 31, 17, 3.6, 6.0, pink, false)
	grass_blades(m, 18, 27, 12.0, 12, L7_GREEN)
	clean_specks(m)
	outline_auto(m, 0.5)
	shadow(m, 19, 27, 15, 2.0, 0.2)
	save3(m, "mushrooms")


# ---------------------------------------------------------------- травы v3

func gen_crops3() -> void:
	var crops: Array = ["mint", "lavender", "chamomile", "nettle"]
	for crop in crops:
		for stage in range(4):
			rng.seed = 500 + stage * 7 + crops.find(crop) * 31
			var im: Image = new_img(32, 48)
			draw_crop3(im, String(crop), stage)
			clean_specks(im)
			outline_auto(im, 0.55)
			save3(im, "%s_%d" % [crop, stage], stage >= 2)


func soil_mound(im: Image, cx: float, cy: float, rx: float, ry: float) -> void:
	var soil: Array = hx(["2e1e1e", "4a2e26", "64402e", "7e5638", "9a6e46", "b88a5a"])
	for y in range(int(cy - ry) - 1, int(cy + ry) + 1):
		for x in range(int(cx - rx) - 1, int(cx + rx) + 1):
			var dx: float = (x + 0.5 - cx) / rx
			var dy: float = (y + 0.5 - cy) / ry
			if dx * dx + dy * dy > 1.0 or dy > 0.6:
				continue
			var ti: int = 4 if dy < -0.4 else (3 if dy < 0.1 else 2)
			if dx > 0.5:
				ti -= 1
			if h01(x, y, 7) > 0.85:
				ti += 1
			px(im, x, y, soil[clampi(ti, 0, 5)])


func draw_crop3(im: Image, crop: String, stage: int) -> void:
	soil_mound(im, 16, 44, 10, 3.5)
	if stage == 0:
		for k in range(3):
			var sx: int = 11 + k * 4
			px(im, sx, 42, Color("f2dca8"))
			px(im, sx + 1, 42, Color("c8a46a"))
			px(im, sx, 43, Color("a8844e"))
		return
	if stage == 1:
		for y in range(35, 44):
			px(im, 16, y, L7_MINT[4] if y < 40 else L7_MINT[3])
		draw_leaf(im, Vector2(12.5, 34), Vector2(-1, -0.5), 7.0, 4.6, 5, L7_MINT, true)
		draw_leaf(im, Vector2(19.5, 33), Vector2(1, -0.6), 7.0, 4.6, 4, L7_MINT, true)
		return
	match crop:
		"mint":
			var cs: Array = []
			if stage == 2:
				cs = [Vector4(16, 32, 7, 6), Vector4(10, 37, 6, 5), Vector4(22, 37, 6, 5)]
			else:
				cs = [Vector4(16, 17, 6, 6), Vector4(10, 25, 7, 6), Vector4(22, 25, 7, 6), Vector4(16, 30, 8, 7), Vector4(8, 36, 7, 6), Vector4(24, 36, 7, 6), Vector4(16, 39, 8, 5)]
			cs.sort_custom(func(p: Vector4, q: Vector4) -> bool: return p.y < q.y)
			var under: Callable = func() -> void:
				for y in range(18 if stage == 3 else 30, 44):
					px(im, 16, y, L7_MINT[2])
			leaf_canopy(im, cs, L7_MINT, 3 + stage, 6.0, 4.8, 3.2, 0.2, under, [], true)
			if stage == 3:
				for p in [Vector2i(9, 18), Vector2i(23, 19), Vector2i(16, 9)]:
					var pp: Vector2i = p
					for k in range(6):
						var c1: Color = Color("e6dcf8") if k % 2 == 0 else Color("c4b4ee")
						px(im, pp.x, pp.y + k, c1)
						px(im, pp.x - 1, pp.y + k, Color("a898dc") if k % 2 == 1 else Color("d4c8f4"))
						px(im, pp.x + 1, pp.y + k, Color("9888cc"))
		"lavender":
			# серо-зелёные узкие листья пучком
			for k in range(16):
				var ang0: float = PI + 0.2 + k / 15.0 * (PI - 0.4)
				var ln0: float = rng.randf_range(7.0, 11.0)
				draw_leaf(im, Vector2(16 + cos(ang0) * ln0 * 0.5, 42 + sin(ang0) * ln0 * 0.5), Vector2(cos(ang0), sin(ang0)), ln0, 2.4, 3 + (k % 3), L7_SAGE)
			var tops: Array = [Vector2i(11, 24), Vector2i(16, 20), Vector2i(21, 24)]
			if stage == 3:
				tops = [Vector2i(5, 12), Vector2i(10, 6), Vector2i(16, 3), Vector2i(22, 6), Vector2i(27, 12), Vector2i(13, 15), Vector2i(19, 14)]
			var lav: Array = hx(["2e2050", "443276", "5c489a", "7660b8", "927ed0", "b4a2e4", "d8ccf6"])
			for tp in tops:
				var tv: Vector2i = tp
				var len0: int = 12 if stage == 3 else 6
				var steps: int = 38 - (tv.y + len0) + 1
				for k2 in range(maxi(1, steps)):
					var t: float = float(k2) / float(maxi(1, steps))
					var xx: int = int(round(lerpf(16.0, float(tv.x), t * t)))
					px(im, xx, 38 - k2, L7_SAGE[4] if k2 % 4 != 0 else L7_SAGE[3])
				for y in range(tv.y, tv.y + len0):
					var row: int = y - tv.y
					var mid: bool = posmod(row, 3) != 2
					var ti2: int = 6 if row < 2 else (5 if row < 5 else 4)
					if stage == 2:
						ti2 = 2
					if mid:
						px(im, tv.x - 1, y, lav[ti2 - 1] if stage == 3 else L7_SAGE[3])
						px(im, tv.x, y, lav[ti2] if stage == 3 else lav[3])
						px(im, tv.x + 1, y, lav[ti2 - 2] if stage == 3 else L7_SAGE[2])
					else:
						px(im, tv.x, y, lav[ti2 - 2] if stage == 3 else L7_SAGE[3])
				px(im, tv.x, tv.y - 1, lav[6] if stage == 3 else lav[4])
		"chamomile":
			# перистые листья: тонкие стебельки с мелкими зубчиками
			for k in range(9):
				var ang1: float = PI + 0.35 + k / 8.0 * (PI - 0.7)
				var ln1: float = rng.randf_range(7.0, 10.0)
				for j in range(int(ln1)):
					var lx: int = int(round(16 + cos(ang1) * j))
					var ly: int = int(round(43 + sin(ang1) * j))
					px(im, lx, ly, L7_MINT[3])
					if j % 2 == 1:
						px(im, lx + (1 if cos(ang1) > 0 else -1), ly - 1, L7_MINT[5])
						px(im, lx, ly + 1, L7_MINT[2])
			var heads: Array = [Vector2i(16, 25)]
			if stage == 3:
				heads = [Vector2i(8, 20), Vector2i(16, 12), Vector2i(24, 18), Vector2i(12, 28), Vector2i(21, 29)]
			for hpos in heads:
				var hp: Vector2i = hpos
				var steps2: int = 42 - hp.y
				for k3 in range(steps2):
					var t2: float = float(k3) / float(steps2)
					px(im, int(round(lerpf(16.0, float(hp.x), sqrt(t2)))), 42 - k3, L7_MINT[3] if k3 % 5 != 0 else L7_MINT[4])
				if stage == 2:
					ball(im, hp.x, hp.y, 2.4, 2.2, [L7_MINT[2], L7_MINT[4], L7_MINT[5], L7_MINT[6]], 0.1)
					px(im, hp.x, hp.y - 2, Color("fff8ea"))
				else:
					# лепестки лучами, нижние в тени
					for a in range(12):
						var ang: float = a / 12.0 * TAU
						for rr in [2.4, 3.4, 4.2]:
							var ex: int = hp.x + int(round(cos(ang) * float(rr)))
							var ey: int = hp.y + int(round(sin(ang) * float(rr) * 0.7))
							var pc: Color = Color("fffcf4") if sin(ang) < 0.0 else (Color("eae2e8") if sin(ang) < 0.6 else Color("c8bccc"))
							px(im, ex, ey, pc)
					ball(im, hp.x, hp.y - 0.5, 2.0, 1.7, hx(["a8701a", "d89a28", "f2c23a", "fde27a"]), 0.15)
		"nettle":
			var top2: int = 22 if stage == 2 else 6
			for y in range(top2, 44):
				px(im, 16, y, L7_NETTLE[3])
				px(im, 17, y, L7_NETTLE[2])
			var yy: int = 38
			var size: float = 12.0 if stage == 3 else 9.0
			var tone0: int = 2
			var flip: float = 1.0
			while yy > top2 + 4:
				for side in [-1, 1]:
					var s: float = float(side)
					var dir: Vector2 = Vector2(s, 0.30 + 0.12 * flip * s)
					var c: Vector2 = Vector2(16.5 + s * size * 0.48, yy + 2.0)
					nettle_leaf(im, c, dir, size, size * 0.72, tone0 + (1 if s < 0 else 0))
				flip = -flip
				yy -= 8
				size = maxf(6.0, size - 1.8)
				tone0 = mini(5, tone0 + 1)
			nettle_leaf(im, Vector2(16.5, top2 + 2), Vector2(0, -1), 6.0, 4.4, 5)


## Лист крапивы: сердцевидный, с зубчатым краем и жилкой
func nettle_leaf(im: Image, c: Vector2, dir: Vector2, L: float, W: float, t: int) -> void:
	var d: Vector2 = dir.normalized()
	var pp: Vector2 = Vector2(-d.y, d.x)
	var b: Vector2 = c - d * L * 0.45
	var r: int = int(ceil(L)) + 1
	for y in range(int(c.y) - r, int(c.y) + r + 1):
		for x in range(int(c.x) - r, int(c.x) + r + 1):
			var q: Vector2 = Vector2(x + 0.5, y + 0.5) - b
			var u: float = q.dot(d) / L
			if u < 0.0 or u > 1.0:
				continue
			var vv: float = q.dot(pp)
			var half: float = W * 0.5 * pow(sin(PI * pow(u, 0.6)), 0.8)
			# зубчики
			half -= (0.5 + 0.5 * sin(u * L * 1.9)) * 0.7 * u
			if absf(vv) > half:
				continue
			var ti: int = t
			var lit: bool = (pp * signf(vv + 0.001)).dot(LT2) > 0.0
			if absf(vv) > half - 1.0:
				ti = t + 1 if lit else t - 1
			elif absf(vv) < 0.55 and u < 0.85:
				ti = t + 1
			elif posmod(int(u * L), 3) == 0 and absf(vv) < half * 0.7:
				ti = t - 1
			px(im, x, y, L7_NETTLE[clampi(ti, 0, 6)])


# ---------------------------------------------------------------- мешочки семян v3

func gen_seed_pouch3() -> void:
	var tints: Dictionary = {"mint": L7_MINT, "lavender": hx(["2e2050", "443276", "5c489a", "7660b8", "927ed0", "b4a2e4", "d8ccf6"]), "chamomile": hx(["6a4410", "94621a", "c08a26", "e0b034", "f4cc4a", "fce27a", "fff3c0"])}
	var sack: Array = hx(["4a3226", "6a4a32", "8a6640", "a8824e", "c4a064", "dcbe84", "eedaaa"])
	for k in tints.keys():
		var im: Image = new_img(32, 32)
		var tc: Array = tints[k]
		# тело мешка: мешковина с плетением и складками
		for y in range(11, 30):
			var t: float = (y - 11) / 19.0
			var hw: float = 6.5 + sin(t * PI * 0.85) * 6.5
			if y > 27:
				hw -= (y - 27) * 1.5
			for x in range(int(16 - hw), int(16 + hw) + 1):
				var u: float = (x + 0.5 - (16 - hw)) / (2.0 * hw)
				var nv: float = 0.86 - u * 0.62 + sin(u * PI) * 0.12 - t * 0.12
				var ti: int = clampi(int(nv * 6.0), 1, 6)
				# плетение
				if posmod(x + (y / 2) * 1, 3) == 0 and posmod(y, 2) == 0:
					ti -= 1
				# складки от завязки
				if y < 17 and (x == 13 or x == 19) :
					ti -= 1
				px(im, x, y, sack[clampi(ti, 0, 6)])
		# горловина
		for y2 in range(4, 10):
			var hw2: float = 3.0 + (9 - y2) * 0.7
			for x2 in range(int(16 - hw2), int(16 + hw2) + 1):
				var u2: float = (x2 + 0.5 - (16 - hw2)) / (2.0 * hw2)
				var ti2: int = 5 if u2 < 0.3 else (4 if u2 < 0.6 else 3)
				if posmod(x2, 2) == 0 and y2 < 6:
					ti2 -= 1
				px(im, x2, y2, sack[ti2])
		# верёвка
		for x3 in range(10, 23):
			px(im, x3, 10, Color("e6c88e") if posmod(x3, 2) == 0 else Color("b8945c"))
			px(im, x3, 11, Color("8a6a40"))
		px(im, 9, 11, Color("b8945c"))
		px(im, 22, 12, Color("e6c88e"))
		px(im, 23, 13, Color("b8945c"))
		px(im, 23, 14, Color("e6c88e"))
		px(im, 24, 15, Color("8a6a40"))
		# семена высыпаются сверху
		for s in [Vector2i(14, 3), Vector2i(16, 2), Vector2i(18, 3), Vector2i(15, 4), Vector2i(17, 4)]:
			var sv: Vector2i = s
			px(im, sv.x, sv.y, tc[5])
			px(im, sv.x, sv.y + 1, tc[3])
		# бирка с рисунком
		for y4 in range(16, 27):
			for x4 in range(10, 22):
				var edge: bool = x4 == 10 or x4 == 21 or y4 == 16 or y4 == 26
				var cc: Color = Color("cbb898") if edge else (Color("fbf4e2") if y4 < 19 else Color("f2e8d0"))
				px(im, x4, y4, cc)
		px(im, 11, 17, Color("8a6a40"))
		# мини-листик/цветок на бирке
		if k == "mint":
			draw_leaf(im, Vector2(16, 21.5), Vector2(1, -0.4), 7.0, 4.4, 4, tc, true)
		elif k == "lavender":
			for y5 in range(18, 24):
				var mid: bool = y5 % 2 == 0
				px(im, 16, y5, tc[5] if y5 < 20 else tc[4])
				px(im, 15, y5, tc[3] if mid else tc[2])
				px(im, 17, y5, tc[2] if mid else tc[1])
			px(im, 16, 17, tc[6])
			px(im, 16, 24, L7_SAGE[3])
			px(im, 16, 25, L7_SAGE[2])
			px(im, 15, 25, L7_SAGE[4])
		else:
			for a in range(8):
				var ang: float = a / 8.0 * TAU
				var ex: int = 16 + int(round(cos(ang) * 3.0))
				var ey: int = 21 + int(round(sin(ang) * 3.0))
				px(im, ex, ey, Color("b8aeb8"))
				px(im, 16 + int(round(cos(ang) * 2.0)), 21 + int(round(sin(ang) * 2.0)), Color("ffffff") if sin(ang) < 0.3 else Color("e2dae0"))
			px(im, 16, 21, tc[4])
			px(im, 15, 21, tc[5])
			px(im, 16, 22, tc[2])
			px(im, 17, 21, tc[3])
		clean_specks(im)
		outline_auto(im, 0.55)
		save3(im, "seeds_%s" % k)


func gen_v3() -> void:
	gen_tree3("tree_a", 11, 128, 160, L7_GREEN)
	gen_tree3("tree_b", 23, 136, 168, L7_LIME)
	gen_tree3("tree_c", 37, 120, 152, L7_DEEP)
	gen_tree3("tree_d", 41, 152, 188, L7_GREEN)
	gen_tree3("tree_blossom", 51, 128, 160, L7_BLOSSOM, "blossom")
	gen_tree3("tree_autumn", 61, 124, 156, L7_AUTUMN)
	gen_tree3("tree_apple", 71, 120, 150, L7_LIME, "apples")
	gen_pine3("pine_a", 5, 84, 156)
	gen_pine3("pine_b", 15, 72, 132)
	gen_bush3("bush_a", 3, 0)
	gen_bush3("bush_b", 8, 1)
	gen_bush3("bush_c", 13, 2)
	gen_rock3()
	gen_mushrooms3()
	gen_crops3()
	gen_seed_pouch3()


# ================================================================== v3: героиня и кот

var SKIN7: Array
var HAIR7: Array
var CAPE7: Array
var DRESS7: Array
var BLOUSE7: Array
var LEATH7: Array
var CAT7: Array
var FUR7: Array


func _palettes_hero() -> void:
	SKIN7 = hx(["6e3a40", "a2564e", "cc7c66", "e8a184", "f6c4a4", "fddcc4", "fff0e4"])
	HAIR7 = hx(["34162a", "582430", "823634", "aa4c36", "cc6a3e", "e68e50", "f6b878"])
	CAPE7 = hx(["1a2e36", "254644", "33604e", "467c58", "639a66", "88b67a", "b6d29c"])
	DRESS7 = hx(["2a1c36", "42284a", "5e385c", "7a4c6c", "98687e", "b88a96", "d8b0b6"])
	BLOUSE7 = hx(["5e5466", "8c808a", "b8aca6", "d8ccbc", "eee4d2", "faf4e6", "ffffff"])
	LEATH7 = hx(["24161e", "3c2428", "583630", "764c3c", "94664c", "b28460", "d0a47a"])
	CAT7 = hx(["4e2228", "7e3a2c", "ae5630", "d27c3c", "eaa252", "f6c47c", "fde2b0"])
	FUR7 = hx(["6a5e70", "968a94", "beb2b4", "dcd2ce", "f0e8e0", "fbf7f0", "ffffff"])


## Тон по сферическому свету в эллипсе: tb ± 2
func blob(im: Image, cx: float, cy: float, rx: float, ry: float, ramp: Array, tb: int, stripe: Vector3 = Vector3.ZERO, lo: int = 0) -> void:
	for y in range(int(floor(cy - ry)) - 1, int(ceil(cy + ry)) + 1):
		for x in range(int(floor(cx - rx)) - 1, int(ceil(cx + rx)) + 1):
			var nx: float = (x + 0.5 - cx) / rx
			var ny: float = (y + 0.5 - cy) / ry
			var d2: float = nx * nx + ny * ny
			if d2 > 1.0:
				continue
			var nv: Vector3 = Vector3(nx, ny, sqrt(1.0 - d2)).normalized()
			var l: float = nv.dot(LT)
			var t: int = tb + int(round(l * 2.4 - 0.4))
			if d2 > 0.82 and ny > 0.0:
				t -= 1
			if stripe != Vector3.ZERO and ny < 0.55:
				if sin((x - cx) * stripe.x + (y - cy) * stripe.y + stripe.z) > 0.72:
					t -= 2
			px(im, x, y, ramp[clampi(t, lo, ramp.size() - 1)])


## Цилиндр/юбка: ряды с полушириной от hw0 до hw1, свет слева
func rows(im: Image, cx: float, y0: int, y1: int, hw0: float, hw1: float, ramp: Array, tb: int, folds: Array = [], sway: float = 0.0) -> void:
	for y in range(y0, y1 + 1):
		var t: float = float(y - y0) / float(maxi(1, y1 - y0))
		var hw: float = lerpf(hw0, hw1, t)
		var c: float = cx + sway * t * t
		for x in range(int(floor(c - hw)), int(ceil(c + hw))):
			var u: float = (x + 0.5 - (c - hw)) / (2.0 * hw)
			var ti: int = tb + 1 if u < 0.28 else (tb if u < 0.7 else (tb - 1 if u < 0.9 else tb - 2))
			for fu in folds:
				var fv: float = fu
				if t > 0.25 and absf(u - fv) < 0.5 / hw:
					ti -= 1
				elif t > 0.25 and absf(u - fv - 1.0 / hw) < 0.5 / hw:
					ti += 1
			if y == y1:
				ti -= 1
			px(im, x, y, ramp[clampi(ti, 0, ramp.size() - 1)])


func hero_boots(im: Image, x0: int, y0: int, w: int, toe_left: bool) -> void:
	for y in range(y0, y0 + 4):
		for x in range(x0, x0 + w):
			var u: float = float(x - x0) / float(w)
			var ti: int = 4 if u < 0.35 else (3 if u < 0.75 else 2)
			if y == y0:
				ti += 1
			if y == y0 + 3:
				ti = 1
			px(im, x, y, LEATH7[clampi(ti - 1, 0, 6)])
	if toe_left:
		px(im, x0 - 1, y0 + 2, LEATH7[2])
		px(im, x0 - 1, y0 + 3, LEATH7[0])


func hero_eye(im: Image, x: int, y: int) -> void:
	px(im, x, y, Color("2a1a2c"))
	px(im, x + 1, y, Color("2a1a2c"))
	px(im, x, y + 1, Color("ffffff"))
	px(im, x + 1, y + 1, Color("3e5a7a"))
	px(im, x, y + 2, Color("5c86a8"))
	px(im, x + 1, y + 2, Color("8ab4d2"))


## Коса: цепочка звеньев от a к b с качанием
func braid(im: Image, a: Vector2, b: Vector2, sway: float) -> void:
	var n: int = int(a.distance_to(b) / 2.2) + 1
	for i in range(n):
		var t: float = float(i) / float(maxi(1, n - 1))
		var p: Vector2 = a.lerp(b, t) + Vector2(sway * t * t, 0)
		var r: float = lerpf(2.4, 1.7, t)
		blob(im, p.x + (0.5 if i % 2 == 0 else -0.5), p.y, r, 1.6, HAIR7, 4 if i % 2 == 0 else 3)
	var e: Vector2 = b + Vector2(sway, 0)
	# лента и кисточка
	px(im, int(e.x) - 1, int(e.y) + 1, Color("e8828a"))
	px(im, int(e.x), int(e.y) + 1, Color("c45a6a"))
	px(im, int(e.x) + 1, int(e.y) + 1, Color("e8828a"))
	px(im, int(e.x), int(e.y) + 2, HAIR7[4])
	px(im, int(e.x) - 1, int(e.y) + 3, HAIR7[3])
	px(im, int(e.x) + 1, int(e.y) + 3, HAIR7[2])


func hair_flower(im: Image, x: int, y: int) -> void:
	px(im, x, y - 1, Color("fff4f6"))
	px(im, x - 1, y, Color("f6c6d4"))
	px(im, x + 1, y, Color("f6c6d4"))
	px(im, x, y + 1, Color("e49ab2"))
	px(im, x, y, Color("f6d26a"))
	px(im, x + 2, y + 1, CAPE7[5])


## Пелерина с зубчатым (листовым) краем
func capelet(im: Image, cx: float, y0: int, y1: int, hw0: float, hw1: float) -> void:
	for y in range(y0, y1 + 1):
		var t: float = float(y - y0) / float(maxi(1, y1 - y0))
		var hw: float = lerpf(hw0, hw1, sqrt(t))
		for x in range(int(floor(cx - hw)), int(ceil(cx + hw))):
			var u: float = (x + 0.5 - (cx - hw)) / (2.0 * hw)
			if y >= y1 - 1:
				# зубчики: каждые 3 пикселя
				var k: int = posmod(x - int(cx) + 1, 3)
				if y == y1 and k != 1:
					continue
			var ti: int = 5 if u < 0.25 else (4 if u < 0.62 else (3 if u < 0.86 else 2))
			if y == y0:
				ti += 1
			if y >= y1 - 1:
				ti -= 1
			px(im, x, y, CAPE7[clampi(ti, 0, 6)])


func draw_hero3(im: Image, dir: int, f: int) -> void:
	var b: int = -1 if (f == 1 or f == 3) else 0
	var sw: float = 1.0 if f == 0 else (-1.0 if f == 2 else 0.0)
	if dir == 0:
		_hero_front(im, f, b, sw)
	elif dir == 1:
		_hero_back(im, f, b, sw)
	else:
		_hero_side(im, f, b, sw)


func _hero_front(im: Image, f: int, b: int, sw: float) -> void:
	# ноги/сапожки
	var ll: int = -1 if f == 2 else 0
	var lr: int = -1 if f == 0 else 0
	hero_boots(im, 11, 43 + ll, 4, false)
	hero_boots(im, 17, 43 + lr, 4, false)
	# юбка
	rows(im, 16, 29 + b, 43, 5.5, 9.5, DRESS7, 4, [0.3, 0.55, 0.78], sw)
	# фартук с карманом и веточкой
	for y in range(31 + b, 42):
		var t: float = float(y - 31 - b) / 11.0
		var hw: float = lerpf(3.5, 4.5, t)
		var c: float = 16.0 + sw * t * t
		for x in range(int(floor(c - hw)), int(ceil(c + hw))):
			var u: float = (x + 0.5 - (c - hw)) / (2.0 * hw)
			var ti: int = 5 if u < 0.3 else (4 if u < 0.75 else 3)
			if y == 41:
				ti = 3 if posmod(x, 2) == 0 else 2
			px(im, x, y, BLOUSE7[ti])
	for x in range(14, 18):
		px(im, x, 36 + b, BLOUSE7[2])
	px(im, 14, 37 + b, BLOUSE7[3])
	px(im, 17, 37 + b, BLOUSE7[3])
	px(im, 15, 35 + b, CAPE7[5])
	px(im, 15, 34 + b, CAPE7[4])
	px(im, 16, 34 + b, CAPE7[5])
	px(im, 16, 33 + b, CAPE7[6])
	px(im, 14, 34 + b, CAPE7[3])
	# корсаж со шнуровкой
	rows(im, 16, 25 + b, 31 + b, 4.6, 5.2, LEATH7, 4)
	for y in range(26 + b, 31 + b):
		px(im, 15 + (y % 2), y, BLOUSE7[5])
	px(im, 16, 31 + b, BLOUSE7[4])
	# ремень сумки и сумка справа
	for i in range(12):
		px(im, 10 + i, 22 + b + i, LEATH7[4])
		px(im, 11 + i, 22 + b + i, LEATH7[3])
	for y in range(32 + b, 39 + b):
		for x in range(21, 27):
			var ti2: int = 5 if x < 23 else (4 if x < 25 else 3)
			if y == 34 + b:
				ti2 = 2
			if y < 34 + b:
				ti2 += 1
			px(im, x, y, LEATH7[clampi(ti2, 0, 6)])
	px(im, 23, 35 + b, Color("e6c458"))
	px(im, 23, 36 + b, Color("b28828"))
	# рукава-фонарики и руки
	var hs: int = 1 if f == 0 else (-1 if f == 2 else 0)
	blob(im, 8.5, 26 + b, 3.0, 3.2, BLOUSE7, 4)
	blob(im, 23.5, 26 + b, 3.0, 3.2, BLOUSE7, 3)
	rows(im, 8, 28 + b, 31 + b + hs, 1.6, 1.5, BLOUSE7, 4)
	rows(im, 24, 28 + b, 31 + b - hs, 1.6, 1.5, BLOUSE7, 3)
	blob(im, 8, 32.5 + b + hs, 1.8, 1.6, SKIN7, 4)
	blob(im, 24, 32.5 + b - hs, 1.8, 1.6, SKIN7, 3)
	# пелерина и застёжка
	capelet(im, 16, 20 + b, 26 + b, 6.0, 9.0)
	px(im, 16, 21 + b, Color("f6e08a"))
	px(im, 15, 21 + b, Color("d0a83a"))
	px(im, 16, 22 + b, Color("8e661c"))
	# волосы сзади (по бокам лица до плеч)
	blob(im, 16, 12 + b, 8.4, 8.6, HAIR7, 3)
	for y in range(13 + b, 23 + b):
		px(im, 8, y, HAIR7[3])
		px(im, 9, y, HAIR7[4])
		px(im, 23, y, HAIR7[2])
	# шея и лицо
	px(im, 15, 19 + b, SKIN7[3])
	px(im, 16, 19 + b, SKIN7[3])
	px(im, 17, 19 + b, SKIN7[2])
	blob(im, 16, 13.6 + b, 6.3, 6.2, SKIN7, 4, Vector3.ZERO, 2)
	# чёлка прядками
	var fr: Array = [3, 4, 5, 3, 4, 6, 3, 2, 3, 5, 4, 3, 4, 3]
	for i in range(fr.size()):
		var x2: int = 9 + i
		for k in range(int(fr[i]) + 4):
			var y2: int = 5 + b + k
			var ti3: int = 5 - k / 2
			if k == 1 and i > 1 and i < 9:
				ti3 = 6
			if k == int(fr[i]) + 3:
				ti3 = 2
			px(im, x2, y2, HAIR7[clampi(ti3, 1, 6)])
	for x3 in range(10, 22):
		px(im, x3, 4 + b, HAIR7[4] if x3 < 17 else HAIR7[3])
	# глаза, румянец, рот
	hero_eye(im, 12, 13 + b)
	hero_eye(im, 18, 13 + b)
	px(im, 11, 16 + b, Color("f29a96"))
	px(im, 12, 16 + b, Color("f6b0a8"))
	px(im, 20, 16 + b, Color("f6b0a8"))
	px(im, 21, 16 + b, Color("f29a96"))
	px(im, 16, 15 + b, SKIN7[3])
	px(im, 15, 17 + b, Color("b85a56"))
	px(im, 16, 17 + b, Color("d0706a"))
	# коса через правое плечо
	braid(im, Vector2(21.5, 15 + b), Vector2(22.5, 31 + b), -sw * 0.5)
	hair_flower(im, 10, 6 + b)


func _hero_back(im: Image, f: int, b: int, sw: float) -> void:
	var ll: int = -1 if f == 2 else 0
	var lr: int = -1 if f == 0 else 0
	hero_boots(im, 11, 43 + ll, 4, false)
	hero_boots(im, 17, 43 + lr, 4, false)
	rows(im, 16, 29 + b, 43, 5.5, 9.5, DRESS7, 3, [0.25, 0.5, 0.75], sw)
	rows(im, 16, 25 + b, 31 + b, 4.6, 5.2, LEATH7, 3)
	# бант фартука на спине
	blob(im, 13.5, 30 + b, 2.0, 1.5, BLOUSE7, 4)
	blob(im, 18.5, 30 + b, 2.0, 1.5, BLOUSE7, 3)
	px(im, 16, 30 + b, BLOUSE7[2])
	px(im, 15, 30 + b, BLOUSE7[4])
	px(im, 13, 32 + b, BLOUSE7[4])
	px(im, 13, 33 + b, BLOUSE7[3])
	px(im, 19, 32 + b, BLOUSE7[3])
	px(im, 19, 33 + b, BLOUSE7[2])
	# сумка слева
	for y in range(32 + b, 39 + b):
		for x in range(5, 11):
			var ti2: int = 4 if x < 8 else 3
			if y == 34 + b:
				ti2 = 2
			px(im, x, y, LEATH7[ti2])
	var hs: int = 1 if f == 0 else (-1 if f == 2 else 0)
	blob(im, 8.5, 26 + b, 3.0, 3.2, BLOUSE7, 3)
	blob(im, 23.5, 26 + b, 3.0, 3.2, BLOUSE7, 2)
	rows(im, 8, 28 + b, 31 + b - hs, 1.6, 1.5, BLOUSE7, 3)
	rows(im, 24, 28 + b, 31 + b + hs, 1.6, 1.5, BLOUSE7, 2)
	blob(im, 8, 32.5 + b - hs, 1.8, 1.6, SKIN7, 3)
	blob(im, 24, 32.5 + b + hs, 1.8, 1.6, SKIN7, 2)
	capelet(im, 16, 20 + b, 27 + b, 6.5, 9.2)
	# сложенный капюшон
	blob(im, 16, 21.5 + b, 5.0, 2.6, CAPE7, 3)
	for x in range(13, 20):
		px(im, x, 21 + b, CAPE7[2])
	# ремень по диагонали
	for i in range(11):
		px(im, 21 - i, 22 + b + i, LEATH7[3])
		px(im, 22 - i, 22 + b + i, LEATH7[2])
	# затылок: волосы до плеч, пряди вертикальными линиями, блик-дуга
	rows(im, 16, 13 + b, 23 + b, 8.2, 7.0, HAIR7, 3)
	blob(im, 16, 12 + b, 8.4, 8.6, HAIR7, 3)
	for y in range(5 + b, 24 + b):
		for x in range(8, 25):
			if a_at(im, x, y) < 0.5:
				continue
			var cur: Color = im.get_pixel(x, y)
			if posmod(x, 3) == 1 and y > 7 + b:
				px(im, x, y, cur.darkened(0.18))
			var arc: float = absf(Vector2((x - 15.0) / 6.5, (y - 9.0 - b) / 3.2).length() - 1.0)
			if arc < 0.22 and y < 11 + b:
				px(im, x, y, HAIR7[5] if x < 17 else HAIR7[4])
	for x2 in range(9, 24):
		if posmod(x2, 2) == 0:
			px(im, x2, 24 + b, HAIR7[2])
	# коса по центру спины
	braid(im, Vector2(16, 17 + b), Vector2(16, 33 + b), sw * 0.6)
	hair_flower(im, 21, 7 + b)


func _hero_side(im: Image, f: int, b: int, sw: float) -> void:
	# шаг: переднее и заднее колено
	var fd: int = -3 if f == 0 else (3 if f == 2 else 0)
	hero_boots(im, 16 + fd, 43, 4, true)
	hero_boots(im, 15 - fd, 43 - (1 if f == 1 or f == 3 else 0), 4, true)
	rows(im, 16.5, 29 + b, 43, 4.8, 7.8, DRESS7, 4, [0.35, 0.7], -sw * 0.8)
	# край фартука спереди
	for y in range(31 + b, 42):
		var t: float = float(y - 31 - b) / 11.0
		var x0: int = int(floor(16.5 - lerpf(4.8, 7.8, (y - 29 - b) / float(14 - b)) - sw * 0.8 * t * t))
		px(im, x0, y, BLOUSE7[5])
		px(im, x0 + 1, y, BLOUSE7[4])
		px(im, x0 + 2, y, BLOUSE7[3])
	rows(im, 16.5, 25 + b, 31 + b, 3.8, 4.4, LEATH7, 4)
	# сумка сзади
	for y in range(31 + b, 38 + b):
		for x in range(20, 26):
			var ti2: int = 4 if x < 22 else 3
			if y == 33 + b:
				ti2 = 2
			if y < 33 + b:
				ti2 += 1
			px(im, x, y, LEATH7[ti2])
	px(im, 22, 34 + b, Color("e6c458"))
	for y2 in range(22 + b, 31 + b):
		px(im, 19, y2, LEATH7[4])
		px(im, 20, y2, LEATH7[3])
	capelet(im, 16.5, 20 + b, 26 + b, 4.8, 6.8)
	# рука качается
	var hx0: float = 16.5 - sw * 3.5
	blob(im, 16.5, 25 + b, 2.8, 2.6, BLOUSE7, 4)
	var hand: Vector2 = Vector2(hx0, 31.5 + b)
	var n: int = 6
	for i in range(n):
		var p: Vector2 = Vector2(16.5, 26 + b).lerp(hand, float(i) / float(n))
		blob(im, p.x, p.y, 1.6, 1.4, BLOUSE7, 4)
	blob(im, hand.x, hand.y + 0.5, 1.8, 1.6, SKIN7, 4)
	# коса сзади
	braid(im, Vector2(20.5, 15 + b), Vector2(21.5 + sw * 0.4, 29 + b), sw * 0.8)
	# голова в профиль (смотрит влево)
	blob(im, 16.5, 12 + b, 7.8, 8.4, HAIR7, 3)
	blob(im, 13.5, 13.8 + b, 5.6, 6.0, SKIN7, 4, Vector3.ZERO, 2)
	px(im, 7, 14 + b, SKIN7[4])
	px(im, 7, 15 + b, SKIN7[3])
	px(im, 8, 16 + b, SKIN7[3])
	# волосы: макушка и чёлка
	for x in range(9, 22):
		var ln: int = 2 + int(h01(x, 3, 7) * 3.0)
		if x > 15:
			ln += 6
		for k in range(ln + 1):
			var ti3: int = 5 - k / 2
			if k == 1 and x < 15:
				ti3 = 6
			if k == ln:
				ti3 = 2
			px(im, x, 5 + b + k, HAIR7[clampi(ti3, 1, 6)])
	for x2 in range(10, 21):
		px(im, x2, 4 + b, HAIR7[4])
	for y3 in range(11 + b, 21 + b):
		px(im, 16, y3, HAIR7[3])
		px(im, 17, y3, HAIR7[2])
	# ухо
	px(im, 15, 15 + b, SKIN7[3])
	px(im, 15, 16 + b, SKIN7[2])
	hero_eye(im, 9, 13 + b)
	px(im, 9, 13 + b, Color("2a1a2c"))
	px(im, 11, 16 + b, Color("f29a96"))
	px(im, 12, 16 + b, Color("f6b0a8"))
	px(im, 8, 17 + b, Color("c06460"))
	hair_flower(im, 18, 6 + b)


func gen_player3() -> void:
	var sheet: Image = new_img(128, 192)
	for dir in range(3):
		for f in range(4):
			var cell: Image = new_img(32, 48)
			draw_hero3(cell, dir, f)
			outline_auto(cell, 0.62)
			sheet.blit_rect(cell, Rect2i(0, 0, 32, 48), Vector2i(f * 32, dir * 48))
			if dir == 2:
				var m: Image = cell.duplicate()
				m.flip_x()
				sheet.blit_rect(m, Rect2i(0, 0, 32, 48), Vector2i(f * 32, 3 * 48))
	save3(sheet, "player")
	var big: Image = sheet.duplicate()
	big.resize(640, 960, Image.INTERPOLATE_NEAREST)
	big.save_png(ProjectSettings.globalize_path("res://").path_join("../screenshots/player_zoom.png"))


# ---------------------------------------------------------------- кот v3

func gen_cat3() -> void:
	var sheet: Image = new_img(144, 30)
	for f in range(4):
		rng.seed = 60 + f
		var im: Image = new_img(36, 30)
		if f < 2:
			draw_cat_sit3(im, f)
		else:
			draw_cat_sleep3(im, f - 2)
		outline_auto(im, 0.6)
		sheet.blit_rect(im, Rect2i(0, 0, 36, 30), Vector2i(f * 36, 0))
	save3(sheet, "cat")
	var big: Image = sheet.duplicate()
	big.resize(144 * 6, 30 * 6, Image.INTERPOLATE_NEAREST)
	big.save_png(ProjectSettings.globalize_path("res://").path_join("../screenshots/cat_zoom.png"))


func cat_ear(im: Image, tip: Vector2, s: int, tb: int) -> void:
	# треугольное ухо: внешняя шерсть, розовое внутри, кисточка
	for k in range(7):
		var y: int = int(tip.y) + k
		var hw: int = k / 2 + 1
		for j in range(-hw, hw + 1):
			var x: int = int(tip.x) + j + (k / 3) * s * -1
			var inner: bool = absi(j) < hw - 1 and k > 1 and k < 6
			var col: Color = (Color("f2a8ac") if j * s < 0 else Color("d8848c")) if inner else CAT7[clampi(tb + (1 if j * s < 0 else 0) - (1 if k > 4 else 0), 0, 6)]
			px(im, x, y, col)
	px(im, int(tip.x), int(tip.y) - 1, CAT7[tb])
	px(im, int(tip.x) - s, int(tip.y) + 3, FUR7[5])


func cat_eye(im: Image, x: int, y: int, open: bool) -> void:
	if not open:
		px(im, x - 1, y + 1, CAT7[0])
		px(im, x, y + 2, CAT7[0])
		px(im, x + 1, y + 2, CAT7[0])
		px(im, x + 2, y + 1, CAT7[0])
		return
	# круглый глаз 4x4: тёмный ободок, зелёная радужка светлее книзу, зрачок, блик
	var iris: Array = hx(["2a3a22", "4e8030", "7cb446", "b4dc78"])
	for yy in range(4):
		for xx in range(4):
			var corner: bool = (yy == 0 or yy == 3) and (xx == 0 or xx == 3)
			if corner:
				continue
			px(im, x + xx, y + yy, iris[mini(3, yy + 1)] if yy > 0 else iris[0])
	px(im, x + 1, y + 1, Color("1e1620"))
	px(im, x + 2, y + 1, Color("1e1620"))
	px(im, x + 1, y + 2, Color("1e1620"))
	px(im, x + 2, y + 2, Color("2e2430"))
	px(im, x + 1, y + 1, Color("ffffff"))


func draw_cat_sit3(im: Image, f: int) -> void:
	# хвост обвивает справа
	var pts: Array = []
	for k in range(16):
		var t: float = float(k) / 15.0
		var tx: float = 26.0 + sin(t * 2.4) * 6.5
		var ty: float = 28.0 - t * 15.0
		if f == 1:
			tx += t * t * 3.5
			ty -= t * t * 1.5
		pts.append(Vector2(tx, ty))
	for k2 in range(pts.size()):
		var tp: Vector2 = pts[k2]
		var tip: bool = k2 > 12
		blob(im, tp.x, tp.y, 2.5, 2.5, FUR7 if tip else CAT7, 4 if tip else 3, Vector3.ZERO if tip else Vector3(0.0, 1.6, k2 * 0.9))
	# тело
	blob(im, 18, 21, 9.6, 8.2, CAT7, 4, Vector3(1.1, 0.25, 0.4))
	# грудка пушистая
	blob(im, 18, 23, 4.6, 5.6, FUR7, 4)
	for k3 in range(5):
		px(im, 15 + k3 * 2, 17 + (k3 % 2), FUR7[5])
		px(im, 14 + k3 * 2, 18, FUR7[4])
	# лапки с пальчиками
	for side in [-1, 1]:
		var s: int = int(side)
		blob(im, 18 + s * 4, 28, 2.9, 1.8, FUR7, 4 if s < 0 else 3)
		px(im, 18 + s * 4 - 1, 28, FUR7[2])
		px(im, 18 + s * 4 + 1, 28, FUR7[2])
	# голова (уши рисуем раньше, голова закрывает их низ)
	cat_ear(im, Vector2(11, 0), -1, 5)
	cat_ear(im, Vector2(25, 0), 1, 4)
	blob(im, 18, 11, 9.2, 7.8, CAT7, 4, Vector3(0.0, 0.0, 0.0))
	# щёчки-пушок
	for s2 in [-1, 1]:
		var sv: int = int(s2)
		px(im, 18 + sv * 9, 13, CAT7[4 if sv < 0 else 3])
		px(im, 18 + sv * 10, 14, CAT7[3 if sv < 0 else 2])
		px(im, 18 + sv * 9, 15, CAT7[3])
	# полоски на лбу «М»
	for p in [Vector2i(15, 5), Vector2i(15, 6), Vector2i(16, 7), Vector2i(18, 5), Vector2i(18, 6), Vector2i(18, 7), Vector2i(21, 5), Vector2i(21, 6), Vector2i(20, 7), Vector2i(10, 10), Vector2i(11, 10), Vector2i(25, 10), Vector2i(26, 10), Vector2i(10, 12), Vector2i(26, 12)]:
		var pp: Vector2i = p
		px(im, pp.x, pp.y, CAT7[2])
	# мордочка
	blob(im, 18, 14.6, 4.6, 3.2, FUR7, 4)
	cat_eye(im, 11, 8, true)
	cat_eye(im, 21, 8, true)
	px(im, 17, 13, Color("e88a96"))
	px(im, 18, 13, Color("f2a8b0"))
	px(im, 17, 14, Color("c0606e"))
	px(im, 16, 15, CAT7[1])
	px(im, 17, 15, CAT7[1])
	px(im, 19, 15, CAT7[1])
	px(im, 18, 16, CAT7[1])
	px(im, 18, 15, FUR7[3])
	# усы
	for s3 in [-1, 1]:
		var w: int = int(s3)
		for k4 in range(4):
			px(im, 18 + w * (5 + k4), 14 + (k4 / 2), FUR7[6] if k4 < 2 else FUR7[4])
	px(im, 12, 15, Color("f29a96"))
	px(im, 24, 15, Color("f29a96"))


func draw_cat_sleep3(im: Image, f: int) -> void:
	var ry: float = 7.4 + f * 0.6
	blob(im, 20.5, 20.8 - f * 0.4, 14.2, ry, CAT7, 4, Vector3(1.0, 0.15, 0.3))
	# хвост вдоль низа, кончик светлый у мордочки
	for k in range(20):
		var tx: float = 33.0 - k * 1.25
		var ty: float = 26.2 + sin(k * 0.25) * 0.7
		var tip: bool = k > 15
		blob(im, tx, ty, 2.3, 2.0, FUR7 if tip else CAT7, 4 if tip else 3, Vector3.ZERO if tip else Vector3(1.5, 0.0, 0.2))
	# голова на лапках
	cat_ear(im, Vector2(5, 10), -1, 5)
	cat_ear(im, Vector2(14, 10), 1, 4)
	blob(im, 9.5, 19.5, 7.2, 6.2, CAT7, 4)
	for p in [Vector2i(8, 14), Vector2i(10, 14), Vector2i(9, 15), Vector2i(3, 18), Vector2i(16, 18)]:
		var pp: Vector2i = p
		px(im, pp.x, pp.y, CAT7[2])
	blob(im, 9, 22.4, 3.8, 2.4, FUR7, 4)
	blob(im, 13.5, 25.5, 3.0, 1.7, FUR7, 3)
	cat_eye(im, 5, 18, false)
	cat_eye(im, 11, 18, false)
	px(im, 8, 21, Color("e88a96"))
	px(im, 9, 21, Color("f2a8b0"))
	px(im, 3, 22, Color("f29a96"))
	px(im, 14, 22, Color("f29a96"))
	for k2 in range(3):
		px(im, 1 - k2 + 2, 22 + k2 / 2, FUR7[6])
		px(im, 15 + k2, 21 + k2 / 2, FUR7[5])


# ================================================================== v4: эльфийка 36x60 и кот-«наклейка»

var HAIRL7: Array
var WHITE7: Array
var TEAL7: Array
var SKINL7: Array
const HCX: float = 18.0


func _palettes_v4() -> void:
	HAIRL7 = hx(["3a2a30", "5a443e", "7c614c", "9c7e5c", "b89a70", "d2b68a", "eadab0"])
	WHITE7 = hx(["5a5c74", "8487a0", "aab0c2", "ccd2dc", "e6eaee", "f5f7f4", "ffffff"])
	TEAL7 = hx(["0e2834", "143e4a", "1c5660", "267274", "378e8a", "5eaea2", "96d0c0"])
	SKINL7 = hx(["7a4048", "b0626a", "d68c84", "eeae9c", "f9cdb8", "fde2d2", "fff3ea"])


## Волнистая прядь-масса волос: ряды y0..y1, полуширина hw(t) + волна, сдвиг sway книзу
func hair_mass(im: Image, cx: float, y0: int, y1: int, hw0: float, hw1: float, sway: float, tb: int, ragged: bool = true, ripple: float = 0.0) -> void:
	if HAIR_CUT > 0 and y1 > HAIR_CUT:
		y1 = HAIR_CUT
	for y in range(y0, y1 + 1):
		var t: float = float(y - y0) / float(maxi(1, y1 - y0))
		var hw: float = lerpf(hw0, hw1, t)
		var c: float = cx + sway * t * t
		var wl: float = sin(y * 0.55 + ripple) * 1.1 * t
		var wr: float = sin(y * 0.55 + 1.7 + ripple) * 1.1 * t
		for x in range(int(floor(c - hw + wl)), int(ceil(c + hw + wr))):
			if ragged and y > y1 - 3 and h01(x, y, 3) > 0.45 + (y1 - y) * 0.2:
				continue
			var u: float = (x + 0.5 - (c - hw)) / (2.0 * hw)
			var ti: int = tb + 1 if u < 0.3 else (tb if u < 0.72 else tb - 1)
			if posmod(x + int(round(sin(y * 0.45) * 1.5)), 3) == 0:
				ti -= 1
			px(im, x, y, HAIRL7[clampi(ti, 0, 6)])


func elf_ear(im: Image, base: Vector2, s: int, tb: int, n: int = 5) -> void:
	# острое ухо: от основания наружу и вверх
	for k in range(n):
		var x: int = int(base.x) + s * k
		var ytop: int = int(base.y) - int(round(k * 1.0))
		var ybot: int = int(base.y) + 2 - int(round(k * 0.9))
		for y in range(ytop, ybot + 1):
			var ti: int = tb if y == ytop else tb - 1
			if y == ybot and k < 3:
				ti = tb - 2
			if k > 0 and k < 3 and y == ytop + 1 and ybot - ytop >= 2:
				px(im, x, y, SKINL7[2])
				continue
			px(im, x, y, SKINL7[clampi(ti, 0, 6)])


func elf_eye(im: Image, x: int, y: int, s: int) -> void:
	# ресницы, радужка бирюзовая, блик
	px(im, x, y, Color("2a1c24"))
	px(im, x + 1, y, Color("2a1c24"))
	px(im, x + (2 if s > 0 else -1), y - (0), Color("3a2a30"))
	px(im, x, y + 1, Color("ffffff"))
	px(im, x + 1, y + 1, Color("1e3a42"))
	px(im, x, y + 2, Color("3e8a84"))
	px(im, x + 1, y + 2, Color("6cbcae"))


func overskirt(im: Image, cx: float, y0: int, y1: int, open: bool, sway: float, tb: int) -> void:
	for y in range(y0, y1 + 1):
		var t: float = float(y - y0) / float(maxi(1, y1 - y0))
		var c: float = cx + sway * t * t
		var outer: float = lerpf(5.6, 13.0, pow(t, 0.85)) + sin(y * 0.4) * 0.5 * t
		var inner: float = lerpf(0.8, 6.0, t) if open else -1.0
		for x in range(int(floor(c - outer)), int(ceil(c + outer))):
			var dx: float = x + 0.5 - c
			if absf(dx) < inner:
				continue
			if y == y1 and posmod(x, 3) == 0:
				continue
			var u: float = (dx + outer) / (2.0 * outer)
			var ti: int = tb + 1 if u < 0.25 else (tb if u < 0.62 else (tb - 1 if u < 0.88 else tb - 2))
			# складки
			var fold: float = sin((dx / outer) * 9.0 + 0.6)
			if t > 0.2 and fold > 0.82:
				ti -= 1
			elif t > 0.2 and fold < -0.85:
				ti += 1
			# светлая кайма по краю разреза
			if open and absf(dx) < inner + 1.0:
				ti = 6 if dx < 0.0 else 5
			if y >= y1 - 1:
				ti -= 1
			px(im, x, y, TEAL7[clampi(ti, 0, 6)])


func elf_boots(im: Image, x0: int, y0: int, lift: int, toe: int) -> void:
	for y in range(y0 - lift, 59 - lift):
		for x in range(x0, x0 + 4):
			var u: int = x - x0
			var ti: int = 5 if u == 0 else (4 if u < 3 else 3)
			if y == y0 - lift:
				ti += 1
			if y == 58 - lift:
				ti = 1
			px(im, x, y, LEATH7[clampi(ti - 1, 0, 6)])
	if toe != 0:
		var tx: int = x0 - 1 if toe < 0 else x0 + 4
		px(im, tx, 57 - lift, LEATH7[3])
		px(im, tx, 58 - lift, LEATH7[0])


func draw_hero4(im: Image, dir: int, f: int) -> void:
	var b: int = -1 if (f == 1 or f == 3) else 0
	var sw: float = 1.0 if f == 0 else (-1.0 if f == 2 else 0.0)
	if dir == 0:
		_elf_front(im, f, b, sw)
	elif dir == 1:
		_elf_back(im, f, b, sw)
	else:
		_elf_side(im, f, b, sw)


func _elf_arms(im: Image, cx: float, b: int, hs: int, tl: int, tr: int) -> void:
	# рукава-фонарики, длинные рукава с бирюзовой манжетой, кисти
	blob(im, cx - 6.5, 20.5 + b, 2.6, 2.6, WHITE7, tl)
	blob(im, cx + 6.5, 20.5 + b, 2.6, 2.6, WHITE7, tr)
	rows(im, cx - 7.0, 22 + b, 33 + b + hs, 1.4, 1.9, WHITE7, tl, [], -0.6)
	rows(im, cx + 7.0, 22 + b, 33 + b - hs, 1.4, 1.9, WHITE7, tr, [], 0.6)
	for x in range(int(cx) - 9, int(cx) - 5):
		px(im, x, 33 + b + hs, TEAL7[4])
	for x2 in range(int(cx) + 5, int(cx) + 9):
		px(im, x2, 33 + b - hs, TEAL7[3])
	blob(im, cx - 7.6, 35.2 + b + hs, 1.5, 1.7, SKINL7, 4)
	blob(im, cx + 7.6, 35.2 + b - hs, 1.5, 1.7, SKINL7, 3)


func _elf_front(im: Image, f: int, b: int, sw: float) -> void:
	var cx: float = HCX
	# волосы сзади — длинные волнистые
	hair_mass(im, cx, 6 + b, 37 + b, 8.6, 9.6, -sw * 0.8, 3)
	# сапожки
	elf_boots(im, 14, 54, 1 if f == 2 else 0, 0)
	elf_boots(im, 19, 54, 1 if f == 0 else 0, 0)
	# белое нижнее платье до щиколоток
	rows(im, cx, 30 + b, 54, 4.6, 5.8, WHITE7, 4, [0.4, 0.62], sw * 0.6)
	# бирюзовая накидка-юбка с разрезом спереди
	overskirt(im, cx, 29 + b, 55, true, sw, 4)
	# лиф
	rows(im, cx, 18 + b, 30 + b, 5.6, 4.6, WHITE7, 4)
	for k in range(4):
		px(im, int(cx) - 3 + k, 19 + b + k, TEAL7[3])
		px(im, int(cx) + 3 - k, 19 + b + k, TEAL7[3])
	for y in range(23 + b, 29 + b):
		px(im, int(cx), y, TEAL7[3])
	px(im, int(cx) - 1, 24 + b, WHITE7[6])
	px(im, int(cx) - 1, 26 + b, WHITE7[6])
	# пояс, пряжка, мешочек трав
	for x in range(int(cx) - 5, int(cx) + 5):
		var ti: int = 4 if x < int(cx) - 1 else (3 if x < int(cx) + 3 else 2)
		px(im, x, 29 + b, LEATH7[ti + 1])
		px(im, x, 30 + b, LEATH7[ti - 1])
	px(im, int(cx) + 1, 29 + b, Color("f2d06a"))
	px(im, int(cx) + 1, 30 + b, Color("b88a2c"))
	px(im, int(cx) + 2, 29 + b, Color("d0a83a"))
	for y2 in range(31 + b, 36 + b):
		for x3 in range(int(cx) - 7, int(cx) - 3):
			px(im, x3, y2, LEATH7[5 if x3 < int(cx) - 5 else 4] if y2 > 31 + b else LEATH7[2])
	px(im, int(cx) - 5, 30 + b, CAPE7[5])
	px(im, int(cx) - 6, 29 + b, CAPE7[4])
	var hs: int = 1 if f == 0 else (-1 if f == 2 else 0)
	_elf_arms(im, cx, b, hs, 4, 3)
	# шея и лицо
	for y3 in range(15 + b, 19 + b):
		px(im, int(cx) - 1, y3, SKINL7[3])
		px(im, int(cx), y3, SKINL7[3])
		px(im, int(cx) + 1, y3, SKINL7[2])
	blob(im, cx, 11.5 + b, 5.0, 5.4, SKINL7, 4, Vector3.ZERO, 2)
	elf_ear(im, Vector2(cx - 5, 10 + b), -1, 4)
	elf_ear(im, Vector2(cx + 5, 10 + b), 1, 3)
	# макушка и чёлка
	blob(im, cx, 7.5 + b, 6.6, 4.8, HAIRL7, 4)
	var fr: Array = [2, 4, 5, 3, 6, 4, 2, 3, 5, 4, 6, 3, 2]
	for i in range(fr.size()):
		var x4: int = int(cx) - 6 + i
		for k2 in range(int(fr[i]) + 1):
			var y4: int = 6 + b + k2
			var ti2: int = 5 if k2 < 2 else 4
			if k2 == int(fr[i]):
				ti2 = 3
			px(im, x4, y4, HAIRL7[ti2])
	# блик на макушке
	for x5 in range(int(cx) - 4, int(cx) + 3):
		px(im, x5, 4 + b + (1 if x5 < int(cx) - 2 or x5 > int(cx) + 1 else 0), HAIRL7[6])
	# пряди у лица (перед ушами)
	for y5 in range(9 + b, 22 + b):
		var wv: int = int(round(sin(y5 * 0.6) * 0.8))
		px(im, int(cx) - 6 + wv, y5, HAIRL7[4])
		px(im, int(cx) - 5 + wv, y5, HAIRL7[3] if y5 > 12 + b else HAIRL7[4])
		px(im, int(cx) + 5 - wv, y5, HAIRL7[3] if y5 > 12 + b else HAIRL7[4])
		px(im, int(cx) + 6 - wv, y5, HAIRL7[2])
	# хохолок
	px(im, int(cx) + 1, 1 + b, HAIRL7[4])
	px(im, int(cx) + 2, 0 + b, HAIRL7[5])
	px(im, int(cx) + 3, 1 + b, HAIRL7[4])
	px(im, int(cx) + 2, 2 + b, HAIRL7[3])
	# лицо
	elf_eye(im, int(cx) - 4, 10 + b, -1)
	elf_eye(im, int(cx) + 2, 10 + b, 1)
	px(im, int(cx) - 4, 14 + b, Color("f4a8a4"))
	px(im, int(cx) - 3, 14 + b, Color("f8bcb4"))
	px(im, int(cx) + 3, 14 + b, Color("f8bcb4"))
	px(im, int(cx) + 4, 14 + b, Color("f4a8a4"))
	px(im, int(cx), 13 + b, SKINL7[3])
	px(im, int(cx), 15 + b, Color("d07a7a"))
	# веточка в волосах
	px(im, int(cx) - 5, 5 + b, CAPE7[5])
	px(im, int(cx) - 6, 6 + b, CAPE7[4])
	px(im, int(cx) - 4, 4 + b, CAPE7[6])
	px(im, int(cx) - 6, 4 + b, Color("fff4f6"))


func _elf_back(im: Image, f: int, b: int, sw: float) -> void:
	var cx: float = HCX
	elf_boots(im, 14, 54, 1 if f == 2 else 0, 0)
	elf_boots(im, 19, 54, 1 if f == 0 else 0, 0)
	rows(im, cx, 30 + b, 54, 4.6, 5.8, WHITE7, 3, [], sw * 0.6)
	overskirt(im, cx, 29 + b, 55, false, sw, 3)
	rows(im, cx, 18 + b, 30 + b, 5.6, 4.6, WHITE7, 3)
	for x in range(int(cx) - 5, int(cx) + 5):
		px(im, x, 29 + b, LEATH7[4])
		px(im, x, 30 + b, LEATH7[2])
	var hs: int = 1 if f == 0 else (-1 if f == 2 else 0)
	_elf_arms(im, cx, b, -hs, 3, 2)
	elf_ear(im, Vector2(cx - 5, 10 + b), -1, 3)
	elf_ear(im, Vector2(cx + 5, 10 + b), 1, 2)
	# волосы сзади целиком
	blob(im, cx, 9 + b, 7.4, 6.6, HAIRL7, 4)
	hair_mass(im, cx, 10 + b, 38 + b, 7.6, 9.4, sw * 0.9, 4)
	# блестящие волны на прядях и тёмные промежутки между локонами
	for x0 in range(int(cx) - 9, int(cx) + 10):
		for band in [12, 23, 32]:
			var yb: int = int(band) + b + int(round(sin(x0 * 0.9) * 1.0))
			if a_at(im, x0, yb) > 0.5 and a_at(im, x0, yb + 1) > 0.5:
				px(im, x0, yb, HAIRL7[6] if posmod(x0, 3) != 0 else HAIRL7[5])
				px(im, x0, yb + 1, HAIRL7[5] if posmod(x0, 3) != 0 else HAIRL7[4])
	for xs in [int(cx) - 4, int(cx) + 1, int(cx) + 5]:
		for y6 in range(14 + b, 37 + b):
			var xw: int = int(xs) + int(round(sin(y6 * 0.45) * 1.2))
			if a_at(im, xw, y6) > 0.5:
				px(im, xw, y6, HAIRL7[2])
	for x2 in range(int(cx) - 5, int(cx) + 4):
		var yy: int = 5 + b + (1 if x2 < int(cx) - 3 or x2 > int(cx) + 2 else 0)
		px(im, x2, yy, HAIRL7[6])
	# лента-бант в волосах
	px(im, int(cx) - 1, 17 + b, TEAL7[5])
	px(im, int(cx) - 2, 16 + b, TEAL7[4])
	px(im, int(cx) - 2, 18 + b, TEAL7[3])
	px(im, int(cx), 17 + b, TEAL7[2])
	px(im, int(cx) + 1, 16 + b, TEAL7[4])
	px(im, int(cx) + 1, 18 + b, TEAL7[3])
	px(im, int(cx) - 1, 19 + b, TEAL7[4])
	px(im, int(cx), 20 + b, TEAL7[3])
	px(im, int(cx) + 2, 1 + b, HAIRL7[4])
	px(im, int(cx) + 3, 0 + b, HAIRL7[5])
	px(im, int(cx) + 4, 1 + b, HAIRL7[4])


func _elf_side(im: Image, f: int, b: int, sw: float) -> void:
	var cx: float = HCX
	var fd: int = -3 if f == 0 else (3 if f == 2 else 0)
	# волосы за спиной
	hair_mass(im, cx + 3.0, 7 + b, 37 + b, 5.0, 6.0, sw * 1.4 + 1.0, 3)
	elf_boots(im, 17 - fd, 54, 0 if f != 1 and f != 3 else 1, -1)
	elf_boots(im, 16 + fd, 54, 0, -1)
	rows(im, cx, 30 + b, 54, 3.8, 5.0, WHITE7, 4, [0.5], -sw * 0.6)
	# накидка: сзади и по бокам, спереди разрез
	for y in range(29 + b, 56):
		var t: float = float(y - 29 - b) / float(maxi(1, 26 - b))
		var c: float = cx - sw * 0.9 * t * t
		var back: float = lerpf(4.5, 11.0, pow(t, 0.85))
		var front: float = lerpf(3.8, 7.0, t)
		for x in range(int(floor(c - front)), int(ceil(c + back))):
			var dx: float = x + 0.5 - c
			if dx < -front + 2.5 + t * 2.0 and dx < 0.0 and y < 54:
				# видна белая юбка спереди
				if dx > -front + 1.0:
					continue
			if y == 55 and posmod(x, 3) == 0:
				continue
			var u: float = (dx + front) / (front + back)
			var ti: int = 5 if u < 0.2 else (4 if u < 0.55 else (3 if u < 0.85 else 2))
			if t > 0.25 and sin(dx * 1.1) > 0.85:
				ti -= 1
			if y >= 54:
				ti -= 1
			px(im, x, y, TEAL7[clampi(ti, 0, 6)])
	rows(im, cx, 18 + b, 30 + b, 4.0, 3.6, WHITE7, 4)
	for y2 in range(19 + b, 23 + b):
		px(im, int(cx) - 3, y2, TEAL7[3])
	for x2 in range(int(cx) - 4, int(cx) + 4):
		px(im, x2, 29 + b, LEATH7[4])
		px(im, x2, 30 + b, LEATH7[2])
	for y3 in range(31 + b, 36 + b):
		for x3 in range(int(cx) + 2, int(cx) + 6):
			px(im, x3, y3, LEATH7[4 if x3 < int(cx) + 4 else 3])
	# рука качается
	blob(im, cx, 20.5 + b, 2.6, 2.6, WHITE7, 4)
	var hand: Vector2 = Vector2(cx - sw * 4.0, 34.5 + b)
	for i in range(7):
		var p: Vector2 = Vector2(cx, 22 + b).lerp(hand, float(i) / 7.0)
		blob(im, p.x, p.y, 1.6, 1.4, WHITE7, 4)
	for k in range(3):
		px(im, int(hand.x) - 1 + k, int(hand.y) - 2, TEAL7[4])
	blob(im, hand.x, hand.y, 1.5, 1.7, SKINL7, 4)
	# голова в профиль, смотрит влево
	for y4 in range(15 + b, 19 + b):
		px(im, int(cx) - 1, y4, SKINL7[3])
		px(im, int(cx), y4, SKINL7[2])
	blob(im, cx + 1.0, 9.0 + b, 6.6, 6.2, HAIRL7, 4)
	blob(im, cx - 2.2, 11.8 + b, 4.4, 5.2, SKINL7, 4, Vector3.ZERO, 2)
	px(im, int(cx) - 7, 12 + b, SKINL7[4])
	px(im, int(cx) - 7, 13 + b, SKINL7[3])
	px(im, int(cx) - 6, 15 + b, SKINL7[3])
	# чёлка
	for x5 in range(int(cx) - 6, int(cx) + 2):
		var ln: int = 2 + int(h01(x5, 4, 9) * 3.0)
		for k2 in range(ln + 1):
			px(im, x5, 6 + b + k2, HAIRL7[5 if k2 < 2 else (4 if k2 < ln else 3)])
	for y5 in range(10 + b, 20 + b):
		px(im, int(cx) + 1, y5, HAIRL7[4])
		px(im, int(cx) + 2, y5, HAIRL7[3])
	# ухо назад
	elf_ear(im, Vector2(cx + 1, 10 + b), 1, 4)
	for x6 in range(int(cx) - 3, int(cx) + 3):
		px(im, x6, 3 + b + (1 if x6 < int(cx) - 1 else 0), HAIRL7[6])
	px(im, int(cx) + 1, 1 + b, HAIRL7[4])
	px(im, int(cx) + 2, 0 + b, HAIRL7[5])
	elf_eye(im, int(cx) - 6, 10 + b, -1)
	px(im, int(cx) - 6, 10 + b, Color("2a1c24"))
	px(im, int(cx) - 5, 14 + b, Color("f4a8a4"))
	px(im, int(cx) - 4, 14 + b, Color("f8bcb4"))
	px(im, int(cx) - 6, 15 + b, Color("d07a7a"))
	px(im, int(cx) - 1, 5 + b, CAPE7[5])
	px(im, int(cx) - 2, 4 + b, Color("fff4f6"))


func gen_player4() -> void:
	var fw: int = 36
	var fh: int = 60
	var sheet: Image = new_img(fw * 4, fh * 4)
	for dir in range(3):
		for f in range(4):
			var cell: Image = new_img(fw, fh)
			draw_hero4(cell, dir, f)
			outline_auto(cell, 0.6)
			sheet.blit_rect(cell, Rect2i(0, 0, fw, fh), Vector2i(f * fw, dir * fh))
			if dir == 2:
				var m: Image = cell.duplicate()
				m.flip_x()
				sheet.blit_rect(m, Rect2i(0, 0, fw, fh), Vector2i(f * fw, 3 * fh))
	save3(sheet, "player")
	var big: Image = sheet.duplicate()
	big.resize(sheet.get_width() * 4, sheet.get_height() * 4, Image.INTERPOLATE_NEAREST)
	big.save_png(ProjectSettings.globalize_path("res://").path_join("../screenshots/player_zoom.png"))


# ---------------------------------------------------------------- кот-«наклейка»

var CAT_LINE: Color = Color("b4582e")
var CAT_W: Array = []
var CAT_O: Array = []


## Плоская фигура: заливка, тень снизу-справа, контур цветом line (если inner_line)
func sblob(im: Image, cx: float, cy: float, rx: float, ry: float, ramp: Array, inner_line: bool) -> void:
	for y in range(int(floor(cy - ry)) - 1, int(ceil(cy + ry)) + 1):
		for x in range(int(floor(cx - rx)) - 1, int(ceil(cx + rx)) + 1):
			var nx: float = (x + 0.5 - cx) / rx
			var ny: float = (y + 0.5 - cy) / ry
			var d2: float = nx * nx + ny * ny
			if d2 > 1.0:
				continue
			var c: Color = ramp[1]
			var sx: float = nx - 0.35
			var sy: float = ny - 0.45
			if sx * sx + sy * sy > 0.95 and (nx > 0.1 or ny > 0.25):
				c = ramp[0]
			if nx < -0.2 and ny < -0.25 and d2 < 0.55:
				c = ramp[2]
			if inner_line:
				var ex: float = (absf(x + 0.5 - cx) + 1.0) / rx
				var ey: float = (absf(y + 0.5 - cy) + 1.0) / ry
				if ex * ex + ny * ny > 1.0 or nx * nx + ey * ey > 1.0:
					c = CAT_LINE
			px(im, x, y, c)


## Рыжие пятна: перекрашивает белую шерсть внутри эллипса
func cat_patch(im: Image, cx: float, cy: float, rx: float, ry: float) -> void:
	for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
		for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
			var nx: float = (x + 0.5 - cx) / rx
			var ny: float = (y + 0.5 - cy) / ry
			if nx * nx + ny * ny + (h01(x / 2, y / 2, 5) - 0.5) * 0.4 > 1.0:
				continue
			if x < 0 or y < 0 or x >= im.get_width() or y >= im.get_height():
				continue
			var c: Color = im.get_pixel(x, y)
			for i in range(3):
				if c.is_equal_approx(CAT_W[i]):
					im.set_pixel(x, y, CAT_O[i])


func sticker_ear(im: Image, tip: Vector2, s: int) -> void:
	for k in range(6):
		var y: int = int(tip.y) + k
		for j in range(-k / 2 - 1, k / 2 + 2):
			var x: int = int(tip.x) + j + s * (k / 4)
			var edge: bool = j == -k / 2 - 1 or j == k / 2 + 1
			var inner: bool = not edge and k > 1 and k < 5 and absi(j) < k / 2
			px(im, x, y, CAT_LINE if edge else (Color("f6b6b8") if inner else CAT_W[1]))
	px(im, int(tip.x), int(tip.y) - 1, CAT_LINE)


func gen_cat4() -> void:
	CAT_W = hx(["eadbd6", "fffaf4", "ffffff"])
	CAT_O = hx(["e8925a", "f6b27c", "fbd0a4"])
	var sheet: Image = new_img(144, 30)
	for f in range(4):
		var im: Image = new_img(36, 30)
		if f < 2:
			_cat_sit4(im, f)
		else:
			_cat_sleep4(im, f - 2)
		outline(im, CAT_LINE)
		sheet.blit_rect(im, Rect2i(0, 0, 36, 30), Vector2i(f * 36, 0))
	save3(sheet, "cat")
	var big: Image = sheet.duplicate()
	big.resize(144 * 6, 30 * 6, Image.INTERPOLATE_NEAREST)
	big.save_png(ProjectSettings.globalize_path("res://").path_join("../screenshots/cat_zoom.png"))


func _cat_tail(im: Image, pts: Array) -> void:
	for k in range(pts.size()):
		var p: Vector2 = pts[k]
		sblob(im, p.x, p.y, 2.4, 2.4, CAT_O if k % 3 != 2 else hx(["d07a44", "e08a52", "eea06a"]), false)


func _cat_sit4(im: Image, f: int) -> void:
	# хвост загибается вверх справа
	var pts: Array = []
	for k in range(13):
		var t: float = float(k) / 12.0
		var tx: float = 25.0 + t * 6.0 + (t * t * 2.0 if f == 1 else 0.0)
		var ty: float = 26.5 - sin(t * 1.9) * 10.0 - (t * t * 2.0 if f == 1 else 0.0)
		pts.append(Vector2(tx, ty))
	_cat_tail(im, pts)
	# тело-груша и лапки
	sblob(im, 17, 21.5, 8.4, 7.0, CAT_W, false)
	cat_patch(im, 23, 19, 4.5, 4.0)
	sblob(im, 13.5, 27.2, 2.7, 1.9, CAT_W, true)
	sblob(im, 20.5, 27.2, 2.7, 1.9, CAT_W, true)
	px(im, 13, 27, CAT_LINE)
	px(im, 20, 27, CAT_LINE)
	# голова
	sticker_ear(im, Vector2(10, 0), 1)
	sticker_ear(im, Vector2(24, 0), -1)
	sblob(im, 17, 11, 9.4, 7.4, CAT_W, true)
	cat_patch(im, 11, 6, 5.0, 4.0)
	cat_patch(im, 24, 5, 3.5, 3.0)
	# пушок на щёках
	px(im, 7, 12, CAT_LINE)
	px(im, 27, 12, CAT_LINE)
	px(im, 7, 13, CAT_W[1])
	px(im, 27, 13, CAT_W[0])
	# глаза: точки, на кадре 1 — довольные «^^»
	for ex in [12, 21]:
		var e: int = int(ex)
		if f == 0:
			px(im, e, 10, Color("4a2c2c"))
			px(im, e + 1, 10, Color("4a2c2c"))
			px(im, e, 11, Color("4a2c2c"))
			px(im, e + 1, 11, Color("6a4040"))
			px(im, e, 10, Color("ffffff"))
		else:
			px(im, e - 1, 11, Color("4a2c2c"))
			px(im, e, 10, Color("4a2c2c"))
			px(im, e + 1, 10, Color("4a2c2c"))
			px(im, e + 2, 11, Color("4a2c2c"))
	# румянец
	for bx in [9, 10, 11, 22, 23, 24]:
		px(im, int(bx), 13, Color("f8b4b4"))
	px(im, 10, 14, Color("fbc8c4"))
	px(im, 23, 14, Color("fbc8c4"))
	# носик и ротик «ω»
	px(im, 16, 12, Color("ee8c96"))
	px(im, 17, 12, Color("ee8c96"))
	px(im, 15, 13, CAT_LINE)
	px(im, 16, 14, CAT_LINE)
	px(im, 17, 14, CAT_LINE)
	px(im, 18, 13, CAT_LINE)


func _cat_sleep4(im: Image, f: int) -> void:
	var ry: float = 6.6 + f * 0.6
	sblob(im, 21, 22.5 - f * 0.4, 13.0, ry, CAT_W, false)
	cat_patch(im, 24, 18, 6.0, 4.0)
	cat_patch(im, 31, 22, 3.0, 3.0)
	# хвост вдоль низа
	var pts: Array = []
	for k in range(14):
		pts.append(Vector2(33.0 - k * 1.5, 27.0 + sin(k * 0.3) * 0.5))
	_cat_tail(im, pts)
	# голова
	sticker_ear(im, Vector2(4, 11), 1)
	sticker_ear(im, Vector2(15, 11), -1)
	sblob(im, 10, 20, 8.2, 6.4, CAT_W, true)
	cat_patch(im, 5, 15, 4.0, 3.0)
	# закрытые глазки «︶»
	for ex in [6, 12]:
		var e: int = int(ex)
		px(im, e - 1, 20, Color("4a2c2c"))
		px(im, e, 21, Color("4a2c2c"))
		px(im, e + 1, 21, Color("4a2c2c"))
		px(im, e + 2, 20, Color("4a2c2c"))
	for bx in [4, 5, 13, 14]:
		px(im, int(bx), 23, Color("f8b4b4"))
	px(im, 9, 22, Color("ee8c96"))
	px(im, 10, 22, Color("ee8c96"))
	px(im, 9, 23, CAT_LINE)
	px(im, 10, 24, CAT_LINE)
	# лапка под щекой
	sblob(im, 15, 26.5, 2.6, 1.8, CAT_W, true)


# ================================================================== v5: аниме-героиня 40x64 и чёрный кот

## Голова спереди, рисуется по пикселям (26 x 24). Точка — пусто.
const HEAD_FRONT: Array = [
	"............hL",
	".............L",
	".........hHHHLHHh",
	".......hHHHLLLLHHHh",
	"......hHHLLLLLHHHHHh",
	".....hHHLLLHHHHHHHHHh",
	"....hHHHHHHHHHHHHHHHHh",
	"....hHHHHHhHHHHHhHHHHh",
	"...hHHHHHhHHHHHHhHHHHHh",
	"...hHHHHhHHHHHhHHHHhHHh",
	"..hHHHhSShHHhSSShHHhSHHHh",
	"..hHHhSSShSSSSShSSSShHHh",
	"..hHhEEEEESSSSSEEEEEhHHh",
	"..hHhSIWIISSSSSIWIIShHHh",
	"..hHhSIIIISSSSSIIIIShHHh",
	"..hHhSiIIiSSSSSiIIiShHHh",
	"..hHhBSiiSSSTSSSiiSBhHHh",
	"..hHhSBBSSSSSSSSSSBBhHHh",
	"..hHhTSSSSSSMMSSSSSThHHh",
	"..hHh.TTSSSSSSSSTT..hHHh",
	"..hHh..TTSSSSSSTT...hHHh",
	"..hHh....TTSSTT.....hHHh",
	"...hH....TSSST.....Hh",
	"...h......TST.......h",
]

## Голова в профиль, смотрит влево (26 x 24)
const HEAD_SIDE: Array = [
	"..............hL",
	"...............L",
	"..........hHHHHLHHh",
	"........hHHLLLLHHHHHh",
	".......hHLLLLLHHHHHHHh",
	"......hHLLLHHHHHHHHHHHh",
	".....hHHHHHHHHHHHHHHHHh",
	".....hHHHhHHHHHHHHHHHHHh",
	"....hHHhHHHhHHHHHHHHHHHh",
	"....hHhSHHhSHHHHHHHHHHHHh",
	"...hHhSShHhSSHHHHHHHHHHHh",
	"...hSSSSSSSSShHHHHHHHHHHh",
	"..EEEEESSSSSShHHHHHHHHHHh",
	"...SIWISSSSSSShHHHHHHHHHh",
	"...SIIISSSSSSShHHHHHHHHHh",
	"..SSiIiSSSSSSShHHHHHHHHHh",
	"...SSiiBBSSSSShHHHHHHHHHh",
	"...SSSSBBSSSSShHHHHHHHHh",
	"....MSSSSSSSShHHHHHHHHHh",
	".....TSSSSSTThHHHHHHHHh",
	"......TTSSTT.hHHHHHHHh",
	"........TSST..hHHHHHHh",
	"........TSST...hHHHHh",
	"........TSST....hHHh",
]

var HEAD_PAL: Dictionary = {}


func _head_pal() -> void:
	HEAD_PAL = {
		"H": HAIRL7[4], "h": HAIRL7[3], "d": HAIRL7[2], "L": HAIRL7[6], "l": HAIRL7[5],
		"S": SKINL7[5], "T": SKINL7[4], "t": SKINL7[3], "B": Color("f6a8a8"),
		"E": Color("2a1824"), "I": Color("2a6468"), "i": Color("6cbcac"), "W": Color("ffffff"),
		"M": Color("c8706c"),
	}
	for k in EYE_OVR.keys():
		HEAD_PAL[k] = EYE_OVR[k]


func grid(im: Image, rows: Array, ox: int, oy: int, pal: Dictionary, flip: bool = false) -> void:
	for y in range(rows.size()):
		var r: String = rows[y]
		for x in range(r.length()):
			var ch: String = r[x]
			if ch == "." or not pal.has(ch):
				continue
			var xx: int = ox + (25 - x if flip else x)
			px(im, xx, oy + y, pal[ch])


func boots5(im: Image, x0: int, lift: int, toe: int) -> void:
	for y in range(57 - lift, 62 - lift):
		for x in range(x0, x0 + 4):
			var u: int = x - x0
			var ti: int = 5 if u == 0 else (4 if u < 3 else 3)
			if y == 57 - lift:
				ti += 1
			if y == 61 - lift:
				ti = 1
			px(im, x, y, LEATH7[clampi(ti - 1, 0, 6)])
	if toe != 0:
		var tx: int = x0 - 1 if toe < 0 else x0 + 4
		px(im, tx, 60 - lift, LEATH7[3])
		px(im, tx, 61 - lift, LEATH7[0])


## Юбка с белой оборкой снизу
func skirt5(im: Image, cx: float, y0: int, y1: int, hw0: float, hw1: float, sway: float, tb: int, apron: bool) -> void:
	# оборка
	for y in range(y1 - 2, y1 + 1):
		var c: float = cx + sway
		var hw: float = hw1 + 0.5
		for x in range(int(floor(c - hw)), int(ceil(c + hw))):
			if y == y1 and posmod(x, 3) == 1:
				continue
			var ti: int = 5 if x < c - 2 else (4 if x < c + 4 else 3)
			if y == y1 - 2:
				ti -= 1
			px(im, x, y, WHITE7[ti])
	rows(im, cx, y0, y1 - 2, hw0, hw1, TEAL7, tb, [0.22, 0.42, 0.6, 0.8], sway)
	# лента по подолу
	for x2 in range(int(floor(cx + sway - hw1)), int(ceil(cx + sway + hw1))):
		px(im, x2, y1 - 3, TEAL7[2] if posmod(x2, 2) == 0 else TEAL7[3])
	if apron:
		for y2 in range(y0 + 1, y1 - 5):
			var t: float = float(y2 - y0) / float(y1 - 5 - y0)
			var c2: float = cx + sway * t * t
			var hw2: float = lerpf(3.0, 5.0, t)
			for x3 in range(int(floor(c2 - hw2)), int(ceil(c2 + hw2))):
				var u: float = (x3 + 0.5 - (c2 - hw2)) / (2.0 * hw2)
				var ti2: int = 6 if u < 0.25 else (5 if u < 0.7 else 4)
				if y2 == y1 - 6:
					ti2 = 3 if posmod(x3, 2) == 0 else 4
				px(im, x3, y2, WHITE7[ti2])
		# карман с травами
		for x4 in range(int(cx) - 2, int(cx) + 2):
			px(im, x4, y0 + 9, WHITE7[3])
		px(im, int(cx) - 1, y0 + 8, CAPE7[5])
		px(im, int(cx) - 1, y0 + 7, CAPE7[6])
		px(im, int(cx), y0 + 8, CAPE7[4])
		px(im, int(cx) - 2, y0 + 7, Color("b8a2e4"))


func torso5(im: Image, cx: float, b: int, tb: int, front: bool) -> void:
	rows(im, cx, 22 + b, 33 + b, 5.6, 4.2, WHITE7, tb)
	# корсаж
	for y in range(29 + b, 36 + b):
		var hw: float = 4.4 if y < 33 + b else 4.8 + (y - 33 - b) * 0.3
		for x in range(int(floor(cx - hw)), int(ceil(cx + hw))):
			var u: float = (x + 0.5 - (cx - hw)) / (2.0 * hw)
			var ti: int = 5 if u < 0.25 else (4 if u < 0.65 else 3)
			if y == 29 + b:
				ti += 1
			px(im, x, y, TEAL7[clampi(ti - 1, 0, 6)] if not front else LEATH7[clampi(ti, 0, 6)])
	if front:
		for y2 in range(30 + b, 35 + b):
			px(im, int(cx) - 1 + (y2 % 2), y2, WHITE7[5])
	# воротник и бант
	if front:
		px(im, int(cx) - 2, 22 + b, WHITE7[6])
		px(im, int(cx) + 1, 22 + b, WHITE7[5])
		px(im, int(cx) - 2, 23 + b, TEAL7[5])
		px(im, int(cx) - 3, 22 + b, TEAL7[4])
		px(im, int(cx) - 3, 24 + b, TEAL7[3])
		px(im, int(cx) + 1, 23 + b, TEAL7[4])
		px(im, int(cx) + 2, 22 + b, TEAL7[3])
		px(im, int(cx) + 2, 24 + b, TEAL7[2])
		px(im, int(cx) - 1, 23 + b, TEAL7[3])
		px(im, int(cx), 23 + b, TEAL7[2])
		px(im, int(cx) - 1, 24 + b, TEAL7[4])
		px(im, int(cx) - 1, 25 + b, TEAL7[3])
		px(im, int(cx), 26 + b, TEAL7[3])
		px(im, int(cx) - 2, 26 + b, TEAL7[4])


func arms5(im: Image, cx: float, b: int, hs: int, tl: int, tr: int) -> void:
	blob(im, cx - 6.4, 24.0 + b, 2.8, 2.8, WHITE7, tl)
	blob(im, cx + 6.4, 24.0 + b, 2.8, 2.8, WHITE7, tr)
	rows(im, cx - 7.0, 26 + b, 35 + b + hs, 1.3, 1.8, WHITE7, tl, [], -0.7)
	rows(im, cx + 7.0, 26 + b, 35 + b - hs, 1.3, 1.8, WHITE7, tr, [], 0.7)
	for x in range(int(cx) - 9, int(cx) - 5):
		px(im, x, 35 + b + hs, TEAL7[4])
	for x2 in range(int(cx) + 5, int(cx) + 9):
		px(im, x2, 35 + b - hs, TEAL7[3])
	blob(im, cx - 7.7, 37.0 + b + hs, 1.5, 1.6, SKINL7, 4)
	blob(im, cx + 7.7, 37.0 + b - hs, 1.5, 1.6, SKINL7, 3)


func draw_hero5(im: Image, dir: int, f: int) -> void:
	var b: int = -1 if (f == 1 or f == 3) else 0
	var sw: float = 1.0 if f == 0 else (-1.0 if f == 2 else 0.0)
	var cx: float = 20.0
	var hs: int = 1 if f == 0 else (-1 if f == 2 else 0)
	if dir == 0:
		hair_mass(im, cx, 10 + b, 44 + b, 10.4, 10.8, -sw * 0.8, 3)
		boots5(im, 15, 1 if f == 2 else 0, 0)
		boots5(im, 21, 1 if f == 0 else 0, 0)
		skirt5(im, cx, 35 + b, 58, 5.0, 11.0, sw, 4, true)
		torso5(im, cx, b, 4, true)
		arms5(im, cx, b, hs, 4, 3)
		elf_ear(im, Vector2(cx - 10, 12 + b), -1, 6, 4)
		elf_ear(im, Vector2(cx + 9, 12 + b), 1, 5, 4)
		grid(im, HEAD_FRONT, int(cx) - 13, b, HEAD_PAL)
		# заколка-цветок
		px(im, int(cx) - 7, 5 + b, Color("fff4f6"))
		px(im, int(cx) - 8, 6 + b, Color("f6c6d4"))
		px(im, int(cx) - 6, 6 + b, Color("f6c6d4"))
		px(im, int(cx) - 7, 7 + b, Color("e49ab2"))
		px(im, int(cx) - 7, 6 + b, Color("f6d26a"))
		px(im, int(cx) - 5, 7 + b, CAPE7[5])
	elif dir == 1:
		boots5(im, 15, 1 if f == 2 else 0, 0)
		boots5(im, 21, 1 if f == 0 else 0, 0)
		skirt5(im, cx, 35 + b, 58, 5.0, 11.0, sw, 3, false)
		torso5(im, cx, b, 3, false)
		# бант фартука
		blob(im, cx - 2.5, 35.0 + b, 2.2, 1.5, WHITE7, 5)
		blob(im, cx + 2.5, 35.0 + b, 2.2, 1.5, WHITE7, 4)
		px(im, int(cx), 35 + b, WHITE7[3])
		px(im, int(cx) - 2, 37 + b, WHITE7[5])
		px(im, int(cx) - 2, 38 + b, WHITE7[4])
		px(im, int(cx) + 1, 37 + b, WHITE7[4])
		px(im, int(cx) + 1, 38 + b, WHITE7[3])
		arms5(im, cx, b, -hs, 3, 2)
		elf_ear(im, Vector2(cx - 9, 12 + b), -1, 5, 3)
		elf_ear(im, Vector2(cx + 8, 12 + b), 1, 4, 3)
		blob(im, cx, 11.0 + b, 10.2, 9.6, HAIRL7, 4)
		hair_mass(im, cx, 12 + b, 45 + b, 10.0, 10.8, sw * 0.9, 4)
		for x0 in range(int(cx) - 11, int(cx) + 12):
			for band in [8, 22, 34]:
				var yb: int = int(band) + b + int(round(sin(x0 * 0.9) * 1.0))
				if a_at(im, x0, yb) > 0.5 and a_at(im, x0, yb + 1) > 0.5:
					px(im, x0, yb, HAIRL7[6] if posmod(x0, 3) != 0 else HAIRL7[5])
					px(im, x0, yb + 1, HAIRL7[5] if posmod(x0, 3) != 0 else HAIRL7[4])
		for xs in [int(cx) - 6, int(cx) - 1, int(cx) + 4, int(cx) + 8]:
			for y6 in range(14 + b, 44 + b):
				var xw: int = int(xs) + int(round(sin(y6 * 0.4) * 1.2))
				if a_at(im, xw, y6) > 0.5:
					px(im, xw, y6, HAIRL7[2])
		# лента
		for p in [Vector2i(-2, 18), Vector2i(-1, 19), Vector2i(0, 19), Vector2i(1, 18), Vector2i(-3, 17), Vector2i(2, 17), Vector2i(-3, 19), Vector2i(2, 19), Vector2i(-1, 21), Vector2i(0, 22)]:
			var pv: Vector2i = p
			px(im, int(cx) + pv.x, pv.y + b, TEAL7[5] if pv.x < 0 else TEAL7[3])
		px(im, int(cx) + 1, 1 + b, HAIRL7[4])
		px(im, int(cx) + 2, 0 + b, HAIRL7[5])
	else:
		var fd: int = -3 if f == 0 else (3 if f == 2 else 0)
		hair_mass(im, cx + 5.0, 10 + b, 44 + b, 6.5, 7.0, sw * 1.4 + 1.0, 3)
		boots5(im, 19 - fd, 0 if f != 1 and f != 3 else 1, -1)
		boots5(im, 18 + fd, 0, -1)
		skirt5(im, cx + 0.5, 35 + b, 58, 4.4, 8.6, -sw * 0.8, 4, false)
		# край фартука спереди
		for y in range(36 + b, 53):
			var t: float = float(y - 36 - b) / float(17 - b)
			var x0: int = int(floor(cx + 0.5 - lerpf(4.4, 8.6, t * 0.9) - sw * 0.8 * t * t))
			px(im, x0, y, WHITE7[6])
			px(im, x0 + 1, y, WHITE7[5])
		rows(im, cx, 22 + b, 33 + b, 4.0, 3.4, WHITE7, 4)
		for y2 in range(29 + b, 36 + b):
			for x2 in range(int(cx) - 4, int(cx) + 4):
				px(im, x2, y2, LEATH7[5 if x2 < int(cx) - 1 else 4] if y2 > 29 + b else LEATH7[6])
		px(im, int(cx) - 4, 23 + b, TEAL7[5])
		px(im, int(cx) - 5, 24 + b, TEAL7[4])
		px(im, int(cx) - 4, 25 + b, TEAL7[3])
		# рука
		blob(im, cx + 0.5, 24.0 + b, 2.7, 2.7, WHITE7, 4)
		var hand: Vector2 = Vector2(cx - sw * 4.0, 37.0 + b)
		for i in range(8):
			var pp: Vector2 = Vector2(cx + 0.5, 26.0 + b).lerp(hand, float(i) / 8.0)
			blob(im, pp.x, pp.y, 1.6, 1.4, WHITE7, 4)
		for k in range(3):
			px(im, int(hand.x) - 1 + k, int(hand.y) - 2, TEAL7[4])
		blob(im, hand.x, hand.y, 1.5, 1.6, SKINL7, 4)
		grid(im, HEAD_SIDE, int(cx) - 12, b, HEAD_PAL)
		elf_ear(im, Vector2(cx + 3, 12 + b), 1, 6, 4)
		px(im, int(cx) + 3, 4 + b, Color("fff4f6"))
		px(im, int(cx) + 2, 5 + b, Color("f6c6d4"))
		px(im, int(cx) + 4, 5 + b, Color("e49ab2"))
		px(im, int(cx) + 3, 5 + b, Color("f6d26a"))


func gen_player5() -> void:
	_head_pal()
	var fw: int = 40
	var fh: int = 64
	var sheet: Image = new_img(fw * 4, fh * 4)
	for dir in range(3):
		for f in range(4):
			var cell: Image = new_img(fw, fh)
			draw_hero5(cell, dir, f)
			outline_auto(cell, 0.66)
			sheet.blit_rect(cell, Rect2i(0, 0, fw, fh), Vector2i(f * fw, dir * fh))
			if dir == 2:
				var m: Image = cell.duplicate()
				m.flip_x()
				sheet.blit_rect(m, Rect2i(0, 0, fw, fh), Vector2i(f * fw, 3 * fh))
	save3(sheet, "player")
	var big: Image = sheet.duplicate()
	big.resize(sheet.get_width() * 4, sheet.get_height() * 4, Image.INTERPOLATE_NEAREST)
	big.save_png(ProjectSettings.globalize_path("res://").path_join("../screenshots/player_zoom.png"))


# ---------------------------------------------------------------- чёрный кот

var CATB7: Array = []


var CAT_HAPPY: bool = false


## Кот идёт (вид сбоку, смотрит влево): тело, голова, хвост трубой, 4 лапы по очереди
func _cat_walk5(im: Image, f: int) -> void:
	var ph: float = f * PI / 2.0
	var bob: float = 0.5 if f % 2 == 1 else 0.0
	# хвост
	for k in range(12):
		var t: float = float(k) / 11.0
		var tx: float = 28.0 + t * 4.0 + sin(ph + t * 2.0) * 1.2
		var ty: float = 18.0 - t * 12.0
		blob(im, tx, ty, 1.7, 1.7, CATB7, 3)
	# дальние лапы
	for leg in [[13.0, 0.0], [24.0, PI]]:
		var lx: float = float(leg[0]) + sin(ph + float(leg[1]) + PI / 2.0) * 2.0
		for y in range(22, 29):
			px(im, int(lx), y, CATB7[2])
			px(im, int(lx) + 1, y, CATB7[1])
	# тело
	blob(im, 18.5, 18.0 + bob, 10.5, 5.6, CATB7, 3)
	# ближние лапы
	for leg2 in [[11.0, 0.0], [22.0, PI]]:
		var lx2: float = float(leg2[0]) + sin(ph + float(leg2[1])) * 2.4
		for y2 in range(22, 29):
			px(im, int(lx2), y2, CATB7[4] if y2 < 27 else CATB7[3])
			px(im, int(lx2) + 1, y2, CATB7[3])
		px(im, int(lx2) - 1, 28, CATB7[3])
	# голова
	cat_ear5(im, Vector2(6, 3), 4.0, 8.5, 8.0, true)
	cat_ear5(im, Vector2(11, 3), 9.5, 13.0, 8.0, false)
	blob(im, 8.5, 11.5 + bob, 5.6, 4.8, CATB7, 3)
	blob(im, 5.0, 13.5 + bob, 2.4, 1.6, CATB7, 4)
	# глаз, нос, усы
	px(im, 6, 10, Color("c8dc58"))
	px(im, 7, 10, Color("a8c040"))
	px(im, 6, 11, Color("100c14"))
	px(im, 7, 11, Color("d4e870"))
	px(im, 6, 10, Color("ffffff"))
	px(im, 3, 13, Color("d47c94"))
	for k2 in range(4):
		px(im, 2 - k2 + 3, 14 + k2 / 2, CATB7[6] if k2 < 2 else CATB7[5])
	for x3 in range(14, 24):
		px(im, x3, 13, CATB7[5] if x3 < 19 else CATB7[4])


func gen_cat5() -> void:
	CATB7 = hx(["0c0a16", "171326", "221c36", "2e2748", "40375e", "584c7a", "7a6ea2"])
	# кадры: 0-1 сидит, 2-3 спит, 4-5 жмурится от глажки, 6-9 идёт (смотрит влево)
	var sheet: Image = new_img(360, 30)
	for f in range(10):
		var im: Image = new_img(36, 30)
		CAT_HAPPY = f == 4 or f == 5
		if f < 2:
			_cat_sit5(im, f)
		elif f < 4:
			_cat_sleep5(im, f - 2)
		elif f < 6:
			_cat_sit5(im, f - 4)
		else:
			_cat_walk5(im, f - 6)
		CAT_HAPPY = false
		outline_auto(im, OUTLINE_CHAR)
		sheet.blit_rect(im, Rect2i(0, 0, 36, 30), Vector2i(f * 36, 0))
	save3(sheet, "cat")
	var big: Image = sheet.duplicate()
	big.resize(360 * 4, 30 * 4, Image.INTERPOLATE_NEAREST)
	big.save_png(ProjectSettings.globalize_path("res://").path_join("../screenshots/cat_zoom.png"))


## Высокое острое ухо: tip — кончик, base_l/base_r — края основания
func cat_ear5(im: Image, tip: Vector2, bl0: float, br0: float, by: float, front: bool) -> void:
	for y in range(int(tip.y), int(by) + 1):
		var t: float = (y - tip.y) / maxf(1.0, by - tip.y)
		var xl: float = lerpf(tip.x, bl0, t)
		var xr: float = lerpf(tip.x, br0, t)
		for x in range(int(floor(xl)), int(ceil(xr)) + 1):
			var u: float = (x - xl) / maxf(1.0, xr - xl)
			var c: Color = CATB7[4] if u < 0.3 else CATB7[3]
			if front and t > 0.35 and u > 0.3 and u < 0.8:
				c = Color("c8788c") if u < 0.55 else Color("9a5470")
			px(im, x, y, c)


func cat_eye5(im: Image, x: int, y: int) -> void:
	# миндалевидный глаз: жёлто-зелёный, узкий зрачок, блик
	px(im, x, y, Color("a8c040"))
	px(im, x + 1, y, Color("c8dc58"))
	px(im, x + 2, y, Color("a8c040"))
	px(im, x - 1, y + 1, Color("8aa030"))
	px(im, x, y + 1, Color("d4e870"))
	px(im, x + 1, y + 1, Color("100c14"))
	px(im, x + 2, y + 1, Color("e8f490"))
	px(im, x + 3, y + 1, Color("8aa030"))
	px(im, x, y + 2, Color("c8dc58"))
	px(im, x + 1, y + 2, Color("100c14"))
	px(im, x + 2, y + 2, Color("d4e870"))
	px(im, x, y, Color("ffffff"))


func _cat_sit5(im: Image, f: int) -> void:
	# хвост: от бедра вправо и вверх крючком
	var pts: Array = []
	for k in range(16):
		var t: float = float(k) / 15.0
		var tx: float = 27.0 + sin(t * 2.0) * 6.0
		var ty: float = 27.0 - t * 17.0
		if t > 0.75:
			tx -= (t - 0.75) * 10.0 * (1.3 if f == 1 else 1.0)
		if f == 1:
			tx += t * t * 1.5
		pts.append(Vector2(tx, ty))
	for p0 in pts:
		var p: Vector2 = p0
		blob(im, p.x, p.y, 1.9, 1.9, CATB7, 3)
	# задняя лапа-бедро
	blob(im, 22.5, 22.0, 7.0, 6.4, CATB7, 3)
	# спина
	blob(im, 18.0, 18.0, 6.5, 6.0, CATB7, 3)
	# грудка
	blob(im, 13.5, 18.5, 5.4, 6.8, CATB7, 3)
	# передние лапы: прямые столбики
	for lx in [10.5, 15.0]:
		var lxf: float = float(lx)
		for y in range(19, 28):
			for x in range(int(lxf) - 1, int(lxf) + 2):
				var u: int = x - int(lxf) + 1
				var ti: int = 4 if u == 0 else (3 if u == 1 else 2)
				if lxf > 12.0:
					ti -= 1
				px(im, x, y, CATB7[clampi(ti, 0, 6)])
		px(im, int(lxf) - 1, 28, CATB7[3])
		px(im, int(lxf), 28, CATB7[4])
		px(im, int(lxf) + 1, 28, CATB7[2])
		px(im, int(lxf) + 2, 28, CATB7[2])
	# лапа задняя на земле
	blob(im, 22.0, 27.6, 3.2, 1.5, CATB7, 2)
	# уши (рисуем до головы)
	cat_ear5(im, Vector2(7, 0), 5.5, 11.0, 6.0, true)
	cat_ear5(im, Vector2(19, 0), 15.0, 20.5, 6.0, true)
	# голова
	blob(im, 12.8, 9.2, 7.2, 5.8, CATB7, 3)
	# щёки-пушок
	px(im, 5, 11, CATB7[3])
	px(im, 5, 12, CATB7[2])
	px(im, 20, 11, CATB7[2])
	px(im, 20, 12, CATB7[1])
	# мордочка
	blob(im, 12.8, 11.8, 2.8, 1.8, CATB7, 4)
	if CAT_HAPPY:
		# зажмурился: светлые дужки «^^»
		for ex in [8, 15]:
			for d in [Vector2i(-1, 2), Vector2i(0, 1), Vector2i(1, 0), Vector2i(2, 1), Vector2i(3, 2)]:
				var dv: Vector2i = d
				px(im, int(ex) + dv.x, 7 + dv.y, CATB7[6])
		px(im, 9, 12, Color("e898aa"))
		px(im, 16, 12, Color("e898aa"))
	else:
		cat_eye5(im, 8, 7)
		cat_eye5(im, 15, 7)
	px(im, 12, 11, Color("d47c94"))
	px(im, 13, 11, Color("e898aa"))
	px(im, 12, 12, CATB7[1])
	px(im, 11, 13, CATB7[1])
	px(im, 14, 13, CATB7[1])
	# усы
	for s in [-1, 1]:
		var sv: int = int(s)
		for k2 in range(4):
			px(im, 12 + sv * (4 + k2) + (1 if sv > 0 else 0), 12 + (k2 / 2), CATB7[6] if k2 < 2 else CATB7[5])
	# блик на макушке и спине
	for x2 in range(9, 14):
		px(im, x2, 4, CATB7[5])
	for x3 in range(15, 21):
		px(im, x3, 12 + absi(x3 - 17) / 2, CATB7[5] if x3 < 18 else CATB7[4])


func _cat_sleep5(im: Image, f: int) -> void:
	var ry: float = 6.6 + f * 0.6
	# тело калачиком
	blob(im, 20.5, 21.5 - f * 0.4, 12.5, ry, CATB7, 3)
	# хвост обнимает спереди
	for k in range(18):
		var tx: float = 32.0 - k * 1.3
		var ty: float = 26.5 + sin(k * 0.3) * 0.6
		blob(im, tx, ty, 1.9, 1.7, CATB7, 3)
	# уши и голова
	cat_ear5(im, Vector2(5, 12), 3.0, 8.5, 17.0, true)
	cat_ear5(im, Vector2(14, 12), 11.0, 16.5, 17.0, true)
	blob(im, 10.0, 20.5, 7.0, 5.4, CATB7, 3)
	blob(im, 10.0, 23.0, 2.8, 1.7, CATB7, 4)
	# закрытые глаза — светлые дужки
	for ex in [6, 12]:
		var e: int = int(ex)
		px(im, e - 1, 20, CATB7[6])
		px(im, e, 21, CATB7[6])
		px(im, e + 1, 21, CATB7[6])
		px(im, e + 2, 20, CATB7[6])
	px(im, 9, 22, Color("d47c94"))
	px(im, 10, 22, Color("e898aa"))
	# лапка
	blob(im, 15.5, 26.0, 2.6, 1.5, CATB7, 4)
	# блик по спине
	for x in range(14, 28):
		var yy: int = int(15.5 - f * 0.4 + absf(x - 21) * 0.25)
		px(im, x, yy, CATB7[5])


# ================================================================== v6: героиня как на референсе (56x112, масштаб 0.5)

const H6_TOP: Array = [
	"...............hHh",
	"..............h..Hh",
	"..............h...H",
	"...............hHh",
	"................H",
	".........hHHHHHHHHHh",
	".......hHHHHLLLHHHHHHh",
	"......hHHHLLLLLLHHHHHHHh",
	".....hHHHLLLHHHHHHHHHHHHh",
	"....hHHHHHHHHHHHHHHHHHHHHh",
	"....hHHHhHHHHHhHHHHHhHHHHh",
	"...hHHHHhHHHHHhHHHHHHhHHHHh",
	"...hHHHHHHHHHHHHHHHHHHHHHHh",
	"...hHHHhHHHHHHhHHHHHHhHHHHh",
]
## Лицо и чёлка: 16 столбцов между прядями (строки 14..33)
## Аниме-лицо: большие глаза 5x6 (ресницы, радужка с переливом, двойной блик), брови, румянец
const H6_FACE: Array = [
	"HHHhHHHHHhHHHhHH",
	"SHHSHHHHHShHHShS",
	"SShSShHHhSShHSSS",
	"SddSSSShSSSSddSS",
	"EEEEEESSSSEEEEEE",
	"SEIWWISSSSEIWWIS",
	"SwIIWISSSSwIIWIS",
	"SwIiiISSSSwIiiIS",
	"SwijjiSSSSwijjiS",
	"SSeeeSSSSSSeeeSS",
	"SBBSSSSSSSSSSBBS",
	"SSSSSSSTSSSSSSSS",
	"TSSSSSSSSSSSSSST",
	"TSSSSSSMMSSSSSST",
	".TSSSSSSSSSSSST.",
	"..TSSSSSSSSSST..",
	"...TTSSSSSSTT...",
	".....TTSSTT.....",
	"......TSST......",
	"......TSST......",
]
## Лицо вполоборота влево
const H6_FACE34: Array = [
	"HHHhHHHHHhHHHhHH",
	"SHHSHHHHHShHHShH",
	"SShSShHHhSShHShH",
	"ddSSSSSddSSSSShH",
	"EEESSSEEEEEESSSh",
	"IWISSSEIWWISSSSh",
	"IWISSSwIIWISSSSh",
	"iiISSSwIiiISSSSh",
	"ijiSSSwijjiSSSSh",
	"eeSSSSSeeeSSSSSh",
	"BSSSSSSSBBSSSSSh",
	"SSTSSSSSSSSSSSSh",
	"SSSSSSSSSSSSSSTh",
	"SSMMSSSSSSSSSSTh",
	"TSSSSSSSSSSSSTh.",
	".TSSSSSSSSSSTh..",
	"..TTSSSSSSTT....",
	"....TTSSSTT.....",
	".....TSST.......",
	".....TSST.......",
]


func head6(im: Image, ox: int, oy: int, three_q: bool) -> void:
	var pal: Dictionary = HEAD_PAL.duplicate()
	pal["E"] = Color("2a1622")
	pal["I"] = Color("4a2630")
	pal["i"] = Color("8e4e48")
	pal["j"] = Color("d08a62")
	pal["w"] = Color("f6f0ee")
	pal["e"] = Color("c88a8a")
	pal["W"] = Color("ffffff")
	pal["d"] = HAIRL7[2]
	pal["B"] = Color("f7b4b0")
	pal["M"] = Color("d8767a")
	var rows6: Array = H6_TOP.duplicate()
	var face: Array = H6_FACE34 if three_q else H6_FACE
	for i in range(face.size()):
		var lockl: String = "..hH" if three_q else "hHHh"
		var lockr: String = "HHHh" if three_q else "hHHh"
		if i > 14:
			lockl = "...." if three_q else "hHh."
			lockr = "HHh." if three_q else ".hHh"
		rows6.append("..." + lockl + String(face[i]) + lockr)
	grid(im, rows6, ox, oy, pal)


## Вьющиеся локоны, торчащие из массы волос
func curls(im: Image, cx: float, y0: int, y1: int, hw: float, seed_v: int) -> void:
	for side in [-1, 1]:
		var s: float = float(side)
		var y: int = y0
		var k: int = 0
		while y < y1:
			var len0: int = 3 + int(h01(k, seed_v, 2) * 4.0)
			var x0: float = cx + s * (hw - 1.0)
			for j in range(len0):
				var xx: int = int(round(x0 + s * j * 0.7))
				var yy: int = y + j + int(round(sin(j * 0.9 + k) * 0.8))
				px(im, xx, yy, HAIRL7[4] if j < len0 - 1 else HAIRL7[3])
				px(im, xx - int(s), yy, HAIRL7[3])
			y += 8 + int(h01(k, seed_v, 5) * 6.0)
			k += 1


## Нога по абсолютной высоте: колено всегда на одной строке (82), при шаге укорачивается только голень
func leg6(im: Image, cx: float, top: int, bot: int, tb: int) -> void:
	var knee: int = 82
	for y in range(top, bot + 1):
		var hw: float
		if y <= knee:
			hw = lerpf(3.7, 2.3, float(y - top) / float(maxi(1, knee - top)))
		else:
			var t: float = float(y - knee) / float(maxi(1, bot - knee))
			hw = 2.3 + sin(clampf(t * 1.6, 0.0, PI)) * 0.55 - t * 0.5
		for x in range(int(floor(cx - hw)), int(ceil(cx + hw))):
			var u: float = (x + 0.5 - (cx - hw)) / (2.0 * hw)
			var ti: int = tb + 1 if u < 0.32 else (tb if u < 0.72 else tb - 1)
			if (y == knee or y == knee + 1) and u > 0.35 and u < 0.65:
				ti = tb - 1 if y == knee + 1 else tb + 1
			px(im, x, y, SKINL7[clampi(ti, 0, 6)])


func boot6(im: Image, cx: float, top: int, toe: int) -> void:
	for y in range(top, top + 11):
		var hw: float = 2.7 if y < top + 9 else 3.0
		var sx: float = cx + (float(toe) * 0.8 if y > top + 7 else 0.0)
		for x in range(int(floor(sx - hw)), int(ceil(sx + hw))):
			var u: float = (x + 0.5 - (sx - hw)) / (2.0 * hw)
			var ti: int = 4 if u < 0.3 else (3 if u < 0.7 else 2)
			if y == top:
				ti = 5
			if y == top + 10:
				ti = 0
			if (y - top) % 3 == 1 and absf(x + 0.5 - sx) < 1.0 and y < top + 8:
				ti = 5
			px(im, x, y, LEATH7[clampi(ti, 0, 6)])


func cape6(im: Image, cx: float, y0: int, y1: int, sway: float, open: bool, inner: bool) -> void:
	for y in range(y0, y1 + 1):
		var t: float = float(y - y0) / float(y1 - y0)
		var c: float = cx + sway * t * t * 2.0
		var outer: float = lerpf(8.5, 21.0, pow(t, 0.8)) + sin(y * 0.35) * 0.8 * t
		var opening: float = lerpf(5.5, 10.0, t) if open else -1.0
		var hem: int = y1 - int(round((sin((0.0) + y * 0.0) + 1.0)))
		for x in range(int(floor(c - outer)), int(ceil(c + outer))):
			var dx: float = x + 0.5 - c
			var hem_y: float = y1 - 2.0 + sin(dx * 0.5) * 1.5 + absf(dx) * 0.12
			if y > hem_y:
				continue
			if inner:
				px(im, x, y, TEAL7[1] if absf(dx) < outer - 2.0 else TEAL7[2])
				continue
			if absf(dx) < opening:
				continue
			var u: float = (dx + outer) / (2.0 * outer)
			var ti: int = 5 if u < 0.2 else (4 if u < 0.5 else (3 if u < 0.85 else 2))
			var fold: float = sin(dx / outer * 11.0 + t * 1.5)
			if t > 0.1 and fold > 0.8:
				ti -= 1
			elif t > 0.1 and fold < -0.88:
				ti += 1
			if open and absf(dx) < opening + 1.2:
				ti = 6 if dx < 0.0 else 5
			if y > hem_y - 1.0:
				ti -= 2
			# потёртые пятна-узор как на референсе
			if h01(x / 3, y / 3, 17) > 0.93 and ti > 2:
				ti -= 1
			px(im, x, y, TEAL7[clampi(ti, 0, 6)])


func shirt6(im: Image, cx: float, b: int, back: bool) -> void:
	for y in range(34 + b, 54 + b):
		var t: float = float(y - 34 - b) / 19.0
		# силуэт: покатые плечи -> грудь -> узкая талия
		var hw: float
		if t < 0.12:
			hw = lerpf(5.5, 7.8, t / 0.12)
		elif t < 0.45:
			hw = lerpf(7.8, 7.0, (t - 0.12) / 0.33)
		elif t < 0.82:
			hw = lerpf(7.0, 4.9, (t - 0.45) / 0.37)
		else:
			hw = lerpf(4.9, 5.4, (t - 0.82) / 0.18)
		for x in range(int(floor(cx - hw)), int(ceil(cx + hw))):
			var u: float = (x + 0.5 - (cx - hw)) / (2.0 * hw)
			var ti: int = 6 if u < 0.25 else (5 if u < 0.6 else (4 if u < 0.85 else 3))
			# мягкая тень под грудью и складки к талии
			if not back and t > 0.36 and t < 0.44 and absf(u - 0.5) > 0.08 and absf(u - 0.5) < 0.38:
				ti -= 1
			if t > 0.5 and (absf(u - 0.22) < 0.05 or absf(u - 0.78) < 0.05):
				ti -= 1
			px(im, x, y, WHITE7[clampi(ti, 0, 6)])
	if back:
		return
	# воротник-кружок и бирюзовые линии вниз
	for k in range(-4, 5):
		var yy: int = 35 + b + int(round(absf(k) * -0.35 + 1.4))
		px(im, int(cx) + k, yy, TEAL7[3])
	for y2 in range(37 + b, 52 + b):
		px(im, int(cx) - 3, y2, TEAL7[3])
		px(im, int(cx) + 3, y2, TEAL7[2])
	for y3 in [40, 44, 48]:
		px(im, int(cx), int(y3) + b, WHITE7[2])
	# ключицы
	px(im, int(cx) - 1, 34 + b, SKINL7[4])
	px(im, int(cx), 34 + b, SKINL7[4])
	px(im, int(cx) + 1, 34 + b, SKINL7[3])


func belt6(im: Image, cx: float, b: int, hw: float) -> void:
	for y in range(52 + b, 56 + b):
		for x in range(int(floor(cx - hw)), int(ceil(cx + hw))):
			var u: float = (x + 0.5 - (cx - hw)) / (2.0 * hw)
			var ti: int = 3 if u < 0.3 else (2 if u < 0.75 else 1)
			if y == 52 + b or y == 54 + b:
				ti += 1
			px(im, x, y, LEATH7[clampi(ti, 0, 6)])
	px(im, int(cx) + 1, 52 + b, Color("f2d06a"))
	px(im, int(cx) + 2, 52 + b, Color("d0a83a"))
	px(im, int(cx) + 1, 53 + b, Color("b88a2c"))
	px(im, int(cx) + 2, 53 + b, Color("8e661c"))


func arm6(im: Image, sh: Vector2, hand: Vector2, tb: int) -> void:
	# кожа руки, поверх полупрозрачный рукав, манжета, кисть
	var n: int = int(sh.distance_to(hand)) + 1
	for i in range(n):
		var t: float = float(i) / float(n)
		var p: Vector2 = sh.lerp(hand, t)
		var hw: float = lerpf(1.9, 2.6, t)
		var wrist: bool = t > 0.86
		if wrist:
			hw = 1.5
		for y in range(int(p.y) - 1, int(p.y) + 1):
			for x in range(int(floor(p.x - hw)), int(ceil(p.x + hw))):
				var u: float = (x + 0.5 - (p.x - hw)) / (2.0 * hw)
				var ti: int = tb + 1 if u < 0.3 else (tb if u < 0.7 else tb - 1)
				var c: Color = WHITE7[clampi(ti, 0, 6)]
				if wrist:
					c = SKINL7[clampi(ti, 0, 6)]
				elif absf(u - 0.5) < 0.22:
					c = c.lerp(SKINL7[4], 0.35)
				px(im, x, y, c)
	blob(im, sh.x, sh.y + 1.0, 3.0, 3.2, WHITE7, tb + 1)
	var cuff: Vector2 = sh.lerp(hand, 0.86)
	for x2 in range(int(cuff.x) - 3, int(cuff.x) + 3):
		px(im, x2, int(cuff.y), TEAL7[4])
		px(im, x2, int(cuff.y) + 1, WHITE7[5])
	blob(im, hand.x, hand.y + 1.5, 2.2, 3.2, SKINL7, 4)
	px(im, int(hand.x) - 1, int(hand.y) + 4, SKINL7[3])
	px(im, int(hand.x), int(hand.y) + 4, SKINL7[2])


func draw_hero6(im: Image, dir: int, f: int) -> void:
	var b: int = -1 if (f == 1 or f == 3) else 0
	var sw: float = 1.0 if f == 0 else (-1.0 if f == 2 else 0.0)
	var cx: float = 28.0
	var hs: float = 1.5 * sw
	if dir == 0:
		hair_mass(im, cx, 14 + b, 66 + b, 13.0, 15.0, -sw * 0.8, 3)
		curls(im, cx, 30 + b, 64 + b, 15.0, 3)
		cape6(im, cx, 53 + b, 107, sw, false, true)
		var ll: int = 2 if f == 2 else 0
		var lr: int = 2 if f == 0 else 0
		leg6(im, cx - 3.5, 60 + b, 100 - ll, 4)
		leg6(im, cx + 3.5, 60 + b, 100 - lr, 4)
		boot6(im, cx - 3.4, 99 - ll, 0)
		boot6(im, cx + 3.4, 99 - lr, 0)
		rows(im, cx, 54 + b, 66 + b, 6.4, 9.2, WHITE7, 5, [0.3, 0.7])
		for x in range(int(cx) - 8, int(cx) + 9):
			px(im, x, 66 + b, TEAL7[3])
		cape6(im, cx, 53 + b, 107, sw, true, false)
		shirt6(im, cx, b, false)
		belt6(im, cx, b, 5.8)
		arm6(im, Vector2(cx - 8.6, 37 + b), Vector2(cx - 13.0 - hs * 0.3, 75 + b + hs), 4)
		arm6(im, Vector2(cx + 8.6, 37 + b), Vector2(cx + 13.0 - hs * 0.3, 75 + b - hs), 3)
		head6(im, int(cx) - 15, b, false)
		# пряди спадают на плечи
		for side in [-1, 1]:
			var s: float = float(side)
			for y in range(30 + b, 50 + b):
				var t: float = float(y - 30 - b) / 20.0
				var xc: float = cx + s * (10.5 + sin(y * 0.5) * 0.9 + t * 1.5)
				var hw: float = 2.4 - t * 1.2
				for x in range(int(floor(xc - hw)), int(ceil(xc + hw))):
					var u: float = (x + 0.5 - (xc - hw)) / (2.0 * hw)
					var ti: int = 5 if u < 0.35 else (4 if u < 0.75 else 3)
					if s > 0.0:
						ti -= 1
					if posmod(y, 6) == 0:
						ti -= 1
					px(im, x, y, HAIRL7[clampi(ti, 0, 6)])
	elif dir == 1:
		cape6(im, cx, 53 + b, 107, sw, false, false)
		boot6(im, cx - 3.4, 99 - (2 if f == 2 else 0), 0)
		boot6(im, cx + 3.4, 99 - (2 if f == 0 else 0), 0)
		cape6(im, cx, 53 + b, 105, sw, false, false)
		shirt6(im, cx, b, true)
		belt6(im, cx, b, 5.8)
		arm6(im, Vector2(cx - 8.6, 37 + b), Vector2(cx - 13.0, 75 + b - hs), 3)
		arm6(im, Vector2(cx + 8.6, 37 + b), Vector2(cx + 13.0, 75 + b + hs), 2)
		blob(im, cx, 17.0 + b, 12.6, 12.0, HAIRL7, 4)
		hair_mass(im, cx, 18 + b, 68 + b, 13.0, 15.0, sw * 0.9, 4)
		curls(im, cx, 30 + b, 66 + b, 15.0, 4)
		for x0 in range(int(cx) - 14, int(cx) + 15):
			for band in [10, 30, 50]:
				var yb: int = int(band) + b + int(round(sin(x0 * 0.8) * 1.2))
				if a_at(im, x0, yb) > 0.5 and a_at(im, x0, yb + 1) > 0.5:
					px(im, x0, yb, HAIRL7[6] if posmod(x0, 3) != 0 else HAIRL7[5])
					px(im, x0, yb + 1, HAIRL7[5])
		for xs in [-9, -4, 1, 6, 10]:
			for y6 in range(16 + b, 66 + b):
				var xw: int = int(cx) + int(xs) + int(round(sin(y6 * 0.35 + float(xs)) * 1.4))
				if a_at(im, xw, y6) > 0.5:
					px(im, xw, y6, HAIRL7[2])
		# хохолок
		for p in [Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(3, 1), Vector2i(3, 2), Vector2i(1, 3), Vector2i(2, 3), Vector2i(2, 4)]:
			var pv: Vector2i = p
			px(im, int(cx) + pv.x, pv.y + b, HAIRL7[4])
	else:
		var fd: float = -4.0 if f == 0 else (4.0 if f == 2 else 0.0)
		hair_mass(im, cx + 6.0, 14 + b, 64 + b, 8.0, 9.5, sw * 1.4 + 1.5, 3)
		curls(im, cx + 6.0, 30 + b, 62 + b, 9.5, 5)
		# плащ сзади развевается вправо
		for y in range(53 + b, 107):
			var t: float = float(y - 53 - b) / float(54 - b)
			var c: float = cx + 2.0 + t * t * (4.0 - sw * 2.0)
			var back: float = lerpf(6.0, 16.0, pow(t, 0.8))
			var front: float = lerpf(3.0, 4.0, t)
			for x in range(int(floor(c - front)), int(ceil(c + back))):
				var dx: float = x + 0.5 - c
				var hem_y: float = 105.0 + sin(dx * 0.5) * 1.5 + dx * 0.1
				if y > hem_y:
					continue
				var u: float = (dx + front) / (front + back)
				var ti: int = 5 if u < 0.2 else (4 if u < 0.55 else (3 if u < 0.85 else 2))
				if t > 0.15 and sin(dx * 0.9 + t) > 0.85:
					ti -= 1
				if y > hem_y - 1.0:
					ti -= 2
				px(im, x, y, TEAL7[clampi(ti, 0, 6)])
		# ноги шагают
		var back_leg: float = cx + 1.0 - fd * 0.5
		var front_leg: float = cx - 1.0 + fd * 0.5
		leg6(im, back_leg, 60 + b, 100, 3)
		boot6(im, back_leg, 99, -1)
		leg6(im, front_leg, 60 + b, 100 - (2 if f == 1 or f == 3 else 0), 4)
		boot6(im, front_leg, 99 - (2 if f == 1 or f == 3 else 0), -1)
		rows(im, cx, 54 + b, 66 + b, 5.2, 6.6, WHITE7, 5, [0.5])
		for x2 in range(int(cx) - 6, int(cx) + 7):
			px(im, x2, 66 + b, TEAL7[3])
		# торс в профиль
		for y2 in range(34 + b, 54 + b):
			var t2: float = float(y2 - 34 - b) / 19.0
			var hw2: float = lerpf(5.2, 5.6, t2 / 0.4) if t2 < 0.4 else lerpf(5.6, 3.8, (t2 - 0.4) / 0.6)
			var c2: float = cx - (1.0 if t2 > 0.18 and t2 < 0.45 else 0.0)
			for x3 in range(int(floor(c2 - hw2)), int(ceil(c2 + hw2))):
				var u2: float = (x3 + 0.5 - (c2 - hw2)) / (2.0 * hw2)
				px(im, x3, y2, WHITE7[6 if u2 < 0.3 else (5 if u2 < 0.7 else 4)])
		for y3 in range(36 + b, 52 + b):
			px(im, int(cx) - 4, y3, TEAL7[3])
		belt6(im, cx, b, 4.4)
		arm6(im, Vector2(cx + 1.0, 37 + b), Vector2(cx - sw * 6.0, 75 + b), 4)
		head6(im, int(cx) - 16, b, true)


func gen_player6() -> void:
	_head_pal()
	HAIRL7 = hx(["4a3430", "6e5244", "907058", "b08e6e", "c8a884", "dcc4a0", "eee0c4"])
	SKINL7 = hx(["8a5a5a", "b87c74", "dca092", "f0c0ac", "fad8c6", "fde8dc", "fff4ee"])
	_head_pal()
	var fw: int = 56
	var fh: int = 112
	var sheet: Image = new_img(fw * 4, fh * 4)
	for dir in range(3):
		for f in range(4):
			var cell: Image = new_img(fw, fh)
			draw_hero6(cell, dir, f)
			outline_auto(cell, 0.66)
			sheet.blit_rect(cell, Rect2i(0, 0, fw, fh), Vector2i(f * fw, dir * fh))
			if dir == 2:
				var m: Image = cell.duplicate()
				m.flip_x()
				sheet.blit_rect(m, Rect2i(0, 0, fw, fh), Vector2i(f * fw, 3 * fh))
	save3(sheet, "player")
	var big: Image = sheet.duplicate()
	big.resize(sheet.get_width() * 3, sheet.get_height() * 3, Image.INTERPOLATE_NEAREST)
	big.save_png(ProjectSettings.globalize_path("res://").path_join("../screenshots/player_zoom.png"))
	var one: Image = new_img(fw, fh)
	one.blit_rect(sheet, Rect2i(0, 0, fw, fh), Vector2i.ZERO)
	one.resize(fw * 8, fh * 8, Image.INTERPOLATE_NEAREST)
	one.save_png(ProjectSettings.globalize_path("res://").path_join("../screenshots/player_front_big.png"))


# ================================================================== v7: котёл, комната варки, зелья, жители

## Цвета зелий: [тёмный, основной, светлый]
const POTION_COL: Dictionary = {
	"sleep_tea": ["4a3a86", "8a78d0", "c8bcf2"],
	"calm_tea": ["3a7a6a", "7cc0a0", "c4ecd4"],
	"warm_tea": ["9a5a1a", "e0a040", "fbe08a"],
	"mint_tea": ["2a7a5a", "5cc08a", "b4f0c8"],
	"vigor_tea": ["7a3a1e", "c86a32", "f6b07a"],
	"heal_salve": ["b08a3a", "f2d684", "fff4c8"],
	"bruise_salve": ["5a6a2a", "a8b85a", "e2ecac"],
	"cool_salve": ["4a7aa0", "9ccce6", "e2f4fb"],
	"strength_tinct": ["2e5a22", "5e9a3a", "a6d47a"],
	"head_tinct": ["6a2a5a", "b0589a", "eaa2d4"],
	"murky": ["3e3a30", "6e6650", "a49a7a"],
}


func gen_v7() -> void:
	gen_cauldron_world()
	gen_brew_room()
	gen_cauldron_big()
	for id in POTION_COL.keys():
		gen_potion_icon(String(id))
	gen_base_icons()
	gen_coin()


func iron_pot(im: Image, cx: float, cy: float, rx: float, ry: float, liquid: Array) -> void:
	var iron: Array = hx(["141218", "1e1b24", "2a2632", "3a3544", "524c5e", "6e6880", "948eaa"])
	# тело котла
	blob(im, cx, cy, rx, ry, iron, 3)
	# ободок
	for x in range(int(cx - rx * 0.92), int(cx + rx * 0.92) + 1):
		var dx: float = (x + 0.5 - cx) / (rx * 0.92)
		var yy: float = cy - ry * 0.62 + (1.0 - sqrt(maxf(0.0, 1.0 - dx * dx))) * 0.0
		var top: int = int(cy - ry * 0.62 - sqrt(maxf(0.0, 1.0 - dx * dx)) * ry * 0.16)
		var bot: int = int(cy - ry * 0.62 + sqrt(maxf(0.0, 1.0 - dx * dx)) * ry * 0.16)
		for y in range(top - 1, bot + 2):
			var c: Color = iron[5] if dx < -0.3 else (iron[4] if dx < 0.4 else iron[3])
			if y == top - 1 or y == bot + 1:
				c = iron[2] if y == bot + 1 else iron[6]
			px(im, x, y, c)
	# жидкость внутри ободка
	if liquid.size() > 0:
		for x2 in range(int(cx - rx * 0.8), int(cx + rx * 0.8) + 1):
			var dx2: float = (x2 + 0.5 - cx) / (rx * 0.8)
			var hh: float = sqrt(maxf(0.0, 1.0 - dx2 * dx2)) * ry * 0.12
			for y2 in range(int(cy - ry * 0.62 - hh), int(cy - ry * 0.62 + hh) + 1):
				var c2: Color = liquid[1]
				if y2 < cy - ry * 0.62 - hh * 0.4 and dx2 < 0.2:
					c2 = liquid[2]
				elif y2 > cy - ry * 0.62 + hh * 0.5:
					c2 = liquid[0]
				px(im, x2, y2, c2)
	# ножки и ручки
	for s in [-1.0, 1.0]:
		var sv: float = float(s)
		for k in range(4):
			px(im, int(cx + sv * rx * 0.55), int(cy + ry * 0.92) + k, iron[2])
			px(im, int(cx + sv * rx * 0.55) + 1, int(cy + ry * 0.92) + k, iron[1])
		for k2 in range(5):
			var a: float = k2 / 4.0 * PI
			px(im, int(cx + sv * (rx + 1.5 + sin(a) * 2.5)), int(cy - ry * 0.45 + cos(a) * 2.5), iron[4])


func flame(im: Image, cx: float, base: float, w: float, h: float) -> void:
	var fire: Array = hx(["8a2a1a", "c8461e", "ee7a26", "f8b040", "fde27a", "fffbe0"])
	for y in range(int(base - h), int(base) + 1):
		var t: float = (base - y) / h
		var hw: float = w * (1.0 - t) * (0.8 + 0.2 * sin(y * 1.3))
		for x in range(int(cx - hw), int(cx + hw) + 1):
			var u: float = absf(x + 0.5 - cx) / maxf(0.5, hw)
			var ti: int = 5 - int(u * 3.0) - int(t * 2.5)
			px(im, x, y, fire[clampi(ti, 0, 5)])


func gen_cauldron_world() -> void:
	rng.seed = 700
	var im: Image = new_img(60, 60)
	# камни очага
	for s in [Vector3(14, 52, 6), Vector3(30, 55, 7), Vector3(46, 52, 6), Vector3(22, 55, 5), Vector3(39, 55, 5)]:
		var sv: Vector3 = s
		blob(im, sv.x, sv.y, sv.z, sv.z * 0.6, ROCK6, 3)
	# поленья и огонь
	branch(im, Vector2(16, 51), Vector2(42, 47), 4.0, 3.0)
	branch(im, Vector2(18, 47), Vector2(44, 51), 4.0, 3.0)
	flame(im, 24, 50, 5.0, 10.0)
	flame(im, 31, 50, 6.0, 13.0)
	flame(im, 37, 50, 4.0, 9.0)
	var liq: Array = hx(["2e7a4a", "5cc070", "b4f09a"])
	iron_pot(im, 30, 32, 17, 14, liq)
	# пузыри и ложка
	for b in [Vector2i(25, 22), Vector2i(33, 21), Vector2i(29, 23)]:
		var bv: Vector2i = b
		px(im, bv.x, bv.y, Color("d4ffc4"))
		px(im, bv.x + 1, bv.y - 1, Color("ffffff"))
	branch(im, Vector2(38, 22), Vector2(46, 6), 2.0, 2.0)
	clean_specks(im)
	outline_auto(im, 0.55)
	shadow(im, 30, 57, 22, 2.5, 0.2)
	save3(im, "cauldron")


func gen_cauldron_big() -> void:
	var im: Image = new_img(240, 190)
	iron_pot(im, 120, 100, 104, 82, [])
	outline_auto(im, 0.5)
	save3(im, "cauldron_big")
	# жидкость отдельно, её красят в коде
	var lq: Image = new_img(180, 30)
	for y in range(30):
		for x in range(180):
			var dx: float = (x + 0.5 - 90.0) / 88.0
			var dy: float = (y + 0.5 - 15.0) / 14.0
			if dx * dx + dy * dy > 1.0:
				continue
			var v: float = 0.78 - dy * 0.25 - dx * 0.05
			if dy < -0.45 and dx < 0.1 and dx > -0.7:
				v = 1.0
			px(lq, x, y, Color(v, v, v))
	save3(lq, "cauldron_liquid")


func gen_brew_room() -> void:
	rng.seed = 801
	var W: int = 960
	var H: int = 540
	var im: Image = new_img(W, H)
	# стена из досок
	planks(im, 0, 0, W, 410, WOOD, true, 24, 0.50, 3)
	# потолочная балка
	planks(im, 0, 0, W, 26, WOOD, false, 13, 0.32, 5)
	# пол
	planks(im, 0, 410, W, 130, WOOD, false, 22, 0.40, 9)
	for x in range(W):
		px(im, x, 410, WOOD[1])
		px(im, x, 411, WOOD[2])
	# очаг: каменная арка
	stone_wall(im, Rect2i(300, 70, 360, 345), STONE, 22, 26, 44, Color("3a3646"), 0.55)
	for y in range(190, 415):
		for x in range(370, 590):
			var dx: float = (x + 0.5 - 480.0) / 110.0
			var top: float = 190.0 + (1.0 - sqrt(maxf(0.0, 1.0 - dx * dx))) * 60.0
			if y < top + 50.0 * (1.0 - sqrt(maxf(0.0, 1.0 - dx * dx))):
				continue
			var t: float = (y - 190.0) / 225.0
			var c: Color = Color("1c1418").lerp(Color("6a3018"), clampf(t * t * 1.4, 0.0, 1.0))
			c = c.lerp(Color("c8662a"), clampf((t - 0.75) * 2.5, 0.0, 1.0) * (1.0 - absf(dx)))
			px(im, x, y, c)
	# полка-каминная доска со свечами и баночками
	planks(im, 284, 176, 392, 14, WOOD, false, 7, 0.62, 11)
	for cxp in [320, 640]:
		for y in range(150, 176):
			px(im, int(cxp), y, CREAM[3])
			px(im, int(cxp) + 1, y, CREAM[2])
		flame(im, int(cxp) + 0.5, 148, 2.0, 7.0)
	for j in range(5):
		var jx: int = 350 + j * 60 + (20 if j > 1 else 0)
		if absf(jx - 480) < 40:
			continue
		var col: Array = POTION_COL[POTION_COL.keys()[j]]
		_jar(im, jx, 175, 9 + j % 3 * 2, 18 + j % 2 * 6, hx(col))
	# полки слева с банками
	for sy in [120, 220, 320]:
		planks(im, 30, sy, 230, 10, WOOD, false, 5, 0.6, sy)
		for k in range(6):
			var bx: int = 46 + k * 36 + rng.randi_range(-4, 4)
			var keys: Array = POTION_COL.keys()
			var colk: Array = POTION_COL[keys[rng.randi_range(0, keys.size() - 1)]]
			_jar(im, bx, sy, rng.randi_range(8, 12), rng.randi_range(18, 30), hx(colk))
	# окно справа с лесом
	var wr: Rect2i = Rect2i(700, 80, 200, 200)
	for y in range(wr.position.y, wr.end.y):
		for x in range(wr.position.x, wr.end.x):
			var t2: float = float(y - wr.position.y) / wr.size.y
			var c2: Color = Color("f6d6a8").lerp(Color("bfe0e8"), 1.0 - t2)
			px(im, x, y, c2)
	for k in range(9):
		var tx: float = wr.position.x + 10 + k * 24
		var th: float = 60.0 + h01(k, 3, 1) * 50.0
		for y in range(int(wr.end.y - th), wr.end.y):
			var hw: float = (y - (wr.end.y - th)) * 0.32
			for x in range(int(tx - hw), int(tx + hw) + 1):
				if x >= wr.position.x and x < wr.end.x:
					px(im, x, y, L7_PINE[2] if (x + y) % 7 != 0 else L7_PINE[3])
	# рама и крест по центру
	for y in range(wr.position.y - 8, wr.end.y + 8):
		for x in range(wr.position.x - 8, wr.end.x + 8):
			var inside: bool = wr.has_point(Vector2i(x, y))
			var cross: bool = absi(x - (wr.position.x + wr.size.x / 2)) < 4 or absi(y - (wr.position.y + wr.size.y / 2)) < 4
			if not inside or cross:
				var v: float = 0.55 if x < wr.position.x + wr.size.x / 2 else 0.42
				px(im, x, y, pick(WOOD, v + (0.12 if y < wr.position.y else 0.0), x, y))
	planks(im, wr.position.x - 16, wr.end.y + 8, wr.size.x + 32, 12, WOOD, false, 6, 0.65, 21)
	# цветы на подоконнике
	for f in range(4):
		var fx: int = wr.position.x + 20 + f * 50
		_jar(im, fx, wr.end.y + 8, 10, 14, hx(["8a4a2a", "c8743e", "eaa46a"]))
		for k2 in range(5):
			flower5(im, fx - 6 + k2 * 3, wr.end.y - 14 - (k2 % 2) * 5, hx(["b0506e", "e488a8", "fbd2e0"]) if f % 2 == 0 else hx(["5c489a", "927ed0", "d8ccf6"]), Color("f6d86a"))
	# пучки трав под балкой
	for hb in range(12):
		var hx0: int = 30 + hb * 80 + rng.randi_range(-10, 10)
		if hx0 > 290 and hx0 < 670:
			continue
		var ln: int = rng.randi_range(40, 70)
		line(im, hx0, 26, hx0, 34, Color("8a6a40"))
		var herb_r: Array = [L7_MINT, L7_SAGE, L7_GREEN, L7_LIME][hb % 4]
		for k3 in range(16):
			var a: float = rng.randf_range(-0.5, 0.5)
			var l2: float = rng.randf_range(ln * 0.6, ln)
			draw_leaf(im, Vector2(hx0 + sin(a) * l2 * 0.5, 34 + l2 * 0.5), Vector2(sin(a), 1), l2 * 0.5, 4.0, 3 + k3 % 3, herb_r)
		for x3 in range(hx0 - 3, hx0 + 4):
			px(im, x3, 35, Color("c45a6a"))
	# ковёр
	for y in range(450, 530):
		for x in range(250, 710):
			var dx3: float = (x + 0.5 - 480.0) / 230.0
			var dy3: float = (y + 0.5 - 490.0) / 40.0
			if dx3 * dx3 + dy3 * dy3 > 1.0:
				continue
			var ring: float = sqrt(dx3 * dx3 + dy3 * dy3)
			var c3: Color = Color("8e3a3a") if ring > 0.88 else (Color("d8a454") if ring > 0.82 else (Color("6e2a34") if posmod(int(ring * 12.0), 2) == 0 else Color("7e3240")))
			px(im, x, y, c3)
	# мягкая виньетка
	for y in range(H):
		for x in range(W):
			var d: float = Vector2((x - W / 2.0) / W, (y - H / 2.0) / H).length()
			var k4: float = clampf((d - 0.35) * 1.3, 0.0, 0.45)
			var c4: Color = im.get_pixel(x, y)
			im.set_pixel(x, y, c4.darkened(k4))
	im.save_png(OUT + "brew_room.png")


func _jar(im: Image, cx: int, base: int, w: int, h: int, col: Array) -> void:
	var glass: Array = hx(["4a5a6a", "8aa0b4", "d4e4ee"])
	for y in range(base - h, base):
		var t: float = float(y - (base - h)) / float(h)
		var hw: float = float(w) * (0.45 if t < 0.25 else 1.0) * 0.5
		for x in range(int(cx - hw), int(cx + hw) + 1):
			var u: float = (x + 0.5 - (cx - hw)) / (2.0 * hw + 0.01)
			var c: Color = glass[1]
			if t > 0.38:
				c = col[1] if u < 0.65 else col[0]
				if u < 0.22:
					c = col[2]
			if u < 0.15 and t > 0.25:
				c = glass[2]
			if x == int(cx - hw) or x == int(cx + hw):
				c = glass[0]
			px(im, x, y, c)
	for x2 in range(cx - w / 4, cx + w / 4 + 1):
		px(im, x2, base - h - 1, Color("a07040"))
		px(im, x2, base - h - 2, Color("c8945a"))


## ================================================================== интерьер домика
## Компактный домик, вид сверху. Картинка 640x360, дом в центре: x 170..470, y 70..292.
## Как снаружи: кремовая штукатурка, тёмные балки, каменный цоколь, деревянные рамы, тёплый свет.
## Кухня слева (x 180..316), спальня справа (x 324..460), между ними перегородка до y 198.
## Дверь внизу по центру (x 302..338). Окна на задней стене показывают двор.

func gen_interior() -> void:
	gen_interior_base()
	gen_in_stove()
	gen_in_counter()
	gen_in_table()
	gen_in_stool()
	gen_in_basket()
	gen_in_barrel()
	gen_in_plant()
	gen_in_bed()
	gen_in_wardrobe(false)
	gen_in_wardrobe(true)
	gen_in_nightstand()
	gen_rod_icon()
	gen_mop()
	gen_net()
	gen_outhouse()
	gen_need_icons()
	gen_cozy()   # новая маленькая уютная комната (перезаписывает interior_floor)


func dim_px(im: Image, x: int, y: int, a: float) -> void:
	bl(im, x, y, Color(0.05, 0.03, 0.08, a))


func beam_v(im: Image, x: int, y: int, w: int, h: int) -> void:
	rect(im, x, y, w, h, WOOD[2])
	rect(im, x, y, 1, h, WOOD[4])
	rect(im, x + w - 1, y, 1, h, WOOD[0])


func beam_h(im: Image, x: int, y: int, w: int, h: int) -> void:
	rect(im, x, y, w, h, WOOD[2])
	rect(im, x, y, w, 1, WOOD[4])
	rect(im, x, y + h - 1, w, 1, WOOD[0])


func gen_interior_base() -> void:
	var im: Image = new_img(640, 360)
	rect(im, 0, 0, 640, 360, Color("1a1620"))
	# кухня: каменные плиты, как цоколь снаружи
	var flag: Array = [Color("6e6a82"), Color("807c94"), Color("9490a6"), Color("a8a4b8")]
	rect(im, 180, 130, 144, 152, Color("4a4658"))
	var row: int = 0
	var yy: int = 130
	while yy < 282:
		var xx: int = 180 - (row % 2) * 12 - int(h01(row, 3, 1) * 8.0)
		while xx < 320:
			var wdt: int = 20 + int(h01(xx, row, 2) * 10.0)
			var tone: float = 0.35 + h01(xx, row, 5) * 0.4
			for y in range(yy + 1, mini(yy + 15, 282)):
				for x in range(maxi(xx + 1, 180), mini(xx + wdt, 320)):
					var t: float = tone
					if y == yy + 1 or x == maxi(xx + 1, 180):
						t += 0.2
					if y == yy + 14 or x == xx + wdt - 1:
						t -= 0.15
					px(im, x, y, pick(flag, t, x, y))
			xx += wdt
		yy += 15
		row += 1
	# спальня: тёплые доски
	planks(im, 320, 130, 140, 152, WOOD, false, 12, 0.5, 3)
	# боковые стены: тёмные балки
	for strip in [Rect2i(170, 70, 10, 222), Rect2i(460, 70, 10, 222)]:
		var s: Rect2i = strip
		rect(im, s.position.x, s.position.y, s.size.x, s.size.y, WOOD[3])
		rect(im, s.position.x, s.position.y, 2, s.size.y, WOOD[6])
		rect(im, s.end.x - 2, s.position.y, 2, s.size.y, WOOD[1])
	# передняя стена: каменный цоколь
	rect(im, 170, 282, 300, 10, STONE[3])
	for bx in range(170, 470, 20):
		var off: int = 0 if ((bx - 170) / 20) % 2 == 0 else 8
		rect(im, bx + off, 282, 1, 10, STONE[1])
	rect(im, 170, 286, 300, 1, STONE[1])
	rect(im, 170, 282, 300, 2, STONE[5])
	rect(im, 170, 290, 300, 2, STONE[1])
	# задняя стена: потолочная балка, штукатурка, балки, цоколь
	rect(im, 170, 70, 300, 8, WOOD[4])
	rect(im, 170, 70, 300, 2, WOOD[7])
	rect(im, 170, 76, 300, 2, WOOD[1])
	for y2 in range(78, 116):
		for x2 in range(180, 460):
			var tv: float = 0.5 + (h01(x2 / 3, y2 / 3, 5) - 0.5) * 0.25
			px(im, x2, y2, pick(PLASTER, tv, x2, y2))
	beam_h(im, 180, 112, 280, 4)
	rect(im, 180, 116, 280, 14, STONE[3])
	for bx2 in range(180, 460, 18):
		var off2: int = 0 if ((bx2 - 180) / 18) % 2 == 0 else 9
		rect(im, bx2 + off2, 116, 1, 14, STONE[1])
	rect(im, 180, 122, 280, 1, STONE[1])
	rect(im, 180, 116, 280, 2, STONE[5])
	rect(im, 180, 128, 280, 2, STONE[1])
	beam_v(im, 170, 70, 10, 60)
	beam_v(im, 460, 70, 10, 60)
	beam_v(im, 316, 78, 8, 52)
	# перегородка: деревянная стенка со столбиком
	rect(im, 316, 130, 8, 68, WOOD[3])
	rect(im, 316, 130, 2, 68, WOOD[6])
	rect(im, 322, 130, 2, 68, WOOD[1])
	rect(im, 314, 196, 12, 8, WOOD[2])
	rect(im, 314, 196, 12, 2, WOOD[6])
	# ступенчатые тени у стен (без плавных переходов)
	for x3 in range(180, 460):
		dim_px(im, x3, 130, 0.26)
		dim_px(im, x3, 131, 0.26)
		dim_px(im, x3, 132, 0.14)
		dim_px(im, x3, 133, 0.14)
	for y4 in range(134, 282):
		for k in range(4):
			var a: float = 0.22 if k < 2 else 0.12
			dim_px(im, 180 + k, y4, a)
			dim_px(im, 459 - k, y4, a)
			if y4 < 196:
				dim_px(im, 314 - k, y4, a)
				dim_px(im, 326 + k, y4, a)
	# окна во двор и тёплый свет на полу
	gen_in_window(im, 258, false)
	gen_in_window(im, 392, true)
	for wx in [258, 392]:
		for y5 in range(134, 196):
			var sh: int = int(float(y5 - 134) * 0.5)
			for x5 in range(int(wx) - 14 + sh, int(wx) + 14 + sh):
				if x5 > 182 and x5 < 458 and not (x5 >= 314 and x5 < 326 and y5 < 198):
					var cc: Color = im.get_pixel(x5, y5)
					im.set_pixel(x5, y5, cc.lightened(0.12))
	# пучки трав сушатся у перегородки
	rect(im, 280, 84, 30, 2, WOOD[2])
	var herbs: Array = [LAV, MINT, SAGE]
	for i in range(3):
		var hx0: int = 286 + i * 10
		var hr: Array = herbs[i]
		rect(im, hx0, 86, 1, 6, WOOD[4])
		for k2 in range(9):
			var lw: int = 1 + (k2 / 3)
			rect(im, hx0 - lw, 91 + k2, lw * 2 + 1, 1, hr[clampi(3 + (k2 % 3) - 1, 0, hr.size() - 1)])
	# банки на полке над плитой
	rect(im, 186, 96, 52, 3, WOOD[5])
	rect(im, 186, 96, 52, 1, WOOD[7])
	var jar_cols: Array = [Color("5fa46a"), Color("c8a05a"), Color("8d7ccc"), Color("d86a5a")]
	for i2 in range(4):
		var jx: int = 190 + i2 * 12
		var jc: Color = jar_cols[i2]
		rect(im, jx, 85, 8, 11, jc.darkened(0.25))
		rect(im, jx + 1, 86, 5, 9, jc)
		rect(im, jx + 1, 86, 2, 8, jc.lightened(0.35))
		rect(im, jx + 1, 83, 6, 2, WOOD[6])
	# картина над кроватью
	rect(im, 428, 84, 26, 22, WOOD[3])
	rect(im, 428, 84, 26, 2, WOOD[6])
	rect(im, 430, 86, 22, 18, Color("8ec4e0"))
	rect(im, 430, 94, 22, 10, Color("4f8a5a"))
	rect(im, 434, 90, 3, 8, Color("2a5a3a"))
	rect(im, 441, 89, 3, 9, Color("2a5a3a"))
	disc(im, 447, 90, 2.0, Color("f6e08a"))
	# ковры
	ell(im, 396, 238, 40, 21, RED[2])
	ell(im, 396, 238, 36, 18, CREAM[2])
	ell(im, 396, 238, 30, 14, RED[3])
	ell(im, 396, 238, 16, 6, CREAM[3])
	for k3 in range(8):
		var ang: float = float(k3) / 8.0 * TAU
		px(im, int(396.0 + cos(ang) * 23.0), int(238.0 + sin(ang) * 10.0), CREAM[4])
	ell(im, 236, 250, 36, 15, Color("4a6a46"))
	ell(im, 236, 250, 32, 12, Color("6a8a5a"))
	ell(im, 236, 250, 24, 8, Color("8aaa72"))
	# дверь: проём с улицей, косяки и коврик
	rect(im, 302, 282, 36, 10, Color("a8cf88"))
	rect(im, 302, 282, 36, 2, Color("7cae6a"))
	rect(im, 306, 286, 3, 1, Color("f6c8d0"))
	rect(im, 326, 288, 3, 1, Color("f6e08a"))
	beam_v(im, 298, 276, 4, 16)
	beam_v(im, 338, 276, 4, 16)
	rect(im, 306, 264, 28, 10, Color("5a2a2e"))
	rect(im, 308, 266, 24, 6, Color("8a3a40"))
	rect(im, 308, 266, 24, 1, Color("b05a60"))
	save3(im, "interior_floor", false)


## Окно во двор: за стеклом трава, цветы, деревья. Красные занавески, как снаружи.
func gen_in_window(im: Image, cx: int, box: bool) -> void:
	var x0: int = cx - 15
	rect(im, cx - 18, 80, 36, 33, WOOD[2])
	rect(im, cx - 18, 80, 36, 2, WOOD[5])
	# листва и небо
	for x in range(x0, x0 + 30):
		for y in range(84, 91):
			var v: float = h01(x, y, 17)
			px(im, x, y, LEAF_DEEP[2] if v < 0.4 else (LEAF_GREEN[2] if v < 0.8 else LEAF_GREEN[3]))
	rect(im, x0 + 20, 84, 8, 4, Color("a8d8f0"))
	# дальняя трава, кусты и ближняя трава
	rect(im, x0, 91, 30, 5, GRASS[3])
	for k in range(4):
		ell(im, float(x0 + 4 + k * 8), 92.0, 5.0, 3.0, LEAF_GREEN[1] if k % 2 == 0 else LEAF_GREEN[2])
	for y2 in range(96, 110):
		var gi: int = 3 + (y2 - 96) / 5
		rect(im, x0, y2, 30, 1, GRASS[mini(gi, 6)])
	# тропинка
	for y3 in range(96, 110):
		var pw: int = 3 + (y3 - 96) / 2
		rect(im, cx - pw / 2 + 4, y3, pw, 1, SAND[3])
	# цветы
	for i in range(11):
		var fx: int = x0 + 1 + int(h01(i, cx, 3) * 27.0)
		var fy: int = 97 + int(h01(i, cx, 4) * 11.0)
		var fcols: Array = [Color("f4a0b8"), Color("f8f4e8"), Color("f6d86a"), Color("c8a8ec")]
		px(im, fx, fy, fcols[i % 4])
	# рама-крестовина и блик
	rect(im, cx - 1, 84, 2, 26, WOOD[5])
	rect(im, x0, 96, 30, 2, WOOD[5])
	px(im, x0 + 2, 85, Color(1, 1, 1))
	px(im, x0 + 3, 86, Color(1, 1, 1))
	px(im, x0 + 2, 86, Color(1, 1, 1, 0.6))
	# занавески
	rect(im, cx - 17, 82, 5, 24, RED[3])
	rect(im, cx + 12, 82, 5, 24, RED[3])
	rect(im, cx - 17, 82, 1, 24, RED[5])
	rect(im, cx + 16, 82, 1, 24, RED[1])
	rect(im, cx - 17, 100, 5, 2, RED[1])
	rect(im, cx + 12, 100, 5, 2, RED[1])
	# подоконник
	rect(im, cx - 20, 110, 40, 3, WOOD[6])
	rect(im, cx - 20, 110, 40, 1, WOOD[8])
	if box:
		rect(im, cx - 18, 106, 36, 4, WOOD[3])
		for i2 in range(9):
			var bx: int = cx - 17 + i2 * 4
			rect(im, bx, 103, 3, 3, Color("f4a0b8") if i2 % 2 == 0 else Color("f8f4e8"))
			px(im, bx + 1, 102, Color("f6d86a"))
			px(im, bx, 106, MINT[3])


func gen_in_stove() -> void:
	var im: Image = new_img(36, 52)
	rect(im, 15, 0, 6, 20, IRON[2])
	rect(im, 15, 0, 2, 20, IRON[4])
	rect(im, 19, 0, 2, 20, IRON[0])
	rect(im, 13, 16, 10, 4, IRON[3])
	rect(im, 2, 18, 32, 10, IRON[4])
	rect(im, 2, 18, 32, 2, IRON[5])
	ell(im, 11, 23, 5, 2, IRON[1])
	ell(im, 26, 23, 5, 2, IRON[1])
	rect(im, 2, 28, 32, 20, IRON[2])
	rect(im, 2, 28, 32, 2, IRON[3])
	rect(im, 2, 28, 2, 20, IRON[3])
	rect(im, 32, 28, 2, 20, IRON[0])
	rect(im, 9, 31, 18, 13, IRON[0])
	rect(im, 11, 33, 14, 9, ORANGE[2])
	rect(im, 11, 38, 14, 4, ORANGE[4])
	rect(im, 14, 34, 8, 6, ORANGE[6])
	rect(im, 16, 36, 4, 3, ORANGE[7])
	for bx in [14, 18, 22]:
		rect(im, int(bx), 33, 1, 9, IRON[1])
	rect(im, 5, 48, 4, 4, IRON[1])
	rect(im, 27, 48, 4, 4, IRON[1])
	outline_auto(im, 0.6)
	save3(im, "in_stove", false)


func gen_in_counter() -> void:
	var im: Image = new_img(54, 38)
	rect(im, 0, 4, 54, 12, STONE[4])
	rect(im, 0, 4, 54, 2, STONE[6])
	rect(im, 0, 14, 54, 2, STONE[2])
	planks(im, 0, 16, 54, 22, WOOD, true, 6, 0.42, 21)
	rect(im, 0, 16, 54, 1, WOOD[1])
	for dx in [3, 28]:
		var d0: int = int(dx)
		rect(im, d0, 19, 23, 15, WOOD[1])
		rect(im, d0 + 1, 20, 21, 13, WOOD[4])
		rect(im, d0 + 3, 22, 17, 9, WOOD[3])
		rect(im, d0 + 3, 22, 17, 1, WOOD[5])
	rect(im, 24, 25, 2, 3, GOLD[3])
	rect(im, 28, 25, 2, 3, GOLD[3])
	ell(im, 14, 9, 9, 3, PORCELAIN[2])
	ell(im, 14, 9, 7, 2, Color("6aaed0"))
	rect(im, 14, 2, 2, 5, IRON[5])
	rect(im, 14, 1, 5, 2, IRON[5])
	rect(im, 36, 5, 11, 8, IRON[2])
	rect(im, 36, 5, 11, 2, IRON[4])
	outline_auto(im, 0.6)
	save3(im, "in_counter", false)


func gen_in_table() -> void:
	var im: Image = new_img(42, 36)
	planks(im, 1, 1, 40, 18, WOOD, false, 6, 0.66, 31)
	rect(im, 1, 1, 40, 1, WOOD[8])
	rect(im, 1, 17, 40, 3, WOOD[3])
	rect(im, 3, 20, 36, 3, WOOD[2])
	rect(im, 4, 20, 4, 16, WOOD[3])
	rect(im, 4, 20, 1, 16, WOOD[5])
	rect(im, 34, 20, 4, 16, WOOD[3])
	rect(im, 34, 20, 1, 16, WOOD[5])
	rect(im, 8, 4, 26, 10, CREAM[3])
	rect(im, 8, 4, 26, 1, CREAM[4])
	rect(im, 8, 13, 26, 2, RED[3])
	ell(im, 16, 9, 5, 2, PORCELAIN[4])
	ell(im, 16, 9, 3, 1, Color("c8893c"))
	disc(im, 27, 8, 2.6, PORCELAIN[4])
	disc(im, 27, 8, 1.6, Color("6a3a22"))
	rect(im, 20, 5, 2, 5, CREAM[4])
	rect(im, 20, 3, 2, 2, ORANGE[6])
	outline_auto(im, 0.6)
	save3(im, "in_table", false)


func gen_in_stool() -> void:
	var im: Image = new_img(18, 24)
	ell(im, 9, 7, 7, 4, WOOD[6])
	ell(im, 9, 6, 6, 3, WOOD[7])
	rect(im, 2, 8, 14, 2, WOOD[3])
	rect(im, 3, 10, 2, 13, WOOD[2])
	rect(im, 13, 10, 2, 13, WOOD[2])
	rect(im, 3, 10, 1, 13, WOOD[4])
	rect(im, 13, 10, 1, 13, WOOD[4])
	rect(im, 4, 17, 10, 1, WOOD[3])
	outline_auto(im, 0.6)
	save3(im, "in_stool", false)


func gen_in_basket() -> void:
	var im: Image = new_img(22, 20)
	ell(im, 11, 13, 10, 5, THATCH[2])
	rect(im, 1, 9, 20, 7, THATCH[3])
	for y in range(9, 18):
		for x in range(1, 21):
			if (x + y * 2) % 6 == 0:
				px(im, x, y, THATCH[1])
			elif (x + y * 2) % 6 == 3:
				px(im, x, y, THATCH[5])
	ell(im, 11, 8, 10, 3, THATCH[4])
	disc(im, 7, 6, 2.6, RED[3])
	disc(im, 12, 5, 2.6, RED[4])
	disc(im, 16, 7, 2.6, Color("c8a030"))
	px(im, 7, 3, Color("5fa46a"))
	outline_auto(im, 0.6)
	save3(im, "in_basket", false)


func gen_in_barrel() -> void:
	var im: Image = new_img(24, 30)
	rect(im, 3, 5, 18, 22, WOOD[3])
	ell(im, 12, 27, 9, 3, WOOD[3])
	rect(im, 3, 5, 3, 22, WOOD[5])
	rect(im, 18, 5, 3, 22, WOOD[1])
	for sx in [8, 12, 16]:
		rect(im, int(sx), 5, 1, 22, WOOD[2])
	for hy in [9, 21]:
		rect(im, 3, int(hy), 18, 2, IRON[2])
		rect(im, 3, int(hy), 18, 1, IRON[4])
	ell(im, 12, 5, 9, 3, WOOD[6])
	ell(im, 12, 5, 7, 2, WOOD[7])
	outline_auto(im, 0.6)
	save3(im, "in_barrel", false)


func gen_in_plant() -> void:
	var im: Image = new_img(20, 30)
	ell(im, 10, 10, 7, 9, MINT[3])
	ell(im, 5, 12, 3, 6, MINT[4])
	ell(im, 15, 12, 3, 6, MINT[5])
	ell(im, 10, 7, 3, 5, MINT[6])
	rect(im, 5, 19, 10, 10, ORANGE[3])
	rect(im, 3, 18, 14, 3, ORANGE[4])
	rect(im, 3, 18, 14, 1, ORANGE[6])
	rect(im, 5, 21, 2, 8, ORANGE[5])
	rect(im, 13, 21, 2, 8, ORANGE[1])
	outline_auto(im, 0.6)
	save3(im, "in_plant", false)


func gen_in_bed() -> void:
	var im: Image = new_img(54, 70)
	rect(im, 0, 0, 54, 70, WOOD[2])
	rect(im, 5, 11, 44, 52, CREAM[3])
	for pxx in [7, 28]:
		var p0: int = int(pxx)
		rect(im, p0, 12, 19, 13, CREAM[4])
		rect(im, p0, 22, 19, 3, CREAM[2])
		rect(im, p0 + 1, 14, 1, 7, CREAM[2])
	for y in range(26, 62):
		for x in range(5, 49):
			var chk: int = ((x - 5) / 6 + (y - 26) / 6) % 2
			px(im, x, y, RED[3] if chk == 0 else RED[2])
	rect(im, 5, 26, 44, 5, CREAM[2])
	rect(im, 5, 26, 44, 1, CREAM[4])
	rect(im, 5, 30, 44, 1, CREAM[0])
	rect(im, 5, 58, 44, 4, RED[1])
	rect(im, 5, 31, 2, 27, RED[4])
	rect(im, 0, 0, 54, 11, WOOD[3])
	rect(im, 0, 0, 54, 2, WOOD[6])
	rect(im, 0, 0, 5, 19, WOOD[4])
	rect(im, 49, 0, 5, 19, WOOD[4])
	rect(im, 0, 0, 5, 3, WOOD[7])
	rect(im, 49, 0, 5, 3, WOOD[7])
	planks(im, 6, 3, 42, 7, WOOD, true, 6, 0.5, 41)
	rect(im, 0, 62, 54, 8, WOOD[3])
	rect(im, 0, 62, 54, 2, WOOD[6])
	rect(im, 0, 56, 5, 14, WOOD[4])
	rect(im, 49, 56, 5, 14, WOOD[4])
	rect(im, 0, 56, 5, 3, WOOD[7])
	rect(im, 49, 56, 5, 3, WOOD[7])
	outline_auto(im, 0.6)
	save3(im, "in_bed", false)


func gen_in_wardrobe(open: bool) -> void:
	var im: Image = new_img(50, 64)
	rect(im, 5, 4, 40, 56, WOOD[2])
	rect(im, 4, 0, 42, 6, WOOD[5])
	rect(im, 4, 0, 42, 2, WOOD[8])
	rect(im, 4, 4, 42, 2, WOOD[2])
	rect(im, 4, 58, 42, 6, WOOD[2])
	rect(im, 4, 58, 42, 1, WOOD[5])
	if not open:
		for dx in [7, 26]:
			var d0: int = int(dx)
			rect(im, d0, 8, 17, 48, WOOD[4])
			rect(im, d0, 8, 17, 1, WOOD[6])
			rect(im, d0, 8, 1, 48, WOOD[6])
			rect(im, d0 + 16, 8, 1, 48, WOOD[2])
			rect(im, d0 + 3, 11, 11, 18, WOOD[3])
			rect(im, d0 + 3, 11, 11, 1, WOOD[2])
			rect(im, d0 + 3, 33, 11, 18, WOOD[3])
			rect(im, d0 + 3, 33, 11, 1, WOOD[2])
		rect(im, 22, 32, 2, 4, GOLD[4])
		rect(im, 26, 32, 2, 4, GOLD[4])
	else:
		rect(im, 7, 8, 36, 48, Color("1c120d"))
		rect(im, 7, 8, 36, 2, Color("2e1c14"))
		rect(im, 8, 12, 34, 2, IRON[4])
		rect(im, 12, 14, 10, 22, CLOAK[3])
		rect(im, 12, 14, 10, 2, CLOAK[5])
		rect(im, 27, 14, 9, 16, TUNIC[2])
		rect(im, 27, 14, 9, 2, TUNIC[4])
		rect(im, 7, 40, 36, 2, WOOD[4])
		rect(im, 7, 40, 36, 1, WOOD[6])
		rect(im, 10, 45, 10, 11, LEATHER[3])
		rect(im, 10, 45, 10, 2, LEATHER[5])
		rect(im, 0, 8, 6, 48, WOOD[4])
		rect(im, 0, 8, 1, 48, WOOD[6])
		rect(im, 44, 8, 6, 48, WOOD[4])
		rect(im, 49, 8, 1, 48, WOOD[2])
	outline_auto(im, 0.6)
	save3(im, "in_wardrobe_open" if open else "in_wardrobe", false)


func gen_in_nightstand() -> void:
	var im: Image = new_img(20, 34)
	rect(im, 1, 11, 18, 6, WOOD[6])
	rect(im, 1, 11, 18, 1, WOOD[8])
	planks(im, 1, 17, 18, 17, WOOD, true, 6, 0.4, 51)
	rect(im, 1, 17, 18, 1, WOOD[1])
	rect(im, 4, 20, 12, 8, WOOD[4])
	rect(im, 4, 20, 12, 1, WOOD[2])
	rect(im, 9, 23, 2, 2, GOLD[4])
	rect(im, 8, 4, 3, 7, CREAM[3])
	rect(im, 8, 4, 1, 7, CREAM[4])
	rect(im, 9, 1, 2, 3, ORANGE[6])
	px(im, 9, 0, ORANGE[7])
	outline_auto(im, 0.6)
	save3(im, "in_nightstand", false)


func gen_rod_icon() -> void:
	var im: Image = new_img(16, 16)
	line(im, 2, 14, 13, 2, WOOD[5])
	line(im, 3, 14, 14, 2, WOOD[3])
	disc(im, 4.5, 11.5, 1.8, IRON[4])
	px(im, 4, 11, IRON[5])
	line(im, 14, 2, 14, 10, Color(1, 1, 1, 0.9))
	rect(im, 13, 10, 3, 2, Color("e8e0d0"))
	rect(im, 13, 11, 3, 2, Color("d8503a"))
	px(im, 14, 13, IRON[5])
	px(im, 15, 14, IRON[5])
	outline_auto(im, 0.6)
	save3(im, "rod_icon", false)


## Деревенский сортир: каменный цоколь, дощатая будка, дверь с полумесяцем, соломенная крыша
func gen_outhouse() -> void:
	var im: Image = new_img(52, 80)
	# стены
	planks(im, 8, 32, 36, 38, WOOD, true, 6, 0.5, 61)
	rect(im, 8, 32, 2, 38, WOOD[6])
	rect(im, 42, 32, 2, 38, WOOD[1])
	# цоколь
	rect(im, 5, 70, 42, 8, STONE[3])
	for bx in range(5, 47, 10):
		var off: int = 0 if ((bx - 5) / 10) % 2 == 0 else 5
		rect(im, bx + off, 70, 1, 8, STONE[1])
	rect(im, 5, 74, 42, 1, STONE[1])
	rect(im, 5, 70, 42, 2, STONE[5])
	rect(im, 5, 76, 42, 2, STONE[1])
	# дверь с железными петлями, полумесяцем и тёплым светом внутри
	rect(im, 15, 38, 22, 32, WOOD[1])
	planks(im, 16, 39, 20, 31, WOOD, true, 5, 0.42, 63)
	rect(im, 16, 39, 20, 1, WOOD[2])
	disc(im, 26.0, 48.0, 4.2, Color("1c120d"))
	disc(im, 27.8, 47.0, 3.4, WOOD[4])
	px(im, 24, 48, ORANGE[5])
	px(im, 24, 49, ORANGE[6])
	px(im, 25, 50, ORANGE[5])
	rect(im, 16, 44, 7, 1, IRON[2])
	rect(im, 16, 60, 7, 1, IRON[2])
	rect(im, 33, 54, 2, 5, IRON[4])
	# щель-вентиляция под крышей
	rect(im, 21, 34, 10, 2, Color("1c120d"))
	# крыша: пучки соломы, как у дома
	for y in range(5, 34):
		var half: float = 8.0 + float(y - 5) * 0.62
		for x in range(int(26.0 - half), int(26.0 + half) + 1):
			var band: int = ((y - 5) / 4) % 2
			var tv: float = 0.55 + (0.12 if band == 0 else -0.05) + (h01(x / 2, y / 3, 9) - 0.5) * 0.18
			if (x + y / 4 * 3) % 4 == 0:
				tv -= 0.14
			px(im, x, y, pick(THATCH, tv, x, y))
	for x2 in range(2, 51):
		var ey: int = 33 + int(h01(x2, 4, 6) * 3.0)
		rect(im, x2, 31, 1, ey - 31, THATCH[2] if x2 % 3 != 0 else THATCH[1])
	rect(im, 20, 3, 12, 3, THATCH[7])
	for mp in [Vector2i(14, 22), Vector2i(34, 26), Vector2i(24, 14)]:
		var mv: Vector2i = mp
		rect(im, mv.x, mv.y, 4, 2, MOSS[2])
		px(im, mv.x + 1, mv.y - 1, MOSS[3])
	outline_auto(im, 0.6)
	save3(im, "outhouse", false)


func gen_need_icons() -> void:
	var a: Image = new_img(12, 12)
	disc(a, 6.0, 7.4, 3.8, Color("e8c84a"))
	for y in range(1, 5):
		var half: float = float(y - 1) * 0.95
		rect(a, int(6.0 - half), y, int(half * 2.0) + 1, 1, Color("e8c84a"))
	rect(a, 4, 6, 1, 3, Color("fff3b0"))
	rect(a, 8, 8, 1, 2, Color("b88a1e"))
	outline_auto(a, 0.6)
	save3(a, "need_pee", false)
	var b: Image = new_img(12, 12)
	ell(b, 6.0, 9.0, 5.0, 2.5, LEATHER[3])
	ell(b, 6.0, 6.2, 4.0, 2.2, LEATHER[4])
	ell(b, 6.0, 3.6, 2.4, 1.8, LEATHER[4])
	rect(b, 3, 8, 2, 1, LEATHER[5])
	rect(b, 4, 5, 2, 1, LEATHER[5])
	px(b, 5, 3, LEATHER[5])
	outline_auto(b, 0.6)
	save3(b, "need_poo", false)
	# стыд: румяное смущённое личико
	var c: Image = new_img(12, 12)
	disc(c, 6.0, 6.0, 5.0, SKIN[3])
	rect(c, 2, 6, 3, 2, Color("e8506a"))
	rect(c, 7, 6, 3, 2, Color("e8506a"))
	rect(c, 3, 4, 2, 1, Color("5a2a22"))
	rect(c, 7, 4, 2, 1, Color("5a2a22"))
	rect(c, 5, 9, 2, 1, Color("8a3a3a"))
	px(c, 1, 2, Color("e8506a"))
	px(c, 10, 2, Color("e8506a"))
	outline_auto(c, 0.6)
	save3(c, "need_shame", false)
	# лужа и кучка на земле (вид сверху)
	var pl: Image = new_img(24, 12)
	ell(pl, 12.0, 6.0, 10.0, 4.5, Color("b89a34"))
	ell(pl, 11.0, 5.5, 8.0, 3.2, Color("d0b448"))
	ell(pl, 9.0, 4.5, 3.0, 1.4, Color("f0dc78"))
	px(pl, 20, 8, Color("b89a34"))
	px(pl, 3, 3, Color("b89a34"))
	save3(pl, "puddle_pee", false)
	# кучка: четыре размера — свежая и всё более подсохшая (меньше), рисуются заново, без размытия
	save3(poo_img(1.0), "puddle_poo", false)
	save3(poo_img(0.75), "poo_75", false)
	save3(poo_img(0.55), "poo_55", false)
	save3(poo_img(0.38), "poo_38", false)


## Жажда (кружка с водой) и голод (булочка) — значки 12x12 для шкал
func gen_need_icons2() -> void:
	var a: Image = new_img(12, 12)
	rect(a, 2, 3, 7, 8, Color("c8d4e0"))
	rect(a, 3, 4, 5, 6, Color("5aa8e8"))
	rect(a, 3, 4, 5, 1, Color("a8dcff"))
	rect(a, 9, 5, 2, 1, Color("c8d4e0"))
	rect(a, 10, 5, 1, 4, Color("c8d4e0"))
	rect(a, 9, 8, 2, 1, Color("c8d4e0"))
	px(a, 4, 6, Color("ffffff"))
	outline_auto(a, 0.6)
	save3(a, "need_thirst", false)
	var b: Image = new_img(12, 12)
	ell(b, 6.0, 7.0, 5.0, 3.6, Color("c07a30"))
	ell(b, 5.6, 6.2, 4.0, 2.6, Color("e09a48"))
	ell(b, 5.0, 5.4, 2.0, 1.0, Color("f6c878"))
	rect(b, 3, 7, 1, 1, Color("8a5420"))
	rect(b, 6, 6, 1, 1, Color("8a5420"))
	rect(b, 8, 7, 1, 1, Color("8a5420"))
	outline_auto(b, 0.6)
	save3(b, "need_hunger", false)


## Кучка на холсте 20x18 (низ по центру — в точке 10,16): витки сверху вниз, свет слева сверху,
## глянцевые блики, трещинки и крапинки. k — размер (1 — свежая, меньше — подсохшая).
func poo_img(k: float) -> Image:
	var pp: Image = new_img(20, 18)
	var br: Array = [Color("2a1810"), Color("3e2416"), Color("56331f"), Color("6e4228"), Color("85552f"), Color("9c683a"), Color("b47d48")]
	ell(pp, 10.0, 16.0, 8.6 * k, 1.8 * maxf(k, 0.6), Color(0.05, 0.03, 0.02, 0.45))
	var tiers: Array = [[10.0, 13.0, 7.8, 3.8], [10.4, 9.6, 6.0, 3.2], [9.7, 6.6, 4.2, 2.7], [10.0, 4.0, 2.4, 2.0]]
	var ntiers: int = 4 if k > 0.7 else (3 if k > 0.45 else 2)
	for ti in range(ntiers):
		var tr: Array = tiers[ti]
		var cx: float = 10.0 + (float(tr[0]) - 10.0) * k
		var cy: float = 16.0 - (16.0 - float(tr[1])) * k
		var rx: float = maxf(1.2, float(tr[2]) * k)
		var ry: float = maxf(1.0, float(tr[3]) * k)
		for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
			for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
				var u: float = (float(x) + 0.5 - cx) / rx
				var v: float = (float(y) + 0.5 - cy) / ry
				if u * u + v * v > 1.0:
					continue
				var sh: float = 0.62 - 0.30 * u - 0.42 * v
				if v > 0.55:
					sh -= 0.18
				if h01(x, y, 91) < 0.07:
					sh -= 0.10
				elif h01(x, y, 92) < 0.05:
					sh += 0.10
				px(pp, x, y, pick(br, sh, x, y))
		var gx: int = int(cx - rx * 0.42)
		var gy: int = int(cy - ry * 0.52)
		px(pp, gx, gy, br[6])
		if k > 0.5:
			px(pp, gx + 1, gy, Color("e8cba0"))
			px(pp, gx + 2, gy, br[6])
			px(pp, gx + 1, gy + 1, br[5])
		for x2 in range(int(cx - rx * 0.8), int(cx + rx * 0.8) + 1):
			px(pp, x2, int(cy + ry) - 1, br[1])
	if k > 0.9:
		px(pp, 10, 0, br[4])
		px(pp, 10, 1, br[5])
		px(pp, 11, 1, br[3])
		px(pp, 9, 2, br[5])
		px(pp, 11, 2, br[2])
		for cr in [Vector2i(6, 12), Vector2i(13, 11), Vector2i(8, 8)]:
			var crv: Vector2i = cr
			px(pp, crv.x, crv.y, br[1])
			px(pp, crv.x + 1, crv.y + 1, br[1])
	else:
		# подсохшая: трещинки по корке
		for cr2 in [Vector2i(8, 14), Vector2i(11, 13)]:
			var c2: Vector2i = cr2
			px(pp, c2.x, c2.y, br[1])
	outline_auto(pp, 0.6)
	return pp


## Швабра в деревянном ведре (в углу кухни), пустое ведро (когда швабру взяли) и швабра в руках
func _mop_bucket(im: Image) -> void:
	var y0: int = 30
	for y in range(y0, y0 + 13):
		var t: float = float(y - y0) / 12.0
		var hw: float = 7.0 - t * 1.4
		for x in range(int(10.0 - hw), int(10.0 + hw) + 1):
			var u: float = (float(x) + 0.5 - (10.0 - hw)) / (2.0 * hw)
			var ti: int = 6 if u < 0.25 else (5 if u < 0.6 else (4 if u < 0.85 else 3))
			if posmod(x, 3) == 0:
				ti -= 1
			px(im, x, y, WOOD[clampi(ti, 0, 8)])
	for hy in [y0 + 2, y0 + 9]:
		for x2 in range(3, 18):
			if a_at(im, x2, int(hy)) > 0.5:
				px(im, x2, int(hy), IRON[2])
				px(im, x2, int(hy) - 1, IRON[4])
	ell(im, 10.0, float(y0), 7.0, 2.0, WOOD[2])
	ell(im, 10.0, float(y0), 5.6, 1.3, Color("4a6a8a"))
	px(im, 8, y0, Color("8ec4e0"))


func _mop_head(im: Image, cx: int, y0: int) -> void:
	for k in range(9):
		var x: int = cx - 4 + k
		var len: int = 7 + int(h01(k, 3, 5) * 3.0)
		for y in range(y0, y0 + len):
			var c: Color = CREAM[2] if (k % 2 == 0) else CREAM[1]
			if y > y0 + len - 2:
				c = Color("9a9488")
			px(im, x + int(round(sin(float(y) * 0.6 + float(k)) * 0.6)), y, c)
	rect(im, cx - 4, y0 - 1, 9, 2, IRON[3])


## Сачок: тонкая палка, обруч и сетка мешочком (вид сбоку)
func _net_draw(im: Image, cx: int) -> void:
	line(im, cx, 43, cx, 17, WOOD[6])
	line(im, cx + 1, 43, cx + 1, 17, WOOD[3])
	# сетка-мешочек под обручем
	for y in range(8, 17):
		var hw: int = 5 - int(maxf(0.0, float(y - 12)) * 0.9)
		for x in range(cx - hw, cx + hw + 1):
			var c: Color = CREAM[2] if ((x + y) % 2 == 0) else Color("b9b4a6")
			px(im, x, y, c)
	# обруч
	for k in range(24):
		var an: float = float(k) / 24.0 * TAU
		px(im, cx + int(round(cos(an) * 6.0)), 8 + int(round(sin(an) * 3.0)), IRON[3])
	outline_auto(im, 0.6)


func gen_net() -> void:
	var a: Image = new_img(20, 44)
	_net_draw(a, 10)
	save3(a, "in_net", false)
	var h: Image = new_img(16, 44)
	_net_draw(h, 8)
	save3(h, "net_held", false)



func gen_mop() -> void:
	var a: Image = new_img(20, 44)
	# ручка наискосок из ведра к стене
	line(a, 13, 1, 9, 31, WOOD[6])
	line(a, 14, 1, 10, 31, WOOD[4])
	line(a, 15, 2, 11, 31, WOOD[2])
	_mop_bucket(a)
	_mop_head(a, 10, 26)
	_mop_bucket_front(a)
	outline_auto(a, 0.6)
	save3(a, "in_mop", false)
	var b: Image = new_img(20, 44)
	_mop_bucket(b)
	_mop_bucket_front(b)
	outline_auto(b, 0.6)
	save3(b, "in_bucket", false)
	var h: Image = new_img(12, 44)
	line(h, 5, 0, 5, 34, WOOD[6])
	line(h, 6, 0, 6, 34, WOOD[3])
	_mop_head(h, 6, 34)
	outline_auto(h, 0.6)
	save3(h, "mop_held", false)


## Передняя стенка ведра поверх тряпки
func _mop_bucket_front(im: Image) -> void:
	var y0: int = 32
	for y in range(y0, y0 + 11):
		var t: float = float(y - y0 + 2) / 12.0
		var hw: float = 7.0 - t * 1.4
		for x in range(int(10.0 - hw), int(10.0 + hw) + 1):
			var u: float = (float(x) + 0.5 - (10.0 - hw)) / (2.0 * hw)
			var ti: int = 6 if u < 0.25 else (5 if u < 0.6 else (4 if u < 0.85 else 3))
			if posmod(x, 3) == 0:
				ti -= 1
			px(im, x, y, WOOD[clampi(ti, 0, 8)])
	for x2 in range(3, 18):
		if a_at(im, x2, 39) > 0.5:
			px(im, x2, 39, IRON[2])
			px(im, x2, 38, IRON[4])


## ================================================================== насекомые
## Лист 64x(16*13): строки — виды, 4 кадра по 16x16. Все смотрят влево (в игре отражаются).
## У летающих: 0 — сидит (крылья сложены), 1-3 — взмах (вверх, середина, вниз).
const INSECT_ROWS: Array = ["bee", "butterfly_white", "butterfly_orange", "butterfly_blue", "butterfly_yellow", "ladybug", "aphid", "dung_beetle", "mosquito", "dragonfly", "firefly", "grasshopper", "moth"]


func gen_insects() -> void:
	var sheet: Image = new_img(64, 16 * INSECT_ROWS.size())
	for r in range(INSECT_ROWS.size()):
		for f in range(4):
			var cell: Image = new_img(16, 16)
			_draw_insect(cell, String(INSECT_ROWS[r]), f)
			if String(INSECT_ROWS[r]) != "mosquito":
				outline_auto(cell, 0.72)
			sheet.blit_rect(cell, Rect2i(0, 0, 16, 16), Vector2i(f * 16, r * 16))
	save3(sheet, "insects", false)
	var big: Image = sheet.duplicate()
	big.resize(sheet.get_width() * 8, sheet.get_height() * 8, Image.INTERPOLATE_NEAREST)
	big.save_png(ProjectSettings.globalize_path("res://").path_join("../screenshots/insects_sheet.png"))


func _wing(im: Image, cx: float, cy: float, rx: float, ry: float) -> void:
	ell(im, cx, cy, rx, ry, Color(0.80, 0.90, 1.0, 0.80))
	px(im, int(cx - rx * 0.3), int(cy - ry * 0.3), Color(1, 1, 1, 0.95))


## Бабочка сверху (как на референсах): переднее крыло больше, заднее меньше, тёмная кайма, пятна.
## E кайма, B основной цвет, S пятно, V прожилка, b тельце. Кадры: 0 сложены, 1 раскрыты, 2 наполовину, 3 почти сложены.
const BFLY_OPEN: Array = [
	"....E...E....",
	".....E.E.....",
	".EEE..b..EEE.",
	"EBBBE.b.EBBBE",
	"EBSBBEbEBBSBE",
	"EBBVBEbEBVBBE",
	".EBBBEbEBBBE.",
	"..EBBEbEBBE..",
	".EBSBEbEBSBE.",
	"..EEE.b.EEE..",
]


func _bfly(im: Image, f: int, base: Color, edge: Color, spot: Color, vein: Color) -> void:
	var drop: Array = []
	if f == 2:
		drop = [1, 2, 10, 11]
	elif f == 3:
		drop = [0, 1, 2, 3, 9, 10, 11, 12]
	elif f == 0:
		drop = [0, 1, 2, 3, 4, 8, 9, 10, 11, 12]
	var pal: Dictionary = {"E": edge, "B": base, "S": spot, "V": vein, "b": Color("2a2026")}
	for r in range(BFLY_OPEN.size()):
		var s: String = String(BFLY_OPEN[r])
		var o: String = ""
		for ci in range(s.length()):
			if not (ci in drop):
				o += s[ci]
		if f == 0 and r >= 2:
			# сложенные крылья видны узкой полоской с каймой
			o = "E" + ("B" if r % 3 != 0 else "S") + "b" + ("B" if r % 3 != 0 else "S") + "E"
		var ox: int = 8 - o.length() / 2
		for ci2 in range(o.length()):
			var ch: String = o[ci2]
			if pal.has(ch):
				px(im, ox + ci2, 3 + r, pal[ch])


func _draw_insect(im: Image, kind: String, f: int) -> void:
	var cx: float = 8.0
	var cy: float = 8.0
	match kind:
		"bee":
			if f == 1:
				_wing(im, 8.0, 4.6, 1.8, 2.4)
				_wing(im, 10.4, 4.8, 1.6, 2.2)
			elif f == 2:
				_wing(im, 9.0, 6.4, 3.0, 1.3)
			elif f == 3:
				_wing(im, 8.6, 9.6, 2.2, 1.4)
			ell(im, cx + 1.2, cy + 0.8, 3.4, 2.4, GOLD[4])
			rect(im, int(cx), int(cy) - 1, 1, 4, Color("2a2026"))
			rect(im, int(cx) + 2, int(cy) - 1, 1, 4, Color("2a2026"))
			px(im, int(cx) + 4, int(cy) + 1, Color("2a2026"))
			disc(im, cx - 2.6, cy + 0.6, 1.6, Color("3a2a26"))
			px(im, int(cx) - 3, int(cy), Color("fff6c0"))
			px(im, int(cx) - 4, int(cy) - 2, Color("2a2026"))
			px(im, int(cx) - 4, int(cy) - 3, Color("2a2026"))
			if f == 0:
				_wing(im, cx + 1.4, cy - 1.2, 2.4, 1.0)
		"butterfly_white":
			_bfly(im, f, Color("f4f0e8"), Color("8a8696"), Color("2a2026"), Color("d8d4cc"))
		"butterfly_orange":
			_bfly(im, f, Color("e8862c"), Color("2a1a14"), Color("fff2d8"), Color("a04a14"))
		"butterfly_blue":
			_bfly(im, f, Color("4a8ae0"), Color("1a2240"), Color("bfe6ff"), Color("2e5aa8"))
		"butterfly_yellow":
			_bfly(im, f, Color("f2d040"), Color("2a2016"), Color("e86a3a"), Color("2a2016"))
		"ladybug":
			# крылья растут из середины спины (по обе стороны от тела), надкрылья остаются на месте
			if f >= 1:
				var sp: float = [0.0, 2.0, 1.4, 0.8][f]
				_wing(im, cx + 0.8, cy + 1.0 - 1.2 - sp, 2.6, 2.4)
				_wing(im, cx + 0.8, cy + 1.0 + 1.2 + sp, 2.6, 2.4)
			ell(im, cx + 0.6, cy + 1.0, 3.4, 2.8, RED[3])
			ell(im, cx + 0.2, cy + 0.4, 2.0, 1.4, RED[5])
			rect(im, int(cx) - 2, int(cy) - 2, 6, 1, RED[2])
			rect(im, int(cx), int(cy) - 1, 1, 5, Color("1c1418"))
			for d in [Vector2i(-1, 0), Vector2i(2, 0), Vector2i(-1, 2), Vector2i(2, 2), Vector2i(1, 3)]:
				var dv: Vector2i = d
				px(im, int(cx) + dv.x, int(cy) + dv.y, Color("1c1418"))
			px(im, int(cx) + 1, int(cy) - 1, Color("ffd8d8"))
			disc(im, cx - 3.0, cy + 1.0, 1.4, Color("1c1418"))
			px(im, int(cx) - 3, int(cy), Color("f4f0e8"))
		"aphid":
			var o: int = f % 2
			for a in [Vector2i(5, 9), Vector2i(8, 8), Vector2i(10, 10), Vector2i(7, 11), Vector2i(11, 7)]:
				var av: Vector2i = a
				ell(im, float(av.x + o), float(av.y), 1.4, 1.0, MINT[5])
				px(im, av.x + o, av.y - 1, MINT[7])
				px(im, av.x + o - 1, av.y + 1, MINT[3])
		"dung_beetle":
			var lg: int = f % 2
			for k in range(3):
				var lx: int = int(cx) - 1 + k * 2
				px(im, lx + (1 if (k + lg) % 2 == 0 else 0), int(cy) - 2, Color("1c1418"))
				px(im, lx + (1 if (k + lg) % 2 == 0 else 0), int(cy) + 4, Color("1c1418"))
			ell(im, cx + 1.0, cy + 1.0, 3.6, 2.6, Color("1e2c26"))
			ell(im, cx + 0.4, cy + 0.2, 2.2, 1.4, Color("2e5a4a"))
			px(im, int(cx), int(cy) - 1, Color("6ac0a0"))
			px(im, int(cx) + 1, int(cy) - 1, Color("4a9a80"))
			rect(im, int(cx) + 1, int(cy) - 1, 1, 5, Color("101a16"))
			disc(im, cx - 3.0, cy + 1.0, 1.5, Color("1c2620"))
			px(im, int(cx) - 5, int(cy), Color("2e3a32"))
			px(im, int(cx) - 5, int(cy) - 1, Color("2e3a32"))
		"mosquito":
			for k2 in range(3):
				var lx2: int = int(cx) - 2 + k2 * 2
				line(im, lx2, int(cy) + 1, lx2 - 1 + k2, int(cy) + 5, Color("4a4038"))
			line(im, int(cx) - 3, int(cy), int(cx) + 4, int(cy) + 1, Color("6a5a4a"))
			px(im, int(cx) + 4, int(cy) + 1, Color("8a7058"))
			disc(im, cx - 3.4, cy - 0.2, 1.1, Color("3a2e28"))
			line(im, int(cx) - 6, int(cy) + 1, int(cx) - 4, int(cy), Color("3a2e28"))
			if f == 1:
				_wing(im, cx, cy - 3.0, 1.2, 2.2)
			elif f == 2:
				_wing(im, cx + 1.0, cy - 1.0, 3.0, 0.9)
			elif f == 3:
				_wing(im, cx + 0.6, cy + 2.2, 1.6, 1.0)
			else:
				_wing(im, cx + 1.6, cy - 0.4, 2.6, 0.7)
		"dragonfly":
			# вид сверху: длинное синее тело, четыре крыла поперёк
			var wl: float = [2.2, 5.4, 4.2, 2.8][f]
			for wx in [cx - 0.6, cx + 2.2]:
				_wing(im, float(wx), cy - 1.0 - wl * 0.5, 1.2, wl * 0.55)
				_wing(im, float(wx), cy + 1.0 + wl * 0.5, 1.2, wl * 0.55)
			rect(im, int(cx) - 3, int(cy) - 1, 11, 2, Color("3a7ac8"))
			rect(im, int(cx) - 3, int(cy) - 1, 11, 1, Color("6aaee8"))
			for sx in [0, 2, 4, 6]:
				px(im, int(cx) + int(sx), int(cy), Color("1e3a6a"))
			disc(im, cx - 4.4, cy, 1.8, Color("2a8a7a"))
			px(im, int(cx) - 5, int(cy) - 1, Color("8af0d0"))
			px(im, int(cx) - 5, int(cy) + 1, Color("8af0d0"))
		"firefly":
			if f == 1:
				_wing(im, cx + 0.4, cy - 2.6, 1.4, 1.8)
			elif f == 2:
				_wing(im, cx + 0.6, cy - 1.0, 2.6, 0.9)
			elif f == 3:
				_wing(im, cx + 0.4, cy + 1.8, 1.6, 1.0)
			ell(im, cx, cy, 2.4, 1.6, Color("3a2e2a"))
			disc(im, cx + 2.6, cy + 0.3, 1.5, Color("e8f878"))
			px(im, int(cx) + 3, int(cy), Color("ffffd8"))
			disc(im, cx - 2.6, cy, 1.1, Color("d86a3a"))
		"grasshopper":
			var crouch: int = 1 if f == 1 else 0
			var jump: bool = f >= 2
			var body_y: float = cy + 1.0 + float(crouch) - (2.0 if jump else 0.0)
			if f == 3:
				ell(im, cx + 2.0, body_y - 2.4, 3.4, 1.8, Color(0.94, 0.62, 0.70, 0.9))
			ell(im, cx + 0.6, body_y, 4.4, 1.7, LEAF_LIME[2])
			ell(im, cx + 0.2, body_y - 0.6, 3.2, 0.8, LEAF_LIME[3])
			disc(im, cx - 4.0, body_y - 0.4, 1.7, LEAF_LIME[2])
			px(im, int(cx) - 5, int(body_y) - 1, Color("2a2026"))
			line(im, int(cx) - 5, int(body_y) - 2, int(cx) - 8, int(body_y) - 6, LEAF_GREEN[1])
			if jump:
				line(im, int(cx) + 2, int(body_y), int(cx) + 7, int(body_y) + 3, LEAF_GREEN[1])
				line(im, int(cx) + 2, int(body_y) + 1, int(cx) + 7, int(body_y) + 4, LEAF_LIME[1])
			else:
				line(im, int(cx) + 1, int(body_y), int(cx) + 4, int(body_y) - 3, LEAF_LIME[1])
				line(im, int(cx) + 4, int(body_y) - 3, int(cx) + 6, int(body_y) + 3, LEAF_GREEN[1])
			px(im, int(cx) - 2, int(body_y) + 2, LEAF_GREEN[1])
			px(im, int(cx), int(body_y) + 2, LEAF_GREEN[1])
		"moth":
			_bfly(im, f, Color("b0a088"), Color("5a4a3a"), Color("e8dcc0"), Color("7a6a58"))

## ---- рыбы маленького пруда: иконки 32x32, вид сбоку, голова слева ----
## a — полудлина тела, b — полувысота, tl — длина хвоста, th — полувысота хвоста,
## df/da — высота спинного/анального плавника, body — 5 цветов от спины к брюху
const FISH_ART: Dictionary = {
	"crucian": {"a": 10, "b": 7.0, "tl": 7, "th": 5.0, "fork": 1.0, "df": 4, "da": 2,
		"body": ["5a4a1e", "8a7430", "c0a048", "e8d27a", "f6ecb4"], "fin": ["a8602c", "d88a44", "f0b868"], "eye": "e8b84a", "kind": "plain"},
	"roach": {"a": 10, "b": 6.0, "tl": 7, "th": 6.0, "fork": 3.0, "df": 3, "da": 3,
		"body": ["4a5c60", "7a9094", "b4c6c8", "dce8e8", "f4fafa"], "fin": ["a82c2c", "d85040", "f08a70"], "eye": "d85040", "kind": "plain"},
	"perch": {"a": 10, "b": 6.0, "tl": 6, "th": 5.0, "fork": 1.5, "df": 5, "da": 3,
		"body": ["2a4a26", "4a7a3a", "7aa04a", "b8c870", "e8e8b0"], "fin": ["b83a20", "d8582c", "f08a50"], "eye": "e8c84a", "kind": "perch"},
	"tench": {"a": 10, "b": 7.0, "tl": 5, "th": 6.0, "fork": 0.0, "df": 3, "da": 2,
		"body": ["2a3a1a", "4a5a28", "6a7a38", "8a8a48", "b0a468"], "fin": ["2e3e1e", "4a5a2c", "6a7a40"], "eye": "e07a30", "kind": "plain"},
	"minnow": {"a": 8, "b": 4.0, "tl": 6, "th": 4.0, "fork": 2.0, "df": 2, "da": 2,
		"body": ["3a4a3a", "7a8a6a", "b4c4b0", "dce6dc", "f4f8f4"], "fin": ["8a9a8a", "b4c4b4", "dce6dc"], "eye": "f0f0d0", "kind": "minnow"},
	"loach": {"a": 12, "b": 3.0, "tl": 3, "th": 3.0, "fork": 0.0, "df": 2, "da": 1,
		"body": ["3a2a1a", "6a4a2a", "9a7442", "c8a468", "e6d09a"], "fin": ["5a3a20", "8a6034", "b08a50"], "eye": "f0e0b0", "kind": "loach"},
	"golden": {"a": 10, "b": 7.0, "tl": 8, "th": 8.0, "fork": 3.0, "df": 5, "da": 3,
		"body": ["b86a10", "e09a1c", "f6c83a", "ffe68a", "fff6c8"], "fin": ["e07818", "ffb840", "fff0a0"], "eye": "7a2810", "kind": "golden"},
}


func gen_fish() -> void:
	for id in FISH_ART.keys():
		gen_fish_icon(String(id))
	# контактный лист для проверки глазами
	var sheet: Image = new_img(32 * FISH_ART.size(), 32)
	var i: int = 0
	for id2 in FISH_ART.keys():
		var one: Image = Image.load_from_file(ProjectSettings.globalize_path(OUT + "fish_%s.png" % String(id2)))
		sheet.blit_rect(one, Rect2i(0, 0, 32, 32), Vector2i(i * 32, 0))
		i += 1
	sheet.resize(sheet.get_width() * 6, sheet.get_height() * 6, Image.INTERPOLATE_NEAREST)
	sheet.save_png(ProjectSettings.globalize_path("res://").path_join("../screenshots/fish_sheet.png"))


func fish_h(u: float, b: float) -> float:
	if u <= 0.1:
		var q: float = absf((u - 0.1) / 1.1)
		return b * pow(maxf(0.0, 1.0 - pow(q, 2.6)), 1.0 / 2.6)
	var t: float = clampf((u - 0.1) / 0.9, 0.0, 1.0)
	return lerpf(b, b * 0.3, t * t * (3.0 - 2.0 * t))


func gen_fish_icon(id: String) -> void:
	var d: Dictionary = FISH_ART[id]
	var a: int = int(d["a"])
	var b: float = float(d["b"])
	var tl: int = int(d["tl"])
	var th: float = float(d["th"])
	var fork: float = float(d["fork"])
	var df: int = int(d["df"])
	var da: int = int(d["da"])
	var kind: String = String(d["kind"])
	var body: Array = hx(d["body"])
	var fin: Array = hx(d["fin"])
	var im: Image = new_img(32, 32)
	var x0: int = 2
	var cy: float = 17.0
	var ped: float = b * 0.3
	# хвост
	var tx0: int = x0 + 2 * a
	for x in range(tx0, tx0 + tl):
		var tt: float = (float(x) + 0.5 - float(tx0)) / float(tl)
		var half: float = lerpf(ped, th, tt)
		for y in range(0, 32):
			var dy: float = absf(float(y) + 0.5 - cy)
			if dy > half:
				continue
			if tt > 0.45 and dy < (tt - 0.45) * fork * 1.6:
				continue
			var ray: bool = (y + x) % 3 == 0
			px(im, x, y, fin[2] if ray else fin[1])
	# спинной плавник (у окуня два: колючий и мягкий)
	var dors: Array = [[-0.1, 0.45]] if kind != "perch" else [[-0.25, 0.1], [0.15, 0.5]]
	for dr in dors:
		var d0: float = float(dr[0])
		var d1: float = float(dr[1])
		for x2 in range(x0, x0 + 2 * a):
			var u: float = (float(x2) + 0.5 - float(x0)) / float(a) - 1.0
			if u < d0 or u > d1:
				continue
			var s: float = (u - d0) / (d1 - d0)
			var hgt: float = float(df) * (s / 0.25 if s < 0.25 else (1.0 - s) / 0.75)
			if kind == "perch" and dr[0] == -0.25:
				hgt = float(df) * (1.0 - 0.5 * s)
			var base_y: int = int(cy - fish_h(u, b))
			for k in range(int(round(hgt))):
				px(im, x2, base_y - 1 - k, fin[2] if k == int(round(hgt)) - 1 else fin[1])
	# анальный и брюшной плавники
	for x3 in range(x0 + int(a * 1.35), x0 + int(a * 1.75)):
		var u2: float = (float(x3) + 0.5 - float(x0)) / float(a) - 1.0
		var by2: int = int(cy + fish_h(u2, b))
		var s2: float = (u2 - 0.35) / 0.4
		for k2 in range(int(round(float(da) * (1.0 - absf(s2 - 0.3))))):
			px(im, x3, by2 + k2, fin[1])
	for x4 in range(x0 + int(a * 0.8), x0 + int(a * 1.1)):
		var u3: float = (float(x4) + 0.5 - float(x0)) / float(a) - 1.0
		var by3: int = int(cy + fish_h(u3, b))
		px(im, x4, by3, fin[1])
		if x4 > x0 + int(a * 0.8):
			px(im, x4, by3 + 1, fin[2])
	# тело
	for x5 in range(x0, x0 + 2 * a):
		var u4: float = (float(x5) + 0.5 - float(x0)) / float(a) - 1.0
		var hh: float = fish_h(u4, b)
		if hh < 0.6:
			continue
		for y2 in range(0, 32):
			var v: float = (float(y2) + 0.5 - cy) / hh
			if absf(v) > 1.0:
				continue
			var ci: int = 0 if v < -0.6 else (1 if v < -0.2 else (2 if v < 0.25 else (3 if v < 0.6 else 4)))
			var c: Color = body[ci]
			if kind == "perch" and v < 0.5:
				if (u4 > -0.45 and u4 < -0.3) or (u4 > -0.02 and u4 < 0.14) or (u4 > 0.3 and u4 < 0.44):
					c = Color("1e3422")
			elif kind == "minnow" and v > -0.1 and v < 0.2:
				c = Color("2e3a34")
			elif kind == "minnow" and v >= 0.2 and v < 0.35:
				c = Color("e6c86a")
			elif kind == "loach":
				if h01(x5, y2, 7) < 0.22 and v < 0.55:
					c = body[0]
			elif kind == "golden":
				if h01(x5, y2, 3) < 0.07 and v < 0.4:
					c = body[4]
			elif kind == "plain" and v > -0.45 and v < -0.3 and u4 > -0.4:
				c = c.lightened(0.1)
			px(im, x5, y2, c)
	# жаберная крышка
	var gx: int = x0 + int(a * 0.55)
	for y3 in range(0, 32):
		var gv: float = (float(y3) + 0.5 - cy) / maxf(0.1, fish_h(-0.45, b))
		if gv > -0.55 and gv < 0.6 and im.get_pixel(gx, y3).a > 0.5:
			im.set_pixel(gx, y3, im.get_pixel(gx, y3).darkened(0.28))
	# грудной плавник
	var pxx: int = x0 + int(a * 0.72)
	var pyy: int = int(cy + b * 0.3)
	for k3 in range(4):
		px(im, pxx + k3, pyy + k3 / 2, fin[1])
		px(im, pxx + k3, pyy + k3 / 2 + 1, fin[2])
	# глаз
	var ex: int = x0 + int(a * 0.3)
	var ey: int = int(cy - b * 0.28)
	var iris: Color = Color(String(d["eye"]))
	for ox in range(-1, 2):
		for oy in range(-1, 2):
			px(im, ex + ox, ey + oy, iris)
	px(im, ex, ey, Color("14101a"))
	px(im, ex + 1, ey, Color("14101a"))
	px(im, ex - 1, ey - 1, Color(1, 1, 1))
	# усики у вьюна
	if kind == "loach":
		px(im, x0 - 1, int(cy + 1), body[1])
		px(im, x0 - 2, int(cy + 2), body[1])
		px(im, x0 - 1, int(cy + 2), body[1])
	# блёстки у золотого
	if kind == "golden":
		for sp in [Vector2i(9, 9), Vector2i(21, 8), Vector2i(26, 14)]:
			var spv: Vector2i = sp
			px(im, spv.x, spv.y, Color(1, 1, 0.85))
			px(im, spv.x - 1, spv.y, Color(1, 1, 0.85, 0.6))
			px(im, spv.x + 1, spv.y, Color(1, 1, 0.85, 0.6))
			px(im, spv.x, spv.y - 1, Color(1, 1, 0.85, 0.6))
			px(im, spv.x, spv.y + 1, Color(1, 1, 0.85, 0.6))
	outline_auto(im, 0.6)
	save3(im, "fish_" + id, false)


func gen_potion_icon(id: String) -> void:
	var c: Array = hx(POTION_COL[id])
	var im: Image = new_img(32, 32)
	var glass: Array = hx(["5a6a7a", "a8bccc", "e8f4fa"])
	if id.ends_with("_tea"):
		# чашка на блюдце, пар
		for y in range(27, 30):
			for x in range(5, 27):
				var dx: float = (x + 0.5 - 16.0) / 11.0
				if absf(dx) > 1.0 - (0.3 if y == 29 else 0.0):
					continue
				px(im, x, y, PORCELAIN[3] if y == 27 else PORCELAIN[1])
		for y2 in range(14, 27):
			var t: float = float(y2 - 14) / 13.0
			var hw: float = 8.5 - t * t * 3.5
			for x2 in range(int(16 - hw), int(16 + hw) + 1):
				var u: float = (x2 + 0.5 - (16 - hw)) / (2.0 * hw)
				px(im, x2, y2, PORCELAIN[5] if u < 0.3 else (PORCELAIN[4] if u < 0.7 else PORCELAIN[2]))
		for x3 in range(8, 25):
			px(im, x3, 14, c[1] if x3 > 9 and x3 < 23 else PORCELAIN[3])
			px(im, x3, 15, c[0] if x3 > 9 and x3 < 23 else PORCELAIN[3])
		px(im, 11, 14, c[2])
		px(im, 12, 14, c[2])
		for k in range(4):
			px(im, 25 + (1 if k > 0 and k < 3 else 0), 17 + k, PORCELAIN[3])
		for s in [12, 17, 21]:
			for k2 in range(6):
				px(im, int(s) + int(round(sin(k2 * 0.9 + s) * 1.2)), 11 - k2, Color(1, 1, 1, 0.75 - k2 * 0.1))
		for k3 in range(5):
			px(im, 14 + k3, 20, c[1])
	elif id.ends_with("_salve"):
		# круглая баночка с крышкой
		for y in range(13, 29):
			for x in range(5, 27):
				var u2: float = (x + 0.5 - 5.0) / 22.0
				var ti: int = 2 if u2 < 0.25 else (1 if u2 < 0.75 else 0)
				px(im, x, y, c[ti])
		for x4 in range(6, 26):
			px(im, x4, 28, c[0])
		for y3 in range(8, 14):
			for x5 in range(4, 28):
				var u3: float = (x5 + 0.5 - 4.0) / 24.0
				var cc: Color = Color("c8945a") if u3 < 0.3 else (Color("a07040") if u3 < 0.75 else Color("7a5030"))
				if y3 == 8:
					cc = Color("e0b07a")
				px(im, x5, y3, cc)
		for y4 in range(17, 24):
			for x6 in range(9, 23):
				px(im, x6, y4, CREAM[4] if y4 > 17 else CREAM[2])
		flower5(im, 16, 20, c, Color("f6d86a"))
	elif id.ends_with("_tinct"):
		# бутылочка с пробкой и этикеткой
		for y in range(11, 30):
			var t2: float = float(y - 11) / 19.0
			var hw2: float = 3.0 if t2 < 0.25 else 8.0 - (0.0 if t2 < 0.95 else 1.0)
			for x in range(int(16 - hw2), int(16 + hw2) + 1):
				var u4: float = (x + 0.5 - (16 - hw2)) / (2.0 * hw2)
				var cc2: Color = glass[1]
				if t2 > 0.32:
					cc2 = c[2] if u4 < 0.25 else (c[1] if u4 < 0.7 else c[0])
				if u4 < 0.18 and t2 > 0.2:
					cc2 = glass[2]
				px(im, x, y, cc2)
		for y5 in range(5, 11):
			for x7 in range(13, 20):
				px(im, x7, y5, Color("c8945a") if x7 < 16 else Color("8a6040"))
		for y6 in range(20, 26):
			for x8 in range(11, 22):
				px(im, x8, y6, CREAM[4] if y6 > 20 and y6 < 25 else CREAM[2])
		for x9 in range(13, 20):
			px(im, x9, 22, c[0])
	else:
		# мутный отвар в миске
		for y in range(16, 29):
			for x in range(4, 28):
				var dx2: float = (x + 0.5 - 16.0) / 12.0
				var dy2: float = (y + 0.5 - 16.0) / 13.0
				if dx2 * dx2 + dy2 * dy2 > 1.0:
					continue
				px(im, x, y, Color("8a5a3a") if dx2 < 0.0 else Color("6a4028"))
		for x2 in range(6, 27):
			px(im, x2, 16, c[1])
			px(im, x2, 17, c[0])
		for b in [Vector2i(10, 14), Vector2i(17, 13), Vector2i(22, 15)]:
			var bv: Vector2i = b
			px(im, bv.x, bv.y, c[2])
			px(im, bv.x + 1, bv.y, c[1])
	outline_auto(im, 0.6)
	save3(im, "potion_" + id)


func gen_base_icons() -> void:
	# вода (кувшин), воск (свеча-соты), спирт (бутыль)
	var w: Image = new_img(32, 32)
	blob(w, 16, 20, 9, 9, hx(["3a5a7a", "5a86a8", "86b4d0", "b4dcec", "e0f4fb", "ffffff", "ffffff"]), 3)
	for y in range(6, 13):
		for x in range(12, 21):
			px(w, x, y, Color("86b4d0") if x < 17 else Color("5a86a8"))
	outline_auto(w, 0.6)
	save3(w, "base_water")
	var wx: Image = new_img(32, 32)
	for k in range(7):
		var hcx: float = 9.0 + (k % 3) * 7.0 + (3.5 if k / 3 == 1 else 0.0)
		var hcy: float = 11.0 + (k / 3) * 6.0
		if k >= 6:
			hcx = 16.0
			hcy = 23.0
		for y in range(int(hcy) - 3, int(hcy) + 4):
			for x in range(int(hcx) - 3, int(hcx) + 4):
				var d: Vector2 = Vector2(x + 0.5 - hcx, y + 0.5 - hcy)
				if absf(d.x) + absf(d.y) * 0.8 > 3.6:
					continue
				px(wx, x, y, Color("f4c85a") if d.x + d.y < -1.0 else (Color("e0a838") if d.x + d.y < 1.5 else Color("b88020")))
	outline_auto(wx, 0.6)
	save3(wx, "base_wax")
	var sp: Image = new_img(32, 32)
	for y in range(8, 30):
		var t: float = float(y - 8) / 22.0
		var hw: float = 2.5 if t < 0.3 else 7.5
		for x in range(int(16 - hw), int(16 + hw) + 1):
			var u: float = (x + 0.5 - (16 - hw)) / (2.0 * hw)
			px(sp, x, y, Color("e8f2e0") if u < 0.25 else (Color("bcd6b4") if u < 0.7 else Color("8aac86")))
	for y2 in range(4, 8):
		for x2 in range(14, 19):
			px(sp, x2, y2, Color("a07040"))
	outline_auto(sp, 0.6)
	save3(sp, "base_spirit")


func gen_coin() -> void:
	var im: Image = new_img(20, 20)
	blob(im, 10, 10, 8, 8, GOLD, 3)
	for k in range(5):
		px(im, 8 + k % 2, 6 + k * 2, GOLD[5] if k < 2 else GOLD[2])
	for y in range(6, 15):
		px(im, 10, y, GOLD[1])
	px(im, 7, 7, Color("fff4c0"))
	outline_auto(im, 0.6)
	save3(im, "coin")


## Жители: та же техника, что у героини, но свои волосы и одежда. 2 кадра (дыхание)
func gen_villagers() -> void:
	var saved_h: Array = HAIRL7.duplicate()
	var saved_w: Array = WHITE7.duplicate()
	var saved_t: Array = TEAL7.duplicate()
	var looks: Array = [
		["villager_marta", ["2a1a1e", "3e2628", "583530", "74483a", "8e5c44", "a87454", "c49272"], ["6a5a4a", "907e66", "b4a084", "d2c0a0", "e6d8bc", "f2e8d4", "fbf6ea"], ["3a1e2a", "5a2a3a", "7a3a4c", "9a4e5e", "b86a74", "d48e92", "ecb6b4"]],
		["villager_lina", ["1e1a2a", "2a2440", "3a3258", "4c4472", "625a8c", "7c74a6", "a49cc6"], ["5e6a74", "8896a2", "b0bcc6", "cfd8de", "e4eaee", "f2f6f8", "ffffff"], ["2a2a14", "44441e", "5e5e2a", "7a7838", "96924a", "b2ac64", "d0ca8c"]],
		["villager_tim", ["4a1a12", "6e2416", "92341c", "b44a24", "d06630", "e68842", "f6b064"], ["5a4a3a", "7e6a54", "a28c70", "c0ac8c", "d8c6a8", "ece0c8", "f8f2e4"], ["1a2a3e", "223a56", "2e4e70", "3e6488", "5680a2", "78a0be", "a6c4da"]],
	]
	for lk in looks:
		HAIRL7 = hx(lk[1])
		WHITE7 = hx(lk[2])
		TEAL7 = hx(lk[3])
		_head_pal()
		var sheet: Image = new_img(112, 112)
		for f in range(2):
			var cell: Image = new_img(56, 112)
			draw_hero6(cell, 0, 1 if f == 1 else 0)
			outline_auto(cell, 0.66)
			sheet.blit_rect(cell, Rect2i(0, 0, 56, 112), Vector2i(f * 56, 0))
		save3(sheet, String(lk[0]))
	HAIRL7 = saved_h
	WHITE7 = saved_w
	TEAL7 = saved_t
	_head_pal()


# ================================================================== v8: героиня 64x128 — песочные часы, округлые ноги

const OUTLINE_CHAR: float = 0.55   # одна обводка для всех персонажей


## Нога: бедро плавно сужается к колену (колено всегда на строке knee), икра с изгибом.
## side: -1 левая, 1 правая, 0 — вид сбоку. Свет слева.
func leg8(im: Image, lx: float, top: int, bot: int, knee: int, side: int, hem: int) -> void:
	for y in range(top, bot + 1):
		var hw: float
		var c: float
		if y <= knee:
			var t: float = float(y - top) / float(maxi(1, knee - top))
			hw = 4.9 - 2.5 * pow(t, 1.5)
			c = lx - float(side) * 0.8 * t
		else:
			var t2: float = float(y - knee) / float(maxi(1, bot - knee))
			hw = lerpf(2.4, 1.5, t2) + 0.75 * sin(PI * clampf(t2 * 1.5, 0.0, 1.0))
			c = lx - float(side) * 0.8 + float(side) * 0.35 * sin(PI * clampf(t2 * 1.5, 0.0, 1.0))
		for x in range(int(floor(c - hw + 0.5)), int(floor(c + hw + 0.5))):
			var u: float = (x + 0.5 - (c - hw)) / (2.0 * hw)
			var ti: int
			if u < 0.14:
				ti = 4
			elif u < 0.3:
				ti = 6
			elif u < 0.45:
				ti = 5
			elif u < 0.74:
				ti = 4
			elif u < 0.9:
				ti = 3
			else:
				ti = 2
			# внутренняя сторона бедра в тени
			var inner: bool = (side < 0 and u > 0.7) or (side > 0 and u < 0.3)
			if y < knee - 6 and inner:
				ti -= 1
			# колено: блик и тень под ним
			if y == knee - 1 and u > 0.3 and u < 0.65:
				ti = 5
			elif (y == knee + 1 or y == knee + 2) and u > 0.35 and u < 0.7:
				ti = 3
			# тень от подола платья
			if y < hem + 3:
				ti -= 1
			px(im, x, y, SKINL7[clampi(ti, 0, 6)])


## Лиф спереди: плечи -> грудь -> узкая талия; грудь светотенью
func torso8_front(im: Image, cx: float, b: int, back: bool) -> void:
	var y0: int = 34 + b
	for o in range(23):
		var y: int = y0 + o
		var hw: float
		if o < 3:
			hw = lerpf(5.4, 8.2, o / 3.0)
		elif o < 11:
			hw = lerpf(8.2, 7.6, (o - 3) / 8.0) + (0.6 * sin(PI * (o - 4) / 7.0) if o >= 4 and not back else 0.0)
		elif o < 19:
			hw = lerpf(7.6, 4.6, pow((o - 11) / 8.0, 0.8))
		else:
			hw = lerpf(4.6, 5.0, (o - 19) / 3.0)
		for x in range(int(floor(cx - hw + 0.5)), int(floor(cx + hw + 0.5))):
			var u: float = (x + 0.5 - (cx - hw)) / (2.0 * hw)
			var ti: int = 6 if u < 0.22 else (5 if u < 0.62 else (4 if u < 0.86 else 3))
			# бока талии темнее — подчёркивают силуэт
			if o > 11 and (u < 0.12 or u > 0.88):
				ti -= 1
			if not back:
				for s in [-1.0, 1.0]:
					var bc: Vector2 = Vector2(cx + s * 3.3, y0 + 8.0)
					var dx: float = (x + 0.5 - bc.x) / 3.4
					var dy: float = (y + 0.5 - bc.y) / 3.1
					var d: float = sqrt(dx * dx + dy * dy)
					if d < 1.0:
						var nv: Vector3 = Vector3(dx, dy, sqrt(maxf(0.0, 1.0 - d * d))).normalized()
						var l: float = nv.dot(LT)
						ti = 6 if l > 0.55 else (5 if l > 0.15 else 4)
					elif d < 1.28 and dy > 0.35:
						ti = mini(ti, 3)
			px(im, x, y, WHITE7[clampi(ti, 0, 6)])
	if back:
		return
	# воротник и бирюзовая планка по центру, пуговицы
	for k in range(-4, 5):
		px(im, int(cx) + k, y0 + 1 + int(round(absf(k) * -0.3 + 1.2)), TEAL7[3])
	for y2 in range(y0 + 3, y0 + 21):
		px(im, int(cx) - 2, y2, TEAL7[3])
		px(im, int(cx) + 1, y2, TEAL7[2])
	for yb in [y0 + 5, y0 + 12, y0 + 17]:
		px(im, int(cx), int(yb), WHITE7[2])
		px(im, int(cx) - 1, int(yb), WHITE7[3])
	px(im, int(cx) - 1, y0, SKINL7[4])
	px(im, int(cx), y0, SKINL7[4])
	px(im, int(cx) + 1, y0, SKINL7[3])


func belt8(im: Image, cx: float, y: int, hw: float) -> void:
	if UNDER:
		return
	for yy in range(y, y + 4):
		var h2: float = hw + (yy - y) * 0.25
		for x in range(int(floor(cx - h2 + 0.5)), int(floor(cx + h2 + 0.5))):
			var u: float = (x + 0.5 - (cx - h2)) / (2.0 * h2)
			var ti: int = 3 if u < 0.3 else (2 if u < 0.75 else 1)
			if yy == y or yy == y + 2:
				ti += 1
			px(im, x, yy, LEATH7[clampi(ti, 0, 6)])
	px(im, int(cx) + 1, y, Color("f2d06a"))
	px(im, int(cx) + 2, y, Color("d0a83a"))
	px(im, int(cx) + 1, y + 1, Color("b88a2c"))
	px(im, int(cx) + 2, y + 1, Color("8e661c"))


## Короткое платье: от талии быстро расширяется к бёдрам
func skirt8(im: Image, cx: float, y0: int, y1: int, hw0: float, hw1: float, sway: float) -> void:
	if UNDER:
		# шортики: до верха бёдер, чуть уже юбки
		y1 = mini(y1, y0 + 14)
		hw1 = minf(hw1, hw0 + 2.2)
		sway = 0.0
	for y in range(y0, y1 + 1):
		var t: float = float(y - y0) / float(maxi(1, y1 - y0))
		var hw: float = lerpf(hw0, hw1, sqrt(t))
		var c: float = cx + sway * t
		for x in range(int(floor(c - hw + 0.5)), int(floor(c + hw + 0.5))):
			var u: float = (x + 0.5 - (c - hw)) / (2.0 * hw)
			var ti: int = 6 if u < 0.25 else (5 if u < 0.62 else (4 if u < 0.86 else 3))
			if t > 0.3 and (absf(u - 0.33) < 0.035 or absf(u - 0.67) < 0.035):
				ti -= 1
			if y == y1:
				ti = 3
			px(im, x, y, WHITE7[clampi(ti, 0, 6)])
	for x2 in range(int(floor(cx + sway - hw1 + 0.5)), int(floor(cx + sway + hw1 + 0.5))):
		px(im, x2, y1, TEAL7[3] if not UNDER else WHITE7[2])
	if UNDER:
		# шов между штанинами
		for y3 in range(y1 - 5, y1 + 1):
			px(im, int(cx), y3, WHITE7[2])


func draw_hero8(im: Image, dir: int, f: int) -> void:
	var b: int = -1 if (f == 1 or f == 3) else 0
	var sw: float = 1.0 if f == 0 else (-1.0 if f == 2 else 0.0)
	var cx: float = 32.0
	var hs: float = 1.5 * sw
	var knee: int = 94
	var hem: int = 72 + b
	if dir == 0 or dir == 1:
		if dir == 0:
			hair_mass(im, cx, 14 + b, 74 + b, 13.0, 12.0, -sw * 0.8, 2)
			curls(im, cx, 30 + b, 72 + b, 13.0, 3)
		cape6(im, cx, 55 + b, 124, sw, false, dir == 0)
		var ll: int = 2 if f == 2 else 0
		var lr: int = 2 if f == 0 else 0
		if dir == 0:
			leg8(im, cx - 4.3, 64 + b, 114 - ll, knee, -1, hem)
			leg8(im, cx + 4.3, 64 + b, 114 - lr, knee, 1, hem)
		boot6(im, cx - 5.1, 114 - ll, 0)
		boot6(im, cx + 5.1, 114 - lr, 0)
		skirt8(im, cx, 57 + b, hem, 5.6, 10.5, sw * 0.6)
		if dir == 0:
			cape6(im, cx, 55 + b, 124, sw, true, false)
		else:
			cape6(im, cx, 55 + b, 122, sw, false, false)
		torso8_front(im, cx, b, dir == 1)
		belt8(im, cx, 54 + b, 4.9)
		if dir == 1:
			# бант на спине
			blob(im, cx - 2.5, 56.0 + b, 2.2, 1.5, WHITE7, 5)
			blob(im, cx + 2.5, 56.0 + b, 2.2, 1.5, WHITE7, 4)
		var tl: int = 4 if dir == 0 else 3
		arm6(im, Vector2(cx - 8.6, 37 + b), Vector2(cx - 14.5 - hs * 0.3, 84 + b + hs * (1.0 if dir == 0 else -1.0)), tl)
		arm6(im, Vector2(cx + 8.6, 37 + b), Vector2(cx + 14.5 - hs * 0.3, 84 + b - hs * (1.0 if dir == 0 else -1.0)), tl - 1)
		if dir == 0:
			head6(im, int(cx) - 15, b, false)
			for side in [-1, 1]:
				var s: float = float(side)
				for y in range(30 + b, 52 + b):
					var t: float = float(y - 30 - b) / 22.0
					var xc: float = cx + s * (10.5 + sin(y * 0.5) * 0.9 + t * 1.5)
					var hw: float = 2.4 - t * 1.2
					for x in range(int(floor(xc - hw)), int(ceil(xc + hw))):
						var u: float = (x + 0.5 - (xc - hw)) / (2.0 * hw)
						var ti: int = 5 if u < 0.35 else (4 if u < 0.75 else 3)
						if s > 0.0:
							ti -= 1
						if posmod(y, 6) == 0:
							ti -= 1
						px(im, x, y, HAIRL7[clampi(ti, 0, 6)])
		else:
			blob(im, cx, 17.0 + b, 12.6, 12.0, HAIRL7, 4)
			hair_mass(im, cx, 18 + b, 76 + b, 13.0, 15.5, sw * 0.9, 4)
			curls(im, cx, 30 + b, 74 + b, 15.5, 4)
			for x0 in range(int(cx) - 15, int(cx) + 16):
				for band in [10, 32, 56]:
					var yb: int = int(band) + b + int(round(sin(x0 * 0.8) * 1.2))
					if a_at(im, x0, yb) > 0.5 and a_at(im, x0, yb + 1) > 0.5:
						px(im, x0, yb, HAIRL7[6] if posmod(x0, 3) != 0 else HAIRL7[5])
						px(im, x0, yb + 1, HAIRL7[5])
			for xs in [-10, -5, 0, 5, 10]:
				for y6 in range(16 + b, 74 + b):
					var xw: int = int(cx) + int(xs) + int(round(sin(y6 * 0.35 + float(xs)) * 1.4))
					if a_at(im, xw, y6) > 0.5:
						px(im, xw, y6, HAIRL7[2])
			for p in [Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(3, 1), Vector2i(3, 2), Vector2i(1, 3), Vector2i(2, 3), Vector2i(2, 4)]:
				var pv: Vector2i = p
				px(im, int(cx) + pv.x, pv.y + b, HAIRL7[4])
	else:
		var fd: float = -4.0 if f == 0 else (4.0 if f == 2 else 0.0)
		hair_mass(im, cx + 6.0, 14 + b, 72 + b, 8.0, 10.0, sw * 1.4 + 1.5, 3)
		curls(im, cx + 6.0, 30 + b, 70 + b, 10.0, 5)
		# плащ сзади развевается
		for y in range(55 + b, 124):
			var t: float = float(y - 55 - b) / float(69 - b)
			var c: float = cx + 2.0 + t * t * (4.0 - sw * 2.0)
			var back: float = lerpf(6.0, 17.0, pow(t, 0.8))
			var front: float = lerpf(3.0, 4.0, t)
			for x in range(int(floor(c - front)), int(ceil(c + back))):
				var dx: float = x + 0.5 - c
				var hem_y: float = 122.0 + sin(dx * 0.5) * 1.5 + dx * 0.1
				if y > hem_y:
					continue
				var u: float = (dx + front) / (front + back)
				var ti2: int = 5 if u < 0.2 else (4 if u < 0.55 else (3 if u < 0.85 else 2))
				if t > 0.15 and sin(dx * 0.9 + t) > 0.85:
					ti2 -= 1
				if y > hem_y - 1.0:
					ti2 -= 2
				px(im, x, y, TEAL7[clampi(ti2, 0, 6)])
		var back_leg: float = cx + 1.0 - fd * 0.5
		var front_leg: float = cx - 1.0 + fd * 0.5
		leg8(im, back_leg, 64 + b, 114, knee, 0, hem)
		boot6(im, back_leg, 114, -1)
		var lift: int = 2 if f == 1 or f == 3 else 0
		leg8(im, front_leg, 64 + b, 114 - lift, knee, 0, hem)
		boot6(im, front_leg, 114 - lift, -1)
		# платье: бедро округляется назад
		for y2 in range(57 + b, hem + 1):
			var t3: float = float(y2 - 57 - b) / float(maxi(1, hem - 57 - b))
			var fr: float = lerpf(4.0, 6.0, sqrt(t3))
			var bk: float = lerpf(4.4, 7.6, sqrt(t3))
			for x2 in range(int(floor(cx - fr + 0.5)), int(floor(cx + bk + 0.5))):
				var u2: float = (x2 + 0.5 - (cx - fr)) / (fr + bk)
				var ti3: int = 6 if u2 < 0.3 else (5 if u2 < 0.7 else 4)
				if y2 == hem:
					ti3 = 3
				px(im, x2, y2, WHITE7[ti3])
		for x3 in range(int(cx) - 6, int(cx) + 8):
			px(im, x3, hem, TEAL7[3])
		# торс в профиль: грудь вперёд, талия, спина
		for o in range(23):
			var y3: int = 34 + b + o
			var front: float
			var back2: float
			if o < 4:
				front = 4.4
				back2 = 4.6
			elif o < 11:
				front = 4.4 + 1.8 * sin(PI * (o - 4) / 7.0)
				back2 = lerpf(4.6, 4.2, (o - 4) / 7.0)
			elif o < 19:
				front = lerpf(4.4, 3.6, (o - 11) / 8.0)
				back2 = lerpf(4.2, 3.4, (o - 11) / 8.0)
			else:
				front = 3.8
				back2 = lerpf(3.4, 4.2, (o - 19) / 3.0)
			for x4 in range(int(floor(cx - front + 0.5)), int(floor(cx + back2 + 0.5))):
				var u3: float = (x4 + 0.5 - (cx - front)) / (front + back2)
				var ti4: int = 6 if u3 < 0.3 else (5 if u3 < 0.7 else 4)
				if o >= 9 and o <= 10 and u3 < 0.35:
					ti4 = 3
				px(im, x4, y3, WHITE7[ti4])
		for y4 in range(37 + b, 53 + b):
			var fx: float = 4.4 + (1.8 * sin(PI * (y4 - 38 - b) / 7.0) if y4 >= 38 + b and y4 < 45 + b else 0.0)
			px(im, int(floor(cx - fx + 1.5)), y4, TEAL7[3])
		belt8(im, cx, 54 + b, 3.9)
		arm6(im, Vector2(cx + 1.0, 37 + b), Vector2(cx - sw * 6.0, 83 + b), 4)
		head6(im, int(cx) - 16, b, true)


func gen_player8() -> void:
	HAIRL7 = hx(["4a3430", "6e5244", "907058", "b08e6e", "c8a884", "dcc4a0", "eee0c4"])
	SKINL7 = hx(["8a5a5a", "b87c74", "dca092", "f0c0ac", "fad8c6", "fde8dc", "fff4ee"])
	WHITE7 = hx(["5a5c74", "8487a0", "aab0c2", "ccd2dc", "e6eaee", "f5f7f4", "ffffff"])
	TEAL7 = hx(["0e2834", "143e4a", "1c5660", "267274", "378e8a", "5eaea2", "96d0c0"])
	_head_pal()
	var fw: int = 64
	var fh: int = 128
	var sheet: Image = new_img(fw * 4, fh * 4)
	for dir in range(3):
		for f in range(4):
			var cell: Image = new_img(fw, fh)
			draw_hero8(cell, dir, f)
			outline_auto(cell, OUTLINE_CHAR)
			sheet.blit_rect(cell, Rect2i(0, 0, fw, fh), Vector2i(f * fw, dir * fh))
			if dir == 2:
				var m: Image = cell.duplicate()
				m.flip_x()
				sheet.blit_rect(m, Rect2i(0, 0, fw, fh), Vector2i(f * fw, 3 * fh))
	save3(sheet, "player")
	var big: Image = sheet.duplicate()
	big.resize(sheet.get_width() * 3, sheet.get_height() * 3, Image.INTERPOLATE_NEAREST)
	big.save_png(ProjectSettings.globalize_path("res://").path_join("../screenshots/player_zoom.png"))
	var one: Image = new_img(fw, fh)
	one.blit_rect(sheet, Rect2i(0, 0, fw, fh), Vector2i.ZERO)
	one.resize(fw * 7, fh * 7, Image.INTERPOLATE_NEAREST)
	one.save_png(ProjectSettings.globalize_path("res://").path_join("../screenshots/player_front_big.png"))
	# жители — тем же способом, свои цвета
	var looks: Array = [
		["villager_marta", ["2a1a1e", "3e2628", "583530", "74483a", "8e5c44", "a87454", "c49272"], ["6a5a4a", "907e66", "b4a084", "d2c0a0", "e6d8bc", "f2e8d4", "fbf6ea"], ["3a1e2a", "5a2a3a", "7a3a4c", "9a4e5e", "b86a74", "d48e92", "ecb6b4"]],
		["villager_lina", ["1e1a2a", "2a2440", "3a3258", "4c4472", "625a8c", "7c74a6", "a49cc6"], ["5e6a74", "8896a2", "b0bcc6", "cfd8de", "e4eaee", "f2f6f8", "ffffff"], ["2a2a14", "44441e", "5e5e2a", "7a7838", "96924a", "b2ac64", "d0ca8c"]],
		["villager_tim", ["4a1a12", "6e2416", "92341c", "b44a24", "d06630", "e68842", "f6b064"], ["5a4a3a", "7e6a54", "a28c70", "c0ac8c", "d8c6a8", "ece0c8", "f8f2e4"], ["1a2a3e", "223a56", "2e4e70", "3e6488", "5680a2", "78a0be", "a6c4da"]],
	]
	var sh: Array = HAIRL7.duplicate()
	var sw7: Array = WHITE7.duplicate()
	var st: Array = TEAL7.duplicate()
	for lk in looks:
		HAIRL7 = hx(lk[1])
		WHITE7 = hx(lk[2])
		TEAL7 = hx(lk[3])
		_head_pal()
		var vs: Image = new_img(fw * 2, fh)
		for k in range(2):
			var c2: Image = new_img(fw, fh)
			draw_hero8(c2, 0, 1 if k == 1 else 0)
			outline_auto(c2, OUTLINE_CHAR)
			vs.blit_rect(c2, Rect2i(0, 0, fw, fh), Vector2i(k * fw, 0))
		save3(vs, String(lk[0]))
	HAIRL7 = sh
	WHITE7 = sw7
	TEAL7 = st
	_head_pal()


## Проверочный лист: всё в реальном игровом размере (мир x2, героиня x1 — как в игре)
func gen_lineup() -> void:
	var items: Array = ["tree_a", "pine_b", "bush_a", "rock", "cauldron", "mint_3", "lavender_3"]
	var sheet: Image = new_img(1400, 420)
	sheet.fill(Color("a9cf8e"))
	var x: int = 20
	var base: int = 400
	for n in items:
		var im: Image = Image.load_from_file(ProjectSettings.globalize_path(OUT + String(n) + ".png"))
		im.resize(im.get_width() * 2, im.get_height() * 2, Image.INTERPOLATE_NEAREST)
		sheet.blend_rect(im, Rect2i(0, 0, im.get_width(), im.get_height()), Vector2i(x, base - im.get_height()))
		x += im.get_width() + 10
	var pl: Image = Image.load_from_file(ProjectSettings.globalize_path(OUT + "player.png"))
	var fr: Image = new_img(80, 160)
	fr.blit_rect(pl, Rect2i(0, 0, 80, 160), Vector2i.ZERO)
	sheet.blend_rect(fr, Rect2i(0, 0, 80, 160), Vector2i(x, base - 157))
	x += 90
	var cat: Image = Image.load_from_file(ProjectSettings.globalize_path(OUT + "cat.png"))
	var cf: Image = new_img(36, 30)
	cf.blit_rect(cat, Rect2i(0, 0, 36, 30), Vector2i.ZERO)
	cf.resize(72, 60, Image.INTERPOLATE_NEAREST)
	sheet.blend_rect(cf, Rect2i(0, 0, 72, 60), Vector2i(x, base - 60))
	sheet.save_png(ProjectSettings.globalize_path("res://").path_join("../screenshots/lineup.png"))


# ================================================================== v9: героиня 80x160 — анатомия ног по референсу, профиль

## Голова строго в профиль, смотрит влево (нос, один глаз, подбородок)
const HEAD_PROFILE: Array = [
	"..............hL",
	"...............L",
	"..........hHHHHLHHh",
	"........hHHLLLLHHHHHh",
	".......hHLLLLLHHHHHHHh",
	"......hHLLLHHHHHHHHHHHh",
	".....hHHHHHHHHHHHHHHHHHh",
	".....hHHHHHHHHHHHHHHHHHh",
	"....hHHHHHHHHHHHHHHHHHHh",
	"....hHHHhHHHHHHHHHHHHHHHh",
	"....hHHhSHHHHHHHHHHHHHHHh",
	"....hHhSShHHHHHHHHHHHHHHh",
	"....hhSSShSHHHHHHHHHHHHHh",
	"....hSSSSSShHHHHHHHHHHHHh",
	"....SSSSSSSShHHHHHHHHHHHh",
	"...SddSSSSSShHHHHHHHHHHHh",
	"...EEEESSSSShHHHHHHHHHHHh",
	"...SIWESSSSShHHHHHHHHHHHh",
	"...SIIwSSSSShHHHHHHHHHHHh",
	"...SijwSSSSSShHHHHHHHHHHh",
	"...SeeSSSSSSShHHHHHHHHHHh",
	"..SSSSSSSSSSShHHHHHHHHHHh",
	".SSSSSSBBSSSShHHHHHHHHHHh",
	"..TSSSSBBSSSShHHHHHHHHHHh",
	"...SSSSSSSSShHHHHHHHHHHh",
	"...MSSSSSSSShHHHHHHHHHHh",
	"...TSSSSSSSShHHHHHHHHHh",
	"....TSSSSSSThHHHHHHHHHh",
	".....TSSSSTThHHHHHHHHh",
	"......TTSSShhHHHHHHHh",
	"........TSSThHHHHHHh",
	"........TSST.hHHHHh",
	"........TSST..hHHh",
	"........TSST...hh",
]


## Плавная кривая по ключевым точкам [(s, значение)], s 0..1
func curve_at(keys: Array, s: float) -> float:
	if s <= float(keys[0].x):
		return float(keys[0].y)
	for i in range(keys.size() - 1):
		var a: Vector2 = keys[i]
		var b2: Vector2 = keys[i + 1]
		if s <= b2.x:
			var t: float = (s - a.x) / maxf(0.0001, b2.x - a.x)
			return lerpf(a.y, b2.y, t * t * (3.0 - 2.0 * t))
	return float(keys[keys.size() - 1].y)


## Нога спереди по анатомии: бедро сходится с другим наверху, колени чуть внутрь,
## икра выпуклая снаружи, тонкая щиколотка. side -1 левая, 1 правая.
const LEG_OUT: Array = [Vector2(0.0, 10.4), Vector2(0.12, 10.2), Vector2(0.30, 8.8), Vector2(0.46, 6.6), Vector2(0.62, 7.4), Vector2(0.80, 6.0), Vector2(0.96, 4.6), Vector2(1.0, 4.5)]
const LEG_IN: Array = [Vector2(0.0, 0.0), Vector2(0.22, 0.4), Vector2(0.38, 1.2), Vector2(0.47, 0.7), Vector2(0.58, 1.3), Vector2(0.80, 1.9), Vector2(1.0, 2.1)]


func leg_front9(im: Image, cx: float, side: int, top: int, knee: int, bot: int, hem: int) -> void:
	for y in range(top, bot + 1):
		var s: float
		if y <= knee:
			s = 0.46 * float(y - top) / float(maxi(1, knee - top))
		else:
			s = 0.46 + 0.54 * float(y - knee) / float(maxi(1, bot - knee))
		var o: float = curve_at(LEG_OUT, s)
		var i0: float = curve_at(LEG_IN, s)
		var xa: float = cx + float(side) * i0
		var xb: float = cx + float(side) * o
		var x0: float = minf(xa, xb)
		var x1: float = maxf(xa, xb)
		for x in range(int(floor(x0 + 0.5)), int(floor(x1 + 0.5))):
			var u: float = absf(x + 0.5 - cx) - i0
			u = u / maxf(0.5, o - i0)
			var hl: float = 0.62 if side < 0 else 0.42
			var ti: int = 4
			if u < 0.12:
				ti = 2
			elif u < 0.26:
				ti = 3
			elif absf(u - hl) < 0.14:
				ti = 5
			elif u > 0.9:
				ti = 4 if side < 0 else 2
			elif u > 0.78 and side > 0:
				ti = 3
			# колено: блик сверху, полумесяц тени снизу
			if s > 0.42 and s < 0.455 and absf(u - 0.5) < 0.2:
				ti = 5
			elif s > 0.475 and s < 0.5 and absf(u - 0.5) < 0.24:
				ti = 3
			# блик на голени
			if s > 0.52 and s < 0.9 and absf(u - (hl - 0.06)) < 0.08:
				ti = 5
			# тень от подола
			if y < hem + 2:
				ti -= 2
			elif y < hem + 5:
				ti -= 1
			px(im, x, y, SKINL7[clampi(ti, 0, 6)])


func boot9(im: Image, cx: float, top: int, toe: int) -> void:
	for y in range(top, top + 14):
		var t: float = float(y - top) / 13.0
		var hw: float = 3.2 if t < 0.65 else 3.2 + (t - 0.65) * 3.0
		var sx: float = cx + float(toe) * (t - 0.6) * 4.0 if t > 0.6 else cx
		for x in range(int(floor(sx - hw + 0.5)), int(floor(sx + hw + 0.5))):
			var u: float = (x + 0.5 - (sx - hw)) / (2.0 * hw)
			var ti: int = 5 if u < 0.25 else (4 if u < 0.6 else (3 if u < 0.85 else 2))
			if y == top or y == top + 1:
				ti = 5 if u < 0.6 else 4
			if y >= top + 12:
				ti = 0 if y == top + 13 else 1
			if y > top + 2 and y < top + 9 and posmod(y - top, 2) == 0 and absf(u - 0.5) < 0.16:
				ti = 6
			px(im, x, y, LEATH7[clampi(ti, 0, 6)])


## Лиф: плечи -> крупная грудь ниже -> узкая талия
func torso9_front(im: Image, cx: float, b: int, back: bool) -> void:
	var y0: int = 34 + b
	var keys: Array = [Vector2(0, 5.6), Vector2(3, 9.0), Vector2(8, 8.8), Vector2(12, 9.6), Vector2(16, 8.4), Vector2(22, 5.2), Vector2(26, 5.6)]
	if back:
		keys = [Vector2(0, 5.6), Vector2(3, 9.0), Vector2(10, 8.4), Vector2(22, 5.2), Vector2(26, 5.6)]
	for o in range(27):
		var y: int = y0 + o
		var hw: float = curve_at_abs(keys, float(o))
		for x in range(int(floor(cx - hw + 0.5)), int(floor(cx + hw + 0.5))):
			var u: float = (x + 0.5 - (cx - hw)) / (2.0 * hw)
			var ti: int = 6 if u < 0.22 else (5 if u < 0.62 else (4 if u < 0.86 else 3))
			if o > 15 and (u < 0.12 or u > 0.88):
				ti -= 1
			if not back:
				for s in [-1.0, 1.0]:
					var bc: Vector2 = Vector2(cx + s * 4.0, y0 + 12.0)
					var dx: float = (x + 0.5 - bc.x) / 4.6
					var dy: float = (y + 0.5 - bc.y) / 4.4
					var d: float = sqrt(dx * dx + dy * dy)
					if d < 1.0:
						var nv: Vector3 = Vector3(dx, dy, sqrt(maxf(0.0, 1.0 - d * d))).normalized()
						var l: float = nv.dot(LT)
						ti = 6 if l > 0.6 else (5 if l > 0.25 else (4 if l > -0.1 else 3))
					elif d < 1.3 and dy > 0.3:
						ti = mini(ti, 3 if d < 1.18 else 4)
				# ложбинка-складка ткани между
				if absf(x + 0.5 - cx) < 0.8 and o > 9 and o < 15:
					ti = mini(ti, 4)
			px(im, x, y, WHITE7[clampi(ti, 0, 6)])
	if back:
		return
	for k in range(-4, 5):
		px(im, int(cx) + k, y0 + 1 + int(round(absf(k) * -0.3 + 1.2)), TEAL7[3])
	for y2 in range(y0 + 3, y0 + 9):
		px(im, int(cx) - 2, y2, TEAL7[3])
		px(im, int(cx) + 1, y2, TEAL7[2])
	for y3 in range(y0 + 17, y0 + 24):
		px(im, int(cx) - 1, y3, TEAL7[3])
	px(im, int(cx) - 1, y0, SKINL7[4])
	px(im, int(cx), y0, SKINL7[4])
	px(im, int(cx) + 1, y0, SKINL7[3])


func curve_at_abs(keys: Array, x: float) -> float:
	var first: Vector2 = keys[0]
	var last: Vector2 = keys[keys.size() - 1]
	return curve_at_norm(keys, x, first.x, last.x)


func curve_at_norm(keys: Array, x: float, a: float, b2: float) -> float:
	var nk: Array = []
	for k in keys:
		var kv: Vector2 = k
		nk.append(Vector2((kv.x - a) / (b2 - a), kv.y))
	return curve_at(nk, (x - a) / (b2 - a))


## Нога сбоку: от бедра (hip) к стопе (foot), колено на строке knee
func leg_side9(im: Image, hip: Vector2, foot: Vector2, knee: int, hem: int, far: bool) -> void:
	var top: int = int(hip.y)
	var bot: int = int(foot.y)
	var kx: float = lerpf(hip.x, foot.x, 0.5) - 1.0
	for y in range(top, bot + 1):
		var s: float
		var c: float
		if y <= knee:
			s = 0.46 * float(y - top) / float(maxi(1, knee - top))
			c = lerpf(hip.x, kx, float(y - top) / float(maxi(1, knee - top)))
		else:
			s = 0.46 + 0.54 * float(y - knee) / float(maxi(1, bot - knee))
			c = lerpf(kx, foot.x, float(y - knee) / float(maxi(1, bot - knee)))
		var fr: float = curve_at([Vector2(0, 5.0), Vector2(0.3, 4.4), Vector2(0.46, 2.8), Vector2(0.62, 2.4), Vector2(1.0, 1.6)], s)
		var bk: float = curve_at([Vector2(0, 5.4), Vector2(0.3, 4.0), Vector2(0.46, 2.6), Vector2(0.62, 3.6), Vector2(0.85, 2.2), Vector2(1.0, 1.6)], s)
		for x in range(int(floor(c - fr + 0.5)), int(floor(c + bk + 0.5))):
			var u: float = (x + 0.5 - (c - fr)) / (fr + bk)
			var ti: int = 5 if u < 0.3 else (4 if u < 0.7 else (3 if u < 0.9 else 2))
			if s > 0.42 and s < 0.47 and u < 0.35:
				ti = 6
			if far:
				ti -= 1
			if y < hem + 2:
				ti -= 2
			elif y < hem + 5:
				ti -= 1
			px(im, x, y, SKINL7[clampi(ti, 0, 6)])


func draw_hero9(im: Image, dir: int, f: int) -> void:
	var b: int = -1 if (f == 1 or f == 3) else 0
	var sw: float = 1.0 if f == 0 else (-1.0 if f == 2 else 0.0)
	var cx: float = 40.0
	var hs: float = 1.8 * sw
	var knee: int = 112
	var hem: int = 80 + b
	var foot_y: int = 143
	if dir == 0 or dir == 1:
		if dir == 0:
			hair_mass(im, cx, 14 + b, 86 + b, 13.0, 12.5, -sw * 0.8, 2)
			curls(im, cx, 32 + b, 84 + b, 13.5, 3)
		cape6(im, cx, 60 + b, 157, sw, false, dir == 0)
		var ll: int = 2 if f == 2 else 0
		var lr: int = 2 if f == 0 else 0
		if dir == 0:
			leg_front9(im, cx, -1, 74 + b, knee, foot_y - ll, hem)
			leg_front9(im, cx, 1, 74 + b, knee, foot_y - lr, hem)
		boot9(im, cx - 4.6, foot_y - 1 - ll, -1)
		boot9(im, cx + 4.6, foot_y - 1 - lr, 1)
		skirt8(im, cx, 61 + b, hem, 6.0, 12.0, sw * 0.6)
		if dir == 0:
			cape6(im, cx, 60 + b, 157, sw, true, false)
		else:
			cape6(im, cx, 60 + b, 155, sw, false, false)
		torso9_front(im, cx, b, dir == 1)
		belt8(im, cx, 58 + b, 5.4)
		if dir == 1:
			blob(im, cx - 2.6, 61.0 + b, 2.4, 1.6, WHITE7, 5)
			blob(im, cx + 2.6, 61.0 + b, 2.4, 1.6, WHITE7, 4)
		var tl: int = 4 if dir == 0 else 3
		var sg: float = 1.0 if dir == 0 else -1.0
		arm6(im, Vector2(cx - 9.6, 37 + b), Vector2(cx - 16.5 - hs * 0.3, 96 + b + hs * sg), tl)
		arm6(im, Vector2(cx + 9.6, 37 + b), Vector2(cx + 16.5 - hs * 0.3, 96 + b - hs * sg), tl - 1)
		if dir == 0:
			head6(im, int(cx) - 15, b, false)
			for side in [-1, 1]:
				var s: float = float(side)
				for y in range(30 + b, 54 + b):
					var t: float = float(y - 30 - b) / 24.0
					var xc: float = cx + s * (11.0 + sin(y * 0.5) * 0.9 + t * 1.8)
					var hw: float = 2.4 - t * 1.2
					for x in range(int(floor(xc - hw)), int(ceil(xc + hw))):
						var u: float = (x + 0.5 - (xc - hw)) / (2.0 * hw)
						var ti: int = 5 if u < 0.35 else (4 if u < 0.75 else 3)
						if s > 0.0:
							ti -= 1
						if posmod(y, 6) == 0:
							ti -= 1
						px(im, x, y, HAIRL7[clampi(ti, 0, 6)])
		else:
			blob(im, cx, 17.0 + b, 12.6, 12.0, HAIRL7, 4)
			hair_mass(im, cx, 18 + b, 88 + b, 13.0, 15.5, sw * 0.9, 4)
			curls(im, cx, 32 + b, 86 + b, 15.5, 4)
			for x0 in range(int(cx) - 16, int(cx) + 17):
				for band in [10, 36, 64]:
					var yb: int = int(band) + b + int(round(sin(x0 * 0.8) * 1.2))
					if a_at(im, x0, yb) > 0.5 and a_at(im, x0, yb + 1) > 0.5:
						px(im, x0, yb, HAIRL7[6] if posmod(x0, 3) != 0 else HAIRL7[5])
						px(im, x0, yb + 1, HAIRL7[5])
			for xs in [-10, -5, 0, 5, 10]:
				for y6 in range(16 + b, 86 + b):
					var xw: int = int(cx) + int(xs) + int(round(sin(y6 * 0.35 + float(xs)) * 1.4))
					if a_at(im, xw, y6) > 0.5:
						px(im, xw, y6, HAIRL7[2])
			for p in [Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(3, 1), Vector2i(3, 2), Vector2i(1, 3), Vector2i(2, 3), Vector2i(2, 4)]:
				var pv: Vector2i = p
				px(im, int(cx) + pv.x, pv.y + b, HAIRL7[4])
	else:
		var fd: float = -5.0 if f == 0 else (5.0 if f == 2 else 0.0)
		# волосы за спиной
		hair_mass(im, cx + 5.0, 14 + b, 82 + b, 8.5, 10.0, sw * 1.4 + 1.5, 3)
		curls(im, cx + 5.0, 32 + b, 80 + b, 10.0, 5)
		# плащ сзади
		for y in range(60 + b, 157):
			var t: float = float(y - 60 - b) / float(97 - b)
			var c: float = cx + 3.0 + t * t * (4.0 - sw * 2.0)
			var back: float = lerpf(6.0, 18.0, pow(t, 0.8))
			var front: float = lerpf(3.0, 4.0, t)
			for x in range(int(floor(c - front)), int(ceil(c + back))):
				var dx: float = x + 0.5 - c
				var hem_y: float = 155.0 + sin(dx * 0.5) * 1.5 + dx * 0.1
				if y > hem_y:
					continue
				var u: float = (dx + front) / (front + back)
				var ti2: int = 5 if u < 0.2 else (4 if u < 0.55 else (3 if u < 0.85 else 2))
				if t > 0.15 and sin(dx * 0.9 + t) > 0.85:
					ti2 -= 1
				if y > hem_y - 1.0:
					ti2 -= 2
				px(im, x, y, TEAL7[clampi(ti2, 0, 6)])
		# ноги: дальняя (темнее), ближняя
		var lift: int = 2 if f == 1 or f == 3 else 0
		leg_side9(im, Vector2(cx + 0.5, 74 + b), Vector2(cx + 0.5 - fd, foot_y), knee, hem, true)
		boot9(im, cx + 0.5 - fd, foot_y - 1, -1)
		leg_side9(im, Vector2(cx - 0.5, 74 + b), Vector2(cx - 0.5 + fd, foot_y - lift), knee, hem, false)
		boot9(im, cx - 0.5 + fd, foot_y - 1 - lift, -1)
		# платье: попа и бёдра округляются назад
		for y2 in range(61 + b, hem + 1):
			var t3: float = float(y2 - 61 - b) / float(maxi(1, hem - 61 - b))
			var frn: float = lerpf(4.4, 6.4, sqrt(t3))
			var bkn: float = lerpf(4.6, 8.6, sqrt(t3)) - (t3 - 0.6) * 2.0 * float(t3 > 0.6)
			for x2 in range(int(floor(cx - frn + 0.5)), int(floor(cx + bkn + 0.5))):
				var u2: float = (x2 + 0.5 - (cx - frn)) / (frn + bkn)
				var ti3: int = 6 if u2 < 0.3 else (5 if u2 < 0.7 else 4)
				if y2 == hem:
					ti3 = 3
				px(im, x2, y2, WHITE7[ti3])
		for x3 in range(int(cx) - 6, int(cx) + 9):
			if a_at(im, x3, hem) > 0.5:
				px(im, x3, hem, TEAL7[3])
		# торс в профиль: грудь заметно вперёд и ниже, талия, спина
		var fk: Array = [Vector2(0, 4.6), Vector2(4, 4.8), Vector2(9, 7.6), Vector2(13, 8.0), Vector2(16, 5.6), Vector2(21, 4.0), Vector2(26, 4.4)]
		var bkk: Array = [Vector2(0, 4.8), Vector2(6, 4.8), Vector2(16, 4.0), Vector2(22, 3.4), Vector2(26, 4.4)]
		for o in range(27):
			var y3: int = 34 + b + o
			var front2: float = curve_at_abs(fk, float(o))
			var back2: float = curve_at_abs(bkk, float(o))
			for x4 in range(int(floor(cx - front2 + 0.5)), int(floor(cx + back2 + 0.5))):
				var u3: float = (x4 + 0.5 - (cx - front2)) / (front2 + back2)
				var ti4: int = 6 if u3 < 0.3 else (5 if u3 < 0.7 else 4)
				if o >= 9 and o <= 14 and u3 < 0.3:
					ti4 = 6 if o < 12 else 5
				if o >= 15 and o <= 16 and u3 < 0.4:
					ti4 = 3
				px(im, x4, y3, WHITE7[ti4])
		for k in range(4):
			px(im, int(cx) - 4, 36 + b + k, TEAL7[3])
		belt8(im, cx, 58 + b, 4.2)
		arm6(im, Vector2(cx + 1.0, 37 + b), Vector2(cx - sw * 7.0, 95 + b), 4)
		grid(im, HEAD_PROFILE, int(cx) - 12, b, _profile_pal())


func _profile_pal() -> Dictionary:
	var pal: Dictionary = HEAD_PAL.duplicate()
	pal["E"] = Color("2a1622")
	pal["I"] = Color("4a2630")
	pal["i"] = Color("8e4e48")
	pal["j"] = Color("d08a62")
	pal["w"] = Color("f6f0ee")
	pal["e"] = Color("c88a8a")
	pal["W"] = Color("ffffff")
	pal["d"] = HAIRL7[2]
	pal["B"] = Color("f7b4b0")
	pal["M"] = Color("d8767a")
	for k in EYE_OVR.keys():
		pal[k] = EYE_OVR[k]
	return pal


func gen_player9() -> void:
	HAIRL7 = hx(["4a3430", "6e5244", "907058", "b08e6e", "c8a884", "dcc4a0", "eee0c4"])
	SKINL7 = hx(["7a4a4c", "a8645e", "d08a7c", "eaae98", "f8ccb8", "fde2d4", "fff2ea"])
	WHITE7 = hx(["5a5c74", "8487a0", "aab0c2", "ccd2dc", "e6eaee", "f5f7f4", "ffffff"])
	TEAL7 = hx(["0e2834", "143e4a", "1c5660", "267274", "378e8a", "5eaea2", "96d0c0"])
	_head_pal()
	var fw: int = 80
	var fh: int = 160
	var sheet: Image = new_img(fw * 4, fh * 4)
	for dir in range(3):
		for f in range(4):
			var cell: Image = new_img(fw, fh)
			draw_hero9(cell, dir, f)
			outline_auto(cell, OUTLINE_CHAR)
			sheet.blit_rect(cell, Rect2i(0, 0, fw, fh), Vector2i(f * fw, dir * fh))
			if dir == 2:
				var m: Image = cell.duplicate()
				m.flip_x()
				sheet.blit_rect(m, Rect2i(0, 0, fw, fh), Vector2i(f * fw, 3 * fh))
	save3(sheet, "player")
	var big: Image = sheet.duplicate()
	big.resize(sheet.get_width() * 2, sheet.get_height() * 2, Image.INTERPOLATE_NEAREST)
	big.save_png(ProjectSettings.globalize_path("res://").path_join("../screenshots/player_zoom.png"))
	for pair in [[0, "player_front_big.png"], [8, "player_side_big.png"]]:
		var idx: int = int(pair[0])
		var one: Image = new_img(fw, fh)
		one.blit_rect(sheet, Rect2i((idx % 4) * fw, (idx / 4) * fh, fw, fh), Vector2i.ZERO)
		one.resize(fw * 6, fh * 6, Image.INTERPOLATE_NEAREST)
		one.save_png(ProjectSettings.globalize_path("res://").path_join("../screenshots/" + String(pair[1])))
	var looks: Array = [
		["villager_marta", ["2a1a1e", "3e2628", "583530", "74483a", "8e5c44", "a87454", "c49272"], ["6a5a4a", "907e66", "b4a084", "d2c0a0", "e6d8bc", "f2e8d4", "fbf6ea"], ["3a1e2a", "5a2a3a", "7a3a4c", "9a4e5e", "b86a74", "d48e92", "ecb6b4"]],
		["villager_lina", ["1e1a2a", "2a2440", "3a3258", "4c4472", "625a8c", "7c74a6", "a49cc6"], ["5e6a74", "8896a2", "b0bcc6", "cfd8de", "e4eaee", "f2f6f8", "ffffff"], ["2a2a14", "44441e", "5e5e2a", "7a7838", "96924a", "b2ac64", "d0ca8c"]],
		["villager_tim", ["4a1a12", "6e2416", "92341c", "b44a24", "d06630", "e68842", "f6b064"], ["5a4a3a", "7e6a54", "a28c70", "c0ac8c", "d8c6a8", "ece0c8", "f8f2e4"], ["1a2a3e", "223a56", "2e4e70", "3e6488", "5680a2", "78a0be", "a6c4da"]],
	]
	var sh: Array = HAIRL7.duplicate()
	var sw7: Array = WHITE7.duplicate()
	var st: Array = TEAL7.duplicate()
	for lk in looks:
		HAIRL7 = hx(lk[1])
		WHITE7 = hx(lk[2])
		TEAL7 = hx(lk[3])
		_head_pal()
		var vs: Image = new_img(fw * 2, fh)
		for k in range(2):
			var c2: Image = new_img(fw, fh)
			draw_hero9(c2, 0, 1 if k == 1 else 0)
			outline_auto(c2, OUTLINE_CHAR)
			vs.blit_rect(c2, Rect2i(0, 0, fw, fh), Vector2i(k * fw, 0))
		save3(vs, String(lk[0]))
	HAIRL7 = sh
	WHITE7 = sw7
	TEAL7 = st
	_head_pal()


# ================================================================== v10: прежние пропорции, всё крупнее x1.25

const H10_TOP: Array = [
	[18, "hL"], [17, "h..H"], [17, "h..H"], [18, "hH"], [19, "H"],
	[11, "hHHHHHHHHHHh"],
	[9, "hHHHHLLLLHHHHHHh"],
	[8, "hHHHLLLLLLLHHHHHHh"],
	[7, "hHHHLLLLHHHHHHHHHHHh"],
	[6, "hHHLLLHHHHHHHHHHHHHHHh"],
	[5, "hHHHHHHHHHHHHHHHHHHHHHHh"],
	[5, "hHHHHHhHHHHHHhHHHHHhHHHh"],
	[4, "hHHHHHhHHHHHHHhHHHHHHhHHHh"],
	[4, "hHHHHhHHHHHHHhHHHHHHHhHHHh"],
]
## Лицо 20 столбцов (строки 14..41): глаза 6x7, брови, румянец
const H10_FACE: Array = [
	"HHHHhHHHHHHhHHHHHhHH",
	"HHHhHHHHHHhHHHHHHhHH",
	"SHHHSHHHHHShHHHHShHS",
	"SShHSSHHHhSSHHHhSShS",
	"SSShSSShHSSSSHhSSSSS",
	"SSSSSSSShSSSSSSSSSSS",
	"SddddSSSSSSSSSSddddS",
	"SSSSSSSSSSSSSSSSSSSS",
	"EEEEEEESSSSSSEEEEEEE",
	"SEIIWWISSSSSSEIIWWIS",
	"SwIIWWISSSSSSwIIWWIS",
	"SwIIIIISSSSSSwIIIIIS",
	"SwIiiiISSSSSSwIiiiIS",
	"SwijjiiSSSSSSwijjiiS",
	"SSeeeeSSSSSSSSeeeeSS",
	"SBBBSSSSSSSSSSSSBBBS",
	"SSSSSSSSSSTSSSSSSSSS",
	"TSSSSSSSSSSSSSSSSSST",
	"TSSSSSSSSMMSSSSSSSST",
	".TSSSSSSSSSSSSSSSST.",
	"..TSSSSSSSSSSSSSST..",
	"...TSSSSSSSSSSSST...",
	"....TTSSSSSSSSTT....",
	"......TTSSSSTT......",
	"........TSST........",
	"........TSST........",
	"........TSST........",
	"........TSST........",
]
## Профиль влево, крупный
const H10_PROFILE: Array = [
	[18, "hL"], [17, "h..H"], [17, "h..H"], [18, "hH"], [19, "H"],
	[11, "hHHHHHHHHHHh"],
	[9, "hHHHHLLLLHHHHHHHh"],
	[8, "hHHHLLLLLLLHHHHHHHh"],
	[7, "hHHHLLLLHHHHHHHHHHHHh"],
	[6, "hHHLLLHHHHHHHHHHHHHHHHh"],
	[6, "hHHHHHHHHHHHHHHHHHHHHHHh"],
	[5, "hHHHHHHHHHHHHHHHHHHHHHHHh"],
	[5, "hHHHHhHHHHHHHHHHHHHHHHHHh"],
	[5, "hHHHhHHHHHHHHHHHHHHHHHHHHh"],
	[6, "hHhHHHHHHHHHHHHHHHHHHHHHHh"],
	[6, "hSHHhHHHHHHHHHHHHHHHHHHHHh"],
	[6, "SShSHHHHHHHHHHHHHHHHHHHHHh"],
	[6, "SSSShHHHHHHHHHHHHHHHHHHHHh"],
	[6, "SSSSShHHHHHHHHHHHHHHHHHHHh"],
	[6, "SSSSSShHHHHHHHHHHHHHHHHHHh"],
	[6, "SddddSShHHHHHHHHHHHHHHHHHh"],
	[6, "SSSSSSSShHHHHHHHHHHHHHHHHh"],
	[5, "SEEEESSSShHHHHHHHHHHHHHHHHh"],
	[5, "SIWWESSSShHHHHHHHHHHHHHHHHh"],
	[5, "SIWWwSSSSShHHHHHHHHHHHHHHHh"],
	[5, "SIIIwSSSSShHHHHHHHHHHHHHHHh"],
	[5, "SiiiwSSSSShHHHHHHHHHHHHHHHh"],
	[5, "SijiSSSSSShHHHHHHHHHHHHHHHh"],
	[5, "SSeeSSSSSShHHHHHHHHHHHHHHh"],
	[5, "SSSSSSSSSShHHHHHHHHHHHHHHh"],
	[4, "SSSSSSBBSSShHHHHHHHHHHHHh"],
	[5, "SSSSSBBSSShHHHHHHHHHHHh"],
	[5, "SMSSSSSSSShHHHHHHHHHh"],
	[5, "SSSSSSSSSShHHHHHHHh"],
	[6, "SSSSSSSSShHHHHHHh"],
	[6, "TSSSSSSSThHHHHh"],
	[7, "TTSSSSSThHHHh"],
	[9, "TTTSSSThHh"],
	[12, "TSSSTHh"],
	[12, "TSSST"],
	[12, "TSSST"],
	[12, "TSSST"],
]


func _rows_from(lst: Array) -> Array:
	var out: Array = []
	for e in lst:
		var ea: Array = e
		out.append(".".repeat(int(ea[0])) + String(ea[1]))
	return out


func head10(im: Image, cx: float, oy: int, profile: bool) -> void:
	var pal: Dictionary = _profile_pal()
	var rows10: Array
	var ox: int
	if profile:
		var all_rows: Array = _rows_from(H10_PROFILE)
		rows10 = []
		for ri in range(all_rows.size()):
			if ri in [16, 18]:
				continue
			rows10.append(all_rows[ri])
		oy += 1
		# макушка в профиле целая (строки купола не вырезаются), шея чуть длиннее —
		# голова на той же высоте, что и в других ракурсах
		for ne in range(1):
			rows10.append(".".repeat(12) + "TSSST")
		ox = int(cx) - 14
	else:
		rows10 = _rows_from(H10_TOP)
		for i in range(H10_FACE.size()):
			var ll: String = "hHHh"
			var lr: String = "hHHh"
			if i < 2:
				ll = "hHHH"
				lr = "HHHh"
			elif i > 20:
				ll = "hHh."
				lr = ".hHh"
			if i > 23:
				ll = "...."
				lr = "...."
			rows10.append("..." + ll + String(H10_FACE[i]) + lr)
		ox = int(cx) - 17
	grid(im, rows10, ox, oy, pal)
	# пряди на массе волос головы
	hair_texture(im, Rect2i(ox, oy, 34, 22 if not profile else 42), oy, profile)


# ================================================================== v14: анатомия ~6 голов, аниме-лицо с острым подбородком
# Макушка y=5, подбородок y=31, шея 32..36, плечи с 37 (b — покачивание)

## Глаза анфас 5x6: [строки, строка с «хвостиком» ресниц у края (-1 — нет)]
const EYES14: Dictionary = {
	"open": [["EEEEE", "EIWWI", "wIWWI", "wIiiI", "wijjI", "SeeeS"], 0],
	"half": [["SSSSS", "EEEEE", "wIWWI", "wIiiI", "wijjI", "SeeeS"], 1],
	"closed": [["SSSSS", "SSSSS", "SSSSS", "EEEEE", "SeeeS", "SSSSS"], 3],
	"happy": [["SSSSS", "SSESS", "SESES", "ESSSE", "SSSSS", "SSSSS"], -1],
	"surprise": [["SEEES", "EwIwE", "wIWIw", "wIIIw", "EwwwE", "SeeeS"], -1],
	"look_l": [["EEEEE", "IWIww", "IWIww", "IiIww", "IjIww", "SeeeS"], 0],
	"look_r": [["EEEEE", "wwIWI", "wwIWI", "wwIiI", "wwIjI", "SeeeS"], 0],
	"sleepy": [["SSSSS", "SSSSS", "EEEEE", "wIiiI", "wijjI", "SeeeS"], 2],
}
## Глаз в профиль 4x6
const EYES_P14: Dictionary = {
	"open": ["EEEE", "IWWE", "IWWw", "IiIw", "ijiS", "SeeS"],
	"half": ["SSSS", "EEEE", "IWWw", "IiIw", "ijiS", "SeeS"],
	"closed": ["SSSS", "SSSS", "SSSS", "EEEE", "SeeS", "SSSS"],
	"happy": ["SSSS", "SEES", "ESSE", "SSSS", "SSSS", "SSSS"],
	"surprise": ["SEEE", "EwIw", "wIWw", "wIIw", "EwwS", "SeeS"],
	"look_l": ["EEEE", "IWWE", "IWWw", "IiIw", "ijiS", "SeeS"],
	"look_r": ["EEEE", "wIWE", "wIWw", "wiIw", "wjiS", "SeeS"],
	"sleepy": ["SSSS", "SSSS", "EEEE", "IiIw", "ijiS", "SeeS"],
}
## Рот 4x3 (анфас и вполоборота)
const MOUTH14: Dictionary = {
	"neutral": ["SSSS", "SMMS", "SSSS"],
	"smile": ["SSSS", "MSSM", "SMMS"],
	"open": ["SSSS", "MOOM", "SMMS"],
	"o": ["SMMS", "MOOM", "SMMS"],
	"frown": ["SMMS", "MSSM", "SSSS"],
	"pout": ["SSSS", "SSMS", "SSSS"],
}
const BROWS14: Dictionary = {
	"normal": ["SddddSSSSSSSSddddS", "SSSSSSSSSSSSSSSSSS"],
	"sad": ["SSSddSSSSSSSSddSSS", "SddSSSSSSSSSSSSddS"],
	"angry": ["SddSSSSSSSSSSSSddS", "SSSddSSSSSSSSddSSS"],
}
const BROWS34_14: Dictionary = {
	"normal": ["SdddSSSSdddddSSSSS", "SSSSSSSSSSSSSSSSSS"],
	"sad": ["SSddSSSSSSddSSSSSS", "SdSSSSSSddSSSSSSSS"],
	"angry": ["SddSSSSSSSSddSSSSS", "SSSdSSSSddSSSSSSSS"],
}
## Какие столбцы лица анфас убрать для вида вполоборота (дальний глаз, щека, часть промежутка)
const FACE_Q_DROP: Array = [1, 3, 7]
const BROWS_P14: Dictionary = {"normal": "dddS", "sad": "SddS", "angry": "ddSS"}


## Лицо 18 столбцов, строки y13..y36 (чёлка, брови, глаза, румянец, нос, рот, острый подбородок, шея).
## q — вполоборота влево: дальний глаз уже, нос и подбородок смещены к дальнему краю.
func _h14_face_rows(e: Array, q: bool) -> Array:
	if q:
		# вполоборота: дальняя (левая) половина лица сжимается — убираем её столбцы,
		# нос, рот и подбородок сами съезжают к дальнему краю
		var src: Array = _h14_face_rows(e, false)
		var outq: Array = []
		for r in src:
			var s: String = String(r)
			var o: String = ""
			for ci in range(s.length()):
				if ci in FACE_Q_DROP:
					continue
				o += s[ci]
			outq.append(o)
		# шея у вполоборота растёт из середины корпуса (рисуется отдельно, neck34), а не из подбородка
		for ni in range(outq.size() - 3, outq.size()):
			outq[ni] = ".".repeat(String(outq[ni]).length())
		return outq
	var rows: Array = []
	rows.append("HHHhHHHHHhHHHHHhHH")
	rows.append("SHHhSHHHhHSHHHhSHS")
	rows.append("SShSSSHhSSSShHSSSS")
	var br: Array = (BROWS34_14 if q else BROWS14)[e[3]]
	rows.append(String(br[0]))
	rows.append(String(br[1]))
	var le: Array = EYES14[e[1]]
	var re: Array = EYES14[e[2]]
	var ls_rows: Array = le[0]
	var rs_rows: Array = re[0]
	for k in range(6):
		var ls: String = String(ls_rows[k])
		var rs: String = String(rs_rows[k])
		var wl: String = "E" if k == int(le[1]) else "S"
		var wr: String = "E" if k == int(re[1]) else "S"
		if q:
			var far4: String = ls[0] + ls[2] + ls[3] + ls[4]
			rows.append(wl + far4 + "SSS" + rs + wr + "SSSS")
		else:
			rows.append(wl + ls + "SSSSSS" + rs + wr)
	var bl: bool = bool(e[5])
	if q:
		rows.append("BBBSSSSSBBBBBSSSSS" if bl else "SBBSSSSSSBBBSSSSSS")
		rows.append("SBSSTSSSSBBBSSSSSS" if bl else "SSSSTSSSSSSSSSSSSS")
	else:
		rows.append("BBBBSSSSSSSSSSBBBB" if bl else "SBBBSSSSSSSSSSBBBS")
		rows.append("SBBSSSSSSTSSSSSBBS" if bl else "SSSSSSSSSTSSSSSSSS")
	var mo: Array = MOUTH14[e[4]]
	if q:
		rows.append("T" + "SSS" + String(mo[0]) + "SSSSSSSSS" + "T")
		rows.append(".T" + "SS" + String(mo[1]) + "SSSSSSSS" + "T.")
		rows.append("..T" + "S" + String(mo[2]) + "SSSSSSS" + "T..")
		rows.append("...T" + "SSSSSSSSS" + "T....")
		rows.append(".....T" + "SSSS" + "T.......")
		rows.append("......TT..........")
	else:
		rows.append("T" + "SSSSSS" + String(mo[0]) + "SSSSSS" + "T")
		rows.append(".T" + "SSSSS" + String(mo[1]) + "SSSSS" + "T.")
		rows.append("..T" + "SSSS" + String(mo[2]) + "SSSS" + "T..")
		rows.append("....T" + "SSSSSSSS" + "T....")
		rows.append("......T" + "SSSS" + "T......")
		rows.append("........TT........")
	for n in range(3):
		rows.append(".......TSST.......")
	return rows


## Купол волос: строки y5..y12 заданной ширины, по центру сетки шириной gw
func _h14_dome(widths: Array, gw: int, shift: int) -> Array:
	var rows: Array = []
	for i in range(widths.size()):
		var w: int = int(widths[i])
		var ind: int = (gw - w) / 2 + shift
		var s: String = ""
		for c in range(w):
			var ch: String = "H"
			if c == 0 or c == w - 1:
				ch = "h"
			elif i >= 1 and i <= 3 and c >= 2 and c <= 2 + (5 if i == 2 else 3):
				ch = "L"
			elif i >= 4 and posmod(c * 3 + i * 2, 11) == 0:
				ch = "h"
			s += ch
		rows.append(".".repeat(maxi(0, ind)) + s)
	return rows


## Вся голова строками (от украшения на макушке до низа шеи).
## view: 0 анфас (сетка 24, ox = cx-12), 1 вполоборота влево (ox = cx-13), 2 профиль влево (ox = cx-11)
func _h14_head_rows(e: Array, view: int) -> Array:
	var rows: Array = [".".repeat(13) + "hL", ".".repeat(12) + "h..H", ".".repeat(12) + "h..H", ".".repeat(13) + "hH", ".".repeat(14) + "H"]
	if view == 2:
		rows.append_array(_h14_dome([10, 14, 16, 18, 19, 20, 20, 21], 22, -1))
		rows.append(".HHhSHHHHHHHHHHHHHHHh")
		rows.append(".SHhSShHHHHHHHHHHHHHh")
		rows.append(".SSSSSShHHHHHHHHHHHHh")
		rows.append("." + String(BROWS_P14[e[3]]) + "SSShHHHHHHHHHHHh")
		rows.append(".SSSSSSShHHHHHHHHHHHh")
		var pe: Array = EYES_P14[e[1]]
		for k in range(6):
			rows.append("." + String(pe[k]) + "SSSShHHHHHHHHHHh")
		rows.append("SSS" + ("BBBB" if bool(e[5]) else "SBBS") + "SSS" + "hHHHHHHHHHh")
		rows.append(".SSSSSSSSShHHHHHHHHHh")
		var mp: Array = MOUTH_P[e[4]]
		rows.append("." + String(mp[0]) + "SSSSSSShHHHHHHHHh")
		rows.append("." + String(mp[1]) + "SSSSSShHHHHHHHh")
		rows.append("." + String(mp[2]) + "SSSSShHHHHHh")
		rows.append("..TSSSSShHHHHh")
		rows.append("..TTSSSThHHh")
		rows.append("...TTTThHh")
		rows.append("........TSTHh")
		for n in range(2):
			rows.append("........TST")
		return rows
	rows.append_array(_h14_dome([8, 14, 18, 20, 22, 23, 24, 24], 24, 0) if view != 1 else _h14_dome([8, 12, 14, 16, 17, 18, 18, 18], 24, -1))
	var face: Array = _h14_face_rows(e, view == 1)
	for j in range(face.size()):
		var ll: String = "..."
		var lr: String = "..."
		if j < 5:
			ll = "hHH"
			lr = "HHh"
		elif j < 15:
			ll = ".hH" if view == 1 else "hHh"
			lr = "hHh"
		elif j < 17:
			ll = "..."
			lr = "..."
		if view == 1:
			# дальняя щека — тонкий край, ближняя сторона — ухо и затылок
			if j < 5:
				ll = "hH"
				lr = "Hh"
			elif j < 15:
				ll = ".h"
				lr = "hh"
			else:
				ll = ".."
				lr = "......"
		rows.append(ll + String(face[j]) + lr)
	return rows


func _h14_ox(cx: float, view: int) -> int:
	return int(cx) - (12 if view == 0 else (11 if view == 1 else 11))


## Голова v14 на кадре: view 0 анфас, 1 вполоборота, 2 профиль
func head14(im: Image, cx: float, oy: int, view: int) -> void:
	var pal: Dictionary = _profile_pal()
	pal["O"] = Color("7a3a44")
	oy += 2
	var ox: int = _h14_ox(cx, view)
	grid(im, _h14_head_rows(EXPRESSIONS[0], view), ox, oy, pal)
	hair_texture(im, Rect2i(ox, oy, 24, 16 if view != 2 else 34), oy, view == 2, 12.0, 9.0, 8.5)


## Прядь по боку головы: выходит из-под головы (верх спрятан за ней), внешний край продолжает линию головы,
## книзу сужается и заканчивается округлым кончиком. side -1 слева, 1 справа.
func side_lock14(im: Image, cx: float, side: int, y0: int, y1: int, outer0: float, w0: float, w1: float, flare: float = 2.4, tuck: float = 1.6) -> void:
	var sd: float = float(side)
	for y in range(y0, y1 + 1):
		var t: float = float(y - y0) / float(maxi(1, y1 - y0))
		# контур плавно расходится от головы к плечам (как колокол), к концу мягко заходит внутрь
		var outer: float = outer0 + flare * smoothstep(0.0, 0.5, t) - tuck * smoothstep(0.55, 1.0, t) + sin(y * 0.34 + sd) * (0.35 + 0.9 * t)
		var wdt: float = lerpf(w0, w1, t) * (1.0 - smoothstep(0.8, 1.0, t))
		if wdt < 0.6:
			continue
		var xa: float = cx + sd * (outer - wdt)
		var xb: float = cx + sd * outer
		var lo: float = minf(xa, xb)
		var hi: float = maxf(xa, xb)
		for x in range(int(floor(lo + 0.5)), int(floor(hi + 0.5))):
			var u: float = (x + 0.5 - lo) / maxf(1.0, hi - lo)
			if side < 0:
				u = 1.0 - u
			var ti: int = 5 if u > 0.65 else (4 if u > 0.3 else 3)
			if side > 0:
				ti -= 1
			px(im, x, y, HAIRL7[clampi(ti, 0, 6)])


## Затылок: верх купола теми же прядями, что и масса волос ниже — без шва между ними
func hair_dome14(im: Image, cx: float, cy: float, rx: float, ry: float, y_end: int, tb: int) -> void:
	for y in range(int(floor(cy - ry)), y_end + 1):
		var dy: float = (y + 0.5 - cy) / ry
		if absf(dy) >= 1.0:
			continue
		var hw: float = rx * sqrt(1.0 - dy * dy)
		for x in range(int(floor(cx - hw + 0.5)), int(floor(cx + hw + 0.5))):
			var u: float = (x + 0.5 - (cx - hw)) / maxf(1.0, 2.0 * hw)
			var ti: int = tb + 1 if u < 0.3 else (tb if u < 0.72 else tb - 1)
			if posmod(x + int(round(sin(y * 0.45) * 1.5)), 3) == 0:
				ti -= 1
			if dy < -0.55 and u < 0.62:
				ti += 1
			px(im, x, y, HAIRL7[clampi(ti, 0, 6)])


## Волосы спереди (две «шторки» по бокам лица). Растут из головы: по макушке идут по её кругу,
## от висков висят прямо вниз под своим весом (чуть ложатся на плечи), концы округлые.
## Рисуются ДО головы — голова закрывает их верх. ol/orr — ширина от центра слева/справа.
func hair_front14(im: Image, cx: float, b: int, sway: float, ol: float, orr: float, y_end: int, taper: float = 0.0, in_l: Array = [], in_r: Array = [], flare: float = 0.8) -> void:
	if HAIR_CUT > 0 and y_end > HAIR_CUT:
		y_end = HAIR_CUT - 4
	for side in [-1, 1]:
		var sd: float = float(side)
		var so: float = ol if side < 0 else orr
		for yy in range(12, y_end + 1):
			var y: int = yy + b
			# внешний край: по кругу головы до виска, ниже — отвесно вниз, чуть шире на плечах
			var outer: float
			if yy < 17:
				var q: float = (17.0 - float(yy)) / 12.6
				outer = so * sqrt(maxf(0.0, 1.0 - q * q))
			else:
				outer = so + flare * smoothstep(24.0, 40.0, float(yy))
			var inner: float = 6.5 if yy < 31 else 7.4
			# своя внутренняя кромка (вполоборота): [до строки, внутр.1, внутр.2]
			var ins: Array = in_l if side < 0 else in_r
			if ins.size() == 3:
				inner = float(ins[1]) if yy < int(ins[0]) else float(ins[2])
			elif ins.size() == 5:
				inner = float(ins[1]) if yy < int(ins[0]) else (float(ins[2]) if yy < int(ins[3]) else float(ins[4]))
			# ветер: качаются только низы прядей, верх у головы неподвижен
			var k: float = clampf(float(yy - 30) / float(maxi(1, y_end - 30)), 0.0, 1.0)
			# прядь сужается книзу к острому кончику (не квадратный срез)
			if taper > 0.0:
				inner += (outer - inner - 1.4) * taper * smoothstep(0.25, 1.0, k)
				outer -= 1.2 * taper * smoothstep(0.5, 1.0, k)
			if outer - inner < 1.0:
				continue
			var shift: float = sway * k * k
			var xa: float = cx + shift + sd * inner
			var xb: float = cx + shift + sd * outer
			var lo: float = minf(xa, xb)
			var hi: float = maxf(xa, xb)
			for x in range(int(floor(lo + 0.5)), int(floor(hi + 0.5))):
				var u: float = (x + 0.5 - lo) / maxf(1.0, hi - lo)
				if side > 0:
					u = 1.0 - u
				# u: 0 — внешний край, 1 — у лица
				# округлые концы: середина пряди длиннее, края короче
				var end_y: float = float(y_end) - pow(absf(u - 0.5) * 2.0, 2.0) * 6.0 + (h01(x, 5, 9) - 0.5) * 2.0
				if float(yy) > end_y:
					continue
				var ti: int = 4 if u < 0.25 else (5 if u < 0.7 else 4)
				if side > 0:
					ti -= 1
				if posmod(x, 3) == 0 and yy > 18:
					ti -= 1
				if float(yy) > end_y - 2.0:
					ti -= 1
				px(im, x, y, HAIRL7[clampi(ti, 0, 6)])


## Масса волос v14: гладкий силуэт (без «колбасок»), книзу сужается, низ закруглён, концы прядей разной длины
func hair_mass14(im: Image, cx: float, y0: int, y1: int, hw0: float, hw1: float, sway: float, tb: int) -> void:
	if HAIR_CUT > 0 and y1 > HAIR_CUT:
		y1 = HAIR_CUT
	var span: float = float(maxi(1, y1 - y0))
	for y in range(y0, y1 + 1):
		var t: float = float(y - y0) / span
		var widen: float = smoothstep(0.0, 0.4, t)
		var taper: float = 1.0 - 0.3 * smoothstep(0.5, 1.0, t)
		var hw: float = lerpf(hw0, hw1, widen) * taper
		var c: float = cx + sway * t * t
		for x in range(int(floor(c - hw)), int(ceil(c + hw))):
			var d: float = absf(x + 0.5 - c) / maxf(1.0, hw)
			var end_y: float = float(y1) - pow(d, 2.0) * 0.2 * span + (h01(x, 3, 7) - 0.5) * 3.0
			if float(y) > end_y:
				continue
			var u: float = (x + 0.5 - (c - hw)) / (2.0 * hw)
			var ti: int = tb + 1 if u < 0.3 else (tb if u < 0.72 else tb - 1)
			if posmod(x + int(round(sin(y * 0.45) * 1.5)), 3) == 0:
				ti -= 1
			if float(y) > end_y - 2.0:
				ti -= 1
			px(im, x, y, HAIRL7[clampi(ti, 0, 6)])


## Фактура волос: пряди по волне и блестящая дуга (только на пикселях основного тона)
func hair_texture(im: Image, r: Rect2i, oy: int, profile: bool, cxo: float = 17.0, arc_y: float = 11.0, arc_rx: float = 11.0) -> void:
	var base: Color = HAIRL7[4]
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			if x < 0 or y < 0 or x >= im.get_width() or y >= im.get_height():
				continue
			if not im.get_pixel(x, y).is_equal_approx(base):
				continue
			if posmod(x + int(round(sin(y * 0.35) * 1.5)), 4) == 0 and y > oy + int(arc_y) - 2:
				px(im, x, y, HAIRL7[3])
			var arc: float = absf(Vector2((x - (r.position.x + cxo)) / arc_rx, (y - oy - arc_y) / 4.0).length() - 1.0)
			if arc < 0.16 and y < oy + int(arc_y) + 2:
				px(im, x, y, HAIRL7[5])


## Волосы сбоку: слои, пряди по волне, блики, прядь перед плечом, завитки на концах
func side_hair10(im: Image, cx: float, b: int, sw: float) -> void:
	var top: int = 12 + b
	var bot: int = 80 + b
	for y in range(top, bot + 1):
		var t: float = float(y - top) / float(bot - top)
		var front: float = cx - 1.0 + t * 1.5
		# задний край — отвесно вниз от самой широкой точки затылка; ветер чуть качает только низ
		var back: float = cx + 6.5 + sw * 1.5 * t * t
		for x in range(int(floor(front)), int(ceil(back))):
			var u: float = (x + 0.5 - front) / maxf(1.0, back - front)
			var k: int = int(floor((x + 0.5 - front + sin(y * 0.3) * 1.6) / 3.0))
			var end_y: float = bot - 6.0 + sin(k * 1.7) * 4.0 + h01(k, 3, 11) * 4.0
			if y > end_y:
				continue
			var ti: int = 5 if u < 0.25 else (4 if u < 0.65 else 3)
			var strand: float = fmod(x + 0.5 - front + sin(y * 0.3) * 1.6, 3.0)
			if strand < 0.9:
				ti -= 1
			# блестящие дуги
			for band in []:
				var by: float = band + b + sin(x * 0.6) * 1.0 - u * 3.0
				if absf(y - by) < 1.0 and ti >= 3:
					ti = 6 if u < 0.6 else 5
			# завиток на конце пряди
			if y > end_y - 3.0:
				ti = 3 if strand < 1.5 else 4
			if t > 0.85 and u > 0.8:
				ti -= 1
			px(im, x, y, HAIRL7[clampi(ti, 0, 6)])
	# прядь перед плечом
	for y2 in range(20 + b, 58 + b):
		var t2: float = float(y2 - 20 - b) / 38.0
		var xc: float = cx - 2.0 + sin(y2 * 0.45) * 1.0 + t2 * 1.0
		for x2 in range(int(floor(xc - 1.4 + t2)), int(ceil(xc + 1.4 - t2))):
			px(im, x2, y2, HAIRL7[5] if x2 < xc else HAIRL7[3])


const LEG10_OUT: Array = [Vector2(0.0, 13.0), Vector2(0.14, 12.6), Vector2(0.32, 11.0), Vector2(0.46, 8.6), Vector2(0.62, 9.6), Vector2(0.80, 8.0), Vector2(0.96, 6.4), Vector2(1.0, 6.2)]
const LEG10_IN: Array = [Vector2(0.0, 0.0), Vector2(0.22, 0.3), Vector2(0.38, 0.9), Vector2(0.47, 0.6), Vector2(0.58, 1.0), Vector2(0.80, 1.5), Vector2(1.0, 1.7)]


func leg_front10(im: Image, cx: float, side: int, top: int, knee: int, bot: int, hem: int) -> void:
	if MERMAID:
		mer_tail_once(im)
		return
	for y in range(top, bot + 1):
		var s: float
		if y <= knee:
			s = 0.46 * float(y - top) / float(maxi(1, knee - top))
		else:
			s = 0.46 + 0.54 * float(y - knee) / float(maxi(1, bot - knee))
		var o: float = curve_at(LEG10_OUT, s)
		# между ногами всегда щель от самого подола до ботинок — посередине пусто
		var i0: float = maxf(curve_at(LEG10_IN, s), 1.6)
		var x0: float = minf(cx + float(side) * i0, cx + float(side) * o)
		var x1: float = maxf(cx + float(side) * i0, cx + float(side) * o)
		for x in range(int(floor(x0 + 0.5)), int(floor(x1 + 0.5))):
			var u: float = (absf(x + 0.5 - cx) - i0) / maxf(0.5, o - i0)
			var hl: float = 0.6 if side < 0 else 0.42
			var ti: int = 4
			if u < 0.1:
				ti = 2
			elif u < 0.24:
				ti = 3
			elif absf(u - hl) < 0.15:
				ti = 5
			elif u > 0.9:
				ti = 4 if side < 0 else 2
			elif u > 0.76 and side > 0:
				ti = 3
			if s > 0.42 and s < 0.455 and absf(u - 0.5) < 0.2:
				ti = 5
			elif s > 0.475 and s < 0.5 and absf(u - 0.5) < 0.26:
				ti = 3
			if s > 0.52 and s < 0.92 and absf(u - (hl - 0.05)) < 0.07:
				ti = 6
			if y < hem + 2:
				ti -= 2
			elif y < hem + 5:
				ti -= 1
			px(im, x, y, SKINL7[clampi(ti, 0, 6)])


## Нога сбоку: толстое бедро, колено чуть вперёд, икра сзади, нормальная щиколотка
func leg_side10(im: Image, hip: Vector2, foot: Vector2, knee: int, hem: int, far: bool, knee_dx: float = 0.0) -> void:
	if MERMAID:
		mer_tail_once(im)
		return
	var top: int = int(hip.y)
	var bot: int = int(foot.y)
	var kx: float = lerpf(hip.x, foot.x, 0.5) - 1.5 + knee_dx
	var FR: Array = [Vector2(0, 8.4), Vector2(0.25, 7.6), Vector2(0.44, 5.0), Vector2(0.47, 5.4), Vector2(0.55, 4.6), Vector2(0.8, 4.0), Vector2(1.0, 3.5)]
	var BK: Array = [Vector2(0, 9.2), Vector2(0.2, 8.0), Vector2(0.44, 4.6), Vector2(0.62, 6.8), Vector2(0.82, 4.4), Vector2(1.0, 3.2)]
	for y in range(top, bot + 1):
		var s: float
		var c: float
		if y <= knee:
			var tt: float = float(y - top) / float(maxi(1, knee - top))
			s = 0.46 * tt
			c = lerpf(hip.x, kx, tt)
		else:
			var tt2: float = float(y - knee) / float(maxi(1, bot - knee))
			s = 0.46 + 0.54 * tt2
			c = lerpf(kx, foot.x, tt2)
		var fr: float = curve_at(FR, s)
		var bk: float = curve_at(BK, s)
		for x in range(int(floor(c - fr + 0.5)), int(floor(c + bk + 0.5))):
			var u: float = (x + 0.5 - (c - fr)) / (fr + bk)
			var ti: int = 4 if u < 0.12 else (5 if u < 0.38 else (4 if u < 0.7 else (3 if u < 0.9 else 2)))
			if s > 0.43 and s < 0.48 and u < 0.3:
				ti = 6
			if s > 0.55 and s < 0.85 and u > 0.6 and u < 0.8:
				ti = 3
			if far:
				ti -= 1
			if y < hem + 2:
				ti -= 2
			elif y < hem + 5:
				ti -= 1
			px(im, x, y, SKINL7[clampi(ti, 0, 6)])


## Лиф спереди. Тело — рельеф (цилиндр + грудь «каплей»), свет по наклону поверхности.
## bounce — смещение груди (физика), tq — поворот корпуса влево (0 анфас, 1 вполоборота):
## дальняя (левая) сторона сжимается, грудь у дальнего края выходит за силуэт, ближняя шире.
func torso10_front(im: Image, cx0: float, b: int, back: bool, bounce: int = 0, tq: float = 0.0) -> void:
	var y0: int = 42 + b
	var cx: float = cx0 - 1.6 * tq
	var by: float = 16.5 + float(bounce)
	var keys: Array = [Vector2(0, 5.4), Vector2(2, 7.8), Vector2(5, 10.0), Vector2(9, 10.8), Vector2(by - 1.0, 13.0), Vector2(by + 2.0, 13.4), Vector2(by + 4.6, 11.0), Vector2(by + 6.8, 8.8), Vector2(26, 6.4), Vector2(29, 6.9)]
	if back:
		keys = [Vector2(0, 5.4), Vector2(2, 7.8), Vector2(5, 10.2), Vector2(12, 10.4), Vector2(26, 6.4), Vector2(29, 6.9)]
	var bl: float = cx - 5.6 - 1.4 * tq     # центр дальней (левой) груди
	var br: float = cx + 5.6 - 2.2 * tq     # центр ближней (правой)
	var L: Vector3 = Vector3(-0.55, -0.55, 0.63).normalized()
	for o in range(30):
		var y: int = y0 + o
		var hw: float = curve_at_abs(keys, float(o))
		var hl: float = hw * (1.0 - 0.18 * tq)
		var hr: float = hw * (1.0 + 0.04 * tq)
		if not back and tq > 0.0 and absf(float(o) - by) < 4.5:
			hl += 1.4 * tq * (1.0 - absf(float(o) - by) / 4.5)
		for x in range(int(floor(cx - hl + 0.5)), int(floor(cx + hr + 0.5))):
			var u: float = (x + 0.5 - (cx - hl)) / (hl + hr)
			var ti: int
			if back:
				ti = 6 if u < 0.22 else (5 if u < 0.62 else (4 if u < 0.86 else 3))
			else:
				var hx0: float = _body_h(cx, y0, by, hl, hr, bl, br, tq, x, y + 0.5)
				var hx1: float = _body_h(cx, y0, by, hl, hr, bl, br, tq, x + 1.0, y + 0.5)
				var hy0: float = _body_h(cx, y0, by, hl, hr, bl, br, tq, x + 0.5, y)
				var hy1: float = _body_h(cx, y0, by, hl, hr, bl, br, tq, x + 0.5, y + 1.0)
				var nrm: Vector3 = Vector3(-(hx1 - hx0), -(hy1 - hy0), 1.0).normalized()
				var l: float = nrm.dot(L)
				ti = 6 if l > 0.86 else (5 if l > 0.68 else (4 if l > 0.48 else (3 if l > 0.24 else 2)))
				for bc in [bl, br]:
					var dx: float = (x + 0.5 - float(bc)) / 6.6
					var dy: float = y + 0.5 - (y0 + by)
					if dy > 3.8 and dy < 6.2 and absf(dx) < 0.85 - (dy - 3.8) * 0.12:
						ti = mini(ti, 4)
			if o > 22 and (u < 0.12 or u > 0.88):
				ti -= 1
			if tq > 0.0 and u < 0.1:
				ti -= 1
			px(im, x, y, WHITE7[clampi(ti, 0, 6)])
	if back:
		return
	# V-вырез: кожа, ключицы, ямочка, бирюзовая кайма и бант внизу
	for o2 in range(7):
		var half: float = 5.2 - o2 * 0.82
		if half < 0.4:
			break
		var hl2: float = half * (1.0 - 0.25 * tq)
		var hr2: float = half * (1.0 + 0.05 * tq)
		for x2 in range(int(floor(cx - hl2 + 0.5)), int(floor(cx + hr2 + 0.5))):
			var dxx: float = absf(x2 + 0.5 - cx)
			var ts: int = 4 if x2 < int(cx) else 3
			if o2 == 0 and dxx < 1.0:
				ts = 3
			if (o2 == 1 and dxx > 1.2 and dxx < 3.2) or (o2 == 2 and dxx >= 3.2 and dxx < 4.6):
				ts = 2 if x2 >= int(cx) else 3
			if o2 == 0 and dxx > 1.0:
				ts = 5 if x2 < int(cx) else 4
			px(im, x2, y0 + o2, SKINL7[ts])
		px(im, int(floor(cx - hl2 + 0.5)) - 1, y0 + o2, TEAL7[3])
		px(im, int(floor(cx + hr2 + 0.5)), y0 + o2, TEAL7[2])
	for p in [Vector2i(-2, 6), Vector2i(-1, 7), Vector2i(1, 7), Vector2i(2, 6), Vector2i(0, 7), Vector2i(-1, 8), Vector2i(1, 8)]:
		var pv: Vector2i = p
		px(im, int(cx) + pv.x, y0 + pv.y, TEAL7[5] if pv.x < 0 else TEAL7[3])


func torso14_front(im: Image, cx0: float, b: int, back: bool, bounce: int = 0, tq: float = 0.0) -> void:
	var y0: int = 37 + b
	var cx: float = cx0 - 1.6 * tq
	var by: float = 16.0 + float(bounce)
	var keys: Array = [Vector2(0, 5.6), Vector2(2, 8.6), Vector2(4, 10.4), Vector2(7, 10.2), Vector2(by - 1.0, 11.2), Vector2(by + 2.0, 11.6), Vector2(by + 4.2, 9.8), Vector2(by + 6.2, 8.6), Vector2(22, 7.6), Vector2(27, 8.4)]
	if back:
		keys = [Vector2(0, 5.6), Vector2(2, 8.6), Vector2(4, 10.4), Vector2(9, 10.0), Vector2(22, 7.6), Vector2(27, 8.4)]
	var bl: float = cx - 5.0 - 1.4 * tq     # центр дальней (левой) груди
	var br: float = cx + 5.0 - 2.2 * tq     # центр ближней (правой)
	var L: Vector3 = Vector3(-0.55, -0.55, 0.63).normalized()
	for o in range(28):
		var y: int = y0 + o
		var hw: float = curve_at_abs(keys, float(o))
		var hl: float = hw * (1.0 - 0.18 * tq)
		var hr: float = hw * (1.0 + 0.04 * tq)
		if not back and tq > 0.0 and absf(float(o) - by) < 4.5:
			hl += 1.4 * tq * (1.0 - absf(float(o) - by) / 4.5)
		for x in range(int(floor(cx - hl + 0.5)), int(floor(cx + hr + 0.5))):
			var u: float = (x + 0.5 - (cx - hl)) / (hl + hr)
			var ti: int
			if back:
				ti = 6 if u < 0.22 else (5 if u < 0.62 else (4 if u < 0.86 else 3))
			else:
				var hx0: float = _body_h14(cx, y0, by, hl, hr, bl, br, tq, x, y + 0.5)
				var hx1: float = _body_h14(cx, y0, by, hl, hr, bl, br, tq, x + 1.0, y + 0.5)
				var hy0: float = _body_h14(cx, y0, by, hl, hr, bl, br, tq, x + 0.5, y)
				var hy1: float = _body_h14(cx, y0, by, hl, hr, bl, br, tq, x + 0.5, y + 1.0)
				var nrm: Vector3 = Vector3(-(hx1 - hx0), -(hy1 - hy0), 1.0).normalized()
				var l: float = nrm.dot(L)
				ti = 6 if l > 0.86 else (5 if l > 0.68 else (4 if l > 0.48 else (3 if l > 0.24 else 2)))
				for bc in [bl, br]:
					var dx: float = (x + 0.5 - float(bc)) / 5.8
					var dy: float = y + 0.5 - (y0 + by)
					if dy > 3.4 and dy < 5.6 and absf(dx) < 0.85 - (dy - 3.4) * 0.12:
						ti = mini(ti, 4)
			if o > 20 and (u < 0.12 or u > 0.88):
				ti -= 1
			if tq > 0.0 and u < 0.1:
				ti -= 1
			px(im, x, y, WHITE7[clampi(ti, 0, 6)])
	if back:
		return
	# V-вырез: кожа, ключицы, ямочка, бирюзовая кайма и бант внизу
	for o2 in range(5):
		var half: float = 5.0 - o2 * 1.25
		if half < 0.4:
			break
		var hl2: float = half * (1.0 - 0.25 * tq)
		var hr2: float = half * (1.0 + 0.05 * tq)
		for x2 in range(int(floor(cx - hl2 + 0.5)), int(floor(cx + hr2 + 0.5))):
			var dxx: float = absf(x2 + 0.5 - cx)
			var ts: int = 4 if x2 < int(cx) else 3
			if o2 == 0 and dxx < 1.0:
				ts = 3
			if (o2 == 1 and dxx > 1.2 and dxx < 3.2) or (o2 == 2 and dxx >= 3.2 and dxx < 4.6):
				ts = 2 if x2 >= int(cx) else 3
			if o2 == 0 and dxx > 1.0:
				ts = 5 if x2 < int(cx) else 4
			px(im, x2, y0 + o2, SKINL7[ts])
	for p in [Vector2i(-2, 3), Vector2i(-1, 4), Vector2i(1, 4), Vector2i(2, 3), Vector2i(0, 4), Vector2i(-1, 5), Vector2i(1, 5)]:
		var pv: Vector2i = p
		px(im, int(cx) + pv.x, y0 + pv.y, TEAL7[5] if pv.x < 0 else TEAL7[3])


## Передняя линия корпуса в профиле: плечи, грудь — ровный круг, талия. o — строка от плеч (0..27)
func _chest_profile(bo: float) -> Array:
	var keys: Array = []
	var c: float = 16.0 + bo
	var ru: float = 10.5    # сверху грудь плавно переходит в грудную клетку
	var rl: float = 3.6    # снизу — округлое «висячее» основание
	for o in range(28):
		var base: float
		if o < 5:
			base = lerpf(2.4, 5.0, float(o) / 5.0)
		elif o < 18:
			base = 5.0
		elif o < 23:
			base = lerpf(5.0, 4.4, float(o - 18) / 5.0)
		else:
			base = lerpf(4.4, 5.4, float(o - 23) / 4.0)
		var d: float = (float(o) - c) / (ru if float(o) < c else rl)
		var bulge: float = 6.4 * sqrt(maxf(0.0, 1.0 - d * d))
		keys.append(Vector2(float(o), base + bulge))
	return keys


## Высота поверхности лифа v14: цилиндр тела + грудь (пропорционально новому телу)
func _body_h14(cx: float, y0: int, by: float, hl: float, hr: float, bl: float, br: float, tq: float, x: float, y: float) -> float:
	var u: float = clampf((x - cx) / maxf(1.0, hr if x > cx else hl), -1.0, 1.0)
	var h: float = sqrt(maxf(0.0, 1.0 - u * u)) * 5.0
	var best: float = 0.0
	var centers: Array = [[bl, 6.0 * (1.0 - 0.2 * tq)], [br, 6.0 * (1.0 + 0.05 * tq)]]
	for cc in centers:
		var dx: float = (x - float(cc[0])) / float(cc[1])
		var dy: float = y - (y0 + by)
		var v: float = dy / 10.0 if dy < 0.0 else dy / 3.2
		var r2: float = dx * dx + v * v
		if r2 < 1.0:
			best = maxf(best, 6.4 * pow(1.0 - r2, 1.25))
	return h + best


## Высота поверхности лифа: цилиндр тела + две «капли» груди (крупнее)
func _body_h(cx: float, y0: int, by: float, hl: float, hr: float, bl: float, br: float, tq: float, x: float, y: float) -> float:
	var u: float = clampf((x - cx) / maxf(1.0, hr if x > cx else hl), -1.0, 1.0)
	var h: float = sqrt(maxf(0.0, 1.0 - u * u)) * 5.0
	var best: float = 0.0
	var centers: Array = [[bl, 6.8 * (1.0 - 0.2 * tq)], [br, 6.8 * (1.0 + 0.05 * tq)]]
	for cc in centers:
		var dx: float = (x - float(cc[0])) / float(cc[1])
		var dy: float = y - (y0 + by)
		var v: float = dy / 9.5 if dy < 0.0 else dy / 4.4
		var r2: float = dx * dx + v * v
		if r2 < 1.0:
			best = maxf(best, 7.0 * pow(1.0 - r2, 1.25))
	return h + best


## Шея: шире, тень под подбородком и по бокам
func neck10(im: Image, cx: float, b: int) -> void:
	for y in range(37 + b, 43 + b):
		var hw: float = 2.6 + float(y - 37 - b) * 0.25
		for x in range(int(floor(cx - hw + 0.5)), int(floor(cx + hw + 0.5))):
			var u: float = (x + 0.5 - (cx - hw)) / (2.0 * hw)
			var ti: int = 4 if u < 0.3 else (4 if u < 0.7 else 3)
			if u < 0.18:
				ti = 3
			if y < 39 + b:
				ti = 3
			px(im, x, y, SKINL7[ti])


func arm10(im: Image, sh: Vector2, hand: Vector2, tb: int) -> void:
	var n: int = int(sh.distance_to(hand)) + 1
	for i in range(n):
		var t: float = float(i) / float(n)
		var p: Vector2 = sh.lerp(hand, t)
		var hw: float = lerpf(2.4, 3.2, t)
		var wrist: bool = t > 0.86
		if wrist:
			hw = 1.9
		for y in range(int(p.y) - 1, int(p.y) + 1):
			for x in range(int(floor(p.x - hw)), int(ceil(p.x + hw))):
				var u: float = (x + 0.5 - (p.x - hw)) / (2.0 * hw)
				var ti: int = tb + 1 if u < 0.3 else (tb if u < 0.7 else tb - 1)
				var c: Color = SKINL7[clampi(ti, 0, 6)] if (wrist or UNDER) else _sleeve()[clampi(ti, 0, 6)]
				if not wrist and not UNDER and absf(u - 0.5) < 0.22:
					c = c.lerp(SKINL7[4], 0.35)
				px(im, x, y, c)
	blob(im, sh.x, sh.y + 2.0, 3.0, 3.4, _sleeve(), tb + 1)
	var cuff: Vector2 = sh.lerp(hand, 0.86)
	for x2 in range(int(cuff.x) - 4, int(cuff.x) + 4 if not UNDER else int(cuff.x) - 4):
		px(im, x2, int(cuff.y), TEAL7[4])
		px(im, x2, int(cuff.y) + 1, WHITE7[5])
	blob(im, hand.x, hand.y + 2.0, 2.7, 3.8, SKINL7, 4)
	px(im, int(hand.x) - 1, int(hand.y) + 5, SKINL7[3])
	px(im, int(hand.x), int(hand.y) + 5, SKINL7[2])


func cape10(im: Image, cx: float, y0: int, y1: int, sway: float, open: bool, inner: bool, neck: bool = false) -> void:
	if NO_CAPE:
		return
	for y in range(y0, y1 + 1):
		var t: float = float(y - y0) / float(y1 - y0)
		var c: float = cx + sway * t * t * 2.0
		var outer: float = lerpf(10.5, 25.0, pow(t, 0.8)) + sin(y * 0.3) * 0.9 * t
		var opening: float = lerpf(7.0, 12.5, t) if open else -1.0
		if neck:
			# плащ от шеи: сверху ложится на плечи (круглый ворот), книзу расходится
			outer = lerpf(14.0, 25.0, pow(t, 0.9)) + sin(y * 0.3) * 0.9 * t
			outer = minf(outer, 5.0 + float(y - y0) * 1.8)
			if open:
				opening = 13.8
		for x in range(int(floor(c - outer)), int(ceil(c + outer))):
			var dx: float = x + 0.5 - c
			var hem_y: float = y1 - 2.0 + sin(dx * 0.45) * 1.6 + absf(dx) * 0.12
			if y > hem_y:
				continue
			if inner:
				px(im, x, y, TEAL7[1] if absf(dx) < outer - 2.0 else TEAL7[2])
				continue
			if absf(dx) < opening:
				continue
			var u: float = (dx + outer) / (2.0 * outer)
			var ti: int = 5 if u < 0.2 else (4 if u < 0.5 else (3 if u < 0.85 else 2))
			var fold: float = sin(dx / outer * 11.0 + t * 1.5)
			if t > 0.1 and fold > 0.8:
				ti -= 1
			elif t > 0.1 and fold < -0.88:
				ti += 1
			if open and absf(dx) < opening + 1.4:
				ti = 6 if dx < 0.0 else 5
			if y > hem_y - 1.0:
				ti -= 2
			if h01(x / 3, y / 3, 17) > 0.93 and ti > 2:
				ti -= 1
			px(im, x, y, TEAL7[clampi(ti, 0, 6)])


func boot10(im: Image, cx: float, top: int, toe: int) -> void:
	if MERMAID:
		return
	if BAREFOOT:
		# босая ступня: щиколотка и пальцы
		for y in range(top + 6, top + 15):
			var t2: float = float(y - top - 6) / 8.0
			var hw2: float = 2.6 if t2 < 0.5 else 2.6 + (t2 - 0.5) * 3.0
			var sx2: float = cx + float(toe) * maxf(0.0, t2 - 0.5) * 4.0
			for x in range(int(floor(sx2 - hw2 + 0.5)), int(floor(sx2 + hw2 + 0.5))):
				var u2: float = (x + 0.5 - (sx2 - hw2)) / (2.0 * hw2)
				var ti2: int = 4 if u2 < 0.35 else (3 if u2 < 0.75 else 2)
				if y == top + 14:
					ti2 = 1
				px(im, x, y, SKINL7[ti2])
		return
	for y in range(top, top + 15):
		var t: float = float(y - top) / 14.0
		var hw: float = 4.6 if t < 0.62 else 4.6 + (t - 0.62) * 3.2
		var sx: float = cx + float(toe) * (t - 0.6) * 4.5 if t > 0.6 else cx
		for x in range(int(floor(sx - hw + 0.5)), int(floor(sx + hw + 0.5))):
			var u: float = (x + 0.5 - (sx - hw)) / (2.0 * hw)
			var ti: int = 5 if u < 0.25 else (4 if u < 0.6 else (3 if u < 0.85 else 2))
			if y <= top + 1:
				ti = 5 if u < 0.6 else 4
			if y >= top + 13:
				ti = 0 if y == top + 14 else 1
			if y > top + 2 and y < top + 10 and posmod(y - top, 2) == 0 and absf(u - 0.5) < 0.15:
				ti = 6
			px(im, x, y, LEATH7[clampi(ti, 0, 6)])


func draw_hero10(im: Image, dir: int, f: int) -> void:
	# 24-27 — бег: те же 4 фазы шага, но с подлётом и размахом
	if f >= 24 and f <= 27:
		RUN = 1.0
		draw_hero10(im, dir, f - 24)
		RUN = 0.0
		return
	# 10-18 — на колене (глажка): только вид сбоку, в остальных ракурсах — стойка
	if f >= 10:
		if dir == 2:
			_hero_kneel(im, f)
		else:
			draw_hero10(im, dir, 4)
		return
	# кадры: 0-3 ходьба, 4 стойка, 5 стойка-вдох
	# кадры: 0-3 ходьба, 4-7 стойка: ветер колышет накидку, волосы, подол; 6-7 — вдох
	var b: int = -1 if (f == 1 or f == 3 or f == 6 or f == 7) else 0
	var wind: float = [0.0, 0.7, 1.4, 0.7][f - 4] if (f >= 4 and f <= 7) else 0.0
	# 8-9 — глажка: чуть присела, рука тянется вперёд-вниз и гладит
	if f >= 8:
		b = 4
	var sw: float = 1.0 if f == 0 else (-1.0 if f == 2 else 0.0)
	var bounce: int = 1 if (f == 1 or f == 3) else 0
	var run: bool = RUN > 0.0 and f <= 3
	if run:
		# толчок — ниже, полёт — выше; плащ и волосы отлетают назад от встречного воздуха
		b = 1 if (f == 0 or f == 2) else -2
		sw = [1.0, 0.4, -1.0, -0.4][f]
		wind = 2.8 if dir == 2 else (1.5 if dir >= 4 else 0.8)
	# волосы при ходьбе: кончики раскачиваются в такт шагам, сбоку волосы чуть отстают назад
	var walk: bool = f <= 3
	var hsw: float = (1.4 + 1.8 * sw) if walk else 0.0
	var hph: float = float(f) * 1.57 if walk else 0.0
	if BOUNCE_OVR != -99:
		bounce = BOUNCE_OVR
	var cx: float = 40.0
	var hs: float = 2.0 * sw
	var knee: int = 117
	var hem: int = (78 if UNDER else 96) + b
	var foot_y: int = 142
	if dir == 4:
		_hero34_front(im, f, b, sw, wind, bounce)
		return
	if dir == 5:
		_hero34_back(im, f, b, sw, wind)
		return
	if dir == 0 or dir == 1:
		if dir == 0:
			hair_mass(im, cx, 14 + b, 84 + b, 11.4, 11.0, sw * 1.4 + wind * 0.5, 3, true, wind * 1.6 + hph)
		if dir == 0:
			# подкладка плаща за спиной (от шеи)
			cape10(im, cx, 38 + b, 157, -sw * 2.2 + wind * 1.3, false, true, true)
		var ll: int = 3 if f == 2 else 0
		var lr: int = 3 if f == 0 else 0
		if run:
			ll = [0, 2, 8, 7][f]
			lr = [8, 7, 0, 2][f]
		if dir == 0 or NO_CAPE:
			leg_front10(im, cx, -1, 76 + b, knee, foot_y - ll, hem)
			leg_front10(im, cx, 1, 76 + b, knee, foot_y - lr, hem)
		boot10(im, cx - 4.6, foot_y - 1 - ll, -1)
		boot10(im, cx + 4.6, foot_y - 1 - lr, 1)
		skirt8(im, cx, 64 + b, hem, 8.4, 13.8, sw * 1.0 + wind * 0.6)
		if dir == 0:
			# края плаща по бокам (спереди он распахнут)
			cape10(im, cx, 38 + b, 157, -sw * 2.2 + wind * 1.3, true, false, true)
		torso14_front(im, cx, b, dir == 1, bounce)
		belt8(im, cx, 61 + b, 7.6)
		if dir == 1:
			blob(im, cx - 3.2, 65.0 + b, 3.0, 2.0, WHITE7, 5)
			blob(im, cx + 3.2, 65.0 + b, 3.0, 2.0, WHITE7, 4)
		var tl: int = 4 if dir == 0 else 3
		var sg: float = 1.0 if dir == 0 else -1.0
		var swg: int = int(sw * sg)
		if run:
			arm10(im, Vector2(cx - 10.8, 39 + b), Vector2(cx - 14.0, 81.0 + b + 6.0 * sw * sg), tl)
			arm10(im, Vector2(cx + 10.8, 39 + b), Vector2(cx + 14.0, 81.0 + b - 6.0 * sw * sg), tl - 1)
		else:
			arm10(im, Vector2(cx - 10.8, 39 + b), Vector2(cx - 15.4, 88 + b + swg), tl)
			arm10(im, Vector2(cx + 10.8, 39 + b), Vector2(cx + 15.4, 88 + b - swg), tl - 1)
		if dir == 1:
			# сзади плащ от шеи закрывает спину и руки; поверх него только волосы
			cape10(im, cx, 38 + b, 155, -sw * 2.2 + wind * 1.3, false, false, true)
		if dir == 0:
			# волосы по бокам лица рисуем ДО головы: голова закрывает их верх, и они растут прямо из неё
			hair_front14(im, cx, b, wind * 0.5 + (sw * 2.4 if walk else 0.0), 12.2, 12.2, 72, 0.0, [], [], -2.0)
			head14(im, cx, b, 0)
		else:
			hair_dome14(im, cx, 17.0 + b, 12.6, 12.6, 18 + b, 4)
			hair_mass(im, cx, 18 + b, 86 + b, 12.6, 13.6, -sw * 2.2 + wind * 0.5, 4, true, wind * 1.6 + hph)
			for x0 in range(int(cx) - 16, int(cx) + 17):
				for band in []:
					var yb: int = int(band) + b + int(round(sin(x0 * 0.7) * 1.4))
					if a_at(im, x0, yb) > 0.5 and a_at(im, x0, yb + 1) > 0.5:
						px(im, x0, yb, HAIRL7[6] if posmod(x0, 3) != 0 else HAIRL7[5])
						px(im, x0, yb + 1, HAIRL7[5])
			for xs in [-10, -5, 0, 5, 10]:
				for y6 in range(16 + b, 86 + b):
					var xw: int = int(cx) + int(xs) + int(round(sin(y6 * 0.3 + float(xs)) * 1.6))
					if a_at(im, xw, y6) > 0.5:
						px(im, xw, y6, HAIRL7[2])
			for p in [Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(3, 1), Vector2i(3, 2), Vector2i(1, 3), Vector2i(2, 3), Vector2i(2, 4)]:
				var pv: Vector2i = p
				px(im, int(cx) + pv.x, pv.y + b, HAIRL7[4])
	else:
		var fd: float = -6.0 if f == 0 else (6.0 if f == 2 else 0.0)
		var lift: int = 2 if f == 1 or f == 3 else 0
		if run:
			# фазы одной ноги: толкается сзади, захлёст назад, ставится впереди, колено вперёд-вверх.
			# Ближняя нога отстаёт от дальней на полцикла.
			var lp: Array = [[Vector2(cx + 13.0, foot_y - 5), knee + 1, 2.0], [Vector2(cx + 13.5, foot_y - 15), knee - 3, 4.0], [Vector2(cx - 11.0, foot_y), knee, -2.0], [Vector2(cx - 6.0, foot_y - 14), knee - 13, -9.0]]
			var fp: Array = lp[f]
			var np: Array = lp[(f + 2) % 4]
			var fpv: Vector2 = fp[0]
			var npv: Vector2 = np[0]
			leg_side10(im, Vector2(cx + 1.5, 76 + b), fpv + Vector2(1.0, 0.0), int(fp[1]), hem, true, float(fp[2]))
			boot10(im, fpv.x + 1.0, int(fpv.y) - 1, -1)
			leg_side10(im, Vector2(cx, 76 + b), npv, int(np[1]), hem, false, float(np[2]))
			boot10(im, npv.x, int(npv.y) - 1, -1)
		else:
			leg_side10(im, Vector2(cx + 1.5, 76 + b), Vector2(cx + 0.5 - fd, foot_y), knee, hem, true)
			boot10(im, cx + 0.5 - fd, foot_y - 1, -1)
			leg_side10(im, Vector2(cx, 76 + b), Vector2(cx - 0.5 + fd, foot_y - lift), knee, hem, false)
			boot10(im, cx - 0.5 + fd, foot_y - 1 - lift, -1)
		# платье: бёдра и ягодицы округляются назад, к подолу чуть внутрь
		var fk2: Array = [Vector2(0, 5.0), Vector2(0.5, 6.8), Vector2(1.0, 7.6)]
		var bk2: Array = [Vector2(0, 5.0), Vector2(0.3, 9.2), Vector2(0.55, 10.6), Vector2(1.0, 9.6)]
		for y2 in range(64 + b, hem + 1):
			var t3: float = float(y2 - 64 - b) / float(maxi(1, hem - 64 - b))
			var frn: float = curve_at(fk2, t3)
			var bkn: float = curve_at(bk2, t3)
			for x2 in range(int(floor(cx - frn + 0.5)), int(floor(cx + bkn + 0.5))):
				var u2: float = (x2 + 0.5 - (cx - frn)) / (frn + bkn)
				var ti3: int = 6 if u2 < 0.28 else (5 if u2 < 0.62 else (4 if u2 < 0.85 else 3))
				if x2 == int(floor(cx + bkn + 0.5)) - 1:
					ti3 = 2
				if y2 == hem:
					ti3 = 3
				px(im, x2, y2, WHITE7[ti3])
		for x3 in range(int(cx) - 8, int(cx) + 12):
			if a_at(im, x3, hem) > 0.5:
				px(im, x3, hem, TEAL7[3] if not UNDER else WHITE7[2])
		# торс: грудь вперёд и ниже, прогиб поясницы
		var bo: float = float(bounce)
		var fk: Array = _chest_profile(bo)
		var bkk: Array = [Vector2(0, 3.0), Vector2(3, 5.2), Vector2(6, 5.8), Vector2(16, 5.0), Vector2(23, 4.0), Vector2(27, 5.0)]
		for o in range(28):
			var y3: int = 37 + b + o
			var front2: float = curve_at_abs(fk, float(o))
			var back2: float = curve_at_abs(bkk, float(o))
			for x4 in range(int(floor(cx - front2 + 0.5)), int(floor(cx + back2 + 0.5))):
				var u3: float = (x4 + 0.5 - (cx - front2)) / (front2 + back2)
				var ti4: int = 6 if u3 < 0.28 else (5 if u3 < 0.66 else (4 if u3 < 0.88 else 3))
				# круглый блик на груди и мягкая тень под ней
				# выпуклость груди: сверху светлее, к низу плавно темнеет, под грудью мягкая тень
				var bo2: float = float(o) - (14.0 + bounce)
				if u3 < 0.5 and bo2 > -6.0 and bo2 < 9.0:
					if bo2 < 0.0:
						ti4 = maxi(ti4, 5 if u3 < 0.4 else ti4)
					else:
						ti4 = mini(ti4, 5 - int(bo2 * 0.45))
					if bo2 > 6.0:
						ti4 = mini(ti4, 3)
				if x4 == int(floor(cx + back2 + 0.5)) - 1:
					ti4 = 2
				px(im, x4, y3, WHITE7[ti4])
		belt8(im, cx, 61 + b, 5.0)
		# плащ поверх ног, платья и тела (кроме волос и руки)
		for y in range(38 + b, (38 + b) if NO_CAPE else 157):
			var t: float = float(y - 38 - b) / float(119 - b)
			var c: float = cx + 2.5 + t * t * (1.0 - sw * 2.4 + wind * 1.0 + (9.0 if run else 0.0))
			var back: float = lerpf(4.0, 6.5, t)
			back = minf(back, 1.0 + float(y - 38 - b) * 0.7)
			var front: float = lerpf(3.5, 4.5, t)
			for x in range(int(floor(c - front)), int(ceil(c + back))):
				var dx: float = x + 0.5 - c
				var hem_y: float = 155.0 + sin(dx * 0.45) * 1.6 + dx * 0.1
				if y > hem_y:
					continue
				var u: float = (dx + front) / (front + back)
				var ti2: int = 5 if u < 0.2 else (4 if u < 0.55 else (3 if u < 0.85 else 2))
				if t > 0.15 and sin(dx * 0.8 + t) > 0.85:
					ti2 -= 1
				if y > hem_y - 1.0:
					ti2 -= 2
				px(im, x, y, TEAL7[clampi(ti2, 0, 6)])
		# волосы поверх плаща
		side_hair10(im, cx + 3.0, b, hsw + wind * 0.9)
		if f >= 8:
			arm10(im, Vector2(cx + 0.5, 46 + b), Vector2(cx - 20.0 - (6.0 if f == 9 else 0.0), 104 + b + (2 if f == 9 else 0)), 4)
		elif run:
			# согнутая рука ходит навстречу ближней ноге, локоть всегда назад
			arm_bent(im, Vector2(cx + 1.0, 39 + b), Vector2(cx - 1.0 + sw * 14.0, 70.0 + b + maxf(sw, 0.0) * 10.0 - maxf(-sw, 0.0) * 4.0), 4, 1.0)
		else:
			arm10(im, Vector2(cx + 1.0, 39 + b), Vector2(cx - sw * 7.0, 88 + b), 4)
		# рука, отведённая назад при шаге, уходит за плащ: перерисовываем плащ только за линией спины
		for y in range(38 + b, (38 + b) if NO_CAPE else 157):
			var t: float = float(y - 38 - b) / float(119 - b)
			var c: float = cx + 2.5 + t * t * (1.0 - sw * 2.4 + wind * 1.0 + (9.0 if run else 0.0))
			var back: float = lerpf(4.0, 6.5, t)
			back = minf(back, 1.0 + float(y - 38 - b) * 0.7)
			var front: float = lerpf(3.5, 4.5, t)
			for x in range(int(floor(c - front)), int(ceil(c + back))):
				if x < int(cx) + 4:
					continue
				var dx: float = x + 0.5 - c
				var hem_y: float = 155.0 + sin(dx * 0.45) * 1.6 + dx * 0.1
				if y > hem_y:
					continue
				var u: float = (dx + front) / (front + back)
				var ti2: int = 5 if u < 0.2 else (4 if u < 0.55 else (3 if u < 0.85 else 2))
				if t > 0.15 and sin(dx * 0.8 + t) > 0.85:
					ti2 -= 1
				if y > hem_y - 1.0:
					ti2 -= 2
				px(im, x, y, TEAL7[clampi(ti2, 0, 6)])
		side_hair10(im, cx + 3.0, b, hsw + wind * 0.9)
		head14(im, cx, b, 2)


# ================================================================== v12: ракурсы вполоборота (по диагонали)

## Лицо вполоборота влево: 20 столбцов, строки 14..41. Глаза и рот вставляются отдельно.
const FACE34_T: Array = [
	"HHHHhHHHHHHhHHHHHhHH",
	"HHHhHHHHHHhHHHHHHhHH",
	"SHHHSHHHHHShHHHHShHS",
	"SShHSSHHHhSSHHHhSShS",
	"SSShSSShHSSSSHhSSSSS",
	"SSSSSSSShSSSSSSSSSSS",
	"SdddSSSSSSddddSSSSSS",
	"SSSSSSSSSSSSSSSSSSSS",
	"#", "#", "#", "#", "#", "#", "#",
	"SBBSSSSSSSBBBSSSSSSS",
	"SSSSSTSSSSSSSSSSSSSS",
	"SSSSSSSSSSSSSSSSSSST",
	"SSSSSMMSSSSSSSSSSSST",
	".SSSSSSSSSSSSSSSSST.",
	"..TSSSSSSSSSSSSSST..",
	"...TTSSSSSSSSSSTT...",
	".....TTSSSSSSTT.....",
	"......TTSSSSTT......",
	"........TSSST.......",
	"........TSSST.......",
	"........TSSST.......",
	"........TSSST.......",
]
const BROWS34: Dictionary = {
	"normal": ["SdddSSSSSSddddSSSSSS", "SSSSSSSSSSSSSSSSSSSS"],
	"sad": ["SSSdSSSSSSddSSSSSSSS", "SddSSSSSSSSSddSSSSSS"],
	"angry": ["SddSSSSSSSSSddSSSSSS", "SSSdSSSSSSddSSSSSSSS"],
}


## Строки лица вполоборота для выражения e = [имя, левый глаз, правый глаз, брови, рот, румянец]
func face34_rows(e: Array) -> Array:
	var rows: Array = []
	for r in FACE34_T:
		rows.append(String(r))
	var br: Array = BROWS34[e[3]]
	rows[6] = br[0]
	rows[7] = br[1]
	var far_e: Array = EYES_F[e[1]]
	var near_e: Array = EYES_F[e[2]]
	var far_s: Array = far_e[0]
	var near_s: Array = near_e[0]
	for k in range(7):
		var fs: String = String(far_s[k])
		var far4: String = fs[0] + fs[2] + fs[4] + fs[5]
		var wing_f: String = "E" if k == int(far_e[1]) else "S"
		var wing_n: String = "E" if k == int(near_e[1]) else "S"
		rows[8 + k] = wing_f + far4 + "SSSS" + String(near_s[k]) + wing_n + "SSSS"
	if bool(e[5]):
		rows[15] = "BBBSSSSSSBBBBBSSSSSS"
		rows[16] = "SBSSSTSSSSBBBSSSSSSS"
	var mo: Array = MOUTH_F[e[4]]
	for r2 in range(3):
		var l2: String = rows[17 + r2]
		rows[17 + r2] = l2.substr(0, 3) + String(mo[r2]) + l2.substr(9)
	return rows


## Голова вполоборота: верх как спереди, лицо смещено к дальнему краю
func head34(im: Image, cx: float, oy: int) -> void:
	var pal: Dictionary = _profile_pal()
	pal["O"] = Color("7a3a44")
	var rows: Array = _rows_from(H10_TOP)
	var face: Array = face34_rows(EXPRESSIONS[0])
	for i in range(face.size()):
		var ll: String = ".hHh"
		var lr: String = "hHHh"
		if i < 2:
			ll = ".hHH"
			lr = "HHHh"
		elif i > 20:
			ll = "..h."
			lr = ".hHh"
		if i > 23:
			ll = "...."
			lr = "...."
		rows.append("..." + ll + String(face[i]) + lr)
	var ox: int = int(cx) - 19
	grid(im, rows, ox, oy, pal)
	hair_texture(im, Rect2i(ox, oy, 34, 22), oy, false)


## Нога вполоборота: бедро и голень «капсулами», колено чуть вперёд к дальнему краю; tb — тон (дальняя темнее)
func leg34(im: Image, hip: Vector2, foot: Vector2, lift: int, tb: int, hem: int) -> void:
	if MERMAID:
		mer_tail_once(im)
		return
	var knee: Vector2 = hip.lerp(foot, 0.5) + Vector2(-1.0 - 1.2 * float(lift), -0.6 * float(lift))
	capsule(im, hip, knee, 6.2, 4.6, SKINL7, tb)
	capsule(im, knee, foot, 4.6, 2.9, SKINL7, tb)
	# под подолом нога в тени
	for y in range(int(hip.y) - 6, hem + 4):
		for x in range(int(hip.x) - 8, int(hip.x) + 9):
			if a_at(im, x, y) > 0.5 and im.get_pixel(x, y).is_equal_approx(SKINL7[clampi(tb + 1, 0, 6)]):
				px(im, x, y, SKINL7[clampi(tb - 1, 0, 6)])


## Шея вполоборота: из середины корпуса вверх, под щёку (голова рисуется поверх)
func neck34(im: Image, cx: float, b: int) -> void:
	for y in range(31 + b, 39 + b):
		var hw: float = 2.4 + maxf(0.0, float(y - 36 - b)) * 0.3
		for x in range(int(floor(cx + 0.5 - hw + 0.5)), int(floor(cx + 0.5 + hw + 0.5))):
			var u: float = (x - (cx + 0.5 - hw) + 0.5) / (2.0 * hw)
			var ti: int = 4 if u < 0.6 else 3
			if y < 35 + b:
				ti = 3
			px(im, x, y, SKINL7[ti])


## Вид вполоборота спереди-влево (S+A). Ближняя сторона — справа на экране.
## Корпус повёрнут: дальнее плечо и рука за телом, ноги шагают по диагонали (вперёд — влево и к нам),
## руки машут навстречу ногам, плащ и волосы раскачиваются от шагов.
func _hero34_front(im: Image, f: int, b: int, sw: float, wind: float, bounce: int) -> void:
	var cx: float = 40.0
	var hem: int = (78 if UNDER else 96) + b
	var foot_y: float = 142.0
	var walk: bool = f <= 3
	var st: float = sw if walk else 0.0
	var lift_far: int = 2 if f == 3 else 0
	var lift_near: int = 2 if f == 1 else 0
	var rk: float = 1.0
	if RUN > 0.0 and walk:
		rk = 1.9
		lift_far = [0, 2, 6, 7][f]
		lift_near = [6, 7, 0, 2][f]
	var cape_sw: float = -st * 2.4 + wind * 1.3
	var hair_sw: float = -st * 2.0 + wind * 0.5
	var hph: float = float(f) * 1.57 if walk else 0.0
	# волосы за спиной: затылок справа, поэтому масса чуть правее
	hair_mass14(im, cx - 0.6, 14 + b, 84 + b, 9.4, 9.8, hair_sw * 0.7, 3)
	cape10(im, cx + 0.8, 38 + b, 157, cape_sw, false, true, true)
	# ноги: шаг вперёд — влево и ниже (к нам), назад — вправо и выше
	var far_hip: Vector2 = Vector2(cx - 3.4, 78.0 + b)
	var near_hip: Vector2 = Vector2(cx + 3.2, 78.0 + b)
	var far_ft: Vector2 = Vector2(cx - 4.4 - 3.2 * rk * st, foot_y + 1.5 * rk * st - float(lift_far))
	var near_ft: Vector2 = Vector2(cx + 3.4 + 3.2 * rk * st, foot_y - 1.5 * rk * st - float(lift_near))
	if far_ft.y <= near_ft.y:
		leg34(im, far_hip, far_ft - Vector2(0, 1), lift_far, 3, hem)
		boot10(im, far_ft.x, int(far_ft.y) - 1, -1)
		leg34(im, near_hip, near_ft - Vector2(0, 1), lift_near, 4, hem)
		boot10(im, near_ft.x, int(near_ft.y) - 1, -1)
	else:
		leg34(im, near_hip, near_ft - Vector2(0, 1), lift_near, 4, hem)
		boot10(im, near_ft.x, int(near_ft.y) - 1, -1)
		leg34(im, far_hip, far_ft - Vector2(0, 1), lift_far, 3, hem)
		boot10(im, far_ft.x, int(far_ft.y) - 1, -1)
	skirt8(im, cx - 0.4, 64 + b, hem, 7.8, 12.8, st * 1.0 + wind * 0.6)
	cape10(im, cx + 0.6, 38 + b, 157, cape_sw, true, false, true)
	# дальняя рука за корпусом: машет навстречу дальней ноге
	if rk > 1.0:
		arm10(im, Vector2(cx - 8.4, 39 + b), Vector2(cx - 11.0 + 5.5 * st, 82.0 + b - 4.0 * st), 3)
	else:
		arm10(im, Vector2(cx - 8.4, 39 + b), Vector2(cx - 11.8 + 2.6 * st, 88.0 + b - 1.2 * st), 3)
	torso14_front(im, cx, b, false, bounce, 1.0)
	belt8(im, cx - 1.0, 61 + b, 7.0)
	if rk > 1.0:
		arm10(im, Vector2(cx + 10.4, 39 + b), Vector2(cx + 14.0 - 5.5 * st, 82.0 + b + 4.0 * st), 4)
	else:
		arm10(im, Vector2(cx + 10.4, 39 + b), Vector2(cx + 14.6 - 2.6 * st, 88.0 + b + 1.2 * st), 4)
	# пряди по бокам головы растут из неё и качаются вместе с ней
	hair_front14(im, cx, b, hair_sw * 0.8, 15.4, 9.8, 72, 0.45, [33, 9.0, 10.6], [31, 6.5, 0.5, 39, 5.2])
	neck34(im, cx, b)
	head14(im, cx, b, 1)


## Вид вполоборота сзади-влево (W+A): затылок, видна щека у левого края.
## Ноги под плащом шагают по диагонали (вперёд — влево и дальше от нас), плащ и волосы качаются.
func _hero34_back(im: Image, f: int, b: int, sw: float, wind: float) -> void:
	var cx: float = 40.0
	var c2: float = cx + 1.2
	var foot_y: float = 142.0
	var walk: bool = f <= 3
	var st: float = sw if walk else 0.0
	var lift_l: int = 2 if f == 3 else 0
	var lift_r: int = 2 if f == 1 else 0
	var rk: float = 1.0
	if RUN > 0.0 and walk:
		rk = 1.9
		lift_l = [0, 2, 6, 7][f]
		lift_r = [6, 7, 0, 2][f]
	var cape_sw: float = -st * 2.4 + wind * 1.3
	var hair_sw: float = -st * 2.0 + wind * 0.5
	var lf: Vector2 = Vector2(c2 - 5.0 - 3.0 * rk * st, foot_y - 1.5 * rk * st - float(lift_l))
	var rf: Vector2 = Vector2(c2 + 3.8 + 3.0 * rk * st, foot_y + 1.5 * rk * st - float(lift_r))
	if NO_CAPE:
		# без плаща сзади видны ноги
		leg34(im, Vector2(c2 - 3.4, 78.0 + b), lf - Vector2(0, 1), lift_l, 3, 96 + b)
		leg34(im, Vector2(c2 + 3.2, 78.0 + b), rf - Vector2(0, 1), lift_r, 4, 96 + b)
	if lf.y <= rf.y:
		boot10(im, lf.x, int(lf.y) - 1, -1)
		boot10(im, rf.x, int(rf.y) - 1, -1)
	else:
		boot10(im, rf.x, int(rf.y) - 1, -1)
		boot10(im, lf.x, int(lf.y) - 1, -1)
	skirt8(im, c2, 64 + b, 96 + b, 8.0, 13.2, st * 1.0 + wind * 0.6)
	torso14_front(im, c2, b, true, 0, 0.0)
	belt8(im, c2, 61 + b, 7.4)
	blob(im, c2 - 2.6, 65.0 + b, 3.0, 2.0, WHITE7, 5)
	blob(im, c2 + 3.4, 65.0 + b, 3.0, 2.0, WHITE7, 4)
	var ak: float = 2.0 if rk > 1.0 else 1.0
	arm10(im, Vector2(c2 - 10.8, 39 + b), Vector2(c2 - 15.0 - 2.4 * ak * st, 88.0 + b - 1.2 * ak * st - (6.0 if rk > 1.0 else 0.0)), 4)
	arm10(im, Vector2(c2 + 9.8, 39 + b), Vector2(c2 + 13.8 + 2.4 * ak * st, 88.0 + b + 1.2 * ak * st - (6.0 if rk > 1.0 else 0.0)), 2)
	cape10(im, c2, 38 + b, 155, cape_sw, false, false, true)
	# щека и ухо слева, затем волосы
	for y in range(18 + b, 30 + b):
		var t: float = float(y - 18 - b) / 12.0
		var w: float = 2.6 * sin(t * PI)
		for x in range(int(floor(c2 - 11.6)), int(floor(c2 - 11.6 + w + 0.5))):
			px(im, x, y, SKINL7[4 if x < int(c2) - 10 else 3])
	hair_dome14(im, c2 + 0.5, 17.0 + b, 12.4, 12.6, 18 + b, 4)
	hair_mass(im, c2 + 0.5, 18 + b, 86 + b, 12.4, 13.4, hair_sw * 0.9, 4, true, wind * 1.6 + (float(f) * 1.57 if walk else 0.0))
	for y2 in range(18 + b, 30 + b):
		var t2: float = float(y2 - 18 - b) / 12.0
		var w2: float = 2.6 * sin(t2 * PI)
		for x2 in range(int(floor(c2 - 11.6)), int(floor(c2 - 11.6 + w2 + 0.5))):
			px(im, x2, y2, SKINL7[4 if x2 < int(c2) - 10 else 3])
	px(im, int(c2) - 12, 23 + b, Color("2a1622"))
	px(im, int(c2) - 13, 24 + b, Color("2a1622"))
	for xs in [-9, -4, 1, 6, 10]:
		for y6 in range(16 + b, 86 + b):
			var k6: float = float(y6 - 16 - b) / 70.0
			var xw: int = int(c2) + int(xs) + int(round(sin(y6 * 0.3 + float(xs)) * 1.6 + hair_sw * 0.9 * k6 * k6))
			if a_at(im, xw, y6) > 0.5 and absf(im.get_pixel(xw, y6).r - HAIRL7[4].r) < 0.12:
				px(im, xw, y6, HAIRL7[2])
	for p in [Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(3, 1), Vector2i(3, 2), Vector2i(1, 3), Vector2i(2, 3), Vector2i(2, 4)]:
		var pv: Vector2i = p
		px(im, int(c2) + pv.x, pv.y + b, HAIRL7[4])


# ================================================================== v13: на колене — глажка животных

## «Капсула» — конечность от a до b с толщиной r0..r1, свет сверху-слева
func capsule(im: Image, a: Vector2, b2: Vector2, r0: float, r1: float, ramp: Array, tb: int) -> void:
	var ab: Vector2 = b2 - a
	var len2: float = maxf(0.001, ab.length_squared())
	var lo: Vector2 = Vector2(minf(a.x, b2.x), minf(a.y, b2.y)) - Vector2.ONE * (maxf(r0, r1) + 1.0)
	var hi: Vector2 = Vector2(maxf(a.x, b2.x), maxf(a.y, b2.y)) + Vector2.ONE * (maxf(r0, r1) + 1.0)
	var light: Vector2 = Vector2(-0.6, -0.8)
	for y in range(int(lo.y), int(hi.y) + 1):
		for x in range(int(lo.x), int(hi.x) + 1):
			var p: Vector2 = Vector2(x + 0.5, y + 0.5)
			var t: float = clampf((p - a).dot(ab) / len2, 0.0, 1.0)
			var q: Vector2 = a + ab * t
			var r: float = lerpf(r0, r1, t)
			var d: float = p.distance_to(q)
			if d > r:
				continue
			var n: Vector2 = (p - q) / maxf(0.001, d)
			var l: float = n.dot(light) * (d / maxf(0.5, r))
			var ti: int = tb + 1 if l > 0.35 else (tb if l > -0.35 else tb - 1)
			if d > r - 1.0 and l < -0.2:
				ti = tb - 2
			px(im, x, y, ramp[clampi(ti, 0, ramp.size() - 1)])


## Рука с локтем: плечо и предплечье постоянной длины, локоть сгибается вниз
func arm_ik(im: Image, sh: Vector2, hand: Vector2, tb: int) -> void:
	var U: float = 23.0
	var F: float = 23.0
	var v: Vector2 = hand - sh
	var d: float = clampf(v.length(), 6.0, U + F - 0.5)
	var dir: Vector2 = v.normalized()
	var h2: Vector2 = sh + dir * d
	var a: float = (U * U - F * F + d * d) / (2.0 * d)
	var hh: float = sqrt(maxf(0.0, U * U - a * a))
	var n1: Vector2 = Vector2(-dir.y, dir.x)
	if n1.y < 0.0:
		n1 = -n1
	var elbow: Vector2 = sh + dir * a + n1 * hh
	var wrist: Vector2 = elbow.lerp(h2, 0.84)
	capsule(im, sh, elbow, 3.0, 2.7, _sleeve(), tb)
	capsule(im, elbow, wrist, 2.7, 2.3, _sleeve(), tb)
	blob(im, sh.x, sh.y + 2.0, 3.0, 3.2, _sleeve(), tb + 1)
	var cn: Vector2 = Vector2(-(h2 - elbow).normalized().y, (h2 - elbow).normalized().x)
	for k in range(-3, 4):
		px(im, int(wrist.x + cn.x * k * 0.8), int(wrist.y + cn.y * k * 0.8), TEAL7[4])
	capsule(im, wrist, h2, 1.8, 1.8, SKINL7, 4)
	blob(im, h2.x, h2.y, 2.6, 2.4, SKINL7, 4)


## Согнутая рука для бега: как arm_ik, но локоть уходит в сторону side (по x: -1 влево, +1 вправо)
func arm_bent(im: Image, sh: Vector2, hand: Vector2, tb: int, side: float) -> void:
	var U: float = 23.0
	var F: float = 22.0
	var v: Vector2 = hand - sh
	var d: float = clampf(v.length(), 6.0, U + F - 0.5)
	var dir: Vector2 = v.normalized()
	var h2: Vector2 = sh + dir * d
	var a: float = (U * U - F * F + d * d) / (2.0 * d)
	var hh: float = sqrt(maxf(0.0, U * U - a * a))
	var n1: Vector2 = Vector2(-dir.y, dir.x)
	if n1.x * side < 0.0:
		n1 = -n1
	var elbow: Vector2 = sh + dir * a + n1 * hh
	var wrist: Vector2 = elbow.lerp(h2, 0.84)
	capsule(im, sh, elbow, 3.0, 2.7, _sleeve(), tb)
	capsule(im, elbow, wrist, 2.7, 2.3, _sleeve(), tb)
	blob(im, sh.x, sh.y + 2.0, 3.0, 3.2, _sleeve(), tb + 1)
	var cn: Vector2 = Vector2(-(h2 - elbow).normalized().y, (h2 - elbow).normalized().x)
	for k in range(-3, 4):
		px(im, int(wrist.x + cn.x * k * 0.8), int(wrist.y + cn.y * k * 0.8), TEAL7[4])
	capsule(im, wrist, h2, 1.8, 1.8, SKINL7, 4)
	blob(im, h2.x, h2.y, 2.6, 2.4, SKINL7, 4)


## Куда тянется кисть (вид сбоку, смотрит влево; кот на подушке слева, героиня вплотную справа).
## Точки посчитаны по рисунку кота: макушка ~ (8, 87), подбородок ~ (10, 108), спина y 106..113.
## 10-15 ладонь скользит по макушке кота слева направо (гладит по голове), 18 рука на колене
const PET_HAND: Dictionary = {
	10: Vector2(1, 81), 11: Vector2(4, 79), 12: Vector2(7, 78), 13: Vector2(10, 78),
	14: Vector2(13, 79), 15: Vector2(16, 81),
	18: Vector2(25, 119),
}
## Насколько присела в кадре: 19-23 — промежуточные кадры плавного опускания на колено
const KNEEL_P: Dictionary = {19: 0.15, 20: 0.32, 21: 0.5, 22: 0.68, 23: 0.85}


## Поза от стойки (p=0) до одного колена (p=1), вид сбоку, смотрит влево.
## Суставы ног плавно переходят между позами, корпус и голова опускаются на 34*p.
func _hero_kneel(im: Image, f: int) -> void:
	var cx: float = 40.0
	var p: float = float(KNEEL_P.get(f, 1.0))
	var K: int = int(round(34.0 * p))
	# при опускании корпус наклоняется вперёд (к коту), в конце выпрямляется
	var lx: float = cx - 5.5 * sin(p * PI) if p < 1.0 else cx
	# задняя нога: колено опускается на землю, голень уходит назад
	var bh: Vector2 = Vector2(42.5, 76 + K)
	var bk: Vector2 = Vector2(42, 117).lerp(Vector2(41, 148), p)
	var bf: Vector2 = Vector2(42, 141).lerp(Vector2(57, 151), p)
	capsule(im, bh, bk, 6.8, 4.8, SKINL7, 3)
	capsule(im, bk, bf, 4.6, 3.0, SKINL7, 3)
	if p < 0.6:
		boot10(im, bf.x, int(bf.y), -1)
	else:
		capsule(im, bf + Vector2(-2, 0), bf + Vector2(9, 1), 3.8, 3.4, LEATH7, 3)
		for x2 in range(int(bf.x) - 4, int(bf.x) + 11):
			px(im, x2, int(bf.y) + 4, LEATH7[0])
	# передняя нога: колено уходит вперёд, стопа остаётся на земле
	var fh: Vector2 = Vector2(38.5, 76 + K)
	var fkn: Vector2 = Vector2(37, 117).lerp(Vector2(22, 123), p)
	var ff: Vector2 = Vector2(38, 141).lerp(Vector2(24, 141), p)
	capsule(im, fh, fkn, 6.8, 5.0, SKINL7, 4)
	capsule(im, fkn, ff, 5.0, 3.4, SKINL7, 4)
	boot10(im, ff.x, int(ff.y), -1)
	# короткое платье (в белье — шортики)
	var khem: int = (78 if UNDER else 96) + K
	for y2 in range(64 + K, khem + 1):
		var t3: float = float(y2 - 64 - K) / 32.0
		var frn: float = lerpf(5.4, lerpf(7.8, 11.0, p), t3)
		var bkn: float = lerpf(5.0, 10.0, sqrt(t3))
		for x3 in range(int(floor(cx - frn + 0.5)), int(floor(cx + bkn + 0.5))):
			var u2: float = (x3 + 0.5 - (cx - frn)) / (frn + bkn)
			var ti3: int = 6 if u2 < 0.28 else (5 if u2 < 0.62 else (4 if u2 < 0.85 else 3))
			if y2 >= khem - 1:
				ti3 = 3
			px(im, x3, y2, WHITE7[ti3])
	for x4 in range(int(cx) - 11, int(cx) + 10):
		if a_at(im, x4, khem) > 0.5:
			px(im, x4, khem, TEAL7[3] if not UNDER else WHITE7[2])
	# торс в профиль
	var fk: Array = _chest_profile(0.0)
	var bkk: Array = [Vector2(0, 3.0), Vector2(3, 5.2), Vector2(6, 5.8), Vector2(16, 5.0), Vector2(23, 4.0), Vector2(27, 5.0)]
	for o in range(28):
		var y3: int = 37 + K + o
		var f2: float = curve_at_abs(fk, float(o))
		var b3: float = curve_at_abs(bkk, float(o))
		for x5 in range(int(floor(lx - f2 + 0.5)), int(floor(lx + b3 + 0.5))):
			var u3: float = (x5 + 0.5 - (lx - f2)) / (f2 + b3)
			var ti4: int = 6 if u3 < 0.28 else (5 if u3 < 0.66 else (4 if u3 < 0.88 else 3))
			var bo2: float = float(o) - 14.0
			if u3 < 0.5 and bo2 > -6.0 and bo2 < 9.0:
				if bo2 < 0.0:
					ti4 = maxi(ti4, 5 if u3 < 0.4 else ti4)
				else:
					ti4 = mini(ti4, 5 - int(bo2 * 0.45))
				if bo2 > 6.0:
					ti4 = mini(ti4, 3)
			if x5 == int(floor(lx + b3 + 0.5)) - 1:
				ti4 = 2
			px(im, x5, y3, WHITE7[ti4])
	belt8(im, lx, 61 + K, 5.0)
	# накидка: чем ниже присела, тем больше ложится на землю
	for y in range(38 + K, 38 + K if NO_CAPE else 157):
		var t: float = float(y - 38 - K) / float(119 - K)
		var c: float = cx + 2.5 + t * t * (1.5 + 2.0 * p)
		var back: float = lerpf(4.0, lerpf(6.5, 12.0, p), t)
		back = minf(back, 1.0 + float(y - 38 - K) * 0.7)
		var front: float = lerpf(4.0, lerpf(5.0, 9.0, p), t)
		for x in range(int(floor(c - front)), int(ceil(c + back))):
			var dx: float = x + 0.5 - c
			if y > 155.0 + sin(dx * 0.5) * 1.2:
				continue
			var u: float = (dx + front) / (front + back)
			var ti2: int = 5 if u < 0.2 else (4 if u < 0.55 else (3 if u < 0.85 else 2))
			if t > 0.15 and sin(dx * 0.8 + t) > 0.85:
				ti2 -= 1
			if y > 153:
				ti2 -= 1
			px(im, x, y, TEAL7[clampi(ti2, 0, 6)])
	# волосы поверх накидки
	side_hair10(im, lx + 3.0, K, 0.0)
	# рука: в промежуточных кадрах опирается на бедро, потом тянется к коту
	var rest: Vector2 = Vector2(36, 88 + K * 0.6).lerp(Vector2(25, 119), p)
	var hand: Vector2 = PET_HAND.get(f, rest)
	arm_ik(im, Vector2(lx - 0.5, 40 + K), hand, 4)
	head14(im, lx, K, 2)


var BOUNCE_OVR: int = -99
var RUN: float = 0.0           # >0 — кадры бега (24-27): шире шаг, подлёт, плащ и волосы летят назад


## Слой груди для физики: варианты смещения -1..2 (анфас 19x18, профиль 12x18)
func gen_bust10() -> void:
	# Слой груди для физики. Берём только пиксели самой кофты в зоне груди — без волос, рук и краёв,
	# иначе при ходьбе (руки и волосы в другом месте) слой рисует поверх них полосу.
	var atlas: Image = new_img(50, 18 * 6)
	# [ракурс, x области, ширина, x в атласе, допустимые x от, до]
	var specs: Array = [[0, 31, 19, 0, 33, 46], [2, 26, 12, 19, 26, 36], [4, 29, 19, 31, 32, 45]]
	for k in range(6):
		BOUNCE_OVR = k - 2
		for sp in specs:
			var view: int = int(sp[0])
			var rx: int = int(sp[1])
			var rw: int = int(sp[2])
			var ax: int = int(sp[3])
			var cell: Image = new_img(80, 160)
			draw_hero10(cell, view, 4)
			outline_auto(cell, OUTLINE_CHAR)
			for y in range(18):
				for x in range(rw):
					var cxp: int = rx + x
					if cxp < int(sp[4]) or cxp > int(sp[5]):
						continue
					var c: Color = cell.get_pixel(cxp, 40 + y)
					if c.a < 0.5:
						continue
					var keep: bool = false
					for wc in WHITE7:
						if c.is_equal_approx(wc):
							keep = true
							break
					if not keep and view == 2 and c.get_luminance() < 0.3:
						keep = true
					if keep:
						atlas.set_pixel(ax + x, k * 18 + y, c)
	BOUNCE_OVR = 0
	atlas.save_png(OUT + "bust.png")


func _sleeve() -> Array:
	if UNDER:
		return SKINL7
	return SLEEVE7 if not SLEEVE7.is_empty() else WHITE7


## v16: листы героини для каждого наряда. Тело — в «теле» body: none (бельё), rags, dress, cloak_travel, lab_coat, apron;
## ноги: обута или босиком (_bare). Имя: player_<наряд>[_bare].png, слой груди bust_<наряд>.png.
const OUTFITS: Dictionary = {
	"none": [["3e5250", "5c7672", "7e9a94", "a2bcb4", "c4dad2", "dfeee8", "f4fbf8"], [], true],
	"rags": [["2e2620", "463a30", "5e4e40", "786654", "927e68", "aa967e", "c4b094"], [], false],
	"dress": [["5a5c74", "8487a0", "aab0c2", "ccd2dc", "e6eaee", "f5f7f4", "ffffff"], [], false],
	"cloak_travel": [["5a5c74", "8487a0", "aab0c2", "ccd2dc", "e6eaee", "f5f7f4", "ffffff"], ["0e2834", "143e4a", "1c5660", "267274", "378e8a", "5eaea2", "96d0c0"], false],
	"lab_coat": [["1c2238", "28304e", "36406a", "4a5686", "6474a2", "8a98c0", "b6c2de"], ["141626", "1e2236", "2a3050", "384068", "4a5482", "66729e", "90a0c4"], false],
	"apron": [["4a3018", "6a4822", "8e6430", "b08444", "cca460", "e2c486", "f4e2b4"], [], false],
}


func gen_outfits() -> void:
	HAIRL7 = hx(["4a3430", "6e5244", "907058", "b08e6e", "c8a884", "dcc4a0", "eee0c4"])
	SKINL7 = hx(["7a4a4c", "a8645e", "d08a7c", "eaae98", "f8ccb8", "fde2d4", "fff2ea"])
	_head_pal()
	BOUNCE_OVR = 0
	var fw: int = 80
	var fh: int = 160
	var mirror: Dictionary = {2: 3, 4: 6, 5: 7}
	var only_o: String = ""
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("--outfit="):
			only_o = String(a).substr(9)
	for oname in OUTFITS.keys():
		if only_o != "" and only_o != String(oname):
			continue
		var od: Array = OUTFITS[oname]
		WHITE7 = hx(od[0])
		var cape_p: Array = od[1]
		TEAL7 = hx(cape_p) if not cape_p.is_empty() else hx(["0e2834", "143e4a", "1c5660", "267274", "378e8a", "5eaea2", "96d0c0"])
		NO_CAPE = cape_p.is_empty()
		UNDER = bool(od[2])
		SLEEVE7 = []
		for bare in [false, true]:
			BAREFOOT = bare
			var sheet: Image = new_img(fw * 28, fh * 8)
			for dir in [0, 1, 2, 4, 5]:
				for f in range(28):
					var cell: Image = new_img(fw, fh)
					draw_hero10(cell, dir, f)
					outline_auto(cell, OUTLINE_CHAR)
					sheet.blit_rect(cell, Rect2i(0, 0, fw, fh), Vector2i(f * fw, dir * fh))
					if mirror.has(dir):
						var m: Image = cell.duplicate()
						m.flip_x()
						sheet.blit_rect(m, Rect2i(0, 0, fw, fh), Vector2i(f * fw, int(mirror[dir]) * fh))
			save3(sheet, "player_%s%s" % [String(oname), "_bare" if bare else ""])
			print("outfit ", oname, " bare=", bare)
		BAREFOOT = false
		gen_bust10()
		var bimg: Image = Image.load_from_file(ProjectSettings.globalize_path(OUT + "bust.png"))
		bimg.save_png(OUT + "bust_%s.png" % String(oname))
	UNDER = false
	BAREFOOT = false
	NO_CAPE = false
	# обычный bust.png — как раньше (платье + плащ)
	WHITE7 = hx(OUTFITS["cloak_travel"][0])
	TEAL7 = hx(OUTFITS["cloak_travel"][1])
	gen_bust10()


func gen_player10() -> void:
	HAIRL7 = hx(["4a3430", "6e5244", "907058", "b08e6e", "c8a884", "dcc4a0", "eee0c4"])
	SKINL7 = hx(["7a4a4c", "a8645e", "d08a7c", "eaae98", "f8ccb8", "fde2d4", "fff2ea"])
	WHITE7 = hx(["5a5c74", "8487a0", "aab0c2", "ccd2dc", "e6eaee", "f5f7f4", "ffffff"])
	TEAL7 = hx(["0e2834", "143e4a", "1c5660", "267274", "378e8a", "5eaea2", "96d0c0"])
	_head_pal()
	gen_bust10()
	BOUNCE_OVR = 0
	var fw: int = 80
	var fh: int = 160
	var sheet: Image = new_img(fw * 28, fh * 8)
	var mirror: Dictionary = {2: 3, 4: 6, 5: 7}
	for dir in [0, 1, 2, 4, 5]:
		for f in range(28):
			var cell: Image = new_img(fw, fh)
			draw_hero10(cell, dir, f)
			outline_auto(cell, OUTLINE_CHAR)
			sheet.blit_rect(cell, Rect2i(0, 0, fw, fh), Vector2i(f * fw, dir * fh))
			if mirror.has(dir):
				var m: Image = cell.duplicate()
				m.flip_x()
				sheet.blit_rect(m, Rect2i(0, 0, fw, fh), Vector2i(f * fw, int(mirror[dir]) * fh))
	save3(sheet, "player")
	var big: Image = sheet.duplicate()
	big.resize(sheet.get_width() * 2, sheet.get_height() * 2, Image.INTERPOLATE_NEAREST)
	big.save_png(ProjectSettings.globalize_path("res://").path_join("../screenshots/player_zoom.png"))
	for pair in [[4, "player_front_big.png"], [52, "player_side_big.png"], [28, "player_back_big.png"], [100, "player_34front_big.png"], [124, "player_34back_big.png"]]:
		var idx: int = int(pair[0])
		var one: Image = new_img(fw, fh)
		one.blit_rect(sheet, Rect2i((idx % 24) * fw, (idx / 24) * fh, fw, fh), Vector2i.ZERO)
		one.resize(fw * 6, fh * 6, Image.INTERPOLATE_NEAREST)
		one.save_png(ProjectSettings.globalize_path("res://").path_join("../screenshots/" + String(pair[1])))
	var wsheet: Image = new_img(fw * 4, fh * 2)
	for k2 in range(4):
		wsheet.blit_rect(sheet, Rect2i((4 + k2) * fw, 0, fw, fh), Vector2i(k2 * fw, 0))
		wsheet.blit_rect(sheet, Rect2i((4 + k2) * fw, 2 * fh, fw, fh), Vector2i(k2 * fw, fh))
	wsheet.resize(wsheet.get_width() * 3, wsheet.get_height() * 3, Image.INTERPOLATE_NEAREST)
	wsheet.save_png(ProjectSettings.globalize_path("res://").path_join("../screenshots/player_wind.png"))
	gen_faces10()
	# кадры бега во всех ракурсах — для проверки глазами
	var rsheet: Image = new_img(fw * 4, fh * 8)
	for rd in range(8):
		rsheet.blit_rect(sheet, Rect2i(24 * fw, rd * fh, fw * 4, fh), Vector2i(0, rd * fh))
	rsheet.resize(rsheet.get_width() * 2, rsheet.get_height() * 2, Image.INTERPOLATE_NEAREST)
	rsheet.save_png(ProjectSettings.globalize_path("res://").path_join("../screenshots/player_run.png"))
	var korder: Array = [4, 19, 20, 21, 22, 23, 18, 10, 11, 12, 13, 14, 15, 16, 17]
	var ksheet: Image = new_img(fw * korder.size(), fh)
	for k4 in range(korder.size()):
		ksheet.blit_rect(sheet, Rect2i(int(korder[k4]) * fw, 2 * fh, fw, fh), Vector2i(k4 * fw, 0))
	ksheet.resize(ksheet.get_width() * 2, ksheet.get_height() * 2, Image.INTERPOLATE_NEAREST)
	ksheet.save_png(ProjectSettings.globalize_path("res://").path_join("../screenshots/player_kneel.png"))
	var looks: Array = [
		["villager_marta", ["2a1a1e", "3e2628", "583530", "74483a", "8e5c44", "a87454", "c49272"], ["6a5a4a", "907e66", "b4a084", "d2c0a0", "e6d8bc", "f2e8d4", "fbf6ea"], ["3a1e2a", "5a2a3a", "7a3a4c", "9a4e5e", "b86a74", "d48e92", "ecb6b4"]],
		["villager_lina", ["1e1a2a", "2a2440", "3a3258", "4c4472", "625a8c", "7c74a6", "a49cc6"], ["5e6a74", "8896a2", "b0bcc6", "cfd8de", "e4eaee", "f2f6f8", "ffffff"], ["2a2a14", "44441e", "5e5e2a", "7a7838", "96924a", "b2ac64", "d0ca8c"]],
		["villager_tim", ["4a1a12", "6e2416", "92341c", "b44a24", "d06630", "e68842", "f6b064"], ["5a4a3a", "7e6a54", "a28c70", "c0ac8c", "d8c6a8", "ece0c8", "f8f2e4"], ["1a2a3e", "223a56", "2e4e70", "3e6488", "5680a2", "78a0be", "a6c4da"]],
	]
	var sh: Array = HAIRL7.duplicate()
	var sw7: Array = WHITE7.duplicate()
	var st: Array = TEAL7.duplicate()
	for lk in looks:
		HAIRL7 = hx(lk[1])
		WHITE7 = hx(lk[2])
		TEAL7 = hx(lk[3])
		_head_pal()
		# 8 ракурсов, как у героини: 0 спереди, 1 сзади, 2 влево, 3 вправо, 4-7 по диагонали
		var vs: Image = new_img(fw * 8, fh * 8)
		for vd in [0, 1, 2, 4, 5]:
			for k in range(8):
				var c2: Image = new_img(fw, fh)
				draw_hero10(c2, vd, k)
				outline_auto(c2, OUTLINE_CHAR)
				vs.blit_rect(c2, Rect2i(0, 0, fw, fh), Vector2i(k * fw, vd * fh))
				if mirror.has(vd):
					var mc: Image = c2.duplicate()
					mc.flip_x()
					vs.blit_rect(mc, Rect2i(0, 0, fw, fh), Vector2i(k * fw, int(mirror[vd]) * fh))
		save3(vs, String(lk[0]))
		gen_faces10("faces_" + String(lk[0]))
	HAIRL7 = sh
	WHITE7 = sw7
	TEAL7 = st
	_head_pal()


# ================================================================== v11: выражения лица (слой поверх лица)

## Глаз 6x7 (анфас): строки сверху вниз. lash — строка ресниц (для «хвостика» у края), -1 — без него
const EYES_F: Dictionary = {
	"open": [["EEEEEE", "EIIWWI", "wIIWWI", "wIIIII", "wIiiiI", "wijjii", "SeeeeS"], 0],
	"half": [["SSSSSS", "SSSSSS", "EEEEEE", "wIIWWI", "wIiiiI", "wijjii", "SeeeeS"], 2],
	"closed": [["SSSSSS", "SSSSSS", "SSSSSS", "SSSSSS", "EEEEEE", "SeeeeS", "SSSSSS"], 4],
	"happy": [["SSSSSS", "SSSSSS", "SSEESS", "SESSES", "ESSSSE", "SSSSSS", "SSSSSS"], -1],
	"surprise": [["SEEEES", "EwwwwE", "wwIIww", "wwIWww", "wwIIww", "EwwwwE", "SeeeeS"], -1],
	"look_l": [["EEEEEE", "IWWIww", "IWWIww", "IIIIww", "iiiIww", "jjiiww", "SeeeeS"], 0],
	"look_r": [["EEEEEE", "wwIIWW", "wwIIWW", "wwIIII", "wwIiii", "wwijji", "SeeeeS"], 0],
	"sleepy": [["SSSSSS", "SSSSSS", "SSSSSS", "EEEEEE", "wIiiiI", "wijjii", "SeeeeS"], 3],
}
## Глаз в профиль 4x7
const EYES_P: Dictionary = {
	"open": ["EEEE", "IWWE", "IWWw", "IIIw", "iiiw", "ijiS", "SeeS"],
	"half": ["SSSS", "SSSS", "EEEE", "IIWw", "iiiw", "ijiS", "SeeS"],
	"closed": ["SSSS", "SSSS", "SSSS", "SSSS", "EEEE", "SeeS", "SSSS"],
	"happy": ["SSSS", "SSSS", "SEES", "ESSE", "SSSS", "SSSS", "SSSS"],
	"surprise": ["SEEE", "Ewww", "wIWw", "wIIw", "wwww", "EwwS", "SeeS"],
	"look_l": ["EEEE", "IWWE", "IWWw", "IIIw", "iiiw", "ijiS", "SeeS"],
	"look_r": ["EEEE", "wIWE", "wIWw", "wIIw", "wiiw", "wijS", "SeeS"],
	"sleepy": ["SSSS", "SSSS", "SSSS", "EEEE", "iiiw", "ijiS", "SeeS"],
}
## Рот анфас: строки 31..33, столбцы 7..12 (6 шт.)
const MOUTH_F: Dictionary = {
	"neutral": ["SSSSSS", "SSMMSS", "SSSSSS"],
	"smile": ["SSSSSS", "SMSSMS", "SSMMSS"],
	"open": ["SSSSSS", "SMOOMS", "SSMMSS"],
	"o": ["SSMMSS", "SMOOMS", "SSMMSS"],
	"frown": ["SSMMSS", "SMSSMS", "SSSSSS"],
	"pout": ["SSSSSS", "SSSMSS", "SSSSSS"],
}
## Рот в профиль: строки 31..33, столбцы 5..6
const MOUTH_P: Dictionary = {
	"neutral": ["SS", "SM", "SS"],
	"smile": ["SS", "SM", "MS"],
	"open": ["SM", "SO", "SM"],
	"o": ["SM", "SO", "SM"],
	"frown": ["SM", "SS", "SS"],
	"pout": ["SS", "MS", "SS"],
}
const BROWS: Dictionary = {
	"normal": ["SddddSSSSSSSSSSddddS", "SSSSSSSSSSSSSSSSSSSS"],
	"sad": ["SSSddSSSSSSSSSSddSSS", "SddSSSSSSSSSSSSSSddS"],
	"angry": ["SddSSSSSSSSSSSSSSddS", "SSSddSSSSSSSSSSddSSS"],
}
## Выражения: [левый глаз, правый глаз, брови, рот, сильный румянец]
const EXPRESSIONS: Array = [
	["neutral", "open", "open", "normal", "neutral", false],
	["blink_half", "half", "half", "normal", "neutral", false],
	["blink", "closed", "closed", "normal", "neutral", false],
	["smile", "open", "open", "normal", "smile", false],
	["happy", "happy", "happy", "normal", "smile", true],
	["surprised", "surprise", "surprise", "normal", "o", false],
	["look_left", "look_l", "look_l", "normal", "neutral", false],
	["look_right", "look_r", "look_r", "normal", "neutral", false],
	["sleepy", "sleepy", "sleepy", "normal", "pout", false],
	["talk_a", "open", "open", "normal", "open", false],
	["talk_b", "open", "open", "normal", "o", false],
	["shy", "half", "half", "sad", "smile", false],
	["sad", "open", "open", "sad", "frown", false],
	["pout", "half", "half", "angry", "pout", false],
	["wink", "closed", "open", "normal", "smile", true],
	["disgust", "closed", "closed", "angry", "frown", false],
	["sick", "closed", "closed", "sad", "o", false],
]


## Атлас лиц: каждая строка — выражение; слева анфас 20x15, справа профиль 11x15
func gen_faces10(out_name: String = "faces") -> void:
	# Атлас выражений для головы v14. Берём из головы только те пиксели, которые меняются
	# хоть в одном выражении (глаза, брови, румянец, рот) — остальное (контур, волосы) не трогаем.
	var pal: Dictionary = _profile_pal()
	pal["O"] = Color("7a3a44")
	var atlas: Image = new_img(51, 15 * EXPRESSIONS.size())
	# [ракурс, x области в кадре, ширина, x в атласе]; область по высоте — строки 16..30
	var specs: Array = [[0, 30, 20, 0], [2, 29, 11, 20], [1, 29, 20, 31]]
	for sp in specs:
		var view: int = int(sp[0])
		var rx: int = int(sp[1])
		var rw: int = int(sp[2])
		var ax: int = int(sp[3])
		var imgs: Array = []
		for ei in range(EXPRESSIONS.size()):
			var im: Image = new_img(80, 60)
			grid(im, _h14_head_rows(EXPRESSIONS[ei], view), _h14_ox(40.0, view), 0, pal)
			imgs.append(im)
		var base: Image = imgs[0]
		for y in range(15):
			for x in range(rw):
				var cxp: int = rx + x
				var cyp: int = 16 + y
				var changes: bool = false
				for im2 in imgs:
					if not (im2 as Image).get_pixel(cxp, cyp).is_equal_approx(base.get_pixel(cxp, cyp)):
						changes = true
						break
				if not changes:
					continue
				for ei2 in range(EXPRESSIONS.size()):
					var c: Color = (imgs[ei2] as Image).get_pixel(cxp, cyp)
					if c.a > 0.5:
						atlas.set_pixel(ax + x, ei2 * 15 + y, c)
	atlas.save_png(OUT + out_name + ".png")
	if out_name != "faces":
		return
	var big: Image = atlas.duplicate()
	big.resize(big.get_width() * 8, big.get_height() * 8, Image.INTERPOLATE_NEAREST)
	big.save_png(ProjectSettings.globalize_path("res://").path_join("../screenshots/faces_atlas.png"))


func save3(im: Image, name: String, show: bool = true) -> void:
	im.save_png(OUT + name + ".png")
	if show:
		v3_items.append([name, im])


## Крупное превью новых спрайтов (x3) на мягком фоне для проверки
func save_preview3() -> void:
	if v3_items.is_empty():
		return
	var all: Array = v3_items.duplicate()
	var small: Array = []
	for it in all:
		var im0: Image = it[1]
		if im0.get_width() <= 64:
			small.append(it)
	_sheet(all, 3, "v3_preview.png")
	_sheet(small, 6, "v3_small.png")


func _sheet(items: Array, sc: int, fname: String) -> void:
	var x: int = 16
	var y: int = 16
	var row_h: int = 0
	var W: int = 1900
	var placed: Array = []
	for it in items:
		var im: Image = it[1]
		var w: int = im.get_width() * sc
		var h: int = im.get_height() * sc
		if x + w > W - 16:
			x = 16
			y += row_h + 16
			row_h = 0
		placed.append([im, x, y])
		x += w + 16
		row_h = maxi(row_h, h)
	var sheet: Image = new_img(W, y + row_h + 16)
	sheet.fill(Color("a9cf8e"))
	for p in placed:
		var src: Image = p[0]
		var s: Image = src.duplicate()
		s.resize(s.get_width() * sc, s.get_height() * sc, Image.INTERPOLATE_NEAREST)
		sheet.blend_rect(s, Rect2i(0, 0, s.get_width(), s.get_height()), Vector2i(int(p[1]), int(p[2])))
	var dir: String = ProjectSettings.globalize_path("res://").path_join("../screenshots")
	sheet.save_png(dir.path_join(fname))


## ================================================================== уютная комнатка (v2, 12.11)
## Одна маленькая комната, как и домик снаружи. Картинка 640x360, комната в центре:
## стены x 220..420, задняя стена y 92..146, пол y 146..282, передняя стенка y 282..290, дверь x 306..334.
## Всё тёплое: медовые доски, кремовая штукатурка, травы под потолком, окно со светом.

const CZ_L: int = 228
const CZ_R: int = 412
const CZ_TOP: int = 146
const CZ_BOT: int = 282

var WARM: Array          # тёплые доски пола
var ROSE: Array          # розовый (ковёр, цветы, ткань)
var SKYW: Array          # небо в окне


func _cozy_pal() -> void:
	WARM = hx(["4a2c1c", "62391f", "7a4a28", "935c32", "aa6f3c", "be834a", "d09a5e", "e0b47a", "eccb98"])
	ROSE = hx(["5c2232", "7e3044", "a04458", "c05e6e", "d87e88", "eba4a8", "f6c8c8", "fde6e2"])
	SKYW = hx(["8ec8e8", "a8d8f0", "c4e6f6", "e2f4fc"])


func gen_cozy() -> void:
	_cozy_pal()
	gen_cozy_room()
	gen_cz_stove()
	gen_cz_counter()
	gen_cz_table()
	gen_cz_stool()
	gen_cz_wardrobe(false)
	gen_cz_wardrobe(true)
	gen_cz_bed()
	gen_cz_nightstand()
	gen_cz_barrel()
	gen_cz_fern()
	gen_cz_geranium()
	gen_cz_crate()
	gen_cz_basket()
	gen_cz_lights()
	gen_cz_armchair()
	gen_cz_sacks()


## Пучок сушёной травы на верёвочке: стебли вверху связаны, книзу метёлка листьев/цветов
func cz_bundle(im: Image, x: int, y: int, len: int, ramp: Array, flower: Color) -> void:
	rect(im, x, y, 1, 3, Color("8a6a4a"))
	rect(im, x - 1, y + 3, 3, 1, Color("c84a4a"))
	for k in range(len):
		var w: int = 1 + int(float(k) / float(len) * 3.0)
		for dx in range(-w, w + 1):
			var v: float = 0.35 + h01(x + dx, y + k, 11) * 0.45 - absf(float(dx)) * 0.08
			px(im, x + dx, y + 4 + k, pick(ramp, v, x, y))
	for f in range(4):
		var fx: int = x - 2 + int(h01(x, f, 13) * 5.0)
		var fy: int = y + 4 + len - 3 + int(h01(x, f, 14) * 3.0)
		px(im, fx, fy, flower)


## Банка на полке
func cz_jar(im: Image, x: int, y: int, w: int, h: int, c: Color, lid: Color) -> void:
	rect(im, x, y + 2, w, h - 2, c.darkened(0.3))
	rect(im, x + 1, y + 2, w - 2, h - 3, c)
	rect(im, x + 1, y + 3, 1, h - 5, c.lightened(0.45))
	rect(im, x, y, w, 2, lid)
	rect(im, x, y, w, 1, lid.lightened(0.3))
	rect(im, x + 1, y + h - 4, w - 2, 1, Color("f4ead6"))


## Цветок-горшочек (на подоконнике/полке): глиняный горшок и шапка цветов
func cz_pot(im: Image, cx: int, by: int, petal: Color) -> void:
	rect(im, cx - 3, by - 5, 7, 5, ORANGE[3])
	rect(im, cx - 4, by - 6, 9, 2, ORANGE[5])
	rect(im, cx - 3, by - 5, 1, 4, ORANGE[5])
	rect(im, cx + 3, by - 5, 1, 4, ORANGE[1])
	ell(im, cx + 0.5, by - 9.0, 4.0, 3.0, MINT[4])
	ell(im, cx - 0.5, by - 10.0, 2.6, 2.0, MINT[6])
	for k in range(5):
		var fx: int = cx - 3 + int(h01(cx, k, 3) * 7.0)
		var fy: int = by - 13 + int(h01(cx, k, 4) * 5.0)
		px(im, fx, fy, petal)
		px(im, fx + 1, fy, petal.darkened(0.15))
		px(im, fx, fy - 1, petal.lightened(0.3))


func gen_cozy_room() -> void:
	var im: Image = new_img(640, 360)
	rect(im, 0, 0, 640, 360, Color("1a1620"))
	# ---- пол: медовые доски, разной длины, с щелями и сучками
	var y: int = CZ_TOP
	var row: int = 0
	while y < CZ_BOT:
		var x: int = CZ_L - int(h01(row, 5, 2) * 30.0)
		while x < CZ_R:
			var ln: int = 34 + int(h01(x, row, 3) * 40.0)
			var tone: float = 0.42 + h01(x, row, 6) * 0.22
			for yy in range(y, mini(y + 8, CZ_BOT)):
				for xx in range(maxi(x, CZ_L), mini(x + ln, CZ_R)):
					var v: float = tone + sin(float(xx) * 0.17 + float(row) * 1.3) * 0.03
					if yy == y:
						v += 0.14
					elif yy == y + 7:
						v -= 0.32
					elif yy == y + 6:
						v -= 0.08
					if xx == x + ln - 1:
						v -= 0.3
					if h01(xx / 4, yy, row) > 0.93:
						v -= 0.12
					px(im, xx, yy, pick(WARM, v, xx, yy))
			# гвоздики на концах доски
			if x + ln - 3 > CZ_L and x + ln - 3 < CZ_R:
				px(im, x + ln - 3, y + 2, WARM[1])
				px(im, x + ln - 3, y + 5, WARM[1])
			x += ln
		y += 8
		row += 1
	# ---- задняя стена: потолочная балка, штукатурка с балками, деревянные панели внизу
	rect(im, 220, 88, 200, 10, WOOD[3])
	rect(im, 220, 88, 200, 2, WOOD[6])
	rect(im, 220, 96, 200, 2, WOOD[1])
	for y2 in range(98, 130):
		for x2 in range(CZ_L, CZ_R):
			var tv: float = 0.62 + (h01(x2 / 3, y2 / 3, 5) - 0.5) * 0.22 + (h01(x2, y2, 9) - 0.5) * 0.08
			px(im, x2, y2, pick(PLASTER, tv, x2, y2))
	for bx in [CZ_L, 262, 378, CZ_R - 6]:
		beam_v(im, int(bx), 98, 6, 32)
	beam_h(im, CZ_L, 128, CZ_R - CZ_L, 4)
	planks(im, CZ_L, 132, CZ_R - CZ_L, 14, WOOD, true, 7, 0.5, 23)
	rect(im, CZ_L, 132, CZ_R - CZ_L, 1, WOOD[7])
	rect(im, CZ_L, 144, CZ_R - CZ_L, 2, WOOD[2])
	# ---- боковые и передняя стенки (толстые тёмные балки)
	for s in [Rect2i(220, 88, 8, 202), Rect2i(CZ_R, 88, 8, 202)]:
		var r: Rect2i = s
		rect(im, r.position.x, r.position.y, r.size.x, r.size.y, WOOD[3])
		rect(im, r.position.x, r.position.y, 2, r.size.y, WOOD[5])
		rect(im, r.end.x - 2, r.position.y, 2, r.size.y, WOOD[1])
		for yk in range(r.position.y + 10, r.end.y, 26):
			rect(im, r.position.x + 1, yk, r.size.x - 2, 1, WOOD[2])
	rect(im, 220, CZ_BOT, 200, 8, WOOD[2])
	rect(im, 220, CZ_BOT, 200, 2, WOOD[5])
	rect(im, 220, CZ_BOT + 6, 200, 2, WOOD[0])
	# ---- тени у стен ступеньками
	for x3 in range(CZ_L, CZ_R):
		for k3 in range(5):
			dim_px(im, x3, CZ_TOP + k3, [0.30, 0.24, 0.18, 0.12, 0.06][k3])
	for y4 in range(CZ_TOP, CZ_BOT):
		for k4 in range(4):
			var a4: float = [0.26, 0.18, 0.11, 0.05][k4]
			dim_px(im, CZ_L + k4, y4, a4)
			dim_px(im, CZ_R - 1 - k4, y4, a4)
	# ---- ковёр в центре: овальный, плетёный, розово-кремовый с узором
	# ---- дверь: проём на улицу, косяки, коврик с цветком
	rect(im, 306, CZ_BOT, 28, 8, Color("a8cf88"))
	rect(im, 306, CZ_BOT, 28, 2, Color("7cae6a"))
	px(im, 310, CZ_BOT + 4, Color("f6c8d0"))
	px(im, 327, CZ_BOT + 5, Color("f6e08a"))
	px(im, 318, CZ_BOT + 6, Color("f8f4e8"))
	beam_v(im, 302, CZ_BOT - 6, 4, 14)
	beam_v(im, 334, CZ_BOT - 6, 4, 14)
	save3(im, "interior_floor", false)


func _cz_window(im: Image, cx: int, y0: int) -> void:
	var w: int = 34
	var h: int = 24
	var x0: int = cx - w / 2
	rect(im, x0 - 3, y0 - 3, w + 6, h + 6, WOOD[2])
	rect(im, x0 - 3, y0 - 3, w + 6, 1, WOOD[5])
	# небо, листва, луг, тропинка
	for yy in range(y0, y0 + h):
		for xx in range(x0, x0 + w):
			var t: float = float(yy - y0) / float(h)
			var c: Color = SKYW[clampi(int(t * 6.0), 0, 3)]
			if yy > y0 + 9:
				c = GRASS[clampi(4 + (yy - y0 - 10) / 4, 0, 8)]
			elif yy > y0 + 5 and h01(xx / 2, 3, 8) > 0.35:
				c = LEAF_GREEN[1 + int(h01(xx, yy, 4) * 2.0)]
			px(im, xx, yy, c)
	for k in range(3):
		ell(im, float(x0 + 5 + k * 12), float(y0 + 6), 5.0, 3.5, LEAF_DEEP[2 + (k % 2)])
		ell(im, float(x0 + 4 + k * 12), float(y0 + 5), 2.5, 1.5, LEAF_DEEP[4])
	for i in range(9):
		var fx: int = x0 + 1 + int(h01(i, cx, 3) * float(w - 2))
		var fy: int = y0 + 12 + int(h01(i, cx, 4) * 10.0)
		px(im, fx, fy, [ROSE[5], Color("f8f4e8"), GOLD[5]][i % 3])
	# солнечный блик в стекле
	for d in range(5):
		px(im, x0 + 2 + d, y0 + 6 - d, Color(1, 1, 1, 0.75))
		px(im, x0 + 4 + d, y0 + 6 - d, Color(1, 1, 1, 0.4))
	# рама: крестовина ровно посередине проёма
	rect(im, cx - 1, y0, 2, h, WOOD[5])
	rect(im, x0, y0 + h / 2 - 1, w, 2, WOOD[5])
	rect(im, cx - 1, y0, 1, h, WOOD[7])
	rect(im, x0, y0 + h / 2 - 1, w, 1, WOOD[7])
	# подоконник с горшочками
	rect(im, x0 - 6, y0 + h + 2, w + 12, 3, WOOD[6])
	rect(im, x0 - 6, y0 + h + 2, w + 12, 1, WOOD[8])
	rect(im, x0 - 6, y0 + h + 5, w + 12, 1, WOOD[2])
	cz_pot(im, cx - 10, y0 + h + 2, ROSE[4])
	cz_pot(im, cx + 1, y0 + h + 2, Color("f8f4e8"))
	cz_pot(im, cx + 11, y0 + h + 2, GOLD[5])
	# кружевные занавески, подвязанные лентами
	for side in [-1, 1]:
		var sx: int = cx + int(side) * (w / 2 + 1)
		for yy2 in range(y0 - 4, y0 + h + 1):
			var t2: float = float(yy2 - y0 + 4) / float(h + 5)
			var pinch: float = 1.0 - 0.55 * exp(-pow((t2 - 0.55) * 4.0, 2.0))
			var cw: int = int(round(7.0 * pinch))
			for k2 in range(cw):
				var xx2: int = sx + (k2 if side > 0 else -k2)
				var v2: float = 0.55 + (0.25 if k2 % 3 == 0 else 0.0) - float(k2) * 0.03
				px(im, xx2, yy2, pick(CREAM, v2, xx2, yy2))
			var edge: int = sx + (cw if side > 0 else -cw)
			if (yy2 % 2) == 0:
				px(im, edge, yy2, CREAM[4])
		var ty: int = y0 + int(0.55 * float(h + 5)) - 4
		rect(im, sx + (0 if side > 0 else -3), ty, 4, 2, ROSE[3])
		px(im, sx + (1 if side > 0 else -2), ty, ROSE[5])
	# карниз
	rect(im, x0 - 10, y0 - 6, w + 20, 2, WOOD[6])
	disc(im, x0 - 10.5, y0 - 5.0, 1.6, GOLD[4])
	disc(im, x0 + w + 10.5, y0 - 5.0, 1.6, GOLD[4])


func _cz_rug(im: Image, cx: int, cy: int, rx: int, ry: int) -> void:
	for yy in range(cy - ry - 1, cy + ry + 2):
		for xx in range(cx - rx - 1, cx + rx + 2):
			var dx: float = (xx + 0.5 - cx) / float(rx)
			var dy: float = (yy + 0.5 - cy) / float(ry)
			var d: float = sqrt(dx * dx + dy * dy)
			if d > 1.0:
				continue
			var ring: int = int(d * 7.0)
			var c: Color = [CREAM[3], ROSE[4], ROSE[3], CREAM[2], ROSE[5], ROSE[2], ROSE[1]][ring]
			# плетёнка: косые стежки
			if (xx + yy * 2) % 4 == 0:
				c = c.darkened(0.08)
			px(im, xx, yy, c)
	for k in range(14):
		var a: float = float(k) / 14.0 * TAU
		px(im, int(cx + cos(a) * rx * 0.62), int(cy + sin(a) * ry * 0.62), GOLD[5])
	for k2 in range(6):
		var a2: float = float(k2) / 6.0 * TAU
		var fx: int = int(cx + cos(a2) * 6.0)
		var fy: int = int(cy + sin(a2) * 3.0)
		px(im, fx, fy, ROSE[6])
	px(im, cx, cy, GOLD[5])
	# кисточки по краям
	for side in [-1, 1]:
		for yy2 in range(cy - 4, cy + 5, 2):
			px(im, cx + int(side) * (rx + 1), yy2, CREAM[2])


## Чугунная печка с трубой до потолка, чайник, огонь за решёткой
func gen_cz_stove() -> void:
	var im: Image = new_img(30, 62)
	# труба
	rect(im, 12, 0, 6, 30, IRON[2])
	rect(im, 12, 0, 2, 30, IRON[4])
	rect(im, 17, 0, 1, 30, IRON[0])
	rect(im, 11, 12, 8, 2, IRON[3])
	rect(im, 11, 26, 8, 3, IRON[3])
	# плита
	rect(im, 1, 30, 28, 6, IRON[4])
	rect(im, 1, 30, 28, 1, IRON[5])
	ell(im, 8, 33, 4, 1.5, IRON[1])
	# чайник (медный)
	ell(im, 20, 29, 5, 3.5, Color("b8643a"))
	ell(im, 19, 28, 3, 2, Color("e09a5e"))
	rect(im, 19, 24, 3, 2, Color("8a4a2a"))
	line(im, 24, 28, 27, 25, Color("8a4a2a"))
	px(im, 18, 27, Color("ffe0b0"))
	# корпус
	rect(im, 2, 36, 26, 20, IRON[2])
	rect(im, 2, 36, 26, 1, IRON[4])
	rect(im, 2, 36, 1, 20, IRON[3])
	rect(im, 27, 36, 1, 20, IRON[0])
	# дверца с огнём
	rect(im, 7, 39, 16, 11, IRON[0])
	rect(im, 8, 40, 14, 9, ORANGE[1])
	rect(im, 8, 44, 14, 5, ORANGE[3])
	ell(im, 15, 46, 5, 2.5, ORANGE[5])
	ell(im, 14, 47, 3, 1.5, ORANGE[7])
	for bx in [11, 15, 19]:
		rect(im, int(bx), 40, 1, 9, IRON[1])
	rect(im, 7, 39, 16, 1, IRON[4])
	rect(im, 21, 43, 2, 3, GOLD[3])
	# зольник и ножки
	rect(im, 4, 52, 22, 3, IRON[1])
	rect(im, 12, 53, 6, 1, IRON[4])
	rect(im, 3, 56, 3, 6, IRON[1])
	rect(im, 24, 56, 3, 6, IRON[1])
	outline_auto(im, 0.6)
	save3(im, "cz_stove", false)


## Кухонный шкафчик: каменная столешница, раковина с краном, доска с морковкой
func gen_cz_counter() -> void:
	var im: Image = new_img(38, 34)
	rect(im, 0, 6, 38, 8, STONE[4])
	rect(im, 0, 6, 38, 1, STONE[6])
	rect(im, 0, 13, 38, 1, STONE[2])
	# раковина
	ell(im, 11, 10, 7, 2.6, PORCELAIN[1])
	ell(im, 11, 10, 6, 2.0, Color("5ea0c8"))
	px(im, 9, 9, Color("c8ecff"))
	rect(im, 10, 1, 2, 7, GOLD[3])
	rect(im, 10, 1, 5, 2, GOLD[4])
	px(im, 10, 1, GOLD[5])
	# доска с морковкой и пучком
	rect(im, 22, 7, 12, 5, WOOD[6])
	rect(im, 22, 7, 12, 1, WOOD[8])
	line(im, 24, 9, 29, 10, ORANGE[4])
	px(im, 23, 9, MINT[5])
	px(im, 22, 8, MINT[6])
	ell(im, 31, 9, 1.6, 1.0, MINT[5])
	# шкафчик
	planks(im, 0, 14, 38, 20, WOOD, true, 6, 0.5, 33)
	rect(im, 0, 14, 38, 1, WOOD[1])
	for dx in [2, 20]:
		var d0: int = int(dx)
		rect(im, d0, 16, 16, 15, WOOD[2])
		rect(im, d0 + 1, 17, 14, 13, WOOD[5])
		rect(im, d0 + 3, 19, 10, 9, WOOD[4])
		rect(im, d0 + 3, 19, 10, 1, WOOD[3])
		rect(im, d0 + 3, 27, 10, 1, WOOD[6])
	disc(im, 16.5, 23.5, 1.0, GOLD[4])
	disc(im, 22.5, 23.5, 1.0, GOLD[4])
	# полотенце в клетку
	rect(im, 30, 14, 5, 9, ROSE[5])
	for k in range(9):
		if k % 3 == 1:
			rect(im, 30, 14 + k, 5, 1, ROSE[3])
	rect(im, 32, 14, 1, 9, ROSE[3])
	outline_auto(im, 0.6)
	save3(im, "cz_counter", false)


## Круглый столик со скатертью: чайник, чашки, вазочка с цветами, свеча
func gen_cz_table() -> void:
	var im: Image = new_img(34, 30)
	ell(im, 17, 10, 16, 7, CREAM[2])
	ell(im, 17, 9, 15, 6, CREAM[3])
	# кружевной край скатерти
	for x in range(2, 33):
		var t: float = (x + 0.5 - 17.0) / 16.0
		var yb: int = int(10.0 + sqrt(maxf(0.0, 1.0 - t * t)) * 7.0)
		rect(im, x, yb, 1, 3 + (x % 2), CREAM[3] if x % 3 != 0 else CREAM[4])
	# ножка-тумба
	rect(im, 14, 18, 6, 9, WOOD[3])
	rect(im, 14, 18, 2, 9, WOOD[5])
	ell(im, 17, 27, 7, 2, WOOD[2])
	# чайник
	ell(im, 11, 8, 4, 3, ROSE[5])
	ell(im, 10, 7, 2, 1.5, ROSE[6])
	rect(im, 10, 4, 3, 1, ROSE[3])
	line(im, 15, 7, 17, 5, ROSE[3])
	# чашки
	ell(im, 20, 10, 2, 1.2, PORCELAIN[4])
	px(im, 20, 10, Color("a86a3a"))
	ell(im, 25, 7, 2, 1.2, PORCELAIN[4])
	px(im, 25, 7, Color("a86a3a"))
	# вазочка с ромашками
	rect(im, 26, 9, 3, 4, Color("6aa0c8"))
	px(im, 26, 9, Color("a8d0ec"))
	for f in [Vector2i(25, 6), Vector2i(28, 5), Vector2i(27, 3), Vector2i(29, 7)]:
		var fv: Vector2i = f
		px(im, fv.x, fv.y, Color("f8f4e8"))
		px(im, fv.x, fv.y - 1, Color("f8f4e8"))
		px(im, fv.x + 1, fv.y, GOLD[5])
	# свеча на блюдце
	ell(im, 17, 6, 2.5, 1, GOLD[3])
	rect(im, 16, 1, 2, 5, CREAM[4])
	px(im, 16, 0, ORANGE[6])
	px(im, 17, 0, GOLD[5])
	outline_auto(im, 0.6)
	save3(im, "cz_table", false)


func gen_cz_stool() -> void:
	var im: Image = new_img(12, 15)
	ell(im, 6, 4, 5, 3, WOOD[6])
	ell(im, 6, 3.5, 4, 2, WOOD[7])
	ell(im, 6, 3.5, 2.5, 1, ROSE[4])
	rect(im, 1, 5, 10, 2, WOOD[3])
	rect(im, 2, 7, 2, 8, WOOD[2])
	rect(im, 8, 7, 2, 8, WOOD[2])
	rect(im, 2, 7, 1, 8, WOOD[4])
	rect(im, 8, 7, 1, 8, WOOD[4])
	rect(im, 3, 11, 6, 1, WOOD[3])
	outline_auto(im, 0.6)
	save3(im, "cz_stool", false)


## Шкаф с резной верхушкой и расписными дверцами (открытый — плащ, рубашка, корзина)
func gen_cz_wardrobe(open: bool) -> void:
	var im: Image = new_img(32, 58)
	rect(im, 2, 6, 28, 48, WOOD[2])
	# резной верх
	rect(im, 1, 3, 30, 4, WOOD[5])
	rect(im, 1, 3, 30, 1, WOOD[7])
	ell(im, 16, 3, 7, 3, WOOD[5])
	ell(im, 16, 2.5, 5, 2, WOOD[6])
	disc(im, 16, 2.5, 1.2, GOLD[4])
	rect(im, 1, 52, 30, 3, WOOD[3])
	rect(im, 1, 52, 30, 1, WOOD[5])
	rect(im, 3, 55, 3, 3, WOOD[2])
	rect(im, 26, 55, 3, 3, WOOD[2])
	if not open:
		for dx in [3, 16]:
			var d0: int = int(dx)
			rect(im, d0, 8, 13, 43, WOOD[4])
			rect(im, d0, 8, 13, 1, WOOD[6])
			rect(im, d0, 8, 1, 43, WOOD[6])
			rect(im, d0 + 12, 8, 1, 43, WOOD[2])
			rect(im, d0 + 2, 11, 9, 16, WOOD[3])
			rect(im, d0 + 2, 11, 9, 1, WOOD[2])
			rect(im, d0 + 2, 31, 9, 17, WOOD[3])
			rect(im, d0 + 2, 31, 9, 1, WOOD[2])
			# расписной цветочек на дверце
			var fx: int = d0 + 6
			px(im, fx, 18, ROSE[4])
			px(im, fx - 1, 19, ROSE[4])
			px(im, fx + 1, 19, ROSE[4])
			px(im, fx, 20, ROSE[4])
			px(im, fx, 19, GOLD[5])
			px(im, fx - 2, 21, MINT[5])
			px(im, fx + 2, 21, MINT[5])
		rect(im, 14, 29, 1, 4, GOLD[4])
		rect(im, 17, 29, 1, 4, GOLD[4])
	else:
		rect(im, 3, 8, 26, 43, Color("1c120d"))
		rect(im, 3, 8, 26, 2, Color("2e1c14"))
		rect(im, 4, 11, 24, 1, IRON[4])
		rect(im, 6, 12, 8, 20, Color("2e6a5e"))
		rect(im, 6, 12, 8, 1, Color("5eaea2"))
		rect(im, 16, 12, 7, 14, CREAM[3])
		rect(im, 16, 12, 7, 1, CREAM[4])
		rect(im, 3, 36, 26, 2, WOOD[4])
		rect(im, 6, 40, 10, 9, THATCH[3])
		rect(im, 6, 40, 10, 1, THATCH[5])
		rect(im, 0, 8, 3, 43, WOOD[4])
		rect(im, 29, 8, 3, 43, WOOD[4])
	outline_auto(im, 0.6)
	save3(im, "cz_wardrobe_open" if open else "cz_wardrobe", false)


## Кровать вдоль стены: резное изголовье, пухлая подушка, лоскутное одеяло, плед в ногах
func gen_cz_bed() -> void:
	var im: Image = new_img(36, 58)
	# изголовье
	rect(im, 0, 0, 36, 10, WOOD[3])
	rect(im, 0, 0, 36, 2, WOOD[6])
	ell(im, 18, 2, 10, 3, WOOD[4])
	ell(im, 18, 1.5, 8, 2, WOOD[6])
	disc(im, 18, 2, 1.5, ROSE[4])
	for p in [0, 32]:
		rect(im, int(p), 0, 4, 14, WOOD[4])
		rect(im, int(p), 0, 4, 1, WOOD[7])
		disc(im, float(p) + 2.0, 0.5, 2.0, WOOD[6])
	# матрас и простыня
	rect(im, 3, 9, 30, 42, CREAM[3])
	# подушка
	ell(im, 18, 15, 12, 4.5, CREAM[4])
	ell(im, 17, 14, 10, 3, Color("fffaf2"))
	for k in range(4):
		px(im, 9 + k * 6, 18, CREAM[2])
	# лоскутное одеяло
	var patch: Array = [ROSE[4], CREAM[3], Color("e8b86a"), ROSE[5], Color("8ab88a"), Color("c8a8dc")]
	for y in range(21, 48):
		for x in range(3, 33):
			var c: Color = patch[((x - 3) / 5 + ((y - 21) / 5) * 2) % patch.size()]
			if (x - 3) % 5 == 0 or (y - 21) % 5 == 0:
				c = c.darkened(0.18)
			if (x + y) % 7 == 0 and (x - 3) % 5 != 0:
				c = c.lightened(0.12)
			px(im, x, y, c)
	rect(im, 3, 21, 30, 2, CREAM[4])
	rect(im, 3, 23, 30, 1, CREAM[1])
	# свисающий край одеяла слева
	rect(im, 2, 22, 1, 26, ROSE[2])
	rect(im, 33, 22, 1, 26, ROSE[2])
	# плед в ногах
	rect(im, 3, 41, 30, 7, Color("6a8ab8"))
	for x2 in range(3, 33, 3):
		rect(im, x2, 41, 1, 7, Color("8aaad0"))
	rect(im, 3, 41, 30, 1, Color("a8c4e4"))
	# изножье
	rect(im, 0, 48, 36, 8, WOOD[3])
	rect(im, 0, 48, 36, 2, WOOD[6])
	for p2 in [0, 32]:
		rect(im, int(p2), 45, 4, 13, WOOD[4])
		rect(im, int(p2), 45, 4, 1, WOOD[7])
	rect(im, 6, 51, 24, 2, WOOD[2])
	outline_auto(im, 0.6)
	save3(im, "cz_bed", false)


## Тумбочка с фонариком-свечой и книжкой
func gen_cz_nightstand() -> void:
	var im: Image = new_img(16, 26)
	planks(im, 1, 12, 14, 12, WOOD, true, 5, 0.5, 61)
	rect(im, 0, 10, 16, 3, WOOD[6])
	rect(im, 0, 10, 16, 1, WOOD[8])
	rect(im, 3, 15, 10, 5, WOOD[4])
	rect(im, 3, 15, 10, 1, WOOD[2])
	disc(im, 8, 17.5, 0.9, GOLD[4])
	rect(im, 2, 24, 2, 2, WOOD[2])
	rect(im, 12, 24, 2, 2, WOOD[2])
	# книжка
	rect(im, 9, 8, 6, 2, Color("4a5a8a"))
	rect(im, 9, 8, 6, 1, Color("7a8aba"))
	# фонарик
	rect(im, 2, 3, 6, 7, IRON[2])
	rect(im, 3, 4, 4, 5, Color("f6d88a"))
	rect(im, 4, 5, 2, 3, Color("fff4c8"))
	rect(im, 2, 2, 6, 1, IRON[4])
	px(im, 4, 1, IRON[4])
	px(im, 5, 0, IRON[4])
	outline_auto(im, 0.6)
	save3(im, "cz_nightstand", false)


func gen_cz_barrel() -> void:
	var im: Image = new_img(20, 24)
	rect(im, 3, 6, 14, 15, WOOD[3])
	ell(im, 10, 21, 7, 2.5, WOOD[3])
	rect(im, 3, 6, 2, 15, WOOD[5])
	rect(im, 15, 6, 2, 15, WOOD[1])
	for sx in [7, 10, 13]:
		rect(im, int(sx), 6, 1, 15, WOOD[2])
	for hy in [9, 17]:
		rect(im, 3, int(hy), 14, 2, IRON[2])
		rect(im, 3, int(hy), 14, 1, IRON[4])
	ell(im, 10, 6, 7, 2.5, WOOD[6])
	ell(im, 10, 6, 5.5, 1.6, WOOD[7])
	# сверху — кувшин с молоком
	rect(im, 8, 1, 5, 5, PORCELAIN[3])
	rect(im, 8, 1, 1, 5, PORCELAIN[5])
	px(im, 13, 3, PORCELAIN[2])
	outline_auto(im, 0.6)
	save3(im, "cz_barrel", false)


func gen_cz_fern() -> void:
	var im: Image = new_img(22, 26)
	for k in range(9):
		var a: float = -PI * 0.95 + float(k) / 8.0 * PI * 0.9
		var ln: float = 8.0 + h01(k, 1, 2) * 3.0
		for s in range(int(ln)):
			var t: float = float(s) / ln
			var x: float = 11.0 + cos(a) * s
			var y: float = 14.0 + sin(a) * s * 0.9 + t * t * 4.0
			px(im, int(x), int(y), MINT[4 + int(t * 3.0)])
			if s % 2 == 0 and s > 1:
				px(im, int(x) + 1, int(y) + 1, MINT[3])
				px(im, int(x) - 1, int(y) + 1, MINT[5])
	rect(im, 6, 15, 10, 9, ORANGE[3])
	rect(im, 5, 14, 12, 3, ORANGE[5])
	rect(im, 5, 14, 12, 1, ORANGE[6])
	rect(im, 6, 17, 2, 7, ORANGE[5])
	rect(im, 14, 17, 2, 7, ORANGE[1])
	rect(im, 7, 24, 8, 1, ORANGE[1])
	outline_auto(im, 0.6)
	save3(im, "cz_fern", false)


func gen_cz_geranium() -> void:
	var im: Image = new_img(16, 20)
	ell(im, 8, 8, 6, 5, MINT[4])
	ell(im, 7, 7, 4, 3, MINT[6])
	for k in range(7):
		var fx: int = 3 + int(h01(k, 7, 3) * 10.0)
		var fy: int = 3 + int(h01(k, 7, 4) * 6.0)
		disc(im, fx + 0.5, fy + 0.5, 1.3, ROSE[3])
		px(im, fx, fy, ROSE[5])
	rect(im, 4, 12, 8, 7, Color("6a8ab8"))
	rect(im, 3, 11, 10, 2, Color("8aaad0"))
	rect(im, 4, 14, 8, 1, Color("f8f4e8"))
	rect(im, 4, 12, 1, 7, Color("a8c4e4"))
	outline_auto(im, 0.6)
	save3(im, "cz_geranium", false)


## Ящик с цветочными горшочками у стены
func gen_cz_crate() -> void:
	var im: Image = new_img(24, 22)
	rect(im, 1, 12, 22, 10, WOOD[4])
	rect(im, 1, 12, 22, 1, WOOD[6])
	rect(im, 1, 16, 22, 1, WOOD[2])
	rect(im, 1, 12, 1, 10, WOOD[6])
	rect(im, 22, 12, 1, 10, WOOD[1])
	cz_pot(im, 6, 13, Color("c8a8ec"))
	cz_pot(im, 12, 12, GOLD[5])
	cz_pot(im, 18, 13, ROSE[5])
	outline_auto(im, 0.6)
	save3(im, "cz_crate", false)


func gen_cz_basket() -> void:
	var im: Image = new_img(18, 16)
	ell(im, 9, 10, 8, 4, THATCH[2])
	rect(im, 1, 7, 16, 6, THATCH[3])
	for y in range(7, 14):
		for x in range(1, 17):
			if (x + y * 2) % 5 == 0:
				px(im, x, y, THATCH[1])
			elif (x + y * 2) % 5 == 2:
				px(im, x, y, THATCH[5])
	ell(im, 9, 6, 8, 2.5, THATCH[4])
	disc(im, 5.5, 5, 2.2, RED[3])
	disc(im, 10, 4, 2.2, RED[4])
	disc(im, 13.5, 5.5, 2.2, Color("c8a030"))
	px(im, 9, 3, RED[6])
	px(im, 5, 2, Color("5fa46a"))
	line(im, 3, 6, 9, 0, THATCH[2])
	line(im, 9, 0, 15, 6, THATCH[2])
	outline_auto(im, 0.6)
	save3(im, "cz_basket", false)


## Мягкие пятна света (рисуются сложением): круглое и полоса из окна
func gen_cz_lights() -> void:
	var g: Image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for y in range(64):
		for x in range(64):
			var d: float = Vector2(x + 0.5 - 32.0, y + 0.5 - 32.0).length() / 32.0
			var a: float = clampf(1.0 - d, 0.0, 1.0)
			a = a * a * (3.0 - 2.0 * a)
			# ступеньки, чтобы свет тоже был «пиксельный»
			a = floorf(a * 6.0) / 6.0
			g.set_pixel(x, y, Color(1, 1, 1, a))
	g.save_png(OUT + "cz_glow.png")


## Плющ, свисающий вниз от (x, y): листики по волне
func cz_ivy(im: Image, x: int, y: int, len: int, seed_v: int) -> void:
	for k in range(len):
		var xx: int = x + int(round(sin(float(k) * 0.45 + float(seed_v)) * 1.5))
		px(im, xx, y + k, MINT[2])
		if k % 3 == 0:
			var sd: int = 1 if (k / 3 + seed_v) % 2 == 0 else -1
			px(im, xx + sd, y + k, MINT[5])
			px(im, xx + sd * 2, y + k, MINT[4])
			px(im, xx + sd, y + k - 1, MINT[6])


## Подвесной горшок на верёвках с плющом
func cz_hang_pot(im: Image, cx: int, top: int, drop: int) -> void:
	line(im, cx - 4, top + drop, cx, top, Color("9a7a58"))
	line(im, cx + 4, top + drop, cx, top, Color("9a7a58"))
	var by: int = top + drop
	rect(im, cx - 4, by, 9, 5, ORANGE[3])
	rect(im, cx - 5, by - 1, 11, 2, ORANGE[5])
	rect(im, cx - 4, by, 1, 5, ORANGE[5])
	ell(im, cx + 0.5, by - 2.0, 5.0, 2.5, MINT[4])
	ell(im, cx - 0.5, by - 3.0, 3.0, 1.5, MINT[6])
	cz_ivy(im, cx - 4, by + 2, 12, 1)
	cz_ivy(im, cx + 4, by + 2, 8, 2)
	cz_ivy(im, cx, by + 4, 15, 3)


## Добавки к стене комнаты: плющ по балкам и подвесные горшки
func gen_cozy_room_extra() -> void:
	var im: Image = Image.load_from_file(ProjectSettings.globalize_path(OUT + "interior_floor.png"))
	cz_ivy(im, 231, 98, 26, 4)
	cz_ivy(im, 265, 98, 14, 5)
	cz_ivy(im, 381, 98, 18, 6)
	cz_ivy(im, CZ_R - 3, 98, 30, 7)
	cz_ivy(im, 223, 100, 60, 8)
	cz_ivy(im, CZ_R + 4, 100, 46, 9)
	cz_hang_pot(im, 296, 99, 9)
	cz_hang_pot(im, 352, 99, 7)
	im.save_png(OUT + "interior_floor.png")


## Кресло-«бабушкино»: розовая обивка, подушка, вязаный плед
func gen_cz_armchair() -> void:
	var im: Image = new_img(28, 30)
	# спинка
	rect(im, 3, 1, 22, 14, ROSE[2])
	ell(im, 14, 3, 11, 3, ROSE[3])
	rect(im, 5, 3, 18, 11, ROSE[3])
	for k in range(3):
		px(im, 8 + k * 6, 7, ROSE[1])
	# подлокотники
	rect(im, 0, 10, 6, 14, ROSE[2])
	rect(im, 0, 10, 6, 2, ROSE[4])
	rect(im, 22, 10, 6, 14, ROSE[1])
	rect(im, 22, 10, 6, 2, ROSE[3])
	# сиденье и подушка
	rect(im, 6, 14, 16, 8, ROSE[4])
	rect(im, 6, 14, 16, 1, ROSE[5])
	ell(im, 11, 12, 4, 3, Color("e8c46a"))
	ell(im, 11, 11.5, 3, 2, Color("f6dc8a"))
	# плед свисает справа
	rect(im, 16, 12, 7, 12, Color("6a8ab8"))
	for y in range(12, 24):
		if y % 2 == 0:
			rect(im, 16, y, 7, 1, Color("8aaad0"))
	rect(im, 16, 24, 7, 1, Color("4a6a98"))
	# юбка и ножки
	rect(im, 1, 22, 26, 4, ROSE[2])
	for x in range(1, 27, 2):
		px(im, x, 25, ROSE[1])
	rect(im, 2, 26, 2, 4, WOOD[2])
	rect(im, 24, 26, 2, 4, WOOD[2])
	outline_auto(im, 0.6)
	save3(im, "cz_armchair", false)


## Мешки с мукой и зерном
func gen_cz_sacks() -> void:
	var im: Image = new_img(22, 20)
	ell(im, 8, 13, 7, 6, CREAM[2])
	ell(im, 7, 12, 5, 4, CREAM[3])
	rect(im, 5, 5, 6, 3, CREAM[2])
	rect(im, 5, 7, 6, 1, Color("9a7a58"))
	px(im, 7, 13, Color("c8a050"))
	px(im, 8, 14, Color("c8a050"))
	ell(im, 16, 15, 5, 4.5, Color("c8a878"))
	ell(im, 15, 14, 3.5, 3, Color("dcc090"))
	rect(im, 14, 9, 4, 2, Color("c8a878"))
	rect(im, 14, 10, 4, 1, Color("8a6a4a"))
	outline_auto(im, 0.6)
	save3(im, "cz_sacks", false)


# ================================================================== открытый мир: земля биомов и карта

const WD = preload("res://world_data.gd")
const WT: int = 256            # сторона бесшовной плитки земли


## Плавный периодический шум на плитке WT x WT (сумма синусов с целыми частотами — плитка без швов)
func tile_noise(x: int, y: int, seed_v: int, lo: int, hi: int) -> float:
	var s: float = 0.0
	var tot: float = 0.0
	for k in range(7):
		var fx: int = lo + int(h01(k, seed_v, 31) * float(hi - lo + 1))
		var fy: int = lo + int(h01(k, seed_v, 37) * float(hi - lo + 1))
		if h01(k, seed_v, 41) < 0.5:
			fx = -fx
		var ph: float = h01(k, seed_v, 43) * TAU
		var amp: float = 1.0 / (1.0 + float(k) * 0.35)
		s += sin(TAU * (float(fx * x) + float(fy * y)) / float(WT) + ph) * amp
		tot += amp
	return s / tot


func _wpx(im: Image, x: int, y: int, c: Color) -> void:
	im.set_pixel(posmod(x, WT), posmod(y, WT), c)


func _wget(im: Image, x: int, y: int) -> Color:
	return im.get_pixel(posmod(x, WT), posmod(y, WT))


const BIOME_RAMP: Dictionary = {
	1: ["4f8a6a", "5f9a6e", "70aa72", "84b979", "98c780", "acd38a", "bfdd96", "d2e7a6", "e4f0bc"],
	2: ["2c2a3e", "36344c", "42405a", "4e4e68", "5c5c76", "6c6e86", "7e8296", "9298a8", "a8b0bc"],
	3: ["2e2830", "3a3238", "463e42", "544a4c", "625856", "726660", "847670", "988a80", "ae9e92"],
	4: ["4a8456", "5a9660", "6ca866", "80b86c", "94c672", "a8d27c", "bcdc8a", "d0e69c", "e2f0b2"],
	5: ["1e5a52", "25685a", "2c7862", "358a6a", "409c72", "4eae7c", "62c088", "7ed09a", "a2e0b2"],
	6: ["44487a", "4e5488", "5a6296", "6870a4", "7a80b2", "8c92be", "a0a6ca", "b6bad8", "cccee6"],
	7: ["7a5e36", "8a6c3c", "9a7a44", "aa8a4e", "ba9a5a", "c8aa68", "d4ba7a", "e0ca90", "ead8a8"],
	8: ["44403e", "524c48", "605a54", "6e6860", "7e766c", "8e867a", "a0988a", "b2aa9c", "c4bcb0"],
	9: ["5a8a5e", "6c9c62", "80ae68", "96bf6e", "acd078", "c0dc84", "d2e694", "e2eeaa", "f0f6c4"],
	10: ["8a5a7a", "a06a8a", "b87c9c", "cc90ae", "dca4be", "e8b8cc", "f0cad8", "f6dce6", "fbeef2"],
	11: ["222030", "2a2a3c", "343448", "403e56", "4c4a64", "5a5872", "6a6882", "7c7a92", "908ea4"],
	12: ["5e8a4e", "70a056", "84b260", "98c26a", "acd076", "bedc84", "cee696", "deeeaa", "ecf6c2"],
	13: ["1e3a30", "264836", "2e563c", "386644", "44764c", "528658", "649668", "78a87a", "8eba8e"],
	14: ["7a4a26", "8e5a2e", "a26c36", "b67e40", "c8904c", "d6a25a", "e2b46c", "ecc684", "f4d8a0"],
	15: ["2a3a2e", "334636", "3c5240", "465e48", "526a52", "5e765c", "6c8468", "7c9276", "8ea286"],
	16: ["7a8a3a", "8e9e42", "a2b04a", "b4c056", "c4cc62", "d2d870", "dee282", "e8ea98", "f2f2b2"],
	17: ["3e6a46", "4a7a4e", "588a56", "6a9a5e", "7caa68", "8eb874", "a2c684", "b8d498", "cce2b0"],
	18: ["b8a070", "c8b07e", "d6be8c", "e2ca9a", "ead4a8", "f0deb6", "f6e8c4", "faf0d4", "fdf8e6"],
	19: ["1e4a7a", "245688", "2a6296", "326ea4", "3c7cb2", "4a8ac0", "5e9ccc", "78b0d8", "98c6e4"],
}


func gen_world() -> void:
	for b in BIOME_RAMP.keys():
		gen_world_tile(int(b))
	gen_road_tile()
	# все плитки — в один столбец (атлас): 0-я — луг, дальше по номерам биомов
	var atlas: Image = new_img(WT, WT * WD.BIOMES)
	for bi in range(WD.BIOMES):
		var tile: Image = Image.load_from_file(ProjectSettings.globalize_path(OUT + "wt_%d.png" % maxi(1, bi)))
		tile.convert(Image.FORMAT_RGBA8)
		atlas.blit_rect(tile, Rect2i(0, 0, WT, WT), Vector2i(0, bi * WT))
	atlas.save_png(ProjectSettings.globalize_path(OUT + "wt_atlas.png"))
	gen_world_maps()


## Плитка земли биома: тот же приём, что у двора (тон по шуму + травинки + мелочи по биому)
func gen_world_tile(biome: int) -> void:
	var ramp: Array = hx(BIOME_RAMP[biome])
	var im: Image = new_img(WT, WT)
	rng.seed = 700 + biome
	for y in range(WT):
		for x in range(WT):
			var v: float = 0.50 + tile_noise(x, y, biome, 1, 3) * 0.20 + tile_noise(x, y, biome + 50, 6, 12) * 0.07 + tile_noise(x, y, biome + 90, 20, 34) * 0.035
			im.set_pixel(x, y, pick(ramp, v, x, y))
	if biome == 18:
		# песок пляжа: мягкая ветровая рябь, без крупных полос
		for y in range(WT):
			for x in range(WT):
				var wob: float = sin(float(x) * TAU / float(WT) * 3.0) * 7.0 + sin(float(x) * TAU / float(WT) * 5.0 + 1.0) * 3.0
				var rip: float = sin((float(y) + wob) * TAU * round(float(WT) / 14.0) / float(WT))
				var v2: float = 0.56 + tile_noise(x, y, 118, 2, 6) * 0.06 + rip * 0.05
				if rip > 0.9:
					v2 += 0.05
				im.set_pixel(x, y, pick(ramp, v2, x, y))
	# травинки-кустики (как во дворе)
	var tufts: int = 3400 if biome != 8 else 1400
	if biome == 18 or biome == 19:
		tufts = 0
	if biome == 7:
		tufts = 2200
	for i in range(tufts):
		var x: int = rng.randi_range(0, WT - 1)
		var y: int = rng.randi_range(0, WT - 1)
		var base: Color = _wget(im, x, y)
		var hi: Color = base.lightened(0.15)
		var hi2: Color = base.lightened(0.28)
		var lo: Color = base.darkened(0.18)
		if biome == 7:
			# сухая степь: жёлтые сухие стебли
			hi = Color("e0c47a")
			hi2 = Color("f0dc9c")
		match rng.randi_range(0, 4):
			0:
				_wpx(im, x, y, hi2)
				_wpx(im, x, y + 1, hi)
				_wpx(im, x, y + 2, base)
				_wpx(im, x - 1, y + 1, hi)
				_wpx(im, x - 2, y, hi)
				_wpx(im, x + 1, y + 1, hi)
				_wpx(im, x + 2, y + 1, hi)
				_wpx(im, x, y + 3, lo)
				_wpx(im, x - 1, y + 3, lo)
				_wpx(im, x + 1, y + 3, lo)
			1:
				_wpx(im, x, y, hi)
				_wpx(im, x, y + 1, hi)
				_wpx(im, x + 1, y + 2, hi)
				_wpx(im, x + 1, y + 3, lo)
			2:
				_wpx(im, x, y, hi2)
				_wpx(im, x + 1, y + 1, hi)
				_wpx(im, x - 1, y + 1, hi)
				_wpx(im, x, y + 2, lo)
			3:
				_wpx(im, x, y, lo)
				_wpx(im, x + 1, y, lo)
			_:
				_wpx(im, x, y, hi)
				_wpx(im, x - 1, y - 1, hi2)
				_wpx(im, x + 1, y - 2, hi)
				_wpx(im, x, y + 1, lo)
	# v19: болото — лужицы с бликами и пятна ила
	if biome == 15:
		var bog: Array = hx(BOG7)
		var mud: Array = hx(MUD7)
		for i3 in range(46):
			var mx: int = rng.randi_range(0, WT - 1)
			var my: int = rng.randi_range(0, WT - 1)
			var mrx: float = rng.randf_range(4.0, 11.0)
			var mry: float = mrx * 0.5
			var water: bool = i3 % 3 != 0
			for yy in range(int(-mry) - 1, int(mry) + 2):
				for xx in range(int(-mrx) - 1, int(mrx) + 2):
					var dd: float = (float(xx) / mrx) * (float(xx) / mrx) + (float(yy) / mry) * (float(yy) / mry)
					if dd > 1.0:
						continue
					var col: Color
					if water:
						col = bog[4] if dd < 0.55 else (bog[5] if yy < 0 else bog[3])
						if yy == 0 and xx > -int(mrx * 0.4) and xx < int(mrx * 0.2):
							col = bog[7]
						if dd > 0.8:
							col = mud[3] if yy > 0 else mud[4]
					else:
						col = mud[3] if dd < 0.5 else (mud[4] if yy < 0 else mud[2])
					_wpx(im, mx + xx, my + yy, col)
	# клевер на зелёных лугах
	if biome in [1, 4, 9, 5]:
		for i in range(70):
			var x2: int = rng.randi_range(0, WT - 1)
			var y2: int = rng.randi_range(0, WT - 1)
			var b2: Color = _wget(im, x2, y2)
			for o in [Vector2i(0, -1), Vector2i(-1, 1), Vector2i(1, 1)]:
				var op: Vector2i = o
				_wpx(im, x2 + op.x * 2, y2 + op.y * 2, b2.darkened(0.12))
				_wpx(im, x2 + op.x * 2 + 1, y2 + op.y * 2, b2.lightened(0.10))
				_wpx(im, x2 + op.x * 2, y2 + op.y * 2 + 1, b2.darkened(0.22))
	# мелочи по биому
	var fl: Array = []
	var nfl: int = 0
	match biome:
		1, 4:
			fl = [hx(["d8d0c0", "f6f0e4", "ffffff"]), hx(["d87a98", "f2a2bc", "fcd2e0"]), hx(["7a86d8", "a0b0f0", "d0d8fc"]), hx(["d8a02a", "f2cc48", "fff0a0"])]
			nfl = 120
		9:
			fl = [hx(["d87a98", "f2a2bc", "fcd2e0"]), hx(["e89ab8", "fcc4d8", "fff0f6"]), hx(["d8d0c0", "f6f0e4", "ffffff"]), hx(["d8a02a", "f2cc48", "fff0a0"])]
			nfl = 210
		5:
			fl = [hx(["3a9ab8", "6cd4e8", "c8f8ff"]), hx(["c8a030", "f2d460", "fff6c0"]), hx(["d8d0c0", "f6f0e4", "ffffff"])]
			nfl = 140
		6:
			fl = [hx(["6a5ab8", "a08cf0", "e0d8ff"]), hx(["3a8ab8", "7cc8f0", "d8f4ff"])]
			nfl = 90
		3:
			fl = [hx(["5a1420", "9a2030", "d04050"])]
			nfl = 40
		2:
			fl = [hx(["4a3a6a", "7a5aa0", "b494d8"])]
			nfl = 50
		10:
			fl = [hx(["d87ab8", "f4a8d8", "ffe0f4"]), hx(["a8d8ff", "d0ecff", "ffffff"]), hx(["f0c860", "fce890", "fffbe0"])]
			nfl = 260
		12:
			fl = [hx(["d8d0c0", "f6f0e4", "ffffff"]), hx(["d8a02a", "f2cc48", "fff0a0"])]
			nfl = 110
		16:
			fl = [hx(["d8a02a", "f2cc48", "fff0a0"]), hx(["c03030", "e85050", "ff9090"]), hx(["7a86d8", "a0b0f0", "d0d8fc"]), hx(["d8d0c0", "f6f0e4", "ffffff"])]
			nfl = 320
		14:
			fl = [hx(["a03a1a", "d0602a", "f09a4a"]), hx(["c89a2a", "e8c248", "fff090"])]
			nfl = 260
		11:
			fl = [hx(["3a8ab8", "6cd4e8", "c8f8ff"])]
			nfl = 50
		17:
			fl = [hx(["e88aa8", "f8b8cc", "ffe4ee"]), hx(["f0a0b8", "fcd0de", "ffffff"])]   # лепестки сакуры
			nfl = 380
	for i in range(nfl):
		var x3: int = rng.randi_range(0, WT - 1)
		var y3: int = rng.randi_range(0, WT - 1)
		var fs: Array = fl[rng.randi_range(0, fl.size() - 1)]
		_wpx(im, x3, y3 + 2, _wget(im, x3, y3 + 2).darkened(0.25))
		if rng.randf() < 0.35:
			_wpx(im, x3, y3 - 1, fs[1])
			_wpx(im, x3 - 1, y3, fs[1])
			_wpx(im, x3 + 1, y3, fs[2])
			_wpx(im, x3, y3 + 1, fs[0])
			_wpx(im, x3, y3, Color("f6d24a"))
		else:
			_wpx(im, x3, y3, fs[2])
			_wpx(im, x3 + 1, y3, fs[1])
			_wpx(im, x3, y3 + 1, fs[0])
	if biome == 19:
		for i in range(140):
			var wx: int = rng.randi_range(0, WT - 1)
			var wy: int = rng.randi_range(0, WT - 1)
			for k in range(rng.randi_range(3, 7)):
				_wpx(im, wx + k, wy + int(sin(k * 0.9) * 1.2), Color("b8dcf0") if k % 3 != 0 else Color("e0f2fa"))
	if biome == 18:
		for i in range(90):
			var sx: int = rng.randi_range(0, WT - 1)
			var sy: int = rng.randi_range(0, WT - 1)
			_wpx(im, sx, sy, [Color("f8f0e8"), Color("f0b8a8"), Color("c8a888"), Color("e8d8c0")][rng.randi_range(0, 3)])
			_wpx(im, sx + 1, sy, Color("fffaf4"))
	match biome:
		2:
			# паутинки-нити по земле и опавшие тёмные листья
			for i in range(26):
				var a0: Vector2 = Vector2(rng.randf_range(0, WT), rng.randf_range(0, WT))
				var ang: float = rng.randf() * TAU
				var ln: int = rng.randi_range(8, 22)
				for k in range(ln):
					var pp: Vector2 = a0 + Vector2(cos(ang), sin(ang) * 0.5) * k
					var bc: Color = _wget(im, int(pp.x), int(pp.y))
					_wpx(im, int(pp.x), int(pp.y), bc.lerp(Color("dfe4f0"), 0.45 if k % 3 != 0 else 0.7))
			for i in range(160):
				var lx: int = rng.randi_range(0, WT - 1)
				var ly: int = rng.randi_range(0, WT - 1)
				var lc: Color = [Color("4a3a52"), Color("5a4458"), Color("3a3446")][rng.randi_range(0, 2)]
				_wpx(im, lx, ly, lc)
				_wpx(im, lx + 1, ly, lc.darkened(0.2))
		3:
			# сухие листья и серые камешки
			for i in range(200):
				var lx2: int = rng.randi_range(0, WT - 1)
				var ly2: int = rng.randi_range(0, WT - 1)
				var lc2: Color = [Color("6a3a2a"), Color("7a5a3a"), Color("504040"), Color("8a6a4a")][rng.randi_range(0, 3)]
				_wpx(im, lx2, ly2, lc2)
				_wpx(im, lx2 + 1, ly2, lc2.darkened(0.25))
				_wpx(im, lx2, ly2 + 1, lc2.darkened(0.4))
		5:
			# светящиеся точки-споры
			for i in range(60):
				var sx: int = rng.randi_range(0, WT - 1)
				var sy: int = rng.randi_range(0, WT - 1)
				_wpx(im, sx, sy, Color("e8fff0"))
				_wpx(im, sx + 1, sy, Color("8ee8c0"))
				_wpx(im, sx, sy + 1, Color("8ee8c0"))
		6:
			# крошечные кристаллы
			for i in range(40):
				var cx2: int = rng.randi_range(0, WT - 1)
				var cy2: int = rng.randi_range(0, WT - 1)
				var cc: Array = [hx(["2a4a8a", "4a8ad8", "a8e0ff", "ffffff"]), hx(["5a2a8a", "9a5ad8", "d8b0ff", "ffffff"])][rng.randi_range(0, 1)]
				_wpx(im, cx2, cy2 - 2, cc[3])
				_wpx(im, cx2, cy2 - 1, cc[2])
				_wpx(im, cx2 + 1, cy2 - 1, cc[1])
				_wpx(im, cx2, cy2, cc[1])
				_wpx(im, cx2 + 1, cy2, cc[0])
				_wpx(im, cx2 - 1, cy2 + 1, _wget(im, cx2 - 1, cy2 + 1).darkened(0.3))
				_wpx(im, cx2, cy2 + 1, _wget(im, cx2, cy2 + 1).darkened(0.3))
		7, 8:
			# камешки и трещины
			for i in range(110 if biome == 8 else 60):
				var px2: int = rng.randi_range(0, WT - 1)
				var py2: int = rng.randi_range(0, WT - 1)
				var st: Array = hx(["4a4450", "6a6470", "8e8894", "b4b0b6"]) if biome == 8 else hx(["6a5034", "8a7050", "a89070", "c8b090"])
				_wpx(im, px2, py2 + 1, st[0])
				_wpx(im, px2 + 1, py2 + 1, st[0])
				_wpx(im, px2, py2, st[2])
				_wpx(im, px2 + 1, py2, st[1])
				if rng.randf() < 0.4:
					_wpx(im, px2 - 1, py2, st[3])
	save(im, "wt_%d" % biome, false)


func gen_road_tile() -> void:
	var im: Image = new_img(WT, WT)
	rng.seed = 777
	for y in range(WT):
		for x in range(WT):
			var v: float = 0.58 + tile_noise(x, y, 77, 2, 5) * 0.12 + tile_noise(x, y, 78, 14, 30) * 0.06
			im.set_pixel(x, y, pick(SAND, v, x, y))
	for i in range(700):
		var x: int = rng.randi_range(0, WT - 1)
		var y: int = rng.randi_range(0, WT - 1)
		var r: float = rng.randf()
		if r < 0.55:
			_wpx(im, x, y + 1, SAND[1])
			_wpx(im, x + 1, y + 1, SAND[1])
			_wpx(im, x, y, SAND[4])
			_wpx(im, x + 1, y, SAND[3])
		elif r < 0.8:
			_wpx(im, x, y + 1, STONE[1])
			_wpx(im, x + 1, y + 1, STONE[1])
			_wpx(im, x, y, STONE[4])
			_wpx(im, x + 1, y, STONE[3])
			_wpx(im, x - 1, y, STONE[2])
		else:
			_wpx(im, x, y, SAND[2])
	save(im, "wt_road", false)


## Карта биомов (R — номер биома, G — дорога) и пергаментная карта мира для экрана M
func gen_world_maps() -> void:
	var w: int = int(WD.SIZE.x) / WD.CELL
	var h: int = int(WD.SIZE.y) / WD.CELL
	var bm: Image = Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	var biome: PackedByteArray = PackedByteArray()
	biome.resize(w * h)
	var road: PackedByteArray = PackedByteArray()
	road.resize(w * h)
	# карта дорог: в каждой клетке 8x8 — расстояние до края дороги (для шейдера земли и игры)
	var rw: int = int(WD.SIZE.x) / WD.RCELL
	var rh: int = int(WD.SIZE.y) / WD.RCELL
	var fld: PackedFloat32Array = PackedFloat32Array()
	fld.resize(rw * rh)
	fld.fill(96.0)
	for c in WD.road_curves():
		var hw: float = float(c[0])
		var pts: PackedVector2Array = c[1]
		for i in range(pts.size() - 1):
			var a: Vector2 = pts[i]
			var b4: Vector2 = pts[i + 1]
			var mn: Vector2 = (a.min(b4) - WD.ORIGIN - Vector2.ONE * (hw + 40.0)) / WD.RCELL
			var mx: Vector2 = (a.max(b4) - WD.ORIGIN + Vector2.ONE * (hw + 40.0)) / WD.RCELL
			for yy in range(maxi(0, int(mn.y)), mini(rh, int(mx.y) + 1)):
				for xx in range(maxi(0, int(mn.x)), mini(rw, int(mx.x) + 1)):
					var q: Vector2 = WD.ORIGIN + Vector2(xx + 0.5, yy + 0.5) * WD.RCELL
					var d: float = WD.seg_dist(q, a, b4) - hw
					# в городах дороги нет — её продолжают улицы города
					var in_town: bool = false
					for tc in WD.TOWN_C.values():
						if q.distance_to(tc) < WD.TOWN_R:
							in_town = true
					if in_town:
						continue
					var k: int = yy * rw + xx
					if d < fld[k]:
						fld[k] = d
	var rim: Image = Image.create_empty(rw, rh, false, Image.FORMAT_L8)
	for yy in range(rh):
		for xx in range(rw):
			var v: float = clampf((fld[yy * rw + xx] + 32.0) / 128.0, 0.0, 1.0)
			rim.set_pixel(xx, yy, Color(v, v, v))
	rim.save_png(ProjectSettings.globalize_path(OUT + "world_road.png"))
	print("  road map ok ", rw, "x", rh)
	for y in range(h):
		for x in range(w):
			var p: Vector2 = WD.ORIGIN + Vector2(x + 0.5, y + 0.5) * WD.CELL
			var b: int = WD.biome_at(p)
			var rv: float = fld[mini(rh - 1, (y * WD.CELL + WD.CELL / 2) / WD.RCELL) * rw + mini(rw - 1, (x * WD.CELL + WD.CELL / 2) / WD.RCELL)]
			var on_road: bool = rv < 0.0
			biome[y * w + x] = b
			road[y * w + x] = 1 if on_road else (2 if rv < 10.0 else 0)
			bm.set_pixel(x, y, Color8(b, 255 if on_road else 0, 0, 255))
	bm.save_png(ProjectSettings.globalize_path(OUT + "world_biome.png"))
	print("  biome map ok ", w, "x", h)
	# --- пергаментная карта: 1 пиксель = 16 пикселей мира ---
	var mp: Image = new_img(w, h)
	var paper: Array = hx(["b89c70", "c8ae80", "d6be90", "e2cca0", "ecd8b0"])
	for y in range(h):
		for x in range(w):
			var b2: int = biome[y * w + x]
			var n: float = h01(x / 3, y / 3, 61) * 0.5 + h01(x, y, 62) * 0.5
			var c: Color = paper[clampi(int(n * 2.0) + 2, 0, 4)]
			var bc: Color = WD.MAP_COL.get(b2, Color("a3b86c"))
			c = c.lerp(bc, 0.62)
			if h01(x, y, 63) < 0.12:
				c = c.darkened(0.05)
			# граница биомов — тонкая тёмная линия
			if x > 0 and y > 0 and (biome[y * w + x - 1] != b2 or biome[(y - 1) * w + x] != b2):
				c = c.darkened(0.12)
			mp.set_pixel(x, y, c)
	# пруд и дом во дворе
	var pc: Vector2 = (LAY.POND_C - WD.ORIGIN) / WD.CELL
	ell(mp, pc.x, pc.y, LAY.POND_R.x / WD.CELL, LAY.POND_R.y / WD.CELL, Color("5a8aaa"))
	ell(mp, pc.x - 2, pc.y - 1, LAY.POND_R.x / WD.CELL - 4, 2, Color("8ab8cc"))
	# лес и горы — значками
	rng.seed = 91
	var gy: int = 3
	while gy < h - 3:
		var gx: int = 3 + (3 if (gy / 7) % 2 == 0 else 0)
		while gx < w - 3:
			var jx: int = gx + rng.randi_range(-2, 2)
			var jy: int = gy + rng.randi_range(-2, 2)
			gx += 7
			if jx < 2 or jy < 6 or jx >= w - 3 or jy >= h - 2:
				continue
			var b3: int = biome[jy * w + jx]
			if road[jy * w + jx] > 0 or road[(jy - 3) * w + jx] > 0:
				continue
			var wp: Vector2 = WD.ORIGIN + Vector2(jx, jy) * WD.CELL
			if Rect2(140, 330, 1640, 860).has_point(wp):
				continue   # середина двора — поляна
			var dense: float = {1: 0.22, 2: 0.95, 3: 0.55, 4: 0.25, 5: 0.9, 6: 0.3, 7: 0.1, 8: 0.0, 9: 0.12, 0: 0.6, 10: 0.8, 11: 0.1, 12: 0.75, 13: 0.95, 14: 0.85, 15: 0.45, 16: 0.05}.get(b3, 0.2)
			if Rect2(0, 0, WD.RW, WD.RH).has_point(wp):
				dense = 0.85
			if (b3 == 8 or b3 == 11) and rng.randf() < 0.75:
				_map_mount(mp, jx, jy)
			elif rng.randf() < dense:
				_map_tree(mp, jx, jy, b3)
		gy += 6
	# дороги поверх
	for y in range(h):
		for x in range(w):
			if road[y * w + x] == 1:
				var rc: Color = Color("8a6a44") if (x + y) % 5 != 0 else Color("a08058")
				mp.set_pixel(x, y, rc)
	# места
	for lm in WD.LANDMARKS:
		var lp: Vector2 = (Vector2(float(lm[0]), float(lm[1])) - WD.ORIGIN) / WD.CELL
		_map_icon(mp, int(lp.x), int(lp.y), String(lm[2]))
	mp.save_png(ProjectSettings.globalize_path(OUT + "world_map.png"))
	var big: Image = mp.duplicate()
	big.resize(w * 2, h * 2, Image.INTERPOLATE_NEAREST)
	big.save_png(ProjectSettings.globalize_path("res://").path_join("../screenshots/world_map_x2.png"))
	print("  world map ok")


func _map_tree(im: Image, x: int, y: int, b: int) -> void:
	var lc: Array = hx(["2e4a36", "3e6a44", "5a8a52", "7aa864"])
	match b:
		2:
			lc = hx(["2a2638", "3a364c", "504c66", "6a6884"])
		3:
			lc = hx(["2a2228", "3e3238", "56484c", "6e6062"])
		5:
			lc = hx(["1e4a40", "2a6a54", "3e8e6a", "62b488"])
		6:
			lc = hx(["34386a", "484e88", "6068a6", "8088c0"])
		7:
			lc = hx(["5a4a28", "7a6a38", "9a8a4c", "b8a866"])
		10:
			lc = hx(["8a3a6a", "b85a8e", "dc84b0", "f4b4d4"])
		12:
			lc = hx(["4a6a2a", "6a8e36", "92b44a", "bcd870"])
		13:
			lc = hx(["10261f", "1e4335", "33684a", "568f66"])
		14:
			lc = hx(["6a2a14", "a0461e", "d0742e", "f0a84a"])
		15:
			lc = hx(["243a2a", "345038", "4a6a4a", "6a8a62"])
	ell(im, x + 0.5, y + 1.5, 3.0, 1.2, im.get_pixel(x, y + 1).darkened(0.25))
	for yy in range(-5, 1):
		var hw: float = 2.6 * sin(float(yy + 6) / 6.0 * PI * 0.85)
		for xx in range(int(floor(-hw)), int(ceil(hw))):
			var t: int = 3 if (xx < 0 and yy < -2) else (2 if xx < 1 else 1)
			if yy == 0:
				t = 0
			px(im, x + xx, y + yy, lc[t])
	px(im, x, y + 1, Color("4a3424"))


func _map_mount(im: Image, x: int, y: int) -> void:
	var c: Array = hx(["4a4440", "6a625a", "8e867a", "d8d4cc"])
	for yy in range(-6, 1):
		var hw: int = yy + 7
		for xx in range(-hw, hw + 1):
			var t: int = 2 if xx < 0 else 1
			if yy < -4:
				t = 3
			if absf(xx) == hw:
				t = 0
			px(im, x + xx, y + yy, c[t])


## Значки мест на карте (рисуются пикселями, без надписей)
func _map_icon(im: Image, x: int, y: int, kind: String) -> void:
	var ink: Color = Color("3a2a1e")
	# круглая подложка
	disc(im, x, y, 9.5, ink)
	disc(im, x, y, 8.5, Color("f0e2c0"))
	match kind:
		"japan":
			var red: Color = Color("c83a2e")
			rect(im, x - 7, y - 5, 15, 2, red)
			rect(im, x - 6, y - 2, 13, 1, red)
			rect(im, x - 5, y - 3, 2, 10, red)
			rect(im, x + 4, y - 3, 2, 10, red)
			px(im, x - 7, y - 6, red)
			px(im, x + 7, y - 6, red)
		"pier":
			for k in range(-6, 7):
				px(im, x + k, y + 3 + int(round(sin(k * 0.9))), Color("3a7ab8"))
			rect(im, x - 1, y - 7, 3, 10, Color("8a6440"))
			disc(im, x + 3, y - 2, 3.0, Color("c8a040"))
			px(im, x + 3, y - 2, Color("a8e0ff"))
		"home":
			for yy in range(-1, 5):
				for xx in range(-4, 5):
					px(im, x + xx, y + yy, Color("e8d0a0") if yy < 4 else Color("8a6a44"))
			for yy2 in range(-6, 0):
				var hw: int = yy2 + 7
				for xx2 in range(-hw, hw + 1):
					px(im, x + xx2, y + yy2, Color("c0603a") if xx2 < 0 else Color("a04a2e"))
			rect(im, x - 1, y + 1, 2, 3, Color("6a4428"))
		"cats":
			ell(im, x, y + 1, 6, 5, Color("f0a050"))
			for s in [-1, 1]:
				for k in range(5):
					for j in range(5 - k):
						px(im, x + s * (3 + j - 2) + (0 if s < 0 else 0), y - 3 - k, Color("f0a050"))
				px(im, x + s * 3, y - 4, Color("f4a0b0"))
			px(im, x - 2, y, ink)
			px(im, x + 2, y, ink)
			px(im, x, y + 2, Color("e06080"))
		"spider":
			for a in range(8):
				var ang: float = TAU * a / 8.0
				line(im, x, y, x + int(round(cos(ang) * 7.0)), y + int(round(sin(ang) * 7.0)), Color("6a6a7a"))
			for r in [3.0, 5.5]:
				for a2 in range(32):
					var an: float = TAU * a2 / 32.0
					px(im, x + int(round(cos(an) * r)), y + int(round(sin(an) * r)), Color("8a8a9a"))
			disc(im, x, y, 1.6, Color("3a2a4a"))
		"gothic":
			var gc: Color = Color("3a3040")
			rect(im, x - 6, y - 1, 13, 7, gc)
			for tx in [-5, 0, 5]:
				rect(im, x + tx - 1, y - 6 + (2 if tx != 0 else 0), 3, 6, gc)
				px(im, x + tx, y - 7 + (2 if tx != 0 else 0), gc)
				px(im, x + tx, y - 8 + (2 if tx != 0 else 0), gc)
			px(im, x - 2, y + 2, Color("e8c060"))
			px(im, x + 2, y + 2, Color("e8c060"))
			px(im, x, y + 3, Color("b02030"))
		"castle":
			var cc: Color = Color("8a8a96")
			rect(im, x - 6, y - 2, 13, 8, cc)
			for tx2 in [-6, -2, 2, 5]:
				rect(im, x + tx2, y - 4, 2, 2, cc)
			rect(im, x - 1, y + 2, 3, 4, Color("4a3a2a"))
			line(im, x, y - 4, x, y - 8, ink)
			rect(im, x + 1, y - 8, 3, 2, Color("c03040"))
		"elf":
			disc(im, x, y - 2, 5.5, Color("3e8e6a"))
			disc(im, x - 1, y - 3, 3.0, Color("62b488"))
			rect(im, x - 1, y + 3, 2, 4, Color("6a4a2a"))
			px(im, x + 3, y - 4, Color("e8fff0"))
			px(im, x - 3, y, Color("e8fff0"))
		"mage":
			rect(im, x - 2, y - 3, 5, 10, Color("7a7cb8"))
			for k2 in range(4):
				for j2 in range(-k2, k2 + 1):
					px(im, x + j2, y - 7 + k2, Color("4a4c8a"))
			px(im, x, y - 9, Color("fff0a0"))
			px(im, x - 1, y - 9, Color("f0c040"))
			px(im, x + 1, y - 9, Color("f0c040"))
			px(im, x, y - 10, Color("f0c040"))
			px(im, x, y, Color("a8e0ff"))
		"orc":
			for k3 in range(7):
				for j3 in range(-k3, k3 + 1):
					px(im, x + j3, y - 4 + k3, Color("7a5a34") if j3 < 0 else Color("5e4428"))
			rect(im, x - 1, y, 2, 3, Color("2a1e14"))
			px(im, x - 2, y - 6, Color("4a8a3a"))
			px(im, x + 2, y - 6, Color("4a8a3a"))
		"goblin":
			ell(im, x, y + 1, 5, 4, Color("6aa040"))
			for s2 in [-1, 1]:
				for k4 in range(4):
					px(im, x + s2 * (5 + k4), y - k4 / 2, Color("6aa040"))
			px(im, x - 2, y, Color("f0e040"))
			px(im, x + 2, y, Color("f0e040"))
		"unicorn":
			ell(im, x, y + 2, 6, 4, Color("fff4fa"))
			disc(im, x + 4, y - 2, 3.0, Color("fff4fa"))
			line(im, x + 5, y - 5, x + 7, y - 10, Color("f0c850"))
			for k5 in range(4):
				px(im, x - 1 + k5, y - 3 - k5 % 2, Color("e870b0"))
		"cave":
			for yy in range(-6, 6):
				var w5: int = int(8.0 * sqrt(maxf(0.0, 1.0 - pow((yy + 1) / 7.0, 2.0))))
				for xx in range(-w5, w5 + 1):
					px(im, x + xx, y + yy, Color("5a5868"))
			ell(im, x, y + 3, 4, 4, Color("1a1622"))
			px(im, x - 5, y + 4, Color("7ae8ff"))
			px(im, x + 5, y + 3, Color("7ae8ff"))
		"hermit":
			for yy2 in range(-1, 5):
				for xx2 in range(-4, 5):
					px(im, x + xx2, y + yy2, Color("8a6a44"))
			for yy3 in range(-6, 0):
				var hw3: int = yy3 + 7
				for xx3 in range(-hw3, hw3 + 1):
					px(im, x + xx3, y + yy3, Color("c8a040"))
			rect(im, x - 1, y + 1, 2, 3, Color("3a2a1e"))
		"outcast":
			for k6 in range(7):
				for j6 in range(-k6, k6 + 1):
					px(im, x + j6, y - 4 + k6, Color("5a4a5a") if j6 < 0 else Color("443848"))
			ell(im, x, y + 4, 3, 1.5, Color("ff8a2a"))
		"dwarf":
			rect(im, x - 4, y - 3, 7, 9, Color("c88a3a"))
			rect(im, x - 4, y - 5, 7, 2, Color("fff4dc"))
			rect(im, x + 3, y - 1, 3, 1, Color("8a5a2a"))
			rect(im, x + 5, y - 1, 1, 5, Color("8a5a2a"))
			rect(im, x + 3, y + 3, 3, 1, Color("8a5a2a"))
			rect(im, x - 3, y - 2, 1, 7, Color("e8b060"))


# ================================================================== деревня кошкодевочек

var HAIR_CUT: int = 0            # >0: обрезать длинные волосы на этой высоте (каре)
var NO_CAPE: bool = false        # кошкодевочки ходят в платьях, без плаща
var UNDER: bool = false          # v16: без одежды — майка и шортики вместо платья, голые руки
var BAREFOOT: bool = false       # v16: без обуви — босые ступни
var SLEEVE7: Array = []          # рукава (обычно = WHITE7, в белье = кожа)
var CAT_TAIL: bool = false

const CAT_LOOKS: Array = [
	# имя, волосы/уши/хвост, платье, отделка
	["catgirl_mira", ["14121a", "1e1c28", "2a2836", "3a3848", "4e4c5e", "686678", "8a889a"], ["6a3a4a", "94566a", "b8768a", "d498a8", "e8b8c2", "f4d6dc", "fcecf0"], ["3a1e2a", "5a2a3a", "7a3a4c", "9a4e5e", "b86a74", "d48e92", "ecb6b4"]],
	["catgirl_ryzhik", ["4a1a10", "74301a", "a04a22", "c8662c", "e0863e", "f0a85a", "fac888"], ["4a5a3a", "6a7e52", "8ea06c", "b0c08a", "ccd8aa", "e2ecc8", "f2f8e4"], ["2a3a1e", "3a5028", "4e6a34", "668642", "80a056", "9cba70", "bcd494"]],
	["catgirl_snow", ["5a5a6e", "7e7e94", "a2a4b6", "c4c6d4", "dcdee8", "eceef4", "fafbfe"], ["283a5e", "34507e", "4a6c9e", "6a8cbc", "92b0d6", "bcd0ea", "e2ecf8"], ["1a2440", "223258", "2e4470", "3e5a8a", "5674a6", "7894c0", "a4b8da"]],
	["catgirl_smoky", ["2a2c34", "3e424c", "565a66", "70747e", "8c909a", "aaaeb6", "cacdd2"], ["4a3a5e", "64507e", "806c9a", "9e8cb6", "bcaed0", "d8cee6", "eee8f4"], ["2a1e3a", "3a2a50", "4e3a68", "664e82", "80689c", "9e88b6", "c0aed2"]],
	["catgirl_choco", ["2e1a12", "46281a", "603a24", "7a4e32", "966844", "b28860", "ccaa84"], ["6a5420", "94782e", "b89a40", "d4b85a", "e8d07c", "f4e4a6", "fcf4d4"], ["4a2a14", "6a3c1c", "8a5226", "aa6a34", "c88648", "e0a462", "f2c48a"]],
	["catgirl_maple", ["3a1a0e", "5a2a16", "7e3e20", "a0562c", "c0743c", "d89458", "ecb888"], ["8a7a80", "b0a2a8", "d2c6ca", "eae2e4", "f6f0f2", "fcf8f8", "ffffff"], ["7a2a4a", "9a3a5e", "b84e74", "d4688c", "e88aa8", "f4b0c4", "fcd6e2"]],
	["catgirl_vanilla", ["9a8a5a", "b4a46e", "ccbc86", "e0d2a0", "eee4be", "f8f2dc", "fffcf2"], ["8a7a80", "b0a2a8", "d2c6ca", "eae2e4", "f6f0f2", "fcf8f8", "ffffff"], ["2a4a7a", "36609a", "4a7ab4", "6496cc", "86b2e0", "aacef0", "d4e8fa"]],
	["catgirl_cream", ["5a4030", "7e5e44", "a0805e", "bea07a", "d6bc98", "e8d4b6", "f6ecd8"], ["2a5a52", "36746a", "4a8e82", "64a89a", "86c2b2", "b0dccc", "dcf2ea"], ["5a2a2a", "7a3a36", "9a4c44", "b86256", "d07e6c", "e4a08a", "f4c4ae"]],
]


func gen_cats() -> void:
	gen_catgirls()
	gen_cat_house("cat_house_a", hx(["b8a27a", "c9b48c", "d8c59e", "e5d5b2", "efe2c6", "f7efdc"]), hx(["4a1e1a", "6e2a22", "92382a", "b44a32", "cc6440", "de8452", "eca46a", "f6c88e"]), 11)
	gen_cat_house("cat_house_b", hx(["b88a8a", "caa0a0", "d8b4b2", "e6c8c4", "f0dad6", "f8ece8"]), hx(["2e1a36", "42244c", "5a3264", "744480", "8e5c9a", "a878b2", "c49ad0", "e0c2e8"]), 12)
	gen_cat_house("cat_house_c", hx(["c09468", "d0a87c", "dcbc92", "e8cea8", "f2dec0", "faeedc"]), hx(["14303a", "1c4450", "265a64", "327078", "44888a", "5ea09c", "80b8b0", "a8d0c6"]), 13)
	gen_cat_house("cat_house_d", hx(["9eae96", "b2c0a8", "c4d2b8", "d6e2ca", "e6eedc", "f4f8ee"]), hx(["4a2410", "6e3616", "924a1c", "b46024", "d07a30", "e49642", "f0b45e", "f8d28a"]), 14)
	gen_cat_plaza()
	gen_cat_fountain()
	gen_fish_rack()
	gen_yarn_basket()
	gen_cat_tower()
	gen_cat_stall()
	gen_milk_cans()
	var items: Array = []
	for nm in ["cat_house_a", "cat_house_b", "cat_house_c", "cat_house_d", "cat_fountain", "fish_rack", "yarn_basket", "cat_tower", "cat_stall", "milk_cans", "cat_plaza"]:
		items.append([nm, Image.load_from_file(ProjectSettings.globalize_path(OUT + String(nm) + ".png"))])
	_sheet(items, 2, "cats_preview.png")


## Заливка треугольника; col(x, y, u) — цвет по положению (u — 0..1 от левого края к правому)
func tri(im: Image, a: Vector2, b2: Vector2, c: Vector2, col: Callable) -> void:
	var x0: int = int(floor(minf(a.x, minf(b2.x, c.x))))
	var x1: int = int(ceil(maxf(a.x, maxf(b2.x, c.x))))
	var y0: int = int(floor(minf(a.y, minf(b2.y, c.y))))
	var y1: int = int(ceil(maxf(a.y, maxf(b2.y, c.y))))
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			var p: Vector2 = Vector2(x + 0.5, y + 0.5)
			var d1: float = (p - b2).cross(a - b2)
			var d2: float = (p - c).cross(b2 - c)
			var d3: float = (p - a).cross(c - a)
			var neg: bool = d1 < 0.0 or d2 < 0.0 or d3 < 0.0
			var pos: bool = d1 > 0.0 or d2 > 0.0 or d3 > 0.0
			if neg and pos:
				continue
			var u: float = (float(x) - float(x0)) / maxf(1.0, float(x1 - x0))
			px(im, x, y, col.call(x, y, u))


# ---------------------------------------------------------------- кошкодевочки

## Кошачье ухо: основание a-b (по волосам), кончик t. inner — розовая середина (вид спереди)
func cat_ear_h(im: Image, a: Vector2, b2: Vector2, t: Vector2, inner: bool, dark: int = 0) -> void:
	tri(im, a, b2, t, func(_x: int, _y: int, u: float) -> Color: return HAIRL7[clampi((5 if u < 0.4 else 4) - dark, 0, 6)])
	if inner:
		var m: Vector2 = (a + b2) / 2.0
		var ia: Vector2 = a.lerp(m, 0.35) + Vector2(0, -1)
		var ib: Vector2 = b2.lerp(m, 0.35) + Vector2(0, -1)
		var it: Vector2 = t.lerp(m, 0.28)
		var pink: Array = hx(["b85a6a", "d8808c", "f0a8b0", "fccad0"])
		tri(im, ia, ib, it, func(_x: int, y: int, _u: float) -> Color: return pink[2] if y > int(it.y) + 2 else pink[1])
		# пушок в ухе
		px(im, int(m.x), int(m.y) - 2, HAIRL7[6])
		px(im, int(m.x) - 1, int(m.y) - 1, HAIRL7[6])


## Хвост: цепочка «капсул» по точкам, покачивается (sway — сдвиг кончика)
func cat_tail_h(im: Image, pts: Array, sway: float) -> void:
	var n: int = pts.size()
	var q: Array = []
	for i in range(n):
		var t: float = float(i) / float(n - 1)
		q.append((pts[i] as Vector2) + Vector2(sway * t * t, -absf(sway) * 0.2 * t))
	for i in range(n - 1):
		var t0: float = float(i) / float(n - 1)
		var r0: float = lerpf(TAIL_R.x, TAIL_R.y, t0)
		var r1: float = lerpf(TAIL_R.x, TAIL_R.y, float(i + 1) / float(n - 1))
		if WOLF and i == 2:
			r0 += 1.0
		capsule(im, q[i], q[i + 1], r0, r1, HAIRL7, 4 if i < n - 2 else 5)
	if WOLF:
		# пушистый светлый кончик волчьего хвоста
		blob(im, (q[n - 1] as Vector2).x, (q[n - 1] as Vector2).y, TAIL_R.y + 0.6, TAIL_R.y + 1.2, HAIRL7, 6)
	else:
		blob(im, (q[n - 1] as Vector2).x, (q[n - 1] as Vector2).y, 2.4, 2.4, HAIRL7, 5)


const EAR_PTS: Dictionary = {
	# ракурс: [[основание a, основание b, кончик, розовое внутри], ...] — дальнее ухо первым
	0: [[Vector2(28, 12), Vector2(37, 6.5), Vector2(26.5, -0.5), true], [Vector2(44, 6.5), Vector2(53, 12), Vector2(54.5, -0.5), true]],
	1: [[Vector2(28, 12), Vector2(37, 6.5), Vector2(26.5, -0.5), false], [Vector2(44, 6.5), Vector2(53, 12), Vector2(54.5, -0.5), false]],
	2: [[Vector2(43, 9), Vector2(51, 12), Vector2(50, 1), false], [Vector2(34, 7.5), Vector2(44, 7.5), Vector2(41, -1), true]],
	4: [[Vector2(26, 12), Vector2(34, 7.5), Vector2(25, 1), true], [Vector2(40, 6.5), Vector2(50, 10), Vector2(49, -1), true]],
	5: [[Vector2(30, 10.5), Vector2(38, 5.5), Vector2(29, 0), false], [Vector2(45, 5), Vector2(54, 10), Vector2(54, -1), false]],
}
const TAIL_PTS: Dictionary = {
	0: [Vector2(46, 74), Vector2(53, 78), Vector2(59, 73), Vector2(62, 62), Vector2(60, 50), Vector2(63, 41)],
	1: [Vector2(40, 72), Vector2(42, 80), Vector2(48, 85), Vector2(54, 80), Vector2(57, 68), Vector2(55, 56)],
	2: [Vector2(47, 70), Vector2(54, 74), Vector2(60, 68), Vector2(62, 57), Vector2(59, 47), Vector2(61, 39)],
	4: [Vector2(48, 74), Vector2(55, 78), Vector2(60, 72), Vector2(63, 61), Vector2(61, 50), Vector2(64, 42)],
	5: [Vector2(43, 72), Vector2(45, 80), Vector2(51, 85), Vector2(57, 80), Vector2(60, 68), Vector2(58, 56)],
}


func draw_catgirl(im: Image, dir: int, f: int) -> void:
	var b: int = -1 if (f == 1 or f == 3 or f == 6 or f == 7) else 0
	var walk: bool = f <= 3
	var sway: float = sin(float(f) * 1.57) * 2.6 if walk else [0.0, 1.2, 2.2, 1.2][clampi(f - 4, 0, 3)]
	var tail: Array = []
	for p in TAIL_PTS[dir]:
		tail.append((p as Vector2) + Vector2(0, b))
	var behind: bool = dir == 0 or dir == 2 or dir == 4
	if behind:
		if KITSUNE > 0:
			kit_tails(im, dir, b, sway)
		else:
			cat_tail_h(im, tail, sway)
	draw_hero10(im, dir, f)
	if not behind:
		if KITSUNE > 0:
			kit_tails(im, dir, b, sway)
		else:
			cat_tail_h(im, tail, sway)
	for e in EAR_PTS[dir]:
		var ea: Array = e
		var off: Vector2 = Vector2(0, b)
		var tip_sw: Vector2 = Vector2(0, 0)
		if f == 6:
			tip_sw = Vector2(-1, 0)   # ушко дёргается
		var ea0: Vector2 = (ea[0] as Vector2) + off
		var ea1: Vector2 = (ea[1] as Vector2) + off
		var etp: Vector2 = (ea[2] as Vector2) + off + tip_sw
		if WOLF:
			# волчьи уши: шире у основания и острее
			var dirv: Vector2 = (ea1 - ea0).normalized()
			ea0 -= dirv * 1.5
			ea1 += dirv * 1.5
			etp += (etp - (ea0 + ea1) / 2.0).normalized() * 1.5
		if KITSUNE > 0:
			fox_ear(im, ea0, ea1, etp, bool(ea[3]))
		else:
			cat_ear_h(im, ea0, ea1, etp, bool(ea[3]), 1 if ea == EAR_PTS[dir][0] and dir == 2 else 0)


func gen_catgirls() -> void:
	var sh: Array = HAIRL7.duplicate()
	var sw7: Array = WHITE7.duplicate()
	var st: Array = TEAL7.duplicate()
	var fw: int = 80
	var fh: int = 160
	var mirror: Dictionary = {2: 3, 4: 6, 5: 7}
	NO_CAPE = true
	BOUNCE_OVR = 0
	var line_up: Image = new_img(fw * CAT_LOOKS.size(), fh)
	var li: int = 0
	for lk in CAT_LOOKS:
		HAIRL7 = hx(lk[1])
		WHITE7 = hx(lk[2])
		TEAL7 = hx(lk[3])
		_head_pal()
		var vs: Image = new_img(fw * 8, fh * 8)
		for vd in [0, 1, 2, 4, 5]:
			for k in range(8):
				var c2: Image = new_img(fw, fh)
				draw_catgirl(c2, vd, k)
				outline_auto(c2, OUTLINE_CHAR)
				vs.blit_rect(c2, Rect2i(0, 0, fw, fh), Vector2i(k * fw, vd * fh))
				if mirror.has(vd):
					var mc: Image = c2.duplicate()
					mc.flip_x()
					vs.blit_rect(mc, Rect2i(0, 0, fw, fh), Vector2i(k * fw, int(mirror[vd]) * fh))
		save3(vs, String(lk[0]))
		gen_faces10("faces_" + String(lk[0]))
		line_up.blit_rect(vs, Rect2i(4 * fw, 0, fw, fh), Vector2i(li * fw, 0))
		li += 1
		# все ракурсы первой — для проверки
		if li == 1:
			var all: Image = new_img(fw * 8, fh)
			for d2 in range(8):
				all.blit_rect(vs, Rect2i(4 * fw, d2 * fh, fw, fh), Vector2i(d2 * fw, 0))
			all.resize(all.get_width() * 3, all.get_height() * 3, Image.INTERPOLATE_NEAREST)
			all.save_png(ProjectSettings.globalize_path("res://").path_join("../screenshots/catgirl_views.png"))
	line_up.resize(line_up.get_width() * 3, line_up.get_height() * 3, Image.INTERPOLATE_NEAREST)
	line_up.save_png(ProjectSettings.globalize_path("res://").path_join("../screenshots/catgirls_lineup.png"))
	NO_CAPE = false
	HAIRL7 = sh
	WHITE7 = sw7
	TEAL7 = st
	_head_pal()


# ---------------------------------------------------------------- домик кошек

## Домик с черепичной крышей, на коньке — кошачьи ушки; круглое окно-мордочка, дверь с лапкой
func gen_cat_house(name: String, wall: Array, roof: Array, seed_v: int) -> void:
	rng.seed = seed_v
	var W: int = 184
	var H: int = 200
	var im: Image = new_img(W, H)
	var cx: int = 92
	var wall_top: int = 108
	var wall_bot: int = 172
	var npl: FastNoiseLite = FastNoiseLite.new()
	npl.seed = seed_v
	npl.frequency = 0.09
	# стены
	for y in range(wall_top, wall_bot):
		for x in range(20, 164):
			var v: float = 0.62 + npl.get_noise_2d(x, y) * 0.10 + (h01(x, y, 2) - 0.5) * 0.06 - (x - 20) * 0.0008
			if y < wall_top + 14:
				v -= 0.40 * pow(1.0 - (y - wall_top) / 14.0, 1.4)
			px(im, x, y, pick(wall, v, x, y))
	# фахверк
	for bx in [20, 56, 121, 157]:
		planks(im, int(bx), wall_top, 7, wall_bot - wall_top, WOOD, true, 7, 0.42, int(bx))
	planks(im, 20, wall_top, 144, 6, WOOD, false, 6, 0.40, 1)
	planks(im, 20, wall_bot - 6, 144, 6, WOOD, false, 6, 0.38, 2)
	# фундамент
	stone_wall(im, Rect2i(16, wall_bot, 152, 14), STONE, 6, 9, 16, Color("39353a"), 0.50)
	# дверь: арка, доски, лапка
	var dw: int = 13
	var dtop: int = wall_bot - 46
	for y in range(dtop - 3, wall_bot + 1):
		for x in range(cx - dw - 3, cx + dw + 4):
			var ax: float = float(x - cx) + 0.5
			var ay: float = float(y - (dtop + dw))
			if ay < 0.0 and ax * ax + ay * ay > float((dw + 3) * (dw + 3)):
				continue
			px(im, x, y, WOOD[1] if (absf(ax) > dw or (ay < 0.0 and ax * ax + ay * ay > dw * dw)) else WOOD[0])
	for y in range(dtop, wall_bot):
		for x in range(cx - dw, cx + dw):
			var ax2: float = float(x - cx) + 0.5
			var ay2: float = float(y - (dtop + dw))
			if ay2 < 0.0 and ax2 * ax2 + ay2 * ay2 > float((dw - 1) * (dw - 1)):
				continue
			var pl: int = posmod(x - (cx - dw), 6)
			var v2: float = 0.55 - (0.25 if pl == 0 else 0.0) + (0.1 if pl == 1 else 0.0) + (h01(x, y / 4, 9) - 0.5) * 0.12 - float(y - dtop) * 0.002
			px(im, x, y, pick(WOOD, v2, x, y))
	# лапка на двери
	var pc: Vector2 = Vector2(cx, dtop + 24)
	var pad: Array = hx(["c86a7a", "e88a98", "f8b4be"])
	ell(im, pc.x, pc.y + 3, 4.5, 3.5, pad[0])
	ell(im, pc.x - 0.5, pc.y + 2.5, 3.8, 2.8, pad[1])
	for tp in [Vector2(-5, -3), Vector2(-2, -6), Vector2(2, -6), Vector2(5, -3)]:
		disc(im, pc.x + tp.x, pc.y + tp.y, 1.6, pad[0])
		px(im, int(pc.x + tp.x), int(pc.y + tp.y) - 1, pad[2])
	# ручка
	disc(im, cx + 8, dtop + 30, 1.3, GOLD[4])
	px(im, cx + 8, dtop + 30, GOLD[5])
	# ступенька
	stone_block(im, cx - 18, wall_bot + 1, 36, 6, STONE, 0.62, 3)
	# круглое окно-мордочка слева
	var wc: Vector2 = Vector2(37 + 1, 138)
	disc(im, wc.x, wc.y, 13.5, WOOD[1])
	disc(im, wc.x, wc.y, 12.0, WOOD[4])
	for y in range(int(wc.y) - 11, int(wc.y) + 12):
		for x in range(int(wc.x) - 11, int(wc.x) + 12):
			var d: float = Vector2(x + 0.5, y + 0.5).distance_to(wc)
			if d > 10.2:
				continue
			var gv: float = 0.35 + float(y - (wc.y - 11)) / 22.0 * 0.45 + (0.18 if (x - y) % 9 == 0 else 0.0)
			px(im, x, y, pick(GLASS, gv, x, y))
	rect(im, int(wc.x) - 1, int(wc.y) - 10, 2, 21, WOOD[2])
	rect(im, int(wc.x) - 10, int(wc.y) - 1, 21, 2, WOOD[2])
	# ушки над рамкой и усики
	for s in [-1, 1]:
		tri(im, Vector2(wc.x + s * 4.0, wc.y - 11.0), Vector2(wc.x + s * 12.0, wc.y - 7.0), Vector2(wc.x + s * 11.0, wc.y - 19.0), func(_x: int, _y: int, u: float) -> Color: return WOOD[4] if u < 0.5 else WOOD[3])
		for k in range(3):
			var yy: int = int(wc.y) + 2 + k * 3
			for j in range(6):
				px(im, int(wc.x) + s * (15 + j), yy - (k - 1) * j / 3, WOOD[1])
	# окно справа: квадратное со ставнями и ящиком цветов
	var rx0: int = 128
	var ry0: int = 126
	rect(im, rx0 - 2, ry0 - 2, 26, 26, WOOD[1])
	for y in range(ry0, ry0 + 22):
		for x in range(rx0, rx0 + 22):
			px(im, x, y, pick(GLASS, 0.3 + float(y - ry0) / 22.0 * 0.5 + (0.2 if (x + y) % 11 == 0 else 0.0), x, y))
	rect(im, rx0 + 10, ry0, 2, 22, WOOD[2])
	rect(im, rx0, ry0 + 10, 22, 2, WOOD[2])
	for sx in [rx0 - 11, rx0 + 24]:
		for y in range(ry0 - 2, ry0 + 24):
			for x in range(int(sx), int(sx) + 9):
				var tv: float = 0.55 + (0.15 if posmod(x - int(sx), 3) == 0 else 0.0) - float(y - ry0) * 0.006
				px(im, x, y, pick(roof, tv, x, y))
	planks(im, rx0 - 4, ry0 + 24, 30, 6, WOOD, false, 6, 0.4, 5)
	var fls: Array = [hx(["d87a98", "f2a2bc", "fcd2e0"]), hx(["d8d0c0", "f6f0e4", "ffffff"]), hx(["d8a02a", "f2cc48", "fff0a0"])]
	for k2 in range(6):
		for j2 in range(3):
			px(im, rx0 - 2 + k2 * 5 + j2, ry0 + 23 - rng.randi_range(0, 1), MINT[3 + j2 % 2])
		flower5(im, rx0 - 1 + k2 * 5, ry0 + 21 - rng.randi_range(0, 2), fls[k2 % 3], Color("f6d24a"))
	# черепичная крыша с кошачьими ушками на коньке
	var top_y: int = 30
	var eave_y: int = 116
	var ch: float = 9.0
	for y in range(top_y, eave_y + 1):
		var t: float = float(y - top_y) / float(eave_y - top_y)
		var hw: float = 34.0 + t * 58.0
		for x in range(int(cx - hw), int(cx + hw) + 1):
			var yy0: float = float(y - top_y)
			var course: int = int(yy0 / ch)
			var ly: float = fposmod(yy0, ch)
			var tx: float = fposmod(float(x) + (5.0 if course % 2 == 1 else 0.0), 10.0)
			var curve: float = pow(absf(tx - 5.0) / 5.0, 2.0) * 2.5
			var v: float = 0.80 - ly / ch * 0.34 + (h01(int(float(x + (5 if course % 2 == 1 else 0)) / 10.0), course, 7) - 0.5) * 0.14
			if ly > ch - 1.6 - curve:
				v -= 0.32
			if tx < 1.0:
				v -= 0.12
			v += (cx - x) / hw * 0.08
			if y > eave_y - 2:
				v -= 0.25
			px(im, x, y, pick(roof, v, x, y))
	# конёк
	for x in range(cx - 36, cx + 37):
		for y in range(top_y - 4, top_y + 2):
			px(im, x, y, pick(roof, 0.52 - float(y - top_y + 4) * 0.05 + (0.1 if posmod(x, 7) == 0 else 0.0), x, y))
	# ушки: из той же черепицы, внутри розовые
	var pinkr: Array = hx(["b85a6a", "d8808c", "f0a8b0", "fccad0"])
	for s2 in [-1, 1]:
		var a0: Vector2 = Vector2(cx + s2 * 12.0, top_y - 2.0)
		var b0: Vector2 = Vector2(cx + s2 * 38.0, top_y + 2.0)
		var tp2: Vector2 = Vector2(cx + s2 * 36.0, top_y - 28.0)
		tri(im, a0, b0, tp2, func(x: int, y: int, u: float) -> Color: return pick(roof, 0.66 - (0.18 if (u > 0.5) == (s2 > 0) else 0.0) - float(posmod(y, 9) > 6) * 0.2, x, y))
		var m2: Vector2 = (a0 + b0) / 2.0
		tri(im, a0.lerp(m2, 0.38) + Vector2(0, -2), b0.lerp(m2, 0.38) + Vector2(0, -2), tp2.lerp(m2, 0.3), func(_x: int, y: int, _u: float) -> Color: return pinkr[2] if y > int(top_y - 12) else pinkr[1])
	# флюгер-рыбка на трубе посередине
	for y in range(top_y - 16, top_y - 3):
		px(im, cx, y, IRON[2])
	var fish: Array = ["..##...", ".####.#", "#######", ".####.#", "..##..."]
	for fy in range(fish.size()):
		for fx in range(7):
			if String(fish[fy])[fx] == "#":
				px(im, cx - 3 + fx, top_y - 22 + fy, IRON[4] if fy < 2 else IRON[3])
	# фонарик у двери
	for y in range(dtop - 2, dtop + 6):
		px(im, cx + 20, y, IRON[1])
	rect(im, cx + 18, dtop + 6, 5, 7, IRON[1])
	rect(im, cx + 19, dtop + 7, 3, 5, GLASS[5])
	# плющ и цветы у стен
	draw_ivy(im, 22, wall_bot + 2, 40, 0.9)
	draw_ivy(im, 160, wall_bot + 2, 34, 0.9)
	outline_auto(im, 0.45)
	save3(im, name)


# ---------------------------------------------------------------- площадь и предметы

func gen_cat_plaza() -> void:
	var W: int = 360
	var H: int = 200
	var im: Image = new_img(W, H)
	var c: Vector2 = Vector2(180, 100)
	rng.seed = 51
	# булыжник кругами вокруг центра
	for y in range(H):
		for x in range(W):
			var q: Vector2 = Vector2((x + 0.5 - c.x) / 176.0, (y + 0.5 - c.y) / 96.0)
			var d: float = q.length() + (h01(x / 4, y / 4, 3) - 0.5) * 0.06
			if d > 1.0:
				continue
			var ang: float = atan2(q.y, q.x)
			var ring: float = d * 9.0
			var ri: int = int(ring)
			var seg: int = int(floor((ang + PI) / TAU * float(10 + ri * 7) + float(ri) * 0.5))
			var fr: float = fposmod(ring, 1.0)
			var v: float = 0.56 + (h01(seg, ri, 5) - 0.5) * 0.2
			if fr < 0.16 or fr > 0.92:
				v = 0.18
			var fa: float = fposmod((ang + PI) / TAU * float(10 + ri * 7) + float(ri) * 0.5, 1.0)
			if fa < 0.08:
				v = 0.22
			if d > 0.94:
				v -= 0.2
			px(im, x, y, pick(STONE, v + 0.1, x, y))
	# мозаика-лапка в середине (под фонтаном видна по краям) и лапки-следы по площади
	for k in range(9):
		var a: float = float(k) / 9.0 * TAU + 0.3
		var pp: Vector2 = c + Vector2(cos(a) * 120.0, sin(a) * 64.0)
		var pd: Array = hx(["c09080", "e0b0a0", "f6d2c4"])
		ell(im, pp.x, pp.y + 2, 4.0, 3.0, pd[0])
		ell(im, pp.x, pp.y + 1.5, 3.3, 2.3, pd[1])
		for tp in [Vector2(-4, -2), Vector2(-1.5, -4), Vector2(1.5, -4), Vector2(4, -2)]:
			disc(im, pp.x + tp.x, pp.y + tp.y, 1.2, pd[1])
	save3(im, "cat_plaza")


func gen_cat_fountain() -> void:
	var W: int = 96
	var H: int = 96
	var im: Image = new_img(W, H)
	var c: Vector2 = Vector2(48, 74)
	# каменная чаша
	ell(im, c.x, c.y + 4, 44, 16, STONE[1])
	for y in range(int(c.y) - 16, int(c.y) + 18):
		for x in range(4, 92):
			var q: Vector2 = Vector2((x + 0.5 - c.x) / 44.0, (y + 0.5 - c.y) / 15.0)
			var d: float = q.length()
			if d > 1.0:
				continue
			var v: float = 0.6 - q.y * 0.15 - q.x * 0.05
			if d < 0.82:
				# вода
				var wv: float = 0.45 + sin(x * 0.5 + y * 1.3) * 0.08 - q.y * 0.15
				if (x + y * 3) % 13 == 0:
					wv += 0.3
				px(im, x, y, pick(WATER, wv, x, y))
				continue
			if d > 0.95:
				v -= 0.22
			px(im, x, y, pick(STONE, v + 0.1, x, y))
	# стенка чаши спереди
	for y in range(int(c.y), int(c.y) + 12):
		for x in range(5, 91):
			var q2: float = (x + 0.5 - c.x) / 44.0
			var top: float = c.y + sqrt(maxf(0.0, 1.0 - q2 * q2)) * 15.0
			if y < top or y > top + 9.0:
				continue
			var v2: float = 0.5 - absf(q2) * 0.2 - float(y - top) * 0.02 + (0.08 if posmod(x, 9) == 0 else 0.0)
			if posmod(int(y - top), 5) == 4:
				v2 -= 0.15
			px(im, x, y, pick(STONE, v2, x, y))
	# постамент и сидящая каменная кошка
	for y in range(48, 74):
		for x in range(40, 57):
			px(im, x, y, pick(STONE, 0.58 - (x - 40) * 0.015 + (0.1 if y == 48 else 0.0), x, y))
	var cr: Array = hx(["4a4a60", "6e6e86", "9898ae", "bdbdcc", "dedee8", "f4f4f8", "ffffff"])
	blob(im, 48, 40, 10, 10, cr, 3)          # тело
	blob(im, 48, 24, 8, 7, cr, 4)             # голова
	for s in [-1, 1]:
		tri(im, Vector2(48 + s * 2, 19), Vector2(48 + s * 8, 21), Vector2(48 + s * 7, 12), func(_x: int, _y: int, u: float) -> Color: return cr[4] if u < 0.5 else cr[3])
		px(im, 48 + s * 3, 24, cr[0])
	px(im, 48, 27, cr[1])
	blob(im, 44, 49, 3, 2, cr, 3)
	blob(im, 52, 49, 3, 2, cr, 3)
	capsule(im, Vector2(57, 46), Vector2(62, 36), 2.2, 1.8, cr, 3)
	# струйки воды изо рта в чашу
	for k in range(14):
		var t: float = float(k) / 13.0
		var p1: Vector2 = Vector2(48 - t * 18.0, 28 + t * t * 44.0)
		var p2: Vector2 = Vector2(48 + t * 18.0, 28 + t * t * 44.0)
		for pp in [p1, p2]:
			px(im, int(pp.x), int(pp.y), WATER[7])
			px(im, int(pp.x), int(pp.y) + 1, WATER[5])
	outline_auto(im, 0.45)
	save3(im, "cat_fountain")


func gen_fish_rack() -> void:
	var im: Image = new_img(64, 52)
	thick_line(im, Vector2(6, 50), Vector2(12, 8), 3.0, WOOD, 0.45)
	thick_line(im, Vector2(18, 50), Vector2(12, 8), 3.0, WOOD, 0.35)
	thick_line(im, Vector2(46, 50), Vector2(52, 8), 3.0, WOOD, 0.45)
	thick_line(im, Vector2(58, 50), Vector2(52, 8), 3.0, WOOD, 0.35)
	thick_line(im, Vector2(10, 10), Vector2(54, 10), 2.5, WOOD, 0.55)
	var fishc: Array = hx(["3a4a5a", "5a7088", "86a0b4", "b8ccd8", "e8f0f4"])
	for k in range(6):
		var fx: int = 16 + k * 6
		for y in range(11, 15):
			px(im, fx, y, Color("d8c49a"))
		for j in range(14):
			var hw: float = sin(float(j) / 13.0 * PI) * 2.6 + 0.4
			for x in range(int(fx - hw), int(fx + hw) + 1):
				var v: int = 3 if x < fx else 2
				if j > 11:
					v = 1
				px(im, x, 15 + j, fishc[v])
		px(im, fx - 1, 28, fishc[1])
		px(im, fx + 1, 28, fishc[1])
		px(im, fx, 17, Color("1a1a22"))
	outline_auto(im, 0.45)
	save3(im, "fish_rack")


func gen_yarn_basket() -> void:
	var im: Image = new_img(40, 30)
	var wick: Array = hx(["5a3a1e", "7a5228", "9a6c36", "b88a4a", "d4a862"])
	var balls: Array = [[Vector2(12, 12), hx(["8a2a4a", "c04a6a", "e8789a", "fcb0c8"])], [Vector2(21, 10), hx(["2a4a8a", "4a72c0", "78a2e8", "b8d4fc"])], [Vector2(28, 13), hx(["8a6a1a", "c09a2a", "e8c84a", "fce890"])]]
	for bb in balls:
		var bp: Vector2 = bb[0]
		var col: Array = bb[1]
		for y in range(int(bp.y) - 6, int(bp.y) + 7):
			for x in range(int(bp.x) - 6, int(bp.x) + 7):
				var d: float = Vector2(x + 0.5, y + 0.5).distance_to(bp)
				if d > 5.6:
					continue
				var v: int = 2 + (1 if (x - bp.x) + (y - bp.y) < -2 else 0) - (1 if d > 4.4 else 0)
				if posmod(x + y * 2, 4) == 0:
					v -= 1
				px(im, x, y, col[clampi(v, 0, 3)])
	for y in range(14, 28):
		var hw: float = 15.0 - float(y - 14) * 0.25
		for x in range(int(20 - hw), int(20 + hw)):
			var v2: float = 0.55 + (0.2 if posmod(x + (y / 2) * 2, 4) < 2 else -0.05) - float(y - 14) * 0.02
			if y == 14:
				v2 = 0.85
			px(im, x, y, pick(wick, v2, x, y))
	# нитка свисает к земле
	for k in range(9):
		px(im, 33 + k / 3, 14 + k * 2 / 3 + k, Color("e8789a"))
	outline_auto(im, 0.45)
	save3(im, "yarn_basket")


func gen_cat_tower() -> void:
	var im: Image = new_img(44, 84)
	var rope: Array = hx(["8a6a3a", "b08c50", "d0ac6a", "e8cc8c"])
	var cush: Array = hx(["8a3a5a", "b8587a", "dc80a0", "f4b0c8"])
	for post in [[12, 30, 80], [30, 10, 80]]:
		for y in range(int(post[1]), int(post[2])):
			for x in range(int(post[0]) - 3, int(post[0]) + 3):
				var v: int = 2 if x < int(post[0]) else 1
				if posmod(y, 3) == 0:
					v -= 1
				if x == int(post[0]) - 3:
					v = 3
				px(im, x, y, rope[clampi(v, 0, 3)])
	for pl in [[4, 26, 22], [20, 8, 20], [2, 56, 40]]:
		planks(im, int(pl[0]), int(pl[1]), int(pl[2]), 4, WOOD, false, 4, 0.5, 3)
		for x in range(int(pl[0]) + 1, int(pl[0]) + int(pl[2]) - 1):
			for y in range(int(pl[1]) - 3, int(pl[1])):
				px(im, x, y, cush[2] if y > int(pl[1]) - 2 else cush[3])
	planks(im, 0, 78, 44, 6, WOOD, false, 6, 0.4, 7)
	# игрушка-мышка на верёвочке
	for y in range(30, 42):
		px(im, 22, y, Color("d8c49a"))
	ell(im, 22, 44, 3, 2, Color("8e8a96"))
	px(im, 20, 43, Color("f0a8b0"))
	outline_auto(im, 0.45)
	save3(im, "cat_tower")


func gen_cat_stall() -> void:
	var im: Image = new_img(96, 84)
	# столбы и прилавок
	for sx in [8, 86]:
		planks(im, int(sx), 22, 4, 60, WOOD, true, 4, 0.45, int(sx))
	planks(im, 4, 52, 88, 26, WOOD, false, 6, 0.42, 3)
	# полосатый навес розовый/белый с фестонами
	for y in range(8, 30):
		var t: float = float(y - 8) / 22.0
		var hw: float = 40.0 + t * 8.0
		for x in range(int(48 - hw), int(48 + hw)):
			var stripe: int = int(floor((x - (48 - hw)) / (2.0 * hw) * 10.0))
			var base: Color = Color("e88aa4") if stripe % 2 == 0 else Color("fbf2ee")
			var sc: float = 1.0 - t * 0.15
			if y > 26:
				var bump: float = sin(float(x) * PI / (2.0 * hw / 10.0))
				if bump < 0.0:
					continue
			px(im, x, y, base * Color(sc, sc, sc))
	for x in range(8, 89):
		px(im, x, 8, Color("a04a64"))
	# товары: рыбки, бутылки молока, клубки
	var fishc: Array = hx(["3a4a5a", "5a7088", "86a0b4", "b8ccd8"])
	for k in range(4):
		var fx: int = 14 + k * 9
		ell(im, fx, 48, 4, 2, fishc[2])
		px(im, fx + 4, 47, fishc[1])
		px(im, fx + 4, 49, fishc[1])
		px(im, fx - 2, 47, Color("1a1a22"))
	for k2 in range(3):
		var bx: int = 56 + k2 * 7
		rect(im, bx, 40, 5, 10, Color("f4f4f0"))
		rect(im, bx + 1, 38, 3, 2, Color("e0e0dc"))
		rect(im, bx + 1, 36, 3, 2, Color("4a72c0"))
		px(im, bx + 1, 42, Color("ffffff"))
	disc(im, 82, 47, 3.4, Color("e8789a"))
	disc(im, 76, 48, 3.0, Color("78a2e8"))
	outline_auto(im, 0.45)
	save3(im, "cat_stall")


func gen_milk_cans() -> void:
	var im: Image = new_img(30, 30)
	for cn in [[9, 4], [21, 7]]:
		var x0: int = int(cn[0])
		var y0: int = int(cn[1])
		for y in range(y0, 28):
			var hw: float = 3.0 if y < y0 + 4 else 6.0
			for x in range(int(x0 - hw), int(x0 + hw)):
				var u: float = (x + 0.5 - (x0 - hw)) / (2.0 * hw)
				var v: float = 0.7 - u * 0.4 + (0.2 if u < 0.25 else 0.0)
				if y == y0 + 4 or y == 27:
					v -= 0.25
				px(im, x, y, pick(PORCELAIN, v, x, y))
		rect(im, x0 - 4, y0 - 1, 8, 2, IRON[3])
	outline_auto(im, 0.45)
	save3(im, "milk_cans")


# ================================================================== паутинный лес

const SILK: Array = ["5e5878", "8a84a4", "b0aac6", "d2cee2", "eae8f4", "f9f8fd"]
const THREAD: Color = Color(0.93, 0.94, 1.0, 0.78)
const SPIDER_LOOKS: Array = [
	# имя, тело (тёмный → светлый), узор, щёчки
	["spider_lilac", ["241a34", "38284e", "52406e", "6e5a92", "927eb6", "b8a6d8", "dcd0f0"], "f4b0d0"],
	["spider_tan", ["2e1c12", "4a2e1c", "6a442a", "8e623e", "b08458", "cca678", "e4caa2"], "fff0d0"],
	["spider_ink", ["0e0c14", "1a1824", "28243a", "3a3650", "524e6c", "706c8c", "9894b0"], "ffffff"],
]


func gen_spider_forest() -> void:
	gen_web_side()
	gen_web_ground()
	gen_web_hang()
	gen_egg_sacs()
	gen_glow_shrooms()
	gen_spider_nest()
	gen_spiders()
	gen_spidergirl()
	var items: Array = []
	for nm in ["spider_nest", "web_side", "web_hang", "web_ground", "egg_sacs", "glow_shrooms", "spider_lilac", "spider_tan", "spider_ink"]:
		items.append([nm, Image.load_from_file(ProjectSettings.globalize_path(OUT + String(nm) + ".png"))])
	_sheet(items, 3, "spider_preview.png")


## Нить: тонкая полупрозрачная линия, ложится поверх того, что уже нарисовано
func thread(im: Image, a: Vector2, b2: Vector2, c: Color = THREAD) -> void:
	var n: int = int(maxf(absf(b2.x - a.x), absf(b2.y - a.y))) + 1
	for i in range(n + 1):
		var p: Vector2 = a.lerp(b2, float(i) / float(n))
		var x: int = int(floor(p.x))
		var y: int = int(floor(p.y))
		if x < 0 or y < 0 or x >= im.get_width() or y >= im.get_height():
			continue
		var d: Color = im.get_pixel(x, y)
		if d.a < 0.01:
			im.set_pixel(x, y, c)
		else:
			var r: Color = d.lerp(Color(c.r, c.g, c.b, 1.0), c.a)
			r.a = maxf(d.a, c.a)
			im.set_pixel(x, y, r)


## Провисающая нить (дуга вниз)
func sag(im: Image, a: Vector2, b2: Vector2, depth: float, c: Color = THREAD) -> void:
	var prev: Vector2 = a
	for i in range(1, 9):
		var t: float = float(i) / 8.0
		var p: Vector2 = a.lerp(b2, t) + Vector2(0, sin(t * PI) * depth)
		thread(im, prev, p, c)
		prev = p


func dew(im: Image, x: int, y: int) -> void:
	px(im, x, y, Color("ffffff"))
	px(im, x, y + 1, Color("a8d8ff"))
	px(im, x + 1, y + 1, Color(0.7, 0.85, 1.0, 0.6))


## Круглая паутина: спицы и спираль; anchors — куда крепятся длинные нити
func orb_web(im: Image, c: Vector2, r: float, spokes: int, rings: int, seed_v: int, anchors: Array = []) -> void:
	var ang: Array = []
	var rad: Array = []
	for i in range(spokes):
		ang.append(TAU * float(i) / float(spokes) + (h01(i, seed_v, 3) - 0.5) * 0.25)
		rad.append(r * (0.85 + h01(i, seed_v, 4) * 0.2))
	for i in range(spokes):
		thread(im, c, c + Vector2(cos(ang[i]), sin(ang[i]) * 0.92) * float(rad[i]))
	for k in range(1, rings + 1):
		var f: float = float(k) / float(rings + 1)
		for i in range(spokes):
			var j: int = (i + 1) % spokes
			var p0: Vector2 = c + Vector2(cos(ang[i]), sin(ang[i]) * 0.92) * float(rad[i]) * f
			var p1: Vector2 = c + Vector2(cos(ang[j]), sin(ang[j]) * 0.92) * float(rad[j]) * f
			sag(im, p0, p1, 0.8 + f * 1.2, Color(0.93, 0.94, 1.0, 0.55 + 0.2 * (1.0 - f)))
			if h01(i, k, seed_v) > 0.82:
				dew(im, int(p0.x), int(p0.y))
	for an in anchors:
		var av: Vector2 = an
		var best: Vector2 = c
		var bd: float = 1e9
		for i in range(spokes):
			var q: Vector2 = c + Vector2(cos(ang[i]), sin(ang[i]) * 0.92) * float(rad[i])
			if q.distance_to(av) < bd:
				bd = q.distance_to(av)
				best = q
		thread(im, best, av)
	disc(im, c.x, c.y, 1.3, Color(0.96, 0.96, 1.0, 0.9))


## Паутина у ствола: крепится к стволу слева, к кроне сверху и к земле справа.
## Ставится так, что левый край картинки — у ствола дерева.
func gen_web_side() -> void:
	var im: Image = new_img(76, 96)
	orb_web(im, Vector2(38, 44), 26.0, 12, 7, 5, [Vector2(0, 30), Vector2(1, 70), Vector2(20, 0), Vector2(56, 2), Vector2(74, 94), Vector2(30, 95)])
	# паучок-хозяин в серединке
	ell(im, 38, 45, 2.5, 3.0, Color("3a2c50"))
	ell(im, 38, 42, 1.8, 1.6, Color("52406e"))
	px(im, 37, 42, Color("ffffff"))
	px(im, 39, 42, Color("ffffff"))
	for s in [-1, 1]:
		for k in range(3):
			thread(im, Vector2(38 + s, 44 + k), Vector2(38 + s * 5, 41 + k * 3), Color("3a2c50"))
	save3(im, "web_side")


func gen_web_hang() -> void:
	# паутина свисает из кроны: несколько нитей с росой и маленькая сеточка
	var im: Image = new_img(40, 70)
	for k in range(5):
		var x0: float = 6.0 + k * 7.0
		var ln: float = 30.0 + h01(k, 2, 9) * 36.0
		thread(im, Vector2(x0, 0), Vector2(x0 + sin(k * 1.7) * 2.0, ln), Color(0.93, 0.94, 1.0, 0.6))
		dew(im, int(x0 + sin(k * 1.7) * 2.0), int(ln) - 1)
	orb_web(im, Vector2(20, 20), 12.0, 9, 4, 8, [Vector2(4, 0), Vector2(36, 0)])
	save3(im, "web_hang")


func gen_web_ground() -> void:
	var im: Image = new_img(48, 26)
	var c: Vector2 = Vector2(24, 14)
	for i in range(10):
		var a: float = TAU * i / 10.0
		thread(im, c, c + Vector2(cos(a) * 22.0, sin(a) * 11.0), Color(0.95, 0.96, 1.0, 0.55))
	for k in range(1, 5):
		var f: float = k / 5.0
		for i in range(10):
			var a0: float = TAU * i / 10.0
			var a1: float = TAU * (i + 1) / 10.0
			thread(im, c + Vector2(cos(a0) * 22.0, sin(a0) * 11.0) * f, c + Vector2(cos(a1) * 22.0, sin(a1) * 11.0) * f, Color(0.95, 0.96, 1.0, 0.42))
	dew(im, 30, 10)
	dew(im, 15, 17)
	save3(im, "web_ground")


## Кладка яиц в шёлковых коконах: круглые, жемчужные, с сиреневым отливом
func gen_egg_sacs() -> void:
	var im: Image = new_img(36, 30)
	var silk: Array = hx(SILK)
	ell(im, 18, 26, 16, 3.5, Color(0.2, 0.15, 0.3, 0.35))
	for e in [[10, 20, 6.5], [24, 21, 6.0], [17, 14, 6.8], [28, 13, 4.5]]:
		blob(im, float(e[0]), float(e[1]), float(e[2]), float(e[2]) * 0.92, silk, 3)
		# нити оплётки
		for k in range(3):
			var yy: int = int(e[1]) - 2 + k * 2
			for x in range(int(e[0]) - int(e[2]) + 1, int(e[0]) + int(e[2]) - 1):
				if posmod(x + k * 3, 5) == 0:
					px(im, x, yy + int(sin(x * 0.7) * 1.0), silk[5])
		px(im, int(e[0]) - 2, int(e[1]) - 3, Color("ffffff"))
		px(im, int(e[0]) + 1, int(e[1]) + 2, Color("e4c8f0"))
	thread(im, Vector2(17, 8), Vector2(15, 0))
	save3(im, "egg_sacs")


## Светящиеся грибы: сиреневые и бирюзовые шляпки с огоньками
func gen_glow_shrooms() -> void:
	var im: Image = new_img(34, 30)
	var caps: Array = [hx(["3a1e5a", "5e3490", "8c5ac8", "b88ae8", "e0c8ff"]), hx(["14404e", "1e6a7a", "34a0aa", "68d4d0", "c0fff4"])]
	var list: Array = [[9, 26, 6.0, 12, 0], [22, 27, 7.5, 16, 1], [29, 28, 4.0, 8, 0], [15, 28, 3.5, 6, 1]]
	for m in list:
		var x: float = float(m[0])
		var base: float = float(m[1])
		var r: float = float(m[2])
		var h: float = float(m[3])
		var cr: Array = caps[int(m[4])]
		for y in range(int(base - h), int(base)):
			for xx in range(int(x - 1.5), int(x + 1.5)):
				px(im, xx, y, Color("d8d0e4") if xx < int(x) else Color("a89cba"))
		for y2 in range(int(base - h - r * 0.75), int(base - h + 2)):
			for x2 in range(int(x - r) - 1, int(x + r) + 1):
				var dx: float = (x2 + 0.5 - x) / r
				var dy: float = (y2 + 0.5 - (base - h + 1.0)) / (r * 0.78)
				if dx * dx + dy * dy > 1.0 or y2 > int(base - h + 1):
					continue
				var t: int = 3 if dx < -0.2 and dy < -0.4 else (2 if dx < 0.4 else 1)
				if y2 == int(base - h + 1):
					t = 0
				px(im, x2, y2, cr[t])
		px(im, int(x - r * 0.4), int(base - h - r * 0.4), cr[4])
		px(im, int(x + r * 0.3), int(base - h - r * 0.2), cr[4])
	save3(im, "glow_shrooms")


## Логово девочки-паука: шёлковый купол-кокон с круглой дверцей и тёплым светом внутри
func gen_spider_nest() -> void:
	var W: int = 160
	var H: int = 170
	var im: Image = new_img(W, H)
	var silk: Array = hx(SILK)
	var c: Vector2 = Vector2(80, 112)
	# нити вверх, в кроны
	for k in range(6):
		var xa: float = 40.0 + k * 16.0
		thread(im, Vector2(xa + sin(k) * 6.0, 0), Vector2(c.x + (xa - 80.0) * 0.5, c.y - 54), Color(0.93, 0.94, 1.0, 0.7))
	ell(im, c.x, c.y + 44, 70, 9, Color(0.18, 0.14, 0.28, 0.35))
	for y in range(int(c.y) - 62, int(c.y) + 46):
		for x in range(8, W - 8):
			var dx: float = (x + 0.5 - c.x) / 66.0
			var dy: float = (y + 0.5 - c.y) / 62.0
			if y > c.y:
				dy = (y + 0.5 - c.y) / 46.0
			var d2: float = dx * dx + dy * dy
			if d2 > 1.0:
				continue
			# свет сверху-слева по сфере + плетение крест-накрест
			var nz: float = sqrt(maxf(0.0, 1.0 - d2))
			var l: float = Vector3(dx, dy, nz).normalized().dot(Vector3(-0.5, -0.7, 0.55).normalized())
			var v: float = 0.45 + l * 0.42
			var w1: float = fposmod(float(x + y) * 0.5, 4.0)
			var w2: float = fposmod(float(x - y) * 0.5, 4.0)
			if w1 < 0.6 or w2 < 0.6:
				v += 0.12
			if (w1 < 0.6) != (w2 < 0.6) and h01(x / 2, y / 2, 31) > 0.6:
				v -= 0.08
			if d2 > 0.9:
				v -= 0.25
			px(im, x, y, pick(silk, v, x, y))
	# свисающие пряди шёлка по низу
	for k2 in range(14):
		var hx2: int = 20 + k2 * 9 + int(h01(k2, 1, 2) * 4.0)
		var top: int = int(c.y + 46.0 * sqrt(maxf(0.0, 1.0 - pow((hx2 - c.x) / 66.0, 2.0)))) - 3
		for y3 in range(top, top + 4 + int(h01(k2, 2, 3) * 5.0)):
			px(im, hx2, y3, silk[3])
			px(im, hx2 + 1, y3, silk[2])
	# дверца: круглая, внутри тёплый свет
	var dc: Vector2 = Vector2(80, 132)
	for y in range(int(dc.y) - 21, int(dc.y) + 26):
		for x in range(int(dc.x) - 21, int(dc.x) + 22):
			var dd: float = Vector2((x + 0.5 - dc.x) / 20.0, (y + 0.5 - dc.y) / 22.0).length()
			if dd > 1.0 or y > 155:
				continue
			if dd > 0.86:
				px(im, x, y, silk[1])
				continue
			var g: float = 1.0 - dd
			var col: Color = Color("2a1a3a").lerp(Color("f2b866"), clampf(g * 1.4 - 0.1 + (0.0 if y > dc.y + 6 else 0.15), 0.0, 1.0))
			px(im, x, y, col)
	# подушки внутри и фонарик-грибок
	ell(im, 72, 150, 7, 3, Color("8a5a9a"))
	ell(im, 88, 151, 6, 2.5, Color("c06a8a"))
	disc(im, 80, 120, 3.0, Color("ffe6a0"))
	px(im, 80, 120, Color("ffffff"))
	# круглые окошки
	for wv in [Vector2(42, 96), Vector2(118, 98)]:
		disc(im, wv.x, wv.y, 7.0, silk[1])
		disc(im, wv.x, wv.y, 5.5, Color("f0c070"))
		px(im, int(wv.x) - 2, int(wv.y) - 2, Color("fff4c8"))
		thread(im, wv + Vector2(-5, 0), wv + Vector2(5, 0), silk[1])
		thread(im, wv + Vector2(0, -5), wv + Vector2(0, 5), silk[1])
	# маленькая паутинка-флажок на куполе и роса
	orb_web(im, Vector2(120, 64), 11.0, 8, 3, 21)
	for k3 in range(12):
		dew(im, 20 + int(h01(k3, 5, 6) * 120.0), 60 + int(h01(k3, 6, 7) * 80.0))
	outline_auto(im, 0.35)
	save3(im, "spider_nest")


# ---------------------------------------------------------------- добрые пауки

## Пушистый паучок с большими глазками. Кадры: 0-3 шаг, 4 стоит, 5 моргнул. 36x28.
func draw_spider(im: Image, f: int, body: Array, mark: Color, blush: Color) -> void:
	var bob: int = 1 if f == 1 or f == 3 else 0
	var c: Vector2 = Vector2(18, 13 - bob)
	# лапки: 4 с каждой стороны, шагают «через одну»
	for s in [-1, 1]:
		for i in range(4):
			var up: bool = ((i + (0 if s < 0 else 1)) % 2 == 0) == (f == 0 or f == 1)
			var lift: float = 2.0 if (up and f < 4) else 0.0
			var hip: Vector2 = Vector2(18 + s * 4, 15 + i * 1.2 - bob)
			var knee: Vector2 = Vector2(18 + s * (10 + i * 1.6), 7 + i * 2.6 - lift - bob)
			var foot: Vector2 = Vector2(18 + s * (13 + i * 1.8) + (s * 1.0 if lift > 0.0 else 0.0), 23 + i * 1.0 - lift)
			for seg in [[hip, knee], [knee, foot]]:
				var a: Vector2 = seg[0]
				var b2: Vector2 = seg[1]
				var n: int = int(a.distance_to(b2)) + 1
				for k in range(n + 1):
					var p: Vector2 = a.lerp(b2, float(k) / float(n))
					px(im, int(p.x), int(p.y), body[1])
					px(im, int(p.x), int(p.y) - 1, body[3] if i < 2 else body[2])
			px(im, int(knee.x), int(knee.y) - 1, body[4])
	# брюшко пушистое (край «шерстяной»)
	for y in range(int(c.y) - 9, int(c.y) + 9):
		for x in range(int(c.x) - 11, int(c.x) + 11):
			var dx: float = (x + 0.5 - c.x) / 9.5
			var dy: float = (y + 0.5 - c.y) / 7.6
			var d: float = sqrt(dx * dx + dy * dy)
			var fuzz: float = (h01(x, y, 17) - 0.5) * 0.14
			if d > 1.0 + fuzz:
				continue
			var l: float = -dx * 0.5 - dy * 0.7
			var t: int = 3 + int(round(l * 1.6))
			if d > 0.86:
				t -= 1
			if posmod(x + y, 3) == 0 and d > 0.5:
				t -= 1
			px(im, x, y, body[clampi(t, 0, 6)])
	# узор: сердечко на брюшке
	var hc: Vector2 = c + Vector2(0, -3)
	for p2 in [Vector2(-2, -1), Vector2(-1, -1), Vector2(1, -1), Vector2(2, -1), Vector2(-2, 0), Vector2(-1, 0), Vector2(0, 0), Vector2(1, 0), Vector2(2, 0), Vector2(-1, 1), Vector2(0, 1), Vector2(1, 1), Vector2(0, 2)]:
		px(im, int(hc.x + p2.x), int(hc.y + p2.y), mark)
	# головогрудь спереди
	var hd: Vector2 = Vector2(18, 19 - bob)
	blob(im, hd.x, hd.y, 6.6, 4.8, body, 3)
	# глазки: два больших с бликом, два маленьких сверху
	for s2 in [-1, 1]:
		var e: Vector2 = hd + Vector2(s2 * 2.7, 0.2)
		if f == 5:
			px(im, int(e.x) - 1, int(e.y) + 1, Color("100a14"))
			px(im, int(e.x), int(e.y) + 1, Color("100a14"))
			px(im, int(e.x) + 1, int(e.y) + 1, Color("100a14"))
		else:
			disc(im, e.x, e.y, 2.2, Color("100a14"))
			px(im, int(e.x) - 1, int(e.y) - 1, Color("ffffff"))
			px(im, int(e.x), int(e.y) - 1, Color("ffffff"))
			px(im, int(e.x) + 1, int(e.y) + 1, Color("7a8ab0"))
		px(im, int(hd.x + s2 * 1.5), int(hd.y) - 3, Color("100a14"))
		px(im, int(hd.x + s2 * 5.0), int(hd.y) + 2, blush)
	px(im, int(hd.x), int(hd.y) + 3, body[0])
	px(im, int(hd.x) - 1, int(hd.y) + 3, body[1])


func gen_spiders() -> void:
	for lk in SPIDER_LOOKS:
		var body: Array = hx(lk[1])
		var sheet: Image = new_img(36 * 6, 28)
		for f in range(6):
			var cell: Image = new_img(36, 28)
			draw_spider(cell, f, body, Color(String(lk[2])), Color("f08aa8"))
			outline_auto(cell, 0.5)
			sheet.blit_rect(cell, Rect2i(0, 0, 36, 28), Vector2i(f * 36, 0))
		save3(sheet, String(lk[0]))


# ---------------------------------------------------------------- девочка-паук

const SG_LEG: Array = ["100c16", "1c1626", "2a2238", "3c3250", "564a70", "7a6c96"]


## Паучьи ножки за спиной: 4 пары, сначала вверх-в стороны, потом коленом вниз к земле.
## view: 0 спереди/сзади (симметрично), 2 сбоку (все назад), 4 вполоборота
func spider_legs(im: Image, view: int, f: int, b: int) -> void:
	var leg: Array = hx(SG_LEG)
	var wob: float = sin(float(f) * 1.57) * 1.5 if f <= 3 else [0.0, 0.7, 1.2, 0.7][clampi(f - 4, 0, 3)]
	var root: Vector2 = Vector2(40, 48 + b)
	var sides: Array = [-1, 1]
	if view == 2:
		root = Vector2(46, 48 + b)
		sides = [1]
	for s in sides:
		# дальние ножки (снизу вверх по списку) рисуем первыми
		for ii in range(4):
			var i: int = 3 - ii
			var ph: float = wob * (1.0 if i % 2 == 0 else -1.0)
			var sp: float = 1.0 if view != 2 else 0.78
			var base: Vector2 = root + Vector2(s * 3.0, float(i) * 2.5)
			# колено высоко и в сторону, кончик — вниз и наружу; пары разнесены по высоте
			var knee: Vector2 = Vector2(root.x + s * (13.0 + i * 5.0) * sp, 12.0 + i * 10.0 + b + ph)
			var tip: Vector2 = Vector2(root.x + s * (21.0 + i * 5.2) * sp, 38.0 + i * 21.0 + b - ph * 0.6)
			var tb: int = 4 if i % 2 == 0 else 3
			capsule(im, base, knee, 1.5, 1.2, leg, tb)
			capsule(im, knee, tip.lerp(knee, 0.18), 1.2, 0.8, leg, tb)
			thread(im, tip.lerp(knee, 0.18), tip, Color(leg[2]))
			# сустав и фиолетовые колечки
			px(im, int(knee.x), int(knee.y), leg[5])
			px(im, int(knee.x), int(knee.y) - 1, Color("c070d8"))
			var mid: Vector2 = knee.lerp(tip, 0.5)
			px(im, int(mid.x), int(mid.y), Color("a050c0"))


func draw_spidergirl(im: Image, dir: int, f: int) -> void:
	var b: int = -1 if (f == 1 or f == 3 or f == 6 or f == 7) else 0
	var view: int = 0 if (dir == 0 or dir == 1) else (2 if dir == 2 else 4)
	var behind: bool = dir == 0 or dir == 2 or dir == 4
	if behind:
		spider_legs(im, view, f, b)
	draw_hero10(im, dir, f)
	if not behind:
		spider_legs(im, view, f, b)


func gen_spidergirl() -> void:
	_spidergirl_one("spidergirl", ["5a4a6e", "7e6e94", "a294b8", "c2b6d4", "dcd2ea", "eee8f6", "fbf9ff"], ["16101e", "221a30", "302642", "403458", "544872", "6e5f8e", "9282ae"])
	_spidergirl_one("spidergirl_b", ["1e1a2a", "2a2440", "3a3258", "4c4472", "625a8c", "7c74a6", "a49cc6"], ["3a1030", "5a1848", "7a2462", "9a347c", "b84e96", "d272b2", "eaa2d0"])
	_spidergirl_one("spidergirl_c", ["4a1a12", "6e2a16", "92401e", "b4582a", "d0763a", "e69652", "f6ba7a"], ["1e2a2a", "2a3e3e", "385454", "4a6c6c", "5e8686", "7aa2a2", "a0c0c0"])


func _spidergirl_one(nm: String, hair: Array, dress: Array) -> void:
	var sh: Array = HAIRL7.duplicate()
	var sw7: Array = WHITE7.duplicate()
	var st: Array = TEAL7.duplicate()
	HAIRL7 = hx(hair)
	WHITE7 = hx(dress)
	TEAL7 = hx(["3a1030", "5a1848", "7a2462", "9a347c", "b84e96", "d272b2", "eaa2d0"])
	_head_pal()
	NO_CAPE = true
	BOUNCE_OVR = 0
	var fw: int = 80
	var fh: int = 160
	var mirror: Dictionary = {2: 3, 4: 6, 5: 7}
	var vs: Image = new_img(fw * 8, fh * 8)
	for vd in [0, 1, 2, 4, 5]:
		for k in range(8):
			var c2: Image = new_img(fw, fh)
			draw_spidergirl(c2, vd, k)
			outline_auto(c2, OUTLINE_CHAR)
			vs.blit_rect(c2, Rect2i(0, 0, fw, fh), Vector2i(k * fw, vd * fh))
			if mirror.has(vd):
				var mc: Image = c2.duplicate()
				mc.flip_x()
				vs.blit_rect(mc, Rect2i(0, 0, fw, fh), Vector2i(k * fw, int(mirror[vd]) * fh))
	save3(vs, nm)
	gen_faces10("faces_" + nm)
	var all: Image = new_img(fw * 8, fh)
	for d2 in range(8):
		all.blit_rect(vs, Rect2i(4 * fw, d2 * fh, fw, fh), Vector2i(d2 * fw, 0))
	all.resize(all.get_width() * 3, all.get_height() * 3, Image.INTERPOLATE_NEAREST)
	all.save_png(ProjectSettings.globalize_path("res://").path_join("../screenshots/spidergirl_views.png"))
	NO_CAPE = false
	HAIRL7 = sh
	WHITE7 = sw7
	TEAL7 = st
	_head_pal()


# ================================================================== готика: замки, кладбище, вампиры, оборотни

const GSTONE: Array = ["16121c", "221c2a", "2e2638", "3c3248", "4c425a", "60566e", "786e86", "948aa2"]
const GSLATE: Array = ["0e0c1a", "181628", "22203a", "2e2c4c", "3c3a60", "504e78", "6a6890"]
const GGLASS: Array = ["5a1a1a", "8a2a1e", "b84a22", "e07a2e", "f6a84a", "ffd27a", "fff0c0"]
const DEADWOOD: Array = ["1a1418", "282024", "382c30", "4a3c3c", "5e4e4a", "74625a"]
var EYE_OVR: Dictionary = {}
var TAIL_R: Vector2 = Vector2(3.0, 2.2)
var WOLF: bool = false


func gen_gothic() -> void:
	gen_goth_castle("goth_castle", true)
	gen_goth_castle("goth_manor", false)
	gen_crypt()
	gen_graves()
	gen_iron_fence()
	gen_dead_tree("dead_tree_a", 3)
	gen_dead_tree("dead_tree_b", 9)
	gen_goth_lamp()
	gen_rose_bush()
	gen_bats()
	gen_vampires()
	var items: Array = []
	for nm in ["goth_castle", "goth_manor", "crypt", "grave_a", "grave_b", "grave_c", "iron_fence", "dead_tree_a", "dead_tree_b", "goth_lamp", "rose_bush", "bat"]:
		items.append([nm, Image.load_from_file(ProjectSettings.globalize_path(OUT + String(nm) + ".png"))])
	_sheet(items, 2, "gothic_preview.png")


## Стрельчатое окно: прямоугольник с острой аркой сверху, внутри светится стекло, переплёт
func lancet(im: Image, cx: float, top: int, hw: float, h: int, lit: bool = true) -> void:
	var gl: Array = hx(GGLASS)
	var st: Array = hx(GSTONE)
	var ah: float = hw * 1.9
	for y in range(top - 2, top + h + 2):
		var w: float = hw + 1.5
		if y < top + ah:
			w = (hw + 1.5) * (1.0 - pow(clampf((top + ah - y) / (ah + 2.0), 0.0, 1.0), 1.7))
		for x in range(int(floor(cx - w)), int(ceil(cx + w))):
			px(im, x, y, st[6] if x < cx else st[5])
	for y2 in range(top, top + h):
		var w2: float = hw
		if y2 < top + ah:
			w2 = hw * (1.0 - pow(clampf((top + ah - y2) / ah, 0.0, 1.0), 1.7))
		for x2 in range(int(floor(cx - w2 + 0.5)), int(floor(cx + w2 + 0.5))):
			var v: float = 0.55 + float(y2 - top) / float(h) * 0.3 if lit else 0.1
			if absf(x2 + 0.5 - cx) < 0.8 or posmod(y2 - top - int(ah), 7) == 0:
				px(im, x2, y2, st[1])
				continue
			if lit and h01(x2, y2, 41) > 0.9:
				v += 0.15
			px(im, x2, y2, pick(gl, v, x2, y2) if lit else st[1])


## Конический шпиль из сланца с крестиком-навершием
func spire(im: Image, cx: float, tip: int, base: int, r: float) -> void:
	var sl: Array = hx(GSLATE)
	for y in range(tip, base + 1):
		var t: float = float(y - tip) / float(base - tip)
		var w: float = r * pow(t, 0.9) + 0.6
		for x in range(int(floor(cx - w)), int(ceil(cx + w))):
			var u: float = (x + 0.5 - (cx - w)) / (2.0 * w)
			var v: float = 0.75 - u * 0.55
			if posmod(y - tip, 5) == 4:
				v -= 0.18
			if posmod(x + (y / 5) * 3, 6) == 0 and t > 0.2:
				v -= 0.1
			if u < 0.12:
				v += 0.12
			px(im, x, y, pick(sl, v, x, y))
	var ir: Array = hx(["0a0a10", "2a2a36", "5a5a6a"])
	for y2 in range(tip - 12, tip + 1):
		px(im, int(cx), y2, ir[1])
	for x2 in range(int(cx) - 3, int(cx) + 4):
		px(im, x2, tip - 9, ir[1])
	px(im, int(cx), tip - 12, ir[2])


func battlement(im: Image, x0: int, x1: int, y: int) -> void:
	var st: Array = hx(GSTONE)
	var x: int = x0
	while x < x1:
		for yy in range(y - 7, y):
			for xx in range(x, mini(x + 6, x1)):
				px(im, xx, yy, st[5] if xx == x else (st[4] if yy > y - 3 else st[5]))
		x += 11


## Замок (big — с двумя башнями и центральным шпилем) или особняк (одна башня)
func gen_goth_castle(name: String, big: bool) -> void:
	var W: int = 360 if big else 240
	var H: int = 400 if big else 260
	var im: Image = new_img(W, H)
	var st: Array = hx(GSTONE)
	var cx: int = W / 2
	var ground: int = H - 16
	rng.seed = 404 if big else 405
	var keep_w: int = 130 if big else 120
	var keep_top: int = 170 if big else 120
	var towers: Array = [[54, 190], [W - 54, 190]] if big else [[W - 44, 92]]
	# башни (сзади)
	for tw in towers:
		var tx: int = int(tw[0])
		var ttop: int = int(tw[1])
		stone_wall(im, Rect2i(tx - 34, ttop, 68, ground - ttop), st, 7, 10, 18, Color(st[0]), 0.42)
		for y in range(ttop, ground):
			for x in range(tx - 34, tx + 34):
				# скругление башни: края темнее
				var u: float = absf(float(x - tx) + 0.5) / 34.0
				if u > 0.7:
					bl(im, x, y, Color(0.05, 0.03, 0.08, (u - 0.7) * 1.6))
				elif x < tx - 10:
					bl(im, x, y, Color(0.6, 0.55, 0.75, 0.06))
		battlement(im, tx - 36, tx + 36, ttop)
		spire(im, float(tx), ttop - (110 if big else 90), ttop - 6, 40.0)
		for k in range(3 if big else 2):
			lancet(im, float(tx), ttop + 30 + k * 52, 6.0, 30, h01(tx, k, 3) > 0.25)
		# знамя
		var bx: int = tx + 18
		for y2 in range(ttop + 14, ttop + 60):
			var wv: int = int(sin(y2 * 0.3) * 1.0)
			for x2 in range(bx - 6 + wv, bx + 6 + wv):
				if y2 > ttop + 52 and absf(x2 - bx - wv) < float(y2 - ttop - 52):
					continue
				px(im, x2, y2, Color("8a1828") if x2 < bx + wv else Color("6a1020"))
			px(im, bx + wv, y2, Color("c8a040") if posmod(y2, 9) == 0 else Color("7a1424"))
	# главный корпус
	var kx0: int = cx - keep_w / 2
	stone_wall(im, Rect2i(kx0, keep_top, keep_w, ground - keep_top), st, 7, 10, 20, Color(st[0]), 0.48)
	for y3 in range(keep_top, ground):
		for x3 in range(kx0, kx0 + keep_w):
			var d: float = float(y3 - keep_top) / float(ground - keep_top)
			bl(im, x3, y3, Color(0.04, 0.02, 0.08, 0.22 * (1.0 - d)))
	# фронтон: острый треугольник крыши над корпусом и центральный шпиль
	var sl: Array = hx(GSLATE)
	var apex: int = keep_top - (78 if big else 70)
	for y4 in range(apex, keep_top + 2):
		var t4: float = float(y4 - apex) / float(keep_top - apex)
		var w4: float = t4 * (keep_w / 2.0 + 8.0)
		for x4 in range(int(cx - w4), int(cx + w4) + 1):
			var v4: float = 0.6 - (x4 - cx) / maxf(1.0, w4) * 0.2
			if posmod(y4, 5) == 4:
				v4 -= 0.18
			px(im, x4, y4, pick(sl, v4, x4, y4))
	if big:
		spire(im, float(cx), apex - 70, apex + 20, 16.0)
	# окно-роза
	var rc: Vector2 = Vector2(cx, keep_top + 34)
	var gl: Array = hx(GGLASS)
	disc(im, rc.x, rc.y, 20.0, st[6])
	disc(im, rc.x, rc.y, 17.0, st[1])
	for y5 in range(int(rc.y) - 16, int(rc.y) + 17):
		for x5 in range(int(rc.x) - 16, int(rc.x) + 17):
			var q: Vector2 = Vector2(x5 + 0.5, y5 + 0.5) - rc
			var r5: float = q.length()
			if r5 > 15.5:
				continue
			var a5: float = atan2(q.y, q.x)
			var petal: float = absf(sin(a5 * 4.0))
			if r5 < 4.0:
				px(im, x5, y5, gl[5])
			elif fposmod(a5 * 8.0 / TAU, 1.0) < 0.12 or absf(r5 - 9.0) < 0.7:
				px(im, x5, y5, st[2])
			else:
				var hue: Color = Color("c02840").lerp(Color("6a3ac0"), petal) if r5 > 9.0 else gl[3]
				px(im, x5, y5, hue.lightened(0.15 if q.x + q.y < 0.0 else 0.0))
	# стрельчатые окна корпуса
	for wx in [-40, 40]:
		lancet(im, float(cx + int(wx)), keep_top + 66, 8.0, 44, true)
	if not big:
		lancet(im, float(cx), keep_top + 70, 7.0, 40, true)
	battlement(im, kx0 - 2, kx0 + keep_w + 2, keep_top + 2)
	# ворота: острая арка, тёмный проход, решётка
	var gw: float = 22.0 if big else 18.0
	var gtop: int = ground - (68 if big else 58)
	for y6 in range(gtop - 4, ground):
		var ah: float = gw * 1.7
		var w6: float = gw + 5.0
		if y6 < gtop + ah:
			w6 = (gw + 5.0) * (1.0 - pow(clampf((gtop + ah - y6) / (ah + 4.0), 0.0, 1.0), 1.7))
		for x6 in range(int(cx - w6), int(cx + w6) + 1):
			px(im, x6, y6, st[6] if (absf(x6 - cx) > w6 - 3.0 and x6 < cx) else st[5])
	for y7 in range(gtop, ground):
		var ah2: float = gw * 1.7
		var w7: float = gw
		if y7 < gtop + ah2:
			w7 = gw * (1.0 - pow(clampf((gtop + ah2 - y7) / ah2, 0.0, 1.0), 1.7))
		for x7 in range(int(cx - w7), int(cx + w7) + 1):
			var c7: Color = Color("140c10").lerp(Color("5a2a1a"), clampf(float(y7 - gtop) / 70.0, 0.0, 1.0) * 0.5)
			if posmod(x7 - cx, 6) == 0 or (posmod(y7 - gtop, 8) == 0 and y7 < ground - 20):
				c7 = Color("3a3440")
			px(im, x7, y7, c7)
	# ступени
	for k2 in range(3):
		var sy: int = ground + k2 * 4
		for x8 in range(int(cx - gw - 10 - k2 * 6), int(cx + gw + 10 + k2 * 6)):
			for yy in range(sy, sy + 4):
				px(im, x8, yy, st[6] if yy == sy else st[4])
	# мох и плющ по низу
	for k3 in range(40):
		var mx: int = rng.randi_range(10, W - 10)
		var my: int = ground - rng.randi_range(0, 30)
		if a_at(im, mx, my) > 0.5:
			px(im, mx, my, Color("3a4a34"))
			px(im, mx + 1, my, Color("4a5e40"))
	draw_ivy(im, kx0 + 4, ground, 60, 0.9)
	outline_auto(im, 0.4)
	save3(im, name)


func gen_crypt() -> void:
	var W: int = 124
	var H: int = 150
	var im: Image = new_img(W, H)
	var st: Array = hx(GSTONE)
	var cx: int = 62
	stone_wall(im, Rect2i(18, 70, 88, 66), st, 6, 9, 15, Color(st[0]), 0.5)
	# двускатная крыша-фронтон
	for y in range(26, 74):
		var t: float = float(y - 26) / 48.0
		var w: float = t * 50.0
		for x in range(int(cx - w), int(cx + w) + 1):
			var v: float = 0.62 - (x - cx) / maxf(1.0, w) * 0.2
			if absf(absf(x - cx) - w) < 2.0:
				v = 0.85
			px(im, x, y, pick(st, v, x, y))
	# колонны
	for px0 in [24, 92]:
		for y2 in range(74, 136):
			for x2 in range(int(px0), int(px0) + 8):
				var u: float = float(x2 - int(px0)) / 7.0
				px(im, x2, y2, st[6] if u < 0.35 else (st[5] if u < 0.7 else st[3]))
	# дверь — стрельчатая, кованая
	for y3 in range(88, 136):
		var ah: float = 18.0
		var w3: float = 14.0
		if y3 < 88 + ah:
			w3 = 14.0 * (1.0 - pow((88.0 + ah - y3) / ah, 1.7))
		for x3 in range(int(cx - w3), int(cx + w3) + 1):
			var c3: Color = Color("2a2232") if posmod(x3 - cx, 5) != 0 else Color("4a4058")
			if absf(x3 - cx) < 0.6:
				c3 = Color("120e16")
			px(im, x3, y3, c3)
	disc(im, cx - 4, 114, 1.4, Color("8a7a50"))
	disc(im, cx + 4, 114, 1.4, Color("8a7a50"))
	# каменный крест на коньке
	rect(im, cx - 2, 4, 5, 26, st[5])
	rect(im, cx - 8, 10, 17, 5, st[5])
	rect(im, cx - 2, 4, 2, 26, st[6])
	# ступени и мох
	for k in range(2):
		rect(im, 12 - k * 4, 136 + k * 5, 100 + k * 8, 5, st[5 - k])
	for k2 in range(30):
		var mx: int = 20 + int(h01(k2, 1, 9) * 84.0)
		var my: int = 120 + int(h01(k2, 2, 9) * 16.0)
		px(im, mx, my, Color("3e5038"))
	outline_auto(im, 0.45)
	save3(im, "crypt")


func gen_graves() -> void:
	var st: Array = hx(GSTONE)
	for kind in ["a", "b", "c"]:
		var im: Image = new_img(28, 36)
		ell(im, 14, 33, 12, 3, Color(0.1, 0.08, 0.14, 0.4))
		match kind:
			"a":
				for y in range(6, 34):
					var w: float = 9.0
					if y < 14:
						w = 9.0 * sqrt(maxf(0.0, 1.0 - pow((14.0 - y) / 8.0, 2.0)))
					for x in range(int(14 - w), int(14 + w)):
						var u: float = (x - (14 - w)) / (2.0 * w)
						px(im, x, y, st[6] if u < 0.3 else (st[5] if u < 0.8 else st[3]))
				rect(im, 11, 16, 6, 1, st[2])
				rect(im, 10, 19, 8, 1, st[2])
				rect(im, 12, 22, 4, 1, st[2])
			"b":
				rect(im, 11, 4, 6, 30, st[5])
				rect(im, 4, 10, 20, 6, st[5])
				rect(im, 11, 4, 2, 30, st[6])
				rect(im, 4, 10, 20, 2, st[6])
				rect(im, 15, 4, 2, 30, st[3])
			"c":
				for y2 in range(4, 34):
					var w2: float = 8.0
					if y2 < 16:
						w2 = 8.0 * (1.0 - pow((16.0 - y2) / 12.0, 1.6))
					for x2 in range(int(14 - w2), int(14 + w2)):
						var u2: float = (x2 - (14 - w2)) / maxf(1.0, 2.0 * w2)
						px(im, x2, y2, st[6] if u2 < 0.3 else (st[5] if u2 < 0.8 else st[3]))
				# черепок-розочка
				disc(im, 14, 20, 2.5, Color("8a1828"))
				px(im, 13, 19, Color("c03048"))
		# мох и травка у основания
		for k in range(10):
			px(im, 6 + int(h01(k, kind.unicode_at(0), 3) * 16.0), 32 - int(h01(k, 4, 5) * 3.0), Color("3e5038") if k % 2 == 0 else Color("566a44"))
		outline_auto(im, 0.45)
		save3(im, "grave_" + kind)


func gen_iron_fence() -> void:
	var im: Image = new_img(64, 44)
	var ir: Array = hx(["08080c", "16141c", "26222e", "3a3644", "56506a"])
	var st: Array = hx(GSTONE)
	for x in range(0, 64, 5):
		for y in range(8, 42):
			px(im, x, y, ir[2])
			px(im, x + 1, y, ir[1])
		# пика
		px(im, x, 6, ir[3])
		px(im, x, 5, ir[3])
		px(im, x - 1, 7, ir[2])
		px(im, x + 1, 7, ir[2])
	for ry in [12, 34]:
		for x2 in range(0, 64):
			px(im, x2, ry, ir[3])
			px(im, x2, ry + 1, ir[1])
	# завитки между рейками
	for x3 in range(2, 62, 10):
		for a in range(8):
			var an: float = float(a) / 8.0 * TAU
			px(im, x3 + 3 + int(cos(an) * 2.0), 20 + int(sin(an) * 2.0), ir[3])
	outline_auto(im, 0.35)
	save3(im, "iron_fence")


func _limb(im: Image, p: Vector2, ang: float, ln: float, w: float, depth: int, seed_v: int) -> void:
	var e: Vector2 = p + Vector2(cos(ang), sin(ang)) * ln
	thick_line(im, p, e, w, hx(DEADWOOD), 0.55)
	if depth <= 0 or w < 1.2:
		return
	var n: int = 2 if h01(depth, seed_v, 3) > 0.3 else 3
	for i in range(n):
		var da: float = (float(i) - float(n - 1) / 2.0) * 0.7 + (h01(i, depth + seed_v, 5) - 0.5) * 0.5
		_limb(im, e, ang + da, ln * (0.62 + h01(i, depth, seed_v) * 0.2), w * 0.62, depth - 1, seed_v + i * 7)


func gen_dead_tree(name: String, seed_v: int) -> void:
	var im: Image = new_img(110, 130)
	ell(im, 55, 126, 22, 4, Color(0.1, 0.08, 0.14, 0.35))
	# корни
	for k in range(4):
		thick_line(im, Vector2(55, 120), Vector2(55 + (k - 1.5) * 12.0, 128), 3.0, hx(DEADWOOD), 0.45)
	_limb(im, Vector2(55, 126), -PI / 2.0 + (h01(seed_v, 1, 2) - 0.5) * 0.3, 44.0, 9.0, 4, seed_v)
	# свисающий мох
	for k2 in range(8):
		var mx: int = 20 + int(h01(k2, seed_v, 7) * 70.0)
		var my: int = 20 + int(h01(k2, seed_v, 8) * 50.0)
		if a_at(im, mx, my) > 0.5:
			for j in range(int(4 + h01(k2, 3, seed_v) * 8.0)):
				px(im, mx, my + j, Color("4a5a48") if j % 2 == 0 else Color("3a4838"))
	outline_auto(im, 0.4)
	save3(im, name)


func gen_goth_lamp() -> void:
	var im: Image = new_img(30, 92)
	var ir: Array = hx(["08080c", "16141c", "26222e", "3a3644", "56506a"])
	for y in range(20, 90):
		px(im, 14, y, ir[2])
		px(im, 15, y, ir[3])
		px(im, 16, y, ir[1])
	rect(im, 10, 86, 11, 4, ir[2])
	# завиток-кронштейн
	for a in range(12):
		var an: float = float(a) / 12.0 * PI
		px(im, 15 + int(cos(an) * 6.0), 24 - int(sin(an) * 6.0), ir[3])
	# фонарь с алым огнём
	rect(im, 9, 6, 13, 16, ir[1])
	rect(im, 11, 8, 9, 12, Color("f0a050"))
	rect(im, 13, 11, 5, 7, Color("ffe0a0"))
	px(im, 15, 13, Color("ffffff"))
	for x in range(8, 23):
		px(im, x, 5, ir[3])
	px(im, 15, 2, ir[3])
	px(im, 15, 3, ir[3])
	px(im, 15, 4, ir[3])
	outline_auto(im, 0.35)
	save3(im, "goth_lamp")


func gen_rose_bush() -> void:
	var im: Image = new_img(40, 30)
	var lf: Array = hx(["0e2418", "183a24", "245030", "34683c", "4a8048"])
	for k in range(60):
		var x: float = 6.0 + h01(k, 1, 4) * 28.0
		var y: float = 8.0 + h01(k, 2, 4) * 18.0
		blob(im, x, y, 3.0, 2.2, lf, 2)
	var rr: Array = hx(["3a0610", "6a0a1c", "9a1428", "c82a40", "ee5a6c"])
	for k2 in range(9):
		var x2: float = 7.0 + h01(k2, 3, 6) * 26.0
		var y2: float = 7.0 + h01(k2, 4, 6) * 14.0
		disc(im, x2, y2, 2.4, rr[1])
		disc(im, x2 - 0.4, y2 - 0.4, 1.6, rr[3])
		px(im, int(x2), int(y2), rr[0])
		px(im, int(x2) - 1, int(y2) - 1, rr[4])
	outline_auto(im, 0.4)
	save3(im, "rose_bush")


## Летучая мышь: 4 кадра взмаха, 24x16
func gen_bats() -> void:
	var sheet: Image = new_img(24 * 4, 16)
	var bc: Array = hx(["0c0810", "1c1424", "2e2238", "48385a"])
	for f in range(4):
		var im: Image = new_img(24, 16)
		var wy: float = [-5.0, -1.0, 3.0, -1.0][f]
		for s in [-1, 1]:
			for i in range(10):
				var t: float = float(i) / 9.0
				var x: float = 12.0 + s * (2.0 + t * 9.0)
				var ytop: float = 7.0 + wy * t
				var ybot: float = ytop + 3.0 - t * 1.5 + (1.5 if i % 3 == 0 else 0.0)
				for y in range(int(ytop), int(ybot) + 1):
					px(im, int(x), y, bc[1] if y > int(ytop) else bc[2])
		ell(im, 12, 8, 2.5, 3.0, bc[2])
		px(im, 11, 5, bc[2])
		px(im, 13, 5, bc[2])
		px(im, 11, 7, Color("ff4040"))
		px(im, 13, 7, Color("ff4040"))
		outline_auto(im, 0.3)
		sheet.blit_rect(im, Rect2i(0, 0, 24, 16), Vector2i(f * 24, 0))
	save3(sheet, "bat")


# ---------------------------------------------------------------- вампирши и оборотни

const VAMP_LOOKS: Array = [
	# имя, волосы, платье, плащ (TEAL7), кожа, глаза [I, i, j]
	["vampire_lilith", ["0e0c14", "181624", "24203a", "322c4e", "443c66", "5a5282", "766ea0"], ["2a0a10", "44101a", "621826", "822434", "a2344a", "c05068", "dc7a8c"], ["0a0810", "141020", "1e182e", "2a2240", "382e54", "4a3e6a", "605484"], true],
	["vampire_carmilla", ["6a6a78", "8e8e9c", "b0b0bc", "ccccd6", "e0e0e8", "f0f0f6", "ffffff"], ["0c0a10", "16121c", "221c2a", "2e2638", "3c3248", "504460", "6a5e7c"], ["2a0610", "4a0a1a", "6a1026", "8a1a34", "aa2a46", "c8465e", "e2707e"], true],
	["vampire_mina", ["3a0c10", "5a141a", "7c1e22", "a02c2a", "c04434", "da6448", "f08e66"], ["1a1024", "2a1a3a", "3c2652", "50346c", "684688", "845ea6", "a680c4"], ["0a0810", "141020", "1e182e", "2a2240", "382e54", "4a3e6a", "605484"], true],
	["werewolf_luna", ["2a2a30", "3e4048", "565a64", "72767e", "90949a", "b0b2b6", "d2d4d6"], ["2a2216", "40321e", "584428", "705836", "8a7048", "a68c62", "c4aa84"], ["1e2a1e", "2a3a28", "384c34", "4a6042", "5e7652", "788e68", "98aa86"], false],
	["werewolf_rua", ["2e140c", "4a2214", "6a321e", "8c462a", "ac5e38", "c87e52", "e0a476"], ["1a1a22", "282834", "383848", "4a4a5e", "5e5e76", "767690", "9494aa"], ["2a1a10", "40281a", "583824", "704a30", "8a5e40", "a67656", "c49674"], false],
	["hunter_vesna", ["5a5a62", "7a7a84", "9a9aa4", "b8b8c0", "d2d2d8", "e6e6ea", "f6f6f8"], ["1a1a20", "26262e", "34343e", "44444e", "565662", "6c6c78", "86868e"], ["1e140e", "2e2016", "40301e", "54402a", "6a5438", "826a4a", "9e8462"], true, "hunter"],
	["hunter_morra", ["3a0c10", "561418", "741e22", "92302c", "ae4a3a", "c86a52", "e09272"], ["2a2226", "3a3034", "4c4046", "605258", "76686e", "8e8288", "aaa0a4"], ["120e14", "1c161e", "28202a", "342a38", "443848", "584a5c", "706274"], true, "hunter"],
]


func draw_wolfgirl(im: Image, dir: int, f: int) -> void:
	WOLF = true
	TAIL_R = Vector2(4.6, 3.4)
	draw_catgirl(im, dir, f)
	WOLF = false
	TAIL_R = Vector2(3.0, 2.2)


func gen_vampires() -> void:
	var sh: Array = HAIRL7.duplicate()
	var sw7: Array = WHITE7.duplicate()
	var st: Array = TEAL7.duplicate()
	var sk: Array = SKINL7.duplicate()
	var fw: int = 80
	var fh: int = 160
	var mirror: Dictionary = {2: 3, 4: 6, 5: 7}
	BOUNCE_OVR = 0
	var line_up: Image = new_img(fw * VAMP_LOOKS.size(), fh)
	var li: int = 0
	for lk in VAMP_LOOKS:
		var vamp: bool = bool(lk[4])
		var hunter: bool = lk.size() > 5 and String(lk[5]) == "hunter"
		HAIRL7 = hx(lk[1])
		WHITE7 = hx(lk[2])
		TEAL7 = hx(lk[3])
		if hunter:
			SKINL7 = sk
			EYE_OVR = {"I": Color("1a2a3a"), "i": Color("4a6a8a"), "j": Color("a0c0e0")}
		elif vamp:
			SKINL7 = hx(["6e5060", "9a7484", "c09aa8", "dcc0c8", "ecdce0", "f6eef0", "fffafc"])
			EYE_OVR = {"I": Color("5a0a14"), "i": Color("c01830"), "j": Color("ff6070")}
		else:
			SKINL7 = sk
			EYE_OVR = {"I": Color("5a3a0a"), "i": Color("c88a1a"), "j": Color("ffd060")}
		_head_pal()
		NO_CAPE = not vamp
		var vs: Image = new_img(fw * 8, fh * 8)
		for vd in [0, 1, 2, 4, 5]:
			for k in range(8):
				var c2: Image = new_img(fw, fh)
				if vamp:
					draw_hero10(c2, vd, k)
				else:
					draw_wolfgirl(c2, vd, k)
				outline_auto(c2, OUTLINE_CHAR)
				vs.blit_rect(c2, Rect2i(0, 0, fw, fh), Vector2i(k * fw, vd * fh))
				if mirror.has(vd):
					var mc: Image = c2.duplicate()
					mc.flip_x()
					vs.blit_rect(mc, Rect2i(0, 0, fw, fh), Vector2i(k * fw, int(mirror[vd]) * fh))
		save3(vs, String(lk[0]))
		gen_faces10("faces_" + String(lk[0]))
		line_up.blit_rect(vs, Rect2i(4 * fw, 0, fw, fh), Vector2i(li * fw, 0))
		li += 1
	line_up.resize(line_up.get_width() * 3, line_up.get_height() * 3, Image.INTERPOLATE_NEAREST)
	line_up.save_png(ProjectSettings.globalize_path("res://").path_join("../screenshots/gothic_lineup.png"))
	EYE_OVR = {}
	NO_CAPE = false
	HAIRL7 = sh
	WHITE7 = sw7
	TEAL7 = st
	SKINL7 = sk
	_head_pal()


# ================================================================== рыцари: замки, турнир, тренировочный двор

const KSTONE: Array = ["4a4a54", "62626e", "7c7c88", "9898a2", "b2b2ba", "cacad0", "e0e0e4", "f2f2f4"]
const KROOF: Array = ["3e1416", "62201e", "862c26", "a63a2e", "c2503a", "d86c4c", "eb9068"]
const KBLUE: Array = ["14203e", "1e305a", "2a4478", "3a5c98", "5078b4", "6e96cc", "98b8e0"]
var KNIGHT_ARMOR: bool = false


func gen_knights() -> void:
	gen_knight_castle("knight_castle", true)
	gen_knight_castle("knight_fort", false)
	gen_tent("tent_red", hx(KROOF))
	gen_tent("tent_blue", hx(KBLUE))
	gen_tilt_fence()
	gen_dummy()
	gen_weapon_rack()
	gen_hay_bale()
	gen_banner_pole()
	gen_archery_target()
	gen_knight_girls()
	var items: Array = []
	for nm in ["knight_castle", "knight_fort", "tent_red", "tent_blue", "tilt_fence", "dummy", "weapon_rack", "hay_bale", "banner_pole", "archery_target"]:
		items.append([nm, Image.load_from_file(ProjectSettings.globalize_path(OUT + String(nm) + ".png"))])
	_sheet(items, 2, "knight_preview.png")


func kbattle(im: Image, x0: int, x1: int, y: int, ramp: Array) -> void:
	var x: int = x0
	while x < x1:
		for yy in range(y - 8, y):
			for xx in range(x, mini(x + 7, x1)):
				var v: int = 6 if xx == x else (5 if yy < y - 2 else 4)
				if xx == mini(x + 7, x1) - 1:
					v = 3
				px(im, xx, yy, ramp[v])
		x += 12


## Знамя: красное полотнище с золотым кантом и гербом-коронкой, хвост ласточкой
func banner(im: Image, x: int, y0: int, w: int, h: int, ramp: Array) -> void:
	for y in range(y0, y0 + h):
		var wv: int = int(round(sin(y * 0.25) * 0.8))
		for xx in range(x - w / 2 + wv, x + w / 2 + wv):
			var rel: int = y - y0
			if rel > h - 8 and absi(xx - x - wv) < (rel - (h - 8)):
				continue
			var c: Color = ramp[4] if xx < x + wv else ramp[3]
			if xx == x - w / 2 + wv or xx == x + w / 2 + wv - 1:
				c = Color("d8b040")
			px(im, xx, y, c)
	# коронка
	var cy: int = y0 + h / 2 - 4
	for xx2 in range(x - 3, x + 4):
		px(im, xx2, cy + 3, Color("f0c850"))
		px(im, xx2, cy + 4, Color("c89a30"))
	for tx in [-3, 0, 3]:
		px(im, x + int(tx), cy + 2, Color("f0c850"))
		px(im, x + int(tx), cy + 1, Color("f0c850"))


## Светлое окошко с полукруглым верхом
func arch_win(im: Image, cx: int, top: int, hw: int, h: int) -> void:
	var st: Array = hx(KSTONE)
	for y in range(top - 2, top + h + 2):
		for x in range(cx - hw - 2, cx + hw + 2):
			var dy: float = float(y - (top + hw))
			if dy < 0.0 and Vector2(x + 0.5 - cx, dy).length() > hw + 2:
				continue
			px(im, x, y, st[6] if x < cx else st[5])
	for y2 in range(top, top + h):
		for x2 in range(cx - hw, cx + hw):
			var dy2: float = float(y2 - (top + hw))
			if dy2 < 0.0 and Vector2(x2 + 0.5 - cx, dy2).length() > hw:
				continue
			px(im, x2, y2, Color("2a2030").lerp(Color("e8a050"), 0.35 + float(y2 - top) / float(h) * 0.4))
	for y3 in range(top + 2, top + h):
		px(im, cx, y3, st[2])


## Круглая башня с зубцами и красной конической крышей с флажком
func round_tower(im: Image, cx: int, top: int, bot: int, r: int, roof: bool) -> void:
	var st: Array = hx(KSTONE)
	stone_wall(im, Rect2i(cx - r, top, r * 2, bot - top), st, 7, 9, 15, Color(st[1]), 0.55)
	for y in range(top, bot):
		for x in range(cx - r, cx + r):
			var u: float = (float(x - cx) + 0.5) / float(r)
			if u > 0.45:
				bl(im, x, y, Color(0.1, 0.08, 0.16, (u - 0.45) * 0.55))
			elif u < -0.5:
				bl(im, x, y, Color(1, 1, 1, (-u - 0.5) * 0.18))
	kbattle(im, cx - r - 3, cx + r + 3, top + 1, st)
	for k in range(2):
		var sy: int = top + 26 + k * 36
		if sy + 14 < bot:
			rect(im, cx - 1, sy, 3, 12, st[0])
	if roof:
		var rf: Array = hx(KROOF)
		var rt: int = top - 62
		for y2 in range(rt, top - 6):
			var t: float = float(y2 - rt) / float(top - 6 - rt)
			var w: float = (r + 5.0) * t + 0.5
			for x2 in range(int(cx - w), int(cx + w) + 1):
				var u2: float = (x2 + 0.5 - (cx - w)) / (2.0 * w)
				var v: float = 0.78 - u2 * 0.5
				if posmod(y2 - rt, 6) == 5:
					v -= 0.16
				if posmod(x2 + (y2 / 6) * 3, 7) == 0:
					v -= 0.06
				px(im, x2, y2, pick(rf, v, x2, y2))
		for y3 in range(rt - 16, rt + 1):
			px(im, cx, y3, Color("3a2a1a"))
		for y4 in range(rt - 16, rt - 9):
			for x4 in range(cx + 1, cx + 12 - (y4 - (rt - 16))):
				px(im, x4, y4, Color("c8303a") if y4 < rt - 12 else Color("a02430"))


func gen_knight_castle(name: String, big: bool) -> void:
	var W: int = 460 if big else 240
	var H: int = 380 if big else 300
	var im: Image = new_img(W, H)
	var st: Array = hx(KSTONE)
	var cx: int = W / 2
	var ground: int = H - 14
	rng.seed = 707 if big else 708
	# донжон сзади
	var kw: int = 150 if big else 110
	var ktop: int = 110 if big else 100
	stone_wall(im, Rect2i(cx - kw / 2, ktop, kw, ground - ktop), st, 7, 10, 18, Color(st[1]), 0.5)
	for y in range(ktop, ground):
		for x in range(cx - kw / 2, cx + kw / 2):
			bl(im, x, y, Color(0.12, 0.1, 0.2, 0.18))
	kbattle(im, cx - kw / 2 - 3, cx + kw / 2 + 3, ktop + 1, st)
	for wx in [-40, 0, 40] if big else [-26, 26]:
		arch_win(im, cx + int(wx), ktop + 28, 5, 20)
	# флагшток на донжоне
	for y2 in range(ktop - 60, ktop - 6):
		px(im, cx, y2, Color("3a2a1a"))
		px(im, cx + 1, y2, Color("5a4228"))
	banner(im, cx + 14, ktop - 58, 24, 34, hx(KROOF) if big else hx(KBLUE))
	# крепостная стена спереди
	var wtop: int = 230 if big else 180
	var wx0: int = 34 if big else 26
	var wx1: int = W - 34 if big else W - 26
	stone_wall(im, Rect2i(wx0, wtop, wx1 - wx0, ground - wtop), st, 7, 11, 20, Color(st[1]), 0.58)
	kbattle(im, wx0 - 2, wx1 + 2, wtop + 1, st)
	for sx in range(wx0 + 30, wx1 - 20, 46):
		if absi(sx - cx) > 50:
			rect(im, sx, wtop + 24, 3, 14, st[0])
	# угловые башни
	var tr: int = 38 if big else 30
	round_tower(im, wx0 + 6, wtop - (60 if big else 46), ground, tr, true)
	round_tower(im, wx1 - 6, wtop - (60 if big else 46), ground, tr, true)
	# ворота: полукруглая арка, дубовые створки с заклёпками, решётка поднята наполовину
	var gw: int = 30 if big else 22
	var gtop: int = ground - (74 if big else 58)
	for y3 in range(gtop - 6, ground):
		for x3 in range(cx - gw - 6, cx + gw + 6):
			var dy: float = float(y3 - (gtop + gw))
			if dy < 0.0 and Vector2(x3 + 0.5 - cx, dy).length() > gw + 6:
				continue
			var ring: bool = dy < 0.0 and Vector2(x3 + 0.5 - cx, dy).length() > gw
			px(im, x3, y3, (st[6] if posmod(int(atan2(dy, x3 + 0.5 - cx) * 6.0), 2) == 0 else st[5]) if ring else st[4])
	for y4 in range(gtop, ground):
		for x4 in range(cx - gw, cx + gw):
			var dy2: float = float(y4 - (gtop + gw))
			if dy2 < 0.0 and Vector2(x4 + 0.5 - cx, dy2).length() > gw:
				continue
			var pl: int = posmod(x4 - (cx - gw), 8)
			var c: Color = pick(WOOD, 0.5 - (0.22 if pl == 0 else 0.0) + (h01(x4, y4 / 5, 3) - 0.5) * 0.1, x4, y4)
			if absi(x4 - cx) < 1:
				c = WOOD[0]
			if posmod(y4 - gtop, 14) == 7 and pl == 4:
				c = Color("2a2a30")
			# решётка в верхней части
			if y4 < gtop + gw + 10 and (posmod(x4 - cx, 6) == 0 or posmod(y4 - gtop, 6) == 0):
				c = Color("2e2e36")
			px(im, x4, y4, c)
	# знамёна по бокам ворот
	banner(im, cx - gw - 22, wtop + 14, 18, 50, hx(KROOF) if big else hx(KBLUE))
	banner(im, cx + gw + 22, wtop + 14, 18, 50, hx(KROOF) if big else hx(KBLUE))
	# ступени-мостик
	for k in range(2):
		rect(im, cx - gw - 8 - k * 6, ground + k * 6, (gw + 8 + k * 6) * 2, 6, st[5 - k])
	# мох и плющ у подножья
	draw_ivy(im, wx0 + 50, ground, 50, 0.9)
	draw_ivy(im, wx1 - 50, ground, 40, 0.9)
	outline_auto(im, 0.4)
	save3(im, name)


## Турнирный шатёр: полосатый цилиндр, конус-крыша с фестонами, вымпел
func gen_tent(name: String, ramp: Array) -> void:
	var im: Image = new_img(96, 104)
	var cx: int = 48
	var white: Array = hx(["9a9488", "bab4a6", "d8d2c4", "eee8dc", "fbf8f0"])
	ell(im, cx, 99, 44, 5, Color(0.1, 0.12, 0.08, 0.3))
	# стенки
	for y in range(56, 100):
		for x in range(cx - 38, cx + 38):
			var u: float = (x + 0.5 - (cx - 38)) / 76.0
			var stripe: int = int(floor(u * 8.0))
			var base: Array = ramp if stripe % 2 == 0 else white
			var v: int = 4 if u < 0.3 else (3 if u < 0.75 else 2)
			if y > 97:
				v -= 1
			px(im, x, y, base[clampi(v, 0, base.size() - 1)])
	# вход: откинутый полог
	for y2 in range(66, 100):
		var w: float = float(y2 - 66) * 0.42
		for x2 in range(int(cx - w), int(cx + w) + 1):
			px(im, x2, y2, Color("2a1e1a") if absf(x2 - cx) < w - 1.0 else white[4])
	# конус
	for y3 in range(16, 58):
		var t: float = float(y3 - 16) / 42.0
		var w3: float = 4.0 + t * 38.0
		for x3 in range(int(cx - w3), int(cx + w3) + 1):
			var u3: float = (x3 + 0.5 - (cx - w3)) / (2.0 * w3)
			var stripe3: int = int(floor(u3 * 8.0))
			var base3: Array = ramp if stripe3 % 2 == 0 else white
			var v3: int = 4 if u3 < 0.35 else (3 if u3 < 0.75 else 2)
			px(im, x3, y3, base3[clampi(v3, 0, base3.size() - 1)])
	# фестоны
	for x4 in range(cx - 42, cx + 42):
		var dd: int = int(abs(sin((x4 - cx) * 0.4)) * 4.0)
		for y4 in range(56, 59 + dd):
			px(im, x4, y4, ramp[3] if y4 < 58 + dd else ramp[1])
		px(im, x4, 56, Color("d8b040"))
	# шпиль и вымпел
	for y5 in range(2, 17):
		px(im, cx, y5, Color("5a4228"))
	disc(im, cx, 2, 1.5, Color("f0c850"))
	for y6 in range(4, 11):
		for x6 in range(cx + 1, cx + 16 - (y6 - 4) * 2):
			px(im, x6, y6, ramp[4])
	outline_auto(im, 0.4)
	save3(im, name)


func gen_tilt_fence() -> void:
	var im: Image = new_img(120, 34)
	for pxp in range(4, 120, 28):
		planks(im, pxp, 8, 5, 24, WOOD, true, 5, 0.42, pxp)
	for y in range(10, 18):
		for x in range(0, 120):
			var seg: int = (x / 12) % 2
			var c: Color = Color("c8303a") if seg == 0 else Color("f2ecdc")
			if y == 10:
				c = c.lightened(0.2)
			if y > 15:
				c = c.darkened(0.25)
			px(im, x, y, c)
	outline_auto(im, 0.4)
	save3(im, "tilt_fence")


func gen_dummy() -> void:
	var im: Image = new_img(40, 66)
	planks(im, 18, 20, 5, 44, WOOD, true, 5, 0.42, 3)
	planks(im, 4, 26, 32, 4, WOOD, false, 4, 0.45, 4)
	var straw: Array = hx(["7a5a1e", "9e7a2a", "c09c3c", "dabc5a", "eed688"])
	blob(im, 20, 40, 10, 14, straw, 3)
	blob(im, 20, 16, 7, 7, straw, 3)
	for k in range(14):
		px(im, 12 + int(h01(k, 1, 3) * 16.0), 30 + int(h01(k, 2, 3) * 22.0), straw[1])
	# верёвки и нарисованная мишень
	for x in range(11, 30):
		px(im, x, 34, Color("6a4a2a"))
		px(im, x, 46, Color("6a4a2a"))
	disc(im, 20, 40, 3.5, Color("c8303a"))
	disc(im, 20, 40, 1.5, Color("f2ecdc"))
	px(im, 18, 15, Color("3a2a1a"))
	px(im, 22, 15, Color("3a2a1a"))
	outline_auto(im, 0.4)
	save3(im, "dummy")


func gen_weapon_rack() -> void:
	var im: Image = new_img(60, 56)
	planks(im, 4, 50, 52, 5, WOOD, false, 5, 0.4, 2)
	planks(im, 6, 18, 4, 34, WOOD, true, 4, 0.45, 3)
	planks(im, 50, 18, 4, 34, WOOD, true, 4, 0.45, 4)
	planks(im, 4, 22, 52, 3, WOOD, false, 3, 0.5, 5)
	var stl: Array = hx(["4a4a54", "7c7c88", "b2b2ba", "e0e0e4"])
	for k in range(4):
		var x: int = 14 + k * 9
		if k % 2 == 0:
			# копьё
			for y in range(4, 52):
				px(im, x, y, WOOD[3])
			for y2 in range(0, 6):
				px(im, x, y2, stl[3 - y2 / 3])
				if y2 > 2:
					px(im, x - 1, y2, stl[1])
					px(im, x + 1, y2, stl[1])
		else:
			# меч
			for y3 in range(10, 40):
				px(im, x, y3, stl[3])
				px(im, x + 1, y3, stl[1])
			rect(im, x - 3, 40, 8, 2, Color("d8b040"))
			rect(im, x, 42, 2, 6, Color("5a3a22"))
			disc(im, x + 0.5, 49, 1.5, Color("d8b040"))
	# щит, прислонённый к стойке
	var sc: Vector2 = Vector2(30, 38)
	for y4 in range(26, 54):
		var t: float = float(y4 - 26) / 27.0
		var w: float = 10.0 * (1.0 - pow(t, 2.2)) + 0.5
		for x4 in range(int(sc.x - w), int(sc.x + w) + 1):
			var c: Color = Color("2a4478") if x4 < sc.x else Color("c8303a")
			if absf(x4 - sc.x) > w - 1.2 or y4 == 26:
				c = Color("d8b040")
			px(im, x4, y4, c)
	outline_auto(im, 0.4)
	save3(im, "weapon_rack")


func gen_hay_bale() -> void:
	var im: Image = new_img(38, 28)
	var straw: Array = hx(["7a5a1e", "9e7a2a", "c09c3c", "dabc5a", "eed688", "fbefc0"])
	for y in range(6, 26):
		for x in range(3, 35):
			var v: float = 0.6 - float(y - 6) * 0.015 + (h01(x, y, 7) - 0.5) * 0.2
			if y < 10:
				v += 0.15
			if posmod(x * 3 + y, 7) == 0:
				v -= 0.18
			px(im, x, y, pick(straw, v, x, y))
	for x2 in [12, 25]:
		for y2 in range(6, 26):
			px(im, int(x2), y2, Color("6a4a22"))
	outline_auto(im, 0.4)
	save3(im, "hay_bale")


func gen_banner_pole() -> void:
	var im: Image = new_img(30, 110)
	for y in range(6, 108):
		px(im, 8, y, Color("3a2a1a"))
		px(im, 9, y, Color("6a4e30"))
	disc(im, 8.5, 5, 2.0, Color("f0c850"))
	for x in range(8, 26):
		px(im, x, 12, Color("5a4228"))
	banner(im, 17, 13, 16, 52, hx(KROOF))
	outline_auto(im, 0.35)
	save3(im, "banner_pole")


func gen_archery_target() -> void:
	var im: Image = new_img(40, 52)
	planks(im, 8, 20, 4, 30, WOOD, true, 4, 0.45, 2)
	planks(im, 28, 20, 4, 30, WOOD, true, 4, 0.45, 3)
	var cols: Array = [Color("f2ecdc"), Color("c8303a"), Color("f2ecdc"), Color("2a4478"), Color("f0c850")]
	for k in range(5):
		ell(im, 20, 22, 15.0 - k * 3.0, 13.0 - k * 2.6, cols[k])
	# стрела в мишени
	for k2 in range(8):
		px(im, 23 + k2, 19 - k2 / 2, Color("6a4e30"))
	px(im, 31, 15, Color("f2ecdc"))
	px(im, 30, 15, Color("c8303a"))
	outline_auto(im, 0.4)
	save3(im, "archery_target")


# ---------------------------------------------------------------- девушки-рыцари

const KNIGHT_LOOKS: Array = [
	# имя, волосы, латы (WHITE7), плащ-сюрко (TEAL7), латы?
	["knight_aria", ["6a4a1a", "8e6a28", "b08c3c", "cca858", "e2c47a", "f0dca0", "faf0cc"], ["2e303c", "4a4c5a", "6a6c7c", "8e909e", "b2b4c0", "d2d4dc", "f0f0f4"], ["3e0c12", "5e141c", "7e1c26", "9e2832", "bc3a42", "d45a5e", "ea8a86"], true],
	["knight_sera", ["0e0c14", "181624", "24203a", "322c4e", "443c66", "5a5282", "766ea0"], ["2e303c", "4a4c5a", "6a6c7c", "8e909e", "b2b4c0", "d2d4dc", "f0f0f4"], ["0e1a36", "16264e", "203668", "2c4a84", "3e62a2", "5a80bc", "86a6d4"], true],
	["knight_vera", ["4a1a12", "6e2416", "92341c", "b44a24", "d06630", "e68842", "f6b064"], ["4a3a14", "6e561c", "927428", "b49438", "d0b04e", "e6ca70", "f6e4a0"], ["6a6a72", "8e8e98", "b2b2bc", "d0d0d8", "e6e6ec", "f4f4f8", "ffffff"], true],
	["squire_tilly", ["2e1a12", "46281a", "603a24", "7a4e32", "966844", "b28860", "ccaa84"], ["3a2a1a", "54402a", "6e563a", "8a6e4c", "a68a64", "c2a882", "dcc8a4"], ["2a3a1e", "3a5028", "4e6a34", "668642", "80a056", "9cba70", "bcd494"], false],
	["adv_rina", ["1a1a2a", "262640", "343458", "464672", "5c5c8e", "7676aa", "9696c6"], ["3a2a1a", "54402a", "6e563a", "8a6e4c", "a68a64", "c2a882", "dcc8a4"], ["5a1a1a", "7a2626", "9a3434", "b84a46", "d06a60", "e4908a", "f4b8b0"], false],
	["adv_elma", ["6a3a12", "8e5218", "b06c22", "cc8a32", "e2a84a", "f0c46c", "fadc98"], ["1e2a4a", "2a3a64", "38507e", "4c6a9a", "6886b4", "8aa4cc", "b2c6e2"], ["2a3a1e", "3a5028", "4e6a34", "668642", "80a056", "9cba70", "bcd494"], false],
]


## Наплечники и меч у бедра поверх тела (латы рыцарей)
func knight_extras(im: Image, dir: int, f: int) -> void:
	var b: int = -1 if (f == 1 or f == 3 or f == 6 or f == 7) else 0
	var stl: Array = WHITE7
	var cx: float = 40.0
	# латы: стальные сапоги, пластины-сегменты на юбке, блик на нагруднике
	var steel: Dictionary = {}
	for i in range(LEATH7.size()):
		steel[(LEATH7[i] as Color).to_rgba32()] = stl[clampi(i, 0, 6)]
	var wk: Dictionary = {}
	for c in stl:
		wk[(c as Color).to_rgba32()] = true
	for y in range(36 + b, 160):
		for x in range(0, 80):
			var c0: Color = im.get_pixel(x, y)
			if c0.a < 0.5:
				continue
			var key: int = c0.to_rgba32()
			if y > 128 and steel.has(key):
				im.set_pixel(x, y, steel[key])
			elif wk.has(key):
				if y > 64 + b and y < 100 + b and posmod(y - b - 66, 8) == 0:
					im.set_pixel(x, y, stl[2])
				elif y > 64 + b and y < 100 + b and posmod(y - b - 66, 8) == 1:
					im.set_pixel(x, y, stl[6])
				elif y > 42 + b and y < 60 + b and absf(x - (cx - 4.0)) < 1.0 and dir != 1 and dir != 5:
					im.set_pixel(x, y, stl[6])
	if dir == 0 or dir == 1 or dir == 4 or dir == 5:
		var sh: Array = [Vector2(cx - 11.5, 40 + b), Vector2(cx + 11.5, 40 + b)]
		if dir == 4 or dir == 5:
			sh = [Vector2(cx - 9.0, 40 + b), Vector2(cx + 11.0, 40 + b)]
		for s in sh:
			var sp: Vector2 = s
			blob(im, sp.x, sp.y, 5.2, 4.0, stl, 5)
			for x in range(int(sp.x) - 5, int(sp.x) + 5):
				px(im, x, int(sp.y) + 3, stl[2])
	else:
		blob(im, cx + 1.0, 41.0 + b, 5.0, 4.2, stl, 5)
		for x2 in range(int(cx) - 4, int(cx) + 6):
			px(im, x2, 44 + b, stl[2])
	# меч в ножнах у левого бедра
	if dir == 0 or dir == 4:
		var hx0: float = cx - 13.0 if dir == 0 else cx - 11.0
		for k in range(34):
			var p: Vector2 = Vector2(hx0 - k * 0.22, 64 + b + k)
			px(im, int(p.x), int(p.y), Color("5a3a22"))
			px(im, int(p.x) - 1, int(p.y), Color("3a2414"))
		rect(im, int(hx0) - 3, 62 + b, 7, 2, Color("d8b040"))
		rect(im, int(hx0), 56 + b, 2, 6, Color("4a2e1c"))
		disc(im, hx0 + 0.5, 55 + b, 1.4, Color("f0c850"))
	elif dir == 2:
		for k2 in range(36):
			var p2: Vector2 = Vector2(cx + 5.0 + k2 * 0.5, 64 + b + k2 * 0.86)
			px(im, int(p2.x), int(p2.y), Color("5a3a22"))
			px(im, int(p2.x), int(p2.y) + 1, Color("3a2414"))
		rect(im, int(cx) + 1, 62 + b, 2, 7, Color("d8b040"))
		rect(im, int(cx) - 4, 60 + b, 6, 2, Color("4a2e1c"))


func gen_knight_girls() -> void:
	var sh: Array = HAIRL7.duplicate()
	var sw7: Array = WHITE7.duplicate()
	var st: Array = TEAL7.duplicate()
	var fw: int = 80
	var fh: int = 160
	var mirror: Dictionary = {2: 3, 4: 6, 5: 7}
	BOUNCE_OVR = 0
	var line_up: Image = new_img(fw * KNIGHT_LOOKS.size(), fh)
	var li: int = 0
	for lk in KNIGHT_LOOKS:
		HAIRL7 = hx(lk[1])
		WHITE7 = hx(lk[2])
		TEAL7 = hx(lk[3])
		_head_pal()
		var armor: bool = bool(lk[4])
		NO_CAPE = not armor
		var vs: Image = new_img(fw * 8, fh * 8)
		for vd in [0, 1, 2, 4, 5]:
			for k in range(8):
				var c2: Image = new_img(fw, fh)
				draw_hero10(c2, vd, k)
				if armor:
					knight_extras(c2, vd, k)
				outline_auto(c2, OUTLINE_CHAR)
				vs.blit_rect(c2, Rect2i(0, 0, fw, fh), Vector2i(k * fw, vd * fh))
				if mirror.has(vd):
					var mc: Image = c2.duplicate()
					mc.flip_x()
					vs.blit_rect(mc, Rect2i(0, 0, fw, fh), Vector2i(k * fw, int(mirror[vd]) * fh))
		save3(vs, String(lk[0]))
		gen_faces10("faces_" + String(lk[0]))
		line_up.blit_rect(vs, Rect2i(4 * fw, 0, fw, fh), Vector2i(li * fw, 0))
		li += 1
	var side: Image = Image.load_from_file(ProjectSettings.globalize_path(OUT + "knight_aria.png"))
	var strip: Image = new_img(fw * 3, fh)
	strip.blit_rect(side, Rect2i(4 * fw, 2 * fh, fw, fh), Vector2i(0, 0))
	strip.blit_rect(side, Rect2i(4 * fw, 4 * fh, fw, fh), Vector2i(fw, 0))
	strip.blit_rect(side, Rect2i(4 * fw, 1 * fh, fw, fh), Vector2i(fw * 2, 0))
	line_up.resize(line_up.get_width() * 3, line_up.get_height() * 3, Image.INTERPOLATE_NEAREST)
	line_up.save_png(ProjectSettings.globalize_path("res://").path_join("../screenshots/knight_lineup.png"))
	strip.resize(strip.get_width() * 3, strip.get_height() * 3, Image.INTERPOLATE_NEAREST)
	strip.save_png(ProjectSettings.globalize_path("res://").path_join("../screenshots/knight_views.png"))
	NO_CAPE = false
	HAIRL7 = sh
	WHITE7 = sw7
	TEAL7 = st
	_head_pal()


# ================================================================== лес эльфов

const ELF_LEAF: Array = ["163a3e", "1e5650", "287462", "389270", "56b07c", "86cc92", "c4ecbc"]
const MARBLE: Array = ["7a8088", "9aa0a8", "b8bec4", "d2d6da", "e6e8ea", "f4f6f6", "ffffff"]
const ELF_GLOW: Array = ["1a6a7a", "3aa6b4", "7ad8dc", "c4f6f2", "ffffff"]


func gen_elves() -> void:
	gen_great_tree()
	gen_elf_house()
	gen_elf_spring()
	gen_elf_arch()
	gen_elf_lantern()
	gen_elf_flowers()
	gen_elf_girls()
	var items: Array = []
	for nm in ["elf_great_tree", "elf_house", "elf_spring", "elf_arch", "elf_lantern", "elf_flowers"]:
		items.append([nm, Image.load_from_file(ProjectSettings.globalize_path(OUT + String(nm) + ".png"))])
	_sheet(items, 2, "elf_preview.png")


## Светящийся шарик-фонарик на нити
func glow_orb(im: Image, x: int, y: int, r: float, thread_len: int) -> void:
	var g: Array = hx(ELF_GLOW)
	for k in range(thread_len):
		px(im, x, y - r - k, Color(0.85, 0.95, 0.9, 0.7))
	disc(im, x, y, r + 1.0, Color(g[1].r, g[1].g, g[1].b, 0.45))
	disc(im, x, y, r, g[2])
	disc(im, x - 0.5, y - 0.5, r * 0.55, g[3])
	px(im, x - 1, y - 1, g[4])


## Деревянный настил-кольцо вокруг ствола: верх досками, передний край, перильца
func deck(im: Image, cx: float, y: float, rx: float, ry: float) -> void:
	for yy in range(int(y - ry), int(y + ry + 5)):
		for x in range(int(cx - rx), int(cx + rx) + 1):
			var dx: float = (x + 0.5 - cx) / rx
			var dy: float = (yy + 0.5 - y) / ry
			if dx * dx + dy * dy <= 1.0:
				var pl: int = posmod(x + int(dy * 4.0), 7)
				var v: float = 0.6 - dy * 0.12 - (0.2 if pl == 0 else 0.0)
				px(im, x, yy, pick(WOOD, v, x, yy))
			else:
				var top: float = y + ry * sqrt(maxf(0.0, 1.0 - dx * dx))
				if yy > top and yy < top + 5.0 and absf(dx) <= 1.0:
					px(im, x, yy, WOOD[1] if yy > top + 3.0 else WOOD[2])
	# перильца по переднему краю
	var k: int = 0
	var a: float = 0.15
	while a < PI - 0.1:
		var p: Vector2 = Vector2(cx + cos(a) * rx * 0.98, y + sin(a) * ry)
		for j in range(9):
			px(im, int(p.x), int(p.y) - j, WOOD[4] if j > 6 else WOOD[3])
		a += 0.32
		k += 1
	var prev: Vector2 = Vector2(cx + rx, y - 8)
	for i in range(1, 25):
		var a2: float = float(i) / 24.0 * PI
		var q: Vector2 = Vector2(cx + cos(a2) * rx * 0.98, y + sin(a2) * ry - 8.0)
		line(im, int(prev.x), int(prev.y), int(q.x), int(q.y), WOOD[5])
		prev = q


func gen_great_tree() -> void:
	rng.seed = 909
	var W: int = 350
	var H: int = 470
	var im: Image = new_img(W, H)
	var cx: float = 175.0
	var base: int = H - 10
	var leaf: Array = hx(ELF_LEAF)
	var t0: int = 220
	draw_trunk3(im, cx, t0, base, 28.0, 909)
	var cl: Array = tree_clumps(cx, 180.0, 138.0)
	var under: Callable = func() -> void:
		branch(im, Vector2(cx - 6, t0 + 10), Vector2(cx - 90, 190), 14.0, 4.0)
		branch(im, Vector2(cx + 6, t0 + 6), Vector2(cx + 96, 178), 14.0, 4.0)
		branch(im, Vector2(cx, t0 + 4), Vector2(cx + 4, 110), 16.0, 5.0)
	leaf_canopy(im, cl, leaf, 909, 7.5, 5.4, 3.6, 0.55, under, [])
	# серебристые искорки в листве
	for i in range(70):
		var sx: int = int(cx + rng.randf_range(-150, 150))
		var sy: int = int(180 + rng.randf_range(-120, 90))
		if a_at(im, sx, sy) > 0.5:
			px(im, sx, sy, Color("e8fff4"))
	# настилы вокруг ствола и лестница
	deck(im, cx, 300.0, 78.0, 13.0)
	deck(im, cx, 380.0, 66.0, 11.0)
	for k in range(9):
		var sy2: float = 442.0 - k * 7.0
		var sx2: float = cx + 34.0 + sin(k * 0.9) * 8.0
		rect(im, int(sx2) - 6, int(sy2), 12, 3, WOOD[4])
		rect(im, int(sx2) - 6, int(sy2) + 3, 12, 1, WOOD[1])
	# дверь в стволе: круглая, внутри тёплый свет
	var dc: Vector2 = Vector2(cx - 4.0, base - 22.0)
	for y in range(int(dc.y) - 20, base - 4):
		for x in range(int(dc.x) - 14, int(dc.x) + 15):
			var d: float = Vector2((x + 0.5 - dc.x) / 13.0, (y + 0.5 - dc.y) / 18.0).length()
			if d > 1.0 and y < int(dc.y):
				continue
			if absf(x + 0.5 - dc.x) > 13.0:
				continue
			var rim: bool = d > 0.86 or absf(x + 0.5 - dc.x) > 11.5
			px(im, x, y, WOOD[5] if rim else Color("3a2418").lerp(Color("ffd890"), clampf(1.1 - d, 0.0, 1.0)))
	# круглые окошки
	for wv in [Vector2(cx + 14, 340), Vector2(cx - 18, 260), Vector2(cx + 10, 422)]:
		disc(im, wv.x, wv.y, 6.0, WOOD[5])
		disc(im, wv.x, wv.y, 4.5, Color("ffd890"))
		px(im, int(wv.x) - 1, int(wv.y) - 1, Color("fff8e0"))
	# фонарики под кроной
	for k2 in range(9):
		var lx: int = int(cx - 130 + k2 * 32 + rng.randf_range(-6, 6))
		var ly: int = 265 + int(rng.randf_range(-10, 20))
		if absf(lx - cx) < 34:
			continue
		glow_orb(im, lx, ly, 2.5, 8 + rng.randi_range(0, 10))
	# лианы с цветами по стволу
	for k3 in range(5):
		var vx: float = cx - 24.0 + k3 * 12.0
		for y2 in range(t0 + 20, base - 30):
			var xx: int = int(vx + sin(y2 * 0.12 + k3) * 3.0)
			if posmod(y2, 3) == 0:
				px(im, xx, y2, leaf[4])
			if posmod(y2 + k3 * 7, 23) == 0:
				px(im, xx + 1, y2, Color("f4f0ff"))
				px(im, xx, y2 - 1, Color("c8e0ff"))
	clean_specks(im)
	outline_auto(im, 0.45)
	shadow(im, cx + 4.0, base + 2.0, 110.0, 8.0, 0.18)
	save3(im, "elf_great_tree")


func gen_elf_house() -> void:
	rng.seed = 919
	var W: int = 160
	var H: int = 236
	var im: Image = new_img(W, H)
	var cx: float = 80.0
	var base: int = H - 8
	var t0: int = 122
	draw_trunk3(im, cx, t0, base, 22.0, 919)
	leaf_canopy(im, tree_clumps(cx, 96.0, 62.0), hx(ELF_LEAF), 919, 6.6, 4.8, 3.4, 0.55, Callable(), [])
	# дверь-арка
	for y in range(base - 46, base - 4):
		for x in range(int(cx) - 12, int(cx) + 13):
			var dy: float = float(y - (base - 34))
			if dy < 0.0 and Vector2(x + 0.5 - cx, dy).length() > 12.0:
				continue
			var rim: bool = (dy < 0.0 and Vector2(x + 0.5 - cx, dy).length() > 10.0) or absf(x + 0.5 - cx) > 10.0
			var pl: int = posmod(x - int(cx), 5)
			px(im, x, y, WOOD[5] if rim else pick(hx(["2e4a3a", "3e6248", "527c58", "6a9a6c", "8ab884"]), 0.5 - (0.2 if pl == 0 else 0.0), x, y))
	disc(im, cx + 6, base - 22, 1.3, Color("f0d070"))
	# окошко и балкончик
	disc(im, cx - 10, 156, 7.0, WOOD[5])
	disc(im, cx - 10, 156, 5.5, Color("ffd890"))
	rect(im, int(cx) - 11, 150, 2, 12, WOOD[3])
	deck(im, cx + 6, 138.0, 30.0, 6.0)
	glow_orb(im, int(cx) + 28, 126, 2.5, 6)
	glow_orb(im, int(cx) - 30, 130, 2.5, 9)
	# ступеньки-корни к двери
	rect(im, int(cx) - 14, base - 4, 28, 4, MARBLE[3])
	rect(im, int(cx) - 14, base - 1, 28, 1, MARBLE[1])
	clean_specks(im)
	outline_auto(im, 0.45)
	shadow(im, cx + 2.0, base + 2.0, 60.0, 6.0, 0.16)
	save3(im, "elf_house")


func gen_elf_spring() -> void:
	var im: Image = new_img(140, 84)
	var c: Vector2 = Vector2(70, 46)
	var g: Array = hx(ELF_GLOW)
	for y in range(8, 84):
		for x in range(0, 140):
			var q: Vector2 = Vector2((x + 0.5 - c.x) / 60.0, (y + 0.5 - c.y) / 30.0)
			var d: float = q.length()
			if d > 1.0:
				continue
			var v: float = 0.4 + (1.0 - d) * 0.5 + sin(x * 0.4 + y * 0.9) * 0.05
			if (x * 3 + y * 7) % 23 == 0:
				v += 0.25
			px(im, x, y, pick(g, v, x, y))
	# белые камни по кругу
	var a: float = 0.0
	while a < TAU:
		var sp: Vector2 = c + Vector2(cos(a) * 62.0, sin(a) * 32.0)
		var r: float = 4.0 + h01(int(a * 10.0), 3, 5) * 3.0
		ball(im, sp.x, sp.y, r, r * 0.7, hx(MARBLE), 0.1)
		a += 0.32
	# кувшинки и кристалл в середине
	for lp in [Vector2(44, 40), Vector2(96, 52), Vector2(60, 60)]:
		ell(im, lp.x, lp.y, 6, 3.5, Color("3a8a5a"))
		ell(im, lp.x - 1, lp.y - 1, 4, 2.2, Color("5aae6a"))
		px(im, int(lp.x), int(lp.y) - 2, Color("fff0fa"))
	for y2 in range(18, 46):
		var w: float = (1.0 - float(46 - y2) / 28.0) * 6.0 + 0.5
		if y2 > 40:
			w = 6.0 - float(y2 - 40) * 0.8
		for x2 in range(int(c.x - w), int(c.x + w) + 1):
			px(im, x2, y2, g[4] if x2 < c.x - 1 else (g[3] if x2 < c.x + 2 else g[2]))
	outline_auto(im, 0.35)
	save3(im, "elf_spring")


func gen_elf_arch() -> void:
	var im: Image = new_img(110, 126)
	var mb: Array = hx(MARBLE)
	var g: Array = hx(ELF_GLOW)
	for pxx in [14, 84]:
		for y in range(40, 120):
			for x in range(int(pxx), int(pxx) + 12):
				var u: float = float(x - int(pxx)) / 11.0
				px(im, x, y, mb[5] if u < 0.3 else (mb[4] if u < 0.7 else mb[2]))
		rect(im, int(pxx) - 2, 116, 16, 6, mb[3])
		# руны
		for k in range(4):
			var ry: int = 56 + k * 14
			px(im, int(pxx) + 5, ry, g[3])
			px(im, int(pxx) + 6, ry + 1, g[2])
			px(im, int(pxx) + 5, ry + 2, g[3])
			px(im, int(pxx) + 4, ry + 1, g[2])
	# изогнутая стрельчатая арка-листок
	for i in range(80):
		var t: float = float(i) / 79.0
		var x2: float = lerpf(20.0, 90.0, t)
		var y2: float = 44.0 - sin(t * PI) * 34.0 - (6.0 * (1.0 - absf(t - 0.5) * 2.0) if absf(t - 0.5) < 0.12 else 0.0)
		for k2 in range(-4, 5):
			px(im, int(x2), int(y2) + k2, mb[5] if k2 < -1 else (mb[4] if k2 < 2 else mb[2]))
	# лоза с листьями и цветами
	for i2 in range(60):
		var t2: float = float(i2) / 59.0
		var x3: float = lerpf(20.0, 90.0, t2)
		var y3: float = 44.0 - sin(t2 * PI) * 34.0 + sin(t2 * 30.0) * 3.0
		px(im, int(x3), int(y3), Color("3a8a5a"))
		if i2 % 5 == 0:
			px(im, int(x3), int(y3) - 1, Color("6ac07a"))
			px(im, int(x3) + 1, int(y3) - 1, Color("8ad890"))
		if i2 % 11 == 0:
			px(im, int(x3), int(y3) + 1, Color("f4f0ff"))
	outline_auto(im, 0.35)
	save3(im, "elf_arch")


func gen_elf_lantern() -> void:
	var im: Image = new_img(30, 80)
	var mb: Array = hx(MARBLE)
	# тонкий изогнутый стебель
	for y in range(14, 78):
		var x: int = 12 + int(sin(float(y) * 0.06) * 2.0)
		px(im, x, y, mb[4])
		px(im, x + 1, y, mb[2])
	for k in range(10):
		px(im, 13 + k, 14 - k / 2, mb[4])
	# фонарик-лист
	glow_orb(im, 22, 22, 3.5, 4)
	for k2 in range(6):
		px(im, 19 + k2, 16 - (k2 % 3), Color("4aa070"))
	rect(im, 8, 76, 10, 3, mb[2])
	outline_auto(im, 0.3)
	save3(im, "elf_lantern")


func gen_elf_flowers() -> void:
	var im: Image = new_img(36, 26)
	var g: Array = hx(ELF_GLOW)
	for k in range(7):
		var x: int = 4 + k * 5
		var top: int = 6 + int(h01(k, 1, 3) * 8.0)
		for y in range(top, 24):
			px(im, x, y, Color("3a8a5a"))
		# колокольчик
		for j in range(3):
			var by: int = top + 1 + j * 4
			px(im, x + 1, by, g[2])
			px(im, x + 2, by, g[3])
			px(im, x + 1, by + 1, g[1])
			px(im, x + 2, by + 1, g[2])
		px(im, x - 1, 22, Color("5aae6a"))
		px(im, x + 1, 21, Color("5aae6a"))
	outline_auto(im, 0.3)
	save3(im, "elf_flowers")


# ---------------------------------------------------------------- эльфийки

const ELF_LOOKS: Array = [
	# имя, волосы, одежда, плащ, плащ?, что в руках
	["elf_lirael", ["6a4a1a", "8e6a28", "b08c3c", "cca858", "e2c47a", "f0dca0", "faf0cc"], ["1e3a24", "2a5030", "3a6a3c", "4e864a", "68a25e", "8abc7a", "b2d6a0"], ["2a2014", "3e301e", "54422a", "6a5638", "84704c", "a08c66", "bcac88"], true, "bow"],
	["elf_sylwen", ["6a6a78", "8e8e9c", "b0b0bc", "ccccd6", "e0e0e8", "f0f0f6", "ffffff"], ["24442a", "325a36", "467444", "5e8e54", "7aa86a", "9cc286", "c2dcaa"], ["1a4a40", "226052", "2c7862", "389270", "56b07c", "86cc92", "c4ecbc"], true, "bow"],
	["elf_thalia", ["4a2a12", "6a3c1a", "8a5226", "aa6a34", "c88648", "e0a462", "f2c48a"], ["1e3a1c", "2a5026", "386a32", "4c8440", "649e54", "84b86e", "aad294"], ["2a2014", "3e301e", "54422a", "6a5638", "84704c", "a08c66", "bcac88"], true, "bow"],
]
const ELF_EARS: Dictionary = {
	# ракурс: [[основание, сторона, длина], ...]
	0: [[Vector2(28, 25), -1, 9], [Vector2(52, 25), 1, 9]],
	1: [[Vector2(27, 25), -1, 9], [Vector2(53, 25), 1, 9]],
	2: [[Vector2(45, 25), 1, 10]],
	4: [[Vector2(26, 26), -1, 6], [Vector2(49, 24), 1, 10]],
	5: [[Vector2(28, 25), -1, 9], [Vector2(54, 24), 1, 8]],
}


func draw_elfgirl(im: Image, dir: int, f: int, item: String) -> void:
	var b: int = -1 if (f == 1 or f == 3 or f == 6 or f == 7) else 0
	var back_view: bool = dir == 1 or dir == 5
	# лук за спиной: в передних ракурсах — позади тела
	if item == "bow" and not back_view:
		_elf_bow(im, dir, b)
	if item == "spear" and dir == 2:
		_elf_spear(im, 33.0, b)
	draw_hero10(im, dir, f)
	if item == "bow" and back_view:
		_elf_bow(im, dir, b)
	for e in ELF_EARS[dir]:
		var ea: Array = e
		elf_ear(im, (ea[0] as Vector2) + Vector2(0, b), int(ea[1]), 5, int(ea[2]))
	if item == "crown":
		# венок из белых и голубых цветочков
		var pts: Array = [Vector2(29, 11), Vector2(33, 8), Vector2(38, 6), Vector2(43, 6), Vector2(48, 8), Vector2(52, 11)]
		if dir == 2:
			pts = [Vector2(31, 9), Vector2(36, 6), Vector2(41, 6), Vector2(46, 8)]
		for i in range(pts.size()):
			var p: Vector2 = (pts[i] as Vector2) + Vector2(0, b)
			px(im, int(p.x), int(p.y) + 1, Color("4a9a5a"))
			px(im, int(p.x) + 1, int(p.y) + 1, Color("6ab86a"))
			var fc: Color = Color("ffffff") if i % 2 == 0 else Color("a8d8ff")
			px(im, int(p.x), int(p.y), fc)
			px(im, int(p.x) - 1, int(p.y), fc.darkened(0.15))
			px(im, int(p.x) + 1, int(p.y), fc.darkened(0.15))
			px(im, int(p.x), int(p.y) - 1, fc)
			px(im, int(p.x), int(p.y), Color("f6d24a"))
	if item == "spear" and dir != 2:
		_elf_spear(im, 58.0 if dir != 4 else 57.0, b)


func _elf_bow(im: Image, dir: int, b: int) -> void:
	var wd: Array = hx(["3a2414", "5a3a22", "7e5634", "a07848"])
	var c: Vector2 = Vector2(40, 64 + b)
	var prev: Vector2 = Vector2.ZERO
	for i in range(31):
		var t: float = float(i) / 30.0
		var y: float = c.y - 34.0 + t * 68.0
		var x: float = c.x + 20.0 - sin(t * PI) * 10.0
		if dir == 2:
			x = c.x + 12.0 + sin(t * PI) * 8.0
		var p: Vector2 = Vector2(x, y)
		px(im, int(x), int(y), wd[2])
		px(im, int(x) + 1, int(y), wd[1])
		if i == 0 or i == 30:
			px(im, int(x), int(y), Color("e8d090"))
		if i > 0 and i % 6 == 0:
			px(im, int(x) - 1, int(y), wd[3])
		prev = p
	# тетива
	var top: Vector2 = Vector2(c.x + 20.0 if dir != 2 else c.x + 12.0, c.y - 34.0)
	var bot: Vector2 = Vector2(top.x, c.y + 34.0)
	line(im, int(top.x), int(top.y), int(bot.x), int(bot.y), Color("e8e4d8"))


func _elf_spear(im: Image, x: float, b: int) -> void:
	for y in range(14 + b, 154):
		px(im, int(x), y, Color("6e5032"))
		px(im, int(x) + 1, y, Color("4a3420"))
	# наконечник-лист
	for k in range(12):
		var w: float = sin(float(k) / 11.0 * PI) * 3.0
		for xx in range(int(x - w), int(x + w) + 2):
			px(im, xx, 2 + b + k, Color("e0e8ec") if xx <= int(x) else Color("a8b8c0"))
	rect(im, int(x) - 2, 14 + b, 6, 2, Color("d8b040"))


func gen_elf_girls() -> void:
	var sh: Array = HAIRL7.duplicate()
	var sw7: Array = WHITE7.duplicate()
	var st: Array = TEAL7.duplicate()
	var fw: int = 80
	var fh: int = 160
	var mirror: Dictionary = {2: 3, 4: 6, 5: 7}
	BOUNCE_OVR = 0
	var line_up: Image = new_img(fw * ELF_LOOKS.size(), fh)
	var views: Image = new_img(fw * 4, fh)
	var li: int = 0
	for lk in ELF_LOOKS:
		HAIRL7 = hx(lk[1])
		WHITE7 = hx(lk[2])
		TEAL7 = hx(lk[3])
		EYE_OVR = {"I": Color("1a5a4a"), "i": Color("3aa88a"), "j": Color("9ae8c8")}
		_head_pal()
		NO_CAPE = not bool(lk[4])
		var vs: Image = new_img(fw * 8, fh * 8)
		for vd in [0, 1, 2, 4, 5]:
			for k in range(8):
				var c2: Image = new_img(fw, fh)
				draw_elfgirl(c2, vd, k, String(lk[5]))
				outline_auto(c2, OUTLINE_CHAR)
				vs.blit_rect(c2, Rect2i(0, 0, fw, fh), Vector2i(k * fw, vd * fh))
				if mirror.has(vd):
					var mc: Image = c2.duplicate()
					mc.flip_x()
					vs.blit_rect(mc, Rect2i(0, 0, fw, fh), Vector2i(k * fw, int(mirror[vd]) * fh))
		save3(vs, String(lk[0]))
		gen_faces10("faces_" + String(lk[0]))
		line_up.blit_rect(vs, Rect2i(4 * fw, 0, fw, fh), Vector2i(li * fw, 0))
		if li == 0:
			for d2 in [2, 4, 1, 5]:
				views.blit_rect(vs, Rect2i(4 * fw, int(d2) * fh, fw, fh), Vector2i([2, 4, 1, 5].find(d2) * fw, 0))
		li += 1
	line_up.resize(line_up.get_width() * 3, line_up.get_height() * 3, Image.INTERPOLATE_NEAREST)
	line_up.save_png(ProjectSettings.globalize_path("res://").path_join("../screenshots/elf_lineup.png"))
	views.resize(views.get_width() * 3, views.get_height() * 3, Image.INTERPOLATE_NEAREST)
	views.save_png(ProjectSettings.globalize_path("res://").path_join("../screenshots/elf_views.png"))
	EYE_OVR = {}
	NO_CAPE = false
	HAIRL7 = sh
	WHITE7 = sw7
	TEAL7 = st
	_head_pal()


# ================================================================== долина магов

const MSTONE: Array = ["6a6a80", "86869c", "a2a2b6", "bcbccc", "d2d2de", "e6e6ee", "f6f6fa"]
const MROOF: Array = ["14183a", "1e2652", "2a386e", "3a4e8e", "5068aa", "6e88c4", "98b0dc"]
const ARCANE: Array = ["2a2a8a", "4a4ac8", "7a7aec", "aab0ff", "dce0ff", "ffffff"]
const CRYST: Array = ["2a1a5a", "4a2a9a", "6e4ad0", "9a7aec", "c8b0ff", "f0e8ff"]


func gen_mages() -> void:
	gen_mage_tower()
	gen_observatory()
	gen_magic_circle()
	gen_rune_stone()
	gen_crystal_cluster()
	gen_moon_flowers()
	gen_mimic()
	gen_mage_girls()
	var items: Array = []
	for nm in ["mage_tower", "observatory", "magic_circle", "rune_stone", "crystal_cluster", "moon_flowers", "mimic"]:
		items.append([nm, Image.load_from_file(ProjectSettings.globalize_path(OUT + String(nm) + ".png"))])
	_sheet(items, 2, "mage_preview.png")


## Звёздочка-искра (4 луча)
func star(im: Image, x: int, y: int, r: int, c: Color) -> void:
	px(im, x, y, Color("ffffff"))
	for k in range(1, r + 1):
		var cc: Color = c if k < r else Color(c.r, c.g, c.b, 0.6)
		px(im, x + k, y, cc)
		px(im, x - k, y, cc)
		px(im, x, y + k, cc)
		px(im, x, y - k, cc)


func gen_mage_tower() -> void:
	var W: int = 200
	var H: int = 460
	var im: Image = new_img(W, H)
	var st: Array = hx(MSTONE)
	var cx: int = 100
	var ground: int = H - 12
	rng.seed = 606
	# стройная башня, сужается кверху
	var top: int = 150
	for y in range(top, ground):
		var t: float = float(y - top) / float(ground - top)
		var hw: float = 34.0 + t * 14.0
		for x in range(int(cx - hw), int(cx + hw)):
			var u: float = (x + 0.5 - (cx - hw)) / (2.0 * hw)
			var row: int = int((y - top) / 9)
			var bx: float = fposmod(x + (6.0 if row % 2 == 1 else 0.0), 14.0)
			var v: float = 0.78 - u * 0.5 + (h01(int((x + (6 if row % 2 == 1 else 0)) / 14), row, 3) - 0.5) * 0.08
			if posmod(y - top, 9) == 8 or bx < 1.0:
				v -= 0.16
			px(im, x, y, pick(st, v, x, y))
	# золотые пояса и руны
	for by in [top + 60, top + 150, top + 240]:
		var t2: float = float(by - top) / float(ground - top)
		var hw2: float = 34.0 + t2 * 14.0
		for x2 in range(int(cx - hw2) - 2, int(cx + hw2) + 2):
			px(im, x2, by, Color("e8c860"))
			px(im, x2, by + 1, Color("b8963a"))
			px(im, x2, by + 2, Color("8a6a2a"))
		for k in range(6):
			var rx: int = int(cx - hw2 + 8 + k * (hw2 * 2 - 16) / 5.0)
			px(im, rx, by - 5, hx(ARCANE)[3])
			px(im, rx, by - 6, hx(ARCANE)[4])
			px(im, rx + 1, by - 5, hx(ARCANE)[2])
	# высокие окна с голубым светом
	for wy in [top + 18, top + 96, top + 186]:
		for y3 in range(wy, wy + 30):
			for x3 in range(cx - 6, cx + 6):
				var dy: float = float(y3 - (wy + 6))
				if dy < 0.0 and Vector2(x3 + 0.5 - cx, dy).length() > 6.0:
					continue
				px(im, x3, y3, Color("2a3a7a").lerp(Color("a8c8ff"), 0.3 + float(y3 - wy) / 30.0 * 0.5))
		px(im, cx, wy + 10, Color("ffffff"))
	# балкон у вершины
	for x4 in range(cx - 46, cx + 47):
		for y4 in range(top - 4, top + 6):
			px(im, x4, y4, st[5] if y4 < top else st[3])
	for x5 in range(cx - 44, cx + 45, 6):
		for y5 in range(top - 14, top - 4):
			px(im, x5, y5, st[4])
	for x6 in range(cx - 46, cx + 47):
		px(im, x6, top - 15, st[5])
	# высокая синяя конусная крыша со звёздами
	var rf: Array = hx(MROOF)
	var tip: int = 20
	for y7 in range(tip, top - 14):
		var t7: float = float(y7 - tip) / float(top - 14 - tip)
		var w7: float = 42.0 * pow(t7, 0.95) + 0.6
		for x7 in range(int(cx - w7), int(cx + w7) + 1):
			var u7: float = (x7 + 0.5 - (cx - w7)) / (2.0 * w7)
			var v7: float = 0.72 - u7 * 0.5
			if posmod(y7 - tip, 7) == 6:
				v7 -= 0.12
			px(im, x7, y7, pick(rf, v7, x7, y7))
	for k2 in range(14):
		var sx: int = cx + int(rng.randf_range(-30, 30))
		var sy: int = int(rng.randf_range(tip + 30, top - 20))
		if a_at(im, sx, sy) > 0.5:
			star(im, sx, sy, 1, Color("f0d870"))
	# навершие — полумесяц и звезда
	for a in range(16):
		var an: float = PI * 0.15 + float(a) / 15.0 * PI * 1.3
		px(im, cx + int(cos(an) * 6.0), tip - 10 + int(sin(an) * 6.0), Color("f0d060"))
	star(im, cx + 2, tip - 12, 2, Color("fff4b0"))
	for y8 in range(tip - 4, tip + 1):
		px(im, cx, y8, Color("c8a040"))
	# парящие кристаллы вокруг башни
	var cr: Array = hx(CRYST)
	for cp in [Vector2(28, 220), Vector2(170, 260), Vector2(36, 360), Vector2(166, 140)]:
		for y9 in range(-8, 9):
			var w9: float = (8.0 - absf(y9)) * 0.5
			for x9 in range(int(-w9), int(w9) + 1):
				px(im, int(cp.x) + x9, int(cp.y) + y9, cr[4] if x9 < 0 else (cr[3] if y9 < 0 else cr[2]))
		px(im, int(cp.x) - 1, int(cp.y) - 3, cr[5])
	# дверь
	for y10 in range(ground - 44, ground):
		for x10 in range(cx - 13, cx + 14):
			var dy10: float = float(y10 - (ground - 31))
			if dy10 < 0.0 and Vector2(x10 + 0.5 - cx, dy10).length() > 13.0:
				continue
			var rim: bool = (dy10 < 0.0 and Vector2(x10 + 0.5 - cx, dy10).length() > 11.0) or absi(x10 - cx) > 11
			px(im, x10, y10, Color("e8c860") if rim else pick(hx(MROOF), 0.4 + (0.15 if posmod(x10 - cx, 5) == 0 else 0.0), x10, y10))
	star(im, cx, ground - 26, 2, Color("e8c860"))
	rect(im, cx - 20, ground, 40, 4, st[4])
	rect(im, cx - 26, ground + 4, 52, 4, st[3])
	outline_auto(im, 0.4)
	save3(im, "mage_tower")


func gen_observatory() -> void:
	var W: int = 260
	var H: int = 250
	var im: Image = new_img(W, H)
	var st: Array = hx(MSTONE)
	var cx: int = 130
	var ground: int = H - 10
	# круглое здание
	stone_wall(im, Rect2i(40, 120, 180, ground - 120), st, 8, 12, 20, Color(st[1]), 0.62)
	for y in range(120, ground):
		for x in range(40, 220):
			var u: float = (float(x - cx) + 0.5) / 90.0
			if absf(u) > 0.6:
				bl(im, x, y, Color(0.1, 0.1, 0.25, (absf(u) - 0.6) * 0.5))
	# купол
	var rf: Array = hx(MROOF)
	for y2 in range(30, 124):
		for x2 in range(36, 225):
			var q: Vector2 = Vector2((x2 + 0.5 - cx) / 94.0, (y2 + 0.5 - 124.0) / 94.0)
			var d: float = q.length()
			if d > 1.0 or y2 > 122:
				continue
			var nz: float = sqrt(maxf(0.0, 1.0 - d * d))
			var l: float = Vector3(q.x, q.y, nz).normalized().dot(Vector3(-0.5, -0.6, 0.6).normalized())
			var v: float = 0.4 + l * 0.45
			if fposmod(atan2(q.y, q.x) * 10.0 / PI, 1.0) < 0.06:
				v -= 0.14
			px(im, x2, y2, pick(rf, v, x2, y2))
	# щель купола и телескоп
	for y3 in range(32, 122):
		for x3 in range(cx + 8, cx + 24):
			if a_at(im, x3, y3) > 0.5:
				px(im, x3, y3, Color("14183a"))
	thick_line(im, Vector2(cx + 14, 90), Vector2(cx + 54, 20), 6.0, hx(["6a4a1a", "9a7428", "c8a040", "e8c860"]), 0.6)
	disc(im, cx + 54, 20, 4.5, Color("e8c860"))
	disc(im, cx + 54, 20, 2.5, Color("a8d8ff"))
	# пояс с рунами, окна, дверь
	for x4 in range(38, 222):
		px(im, x4, 122, Color("e8c860"))
		px(im, x4, 123, Color("b8963a"))
	for wx in [72, 188]:
		for y5 in range(150, 184):
			for x5 in range(wx - 8, wx + 8):
				var dy: float = float(y5 - 158)
				if dy < 0.0 and Vector2(x5 + 0.5 - wx, dy).length() > 8.0:
					continue
				px(im, x5, y5, Color("2a3a7a").lerp(Color("a8c8ff"), 0.3 + float(y5 - 150) / 34.0 * 0.5))
	for y6 in range(ground - 50, ground):
		for x6 in range(cx - 16, cx + 17):
			var dy6: float = float(y6 - (ground - 34))
			if dy6 < 0.0 and Vector2(x6 + 0.5 - cx, dy6).length() > 16.0:
				continue
			var rim: bool = (dy6 < 0.0 and Vector2(x6 + 0.5 - cx, dy6).length() > 14.0) or absi(x6 - cx) > 14
			px(im, x6, y6, Color("e8c860") if rim else pick(rf, 0.45 + (0.12 if posmod(x6 - cx, 6) == 0 else 0.0), x6, y6))
	# звёздная карта над дверью
	disc(im, cx, ground - 64, 9.0, Color("1e2652"))
	for k in range(6):
		star(im, cx - 6 + int(h01(k, 1, 7) * 12.0), ground - 70 + int(h01(k, 2, 7) * 12.0), 0, Color("fff4b0"))
	rect(im, cx - 26, ground, 52, 4, st[4])
	outline_auto(im, 0.4)
	save3(im, "observatory")


## Магический круг на земле (плоский): кольца, руны, звезда
func gen_magic_circle() -> void:
	var W: int = 180
	var H: int = 100
	var im: Image = new_img(W, H)
	var c: Vector2 = Vector2(90, 50)
	var ar: Array = hx(ARCANE)
	for y in range(H):
		for x in range(W):
			var q: Vector2 = Vector2((x + 0.5 - c.x) / 86.0, (y + 0.5 - c.y) / 46.0)
			var d: float = q.length()
			var a: float = atan2(q.y, q.x)
			var col: Color = Color(0, 0, 0, 0)
			if absf(d - 0.97) < 0.025 or absf(d - 0.78) < 0.02 or absf(d - 0.3) < 0.03:
				col = ar[3]
			elif d > 0.8 and d < 0.95 and fposmod(a * 24.0 / TAU, 1.0) < 0.35 and fposmod(a * 72.0 / TAU, 1.0) < 0.6:
				col = ar[2]
			if col.a > 0.0:
				px(im, x, y, Color(col.r, col.g, col.b, 0.85))
	# шестиконечная звезда
	for k in range(6):
		var a1: float = TAU * k / 6.0 - PI / 2.0
		var a2: float = TAU * (k + 2) / 6.0 - PI / 2.0
		var p1: Vector2 = c + Vector2(cos(a1) * 67.0, sin(a1) * 36.0)
		var p2: Vector2 = c + Vector2(cos(a2) * 67.0, sin(a2) * 36.0)
		line(im, int(p1.x), int(p1.y), int(p2.x), int(p2.y), Color(ar[4].r, ar[4].g, ar[4].b, 0.9))
	save3(im, "magic_circle")


func gen_rune_stone() -> void:
	var im: Image = new_img(34, 66)
	var st: Array = hx(MSTONE)
	for y in range(6, 62):
		var w: float = 11.0 if y > 14 else 11.0 * sqrt(maxf(0.0, 1.0 - pow((14.0 - y) / 9.0, 2.0)))
		for x in range(int(17 - w), int(17 + w)):
			var u: float = (x - (17 - w)) / maxf(1.0, 2.0 * w)
			px(im, x, y, st[4] if u < 0.3 else (st[3] if u < 0.75 else st[1]))
	var ar: Array = hx(ARCANE)
	var glyphs: Array = [[0, 0, 0, 4, 2, 2], [-2, 0, 2, 0, 0, -3], [0, 0, 3, 3, 3, 0]]
	for g in range(3):
		var gy: int = 20 + g * 13
		var gl: Array = glyphs[g]
		line(im, 17 + int(gl[0]), gy + int(gl[1]), 17 + int(gl[2]), gy + int(gl[3]), ar[3])
		line(im, 17 + int(gl[2]), gy + int(gl[3]), 17 + int(gl[4]), gy + 4 + int(gl[5]), ar[4])
	ell(im, 17, 62, 13, 3, Color(0.1, 0.1, 0.2, 0.35))
	outline_auto(im, 0.4)
	save3(im, "rune_stone")


func gen_crystal_cluster() -> void:
	var im: Image = new_img(56, 56)
	var cr: Array = hx(CRYST)
	ell(im, 28, 52, 22, 4, Color(0.15, 0.1, 0.3, 0.35))
	for sh in [[28, 50, 7, 40, -0.05], [17, 52, 5, 26, -0.4], [40, 52, 5, 30, 0.35], [10, 53, 3, 14, -0.6], [47, 53, 3, 16, 0.6]]:
		var bx: float = float(sh[0])
		var by: float = float(sh[1])
		var hw: float = float(sh[2])
		var hgt: float = float(sh[3])
		var tilt: float = float(sh[4])
		for k in range(int(hgt)):
			var t: float = float(k) / hgt
			var w: float = hw * (1.0 if t < 0.75 else (1.0 - (t - 0.75) / 0.25))
			var cxk: float = bx + tilt * k
			for x in range(int(cxk - w), int(cxk + w) + 1):
				var u: float = (x + 0.5 - (cxk - w)) / maxf(1.0, 2.0 * w)
				var ci: int = 4 if u < 0.35 else (3 if u < 0.6 else 2)
				if t > 0.75:
					ci += 1
				px(im, x, int(by) - k, cr[clampi(ci, 0, 5)])
	star(im, 25, 18, 2, Color("e8e0ff"))
	outline_auto(im, 0.35)
	save3(im, "crystal_cluster")


func gen_moon_flowers() -> void:
	# крупные белые и голубые цветы на тонких стеблях, с листьями — заметны издалека
	var im: Image = new_img(44, 32)
	for k in range(5):
		var x: int = 5 + k * 8 + int(h01(k, 5, 2) * 3.0)
		var top: int = 7 + int(h01(k, 1, 9) * 9.0)
		for y in range(top, 30):
			px(im, x, y, Color("4a8a6a") if y % 3 != 0 else Color("3a7058"))
		px(im, x - 1, 24, Color("6aae7a"))
		px(im, x - 2, 23, Color("6aae7a"))
		px(im, x + 1, 26, Color("5a9a6a"))
		px(im, x + 2, 25, Color("6aae7a"))
		var pc: Array = hx(["8aa8e8", "c0d6ff", "eef4ff", "ffffff"]) if k % 2 == 0 else hx(["a898e0", "d0c4ff", "f2eeff", "ffffff"])
		for o in [Vector2i(0, -3), Vector2i(-3, -1), Vector2i(3, -1), Vector2i(-2, 2), Vector2i(2, 2)]:
			var ov: Vector2i = o
			disc(im, x + ov.x * 0.8, top + ov.y * 0.8, 1.9, pc[1])
			disc(im, x + ov.x * 0.8 - 0.4, top + ov.y * 0.8 - 0.4, 1.1, pc[3])
		disc(im, x, top, 1.2, Color("f6d860"))
		px(im, x, top, Color("fff4b0"))
	outline_auto(im, 0.3)
	save3(im, "moon_flowers")


## Сундук-мимик: кадр 0 — обычный сундук, кадр 1 — открылся, язык и зубы
func gen_mimic() -> void:
	var sheet: Image = new_img(44 * 2, 40)
	for f in range(2):
		var im: Image = new_img(44, 40)
		ell(im, 22, 37, 19, 3, Color(0.1, 0.08, 0.14, 0.35))
		planks(im, 4, 20, 36, 16, WOOD, false, 5, 0.45, 3)
		for x in range(4, 40):
			px(im, x, 20, Color("c8a040"))
			px(im, x, 35, Color("8a6a2a"))
		rect(im, 4, 20, 3, 16, Color("b8963a"))
		rect(im, 37, 20, 3, 16, Color("b8963a"))
		if f == 0:
			# крышка закрыта
			for y in range(8, 21):
				var w: float = 18.0 - pow(maxf(0.0, 13.0 - float(y - 8)) / 13.0, 2.0) * 4.0
				for x2 in range(int(22 - w), int(22 + w)):
					px(im, x2, y, pick(WOOD, 0.6 - float(20 - y) * 0.01 + (0.15 if posmod(x2, 6) == 0 else 0.0), x2, y))
			for x3 in range(4, 40):
				px(im, x3, 19, Color("c8a040"))
			rect(im, 19, 17, 6, 7, Color("e8c860"))
			px(im, 21, 20, Color("3a2a1a"))
			px(im, 22, 20, Color("3a2a1a"))
		else:
			# пасть: крышка откинута, внутри красное, зубы, язык
			for y4 in range(0, 12):
				for x4 in range(6, 38):
					px(im, x4, y4, pick(WOOD, 0.5 + (0.15 if posmod(x4, 6) == 0 else 0.0), x4, y4))
			for y5 in range(12, 22):
				for x5 in range(6, 38):
					px(im, x5, y5, Color("6a1020").lerp(Color("2a0610"), float(y5 - 12) / 10.0))
			for k in range(7):
				var tx: int = 8 + k * 4
				for j in range(3):
					px(im, tx + 1, 12 + j, Color("f6f0e0"))
					px(im, tx + 1, 21 - j, Color("f6f0e0"))
				px(im, tx, 12, Color("f6f0e0"))
				px(im, tx + 2, 21, Color("f6f0e0"))
			ell(im, 26, 22, 6, 3, Color("e85a7a"))
			ell(im, 25, 21, 4, 1.6, Color("f88aa0"))
			px(im, 14, 8, Color("ffe060"))
			px(im, 29, 8, Color("ffe060"))
		outline_auto(im, 0.4)
		sheet.blit_rect(im, Rect2i(0, 0, 44, 40), Vector2i(f * 44, 0))
	save3(sheet, "mimic")


# ---------------------------------------------------------------- девушки-маги

const MAGE_LOOKS: Array = [
	# имя, волосы, платье, длинная мантия (плащ), пелерина, кристалл посоха, глаза
	["mage_aurel", ["8a8a7a", "a8a898", "c4c4b4", "dcdccc", "ececde", "f6f6ec", "ffffff"], ["5e6a74", "8896a2", "b0bcc6", "cfd8de", "e4eaee", "f2f6f8", "ffffff"], ["1a1a24", "26262e", "34343e", "444450", "585866", "707080", "8e8e9e"], ["e8e8ec", "f6f6f8", "ffffff"], "c03040", ["2a5a3a", "4a9a6a", "8ae0aa"]],
	["mage_noa", ["2a1a4a", "3e2866", "543a84", "6e50a2", "8a6cbe", "a88cd6", "c8b0ea"], ["2a1e3a", "3e2c54", "54406e", "6c568a", "866ea6", "a28ac0", "c0aad8"], ["14102a", "1e183c", "2a2250", "382e66", "483c7e", "5c4e96", "7466b0"], ["3e2c54", "54406e", "6c568a"], "4a8aff", ["4a2a6a", "8a5ac8", "c8a0ff"]],
	["mage_ilka", ["4a1a12", "6e2a16", "92401e", "b4582a", "d0763a", "e69652", "f6ba7a"], ["1a3a3a", "245050", "306a68", "408680", "56a29a", "76bcb2", "a0d6cc"], ["2a1a10", "3e2818", "543a22", "6c4c2e", "86623c", "a07c50", "bc9a6c"], ["2a4a48", "3a6a66", "56908a"], "4ac060", ["6a3a1a", "c8762a", "f6c060"]],
	["mage_lisel", ["9a9268", "b4ac80", "ccc49a", "e0dab6", "eeead0", "f8f6e8", "ffffff"], ["6a6a72", "8e8e98", "b2b2bc", "d0d0d8", "e6e6ec", "f4f4f8", "ffffff"], ["5a4a2a", "766236", "927c46", "ac965a", "c4b074", "dacc96", "eee4bc"], ["f0e8d0", "f8f2e2", "ffffff"], "d04040", ["2a5a3a", "4a9a6a", "8ae0aa"]],
	["mage_fenna", ["2a1a3a", "3e2858", "543a76", "6e5094", "8a6cb0", "a88cca", "c8b0e0"], ["1a1a2a", "262640", "343458", "464672", "5c5c8e", "7676aa", "9696c6"], ["120e1e", "1a1430", "241c42", "302656", "3e326c", "504284", "66569e"], ["303050", "444470", "5c5c90"], "e0c040", ["4a2a6a", "8a5ac8", "c8a0ff"]],
]


## Пелерина с золотым кантом и брошью + посох с кольцом и кристаллом
func mage_extras(im: Image, dir: int, f: int, cap: Array, gem: Color) -> void:
	var b: int = -1 if (f == 1 or f == 3 or f == 6 or f == 7) else 0
	var cx: float = 40.0
	var back: bool = dir == 1 or dir == 5
	var gold: Color = Color("e8c860")
	if not back:
		for y in range(36 + b, 57 + b):
			var t: float = float(y - 36 - b) / 20.0
			var hw: float = 11.0 + t * 7.0
			var x0: float = cx - hw
			var x1: float = cx + hw
			if dir == 2:
				x0 = cx - 7.0 - t * 2.0
				x1 = cx + 8.0 + t * 4.0
			elif dir == 4:
				x0 = cx - hw + 1.0
			for x in range(int(x0), int(x1) + 1):
				# низ пелерины — волной
				var hem: float = 56.0 + b - absf(sin((x - cx) * 0.35)) * 1.5
				if y > hem:
					continue
				var u: float = (x + 0.5 - x0) / maxf(1.0, x1 - x0)
				var c: Color = cap[2] if u < 0.35 else (cap[1] if u < 0.8 else cap[0])
				if y > hem - 2.0:
					c = gold
				px(im, x, y, c)
		# воротник и брошь
		for x2 in range(int(cx) - 6, int(cx) + 7):
			px(im, x2, 36 + b, gold)
		if dir != 2:
			disc(im, cx + (1.0 if dir == 4 else 0.0), 40 + b, 2.2, gold)
			px(im, int(cx) + (1 if dir == 4 else 0), 40 + b, gem)
	# посох
	var sx: float = cx + 17.0
	if dir == 2:
		sx = cx - 19.0
	elif dir == 1:
		sx = cx - 17.0
	elif dir == 5:
		sx = cx - 15.0
	elif dir == 4:
		sx = cx + 16.0
	for y3 in range(20 + b, 156):
		px(im, int(sx), y3, Color("6e4a2a"))
		px(im, int(sx) + 1, y3, Color("4a3018"))
		if posmod(y3, 22) == 0:
			px(im, int(sx), y3, gold)
			px(im, int(sx) + 1, y3, gold)
	# навершие: кольцо с крылышками и кристалл в середине
	var top: Vector2 = Vector2(sx + 0.5, 12.0 + b)
	for a in range(28):
		var an: float = TAU * float(a) / 28.0
		px(im, int(round(top.x + cos(an) * 6.0)), int(round(top.y + sin(an) * 6.0)), gold)
	for s in [-1, 1]:
		for k in range(4):
			px(im, int(top.x) + s * (7 + k), int(top.y) - k, gold.lightened(0.2))
			px(im, int(top.x) + s * (7 + k), int(top.y) - k + 1, gold.darkened(0.2))
	disc(im, top.x, top.y, 3.0, gem)
	px(im, int(top.x) - 1, int(top.y) - 1, Color("ffffff"))
	px(im, int(top.x), int(top.y) + 6, gold)
	px(im, int(top.x), int(top.y) + 7, gold)


func gen_mage_girls() -> void:
	var sh: Array = HAIRL7.duplicate()
	var sw7: Array = WHITE7.duplicate()
	var st: Array = TEAL7.duplicate()
	var fw: int = 80
	var fh: int = 160
	var mirror: Dictionary = {2: 3, 4: 6, 5: 7}
	BOUNCE_OVR = 0
	var line_up: Image = new_img(fw * MAGE_LOOKS.size(), fh)
	var views: Image = new_img(fw * 4, fh)
	var li: int = 0
	for lk in MAGE_LOOKS:
		HAIRL7 = hx(lk[1])
		WHITE7 = hx(lk[2])
		TEAL7 = hx(lk[3])
		var ey: Array = hx(lk[6])
		EYE_OVR = {"I": ey[0], "i": ey[1], "j": ey[2]}
		_head_pal()
		var cap: Array = hx(lk[4])
		var gem: Color = Color(String(lk[5]))
		var vs: Image = new_img(fw * 8, fh * 8)
		for vd in [0, 1, 2, 4, 5]:
			for k in range(8):
				var c2: Image = new_img(fw, fh)
				draw_hero10(c2, vd, k)
				mage_extras(c2, vd, k, cap, gem)
				outline_auto(c2, OUTLINE_CHAR)
				vs.blit_rect(c2, Rect2i(0, 0, fw, fh), Vector2i(k * fw, vd * fh))
				if mirror.has(vd):
					var mc: Image = c2.duplicate()
					mc.flip_x()
					vs.blit_rect(mc, Rect2i(0, 0, fw, fh), Vector2i(k * fw, int(mirror[vd]) * fh))
		save3(vs, String(lk[0]))
		gen_faces10("faces_" + String(lk[0]))
		line_up.blit_rect(vs, Rect2i(4 * fw, 0, fw, fh), Vector2i(li * fw, 0))
		if li == 0:
			for d2 in [2, 4, 1, 5]:
				views.blit_rect(vs, Rect2i(4 * fw, int(d2) * fh, fw, fh), Vector2i([2, 4, 1, 5].find(d2) * fw, 0))
		li += 1
	line_up.resize(line_up.get_width() * 3, line_up.get_height() * 3, Image.INTERPOLATE_NEAREST)
	line_up.save_png(ProjectSettings.globalize_path("res://").path_join("../screenshots/mage_lineup.png"))
	views.resize(views.get_width() * 3, views.get_height() * 3, Image.INTERPOLATE_NEAREST)
	views.save_png(ProjectSettings.globalize_path("res://").path_join("../screenshots/mage_views.png"))
	EYE_OVR = {}
	HAIRL7 = sh
	WHITE7 = sw7
	TEAL7 = st
	_head_pal()


# ---------------------------------------------------------------- рокерши клуба «Старлит»

const ROCK_BLACK: Array = ["0c0c10", "14141a", "1e1e26", "2a2a34", "383844", "484856", "5a5a6a"]
const ROCK_LOOKS: Array = [
	# имя, волосы, одежда, глаза, инструмент, цвет инструмента, ремень
	["rock_bokki", ["8a3a62", "b25282", "d874a4", "ee96bc", "f8b4d0", "fcd0e2", "ffe6f0"], ROCK_BLACK, ["1a4a8a", "3a86d8", "a8dcff"], "guitar", "c43a3a", "e8c060", "clip"],
	["rock_niko", ["a07818", "c49a24", "e4b832", "f6d04a", "fce070", "fff098", "fff6c0"], ROCK_BLACK, ["8a2a1a", "d85a3a", "ffb89a"], "sticks", "e8e0c8", "e8c060", "side"],
	["rock_rio", ["16264a", "1e3470", "284492", "3458b4", "4a72ce", "6c92e2", "98b4f0"], ROCK_BLACK, ["8a8a1a", "d8d84a", "fffaa0"], "bass", "e8e0c0", "58a0e8", "bob"],
	["rock_ikka", ["7a1414", "a02020", "c43030", "e04848", "f06a5a", "f88e7a", "fcb49c"], ROCK_BLACK, ["3a7a1a", "7ad03a", "d0ff9a"], "guitar", "d8a02a", "e8e0d0", "tie"],
	["rock_seiko", ["1c1830", "2a2444", "3a3460", "4c4680", "62609c", "7e7cb8", "a09ed0"], ["3a1418", "541e24", "722a32", "903a44", "ae5260", "c8727e", "e096a0"], ["8a1a2a", "d84a5a", "ffa0aa"], "none", "000000", "000000", "long"],
	["rock_pei", ["202024", "2e2e34", "40404a", "545460", "6c6c7a", "888896", "a8a8b6"], ["303a40", "424e56", "586870", "708288", "8a9ca2", "a8b8bc", "c8d4d6"], ["4a2a6a", "8a5ad0", "d0b0ff"], "phones", "e04a4a", "000000", "long"],
	["rock_kuki", ["2a1a2a", "3e2640", "543458", "6c4672", "865c8c", "a07aa6", "bc9cc0"], ["4a2a6a", "62408a", "7e5aa6", "9a78c0", "b498d6", "ccb6e8", "e4d6f6"], ["8a1a5a", "d84aa0", "ffa0d8"], "bottle", "5a9a5a", "000000", "long"],
]


## Инструмент за спиной/на ремне, наушники, бутылка, значок группы на груди
func rock_extras(im: Image, dir: int, f: int, inst: String, col: Color, strap: Color, emblem: bool, style: String = "long", hair: Array = []) -> void:
	var b: int = -1 if (f == 1 or f == 3 or f == 6 or f == 7) else 0
	var cx: float = 40.0
	var back: bool = dir == 1 or dir == 5
	var dk: Color = col.darkened(0.45)
	var wood: Color = Color("8a5a2e")
	var wood_d: Color = Color("5a3a1a")
	var sgn: float = -1.0 if dir == 2 else 1.0
	if style != "long" and style != "bob" and dir != 1 and dir != 5:
		var hc: Color = hair[4] if hair.size() > 4 else Color.WHITE
		var hd: Color = hair[2] if hair.size() > 2 else Color.GRAY
		var hxo: float = (0.0 if dir == 0 else (3.0 if dir == 4 else -3.0))
		if style == "clip":
			var kx: int = int(cx - 9.0 + hxo)
			rect(im, kx, 16 + b, 3, 3, Color("4aa0f0"))
			rect(im, kx, 19 + b, 3, 3, Color("f0d040"))
			px(im, kx, 16 + b, Color("a8dcff"))
			px(im, kx, 19 + b, Color("fff6a0"))
		elif style == "side" or style == "tie":
			var sx2: float = cx + 11.0 + hxo
			var len: int = 30 if style == "side" else 12
			for y in range(14 + b, 14 + b + len):
				var wv: int = int(round(sin(float(y) * 0.4) * 1.0))
				rect(im, int(sx2) + wv, y, 3, 1, hc if posmod(y, 3) != 0 else hd)
			rect(im, int(sx2) - 1, 13 + b, 5, 3, Color("e84a4a") if style == "tie" else Color("d02828"))
			px(im, int(sx2), 13 + b, Color("ff9a9a"))
	if emblem and not back:
		var ex: float = cx + (0.0 if dir == 0 else (3.0 if dir == 4 else -2.0))
		if dir != 2:
			for a in range(14):
				var an: float = TAU * float(a) / 14.0
				px(im, int(round(ex + cos(an) * 4.0)), int(round(49 + b + sin(an) * 4.0)), Color("d8d8e0"))
			px(im, int(ex), 49 + b, Color("d8d8e0"))
	if inst == "guitar" or inst == "bass":
		var neck: float = 30.0 if inst == "bass" else 24.0
		if not back:
			# на груди: корпус слева у бедра, гриф вверх-вперёд
			var bx: float = cx - 5.0 * sgn
			var by: float = 80.0 + b
			for y in range(38 + b, 78 + b):
				var t: float = float(y - 38 - b) / 40.0
				px(im, int(cx + 9.0 * sgn - t * 14.0 * sgn), y, strap)
			ell(im, bx, by, 10.0, 8.0, col)
			ell(im, bx + 6.0 * sgn, by - 4.0, 6.0, 5.0, col)
			ell(im, bx, by + 1.0, 3.0, 3.0, dk)
			for k in range(int(neck)):
				var tx: int = int(bx + 8.0 * sgn + float(k) * sgn * 1.1)
				var ty: int = int(by - 5.0 - float(k) * 0.4)
				px(im, tx, ty, wood)
				px(im, tx, ty + 1, wood_d)
			var hx2: int = int(bx + 8.0 * sgn + neck * sgn * 1.1)
			rect(im, hx2 if sgn > 0 else hx2 - 4, int(by - 5.0 - neck * 0.4) - 2, 4, 4, wood_d)
			px(im, int(bx + 1.0), int(by + 4.0), Color("ffffff"))
		else:
			# за спиной: корпус по центру, гриф над плечом
			ell(im, cx, 72.0 + b, 11.0, 9.0, col)
			ell(im, cx, 61.0 + b, 7.0, 6.0, col)
			ell(im, cx, 72.0 + b, 3.0, 3.0, dk)
			for y2 in range(22 + b, 58 + b):
				px(im, int(cx + 11.0 - float(y2 - 22 - b) * 0.12), y2, wood)
				px(im, int(cx + 12.0 - float(y2 - 22 - b) * 0.12), y2, wood_d)
			rect(im, int(cx) + 9, 18 + b, 5, 5, wood_d)
	elif inst == "sticks":
		for s in [-1, 1]:
			for k in range(16):
				px(im, int(cx + float(s) * (11.0 + float(k) * 0.35)), 82 + b - k, Color("e8d4a0"))
			disc(im, cx + float(s) * 16.5, 65.0 + b, 1.3, Color("c8a060"))
	elif inst == "phones":
		for a2 in range(-8, 9):
			var ay: int = 30 + b - int(round(sqrt(maxf(0.0, 81.0 - float(a2 * a2)) ) * 0.9)) + 4
			px(im, int(cx) + a2, 44 + b - int(round(sqrt(maxf(0.0, 100.0 - float(a2 * a2)) ) * 0.3)), Color("2a2a30"))
		disc(im, cx - 9.0, 36.0 + b, 2.6, col)
		disc(im, cx + 9.0, 36.0 + b, 2.6, col)
	elif inst == "bottle":
		var bx2: float = cx + 14.0 * sgn
		rect(im, int(bx2) - 2, 70 + b, 5, 10, col)
		rect(im, int(bx2) - 1, 66 + b, 3, 5, col.darkened(0.2))
		px(im, int(bx2) - 1, 72 + b, Color("e8f4e8"))


func gen_rock_girls() -> void:
	var sh: Array = HAIRL7.duplicate()
	var sw7: Array = WHITE7.duplicate()
	var st: Array = TEAL7.duplicate()
	var fw: int = 80
	var fh: int = 160
	var mirror: Dictionary = {2: 3, 4: 6, 5: 7}
	BOUNCE_OVR = 0
	NO_CAPE = true
	var line_up: Image = new_img(fw * ROCK_LOOKS.size(), fh)
	var views: Image = new_img(fw * 4 * 2, fh * 2)
	var li: int = 0
	for lk in ROCK_LOOKS:
		HAIRL7 = hx(lk[1])
		WHITE7 = hx(lk[2])
		TEAL7 = hx(lk[2])
		var ey: Array = hx(lk[3])
		EYE_OVR = {"I": ey[0], "i": ey[1], "j": ey[2]}
		_head_pal()
		var inst: String = String(lk[4])
		var icol: Color = Color(String(lk[5]))
		var scol: Color = Color(String(lk[6]))
		var sty: String = String(lk[7])
		HAIR_CUT = 40 if sty == "bob" else 0
		var emb: bool = String(lk[0]) in ["rock_bokki", "rock_niko", "rock_rio", "rock_ikka"]
		var vs: Image = new_img(fw * 8, fh * 8)
		for vd in [0, 1, 2, 4, 5]:
			for k in range(8):
				var c2: Image = new_img(fw, fh)
				draw_hero10(c2, vd, k)
				rock_extras(c2, vd, k, inst, icol, scol, emb, sty, HAIRL7)
				outline_auto(c2, OUTLINE_CHAR)
				vs.blit_rect(c2, Rect2i(0, 0, fw, fh), Vector2i(k * fw, vd * fh))
				if mirror.has(vd):
					var mc: Image = c2.duplicate()
					mc.flip_x()
					vs.blit_rect(mc, Rect2i(0, 0, fw, fh), Vector2i(k * fw, int(mirror[vd]) * fh))
		save3(vs, String(lk[0]))
		gen_faces10("faces_" + String(lk[0]))
		line_up.blit_rect(vs, Rect2i(4 * fw, 0, fw, fh), Vector2i(li * fw, 0))
		li += 1
	line_up.resize(line_up.get_width() * 3, line_up.get_height() * 3, Image.INTERPOLATE_NEAREST)
	line_up.save_png(ProjectSettings.globalize_path("res://").path_join("../screenshots/rock_lineup.png"))
	EYE_OVR = {}
	HAIR_CUT = 0
	NO_CAPE = false
	HAIRL7 = sh
	WHITE7 = sw7
	TEAL7 = st
	_head_pal()


# ================================================================== степь: орки и гоблины

const LOG: Array = ["2e1c10", "462c18", "5e3c22", "7a502e", "94683e", "ae8454", "c8a272"]
const HIDE: Array = ["4a3220", "64462c", "7e5c3a", "98744c", "b08c62", "c8a67e", "dcc29e"]
const PATCH: Array = [["6a3a2a", "8a5038", "aa6a48"], ["3a5a3a", "4e7a4a", "6a9a5e"], ["6a5a2a", "8a7838", "aa984c"], ["4a3a6a", "62508a", "7e6aa6"]]


func gen_orcs() -> void:
	gen_orc_longhouse()
	gen_orc_tent()
	gen_totem()
	gen_palisade()
	gen_campfire()
	gen_war_drum()
	gen_goblin_hut("goblin_hut_a", 31)
	gen_goblin_hut("goblin_hut_b", 47)
	gen_goblin_tower()
	gen_junk_pile()
	gen_goblin_stall()
	gen_orc_girls()
	var items: Array = []
	for nm in ["orc_longhouse", "orc_tent", "totem", "palisade", "campfire", "war_drum", "goblin_hut_a", "goblin_hut_b", "goblin_tower", "junk_pile", "goblin_stall"]:
		items.append([nm, Image.load_from_file(ProjectSettings.globalize_path(OUT + String(nm) + ".png"))])
	_sheet(items, 2, "orc_preview.png")


## Бревно (вертикальное), заострённое сверху
func log_v(im: Image, x: int, top: int, bot: int, w: int, sharp: bool) -> void:
	var lg: Array = hx(LOG)
	for y in range(top, bot):
		var hw: float = float(w) / 2.0
		if sharp and y < top + w:
			hw = float(y - top + 1) / float(w) * float(w) / 2.0
		for xx in range(int(x - hw), int(x + hw) + 1):
			var u: float = (xx + 0.5 - (x - hw)) / maxf(1.0, 2.0 * hw)
			var v: int = 5 if u < 0.25 else (4 if u < 0.6 else (3 if u < 0.85 else 2))
			if posmod(y * 3 + xx, 17) == 0:
				v -= 1
			px(im, xx, y, lg[clampi(v, 0, 6)])


func gen_orc_longhouse() -> void:
	var W: int = 280
	var H: int = 220
	var im: Image = new_img(W, H)
	var cx: int = W / 2
	var ground: int = H - 10
	rng.seed = 313
	# стены из брёвен
	for x in range(30, W - 30, 9):
		log_v(im, x, 110, ground, 9, false)
	# крыша из шкур на жердях: широкая, провисающая
	var hd: Array = hx(HIDE)
	for y in range(40, 120):
		var t: float = float(y - 40) / 80.0
		var hw: float = 40.0 + t * 100.0
		for x2 in range(int(cx - hw), int(cx + hw) + 1):
			var sag: float = sin((x2 - cx + hw) / maxf(1.0, 2.0 * hw) * PI * 4.0) * 2.0
			var v: float = 0.68 - absf(x2 - cx) / hw * 0.25 - t * 0.15 + sag * 0.04
			if posmod(int((x2 - cx + hw) / 34.0), 2) == 0:
				v += 0.06
			# швы между шкурами
			if posmod(x2 - cx + int(hw), 34) == 0:
				v -= 0.25
			if posmod(x2 + y, 23) == 0:
				v -= 0.08
			px(im, x2, y, pick(hd, v, x2, y))
	# кромка с бахромой
	for x3 in range(cx - 140, cx + 141):
		for j in range(4 + posmod(x3, 3)):
			px(im, x3, 120 + j, hd[1] if j > 1 else hd[2])
	# жерди крест-накрест на коньке и рога
	thick_line(im, Vector2(cx - 30, 20), Vector2(cx + 10, 56), 4.0, hx(LOG), 0.5)
	thick_line(im, Vector2(cx + 30, 20), Vector2(cx - 10, 56), 4.0, hx(LOG), 0.6)
	for s in [-1, 1]:
		for k in range(12):
			var t2: float = float(k) / 11.0
			var p: Vector2 = Vector2(cx + s * (40 + t2 * 18.0), 44 - sin(t2 * PI * 0.8) * 16.0)
			disc(im, p.x, p.y, 2.6 - t2 * 1.6, Color("e8dcc0") if t2 < 0.8 else Color("fff8e8"))
	# вход: тёмный проём со шкурой-пологом и знаменем рода
	for y4 in range(ground - 56, ground):
		for x4 in range(cx - 20, cx + 21):
			px(im, x4, y4, Color("1e140c") if absi(x4 - cx) < 18 else hx(LOG)[1])
	for y5 in range(ground - 56, ground - 20):
		for x5 in range(cx - 18, cx - 2):
			px(im, x5, y5, pick(hd, 0.55 - float(x5 - cx + 18) * 0.02, x5, y5))
	# знамя с красной лапой-отпечатком
	for y6 in range(130, 176):
		for x6 in range(cx + 34, cx + 56):
			if y6 > 168 and absi(x6 - cx - 45) < y6 - 168:
				continue
			px(im, x6, y6, Color("3a2a1e") if x6 < cx + 45 else Color("2e2016"))
	disc(im, cx + 45, 154, 5.0, Color("b02a20"))
	for k2 in range(4):
		disc(im, cx + 39 + k2 * 4, 145, 1.6, Color("b02a20"))
	# череп-трофей над входом (мультяшный)
	ell(im, cx, ground - 62, 7, 6, Color("efe6d0"))
	px(im, cx - 3, ground - 63, Color("2a1a10"))
	px(im, cx + 2, ground - 63, Color("2a1a10"))
	rect(im, cx - 3, ground - 58, 7, 2, Color("d8ccb0"))
	outline_auto(im, 0.4)
	save3(im, "orc_longhouse")


func gen_orc_tent() -> void:
	var im: Image = new_img(120, 112)
	var hd: Array = hx(HIDE)
	var cx: int = 60
	for y in range(16, 106):
		var t: float = float(y - 16) / 90.0
		var hw: float = 6.0 + t * 52.0
		for x in range(int(cx - hw), int(cx + hw) + 1):
			var u: float = (x + 0.5 - (cx - hw)) / (2.0 * hw)
			var v: float = 0.72 - u * 0.45
			if posmod(int(u * 6.0 * 10.0), 10) == 0:
				v -= 0.2
			px(im, x, y, pick(hd, v, x, y))
	# жерди торчат сверху
	for k in range(5):
		thick_line(im, Vector2(cx, 18), Vector2(cx - 10 + k * 5, 2), 2.0, hx(LOG), 0.6)
	# полог входа и узоры
	for y2 in range(66, 106):
		var w: float = float(y2 - 66) * 0.42
		for x2 in range(int(cx - w), int(cx + w) + 1):
			px(im, x2, y2, Color("1e140c"))
	for k2 in range(8):
		var yy: int = 50 + k2 * 2
		px(im, cx - 26 + k2 * 2, yy, Color("b02a20"))
		px(im, cx + 26 - k2 * 2, yy, Color("b02a20"))
	outline_auto(im, 0.4)
	save3(im, "orc_tent")


func gen_totem() -> void:
	var im: Image = new_img(44, 120)
	log_v(im, 22, 20, 118, 14, false)
	# вырезанные лица в три яруса
	var cols: Array = [Color("b02a20"), Color("e0b040"), Color("2a6a8a")]
	for k in range(3):
		var fy: int = 34 + k * 28
		rect(im, 16, fy, 4, 3, Color("1e140c"))
		rect(im, 24, fy, 4, 3, Color("1e140c"))
		rect(im, 17, fy + 9, 10, 3, cols[k])
		px(im, 18, fy + 12, Color("efe6d0"))
		px(im, 25, fy + 12, Color("efe6d0"))
		for x in range(15, 30):
			px(im, x, fy - 5, cols[(k + 1) % 3])
	# крылья-доски наверху и рога
	planks(im, 2, 22, 40, 6, hx(LOG), false, 6, 0.55, 2)
	for s in [-1, 1]:
		for j in range(10):
			var t: float = float(j) / 9.0
			disc(im, 22 + s * (6 + t * 10.0), 18 - sin(t * PI * 0.8) * 12.0, 2.2 - t * 1.2, Color("e8dcc0"))
	outline_auto(im, 0.4)
	save3(im, "totem")


func gen_palisade() -> void:
	var im: Image = new_img(96, 80)
	for x in range(6, 92, 10):
		log_v(im, x, 4 + int(h01(x, 1, 3) * 10.0), 78, 10, true)
	for x2 in range(0, 96):
		px(im, x2, 40, Color("3a2814"))
		px(im, x2, 41, Color("5a4022"))
	outline_auto(im, 0.4)
	save3(im, "palisade")


func gen_campfire() -> void:
	var im: Image = new_img(56, 40)
	for k in range(9):
		var a: float = TAU * k / 9.0
		ball(im, 28 + cos(a) * 18.0, 28 + sin(a) * 7.0, 4.0, 3.0, STONE, 0.3)
	thick_line(im, Vector2(16, 30), Vector2(40, 24), 4.0, hx(LOG), 0.5)
	thick_line(im, Vector2(18, 24), Vector2(38, 31), 4.0, hx(LOG), 0.4)
	ell(im, 28, 27, 8, 3, Color("ff8a2a"))
	ell(im, 28, 27, 4, 1.6, Color("ffe08a"))
	# вертел с мясом
	for y in range(6, 30):
		px(im, 8, y, hx(LOG)[2])
		px(im, 48, y, hx(LOG)[2])
	for x in range(8, 49):
		px(im, x, 8, hx(LOG)[3])
	ell(im, 28, 11, 7, 4, Color("8a4a2a"))
	ell(im, 27, 10, 5, 2.5, Color("b06a3a"))
	px(im, 25, 9, Color("e8a060"))
	outline_auto(im, 0.4)
	save3(im, "campfire")


func gen_war_drum() -> void:
	var im: Image = new_img(44, 46)
	var hd: Array = hx(HIDE)
	for y in range(10, 42):
		for x in range(6, 38):
			var u: float = (x - 6) / 31.0
			var v: float = 0.6 - u * 0.35
			if posmod(y, 8) == 0:
				v -= 0.2
			px(im, x, y, pick(hx(LOG), v, x, y))
	ell(im, 22, 10, 16, 5, hd[5])
	ell(im, 22, 10, 13, 3.5, hd[6])
	for k in range(8):
		var x2: int = 8 + k * 4
		line(im, x2, 13, x2 + 2, 40, Color("c8b080"))
	# колотушки
	thick_line(im, Vector2(30, 2), Vector2(40, 12), 2.0, hx(LOG), 0.6)
	disc(im, 30, 2, 2.5, hd[4])
	outline_auto(im, 0.4)
	save3(im, "war_drum")


## Гоблинский домик: кривой, на сваях, крыша-лоскуты, труба-ведро
func gen_goblin_hut(name: String, seed_v: int) -> void:
	rng.seed = seed_v
	var im: Image = new_img(130, 140)
	var cx: int = 64
	var ground: int = 132
	# сваи
	for x in [34, 60, 92]:
		log_v(im, int(x), 100, ground, 6, false)
	# кривые стены из досок
	for y in range(64, 104):
		var lean: float = float(104 - y) * 0.18
		for x2 in range(26 + int(lean), 102 + int(lean)):
			var pl: int = posmod(x2 - int(lean), 9)
			var v: float = 0.5 + (h01(x2 / 9, 2, seed_v) - 0.5) * 0.3 - (0.22 if pl == 0 else 0.0)
			px(im, x2, y, pick(WOOD, v, x2, y))
	# дверь-кругляш и окошко-банка
	disc(im, cx - 6, 90, 11.0, WOOD[1])
	disc(im, cx - 6, 90, 9.0, Color("2a1e14"))
	disc(im, cx + 24, 78, 6.0, WOOD[1])
	disc(im, cx + 24, 78, 4.5, Color("e8c060"))
	# крыша из лоскутов
	for y3 in range(20, 70):
		var t: float = float(y3 - 20) / 50.0
		var hw: float = 10.0 + t * 54.0
		var c0: float = cx + 6.0 - t * 4.0 + sin(t * 3.0) * 3.0
		for x3 in range(int(c0 - hw), int(c0 + hw) + 1):
			var pi2: int = posmod(int((x3 + y3 * 0.6) / 16.0) + int(y3 / 14), PATCH.size())
			var pc: Array = PATCH[pi2]
			var u: float = (x3 + 0.5 - (c0 - hw)) / (2.0 * hw)
			var cc: Color = Color(pc[2] if u < 0.35 else (pc[1] if u < 0.75 else pc[0]))
			if posmod(x3 + int(y3 * 0.6), 16) == 0 or posmod(y3, 14) == 0:
				cc = Color("e8d8a8") if posmod(x3 + y3, 3) == 0 else cc.darkened(0.3)
			px(im, x3, y3, cc)
	# труба-ведро с дымком и заплатки
	rect(im, cx + 20, 12, 10, 16, Color("6a6a72"))
	rect(im, cx + 19, 12, 12, 2, Color("8a8a92"))
	disc(im, cx + 25, 6, 3.0, Color(0.85, 0.85, 0.9, 0.6))
	disc(im, cx + 29, 1, 2.0, Color(0.85, 0.85, 0.9, 0.4))
	# лесенка к двери
	for k in range(4):
		rect(im, cx - 16, 104 + k * 7, 20, 2, WOOD[4])
	outline_auto(im, 0.4)
	save3(im, name)


func gen_goblin_tower() -> void:
	var im: Image = new_img(90, 190)
	var cx: int = 44
	# шаткие ноги-жерди
	thick_line(im, Vector2(20, 186), Vector2(36, 60), 4.0, hx(LOG), 0.5)
	thick_line(im, Vector2(70, 186), Vector2(54, 60), 4.0, hx(LOG), 0.45)
	thick_line(im, Vector2(24, 150), Vector2(66, 120), 2.5, hx(LOG), 0.6)
	thick_line(im, Vector2(66, 150), Vector2(26, 120), 2.5, hx(LOG), 0.5)
	# будка наверху, кривая
	for y in range(34, 64):
		for x in range(22, 70):
			var pl: int = posmod(x, 7)
			px(im, x + int(float(64 - y) * 0.1), y, pick(WOOD, 0.5 - (0.2 if pl == 0 else 0.0), x, y))
	rect(im, 36, 42, 18, 8, Color("1e140c"))
	px(im, 41, 45, Color("ffe060"))
	px(im, 48, 45, Color("ffe060"))
	# крыша-конус из лоскутов и флажок-тряпка
	for y2 in range(6, 36):
		var w: float = float(y2 - 6) * 1.1 + 1.0
		for x2 in range(int(cx + 4 - w), int(cx + 4 + w)):
			var pc: Array = PATCH[posmod(int(x2 / 10) + int(y2 / 8), PATCH.size())]
			px(im, x2, y2, Color(pc[1]) if (x2 + y2) % 9 != 0 else Color("e8d8a8"))
	for y3 in range(0, 8):
		px(im, cx + 4, y3, hx(LOG)[2])
	for y4 in range(0, 5):
		for x4 in range(cx + 5, cx + 14 - y4):
			px(im, x4, y4, Color("c8a030"))
	outline_auto(im, 0.4)
	save3(im, "goblin_tower")


func gen_junk_pile() -> void:
	var im: Image = new_img(70, 46)
	rng.seed = 77
	ell(im, 35, 42, 30, 4, Color(0.1, 0.08, 0.05, 0.35))
	# доски, бочка, котелок, шестерни, колесо
	thick_line(im, Vector2(6, 40), Vector2(40, 20), 4.0, hx(LOG), 0.5)
	thick_line(im, Vector2(30, 40), Vector2(64, 26), 4.0, hx(LOG), 0.4)
	ball(im, 50, 30, 9.0, 10.0, hx(LOG), 0.3)
	ball(im, 20, 32, 8.0, 6.0, IRON, 0.2)
	for g in [[34, 18, 7.0], [56, 14, 5.0], [14, 20, 4.0]]:
		var gc: Vector2 = Vector2(float(g[0]), float(g[1]))
		var r: float = float(g[2])
		for a in range(24):
			var an: float = TAU * a / 24.0
			var rr: float = r + (1.5 if a % 3 == 0 else 0.0)
			px(im, int(gc.x + cos(an) * rr), int(gc.y + sin(an) * rr), Color("5a5a64"))
			if a % 3 == 0:
				px(im, int(gc.x + cos(an) * (rr + 0.8)), int(gc.y + sin(an) * (rr + 0.8)), Color("6a6a74"))
		disc(im, gc.x, gc.y, r - 1.0, Color("8a8a96"))
		disc(im, gc.x - 0.6, gc.y - 0.6, r - 2.4, Color("a8a8b2"))
		disc(im, gc.x, gc.y, r * 0.35, Color("2e2e36"))
	outline_auto(im, 0.4)
	save3(im, "junk_pile")


func gen_goblin_stall() -> void:
	var im: Image = new_img(96, 84)
	for sx in [8, 84]:
		planks(im, int(sx), 22, 4, 60, WOOD, true, 4, 0.45, int(sx))
	planks(im, 4, 54, 88, 24, WOOD, false, 6, 0.4, 2)
	# навес из лоскутов
	for y in range(8, 28):
		for x in range(4, 92):
			var pc: Array = PATCH[posmod(int(x / 14) + int(y / 10), PATCH.size())]
			if y > 24 and posmod(x, 8) > 4:
				continue
			px(im, x, y, Color(pc[1]) if posmod(x, 14) != 0 else Color("e8d8a8"))
	# товары: банки со светлячками, грибы, ключи-шестерёнки
	for k in range(4):
		var bx: int = 12 + k * 10
		rect(im, bx, 42, 7, 10, Color(0.75, 0.9, 1.0, 0.7))
		rect(im, bx, 40, 7, 2, Color("8a6a3a"))
		px(im, bx + 3, 46, Color("fff080"))
	disc(im, 62, 48, 4.0, Color("c03030"))
	px(im, 61, 46, Color("ffffff"))
	disc(im, 74, 48, 4.5, Color("c8a040"))
	disc(im, 74, 48, 1.8, Color("5a4420"))
	outline_auto(im, 0.4)
	save3(im, "goblin_stall")


# ---------------------------------------------------------------- орочки и гоблинши

const ORC_LOOKS: Array = [
	# имя, волосы, одежда, плащ/шкура, кожа, гоблин?
	["orc_grasha", ["14140e", "1e2016", "2a2e20", "3a402c", "4e563a", "667050", "848e6a"], ["3a2216", "54321e", "6e4428", "8a5a36", "a67448", "c0905e", "d8ae7c"], ["3a2a1a", "54402a", "6e563a", "8a704e", "a68a66", "c0a682", "d8c2a0"], ["2a4a1e", "3e6a2a", "568a36", "70a844", "8cc25a", "acd87a", "d0eca4"], false],
	["orc_ruzga", ["4a0e0a", "6e1a12", "922a1a", "b43c24", "d05a34", "e67e4a", "f6a46a"], ["2a2a2e", "3e3e44", "56565e", "6e6e78", "8a8a94", "a6a6b0", "c4c4cc"], ["4a2a1a", "64402a", "7e563a", "98704c", "b08a62", "c8a67e", "dcc29e"], ["2a4a2a", "3a6a3a", "4e8a4a", "68a85e", "86c276", "a8d896", "ccecbc"], false],
	["orc_brakka", ["14140e", "1e2016", "2a2e20", "3a402c", "4e563a", "667050", "848e6a"], ["2a2a2e", "3e3e44", "56565e", "6e6e78", "8a8a94", "a6a6b0", "c4c4cc"], ["2a1a10", "40281a", "583824", "704a30", "8a5e40", "a67656", "c49674"], ["2a4a1e", "3e6a2a", "568a36", "70a844", "8cc25a", "acd87a", "d0eca4"], false],
	["goblin_pip", ["4a1a0a", "74300e", "9e4a14", "c8661e", "e0862e", "f0a84a", "fac87a"], ["3a2e1a", "54442a", "6e5a38", "8a744c", "a68e62", "c0aa80", "d8c6a0"], ["2a2a1a", "3e3e26", "565634", "6e6e44", "8a8a58", "a6a670", "c4c48e"], ["3a4a14", "566a1e", "728a2a", "8ea83a", "a8c254", "c4d878", "e0eca4"], true],
	["goblin_zix", ["2a1a3a", "3e2858", "543a76", "6e5094", "8a6cb0", "a88cca", "c8b0e0"], ["4a2a1a", "64402a", "7e563a", "98704c", "b08a62", "c8a67e", "dcc29e"], ["2a2a1a", "3e3e26", "565634", "6e6e44", "8a8a58", "a6a670", "c4c48e"], ["3a4a14", "566a1e", "728a2a", "8ea83a", "a8c254", "c4d878", "e0eca4"], true],
	["goblin_snik", ["1a1a10", "2a2a18", "3a3a22", "4e4e2e", "64643c", "7e7e50", "9a9a6a"], ["4a3a2a", "604c36", "786044", "907654", "a88e68", "c0a882", "d6c4a2"], ["3a2a1a", "54402a", "6e563a", "8a704e", "a68a66", "c0a682", "d8c2a0"], ["3a4a14", "566a1e", "728a2a", "8ea83a", "a8c254", "c4d878", "e0eca4"], true],
	["goblin_grub", ["5a3a10", "7a5216", "9a6a1e", "b88428", "d0a03a", "e4bc58", "f4d886"], ["2a2a1a", "3e3e26", "565634", "6e6e44", "8a8a58", "a6a670", "c4c48e"], ["4a2a1a", "64402a", "7e563a", "98704c", "b08a62", "c8a67e", "dcc29e"], ["3a4a14", "566a1e", "728a2a", "8ea83a", "a8c254", "c4d878", "e0eca4"], true],
]


## Клыки, острые уши, бусы из клыков (орки) / большие висячие уши (гоблины)
func orc_extras(im: Image, dir: int, f: int, goblin: bool) -> void:
	var b: int = -1 if (f == 1 or f == 3 or f == 6 or f == 7) else 0
	var ears: Dictionary = {
		0: [[Vector2(28, 25), -1], [Vector2(52, 25), 1]], 1: [[Vector2(27, 25), -1], [Vector2(53, 25), 1]],
		2: [[Vector2(45, 25), 1]], 4: [[Vector2(26, 26), -1], [Vector2(49, 24), 1]], 5: [[Vector2(28, 25), -1], [Vector2(54, 24), 1]],
	}
	for e in ears[dir]:
		var ea: Array = e
		var base: Vector2 = (ea[0] as Vector2) + Vector2(0, b)
		var s: int = int(ea[1])
		if goblin:
			# длинное ухо, кончик чуть опущен
			for k in range(11):
				var x: int = int(base.x) + s * k
				var yc: float = base.y - 1.0 + float(k) * 0.1
				var hh: float = 3.0 - float(k) * 0.22
				for y in range(int(yc - hh), int(yc + hh) + 1):
					var ti: int = 4 if y < int(yc) else 3
					if k > 2 and k < 8 and absf(y - yc) < 1.0:
						ti = 2
					px(im, x, y, SKINL7[ti])
		else:
			elf_ear(im, base, s, 5, 5)
	# клыки у рта (рот — строки 31..33)
	if not goblin and (dir == 0 or dir == 4):
		var mx: int = 40 if dir == 0 else 38
		for xo in [-3, 3]:
			px(im, mx + int(xo), 32 + b, Color("fff8e8"))
			px(im, mx + int(xo), 31 + b, Color("fff8e8"))
			px(im, mx + int(xo) + (1 if xo > 0 else -1), 32 + b, Color("e8dcc0"))
	# бусы из клыков
	if not goblin and dir != 1 and dir != 5:
		var cx: float = 40.0 if dir != 2 else 36.0
		for k2 in range(7):
			var t: float = float(k2) / 6.0
			var p: Vector2 = Vector2(cx - 7.0 + t * 14.0, 40.0 + b + sin(t * PI) * 5.0)
			if dir == 2:
				p.x = cx - 3.0 + t * 6.0
			px(im, int(p.x), int(p.y), Color("5a3a22"))
			px(im, int(p.x), int(p.y) + 1, Color("efe6d0"))
			px(im, int(p.x), int(p.y) + 2, Color("efe6d0") if k2 % 2 == 0 else Color("b02a20"))


func gen_orc_girls() -> void:
	var sh: Array = HAIRL7.duplicate()
	var sw7: Array = WHITE7.duplicate()
	var st: Array = TEAL7.duplicate()
	var sk: Array = SKINL7.duplicate()
	var fw: int = 80
	var fh: int = 160
	var mirror: Dictionary = {2: 3, 4: 6, 5: 7}
	BOUNCE_OVR = 0
	var line_up: Image = new_img(fw * ORC_LOOKS.size(), fh)
	var li: int = 0
	for lk in ORC_LOOKS:
		HAIRL7 = hx(lk[1])
		WHITE7 = hx(lk[2])
		TEAL7 = hx(lk[3])
		SKINL7 = hx(lk[4])
		var goblin: bool = bool(lk[5])
		EYE_OVR = {"I": Color("5a1a0a"), "i": Color("d06020"), "j": Color("ffc060")} if not goblin else {"I": Color("3a4a0a"), "i": Color("c8d030"), "j": Color("fff080")}
		_head_pal()
		NO_CAPE = goblin
		var vs: Image = new_img(fw * 8, fh * 8)
		for vd in [0, 1, 2, 4, 5]:
			for k in range(8):
				var c2: Image = new_img(fw, fh)
				draw_hero10(c2, vd, k)
				orc_extras(c2, vd, k, goblin)
				outline_auto(c2, OUTLINE_CHAR)
				vs.blit_rect(c2, Rect2i(0, 0, fw, fh), Vector2i(k * fw, vd * fh))
				if mirror.has(vd):
					var mc: Image = c2.duplicate()
					mc.flip_x()
					vs.blit_rect(mc, Rect2i(0, 0, fw, fh), Vector2i(k * fw, int(mirror[vd]) * fh))
		save3(vs, String(lk[0]))
		gen_faces10("faces_" + String(lk[0]))
		line_up.blit_rect(vs, Rect2i(4 * fw, 0, fw, fh), Vector2i(li * fw, 0))
		li += 1
	line_up.resize(line_up.get_width() * 3, line_up.get_height() * 3, Image.INTERPOLATE_NEAREST)
	line_up.save_png(ProjectSettings.globalize_path("res://").path_join("../screenshots/orc_lineup.png"))
	EYE_OVR = {}
	NO_CAPE = false
	HAIRL7 = sh
	WHITE7 = sw7
	TEAL7 = st
	SKINL7 = sk
	_head_pal()


# ================================================================== горы дворфов

const DSTONE: Array = ["2e2a2e", "423c40", "585054", "6e666a", "868084", "a09a9c", "bab4b4", "d2cece"]
const BRASS: Array = ["5a3a10", "8a5e1c", "b4842a", "d8a83c", "f0cc60", "fae69a"]
const ALE: Array = ["5a2e08", "8a4a10", "b46a18", "d8902a", "f0b84a"]


func gen_dwarves() -> void:
	gen_dwarf_gate()
	gen_dwarf_tavern()
	gen_ale_kegs()
	gen_ale_table()
	gen_forge()
	gen_mine_cart()
	gen_ore_rock()
	gen_brazier()
	gen_cliff()
	gen_dwarf_girls()
	var items: Array = []
	for nm in ["dwarf_gate", "dwarf_tavern", "ale_kegs", "ale_table", "forge", "mine_cart", "ore_rock", "brazier", "cliff"]:
		items.append([nm, Image.load_from_file(ProjectSettings.globalize_path(OUT + String(nm) + ".png"))])
	_sheet(items, 2, "dwarf_preview.png")


## Скальная масса: гранёные глыбы с тенью слева-сверху светом
func rock_mass(im: Image, r: Rect2i, seed_v: int, peak: float) -> void:
	# скала из гранёных глыб: тон по ячейке, тёмные трещины по границам, свет сверху-слева
	var st: Array = hx(DSTONE)
	var nz: FastNoiseLite = FastNoiseLite.new()
	nz.seed = seed_v
	nz.frequency = 0.016
	var cell: FastNoiseLite = FastNoiseLite.new()
	cell.seed = seed_v + 1
	cell.noise_type = FastNoiseLite.TYPE_CELLULAR
	cell.frequency = 0.045
	cell.cellular_return_type = FastNoiseLite.RETURN_CELL_VALUE
	var edge: FastNoiseLite = FastNoiseLite.new()
	edge.seed = seed_v + 1
	edge.noise_type = FastNoiseLite.TYPE_CELLULAR
	edge.frequency = 0.045
	edge.cellular_return_type = FastNoiseLite.RETURN_DISTANCE2_SUB
	for x in range(r.position.x, r.end.x):
		var u: float = float(x - r.position.x) / float(r.size.x)
		var top: float = r.position.y + (1.0 - sin(u * PI) * peak) * r.size.y * 0.55 + nz.get_noise_1d(float(x)) * 14.0
		for y in range(int(top), r.end.y):
			var cv: float = cell.get_noise_2d(float(x), float(y) * 1.4)
			var ed: float = edge.get_noise_2d(float(x), float(y) * 1.4)
			var v: float = 0.56 + cv * 0.16 - float(y - top) * 0.0010
			# каждая глыба светлее сверху-слева
			var ex: float = edge.get_noise_2d(float(x) - 2.0, float(y) * 1.4 - 2.0)
			if ex < ed:
				v += 0.08
			if ed > -0.9 + 0.08 and ed < -0.82:
				pass
			if y < top + 3.0:
				v += 0.22
			if ed > -0.12:
				v -= 0.26
			px(im, x, y, pick(st, v, x, y))


func gen_dwarf_gate() -> void:
	var W: int = 400
	var H: int = 320
	var im: Image = new_img(W, H)
	var cx: int = W / 2
	var ground: int = H - 10
	rock_mass(im, Rect2i(0, 0, W, ground), 501, 0.9)
	var st: Array = hx(DSTONE)
	# обработанный портал: ступенчатая арка из ровных блоков
	for k in range(3):
		var hw: int = 74 - k * 14
		var top: int = 92 + k * 14
		for y in range(top, ground):
			for x in range(cx - hw, cx + hw):
				var inner: bool = absi(x - cx) < hw - 12 and y > top + 12
				if inner:
					continue
				var row: int = (y - top) / 10
				var v: float = 0.68 - float(k) * 0.08 + (0.12 if posmod(x + row * 7, 20) < 2 else 0.0)
				if posmod(y - top, 10) == 0:
					v -= 0.18
				px(im, x, y, pick(st, v, x, y))
	# сами врата: тяжёлые створки с латунными полосами и рунами
	for y2 in range(146, ground):
		for x2 in range(cx - 32, cx + 32):
			var c: Color = Color("3a2a1e") if absi(x2 - cx) > 1 else Color("1a120c")
			if posmod(y2 - 146, 26) < 4:
				c = hx(BRASS)[2] if posmod(y2 - 146, 26) < 2 else hx(BRASS)[1]
			px(im, x2, y2, c)
	for k2 in range(3):
		var ry: int = 160 + k2 * 26
		for s in [-1, 1]:
			var rx: int = cx + s * 16
			line(im, rx - 3, ry, rx + 3, ry + 8, Color("7ad8ff"))
			line(im, rx + 3, ry, rx - 3, ry + 8, Color("7ad8ff"))
	disc(im, cx - 6, 210, 2.5, hx(BRASS)[4])
	disc(im, cx + 6, 210, 2.5, hx(BRASS)[4])
	# над вратами — резной лик дворфа с бородой
	var fc: Vector2 = Vector2(cx, 112)
	ell(im, fc.x, fc.y, 18, 14, st[6])
	ell(im, fc.x, fc.y + 18, 16, 14, st[5])
	for k3 in range(6):
		line(im, int(fc.x) - 12 + k3 * 5, int(fc.y) + 8, int(fc.x) - 13 + k3 * 5, int(fc.y) + 30, st[3])
	rect(im, int(fc.x) - 10, int(fc.y) - 3, 6, 3, st[1])
	rect(im, int(fc.x) + 4, int(fc.y) - 3, 6, 3, st[1])
	rect(im, int(fc.x) - 14, int(fc.y) - 10, 28, 4, st[4])
	# статуи по бокам: дворф с топором
	for s2 in [-1, 1]:
		var sx: int = cx + s2 * 128
		rect(im, sx - 22, ground - 26, 44, 26, st[4])
		rect(im, sx - 22, ground - 26, 44, 3, st[6])
		blob(im, sx, ground - 60, 18.0, 24.0, st, 4)
		blob(im, sx, ground - 98, 13.0, 13.0, st, 5)
		ell(im, sx, ground - 78, 12, 14, st[6])
		for k4 in range(4):
			line(im, sx - 8 + k4 * 5, ground - 84, sx - 9 + k4 * 5, ground - 66, st[4])
		rect(im, sx - 14, ground - 112, 28, 6, st[5])
		# топор
		thick_line(im, Vector2(sx + s2 * 22, ground - 120), Vector2(sx + s2 * 22, ground - 30), 3.0, st, 0.5)
		for y5 in range(ground - 124, ground - 100):
			var w5: float = 10.0 - absf(float(y5 - (ground - 112))) * 0.4
			for x5 in range(int(sx + s2 * 22), int(sx + s2 * 22 + s2 * w5), s2):
				px(im, x5, y5, st[6] if y5 < ground - 112 else st[5])
	# жилы золота и самоцветы в скале
	rng.seed = 502
	for i in range(30):
		var gx: int = rng.randi_range(10, W - 10)
		var gy: int = rng.randi_range(40, ground - 20)
		if absi(gx - cx) < 90 or a_at(im, gx, gy) < 0.5:
			continue
		var col: Color = [hx(BRASS)[4], Color("e05080"), Color("50c0e0"), hx(BRASS)[3]][i % 4]
		px(im, gx, gy, col)
		px(im, gx + 1, gy, col.darkened(0.3))
		px(im, gx, gy - 1, Color("ffffff") if i % 3 == 0 else col)
	outline_auto(im, 0.4)
	save3(im, "dwarf_gate")


func gen_dwarf_tavern() -> void:
	var W: int = 260
	var H: int = 240
	var im: Image = new_img(W, H)
	var st: Array = hx(DSTONE)
	var cx: int = W / 2
	var ground: int = H - 10
	# каменный первый этаж
	stone_wall(im, Rect2i(24, 150, W - 48, ground - 150), st, 8, 12, 20, Color(st[1]), 0.55)
	# деревянный второй этаж
	planks(im, 30, 92, W - 60, 58, WOOD, true, 9, 0.5, 4)
	for bx in [30, cx - 4, W - 38]:
		planks(im, int(bx), 92, 8, 58, WOOD, true, 8, 0.32, int(bx))
	planks(im, 26, 146, W - 52, 6, WOOD, false, 6, 0.3, 1)
	# крутая крыша из каменной черепицы
	for y in range(20, 96):
		var t: float = float(y - 20) / 76.0
		var hw: float = 30.0 + t * 112.0
		for x in range(int(cx - hw), int(cx + hw) + 1):
			var v: float = 0.6 - (x - cx) / hw * 0.18
			if posmod(y, 6) == 5:
				v -= 0.2
			if posmod(x + (y / 6) * 5, 11) == 0:
				v -= 0.08
			px(im, x, y, pick(st, v, x, y))
	# труба пивоварни с медным колпаком
	rect(im, cx + 50, 6, 16, 50, st[4])
	rect(im, cx + 46, 2, 24, 6, hx(BRASS)[3])
	# окна с тёплым светом
	for wx in [60, W - 76]:
		rect(im, wx - 2, 104, 20, 24, WOOD[1])
		rect(im, wx, 106, 16, 20, Color("f0b050"))
		rect(im, wx + 7, 106, 2, 20, WOOD[1])
		rect(im, wx, 115, 16, 2, WOOD[1])
	for wx2 in [50, W - 70]:
		rect(im, wx2, 170, 22, 26, WOOD[1])
		rect(im, wx2 + 2, 172, 18, 22, Color("f0b050"))
	# дверь — полукруглая, дубовая
	for y2 in range(ground - 54, ground):
		for x2 in range(cx - 18, cx + 18):
			var dy: float = float(y2 - (ground - 36))
			if dy < 0.0 and Vector2(x2 + 0.5 - cx, dy).length() > 18.0:
				continue
			var pl: int = posmod(x2 - cx, 6)
			px(im, x2, y2, hx(BRASS)[2] if posmod(y2, 14) == 0 else pick(WOOD, 0.45 - (0.2 if pl == 0 else 0.0), x2, y2))
	# вывеска — большая кружка эля на кронштейне
	for x3 in range(W - 26, W - 2):
		px(im, x3, 160, Color("2a2a30"))
	var mx: int = W - 14
	rect(im, mx - 9, 166, 18, 22, hx(ALE)[2])
	for y4 in range(166, 188):
		px(im, mx - 9, y4, WOOD[1])
		px(im, mx + 8, y4, WOOD[1])
		if posmod(y4, 7) == 0:
			for x4 in range(mx - 9, mx + 9):
				px(im, x4, y4, hx(BRASS)[2])
	ell(im, mx, 165, 10, 4, Color("fff8e8"))
	disc(im, mx - 5, 162, 3.0, Color("ffffff"))
	for y5 in range(170, 184):
		px(im, mx + 10, y5, WOOD[2])
	outline_auto(im, 0.4)
	save3(im, "dwarf_tavern")


func _keg(im: Image, cx: float, cy: float, r: float) -> void:
	# бочка лёжа: круглое днище с кранчиком
	disc(im, cx, cy, r + 1.0, WOOD[1])
	for y in range(int(cy - r), int(cy + r) + 1):
		for x in range(int(cx - r), int(cx + r) + 1):
			var d: float = Vector2(x + 0.5 - cx, y + 0.5 - cy).length()
			if d > r:
				continue
			var v: float = 0.6 - (y - cy) / r * 0.15 - (x - cx) / r * 0.1
			if absf(d - r * 0.92) < 0.8 or absf(d - r * 0.55) < 0.6:
				v = 0.15
			px(im, x, y, pick(WOOD, v, x, y))
	rect(im, int(cx) - 1, int(cy) + 1, 3, 4, hx(BRASS)[3])


func gen_ale_kegs() -> void:
	var im: Image = new_img(72, 60)
	ell(im, 36, 56, 32, 4, Color(0.1, 0.08, 0.06, 0.35))
	for k in [[14, 44], [36, 44], [58, 44], [25, 25], [47, 25], [36, 8]]:
		_keg(im, float(k[0]), float(k[1]), 10.5)
	outline_auto(im, 0.4)
	save3(im, "ale_kegs")


func gen_ale_table() -> void:
	var im: Image = new_img(76, 50)
	planks(im, 4, 22, 68, 8, WOOD, false, 8, 0.55, 3)
	planks(im, 8, 30, 6, 18, WOOD, true, 6, 0.4, 4)
	planks(im, 62, 30, 6, 18, WOOD, true, 6, 0.4, 5)
	planks(im, 2, 40, 18, 4, WOOD, false, 4, 0.45, 6)
	planks(im, 56, 40, 18, 4, WOOD, false, 4, 0.45, 7)
	for mx in [18, 34, 54]:
		rect(im, int(mx) - 4, 10, 9, 12, hx(ALE)[3])
		rect(im, int(mx) - 4, 10, 1, 12, WOOD[2])
		rect(im, int(mx) + 4, 10, 1, 12, WOOD[2])
		for x in range(int(mx) - 4, int(mx) + 5):
			px(im, x, 15, hx(BRASS)[2])
		ell(im, mx, 10, 5, 2, Color("fff8e8"))
		for y in range(12, 19):
			px(im, int(mx) + 6, y, WOOD[2])
	outline_auto(im, 0.4)
	save3(im, "ale_table")


func gen_forge() -> void:
	var im: Image = new_img(90, 80)
	var st: Array = hx(DSTONE)
	# горн из камня с огнём
	stone_wall(im, Rect2i(4, 34, 46, 42), st, 6, 8, 12, Color(st[1]), 0.55)
	rect(im, 12, 44, 30, 14, Color("2a120a"))
	ell(im, 27, 54, 12, 4, Color("ff7a20"))
	ell(im, 27, 53, 7, 2, Color("ffd060"))
	rect(im, 14, 6, 26, 30, st[3])
	rect(im, 16, 4, 22, 4, st[5])
	# наковальня
	for y in range(56, 76):
		var w: float = 6.0 if y > 64 else 14.0 - float(64 - y) * 0.3
		if y < 60:
			w = 16.0
		for x in range(int(70 - w), int(70 + w)):
			px(im, x, y, IRON[4] if y < 58 else (IRON[3] if x < 70 else IRON[2]))
	# молот, прислонённый к наковальне
	thick_line(im, Vector2(56, 74), Vector2(62, 48), 2.0, hx(LOG), 0.6)
	rect(im, 58, 42, 10, 7, IRON[3])
	outline_auto(im, 0.4)
	save3(im, "forge")


func gen_mine_cart() -> void:
	var im: Image = new_img(60, 46)
	for y in range(14, 36):
		var w: float = 24.0 - float(y - 14) * 0.25
		for x in range(int(30 - w), int(30 + w)):
			var c: Color = IRON[3] if x < 30 else IRON[2]
			if y == 14 or posmod(x, 12) == 0:
				c = IRON[1]
			px(im, x, y, c)
	# руда с золотом и самоцветами горкой
	for k in range(12):
		var ox: float = 12.0 + h01(k, 1, 4) * 36.0
		var oy: float = 12.0 - sin((ox - 12.0) / 36.0 * PI) * 7.0 + h01(k, 2, 4) * 3.0
		ball(im, ox, oy, 4.0, 3.2, STONE, 0.3)
		if k % 3 == 0:
			px(im, int(ox), int(oy) - 1, hx(BRASS)[4])
			px(im, int(ox) + 1, int(oy), hx(BRASS)[3])
		elif k % 3 == 1:
			px(im, int(ox), int(oy) - 1, Color("e05080"))
	for wx in [14, 46]:
		disc(im, wx, 38, 6.0, IRON[1])
		disc(im, wx, 38, 3.0, IRON[3])
	outline_auto(im, 0.4)
	save3(im, "mine_cart")


func gen_ore_rock() -> void:
	var im: Image = new_img(52, 42)
	rock_mass(im, Rect2i(2, 2, 48, 38), 77, 1.0)
	for k in range(10):
		var x: int = 8 + int(h01(k, 3, 6) * 36.0)
		var y: int = 18 + int(h01(k, 4, 6) * 16.0)
		if a_at(im, x, y) > 0.5:
			var c: Color = hx(BRASS)[4] if k % 2 == 0 else Color("50c0e0")
			px(im, x, y, c)
			px(im, x + 1, y, c.darkened(0.3))
			px(im, x, y - 1, Color("ffffff"))
	outline_auto(im, 0.4)
	save3(im, "ore_rock")


func gen_brazier() -> void:
	var im: Image = new_img(32, 48)
	var st: Array = hx(DSTONE)
	rect(im, 12, 18, 8, 28, st[4])
	rect(im, 12, 18, 3, 28, st[6])
	rect(im, 8, 42, 16, 5, st[3])
	ell(im, 16, 16, 13, 5, st[5])
	ell(im, 16, 14, 10, 3, Color("2a120a"))
	ell(im, 16, 13, 7, 2, Color("ff8a2a"))
	outline_auto(im, 0.4)
	save3(im, "brazier")


func gen_cliff() -> void:
	var im: Image = new_img(240, 170)
	rock_mass(im, Rect2i(0, 0, 240, 166), 909, 1.0)
	# снег на вершине
	for x in range(240):
		for y in range(170):
			var c: Color = im.get_pixel(x, y)
			if c.a > 0.5 and a_at(im, x, y - 3) < 0.5 and y < 90:
				for j in range(4):
					px(im, x, y + j, Color("f4f6fa") if j < 2 else Color("cfd6e2"))
				break
	outline_auto(im, 0.4)
	save3(im, "cliff")


# ---------------------------------------------------------------- дворфийки

const DWARF_LOOKS: Array = [
	# имя, волосы, одежда, фартук/плащ, в руках
	["dwarf_hilda", ["4a0e0a", "6e1a12", "922a1a", "b43c24", "d05a34", "e67e4a", "f6a46a"], ["2a3a4a", "3a4e62", "4e667c", "668098", "829cb2", "a2b8ca", "c4d4e0"], ["3a2216", "54321e", "6e4428", "8a5a36", "a67448", "c0905e", "d8ae7c"], "mug"],
	["dwarf_tova", ["2e1a12", "46281a", "603a24", "7a4e32", "966844", "b28860", "ccaa84"], ["5a1a22", "7a2430", "9c3240", "bc4652", "d65e68", "e8828a", "f4aab0"], ["6a5a4a", "907e66", "b4a084", "d2c0a0", "e6d8bc", "f2e8d4", "fbf6ea"], "two_mugs"],
	["dwarf_greta", ["6a4a1a", "8e6a28", "b08c3c", "cca858", "e2c47a", "f0dca0", "faf0cc"], ["2a2a2e", "3e3e44", "56565e", "6e6e78", "8a8a94", "a6a6b0", "c4c4cc"], ["3a2216", "54321e", "6e4428", "8a5a36", "a67448", "c0905e", "d8ae7c"], "hammer"],
	["dwarf_berta", ["8a8a90", "a6a6ac", "c0c0c6", "d6d6dc", "e8e8ec", "f4f4f6", "ffffff"], ["3a2a4a", "4e3a62", "644e7c", "7e6698", "9a82b2", "b6a2ca", "d2c4e0"], ["3a2216", "54321e", "6e4428", "8a5a36", "a67448", "c0905e", "d8ae7c"], "two_mugs"],
	["dwarf_ingrid", ["4a1a0a", "74300e", "9e4a14", "c8661e", "e0862e", "f0a84a", "fac87a"], ["3a3a2a", "54543c", "6e6e50", "8a8a66", "a6a680", "c2c29e", "dcdcbc"], ["2a2a2e", "3e3e44", "56565e", "6e6e78", "8a8a94", "a6a6b0", "c4c4cc"], "hammer"],
]


func dwarf_braid(im: Image, a: Vector2, b2: Vector2) -> void:
	var n: int = int(a.distance_to(b2) / 2.4) + 1
	for i in range(n):
		var t: float = float(i) / float(maxi(1, n - 1))
		var p: Vector2 = a.lerp(b2, t)
		blob(im, p.x + (0.6 if i % 2 == 0 else -0.6), p.y, lerpf(2.8, 2.0, t), 1.8, HAIRL7, 4 if i % 2 == 0 else 3)
		if i == n / 2 or i == n - 2:
			for x in range(int(p.x) - 2, int(p.x) + 3):
				px(im, x, int(p.y), hx(BRASS)[4])
				px(im, x, int(p.y) + 1, hx(BRASS)[2])


func _mug(im: Image, c: Vector2) -> void:
	rect(im, int(c.x) - 4, int(c.y) - 5, 8, 10, hx(ALE)[3])
	rect(im, int(c.x) - 4, int(c.y) - 5, 1, 10, WOOD[2])
	rect(im, int(c.x) + 3, int(c.y) - 5, 1, 10, WOOD[2])
	for x in range(int(c.x) - 4, int(c.x) + 4):
		px(im, x, int(c.y), hx(BRASS)[2])
	ell(im, c.x, c.y - 5, 5, 2, Color("fff8e8"))
	px(im, int(c.x) - 2, int(c.y) - 7, Color("ffffff"))
	for y in range(int(c.y) - 3, int(c.y) + 3):
		px(im, int(c.x) + 5, y, WOOD[2])


func dwarf_extras(im: Image, dir: int, f: int, item: String) -> void:
	var b: int = -1 if (f == 1 or f == 3 or f == 6 or f == 7) else 0
	var cx: float = 40.0
	# косы спереди (в передних ракурсах) с золотыми кольцами
	if dir == 0:
		dwarf_braid(im, Vector2(cx - 10, 30 + b), Vector2(cx - 12, 70 + b))
		dwarf_braid(im, Vector2(cx + 10, 30 + b), Vector2(cx + 12, 70 + b))
	elif dir == 4:
		dwarf_braid(im, Vector2(cx + 9, 30 + b), Vector2(cx + 11, 70 + b))
	elif dir == 2:
		dwarf_braid(im, Vector2(cx + 2, 30 + b), Vector2(cx + 1, 66 + b))
	# что в руках
	var hand: Vector2 = Vector2(cx + 15.4, 88 + b)
	var hand2: Vector2 = Vector2(cx - 15.4, 88 + b)
	if dir == 2:
		hand = Vector2(cx - 1, 88 + b)
	elif dir == 4:
		hand = Vector2(cx + 14.6, 88 + b)
		hand2 = Vector2(cx - 11.8, 88 + b)
	if dir == 1 or dir == 5:
		return
	match item:
		"mug":
			_mug(im, hand + Vector2(2, -2))
		"two_mugs":
			_mug(im, hand + Vector2(2, -2))
			if dir != 2:
				_mug(im, hand2 + Vector2(-2, -2))
		"hammer":
			thick_line(im, hand + Vector2(0, 4), hand + Vector2(4, -30), 2.0, hx(LOG), 0.6)
			var hd: Vector2 = hand + Vector2(4, -32)
			rect(im, int(hd.x) - 6, int(hd.y) - 4, 13, 8, IRON[3])
			rect(im, int(hd.x) - 6, int(hd.y) - 4, 13, 2, IRON[4])


func gen_dwarf_girls() -> void:
	var sh: Array = HAIRL7.duplicate()
	var sw7: Array = WHITE7.duplicate()
	var st: Array = TEAL7.duplicate()
	var fw: int = 80
	var fh: int = 160
	var mirror: Dictionary = {2: 3, 4: 6, 5: 7}
	BOUNCE_OVR = 0
	var line_up: Image = new_img(fw * DWARF_LOOKS.size(), fh)
	var li: int = 0
	for lk in DWARF_LOOKS:
		HAIRL7 = hx(lk[1])
		WHITE7 = hx(lk[2])
		TEAL7 = hx(lk[3])
		EYE_OVR = {"I": Color("2a3a5a"), "i": Color("4a7ab8"), "j": Color("a8d0ff")}
		_head_pal()
		NO_CAPE = true
		var vs: Image = new_img(fw * 8, fh * 8)
		for vd in [0, 1, 2, 4, 5]:
			for k in range(8):
				var c2: Image = new_img(fw, fh)
				draw_hero10(c2, vd, k)
				dwarf_extras(c2, vd, k, String(lk[4]))
				outline_auto(c2, OUTLINE_CHAR)
				vs.blit_rect(c2, Rect2i(0, 0, fw, fh), Vector2i(k * fw, vd * fh))
				if mirror.has(vd):
					var mc: Image = c2.duplicate()
					mc.flip_x()
					vs.blit_rect(mc, Rect2i(0, 0, fw, fh), Vector2i(k * fw, int(mirror[vd]) * fh))
		save3(vs, String(lk[0]))
		gen_faces10("faces_" + String(lk[0]))
		line_up.blit_rect(vs, Rect2i(4 * fw, 0, fw, fh), Vector2i(li * fw, 0))
		li += 1
	line_up.resize(line_up.get_width() * 3, line_up.get_height() * 3, Image.INTERPOLATE_NEAREST)
	line_up.save_png(ProjectSettings.globalize_path("res://").path_join("../screenshots/dwarf_lineup.png"))
	EYE_OVR = {}
	NO_CAPE = false
	HAIRL7 = sh
	WHITE7 = sw7
	TEAL7 = st
	_head_pal()


# ================================================================== города: дома всех народов, лавки, лидеры

func gen_towns() -> void:
	_palettes3()
	var plaster: Array = hx(["b8a27a", "c9b48c", "d8c59e", "e5d5b2", "efe2c6", "f7efdc"])
	var gstone: Array = hx(["2e2638", "3c3248", "4c425a", "60566e", "786e86", "948aa2"])
	var mstone: Array = hx(["a2a2b6", "bcbccc", "d2d2de", "e6e6ee", "f0f0f6", "fafafe"])
	var dstone: Array = hx(["585054", "6e666a", "868084", "a09a9c", "bab4b4", "d2cece"])
	var red_roof: Array = hx(["3e1416", "62201e", "862c26", "a63a2e", "c2503a", "d86c4c", "eb9068", "f6b48c"])
	var brown_roof: Array = hx(["2e1c10", "462c18", "5e3c22", "7a502e", "94683e", "ae8454", "c8a272", "dcc09a"])
	var slate: Array = hx(["0e0c1a", "181628", "22203a", "2e2c4c", "3c3a60", "504e78", "6a6890", "8a88aa"])
	var blue_roof: Array = hx(["14183a", "1e2652", "2a386e", "3a4e8e", "5068aa", "6e88c4", "98b0dc", "bcd0ee"])
	var stone_roof: Array = hx(["2e2a2e", "423c40", "585054", "6e666a", "868084", "a09a9c", "bab4b4", "d2cece"])
	# кошки: двухэтажные домики с ушками и ратуша королевы
	gen_town_house("cat_house_e", 210, 2, hx(["c09468", "d0a87c", "dcbc92", "e8cea8", "f2dec0", "faeedc"]), hx(["2e1a36", "42244c", "5a3264", "744480", "8e5c9a", "a878b2", "c49ad0", "e0c2e8"]), "hip", "ears", 21)
	gen_town_house("cat_house_f", 190, 1, hx(["9eae96", "b2c0a8", "c4d2b8", "d6e2ca", "e6eedc", "f4f8ee"]), red_roof, "hip", "ears", 22)
	gen_town_house("cat_hall", 300, 2, plaster, hx(["4a1a3a", "6a2452", "8a3068", "aa4282", "c45c9a", "d87cb2", "eaa2ca", "f6c8e0"]), "hip", "ears_crown", 23)
	# готика: узкие тёмные дома с крутыми крышами
	gen_town_house("goth_house_a", 150, 2, gstone, slate, "steep", "lancet", 31)
	gen_town_house("goth_house_b", 170, 2, gstone, hx(["2a0a14", "44101e", "62182a", "822438", "a23448", "c04a5e", "d86a7a", "ea92a0"]), "steep", "lancet", 32)
	# рыцари: фахверковые дома
	gen_town_house("town_house_a", 200, 2, plaster, red_roof, "gable", "timber", 41)
	gen_town_house("town_house_b", 170, 2, hx(["c8b49a", "d6c4aa", "e2d2bc", "ece0cc", "f4ecdc", "faf6ec"]), brown_roof, "gable", "timber", 42)
	gen_town_house("town_house_c", 220, 1, plaster, hx(["5e3a14", "7a4c18", "96621f", "b07a28", "c89433", "dcac42", "ebc25a", "f4d77e"]), "hip", "timber", 43)
	# маги: белые дома с синими крышами и звёздами
	gen_town_house("mage_house_a", 170, 2, mstone, blue_roof, "steep", "star", 51)
	gen_town_house("mage_house_b", 190, 1, mstone, hx(["2a1a4a", "3e2a6a", "543a8a", "6c50a8", "8a6cc2", "a88cd6", "c8b0ea", "e2d4f6"]), "hip", "star", 52)
	# дворфы: приземистые каменные дома
	gen_town_house("dwarf_house_a", 200, 1, dstone, stone_roof, "gable", "dwarf", 61)
	gen_town_house("dwarf_house_b", 170, 1, dstone, brown_roof, "hip", "dwarf", 62)
	# эльфы и гоблины — ещё варианты, орки — круглая хижина, пауки — шёлковый кокон
	gen_elf_house_b()
	gen_goblin_hut("goblin_hut_c", 63)
	gen_orc_hut()
	gen_cocoon_house()
	for st in [["stall_red", "c8303a"], ["stall_blue", "3a5ca8"], ["stall_purple", "6a3a8a"], ["stall_green", "3a8a5a"], ["stall_brown", "8a5a2a"], ["stall_silk", "b8b0d0"]]:
		gen_market_stall(String(st[0]), Color(String(st[1])))
	gen_leaders()
	gen_cobble()
	var items: Array = []
	for nm in ["cat_house_e", "cat_house_f", "cat_hall", "goth_house_a", "goth_house_b", "town_house_a", "town_house_b", "town_house_c", "mage_house_a", "mage_house_b", "dwarf_house_a", "dwarf_house_b", "elf_house_b", "goblin_hut_c", "orc_hut", "cocoon_house", "stall_red", "stall_silk"]:
		items.append([nm, Image.load_from_file(ProjectSettings.globalize_path(OUT + String(nm) + ".png"))])
	_sheet(items, 2, "town_preview.png")


## Общий дом: W ширина, этажей 1-2, стены (ramp), крыша (ramp) формы hip/gable/steep, стиль окон/украшений
func gen_town_house(name: String, W: int, floors: int, wall: Array, roof: Array, shape: String, style: String, seed_v: int) -> void:
	rng.seed = seed_v
	var wall_h: int = 64 if floors == 1 else 116
	var roof_h: int = 70 if shape != "steep" else 120
	var H: int = wall_h + roof_h + 40
	var im: Image = new_img(W, H)
	var cx: int = W / 2
	var ground: int = H - 8
	var wall_bot: int = ground - 10
	var wall_top: int = wall_bot - wall_h
	var x0: int = 16
	var x1: int = W - 16
	var npl: FastNoiseLite = FastNoiseLite.new()
	npl.seed = seed_v
	npl.frequency = 0.09
	# стены: штукатурка или камень
	if style in ["lancet", "dwarf", "star"]:
		stone_wall(im, Rect2i(x0, wall_top, x1 - x0, wall_h), wall, 7, 9, 16, Color(wall[0]), 0.55)
	else:
		for y in range(wall_top, wall_bot):
			for x in range(x0, x1):
				var v: float = 0.62 + npl.get_noise_2d(x, y) * 0.10 + (h01(x, y, 2) - 0.5) * 0.06
				if y < wall_top + 12:
					v -= 0.35 * pow(1.0 - (y - wall_top) / 12.0, 1.4)
				px(im, x, y, pick(wall, v, x, y))
	# фахверк или пояса
	if style in ["timber", "ears", "ears_crown"]:
		var posts: int = maxi(3, W / 50)
		for k in range(posts + 1):
			var bx: int = x0 + int(float(x1 - x0 - 7) * float(k) / float(posts))
			planks(im, bx, wall_top, 7, wall_h, WOOD, true, 7, 0.42, bx)
		planks(im, x0, wall_top, x1 - x0, 6, WOOD, false, 6, 0.40, 1)
		if floors == 2:
			planks(im, x0, wall_top + wall_h / 2 - 3, x1 - x0, 6, WOOD, false, 6, 0.40, 2)
			if style == "timber":
				thick_line(im, Vector2(x0 + 10, wall_top + 8), Vector2(cx - 30, wall_top + wall_h / 2 - 4), 3.5, WOOD, 0.4)
				thick_line(im, Vector2(x1 - 10, wall_top + 8), Vector2(cx + 30, wall_top + wall_h / 2 - 4), 3.5, WOOD, 0.4)
	elif style == "star":
		for x2 in range(x0, x1):
			px(im, x2, wall_top + 2, Color("e8c860"))
			px(im, x2, wall_top + 3, Color("b8963a"))
	# фундамент
	stone_wall(im, Rect2i(x0 - 4, wall_bot, x1 - x0 + 8, 10), STONE, 5, 8, 14, Color("39353a"), 0.5)
	# окна по этажам
	var cols: int = maxi(2, (x1 - x0) / 60)
	for fl in range(floors):
		var wy: int = wall_bot - 44 - fl * (wall_h / 2) if floors == 2 else wall_top + 18
		if floors == 2 and fl == 0:
			wy = wall_bot - 44
		for k2 in range(cols):
			var wx: int = x0 + int(float(x1 - x0) * (float(k2) + 0.5) / float(cols))
			if fl == 0 and absi(wx - cx) < 30:
				continue
			_house_window(im, wx, wy, style, roof)
	# дверь
	var dw: int = 12
	var dtop: int = wall_bot - 40
	for y3 in range(dtop - 2, wall_bot):
		for x3 in range(cx - dw - 2, cx + dw + 2):
			var dy: float = float(y3 - (dtop + dw))
			if style == "lancet" and dy < 0.0:
				var w: float = (dw + 2.0) * (1.0 - pow((dtop + dw - y3) / float(dw + 2), 1.6))
				if absf(x3 + 0.5 - cx) > w:
					continue
			elif dy < 0.0 and Vector2(x3 + 0.5 - cx, dy).length() > dw + 2:
				continue
			var rim: bool = absf(x3 + 0.5 - cx) > dw
			if not rim and dy < 0.0 and style != "lancet":
				rim = Vector2(x3 + 0.5 - cx, dy).length() > dw
			var pl: int = posmod(x3 - cx, 6)
			px(im, x3, y3, WOOD[1] if rim else pick(WOOD, 0.48 - (0.2 if pl == 0 else 0.0) - float(y3 - dtop) * 0.002, x3, y3))
	disc(im, cx + 6, dtop + 24, 1.3, GOLD[4])
	rect(im, cx - dw - 4, wall_bot, dw * 2 + 8, 4, STONE[4])
	# крыша
	var top_y: int = wall_top + 8 - roof_h
	for y4 in range(top_y, wall_top + 8):
		var t: float = float(y4 - top_y) / float(wall_top + 8 - top_y)
		var hw: float
		match shape:
			"steep":
				hw = 6.0 + t * (W / 2.0 - 2.0)
			"gable":
				hw = (W / 2.0 - 2.0) * (0.25 + 0.75 * t)
			_:
				hw = (W / 2.0 - 2.0) * (0.42 + 0.58 * t)
		for x4 in range(int(cx - hw), int(cx + hw) + 1):
			var ly: float = fposmod(float(y4 - top_y), 8.0)
			var tx: float = fposmod(float(x4) + (5.0 if int((y4 - top_y) / 8) % 2 == 1 else 0.0), 10.0)
			var v4: float = 0.78 - ly / 8.0 * 0.3 - (x4 - cx) / hw * 0.1 + (h01(int(float(x4) / 10.0), int((y4 - top_y) / 8), seed_v) - 0.5) * 0.12
			if ly > 6.4 - pow(absf(tx - 5.0) / 5.0, 2.0) * 2.0:
				v4 -= 0.3
			if y4 > wall_top + 5:
				v4 -= 0.25
			px(im, x4, y4, pick(roof, v4, x4, y4))
	# конёк
	var ridge_w: int = 6 if shape == "steep" else int((W / 2.0 - 2.0) * (0.42 if shape == "hip" else 0.25))
	for x5 in range(cx - ridge_w, cx + ridge_w + 1):
		for y5 in range(top_y - 3, top_y + 1):
			px(im, x5, y5, pick(roof, 0.5 - float(y5 - top_y + 3) * 0.06, x5, y5))
	# труба
	if style in ["timber", "dwarf", "lancet"]:
		var chx: int = cx + int(W * 0.22)
		var chy: int = top_y + int(roof_h * 0.35)
		stone_wall(im, Rect2i(chx - 7, chy - 26, 14, 28), STONE, 5, 5, 8, Color("39353a"), 0.45)
		rect(im, chx - 9, chy - 28, 18, 3, STONE[5])
	# особые украшения
	match style:
		"ears", "ears_crown":
			var pinkr: Array = hx(["b85a6a", "d8808c", "f0a8b0", "fccad0"])
			for s2 in [-1, 1]:
				var a0: Vector2 = Vector2(cx + s2 * (ridge_w - 22), top_y - 1.0)
				var b0: Vector2 = Vector2(cx + s2 * (ridge_w + 4), top_y + 4.0)
				var tp: Vector2 = Vector2(cx + s2 * (ridge_w + 2), top_y - 28.0)
				tri(im, a0, b0, tp, func(x: int, y: int, _u: float) -> Color: return pick(roof, 0.62, x, y))
				var m2: Vector2 = (a0 + b0) / 2.0
				tri(im, a0.lerp(m2, 0.38) + Vector2(0, -2), b0.lerp(m2, 0.38) + Vector2(0, -2), tp.lerp(m2, 0.3), func(_x: int, _y: int, _u: float) -> Color: return pinkr[2])
			if style == "ears_crown":
				# золотая корона на коньке и розовые флажки
				var cy0: int = top_y - 18
				rect(im, cx - 12, cy0 + 8, 25, 7, GOLD[3])
				for k6 in range(4):
					var sx: int = cx - 12 + k6 * 8
					tri(im, Vector2(sx, cy0 + 9), Vector2(sx + 6, cy0 + 9), Vector2(sx + 3, cy0), func(_x: int, _y: int, u: float) -> Color: return GOLD[4] if u < 0.5 else GOLD[3])
				disc(im, cx, cy0 + 11, 2.0, Color("e04070"))
		"lancet":
			# кованый шпиль-флюгер
			for y6 in range(top_y - 18, top_y):
				px(im, cx, y6, IRON[2])
			px(im, cx - 2, top_y - 12, IRON[2])
			px(im, cx + 2, top_y - 12, IRON[2])
		"star":
			for k7 in range(6):
				var sx2: int = cx + int(rng.randf_range(-W * 0.25, W * 0.25))
				var sy2: int = top_y + int(rng.randf_range(roof_h * 0.3, roof_h * 0.8))
				if a_at(im, sx2, sy2) > 0.5:
					px(im, sx2, sy2, Color("fff0a0"))
					px(im, sx2 + 1, sy2, Color("e8c860"))
					px(im, sx2, sy2 + 1, Color("e8c860"))
			for y8 in range(top_y - 14, top_y):
				px(im, cx, y8, Color("c8a040"))
			disc(im, cx, top_y - 16, 2.5, Color("a8d8ff"))
		"dwarf":
			# латунный щит-герб над дверью
			disc(im, cx, dtop - 10, 6.0, GOLD[2])
			disc(im, cx, dtop - 10, 4.0, Color("8a2a20"))
			rect(im, cx - 1, dtop - 14, 2, 8, GOLD[4])
	# плющ и цветы у стен (не у дворфов и готики)
	if style in ["timber", "ears", "ears_crown", "star"]:
		draw_ivy(im, x0 + 6, wall_bot + 2, 30 + rng.randi_range(0, 20), 0.8)
	outline_auto(im, 0.42)
	save3(im, name)


func _house_window(im: Image, wx: int, wy: int, style: String, roof: Array) -> void:
	var glass: Array = GLASS
	if style == "lancet":
		for y in range(wy - 4, wy + 26):
			var w: float = 7.0
			if y < wy + 4:
				w = 7.0 * (1.0 - pow(float(wy + 4 - y) / 8.0, 1.6))
			for x in range(int(wx - w), int(wx + w) + 1):
				var edge: bool = absf(x + 0.5 - wx) > w - 1.5
				px(im, x, y, Color("3a3040") if edge else pick(glass, 0.3 + float(y - wy) / 30.0 * 0.5, x, y))
		rect(im, wx, wy, 1, 26, Color("3a3040"))
		return
	rect(im, wx - 10, wy - 2, 20, 26, WOOD[1])
	for y2 in range(wy, wy + 22):
		for x2 in range(wx - 8, wx + 8):
			px(im, x2, y2, pick(glass, 0.3 + float(y2 - wy) / 22.0 * 0.5 + (0.15 if (x2 + y2) % 11 == 0 else 0.0), x2, y2))
	rect(im, wx - 1, wy, 2, 22, WOOD[1])
	rect(im, wx - 8, wy + 10, 16, 2, WOOD[1])
	if style in ["ears", "ears_crown", "timber"]:
		# ставни цвета крыши и ящик с цветами
		for sx in [wx - 17, wx + 10]:
			for y3 in range(wy - 2, wy + 24):
				for x3 in range(int(sx), int(sx) + 7):
					px(im, x3, y3, pick(roof, 0.55 + (0.15 if posmod(x3 - int(sx), 3) == 0 else 0.0), x3, y3))
		planks(im, wx - 11, wy + 23, 22, 4, WOOD, false, 4, 0.4, wx)
		for k in range(4):
			flower5(im, wx - 8 + k * 5, wy + 21, [hx(["d87a98", "f2a2bc", "fcd2e0"]), hx(["d8d0c0", "f6f0e4", "ffffff"])][k % 2], Color("f6d24a"))


func gen_elf_house_b() -> void:
	rng.seed = 929
	var W: int = 160
	var H: int = 236
	var im: Image = new_img(W, H)
	var cx: float = 80.0
	var base: int = H - 8
	draw_trunk3(im, cx, 122, base, 20.0, 929)
	leaf_canopy(im, tree_clumps(cx, 96.0, 60.0), L7_BLOSSOM, 929, 6.4, 4.6, 3.4, 0.55, Callable(), [])
	for y in range(base - 44, base - 4):
		for x in range(int(cx) - 11, int(cx) + 12):
			var dy: float = float(y - (base - 33))
			if dy < 0.0 and Vector2(x + 0.5 - cx, dy).length() > 11.0:
				continue
			var rim: bool = (dy < 0.0 and Vector2(x + 0.5 - cx, dy).length() > 9.0) or absf(x + 0.5 - cx) > 9.0
			px(im, x, y, WOOD[5] if rim else pick(hx(["6a3a5a", "8a4a72", "a8608a", "c47aa2", "dc9ab8"]), 0.5 - (0.2 if posmod(x, 5) == 0 else 0.0), x, y))
	disc(im, cx + 12, 160, 6.0, WOOD[5])
	disc(im, cx + 12, 160, 4.5, Color("ffd890"))
	glow_orb(im, int(cx) - 26, 132, 2.5, 7)
	glow_orb(im, int(cx) + 30, 128, 2.5, 5)
	clean_specks(im)
	outline_auto(im, 0.45)
	shadow(im, cx + 2.0, base + 2.0, 56.0, 6.0, 0.16)
	save3(im, "elf_house_b")


func gen_orc_hut() -> void:
	var im: Image = new_img(130, 120)
	var cx: int = 65
	var hd: Array = hx(HIDE)
	# круглая плетёная стена
	for y in range(64, 112):
		for x in range(14, 116):
			var u: float = (x - 14) / 101.0
			var v: float = 0.6 - absf(u - 0.4) * 0.5 + (0.12 if posmod(x + (y / 4) * 3, 6) < 2 else 0.0)
			px(im, x, y, pick(hx(LOG), v, x, y))
	# крыша-купол из шкур
	for y2 in range(14, 70):
		var t: float = float(y2 - 14) / 56.0
		var hw: float = 60.0 * sqrt(t) + 2.0
		for x2 in range(int(cx - hw), int(cx + hw) + 1):
			var v2: float = 0.7 - (x2 - cx) / hw * 0.25 - t * 0.1
			if posmod(x2 - cx + 60, 24) == 0:
				v2 -= 0.2
			px(im, x2, y2, pick(hd, v2, x2, y2))
	for x3 in range(cx - 62, cx + 63):
		for j in range(3 + posmod(x3, 2)):
			px(im, x3, 68 + j, hd[1])
	# вход и рога над ним
	for y4 in range(80, 112):
		for x4 in range(cx - 12, cx + 13):
			var dy: float = float(y4 - 92)
			if dy < 0.0 and Vector2(x4 + 0.5 - cx, dy).length() > 12.0:
				continue
			px(im, x4, y4, Color("1e140c"))
	for s in [-1, 1]:
		for k in range(8):
			var tt: float = float(k) / 7.0
			disc(im, cx + s * (6 + tt * 10.0), 76 - sin(tt * PI * 0.8) * 8.0, 2.0 - tt, Color("e8dcc0"))
	thick_line(im, Vector2(cx, 16), Vector2(cx - 4, 2), 2.0, hx(LOG), 0.6)
	thick_line(im, Vector2(cx, 16), Vector2(cx + 5, 3), 2.0, hx(LOG), 0.5)
	outline_auto(im, 0.4)
	save3(im, "orc_hut")


func gen_cocoon_house() -> void:
	var W: int = 110
	var H: int = 120
	var im: Image = new_img(W, H)
	var silk: Array = hx(SILK)
	var c: Vector2 = Vector2(55, 80)
	for k in range(4):
		thread(im, Vector2(25 + k * 20, 0), Vector2(40 + k * 10, 40), Color(0.93, 0.94, 1.0, 0.7))
	for y in range(int(c.y) - 44, int(c.y) + 32):
		for x in range(6, W - 6):
			var dx: float = (x + 0.5 - c.x) / 46.0
			var dy: float = (y + 0.5 - c.y) / (44.0 if y < c.y else 32.0)
			var d2: float = dx * dx + dy * dy
			if d2 > 1.0:
				continue
			var l: float = Vector3(dx, dy, sqrt(maxf(0.0, 1.0 - d2))).normalized().dot(Vector3(-0.5, -0.7, 0.55).normalized())
			var v: float = 0.45 + l * 0.42
			if fposmod(float(x + y) * 0.5, 4.0) < 0.6 or fposmod(float(x - y) * 0.5, 4.0) < 0.6:
				v += 0.1
			if d2 > 0.9:
				v -= 0.25
			px(im, x, y, pick(silk, v, x, y))
	var dc: Vector2 = Vector2(55, 96)
	for y2 in range(int(dc.y) - 14, int(dc.y) + 16):
		for x2 in range(int(dc.x) - 13, int(dc.x) + 14):
			var dd: float = Vector2((x2 + 0.5 - dc.x) / 12.0, (y2 + 0.5 - dc.y) / 14.0).length()
			if dd > 1.0 or y2 > 110:
				continue
			px(im, x2, y2, silk[1] if dd > 0.84 else Color("2a1a3a").lerp(Color("f2b866"), clampf(1.0 - dd, 0.0, 1.0)))
	disc(im, 30, 66, 5.0, silk[1])
	disc(im, 30, 66, 3.8, Color("f0c070"))
	outline_auto(im, 0.35)
	save3(im, "cocoon_house")


func gen_market_stall(name: String, col: Color) -> void:
	var im: Image = new_img(96, 84)
	for sx in [8, 84]:
		planks(im, int(sx), 22, 4, 60, WOOD, true, 4, 0.45, int(sx))
	planks(im, 4, 52, 88, 26, WOOD, false, 6, 0.42, 3)
	for y in range(8, 30):
		var t: float = float(y - 8) / 22.0
		for x in range(4, 92):
			var stripe: int = int(floor((x - 4) / 88.0 * 10.0))
			var base: Color = col if stripe % 2 == 0 else Color("fbf2ee")
			if y > 26 and posmod(x, 9) > 5:
				continue
			px(im, x, y, base.darkened(t * 0.15))
	for x2 in range(4, 92):
		px(im, x2, 8, col.darkened(0.35))
	# товары: корзинки, кувшины, хлебцы
	for k in range(4):
		var bx: int = 14 + k * 18
		ell(im, bx, 48, 7, 3.5, hx(["7a5228", "9a6c36", "b88a4a"])[k % 3])
		ell(im, bx, 46, 5, 2, [Color("d8503a"), Color("e8c84a"), Color("8ac85a"), Color("e09a48")][k])
	rect(im, 76, 38, 6, 10, Color("c8d4e0"))
	rect(im, 77, 36, 4, 2, Color("8a6a3a"))
	outline_auto(im, 0.4)
	save3(im, name)


# ---------------------------------------------------------------- лидеры

## Корона на голове. style: gold / tiara / circlet / bone / tin
func crown(im: Image, dir: int, f: int, style: String) -> void:
	var b: int = -1 if (f == 1 or f == 3 or f == 6 or f == 7) else 0
	var x0: int = 31 if dir != 2 else 32
	var x1: int = 49 if dir != 2 else 46
	if dir == 4 or dir == 5:
		x0 = 30
		x1 = 48
	var y: int = 7 + b
	var gold: Array = GOLD
	match style:
		"gold", "tin":
			var g: Array = gold if style == "gold" else hx(["4a4a54", "6a6a74", "8a8a94", "a8a8b2", "c4c4cc", "e0e0e6"])
			rect(im, x0, y, x1 - x0, 4, g[3])
			rect(im, x0, y + 3, x1 - x0, 1, g[1])
			var n: int = 4
			for k in range(n + 1):
				var sx: int = x0 + int(float(x1 - x0 - 1) * float(k) / float(n))
				for j in range(5):
					var w: int = maxi(0, 2 - j / 2)
					for xx in range(sx - w, sx + w + 1):
						px(im, xx, y - j, g[4] if xx <= sx else g[2])
				px(im, sx, y - 5, g[5])
			disc(im, (x0 + x1) / 2.0, y + 1.5, 1.6, Color("e04070") if style == "gold" else Color("50c0e0"))
		"tiara":
			for x in range(x0 + 1, x1 - 1):
				var hgt: int = int(round(4.0 * sin(float(x - x0) / float(x1 - x0) * PI)))
				px(im, x, y + 2 - hgt / 2, Color("e8ecf4"))
				px(im, x, y + 3 - hgt / 2, Color("b8c0d0"))
			disc(im, (x0 + x1) / 2.0, y - 1, 1.8, Color("7ad8ff"))
			px(im, (x0 + x1) / 2, y - 2, Color("ffffff"))
		"circlet":
			for x2 in range(x0, x1):
				px(im, x2, y + 4, gold[3])
				px(im, x2, y + 5, gold[1])
			disc(im, (x0 + x1) / 2.0, y + 4.5, 1.8, Color("7a7aec"))
			px(im, (x0 + x1) / 2, y + 3, Color("ffffff"))
		"bone":
			rect(im, x0, y + 2, x1 - x0, 3, Color("8a5a36"))
			for k2 in range(5):
				var sx2: int = x0 + 1 + k2 * (x1 - x0 - 2) / 4
				for j2 in range(6 - absi(k2 - 2)):
					px(im, sx2, y + 1 - j2, Color("efe6d0"))
				px(im, sx2, y - 5 + absi(k2 - 2), Color("fff8e8"))
			disc(im, (x0 + x1) / 2.0, y + 3, 1.5, Color("b02a20"))


func gen_leaders() -> void:
	var sh: Array = HAIRL7.duplicate()
	var sw7: Array = WHITE7.duplicate()
	var st: Array = TEAL7.duplicate()
	var sk: Array = SKINL7.duplicate()
	var fw: int = 80
	var fh: int = 160
	var mirror: Dictionary = {2: 3, 4: 6, 5: 7}
	BOUNCE_OVR = 0
	var royal_cape: Array = ["3a0c1a", "5a1428", "7a1c38", "9a2848", "b83a5a", "d05a74", "e88296"]
	var leaders: Array = [
		# имя, волосы, платье, плащ, кожа (пусто — обычная), глаза, корона, вид
		["catgirl_queen", ["6a6a78", "8e8e9c", "b0b0bc", "ccccd6", "e0e0e8", "f0f0f6", "ffffff"], ["3a1a4a", "54266a", "6e3488", "8a48a6", "a666c0", "c088d6", "dab0ea"], royal_cape, [], ["5a3a0a", "c8902a", "ffd060"], "gold", "cat"],
		["knight_queen", ["6a4a1a", "8e6a28", "b08c3c", "cca858", "e2c47a", "f0dca0", "faf0cc"], ["4a3a14", "6e561c", "927428", "b49438", "d0b04e", "e6ca70", "f6e4a0"], royal_cape, [], ["1a3a6a", "3a6ac8", "a8d0ff"], "gold", "knight"],
		["elf_queen", ["8a8a7a", "a8a898", "c4c4b4", "dcdccc", "ececde", "f6f6ec", "ffffff"], ["5e6a74", "8896a2", "b0bcc6", "cfd8de", "e4eaee", "f2f6f8", "ffffff"], ["1a4a40", "226052", "2c7862", "389270", "56b07c", "86cc92", "c4ecbc"], [], ["1a5a4a", "3aa88a", "9ae8c8"], "tiara", "elf"],
		["archmage", ["c8c8d8", "d8d8e6", "e6e6f0", "f0f0f6", "f6f6fa", "fafafe", "ffffff"], ["14183a", "1e2652", "2a386e", "3a4e8e", "5068aa", "6e88c4", "98b0dc"], ["0e1030", "16184a", "202464", "2c3280", "3c449c", "5058b6", "6e76cc"], [], ["2a2a8a", "6a6aea", "c8c8ff"], "circlet", "mage"],
		["orc_chief", ["14140e", "1e2016", "2a2e20", "3a402c", "4e563a", "667050", "848e6a"], ["5a1a12", "7a2418", "9a3020", "b8422a", "d05a38", "e47a50", "f0a070"], ["2a1a10", "3e2818", "543a22", "6c4c2e", "86623c", "a07c50", "bc9a6c"], ["2a4a1e", "3e6a2a", "568a36", "70a844", "8cc25a", "acd87a", "d0eca4"], ["5a1a0a", "d06020", "ffc060"], "bone", "orc"],
		["goblin_boss", ["2a2a30", "3e4048", "565a64", "72767e", "90949a", "b0b2b6", "d2d4d6"], ["4a3a6a", "62508a", "7e6aa6", "9a86c0", "b4a2d6", "ccc0e6", "e2dcf2"], ["2a2a1a", "3e3e26", "565634", "6e6e44", "8a8a58", "a6a670", "c4c48e"], ["3a4a14", "566a1e", "728a2a", "8ea83a", "a8c254", "c4d878", "e0eca4"], ["3a4a0a", "c8d030", "fff080"], "tin", "goblin"],
		["dwarf_queen", ["6a4a1a", "8e6a28", "b08c3c", "cca858", "e2c47a", "f0dca0", "faf0cc"], ["3a1a1a", "5a2424", "7a3030", "9a4040", "b85656", "d07474", "e49a9a"], royal_cape, [], ["2a3a5a", "4a7ab8", "a8d0ff"], "gold", "dwarf"],
	]
	var line_up: Image = new_img(fw * leaders.size(), fh)
	var li: int = 0
	for lk in leaders:
		HAIRL7 = hx(lk[1])
		WHITE7 = hx(lk[2])
		TEAL7 = hx(lk[3])
		SKINL7 = hx(lk[4]) if (lk[4] as Array).size() > 0 else sk
		var ey: Array = hx(lk[5])
		EYE_OVR = {"I": ey[0], "i": ey[1], "j": ey[2]}
		_head_pal()
		var kind: String = String(lk[7])
		NO_CAPE = kind in ["cat", "goblin"]
		var vs: Image = new_img(fw * 8, fh * 8)
		for vd in [0, 1, 2, 4, 5]:
			for k in range(8):
				var c2: Image = new_img(fw, fh)
				match kind:
					"cat":
						draw_catgirl(c2, vd, k)
					"elf":
						draw_elfgirl(c2, vd, k, "")
					_:
						draw_hero10(c2, vd, k)
				match kind:
					"knight":
						knight_extras(c2, vd, k)
					"mage":
						mage_extras(c2, vd, k, hx(["e8e8ec", "f6f6f8", "ffffff"]), Color("7a7aec"))
					"orc":
						orc_extras(c2, vd, k, false)
					"goblin":
						orc_extras(c2, vd, k, true)
					"dwarf":
						dwarf_extras(c2, vd, k, "")
				crown(c2, vd, k, String(lk[6]))
				outline_auto(c2, OUTLINE_CHAR)
				vs.blit_rect(c2, Rect2i(0, 0, fw, fh), Vector2i(k * fw, vd * fh))
				if mirror.has(vd):
					var mc: Image = c2.duplicate()
					mc.flip_x()
					vs.blit_rect(mc, Rect2i(0, 0, fw, fh), Vector2i(k * fw, int(mirror[vd]) * fh))
		save3(vs, String(lk[0]))
		gen_faces10("faces_" + String(lk[0]))
		line_up.blit_rect(vs, Rect2i(4 * fw, 0, fw, fh), Vector2i(li * fw, 0))
		li += 1
	line_up.resize(line_up.get_width() * 3, line_up.get_height() * 3, Image.INTERPOLATE_NEAREST)
	line_up.save_png(ProjectSettings.globalize_path("res://").path_join("../screenshots/leaders_lineup.png"))
	EYE_OVR = {}
	NO_CAPE = false
	HAIRL7 = sh
	WHITE7 = sw7
	TEAL7 = st
	SKINL7 = sk
	_head_pal()


## Бесшовная мостовая 64x64: камни рядами со сдвигом, свет сверху-слева, тёмные швы
func gen_cobble() -> void:
	var im: Image = new_img(64, 64)
	for y in range(64):
		var row: int = y / 8
		for x in range(64):
			var off: int = 6 if row % 2 == 1 else 0
			var bx: int = posmod(x + off, 12)
			var by: int = posmod(y, 8)
			var id: int = int(posmod(x + off, 64) / 12) + row * 7
			var v: float = 0.5 + (h01(id, row, 9) - 0.5) * 0.22
			if by == 0 or bx == 0:
				v = 0.12
			elif by == 1 or bx == 1:
				v += 0.16
			elif by == 7 or bx == 11:
				v -= 0.14
			im.set_pixel(x, y, pick(STONE, v + 0.08, x, y))
	save3(im, "wt_cobble", false)


# ================================================================== дикие края: деревья, пещеры, звери, грибы, отшельники

func gen_wild() -> void:
	_palettes3()
	gen_birch()
	gen_tree3("tree_unicorn", 81, 128, 160, hx(["6a2a5a", "9a3a7a", "c45a9c", "e47cba", "f4a2d2", "fcc8e6", "fff0fa"]), "blossom")
	gen_tree3("tree_autumn2", 83, 136, 168, hx(["5a1a12", "8a2a16", "b4441e", "d8662a", "ee9038", "f8b850", "fde090"]))
	gen_swamp_pool()
	gen_reeds()
	gen_cave_entrance()
	gen_giant_shroom("giant_shroom_blue", hx(["14304e", "1e4e7a", "2e74a8", "4aa0d0", "7ad0f0", "c0f4ff"]))
	gen_giant_shroom("giant_shroom_pink", hx(["4a1438", "7a2258", "a8387e", "d05aa4", "ec88c4", "fcc4e4"]))
	gen_hermit_hut()
	gen_stump_table()
	gen_animals()
	gen_mushrooms()
	gen_wild_people()
	var items: Array = []
	for nm in ["tree_birch", "tree_unicorn", "tree_autumn2", "swamp_pool", "reeds", "cave_entrance", "giant_shroom_blue", "giant_shroom_pink", "hermit_hut", "stump_table"]:
		items.append([nm, Image.load_from_file(ProjectSettings.globalize_path(OUT + String(nm) + ".png"))])
	_sheet(items, 2, "wild_preview.png")


func gen_birch() -> void:
	gen_tree3("tree_birch", 91, 112, 168, hx(["2e4e24", "3e6a2c", "5a8e38", "7cb048", "a2cc5e", "c8e27e", "eaf4b0"]))
	var im: Image = Image.load_from_file(ProjectSettings.globalize_path(OUT + "tree_birch.png"))
	im.convert(Image.FORMAT_RGBA8)
	var bark: Dictionary = {}
	for i in range(BARK7.size()):
		bark[(BARK7[i] as Color).to_rgba32()] = i
	var white: Array = hx(["6a6a6e", "a8a8ae", "cfcfd2", "e6e6e6", "f2f2ee", "fafaf6", "ffffff"])
	for y in range(im.get_height()):
		for x in range(im.get_width()):
			var c: Color = im.get_pixel(x, y)
			var k: int = c.to_rgba32()
			if bark.has(k):
				var nc: Color = white[clampi(int(bark[k]) + 1, 0, 6)]
				# чёрные чёрточки берёзы
				if h01(x / 3, y / 2, 61) > 0.82 and posmod(y, 2) == 0:
					nc = Color("2a2a2e")
				im.set_pixel(x, y, nc)
	save3(im, "tree_birch")


func gen_swamp_pool() -> void:
	var im: Image = new_img(120, 56)
	var c: Vector2 = Vector2(60, 28)
	var wa: Array = hx(["1e3a2e", "28483a", "345a46", "426e52", "54825e", "6a9670"])
	for y in range(56):
		for x in range(120):
			var q: Vector2 = Vector2((x + 0.5 - c.x) / 56.0, (y + 0.5 - c.y) / 24.0)
			var ang: float = atan2(q.y, q.x)
			var d: float = q.length() - sin(ang * 3.0 + 1.0) * 0.08
			if d > 1.0:
				continue
			var v: float = 0.25 + (1.0 - d) * 0.3 + sin(x * 0.3 + y * 0.8) * 0.04
			if d > 0.9:
				v = 0.05
			if (x * 7 + y * 3) % 41 == 0:
				v += 0.4
			px(im, x, y, pick(wa, v, x, y))
	for k in range(6):
		var lp: Vector2 = Vector2(20 + h01(k, 1, 3) * 80.0, 14 + h01(k, 2, 3) * 26.0)
		ell(im, lp.x, lp.y, 4, 2.5, Color("3a7a3a"))
		ell(im, lp.x - 1, lp.y - 0.5, 2.5, 1.4, Color("5aa04a"))
	save3(im, "swamp_pool")


func gen_reeds() -> void:
	var im: Image = new_img(30, 40)
	for k in range(9):
		var x: int = 3 + k * 3
		var top: int = 4 + int(h01(k, 1, 5) * 14.0)
		for y in range(top, 40):
			px(im, x + int((40 - y) * 0.05 * (k % 3 - 1)), y, Color("4a6a2e") if y % 4 else Color("5a7e36"))
		if k % 2 == 0:
			for y2 in range(top, top + 7):
				px(im, x, y2, Color("6a4022"))
				px(im, x + 1, y2, Color("8a5a2e"))
	outline_auto(im, 0.35)
	save3(im, "reeds")


func gen_cave_entrance() -> void:
	var W: int = 220
	var H: int = 170
	var im: Image = new_img(W, H)
	rock_mass(im, Rect2i(0, 0, W, H - 6), 707, 1.0)
	var c: Vector2 = Vector2(110, 164)
	for y in range(80, 165):
		for x in range(50, 170):
			var q: Vector2 = Vector2((x + 0.5 - c.x) / 54.0, (y + 0.5 - c.y) / 82.0)
			var d: float = q.length()
			if d > 1.0:
				continue
			var col: Color = Color("0c0a12").lerp(Color("1e1a2e"), clampf(d * 1.2 - 0.3, 0.0, 1.0))
			if d > 0.93:
				col = Color("2a2638")
			px(im, x, y, col)
	# светящиеся грибочки и кристаллы в глубине
	for k in range(9):
		var gx: int = 70 + int(h01(k, 1, 9) * 80.0)
		var gy: int = 140 + int(h01(k, 2, 9) * 20.0)
		var gc: Color = Color("6ae8ff") if k % 2 == 0 else Color("ff8ae0")
		px(im, gx, gy, gc)
		px(im, gx - 1, gy, gc.darkened(0.3))
		px(im, gx + 1, gy, gc.darkened(0.3))
		px(im, gx, gy + 1, Color("c8c0d8"))
		px(im, gx, gy - 1, Color("ffffff"))
	outline_auto(im, 0.4)
	save3(im, "cave_entrance")


func gen_giant_shroom(name: String, cap: Array) -> void:
	var im: Image = new_img(60, 80)
	for y in range(36, 78):
		var w: float = 4.0 + float(y - 36) * 0.08
		for x in range(int(30 - w), int(30 + w) + 1):
			var u: float = (x - (30 - w)) / (2.0 * w)
			px(im, x, y, Color("eae2f2") if u < 0.35 else (Color("cfc4dc") if u < 0.75 else Color("a89cba")))
	for y2 in range(8, 42):
		for x2 in range(2, 58):
			var dx: float = (x2 + 0.5 - 30.0) / 27.0
			var dy: float = (y2 + 0.5 - 38.0) / 30.0
			if dx * dx + dy * dy > 1.0 or y2 > 40:
				continue
			var l: float = -dx * 0.5 - dy * 0.8
			var t: int = 3 + int(round(l * 1.8))
			if y2 > 37:
				t = 0
			px(im, x2, y2, cap[clampi(t, 0, 5)])
	for k in range(8):
		var sx: int = 10 + int(h01(k, 3, 7) * 40.0)
		var sy: int = 14 + int(h01(k, 4, 7) * 18.0)
		if a_at(im, sx, sy) > 0.5:
			disc(im, sx, sy, 1.8, cap[5])
			px(im, sx, sy, Color("ffffff"))
	outline_auto(im, 0.35)
	save3(im, name)


func gen_hermit_hut() -> void:
	var im: Image = new_img(140, 130)
	var cx: int = 70
	var ground: int = 122
	planks(im, 24, 70, 92, ground - 70, WOOD, true, 9, 0.42, 3)
	# соломенная крыша, низкая и лохматая
	for y in range(22, 76):
		var t: float = float(y - 22) / 54.0
		var hw: float = 18.0 + t * 54.0
		for x in range(int(cx - hw), int(cx + hw) + 1):
			var v: float = 0.7 - t * 0.2 - (x - cx) / hw * 0.12 + (h01(x, y / 3, 9) - 0.5) * 0.2
			if y > 72 and posmod(x, 3) == 0:
				continue
			px(im, x, y, pick(THATCH, v, x, y))
	# мох на крыше
	for k in range(30):
		var mx: int = cx - 40 + int(h01(k, 1, 5) * 80.0)
		var my: int = 30 + int(h01(k, 2, 5) * 36.0)
		if a_at(im, mx, my) > 0.5:
			px(im, mx, my, MOSS[2])
			px(im, mx + 1, my, MOSS[3])
	# дверь, окошко, связки трав, труба с дымком
	rect(im, cx - 10, ground - 34, 20, 34, WOOD[1])
	rect(im, cx - 8, ground - 32, 16, 32, WOOD[3])
	disc(im, cx + 4, ground - 16, 1.2, GOLD[4])
	rect(im, cx + 24, 84, 14, 12, WOOD[1])
	rect(im, cx + 26, 86, 10, 8, Color("f0b050"))
	for k2 in range(4):
		var bx: int = cx - 34 + k2 * 6
		for y3 in range(78, 92):
			px(im, bx, y3, [MINT[4], LAV[5], SAGE[4], MINT[3]][k2])
	rect(im, cx + 28, 10, 10, 24, STONE[3])
	disc(im, cx + 33, 4, 3.0, Color(0.85, 0.85, 0.9, 0.5))
	outline_auto(im, 0.4)
	save3(im, "hermit_hut")


func gen_stump_table() -> void:
	var im: Image = new_img(40, 30)
	ell(im, 20, 26, 16, 3, Color(0.1, 0.08, 0.06, 0.3))
	for y in range(10, 26):
		for x in range(8, 32):
			px(im, x, y, pick(hx(LOG), 0.5 - (x - 20) * 0.02, x, y))
	ell(im, 20, 10, 12, 4, Color("c8a272"))
	for r in [3.0, 6.0, 9.0]:
		for a in range(24):
			px(im, 20 + int(cos(a * 0.26) * r), 10 + int(sin(a * 0.26) * r * 0.33), Color("94683e"))
	rect(im, 15, 4, 5, 6, Color("e8e4d8"))
	ell(im, 26, 7, 3, 1.5, Color("c03030"))
	outline_auto(im, 0.4)
	save3(im, "stump_table")


# ---------------------------------------------------------------- звери

## Четвероногий зверь сбоку (смотрит влево). sp — размеры и цвета. Кадры: 0-3 шаг, 4 стоит, 5 щиплет траву
func draw_beast(im: Image, f: int, sp: Dictionary) -> void:
	var W: int = im.get_width()
	var H: int = im.get_height()
	var body: Array = sp["body"]
	var bw: float = float(sp["bw"])
	var bh: float = float(sp["bh"])
	var leg: float = float(sp["leg"])
	var ground: float = float(H - 2)
	var cy: float = ground - leg - bh * 0.5
	var cx: float = W * 0.55
	var bob: float = 1.0 if f == 1 or f == 3 else 0.0
	cy -= bob
	var hop: bool = sp.get("hop", false)
	if hop and f < 4:
		cy -= [0.0, 3.0, 4.0, 2.0][f]
	# хвост
	var tail: Vector2 = Vector2(cx + bw * 0.5, cy - bh * 0.2)
	if sp.has("tail"):
		var tc: Array = sp["tail"]
		var tl: float = float(sp.get("tail_len", 4.0))
		blob(im, tail.x + tl * 0.5, tail.y - tl * 0.3, tl * 0.7, tl * 0.45, tc, 3)
		if sp.get("tail_tip", null) != null:
			blob(im, tail.x + tl, tail.y - tl * 0.5, tl * 0.35, tl * 0.3, [sp["tail_tip"], sp["tail_tip"], sp["tail_tip"], sp["tail_tip"], sp["tail_tip"], sp["tail_tip"], sp["tail_tip"]], 3)
	# ноги: дальние темнее
	var legs: Array = [cx - bw * 0.32, cx + bw * 0.3]
	for side in [0, 1]:
		for i in range(2):
			var lx: float = legs[i]
			var ph: float = float(f + side * 2 + i) * 1.57
			var sw: float = sin(ph) * 2.2 if f < 4 else 0.0
			if hop and f < 4:
				sw = (2.5 if i == 1 else -1.5) * (1.0 if f % 2 == 0 else -0.6)
			var top: Vector2 = Vector2(lx + (1.0 if side == 0 else -1.0), cy + bh * 0.3)
			var foot: Vector2 = Vector2(lx + sw + (1.0 if side == 0 else -1.0), ground)
			if f < 4 and sin(ph) > 0.5 and not hop:
				foot.y -= 1.5
			var lw: float = float(sp.get("leg_w", 1.6))
			capsule(im, top, foot, lw, lw * 0.8, body, 2 if side == 0 else 3)
			px(im, int(foot.x), int(foot.y), body[0])
	# тело
	blob(im, cx, cy, bw * 0.5, bh * 0.5, body, 4)
	if sp.has("belly"):
		var bc: Array = sp["belly"]
		for x in range(int(cx - bw * 0.35), int(cx + bw * 0.3)):
			for y in range(int(cy + bh * 0.15), int(cy + bh * 0.45)):
				if a_at(im, x, y) > 0.5:
					px(im, x, y, bc[4])
	if sp.has("stripe"):
		for x2 in range(int(cx - bw * 0.4), int(cx + bw * 0.42)):
			px(im, x2, int(cy - bh * 0.42), sp["stripe"])
			px(im, x2, int(cy - bh * 0.42) + 1, sp["stripe"])
	# голова
	var graze: bool = f == 5
	var hx0: float = cx - bw * 0.5 - float(sp["head"]) * 0.2
	var hy: float = cy - bh * 0.25 - float(sp.get("neck", 0.0))
	if graze:
		hy = ground - float(sp["head"]) * 0.5
		hx0 -= 1.0
	var hr: float = float(sp["head"])
	if sp.get("neck", 0.0) > 0.0 and not graze:
		capsule(im, Vector2(cx - bw * 0.35, cy - bh * 0.2), Vector2(hx0 + hr * 0.3, hy + hr * 0.3), bh * 0.28, hr * 0.4, body, 4)
	blob(im, hx0, hy, hr * 0.62, hr * 0.5, body, 5)
	var snout: Vector2 = Vector2(hx0 - hr * 0.6, hy + hr * 0.15)
	blob(im, snout.x, snout.y, hr * float(sp.get("snout", 0.35)), hr * 0.26, sp.get("snout_col", body), 4)
	px(im, int(snout.x - hr * float(sp.get("snout", 0.35)) + 0.5), int(snout.y), Color("1a1418"))
	# ухо
	var ear: float = float(sp.get("ear", 0.5)) * hr
	var ex: float = hx0 + hr * 0.15
	if sp.get("ear_long", false):
		capsule(im, Vector2(ex, hy - hr * 0.3), Vector2(ex + hr * 0.4, hy - hr * 0.3 - ear), 1.6, 1.2, body, 5)
		capsule(im, Vector2(ex + 1.5, hy - hr * 0.3), Vector2(ex + hr * 0.6, hy - hr * 0.2 - ear), 1.5, 1.1, body, 3)
	else:
		tri(im, Vector2(ex - 1.5, hy - hr * 0.35), Vector2(ex + 2.0, hy - hr * 0.3), Vector2(ex + 0.5, hy - hr * 0.35 - ear), func(_x: int, _y: int, u: float) -> Color: return body[5] if u < 0.5 else body[3])
	# рога / рог
	if sp.has("antlers"):
		var ac: Color = sp["antlers"]
		for k in range(3):
			line(im, int(ex), int(hy - hr * 0.4), int(ex + 2 - k * 3), int(hy - hr * 0.4 - 6 - k), ac)
			line(im, int(ex + 2 - k * 3), int(hy - hr * 0.4 - 6 - k), int(ex + 4 - k * 3), int(hy - hr * 0.4 - 9 - k), ac)
	if sp.has("horn"):
		var hc: Color = sp["horn"]
		for k2 in range(8):
			px(im, int(hx0 - hr * 0.2 - k2 * 0.5), int(hy - hr * 0.4 - k2), hc if k2 % 2 == 0 else hc.darkened(0.2))
	if sp.has("tusk"):
		px(im, int(snout.x), int(snout.y) - 1, Color("f6f0e0"))
		px(im, int(snout.x) + 1, int(snout.y) - 2, Color("f6f0e0"))
	if sp.has("mane"):
		var mc: Array = sp["mane"]
		for k3 in range(10):
			var mp: Vector2 = Vector2(hx0 + hr * 0.3 + k3 * 1.4, hy - hr * 0.35 + k3 * 0.9)
			disc(im, mp.x, mp.y, 1.8, mc[k3 % mc.size()])
	# глаз с бликом
	var eye: Vector2 = Vector2(hx0 - hr * 0.15, hy - hr * 0.05)
	px(im, int(eye.x), int(eye.y), Color("120c10"))
	if hr >= 6.0:
		px(im, int(eye.x) - 1, int(eye.y), Color("120c10"))
		px(im, int(eye.x), int(eye.y) - 1, Color("ffffff"))
	if sp.has("blush"):
		px(im, int(eye.x) + 1, int(eye.y) + 2, sp["blush"])
	# искры волшебных зверей
	if sp.get("magic", false):
		for k4 in range(5):
			var gx: int = int(h01(k4, f, 41) * W)
			var gy: int = int(h01(k4, f, 43) * H * 0.7)
			if a_at(im, gx, gy) < 0.1:
				px(im, gx, gy, Color("ffffff"))
				px(im, gx + 1, gy, Color(1, 1, 1, 0.5))
	if sp.has("facets"):
		for y5 in range(H):
			for x5 in range(W):
				var c5: Color = im.get_pixel(x5, y5)
				if c5.a > 0.5 and posmod(x5 + y5 * 2, 7) == 0 and c5.b > c5.r:
					im.set_pixel(x5, y5, c5.lightened(0.35))


## Сплющенный кабан: широкий плоский, ножки еле видны, тёмная полоска по спине, розовый пятачок
func draw_flat_boar(im: Image, f: int) -> void:
	var W: int = im.get_width()
	var H: int = im.get_height()
	var body: Array = hx(["2a2228", "3e3238", "56464a", "6e5a5a", "86706a", "a08a80", "baa69a"])
	var ground: float = float(H - 2)
	var squash: float = [0.0, 1.0, 0.0, 1.0, 0.0, 0.5][f]
	var cy: float = ground - 6.0 + squash * 0.5
	var cx: float = W * 0.52
	for i in range(4):
		var lx: float = cx - 12.0 + float(i) * 8.0
		var sw: float = sin(float(f + i) * 1.57) * 1.5 if f < 4 else 0.0
		rect(im, int(lx + sw), int(ground) - 2, 3, 2, body[1])
	blob(im, cx, cy, 16.0, 6.0 - squash * 0.6, body, 3)
	# полоска и щетинка на спине
	for x in range(int(cx - 12), int(cx + 13)):
		var yt: int = int(cy - 5.5 + squash * 0.6 + pow((x - cx) / 16.0, 2.0) * 4.0)
		px(im, x, yt, body[0])
		if posmod(x, 3) == 0:
			px(im, x, yt - 1, body[1])
	# мордочка слева
	var sx: float = cx - 16.0
	blob(im, sx, cy + 1.0, 4.0, 3.2, hx(["6a4a4c", "8a6266", "a87a7c", "c49696", "dcb0ae", "eccac6", "f8e2de"]), 3)
	px(im, int(sx) - 2, int(cy) + 1, Color("3a2224"))
	px(im, int(sx) - 2, int(cy) + 2, Color("3a2224"))
	px(im, int(sx) + 1, int(cy) - 1, Color("f6f0e0"))
	# глаз с бликом и ухо
	px(im, int(cx - 9), int(cy - 2), Color("120c10"))
	px(im, int(cx - 10), int(cy - 2), Color("120c10"))
	px(im, int(cx - 9), int(cy - 3), Color("ffffff"))
	tri(im, Vector2(cx - 6, cy - 4), Vector2(cx - 2, cy - 4), Vector2(cx - 5, cy - 8 + squash), func(_x: int, _y: int, u: float) -> Color: return body[4] if u < 0.5 else body[2])
	# хвостик-завиток
	px(im, int(cx + 16), int(cy - 2), body[2])
	px(im, int(cx + 17), int(cy - 3), body[2])
	px(im, int(cx + 18), int(cy - 2), body[2])


const ANIMALS: Dictionary = {
	"rabbit": {"w": 22, "h": 18, "bw": 11, "bh": 8, "leg": 3, "head": 6, "body": ["4a3428", "6a4a36", "8a6448", "a8805e", "c49e7c", "dcbc9e", "f0dcc4"], "belly": ["f0e8e0", "f0e8e0", "f0e8e0", "f0e8e0", "f0e8e0", "f0e8e0", "f0e8e0"], "ear": 1.2, "ear_long": true, "hop": true, "tail": ["e8e0d8", "f0e8e0", "f8f0ea", "fffaf6", "ffffff", "ffffff", "ffffff"], "tail_len": 3},
	"fox": {"w": 34, "h": 22, "bw": 16, "bh": 7, "leg": 6, "head": 6, "body": ["5a1e0a", "7e2e10", "a64218", "c85a22", "e07832", "ee9a52", "f8c08a"], "belly": ["f0e8e0", "f0e8e0", "f0e8e0", "f0e8e0", "f0e8e0", "f0e8e0", "f0e8e0"], "snout": 0.5, "ear": 0.8, "tail": ["7e2e10", "a64218", "c85a22", "e07832", "ee9a52", "f8c08a", "fff0e0"], "tail_len": 9, "tail_tip": "fff8f0", "leg_w": 1.3},
	"deer": {"w": 42, "h": 44, "bw": 18, "bh": 10, "leg": 14, "head": 6, "neck": 9, "body": ["4a2e18", "6a4224", "8a5a32", "a87444", "c4925e", "dcb080", "f0d0a8"], "belly": ["f0e0c8", "f0e0c8", "f0e0c8", "f0e0c8", "f0e0c8", "f0e0c8", "f0e0c8"], "snout": 0.45, "ear": 0.8, "antlers": "6a4a2a", "tail": ["f0e8e0", "f0e8e0", "f8f0ea", "fffaf6", "ffffff", "ffffff", "ffffff"], "tail_len": 2.5, "leg_w": 1.2},
	"boar": {"w": 36, "h": 26, "bw": 20, "bh": 12, "leg": 5, "head": 8, "body": ["1e1614", "2e2420", "44362e", "5a4a3e", "726050", "8c7a66", "a89482"], "snout": 0.4, "snout_col": ["6a4a4c", "8a6266", "a87a7c", "c49696", "dcb0ae", "eccac6", "f8e2de"], "ear": 0.5, "tusk": true, "stripe": "1e1614", "tail": ["2e2420", "2e2420", "44362e", "44362e", "5a4a3e", "5a4a3e", "726050"], "tail_len": 2, "leg_w": 2.0},
	"hedgehog": {"w": 22, "h": 14, "bw": 13, "bh": 8, "leg": 1, "head": 4, "body": ["2e2018", "46322a", "5e4638", "7a5c48", "967458", "b08e70", "c8aa8c"], "snout": 0.5, "snout_col": ["8a6a5a", "a8887a", "c4a49a", "dcc0b6", "eedad2", "f6ece6", "ffffff"], "ear": 0.3, "leg_w": 1.0, "spikes": true},
	"squirrel": {"w": 22, "h": 20, "bw": 9, "bh": 7, "leg": 3, "head": 5, "body": ["5a2210", "7e3216", "a4481e", "c4602a", "dc7e3e", "ec9e5e", "f8c690"], "belly": ["f8e8d8", "f8e8d8", "f8e8d8", "f8e8d8", "f8e8d8", "f8e8d8", "f8e8d8"], "ear": 0.9, "hop": true, "tail": ["7e3216", "a4481e", "c4602a", "dc7e3e", "ec9e5e", "f8c690", "fff0e0"], "tail_len": 8},
	"duck": {"w": 20, "h": 16, "bw": 11, "bh": 7, "leg": 2, "head": 4, "body": ["5a4a2e", "7a6440", "9a8054", "b89c6a", "d0b684", "e4ce9e", "f4e4c0"], "snout": 0.5, "snout_col": ["8a5a10", "b07818", "d09a28", "e8b83a", "f6d050", "fde480", "fff2b0"], "ear": 0.01, "neck": 3, "leg_w": 0.8},
	"sapphire_hare": {"w": 24, "h": 20, "bw": 11, "bh": 8, "leg": 3, "head": 6, "body": ["0e1e5a", "16308a", "2048b8", "3468dc", "5a92f0", "92c0ff", "d0e8ff"], "ear": 1.3, "ear_long": true, "hop": true, "magic": true, "facets": true, "tail": ["92c0ff", "b0d4ff", "d0e8ff", "ffffff", "ffffff", "ffffff", "ffffff"], "tail_len": 3},
	"unicorn": {"w": 48, "h": 46, "bw": 20, "bh": 11, "leg": 15, "head": 7, "neck": 10, "body": ["8a7a92", "b0a4ba", "ccc4d6", "e2dcea", "f2eef6", "faf8fc", "ffffff"], "snout": 0.45, "ear": 0.7, "horn": "f0c850", "mane": ["f48ac8", "c08af0", "8ac8f8", "f8e08a"], "tail": ["f48ac8", "c08af0", "8ac8f8", "f8a8d8", "fcd0e8", "ffffff", "ffffff"], "tail_len": 8, "magic": true, "blush": "f8a8c8", "leg_w": 1.3},
	"golden_deer": {"w": 42, "h": 44, "bw": 18, "bh": 10, "leg": 14, "head": 6, "neck": 9, "body": ["6a4a0e", "8e6616", "b48a22", "d4ac36", "ecc850", "f8e07a", "fff4b8"], "snout": 0.45, "ear": 0.8, "antlers": "fff0b0", "magic": true, "tail": ["fff4b8", "fff4b8", "fff8d8", "ffffff", "ffffff", "ffffff", "ffffff"], "tail_len": 2.5, "leg_w": 1.2},
	"ember_fox": {"w": 34, "h": 24, "bw": 16, "bh": 7, "leg": 6, "head": 6, "body": ["3a0a06", "5a140a", "82200e", "a83212", "d04a1a", "f07a2a", "ffb050"], "snout": 0.5, "ear": 0.8, "tail": ["d04a1a", "f07a2a", "ff9a30", "ffc040", "ffe070", "fff4b0", "ffffff"], "tail_len": 10, "tail_tip": "fff6a0", "magic": true, "leg_w": 1.3},
}
const MYTHIC: Array = ["sapphire_hare", "unicorn", "golden_deer", "ember_fox"]


func gen_animals() -> void:
	var sheet_all: Image = new_img(60 * 12, 50)
	var ai: int = 0
	for nm in ANIMALS.keys():
		var sp: Dictionary = ANIMALS[nm].duplicate()
		for key in ["body", "belly", "tail", "snout_col", "mane"]:
			if sp.has(key):
				sp[key] = hx(sp[key])
		for key2 in ["antlers", "horn", "stripe", "tail_tip", "blush"]:
			if sp.has(key2):
				sp[key2] = Color(String(sp[key2]))
		var w: int = int(sp["w"])
		var h: int = int(sp["h"])
		var sheet: Image = new_img(w * 6, h)
		for f in range(6):
			var cell: Image = new_img(w, h)
			draw_beast(cell, f, sp)
			if sp.get("spikes", false):
				for x in range(3, w - 2):
					for y in range(0, h):
						if a_at(cell, x, y) > 0.5:
							if posmod(x, 2) == 0 and x > 6:
								px(cell, x, y - 1, Color("2e2018"))
								px(cell, x + 1, y - 2, Color("5e4638"))
							break
			outline_auto(cell, 0.5)
			sheet.blit_rect(cell, Rect2i(0, 0, w, h), Vector2i(f * w, 0))
		save3(sheet, "animal_" + String(nm))
		sheet_all.blit_rect(sheet, Rect2i(0, 0, w, h), Vector2i(ai * 60, 0))
		ai += 1
	# сплющенный кабан
	var fb: Image = new_img(42 * 6, 18)
	for f2 in range(6):
		var c2: Image = new_img(42, 18)
		draw_flat_boar(c2, f2)
		outline_auto(c2, 0.5)
		fb.blit_rect(c2, Rect2i(0, 0, 42, 18), Vector2i(f2 * 42, 0))
	save3(fb, "animal_flat_boar")
	sheet_all.blit_rect(fb, Rect2i(0, 0, 42, 18), Vector2i(ai * 60, 0))
	sheet_all.resize(sheet_all.get_width() * 3, sheet_all.get_height() * 3, Image.INTERPOLATE_NEAREST)
	sheet_all.save_png(ProjectSettings.globalize_path("res://").path_join("../screenshots/animals_lineup.png"))


# ---------------------------------------------------------------- грибы

const SHROOMS: Dictionary = {
	"porcini": [["5a3a1e", "7a5028", "9a6a36", "b88a4c", "d0a868"], "f0e8d8", 7.0, 9.0, false],
	"birch_bolete": [["3a2a1e", "5a4028", "7a5a38", "96764e", "b09468"], "e8e4dc", 6.0, 11.0, false],
	"chanterelle": [["9a5a10", "c07a18", "e09a28", "f0b840", "fcd870"], "f0b840", 5.0, 7.0, false],
	"fly_agaric": [["6a0e0e", "9a1a16", "c82a22", "e44a3a", "f47a6a"], "f4f0e8", 7.0, 9.0, true],
	"glow_cap": [["14304e", "1e4e7a", "2e74a8", "4aa0d0", "9ae8ff"], "c8e8f0", 5.0, 8.0, true],
	"moon_shroom": [["5a4a8a", "7a6aaa", "a090cc", "c8b8e8", "f0e8ff"], "f0eaff", 6.0, 9.0, true],
	"swamp_honey": [["6a4a10", "8e6a1a", "b08a2a", "cca840", "e4c460"], "e8dcb8", 4.0, 8.0, false],
	"web_shroom": [["3a3448", "524a66", "6c6484", "8a84a2", "b4b0c8"], "dcdce8", 5.0, 9.0, true],
	"blood_russula": [["4a0812", "6e0e1c", "92182a", "b42a3c", "d04a58"], "f0e0e0", 6.0, 7.0, false],
	"elf_star": [["1a5a4a", "2a7a62", "3aa080", "6ac8a4", "b4f0d8"], "eaf8f0", 5.0, 9.0, true],
	"morel": [["4a361e", "6a4e2c", "8a6a3e", "a88852", "c4a670"], "e4d8c0", 4.0, 10.0, false],
	"field_champignon": [["c8c0b0", "dcd4c4", "eae4d6", "f4f0e6", "ffffff"], "f0ece4", 6.0, 6.0, false],
}


func draw_shroom(im: Image, cap: Array, stem: Color, r: float, sh: float, spots: bool, morel: bool) -> void:
	var W: int = im.get_width()
	var cx: float = W / 2.0
	var base: int = im.get_height() - 2
	ell(im, cx, base + 0.5, r + 1.0, 1.5, Color(0, 0, 0, 0.3))
	for y in range(base - int(sh), base + 1):
		var w: float = 1.8 + float(y - base + sh) * 0.08
		for x in range(int(cx - w), int(cx + w) + 1):
			px(im, x, y, stem if x <= cx else stem.darkened(0.2))
	var top: float = base - sh
	for y2 in range(int(top - r * (1.3 if morel else 0.8)), int(top + 2)):
		for x2 in range(int(cx - r) - 1, int(cx + r) + 2):
			var dx: float = (x2 + 0.5 - cx) / r
			var dy: float = (y2 + 0.5 - top) / (r * (1.3 if morel else 0.8))
			if dx * dx + dy * dy > 1.0 or y2 > top + 1:
				continue
			var t: int = 3 if dx < -0.2 and dy < -0.3 else (2 if dx < 0.4 else 1)
			if y2 >= int(top):
				t = 0
			if morel and posmod(x2 + y2, 3) == 0:
				t = 0
			px(im, x2, y2, cap[t])
	px(im, int(cx - r * 0.4), int(top - r * 0.4), cap[4])
	if spots:
		for k in range(4):
			var sx: int = int(cx - r * 0.6 + k * r * 0.4)
			var sy: int = int(top - r * 0.3 - (k % 2) * r * 0.25)
			if a_at(im, sx, sy) > 0.5:
				px(im, sx, sy, Color("ffffff") if cap[2].r > 0.6 else cap[4])


func gen_mushrooms() -> void:
	var line_img: Image = new_img(24 * SHROOMS.size(), 24)
	var i: int = 0
	for id in SHROOMS.keys():
		var sp: Array = SHROOMS[id]
		var im: Image = new_img(24, 24)
		draw_shroom(im, hx(sp[0]), Color(String(sp[1])), float(sp[2]), float(sp[3]), bool(sp[4]), id == "morel")
		outline_auto(im, 0.45)
		save3(im, "shroom_" + String(id))
		line_img.blit_rect(im, Rect2i(0, 0, 24, 24), Vector2i(i * 24, 0))
		i += 1
	line_img.resize(line_img.get_width() * 4, line_img.get_height() * 4, Image.INTERPOLATE_NEAREST)
	line_img.save_png(ProjectSettings.globalize_path("res://").path_join("../screenshots/shrooms_lineup.png"))


# ---------------------------------------------------------------- отшельники и изгои

const WILD_PEOPLE: Array = [
	# имя, волосы, одежда, плащ, плащ?
	["hermit_agna", ["6a6a72", "8e8e96", "b0b0b8", "ccccd2", "e0e0e6", "f0f0f4", "ffffff"], ["3a2a1a", "54402a", "6e563a", "8a6e4c", "a68a64", "c2a882", "dcc8a4"], ["2a3a1e", "3a5028", "4e6a34", "668642", "80a056", "9cba70", "bcd494"], true],
	["hermit_oda", ["2a1a12", "3e2a1c", "543c28", "6c5036", "866848", "a2845e", "c0a27a"], ["4a3a5a", "5e4c72", "74608a", "8c78a4", "a692bc", "c0aed2", "dccae8"], ["3a2a1a", "54402a", "6e563a", "8a6e4c", "a68a64", "c2a882", "dcc8a4"], true],
	["outcast_rin", ["0e0c14", "181624", "24203a", "322c4e", "443c66", "5a5282", "766ea0"], ["2a2a2e", "3e3e44", "56565e", "6e6e78", "8a8a94", "a6a6b0", "c4c4cc"], ["1a1418", "2a2026", "3a2e36", "4c3e48", "60505c", "766672", "8e7e8a"], true],
	["outcast_vex", ["5a1a0a", "7e2a12", "a43e1a", "c45626", "dc7438", "ec9452", "f8b878"], ["1a2a1e", "26402c", "345a3c", "46744e", "5a8e62", "76aa7c", "9ac69c"], ["1a1418", "2a2026", "3a2e36", "4c3e48", "60505c", "766672", "8e7e8a"], true],
]


func gen_wild_people() -> void:
	var sh: Array = HAIRL7.duplicate()
	var sw7: Array = WHITE7.duplicate()
	var st: Array = TEAL7.duplicate()
	var fw: int = 80
	var fh: int = 160
	var mirror: Dictionary = {2: 3, 4: 6, 5: 7}
	BOUNCE_OVR = 0
	for lk in WILD_PEOPLE:
		HAIRL7 = hx(lk[1])
		WHITE7 = hx(lk[2])
		TEAL7 = hx(lk[3])
		_head_pal()
		var vs: Image = new_img(fw * 8, fh * 8)
		for vd in [0, 1, 2, 4, 5]:
			for k in range(8):
				var c2: Image = new_img(fw, fh)
				draw_hero10(c2, vd, k)
				outline_auto(c2, OUTLINE_CHAR)
				vs.blit_rect(c2, Rect2i(0, 0, fw, fh), Vector2i(k * fw, vd * fh))
				if mirror.has(vd):
					var mc: Image = c2.duplicate()
					mc.flip_x()
					vs.blit_rect(mc, Rect2i(0, 0, fw, fh), Vector2i(k * fw, int(mirror[vd]) * fh))
		save3(vs, String(lk[0]))
		gen_faces10("faces_" + String(lk[0]))
	HAIRL7 = sh
	WHITE7 = sw7
	TEAL7 = st
	_head_pal()


# ================================================================== звери v9
# Звери в два раза подробнее (в игре — масштаб 0,5): толстый тёмный контур вокруг каждой
# части, объём светом сверху-слева, крупный глаз с бликом. 12 кадров:
# 0-3 шаг, 4-5 стоит (5 — моргает), 6-9 своё занятие, 10-11 отдых/сон.

const OUTL: Color = Color("1d1a2e")
var crit_layers: Array = []


## Слой части тела: рисуем отдельно, обводим, потом кладём на кадр (части разделены контуром)
func _lay(w: int, h: int) -> Image:
	var l: Image = new_img(w, h)
	crit_layers.append(l)
	return l


func _flush(cell: Image) -> void:
	for l in crit_layers:
		var li: Image = l
		outline(li, OUTL)
		cell.blend_rect(li, Rect2i(0, 0, li.get_width(), li.get_height()), Vector2i.ZERO)
	crit_layers.clear()


## Повёрнутый эллипс с объёмом (ramp — от тёмного к светлому)
func rell(im: Image, c: Vector2, rx: float, ry: float, ang: float, ramp: Array, tb: int) -> void:
	var r: float = maxf(rx, ry) + 1.0
	var ca: float = cos(ang)
	var sa: float = sin(ang)
	for y in range(int(c.y - r), int(c.y + r) + 1):
		for x in range(int(c.x - r), int(c.x + r) + 1):
			var d: Vector2 = Vector2(x + 0.5 - c.x, y + 0.5 - c.y)
			var u: float = (d.x * ca + d.y * sa) / rx
			var v: float = (-d.x * sa + d.y * ca) / ry
			var d2: float = u * u + v * v
			if d2 > 1.0:
				continue
			# свет сверху-слева: по мировым координатам точки на «шаре»
			var nx: float = d.x / r
			var ny: float = d.y / r
			var l: float = -nx * 0.45 - ny * 0.9 + (1.0 - d2) * 0.6
			var t: int = tb + (1 if l > 0.55 else (0 if l > -0.05 else -1))
			if d2 > 0.78 and ny > 0.15:
				t -= 1
			px(im, x, y, ramp[clampi(t, 0, ramp.size() - 1)])


## Нога из двух звеньев: бедро → колено → копыто/лапка
func cleg(im: Image, hip: Vector2, foot: Vector2, w0: float, w1: float, ramp: Array, tb: int, paw: Color, knee_back: bool) -> void:
	var mid: Vector2 = hip.lerp(foot, 0.5) + Vector2(1.5 if knee_back else -1.0, 0)
	capsule(im, hip, mid, w0, (w0 + w1) * 0.5, ramp, tb)
	capsule(im, mid, foot, (w0 + w1) * 0.5, w1, ramp, tb)
	rect(im, int(foot.x - w1), int(foot.y - 1), int(w1 * 2.0) + 1, 2, paw)


func ceye(im: Image, p: Vector2, big: bool, blink: bool) -> void:
	if blink:
		rect(im, int(p.x) - 1, int(p.y), 3, 1, OUTL)
		return
	rect(im, int(p.x) - 1, int(p.y) - 1, 2 if not big else 3, 3 if big else 2, Color("16121e"))
	px(im, int(p.x) - 1, int(p.y) - 1, Color("ffffff"))
	if big:
		px(im, int(p.x) + 1, int(p.y) + 1, Color("4a4060"))


const CRIT: Dictionary = {
	"rabbit": {"w": 44, "h": 36, "kind": "bunny", "act": "dig", "rest": "lie",
		"body": ["4a342e", "6e5044", "927060", "b2927e", "ccb09a", "e4ceb8", "f6e8d8"], "belly": "f4ece0", "inner": "f0a8a8"},
	"sapphire_hare": {"w": 48, "h": 40, "kind": "bunny", "act": "sniff", "rest": "lie", "magic": true, "gem": true,
		"body": ["101c58", "1a3090", "2650c0", "3a74e0", "62a0f4", "a0ccff", "e0f0ff"], "belly": "c8e4ff", "inner": "8ad0ff"},
	"fox": {"w": 64, "h": 44, "kind": "fox", "act": "pounce", "rest": "curl",
		"body": ["5a1e0c", "86300e", "b04816", "d2621e", "ea8432", "f6aa5e", "ffd49a"], "belly": "fbf2e6", "sock": "2e1a1a"},
	"ember_fox": {"w": 64, "h": 46, "kind": "fox", "act": "pounce", "rest": "curl", "magic": true, "flame": true,
		"body": ["2e0a08", "52120a", "80200e", "aa3414", "d4501c", "f47c2c", "ffb052"], "belly": "ffd890", "sock": "1a0a0a"},
	"deer": {"w": 76, "h": 84, "kind": "deer", "act": "graze", "rest": "lie", "antlers": "7a5a36",
		"body": ["4a2c18", "6c4226", "8e5a34", "ae7646", "c8945e", "dcb27e", "eed0a6"], "belly": "f4e6d0", "spots": true},
	"golden_deer": {"w": 76, "h": 84, "kind": "deer", "act": "graze", "rest": "lie", "antlers": "fff2b8", "magic": true,
		"body": ["6a4808", "906810", "b88c1c", "d8ae30", "f0ca4e", "fae078", "fff4bc"], "belly": "fff8dc", "spots": true},
	"boar": {"w": 68, "h": 50, "kind": "boar", "act": "root", "rest": "lie",
		"body": ["1e1616", "2e2422", "45372f", "5c4b3f", "766252", "907a66", "aa947e"], "belly": "6e5a4a", "snout": "d49a96"},
	"hedgehog": {"w": 44, "h": 30, "kind": "hedgehog", "act": "sniff", "rest": "curl",
		"body": ["2a1c16", "443026", "5e4434", "7a5c46", "96765a", "b29472", "ccb08e"], "belly": "f0dcc4", "snout": "f2d8c0"},
	"squirrel": {"w": 40, "h": 40, "kind": "squirrel", "act": "eat", "rest": "flick",
		"body": ["5a200e", "822e12", "a8441a", "c85e26", "de7c3a", "ee9e5c", "f8c690"], "belly": "fbeedc"},
	"duck": {"w": 40, "h": 32, "kind": "duck", "act": "preen", "rest": "sit",
		"body": ["4a3e30", "6a5a46", "8a785e", "aa9878", "c4b496", "dccdb2", "f0e6d4"], "head": ["0c3a26", "125236", "1a6c46", "26885a", "40a474"], "beak": "f0b030"},
	"unicorn": {"w": 92, "h": 92, "kind": "horse", "act": "rear", "rest": "lie", "magic": true, "horn": "f4cc54",
		"body": ["8c7c98", "b0a4be", "cec6da", "e4def0", "f4f0fa", "fbf9fe", "ffffff"], "belly": "ffffff",
		"mane": ["f48ac8", "c08af0", "8ac8f8", "f8e08a", "a8f0c0"]},
	"flat_boar": {"w": 84, "h": 36, "kind": "flat", "act": "flatten", "rest": "flat",
		"body": ["2a2228", "3e3238", "56464a", "6e5a5a", "86706a", "a08a80", "baa69a"], "snout": "dcb0ae"},
}


## Поза кадра: что делает зверь
func crit_pose(f: int, sp: Dictionary) -> Dictionary:
	var p: Dictionary = {"ph": 0.0, "walk": false, "bob": 0.0, "head": 0.0, "hop": 0.0, "crouch": 0.0, "lie": false,
		"blink": false, "curl": false, "up": 0.0, "mouth": false, "chew": 0, "tilt": 0.0, "squash": 0.0, "dirt": false, "front": 0.0, "tail": 0.0}
	if f < 4:
		p["walk"] = true
		p["ph"] = float(f) * PI * 0.5
		p["bob"] = [0.0, 1.0, 0.0, 1.0][f]
		if sp["kind"] in ["bunny", "squirrel"]:
			p["hop"] = [0.0, 4.0, 6.0, 3.0][f]
		if sp["kind"] == "flat":
			p["squash"] = [0.0, 0.5, 0.0, 0.5][f]
		p["tail"] = [0.0, 0.5, 1.0, 0.5][f]
		return p
	if f == 4:
		return p
	if f == 5:
		p["blink"] = true
		p["bob"] = -0.5
		p["tail"] = 0.6
		return p
	var k: int = f - 6
	if f >= 10:
		k = f - 10
		match String(sp["rest"]):
			"lie", "sit", "flat":
				p["lie"] = true
				p["blink"] = true
				p["bob"] = 0.5 * k
				p["head"] = 0.35
			"curl":
				p["curl"] = true
				p["bob"] = 0.5 * k
			"flick":
				p["up"] = 1.0
				p["tail"] = 1.0 * k
				p["blink"] = k == 1
		return p
	match String(sp["act"]):
		"graze":
			p["head"] = [0.7, 1.0, 1.0, 0.7][k]
			p["chew"] = k % 2
			p["tail"] = 0.5 * (k % 2)
		"dig":
			p["head"] = 0.6
			p["front"] = [1.0, -1.0, 1.0, -1.0][k]
			p["dirt"] = k % 2 == 0
		"root":
			p["head"] = [0.8, 1.0, 0.8, 1.0][k]
			p["dirt"] = k % 2 == 1
			p["bob"] = float(k % 2)
		"sniff":
			p["head"] = [0.15, 0.3, 0.15, 0.0][k]
			p["up"] = 0.6 if sp["kind"] == "bunny" else 0.0
			p["mouth"] = k % 2 == 0
		"pounce":
			p["crouch"] = [1.0, 0.0, 0.0, 0.6][k]
			p["hop"] = [0.0, 10.0, 6.0, 0.0][k]
			p["head"] = [0.2, -0.3, 0.8, 0.5][k]
			p["tail"] = [0.2, 1.0, 1.0, 0.4][k]
		"eat":
			p["up"] = 1.0
			p["chew"] = k % 2
			p["blink"] = k == 3
		"preen":
			if k < 2:
				p["mouth"] = true
				p["head"] = -0.4
			else:
				p["head"] = 0.5
				p["chew"] = k % 2
		"rear":
			p["tilt"] = [-0.18, -0.38, -0.38, -0.18][k]
			p["mouth"] = k == 1 or k == 2
			p["tail"] = 1.0
		"flatten":
			p["squash"] = [1.0, 2.0, 1.0, 0.0][k]
	return p


func gen_critters() -> void:
	var lineup: Array = []
	for nm in CRIT.keys():
		var sp: Dictionary = CRIT[nm].duplicate()
		sp["body"] = hx(sp["body"])
		if sp.has("head") and sp["head"] is Array:
			sp["head"] = hx(sp["head"])
		if sp.has("mane"):
			sp["mane"] = hx(sp["mane"])
		var w: int = int(sp["w"])
		var h: int = int(sp["h"])
		var sheet: Image = new_img(w * 12, h)
		for f in range(12):
			var cell: Image = new_img(w, h)
			draw_critter(cell, crit_pose(f, sp), sp, f)
			sheet.blit_rect(cell, Rect2i(0, 0, w, h), Vector2i(f * w, 0))
		save3(sheet, "animal_" + String(nm), false)
		lineup.append(sheet)
	# превью всех зверей (кадры 0, 4, 6, 8, 10) крупно
	var lw: int = 0
	var lh: int = 0
	for s in lineup:
		lw = maxi(lw, (s as Image).get_width() / 12 * 5 + 20)
		lh += (s as Image).get_height() + 6
	var pv: Image = new_img(lw, lh)
	pv.fill(Color("5a7aa0"))
	var yy: int = 0
	for s2 in lineup:
		var im2: Image = s2
		var fw: int = im2.get_width() / 12
		for j in range(5):
			var fr: int = [0, 4, 6, 8, 10][j]
			pv.blend_rect(im2, Rect2i(fr * fw, 0, fw, im2.get_height()), Vector2i(4 + j * (fw + 4), yy))
		yy += im2.get_height() + 6
	pv.resize(pv.get_width() * 3, pv.get_height() * 3, Image.INTERPOLATE_NEAREST)
	pv.save_png(ProjectSettings.globalize_path("res://").path_join("../screenshots/animals_v9.png"))


func draw_critter(cell: Image, p: Dictionary, sp: Dictionary, f: int) -> void:
	var W: int = cell.get_width()
	var H: int = cell.get_height()
	var b: Array = sp["body"]
	var dark: Array = [b[0], b[0], b[1], b[2], b[3], b[4], b[5]]   # дальние ноги темнее
	var ground: float = float(H - 3)
	var kind: String = sp["kind"]
	match kind:
		"bunny":
			_bunny(cell, p, sp, b, dark, ground, W)
		"fox":
			_fox(cell, p, sp, b, dark, ground, W)
		"deer", "horse":
			_deer(cell, p, sp, b, dark, ground, W)
		"boar":
			_boar(cell, p, sp, b, dark, ground, W)
		"hedgehog":
			_hedgehog(cell, p, sp, b, ground, W)
		"squirrel":
			_squirrel(cell, p, sp, b, dark, ground, W)
		"duck":
			_duck(cell, p, sp, b, ground, W)
		"flat":
			_flatboar(cell, p, sp, b, ground, W)
	_flush(cell)
	# земля из-под лап
	if p["dirt"]:
		for k in range(5):
			var dx: int = int(W * 0.18) + int(h01(k, f, 5) * 10.0)
			var dy: int = int(ground) - 2 - int(h01(k, f, 6) * 8.0)
			px(cell, dx, dy, Color("6e4a2e"))
			px(cell, dx + 1, dy, Color("8c623e"))
	# самоцветные грани и искры волшебных зверей
	if sp.get("gem", false):
		for y in range(H):
			for x in range(W):
				var c: Color = cell.get_pixel(x, y)
				if c.a > 0.5 and c != OUTL and posmod(x * 2 + y * 3, 11) == 0:
					cell.set_pixel(x, y, c.lightened(0.45))
	if sp.get("magic", false):
		for k2 in range(6):
			var gx: int = int(h01(k2, f, 41) * W)
			var gy: int = int(h01(k2, f, 43) * H * 0.75)
			if a_at(cell, gx, gy) < 0.1:
				px(cell, gx, gy, Color("ffffff"))
				if k2 % 2 == 0:
					px(cell, gx - 1, gy, Color(1, 1, 1, 0.45))
					px(cell, gx + 1, gy, Color(1, 1, 1, 0.45))
					px(cell, gx, gy - 1, Color(1, 1, 1, 0.45))
					px(cell, gx, gy + 1, Color(1, 1, 1, 0.45))


## Кролик / сапфировый заяц: круглое тело, большие задние лапы, длинные уши
func _bunny(cell: Image, p: Dictionary, sp: Dictionary, b: Array, dark: Array, ground: float, W: int) -> void:
	var w: int = cell.get_width()
	var h: int = cell.get_height()
	var lie: bool = p["lie"]
	var up: float = p["up"]
	var cy: float = ground - 10.0 - float(p["hop"]) + float(p["bob"]) * 0.5
	if lie:
		cy = ground - 7.0
	var cx: float = w * 0.56
	# хвостик
	var tl: Image = _lay(w, h)
	rell(tl, Vector2(cx + 11.0, cy - 2.0 - up * 3.0), 3.5, 3.0, 0.0, hx(["c8c0bc", "e0dad6", "f4f0ee", "ffffff", "ffffff"]), 2)
	# задняя лапа (большая)
	var hl: Image = _lay(w, h)
	if not lie:
		var st: float = sin(float(p["ph"])) * 3.0 if p["walk"] else 0.0
		rell(hl, Vector2(cx + 5.0, cy + 4.0), 6.0, 5.0, 0.0, b, 3)
		rell(hl, Vector2(cx + 4.0 + st, ground - 1.5), 6.0, 2.0, 0.0, b, 2)
	# тело
	var bd: Image = _lay(w, h)
	rell(bd, Vector2(cx, cy - up * 4.0), 11.0 - up * 3.0, 8.0 + up * 3.0, -up * 0.9, b, 3)
	rell(bd, Vector2(cx - 5.0, cy + 3.0 - up * 4.0), 5.0, 4.0, 0.0, [Color(sp["belly"]).darkened(0.1), Color(sp["belly"]), Color(sp["belly"]).lightened(0.3)], 1)
	# передние лапки
	var fl: Image = _lay(w, h)
	if not lie:
		var fx: float = float(p["front"]) * 2.0
		var sw: float = sin(float(p["ph"]) + PI) * 3.0 if p["walk"] else 0.0
		if up > 0.3:
			capsule(fl, Vector2(cx - 7.0, cy - 2.0), Vector2(cx - 10.0, cy + 1.0), 1.8, 1.6, b, 4)
		else:
			capsule(fl, Vector2(cx - 7.0, cy + 2.0), Vector2(cx - 8.0 + sw + fx, ground - 1.0 - absf(fx)), 2.0, 1.8, b, 4)
	# голова
	var hd: Image = _lay(w, h)
	var hdn: float = float(p["head"])
	var hc: Vector2 = Vector2(cx - 11.0 - hdn * 2.0, cy - 6.0 + hdn * 8.0 - up * 7.0)
	if lie:
		hc = Vector2(cx - 11.0, cy - 2.0)
	rell(hd, hc, 7.0, 6.0, 0.0, b, 4)
	rell(hd, hc + Vector2(-4.0, 2.5), 3.2, 2.6, 0.0, [Color(sp["belly"]).darkened(0.1), Color(sp["belly"]), Color(sp["belly"]).lightened(0.3)], 1)
	px(hd, int(hc.x - 7.0), int(hc.y + 1.0), Color(sp["inner"]).darkened(0.2))
	if p["mouth"]:
		px(hd, int(hc.x - 6.0), int(hc.y + 3.0), OUTL)
	ceye(hd, hc + Vector2(-2.0, -1.0), true, bool(p["blink"]))
	# уши
	var er: Image = _lay(w, h)
	var ear_a: float = -0.25 if not lie else 0.9
	for k in range(2):
		var base: Vector2 = hc + Vector2(2.0 + k * 2.5, -4.0)
		var tip: Vector2 = base + Vector2(sin(ear_a + k * 0.25) * 12.0, -cos(ear_a + k * 0.25) * 12.0)
		if lie:
			tip = base + Vector2(10.0, 3.0 + k * 2.0)
		capsule(er, base, tip, 2.4, 2.0, b if k == 1 else dark, 4)
		if k == 1:
			capsule(er, base.lerp(tip, 0.2), base.lerp(tip, 0.8), 0.9, 0.7, [Color(sp["inner"]), Color(sp["inner"]), Color(sp["inner"])], 1)


## Лиса: длинное тело, тонкие ноги в «носочках», острая морда, пушистый хвост
func _fox(cell: Image, p: Dictionary, sp: Dictionary, b: Array, dark: Array, ground: float, W: int) -> void:
	var w: int = cell.get_width()
	var h: int = cell.get_height()
	var crouch: float = p["crouch"]
	var cy: float = ground - 18.0 - float(p["hop"]) + float(p["bob"]) + crouch * 5.0
	var cx: float = w * 0.52
	var sock: Color = Color(sp["sock"])
	var bel: Array = [Color(sp["belly"]).darkened(0.12), Color(sp["belly"]), Color(sp["belly"]).lightened(0.4)]
	if p["curl"]:
		# спит клубком: хвост укрывает нос
		var tl0: Image = _lay(w, h)
		rell(tl0, Vector2(cx, ground - 9.0 - float(p["bob"]) * 0.5), 17.0, 9.0, 0.0, b, 3)
		var hd0: Image = _lay(w, h)
		rell(hd0, Vector2(cx - 8.0, ground - 9.0), 7.0, 5.5, 0.1, b, 4)
		tri(hd0, Vector2(cx - 6.0, ground - 13.0), Vector2(cx - 1.0, ground - 13.0), Vector2(cx - 2.0, ground - 20.0), func(_x: int, _y: int, u: float) -> Color: return b[4] if u < 0.5 else b[2])
		ceye(hd0, Vector2(cx - 10.0, ground - 10.0), false, true)
		var tl1: Image = _lay(w, h)
		rell(tl1, Vector2(cx - 4.0, ground - 4.0), 15.0, 4.5, 0.05, b, 4)
		rell(tl1, Vector2(cx - 17.0, ground - 4.5), 4.5, 3.5, 0.0, bel, 1)
		return
	# хвост
	var tl: Image = _lay(w, h)
	var ta: float = -0.35 - float(p["tail"]) * 0.35
	var tbase: Vector2 = Vector2(cx + 14.0, cy - 2.0)
	var tc: Vector2 = tbase + Vector2(cos(ta) * 11.0, sin(ta) * 11.0)
	rell(tl, tc, 12.0, 5.5, ta, b, 4)
	var tip: Vector2 = tbase + Vector2(cos(ta) * 21.0, sin(ta) * 21.0)
	rell(tl, tip, 4.5, 4.0, ta, bel, 1)
	if sp.get("flame", false):
		for k in range(10):
			var fp: Vector2 = tip + Vector2(h01(k, int(float(p["ph"]) * 10.0), 7) * 8.0 - 2.0, -h01(k, int(float(p["tail"]) * 10.0) + 3, 9) * 9.0)
			px(tl, int(fp.x), int(fp.y), [Color("ffe070"), Color("ff9a30"), Color("fff4b0")][k % 3])
	# дальние ноги
	var fl0: Image = _lay(w, h)
	var legs_x: Array = [cx - 10.0, cx + 10.0]
	for i in range(2):
		var ph: float = float(p["ph"]) + PI + float(i) * PI
		var sw: float = sin(ph) * 4.0 if p["walk"] else 0.0
		var lift: float = maxf(0.0, cos(ph)) * 2.0 if p["walk"] else 0.0
		var foot: Vector2 = Vector2(float(legs_x[i]) + sw + 1.0, ground - lift)
		if float(p["hop"]) > 3.0:
			foot = Vector2(float(legs_x[i]) + (-6.0 if i == 0 else 6.0), cy + 10.0)
		cleg(fl0, Vector2(float(legs_x[i]) + 1.0, cy + 2.0), foot, 2.0, 1.4, dark, 3, sock, i == 1)
	# тело
	var bd: Image = _lay(w, h)
	rell(bd, Vector2(cx, cy), 15.0, 7.0 - crouch, 0.0, b, 3)
	rell(bd, Vector2(cx - 9.0, cy + 2.5), 6.0, 4.0, 0.0, bel, 1)
	# ближние ноги
	var fl1: Image = _lay(w, h)
	for i2 in range(2):
		var ph2: float = float(p["ph"]) + float(i2) * PI
		var sw2: float = sin(ph2) * 4.0 if p["walk"] else 0.0
		var lift2: float = maxf(0.0, cos(ph2)) * 2.0 if p["walk"] else 0.0
		var foot2: Vector2 = Vector2(float(legs_x[i2]) + sw2 - 1.0, ground - lift2)
		if float(p["hop"]) > 3.0:
			foot2 = Vector2(float(legs_x[i2]) + (-8.0 if i2 == 0 else 8.0), cy + 9.0)
		cleg(fl1, Vector2(float(legs_x[i2]) - 1.0, cy + 3.0), foot2, 2.2, 1.5, b, 3, sock, i2 == 1)
	# голова
	var hd: Image = _lay(w, h)
	var hdn: float = float(p["head"])
	var hc: Vector2 = Vector2(cx - 18.0, cy - 7.0 + hdn * 9.0)
	rell(hd, hc, 7.0, 6.0, 0.0, b, 4)
	# острая морда
	tri(hd, hc + Vector2(-3.0, -1.0), hc + Vector2(-3.0, 5.0), hc + Vector2(-13.0, 3.5 + hdn * 1.5), func(_x: int, _y: int, u: float) -> Color: return b[4] if u < 0.4 else b[3])
	tri(hd, hc + Vector2(-3.0, 3.0), hc + Vector2(-3.0, 5.5), hc + Vector2(-12.0, 4.5 + hdn * 1.5), func(_x: int, _y: int, _u: float) -> Color: return bel[1])
	px(hd, int(hc.x - 13.0), int(hc.y + 3.0 + hdn * 1.5), OUTL)
	px(hd, int(hc.x - 13.0), int(hc.y + 4.0 + hdn * 1.5), OUTL)
	ceye(hd, hc + Vector2(-2.0, -1.0), false, bool(p["blink"]))
	# уши с тёмными кончиками
	var er: Image = _lay(w, h)
	for k2 in range(2):
		var ex: float = hc.x + 1.0 + k2 * 4.0
		tri(er, Vector2(ex - 3.0, hc.y - 3.0), Vector2(ex + 3.0, hc.y - 3.0), Vector2(ex + 0.5, hc.y - 12.0), func(_x: int, y: int, u: float) -> Color: return sock if y < int(hc.y) - 9 else (b[4] if u < 0.5 else b[2]))


## Олень и единорог: высокие ноги, шея, голова; у оленя рога и пятнышки, у единорога рог, грива, хвост-радуга
func _deer(cell: Image, p: Dictionary, sp: Dictionary, b: Array, dark: Array, ground: float, W: int) -> void:
	var w: int = cell.get_width()
	var h: int = cell.get_height()
	var horse: bool = sp["kind"] == "horse"
	var lie: bool = p["lie"]
	var leg_l: float = 22.0 if horse else 18.0
	var cy: float = ground - leg_l - 4.0 + float(p["bob"])
	if lie:
		cy = ground - 10.0
	var cx: float = w * 0.55
	var tilt: float = p["tilt"]
	var bel: Array = [Color(sp["belly"]).darkened(0.12), Color(sp["belly"]), Color(sp["belly"]).lightened(0.4)]
	var hoof: Color = Color("3a2a2a") if not horse else Color("c8a060")
	var front_hip: Vector2 = Vector2(cx - 12.0, cy + 4.0).rotated(0)
	var back_hip: Vector2 = Vector2(cx + 13.0, cy + 4.0)
	if tilt != 0.0:
		front_hip = Vector2(cx + 13.0, cy) + (Vector2(-25.0, 4.0)).rotated(tilt)
	# хвост
	var tl: Image = _lay(w, h)
	if horse:
		var mane: Array = sp["mane"]
		for k in range(5):
			var a0: Vector2 = Vector2(cx + 19.0, cy - 4.0 + k * 1.2)
			var a1: Vector2 = a0 + Vector2(8.0 + k, 10.0 + k * 3.0 - float(p["tail"]) * 4.0)
			capsule(tl, a0, a1, 2.2, 1.4, [mane[k].darkened(0.3), mane[k].darkened(0.15), mane[k], mane[k].lightened(0.2), mane[k].lightened(0.4)], 2)
	else:
		rell(tl, Vector2(cx + 19.0, cy - 5.0), 3.0, 2.5, -0.4, bel, 1)
	# дальние ноги
	var fl0: Image = _lay(w, h)
	if not lie:
		for i in range(2):
			var hip: Vector2 = [front_hip, back_hip][i] + Vector2(1.0, 0)
			var ph: float = float(p["ph"]) + PI + float(i) * PI
			var sw: float = sin(ph) * 5.0 if p["walk"] else 0.0
			var lift: float = maxf(0.0, cos(ph)) * 3.0 if p["walk"] else 0.0
			var foot: Vector2 = Vector2(hip.x + sw, ground - lift)
			if tilt != 0.0 and i == 0:
				foot = hip + Vector2(-6.0, 12.0)
			cleg(fl0, hip, foot, 2.6, 1.6, dark, 3, hoof, i == 1)
	# тело
	var bd: Image = _lay(w, h)
	rell(bd, Vector2(cx, cy), 19.0 if horse else 17.0, 10.0 if horse else 9.0, tilt, b, 3)
	rell(bd, Vector2(cx - 2.0, cy + 5.0), 11.0, 3.5, tilt, bel, 1)
	if sp.get("spots", false):
		for k3 in range(7):
			var sp2: Vector2 = Vector2(cx - 8.0 + k3 * 4.0, cy - 4.0 + (k3 % 2) * 2.0)
			px(bd, int(sp2.x), int(sp2.y), b[6])
	# ближние ноги
	var fl1: Image = _lay(w, h)
	if not lie:
		for i2 in range(2):
			var hip2: Vector2 = [front_hip, back_hip][i2] - Vector2(1.0, -1.0)
			var ph2: float = float(p["ph"]) + float(i2) * PI
			var sw2: float = sin(ph2) * 5.0 if p["walk"] else 0.0
			var lift2: float = maxf(0.0, cos(ph2)) * 3.0 if p["walk"] else 0.0
			var foot2: Vector2 = Vector2(hip2.x + sw2, ground - lift2)
			if tilt != 0.0 and i2 == 0:
				foot2 = hip2 + Vector2(-10.0, 8.0)
			cleg(fl1, hip2, foot2, 2.8, 1.7, b, 3, hoof, i2 == 1)
	else:
		capsule(fl1, Vector2(cx - 10.0, ground - 4.0), Vector2(cx - 20.0, ground - 2.0), 2.4, 2.0, b, 3)
	# шея и голова
	var hd: Image = _lay(w, h)
	var hdn: float = float(p["head"])
	var neck0: Vector2 = Vector2(cx - 13.0, cy - 3.0)
	if tilt != 0.0:
		neck0 = Vector2(cx + 13.0, cy) + Vector2(-26.0, -4.0).rotated(tilt)
	var hc: Vector2 = neck0 + Vector2(-8.0 - hdn * 4.0, -16.0 + hdn * (leg_l + 10.0))
	if lie:
		hc = neck0 + Vector2(-8.0, -12.0 + hdn * 6.0)
	capsule(hd, neck0, hc + Vector2(2.0, 2.0), 5.5 if horse else 4.5, 3.5, b, 4)
	if horse:
		rell(hd, hc, 6.5, 5.5, 0.5 + hdn * 0.6, b, 4)
		rell(hd, hc + Vector2(-6.0, 3.0 + hdn * 2.0), 4.0, 3.5, 0.3, b, 4)
		px(hd, int(hc.x - 9.0), int(hc.y + 3.0 + hdn * 2.0), b[1])
		if p["mouth"]:
			px(hd, int(hc.x - 8.0), int(hc.y + 6.0), OUTL)
		px(hd, int(hc.x - 1.0), int(hc.y + 1.0), Color("f8a8c8"))
	else:
		rell(hd, hc, 5.5, 5.0, 0.0, b, 4)
		rell(hd, hc + Vector2(-5.0, 2.0 + hdn), 3.5, 2.8, 0.2, b, 4)
		px(hd, int(hc.x - 8.0), int(hc.y + 2.0 + hdn), OUTL)
		if int(p["chew"]) == 1:
			px(hd, int(hc.x - 6.0), int(hc.y + 5.0 + hdn), OUTL)
	ceye(hd, hc + Vector2(-1.5, -1.0), true, bool(p["blink"]))
	# грива единорога / уши
	var er: Image = _lay(w, h)
	tri(er, hc + Vector2(1.0, -3.0), hc + Vector2(5.0, -2.0), hc + Vector2(5.0, -9.0), func(_x: int, _y: int, u: float) -> Color: return b[4] if u < 0.5 else b[2])
	if horse:
		var mane2: Array = sp["mane"]
		for k4 in range(7):
			var mp: Vector2 = hc.lerp(neck0, float(k4) / 6.0) + Vector2(4.0, -3.0)
			rell(er, mp + Vector2(2.0, 2.0), 3.0, 2.2, 0.8, [mane2[k4 % 5].darkened(0.25), mane2[k4 % 5], mane2[k4 % 5].lightened(0.25)], 1)
		# рог спиралью
		var hb: Vector2 = hc + Vector2(-2.0, -5.0)
		for k5 in range(10):
			var q: Vector2 = hb + Vector2(-k5 * 0.6, -k5 * 1.0)
			px(er, int(q.x), int(q.y), Color(sp["horn"]) if k5 % 3 != 0 else Color(sp["horn"]).darkened(0.3))
			px(er, int(q.x) + 1, int(q.y), Color(sp["horn"]).lightened(0.3))
	elif sp.has("antlers"):
		var ac: Color = Color(sp["antlers"])
		var ab: Vector2 = hc + Vector2(1.0, -4.0)
		for k6 in range(2):
			var o: Vector2 = ab + Vector2(k6 * 3.0, 0)
			line(er, int(o.x), int(o.y), int(o.x + 3), int(o.y - 9), ac)
			line(er, int(o.x + 1), int(o.y - 4), int(o.x - 3), int(o.y - 8), ac)
			line(er, int(o.x + 3), int(o.y - 9), int(o.x + 7), int(o.y - 12), ac)
			line(er, int(o.x + 3), int(o.y - 9), int(o.x + 1), int(o.y - 14), ac)


## Кабан: тяжёлое тело, короткие ноги, гребень щетины, клыки, розовый пятачок
func _boar(cell: Image, p: Dictionary, sp: Dictionary, b: Array, dark: Array, ground: float, W: int) -> void:
	var w: int = cell.get_width()
	var h: int = cell.get_height()
	var lie: bool = p["lie"]
	var cy: float = ground - 17.0 + float(p["bob"])
	if lie:
		cy = ground - 11.0
	var cx: float = w * 0.56
	var hoof: Color = Color("1a1214")
	var tl: Image = _lay(w, h)
	var tb: Vector2 = Vector2(cx + 19.0, cy - 4.0)
	line(tl, int(tb.x), int(tb.y), int(tb.x + 3), int(tb.y - 2 - float(p["tail"]) * 2.0), b[2])
	line(tl, int(tb.x + 3), int(tb.y - 2 - float(p["tail"]) * 2.0), int(tb.x + 4), int(tb.y + 1), b[2])
	var fl0: Image = _lay(w, h)
	var lx: Array = [cx - 11.0, cx + 11.0]
	if not lie:
		for i in range(2):
			var ph: float = float(p["ph"]) + PI + float(i) * PI
			var sw: float = sin(ph) * 3.0 if p["walk"] else 0.0
			cleg(fl0, Vector2(float(lx[i]) + 1.0, cy + 6.0), Vector2(float(lx[i]) + sw + 1.0, ground), 3.2, 2.4, dark, 3, hoof, false)
	var bd: Image = _lay(w, h)
	rell(bd, Vector2(cx, cy), 20.0, 12.0, 0.0, b, 3)
	# гребень щетины
	for x in range(int(cx - 16.0), int(cx + 14.0)):
		var yt: float = cy - 11.0 + pow((x - cx + 2.0) / 18.0, 2.0) * 6.0
		px(bd, x, int(yt), b[0])
		if posmod(x, 2) == 0:
			px(bd, x, int(yt) - 1, b[1])
			px(bd, x + 1, int(yt) - 2, b[0])
	var fl1: Image = _lay(w, h)
	if not lie:
		for i2 in range(2):
			var ph2: float = float(p["ph"]) + float(i2) * PI
			var sw2: float = sin(ph2) * 3.0 if p["walk"] else 0.0
			cleg(fl1, Vector2(float(lx[i2]) - 1.0, cy + 7.0), Vector2(float(lx[i2]) + sw2 - 1.0, ground), 3.4, 2.6, b, 3, hoof, false)
	var hd: Image = _lay(w, h)
	var hdn: float = float(p["head"])
	var hc: Vector2 = Vector2(cx - 20.0, cy - 2.0 + hdn * 7.0)
	rell(hd, hc, 9.0, 8.0, 0.25 + hdn * 0.3, b, 4)
	var sn: Vector2 = hc + Vector2(-9.0, 3.0 + hdn * 2.0)
	var snc: Color = Color(sp["snout"])
	rell(hd, sn, 3.0, 3.8, 0.0, [snc.darkened(0.3), snc.darkened(0.12), snc, snc.lightened(0.25)], 2)
	px(hd, int(sn.x) - 1, int(sn.y), Color("5a3438"))
	px(hd, int(sn.x) - 1, int(sn.y) + 2, Color("5a3438"))
	# клыки
	px(hd, int(sn.x) + 2, int(sn.y) + 2, Color("f6f0e0"))
	px(hd, int(sn.x) + 2, int(sn.y) + 1, Color("f6f0e0"))
	px(hd, int(sn.x) + 1, int(sn.y), Color("f6f0e0"))
	ceye(hd, hc + Vector2(-3.0, -2.0), false, bool(p["blink"]))
	var er: Image = _lay(w, h)
	tri(er, hc + Vector2(1.0, -6.0), hc + Vector2(6.0, -5.0), hc + Vector2(5.0, -12.0), func(_x: int, _y: int, u: float) -> Color: return b[3] if u < 0.5 else b[1])


## Ёжик: купол из иголок, светлая мордочка с чёрным носиком; спит клубком
func _hedgehog(cell: Image, p: Dictionary, sp: Dictionary, b: Array, ground: float, W: int) -> void:
	var w: int = cell.get_width()
	var h: int = cell.get_height()
	var curl: bool = p["curl"]
	var cx: float = w * 0.56
	var cy: float = ground - 9.0 + float(p["bob"]) * 0.5
	var bel: Color = Color(sp["belly"])
	var fl: Image = _lay(w, h)
	if not curl:
		for i in range(2):
			var sw: float = sin(float(p["ph"]) + i * PI) * 2.0 if p["walk"] else 0.0
			rect(fl, int(cx - 7.0 + i * 12.0 + sw), int(ground) - 2, 3, 3, Color("4a3428"))
	var hd: Image = _lay(w, h)
	if not curl:
		var hdn: float = float(p["head"])
		var hc: Vector2 = Vector2(cx - 12.0, cy + 1.0 + hdn * 3.0)
		rell(hd, hc, 6.0, 4.5, 0.15, [bel.darkened(0.3), bel.darkened(0.15), bel, bel.lightened(0.2), bel.lightened(0.4)], 2)
		tri(hd, hc + Vector2(-3.0, -2.0), hc + Vector2(-3.0, 3.0), hc + Vector2(-10.0, 2.0 + (1.0 if p["mouth"] else 0.0)), func(_x: int, _y: int, u: float) -> Color: return bel if u < 0.5 else bel.darkened(0.15))
		rect(hd, int(hc.x - 11.0), int(hc.y + 1.0 + (1.0 if p["mouth"] else 0.0)), 2, 2, OUTL)
		ceye(hd, hc + Vector2(-2.0, -1.0), false, bool(p["blink"]))
	var bd: Image = _lay(w, h)
	var rx: float = 13.0 if not curl else 11.0
	var ry: float = 9.0 if not curl else 10.0
	var bc: Vector2 = Vector2(cx + (0.0 if not curl else -2.0), ground - ry + 1.0)
	rell(bd, bc, rx, ry, 0.0, b, 3)
	# иголки: короткие штрихи от центра наружу
	for k in range(46):
		var a: float = PI + float(k) / 45.0 * PI * (1.0 if not curl else 2.0)
		var r0: float = 0.55 + h01(k, 3, 11) * 0.3
		var s0: Vector2 = bc + Vector2(cos(a) * rx * r0, sin(a) * ry * r0)
		var s1: Vector2 = bc + Vector2(cos(a) * (rx + 2.5), sin(a) * (ry + 2.5))
		if s1.y > ground:
			continue
		line(bd, int(s0.x), int(s0.y), int(s1.x), int(s1.y), b[0] if k % 2 == 0 else b[5])
	if curl:
		ceye(bd, bc + Vector2(-6.0, 2.0), false, true)


## Белка: большой хвост-завиток, кисточки на ушах; ест орешек сидя
func _squirrel(cell: Image, p: Dictionary, sp: Dictionary, b: Array, dark: Array, ground: float, W: int) -> void:
	var w: int = cell.get_width()
	var h: int = cell.get_height()
	var up: float = p["up"]
	var cx: float = w * 0.52
	var cy: float = ground - 8.0 - float(p["hop"]) - up * 4.0 + float(p["bob"]) * 0.5
	var bel: Array = [Color(sp["belly"]).darkened(0.12), Color(sp["belly"]), Color(sp["belly"]).lightened(0.3)]
	var tl: Image = _lay(w, h)
	var tw: float = float(p["tail"])
	rell(tl, Vector2(cx + 9.0, cy - 6.0 - tw), 5.5, 9.0, 0.25 + tw * 0.15, b, 4)
	rell(tl, Vector2(cx + 6.0 + tw, cy - 16.0 - tw), 5.0, 4.0, -0.4, b, 4)
	var bd: Image = _lay(w, h)
	rell(bd, Vector2(cx, cy), 7.0 - up, 6.0 + up * 3.0, -up * 0.8, b, 3)
	rell(bd, Vector2(cx - 3.0, cy + 2.0 - up * 2.0), 3.5, 3.5 + up * 1.5, 0.0, bel, 1)
	rell(bd, Vector2(cx + 3.0, ground - 3.0), 4.5, 3.0, 0.0, b, 3)
	var fl: Image = _lay(w, h)
	if up > 0.5:
		# орешек в лапках
		capsule(fl, Vector2(cx - 4.0, cy - 2.0), Vector2(cx - 7.0, cy - 2.0), 1.4, 1.2, b, 4)
		rell(fl, Vector2(cx - 8.0, cy - 3.0), 2.5, 3.0, 0.0, hx(["5a3a1e", "7a5028", "9a6a36", "b88a4c"]), 2)
	else:
		var sw: float = sin(float(p["ph"])) * 2.0 if p["walk"] else 0.0
		capsule(fl, Vector2(cx - 4.0, cy + 2.0), Vector2(cx - 6.0 + sw, ground - 1.0), 1.5, 1.3, b, 4)
	var hd: Image = _lay(w, h)
	var hc: Vector2 = Vector2(cx - 6.0 + up * 2.0, cy - 7.0 - up * 4.0)
	rell(hd, hc, 5.5, 5.0, 0.0, b, 4)
	rell(hd, hc + Vector2(-4.0, 1.5), 2.5, 2.0, 0.0, bel, 1)
	px(hd, int(hc.x - 6.0), int(hc.y + 1.0), OUTL)
	if int(p["chew"]) == 1:
		px(hd, int(hc.x - 5.0), int(hc.y + 3.0), OUTL)
	ceye(hd, hc + Vector2(-1.5, -1.0), true, bool(p["blink"]))
	var er: Image = _lay(w, h)
	tri(er, hc + Vector2(0.0, -3.0), hc + Vector2(4.0, -3.0), hc + Vector2(2.0, -9.0), func(_x: int, y: int, u: float) -> Color: return b[1] if y < int(hc.y) - 7 else (b[4] if u < 0.5 else b[2]))


## Утка: селезень с зелёной головой, жёлтый клюв, серое тело, синее зеркальце на крыле
func _duck(cell: Image, p: Dictionary, sp: Dictionary, b: Array, ground: float, W: int) -> void:
	var w: int = cell.get_width()
	var h: int = cell.get_height()
	var sit: bool = p["lie"]
	var cx: float = w * 0.55
	var cy: float = ground - 8.0 + float(p["bob"]) * 0.5
	if sit:
		cy = ground - 6.0
	var fl: Image = _lay(w, h)
	var orange: Array = hx(["a05a10", "d0801a", "f0a028", "fcc050"])
	if not sit:
		for i in range(2):
			var sw: float = sin(float(p["ph"]) + i * PI) * 2.5 if p["walk"] else 0.0
			capsule(fl, Vector2(cx - 1.0 + i * 3.0, cy + 4.0), Vector2(cx - 1.0 + i * 3.0 + sw, ground - 1.0), 1.0, 1.0, orange, 2)
			rect(fl, int(cx - 3.0 + i * 3.0 + sw), int(ground) - 1, 4, 2, orange[2])
	var bd: Image = _lay(w, h)
	rell(bd, Vector2(cx, cy), 11.0, 7.0, 0.05, b, 3)
	tri(bd, Vector2(cx + 8.0, cy - 4.0), Vector2(cx + 9.0, cy + 2.0), Vector2(cx + 15.0, cy - 7.0), func(_x: int, _y: int, u: float) -> Color: return b[2] if u < 0.5 else b[1])
	# крыло с синим зеркальцем
	var wg: Image = _lay(w, h)
	rell(wg, Vector2(cx + 2.0, cy - 1.0), 7.0, 4.0, 0.1, [b[1], b[2], b[3], b[4]], 1)
	rect(wg, int(cx + 3.0), int(cy + 1.0), 4, 1, Color("3a5ad0"))
	var hd: Image = _lay(w, h)
	var hdn: float = float(p["head"])
	var hcol: Array = hx(sp["head"]) if sp["head"] is PackedStringArray else sp["head"]
	var hc: Vector2 = Vector2(cx - 9.0, cy - 9.0)
	if hdn < 0.0:
		hc = Vector2(cx - 9.0, cy - 12.0)       # крякает, вытянув шею
	elif hdn > 0.3:
		hc = Vector2(cx + 1.0, cy - 6.0)        # чистит пёрышки, клювом к крылу
	capsule(hd, Vector2(cx - 6.0, cy - 3.0), hc + Vector2(1.0, 2.0), 3.0, 2.5, hcol, 2)
	rect(hd, int(cx - 7.0), int(cy - 3.0), 4, 1, Color("f4f0e8"))
	rell(hd, hc, 4.5, 4.0, 0.0, hcol, 3)
	var bk: Color = Color(sp["beak"])
	var dir: float = -1.0 if hdn <= 0.3 else 1.0
	var bk0: Vector2 = hc + Vector2(dir * 3.5, 1.0)
	rect(hd, int(minf(bk0.x, bk0.x + dir * 5.0)), int(bk0.y), 5, 2 if not p["mouth"] else 1, bk)
	if p["mouth"]:
		rect(hd, int(minf(bk0.x, bk0.x + dir * 5.0)), int(bk0.y) + 2, 5, 1, bk.darkened(0.2))
	ceye(hd, hc + Vector2(-1.0 * dir * -1.0 - 1.0, -1.0), false, bool(p["blink"]) or sit)


## Сплющенный кабан: очень широкий и плоский, ножки-пуговки, полоска по спине
func _flatboar(cell: Image, p: Dictionary, sp: Dictionary, b: Array, ground: float, W: int) -> void:
	var w: int = cell.get_width()
	var h: int = cell.get_height()
	var sq: float = p["squash"]
	var flat: bool = p["lie"]
	var cx: float = w * 0.52
	var ry: float = 9.0 - sq * 1.5 - (2.0 if flat else 0.0)
	var rx: float = 32.0 + sq * 2.0 + (2.0 if flat else 0.0)
	var cy: float = ground - ry - 2.0
	var fl: Image = _lay(w, h)
	if not flat:
		for i in range(4):
			var sw: float = sin(float(p["ph"]) + i * 1.57) * 2.0 if p["walk"] else 0.0
			rect(fl, int(cx - 22.0 + i * 14.0 + sw), int(ground) - 3, 5, 3, b[1])
	var bd: Image = _lay(w, h)
	rell(bd, Vector2(cx, cy), rx, ry, 0.0, b, 3)
	for x in range(int(cx - rx * 0.8), int(cx + rx * 0.8)):
		var yt: float = cy - ry + 1.0 + pow((x - cx) / rx, 2.0) * ry * 0.7
		px(bd, x, int(yt), b[0])
		if posmod(x, 3) == 0:
			px(bd, x, int(yt) - 1, b[1])
	var hd: Image = _lay(w, h)
	var snc: Color = Color(sp["snout"])
	var sn: Vector2 = Vector2(cx - rx + 1.0, cy + 1.0)
	rell(hd, sn, 4.5, 3.5, 0.0, [snc.darkened(0.3), snc.darkened(0.12), snc, snc.lightened(0.25)], 2)
	px(hd, int(sn.x) - 2, int(sn.y), Color("5a3438"))
	px(hd, int(sn.x) - 2, int(sn.y) + 2, Color("5a3438"))
	ceye(hd, Vector2(cx - rx + 9.0, cy - 2.0), false, bool(p["blink"]))
	var er: Image = _lay(w, h)
	tri(er, Vector2(cx - rx + 12.0, cy - ry + 3.0), Vector2(cx - rx + 18.0, cy - ry + 3.0), Vector2(cx - rx + 14.0, cy - ry - 4.0 + sq), func(_x: int, _y: int, u: float) -> Color: return b[4] if u < 0.5 else b[2])
	px(er, int(cx + rx + 1.0), int(cy - 3.0), b[2])
	px(er, int(cx + rx + 2.0), int(cy - 4.0), b[2])
	px(er, int(cx + rx + 3.0), int(cy - 3.0), b[2])




# ================================================================== рабочие места и десерты v9

## Ящик/плита с объёмом: верх светлее, перед — средний, правый край темнее
func box3(im: Image, x: int, y: int, w: int, h: int, top: int, ramp: Array, tb: int) -> void:
	for yy in range(y, y + h):
		for xx in range(x, x + w):
			var t: int = tb
			if yy < y + top:
				t = tb + 2
			elif xx >= x + w - 2:
				t = tb - 1
			elif yy >= y + h - 1:
				t = tb - 2
			px(im, xx, yy, ramp[clampi(t, 0, ramp.size() - 1)])


## Кусочек торта сбоку (треугольник с коржами и кремом), как маленький значок для витрины
func cake_slice(im: Image, x: int, y: int, sponge: Color, cream: Color, top: Color, topping: Color) -> void:
	for yy in range(0, 9):
		var w: int = 4 + yy
		for xx in range(0, w):
			var c: Color = sponge
			if yy < 2:
				c = top
			elif yy % 3 == 1:
				c = cream
			if xx == w - 1:
				c = c.darkened(0.18)
			px(im, x + xx, y + yy, c)
	disc(im, x + 2, y - 1, 1.6, topping)
	px(im, x + 1, y - 2, topping.lightened(0.4))


## Рулет: спираль крема в бисквите
func roll_cake(im: Image, x: int, y: int, sponge: Color, cream: Color, topping: Color) -> void:
	disc(im, x + 4, y + 4, 4.6, sponge.darkened(0.08))
	disc(im, x + 4, y + 4, 3.6, sponge)
	for a in range(18):
		var r: float = 0.6 + a * 0.16
		var ang: float = a * 0.9
		px(im, x + 4 + int(cos(ang) * r), y + 4 + int(sin(ang) * r), cream)
	rect(im, x + 8, y + 1, 3, 7, sponge.darkened(0.15))
	disc(im, x + 4, y, 1.4, topping)


func gen_stations() -> void:
	var w8: Array = hx(LOG)
	var st: Array = hx(DSTONE)
	var bake: Array = hx(["5a2a1a", "7e3e24", "a4563a", "c47452", "dc9670", "ecb894", "f8dcc0"])
	# --- печь-пекарня: кирпичный купол, огонь в устье, противень с булочками
	var im: Image = new_img(76, 76)
	ell(im, 38, 72, 34, 4, Color(0.1, 0.08, 0.1, 0.3))
	box3(im, 8, 44, 60, 28, 4, bake, 3)
	blob(im, 38, 40, 26, 22, bake, 3)
	for k in range(9):
		for j in range(4):
			px(im, 16 + k * 6 + (j % 2) * 3, 30 + j * 6, bake[1])
	ell(im, 38, 52, 12, 9, Color("2a120a"))
	ell(im, 38, 56, 9, 4, Color("ff7a20"))
	ell(im, 38, 57, 5, 2, Color("ffd060"))
	rect(im, 50, 8, 8, 18, st[3])
	rect(im, 49, 6, 10, 3, st[5])
	box3(im, 4, 62, 26, 4, 1, hx(["3a3a44", "56565e", "7a7a84", "a0a0a8"]), 2)
	for b in range(4):
		ell(im, 8 + b * 6, 61, 2.6, 2.0, Color("d89a4a"))
		px(im, 7 + b * 6, 60, Color("f4cc84"))
	outline_auto(im, 0.45)
	save3(im, "bake_oven")
	# --- грядка пшеницы: борозды и золотые колосья
	im = new_img(124, 54)
	for y in range(30, 52):
		for x in range(2, 122):
			px(im, x, y, hx(["4a2e1c", "5e3c24", "6e4a2c"])[(y / 3 + x / 40) % 3])
	for r in range(4):
		for k2 in range(22):
			var bx: int = 6 + k2 * 5 + (r % 2) * 2
			var by: int = 34 + r * 5
			var hgt: int = 14 + int(h01(k2, r, 3) * 6.0)
			line(im, bx, by, bx + 1, by - hgt, Color("b0902e"))
			for q in range(4):
				px(im, bx + 1 + (q % 2), by - hgt + q, Color("f0cc5a") if q % 2 == 0 else Color("d8a83a"))
	outline_auto(im, 0.35)
	save3(im, "wheat_patch")
	# --- стол кондитера с тортиками и рулетами (как витрина)
	im = new_img(84, 56)
	ell(im, 42, 53, 38, 3, Color(0.1, 0.08, 0.1, 0.3))
	box3(im, 4, 26, 76, 8, 3, hx(["8a5a6a", "a87484", "c896a4", "e2b8c4", "f4d8e0"]), 2)
	for lx in [8, 72]:
		rect(im, lx, 34, 4, 18, w8[2])
	# кружевная скатерть
	for x in range(4, 80, 4):
		disc(im, x + 2, 35, 1.6, Color("fff4f8"))
	cake_slice(im, 8, 15, Color("f4d8a0"), Color("fff6ee"), Color("f8b8c8"), Color("e03040"))
	cake_slice(im, 24, 15, Color("6a3a24"), Color("c08a5a"), Color("4a2418"), Color("8a5a2a"))
	cake_slice(im, 40, 15, Color("a8c878"), Color("f6f2e0"), Color("8ab860"), Color("6a2a2a"))
	roll_cake(im, 56, 17, Color("e8c088"), Color("fff6e8"), Color("f0f0f0"))
	roll_cake(im, 68, 17, Color("7a4a2a"), Color("f4e0c8"), Color("3a2010"))
	# подставка с большим тортом
	rect(im, 36, 10, 2, 6, Color("d8d0d8"))
	outline_auto(im, 0.4)
	save3(im, "dessert_table")
	# --- ткацкий станок
	im = new_img(64, 64)
	rect(im, 6, 8, 4, 54, w8[3])
	rect(im, 54, 8, 4, 54, w8[3])
	rect(im, 4, 6, 56, 5, w8[4])
	rect(im, 4, 40, 56, 5, w8[4])
	for x2 in range(12, 52, 2):
		line(im, x2, 11, x2, 40, Color("e8e0f0"))
	for y2 in range(14, 38, 3):
		for x3 in range(12, 52):
			if (x3 + y2) % 4 < 2:
				px(im, x3, y2, Color("b88ad0") if y2 < 26 else Color("8ac0e0"))
	outline_auto(im, 0.4)
	save3(im, "loom")
	# --- клумба
	im = new_img(104, 44)
	ell(im, 52, 34, 48, 9, Color("5e3c24"))
	ell(im, 52, 32, 46, 7, Color("6e4a2c"))
	for k3 in range(26):
		var fx: int = 10 + int(h01(k3, 1, 4) * 84.0)
		var fy: int = 26 + int(h01(k3, 2, 4) * 10.0)
		line(im, fx, fy, fx, fy - 6, Color("3e7a3a"))
		disc(im, fx, fy - 7, 2.0, [Color("f06a8a"), Color("f4d050"), Color("8a9af0"), Color("ffffff"), Color("e05050")][k3 % 5])
		px(im, fx, fy - 7, Color("ffe080"))
	outline_auto(im, 0.35)
	save3(im, "flower_bed")
	# --- котёл на огне (готика и маги)
	im = new_img(60, 56)
	ell(im, 30, 52, 24, 3, Color(0.1, 0.08, 0.1, 0.3))
	for k4 in range(3):
		line(im, 12 + k4 * 18, 52, 30, 18, st[1])
	blob(im, 30, 38, 20, 13, hx(["1a1820", "26242e", "36343e", "4a4854", "605e6a"]), 2)
	ell(im, 30, 28, 18, 4, Color("40e070"))
	ell(im, 26, 27, 6, 2, Color("a0ffb0"))
	disc(im, 36, 26, 2.0, Color("80f090"))
	ell(im, 30, 52, 10, 3, Color("ff8a2a"))
	outline_auto(im, 0.4)
	save3(im, "goth_cauldron")
	# --- поленница с колодой и топором
	im = new_img(74, 50)
	for r2 in range(3):
		for k5 in range(5 - r2):
			var cx: int = 10 + k5 * 11 + r2 * 5
			var cy: int = 42 - r2 * 9
			disc(im, cx, cy, 5.2, w8[3])
			disc(im, cx, cy, 4.0, Color("c8a272"))
			disc(im, cx, cy, 1.5, Color("94683e"))
	rect(im, 58, 30, 12, 16, w8[3])
	ell(im, 64, 30, 6, 2, Color("c8a272"))
	line(im, 64, 30, 70, 14, w8[2])
	rect(im, 66, 12, 7, 5, hx(["56525c", "8c8892"])[1])
	outline_auto(im, 0.4)
	save3(im, "woodpile")
	# --- тренировочное чучело
	im = new_img(38, 64)
	rect(im, 17, 20, 4, 42, w8[3])
	rect(im, 6, 26, 26, 4, w8[3])
	blob(im, 19, 36, 9, 12, THATCH, 5)
	for y3 in range(26, 48, 4):
		line(im, 11, y3, 27, y3 + 1, Color("8a5a1a"))
	blob(im, 19, 14, 7, 7, hx(["8a7050", "a88a64", "c4a67c", "dcc298"]), 2)
	rect(im, 14, 11, 10, 2, Color("b03030"))
	outline_auto(im, 0.4)
	save3(im, "training_dummy")
	# --- точильный круг
	im = new_img(54, 50)
	rect(im, 8, 30, 38, 4, w8[4])
	for lx2 in [10, 42]:
		line(im, lx2, 34, lx2 - 3, 48, w8[2])
	disc(im, 27, 22, 13.0, st[4])
	disc(im, 27, 22, 10.0, st[5])
	disc(im, 27, 22, 2.5, w8[1])
	line(im, 27, 22, 40, 12, w8[2])
	outline_auto(im, 0.4)
	save3(im, "grindstone")
	# --- стойка с мечами
	im = new_img(62, 58)
	rect(im, 4, 44, 54, 6, w8[3])
	rect(im, 4, 20, 54, 4, w8[4])
	for k6 in range(5):
		var sx: int = 10 + k6 * 10
		rect(im, sx, 8, 3, 38, Color("c8ccd8"))
		px(im, sx + 1, 8, Color("ffffff"))
		rect(im, sx - 3, 38, 9, 2, Color("b08a28"))
		rect(im, sx, 40, 3, 6, w8[2])
	outline_auto(im, 0.4)
	save3(im, "sword_rack")
	# --- мишень лучницы
	im = new_img(46, 64)
	line(im, 10, 62, 20, 20, w8[2])
	line(im, 36, 62, 26, 20, w8[2])
	disc(im, 23, 26, 17.0, Color("f4ead8"))
	disc(im, 23, 26, 13.0, Color("d03a3a"))
	disc(im, 23, 26, 9.0, Color("f4ead8"))
	disc(im, 23, 26, 5.0, Color("d03a3a"))
	disc(im, 23, 26, 2.0, Color("f4d050"))
	line(im, 25, 24, 34, 16, w8[4])
	px(im, 35, 15, Color("ffffff"))
	outline_auto(im, 0.4)
	save3(im, "archery_target")
	# --- кафедра с книгой
	im = new_img(40, 58)
	rect(im, 16, 24, 8, 32, w8[3])
	rect(im, 10, 52, 20, 4, w8[2])
	for y4 in range(0, 10):
		rect(im, 4 + y4 / 3, 14 + y4, 32 - y4 / 2, 1, w8[4] if y4 < 8 else w8[2])
	rect(im, 8, 8, 12, 8, Color("f4ecd8"))
	rect(im, 21, 8, 12, 8, Color("ece2c8"))
	for y5 in range(10, 15, 2):
		line(im, 10, y5, 18, y5, Color("8a7a6a"))
		line(im, 23, y5, 31, y5, Color("8a7a6a"))
	outline_auto(im, 0.4)
	save3(im, "lectern")
	# --- звёздный глобус магов
	im = new_img(48, 68)
	rect(im, 20, 40, 8, 24, Color("8a8ab8"))
	rect(im, 12, 60, 24, 5, Color("5a5a8a"))
	disc(im, 24, 24, 16.0, Color("2a2a6a"))
	disc(im, 24, 24, 13.0, Color("3a3a8e"))
	for k7 in range(12):
		px(im, 12 + int(h01(k7, 2, 9) * 24.0), 12 + int(h01(k7, 3, 9) * 24.0), Color("fff4b0"))
	for a2 in range(40):
		var ang: float = a2 * 0.157
		px(im, 24 + int(cos(ang) * 18.0), 24 + int(sin(ang) * 5.0), Color("e8c860"))
	outline_auto(im, 0.4)
	save3(im, "star_globe")
	# --- вертел с мясом над огнём
	im = new_img(74, 54)
	line(im, 10, 50, 14, 16, w8[2])
	line(im, 64, 50, 60, 16, w8[2])
	line(im, 8, 18, 66, 18, IRON[3])
	blob(im, 37, 20, 14, 7, hx(["5a2410", "7e3818", "a4522a", "c8743e", "e0965a"]), 3)
	for k8 in range(8):
		disc(im, 22 + k8 * 4, 46, 3.0, [st[2], st[3], st[1]][k8 % 3])
	ell(im, 37, 42, 10, 5, Color("ff8a2a"))
	ell(im, 37, 40, 5, 3, Color("ffd060"))
	outline_auto(im, 0.4)
	save3(im, "roast_spit")
	# --- верстак гоблинши: шестерёнки, банки, инструменты
	im = new_img(84, 54)
	box3(im, 4, 22, 76, 8, 3, w8, 3)
	for lx3 in [8, 74]:
		rect(im, lx3, 30, 4, 22, w8[2])
	for k9 in range(3):
		var gx: int = 18 + k9 * 20
		disc(im, gx, 16, 6.0, [IRON[4], GOLD[3], IRON[3]][k9])
		disc(im, gx, 16, 2.0, w8[1])
		for t in range(8):
			var a3: float = t * PI / 4.0
			px(im, gx + int(cos(a3) * 7.0), 16 + int(sin(a3) * 7.0), [IRON[4], GOLD[3], IRON[3]][k9])
	rect(im, 66, 10, 8, 12, Color("6a9a5a"))
	rect(im, 66, 8, 8, 2, IRON[4])
	outline_auto(im, 0.4)
	save3(im, "tinker_bench")
	# --- бочки эля с краником
	im = new_img(84, 60)
	for k10 in range(2):
		var bx2: int = 6 + k10 * 38
		for y6 in range(22, 56):
			var hw: float = 16.0 - absf(y6 - 39.0) * 0.12
			for x6 in range(int(bx2 + 18 - hw), int(bx2 + 18 + hw)):
				px(im, x6, y6, w8[4] if x6 < bx2 + 14 else w8[3])
		for hy in [26, 38, 50]:
			rect(im, bx2 + 3, hy, 30, 2, IRON[3])
		rect(im, bx2 + 16, 44, 4, 4, GOLD[3])
	ell(im, 25, 22, 14, 3, w8[5])
	rect(im, 60, 14, 8, 8, Color("f0c050"))
	rect(im, 60, 12, 8, 3, Color("fffaf0"))
	outline_auto(im, 0.4)
	save3(im, "ale_barrels")
	# --- вагонетка с рудой
	im = new_img(74, 52)
	for y7 in range(20, 40):
		var inset: int = (y7 - 20) / 4
		for x7 in range(8 + inset, 66 - inset):
			px(im, x7, y7, IRON[3] if y7 > 22 else IRON[5])
	for k11 in range(10):
		disc(im, 14 + k11 * 5, 18 - (k11 % 3), 4.0, [st[3], st[4], Color("c0a040"), st[2]][k11 % 4])
	for wx in [18, 56]:
		disc(im, wx, 42, 6.0, IRON[1])
		disc(im, wx, 42, 2.0, IRON[4])
	rect(im, 0, 47, 74, 2, w8[2])
	outline_auto(im, 0.4)
	save3(im, "ore_cart")
	# --- превью: всё вместе
	var names: Array = ["bake_oven", "wheat_patch", "dessert_table", "loom", "flower_bed", "goth_cauldron", "woodpile", "training_dummy", "grindstone", "sword_rack", "archery_target", "lectern", "star_globe", "roast_spit", "tinker_bench", "ale_barrels", "ore_cart"]
	var pv: Image = new_img(130 * 6, 90 * 3)
	pv.fill(Color("8aa070"))
	for i in range(names.size()):
		var s: Image = Image.load_from_file(ProjectSettings.globalize_path(OUT + String(names[i]) + ".png"))
		s.convert(Image.FORMAT_RGBA8)
		pv.blend_rect(s, Rect2i(0, 0, s.get_width(), s.get_height()), Vector2i((i % 6) * 130 + 4, (i / 6) * 90 + 4))
	pv.resize(pv.get_width() * 2, pv.get_height() * 2, Image.INTERPOLATE_NEAREST)
	pv.save_png(ProjectSettings.globalize_path("res://").path_join("../screenshots/stations_v9.png"))


# ================================================================== интерьеры земель v9
# Мебель для домов: у кошек — мило и розово, у орков — грозно, у вампиров — мрачно и т.д.

func _rug(name: String, w: int, h: int, base: Color, border: Color, pattern: Color, kind: int) -> void:
	var im: Image = new_img(w, h)
	for y in range(h):
		for x in range(w):
			var dx: float = (x + 0.5 - w / 2.0) / (w / 2.0)
			var dy: float = (y + 0.5 - h / 2.0) / (h / 2.0)
			var d: float = dx * dx + dy * dy if kind != 2 else maxf(absf(dx), absf(dy))
			if d > 1.0:
				continue
			var c: Color = base
			if d > 0.8:
				c = border
			elif kind == 0 and posmod(x / 4 + y / 4, 2) == 0 and d < 0.6:
				c = pattern
			elif kind == 1 and absf(sin(x * 0.4) * 3.0 - (y - h / 2.0)) < 1.0:
				c = pattern
			elif kind == 2 and (absf(dx) < 0.08 or absf(dy) < 0.1):
				c = pattern
			elif kind == 3 and h01(x / 2, y / 2, 5) > 0.7:
				c = pattern
			px(im, x, y, c)
	save3(im, name, false)


func gen_interiors9() -> void:
	var w8: Array = hx(LOG)
	var pink: Array = hx(["8a4a6a", "b0688a", "d48aa8", "eeb0c8", "fcd6e4", "fff0f6"])
	var im: Image
	# ---------- кошки
	_rug("in9_rug_cats", 90, 48, Color("f4b8cc"), Color("d47898"), Color("fff0f6"), 0)
	im = new_img(46, 34)   # кошачья лежанка-подушка
	blob(im, 23, 24, 20, 9, pink, 3)
	blob(im, 23, 21, 14, 5, hx(["e0b0c0", "f0c8d4", "fce0ea", "fff4f8"]), 2)
	disc(im, 30, 18, 4.0, Color("f4e050"))
	outline_auto(im, 0.4)
	save3(im, "in9_cat_bed", false)
	im = new_img(34, 64)   # когтеточка-домик
	rect(im, 14, 10, 6, 52, Color("d8b880"))
	for y in range(12, 60, 3):
		line(im, 14, y, 19, y + 1, Color("b89860"))
	box3(im, 4, 54, 26, 8, 2, pink, 3)
	box3(im, 6, 4, 22, 8, 2, pink, 3)
	disc(im, 10, 16, 3.0, Color("f06a8a"))
	line(im, 10, 13, 10, 8, Color("f8f0e0"))
	outline_auto(im, 0.4)
	save3(im, "in9_cat_tree", false)
	im = new_img(36, 40)   # подставка с тортом
	rect(im, 16, 24, 4, 12, Color("e8e0e8"))
	ell(im, 18, 36, 10, 2, Color("e8e0e8"))
	ell(im, 18, 24, 14, 3, Color("f4eef4"))
	for y2 in range(8, 23):
		for x2 in range(6, 30):
			px(im, x2, y2, Color("f8c8d8") if y2 < 12 else (Color("fff4f0") if y2 % 5 == 0 else Color("f4d8a0")))
	for k in range(5):
		disc(im, 8 + k * 5, 7, 2.0, Color("e03040"))
	outline_auto(im, 0.4)
	save3(im, "in9_cake_stand", false)
	im = new_img(30, 20)   # клубки
	for k2 in range(3):
		disc(im, 8 + k2 * 7, 12 - (k2 % 2) * 3, 5.0, [Color("f08aa8"), Color("8ac0f0"), Color("f4d050")][k2])
		line(im, 5 + k2 * 7, 10, 11 + k2 * 7, 14, Color(1, 1, 1, 0.6))
	outline_auto(im, 0.4)
	save3(im, "in9_yarn", false)
	# ---------- орки
	_rug("in9_rug_orcs", 92, 50, Color("8a6a4a"), Color("5a3e28"), Color("a88a64"), 3)
	im = new_img(50, 42)   # лежанка из шкур
	box3(im, 4, 22, 42, 14, 3, w8, 3)
	blob(im, 25, 22, 22, 9, hx(["3a2a20", "54402e", "6e563e", "8a7050", "a68c68"]), 3)
	for k3 in range(6):
		line(im, 8 + k3 * 7, 18, 10 + k3 * 7, 26, Color("2a1c14"))
	disc(im, 10, 14, 5.0, Color("e8e0d0"))
	px(im, 8, 13, Color("2a1c14"))
	px(im, 12, 13, Color("2a1c14"))
	outline_auto(im, 0.4)
	save3(im, "in9_orc_bed", false)
	im = new_img(48, 50)   # стена с оружием
	rect(im, 4, 6, 40, 40, w8[2])
	for y3 in range(6, 46, 8):
		line(im, 4, y3, 43, y3, w8[1])
	line(im, 10, 40, 38, 10, IRON[4])
	line(im, 10, 10, 38, 40, IRON[4])
	rect(im, 34, 6, 9, 8, IRON[3])
	disc(im, 24, 25, 8.0, Color("8a2a20"))
	disc(im, 24, 25, 3.0, IRON[4])
	outline_auto(im, 0.4)
	save3(im, "in9_weapon_wall", false)
	im = new_img(44, 40)   # полка с черепами
	rect(im, 2, 20, 40, 4, w8[3])
	rect(im, 2, 36, 40, 4, w8[3])
	for k4 in range(3):
		disc(im, 9 + k4 * 13, 14, 5.0, Color("ece4d4"))
		rect(im, 6 + k4 * 13, 16, 7, 4, Color("ece4d4"))
		px(im, 7 + k4 * 13, 13, Color("2a1c14"))
		px(im, 11 + k4 * 13, 13, Color("2a1c14"))
	for k5 in range(4):
		rect(im, 6 + k5 * 9, 28, 6, 8, [Color("8a3a2a"), Color("5a7a3a"), Color("6a5a3a"), Color("8a6a2a")][k5])
	outline_auto(im, 0.4)
	save3(im, "in9_skull_shelf", false)
	im = new_img(50, 34)   # грубый стол с костью
	box3(im, 2, 10, 46, 8, 3, w8, 3)
	for lx in [6, 40]:
		rect(im, lx, 18, 5, 14, w8[2])
	blob(im, 22, 7, 8, 4, hx(["7e3818", "a4522a", "c8743e", "e0965a"]), 2)
	line(im, 28, 6, 36, 4, Color("ece4d4"))
	outline_auto(im, 0.4)
	save3(im, "in9_orc_table", false)
	# ---------- готика
	_rug("in9_rug_gothic", 90, 48, Color("6a1828"), Color("2a0a12"), Color("a02a3a"), 2)
	im = new_img(30, 64)   # гроб-кровать стоя у стены
	for y4 in range(4, 62):
		var hw: float = 9.0 + minf(float(y4 - 4), 14.0) * 0.35 - maxf(0.0, float(y4 - 20)) * 0.12
		for x4 in range(int(15 - hw), int(15 + hw)):
			px(im, x4, y4, Color("2a1e26") if x4 > 15 + hw - 3 else Color("3e2c38"))
	rect(im, 13, 16, 4, 20, Color("c8a040"))
	rect(im, 9, 22, 12, 4, Color("c8a040"))
	outline_auto(im, 0.4)
	save3(im, "in9_coffin", false)
	im = new_img(30, 56)   # канделябр
	rect(im, 13, 14, 4, 38, Color("a08a40"))
	ell(im, 15, 52, 9, 3, Color("a08a40"))
	line(im, 5, 18, 25, 18, Color("a08a40"))
	for k6 in range(3):
		rect(im, 4 + k6 * 10, 8, 3, 10, Color("f0ece0"))
		disc(im, 5 + k6 * 10, 5, 2.0, Color("ffc040"))
		px(im, 5 + k6 * 10, 3, Color("fff0a0"))
	outline_auto(im, 0.4)
	save3(im, "in9_candelabra", false)
	im = new_img(36, 52)   # зеркало в чёрной раме
	ell(im, 18, 22, 15, 20, Color("2a1e26"))
	ell(im, 18, 22, 11, 16, Color("9aa8c8"))
	line(im, 12, 14, 20, 8, Color("e0e8f8"))
	rect(im, 10, 42, 16, 8, Color("2a1e26"))
	outline_auto(im, 0.4)
	save3(im, "in9_goth_mirror", false)
	im = new_img(32, 36)   # портрет графини
	rect(im, 2, 2, 28, 32, Color("b08a30"))
	rect(im, 5, 5, 22, 26, Color("3a2030"))
	disc(im, 16, 15, 5.0, Color("f0dcd4"))
	rect(im, 9, 20, 14, 11, Color("8a1a2a"))
	rect(im, 10, 9, 12, 4, Color("1a1018"))
	outline_auto(im, 0.4)
	save3(im, "in9_portrait", false)
	# ---------- рыцари
	_rug("in9_rug_knights", 92, 48, Color("2a4a8a"), Color("c8a040"), Color("4a6ab0"), 2)
	im = new_img(30, 60)   # доспехи на стойке
	rect(im, 13, 40, 4, 18, w8[2])
	rect(im, 6, 56, 18, 3, w8[2])
	blob(im, 15, 30, 9, 11, IRON, 4)
	blob(im, 15, 12, 7, 8, IRON, 4)
	rect(im, 10, 12, 10, 2, Color("1a1820"))
	line(im, 15, 4, 15, 1, Color("c03030"))
	outline_auto(im, 0.4)
	save3(im, "in9_armor", false)
	im = new_img(26, 50)   # знамя
	rect(im, 2, 2, 22, 3, w8[3])
	for y5 in range(5, 46):
		var cut: int = maxi(0, y5 - 38)
		for x5 in range(4, 22):
			if absf(x5 - 13.0) < float(cut):
				continue
			px(im, x5, y5, Color("b02a2a") if x5 > 6 else Color("8a1a1a"))
	disc(im, 13, 20, 5.0, Color("e8c050"))
	outline_auto(im, 0.4)
	save3(im, "in9_banner", false)
	# ---------- эльфы
	_rug("in9_rug_elves", 90, 48, Color("6aa878"), Color("3a7a52"), Color("b4e0a0"), 1)
	im = new_img(48, 40)   # кровать-лист
	blob(im, 24, 26, 22, 10, hx(["2a5a3a", "3a7a4a", "52985e", "72b474", "98cc8e"]), 3)
	line(im, 4, 26, 44, 24, Color("2a5a3a"))
	blob(im, 14, 20, 7, 4, hx(["d8e8d0", "eef6e8", "ffffff"]), 1)
	outline_auto(im, 0.4)
	save3(im, "in9_leaf_bed", false)
	im = new_img(36, 54)   # большое растение в горшке
	box3(im, 10, 38, 16, 14, 2, hx(["6a4a8a", "8a6aaa", "aa8acc", "ccaee8"]), 2)
	for k7 in range(9):
		var a: float = -PI * 0.9 + k7 * 0.22
		capsule(im, Vector2(18, 38), Vector2(18 + cos(a) * 18.0, 38 + sin(a) * 30.0), 1.5, 3.0, MINT, 4)
	outline_auto(im, 0.4)
	save3(im, "in9_plant", false)
	im = new_img(22, 48)   # лунная лампа
	rect(im, 9, 14, 4, 32, Color("c8d8e0"))
	disc(im, 11, 9, 7.0, Color("b0f0f0"))
	disc(im, 9, 7, 2.0, Color("ffffff"))
	outline_auto(im, 0.4)
	save3(im, "in9_moon_lamp", false)
	# ---------- маги
	_rug("in9_rug_mages", 90, 48, Color("3a3a7a"), Color("c8a040"), Color("f4e080"), 3)
	im = new_img(30, 36)   # хрустальный шар
	disc(im, 15, 13, 11.0, Color("8ab0f0"))
	disc(im, 12, 10, 4.0, Color("e0f0ff"))
	box3(im, 6, 24, 18, 10, 2, hx(["3a2a5a", "5a4a7a", "7a6a9a", "9a8aba"]), 2)
	outline_auto(im, 0.4)
	save3(im, "in9_crystal_ball", false)
	im = new_img(34, 30)   # стопка книг
	for k8 in range(5):
		rect(im, 4 + (k8 % 2) * 3, 24 - k8 * 5, 24, 5, [Color("8a2a2a"), Color("2a5a8a"), Color("5a8a3a"), Color("8a6a2a"), Color("6a3a8a")][k8])
		rect(im, 6 + (k8 % 2) * 3, 25 - k8 * 5, 20, 1, Color("f0e8d8"))
	outline_auto(im, 0.4)
	save3(im, "in9_books", false)
	im = new_img(46, 54)   # полка с зельями
	rect(im, 2, 2, 42, 50, w8[2])
	for sy in [16, 32, 48]:
		rect(im, 2, sy, 42, 3, w8[4])
	for k9 in range(9):
		var bx: int = 6 + (k9 % 3) * 13
		var by: int = 6 + (k9 / 3) * 16
		disc(im, bx + 3, by + 6, 4.0, [Color("e05080"), Color("50c0e0"), Color("80e060"), Color("f0c040"), Color("a070f0")][k9 % 5])
		rect(im, bx + 2, by, 3, 3, Color("d8c8b0"))
	outline_auto(im, 0.4)
	save3(im, "in9_potion_shelf", false)
	# ---------- дворфы
	_rug("in9_rug_dwarves", 92, 48, Color("8a5a3a"), Color("4a2e1e"), Color("c89050"), 2)
	im = new_img(52, 56)   # каменный очаг
	stone_wall(im, Rect2i(2, 8, 48, 46), hx(DSTONE), 6, 8, 12, Color(hx(DSTONE)[1]), 0.55)
	rect(im, 12, 26, 28, 24, Color("2a120a"))
	ell(im, 26, 46, 10, 4, Color("ff7a20"))
	ell(im, 26, 45, 5, 2, Color("ffd060"))
	outline_auto(im, 0.4)
	save3(im, "in9_hearth", false)
	im = new_img(34, 40)   # бочонок эля с кружками
	for y6 in range(8, 38):
		var hw2: float = 13.0 - absf(y6 - 23.0) * 0.1
		for x6 in range(int(17 - hw2), int(17 + hw2)):
			px(im, x6, y6, w8[4] if x6 < 14 else w8[3])
	for hy in [12, 23, 34]:
		rect(im, 4, hy, 26, 2, IRON[3])
	rect(im, 24, 2, 8, 8, Color("f0c050"))
	rect(im, 24, 1, 8, 2, Color("fffaf0"))
	outline_auto(im, 0.4)
	save3(im, "in9_keg", false)
	im = new_img(40, 40)   # кирки на стене
	line(im, 8, 36, 30, 6, w8[3])
	line(im, 32, 36, 10, 6, w8[3])
	line(im, 22, 2, 38, 10, IRON[4])
	line(im, 18, 2, 2, 10, IRON[4])
	outline_auto(im, 0.4)
	save3(im, "in9_picks", false)
	# ---------- гоблины
	_rug("in9_rug_goblins", 92, 48, Color("8a7a4a"), Color("5a4a2a"), Color("6a9a5a"), 0)
	im = new_img(52, 40)   # кровать из ящиков и тряпок
	for k10 in range(3):
		box3(im, 2 + k10 * 16, 18, 16, 18, 2, w8, 4 - k10 % 2)
	blob(im, 26, 18, 22, 6, hx(["6a4a6a", "8a6a3a", "aa8a5a", "c8a87a"]), 2)
	rect(im, 8, 12, 10, 6, Color("d06a4a"))
	outline_auto(im, 0.4)
	save3(im, "in9_junk_bed", false)
	im = new_img(46, 34)   # куча шестерёнок и банок
	for k11 in range(7):
		var gx: int = 6 + int(h01(k11, 1, 7) * 34.0)
		var gy: int = 14 + int(h01(k11, 2, 7) * 14.0)
		disc(im, gx, gy, 4.0 + h01(k11, 3, 7) * 3.0, [IRON[4], GOLD[3], IRON[3], Color("6a9a5a")][k11 % 4])
		disc(im, gx, gy, 1.5, IRON[1])
	outline_auto(im, 0.4)
	save3(im, "in9_gears", false)
	# ---------- паучихи
	_rug("in9_rug_spider", 90, 48, Color("d8d4e8"), Color("8a84a2"), Color("f4f2fa"), 1)
	im = new_img(46, 40)   # кокон-гамак
	blob(im, 23, 22, 20, 12, hx(["8a84a2", "aca6c4", "ccc8e0", "e8e6f4", "ffffff"]), 3)
	for k12 in range(8):
		line(im, 4 + k12 * 5, 14, 8 + k12 * 5, 32, Color(1, 1, 1, 0.5))
	outline_auto(im, 0.4)
	save3(im, "in9_cocoon_bed", false)
	im = new_img(48, 48)   # паутина в углу
	for k13 in range(6):
		var a2: float = k13 * PI / 10.0
		line(im, 0, 0, int(cos(a2) * 47.0), int(sin(a2) * 47.0), Color(1, 1, 1, 0.7))
	for r in [12.0, 22.0, 32.0, 42.0]:
		for k14 in range(30):
			var a3: float = k14 * PI / 60.0
			px(im, int(cos(a3) * r), int(sin(a3) * r), Color(1, 1, 1, 0.6))
	save3(im, "in9_web", false)


# ================================================================== трава v10
# Короткие пучки (на земле, много), высокая трава (качается на ветру), подстриженный газон для городов.
# Светлые нейтрально-зелёные: в игре их подкрашивает цвет края (осень — желтее, единороги — розовее).

func blade(im: Image, x: float, base: float, h: float, lean: float, ramp: Array) -> void:
	var n: int = int(h)
	for k in range(n):
		var t: float = float(k) / maxf(1.0, h)
		var xx: float = x + lean * t * t * h * 0.5
		var c: Color = ramp[clampi(int(t * (ramp.size() - 1) + 0.5), 0, ramp.size() - 1)]
		px(im, int(xx), int(base - k), c)
		if t < 0.45:
			px(im, int(xx) + 1, int(base - k), c.darkened(0.08))


func gen_grass10() -> void:
	var gr: Array = hx(["2e5a3a", "3e7044", "52884e", "6aa05a", "84b86a", "a2cc7e", "c0dc96"])
	var dry: Array = hx(["5a5a2e", "74723a", "8e8a46", "a8a456", "c2bc6a"])
	# короткие пучки: 6 видов
	for v in range(6):
		var im: Image = new_img(20, 15)
		var r: RandomNumberGenerator = RandomNumberGenerator.new()
		r.seed = 300 + v
		for k in range(9 + v % 4):
			var bx: float = 3.0 + r.randf() * 14.0
			blade(im, bx, 14.0, r.randf_range(4.0, 11.0) * (1.0 - absf(bx - 10.0) / 14.0), (bx - 10.0) * 0.12 + r.randf_range(-0.5, 0.5), gr if v != 5 else dry)
		if v == 3:
			disc(im, 7, 5, 1.2, Color("f4f0e8"))
			disc(im, 13, 6, 1.2, Color("f4e070"))
		save3(im, "grass_s%d" % v, false)
	# высокая трава: 5 видов кустиков с колосками
	for v2 in range(5):
		var im2: Image = new_img(30, 30)
		var r2: RandomNumberGenerator = RandomNumberGenerator.new()
		r2.seed = 400 + v2
		ell(im2, 15, 28, 11, 2, Color(0.15, 0.2, 0.12, 0.35))
		for k2 in range(16):
			var x0: float = 5.0 + r2.randf() * 20.0
			var hh: float = r2.randf_range(12.0, 26.0)
			var ln: float = (x0 - 15.0) * 0.08 + r2.randf_range(-0.6, 0.6)
			blade(im2, x0, 28.0, hh, ln, gr)
			if v2 >= 3 and k2 % 4 == 0:
				var tx: int = int(x0 + ln * hh * 0.5)
				for q in range(4):
					px(im2, tx + (q % 2), int(28.0 - hh) + q, Color("e8d890") if v2 == 3 else Color("d8c8f0"))
		save3(im2, "grass_t%d" % v2, false)
	# газон: короткая ровная травка и клумба-бордюр
	for v3 in range(3):
		var im3: Image = new_img(16, 6)
		for x in range(1, 15):
			if (x + v3) % 2 == 0:
				px(im3, x, 5, gr[3])
				px(im3, x, 4, gr[4])
				if x % 3 == 0:
					px(im3, x, 3, gr[5])
		if v3 == 2:
			px(im3, 5, 2, Color("f6a0c0"))
			px(im3, 11, 3, Color("ffffff"))
		save3(im3, "grass_lawn%d" % v3, false)


# ================================================================== улицы и большие здания v10

## Плитка улицы 64x64 (бесшовная): свой материал у каждой земли
func gen_streets10() -> void:
	var specs: Dictionary = {
		"cats": ["brick", hx(["b07a80", "c8949a", "deb0b2", "eccac8", "f6e0da"]), Color("8a5a62")],
		"knights": ["cobble", hx(["5a5868", "706e80", "8a889a", "a4a2b2", "bebcc8"]), Color("3e3c4a")],
		"gothic": ["slab", hx(["24222c", "302e3a", "3e3c4a", "4e4c5c", "62606e"]), Color("16141c")],
		"elves": ["moss", hx(["3e4a2a", "52603a", "687a48", "82945a", "9cae70"]), Color("2e3a20")],
		"mages": ["marble", hx(["9aa2c0", "b0b8d4", "c8cee4", "dce0f0", "eef0fa"]), Color("8088a8")],
		"orcs": ["earth", hx(["6a3a26", "804a30", "98603e", "b0784e", "c69262"]), Color("4a2a1a")],
		"goblins": ["planks", hx(["3e2e1e", "52402a", "665236", "7c6644", "927a54"]), Color("2a1e14")],
		"dwarves": ["bigslab", hx(["4a4440", "5c5650", "706a62", "868076", "9c968a"]), Color("2e2a26")],
		"spider": ["moss", hx(["4a4658", "5a566a", "6c687e", "807c92", "9894a8"]), Color("2e2a3a")],
	}
	for land in specs.keys():
		var sp: Array = specs[land]
		var kind: String = sp[0]
		var r: Array = sp[1]
		var mort: Color = sp[2]
		var im: Image = new_img(64, 64)
		im.fill(mort)
		match kind:
			"brick":   # розово-кремовая плитка «ёлочкой»
				for by in range(0, 64, 8):
					for bx in range(0, 64, 16):
						var off: int = 8 if (by / 8) % 2 == 1 else 0
						var c: Color = r[1 + int(h01(bx, by, 3) * 3.0)]
						for y in range(by + 1, by + 8):
							for x in range(bx + off + 1, bx + off + 16):
								px(im, posmod(x, 64), y, c if y > by + 1 else c.lightened(0.15))
			"cobble":
				for k in range(40):
					var cx: int = int(h01(k, 1, 5) * 64.0)
					var cy: int = int(h01(k, 2, 5) * 64.0)
					var rr: float = 4.0 + h01(k, 3, 5) * 3.0
					var c2: Color = r[1 + int(h01(k, 4, 5) * 3.0)]
					for y2 in range(-8, 9):
						for x2 in range(-8, 9):
							if x2 * x2 + y2 * y2 * 1.3 < rr * rr:
								px(im, posmod(cx + x2, 64), posmod(cy + y2, 64), c2 if y2 > -rr * 0.5 else c2.lightened(0.2))
			"slab", "bigslab", "marble":
				var s0: int = 32 if kind == "bigslab" else 16
				for by2 in range(0, 64, s0):
					for bx2 in range(0, 64, s0 * (2 if kind == "slab" else 1)):
						var off2: int = (s0 / 2) if (by2 / s0) % 2 == 1 and kind != "marble" else 0
						var c3: Color = r[1 + int(h01(bx2, by2, 7) * 3.0)]
						for y3 in range(by2 + 1, by2 + s0):
							for x3 in range(bx2 + off2 + 1, bx2 + off2 + s0 * (2 if kind == "slab" else 1)):
								var cc: Color = c3
								if kind == "slab" and h01(x3, y3, 9) > 0.93:
									cc = Color("6a7090")   # мокрый блеск
								if kind == "marble" and absf(sin((x3 + y3 * 0.6) * 0.3) + sin(y3 * 0.11) * 0.8) < 0.08:
									cc = r[0]
								px(im, posmod(x3, 64), y3, cc if y3 > by2 + 1 else cc.lightened(0.12))
			"moss", "earth":
				for y4 in range(64):
					for x4 in range(64):
						var n: float = h01(x4 / 3, y4 / 3, 11) * 0.6 + h01(x4, y4, 12) * 0.4
						px(im, x4, y4, r[clampi(int(n * 4.0), 0, 4)])
				for k2 in range(18):
					var gx: int = int(h01(k2, 5, 13) * 62.0)
					var gy: int = int(h01(k2, 6, 13) * 62.0)
					px(im, gx, gy, r[4].lightened(0.2))
					px(im, gx + 1, gy, r[3])
					if kind == "moss" and k2 % 3 == 0:
						px(im, gx, gy + 1, Color("c87a3a"))   # опавший листик
			"planks":
				for py in range(0, 64, 8):
					var c4: Color = r[1 + int(h01(0, py, 15) * 3.0)]
					for y5 in range(py + 1, py + 8):
						for x5 in range(64):
							px(im, x5, y5, c4 if h01(x5, y5, 16) > 0.1 else c4.darkened(0.2))
					var cut: int = int(h01(1, py, 17) * 60.0)
					for y6 in range(py, py + 8):
						px(im, cut, y6, mort)
					px(im, cut + 3, py + 4, Color("8a8a90"))
		save3(im, "st10_" + String(land), false)


## Фасад большого здания (вид спереди-сверху). sp: w, h — фасад; roof_h; стены, крыша, окна, украшения
func building10(name: String, sp: Dictionary) -> void:
	var W: int = int(sp["w"])
	var Hf: int = int(sp["h"])
	var rh: int = int(sp["roof_h"])
	var tower: bool = sp.get("towers", false)
	var tw: int = 34 if tower else 0
	var total_h: int = Hf + rh + (40 if tower else 0) + 10
	var im: Image = new_img(W + tw * 2 + 8, total_h)
	var ox: int = tw + 4
	var base: int = total_h - 4
	var wall: Array = hx(sp["wall"])
	var roof: Array = hx(sp["roof"])
	var trim: Color = Color(sp.get("trim", "3a2a22"))
	ell(im, ox + W / 2.0, base + 1, W / 2.0 + tw, 4, Color(0.1, 0.08, 0.1, 0.3))
	# стены: материал
	var mat: String = sp.get("mat", "plaster")
	for y in range(base - Hf, base):
		for x in range(ox, ox + W):
			var t: int = 2
			match mat:
				"stone":
					var row: int = (y - base) / 7
					var bw: int = 14
					var off: int = 7 if row % 2 == 0 else 0
					t = 1 + int(h01((x + off) / bw, row, 21) * 3.0)
					if posmod(y - base, 7) == 0 or posmod(x + off, bw) == 0:
						t = 0
				"wood", "logs":
					t = 2 + int(h01(x / 3, (y - base) / 9, 22) * 2.0)
					if posmod(y - base, 9) == 0:
						t = 0
				"brick":
					var row2: int = (y - base) / 5
					var off2: int = 5 if row2 % 2 == 0 else 0
					t = 2 + int(h01((x + off2) / 10, row2, 23) * 2.0)
					if posmod(y - base, 5) == 0 or posmod(x + off2, 10) == 0:
						t = 1
				"shoji":
					# бумажные панели в тёмной деревянной раме, внизу — каменный цоколь
					t = 4 if h01(x, y, 26) > 0.1 else 3
					if y >= base - 8:
						t = 0 if posmod(x, 9) == 0 or y == base - 8 else 1
					elif posmod(x - ox, 8) == 0 or posmod(y - base, 10) == 0:
						t = 2
				"hide":
					t = 2 + int(h01(x / 6, y / 6, 24) * 2.0)
					if posmod(x - ox, 24) < 2:
						t = 0
				_:
					t = 3 if h01(x, y, 25) > 0.12 else 2
			if x >= ox + W - 4:
				t -= 1
			px(im, x, y, wall[clampi(t, 0, wall.size() - 1)])
	# японский дом: толстые тёмные столбы и балки, веранда-энгава
	if mat == "shoji":
		for bx2 in range(ox, ox + W, 34):
			rect(im, bx2, base - Hf, 4, Hf - 8, trim)
		rect(im, ox + W - 4, base - Hf, 4, Hf - 8, trim)
		rect(im, ox, base - Hf, W, 4, trim)
		rect(im, ox, base - Hf / 2 - 1, W, 2, trim)
		rect(im, ox - 6, base - 10, W + 12, 3, Color("8a6440"))
		rect(im, ox - 6, base - 7, W + 12, 1, Color("5a3e26"))
	# фахверк
	if mat == "plaster" and sp.get("timber", false):
		for bx in range(ox, ox + W, 28):
			rect(im, bx, base - Hf, 4, Hf, trim)
		rect(im, ox, base - Hf / 2, W, 3, trim)
	# башенки по бокам
	if tower:
		for side in [0, 1]:
			var tx: int = 4 if side == 0 else ox + W
			for y2 in range(base - Hf - 40, base):
				for x2 in range(tx, tx + tw):
					px(im, x2, y2, wall[2 if x2 < tx + tw - 5 else 1])
			# коническая крыша башни
			for k in range(46):
				var hw: float = (tw / 2.0 + 4.0) * float(k) / 45.0
				for x3 in range(int(tx + tw / 2.0 - hw), int(tx + tw / 2.0 + hw)):
					px(im, x3, base - Hf - 40 - 46 + k, roof[2 if x3 < tx + tw / 2.0 else 1])
			rect(im, tx + tw / 2 - 4, base - Hf - 10, 8, 14, Color("3a3040"))
			rect(im, tx + tw / 2 - 3, base - Hf - 9, 6, 12, Color("ffd890"))
	# крыша
	var rs: String = sp.get("roof_shape", "gable")
	for k2 in range(rh):
		var y4: int = base - Hf - k2
		var hw2: float = W / 2.0 + 10.0
		match rs:
			"gable":
				hw2 = (W / 2.0 + 10.0) * (1.0 - float(k2) / float(rh) * 0.82)
			"steep":
				hw2 = (W / 2.0 + 8.0) * (1.0 - float(k2) / float(rh))
			"dome":
				hw2 = (W / 2.0 + 6.0) * sqrt(maxf(0.0, 1.0 - pow(float(k2) / float(rh), 2.0)))
			"flat":
				hw2 = W / 2.0 + 6.0 - (2.0 if k2 > rh - 4 else 0.0)
			"tent":
				hw2 = (W / 2.0 + 14.0) * (1.0 - float(k2) / float(rh))
			"curved":
				# вогнутый скат: у карниза пологий и широкий, кверху крутой; кончики загнуты вверх
				hw2 = (W / 2.0 + 22.0) * (1.0 - sqrt(float(k2) / float(rh)) * 0.78) + maxf(0.0, 4.0 - float(k2)) * 4.0
		var cx: float = ox + W / 2.0
		for x4 in range(int(cx - hw2), int(cx + hw2)):
			var t2: int = 2
			if posmod(k2, 6) == 0 and rs != "dome":
				t2 = 1
			if x4 > cx + hw2 * 0.6:
				t2 -= 1
			if x4 < cx - hw2 * 0.6 and k2 > 2:
				t2 += 1
			if rs == "dome" and float(k2) / rh > 0.6 and x4 < cx:
				t2 = 4
			px(im, x4, y4, roof[clampi(t2, 0, roof.size() - 1)])
	# окна
	var win: Color = Color(sp.get("win", "ffd890"))
	var floors: int = maxi(1, Hf / 50)
	for f in range(floors):
		var wy: int = base - Hf + 12 + f * 46
		if wy > base - 46:
			break
		var nwin: int = maxi(2, W / 44)
		for i in range(nwin):
			var wx: int = ox + int((float(i) + 0.5) / nwin * W) - 6
			if absi(wx + 6 - (ox + W / 2)) < 22 and f == floors - 1:
				continue
			if mat == "shoji":
				rect(im, wx - 3, wy - 1, 18, 16, trim)
				rect(im, wx - 2, wy, 16, 14, win)
				for lx in [wx + 2, wx + 6, wx + 10]:
					rect(im, lx, wy, 1, 14, trim)
				for ly in [wy + 4, wy + 9]:
					rect(im, wx - 2, ly, 16, 1, trim)
				continue
			rect(im, wx - 1, wy - 1, 14, 18, trim)
			rect(im, wx, wy, 12, 16, win)
			rect(im, wx + 5, wy, 2, 16, trim)
			rect(im, wx, wy + 7, 12, 2, trim)
			if sp.get("arch", false):
				for a in range(6):
					px(im, wx + a + 3, wy - 2 - int(sin(a / 5.0 * PI) * 3.0), trim)
	# дверь (большая, по центру)
	var dw: int = int(sp.get("door_w", 26))
	var dx0: int = ox + W / 2 - dw / 2
	rect(im, dx0 - 2, base - 40, dw + 4, 40, trim)
	rect(im, dx0, base - 38, dw, 38, Color(sp.get("door", "6a4428")))
	rect(im, dx0 + dw / 2 - 1, base - 38, 2, 38, Color(sp.get("door", "6a4428")).darkened(0.3))
	px(im, dx0 + dw / 2 + 3, base - 18, Color("e8c860"))
	if mat == "shoji":
		# раздвижная дверь-сёдзи и занавеска-норэн
		rect(im, dx0, base - 38, dw, 28, Color(sp.get("win", "f8ecc8")))
		for lx2 in range(dx0 + 4, dx0 + dw, 5):
			rect(im, lx2, base - 38, 1, 28, trim)
		rect(im, dx0 + dw / 2 - 1, base - 38, 2, 28, trim)
		var nc: Color = Color(sp.get("noren", "2a3a6a"))
		for nk in range(3):
			rect(im, dx0 - 2 + nk * (dw + 4) / 3, base - 40, (dw + 4) / 3 - 1, 14, nc)
		px(im, dx0 + dw / 2, base - 34, Color("f0e8d8"))
	# крыльцо
	rect(im, dx0 - 8, base - 3, dw + 16, 3, wall[1])
	# украшения
	var dec: Array = sp.get("deco", [])
	for d in dec:
		match String(d):
			"cat_ears":
				for side2 in [-1, 1]:
					var ex: float = ox + W / 2.0 + side2 * W * 0.22
					tri(im, Vector2(ex - 12, base - Hf - rh * 0.55), Vector2(ex + 12, base - Hf - rh * 0.55), Vector2(ex + side2 * 4, base - Hf - rh * 0.55 - 26), func(_x: int, _y: int, u: float) -> Color: return roof[3] if u < 0.5 else roof[1])
					tri(im, Vector2(ex - 5, base - Hf - rh * 0.55 - 2), Vector2(ex + 5, base - Hf - rh * 0.55 - 2), Vector2(ex + side2 * 3, base - Hf - rh * 0.55 - 16), func(_x: int, _y: int, _u: float) -> Color: return Color("f8b8c8"))
			"banner":
				for bxx in [ox + 14, ox + W - 26]:
					rect(im, bxx, base - Hf + 6, 12, 34, Color(sp.get("banner", "b02a2a")))
					disc(im, bxx + 6, base - Hf + 18, 3.0, Color("e8c050"))
			"spikes":
				for sx in range(ox - 6, ox + W + 6, 10):
					tri(im, Vector2(sx, base - Hf - rh + 4), Vector2(sx + 6, base - Hf - rh + 4), Vector2(sx + 3, base - Hf - rh - 10), func(_x: int, _y: int, _u: float) -> Color: return Color("e8e0d0"))
			"skull":
				disc(im, ox + W / 2.0, base - Hf - 14, 8.0, Color("ece4d4"))
				rect(im, ox + W / 2 - 4, base - Hf - 14, 3, 3, Color("2a1c14"))
				rect(im, ox + W / 2 + 2, base - Hf - 14, 3, 3, Color("2a1c14"))
			"vines":
				for vx in range(ox, ox + W, 3):
					var vh: int = int(h01(vx, 1, 31) * 40.0)
					for vy in range(vh):
						if h01(vx, vy, 32) > 0.4:
							px(im, vx, base - Hf + vy, [Color("3e7a3a"), Color("5a9a4a"), Color("f0a0c0")][int(h01(vx, vy, 33) * 2.9)])
			"crystal":
				for k3 in range(3):
					var cxx: float = ox + W / 2.0 + (k3 - 1) * 16.0
					tri(im, Vector2(cxx - 5, base - Hf - rh + 6), Vector2(cxx + 5, base - Hf - rh + 6), Vector2(cxx, base - Hf - rh - 18 + absf(k3 - 1) * 8.0), func(_x: int, _y: int, u: float) -> Color: return Color("a0d8ff") if u < 0.5 else Color("6aa0e0"))
			"chimney":
				rect(im, ox + W - 40, base - Hf - rh + 4, 14, rh * 0.7, hx(DSTONE)[3])
			"lamps":
				for lx in [dx0 - 16, dx0 + dw + 10]:
					rect(im, lx, base - 34, 6, 8, Color("ffd060"))
					rect(im, lx - 1, base - 36, 8, 2, trim)
			"gears":
				for k4 in range(3):
					disc(im, ox + 20 + k4 * 30, base - Hf - 8, 7.0, [IRON[4], GOLD[3], IRON[3]][k4])
					disc(im, ox + 20 + k4 * 30, base - Hf - 8, 2.0, IRON[1])
			"web":
				for k5 in range(6):
					line(im, ox, base - Hf, ox + k5 * 10, base - Hf + 30, Color(1, 1, 1, 0.6))
	# вывеска
	if sp.has("sign"):
		var sx0: int = ox + W / 2 + dw / 2 + 12
		var sy0: int = base - 62
		line(im, sx0 - 4, sy0, sx0 + 22, sy0, trim)
		rect(im, sx0 + 2, sy0 + 2, 20, 16, Color("e8d4a8"))
		rect(im, sx0 + 2, sy0 + 2, 20, 1, trim)
		match String(sp["sign"]):
			"bread":
				ell(im, sx0 + 12, sy0 + 10, 7, 4, Color("c88a3a"))
				line(im, sx0 + 8, sy0 + 9, sx0 + 10, sy0 + 11, Color("8a5a2a"))
				line(im, sx0 + 13, sy0 + 9, sx0 + 15, sy0 + 11, Color("8a5a2a"))
			"cake":
				rect(im, sx0 + 6, sy0 + 8, 12, 7, Color("f4d8a0"))
				rect(im, sx0 + 6, sy0 + 7, 12, 2, Color("f8b8c8"))
				disc(im, sx0 + 12, sy0 + 5, 2.0, Color("e03040"))
			"mug":
				rect(im, sx0 + 7, sy0 + 6, 9, 10, Color("e8b040"))
				rect(im, sx0 + 7, sy0 + 5, 9, 2, Color("fffaf0"))
				rect(im, sx0 + 16, sy0 + 8, 3, 5, Color("a87828"))
			"sword":
				line(im, sx0 + 6, sy0 + 15, sx0 + 18, sy0 + 4, Color("c8ccd8"))
				line(im, sx0 + 7, sy0 + 10, sx0 + 11, sy0 + 14, Color("b08a28"))
			"potion":
				disc(im, sx0 + 12, sy0 + 11, 5.0, Color("8a6ae0"))
				rect(im, sx0 + 11, sy0 + 3, 3, 4, Color("d8c8b0"))
			"bag":
				disc(im, sx0 + 12, sy0 + 11, 5.0, Color("a07a4a"))
				px(im, sx0 + 12, sy0 + 11, Color("f0d050"))
	outline_auto(im, 0.45)
	save3(im, name, false)


func gen_buildings10() -> void:
	# дворцы
	building10("palace_cats", {"w": 280, "h": 110, "roof_h": 70, "towers": true, "wall": ["b89aa0", "d0b4b8", "e6d0d0", "f4e4e2", "fff4f0"], "roof": ["6a3a5a", "8a4a78", "aa6094", "c880b0", "e0a8cc"], "deco": ["cat_ears", "banner"], "banner": "e06a9a", "trim": "6a4a50", "door": "a04a6a", "door_w": 34, "arch": true})
	building10("palace_knights", {"w": 300, "h": 120, "roof_h": 50, "towers": true, "mat": "stone", "wall": ["4a4858", "5e5c6c", "767484", "8e8c9a", "a8a6b2"], "roof": ["2a3050", "3a4470", "4a5890", "5e70a8", "8090c0"], "deco": ["banner"], "banner": "b02a2a", "trim": "2a2834", "door": "5a3a24", "door_w": 34, "arch": true})
	building10("palace_gothic", {"w": 280, "h": 130, "roof_h": 90, "towers": true, "mat": "stone", "roof_shape": "steep", "wall": ["22202a", "2e2c38", "3c3a48", "4c4a58", "5e5c6a"], "roof": ["1a1420", "2a1e30", "3a2840", "4e3654", "684a6e"], "deco": ["banner"], "banner": "6a1020", "trim": "14121a", "door": "3a1a1e", "win": "e8506a", "door_w": 30, "arch": true})
	building10("palace_elves", {"w": 260, "h": 110, "roof_h": 70, "mat": "wood", "roof_shape": "dome", "wall": ["5a4a30", "74603e", "8e784e", "a89062", "c4ac7a"], "roof": ["1e4a32", "2a6644", "3a8456", "58a46e", "84c48c"], "deco": ["vines"], "trim": "3a2a1a", "door": "4a3420", "win": "b0f0e0", "door_w": 30, "arch": true})
	building10("palace_mages", {"w": 240, "h": 140, "roof_h": 90, "towers": true, "mat": "stone", "roof_shape": "steep", "wall": ["9aa2c0", "b0b8d4", "c8cee4", "dce0f0", "eef0fa"], "roof": ["1e2a6a", "2a3a8a", "3a50aa", "5a70c8", "8a9ce0"], "deco": ["crystal"], "trim": "5a6080", "door": "3a4a8a", "win": "c8e0ff", "door_w": 28, "arch": true})
	building10("palace_orcs", {"w": 300, "h": 90, "roof_h": 60, "mat": "logs", "roof_shape": "gable", "wall": ["3a2416", "4e3220", "62402a", "784e34", "8e6040"], "roof": ["4a3a2a", "5e4a36", "766048", "8e785a", "a89070"], "deco": ["spikes", "skull"], "trim": "2a1a10", "door": "3a2416", "win": "ff9a40", "door_w": 36})
	building10("palace_goblins", {"w": 220, "h": 100, "roof_h": 60, "mat": "wood", "roof_shape": "tent", "wall": ["4a3a24", "5e4c30", "74603e", "8a764e", "a08c62"], "roof": ["5a6a3a", "6e8248", "849a58", "9ab26a", "b4c884"], "deco": ["gears", "spikes"], "trim": "2a1e14", "door": "4a3a24", "win": "c8e070", "door_w": 24})
	building10("palace_dwarves", {"w": 300, "h": 110, "roof_h": 40, "mat": "stone", "roof_shape": "flat", "wall": ["3e3834", "524a44", "665e56", "7c746a", "948a7e"], "roof": ["2e2824", "3e3632", "524842", "665c54", "7e7268"], "deco": ["lamps", "banner"], "banner": "c8902a", "trim": "26201c", "door": "5a3a1e", "win": "ffb050", "door_w": 40})
	building10("palace_spider", {"w": 220, "h": 100, "roof_h": 80, "roof_shape": "dome", "wall": ["8a84a2", "aca6c4", "ccc8e0", "e8e6f4", "ffffff"], "roof": ["6a6484", "8a84a2", "aca6c4", "ccc8e0", "e8e6f4"], "deco": ["web"], "trim": "4a4458", "door": "3a3448", "win": "c8a0ff", "door_w": 26})
	# таверны и пекарня
	building10("tavern_cats", {"w": 220, "h": 100, "roof_h": 60, "timber": true, "wall": ["c8b098", "dcc8b0", "eadcc4", "f4ead8", "fff8ec"], "roof": ["8a3a4a", "a84a5e", "c66478", "dc8494", "eeaab4"], "deco": ["cat_ears", "lamps"], "trim": "6a4a3a", "sign": "cake", "door": "8a4a5a"})
	building10("bakery_cats", {"w": 200, "h": 90, "roof_h": 56, "mat": "brick", "wall": ["b07a6a", "c8907e", "dca894", "ecc4ae", "f8dcc8"], "roof": ["7a4a2a", "966036", "b07a46", "c8965c", "dcb47a"], "deco": ["cat_ears", "chimney", "lamps"], "trim": "5a3a2a", "sign": "bread", "door": "a06a4a"})
	building10("tavern_knights", {"w": 230, "h": 100, "roof_h": 60, "timber": true, "wall": ["b8a888", "ccbe9e", "ddd2b6", "ece4cc", "f8f2e2"], "roof": ["5a3a2a", "744a34", "8e5e42", "a87652", "c29268"], "deco": ["lamps", "chimney"], "trim": "3a2a1e", "sign": "mug"})
	building10("tavern_gothic", {"w": 220, "h": 110, "roof_h": 70, "mat": "stone", "roof_shape": "steep", "wall": ["2a2832", "36343e", "44424e", "54525e", "66646e"], "roof": ["1a1420", "2a1e30", "3a2840", "4e3654", "684a6e"], "deco": ["lamps"], "trim": "14121a", "sign": "mug", "win": "e8a060"})
	building10("tavern_elves", {"w": 200, "h": 90, "roof_h": 60, "mat": "wood", "roof_shape": "dome", "wall": ["5a4a30", "74603e", "8e784e", "a89062", "c4ac7a"], "roof": ["1e4a32", "2a6644", "3a8456", "58a46e", "84c48c"], "deco": ["vines"], "trim": "3a2a1a", "sign": "mug", "win": "b0f0e0"})
	building10("tavern_mages", {"w": 200, "h": 100, "roof_h": 70, "mat": "stone", "roof_shape": "steep", "wall": ["9aa2c0", "b0b8d4", "c8cee4", "dce0f0", "eef0fa"], "roof": ["3a2a6a", "4a3a8a", "5e4caa", "7a68c8", "9a8ae0"], "deco": ["crystal"], "trim": "5a6080", "sign": "potion", "win": "c8e0ff"})
	building10("tavern_orcs", {"w": 240, "h": 80, "roof_h": 56, "mat": "hide", "roof_shape": "tent", "wall": ["6a4a30", "806040", "9a7a52", "b49468", "ccae82"], "roof": ["4a3a2a", "5e4a36", "766048", "8e785a", "a89070"], "deco": ["skull"], "trim": "2a1a10", "sign": "mug", "win": "ff9a40"})
	building10("tavern_goblins", {"w": 180, "h": 80, "roof_h": 50, "mat": "wood", "roof_shape": "tent", "wall": ["4a3a24", "5e4c30", "74603e", "8a764e", "a08c62"], "roof": ["6a3a3a", "844848", "9e5a5a", "b87070", "d08c8c"], "deco": ["gears"], "trim": "2a1e14", "sign": "mug", "win": "c8e070"})
	building10("tavern_dwarves", {"w": 240, "h": 100, "roof_h": 40, "mat": "stone", "roof_shape": "flat", "wall": ["3e3834", "524a44", "665e56", "7c746a", "948a7e"], "roof": ["5a3a1e", "744c28", "8e6034", "a87a46", "c2945c"], "deco": ["lamps", "chimney"], "trim": "26201c", "sign": "mug", "win": "ffb050"})
	building10("tavern_spider", {"w": 180, "h": 80, "roof_h": 60, "roof_shape": "dome", "wall": ["8a84a2", "aca6c4", "ccc8e0", "e8e6f4", "ffffff"], "roof": ["5a4a7a", "6e5c94", "8470ae", "9c88c4", "b8a8dc"], "deco": ["web"], "trim": "4a4458", "sign": "mug", "win": "c8a0ff"})
	# лавки: короче и шире, с вывеской
	var shop_sign: Dictionary = {"cats": "cake", "knights": "sword", "gothic": "potion", "elves": "bag", "mages": "potion", "orcs": "sword", "goblins": "bag", "dwarves": "sword", "spider": "bag"}
	var shop_style: Dictionary = {
		"cats": {"timber": true, "wall": ["c8b098", "dcc8b0", "eadcc4", "f4ead8", "fff8ec"], "roof": ["6a6aa8", "7e7ec0", "9696d4", "b0b0e4", "ccccf2"], "deco": ["cat_ears"]},
		"knights": {"timber": true, "wall": ["b8a888", "ccbe9e", "ddd2b6", "ece4cc", "f8f2e2"], "roof": ["7a2a2a", "963636", "b04848", "c86262", "dc8484"]},
		"gothic": {"mat": "stone", "roof_shape": "steep", "wall": ["2a2832", "36343e", "44424e", "54525e", "66646e"], "roof": ["2a1a2a", "3e2640", "543256", "6c4470", "8a5e8e"], "win": "e8a060"},
		"elves": {"mat": "wood", "roof_shape": "dome", "wall": ["5a4a30", "74603e", "8e784e", "a89062", "c4ac7a"], "roof": ["2a5a3a", "3a7448", "4e905a", "6aac70", "8ec88e"], "deco": ["vines"], "win": "b0f0e0"},
		"mages": {"mat": "stone", "roof_shape": "steep", "wall": ["9aa2c0", "b0b8d4", "c8cee4", "dce0f0", "eef0fa"], "roof": ["1e2a6a", "2a3a8a", "3a50aa", "5a70c8", "8a9ce0"], "deco": ["crystal"], "win": "c8e0ff"},
		"orcs": {"mat": "hide", "roof_shape": "tent", "wall": ["6a4a30", "806040", "9a7a52", "b49468", "ccae82"], "roof": ["5a3a2a", "6e4a36", "866048", "9e785a", "b89070"], "win": "ff9a40"},
		"goblins": {"mat": "wood", "roof_shape": "tent", "wall": ["4a3a24", "5e4c30", "74603e", "8a764e", "a08c62"], "roof": ["3a5a6a", "487084", "5a889e", "70a0b8", "8cbcd0"], "deco": ["gears"], "win": "c8e070"},
		"dwarves": {"mat": "stone", "roof_shape": "flat", "wall": ["3e3834", "524a44", "665e56", "7c746a", "948a7e"], "roof": ["2e2824", "3e3632", "524842", "665c54", "7e7268"], "deco": ["lamps"], "win": "ffb050"},
		"spider": {"roof_shape": "dome", "wall": ["8a84a2", "aca6c4", "ccc8e0", "e8e6f4", "ffffff"], "roof": ["5a5a7a", "6e6e94", "8484ae", "9c9cc4", "b8b8dc"], "deco": ["web"], "win": "c8a0ff"},
	}
	for land in shop_style.keys():
		var sp: Dictionary = (shop_style[land] as Dictionary).duplicate()
		sp["w"] = 170
		sp["h"] = 80
		sp["roof_h"] = 50
		sp["sign"] = shop_sign[land]
		sp["trim"] = "3a2a22"
		building10("shop_" + String(land), sp)
	# мебель лавок, таверн и дворцов
	gen_shop_interior10()


func gen_shop_interior10() -> void:
	var w8: Array = hx(LOG)
	# витрина с булочками и тортами (пекарня)
	var im: Image = new_img(84, 50)
	box3(im, 2, 18, 80, 30, 3, w8, 4)
	rect(im, 6, 4, 72, 26, Color(0.8, 0.92, 1.0, 0.55))
	rect(im, 6, 4, 72, 1, Color("ffffff"))
	rect(im, 6, 16, 72, 2, w8[5])
	for k in range(5):
		ell(im, 12 + k * 14, 13, 5, 3, Color("d89a4a"))
		px(im, 11 + k * 14, 12, Color("f4cc84"))
	cake_slice(im, 10, 19, Color("f4d8a0"), Color("fff6ee"), Color("f8b8c8"), Color("e03040"))
	cake_slice(im, 26, 19, Color("6a3a24"), Color("c08a5a"), Color("4a2418"), Color("8a5a2a"))
	roll_cake(im, 44, 20, Color("a8c878"), Color("f6f2e0"), Color("6a2a2a"))
	roll_cake(im, 60, 20, Color("e8c088"), Color("fff6e8"), Color("f0f0f0"))
	outline_auto(im, 0.4)
	save3(im, "in10_vitrine", false)
	# прилавок
	im = new_img(70, 34)
	box3(im, 2, 8, 66, 24, 4, w8, 4)
	rect(im, 8, 2, 10, 7, Color("e8d8b0"))
	disc(im, 52, 5, 4.0, Color("e8c050"))
	outline_auto(im, 0.4)
	save3(im, "in10_counter", false)
	# стойка таверны с бочками
	im = new_img(110, 52)
	for k2 in range(3):
		var bx: int = 6 + k2 * 34
		for y in range(4, 28):
			var hw: float = 13.0 - absf(y - 16.0) * 0.12
			for x in range(int(bx + 14 - hw), int(bx + 14 + hw)):
				px(im, x, y, w8[4] if x < bx + 12 else w8[3])
		rect(im, bx + 3, 10, 22, 2, IRON[3])
		rect(im, bx + 3, 22, 22, 2, IRON[3])
	box3(im, 2, 28, 106, 22, 4, w8, 3)
	for k3 in range(4):
		rect(im, 14 + k3 * 24, 22, 7, 8, Color("f0c050"))
		rect(im, 14 + k3 * 24, 21, 7, 2, Color("fffaf0"))
	outline_auto(im, 0.4)
	save3(im, "in10_bar", false)
	# стол таверны со скамьями
	im = new_img(60, 40)
	box3(im, 6, 10, 48, 10, 3, w8, 4)
	rect(im, 10, 20, 4, 14, w8[2])
	rect(im, 46, 20, 4, 14, w8[2])
	box3(im, 2, 30, 56, 6, 2, w8, 3)
	rect(im, 18, 4, 7, 7, Color("f0c050"))
	ell(im, 38, 8, 6, 3, Color("c88a3a"))
	outline_auto(im, 0.4)
	save3(im, "in10_tavern_table", false)
	# трон
	im = new_img(50, 70)
	box3(im, 8, 6, 34, 48, 3, hx(["6a1a2a", "8a2a3a", "aa3a4a", "c85a6a", "e08a96"]), 2)
	rect(im, 4, 40, 42, 8, GOLD[2])
	rect(im, 4, 54, 42, 14, GOLD[1])
	for k4 in range(3):
		disc(im, 13 + k4 * 12, 6, 4.0, GOLD[4])
	disc(im, 25, 18, 4.0, Color("a0d8ff"))
	outline_auto(im, 0.4)
	save3(im, "in10_throne", false)
	# полки с товаром
	im = new_img(56, 60)
	rect(im, 2, 2, 52, 56, w8[2])
	for sy in [18, 38, 56]:
		rect(im, 2, sy, 52, 3, w8[4])
	for k5 in range(12):
		var gx: int = 6 + (k5 % 4) * 12
		var gy: int = 6 + (k5 / 4) * 20
		rect(im, gx, gy + 2, 8, 10, [Color("c84a4a"), Color("4a8ac8"), Color("e8c050"), Color("6aa04a"), Color("a070c8")][k5 % 5])
	outline_auto(im, 0.4)
	save3(im, "in10_shelf", false)
	# красная ковровая дорожка
	im = new_img(60, 120)
	for y in range(120):
		for x in range(60):
			px(im, x, y, Color("e8c050") if x < 4 or x > 55 else Color("a02a3a") if h01(x, y, 3) > 0.05 else Color("8a2030"))
	save3(im, "in10_carpet", false)
	# превью
	var names: Array = ["palace_cats", "bakery_cats", "tavern_cats", "shop_cats", "palace_knights", "tavern_knights", "palace_gothic", "tavern_gothic", "palace_orcs", "tavern_orcs", "palace_dwarves", "palace_mages", "palace_elves", "palace_goblins", "palace_spider", "in10_vitrine", "in10_bar", "in10_throne"]
	var pv: Image = new_img(380 * 6, 330 * 3)
	pv.fill(Color("8aa070"))
	for i in range(names.size()):
		var s: Image = Image.load_from_file(ProjectSettings.globalize_path(OUT + String(names[i]) + ".png"))
		s.convert(Image.FORMAT_RGBA8)
		pv.blend_rect(s, Rect2i(0, 0, s.get_width(), s.get_height()), Vector2i((i % 6) * 380 + 4, (i / 6) * 330 + 4))
	pv.save_png(ProjectSettings.globalize_path("res://").path_join("../screenshots/buildings_v10.png"))


# ================================================================== участок v11: постройки и предметы

func gen_home11() -> void:
	var w8: Array = hx(LOG)
	# верстак: столешница, тиски, пила, молоток
	var im: Image = new_img(76, 52)
	ell(im, 38, 49, 34, 3, Color(0.1, 0.08, 0.1, 0.3))
	box3(im, 4, 18, 68, 9, 3, w8, 4)
	for lx in [8, 64]:
		rect(im, lx, 27, 5, 22, w8[2])
	rect(im, 8, 38, 60, 3, w8[3])
	rect(im, 50, 10, 10, 9, IRON[3])
	rect(im, 48, 8, 14, 3, IRON[4])
	line(im, 14, 16, 34, 10, Color("c8ccd8"))
	line(im, 14, 17, 34, 11, Color("8c8892"))
	rect(im, 10, 14, 6, 4, w8[5])
	rect(im, 36, 13, 9, 4, IRON[4])
	rect(im, 40, 16, 2, 4, w8[2])
	outline_auto(im, 0.4)
	save3(im, "workbench", false)
	# стол изучения трав: свитки, лупа, пучки трав
	im = new_img(70, 50)
	ell(im, 35, 47, 31, 3, Color(0.1, 0.08, 0.1, 0.3))
	box3(im, 4, 18, 62, 8, 3, hx(["3e2a3a", "56404e", "6e5664", "8a707e", "a68c98"]), 3)
	for lx2 in [8, 58]:
		rect(im, lx2, 26, 4, 20, w8[2])
	rect(im, 10, 10, 18, 10, Color("f4ecd8"))
	for yy in range(12, 19, 2):
		line(im, 12, yy, 26, yy, Color("8a7a6a"))
	disc(im, 42, 13, 5.0, Color("b0d8f0"))
	disc(im, 42, 13, 3.0, Color("e0f4ff"))
	line(im, 45, 17, 50, 22, w8[2])
	for k in range(3):
		line(im, 54 + k * 3, 18, 52 + k * 3, 6, [MINT[5], LAV[5], Color("f4e070")][k])
	outline_auto(im, 0.4)
	save3(im, "research_table", false)
	# загон: кольцо из жердей
	im = new_img(150, 96)
	for side in range(4):
		pass
	var pts: Array = []
	for k2 in range(16):
		var a: float = TAU * k2 / 16.0
		pts.append(Vector2(75 + cos(a) * 66.0, 56 + sin(a) * 34.0))
	for k3 in range(16):
		var p0: Vector2 = pts[k3]
		var p1: Vector2 = pts[(k3 + 1) % 16]
		if k3 == 4:
			continue   # калитка спереди
		for hh in [8, 16]:
			line(im, int(p0.x), int(p0.y - hh), int(p1.x), int(p1.y - hh), w8[4])
		rect(im, int(p0.x) - 2, int(p0.y) - 22, 4, 22, w8[3])
	ell(im, 75, 60, 40, 14, Color(0.85, 0.75, 0.4, 0.35))
	outline_auto(im, 0.35)
	save3(im, "animal_pen", false)
	# межевой столб с табличкой
	im = new_img(26, 50)
	rect(im, 11, 14, 4, 34, w8[3])
	box3(im, 2, 6, 22, 12, 2, w8, 5)
	line(im, 6, 10, 20, 10, w8[1])
	line(im, 6, 13, 16, 13, w8[1])
	outline_auto(im, 0.4)
	save3(im, "boundary_post", false)
	# значки предметов 20x20
	im = new_img(20, 20)
	for y in range(6, 15):
		for x in range(2, 18):
			px(im, x, y, w8[4] if y < 9 else (w8[3] if y < 13 else w8[2]))
	disc(im, 3, 10, 4.0, Color("c8a272"))
	disc(im, 3, 10, 2.0, Color("94683e"))
	outline_auto(im, 0.4)
	save3(im, "icon_log", false)
	im = new_img(20, 20)
	line(im, 4, 18, 14, 4, w8[3])
	line(im, 5, 18, 15, 4, w8[2])
	for k4 in range(6):
		line(im, 11 + k4 / 2, 2 + k4, 18, 4 + k4 / 2, IRON[4] if k4 < 4 else IRON[2])
	outline_auto(im, 0.4)
	save3(im, "icon_axe", false)
	im = new_img(20, 20)
	ell(im, 10, 17, 6, 2, Color("6e4a2c"))
	line(im, 10, 17, 10, 7, Color("4a7a3a"))
	ell(im, 7, 8, 3, 2, MINT[5])
	ell(im, 13, 6, 3, 2, MINT[6])
	ell(im, 10, 4, 2, 2, MINT[4])
	outline_auto(im, 0.4)
	save3(im, "icon_sapling", false)
	# саженец в земле: 3 стадии
	for st in range(3):
		var h: int = [10, 22, 40][st]
		im = new_img(40, 50)
		ell(im, 20, 46, 8 + st * 3, 3, Color("5e3c24"))
		line(im, 20, 46, 20, 46 - h, TRUNK[3])
		if st >= 1:
			line(im, 21, 46, 21, 46 - h, TRUNK[2])
		for k5 in range(2 + st * 3):
			var lp: Vector2 = Vector2(20 + sin(k5 * 2.3) * (3 + st * 4), 46 - h + 4 + k5 * (2 + st))
			blob(im, lp.x, lp.y, 3.0 + st, 2.2 + st * 0.6, BUSH, 5)
		outline_auto(im, 0.4)
		save3(im, "sapling_%d" % st, false)


# ================================================================== японский край и море v12

func gen_japan12() -> void:
	var w8: Array = hx(LOG)
	# бамбук: кучка стеблей с коленцами и листьями
	var im: Image = new_img(46, 120)
	ell(im, 23, 117, 18, 3, Color(0.1, 0.12, 0.08, 0.3))
	for k in range(5):
		var x: int = 6 + k * 8 + int(h01(k, 1, 3) * 3.0)
		var top: int = 6 + int(h01(k, 2, 3) * 30.0)
		var g: Array = hx(["3a6a2a", "4e8a36", "6aa848", "8cc464", "b4dc8a"])
		for y in range(top, 117):
			px(im, x, y, g[1])
			px(im, x + 1, y, g[2])
			px(im, x + 2, y, g[3])
			px(im, x + 3, y, g[2])
			if posmod(y - top, 18) == 0:
				rect(im, x - 1, y, 6, 1, g[0])
		for l in range(3):
			var ly: int = top + 6 + l * 16
			line(im, x + 3, ly, x + 12 - (k % 2) * 18, ly - 4, g[3])
			line(im, x + 3, ly + 1, x + 11 - (k % 2) * 16, ly - 2, g[4])
	outline_auto(im, 0.35)
	save3(im, "bamboo", false)
	# пальма для пляжа
	im = new_img(80, 120)
	ell(im, 40, 117, 22, 3, Color(0.1, 0.1, 0.06, 0.3))
	for y2 in range(40, 117):
		var cx: float = 40 + sin((117 - y2) * 0.03) * 8.0
		rect(im, int(cx) - 3, y2, 7, 1, TRUNK[3] if posmod(y2, 6) > 1 else TRUNK[2])
	for a in range(7):
		var ang: float = -PI * 0.95 + a * PI * 0.32
		var tip: Vector2 = Vector2(48 + cos(ang) * 34.0, 40 + sin(ang) * 22.0 + 10.0)
		capsule(im, Vector2(48, 40), tip, 3.0, 1.4, BUSH, 5)
	disc(im, 46, 44, 3.0, Color("6a4a2a"))
	disc(im, 50, 45, 3.0, Color("6a4a2a"))
	outline_auto(im, 0.35)
	save3(im, "palm", false)
	# ворота-тории
	im = new_img(130, 110)
	var red: Array = hx(["7a1a14", "a02a1e", "c43a28", "dc5a3c", "ec8058"])
	for x2 in [24, 98]:
		box3(im, x2, 26, 9, 82, 2, red, 2)
	box3(im, 4, 14, 122, 9, 2, hx(["1a1418", "2a2228", "3a3036", "4a4046"]), 2)
	for x3 in range(0, 130):
		if x3 < 6 or x3 > 123:
			px(im, x3, 13, Color("2a2228"))
	box3(im, 14, 34, 102, 7, 2, red, 2)
	rect(im, 58, 22, 14, 12, Color("e8d8b0"))
	outline_auto(im, 0.4)
	save3(im, "torii", false)
	# каменный фонарь
	im = new_img(30, 52)
	var st: Array = hx(DSTONE)
	box3(im, 8, 40, 14, 10, 2, st, 4)
	rect(im, 12, 26, 6, 14, st[4])
	box3(im, 6, 18, 18, 8, 2, st, 4)
	rect(im, 10, 20, 10, 5, Color("ffd890"))
	for k2 in range(8):
		rect(im, 15 - k2 * 2, 10 + k2, 1 + k2 * 4, 1, st[5 - k2 / 3])
	outline_auto(im, 0.4)
	save3(im, "stone_lantern", false)
	# улица: камни-ступени по мху
	im = new_img(64, 64)
	for y4 in range(64):
		for x4 in range(64):
			var n: float = h01(x4 / 3, y4 / 3, 61) * 0.6 + h01(x4, y4, 62) * 0.4
			px(im, x4, y4, hx(["8a8a7e", "9c9c90", "aeaea2", "c0c0b4", "d0d0c6"])[clampi(int(n * 4.0), 0, 4)])
	for k3 in range(5):
		var sx: int = int(h01(k3, 1, 63) * 56.0)
		var sy: int = k3 * 13 + 2
		ell(im, sx + 6, sy + 5, 9, 5, Color("6e6c66"))
		ell(im, sx + 6, sy + 4, 8, 4, Color("9a988e"))
	save3(im, "st10_japan", false)
	# японские дома, чайный домик, лавка и пагода
	var jp: Dictionary = {"mat": "shoji", "roof_shape": "curved", "noren": "2a3a6a", "wall": ["6e6a64", "8a867e", "b8a07a", "efe6d0", "fbf8f0"], "roof": ["22252e", "2e323e", "3c4252", "4e5668", "667086"], "trim": "3a2418", "win": "f8ecc8", "door": "6a3a24"}
	for k4 in range(2):
		var spj: Dictionary = jp.duplicate()
		spj["w"] = 170 + k4 * 20
		spj["h"] = 70
		spj["roof_h"] = 50
		if k4 == 1:
			spj["roof"] = ["4a2a1e", "64382a", "7e4a36", "985e44", "b07654"]
		building10("jp_house_" + ["a", "b"][k4], spj)
	var tea: Dictionary = jp.duplicate()
	tea.merge({"w": 220, "h": 80, "roof_h": 56, "sign": "mug", "deco": ["lamps"], "noren": "a82a22", "roof": ["5a1a14", "7a261c", "9a3424", "b44a34", "cc6a4c"]}, true)
	building10("tavern_japan", tea)
	var shp: Dictionary = jp.duplicate()
	shp.merge({"w": 170, "h": 76, "roof_h": 48, "sign": "bag"}, true)
	building10("shop_japan", shp)
	# пагода: три яруса с загнутыми крышами
	im = new_img(300, 330)
	ell(im, 150, 326, 120, 4, Color(0.1, 0.08, 0.1, 0.3))
	var tiers: Array = [[230, 90, 236], [170, 70, 156], [120, 56, 90]]
	for t in tiers:
		var w: int = t[0]
		var hh: int = t[1]
		var base_y: int = t[2] + hh
		for y5 in range(base_y - hh, base_y):
			for x5 in range(150 - w / 2, 150 + w / 2):
				px(im, x5, y5, hx(jp["wall"])[3 if x5 < 150 + w / 2 - 4 else 2])
		for x6 in range(150 - w / 2, 150 + w / 2, 18):
			rect(im, x6, base_y - hh, 3, hh, Color("8a2a1e"))
		for k5 in range(26):
			var rw: float = (w / 2.0 + 26.0) * (1.0 - k5 / 30.0) + maxf(0.0, 4.0 - k5) * 4.0
			for x7 in range(int(150 - rw), int(150 + rw)):
				px(im, x7, base_y - hh - k5, hx(jp["roof"])[2 if x7 < 150 else 1])
	rect(im, 147, 4, 6, 30, Color("c8a040"))
	for k6 in range(4):
		ell(im, 150, 10 + k6 * 6, 6, 2, Color("e0c050"))
	rect(im, 134, 286, 32, 40, Color("6a3a24"))
	outline_auto(im, 0.45)
	save3(im, "palace_japan", false)


func gen_sea12() -> void:
	var w8: Array = hx(LOG)
	# пирс: доски от берега в море (рисуется на земле)
	var im: Image = new_img(96, 520)
	for y in range(520):
		for x in range(8, 88):
			var c: Color = w8[4] if posmod(y, 14) > 1 else w8[2]
			if h01(x / 20, y / 14, 3) > 0.85:
				c = w8[3]
			px(im, x, y, c)
		if posmod(y, 90) < 8:
			rect(im, 0, y, 8, 1, w8[1])
			rect(im, 88, y, 8, 1, w8[1])
	save3(im, "pier", false)
	# водолазный колокол: будка с медным колоколом и лебёдкой
	im = new_img(110, 130)
	ell(im, 55, 126, 46, 4, Color(0.1, 0.1, 0.12, 0.3))
	box3(im, 10, 50, 90, 74, 3, w8, 4)
	for k in range(26):
		var rw: float = 52.0 * (1.0 - k / 26.0)
		rect(im, int(55 - rw), 50 - k, int(rw * 2.0), 1, Color("3a5a7a") if k % 5 != 0 else Color("2a4460"))
	var brass: Array = hx(["6a4a14", "8e661c", "b28828", "d0a83a", "e6c458", "f6e08a"])
	blob(im, 55, 92, 22, 22, brass, 3)
	ell(im, 55, 110, 24, 5, brass[1])
	disc(im, 48, 88, 6.0, Color("a0d8f0"))
	disc(im, 62, 88, 6.0, Color("a0d8f0"))
	disc(im, 55, 98, 6.0, Color("a0d8f0"))
	line(im, 55, 30, 55, 70, Color("8a7a6a"))
	outline_auto(im, 0.4)
	save3(im, "diving_bell", false)
	# дно моря
	im = new_img(64, 64)
	for y2 in range(64):
		for x2 in range(64):
			var n: float = h01(x2 / 2, y2 / 2, 71) * 0.5 + sin((x2 + y2 * 0.4) * 0.35) * 0.25 + 0.5
			px(im, x2, y2, hx(["7a7a6a", "8e8a72", "a09a7c", "b2aa88", "c2ba98"])[clampi(int(n * 3.2), 0, 4)])
	save3(im, "seabed", false)
	# коралловые домики, жемчужный дворец, водоросли, кораллы, раковина-фонарь
	for k2 in range(2):
		im = new_img(150, 150)
		var cr: Array = [hx(["8a2a3a", "b04050", "d0606a", "e88a8a", "f8b8b0"]), hx(["9a5a1a", "c07a24", "e09a38", "f0bc5a", "fadc8a"])][k2]
		ell(im, 75, 146, 60, 4, Color(0, 0, 0, 0.25))
		blob(im, 75, 92, 62, 54, cr, 2, Vector3(0.6, 0.3, 0.0))
		for k3 in range(9):
			var bx: float = 22 + k3 * 13
			capsule(im, Vector2(bx, 50), Vector2(bx + sin(k3) * 6.0, 26 + h01(k3, k2, 5) * 16.0), 3.0, 2.0, cr, 3)
		ell(im, 75, 128, 16, 18, Color("2a1a2a"))
		ell(im, 75, 124, 12, 13, Color("4a6a9a"))
		disc(im, 50, 90, 8.0, Color("a0e8ff"))
		disc(im, 100, 90, 8.0, Color("a0e8ff"))
		outline_auto(im, 0.4)
		save3(im, "coral_house_" + ["a", "b"][k2], false)
	im = new_img(280, 230)
	ell(im, 140, 226, 120, 4, Color(0, 0, 0, 0.25))
	for k4 in range(9):
		var a: float = PI + k4 * PI / 8.0
		var tip: Vector2 = Vector2(140 + cos(a) * 130.0, 210 + sin(a) * 190.0)
		capsule(im, Vector2(140, 210), tip, 6.0, 22.0, hx(["c8a8b8", "dcbcc8", "ecd2da", "f6e4ea", "fff4f8"]), 3)
	blob(im, 140, 196, 50, 30, hx(["c8a8b8", "dcbcc8", "ecd2da", "f6e4ea", "fff4f8"]), 3)
	disc(im, 140, 150, 16.0, Color("f8f4ff"))
	disc(im, 135, 145, 5.0, Color("ffffff"))
	ell(im, 140, 204, 18, 20, Color("3a2a4a"))
	outline_auto(im, 0.4)
	save3(im, "pearl_palace", false)
	im = new_img(34, 110)
	for k5 in range(3):
		for y3 in range(10, 108):
			var xx: float = 8 + k5 * 9 + sin(y3 * 0.12 + k5) * 3.0
			px(im, int(xx), y3, hx(["2a5a2a", "3e7a36", "5a9a44"])[k5])
			if posmod(y3, 14) == 0:
				ell(im, xx + 3, y3, 4, 2, hx(["3e7a36", "5a9a44", "7aba5a"])[k5])
	outline_auto(im, 0.3)
	save3(im, "kelp", false)
	for k6 in range(3):
		im = new_img(50, 46)
		var cc: Color = [Color("f06a8a"), Color("f0a040"), Color("8a6af0")][k6]
		for b in range(6):
			capsule(im, Vector2(25, 44), Vector2(10 + b * 6, 8 + h01(b, k6, 7) * 14.0), 3.0, 2.0, [cc.darkened(0.3), cc.darkened(0.1), cc, cc.lightened(0.25), cc.lightened(0.45)], 3)
		outline_auto(im, 0.35)
		save3(im, "coral_%d" % k6, false)
	im = new_img(30, 40)
	rect(im, 13, 14, 4, 24, Color("c8b8a8"))
	blob(im, 15, 10, 11, 8, hx(["d8b8c8", "ecd2da", "fff4f8", "ffffff"]), 2)
	disc(im, 15, 11, 3.0, Color("fff8d0"))
	outline_auto(im, 0.4)
	save3(im, "shell_lamp", false)
	# пузырьковый столб — путь наверх
	im = new_img(60, 120)
	for k7 in range(26):
		var bx2: float = 30 + sin(k7 * 1.7) * 14.0
		var by: float = 116 - k7 * 4.4
		var r: float = 2.0 + h01(k7, 1, 9) * 4.0
		disc(im, bx2, by, r, Color(0.8, 0.95, 1.0, 0.55))
		px(im, int(bx2 - r * 0.4), int(by - r * 0.4), Color(1, 1, 1, 0.9))
	ell(im, 30, 116, 22, 4, Color("6a8aa8"))
	save3(im, "bubble_column", false)


# ================================================================== v13: кицунэ и русалки — хвосты рисуются вместе с телом

var MERMAID: bool = false
var MER_DIR: int = 0
var MER_F: int = 0
var MER_DONE: bool = false
var MER_RAMP: Array = []
var MER_FIN: Array = []
var KITSUNE: int = 0           # сколько лисьих хвостов; 0 — обычная кошкодевочка
var _TUBE_TAN: Vector2 = Vector2.DOWN

const KIT_LOOKS: Array = [
	# имя, мех/волосы, кимоно, пояс-оби, хвостов
	["kitsune_sakura", ["8a3a1a", "b04e22", "d0682c", "e8883e", "f4aa5c", "facc88", "fee8c0"], ["c8c0c4", "e0d8dc", "eee8ea", "f8f4f6", "fcfafb", "ffffff", "ffffff"], ["7a1a2a", "9e2436", "c03448", "d84e60", "ea7480", "f6a2a8", "fcd0d2"], 2],
	["kitsune_hana", ["c8b098", "dcc6b0", "eadac8", "f4e8dc", "faf2ea", "fef9f6", "ffffff"], ["8a4a7a", "aa5e96", "c87ab0", "dc9ac6", "ecbad8", "f6d6e8", "fcecf4"], ["3a5a8a", "4a72a8", "5e8ac4", "7aa4d6", "9cbee4", "c0d6f0", "e2ecf8"], 1],
	["kitsune_aka", ["1a1418", "26202a", "34303c", "46404e", "5c5666", "766e80", "948ea0"], ["6a1a1a", "8a2222", "aa2e2c", "c84038", "dc5c4c", "ec8270", "f6b0a0"], ["1a1418", "2a2228", "3a3036", "4c4048", "60545c", "786c74", "948890"], 1],
	["kitsune_kuro", ["2a1a0e", "3e2614", "54341c", "6c4426", "865834", "a07046", "bc8c62"], ["1a1e2e", "242a40", "303854", "3e4868", "505c80", "687698", "8892b0"], ["5a1a1a", "7a2626", "9a3434", "b84a46", "d06a60", "e4908a", "f4b8b0"], 1],
]

const MER_LOOKS: Array = [
	# имя, волосы, платье, отделка, хвост (7), плавник (7), вещь
	["fishgirl_marina", ["0e3a5a", "16507a", "20689a", "3484b8", "52a2d0", "7ec0e4", "b0dcf4"], ["7a5a8a", "9a76aa", "ba96c8", "d4b4de", "e8d0ee", "f4e6f8", "ffffff"], ["1a4a5a", "226070", "2c7888", "3a92a0", "56acb8", "80c8d0", "b4e2e6"], ["0e3a4a", "145262", "1c6c7a", "288894", "3ea6ae", "66c4c4", "a6e2dc"], ["2a4a7a", "3a64a0", "5282c0", "74a2d8", "9cc2ea", "c6def6", "eef6ff"], "crown"],
	["fishgirl_koral", ["6a1a2a", "8e2a3a", "b03e4c", "cc5a62", "e07e80", "f0a8a6", "fad2ce"], ["2a5a6a", "367484", "46909e", "5eaab6", "7ec4cc", "a6dce0", "d2f0f2"], ["1a4a5a", "226070", "2c7888", "3a92a0", "56acb8", "80c8d0", "b4e2e6"], ["5a1422", "7c1e2e", "a02c3a", "c0444a", "da6660", "ec9284", "f8c6b6"], ["8a2a4a", "b0405e", "d05c76", "e68296", "f4aab8", "fcd2da", "fff0f2"], ""],
	["fishgirl_perla", ["8a8aa0", "a6a6ba", "c2c2d2", "dadae6", "ececf4", "f6f6fa", "ffffff"], ["1e4a6a", "285e86", "3474a2", "468ebc", "62a8d2", "8ac4e4", "b8def2"], ["1a4a5a", "226070", "2c7888", "3a92a0", "56acb8", "80c8d0", "b4e2e6"], ["2a2a5a", "36387a", "48509a", "5e6eb8", "7e92d0", "a8bce4", "d6e2f6"], ["4a3a7a", "6450a0", "8270c0", "a294d8", "c4b8ea", "e2dcf6", "faf8ff"], ""],
	["fishgirl_tida", ["0a3a2a", "12503a", "1c684c", "2c8460", "44a078", "6cbc96", "a0d8b8"], ["2a3a5a", "364c74", "46628e", "5a7aa8", "7894c0", "9cb2d6", "c6d4ea"], ["1a4a5a", "226070", "2c7888", "3a92a0", "56acb8", "80c8d0", "b4e2e6"], ["123a1e", "1a5028", "246a34", "348644", "4ca45a", "74c27a", "aadea6"], ["1a4a3a", "246650", "32846a", "4aa286", "6ec0a4", "9cdcc4", "d0f2e4"], "spear"],
]


## Точки кривой Catmull-Rom через опорные точки (sub — шагов между точками)
func spline_pts(pts: Array, sub: int) -> Array:
	var out: Array = []
	var n: int = pts.size()
	for i in range(n - 1):
		var p0: Vector2 = pts[maxi(0, i - 1)]
		var p1: Vector2 = pts[i]
		var p2: Vector2 = pts[i + 1]
		var p3: Vector2 = pts[mini(n - 1, i + 2)]
		for k in range(sub):
			var t: float = float(k) / float(sub)
			var t2: float = t * t
			var t3: float = t2 * t
			out.append(0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3))
	out.append(pts[n - 1])
	return out


func _cum_len(q: Array) -> PackedFloat32Array:
	var cum: PackedFloat32Array = PackedFloat32Array([0.0])
	for j in range(1, q.size()):
		cum.append(cum[j - 1] + (q[j] as Vector2).distance_to(q[j - 1]))
	return cum


## Ближайшая точка ломаной: x — доля длины 0..1, y — расстояние со знаком (сторона), z — путь вдоль, в пикселях.
## Касательная в этой точке — в _TUBE_TAN.
func _tube_hit(q: Array, cum: PackedFloat32Array, p: Vector2) -> Vector3:
	var best: float = 1e9
	var res: Vector3 = Vector3.ZERO
	var total: float = maxf(0.001, cum[cum.size() - 1])
	for j in range(q.size() - 1):
		var a: Vector2 = q[j]
		var ab: Vector2 = (q[j + 1] as Vector2) - a
		var l2: float = maxf(0.0001, ab.length_squared())
		var t: float = clampf((p - a).dot(ab) / l2, 0.0, 1.0)
		var c: Vector2 = a + ab * t
		var d2: float = p.distance_squared_to(c)
		if d2 < best:
			best = d2
			var along: float = cum[j] + sqrt(l2) * t
			var cr: float = ab.cross(p - a)
			res = Vector3(along / total, sqrt(d2) * (-1.0 if cr < 0.0 else 1.0), along)
			_TUBE_TAN = ab / sqrt(l2)
	return res


func _bbox(q: Array, pad: float) -> Rect2:
	var lo: Vector2 = q[0]
	var hi: Vector2 = q[0]
	for v in q:
		lo = lo.min(v)
		hi = hi.max(v)
	return Rect2(lo - Vector2.ONE * pad, hi - lo + Vector2.ONE * pad * 2.0)


## Пушистый лисий хвост: тонкий у спины, толстый в середине, белый острый кончик,
## по краю — зубчики шерсти, внутри — пряди вдоль хвоста.
func fox_tail(im: Image, pts: Array, rmax: float, seed_v: int) -> void:
	var q: Array = spline_pts(pts, 8)
	var cum: PackedFloat32Array = _cum_len(q)
	var bb: Rect2 = _bbox(q, rmax + 4.0)
	var light: Vector2 = Vector2(-0.6, -0.8)
	var tipr: Array = hx(["a89c9c", "c4bab8", "dcd4d2", "eeeae8", "f8f6f4", "ffffff", "ffffff"])
	for y in range(int(bb.position.y), int(bb.end.y) + 1):
		for x in range(int(bb.position.x), int(bb.end.x) + 1):
			var h: Vector3 = _tube_hit(q, cum, Vector2(x + 0.5, y + 0.5))
			var t: float = h.x
			var r: float
			if t < 0.55:
				r = lerpf(2.6, rmax, sin(t / 0.55 * PI * 0.5))
			else:
				r = lerpf(rmax, 0.5, pow((t - 0.55) / 0.45, 1.5))
			var sd: int = 0 if h.y < 0.0 else 1
			var seg: int = int(h.z / 4.6)
			var ph: float = fposmod(h.z / 4.6 + float(sd) * 0.5 + h01(seg, sd, seed_v) * 0.35, 1.0)
			var spike: float = (1.0 - absf(ph * 2.0 - 1.0)) * clampf(r * 0.24, 0.5, 1.8) * (1.0 - clampf((t - 0.7) / 0.3, 0.0, 0.7))
			if t < 0.1:
				spike = 0.0
			var d: float = absf(h.y)
			if d > r + spike - 0.5:
				continue
			var s: float = clampf(h.y / maxf(0.8, r), -1.0, 1.0)
			var nrm: Vector2 = Vector2(-_TUBE_TAN.y, _TUBE_TAN.x) * s
			var l: float = nrm.dot(light) * absf(s) * 1.2 + (1.0 - absf(s)) * 0.3
			var ti: int = 4 + int(round(l * 2.0))
			if d > r - 0.3:
				ti -= 1
			# пряди: тонкие тёмные линии вдоль хвоста, чуть закручены
			var strand: float = fposmod(h.y * 0.85 + h.z * 0.14 + h01(int(h.z / 7.0), int(floor(h.y)), seed_v + 3) * 0.7, 2.8)
			if strand < 0.6 and absf(s) < 0.9:
				ti -= 1
			elif strand > 2.35 and l > 0.05:
				ti += 1
			var tip_edge: float = 0.74 + (h01(int(floor(h.y * 0.6)) + 40, 7, seed_v) - 0.5) * 0.05 + absf(s) * 0.03
			var ramp: Array = tipr if t > tip_edge else HAIRL7
			px(im, x, y, ramp[clampi(ti, 0, 6)])


const FOX_PTS: Dictionary = {
	0: [Vector2(44, 72), Vector2(52, 81), Vector2(60, 81), Vector2(65, 71), Vector2(66, 59), Vector2(63, 49)],
	1: [Vector2(40, 71), Vector2(41, 82), Vector2(47, 90), Vector2(56, 86), Vector2(60, 74), Vector2(59, 62)],
	2: [Vector2(47, 71), Vector2(55, 78), Vector2(62, 76), Vector2(67, 66), Vector2(67, 55), Vector2(64, 46)],
	4: [Vector2(46, 73), Vector2(54, 82), Vector2(62, 80), Vector2(66, 70), Vector2(67, 58), Vector2(64, 49)],
	5: [Vector2(43, 72), Vector2(45, 83), Vector2(52, 90), Vector2(60, 85), Vector2(63, 73), Vector2(62, 61)],
}


func _fox_pts(dir: int, b: int, sway: float, second: bool) -> Array:
	var src: Array = FOX_PTS[dir]
	var base: Vector2 = src[0]
	var out: Array = []
	for i in range(src.size()):
		var t: float = float(i) / float(src.size() - 1)
		var p: Vector2 = (src[i] as Vector2)
		if second:
			if dir == 0 or dir == 1:
				p.x = 80.0 - p.x          # второй хвост — на другую сторону
			else:
				p = base + (p - base).rotated(-0.42) * 0.92
		out.append(p + Vector2(sway * t * t * (-1.0 if second and (dir == 0 or dir == 1) else 1.0), -absf(sway) * 0.2 * t + float(b)))
	return out


func kit_tails(im: Image, dir: int, b: int, sway: float) -> void:
	if KITSUNE >= 2:
		fox_tail(im, _fox_pts(dir, b, sway * 0.8, true), 7.4, 23)
	fox_tail(im, _fox_pts(dir, b, sway, false), 8.4, 11)


## Лисьи ушки: выше и острее кошачьих, с тёмными кончиками и белым пухом внутри
func fox_ear(im: Image, a: Vector2, b2: Vector2, t: Vector2, inner: bool) -> void:
	var m: Vector2 = (a + b2) / 2.0
	var tip: Vector2 = m + (t - m) * 1.28
	var dv: Vector2 = (b2 - a).normalized()
	cat_ear_h(im, a - dv * 0.8, b2 + dv * 0.8, tip, false)
	# тёмный кончик
	for k in range(5):
		var p: Vector2 = tip.lerp(m, float(k) / 14.0)
		var w: int = k / 2
		for dx in range(-w, w + 1):
			px(im, int(p.x) + dx, int(p.y), HAIRL7[0] if k < 3 else HAIRL7[1])
	if inner:
		var cream: Array = hx(["d8c8c0", "eadcd4", "f8f0ea", "ffffff"])
		var ia: Vector2 = a.lerp(m, 0.3) + Vector2(0, -1)
		var ib: Vector2 = b2.lerp(m, 0.3) + Vector2(0, -1)
		var it: Vector2 = tip.lerp(m, 0.34)
		tri(im, ia, ib, it, func(_x: int, y: int, _u: float) -> Color: return cream[2] if y > int(it.y) + 3 else cream[1])
		# пух прядками из уха
		for k2 in range(3):
			var fp: Vector2 = m.lerp(it, 0.25 + k2 * 0.18) + Vector2((k2 - 1) * 1.0, 0)
			px(im, int(fp.x), int(fp.y), cream[3])
			px(im, int(fp.x), int(fp.y) - 1, cream[2])


## Кимоно поверх платья: вырез запахом, широкий пояс-оби с узлом, мелкий узор цветов
func kimono13(im: Image, dir: int, f: int) -> void:
	var b: int = -1 if (f == 1 or f == 3 or f == 6 or f == 7) else 0
	var w: int = im.get_width()
	var h: int = im.get_height()
	var dress: Dictionary = {}
	for c in WHITE7:
		dress[(c as Color).to_html(false)] = true
	# узор: пятилепестковые цветочки цвета пояса на ткани
	for gy in range(40 + b, 98 + b, 7):
		for gx in range(18, 64, 7):
			var ox: int = gx + (3 if posmod(gy / 7, 2) == 1 else 0) + int(h01(gx, gy, 5) * 2.0)
			var oy: int = gy + int(h01(gx, gy, 6) * 2.0)
			if not dress.has(im.get_pixel(clampi(ox, 0, w - 1), clampi(oy, 0, h - 1)).to_html(false)):
				continue
			var ok: bool = true
			for p in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
				var pv: Vector2i = p
				if not dress.has(im.get_pixel(clampi(ox + pv.x, 0, w - 1), clampi(oy + pv.y, 0, h - 1)).to_html(false)):
					ok = false
			if not ok:
				continue
			var lit: bool = im.get_pixel(ox, oy).get_luminance() > WHITE7[3].get_luminance()
			var pc: Color = TEAL7[5] if lit else TEAL7[3]
			for p2 in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
				var pv2: Vector2i = p2
				px(im, ox + pv2.x, oy + pv2.y, pc)
			px(im, ox, oy, Color("f6d24a"))
	# оби: широкий пояс там, где ткань (поверх старого ремешка)
	for y in range(56 + b, 65 + b):
		for x in range(14, 66):
			var c2: Color = im.get_pixel(x, y)
			if c2.a < 0.5:
				continue
			if not dress.has(c2.to_html(false)) and not (c2.get_luminance() < 0.45 and c2.r > c2.b):
				continue
			var u: float = float(y - 56 - b) / 8.0
			var ti: int = 4 if u < 0.25 else (3 if u < 0.8 else 2)
			if y == 60 + b:
				ti = 5
			px(im, x, y, TEAL7[ti])
	# шнур-обидзимэ посередине пояса
	for x2 in range(14, 66):
		if im.get_pixel(x2, 60 + b).is_equal_approx(TEAL7[5]):
			px(im, x2, 60 + b, Color("f0c850") if posmod(x2, 3) != 0 else Color("c89a30"))
	if dir == 0 or dir == 4:
		# запах: левая пола поверх правой — косая линия отделки от шеи к поясу
		var cx: float = 40.0 if dir == 0 else 41.5
		for k in range(15):
			var y3: int = 41 + b + k
			var x3: int = int(cx - 4.0 + float(k) * 0.55)
			px(im, x3, y3, TEAL7[4])
			px(im, x3 + 1, y3, TEAL7[2])
			var x4: int = int(cx + 4.0 - float(k) * 0.3)
			if k < 9:
				px(im, x4, y3, TEAL7[3])
	if dir == 1 or dir == 5:
		# бант-узел оби на спине
		var bc: Vector2 = Vector2(40 if dir == 1 else 39, 60 + b)
		blob(im, bc.x - 6.0, bc.y - 1.0, 6.0, 4.2, TEAL7, 3)
		blob(im, bc.x + 6.0, bc.y - 1.0, 6.0, 4.2, TEAL7, 3)
		rect(im, int(bc.x) - 4, int(bc.y) + 2, 4, 10, TEAL7[2])
		rect(im, int(bc.x), int(bc.y) + 2, 4, 9, TEAL7[3])
		blob(im, bc.x, bc.y, 3.0, 3.6, TEAL7, 4)


## Рыбий хвост вместо ног: чешуя рядами, боковые плавники, хвостовой плавник с лучами.
## Рисуется один раз за кадр — на месте первой ноги (под подолом платья).
const MER_HIP: Dictionary = {0: Vector2(40, 71), 1: Vector2(40, 71), 2: Vector2(40.5, 71), 4: Vector2(40.5, 73), 5: Vector2(40.5, 73)}
const MER_R: Array = [Vector2(0.0, 12.0), Vector2(0.2, 11.4), Vector2(0.42, 9.0), Vector2(0.64, 6.2), Vector2(0.86, 3.4), Vector2(1.0, 2.8)]


func _mer_r(t: float) -> float:
	for i in range(MER_R.size() - 1):
		var a: Vector2 = MER_R[i]
		var c: Vector2 = MER_R[i + 1]
		if t <= c.x:
			var u: float = (t - a.x) / maxf(0.001, c.x - a.x)
			return lerpf(a.y, c.y, u * u * (3.0 - 2.0 * u))
	return (MER_R[MER_R.size() - 1] as Vector2).y


func mer_tail_once(im: Image) -> void:
	if MER_DONE:
		return
	MER_DONE = true
	var dir: int = MER_DIR
	var f: int = MER_F
	var b: int = -1 if (f == 1 or f == 3 or f == 6 or f == 7) else 0
	var swim: bool = f <= 3
	var ph: float = float(f) * PI * 0.5
	var amp: float = 3.4 if swim else 1.4
	var hip: Vector2 = (MER_HIP[dir] as Vector2) + Vector2(0, b)
	var side: bool = dir == 2
	var lean: float = 0.0
	if dir == 4:
		lean = 3.0
	elif dir == 5:
		lean = -2.0
	var pts: Array = []
	for k in range(7):
		var t: float = float(k) / 6.0
		var x: float = hip.x + lean * t * t
		var y: float = hip.y + t * 64.0
		if side:
			# сбоку хвост изгибается назад и снова вперёд — как у плывущей рыбы
			x += sin(t * PI) * 4.0 + t * t * 7.0
			x += sin(ph + t * 2.6) * amp * t * t
		else:
			x += sin(ph + t * 2.6) * amp * t * t
		pts.append(Vector2(x, y))
	var q: Array = spline_pts(pts, 6)
	var cum: PackedFloat32Array = _cum_len(q)
	var end: Vector2 = q[q.size() - 1]
	var end_dir: Vector2 = (end - (q[q.size() - 4] as Vector2)).normalized()
	var R: Array = MER_RAMP
	var FIN: Array = MER_FIN
	# боковые плавнички (дальний — до хвоста)
	var mid_i: int = int(q.size() * 0.6)
	var mid: Vector2 = q[mid_i]
	var swing: float = sin(ph + 1.2) * (0.25 if swim else 0.1)
	if side:
		fin_fan(im, mid + Vector2(-2, 0), PI * 0.62 + swing, 0.7, 8.0, FIN, 3)
	# хвостовой плавник: две лопасти с лучами
	var fa: float = end_dir.angle()
	var fswing: float = sin(ph + 2.4) * (0.28 if swim else 0.12)
	if side:
		fin_fan(im, end, fa - 0.35 + fswing, 1.25, 17.0, FIN, 5)
	elif dir == 4 or dir == 5:
		fin_fan(im, end + Vector2(0, -2), fa + 0.6 + fswing, 1.25, 14.0, FIN, 5)
		fin_fan(im, end + Vector2(0, -2), fa - 0.62 + fswing, 1.25, 17.0, FIN, 5)
	else:
		fin_fan(im, end + Vector2(0, -2), fa + 0.62 + fswing, 1.25, 16.0, FIN, 5)
		fin_fan(im, end + Vector2(0, -2), fa - 0.62 + fswing, 1.25, 16.0, FIN, 5)
	# тело хвоста
	var bb: Rect2 = _bbox(q, 12.0)
	var light: Vector2 = Vector2(-0.6, -0.8)
	for y in range(int(bb.position.y), int(bb.end.y) + 1):
		for x in range(int(bb.position.x), int(bb.end.x) + 1):
			var h: Vector3 = _tube_hit(q, cum, Vector2(x + 0.5, y + 0.5))
			var r: float = _mer_r(h.x)
			if side:
				r *= 0.86
			var d: float = absf(h.y)
			if d > r:
				continue
			if h.x >= 0.999 and d > 1.2:
				continue
			var s: float = h.y / maxf(0.8, r)
			var nrm: Vector2 = Vector2(-_TUBE_TAN.y, _TUBE_TAN.x) * s
			var l: float = nrm.dot(light) * absf(s) * 1.25 + (1.0 - absf(s)) * 0.35
			var ti: int = 3 + int(round(l * 2.2))
			# чешуя: ряды полукружий со сдвигом через ряд, чешуйки к кончику мельче
			var sc: float = lerpf(3.6, 2.2, h.x)
			var row: int = int(floor(h.z / sc))
			var lu: float = fposmod(h.y + (sc * 0.5 if posmod(row, 2) == 1 else 0.0), sc) - sc * 0.5
			var lv: float = fposmod(h.z, sc)
			var edge: float = sc * 0.78 - (lu * lu) / (sc * 0.55)
			if lv > edge:
				ti -= 1
			elif lv < sc * 0.3 and absf(lu) < sc * 0.22 and l > -0.2:
				ti += 1
			if d > r - 0.8 and l < 0.0:
				ti -= 1
			# у самого подола хвост в тени от платья
			if h.z < 6.0:
				ti -= 1
			px(im, x, y, R[clampi(ti, 0, 6)])
	# переливы: редкие яркие чешуйки на освещённой стороне
	for k3 in range(4):
		var t3: float = 0.12 + h01(k3, 3, 77) * 0.7
		var qi: int = clampi(int(t3 * float(q.size() - 1)), 0, q.size() - 1)
		var c3: Vector2 = q[qi]
		var off: float = -_mer_r(t3) * (0.25 + h01(k3, 4, 77) * 0.4)
		var p3: Vector2 = c3 + Vector2(off, 0)
		if a_at(im, int(p3.x), int(p3.y)) > 0.5:
			px(im, int(p3.x), int(p3.y), R[6])
	# ближний боковой плавничок — поверх хвоста
	if side:
		fin_fan(im, mid + Vector2(1, 1), PI * 0.42 + swing, 0.8, 9.0, FIN, 3)
	else:
		var rr: float = _mer_r(0.6)
		fin_fan(im, mid + Vector2(-rr + 1.0, 0), PI * 0.5 + 0.95 + swing, 0.7, 8.0, FIN, 3)
		fin_fan(im, mid + Vector2(rr - 1.0, 0), PI * 0.5 - 0.95 - swing, 0.7, 8.0, FIN, 3)


## Плавник-веер: от корня root в сторону ang, раскрытие spread, длина L; лучи темнее, край волнистый и светлее
func fin_fan(im: Image, root: Vector2, ang: float, spread: float, L: float, ramp: Array, rays: int) -> void:
	var steps: int = int(spread * L * 2.2) + 6
	for i in range(steps + 1):
		var u: float = float(i) / float(steps)
		var a: float = ang - spread * 0.5 + spread * u
		var rp: float = fposmod(u * float(rays) + 0.5, 1.0)
		var ln: float = L * (0.94 + 0.06 * cos((rp - 0.5) * TAU)) * (0.8 + 0.2 * sin(u * PI))
		var on_ray: bool = absf(rp - 0.5) < 0.1
		for r in range(1, int(ln) + 1):
			var p: Vector2 = root + Vector2(cos(a), sin(a)) * float(r)
			var tt: float = float(r) / ln
			var ti: int = 2 + int(tt * 3.2)
			if on_ray and tt < 0.88:
				ti -= 1
			if u < 0.12:
				ti -= 1
			if r >= int(ln):
				ti = 5
			var c: Color = ramp[clampi(ti, 0, ramp.size() - 1)]
			if tt > 0.72:
				c.a = 0.82
			px(im, int(p.x), int(p.y), c)


func gen_people13() -> void:
	var sh: Array = HAIRL7.duplicate()
	var sw7: Array = WHITE7.duplicate()
	var st: Array = TEAL7.duplicate()
	var fw: int = 80
	var fh: int = 160
	var mirror: Dictionary = {2: 3, 4: 6, 5: 7}
	BOUNCE_OVR = 0
	NO_CAPE = true
	var all_n: int = KIT_LOOKS.size() + MER_LOOKS.size()
	var line_up: Image = new_img(fw * all_n * 2, fh)
	var li: int = 0
	# --- кицунэ
	for lk in KIT_LOOKS:
		HAIRL7 = hx(lk[1])
		WHITE7 = hx(lk[2])
		TEAL7 = hx(lk[3])
		EYE_OVR = {"I": Color("6a2a10"), "i": Color("d07a2a"), "j": Color("fcd890")}
		_head_pal()
		KITSUNE = int(lk[4])
		var vs: Image = new_img(fw * 8, fh * 8)
		for vd in [0, 1, 2, 4, 5]:
			for k in range(8):
				var c2: Image = new_img(fw, fh)
				draw_catgirl(c2, vd, k)
				kimono13(c2, vd, k)
				if String(lk[0]) == "kitsune_sakura":
					crown(c2, vd, k, "tiara")
				outline_auto(c2, OUTLINE_CHAR)
				vs.blit_rect(c2, Rect2i(0, 0, fw, fh), Vector2i(k * fw, vd * fh))
				if mirror.has(vd):
					var mc: Image = c2.duplicate()
					mc.flip_x()
					vs.blit_rect(mc, Rect2i(0, 0, fw, fh), Vector2i(k * fw, int(mirror[vd]) * fh))
		save3(vs, String(lk[0]))
		gen_faces10("faces_" + String(lk[0]))
		line_up.blit_rect(vs, Rect2i(4 * fw, 0, fw, fh), Vector2i(li * fw, 0))
		line_up.blit_rect(vs, Rect2i(4 * fw, 2 * fh, fw, fh), Vector2i((li + 1) * fw, 0))
		li += 2
	KITSUNE = 0
	# --- русалки
	for lk2 in MER_LOOKS:
		HAIRL7 = hx(lk2[1])
		WHITE7 = hx(lk2[2])
		TEAL7 = hx(lk2[3])
		MER_RAMP = hx(lk2[4])
		MER_FIN = hx(lk2[5])
		EYE_OVR = {"I": Color("0e3a5a"), "i": Color("2a8ac8"), "j": Color("a8e4ff")}
		_head_pal()
		MERMAID = true
		var vs2: Image = new_img(fw * 8, fh * 8)
		for vd2 in [0, 1, 2, 4, 5]:
			for k2 in range(8):
				var c3: Image = new_img(fw, fh)
				MER_DIR = vd2
				MER_F = k2
				MER_DONE = false
				draw_elfgirl(c3, vd2, k2, String(lk2[6]))
				outline_auto(c3, OUTLINE_CHAR)
				vs2.blit_rect(c3, Rect2i(0, 0, fw, fh), Vector2i(k2 * fw, vd2 * fh))
				if mirror.has(vd2):
					var mc2: Image = c3.duplicate()
					mc2.flip_x()
					vs2.blit_rect(mc2, Rect2i(0, 0, fw, fh), Vector2i(k2 * fw, int(mirror[vd2]) * fh))
		MERMAID = false
		save3(vs2, String(lk2[0]))
		gen_faces10("faces_" + String(lk2[0]))
		line_up.blit_rect(vs2, Rect2i(0, 0, fw, fh), Vector2i(li * fw, 0))
		line_up.blit_rect(vs2, Rect2i(0, 2 * fh, fw, fh), Vector2i((li + 1) * fw, 0))
		li += 2
	line_up.resize(line_up.get_width() * 3, line_up.get_height() * 3, Image.INTERPOLATE_NEAREST)
	line_up.save_png(ProjectSettings.globalize_path("res://").path_join("../screenshots/v13_people.png"))
	EYE_OVR = {}
	NO_CAPE = false
	HAIRL7 = sh
	WHITE7 = sw7
	TEAL7 = st
	_head_pal()


# ================================================================== v13: море — пирс, колокол, пляж, подводный город

const SHELL7: Array = ["7a5a5e", "9c7a78", "bc9a92", "d8b8aa", "ecd4c4", "f8eade", "fffaf2"]
const PEARL7: Array = ["7a7a96", "9a9ab4", "babad0", "d6d6e6", "eaeaf4", "f6f6fc", "ffffff"]
const BRASS7: Array = ["4a300c", "6a4a14", "8e661c", "b28828", "d0a83a", "e6c458", "f8e48e"]
const PINKC7: Array = ["6a1e36", "8e2c48", "b2405c", "cc5c72", "e2828e", "f2aab0", "fcd4d4"]
const ORANC7: Array = ["6a2a10", "92401a", "b85a24", "d47834", "e89a4c", "f4be72", "fcdca4"]
const VIOC7: Array = ["2e1a5a", "442a80", "5c3ea4", "7a5ac0", "9a80d6", "beaae8", "e0d6f6"]
const KELP7: Array = ["14301a", "1e4424", "2a5a2e", "3a723a", "52904a", "70ac5e", "98c87c"]
const DRIFT7: Array = ["3a3028", "52463a", "6a5c4c", "84765e", "9e9076", "b8ac92", "d2c8b0"]
const SANDW7: Array = ["8a7a5a", "a08e6a", "b4a27c", "c8b690", "d8c8a2", "e6d8b6", "f2e8cc"]


func _rampi(r: Array, i: int) -> Color:
	return r[clampi(i, 0, r.size() - 1)]


## Доска поперёк пирса: волокна, сучок, торцы светлее, гвозди над балками
func plank13(im: Image, x0: int, y0: int, w: int, h: int, ramp: Array, seed_v: int) -> void:
	var knot: Vector2 = Vector2(x0 + 10 + h01(seed_v, 1, 3) * float(w - 20), y0 + h * 0.5)
	for y in range(y0, y0 + h):
		for x in range(x0, x0 + w):
			var v: float = float(y - y0) / float(h - 1)
			var ti: int = 4
			if v < 0.2:
				ti = 5
			elif v > 0.8:
				ti = 3
			if y == y0 + h - 1:
				ti = 2
			var gr: float = sin(float(x) * 0.09 + float(y - y0) * 1.7 + h01(y, seed_v, 5) * 6.0)
			if gr > 0.82:
				ti -= 1
			var kd: float = Vector2(x, y).distance_to(knot)
			if kd < 2.6:
				ti = 2 if kd < 1.4 else 3
			elif kd < 4.5 and absf(float(y) - knot.y) < 1.0:
				ti -= 1
			if (x == x0 or x == x0 + w - 1):
				ti -= 1
			if h01(x / 9, y + seed_v, 8) > 0.93:
				ti -= 1
			px(im, x, y, _rampi(ramp, ti))


func gen_sea13() -> void:
	var w7: Array = hx(LOG)
	var dr: Array = hx(DRIFT7)
	var brass: Array = hx(BRASS7)
	var items: Array = []
	var im: Image
	# ---------------------------------------------------------------- пирс (вид сверху, щели прозрачные — видно воду)
	var PW: int = 112
	var PL: int = 600
	im = new_img(PW + 40, PL)
	var weath: Array = hx(["3a2c22", "54402e", "6e563e", "887050", "a08a66", "b8a27e", "d0bc98"])
	for k in range(PL / 11):
		var y0: int = k * 11
		var off: int = int(h01(k, 3, 1) * 5.0) - 2
		var ramp: Array = weath if h01(k, 4, 2) > 0.3 else w7
		plank13(im, 20 + off, y0, PW + int(h01(k, 5, 1) * 4.0) - 2, 9, ramp, k)
		# гвозди над продольными балками
		for bx in [26, 20 + PW / 2, 14 + PW]:
			px(im, bx + off, y0 + 3, Color("3a3438"))
			px(im, bx + off, y0 + 5, Color("3a3438"))
			px(im, bx + off + 1, y0 + 3, Color("8a8890"))
	# сваи по бокам: круглые торцы брёвен с кольцами и верёвкой
	for k2 in range(0, PL - 20, 96):
		for sx in [12, PW + 28]:
			var cy: float = float(k2) + 20.0
			for y in range(int(cy) - 9, int(cy) + 10):
				for x in range(sx - 9, sx + 10):
					var d: float = Vector2(x + 0.5, y + 0.5).distance_to(Vector2(sx, cy))
					if d > 8.6:
						continue
					var ring: int = int(d * 0.9) % 2
					var l: float = (Vector2(x + 0.5, y + 0.5) - Vector2(sx, cy)).normalized().dot(Vector2(-0.6, -0.8))
					var ti: int = 5 - ring
					if d > 7.4:
						ti = 3 if l > 0.0 else 1
					if d < 1.2:
						ti = 2
					px(im, x, y, w7[clampi(ti, 0, 6)])
			# верёвка вокруг сваи
			for a in range(28):
				var ang: float = TAU * float(a) / 28.0
				var rp: Vector2 = Vector2(sx, cy + 12.0) + Vector2(cos(ang) * 9.0, sin(ang) * 3.0)
				px(im, int(rp.x), int(rp.y), Color("d8c08a") if a % 3 != 0 else Color("a88a58"))
	# канатные перила между сваями (провисают)
	for k3 in range(0, PL - 116, 96):
		for sx2 in [12, PW + 28]:
			for i in range(97):
				var t: float = float(i) / 96.0
				var yy: float = float(k3) + 20.0 + float(i) + sin(t * PI) * 0.0
				var xx: float = float(sx2) + sin(t * PI) * (4.0 if sx2 < 40 else -4.0)
				px(im, int(xx), int(yy), Color("cfb47e") if i % 4 != 0 else Color("9c8050"))
	outline_auto(im, 0.35)
	save3(im, "pier", false)
	# тень пирса на воде
	var shd: Image = new_img(PW + 40, PL)
	for y in range(PL):
		for x in range(14, PW + 30):
			shd.set_pixel(x, y, Color(0.02, 0.08, 0.16, 0.42))
	save3(shd, "pier_shadow", false)
	# ---------------------------------------------------------------- водолазный колокол на кран-балке
	im = new_img(150, 170)
	ell(im, 75, 164, 58, 5, Color(0.05, 0.08, 0.1, 0.3))
	# основание-помост
	box3(im, 22, 140, 106, 22, 4, w7, 4)
	for xx2 in range(26, 126, 12):
		line(im, xx2, 141, xx2, 160, w7[2])
	# стойки буквой П
	for sx3 in [30, 116]:
		for y in range(26, 142):
			for x in range(sx3, sx3 + 7):
				var u: float = float(x - sx3) / 6.0
				px(im, x, y, w7[5 if u < 0.3 else (4 if u < 0.7 else 2)])
			if posmod(y, 22) == 0:
				rect(im, sx3, y, 7, 1, w7[2])
	box3(im, 24, 18, 106, 9, 2, w7, 4)
	# блок со шкивом
	disc(im, 76, 31, 6.0, IRON7()[2])
	disc(im, 76, 31, 4.0, IRON7()[4])
	disc(im, 76, 31, 1.5, IRON7()[1])
	# канат к колоколу
	for y in range(36, 66):
		px(im, 76, y, Color("cfb47e") if posmod(y, 3) != 0 else Color("9c8050"))
		px(im, 77, y, Color("a88a58"))
	# ворот с ручкой
	box3(im, 100, 112, 16, 12, 2, w7, 3)
	disc(im, 108, 114, 7.0, w7[3])
	disc(im, 108, 114, 5.0, w7[5])
	line(im, 108, 114, 118, 106, IRON7()[3])
	rect(im, 117, 103, 3, 5, w7[2])
	for k4 in range(6):
		line(im, 78, 40 + k4, 106, 108 + k4 % 2, Color(0.8, 0.7, 0.5, 0.0))
	# сам колокол: купол, пояса заклёпок, иллюминаторы
	for y in range(64, 132):
		var t2: float = float(y - 64) / 67.0
		var hw: float = 14.0 + 16.0 * pow(t2, 0.7)
		if t2 > 0.9:
			hw += (t2 - 0.9) * 40.0
		for x in range(int(76 - hw), int(76 + hw) + 1):
			var u2: float = (float(x) + 0.5 - (76.0 - hw)) / (2.0 * hw)
			var ti2: int = 3
			if u2 < 0.18:
				ti2 = 4
			elif u2 < 0.34:
				ti2 = 6 if u2 > 0.22 and u2 < 0.28 else 5
			elif u2 > 0.82:
				ti2 = 1
			elif u2 > 0.66:
				ti2 = 2
			if y == 64 or y == 65:
				ti2 += 1
			px(im, x, y, brass[clampi(ti2, 0, 6)])
		if y == 80 or y == 104 or y == 126:
			for x2 in range(int(76 - hw) + 2, int(76 + hw) - 1, 4):
				px(im, x2, y, brass[6])
				px(im, x2, y + 1, brass[1])
	# крышка-купол и кольцо
	blob(im, 76, 66, 14, 6, brass, 4)
	disc(im, 76, 60, 3.5, brass[2])
	disc(im, 76, 60, 2.0, Color(0, 0, 0, 0))
	for p3 in [Vector2(64, 96), Vector2(88, 96), Vector2(76, 112)]:
		var pv: Vector2 = p3
		disc(im, pv.x, pv.y, 7.0, brass[1])
		disc(im, pv.x, pv.y, 5.6, brass[5])
		disc(im, pv.x, pv.y, 4.4, Color("2a5a7a"))
		disc(im, pv.x + 0.5, pv.y + 0.5, 3.6, Color("4a8ab0"))
		px(im, int(pv.x) - 2, int(pv.y) - 2, Color("e8f8ff"))
		px(im, int(pv.x) - 1, int(pv.y) - 2, Color("bfe4f6"))
		px(im, int(pv.x) - 2, int(pv.y) - 1, Color("bfe4f6"))
		for a2 in range(8):
			var an: float = TAU * float(a2) / 8.0
			px(im, int(pv.x + cos(an) * 6.3), int(pv.y + sin(an) * 6.3), brass[6])
	# бухта каната на помосте
	for k5 in range(4):
		ell(im, 44, 146, 11 - k5 * 2, 4 - k5 * 0.7, Color("cfb47e") if k5 % 2 == 0 else Color("9c8050"))
	outline_auto(im, 0.4)
	save3(im, "diving_bell", false)
	items.append(["diving_bell", im])
	# ---------------------------------------------------------------- пальмы
	for pv2 in range(2):
		im = new_img(140, 170)
		rng.seed = 900 + pv2
		ell(im, 64, 165, 26, 4, Color(0.1, 0.08, 0.04, 0.28))
		var bend: float = 18.0 if pv2 == 0 else -12.0
		var top: Vector2 = Vector2(64 + bend, 46)
		var trunk_pts: Array = [Vector2(64, 166), Vector2(64 + bend * 0.1, 130), Vector2(64 + bend * 0.45, 90), top]
		var tq: Array = spline_pts(trunk_pts, 12)
		var tr: Array = hx(["3a2a1c", "54402a", "6e563a", "8a6e4c", "a68a62", "c2a67c", "dcc49c"])
		for i in range(tq.size() - 1, -1, -1):
			var c: Vector2 = tq[i]
			var t3: float = float(i) / float(tq.size() - 1)
			var rr: float = lerpf(7.0, 4.6, t3)
			var seg: bool = posmod(i, 5) == 0
			for x in range(int(c.x - rr) - 1, int(c.x + rr) + 2):
				var u3: float = (float(x) + 0.5 - (c.x - rr)) / (2.0 * rr)
				if u3 < 0.0 or u3 > 1.0:
					continue
				var ti3: int = 5 if u3 < 0.25 else (4 if u3 < 0.6 else (3 if u3 < 0.85 else 2))
				if seg:
					ti3 -= 2 if u3 > 0.5 else 1
				px(im, x, int(c.y), tr[clampi(ti3, 0, 6)])
				px(im, x, int(c.y) + 1, tr[clampi(ti3 - (1 if seg else 0), 0, 6)])
		# кокосы
		for cc in [Vector2(-4, 6), Vector2(3, 7), Vector2(-1, 11), Vector2(6, 3)]:
			var cv: Vector2 = cc
			blob(im, top.x + cv.x, top.y + cv.y, 4.0, 4.0, hx(["2a1a10", "3e2818", "56381e", "6e4a28", "8a6236", "a67c4a", "c49a66"]), 3)
		# листья: дальние темнее, у каждого стержень и много узких листочков
		var fr: Array = hx(["163a1e", "1e5026", "2a6a30", "3a843a", "54a046", "76bc58", "a0d47a"])
		var angs: Array = [-2.9, -2.35, -1.75, -1.2, -0.55, -0.05, 0.5, 2.6, 1.9]
		for fi in range(angs.size()):
			var a3: float = float(angs[fi]) + rng.randf_range(-0.1, 0.1)
			var back: bool = fi >= 7 or (fi % 2 == 1)
			var L: float = rng.randf_range(42.0, 56.0) if not back else rng.randf_range(34.0, 44.0)
			var tb: int = 3 if back else 4
			var prev: Vector2 = top
			for s in range(1, 40):
				var t4: float = float(s) / 39.0
				var droop: float = t4 * t4 * L * 0.55
				var p4: Vector2 = top + Vector2(cos(a3), sin(a3) * 0.55) * L * t4 + Vector2(0, droop)
				line(im, int(prev.x), int(prev.y), int(p4.x), int(p4.y), fr[tb - 1])
				# листочки по обе стороны стержня
				if s > 2 and s % 2 == 0:
					var dirv: Vector2 = (p4 - prev).normalized()
					var nrm: Vector2 = Vector2(-dirv.y, dirv.x)
					var ll: float = 9.0 * sin(t4 * PI * 0.9 + 0.2)
					for sd in [-1.0, 1.0]:
						var side_tip: Vector2 = p4 + (nrm * sd + dirv * 0.6).normalized() * ll + Vector2(0, ll * 0.5)
						line(im, int(p4.x), int(p4.y), int(side_tip.x), int(side_tip.y), fr[tb + (1 if sd < 0.0 else 0)])
						line(im, int(p4.x), int(p4.y) + 1, int(side_tip.x), int(side_tip.y) + 1, fr[tb - 1])
				prev = p4
		blob(im, top.x, top.y, 5.0, 4.0, fr, 3)
		outline_auto(im, 0.35)
		save3(im, "palm" if pv2 == 0 else "palm_b", false)
		items.append(["palm" if pv2 == 0 else "palm_b", im])
	# ---------------------------------------------------------------- мелочи на пляже
	im = new_img(64, 22)
	ell(im, 32, 18, 28, 3, Color(0.1, 0.08, 0.04, 0.25))
	capsule(im, Vector2(6, 12), Vector2(56, 10), 4.5, 3.4, dr, 4)
	capsule(im, Vector2(40, 10), Vector2(52, 3), 2.2, 1.4, dr, 4)
	for x in range(8, 54, 3):
		px(im, x, 10 + int(sin(x * 0.4)), dr[2])
	outline_auto(im, 0.35)
	save3(im, "driftwood", false)
	items.append(["driftwood", im])
	im = new_img(40, 26)
	var shells: Array = [[Vector2(10, 14), PINKC7], [Vector2(24, 10), SHELL7], [Vector2(30, 18), ORANC7]]
	for sh_e in shells:
		var sp: Vector2 = sh_e[0]
		var sr: Array = hx(sh_e[1])
		for y in range(int(sp.y) - 5, int(sp.y) + 3):
			for x in range(int(sp.x) - 6, int(sp.x) + 7):
				var dv: Vector2 = Vector2(x + 0.5, y + 0.5) - Vector2(sp.x, sp.y + 2)
				var ang2: float = atan2(dv.y, dv.x)
				if dv.length() > 6.0 + sin(ang2 * 9.0) * 0.6 or dv.y > 0.5:
					continue
				var rib: bool = sin(ang2 * 9.0) > 0.4
				px(im, x, y, sr[4 if not rib else 5] if dv.x < 0.0 else sr[3 if not rib else 4])
		rect(im, int(sp.x) - 2, int(sp.y) + 2, 5, 1, sr[2])
	# морская звезда
	for a4 in range(5):
		var an2: float = -PI / 2.0 + TAU * float(a4) / 5.0
		capsule(im, Vector2(16, 20), Vector2(16, 20) + Vector2(cos(an2), sin(an2) * 0.8) * 5.5, 2.0, 0.8, hx(ORANC7), 4)
	disc(im, 16, 20, 2.0, hx(ORANC7)[5])
	outline_auto(im, 0.3)
	save3(im, "beach_shells", false)
	items.append(["beach_shells", im])
	# камни прилива с ракушками-балянусами и лужицей
	im = new_img(90, 54)
	ell(im, 45, 48, 40, 5, Color(0.05, 0.06, 0.08, 0.3))
	var rk: Array = hx(["2a2a30", "3c3c44", "52525a", "6a6a72", "84848a", "a0a0a4", "bcbcbe"])
	blob(im, 26, 34, 22, 15, rk, 4)
	blob(im, 58, 30, 26, 19, rk, 4)
	blob(im, 74, 40, 13, 9, rk, 3)
	ell(im, 50, 30, 12, 5, Color("2a5a7a"))
	ell(im, 49, 29, 10, 3.6, Color("4a8ab0"))
	px(im, 45, 28, Color("e8f8ff"))
	px(im, 46, 28, Color("bfe4f6"))
	for k6 in range(22):
		var bp: Vector2 = Vector2(10 + h01(k6, 1, 44) * 72.0, 22 + h01(k6, 2, 44) * 22.0)
		if a_at(im, int(bp.x), int(bp.y)) > 0.5 and Vector2(50, 30).distance_to(bp) > 13.0:
			disc(im, bp.x, bp.y, 1.6, Color("d8d4c8"))
			px(im, int(bp.x), int(bp.y), Color("3a3a40"))
	for k7 in range(9):
		var gp: Vector2 = Vector2(14 + h01(k7, 3, 45) * 64.0, 38 + h01(k7, 4, 45) * 8.0)
		line(im, int(gp.x), int(gp.y), int(gp.x) + 1, int(gp.y) - 4, Color("3e7a36"))
		px(im, int(gp.x) + 1, int(gp.y) - 4, Color("6aa850"))
	outline_auto(im, 0.35)
	save3(im, "tide_rocks", false)
	items.append(["tide_rocks", im])
	_sheet(items, 2, "v13_beach.png")
	gen_under13()


static func IRON7() -> Array:
	return [Color("1e1e26"), Color("30303a"), Color("464652"), Color("5e5e6c"), Color("7a7a88"), Color("9a9aa6"), Color("c0c0c8")]


## Спиральная раковина-наутилус. c — центр завитка, a — начальный радиус, turns — витков, rot — поворот
func nautilus(im: Image, c: Vector2, a: float, rmax: float, rot: float, ramp: Array, stripe: Array) -> void:
	var g: float = log(2.4) / TAU
	var t_end: float = log(rmax / a) / g
	for y in range(int(c.y - rmax) - 2, int(c.y + rmax) + 3):
		for x in range(int(c.x - rmax) - 2, int(c.x + rmax) + 3):
			var d: Vector2 = Vector2(x + 0.5, y + 0.5) - c
			var r: float = d.length()
			if r < a * 0.6:
				px(im, x, y, ramp[1])
				continue
			var th: float = fposmod(atan2(d.y, d.x) - rot, TAU)
			var lr: float = log(maxf(r, 0.01) / a) / g
			var n: float = floor((lr - th) / TAU)
			var t: float = th + TAU * n
			var u: float = (lr - t) / TAU
			if t + TAU > t_end + 0.001:
				continue
			# поперечное сечение трубки: свет сверху-слева
			var l: float = sin(u * PI) * 0.8 + d.normalized().dot(Vector2(-0.6, -0.8)) * 0.35 * u
			var ti: int = 1 + int(round(l * 5.0))
			if u < 0.07 or u > 0.95:
				ti = 1
			var outer: bool = t + TAU > t_end - TAU
			if outer and u > 0.25 and u < 0.9:
				var fl: float = sin(t * 5.5 + u * 2.5 + sin(u * 6.0) * 0.6)
				if fl > 0.55 and t < t_end - 1.3:
					px(im, x, y, stripe[clampi(ti / 2 + 1, 0, stripe.size() - 1)])
					continue
			# поперечные перегородки-рёбрышки
			if posmod(int(t * 2.2), 2) == 0 and fposmod(t * 2.2, 1.0) < 0.06:
				ti -= 1
			px(im, x, y, ramp[clampi(ti, 0, ramp.size() - 1)])


## Арочная дверь: тёмный проём, доски, ракушечная рамка
func shell_door(im: Image, cx: float, bottom: int, w: int, h: int, frame: Array) -> void:
	var dark: Array = hx(["1a1420", "2a2030", "3c2e40"])
	var wood: Array = hx(["3a2418", "54361e", "6e4a2a", "8a6038", "a67a4a"])
	for y in range(bottom - h, bottom):
		for x in range(int(cx) - w / 2 - 2, int(cx) + w / 2 + 3):
			var dy: float = float(y - (bottom - h + w / 2))
			var dx: float = float(x) + 0.5 - cx
			var inside: bool = (dy >= 0.0 and absf(dx) <= float(w) / 2.0) or (dy < 0.0 and dx * dx + dy * dy <= float(w * w) / 4.0)
			var rim: bool = (dy >= 0.0 and absf(dx) <= float(w) / 2.0 + 2.0) or (dy < 0.0 and dx * dx + dy * dy <= pow(float(w) / 2.0 + 2.0, 2.0))
			if inside:
				var plank: int = int(floor((dx + float(w) / 2.0) / 4.0))
				var ti: int = 3 if posmod(plank, 2) == 0 else 2
				if fposmod(dx + float(w) / 2.0, 4.0) < 0.9:
					ti = 1
				px(im, x, y, wood[ti])
			elif rim:
				var ang: float = atan2(dy, dx)
				var bead: bool = posmod(int((ang + PI) * 6.0 + float(y) * (0.0 if dy < 0.0 else 0.5)), 2) == 0
				px(im, x, y, frame[5] if bead else frame[3])
	# ручка
	disc(im, cx + float(w) * 0.25, bottom - h * 0.4, 1.3, hx(BRASS7)[5])
	px(im, int(cx) - w / 2, bottom - 1, dark[0])


## Круглое окошко с тёплым светом и перекрестием
func port_win(im: Image, c: Vector2, r: float, frame: Array) -> void:
	disc(im, c.x, c.y, r + 1.6, frame[2])
	disc(im, c.x, c.y, r + 0.8, frame[5])
	for y in range(int(c.y - r) - 1, int(c.y + r) + 2):
		for x in range(int(c.x - r) - 1, int(c.x + r) + 2):
			var d: Vector2 = Vector2(x + 0.5, y + 0.5) - c
			if d.length() > r:
				continue
			var gl: float = 1.0 - d.length() / r
			var col: Color = Color("f6b24a").lerp(Color("fff2b0"), gl)
			if absf(d.x) < 0.6 or absf(d.y) < 0.6:
				col = Color("8a5a2a")
			px(im, x, y, col)


func gen_under13() -> void:
	var items: Array = []
	var im: Image
	# ---------------------------------------------------------------- дно: песок рябью, камешки, обломки ракушек, пучки травы
	var SB: Array = hx(["6a6a5a", "7c7a64", "8e8a70", "a09a7c", "b0a888", "beb694", "ccc4a2"])
	im = new_img(128, 128)
	for y in range(128):
		for x in range(128):
			var wob: float = sin(float(x) * TAU / 128.0) * 5.0 + sin(float(x) * TAU / 64.0 + 1.0) * 2.0
			var rip: float = sin((float(y) + wob) * TAU / 16.0)
			var n: float = (sin(float(x) * TAU / 32.0 + sin(float(y) * TAU / 64.0) * 2.0) * 0.5 + sin(float(y) * TAU / 42.67 + float(x) * TAU / 128.0) * 0.3 + h01(x, y, 19) * 0.4) * 0.5
			var v: float = 3.2 + rip * 0.55 + n * 1.3
			var ti: int = int(round(v))
			# гребень ряби — светлая полоска, ложбинка — тёмная
			if rip > 0.95:
				ti += 1
			im.set_pixel(x, y, SB[clampi(ti, 0, 6)])
	rng.seed = 1313
	for i in range(40):
		var p: Vector2 = Vector2(rng.randi_range(0, 127), rng.randi_range(0, 127))
		var kind: int = rng.randi_range(0, 3)
		if kind == 0:
			_spx(im, int(p.x), int(p.y), SB[1])
			_spx(im, int(p.x) + 1, int(p.y), SB[5])
			_spx(im, int(p.x), int(p.y) - 1, SB[6])
			_spx(im, int(p.x) + 1, int(p.y) + 1, SB[0])
		elif kind == 1:
			var sc: Array = hx(PINKC7) if rng.randf() < 0.5 else hx(SHELL7)
			_spx(im, int(p.x), int(p.y), sc[5])
			_spx(im, int(p.x) + 1, int(p.y), sc[4])
			_spx(im, int(p.x) + 2, int(p.y), sc[3])
			_spx(im, int(p.x) + 1, int(p.y) + 1, sc[2])
		elif kind == 2:
			for k in range(4):
				_spx(im, int(p.x) + k - 2, int(p.y) - (k % 2) * 2 - 1, hx(KELP7)[4 + (k % 2)])
				_spx(im, int(p.x) + k - 2, int(p.y), hx(KELP7)[2])
		else:
			_spx(im, int(p.x), int(p.y), Color("e8e0d0"))
	save3(im, "seabed", false)
	# ---------------------------------------------------------------- луч света сверху (в игре — поворот и мягкое мерцание)
	im = new_img(48, 420)
	for y in range(420):
		for x in range(48):
			var u: float = absf(float(x) + 0.5 - 24.0) / 24.0
			var a: float = pow(1.0 - u, 1.6) * (1.0 - float(y) / 420.0) * 0.55
			im.set_pixel(x, y, Color(0.75, 0.95, 1.0, a))
	save3(im, "light_ray", false)
	# ---------------------------------------------------------------- домики
	var shell_r: Array = hx(SHELL7)
	var stripe: Array = hx(["5a2a1a", "7a3a22", "9a502e", "b46a3e"])
	im = new_img(180, 160)
	ell(im, 90, 152, 72, 7, Color(0.02, 0.06, 0.1, 0.32))
	blob(im, 90, 150, 70, 8, hx(SANDW7), 3)
	var ntmp: Image = new_img(180, 160)
	nautilus(ntmp, Vector2(92, 84), 3.4, 68.0, 2.0, shell_r, stripe)
	ntmp.flip_y()
	im.blend_rect(ntmp, Rect2i(0, 0, 180, 160), Vector2i(0, -6))
	# ровное основание: срезаем раковину по линии земли
	for y in range(147, 160):
		for x in range(180):
			if a_at(im, x, y) > 0.5 and im.get_pixel(x, y) != hx(SANDW7)[3]:
				pass
	shell_door(im, 92, 148, 22, 32, hx(PEARL7))
	port_win(im, Vector2(56, 104), 6.0, hx(PEARL7))
	port_win(im, Vector2(130, 100), 6.0, hx(PEARL7))
	port_win(im, Vector2(96, 56), 4.5, hx(PEARL7))
	# морская звёздочка и жемчужинки у входа
	for a5 in range(5):
		var an3: float = -PI / 2.0 + TAU * float(a5) / 5.0
		capsule(im, Vector2(140, 134), Vector2(140, 134) + Vector2(cos(an3), sin(an3)) * 6.0, 2.2, 0.8, hx(ORANC7), 4)
	disc(im, 140, 134, 2.2, hx(ORANC7)[5])
	for k2 in range(5):
		blob(im, 46 + k2 * 5, 148 - (k2 % 2), 2.2, 2.2, hx(PEARL7), 4)
	_anemone(im, Vector2(28, 148), 9.0, hx(PINKC7), 3)
	outline_auto(im, 0.42)
	save3(im, "coral_house_a", false)
	items.append(["coral_house_a", im])
	# коралл-мозговик: купол с бороздами-лабиринтом
	im = new_img(180, 150)
	ell(im, 90, 144, 74, 7, Color(0.02, 0.06, 0.1, 0.32))
	var bc: Array = hx(ORANC7)
	for y in range(20, 146):
		for x in range(10, 170):
			var nx: float = (float(x) + 0.5 - 90.0) / 76.0
			var ny: float = (float(y) + 0.5 - 140.0) / 118.0
			if nx * nx + ny * ny > 1.0 or ny > 0.03:
				continue
			var nz: float = sqrt(maxf(0.0, 1.0 - nx * nx - ny * ny))
			var l: float = Vector3(nx, ny, nz).normalized().dot(LT)
			var ti: int = 3 + int(round(l * 2.6 - 0.3))
			var mz: float = sin(float(x) * 0.42 + sin(float(y) * 0.23) * 2.4) * cos(float(y) * 0.47 + sin(float(x) * 0.19) * 2.1)
			if absf(mz) < 0.16:
				ti -= 2
			elif absf(mz) > 0.75 and l > 0.1:
				ti += 1
			px(im, x, y, bc[clampi(ti, 0, 6)])
	shell_door(im, 90, 141, 22, 32, hx(SHELL7))
	port_win(im, Vector2(52, 104), 6.0, hx(SHELL7))
	port_win(im, Vector2(128, 104), 6.0, hx(SHELL7))
	port_win(im, Vector2(90, 64), 5.0, hx(SHELL7))
	_staghorn(im, Vector2(64, 36), 14.0, hx(PINKC7), 6)
	_staghorn(im, Vector2(118, 40), 11.0, hx(VIOC7), 9)
	_anemone(im, Vector2(150, 142), 8.0, hx(VIOC7), 3)
	outline_auto(im, 0.42)
	save3(im, "coral_house_b", false)
	items.append(["coral_house_b", im])
	# башенка-рапан: высокая спиральная раковина с шипами
	im = new_img(120, 210)
	ell(im, 60, 204, 46, 6, Color(0.02, 0.06, 0.1, 0.32))
	var ct: Array = hx(["5a3a5a", "7a5276", "9a6e92", "ba8eae", "d4b0c8", "eacee0", "f8eaf2"])
	for y in range(14, 204):
		var t5: float = float(y - 14) / 190.0
		var hw: float = 6.0 + 40.0 * pow(t5, 0.8)
		if t5 > 0.92:
			hw -= (t5 - 0.92) * 120.0
		for x in range(int(60 - hw), int(60 + hw) + 1):
			var u5: float = (float(x) + 0.5 - (60.0 - hw)) / (2.0 * hw)
			var band: float = (float(y) + (u5 - 0.5) * 22.0) / 22.0
			var bu: float = fposmod(band, 1.0)
			var l2: float = sin(bu * PI) * 0.7 + (0.5 - u5) * 0.9
			var ti5: int = 3 + int(round(l2 * 2.2))
			if bu < 0.08:
				ti5 = 1
			px(im, x, y, ct[clampi(ti5, 0, 6)])
		# шипы на каждом витке
		if posmod(y, 22) == 6 and t5 < 0.85:
			for sdx in [-1.0, 1.0]:
				capsule(im, Vector2(60 + sdx * (hw - 2.0), y), Vector2(60 + sdx * (hw + 6.0), y - 6), 2.4, 0.7, ct, 4)
	shell_door(im, 60, 200, 18, 28, hx(PEARL7))
	port_win(im, Vector2(60, 140), 5.0, hx(PEARL7))
	port_win(im, Vector2(60, 96), 4.0, hx(PEARL7))
	port_win(im, Vector2(60, 58), 3.0, hx(PEARL7))
	outline_auto(im, 0.42)
	save3(im, "coral_house_c", false)
	items.append(["coral_house_c", im])
	# ---------------------------------------------------------------- жемчужный дворец
	im = new_img(360, 300)
	ell(im, 180, 292, 150, 8, Color(0.02, 0.06, 0.1, 0.35))
	var scal: Array = hx(["7a4a6a", "9a6286", "ba7ea2", "d49cbc", "e8bcd4", "f6dae8", "fff2f8"])
	var fc: Vector2 = Vector2(180, 250)
	for y in range(0, 252):
		for x in range(0, 360):
			var d2: Vector2 = Vector2(x + 0.5, y + 0.5) - fc
			var ang3: float = atan2(d2.y, d2.x)
			if ang3 > -0.12 or ang3 < -PI + 0.12:
				continue
			var rib: float = sin((ang3 + PI) * 15.0)
			var R: float = 172.0 + absf(rib) * 7.0
			if d2.length() > R:
				continue
			var l3: float = rib * 0.6 + (1.0 - d2.length() / R) * 0.3
			var ti6: int = 3 + int(round(l3 * 2.4))
			if fposmod(d2.length(), 18.0) < 1.0:
				ti6 -= 1
			if d2.length() > R - 2.0:
				ti6 = 6
			px(im, x, y, scal[clampi(ti6, 0, 6)])
	var pr: Array = hx(PEARL7)
	# корпус дворца с арками-окнами и колоннами
	for y in range(170, 290):
		for x in range(90, 270):
			var u6: float = float(x - 90) / 180.0
			var ti7: int = 4 if u6 < 0.5 else 3
			if posmod(y - 170, 14) == 0:
				ti7 -= 1
			if posmod(x - 90 + (7 if posmod((y - 170) / 14, 2) == 1 else 0), 14) == 0:
				ti7 -= 1
			px(im, x, y, pr[clampi(ti7, 0, 6)])
	for cxk in [104, 140, 220, 256]:
		for y in range(176, 290):
			for x in range(cxk - 5, cxk + 6):
				var uu: float = float(x - cxk + 5) / 10.0
				px(im, x, y, pr[6 if uu < 0.25 else (5 if uu < 0.6 else (3 if uu < 0.85 else 2))])
		blob(im, cxk, 176, 8, 3, pr, 4)
		blob(im, cxk, 288, 8, 3, pr, 3)
	for wx in [122, 238]:
		for y in range(196, 250):
			for x in range(wx - 9, wx + 10):
				var dy2: float = float(y - 205)
				var dx2: float = float(x) + 0.5 - float(wx)
				if (dy2 < 0.0 and dx2 * dx2 + dy2 * dy2 > 81.0) or absf(dx2) > 9.0:
					continue
				var g2: float = 1.0 - absf(dx2) / 10.0
				px(im, x, y, Color("f6b24a").lerp(Color("fff2b0"), g2) if absf(dx2) > 0.8 else Color("a07a4a"))
	# купол с большой жемчужиной
	blob(im, 180, 170, 56, 34, pr, 4)
	for k3 in range(12):
		var aa: float = PI + PI * float(k3) / 11.0
		px(im, int(180 + cos(aa) * 54.0), int(170 + sin(aa) * 32.0), hx(BRASS7)[5])
	blob(im, 180, 124, 16, 16, hx(["8a8aa8", "aeaec8", "cecee2", "e6e6f2", "f4f4fa", "fcfcff", "ffffff"]), 4)
	disc(im, 174, 118, 3.0, Color("ffffff"))
	# башни-раковины по бокам
	for tx in [72, 288]:
		for y in range(96, 290):
			var t6: float = float(y - 96) / 194.0
			var hw2: float = 4.0 + 20.0 * pow(t6, 0.6)
			for x in range(int(tx - hw2), int(tx + hw2) + 1):
				var u7: float = (float(x) + 0.5 - (tx - hw2)) / (2.0 * hw2)
				var bu2: float = fposmod((float(y) + (u7 - 0.5) * 16.0) / 16.0, 1.0)
				var ti8: int = 3 + int(round((sin(bu2 * PI) * 0.6 + (0.5 - u7) * 0.9) * 2.2))
				if bu2 < 0.1:
					ti8 = 1
				px(im, x, y, scal[clampi(ti8, 0, 6)])
		port_win(im, Vector2(tx, 200), 5.0, pr)
		port_win(im, Vector2(tx, 160), 4.0, pr)
		blob(im, tx, 94, 4, 4, pr, 5)
	shell_door(im, 180, 290, 34, 50, hx(BRASS7))
	# ступени
	for k4 in range(3):
		rect(im, 156 - k4 * 6, 290 + k4 * 3, 48 + k4 * 12, 3, pr[4 - k4])
	outline_auto(im, 0.45)
	save3(im, "pearl_palace", false)
	items.append(["pearl_palace", im])
	# ---------------------------------------------------------------- кораллы и водоросли
	for kv in range(3):
		im = new_img(60, 150)
		for st in range(3):
			var bx: float = 18.0 + float(st) * 12.0 + float(kv)
			var pts: Array = []
			for k5 in range(7):
				var t7: float = float(k5) / 6.0
				pts.append(Vector2(bx + sin(t7 * 4.0 + float(st + kv)) * 6.0 * t7, 148.0 - t7 * (110.0 + float(st) * 12.0 - float(kv) * 8.0)))
			var q: Array = spline_pts(pts, 10)
			for i2 in range(q.size() - 1):
				var a6: Vector2 = q[i2]
				px(im, int(a6.x), int(a6.y), hx(KELP7)[2])
				px(im, int(a6.x) + 1, int(a6.y), hx(KELP7)[1])
				if i2 % 9 == 4 and posmod(i2 / 9, 3) != 2:
					var sd2: float = 1.0 if posmod(i2 / 9, 2) == 0 else -1.0
					var dirk: Vector2 = Vector2(sd2 * 0.9, -0.55).normalized()
					draw_leaf(im, a6 + dirk * 9.0, dirk, 19.0, 7.0, 4 - (st % 2), hx(KELP7), true)
					if posmod(i2 / 9, 2) == 0:
						blob(im, a6.x + sd2 * 1.5, a6.y, 1.8, 1.8, hx(["4a5a1a", "6a7a26", "8a9a36", "aab84e", "c8d06a", "e0e48a", "f0f4b0"]), 4)
			draw_leaf(im, (q[q.size() - 1] as Vector2) + Vector2(0, -6), Vector2(0.2, -1.0), 14.0, 6.0, 5, hx(KELP7), true)
		outline_auto(im, 0.3)
		save3(im, "kelp" if kv == 0 else "kelp_%d" % kv, false)
		items.append(["kelp_%d" % kv, im])
	var cramps: Array = [hx(PINKC7), hx(ORANC7), hx(VIOC7)]
	for k6 in range(3):
		im = new_img(70, 64)
		ell(im, 35, 60, 22, 3, Color(0.02, 0.06, 0.1, 0.3))
		_staghorn(im, Vector2(35, 60), 20.0, cramps[k6], 30 + k6)
		outline_auto(im, 0.35)
		save3(im, "coral_%d" % k6, false)
		items.append(["coral_%d" % k6, im])
	# горгонария-веер: тонкая сеточка
	im = new_img(70, 76)
	var vf: Array = hx(VIOC7)
	rng.seed = 77
	var branches: Array = [[Vector2(35, 74), -PI / 2.0, 26.0, 0]]
	var segs: Array = []
	while branches.size() > 0:
		var br: Array = branches.pop_back()
		var p0: Vector2 = br[0]
		var a7: float = br[1]
		var ln: float = br[2]
		var dep: int = br[3]
		var p1: Vector2 = p0 + Vector2(cos(a7), sin(a7)) * ln
		segs.append([p0, p1, dep])
		if dep < 5:
			branches.append([p1, a7 - 0.45 - rng.randf() * 0.2, ln * 0.72, dep + 1])
			branches.append([p1, a7 + 0.45 + rng.randf() * 0.2, ln * 0.72, dep + 1])
	for sg in segs:
		var w2: float = 2.2 - float(sg[2]) * 0.35
		capsule(im, sg[0], sg[1], w2, maxf(0.7, w2 - 0.35), vf, 4)
	# поперечная сеточка между ветвями
	# сеточка: соседние ветки одного уровня соединены тонкими перемычками
	for i9 in range(segs.size()):
		for j9 in range(i9 + 1, segs.size()):
			if int(segs[i9][2]) != int(segs[j9][2]) or int(segs[i9][2]) < 2:
				continue
			var m1: Vector2 = ((segs[i9][0] as Vector2) + (segs[i9][1] as Vector2)) / 2.0
			var m2: Vector2 = ((segs[j9][0] as Vector2) + (segs[j9][1] as Vector2)) / 2.0
			if m1.distance_to(m2) < 11.0:
				line(im, int(m1.x), int(m1.y), int(m2.x), int(m2.y), vf[3])
	outline_auto(im, 0.3)
	save3(im, "sea_fan", false)
	items.append(["sea_fan", im])
	# трубчатые губки
	im = new_img(50, 60)
	ell(im, 25, 56, 18, 3, Color(0.02, 0.06, 0.1, 0.3))
	var sp2: Array = hx(["5a3a0a", "7a5414", "9a7020", "ba8e30", "d4ac48", "e8c868", "f6e294"])
	for tt in [[14.0, 24.0, 5.0], [26.0, 12.0, 6.5], [37.0, 28.0, 4.6]]:
		var tx2: float = tt[0]
		var ty: float = tt[1]
		var tr2: float = tt[2]
		capsule(im, Vector2(tx2, 56), Vector2(tx2, ty), tr2 + 0.6, tr2, sp2, 4)
		ell(im, tx2, ty, tr2, tr2 * 0.42, sp2[1])
		ell(im, tx2, ty + 0.5, tr2 - 1.4, tr2 * 0.3, Color("2a1a0a"))
		for k8 in range(int(56 - ty) / 4):
			px(im, int(tx2 - tr2 * 0.4), int(ty) + 4 + k8 * 4, sp2[6])
	outline_auto(im, 0.35)
	save3(im, "tube_sponge", false)
	items.append(["tube_sponge", im])
	# актиния с рыбкой-клоуном
	im = new_img(50, 44)
	_anemone(im, Vector2(25, 40), 14.0, hx(PINKC7), 7)
	var cf: Vector2 = Vector2(33, 18)
	blob(im, cf.x, cf.y, 4.5, 2.6, hx(ORANC7), 4)
	for sx4 in [-1.5, 1.5]:
		line(im, int(cf.x + sx4), int(cf.y) - 2, int(cf.x + sx4), int(cf.y) + 2, Color("ffffff"))
	line(im, int(cf.x) + 4, int(cf.y) - 1, int(cf.x) + 6, int(cf.y) - 2, hx(ORANC7)[3])
	line(im, int(cf.x) + 4, int(cf.y) + 1, int(cf.x) + 6, int(cf.y) + 2, hx(ORANC7)[3])
	px(im, int(cf.x) - 3, int(cf.y) - 1, Color("1a1a1a"))
	outline_auto(im, 0.32)
	save3(im, "anemone", false)
	items.append(["anemone", im])
	# гигантский моллюск
	im = new_img(56, 36)
	ell(im, 28, 32, 24, 3, Color(0.02, 0.06, 0.1, 0.3))
	for y in range(6, 33):
		for x in range(3, 54):
			var u8: float = (float(x) - 28.0) / 25.0
			var top: float = 20.0 - sqrt(maxf(0.0, 1.0 - u8 * u8)) * 14.0 + sin(u8 * 18.0) * 2.0
			if float(y) < top or absf(u8) > 1.0:
				continue
			var lip: bool = float(y) < top + 2.5
			var mid: bool = absf(float(y) - 22.0) < 2.0 + (1.0 - absf(u8)) * 1.5
			if mid:
				px(im, x, y, Color("2a8ac8") if posmod(x, 3) != 0 else Color("6ad0f0"))
			elif lip:
				px(im, x, y, hx(SHELL7)[5])
			else:
				var rib2: bool = sin(u8 * 18.0) > 0.3
				px(im, x, y, hx(SHELL7)[(4 if rib2 else 3) - (1 if y > 26 else 0)])
	outline_auto(im, 0.35)
	save3(im, "giant_clam", false)
	items.append(["giant_clam", im])
	# камень с балянусами и морской звездой
	im = new_img(70, 50)
	ell(im, 35, 46, 30, 4, Color(0.02, 0.06, 0.1, 0.3))
	var rk2: Array = hx(["1e262e", "2c3640", "3c4852", "4e5c66", "64727a", "7c8a90", "98a4a8"])
	blob(im, 30, 30, 26, 17, rk2, 4)
	blob(im, 50, 34, 16, 12, rk2, 3)
	for k9 in range(26):
		var bp2: Vector2 = Vector2(8 + h01(k9, 1, 88) * 56.0, 16 + h01(k9, 2, 88) * 26.0)
		if a_at(im, int(bp2.x), int(bp2.y)) > 0.5:
			disc(im, bp2.x, bp2.y, 1.5, Color("cfc8bc"))
			px(im, int(bp2.x), int(bp2.y), Color("2a2a30"))
	for a8 in range(5):
		var an4: float = -PI / 2.0 + TAU * float(a8) / 5.0
		capsule(im, Vector2(22, 24), Vector2(22, 24) + Vector2(cos(an4), sin(an4)) * 7.0, 2.6, 0.9, hx(PINKC7), 4)
	disc(im, 22, 24, 2.6, hx(PINKC7)[5])
	outline_auto(im, 0.35)
	save3(im, "sea_rock", false)
	items.append(["sea_rock", im])
	# фонарь-ракушка: раскрытая створка и светящаяся жемчужина на стебле
	im = new_img(34, 56)
	ell(im, 17, 53, 9, 2, Color(0.02, 0.06, 0.1, 0.3))
	capsule(im, Vector2(17, 54), Vector2(17, 26), 2.2, 1.6, hx(KELP7), 4)
	for k10 in range(3):
		draw_leaf(im, Vector2(17 + (k10 - 1) * 5, 48 - k10 * 3), Vector2(float(k10 - 1) * 0.8, -1.0), 9.0, 4.0, 4, hx(KELP7))
	for y in range(8, 30):
		for x in range(3, 31):
			var d3: Vector2 = Vector2(x + 0.5, y + 0.5) - Vector2(17, 28)
			var ang5: float = atan2(d3.y, d3.x)
			var R2: float = 14.0 + absf(sin(ang5 * 7.0)) * 1.2
			if d3.y > 0.0 or d3.length() > R2:
				continue
			var rib3: float = sin(ang5 * 7.0)
			px(im, x, y, hx(SHELL7)[clampi(4 + int(round(rib3 * 1.4)), 0, 6)])
	blob(im, 17, 28, 5, 4.5, hx(["c8b060", "e0c870", "f4e090", "fff2b8", "fffad8", "ffffff", "ffffff"]), 4)
	px(im, 15, 26, Color("ffffff"))
	outline_auto(im, 0.35)
	save3(im, "shell_lamp", false)
	items.append(["shell_lamp", im])
	# лавки русалок: прилавок из плавника под раковиной-навесом
	for kk in range(2):
		im = new_img(110, 96)
		ell(im, 55, 92, 46, 4, Color(0.02, 0.06, 0.1, 0.3))
		var drr: Array = hx(DRIFT7)
		for sx5 in [12, 94]:
			capsule(im, Vector2(sx5, 90), Vector2(sx5 + (2 if sx5 < 50 else -2), 30), 2.6, 2.0, drr, 4)
		box3(im, 8, 62, 94, 26, 4, drr, 4)
		for x in range(10, 100, 9):
			line(im, x, 64, x, 86, drr[2])
		var can: Array = [hx(PINKC7), hx(VIOC7)][kk]
		for y in range(4, 40):
			for x in range(0, 110):
				var d4: Vector2 = Vector2(x + 0.5, y + 0.5) - Vector2(55, 40)
				var ang6: float = atan2(d4.y, d4.x)
				var rib4: float = sin((ang6 + PI) * 11.0)
				var R3: float = 54.0 + absf(rib4) * 3.0
				if d4.y > 0.0 or d4.length() > R3 or ang6 > -0.25 or ang6 < -PI + 0.25:
					continue
				px(im, x, y, can[clampi(3 + int(round(rib4 * 1.6 + (1.0 - d4.length() / R3) * 0.8)), 0, 6)])
		# товары: жемчуг, рыбка, связка водорослей, ракушки
		for k11 in range(5):
			blob(im, 22 + k11 * 4, 59, 2.0, 2.0, hx(PEARL7), 4)
		blob(im, 50, 58, 7, 3, hx(["2a4a6a", "3a6a8a", "5a8aaa", "7aaac8", "a0cce0", "c8e6f2", "eef8ff"]), 4)
		line(im, 57, 58, 60, 55, Color("5a8aaa"))
		line(im, 57, 58, 60, 61, Color("5a8aaa"))
		for k12 in range(4):
			line(im, 72 + k12 * 2, 60, 74 + k12 * 2, 50, hx(KELP7)[3 + k12 % 2])
		blob(im, 88, 58, 4, 3, hx(ORANC7), 4)
		outline_auto(im, 0.38)
		save3(im, "sea_stall_%d" % kk, false)
		items.append(["sea_stall_%d" % kk, im])
	# рыбки для стаек: 3 вида x 2 кадра (16x10)
	im = new_img(32, 30)
	var fishes: Array = [hx(["1a4a8a", "2a6ac0", "4a8ae0", "7ab0f0", "b0d4fa"]), hx(["8a4a0a", "c06a10", "f09a20", "f8c050", "fce090"]), hx(["5a5a6a", "8a8a9a", "b0b0c0", "d6d6e2", "f2f2f8"])]
	for fi2 in range(3):
		for fr2 in range(2):
			var ox: int = fr2 * 16
			var oy: int = fi2 * 10
			var fr3: Array = fishes[fi2]
			for y in range(oy + 2, oy + 8):
				for x in range(ox + 3, ox + 13):
					var u9: float = (float(x - ox) - 8.0) / 5.0
					var v9: float = (float(y - oy) - 5.0) / 3.0
					if u9 * u9 + v9 * v9 > 1.0:
						continue
					px(im, x, y, fr3[3] if v9 < -0.2 else (fr3[2] if v9 < 0.5 else fr3[1]))
			var tw: int = 1 if fr2 == 0 else -1
			px(im, ox + 13, oy + 4 + tw, fr3[2])
			px(im, ox + 14, oy + 3 + tw, fr3[2])
			px(im, ox + 14, oy + 6 + tw, fr3[2])
			px(im, ox + 13, oy + 5 + tw, fr3[1])
			px(im, ox + 5, oy + 4, Color("101018"))
			px(im, ox + 6, oy + 3, fr3[4])
	save3(im, "sea_fish", false)
	# жерло пузырей: каменный бугорок с тёмной дырой
	im = new_img(70, 40)
	ell(im, 35, 36, 30, 4, Color(0.02, 0.06, 0.1, 0.3))
	blob(im, 35, 28, 30, 12, rk2, 4)
	ell(im, 35, 24, 11, 4.5, Color("0e1820"))
	ell(im, 35, 24, 8, 3, Color("4ab8e0"))
	ell(im, 35, 23.5, 5, 1.8, Color("bff0ff"))
	for k13 in range(18):
		var bp3: Vector2 = Vector2(10 + h01(k13, 1, 99) * 50.0, 22 + h01(k13, 2, 99) * 14.0)
		if a_at(im, int(bp3.x), int(bp3.y)) > 0.5 and bp3.distance_to(Vector2(35, 24)) > 12.0:
			disc(im, bp3.x, bp3.y, 1.4, Color("cfc8bc"))
	outline_auto(im, 0.35)
	save3(im, "bubble_column", false)
	items.append(["bubble_column", im])
	_sheet(items, 2, "v13_sea.png")


## Ветвистый коралл: ветки делятся, на кончиках светлые полипы
func _staghorn(im: Image, base: Vector2, L: float, ramp: Array, seed_v: int) -> void:
	rng.seed = seed_v
	var stack: Array = [[base, -PI / 2.0 + rng.randf_range(-0.2, 0.2), L, 0]]
	var tips: Array = []
	while stack.size() > 0:
		var br: Array = stack.pop_back()
		var p0: Vector2 = br[0]
		var a: float = br[1]
		var ln: float = br[2]
		var dep: int = br[3]
		var p1: Vector2 = p0 + Vector2(cos(a), sin(a)) * ln
		var w: float = maxf(1.3, 4.0 - float(dep) * 0.9)
		capsule(im, p0, p1, w, maxf(1.1, w - 0.6), ramp, 4)
		if dep < 3:
			stack.append([p1, a - rng.randf_range(0.35, 0.7), ln * rng.randf_range(0.6, 0.8), dep + 1])
			stack.append([p1, a + rng.randf_range(0.35, 0.7), ln * rng.randf_range(0.6, 0.8), dep + 1])
			if rng.randf() < 0.4:
				stack.append([p1, a + rng.randf_range(-0.15, 0.15), ln * 0.6, dep + 2])
		else:
			tips.append(p1)
	for t in tips:
		var tp: Vector2 = t
		px(im, int(tp.x), int(tp.y), ramp[6])
		px(im, int(tp.x), int(tp.y) - 1, ramp[5])


## Актиния: столбик и венчик щупалец с розовыми кончиками
func _anemone(im: Image, base: Vector2, r: float, ramp: Array, seed_v: int) -> void:
	blob(im, base.x, base.y - r * 0.35, r * 0.55, r * 0.4, ramp, 3)
	for k in range(int(r * 1.6)):
		var u: float = float(k) / (r * 1.6 - 1.0)
		var a: float = -PI + 0.25 + u * (PI - 0.5)
		var ln: float = r * (0.8 + h01(k, seed_v, 3) * 0.4)
		var p0: Vector2 = base + Vector2(cos(a) * r * 0.3, -r * 0.5)
		var p1: Vector2 = p0 + Vector2(cos(a), sin(a) * 0.9) * ln + Vector2(sin(float(k)) * 1.5, 0)
		capsule(im, p0, p1, 1.4, 0.9, ramp, 4)
		px(im, int(p1.x), int(p1.y), ramp[6])


func _spx(im: Image, x: int, y: int, c: Color) -> void:
	im.set_pixel(posmod(x, im.get_width()), posmod(y, im.get_height()), c)


# ================================================================== v13: Япония — замок, минка, чайный домик, пагода, тории, сад

const JTILE: Array = ["1a1c26", "262a36", "323848", "40485a", "52596e", "687086", "8890a6"]
const JTILE_B: Array = ["2a1612", "3e201a", "542c22", "6c3a2c", "864c3a", "a0624c", "bc8266"]
const JWOOD: Array = ["1e120c", "2e1c12", "42281a", "583824", "704a30", "8a6040", "a67a54"]
const JPLAST: Array = ["8a8478", "a8a296", "c4beb2", "dcd6ca", "eeeae0", "f8f6f0", "ffffff"]
const JVERM: Array = ["5a1210", "7e1a14", "a4261a", "c43a22", "dc5432", "ee7a4e", "f8a676"]
const JSTONE: Array = ["2e2c2c", "423e3c", "585450", "6e6a64", "86827a", "a09c92", "bcb8ae"]
const JPAPER: Array = ["b8ae98", "d0c8b2", "e4dcc8", "f2ecdc", "faf6ec"]


## Черепичная крыша с загнутыми углами: конёк сверху, ряды черепицы, торцевые «кругляши» по свесу
func jp_roof(im: Image, cx: float, top: int, eave: int, ridge_hw: float, hw: float, curl: float, ramp: Array) -> void:
	for y in range(top - 8, eave + 1):
		for x in range(int(cx - hw) - 2, int(cx + hw) + 3):
			var u: float = (float(x) + 0.5 - cx) / hw
			var lift: float = curl * pow(absf(u), 5.0)
			var ey: float = float(eave) - lift
			var ty: float = float(top) - lift * 0.35
			if float(y) > ey or float(y) < ty:
				continue
			var t: float = clampf((float(y) - ty) / maxf(1.0, ey - ty), 0.0, 1.0)
			var w: float = lerpf(ridge_hw, hw, pow(t, 0.75))
			if absf(float(x) + 0.5 - cx) > w + lift * 0.15:
				continue
			var row: int = int(floor((float(y) - ty) / 4.0))
			var ry: float = fposmod(float(y) - ty, 4.0)
			var ti: int = 3
			# левая половина под светом, правая в тени
			if u < -0.25:
				ti = 4
			elif u > 0.35:
				ti = 2
			if ry < 1.0:
				ti -= 1
			elif ry > 2.9:
				ti += 1
			if posmod(x + (2 if posmod(row, 2) == 1 else 0), 4) == 0:
				ti -= 1
			# край свеса — светлая полоска торцевой черепицы
			if float(y) > ey - 2.0:
				ti = 5 if posmod(x, 4) < 2 else 3
			px(im, x, y, ramp[clampi(ti, 0, 6)])
	# конёк
	for x2 in range(int(cx - ridge_hw) - 2, int(cx + ridge_hw) + 3):
		var uu: float = (float(x2) + 0.5 - cx) / maxf(1.0, ridge_hw)
		var up: int = int(round(pow(absf(uu), 6.0) * 4.0))
		for k in range(4):
			px(im, x2, top - 3 - up + k, ramp[clampi([1, 2, 1, 0][k] + (1 if uu < 0.0 else 0), 0, 6)])


## Стена с сёдзи: тёмный каркас, бумажные панели с решёткой, внизу доски; lit — тёплый свет за бумагой
func shoji_wall(im: Image, x0: int, y0: int, w: int, h: int, lit: bool, seed_v: int) -> void:
	var wood: Array = hx(JWOOD)
	var pap: Array = hx(JPAPER)
	var post: int = 26
	for y in range(y0, y0 + h):
		for x in range(x0, x0 + w):
			var lx: int = x - x0
			var ly: int = y - y0
			var c: Color
			var in_post: bool = posmod(lx, post) < 3 or lx >= w - 3
			if ly < 3 or in_post:
				c = wood[3] if posmod(lx, post) == 0 or ly == 0 else wood[2]
			elif ly > h - 10:
				# нижние доски
				c = wood[2] if posmod(ly, 3) != 0 else wood[1]
				if posmod(lx, 9) == 0:
					c = wood[1]
			else:
				var gx: int = posmod(lx - 3, post) - 0
				var gy: int = ly - 3
				var grid: bool = posmod(gx, 6) == 5 or posmod(gy, 8) == 7
				var warm: bool = lit and h01(int(lx / post), seed_v, 3) > 0.35
				if grid:
					c = wood[4]
				else:
					c = pap[3] if not warm else Color("f8d896")
					if gy < 2:
						c = pap[1] if not warm else Color("e8b868")
			px(im, x, y, c)


## Норэн: занавеска над дверью из трёх полотнищ с гербом
func noren(im: Image, cx: float, y0: int, w: int, h: int, col: Color, crest: Color) -> void:
	var flaps: int = 3
	var fw: float = float(w) / float(flaps)
	for y in range(y0, y0 + h):
		for x in range(int(cx - w / 2.0), int(cx + w / 2.0)):
			var lx: float = float(x) - (cx - w / 2.0)
			var f: int = int(lx / fw)
			var fx: float = fposmod(lx, fw)
			if fx < 1.0 and y > y0 + 3:
				continue
			var c: Color = col
			if fx < 2.0:
				c = col.lightened(0.15)
			elif fx > fw - 2.0:
				c = col.darkened(0.2)
			if y == y0 + h - 1:
				c = col.darkened(0.3)
			px(im, x, y, c)
	# герб-кружок посередине
	for y2 in range(y0 + 4, y0 + 11):
		for x2 in range(int(cx) - 3, int(cx) + 4):
			var d: float = Vector2(x2 + 0.5 - cx, y2 + 0.5 - float(y0 + 7)).length()
			if d < 3.4 and d > 1.6:
				px(im, x2, y2, crest)


## Бумажный фонарик-тётин: красный, рёбра, чёрные крышечки
func chochin(im: Image, cx: float, top: int, r: float, col: Color) -> void:
	line(im, int(cx), top - 5, int(cx), top, Color("2a1c12"))
	var h: int = int(r * 2.4)
	for y in range(top, top + h):
		var t: float = float(y - top) / float(h - 1)
		var hw: float = r * sin(t * PI) * 0.95 + 1.2
		for x in range(int(cx - hw), int(cx + hw) + 1):
			var u: float = (float(x) + 0.5 - (cx - hw)) / (2.0 * hw)
			var c: Color = col.lightened(0.25) if u < 0.35 else (col if u < 0.75 else col.darkened(0.25))
			if posmod(y - top, 3) == 0:
				c = c.darkened(0.18)
			px(im, x, y, c)
	rect(im, int(cx - r * 0.5), top, int(r) + 1, 2, Color("1a1214"))
	rect(im, int(cx - r * 0.5), top + h - 2, int(r) + 1, 2, Color("1a1214"))
	px(im, int(cx), top + h / 2, Color("fff0b0"))


## Каменный фундамент из неровных камней
func stone_base(im: Image, x0: int, y0: int, w: int, h: int, seed_v: int) -> void:
	var st: Array = hx(JSTONE)
	for y in range(y0, y0 + h):
		var row: int = (y - y0) / 6
		for x in range(x0, x0 + w):
			var sx: int = (x - x0 + (5 if row % 2 == 1 else 0) + int(h01(row, 0, seed_v) * 4.0)) / 11
			var lx: int = posmod(x - x0 + (5 if row % 2 == 1 else 0) + int(h01(row, 0, seed_v) * 4.0), 11)
			var ly: int = posmod(y - y0, 6)
			var ti: int = 3 + int(h01(sx, row, seed_v + 1) * 2.0)
			if lx == 0 or ly == 5:
				ti = 1
			elif ly == 0 or lx == 1:
				ti += 1
			px(im, x, y, st[clampi(ti, 0, 6)])


## Японский дом-минка: фундамент, веранда-энгава, стены с сёдзи, дверь с норэн, черепичная крыша
func jp_house13(name: String, W: int, roof_ramp: Array, noren_col: Color, deco: String, seed_v: int) -> Image:
	var H: int = 176
	var im: Image = new_img(W, H)
	var cx: float = float(W) / 2.0
	var bw: int = W - 28
	var x0: int = 14
	var wall_top: int = 92
	var floor_y: int = H - 18
	ell(im, cx, H - 5, float(W) * 0.46, 6, Color(0.08, 0.06, 0.1, 0.3))
	stone_base(im, x0 - 2, floor_y, bw + 4, 12, seed_v)
	# энгава — дощатая веранда
	var wd: Array = hx(JWOOD)
	for y in range(floor_y - 6, floor_y + 1):
		for x in range(x0 - 4, x0 + bw + 4):
			var c: Color = wd[5] if y == floor_y - 6 else (wd[4] if posmod(x, 12) != 0 else wd[2])
			if y == floor_y:
				c = wd[2]
			px(im, x, y, c)
	shoji_wall(im, x0, wall_top, bw, floor_y - 6 - wall_top, true, seed_v)
	# тень под свесом крыши
	for y2 in range(wall_top, wall_top + 5):
		for x2 in range(x0, x0 + bw):
			if a_at(im, x2, y2) > 0.5:
				px(im, x2, y2, im.get_pixel(x2, y2).darkened(0.45 - float(y2 - wall_top) * 0.08))
	# дверь посередине: раздвижная, тёмная щель и норэн
	var dw: int = 26
	rect(im, int(cx) - dw / 2, floor_y - 40, dw, 34, wd[1])
	rect(im, int(cx) - dw / 2 + 2, floor_y - 38, dw / 2 - 2, 32, Color("3a2418"))
	rect(im, int(cx) + 1, floor_y - 38, dw / 2 - 3, 32, Color("f0c070"))
	noren(im, cx, floor_y - 42, dw + 6, 16, noren_col, Color("f4ecdc"))
	# ступенька-камень
	ell(im, cx, floor_y + 4, 12, 3, hx(JSTONE)[4])
	ell(im, cx, floor_y + 3, 11, 2, hx(JSTONE)[5])
	# крыша
	jp_roof(im, cx, 30, wall_top + 6, float(bw) * 0.24, float(W) * 0.5 - 1.0, 9.0, roof_ramp)
	# мелочи
	if deco == "lantern":
		chochin(im, x0 + 18, wall_top + 8, 5.0, Color("d83a2a"))
		chochin(im, x0 + bw - 18, wall_top + 8, 5.0, Color("d83a2a"))
	elif deco == "bonsai":
		box3(im, x0 + 6, floor_y - 14, 14, 8, 2, hx(["3a2a4a", "4e3a62", "644e7c", "7e6696", "9a84b0"]), 3)
		blob(im, x0 + 13, floor_y - 19, 9, 5, BUSH, 4)
		blob(im, x0 + 9, floor_y - 23, 6, 3, BUSH, 5)
		line(im, x0 + 13, floor_y - 14, x0 + 12, floor_y - 20, Color("5a3a24"))
	elif deco == "bamboo":
		for k in range(3):
			var bx: int = x0 + bw - 12 + k * 4
			for y3 in range(floor_y - 50 + k * 6, floor_y):
				px(im, bx, y3, Color("6aa848"))
				px(im, bx + 1, y3, Color("8cc464"))
				if posmod(y3, 12) == 0:
					px(im, bx, y3, Color("3a6a2a"))
					px(im, bx + 1, y3, Color("4e8a36"))
	outline_auto(im, 0.42)
	save3(im, name, false)
	return im


func gen_japan13() -> void:
	var items: Array = []
	var im: Image
	items.append(["jp_house_a", jp_house13("jp_house_a", 180, hx(JTILE), Color("2a3a6a"), "bonsai", 3)])
	items.append(["jp_house_b", jp_house13("jp_house_b", 200, hx(JTILE_B), Color("6a2a3a"), "bamboo", 5)])
	items.append(["jp_house_c", jp_house13("jp_house_c", 170, hx(JTILE), Color("2a5a3a"), "lantern", 7)])
	# лавка: дом с вывеской-доской и товарами на веранде
	im = jp_house13("shop_japan", 186, hx(JTILE_B), Color("1e3a5a"), "lantern", 9)
	var wd: Array = hx(JWOOD)
	box3(im, 16, 110, 16, 44, 2, wd, 4)
	for k in range(4):
		rect(im, 20, 116 + k * 9, 8, 5, Color("e8dcc0"))
		rect(im, 21, 117 + k * 9, 6, 1, Color("2a1a14"))
	for k2 in range(3):
		blob(im, 146 + k2 * 9, 146, 4, 3, hx(["6a3a1a", "8a5a2a", "aa7a3a", "c89a50", "e0b870", "f0d498", "f8ecc4"]), 4)
	outline_auto(im, 0.3)
	save3(im, "shop_japan", false)
	items.append(["shop_japan", im])
	# чайный домик: два этажа, красные фонарики, скамья под красным зонтом
	im = new_img(250, 230)
	var cx: float = 125.0
	ell(im, cx, 224, 116, 6, Color(0.08, 0.06, 0.1, 0.3))
	stone_base(im, 18, 204, 214, 12, 21)
	shoji_wall(im, 22, 148, 206, 52, true, 21)
	for x in range(14, 236):
		for y in range(198, 205):
			px(im, x, y, wd[5] if y == 198 else (wd[4] if posmod(x, 12) != 0 else wd[2]))
	jp_roof(im, cx, 118, 152, 70.0, 124.0, 7.0, hx(JTILE))
	shoji_wall(im, 52, 76, 146, 40, true, 22)
	# перила балкона второго этажа
	for x2 in range(48, 202):
		px(im, x2, 114, JVERM_C(4))
		px(im, x2, 115, JVERM_C(2))
		if posmod(x2, 8) == 0:
			line(im, x2, 106, x2, 114, JVERM_C(3))
	for x3 in range(48, 202):
		px(im, x3, 106, JVERM_C(5))
	jp_roof(im, cx, 30, 82, 30.0, 92.0, 10.0, hx(JTILE))
	for lx in [40, 70, 180, 210]:
		chochin(im, lx, 154, 5.5, Color("d83a2a"))
	rect(im, int(cx) - 14, 160, 28, 38, wd[1])
	rect(im, int(cx) - 12, 162, 24, 36, Color("f0c070"))
	noren(im, cx, 156, 36, 18, Color("b82a22"), Color("f4ecdc"))
	# вывеска с чашкой
	box3(im, int(cx) - 16, 122, 32, 14, 2, wd, 4)
	ell(im, cx, 130, 5, 3, Color("e8e0d0"))
	ell(im, cx, 128.5, 4, 1.4, Color("6a8a3a"))
	outline_auto(im, 0.42)
	save3(im, "tavern_japan", false)
	items.append(["tavern_japan", im])
	# замок-тэнсю на каменном основании
	im = new_img(320, 380)
	cx = 160.0
	ell(im, cx, 372, 150, 8, Color(0.08, 0.06, 0.1, 0.32))
	var st: Array = hx(JSTONE)
	# исигаки: наклонные каменные стены
	for y in range(290, 368):
		var t: float = float(y - 290) / 77.0
		var hw: float = 112.0 + pow(t, 1.8) * 34.0
		var row: int = (y - 290) / 7
		for x in range(int(cx - hw), int(cx + hw) + 1):
			var off: int = (6 if row % 2 == 1 else 0) + int(h01(row, 1, 31) * 5.0)
			var lx2: int = posmod(x + off, 14)
			var ly: int = posmod(y - 290, 7)
			var sid: int = (x + off) / 14
			var ti: int = 3 + int(h01(sid, row, 32) * 2.0)
			if float(x) > cx + hw * 0.6:
				ti -= 1
			if lx2 == 0 or ly == 6:
				ti = 1
			elif ly == 0:
				ti += 1
			px(im, x, y, st[clampi(ti, 0, 6)])
	# ворота в основании
	for y2 in range(326, 368):
		for x4 in range(int(cx) - 22, int(cx) + 23):
			var dy: float = float(y2 - 334)
			var dx: float = float(x4) + 0.5 - cx
			if dy < 0.0 and dx * dx + dy * dy * 4.0 > 484.0:
				continue
			var plank: int = posmod(int(dx + 22.0) / 5, 2)
			px(im, x4, y2, wd[2 + plank] if absf(dx) > 0.8 else wd[0])
			if posmod(int(dx + 22.0), 11) == 5 and posmod(y2, 7) == 0:
				px(im, x4, y2, Color("8a8a96"))
	# три яруса: белая штукатурка, чёрные доски внизу, окна, крыши
	var tiers: Array = [[246, 290, 104.0, 46], [180, 240, 80.0, 40], [116, 176, 58.0, 34]]
	var pl: Array = hx(JPLAST)
	for ti2 in range(tiers.size()):
		var tr: Array = tiers[ti2]
		var y0: int = tr[0]
		var y1: int = tr[1]
		var hw2: float = tr[2]
		for y3 in range(y0, y1):
			for x5 in range(int(cx - hw2), int(cx + hw2) + 1):
				var u2: float = (float(x5) + 0.5 - (cx - hw2)) / (2.0 * hw2)
				var c2: Color = pl[4] if u2 < 0.6 else pl[3]
				if y3 > y1 - 16:
					c2 = wd[1] if posmod(x5, 6) != 0 else wd[0]
					if y3 == y1 - 16:
						c2 = wd[3]
				if y3 < y0 + 4:
					c2 = pl[2]
				px(im, x5, y3, c2)
		# окна-решётки
		var nwin: int = [5, 4, 3][ti2]
		for k3 in range(nwin):
			var wx: float = cx - hw2 + (2.0 * hw2) * (float(k3) + 0.5) / float(nwin)
			for y4 in range(y0 + 10, y0 + 22):
				for x6 in range(int(wx) - 5, int(wx) + 6):
					var lit: bool = posmod(x6, 3) != 0
					px(im, x6, y4, Color("f0c070") if lit else wd[1])
			rect(im, int(wx) - 6, y0 + 9, 13, 1, wd[2])
			rect(im, int(wx) - 6, y0 + 22, 13, 1, wd[2])
		var roof_y: int = y0 + 2
		jp_roof(im, cx, roof_y - (16 if ti2 < 2 else 30), roof_y + 4, hw2 * 0.6, hw2 + 20.0, 10.0, hx(JTILE))
		if ti2 == 1:
			# кара-хафу: закруглённый фронтон посередине
			for k4 in range(48):
				var a: float = PI + PI * float(k4) / 47.0
				var p: Vector2 = Vector2(cx + cos(a) * 26.0, float(roof_y) - 2.0 + sin(a) * 12.0)
				rect(im, int(p.x), int(p.y), 2, 3, hx(JTILE)[1])
				px(im, int(p.x), int(p.y) + 3, Color("e8c860"))
			for y5 in range(roof_y - 12, roof_y + 2):
				for x7 in range(int(cx) - 22, int(cx) + 23):
					var dd: Vector2 = Vector2(float(x7) + 0.5 - cx, (float(y5) - float(roof_y) + 2.0) * 2.1)
					if dd.length() < 21.0 and y5 < roof_y:
						px(im, x7, y5, pl[4] if dd.x < 0.0 else pl[3])
			disc(im, cx, roof_y - 5, 3.0, Color("e8c860"))
	# золотые сятихоко на коньке
	for sx in [-1.0, 1.0]:
		var sp: Vector2 = Vector2(cx + float(sx) * 36.0, 84)
		blob(im, sp.x, sp.y, 3.0, 4.5, hx(BRASS7), 5)
		capsule(im, sp + Vector2(0, -3), sp + Vector2(float(sx) * -3.0, -10), 2.2, 1.0, hx(BRASS7), 5)
	outline_auto(im, 0.45)
	save3(im, "palace_japan", false)
	items.append(["palace_japan", im])
	# пагода в пять ярусов
	im = new_img(130, 320)
	cx = 65.0
	ell(im, cx, 314, 52, 5, Color(0.08, 0.06, 0.1, 0.3))
	stone_base(im, 24, 300, 82, 10, 41)
	var vm: Array = hx(JVERM)
	for k5 in range(5):
		var ybot: int = 300 - k5 * 50
		var hw3: float = 32.0 - float(k5) * 3.5
		for y6 in range(ybot - 30, ybot):
			for x8 in range(int(cx - hw3), int(cx + hw3) + 1):
				var u3: float = (float(x8) + 0.5 - (cx - hw3)) / (2.0 * hw3)
				var c3: Color = pl[4] if u3 < 0.55 else pl[3]
				if posmod(int(float(x8) - cx + hw3), 14) < 3:
					c3 = vm[3] if u3 < 0.55 else vm[2]
				if y6 < ybot - 26:
					c3 = vm[4]
				px(im, x8, y6, c3)
		rect(im, int(cx) - 5, ybot - 22, 10, 14, wd[1])
		jp_roof(im, cx, ybot - 48, ybot - 26, hw3 * 0.5, hw3 + 18.0, 8.0, hx(JTILE))
	# сорин: шпиль с золотыми кольцами
	for y7 in range(16, 56):
		px(im, int(cx), y7, hx(BRASS7)[4])
		px(im, int(cx) + 1, y7, hx(BRASS7)[2])
		if posmod(y7, 5) == 0 and y7 > 24:
			rect(im, int(cx) - 3, y7, 8, 2, hx(BRASS7)[5])
	blob(im, cx + 0.5, 14, 3, 4, hx(BRASS7), 5)
	outline_auto(im, 0.45)
	save3(im, "jp_pagoda", false)
	items.append(["jp_pagoda", im])
	# тории
	im = new_img(150, 130)
	cx = 75.0
	ell(im, cx, 126, 64, 4, Color(0.08, 0.06, 0.1, 0.28))
	for sx2 in [-1.0, 1.0]:
		var px0: float = cx + float(sx2) * 48.0
		for y8 in range(26, 124):
			var lean: float = float(sx2) * float(124 - y8) * -0.03
			for x9 in range(int(px0 + lean) - 4, int(px0 + lean) + 5):
				var u4: float = (float(x9) + 0.5 - (px0 + lean - 4.0)) / 9.0
				var c4: Color = vm[5] if u4 < 0.3 else (vm[4] if u4 < 0.6 else vm[2])
				if y8 > 112:
					c4 = hx(JTILE)[2] if u4 > 0.4 else hx(JTILE)[4]
				px(im, x9, y8, c4)
	# нуки — поперечная балка
	box3(im, 14, 40, 122, 7, 2, vm, 4)
	# касаги: чёрная верхняя балка с поднятыми концами, под ней красная симаки
	for x10 in range(2, 148):
		var u5: float = (float(x10) - cx) / 73.0
		var up: float = pow(absf(u5), 3.0) * 9.0
		for k6 in range(7):
			var yy: int = int(18.0 - up) + k6
			px(im, x10, yy, hx(JTILE)[[4, 3, 2, 2, 1, 1, 0][k6]])
		for k7 in range(5):
			var yy2: int = int(25.0 - up * 0.6) + k7
			if absf(u5) < 0.86:
				px(im, x10, yy2, vm[[5, 4, 3, 3, 1][k7]])
	# табличка гакудзука
	box3(im, int(cx) - 7, 29, 14, 12, 2, hx(JTILE), 3)
	rect(im, int(cx) - 4, 31, 8, 8, Color("e8c860"))
	for k8 in range(3):
		rect(im, int(cx) - 2, 32 + k8 * 2, 4, 1, hx(JTILE)[1])
	outline_auto(im, 0.42)
	save3(im, "torii", false)
	items.append(["torii", im])
	# каменный фонарь исидоро
	im = new_img(36, 70)
	cx = 18.0
	ell(im, cx, 67, 13, 2.5, Color(0.08, 0.06, 0.1, 0.3))
	box3(im, 7, 58, 22, 9, 2, st, 4)
	box3(im, 13, 40, 10, 18, 2, st, 4)
	box3(im, 9, 34, 18, 6, 2, st, 4)
	box3(im, 10, 22, 16, 12, 2, st, 4)
	rect(im, 13, 25, 10, 7, Color("ffd890"))
	rect(im, 15, 26, 6, 5, Color("fff2c0"))
	line(im, 18, 25, 18, 31, st[2])
	for k9 in range(7):
		var rw: int = 15 - k9 + (2 if k9 == 0 else 0)
		rect(im, int(cx) - rw, 21 - k9, rw * 2, 1, st[clampi(5 - k9 / 2, 0, 6)])
	px(im, 2, 20, st[4])
	px(im, 33, 20, st[3])
	blob(im, cx, 12, 3, 3.5, st, 4)
	for k10 in range(10):
		var mp: Vector2 = Vector2(9 + h01(k10, 1, 51) * 18.0, 36 + h01(k10, 2, 51) * 28.0)
		if a_at(im, int(mp.x), int(mp.y)) > 0.5:
			px(im, int(mp.x), int(mp.y), Color("5a8a3a"))
			px(im, int(mp.x) + 1, int(mp.y), Color("7aa84e"))
	outline_auto(im, 0.42)
	save3(im, "stone_lantern", false)
	items.append(["stone_lantern", im])
	# бамбуковая рощица
	im = new_img(80, 190)
	ell(im, 40, 186, 30, 4, Color(0.08, 0.06, 0.1, 0.3))
	var bg: Array = hx(["2e5a22", "3e7a2c", "529638", "6aae48", "8cc464", "b0da8a", "d4eeb2"])
	for k11 in range(7):
		var bx: float = 8.0 + float(k11) * 10.0 + h01(k11, 1, 61) * 4.0
		var top: int = 6 + int(h01(k11, 2, 61) * 46.0)
		var back: bool = k11 % 2 == 1
		for y9 in range(top, 186):
			var sway: float = pow(float(186 - y9) / 180.0, 2.0) * (4.0 if k11 % 3 == 0 else -3.0)
			var xx: int = int(bx + sway)
			for k12 in range(4):
				px(im, xx + k12, y9, bg[clampi([4, 3, 3, 2][k12] - (1 if back else 0), 0, 6)])
			if posmod(y9 - top, 20) == 0:
				rect(im, xx - 1, y9, 6, 1, bg[1])
				rect(im, xx - 1, y9 + 1, 6, 1, bg[5])
			# пучки листьев у узлов
			if posmod(y9 - top, 20) == 10 and y9 < 150:
				var sd: float = 1.0 if posmod((y9 - top) / 20 + k11, 2) == 0 else -1.0
				for k13 in range(3):
					var dir: Vector2 = Vector2(sd, 0.25 + float(k13) * 0.3).normalized()
					draw_leaf(im, Vector2(xx + 2, y9) + dir * 7.0, dir, 13.0, 3.6, 4 - (1 if back else 0), bg)
	outline_auto(im, 0.35)
	save3(im, "bamboo", false)
	items.append(["bamboo", im])
	# пруд с карпами кои (на земле) и красный мостик
	im = new_img(220, 120)
	var pc: Vector2 = Vector2(110, 60)
	for y10 in range(120):
		for x11 in range(220):
			var d2: Vector2 = Vector2(x11 + 0.5, y10 + 0.5) - pc
			var ang: float = atan2(d2.y, d2.x)
			var R: float = 1.0 + sin(ang * 3.0 + 0.6) * 0.08 + sin(ang * 5.0) * 0.05
			var e: float = Vector2(d2.x / 100.0, d2.y / 50.0).length() / R
			if e > 1.0:
				continue
			if e > 0.86:
				var sid2: int = int((ang + PI) * 9.0)
				var tone: int = 3 + int(h01(sid2, 0, 71) * 2.0)
				if fposmod((ang + PI) * 9.0, 1.0) < 0.12:
					tone = 1
				px(im, x11, y10, st[tone])
				continue
			var deep: float = 1.0 - e
			var wc: Color = Color("4aa0a8").lerp(Color("1e5a72"), clampf(deep * 1.6, 0.0, 1.0))
			if sin(float(x11) * 0.25 + float(y10) * 0.6) > 0.94:
				wc = wc.lightened(0.18)
			px(im, x11, y10, wc)
	for lp in [Vector2(60, 46), Vector2(150, 74), Vector2(168, 44)]:
		var lv: Vector2 = lp
		for y11 in range(int(lv.y) - 5, int(lv.y) + 6):
			for x12 in range(int(lv.x) - 7, int(lv.x) + 8):
				var dd2: Vector2 = Vector2(x12 + 0.5 - lv.x, (y11 + 0.5 - lv.y) * 1.4)
				if dd2.length() < 7.0 and not (dd2.x > 0.0 and absf(dd2.y) < dd2.x * 0.3):
					px(im, x12, y11, Color("5a9a3a") if dd2.x < 2.0 else Color("4a8a32"))
		px(im, int(lv.x) - 1, int(lv.y) - 1, Color("f4b0c8"))
		px(im, int(lv.x), int(lv.y) - 2, Color("fcd8e4"))
	for kf in range(4):
		var kp: Vector2 = Vector2(80 + kf * 22, 54 + (kf % 2) * 14)
		var kc: Color = [Color("f07a2a"), Color("f8f4ec"), Color("e84a2a"), Color("f4c040")][kf]
		var kd: float = 1.0 if kf % 2 == 0 else -1.0
		for k14 in range(9):
			var bp: Vector2 = kp + Vector2(kd * float(k14), sin(float(k14) * 0.5) * 1.2)
			var bw2: int = 2 if k14 < 6 else 1
			for w2 in range(-bw2 / 2, bw2 - bw2 / 2 + 1):
				px(im, int(bp.x), int(bp.y) + w2, kc if (k14 + kf) % 4 != 0 else Color("f8f4ec"))
		px(im, int(kp.x + kd * 10.0), int(kp.y) - 1, kc)
		px(im, int(kp.x + kd * 10.0), int(kp.y) + 1, kc)
	save3(im, "koi_pond", false)
	items.append(["koi_pond", im])
	im = new_img(130, 76)
	ell(im, 65, 72, 56, 4, Color(0.08, 0.06, 0.1, 0.25))
	for x13 in range(6, 124):
		var u6: float = (float(x13) - 65.0) / 59.0
		var arch: float = (1.0 - u6 * u6) * 22.0
		var yb: int = int(56.0 - arch)
		for k15 in range(14):
			var y12: int = yb + k15
			var c5: Color = wd[5] if k15 < 2 else (wd[4] if posmod(x13, 6) != 0 else wd[2])
			if k15 > 10:
				c5 = wd[1]
			px(im, x13, y12, c5)
		# перила
		px(im, x13, yb - 9, vm[5])
		px(im, x13, yb - 8, vm[3])
		if posmod(x13, 16) == 6:
			for k16 in range(9):
				px(im, x13, yb - 9 + k16, vm[3])
				px(im, x13 + 1, yb - 9 + k16, vm[2])
			disc(im, x13 + 0.5, yb - 10, 1.4, Color("e8c860"))
	outline_auto(im, 0.42)
	save3(im, "jp_bridge", false)
	items.append(["jp_bridge", im])
	# ятай — тележки-лавки с фонариками
	for kk in range(2):
		im = new_img(112, 104)
		cx = 56.0
		ell(im, cx, 99, 48, 4, Color(0.08, 0.06, 0.1, 0.3))
		for sx3 in [12, 98]:
			line(im, sx3, 30, sx3, 92, wd[3])
			line(im, sx3 + 1, 30, sx3 + 1, 92, wd[2])
		box3(im, 8, 64, 96, 26, 4, wd, 4)
		for x14 in range(10, 102, 8):
			line(im, x14, 66, x14, 88, wd[2])
		for wx2 in [22, 90]:
			disc(im, wx2, 92, 6.0, wd[1])
			disc(im, wx2, 92, 4.0, wd[3])
			disc(im, wx2, 92, 1.4, wd[1])
		jp_roof(im, cx, 14, 34, 34.0, 56.0, 6.0, hx(JTILE) if kk == 0 else hx(JTILE_B))
		noren(im, cx, 34, 80, 14, [Color("2a3a6a"), Color("b82a22")][kk], Color("f4ecdc"))
		chochin(im, 16, 36, 4.5, Color("d83a2a"))
		chochin(im, 96, 36, 4.5, Color("d83a2a"))
		if kk == 0:
			# данго на палочках
			for k17 in range(4):
				var dx2: int = 30 + k17 * 14
				line(im, dx2, 52, dx2 + 2, 63, Color("c8a870"))
				for k18 in range(3):
					disc(im, dx2 + k18 * 0.6, 54 + k18 * 3, 2.2, [Color("f4a8b8"), Color("fffaf0"), Color("a8d080")][k18])
		else:
			# веера и чашки
			for k19 in range(3):
				var fx: float = 30.0 + float(k19) * 22.0
				for k20 in range(9):
					var a2: float = PI + PI * float(k20) / 8.0
					line(im, int(fx), 62, int(fx + cos(a2) * 9.0), int(62.0 + sin(a2) * 9.0), [Color("e84a5a"), Color("f0f0e8"), Color("4a7ac8")][k19] if k20 % 2 == 0 else Color("2a1a14"))
		outline_auto(im, 0.4)
		save3(im, "stall_jp_%d" % kk, false)
		items.append(["stall_jp_%d" % kk, im])
	# лепесток сакуры для частиц
	im = new_img(6, 5)
	for p2 in [Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1), Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2), Vector2i(4, 2), Vector2i(1, 3), Vector2i(2, 3), Vector2i(3, 3)]:
		var pv: Vector2i = p2
		px(im, pv.x, pv.y, Color("f8b8cc") if pv.y > 1 else Color("fcd8e4"))
	px(im, 4, 1, Color("e890a8"))
	save3(im, "fx_petal", false)
	# улица: светлый гравий с граблевыми бороздками и плоскими камнями
	im = new_img(64, 64)
	var gr: Array = hx(["8a8478", "9c968a", "aea89c", "c0baae", "d0cabe", "dedad0"])
	for y13 in range(64):
		for x15 in range(64):
			var rk: float = sin(float(y13) * TAU / 8.0)
			var ti3: int = 3 + int(round(rk * 0.8)) + (1 if h01(x15, y13, 81) > 0.8 else 0) - (1 if h01(x15, y13, 82) > 0.85 else 0)
			px(im, x15, y13, gr[clampi(ti3, 0, 5)])
	save3(im, "st10_japan", false)
	_sheet(items, 2, "v13_japan.png")


func JVERM_C(i: int) -> Color:
	return Color(JVERM[clampi(i, 0, 6)])


# ================================================================== v13: хозяйство — постройки, саженцы, значки, ячейки сумки

const SOIL7: Array = ["1e140e", "2e1e14", "40281a", "523422", "66442c", "7c583a", "94704c"]
const BURLAP7: Array = ["4a3a24", "64502e", "7e6838", "988246", "b09c5a", "c8b474", "dcca92"]

# порода дерева: [листва (7), ствол (7), вид]
const SAP_LOOK: Dictionary = {
	"tree_a": [["1e3a1e", "2a5226", "3a6a30", "4e843a", "66a046", "86b858", "a8d070"], "trunk", "broad"],
	"tree_b": [["2a4a1e", "3a6226", "4e7c30", "68983c", "84b24a", "a2c85c", "c0dc7a"], "trunk", "broad"],
	"tree_c": [["16362e", "1e4a3c", "2a6048", "3a7856", "529466", "70ae7a", "94c896"], "trunk", "broad"],
	"tree_d": [["2e4214", "40581c", "567226", "6e8c30", "88a63e", "a4c052", "c2d872"], "trunk", "broad"],
	"pine_a": [["0e2a1e", "163a28", "1e4c32", "2a603e", "3a764c", "52905e", "72aa76"], "trunk", "pine"],
	"pine_b": [["0a2228", "123238", "1a4446", "245854", "326e64", "468878", "62a290"], "trunk", "pine"],
	"tree_blossom": [["7a3a5a", "a04e74", "c06a8e", "d888a8", "eaa8c2", "f6c8d8", "fde6ee"], "trunk", "broad"],
	"tree_autumn": [["6a2a0e", "8e3c12", "b25418", "d0701e", "e4902e", "f2b04a", "fad07a"], "trunk", "broad"],
	"tree_autumn2": [["5a1414", "7e1e1a", "a22a20", "c23e28", "da5a36", "ec8050", "f8aa78"], "trunk", "broad"],
	"tree_apple": [["1e3a1e", "2a5226", "3a6a30", "4e843a", "66a046", "86b858", "a8d070"], "trunk", "apple"],
	"tree_birch": [["3a5a1e", "4e7626", "669232", "80ac40", "9cc452", "b8d86a", "d4ea90"], "birch", "broad"],
	"tree_unicorn": [["5a3a7a", "7a4ea0", "9a68c0", "b888d8", "d2a8ea", "e6c8f4", "f6e6fc"], "trunk", "broad"],
	"dead_tree_a": [["2a2024", "3a2e30", "4a3c3c", "5e4e4a", "74625a", "8a7868", "a08e7c"], "trunk", "dead"],
	"dead_tree_b": [["2a2024", "3a2e30", "4a3c3c", "5e4e4a", "74625a", "8a7868", "a08e7c"], "trunk", "dead"],
}


## Холмик земли с крошками и кольцом мульчи
func soil_mound13(im: Image, cx: float, cy: float, rx: float, ry: float) -> void:
	var so: Array = hx(SOIL7)
	ell(im, cx, cy + 1.0, rx + 1.0, ry + 1.0, so[1])
	for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
		for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
			var nx: float = (float(x) + 0.5 - cx) / rx
			var ny: float = (float(y) + 0.5 - cy) / ry
			var d: float = nx * nx + ny * ny
			if d > 1.0:
				continue
			var ti: int = 4 if ny < -0.2 else (3 if ny < 0.4 else 2)
			if h01(x, y, 91) > 0.82:
				ti += 1
			elif h01(x, y, 92) > 0.86:
				ti -= 1
			px(im, x, y, so[clampi(ti, 0, 6)])


## Саженец: stage 0 — росток с двумя листиками, 1 — прутик с листьями, 2 — молодое деревце у колышка
func sapling13(im: Image, cx: float, base: float, stage: int, look: Array, seed_v: int) -> void:
	var lr: Array = hx(look[0])
	var kind: String = look[2]
	var stem: Array = hx(["2a1a10", "3e2818", "56381e", "6e4a28", "8a6236", "a67c4a", "c49a66"])
	if String(look[1]) == "birch":
		stem = hx(["5a5a58", "8a8a86", "b4b4ae", "d4d4cc", "eaeae2", "f6f6f0", "ffffff"])
	if stage == 0:
		line(im, int(cx), int(base) - 1, int(cx), int(base) - 6, hx(["3a6a2a", "4e8a36"])[1])
		if kind == "dead":
			line(im, int(cx), int(base) - 6, int(cx) + 2, int(base) - 8, stem[3])
			return
		draw_leaf(im, Vector2(cx - 3.0, base - 7.0), Vector2(-1, -0.4), 6.0, 3.6, 4, lr if kind != "pine" else hx(KELP7))
		draw_leaf(im, Vector2(cx + 3.0, base - 7.5), Vector2(1, -0.5), 6.0, 3.6, 5, lr if kind != "pine" else hx(KELP7))
		return
	var h: float = 16.0 if stage == 1 else 34.0
	# ствол
	for y in range(int(base - h), int(base)):
		var t: float = (base - float(y)) / h
		var w: int = 2 if (stage == 2 and t < 0.6) else 1
		var xo: float = cx + sin(t * 2.0 + float(seed_v)) * 0.8
		for k in range(w + 1):
			px(im, int(xo) + k, y, stem[4 - k * 2] if k <= 1 else stem[1])
		if String(look[1]) == "birch" and posmod(y, 5) == 0:
			px(im, int(xo), y, Color("2a2a2a"))
	if stage == 2:
		# колышек с подвязкой
		for y2 in range(int(base - 26), int(base) + 1):
			px(im, int(cx) + 6, y2, hx(LOG)[4])
			px(im, int(cx) + 7, y2, hx(LOG)[2])
		line(im, int(cx) + 1, int(base) - 18, int(cx) + 6, int(base) - 18, Color("d8c08a"))
		line(im, int(cx) + 1, int(base) - 17, int(cx) + 6, int(base) - 17, Color("a88a58"))
	if kind == "dead":
		for k2 in range(4 if stage == 2 else 2):
			var yy: float = base - h * (0.4 + 0.15 * float(k2))
			var sd: float = 1.0 if k2 % 2 == 0 else -1.0
			line(im, int(cx), int(yy), int(cx + sd * (4.0 + float(stage) * 2.0)), int(yy - 4.0), stem[3])
		return
	if kind == "pine":
		# ярусы хвои: короткие иголки-штрихи
		var tiers: int = 3 if stage == 1 else 5
		for k3 in range(tiers):
			var ty: float = base - h * (0.25 + 0.75 * float(k3) / float(tiers))
			var tw: float = (7.0 if stage == 1 else 12.0) * (1.0 - float(k3) / float(tiers + 1))
			for x in range(int(cx - tw), int(cx + tw) + 1):
				var u: float = (float(x) + 0.5 - cx) / tw
				var droop: float = absf(u) * 3.0
				for d2 in range(3):
					var c: Color = lr[clampi(4 - d2 + (1 if u < 0.0 else 0), 0, 6)]
					px(im, x, int(ty + droop) + d2, c)
		px(im, int(cx), int(base - h) - 1, lr[5])
		return
	# лиственный: листики по веткам, к верху гуще
	var nleaf: int = 7 if stage == 1 else 22
	rng.seed = seed_v * 13 + stage
	for k4 in range(nleaf):
		var t2: float = 0.45 + 0.55 * float(k4) / float(nleaf)
		var ly: float = base - h * t2
		var sd2: float = 1.0 if k4 % 2 == 0 else -1.0
		var spread: float = (3.0 if stage == 1 else 9.0) * sin(t2 * PI) + 2.0
		var lp: Vector2 = Vector2(cx + sd2 * rng.randf_range(1.0, spread), ly + rng.randf_range(-2.0, 2.0))
		var dir: Vector2 = Vector2(sd2, -0.6 + rng.randf_range(-0.3, 0.3)).normalized()
		draw_leaf(im, lp, dir, 6.0 if stage == 1 else 7.0, 3.6, 4 + (1 if sd2 < 0.0 else 0) - (1 if k4 < nleaf / 3 else 0), lr, stage == 2)
	if kind == "apple" and stage == 2:
		for ap in [Vector2(-5, -24), Vector2(4, -30)]:
			var av: Vector2 = ap
			blob(im, cx + av.x, base + av.y, 1.8, 1.8, hx(["5a0a0a", "8a1414", "b82020", "d83a2a", "ee6040", "f8946a", "fcc0a0"]), 4)


func gen_home13() -> void:
	var items: Array = []
	var w7: Array = hx(LOG)
	var im: Image
	# ---------------------------------------------------------------- верстак
	im = new_img(96, 74)
	ell(im, 48, 70, 42, 4, Color(0.08, 0.06, 0.1, 0.3))
	# задняя доска с инструментами
	box3(im, 10, 8, 76, 26, 2, w7, 3)
	for x in range(12, 84, 9):
		line(im, x, 10, x, 32, w7[2])
	# пила
	for k in range(22):
		px(im, 16 + k, 14 + k / 6, Color("c8ccd8"))
		px(im, 16 + k, 15 + k / 6, Color("9a9ea8"))
		if k % 2 == 0:
			px(im, 16 + k, 16 + k / 6, Color("6a6e78"))
	box3(im, 12, 11, 6, 7, 1, w7, 5)
	# молоток и стамески
	line(im, 48, 12, 48, 28, w7[5])
	line(im, 49, 12, 49, 28, w7[3])
	box3(im, 44, 10, 10, 5, 1, hx(["30303a", "464652", "5e5e6c", "7a7a88", "9a9aa6"]), 3)
	for k2 in range(3):
		var sx: int = 60 + k2 * 6
		line(im, sx, 12, sx, 20, w7[5 - k2])
		line(im, sx, 21, sx, 28, Color("b8bcc8"))
	# клещи на гвоздике
	line(im, 76, 13, 80, 26, Color("6a6e78"))
	line(im, 80, 13, 76, 26, Color("8a8e98"))
	# столешница
	box3(im, 4, 34, 88, 10, 4, w7, 4)
	for x2 in range(6, 90, 14):
		line(im, x2, 35, x2, 38, w7[3])
	# стружка и брусок
	box3(im, 40, 29, 22, 6, 2, hx(["8a6a3a", "a8844c", "c49e62", "dcba80", "eed4a0"]), 3)
	for k3 in range(5):
		var cp: Vector2 = Vector2(28 + k3 * 4, 32 + (k3 % 2))
		px(im, int(cp.x), int(cp.y), Color("eed4a0"))
		px(im, int(cp.x) + 1, int(cp.y) - 1, Color("dcba80"))
	# тиски
	box3(im, 74, 26, 12, 9, 2, hx(["30303a", "464652", "5e5e6c", "7a7a88", "9a9aa6"]), 3)
	line(im, 72, 30, 88, 30, Color("c0c0c8"))
	# ножки и распорка
	for lx in [8, 82]:
		box3(im, lx, 44, 7, 24, 1, w7, 3)
	box3(im, 12, 56, 72, 4, 1, w7, 3)
	# полка внизу с брусками
	for k4 in range(3):
		box3(im, 22 + k4 * 16, 50, 14, 6, 1, hx(["6a4a2a", "8a6238", "a87c4a", "c49660", "dcb07a"]), 3)
	outline_auto(im, 0.42)
	save3(im, "workbench", false)
	items.append(["workbench", im])
	# ---------------------------------------------------------------- стол изучения трав
	im = new_img(96, 78)
	ell(im, 48, 74, 42, 4, Color(0.08, 0.06, 0.1, 0.3))
	var dark_w: Array = hx(["2a1a14", "3e281e", "54382a", "6c4a38", "866048", "a07a5e"])
	# рама с сушёными травами
	for lx2 in [10, 84]:
		box3(im, lx2, 4, 4, 38, 1, dark_w, 3)
	box3(im, 8, 4, 82, 4, 1, dark_w, 3)
	var bunches: Array = [MINT, LAV, ["6a5a1a", "8a7a26", "aa9a36", "c8b850", "e0d070", "f0e494", "f8f2c4"], MINT, LAV]
	for k5 in range(5):
		var bx: int = 20 + k5 * 14
		line(im, bx, 8, bx, 12, Color("c8b088"))
		var br: Array = bunches[k5]
		var brc: Array = hx(br) if typeof(br[0]) == TYPE_STRING else br
		for k6 in range(5):
			line(im, bx + k6 - 2, 12, bx + (k6 - 2) * 2, 26 + (k6 % 2) * 2, brc[clampi(3 + k6 % 3, 0, brc.size() - 1)])
		rect(im, bx - 2, 12, 5, 2, Color("b04030"))
	# столешница
	box3(im, 4, 38, 88, 10, 4, dark_w, 4)
	# раскрытая книга с рисунком листа
	for y in range(28, 40):
		for x3 in range(14, 46):
			var mid: bool = x3 == 30
			var c: Color = Color("f4ecd8") if x3 < 30 else Color("ece2c8")
			if mid:
				c = Color("b8a888")
			if y == 39:
				c = Color("8a5a3a")
			px(im, x3, y, c)
	for k7 in range(4):
		line(im, 33, 30 + k7 * 2, 43, 30 + k7 * 2, Color("9a8a78"))
	draw_leaf(im, Vector2(22, 33), Vector2(1, -0.4), 9.0, 5.0, 4, hx(MINT) if typeof(MINT[0]) == TYPE_STRING else MINT, true)
	# ступка с пестиком
	blob(im, 56, 34, 6, 4.5, hx(["4a4a52", "62626c", "7c7c86", "9696a0", "b0b0b8", "cacad0", "e0e0e4"]), 4)
	ell(im, 56, 31, 5, 1.6, Color("3a3a40"))
	line(im, 57, 31, 62, 22, w7[5])
	line(im, 58, 31, 63, 22, w7[3])
	# баночки
	for k8 in range(3):
		var jx: int = 68 + k8 * 8
		var jc: Array = [Color("7ac0a0"), Color("c890d0"), Color("e8c860")]
		for y4 in range(26, 38):
			for x4 in range(jx, jx + 6):
				var u: float = float(x4 - jx) / 5.0
				var cc: Color = Color(0.8, 0.9, 0.95, 0.85)
				if y4 > 29:
					cc = (jc[k8] as Color).lightened(0.2) if u < 0.4 else jc[k8]
				if x4 == jx + 1 and y4 > 27:
					cc = Color(1, 1, 1, 0.9)
				px(im, x4, y4, cc)
		rect(im, jx, 24, 6, 2, Color("8a5a3a"))
	# свеча
	rect(im, 50, 26, 3, 8, Color("f4ecd8"))
	px(im, 51, 24, Color("ffd060"))
	px(im, 51, 23, Color("fff2b0"))
	# лупа
	disc(im, 40, 44, 3.5, Color("b0d8f0"))
	px(im, 39, 43, Color("ffffff"))
	line(im, 43, 46, 46, 48, w7[2])
	# ножки
	for lx3 in [8, 82]:
		box3(im, lx3, 48, 7, 24, 1, dark_w, 3)
	box3(im, 12, 62, 72, 4, 1, dark_w, 3)
	outline_auto(im, 0.42)
	save3(im, "research_table", false)
	items.append(["research_table", im])
	# ---------------------------------------------------------------- загон: ограда, сено, поилка
	im = new_img(176, 116)
	var pc: Vector2 = Vector2(88, 64)
	var pts: Array = []
	for k9 in range(18):
		var a: float = TAU * float(k9) / 18.0
		pts.append(pc + Vector2(cos(a) * 80.0, sin(a) * 42.0))
	# солома на земле внутри
	for y5 in range(20, 110):
		for x5 in range(6, 170):
			var dv: Vector2 = Vector2((float(x5) - pc.x) / 76.0, (float(y5) - pc.y) / 38.0)
			if dv.length() > 1.0:
				continue
			if h01(x5, y5, 7) > 0.93:
				px(im, x5, y5, Color("d8c070") if h01(x5, y5, 8) > 0.5 else Color("b89a50"))
	# поилка и стожок
	box3(im, 106, 70, 34, 10, 3, w7, 3)
	rect(im, 109, 71, 28, 3, Color("4a8ab0"))
	rect(im, 110, 71, 6, 1, Color("bfe4f6"))
	for k10 in range(40):
		var hp: Vector2 = Vector2(50, 66) + Vector2(cos(float(k10) * 2.4) * float(k10 % 13), -float(k10 % 9) - absf(sin(float(k10))) * 4.0)
		line(im, int(hp.x), int(hp.y), int(hp.x) + 3, int(hp.y) - 2, [Color("e8d080"), Color("c8a850"), Color("f4e4a0")][k10 % 3])
	# жерди и столбики (задняя половина, потом передняя — поверх)
	for half in [0, 1]:
		for k11 in range(18):
			var p0: Vector2 = pts[k11]
			var p1: Vector2 = pts[(k11 + 1) % 18]
			var front: bool = (p0.y + p1.y) * 0.5 > pc.y
			if (half == 1) != front:
				continue
			if k11 == 4:
				continue   # калитка
			for hh in [8, 17]:
				line(im, int(p0.x), int(p0.y) - hh, int(p1.x), int(p1.y) - hh, w7[5])
				line(im, int(p0.x), int(p0.y) - hh + 1, int(p1.x), int(p1.y) - hh + 1, w7[3])
			box3(im, int(p0.x) - 2, int(p0.y) - 24, 5, 24, 1, w7, 4)
	outline_auto(im, 0.38)
	save3(im, "animal_pen", false)
	items.append(["animal_pen", im])
	# ---------------------------------------------------------------- межевой столб с крышей, фонариком и знаком-листиком
	im = new_img(34, 72)
	ell(im, 17, 69, 11, 2.5, Color(0.08, 0.06, 0.1, 0.3))
	box3(im, 14, 14, 7, 56, 1, w7, 4)
	for k12 in range(7):
		rect(im, 17 - k12 - 2, 6 + k12, (k12 + 2) * 2 + 1, 1, hx(["3a2418", "54361e", "6e4a2a", "8a6038"])[clampi(3 - k12 / 2, 0, 3)])
	box3(im, 4, 22, 26, 16, 2, w7, 5)
	draw_leaf(im, Vector2(17, 30), Vector2(0.6, -1.0), 10.0, 6.0, 4, hx(MINT) if typeof(MINT[0]) == TYPE_STRING else MINT, true)
	chochin(im, 25, 42, 3.4, Color("f0b040"))
	rect(im, 12, 52, 11, 2, Color("b04030"))
	px(im, 12, 54, Color("b04030"))
	px(im, 22, 54, Color("b04030"))
	outline_auto(im, 0.42)
	save3(im, "boundary_post", false)
	items.append(["boundary_post", im])
	# колышек границы участка с верёвкой и флажком
	im = new_img(14, 28)
	ell(im, 7, 26, 4, 1.5, Color(0.08, 0.06, 0.1, 0.3))
	box3(im, 5, 8, 4, 18, 1, w7, 4)
	for y6 in range(3, 9):
		for x6 in range(9, 9 + (9 - y6) + 1):
			px(im, x6, y6, Color("e8c860") if y6 < 6 else Color("c89a30"))
	line(im, 8, 3, 8, 9, w7[2])
	rect(im, 4, 14, 6, 2, Color("d8c08a"))
	outline_auto(im, 0.4)
	save3(im, "plot_stake", false)
	# ---------------------------------------------------------------- свежий пень и бревно на земле
	im = new_img(46, 34)
	ell(im, 23, 30, 20, 3.5, Color(0.08, 0.06, 0.1, 0.3))
	var bark: Array = hx(["2a1a10", "3e2818", "56381e", "6e4a28", "8a6236", "a67c4a", "c49a66"])
	# корни
	for rr in [[-1.0, 0.6], [1.0, 0.5], [-0.4, 1.0], [0.5, 1.0]]:
		var rv: Array = rr
		capsule(im, Vector2(23, 22), Vector2(23.0 + float(rv[0]) * 18.0, 26.0 + float(rv[1]) * 3.0), 3.0, 1.2, bark, 3)
	for y7 in range(10, 26):
		for x7 in range(10, 37):
			var u2: float = (float(x7) - 10.0) / 26.0
			var ti: int = 4 if u2 < 0.3 else (3 if u2 < 0.7 else 2)
			if posmod(x7 + int(h01(y7 / 3, 0, 5) * 3.0), 4) == 0:
				ti -= 1
			px(im, x7, y7, bark[ti])
	# свежий срез с годовыми кольцами
	for y8 in range(6, 15):
		for x8 in range(10, 37):
			var d3: Vector2 = Vector2((float(x8) + 0.5 - 23.5) / 13.5, (float(y8) + 0.5 - 10.5) / 4.6)
			var dl: float = d3.length()
			if dl > 1.0:
				continue
			var ring: bool = posmod(int(dl * 6.0 + h01(x8, y8, 3) * 0.6), 2) == 0
			var c2: Color = Color("e8c890") if ring else Color("d4ae74")
			if dl > 0.86:
				c2 = bark[3]
			if dl < 0.12:
				c2 = Color("a87c4a")
			px(im, x8, y8, c2)
	# грибок у пня
	blob(im, 36, 24, 3, 2, hx(["6a1a1a", "9a2a22", "c43a2a", "e05a3a", "f08a6a", "fcb8a0", "ffe8e0"]), 4)
	px(im, 36, 26, Color("f4ecd8"))
	px(im, 35, 23, Color("ffffff"))
	outline_auto(im, 0.4)
	save3(im, "stump_cut", false)
	items.append(["stump_cut", im])
	im = new_img(22, 12)
	capsule(im, Vector2(5, 6), Vector2(17, 6), 3.6, 3.4, bark, 4)
	for y9 in range(3, 10):
		for x9 in range(15, 21):
			var d4: float = Vector2(float(x9) + 0.5 - 18.0, float(y9) + 0.5 - 6.0).length()
			if d4 < 3.5:
				px(im, x9, y9, Color("e8c890") if posmod(int(d4 * 1.6), 2) == 0 else Color("c8a070"))
	outline_auto(im, 0.4)
	save3(im, "log_drop", false)
	# ---------------------------------------------------------------- значки 24x24
	im = new_img(24, 24)
	for k13 in range(2):
		var ly: float = 10.0 + float(k13) * 7.0
		capsule(im, Vector2(4, ly), Vector2(18, ly - 3.0), 3.4, 3.2, bark, 4)
		for y10 in range(int(ly) - 7, int(ly) + 4):
			for x10 in range(15, 24):
				var d5: float = Vector2(float(x10) + 0.5 - 18.5, float(y10) + 0.5 - (ly - 3.0)).length()
				if d5 < 3.3:
					px(im, x10, y10, Color("e8c890") if posmod(int(d5 * 1.8), 2) == 0 else Color("c8a070"))
	outline_auto(im, 0.45)
	save3(im, "icon_log", false)
	im = new_img(24, 24)
	for k14 in range(18):
		var p2: Vector2 = Vector2(5, 21).lerp(Vector2(16, 4), float(k14) / 17.0)
		px(im, int(p2.x), int(p2.y), w7[5])
		px(im, int(p2.x) + 1, int(p2.y), w7[3])
		px(im, int(p2.x) + 1, int(p2.y) + 1, w7[2])
	var iron: Array = [Color("30303a"), Color("464652"), Color("6e6e7c"), Color("9a9aa6"), Color("c8c8d0"), Color("eeeef4")]
	for y11 in range(2, 12):
		for x11 in range(12, 23):
			var u3: float = float(x11 - 12) / 10.0
			var v3: float = float(y11 - 2) / 9.0
			if u3 > 0.35 + absf(v3 - 0.5) * 0.9 and u3 < 0.95 - absf(v3 - 0.5) * 0.4:
				continue
			if u3 > 0.95 - absf(v3 - 0.5) * 0.4 or (u3 < 0.35 and absf(v3 - 0.5) > 0.4):
				continue
			var ti2: int = 3 if v3 < 0.45 else 2
			if u3 > 0.75:
				ti2 = 5 if v3 < 0.5 else 4
			px(im, x11, y11, iron[ti2])
	outline_auto(im, 0.45)
	save3(im, "icon_axe", false)
	# саженцы: значок (в мешковине) и три стадии в земле — для каждой породы
	var gen_icon: Image = null
	for tex in SAP_LOOK.keys():
		var look: Array = SAP_LOOK[tex]
		im = new_img(24, 24)
		var bu: Array = hx(BURLAP7)
		for y12 in range(14, 23):
			for x12 in range(5, 19):
				var dd: Vector2 = Vector2((float(x12) + 0.5 - 12.0) / 7.0, (float(y12) + 0.5 - 18.5) / 4.6)
				if dd.length() > 1.0:
					continue
				var ti3: int = 4 if dd.x < -0.2 else (3 if dd.x < 0.4 else 2)
				if posmod(x12 + y12, 3) == 0:
					ti3 -= 1
				px(im, x12, y12, bu[ti3])
		line(im, 6, 16, 18, 16, Color("b04030"))
		sapling13(im, 12.0, 15.0, 1, look, 3)
		outline_auto(im, 0.45)
		save3(im, "icon_sapling_" + String(tex), false)
		if tex == "tree_a":
			gen_icon = im
		for stg in range(3):
			im = new_img(40, 52)
			ell(im, 20, 48, 12, 3, Color(0.08, 0.06, 0.1, 0.25))
			soil_mound13(im, 20, 46, 7.0 + float(stg) * 2.0, 3.0)
			sapling13(im, 20.0, 46.0, stg, look, 5)
			outline_auto(im, 0.4)
			save3(im, "sapling_%s_%d" % [String(tex), stg], false)
			if tex == "tree_blossom" or tex == "pine_a" or tex == "tree_birch":
				items.append(["sapling_%s_%d" % [String(tex), stg], im])
	if gen_icon != null:
		gen_icon.save_png(OUT + "icon_sapling.png")
	# ---------------------------------------------------------------- ячейки сумки (9-сегментные) и рюкзак
	for sel in [false, true]:
		im = new_img(24, 24)
		var fr: Array = hx(["3a2418", "54361e", "6e4a2a", "8a6038", "a67a4a"]) if not sel else hx(["6a4a0a", "9a6e14", "c8961e", "e8bc3a", "f8dc70"])
		for y13 in range(24):
			for x13 in range(24):
				var edge: int = mini(mini(x13, y13), mini(23 - x13, 23 - y13))
				var c3: Color
				if edge == 0:
					c3 = fr[0]
				elif edge == 1:
					c3 = fr[3] if (x13 < 12 and y13 < 12) or y13 == 1 or x13 == 1 else fr[2]
				elif edge == 2:
					c3 = fr[1]
				else:
					c3 = Color("ecdcb8") if not sel else Color("f8e8b8")
					if edge == 3:
						c3 = c3.darkened(0.12)
				if (x13 == 0 or x13 == 23) and (y13 == 0 or y13 == 23):
					c3 = Color(0, 0, 0, 0)
				im.set_pixel(x13, y13, c3)
		save3(im, "ui_slot_sel" if sel else "ui_slot", false)
	im = new_img(24, 24)
	var pack: Array = hx(["4a2e1a", "6a4226", "8a5a32", "a87444", "c49060", "dcae80", "f0d0a8"])
	blob(im, 12, 14, 8, 8.5, pack, 4)
	box3(im, 6, 15, 12, 6, 2, pack, 3)
	line(im, 9, 5, 9, 9, pack[2])
	line(im, 15, 5, 15, 9, pack[2])
	line(im, 9, 5, 15, 5, pack[2])
	rect(im, 11, 16, 3, 2, Color("e8c860"))
	outline_auto(im, 0.45)
	save3(im, "icon_pack", false)
	_sheet(items, 3, "v13_home.png")


# ================================================================== v19: болото — та же техника, что у деревьев
# Ива плакучая, болотный кипарис с бородатым мхом, заросшие окна воды с кувшинками, рогоз, кочки, упавшее бревно.
# Кора — draw_trunk3, листва — leaf_canopy (тёмная подложка + сотни листиков с тоном по свету),
# травинки у корней, clean_specks, outline_auto, мягкая тень — как у tree_a..tree_d.

const L7_WILLOW: Array = ["1c3a2c", "28503a", "386a42", "4e864a", "6aa452", "92c260", "c4e284"]
const L7_CYPRESS: Array = ["13262a", "1a3a36", "245040", "30684a", "448254", "62a062", "92c47e"]
const MOSS7: Array = ["2e3a2e", "44543e", "5c6e4e", "76885e", "92a072", "aeb98a", "ccd4a8"]
const BOG7: Array = ["0f1f1c", "142a24", "1c362c", "264436", "325444", "406652", "557a66", "6e9480", "98bca8"]
const MUD7: Array = ["241a14", "34261c", "463424", "5a442e", "6e563a", "86704e", "a08c68"]


func gen_swamp19() -> void:
	gen_willow19("willow_a", 1901, 176, 196, 0)
	gen_willow19("willow_b", 1907, 150, 176, 1)
	gen_cypress19("swamp_cypress", 1913, 140, 200)
	gen_bog_pool19("bog_pool_a", 1921, 196, 86)
	gen_bog_pool19("bog_pool_b", 1927, 128, 62)
	gen_cattails19("cattails", 1931)
	gen_bog_mound19("bog_mound", 1937)
	gen_bog_log19("bog_log", 1941)
	gen_swamp_bush19("swamp_bush", 1949)


## Ива: невысокий толстый ствол, купол кроны и длинные свисающие пряди до самой земли
func gen_willow19(name: String, seed_v: int, w: int, h: int, variant: int) -> void:
	rng.seed = seed_v
	var im: Image = new_img(w, h)
	var ramp: Array = hx(L7_WILLOW)
	var cx: float = w / 2.0 + (4.0 if variant == 1 else -2.0)
	var base: int = h - 8
	var R: float = w * 0.36
	var ccy: float = h * 0.30
	var t0: int = int(ccy + R * 0.25)
	# пряди сзади (по краям купола)
	var back: Array = []
	var front: Array = []
	var nstr: int = 26 if variant == 0 else 21
	for j in range(nstr):
		var u: float = (float(j) + rng.randf_range(0.1, 0.9)) / float(nstr) * 2.0 - 1.0
		var sx: float = cx + u * R * 1.12
		var top_y: float = ccy + R * (0.1 + 0.4 * absf(u)) + rng.randf_range(-6, 4)
		var bot_y: float = float(base) - rng.randf_range(6.0, 44.0) - (22.0 if absf(u) < 0.3 else 0.0)
		var y: float = top_y
		var k: int = 0
		var n_seg: float = maxf(1.0, (bot_y - top_y) / 7.0)
		var col: Array = back if (absf(u) > 0.6 or j % 3 != 0) else front
		var ph2: float = rng.randf() * TAU
		while y < bot_y:
			var tk: float = float(k) / n_seg
			var sway: float = sin(y * 0.05 + ph2) * 2.5 + u * tk * 6.0
			col.append(Vector4(sx + sway, y, lerpf(3.2, 1.6, tk), 6.0))
			y += 7.0
			k += 1
	back.sort_custom(func(p: Vector4, q: Vector4) -> bool: return p.y < q.y)
	leaf_canopy(im, back, ramp, seed_v + 1, 6.4, 1.9, 2.1, 3.6)
	# ствол — чуть наклонён, развилка на две ветви
	draw_trunk3(im, cx, t0, base, 7.0, seed_v)
	branch(im, Vector2(cx - 2, t0 + 8), Vector2(cx - R * 0.55, ccy + R * 0.05), 8.0, 3.0)
	branch(im, Vector2(cx + 2, t0 + 6), Vector2(cx + R * 0.5, ccy - R * 0.05), 7.0, 3.0)
	branch(im, Vector2(cx, t0 + 4), Vector2(cx + 3, ccy - R * 0.4), 7.0, 2.5)
	# купол
	var dome: Array = tree_clumps(cx, ccy, R)
	var under: Callable = func() -> void:
		for y2 in range(int(ccy + R * 0.1), t0 + 8):
			for x2 in range(int(cx - 5), int(cx + 6)):
				px(im, x2, y2, BARK7[2] if x2 < cx + 1 else BARK7[1])
	leaf_canopy(im, dome, ramp, seed_v, 6.4, 3.4, 2.9, 1.6, under)
	# пряди спереди: сквозь них видно ствол
	front.sort_custom(func(p: Vector4, q: Vector4) -> bool: return p.y < q.y)
	leaf_canopy(im, front, ramp, seed_v + 2, 6.6, 1.9, 2.2, 3.8)
	# серёжки — светлые штрихи на прядях
	for i in range(40):
		var fx: int = int(cx + rng.randf_range(-R * 1.1, R * 1.1))
		var fy: int = int(rng.randf_range(ccy, float(base) - 20.0))
		if a_at(im, fx, fy) > 0.5 and a_at(im, fx, fy + 2) > 0.5 and im.get_pixel(fx, fy).get_luminance() > Color(ramp[3]).get_luminance():
			px(im, fx, fy, Color(ramp[6]))
			px(im, fx, fy + 1, Color(ramp[5]))
	# у корней — осока и мох
	grass_blades(im, cx, base + 1, 22.0, 34, hx(L7_WILLOW))
	clean_specks(im)
	outline_auto(im, 0.5)
	shadow(im, cx + 2.0, base + 2.0, w * 0.38, 5.0, 0.18)
	save3(im, name)


## Болотный кипарис: ствол с широкими «юбками» корней, плоские ярусы хвои и бородатый мох
func gen_cypress19(name: String, seed_v: int, w: int, h: int) -> void:
	rng.seed = seed_v
	var im: Image = new_img(w, h)
	var cx: float = w / 2.0
	var base: int = h - 8
	var t0: int = 30
	# расширенное основание (контрфорсы)
	for y in range(base - 26, base + 1):
		var t: float = float(y - (base - 26)) / 26.0
		var hw: float = 6.0 + pow(t, 2.2) * 16.0
		for x in range(int(cx - hw), int(cx + hw) + 1):
			var u: float = (x + 0.5 - (cx - hw)) / (2.0 * hw)
			var ti: int = 5 if u < 0.2 else (4 if u < 0.45 else (3 if u < 0.72 else (2 if u < 0.9 else 1)))
			if absf(sin((x - cx) * 0.7)) > 0.93:
				ti -= 2
			px(im, x, y, BARK7[clampi(ti, 0, 6)])
	draw_trunk3(im, cx, t0, base - 22, 5.0, seed_v)
	# ярусы-ветви
	var tiers: Array = []
	for k in range(5):
		var ty: float = 26.0 + float(k) * 22.0
		var ww: float = 18.0 + float(k) * 7.0
		var side: float = -1.0 if k % 2 == 0 else 1.0
		branch(im, Vector2(cx, ty + 10.0), Vector2(cx + side * ww * 0.9, ty + 4.0), 3.0, 1.5)
		tiers.append(Vector4(cx + side * ww * 0.5, ty, ww * 0.62, 7.0))
		tiers.append(Vector4(cx - side * ww * 0.3, ty + 6.0, ww * 0.45, 6.0))
	tiers.sort_custom(func(p: Vector4, q: Vector4) -> bool: return p.y < q.y)
	leaf_canopy(im, tiers, hx(L7_CYPRESS), seed_v, 6.0, 2.6, 2.5, 1.0)
	# бородатый мох свисает с ветвей
	var moss: Array = hx(MOSS7)
	for i in range(26):
		var mx: int = int(cx + rng.randf_range(-w * 0.42, w * 0.42))
		var my: int = int(rng.randf_range(30.0, float(base) - 60.0))
		if a_at(im, mx, my) < 0.5:
			continue
		var ln: int = rng.randi_range(8, 22)
		for k2 in range(ln):
			var xx: int = mx + int(sin(float(k2) * 0.5 + float(i)) * 1.2)
			var ti2: int = 5 if k2 < 3 else (4 if k2 < ln - 4 else 3)
			px(im, xx, my + k2, moss[ti2])
			if k2 % 3 == 0 and k2 > 2:
				px(im, xx + 1, my + k2, moss[ti2 - 1])
	grass_blades(im, cx, base + 1, 26.0, 30, hx(L7_WILLOW))
	clean_specks(im)
	outline_auto(im, 0.5)
	shadow(im, cx + 2.0, base + 2.0, w * 0.34, 5.0, 0.18)
	save3(im, name)


## Окно болотной воды: неровный берег из ила и мха, глубина темнее к середине, отблески неба,
## ряска, кувшинки (листья с вырезом) и белые/розовые цветы
func gen_bog_pool19(name: String, seed_v: int, w: int, h: int) -> void:
	rng.seed = seed_v
	var im: Image = new_img(w, h)
	var c: Vector2 = Vector2(w / 2.0, h / 2.0 + 2.0)
	var rx: float = w * 0.41
	var ry: float = h * 0.36
	var water: Array = hx(BOG7)
	var mud: Array = hx(MUD7)
	var moss: Array = hx(MOSS7)
	var ph: Array = [rng.randf() * TAU, rng.randf() * TAU, rng.randf() * TAU]
	for y in range(h):
		for x in range(w):
			var q: Vector2 = Vector2((x + 0.5 - c.x) / rx, (y + 0.5 - c.y) / ry)
			var a: float = atan2(q.y, q.x)
			var edge: float = 1.0 + 0.09 * sin(a * 3.0 + ph[0]) + 0.05 * sin(a * 7.0 + ph[1]) + 0.03 * sin(a * 13.0 + ph[2])
			var d: float = q.length() / edge
			if d > 1.08:
				continue
			if d > 1.0:
				# илистый берег, сверху — мох
				var ti: int = 4 if q.y < 0.0 else 2
				if h01(x / 2, y, seed_v) > 0.7:
					ti += 1
				px(im, x, y, mud[clampi(ti, 0, 6)] if q.y > -0.3 else moss[clampi(ti, 0, 6)])
				continue
			# вода: глубже — темнее; верхний край — тень берега; полосы отблеска
			var v: float = 0.62 - (1.0 - d) * 0.42
			if q.y < -0.55 and d > 0.75:
				v -= 0.18
			var rip: float = sin((y + sin(x * 0.18) * 1.5) * 1.1)
			if rip > 0.93 and h01(x / 6, y, seed_v + 1) > 0.45:
				v += 0.22
			px(im, x, y, pick(water, v, x, y))
	# отблески неба
	for k in range(5):
		var sx: float = c.x + rng.randf_range(-rx * 0.6, rx * 0.5)
		var sy: float = c.y + rng.randf_range(-ry * 0.4, ry * 0.4)
		var ln: int = rng.randi_range(6, 14)
		for i in range(ln):
			if a_at(im, int(sx) + i, int(sy)) > 0.5:
				px(im, int(sx) + i, int(sy), water[8] if i % 4 != 0 else water[7])
	# ряска
	for k2 in range(int(w * 0.6)):
		var dx: int = int(c.x + rng.randf_range(-rx, rx))
		var dy: int = int(c.y + rng.randf_range(-ry, ry))
		var cc: Color = im.get_pixel(clampi(dx, 0, w - 1), clampi(dy, 0, h - 1))
		if cc.a > 0.5 and cc.g > cc.r and cc.get_luminance() < 0.45:
			px(im, dx, dy, Color("6a9a3e") if k2 % 3 else Color("8ab84e"))
	# кувшинки
	var pads: int = int(w / 26.0) + 2
	for k3 in range(pads):
		var lp: Vector2 = Vector2(c.x + rng.randf_range(-rx * 0.75, rx * 0.75), c.y + rng.randf_range(-ry * 0.55, ry * 0.6))
		var pr: float = rng.randf_range(4.0, 7.0)
		var cut: float = rng.randf() * TAU
		for y2 in range(int(lp.y - pr * 0.6) - 1, int(lp.y + pr * 0.6) + 2):
			for x2 in range(int(lp.x - pr) - 1, int(lp.x + pr) + 2):
				var qq: Vector2 = Vector2((x2 + 0.5 - lp.x) / pr, (y2 + 0.5 - lp.y) / (pr * 0.6))
				if qq.length() > 1.0:
					continue
				if absf(wrapf(atan2(qq.y, qq.x) - cut, -PI, PI)) < 0.32 and qq.length() > 0.15:
					continue
				var ti3: int = 4 if qq.y < -0.1 else 3
				if qq.length() > 0.8:
					ti3 = 2 if qq.y > 0.0 else 5
				if absf(qq.x) < 0.08:
					ti3 -= 1
				px(im, x2, y2, L7_GREEN[clampi(ti3, 0, 6)])
		if k3 % 2 == 0:
			var fs: Array = hx(["e0c8d8", "f8eef4", "ffffff"]) if k3 % 4 == 0 else hx(["c86a98", "f0a0c4", "fcd8e8"])
			flower5(im, int(lp.x) + 1, int(lp.y) - 1, fs, Color("f6d050"))
	clean_specks(im)
	outline_auto(im, 0.3)
	save3(im, name)


## Рогоз: длинные листья-ленты и бархатные коричневые початки
func gen_cattails19(name: String, seed_v: int) -> void:
	rng.seed = seed_v
	var im: Image = new_img(46, 64)
	var g: Array = hx(L7_WILLOW)
	var base: int = 62
	# листья-ленты
	for k in range(14):
		var x0: float = 8.0 + rng.randf_range(0, 30)
		var hgt: float = rng.randf_range(26, 50)
		var lean: float = rng.randf_range(-0.45, 0.45)
		for i in range(int(hgt)):
			var t: float = float(i) / hgt
			var x: int = int(x0 + lean * float(i) + lean * t * t * 10.0)
			var ti: int = 2 if t < 0.2 else (4 if t < 0.8 else 5)
			if lean > 0.15:
				ti -= 1
			px(im, x, base - i, g[clampi(ti, 0, 6)])
			if t < 0.6:
				px(im, x + 1, base - i, g[clampi(ti - 1, 0, 6)])
	# стебли и початки
	for k2 in range(6):
		var sx: int = 10 + k2 * 5 + rng.randi_range(-1, 1)
		var top: int = rng.randi_range(4, 18)
		for y in range(top, base):
			px(im, sx, y, g[3] if y % 5 else g[4])
		for y2 in range(top + 2, top + 12):
			var tt: int = 3 if y2 < top + 4 else 2
			px(im, sx - 1, y2, hx(["3a2414", "56341c", "744826", "92603a", "b07c50"])[tt + 1])
			px(im, sx, y2, hx(["3a2414", "56341c", "744826", "92603a", "b07c50"])[tt])
			px(im, sx + 1, y2, hx(["3a2414", "56341c", "744826", "92603a", "b07c50"])[tt - 1])
		px(im, sx, top, g[5])
		px(im, sx, top + 1, g[4])
	clean_specks(im)
	outline_auto(im, 0.4)
	shadow(im, 24, 63, 16, 2.5, 0.16)
	save3(im, name)


## Кочка: мшистый бугор, осока и клюква
func gen_bog_mound19(name: String, seed_v: int) -> void:
	rng.seed = seed_v
	var im: Image = new_img(52, 36)
	var moss: Array = hx(MOSS7)
	ball(im, 26, 25, 21, 9, moss, 0.1, 0.25, seed_v)
	ball(im, 19, 21, 11, 7, hx(L7_WILLOW), 0.05, 0.3, seed_v + 1)
	ball(im, 33, 22, 10, 6, moss, 0.0, 0.3, seed_v + 2)
	for k in range(18):
		var x: int = rng.randi_range(8, 44)
		var hgt: int = rng.randi_range(4, 11)
		var lean: float = rng.randf_range(-0.6, 0.6)
		for i in range(hgt):
			px(im, int(x + lean * i), 20 - i, hx(L7_WILLOW)[clampi(3 + (i * 3) / hgt, 0, 6)])
	for k2 in range(7):
		var bx: int = rng.randi_range(10, 42)
		var by: int = rng.randi_range(20, 30)
		if a_at(im, bx, by) > 0.5:
			px(im, bx, by, Color("b82a2a"))
			px(im, bx + 1, by, Color("8a1a1e"))
			px(im, bx, by - 1, Color("f07070"))
	clean_specks(im)
	outline_auto(im, 0.45)
	shadow(im, 27, 33, 20, 3.0, 0.16)
	save3(im, name)


## Упавшее бревно: кора полосами, годовые кольца на торце, мох сверху, грибочки
func gen_bog_log19(name: String, seed_v: int) -> void:
	rng.seed = seed_v
	var im: Image = new_img(100, 38)
	var y0: int = 12
	var y1: int = 30
	for y in range(y0, y1):
		var t: float = float(y - y0) / float(y1 - y0)
		var ti: int = 5 if t < 0.18 else (4 if t < 0.42 else (3 if t < 0.7 else 2))
		for x in range(10, 92):
			var tt: int = ti
			if absf(sin(y * 1.25 + sin(x * 0.13) * 1.6)) > 0.92:
				tt -= 2
			elif h01(x, y / 2, seed_v) > 0.86:
				tt -= 1
			px(im, x, y, BARK7[clampi(tt, 0, 6)])
	# торец с кольцами
	var ec: Vector2 = Vector2(92, (y0 + y1) / 2.0)
	for y2 in range(y0, y1 + 1):
		for x2 in range(86, 100):
			var q: Vector2 = Vector2((x2 + 0.5 - ec.x) / 6.0, (y2 + 0.5 - ec.y) / 9.5)
			var d: float = q.length()
			if d <= 1.0:
				var ring: int = int(d * 5.0)
				px(im, x2, y2, hx(["7a5a3a", "a8804e", "c49a62", "dcb67e", "eed29c"])[clampi(4 - ring + (ring % 2), 0, 4)])
	# мох сверху и грибы
	var moss: Array = hx(MOSS7)
	for x3 in range(12, 88):
		var mh: int = int(2.0 + 2.0 * sin(x3 * 0.21) + h01(x3, 1, seed_v) * 2.0)
		for k in range(mh):
			px(im, x3, y0 + k, moss[clampi(5 - k, 0, 6)])
		if h01(x3, 7, seed_v) > 0.88:
			px(im, x3, y0 - 1, moss[6])
	for mp in [Vector2(30, 11), Vector2(36, 10), Vector2(62, 11)]:
		var mv: Vector2 = mp
		ell(im, mv.x, mv.y - 2, 3, 1.6, Color("c8803a"))
		ell(im, mv.x - 0.5, mv.y - 2.5, 1.8, 0.8, Color("eab060"))
		line(im, int(mv.x), int(mv.y) - 1, int(mv.x), int(mv.y) + 1, Color("e8dcc0"))
	clean_specks(im)
	outline_auto(im, 0.45)
	shadow(im, 52, 34, 42, 3.0, 0.16)
	save3(im, name)


## Болотный кустарник (ольха): тёмная сизая листва
func gen_swamp_bush19(name: String, seed_v: int) -> void:
	rng.seed = seed_v
	var im: Image = new_img(64, 50)
	var cx: float = 32.0
	var cy: float = 28.0
	var R: float = 22.0
	var lay: Array = [[0.0, -0.42, 0.42, 0.38], [-0.46, -0.20, 0.40, 0.36], [0.46, -0.22, 0.40, 0.36], [-0.80, 0.14, 0.30, 0.30], [0.80, 0.12, 0.30, 0.30], [0.0, 0.0, 0.46, 0.38], [-0.38, 0.30, 0.40, 0.32], [0.38, 0.32, 0.40, 0.32]]
	var cl: Array = []
	for L0 in lay:
		var a: Array = L0
		cl.append(Vector4(cx + float(a[0]) * R + rng.randf_range(-1, 1), cy + float(a[1]) * R, float(a[2]) * R, float(a[3]) * R))
	cl.sort_custom(func(p: Vector4, q: Vector4) -> bool: return p.y < q.y)
	leaf_canopy(im, cl, hx(L7_CYPRESS), seed_v, 5.6, 3.6, 2.8, 0.6)
	# серёжки ольхи
	for k in range(9):
		var x: int = rng.randi_range(10, 54)
		var y: int = rng.randi_range(10, 38)
		if a_at(im, x, y) > 0.5 and a_at(im, x, y + 3) > 0.5:
			for i in range(4):
				px(im, x, y + i, Color("8a6a3a") if i % 2 else Color("b08a50"))
	clean_specks(im)
	outline_auto(im, 0.5)
	shadow(im, 33, 46, 25, 3.5, 0.16)
	save3(im, name)

# ================================================================== v24: демоницы (Ад) и ангелицы (Рай)
# Тело, лицо и одежда — как у всех девочек (draw_hero10, свои палитры, лица gen_faces10).
# Поверх: рога, острые ушки, хвост с сердечком-пикой и кожистые крылья (демоницы);
# нимб и белые крылья из перьев (ангелицы). Крылья рисуются на отдельной картинке и кладутся
# за спину (вид спереди/сбоку) или поверх спины (вид сзади).

const DEMON_LOOKS: Array = [
	# имя, волосы, платье, отделка, кожа ("" — обычная), глаза [I, i, j], рога, крылья (7)
	["demon_ruby", ["4a0a1a", "6e1226", "94203a", "b8344e", "d4526a", "e87e90", "f6b0bc"], ["1a1018", "261822", "34222e", "443040", "584054", "70566c", "8c7088"], ["6a0a10", "8e1218", "b41e22", "d0342c", "e45a44", "f08868", "f8b896"], "", ["5a2a04", "e0a020", "fff090"], "ram", ["2a0a14", "48121e", "6a1c2a", "8c2a38", "aa3e4a", "c85e66", "e48a8e"]],
	["demon_nyx", ["0e0a1a", "1a1430", "28204a", "3a2e66", "4e4284", "6a5ea4", "9488c8"], ["2a0a2a", "3e123e", "561c56", "702870", "8c3a8a", "a856a6", "c87ec4"], ["1a1a2a", "2a2a40", "3c3c58", "525272", "6c6c8e", "8a8aac", "b0b0cc"], "lavender", ["3a0a4a", "c040e0", "f0a0ff"], "long", ["120a1e", "1e1230", "2c1c46", "3e2a5e", "543c7a", "70549a", "9476ba"]],
	["demon_iskra", ["5a1a04", "8a2a08", "b8420c", "e06414", "f48a26", "fab44e", "fede8a"], ["2a0a0a", "401010", "5a1818", "762424", "943434", "b04c4c", "cc7070"], ["3a2a0a", "5a4210", "7e5c18", "a07a22", "c49c34", "e0c050", "f6e08a"], "red", ["5a3a04", "ffb020", "fff4a0"], "small", ["3a0a06", "5a120a", "7e1e10", "a02c18", "c04224", "dc6438", "f09058"]],
	["demon_lavi", ["2a1a3a", "3e2858", "56387a", "704c9a", "8e66b8", "ae88d2", "d0b0ea"], ["101018", "1a1a26", "262636", "343448", "46465e", "5c5c78", "787896"], ["5a0a3a", "7e1250", "a01e68", "c03282", "d8509c", "ea78b8", "f6a8d4"], "", ["4a0a2a", "e0307a", "ffa0c8"], "long", ["1a0a1a", "2c1230", "421c48", "5a2862", "763a80", "9450a0", "b472c0"]],
	["demon_kira", ["e0d8e0", "eae4ea", "f2eef2", "f8f6f8", "fcfbfc", "ffffff", "ffffff"], ["3a0a0a", "561212", "741c1c", "922828", "b03a3a", "c85656", "de7e7e"], ["1a1a1a", "2a2a2a", "3c3c3c", "525252", "6c6c6c", "8a8a8a", "b0b0b0"], "ash", ["5a0a0a", "ff3020", "ffb0a0"], "ram", ["1a1418", "2a2228", "3c3238", "50444c", "665a62", "807480", "9e94a0"]],
	["demon_mora", ["1a0410", "2e081c", "48102c", "661a40", "882858", "aa4074", "cc6698"], ["1a0a0a", "2c1010", "421818", "5c2222", "7a2e2e", "984242", "b86060"], ["5a3a04", "8a5a08", "b67a0e", "dc9c1e", "f4be3a", "fcda6a", "fff0aa"], "red", ["5a3a04", "ffc030", "fff8b0"], "queen", ["1e060c", "340a16", "4e1022", "6c1a30", "8c2840", "ae3e56", "d05e72"]],
]

const ANGEL_LOOKS: Array = [
	# имя, волосы, платье, отделка, глаза [I, i, j], перья (7), нимб
	["angel_lucia", ["8a6a24", "b08c34", "d0ae4a", "e6ca6a", "f4e092", "fcf0c0", "fffae6"], ["a8a0b8", "c4bed0", "dcd8e6", "eceaf2", "f6f5fa", "fcfcfe", "ffffff"], ["6a5010", "967418", "c09a24", "e0bc3a", "f2d462", "fae696", "fff4cc"], ["1a3a6a", "4a8ae0", "b0d8ff"], ["8a8aa8", "aeaec8", "cacade", "e0e0ee", "eeeef6", "f8f8fc", "ffffff"], "gold"],
	["angel_mel", ["b0a8b8", "c8c2d0", "dcd8e2", "ece8f0", "f6f4f8", "fcfbfd", "ffffff"], ["3a5a8a", "4e74a8", "6890c4", "88acd8", "aac8e8", "cce0f4", "eaf2fc"], ["8a8aa8", "aeaec8", "cacade", "e0e0ee", "eeeef6", "f8f8fc", "ffffff"], ["2a4a6a", "60a0d0", "c0e8ff"], ["8a90a8", "aab0c6", "c8ccde", "dee2ee", "ecf0f6", "f8fafc", "ffffff"], "silver"],
	["angel_nimbi", ["c87a8a", "dc96a4", "eab2bc", "f4cad2", "fadee4", "fdeef2", "fffafb"], ["a8a0b8", "c4bed0", "dcd8e6", "eceaf2", "f6f5fa", "fcfcfe", "ffffff"], ["c86a8a", "dc88a2", "eca8bc", "f6c6d4", "fadce6", "fdeef3", "ffffff"], ["5a2a4a", "d070a0", "ffc8e0"], ["a898b0", "c4b6ca", "dcd0e0", "eee6f0", "f6f2f8", "fcfafc", "ffffff"], "gold"],
	["angel_celi", ["5a7aa0", "7494b8", "92b0d0", "b0cae2", "cce0f0", "e4f0f8", "f8fcff"], ["8a7a5a", "a8987a", "c4b698", "dcd0b6", "ece4d2", "f6f2e8", "fffcf6"], ["3a6a8a", "4a86a8", "62a2c4", "82bcd8", "a6d4e8", "cce8f4", "eef8fc"], ["1a4a5a", "40b0c0", "b0f0f8"], ["8890a8", "a8b0c6", "c6ccde", "dce2ee", "ecf0f6", "f8fafc", "ffffff"], "gold"],
	["angel_aurora", ["a86a2a", "c8843a", "e0a04e", "eebc6a", "f6d48e", "fbe8b8", "fff6e4"], ["c8a8b8", "dcc0cc", "ead4dc", "f4e6ea", "faf2f4", "fdf9fa", "ffffff"], ["7a5a10", "a07a18", "c49c24", "e0bc3a", "f2d462", "fae696", "fff4cc"], ["4a3a0a", "e0a030", "ffe8a0"], ["a89880", "c4b6a0", "dcd0bc", "ece4d6", "f6f2ea", "fcfaf6", "ffffff"], "gold"],
	["angel_serafima", ["e0d0a0", "ecdeb4", "f4eac8", "faf2da", "fdf8ea", "fffcf4", "ffffff"], ["c8c0d0", "dcd6e4", "ebe8f0", "f5f3f8", "faf9fc", "fdfcfe", "ffffff"], ["8a6a10", "b48c18", "d8ae28", "f0cc44", "fae070", "fff0a8", "fffadc"], ["3a2a6a", "8a70e0", "e0d0ff"], ["9a96b0", "b8b4ca", "d2d0e0", "e6e4f0", "f2f2f8", "fafafc", "ffffff"], "queen"],
]

var HORN_STYLE: String = ""
var WING_RAMP: Array = []
var WING_KIND: String = ""         # "bat" / "feather"
var HALO: String = ""
var DEMON_TAIL: bool = false


## Точки, откуда растут рога / уши: середина основания кошачьего уха
func _head_spot(dir: int, b: int, which: int) -> Vector2:
	var e: Array = EAR_PTS[dir][which]
	return ((e[0] as Vector2) + (e[1] as Vector2)) / 2.0 + Vector2(0, b + 2)


## Рог: цепочка капсул по кривой, кольца-насечки, светлый кончик
func horn(im: Image, base: Vector2, pts: Array, r0: float, ramp: Array) -> void:
	var q: Array = [base]
	for p in pts:
		q.append(base + (p as Vector2))
	var n: int = q.size()
	for i in range(n - 1):
		var t0: float = float(i) / float(n - 1)
		var t1: float = float(i + 1) / float(n - 1)
		capsule(im, q[i], q[i + 1], lerpf(r0, 0.6, t0), lerpf(r0, 0.6, t1), ramp, 3 if i < n - 2 else 4)
	# насечки
	for i2 in range(1, n - 1):
		var a: Vector2 = q[i2]
		var tg: Vector2 = ((q[i2 + 1] as Vector2) - (q[i2 - 1] as Vector2)).normalized()
		var nr: Vector2 = Vector2(-tg.y, tg.x)
		var rr: float = lerpf(r0, 0.6, float(i2) / float(n - 1)) - 0.3
		for k in range(-int(rr), int(rr) + 1):
			px(im, int(a.x + nr.x * k), int(a.y + nr.y * k), ramp[1])
	var tip: Vector2 = q[n - 1]
	px(im, int(tip.x), int(tip.y), ramp[6])


func demon_horns(im: Image, dir: int, f: int) -> void:
	var b: int = -1 if (f == 1 or f == 3 or f == 6 or f == 7) else 0
	var ramp: Array = hx(["140c10", "241a1e", "382c30", "4e4044", "6a5a5c", "8c7a78", "b8a49c"])
	if HORN_STYLE == "queen":
		ramp = hx(["1a0a06", "301408", "4a200c", "6a3010", "8c4618", "b06428", "e09a50"])
	var ears: Array = EAR_PTS[dir]
	for wi in range(ears.size()):
		var base: Vector2 = _head_spot(dir, b, wi)
		var side: float = -1.0 if base.x < 40.0 else 1.0
		if dir == 2:
			side = 1.0     # смотрит влево — рога назад (вправо)
		var pts: Array
		match HORN_STYLE:
			"ram":
				pts = [Vector2(side * 3, -3), Vector2(side * 6, -2), Vector2(side * 7, 1), Vector2(side * 5, 4), Vector2(side * 3, 3)]
			"long":
				pts = [Vector2(side * 2, -3), Vector2(side * 4, -6), Vector2(side * 6.5, -8), Vector2(side * 9, -8.5)]
			"small":
				pts = [Vector2(side * 1, -3), Vector2(side * 2, -5.5)]
			_:
				pts = [Vector2(side * 2, -4), Vector2(side * 3, -8), Vector2(side * 5, -11), Vector2(side * 8, -13), Vector2(side * 11, -12)]
		horn(im, base, pts, 2.2 if HORN_STYLE != "small" else 1.8, ramp)


## Острые ушки у демониц (как у эльфов, торчат из-под волос)
func demon_ears(im: Image, dir: int, f: int) -> void:
	var b: int = -1 if (f == 1 or f == 3 or f == 6 or f == 7) else 0
	var ears: Dictionary = {
		0: [[Vector2(28, 25), -1], [Vector2(52, 25), 1]], 1: [[Vector2(27, 25), -1], [Vector2(53, 25), 1]],
		2: [[Vector2(45, 25), 1]], 4: [[Vector2(26, 26), -1], [Vector2(49, 24), 1]], 5: [[Vector2(28, 25), -1], [Vector2(54, 24), 1]],
	}
	for e in ears[dir]:
		elf_ear(im, (e[0] as Vector2) + Vector2(0, b), int(e[1]), 5, 5)


## Тонкий хвост демоницы с пикой-сердечком на кончике
func demon_tail(im: Image, dir: int, f: int, sway: float) -> void:
	var b: int = -1 if (f == 1 or f == 3 or f == 6 or f == 7) else 0
	var pts: Array = []
	var src: Array = TAIL_PTS[dir]
	for i in range(src.size()):
		var t: float = float(i) / float(src.size() - 1)
		pts.append((src[i] as Vector2) + Vector2(sway * t * t, -absf(sway) * 0.2 * t + b + (3.0 if i > 2 else 0.0)))
	var ramp: Array = SKINL7 if SKINL7.size() == 7 else hx(["3a0a10", "5a1218", "7e1e22", "a02c2c", "c04238", "dc6450", "f09070"])
	var tr: Array = hx(["2a0a10", "44121a", "621c24", "822830", "a03a3e", "bc5450", "d87868"])
	for i2 in range(pts.size() - 1):
		capsule(im, pts[i2], pts[i2 + 1], 1.5, 1.2, tr, 3)
	# пика-сердечко
	var tip: Vector2 = pts[pts.size() - 1]
	var dv: Vector2 = (tip - (pts[pts.size() - 2] as Vector2)).normalized()
	var nr: Vector2 = Vector2(-dv.y, dv.x)
	var a: Vector2 = tip + dv * 5.0
	tri(im, tip - nr * 3.2 - dv * 0.5, tip + nr * 3.2 - dv * 0.5, a, func(_x: int, y: int, u: float) -> Color: return tr[4] if u < 0.45 else tr[2])
	blob(im, tip.x - nr.x * 1.6, tip.y - nr.y * 1.6, 1.6, 1.6, tr, 4)
	blob(im, tip.x + nr.x * 1.6, tip.y + nr.y * 1.6, 1.6, 1.6, tr, 3)


## Кожистое крыло: пальцы-кости от корня, перепонка с вырезами по краю
func bat_wing(w: Image, root: Vector2, side: float, span: float, lift: float, ramp: Array) -> void:
	var elbow: Vector2 = root + Vector2(side * span * 0.38, -span * 0.62 + lift)
	var tips: Array = [
		root + Vector2(side * span * 0.62, -span * 0.98 + lift),
		root + Vector2(side * span * 1.0, -span * 0.62 + lift * 0.8),
		root + Vector2(side * span * 0.98, -span * 0.12 + lift * 0.5),
		root + Vector2(side * span * 0.62, span * 0.24 + lift * 0.2),
	]
	# перепонка: треугольники от корня и от локтя к соседним пальцам
	var poly: Array = [root, elbow] + tips
	for i in range(tips.size() - 1):
		var ta: Vector2 = tips[i]
		var tb2: Vector2 = tips[i + 1]
		tri(w, elbow, ta, tb2, func(x: int, y: int, _u: float) -> Color:
			var dd: float = Vector2(x, y).distance_to(elbow) / span
			return ramp[clampi(4 - int(dd * 3.0) + (1 if i == 0 else 0), 1, 5)])
		tri(w, root, elbow, tb2, func(x: int, y: int, _u: float) -> Color:
			var dd2: float = Vector2(x, y).distance_to(root) / span
			return ramp[clampi(3 - int(dd2 * 2.0), 1, 5)])
	tri(w, root, tips[tips.size() - 1], tips[tips.size() - 2], func(_x: int, _y: int, _u: float) -> Color: return ramp[2])
	# вырезы между пальцами (дуги внутрь)
	for i2 in range(tips.size() - 1):
		var m: Vector2 = ((tips[i2] as Vector2) + (tips[i2 + 1] as Vector2)) / 2.0
		var inward: Vector2 = (elbow - m).normalized()
		var rr: float = (tips[i2] as Vector2).distance_to(tips[i2 + 1]) * 0.42
		var c: Vector2 = m - inward * rr * 0.55
		for y in range(int(c.y - rr) - 1, int(c.y + rr) + 2):
			for x in range(int(c.x - rr) - 1, int(c.x + rr) + 2):
				if Vector2(x + 0.5, y + 0.5).distance_to(c) < rr and x >= 0 and y >= 0 and x < w.get_width() and y < w.get_height():
					w.set_pixel(x, y, Color(0, 0, 0, 0))
	# кости-пальцы
	thick_line(w, root, elbow, 1.6, ramp, 0.25)
	for tp in tips:
		line(w, int(elbow.x), int(elbow.y), int((tp as Vector2).x), int((tp as Vector2).y), ramp[0])
	px(w, int(elbow.x), int(elbow.y) - 1, ramp[5])
	# коготок на локте
	px(w, int(elbow.x), int(elbow.y) - 2, Color("e8e0d0"))


## Крыло из перьев: плечевая дуга, ряды кроющих перьев, длинные маховые внизу и по краю
func feather_wing(w: Image, root: Vector2, side: float, span: float, lift: float, ramp: Array) -> void:
	var wrist: Vector2 = root + Vector2(side * span * 0.55, -span * 0.75 + lift)
	var tipp: Vector2 = root + Vector2(side * span * 1.02, -span * 0.35 + lift * 0.7)
	# маховые перья: от дуги плеча вниз-наружу, длиннее к краю
	var n: int = 9
	for k in range(n):
		var t: float = float(k) / float(n - 1)
		var a: Vector2 = root.lerp(wrist, minf(1.0, t * 1.4)) if t < 0.72 else wrist.lerp(tipp, (t - 0.72) / 0.28)
		var L: float = lerpf(span * 0.55, span * 0.95, t)
		var ang: Vector2 = Vector2(side * lerpf(0.15, 0.85, t), lerpf(1.0, 0.45, t)).normalized()
		var e: Vector2 = a + ang * L
		capsule(w, a, e, 2.4, 1.1, ramp, 3 if k % 2 == 0 else 4)
		# стержень пера
		line(w, int(a.x), int(a.y), int(lerpf(a.x, e.x, 0.8)), int(lerpf(a.y, e.y, 0.8)), ramp[2])
	# средние (второстепенные) перья
	for k2 in range(7):
		var t2: float = float(k2) / 6.0
		var a2: Vector2 = root.lerp(wrist, t2) + Vector2(0, 2)
		var e2: Vector2 = a2 + Vector2(side * lerpf(1.0, 4.0, t2), lerpf(span * 0.32, span * 0.42, t2))
		capsule(w, a2, e2, 2.6, 1.4, ramp, 5 if k2 % 2 == 0 else 4)
	# кроющие: чешуйки вдоль дуги
	for k3 in range(10):
		var t3: float = float(k3) / 9.0
		var a3: Vector2 = root.lerp(wrist, t3)
		blob(w, a3.x + side * 0.5, a3.y + 2.5, 2.6, 2.0, ramp, 5)
		blob(w, a3.x + side * 1.0, a3.y + 6.0, 2.4, 1.8, ramp, 4)
	# плечевая дуга сверху — самая светлая
	thick_line(w, root, wrist, 2.6, ramp, 0.85)
	thick_line(w, wrist, tipp, 1.8, ramp, 0.75)


## Крылья за спиной / на спине. on_top — рисовать поверх тела (вид сзади)
func wings24(im: Image, dir: int, f: int, on_top: bool) -> void:
	var b: int = -1 if (f == 1 or f == 3 or f == 6 or f == 7) else 0
	var back_view: bool = dir == 1 or dir == 5
	if back_view != on_top:
		return
	# лёгкий взмах: стойка — медленно, шаг — в такт
	var lift: float = [0.0, -1.0, 0.0, 1.0, 0.0, -1.0, -2.0, -1.0][f % 8]
	var w: Image = new_img(im.get_width(), im.get_height())
	var span: float = 21.0 if WING_KIND == "feather" else 23.0
	var roots: Array = []
	match dir:
		0, 1:
			roots = [[Vector2(36, 47 + b), -1.0, 1.0], [Vector2(44, 47 + b), 1.0, 1.0]]
		2:
			roots = [[Vector2(46, 46 + b), 1.0, 0.82]]
		4:
			roots = [[Vector2(37, 47 + b), -1.0, 0.7], [Vector2(46, 46 + b), 1.0, 1.0]]
		5:
			roots = [[Vector2(36, 47 + b), -1.0, 0.95], [Vector2(46, 46 + b), 1.0, 0.75]]
	for r in roots:
		var ra: Array = r
		if WING_KIND == "feather":
			feather_wing(w, ra[0], float(ra[1]), span * float(ra[2]), lift, WING_RAMP)
		else:
			bat_wing(w, ra[0], float(ra[1]), span * float(ra[2]), lift, WING_RAMP)
	outline_auto(w, OUTLINE_CHAR)
	im.blend_rect(w, Rect2i(0, 0, w.get_width(), w.get_height()), Vector2i.ZERO)


## Нимб над головой: тонкое кольцо с бликом
func halo24(im: Image, dir: int, f: int) -> void:
	var b: int = -1 if (f == 1 or f == 3 or f == 6 or f == 7) else 0
	var bob: float = [0.0, 0.0, -1.0, -1.0, 0.0, -1.0, -1.0, 0.0][f % 8]
	var c: Vector2 = Vector2(40 if dir != 2 else 39, 3.0 + b + bob)
	var ramp: Array = hx(["8a6a10", "b48c18", "d8ae28", "f0cc44", "fae070", "fff0a8", "fffadc"])
	if HALO == "silver":
		ramp = hx(["6a7088", "8a92aa", "aab2c8", "c8d0e2", "e0e6f2", "f0f4fa", "ffffff"])
	var rx: float = 8.5 if HALO != "queen" else 10.0
	for y in range(int(c.y - 4), int(c.y + 4)):
		for x in range(int(c.x - rx - 2), int(c.x + rx + 2)):
			var nx: float = (x + 0.5 - c.x) / rx
			var ny: float = (y + 0.5 - c.y) / 2.4
			var d: float = sqrt(nx * nx + ny * ny)
			if d > 0.74 and d < 1.06 and y >= 0:
				var ti: int = 4 if ny < 0.0 else 3
				if nx < -0.3 and ny < 0.0:
					ti = 6
				px(im, x, y, ramp[ti])
	if HALO == "queen":
		# корона-лучики над нимбом
		for k in range(5):
			var xx: int = int(c.x) - 6 + k * 3
			px(im, xx, int(c.y) - 3, ramp[5])
			px(im, xx, int(c.y) - 4, ramp[6] if k == 2 else ramp[4])


func draw_demon(im: Image, dir: int, f: int) -> void:
	var walk: bool = f <= 3
	var sway: float = sin(float(f) * 1.57) * 2.6 if walk else [0.0, 1.2, 2.2, 1.2][clampi(f - 4, 0, 3)]
	var behind: bool = dir == 0 or dir == 2 or dir == 4
	wings24(im, dir, f, false)
	if behind:
		demon_tail(im, dir, f, sway)
	draw_hero10(im, dir, f)
	if not behind:
		demon_tail(im, dir, f, sway)
	wings24(im, dir, f, true)
	demon_ears(im, dir, f)
	demon_horns(im, dir, f)


func draw_angel(im: Image, dir: int, f: int) -> void:
	wings24(im, dir, f, false)
	draw_hero10(im, dir, f)
	wings24(im, dir, f, true)
	halo24(im, dir, f)


func gen_realm_girls() -> void:
	var sh: Array = HAIRL7.duplicate()
	var sw7: Array = WHITE7.duplicate()
	var st: Array = TEAL7.duplicate()
	var sk: Array = SKINL7.duplicate()
	var fw: int = 80
	var fh: int = 160
	var mirror: Dictionary = {2: 3, 4: 6, 5: 7}
	BOUNCE_OVR = 0
	NO_CAPE = true
	var all_looks: Array = []
	for d in DEMON_LOOKS:
		all_looks.append(["demon", d])
	for a in ANGEL_LOOKS:
		all_looks.append(["angel", a])
	var line_up: Image = new_img(fw * all_looks.size(), fh)
	var views: Image = new_img(fw * 8, fh * 2)
	var li: int = 0
	for e in all_looks:
		var kind: String = String(e[0])
		var lk: Array = e[1]
		HAIRL7 = hx(lk[1])
		WHITE7 = hx(lk[2])
		TEAL7 = hx(lk[3])
		if kind == "demon":
			match String(lk[4]):
				"red":
					SKINL7 = hx(["5a1418", "862428", "b03a38", "cc5a50", "e07e6c", "f0a690", "fad0bc"])
				"lavender":
					SKINL7 = hx(["4a3a6a", "6a5890", "8e7cb2", "aea0cc", "c8bee0", "e0d8f0", "f4f0fa"])
				"ash":
					SKINL7 = hx(["3a3c48", "585c6a", "7a7e8e", "9ca0ae", "bcc0cc", "d8dce4", "f0f2f6"])
				_:
					SKINL7 = sk
			var ey: Array = lk[5]
			EYE_OVR = {"I": Color(ey[0]), "i": Color(ey[1]), "j": Color(ey[2])}
			HORN_STYLE = String(lk[6])
			WING_KIND = "bat"
			WING_RAMP = hx(lk[7])
		else:
			SKINL7 = sk
			var ey2: Array = lk[4]
			EYE_OVR = {"I": Color(ey2[0]), "i": Color(ey2[1]), "j": Color(ey2[2])}
			WING_KIND = "feather"
			WING_RAMP = hx(lk[5])
			HALO = String(lk[6])
		_head_pal()
		var vs: Image = new_img(fw * 8, fh * 8)
		for vd in [0, 1, 2, 4, 5]:
			for k in range(8):
				var c2: Image = new_img(fw, fh)
				if kind == "demon":
					draw_demon(c2, vd, k)
				else:
					draw_angel(c2, vd, k)
				outline_auto(c2, OUTLINE_CHAR)
				vs.blit_rect(c2, Rect2i(0, 0, fw, fh), Vector2i(k * fw, vd * fh))
				if mirror.has(vd):
					var mc: Image = c2.duplicate()
					mc.flip_x()
					vs.blit_rect(mc, Rect2i(0, 0, fw, fh), Vector2i(k * fw, int(mirror[vd]) * fh))
		save3(vs, String(lk[0]))
		gen_faces10("faces_" + String(lk[0]))
		line_up.blit_rect(vs, Rect2i(4 * fw, 0, fw, fh), Vector2i(li * fw, 0))
		if li == 0 or li == DEMON_LOOKS.size():
			for d2 in range(8):
				views.blit_rect(vs, Rect2i(4 * fw, d2 * fh, fw, fh), Vector2i(d2 * fw, (0 if li == 0 else 1) * fh))
		li += 1
	line_up.resize(line_up.get_width() * 3, line_up.get_height() * 3, Image.INTERPOLATE_NEAREST)
	line_up.save_png(ProjectSettings.globalize_path("res://").path_join("../screenshots/realm_lineup.png"))
	views.resize(views.get_width() * 3, views.get_height() * 3, Image.INTERPOLATE_NEAREST)
	views.save_png(ProjectSettings.globalize_path("res://").path_join("../screenshots/realm_views.png"))
	EYE_OVR = {}
	NO_CAPE = false
	HORN_STYLE = ""
	HALO = ""
	WING_KIND = ""
	HAIRL7 = sh
	WHITE7 = sw7
	TEAL7 = st
	SKINL7 = sk
	_head_pal()


# ================================================================== v25: Понивилль — пони в виде девушек

## Персонажи из «My Little Pony» в виде людей: волосы цветами гривы (несколько полос — грива из прядей разных цветов),
## одежда цветом шёрстки, глаза своего цвета, знак отличия на юбке, у принцесс корона.
## [имя, полосы волос (базовые цвета), платье, отделка, глаза (база), причёска, корона, знак, кожа]
var PONY_ONLY: Array = []
const PONY_LOOKS: Array = [
	["pony_twilight", ["2a2c6e", "2a2c6e", "2a2c6e", "7a3ab0", "2a2c6e", "e04a9a"], "b48ae0", "3a2a6a", "7a4ac0", "long", "tiara", "star", ""],
	["pony_rarity", ["5a32b0"], "f6f4fa", "6a4ab0", "3a6ac8", "long", "", "diamond", ""],
	["pony_pinkie", ["e8508a"], "f6a8c8", "3a8ad8", "4a9ae0", "long", "", "balloon", ""],
	["pony_applejack", ["f0d060"], "e8902a", "8a5a2a", "3aa040", "tie", "", "apple", "tan"],
	["pony_rainbow", ["e83a3a", "f08a2a", "f0e040", "50c050", "3a8ae0", "8a4ac8"], "7ac8f0", "3a3a4a", "c03a90", "bob", "", "bolt", ""],
	["pony_fluttershy", ["f4a8c8"], "f8f0a0", "8ad0a0", "3aa0a0", "long", "", "butterfly", ""],
	["pony_celestia", ["5ac0d8", "5a9ae8", "8a6ae0", "e880c0"], "fcfaff", "f0c040", "b04aa8", "long", "gold", "sun", ""],
	["pony_luna", ["1a2a7a", "2a4ab0", "3a6ad8", "2a3a9a"], "2a3466", "8ab0f0", "3aa0c0", "long", "circlet", "moon", ""],
	["pony_cadance", ["a03a7a", "e0c040", "c050a0"], "f4b0d0", "e0c040", "8a4ac0", "long", "tiara", "heart", ""],
	["pony_starlight", ["8a3ab0", "8a3ab0", "5ad0e0"], "e8b8e8", "6a3a9a", "7a4ac0", "tie", "", "wand", ""],
	["pony_trixie", ["e0e8f4"], "3a7ad8", "8a4ac8", "9a6ad0", "long", "", "wand", ""],
	["pony_sunset", ["e83a2a", "f0d040"], "f0a040", "6a3a2a", "3aa0b8", "long", "", "sun", ""],
	["pony_applebloom", ["e04a6a"], "f4ecb8", "e04a6a", "e08a3a", "tie", "", "apple", ""],
	["pony_sweetie", ["c890e0", "f4a8d0"], "f8f6fa", "c890e0", "3ab060", "bob", "", "note", ""],
	["pony_scootaloo", ["a050c0"], "f0a040", "4a3a6a", "8a4ab0", "bob", "", "bolt", ""],
	["pony_babs", ["8a3a2a", "f0a0c0"], "c09060", "6a4a2a", "3aa040", "bob", "", "apple", ""],
	["pony_derpy", ["f4e890"], "a8a8b8", "5a7ab0", "e0c040", "long", "", "bubble", ""],
	["pony_vinyl", ["3a6ad0", "5ad0f0"], "f4f6fa", "3a3a4a", "e03a5a", "bob", "", "note", ""],
	["pony_octavia", ["2a2a2e"], "a89a8a", "8a1a2a", "9a6ac0", "long", "", "note", ""],
	["pony_lyra", ["8af0d8", "f4f8f8"], "a8f0d8", "e0c040", "e0a040", "long", "", "lyre", ""],
	["pony_bonbon", ["3a3a8a", "e85a8a"], "f0e8c8", "3a3a8a", "4a8ad0", "bob", "", "candy", ""],
	["pony_cheerilee", ["8a2a5a", "f0b0c8"], "c06090", "6a2a4a", "3ab060", "long", "", "flower", ""],
	["pony_mayor", ["e8e4dc"], "d8b88a", "6a4a2a", "4a8ad0", "bob", "", "scroll", ""],
	["pony_zecora", ["2a2a2e", "f4f4f4"], "6a5a4a", "f0c040", "4a8ad0", "long", "", "swirl", "dark"],
	["pony_spitfire", ["f04a2a", "f0c040"], "2a4ab0", "f0d040", "e08a3a", "bob", "", "flame", ""],
	["pony_fleetfoot", ["f4f4ff"], "2a4ab0", "f0d040", "c03a90", "bob", "", "bolt", ""],
	["pony_maud", ["5a4a8a"], "8a7aa8", "3a2a4a", "6a4a8a", "long", "", "rock", ""],
	["pony_limestone", ["6a6a6e"], "6a8ab0", "3a3a4a", "e0c040", "bob", "", "rock", ""],
	["pony_marble", ["4a4a5a"], "c0c4c8", "4a4a5a", "6a6ac0", "long", "", "rock", ""],
	["pony_diamond", ["a03a8a", "f0f0f8"], "e8a0d0", "c8c8d8", "4a8ad0", "long", "tiara", "diamond", ""],
	["pony_silver", ["a8a8b0"], "b0b4bc", "6a6a7a", "8a4ac0", "bob", "", "spoon", ""],
	["pony_daring", ["3a3a3e", "8a8a8e", "f0f0f0"], "8a6a3a", "4a3a2a", "c04a6a", "bob", "", "compass", "tan"],
	["pony_coco", ["5ac8c0", "f0f0f0"], "a87a5a", "5ac8c0", "4a8ad0", "long", "", "flower", ""],
	["pony_sapphire", ["8a3ab0"], "3a6ae0", "f0c040", "8a4ac0", "long", "", "gem", "dark"],
	["pony_berry", ["a03a8a"], "c050a0", "6a2a5a", "3aa040", "bob", "", "grape", ""],
	["pony_carrot", ["f08a2a"], "f4e070", "50a040", "3aa040", "long", "", "carrot", ""],
	["pony_minuette", ["3a6ae0", "8ac8f8"], "a8c8f0", "3a6ae0", "e04a6a", "long", "", "clock", ""],
	["pony_twist", ["e04a3a"], "f0e0c8", "e04a3a", "3aa040", "tie", "", "candy", ""],
	["pony_gilda", ["f4f4f0"], "8a6a40", "c8a040", "e08a3a", "bob", "", "feather", "tan"],
	["pony_cozy", ["f4d090"], "f0a8c8", "e04a9a", "4a8ad0", "tie", "", "heart", ""],
	["pony_tempest", ["c03a3a", "e0603a"], "4a2a5a", "2a1a3a", "3aa0b8", "bob", "", "bolt", ""],
	["pony_sugarbelle", ["8a3ab0", "f0b0e0"], "f0e0f8", "8a3ab0", "c04a8a", "long", "", "cake", ""],
	["pony_coloratura", ["e0e0f0", "c050a0"], "f4c0d0", "c050a0", "3a6ac8", "long", "", "note", ""],
	["pony_roseluck", ["c03a4a"], "f0e080", "50a040", "3aa040", "long", "", "rose", ""],
	["pony_daisy", ["c0d8f0"], "c8f0b8", "50a040", "3aa040", "bob", "", "flower", ""],
	["pony_lily", ["e070b0"], "f8f8fc", "e070b0", "3a6ac8", "long", "", "flower", ""],
	["pony_redheart", ["e04a5a"], "f8f8fc", "e04a5a", "3a6ac8", "bob", "", "heart", ""],
	["pony_cake", ["f0a0c0"], "f4e0a0", "e04a8a", "c04a6a", "tie", "", "cake", ""],
	["pony_photo", ["e8e4f0"], "f0e8f0", "1a1a1e", "3a6ac8", "bob", "", "star", ""],
	["pony_moondancer", ["c84a8a", "a03a6a"], "f0e8e0", "6a3a5a", "8a4ac0", "tie", "", "moon", ""],
	["pony_lemon", ["3a5ab0"], "f0e860", "3a5ab0", "3aa040", "long", "", "heart", ""],
	["pony_twinkle", ["f070b0"], "f8f8fc", "f070b0", "3aa040", "long", "", "star", ""],
	["pony_amethyst", ["9a3ac0"], "f0b0e0", "9a3ac0", "3a6ac8", "long", "", "gem", ""],
	["pony_cherry", ["c03a3a"], "f0c890", "c03a3a", "3aa040", "tie", "", "cherry", ""],
	["pony_chrysalis", ["3a8a8a", "2a5a5a"], "26262e", "40c080", "40c0a0", "long", "bone", "", "pale"],
]


func pramp(hexs: String) -> Array:
	var c: Color = Color(hexs)
	var out: Array = []
	for k in [-0.66, -0.46, -0.24, 0.0, 0.2, 0.42, 0.66]:
		var kk: float = float(k)
		if kk < 0.0:
			out.append(c.lerp(Color(0.14, 0.09, 0.24), -kk))
		else:
			out.append(c.lerp(Color(1.0, 0.98, 0.94), kk))
	return out


## знак на юбке 5x5: символ -> [строки, цвета]
const PONY_MARKS: Dictionary = {
	"star": [[".a.a.", "aabaa", ".aba.", "aa.aa", "....."], ["e04a9a", "ffffff"]],
	"diamond": [["a...a", "aa.aa", ".bab.", "..a..", "....."], ["5ab0f0", "c8f0ff"]],
	"balloon": [["aa.bb", "aa.bb", ".a..b", ".a.b.", "..c.."], ["4a9ae0", "f0e040", "8a8a8a"]],
	"apple": [["..c..", ".aaa.", "aabaa", "aaaaa", ".aaa."], ["d83a3a", "f8a0a0", "50a040"]],
	"bolt": [["..aab", ".aab.", "aaab.", ".bab.", "ab..."], ["e83a3a", "f0e040"]],
	"butterfly": [["aa.aa", "abcba", ".aca.", "aa.aa", "....."], ["f4a8c8", "e04a9a", "4ab0a0"]],
	"sun": [["a.a.a", ".bbb.", "abbba", ".bbb.", "a.a.a"], ["f0c040", "f08a2a"]],
	"moon": [[".aa..", "aa...", "aa..b", "aa...", ".aa.."], ["f0f4ff", "a8c0f0"]],
	"heart": [[".a.a.", "abaaa", "aaaaa", ".aaa.", "..a.."], ["e04a6a", "ffc0d0"]],
	"wand": [["...ab", "..a.b", ".a...", "a....", "....."], ["c890e0", "f0e040"]],
	"note": [["..aaa", "..a.a", "..a.a", "aaa..", "aa..."], ["3a3a6a", "8a8ad0"]],
	"bubble": [[".a...", "a.a.b", ".a.b.", "...b.", ".a..."], ["8ac8f0", "c8e8ff"]],
	"lyre": [["a...a", "ab.ba", "a.b.a", ".aaa.", "..a.."], ["f0c040", "f8f0c0"]],
	"candy": [["a...a", "abbba", ".bcb.", "abbba", "a...a"], ["e85a8a", "f0f0f0", "3a3a8a"]],
	"flower": [[".a.a.", "aabaa", ".aaa.", "..c..", ".cc.."], ["f070b0", "f0e040", "50a040"]],
	"scroll": [["aaaa.", "abbba", "abbba", ".aaaa", "....."], ["c8a060", "f8f0d8"]],
	"swirl": [[".aaa.", "a...a", "a.a.a", "a..a.", ".a..."], ["f0c040", "f0c040"]],
	"flame": [["..a..", ".aba.", "abcba", "abbba", ".aaa."], ["f04a2a", "f0a040", "f8f080"]],
	"rock": [[".aa..", "abaa.", "aaaa.", ".aa..", "....."], ["6a6a7a", "a8a8b8"]],
	"spoon": [[".aa..", "abaa.", ".aa..", "..a..", "..a.."], ["c8c8d8", "ffffff"]],
	"compass": [[".aaa.", "a.b.a", "abbba", "a.b.a", ".aaa."], ["c8a040", "d83a3a"]],
	"gem": [[".aaa.", "abbba", ".aba.", "..a..", "....."], ["3a6ae0", "a8c8ff"]],
	"grape": [[".c...", "aa...", "aaa..", ".aa..", "..a.."], ["8a3ab0", "c890e0", "50a040"]],
	"carrot": [["...cc", "..aac", ".aa..", "aa...", "a...."], ["f08a2a", "f0a040", "50a040"]],
	"clock": [[".aaa.", "a.b.a", "a.bba", "a...a", ".aaa."], ["3a6ae0", "f0f0f0"]],
	"feather": [["...aa", "..aba", ".aba.", "aba..", "a...."], ["c8a040", "f4f4f0"]],
	"cake": [["..c..", ".aaa.", "bbbbb", "aaaaa", "aaaaa"], ["f0a0c0", "f8f0f0", "e04a4a"]],
	"rose": [[".aa..", "abba.", ".aa..", "..c..", ".cc.."], ["c03a4a", "f07080", "50a040"]],
	"cherry": [["...c.", "..c.c", ".c..c", "aa.aa", "aa.aa"], ["c03a3a", "f07080", "50a040"]],
}


func pony_mark(im: Image, dir: int, f: int, mark: String) -> void:
	if mark == "" or not PONY_MARKS.has(mark) or dir == 1 or dir == 5:
		return
	var b: int = -1 if (f == 1 or f == 3 or f == 6 or f == 7) else 0
	var m: Array = PONY_MARKS[mark]
	var rows: Array = m[0]
	var cols: Array = m[1]
	var x0: int = 43 if dir == 0 else (41 if dir == 2 else 44)
	var y0: int = 71 + b
	for yy in range(rows.size()):
		var row: String = rows[yy]
		for xx in range(row.length()):
			var ch: String = row[xx]
			if ch == ".":
				continue
			var ci: int = "abc".find(ch)
			if ci >= 0 and ci < cols.size():
				px(im, x0 + xx, y0 + yy, Color(String(cols[ci])))


## Причёска: хвостик сбоку или заколка (через rock_extras); каре — через HAIR_CUT
func pony_hair_extra(im: Image, dir: int, f: int, sty: String) -> void:
	if sty == "tie" or sty == "clip":
		rock_extras(im, dir, f, "", Color.WHITE, Color.WHITE, false, "side" if sty == "tie" else "clip", HAIRL7)


func gen_ponies25() -> void:
	var sh: Array = HAIRL7.duplicate()
	var sw7: Array = WHITE7.duplicate()
	var st: Array = TEAL7.duplicate()
	var sk: Array = SKINL7.duplicate()
	var fw: int = 80
	var fh: int = 160
	var mirror: Dictionary = {2: 3, 4: 6, 5: 7}
	BOUNCE_OVR = 0
	NO_CAPE = true
	var looks: Array = []
	for lk in PONY_LOOKS:
		if PONY_ONLY.is_empty() or PONY_ONLY.has(String(lk[0])):
			looks.append(lk)
	var line_up: Image = new_img(fw * looks.size(), fh)
	var li: int = 0
	for lk in looks:
		var bands: Array = lk[1]
		WHITE7 = pramp(String(lk[2]))
		TEAL7 = pramp(String(lk[3]))
		var ec: Array = pramp(String(lk[4]))
		EYE_OVR = {"I": ec[1], "i": ec[3], "j": ec[5]}
		var sty: String = String(lk[5])
		HAIR_CUT = 40 if sty == "bob" else 0
		match String(lk[8]):
			"tan":
				SKINL7 = hx(["6a3a2a", "9a5a40", "c07a58", "d89a74", "eab894", "f4d2b2", "fbe8d4"])
			"dark":
				SKINL7 = hx(["3a2018", "5a3424", "7a4a32", "966244", "b07e5a", "c89a76", "dcb898"])
			"pale":
				SKINL7 = hx(["6a6a7a", "9a9aaa", "bcbcca", "d4d4e0", "e4e4ee", "f0f0f6", "fafaff"])
			_:
				SKINL7 = sk
		var crown_sty: String = String(lk[6])
		var mark: String = String(lk[7])
		# волосы из полос: кадр рисуется по разу на каждый цвет, пиксели волос берутся из «своей» полосы
		var uniq: Array = []
		for bh in bands:
			if not uniq.has(String(bh)):
				uniq.append(String(bh))
		var ramps: Array = []
		for u in uniq:
			ramps.append(pramp(String(u)))
		var vs: Image = new_img(fw * 8, fh * 8)
		for vd in [0, 1, 2, 4, 5]:
			for k in range(8):
				var imgs: Array = []
				for ri in range(ramps.size()):
					HAIRL7 = ramps[ri]
					_head_pal()
					var c2: Image = new_img(fw, fh)
					draw_hero10(c2, vd, k)
					pony_hair_extra(c2, vd, k, sty)
					if crown_sty != "":
						crown(c2, vd, k, crown_sty)
					pony_mark(c2, vd, k, mark)
					outline_auto(c2, OUTLINE_CHAR)
					imgs.append(c2)
				var res: Image = imgs[0]
				if imgs.size() > 1:
					res = (imgs[0] as Image).duplicate()
					for y in range(fh):
						for x in range(fw):
							var c0: Color = (imgs[0] as Image).get_pixel(x, y)
							var diff: bool = false
							for ii in range(1, imgs.size()):
								if not (imgs[ii] as Image).get_pixel(x, y).is_equal_approx(c0):
									diff = true
									break
							if diff:
								# полоса по длине волос: по высоте с наклоном
								var bi: int = int(floor((float(y) + float(x) * 0.3) / 7.0)) % bands.size()
								var ui: int = uniq.find(String(bands[bi]))
								res.set_pixel(x, y, (imgs[ui] as Image).get_pixel(x, y))
				vs.blit_rect(res, Rect2i(0, 0, fw, fh), Vector2i(k * fw, vd * fh))
				if mirror.has(vd):
					var mc: Image = res.duplicate()
					mc.flip_x()
					vs.blit_rect(mc, Rect2i(0, 0, fw, fh), Vector2i(k * fw, int(mirror[vd]) * fh))
		save3(vs, String(lk[0]), false)
		HAIRL7 = ramps[0]
		_head_pal()
		gen_faces10("faces_" + String(lk[0]))
		line_up.blit_rect(vs, Rect2i(4 * fw, 0, fw, fh), Vector2i(li * fw, 0))
		li += 1
		print("pony ", lk[0])
	line_up.resize(line_up.get_width() * 2, line_up.get_height() * 2, Image.INTERPOLATE_NEAREST)
	line_up.save_png(ProjectSettings.globalize_path("res://").path_join("../screenshots/ponies25_lineup.png"))
	NO_CAPE = false
	HAIR_CUT = 0
	EYE_OVR = {}
	HAIRL7 = sh
	WHITE7 = sw7
	TEAL7 = st
	SKINL7 = sk
	_head_pal()
	if PONY_ONLY.is_empty():
		gen_pony_buildings25()


## Здания Понивилля: дворец (Кантерлот), кондитерская («Сахарный уголок»), бутик-карусель, амбар, коттедж,
## облачный домик, хижина травницы-зебры и пастельные дома горожанок
func gen_pony_buildings25() -> void:
	building10("palace_ponies", {"w": 300, "h": 130, "roof_h": 90, "towers": true, "mat": "stone", "roof_shape": "steep", "wall": ["c8c4d8", "dcd8ea", "eceaf6", "f6f4fc", "ffffff"], "roof": ["4a2a8a", "5e38aa", "7a4cc8", "9a6ae0", "c09af0"], "deco": ["banner", "crystal"], "banner": "f0c040", "trim": "8a7ab0", "door": "e0b040", "win": "a8d8ff", "door_w": 36, "arch": true})
	building10("tavern_ponies", {"w": 220, "h": 100, "roof_h": 66, "mat": "brick", "wall": ["8a5030", "a46840", "bc8456", "d0a070", "e4bc90"], "roof": ["d8c8d0", "e8dce4", "f4ecf2", "faf6fa", "ffffff"], "deco": ["chimney", "lamps"], "trim": "e070a0", "sign": "cake", "door": "e070a0", "win": "fff0c0"})
	building10("shop_ponies", {"w": 180, "h": 90, "roof_h": 70, "roof_shape": "dome", "wall": ["dcd8e4", "eae6f0", "f4f2f8", "faf8fc", "ffffff"], "roof": ["4a2a8a", "5e38aa", "7a4cc8", "9a6ae0", "c09af0"], "deco": ["banner"], "banner": "5ab0f0", "trim": "6a4ab0", "sign": "bag", "door": "6a4ab0", "win": "c8e8ff"})
	building10("pony_barn", {"w": 240, "h": 110, "roof_h": 70, "mat": "wood", "roof_shape": "gable", "wall": ["6a1a1a", "8a2420", "a8302a", "c04438", "d8604e"], "roof": ["3a2a24", "4e3a30", "66503e", "7e6650", "988068"], "deco": ["chimney"], "trim": "f4f0e8", "door": "f4f0e8", "door_w": 44, "win": "fff0c0"})
	building10("pony_cottage", {"w": 180, "h": 80, "roof_h": 60, "mat": "wood", "roof_shape": "dome", "wall": ["9a7a50", "b49464", "c8ac7c", "dcc498", "ecdab4"], "roof": ["3a6a2a", "4a8436", "5ea044", "7cbc5a", "a0d47a"], "deco": ["vines"], "trim": "5a3a24", "door": "8a5a34", "win": "fff0c0"})
	building10("pony_cloud_house", {"w": 200, "h": 100, "roof_h": 70, "towers": true, "roof_shape": "dome", "wall": ["c8d8f0", "dce6f8", "eaf0fc", "f6f8ff", "ffffff"], "roof": ["5a8ad8", "6ea0e8", "8ab8f0", "a8ccf8", "c8e0ff"], "deco": ["banner"], "banner": "e83a3a", "trim": "8aa8d8", "door": "6ea0e8", "win": "fff8c0", "door_w": 28, "arch": true})
	building10("pony_hut", {"w": 160, "h": 70, "roof_h": 60, "mat": "hide", "roof_shape": "tent", "wall": ["5a4a30", "6e5c3c", "84704c", "9a8660", "b09c78"], "roof": ["3a4a2a", "4a5c34", "5e7040", "74864e", "8c9c62"], "deco": ["skull", "vines"], "trim": "f0c040", "door": "3a2a1a", "win": "c8f070"})
	var house_pals: Array = [
		[["e4c8d0", "eed8de", "f6e6ea", "faf0f2", "fff8fa"], ["8a3a6a", "a84a84", "c8669e", "e08ab8", "f0b0d0"]],
		[["d8e4c8", "e4eed8", "eef6e6", "f4faf0", "fafff8"], ["2a7a6a", "3a947e", "50ae94", "70c8ac", "98dcc4"]],
		[["e4dcc8", "eee8d8", "f6f0e4", "faf6ee", "fffcf8"], ["6a4aaa", "7e5cc4", "9676d8", "b296e8", "ccb8f4"]],
		[["e8dcb8", "f0e6c8", "f6eed8", "faf4e8", "fffaf4"], ["c0702a", "d4883a", "e4a250", "f0bc70", "f8d498"]],
	]
	var letters: String = "abcd"
	for i in range(house_pals.size()):
		var pal: Array = house_pals[i]
		var roof_p: Array = pal[1]
		building10("pony_house_" + letters[i], {"w": 160, "h": 80, "roof_h": 60, "timber": true, "wall": pal[0], "roof": roof_p, "deco": ["chimney"] if i % 2 == 0 else ["lamps"], "trim": "6a4a3a", "door": String(roof_p[2])})

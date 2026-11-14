extends SceneTree
## Значки раннего доступа (кузница, зазывание в лавке) — рисуются кодом, 24×24, как остальные icon_*.
## Запуск из папки game:  godot --headless --path . -s res://tools/paths_art.gd   потом  --headless --import

const OUT: String = "res://art/"
const OL: Color = Color("2a1c14")        # обводка
const M0: Color = Color("4a4e5a")        # металл: тень
const M1: Color = Color("7c8290")
const M2: Color = Color("b4bac4")
const M3: Color = Color("eef2f6")        # блик
const W0: Color = Color("5a3a20")        # дерево
const W1: Color = Color("8a5a30")
const W2: Color = Color("b07a44")
const G1: Color = Color("d8a030")        # золото
const G2: Color = Color("ffe08a")
const R1: Color = Color("a83a3a")        # ткань
const R2: Color = Color("d86a5a")
const S1: Color = Color("6a5aff")        # звезда
const S2: Color = Color("b8b0ff")

var img: Image


func _init() -> void:
	_make("icon_iron_bar", _iron_bar)
	_make("icon_horseshoe", _horseshoe)
	_make("icon_guard_sword", _sword.bind(false))
	_make("icon_star_blade", _sword.bind(true))
	_make("icon_tourney_spear", _spear)
	_make("icon_round_shield", _shield)
	_make("icon_helmet", _helmet)
	_make("icon_iron_pot", _pot)
	_make("icon_lure", _bell)
	print("paths_art: ok")
	quit()


func _make(name: String, f: Callable) -> void:
	img = Image.create(24, 24, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	f.call()
	_outline()
	img.save_png(ProjectSettings.globalize_path(OUT + name + ".png"))


func px(x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < 24 and y < 24:
		img.set_pixel(x, y, c)


func rect(x0: int, y0: int, w: int, h: int, c: Color) -> void:
	for y in range(y0, y0 + h):
		for x in range(x0, x0 + w):
			px(x, y, c)


## Обводка: каждый прозрачный пиксель рядом с цветным становится тёмным
func _outline() -> void:
	var src: Image = img.duplicate()
	for y in range(24):
		for x in range(24):
			if src.get_pixel(x, y).a > 0.0:
				continue
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var q: Vector2i = Vector2i(x, y) + d
				if q.x >= 0 and q.y >= 0 and q.x < 24 and q.y < 24 and src.get_pixel(q.x, q.y).a > 0.0 and src.get_pixel(q.x, q.y) != OL:
					img.set_pixel(x, y, OL)
					break


func _iron_bar() -> void:
	# слиток: трапеция, верхняя грань светлая, боковая тёмная
	for y in range(7, 17):
		var k: int = y - 7
		var x0: int = 2 + (2 if k < 4 else 0) + (k - 4 if k >= 4 else 0) / 3
		var x1: int = 21 - (2 if k < 4 else 0) - (k - 4 if k >= 4 else 0) / 3
		for x in range(x0, x1 + 1):
			var col: Color = M2 if k < 4 else M1
			if k >= 4 and x > x1 - 3:
				col = M0
			if k < 4 and (x == x0 + 1 or k == 0):
				col = M3
			px(x, y, col)
	rect(6, 12, 9, 1, M2)


func _horseshoe() -> void:
	var c: Vector2 = Vector2(11.5, 10.0)
	for y in range(24):
		for x in range(24):
			var d: float = Vector2(x, y).distance_to(c)
			if d >= 4.5 and d <= 8.5 and y <= 19 and not (y > 11 and absf(float(x) - 11.5) < 4.5):
				var col: Color = M1
				if d < 5.6:
					col = M0
				elif d > 7.6:
					col = M2
				if y < 6 and x > 8 and x < 15:
					col = M3 if d > 7.0 else M2
				px(x, y, col)
	# дырочки под гвозди
	for p in [Vector2i(5, 12), Vector2i(6, 7), Vector2i(17, 7), Vector2i(18, 12)]:
		px(p.x, p.y, M0)
	rect(3, 18, 4, 2, M1)
	rect(17, 18, 4, 2, M1)


func _sword(star: bool) -> void:
	# клинок по диагонали от правого верха к левому низу
	for i in range(14):
		var x: int = 19 - i
		var y: int = 2 + i
		px(x, y, S2 if star and i % 3 == 0 else M3)
		px(x - 1, y, S1 if star else M2)
		px(x, y + 1, M1)
	px(20, 1, M3)
	# гарда
	for i in range(-3, 4):
		px(6 + i, 15 + i, G1 if not star else S1)
		px(7 + i, 15 + i, G2 if not star else S2)
	# рукоять и навершие
	px(4, 18, W1)
	px(3, 19, W2)
	px(5, 19, W0)
	px(4, 20, W1)
	rect(1, 20, 2, 2, G1 if not star else S2)
	if star:
		px(13, 8, Color.WHITE)
		px(14, 7, S2)
		px(12, 9, S2)


func _spear() -> void:
	for i in range(18):
		px(3 + i, 20 - i, W2 if i % 4 != 0 else W1)
		px(4 + i, 20 - i, W0)
	# мягкий наконечник: подушечка в ткани (турнирное)
	rect(17, 2, 5, 5, R1)
	rect(18, 3, 3, 2, R2)
	px(19, 2, R2)
	# флажок
	rect(9, 9, 4, 3, G1)
	px(9, 12, G1)
	px(10, 10, G2)


func _shield() -> void:
	var c: Vector2 = Vector2(11.5, 11.5)
	for y in range(24):
		for x in range(24):
			var d: float = Vector2(x, y).distance_to(c)
			if d <= 9.5:
				var col: Color = W1 if (x / 3) % 2 == 0 else W2
				if d > 8.0:
					col = M1 if (x + y) % 5 != 0 else M3
				elif d > 7.2:
					col = M0
				px(x, y, col)
	# умбон
	rect(10, 10, 4, 4, M2)
	px(10, 10, M3)
	px(13, 13, M0)


func _helmet() -> void:
	var c: Vector2 = Vector2(11.5, 12.0)
	for y in range(3, 20):
		for x in range(3, 21):
			var d: float = Vector2(x, y).distance_to(c)
			if d <= 8.6 and y <= 18:
				var col: Color = M1
				if x < 9 and y < 11:
					col = M2
				if x < 7 and y < 9:
					col = M3
				if x > 15:
					col = M0
				px(x, y, col)
	# смотровая щель и гребень
	rect(6, 11, 12, 2, OL)
	rect(7, 14, 1, 3, M0)
	rect(10, 14, 1, 3, M0)
	rect(13, 14, 1, 3, M0)
	rect(16, 14, 1, 3, M0)
	rect(10, 1, 4, 3, R1)
	rect(11, 1, 2, 1, R2)


func _pot() -> void:
	var c: Vector2 = Vector2(11.5, 13.5)
	for y in range(7, 21):
		for x in range(3, 21):
			var d: float = Vector2(x, (y - 13.5) * 1.15 + 13.5).distance_to(c)
			if d <= 8.6:
				var col: Color = M0
				if x < 9:
					col = M1
				if x < 6 and y < 13:
					col = M2
				px(x, y, col)
	rect(3, 7, 18, 2, M1)
	rect(4, 7, 6, 1, M3)
	# ручка-дужка
	for i in range(9):
		px(6 + i, 4 - int(sin(float(i) / 8.0 * PI) * 3.0) + 2, M2)
	rect(7, 20, 2, 2, M0)
	rect(15, 20, 2, 2, M0)


func _bell() -> void:
	# колокольчик зазывалы
	for y in range(4, 18):
		var w: int = 2 + (y - 4) / 2
		for x in range(12 - w, 12 + w):
			var col: Color = G1
			if x < 12 - w + 2:
				col = G2
			if x > 12 + w - 3:
				col = Color("a87020")
			px(x, y, col)
	rect(4, 17, 16, 2, Color("a87020"))
	rect(5, 17, 6, 1, G2)
	rect(11, 19, 2, 2, M1)
	rect(11, 1, 2, 3, W1)
	# звон
	px(2, 9, G2)
	px(1, 11, G2)
	px(21, 9, G2)
	px(22, 11, G2)

extends "res://tools/art_gen.gd"
## v31: Большое дерево заднего двора (огорода) — в том же стиле, что лесные деревья tree_a…tree_d:
## та же крона из клубов (leaf_canopy: тёмная подложка-просветы + мазки-листья по свету сверху-слева,
## бирюзовые тени → жёлто-зелёный свет), те же ветки, кора, трава и обводка.
## Отличия: крупнее (232x300 против 152x188), больше клубов, ствол толще и БЕЗ дупла,
## нижние ~100 px ствола свободны от листвы — там растут грибы (SHROOM_AT в backyard29.gd).
## Варианты под биом дома: by29_big_tree.png (луг) и by29_big_tree_<биом>.png — берёт backyard29.gd (_tree_tex).
## Запуск: godot --headless --path game --script res://tools/art_v31_bigtree.gd


func _init() -> void:
	_palettes()
	_palettes3()
	_palettes_hero()
	_palettes_v4()
	# одно и то же дерево (тот же seed — та же форма) в цветах каждого биома, где можно поставить дом
	var bark0: Array = BARK7
	var birch_bark: Array = hx(["2e2a2c", "4a4446", "7a7474", "a8a29c", "cec8c0", "e6e2da", "f8f6f0"])
	var looks: Dictionary = {
		"": [L7_GREEN, bark0],                                   # Родной луг (и всё остальное)
		"field": [L7_LIME, bark0],                               # Цветочные поля
		"beach": [L7_MINT, bark0],                               # Побережье
		"birch": [L7_LIME, birch_bark],                          # Берёзовая роща — белый ствол
		"pine": [L7_PINE, bark0],                                # Хвойная тайга
		"autumn": [L7_AUTUMN, bark0],                            # Осенний лес
		"pink": [L7_BLOSSOM, bark0],                             # Розовый лес
		"grotto": [hx(["1a1a3a", "262a5a", "343e78", "465a94", "5e78ae", "86a2cc", "bcd0ec"]), bark0],   # Гроты
		"swamp": [hx(["1e2a22", "2a3a2a", "3a4e32", "4e643a", "667c44", "829654", "a8b878"]), bark0],    # Болото
	}
	for key in looks.keys():
		var lk: Array = looks[key]
		BARK7 = lk[1]
		gen_big_yard_tree("by29_big_tree" + ("" if String(key) == "" else "_" + String(key)), 3131, 232, 300, lk[0])
	BARK7 = bark0
	print("ART DONE by29_big_tree x%d" % looks.size())
	quit()


## Кора как у лесных деревьев (draw_trunk3), только без дупла-пятна
func draw_trunk3(im: Image, cx: float, t0: int, base: int, hw_top: float, seed_v: int) -> void:
	for side in [-1.0, 1.0]:
		var s: float = float(side)
		for k in range(16):
			var t: float = k / 15.0
			var rxp: float = cx + s * (hw_top * 0.6 + t * hw_top * 1.8)
			var ryp: float = base - 7.0 + t * 7.0
			var rr: float = 4.6 - t * 3.0
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
			var col: float = (x - cx) / hw
			var crack: float = sin(col * 7.0 + sin(y * 0.35 + seed_v) * 0.8)
			if crack > 0.86:
				ti2 -= 2
			elif crack > 0.6 and h01(x, y / 3, seed_v) > 0.4:
				ti2 -= 1
			if y < t0 + 5:
				ti2 = maxi(1, ti2 - 2)
			px(im, x, y, BARK7[clampi(ti2, 0, 6)])
	# мох у основания (как у лесных)
	for k3 in range(16):
		var mx: int = int(cx + rng.randf_range(-hw_top * 1.3, hw_top * 1.3))
		var my: int = base - rng.randi_range(0, 5)
		if a_at(im, mx, my) > 0.5:
			px(im, mx, my, L7_GREEN[4])
			px(im, mx + 1, my, L7_GREEN[3])


func gen_big_yard_tree(name: String, seed_v: int, w: int, h: int, ramp: Array) -> void:
	rng.seed = seed_v
	var im: Image = new_img(w, h)
	var cx: float = w / 2.0
	var base: int = h - 8
	var R: float = w * 0.40
	var ccy: float = 128.0                 # крона повыше: низ кроны ~ на 100 px выше земли
	var t0: int = int(ccy + R * 0.2)
	draw_trunk3(im, cx, t0, base, 9.0, seed_v)
	# клубы: раскладка лесных деревьев + ещё несколько для большой пышной кроны
	var cl: Array = tree_clumps(cx, ccy, R)
	for a0 in [[-0.30, -0.86, 0.34, 0.28], [0.32, -0.84, 0.34, 0.28], [-0.66, -0.40, 0.34, 0.30], [0.68, -0.38, 0.34, 0.30],
			[-0.28, 0.06, 0.40, 0.34], [0.30, 0.04, 0.40, 0.34], [-1.02, 0.08, 0.26, 0.24], [1.02, 0.10, 0.26, 0.24]]:
		var a: Array = a0
		cl.append(Vector4(cx + float(a[0]) * R + rng.randf_range(-2, 2), ccy + float(a[1]) * R + rng.randf_range(-2, 2),
				float(a[2]) * R * rng.randf_range(0.92, 1.08), float(a[3]) * R * rng.randf_range(0.92, 1.08)))
	cl.sort_custom(func(p: Vector4, q: Vector4) -> bool: return p.y < q.y)
	var bA: Vector2 = Vector2(cx - R * 0.6, ccy + R * 0.04)
	var bB: Vector2 = Vector2(cx + R * 0.56, ccy - R * 0.08)
	var bC: Vector2 = Vector2(cx + 2.0, ccy - R * 0.5)
	var bD: Vector2 = Vector2(cx - R * 0.3, ccy - R * 0.42)
	var under: Callable = func() -> void:
		branch(im, Vector2(cx - 3, t0 + 6), bA, 9.0, 2.5)
		branch(im, Vector2(cx + 3, t0 + 2), bB, 9.0, 2.5)
		branch(im, Vector2(cx, t0 + 4), bC, 10.0, 3.0)
		branch(im, Vector2(cx - 2, t0 - 4), bD, 6.0, 2.0)
		for y in range(int(ccy + R * 0.1), t0 + 8):
			for x in range(int(cx - 7), int(cx + 8)):
				px(im, x, y, BARK7[2] if x < cx + 1 else BARK7[1])
	var holes: Array = [Vector3(bA.x * 0.5 + cx * 0.5 - 2, (bA.y + t0) * 0.5, 5.5), Vector3(bB.x * 0.5 + cx * 0.5 + 1, (bB.y + t0) * 0.5 - 2, 5.0),
			Vector3(bD.x * 0.5 + cx * 0.5, (bD.y + t0) * 0.5 - 6, 4.0)]
	leaf_canopy(im, cl, ramp, seed_v, 6.4, 4.8, 3.4, 0.55, under, holes)
	grass_blades(im, cx, base + 1, 26.0, 40, L7_GREEN)
	clean_specks(im)
	outline_auto(im, 0.5)
	shadow(im, cx + 2.0, base + 2.0, w * 0.34, 6.0, 0.16)
	save3(im, name)

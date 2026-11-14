extends SceneTree
## Делит лист героини/жителей на три слоя: тело, волосы, плащ (для ветра).
## Запуск: godot --headless --path game --script res://tools/wind_mask_gen.gd
## Потом: godot --headless --path game --import
## Результат: art/<имя>_body.png, _hair.png, _cape.png (та же раскладка кадров, что у листа).

const FW: int = 80
const FH: int = 160
const PAD: int = 48          # поля слоёв волос/плаща с каждой стороны: можно улетать за рамку кадра
const SHEETS: Array = ["player", "villager_marta", "villager_lina", "villager_tim"]
const OUTFITS: Array = ["none", "rags", "dress", "cloak_travel", "lab_coat", "apron"]


func _init() -> void:
	var only_o: bool = OS.get_cmdline_user_args().has("--outfits")
	if not only_o:
		for n in SHEETS:
			_make(String(n))
	for o in OUTFITS:
		_make("player_" + String(o))
		_make("player_" + String(o) + "_bare")
	quit()


func _px(img: Image, x: int, y: int) -> Color:
	return img.get_pixel(x, y)


func _key(c: Color) -> int:
	return (c.to_rgba32() >> 8) & 0xFFFFFF


## Палитра: цвета, встречающиеся в прямоугольнике (минимум cnt пикселей)
func _palette(img: Image, x0: int, y0: int, x1: int, y1: int, cnt: int, min_lum: float) -> Dictionary:
	var counts: Dictionary = {}
	for y in range(y0, y1):
		for x in range(x0, x1):
			var c: Color = _px(img, x, y)
			if c.a < 0.9 or c.get_luminance() < min_lum:
				continue
			var k: int = _key(c)
			counts[k] = int(counts.get(k, 0)) + 1
	var res: Dictionary = {}
	for k in counts.keys():
		if int(counts[k]) >= cnt:
			res[k] = true
	return res


func _make(name: String) -> void:
	var img: Image = Image.load_from_file(ProjectSettings.globalize_path("res://art/%s.png" % name))
	if img == null:
		push_error("нет листа " + name)
		return
	img.convert(Image.FORMAT_RGBA8)
	var cols: int = img.get_width() / FW
	var rows: int = img.get_height() / FH
	# эталон — стойка анфас (ряд 0, кадр 4 у героини; кадр 0 у жителей)
	var ref_col: int = 4 if cols > 8 else 0
	var base: Image = img.get_region(Rect2i(ref_col * FW, 0, FW, FH))
	var hair: Dictionary = _palette(base, 0, 5, FW, 16, 2, 0.3)
	# плащ: боковые края ниже колен (ноги и сапоги стоят в середине)
	var cape: Dictionary = {}
	var left: Dictionary = _palette(base, 0, 110, 24, 150, 2, 0.0)
	var right: Dictionary = _palette(base, 56, 110, FW, 150, 2, 0.0)
	for k in left.keys():
		cape[k] = true
	for k in right.keys():
		cape[k] = true
	# кожа (ноги, кисти) и сапоги — они не плащ, даже если стоят на его фоне
	var skin: Dictionary = _palette(base, 28, 100, 38, 128, 3, 0.0)
	var skin2: Dictionary = _palette(base, 42, 100, 52, 128, 3, 0.0)
	var hands: Dictionary = _palette(base, 14, 76, 28, 90, 3, 0.0)
	var hands2: Dictionary = _palette(base, 52, 76, 66, 90, 3, 0.0)
	for d in [skin2, hands, hands2]:
		for k in d.keys():
			skin[k] = true
	var boots: Dictionary = _palette(base, 26, 140, 54, 156, 3, 0.0)
	for k in cape.keys():
		boots.erase(k)
		skin.erase(k)
	var hem: Dictionary = _palette(base, 30, 66, 50, 82, 4, 0.5)
	# --- делим лист на три: тело без волос/плаща, волосы, плащ ---
	var body: Image = img.duplicate()
	var lw: int = FW + PAD * 2
	var hair_img: Image = Image.create(cols * lw, img.get_height(), false, Image.FORMAT_RGBA8)
	var cape_img: Image = Image.create(cols * lw, img.get_height(), false, Image.FORMAT_RGBA8)
	hair_img.fill(Color(0, 0, 0, 0))
	cape_img.fill(Color(0, 0, 0, 0))
	var nh: int = 0
	var nc: int = 0
	for fy in range(rows):
		for fx in range(cols):
			var ox: int = fx * FW
			var oy: int = fy * FH
			var kind: PackedByteArray = PackedByteArray()   # 0 тело, 1 волосы, 2 плащ
			kind.resize(FW * FH)
			for y in range(FH):
				for x in range(FW):
					var c: Color = img.get_pixel(ox + x, oy + y)
					if c.a < 0.5:
						continue
					var k: int = _key(c)
					if y >= 24 and y <= 80 and hair.has(k):
						kind[y * FW + x] = 1
					elif (y >= 84 and cape.has(k)) or (y >= 40 and y < 84 and absi(x - 40) >= 16 and cape.has(k)) or (y >= 100 and not skin.has(k) and not boots.has(k) and not hem.has(k)):
						# контур сапог остаётся на сапогах
						var near_boot: bool = false
						if y >= 136 or y < 112:
							for dy in range(-1, 2):
								for dx in range(-1, 2):
									var bx: int = x + dx
									var by: int = y + dy
									if bx >= 0 and by >= 0 and bx < FW and by < FH:
										var bc: Color = img.get_pixel(ox + bx, oy + by)
										if bc.a > 0.5 and (boots.has(_key(bc)) or (y < 112 and skin.has(_key(bc)))):
											near_boot = true
						if not near_boot:
							kind[y * FW + x] = 2
			for y in range(FH):
				for x in range(FW):
					var t: int = kind[y * FW + x]
					if t == 0:
						continue
					var c2: Color = img.get_pixel(ox + x, oy + y)
					body.set_pixel(ox + x, oy + y, Color(0, 0, 0, 0))
					if t == 1:
						hair_img.set_pixel(fx * lw + PAD + x, oy + y, c2)
						nh += 1
						# под волосами у тела дыра: закрываем цветом ближайшего пикселя тела слева/справа
						var lc: Color = Color(0, 0, 0, 0)
						var rc: Color = Color(0, 0, 0, 0)
						var ld: int = 99
						var rd: int = 99
						for d in range(1, 15):
							if ld == 99 and x - d >= 0 and kind[y * FW + x - d] == 0:
								var q: Color = img.get_pixel(ox + x - d, oy + y)
								if q.a > 0.5:
									lc = q
									ld = d
							if rd == 99 and x + d < FW and kind[y * FW + x + d] == 0:
								var q2: Color = img.get_pixel(ox + x + d, oy + y)
								if q2.a > 0.5:
									rc = q2
									rd = d
						if ld < 99 and rd < 99:
							body.set_pixel(ox + x, oy + y, lc if ld <= rd else rc)
					else:
						cape_img.set_pixel(fx * lw + PAD + x, oy + y, c2)
						nc += 1
	# плащ за телом сплошной: закрашиваем промежутки между краями самым тёмным цветом плаща
	var dark: Color = Color(0, 0, 0, 1)
	var dl: float = 9.0
	for k in cape.keys():
		var kc: Color = Color.from_rgba8((int(k) >> 16) & 255, (int(k) >> 8) & 255, int(k) & 255)
		if kc.get_luminance() < dl:
			dl = kc.get_luminance()
			dark = kc
	for fy in range(rows):
		for fx in range(cols):
			for y in range(40, FH):
				var x0: int = -1
				var x1: int = -1
				for x in range(lw):
					if cape_img.get_pixel(fx * lw + x, fy * FH + y).a > 0.5:
						if x0 < 0:
							x0 = x
						x1 = x
				if x0 < 0:
					continue
				for x in range(x0, x1 + 1):
					if cape_img.get_pixel(fx * lw + x, fy * FH + y).a < 0.5:
						cape_img.set_pixel(fx * lw + x, fy * FH + y, dark)
	body.save_png(ProjectSettings.globalize_path("res://art/%s_body.png" % name))
	hair_img.save_png(ProjectSettings.globalize_path("res://art/%s_hair.png" % name))
	cape_img.save_png(ProjectSettings.globalize_path("res://art/%s_cape.png" % name))
	print("%s: волосы %d, плащ %d пикселей" % [name, nh, nc])

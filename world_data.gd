extends RefCounted
## Большой открытый мир: сетка регионов вокруг двора травницы.
## Один регион — как двор (1920x1280 пикселей арта). Двор — регион (0, 0).
## Используют: генератор картинок (земля, карта), игра (world.gd), карта на M (map_ui.gd).

const RW: int = 1920
const RH: int = 1280
const GX0: int = -9          # самый левый столбец регионов (v18: карта расширена лесами)
const GY0: int = -7          # самый верхний ряд
const COLS: int = 21
const ROWS: int = 14
const ORIGIN: Vector2 = Vector2(GX0 * RW, GY0 * RH)
const SIZE: Vector2 = Vector2(COLS * RW, ROWS * RH)
const CELL: int = 16          # клетка карты биомов (пикселей мира)
const FOG_CELL: int = 64      # клетка тумана на карте

# Биомы (номер — индекс в карте биомов и в шейдере земли)
const HOME: int = 0
const MEADOW: int = 1
const SPIDER: int = 2        # паутинный лес: добрые пауки и девочка-паук
const GOTHIC: int = 3        # готика: замки, вампиры, оборотни
const KNIGHT: int = 4        # средневековые замки и рыцари
const ELF: int = 5           # лес эльфов
const MAGE: int = 6          # долина магов с посохами
const ORC: int = 7           # степь орков и гоблинов
const DWARF: int = 8         # горы дворфов и эль
const CATS: int = 9          # деревня кошкодевочек
const UNICORN: int = 10      # розовый лес единорогов
const GROTTO: int = 11       # каменистые гроты со светящимися грибами и пещерами
const BIRCH: int = 12        # берёзовая роща
const PINE: int = 13         # хвойная тайга
const AUTUMN: int = 14       # осенний лес
const SWAMP: int = 15        # болото
const FIELD: int = 16        # поля с цветами и стогами
const JAPAN: int = 17        # земли Восходящего Солнца: сакура, бамбук, тории
const BEACH: int = 18        # песчаное побережье
const SEA: int = 19          # море (по нему не пройти — только с пирса под воду)
const ROAD: int = 31         # дорога (только в карте биомов)
const BIOMES: int = 20       # сколько всего биомов (плиток земли)
const WILD: Array = [UNICORN, GROTTO, BIRCH, PINE, AUTUMN, SWAMP, FIELD]

# Раскладка: ряды сверху вниз (y = -4..4), столбцы слева направо (x = -6..6).
# Двор (0, 0) окружён кольцом пустых полей и лесов: до ближайших соседей идти далеко.
# Земли стоят далеко друг от друга — у каждой свой край, делить нечего, войн нет.
const GRID: Array = [
	[PINE, PINE, PINE, GROTTO, PINE, PINE, BIRCH, PINE, PINE, AUTUMN, BIRCH, UNICORN, UNICORN, UNICORN, BIRCH, PINE, PINE, GROTTO, PINE, PINE, PINE],
	[PINE, BIRCH, SWAMP, PINE, PINE, AUTUMN, PINE, BIRCH, BIRCH, PINE, PINE, UNICORN, UNICORN, BIRCH, PINE, AUTUMN, PINE, PINE, BIRCH, PINE, PINE],
	[BIRCH, PINE, PINE, BIRCH, AUTUMN, PINE, PINE, GROTTO, BIRCH, PINE, AUTUMN, AUTUMN, UNICORN, BIRCH, PINE, PINE, BIRCH, AUTUMN, PINE, GROTTO, PINE],
	[PINE, PINE, PINE, PINE, PINE, GROTTO, GROTTO, BIRCH, GOTHIC, GOTHIC, GOTHIC, AUTUMN, BIRCH, PINE, PINE, GROTTO, PINE, GROTTO, PINE, GROTTO, PINE],
	[PINE, BIRCH, PINE, DWARF, DWARF, PINE, GROTTO, AUTUMN, BIRCH, GOTHIC, AUTUMN, UNICORN, BIRCH, MAGE, MAGE, PINE, BIRCH, PINE, BIRCH, PINE, PINE],
	[BIRCH, PINE, AUTUMN, DWARF, DWARF, PINE, BIRCH, SPIDER, AUTUMN, MEADOW, BIRCH, UNICORN, UNICORN, MAGE, MAGE, BIRCH, AUTUMN, BIRCH, PINE, BIRCH, PINE],
	[PINE, AUTUMN, BIRCH, PINE, BIRCH, AUTUMN, FIELD, SPIDER, MEADOW, MEADOW, MEADOW, FIELD, BIRCH, AUTUMN, FIELD, GROTTO, JAPAN, JAPAN, AUTUMN, PINE, BIRCH],
	[SWAMP, BIRCH, PINE, SWAMP, FIELD, BIRCH, AUTUMN, MEADOW, MEADOW, HOME, MEADOW, MEADOW, FIELD, KNIGHT, FIELD, AUTUMN, JAPAN, JAPAN, BIRCH, PINE, AUTUMN],
	[SWAMP, SWAMP, BIRCH, SWAMP, ELF, ELF, BIRCH, FIELD, MEADOW, MEADOW, MEADOW, FIELD, KNIGHT, KNIGHT, BIRCH, PINE, JAPAN, JAPAN, PINE, BIRCH, PINE],
	[AUTUMN, SWAMP, PINE, SWAMP, ELF, ELF, AUTUMN, FIELD, FIELD, MEADOW, FIELD, BIRCH, KNIGHT, AUTUMN, FIELD, BIRCH, JAPAN, BIRCH, UNICORN, BIRCH, PINE],
	[PINE, AUTUMN, BIRCH, SWAMP, ELF, BIRCH, FIELD, FIELD, CATS, CATS, FIELD, AUTUMN, ORC, ORC, ORC, GROTTO, FIELD, AUTUMN, BIRCH, PINE, AUTUMN],
	[BIRCH, PINE, AUTUMN, BIRCH, SWAMP, UNICORN, UNICORN, AUTUMN, CATS, CATS, FIELD, BIRCH, ORC, ORC, ORC, PINE, BIRCH, PINE, PINE, BIRCH, PINE],
	[BEACH, BEACH, BEACH, BEACH, BEACH, BEACH, BEACH, BEACH, BEACH, BEACH, BEACH, BEACH, BEACH, BEACH, BEACH, BEACH, BEACH, BEACH, BEACH, BEACH, BEACH],
	[SEA, SEA, SEA, SEA, SEA, SEA, SEA, SEA, SEA, SEA, SEA, SEA, SEA, SEA, SEA, SEA, SEA, SEA, SEA, SEA, SEA],
]

# Цвет биома на карте (пергамент) и общий тон земли
const MAP_COL: Dictionary = {
	HOME: Color("8fae62"), MEADOW: Color("a3b86c"), SPIDER: Color("6a6278"), GOTHIC: Color("6e6670"),
	KNIGHT: Color("93b25e"), ELF: Color("6fae7a"), MAGE: Color("9a9cc8"), ORC: Color("c2a868"),
	DWARF: Color("9a9488"), CATS: Color("c9b874"), UNICORN: Color("e8a8c8"), GROTTO: Color("6a6880"),
	BIRCH: Color("b4c87c"), PINE: Color("5e8a64"), AUTUMN: Color("d0985a"), SWAMP: Color("6e8a6a"), FIELD: Color("d8cc78"),
	JAPAN: Color("e8a0b0"), BEACH: Color("ecdca0"), SEA: Color("5a9ac8"),
}

# Дороги: опорные точки. Между ними дорога петляет (road_curves), в опорных точках — ровно
# проходит через точку, поэтому развилки сходятся без швов. Первое число — полуширина.
const ROADS: Array = [
	# тропинки из двора (узкие): на юг к кошкам и на запад к паучихам
	[14.0, Vector2(960, 1640), Vector2(960, 1780), Vector2(1150, 1900), Vector2(760, 2800), Vector2(120, 3500), Vector2(-940, 4300)],
	[14.0, Vector2(150, 596), Vector2(-700, 420), Vector2(-1700, -60), Vector2(-2720, -380)],
	# кошки: деревня ↔ городок
	[20.0, Vector2(-940, 4300), Vector2(-200, 4500), Vector2(630, 4260)],
	# паучихи → дворфы
	[22.0, Vector2(-2720, -380), Vector2(-4300, -1300), Vector2(-6500, -2500), Vector2(-8760, -3230)],
	# паучихи → готика (замок и городок)
	[22.0, Vector2(-2720, -380), Vector2(-2300, -2000), Vector2(-900, -3300), Vector2(60, -4100), Vector2(1400, -4260)],
	# к особняку вампирш
	[18.0, Vector2(60, -4100), Vector2(-1000, -4300), Vector2(-1900, -4520)],
	# готика → маги
	[22.0, Vector2(1400, -4260), Vector2(3300, -3500), Vector2(5200, -2700), Vector2(7400, -3000), Vector2(8240, -3200), Vector2(10540, -3160)],
	# маги → рыцари
	[22.0, Vector2(8240, -3200), Vector2(7900, -1400), Vector2(8520, 700), Vector2(8620, 1660)],
	# двор → рыцари (через поля)
	[18.0, Vector2(1150, 1900), Vector2(3000, 2100), Vector2(5000, 1600), Vector2(6720, 1870), Vector2(8620, 1660)],
	# рыцари → орки → гоблины
	[22.0, Vector2(8620, 1660), Vector2(8300, 3200), Vector2(7300, 4500), Vector2(6740, 5540)],
	[20.0, Vector2(6740, 5540), Vector2(8990, 5300), Vector2(10870, 5560)],
	# кошки → орки
	[20.0, Vector2(630, 4260), Vector2(2500, 4700), Vector2(4700, 5100), Vector2(6740, 5540)],
	# кошки → эльфы
	[22.0, Vector2(-940, 4300), Vector2(-3000, 3800), Vector2(-5600, 3300), Vector2(-8540, 3120)],
	# эльфы → паучихи
	[18.0, Vector2(-8540, 3120), Vector2(-7000, 1500), Vector2(-4600, 600), Vector2(-2720, -380)],
	# тропы к диким местам
	[14.0, Vector2(-8540, 3120), Vector2(-9800, 1800), Vector2(-10560, 640)],
	[14.0, Vector2(-8760, -3230), Vector2(-6600, -4200), Vector2(-4800, -4480)],
	[14.0, Vector2(5200, -2700), Vector2(4800, -1920)],
	[14.0, Vector2(8620, 1660), Vector2(10500, 800), Vector2(12480, -640)],
	[14.0, Vector2(10500, 800), Vector2(11800, 2000), Vector2(12480, 3200)],
	[14.0, Vector2(-3000, 3800), Vector2(-4200, 4800), Vector2(-4800, 5760)],
	[14.0, Vector2(-4600, 600), Vector2(-4800, 1920)],
	[14.0, Vector2(-4600, 600), Vector2(-3800, 1500), Vector2(-2880, 1920)],
	# v25: от развилки у Сумеречья на север — в Понивилль (Эквестрия)
	[20.0, Vector2(3300, -3500), Vector2(4200, -4900), Vector2(5300, -6100), Vector2(6100, -7000)],
	# к японским землям и к морю
	[20.0, Vector2(10500, 800), Vector2(13600, 1100), Vector2(16320, 640)],
	[18.0, Vector2(630, 4260), Vector2(760, 5400), Vector2(960, 6400), Vector2(960, 7400)],
	# выход со двора: прямая дорожка как во дворе (ширина 30), потом плавно сужается до тропинки
	[30.0, Vector2(960, 1100), Vector2(960, 1400)],
	[26.0, Vector2(960, 1400), Vector2(960, 1500)],
	[21.0, Vector2(960, 1500), Vector2(960, 1580)],
	[17.0, Vector2(960, 1580), Vector2(960, 1650)],
]
## Дороги с этого номера идут строго прямо, без изгибов
const STRAIGHT_FROM: int = 25
const ROAD_HW: float = 22.0   # полуширина большой дороги
# центры городов (площади). Внутри TOWN_R дорога не рисуется — там свои улицы города
const TOWN_C: Dictionary = {
	"cats": Vector2(630, 4260), "spider": Vector2(-2720, -380), "gothic": Vector2(1400, -4260), "knights": Vector2(8620, 1660),
	"elves": Vector2(-8540, 3120), "mages": Vector2(10540, -3160), "orcs": Vector2(6740, 5540), "goblins": Vector2(10870, 5560),
	"dwarves": Vector2(-8760, -3230), "japan": Vector2(16320, 640), "ponies": Vector2(6100, -7000),
}
const PIER: Vector2 = Vector2(960, 7560)      # пирс с водолазным колоколом: спуск под воду
const TOWN_R: float = 820.0
const RCELL: int = 8          # клетка карты дорог (world_road.png): пикселей мира

# Главные места (иконки на карте): [x, y, вид]
const LANDMARKS: Array = [
	[960, 300, "home"],
	[-960, 4460, "cats"],
	[-2880, -640, "spider"],
	[0, -4510, "gothic"],
	[-1900, -4560, "gothic"],
	[6720, 1680, "castle"],
	[8520, 680, "castle"],
	[-6740, 2960, "elf"],
	[8240, -3230, "mage"],
	[8440, 5260, "orc"],
	[10140, 5560, "goblin"],
	[-10360, -3180, "dwarf"],
	[4800, -1920, "unicorn"],
	[-4800, 5760, "unicorn"],
	[-4800, -4480, "cave"],
	[-10560, -8320, "cave"],
	[12480, -640, "cave"],
	[-4800, 1920, "hermit"],
	[12480, 3200, "hermit"],
	[-2880, 1920, "outcast"],
	[-10560, 640, "outcast"],
	[16320, 520, "japan"],
	[960, 7560, "pier"],
]

static var _curves: Array = []
static var _rimg: Image = null


## Дороги как плотные ломаные (точка каждые ~40 пикселей): петляют между опорными точками
static func road_curves() -> Array:
	if not _curves.is_empty():
		return _curves
	for i in range(ROADS.size()):
		var rd: Array = ROADS[i]
		var hw: float = float(rd[0])
		var cp: Array = rd.slice(1)
		var out: PackedVector2Array = PackedVector2Array()
		for j in range(cp.size() - 1):
			var p0: Vector2 = cp[maxi(j - 1, 0)]
			var p1: Vector2 = cp[j]
			var p2: Vector2 = cp[j + 1]
			var p3: Vector2 = cp[mini(j + 2, cp.size() - 1)]
			var ln: float = p1.distance_to(p2)
			var n: int = maxi(2, int(ln / 40.0))
			var hs: int = (i * 7919 + j * 104729) % 1000
			var amp: float = clampf(ln * 0.07, 24.0, 150.0) * (1.0 if hs % 2 == 0 else -1.0)
			if i >= STRAIGHT_FROM:
				amp = 0.0
			var k: float = 1.0 if hs % 3 != 0 else 2.0
			for s in range(n + (1 if j == cp.size() - 2 else 0)):
				var t: float = float(s) / float(n)
				var t2: float = t * t
				var t3: float = t2 * t
				var q: Vector2 = 0.5 * ((2.0 * p1) + (p2 - p0) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 + (3.0 * p1 - p0 - 3.0 * p2 + p3) * t3)
				var tg: Vector2 = 0.5 * ((p2 - p0) + 2.0 * (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t + 3.0 * (3.0 * p1 - p0 - 3.0 * p2 + p3) * t2)
				var nrm: Vector2 = tg.normalized().orthogonal()
				var off: float = amp * sin(PI * k * t) + amp * 0.22 * sin(PI * 3.0 * t + 0.0) * sin(PI * t)
				out.append(q + nrm * off)
		_curves.append([hw, out])
	return _curves


## Точки вдоль дорог через каждые step пикселей: [точка, нормаль]
static func road_points(step: float) -> Array:
	var res: Array = []
	for c in road_curves():
		var pts: PackedVector2Array = c[1]
		var acc: float = step * 0.5
		for i in range(pts.size() - 1):
			var a: Vector2 = pts[i]
			var b: Vector2 = pts[i + 1]
			var ln: float = a.distance_to(b)
			while acc < ln:
				res.append([a.lerp(b, acc / ln), (b - a).normalized().orthogonal()])
				acc += step
			acc -= ln
	return res


## Точное расстояние до края дороги (минус — на дороге). Медленно: только для генератора картинок.
static func road_value_raw(p: Vector2) -> float:
	var best: float = 99999.0
	for c in road_curves():
		var pts: PackedVector2Array = c[1]
		for i in range(pts.size() - 1):
			best = minf(best, seg_dist(p, pts[i], pts[i + 1]) - float(c[0]))
	return best


## Расстояние до края ближайшей дороги (минус — на дороге), края чуть волнистые.
## Берётся из готовой карты дорог (art/world_road.png), поэтому быстро.
static func road_value(p: Vector2) -> float:
	if _rimg == null:
		if not ResourceLoader.exists("res://art/world_road.png"):
			return road_value_raw(p)
		_rimg = (load("res://art/world_road.png") as Texture2D).get_image()
		if _rimg.is_compressed():
			_rimg.decompress()
	var f: Vector2 = (p - ORIGIN) / float(RCELL) - Vector2(0.5, 0.5)
	var x0: int = int(floor(f.x))
	var y0: int = int(floor(f.y))
	var w: int = _rimg.get_width()
	var h: int = _rimg.get_height()
	if x0 < 0 or y0 < 0 or x0 + 1 >= w or y0 + 1 >= h:
		return 999.0
	var fx: float = f.x - x0
	var fy: float = f.y - y0
	var v: float = lerpf(lerpf(_rimg.get_pixel(x0, y0).r, _rimg.get_pixel(x0 + 1, y0).r, fx), lerpf(_rimg.get_pixel(x0, y0 + 1).r, _rimg.get_pixel(x0 + 1, y0 + 1).r, fx), fy)
	var wob: float = sin(p.x * 0.05) * 3.0 + cos(p.y * 0.043) * 3.0
	return v * 128.0 - 32.0 + wob


static func region_of(p: Vector2) -> Vector2i:
	return Vector2i(int(floor(p.x / RW)), int(floor(p.y / RH)))


static func in_world(p: Vector2) -> bool:
	return Rect2(ORIGIN, SIZE).has_point(p)


static func biome_of_region(r: Vector2i) -> int:
	var cx: int = r.x - GX0
	var cy: int = r.y - GY0
	if cx < 0 or cy < 0 or cx >= COLS or cy >= ROWS:
		return -1
	return int((GRID[cy] as Array)[cx])


static func region_rect(r: Vector2i) -> Rect2:
	return Rect2(Vector2(r.x * RW, r.y * RH), Vector2(RW, RH))


static func seg_dist(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab: Vector2 = b - a
	var t: float = 0.0
	if ab.length_squared() > 0.0:
		t = clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
	return p.distance_to(a + ab * t)


## Биом в точке мира: границы регионов размыты «волной», чтобы не было ровных линий
static func biome_at(p: Vector2) -> int:
	var q: Vector2 = p + Vector2(sin(p.y * 0.0047 + 1.3) * 150.0 + sin(p.y * 0.017) * 40.0, sin(p.x * 0.0041 + 0.7) * 120.0 + sin(p.x * 0.019) * 30.0)
	var b: int = biome_of_region(region_of(q))
	if b < 0:
		b = biome_of_region(region_of(p))
	# двор (его земля нарисована отдельно) окружён полосой луга: так край двора мягко переходит в мир
	var hd: Vector2 = (p - Vector2(RW / 2.0, RH / 2.0)).abs() - Vector2(RW / 2.0, RH / 2.0)
	var out: float = maxf(hd.x, hd.y)
	if b == HOME or out < 220.0 + sin(p.x * 0.011 + p.y * 0.007) * 70.0 + sin(p.y * 0.023 + 1.0) * 45.0 + sin(p.x * 0.019) * 45.0:
		b = MEADOW
	return maxi(b, 0)

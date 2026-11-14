extends RefCounted
## Раскладка мира: где тропы, пруд, дом, огород.
## Используют и генератор картинок, и сама игра, чтобы всё совпадало.
## Единица — пиксель арта. Камера показывает мир с увеличением x2.

const W: int = 1920
const H: int = 1280

const HOUSE_POS: Vector2 = Vector2(960, 358)      # «ноги» дома (низ фундамента)
const DOOR_POS: Vector2 = Vector2(960, 372)
const POND_C: Vector2 = Vector2(500, 860)
const POND_R: Vector2 = Vector2(196, 122)
const WELL_POS: Vector2 = Vector2(1210, 884)
const GATE_Y: float = 1200.0

# Отрезки троп: [начало, конец, полуширина]
const PATHS: Array = [
	[Vector2(960, 350), Vector2(960, 1400), 30.0],
	[Vector2(960, 600), Vector2(1186, 594), 22.0],
	[Vector2(960, 760), Vector2(712, 826), 22.0],
	[Vector2(960, 940), Vector2(1160, 904), 18.0],
	# тропа на запад — к паутинному лесу и дальше в большой мир
	[Vector2(960, 600), Vector2(-60, 596), 20.0],
]

# Огород: 2 ряда по 4 грядки (точка — низ грядки)
const PLOT_COLS: Array = [1250, 1342, 1434, 1526]
const PLOT_ROWS: Array = [566, 668]
const GARDEN_RECT: Rect2 = Rect2(1198, 500, 380, 182)

# Где герой может ходить
const WALK_RECT: Rect2 = Rect2(140, 344, 1640, 836)


static func seg_dist(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab: Vector2 = b - a
	var t: float = 0.0
	if ab.length_squared() > 0.0:
		t = clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
	return p.distance_to(a + ab * t)


## < 0 внутри тропы (в пикселях от края)
static func path_value(p: Vector2) -> float:
	var best: float = 9999.0
	for s in PATHS:
		var a: Vector2 = s[0]
		var b: Vector2 = s[1]
		var r: float = s[2]
		best = minf(best, seg_dist(p, a, b) - r)
	var q: Vector2 = (p - Vector2(960, 404)) / Vector2(96, 46)
	best = minf(best, (q.length() - 1.0) * 46.0)
	var wob: float = sin(p.x * 0.115) * 2.4 + cos(p.y * 0.095) * 2.4 + sin((p.x + p.y) * 0.035) * 3.2
	return best + wob


## < 0 внутри пруда (доля радиуса)
static func pond_value(p: Vector2) -> float:
	var q: Vector2 = (p - POND_C) / POND_R
	var ang: float = atan2(q.y, q.x)
	var wob: float = sin(ang * 3.0 + 0.6) * 0.07 + sin(ang * 5.0 + 2.0) * 0.04
	return q.length() - 1.0 - wob


static func is_path(p: Vector2) -> bool:
	return path_value(p) < 0.0


static func is_pond(p: Vector2) -> bool:
	return pond_value(p) < 0.0


## Место занято (для расстановки декора и трав)
static func is_busy(p: Vector2, margin: float = 16.0) -> bool:
	if path_value(p) < margin:
		return true
	if pond_value(p) < margin / 120.0 + 0.14:
		return true
	if Rect2(760, 110, 400, 300).has_point(p):
		return true
	if GARDEN_RECT.grow(margin + 12.0).has_point(p):
		return true
	if p.distance_to(WELL_POS) < 52.0 + margin:
		return true
	return false

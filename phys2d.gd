extends RefCounted
## Простая физика твёрдых тел для окон (v19): предмет — прямоугольник, который падает, крутится,
## отскакивает от пола и стен, трётся и ложится на бок. Тела — словари:
## {"pos": центр, "vel", "ang", "av" (угловая скорость), "hx", "hy" (полуширина/полувысота), "sleep"}
## Столкновение с полом и стенами — по углам прямоугольника (импульс в точке касания: так он и вращается).
## Друг с другом — кругами (чтобы не проваливались и толкались).

const GRAV: float = 1900.0
const REST: float = 0.32          # упругость отскока
const FRIC: float = 0.55          # трение о пол
const AIR: float = 0.06           # сопротивление воздуха
const ADAMP: float = 0.6          # затухание вращения


static func make(center: Vector2, size: Vector2, vel: Vector2 = Vector2.ZERO, av: float = 0.0, ang: float = 0.0) -> Dictionary:
	return {"pos": center, "vel": vel, "ang": ang, "av": av, "hx": maxf(4.0, size.x * 0.5), "hy": maxf(4.0, size.y * 0.5), "sleep": 0.0}


static func corners(b: Dictionary) -> Array:
	var c: Vector2 = b["pos"]
	var a: float = float(b["ang"])
	var hx: float = float(b["hx"])
	var hy: float = float(b["hy"])
	var out: Array = []
	for s in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
		out.append(c + Vector2(hx * s.x, hy * s.y).rotated(a))
	return out


static func _inertia(b: Dictionary) -> float:
	var w: float = float(b["hx"]) * 2.0
	var h: float = float(b["hy"]) * 2.0
	return (w * w + h * h) / 12.0


static func _cross(a: Vector2, b: Vector2) -> float:
	return a.x * b.y - a.y * b.x


## Импульс в точке касания с неподвижной поверхностью (нормаль n смотрит из поверхности к телу)
static func _contact(b: Dictionary, p: Vector2, n: Vector2, depth: float, count: int) -> void:
	var I: float = _inertia(b)
	var r: Vector2 = p - Vector2(b["pos"])
	var v: Vector2 = b["vel"]
	var w: float = float(b["av"])
	var vp: Vector2 = v + Vector2(-w * r.y, w * r.x)
	var vn: float = vp.dot(n)
	# выталкиваем из пола
	b["pos"] = Vector2(b["pos"]) + n * depth * (0.85 / float(count))
	if vn >= 0.0:
		return
	var rn: float = _cross(r, n)
	var e: float = REST if vn < -160.0 else 0.0
	var j: float = -(1.0 + e) * vn / (1.0 + rn * rn / I)
	v += n * j
	w += rn * j / I
	# трение
	var tg: Vector2 = Vector2(-n.y, n.x)
	var vp2: Vector2 = v + Vector2(-w * r.y, w * r.x)
	var vt: float = vp2.dot(tg)
	var rt: float = _cross(r, tg)
	var jt: float = -vt / (1.0 + rt * rt / I)
	jt = clampf(jt, -FRIC * j, FRIC * j)
	v += tg * jt
	w += rt * jt / I
	b["vel"] = v
	b["av"] = w


## Один шаг: гравитация, полёт, удары о пол (floor_y) и стены (left/right). Возвращает true, если ударилось сильно.
static func step(b: Dictionary, dt: float, floor_y: float, left: float, right: float) -> bool:
	var hard: bool = false
	# уснувшее тело лежит, пока его не толкнут
	if float(b["sleep"]) > 0.5 and Vector2(b["vel"]) == Vector2.ZERO and float(b["av"]) == 0.0:
		return false
	var sub: int = 2
	var h: float = dt / float(sub)
	for s in range(sub):
		var v: Vector2 = b["vel"]
		v.y += GRAV * h
		v *= (1.0 - AIR * h)
		b["vel"] = v
		b["av"] = float(b["av"]) * (1.0 - ADAMP * h)
		b["pos"] = Vector2(b["pos"]) + v * h
		b["ang"] = float(b["ang"]) + float(b["av"]) * h
		# пол: последовательные импульсы по углам (две итерации — чтобы не «тонул» и не дрожал)
		if Vector2(b["vel"]).y > 420.0 and _lowest(b) > floor_y:
			hard = true
		for it in range(2):
			var hits: Array = []
			for c in corners(b):
				if (c as Vector2).y > floor_y:
					hits.append(c)
			for c2 in hits:
				_contact(b, c2, Vector2(0, -1), (c2 as Vector2).y - floor_y, hits.size())
		# стены
		for c3 in corners(b):
			if (c3 as Vector2).x < left:
				_contact(b, c3, Vector2(1, 0), left - (c3 as Vector2).x, 1)
			elif (c3 as Vector2).x > right:
				_contact(b, c3, Vector2(-1, 0), (c3 as Vector2).x - right, 1)
	# успокоился на полу: замирает (без мелкой дрожи)
	if Vector2(b["vel"]).length() < 14.0 and absf(float(b["av"])) < 0.25 and _lowest(b) > floor_y - 2.0:
		b["sleep"] = float(b["sleep"]) + dt
		if float(b["sleep"]) > 0.25:
			b["vel"] = Vector2.ZERO
			b["av"] = 0.0
	else:
		b["sleep"] = 0.0
	return hard


static func _lowest(b: Dictionary) -> float:
	var m: float = -1e9
	for c in corners(b):
		m = maxf(m, (c as Vector2).y)
	return m


static func resting(b: Dictionary) -> bool:
	return float(b["sleep"]) > 0.25


## Тела толкают друг друга (как круги)
static func collide_all(bodies: Array) -> void:
	for i in range(bodies.size()):
		var a: Dictionary = bodies[i]
		var ra: float = minf(float(a["hx"]), float(a["hy"])) * 0.95
		for j in range(i + 1, bodies.size()):
			var c: Dictionary = bodies[j]
			var rc: float = minf(float(c["hx"]), float(c["hy"])) * 0.95
			var d: Vector2 = Vector2(c["pos"]) - Vector2(a["pos"])
			var dist: float = d.length()
			var need: float = ra + rc
			if dist >= need or dist < 0.01:
				continue
			var n: Vector2 = d / dist
			var push: float = (need - dist) * 0.5
			a["pos"] = Vector2(a["pos"]) - n * push
			c["pos"] = Vector2(c["pos"]) + n * push
			var rv: float = (Vector2(c["vel"]) - Vector2(a["vel"])).dot(n)
			if rv < 0.0:
				var jj: float = -(1.0 + 0.3) * rv * 0.5
				a["vel"] = Vector2(a["vel"]) - n * jj
				c["vel"] = Vector2(c["vel"]) + n * jj
				# касательное — закручивает
				var tg: Vector2 = Vector2(-n.y, n.x)
				var vt: float = (Vector2(c["vel"]) - Vector2(a["vel"])).dot(tg)
				a["av"] = float(a["av"]) + vt * 0.004
				c["av"] = float(c["av"]) - vt * 0.004
				a["sleep"] = 0.0
				c["sleep"] = 0.0


## Точка внутри повёрнутого прямоугольника тела (для клика мышкой)
static func has_point(b: Dictionary, p: Vector2, grow: float = 6.0) -> bool:
	var l: Vector2 = (p - Vector2(b["pos"])).rotated(-float(b["ang"]))
	return absf(l.x) <= float(b["hx"]) + grow and absf(l.y) <= float(b["hy"]) + grow


## Скорость броска по последним движениям мыши
static func throw_vel(trail: Array) -> Vector2:
	if trail.size() < 2:
		return Vector2.ZERO
	var a: Array = trail[0]
	var b: Array = trail[trail.size() - 1]
	var dt: float = maxf(0.016, float(b[1]) - float(a[1]))
	var v: Vector2 = (Vector2(b[0]) - Vector2(a[0])) / dt
	return v.limit_length(2600.0)

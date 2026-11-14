extends Node2D
## Рыбалка в мире, всё пикселями: удочка, леска, поплавок, круги на воде, прицел.
## Ничего не пишет — только рисует. Данные берёт у fishing_ui.

var ui: Node


func _ready() -> void:
	z_index = 60
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _process(_delta: float) -> void:
	visible = ui != null and bool(ui.call("is_open"))
	if visible:
		queue_redraw()


func _dot(p: Vector2, c: Color) -> void:
	draw_rect(Rect2(floorf(p.x), floorf(p.y), 1, 1), c)


func _pline(a: Vector2, b: Vector2, c: Color) -> void:
	var n: int = int(maxf(absf(b.x - a.x), absf(b.y - a.y)))
	if n <= 0:
		_dot(a, c)
		return
	for i in range(n + 1):
		_dot(a.lerp(b, float(i) / float(n)), c)


func _ring(c: Vector2, r: float, col: Color) -> void:
	var n: int = maxi(12, int(r * 4.0))
	for i in range(n):
		var a: float = TAU * float(i) / float(n)
		_dot(Vector2(c.x + cos(a) * r, c.y + sin(a) * r * 0.55), col)


func _bobber(p: Vector2) -> void:
	draw_rect(Rect2(floorf(p.x) - 1, floorf(p.y) - 3, 2, 2), Color("d8503a"))
	draw_rect(Rect2(floorf(p.x) - 1, floorf(p.y) - 1, 2, 2), Color("f0e8d8"))
	_dot(Vector2(p.x - 1, p.y - 3), Color("f08a70"))


func _draw() -> void:
	if ui == null:
		return
	var st: int = int(ui.get("state"))
	var shore: Vector2 = ui.get("shore_p")
	var dir: Vector2 = ui.call("aim_dir")
	var land: Vector2 = ui.call("landing")
	var t: float = float(ui.get("t_state"))
	var base: Vector2 = shore + Vector2(0, -14)
	var tip: Vector2 = base + dir * 15.0 + Vector2(0, -12)
	# удочка
	_pline(base, tip, Color("7a5030"))
	_pline(base + Vector2(0, -1), tip + Vector2(0, -1), Color("a4764a"))
	_dot(base + Vector2(1, -2), Color("56525c"))
	var line_c: Color = Color(1, 1, 1, 0.9)
	match st:
		1:
			# прицел ходит по воде туда-сюда
			var blink: bool = int(t * 5.0) % 2 == 0
			var cc: Color = Color("fff6c0") if blink else Color("e8b84a")
			for k in range(-2, 3):
				_dot(land + Vector2(k, 0), cc)
				_dot(land + Vector2(0, k), cc)
			_dot(land, Color("3a2718"))
			_pline(tip, tip + Vector2(0, 8), line_c)
			_bobber(tip + Vector2(0, 11))
		2:
			var f: float = clampf(t / 0.55, 0.0, 1.0)
			var bp: Vector2 = tip.lerp(land, f) + Vector2(0, -sin(f * PI) * 26.0)
			_pline(tip, bp, line_c)
			_bobber(bp)
		3, 4, 5:
			var bob: float = 0.0
			var side: float = 0.0
			if st == 3:
				bob = sin(t * 3.0) * 0.8
			elif st == 4:
				bob = 2.0 + sin(t * 40.0) * 0.8
			else:
				side = sin(t * 18.0) * 1.5
				bob = 1.0
			var bp2: Vector2 = land + Vector2(side, bob)
			var speed: float = 1.8 if st == 4 else 0.55
			var n: int = 3
			for k2 in range(n):
				var ph: float = fmod(t * speed + float(k2) / float(n), 1.0)
				_ring(land, 2.0 + ph * 12.0, Color(1, 1, 1, (1.0 - ph) * 0.75))
			var mid: Vector2 = tip.lerp(bp2, 0.5) + Vector2(0, 0.0 if st == 5 else 5.0)
			_pline(tip, mid, line_c)
			_pline(mid, bp2 + Vector2(0, -3), line_c)
			_bobber(bp2)
		8:
			var f2: float = clampf(t / 0.5, 0.0, 1.0)
			var bp3: Vector2 = land.lerp(tip, f2) + Vector2(0, -sin(f2 * PI) * 12.0)
			_pline(tip, bp3, line_c)
			_bobber(bp3)
		6:
			# пойманная рыба блестит над водой
			var fp: Vector2 = land + Vector2(0, -8.0 - sin(t * 6.0) * 2.0)
			_pline(tip, fp, line_c)
			for k3 in range(4):
				var ang: float = t * 3.0 + float(k3) * TAU / 4.0
				_dot(fp + Vector2(cos(ang) * 8.0, sin(ang) * 5.0), Color("fff6c0"))

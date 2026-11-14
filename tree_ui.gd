extends CanvasLayer
## Окно веточек (v17): подошла к дереву, нажала E (или ПКМ по дереву) — открываются ветки с листьями.
## Листики рвут по одному кликом и они летят в сумку. На яблоне (и других плодовых деревьях) висят плоды — их тоже срывают.
## Сорванное отрастает: листья через 2 дня, плоды через 2-4 дня. Без надписей — всё картинками.

const TD = preload("res://tree_db.gd")
const FD = preload("res://food_db.gd")
const IT = preload("res://items_db.gd")
const W: float = 1180.0
const H: float = 720.0
const ORG: Vector2 = Vector2(370, 180)
const LEAF_SC: float = 2.6
const LEAF_BACK_DAYS: int = 2

var root: Control
var canvas: Control
var is_open: bool = false
var tex: String = ""
var key: String = ""
var twigs: Array = []        # [{pts: PackedVector2Array, w: float}]
var items: Array = []        # [{kind: "leaf"/"fruit", idx, pos, ang, frame, id, rect, gone}]
var flying: Array = []       # летящее в сумку: {tex, from, t, id, rot}
var hover: int = -1
var leaf_tex: Texture2D
var bag_tex: Texture2D
var t: float = 0.0
var taken_now: int = 0


func _ready() -> void:
	layer = 24
	add_to_group("tree_ui")
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.visible = false
	add_child(root)
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0.02, 0.05, 0.03, 0.62)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(dim)
	canvas = Control.new()
	canvas.position = ORG
	canvas.size = Vector2(W, H)
	canvas.mouse_filter = Control.MOUSE_FILTER_STOP
	canvas.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	canvas.clip_contents = true
	canvas.draw.connect(_draw_all)
	canvas.gui_input.connect(_on_input)
	root.add_child(canvas)
	bag_tex = load("res://art/icon_pack.png")


func _process(delta: float) -> void:
	if not is_open:
		return
	t += delta
	for i in range(flying.size() - 1, -1, -1):
		flying[i]["t"] = float(flying[i]["t"]) + delta / 0.55
		if float(flying[i]["t"]) >= 1.0:
			var id: String = String(flying[i]["id"])
			flying.remove_at(i)
			Game.add_item(id)
			taken_now += 1
	canvas.queue_redraw()


# ------------------------------------------------------------------ открыть

## Есть ли чем поживиться на этом дереве
func can_open(tx: String) -> bool:
	return TD.has(tx)


func open_for(tree: Sprite2D) -> bool:
	if tree == null or tree.texture == null:
		return false
	var tx: String = tree.texture.resource_path.get_file().get_basename()
	return open_tree(tx, "%s:%d,%d" % [tx, int(round(tree.global_position.x)), int(round(tree.global_position.y))])


func open_tree(tx: String, k: String) -> bool:
	if not TD.has(tx) or is_open or Game.ui_open or Game.busy:
		return false
	tex = tx
	key = k
	leaf_tex = load("res://art/leafw_%s.png" % tx)
	_build()
	is_open = true
	taken_now = 0
	Game.ui_open = true
	root.visible = true
	root.modulate.a = 0.0
	create_tween().tween_property(root, "modulate:a", 1.0, 0.18)
	Sound.play("page", -8.0, 0.2)
	return true


func close() -> void:
	if not is_open:
		return
	# что ещё летит — сразу в сумку
	for fl in flying:
		Game.add_item(String(fl["id"]))
	flying.clear()
	is_open = false
	Game.ui_open = false
	root.visible = false


## Состояние дерева (сколько и что сорвано)
func _state() -> Dictionary:
	if not Game.tree_state.has(key):
		Game.tree_state[key] = {"leaf": {}, "fruit": {}}
	return Game.tree_state[key]


func _leaf_there(idx: int) -> bool:
	var d: Dictionary = _state()["leaf"]
	return not d.has(idx) or Game.day - int(d[idx]) >= LEAF_BACK_DAYS


func _fruit_there(idx: int) -> bool:
	var d: Dictionary = _state()["fruit"]
	var back: int = int((TD.TREES[tex] as Array)[4])
	return not d.has(idx) or Game.day - int(d[idx]) >= back


# ------------------------------------------------------------------ ветки: у каждого дерева свои, но всегда одни и те же

func _build() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = hash(key)
	twigs.clear()
	items.clear()
	flying.clear()
	var n_tw: int = 5
	var fruits_total: int = int((TD.TREES[tex] as Array)[3]) * 2
	var fruit_slots: Array = []
	for i in range(fruits_total):
		fruit_slots.append(i)
	var li: int = 0
	var fi: int = 0
	for ti in range(n_tw):
		var y0: float = 80.0 + ti * 130.0 + rng.randf_range(-14.0, 14.0)
		var p0: Vector2 = Vector2(-20.0, y0 + rng.randf_range(40.0, 120.0))
		var p1: Vector2 = Vector2(W * 0.3, y0 + rng.randf_range(-60.0, 60.0))
		var p2: Vector2 = Vector2(W * 0.62, y0 + rng.randf_range(-80.0, 40.0))
		var p3: Vector2 = Vector2(W - 70.0 - rng.randf_range(0.0, 130.0), y0 + rng.randf_range(-70.0, 30.0))
		var pts: PackedVector2Array = PackedVector2Array()
		for s in range(33):
			var u: float = float(s) / 32.0
			pts.append(_bez(p0, p1, p2, p3, u))
		twigs.append({"pts": pts, "w": 9.0 - ti * 0.3})
		# листья вдоль ветки, по очереди сверху и снизу
		var n_leaf: int = rng.randi_range(6, 8)
		for k in range(n_leaf):
			var u2: float = 0.22 + 0.74 * float(k) / float(n_leaf) + rng.randf_range(-0.02, 0.02)
			var pa: Vector2 = _bez(p0, p1, p2, p3, u2)
			var pb: Vector2 = _bez(p0, p1, p2, p3, u2 + 0.02)
			var tan: Vector2 = (pb - pa).normalized()
			var side: float = -1.0 if k % 2 == 0 else 1.0
			var ang: float = tan.angle() + side * rng.randf_range(0.7, 1.25)
			var stem: float = rng.randf_range(10.0, 22.0)
			var base: Vector2 = pa + Vector2.from_angle(ang) * stem
			var fr: int = posmod(int(round(-ang / (PI / 4.0))) + 1, 8)
			items.append({"kind": "leaf", "idx": li, "pos": base, "from": pa, "ang": ang, "frame": fr, "id": TD.leaf_id(tex), "gone": false})
			li += 1
		# плоды: висят под веткой
		if fi < fruits_total and TD.TREES[tex][2].size() > 0:
			var per: int = mini(2, fruits_total - fi)
			for q in range(per):
				var u3: float = 0.35 + 0.28 * q + rng.randf_range(-0.05, 0.05)
				var pf: Vector2 = _bez(p0, p1, p2, p3, u3)
				var fid: String = TD.pick_fruit(tex, float(abs(hash("%s#%d" % [key, fi])) % 1000) / 1000.0)
				items.append({"kind": "fruit", "idx": fi, "pos": pf + Vector2(0, 54), "from": pf, "ang": 0.0, "frame": 0, "id": fid, "gone": false})
				fi += 1


func _bez(a: Vector2, b: Vector2, c: Vector2, d: Vector2, u: float) -> Vector2:
	var uu: float = clampf(u, 0.0, 1.0)
	var q0: Vector2 = a.lerp(b, uu)
	var q1: Vector2 = b.lerp(c, uu)
	var q2: Vector2 = c.lerp(d, uu)
	return q0.lerp(q1, uu).lerp(q1.lerp(q2, uu), uu)


func _alive(it: Dictionary) -> bool:
	if bool(it["gone"]):
		return false
	return _leaf_there(int(it["idx"])) if String(it["kind"]) == "leaf" else _fruit_there(int(it["idx"]))


func _rect_of(it: Dictionary) -> Rect2:
	var p: Vector2 = it["pos"]
	if String(it["kind"]) == "leaf":
		var s: float = 28.0 * LEAF_SC
		return Rect2(p - Vector2(s, s) * 0.5, Vector2(s, s))
	var s2: float = 32.0 * 2.0
	return Rect2(p - Vector2(s2, s2) * 0.5, Vector2(s2, s2))


# ------------------------------------------------------------------ рисование

func _draw_all() -> void:
	var c: Control = canvas
	# листва за окном: тёмный лес, светлые пятна
	c.draw_rect(Rect2(0, 0, W, H), Color("1d3524"))
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = hash(key) + 7
	for i in range(46):
		var bp: Vector2 = Vector2(rng.randf() * W, rng.randf() * H)
		var br: float = rng.randf_range(40.0, 120.0)
		c.draw_circle(bp, br, Color(0.20 + rng.randf() * 0.1, 0.36 + rng.randf() * 0.12, 0.22, 0.28))
	for i in range(30):
		var sp: Vector2 = Vector2(rng.randf() * W, rng.randf() * H * 0.6)
		c.draw_circle(sp, rng.randf_range(10.0, 30.0), Color(1.0, 0.95, 0.7, 0.07))
	# рамка
	c.draw_rect(Rect2(0, 0, W, H), Color("3a2718"), false, 8.0)
	c.draw_rect(Rect2(8, 8, W - 16, H - 16), Color("8a6a40"), false, 3.0)
	# ветки: тёмная кромка, коричневая сердцевина, светлая полоска сверху
	for tw in twigs:
		var pts: PackedVector2Array = tw["pts"]
		var w: float = float(tw["w"])
		c.draw_polyline(pts, Color("2a1a10"), w + 4.0, false)
		c.draw_polyline(pts, Color("6a4a2a"), w, false)
		var up: PackedVector2Array = PackedVector2Array()
		for p in pts:
			up.append(p + Vector2(0, -w * 0.28))
		c.draw_polyline(up, Color("9a7440"), maxf(2.0, w * 0.3), false)
	# черенки, листья, плоды
	var mp: Vector2 = canvas.get_local_mouse_position()
	for i in range(items.size()):
		var it: Dictionary = items[i]
		if not _alive(it):
			# след на ветке — маленький бугорок
			c.draw_circle(it["from"], 4.0, Color("2a1a10"))
			c.draw_circle(it["from"], 2.6, Color("6a4a2a"))
			continue
		var hot: bool = i == hover
		var wob: float = sin(t * 1.6 + float(i) * 1.7) * 1.8
		var p: Vector2 = it["pos"] + Vector2(0, wob * 0.5)
		var fr: Vector2 = it["from"]
		c.draw_line(fr, p, Color("2a1a10"), 5.0)
		c.draw_line(fr, p, Color("5a8a3a") if String(it["kind"]) == "leaf" else Color("6a4a2a"), 3.0)
		var r: Rect2 = _rect_of(it)
		r.position += Vector2(0, wob * 0.5)
		var mod: Color = Color(1.28, 1.25, 1.1) if hot else Color.WHITE
		if String(it["kind"]) == "leaf":
			var src: Rect2 = Rect2(float(it["frame"]) * 28.0, 0.0, 28.0, 28.0)
			c.draw_texture_rect_region(leaf_tex, r, src, mod)
		else:
			c.draw_texture_rect(FD.icon(String(it["id"])), r, false, mod)
		if hot:
			c.draw_rect(r.grow(2.0), Color(1.0, 0.95, 0.6, 0.55), false, 2.0)
	# летящее в сумку
	var bag: Vector2 = Vector2(W - 60.0, 54.0)
	for fl in flying:
		var k: float = float(fl["t"])
		var pos: Vector2 = (fl["from"] as Vector2).lerp(bag, k * k * (3.0 - 2.0 * k))
		pos.y -= sin(k * PI) * 60.0
		var ic: Texture2D = IT.icon(String(fl["id"]))
		var sz: float = lerpf(64.0, 28.0, k)
		c.draw_texture_rect(ic, Rect2(pos - Vector2(sz, sz) * 0.5, Vector2(sz, sz)), false, Color(1, 1, 1, 1.0 - k * 0.3))
	# сумка в углу и счётчик взятого
	c.draw_texture_rect(bag_tex, Rect2(bag - Vector2(24, 24), Vector2(48, 48)), false)
	if taken_now > 0:
		c.draw_string(ThemeDB.fallback_font, bag + Vector2(-36, 46), "+%d" % taken_now, HORIZONTAL_ALIGNMENT_RIGHT, 72.0, 22, Color("f4ecd8"))
	# крестик закрытия
	c.draw_rect(Rect2(14, 14, 36, 36), Color(0.1, 0.07, 0.04, 0.7))
	c.draw_line(Vector2(22, 22), Vector2(42, 42), Color("f4ecd8"), 3.0)
	c.draw_line(Vector2(42, 22), Vector2(22, 42), Color("f4ecd8"), 3.0)
	if mp.x < -1000.0:
		return


# ------------------------------------------------------------------ ввод

func _item_at(p: Vector2) -> int:
	# последним нарисованное — сверху; ищем с конца
	for i in range(items.size() - 1, -1, -1):
		var it: Dictionary = items[i]
		if _alive(it) and _rect_of(it).grow(-6.0).has_point(p):
			return i
	return -1


func _on_input(event: InputEvent) -> void:
	if not is_open:
		return
	if event is InputEventMouseMotion:
		var h: int = _item_at((event as InputEventMouseMotion).position)
		if h != hover:
			hover = h
	elif event is InputEventMouseButton and (event as InputEventMouseButton).pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var mp: Vector2 = (event as InputEventMouseButton).position
		if Rect2(14, 14, 36, 36).has_point(mp):
			close()
			return
		var i: int = _item_at(mp)
		if i >= 0:
			pick(i)


## Сорвать листик или плод под номером i
func pick(i: int) -> void:
	var it: Dictionary = items[i]
	if not _alive(it):
		return
	var st: Dictionary = _state()
	if String(it["kind"]) == "leaf":
		(st["leaf"] as Dictionary)[int(it["idx"])] = Game.day
		Sound.play("page", -4.0, 0.25)
	else:
		(st["fruit"] as Dictionary)[int(it["idx"])] = Game.day
		Sound.play("pickup", -4.0, 0.15)
	flying.append({"from": it["pos"], "t": 0.0, "id": String(it["id"])})
	hover = -1


## Для автотеста: сколько ещё можно сорвать
func available(kind: String) -> int:
	var n: int = 0
	for it in items:
		if String(it["kind"]) == kind and _alive(it):
			n += 1
	return n


func pick_first(kind: String) -> bool:
	for i in range(items.size()):
		if String(items[i]["kind"]) == kind and _alive(items[i]):
			pick(i)
			return true
	return false


func _input(event: InputEvent) -> void:
	if not is_open:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var k: Key = (event as InputEventKey).physical_keycode
		if k == KEY_ESCAPE or KB.is_key("interact", k):
			close()
			get_viewport().set_input_as_handled()

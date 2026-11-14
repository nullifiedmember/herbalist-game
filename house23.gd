extends Node
## v23: дом героини изнутри — мебель (ставить, двигать, разворачивать, убирать) и пристройка комнат.
## Мебель — предметы "furn:<id>" (v23_data.FURN). В руке (панель 1–8) — ЛКМ ставит в доме.
## B в доме — обустройство: ЛКМ по мебели — взять обратно, ПКМ — развернуть, стрелки по краям — пристроить комнату.

const V = preload("res://v23_data.gd")
const IT = preload("res://items_db.gd")
const ROOM_W: float = 192.0
const MAX_SIDE: int = 3
const ROOM_NEED: Dictionary = {"@plank": 14, "log": 6, "stone_m": 4}

var main: Node2D
var holder: Node2D                # спрайты комнат
var nodes: Array = []             # [спрайт, узел-действие или null, свет или null]
var ghost: Sprite2D
var decor: bool = false
var arrows: Array = []            # [спрайт, слот, подпись]
var hover_i: int = -1
var t: float = 0.0
var cool: float = 0.0
var add_mat: CanvasItemMaterial


func setup(m: Node2D) -> void:
	main = m
	add_to_group("house23")
	add_mat = CanvasItemMaterial.new()
	add_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	holder = Node2D.new()
	holder.position = m.get("IN_ORG")
	holder.z_index = -10
	m.add_child(holder)
	var void_r: ColorRect = ColorRect.new()
	void_r.color = Color("1a1620")
	void_r.position = Vector2(-ROOM_W * 4 - 400, -300)
	void_r.size = Vector2(ROOM_W * 8 + 1440, 900)
	void_r.z_index = -2
	void_r.show_behind_parent = true
	holder.add_child(void_r)
	ghost = Sprite2D.new()
	ghost.centered = false
	ghost.visible = false
	ghost.z_index = 40
	m.add_child(ghost)
	if not Game.house_init:
		Game.house_init = true
		if bool(m.get("classic_yard")) or Game.day > 1:
			Game.furniture = classic_set()
		else:
			Game.furniture = [["straw_bed", 386.0, 212.0, false]]   # новая игра: только самая дешёвая лежанка
	rebuild()


## Обстановка «как было» — для старых сохранений и автотеста
static func classic_set() -> Array:
	return [
		["dp_bookcase", 252.0, 156.0, false], ["dp_cupboard", 288.0, 156.0, false], ["dp_dresser", 322.0, 158.0, false],
		["dp_wardrobe", 376.0, 156.0, false], ["dp_pot_red", 402.0, 152.0, false], ["dp_flowerbox", 322.0, 180.0, false],
		["dp_shelf", 246.0, 228.0, false], ["dp_bed", 386.0, 210.0, false], ["dp_nightstand", 395.0, 240.0, false],
		["dp_table", 298.0, 246.0, false], ["dp_cushions", 346.0, 252.0, false], ["dp_basket_oranges", 260.0, 278.0, false],
		["dp_basket_greens", 286.0, 278.0, false], ["dp_horse", 322.0, 278.0, false], ["dp_chest", 352.0, 278.0, false],
		["dp_barrel", 398.0, 278.0, false], ["dp_rug", 318.0, 262.0, false], ["dp_clock", 292.0, 108.0, false],
	]


# ------------------------------------------------------------------ комнаты

func slot_ox(s: int) -> float:
	return ROOM_W * float(s)


func min_slot() -> int:
	var m: int = 0
	for s in Game.rooms:
		m = mini(m, int(s))
	return m


func max_slot() -> int:
	var m: int = 0
	for s in Game.rooms:
		m = maxi(m, int(s))
	return m


func has_room(s: int) -> bool:
	for r in Game.rooms:
		if int(r) == s:
			return true
	return false


## Можно ли стоять в точке дома (l — от IN_ORG)
func blocked(l: Vector2, ignore_furn: bool = false) -> bool:
	var s: int = int(floor((l.x - 220.0) / ROOM_W))
	var ox: float = slot_ox(s)
	if not has_room(s):
		return true
	# проём в соседнюю комнату
	var in_gap_r: bool = l.x > 400.0 + ox and has_room(s + 1) and l.y > 196.0 and l.y < 228.0
	var in_gap_l: bool = l.x < 240.0 + ox and has_room(s - 1) and l.y > 196.0 and l.y < 228.0
	if not in_gap_r and not in_gap_l:
		if l.y < 150.0 or l.y > 300.0 or l.x < 232.0 + ox or l.x > 408.0 + ox:
			return true
		if l.y > 278.0 and (s != 0 or l.x < 306.0 or l.x > 334.0):
			return true
	if ignore_furn:
		return false
	for f in Game.furniture:
		var r: Rect2 = foot_rect(f)
		if r.size != Vector2.ZERO and r.has_point(l):
			return true
	return false


func foot_rect(f: Array) -> Rect2:
	var d: Dictionary = V.FURN.get(String(f[0]), {})
	if d.is_empty():
		return Rect2()
	var ft: Array = d["foot"]
	if float(ft[2]) <= 0.0:
		return Rect2()
	return Rect2(float(f[1]) + float(ft[0]), float(f[2]) + float(ft[1]), float(ft[2]), float(ft[3]))


func rebuild() -> void:
	for ch in holder.get_children():
		if ch is Sprite2D:
			ch.queue_free()
	var floor_t: Texture2D = load("res://art/room_side.png")
	var gap_t: Texture2D = load("res://art/room_gap.png")
	for s0 in Game.rooms:
		var s: int = int(s0)
		if s == 0:
			continue
		var rs: Sprite2D = Sprite2D.new()
		rs.texture = floor_t
		rs.centered = false
		rs.position = Vector2(220.0 + slot_ox(s), 88.0)
		rs.z_index = 1
		holder.add_child(rs)
	for s1 in Game.rooms:
		var a: int = int(s1)
		if has_room(a + 1):
			var g: Sprite2D = Sprite2D.new()
			g.texture = gap_t
			g.centered = false
			g.position = Vector2(411.0 + slot_ox(a), 192.0)
			g.z_index = 2
			holder.add_child(g)
	_build_furniture()
	_build_arrows()


func _build_furniture() -> void:
	for n in nodes:
		for x in n:
			if x != null and is_instance_valid(x):
				(x as Node).queue_free()
	nodes.clear()
	var org: Vector2 = main.get("IN_ORG")
	var glow_t: Texture2D = load("res://art/cz_glow.png")
	for i in range(Game.furniture.size()):
		var f: Array = Game.furniture[i]
		var id: String = String(f[0])
		if not V.FURN.has(id):
			nodes.append([null, null, null])
			continue
		var d: Dictionary = V.FURN[id]
		var p: Vector2 = org + Vector2(float(f[1]), float(f[2]))
		var s: Sprite2D = main.call("spr", String(d["tex"]), p, 0.0, bool(f[3]), null, false)
		var use: String = String(d["use"])
		if use == "flat":
			s.z_index = -5
		elif use == "wall":
			s.z_index = -6
		var act: Node2D = null
		if use in ["sleep", "chest", "book", "water", "food", "music", "stove", "light"]:
			act = Node2D.new()
			act.set_script(load("res://furn_use.gd"))
			act.set("use", use)
			act.set("fid", id)
			act.position = p + Vector2(0, 2)
			(main.get("objects") as Node).add_child(act)
		var gl: Sprite2D = null
		if use == "light" or d["cat"] == "lamp" or id in ["fireplace", "stove"]:
			gl = Sprite2D.new()
			gl.texture = glow_t
			gl.position = p + Vector2(0, -float(s.texture.get_height()) * 0.7)
			gl.scale = Vector2.ONE * (1.1 if id != "fireplace" else 1.8)
			gl.material = add_mat
			gl.z_index = 30
			main.add_child(gl)
		nodes.append([s, act, gl])


func _build_arrows() -> void:
	for a in arrows:
		(a[0] as Node).queue_free()
	arrows.clear()
	var org: Vector2 = main.get("IN_ORG")
	for side in [-1, 1]:
		var s: int = (min_slot() - 1) if side < 0 else (max_slot() + 1)
		if absi(s) > MAX_SIDE:
			continue
		var sp: Sprite2D = Sprite2D.new()
		sp.texture = load("res://art/room_add.png")
		sp.flip_h = side < 0
		sp.position = org + Vector2((220.0 + slot_ox(s - side)) + (ROOM_W + 24.0 if side > 0 else -24.0), 212.0)
		sp.z_index = 45
		sp.visible = false
		main.add_child(sp)
		# цена значками: доски, брёвна, камни
		var row: HBoxContainer = HBoxContainer.new()
		row.position = Vector2(-26, 14)
		row.scale = Vector2(0.25, 0.25)
		sp.add_child(row)
		for k in ROOM_NEED.keys():
			var ic: TextureRect = TextureRect.new()
			ic.texture = IT.icon(preload("res://mats_db.gd").need_icon(Game.inventory, String(k)))
			ic.custom_minimum_size = Vector2(48, 48)
			ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			ic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			row.add_child(ic)
			var l: Label = Label.new()
			l.text = "%d" % int(ROOM_NEED[k])
			l.add_theme_font_size_override("font_size", 40)
			l.add_theme_color_override("font_outline_color", Color.BLACK)
			l.add_theme_constant_override("outline_size", 10)
			row.add_child(l)
		arrows.append([sp, s])


func build_room(s: int) -> bool:
	if has_room(s) or absi(s) > MAX_SIDE or not (has_room(s - 1) or has_room(s + 1)):
		return false
	var hs: Node = get_tree().get_first_node_in_group("homestead")
	if not Game.god_mode:
		if hs == null or not bool(hs.call("_pay", ROOM_NEED)):
			return false
	Game.rooms.append(s)
	Sound.play("chop", -4.0)
	Game.toast.emit("Новая комната!", load("res://art/room_add.png"))
	Game.skill_xp("craft", 20.0)
	rebuild()
	return true


# ------------------------------------------------------------------ мебель

func can_put(id: String, l: Vector2) -> bool:
	var d: Dictionary = V.FURN.get(id, {})
	if d.is_empty():
		return false
	var use: String = String(d["use"])
	var s: int = int(floor((l.x - 220.0) / ROOM_W))
	if not has_room(s):
		return false
	var ox: float = slot_ox(s)
	if use == "wall":
		return l.y > 100.0 and l.y < 146.0 and l.x > 236.0 + ox and l.x < 404.0 + ox
	if blocked(l, true):
		return false
	# дверь не загораживать
	if s == 0 and l.x > 296.0 and l.x < 344.0 and l.y > 250.0:
		return false
	var ft: Array = d["foot"]
	var r: Rect2 = Rect2(l.x + float(ft[0]), l.y + float(ft[1]), maxf(1.0, float(ft[2])), maxf(1.0, float(ft[3])))
	if use != "flat":
		for q in [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]:
			if blocked(q, true):
				return false
		for f in Game.furniture:
			var o: Rect2 = foot_rect(f)
			if o.size != Vector2.ZERO and o.intersects(r):
				return false
	var pl: Node2D = main.get("player")
	if use != "flat" and r.grow(2.0).has_point(pl.position - main.get("IN_ORG")):
		return false
	return true


func put(id: String, l: Vector2, flip: bool = false) -> bool:
	if not can_put(id, l):
		return false
	Game.furniture.append([id, l.x, l.y, flip])
	_build_furniture()
	return true


func pick(i: int) -> void:
	if i < 0 or i >= Game.furniture.size():
		return
	var id: String = String(Game.furniture[i][0])
	Game.furniture.remove_at(i)
	Game.add_item("furn:" + id)
	var hb: int = Game.hotbar.find("furn:" + id)
	if hb < 0:
		hb = Game.hotbar.find("")
		if hb >= 0:
			Game.hotbar[hb] = "furn:" + id
	if hb >= 0:
		Game.hot_sel = hb
	Game.inventory_changed.emit()
	_build_furniture()
	Sound.play("ui_click", -6.0)


func _furn_at(l: Vector2) -> int:
	var best: int = -1
	var best_y: float = -1e9
	for i in range(nodes.size()):
		var s: Sprite2D = nodes[i][0]
		if s == null:
			continue
		var r: Rect2 = Rect2(s.position + s.offset - main.get("IN_ORG"), s.texture.get_size())
		if r.has_point(l) and float(Game.furniture[i][2]) > best_y:
			best = i
			best_y = float(Game.furniture[i][2])
	return best


func _mouse_l() -> Vector2:
	return ((main.get_global_mouse_position() - main.get("IN_ORG")) / 2.0).round() * 2.0


# ------------------------------------------------------------------ ввод и кадр

func _unhandled_input(event: InputEvent) -> void:
	if not bool(main.get("inside")) or Game.ui_open or Game.busy:
		return
	if event is InputEventKey and event.pressed and not event.echo and KB.is_key("build", (event as InputEventKey).physical_keycode):
		decor = not decor
		Sound.play("page", -8.0)
		get_viewport().set_input_as_handled()
		return
	if not (event is InputEventMouseButton) or not (event as InputEventMouseButton).pressed:
		return
	var mb: InputEventMouseButton = event
	var l: Vector2 = _mouse_l()
	var held: String = Game.held()
	if mb.button_index == MOUSE_BUTTON_LEFT:
		if IT.is_furn(held):
			var id: String = held.substr(5)
			if put(id, l, false):
				Game.take_item(held)
				Sound.play("chop", -8.0, 0.2)
				Game.fx.emit(main.get("IN_ORG") + l, "dust")
			else:
				(main.get("player") as Node).call("react", "pout", 0.6)
			get_viewport().set_input_as_handled()
			return
		if decor:
			for a in arrows:
				if (a[0] as Sprite2D).visible and (a[0] as Sprite2D).global_position.distance_to(main.get_global_mouse_position()) < 14.0:
					if not build_room(int(a[1])):
						(main.get("player") as Node).call("react", "pout", 0.6)
						Sound.play("ui_click", -2.0)
					get_viewport().set_input_as_handled()
					return
			var fi: int = _furn_at(l)
			if fi >= 0:
				pick(fi)
				get_viewport().set_input_as_handled()
	elif mb.button_index == MOUSE_BUTTON_RIGHT and decor:
		var fi2: int = _furn_at(l)
		if fi2 >= 0:
			Game.furniture[fi2][3] = not bool(Game.furniture[fi2][3])
			(nodes[fi2][0] as Sprite2D).flip_h = bool(Game.furniture[fi2][3])
			Sound.play("ui_click", -8.0)
			get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	t += delta
	var ins: bool = bool(main.get("inside"))
	if not ins:
		decor = false
	# камера захватывает все комнаты
	if ins:
		var cam: Camera2D = main.get("cam")
		var org: Vector2 = main.get("IN_ORG")
		cam.limit_left = int(org.x + slot_ox(min_slot()))
		cam.limit_right = int(org.x + 640.0 + slot_ox(max_slot()))
	var held: String = Game.held()
	var show_g: bool = ins and IT.is_furn(held) and not Game.ui_open
	ghost.visible = show_g
	if show_g:
		var d: Dictionary = V.FURN.get(held.substr(5), {})
		if not d.is_empty():
			var tx: Texture2D = load("res://art/%s.png" % String(d["tex"]))
			ghost.texture = tx
			ghost.offset = Vector2(-floorf(tx.get_width() / 2.0), -float(tx.get_height()))
			var l: Vector2 = _mouse_l()
			ghost.position = main.get("IN_ORG") + l
			ghost.modulate = Color(0.7, 1.0, 0.7, 0.7) if can_put(held.substr(5), l) else Color(1.0, 0.45, 0.45, 0.55)
	# обустройство: подсветка мебели под мышью и стрелки пристройки
	var hi: int = _furn_at(_mouse_l()) if (ins and decor) else -1
	for i in range(nodes.size()):
		var s: Sprite2D = nodes[i][0]
		if s != null:
			s.self_modulate = Color(1.3, 1.25, 0.9).lerp(Color(1.1, 1.1, 1.0), 0.5 + 0.5 * sin(t * 6.0)) if i == hi else Color.WHITE
	for a in arrows:
		var sp: Sprite2D = a[0]
		sp.visible = ins and decor
		sp.modulate.a = 0.7 + 0.3 * sin(t * 4.0)
	# свет ламп: ночью ярче
	var n: float = Game.night_factor()
	for nd in nodes:
		var gl: Sprite2D = nd[2]
		if gl != null:
			gl.visible = ins
			var a2: float = lerpf(0.12, 0.7, n) * (1.0 + 0.06 * sin(t * 9.0 + gl.position.x))
			gl.modulate = Color(1.0 * a2, 0.8 * a2, 0.5 * a2, 1.0)

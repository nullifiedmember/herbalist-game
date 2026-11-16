extends CanvasLayer
## v23: сундук как в PoE — слева сетка сундука 12×12 клеток, справа открывается сумка.
## ЛКМ по вещи — взять в курсор, ЛКМ по клетке — положить (обмен, пучки). Вещь из курсора мимо сундука — в сумку.
## Ctrl+ЛКМ — сразу перенести: из сундука в сумку и (в сумке) из сумки в сундук. Из сумки можно тащить прямо в сундук.
## v24: сундуков много, у каждого свой размер (storage_db.KINDS) и назначение (что в нём лежит). Game.chests[ключ].
## Работницы кладут добычу через deposit() — в ближайший сундук с подходящим назначением.

const IT = preload("res://items_db.gd")
const SDB = preload("res://storage_db.gd")
const CELL: float = 40.0
const COLS: int = 12
const ROWS: int = 12
const PW: float = COLS * CELL + 48.0
const PH: float = ROWS * CELL + 140.0

var main: Node2D
var hud: CanvasLayer
var root: Control
var panel: Control
var grid: Control
var carry_id: String = ""
var carry_n: int = 0
var carry_rot: bool = false         # v29: вещь в курсоре повёрнута (R)
var carry_icon: TextureRect
var open: bool = false
var tip: Control
var tip_box: VBoxContainer
var tip_id: String = ""
var cur_key: String = ""
var cols: int = COLS
var rows: int = ROWS
var cell: float = CELL
var title_l: Label
var bg_rect: Control
var sign_rect: TextureRect
const U31 = preload("res://ui31.gd")
var btn_box: HBoxContainer
var filter_box: HBoxContainer
var filter_btn: OptionButton
var _last_sum: Dictionary = {}


func setup(m: Node2D, h: CanvasLayer) -> void:
	main = m
	hud = h
	layer = 23
	add_to_group("chest_ui")
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.visible = false
	add_child(root)
	panel = Control.new()
	panel.position = Vector2(40, 170)
	panel.size = Vector2(PW, PH)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(panel)
	# v31: рамка в стиле яблока (картинка уже ×2 — размер можно задавать напрямую)
	# рамка-плитка: уголки и рёбра не растягиваются, бумага повторяется (ui31_wpanel, поля 12 → 24 на экране)
	var bg: NinePatchRect = U31.np("ui31_wpanel_x2", 24, 1.0, panel.size)
	bg.axis_stretch_horizontal = NinePatchRect.AXIS_STRETCH_MODE_TILE_FIT
	bg.axis_stretch_vertical = NinePatchRect.AXIS_STRETCH_MODE_TILE_FIT
	bg_rect = bg
	panel.add_child(bg)
	sign_rect = TextureRect.new()
	sign_rect.texture = U31.tex("ui31_sign")
	sign_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sign_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sign_rect.stretch_mode = TextureRect.STRETCH_SCALE
	sign_rect.size = Vector2(260, 44)
	sign_rect.position = Vector2(PW / 2.0 - 130.0, 28)
	sign_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(sign_rect)
	# пучки трав по бокам таблички, как в сумке
	for bk in ["lavender", "chamomile"]:
		var bt: TextureRect = TextureRect.new()
		bt.name = "bundle_" + bk
		bt.texture = U31.tex("ui31_bundle_" + bk)
		bt.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		bt.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bt.size = bt.texture.get_size() * 2.0
		bt.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(bt)
	var ttl: Label = Label.new()
	title_l = ttl
	ttl.text = "Сундук"
	ttl.add_theme_font_override("font", hud.get("font_title"))
	ttl.add_theme_font_size_override("font_size", 36)
	ttl.add_theme_color_override("font_color", U31.INK)
	ttl.position = Vector2(0, 21)
	ttl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ttl.size = Vector2(PW, 44)
	ttl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ttl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(ttl)
	# кнопки: всё в сундук / всё в сумку / отсортировать
	var bx: HBoxContainer = HBoxContainer.new()
	btn_box = bx
	bx.position = Vector2(24, PH - 50)
	bx.add_theme_constant_override("separation", 10)
	panel.add_child(bx)
	for b in [["Всё в сундук", _put_all], ["Всё в сумку", _take_all], ["Сортировать", _sort]]:
		var btn: Button = Button.new()
		btn.text = String(b[0])
		btn.focus_mode = Control.FOCUS_NONE
		U31.style_button(btn, hud.get("font_body"), 18)
		btn.pressed.connect(b[1])
		bx.add_child(btn)
	filter_box = HBoxContainer.new()
	filter_box.position = Vector2(30, 76)
	filter_box.alignment = BoxContainer.ALIGNMENT_BEGIN
	filter_box.add_theme_constant_override("separation", 8)
	panel.add_child(filter_box)
	var fl: Label = Label.new()
	fl.text = "Для чего:"
	fl.add_theme_font_override("font", hud.get("font_body"))
	fl.add_theme_font_size_override("font_size", 18)
	fl.add_theme_color_override("font_color", U31.INK_SOFT)
	fl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	filter_box.add_child(fl)
	filter_btn = OptionButton.new()
	filter_btn.focus_mode = Control.FOCUS_NONE
	U31.style_option(filter_btn, hud.get("font_body"), 18)
	filter_btn.add_theme_constant_override("icon_max_width", 22)
	filter_btn.custom_minimum_size = Vector2(300, 38)
	filter_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for i in range(SDB.CATS.size()):
		var ce: Array = SDB.CATS[i]
		filter_btn.add_icon_item(SDB.cat_icon(String(ce[0])), String(ce[1]), i)
	filter_btn.item_selected.connect(func(i: int) -> void:
		if cur_key != "" and Game.chests.has(cur_key):
			Game.chests[cur_key]["filter"] = String(SDB.CATS[i][0])
			Sound.play("ui_click", -6.0))
	filter_box.add_child(filter_btn)
	grid = Control.new()
	grid.position = Vector2(24, 118)
	grid.size = Vector2(COLS * CELL, ROWS * CELL)
	grid.mouse_filter = Control.MOUSE_FILTER_STOP
	grid.gui_input.connect(_grid_input)
	grid.draw.connect(_draw_grid)
	panel.add_child(grid)
	carry_icon = TextureRect.new()
	carry_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	carry_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	carry_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	carry_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	carry_icon.z_index = 30
	root.add_child(carry_icon)
	# v26: подсказка как в сумке — что это и что делает (item_info.gd)
	tip = Control.new()
	tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tip.z_index = 31
	tip.visible = false
	root.add_child(tip)
	var tbg: NinePatchRect = U31.np("ui31_tip_x2", 12, 1.0, Vector2(64, 64))
	tbg.name = "bg"
	tip.add_child(tbg)
	tip_box = VBoxContainer.new()
	tip_box.position = Vector2(18, 14)
	tip_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tip_box.add_theme_constant_override("separation", 2)
	tip.add_child(tip_box)
	_migrate()


# ------------------------------------------------------------------ данные

## Раскладка текущего сундука (массив по ссылке)
func L() -> Array:
	if cur_key == "" or not Game.chests.has(cur_key):
		return []
	return Game.chests[cur_key]["layout"]


## Завести сундук в Game.chests (если ещё нет)
func register(key: String, kind: String) -> void:
	if not Game.chests.has(key):
		var f: String = "stone" if kind == "storage_crate" else "all"
		Game.chests[key] = {"kind": kind, "layout": [], "filter": f}
	_migrate()


## Сундук разобрали — вещи из него в сумку
func forget(key: String) -> void:
	if not Game.chests.has(key):
		return
	for e in (Game.chests[key]["layout"] as Array):
		_to_bag(String(e["id"]), int(e["n"]))
	Game.chests.erase(key)
	_sync_dict()


func _use(key: String) -> void:
	cur_key = key
	var kd: Array = SDB.KINDS.get(String(Game.chests.get(key, {}).get("kind", "chest")), SDB.KINDS["chest"])
	cols = int(kd[1])
	rows = int(kd[2])
	cell = float(kd[3])


## Game.chest (предмет -> сколько) — сумма по всем сундукам: старый код и автотест читают его
func _sync_dict() -> void:
	Game.chest.clear()
	for k in Game.chests.keys():
		for e2 in (Game.chests[k]["layout"] as Array):
			Game.chest[String(e2["id"])] = int(Game.chest.get(String(e2["id"]), 0)) + int(e2["n"])
	_last_sum = Game.chest.duplicate()


## Старые сохранения (один общий сундук) и чужой код, который пишет прямо в Game.chest, — разложить по сундукам
func _migrate() -> void:
	if Game.chests.is_empty():
		return
	if not Game.chest_layout.is_empty():
		var old: Array = Game.chest_layout.duplicate(true)
		Game.chest_layout.clear()
		for e in old:
			var lft0: int = deposit(String(e["id"]), int(e["n"]), Vector2.ZERO, false)
			if lft0 > 0:
				Game.ground.append([String(e["id"]), lft0, Game.home_pos.x, Game.home_pos.y + 40.0])
	# прибавки «мимо сетки»
	var have: Dictionary = {}
	for k in Game.chests.keys():
		for e2 in (Game.chests[k]["layout"] as Array):
			have[String(e2["id"])] = int(have.get(String(e2["id"]), 0)) + int(e2["n"])
	for id in Game.chest.keys():
		var extra: int = int(Game.chest[id]) - int(have.get(String(id), 0))
		if extra > 0:
			var lft: int = deposit(String(id), extra, Vector2.ZERO, false)
			if lft > 0:
				Game.ground.append([String(id), lft, Game.home_pos.x, Game.home_pos.y + 40.0])
	_sync_dict()


func _key_pos(key: String) -> Vector2:
	var pp: PackedStringArray = key.trim_prefix("f:").split(",")
	if pp.size() < 2:
		return Game.home_pos
	return Vector2(float(pp[0]), float(pp[1]))


## Ключи сундуков, куда подходит вещь: сначала с точным назначением, потом «всё подряд», ближе — раньше
func keys_for(id: String, near: Vector2) -> Array:
	var cat: String = SDB.category(id)
	var keys: Array = []
	for k in Game.chests.keys():
		if SDB.accepts(String(Game.chests[k].get("filter", "all")), id):
			keys.append(k)
	keys.sort_custom(func(a: Variant, b: Variant) -> bool:
		var ra: int = 0 if String(Game.chests[a].get("filter", "all")) == cat else 1
		var rb: int = 0 if String(Game.chests[b].get("filter", "all")) == cat else 1
		if ra != rb:
			return ra < rb
		return _key_pos(String(a)).distance_to(near) < _key_pos(String(b)).distance_to(near))
	return keys


## Положить n штук в подходящие сундуки. Возвращает, сколько не влезло никуда.
func deposit(id: String, n: int, near: Vector2, sync: bool = true) -> int:
	if n <= 0:
		return 0
	var keep: String = cur_key
	for k in keys_for(id, near):
		if n <= 0:
			break
		_use(String(k))
		n = _add(id, n)
	if keep != "" and Game.chests.has(keep):
		_use(keep)
	else:
		cur_key = ""
	if sync:
		_sync_dict()
		if open:
			_refresh()
	return n


## Ключ сундука, куда влезет хоть одна такая вещь ("" — некуда)
func room_for(id: String, near: Vector2) -> String:
	var keep: String = cur_key
	var found: String = ""
	for k in keys_for(id, near):
		_use(String(k))
		var st: int = IT.stack(id)
		for e in L():
			if found == "" and String(e["id"]) == id and int(e["n"]) < st:
				found = String(k)
		if found == "" and _find_spot(id, _cells()).x >= 0:
			found = String(k)
		if found != "":
			break
	if keep != "" and Game.chests.has(keep):
		_use(keep)
	else:
		cur_key = ""
	return found


# ------------------------------------------------------------------ v26: запасы базы для крафта

## Сундуки на участке (и чуть вокруг него): из них верстаки берут материалы сами
func base_keys() -> Array:
	var r: Rect2 = Rect2(Game.home_pos - Vector2(700, 450), Vector2(1400, 900))
	var hs: Node = get_tree().get_first_node_in_group("homestead") if is_inside_tree() else null
	if hs != null:
		r = (hs.call("plot_rect") as Rect2).grow(220.0)
	var out: Array = []
	for k in Game.chests.keys():
		if r.has_point(_key_pos(String(k))):
			out.append(k)
	return out


## Сколько чего лежит в сундуках базы (предмет -> штук)
func base_totals() -> Dictionary:
	var t: Dictionary = {}
	for k in base_keys():
		for e in (Game.chests[k]["layout"] as Array):
			t[String(e["id"])] = int(t.get(String(e["id"]), 0)) + int(e["n"])
	return t


## Забрать из сундуков базы до n штук. Возвращает, сколько забрала.
func base_take(id: String, n: int) -> int:
	var got: int = 0
	for k in base_keys():
		var lay: Array = Game.chests[k]["layout"]
		var i: int = lay.size() - 1
		while i >= 0 and got < n:
			var e: Dictionary = lay[i]
			if String(e["id"]) == id:
				var t: int = mini(int(e["n"]), n - got)
				e["n"] = int(e["n"]) - t
				got += t
				if int(e["n"]) <= 0:
					lay.remove_at(i)
			i -= 1
		if got >= n:
			break
	if got > 0:
		_sync_dict()
		if open:
			_refresh()
	return got


func _cells(skip: int = -1) -> Array:
	var g: Array = []
	for y in range(rows):
		var row: Array = []
		row.resize(cols)
		row.fill(-1)
		g.append(row)
	for i in range(L().size()):
		if i == skip:
			continue
		var e: Dictionary = L()[i]
		var sz: Vector2i = Game.esize(e)
		for yy in range(int(e["y"]), mini(rows, int(e["y"]) + sz.y)):
			for xx in range(int(e["x"]), mini(cols, int(e["x"]) + sz.x)):
				g[yy][xx] = i
	return g


func _covered(id: String, x: int, y: int, rot: bool = false) -> Array:
	var sz: Vector2i = Game.rsize(id, rot)
	if x < 0 or y < 0 or x + sz.x > cols or y + sz.y > rows:
		return [-2]
	var g: Array = _cells()
	var out: Array = []
	for yy in range(y, y + sz.y):
		for xx in range(x, x + sz.x):
			var v: int = int(g[yy][xx])
			if v >= 0 and not out.has(v):
				out.append(v)
	return out


## Первое свободное место для вещи (сетка g из _cells, строится один раз; раньше сетка строилась на каждую клетку — давало лаг на секунды)
func _find_spot(id: String, g: Array, rot: bool = false) -> Vector2i:
	var sz: Vector2i = Game.rsize(id, rot)
	for y in range(rows - sz.y + 1):
		for x in range(cols - sz.x + 1):
			var ok: bool = true
			for yy in range(y, y + sz.y):
				for xx in range(x, x + sz.x):
					if int(g[yy][xx]) >= 0:
						ok = false
						break
				if not ok:
					break
			if ok:
				return Vector2i(x, y)
	return Vector2i(-1, -1)


## Положить n штук куда влезет (сначала в неполные стопки). Возвращает, сколько не влезло.
func _add(id: String, n: int) -> int:
	var st: int = IT.stack(id)
	for e in L():
		if n <= 0:
			break
		if String(e["id"]) == id and int(e["n"]) < st:
			var put: int = mini(n, st - int(e["n"]))
			e["n"] = int(e["n"]) + put
			n -= put
	while n > 0:
		var g0: Array = _cells()
		var spot: Vector2i = _find_spot(id, g0)
		var rot0: bool = false
		if spot.x < 0 and IT.size(id).x != IT.size(id).y:
			spot = _find_spot(id, g0, true)      # v29: не влезло прямо — кладём повёрнутым
			rot0 = true
		if spot.x < 0:
			return n
		var put2: int = mini(n, st)
		L().append({"id": id, "n": put2, "x": spot.x, "y": spot.y, "r": rot0})
		n -= put2
	return 0


## Из сумки в сундук (n штук). true — что-то положила.
func store(id: String, n: int) -> bool:
	n = mini(n, Game.get_count(id))
	if n <= 0:
		return false
	var left: int = _add(id, n)
	var moved: int = n - left
	if moved > 0:
		Game.inventory[id] = Game.get_count(id) - moved
		Game.inventory_changed.emit()
		_sync_dict()
		_refresh()
	return moved > 0


func _to_bag(id: String, n: int) -> void:
	Game.inventory[id] = Game.get_count(id) + n
	Game.discovered[id] = true
	Game.inventory_changed.emit()


# ------------------------------------------------------------------ окно

func open_chest(key: String = "", kind: String = "chest") -> void:
	if open:
		return
	if key == "":
		key = String(Game.chests.keys()[0]) if not Game.chests.is_empty() else "main"
	register(key, kind)
	_use(key)
	open = true
	root.visible = true
	_layout_panel()
	_migrate()
	_refresh()
	var iu: Node = get_tree().get_first_node_in_group("inventory_ui")
	if iu != null and not bool(iu.get("open")):
		Game.ui_open = false
		iu.call("open_inv")
	Game.ui_open = true
	Sound.play("door", -6.0)


func _layout_panel() -> void:
	var pw: float = cols * cell + 48.0
	var ph: float = rows * cell + 212.0
	panel.size = Vector2(maxf(pw, 560.0), ph)
	panel.position = Vector2(24, clampf(540.0 - ph / 2.0, 20.0, 400.0))
	bg_rect.size = panel.size
	title_l.size = Vector2(panel.size.x, 44)
	sign_rect.position = Vector2(panel.size.x / 2.0 - 130.0, 28)
	# справа от таблички (слева занято списком «Для чего»)
	(panel.get_node("bundle_lavender") as Control).position = Vector2(panel.size.x / 2.0 + 168.0, 14)
	(panel.get_node("bundle_chamomile") as Control).position = Vector2(panel.size.x / 2.0 + 218.0, 14)
	title_l.text = String(SDB.KINDS.get(String(Game.chests[cur_key].get("kind", "chest")), ["Сундук"])[0])
	grid.size = Vector2(cols * cell, rows * cell)
	grid.position = Vector2((panel.size.x - grid.size.x) / 2.0, 140)
	btn_box.position = Vector2(24, ph - 54)
	var f: String = String(Game.chests[cur_key].get("filter", "all"))
	for i in range(SDB.CATS.size()):
		if String(SDB.CATS[i][0]) == f:
			filter_btn.select(i)


func close_chest() -> void:
	if not open:
		return
	if carry_id != "":
		_to_bag(carry_id, carry_n)
		carry_id = ""
		carry_rot = false
	open = false
	root.visible = false
	var iu: Node = get_tree().get_first_node_in_group("inventory_ui")
	if iu != null and bool(iu.get("open")):
		iu.call("close_inv")
	Game.ui_open = false
	Sound.play("door", -8.0)


func _refresh() -> void:
	for c in grid.get_children():
		c.queue_free()
	for i in range(L().size()):
		var e: Dictionary = L()[i]
		var id: String = String(e["id"])
		var sz0: Vector2i = IT.size(id)
		var sz: Vector2i = Game.esize(e)
		var ic: TextureRect = TextureRect.new()
		ic.texture = preload("res://item_info.gd").ui_icon(id)
		ic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.size = Vector2(sz0.x * cell - 4, sz0.y * cell - 4)
		var ctr: Vector2 = Vector2(int(e["x"]) * cell, int(e["y"]) * cell) + Vector2(sz.x * cell, sz.y * cell) / 2.0
		ic.position = ctr - ic.size / 2.0
		ic.pivot_offset = ic.size / 2.0
		ic.rotation = PI / 2.0 if bool(e.get("r", false)) else 0.0
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		grid.add_child(ic)
		if int(e["n"]) > 1:
			var l: Control = U31.pix_count(int(e["n"]), 2.0)
			l.position = Vector2(int(e["x"]) * cell, int(e["y"]) * cell) + Vector2(sz.x * cell, sz.y * cell) - l.size - Vector2(2, 2)
			grid.add_child(l)
	grid.queue_redraw()


func _draw_grid() -> void:
	var cell_t: Texture2D = U31.tex("ui31_cell")
	# деревянный лоток под сеткой: контур, кромка света сверху-слева, тень снизу-справа
	var gr: Rect2 = Rect2(Vector2.ZERO, grid.size)
	grid.draw_rect(gr.grow(8), Color("6e4636"))
	grid.draw_rect(gr.grow(6), Color("9c6a48"))
	grid.draw_rect(Rect2(gr.position - Vector2(6, 6), Vector2(gr.size.x + 10, 2)), Color("ecc48e"))
	grid.draw_rect(Rect2(gr.position - Vector2(6, 6), Vector2(2, gr.size.y + 10)), Color("ecc48e"))
	grid.draw_rect(Rect2(gr.position - Vector2(4, 4), Vector2(gr.size.x + 6, 2)), Color("d9a873"))
	grid.draw_rect(Rect2(gr.position - Vector2(4, 4), Vector2(2, gr.size.y + 6)), Color("d9a873"))
	grid.draw_rect(gr.grow(2), Color("6e4636"))
	for y in range(rows):
		for x in range(cols):
			grid.draw_texture_rect(cell_t, Rect2(x * cell, y * cell, cell, cell), false)
	for e in L():
		var sz: Vector2i = Game.esize(e)
		grid.draw_rect(Rect2(int(e["x"]) * cell + 2, int(e["y"]) * cell + 2, sz.x * cell - 4, sz.y * cell - 4), Color(0.55, 0.72, 0.42, 0.22) if not IT.is_gear(String(e["id"])) else Color(0.85, 0.6, 0.28, 0.22))
	var cid: String = _carry_any()
	if cid != "":
		var crot: bool = _carry_rot_any()
		var tgt: Vector2i = _target(cid, crot)
		var sz2: Vector2i = Game.rsize(cid, crot)
		var cov: Array = _covered(cid, tgt.x, tgt.y, crot)
		var ok: bool = not cov.has(-2) and cov.size() <= 1
		grid.draw_rect(Rect2(tgt.x * cell, tgt.y * cell, sz2.x * cell, sz2.y * cell), Color(0.3, 0.9, 0.3, 0.28) if ok else Color(0.9, 0.25, 0.2, 0.3))


## Что «в руке»: своё или из сумки
func _carry_any() -> String:
	if carry_id != "":
		return carry_id
	var iu: Node = get_tree().get_first_node_in_group("inventory_ui")
	return String(iu.get("carry_id")) if iu != null else ""


func _carry_rot_any() -> bool:
	if carry_id != "":
		return carry_rot
	var iu: Node = get_tree().get_first_node_in_group("inventory_ui")
	return bool(iu.get("carry_rot")) if iu != null else false


func _target(id: String, rot: bool = false) -> Vector2i:
	var mp: Vector2 = grid.get_local_mouse_position()
	var sz: Vector2i = Game.rsize(id, rot)
	return Vector2i(int(floor(mp.x / cell - float(sz.x) / 2.0 + 0.5)), int(floor(mp.y / cell - float(sz.y) / 2.0 + 0.5)))


func _index_at(mp: Vector2) -> int:
	var cx: int = int(mp.x / cell)
	var cy: int = int(mp.y / cell)
	if cx < 0 or cy < 0 or cx >= cols or cy >= rows:
		return -1
	return int(_cells()[cy][cx])


func _grid_input(ev: InputEvent) -> void:
	if not (ev is InputEventMouseButton) or not (ev as InputEventMouseButton).pressed:
		return
	var mb: InputEventMouseButton = ev
	var iu: Node = get_tree().get_first_node_in_group("inventory_ui")
	# вещь из сумки в курсоре — кладём в сундук
	if carry_id == "" and iu != null and String(iu.get("carry_id")) != "":
		var cid: String = String(iu.get("carry_id"))
		var cn: int = maxi(1, int(iu.get("carry_n")))
		var rot_b: bool = bool(iu.get("carry_rot"))
		var tgt0: Vector2i = _target(cid, rot_b)
		var cov0: Array = _covered(cid, tgt0.x, tgt0.y, rot_b)
		if cov0.is_empty():
			L().append({"id": cid, "n": cn, "x": tgt0.x, "y": tgt0.y, "r": rot_b})
		elif _add(cid, cn) > 0:
			Sound.play("ui_click", -2.0)
			return
		Game.inventory[cid] = maxi(0, Game.get_count(cid) - cn)
		iu.set("carry_id", "")
		iu.set("carry_n", 0)
		iu.set("carry_from_grid", false)
		iu.set("carry_rot", false)
		Game.hold = {}
		Game.layout_sync()
		Game.inventory_changed.emit()
		_sync_dict()
		_refresh()
		Sound.play("ui_click", -6.0)
		return
	if mb.button_index != MOUSE_BUTTON_LEFT and mb.button_index != MOUSE_BUTTON_RIGHT:
		return
	var idx: int = _index_at(grid.get_local_mouse_position())
	if carry_id == "":
		if idx < 0:
			return
		var e: Dictionary = L()[idx]
		if mb.ctrl_pressed or mb.shift_pressed or mb.double_click:
			_to_bag(String(e["id"]), int(e["n"]))
			L().remove_at(idx)
		elif mb.button_index == MOUSE_BUTTON_RIGHT and int(e["n"]) > 1:
			e["n"] = int(e["n"]) - 1
			carry_id = String(e["id"])
			carry_n = 1
			carry_rot = bool(e.get("r", false))
		else:
			carry_id = String(e["id"])
			carry_n = int(e["n"])
			carry_rot = bool(e.get("r", false))
			L().remove_at(idx)
		Sound.play("ui_click", -6.0)
	else:
		var tgt: Vector2i = _target(carry_id, carry_rot)
		var cov: Array = _covered(carry_id, tgt.x, tgt.y, carry_rot)
		if cov.has(-2) or cov.size() > 1:
			Sound.play("ui_click", -2.0)
			return
		if cov.is_empty():
			L().append({"id": carry_id, "n": carry_n, "x": tgt.x, "y": tgt.y, "r": carry_rot})
			carry_id = ""
			carry_rot = false
		else:
			var o: Dictionary = L()[int(cov[0])]
			if String(o["id"]) == carry_id and IT.stack(carry_id) > 1:
				var put: int = mini(carry_n, IT.stack(carry_id) - int(o["n"]))
				o["n"] = int(o["n"]) + put
				carry_n -= put
				if carry_n <= 0:
					carry_id = ""
			else:
				var old: Dictionary = {"id": String(o["id"]), "n": int(o["n"])}
				L().remove_at(int(cov[0]))
				L().append({"id": carry_id, "n": carry_n, "x": tgt.x, "y": tgt.y, "r": carry_rot})
				carry_id = String(old["id"])
				carry_n = int(old["n"])
				carry_rot = bool(o.get("r", false))
		Sound.play("ui_click", -6.0)
	_sync_dict()
	_refresh()


func _put_all() -> void:
	for id in Game.inventory.keys():
		var sid: String = String(id)
		if Game.get_count(sid) > 0 and not Game.hotbar.has(sid):
			store(sid, Game.get_count(sid))
	Sound.play("door", -8.0)


func _take_all() -> void:
	for e in L():
		_to_bag(String(e["id"]), int(e["n"]))
	L().clear()
	_sync_dict()
	_refresh()
	Sound.play("door", -8.0)


## Сложить: заново разложить всё по порядку (большие вещи — первыми)
func _sort() -> void:
	var all: Dictionary = {}
	for e in L():
		all[String(e["id"])] = int(all.get(String(e["id"]), 0)) + int(e["n"])
	L().clear()
	var ids: Array = all.keys()
	ids.sort_custom(func(a: Variant, b: Variant) -> bool:
		var sa: Vector2i = IT.size(String(a))
		var sb: Vector2i = IT.size(String(b))
		if sa.x * sa.y != sb.x * sb.y:
			return sa.x * sa.y > sb.x * sb.y
		return IT.name(String(a)) < IT.name(String(b)))
	for id in ids:
		var left: int = _add(String(id), int(all[id]))
		if left > 0:
			_to_bag(String(id), left)
	_sync_dict()
	_refresh()
	Sound.play("ui_click", -6.0)


func _input(event: InputEvent) -> void:
	if not open:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var k: Key = (event as InputEventKey).physical_keycode
		if k == KEY_R and _carry_any() != "":
			var rid: String = _carry_any()
			if IT.size(rid).x != IT.size(rid).y:
				if carry_id != "":
					carry_rot = not carry_rot
				else:
					var iu2: Node = get_tree().get_first_node_in_group("inventory_ui")
					if iu2 != null:
						iu2.set("carry_rot", not bool(iu2.get("carry_rot")))
				Sound.play("ui_click", -8.0)
			get_viewport().set_input_as_handled()
			return
		if k == KEY_ESCAPE or KB.is_key("interact", k) or KB.is_key("inventory", k):
			close_chest()
			get_viewport().set_input_as_handled()
		return
	# своя вещь в курсоре и клик мимо сундука — в сумку
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed and carry_id != "":
		if not Rect2(Vector2.ZERO, panel.size).has_point(panel.get_local_mouse_position()):
			_to_bag(carry_id, carry_n)
			carry_id = ""
			carry_n = 0
			_refresh()
			Sound.play("ui_click", -6.0)
			get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	if not open:
		return
	carry_icon.visible = carry_id != ""
	var mp: Vector2 = root.get_local_mouse_position()
	if carry_id != "":
		var sz: Vector2i = IT.size(carry_id)
		carry_icon.texture = preload("res://item_info.gd").ui_icon(carry_id)
		carry_icon.size = Vector2(sz.x * cell - 4, sz.y * cell - 4)
		carry_icon.position = mp - carry_icon.size / 2.0
		carry_icon.pivot_offset = carry_icon.size / 2.0
		carry_icon.rotation = PI / 2.0 if carry_rot else 0.0
	grid.queue_redraw()
	var idx: int = _index_at(grid.get_local_mouse_position()) if Rect2(Vector2.ZERO, grid.size).has_point(grid.get_local_mouse_position()) else -1
	if idx < 0 or carry_id != "":
		tip.visible = false
		tip_id = ""
		return
	var e: Dictionary = L()[idx]
	var key: String = "%s#%d" % [String(e["id"]), int(e["n"])]
	if key != tip_id:
		tip_id = key
		var extra: Array = [["В сундуке: %d шт." % int(e["n"]), "dim"], ["Ctrl+клик — в сумку", "hint"]]
		preload("res://item_info.gd").fill_box(tip_box, String(e["id"]), hud, extra)
		tip_box.reset_size()
		tip.visible = false
		return
	var bg: NinePatchRect = tip.get_node("bg")
	bg.size = tip_box.size + Vector2(36, 28)
	var tp: Vector2 = mp + Vector2(24, 18)
	if tp.x + bg.size.x > 1912.0:
		tp.x = mp.x - bg.size.x - 24.0
	tp.y = clampf(tp.y, 8.0, 1072.0 - bg.size.y)
	tip.position = tp
	tip.visible = true

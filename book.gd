extends CanvasLayer
## Книга травника в духе старинного гербария. Tab / J — открыть и закрыть.

const DB = preload("res://herbs_db.gd")
const FDB = preload("res://fish_db.gd")
const FD = preload("res://food_db.gd")
const W = preload("res://wild_db.gd")
const RDB = preload("res://recipes_db.gd")
const TIPS = preload("res://tips_db.gd")
const INK: Color = Color("3a2718")
const INK_SOFT: Color = Color("6b4f36")
const INK_FAINT: Color = Color(0.23, 0.15, 0.09, 0.38)
const O: Vector2 = Vector2(160, 80)
const PAGE_L: Rect2 = Rect2(206, 110, 754, 860)
const PAGE_R: Rect2 = Rect2(960, 110, 754, 860)
const CIRCLE_C: Vector2 = Vector2(583, 480)

var root: Control
var ink: Control
var font_title: Font
var font_body: Font
var font_italic: Font
var font_bold: Font

var title_l: Label
var latin_l: Label
var props_l: Label
var desc_l: Label
var where_l: Label
var fish_l: Label
var notes_l: Label
var notes_a: Label
var notes_b: Label
var right_title: Label
var hint_l: Label
var tab: String = "herb"        # herb / shroom / food / notes
var all_notes: bool = false     # на страничке показать все записи жителей (N)
var notes_off: int = 0
const GRID_BOTTOM: float = 850.0
var grid_row: int = 0           # первый видимый ряд сетки
var grid_vis: int = 999         # сколько рядов вмещается
var grid_max: int = 0           # на сколько рядов можно прокрутить
var grid_l: Label
var grid_labels: Array = []
var icon_tr: TextureRect
var selected: String = "mint"
var slots: Array = []           # [Rect2, id, kind]
var slot_labels: Dictionary = {}
var is_open: bool = false
var tex_cache: Dictionary = {}


func _ready() -> void:
	layer = 10
	# v31: пиксельный шрифт (ui31.gd); курсив — тот же шрифт (у пиксельного нет курсива)
	font_title = preload("res://ui31.gd").title_font()
	font_body = preload("res://ui31.gd").pixel_font(400)
	font_italic = preload("res://ui31.gd").pixel_font(400)
	font_bold = preload("res://ui31.gd").pixel_font(600)
	for id in DB.ORDER:
		tex_cache[id] = DB.icon(id)
	for sid in DB.SEEDS:
		tex_cache["seed_" + sid] = DB.seed_icon(sid)
	_build()
	root.visible = false


## v31: строки под описанием идут друг за другом — «Где растёт» и заметки не налезают на длинное описание
func _process(_delta: float) -> void:
	if root == null or not root.visible or desc_l == null:
		return
	var dy: float = desc_l.position.y + float(desc_l.get_line_count()) * float(desc_l.get_line_height()) + 8.0
	where_l.position.y = maxf(836.0, dy)
	var wy: float = where_l.position.y + float(where_l.get_line_count()) * float(where_l.get_line_height()) + 6.0
	notes_l.position.y = maxf(886.0, wy)


func lbl(text: String, font: Font, size: int, color: Color, pos: Vector2, w: float, h: float = 0.0) -> Label:
	var l: Label = Label.new()
	if h > 0.0:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.position = pos
	l.size = Vector2(w, h if h > 0.0 else size * 1.4)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.text = text
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(l)
	return l


func _build() -> void:
	root = Control.new()
	root.size = Vector2(1920, 1080)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0.06, 0.04, 0.03, 0.6)
	dim.size = Vector2(1920, 1080)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(dim)
	var bk: TextureRect = TextureRect.new()
	bk.texture = load("res://art/book.png")
	bk.position = O
	bk.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	bk.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bk)
	ink = Control.new()
	ink.size = Vector2(1920, 1080)
	ink.mouse_filter = Control.MOUSE_FILTER_STOP
	ink.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	root.add_child(ink)
	ink.draw.connect(_draw_ink)
	ink.gui_input.connect(_on_ink_input)

	# левая страница
	title_l = lbl("", font_title, 86, INK, Vector2(PAGE_L.position.x, 124), PAGE_L.size.x, 110)
	latin_l = lbl("", font_italic, 26, INK_SOFT, Vector2(PAGE_L.position.x, 224), PAGE_L.size.x)
	icon_tr = TextureRect.new()
	icon_tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon_tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_tr.size = Vector2(160, 240)
	icon_tr.position = CIRCLE_C - Vector2(80, 128)
	icon_tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(icon_tr)
	props_l = lbl("", font_bold, 30, INK, Vector2(PAGE_L.position.x, 694), PAGE_L.size.x)
	desc_l = lbl("", font_italic, 23, INK, Vector2(PAGE_L.position.x + 70, 740), PAGE_L.size.x - 140, 104)
	desc_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	where_l = lbl("", font_body, 21, INK_SOFT, Vector2(PAGE_L.position.x + 40, 836), PAGE_L.size.x - 80, 52)
	where_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notes_l = lbl("", font_italic, 20, Color("5a3a22"), Vector2(PAGE_L.position.x + 56, 886), PAGE_L.size.x - 112, 80)
	notes_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notes_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	notes_l.clip_text = true
	# страницы «Заметки»: два столбца текста
	notes_a = lbl("", font_body, 22, INK, Vector2(PAGE_L.position.x + 56, 306), PAGE_L.size.x - 112, 620)
	notes_a.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	notes_a.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notes_a.clip_text = true
	notes_b = lbl("", font_body, 22, INK, Vector2(PAGE_R.position.x + 56, 246), PAGE_R.size.x - 112, 590)
	notes_b.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	notes_b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notes_b.clip_text = true

	# правая страница
	right_title = lbl("Сумка травника", font_title, 74, INK, Vector2(PAGE_R.position.x, 124), PAGE_R.size.x, 100)
	fish_l = lbl("", font_italic, 22, INK_SOFT, Vector2(PAGE_R.position.x + 60, 836), PAGE_R.size.x - 120, 50)
	fish_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_l = lbl("J — закрыть   ·   A / D — листать   ·   Tab — раздел   ·   N — все записи", font_italic, 21, INK_SOFT, Vector2(PAGE_R.position.x, 890), PAGE_R.size.x)
	grid_l = lbl("", font_italic, 20, INK_SOFT, Vector2(PAGE_R.position.x, 858), PAGE_R.size.x)
	_build_grid()


## Сетка правой страницы зависит от вкладки: травы 8×6, грибы 4×3, еда 12×10
func _build_grid() -> void:
	for l in grid_labels:
		if is_instance_valid(l):
			(l as Node).queue_free()
	grid_labels.clear()
	slots.clear()
	slot_labels.clear()
	var ids: Array = []
	var kind: String = tab
	if tab == "herb":
		ids = DB.ORDER
	elif tab == "shroom":
		ids = W.SHROOMS.keys()
	elif tab == "food":
		ids = FD.ORDER
	elif tab == "animal":
		ids = ZOO.ORDER
	elif tab == "bird":
		ids = BD.ORDER
	var cols: int = 8
	var cs: float = 76.0
	var gap: float = 6.0
	var y0: float = 214.0
	if tab == "shroom":
		cols = 4
		cs = 120.0
		gap = 10.0
	elif tab == "food":
		cols = 12
		cs = 52.0
		gap = 4.0
		y0 = 206.0
	elif tab == "animal":
		cols = 5
		cs = 104.0
		gap = 10.0
	elif tab == "bird":
		cols = 8
		cs = 72.0
		gap = 6.0
	var sx: float = 1337.0 - (cols * cs + (cols - 1) * gap) / 2.0
	# v26: если ячейки не вмещаются на страничку — листаем рядами (колесо мыши, ↑/↓, PgUp/PgDn)
	grid_vis = 999
	if tab != "herb":
		grid_vis = maxi(1, int((GRID_BOTTOM - y0 + gap) / (cs + gap)))
	var total_rows: int = int(ceil(float(ids.size()) / cols))
	grid_max = maxi(0, total_rows - grid_vis)
	grid_row = clampi(grid_row, 0, grid_max)
	grid_l.visible = grid_max > 0
	if grid_max > 0:
		grid_l.text = "ряды %d–%d из %d   ·   колесо мыши или ↑ / ↓ — листать" % [grid_row + 1, grid_row + grid_vis, total_rows]
	for i in range(ids.size()):
		var row: int = i / cols - grid_row
		if row < 0 or row >= grid_vis:
			continue
		var id: String = String(ids[i])
		var r: Rect2 = Rect2(sx + (i % cols) * (cs + gap), y0 + row * (cs + gap), cs, cs)
		slots.append([r, id, kind])
		var fs: int = 19 if tab != "food" else 14
		var cnt: Label = lbl("", font_bold, fs, INK, Vector2(r.end.x - 44, r.end.y - fs * 1.4), 40)
		cnt.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		slot_labels[id] = cnt
		grid_labels.append(cnt)
	if tab == "herb":
		var seeds_y: float = y0 + ceilf(float(ids.size()) / cols) * (cs + gap) + 10.0
		var sx2: float = 1337.0 - (3.0 * 84.0 + 2.0 * 30.0) / 2.0
		for i in range(DB.SEEDS.size()):
			var sid: String = DB.SEEDS[i]
			var r2: Rect2 = Rect2(sx2 + i * 114.0, seeds_y, 84.0, 84.0)
			slots.append([r2, sid, "seed"])
			var c2: Label = lbl("", font_bold, 20, INK, Vector2(r2.end.x - 46, r2.end.y - 30), 40)
			c2.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			slot_labels["seed_" + sid] = c2
			grid_labels.append(c2)
	fish_l.visible = tab == "herb"
	notes_a.visible = tab == "notes"
	notes_b.visible = tab == "notes"
	desc_l.visible = tab != "notes"
	where_l.visible = tab != "notes"
	notes_l.visible = tab != "notes"
	props_l.visible = tab != "notes"
	icon_tr.visible = tab != "notes"
	right_title.text = {"herb": "Сумка травника", "shroom": "Грибы", "food": "Блюда и плоды", "notes": "Заметки", "animal": "Звери", "bird": "Птицы"}[tab]


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var k: InputEventKey = event
	if not k.pressed or k.echo:
		return
	if KB.is_key("book", k.physical_keycode):
		if is_open:
			close()
		elif not Game.busy and not Game.ui_open:
			open()
		get_viewport().set_input_as_handled()
	elif is_open and k.physical_keycode == KEY_ESCAPE:
		close()
		get_viewport().set_input_as_handled()
	elif is_open and (KB.is_key("move_left", k.physical_keycode) or k.physical_keycode == KEY_LEFT):
		_step(-1)
		get_viewport().set_input_as_handled()
	elif is_open and (KB.is_key("move_right", k.physical_keycode) or k.physical_keycode == KEY_RIGHT):
		_step(1)
		get_viewport().set_input_as_handled()
	elif is_open and (k.physical_keycode == KEY_DOWN or k.physical_keycode == KEY_PAGEDOWN):
		_scroll_grid(1 if k.physical_keycode == KEY_DOWN else grid_vis)
		get_viewport().set_input_as_handled()
	elif is_open and (k.physical_keycode == KEY_UP or k.physical_keycode == KEY_PAGEUP):
		_scroll_grid(-1 if k.physical_keycode == KEY_UP else -grid_vis)
		get_viewport().set_input_as_handled()
	elif is_open and k.physical_keycode == KEY_N:
		all_notes = not all_notes
		refresh()
		get_viewport().set_input_as_handled()
	elif is_open and k.physical_keycode == KEY_TAB:
		var order: Array = ["herb", "shroom", "food", "animal", "bird", "notes"]
		set_tab(String(order[(order.find(tab) + 1) % order.size()]))
		get_viewport().set_input_as_handled()


func set_tab(t: String) -> void:
	if t == tab:
		return
	tab = t
	all_notes = false
	notes_off = 0
	grid_row = 0
	if tab == "herb":
		if not DB.DATA.has(selected) and not FDB.is_fish(selected):
			selected = String(DB.ORDER[0])
	elif tab == "shroom":
		selected = String(W.SHROOMS.keys()[0])
	elif tab == "food":
		selected = String(FD.ORDER[0])
	elif tab == "animal":
		selected = String(ZOO.ORDER[0])
	elif tab == "bird":
		selected = String(BD.ORDER[0])
	_build_grid()
	Sound.play("page", -8.0, 0.1)
	refresh()


func _step(d: int) -> void:
	if tab == "notes":
		notes_off = maxi(0, notes_off + d * NOTES_PER_PAGE)
		refresh()
		return
	var pages: Array = _pages()
	var i: int = pages.find(selected)
	selected = String(pages[posmod(i + d, pages.size())])
	all_notes = false
	_show_selected_row()
	refresh()


## Прокрутить сетку так, чтобы выбранная ячейка была видна
func _show_selected_row() -> void:
	if tab == "herb" or tab == "notes" or grid_max <= 0:
		return
	var idx: int = _pages().find(selected)
	if idx < 0:
		return
	var cols: int = {"shroom": 4, "food": 12, "animal": 5, "bird": 8}.get(tab, 8)
	var row: int = idx / cols
	var want: int = grid_row
	if row < grid_row:
		want = row
	elif row >= grid_row + grid_vis:
		want = row - grid_vis + 1
	if want != grid_row:
		grid_row = want
		_build_grid()


func _scroll_grid(d: int) -> void:
	if grid_max <= 0:
		return
	var n: int = clampi(grid_row + d, 0, grid_max)
	if n == grid_row:
		return
	grid_row = n
	_build_grid()
	Sound.play("page", -10.0, 0.1)
	refresh()


func open() -> void:
	if hint_l != null:   # v24: подсказка — с клавишами из настроек
		hint_l.text = "%s — закрыть   ·   %s / %s — листать   ·   Tab — раздел   ·   N — все записи" % [KB.key_name("book"), KB.key_name("move_left"), KB.key_name("move_right")]
	is_open = true
	Game.ui_open = true
	root.visible = true
	refresh()
	get_tree().create_timer(0.05).timeout.connect(ink.queue_redraw)
	root.modulate.a = 0.0
	root.position.y = 24.0
	var tw: Tween = create_tween().set_parallel(true)
	tw.tween_property(root, "modulate:a", 1.0, 0.22)
	tw.tween_property(root, "position:y", 0.0, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func close() -> void:
	is_open = false
	Game.ui_open = false
	var tw: Tween = create_tween()
	tw.tween_property(root, "modulate:a", 0.0, 0.15)
	tw.tween_callback(func() -> void: root.visible = false)


func _known(id: String) -> bool:
	return Game.discovered.has(id) or Game.get_count(id) > 0 or int(Game.eaten.get(id, 0)) > 0


func _heard(id: String) -> bool:
	return Game.notes.has(id) and not (Game.notes[id] as Array).is_empty()


func _fish_known(id: String) -> bool:
	return int(Game.fish_caught.get(id, 0)) > 0


func _pages() -> Array:
	if tab == "shroom":
		return W.SHROOMS.keys()
	if tab == "food":
		return FD.ORDER
	if tab == "animal":
		return ZOO.ORDER
	if tab == "bird":
		return BD.ORDER
	return DB.ORDER + FDB.ORDER


## Страница рыбы: название, сколько поймано, цена, когда лучше клюёт
func _refresh_fish() -> void:
	var d: Dictionary = FDB.DATA[selected]
	var known: bool = _fish_known(selected)
	title_l.text = String(d["name"]) if known else "???"
	latin_l.text = ("Поймано: %d" % int(Game.fish_caught.get(selected, 0))) if known else "неизвестная рыба"
	icon_tr.texture = FDB.icon(selected)
	icon_tr.modulate = Color(1, 1, 1, 1) if known else Color(0.2, 0.13, 0.08, 0.35)
	props_l.text = ("Цена: %d мон.   ·   Скупщик у вывески" % int(d["price"])) if known else "?   ·   ?"
	desc_l.text = String(d["desc"]) if known else "Эту рыбу ты ещё не ловила. Загляни на пруд — у каждой рыбы своё время."
	where_l.text = "Ловится в пруду" if known else ""
	notes_l.text = ""
	_refresh_counts()
	_refresh_fish_note()
	ink.queue_redraw()


func _refresh_fish_note() -> void:
	var n: int = 0
	for fid in FDB.ORDER:
		n += Game.get_count(String(fid))
	fish_l.text = "Рыбы в сумке: %d  ·  страницы рыб — дальше за травами" % n


func _refresh_counts() -> void:
	for s in slots:
		var id: String = String(s[1])
		var key: String = ("seed_" + id) if String(s[2]) == "seed" else id
		if not slot_labels.has(key):
			continue
		var c: int = int(Game.seeds.get(id, 0)) if String(s[2]) == "seed" else Game.get_count("food_" + id if String(s[2]) == "food" else id)
		(slot_labels[key] as Label).text = str(c) if c > 0 or String(s[2]) == "seed" else ""


## Записи жителей на страничке: последние две (или все по N)
func _show_notes(id: String) -> void:
	var arr: Array = Game.notes.get(id, [])
	if arr.is_empty():
		notes_l.text = ""
		return
	if all_notes:
		var lines: Array = []
		for t in arr:
			lines.append("✎ " + String(t))
		notes_l.size.y = 130.0
		notes_l.position.y = 760.0
		desc_l.text = ""
		where_l.text = ""
		notes_l.text = "\n".join(lines)
		return
	notes_l.size.y = 80.0
	notes_l.position.y = 886.0
	var show: Array = arr.slice(maxi(0, arr.size() - 2))
	var out: Array = []
	for t in show:
		var s: String = String(t)
		out.append("✎ " + (s if s.length() < 96 else s.substr(0, 93) + "…"))
	if arr.size() > 2:
		out.append("   … записей: %d (N — все)" % arr.size())
	notes_l.text = "\n".join(out)


func refresh() -> void:
	_refresh_fish_note()
	ink.queue_redraw()
	notes_l.size.y = 80.0
	notes_l.position.y = 886.0
	if tab == "notes":
		_refresh_notes()
		return
	if FDB.is_fish(selected):
		_refresh_fish()
		return
	if tab == "shroom":
		_refresh_shroom()
		return
	if tab == "food":
		_refresh_food()
		return
	if tab == "animal":
		_refresh_animal()
		return
	if tab == "bird":
		_refresh_bird()
		return
	var d: Dictionary = DB.DATA[selected]
	var known: bool = _known(selected)
	var heard: bool = _heard(selected)
	title_l.text = String(d["name"]) if (known or heard) else "???"
	latin_l.text = String(d["latin"]) if known else ("неизвестная трава" if not heard else "знаешь только по рассказам")
	icon_tr.texture = DB.icon(selected)
	icon_tr.modulate = Color(1, 1, 1, 1) if known else Color(0.2, 0.13, 0.08, 0.35)
	var parts: Array = []
	for p in d["props"]:
		parts.append("%s %s" % [p[0], p[1]])
	props_l.text = "   ·   ".join(parts) if known else "?   ·   ?"
	desc_l.text = (String(d["desc"]) + "\n\n" + String(preload("res://harvest_db.gd").q(selected)["text"])) if known else "Эту траву ты ещё не находила. Травы растут в разных краях мира — каждая в своих."
	where_l.text = ("Где растёт: " if known else "Говорят, её видели: ") + String(d["where"])
	_refresh_counts()
	_show_notes(selected)
	ink.queue_redraw()


func _shroom_props(id: String) -> Array:
	var out: Array = []
	var pr: Dictionary = RDB.SHROOM_PROPS.get(id, {})
	for k in pr.keys():
		out.append([String(k), ["I", "II", "III"][clampi(int(pr[k]) - 1, 0, 2)]])
	return out


func _refresh_shroom() -> void:
	var d: Dictionary = W.SHROOMS[selected]
	var known: bool = _known(selected)
	var heard: bool = _heard(selected)
	title_l.text = String(d["name"]) if (known or heard) else "???"
	latin_l.text = (("Съедобный" if float(d["food"]) > 0.0 else "Ядовитый, не ешь!") if known else "неизвестный гриб")
	icon_tr.texture = W.shroom_icon(selected)
	icon_tr.modulate = Color(1, 1, 1, 1) if known else Color(0.2, 0.13, 0.08, 0.35)
	var parts: Array = []
	for p in _shroom_props(selected):
		parts.append("%s %s" % [p[0], p[1]])
	props_l.text = "   ·   ".join(parts) if known else "?   ·   ?"
	desc_l.text = ("Цена: %d мон.   ·   Сытость: %d%%" % [int(d["price"]), int(maxf(0.0, float(d["food"])) * 100.0)]) if known else "Этот гриб ты ещё не находила. Расспроси жителей или поищи в лесу."
	where_l.text = String(d["need"]) if known else ""
	_refresh_counts()
	_show_notes(selected)
	ink.queue_redraw()


func _recipe_text(fid: String) -> String:
	for r in FD.RECIPES:
		if "food_" + String(r[1]) == fid:
			var names: Array = []
			for nd in (r[0] as Array):
				names.append(TIPS._ing_name(String(nd)))
			return "Рецепт: " + " + ".join(names) + " (костёр, E)"
	return ""


func _food_known(fk: String) -> bool:
	return _known("food_" + fk) or Game.cooked.has("food_" + fk)


func _refresh_food() -> void:
	var fk: String = selected
	var fid: String = "food_" + fk
	var d: Array = FD.DATA[fk]
	var known: bool = _food_known(fk)
	var heard: bool = _heard(fid)
	title_l.text = String(d[0]) if (known or heard) else "???"
	latin_l.text = String(FD.KINDS.get(String(d[1]), "")) if known else "неизвестное блюдо"
	icon_tr.texture = FD.icon(fid)
	icon_tr.modulate = Color(1, 1, 1, 1) if known else Color(0.2, 0.13, 0.08, 0.35)
	var parts: Array = []
	if float(d[2]) > 0.0:
		parts.append("Сытость +%d%%" % int(float(d[2]) * 100.0))
	if float(d[3]) > 0.0:
		parts.append("Жажда +%d%%" % int(float(d[3]) * 100.0))
	props_l.text = "   ·   ".join(parts) if known else "?   ·   ?"
	var rt: String = _recipe_text(fid)
	desc_l.text = (String(d[6]) + (("\n" + rt) if rt != "" else "")) if known else "Этого блюда ты ещё не пробовала. Спрашивай жителей, смотри в лавках, срывай плоды с деревьев."
	where_l.text = ("Где взять: %s   ·   Цена: %d мон.   ·   Съедено: %d" % [String(d[5]), int(d[4]), int(Game.eaten.get(fid, 0))]) if known else ""
	_refresh_counts()
	_show_notes(fid)
	ink.queue_redraw()


const NOTES_PER_PAGE: int = 8


func _refresh_notes() -> void:
	title_l.text = "Записи"
	latin_l.text = "что рассказали жители"
	icon_tr.texture = null
	props_l.text = ""
	desc_l.text = ""
	where_l.text = ""
	notes_l.text = ""
	var groups: Dictionary = {"animal": [], "place": [], "life": [], "craft": []}
	for n in Game.misc_notes:
		if groups.has(String(n["cat"])):
			(groups[String(n["cat"])] as Array).append(String(n["text"]))
	var left: Array = []
	var right: Array = []
	for c in ["animal", "place"]:
		for t in groups[c]:
			left.append(String(t))
	for c in ["life", "craft"]:
		for t in groups[c]:
			right.append(String(t))
	var pages_l: int = maxi(1, int(ceil(float(left.size()) / NOTES_PER_PAGE)))
	var pages_r: int = maxi(1, int(ceil(float(right.size()) / NOTES_PER_PAGE)))
	var pg_max: int = maxi(pages_l, pages_r)
	notes_off = clampi(notes_off, 0, (pg_max - 1) * NOTES_PER_PAGE)
	notes_a.text = _notes_text(left, "Звери и места")
	notes_b.text = _notes_text(right, "Жизнь и ремесло")
	var cnt_h: int = 0
	var cnt_s: int = 0
	var cnt_f: int = 0
	for key in Game.notes.keys():
		var ks: String = String(key)
		if ks.begins_with("food_"):
			cnt_f += (Game.notes[key] as Array).size()
		elif W.is_shroom(ks):
			cnt_s += (Game.notes[key] as Array).size()
		else:
			cnt_h += (Game.notes[key] as Array).size()
	fish_l.visible = true
	fish_l.text = "Страница %d из %d  ·  о травах %d, о грибах %d, о еде %d записей" % [notes_off / NOTES_PER_PAGE + 1, pg_max, cnt_h, cnt_s, cnt_f]
	ink.queue_redraw()


func _notes_text(lst: Array, head: String) -> String:
	if lst.is_empty():
		return head + "\n\nПока пусто. Попроси совет у жителей («Дай совет») — и он запишется сюда."
	var out: Array = [head + "  (%d)" % lst.size(), ""]
	var i0: int = notes_off
	for i in range(i0, mini(lst.size(), i0 + NOTES_PER_PAGE)):
		out.append("• " + String(lst[i]))
		out.append("")
	return "\n".join(out)


func _on_ink_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		var bi: int = (event as InputEventMouseButton).button_index
		if bi == MOUSE_BUTTON_WHEEL_DOWN:
			_scroll_grid(1)
			return
		if bi == MOUSE_BUTTON_WHEEL_UP:
			_scroll_grid(-1)
			return
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var mp: Vector2 = (event as InputEventMouseButton).position
		# закладки-вкладки справа
		for i in range(TABS.size()):
			if Rect2(1718, 160.0 + i * 86.0, 76, 78).has_point(mp):
				set_tab(String(TABS[i][1]))
				return
		for s in slots:
			var r: Rect2 = s[0]
			if r.has_point(mp) and String(s[2]) != "seed":
				selected = String(s[1])
				all_notes = false
				refresh()


# ------------------------------------------------------------------ рисование чернилами

const TABS: Array = [[Color("2f5a3a"), "herb"], [Color("7a2a32"), "shroom"], [Color("2e4a72"), "food"], [Color("8a6a2a"), "animal"], [Color("3a6a72"), "bird"], [Color("6a4a22"), "notes"]]
const ZOO = preload("res://farm23.gd")
const BD = preload("res://birds_db.gd")
const BL = preload("res://birds_lore24.gd")


## v24: значок птицы — первый кадр листа (12 кадров)
func _bird_tex(id: String) -> Texture2D:
	if not tex_cache.has("bd_" + id):
		var src: Texture2D = load("res://art/bird_%s.png" % id)
		var at: AtlasTexture = AtlasTexture.new()
		at.atlas = src
		at.region = Rect2(0, 0, src.get_width() / 12.0, src.get_height())
		tex_cache["bd_" + id] = at
	return tex_cache["bd_" + id]


## Птицу знаешь, если видела вблизи (вспорхнула от тебя), поймала или нашла её перо
func _bird_known(id: String) -> bool:
	return Game.birds_seen.has(id) or Game.birds_met.has(id) or Game.discovered.has(BD.feather(id))


## v24: страница птицы — кто такая, где и когда встречается, что даёт её перо в котле
func _refresh_bird() -> void:
	var known: bool = _bird_known(selected)
	var d: Dictionary = BD.DATA[selected]
	title_l.text = String(d["name"]) if known else "???"
	var kind: String = "Волшебная птица" if bool(d.get("magic", false)) else ("Сова" if bool(d.get("owl", false)) else "Птица")
	latin_l.text = (kind + " · " + {"s": "маленькая", "m": "средняя", "l": "большая", "xl": "огромная"}.get(String(d["size"]), "")) if known else "ещё не встречала"
	icon_tr.texture = _bird_tex(selected)
	icon_tr.modulate = Color.WHITE if known else Color(0.2, 0.13, 0.08, 0.35)
	var pr: Array = []
	for p in (d["props"] as Dictionary):
		pr.append("%s %d" % [String(p), int(d["props"][p])])
	props_l.text = ("Перо в котле: " + ", ".join(pr)) if known else "?"
	var caught: int = int(Game.birds_seen.get(selected, 0))
	desc_l.text = BL.text(selected) if known else "Эту птицу ты ещё не видела. Подойди тихонько, когда услышишь её голос."
	where_l.text = ("Где: %s   ·   Когда: %s, %s" % [BL.where(d), String(BL.WHEN_RU.get(String(d["when"]), "")), String(BL.PERCH_RU.get(String(d["perch"]), ""))]) if known else ""
	notes_l.text = ("Перо стоит %d мон.%s" % [int(d["price"]), ("   ·   Поймала: %d" % caught) if caught > 0 else ""]) if known else ""
	ink.queue_redraw()


## v23: значок зверя — первый кадр листа
func _animal_tex(id: String) -> Texture2D:
	if not tex_cache.has("an_" + id):
		var src: Texture2D = load("res://art/animal_%s.png" % id)
		var at: AtlasTexture = AtlasTexture.new()
		at.atlas = src
		at.region = Rect2(0, 0, src.get_width() / 12.0, src.get_height())
		tex_cache["an_" + id] = at
	return tex_cache["an_" + id]


func _animal_known(id: String) -> bool:
	return Game.animals_seen.has(id) or Game.met.has(id)


## v23: страница зверя — кто такой, где живёт, что любит, какой от него толк, сколько у тебя в загонах
func _refresh_animal() -> void:
	var known: bool = _animal_known(selected)
	var z: Array = ZOO.ZOO[selected]
	var info: Dictionary = W.ANIMALS.get(selected, {})
	title_l.text = String(info.get("name", selected)) if known else "???"
	var mine: int = 0
	for e in Game.farm:
		if String(e["kind"]) == selected:
			mine += 1
	latin_l.text = ("Волшебный зверь" if bool(info.get("mythic", false)) else ("Домашний зверь" if bool(info.get("farm", false)) else "Дикий зверь")) if known else "ещё не встречала"
	icon_tr.texture = _animal_tex(selected)
	icon_tr.modulate = Color.WHITE if known else Color(0.2, 0.13, 0.08, 0.35)
	var likes: Array = []
	for k in (z[2] as Array):
		likes.append({"veg": "овощи", "berry": "ягоды", "fruit": "фрукты", "meat": "мясо", "fish": "рыбу", "bread": "хлеб и выпечку", "nut": "орехи", "sweet": "сладкое", "mushroom": "грибы", "soup": "супы", "dairy": "молочное"}.get(String(k), String(k)))
	var pr: Array = z[3]
	props_l.text = ("Любит: " + ", ".join(likes)) if known else "?"
	desc_l.text = (String(z[0]) + "
В загоне даёт: %s ×%d в день." % [preload("res://items_db.gd").name(String(pr[0])), int(pr[1])]) if known else "Этого зверя ты ещё не видела. Подойди поближе, когда встретишь."
	where_l.text = ("Где живёт: %s   ·   Малыши: %d%%%s" % [String(z[1]), int(float(z[4]) * 100.0), ("   ·   В загонах: %d" % mine) if mine > 0 else ""]) if known else ""
	notes_l.text = "Возьми в руку угощение и нажми E у зверя — пойдёт за тобой в загон." if known else ""
	ink.queue_redraw()


## Какой значок рисовать в ячейке: [текстура, размер, сдвиг]
func _slot_icon(kind: String, id: String) -> Array:
	if kind == "herb":
		return [tex_cache[id], Vector2(44, 66), Vector2(0, -6)]
	# текстуры держим в кэше: рисование откладывается, а несохранённая картинка к тому времени исчезает (белый квадрат)
	if kind == "shroom":
		if not tex_cache.has("sh_" + id):
			tex_cache["sh_" + id] = W.shroom_icon(id)
		return [tex_cache["sh_" + id], Vector2(84, 84), Vector2(0, 0)]
	if kind == "animal":
		return [_animal_tex(id), Vector2(84, 76), Vector2(0, 0)]
	if kind == "bird":
		return [_bird_tex(id), Vector2(58, 50), Vector2(0, 0)]
	if kind == "food":
		if not tex_cache.has("fd_" + id):
			tex_cache["fd_" + id] = FD.icon("food_" + id)
		return [tex_cache["fd_" + id], Vector2(40, 40), Vector2(0, 0)]
	return [tex_cache["seed_" + id], Vector2(56, 56), Vector2(0, -2)]


func _slot_known(kind: String, id: String) -> bool:
	if kind == "animal":
		return _animal_known(id)
	if kind == "bird":
		return _bird_known(id)
	if kind == "food":
		return _food_known(id)
	return _known(id)


func _draw_ink() -> void:
	for page in [PAGE_L, PAGE_R]:
		var pr: Rect2 = page
		var f1: Rect2 = pr.grow(-34)
		var f2: Rect2 = pr.grow(-42)
		ink.draw_rect(f1, INK_FAINT, false, 2.0)
		ink.draw_rect(f2, INK_FAINT, false, 1.0)
		for c in [f1.position, Vector2(f1.end.x, f1.position.y), Vector2(f1.position.x, f1.end.y), f1.end]:
			var cp: Vector2 = c
			_diamond(cp, 7.0, INK_SOFT)
			ink.draw_arc(cp, 13.0, 0.0, TAU, 24, INK_FAINT, 1.5)
	_flourish(Vector2(583, 276), 210.0)
	_flourish(Vector2(1337, 200), 230.0)
	if tab == "notes":
		_draw_ribbons()
		return
	# круг с иллюстрацией
	var is_fish: bool = FDB.is_fish(selected)
	var known: bool = _fish_known(selected) if is_fish else _slot_known(tab, selected)
	ink.draw_arc(CIRCLE_C, 132.0, 0.0, TAU, 128, INK, 3.0)
	ink.draw_arc(CIRCLE_C, 124.0, 0.0, TAU, 128, INK_FAINT, 1.5)
	for i in range(48):
		var a: float = i / 48.0 * TAU
		var r0: float = 138.0
		var r1: float = 144.0 if i % 4 == 0 else 141.0
		ink.draw_line(CIRCLE_C + Vector2(cos(a), sin(a)) * r0, CIRCLE_C + Vector2(cos(a), sin(a)) * r1, INK_SOFT, 1.5)
	var props: Array = []
	if is_fish or tab == "food" or tab == "animal":
		props = []
	elif tab == "bird":
		for bp0 in (BD.DATA[selected]["props"] as Dictionary):
			props.append([bp0, int(BD.DATA[selected]["props"][bp0])])
	elif tab == "shroom":
		props = _shroom_props(selected)
	else:
		props = DB.DATA[selected]["props"]
	for i in range(6):
		var a2: float = -PI / 2.0 + i * TAU / 6.0
		var bp: Vector2 = CIRCLE_C + Vector2(cos(a2), sin(a2)) * 182.0
		var has: bool = known and i < props.size()
		ink.draw_line(CIRCLE_C + Vector2(cos(a2), sin(a2)) * 146.0, bp - Vector2(cos(a2), sin(a2)) * 30.0, INK_FAINT, 1.5)
		ink.draw_circle(bp, 29.0, Color(0.95, 0.88, 0.72, 0.55))
		ink.draw_arc(bp, 29.0, 0.0, TAU, 48, INK if has else INK_FAINT, 2.5 if has else 1.5)
		if has:
			_glyph(String(props[i][0]), bp, 15.0, INK)
		else:
			ink.draw_circle(bp, 3.0, INK_FAINT)
	# слоты
	for s in slots:
		var r: Rect2 = s[0]
		var id: String = s[1]
		var kind: String = s[2]
		var sel: bool = kind != "seed" and id == selected
		ink.draw_rect(r, Color(0.36, 0.22, 0.12, 0.08), true)
		ink.draw_rect(r, INK if sel else INK_FAINT, false, 3.0 if sel else 1.5)
		if r.size.x > 60.0:
			ink.draw_rect(r.grow(-6), INK_FAINT, false, 1.0)
		if sel:
			for c2 in [r.position, Vector2(r.end.x, r.position.y), Vector2(r.position.x, r.end.y), r.end]:
				_diamond(c2, 6.0 if r.size.x > 60.0 else 4.0, INK)
		var info: Array = _slot_icon(kind, id)
		var tx: Texture2D = info[0]
		var sz: Vector2 = info[1]
		var dst: Rect2 = Rect2(r.get_center() - sz / 2.0 + (info[2] as Vector2), sz)
		var mod: Color = Color.WHITE
		if kind != "seed" and not _slot_known(kind, id):
			mod = Color(0.2, 0.13, 0.08, 0.3)
		ink.draw_texture_rect(tx, dst, false, mod)
		# красная точка: про этот предмет есть записи жителей
		var nid: String = ("food_" + id) if kind == "food" else id
		if kind != "seed" and _heard(nid):
			ink.draw_circle(r.position + Vector2(r.size.x - 8.0, 8.0), 4.0, Color("7a2a32"))
	_draw_ribbons()


## Закладки-ленты: травы, грибы, еда, заметки
func _draw_ribbons() -> void:
	for i in range(TABS.size()):
		var col: Color = TABS[i][0]
		var y: float = 160.0 + i * 86.0
		var active: bool = String(TABS[i][1]) == tab
		var x0: float = 1752.0 + (6.0 if active else 0.0)
		var pts: PackedVector2Array = PackedVector2Array([Vector2(x0 - 30, y), Vector2(x0 + 34, y), Vector2(x0 + 24, y + 38), Vector2(x0 + 34, y + 76), Vector2(x0 - 30, y + 76)])
		ink.draw_colored_polygon(pts, col.darkened(0.0 if active else 0.25))
		ink.draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[4]]), col.darkened(0.45), 2.0)
		ink.draw_line(Vector2(x0 - 30, y + 6), Vector2(x0 + 30, y + 6), col.lightened(0.3), 1.5)
		match String(TABS[i][1]):
			"herb":
				ink.draw_texture_rect(tex_cache["mint"], Rect2(Vector2(x0 - 14, y + 12), Vector2(32, 48)), false)
			"shroom":
				ink.draw_texture_rect(_slot_icon("shroom", "fly_agaric")[0], Rect2(Vector2(x0 - 14, y + 16), Vector2(36, 36)), false)
			"food":
				ink.draw_texture_rect(_slot_icon("food", "apple")[0], Rect2(Vector2(x0 - 14, y + 16), Vector2(36, 36)), false)
			"animal":
				ink.draw_texture_rect(_animal_tex("chicken"), Rect2(Vector2(x0 - 16, y + 16), Vector2(40, 40)), false)
			"bird":
				ink.draw_texture_rect(_bird_tex("robin"), Rect2(Vector2(x0 - 16, y + 18), Vector2(40, 34)), false)
			"notes":
				ink.draw_line(Vector2(x0 - 12, y + 56), Vector2(x0 + 14, y + 20), Color("e8dcc0"), 3.0)
				ink.draw_line(Vector2(x0 - 12, y + 56), Vector2(x0 - 16, y + 62), Color("e8dcc0"), 3.0)
				ink.draw_line(Vector2(x0 + 14, y + 20), Vector2(x0 + 6, y + 36), Color("e8dcc0"), 2.0)


func _diamond(c: Vector2, s: float, col: Color) -> void:
	ink.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -s), c + Vector2(s, 0), c + Vector2(0, s), c + Vector2(-s, 0)]), col)


func _flourish(c: Vector2, hw: float) -> void:
	ink.draw_line(c - Vector2(hw, 0), c - Vector2(16, 0), INK_SOFT, 2.0)
	ink.draw_line(c + Vector2(16, 0), c + Vector2(hw, 0), INK_SOFT, 2.0)
	_diamond(c, 8.0, INK)
	ink.draw_arc(c, 13.0, 0.0, TAU, 24, INK_FAINT, 1.5)
	for s in [-1.0, 1.0]:
		var e: Vector2 = c + Vector2(hw * s, 0)
		ink.draw_circle(e, 3.5, INK_SOFT)
		ink.draw_arc(e - Vector2(10 * s, 7), 7.0, 0.0, PI, 16, INK_FAINT, 1.5)
		ink.draw_arc(c + Vector2((hw * 0.5) * s, 0) + Vector2(0, -6), 6.0, 0.0, PI, 12, INK_FAINT, 1.5)


func _glyph(kind: String, c: Vector2, s: float, col: Color) -> void:
	var w: float = 2.6
	match kind:
		"Свежесть":
			for i in range(3):
				var a: float = i * PI / 3.0
				var d: Vector2 = Vector2(cos(a), sin(a)) * s
				ink.draw_line(c - d, c + d, col, w)
				for e in [d, -d]:
					var ev: Vector2 = e
					var n: Vector2 = ev.normalized()
					var p: Vector2 = c + ev * 0.65
					ink.draw_line(p, p + n.rotated(0.7) * s * 0.3, col, 2.0)
					ink.draw_line(p, p + n.rotated(-0.7) * s * 0.3, col, 2.0)
		"Покой":
			ink.draw_arc(c, s * 0.85, PI * 0.45, PI * 1.75, 28, col, 4.0)
			ink.draw_arc(c + Vector2(s * 0.3, -s * 0.15), s * 0.6, PI * 0.5, PI * 1.6, 24, col, 1.5)
		"Сон":
			var pts: PackedVector2Array = PackedVector2Array()
			for i in range(6):
				var a2: float = -PI / 2.0 + i * TAU * 2.0 / 5.0
				pts.append(c + Vector2(cos(a2), sin(a2)) * s)
			ink.draw_polyline(pts, col, w)
		"Тепло":
			ink.draw_arc(c, s * 0.4, 0.0, TAU, 24, col, w)
			for i in range(8):
				var a3: float = i * TAU / 8.0
				ink.draw_line(c + Vector2(cos(a3), sin(a3)) * s * 0.62, c + Vector2(cos(a3), sin(a3)) * s, col, 2.0)
		"Исцеление":
			ink.draw_line(c + Vector2(0, -s), c + Vector2(0, s), col, 5.0)
			ink.draw_line(c + Vector2(-s, 0), c + Vector2(s, 0), col, 5.0)
		"Сила":
			var fl: PackedVector2Array = PackedVector2Array([c + Vector2(0, -s), c + Vector2(s * 0.55, -s * 0.1), c + Vector2(s * 0.6, s * 0.5), c + Vector2(0, s), c + Vector2(-s * 0.6, s * 0.5), c + Vector2(-s * 0.3, -s * 0.2), c + Vector2(-s * 0.05, s * 0.1), c + Vector2(0, -s)])
			ink.draw_polyline(fl, col, w)
		"Жгучесть":
			ink.draw_polyline(PackedVector2Array([c + Vector2(s * 0.3, -s), c + Vector2(-s * 0.4, 0), c + Vector2(s * 0.3, 0), c + Vector2(-s * 0.3, s)]), col, w)
		_:
			ink.draw_circle(c, s * 0.3, col)

extends CanvasLayer
## Инвентарь на Tab (и на I) в духе Path of Exile: тёмная каменная панель с золотым гербом,
## слоты снаряжения как в PoE и сетка сумки 12×5 под ними.
##   основная и вторая рука (два набора I / II, переключение X) — инструменты для сбора, фонарь, гербарий
##   голова, тело, руки, ноги, амулет, два кольца, пояс (даёт ячейки зелий), 5 ячеек зелий (пьются на Z)
##   рюкзак (корзина для грибов, сумка травницы, садок...) — открывает ряды сетки и прибавляет вес
## Мышь: левая — взять вещь / надеть в слот / положить обратно; правая — сразу надеть (или снять),
## для трав и прочего — положить в выбранную ячейку панели быстрого доступа (1–8).

const IT = preload("res://items_db.gd")
const RDB = preload("res://recipes_db.gd")
const W: float = 768.0
const H: float = 1040.0
const XO: float = 32.0    # v26: панель шире — всё старое сдвинуто на XO
const CELL: float = 44.0   # v26: клетки крупнее (было 40), в сумке 16×7
const PY: float = 20.0
const COLS: int = 16
const ROWS: int = 7
const GRID_Y: float = 664.0
const GOLD: Color = Color("c8a96e")
const GOLD_HI: Color = Color("f0d89a")
const TXT: Color = Color("a89878")
const MAGIC: Color = Color("8ea8ff")
const BAD: Color = Color("d86a5a")

# слот -> [прямоугольник, значок-силуэт пустого слота]
const SLOTS: Dictionary = {
	"main": [Rect2(56, 134, 120, 232), "axe"],
	"off": [Rect2(528, 134, 120, 232), "lantern_hand"],
	"head": [Rect2(292, 112, 120, 120), "hat_straw"],
	"body": [Rect2(292, 244, 120, 180), "dress"],
	"neck": [Rect2(428, 240, 62, 62), "amulet_clover"],
	"ring2": [Rect2(428, 312, 62, 62), "ring_copper"],
	"ring1": [Rect2(214, 312, 62, 62), "ring_copper"],
	"hands": [Rect2(154, 382, 120, 120), "gloves_garden"],
	"belt": [Rect2(292, 436, 120, 64), "belt_leather"],
	"feet": [Rect2(430, 382, 120, 120), "boots_travel"],
	"pack": [Rect2(56, 520, 120, 112), "pack_sack"],
}

var main: Node2D
var hud: CanvasLayer
var root: Control
var panel: Control
var slot_nodes: Dictionary = {}       # слот -> {frame, icon, base}
var flask_nodes: Array = []
var grid: Control
var cells: Array = []                 # [Control, id]
var stats_l: RichTextLabel
var weight_c: Control
var tip: Control
var tip_box: VBoxContainer
var carry_id: String = ""
var carry_n: int = 0                  # сколько штук в курсоре (пучок)
var carry_from_grid: bool = false     # взято из сетки сумки
var carry_rot: bool = false           # вещь в курсоре повёрнута (R, как в Таркове)
var bg_ctrl: Control
var over_box: Control
var over_row: HFlowContainer
const DB_H = preload("res://herbs_db.gd")
var carry_icon: TextureRect
var set_btns: Array = []
var open: bool = false
var t: float = 0.0
var hover_slot: String = ""
var tip_id: String = ""


func setup(m: Node2D, h: CanvasLayer) -> void:
	main = m
	hud = h
	layer = 22
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.visible = false
	add_child(root)
	# затемнение мира слева, как в PoE
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0.02, 0.02, 0.03, 0.35)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed:
			_drop_carry())
	root.add_child(dim)
	panel = Control.new()
	panel.position = Vector2(1920 - W - 24, PY)
	panel.size = Vector2(W, H)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(panel)
	_tex_rect(panel, "inv_bg", Vector2.ZERO, Vector2(W, H))
	# герб и табличка с названием
	_tex_rect(panel, "inv_crest", Vector2(W / 2.0 - 200, -34), Vector2(400, 100))
	var plq: TextureRect = _tex_rect(panel, "inv_plaque", Vector2(W / 2.0 - 130, 46), Vector2(260, 44))
	var title: Label = _label(plq, "Инвентарь", hud.get("font_title"), 34, Color("2a1c10"))
	title.size = Vector2(260, 44)
	title.position = Vector2(0, -2)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var close_b: TextureButton = TextureButton.new()
	close_b.texture_normal = _tex("inv_close")
	close_b.ignore_texture_size = true
	close_b.stretch_mode = TextureButton.STRETCH_SCALE
	close_b.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	close_b.position = Vector2(W - 54, 54)
	close_b.size = Vector2(32, 32)
	close_b.pressed.connect(close_inv)
	panel.add_child(close_b)
	for key in SLOTS.keys():
		_make_slot(String(key))
	# переключатели наборов рук I / II над каждой рукой
	for side in [0, 1]:
		var x0: float = (56.0 if side == 0 else 528.0) + XO
		for s in [0, 1]:
			var b: Button = Button.new()
			b.text = "I" if s == 0 else "II"
			b.flat = true
			b.focus_mode = Control.FOCUS_NONE
			b.position = Vector2(x0 + s * 34.0, 102)
			b.size = Vector2(30, 28)
			b.add_theme_font_override("font", hud.get("font_bold"))
			b.add_theme_font_size_override("font_size", 18)
			b.pressed.connect(func() -> void: set_weapon_set(s))
			panel.add_child(b)
			set_btns.append([b, s])
	# ячейки зелий на поясе
	for i in range(5):
		var r: Rect2 = Rect2(206 + XO + i * 58, 520, 54, 112)
		var c: Control = _slot_frame(r)
		var key: String = "flask%d" % i
		c.gui_input.connect(_slot_input.bind(key))
		c.mouse_entered.connect(func() -> void: hover_slot = key)
		c.mouse_exited.connect(func() -> void:
			if hover_slot == key:
				hover_slot = ""
			_hide_tip())
		var ic: TextureRect = _icon_rect(c, Vector2(r.size.x - 6, r.size.x - 6))
		ic.position = Vector2(3, (r.size.y - r.size.x) / 2.0 + 3)
		var num: Label = _label(c, ["Z", "", "", "", ""][i], hud.get("font_bold"), 16, Color(TXT, 0.8))
		num.position = Vector2(4, r.size.y - 24)
		flask_nodes.append({"frame": c, "icon": ic, "lock": _lock(c, r.size)})
	# свойства героини (сумма вещей) — справа от зелий
	stats_l = RichTextLabel.new()
	stats_l.bbcode_enabled = true
	stats_l.position = Vector2(504 + XO, 514)
	stats_l.size = Vector2(176, 126)
	stats_l.scroll_active = false
	stats_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stats_l.add_theme_font_override("normal_font", hud.get("font_body"))
	stats_l.add_theme_font_size_override("normal_font_size", 15)
	stats_l.add_theme_color_override("default_color", TXT)
	panel.add_child(stats_l)
	# сетка сумки 12×5
	grid = Control.new()
	grid.position = Vector2((W - CELL * COLS) / 2.0, GRID_Y)
	grid.size = Vector2(CELL * COLS, CELL * ROWS)
	grid.mouse_filter = Control.MOUSE_FILTER_STOP
	grid.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed and (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
			_drop_carry())
	panel.add_child(grid)
	# v26: кнопка «Сортировать»
	var sort_b: Button = Button.new()
	sort_b.text = "Сортировать"
	sort_b.focus_mode = Control.FOCUS_NONE
	sort_b.position = Vector2(W - 170, GRID_Y - 34)
	sort_b.size = Vector2(150, 28)
	sort_b.add_theme_font_override("font", hud.get("font_body"))
	sort_b.add_theme_font_size_override("font_size", 17)
	sort_b.pressed.connect(func() -> void:
		Game.sort_layout()
		Sound.play("ui_click", -6.0))
	panel.add_child(sort_b)
	# не влезло: полоска слева от панели
	over_box = Control.new()
	over_box.position = Vector2(-150, GRID_Y)
	over_box.size = Vector2(140, 280)
	over_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	over_box.visible = false
	panel.add_child(over_box)
	var ob: ColorRect = ColorRect.new()
	ob.color = Color(0.25, 0.04, 0.03, 0.85)
	ob.size = over_box.size
	ob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	over_box.add_child(ob)
	over_row = HFlowContainer.new()
	over_row.position = Vector2(6, 6)
	over_row.size = Vector2(128, 268)
	over_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	over_box.add_child(over_row)
	weight_c = Control.new()
	weight_c.position = Vector2(16, GRID_Y + CELL * ROWS + 14)
	weight_c.size = Vector2(W - 32, 44)
	weight_c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	weight_c.draw.connect(_draw_weight)
	panel.add_child(weight_c)
	# подсказка о вещи (как в PoE: тёмная табличка с золотым заголовком и синими свойствами)
	tip = Control.new()
	tip.visible = false
	tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tip.z_index = 10
	root.add_child(tip)
	var tbg: ColorRect = ColorRect.new()
	tbg.name = "bg"
	tbg.color = Color(0.03, 0.025, 0.02, 0.94)
	tbg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tip.add_child(tbg)
	tip_box = VBoxContainer.new()
	tip_box.position = Vector2(14, 10)
	tip_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tip_box.add_theme_constant_override("separation", 2)
	tip.add_child(tip_box)
	carry_icon = TextureRect.new()
	carry_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	carry_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	carry_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	carry_icon.size = Vector2(56, 56)
	carry_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	carry_icon.visible = false
	carry_icon.z_index = 20
	root.add_child(carry_icon)
	Game.inventory_changed.connect(_refresh)
	Game.equip_changed.connect(_refresh)
	_refresh()


# ------------------------------------------------------------------ сборка

func _tex(name: String) -> Texture2D:
	var p: String = "res://art/%s.png" % name
	return load(p) if ResourceLoader.exists(p) else null


func _tex_rect(parent: Control, name: String, pos: Vector2, size: Vector2) -> TextureRect:
	var tr: TextureRect = TextureRect.new()
	tr.texture = _tex(name)
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.position = pos
	tr.size = size
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(tr)
	return tr


func _label(parent: Node, text: String, font: Font, size: int, col: Color) -> Label:
	var l: Label = Label.new()
	l.text = text
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l


func _icon_rect(parent: Control, size: Vector2) -> TextureRect:
	var tr: TextureRect = TextureRect.new()
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.size = size
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(tr)
	return tr


## Утопленная ячейка с бронзовой рамкой (9-сегментная картинка, пиксель 2×2)
func _slot_frame(r: Rect2) -> Control:
	var c: Control = Control.new()
	c.position = r.position
	c.size = r.size
	c.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_child(c)
	var np: NinePatchRect = NinePatchRect.new()
	np.name = "frame"
	np.texture = _tex("inv_slot")
	np.patch_margin_left = 5
	np.patch_margin_top = 5
	np.patch_margin_right = 5
	np.patch_margin_bottom = 5
	np.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	np.size = r.size / 2.0
	np.scale = Vector2(2, 2)
	np.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(np)
	return c


func _lock(parent: Control, size: Vector2) -> Control:
	var l: ColorRect = ColorRect.new()
	l.color = Color(0, 0, 0, 0.6)
	l.position = Vector2(4, 4)
	l.size = size - Vector2(8, 8)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	var ch: TextureRect = _icon_rect(l, Vector2(28, 28))
	ch.texture = _tex("inv_lock")
	ch.position = (l.size - Vector2(28, 28)) / 2.0
	return l


func _make_slot(key: String) -> void:
	var r: Rect2 = SLOTS[key][0]
	r.position.x += XO
	var c: Control = _slot_frame(r)
	var big: float = 96.0 if r.size.x >= 110.0 and r.size.y >= 110.0 else (48.0 if r.size.x < 70.0 else 64.0)
	var sil: TextureRect = _icon_rect(c, Vector2(big, big))
	sil.position = (r.size - Vector2(big, big)) / 2.0
	sil.texture = IT.icon(String(SLOTS[key][1]))
	sil.modulate = Color(0.32, 0.36, 0.38, 0.35)
	var ic: TextureRect = _icon_rect(c, Vector2(big, big))
	ic.position = sil.position
	c.gui_input.connect(_slot_input.bind(key))
	c.mouse_entered.connect(func() -> void: hover_slot = key)
	c.mouse_exited.connect(func() -> void:
		if hover_slot == key:
			hover_slot = ""
			_hide_tip())
	slot_nodes[key] = {"frame": c, "icon": ic, "sil": sil}


## Настоящий слот Game.equip: руки — с номером набора
func _real(key: String) -> String:
	if key == "main" or key == "off":
		return key + str(Game.weapon_set + 1)
	return key


# ------------------------------------------------------------------ обновление

func _refresh() -> void:
	if grid == null:
		return
	for key in slot_nodes.keys():
		var n: Dictionary = slot_nodes[key]
		var id: String = Game.worn(_real(String(key)))
		(n["icon"] as TextureRect).texture = IT.icon(id) if id != "" else null
		(n["sil"] as TextureRect).visible = id == ""
	var nf: int = Game.flask_slots()
	for i in range(5):
		var fd: Dictionary = flask_nodes[i]
		var fid: String = Game.worn("flask%d" % i)
		(fd["icon"] as TextureRect).texture = RDB.icon(fid) if fid != "" else null
		(fd["lock"] as Control).visible = i >= nf
	for b in set_btns:
		var on: bool = int(b[1]) == Game.weapon_set
		(b[0] as Button).add_theme_color_override("font_color", GOLD_HI if on else Color(TXT, 0.55))
		(b[0] as Button).add_theme_color_override("font_hover_color", GOLD_HI)
	_fill_grid()
	_fill_stats()
	weight_c.queue_redraw()


func pack_rows() -> int:
	var pk: String = Game.worn("pack")
	return int(IT.gear(pk).get("rows", 2)) if pk != "" else 2


func _fill_grid() -> void:
	Game.layout_sync()
	for c in grid.get_children():
		c.queue_free()
	cells.clear()
	var open_rows: int = Game.grid_rows()
	# фон клеток + подсветка места под вещью в курсоре (зелёная — ляжет, красная — нет)
	var bgc: Control = Control.new()
	bgc.size = grid.size
	bgc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grid.add_child(bgc)
	var cell_t: Texture2D = _tex("inv_cell")
	bgc.draw.connect(func() -> void:
		for y in range(ROWS):
			for x in range(COLS):
				bgc.draw_texture_rect(cell_t, Rect2(x * CELL, y * CELL, CELL, CELL), false, Color.WHITE if y < open_rows else Color(0.4, 0.36, 0.36))
		if carry_id != "" and carry_from_grid:
			var tgt: Vector2i = _target_cell()
			var sz: Vector2i = Game.rsize(carry_id, carry_rot)
			var cov: Array = Game.covered(carry_id, tgt.x, tgt.y, -1, carry_rot)
			var ok: bool = not cov.has(-2) and cov.size() <= 1
			var col: Color = Color(0.3, 0.9, 0.3, 0.28) if ok else Color(0.9, 0.25, 0.2, 0.3)
			bgc.draw_rect(Rect2(tgt.x * CELL, tgt.y * CELL, sz.x * CELL, sz.y * CELL), col))
	bg_ctrl = bgc
	for i in range(Game.layout.size()):
		var e: Dictionary = Game.layout[i]
		var id: String = String(e["id"])
		var n: int = int(e["n"])
		var rot: bool = bool(e.get("r", false))
		var sz2: Vector2i = Game.esize(e)
		var c: Control = Control.new()
		c.position = Vector2(int(e["x"]) * CELL, int(e["y"]) * CELL)
		c.size = Vector2(sz2.x * CELL, sz2.y * CELL)
		c.mouse_filter = Control.MOUSE_FILTER_STOP
		grid.add_child(c)
		var shade: ColorRect = ColorRect.new()
		shade.color = Color(0.1, 0.16, 0.3, 0.35) if not IT.is_gear(id) else Color(0.25, 0.2, 0.08, 0.35)
		shade.position = Vector2(2, 2)
		shade.size = c.size - Vector2(4, 4)
		shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		c.add_child(shade)
		# пучок: стебельки веером позади
		if n > 1 and DB_H.DATA.has(id):
			for k in range(mini(n - 1, 3)):
				var back: TextureRect = _icon_rect(c, c.size - Vector2(8, 8))
				back.position = Vector2(4 + (k + 1) * 4 * (1 if k % 2 == 0 else -1), 4 - (k + 1) * 3)
				back.texture = preload("res://item_info.gd").ui_icon(id)
				back.modulate = Color(0.72, 0.72, 0.72)
		var ic: TextureRect = _icon_rect(c, c.size - Vector2(4, 4))
		ic.position = Vector2(2, 2)
		ic.texture = preload("res://item_info.gd").ui_icon(id)
		if rot:
			# повёрнутая вещь: рисуем в исходных размерах и крутим на 90° вокруг центра клетки
			var u: Vector2 = Vector2(sz2.y * CELL - 4, sz2.x * CELL - 4)
			ic.size = u
			ic.pivot_offset = u / 2.0
			ic.rotation = PI / 2.0
			ic.position = c.size / 2.0 - u / 2.0
		if n > 1:
			var l: Label = _label(c, str(n), hud.get("font_bold"), 18, Color("f4ecd8"))
			l.add_theme_color_override("font_outline_color", Color(0, 0, 0))
			l.add_theme_constant_override("outline_size", 5)
			l.position = Vector2(c.size.x - 8 - 9 * str(n).length(), c.size.y - 24)
		c.gui_input.connect(_cell_input.bind(i))
		c.mouse_entered.connect(func() -> void: _show_tip(id))
		c.mouse_exited.connect(_hide_tip)
		cells.append([c, id])
	# что не влезло — красная полоска слева от сумки
	over_box.visible = not Game.overflow.is_empty()
	for ch in over_row.get_children():
		ch.queue_free()
	for oid in Game.overflow.keys():
		var oc: TextureRect = TextureRect.new()
		oc.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		oc.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		oc.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		oc.custom_minimum_size = Vector2(40, 40)
		oc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		oc.texture = IT.icon(String(oid))
		oc.modulate = Color(1.0, 0.75, 0.7)
		over_row.add_child(oc)
		if int(Game.overflow[oid]) > 1:
			var ol: Label = _label(oc, str(int(Game.overflow[oid])), hud.get("font_bold"), 14, Color("f4ecd8"))
			ol.position = Vector2(22, 22)


## Клетка, куда ляжет вещь из курсора (вещь — центром под мышью)
func _target_cell() -> Vector2i:
	var mp: Vector2 = grid.get_local_mouse_position()
	var sz: Vector2i = Game.rsize(carry_id, carry_rot)
	return Vector2i(int(floor(mp.x / CELL - float(sz.x) / 2.0 + 0.5)), int(floor(mp.y / CELL - float(sz.y) / 2.0 + 0.5)))


## Положить вещь из курсора в сетку (или обменять / добавить в пучок)
func _place_carry() -> void:
	if carry_id == "" or not carry_from_grid:
		return
	var tgt: Vector2i = _target_cell()
	var rest: Dictionary = Game.layout_place(carry_id, carry_n, tgt.x, tgt.y, carry_rot)
	if not rest.is_empty() and String(rest["id"]) == carry_id and int(rest["n"]) == carry_n:
		_nope()
		return
	if rest.is_empty():
		carry_id = ""
		carry_n = 0
		carry_rot = false
		carry_from_grid = false
		Game.hold = {}
	else:
		carry_id = String(rest["id"])
		carry_n = int(rest["n"])
		carry_rot = bool(rest.get("r", false))
		Game.hold = {"id": carry_id, "n": carry_n}
	Sound.play("ui_click", -6.0)
	_refresh()


const STAT_NAMES: Dictionary = {
	"cap": "Вес: +%d", "speed": "Скорость: +%d%%", "herb": "Двойная трава: %d%%", "shroom": "Двойной гриб: %d%%",
	"seed": "Семена: %d%%", "sell": "Продажа: +%d%%", "buy": "Скидка: %d%%", "brew": "Два зелья: %d%%",
	"reveal": "Обзор карты: +%d%%",
}


func _fill_stats() -> void:
	var s: String = "[color=#c8a96e]%s[/color]\n" % String(preload("res://scenarios_db.gd").get_s(Game.scenario)["name"])
	for k in ["speed", "herb", "shroom", "seed", "sell", "buy", "brew", "reveal"]:
		var v: float = Game.stat(String(k))
		if absf(v) >= 1.0:
			s += "[color=#8ea8ff]" + (String(STAT_NAMES[k]) % int(round(v))) + "[/color]\n"
	for k2 in ["hunger", "thirst"]:
		var v2: float = Game.stat(String(k2))
		if v2 <= -1.0:
			s += "[color=#8ea8ff]%s медленнее на %d%%[/color]\n" % ["Голод" if k2 == "hunger" else "Жажда", int(-v2)]
	if Game.stat("light") > 0.0:
		s += "[color=#8ea8ff]Свет ночью[/color]\n"
	if Game.buff_t > 0.0:
		s += "[color=#e8c860]Бодрость: %d с[/color]\n" % int(Game.buff_t)
	if Game.pbuff_t > 0.0:
		s += "[color=#e8c860]Зелье: %d с[/color]\n" % int(Game.pbuff_t)
	if Game.god_mode:
		s += "[color=#ffd84a]Режим бога[/color]\n"
	stats_l.text = s


## Полоса веса: золото, на пределе — янтарь, перегруз — красная
func _draw_weight() -> void:
	var w: float = Game.carried()
	var cap: float = Game.capacity()
	var full: float = weight_c.size.x - 250.0
	var x0: float = 40.0
	var over: bool = w > cap and not Game.god_mode
	var shake: float = sin(t * 30.0) * 2.0 if over else 0.0
	var pk: Texture2D = IT.icon(Game.worn("pack")) if Game.worn("pack") != "" else _tex("icon_pack")
	if pk != null:
		weight_c.draw_texture_rect(pk, Rect2(0, 4, 32, 32), false)
	weight_c.draw_rect(Rect2(x0 - 3 + shake, 9, full + 6, 22), Color("1a1410"))
	weight_c.draw_rect(Rect2(x0 + shake, 12, full, 16), Color("2c2620"))
	var f: float = clampf(w / maxf(1.0, cap * 1.5), 0.0, 1.0) * full
	var col: Color = Color("b89048") if w < cap * 0.75 else (Color("d8a030") if w <= cap else Color("c83a2a"))
	weight_c.draw_rect(Rect2(x0 + shake, 12, f, 16), col)
	weight_c.draw_rect(Rect2(x0 + shake, 12, f, 4), col.lightened(0.3))
	var lx: float = x0 + full / 1.5
	weight_c.draw_rect(Rect2(lx - 1 + shake, 6, 3, 28), GOLD_HI)
	var font: Font = hud.get("font_bold")
	weight_c.draw_string(font, Vector2(x0 + full + 14, 28), "%d/%d" % [int(round(w)), int(cap)], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, BAD if over else TXT)
	var coin: Texture2D = _tex("coin")
	var cx: float = weight_c.size.x - 92.0
	if coin != null:
		weight_c.draw_texture_rect(coin, Rect2(cx, 8, 24, 24), false)
	weight_c.draw_string(font, Vector2(cx + 30, 28), str(Game.coins), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, GOLD)


# ------------------------------------------------------------------ подсказка о вещи

func _tip_line(text: String, col: Color, size: int = 17, font_key: String = "font_body") -> void:
	var l: Label = _label(tip_box, text, hud.get(font_key), size, col)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.custom_minimum_size = Vector2(300, 0)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


const SLOT_NAMES: Dictionary = {
	"tool": "Инструмент · в любую руку", "off": "Вторая рука", "head": "Голова", "body": "Одежда", "hands": "Руки",
	"feet": "Ноги", "neck": "Амулет", "ring": "Кольцо", "belt": "Пояс", "pack": "Рюкзак",
}


func _hide_tip() -> void:
	tip.visible = false
	tip_id = ""


func _show_tip(id: String) -> void:
	if id == "" or carry_id != "":
		_hide_tip()
		return
	if tip_id == id:
		return
	tip_id = id
	for c in tip_box.get_children():
		tip_box.remove_child(c)
		c.queue_free()
	var extra: Array = [["Вес: %.1f" % IT.weight_in(id, Game.worn("pack")), "dim"]]
	preload("res://item_info.gd").fill_box(tip_box, id, hud, extra)
	tip_box.reset_size()
	await get_tree().process_frame
	if tip_id != id:
		return
	var bg: ColorRect = tip.get_node("bg")
	bg.size = tip_box.size + Vector2(28, 20)
	tip.visible = true


func _stat_text(k: String, v: float) -> String:
	match k:
		"cap":
			return "+%d к переносимому весу" % int(v)
		"speed":
			return "+%d%% к скорости" % int(v)
		"herb":
			return "%d%% шанс собрать две травы" % int(v)
		"shroom":
			return "%d%% шанс срезать два гриба" % int(v)
		"seed":
			return "%d%% шанс найти семечко" % int(v)
		"sell":
			return "+%d%% к цене продажи" % int(v)
		"brew":
			return "%d%% шанс сварить два зелья" % int(v)
		"hunger":
			return "Голод растёт на %d%% медленнее" % int(-v)
		"thirst":
			return "Жажда растёт на %d%% медленнее" % int(-v)
		"light":
			return "Светит вокруг ночью"
		"shroom_w":
			return "Грибы ничего не весят"
		"herb_w":
			return "Травы весят вдвое меньше"
		"fish_w":
			return "Рыба весит втрое меньше"
		"potion_w":
			return "Зелья ничего не весят"
	return k


# ------------------------------------------------------------------ мышь

func _cell_input(ev: InputEvent, idx: int) -> void:
	if not (ev is InputEventMouseButton) or not (ev as InputEventMouseButton).pressed:
		return
	var mb: InputEventMouseButton = ev
	if idx >= Game.layout.size():
		return
	var e: Dictionary = Game.layout[idx]
	var id: String = String(e["id"])
	# v23: Ctrl/Shift+клик — сразу в открытый сундук
	var cu: Node = get_tree().get_first_node_in_group("chest_ui")
	var quick: bool = (mb.ctrl_pressed or mb.shift_pressed) and mb.button_index == MOUSE_BUTTON_LEFT
	if quick and carry_id == "" and cu != null and bool(cu.get("open")):
		if bool(cu.call("store", id, int(e["n"]))):
			Sound.play("ui_click", -6.0)
		return
	# Shift+ЛКМ без сундука — быстро надеть / съесть / положить в панель 1–9
	if quick and carry_id == "":
		_auto_equip(id)
		return
	if mb.button_index == MOUSE_BUTTON_LEFT:
		if carry_id != "":
			if carry_from_grid:
				_place_carry()
			else:
				_drop_carry()
		elif mb.double_click:
			_auto_equip(id)
		else:
			# взять всю стопку / пучок в курсор
			carry_id = id
			carry_n = int(e["n"])
			carry_rot = bool(e.get("r", false))
			carry_from_grid = true
			Game.layout.remove_at(idx)
			Game.hold = {"id": id, "n": carry_n}
			tip.visible = false
			Sound.play("ui_click", -6.0)
			_refresh()
	elif mb.button_index == MOUSE_BUTTON_RIGHT:
		var v23: Node = get_tree().get_first_node_in_group("v23")
		if carry_id == "" and v23 != null and bool(v23.call("use_item", id)):
			_hide_tip()
			return
		if carry_id == "" and IT.is_food(id):
			_eat(id)     # v17: ПКМ по еде — съесть
		elif carry_id == "" and int(e["n"]) > 1:
			# вытащить из пучка одну штуку
			e["n"] = int(e["n"]) - 1
			carry_id = id
			carry_n = 1
			carry_rot = bool(e.get("r", false))
			carry_from_grid = true
			Game.hold = {"id": id, "n": 1}
			Sound.play("ui_click", -8.0)
			_refresh()
		else:
			_auto_equip(id)


## Правая кнопка: вещь — в свой слот, зелье — на пояс, остальное — в выбранную ячейку панели 1–8
func _eat(id: String) -> void:
	if Game.eat_item(id):
		_hide_tip()
		get_tree().call_group("player", "react", "happy", 1.4)
		Game.fx.emit((main.get("player") as Node2D).global_position + Vector2(0, -50), "heart")


func _auto_equip(id: String) -> void:
	if IT.is_food(id):
		_eat(id)
		return
	var slot: String = IT.slot_for(id, Game.equip, Game.weapon_set)
	if slot != "" and (not slot.begins_with("flask") or int(slot.substr(5)) < Game.flask_slots()):
		if Game.equip_item(id, slot):
			Sound.play("ui_select", -6.0)
			carry_id = ""
			return
	var old: int = Game.hotbar.find(id)
	if old >= 0:
		Game.hotbar[old] = ""
	Game.hotbar[Game.hot_sel] = id
	Sound.play("ui_click", -6.0)
	Game.inventory_changed.emit()


func _slot_input(ev: InputEvent, key: String) -> void:
	if not (ev is InputEventMouseButton) or not (ev as InputEventMouseButton).pressed:
		return
	var mb: InputEventMouseButton = ev
	var real: String = _real(key)
	if real.begins_with("flask") and int(real.substr(5)) >= Game.flask_slots():
		_nope()
		return
	if mb.button_index == MOUSE_BUTTON_RIGHT:
		if Game.worn(real) != "":
			Game.unequip(real)
			Sound.play("ui_click", -6.0)
		return
	if mb.button_index != MOUSE_BUTTON_LEFT:
		return
	if carry_id != "":
		if IT.fits(carry_id, real) and Game.equip_item(carry_id, real):
			carry_id = ""
			Sound.play("ui_select", -6.0)
			_refresh()
		else:
			_nope()
		return
	var cur: String = Game.worn(real)
	if cur != "":
		# сняла вещь — она сразу «в руке» курсора, можно перенести в другой слот
		Game.unequip(real)
		carry_id = cur
		Sound.play("ui_click", -6.0)
		_refresh()


func _drop_carry() -> void:
	if carry_id == "":
		return
	if carry_from_grid and Rect2(Vector2.ZERO, grid.size).has_point(grid.get_local_mouse_position()):
		_place_carry()
		return
	# v23: отпустила за пределами окна — выбросить на землю
	var v23: Node = get_tree().get_first_node_in_group("v23")
	if carry_from_grid and v23 != null and not Rect2(Vector2.ZERO, panel.size).has_point(panel.get_local_mouse_position()):
		Game.hold = {}
		if bool(v23.call("drop_ground", carry_id, carry_n)):
			carry_from_grid = false
			carry_n = 0
			carry_id = ""
			_refresh()
			return
	# отпустила мимо сетки — вещь возвращается на свободное место
	carry_from_grid = false
	carry_n = 0
	carry_rot = false
	Game.hold = {}
	carry_id = ""
	Sound.play("ui_click", -10.0)
	_refresh()


func _nope() -> void:
	Sound.play("ui_click", -2.0, 0.0)
	var tw: Tween = create_tween()
	tw.tween_property(panel, "position:x", panel.position.x + 6, 0.04)
	tw.tween_property(panel, "position:x", panel.position.x - 6, 0.06)
	tw.tween_property(panel, "position:x", 1920 - W - 24, 0.04)


# ------------------------------------------------------------------ открыть / закрыть / клавиши

func open_inv() -> void:
	open = true
	root.visible = true
	Game.ui_open = true
	Sound.play("page", -8.0)
	_refresh()


func close_inv() -> void:
	open = false
	carry_id = ""
	carry_n = 0
	carry_rot = false
	carry_from_grid = false
	Game.hold = {}
	Game.layout_sync()
	tip.visible = false
	root.visible = false
	Game.ui_open = false
	Sound.play("page", -10.0)


func set_weapon_set(s: int) -> void:
	if Game.weapon_set == s:
		return
	Game.weapon_set = s
	Sound.play("ui_select", -8.0)
	Game.equip_changed.emit()
	Game.inventory_changed.emit()


## Z — выпить первое зелье с пояса
func drink_next() -> void:
	for i in range(Game.flask_slots()):
		if Game.drink_flask(i):
			if Game.last_drink != "mermaid_tail" and preload("res://item_info.gd").potion_fx(Game.last_drink).is_empty():
				Game.toast.emit("Бодрость!", load("res://art/fx_heart.png"))
			return


## Пока окно открыто: R — повернуть вещь в курсоре; 1–9 — положить вещь под курсором мыши (или в руке-курсоре) в ячейку панели
func _input(event: InputEvent) -> void:
	if not open or not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var k: Key = (event as InputEventKey).physical_keycode
	if k == KEY_R and carry_id != "" and carry_from_grid:
		if IT.size(carry_id).x != IT.size(carry_id).y:
			carry_rot = not carry_rot
			Sound.play("ui_click", -8.0)
			if bg_ctrl != null and is_instance_valid(bg_ctrl):
				bg_ctrl.queue_redraw()
		get_viewport().set_input_as_handled()
	elif k >= KEY_1 and k <= KEY_9:
		var hid: String = carry_id if carry_id != "" else tip_id
		if hid != "" and Game.get_count(hid) > 0:
			var old: int = Game.hotbar.find(hid)
			if old >= 0:
				Game.hotbar[old] = ""
			Game.hotbar[int(k - KEY_1)] = hid
			Game.hot_sel = int(k - KEY_1)
			Sound.play("ui_click", -6.0)
			Game.inventory_changed.emit()
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var k: Key = (event as InputEventKey).physical_keycode
	if KB.is_key("inventory", k):
		if open:
			close_inv()
		elif not Game.ui_open and not Game.busy:
			open_inv()
		get_viewport().set_input_as_handled()
	elif open and k == KEY_ESCAPE:
		close_inv()
		get_viewport().set_input_as_handled()
	elif KB.is_key("swap", k) and (open or not Game.ui_open):
		set_weapon_set(1 - Game.weapon_set)
		get_viewport().set_input_as_handled()
	elif KB.is_key("potion", k) and not Game.ui_open and not Game.busy:
		drink_next()
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if not open:
		return
	t += delta
	var mp: Vector2 = root.get_local_mouse_position()
	carry_icon.visible = carry_id != ""
	if carry_id != "":
		carry_icon.texture = preload("res://item_info.gd").ui_icon(carry_id)
		var csz: Vector2i = IT.size(carry_id)    # исходный размер; поворот — вращением значка
		carry_icon.size = Vector2(csz.x * CELL - 4, csz.y * CELL - 4)
		carry_icon.pivot_offset = carry_icon.size / 2.0
		carry_icon.rotation = PI / 2.0 if carry_rot else 0.0
		carry_icon.position = mp - carry_icon.size / 2.0
		if bg_ctrl != null and is_instance_valid(bg_ctrl):
			bg_ctrl.queue_redraw()
	# подсветка слота под курсором: золото; если вещь не подходит — красным
	for key in slot_nodes.keys():
		var fr: NinePatchRect = (slot_nodes[key]["frame"] as Control).get_node("frame")
		fr.modulate = _hl(String(key))
	for i in range(5):
		var fr2: NinePatchRect = (flask_nodes[i]["frame"] as Control).get_node("frame")
		fr2.modulate = _hl("flask%d" % i)
	if tip.visible:
		var tp: Vector2 = mp + Vector2(24, 18)
		var bs: Vector2 = (tip.get_node("bg") as ColorRect).size
		tp.x = minf(tp.x, 1920.0 - bs.x - 8.0)
		if tp.x + bs.x > panel.position.x and mp.x > panel.position.x:
			tp.x = mp.x - bs.x - 24.0
		tp.y = clampf(tp.y, 8.0, 1080.0 - bs.y - 8.0)
		tip.position = tp
	if hover_slot != "" and carry_id == "":
		var hid: String = Game.worn(_real(hover_slot))
		if hid != "":
			_show_tip(hid)
		elif tip_id != "":
			_hide_tip()
	if Game.overloaded() or Game.buff_t > 0.0:
		weight_c.queue_redraw()


func _hl(key: String) -> Color:
	var real: String = _real(key)
	if carry_id != "":
		if IT.fits(carry_id, real) and not (real.begins_with("flask") and int(real.substr(5)) >= Game.flask_slots()):
			return Color(0.75, 1.25, 0.75) if hover_slot == key else Color(1.05, 1.15, 1.0)
		return Color(1.2, 0.6, 0.55) if hover_slot == key else Color(0.7, 0.7, 0.7)
	return Color(1.5, 1.3, 0.9) if hover_slot == key else Color.WHITE

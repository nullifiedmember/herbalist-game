extends Node
## Хозяйство травницы: сумка (I) с весом и перегрузом, панель быстрого доступа (1-8),
## предмет прямо в руках, рубка деревьев топором (брёвна и саженцы выпадают и летят в руки),
## саженцы своей породы, свой участок с колышками по границе и расширением у межевого столба,
## постройки с верстака (стол изучения, загон, сундук, грядки, котёл, туалет, колодец, фонари, забор).
## Всё показывается картинками: значки, полоска веса, цены брёвнами и монетами — без надписей-подсказок.
## Действие предметом в руках — левая кнопка мыши или F.

const IT = preload("res://items_db.gd")
const WD = preload("res://world_data.gd")
const BASE_PLOT: Rect2 = Rect2(560, 300, 800, 600)   # участок у дома в самом начале
const GROW: float = 240.0                          # на сколько растёт участок за одно расширение
const MAX_LEVEL: int = 6
const PLOT_COST: Array = [40, 90, 160, 260, 400, 600]
const UI_INK: Color = Color("3a2718")

var main: Node2D
var hud: CanvasLayer
var world: Node2D
var ui: CanvasLayer
var inv_panel: Control
var inv_grid: GridContainer
var weight_bar: Control
var hot_box: HBoxContainer
var held_spr: Sprite2D
var heavy_spr: Sprite2D
var light_spr: Sprite2D
var border: Line2D
var plot_fill: Polygon2D
var stakes: Array = []
var ghost: Sprite2D
var menu_panel: Control
var menu_list: Control
var menu_np: NinePatchRect
var menu_opts: Array = []
var menu_target: Node2D = null
var menu_tabs: HBoxContainer
var menu_scroll: ScrollContainer
var menu_kind: String = ""
var menu_tab: String = "home"
const MT = preload("res://mats_db.gd")
## Значки вкладок верстака
const TAB_ICONS: Dictionary = {"furn": "fu_cozy_bed", "wpn": "gear_wpn_sword_iron", "kingdom": "icon_crown23", "home": "workbench", "work": "st20_anvil", "trap": "trap20_small", "bird": "b20_birdhouse", "deco": "flower_bed", "wall": "w20_brick_wall"}
var chop_hits: Dictionary = {}       # спрайт дерева -> сколько ударов
var stumps: Array = []               # v17: пеньки [спрайт, когда срублено (минуты с начала игры)] — тают за STUMP_DAYS дней
const STUMP_DAYS: float = 5.0
var _stump_t: float = 0.0
var placed: Array = []               # [вид, точка]
var placed_rt: Array = []            # параллельно placed: {"nodes", "glows", "rect"} — что создала постройка (для сноса)
var pens: Array = []                 # [центр, сколько зверей]
var cool: float = 0.0
var swing_t: float = 0.0
var t: float = 0.0


func setup(m: Node2D, h: CanvasLayer, w: Node2D) -> void:
	main = m
	hud = h
	world = w
	_build_ui()
	held_spr = Sprite2D.new()
	held_spr.z_index = 1
	held_spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	(main.get("player") as Node2D).add_child(held_spr)
	heavy_spr = Sprite2D.new()
	heavy_spr.texture = load("res://art/icon_pack.png")
	heavy_spr.scale = Vector2(0.5, 0.5)
	heavy_spr.modulate = Color(1.0, 0.55, 0.5)
	heavy_spr.z_index = 30
	heavy_spr.visible = false
	(main.get("player") as Node2D).add_child(heavy_spr)
	# свет ручного фонаря / лунного амулета вокруг героини ночью
	light_spr = Sprite2D.new()
	light_spr.texture = load("res://art/fx_glow.png")
	var lm: CanvasItemMaterial = CanvasItemMaterial.new()
	lm.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	light_spr.material = lm
	light_spr.position = Vector2(0, -18)
	light_spr.scale = Vector2(2.6, 2.6)
	light_spr.z_index = 60
	light_spr.visible = false
	(main.get("player") as Node2D).add_child(light_spr)
	# участок: светлая заливка и верёвка — только когда в руках постройка или саженец
	plot_fill = Polygon2D.new()
	plot_fill.color = Color(1.0, 0.95, 0.7, 0.0)
	plot_fill.z_index = -9
	main.add_child(plot_fill)
	border = Line2D.new()
	border.width = 1.0
	border.default_color = Color("d8c08a")
	border.default_color.a = 0.0
	border.z_index = -8
	main.add_child(border)
	ghost = Sprite2D.new()
	ghost.centered = false
	ghost.z_index = 40
	ghost.visible = false
	main.add_child(ghost)
	_redraw_border()
	# межевой столб у дома: расширить участок
	var post: Node2D = Node2D.new()
	post.set_script(load("res://placed.gd"))
	post.set("kind", "post")
	post.set("home", self)
	post.position = Vector2(1090, 420) + Game.home_pos - Vector2(960, 358)
	main.get("objects").add_child(post)
	main.call("spr", "boundary_post", post.position, 0.0, false, null, true)
	_block_circle(post.position + Vector2(0, -3), 6.0)
	Game.inventory_changed.connect(_refresh_soon)
	Game.inventory_changed.connect(func() -> void: _pool_frame = -1)
	_refresh()
	# v28: обучение-задание от гида (tutq28.gd)
	var tq: Node = Node.new()
	tq.set_script(load("res://tutq28.gd"))
	add_child(tq)
	tq.call("setup", m, self, ui, h)
	# проверка картинкой: --inv (сумка с перегрузом), --bench (меню верстака)
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.has("--inv") or args.has("--bench"):
		get_tree().create_timer(0.6).timeout.connect(func() -> void:
			if args.has("--inv17"):
				Game.equip["pack"] = "pack_herb"
				var FD17h = preload("res://food_db.gd")
				var ci: int = 0
				for fk in FD17h.ORDER:
					if ci % 3 == 0 and ci < 90:
						Game.add_item("food_" + String(fk), 1 + ci % 4)
					ci += 1
				for lk in preload("res://tree_db.gd").TREES.keys():
					Game.add_item("leaf_" + String(lk), 3 + ci % 5)
				for it3 in [["lavender", 7], ["mint", 3], ["bug_ladybug", 2], ["bug_firefly", 3], ["porcini", 4], ["calm_tea", 1], ["net", 1], ["log", 2]]:
					Game.add_item(String(it3[0]), int(it3[1]))
			elif args.has("--inv16"):
				Game.equip["pack"] = "pack_herb"
				for it2 in [["lavender", 7], ["mint", 1], ["chamomile", 3], ["clover", 2], ["glowmoss", 1], ["bug_ladybug", 1], ["bug_butterfly_blue", 1],
						["porcini", 4], ["calm_tea", 1], ["fire_brew", 1], ["water_cold", 2], ["bottle", 3], ["net", 1], ["fish_perch" if preload("res://fish_db.gd").ORDER.has("fish_perch") else String(preload("res://fish_db.gd").ORDER[0]), 1], ["log", 1]]:
					Game.add_item(String(it2[0]), int(it2[1]))
			else:
				for it in ["log", "sapling:tree_blossom", "sapling:pine_a", "sapling:tree_birch", "kit:research", "kit:pen"]:
					Game.add_item(it, 14 if it == "log" else 2)
			Game.coins = 120
			if args.has("--inv"):
				var iu: Node = get_tree().get_first_node_in_group("inventory_ui")
				if iu != null:
					iu.call("open_inv")
			else:
				open_menu("workbench", post))


## Преграда: во дворе — списки main, в большом мире — сетка мира (дом может стоять в любом биоме)
func _block_circle(p: Vector2, r: float) -> void:
	if Rect2(0, 0, 1920, 1280).has_point(p):
		(main.get("block_circles") as Array).append(Vector3(p.x, p.y, r))
	else:
		world.call("add_block", p, r)


func _block_rect(r: Rect2) -> void:
	if Rect2(0, 0, 1920, 1280).has_point(r.get_center()):
		(main.get("block_rects") as Array).append(r)
	else:
		world.call("add_block_rect", r)


func plot_rect() -> Rect2:
	var r: Rect2 = BASE_PLOT.grow(GROW * Game.plot_level)
	r.position += Game.home_pos - Vector2(960, 358)   # участок — у дома, где бы он ни стоял
	return r


## Граница участка: колышки с флажками по периметру, в углах — парами
func _redraw_border() -> void:
	var r: Rect2 = plot_rect()
	var corners: Array = [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]
	border.points = PackedVector2Array(corners + [r.position])
	plot_fill.polygon = PackedVector2Array(corners)
	for s in stakes:
		if is_instance_valid(s):
			(s as Node).queue_free()
	stakes.clear()
	# v26: колышки по границе участка убраны — границы видно только линией при стройке


# ------------------------------------------------------------------ интерфейс

func _build_ui() -> void:
	ui = CanvasLayer.new()
	ui.layer = 18
	add_child(ui)
	# панель быстрого доступа — внизу слева
	var hb_bg: Control = Control.new()
	hb_bg.position = Vector2(24, 990)
	hb_bg.size = Vector2(9 * 70 + 20, 76)
	hb_bg.mouse_filter = Control.MOUSE_FILTER_STOP     # клики по панели не уходят в мир
	ui.add_child(hb_bg)
	hud.call("panel", hb_bg, Vector2.ZERO, Vector2(9 * 70 + 20, 76))
	hot_box = HBoxContainer.new()
	hot_box.position = Vector2(10, 6)
	hot_box.add_theme_constant_override("separation", 6)
	hb_bg.add_child(hot_box)
	# сумка
	inv_panel = Control.new()
	inv_panel.position = Vector2(540, 170)
	inv_panel.visible = false
	inv_panel.size = Vector2(840, 660)
	inv_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	ui.add_child(inv_panel)
	hud.call("panel", inv_panel, Vector2.ZERO, Vector2(840, 660))
	var pack: TextureRect = _icon(load("res://art/icon_pack.png"), Vector2(72, 72))
	pack.position = Vector2(30, 22)
	inv_panel.add_child(pack)
	weight_bar = Control.new()
	weight_bar.position = Vector2(116, 40)
	weight_bar.size = Vector2(440, 40)
	weight_bar.draw.connect(_draw_weight)
	inv_panel.add_child(weight_bar)
	inv_grid = GridContainer.new()
	inv_grid.columns = 8
	inv_grid.position = Vector2(36, 128)
	inv_grid.add_theme_constant_override("h_separation", 10)
	inv_grid.add_theme_constant_override("v_separation", 10)
	inv_panel.add_child(inv_grid)
	# собрать верстак прямо из сумки: картинка верстака и цена брёвнами
	var craft: Control = _card(load("res://art/workbench.png"), [[load("res://art/icon_log.png"), 6]], IT.name("kit:workbench"), func() -> void:
		if Game.take_item("log", 6):
			Game.add_item("kit:workbench")
			Sound.play("anvil", -10.0)
		else:
			_nope())
	craft.position = Vector2(640, 18)
	craft.scale = Vector2(0.62, 0.62)
	inv_panel.add_child(craft)
	# меню построек
	# v20: меню построек и мастерских — вкладки сверху, карточки в прокрутке (их стало много)
	menu_panel = Control.new()
	menu_panel.position = Vector2(220, 60)
	menu_panel.visible = false
	ui.add_child(menu_panel)
	menu_np = hud.call("panel", menu_panel, Vector2.ZERO, Vector2(1480, 960))
	menu_tabs = HBoxContainer.new()
	menu_tabs.position = Vector2(40, 26)
	menu_tabs.add_theme_constant_override("separation", 10)
	menu_panel.add_child(menu_tabs)
	menu_scroll = ScrollContainer.new()
	menu_scroll.position = Vector2(30, 120)
	menu_scroll.size = Vector2(1420, 810)
	menu_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	menu_panel.add_child(menu_scroll)
	menu_list = GridContainer.new()
	(menu_list as GridContainer).columns = 8
	menu_list.add_theme_constant_override("h_separation", 12)
	menu_list.add_theme_constant_override("v_separation", 12)
	menu_scroll.add_child(menu_list)


func _icon(tex: Texture2D, size: Vector2) -> TextureRect:
	var tr: TextureRect = TextureRect.new()
	tr.texture = tex
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.size = size
	tr.custom_minimum_size = size
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return tr


## v31: число из пиксельных цифр ui31_dg_* (контуры соседних цифр сливаются в один)
func _pix_count(n: int, k: float) -> Control:
	var s: String = str(n)
	var root: Control = Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in range(s.length()):
		var tr: TextureRect = TextureRect.new()
		tr.texture = load("res://art/ui31_dg_%s.png" % s[i])
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.size = Vector2(6, 8) * k
		tr.position = Vector2(i * 5, 0) * k
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(tr)
	root.size = Vector2(s.length() * 5 + 1, 8) * k
	return root


## v31: бирка с номером ячейки (выбранная — медовая)
func _hot_tag(i: int, sel: bool) -> TextureRect:
	var tr: TextureRect = TextureRect.new()
	tr.texture = load("res://art/ui31_tag_%d%s.png" % [i, "_sel" if sel else ""])
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.size = Vector2(8, 10) * 2.0
	tr.position = Vector2(-2, -2)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return tr


func _num(text: String, size: int) -> Label:
	var l: Label = Label.new()
	l.text = text
	l.add_theme_font_override("font", hud.get("font_title"))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", Color("fff4dc"))
	l.add_theme_color_override("font_outline_color", UI_INK)
	l.add_theme_constant_override("outline_size", 6)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## Пиксельная ячейка: деревянная рамка (выбранная — золотая)
func _frame(selected: bool, size: float) -> NinePatchRect:
	var np: NinePatchRect = NinePatchRect.new()
	np.texture = load("res://art/ui_slot_sel.png" if selected else "res://art/ui_slot.png")
	np.patch_margin_left = 5
	np.patch_margin_top = 5
	np.patch_margin_right = 5
	np.patch_margin_bottom = 5
	np.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	np.size = Vector2(size, size) / 3.0
	np.scale = Vector2(3, 3)
	np.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return np


func _slot(id: String, count: int, selected: bool, size: float) -> Control:
	var c: Control = Control.new()
	c.custom_minimum_size = Vector2(size, size)
	c.add_child(_frame(selected, size))
	if id != "":
		var tr: TextureRect = _icon(IT.icon(id), Vector2(size - 20, size - 20))
		tr.position = Vector2(10, 10)
		c.add_child(tr)
		if count > 1:
			# v31: пиксельные цифры счётчика в правом нижнем углу (k — размер пикселя)
			var k: float = 3.0 if size > 70.0 else 2.0
			var pn: Control = _pix_count(count, k)
			pn.position = Vector2(size - 5.0 - pn.size.x, size - 5.0 - pn.size.y)
			c.add_child(pn)
		c.tooltip_text = IT.name(id)
	return c


## Карточка постройки: большая картинка и цена значками (бревно ×N, монета ×N)
func _card(tex: Texture2D, costs: Array, tip: String, cb: Callable) -> Control:
	var c: Button = Button.new()
	c.flat = true
	c.custom_minimum_size = Vector2(160, 190)
	c.tooltip_text = tip
	c.focus_mode = Control.FOCUS_NONE
	var fr: NinePatchRect = _frame(false, 160)
	fr.size = Vector2(160, 190) / 3.0
	c.add_child(fr)
	var many: bool = costs.size() > 2
	var ic: TextureRect = _icon(tex, Vector2(136, 104 if many else 120))
	ic.position = Vector2(12, 8)
	c.add_child(ic)
	# v20: цена — значками материалов; несколько — в два ряда, мельче; чего не хватает — красным
	var row: HFlowContainer = HFlowContainer.new()
	row.position = Vector2(10, 114 if many else 138)
	row.size = Vector2(144, 70)
	row.add_theme_constant_override("h_separation", 2)
	row.add_theme_constant_override("v_separation", 0)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for cost in costs:
		if int(cost[1]) <= 0:
			continue
		var box: HBoxContainer = HBoxContainer.new()
		box.add_theme_constant_override("separation", 1)
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(_icon(cost[0], Vector2(30, 30) if many else Vector2(36, 36)))
		var lb: Label = _num(str(int(cost[1])), 20 if many else 26)
		if cost.size() > 2 and not bool(cost[2]):
			lb.add_theme_color_override("font_color", Color("ff8a7a"))
		box.add_child(lb)
		row.add_child(box)
	c.add_child(row)
	c.pressed.connect(cb)
	c.mouse_entered.connect(func() -> void: fr.texture = load("res://art/ui_slot_sel.png"))
	c.mouse_exited.connect(func() -> void: fr.texture = load("res://art/ui_slot.png"))
	return c


## Полоска веса: заполняется по мере груза, за чертой — красная и дрожит
func _draw_weight() -> void:
	var w: float = Game.carried()
	var cap: float = Game.capacity()
	var full: float = 420.0
	var x0: float = 8.0
	var over: bool = w > cap
	var shake: float = sin(t * 30.0) * 2.0 if over else 0.0
	weight_bar.draw_rect(Rect2(x0 - 4 + shake, 4, full + 8, 32), UI_INK)
	weight_bar.draw_rect(Rect2(x0 + shake, 8, full, 24), Color("d8c8a0"))
	var f: float = clampf(w / (cap * 1.5), 0.0, 1.0) * full
	var col: Color = Color("6aa848") if w < cap * 0.75 else (Color("e8b030") if w <= cap else Color("d83a2a"))
	weight_bar.draw_rect(Rect2(x0 + shake, 8, f, 24), col)
	weight_bar.draw_rect(Rect2(x0 + shake, 8, f, 6), col.lightened(0.3))
	# черта предела
	var lx: float = x0 + full / 1.5
	weight_bar.draw_rect(Rect2(lx - 2 + shake, 0, 4, 40), UI_INK)
	for k in range(1, 12):
		var tx: float = x0 + full * float(k) / 12.0
		weight_bar.draw_rect(Rect2(tx + shake, 26, 2, 6), Color(0, 0, 0, 0.25))


var _refresh_pending: bool = false


## v29: перерисовка панели быстрого доступа один раз за кадр
func _refresh_soon() -> void:
	if _refresh_pending:
		return
	_refresh_pending = true
	_refresh_now.call_deferred()


func _refresh_now() -> void:
	_refresh_pending = false
	_refresh()


func _refresh() -> void:
	if hot_box == null:
		return
	for ch in hot_box.get_children():
		ch.queue_free()
	while Game.hotbar.size() < 9:
		Game.hotbar.append("")
	for i in range(9):
		var id: String = String(Game.hotbar[i])
		if id != "" and Game.get_count(id) <= 0:
			id = ""
		var s: Control = _slot(id, Game.get_count(id) if id != "" else 0, i == Game.hot_sel, 64.0)
		s.add_child(_hot_tag(i + 1, i == Game.hot_sel))
		s.mouse_filter = Control.MOUSE_FILTER_STOP
		s.gui_input.connect(func(ev: InputEvent) -> void:
			if ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed and (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
				Game.hot_sel = i
				Sound.play("ui_click", -10.0)
				_refresh())
		hot_box.add_child(s)
	weight_bar.queue_redraw()
	if inv_panel.visible:
		_fill_inventory()
	_update_held()


func _fill_inventory() -> void:
	for ch in inv_grid.get_children():
		ch.queue_free()
	var n_slots: int = 0
	for id in Game.inventory.keys():
		var n: int = int(Game.inventory[id])
		if n <= 0:
			continue
		var s: Control = _slot(String(id), n, Game.held() == String(id), 86.0)
		s.mouse_filter = Control.MOUSE_FILTER_STOP
		s.gui_input.connect(func(ev: InputEvent) -> void:
			if ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed and (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
				var old: int = Game.hotbar.find(String(id))
				if old >= 0:
					Game.hotbar[old] = ""
				Game.hotbar[Game.hot_sel] = String(id)
				Sound.play("ui_click", -6.0)
				_refresh())
		inv_grid.add_child(s)
		n_slots += 1
	# пустые ячейки до конца ряда — сумка выглядит как сумка
	while n_slots < 40:
		inv_grid.add_child(_slot("", 0, false, 86.0))
		n_slots += 1


## Что в руках: из панели быстрого доступа, а если там пусто — инструмент основной руки (Tab, набор I/II)
func in_hand() -> String:
	var id: String = Game.held()
	if id == "":
		id = Game.worn(Game.hand_slot(false))
	return id


func _update_held() -> void:
	var id: String = in_hand()
	if id == "" or bool(main.get("inside")):
		held_spr.visible = false
		return
	held_spr.texture = IT.icon(id)
	var big: float = 24.0 / maxf(24.0, float(maxi(held_spr.texture.get_width(), held_spr.texture.get_height())))
	held_spr.scale = Vector2.ONE * 0.62 * big
	held_spr.visible = true


# ------------------------------------------------------------------ ввод

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var k: Key = (event as InputEventKey).physical_keycode
		if menu_panel.visible:
			if k == KEY_ESCAPE or KB.is_key("interact", k) or (menu_kind == "handcraft" and KB.is_key("craft", k)):
				_close_menu()
			elif k >= KEY_1 and k <= KEY_9:
				_menu_choose(int(k - KEY_1))
			get_viewport().set_input_as_handled()
			return
		if Game.ui_open:
			return
		if KB.is_key("craft", k) and not Game.busy:
			open_menu("handcraft", null)   # окно крафта: что можно сделать руками, без верстака
			get_viewport().set_input_as_handled()
			return
		if k >= KEY_1 and k <= KEY_9:
			Game.hot_sel = int(k - KEY_1)
			Sound.play("ui_click", -10.0)
			_refresh()
			get_viewport().set_input_as_handled()
		elif KB.is_key("eat", k):
			_use(false)
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and (event as InputEventMouseButton).pressed and not Game.ui_open:
		var mb: InputEventMouseButton = event
		if mb.button_index == MOUSE_BUTTON_LEFT and KB.down("demolish") and not bool(main.get("inside")):
			_demolish_click()
		elif mb.button_index == MOUSE_BUTTON_LEFT:
			_use(true)
		elif mb.button_index == MOUSE_BUTTON_RIGHT and ghost.visible:
			Game.hot_sel = Game.hotbar.find("") if Game.hotbar.find("") >= 0 else Game.hot_sel
			_refresh()
		elif mb.button_index == MOUSE_BUTTON_RIGHT:
			try_tree(true)


func _process(delta: float) -> void:
	t += delta
	_update_stumps(delta)
	cool = maxf(0.0, cool - delta)
	var pl: Node2D = main.get("player") as Node2D
	if pl == null:
		return
	# предмет в руке: у правой руки, сзади — за спиной; топор при ударе замахивается
	var f: int = int(pl.get("facing"))
	var hp: Vector2 = [Vector2(9, -19), Vector2(-9, -19), Vector2(-10, -18), Vector2(10, -18), Vector2(-4, -18), Vector2(-9, -19), Vector2(10, -18), Vector2(9, -19)][f]
	var flip: bool = f in [2, 4, 5]
	swing_t = maxf(0.0, swing_t - delta)
	var sw: float = 0.0
	if swing_t > 0.0:
		var k: float = 1.0 - swing_t / 0.32
		sw = (-1.3 + k * 2.4) if k < 0.6 else (1.1 - (k - 0.6) * 2.5)
	held_spr.position = hp + Vector2(0, -2.0 * sin(sw))
	held_spr.rotation = sw * (-1.0 if flip else 1.0)
	held_spr.z_index = -1 if f in [1, 5, 7] else 1
	held_spr.flip_h = flip
	_update_held()
	# перегруз: красный рюкзак над головой покачивается
	var lit: float = Game.night_factor() if (Game.stat("light") > 0.0 and not bool(main.get("inside"))) else 0.0
	light_spr.visible = lit > 0.01
	light_spr.modulate = Color(1.0, 0.78, 0.45, 0.55 * lit + sin(t * 9.0) * 0.02 * lit)
	var heavy: bool = Game.overloaded()
	heavy_spr.visible = heavy and not bool(main.get("inside"))
	heavy_spr.position = Vector2(0, -64 + sin(t * 4.0) * 1.5)
	if inv_panel.visible and heavy:
		weight_bar.queue_redraw()
	var id: String = Game.held()
	var placing: bool = id.begins_with("kit:") and not Game.ui_open and not bool(main.get("inside"))
	var planting: bool = id.begins_with("sapling:") and not Game.ui_open
	var show: float = 1.0 if (placing or planting) else 0.0
	plot_fill.color.a = move_toward(plot_fill.color.a, 0.08 * show, delta)
	border.default_color.a = move_toward(border.default_color.a, 0.8 * show, delta * 3.0)
	ghost.visible = placing
	if placing:
		var kind: String = id.substr(4)
		var p: Vector2 = _place_point(true)
		var tex: String = String(IT.BUILD[kind][1])
		ghost.texture = load("res://art/%s.png" % (tex if tex != "" else "sapling_0"))
		ghost.scale = Vector2.ONE * float(MT.SHRINK.get(tex, 1.0))
		ghost.offset = Vector2(-floorf(ghost.texture.get_width() / 2.0), -float(ghost.texture.get_height()))
		ghost.position = p
		ghost.modulate = Color(0.7, 1.0, 0.7, 0.65 + sin(t * 5.0) * 0.1) if _can_place(kind, p) == "" else Color(1.0, 0.4, 0.4, 0.55)
	# T зажата: постройка под курсором краснеет — клик уберёт её
	if not placing and not Game.ui_open and not bool(main.get("inside")) and KB.down("demolish"):
		var di: int = placed_at((main as Node2D).get_global_mouse_position())
		if di >= 0 and (placed[di][1] as Vector2).distance_to(pl.global_position) <= DEMOLISH_REACH:
			var dk: String = String(placed[di][0])
			var dtex: String = String(IT.BUILD[dk][1])
			if dtex != "" and ResourceLoader.exists("res://art/%s.png" % dtex):
				ghost.texture = load("res://art/%s.png" % dtex)
				ghost.scale = Vector2.ONE * float(MT.SHRINK.get(dtex, 1.0))
				ghost.offset = Vector2(-floorf(ghost.texture.get_width() / 2.0), -float(ghost.texture.get_height())) if not (dk in MT.FLAT) else Vector2(-floorf(ghost.texture.get_width() / 2.0), -floorf(ghost.texture.get_height() / 2.0))
				ghost.position = placed[di][1]
				ghost.modulate = Color(1.0, 0.3, 0.3, 0.55 + sin(t * 8.0) * 0.15)
				ghost.visible = true
	_follow_animals(delta)
	# топор в руке: дерево под курсором подсвечивается (если до него можно дотянуться)
	var want_hl: Sprite2D = null
	if id == "axe" and not Game.ui_open and not bool(main.get("inside")):
		var tt: Sprite2D = tree_at((main as Node2D).get_global_mouse_position())
		if tt != null and tt.global_position.distance_to(pl.global_position) <= CHOP_REACH:
			want_hl = tt
	if want_hl != hl_tree:
		if hl_tree != null and is_instance_valid(hl_tree):
			hl_tree.self_modulate = Color.WHITE
		hl_tree = want_hl
	if hl_tree != null and is_instance_valid(hl_tree):
		hl_tree.self_modulate = Color(1.12, 1.12, 1.0).lerp(Color(1.25, 1.2, 1.0), 0.5 + 0.5 * sin(t * 6.0))


func _place_point(mouse: bool) -> Vector2:
	var pl: Node2D = main.get("player") as Node2D
	if mouse and DisplayServer.get_name() != "headless":
		var mp: Vector2 = (main as Node2D).get_global_mouse_position()
		if mp.distance_to(pl.global_position) < 220.0:
			return (mp / 4.0).round() * 4.0
	var fd: Vector2 = pl.get("FACE_DIRS")[int(pl.get("facing"))]
	return ((pl.global_position + fd * 40.0) / 4.0).round() * 4.0


## Нельзя: героиня дуется, глухой звук — без надписей
func _demolish_click() -> void:
	if cool > 0.0 or Game.busy:
		return
	var pl: Node2D = main.get("player") as Node2D
	var i: int = placed_at((main as Node2D).get_global_mouse_position())
	if i < 0 or (placed[i][1] as Vector2).distance_to(pl.global_position) > DEMOLISH_REACH:
		_nope()
		return
	if demolish(i):
		cool = 0.3
	else:
		_nope()


func _nope() -> void:
	var pl: Node2D = main.get("player") as Node2D
	pl.call("react", "pout", 0.8)
	Sound.play("ui_click", -4.0, 0.0)
	cool = 0.5


# ------------------------------------------------------------------ действие предметом

func _use(mouse: bool) -> void:
	if cool > 0.0 or Game.busy or bool(main.get("inside")):
		return
	var id: String = in_hand()
	if id == "axe":
		# рубить — только кликнув по самому дереву
		if mouse:
			chop_at((main as Node2D).get_global_mouse_position())
	elif id == "pickaxe":
		# кирка: бить камень или руду, на который кликнули (рядом с героиней)
		if mouse:
			var rk: Node = get_tree().get_first_node_in_group("rocks18")
			if rk != null:
				rk.call("mine_at", (main as Node2D).get_global_mouse_position())
	elif IT.is_food(id):
		# еда в руках: съесть (ЛКМ или F)
		if Game.eat_item(id):
			get_tree().call_group("player", "react", "happy", 1.4)
			Game.fx.emit((main.get("player") as Node2D).global_position + Vector2(0, -50), "heart")
			cool = 0.3
	elif id.begins_with("sapling:"):
		_plant(id, _place_point(mouse))
	elif id.begins_with("kit:"):
		var kind: String = id.substr(4)
		var p: Vector2 = _place_point(mouse)
		if _can_place(kind, p) != "":
			_nope()
			return
		if Game.take_item(id):
			build(kind, p)
			Sound.play("chop", -6.0, 0.1, p)
			Game.fx.emit(p, "dust")
			cool = 0.3
	else:
		try_tree(mouse)     # пустые руки / обычная вещь: потянуться к ветке


## Дерево рядом: окно веточек (E, F или ПКМ по дереву). Возвращает true, если окно открылось.
func try_tree(mouse: bool) -> bool:
	if cool > 0.0 or Game.busy or Game.ui_open or bool(main.get("inside")):
		return false
	var tu: Node = get_tree().get_first_node_in_group("tree_ui")
	var pl: Node2D = main.get("player") as Node2D
	if tu == null or pl == null:
		return false
	var tr: Sprite2D = null
	if mouse:
		tr = tree_at((main as Node2D).get_global_mouse_position())
		if tr != null and tr.global_position.distance_to(pl.global_position) > CHOP_REACH:
			tr = null
	else:
		tr = _nearest_tree(58.0)
	if tr == null:
		return false
	return bool(tu.call("open_for", tr))


const CHOP_REACH: float = 70.0
const DEMOLISH_REACH: float = 130.0
const AXE_NEED: Dictionary = {"stick": 2, "stone_s": 2}     # топор руками: палки с веток и камушки с земли
var hl_tree: Sprite2D = null


## Дерево под точкой мира (по непрозрачным пикселям ствола и кроны)
func tree_at(wp: Vector2) -> Sprite2D:
	var cands: Array = []
	var tall: Dictionary = world.get("tall")
	var c0: Vector2i = Vector2i(int(floor(wp.x / 256.0)), int(floor(wp.y / 256.0)))
	for dy in range(-1, 3):
		for dx in range(-1, 2):
			cands.append_array(tall.get(c0 + Vector2i(dx, dy), []))
	cands.append_array(main.get("yard_trees"))
	var best: Sprite2D = null
	for sv in cands:
		if not is_instance_valid(sv):
			continue
		var s: Sprite2D = sv
		if not s.is_visible_in_tree() or s.texture == null or not IT.is_tree_tex(s.texture.resource_path.get_file().get_basename()):
			continue
		var lp: Vector2 = s.to_local(wp)
		var r: Rect2 = s.get_rect()
		if not r.has_point(lp):
			continue
		var img: Image = main.call("_tex_img", s.texture)
		var ix: int = int(lp.x - r.position.x)
		var iy: int = int(lp.y - r.position.y)
		if s.flip_h:
			ix = int(r.size.x) - 1 - ix
		if ix < 0 or iy < 0 or ix >= img.get_width() or iy >= img.get_height() or img.get_pixel(ix, iy).a < 0.5:
			continue
		# из нескольких — то, что ближе к зрителю (ниже)
		if best == null or s.global_position.y > best.global_position.y:
			best = s
	return best


## Клик по дереву топором: дерево должно быть рядом с героиней
func chop_at(wp: Vector2) -> bool:
	var t2: Sprite2D = tree_at(wp)
	var pl: Node2D = main.get("player") as Node2D
	if t2 == null or t2.global_position.distance_to(pl.global_position) > CHOP_REACH:
		return false
	_chop(t2)
	return true


## Ближайшее дерево перед героиней (в мире и во дворе)
func _nearest_tree(reach: float = 44.0) -> Sprite2D:
	var pl: Node2D = main.get("player") as Node2D
	var p: Vector2 = pl.global_position
	var best: Sprite2D = null
	var bd: float = reach
	var cands: Array = []
	var tall: Dictionary = world.get("tall")
	var c0: Vector2i = Vector2i(int(floor(p.x / 256.0)), int(floor(p.y / 256.0)))
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			cands.append_array(tall.get(c0 + Vector2i(dx, dy), []))
	cands.append_array(main.get("yard_trees"))
	for sv in cands:
		if not is_instance_valid(sv):
			continue
		var s: Sprite2D = sv
		if not s.is_visible_in_tree() or not IT.is_tree_tex(s.texture.resource_path.get_file().get_basename()):
			continue
		var d: float = s.global_position.distance_to(p + Vector2(0, -6))
		if d < bd:
			bd = d
			best = s
	return best


func _chop(t2: Sprite2D = null) -> void:
	if Game.tired():
		get_tree().call_group("player", "react", "sad", 1.4)
		cool = 0.8
		return
	var pl: Node2D = main.get("player") as Node2D
	swing_t = 0.32
	if t2 == null:
		Sound.play("dig", -12.0)
		cool = 0.4
		return
	cool = 0.45
	var tex: String = t2.texture.resource_path.get_file().get_basename()
	var need: int = 5 if tex.begins_with("pine") else 4
	var hits: int = int(chop_hits.get(t2, 0)) + 1
	chop_hits[t2] = hits
	Sound.play("chop", -4.0, 0.12, t2.global_position)
	Game.fx.emit(t2.global_position + Vector2(0, -14), "chips")
	pl.call("react", "pout", 0.4)
	var tw: Tween = create_tween()
	tw.tween_property(t2, "rotation", 0.05, 0.05)
	tw.tween_property(t2, "rotation", -0.04, 0.07)
	tw.tween_property(t2, "rotation", 0.0, 0.06)
	if hits < need:
		return
	chop_hits.erase(t2)
	_remove_tree(t2)
	# в городе деревья рубить нельзя: стража запоминает
	var lw: Node = get_tree().get_first_node_in_group("law18")
	if lw != null:
		var town: String = String(lw.call("land_at", t2.global_position, 100.0))
		if town != "":
			lw.call("report", town, "trees", 1)
	# v24: дерево падает ЦЕЛИКОМ в сторону от героини и лежит с ветками (trees24.gd), остаётся свежий пень.
	# Брёвна — когда обрубишь ветки и порубишь ствол (или отнесёшь ствол в штабель вместе с помощницами)
	var dir: float = 1.0 if pl.global_position.x < t2.global_position.x else -1.0
	var base: Vector2 = t2.global_position
	var tn24: Node = get_tree().get_first_node_in_group("trees24")
	if tn24 != null:
		tn24.call("fell", t2, dir)
	else:
		t2.queue_free()
	var st: Sprite2D = main.call("spr", "stump_cut", base, 0.0, false, null, false)
	stumps.append([st, _abs_minutes()])
	var ns: int = 1 if randf() < 0.75 else 2
	for j in range(ns):
		var ic: String = "icon_sapling_" + tex
		_drop("sapling:" + tex, ic if ResourceLoader.exists("res://art/%s.png" % ic) else "icon_sapling", base + Vector2(-dir * (12.0 + j * 10.0), 6), 0.8 + j * 0.1)
	# v20: чурки, кора, смола — теперь выпадают, когда рубишь ствол на поленья (trees24.drop_logs)
	pl.call("react", "happy", 1.0)


## Предмет выпадает: подпрыгивает на земле и через миг сам летит в руки
func _drop(item: String, tex: String, at: Vector2, delay: float) -> void:
	var s: Sprite2D = Sprite2D.new()
	s.texture = load("res://art/%s.png" % tex)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.scale = Vector2.ONE * (0.6 if tex.begins_with("icon") else 0.8)
	s.position = at
	s.z_index = 5
	s.modulate.a = 0.0
	main.add_child(s)
	var pl: Node2D = main.get("player") as Node2D
	var tw: Tween = create_tween()
	tw.tween_interval(delay * 0.6)
	tw.tween_property(s, "modulate:a", 1.0, 0.05)
	tw.tween_property(s, "position", at + Vector2(0, -16), 0.16).set_ease(Tween.EASE_OUT)
	tw.tween_property(s, "position", at, 0.16).set_ease(Tween.EASE_IN)
	tw.tween_property(s, "position", at + Vector2(0, -5), 0.08).set_ease(Tween.EASE_OUT)
	tw.tween_property(s, "position", at, 0.08).set_ease(Tween.EASE_IN)
	tw.tween_interval(0.25)
	tw.tween_method(func(k: float) -> void:
		if is_instance_valid(pl):
			s.position = at.lerp(pl.global_position + Vector2(0, -20), k * k)
			s.scale = Vector2.ONE * lerpf(0.7, 0.3, k), 0.0, 1.0, 0.3)
	tw.tween_callback(func() -> void:
		Game.add_item(item)
		Sound.play("pickup", -10.0, 0.15)
		s.queue_free())


## Игровые минуты с самого начала (чтобы считать дни без привязки к полуночи)
func _abs_minutes() -> float:
	return float(Game.day) * 1440.0 + Game.minutes


## Пеньки понемногу темнеют, уменьшаются и пропадают за STUMP_DAYS дней
func _update_stumps(delta: float) -> void:
	_stump_t += delta
	if _stump_t < 1.0:
		return
	_stump_t = 0.0
	for i in range(stumps.size() - 1, -1, -1):
		var sp: Sprite2D = stumps[i][0]
		if not is_instance_valid(sp):
			stumps.remove_at(i)
			continue
		var age: float = (_abs_minutes() - float(stumps[i][1])) / (1440.0 * STUMP_DAYS)
		if age >= 1.0:
			sp.queue_free()
			stumps.remove_at(i)
			continue
		sp.modulate = Color(1.0 - 0.25 * age, 1.0 - 0.3 * age, 1.0 - 0.35 * age, 1.0 - age * age * 0.6 - age * 0.4)
		sp.scale = Vector2.ONE * (1.0 - 0.4 * age)


## Убрать дерево из преград и теней
func _remove_tree(t2: Sprite2D) -> void:
	var base: Vector2 = t2.global_position
	var blocks: Dictionary = world.get("blocks")
	var k: Vector2i = Vector2i(int(floor(base.x / 96.0)), int(floor(base.y / 96.0)))
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var lst: Array = blocks.get(k + Vector2i(dx, dy), [])
			for i in range(lst.size() - 1, -1, -1):
				var cv: Vector3 = lst[i]
				if Vector2(cv.x, cv.y).distance_to(base) < 7.0:
					lst.remove_at(i)
	var bc: Array = main.get("block_circles")
	for j in range(bc.size() - 1, -1, -1):
		var c2: Vector3 = bc[j]
		if Vector2(c2.x, c2.y).distance_to(base) < 7.0:
			bc.remove_at(j)
	var casters: Dictionary = world.get("casters")
	for reg in casters.keys():
		var arr: Array = casters[reg]
		for i2 in range(arr.size() - 1, -1, -1):
			if arr[i2][0] == t2:
				(arr[i2][1] as Node).queue_free()
				arr.remove_at(i2)


## Можно ли посадить: не у чужих городов, не на дороге, не в стене
func can_plant(p: Vector2) -> bool:
	for tc in WD.TOWN_C.values():
		if p.distance_to(tc) < WD.TOWN_R + 400.0:
			return false
	if bool(main.call("is_blocked", p)) or WD.road_value(p) < 10.0 or Rect2(Vector2(820, 200) + Game.home_pos - Vector2(960, 358), Vector2(280, 200)).has_point(p):
		return false
	return true


func _plant(id: String, p: Vector2) -> void:
	if not can_plant(p):
		_nope()
		return
	if not Game.take_item(id):
		return
	var s: Node2D = Node2D.new()
	s.set_script(load("res://sapling.gd"))
	s.set("tree", id.substr(8))
	s.set("planted", Game.day)
	s.set("main", main)
	s.set("home", self)
	s.position = p
	main.get("objects").add_child(s)
	Sound.play("dig", -6.0, 0.1, p)
	Game.fx.emit(p, "dust")
	(main.get("player") as Node2D).call("react", "smile", 0.8)
	cool = 0.4


## Дерево выросло: настоящее, его тоже можно срубить
func grow_tree(tex: String, p: Vector2) -> void:
	var s: Sprite2D = main.call("spr", tex, p, 0.5, randf() < 0.5, null, true)
	_block_circle(p + Vector2(0, -2), 6.0)
	(main.get("yard_trees") as Array).append(s)


# ------------------------------------------------------------------ постройки

func _can_place(kind: String, p: Vector2) -> String:
	# v23: постройки королевства — где угодно на воле (не в чужих городах), лишь бы место было свободно
	if kind.begins_with("kg_"):
		for tc0 in WD.TOWN_C.values():
			if p.distance_to(tc0) < WD.TOWN_R + 200.0:
				return "town"
		var bk: Rect2 = IT.BUILD[kind][5]
		var rk: Rect2 = Rect2(p + bk.position, bk.size) if bk.size != Vector2.ZERO else Rect2(p - Vector2(30, 20), Vector2(60, 20))
		for q0 in [rk.position, Vector2(rk.end.x, rk.position.y), rk.end, Vector2(rk.position.x, rk.end.y), rk.get_center()]:
			if bool(main.call("is_blocked", q0)):
				return "busy"
		return ""
	# v20: ловушки ставятся где угодно в дикой природе (но не в городах); верша — только в воду
	if kind.begins_with("trap_"):
		for tc in WD.TOWN_C.values():
			if p.distance_to(tc) < WD.TOWN_R + 120.0:
				return "town"
		if kind == "trap_fish":
			var wet: bool = LAY_POND(p) or WD.biome_at(p) in [WD.SWAMP, WD.BEACH]
			return "" if wet else "dry"
		if bool(main.call("is_blocked", p)):
			return "busy"
		return ""
	if not plot_rect().has_point(p):
		return "outside"
	if kind in MT.FLAT:
		return ""
	var b: Rect2 = IT.BUILD[kind][5]
	var r: Rect2 = Rect2(p + b.position, b.size) if b.size != Vector2.ZERO else Rect2(p - Vector2(30, 20), Vector2(60, 20))
	for q in [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y), r.get_center()]:
		if bool(main.call("is_blocked", q)):
			return "busy"
	if LAY_POND(p):
		return "pond"
	return ""


func LAY_POND(p: Vector2) -> bool:
	return preload("res://world_layout.gd").pond_value(p) < 1.0


## Индекс своей постройки под точкой мира (или -1): по картинке постройки
func placed_at(wp: Vector2) -> int:
	var best: int = -1
	var bd: float = 1e9
	for i in range(placed.size()):
		var kind: String = String(placed[i][0])
		var p: Vector2 = placed[i][1]
		if not IT.BUILD.has(kind):
			continue
		var r: Rect2
		var tex: String = String(IT.BUILD[kind][1])
		if tex != "" and ResourceLoader.exists("res://art/%s.png" % tex):
			var t: Texture2D = load("res://art/%s.png" % tex)
			var sk: float = float(MT.SHRINK.get(tex, 1.0))
			var w: float = float(t.get_width()) * sk
			var h: float = float(t.get_height()) * sk
			if kind in MT.FLAT:
				r = Rect2(p.x - w / 2.0, p.y - h / 2.0, w, h)
			else:
				r = Rect2(p.x - w / 2.0, p.y - h, w, h + 4.0)
		else:
			r = Rect2(p - Vector2(24, 24), Vector2(48, 28))
		if r.grow(6.0).has_point(wp):
			var d: float = wp.distance_to(p)
			if d < bd:
				bd = d
				best = i
	return best


## Убрать свою постройку: вещь возвращается в сумку (вещи из сундука — тоже), всё, что она создала, исчезает
func demolish(i: int) -> bool:
	if i < 0 or i >= placed.size() or i >= placed_rt.size():
		return false
	var kind: String = String(placed[i][0])
	var p: Vector2 = placed[i][1]
	var key: String = "%d,%d" % [int(p.x), int(p.y)]
	# лавку с товаром или выручкой сначала опустошить
	if Game.shops.has(key) and (preload("res://shops26.gd").goods_count(key) > 0 or int(Game.shops[key]["cash"]) > 0):
		Game.toast.emit("Сначала забери товар и выручку", IT.icon("kit:" + kind))
		return false
	var rt: Dictionary = placed_rt[i]
	for nd in (rt["nodes"] as Array):
		if is_instance_valid(nd):
			(nd as Node).queue_free()
	var gl: Array = main.get("glows")
	for g in (rt["glows"] as Array):
		var gi: int = gl.find(g)
		if gi >= 0:
			if is_instance_valid(g[0]):
				(g[0] as Node).queue_free()
			gl.remove_at(gi)
	var br: Rect2 = rt["rect"]
	if br.size != Vector2.ZERO:
		(main.get("block_rects") as Array).erase(br)
		var wbr: Variant = world.get("block_rects")
		if wbr is Array:
			(wbr as Array).erase(br)
	if kind == "pen":
		for pi in range(pens.size() - 1, -1, -1):
			if (pens[pi][0] as Vector2).distance_to(p) < 4.0:
				pens.remove_at(pi)
	if preload("res://storage_db.gd").is_chest(kind):
		var cu: Node = get_tree().get_first_node_in_group("chest_ui")
		if cu != null:
			cu.call("forget", key)
	if Game.shops.has(key):
		Game.shops.erase(key)
	var v24n: Node = get_tree().get_first_node_in_group("v24")
	if v24n != null:
		var dd: Dictionary = v24n.get("doors")
		dd.erase(key)
	placed.remove_at(i)
	placed_rt.remove_at(i)
	Game.add_item("kit:" + kind)
	Sound.play("chop", -6.0, 0.1, p)
	Game.fx.emit(p, "dust")
	return true


func has_built(kind: String) -> bool:
	for pl in placed:
		if String(pl[0]) == kind:
			return true
	return false


func build(kind: String, p: Vector2) -> void:
	var info: Array = IT.BUILD[kind]
	var tex: String = info[1]
	var objs: Node = main.get("objects")
	var b: Rect2 = info[5]
	var n0: int = objs.get_child_count()
	var g0: int = (main.get("glows") as Array).size()
	var brect: Rect2 = Rect2()
	if b.size != Vector2.ZERO:
		brect = Rect2(p + b.position, b.size)
		_block_rect(brect)
	match kind:
		"plot":
			var pl: Node2D = Node2D.new()
			pl.set_script(load("res://plot.gd"))
			pl.position = p
			objs.add_child(pl)
			for sp in pl.get("plants"):
				main.call("add_caster", sp as Sprite2D, true)
		"cauldron":
			main.call("spr", "cauldron", p)
			var cn: Node2D = Node2D.new()
			cn.set_script(load("res://cauldron.gd"))
			cn.position = p
			objs.add_child(cn)
			main.call("add_glow", p + Vector2(0, -8), 0.6, 0.7)
		"outhouse":
			var s: Sprite2D = main.call("spr", "outhouse", p)
			var n: Node2D = Node2D.new()
			n.set_script(load("res://outhouse.gd"))
			n.position = p + Vector2(0, 2)
			n.set("sprite", s)
			objs.add_child(n)
		"well":
			main.call("spr", "well", p)
			main.call("_make_consumable", "well", p + Vector2(0, 32), Vector2(0, -4))
		"campfire":
			main.call("spr", "campfire", p)
			var cf: Node2D = Node2D.new()
			cf.set_script(load("res://campfire.gd"))
			cf.position = p
			objs.add_child(cf)
		"dryer":
			main.call("spr", "dryer", p)
			var dn: Node2D = Node2D.new()
			dn.set_script(load("res://dryer_spot.gd"))
			dn.position = p
			objs.add_child(dn)
		"lantern":
			main.call("spr", "lantern", p)
			main.call("add_glow", p + Vector2(8, -46), 0.75, 0.55)
		"pen":
			var ps: Sprite2D = main.call("spr", "animal_pen", p + Vector2(0, 30), 0.0, false, null, false)
			ps.z_index = 0
			pens.append([p, 0])
			var pn: Node2D = Node2D.new()
			pn.set_script(load("res://placed.gd"))
			pn.set("kind", "pen")
			pn.set("home", self)
			pn.position = p + Vector2(0, 30)
			objs.add_child(pn)
		_ when kind.begins_with("trap_"):
			var tr: Node2D = Node2D.new()
			tr.set_script(load("res://trap20.gd"))
			tr.set("kind", kind)
			tr.set("main", main)
			tr.position = p
			objs.add_child(tr)
		_ when kind in ["beehive", "rain_barrel", "compost", "birdhouse", "bird_feeder", "owl_post", "bird_bath"]:
			main.call("spr", tex, p)
			var yd: Node2D = Node2D.new()
			yd.set_script(load("res://yard20.gd"))
			yd.set("kind", kind)
			yd.position = p
			objs.add_child(yd)
		_ when kind in MT.FLAT:
			# дорожки и клумбы лежат на земле: по ним ходят, они под тенями
			var fs: Sprite2D = main.call("spr", tex, p, 0.0, false, null, false)
			fs.offset = Vector2(-floorf(fs.texture.get_width() / 2.0), -floorf(fs.texture.get_height() / 2.0))
			fs.z_index = -10
		_ when preload("res://storage_db.gd").is_chest(kind):
			# v24: у каждого сундука свой размер и назначение (chest_ui.gd, storage_db.gd)
			var cs: Sprite2D = main.call("spr", tex, p)
			var chn: Node2D = Node2D.new()
			chn.set_script(load("res://placed.gd"))
			chn.set("kind", "chest")
			chn.set("home", self)
			chn.set_meta("chest_kind", kind)
			chn.set_meta("chest_key", "%d,%d" % [int(p.x), int(p.y)])
			chn.position = p + (Vector2(0, 4) if kind == "warehouse" else Vector2.ZERO)
			if kind == "warehouse":
				chn.set("interact_offset", Vector2(0, -20))
			objs.add_child(chn)
			var cu24: Node = get_tree().get_first_node_in_group("chest_ui")
			if cu24 != null:
				cu24.call("register", "%d,%d" % [int(p.x), int(p.y)], kind)
		_ when preload("res://shops26.gd").is_shop(kind):
			# v26: магазин королевства — покупатели приходят сами (shops26.gd)
			main.call("spr", tex, p)
			var skey: String = "%d,%d" % [int(p.x), int(p.y)]
			preload("res://shops26.gd").register(skey, kind)
			var shn: Node2D = Node2D.new()
			shn.set_script(load("res://placed.gd"))
			shn.set("kind", "shop26")
			shn.set("home", self)
			shn.set_meta("shop_key", skey)
			shn.set_meta("shop_kind", kind)
			shn.position = p
			objs.add_child(shn)
		_ when MT.STATIONS.has(kind):
			main.call("spr", tex, p)
			var st: Node2D = Node2D.new()
			st.set_script(load("res://placed.gd"))
			st.set("kind", "chest" if kind == "storage_crate" else kind)
			st.set("home", self)
			st.position = p
			objs.add_child(st)
			if kind in ["kiln", "smelter"]:
				main.call("add_glow", p + Vector2(0, -10), 0.5, 0.6)
		_ when kind in ["stone_lantern", "elf_lantern", "goth_lamp"]:
			main.call("spr", tex, p)
			main.call("add_glow", p + Vector2(0, -30), 0.6, 0.55)
		_:
			main.call("spr", tex, p)
			if kind in ["workbench", "chest", "research", "stall", "forge"]:
				var pn2: Node2D = Node2D.new()
				pn2.set_script(load("res://placed.gd"))
				pn2.set("kind", kind)
				pn2.set("home", self)
				pn2.position = p
				objs.add_child(pn2)
	placed.append([kind, p])
	var v24n: Node = get_tree().get_first_node_in_group("v24")
	if v24n != null:
		v24n.call("on_built", kind, p)
	# что именно создала постройка — нужно, чтобы её можно было убрать (demolish)
	var made: Array = []
	for ci in range(n0, objs.get_child_count()):
		made.append(objs.get_child(ci))
	var made_glows: Array = []
	var all_g: Array = main.get("glows")
	for gi in range(g0, all_g.size()):
		made_glows.append(all_g[gi])
	placed_rt.append({"nodes": made, "glows": made_glows, "rect": brect})


# ------------------------------------------------------------------ меню построек (карточки)

func open_menu(kind: String, who: Node2D) -> void:
	if kind == "chest":
		# v23: сундук — сетка как в PoE (chest_ui.gd); v24: у каждого сундука своя сетка и назначение
		var cu: Node = get_tree().get_first_node_in_group("chest_ui")
		if cu != null:
			var ck: String = ""
			var ckind: String = "chest"
			if who != null:
				ck = String(who.get_meta("chest_key", "%d,%d" % [int(who.position.x), int(who.position.y)]))
				ckind = String(who.get_meta("chest_kind", "chest"))
			cu.call("open_chest", ck, ckind)
			return
	menu_target = who
	var opts: Array = []
	var log_ic: Texture2D = load("res://art/icon_log.png")
	var coin_ic: Texture2D = load("res://art/coin.png")
	menu_kind = kind
	for tch in menu_tabs.get_children():
		tch.queue_free()
	if MT.STATIONS.has(kind):
		# мастерская: рецепты карточками — что получится (×сколько) и из чего
		var recs: Array = MT.RECIPES[kind]
		for ri in range(recs.size()):
			var rc: Array = recs[ri]
			var costs: Array = _need_costs(rc[2])
			var tip: String = "%s ×%d\n%s" % [IT.name(String(rc[0])), int(rc[1]), _need_text(rc[2])]
			opts.append([IT.icon(String(rc[0])), costs, tip, "craft:%d" % ri, not _can_pay(rc[2]), int(rc[1])])
	match kind:
		"handcraft":
			# окно крафта (клавиша KB "craft"): верстак из брёвен, остальное делается уже на верстаке
			var wb_need: Dictionary = IT.build_need("workbench")
			opts.append([IT.icon("kit:workbench"), _need_costs(wb_need), "Верстак\n" + _need_text(wb_need), "make:workbench", not _can_pay(wb_need)])
			opts.append([IT.icon("axe"), _need_costs(AXE_NEED), "Топор\n" + _need_text(AXE_NEED), "tool:axe", not _can_pay(AXE_NEED)])
		"workbench":
			# вкладки: хозяйство, мастерские, ловушки, для птиц, украшения, ограды и дорожки
			var v23n: Node = get_tree().get_first_node_in_group("v23")
			var all_tabs: Array = MT.TABS.duplicate()
			if v23n != null:
				all_tabs.append_array(v23n.call("bench_tabs"))
			for tb in all_tabs:
				var tbtn: Button = Button.new()
				tbtn.flat = true
				tbtn.custom_minimum_size = Vector2(110, 82)
				tbtn.focus_mode = Control.FOCUS_NONE
				var tfr: NinePatchRect = _frame(String(tb) == menu_tab, 110)
				tfr.size = Vector2(110, 82) / 3.0
				tbtn.add_child(tfr)
				var tic: TextureRect = _icon(load("res://art/%s.png" % String(TAB_ICONS[tb])), Vector2(90, 66))
				tic.position = Vector2(10, 8)
				tbtn.add_child(tic)
				if Game.SOLO and String(tb) == "wpn":
					tic.texture = load("res://art/icon_hoe.png")
				tbtn.tooltip_text = {"furn": "Мебель", "wpn": "Садовые инструменты и удочка" if Game.SOLO else "Оружие и удочка", "kingdom": "Королевство", "home": "Хозяйство", "work": "Мастерские", "trap": "Ловушки", "bird": "Для птиц", "deco": "Украшения", "wall": "Ограды и дорожки"}[tb]
				tbtn.pressed.connect(func() -> void:
					menu_tab = String(tb)
					Sound.play("page", -10.0)
					open_menu("workbench", menu_target))
				menu_tabs.add_child(tbtn)
			if v23n != null and menu_tab in (v23n.call("bench_tabs") as Array):
				opts.append_array(v23n.call("bench_cards", menu_tab))
			var all_b: Dictionary = MT.BUILD.duplicate()
			all_b.merge(IT.V24.BUILD)
			for k in all_b.keys():
				if String((all_b[k] as Array)[4]) != menu_tab or k == "workbench":
					continue
				if k == "plot" and Game.SOLO:
					continue   # v29: старый огород убран — грядки теперь на заднем дворе
				if k == "outhouse" and not Game.TOILET_ENABLED:
					continue   # туалет убран из построек (нужды выключены)
				var need: Dictionary = IT.build_need(String(k))
				opts.append([IT.icon("kit:" + String(k)), _need_costs(need), String((all_b[k] as Array)[0]) + "\n" + _need_text(need), "make:" + String(k), not _can_pay(need)])
		"chest":
			opts.append([load("res://art/icon_pack.png"), [], "→", "put"])
			opts.append([load("res://art/dp_chest_small.png"), [], "←", "take"])
		"research":
			opts.append([load("res://art/research_table.png"), [], "", "study"])
		"post":
			# v20: участок растёт не за деньги (это и так её земля), а трудом: колышки, верёвка, камни для межи
			if Game.plot_level < MAX_LEVEL:
				var pn: Dictionary = MT.PLOT_NEED[Game.plot_level]
				opts.append([load("res://art/plot_stake.png"), _need_costs(pn), "Расширить участок\n" + _need_text(pn), "grow", not _can_pay(pn)])
		"pen":
			# v23: забрать дары зверей (яйца, молоко, шерсть...)
			var fm2: Node = get_tree().get_first_node_in_group("farm23")
			if fm2 != null:
				fm2.call("collect_at", menu_target.global_position + Vector2(0, -30))
			opts.append([load("res://art/animal_pen.png"), [[load("res://art/fx_heart.png"), _pen_count(menu_target.global_position + Vector2(0, -30))]], "", "close"])
		"stall", "forge":
			opts = _paths_cards(kind)
		"shop26":
			opts = _shop_cards(who)
	menu_opts = opts
	for ch in menu_list.get_children():
		ch.queue_free()
	for i in range(opts.size()):
		var o: Array = opts[i]
		var card: Control = _card(o[0], o[1], String(o[2]), _menu_choose.bind(i))
		if o.size() > 4 and bool(o[4]):
			card.modulate = Color(1, 1, 1, 0.5)    # не хватает материалов
		if o.size() > 5 and int(o[5]) > 1:
			var cnt: Label = _num("×%d" % int(o[5]), 24)
			cnt.position = Vector2(108, 6)
			card.add_child(cnt)
		menu_list.add_child(card)
	var rows: int = int(ceil(float(opts.size()) / 8.0))
	var tabs_h: float = 100.0 if menu_tabs.get_child_count() > 0 else 0.0
	menu_scroll.position = Vector2(30, 20 + tabs_h)
	var list_h: float = minf(float(rows) * 202.0, 920.0 - tabs_h)
	menu_scroll.size = Vector2(1420, list_h)
	menu_np.size = Vector2(1480, 50 + tabs_h + list_h) / menu_np.scale.x
	menu_panel.visible = true
	Game.ui_open = true
	Sound.play("page", -8.0)


## v26: карточки магазина королевства — из сумки / из сундуков базы / забрать назад / выручка
func _shop_cards(who: Node2D) -> Array:
	var S = preload("res://shops26.gd")
	var s26: Node = get_tree().get_first_node_in_group("shops26")
	var opts: Array = []
	if who == null or s26 == null:
		return opts
	var key: String = String(who.get_meta("shop_key", ""))
	if not Game.shops.has(key):
		return opts
	var sh: Dictionary = Game.shops[key]
	var kind: String = String(sh["kind"])
	var coin_ic: Texture2D = load("res://art/coin.png")
	var pack_ic: Texture2D = load("res://art/icon_pack.png")
	var bag: int = S.bag_count(kind)
	var chs: int = int(s26.call("chest_count", kind))
	var on: int = S.goods_count(key)
	opts.append([pack_ic, [[pack_ic, bag]], "→ из сумки", "shp:put", bag == 0])
	opts.append([load("res://art/dp_chest_small.png"), [[load("res://art/dp_chest_small.png"), chs]], "→ из сундуков базы", "shp:restock", chs == 0])
	opts.append([load("res://art/%s.png" % String(IT.BUILD[kind][1])), [[pack_ic, on]], "← забрать товар", "shp:take", on == 0])
	opts.append([coin_ic, [[coin_ic, int(sh["cash"])]], "выручка", "shp:cash", int(sh["cash"]) == 0])
	return opts


## Ранний доступ: карточки лавки зелий и кузницы — без слов, только значки и числа
func _paths_cards(kind: String) -> Array:
	var PDB = preload("res://paths_db.gd")
	var pth: Node = get_tree().get_first_node_in_group("paths")
	var opts: Array = []
	if pth == null:
		return opts
	var coin_ic: Texture2D = load("res://art/coin.png")
	if kind == "stall":
		var in_bag: int = 0
		var bag_ic: Texture2D = load("res://art/icon_bottle.png")
		for id in Game.inventory.keys():
			var sid: String = String(id)
			if Game.get_count(sid) > 0 and PDB.sellable(sid) and not Game.hotbar.has(sid):
				in_bag += Game.get_count(sid)
				bag_ic = IT.icon(sid)
		var on_stall: int = int(pth.call("stall_count"))
		var st_ic: Texture2D = load("res://art/icon_bottle.png")
		for gid in (Game.stall["goods"] as Dictionary).keys():
			st_ic = IT.icon(String(gid))
		opts.append([bag_ic, [[load("res://art/icon_pack.png"), in_bag]], "→", "pth:put", in_bag == 0])
		opts.append([load("res://art/stall_purple.png"), [[st_ic, on_stall]], "←", "pth:take", on_stall == 0])
		opts.append([coin_ic, [[coin_ic, int(Game.stall["cash"])]], "", "pth:cash", int(Game.stall["cash"]) == 0])
		var lure_ic: String = "res://art/icon_lure.png"
		var busy_lure: bool = float(pth.call("abs_min")) < float(Game.stall.get("lure_cd", -1.0))
		opts.append([load(lure_ic) if ResourceLoader.exists(lure_ic) else load("res://art/fx_heart.png"), [[load("res://art/fx_heart.png"), int(Game.stall.get("fame", 0))]], "", "pth:lure", busy_lure or on_stall == 0])
	else:
		for rid in PDB.SMITH_ORDER:
			var r: String = String(rid)
			var need: Dictionary = (PDB.FORGE[r] as Array)[0]
			var costs: Array = []
			for k in need.keys():
				var ks: String = String(k)
				costs.append([load("res://art/icon_ore_star.png") if ks == "ore" else IT.icon(ks), int(need[k])])
			opts.append([IT.icon(r), costs, IT.name(r), "pth:forge:" + r, not bool(pth.call("can_forge", r))])
	return opts


## Цена значками: [[значок, сколько, хватает ли], ...] (группы вроде «любые доски» — значком того, что есть в сумке)
func _need_costs(need: Dictionary) -> Array:
	var out: Array = []
	for k in need.keys():
		var ks: String = String(k)
		var ic: Texture2D = IT.icon(MT.need_icon(Game.inventory, ks))
		out.append([ic, int(need[k]), _have(ks) >= int(need[k])])
	return out


func _need_text(need: Dictionary) -> String:
	var parts: Array = []
	for k in need.keys():
		var ks: String = String(k)
		parts.append("%s ×%d" % [MT.need_name(ks) if ks.begins_with("@") else IT.name(ks), int(need[k])])
	return ", ".join(parts)


var _pool_frame: int = -1
var _pool_cache: Dictionary = {}


## v26: всё, что можно потратить на верстаке: сумка + сундуки на базе
func pool() -> Dictionary:
	var fr: int = Engine.get_process_frames()
	if fr == _pool_frame:
		return _pool_cache
	var p: Dictionary = {}
	for k in Game.inventory.keys():
		if int(Game.inventory[k]) > 0:
			p[String(k)] = int(Game.inventory[k])
	var cu: Node = get_tree().get_first_node_in_group("chest_ui")
	if cu != null:
		var bt: Dictionary = cu.call("base_totals")
		for k2 in bt.keys():
			p[String(k2)] = int(p.get(String(k2), 0)) + int(bt[k2])
	_pool_frame = fr
	_pool_cache = p
	return p


## Взять n штук: сначала из сумки, остальное из сундуков базы
func take_any(id: String, n: int) -> void:
	_pool_frame = -1
	var inv: int = mini(n, Game.get_count(id))
	if inv > 0:
		Game.take_item(id, inv)
	if n - inv > 0:
		var cu: Node = get_tree().get_first_node_in_group("chest_ui")
		if cu != null:
			cu.call("base_take", id, n - inv)


func _have(need: String) -> int:
	return MT.have(pool(), need)


func _can_pay(need: Dictionary) -> bool:
	for k in need.keys():
		if _have(String(k)) < int(need[k]):
			return false
	return true


## Потратить материалы (сначала проверить всё, потом брать)
func _pay(need: Dictionary) -> bool:
	if not _can_pay(need):
		return false
	for k in need.keys():
		var ks: String = String(k)
		var left: int = int(need[k])
		if not ks.begins_with("@"):
			take_any(ks, left)
			continue
		var pl: Dictionary = pool().duplicate()
		for id in pl.keys():
			if left <= 0:
				break
			if MT.in_group(String(id), ks):
				var n: int = mini(left, int(pl[id]))
				if n > 0:
					take_any(String(id), n)
					left -= n
	Game.inventory_changed.emit()
	return true


func _close_menu() -> void:
	menu_panel.visible = false
	Game.ui_open = false


func _menu_choose(i: int) -> void:
	if i < 0 or i >= menu_opts.size():
		return
	Sound.play("ui_click", -6.0)
	var act: String = menu_opts[i][3]
	if act == "close":
		_close_menu()
		return
	if act.begins_with("shp:"):
		# v26: магазин королевства — меню остаётся открытым
		var s26: Node = get_tree().get_first_node_in_group("shops26")
		var sk: String = String(menu_target.get_meta("shop_key", "")) if menu_target != null else ""
		if s26 == null or not bool(s26.call("act", sk, act.substr(4))):
			_nope()
		open_menu("shop26", menu_target)
		return
	if act.begins_with("pth:"):
		# ранний доступ: лавка и кузница — меню остаётся открытым
		var pth: Node = get_tree().get_first_node_in_group("paths")
		var a2: String = act.substr(4)
		var ok: bool = false
		if pth != null:
			if a2.begins_with("forge:"):
				ok = bool(pth.call("forge", a2.substr(6)))
			else:
				ok = bool(pth.call("stall_act", a2))
		if not ok:
			_nope()
		var mk: String = "forge" if a2.begins_with("forge:") else "stall"
		open_menu(mk, menu_target)
		return
	if act.begins_with("v23:"):
		var vn: Node = get_tree().get_first_node_in_group("v23")
		if vn == null or not bool(vn.call("bench_craft", act.substr(4))):
			_nope()
			return
		Sound.play("anvil", -10.0)
		swing_t = 0.32
		open_menu(menu_kind, menu_target)
		return
	if act == "tool:axe":
		if not _pay(AXE_NEED):
			_nope()
			return
		Game.add_item("axe")
		Sound.play("anvil", -10.0)
		Game.skill_xp("craft", 2.0)
		# сразу в панель быстрого доступа, если есть свободная ячейка
		if not Game.hotbar.has("axe") and Game.hotbar.has(""):
			Game.hotbar[Game.hotbar.find("")] = "axe"
		_refresh()
		open_menu(menu_kind, menu_target)
		return
	if act.begins_with("make:"):
		var k: String = act.substr(5)
		if not _pay(IT.build_need(k)):
			_nope()
			return
		Game.add_item("kit:" + k)
		Sound.play("anvil", -10.0)
		open_menu(menu_kind, menu_target)
		return
	if act.begins_with("craft:"):
		# v20: мастерская — сделать по рецепту
		var rc: Array = (MT.RECIPES[menu_kind] as Array)[int(act.substr(6))]
		if not _pay(rc[2]):
			_nope()
			return
		Game.add_item(String(rc[0]), int(rc[1]))
		Game.skill_xp("craft", 2.0)
		if randf() * 100.0 < Game.stat("craft"):
			Game.add_item(String(rc[0]), int(rc[1]))   # v23: навык ремесла — иногда вдвое
		Sound.play(String((MT.STATIONS[menu_kind] as Array)[1]), -6.0, 0.1)
		swing_t = 0.32
		Game.fatigue = minf(1.0, Game.fatigue + 0.003)
		open_menu(menu_kind, menu_target)
		return
	match act:
		"put":
			for id in Game.inventory.keys():
				var n: int = int(Game.inventory[id])
				if n > 0 and not Game.hotbar.has(String(id)):
					Game.chest[id] = int(Game.chest.get(id, 0)) + n
					Game.inventory[id] = 0
			Game.inventory_changed.emit()
			Sound.play("door", -8.0)
		"take":
			for id2 in Game.chest.keys():
				Game.inventory[id2] = int(Game.inventory.get(id2, 0)) + int(Game.chest[id2])
			Game.chest.clear()
			Game.inventory_changed.emit()
			Sound.play("door", -8.0)
		"study":
			var n2: int = 0
			for id3 in Game.inventory.keys():
				var sid: String = String(id3)
				if int(Game.inventory[sid]) > 0 and preload("res://herbs_db.gd").DATA.has(sid) and not Game.researched.has(sid):
					Game.take_item(sid)
					Game.researched[sid] = true
					n2 += 1
					Game.toast.emit("%s ✦" % preload("res://herbs_db.gd").short(sid), preload("res://herbs_db.gd").icon(sid))
			if n2 == 0:
				_nope()
			else:
				Sound.play("page", -4.0)
		"grow":
			if Game.plot_level >= MAX_LEVEL or not _pay(MT.PLOT_NEED[Game.plot_level]):
				_nope()
			else:
				Game.plot_level += 1
				Game.fatigue = minf(1.0, Game.fatigue + 0.05)   # вбить колышки — работа
				Sound.play("chop", -6.0)
				Game.inventory_changed.emit()
				_redraw_border()
				Sound.play("ui_select", -4.0)
				border.default_color.a = 1.0
				plot_fill.color.a = 0.2
	_close_menu()


# ------------------------------------------------------------------ приручённые звери

func _pen_count(c: Vector2) -> int:
	for pn in pens:
		if (pn[0] as Vector2).distance_to(c) < 80.0:
			return int(pn[1])
	return 0


## Есть ли место в загоне (до 4 зверей)
func pen_free() -> bool:
	for pn in pens:
		if int(pn[1]) < 6:
			return true
	return false


func _follow_animals(_delta: float) -> void:
	for a in get_tree().get_nodes_in_group("followers"):
		var an: Node2D = a
		for pn in pens:
			if int(pn[1]) < 6 and an.global_position.distance_to(pn[0]) < 90.0:
				pn[1] = int(pn[1]) + 1
				an.call("settle", pn[0])
				var fm: Node = get_tree().get_first_node_in_group("farm23")
				if fm != null:
					fm.call("on_settle", an, pn[0])
				Game.toast.emit("+1", load("res://art/fx_heart.png"))
				Sound.play("ui_select", -8.0)
				break

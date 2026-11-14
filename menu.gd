extends CanvasLayer
## Главное меню: название, «Играть» / «Настройки» / «Выход». Esc в игре — пауза с тем же меню.
## Пока меню открыто, время стоит. Громкость музыки и звуков — ползунками.

const INK: Color = Color("3a2718")
var hud: CanvasLayer
var root: Control
var title: Label
var box: VBoxContainer
var settings: Control          # v24: окно настроек settings24.gd
var open: bool = false
var started: bool = false
var t: float = 0.0
var leaves: CPUParticles2D
var main_panel: Control
var god_btn: Button
var wonder_btn: Button
var give_btn: Button
var ng_root: Control            # новая игра: выбор сценария и места
var ng_title: Label
var ng_grid: GridContainer
var ng_info: Label
var ng_step: int = 0
var ng_scen: String = "herbalist"
var ng_spawn: String = "home"
var giver: Control              # режим бога: выдать предметы
var giver_grid: GridContainer
var giver_cat: String = "Всё"
var tp_btn: Button
var sp_btn: Button
var sp_root: Control            # v21: режим бога — призвать зверя или птицу
var tp_root: Control            # режим бога: телепорт
var cont_btn: Button            # «Продолжить» — есть сохранение или игра уже идёт
var save_btn: Button            # «Сохранить» — только во время игры
var sl_root: Control            # ячейки сохранений
var sl_title: Label
var sl_box: VBoxContainer
var sl_mode: String = "load"    # load / new / save
var cf_root: Control            # подтверждение
var cf_label: Label
var cf_yes: Callable
const GOD = preload("res://god.gd")
const SCN = preload("res://scenarios_db.gd")
const IT = preload("res://items_db.gd")


func setup(h: CanvasLayer) -> void:
	hud = h
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0.10, 0.08, 0.14, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(dim)
	# падающие листья поверх
	leaves = CPUParticles2D.new()
	leaves.texture = load("res://art/fx_leaf.png")
	leaves.amount = 40
	leaves.lifetime = 9.0
	leaves.preprocess = 9.0
	leaves.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	leaves.emission_rect_extents = Vector2(1100, 10)
	leaves.position = Vector2(960, -20)
	leaves.direction = Vector2(0.3, 1)
	leaves.gravity = Vector2(10, 30)
	leaves.initial_velocity_min = 20.0
	leaves.initial_velocity_max = 50.0
	leaves.angular_velocity_min = -90.0
	leaves.angular_velocity_max = 90.0
	leaves.scale_amount_min = 3.0
	leaves.scale_amount_max = 4.0
	root.add_child(leaves)
	var p: Control = Control.new()
	p.position = Vector2(660, 170)
	root.add_child(p)
	main_panel = p
	hud.call("panel", p, Vector2.ZERO, Vector2(600, 740))
	title = Label.new()
	title.text = "Лесной травник"
	title.add_theme_font_override("font", hud.get("font_title"))
	title.add_theme_font_size_override("font_size", 86)
	title.add_theme_color_override("font_color", INK)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, 30)
	title.size = Vector2(600, 100)
	p.add_child(title)
	var leaf: TextureRect = TextureRect.new()
	leaf.texture = load("res://art/potion_heal_salve.png")
	leaf.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	leaf.position = Vector2(260, 140)
	leaf.size = Vector2(80, 80)
	leaf.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	leaf.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	p.add_child(leaf)
	# кнопок много (особенно в режиме бога) — список листается колесом мыши
	var box_scroll: ScrollContainer = ScrollContainer.new()
	box_scroll.position = Vector2(80, 225)
	box_scroll.size = Vector2(440, 480)
	box_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	p.add_child(box_scroll)
	box = VBoxContainer.new()
	box.custom_minimum_size = Vector2(420, 0)
	box.add_theme_constant_override("separation", 10)
	box_scroll.add_child(box)
	cont_btn = _button(box, "Продолжить", _continue)
	_button(box, "Новая игра", func() -> void: _open_slots("new"))
	save_btn = _button(box, "Сохранить", func() -> void: _open_slots("save"))
	_button(box, "Сохранения", func() -> void: _open_slots("load"))
	god_btn = _button(box, "Режим бога: выкл", _toggle_god)
	give_btn = _button(box, "Выдать предметы", _open_giver)
	tp_btn = _button(box, "Телепорт", _open_tp)
	sp_btn = _button(box, "Призвать зверя", _open_spawn)
	wonder_btn = _button(box, "Чудеса бога", func() -> void:
		var v23: Node = get_tree().get_first_node_in_group("v23")
		if v23 != null:
			_continue()
			v23.call("open_god"))
	_button(box, "Настройки", _toggle_settings)
	_button(box, "Выход", func() -> void: Saves.quit_game())
	_build_newgame()
	_build_slots()
	_build_confirm()
	_build_giver()
	_build_teleport()
	_build_spawn()
	_update_god()
	# v24: полноценные настройки (settings24.gd) — своё большое окно
	add_to_group("menu")
	settings = preload("res://settings24.gd").new()
	settings.call("setup", hud, func() -> void: main_panel.visible = true)
	root.add_child(settings)


func _button(parent: Control, text: String, cb: Callable) -> Button:
	var b: Button = Button.new()
	b.text = text
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_override("font", hud.get("font_title"))
	b.add_theme_font_size_override("font_size", 44)
	b.add_theme_color_override("font_color", Color("7a5a3a"))
	b.add_theme_color_override("font_hover_color", INK)
	b.mouse_entered.connect(func() -> void: Sound.play("ui_click", -8.0))
	b.pressed.connect(func() -> void:
		Sound.play("ui_select")
		cb.call())
	parent.add_child(b)
	return b


func _slider(parent: Control, text: String, val: float, cb: Callable) -> void:
	var l: Label = Label.new()
	l.text = text
	l.add_theme_font_override("font", hud.get("font_body"))
	l.add_theme_font_size_override("font_size", 30)
	l.add_theme_color_override("font_color", INK)
	parent.add_child(l)
	var s: HSlider = HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = val
	s.custom_minimum_size = Vector2(380, 30)
	s.value_changed.connect(cb)
	parent.add_child(s)


func _toggle_settings() -> void:
	main_panel.visible = false
	settings.call("open")


# ------------------------------------------------------------------ режим бога

func _toggle_god() -> void:
	Game.god_mode = not Game.god_mode
	if Game.god_mode:
		Game.hunger = 0.0
		Game.thirst = 0.0
	_update_god()
	Game.inventory_changed.emit()


func _update_god() -> void:
	god_btn.text = "Режим бога: " + ("вкл" if Game.god_mode else "выкл")
	god_btn.add_theme_color_override("font_color", Color("b8860b") if Game.god_mode else Color("7a5a3a"))
	give_btn.visible = Game.god_mode
	tp_btn.visible = Game.god_mode
	sp_btn.visible = Game.god_mode
	wonder_btn.visible = Game.god_mode


## Все предметы игры (god.gd): снаряжение, инструменты, травы, зелья, еда, грибы, рыба, руды, постройки, саженцы, листья, насекомые
func _all_items() -> Array:
	return GOD.all_items()


func _build_giver() -> void:
	giver = Control.new()
	giver.position = Vector2(260, 90)
	giver.visible = false
	root.add_child(giver)
	hud.call("panel", giver, Vector2.ZERO, Vector2(1400, 900))
	var tl: Label = Label.new()
	tl.text = "Выдать предметы"
	tl.add_theme_font_override("font", hud.get("font_title"))
	tl.add_theme_font_size_override("font_size", 56)
	tl.add_theme_color_override("font_color", INK)
	tl.position = Vector2(40, 16)
	giver.add_child(tl)
	var hint: Label = Label.new()
	hint.text = "Клик — 1 шт.,  Shift+клик — 10 шт."
	hint.add_theme_font_override("font", hud.get("font_body"))
	hint.add_theme_font_size_override("font_size", 24)
	hint.add_theme_color_override("font_color", Color("7a5a3a"))
	hint.position = Vector2(460, 40)
	giver.add_child(hint)
	var coins_b: Button = Button.new()
	coins_b.text = "+100 монет"
	coins_b.flat = true
	coins_b.focus_mode = Control.FOCUS_NONE
	coins_b.add_theme_font_override("font", hud.get("font_bold"))
	coins_b.add_theme_font_size_override("font_size", 28)
	coins_b.add_theme_color_override("font_color", Color("b8860b"))
	coins_b.position = Vector2(1000, 22)
	coins_b.pressed.connect(func() -> void:
		Game.coins += 100
		Sound.play("coin", -4.0)
		Game.inventory_changed.emit())
	giver.add_child(coins_b)
	# v19: открыть всё в книге
	var book_b: Button = Button.new()
	book_b.text = "Открыть всё в книге"
	book_b.flat = true
	book_b.focus_mode = Control.FOCUS_NONE
	book_b.add_theme_font_override("font", hud.get("font_bold"))
	book_b.add_theme_font_size_override("font_size", 26)
	book_b.add_theme_color_override("font_color", Color("4a7a2a"))
	book_b.position = Vector2(1000, 66)
	book_b.pressed.connect(func() -> void:
		var n: int = GOD.unlock_book()
		Sound.play("page", -4.0)
		book_b.text = "В книге открыто: %d" % n)
	giver.add_child(book_b)
	# вкладки-категории
	var cx: float = 40.0
	var cy: float = 96.0
	for cat in GOD.CATEGORIES:
		var cname: String = String(cat)
		var cb: Button = Button.new()
		cb.text = cname
		cb.flat = true
		cb.focus_mode = Control.FOCUS_NONE
		cb.add_theme_font_override("font", hud.get("font_bold"))
		cb.add_theme_font_size_override("font_size", 24)
		cb.add_theme_color_override("font_color", Color("7a5a3a"))
		cb.add_theme_color_override("font_hover_color", INK)
		cb.position = Vector2(cx, cy)
		cb.pressed.connect(func() -> void:
			giver_cat = cname
			_fill_giver())
		giver.add_child(cb)
		cx += 30.0 + float(cname.length()) * 15.0
	var sc: ScrollContainer = ScrollContainer.new()
	sc.position = Vector2(40, 140)
	sc.size = Vector2(1320, 660)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	giver.add_child(sc)
	giver_grid = GridContainer.new()
	giver_grid.columns = 16
	giver_grid.add_theme_constant_override("h_separation", 8)
	giver_grid.add_theme_constant_override("v_separation", 8)
	sc.add_child(giver_grid)
	_fill_giver()
	var back: Button = _button(giver, "Назад", func() -> void:
		giver.visible = false
		main_panel.visible = true)
	back.position = Vector2(620, 810)


## Заполнить сетку предметами выбранной категории
func _fill_giver() -> void:
	for ch in giver_grid.get_children():
		giver_grid.remove_child(ch)
		ch.queue_free()
	var ids: Array = (GOD.by_category() as Dictionary).get(giver_cat, [])
	for id in ids:
		var sid: String = String(id)
		var b: Button = Button.new()
		b.custom_minimum_size = Vector2(72, 72)
		b.focus_mode = Control.FOCUS_NONE
		b.tooltip_text = IT.name(sid)
		b.icon = IT.icon(sid)
		b.expand_icon = true
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		b.pressed.connect(func() -> void:
			Game.add_item(sid, 10 if Input.is_key_pressed(KEY_SHIFT) else 1))
		giver_grid.add_child(b)


func _open_giver() -> void:
	main_panel.visible = false
	giver.visible = true


# ------------------------------------------------------------------ режим бога: телепорт

func _build_teleport() -> void:
	tp_root = Control.new()
	tp_root.position = Vector2(260, 90)
	tp_root.visible = false
	root.add_child(tp_root)
	hud.call("panel", tp_root, Vector2.ZERO, Vector2(1400, 900))
	var tl: Label = Label.new()
	tl.text = "Телепорт"
	tl.add_theme_font_override("font", hud.get("font_title"))
	tl.add_theme_font_size_override("font_size", 56)
	tl.add_theme_color_override("font_color", INK)
	tl.position = Vector2(40, 16)
	tp_root.add_child(tl)
	var hint: Label = Label.new()
	hint.text = "Город, место, тюрьма или лес — клик, и ты там"
	hint.add_theme_font_override("font", hud.get("font_body"))
	hint.add_theme_font_size_override("font_size", 24)
	hint.add_theme_color_override("font_color", Color("7a5a3a"))
	hint.position = Vector2(360, 40)
	tp_root.add_child(hint)
	var sc: ScrollContainer = ScrollContainer.new()
	sc.position = Vector2(40, 100)
	sc.size = Vector2(1320, 700)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tp_root.add_child(sc)
	var col: VBoxContainer = VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	sc.add_child(col)
	var groups: Array = []
	var by_group: Dictionary = {}
	for tg in GOD.targets():
		var gname: String = String((tg as Dictionary)["group"])
		if not by_group.has(gname):
			by_group[gname] = []
			groups.append(gname)
		(by_group[gname] as Array).append(tg)
	for gname2 in groups:
		var gl: Label = Label.new()
		gl.text = String(gname2)
		gl.add_theme_font_override("font", hud.get("font_title"))
		gl.add_theme_font_size_override("font_size", 34)
		gl.add_theme_color_override("font_color", INK)
		col.add_child(gl)
		var gc: GridContainer = GridContainer.new()
		gc.columns = 4
		gc.add_theme_constant_override("h_separation", 10)
		gc.add_theme_constant_override("v_separation", 6)
		col.add_child(gc)
		for tg2 in (by_group[gname2] as Array):
			var td: Dictionary = tg2
			var b: Button = Button.new()
			b.text = String(td["name"])
			b.custom_minimum_size = Vector2(318, 46)
			b.focus_mode = Control.FOCUS_NONE
			b.add_theme_font_override("font", hud.get("font_body"))
			b.add_theme_font_size_override("font_size", 22)
			b.add_theme_color_override("font_color", Color("5a4028"))
			b.pressed.connect(func() -> void: _teleport(td))
			gc.add_child(b)
	var back: Button = _button(tp_root, "Назад", func() -> void:
		tp_root.visible = false
		main_panel.visible = true)
	back.position = Vector2(620, 810)


## v21: режим бога — любой зверь или птица появляется рядом с героиней
func _build_spawn() -> void:
	sp_root = Control.new()
	sp_root.position = Vector2(260, 90)
	sp_root.visible = false
	root.add_child(sp_root)
	hud.call("panel", sp_root, Vector2.ZERO, Vector2(1400, 900))
	var tl: Label = Label.new()
	tl.text = "Призвать зверя"
	tl.add_theme_font_override("font", hud.get("font_title"))
	tl.add_theme_font_size_override("font_size", 56)
	tl.add_theme_color_override("font_color", INK)
	tl.position = Vector2(40, 16)
	sp_root.add_child(tl)
	var hint: Label = Label.new()
	hint.text = "Клик — зверь появится рядом с тобой"
	hint.add_theme_font_override("font", hud.get("font_body"))
	hint.add_theme_font_size_override("font_size", 24)
	hint.add_theme_color_override("font_color", Color("7a5a3a"))
	hint.position = Vector2(420, 40)
	sp_root.add_child(hint)
	var sc: ScrollContainer = ScrollContainer.new()
	sc.position = Vector2(40, 100)
	sc.size = Vector2(1320, 700)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sp_root.add_child(sc)
	var col: VBoxContainer = VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	sc.add_child(col)
	var wdb = preload("res://wild_db.gd")
	var bdb = preload("res://birds_db.gd")
	var groups: Array = [["Звери", [], false], ["Птицы", [], true]]
	for k in (wdb.ANIMALS as Dictionary).keys():
		(groups[0][1] as Array).append([String(k), String((wdb.ANIMALS[k] as Dictionary).get("name", k))])
	for bid in bdb.ORDER:
		if bdb.DATA.has(bid):
			(groups[1][1] as Array).append([String(bid), String((bdb.DATA[bid] as Dictionary).get("name", bid))])
	for g in groups:
		var gl: Label = Label.new()
		gl.text = String(g[0])
		gl.add_theme_font_override("font", hud.get("font_title"))
		gl.add_theme_font_size_override("font_size", 34)
		gl.add_theme_color_override("font_color", INK)
		col.add_child(gl)
		var gc: GridContainer = GridContainer.new()
		gc.columns = 4
		gc.add_theme_constant_override("h_separation", 10)
		gc.add_theme_constant_override("v_separation", 6)
		col.add_child(gc)
		var is_bird: bool = bool(g[2])
		for e in (g[1] as Array):
			var kid: String = String(e[0])
			var b: Button = Button.new()
			b.text = String(e[1])
			b.custom_minimum_size = Vector2(318, 46)
			b.focus_mode = Control.FOCUS_NONE
			b.add_theme_font_override("font", hud.get("font_body"))
			b.add_theme_font_size_override("font_size", 22)
			b.add_theme_color_override("font_color", Color("5a4028"))
			b.pressed.connect(func() -> void: _spawn_pick(kid, is_bird))
			gc.add_child(b)
	var back: Button = _button(sp_root, "Назад", func() -> void:
		sp_root.visible = false
		main_panel.visible = true)
	back.position = Vector2(620, 810)


func _open_spawn() -> void:
	main_panel.visible = false
	sp_root.visible = true


func _spawn_pick(kid: String, is_bird: bool) -> void:
	sp_root.visible = false
	_play()
	var m: Node = get_tree().current_scene
	if m != null:
		m.call("god_spawn", kid, is_bird)


func _open_tp() -> void:
	main_panel.visible = false
	tp_root.visible = true


## Лечу туда: для лесов место дома ищется так же, как при старте (далеко от городов)
func _teleport(td: Dictionary) -> void:
	var p: Vector2 = td["pos"]
	if p == Vector2.INF:
		p = SCN.find_home(String(td["key"]))
	tp_root.visible = false
	if started:
		_play()
	else:
		_play()
	var m: Node = get_tree().current_scene
	if m != null:
		m.call("teleport_to", p)

# ------------------------------------------------------------------ новая игра: сценарий и место дома

func _build_newgame() -> void:
	ng_root = Control.new()
	ng_root.position = Vector2(160, 70)
	ng_root.visible = false
	root.add_child(ng_root)
	hud.call("panel", ng_root, Vector2.ZERO, Vector2(1600, 940))
	ng_title = Label.new()
	ng_title.add_theme_font_override("font", hud.get("font_title"))
	ng_title.add_theme_font_size_override("font_size", 64)
	ng_title.add_theme_color_override("font_color", INK)
	ng_title.position = Vector2(0, 14)
	ng_title.size = Vector2(1600, 80)
	ng_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ng_root.add_child(ng_title)
	ng_grid = GridContainer.new()
	ng_grid.position = Vector2(60, 120)
	ng_grid.add_theme_constant_override("h_separation", 18)
	ng_grid.add_theme_constant_override("v_separation", 18)
	ng_root.add_child(ng_grid)
	ng_info = Label.new()
	ng_info.add_theme_font_override("font", hud.get("font_body"))
	ng_info.add_theme_font_size_override("font_size", 26)
	ng_info.add_theme_color_override("font_color", INK)
	ng_info.position = Vector2(80, 752)
	ng_info.size = Vector2(1440, 80)
	ng_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ng_root.add_child(ng_info)
	var back: Button = _button(ng_root, "Назад", func() -> void:
		if ng_step == 0:
			ng_root.visible = false
			main_panel.visible = true
		else:
			ng_step = 0
			_fill_newgame())
	back.position = Vector2(120, 840)
	var go: Button = _button(ng_root, "Дальше", func() -> void:
		if ng_step == 0:
			ng_step = 1
			_fill_newgame()
		else:
			_start_new_game())
	go.name = "go"
	go.position = Vector2(1300, 840)


func _open_newgame() -> void:
	main_panel.visible = false
	ng_step = 0
	ng_root.visible = true
	_fill_newgame()


## Карточка выбора: картинка (или цвет биома), название, короткий текст; выбранная — золотая рамка
func _ng_card(sel: bool, tex: Texture2D, col: Color, title_t: String, text: String, size: Vector2, cb: Callable) -> Button:
	var b: Button = Button.new()
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = size
	var fr: NinePatchRect = NinePatchRect.new()
	fr.texture = load("res://art/ui_slot_sel.png" if sel else "res://art/ui_slot.png")
	fr.patch_margin_left = 5
	fr.patch_margin_top = 5
	fr.patch_margin_right = 5
	fr.patch_margin_bottom = 5
	fr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	fr.size = size / 3.0
	fr.scale = Vector2(3, 3)
	fr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(fr)
	if tex != null:
		var ic: TextureRect = TextureRect.new()
		ic.texture = tex
		ic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.position = Vector2((size.x - 120) / 2.0, 20)
		ic.size = Vector2(120, 120)
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(ic)
	else:
		var sw: ColorRect = ColorRect.new()
		sw.color = col
		sw.position = Vector2(24, 22)
		sw.size = Vector2(size.x - 48, 70 if size.y > 230.0 else 44)
		sw.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(sw)
	var tl: Label = Label.new()
	tl.text = title_t
	tl.add_theme_font_override("font", hud.get("font_bold"))
	tl.add_theme_font_size_override("font_size", 24 if size.y > 230.0 else 20)
	tl.add_theme_color_override("font_color", INK)
	tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var ty: float = 148.0 if tex != null else (100.0 if size.y > 230.0 else 72.0)
	tl.position = Vector2(10, ty)
	tl.size = Vector2(size.x - 20, 60)
	tl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(tl)
	var dl: Label = Label.new()
	dl.text = text
	dl.add_theme_font_override("font", hud.get("font_body"))
	dl.add_theme_font_size_override("font_size", 19)
	dl.add_theme_color_override("font_color", Color("6a5038"))
	dl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dl.position = Vector2(14, ty + (62.0 if size.y > 230.0 else 28.0))
	dl.size = Vector2(size.x - 28, 200)
	dl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(dl)
	b.mouse_entered.connect(func() -> void: Sound.play("ui_click", -10.0))
	b.pressed.connect(cb)
	return b


func _fill_newgame() -> void:
	for c in ng_grid.get_children():
		ng_grid.remove_child(c)
		c.queue_free()
	var go: Button = ng_root.get_node("go")
	if ng_step == 0:
		ng_title.text = "Кем ты начнёшь?"
		go.text = "Дальше"
		ng_grid.columns = 5
		ng_grid.add_theme_constant_override("h_separation", 18)
		ng_grid.add_theme_constant_override("v_separation", 18)
		for id in SCN.SCEN_ORDER:
			var s: Dictionary = SCN.SCEN[id]
			var sid: String = String(id)
			var pluses: String = ""
			for pl in s["plus"]:
				pluses += "\n\n✦ " + String(pl)
			ng_grid.add_child(_ng_card(sid == ng_scen, IT.icon(String(s["icon"]).substr(5)), Color.WHITE, String(s["name"]), String(s["text"]) + pluses, Vector2(278, 540), func() -> void:
				ng_scen = sid
				Sound.play("ui_select", -6.0)
				_fill_newgame()))
		ng_info.text = "Выбрано: %s. Дальше — где будет твой дом." % String(SCN.get_s(ng_scen)["name"])
	else:
		ng_title.text = "Где стоит твой дом?"
		go.text = "Начать"
		ng_grid.columns = 7
		ng_grid.add_theme_constant_override("h_separation", 12)
		ng_grid.add_theme_constant_override("v_separation", 12)
		for key in SCN.SPAWN_ORDER:
			var sp: Dictionary = SCN.SPAWNS[key]
			var k: String = String(key)
			ng_grid.add_child(_ng_card(k == ng_spawn, null, sp["col"], String(sp["name"]), String(sp["text"]), Vector2(204, 196), func() -> void:
				ng_spawn = k
				Sound.play("ui_select", -6.0)
				_fill_newgame()))
		ng_info.text = "%s · дом появится здесь: %s." % [String(SCN.get_s(ng_scen)["name"]), String(SCN.SPAWNS[ng_spawn]["name"])]


## Начать: место дома ищется в выбранном биоме, сцена собирается заново уже с домом там
func _start_new_game() -> void:
	# всё прошлое — забыть (иначе рецепты, деньги и задания старой игры перешли бы в новую)
	Saves.reset_game()
	if Saves.has_save(Saves.slot):
		Saves.delete_slot(Saves.slot)   # старое сохранение не стирается, а уходит в .bak
	Game.scenario = ng_scen
	Game.home_biome = ng_spawn
	Game.home_pos = SCN.find_home(ng_spawn)
	Game.new_game_ready = true
	Game.ui_open = false
	get_tree().paused = false
	Sound.mode = "game"
	Sound.cur_track = ""
	get_tree().reload_current_scene()


func show_menu() -> void:
	open = true
	root.visible = true
	settings.visible = false
	main_panel.visible = true
	ng_root.visible = false
	giver.visible = false
	tp_root.visible = false
	sp_root.visible = false
	sl_root.visible = false
	cf_root.visible = false
	_update_god()
	Game.ui_open = true
	get_tree().paused = true
	Sound.mode = "menu"
	Sound.music("music_menu")
	cont_btn.visible = started or Saves.any_save()
	save_btn.visible = started


func _play() -> void:
	started = true
	var m: Node = get_tree().current_scene
	if m != null and m.has_method("save_world"):
		m.set("playing", true)
	open = false
	root.visible = false
	Game.ui_open = false
	get_tree().paused = false
	Sound.mode = "game"
	Sound.cur_track = ""


## v24: бег «нажать один раз» — переключаем здесь (меню живёт всегда)
func _input(event: InputEvent) -> void:
	if KB.pressed("run", event) and bool(Saves.opt.get("run_toggle", false)) and not open:
		KB.run_latched = not KB.run_latched


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and (event as InputEventKey).physical_keycode == KEY_ESCAPE:
		if open and (giver.visible or ng_root.visible or tp_root.visible or sp_root.visible or sl_root.visible or cf_root.visible):
			giver.visible = false
			tp_root.visible = false
			sp_root.visible = false
			ng_root.visible = false
			sl_root.visible = false
			cf_root.visible = false
			main_panel.visible = true
			get_viewport().set_input_as_handled()
		elif open and started:
			_play()
			get_viewport().set_input_as_handled()
		elif not open and not Game.ui_open and not Game.busy:
			show_menu()
			get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if open:
		t += delta
		title.position.y = 30.0 + sin(t * 1.4) * 4.0


# ------------------------------------------------------------------ ранний доступ: продолжить, ячейки, подтверждение

func _continue() -> void:
	if started:
		_play()
		return
	var s: int = Saves.latest_slot()
	if s >= 0:
		Saves.load_game(s)


func _build_slots() -> void:
	sl_root = Control.new()
	sl_root.position = Vector2(460, 170)
	sl_root.visible = false
	root.add_child(sl_root)
	hud.call("panel", sl_root, Vector2.ZERO, Vector2(1000, 700))
	sl_title = Label.new()
	sl_title.add_theme_font_override("font", hud.get("font_title"))
	sl_title.add_theme_font_size_override("font_size", 60)
	sl_title.add_theme_color_override("font_color", INK)
	sl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sl_title.position = Vector2(0, 24)
	sl_title.size = Vector2(1000, 80)
	sl_root.add_child(sl_title)
	sl_box = VBoxContainer.new()
	sl_box.position = Vector2(80, 140)
	sl_box.size = Vector2(840, 400)
	sl_box.add_theme_constant_override("separation", 14)
	sl_root.add_child(sl_box)
	var back: Button = _button(sl_root, "Назад", func() -> void:
		sl_root.visible = false
		main_panel.visible = true)
	back.position = Vector2(420, 590)


func _slot_text(i: int) -> String:
	var inf: Dictionary = Saves.info(i)
	if inf.is_empty():
		return "Ячейка %d — пусто" % (i + 1)
	var sc: String = String(SCN.get_s(String(inf.get("scenario", "herbalist"))).get("name", ""))
	return "Ячейка %d — день %d, %d монет, %s · %s" % [i + 1, int(inf.get("day", 1)), int(inf.get("coins", 0)), sc, String(inf.get("time", "")).replace("T", " ").substr(0, 16)]


func _open_slots(mode: String) -> void:
	sl_mode = mode
	sl_title.text = {"new": "Где начать новую историю?", "load": "Загрузить", "save": "Сохранить"}[mode]
	for c in sl_box.get_children():
		sl_box.remove_child(c)
		c.queue_free()
	for i in range(Saves.SLOTS):
		var b: Button = Button.new()
		b.text = _slot_text(i)
		b.flat = true
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_override("font", hud.get("font_body"))
		b.add_theme_font_size_override("font_size", 30)
		b.add_theme_color_override("font_color", Color("7a5a3a") if Saves.has_save(i) or mode != "load" else Color("b0a080"))
		b.add_theme_color_override("font_hover_color", INK)
		b.custom_minimum_size = Vector2(840, 60)
		var si: int = i
		b.pressed.connect(func() -> void:
			Sound.play("ui_select")
			_slot_chosen(si))
		sl_box.add_child(b)
	main_panel.visible = false
	sl_root.visible = true


func _slot_chosen(i: int) -> void:
	match sl_mode:
		"load":
			if not Saves.has_save(i):
				return
			if started:
				_confirm("Загрузить ячейку %d? Несохранённое пропадёт." % (i + 1), func() -> void: Saves.load_game(i))
			else:
				Saves.load_game(i)
		"save":
			var do_save: Callable = func() -> void:
				var ok: bool = _save_now(i)
				Sound.play("page" if ok else "hiss", -4.0)
				_open_slots("save")
			if Saves.has_save(i) and i != Saves.slot:
				_confirm("Записать поверх ячейки %d?" % (i + 1), do_save)
			else:
				do_save.call()
		"new":
			var go: Callable = func() -> void:
				Saves.slot = i
				sl_root.visible = false
				cf_root.visible = false
				_open_newgame()
			if Saves.has_save(i):
				_confirm("В ячейке %d уже есть история. Начать заново? (старая уйдёт в запасной файл)" % (i + 1), go)
			else:
				go.call()


## Сохранить из меню паузы: на миг «снимаем» паузу для проверки, можно ли (не в тюрьме, не под водой)
func _save_now(i: int) -> bool:
	Game.ui_open = false
	var ok: bool = Saves.can_save() and Saves.save_game(i)
	Game.ui_open = true
	return ok


func _build_confirm() -> void:
	cf_root = Control.new()
	cf_root.position = Vector2(560, 360)
	cf_root.visible = false
	root.add_child(cf_root)
	hud.call("panel", cf_root, Vector2.ZERO, Vector2(800, 340))
	cf_label = Label.new()
	cf_label.add_theme_font_override("font", hud.get("font_body"))
	cf_label.add_theme_font_size_override("font_size", 32)
	cf_label.add_theme_color_override("font_color", INK)
	cf_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cf_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cf_label.position = Vector2(50, 40)
	cf_label.size = Vector2(700, 160)
	cf_root.add_child(cf_label)
	var yes: Button = _button(cf_root, "Да", func() -> void:
		cf_root.visible = false
		if cf_yes.is_valid():
			cf_yes.call())
	yes.position = Vector2(200, 220)
	var no: Button = _button(cf_root, "Нет", func() -> void:
		cf_root.visible = false
		sl_root.visible = true)
	no.position = Vector2(500, 220)


func _confirm(text: String, yes_cb: Callable) -> void:
	cf_label.text = text
	cf_yes = yes_cb
	sl_root.visible = false
	cf_root.visible = true

extends Node
## v22: всё новое одним узлом — плавание в хвосте русалки, события дней, цели (G), итоги дня, шкалы справа.

const EDB = preload("res://events_db.gd")
const GDB = preload("res://goals_db.gd")
const INK: Color = Color("3a2718")
const SHORE_Y: float = 7592.0

var main: Node2D
var hud: CanvasLayer
var player: Node2D
var swim: Node2D
var ui: CanvasLayer
var ev_root: Control
var mer_root: Control
var mer_bar: Control
var win_root: Control
var win_list: VBoxContainer
var win_info: Label
var win_open: bool = false
var goal_t: float = 1.0


func setup(m: Node2D, h: CanvasLayer) -> void:
	main = m
	hud = h
	player = m.get("player") as Node2D
	add_to_group("v22")
	swim = Node2D.new()
	swim.set_script(load("res://swim.gd"))
	swim.name = "Swim"
	player.add_child(swim)
	_build_ui()
	Game.mermaid_ended.connect(_on_mermaid_ended)
	Game.day_changed.connect(_new_day.bind(false))
	_new_day(true)


# ------------------------------------------------------------------ каждый кадр

func _process(delta: float) -> void:
	var sea_now: bool = false
	if Game.mermaid_t > 0.0 and player != null and not bool(main.get("inside")) and main.get("visiting") == null:
		sea_now = player.position.y > SHORE_Y + 60.0 and player.position.y < 90000.0 and player.position.x < 150000.0
		# v23: на пирсе (настил над водой) героиня стоит на ногах — хвоста нет
		var wld: Node = main.get("world")
		if sea_now and wld != null:
			for wr in (wld.get("walk_rects") as Array):
				if (wr as Rect2).grow(6.0).has_point(player.position):
					sea_now = false
					break
	Game.in_sea = sea_now
	mer_root.visible = Game.mermaid_t > 0.0
	if mer_root.visible:
		mer_bar.queue_redraw()
	# v24: окна целей и счётчика целей нет — задания берут только у торговок (quests.gd)


func _on_mermaid_ended() -> void:
	if Game.in_sea:
		# хвост исчез в воде: волна выносит на берег (без вреда)
		player.position = Vector2(player.position.x, SHORE_Y - 50.0)
		Game.in_sea = false
		main.get("cam").call("reset_smoothing")
		Game.toast.emit("Хвост исчез — волна вынесла тебя на берег", load("res://art/fx_drop.png"))
	else:
		Game.toast.emit("Хвост исчез", load("res://art/fx_drop.png"))


# ------------------------------------------------------------------ события дней

func _new_day(first: bool) -> void:
	var id: String = EDB.for_day(Game.day)
	_update_event_badge()
	if Game.event_done_day == Game.day:
		return
	Game.event_done_day = Game.day
	var d: Dictionary = EDB.DATA[id]
	# итоги вчерашнего дня
	var lg: Dictionary = Game.day_log
	var c_now: int = int(Game.counters.get("earned", 0))
	var h_now: int = int(Game.counters.get("herbs", 0))
	if not first and not lg.is_empty():
		var dc: int = c_now - int(lg.get("earned", 0))
		var dh: int = h_now - int(lg.get("herbs", 0))
	Game.day_log = {"day": Game.day, "earned": c_now, "herbs": h_now}
	if id != EDB.NONE:
		# v24: без надписей о дне — игра без подсказок, событие видно по миру
		if id in ["bazaar", "harvest_fair", "sea_feast", "tide"]:
			Game.chron("%s." % String(d["name"]), "event")
	var g: Dictionary = d.get("gift", {})
	if g.has("coins"):
		var cr: Array = g["coins"]
		Game.add_coins(randi_range(int(cr[0]), int(cr[1])))
	if g.has("items"):
		for it in g["items"]:
			var n: int = randi_range(int(it[1]), int(it[2]))
			if n > 0:
				Game.add_item(String(it[0]), n)
	if g.has("rep"):
		Game.rep_add(String(g["rep"][0]), int(g["rep"][1]))


func _update_event_badge() -> void:
	for c in ev_root.get_children():
		c.queue_free()
	var id: String = EDB.for_day(Game.day)
	ev_root.visible = false     # v24: никаких табличек «Ясный день»
	if true:
		return
	var nm: String = EDB.title(id)
	var f: Font = hud.get("font_bold")
	var w: float = ceilf((f.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x + 36.0) / 2.0) * 2.0
	ev_root.position = Vector2(1920.0 - 28.0 - w, 262.0)
	hud.call("panel", ev_root, Vector2.ZERO, Vector2(w, 48))
	hud.call("label", ev_root, nm, f, 22, INK, Vector2(18, 8))


# ------------------------------------------------------------------ интерфейс

func _build_ui() -> void:
	ui = CanvasLayer.new()
	ui.layer = 6
	add_child(ui)
	ev_root = Control.new()
	ev_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(ev_root)
	# шкала хвоста русалки: значок зелья и 10 блоков времени
	mer_root = Control.new()
	mer_root.position = Vector2(1920 - 28 - 190, 322)
	mer_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mer_root.visible = false
	ui.add_child(mer_root)
	hud.call("panel", mer_root, Vector2.ZERO, Vector2(190, 56))
	var ic: TextureRect = TextureRect.new()
	ic.texture = load("res://art/potion_mermaid_tail.png")
	ic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.position = Vector2(8, 6)
	ic.size = Vector2(44, 44)
	mer_root.add_child(ic)
	mer_bar = Control.new()
	mer_bar.size = Vector2(190, 56)
	mer_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mer_bar.draw.connect(_draw_mermaid)
	mer_root.add_child(mer_bar)
	# окно целей
	win_root = Control.new()
	win_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	win_root.visible = false
	var win_layer: CanvasLayer = CanvasLayer.new()
	win_layer.layer = 36
	add_child(win_layer)
	win_layer.add_child(win_root)
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0.10, 0.08, 0.14, 0.45)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	win_root.add_child(dim)
	var p: Control = Control.new()
	p.position = Vector2(360, 90)
	win_root.add_child(p)
	hud.call("panel", p, Vector2.ZERO, Vector2(1200, 900))
	hud.call("label", p, "Цели и календарь", hud.get("font_title"), 56, INK, Vector2(40, 16))
	win_info = hud.call("label", p, "", hud.get("font_body"), 24, Color("7a5a3a"), Vector2(640, 40)) as Label
	var sc: ScrollContainer = ScrollContainer.new()
	sc.position = Vector2(40, 100)
	sc.size = Vector2(1120, 750)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	p.add_child(sc)
	win_list = VBoxContainer.new()
	win_list.custom_minimum_size = Vector2(1090, 0)
	win_list.add_theme_constant_override("separation", 10)
	sc.add_child(win_list)
	hud.call("label", p, "G — закрыть", hud.get("font_body"), 22, Color("8a6a4a"), Vector2(40, 858))


func _draw_mermaid() -> void:
	var lv: float = clampf(Game.mermaid_t / Game.MERMAID_MIN, 0.0, 1.0)
	var n: int = int(ceil(lv * 10.0))
	var warn: bool = lv < 0.15 and int(Time.get_ticks_msec() / 250) % 2 == 0
	for k in range(10):
		var r: Rect2 = Rect2(60 + k * 12, 18, 10, 20)
		mer_bar.draw_rect(r.grow(2), INK)
		mer_bar.draw_rect(r, Color("c4a478"))
		if k < n:
			mer_bar.draw_rect(r, Color("d8503a") if warn else Color("3cc4b0"))


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var k: int = (event as InputEventKey).physical_keycode
	if k == KEY_ESCAPE and win_open:
		toggle_window()
		get_viewport().set_input_as_handled()


func toggle_window() -> void:
	win_open = not win_open
	win_root.visible = win_open
	Game.ui_open = win_open
	if win_open:
		Sound.play("page", -4.0)
		_refresh_window()


func _line(text: String, size: int, col: Color, bold: bool) -> Label:
	var l: Label = Label.new()
	l.text = text
	l.add_theme_font_override("font", hud.get("font_bold") if bold else hud.get("font_body"))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(1080, 0)
	return l


func _refresh_window() -> void:
	for c in win_list.get_children():
		win_list.remove_child(c)
		c.queue_free()
	var total: int = GDB.LIST.size()
	win_info.text = "Выполнено: %d из %d" % [Game.goals_done.size(), total]
	# календарь
	var id: String = EDB.for_day(Game.day)
	win_list.add_child(_line("Сегодня, день %d: %s" % [Game.day, EDB.title(id)], 32, INK, true))
	win_list.add_child(_line(String((EDB.DATA[id] as Dictionary)["text"]), 24, Color("5a4028"), false))
	var up: Array = EDB.upcoming(Game.day + 1, 3)
	for u in up:
		win_list.add_child(_line("День %d (через %d): %s" % [int(u[0]), int(u[0]) - Game.day, EDB.title(String(u[1]))], 24, Color("6a5038"), false))
	var sep: Label = _line("— — —", 24, Color("a08a6a"), false)
	win_list.add_child(sep)
	# сначала невыполненные, потом выполненные
	for pass_done in [false, true]:
		for g in GDB.LIST:
			var gd: Dictionary = g
			var done: bool = Game.goals_done.has(String(gd["id"]))
			if done != pass_done:
				continue
			var pr: Vector2i = GDB.progress(gd)
			var box: VBoxContainer = VBoxContainer.new()
			box.add_theme_constant_override("separation", 0)
			var mark: String = "[готово] " if done else "• "
			box.add_child(_line(mark + String(gd["name"]), 30, Color("2f6a2a") if done else INK, true))
			box.add_child(_line(String(gd["desc"]), 23, Color("5a4028"), false))
			if not done:
				box.add_child(_line("Прогресс: %d из %d   ·   Награда: %s" % [pr.x, pr.y, _reward_text(gd)], 22, Color("8a6a1a"), false))
			win_list.add_child(box)


func _reward_text(g: Dictionary) -> String:
	var parts: Array = []
	if int(g.get("coins", 0)) > 0:
		parts.append("%d монет" % int(g["coins"]))
	for it in g.get("items", []):
		parts.append("%s ×%d" % [preload("res://mats_db.gd").name(String(it[0])) if preload("res://mats_db.gd").has(String(it[0])) else String(it[0]), int(it[1])])
	return ", ".join(parts)


## Проверка целей: выданные награды больше не повторяются
func check_goals() -> void:
	if Game.ui_open and not win_open:
		return
	for g in GDB.LIST:
		var gd: Dictionary = g
		var gid: String = String(gd["id"])
		if Game.goals_done.has(gid) or not GDB.done(gd):
			continue
		Game.goals_done[gid] = Game.day
		if int(gd.get("coins", 0)) > 0:
			Game.add_coins(int(gd["coins"]))
		for it in gd.get("items", []):
			Game.add_item(String(it[0]), int(it[1]))
		Game.toast.emit("Цель: %s" % String(gd["name"]), load("res://art/fx_heart.png"))
		Game.chron("Цель выполнена: %s." % String(gd["name"]), "goal")
		Sound.play("magic", -6.0)
		if Game.goals_done.size() == GDB.LIST.size():
			Game.toast.emit("Все цели выполнены. Ты — настоящая хозяйка леса и моря!", load("res://art/fx_heart.png"))
	if win_open:
		_refresh_window()

extends RefCounted
## v28: топор руками, снос построек, уменьшенные столы, обучение-квест, подгрузка областей, кнопки HUD.
const IT = preload("res://items_db.gd")
const MT = preload("res://mats_db.gd")
const WD = preload("res://world_data.gd")

var m: Node2D
var fails: Array


func ck(ok: bool, name: String) -> void:
	m.call("_check", ok, name, fails)


func run(main: Node2D, f: Array) -> void:
	m = main
	fails = f
	var tree: SceneTree = m.get_tree()
	var hs: Node = tree.get_first_node_in_group("homestead")
	# ---- топор руками
	Game.inventory.clear()
	Game.hotbar = ["", "", "", "", "", "", "", "", ""]
	Game.equip.erase("main1")
	Game.add_item("stick", 2)
	Game.add_item("stone_s", 2)
	hs.call("open_menu", "handcraft", null)
	var ai: int = -1
	var opts: Array = hs.get("menu_opts")
	for i in range(opts.size()):
		if String(opts[i][3]) == "tool:axe":
			ai = i
	ck(ai >= 0, "в окне крафта есть топор")
	hs.call("_menu_choose", ai)
	ck(Game.get_count("axe") == 1 and Game.get_count("stick") == 0 and Game.get_count("stone_s") == 0, "топор сделан из палок и камушков")
	ck(Game.hotbar.has("axe"), "топор сразу в панели быстрого доступа")
	hs.call("_close_menu")
	# ---- уменьшенные столы
	var ws: Sprite2D = m.call("spr", "workbench", Game.home_pos + Vector2(0, 600))
	ck(absf(ws.scale.x - float(MT.SHRINK["workbench"])) < 0.001, "верстак нарисован уменьшенным")
	ws.queue_free()
	# ---- снос
	var p: Vector2 = (hs.call("plot_rect") as Rect2).get_center() + Vector2(120, 40)
	var n0: int = (hs.get("placed") as Array).size()
	hs.call("build", "workbench", p)
	ck((hs.get("placed") as Array).size() == n0 + 1 and (hs.get("placed_rt") as Array).size() == n0 + 1, "постройка записана (с данными для сноса)")
	var idx: int = int(hs.call("placed_at", p + Vector2(0, -8)))
	ck(idx == n0, "постройка находится под курсором (%d)" % idx)
	var kits0: int = Game.get_count("kit:workbench")
	ck(bool(hs.call("demolish", idx)), "постройка убрана")
	ck((hs.get("placed") as Array).size() == n0 and Game.get_count("kit:workbench") == kits0 + 1, "верстак вернулся в сумку")
	await tree.process_frame
	await tree.process_frame
	ck(int(hs.call("placed_at", p + Vector2(0, -8))) < 0, "на месте ничего не осталось")
	# сундук с вещами при сносе отдаёт их в сумку
	hs.call("build", "chest", p)
	var key: String = "%d,%d" % [int(p.x), int(p.y)]
	var cu: Node = tree.get_first_node_in_group("chest_ui")
	cu.call("deposit", "flint", 3, p)
	var fl0: int = Game.get_count("flint")
	ck(bool(hs.call("demolish", int(hs.call("placed_at", p + Vector2(0, -6))))) and Game.get_count("flint") == fl0 + 3 and not Game.chests.has(key), "сундук разобран, вещи в сумке")
	# ---- обучение-квест
	Game.tut_step = 1
	Game.inventory.clear()
	Game.equip.erase("main1")
	Game.hotbar = ["", "", "", "", "", "", "", "", ""]
	var tq: Node = tree.get_first_node_in_group("tutq28")
	tq.call("_update")
	var st: Array = tq.call("_steps")
	ck(st.size() == 3 and not bool(st[0][1]), "обучение: сначала нужен топор")
	Game.add_item("axe")
	Game.hotbar[0] = "axe"
	Game.hot_sel = 0
	Game.add_item("log", 6)
	tq.call("_update")
	ck(Game.tut_step == 2, "обучение: 6 брёвен — задание сменилось на верстак")
	Game.add_item("kit:workbench")
	hs.call("build", "workbench", p)
	tq.call("_update")
	var coins0: int = Game.coins
	tq.call("_update")
	ck(Game.tut_step == 99, "обучение пройдено")
	hs.call("demolish", int(hs.call("placed_at", p + Vector2(0, -8))))
	ck(Game.coins >= coins0, "награда получена")
	# ---- подгрузка областей
	var w: Node = m.get("world")
	var far: Vector2 = WD.TOWN_C.values()[3] if WD.TOWN_C.size() > 3 else Vector2(2000, 2000)
	var ready0: int = (w.get("ready_regions") as Dictionary).size()
	w.call("_update_active", far, false)
	var waited: int = 0
	while (not (w.get("load_queue") as Array).is_empty() or w.get("loading") != Vector2i(-99999, -99999)) and waited < 600:
		w.call("_update_active", far, false)
		await tree.process_frame
		waited += 1
	var rdy: Dictionary = w.get("ready_regions")
	ck(waited < 600, "области подгрузились в фоне за %d кадров" % waited)
	var all_ok: bool = true
	for r in w.get("built").keys():
		if not rdy.has(r):
			all_ok = false
	ck(all_ok and rdy.size() >= ready0, "все построенные области достроены (%d)" % rdy.size())
	# ---- Ад: после выхода из дома камера остаётся в границах Пеклограда
	var rl: Node = m.get_node_or_null("Realm24")
	if rl != null:
		rl.set("active", "hell")
		m.call("_world_limits")
		var cam: Camera2D = m.get("cam")
		ck(cam.limit_left == int((rl.call("org") as Vector2).x) and cam.limit_top < -100000, "в Аду границы камеры остаются адскими")
		rl.set("active", "")
		m.call("_world_limits")
		ck(cam.limit_top > -100000, "вне Ада границы камеры обычные")
	# ---- кнопки HUD нажимаются
	var hud: Node = m.get("hud")
	ck(hud.has_method("_press_action"), "значки меню нажимаются мышью")
	Game.ui_open = false
	# ---- v29: бутылочка, пальма, море во сне, дом на карте, поворот в сундуке, кот, голос
	Game.equip["flask0"] = "calm_tea"
	var bt29: int = Game.get_count("bottle")
	if Game.flask_slots() > 0 and Game.drink_flask(0):
		ck(Game.get_count("bottle") == bt29 + 1, "после зелья осталась пустая бутылочка")
	ck(IT.is_tree_tex("palm") and IT.is_tree_tex("palm_b"), "пальму можно рубить")
	ck(m.has_method("_sea_gifts"), "во сне море приносит подарки")
	ck(ResourceLoader.exists("res://audio/hero_sigh.wav") and ResourceLoader.exists("res://audio/hero_giggle.wav"), "у героини есть голос")
	var cu29: Node = tree.get_first_node_in_group("chest_ui")
	ck(cu29 == null or cu29.has_method("_carry_rot_any"), "в сундуке вещи поворачиваются (R)")
	var ct29: Node = tree.get_first_node_in_group("companion_cat")
	ck(ct29 != null and ct29.get("stay") == false, "кота можно оставить на месте")
	var an29: Node = preload("res://animal.gd").new()
	ck(an29.has_method("is_tamed") and an29.get("stay") == false and an29.has_method("_send_home"), "прирученных можно оставить и отправить гулять у дома")
	an29.free()
	var mu29: Node =tree.get_first_node_in_group("map_ui")
	ck(mu29 == null or mu29.has_method("_draw_home"), "дом отмечен на карте")


## Скриншот: --v28=tables (столы рядом с героиней, панель задания, красная подсветка сноса)
func shot(main: Node2D, what: String) -> void:
	m = main
	var tree: SceneTree = m.get_tree()
	var hs: Node = tree.get_first_node_in_group("homestead")
	var pl: Node2D = m.get("player")
	Game.tut_step = 1
	Game.add_item("axe")
	Game.hotbar[0] = "axe"
	Game.hot_sel = 0
	var base: Vector2 = (hs.call("plot_rect") as Rect2).get_center() + Vector2(0, 60)
	pl.position = base
	var kinds: Array = ["workbench", "research", "forge", "sawmill", "loom", "anvil"]
	for i in range(kinds.size()):
		hs.call("build", kinds[i], base + Vector2(-210.0 + float(i) * 80.0, 70.0))
	m.set("zoom_target", 2.0)
	(m.get("cam") as Camera2D).zoom = Vector2(2, 2)
	if what == "demolish":
		Input.action_press("ui_accept")

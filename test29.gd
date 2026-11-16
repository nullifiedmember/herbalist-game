extends RefCounted
const BY = preload("res://backyard29.gd")
## v29: проверки и скриншоты — открытый двор (без барьера), задний двор (мотыга, посев взмахом, лейка,
## грибные деревья, бочка), погода с дождём, одиночная игра (без королевства, оружия, подземелий).
## Скрин: --shot=... --v29=yard|yard_grow|rain|storm|fog|gate|barrier   Проверки: печатает «T29 ok/FAIL».

var m: Node2D
var fails: int = 0


func ck(ok: bool, name: String) -> void:
	print("T29 %s: %s" % ["ok" if ok else "FAIL", name])
	if not ok:
		fails += 1


func checks(main: Node2D) -> void:
	m = main
	var by: Node = m.get_node("Backyard29")
	var wx: Node = m.get_node("Weather29")
	ck(by != null and wx != null, "задний двор и погода созданы")
	ck(Game.SOLO, "одиночная игра включена")
	# барьер у дома убран (в новой игре двор открыт)
	if not bool(m.get("classic_yard")):
		ck(not bool(m.call("is_blocked", Vector2(700, 300))), "над скамейкой можно пройти (барьер убран)")
		ck(not bool(m.call("is_blocked", Vector2(620, 200))), "в лесок за домом можно зайти")
	# королевство и оружие
	var v23: Node = m.get_node("V23")
	ck(not (v23.call("bench_tabs") as Array).has("kingdom"), "на верстаке нет вкладки королевства")
	var cards: Array = v23.call("bench_cards", "wpn")
	var has_wpn: bool = false
	var has_hoe: bool = false
	for c in cards:
		if String(c[3]).begins_with("v23:wpn:"):
			has_wpn = true
		if String(c[3]) == "v23:hoe":
			has_hoe = true
	ck(not has_wpn and has_hoe, "оружия нет, мотыга есть на верстаке")
	# инструменты (режим скриншота чистит сумку — выдаём, если пропали)
	for tid in ["hoe", "watering_can"]:
		if Game.get_count(tid) <= 0:
			Game.add_item(tid)
	ck(Game.get_count("hoe") >= 1 and Game.get_count("watering_can") >= 1, "мотыга и лейка в сумке")
	# v30: огород справа от дома, в мире; грядки копаем где хотим и засыпаем
	var org: Vector2 = by.get("org")
	ck(org == (Game.home_pos + BY.OFF).round(), "огород стоит справа от дома")
	var arch: Vector2 = org + Vector2(BY.ARCH_X, BY.FENCE_Y)
	ck(not bool(m.call("is_blocked", arch + Vector2(0, -3))), "через арку можно пройти")
	ck(bool(m.call("is_blocked", org + Vector2(200, BY.FENCE_Y - 3))), "передний забор не пускает")
	ck(bool(m.call("is_blocked", org + Vector2(300, BY.FENCE_TOP - 3))), "задний забор не пускает")
	Game.yard29["cells"] = []
	for n0 in by.get("cells"):
		(n0 as Node).queue_free()
	(by.get("cells") as Array).clear()
	Game.hotbar[0] = "hoe"
	Game.hot_sel = 0
	ck(Game.held() == "hoe", "мотыга в руке")
	m.get("player").position = org + Vector2(120, 200)
	ck(bool(by.call("make_cell", Vector2i(1, 2))), "мотыгой вскопана новая грядка")
	ck(not bool(by.call("make_cell", Vector2i(1, 2))), "на месте грядки вторую не вскопать")
	ck(not bool(by.call("can_make", Vector2i(-1, -1))), "за сеткой копать нельзя")
	var cell: Node2D = (by.get("cells") as Array)[0]
	ck(int(Game.yard29["cells"][0]["s"]) == 1, "грядка вскопана")
	Game.seeds["mint"] = 5
	Game.seed_sel = "mint"
	Game.hotbar[0] = ""
	by.call("use", cell, false)
	ck(String(Game.yard29["cells"][0]["c"]) == "mint" and int(Game.seeds["mint"]) == 4, "мята посеяна, семя потрачено")
	Game.hotbar[0] = "hoe"
	by.call("use", cell, false)
	ck((Game.yard29["cells"] as Array).size() == 1, "засеянную грядку мотыга не засыпает")
	Game.hotbar[0] = "watering_can"
	Game.can_water = 0
	by.call("use", cell, false)
	ck(not bool(Game.yard29["cells"][0]["w"]), "пустая лейка не поливает")
	Game.yard29["barrel"] = 20
	by.call("use", _barrel(by), false)
	ck(Game.can_water == 10 and int(Game.yard29["barrel"]) == 10, "лейка наполнена из бочки")
	by.call("use", cell, false)
	ck(bool(Game.yard29["cells"][0]["w"]) and Game.can_water == 9, "грядка полита, вода убыла")
	Game.rain_today = 0.0
	for k in range(3):
		Game.yard29["cells"][0]["w"] = true
		by.call("on_new_day")
	ck(int(Game.yard29["cells"][0]["st"]) == 3, "за три ночи мята выросла")
	var before: int = Game.get_count("mint")
	by.call("use", cell, false)
	ck(Game.get_count("mint") >= before + 2 and String(Game.yard29["cells"][0]["c"]) == "", "урожай собран")
	Game.hotbar[0] = "hoe"
	by.call("use", cell, false)
	ck((Game.yard29["cells"] as Array).size() == 0 and (by.get("cells") as Array).size() == 0, "пустая грядка засыпана мотыгой")
	# взмах мотыгой копает ряд, взмах семенами — ровная борозда
	by.set("stroke", true)
	by.set("stroke_mode", "")
	(by.get("stroke_done") as Dictionary).clear()
	for i in range(5):
		by.set("stroke_cd", 0.0)
		by.call("_stroke_at", org + BY.grid_pos(i, 3) + Vector2(0, -12))
	by.call("_end_stroke")
	ck((Game.yard29["cells"] as Array).size() == 5, "взмах мотыгой вскопал ряд из 5 грядок")
	Game.hotbar[0] = ""
	Game.seeds["chamomile"] = 10
	Game.seed_sel = "chamomile"
	by.set("stroke", true)
	by.set("stroke_n", 0)
	(by.get("stroke_done") as Dictionary).clear()
	(by.get("stroke_rows") as Dictionary).clear()
	for i in range(5):
		by.call("_stroke_at", org + BY.grid_pos(i, 3) + Vector2(0, -12))
	by.call("_end_stroke")
	var all_b: bool = true
	for i in range(5):
		if int(Game.yard29["cells"][i]["b"]) != 1 or String(Game.yard29["cells"][i]["c"]) != "chamomile":
			all_b = false
	ck(all_b, "ряд засеян одним взмахом — бонус борозды")
	# пугало рядом — урожай больше
	var hs: Node = m.get("homestead")
	(hs.get("placed") as Array).append(["scarecrow", org + BY.grid_pos(2, 2)])
	ck(bool(by.call("scarecrow_near", org + BY.grid_pos(1, 3))), "пугало рядом с грядкой замечено")
	(hs.get("placed") as Array).pop_back()
	# дождь поливает
	wx.call("set_weather", "rain", 3.0)
	Game.rain_today = 0.0
	wx.call("_hour")
	ck(bool(Game.yard29["cells"][1]["w"]) and Game.rain_today >= 1.0, "дождь полил грядки")
	# большое грибное дерево: привить гриб -> грибы
	var tr: Node2D = (by.get("trees") as Array)[0]
	ck((by.get("trees") as Array).size() == 1, "одно большое дерево")
	Game.add_item("porcini")
	Game.hotbar[0] = "porcini"
	by.call("use", tr, false)
	ck(String(Game.yard29["trees"][0]["sh"]) == "porcini", "грибница привита")
	by.call("on_new_day")
	var nb: int = Game.get_count("porcini")
	ck(int(Game.yard29["trees"][0]["n"]) >= 1, "на дереве выросли грибы")
	by.call("use", tr, false)
	ck(Game.get_count("porcini") > nb, "грибы собраны")
	# расширение вверх
	var top0: float = (by.call("yard_rect") as Rect2).position.y
	ck(bool(by.call("expand_up")), "двор расширен вверх")
	ck((by.call("yard_rect") as Rect2).position.y < top0 - 90.0, "забор ушёл вверх")
	# вход и выход
	print("T29 итого ошибок: %d" % fails)


func _barrel(by: Node) -> Node2D:
	for n in m.get_tree().get_nodes_in_group("interactables"):
		if n.get("mgr") == by and String(n.get("kind")) == "barrel":
			return n
	return null


func shot(main: Node2D, what: String) -> void:
	m = main
	var by: Node = m.get_node("Backyard29")
	var wx: Node = m.get_node("Weather29")
	if OS.get_cmdline_user_args().has("--checks29"):
		checks(m)
	match what:
		"yard", "yard_rain":
			_fill_yard()
			m.get("player").position = (by.get("org") as Vector2) + Vector2(300, 236)
			Game.hotbar[0] = "watering_can"
			Game.hot_sel = 0
			if what == "yard_rain":
				wx.call("set_weather", "rain", 4.0)
				wx.set("amount", 0.8)
				wx.set("dim", 0.2)
		"rain", "storm", "fog", "cloudy":
			wx.call("set_weather", what, 4.0)
			wx.set("amount", 1.0 if what == "storm" else (0.7 if what == "rain" else 0.0))
			wx.set("dim", {"rain": 0.2, "storm": 0.32, "fog": 0.06, "cloudy": 0.1}[what])
			wx.set("fog", 1.0 if what == "fog" else 0.0)
		"yard_wide":
			_fill_yard()
			m.get("player").position = (by.get("org") as Vector2) + Vector2(250, 200)
			var hs: Node = m.get("homestead")
			hs.call("build", "scarecrow", (by.get("org") as Vector2) + Vector2(260, 130))
			Game.hotbar[0] = "hoe"
			Game.hot_sel = 0
		"tree":
			_fill_yard()
			m.get("player").position = (by.get("org") as Vector2) + Vector2(470, 170)
			Game.hotbar[0] = "hoe"
			Game.hot_sel = 0
		"gate":
			m.get("player").position = (Game.home_pos + Vector2(250, 40)).round()
		"barrier":
			m.get("player").position = Vector2(700, 300)
	(m.get("cam") as Camera2D).reset_smoothing()


func _fill_yard() -> void:
	# огород как его сделала бы травница: два ровных ряда и грядки вразнобой
	var plan: Array = [
		[1, 1, "mint", 0, true, 0], [2, 1, "chamomile", 1, false, 0], [3, 1, "lavender", 2, true, 0], [4, 1, "mint", 3, false, 1],
		[1, 2, "nettle", 3, false, 0], [2, 2, "chamomile", 2, true, 0], [3, 2, "lavender", 3, false, 0], [4, 2, "", 0, false, 0],
		[6, 4, "sage", 1, true, 0], [7, 4, "", 0, true, 0], [6, 5, "thyme", 3, false, 0], [7, 5, "calendula", 2, false, 0],
		[1, 4, "", 0, false, 0],
	]
	var by0: Node = m.get_node("Backyard29")
	for n0 in by0.get("cells"):
		(n0 as Node).queue_free()
	(by0.get("cells") as Array).clear()
	var cs: Array = []
	for e in plan:
		cs.append({"gx": e[0], "gy": e[1], "s": 1, "c": e[2], "st": e[3], "w": e[4], "b": e[5]})
	Game.yard29["cells"] = cs
	for i in range(cs.size()):
		(by0.get("cells") as Array).append(by0.call("_make_cell_node", i))
	Game.yard29["trees"] = [{"s": 2, "age": 9, "sh": "chanterelle", "n": 3}]
	var by: Node = m.get_node("Backyard29")
	for i in range((Game.yard29["cells"] as Array).size()):
		by.call("_refresh_cell", i)
	by.call("_refresh_tree", 0)
	Game.seeds = {"mint": 4, "chamomile": 6, "lavender": 2, "sage": 3}
	Game.can_water = 7

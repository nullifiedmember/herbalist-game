extends RefCounted
## v24: автотест (main._run_tests, флаг --only24 — только он). Проверяет падение деревьев, ветки, переноску,
## штабели, сундуки по назначению, работниц, название королевства, дома, клавиши, факел, туман карты.

var m: Node2D
var fails: Array


func ck(ok: bool, name: String) -> void:
	m.call("_check", ok, "v24: " + name, fails)


func wait(sec: float) -> void:
	await m.get_tree().create_timer(sec).timeout


func run(main: Node2D, f: Array) -> void:
	m = main
	fails = f
	var tree: SceneTree = m.get_tree()
	var pl: Node2D = m.get("player")
	var hs: Node = m.get("homestead")
	var cu: Node = tree.get_first_node_in_group("chest_ui")
	var tn: Node = tree.get_first_node_in_group("trees24")
	var w24: Node = tree.get_first_node_in_group("workers24")
	var v24: Node = tree.get_first_node_in_group("v24")
	ck(tn != null and w24 != null and v24 != null, "модули v24 на месте")
	# --- сундуки по назначению
	Game.chests.clear()
	Game.chest.clear()
	cu.call("register", "100,100", "chest_small")
	cu.call("register", "200,100", "chest_mid")
	Game.chests["100,100"]["filter"] = "herbs"
	var left: int = int(cu.call("deposit", "mint", 5, Vector2(100, 100)))
	ck(left == 0 and _has("100,100", "mint"), "трава легла в сундук для трав")
	left = int(cu.call("deposit", "stone_m", 3, Vector2(100, 100)))
	ck(left == 0 and _has("200,100", "stone_m") and not _has("100,100", "stone_m"), "камни — не в травяной сундук, а в «всё подряд»")
	Game.chests["200,100"]["filter"] = "fish"
	ck(String(cu.call("room_for", "stone_m", Vector2.ZERO)) == "", "камням некуда, если все сундуки под другое")
	ck(int(Game.chest.get("mint", 0)) == 5, "общая сумма сундуков считается")
	var SDB = preload("res://storage_db.gd")
	ck(SDB.category("log") == "wood" and SDB.category("branch_long") == "wood" and SDB.category("mint") == "herbs", "назначения вещей")
	ck(SDB.KINDS["warehouse"][1] * SDB.KINDS["warehouse"][2] > SDB.KINDS["chest"][1] * SDB.KINDS["chest"][2], "склад больше большого сундука")
	cu.call("open_chest", "200,100", "chest_mid")
	ck(int(cu.get("cols")) == 9 and int(cu.get("rows")) == 6, "средний сундук 9×6")
	cu.call("close_chest")
	# постройка сундука на верстаке есть
	ck(IT().BUILD.has("chest_small") and IT().BUILD.has("warehouse") and IT().build_need("warehouse").has("log"), "сундуки и склад есть на верстаке")
	# --- дерево падает целиком (работниц из прошлых проверок отводим подальше, чтобы не помогали)
	var k23a: Node = tree.get_first_node_in_group("kingdom23")
	if k23a != null:
		for wn0 in (k23a.get("nodes") as Dictionary).values():
			(wn0 as Node2D).global_position = Game.home_pos + Vector2(6000, 6000)
			(wn0 as Node2D).visible = false     # невидимые не считаются свободными помощницами
	var spot: Vector2 = Game.home_pos + Vector2(400, 300)
	var t2: Sprite2D = m.call("spr", "tree_a", spot, 0.5, false, null, true)
	(m.get("yard_trees") as Array).append(t2)
	pl.position = spot + Vector2(-30, 4)
	Game.equip["main1"] = "axe"
	var nf: int = Game.felled.size()
	for i in range(6):
		hs.set("cool", 0.0)
		hs.call("_chop", t2)
	await wait(1.8)
	ck(Game.felled.size() == nf + 1, "дерево упало и лежит целиком")
	var fel: Node2D = null
	for f2 in tree.get_nodes_in_group("felled24"):
		if (f2 as Node2D).global_position.distance_to(spot) < 10.0:
			fel = f2
	ck(fel != null and String((fel.get("rec") as Dictionary)["state"]) == "crown", "лежит с ветками")
	ck(absf(absf((fel.get("spr") as Sprite2D).rotation) - PI / 2.0) < 0.05, "лежит на боку (повёрнуто на 90°)")
	var br0: int = Game.get_count("branch_long")
	for i in range(4):
		fel.call("hit", pl)
	await wait(1.4)
	ck(String((fel.get("rec") as Dictionary)["state"]) == "trunk", "ветки обрублены — голый ствол")
	ck(Game.get_count("branch_long") > br0, "длинные ветки в руки")
	Game.add_item("branch_long", 1)
	var st0: int = Game.get_count("stick")
	m.get_node("V23").call("use_item", "branch_long")
	ck(Game.get_count("stick") == st0 + 3, "длинная ветка ломается на 3 палки")
	# --- одной ствол не поднять
	var wk_save: Array = Game.workers.duplicate(true)
	tn.call("try_lift", fel, {})
	ck(not bool(tn.call("carrying")) and float(tn.get("gathering")) <= 0.0, "одной ствол не поднять")
	# --- с помощницей — несут медленно
	var k23: Node = tree.get_first_node_in_group("kingdom23")
	var hidden_w: Array = []
	for wh in (k23.get("nodes") as Dictionary).values():
		if not (wh as Node2D).visible:
			hidden_w.append(wh)
	k23.call("god_hire", 2)
	await wait(0.6)
	for wn in (k23.get("nodes") as Dictionary).values():
		if not hidden_w.has(wn):
			(wn as Node2D).global_position = pl.global_position + Vector2(40, 10)
	tn.call("try_lift", fel, {})
	await wait(0.4)
	for wn2 in (k23.get("nodes") as Dictionary).values():
		if not hidden_w.has(wn2):
			(wn2 as Node2D).global_position = pl.global_position + Vector2(20, 10)
	await wait(0.6)
	ck(bool(tn.call("carrying")), "подняли ствол вместе с работницами")
	ck(Game.carry_speed > 0.0 and Game.carry_speed < 0.7, "с бревном идут медленно (%.2f)" % Game.carry_speed)
	var crew_n: int = (tn.get("crew") as Array).size()
	ck(float(tn.call("carry_speed")) < [0, 0, 0.33, 0.49, 0.67, 0.86, 0.91][clampi(crew_n + 1, 0, 6)], "чем больше рук, тем быстрее")
	pl.position = Game.home_pos + Vector2(-300, 200)
	tn.call("drop_carry")
	ck(not bool(tn.call("carrying")) and Game.carry_speed == 1.0, "положили ствол")
	for wv in hidden_w:
		if is_instance_valid(wv):
			(wv as Node2D).visible = true
	# второй ствол рядом — получается штабель
	var r2: Dictionary = {"tex": "tree_a", "fam": "oak", "x": pl.position.x + 200.0, "y": pl.position.y, "dir": 1.0, "state": "trunk", "hits": 0}
	Game.felled.append(r2)
	var f3: Node2D = tn.call("_spawn_felled", r2, false, false)
	for wn3 in (k23.get("nodes") as Dictionary).values():
		(wn3 as Node2D).global_position = f3.global_position + Vector2(20, 10)
	pl.position = f3.global_position + Vector2(30, 10)
	tn.call("try_lift", f3, {})
	await wait(1.0)
	pl.position = Game.home_pos + Vector2(-300 + 52, 226)
	var np0: int = Game.piles.size()
	tn.call("drop_carry")
	ck(Game.piles.size() == np0 + 1 and int((Game.piles[Game.piles.size() - 1] as Dictionary)["n"]) == 2, "два ствола рядом — штабель из 2")
	# рубка ствола на поленья
	var r4: Dictionary = {"tex": "tree_b", "fam": "oak", "x": pl.position.x + 300.0, "y": pl.position.y, "dir": 1.0, "state": "trunk", "hits": 0}
	Game.felled.append(r4)
	var f4: Node2D = tn.call("_spawn_felled", r4, false, false)
	var lg0: int = Game.get_count("log")
	pl.position = f4.global_position + Vector2(20, 8)
	for i in range(6):
		f4.call("hit", pl)
	await wait(1.6)
	ck(Game.get_count("log") >= lg0 + 3 and not Game.felled.has(r4), "ствол порублен на поленья")
	# --- работница: некуда класть — идёт жаловаться
	Game.chests.clear()
	Game.chest.clear()
	var wn4: Node2D = (k23.get("nodes") as Dictionary).values().back()   # недавно нанятая (в полном тесте есть и старые)
	w24.call("set_busy", wn4, "")
	w24.call("load_up", wn4, "mint", 3)
	(w24.get("st") as Dictionary)[wn4]["s"] = "to_chest"
	await wait(0.2)
	ck(String((w24.get("st") as Dictionary)[wn4]["s"]) in ["to_player", "wait_room"], "без сундука работница идёт к героине")
	cu.call("register", "%d,%d" % [int(wn4.global_position.x), int(wn4.global_position.y + 30)], "chest_small")
	(w24.get("st") as Dictionary)[wn4]["s"] = "to_chest"
	(w24.get("st") as Dictionary)[wn4]["cd"] = 0.0
	await wait(0.3)
	wn4.global_position = Vector2(int(wn4.global_position.x), int(wn4.global_position.y + 30)) + Vector2(0, 16)
	wn4.set("walking", false)
	await wait(0.3)
	ck(int(Game.chest.get("mint", 0)) >= 3, "работница сама сложила травы в сундук")
	if bool(m.get_node("V23").call("talking")):
		m.get_node("V23").set("talk_root", m.get_node("V23").get("talk_root"))
		(m.get_node("V23").get("talk_root") as Control).visible = false
		Game.ui_open = false
	# разговор с работницей — окно с выбором
	w24.call("talk", wn4)
	ck(bool(m.get_node("V23").call("talking")), "разговор с работницей — окно с лицом и выбором")
	(m.get_node("V23").get("talk_root") as Control).visible = false
	Game.ui_open = false
	var T = preload("res://talk24_db.gd")
	var many: bool = true
	for k in ["no_room", "help_carry", "deposit", "greet", "order_ok", "carry_done"]:
		if (T.L[k] as Array).size() < 8:
			many = false
	ck(many, "у каждой реплики много вариантов")
	# --- название королевства своё
	k23.call("found", "Королевство Пушистых Хвостиков")
	ck(String(Game.kingdom.get("name", "")) == "Королевство Пушистых Хвостиков", "королевство с любым названием")
	v24.call("ask_text", "x", "Новое имя", func(s: String) -> void: Game.kingdom["name"] = s)
	v24.call("_ask_ok")
	ck(String(Game.kingdom.get("name", "")) == "Новое имя", "переименование через поле ввода")
	# --- дома королевства — с дверью
	hs.call("build", "kg_house_b", Game.home_pos + Vector2(600, -300))
	var dd: Dictionary = v24.get("doors")
	ck(dd.size() >= 1 and bool((dd.values()[0] as Node).call("is_open")), "в дом королевства можно зайти")
	ck(bool(v24.call("has_house")), "работницам есть где спать")
	k23.call("abdicate")
	# --- клавиши
	ck(KB.code("interact") == KEY_E, "E — действие по умолчанию")
	Game.keybinds["interact"] = KEY_R
	ck(KB.code("interact") == KEY_R and KB.is_key("interact", KEY_R) and not KB.is_key("interact", KEY_E), "клавишу можно переназначить")
	Game.keybinds.erase("interact")
	KB.assign("interact", KEY_Q)
	ck(KB.code("interact") == KEY_Q and KB.code("quests") == KEY_E, "занятая клавиша меняется местами")
	KB.reset_all()
	ck(KB.code("interact") == KEY_E and KB.code("quests") == KEY_Q, "сброс клавиш")
	var mn: CanvasLayer = CanvasLayer.new()
	mn.set_script(load("res://menu.gd"))
	main.add_child(mn)
	mn.call("setup", main.get("hud"))
	ck(mn.get("settings") != null, "окно настроек есть")
	if mn.get("settings") != null:
		var st: Node = mn.get("settings")
		for tb in ["sound", "video", "game", "keys"]:
			st.call("_open_tab", tb)
		ck((st.get("key_btns") as Dictionary).size() == KB.ACTIONS.size(), "в настройках все клавиши (%d)" % KB.ACTIONS.size())
		st.set("visible", false)
	mn.queue_free()
	Game.ui_open = false
	tree.paused = false
	Saves.opt["run_toggle"] = true
	KB.run_latched = true
	ck(KB.down("run"), "бег переключением")
	Saves.opt["run_toggle"] = false
	KB.run_latched = false
	# --- птицы в книге
	var book: Node = main.get("book")
	ck(preload("res://birds_lore24.gd").TEXT.size() == preload("res://birds_db.gd").ORDER.size(), "у каждой птицы своя страничка (%d)" % preload("res://birds_db.gd").ORDER.size())
	book.call("open")
	book.call("set_tab", "bird")
	Game.birds_met["robin"] = true
	book.set("selected", "robin")
	book.call("refresh")
	ck(String((book.get("title_l") as Label).text) == "Зарянка" and String((book.get("desc_l") as Label).text).length() > 10, "страница зарянки в книге")
	book.set("selected", "firebird")
	Game.birds_met.erase("firebird")
	book.call("refresh")
	ck(String((book.get("title_l") as Label).text) == "???", "незнакомая птица скрыта")
	book.call("set_tab", "herb")
	book.call("close")
	Game.birds_met.erase("robin")
	# --- монстры тоже что-то делают с героиней
	var dn: Node = tree.get_first_node_in_group("dungeon23")
	var mp: Vector2 = pl.position + Vector2(400, 0)
	var sl: Node2D = dn.call("spawn_monster", "slime", mp, 1)
	ck(String(sl.call("trick", pl)) == "sticky" and Game.mon_sticky > 0.0, "слизень облепил слизью — героиня еле идёт")
	var sh: Node2D = dn.call("spawn_monster", "mushroom", mp, 1)
	ck(String(sh.call("trick", pl)) == "sleep" and Game.mon_sleep > 0.0, "грибочек усыпил спорами")
	var gh: Node2D = dn.call("spawn_monster", "ghost", mp, 1)
	ck(String(gh.call("trick", pl)) == "confuse" and Game.mon_confuse > 0.0, "привидение напугало — всё наоборот")
	var old_lav: int = int(Game.inventory.get("lavender", 0))
	Game.inventory["lavender"] = 5
	Game.coins = 50
	var skl: Node2D = dn.call("spawn_monster", "skeleton", mp, 1)
	var before: int = 0
	for iv in Game.inventory.values():
		before += int(iv)
	ck(String(skl.call("trick", pl)) == "steal" and not (skl.get("loot") as Dictionary).is_empty(), "скелетик стащил вещь и удирает")
	var after: int = 0
	for iv2 in Game.inventory.values():
		after += int(iv2)
	ck(after < before, "вещи в сумке стало меньше")
	skl.call("defeat")
	var back: int = 0
	for iv3 in Game.inventory.values():
		back += int(iv3)
	ck(back == before, "победила скелетика — вещь вернулась")
	var imp: Node2D = dn.call("spawn_monster", "ice_imp", mp, 1)
	ck(String(imp.call("trick", pl)) == "coins" and Game.coins < 50, "бесёнок стащил монетки")
	imp.call("give_back", true)
	ck(int(Game.mon_stash.get("coins", 0)) > 0, "ушла — монетки в тайнике монстров")
	Game.mon_stash.clear()
	var taken: Array = dn.call("faint")
	ck(not taken.is_empty() and not Game.mon_stash.is_empty(), "без сил — монстры утащили вещи в тайник")
	dn.call("open_stash")
	ck(Game.mon_stash.is_empty() and int(Game.inventory.get("lavender", 0)) == 5, "в сундуке подземелья нашёлся тайник")
	Game.inventory["lavender"] = old_lav
	for mm in [sl, sh, gh, imp]:
		(mm as Node).queue_free()
	Game.mon_sticky = 0.0
	Game.mon_sleep = 0.0
	Game.mon_confuse = 0.0
	# --- факел — предмет, свет только в руке
	var dk: Node = tree.get_first_node_in_group("darkness")
	Game.equip.erase("off1")
	ck(not bool(dk.call("has_light")), "без факела в руке нет света")
	Game.equip["off1"] = "torch"
	ck(bool(dk.call("has_light")) and not bool(dk.call("has_lantern")), "факел в руке светит")
	Game.equip.erase("off1")
	# --- поверхность под ногами
	pl.position = Game.home_pos + Vector2(300, 300)
	ck(String(pl.call("surface")) in ["grass", "gravel", "leaves", "sand", "mud", "stone"], "звук шагов по поверхности: %s" % String(pl.call("surface")))
	# --- туман карты не тянется в новую игру
	var def_ex: Variant = (Saves.get("defaults") as Dictionary).get("explored", PackedByteArray())
	ck(typeof(def_ex) == TYPE_PACKED_BYTE_ARRAY and (def_ex as PackedByteArray).size() == 0, "у новой игры карта закрыта")
	# --- задания только у торговок
	var qn: Node = tree.get_first_node_in_group("quests18")
	var fake: Node2D = Node2D.new()
	fake.set_script(load("res://catgirl.gd"))
	fake.set("npc_name", "Тестовая")
	fake.set("land", "cats")
	fake.set("role", "житель")
	ck((qn.call("offer_for", fake) as Dictionary).is_empty(), "простая жительница заданий не даёт")
	fake.free()
	Game.workers = wk_save
	k23.call("_respawn_all")
	# --- Ад и Рай: свои миры с городами
	var rl: Node = tree.get_first_node_in_group("realm24")
	ck(rl != null and (rl.get("gates") as Array).size() == 2, "в мире стоят огненные и светлые врата")
	var from: Vector2 = pl.position
	await rl.call("enter", "hell", from)
	await wait(0.4)
	ck(String(rl.get("active")) == "hell" and pl.position.y < -150000.0, "шагнула в Пеклоград")
	ck(not bool(m.call("is_blocked", pl.position)), "в Аду стоит на земле")
	var demons: int = 0
	var doors: int = 0
	for c in (rl.get("roots") as Dictionary)["hell"].get_children():
		if String(c.get("tex_name") if c.get("tex_name") != null else "").begins_with("demon_"):
			demons += 1
		if c.get_script() == load("res://house_door.gd"):
			doors += 1
	ck(demons >= 5, "в Пеклограде живут демоницы (%d)" % demons)
	ck(doors >= 8, "в Пеклограде дома, в которые можно зайти (%d)" % doors)
	ck(not bool(m.call("can_save")), "в другом мире не сохраняемся")
	await rl.call("enter", "heaven", from)
	await wait(0.4)
	var angels: int = 0
	for c2 in (rl.get("roots") as Dictionary)["heaven"].get_children():
		if String(c2.get("tex_name") if c2.get("tex_name") != null else "").begins_with("angel_"):
			angels += 1
	ck(String(rl.get("active")) == "heaven" and angels >= 5, "Облакоград с ангелицами (%d)" % angels)
	var NPCd = preload("res://npc_db.gd")
	ck(String(NPCd.LANDS["hell"]["about"]).contains("Раем") and String(NPCd.LANDS["heaven"]["about"]).contains("Пеклоград"), "Ад и Рай не дружат, но не воюют — говорят друг о друге")
	await rl.call("leave")
	await wait(0.3)
	ck(String(rl.get("active")) == "" and pl.position.y > -100000.0, "вернулась из Облакограда")


func _has(key: String, id: String) -> bool:
	for e in (Game.chests[key]["layout"] as Array):
		if String(e["id"]) == id:
			return true
	return false


func IT() -> GDScript:
	return preload("res://items_db.gd")


## Скриншоты: --v24=fell | trunk | pile | carry | chest | work
func shot(main: Node2D, what: String) -> void:
	m = main
	fails = []
	var tree: SceneTree = m.get_tree()
	var pl: Node2D = m.get("player")
	var tn: Node = tree.get_first_node_in_group("trees24")
	var k23: Node = tree.get_first_node_in_group("kingdom23")
	var cam: Camera2D = m.get("cam")
	var at: Vector2 = m.call("free_near", Game.home_pos + Vector2(1150, 760))
	pl.position = at + Vector2(-60, 30)
	cam.reset_smoothing()
	match what:
		"bestiary":
			var dir: String = ""
			for ua in OS.get_cmdline_user_args():
				if String(ua).begins_with("--out="):
					dir = String(ua).substr(6)
			var n: int = preload("res://bestiary24.gd").new().dump(dir)
			print("BESTIARY: картинок %d -> %s" % [n, dir])
			m.get_tree().quit()
			return
		"birds":
			var bk: Node = m.get("book")
			for bid in ["sparrow", "robin", "great_tit", "goldfinch", "kingfisher", "tawny_owl", "firebird", "jay", "magpie", "heron"]:
				Game.birds_met[bid] = true
			Game.birds_seen["robin"] = 2
			bk.call("open")
			bk.call("set_tab", "bird")
			bk.set("selected", "robin")
			bk.call("refresh")
			await wait(0.6)
		"settings", "settings:keys", "settings:video", "settings:game":
			var mn: CanvasLayer = CanvasLayer.new()
			mn.set_script(load("res://menu.gd"))
			m.add_child(mn)
			mn.call("setup", m.get("hud"))
			mn.call("show_menu")
			mn.call("_toggle_settings")
			if what.contains(":"):
				(mn.get("settings") as Node).call("_open_tab", what.get_slice(":", 1))
			await wait(0.5)
		"fell", "trunk":
			var t2: Sprite2D = m.call("spr", "tree_a", at, 0.5, false, null, true)
			var f: Node2D = tn.call("fell", t2, 1.0)
			await wait(2.2)
			if what == "trunk":
				for i in range(4):
					f.call("hit", pl)
				await wait(1.0)
		"pile":
			for n in [3, 6, 10]:
				var r: Dictionary = {"x": at.x + float(n) * 30.0 - 120.0, "y": at.y, "n": n, "fam": "oak"}
				Game.piles.append(r)
				tn.call("_spawn_pile", r)
		"carry", "work":
			k23.call("god_hire", 4)
			await wait(0.6)
			if what == "carry":
				var r2: Dictionary = {"tex": "tree_a", "fam": "oak", "x": at.x, "y": at.y, "dir": 1.0, "state": "trunk", "hits": 0}
				Game.felled.append(r2)
				var f2: Node2D = tn.call("_spawn_felled", r2, false, false)
				for wn in (k23.get("nodes") as Dictionary).values():
					(wn as Node2D).global_position = at + Vector2(randf_range(0, 60), 14)
				pl.position = at + Vector2(40, 12)
				tn.call("try_lift", f2, {})
				await wait(1.2)
				Input.action_press("ui_right")
			else:
				for i in range((k23.get("nodes") as Dictionary).size()):
					k23.call("give_order", i, "wood")
				Game.minutes = 10.0 * 60.0
				await wait(14.0)
		"hell", "heaven", "hell_city", "heaven_city":
			var rl: Node = tree.get_first_node_in_group("realm24")
			await rl.call("enter", what.trim_suffix("_city"), pl.position)
			await wait(0.5)
			if what.ends_with("_city"):
				pl.position = rl.call("org") + Vector2(1400, 1250)
			cam.reset_smoothing()
			await wait(1.0)
		"chest":
			var cu: Node = tree.get_first_node_in_group("chest_ui")
			cu.call("register", "1,1", "warehouse")
			cu.call("deposit", "mint", 30, Vector2.ZERO)
			cu.call("deposit", "log", 12, Vector2.ZERO)
			cu.call("open_chest", "1,1", "warehouse")
	cam.reset_smoothing()

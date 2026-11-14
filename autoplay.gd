extends Node
## Автоигра (--autoplay): бот сам проходит игру на ускорении и пишет сохранение в слот 1 (ячейка «1» в меню).
## Шаг 1: новая игра. Шаг 2: травничество, зелья, карта, земли, фракции, навыки, магия, дом, двор,
## ферма, работницы и королевство с мастерскими. Шаг 3: несколько игровых дней на ускорении x30 —
## работницы рубят, копают, варят, мастерские производят, казна собирает налоги. Потом снимки и сохранение.
## Запуск: godot --path . -- --autoplay [--days=N]

const SCN = preload("res://scenarios_db.gd")
const DB = preload("res://herbs_db.gd")
const RDB = preload("res://recipes_db.gd")
const IT = preload("res://items_db.gd")
const PDB = preload("res://paths_db.gd")
const FD = preload("res://food_db.gd")
const SP = preload("res://spells25_db.gd")
const V = preload("res://v23_data.gd")
const TW = preload("res://towns.gd")
const SLOT: int = 0
const SPEED: float = 30.0
const KNAME: String = "Травяное королевство Рассвета"

var main: Node2D
var hs: Node
var days: int = 12
var shots: String = ""


func start(m: Node2D) -> void:
	main = m
	Saves.opt["pause_unfocus"] = false     # бот играет в фоне — не ставить паузу без фокуса
	Saves.opt["mute_unfocus"] = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("--days="):
			days = int(String(a).substr(7))
	shots = ProjectSettings.globalize_path("res://").path_join("../screenshots/")
	call_deferred("_run")


func say(t: String) -> void:
	print("AUTOPLAY: " + t)


func _run() -> void:
	if OS.get_cmdline_user_args().has("--apcheck"):
		await _check()
		return
	if not Saves.has_meta("ap_phase"):
		# ---------------- шаг 1: новая игра (травница, дом у старой опушки)
		Saves.set_meta("ap_phase", 1)
		say("новая игра")
		Saves.reset_game()
		Saves.slot = SLOT
		Game.scenario = "herbalist"
		Game.home_biome = "home"
		Game.home_pos = SCN.find_home("home")
		Game.new_game_ready = true
		Game.ui_open = false
		get_tree().paused = false
		await get_tree().process_frame
		get_tree().reload_current_scene()
		return
	await get_tree().create_timer(1.5).timeout
	get_tree().paused = false
	Game.ui_open = false
	hs = get_tree().get_first_node_in_group("homestead")
	Game.god_mode = true            # на время стройки: голод и усталость не мешают
	Game.guide_step = 999
	await _herbalism()
	await _world_and_lands()
	await _skills_and_magic()
	await _house()
	await _yard()
	await _farm()
	await _kingdom()
	await _stock()
	await _live_days()
	await _finish()


# ------------------------------------------------------------------ травы и зелья

func _herbalism() -> void:
	say("травы, рецепты, еда")
	for h in DB.DATA.keys():
		Game.discovered[String(h)] = true
		Game.researched[String(h)] = true
		Game.seeds[String(h)] = int(Game.seeds.get(String(h), 0)) + 6
	# каждое зелье — настоящая варка по рецепту (Game.brew_mix сам запишет рецепт, если вышло)
	var ok: int = 0
	for pid in RDB.PRODUCTS.keys():
		var pd: Dictionary = RDB.PRODUCTS[pid]
		if not pd.has("ex"):
			continue
		var ex: Array = pd["ex"]
		if ex.size() < 3:
			continue
		var ings: Array = []
		for ig in (ex[2] as Array):
			ings.append({"id": String(ig[0]), "procs": (ig[1] as Array).duplicate()})
		var res: String = Game.brew_mix(String(ex[0]), String(ex[1]), ings)
		if not Game.known_recipes.has(String(pid)):
			Game.known_recipes[String(pid)] = {"base": String(ex[0]), "temp": String(ex[1]), "ings": ings}
		Game.discovered[String(pid)] = true
		if res == String(pid):
			ok += 1
	say("рецептов зелий: %d (сварено с первого раза %d)" % [Game.known_recipes.size(), ok])
	for r in FD.RECIPES:
		var fid: String = "food_" + String(r[1])
		Game.discovered[fid] = true
		Game.cooked[fid] = true
	Game.chron("Изучила все травы опушки и записала в книгу рецепты зелий.", "start")
	Game.skill_xp("brew", 500.0)
	await get_tree().process_frame


# ------------------------------------------------------------------ карта, земли, фракции

func _world_and_lands() -> void:
	say("карта, земли, союзы, фракции")
	for i in range(Game.explored.size()):
		Game.explored[i] = 255
	var lands: Array = []
	for land in TW.TOWNS.keys():
		lands.append(String(land))
	for land in lands:
		Game.rep[land] = 90
		Game.pacts[land] = {"since": Game.day, "earned": 0}
	for land in lands.slice(0, 3):
		Game.court[land] = Game.day
	var joined: int = 0
	for fid in PDB.FACTION_ORDER:
		var fd: Dictionary = PDB.FACTIONS[fid]
		var rival: String = String(fd.get("rival", ""))
		if rival != "" and Game.factions.has(rival):
			continue
		var rank: int = 4 if joined < 2 else 2
		Game.factions[String(fid)] = {"favor": PDB.RANK_FAVOR[rank], "rank": rank, "task": {}, "since": Game.day}
		Game.chron("Вступила: %s. Звание — %s." % [String(fd["name"]), String((fd["ranks"] as Array)[rank])], "faction")
		joined += 1
	for t in PDB.TITLES.keys():
		Game.add_title(String(t))
	Game.chron("Заключила торговые союзы со всеми землями. Караваны пошли по дорогам.", "pact")
	say("земель %d, фракций %d, титулов %d" % [lands.size(), Game.factions.size(), Game.titles.size()])
	await get_tree().process_frame


# ------------------------------------------------------------------ навыки и магия

func _skills_and_magic() -> void:
	say("навыки, сферы, облики, скакуны")
	for k in Game.SKILL_ORDER:
		Game.skills[String(k)] = Game.skill_need(Game.SKILL_MAX)
	Game.orbs_open = SP.ORDER.duplicate()
	for key in SP.SPELLS.keys():
		Game.spells_known[String(key)] = Game.day
	for f in ["rabbit", "fox", "deer", "boar", "squirrel", "hedgehog", "golden_deer", "unicorn", "ember_fox", "sapphire_hare", "cow", "goat"]:
		if not Game.forms_known.has(f):
			Game.forms_known.append(f)
	for m in ["unicorn", "golden_deer", "deer"]:
		if not Game.mounts.has(m):
			Game.mounts.append(m)
		Game.trust[m] = 10
	Game.mount_kind = "unicorn"
	for k2 in preload("res://farm23.gd").ORDER:
		Game.animals_seen[String(k2)] = Game.day
	Game.hp = Game.hp_max()
	Game.chron("Приручила единорога. Открыла все восемь стихий книги сфер.", "magic")
	await get_tree().process_frame


# ------------------------------------------------------------------ дом: комнаты и мебель

func _house() -> void:
	say("дом: комнаты и мебель")
	var h23: Node = main.get_node_or_null("House23")
	if h23 == null:
		return
	for s in [1, -1, 2, -2]:
		h23.call("build_room", s)
	Game.house_init = true
	Game.furniture = []
	# королевская спальня справа, кошачья гостиная в центре, готическая библиотека слева, мастерская дальше
	var want: Array = ["royal_bed", "royal_wardrobe", "royal_table", "royal_rug", "royal_lamp", "throne",
		"cat_bed", "cat_bookcase", "cat_rug", "cat_table", "cat_tree", "cat_basket", "cat_lamp",
		"gothic_bed", "gothic_bookcase", "gothic_rug", "gothic_lamp", "gothic_dresser", "gothic_plant"]
	var placed: int = 0
	for id in want:
		if not V.FURN.has(id):
			continue
		var done: bool = false
		for s in [1, 0, -1, 2, -2]:
			if done:
				break
			var ox: float = float(h23.call("slot_ox", s))
			for yy in [160.0, 212.0, 250.0, 120.0]:
				if done:
					break
				for xx in [250.0, 290.0, 330.0, 370.0, 270.0, 310.0, 350.0, 390.0]:
					if bool(h23.call("put", id, Vector2(xx + ox, yy), false)):
						done = true
						placed += 1
						break
	if h23.has_method("_build_furniture"):
		h23.call("_build_furniture")
	say("комнат %d, мебели %d" % [Game.rooms.size(), placed])
	Game.chron("Пристроила к дому четыре комнаты: спальня, гостиная, библиотека.", "home")
	await get_tree().process_frame


# ------------------------------------------------------------------ двор: мастерские, сундуки, грядки

func _grid_place(kind: String, area: Rect2, step: Vector2, n: int = 1) -> int:
	var got: int = 0
	var y: float = area.position.y + step.y * 0.5
	while y < area.end.y and got < n:
		var x: float = area.position.x + step.x * 0.5
		while x < area.end.x and got < n:
			var p: Vector2 = Vector2(round(x), round(y))
			if String(hs.call("_can_place", kind, p)) == "":
				hs.call("build", kind, p)
				got += 1
			x += step.x
		y += step.y
	return got


func _yard() -> void:
	say("двор")
	Game.plot_level = 2
	if hs.has_method("_redraw_border"):
		hs.call("_redraw_border")
	var r: Rect2 = hs.call("plot_rect")
	var hp: Vector2 = Game.home_pos
	# у дома — котёл, верстак, стол изучения, сушилка, лавка
	var near: Rect2 = Rect2(hp + Vector2(-420, 40), Vector2(840, 260))
	var core: Array = [["workbench", 1], ["cauldron", 2], ["research", 1], ["dryer", 2], ["stall", 1], ["forge", 1], ["campfire", 1], ["bench", 2], ["lantern", 4]]
	for c in core:
		if not bool(hs.call("has_built", String(c[0]))) or int(c[1]) > 1:
			_grid_place(String(c[0]), near, Vector2(90, 70), int(c[1]))
	# склад и сундуки
	var store_area: Rect2 = Rect2(Vector2(r.position.x + 40, hp.y + 40), Vector2(360, 600))
	_grid_place("warehouse", store_area, Vector2(140, 80), 3)
	for ck in ["chest_big", "chest_big", "chest_mid", "chest_mid", "storage_crate", "barrel"]:
		_grid_place(ck, store_area, Vector2(50, 40), 1)
	# мастерские — справа
	var work: Rect2 = Rect2(Vector2(hp.x + 420, r.position.y + 60), Vector2(r.end.x - hp.x - 460, r.size.y - 120))
	for wk in ["sawmill", "kiln", "smelter", "anvil", "spinning", "loom", "dye_vat", "mason", "jeweler", "press", "woodpile", "hay"]:
		_grid_place(wk, work, Vector2(100, 80), 1)
	# огород и пасека — внизу
	var garden: Rect2 = Rect2(Vector2(hp.x - 400, hp.y + 330), Vector2(800, 420))
	_grid_place("plot", garden, Vector2(80, 70), 16)
	for g in ["beehive", "beehive", "beehive", "compost", "rain_barrel", "rain_barrel", "scarecrow", "birdhouse", "bird_feeder", "bird_bath", "owl_post"]:
		_grid_place(g, garden, Vector2(60, 50), 1)
	# красота
	for d in ["fountain", "rose_bush", "rose_bush", "flower_bed", "flower_bed", "stone_lantern", "elf_lantern", "goth_lamp", "goth_lamp", "banner", "banner", "planter", "planter", "star_globe", "tea_table", "pillar", "pillar"]:
		_grid_place(d, r, Vector2(110, 90), 1)
	# засеять грядки и сразу полить
	var crops: Array = []
	for hk in DB.ORDER:
		var ok3: bool = true
		for st in [1, 2, 3]:
			ok3 = ok3 and ResourceLoader.exists("res://art/%s_%d.png" % [String(hk), st])
		if ok3:
			crops.append(String(hk))
	if crops.is_empty():
		crops = ["mint", "lavender", "chamomile"]
	say("травы для грядок: %s" % str(crops))
	var i: int = 0
	for pl in get_tree().get_nodes_in_group("plots"):
		var c: String = String(crops[i % crops.size()])
		pl.set("crop", c)
		pl.set("stage", 1 + i % 3)
		pl.set("watered", true)
		if pl.has_method("refresh"):
			pl.call("refresh")
		i += 1
	say("построек во дворе: %d, грядок %d" % [(hs.get("placed") as Array).size(), i])
	Game.chron("Расширила участок. Поставила склад, мастерские, пасеку и огород на %d грядок." % i, "home")
	await get_tree().create_timer(0.3).timeout


# ------------------------------------------------------------------ ферма

func _farm() -> void:
	say("ферма")
	var r: Rect2 = hs.call("plot_rect")
	var farm_area: Rect2 = Rect2(Vector2(Game.home_pos.x + 300, Game.home_pos.y + 360), Vector2(r.end.x - Game.home_pos.x - 320, r.end.y - Game.home_pos.y - 380))
	_grid_place("pen", farm_area, Vector2(180, 150), 4)
	var fm: Node = main.get_node_or_null("V23/Farm23")
	if fm == null:
		return
	var sets: Array = [["chicken", "chicken", "goose", "duck", "chicken"], ["cow", "cow", "goat"], ["sheep", "sheep", "sheep", "goat"], ["pig", "pig", "rabbit", "rabbit"]]
	var pens: Array = hs.get("pens")
	for pi in range(pens.size()):
		var pn: Array = pens[pi]
		for k in sets[pi % sets.size()]:
			if int(pn[1]) >= 6:
				break
			var an: Node2D = fm.call("_spawn", String(k), (pn[0] as Vector2) + Vector2(randf_range(-30, 30), 30))
			if an == null:
				continue
			an.call("settle", pn[0])
			Game.farm.append({"kind": String(k), "x": (pn[0] as Vector2).x, "y": (pn[0] as Vector2).y, "born": Game.day, "baby": false, "id": an.get_instance_id(), "ready": 1, "fed": true})
			pn[1] = int(pn[1]) + 1
	say("зверей на ферме: %d" % Game.farm.size())
	Game.chron("Завела ферму: куры, гуси, коровы, овцы, козы и свинки.", "home")
	await get_tree().process_frame


# ------------------------------------------------------------------ работницы и королевство

func _kingdom() -> void:
	say("королевство")
	var kg: Node = main.get_node_or_null("V23/Kingdom23")
	if kg == null:
		return
	kg.set("propose_t", -1.0)
	kg.call("god_hire", 12)
	kg.set("propose_t", -1.0)
	kg.call("found", KNAME)
	# постройки королевства — кольцом вокруг участка, на свободных местах
	var plan: Array = ["kg_palace", "kg_house_c", "kg_house_c", "kg_house_a", "kg_house_a", "kg_house_b", "kg_house_b", "kg_house_elf", "kg_house_jp",
		"kg_house_c", "kg_house_a", "kg_tavern", "kg_teahouse", "kg_stage", "kg_garden", "kg_circle", "kg_bench", "kg_bench",
		"kg_brewery", "kg_brewery", "kg_forge", "kg_bakery", "kg_bakery", "kg_sawmill", "kg_sawmill", "kg_mine", "kg_mine", "kg_tailor", "kg_tailor"]
	var r: Rect2 = hs.call("plot_rect")
	var cands: Array = []
	for ring in range(1, 9):
		var big: Rect2 = r.grow(120.0 + 230.0 * float(ring - 1))
		var xx: float = big.position.x
		while xx <= big.end.x:
			cands.append(Vector2(xx, big.position.y))
			cands.append(Vector2(xx, big.end.y))
			xx += 260.0
		var yy: float = big.position.y + 200.0
		while yy < big.end.y:
			cands.append(Vector2(big.position.x, yy))
			cands.append(Vector2(big.end.x, yy))
			yy += 200.0
	# сначала ближе к дому, дворец — снизу по центру
	cands.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.distance_to(Game.home_pos) < b.distance_to(Game.home_pos))
	var built: Dictionary = {}
	var used: Array = []
	for kind in plan:
		for p in cands:
			var pv: Vector2 = (p as Vector2).round()
			var clash: bool = false
			for u in used:
				if (u as Vector2).distance_to(pv) < 200.0:
					clash = true
					break
			if clash:
				continue
			if String(hs.call("_can_place", kind, pv)) == "":
				hs.call("build", kind, pv)
				used.append(pv)
				built[kind] = int(built.get(kind, 0)) + 1
				await get_tree().process_frame
				break
	say("построено королевства: %s" % str(built))
	# новые жительницы — на все кровати
	var beds: int = int(kg.call("beds"))
	var want: int = mini(beds, int(kg.call("max_workers"))) - Game.workers.size()
	if want > 0:
		kg.call("god_hire", want)
	kg.set("propose_t", -1.0)
	var orders: Array = ["wood", "wood", "herb", "herb", "stone", "stone", "fish", "farm", "brew", "brew", "shroom", "build", "guard"]
	for i in range(Game.workers.size()):
		kg.call("give_order", i, String(orders[i % orders.size()]))
	Game.chron("Работницы построили дворец, %d домов, таверну, чайный домик и мастерские." % (int(built.get("kg_house_a", 0)) + int(built.get("kg_house_b", 0)) + int(built.get("kg_house_c", 0)) + int(built.get("kg_house_elf", 0)) + int(built.get("kg_house_jp", 0))), "kingdom")
	say("работниц: %d, кроватей: %d, довольство %d%%" % [Game.workers.size(), beds, int(float(kg.call("happiness")) * 100.0)])
	await get_tree().create_timer(0.5).timeout


# ------------------------------------------------------------------ запасы

func _stock() -> void:
	say("запасы")
	Game.coins = maxi(Game.coins, 3000)
	for t in ["rod", "pickaxe", "sickle", "net", "lantern_hand"]:
		if Game.get_count(t) == 0:
			Game.add_item(t, 1)
	Game.has_rod = true
	Game.has_net = true
	# зелья — по 3 каждого, в сумку; материалы — в склад
	var cu: Node = get_tree().get_first_node_in_group("chest_ui")
	for pid in Game.known_recipes.keys():
		if cu != null and not Game.chests.is_empty():
			cu.call("deposit", String(pid), 2, Game.home_pos)
	var mats: Array = [["log", 60], ["plank_tree_a", 60], ["stone_m", 60], ["stone_s", 40], ["iron_bar", 20], ["ore_iron", 20], ["coal", 30], ["glass", 12],
		["linen", 20], ["twine", 20], ["nail", 40], ["brick", 30], ["bar_gold", 6], ["cloth_red", 6], ["flour", 20], ["wool_raw", 12], ["honey", 10], ["egg", 12]]
	for m in mats:
		if cu != null and not Game.chests.is_empty():
			var left: int = int(cu.call("deposit", String(m[0]), int(m[1]), Game.home_pos))
			if left > 0:
				Game.add_item(String(m[0]), left)
	Game.inventory_changed.emit()
	await get_tree().process_frame


# ------------------------------------------------------------------ прожить несколько дней на ускорении

func _live_days() -> void:
	say("живу %d дней на ускорении x%d" % [days, int(SPEED)])
	var pl: Node2D = main.get("player")
	pl.position = main.call("free_near", Game.home_pos + Vector2(0, 160))
	Game.minutes = 7.0 * 60.0
	Engine.time_scale = 4.0          # на глаз ускорено; время дня двигаем сами — так быстрее при 50 работницах
	var d0: int = Game.day
	var coins0: int = Game.coins
	var last: int = Game.day
	var steps: int = 0
	while Game.day < d0 + days and steps < 110 * (days + 1):
		Game.minutes += 15.0          # полночь и новый день Game обработает сам в _process
		for f in range(3):
			await get_tree().process_frame
		steps += 1
		Game.ui_open = false
		Game.busy = false
		Game.time_frozen = false
		get_tree().paused = false
		var mn: Node = get_tree().get_first_node_in_group("menu")
		if mn != null and bool(mn.get("open")) and mn.has_method("_play"):
			mn.call("_play")
		Game.hunger = 0.1
		Game.thirst = 0.1
		Game.fatigue = 0.1
		_answer_talk()
		if Game.day != last:
			last = Game.day
			say("день %d: монет %d, работниц %d, в сундуках %d вещей" % [Game.day, Game.coins, Game.workers.size(), _chest_total()])
			_daily_actions()
	Engine.time_scale = 1.0
	say("прожито %d дней, монеты %d -> %d" % [Game.day - d0, coins0, Game.coins])


var extra_chests: int = 0


## работница пришла с вопросом (обычно: сундуки полны) — ответить «построю ещё сундук» и построить
func _answer_talk() -> void:
	var v23: Node = main.get_node_or_null("V23")
	if v23 == null or not bool(v23.call("talking")):
		return
	if extra_chests < 12:
		var r: Rect2 = hs.call("plot_rect")
		var kind: String = "warehouse" if extra_chests % 3 == 0 else "chest_big"
		if _grid_place(kind, r, Vector2(70, 60), 1) > 0:
			extra_chests += 1
			say("  построила ещё: %s" % kind)
	var opts: Node = v23.get("talk_opts")
	if opts != null and opts.get_child_count() > 0:
		var b: Node = opts.get_child(0)
		if b is Button:
			(b as Button).pressed.emit()


func _chest_total() -> int:
	var n: int = 0
	for ck in Game.chests.keys():
		for e in ((Game.chests[ck] as Dictionary).get("layout", []) as Array):
			n += int((e as Dictionary).get("n", 0))
	return n


## раз в день: собрать продукты фермы, полить грядки, продать излишки караваном
func _daily_actions() -> void:
	for pl in get_tree().get_nodes_in_group("plots"):
		pl.set("watered", true)
		if int(pl.get("stage")) >= 3 and pl.has_method("refresh"):
			# урожай — в сундук, грядку — засеять снова
			var c: String = String(pl.get("crop"))
			var cu: Node = get_tree().get_first_node_in_group("chest_ui")
			if cu != null and c != "":
				cu.call("deposit", c, 3, Game.home_pos)
			pl.set("stage", 1)
			pl.call("refresh")
	var fm: Node = main.get_node_or_null("V23/Farm23")
	for e in Game.farm:
		e["fed"] = true
	if fm != null and fm.has_method("night_breed") and randf() < 0.4:
		fm.call("night_breed", true)
	Game.count_add("sold", randi_range(6, 14))
	Game.stall["fame"] = int(Game.stall.get("fame", 0)) + 3
	Game.stall["sold"] = int(Game.stall.get("sold", 0)) + randi_range(6, 14)
	Game.add_coins(randi_range(80, 160))     # лавка и караваны за день
	Game.skill_xp("trade", 20.0)


# ------------------------------------------------------------------ снимки и сохранение

func _shot(name: String, at: Vector2, zoom: float) -> void:
	var pl: Node2D = main.get("player")
	pl.position = main.call("free_near", at)
	var w: Node = main.get("world")
	if w != null:
		w.call("build_around", pl.position)
	main.set("zoom_target", zoom)
	var cam: Camera2D = main.get("cam")
	if cam != null:
		cam.zoom = Vector2(zoom, zoom)
		cam.reset_smoothing()
	await get_tree().create_timer(0.6).timeout
	_answer_talk()
	var mn0: Node = get_tree().get_first_node_in_group("menu")
	if mn0 != null and bool(mn0.get("open")):
		mn0.call("_play")
	await get_tree().create_timer(0.6).timeout
	if DisplayServer.get_name() == "headless":
		return
	var img: Image = get_viewport().get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(shots)
	img.save_png(shots.path_join(name + ".png"))
	say("снимок " + shots.path_join(name + ".png"))


func _shot_here(name: String) -> void:
	await get_tree().create_timer(1.0).timeout
	if DisplayServer.get_name() == "headless":
		return
	var img: Image = get_viewport().get_texture().get_image()
	img.save_png(shots.path_join(name + ".png"))
	say("снимок " + shots.path_join(name + ".png"))


func _finish() -> void:
	say("снимки и сохранение")
	_answer_talk()
	var mn0: Node = get_tree().get_first_node_in_group("menu")
	if mn0 != null and bool(mn0.get("open")):
		mn0.call("_play")
	get_tree().paused = false
	Game.minutes = 10.0 * 60.0
	await _shot("autoplay_yard", Game.home_pos + Vector2(0, 220), 1.5)
	var palace: Vector2 = Vector2.ZERO
	for p in (hs.get("placed") as Array):
		if String(p[0]) == "kg_palace":
			palace = p[1]
	if palace != Vector2.ZERO:
		await _shot("autoplay_palace", palace + Vector2(0, 90), 1.5)
	var sum: Vector2 = Vector2.ZERO
	var cnt: int = 0
	for p2 in (hs.get("placed") as Array):
		if String(p2[0]).begins_with("kg_"):
			sum += p2[1]
			cnt += 1
	await _shot("autoplay_kingdom", (sum / float(maxi(cnt, 1))) if cnt > 0 else Game.home_pos, 0.8)
	var h23: Node = main.get_node_or_null("House23")
	if main.has_method("enter_house"):
		await main.call("enter_house")
		await _shot_here("autoplay_house")
		if main.has_method("_set_inside"):
			main.call("_set_inside", false, preload("res://world_layout.gd").DOOR_POS + main.call("home_off") + Vector2(0, 40))
	# героиня — у крыльца, утро, сыта
	Game.god_mode = false
	Game.hunger = 0.05
	Game.thirst = 0.05
	Game.fatigue = 0.0
	Game.hp = Game.hp_max()
	Game.minutes = 8.0 * 60.0
	var pl: Node2D = main.get("player")
	pl.position = main.call("free_near", Game.home_pos + Vector2(0, 120))
	main.set("zoom_target", 3.0)
	var cam: Camera2D = main.get("cam")
	if cam != null:
		cam.zoom = Vector2(3, 3)
		cam.reset_smoothing()
	# в сумке не должно быть перегруза: лишнее — на склад
	var cu: Node = get_tree().get_first_node_in_group("chest_ui")
	if Game.overloaded() and cu != null:
		for id in Game.inventory.keys():
			if Game.overloaded():
				var sid: String = String(id)
				if Game.hotbar.has(sid) or IT.is_gear(sid):
					continue
				var n: int = Game.get_count(sid)
				if n > 0:
					var left: int = int(cu.call("deposit", sid, n, Game.home_pos))
					Game.inventory[sid] = left
		Game.inventory_changed.emit()
	Game.chron("Королевство «%s» живёт и богатеет. Добро пожаловать домой, королева!" % KNAME, "kingdom")
	await get_tree().create_timer(0.5).timeout
	var ok: bool = Saves.save_game(SLOT, false)
	say("сохранение в слот %d: %s (день %d, монет %d, работниц %d, построек %d)" % [SLOT, str(ok), Game.day, Game.coins, Game.workers.size(), (hs.get("placed") as Array).size()])
	await get_tree().create_timer(0.5).timeout
	get_tree().quit()


## Проверка: загрузить слот как игрок, посчитать, что есть, снять чистые снимки
func _check() -> void:
	if not Saves.has_meta("ap_loaded"):
		Saves.set_meta("ap_loaded", 1)
		say("загружаю слот %d" % SLOT)
		say("загрузка: %s" % str(Saves.load_game(SLOT)))
		return
	await get_tree().create_timer(2.0).timeout
	hs = get_tree().get_first_node_in_group("homestead")
	var kg: Node = main.get_node_or_null("V23/Kingdom23")
	say("ПРОВЕРКА: день %d, монет %d, королевство %s ур.%d, работниц %d, построек %d, рецептов %d, ферма %d, комнат %d, мебели %d, навыки %s" % [
		Game.day, Game.coins, str(Game.kingdom.get("name", "-")), int(Game.kingdom.get("level", 0)), Game.workers.size(),
		(hs.get("placed") as Array).size(), Game.known_recipes.size(), Game.farm.size(), Game.rooms.size(), Game.furniture.size(),
		str(Game.skill_level("herb"))])
	say("сундуков %d, вещей в них %d, довольство %d%%, god_mode %s" % [Game.chests.size(), _chest_total(), int(float(kg.call("happiness")) * 100.0), str(Game.god_mode)])
	var palace: Vector2 = Vector2.ZERO
	for p in (hs.get("placed") as Array):
		if String(p[0]) == "kg_palace":
			palace = p[1]
	await _shot("save_yard", Game.home_pos + Vector2(0, 200), 1.6)
	if palace != Vector2.ZERO:
		await _shot("save_palace", palace + Vector2(0, 120), 1.4)
	await _shot("save_overview", Game.home_pos + Vector2(0, 260), 0.75)
	get_tree().quit()

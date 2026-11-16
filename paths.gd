extends Node
## Ранний доступ: свои пути — каждая сама решает, кем быть.
## • Лавка зелий у дома: выставить товар, зазывать покупательниц, собрать выручку.
## • Союзы с королевствами: караваны (прибыль пополам с казной), королевские заказы, придворная травница, пожертвования.
## • Кузница: брусок из камня, подковы, котелки, парадное оружие и инструменты; заказы городов.
## • Фракции и секты: вступить, брать дела, расти в званиях, соперницы не уживаются.
## • Народная целительница: больным жительницам нужно своё зелье.
## • Летопись (L): титулы, звания, союзы и всё, что случилось — своя история.
## Данные — paths_db.gd, состояние — в Game (сохраняется само). В разговорах подключено из dialog_ui.gd.

const PDB = preload("res://paths_db.gd")
const NPC = preload("res://npc_db.gd")
const RDB = preload("res://recipes_db.gd")
const DB = preload("res://herbs_db.gd")
const FDB = preload("res://fish_db.gd")
const FD = preload("res://food_db.gd")
const MD = preload("res://mining_db.gd")
const IT = preload("res://items_db.gd")
const INK: Color = Color("3a2718")
const SICK_POTIONS: Array = ["heal_salve", "warm_tea", "mint_tea", "calm_tea", "sleep_tea", "vigor_tea"]

var main: Node2D
var hud: CanvasLayer
var last_hour: int = -1
var ui: CanvasLayer
var ui_root: Control
var ui_text: RichTextLabel
var ui_open: bool = false
var instant_customers: bool = false     # автотест: покупательницы платят сразу, без прогулки


func setup(m: Node2D, h: CanvasLayer) -> void:
	main = m
	hud = h
	name = "Paths"
	add_to_group("paths")
	last_hour = int(Game.hour())
	instant_customers = DisplayServer.get_name() == "headless" or OS.get_cmdline_user_args().has("--test")
	if Game.paths_day > Game.day:
		Game.paths_day = Game.day
	Game.day_changed.connect(_on_new_day)
	_build_ui()


# ================================================================== время

func abs_min() -> float:
	return float(Game.day) * 1440.0 + Game.minutes


func _process(_delta: float) -> void:
	var h: int = int(Game.hour())
	if h != last_hour:
		last_hour = h
		_hour_tick(h)


func _on_new_day() -> void:
	while Game.paths_day < Game.day:
		Game.paths_day += 1
		_daily(Game.paths_day)


func _land_name(land: String) -> String:
	return String(NPC.land(land).get("name", land))


func _daily(d: int) -> void:
	# караваны вернулись
	for i in range(Game.caravans.size() - 1, -1, -1):
		var c: Dictionary = Game.caravans[i]
		if int(c["due"]) <= d:
			Game.caravans.remove_at(i)
			var land: String = String(c["land"])
			var got: int = int(c["coins"])
			Game.add_coins(got)
			if Game.pacts.has(land):
				Game.pacts[land]["earned"] = int((Game.pacts[land] as Dictionary).get("earned", 0)) + got
			Game.rep_add(land, 2)
			Game.toast.emit("Караван из %s: +%d" % [_land_name(land), got], load("res://art/coin.png"))
	# жалованье придворной травницы
	for land2 in Game.court.keys():
		if Game.rep_tier(String(land2)) >= 3:
			Game.add_coins(15)
	# просроченные заказы
	for land3 in Game.royal.keys():
		if int((Game.royal[land3] as Dictionary)["due"]) < d:
			Game.royal.erase(land3)
			Game.rep_add(String(land3), -3)
			Game.chron("Не успела с королевским заказом для %s." % _land_name(String(land3)), "fail")
	for land4 in Game.smith_orders.keys():
		if int((Game.smith_orders[land4] as Dictionary)["due"]) < d:
			Game.smith_orders.erase(land4)
			Game.rep_add(String(land4), -2)


# ================================================================== лавка зелий

func stall_node() -> Node2D:
	return get_tree().get_first_node_in_group("stall_ea") as Node2D


func stall_count() -> int:
	var n: int = 0
	for v in (Game.stall["goods"] as Dictionary).values():
		n += int(v)
	return n


func lured() -> bool:
	return abs_min() < float(Game.stall.get("lure_until", -1.0))


## Шанс, что за час придёт покупательница
func customer_chance() -> float:
	var c: float = 0.18 + minf(0.3, float(Game.stall.get("fame", 0)) * 0.004)
	if lured():
		c += 0.5
	if Game.factions.has("guild"):
		c += 0.04 * float(int((Game.factions["guild"] as Dictionary).get("rank", 0)) + 1)
	return minf(c, 0.95)


func _hour_tick(h: int) -> void:
	if float(h) < float(PDB.STALL_HOURS_OPEN[0]) or float(h) >= float(PDB.STALL_HOURS_OPEN[1]):
		return
	var st: Node2D = stall_node()
	if st == null or stall_count() <= 0:
		return
	var tries: int = 2 if lured() else 1
	for i in range(tries):
		if randf() < customer_chance():
			send_customer(st)


func send_customer(st: Node2D) -> void:
	if instant_customers or st == null:
		sell_one()
		return
	var cu: Node2D = Node2D.new()
	cu.set_script(load("res://customer.gd"))
	var ang: float = randf_range(0.2, PI - 0.2)
	var from: Vector2 = st.global_position + Vector2(cos(ang) * 340.0, sin(ang) * 260.0)
	cu.call("setup", from, st.global_position + Vector2(randf_range(-18.0, 18.0), 30.0), Callable(self, "sell_one"), randi())
	(main.get("objects") as Node).add_child(cu)


## Продать одну вещь с прилавка. Возвращает цену (0 — нечего продавать)
func sell_one() -> int:
	var goods: Dictionary = Game.stall["goods"]
	var ids: Array = []
	for k in goods.keys():
		if int(goods[k]) > 0:
			ids.append(String(k))
	if ids.is_empty():
		return 0
	var id: String = String(ids.pick_random())
	var pr: int = maxi(1, int(round(float(PDB.price(id)) * 1.3 * (1.0 + Game.stat("sell") / 100.0))))
	goods[id] = int(goods[id]) - 1
	if int(goods[id]) <= 0:
		goods.erase(id)
	Game.stall["cash"] = int(Game.stall["cash"]) + pr
	Game.stall["fame"] = int(Game.stall.get("fame", 0)) + 1
	Game.stall["sold"] = int(Game.stall.get("sold", 0)) + 1
	Game.count_add("sold")
	var st: Node2D = stall_node()
	Sound.play("coin", -10.0, 0.08, st.global_position if st != null else null)
	var sold: int = int(Game.stall["sold"])
	if sold == 1:
		Game.chron("Первая покупательница в моей лавке! Взяла «%s»." % IT.name(id), "stall")
	if sold >= 10:
		Game.add_title("merchant")
	if sold >= 60:
		Game.add_title("merchant2")
	return pr


## Действия с карточек лавки (homestead.open_menu("stall"))
func stall_act(act: String) -> bool:
	var goods: Dictionary = Game.stall["goods"]
	match act:
		"put":
			var n: int = 0
			for id in Game.inventory.keys():
				var sid: String = String(id)
				var c: int = Game.get_count(sid)
				if c > 0 and PDB.sellable(sid) and not Game.hotbar.has(sid):
					goods[sid] = int(goods.get(sid, 0)) + c
					Game.inventory[sid] = 0
					n += c
			if n == 0:
				return false
			Game.inventory_changed.emit()
			Sound.play("pickup", -6.0)
			if not Game.counters.has("stall_open"):
				Game.counters["stall_open"] = Game.day
				Game.chron("Открыла свою лавку зелий у дома.", "stall")
			return true
		"take":
			if goods.is_empty():
				return false
			for id2 in goods.keys():
				Game.inventory[String(id2)] = Game.get_count(String(id2)) + int(goods[id2])
			goods.clear()
			Game.inventory_changed.emit()
			Sound.play("pickup", -6.0)
			return true
		"cash":
			var cash: int = int(Game.stall["cash"])
			if cash <= 0:
				return false
			Game.stall["cash"] = 0
			Game.add_coins(cash)
			return true
		"lure":
			if abs_min() < float(Game.stall.get("lure_cd", -1.0)) or stall_count() <= 0:
				return false
			Game.stall["lure_until"] = abs_min() + PDB.LURE_MIN
			Game.stall["lure_cd"] = abs_min() + PDB.LURE_CD
			get_tree().call_group("player", "react", "happy", 2.0)
			Sound.play("drum", -6.0)
			Game.count_add("lured")
			# зазывала — и первая уже идёт
			send_customer(stall_node())
			return true
	return false


# ================================================================== кузница

func _ore_count() -> int:
	var n: int = 0
	for id in Game.inventory.keys():
		if String(id).begins_with("ore_"):
			n += Game.get_count(String(id))
	return n


func _take_ore() -> bool:
	for id in Game.inventory.keys():
		if String(id).begins_with("ore_") and Game.get_count(String(id)) > 0:
			return Game.take_item(String(id))
	return false


## v26: сколько есть у героини + в сундуках базы
func _base_have(id: String) -> int:
	var cu: Node = get_tree().get_first_node_in_group("chest_ui")
	if cu == null:
		return 0
	return int((cu.call("base_totals") as Dictionary).get(id, 0))


func _base_ore() -> int:
	var cu: Node = get_tree().get_first_node_in_group("chest_ui")
	var n: int = 0
	if cu != null:
		var bt: Dictionary = cu.call("base_totals")
		for id in bt.keys():
			if String(id).begins_with("ore_"):
				n += int(bt[id])
	return n


## Перенести из сундуков базы в сумку недостающее для ковки
func _pull_for(need: Dictionary) -> void:
	var cu: Node = get_tree().get_first_node_in_group("chest_ui")
	if cu == null:
		return
	for k in need.keys():
		var ks: String = String(k)
		if ks == "ore":
			var miss: int = int(need[k]) - _ore_count()
			if miss > 0:
				var bt: Dictionary = cu.call("base_totals")
				for id in bt.keys():
					if miss > 0 and String(id).begins_with("ore_"):
						var g: int = int(cu.call("base_take", String(id), mini(miss, int(bt[id]))))
						Game.add_item(String(id), g)
						miss -= g
		else:
			var miss2: int = int(need[k]) - Game.get_count(ks)
			if miss2 > 0:
				var g2: int = int(cu.call("base_take", ks, miss2))
				if g2 > 0:
					Game.add_item(ks, g2)


func can_forge(id: String) -> bool:
	var need: Dictionary = (PDB.FORGE[id] as Array)[0]
	for k in need.keys():
		var have: int = (_ore_count() + _base_ore()) if String(k) == "ore" else Game.get_count(String(k)) + _base_have(String(k))
		if have < int(need[k]):
			return false
	return true


func forge(id: String) -> bool:
	if not PDB.FORGE.has(id) or not can_forge(id):
		return false
	var rec: Array = PDB.FORGE[id]
	var need: Dictionary = rec[0]
	_pull_for(need)
	for k in need.keys():
		for i in range(int(need[k])):
			if String(k) == "ore":
				_take_ore()
			else:
				Game.take_item(String(k))
	Game.add_item(id, int(rec[1]))
	Sound.play("anvil", -4.0)
	if id != "iron_bar":
		Game.count_add("forged", int(rec[1]))
	var f: int = int(Game.counters.get("forged", 0))
	if not Game.counters.has("forge_first") and id != "iron_bar":
		Game.counters["forge_first"] = Game.day
		Game.chron("Выковала первую вещь: %s." % IT.name(id), "forge")
	if f >= 10:
		Game.add_title("smith")
	return true


# ================================================================== разговоры

func _night() -> bool:
	var h: float = Game.hour()
	return h >= 20.0 or h < 5.0


## Какой фракции принадлежит жительница ("" — никакой)
func faction_of(npc: Node) -> String:
	var nm: String = String(npc.get("npc_name"))
	var land: String = String(npc.get("land"))
	var role: String = String(npc.get("role"))
	if nm == "":
		return ""
	var hv: int = absi(hash(nm + "#fac"))
	var cands: Array = []
	for fid in PDB.FACTION_ORDER:
		var f: Dictionary = PDB.FACTIONS[fid]
		if String(f["land"]) != "" and String(f["land"]) != land:
			continue
		if not (f["roles"] as Array).has(role):
			continue
		if bool(f["night"]) and not _night():
			continue
		cands.append(String(fid))
	if cands.is_empty():
		return ""
	var pick: String = String(cands[hv % cands.size()])
	if String((PDB.FACTIONS[pick] as Dictionary)["land"]) != "" and hv % 5 >= 3:
		return ""        # не каждая в этих землях — из тайного общества
	return pick


func is_sick(npc: Node) -> bool:
	var nm: String = String(npc.get("npc_name"))
	if nm == "" or String(npc.get("role")) != "житель":
		return false
	if int(Game.healed_today.get(nm, -1)) == Game.day:
		return false
	return absi(hash(nm + ":" + str(Game.day))) % 6 == 0


func sick_need(npc: Node) -> String:
	return String(SICK_POTIONS[absi(hash(String(npc.get("npc_name")) + "x" + str(Game.day))) % SICK_POTIONS.size()])


func handles(act: String) -> bool:
	return act.begins_with("pk_") or act.begins_with("sm_") or act.begins_with("fc_") or act.begins_with("hl_")


## Новые пункты в разговоре (перед «Пока!»)
func extra_options(d: Node, opts: Array) -> Array:
	var npc: Node = d.get("npc")
	if npc == null or npc.has_meta("jailer") or npc.has_meta("shelter"):
		return opts
	var land: String = String(npc.get("land"))
	var role: String = String(npc.get("role"))
	var nm: String = String(npc.get("npc_name"))
	if nm == "" and role != "лидер":
		return opts
	var extra: Array = []
	if role == "лидер" and land != "":
		if not Game.pacts.has(land):
			extra.append(["Предложить торговый союз", "pk_offer"])
		else:
			extra.append(["Отправить товары с караваном", "pk_caravan"])
			extra.append(["Сдать королевский заказ" if (Game.royal.has(land) and _can_deliver(Game.royal[land])) else "Есть ли королевский заказ?", "pk_royal"])
			if not Game.court.has(land) and Game.rep_tier(land) >= 4:
				extra.append(["Стать придворной травницей", "pk_court"])
		extra.append(["Пожертвовать в казну (50 монет)", "pk_donate"])
	if not Game.SOLO and role in ["кузнец", "стража", "заместитель"] and PDB.LAND_WEAPONS.has(land):
		if Game.smith_orders.has(land) and _can_deliver(Game.smith_orders[land]):
			extra.append(["Сдать оружие для города", "sm_ask"])
		else:
			extra.append(["Городу нужно оружие?", "sm_ask"])
		if role == "кузнец" and _smith_goods() > 0:
			extra.append(["Продать кованое", "sm_sell"])
	var fid: String = faction_of(npc)
	if fid != "":
		var fd: Dictionary = PDB.FACTIONS[fid]
		if Game.factions.has(fid):
			extra.append(["Дело для: %s" % String(fd["name"]), "fc_task:" + fid])
			extra.append(["Уйти из: %s" % String(fd["name"]), "fc_leave:" + fid])
		elif Game.counters.has("known_" + fid):
			extra.append(["Хочу вступить: %s" % String(fd["name"]), "fc_join:" + fid])
		else:
			extra.append(["Что это за знак у тебя?", "fc_info:" + fid])
	if is_sick(npc):
		extra.append(["Ты бледная... Тебе нездоровится?", "hl_ask"])
	if extra.is_empty():
		return opts
	var tail: Array = opts.pop_back() if not opts.is_empty() else ["Пока!", "bye"]
	opts.append_array(extra)
	opts.append(tail)
	return opts


func handle(d: Node, act: String) -> void:
	var npc: Node = d.get("npc")
	var land: String = String(npc.get("land"))
	if act.begins_with("pk_"):
		_pact_act(d, npc, land, act)
	elif act.begins_with("sm_"):
		_smith_act(d, npc, land, act)
	elif act.begins_with("fc_"):
		var p: int = act.find(":")
		_faction_act(d, npc, land, act.substr(0, p), act.substr(p + 1))
	elif act.begins_with("hl_"):
		_heal_act(d, npc, land, act)


func _say(d: Node, text: String) -> void:
	d.call("_say", text)


# ------------------------------------------------------------------ требования: «любое зелье», «любые травы» и т.п.

func _matches(kind: String, id: String) -> bool:
	match kind:
		"potion_any":
			return RDB.is_product(id) and id != "murky"
		"herb_any":
			return DB.DATA.has(id)
		"fish_any":
			return FDB.is_fish(id)
		"food_any":
			return FD.is_food(id)
		"sapling_any":
			return id.begins_with("sapling:")
		"leaf_any":
			return id.begins_with("leaf_")
		"dry_any":
			return id.begins_with("dry:")
		"ore":
			return id.begins_with("ore_")
	return id == kind


func have_of(kind: String) -> int:
	match kind:
		"coins":
			return Game.coins
		"researched":
			return Game.researched.size()
		"sold":
			return int(Game.counters.get("sold", 0))
		"forged":
			return int(Game.counters.get("forged", 0))
	var n: int = 0
	for id in Game.inventory.keys():
		if _matches(kind, String(id)):
			n += Game.get_count(String(id))
	return n


func take_of(kind: String, n: int) -> void:
	if kind == "coins":
		Game.coins -= n
		Game.inventory_changed.emit()
		return
	if kind in ["researched", "sold", "forged"]:
		return
	var left: int = n
	for id in Game.inventory.keys():
		if left <= 0:
			break
		var sid: String = String(id)
		if _matches(kind, sid):
			var c: int = mini(left, Game.get_count(sid))
			if c > 0:
				Game.take_item(sid, c)
				left -= c


func req_text(kind: String, n: int) -> String:
	match kind:
		"potion_any":
			return "%d любых зелья" % n if n < 5 else "%d любых зелий" % n
		"herb_any":
			return "%d любых трав" % n
		"fish_any":
			return "рыбка" if n == 1 else "%d рыбки" % n
		"food_any":
			return "%d угощения" % n
		"sapling_any":
			return "%d саженца" % n
		"leaf_any":
			return "%d листьев" % n
		"dry_any":
			return "%d пучка сушёных трав" % n
		"ore":
			return "волшебный камень" if n == 1 else "%d волшебных камня" % n
		"coins":
			return "%d монет" % n
		"sold":
			return "продать в лавке ещё %d вещей" % n
		"forged":
			return "выковать ещё %d вещей" % n
		"researched":
			return "изучить %d трав" % n
	return "%d × %s" % [n, IT.name(kind)]


## Заказ {item, n} — хватает ли в сумке
func _can_deliver(o: Dictionary) -> bool:
	return have_of(String(o["item"])) >= int(o["n"])


func _smith_goods() -> int:
	var n: int = 0
	for id in Game.inventory.keys():
		if PDB.is_smith(String(id)) and String(id) != "iron_bar":
			n += Game.get_count(String(id))
	return n


# ------------------------------------------------------------------ королевства

func _pact_act(d: Node, npc: Node, land: String, act: String) -> void:
	var lname: String = _land_name(land)
	var tier: int = Game.rep_tier(land)
	match act:
		"pk_offer":
			if tier < 3:
				_say(d, "Союз — дело доверия. Сначала стань другом %s: помогай людям, торгуй честно." % lname)
			elif Game.coins < 100:
				_say(d, "Для союза нужен вклад в казну — сто монет. Пока у тебя %d." % Game.coins)
			else:
				Game.coins -= 100
				Game.inventory_changed.emit()
				Game.pacts[land] = {"since": Game.day, "earned": 0}
				Game.rep_add(land, 5)
				Game.chron("Заключила торговый союз с землёй %s." % lname, "pact")
				Game.add_title("partner")
				Sound.play("ui_select")
				_say(d, "По рукам! Отныне твои товары едут с нашими караванами, а прибыль мы делим пополам. И заглядывай за королевскими заказами.")
		"pk_caravan":
			var val: int = 0
			var cnt: int = 0
			for id in Game.inventory.keys():
				var sid: String = String(id)
				var c: int = Game.get_count(sid)
				if c > 0 and PDB.sellable(sid) and not Game.hotbar.has(sid):
					val += PDB.price(sid) * c
					cnt += c
					Game.inventory[sid] = 0
			if cnt == 0:
				_say(d, "Караван готов, а везти нечего. Принеси зелья, кованое или угощения.")
			else:
				Game.inventory_changed.emit()
				var share: int = int(round(float(val) * 1.7 * 0.5 * (1.0 + 0.05 * float(tier))))
				Game.caravans.append({"land": land, "due": Game.day + 2, "coins": share, "n": cnt})
				Game.count_add("caravans")
				if int(Game.counters["caravans"]) == 1:
					Game.chron("Отправила первый караван с товарами из %s." % lname, "pact")
				Sound.play("neigh", -6.0)
				_say(d, "Погрузили %d вещей. Продадим в дальних городах втридорога. Твоя половина — около %d монет — будет через два дня." % [cnt, share])
		"pk_royal":
			if Game.royal.has(land):
				var o: Dictionary = Game.royal[land]
				if _can_deliver(o):
					take_of(String(o["item"]), int(o["n"]))
					Game.royal.erase(land)
					Game.add_coins(int(o["reward"]))
					Game.rep_add(land, 8)
					Game.count_add("royal")
					Game.chron("Выполнила королевский заказ для %s: %s." % [lname, req_text(String(o["item"]), int(o["n"]))], "pact")
					_say(d, "Ровно то, что нужно казне! Держи %d монет. Двор тебя не забудет." % int(o["reward"]))
				else:
					_say(d, "Казна ждёт: %s до дня %d. Сейчас у тебя %d." % [req_text(String(o["item"]), int(o["n"])), int(o["due"]), have_of(String(o["item"]))])
			else:
				var o2: Dictionary = _new_royal(land)
				Game.royal[land] = o2
				_say(d, "Есть! Двору нужно: %s до дня %d. Награда — %d монет." % [req_text(String(o2["item"]), int(o2["n"])), int(o2["due"]), int(o2["reward"])])
		"pk_court":
			if tier < 4:
				_say(d, "Придворной травницей становится только та, кого земля уважает.")
			else:
				Game.court[land] = Game.day
				Game.add_title("court")
				Game.chron("Стала придворной травницей в %s. Жалованье — 15 монет в день." % lname, "pact")
				Sound.play("ui_select")
				_say(d, "Решено! Ты — наша придворная травница. Каждое утро казна будет платить тебе жалованье.")
		"pk_donate":
			if Game.coins < 50:
				_say(d, "Спасибо за доброе сердце, но у тебя самой мало монет.")
			else:
				Game.coins -= 50
				Game.inventory_changed.emit()
				Game.count_add("donated", 50)
				Game.rep_add(land, 6)
				if int(Game.counters["donated"]) == 50:
					Game.chron("Впервые пожертвовала в казну %s." % lname, "gift")
				if int(Game.counters["donated"]) >= 300:
					Game.add_title("patron")
				_say(d, "Казна благодарит тебя! Об этой щедрости узнает весь город.")
	d.call("_talk_menu")


func _new_royal(land: String) -> Dictionary:
	var pool: Array = []
	for k in Game.known_recipes.keys():
		if String(k) != "murky":
			pool.append(String(k))
	for w in ([] if Game.SOLO else PDB.LAND_WEAPONS.get(land, [])):
		pool.append(String(w))
	if pool.is_empty():
		pool = ["heal_salve", "calm_tea", "mint_tea"]
	var item: String = String(pool.pick_random())
	var n: int = 1 if item == "star_blade" else randi_range(3, 5)
	return {"item": item, "n": n, "due": Game.day + 5, "reward": PDB.price(item) * n * 2 + 30}


# ------------------------------------------------------------------ кузнецы и стража

func _smith_act(d: Node, npc: Node, land: String, act: String) -> void:
	match act:
		"sm_ask":
			if Game.smith_orders.has(land):
				var o: Dictionary = Game.smith_orders[land]
				if _can_deliver(o):
					take_of(String(o["item"]), int(o["n"]))
					Game.smith_orders.erase(land)
					Game.add_coins(int(o["reward"]))
					Game.rep_add(land, 6)
					Game.count_add("weapon_orders")
					var wo: int = int(Game.counters["weapon_orders"])
					var towns: Dictionary = Game.counters.get("weapon_towns", {})
					towns[land] = true
					Game.counters["weapon_towns"] = towns
					Game.chron("Выковала для %s: %s." % [_land_name(land), req_text(String(o["item"]), int(o["n"]))], "forge")
					if towns.size() >= 5 or wo >= 12:
						Game.add_title("smith2")
					_say(d, "Отличная работа! Стража наденет это на парад. Вот %d монет." % int(o["reward"]))
				else:
					_say(d, "Ждём: %s до дня %d. Кузницу можно поставить у себя во дворе — с верстака." % [req_text(String(o["item"]), int(o["n"])), int(o["due"])])
			else:
				var pool: Array = PDB.LAND_WEAPONS.get(land, ["horseshoe"])
				var item: String = String(pool.pick_random())
				var n: int = 1 if item == "star_blade" else randi_range(2, 4)
				var o2: Dictionary = {"item": item, "n": n, "due": Game.day + 6, "reward": int(round(float(PDB.price(item) * n) * 1.5))}
				Game.smith_orders[land] = o2
				_say(d, "Ещё как! Для парадов и турниров нужно: %s до дня %d. Заплатим %d монет." % [req_text(item, n), int(o2["due"]), int(o2["reward"])])
		"sm_sell":
			var got: int = 0
			var k: float = [0.6, 0.8, 1.0, 1.1, 1.2, 1.3][Game.rep_tier(land)] * (1.0 + Game.stat("sell") / 100.0)
			for id in Game.inventory.keys():
				var sid: String = String(id)
				if PDB.is_smith(sid) and sid != "iron_bar" and Game.get_count(sid) > 0:
					got += maxi(1, int(round(float(PDB.price(sid)) * k))) * Game.get_count(sid)
					Game.count_add("sold_smith", Game.get_count(sid))
					Game.inventory[sid] = 0
			Game.inventory_changed.emit()
			if got > 0:
				Game.add_coins(got)
				Game.rep_add(land, 1, true)
				_say(d, "Крепкая работа! Беру всё за %d монет." % got)
	d.call("_talk_menu")


# ------------------------------------------------------------------ фракции

func _faction_act(d: Node, npc: Node, land: String, act: String, fid: String) -> void:
	var fd: Dictionary = PDB.faction(fid)
	if fd.is_empty():
		d.call("_talk_menu")
		return
	var fname: String = String(fd["name"])
	var rival: String = String(fd["rival"])
	match act:
		"fc_info":
			Game.counters["known_" + fid] = Game.day
			var t: String = "Это знак: %s — %s. %s Чтобы вступить, нужно: %s." % [fname, String(fd["kind"]), String(fd["about"]), String(fd["join_text"])]
			if rival != "" and Game.factions.has(rival):
				t += " Только ты из «%s»... С ними нам не по пути." % String(PDB.FACTIONS[rival]["name"])
			_say(d, t)
		"fc_join":
			var req: Dictionary = fd["join"]
			var kind: String = String(req.keys()[0])
			var n: int = int(req[kind])
			if rival != "" and Game.factions.has(rival):
				_say(d, "Ты из «%s». Сначала уйди от них — двум господам не служат." % String(PDB.FACTIONS[rival]["name"]))
			elif have_of(kind) < n:
				_say(d, "Чтобы вступить, нужно: %s. Приходи, когда будет." % String(fd["join_text"]))
			else:
				take_of(kind, n)
				Game.factions[fid] = {"favor": 0, "rank": 0, "task": {}, "since": Game.day}
				Game.chron("Вступила: %s (%s). Звание — %s." % [fname, String(fd["kind"]), String((fd["ranks"] as Array)[0])], "faction")
				Game.toast.emit("✦ %s" % fname, null)
				Sound.play("magic", -4.0)
				npc.call("react", "happy", 2.0)
				_say(d, "Добро пожаловать! Теперь ты — %s. Спрашивай у наших о деле, когда захочешь помочь." % String((fd["ranks"] as Array)[0]).to_lower())
		"fc_task":
			var fr: Dictionary = Game.factions[fid]
			var task: Dictionary = fr.get("task", {})
			if task.is_empty():
				var pick: Array = (fd["tasks"] as Array).pick_random()
				task = {"item": String(pick[0]), "n": int(pick[1])}
				if String(pick[0]) in ["sold", "forged"]:
					task["base"] = have_of(String(pick[0]))
				fr["task"] = task
				_say(d, "Есть дело: %s. Принеси любому из наших." % req_text(String(task["item"]), int(task["n"])))
			else:
				var item: String = String(task["item"])
				var need: int = int(task["n"])
				var have: int = have_of(item) - int(task.get("base", 0))
				if have >= need:
					if not task.has("base"):
						take_of(item, need)
					fr["task"] = {}
					var old_rank: int = int(fr["rank"])
					fr["favor"] = int(fr["favor"]) + 8 + old_rank * 2
					fr["rank"] = PDB.rank_of_favor(int(fr["favor"]))
					var pay: int = 10 + 5 * old_rank
					Game.add_coins(pay)
					if String(fd["land"]) != "":
						Game.rep_add(String(fd["land"]), 3)
					Game.count_add("faction_tasks")
					var msg: String = "Спасибо, сестра! Вот %d монет." % pay
					if int(fr["rank"]) > old_rank:
						var rn: String = String((fd["ranks"] as Array)[int(fr["rank"])])
						msg += " И новое звание: %s!" % rn
						Game.chron("%s: получила звание «%s»." % [fname, rn], "faction")
						Sound.play("ui_select")
						if int(fr["rank"]) >= 4:
							Game.add_title("faction_head")
							Game.chron("Возглавила: %s." % fname, "faction")
					_say(d, msg)
				else:
					_say(d, "Дело ещё ждёт: %s (сейчас %d)." % [req_text(item, need), maxi(0, have)])
		"fc_leave":
			Game.factions.erase(fid)
			Game.counters.erase("known_" + fid)
			if String(fd["land"]) != "":
				Game.rep_add(String(fd["land"]), -5)
			Game.chron("Ушла из: %s." % fname, "faction")
			_say(d, "Что ж... Дверь закрыта. Но знак мы помним.")
	d.call("_talk_menu")


# ------------------------------------------------------------------ лечение

func _heal_act(d: Node, npc: Node, land: String, act: String) -> void:
	var need: String = sick_need(npc)
	match act:
		"hl_ask":
			_say(d, "Ох... совсем расклеилась. %s Мне бы «%s»." % [String((RDB.PRODUCTS[need] as Dictionary)["use"]), RDB.name(need)])
			if Game.get_count(need) > 0:
				d.call("_set_options", [["Дать: %s" % RDB.name(need), "hl_give"], ["Прости, нечем помочь", "back"]])
				return
		"hl_give":
			if Game.take_item(need):
				var nm: String = String(npc.get("npc_name"))
				Game.healed_today[nm] = Game.day
				var pay: int = 18 + RDB.rarity(need) * 10
				Game.add_coins(pay)
				Game.rep_add(land, 4)
				Game.count_add("healed")
				npc.call("react", "happy", 2.5)
				if int(Game.counters["healed"]) == 1:
					Game.chron("Вылечила жительницу: %s дала «%s»." % [nm, RDB.name(need)], "heal")
				if int(Game.counters["healed"]) >= 5:
					Game.add_title("healer")
				_say(d, "Уже легче! Ты настоящая целительница. Возьми %d монет, не спорь." % pay)
	d.call("_talk_menu")


# ================================================================== летопись (L)

func _build_ui() -> void:
	ui = CanvasLayer.new()
	ui.layer = 30
	add_child(ui)
	ui_root = Control.new()
	ui_root.position = Vector2(360, 90)
	ui_root.visible = false
	ui.add_child(ui_root)
	hud.call("panel", ui_root, Vector2.ZERO, Vector2(1200, 900))
	var tl: Label = Label.new()
	tl.text = "Летопись"
	tl.add_theme_font_override("font", hud.get("font_title"))
	tl.add_theme_font_size_override("font_size", 60)
	tl.add_theme_color_override("font_color", INK)
	tl.position = Vector2(0, 20)
	tl.size = Vector2(1200, 80)
	tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ui_root.add_child(tl)
	ui_text = RichTextLabel.new()
	ui_text.bbcode_enabled = true
	ui_text.position = Vector2(70, 110)
	ui_text.size = Vector2(1060, 740)
	ui_text.add_theme_font_override("normal_font", hud.get("font_body"))
	ui_text.add_theme_font_override("bold_font", hud.get("font_bold"))
	ui_text.add_theme_font_size_override("normal_font_size", 25)
	ui_text.add_theme_font_size_override("bold_font_size", 27)
	ui_text.add_theme_color_override("default_color", INK)
	ui_root.add_child(ui_text)


func chronicle_text() -> String:
	var out: Array = []
	out.append("[b]День %d.[/b] Монет: %d." % [Game.day, Game.coins])
	if not Game.titles.is_empty():
		var tn: Array = []
		for t in Game.titles:
			tn.append(String(PDB.TITLES.get(String(t), String(t))))
		out.append("[b]Титулы:[/b] " + ", ".join(tn) + ".")
	if not Game.factions.is_empty():
		out.append("[b]Фракции:[/b]")
		for fid in Game.factions.keys():
			var fd: Dictionary = PDB.faction(String(fid))
			var fr: Dictionary = Game.factions[fid]
			var task: Dictionary = fr.get("task", {})
			var ts: String = (" — дело: " + req_text(String(task["item"]), int(task["n"]))) if not task.is_empty() else ""
			out.append("   %s — %s (доверие %d)%s" % [String(fd["name"]), String((fd["ranks"] as Array)[int(fr["rank"])]), int(fr["favor"]), ts])
	if not Game.pacts.is_empty():
		var pn: Array = []
		for land in Game.pacts.keys():
			pn.append(_land_name(String(land)) + (" (придворная)" if Game.court.has(land) else ""))
		out.append("[b]Союзы:[/b] " + ", ".join(pn) + ".")
	var orders: Array = []
	for land2 in Game.royal.keys():
		var o: Dictionary = Game.royal[land2]
		orders.append("   казна %s: %s до дня %d" % [_land_name(String(land2)), req_text(String(o["item"]), int(o["n"])), int(o["due"])])
	for land3 in Game.smith_orders.keys():
		var o2: Dictionary = Game.smith_orders[land3]
		orders.append("   стража %s: %s до дня %d" % [_land_name(String(land3)), req_text(String(o2["item"]), int(o2["n"])), int(o2["due"])])
	for c in Game.caravans:
		orders.append("   караван из %s вернётся в день %d (~%d монет)" % [_land_name(String(c["land"])), int(c["due"]), int(c["coins"])])
	if not orders.is_empty():
		out.append("[b]Заказы и караваны:[/b]")
		out.append_array(orders)
	if Game.counters.has("stall_open"):
		out.append("[b]Лавка:[/b] продано %d, слава %d, на прилавке %d, в кассе %d." % [int(Game.stall.get("sold", 0)), int(Game.stall.get("fame", 0)), stall_count(), int(Game.stall.get("cash", 0))])
	if int(Game.counters.get("forged", 0)) > 0:
		out.append("[b]Кузница:[/b] выковано %d." % int(Game.counters["forged"]))
	if int(Game.counters.get("healed", 0)) > 0:
		out.append("[b]Вылечено:[/b] %d." % int(Game.counters["healed"]))
	out.append("")
	out.append("[b]История[/b]")
	if Game.chronicle.is_empty():
		out.append("   Страницы пока пусты. Твоя история только начинается.")
	var start: int = maxi(0, Game.chronicle.size() - 40)
	for i in range(Game.chronicle.size() - 1, start - 1, -1):
		var e: Dictionary = Game.chronicle[i]
		out.append("   День %d. %s" % [int(e["day"]), String(e["text"])])
	return "\n".join(out)


func toggle_ui() -> void:
	if ui_open:
		ui_open = false
		ui_root.visible = false
		Game.ui_open = false
		Sound.play("page", -8.0)
	elif not Game.ui_open and not Game.busy:
		ui_open = true
		ui_text.text = chronicle_text()
		ui_root.visible = true
		Game.ui_open = true
		Sound.play("page", -6.0)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var k: Key = (event as InputEventKey).physical_keycode
		if KB.is_key("chronicle", k) or (k == KEY_ESCAPE and ui_open):
			toggle_ui()
			get_viewport().set_input_as_handled()

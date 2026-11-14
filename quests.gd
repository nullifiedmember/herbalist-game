extends Node
## Задания жителей (v18): найти кошку, принести травы / грибы / камни / руду / еду / зелье / насекомых,
## передать письмо. За них платят монетами, вещами и уважением земли; лидеры дают особые награды.
## Предложение на день у каждой жительницы своё и не меняется (считается от имени и дня).

const WD = preload("res://world_data.gd")
const DB = preload("res://herbs_db.gd")
const W = preload("res://wild_db.gd")
const RDB = preload("res://recipes_db.gd")
const FD = preload("res://food_db.gd")
const INS = preload("res://insects_db.gd")
const MD = preload("res://mining_db.gd")
const IT = preload("res://items_db.gd")

const LAND_BIOME: Dictionary = {"cats": 9, "spider": 2, "gothic": 3, "knights": 4, "elves": 5, "mages": 6, "orcs": 7, "goblins": 7, "dwarves": 8, "japan": 17}
const CAT_NAMES: Array = ["Пуся", "Мурка", "Рыжик", "Снежок", "Бусинка", "Тучка", "Пирожок", "Лапуша", "Дымка", "Ириска", "Клубочек", "Шуршик"]
const CAT_SKINS: Array = ["ginger", "white", "gray", "calico"]
const SIDES: Array = ["востоку", "юго-востоку", "югу", "юго-западу", "западу", "северо-западу", "северу", "северо-востоку"]

var main: Node2D
var active: Array = []             # Dictionary: задания в работе
var done_count: int = 0
var cooldown: Dictionary = {}      # имя жительницы -> до какого дня не даёт новых
var next_id: int = 1
var cats: Dictionary = {}          # id задания -> узел кошки


func setup(m: Node2D) -> void:
	main = m
	add_to_group("quests18")


# ------------------------------------------------------------------ предложение

func has_active_from(nm: String) -> bool:
	for q in active:
		if String(q["giver"]) == nm:
			return true
	return false


func active_from(nm: String) -> Dictionary:
	for q in active:
		if String(q["giver"]) == nm:
			return q
	return {}


func _weights(land: String, role: String) -> Array:
	if role == "лидер":
		return [["ore", 3], ["potion", 2], ["herbs", 1], ["cat", 1], ["star", 1]]
	var w: Array = [["herbs", 3], ["shrooms", 2], ["cat", 2], ["stone", 1], ["food", 1], ["bugs", 1], ["letter", 2], ["potion", 1]]
	if land in ["dwarves", "orcs", "knights", "goblins"]:
		w.append(["stone", 2])
		w.append(["ore", 1])
	if land in ["mages", "gothic"]:
		w.append(["ore", 1])
		w.append(["potion", 1])
	return w


## Что предлагает жительница сегодня (пусто — ничего). Не меняет состояние.
func offer_for(npc: Node) -> Dictionary:
	var nm: String = String(npc.get("npc_name"))
	var land: String = String(npc.get("land"))
	var role: String = String(npc.get("role"))
	if nm == "" or land == "" or role == "стража" or has_active_from(nm):
		return {}
	# v24: задания дают только торговки (хозяйки лавок, пекарен, таверн, кузнецы)
	if not (role in ["торговец", "кузнец", "пекарь"] or npc.has_meta("goods")):
		return {}
	if int(cooldown.get(nm, 0)) > Game.day:
		return {}
	var r: RandomNumberGenerator = RandomNumberGenerator.new()
	r.seed = hash(nm) * 31 + Game.day * 7919 + hash(land)
	if r.randf() > 0.85:
		return {}
	var bag: Array = []
	for w in _weights(land, role):
		for i in range(int(w[1])):
			bag.append(String(w[0]))
	var type: String = String(bag[r.randi_range(0, bag.size() - 1)])
	var q: Dictionary = _build(type, nm, land, role, String(npc.get("tex_name")), r)
	if q.is_empty():
		q = _build("herbs", nm, land, role, String(npc.get("tex_name")), r)
	return q


## Травы биома, которые растут не слишком редко: [id, ...]
func _common_herbs(biome: int) -> Array:
	var common: Array = []
	var all: Array = []
	for o in DB.wild_for(biome):
		all.append(String(o[0]))
		if float(o[1]) >= 0.5:
			common.append(String(o[0]))
	return common if not common.is_empty() else all


func _pick(arr: Array, r: RandomNumberGenerator) -> Variant:
	return arr[r.randi_range(0, arr.size() - 1)]


func _build(type: String, nm: String, land: String, role: String, tex: String, r: RandomNumberGenerator) -> Dictionary:
	var biome: int = int(LAND_BIOME.get(land, 1))
	var q: Dictionary = {"type": type, "giver": nm, "tex": tex, "land": land, "role": role, "need": {}, "found": false, "target": "", "delivered": false}
	var coins: int = 0
	var rep: int = 3
	match type:
		"herbs":
			var opts: Array = _common_herbs(biome)
			if opts.is_empty():
				opts = _common_herbs(1)
			if opts.is_empty():
				return {}
			var id: String = String(_pick(opts, r))
			var n: int = r.randi_range(3, 6)
			q["need"] = {id: n}
			coins = int(DB.price(id) * n * 1.6) + r.randi_range(6, 12)
			q["title"] = "Травы: %s" % DB.short(id)
			q["text"] = "У меня закончилась трава «%s». Принеси %d шт. — я заплачу." % [DB.short(id), n]
		"shrooms":
			var so: Array = W.shrooms_for(biome)
			if so.is_empty():
				so = W.shrooms_for(1)
			if so.is_empty():
				return {}
			var sid: String = String(_pick(so, r))
			var sn: int = r.randi_range(3, 5)
			q["need"] = {sid: sn}
			coins = int(int((W.SHROOMS[sid] as Dictionary)["price"]) * sn * 1.6) + r.randi_range(5, 10)
			q["title"] = "Грибы: %s" % W.shroom_name(sid)
			q["text"] = "Хочу грибного супа! Найди %d шт. гриба «%s» — награжу." % [sn, W.shroom_name(sid)]
		"cat":
			var cname: String = String(_pick(CAT_NAMES, r))
			var skin: String = String(_pick(CAT_SKINS, r))
			var c0: Vector2 = WD.TOWN_C.get(land, Vector2.ZERO)
			var ang: float = r.randf() * TAU
			var dist: float = r.randf_range(1300.0, 2600.0)
			var pos: Vector2 = (c0 + Vector2(cos(ang), sin(ang)) * dist).round()
			pos.x = clampf(pos.x, WD.ORIGIN.x + 400.0, WD.ORIGIN.x + WD.SIZE.x - 400.0)
			pos.y = clampf(pos.y, WD.ORIGIN.y + 400.0, WD.ORIGIN.y + WD.SIZE.y - 1900.0)
			q["need"] = {"cat": 1}
			q["cat_name"] = cname
			q["cat_skin"] = skin
			q["cat_pos"] = pos
			coins = r.randi_range(25, 45)
			rep = 4
			q["title"] = "Пропала кошка %s" % cname
			q["text"] = "Моя кошка %s убежала в лес и не вернулась! Найди её и принеси домой. Искать — %s." % [cname, where_text(land, pos)]
		"stone":
			if r.randf() < 0.5:
				q["need"] = {"stone_m": r.randi_range(2, 4)}
			else:
				q["need"] = {"stone_s": r.randi_range(5, 8)}
			var sk: String = String((q["need"] as Dictionary).keys()[0])
			coins = int(MD.price(sk) * int((q["need"] as Dictionary)[sk]) * 2.2) + r.randi_range(8, 14)
			q["title"] = "Камни для стройки"
			q["text"] = "Строю ограду, не хватает камней. Принеси: %s ×%d." % [IT.name(sk), int((q["need"] as Dictionary)[sk])]
		"ore":
			var oid: String = MD.pick_ore(biome, r)
			if oid == "":
				oid = String(_pick(MD.ORE_ORDER, r))
			var on: int = r.randi_range(1, 2)
			q["need"] = {"ore_" + oid: on}
			coins = int(MD.price("ore_" + oid) * on * 1.9)
			rep = 5
			q["title"] = "Руда: %s" % IT.name("ore_" + oid)
			q["text"] = "Мне нужна руда — %s, %d шт. Добывают киркой в диких краях. Заплачу щедро." % [IT.name("ore_" + oid), on]
		"star":
			q["need"] = {"ore_star": 1}
			coins = int(MD.price("ore_star") * 2.4)
			rep = 8
			q["title"] = "Звёздный осколок"
			q["text"] = "Говорят, в диких краях лежат звёздные осколки. Принеси один — это важно для нашей земли."
		"food":
			var keys: Array = FD.DATA.keys()
			var fk: String = String(_pick(keys, r))
			var fnn: int = r.randi_range(1, 2)
			q["need"] = {"food_" + fk: fnn}
			coins = int(FD.price(fk) * fnn * 2.2) + r.randi_range(5, 10)
			q["title"] = "Угощение: %s" % FD.name("food_" + fk)
			q["text"] = "Так хочется вкусного! Принеси «%s» (%d шт.) — угощу монетами." % [FD.name("food_" + fk), fnn]
		"potion":
			var pk: Array = RDB.PRODUCTS.keys()
			var pid: String = String(_pick(pk, r))
			while pid == "murky":
				pid = String(_pick(pk, r))
			q["need"] = {pid: 1}
			coins = r.randi_range(30, 60) if role != "лидер" else r.randi_range(90, 160)
			q["title"] = "Зелье: %s" % RDB.name(pid)
			q["text"] = "Мне нужно зелье «%s». Сваришь — отблагодарю." % RDB.name(pid)
		"bugs":
			var bk: Array = INS.DATA.keys()
			var bid: String = String(_pick(bk, r))
			var bn: int = r.randi_range(2, 3)
			q["need"] = {"bug_" + bid: bn}
			coins = r.randi_range(14, 26)
			q["title"] = "Насекомые"
			q["text"] = "Нужны насекомые: %s ×%d. Поймай сачком и принеси." % [IT.name("bug_" + bid), bn]
		"letter":
			var tgt: Node = _random_neighbor(nm, land, r)
			if tgt == null:
				return {}
			q["target"] = String(tgt.get("npc_name"))
			coins = r.randi_range(14, 24)
			q["title"] = "Письмо для %s" % String(tgt.get("npc_name"))
			q["text"] = "Передай, пожалуйста, это письмо — %s. Она живёт в нашем городе." % String(tgt.get("npc_name"))
		_:
			return {}
	var rw: Dictionary = {"coins": coins, "rep": rep, "items": {}}
	if role == "лидер":
		rw["rep"] = r.randi_range(9, 14)
		rw["coins"] = int(coins * 1.5) + 40
		rw["items"] = {String(_pick(["ring_amber", "amulet_clover", "amulet_moon", "gold_sickle", "pickaxe", "pack_travel", "lantern_hand", "goggles", "ring_moss"], r)): 1}
	elif r.randf() < 0.3:
		rw["items"] = {String(_pick(["bottle", "honey", "wax", "spirit", "stone_m", "ore_moonsilver"], r)): 1}
	q["reward"] = rw
	return q


func _random_neighbor(nm: String, land: String, r: RandomNumberGenerator) -> Node:
	var cand: Array = []
	for n in get_tree().get_nodes_in_group("interactables"):
		if is_instance_valid(n) and n.get("npc_name") != null and String(n.get("land")) == land and String(n.get("npc_name")) != nm and String(n.get("role")) != "стража" and String(n.get("npc_name")) != "":
			cand.append(n)
	if cand.is_empty():
		return null
	return cand[r.randi_range(0, cand.size() - 1)]


func where_text(land: String, pos: Vector2) -> String:
	var c0: Vector2 = WD.TOWN_C.get(land, Vector2.ZERO)
	var d: Vector2 = pos - c0
	var idx: int = int(round(d.angle() / (TAU / 8.0))) % 8
	if idx < 0:
		idx += 8
	return "к %s от города, примерно %d шагов" % [SIDES[idx], int(d.length() / 18.0)]


# ------------------------------------------------------------------ принять / сдать

func accept(q: Dictionary) -> void:
	q["id"] = next_id
	next_id += 1
	active.append(q)
	if String(q["type"]) == "cat":
		_spawn_cat(q)
	if String(q["type"]) == "letter":
		Game.add_item("quest_letter")
	Game.toast.emit("Задание: " + String(q["title"]), load("res://art/icon_scroll.png"))
	Sound.play("page", -4.0)


func progress_text(q: Dictionary) -> String:
	var out: Array = []
	for id in (q["need"] as Dictionary).keys():
		var n: int = int((q["need"] as Dictionary)[id])
		if String(id) == "cat":
			out.append("кошка %s: %s" % [String(q.get("cat_name", "")), "найдена" if bool(q["found"]) else "ещё в лесу"])
		else:
			out.append("%s %d/%d" % [IT.name(String(id)), mini(Game.get_count(String(id)), n), n])
	if String(q["type"]) == "letter":
		out.append("письмо: %s" % ("передано" if bool(q["delivered"]) else "для " + String(q["target"])))
	return ", ".join(out)


func can_turn_in(q: Dictionary) -> bool:
	if String(q["type"]) == "letter":
		return bool(q["delivered"])
	for id in (q["need"] as Dictionary).keys():
		var n: int = int((q["need"] as Dictionary)[id])
		if String(id) == "cat":
			if not bool(q["found"]):
				return false
		elif Game.get_count(String(id)) < n:
			return false
	return true


func reward_text(q: Dictionary) -> String:
	var rw: Dictionary = q["reward"]
	var parts: Array = ["%d монет" % int(rw["coins"]), "уважение +%d" % int(rw["rep"])]
	for it in (rw["items"] as Dictionary).keys():
		parts.append(IT.name(String(it)))
	return ", ".join(parts)


## Сдать: забрать предметы, выдать награду
func turn_in(q: Dictionary) -> bool:
	if not can_turn_in(q):
		return false
	for id in (q["need"] as Dictionary).keys():
		if String(id) != "cat":
			Game.take_item(String(id), int((q["need"] as Dictionary)[id]))
	var rw: Dictionary = q["reward"]
	Game.add_coins(int(rw["coins"]))
	Game.rep_add(String(q["land"]), int(rw["rep"]))
	for it in (rw["items"] as Dictionary).keys():
		Game.add_item(String(it), int((rw["items"] as Dictionary)[it]))
	if cats.has(int(q["id"])):
		_free_cat(int(q["id"]))
	active.erase(q)
	done_count += 1
	cooldown[String(q["giver"])] = Game.day + 2
	return true


func abandon(q: Dictionary) -> void:
	if cats.has(int(q["id"])):
		_free_cat(int(q["id"]))
	active.erase(q)


## Письмо: передала нужной жительнице
func deliver_to(npc: Node) -> Dictionary:
	var nm: String = String(npc.get("npc_name"))
	for q in active:
		if String(q["type"]) == "letter" and String(q["target"]) == nm and not bool(q["delivered"]) and Game.get_count("quest_letter") > 0:
			Game.take_item("quest_letter")
			q["delivered"] = true
			return q
	return {}


func letter_for(npc: Node) -> bool:
	var nm: String = String(npc.get("npc_name"))
	for q in active:
		if String(q["type"]) == "letter" and String(q["target"]) == nm and not bool(q["delivered"]) and Game.get_count("quest_letter") > 0:
			return true
	return false


# ------------------------------------------------------------------ потерявшаяся кошка

func _spawn_cat(q: Dictionary) -> void:
	var c: Node2D = Node2D.new()
	c.set_script(load("res://lost_cat.gd"))
	c.set("quest_id", int(q["id"]))
	c.set("skin", String(q["cat_skin"]))
	c.set("cat_name", String(q["cat_name"]))
	c.set("main", main)
	c.position = q["cat_pos"]
	(main.get("objects") as Node).add_child(c)
	cats[int(q["id"])] = c


func _free_cat(id: int) -> void:
	var c: Node = cats.get(id)
	if c != null and is_instance_valid(c):
		c.queue_free()
	cats.erase(id)


func cat_found(id: int) -> void:
	for q in active:
		if int(q["id"]) == id:
			q["found"] = true
			Game.toast.emit("Кошка %s найдена! Отнеси её домой." % String(q.get("cat_name", "")), load("res://art/icon_scroll.png"))
	_free_cat(id)


## Для тестов: сразу засчитать условие задания (положить предметы)
func cheat_complete(q: Dictionary) -> void:
	for id in (q["need"] as Dictionary).keys():
		if String(id) == "cat":
			q["found"] = true
		else:
			Game.add_item(String(id), int((q["need"] as Dictionary)[id]))
	if String(q["type"]) == "letter":
		q["delivered"] = true

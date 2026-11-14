extends RefCounted
## v25: автотест (main._run_tests, флаг --only25 — только он). Новые звери и грибы, птицы на насестах,
## книга сфер (сферы, противоположности, заклинания, мана), приручение и езда, облик зверя, переезд, Эквестрия, алтари.

const W = preload("res://wild_db.gd")
const SP = preload("res://spells25_db.gd")
const NPC = preload("res://npc_db.gd")

var m: Node2D
var fails: Array


func ck(ok: bool, name: String) -> void:
	m.call("_check", ok, "v25: " + name, fails)


func wait(sec: float) -> void:
	await m.get_tree().create_timer(sec).timeout


func run(main: Node2D, f: Array) -> void:
	m = main
	fails = f
	var tree: SceneTree = m.get_tree()
	var pl: Node2D = m.get("player")
	var v25: Node = tree.get_first_node_in_group("v25")
	ck(v25 != null and m.get_node_or_null("Pony25") != null, "модули v25 на месте")
	# --- звери и грибы
	var n_new: int = 0
	var bad: Array = []
	for k in W.ANIMALS.keys():
		var a: Dictionary = W.ANIMALS[k]
		if a.get("v25", false):
			n_new += 1
			var tex: Texture2D = load("res://art/animal_%s.png" % k)
			if tex == null or tex.get_width() % 12 != 0:
				bad.append(k)
	ck(n_new >= 50 and W.ANIMALS.size() >= 70, "новых зверей %d, всего %d" % [n_new, W.ANIMALS.size()])
	ck(bad.is_empty(), "листы новых зверей по 12 кадров " + str(bad))
	ck((W.FAUNA[13] as Array).size() > 5 and W.MYTHIC_SPAWN.has(17), "звери расселены по биомам")
	ck(preload("res://farm23.gd").ORDER.size() >= 70 and preload("res://farm23.gd").ZOO.has("wolf"), "новые звери в книге")
	var ns: int = 0
	var bad2: Array = []
	for s in W.SHROOMS.keys():
		if (W.SHROOMS[s] as Dictionary).get("v25", false):
			ns += 1
			if W.shroom_icon(s) == null or not preload("res://recipes_db.gd").SHROOM_PROPS.has(s):
				bad2.append(s)
	ck(ns >= 50 and bad2.is_empty(), "новых грибов %d, у всех значок и свойства %s" % [ns, str(bad2)])
	ck(W.shrooms_for(17).size() >= 4 and W.shrooms_for(10).size() >= 5, "грибы растут в Сакураяме и розовом лесу")
	# --- птицы на заборах и крышах
	var bm: Node = m.get_node_or_null("Birds")
	if bm == null:
		for c in m.get_children():
			if String(c.get_script().resource_path if c.get_script() != null else "").ends_with("birds.gd"):
				bm = c
	ck(bm != null and bm.has_method("_perch_near"), "птицам есть где искать насесты")
	ck(not tree.get_nodes_in_group("perch_fence").is_empty(), "заборы стали насестами")
	# --- книга сфер
	Game.mana = 100.0
	Game.orbs_open = ["water", "life", "earth", "fire"]
	Game.spells_known.clear()
	v25.set("orbs", [])
	ck(not bool(v25.call("add_orb", "arcane")), "закрытая стихия не кладётся")
	v25.call("add_orb", "fire")
	Game.orbs_open.append("cold")
	v25.call("add_orb", "cold")
	ck((v25.get("orbs") as Array).is_empty(), "холод гасит огонь")
	for i in range(4):
		v25.call("add_orb", "water")
	ck((v25.get("orbs") as Array).size() == 3, "в очереди не больше трёх сфер")
	ck(SP.key_of(["fire", "water", "life"]) == "water+life+fire", "ключ сочетания по порядку стихий")
	v25.set("orbs", ["water", "water"])
	v25.set("cast_cd", 0.0)
	var mana0: float = Game.mana
	ck(bool(v25.call("cast")), "заклинание произносится")
	ck(Game.spells_known.has("water+water") and Game.mana < mana0, "Ливень найден, сила потрачена")
	Game.orbs_open.append("shield")
	v25.set("orbs", ["shield"])
	v25.set("cast_cd", 0.0)
	v25.call("cast")
	ck(Game.spell_shield > 5.0, "щит держится")
	v25.set("orbs", ["earth", "fire", "water"])
	v25.set("cast_cd", 0.0)
	ck(bool(v25.call("cast")), "Горячий источник")
	v25.set("orbs", ["fire", "earth", "life"])
	v25.set("cast_cd", 0.0)
	Game.mana = 100.0
	ck(bool(v25.call("cast")), "неизвестное сочетание — смесь стихий")
	var plot: Node2D = tree.get_nodes_in_group("plots")[0]
	plot.call("debug_set", "mint", 0, false)
	pl.position = plot.global_position + Vector2(0, 30)
	v25.call("do_spell", "living_water", ["water", "life"])
	ck(int(plot.get("stage")) == 1 and bool(plot.get("watered")), "Живая вода растит грядку")
	await wait(0.6)
	# --- приручение и езда
	var a2: Node2D = Node2D.new()
	a2.set_script(load("res://animal.gd"))
	(m.get("objects") as Node).add_child(a2)
	a2.call("setup", "horse", pl.position + Vector2(30, 0))
	Game.mounts.clear()
	Game.mount_kind = ""
	Game.trust.erase("horse")
	Game.add_item("food_apple", 10)
	var hs: int = Game.hotbar.find("food_apple")
	if hs < 0:
		Game.hotbar[0] = "food_apple"
		hs = 0
	Game.hot_sel = hs
	ck(String(v25.call("animal_prompt", a2)).begins_with("Угостить"), "конь просит угощение")
	for i2 in range(6):
		if Game.mounts.has("horse"):
			break
		a2.call("interact")
	ck(Game.mounts.has("horse") and Game.mount_kind == "horse", "конь приручен")
	v25.call("mount")
	await wait(0.3)
	ck(Game.riding and float(pl.get("speed_mul")) > 2.0 and not (pl.get("sprite") as Sprite2D).visible, "верхом: быстрее, всадница на коне")
	v25.call("dismount", true)
	await wait(0.2)
	ck(not Game.riding and (pl.get("sprite") as Sprite2D).visible and is_instance_valid(v25.get("companion")), "слезла — конь рядом")
	# --- облик зверя
	v25.call("start_form", "fox")
	await wait(0.2)
	ck(Game.shape_form == "fox" and not (pl.get("sprite") as Sprite2D).visible, "облик лисы")
	ck(String(v25.call("animal_prompt", v25.get("companion"))) == "Поговорить", "в облике зверя со зверями можно говорить")
	v25.call("end_form")
	ck(Game.shape_form == "" and (pl.get("sprite") as Sprite2D).visible, "снова травница")
	# --- алтарь
	var al: Node2D = Node2D.new()
	al.set_script(load("res://altar25.gd"))
	(m.get("objects") as Node).add_child(al)
	al.call("setup", "lightning", pl.position + Vector2(-60, 0))
	Game.orbs_open.erase("lightning")
	al.call("interact")
	ck(Game.orbs_open.has("lightning"), "алтарь открывает молнию")
	al.queue_free()
	# --- Эквестрия
	ck(NPC.land_of("pony_twilight") == "ponies" and String(NPC.person("pony_pinkie")[0]) == "Пинки Пай", "пони — жительницы Эквестрии")
	ck(preload("res://world_data.gd").TOWN_C.has("ponies"), "Понивилль на карте")
	var pn: Node = m.get_node("Pony25")
	Game.orbs_open.erase("arcane")
	for mm in pn.get("MANE6"):
		pn.call("met", String(mm))
	ck(Game.orbs_open.has("arcane"), "дружба с шестёркой открывает Тайну")
	await m.call("teleport_to", Vector2(6100, -6850))
	await wait(1.5)
	var ponies: int = 0
	for c2 in tree.get_nodes_in_group("catgirls"):
		if String(c2.get("tex_name")).begins_with("pony_"):
			ponies += 1
	ck(ponies >= 20, "в Понивилле много пони (%d)" % ponies)
	# --- переезд
	Game.coins = 200
	Game.chests["%d,%d" % [int(Game.home_pos.x) + 10, int(Game.home_pos.y)]] = {"kind": "chest_small", "layout": [], "filter": ""}
	var old: Vector2 = Game.home_pos
	ck(bool(v25.call("relocate", "birch")), "переезд оплачен")
	var d: Vector2 = Game.home_pos - old
	ck(Game.home_biome == "birch" and d.length() > 100.0 and Game.chests.has("%d,%d" % [int(old.x + d.x) + 10, int(old.y + d.y)]), "дом и сундук переехали")


## Скриншоты: --v25=fauna|ponyville|canterlot|ride|form|spells|grimoire|move|birds
func shot(main: Node2D, what: String) -> void:
	m = main
	var pl: Node2D = m.get("player")
	var v25: Node = m.get_tree().get_first_node_in_group("v25")
	match what:
		"ponyville":
			await m.call("teleport_to", Vector2(6100, -6900))
			await wait(1.5)
		"farm":
			await m.call("teleport_to", Vector2(4560, -6600))
			await wait(1.5)
		"canterlot":
			await m.call("teleport_to", Vector2(6700, -8150))
			await wait(1.5)
		"fauna":
			var kinds: Array = []
			for k in W.ANIMALS.keys():
				if (W.ANIMALS[k] as Dictionary).get("v25", false):
					kinds.append(k)
			var i: int = 0
			for k2 in kinds.slice(0, 24):
				var a: Node2D = Node2D.new()
				a.set_script(load("res://animal.gd"))
				(m.get("objects") as Node).add_child(a)
				a.call("setup", String(k2), pl.position + Vector2(-260 + (i % 6) * 100, -120 + (i / 6) * 70))
				a.set("roam", 0.0)
				a.set("wait_t", 999.0)
				i += 1
			await wait(0.5)
		"ride":
			Game.mounts = ["horse"]
			Game.mount_kind = "horse"
			v25.call("mount")
			Input.action_press("ui_left")
			await wait(0.5)
		"unicorn":
			Game.mounts = ["pegasus"]
			Game.mount_kind = "pegasus"
			v25.call("mount")
			await wait(0.5)
		"form":
			v25.call("start_form", "wolf")
			await wait(0.5)
		"spells":
			Game.orbs_open = SP.ORDER.duplicate()
			v25.set("spell_mode", true)
			v25.set("orbs", ["water", "life", "earth"])
			v25.call("do_spell", "blizzard", ["cold", "cold"])
			v25.call("do_spell", "fireball", ["fire", "fire"])
			await wait(0.25)
		"grimoire":
			Game.spells_known = {"water": 1, "fire+fire": 1, "life+earth+earth": 1}
			v25.call("toggle_grimoire")
			await wait(0.3)
		"move":
			v25.call("open_move")
			await wait(0.3)

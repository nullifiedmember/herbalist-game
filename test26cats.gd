extends RefCounted
## v26: автотест котов разных окрасов (флаг --only26cats — только он) и сцены для скриншотов (--v26cats=village|all).

const DB = preload("res://cats26_db.gd")
const CV = preload("res://cat_village.gd")

var m: Node2D
var fails: Array


func ck(ok: bool, name: String) -> void:
	m.call("_check", ok, "коты26: " + name, fails)


func wait(sec: float) -> void:
	await m.get_tree().create_timer(sec).timeout


func run(main: Node2D, f: Array) -> void:
	m = main
	fails = f
	var tree: SceneTree = m.get_tree()
	# --- картинки: у каждого окраса взрослый и котёнок, по 10 кадров как у кота травницы (кадр 42 px: место для хвоста)
	var bad: Array = []
	for s in DB.ORDER:
		for sk in [s, "kit_" + s]:
			var tex: Texture2D = load(DB.tex_path(sk))
			if tex == null or tex.get_width() % 10 != 0 or tex.get_height() < 16:   # чиби-листы: 10 кадров, размер у каждого свой
				bad.append(sk)
	ck(bad.is_empty(), "листы %d окрасов и котят на месте %s" % [DB.ORDER.size(), str(bad)])
	var rares: int = 0
	for s2 in DB.ORDER:
		if DB.tier(s2) >= 2:
			rares += 1
	ck(DB.ORDER.size() >= 20 and rares >= 5, "окрасов %d, из них редких %d" % [DB.ORDER.size(), rares])
	# --- редкость: на 20000 котов деревни редких около 6%, сказочных меньше, чем редких
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 26
	var cnt: Array = [0, 0, 0, 0]
	for i in range(20000):
		cnt[DB.tier(DB.pick(rng, 0.06))] += 1
	var rare_p: float = float(cnt[2] + cnt[3]) / 20000.0
	ck(rare_p > 0.04 and rare_p < 0.08 and cnt[3] < cnt[2] and cnt[3] > 0, "редкие выпадают редко: %.1f%% (редких %d, сказочных %d)" % [rare_p * 100.0, cnt[2], cnt[3]])
	# --- деревня кошкодевочек: много котов, у кого-то котята
	var mgr: Node = tree.get_first_node_in_group("stray_cats26_mgr")
	ck(mgr != null, "менеджер бродячих котов есть")
	await m.call("teleport_to", CV.PLAZA + Vector2(0, 120))
	await wait(1.0)
	var near: Array = []
	var kits: int = 0
	for c in tree.get_nodes_in_group("stray_cats26"):
		if (c as Node2D).global_position.distance_to(CV.PLAZA) < 900.0:
			near.append(c)
			if DB.is_kit(String(c.get("skin"))):
				kits += 1
	ck(near.size() >= 6, "в деревне кошкодевочек котов: %d (котят %d)" % [near.size(), kits])
	# котёнок держится возле мамы
	var mgr_node: Node2D = m.get("objects") as Node2D
	var mom: Node2D = mgr.call("spawn", mgr_node, "tabby_gray", CV.PLAZA + Vector2(60, 160))
	var kit: Node2D = mgr.call("spawn", mgr_node, "kit_tabby_gray", CV.PLAZA + Vector2(200, 200))
	kit.set("mom", mom)
	await wait(4.0)
	ck(kit.global_position.distance_to(mom.global_position) < 60.0, "котёнок прибежал к маме (%.0f px)" % kit.global_position.distance_to(mom.global_position))
	ck((kit.get("spr") as Sprite2D).texture.resource_path.ends_with("cat26_kit_tabby_gray.png"), "у котёнка свой маленький спрайт")
	# --- погладить несколько раз — кот пойдёт с героиней
	var pets0: int = (Game.pets as Array).size()
	var gold: Node2D = mgr.call("spawn", mgr_node, "golden", (m.get("player") as Node2D).global_position + Vector2(30, 10))
	await wait(0.2)
	var need: int = int(gold.call("need_pets"))
	ck(need > 3, "редкого кота дольше уговаривать (%d раз)" % need)
	for k in range(need):
		gold.call("interact")
	await wait(0.3)
	var pet: Node2D = null
	for p in tree.get_nodes_in_group("pets18"):
		if str(p.get("skin")) == "golden":
			pet = p
	ck((Game.pets as Array).size() == pets0 + 1 and pet != null, "золотой кот пошёл с героиней")
	if pet != null:
		ck((pet.get("spr") as Sprite2D).texture.resource_path.ends_with("cat26_golden.png"), "питомец в своём окрасе")
		(Game.pets as Array).pop_back()
		pet.queue_free()
	# кот травницы теперь пушистый
	var own: Node = tree.get_first_node_in_group("companion_cat")
	if own != null:
		ck((own.get("spr") as Sprite2D).texture.resource_path.ends_with("cat26_black.png"), "кот травницы пушистый")
	mom.queue_free()
	kit.queue_free()


func shot(main: Node2D, what: String) -> void:
	m = main
	var pl: Node2D = m.get("player")
	var mgr: Node = m.get_tree().get_first_node_in_group("stray_cats26_mgr")
	match what:
		"village":
			await m.call("teleport_to", CV.PLAZA + Vector2(0, 90))
			await wait(1.5)
		"all":
			# все окрасы рядком: сверху взрослые, снизу котята
			await m.call("teleport_to", CV.PLAZA + Vector2(0, 90))
			await wait(0.8)
			var i: int = 0
			for s in DB.ORDER:
				var at: Vector2 = pl.global_position + Vector2(-276 + (i % 12) * 50, -130 + (i / 12) * 70)
				var c: Node2D = mgr.call("spawn", m.get("objects"), s, at)
				c.set("state_t", 999.0)
				var kk: Node2D = mgr.call("spawn", m.get("objects"), "kit_" + s, at + Vector2(0, 30))
				kk.set("state_t", 999.0)
				i += 1
			await wait(0.5)

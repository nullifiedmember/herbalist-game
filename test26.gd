extends RefCounted
## v26: автотест (флаг --only26 — только он). Крафт из сундуков базы, сортировка сумки, колышки у участка, магазины королевства.

const S = preload("res://shops26.gd")

var m: Node2D
var fails: Array


func ck(ok: bool, name: String) -> void:
	m.call("_check", ok, "v26: " + name, fails)


func run(main: Node2D, f: Array) -> void:
	m = main
	fails = f
	var hs: Node = m.get_tree().get_first_node_in_group("homestead")
	var cu: Node = m.get_tree().get_first_node_in_group("chest_ui")
	# ---- крафт из сундука базы
	Game.chests.clear()
	Game.chest.clear()
	cu.call("register", "%d,%d" % [int(Game.home_pos.x) + 40, int(Game.home_pos.y) + 40], "chest")
	for id in ["log", "stick", "twine"]:
		Game.inventory[id] = 0
	Game.inventory_changed.emit()
	cu.call("deposit", "stick", 5, Game.home_pos)
	cu.call("deposit", "twine", 3, Game.home_pos)
	ck(int(hs.call("_have", "stick")) == 5, "верстак видит палки в сундуке")
	ck(bool(hs.call("_can_pay", {"stick": 2, "twine": 1})), "хватает материалов из сундука")
	var had_rod: int = Game.get_count("rod")
	ck(bool(m.get_node("V23").call("bench_craft", "rod")) and Game.get_count("rod") == had_rod + 1, "удочка сделана из сундука")
	ck(int((cu.call("base_totals") as Dictionary).get("stick", 0)) == 3 and int((cu.call("base_totals") as Dictionary).get("twine", 0)) == 2, "материалы списаны из сундука")
	# сумка + сундук вместе
	Game.add_item("stick", 2)
	ck(int(hs.call("_have", "stick")) == 5, "сумка и сундук складываются")
	ck(bool(hs.call("_pay", {"stick": 4})) and Game.get_count("stick") == 0 and int((cu.call("base_totals") as Dictionary).get("stick", 0)) == 1, "сначала сумка, остальное из сундука")
	# далёкий сундук не считается
	cu.call("register", "%d,%d" % [int(Game.home_pos.x) + 9000, int(Game.home_pos.y)], "chest")
	cu.call("deposit", "flint", 4, Game.home_pos + Vector2(9000, 0), true)
	Game.inventory["flint"] = 0
	ck(int(hs.call("_have", "flint")) == 0 and int((cu.call("base_totals") as Dictionary).get("flint", 0)) == 0, "далёкий сундук вне базы")
	# ---- сортировка сумки
	Game.inventory.clear()
	for it in [["lavender", 3], ["log", 4], ["mint", 2], ["stick", 5], ["clover", 1]]:
		Game.add_item(String(it[0]), int(it[1]))
	Game.layout.clear()
	Game.sort_layout()
	var tot: int = 0
	for e in Game.layout:
		tot += int(e["n"])
	ck(tot == 15 and Game.overflow.is_empty(), "сортировка ничего не потеряла")
	# ---- колышки участка
	ck((hs.get("stakes") as Array).is_empty(), "колышков у границы дома нет")
	# ---- магазины
	ck(IT_has("kg_shop_potion") and IT_has("kg_shop_smith"), "магазины в постройках королевства")
	Game.shops.clear()
	var key: String = "%d,%d" % [int(Game.home_pos.x) + 300, int(Game.home_pos.y) + 100]
	hs.call("build", "kg_shop_potion", Vector2(Game.home_pos.x + 300, Game.home_pos.y + 100))
	ck(Game.shops.has(key), "лавка зелий построена и записана")
	Game.add_item("calm_tea", 3)
	var sh: Node = m.get_tree().get_first_node_in_group("shops26")
	ck(S.accepts("kg_shop_potion", "calm_tea") and not S.accepts("kg_shop_potion", "log"), "лавка берёт только свои товары")
	ck(bool(sh.call("act", key, "put")) and S.goods_count(key) == 3, "товар выложен на прилавок")
	var pr: int = int(sh.call("sell_one", key))
	ck(pr > 0 and S.goods_count(key) == 2 and int(Game.shops[key]["cash"]) == pr, "покупатель купил, деньги в кассе")
	var c0: int = Game.coins
	ck(bool(sh.call("act", key, "cash")) and Game.coins == c0 + pr, "выручка забрана")
	# пополнение из сундуков базы
	cu.call("deposit", "calm_tea", 4, Game.home_pos)
	ck(bool(sh.call("act", key, "restock")) and S.goods_count(key) == 6, "лавка пополнена из сундуков базы")
	# покупатели приходят сами в рабочие часы
	var before: int = int(Game.shops[key]["sold"])
	Game.workers.clear()
	for i in range(40):
		sh.call("_hour_tick", 12.0)
	ck(int(Game.shops[key]["sold"]) > before or S.goods_count(key) == 0, "жители сами приходят и покупают")
	var night: int = S.goods_count(key)
	sh.call("_hour_tick", 3.0)
	ck(S.goods_count(key) == night, "ночью лавка закрыта")


func IT_has(k: String) -> bool:
	return preload("res://items_db.gd").KBUILD.has(k) and preload("res://items_db.gd").BUILD.has(k)

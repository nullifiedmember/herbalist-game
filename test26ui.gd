extends RefCounted
## v26: скриншоты сундуков/склада/сумки с подсказкой: --v26ui=вид_сундука[:id_под_мышью]
const IT = preload("res://items_db.gd")
const RDB = preload("res://recipes_db.gd")


func shot(m: Node2D, what: String) -> void:
	var kind: String = what.get_slice(":", 0)
	var hover: String = what.get_slice(":", 1) if what.contains(":") else ""
	var tree: SceneTree = m.get_tree()
	var cu: Node = tree.get_first_node_in_group("chest_ui")
	var ids: Array = []
	var k: int = 0
	for p in RDB.PRODUCTS.keys():
		if k < 40:
			ids.append(p)
		k += 1
	ids.append_array(["food_apple", "food_bread", "mint", "porcini", "ore_mana", "stone_m", "log", "sickle", "wpn_sword_wood", "minnow", "book_magic_herb", "bark_tree_a"])
	if kind == "hotbar":
		# v31: панель быстрого доступа с вещами и счётчиками (1, 2, 12, 99)
		var hb: Array = ["hoe", "mint", "log", "food_apple", "stone_m", "sickle", "", "porcini", "minnow"]
		var cnt: Array = [1, 12, 99, 3, 7, 1, 0, 24, 2]
		for i in range(9):
			if String(hb[i]) != "":
				Game.add_item(String(hb[i]), int(cnt[i]))
			Game.hotbar[i] = String(hb[i])
		Game.hot_sel = 1
		var hs: Node = tree.get_first_node_in_group("homestead")
		if hs == null:
			for n in m.get_children():
				if n.has_method("_refresh_soon"):
					hs = n
		if hs:
			hs.call("_refresh")
		await tree.create_timer(0.6).timeout
		return
	if kind == "bag":
		for id in ids.slice(0, 30):
			Game.add_item(String(id), 2)
		tree.get_first_node_in_group("inventory_ui").call("open_inv")
		await tree.create_timer(0.5).timeout
		if hover != "":
			var iu: Node = tree.get_first_node_in_group("inventory_ui")
			for c in (iu.get("cells") as Array):
				if String(c[1]) == hover:
					_warp(m, (c[0] as Control).get_global_rect().get_center())
		await tree.create_timer(0.6).timeout
		return
	var key: String = "f:%d,%d" % [int(Game.home_pos.x) + 5, int(Game.home_pos.y) + 5]
	cu.call("register", key, kind)
	Game.chests[key]["filter"] = "all"
	cu.call("open_chest", key, kind)
	cu.call("_use", key)
	for id in ids:
		cu.call("_add", String(id), 4)
	cu.call("_sync_dict")
	cu.call("_refresh")
	await tree.create_timer(0.5).timeout
	if hover != "":
		var grid: Control = cu.get("grid")
		var cell: float = float(cu.get("cell"))
		for e in (cu.call("L") as Array):
			if String(e["id"]) == hover:
				_warp(m, grid.get_global_rect().position + Vector2(int(e["x"]) + 0.5, int(e["y"]) + 0.5) * cell)
				break
	await tree.create_timer(0.8).timeout


func _warp(m: Node2D, p: Vector2) -> void:
	var vp: Viewport = m.get_viewport()
	var xf: Transform2D = vp.get_final_transform()
	vp.warp_mouse(p)
	Input.warp_mouse(xf * p)


## Автотест v26-UI: у каждой вещи есть описание, зелья действуют, сундук и подсказка работают
func run(m: Node2D, fails: Array) -> void:
	print("TEST: v26 значки и описания")
	var II = preload("res://item_info.gd")
	var empty: Array = []
	var all_ids: Array = []
	all_ids.append_array(RDB.PRODUCTS.keys())
	all_ids.append_array(IT.GEAR.keys())
	all_ids.append_array(IT.ITEMS.keys())
	all_ids.append_array(preload("res://herbs_db.gd").DATA.keys())
	all_ids.append_array(preload("res://wild_db.gd").SHROOMS.keys())
	all_ids.append_array(preload("res://mats_db.gd").MATS.keys())
	for id in all_ids:
		var ok: bool = false
		for l in II.lines(String(id)):
			if String(l[1]) in ["good", "desc", "hint"]:
				ok = true
		if not ok:
			empty.append(id)
	m.call("_check", empty.is_empty(), "v26: у всех вещей есть описание (пустых %d)" % empty.size(), fails)
	m.call("_check", II.ui_icon("calm_tea") != null, "v26: значок для ячейки есть", fails)
	# зелье с главным свойством «Исцеление» лечит, «Сила» даёт вес
	var heal: String = ""
	var str_p: String = ""
	for p in RDB.PRODUCTS.keys():
		var fx: Array = II.potion_fx(String(p))
		if fx.is_empty():
			continue
		if heal == "" and String(fx[3]) == "heal":
			heal = String(p)
		if str_p == "" and (fx[1] as Dictionary).has("cap"):
			str_p = String(p)
	m.call("_check", heal != "" and str_p != "", "v26: есть зелья лечения и силы", fails)
	if heal != "" and str_p != "":
		Game.hp = 10.0
		Game.equip["flask0"] = heal
		Game.drink_flask(0)
		m.call("_check", Game.hp >= Game.hp_max() - 0.1, "v26: зелье исцеления лечит", fails)
		var cap0: float = Game.capacity()
		Game.equip["flask0"] = str_p
		Game.drink_flask(0)
		m.call("_check", Game.capacity() > cap0 and Game.pbuff_t > 0.0, "v26: зелье силы даёт вес", fails)
		Game.pbuff_t = 0.0
	m.call("_check", IT.stack("calm_tea") == 5, "v26: зелья складываются по 5", fails)
	# сундук: клетки крупные, подсказка строится
	var cu: Node = m.get_tree().get_first_node_in_group("chest_ui")
	var key: String = "f:%d,%d" % [int(Game.home_pos.x) + 9, int(Game.home_pos.y) + 9]
	cu.call("register", key, "warehouse")
	cu.call("open_chest", key, "warehouse")
	cu.call("_use", key)
	m.call("_check", float(cu.get("cell")) >= 44.0, "v26: клетки склада крупные", fails)
	var pn: Control = cu.get("panel")
	m.call("_check", pn.position.x + pn.size.x <= 1920.0 - 768.0 - 24.0 + 1.0, "v26: склад не налезает на сумку", fails)
	var tb: VBoxContainer = cu.get("tip_box")
	II.fill_box(tb, "calm_tea", m.get("hud"))
	m.call("_check", tb.get_child_count() >= 4, "v26: подсказка в сундуке собирается", fails)
	cu.call("close_chest")
	Game.chests.erase(key)

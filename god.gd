extends RefCounted
## Режим бога (v18): все предметы игры по категориям и цели для телепорта.

const IT = preload("res://items_db.gd")
const DB = preload("res://herbs_db.gd")
const RDB = preload("res://recipes_db.gd")
const WDB = preload("res://wild_db.gd")
const FDB = preload("res://fish_db.gd")
const FD = preload("res://food_db.gd")
const TD = preload("res://tree_db.gd")
const INS = preload("res://insects_db.gd")
const MD = preload("res://mining_db.gd")
const WD = preload("res://world_data.gd")
const SCN = preload("res://scenarios_db.gd")
const NPC = preload("res://npc_db.gd")

const PLACE_NAMES: Dictionary = {
	"home": "Родной двор", "cats": "Деревня кошек", "spider": "Паучий лес", "gothic": "Готический край", "castle": "Замок",
	"elf": "Лес эльфов", "mage": "Долина магов", "orc": "Становище орков", "goblin": "Деревня гоблинов", "dwarf": "Врата дворфов",
	"unicorn": "Поляна единорогов", "cave": "Пещера", "hermit": "Хижина отшельницы", "outcast": "Стоянка изгоев",
	"japan": "Сакураяма", "pier": "Пирс и колокол",
}

const CATEGORIES: Array = ["Всё", "Оружие", "Мебель", "Книги и приколы", "Вещи", "Травы", "Зелья", "Еда", "Грибы и рыба", "Камни и руды", "Постройки", "Листья и жуки", "Материалы", "Перья и шерсть"]


## Все предметы игры по категориям: категория -> Array[id]. Каждый предмет ровно в одной категории.
static func by_category() -> Dictionary:
	var cats: Dictionary = {}
	for c in CATEGORIES:
		cats[c] = []
	var seen: Dictionary = {}
	var add: Callable = func(cat: String, id: String) -> void:
		if seen.has(id):
			return
		seen[id] = true
		(cats[cat] as Array).append(id)
	for id in MD.all_item_ids():
		add.call("Камни и руды", String(id))
	var MT = preload("res://mats_db.gd")
	for mid in MT.ORDER:
		var c: String = MT.cat(String(mid))
		add.call("Перья и шерсть" if c in ["feather", "animal"] else "Материалы", String(mid))
	var V23 = preload("res://v23_data.gd")
	for vid in preload("res://v24_data.gd").ITEMS.keys():   # v24: длинная ветка и др.
		add.call("Материалы", String(vid))
	for wid in ([] if Game.SOLO else V23.WEAPON_ORDER):
		add.call("Оружие", String(wid))
	for fid in V23.FURN.keys():
		add.call("Мебель", "furn:" + String(fid))
	for bid in V23.BOOKS.keys():
		add.call("Книги и приколы", String(bid))
	for jid in V23.JOKES.keys():
		add.call("Книги и приколы", String(jid))
	for pid in V23.PRODUCTS.keys():
		add.call("Вещи", String(pid))
	for id in IT.GEAR.keys():
		add.call("Вещи", String(id))
	for id in IT.ITEMS.keys():
		add.call("Вещи", String(id))
	for id in DB.DATA.keys():
		add.call("Травы", String(id))
	for idd in DB.DATA.keys():
		add.call("Травы", "dry:" + String(idd))
	for id in RDB.PRODUCTS.keys():
		add.call("Зелья", String(id))
	for id in FD.DATA.keys():
		add.call("Еда", "food_" + String(id))
	for id in WDB.SHROOMS.keys():
		add.call("Грибы и рыба", String(id))
	for id in FDB.DATA.keys():
		add.call("Грибы и рыба", String(id))
	for k in IT.BUILD.keys():
		add.call("Постройки", "kit:" + String(k))
	for tr in IT.TREE_NAMES.keys():
		add.call("Постройки", "sapling:" + String(tr))
	for tr2 in TD.TREES.keys():
		add.call("Листья и жуки", "leaf_" + String(tr2))
	for ins in INS.DATA.keys():
		add.call("Листья и жуки", "bug_" + String(ins))
	var all: Array = []
	for c in CATEGORIES:
		if c != "Всё":
			all.append_array(cats[c])
	cats["Всё"] = all
	return cats


static func all_items() -> Array:
	return by_category()["Всё"]


## Цели телепорта: Array[{group, name, pos}]
static func targets() -> Array:
	var out: Array = []
	for land in WD.TOWN_C.keys():
		var nm: String = String((NPC.LANDS.get(land, {}) as Dictionary).get("name", String(land)))
		out.append({"group": "Города", "name": nm, "pos": (WD.TOWN_C[land] as Vector2) + Vector2(0, 150)})
	for land2 in WD.TOWN_C.keys():
		var nm2: String = String((NPC.LANDS.get(land2, {}) as Dictionary).get("name", String(land2)))
		out.append({"group": "Тюрьмы", "name": "Тюрьма: " + nm2, "pos": (WD.TOWN_C[land2] as Vector2) + Vector2(430, 360)})
	var count: Dictionary = {}
	for lm in WD.LANDMARKS:
		var kind: String = String(lm[2])
		count[kind] = int(count.get(kind, 0)) + 1
		var nm3: String = String(PLACE_NAMES.get(kind, kind))
		if int(count[kind]) > 1:
			nm3 += " " + str(count[kind])
		out.append({"group": "Места", "name": nm3, "pos": Vector2(float(lm[0]), float(lm[1])) + Vector2(0, 90)})
	var lep: Vector2 = preload("res://livehouse.gd").ent_pos
	if lep != Vector2.INF:
		out.append({"group": "Места", "name": "Клуб «Старлит»", "pos": lep + Vector2(0, 40)})
	for key in SCN.SPAWN_ORDER:
		if String(key) in ["random", "home"]:
			continue
		var sp: Dictionary = SCN.SPAWNS[key]
		out.append({"group": "Леса и биомы", "name": String(sp["name"]), "key": String(key), "pos": Vector2.INF})
	return out


## Открыть всё в книге: растения, грибы, еда (и рыба). Для режима бога.
static func unlock_book() -> int:
	var n: int = 0
	for id in DB.DATA.keys():
		Game.discovered[String(id)] = true
		Game.researched[String(id)] = true
		n += 1
	for id2 in WDB.SHROOMS.keys():
		Game.discovered[String(id2)] = true
		n += 1
	for fk in FD.DATA.keys():
		Game.discovered["food_" + String(fk)] = true
		n += 1
	for fi in FDB.DATA.keys():
		if int(Game.fish_caught.get(String(fi), 0)) <= 0:
			Game.fish_caught[String(fi)] = 1
		Game.discovered[String(fi)] = true
		n += 1
	Game.inventory_changed.emit()
	return n
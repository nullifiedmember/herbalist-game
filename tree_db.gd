extends RefCounted
## Деревья v17: что можно снять с веток (листья, плоды), свойства листьев и насекомых для котла.
## Листья — предметы "leaf_<дерево>" (например leaf_tree_apple), плоды — еда "food_<id>".

# дерево -> [название листа, свойства в котле, плоды [[еда, вес]...], сколько плодов за раз на ветке (0-N), дней до нового плода]
const TREES: Dictionary = {
	"tree_a": ["Дубовый лист", {"Сила": 1, "Тепло": 1}, [["acorn", 1.0]], 2, 3],
	"tree_b": ["Липовый лист", {"Тепло": 1, "Покой": 1}, [], 0, 3],
	"tree_c": ["Вязовый лист", {"Исцеление": 1}, [["hazelnut", 1.0]], 2, 3],
	"tree_d": ["Ясеневый лист", {"Свежесть": 1, "Сила": 1}, [["walnut", 1.0]], 2, 3],
	"pine_a": ["Сосновая хвоя", {"Свежесть": 1, "Холод": 1}, [["pine_nut", 1.0]], 1, 4],
	"pine_b": ["Еловая хвоя", {"Холод": 1, "Исцеление": 1}, [["spruce_tips", 1.0]], 2, 3],
	"tree_blossom": ["Лепесток сакуры", {"Чары": 1, "Покой": 1}, [["sakura_plum", 0.6], ["cherry", 0.4]], 2, 3],
	"tree_autumn": ["Кленовый лист", {"Огонь": 1, "Тепло": 1}, [["maple_syrup", 1.0]], 1, 4],
	"tree_autumn2": ["Рябиновый лист", {"Исцеление": 1, "Жгучесть": 1}, [["rowan", 1.0]], 3, 3],
	"tree_apple": ["Яблоневый лист", {"Свежесть": 1, "Исцеление": 1}, [["apple", 0.6], ["apple_green", 0.3], ["apple_golden", 0.1]], 3, 3],
	"tree_birch": ["Берёзовый лист", {"Свежесть": 2}, [["birch_sap", 1.0]], 1, 2],
	"tree_unicorn": ["Розовый лист", {"Свет": 1, "Чары": 1}, [["pink_apple", 1.0]], 2, 4],
}

# насекомые в котле (id вида из insects_db.gd)
const BUG_PROPS: Dictionary = {
	"bee": {"Тепло": 1, "Исцеление": 1},
	"butterfly_white": {"Свежесть": 1, "Свет": 1},
	"butterfly_orange": {"Огонь": 1, "Тепло": 1},
	"butterfly_blue": {"Холод": 1, "Покой": 1},
	"butterfly_yellow": {"Свет": 1, "Тепло": 1},
	"ladybug": {"Исцеление": 1, "Сила": 1},
	"aphid": {"Жгучесть": 1},
	"dung_beetle": {"Тьма": 1, "Сила": 1},
	"mosquito": {"Жгучесть": 1, "Тьма": 1},
	"dragonfly": {"Свежесть": 1, "Холод": 1},
	"firefly": {"Свет": 2},
	"grasshopper": {"Сила": 1, "Жгучесть": 1},
	"moth": {"Сон": 1, "Тьма": 1},
}


static func has(tex: String) -> bool:
	return TREES.has(tex)


static func leaf_id(tex: String) -> String:
	return "leaf_" + tex


static func is_leaf(id: String) -> bool:
	return id.begins_with("leaf_") and TREES.has(id.substr(5))


static func leaf_name(id: String) -> String:
	return String((TREES[id.substr(5)] as Array)[0]) if is_leaf(id) else id


static func leaf_icon(id: String) -> Texture2D:
	return load("res://art/leaf_%s.png" % id.substr(5))


static func tree_name(tex: String) -> String:
	return String(preload("res://items_db.gd").TREE_NAMES.get(tex, "дерево"))


## Свойства листа или насекомого для котла (пусто — это не такой ингредиент)
static func ing_props(id: String) -> Dictionary:
	if is_leaf(id):
		return (TREES[id.substr(5)] as Array)[1].duplicate()
	if id.begins_with("bug_") and BUG_PROPS.has(id.substr(4)):
		return (BUG_PROPS[id.substr(4)] as Dictionary).duplicate()
	# v20: перья, шерсть, усы, самоцветы, смола... — из mats_db
	return preload("res://mats_db.gd").props(id)


static func is_ingredient(id: String) -> bool:
	return is_leaf(id) or (id.begins_with("bug_") and BUG_PROPS.has(id.substr(4))) or preload("res://mats_db.gd").is_ingredient(id)


## Выбрать плод для дерева по весам (случайный)
static func pick_fruit(tex: String, r: float) -> String:
	if not TREES.has(tex):
		return ""
	var fl: Array = (TREES[tex] as Array)[2]
	if fl.is_empty():
		return ""
	var tot: float = 0.0
	for e in fl:
		tot += float(e[1])
	var x: float = r * tot
	for e in fl:
		x -= float(e[1])
		if x <= 0.0:
			return "food_" + String(e[0])
	return "food_" + String((fl[0] as Array)[0])

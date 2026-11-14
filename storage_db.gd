extends RefCounted
## v24: сундуки разных размеров и «для чего» каждый сундук. Работницы сами раскладывают добычу по сундукам
## с подходящим назначением; сундук «всё подряд» берёт что угодно.

const IT = preload("res://items_db.gd")
const MT = preload("res://mats_db.gd")
const DB = preload("res://herbs_db.gd")
const W = preload("res://wild_db.gd")
const RDB = preload("res://recipes_db.gd")
const FDB = preload("res://fish_db.gd")
const V23 = preload("res://v23_data.gd")

## вид постройки -> [название, столбцов, строк, клетка в пикселях окна, картинка]
const KINDS: Dictionary = {
	"chest_small": ["Маленький сундук", 6, 4, 60.0, "chest_small24"],
	"chest_mid": ["Средний сундук", 9, 6, 60.0, "chest_mid24"],
	"chest": ["Большой сундук", 12, 12, 56.0, "dp_chest_small"],
	"chest_big": ["Огромный сундук", 14, 10, 56.0, "chest_big24"],
	"storage_crate": ["Ящик для материалов", 8, 6, 60.0, "mine_crate"],
	"warehouse": ["Склад", 24, 16, 44.0, "warehouse24"],
}

## назначение сундука: ключ -> [название, значок]
const CATS: Array = [
	["all", "Всё подряд", "icon_pack"],
	["herbs", "Травы", "herb14_calendula"],
	["shrooms", "Грибы", "shroom_chanterelle"],
	["food", "Еда и продукты", "food_bread"],
	["potions", "Зелья и основы", "icon_bottle"],
	["weapons", "Оружие", "gear_wpn_sword_iron"],
	["gear", "Одежда и инструменты", "gear_axe"],
	["wood", "Дерево и ветки", "icon_log"],
	["stone", "Камни, руды и металлы", "icon_stone_m"],
	["mats", "Ткани, нитки и прочие материалы", "m20_linen"],
	["fish", "Рыба", "fish_crucian"],
	["bugs", "Насекомые и перья", "icon_feather_blackbird"],
	["seeds", "Семена и саженцы", "icon_sapling"],
	["furn", "Мебель и наборы построек", "workbench"],
]


static func cat_name(c: String) -> String:
	for e in CATS:
		if String(e[0]) == c:
			return String(e[1])
	return "Всё подряд"


static func cat_icon(c: String) -> Texture2D:
	for e in CATS:
		if String(e[0]) == c:
			var p: String = "res://art/%s.png" % String(e[2])
			if ResourceLoader.exists(p):
				return load(p)
	return load("res://art/icon_pack.png")


## К какому назначению относится вещь
static func category(id: String) -> String:
	if id.begins_with("dry:") or DB.DATA.has(id):
		return "herbs"
	if W.is_shroom(id):
		return "shrooms"
	if IT.is_weapon(id):
		return "weapons"
	if IT.is_furn(id) or id.begins_with("kit:"):
		return "furn"
	if id.begins_with("sapling:") or id.begins_with("seed"):
		return "seeds"
	if IT.is_bug(id) or id.begins_with("feather_"):
		return "bugs"
	if FDB.is_fish(id):
		return "fish"
	if RDB.is_product(id) or id in ["bottle", "water_cold", "water_warm", "water_hot", "wax", "spirit", "moon_dew"]:
		return "potions"
	if IT.is_food(id) or V23.PRODUCTS.has(id) or id == "honey" or IT.is_leaf(id):
		return "food"
	if id in ["log", "branch_long"]:
		return "wood"
	if id.begins_with("stone_") or id.begins_with("ore_") or id in ["iron_bar", "horseshoe"]:
		return "stone"
	if MT.has(id):
		var g: String = MT.cat(id)
		if g == "wood":
			return "wood"
		if g in ["metal", "gem", "stone", "earth", "glass"]:
			return "stone"
		if g == "feather":
			return "bugs"
		return "mats"
	if IT.is_gear(id):
		return "gear"
	return "mats"


static func accepts(filter: String, id: String) -> bool:
	return filter == "all" or filter == "" or category(id) == filter


static func is_chest(kind: String) -> bool:
	return KINDS.has(kind)

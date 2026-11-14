extends RefCounted
## Камни и руды (v18): размеры камней, магические руды, где что лежит, сколько ударов киркой.
## Арт: tools/aseprite/gen_stone.lua (rock18_*, ore18_*, icon_ore_*, icon_stone_*, gear_pickaxe).

# Биомы (номера как в world_data.gd)
const HOME := 0
const MEADOW := 1
const SPIDER := 2
const GOTHIC := 3
const KNIGHT := 4
const ELF := 5
const MAGE := 6
const ORC := 7
const DWARF := 8
const CATS := 9
const UNICORN := 10
const GROTTO := 11
const BIRCH := 12
const PINE := 13
const AUTUMN := 14
const SWAMP := 15
const FIELD := 16
const JAPAN := 17
const BEACH := 18

## Размеры: s — маленькие, m — средние, l — большие, h — огромные (только киркой)
const SIZES: Dictionary = {
	"s": {"name": "Маленький камушек", "w": 0.4, "price": 1, "hand": true, "hits": 1, "r": 8.0},
	"m": {"name": "Средний камень", "w": 2.0, "price": 3, "hand": true, "hits": 1, "r": 12.0},
	"l": {"name": "Большой камень", "w": 6.0, "price": 8, "hand": true, "hits": 4, "r": 20.0},
	"h": {"name": "Огромный валун", "w": 0.0, "price": 0, "hand": false, "hits": 9, "r": 52.0},
}

## Руды: название, цена за штуку, вес, ударов киркой, в каких биомах лежит (биом: вес)
const ORES: Dictionary = {
	"mana": {"name": "Мана-кристалл", "price": 55, "w": 0.8, "hits": 6, "biomes": {GROTTO: 3, MAGE: 4, UNICORN: 2}, "desc": "Тихо гудит. Из него делают чары и сильные зелья."},
	"frost": {"name": "Морозный сапфир", "price": 48, "w": 0.8, "hits": 6, "biomes": {PINE: 3, GROTTO: 1, DWARF: 2}, "desc": "Холодный даже в тёплой руке."},
	"ember": {"name": "Огненный рубин", "price": 52, "w": 0.8, "hits": 7, "biomes": {DWARF: 4, ORC: 2, GROTTO: 1}, "desc": "Внутри тлеет уголёк, который никогда не гаснет."},
	"verdant": {"name": "Живой изумруд", "price": 50, "w": 0.8, "hits": 6, "biomes": {SWAMP: 3, ELF: 2, UNICORN: 1, BIRCH: 1}, "desc": "На ощупь как мох, а внутри что-то растёт."},
	"void": {"name": "Бездонный камень", "price": 70, "w": 0.8, "hits": 8, "biomes": {GOTHIC: 3, SPIDER: 2, GROTTO: 2}, "desc": "Смотришь в него — а он смотрит в ответ."},
	"moonsilver": {"name": "Лунное серебро", "price": 60, "w": 0.6, "hits": 6, "biomes": {GROTTO: 2, MAGE: 2, KNIGHT: 1, PINE: 1}, "desc": "Серебро, которое светится в полнолуние."},
	"sunstone": {"name": "Солнечное золото", "price": 65, "w": 0.6, "hits": 6, "biomes": {DWARF: 3, FIELD: 1, ORC: 1, JAPAN: 1, AUTUMN: 1}, "desc": "Тёплое самородное золото, пахнет летом."},
	"star": {"name": "Звёздный осколок", "price": 95, "w": 0.4, "hits": 9, "biomes": {MAGE: 2, UNICORN: 1, GROTTO: 1}, "desc": "Упал с неба. Редкая находка."},
}
const ORE_ORDER: Array = ["mana", "frost", "ember", "verdant", "void", "moonsilver", "sunstone", "star"]

## Сколько камней на область (1920x1280): [маленьких, средних, больших, огромных, месторождений руды]
const DENSITY_DEFAULT: Array = [10, 5, 2, 1, 1]
const DENSITY: Dictionary = {
	MEADOW: [10, 4, 1, 0, 0], FIELD: [8, 4, 1, 0, 0], BEACH: [5, 3, 1, 0, 0], CATS: [8, 4, 1, 0, 0],
	GROTTO: [22, 12, 8, 4, 4], DWARF: [22, 12, 8, 5, 5], MAGE: [14, 8, 4, 2, 3], PINE: [16, 8, 4, 2, 1],
	ORC: [14, 8, 4, 2, 2], GOTHIC: [12, 6, 3, 2, 2], UNICORN: [10, 5, 3, 1, 2], AUTUMN: [12, 6, 3, 1, 1],
	SWAMP: [8, 4, 2, 1, 1], JAPAN: [8, 4, 2, 1, 1],
}
## Тёплые (бурые) камни — в этих биомах
const WARM: Array = [ORC, FIELD, BEACH, AUTUMN, DWARF, MEADOW]


static func is_mineral(id: String) -> bool:
	return id.begins_with("stone_") or id.begins_with("ore_")


static func ore_of(id: String) -> String:
	return id.substr(4) if id.begins_with("ore_") else ""


static func price(id: String) -> int:
	if id.begins_with("stone_"):
		return int((SIZES.get(id.substr(6), {}) as Dictionary).get("price", 1))
	var o: String = ore_of(id)
	if o != "" and ORES.has(o):
		return int((ORES[o] as Dictionary)["price"])
	return 1


static func item_name(id: String) -> String:
	if id.begins_with("stone_"):
		return String((SIZES.get(id.substr(6), {}) as Dictionary).get("name", "Камень"))
	var o: String = ore_of(id)
	if o != "" and ORES.has(o):
		return String((ORES[o] as Dictionary)["name"])
	return id


static func weight(id: String) -> float:
	if id.begins_with("stone_"):
		return float((SIZES.get(id.substr(6), {}) as Dictionary).get("w", 1.0))
	var o: String = ore_of(id)
	if o != "" and ORES.has(o):
		return float((ORES[o] as Dictionary)["w"])
	return 1.0


## Руда по биому (с учётом весов): id или ""
static func pick_ore(biome: int, rng: RandomNumberGenerator) -> String:
	var bag: Array = []
	for id in ORE_ORDER:
		var w: int = int(((ORES[id] as Dictionary)["biomes"] as Dictionary).get(biome, 0))
		for i in range(w):
			bag.append(id)
	# v20: обычные металлы (медь, олово, железо, серебро, золото...) — чаще волшебных
	var dep: Dictionary = preload("res://mats_db.gd").ORE_DEPOSITS
	for mid in dep.keys():
		var w2: int = int((dep[mid] as Dictionary).get(biome, 0)) * 2
		for j in range(w2):
			bag.append(String(mid))
	if bag.is_empty():
		return ""
	return String(bag[rng.randi_range(0, bag.size() - 1)])


## Все предметы-минералы: для режима бога и тестов
static func all_item_ids() -> Array:
	var out: Array = ["stone_s", "stone_m", "stone_l"]
	for id in ORE_ORDER:
		out.append("ore_" + String(id))
	return out


## Сколько ударов киркой у месторождения (у новых металлов — по редкости)
static func ore_hits(id: String) -> int:
	if ORES.has(id):
		return int((ORES[id] as Dictionary)["hits"])
	return {"copper": 3, "tin": 3, "zinc": 3, "lead": 3, "iron": 4, "nickel": 4, "silver": 5, "gold": 5, "cobalt": 6, "mithril": 7, "adamant": 8, "orichalcum": 7}.get(id, 4)

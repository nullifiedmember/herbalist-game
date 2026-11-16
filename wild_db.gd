extends RefCounted
## Дикая природа: какие звери и грибы живут в каком биоме, их шансы и условия.

const WD = preload("res://world_data.gd")
const F25 = preload("res://fauna25_db.gd")
const S25 = preload("res://shrooms25_db.gd")

# Звери: имя, ширина кадра, высота, скорость, пугливость (бежит от героини), можно погладить
const ANIMALS_BASE: Dictionary = {
	"rabbit": {"name": "Кролик", "w": 55, "h": 57, "speed": 40.0, "shy": true, "pet": true, "sound": "squeak"},
	"fox": {"name": "Лиса", "w": 71, "h": 44, "speed": 46.0, "shy": true, "pet": false, "sound": "sniff"},
	"deer": {"name": "Олень", "w": 73, "h": 58, "speed": 50.0, "shy": true, "pet": false, "sound": ""},
	"boar": {"name": "Кабан", "w": 66, "h": 45, "speed": 34.0, "shy": false, "pet": false, "sound": "grunt"},
	"flat_boar": {"name": "Сплющенный кабан", "w": 60, "h": 48, "speed": 22.0, "shy": false, "pet": true, "sound": "grunt"},
	"hedgehog": {"name": "Ёжик", "w": 64, "h": 35, "speed": 14.0, "shy": false, "pet": true, "sound": "sniff"},
	"squirrel": {"name": "Белка", "w": 67, "h": 45, "speed": 44.0, "shy": true, "pet": false, "sound": "squeak"},
	"duck": {"name": "Утка", "w": 54, "h": 39, "speed": 20.0, "shy": false, "pet": true, "sound": "quack"},
	"sapphire_hare": {"name": "Сапфировый заяц", "w": 61, "h": 48, "speed": 60.0, "shy": true, "pet": true, "sound": "magic", "mythic": true},
	"unicorn": {"name": "Единорог", "w": 89, "h": 62, "speed": 44.0, "shy": false, "pet": true, "sound": "neigh", "mythic": true},
	"golden_deer": {"name": "Золотой олень", "w": 77, "h": 65, "speed": 56.0, "shy": true, "pet": true, "sound": "magic", "mythic": true},
	"ember_fox": {"name": "Угольная лиса", "w": 71, "h": 44, "speed": 52.0, "shy": true, "pet": true, "sound": "magic", "mythic": true},
	# v23: домашние звери (приманить едой, в загоне дают яйца, молоко, шерсть)
	"chicken": {"name": "Курочка", "w": 55, "h": 41, "speed": 22.0, "shy": false, "pet": true, "sound": "squeak", "farm": true},
	"cow": {"name": "Корова", "w": 78, "h": 51, "speed": 16.0, "shy": false, "pet": true, "sound": "grunt", "farm": true},
	"sheep": {"name": "Овечка", "w": 62, "h": 38, "speed": 20.0, "shy": false, "pet": true, "sound": "squeak", "farm": true},
	"goat": {"name": "Козочка", "w": 61, "h": 43, "speed": 26.0, "shy": false, "pet": true, "sound": "squeak", "farm": true},
	"pig": {"name": "Свинка", "w": 64, "h": 40, "speed": 20.0, "shy": false, "pet": true, "sound": "grunt", "farm": true},
	"goose": {"name": "Гусь", "w": 65, "h": 53, "speed": 22.0, "shy": false, "pet": true, "sound": "quack", "farm": true},
}

# Кто живёт в биоме: [зверь, сколько в области]; мифические — [зверь, шанс появиться]
const FAUNA_BASE: Dictionary = {
	WD.MEADOW: [["rabbit", 5], ["hedgehog", 2], ["duck", 2], ["chicken", 3], ["sheep", 2]],
	WD.FIELD: [["rabbit", 6], ["hedgehog", 2], ["flat_boar", 2], ["cow", 2], ["pig", 2], ["goat", 2], ["goose", 2]],
	WD.BIRCH: [["deer", 3], ["squirrel", 4], ["hedgehog", 2], ["fox", 2]],
	WD.PINE: [["boar", 3], ["squirrel", 3], ["deer", 2], ["fox", 2], ["flat_boar", 2]],
	WD.AUTUMN: [["boar", 3], ["deer", 3], ["hedgehog", 3], ["squirrel", 2], ["flat_boar", 2]],
	WD.SWAMP: [["duck", 6], ["boar", 2], ["flat_boar", 3]],
	WD.UNICORN: [["rabbit", 4], ["deer", 2], ["unicorn", 3]],
	WD.GROTTO: [["flat_boar", 4], ["hedgehog", 2]],
	WD.ELF: [["deer", 3], ["rabbit", 3], ["squirrel", 2], ["goat", 2]],
	WD.KNIGHT: [["rabbit", 3], ["duck", 2], ["cow", 2], ["sheep", 2]],
	WD.ORC: [["boar", 3], ["flat_boar", 3]],
	WD.SPIDER: [["hedgehog", 2]],
	WD.MAGE: [["rabbit", 3]],
	WD.DWARF: [["boar", 2], ["flat_boar", 2]],
	WD.GOTHIC: [["fox", 2]],
	WD.CATS: [["duck", 2], ["rabbit", 2], ["chicken", 3]],
	WD.JAPAN: [["fox", 4], ["squirrel", 3], ["deer", 2], ["chicken", 2]],
	WD.BEACH: [["duck", 3]],
}
const MYTHIC_BASE: Dictionary = {
	WD.UNICORN: [["sapphire_hare", 0.6], ["unicorn", 0.5]],
	WD.MAGE: [["sapphire_hare", 0.35]],
	WD.ELF: [["golden_deer", 0.3]],
	WD.BIRCH: [["golden_deer", 0.12]],
	WD.GROTTO: [["ember_fox", 0.4]],
	WD.AUTUMN: [["ember_fox", 0.15]],
	WD.FIELD: [["sapphire_hare", 0.1]],
}

# Грибы: название, биомы, шанс вырасти на месте, часы (с, по; через полночь — с > по), цена, сытость, условие (текст)
const SHROOMS_BASE: Dictionary = {
	"porcini": {"name": "Белый гриб", "biomes": [WD.AUTUMN, WD.BIRCH, WD.PINE], "chance": 0.35, "hours": [0, 24], "price": 12, "food": 0.35, "need": "растёт в осенних, берёзовых и хвойных лесах"},
	"birch_bolete": {"name": "Подберёзовик", "biomes": [WD.BIRCH], "chance": 0.5, "hours": [0, 24], "price": 7, "food": 0.3, "need": "только под берёзами"},
	"chanterelle": {"name": "Лисичка", "biomes": [WD.PINE, WD.BIRCH], "chance": 0.4, "hours": [5, 12], "price": 8, "food": 0.25, "need": "показывается по утрам, с 5 до 12"},
	"fly_agaric": {"name": "Мухомор", "biomes": [WD.PINE, WD.AUTUMN, WD.GOTHIC], "chance": 0.3, "hours": [0, 24], "price": 4, "food": -0.2, "need": "ядовитый! есть нельзя, только для зелий"},
	"glow_cap": {"name": "Светящаяся шляпка", "biomes": [WD.GROTTO, WD.SPIDER], "chance": 0.5, "hours": [20, 5], "price": 15, "food": 0.15, "need": "светится только ночью, с 20 до 5, в гротах и паутинной чаще"},
	"moon_shroom": {"name": "Лунный гриб", "biomes": [WD.UNICORN, WD.MAGE], "chance": 0.15, "hours": [22, 4], "price": 40, "food": 0.2, "need": "редкий, только глубокой ночью (22-4), в лесу единорогов и долине магов"},
	"swamp_honey": {"name": "Болотный опёнок", "biomes": [WD.SWAMP], "chance": 0.45, "hours": [0, 24], "price": 6, "food": 0.3, "need": "растёт на болоте"},
	"web_shroom": {"name": "Паутинник", "biomes": [WD.SPIDER], "chance": 0.4, "hours": [0, 24], "price": 9, "food": 0.2, "need": "только в паутинной чаще"},
	"blood_russula": {"name": "Кровавая сыроежка", "biomes": [WD.GOTHIC], "chance": 0.35, "hours": [18, 6], "price": 14, "food": 0.25, "need": "появляется в Сумеречье с вечера до утра (18-6)"},
	"elf_star": {"name": "Эльфийская звёздочка", "biomes": [WD.ELF], "chance": 0.3, "hours": [0, 24], "price": 18, "food": 0.2, "need": "растёт только в лесу эльфов"},
	"morel": {"name": "Сморчок", "biomes": [WD.MEADOW, WD.FIELD], "chance": 0.25, "hours": [5, 10], "price": 10, "food": 0.3, "need": "на лугах и полях, только ранним утром (5-10)"},
	"field_champignon": {"name": "Луговой шампиньон", "biomes": [WD.FIELD, WD.MEADOW, WD.CATS], "chance": 0.4, "hours": [0, 24], "price": 5, "food": 0.35, "need": "на полях и лугах"},
}


# v25: старые звери и грибы + новые (fauna25_db / shrooms25_db генерируются скриптами в tools)
static var ANIMALS: Dictionary = _merge(ANIMALS_BASE, F25.ANIMALS)
static var FAUNA: Dictionary = _merge_lists(FAUNA_BASE, F25.FAUNA)
static var MYTHIC_SPAWN: Dictionary = _merge_lists(MYTHIC_BASE, F25.MYTHIC_SPAWN)
static var SHROOMS: Dictionary = _merge(SHROOMS_BASE, S25.SHROOMS)


static func _merge(a: Dictionary, b: Dictionary) -> Dictionary:
	var r: Dictionary = a.duplicate()
	for k in b.keys():
		r[k] = b[k]
	return r


static func _merge_lists(a: Dictionary, b: Dictionary) -> Dictionary:
	var r: Dictionary = {}
	for k in a.keys():
		r[k] = (a[k] as Array).duplicate()
	for k2 in b.keys():
		if not r.has(k2):
			r[k2] = []
		(r[k2] as Array).append_array(b[k2] as Array)
	return r


## v25: на ком можно ездить (приручить и оседлать)
static func rideable(id: String) -> bool:
	return bool((ANIMALS.get(id, {}) as Dictionary).get("ride", false))


static func is_shroom(id: String) -> bool:
	return SHROOMS.has(id)


static func shroom_name(id: String) -> String:
	return String((SHROOMS[id] as Dictionary)["name"]) if SHROOMS.has(id) else id


static func shroom_icon(id: String) -> Texture2D:
	return load("res://art/shroom_%s.png" % id)


static func hour_ok(id: String, h: float) -> bool:
	var hr: Array = (SHROOMS[id] as Dictionary)["hours"]
	var a: float = float(hr[0])
	var b: float = float(hr[1])
	if a <= b:
		return h >= a and h < b
	return h >= a or h < b


## Грибы, которые могут расти в биоме
static func shrooms_for(biome: int) -> Array:
	var res: Array = []
	for id in SHROOMS.keys():
		if ((SHROOMS[id] as Dictionary)["biomes"] as Array).has(biome):
			res.append(id)
	return res

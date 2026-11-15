extends RefCounted
## Новые предметы (брёвна, топор, саженцы, наборы построек), их вес и значки.
## Вес остальных предметов: травы, зелья, рыба, грибы — по своему виду.

const DB = preload("res://herbs_db.gd")
const RDB = preload("res://recipes_db.gd")
const FDB = preload("res://fish_db.gd")
const W = preload("res://wild_db.gd")

const CAPACITY: float = 30.0      # сколько героиня несёт без рюкзака (рюкзак, пояс, плащ — прибавляют)

const ITEMS: Dictionary = {
	"log": ["Бревно", 3.0, "icon_log"],
	"axe": ["Топор", 2.0, "icon_axe"],
	# основы для котла (v16)
	"bottle": ["Пустая бутылочка", 0.3, "icon_bottle"],
	"water_cold": ["Холодная вода", 1.0, "icon_water_cold"],
	"water_warm": ["Тёплая вода", 1.0, "icon_water_warm"],
	"water_hot": ["Горячая вода", 1.0, "icon_water_hot"],
	"wax": ["Пчелиный воск", 0.5, "icon_wax"],
	"spirit": ["Спирт", 1.0, "icon_spirit"],
	"honey": ["Горшочек мёда", 1.0, "icon_honey"],
	"moon_dew": ["Лунная роса", 0.5, "icon_moon_dew"],
	# v18: камни и магические руды (mining_db.gd), письмо для заданий
	"stone_s": ["Маленький камушек", 0.4, "icon_stone_s"],
	"stone_m": ["Средний камень", 2.0, "icon_stone_m"],
	"stone_l": ["Большой камень", 6.0, "icon_stone_l"],
	"ore_mana": ["Мана-кристалл", 0.8, "icon_ore_mana"],
	"ore_frost": ["Морозный сапфир", 0.8, "icon_ore_frost"],
	"ore_ember": ["Огненный рубин", 0.8, "icon_ore_ember"],
	"ore_verdant": ["Живой изумруд", 0.8, "icon_ore_verdant"],
	"ore_void": ["Бездонный камень", 0.8, "icon_ore_void"],
	"ore_moonsilver": ["Лунное серебро", 0.6, "icon_ore_moonsilver"],
	"ore_sunstone": ["Солнечное золото", 0.6, "icon_ore_sunstone"],
	"ore_star": ["Звёздный осколок", 0.4, "icon_ore_star"],
	"quest_letter": ["Письмо", 0.05, "icon_letter"],
	# ранний доступ: кузница (paths_db.gd SMITH_ITEMS — цены и описания)
	"iron_bar": ["Железный брусок", 1.5, "icon_iron_bar"],
	"horseshoe": ["Подкова", 0.5, "icon_horseshoe"],
	"guard_sword": ["Меч стражи", 2.5, "icon_guard_sword"],
	"tourney_spear": ["Турнирное копьё", 3.0, "icon_tourney_spear"],
	"round_shield": ["Круглый щит", 3.0, "icon_round_shield"],
	"helmet": ["Шлем", 2.0, "icon_helmet"],
	"star_blade": ["Звёздный клинок", 2.0, "icon_star_blade"],
	"iron_pot": ["Железный котелок", 2.5, "icon_iron_pot"],
}
## Цены и описания простых товаров на полках (у снаряжения — свои в GEAR)
const PRICE: Dictionary = {"bottle": 3, "wax": 5, "spirit": 7, "honey": 6, "moon_dew": 24}
const PACK: Dictionary = {"bottle": 3}     # сколько штук даёт одна покупка
const DESC: Dictionary = {
	"bottle": "Три пустые бутылочки. Набери в них воды у колодца.",
	"water_cold": "Студёная вода из колодца.",
	"water_warm": "Согрелась у костра.",
	"water_hot": "Горячая, только с огня. Остывает со временем.",
	"wax": "Основа для мазей.",
	"spirit": "Основа для настоек.",
	"honey": "Основа для сиропов.",
	"moon_dew": "Роса с лунных цветов. Основа для эликсиров.",
}
## Основы: предмет -> [основа в котле, температура (0..2, -1 — не вода), что остаётся после]
const BASE_ITEMS: Dictionary = {
	"water_cold": ["water", 0.0, "bottle"], "water_warm": ["water", 1.0, "bottle"], "water_hot": ["water", 2.0, "bottle"],
	"spirit": ["spirit", -1.0, "bottle"], "moon_dew": ["moon_dew", -1.0, "bottle"], "wax": ["wax", -1.0, ""], "honey": ["honey", -1.0, ""],
}

# Снаряжение. slot: tool (обе руки), off (вторая рука), head, body, hands, feet, neck, ring, belt, pack.
# stats: cap — вес, speed — % скорости, herb / shroom — % шанс собрать вдвое больше,
# sell — % к цене продажи, brew — % шанс двух зелий, hunger / thirst — % к скорости голода/жажды (минус — медленнее),
# light — свет вокруг ночью, seed — % шанс найти семечко у дикой травы, fish_w / herb_w / shroom_w / potion_w — множитель веса.
# rows — сколько рядов открывает рюкзак (в сетке 12×5), flasks — ячеек зелий у пояса, price — цена в лавке.
const GEAR_BASE: Dictionary = {
	# ---- инструменты для сбора
	"axe": {"name": "Топор", "slot": "tool", "w": 2.0, "price": 30, "stats": {}, "desc": "Рубит деревья: брёвна и саженцы."},
	"sickle": {"name": "Серп травницы", "slot": "tool", "w": 1.0, "price": 24, "stats": {"herb": 35}, "desc": "Срезает травы под корень — часто выходит две."},
	"gold_sickle": {"name": "Золотой серп", "slot": "tool", "w": 1.0, "price": 160, "stats": {"herb": 70, "sell": 5}, "desc": "Серп друидов. Травы так и просятся в руки."},
	"net": {"name": "Сачок", "slot": "tool", "w": 0.6, "price": 15, "stats": {}, "desc": "Взмах на E — и бабочка в сумке."},
	"knife": {"name": "Нож грибника", "slot": "tool", "w": 0.5, "price": 18, "stats": {"shroom": 40}, "desc": "Гриб срезан, грибница цела — рядом вырастет второй."},
	"trowel": {"name": "Садовый совок", "slot": "tool", "w": 1.0, "price": 16, "stats": {"seed": 35}, "desc": "Выкапывает дикие травы с семенами."},
	"pickaxe": {"name": "Кирка", "slot": "tool", "w": 3.0, "price": 42, "stats": {}, "desc": "Ломает огромные валуны и добывает руду. Большие камни тоже крошит."},
	"shovel": {"name": "Лопата", "slot": "tool", "w": 2.5, "price": 28, "stats": {"seed": 25, "herb": 10}, "desc": "Тяжёлая, но с ней и корни, и семена."},
	# ---- вторая рука
	"lantern_hand": {"name": "Ручной фонарь", "slot": "off", "w": 1.5, "price": 26, "stats": {"light": 1}, "desc": "Светит вокруг ночью."},
	"torch": {"name": "Факел", "slot": "off", "w": 0.8, "price": 4, "stats": {"light": 0.5}, "desc": "Возьми во вторую руку — и ночью будет светло вокруг. Фонарь светит шире."},
	"herbarium": {"name": "Гербарий", "slot": "off", "w": 1.0, "price": 40, "stats": {"sell": 15}, "desc": "Всё о травах: торговки платят больше."},
	# ---- голова
	"hat_straw": {"name": "Соломенная шляпа", "slot": "head", "w": 0.3, "price": 12, "stats": {"thirst": -15}, "desc": "Солнце не печёт — пить хочется реже."},
	"wreath": {"name": "Травяной венок", "slot": "head", "w": 0.1, "price": 20, "stats": {"herb": 10}, "desc": "Травы чуют свою."},
	"hood": {"name": "Капюшон странницы", "slot": "head", "w": 0.4, "price": 22, "stats": {"speed": 4}, "desc": "Ветер в лицо не дует."},
	"goggles": {"name": "Очки-лупы", "slot": "head", "w": 0.2, "price": 45, "stats": {"herb": 10, "shroom": 10}, "desc": "Видно каждую прожилку листа."},
	"witch_hat": {"name": "Шляпа зельевара", "slot": "head", "w": 0.4, "price": 38, "stats": {"brew": 10}, "desc": "Пар от котла не лезет в глаза."},
	# ---- одежда
	"rags": {"name": "Рваная одежда", "slot": "body", "w": 0.5, "price": 2, "stats": {}, "desc": "Заплатка на заплатке. Зато своя."},
	"dress": {"name": "Платье травницы", "slot": "body", "w": 1.0, "price": 30, "stats": {"herb": 5, "cap": 2}, "desc": "Много кармашков для листиков."},
	"cloak_travel": {"name": "Плащ странницы", "slot": "body", "w": 1.5, "price": 48, "stats": {"speed": 5, "cap": 4}, "desc": "Тёплый, лёгкий, в нём хоть на край света."},
	"lab_coat": {"name": "Мантия исследовательницы", "slot": "body", "w": 1.2, "price": 55, "stats": {"sell": 10}, "desc": "Солидный вид — торговки уважают."},
	"apron": {"name": "Фартук зельевара", "slot": "body", "w": 0.8, "price": 35, "stats": {"brew": 15}, "desc": "В пятнах всех цветов радуги."},
	# ---- руки
	"gloves_garden": {"name": "Садовые перчатки", "slot": "hands", "w": 0.2, "price": 14, "stats": {"herb": 10}, "desc": "Крапива больше не жжётся."},
	"gloves_fire": {"name": "Огнеупорные перчатки", "slot": "hands", "w": 0.4, "price": 90, "stats": {}, "desc": "Из кожи саламандры. Огненные травы не жгут пальцы."},
	"gloves_leather": {"name": "Кожаные перчатки", "slot": "hands", "w": 0.3, "price": 20, "stats": {"shroom": 10, "cap": 1}, "desc": "Крепкие, для любой работы."},
	# ---- ноги
	"boots_old": {"name": "Старые башмаки", "slot": "feet", "w": 0.6, "price": 8, "stats": {"speed": 2}, "desc": "Стоптаны, но идти можно."},
	"boots_travel": {"name": "Сапоги странницы", "slot": "feet", "w": 0.8, "price": 50, "stats": {"speed": 10}, "desc": "Дорога сама ложится под ноги."},
	# ---- шея и кольца
	"amulet_clover": {"name": "Оберег-клевер", "slot": "neck", "w": 0.0, "price": 60, "stats": {"herb": 8, "shroom": 8}, "desc": "Четыре листика — к удаче."},
	"amulet_moon": {"name": "Лунный амулет", "slot": "neck", "w": 0.0, "price": 75, "stats": {"light": 1, "speed": 3}, "desc": "Тихо светится в темноте."},
	"ring_copper": {"name": "Медное кольцо", "slot": "ring", "w": 0.0, "price": 25, "stats": {"sell": 5}, "desc": "Торговки замечают блеск."},
	"ring_moss": {"name": "Моховое кольцо", "slot": "ring", "w": 0.0, "price": 30, "stats": {"hunger": -12}, "desc": "Лес кормит того, кто его носит."},
	"ring_amber": {"name": "Янтарное кольцо", "slot": "ring", "w": 0.0, "price": 40, "stats": {"brew": 8}, "desc": "Внутри застыла капля древнего зелья."},
	# ---- пояса
	"belt_rope": {"name": "Верёвочный пояс", "slot": "belt", "w": 0.2, "price": 6, "flasks": 3, "stats": {"cap": 2}, "desc": "Три петли для склянок."},
	"belt_leather": {"name": "Пояс с кармашками", "slot": "belt", "w": 0.5, "price": 34, "flasks": 5, "stats": {"cap": 5}, "desc": "Пять гнёзд для зелий и куча кармашков."},
	# ---- рюкзаки
	"pack_sack": {"name": "Котомка", "slot": "pack", "w": 0.5, "price": 15, "rows": 4, "stats": {"cap": 10}, "desc": "Простой мешок на лямке."},
	"pack_basket": {"name": "Корзина для грибов", "slot": "pack", "w": 1.0, "price": 22, "rows": 4, "stats": {"cap": 6, "shroom": 25, "shroom_w": 0.0}, "desc": "Грибы в ней ничего не весят и не мнутся."},
	"pack_herb": {"name": "Сумка травницы", "slot": "pack", "w": 0.6, "price": 36, "rows": 5, "stats": {"cap": 12, "herb_w": 0.5}, "desc": "Травы в отделениях — вдвое легче."},
	"pack_creel": {"name": "Рыбацкий садок", "slot": "pack", "w": 1.0, "price": 26, "rows": 4, "stats": {"cap": 8, "fish_w": 0.3}, "desc": "Плетёный короб: рыба почти не тянет плечи."},
	"pack_alch": {"name": "Ларец зельевара", "slot": "pack", "w": 1.5, "price": 44, "rows": 4, "stats": {"cap": 8, "potion_w": 0.0}, "desc": "Склянки в бархатных гнёздах ничего не весят."},
	"pack_travel": {"name": "Рюкзак странницы", "slot": "pack", "w": 1.5, "price": 70, "rows": 5, "stats": {"cap": 25}, "desc": "Большой, на раме. Влезет всё."},
}

## v23: всё снаряжение — старое + удочка + оружие (v23_data.gd, сотни видов)
const V23 = preload("res://v23_data.gd")
static var GEAR: Dictionary = _all_gear()


static func _all_gear() -> Dictionary:
	var out: Dictionary = GEAR_BASE.duplicate()
	out["rod"] = {"name": "Удочка", "slot": "tool", "w": 1.2, "price": 20, "stats": {}, "desc": "Сделана своими руками на верстаке. Подойди к воде и нажми E."}
	for wid in V23.WEAPON_ORDER:
		var w: Dictionary = V23.WEAPONS[wid]
		var d: String = String(w.get("desc", ""))
		if d == "":
			d = "Сила удара %d. %s" % [int(w["atk"]), "Бьёт издалека." if bool(w["ranged"]) else "Бьёт вблизи."]
		if String(w["fx"]) != "":
			d += "
" + String(V23.WEAPON_FX.get(String(w["fx"]), ""))
		out[wid] = {"name": String(w["name"]), "slot": "tool", "w": float(w["w"]), "price": int(w["price"]), "stats": {"atk": int(w["atk"])}, "desc": d, "wpn": true}
	return out


static func is_weapon(id: String) -> bool:
	return V23.WEAPONS.has(id)


static func is_furn(id: String) -> bool:
	return id.begins_with("furn:") and V23.FURN.has(id.substr(5))


## Новые простые предметы v23: продукты ферм, книги, приколы
static func v23_item(id: String) -> bool:
	return V23.BOOKS.has(id) or V23.JOKES.has(id) or V23.PRODUCTS.has(id)


# Какие слоты принимают какой вид вещи
const SLOT_KIND: Dictionary = {
	"main1": "tool", "off1": "off", "main2": "tool", "off2": "off", "head": "head", "body": "body", "hands": "hands",
	"feet": "feet", "neck": "neck", "ring1": "ring", "ring2": "ring", "belt": "belt", "pack": "pack",
}


static func gear(id: String) -> Dictionary:
	return GEAR.get(id, {})


static func is_gear(id: String) -> bool:
	return GEAR.has(id)


## Подходит ли вещь в слот (во вторую руку можно и инструмент; в ячейки пояса — зелья)
static func fits(id: String, slot: String) -> bool:
	if slot.begins_with("flask"):
		return RDB.is_product(id) and id != "murky"
	if not GEAR.has(id):
		return false
	var k: String = String(GEAR[id]["slot"])
	var want: String = String(SLOT_KIND.get(slot, ""))
	return k == want or (want == "off" and k == "tool")


## Свободный подходящий слот для вещи (для двойного клика / правой кнопки)
static func slot_for(id: String, eq: Dictionary, wset: int) -> String:
	if RDB.is_product(id) and id != "murky":
		for i in range(5):
			if String(eq.get("flask%d" % i, "")) == "":
				return "flask%d" % i
		return "flask0"
	if not GEAR.has(id):
		return ""
	var k: String = String(GEAR[id]["slot"])
	var s: String = str(wset + 1)
	match k:
		"tool":
			return "main" + s if String(eq.get("main" + s, "")) == "" or String(eq.get("off" + s, "")) != "" else "off" + s
		"off":
			return "off" + s
		"ring":
			return "ring1" if String(eq.get("ring1", "")) == "" or String(eq.get("ring2", "")) != "" else "ring2"
	return k


## Вес предмета в рюкзаке: корзина облегчает грибы, сумка — травы, садок — рыбу, ларец — зелья
static func weight_in(id: String, pack: String) -> float:
	var w: float = weight(id)
	if pack == "":
		return w
	var st: Dictionary = (GEAR.get(pack, {}) as Dictionary).get("stats", {})
	if W.is_shroom(id) and st.has("shroom_w"):
		return w * float(st["shroom_w"])
	if FDB.is_fish(id) and st.has("fish_w"):
		return w * float(st["fish_w"])
	if RDB.is_product(id) and st.has("potion_w"):
		return w * float(st["potion_w"])
	if DB.DATA.has(id) and st.has("herb_w"):
		return w * float(st["herb_w"])
	return w

# Постройки: название, картинка, цена (брёвна, монеты), вес набора, преграда (прямоугольник от ног)
const BUILD_BASE: Dictionary = {
	"workbench": ["Верстак", "workbench", 6, 0, 8.0, Rect2(-32, -18, 64, 16)],
	"table": ["Стол", "dp_table_round", 4, 0, 5.0, Rect2(-16, -16, 32, 14)],
	"research": ["Стол изучения трав", "research_table", 6, 10, 7.0, Rect2(-30, -18, 60, 16)],
	"pen": ["Загон для зверей", "animal_pen", 10, 0, 10.0, Rect2()],
	"chest": ["Сундук", "dp_chest_small", 5, 0, 5.0, Rect2(-14, -12, 28, 12)],
	"plot": ["Грядка", "", 2, 0, 2.0, Rect2()],
	"cauldron": ["Котёл для зелий", "cauldron", 4, 25, 8.0, Rect2(-20, -14, 40, 14)],
	"outhouse": ["Туалет", "outhouse", 6, 0, 9.0, Rect2(-22, -12, 44, 12)],
	"well": ["Колодец", "well", 8, 30, 10.0, Rect2(-30, -28, 60, 28)],
	"lantern": ["Фонарь", "lantern", 2, 5, 2.0, Rect2(-5, -6, 10, 6)],
	"fence": ["Забор", "fence", 1, 0, 1.0, Rect2(-16, -6, 32, 6)],
	"bench": ["Скамейка", "bench", 3, 0, 4.0, Rect2(-30, -14, 60, 12)],
	"campfire": ["Костёр", "campfire", 3, 0, 3.0, Rect2(-12, -8, 24, 8)],
	"dryer": ["Сушилка для трав", "dryer", 5, 0, 6.0, Rect2(-30, -10, 60, 10)],
	# ранний доступ: свои пути
	"stall": ["Лавка зелий", "stall_purple", 6, 20, 8.0, Rect2(-44, -14, 88, 14)],
	"forge": ["Кузница", "forge", 8, 40, 12.0, Rect2(-42, -18, 84, 18)],
}

## v20: все постройки — старые и новые (mats_db.BUILD): [название, картинка, брёвна, монеты, вес, преграда]
## Цена теперь — материалами (build_need), монеты не нужны.
const MT = preload("res://mats_db.gd")
const V24 = preload("res://v24_data.gd")
static var BUILD: Dictionary = _all_builds()


## v23: постройки своего королевства: [название, картинка, -, -, вес набора, преграда, что нужно, вид, сила]
## вид: house — кровати (сила = сколько спят), fun — развлечение (сила = радость), work — промышленность (сила = выработка)
const KBUILD: Dictionary = {
	"kg_house_a": ["Домик работников", "town_house_a", 0, 0, 12.0, Rect2(-80, -40, 160, 38), {"@plank": 20, "log": 10, "stone_m": 6}, "house", 4],
	"kg_house_b": ["Кошачий домик", "cat_house_a", 0, 0, 12.0, Rect2(-72, -40, 144, 38), {"@plank": 18, "log": 8, "cat_fur": 2}, "house", 4],
	"kg_house_c": ["Каменный дом", "town_house_b", 0, 0, 14.0, Rect2(-80, -40, 160, 38), {"stone_m": 16, "@plank": 12, "log": 6}, "house", 6],
	"kg_house_elf": ["Эльфийский домик", "elf_house", 0, 0, 12.0, Rect2(-60, -40, 120, 38), {"@plank": 22, "fairy_dust": 2}, "house", 5],
	"kg_house_jp": ["Минка", "jp_house_a", 0, 0, 12.0, Rect2(-70, -40, 140, 38), {"@plank": 20, "paper": 4}, "house", 4],
	"kg_tavern": ["Таверна", "tavern_cats", 0, 0, 16.0, Rect2(-100, -44, 200, 42), {"@plank": 30, "log": 12, "stone_m": 8}, "fun", 6],
	"kg_teahouse": ["Чайный домик", "tavern_japan", 0, 0, 14.0, Rect2(-90, -44, 180, 42), {"@plank": 24, "paper": 6}, "fun", 5],
	"kg_stage": ["Сцена для музыкантов", "stall_silk", 0, 0, 8.0, Rect2(-44, -14, 88, 14), {"@plank": 12, "cloth_red": 2}, "fun", 4],
	"kg_garden": ["Сад лунных цветов", "moon_flowers", 0, 0, 4.0, Rect2(), {"seed_mix": 4, "loam": 4}, "fun", 3],
	"kg_circle": ["Круг для танцев", "magic_circle", 0, 0, 4.0, Rect2(), {"stone_m": 8, "mana_dust": 2}, "fun", 3],
	"kg_bench": ["Скамейка у фонтана", "bench", 0, 0, 3.0, Rect2(-30, -14, 60, 12), {"@plank": 4}, "fun", 1],
	"kg_brewery": ["Зельеварня", "shop_mages", 0, 0, 16.0, Rect2(-90, -44, 180, 42), {"@plank": 24, "stone_m": 10, "glass": 4}, "work", 3],
	"kg_forge": ["Кузница королевства", "forge", 0, 0, 12.0, Rect2(-42, -18, 84, 18), {"stone_m": 12, "iron_bar": 4, "log": 6}, "work", 2],
	"kg_bakery": ["Пекарня", "bakery_cats", 0, 0, 14.0, Rect2(-90, -40, 180, 38), {"@plank": 20, "stone_m": 8, "flour": 4}, "work", 4],
	"kg_sawmill": ["Лесопилка", "st20_sawmill", 0, 0, 10.0, Rect2(-30, -12, 60, 12), {"log": 16, "iron_bar": 2}, "work", 6],
	"kg_mine": ["Шахтёрская артель", "shop_dwarves", 0, 0, 16.0, Rect2(-90, -44, 180, 42), {"@plank": 20, "stone_m": 14}, "work", 4],
	"kg_tailor": ["Ткацкая мастерская", "st20_spinning", 0, 0, 8.0, Rect2(-24, -12, 48, 12), {"@plank": 10, "wool_raw": 4}, "work", 3],
	# v26: магазины — жители сами приходят и покупают (shops26.gd); сила = на сколько растёт «слава» места
	"kg_shop_potion": ["Лавка зелий", "stall_purple", 0, 0, 8.0, Rect2(-44, -14, 88, 14), {"@plank": 10, "log": 4, "glass": 2}, "shop", 1],
	"kg_shop_food": ["Лавка снеди", "stall_green", 0, 0, 8.0, Rect2(-44, -14, 88, 14), {"@plank": 10, "log": 4, "cloth_red": 1}, "shop", 1],
	"kg_shop_smith": ["Лавка кованого", "shop_dwarves", 0, 0, 14.0, Rect2(-90, -44, 180, 42), {"@plank": 16, "stone_m": 8, "iron_bar": 2}, "shop", 1],
	"kg_shop_general": ["Лавка трав и руд", "shop_elves", 0, 0, 14.0, Rect2(-90, -44, 180, 42), {"@plank": 16, "log": 6, "stone_m": 4}, "shop", 1],
	"kg_palace": ["Дворец королевы", "palace_knights", 0, 0, 30.0, Rect2(-160, -50, 320, 48), {"stone_m": 60, "@plank": 40, "bar_gold": 6, "cloth_red": 6}, "palace", 10],
}


static func _all_builds() -> Dictionary:
	var out: Dictionary = BUILD_BASE.duplicate()
	for kk in KBUILD.keys():
		var kb: Array = KBUILD[kk]
		out[kk] = [kb[0], kb[1], 0, 0, kb[4], kb[5]]
	for k in MT.BUILD.keys():
		var b: Array = MT.BUILD[k]
		var r: Array = b[3]
		var kk2: float = float(MT.SHRINK.get(String(b[1]), 1.0))     # v28: уменьшенные столы — и преграда меньше
		out[k] = [String(b[0]), String(b[1]), 0, 0, float(b[2]), Rect2(float(r[0]) * kk2, float(r[1]) * kk2, float(r[2]) * kk2, float(r[3]) * kk2)]
	for k2 in V24.BUILD.keys():
		var b2: Array = V24.BUILD[k2]
		var r2: Array = b2[3]
		out[k2] = [String(b2[0]), String(b2[1]), 0, 0, float(b2[2]), Rect2(float(r2[0]), float(r2[1]), float(r2[2]), float(r2[3]))]
	return out


## Что нужно на постройку: {предмет или @группа: сколько}
static func build_need(kind: String) -> Dictionary:
	if KBUILD.has(kind):
		return KBUILD[kind][6]
	if MT.BUILD.has(kind):
		return (MT.BUILD[kind] as Array)[5]
	if V24.BUILD.has(kind):
		return (V24.BUILD[kind] as Array)[5]
	return {"log": int((BUILD_BASE.get(kind, ["", "", 1]) as Array)[2])}

# Саженцы: дерево -> как называется
const TREE_NAMES: Dictionary = {
	"tree_a": "дуб", "tree_b": "липа", "tree_c": "вяз", "tree_d": "ясень", "pine_a": "сосна", "pine_b": "ель",
	"tree_blossom": "сакура", "tree_autumn": "клён", "tree_autumn2": "рябина", "tree_apple": "яблоня",
	"tree_birch": "берёза", "tree_unicorn": "розовое древо", "dead_tree_a": "сухое дерево", "dead_tree_b": "сухое дерево",
}


# ------------------------------------------------------------------ v16: форма в сетке (как в PoE) и пучки
## Низкие травы и мох — 1×2, крошечные — 1×1, остальные травы высокие — 1×3
const HERB_SHORT: Array = ["clover", "thyme", "stonecrop", "strawberry", "lingonberry", "cloudberry", "pink_clover", "sundew", "club_moss", "plantain", "web_grass", "frost_lotus"]
const HERB_TINY: Array = ["glowmoss", "world_leaf"]
const INSECTS = preload("res://insects_db.gd")
const FD = preload("res://food_db.gd")
const TD = preload("res://tree_db.gd")


static func is_food(id: String) -> bool:
	return FD.is_food(id)


static func is_leaf(id: String) -> bool:
	return TD.is_leaf(id)


static func is_bug(id: String) -> bool:
	return id.begins_with("bug_") and INSECTS.DATA.has(id.substr(4))


## Сколько клеток занимает: Vector2i(ширина, высота)
static func size(id: String) -> Vector2i:
	if V23.WEAPONS.has(id):
		var ws: Array = V23.WEAPONS[id]["size"]
		return Vector2i(int(ws[0]), int(ws[1]))
	if is_furn(id):
		return Vector2i(2, 2)
	if v23_item(id):
		return Vector2i(1, 2) if V23.BOOKS.has(id) else Vector2i(1, 1)
	if id == "rod":
		return Vector2i(1, 4)
	if MT.has(id):
		return MT.cell_size(id)
	if is_dry(id):
		return size(id.substr(4))
	if DB.DATA.has(id):
		if HERB_TINY.has(id):
			return Vector2i(1, 1)
		return Vector2i(1, 2) if HERB_SHORT.has(id) else Vector2i(1, 3)
	if is_bug(id) or W.is_shroom(id) or is_food(id) or is_leaf(id):
		return Vector2i(1, 1)
	if FDB.is_fish(id):
		return Vector2i(2, 1)
	if RDB.is_product(id):
		return Vector2i(1, 2)
	if id == "wax" or id == "stone_s" or id == "quest_letter" or id.begins_with("ore_"):
		return Vector2i(1, 1)
	if id == "stone_l" or id in ["round_shield", "helmet", "iron_pot"]:
		return Vector2i(2, 2)
	if id in ["iron_bar", "horseshoe"]:
		return Vector2i(1, 1)
	if id in ["guard_sword", "tourney_spear", "star_blade"]:
		return Vector2i(1, 3)
	if ITEMS.has(id) and id != "log" and id != "axe":
		return Vector2i(1, 2)
	if id == "log":
		return Vector2i(3, 1)
	if id == "branch_long":
		return Vector2i(1, 4)
	if id.begins_with("sapling:"):
		return Vector2i(1, 2)
	if id.begins_with("kit:"):
		return Vector2i(2, 2)
	if GEAR.has(id):
		match String(GEAR[id]["slot"]):
			"tool":
				return Vector2i(1, 3) if id != "axe" and id != "shovel" else Vector2i(2, 3)
			"off":
				return Vector2i(2, 2)
			"head", "hands", "feet":
				return Vector2i(2, 2)
			"body", "pack":
				return Vector2i(2, 3)
			"belt":
				return Vector2i(2, 1)
			"neck", "ring":
				return Vector2i(1, 1)
	return Vector2i(1, 1)


## Сколько штук влезает в одну «стопку»: цветы — пучок до 10, грибы — 5, бутылочки — 5
static func stack(id: String) -> int:
	if V23.PRODUCTS.has(id):
		return 10
	if V23.JOKES.has(id) or V23.BOOKS.has(id):
		return 3
	if is_furn(id):
		return 5
	if MT.has(id):
		return MT.stack(id)
	if DB.DATA.has(id) or is_dry(id):
		return 10
	if W.is_shroom(id) or is_food(id):
		return 5
	if is_leaf(id):
		return 10
	if RDB.is_product(id):
		return 5      # v26: зелья складываются по 5 — склад не забивается одиночными бутылочками
	if FDB.is_fish(id):
		return 3
	if id == "bottle" or id == "stone_s":
		return 5
	if id.begins_with("ore_"):
		return 3
	if id == "wax" or id.begins_with("sapling:"):
		return 3
	return 1


static func is_tree_tex(tex: String) -> bool:
	return TREE_NAMES.has(tex)


static func is_dry(id: String) -> bool:
	return id.begins_with("dry:") and DB.DATA.has(id.substr(4))


static var _dry_icons: Dictionary = {}


## Значок сушёной травы: та же трава, но бурая и чуть блёклая
static func dry_icon(id: String) -> Texture2D:
	if _dry_icons.has(id):
		return _dry_icons[id]
	var src: Texture2D = DB.icon(id.substr(4))
	var img: Image = src.get_image()
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			var c: Color = img.get_pixel(x, y)
			if c.a > 0.0:
				var g: float = c.get_luminance()
				var d: Color = Color(g, g, g).lerp(c, 0.45) * Color(1.05, 0.86, 0.58)
				img.set_pixel(x, y, Color(d.r, d.g, d.b, c.a))
	var t: ImageTexture = ImageTexture.create_from_image(img)
	_dry_icons[id] = t
	return t


static func is_new(id: String) -> bool:
	return V24.ITEMS.has(id) or v23_item(id) or is_furn(id) or MT.has(id) or is_dry(id) or is_bug(id) or is_food(id) or is_leaf(id) or ITEMS.has(id) or GEAR.has(id) or id.begins_with("sapling:") or id.begins_with("kit:")


static func name(id: String) -> String:
	if is_furn(id):
		return String(V23.FURN[id.substr(5)]["name"])
	if V23.BOOKS.has(id):
		return String(V23.BOOKS[id]["name"])
	if V23.JOKES.has(id):
		return String(V23.JOKES[id]["name"])
	if V23.PRODUCTS.has(id):
		return String(V23.PRODUCTS[id]["name"])
	if MT.has(id):
		return MT.name(id)
	if is_dry(id):
		return "Сушёная " + DB.short(id.substr(4)).to_lower()
	if is_food(id):
		return FD.name(id)
	if is_leaf(id):
		return TD.leaf_name(id)
	if is_bug(id):
		return String(INSECTS.DATA[id.substr(4)]["name"])
	if ITEMS.has(id):
		return String(ITEMS[id][0])
	if V24.ITEMS.has(id):
		return String(V24.ITEMS[id][0])
	if GEAR.has(id):
		return String(GEAR[id]["name"])
	if id.begins_with("sapling:"):
		return "Саженец: " + String(TREE_NAMES.get(id.substr(8), "дерево"))
	if id.begins_with("kit:"):
		return String((BUILD.get(id.substr(4), ["Постройка"]) as Array)[0])
	if W.is_shroom(id):
		return W.shroom_name(id)
	if FDB.is_fish(id):
		return FDB.title(id)
	if RDB.is_product(id):
		return RDB.name(id)
	return DB.short(id)


static func icon(id: String) -> Texture2D:
	if is_furn(id):
		return load("res://art/%s.png" % String(V23.FURN[id.substr(5)]["tex"]))
	if v23_item(id):
		return load("res://art/icon_%s.png" % id)
	if MT.has(id):
		return MT.icon(id)
	if is_dry(id):
		return dry_icon(id)
	if is_food(id):
		return FD.icon(id)
	if is_leaf(id):
		return TD.leaf_icon(id)
	if is_bug(id):
		var at: AtlasTexture = AtlasTexture.new()
		at.atlas = load("res://art/insects.png")
		at.region = Rect2(0, int(INSECTS.DATA[id.substr(4)]["row"]) * 16, 16, 16)
		return at
	if ITEMS.has(id):
		return load("res://art/%s.png" % String(ITEMS[id][2]))
	if V24.ITEMS.has(id):
		return load("res://art/%s.png" % String(V24.ITEMS[id][2]))
	if GEAR.has(id):
		var gp: String = "res://art/gear_%s.png" % id
		return load(gp if ResourceLoader.exists(gp) else "res://art/icon_pack.png")
	if id.begins_with("sapling:"):
		var ic: String = "res://art/icon_sapling_%s.png" % id.substr(8)
		return load(ic if ResourceLoader.exists(ic) else "res://art/icon_sapling.png")
	if id.begins_with("kit:"):
		var tex: String = String((BUILD.get(id.substr(4), ["", ""]) as Array)[1])
		if tex == "":
			return load("res://art/bed_dry.png")
		return load("res://art/%s.png" % tex)
	if W.is_shroom(id):
		return W.shroom_icon(id)
	if FDB.is_fish(id):
		return FDB.icon(id)
	if RDB.is_product(id):
		return RDB.icon(id)
	return DB.icon(id)


static func weight(id: String) -> float:
	if is_furn(id):
		return 0.0                     # мебель везут сами мастера — в сумке не весит
	if V23.BOOKS.has(id):
		return 0.4
	if v23_item(id):
		return 0.2
	if MT.has(id):
		return MT.weight(id)
	if is_dry(id):
		return 0.08
	if is_food(id):
		return 0.5 if FD.is_drink(id) else 0.25
	if is_leaf(id):
		return 0.02
	if is_bug(id):
		return 0.05
	if ITEMS.has(id):
		return float(ITEMS[id][1])
	if V24.ITEMS.has(id):
		return float(V24.ITEMS[id][1])
	if GEAR.has(id):
		return float(GEAR[id]["w"])
	if id.begins_with("sapling:"):
		return 0.5
	if id.begins_with("kit:"):
		return float((BUILD.get(id.substr(4), [0, 0, 0, 0, 4.0]) as Array)[4])
	if W.is_shroom(id):
		return 0.3
	if FDB.is_fish(id):
		return 1.0
	if RDB.is_product(id):
		return 0.5
	return 0.2

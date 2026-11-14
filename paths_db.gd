extends RefCounted
## Ранний доступ: «пути» — своя история вместо одной цели.
## Лавка зелий (зазывать покупателей), союзы с королевствами (караваны, королевские заказы, придворная травница),
## кузница (оружие и инструменты для городов), фракции и секты, лечение больных, пожертвования, летопись.
## Игра без крови: оружие — для стражи, турниров и парадов, никто никого не ранит.

const RDB = preload("res://recipes_db.gd")
const IT = preload("res://items_db.gd")

# ------------------------------------------------------------------ кузница
## Предметы кузницы: id -> [название, вес, значок, цена, описание]
const SMITH_ITEMS: Dictionary = {
	"iron_bar": ["Железный брусок", 1.5, "icon_iron_bar", 12, "Выплавлен из камней с прожилками железа."],
	"horseshoe": ["Подкова", 0.5, "icon_horseshoe", 9, "На счастье и для коней. Нужна в каждом городе."],
	"guard_sword": ["Меч стражи", 2.5, "icon_guard_sword", 48, "Тупой парадный клинок: стража носит его для порядка."],
	"tourney_spear": ["Турнирное копьё", 3.0, "icon_tourney_spear", 34, "С мягким наконечником — для рыцарских турниров."],
	"round_shield": ["Круглый щит", 3.0, "icon_round_shield", 40, "Дубовые доски в железном ободе."],
	"helmet": ["Шлем", 2.0, "icon_helmet", 44, "Начищенный до блеска — для парадов."],
	"star_blade": ["Звёздный клинок", 2.0, "icon_star_blade", 150, "В сталь вплавлен волшебный камень. Светится, но не режет."],
	"iron_pot": ["Железный котелок", 2.5, "icon_iron_pot", 30, "Для супа и зелий. Травницы просят такие."],
}
const SMITH_ORDER: Array = ["iron_bar", "horseshoe", "iron_pot", "tourney_spear", "round_shield", "helmet", "guard_sword", "star_blade", "sickle", "pickaxe"]
## Что нужно на кузне: id -> [{предмет: сколько}, сколько выходит]. «ore» — любой волшебный камень.
const FORGE: Dictionary = {
	"iron_bar": [{"stone_m": 2, "log": 1}, 1],
	"horseshoe": [{"iron_bar": 1}, 2],
	"iron_pot": [{"iron_bar": 2}, 1],
	"tourney_spear": [{"iron_bar": 1, "log": 2}, 1],
	"round_shield": [{"iron_bar": 1, "log": 3}, 1],
	"helmet": [{"iron_bar": 2}, 1],
	"guard_sword": [{"iron_bar": 2, "log": 1}, 1],
	"star_blade": [{"guard_sword": 1, "ore": 1}, 1],
	"sickle": [{"iron_bar": 1, "log": 1}, 1],
	"pickaxe": [{"iron_bar": 2, "log": 1}, 1],
}
## Что заказывают земли у кузнецов
const LAND_WEAPONS: Dictionary = {
	"knights": ["guard_sword", "round_shield", "helmet", "tourney_spear"],
	"orcs": ["tourney_spear", "round_shield", "iron_pot"],
	"dwarves": ["helmet", "iron_pot", "horseshoe"],
	"elves": ["tourney_spear", "horseshoe"],
	"mages": ["star_blade", "iron_pot"],
	"gothic": ["star_blade", "guard_sword", "helmet"],
	"cats": ["horseshoe", "iron_pot"],
	"goblins": ["iron_pot", "helmet", "horseshoe"],
	"spider": ["round_shield", "iron_pot"],
	"japan": ["tourney_spear", "guard_sword"],
	"sea": ["tourney_spear", "iron_pot"],
}

# ------------------------------------------------------------------ фракции и секты
## rank_names — звания 0..4; favor — сколько доверия нужно для звания; perk — прибавка к Game.stat за звание
const RANK_FAVOR: Array = [0, 10, 25, 45, 70]
const FACTIONS: Dictionary = {
	"coven": {
		"name": "Ковен Лунного Котла", "kind": "тайный ковен зельеваров",
		"land": "gothic", "night": true, "roles": ["житель", "торговец"],
		"about": "Мы варим при луне то, что днём не сваришь. Никаких проклятий — только самые чистые зелья. Ковен помнит тех, кто ему помог.",
		"join": {"potion_any": 3}, "join_text": "три любых зелья",
		"ranks": ["Подмастерье котла", "Сестра ковена", "Лунная ведьма", "Хранительница котла", "Верховная ведьма"],
		"perk": {"brew": 5}, "perk_text": "+5% к удаче варки за звание",
		"rival": "shield",
		"tasks": [["potion_any", 2], ["moon_dew", 1], ["sleep_tea", 1], ["calm_tea", 1], ["wax", 2]],
		"col": Color("7a4aa8"), "icon": "emblem_coven",
	},
	"shield": {
		"name": "Орден Светлого Щита", "kind": "рыцарский орден",
		"land": "knights", "night": false, "roles": ["стража", "заместитель", "житель"],
		"about": "Мы бережём дороги и помогаем путникам. Оружие у нас парадное — честь важнее клинка. Колдовские ковены нам не друзья.",
		"join": {"round_shield": 1}, "join_text": "один круглый щит из кузницы",
		"ranks": ["Оруженоска", "Сестра ордена", "Рыцарь-травница", "Знаменосица", "Магистр ордена"],
		"perk": {"speed": 2}, "perk_text": "+2% к скорости за звание",
		"rival": "coven",
		"tasks": [["horseshoe", 4], ["heal_salve", 1], ["guard_sword", 1], ["helmet", 1], ["vigor_tea", 2]],
		"col": Color("c8a038"), "icon": "emblem_shield",
	},
	"guild": {
		"name": "Гильдия Золотых Весов", "kind": "торговая гильдия",
		"land": "", "night": false, "roles": ["торговец"],
		"about": "Каждая монета любит счёт. Гильдия даёт своим лучшие цены и хорошие места на ярмарках. Совам мы не доверяем.",
		"join": {"coins": 50}, "join_text": "взнос 50 монет",
		"ranks": ["Подручная", "Торговка гильдии", "Купчиха", "Старшина рынка", "Глава гильдии"],
		"perk": {"sell": 4}, "perk_text": "+4% к цене продажи за звание",
		"rival": "owls",
		"tasks": [["sold", 6], ["coins", 40], ["potion_any", 3], ["sold", 10]],
		"col": Color("d8b040"), "icon": "emblem_guild",
	},
	"anvil": {
		"name": "Братство Наковальни", "kind": "союз кузнецов",
		"land": "", "night": false, "roles": ["кузнец"],
		"about": "Дзынь! Мы куём для всех городов: подковы, котелки, парадные мечи. Друиды ворчат, что мы рубим лес на уголь. Пусть ворчат.",
		"join": {"iron_bar": 2}, "join_text": "два железных бруска",
		"ranks": ["Подмастерье", "Молотобойка", "Кузнечиха", "Мастер горна", "Старейшина наковальни"],
		"perk": {"cap": 3}, "perk_text": "+3 к весу за звание",
		"rival": "druids",
		"tasks": [["iron_bar", 3], ["horseshoe", 4], ["iron_pot", 1], ["forged", 4], ["log", 6]],
		"col": Color("8a5a3a"), "icon": "emblem_anvil",
	},
	"druids": {
		"name": "Круг Зелёного Корня", "kind": "круг друидов",
		"land": "elves", "night": false, "roles": ["житель", "заместитель", "торговец"],
		"about": "Каждое дерево — чья-то бабушка. Мы сажаем леса и лечим травами. Кузнецы жгут уголь — с ними нам не по пути.",
		"join": {"herb_any": 6}, "join_text": "шесть любых трав",
		"ranks": ["Росток", "Побег", "Ветвь", "Крона", "Древняя"],
		"perk": {"herb": 5}, "perk_text": "+5% к сбору трав за звание",
		"rival": "anvil",
		"tasks": [["herb_any", 8], ["sapling_any", 2], ["mint_tea", 1], ["leaf_any", 6], ["herb_any", 12]],
		"col": Color("4a8a3a"), "icon": "emblem_druids",
	},
	"cat_cult": {
		"name": "Секта Великой Спящей Кошки", "kind": "весёлая секта котопоклонниц",
		"land": "cats", "night": false, "roles": ["житель", "торговец"],
		"about": "Великая Кошка спит и видит сон — это и есть наш мир. Мы ей не мешаем: дремлем, носим рыбку и мурлычем. Мур!",
		"join": {"fish_any": 1}, "join_text": "одна рыбка для Великой Кошки",
		"ranks": ["Котёночек", "Мурлыка", "Дремлющая", "Хранительница клубка", "Жрица Сна"],
		"perk": {"hunger": -4}, "perk_text": "голод на 4% медленнее за звание",
		"rival": "",
		"tasks": [["fish_any", 2], ["sleep_tea", 1], ["fish_any", 4], ["food_any", 2]],
		"col": Color("e08a5a"), "icon": "emblem_cat",
	},
	"owls": {
		"name": "Общество Ночных Сов", "kind": "тайное общество",
		"land": "goblins", "night": true, "roles": ["житель", "торговец", "кузнец"],
		"about": "Ух-ху. Мы возим то, что не облагают налогом, и знаем все тропы. Никого не обижаем — просто не любим вопросов. Гильдия нас терпеть не может.",
		"join": {"coins": 30}, "join_text": "30 монет — и никому ни слова",
		"ranks": ["Совёнок", "Тень", "Ночная тропа", "Филин", "Старая Сова"],
		"perk": {"buy": 4}, "perk_text": "покупки на 4% дешевле за звание",
		"rival": "guild",
		"tasks": [["ore", 1], ["stone_s", 6], ["stone_m", 4], ["ore", 2]],
		"col": Color("4a4a6a"), "icon": "emblem_owls",
	},
	"stars": {
		"name": "Орден Звёздного Пера", "kind": "общество учёных магов",
		"land": "mages", "night": false, "roles": ["житель", "заместитель", "торговец"],
		"about": "Мы записываем всё: травы, звёзды, сны. Книга — лучший учитель. Принеси знание — получишь знание.",
		"join": {"researched": 5}, "join_text": "изучить на столе пять трав",
		"ranks": ["Ученица", "Писарь", "Звездочёт", "Магистр", "Архивариус"],
		"perk": {"sell": 2, "brew": 2}, "perk_text": "+2% к продаже и варке за звание",
		"rival": "",
		"tasks": [["dry_any", 3], ["ore_star", 1], ["ore", 1], ["potion_any", 2]],
		"col": Color("4a6ac8"), "icon": "emblem_stars",
	},
}
const FACTION_ORDER: Array = ["coven", "shield", "guild", "anvil", "druids", "cat_cult", "owls", "stars"]

# ------------------------------------------------------------------ лавка зелий
const STALL_HOURS_OPEN: Array = [8.0, 20.0]
const LURE_MIN: float = 120.0        # сколько игровых минут действуют зазывания
const LURE_CD: float = 60.0          # не чаще раза в час

# ------------------------------------------------------------------ титулы (летопись)
const TITLES: Dictionary = {
	"merchant": "Торговка зельями",
	"merchant2": "Знаменитая лавочница",
	"smith": "Кузнечиха",
	"smith2": "Мастер оружия всех городов",
	"partner": "Торговая союзница королевств",
	"court": "Придворная травница",
	"healer": "Народная целительница",
	"patron": "Покровительница земель",
	"faction_head": "Глава фракции",
}


static func is_smith(id: String) -> bool:
	return SMITH_ITEMS.has(id)


static func smith_name(id: String) -> String:
	if SMITH_ITEMS.has(id):
		return String(SMITH_ITEMS[id][0])
	return IT.name(id)


static func smith_icon(id: String) -> Texture2D:
	if SMITH_ITEMS.has(id):
		var p: String = "res://art/%s.png" % String(SMITH_ITEMS[id][2])
		if ResourceLoader.exists(p):
			return load(p)
		return load("res://art/icon_stone_m.png")
	return IT.icon(id)


## Цена товара для лавки, каравана и заказов
static func price(id: String) -> int:
	if SMITH_ITEMS.has(id):
		return int(SMITH_ITEMS[id][3])
	if IT.GEAR.has(id):
		return int(IT.GEAR[id].get("price", 10)) / 2
	if RDB.is_product(id):
		return 6 if id == "murky" else 14 + RDB.rarity(id) * 10
	if preload("res://food_db.gd").is_food(id):
		return maxi(2, int(preload("res://food_db.gd").price(id)))
	if preload("res://fish_db.gd").is_fish(id):
		return int((preload("res://fish_db.gd").DATA[id] as Dictionary).get("price", 4))
	if preload("res://mining_db.gd").is_mineral(id):
		return preload("res://mining_db.gd").price(id)
	if preload("res://herbs_db.gd").DATA.has(id):
		return preload("res://herbs_db.gd").price(id)
	return 3


## Что можно выставить в лавку и отправить с караваном: зелья, кованое, еда (готовая)
static func sellable(id: String) -> bool:
	if id == "murky":
		return false
	return RDB.is_product(id) or SMITH_ITEMS.has(id) or (preload("res://food_db.gd").is_food(id))


static func faction(id: String) -> Dictionary:
	return FACTIONS.get(id, {})


static func rank_of_favor(f: int) -> int:
	var r: int = 0
	for i in range(RANK_FAVOR.size()):
		if f >= int(RANK_FAVOR[i]):
			r = i
	return r

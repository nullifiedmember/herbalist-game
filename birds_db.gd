extends RefCounted
## Птицы v20 — СГЕНЕРИРОВАНО tools/birds_design.py (правки — там, потом `python tools/birds_design.py --write`).
## id -> name, size (s/m/l/xl), owl, frame [w,h], biomes {биом: вес}, when (day/night/dusk), shy (0..1 — с какого
## расстояния улетает), common (0..1), props (свойства пера в котле), price (цена пера), perch (ground/tree/water).
## Спрайт art/bird_<id>.png: 12 кадров (0-1 стоит/моргает, 2-3 клюёт, 4 прыжок, 6-9 полёт, 10-11 поёт).
## Перо — предмет feather_<id> (значок art/icon_feather_<id>.png), голос audio/bird_<id>.wav.

const DATA: Dictionary = {
	"sparrow": {"name": "Воробей", "size": "s", "owl": false, "frame": [57, 42], "biomes": {0: 6, 1: 4, 9: 6, 16: 4, 4: 4, 7: 2, 8: 2}, "when": "day", "shy": 0.45, "common": 1.0, "props": {"Сила": 1}, "price": 2, "perch": "ground", "magic": false},
	"great_tit": {"name": "Большая синица", "size": "s", "owl": false, "frame": [57, 42], "biomes": {0: 4, 1: 3, 12: 5, 14: 3, 5: 3}, "when": "day", "shy": 0.35, "common": 0.9, "props": {"Свежесть": 1, "Сила": 1}, "price": 3, "perch": "tree", "magic": false},
	"blue_tit": {"name": "Лазоревка", "size": "s", "owl": false, "frame": [57, 40], "biomes": {12: 5, 1: 2, 5: 3, 0: 2}, "when": "day", "shy": 0.35, "common": 0.8, "props": {"Холод": 1, "Свежесть": 1}, "price": 3, "perch": "tree", "magic": false},
	"robin": {"name": "Зарянка", "size": "s", "owl": false, "frame": [57, 42], "biomes": {0: 4, 12: 3, 14: 4, 13: 2, 5: 2}, "when": "day", "shy": 0.3, "common": 0.85, "props": {"Тепло": 1, "Исцеление": 1}, "price": 3, "perch": "ground", "magic": false},
	"chaffinch": {"name": "Зяблик", "size": "s", "owl": false, "frame": [57, 42], "biomes": {12: 4, 13: 3, 1: 3, 0: 2, 14: 3}, "when": "day", "shy": 0.4, "common": 0.9, "props": {"Свежесть": 1, "Тепло": 1}, "price": 3, "perch": "tree", "magic": false},
	"goldfinch": {"name": "Щегол", "size": "s", "owl": false, "frame": [57, 40], "biomes": {16: 5, 1: 4, 0: 2}, "when": "day", "shy": 0.45, "common": 0.6, "props": {"Свет": 1, "Чары": 1}, "price": 6, "perch": "tree", "magic": false},
	"bullfinch": {"name": "Снегирь", "size": "s", "owl": false, "frame": [60, 44], "biomes": {13: 5, 12: 2, 6: 2}, "when": "day", "shy": 0.3, "common": 0.6, "props": {"Холод": 1, "Тепло": 1}, "price": 5, "perch": "tree", "magic": false},
	"wren": {"name": "Крапивник", "size": "s", "owl": false, "frame": [57, 42], "biomes": {13: 3, 14: 3, 2: 3, 15: 2, 5: 2}, "when": "day", "shy": 0.55, "common": 0.6, "props": {"Сила": 2}, "price": 4, "perch": "ground", "magic": false},
	"nightingale": {"name": "Соловей", "size": "s", "owl": false, "frame": [57, 42], "biomes": {12: 3, 1: 2, 5: 4, 9: 2, 0: 2}, "when": "dusk", "shy": 0.6, "common": 0.45, "props": {"Покой": 1, "Сон": 1}, "price": 8, "perch": "tree", "magic": false},
	"lark": {"name": "Жаворонок", "size": "s", "owl": false, "frame": [57, 42], "biomes": {16: 6, 1: 4, 4: 2}, "when": "day", "shy": 0.5, "common": 0.75, "props": {"Свет": 1, "Свежесть": 1}, "price": 4, "perch": "ground", "magic": false},
	"swallow": {"name": "Ласточка", "size": "s", "owl": false, "frame": [57, 40], "biomes": {16: 4, 1: 4, 0: 3, 9: 3, 4: 2}, "when": "day", "shy": 0.6, "common": 0.7, "props": {"Свежесть": 1, "Свет": 1}, "price": 4, "perch": "ground", "magic": false},
	"starling": {"name": "Скворец", "size": "s", "owl": false, "frame": [59, 44], "biomes": {0: 4, 1: 4, 9: 4, 16: 3, 4: 3}, "when": "day", "shy": 0.45, "common": 0.85, "props": {"Чары": 1, "Тьма": 1}, "price": 3, "perch": "ground", "magic": false},
	"thrush": {"name": "Певчий дрозд", "size": "s", "owl": false, "frame": [59, 44], "biomes": {12: 3, 14: 4, 13: 3, 5: 2, 0: 2}, "when": "day", "shy": 0.45, "common": 0.75, "props": {"Исцеление": 1, "Покой": 1}, "price": 4, "perch": "ground", "magic": false},
	"blackbird": {"name": "Чёрный дрозд", "size": "s", "owl": false, "frame": [59, 44], "biomes": {0: 4, 12: 3, 14: 3, 3: 4, 9: 2}, "when": "day", "shy": 0.4, "common": 0.8, "props": {"Тьма": 1, "Покой": 1}, "price": 4, "perch": "ground", "magic": false},
	"wagtail": {"name": "Трясогузка", "size": "s", "owl": false, "frame": [57, 40], "biomes": {15: 3, 18: 3, 1: 3, 0: 2, 9: 2}, "when": "day", "shy": 0.5, "common": 0.7, "props": {"Свежесть": 2}, "price": 3, "perch": "ground", "magic": false},
	"oriole": {"name": "Иволга", "size": "s", "owl": false, "frame": [59, 44], "biomes": {14: 4, 12: 3, 5: 3}, "when": "day", "shy": 0.65, "common": 0.35, "props": {"Свет": 2, "Тепло": 1}, "price": 10, "perch": "tree", "magic": false},
	"waxwing": {"name": "Свиристель", "size": "s", "owl": false, "frame": [59, 44], "biomes": {13: 3, 14: 3, 6: 2, 12: 2}, "when": "day", "shy": 0.35, "common": 0.45, "props": {"Холод": 1, "Чары": 1}, "price": 7, "perch": "tree", "magic": false},
	"kingfisher": {"name": "Зимородок", "size": "s", "owl": false, "frame": [58, 42], "biomes": {15: 4, 1: 1, 18: 2, 17: 2}, "when": "day", "shy": 0.7, "common": 0.3, "props": {"Холод": 1, "Свет": 1, "Свежесть": 1}, "price": 12, "perch": "water", "magic": false},
	"hoopoe": {"name": "Удод", "size": "m", "owl": false, "frame": [66, 49], "biomes": {16: 4, 7: 3, 1: 2, 18: 1}, "when": "day", "shy": 0.55, "common": 0.35, "props": {"Огонь": 1, "Сила": 1}, "price": 9, "perch": "ground", "magic": false},
	"jay": {"name": "Сойка", "size": "m", "owl": false, "frame": [64, 47], "biomes": {14: 4, 13: 3, 12: 2, 5: 2, 3: 2}, "when": "day", "shy": 0.6, "common": 0.6, "props": {"Чары": 1, "Холод": 1}, "price": 6, "perch": "tree", "magic": false},
	"magpie": {"name": "Сорока", "size": "m", "owl": false, "frame": [68, 47], "biomes": {0: 3, 1: 3, 9: 3, 16: 3, 4: 3, 7: 2}, "when": "day", "shy": 0.55, "common": 0.8, "props": {"Чары": 1, "Тьма": 1}, "price": 4, "perch": "ground", "magic": false},
	"crow": {"name": "Серая ворона", "size": "m", "owl": false, "frame": [65, 49], "biomes": {3: 5, 0: 2, 7: 4, 9: 2, 4: 2, 8: 2, 16: 2}, "when": "day", "shy": 0.5, "common": 0.85, "props": {"Тьма": 1, "Сила": 1}, "price": 2, "perch": "ground", "magic": false},
	"raven": {"name": "Ворон", "size": "l", "owl": false, "frame": [71, 52], "biomes": {3: 5, 13: 2, 2: 3, 8: 2}, "when": "day", "shy": 0.6, "common": 0.45, "props": {"Тьма": 2, "Чары": 1}, "price": 8, "perch": "ground", "magic": false},
	"cuckoo": {"name": "Кукушка", "size": "m", "owl": false, "frame": [62, 45], "biomes": {12: 4, 13: 3, 14: 3, 5: 2}, "when": "day", "shy": 0.7, "common": 0.4, "props": {"Сон": 1, "Чары": 1}, "price": 7, "perch": "tree", "magic": false},
	"woodpecker": {"name": "Пёстрый дятел", "size": "m", "owl": false, "frame": [61, 45], "biomes": {13: 4, 12: 4, 14: 3, 5: 2}, "when": "day", "shy": 0.5, "common": 0.6, "props": {"Сила": 2}, "price": 5, "perch": "tree", "magic": false},
	"dove": {"name": "Горлица", "size": "m", "owl": false, "frame": [59, 44], "biomes": {9: 5, 17: 3, 0: 3, 4: 3, 1: 2, 5: 2}, "when": "day", "shy": 0.4, "common": 0.8, "props": {"Покой": 2}, "price": 3, "perch": "ground", "magic": false},
	"pheasant": {"name": "Фазан", "size": "l", "owl": false, "frame": [68, 50], "biomes": {16: 3, 14: 4, 1: 2, 4: 2}, "when": "day", "shy": 0.6, "common": 0.4, "props": {"Огонь": 1, "Тепло": 1, "Сила": 1}, "price": 9, "perch": "ground", "magic": false},
	"quail": {"name": "Перепел", "size": "s", "owl": false, "frame": [65, 49], "biomes": {16: 6, 1: 3}, "when": "day", "shy": 0.5, "common": 0.6, "props": {"Сила": 1, "Тепло": 1}, "price": 4, "perch": "ground", "magic": false},
	"partridge": {"name": "Серая куропатка", "size": "m", "owl": false, "frame": [61, 45], "biomes": {16: 4, 1: 3, 14: 2, 7: 2}, "when": "day", "shy": 0.5, "common": 0.5, "props": {"Тепло": 1, "Сила": 1}, "price": 5, "perch": "ground", "magic": false},
	"heron": {"name": "Серая цапля", "size": "xl", "owl": false, "frame": [80, 70], "biomes": {15: 6, 18: 2, 17: 2, 1: 1}, "when": "day", "shy": 0.65, "common": 0.4, "props": {"Холод": 1, "Покой": 1, "Свежесть": 1}, "price": 8, "perch": "water", "magic": false},
	"crane": {"name": "Японский журавль", "size": "xl", "owl": false, "frame": [81, 68], "biomes": {17: 5, 15: 1}, "when": "day", "shy": 0.7, "common": 0.25, "props": {"Чары": 1, "Покой": 1, "Свет": 1}, "price": 18, "perch": "water", "magic": false},
	"swan": {"name": "Лебедь-шипун", "size": "l", "owl": false, "frame": [99, 72], "biomes": {15: 3, 4: 2, 5: 2, 10: 2}, "when": "day", "shy": 0.5, "common": 0.35, "props": {"Свет": 1, "Покой": 1, "Исцеление": 1}, "price": 14, "perch": "water", "magic": false},
	"goose": {"name": "Серый гусь", "size": "l", "owl": false, "frame": [75, 54], "biomes": {1: 3, 15: 4, 16: 2, 4: 2}, "when": "day", "shy": 0.45, "common": 0.55, "props": {"Сила": 1, "Тепло": 1}, "price": 5, "perch": "ground", "magic": false},
	"gull": {"name": "Чайка", "size": "m", "owl": false, "frame": [65, 49], "biomes": {18: 8, 19: 6, 15: 1}, "when": "day", "shy": 0.45, "common": 0.9, "props": {"Свежесть": 1, "Холод": 1}, "price": 3, "perch": "ground", "magic": false},
	"sandpiper": {"name": "Кулик-перевозчик", "size": "s", "owl": false, "frame": [56, 40], "biomes": {18: 6, 15: 4}, "when": "day", "shy": 0.55, "common": 0.7, "props": {"Свежесть": 1}, "price": 3, "perch": "ground", "magic": false},
	"bee_eater": {"name": "Золотистая щурка", "size": "s", "owl": false, "frame": [58, 42], "biomes": {16: 3, 7: 3, 18: 2, 14: 1}, "when": "day", "shy": 0.6, "common": 0.35, "props": {"Огонь": 1, "Свет": 1, "Жгучесть": 1}, "price": 11, "perch": "tree", "magic": false},
	"crossbill": {"name": "Клёст-еловик", "size": "s", "owl": false, "frame": [59, 44], "biomes": {13: 6, 8: 2}, "when": "day", "shy": 0.35, "common": 0.5, "props": {"Огонь": 1, "Холод": 1}, "price": 6, "perch": "tree", "magic": false},
	"nuthatch": {"name": "Поползень", "size": "s", "owl": false, "frame": [57, 40], "biomes": {12: 3, 14: 4, 5: 3, 13: 2}, "when": "day", "shy": 0.3, "common": 0.6, "props": {"Сила": 1, "Свежесть": 1}, "price": 4, "perch": "tree", "magic": false},
	"white_eye": {"name": "Белоглазка мэдзиро", "size": "s", "owl": false, "frame": [54, 39], "biomes": {17: 7, 10: 1}, "when": "day", "shy": 0.35, "common": 0.7, "props": {"Свежесть": 1, "Чары": 1}, "price": 6, "perch": "tree", "magic": false},
	"rosefinch": {"name": "Розовый чечевичник", "size": "s", "owl": false, "frame": [57, 42], "biomes": {10: 6, 5: 2, 6: 1}, "when": "day", "shy": 0.4, "common": 0.5, "props": {"Чары": 1, "Исцеление": 1}, "price": 9, "perch": "tree", "magic": false},
	"mandarin_duck": {"name": "Утка-мандаринка", "size": "m", "owl": false, "frame": [65, 48], "biomes": {17: 4, 15: 3, 5: 1}, "when": "day", "shy": 0.4, "common": 0.3, "props": {"Чары": 1, "Тепло": 1, "Свет": 1}, "price": 12, "perch": "water", "magic": false},
	"nightjar": {"name": "Козодой", "size": "m", "owl": false, "frame": [60, 44], "biomes": {13: 3, 1: 2, 16: 2, 3: 2}, "when": "night", "shy": 0.55, "common": 0.4, "props": {"Сон": 2, "Тьма": 1}, "price": 9, "perch": "ground", "magic": false},
	"tawny_owl": {"name": "Серая неясыть", "size": "m", "owl": true, "frame": [63, 45], "biomes": {12: 4, 13: 4, 14: 4, 5: 3, 0: 2, 1: 2, 3: 3, 2: 3}, "when": "night", "shy": 0.45, "common": 0.8, "props": {"Сон": 1, "Тьма": 1, "Покой": 1}, "price": 6, "perch": "tree", "magic": false},
	"eagle_owl": {"name": "Филин", "size": "l", "owl": true, "frame": [74, 53], "biomes": {3: 4, 13: 3, 8: 3, 11: 3, 2: 2}, "when": "night", "shy": 0.55, "common": 0.45, "props": {"Тьма": 2, "Сила": 1}, "price": 12, "perch": "tree", "magic": false},
	"barn_owl": {"name": "Сипуха", "size": "m", "owl": true, "frame": [63, 46], "biomes": {16: 4, 3: 4, 1: 3, 4: 3, 9: 2, 0: 2}, "when": "night", "shy": 0.45, "common": 0.6, "props": {"Сон": 1, "Свет": 1, "Покой": 1}, "price": 8, "perch": "tree", "magic": false},
	"scops_owl": {"name": "Сплюшка", "size": "s", "owl": true, "frame": [58, 40], "biomes": {14: 4, 17: 4, 7: 2, 12: 2, 5: 2}, "when": "night", "shy": 0.35, "common": 0.55, "props": {"Сон": 2}, "price": 7, "perch": "tree", "magic": false},
	"snowy_owl": {"name": "Белая сова", "size": "l", "owl": true, "frame": [68, 49], "biomes": {13: 2, 6: 3, 11: 2, 10: 1}, "when": "night", "shy": 0.6, "common": 0.2, "props": {"Холод": 2, "Свет": 1}, "price": 16, "perch": "ground", "magic": false},
	"firebird": {"name": "Жар-птица", "size": "l", "owl": false, "frame": [134, 90], "biomes": {8: 2, 7: 2, 14: 1, 6: 1}, "when": "day", "shy": 0.75, "common": 0.08, "props": {"Огонь": 2, "Свет": 2, "Исцеление": 1}, "price": 60, "perch": "tree", "magic": true},
	"moon_finch": {"name": "Лунный вьюрок", "size": "s", "owl": false, "frame": [57, 42], "biomes": {6: 4, 10: 3, 11: 3}, "when": "night", "shy": 0.5, "common": 0.2, "props": {"Чары": 2, "Свет": 1, "Холод": 1}, "price": 30, "perch": "tree", "magic": true},
	"fairy_wren": {"name": "Фейный крапивник", "size": "s", "owl": false, "frame": [57, 42], "biomes": {5: 5, 10: 3}, "when": "day", "shy": 0.6, "common": 0.2, "props": {"Чары": 2, "Свежесть": 1}, "price": 26, "perch": "ground", "magic": true},
	"shadow_crow": {"name": "Теневой ворон", "size": "m", "owl": false, "frame": [66, 50], "biomes": {3: 4, 2: 3, 11: 1}, "when": "dusk", "shy": 0.6, "common": 0.15, "props": {"Тьма": 3, "Чары": 1}, "price": 34, "perch": "ground", "magic": true},
}
const ORDER: Array = ["sparrow", "great_tit", "blue_tit", "robin", "chaffinch", "goldfinch", "bullfinch", "wren", "nightingale", "lark", "swallow", "starling", "thrush", "blackbird", "wagtail", "oriole", "waxwing", "kingfisher", "hoopoe", "jay", "magpie", "crow", "raven", "cuckoo", "woodpecker", "dove", "pheasant", "quail", "partridge", "heron", "crane", "swan", "goose", "gull", "sandpiper", "bee_eater", "crossbill", "nuthatch", "white_eye", "rosefinch", "mandarin_duck", "nightjar", "tawny_owl", "eagle_owl", "barn_owl", "scops_owl", "snowy_owl", "firebird", "moon_finch", "fairy_wren", "shadow_crow"]


static func feather(bid: String) -> String:
	return "feather_" + bid


static func is_feather(id: String) -> bool:
	return id.begins_with("feather_") and DATA.has(id.substr(8))


static func feather_name(id: String) -> String:
	return "Перо: " + String(DATA[id.substr(8)]["name"]).to_lower() if is_feather(id) else id


## Какие птицы живут в биоме в это время суток: [[id, вес], ...]
static func for_biome(biome: int, night: bool, dusk: bool) -> Array:
	var out: Array = []
	for id in ORDER:
		var d: Dictionary = DATA[id]
		var w: String = String(d["when"])
		var ok: bool = (w == "day" and not night) or (w == "night" and night) or (w == "dusk" and (dusk or night))
		if not ok:
			continue
		var bw: float = float((d["biomes"] as Dictionary).get(biome, 0))
		if bw > 0.0:
			out.append([id, bw * float(d["common"])])
	return out

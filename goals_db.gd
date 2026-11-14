extends RefCounted
## v22: цели игры. Каждая проверяется сама по состоянию Game (ничего вручную отмечать не нужно),
## за выполнение — награда монетами и вещами. Окно целей: клавиша G.
## kind: counter (Game.counters[key] >= n), day (Game.day >= n), known (изучено трав), recipes (открыто рецептов),
##       fish (поймано видов рыб), mermaid (раз пила эликсир хвоста), seen_sea (открыто подводных трав),
##       has (в сумке или открыта трава id).

const SEA_HERBS: Array = ["sea_lettuce", "eelgrass", "kelp_gold", "sea_grape", "storm_weed", "sea_anemone", "pearl_moss", "coral_bloom", "ice_algae", "star_coral", "glow_algae", "mermaid_hair", "abyss_kelp", "siren_lily", "tide_orchid", "pearl_flower"]

const LIST: Array = [
	# первые шаги
	{"id": "herbs_10", "name": "Первая охапка", "desc": "Собери 10 трав.", "kind": "counter", "key": "herbs", "n": 10, "coins": 25},
	{"id": "day_3", "name": "Обжилась", "desc": "Дожить до третьего дня.", "kind": "day", "n": 3, "coins": 20},
	{"id": "known_8", "name": "Знаток лугов", "desc": "Узнай 8 разных трав.", "kind": "known", "n": 8, "coins": 40},
	{"id": "recipe_1", "name": "Первое зелье", "desc": "Открой свой первый рецепт.", "kind": "recipes", "n": 1, "coins": 30},
	{"id": "fish_3", "name": "Рыбачка", "desc": "Поймай 3 вида рыбы.", "kind": "fish", "n": 3, "coins": 35},
	{"id": "earn_200", "name": "Первые деньги", "desc": "Заработай 200 монет за всё время.", "kind": "counter", "key": "earned", "n": 200, "coins": 40},
	# обычная жизнь травницы
	{"id": "herbs_60", "name": "Полная корзина", "desc": "Собери 60 трав.", "kind": "counter", "key": "herbs", "n": 60, "coins": 80},
	{"id": "day_7", "name": "Неделя в лесу", "desc": "Проживи неделю.", "kind": "day", "n": 7, "coins": 60},
	{"id": "known_20", "name": "Травница", "desc": "Узнай 20 разных трав.", "kind": "known", "n": 20, "coins": 120},
	{"id": "recipe_6", "name": "Мастерица котла", "desc": "Открой 6 рецептов.", "kind": "recipes", "n": 6, "coins": 150},
	{"id": "earn_1000", "name": "Состоятельная", "desc": "Заработай 1000 монет.", "kind": "counter", "key": "earned", "n": 1000, "coins": 200},
	{"id": "day_30", "name": "Месяц в лесу", "desc": "Проживи 30 дней.", "kind": "day", "n": 30, "coins": 250},
	# море
	{"id": "mermaid_1", "name": "Хвост и чешуя", "desc": "Выпей эликсир русалочьего хвоста и поплыви.", "kind": "mermaid", "n": 1, "coins": 150, "items": [["pearl", 1]]},
	{"id": "sea_5", "name": "Первые морские травы", "desc": "Собери 5 подводных трав.", "kind": "counter", "key": "sea_herbs", "n": 5, "coins": 80},
	{"id": "sea_30", "name": "Морская огородница", "desc": "Собери 30 подводных трав.", "kind": "counter", "key": "sea_herbs", "n": 30, "coins": 300, "items": [["pearl", 2]]},
	{"id": "sea_8", "name": "Знаток глубин", "desc": "Узнай 8 разных подводных трав.", "kind": "seen_sea", "n": 8, "coins": 200},
	{"id": "pearl_flower", "name": "Слеза принцессы", "desc": "Найди жемчужный цветок — самую редкую траву моря.", "kind": "has", "id2": "pearl_flower", "coins": 500},
	{"id": "sea_all", "name": "Хозяйка моря", "desc": "Узнай все 16 подводных трав.", "kind": "seen_sea", "n": 16, "coins": 800},
	# большие цели
	{"id": "recipe_15", "name": "Алхимик", "desc": "Открой 15 рецептов.", "kind": "recipes", "n": 15, "coins": 400},
	{"id": "day_100", "name": "Сто дней", "desc": "Проживи 100 дней.", "kind": "day", "n": 100, "coins": 1000},
]


static func progress(g: Dictionary) -> Vector2i:
	var n: int = int(g.get("n", 1))
	var cur: int = 0
	match String(g["kind"]):
		"counter":
			cur = int(Game.counters.get(String(g["key"]), 0))
		"day":
			cur = Game.day
		"known":
			for k in Game.discovered.keys():
				if preload("res://herbs_db.gd").DATA.has(String(k)):
					cur += 1
		"recipes":
			cur = Game.known_recipes.size()
		"fish":
			cur = Game.fish_caught.size()
		"mermaid":
			cur = Game.mermaid_ever
		"seen_sea":
			for id in SEA_HERBS:
				if Game.discovered.has(id):
					cur += 1
		"has":
			n = 1
			cur = 1 if (Game.discovered.has(String(g["id2"])) or Game.get_count(String(g["id2"])) > 0) else 0
	return Vector2i(mini(cur, n), n)


static func done(g: Dictionary) -> bool:
	var p: Vector2i = progress(g)
	return p.x >= p.y

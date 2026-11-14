extends RefCounted
## Сценарии новой игры (кем начинает героиня) и места старта по биомам.
## Сценарий: что надето, что в сумке, сколько монет и семян, свои плюсы (stats — как у вещей, см. items_db.gd).

const SCEN_ORDER: Array = ["herbalist", "beggar", "wanderer", "scholar", "alchemist"]

const SCEN: Dictionary = {
	"herbalist": {
		"name": "Травница", "icon": "gear_sickle",
		"text": "Обычное начало: дом, топор и серп, котомка, немного семян и монет.",
		"plus": ["Ничего особенного — и ничего лишнего"],
		"coins": 20, "seeds": {"mint": 4, "lavender": 3, "chamomile": 3},
		"wear": {"body": "dress", "pack": "pack_sack", "main1": "axe", "off1": "sickle", "belt": "belt_rope", "feet": "boots_old"},
		"items": {},
		"stats": {},
	},
	"beggar": {
		"name": "Нищая", "icon": "gear_rags",
		"text": "Нет ничего, кроме дома и рваной одежды. Ни топора, ни монет, ни семян.",
		"plus": ["Неприхотлива: голод и жажда растут на 35% медленнее", "Жалеют: в лавках всё на 15% дешевле"],
		"coins": 0, "seeds": {},
		"wear": {"body": "rags"},
		"items": {},
		"stats": {"hunger": -35, "thirst": -35, "buy": 15},
	},
	"wanderer": {
		"name": "Опытная странница", "icon": "gear_pack_travel",
		"text": "Исходила полмира. Большой рюкзак, сапоги, плащ и нож грибника.",
		"plus": ["Ходит и бегает на 12% быстрее", "Видит дальше: карта открывается шире", "Большой рюкзак (+25 к весу)"],
		"coins": 40, "seeds": {"mint": 2},
		"wear": {"body": "cloak_travel", "head": "hood", "feet": "boots_travel", "pack": "pack_travel", "main1": "axe", "off1": "knife", "belt": "belt_rope"},
		"items": {"lantern_hand": 1},
		"stats": {"speed": 12, "reveal": 60},
	},
	"scholar": {
		"name": "Научная исследовательница", "icon": "gear_goggles",
		"text": "Учёная из столицы. Гербарий, очки-лупы, стол изучения трав в наборе.",
		"plus": ["Все обычные травы уже изучены", "Торговки платят на 10% больше", "Чаще находит семена у диких трав"],
		"coins": 80, "seeds": {"mint": 2, "chamomile": 2},
		"wear": {"body": "lab_coat", "head": "goggles", "pack": "pack_herb", "main1": "trowel", "off1": "herbarium", "hands": "gloves_garden", "feet": "boots_old"},
		"items": {"kit:research": 1, "axe": 1},
		"stats": {"sell": 10, "seed": 20},
	},
	"alchemist": {
		"name": "Зельевар", "icon": "gear_witch_hat",
		"text": "Варила зелья в городе, теперь своя хижина. Котёл в наборе, зелья на поясе.",
		"plus": ["Четверть варок даёт два зелья", "Знает два рецепта", "Ларец: зелья ничего не весят"],
		"coins": 50, "seeds": {"mint": 3, "lavender": 2},
		"wear": {"body": "apron", "head": "witch_hat", "pack": "pack_alch", "belt": "belt_leather", "main1": "axe", "ring1": "ring_amber",
			"flask0": "vigor_tea", "flask1": "mint_tea", "flask2": "heal_salve"},
		"items": {"kit:cauldron": 1, "mint": 3, "lavender": 2, "chamomile": 2},
		"recipes": {"mint_tea": ["water", "mint", "mint"], "calm_tea": ["water", "lavender", "chamomile"]},
		"stats": {"brew": 25},
	},
}

# Где можно начать: биом, название, регион (там ищется свободная поляна), цвет карточки
const SPAWN_ORDER: Array = ["home", "birch", "pine", "autumn", "field", "unicorn", "grotto", "swamp", "beach", "wild_pine_nw", "wild_birch_n", "wild_autumn_ne", "wild_pink_n", "wild_grotto_ne", "wild_swamp_w", "wild_pine_e", "wild_birch_se", "wild_autumn_w", "wild_pine_w", "random"]
const SPAWNS: Dictionary = {
	"home": {"name": "Родной луг", "text": "Старый двор с прудом в середине мира", "region": Vector2i(0, 0), "biome": 0, "col": Color("8fae62")},
	"birch": {"name": "Берёзовая роща", "text": "Светло, тихо, много трав", "region": Vector2i(2, 2), "biome": 12, "col": Color("b4c87c")},
	"pine": {"name": "Хвойная тайга", "text": "Сосны, ели и грибы", "region": Vector2i(-4, -2), "biome": 13, "col": Color("5e8a64")},
	"autumn": {"name": "Осенний лес", "text": "Вечная золотая осень", "region": Vector2i(-3, 0), "more": [Vector2i(-3, 2), Vector2i(-1, -2)], "biome": 14, "col": Color("d0985a")},
	"field": {"name": "Цветочные поля", "text": "Простор, стога и цветы", "region": Vector2i(-2, 1), "biome": 16, "col": Color("d8cc78")},
	"unicorn": {"name": "Розовый лес", "text": "Тут бродят единороги", "region": Vector2i(2, -2), "more": [Vector2i(3, -2), Vector2i(2, -3)], "biome": 10, "col": Color("e8a8c8")},
	"grotto": {"name": "Гроты", "text": "Камни, пещеры, светящиеся грибы", "region": Vector2i(-3, -3), "biome": 11, "col": Color("6a6880")},
	"swamp": {"name": "Болото", "text": "Сыро и туманно, зато редкие травы", "region": Vector2i(-6, 1), "biome": 15, "col": Color("6e8a6a")},
	"beach": {"name": "Побережье", "text": "Песок, пальмы и шум моря", "region": Vector2i(-2, 5), "biome": 18, "col": Color("ecdca0")},
	# v18: глухие леса на краях расширенной карты — до городов далеко, но не безнадёжно
	"wild_pine_nw": {"name": "Дремучий бор", "text": "Северо-запад, сосны до неба", "region": Vector2i(-5, -6), "more": [Vector2i(-6, -6), Vector2i(-3, -6)], "biome": 13, "col": Color("4d7a58"), "wild": true},
	"wild_birch_n": {"name": "Берёзовая глушь", "text": "Север, светлая тишина", "region": Vector2i(-1, -6), "more": [Vector2i(-2, -6), Vector2i(-1, -5)], "biome": 12, "col": Color("a8bf70"), "wild": true},
	"wild_autumn_ne": {"name": "Золотая чаща", "text": "Северо-восток, листопад", "region": Vector2i(6, -6), "more": [Vector2i(8, -5)], "biome": 14, "col": Color("c98a4a"), "wild": true},
	"wild_pink_n": {"name": "Розовая чаща", "text": "Север, лес единорогов", "region": Vector2i(2, -6), "more": [Vector2i(3, -6), Vector2i(4, -7)], "biome": 10, "col": Color("e096be"), "wild": true},
	"wild_grotto_ne": {"name": "Лесные пещеры", "text": "Камни и мох среди сосен", "region": Vector2i(-2, -5), "more": [Vector2i(-6, -7)], "biome": 11, "col": Color("625f78"), "wild": true},
	"wild_swamp_w": {"name": "Топкий лес", "text": "Запад, туман и лягушки", "region": Vector2i(-7, -6), "more": [Vector2i(-9, 0), Vector2i(-8, 1)], "biome": 15, "col": Color("62806a"), "wild": true},
	"wild_pine_e": {"name": "Восточная тайга", "text": "Северо-восток, хвоя и ветер", "region": Vector2i(9, -4), "more": [Vector2i(10, -3)], "biome": 13, "col": Color("56806a"), "wild": true},
	"wild_birch_se": {"name": "Восточная роща", "text": "Юго-восток, берёзы", "region": Vector2i(10, 2), "more": [Vector2i(9, 0), Vector2i(9, 3)], "biome": 12, "col": Color("b0c47a"), "wild": true},
	"wild_autumn_w": {"name": "Западная осень", "text": "Запад, багрянец", "region": Vector2i(-7, 4), "more": [Vector2i(-8, 3)], "biome": 14, "col": Color("c58850"), "wild": true},
	"wild_pine_w": {"name": "Западный ельник", "text": "Дальний запад, сумрак", "region": Vector2i(-7, -4), "more": [Vector2i(-8, -4)], "biome": 13, "col": Color("4a7254"), "wild": true},
	"random": {"name": "Случайный лес", "text": "Судьба выберет глушь сама", "region": Vector2i(-5, -6), "biome": 13, "col": Color("8a9a7a")},
}


## Дом всегда ставится не ближе этого расстояния до центра любого города (пикселей мира)
const MIN_TOWN_DIST: float = 2300.0


## Расстояние от точки до ближайшего города
static func town_dist(p: Vector2) -> float:
	var WD = preload("res://world_data.gd")
	var best: float = 1e9
	for tc in WD.TOWN_C.values():
		best = minf(best, p.distance_to(tc))
	return best


static func get_s(id: String) -> Dictionary:
	return SCEN.get(id, SCEN["herbalist"])


## Свободная поляна для дома в регионе: подальше от дорог, городов и особых мест, весь участок — в своём биоме
static func find_home(key: String) -> Vector2:
	var WD = preload("res://world_data.gd")
	if key == "random":
		var wild: Array = []
		for k in SPAWN_ORDER:
			if bool((SPAWNS[k] as Dictionary).get("wild", false)):
				wild.append(k)
		key = String(wild[randi() % wild.size()])
	var sp: Dictionary = SPAWNS.get(key, SPAWNS["home"])
	if key == "home":
		return Vector2(960, 358)
	var want: int = int(sp["biome"])
	var regs: Array = [sp["region"]]
	regs.append_array(sp.get("more", []))
	var best: Vector2 = Vector2.ZERO
	var best_score: float = -1e9
	for rv in regs:
		var r: Vector2i = rv
		var c: Vector2 = Vector2(r.x * WD.RW + WD.RW / 2.0, r.y * WD.RH + WD.RH / 2.0)
		var res: Array = _search(c, want)
		if float(res[1]) > best_score:
			best_score = float(res[1])
			best = res[0]
		if best_score > 140.0:
			break
	return best


## Лучшая точка вокруг центра региона: [точка, оценка] (оценка > 140 — двор далеко от дорог и мест)
static func _search(c: Vector2, want: int) -> Array:
	var WD = preload("res://world_data.gd")
	var best: Vector2 = c
	var best_score: float = -1e9
	# v20: ищем шире (до ~1700 px от центра региона) и строже: чужие стоянки, хижины, пещеры
	# и края других биомов — далеко от двора (раньше дом вставал впритык к стоянке изгоев)
	for ring in range(0, 22):
		for k in range(maxi(1, ring * 6)):
			var a: float = TAU * float(k) / float(maxi(1, ring * 6))
			var p: Vector2 = (c + Vector2(cos(a), sin(a) * 0.7) * float(ring) * 80.0).round()
			# весь двор (дом, участок) — подальше от дорог: проверяем сеткой точек
			var score: float = 400.0
			for gy in range(-3, 4):
				for gx in range(-4, 5):
					score = minf(score, WD.road_value(p + Vector2(gx * 90.0, gy * 100.0)) + 60.0)
			for tc in WD.TOWN_C.values():
				# v18: дом всегда далеко от городов (не ближе MIN_TOWN_DIST), но и не на краю света
				score = minf(score, p.distance_to(tc) - MIN_TOWN_DIST)
			for lm in WD.LANDMARKS:
				if String(lm[2]) != "home":
					score = minf(score, Vector2(float(lm[0]), float(lm[1])).distance_to(p) - 1150.0)
			score = minf(score, p.distance_to(WD.PIER) - 900.0)
			# весь участок (дом и двор) — в нужном биоме
			for q in [Vector2(-300, -250), Vector2(300, -250), Vector2(-300, 250), Vector2(300, 250), Vector2.ZERO]:
				if WD.biome_at(p + (q as Vector2)) != want:
					score -= 200.0
			# и вокруг двора свой биом: до края другого — не меньше ~700 px
			for i in range(12):
				var aa: float = TAU * float(i) / 12.0
				if WD.biome_at(p + Vector2(cos(aa) * 720.0, sin(aa) * 560.0)) != want:
					score -= 70.0
			if score > best_score:
				best_score = score
				best = p
		if best_score > 140.0:
			break
	return [best, best_score]

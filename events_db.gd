extends RefCounted
## v22: события дней. День определяет событие сам (по номеру дня), поэтому сохранять ничего не нужно:
## в один и тот же день всегда одно и то же событие. Праздники идут по календарю, остальное — случайно.
## mods — поправки в процентах к Game.stat(): speed, thirst, hunger, sell, buy, herb (шанс двойного сбора),
## herb_grow (шанс, что на месте трав что-то выросло), sea_grow (то же для морских трав), shroom.
## gift — подарок утром: coins [от, до], items [[id, от, до], ...], rep [земля, сколько].
## tint — оттенок света в этот день.

const NONE: String = "calm"

const DATA: Dictionary = {
	"calm": {"name": "Обычный день", "text": "Ничего особенного. Хороший день для работы.", "w": 34, "mods": {}},
	"sunny": {"name": "Ясный день", "text": "Тепло и ясно. Ноги сами несут вперёд.", "w": 9, "mods": {"speed": 8, "herb_grow": 8}, "tint": Color(1.04, 1.02, 0.96)},
	"rain": {"name": "Дождливый день", "text": "Тихий дождь по крышам. Травы тянутся к небу, а жажды почти нет.", "w": 9, "mods": {"herb_grow": 25, "speed": -4, "thirst": -40}, "tint": Color(0.80, 0.88, 1.0)},
	"storm": {"name": "Гроза", "text": "Гремит так, что звенит посуда. Лучше не уходить далеко.", "w": 4, "mods": {"speed": -10, "herb_grow": -12, "shroom": 30}, "tint": Color(0.62, 0.68, 0.84)},
	"fog": {"name": "Туман", "text": "Всё как в молоке. Грибы довольны, а ты почти ничего не видишь.", "w": 6, "mods": {"shroom": 30, "herb_grow": 10}, "tint": Color(0.86, 0.9, 0.96)},
	"heat": {"name": "Знойный день", "text": "Жарко до звона в ушах. Пить хочется вдвое чаще.", "w": 6, "mods": {"thirst": 60, "herb_grow": -10, "speed": -3}, "tint": Color(1.08, 0.98, 0.86)},
	"frost": {"name": "Заморозок", "text": "Иней на траве. Нос красный, есть хочется сильнее.", "w": 5, "mods": {"hunger": 30, "thirst": -30, "herb_grow": -10}, "tint": Color(0.9, 0.95, 1.06)},
	"rainbow": {"name": "Радуга", "text": "Над лугом радуга. Жители в хорошем настроении и щедрее платят.", "w": 5, "mods": {"sell": 12, "herb_grow": 12}, "tint": Color(1.03, 1.0, 1.04)},
	"bees": {"name": "Пчёлы роятся", "text": "Над цветами гудит. Травы собираются щедрее.", "w": 5, "mods": {"herb": 18, "herb_grow": 10}},
	"fireflies": {"name": "Ночь светлячков", "text": "Вечером лес засияет. Редкие травы показываются охотнее.", "w": 5, "mods": {"herb_grow": 20, "shroom": 15}},
	"stars": {"name": "Звездопад", "text": "Ночью небо чертит звёздами. Говорят, на рассвете находят звёздную пыль.", "w": 3, "mods": {"herb_grow": 18}, "gift": {"items": [["star_dust", 1, 1]]}},
	"gift_forest": {"name": "Подарок леса", "text": "У крыльца кто-то оставил охапку трав. Спасибо, лес!", "w": 5, "mods": {}, "gift": {"items": [["mint", 2, 4], ["lavender", 1, 3], ["chamomile", 1, 3], ["clover", 1, 3]]}},
	"lost_coins": {"name": "Находка у крыльца", "text": "Под ступенькой блестит кошелёк. Кто-то обронил.", "w": 4, "mods": {}, "gift": {"coins": [20, 60]}},
	"caravan": {"name": "Караван в деревне", "text": "Приехали торговцы. Покупать выгоднее, чем обычно.", "w": 6, "mods": {"buy": 20}},
	"demand": {"name": "Хороший спрос", "text": "Все спрашивают зелья. Продавать выгоднее.", "w": 6, "mods": {"sell": 20}},
	"cough": {"name": "Поветрие кашля", "text": "В деревне кашляют. Зелья нужны всем, платят щедро, но идти тяжело.", "w": 4, "mods": {"sell": 30, "speed": -4}},
	"cat_party": {"name": "Кошачий праздник", "text": "Кошкодевочки устроили пляски. Они стали к тебе добрее.", "w": 4, "mods": {"buy": 10, "sell": 8}, "gift": {"rep": ["cats", 3]}},
	"tide": {"name": "Большой прилив", "text": "Море вздохнуло полной грудью. На дне густо растут травы, а на берегу полно ракушек.", "w": 6, "mods": {"sea_grow": 70}, "gift": {"items": [["shell", 2, 4], ["pearl", 0, 1]]}},
	"mermaid_mail": {"name": "Весточка от русалок", "text": "Волна выбросила на берег бутылочку с ракушками. Русалки о тебе не забыли.", "w": 3, "mods": {"sea_grow": 30}, "gift": {"items": [["shell", 2, 3], ["conch", 1, 1], ["sea_glass", 1, 2]]}},
	# праздники по календарю
	"bazaar": {"name": "Базарный день", "text": "Каждый седьмой день на площади базар. Жители платят на четверть больше.", "w": 0, "mods": {"sell": 25, "buy": 10}, "tint": Color(1.03, 1.01, 0.98)},
	"harvest_fair": {"name": "Ярмарка урожая", "text": "Большая ярмарка! Платят щедро, травы растут на славу, а староста раздаёт монеты.", "w": 0, "mods": {"sell": 40, "herb_grow": 25, "herb": 15}, "tint": Color(1.06, 1.0, 0.92), "gift": {"coins": [40, 80]}},
	"sea_feast": {"name": "Праздник моря", "text": "Раз в месяц русалки празднуют. Море полно жемчуга, а редкие травы вылезают на мелководье.", "w": 0, "mods": {"sea_grow": 120, "sell": 10}, "tint": Color(0.96, 1.02, 1.06), "gift": {"items": [["pearl", 1, 2], ["shell", 2, 4]]}},
}

static var _cache_day: int = -1
static var _cache_id: String = NONE


## Что за событие в этот день (всегда одно и то же для одного и того же дня)
static func for_day(day: int) -> String:
	if day == _cache_day:
		return _cache_id
	var id: String = _pick(day)
	_cache_day = day
	_cache_id = id
	return id


static func _pick(day: int) -> String:
	if day <= 1:
		return NONE                 # первый день без сюрпризов
	if day % 30 == 20:
		return "sea_feast"
	if day % 30 == 14:
		return "harvest_fair"
	if day % 7 == 0:
		return "bazaar"
	var r: RandomNumberGenerator = RandomNumberGenerator.new()
	r.seed = hash("v22/day/%d" % day)
	var total: float = 0.0
	for k in DATA.keys():
		total += float((DATA[k] as Dictionary)["w"])
	var roll: float = r.randf() * total
	for k2 in DATA.keys():
		roll -= float((DATA[k2] as Dictionary)["w"])
		if roll <= 0.0:
			return String(k2)
	return NONE


static func mod(day: int, key: String) -> float:
	return float(((DATA[for_day(day)] as Dictionary).get("mods", {}) as Dictionary).get(key, 0.0))


static func tint(day: int) -> Color:
	return (DATA[for_day(day)] as Dictionary).get("tint", Color(1, 1, 1))


static func title(id: String) -> String:
	return String((DATA[id] as Dictionary)["name"]) if DATA.has(id) else id


## Что ждёт в ближайшие дни: [[день, id], ...] только про особенные (не «обычный день»)
static func upcoming(from_day: int, count: int) -> Array:
	var out: Array = []
	for d in range(from_day, from_day + 60):
		var id: String = _pick(d)
		if id != NONE and (d == from_day or id in ["bazaar", "harvest_fair", "sea_feast"]):
			out.append([d, id])
			if out.size() >= count:
				break
	return out

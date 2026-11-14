extends RefCounted
## Справочник рыб маленького пруда: названия, как часто клюют, как трудно вытащить.

const ORDER: Array = ["minnow", "roach", "crucian", "perch", "tench", "loach", "golden"]

## weight — как часто клюёт, zone — ширина зелёной полосы (доля шкалы, меньше = труднее),
## speed — как быстро бегает ползунок, price — цена (пока для будущего рынка).
const POND: Dictionary = {
	"minnow": {
		"name": "Гольян", "short": "Гольян",
		"desc": "Крохотная серебристая рыбка с тёмной полоской. Стайками шныряет у берега.",
		"weight": 22.0, "zone": 0.30, "speed": 1.45, "price": 3,
	},
	"roach": {
		"name": "Плотва", "short": "Плотва",
		"desc": "Серебристая, с красными плавниками и красным глазом. Самая частая гостья в пруду.",
		"weight": 26.0, "zone": 0.25, "speed": 1.15, "price": 5,
	},
	"crucian": {
		"name": "Карась", "short": "Карась",
		"desc": "Золотистый и круглый, как пирожок. Любит тихие заросшие места.",
		"weight": 30.0, "zone": 0.26, "speed": 1.0, "price": 6,
	},
	"perch": {
		"name": "Окунь", "short": "Окунь",
		"desc": "Полосатый разбойник с колючим плавником. Клюёт на заре и на закате.",
		"weight": 18.0, "zone": 0.20, "speed": 1.3, "price": 9,
	},
	"tench": {
		"name": "Линь", "short": "Линь",
		"desc": "Тёмно-зелёный, скользкий и степенный. Прячется в иле, лучше берётся ночью.",
		"weight": 12.0, "zone": 0.18, "speed": 1.2, "price": 12,
	},
	"loach": {
		"name": "Вьюн", "short": "Вьюн",
		"desc": "Длинный пятнистый вьюн с усиками. Вылезает из ила, когда темнеет.",
		"weight": 10.0, "zone": 0.16, "speed": 1.6, "price": 10,
	},
	"golden": {
		"name": "Золотой карась", "short": "Зол. карась",
		"desc": "Редкость! Говорят, он блестит так только на рассвете и закате. Береги его.",
		"weight": 2.0, "zone": 0.10, "speed": 1.8, "price": 40,
	},
}


## v23: + морские рыбы и акулы (v23_data.SEA_FISH) — ловятся с пирса
const V23 = preload("res://v23_data.gd")
static var DATA: Dictionary = _all()


static func _all() -> Dictionary:
	var out: Dictionary = POND.duplicate()
	for k in V23.SEA_FISH.keys():
		var f: Dictionary = V23.SEA_FISH[k]
		out[k] = {"name": String(f["name"]), "short": String(f["name"]), "desc": String(f["desc"]), "weight": float(f["weight"]),
			"zone": float(f["zone"]), "speed": float(f["speed"]), "price": int(f["price"]), "sea": true}
	return out


static func is_sea(id: String) -> bool:
	return V23.SEA_FISH.has(id)


## Морская рыба на крючке: глубже — крупнее (акулы — далеко от берега), ночью — лунная рыба
static func roll_sea(h: float, r: float, d: float) -> String:
	var w: Dictionary = {}
	var total: float = 0.0
	var night: bool = h < 6.0 or h >= 20.5
	for id in V23.SEA_ORDER:
		var f: Dictionary = V23.SEA_FISH[id]
		var near: float = 1.0 - absf(float(f["depth"]) - d)
		var x: float = float(f["weight"]) * maxf(0.05, near * near)
		if String(id) == "sea_moon" and not night:
			x = 0.0
		if String(id) == "sea_lantern" and not night:
			x *= 0.3
		w[id] = x
		total += x
	var k: float = clampf(r, 0.0, 0.9999) * total
	for id2 in V23.SEA_ORDER:
		k -= float(w[id2])
		if k < 0.0:
			return String(id2)
	return "sea_sardine"


static func is_fish(id: String) -> bool:
	return DATA.has(id)


static func title(id: String) -> String:
	return String(DATA[id]["name"]) if DATA.has(id) else id


static func short(id: String) -> String:
	return String(DATA[id]["short"]) if DATA.has(id) else id


static func icon(id: String) -> Texture2D:
	return load("res://art/fish_%s.png" % id)


## Во сколько раз эта рыба чаще или реже клюёт в такой час
static func time_mult(id: String, h: float) -> float:
	var night: bool = h < 6.5 or h >= 20.0
	var edge: bool = (h >= 5.5 and h < 9.0) or (h >= 17.0 and h < 20.5)
	match id:
		"perch":
			return 2.2 if edge else 1.0
		"tench":
			if night:
				return 2.5
			return 0.6 if (h >= 10.0 and h < 16.0) else 1.0
		"loach":
			return 2.5 if night else 0.5
		"minnow":
			return 1.6 if (h >= 10.0 and h < 16.0) else 1.0
		"golden":
			return 5.0 if ((h >= 6.0 and h < 8.0) or (h >= 17.0 and h < 19.0)) else 1.0
	return 1.0


## Глубина места заброса: 0 — у берега, мелко; 1 — самая середина пруда.
## Во сколько раз эта рыба чаще или реже попадается на такой глубине.
static func depth_mult(id: String, d: float) -> float:
	match id:
		"minnow":
			return lerpf(2.6, 0.25, d)
		"roach":
			return lerpf(1.6, 0.8, d)
		"crucian":
			return lerpf(1.4, 0.9, d)
		"perch":
			return lerpf(0.5, 2.0, d)
		"tench":
			return lerpf(0.3, 2.4, d)
		"loach":
			return lerpf(0.8, 1.6, d)
		"golden":
			return lerpf(0.0, 3.0, d)
	return 1.0


## Шанс, что рыба вообще подойдёт к поплавку: у берега почти нет, на глубине почти всегда
static func bite_chance(d: float) -> float:
	return lerpf(0.08, 0.95, smoothstep(0.05, 0.8, d))


## Шансы по часам и глубине: {id: вес}
static func weights(h: float, d: float = 0.5) -> Dictionary:
	var out: Dictionary = {}
	for id in ORDER:
		out[id] = float(DATA[id]["weight"]) * time_mult(String(id), h) * depth_mult(String(id), d)
	return out


## Какая рыба клюнула. r — случайное число 0..1 (можно подставить для проверки).
static func roll(h: float, r: float, d: float = 0.5) -> String:
	var w: Dictionary = weights(h, d)
	var total: float = 0.0
	for id in ORDER:
		total += float(w[id])
	var x: float = clampf(r, 0.0, 0.9999) * total
	for id in ORDER:
		x -= float(w[id])
		if x < 0.0:
			return String(id)
	return String(ORDER[ORDER.size() - 1])

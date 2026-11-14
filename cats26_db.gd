extends RefCounted
## v26: окрасы котов. Все коты — перекраска чёрного кота травницы (art/cat.png), котята — уменьшенные
## те же кадры (tools/cats26.py). Окрас в игре — строка: "ginger", котёнок — "kit_ginger".
## Редкость: 0 обычный, 1 необычный, 2 редкий, 3 сказочный.

const TIER_NAME: Array = ["обычный", "необычный", "редкий", "сказочный"]
const TIER_RU_F: Array = ["обычная", "необычная", "редкая", "сказочная"]

## окрас -> [имя, редкость, описание]
const DATA: Dictionary = {
	"black": ["Чёрный кот", 0, "Угольно-чёрный, глаза жёлто-зелёные — как кот травницы."],
	"ginger": ["Рыжий кот", 0, "Солнечно-рыжий, любит греться на крылечках."],
	"white": ["Белая кошка", 0, "Белоснежная. Котята у неё голубоглазые."],
	"gray": ["Серый кот", 0, "Простой серый кот с янтарными глазами. Ловит мышей лучше всех."],
	"calico": ["Трёхцветная кошка", 1, "Белая с рыжими и чёрными пятнами. Говорят, приносит удачу дому."],
	"tabby_ginger": ["Рыжий полосатый", 0, "Рыжий в тёмных полосках, на лбу буква «М»."],
	"tabby_gray": ["Серый полосатый", 0, "Серый табби: полоски на боках, кольца на хвосте и лапах."],
	"tabby_brown": ["Бурый полосатый", 0, "Окрас лесного кота: бурые полосы, чтобы прятаться в траве."],
	"cream": ["Кремовый кот", 0, "Мягкий, как сливки. Глаза медные."],
	"cream_tabby": ["Кремовый полосатый", 0, "Светлый, с едва заметными полосками."],
	"choco": ["Шоколадный кот", 0, "Тёплый коричневый, как плитка шоколада."],
	"smoke": ["Дымчатый кот", 1, "Сверху тёмный, к брюшку светлеет — будто окутан дымом."],
	"blue": ["Голубой кот", 1, "Серо-голубая шубка и зелёные глаза. Тихий и вежливый."],
	"tuxedo": ["Кот во фраке", 0, "Чёрный с белой манишкой, носочками и мордочкой — всегда нарядный."],
	"gray_white": ["Серо-белый кот", 0, "Серая спинка, белые лапки и грудка."],
	"ginger_white": ["Рыже-белый кот", 0, "Рыжая спинка, белые лапки и грудка."],
	"siamese": ["Сиамская кошка", 1, "Светлая, с тёмными ушками, мордочкой, лапками и хвостом. Глаза голубые."],
	"tortie": ["Черепаховая кошка", 1, "Тёмная, с рыжими разводами, как панцирь черепахи."],
	"golden": ["Золотой кот", 2, "Шерсть с золотыми искорками блестит на солнце."],
	"lavender": ["Лавандовый кот", 2, "Сиреневый, в нежных полосках, с белыми носочками. Пахнет лавандой."],
	"sakura": ["Сакуровая кошка", 2, "Розовая, как цветы вишни, в пятнышках-лепестках."],
	"moonsilver": ["Лунно-серебристый кот", 3, "Серебристо-голубой, с лунным пятнышком на лбу. Гуляет при луне."],
	"starry": ["Звёздный кот", 3, "Тёмно-синий, а в шерсти мерцают звёздочки — как ночное небо."],
	"aurora": ["Кошка северного сияния", 3, "Переливается от мятного к розовому и сиреневому."],
}
const ORDER: Array = ["black", "ginger", "white", "gray", "calico", "tabby_ginger", "tabby_gray", "tabby_brown",
	"cream", "cream_tabby", "choco", "smoke", "blue", "tuxedo", "gray_white", "ginger_white", "siamese", "tortie",
	"golden", "lavender", "sakura", "moonsilver", "starry", "aurora"]
## эти окрасы взрослыми уже были раньше (cat.png и cat_lost_*.png из приюта)
const OLD: Array = ["black", "ginger", "white", "gray", "calico"]


static func is_kit(skin: String) -> bool:
	return skin.begins_with("kit_")


static func base(skin: String) -> String:
	return skin.substr(4) if is_kit(skin) else skin


static func tex_path(skin: String) -> String:
	var b: String = base(skin)
	if b == "":
		b = "black"
	# v26: все коты — пушистые перекраски (старые cat.png и cat_lost_*.png лежат как были)
	if is_kit(skin):
		return "res://art/cat26_kit_%s.png" % b
	return "res://art/cat26_%s.png" % b


static func tier(skin: String) -> int:
	return int((DATA.get(base(skin), ["", 0, ""]) as Array)[1])


static func title(skin: String) -> String:
	var b: String = base(skin)
	var nm: String = String((DATA.get(b, ["Кошка", 0, ""]) as Array)[0])
	return ("Котёнок — " + nm.to_lower()) if is_kit(skin) else nm


static func desc(skin: String) -> String:
	return String((DATA.get(base(skin), ["", 0, ""]) as Array)[2])


## Случайный окрас: с шансом rare_chance — редкий или сказочный (сказочный в 4 раза реже редкого),
## иначе обычный (вес 10) или необычный (вес 4)
static func pick(rng: RandomNumberGenerator, rare_chance: float) -> String:
	var want_rare: bool = rng.randf() < rare_chance
	var pool: Array = []
	var total: float = 0.0
	for s in ORDER:
		var t: int = int((DATA[s] as Array)[1])
		var w: float = 0.0
		if want_rare:
			w = 3.0 if t == 2 else (1.0 if t == 3 else 0.0)
		else:
			w = 10.0 if t == 0 else (4.0 if t == 1 else 0.0)
		if w > 0.0:
			pool.append([s, w])
			total += w
	var x: float = rng.randf() * total
	for p in pool:
		x -= float(p[1])
		if x <= 0.0:
			return String(p[0])
	return String(pool[pool.size() - 1][0])

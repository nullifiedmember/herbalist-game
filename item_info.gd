extends RefCounted
## v26: что делает каждая вещь — одна общая подсказка для сумки, сундуков и склада.
## lines(id) -> массив строк [текст, вид]: вид = "title" | "type" | "good" | "desc" | "hint" | "dim".
## Зелья: эффект по главному свойству (POTION_FX) — применяется в Game.drink_flask().

const IT = preload("res://items_db.gd")
const RDB = preload("res://recipes_db.gd")
const DB = preload("res://herbs_db.gd")
const W = preload("res://wild_db.gd")
const FDB = preload("res://fish_db.gd")
const MT = preload("res://mats_db.gd")
const MIN = preload("res://mining_db.gd")
const V23 = preload("res://v23_data.gd")
const V24 = preload("res://v24_data.gd")
const INS = preload("res://insects_db.gd")
const TD = preload("res://tree_db.gd")

## v26: значок для ячеек — без пустых краёв, чтобы рисунок заполнял клетку
static var _crop: Dictionary = {}


static func ui_icon(id: String) -> Texture2D:
	if _crop.has(id):
		return _crop[id]
	var t: Texture2D = IT.icon(id)
	var out: Texture2D = t
	if t != null:
		var img: Image = t.get_image()
		if img != null and not img.is_empty():
			if img.is_compressed():
				img.decompress()
			var r: Rect2i = img.get_used_rect()
			if r.size.x > 0 and r.size.y > 0 and r.size != img.get_size():
				var at: AtlasTexture = AtlasTexture.new()
				at.atlas = t if not (t is AtlasTexture) else (t as AtlasTexture).atlas
				var base: Vector2 = (t as AtlasTexture).region.position if t is AtlasTexture else Vector2.ZERO
				at.region = Rect2(base + Vector2(r.position), Vector2(r.size))
				out = at
	_crop[id] = out
	return out


## главное свойство зелья -> [что пишем, прибавки к Game.stat на время, секунд, особое]
const POTION_FX: Dictionary = {
	"Свежесть": ["Жажда и голод уходят, %s голод растёт вдвое медленнее", {"hunger": -50.0}, 180.0, "fresh"],
	"Покой": ["Стыд и тревога проходят, %s жажда растёт вдвое медленнее", {"thirst": -50.0}, 180.0, "calm"],
	"Сон": ["Силы возвращаются: здоровье +50%%, %s голод и жажда медленнее", {"hunger": -35.0, "thirst": -35.0}, 180.0, "heal_half"],
	"Тепло": ["%s бежишь быстрее (+25%% скорости)", {"speed": 25.0}, 180.0, ""],
	"Исцеление": ["Здоровье восстанавливается полностью", {}, 0.0, "heal"],
	"Сила": ["%s несёшь больше (+20 к весу)", {"cap": 20.0}, 180.0, ""],
	"Жгучесть": ["%s очень быстрая (+40%% скорости)", {"speed": 40.0}, 60.0, ""],
	"Холод": ["Жажда проходит совсем, %s почти не хочется пить", {"thirst": -80.0}, 180.0, "fresh"],
	"Огонь": ["%s: +30%% скорости и +10 к весу", {"speed": 30.0, "cap": 10.0}, 120.0, ""],
	"Свет": ["%s светишься в темноте, как фонарь", {"light": 1.0}, 300.0, ""],
	"Тьма": ["%s чуткие руки: +30%% шанс двойной травы и гриба", {"herb": 30.0, "shroom": 30.0}, 180.0, ""],
	"Чары": ["%s удача: +40%% двойной сбор, +10%% к цене продажи", {"herb": 40.0, "shroom": 40.0, "sell": 10.0}, 180.0, ""],
}
const RARITY_MULT: Array = [1.0, 1.5, 2.0, 3.0]


## Эффект зелья: [текст, прибавки, секунд, особое]. Пусто — только бодрость.
static func potion_fx(id: String) -> Array:
	if not RDB.PRODUCTS.has(id) or id == "murky" or id == "mermaid_tail":
		return []
	var main: String = RDB.strongest(RDB.PRODUCTS[id]["need"])
	if main == "" or not POTION_FX.has(main):
		return []
	var fx: Array = (POTION_FX[main] as Array).duplicate()
	fx[2] = float(fx[2]) * float(RARITY_MULT[clampi(RDB.rarity(id), 0, 3)])
	var tx: String = String(fx[0])
	if tx.contains("%s"):
		tx = tx % _mins(float(fx[2]))
	fx[0] = tx.replace("%%", "%")
	return fx


static func _mins(sec: float) -> String:
	if sec >= 60.0:
		return "%s мин" % (str(int(sec / 60.0)) if fmod(sec, 60.0) < 1.0 else "%.1f" % (sec / 60.0))
	return "%d с" % int(sec)


static func coins(n: int) -> String:
	var m10: int = n % 10
	var m100: int = n % 100
	if m10 == 1 and m100 != 11:
		return "%d монета" % n
	if m10 >= 2 and m10 <= 4 and (m100 < 12 or m100 > 14):
		return "%d монеты" % n
	return "%d монет" % n


## Примерная цена у торговцев (0 — не знаем)
static func price(id: String) -> int:
	var g: Dictionary = IT.gear(id)
	if not g.is_empty():
		return int(g.get("price", 0))
	if RDB.is_product(id):
		return RDB.price(id)
	if IT.is_food(id):
		return IT.FD.price(id)
	if MT.has(id):
		return MT.price(id)
	if W.is_shroom(id):
		return int(W.SHROOMS[id].get("price", 0))
	if FDB.is_fish(id):
		return int(FDB.DATA[id].get("price", 0))
	if DB.DATA.has(id):
		return int(DB.DATA[id].get("price", 0))
	if id.begins_with("ore_") and MIN.ORES.has(id.substr(4)):
		return int(MIN.ORES[id.substr(4)].get("price", 0))
	if IT.PRICE.has(id):
		return int(IT.PRICE[id])
	return 0


static func _props_line(p: Dictionary) -> String:
	var s: String = RDB.props_text(p)
	return "Для котла: " + s if s != "" else ""


## Все строки подсказки
static func lines(id: String) -> Array:
	var out: Array = []
	if id == "":
		return out
	var g: Dictionary = IT.gear(id)
	out.append([IT.name(id), "title_gear" if not g.is_empty() else "title"])
	if not g.is_empty():
		_gear(id, g, out)
	elif RDB.is_product(id):
		_potion(id, out)
	elif IT.is_food(id):
		out.append([String(IT.FD.KINDS.get(IT.FD.kind(id), "Еда")), "type"])
		if IT.FD.hunger_of(id) > 0.0:
			out.append(["Сытость +%d%%" % int(IT.FD.hunger_of(id) * 100.0), "good"])
		if IT.FD.juicy_of(id) > 0.0:
			out.append(["Утоляет жажду +%d%%" % int(IT.FD.juicy_of(id) * 100.0), "good"])
		out.append([IT.FD.desc(id), "desc"])
		out.append(["ПКМ — съесть", "hint"])
	elif DB.DATA.has(id):
		var d: Dictionary = DB.DATA[id]
		out.append(["Трава", "type"])
		out.append([_props_line(RDB.herb_props(id)), "good"])
		out.append([String(d.get("desc", "")), "desc"])
		out.append(["Где растёт: " + String(d.get("where", "")), "dim"])
		out.append(["Положи в котёл — свойства трав складываются в зелье", "hint"])
	elif IT.is_dry(id):
		out.append(["Сушёная трава", "type"])
		out.append(["Сушка меняет свойства: смотри в книге травника (%s)" % KB.key_name("book"), "desc"])
		out.append(["Положи в котёл", "hint"])
	elif W.is_shroom(id):
		var sd: Dictionary = W.SHROOMS[id]
		out.append(["Гриб", "type"])
		out.append([_props_line(RDB.SHROOM_PROPS.get(id, {})), "good"])
		if sd.has("food"):
			out.append(["Из него готовят еду (сытость до +%d%%)" % int(float(sd["food"]) * 100.0), "good"])
		out.append([String(sd.get("desc", "")), "desc"])
		out.append(["Где искать: " + String(sd.get("need", "")), "dim"])
		out.append(["Для котла или кухни", "hint"])
	elif FDB.is_fish(id):
		out.append(["Морская рыба" if FDB.is_sea(id) else "Рыба", "type"])
		out.append([String(FDB.DATA[id].get("desc", "")), "desc"])
		out.append(["Продай рыбаку или приготовь на кухне", "hint"])
	elif IT.is_leaf(id):
		out.append(["Лист дерева", "type"])
		out.append([_props_line(TD.ing_props(id)), "good"])
		out.append(["Положи в котёл", "hint"])
	elif IT.is_bug(id):
		var b: Dictionary = INS.DATA.get(id.substr(4), {})
		out.append(["Насекомое", "type"])
		out.append([_props_line(TD.ing_props(id)), "good"])
		out.append([String(b.get("effect", "")), "desc"])
		out.append(["Положи в котёл или отпусти", "hint"])
	elif id.begins_with("ore_") and MIN.ORES.has(id.substr(4)):
		out.append(["Самоцвет", "type"])
		out.append([String(MIN.ORES[id.substr(4)].get("desc", "")), "desc"])
		out.append(["Нужен для чар, сильных зелий и у кузнеца. Дорого стоит", "hint"])
	elif id.begins_with("stone_"):
		out.append(["Камень", "type"])
		out.append(["Строить дома, заборы и печи. Добывается киркой", "desc"])
	elif IT.BASE_ITEMS.has(id):
		out.append(["Основа для котла", "type"])
		out.append([String(IT.DESC.get(id, "")), "desc"])
		out.append(["Без основы зелье не сварить: вода — чай, воск — мазь, спирт — настойка", "hint"])
	elif id == "bottle":
		out.append(["Посуда", "type"])
		out.append(["Набери воды у колодца — получится основа для чая", "desc"])
	elif id == "log":
		out.append(["Дерево", "type"])
		out.append(["Для построек (%s). На верстаке пилится на доски" % KB.key_name("build"), "desc"])
	elif id == "quest_letter":
		out.append(["Задание", "type"])
		out.append(["Отнеси адресату — смотри задания (%s)" % KB.key_name("quests"), "desc"])
	elif preload("res://paths_db.gd").SMITH_ITEMS.has(id):
		out.append(["Кованое изделие", "type"])
		out.append([String(preload("res://paths_db.gd").SMITH_ITEMS[id][4]), "desc"])
		out.append(["Продай в городе или отдай по королевскому заказу", "hint"])
	elif V24.ITEMS.has(id):
		out.append(["Материал", "type"])
		if id == "branch_long":
			out.append(["ПКМ — разломать на 3 палки", "hint"])
	elif V23.BOOKS.has(id):
		out.append(["Книга", "type"])
		out.append(["ПКМ — прочитать: навык растёт", "good"])
	elif V23.JOKES.has(id):
		out.append(["Шутка", "type"])
		out.append([String(V23.JOKES[id].get("desc", "")), "desc"])
		out.append(["ПКМ — использовать", "hint"])
	elif V23.PRODUCTS.has(id):
		_farm(id, out)
	elif IT.is_furn(id):
		out.append(["Мебель", "type"])
		out.append(["Поставь в доме: режим построек (%s)" % KB.key_name("build"), "hint"])
	elif id.begins_with("kit:"):
		out.append(["Набор постройки", "type"])
		out.append(["Поставь на участке: режим построек (%s)" % KB.key_name("build"), "hint"])
	elif id.begins_with("sapling:"):
		out.append(["Саженец", "type"])
		out.append(["Посади на участке — вырастет дерево с плодами и листьями", "hint"])
	elif MT.has(id):
		out.append(["Материал", "type"])
		var mp: String = _props_line(MT.props(id))
		if mp != "":
			out.append([mp, "good"])
		out.append(["Для мастерских и построек", "hint"])
	var pr: int = price(id)
	if pr > 0:
		out.append(["Цена: около " + coins(pr), "dim"])
	var clean: Array = []
	for l in out:
		if String(l[0]).strip_edges() != "":
			clean.append(l)
	return clean


static func _farm(id: String, out: Array) -> void:
	out.append(["С фермы", "type"])
	match id:
		"egg", "egg_duck", "egg_goose":
			out.append(["Сытость +35%", "good"])
			out.append(["ПКМ — съесть. Или на кухню", "hint"])
		"milk", "milk_goat":
			out.append(["Жажда +50%, сытость +15%", "good"])
			out.append(["ПКМ — выпить", "hint"])
		"milk_rainbow":
			out.append(["Жажда +50%, здоровье полностью", "good"])
			out.append(["ПКМ — выпить", "hint"])
		"hp_potion":
			out.append(["Здоровье полностью, сытость +35%", "good"])
			out.append(["ПКМ — съесть", "hint"])
		"wool_raw":
			out.append(["Пряди в мастерской — будут нитки и ткань", "hint"])
		"truffle":
			out.append(["Редкий гриб — очень дорогой", "good"])
		"manure":
			out.append(["Удобрение: грядки растут быстрее", "hint"])


static func _potion(id: String, out: Array) -> void:
	var p: Dictionary = RDB.PRODUCTS[id]
	var r: int = RDB.rarity(id)
	out.append(["Зелье · " + String(RDB.RARITY_NAME[clampi(r, 0, 3)]), "type"])
	if id == "murky":
		out.append([String(p.get("use", "")), "desc"])
		return
	if id == "mermaid_tail":
		out.append(["Выпить: 8 часов можно плавать под водой с хвостом", "good"])
	else:
		var fx: Array = potion_fx(id)
		if not fx.is_empty():
			out.append(["Выпить: " + String(fx[0]), "good"])
		out.append(["И всегда: жажда проходит, минуту +20% скорости", "good"])
	out.append([String(p.get("use", "")), "desc"])
	out.append(["Повесь на пояс (ПКМ) и пей на %s. Или продай" % KB.key_name("potion"), "hint"])


static func _gear(id: String, g: Dictionary, out: Array) -> void:
	const SLOT_NAMES: Dictionary = {
		"tool": "Инструмент · в любую руку", "off": "Вторая рука", "head": "Голова", "body": "Одежда", "hands": "Руки",
		"feet": "Ноги", "neck": "Амулет", "ring": "Кольцо", "belt": "Пояс", "pack": "Рюкзак",
	}
	out.append([String(SLOT_NAMES.get(String(g["slot"]), "")) if not bool(g.get("wpn", false)) else "Оружие · в руку", "type"])
	var st: Dictionary = g.get("stats", {})
	for k in st.keys():
		out.append([stat_text(String(k), float(st[k])), "good"])
	if g.has("rows"):
		out.append(["Открывает %d ряда сумки" % int(g["rows"]), "good"])
	if g.has("flasks"):
		out.append(["%d ячеек для зелий" % int(g["flasks"]), "good"])
	if not String(g.get("desc", "")).begins_with("Сила удара"):
		out.append([String(g.get("desc", "")), "desc"])
	elif String(g.get("desc", "")).contains("\n"):
		out.append([String(g.get("desc", "")).get_slice("\n", 1), "desc"])
	out.append(["Двойной клик или ПКМ — надеть", "hint"])


static func stat_text(k: String, v: float) -> String:
	match k:
		"atk":
			return "Сила удара %d" % int(v)
		"cap":
			return "+%d к переносимому весу" % int(v)
		"speed":
			return "+%d%% к скорости" % int(v)
		"herb":
			return "%d%% шанс собрать две травы" % int(v)
		"shroom":
			return "%d%% шанс срезать два гриба" % int(v)
		"seed":
			return "%d%% шанс найти семечко" % int(v)
		"sell":
			return "+%d%% к цене продажи" % int(v)
		"buy":
			return "Скидка %d%% в лавках" % int(v)
		"brew":
			return "%d%% шанс сварить два зелья" % int(v)
		"reveal":
			return "+%d%% обзора карты" % int(v)
		"hunger":
			return "Голод растёт на %d%% медленнее" % int(-v)
		"thirst":
			return "Жажда растёт на %d%% медленнее" % int(-v)
		"light":
			return "Светит вокруг ночью"
		"shroom_w":
			return "Грибы ничего не весят"
		"herb_w":
			return "Травы весят вдвое меньше"
		"fish_w":
			return "Рыба весит втрое меньше"
		"potion_w":
			return "Зелья ничего не весят"
	return k


## Собрать табличку-подсказку в box (VBoxContainer). font — словарь шрифтов hud.
static func fill_box(box: VBoxContainer, id: String, hud: Node, extra: Array = []) -> void:
	for c in box.get_children():
		box.remove_child(c)
		c.queue_free()
	var all: Array = lines(id)
	all.append_array(extra)
	for l in all:
		var kind: String = String(l[1])
		var lb: Label = Label.new()
		lb.text = String(l[0])
		lb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lb.custom_minimum_size = Vector2(340, 0)
		var fk: String = "font_body"
		var sz: int = 18
		var col: Color = Color("b8a888")
		match kind:
			"title":
				fk = "font_bold"; sz = 24; col = Color("e8e0d0")
			"title_gear":
				fk = "font_bold"; sz = 24; col = Color("f0d89a")
			"type":
				sz = 16; col = Color("a89878")
			"good":
				sz = 18; col = Color("8ea8ff")
			"hint":
				sz = 16; col = Color("9cc890")
			"dim":
				sz = 15; col = Color(0.66, 0.6, 0.47, 0.8)
		lb.add_theme_font_override("font", hud.get(fk))
		lb.add_theme_font_size_override("font_size", sz)
		lb.add_theme_color_override("font_color", col)
		box.add_child(lb)

extends RefCounted
## v24: бестиарий — выгрузка всего, что есть в игре, в папку на компьютере (картинки + data.json).
## Запуск: godot --headless --path . -- --classic --bestiary=<папка>
## Потом tools/bestiary24.py собирает из data.json красивую книгу index.html.

const DB = preload("res://herbs_db.gd")
const FDB = preload("res://fish_db.gd")
const FD = preload("res://food_db.gd")
const W = preload("res://wild_db.gd")
const RDB = preload("res://recipes_db.gd")
const BD = preload("res://birds_db.gd")
const BL = preload("res://birds_lore24.gd")
const INS = preload("res://insects_db.gd")
const MT = preload("res://mats_db.gd")
const IT = preload("res://items_db.gd")
const V23 = preload("res://v23_data.gd")
const ZOO = preload("res://farm23.gd")
const NPC = preload("res://npc_db.gd")
const SP = preload("res://spells25_db.gd")

var out: String = ""
var saved: Dictionary = {}
var n_img: int = 0

const TRICKS: Dictionary = {
	"slime": "Облепляет слизью — героиня еле идёт несколько секунд.",
	"bug": "Облепляет липкой паутинкой — героиня еле идёт.",
	"shroom": "Пускает сонные споры — героиня задрёмывает на месте.",
	"ghost": "Пугает — пару секунд всё управление наоборот.",
	"bat": "Мельтешит перед лицом — управление на миг наоборот.",
	"golem": "Швыряет в сторону и оглушает.",
	"frog": "Длинным языком притягивает к себе.",
	"skel": "Ворует вещь из сумки и удирает. Догони и победи — вернёт.",
	"hound": "Ворует еду из сумки и удирает.",
	"imp": "Ворует монетки и удирает.",
	"demon": "Ворует монетки и хохочет.",
}
const HOME_RU: Dictionary = {
	"cave": "пещеры", "ice": "ледяные пещеры", "meadow": "луговые норы", "sand": "песчаные гробницы",
	"forest": "лесные подземелья", "swamp": "болотные гроты", "crypt": "склепы", "crystal": "хрустальные пещеры",
	"hell": "Ад", "boss": "логово (главный монстр)",
}


func dump(dir: String) -> int:
	out = dir
	DirAccess.make_dir_recursive_absolute(out + "/img")
	var secs: Array = []
	secs.append(_herbs())
	secs.append(_shrooms())
	secs.append(_potions())
	secs.append(_food())
	secs.append(_animals())
	secs.append(_cats26())
	secs.append(_birds())
	secs.append(_fish())
	secs.append(_insects())
	secs.append(_monsters())
	secs.append(_people())
	secs.append(_mats())
	secs.append(_weapons())
	secs.append(_spells())
	secs.append(_furniture())
	secs.append(_nature27())
	var f: FileAccess = FileAccess.open(out + "/data.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"title": "Бестиарий «Лесного травника»", "sections": secs}, "\t"))
	f.close()
	return n_img


# ------------------------------------------------------------------ картинки

func _img(key: String, tex: Texture2D) -> String:
	if tex == null:
		return ""
	if saved.has(key):
		return saved[key]
	var im: Image = tex.get_image()
	if im == null or im.is_empty():
		return ""
	if im.is_compressed():
		im.decompress()
	# прозрачные отступы кадра (они нужны в игре) в бестиарии не нужны — режем по самой картинке
	var ur: Rect2i = im.get_used_rect()
	if ur.size.x > 0 and ur.size.y > 0 and ur.size != im.get_size():
		im = im.get_region(ur)
	var p: String = "img/%s.png" % key.validate_filename()
	im.save_png(out + "/" + p)
	saved[key] = p
	n_img += 1
	return p


func _frame(path: String, frames_x: int, frames_y: int = 1) -> Texture2D:
	if not ResourceLoader.exists(path):
		return null
	var src: Texture2D = load(path)
	var at: AtlasTexture = AtlasTexture.new()
	at.atlas = src
	at.region = Rect2(0, 0, src.get_width() / float(frames_x), src.get_height() / float(frames_y))
	return at


func _e(id: String, name: String, img: String, sub: String, lines: Array, tags: Array = []) -> Dictionary:
	var clean: Array = []
	for l in lines:
		if String(l) != "":
			clean.append(String(l))
	return {"id": id, "name": name, "img": img, "sub": sub, "text": clean, "tags": tags}


func _props(p: Variant) -> String:
	var parts: Array = []
	if p is Dictionary:
		for k in p:
			parts.append("%s %s" % [String(k), str(p[k])])
	elif p is Array:
		for x in p:
			parts.append("%s %s" % [String(x[0]), String(x[1])])
	return ", ".join(parts)


func _nm(id: String) -> String:
	if DB.DATA.has(id):
		return DB.title(id)
	if W.SHROOMS.has(id):
		return W.shroom_name(id)
	var n: String = IT.name(id)
	return n if n != "" else id


# ------------------------------------------------------------------ разделы

func _herbs() -> Dictionary:
	var land: Array = []
	var sea: Array = []
	for id in DB.ORDER:
		var d: Dictionary = DB.DATA[id]
		var e: Dictionary = _e(id, String(d["name"]), _img("herb_" + id, DB.icon(id)), String(d.get("latin", "")),
			[String(d.get("desc", "")), "Свойства: " + _props(d.get("props", [])), "Где растёт: " + String(d.get("where", "")),
			"Цена: %d мон." % int(d.get("price", 0))], ["семена есть"] if DB.SEEDS.has(id) else [])
		var wp27: String = "res://art/herbw_%s.png" % id
		if ResourceLoader.exists(wp27):   # v27: как трава растёт в мире (стиль яблока)
			e["img2"] = _img("herbw_" + id, load(wp27))
			e["img2_t"] = "так растёт в мире"
		if (d.get("biomes", []) as Array).has(19):
			sea.append(e)
		else:
			land.append(e)
	var groups: Array = [{"title": "Травы суши", "entries": land}]
	if not sea.is_empty():
		groups.append({"title": "Подводные травы (нужно зелье русалки)", "entries": sea})
	return {"id": "herbs", "title": "Травы", "icon": _img("herb_mint", DB.icon("mint")),
		"intro": "Всё, что растёт в полях, лесах и под водой. Свойства трав складываются в котле.", "groups": groups}


func _shrooms() -> Dictionary:
	var ents: Array = []
	for id in W.SHROOMS:
		var d: Dictionary = W.SHROOMS[id]
		var pr: Dictionary = RDB.SHROOM_PROPS.get(id, {})
		ents.append(_e(id, String(d["name"]), _img("shroom_" + id, W.shroom_icon(id)), "",
			["Где и когда: " + String(d.get("need", "")), ("Свойства в котле: " + _props(pr)) if not pr.is_empty() else "",
			"Цена: %d мон." % int(d.get("price", 0))]))
	return {"id": "shrooms", "title": "Грибы", "icon": ents[0]["img"] if not ents.is_empty() else "",
		"intro": "Грибы растут в своих лесах и часто только в своё время суток.", "groups": [{"title": "Грибы", "entries": ents}]}


func _potions() -> Dictionary:
	var by_base: Dictionary = {}
	for id in RDB.PRODUCTS:
		var d: Dictionary = RDB.PRODUCTS[id]
		var base: String = String(d.get("base", "water"))
		var ex: Array = d.get("ex", [])
		var ex_t: String = ""
		if ex.size() >= 3:
			var ings: Array = []
			for ing in (ex[2] as Array):
				var procs: Array = []
				for pc in (ing[1] as Array):
					procs.append(String(RDB.PROC_NAME.get(String(pc), String(pc))).to_lower())
				ings.append(_nm(String(ing[0])) + ((" (" + ", ".join(procs) + ")") if not procs.is_empty() else ""))
			ex_t = "Рецепт: %s, %s + %s" % [String(RDB.BASE_NAME.get(String(ex[0]), "")), String(RDB.TEMP_NAME.get(String(ex[1]), "")), " + ".join(ings)]
		var temp: String = String(d.get("temp", "any"))
		var rar: int = int(d.get("rarity", 0))
		var e: Dictionary = _e(id, String(d["name"]), _img("potion_" + id, RDB.icon(id)), String(RDB.RARITY_NAME[clampi(rar, 0, 3)]),
			[String(d.get("use", "")), "Нужно свойств: " + _props(d.get("need", {})),
			"Основа: %s%s" % [String(RDB.BASE_NAME.get(base, base)), ("" if temp == "any" else ", " + String(RDB.TEMP_NAME.get(temp, temp)))],
			ex_t, _keys_text(d.get("keys", []))],
			["rar%d" % rar])
		if not by_base.has(base):
			by_base[base] = []
		(by_base[base] as Array).append(e)
	var groups: Array = []
	for b in RDB.BASES:
		if by_base.has(b):
			groups.append({"title": "%s — %s" % [String(RDB.BASE_NAME[b]), String(RDB.BASE_KIND[b])], "entries": by_base[b]})
	var proc_t: Array = []
	for pc in RDB.PROCS:
		proc_t.append(String(RDB.PROC_NAME[pc]))
	return {"id": "potions", "title": "Зелья и рецепты", "icon": _img("potion_heal_salve", load("res://art/potion_heal_salve.png")),
		"intro": "Зелье получается, когда в котле набралось нужных свойств. Основа решает, что выйдет: чай, мазь, настойка, сироп или эликсир. Травы можно: " + ", ".join(proc_t).to_lower() + " — это меняет их свойства. Рецепт в карточке — один из возможных.",
		"groups": groups}


## Особые травы: каждая группа — «одна из»
func _keys_text(keys: Array) -> String:
	var parts: Array = []
	for g in keys:
		var names: Array = []
		for k in (g as Array):
			names.append(_nm(String(k)))
		parts.append(("одна из: " + ", ".join(names)) if names.size() > 1 else String(names[0]) if not names.is_empty() else "")
	return ("Обязательно: " + "; ".join(parts)) if not parts.is_empty() else ""


func _food() -> Dictionary:
	var by_kind: Dictionary = {}
	for id in FD.ORDER:
		var fid: String = "food_" + String(id)
		var e: Dictionary = _e(fid, FD.name(fid), _img("food_" + id, FD.icon(fid)), "",
			[FD.desc(fid), ("Где взять: " + FD.source(fid)) if FD.source(fid) != "" else "", "Цена: %d мон." % FD.price(fid)])
		var k: String = FD.kind(fid)
		if not by_kind.has(k):
			by_kind[k] = []
		(by_kind[k] as Array).append(e)
	var groups: Array = []
	for k in FD.KINDS:
		if by_kind.has(k):
			groups.append({"title": String(FD.KINDS[k]), "entries": by_kind[k]})
	var rec: Array = []
	for r in FD.RECIPES:
		var ins: Array = []
		for x in (r[0] as Array):
			ins.append(_nm(String(x)) if not FD.DATA.has(String(x)) else FD.name("food_" + String(x)))
		var res: String = "food_" + String(r[1])
		rec.append(_e("cook_" + String(r[1]) + str(rec.size()), FD.name(res), _img("food_" + String(r[1]), FD.icon(res)), "блюдо", [" + ".join(ins)]))
	groups.append({"title": "Кухонные рецепты", "entries": rec})
	return {"id": "food", "title": "Еда и блюда", "icon": _img("food_apple", FD.icon("food_apple")),
		"intro": "Плоды, ягоды, выпечка, супы и напитки. Внизу — что из чего готовится.", "groups": groups}


func _animals() -> Dictionary:
	var wild: Array = []
	var farm: Array = []
	var magic: Array = []
	for id in ZOO.ORDER:
		var z: Array = ZOO.ZOO[id]
		var info: Dictionary = W.ANIMALS.get(id, {})
		var nm: String = String(info.get("name", V23.FARM.get(id, {}).get("name", id)))
		var likes: Array = []
		for k in (z[2] as Array):
			likes.append(String(k))
		var pr: Array = z[3]
		var e: Dictionary = _e(id, nm, _img("animal_" + id, _frame("res://art/animal_%s.png" % id, 12)), "",
			[String(z[0]), "Пол: " + preload("res://sex27.gd").species_text(id) + " (у каждой особи свой, видно в подсказке)", "Где живёт: " + String(z[1]), "Любит: " + ", ".join(likes),
			"В загоне даёт: %s ×%d в день" % [_nm(String(pr[0])), int(pr[1])], "Малыши: %d%%" % int(float(z[4]) * 100.0)])
		if ResourceLoader.exists("res://art/animal_%s_baby.png" % id):   # малыш зверя — маленькой картинкой
			e["img2"] = _img("animal_%s_baby" % id, _frame("res://art/animal_%s_baby.png" % id, 12))
		if bool(info.get("mythic", false)):
			magic.append(e)
		elif bool(info.get("farm", false)) or V23.FARM.has(id):
			farm.append(e)
		else:
			wild.append(e)
	return {"id": "animals", "title": "Звери", "icon": _img("animal_fox", _frame("res://art/animal_fox.png", 12)),
		"intro": "Возьми в руку угощение и подойди — зверь пойдёт за тобой в загон.",
		"groups": [{"title": "Дикие звери", "entries": wild}, {"title": "Домашние", "entries": farm}, {"title": "Волшебные", "entries": magic}]}


## v26: коты всех окрасов и котята (все — перекраска кота травницы)
func _cats26() -> Dictionary:
	var CD = preload("res://cats26_db.gd")
	var by_tier: Array = [[], [], [], []]
	var kits: Array = []
	for s in CD.ORDER:
		var tr: int = CD.tier(s)
		var where: String = "Деревня кошкодевочек, города, изредка лес. "
		where += ["Встречается часто.", "Встречается нечасто.", "Редкий окрас: примерно 1 кот из 20 в деревне кошкодевочек, в городах и лесу ещё реже.", "Сказочный окрас: в 4 раза реже редких — большая удача!"][tr]
		var e: Dictionary = _e("cat26_" + s, CD.title(s), _img("cat26_" + s, _frame(CD.tex_path(s), 10)), String(CD.TIER_NAME[tr]) + " окрас",
			[CD.desc(s), where, "Погладь %d раз — пойдёт жить к тебе и будет ходить следом." % (3 + tr * 2), "При поглаживании иногда остаётся кошачья шерсть."],
			(["rar%d" % tr, String(CD.TIER_NAME[tr])] if tr > 0 else []))
		e["img2"] = _img("cat26_kit_" + s, _frame(CD.tex_path("kit_" + s), 10))
		e["img2_t"] = "котёнок"
		(by_tier[tr] as Array).append(e)
		kits.append(_e("cat26_kit_" + s, CD.title("kit_" + s), e["img2"], "котёнок",
			["Маленький, голова крупнее, лапки короче. Бегает за мамой-кошкой; часто в маму окрасом, иногда в папу.",
			"Погладь %d раз — пойдёт с тобой." % (3 + tr * 2)], (["rar%d" % tr] if tr > 0 else [])))
	return {"id": "cats26", "title": "Кошки и котята", "icon": _img("cat26_tabby_ginger", _frame(CD.tex_path("tabby_ginger"), 10)),
		"intro": "Все коты — родня кота травницы: та же порода, разные шубки. Каждый день в деревне кошкодевочек и в городах гуляют другие коты, иногда с котятами. Редкие окрасы выпадают редко.",
		"groups": [{"title": "Обычные окрасы", "entries": by_tier[0]}, {"title": "Необычные", "entries": by_tier[1]},
			{"title": "Редкие", "entries": by_tier[2]}, {"title": "Сказочные", "entries": by_tier[3]}, {"title": "Котята", "entries": kits}]}


func _birds() -> Dictionary:
	var day: Array = []
	var owls: Array = []
	var magic: Array = []
	for id in BD.ORDER:
		var d: Dictionary = BD.DATA[id]
		var e: Dictionary = _e(id, String(d["name"]), _img("bird_" + id, _frame("res://art/bird_%s.png" % id, 12)), "",
			[BL.text(id), "Где: " + BL.where(d), "Когда: %s, %s" % [String(BL.WHEN_RU.get(String(d["when"]), "")), String(BL.PERCH_RU.get(String(d["perch"]), ""))],
			"Перо в котле: " + _props(d.get("props", {})), "Перо стоит %d мон." % int(d["price"])])
		e["img2"] = _img("feather_" + id, load("res://art/icon_feather_%s.png" % id) if ResourceLoader.exists("res://art/icon_feather_%s.png" % id) else null)
		if bool(d.get("magic", false)):
			magic.append(e)
		elif bool(d.get("owl", false)):
			owls.append(e)
		else:
			day.append(e)
	return {"id": "birds", "title": "Птицы", "icon": _img("bird_robin", _frame("res://art/bird_robin.png", 12)),
		"intro": "Подойди тихонько с сачком (E) — можно поймать и отпустить, а перо остаётся. У каждой птицы свой голос.",
		"groups": [{"title": "Певчие и другие птицы", "entries": day}, {"title": "Совы и ночные", "entries": owls}, {"title": "Волшебные птицы", "entries": magic}]}


func _fish() -> Dictionary:
	var pond: Array = []
	var sea: Array = []
	for id in FDB.DATA:
		var d: Dictionary = FDB.DATA[id]
		var e: Dictionary = _e(id, String(d.get("name", id)), _img("fish_" + id, FDB.icon(id)), "",
			[String(d.get("desc", "")), "Цена: %d мон." % int(d.get("price", 0))], ["говорит!"] if bool(d.get("talk", false)) else [])
		if FDB.is_sea(id):
			sea.append(e)
		else:
			pond.append(e)
	return {"id": "fish", "title": "Рыбы", "icon": _img("fish_perch", FDB.icon("perch")),
		"intro": "Пруд у дома и море у пирса. Некоторые морские рыбы умеют разговаривать.",
		"groups": [{"title": "Пруд", "entries": pond}, {"title": "Море", "entries": sea}]}


func _insects() -> Dictionary:
	var ents: Array = []
	for id in INS.DATA:
		var d: Dictionary = INS.DATA[id]
		var at: AtlasTexture = AtlasTexture.new()
		at.atlas = load("res://art/insects.png")
		at.region = Rect2(0, int(d["row"]) * 16, 16, 16)
		ents.append(_e(id, String(d["name"]), _img("bug_" + id, at), "",
			[String(d.get("effect", "")), "Когда: " + String(d.get("when", "")), "Где: " + String(d.get("where", ""))]))
	return {"id": "insects", "title": "Насекомые", "icon": ents[0]["img"] if not ents.is_empty() else "",
		"intro": "Одни помогают огороду, другие вредят. Пойманных можно бросить в котёл.", "groups": [{"title": "Насекомые", "entries": ents}]}


func _monsters() -> Dictionary:
	var ents: Array = []
	var bosses: Array = []
	for id in V23.MONSTERS:
		var d: Dictionary = V23.MONSTERS[id]
		var home: String = String(d.get("home", ""))
		var e: Dictionary = _e(id, String(d["name"]), _img("mon_" + id, _frame("res://art/mon_%s.png" % id, 4)), String(HOME_RU.get(home, home)),
			["Проделка: " + String(TRICKS.get(String(d.get("shape", "")), "толкается.")),
			"Сила: %d   ·   Удар: %d   ·   Скорость: %d" % [int(d["hp"]), int(d["dmg"]), int(d["speed"])]])
		if home.begins_with("boss"):
			bosses.append(e)
		else:
			ents.append(e)
	return {"id": "monsters", "title": "Монстры", "icon": _img("mon_slime", _frame("res://art/mon_slime.png", 4)),
		"intro": "Живут в подземельях и в Аду. Битвы без крови: побеждённый монстр исчезает облачком звёздочек. Если совсем без сил — монстры утащат часть вещей в свой тайник, а найти его можно в сундуке подземелья.",
		"groups": [{"title": "Монстры подземелий", "entries": ents}, {"title": "Главные монстры", "entries": bosses}]}


func _people() -> Dictionary:
	var by_land: Dictionary = {}
	for tex in NPC.PEOPLE:
		var p: Array = NPC.PEOPLE[tex]
		var ld: String = NPC.land_of(String(tex))
		if not by_land.has(ld):
			by_land[ld] = []
		(by_land[ld] as Array).append(_e(String(tex), String(p[0]), _img("npc_" + String(tex), _frame("res://art/%s.png" % tex, 8, 8)), "",
			["«" + String(p[1]) + "»"]))
	var groups: Array = []
	for ld in NPC.LANDS:
		var l: Dictionary = NPC.LANDS[ld]
		var ents: Array = by_land.get(ld, [])
		groups.append({"title": String(l["name"]), "about": "%s %s — %s." % [String(l.get("about", "")), String(l.get("leader", "")), String(l.get("title", ""))], "entries": ents})
	return {"id": "people", "title": "Земли и жители", "icon": _img("npc_catgirl_choco", _frame("res://art/catgirl_choco.png", 8, 8)),
		"intro": "Земли далеко друг от друга, у каждой свой край и свои жители. Ад (Пеклоград) и Рай (Облакоград) — отдельные миры за вратами: не дружат, но и не воюют.",
		"groups": groups}


func _mats() -> Dictionary:
	var by_kind: Dictionary = {}
	for id in MT.ORDER:
		var m: Array = MT.MATS[id]
		var k: String = String(m[4])
		if not by_kind.has(k):
			by_kind[k] = []
		(by_kind[k] as Array).append(_e(id, String(m[0]), _img("mat_" + id, MT.icon(id)), "", [("Свойства: " + _props(m[5])) if not (m[5] as Dictionary).is_empty() else "", "Цена: %d мон." % int(m[2])]))
	var groups: Array = []
	for k in by_kind:
		groups.append({"title": _kind_ru(String(k)), "small": true, "entries": by_kind[k]})
	var rec: Array = []
	for st in MT.RECIPES:
		for r in (MT.RECIPES[st] as Array):
			var ins: Array = []
			for x in (r[2] as Dictionary):
				ins.append("%s ×%d" % [_nm(String(x)), int(r[2][x])])
			rec.append(_e("rec_" + String(r[0]) + str(rec.size()), "%s ×%d" % [_nm(String(r[0])), int(r[1])], _img("mat_" + String(r[0]), IT.icon(String(r[0]))),
				String(MT.STATIONS[st][0]), [" + ".join(ins)]))
	groups.append({"title": "Что делают в мастерских", "small": true, "entries": rec})
	# v26: магазины королевства — жители приходят и покупают сами
	var shop_ents: Array = []
	var S26 = preload("res://shops26.gd")
	for sk in S26.KINDS.keys():
		var sd: Array = S26.KINDS[sk]
		var kb: Array = IT.KBUILD[sk]
		var need_t: Array = []
		for x2 in (kb[6] as Dictionary):
			need_t.append("%s ×%d" % [_nm(String(x2)), int(kb[6][x2])])
		shop_ents.append(_e("shop26_" + String(sk), String(sd[0]), _img("shop26_" + String(sk), load("res://art/%s.png" % String(kb[1]))), "магазин королевства",
			["Строится на верстаке (вкладка с короной): " + ", ".join(need_t), "Жители сами приходят и платят в рабочие часы (8–21). Товар кладут из сумки или подвозят из сундуков базы; выручка копится в кассе."]))
	groups.append({"title": "Магазины королевства", "entries": shop_ents})
	return {"id": "mats", "title": "Материалы и мастерские", "icon": _img("mat_plank_tree_a", MT.icon("plank_tree_a")),
		"intro": "Дерево, камень, руды, ткани, шерсть, перья, краски и магическая пыль — из них строят и мастерят.", "groups": groups}


func _spells() -> Dictionary:
	var el_ents: Array = []
	for el in SP.ORDER:
		var d: Array = SP.EL[el]
		var opp: String = String(SP.OPPOSE.get(el, ""))
		el_ents.append(_e("el_" + String(el), String(d[0]), _img("orb_" + String(el), SP.icon(String(el))), "сфера",
			["Где взять: " + String(d[2]), ("Гасит: " + String((SP.EL[opp] as Array)[0])) if opp != "" else ""]))
	var by_n: Dictionary = {1: [], 2: [], 3: []}
	for k in SP.SPELLS:
		var s: Array = SP.SPELLS[k]
		var parts: PackedStringArray = String(k).split("+")
		var names: Array = []
		for pt in parts:
			names.append(String((SP.EL[pt] as Array)[0]))
		var e: Dictionary = _e("spell_" + String(s[0]), String(s[1]), _img("orb_" + String(parts[0]), SP.icon(String(parts[0]))), " + ".join(names),
			[String(s[2]), "Мана: %d" % int(s[3])])
		(by_n[parts.size()] as Array).append(e)
	return {"id": "spells", "title": "Книга сфер", "icon": _img("orb_arcane", SP.icon("arcane")),
		"intro": "Режим заклинаний — клавиша C. Клавиши 1-8 кладут сферы стихий в очередь (до трёх), R — произнести. Противоположные стихии гасят друг друга: огонь—холод, вода—молния, жизнь—тайна.",
		"groups": [{"title": "Стихии", "entries": el_ents}, {"title": "Заклинания из одной сферы", "entries": by_n[1]},
			{"title": "Из двух сфер", "entries": by_n[2]}, {"title": "Из трёх сфер", "entries": by_n[3]}]}


func _kind_ru(k: String) -> String:
	return String({"wood": "Дерево", "stone": "Камень", "earth": "Глина, песок и земля", "metal": "Руды и металлы", "gem": "Самоцветы",
		"fiber": "Волокна и нитки", "cloth": "Ткани", "animal": "Шерсть, пух и дары зверей", "sea": "Дары моря", "dye": "Краски",
		"glass": "Стекло", "paper": "Бумага, свечи и масла", "magic": "Магия", "feather": "Перья"}.get(k, k.capitalize()))


func _weapons() -> Dictionary:
	var by_type: Dictionary = {}
	for id in V23.WEAPON_ORDER:
		var d: Dictionary = V23.WEAPONS[id]
		var t: String = String(d.get("type", ""))
		if not by_type.has(t):
			by_type[t] = []
		var fx: String = String(d.get("fx", ""))
		(by_type[t] as Array).append(_e(id, String(d["name"]), _img("wpn_" + id, load("res://art/gear_%s.png" % id) if ResourceLoader.exists("res://art/gear_%s.png" % id) else IT.icon(String(id))), "",
			["Удар %d · %s · ступень %d" % [int(d["atk"]), "издалека" if bool(d.get("ranged", false)) else "вблизи", int(d.get("tier", 1))],
			("Особое: " + String(V23.WEAPON_FX.get(fx, fx))) if fx != "" else "", "Цена: %d мон." % int(d.get("price", 0))]))
	var groups: Array = []
	for t in by_type:
		groups.append({"title": _wtype_ru(String(t)), "small": true, "entries": by_type[t]})
	return {"id": "weapons", "title": "Оружие", "icon": _img("wpn_wpn_sword_wood", load("res://art/gear_wpn_sword_wood.png")),
		"intro": "Парадное и турнирное оружие — игра без крови. Им гоняют монстров в подземельях.", "groups": groups}


func _wtype_ru(t: String) -> String:
	return String({"sword": "Мечи", "axe": "Топоры", "spear": "Копья", "bow": "Луки", "staff": "Посохи", "wand": "Палочки", "dagger": "Кинжалы",
		"hammer": "Молоты", "mace": "Булавы", "crossbow": "Арбалеты", "shield": "Щиты", "scythe": "Косы", "whip": "Кнуты", "fan": "Веера",
		"katana": "Катаны", "club": "Дубинки", "slingshot": "Рогатки", "rapier": "Рапиры", "boomerang": "Бумеранги",
		"bubble": "Пузырьковые жезлы", "flail": "Цепы", "greatsword": "Двуручные мечи", "pillow": "Подушки", "squeaky": "Пищалки", "trident": "Трезубцы"}.get(t, t.capitalize()))


func _furniture() -> Dictionary:
	var by_cat: Dictionary = {}
	for id in V23.FURN:
		var d: Dictionary = V23.FURN[id]
		var c: String = String(d.get("cat", ""))
		if not by_cat.has(c):
			by_cat[c] = []
		var tp: String = "res://art/%s.png" % String(d["tex"])
		(by_cat[c] as Array).append(_e(id, String(d["name"]), _img("furn_" + id, load(tp) if ResourceLoader.exists(tp) else null), "",
			["Цена: %d мон." % int(d.get("price", 0))]))
	var groups: Array = []
	for c in by_cat:
		groups.append({"title": _fcat(String(c)), "small": true, "entries": by_cat[c]})
	return {"id": "furniture", "title": "Мебель и дом", "icon": _img("furn_straw_bed", load("res://art/fu_straw_bed.png")),
		"intro": "Мебель ставится в доме (клавиша B). Комнаты можно пристраивать.", "groups": groups}


func _fcat(c: String) -> String:
	return String({"bed": "Кровати", "table": "Столы", "chair": "Стулья и лавки", "wardrobe": "Шкафы", "bookcase": "Книжные полки",
		"lamp": "Свет", "rug": "Ковры", "dresser": "Комоды", "plant": "Цветы и растения", "cabinet": "Шкафчики", "misc": "Разное"}.get(c, c))


# ------------------------------------------------------------------ v27: деревья и луговые цветы (стиль яблока)

const TREES27: Array = [
	["tree_a", "Дуб", "Quercus robur", "Луга у дома, светлые рощи, земли рыцарей.", "Крепкая кора, широкая крона. Даёт брёвна, кору и листья для котла."],
	["tree_b", "Клён", "Acer platanoides", "Луга и светлые рощи.", "Светлая пышная крона. Брёвна, кора, листья."],
	["tree_c", "Липа", "Tilia cordata", "Сумрачные леса, луга, болота.", "Тёмная густая крона, в тени под ней прохладно."],
	["tree_d", "Вяз", "Ulmus glabra", "Луга, рощи, осенний лес.", "Самое высокое лиственное дерево мира."],
	["tree_apple", "Яблоня", "Malus domestica", "Двор травницы, деревня кошкодевочек.", "Даёт яблоки. Можно посадить саженец у дома."],
	["tree_autumn", "Осенний клён", "Acer (осень)", "Осенний лес, луга.", "Золотая листва круглый год."],
	["tree_autumn2", "Рыжий клён", "Acer rubrum", "Осенний лес.", "Огненно-рыжая крона."],
	["tree_blossom", "Сакура", "Prunus serrulata", "Цветущие рощи, земли Восходящего Солнца, луга.", "Розовые лепестки падают на траву."],
	["tree_unicorn", "Единорожье дерево", "Arbor unicornis", "Земли единорогов.", "Сказочная розово-сиреневая крона."],
	["tree_birch", "Берёза", "Betula pendula", "Берёзовые рощи, земли единорогов.", "Белая кора с чёрными полосками."],
]
const FLOWERS27: Array = [
	["flowers_pink", "Розовая гвоздичка", "Dianthus deltoides", "Луга, цветущие рощи, поля."],
	["flowers_white", "Нивяник (луговая ромашка)", "Leucanthemum vulgare", "Луга и поля у дома."],
	["flowers_blue", "Василёк луговой", "Centaurea jacea", "Луга, поля, берёзовые рощи."],
	["flowers_yellow", "Лютик едкий", "Ranunculus acris", "Луга и поля."],
]


func _nature27() -> Dictionary:
	var trees: Array = []
	for t in TREES27:
		var p: String = "res://art/%s.png" % String(t[0])
		if not ResourceLoader.exists(p):
			continue
		trees.append(_e(String(t[0]), String(t[1]), _img("nat_" + String(t[0]), load(p)), String(t[2]),
			[String(t[4]), "Где растёт: " + String(t[3]), "Ствол перерисован в стиле яблока: мягкий цветной контур, кора с волокнами, без дупла."]))
	var fl: Array = []
	for t in FLOWERS27:
		var p2: String = "res://art/%s.png" % String(t[0])
		if not ResourceLoader.exists(p2):
			continue
		fl.append(_e(String(t[0]), String(t[1]), _img("nat_" + String(t[0]), load(p2)), String(t[2]),
			["Украшение луга, собрать нельзя.", "Где растёт: " + String(t[3]),
			"Растёт прямо из земли: под кустиком тень-лунка и травинки в цвет травы своего края."]))
	return {"id": "nature27", "title": "Деревья и луговые цветы", "icon": trees[0]["img"] if not trees.is_empty() else "",
		"intro": "Деревья и цветы мира в стиле яблока. Травы, которые можно собрать, — в разделе «Травы» (маленькая картинка — как трава растёт в мире).",
		"groups": [{"title": "Деревья", "entries": trees}, {"title": "Луговые цветы", "entries": fl}]}

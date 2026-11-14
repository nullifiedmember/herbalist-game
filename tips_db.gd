extends RefCounted
## Советы жителей v17. Сотни подсказок: у каждой своя категория и «страница в книге».
##   herb — трава (запись на страничке этой травы), shroom — гриб, food — еда,
##   animal / place / life / craft — в раздел «Заметки».
## Житель знает лишь часть советов (у каждого своя четверть — по хэшу имени), любит свои темы
## и по возможности рассказывает то, чего героиня ещё не слышала.

const DB = preload("res://herbs_db.gd")
const W = preload("res://wild_db.gd")
const FD = preload("res://food_db.gd")
const RDB = preload("res://recipes_db.gd")
const HV = preload("res://harvest_db.gd")
const TD = preload("res://tree_db.gd")

static var _cache: Array = []
static var _by_id: Dictionary = {}

const SECTION: Dictionary = {
	"herb": "Травы", "shroom": "Грибы", "food": "Еда", "animal": "Заметки", "place": "Заметки", "life": "Заметки", "craft": "Заметки",
}
const CAT_NAME: Dictionary = {
	"animal": "Звери", "place": "Места", "life": "Жизнь", "craft": "Ремесло", "herb": "Травы", "shroom": "Грибы", "food": "Еда",
}

# ------------------------------------------------------------------ написанное вручную
# [категория, цель (id страницы или ""), текст]
const HAND: Array = [
	# ---- грибы
	["shroom", "chanterelle", "Лисички растут по утрам — после полудня их уже не найдёшь."],
	["shroom", "chanterelle", "Рыжие, как лисий хвост. Ищи под хвойными и берёзами, пока роса не высохла."],
	["shroom", "glow_cap", "Светящиеся шляпки ищи ночью в гротах. Днём они прячутся."],
	["shroom", "glow_cap", "В паутинной чаще ночью грибы светятся — хоть без фонаря ходи."],
	["shroom", "moon_shroom", "Лунный гриб — редкость. Только глубокой ночью, у единорогов или магов."],
	["shroom", "moon_shroom", "Говорят, лунный гриб слышит тихие песни. Спой ему — и он покажется."],
	["shroom", "fly_agaric", "Не ешь мухоморы. Просто поверь. Зато в котёл они годятся."],
	["shroom", "fly_agaric", "Красная шляпка в белую крапинку — красиво, но ядовито."],
	["shroom", "morel", "Сморчки — ранним утром на лугах. Кто рано встаёт, тому грибы."],
	["shroom", "blood_russula", "Кровавую сыроежку ищи вечером в Сумеречье."],
	["shroom", "porcini", "Белый гриб — король леса. Ищи его в осенних и берёзовых рощах."],
	["shroom", "birch_bolete", "Подберёзовики прячутся только под берёзами. Больше нигде их нет."],
	["shroom", "swamp_honey", "Болотные опята растут пучками. Один нашла — рядом ищи ещё."],
	["shroom", "elf_star", "Эльфийские звёздочки растут лишь у эльфов. Не рви их без нужды."],
	["shroom", "web_shroom", "Паутинник любит чащу. Там тихо, сыро и пауки не кусаются."],
	["shroom", "field_champignon", "Шампиньоны растут на полях и лугах. Они почти всегда рядом с жильём."],
	["shroom", "porcini", "Нож грибника — вещь! Гриб срежешь, а грибница останется, и рядом вырастет второй."],
	["shroom", "chanterelle", "В корзине для грибов лисички весят как пёрышки."],
	# ---- травы
	["herb", "mint", "Мята любит воду. Сажай её у колодца — разрастётся на всю грядку."],
	["herb", "lavender", "Лавандовый мешочек под подушкой прогоняет кошмары. Проверено!"],
	["herb", "nettle", "Крапиву рви в перчатках, не то будешь чесаться до вечера."],
	["herb", "poppy", "Мак тряхнёшь — и засыпаешь на ходу. Берегись пыльцы!"],
	["herb", "moonbloom", "Лунные цветы раскрываются ночью. Днём их и не найти."],
	["herb", "mandrake", "Мандрагору дёрнешь — закричит. Лучше надень что-нибудь на уши."],
	["herb", "glowmoss", "Светящийся мох найдёшь в гротах. Он согреет зельем и осветит путь."],
	["herb", "catnip", "Кошачья мята — любимая трава кошкодевочек. Угости — подружишься."],
	["herb", "fire_pepper", "Огненный перец жжётся даже в котле. Клади по одному."],
	["herb", "sage", "Шалфей — для горла. Заваривай горячей водой, и кашель пройдёт."],
	["herb", "chamomile", "Ромашковый чай — первое, что варит любая травница."],
	["herb", "valerian", "Корень валерианы любят все кошки. Береги корзинку!"],
	["herb", "dandelion", "У одуванчика корень длиннющий. Тянуть надо медленно."],
	["herb", "sundew", "Росянка ловит мошек. Осторожнее, она липкая."],
	["herb", "star_bell", "Звёздные колокольчики звенят на ветру. Услышишь — иди на звук."],
	["herb", "ginseng", "Женьшень растёт медленно, зато стоит дорого."],
	["herb", "plantain", "Подорожник к ссадине — старый добрый способ."],
	["herb", "thyme", "Тимьян стелется по земле. Ищи под ногами."],
	# ---- звери
	["animal", "", "Сапфировый заяц пугливый. Подходи медленно, не беги!"],
	["animal", "", "Ежи любят, когда их не трогают. Но если очень хочется — осторожно."],
	["animal", "", "Кабаны хрюкают, когда довольны. Сплющенный кабан хрюкает всегда."],
	["animal", "", "Единороги живут в розовом лесу. Говорят, они любят тихие песни."],
	["animal", "", "Если увидишь золотого оленя — загадай желание."],
	["animal", "", "Лисы днём спят, а ночью бегают. Угольная лиса — вообще никогда не показывается при свете."],
	["animal", "", "Утки в пруду не боятся людей, но от собак убегают."],
	["animal", "", "Белки прячут орехи в дуплах. Заглянешь — и найдёшь запасы."],
	["animal", "", "Пчёл не трогай, пока не накрыла сачком: пчела с цветка — урожай на грядке."],
	["animal", "", "Божья коровка ест тлю. Поймаешь её — грядки заскучают."],
	["animal", "", "Комары кусаются у пруда вечером. Стрекозы днём их ловят."],
	["animal", "", "Светлячки светят ночью на лугу. Рядом с ними стыд проходит быстрее."],
	["animal", "", "Бабочек много на цветущем лугу днём. Не шуми — спугнёшь."],
	["animal", "", "Кузнечики объедают дикие травы. Поймаешь — меньше потерь."],
	# ---- места
	["place", "", "Деревня кошкодевочек к югу от домика. Там пахнет рыбкой и молоком."],
	["place", "", "На западе — паутинная чаща. Пауки там добрые, честно-честно!"],
	["place", "", "За паутинной чащей на север — Сумеречье. Замок графини и кладбище."],
	["place", "", "На восток от деревни кошек — Кронхольм. Рыцари устраивают турниры."],
	["place", "", "В лесу эльфов великое древо. Говорят, раз в сто лет с него падает лист."],
	["place", "", "Долина магов далеко на северо-востоке. Остерегайся сундуков: некоторые кусаются."],
	["place", "", "У дворфов лучшая таверна на свете. Эль там по рецепту прабабушки."],
	["place", "", "Хламбург построен из хлама. Продают там шипучку из банок и жуков в карамели."],
	["place", "", "С пирса у моря можно спуститься в колоколе к русалкам."],
	["place", "", "Русалки говорят: в хвосте можно плавать по всему морю. Эликсир русалочьего хвоста редкий: морская трава, эльфийский лист и кристальный корень на лунной росе."],
	["place", "", "На дне моря растут шестнадцать трав. Самые редкие прячутся на глубине, а в жемчужницах бывает жемчуг."],
	["place", "", "Нажми G — цели и календарь событий. Каждый седьмой день на площади базар."],
	["place", "", "Сакураяма — на востоке. Там цветёт сакура и водятся лисички-кицунэ."],
	["place", "", "В гротах живут угольные лисы, а ещё там растёт светящийся мох."],
	["place", "", "Болото — место для терпеливых. Там растут редкие травы и болотные опята."],
	["place", "", "На дорогах не заблудишься: они сами выведут к городу."],
	["place", "", "Нажми M — увидишь карту. Туман рассеивается там, где ты уже побывала."],
	# ---- жизнь
	["life", "", "Если устала — присядь у костра. Жизнь не убежит."],
	["life", "", "Пей воду чаще, в дороге жажда незаметно подкрадывается."],
	["life", "", "В чужой дом без приглашения не ходи — стража не любит."],
	["life", "", "Спи вовремя: усталость копится, и в конце концов упадёшь без сил."],
	["life", "", "Бег — это быстро, но утомляет вдвое сильнее."],
	["life", "", "Репутация среди жителей зависит от доброты: болтай, помогай, не надоедай одним и тем же."],
	["life", "", "Не спрашивай одно и то же много раз — рассердишь собеседницу."],
	["life", "", "Погладь кошкодевочку — она замурчит. Только не переусердствуй."],
	["life", "", "Топор можно использовать и для брёвен, и для саженцев. Посадишь рядом — вырастет новое дерево."],
	["life", "", "Дерево вокруг твоего дома — дрова на зиму и листья для зелий."],
	["life", "", "У хорошего рюкзака много карманов. Купи побольше — влезет больше трав."],
	["life", "", "Перчатки нужны не только от крапивы. Некоторые травы жгутся ещё сильнее."],
	["life", "", "Ночью без фонаря в лесу трудно. Возьми факел — клавиша T."],
	["life", "", "Когда нечего делать — сходи на рыбалку. Рыба клюёт в разное время."],
	# ---- ремесло
	["craft", "", "Вода холодная, тёплая и горячая в котле даёт разные зелья. Гляди, что хочешь получить."],
	["craft", "", "Траву можно растереть, нарезать, высушить, обжечь или замочить — и она станет другой."],
	["craft", "", "Мёд, воск и спирт — не только для еды. Они основы для сиропов, мазей и настоек."],
	["craft", "", "Листья дерева и пойманные насекомые тоже идут в котёл. Бросай — получатся странные зелья."],
	["craft", "", "Чем больше ингредиентов в котле, тем сильнее зелье. Но смотри, чтобы они дружили."],
	["craft", "", "Огненные травы нельзя хватать голой рукой. Нужны перчатки из шкуры саламандры."],
	["craft", "", "Рецепт можно найти в книге зелий — тот, что на столе зельевара."],
	["craft", "", "Еду готовят на костре во дворе: разожги его бревном и нажми E, а нужные продукты пусть лежат в сумке."],
	["craft", "", "Из яблока и мёда выйдет яблочный пирог. Брось на костёр и нажми E."],
	["craft", "", "Тыквенный суп — любимое лакомство осенью. Тыква, бутылочка воды и костёр."],
]

# ------------------------------------------------------------------ собираем всё вместе


static func all() -> Array:
	if not _cache.is_empty():
		return _cache
	var out: Array = []
	var n: int = 0
	for h in HAND:
		out.append({"id": "h%d" % n, "cat": String(h[0]), "target": String(h[1]), "text": String(h[2])})
		n += 1
	# ---- по каждой траве
	for hid in DB.ORDER:
		var d: Dictionary = DB.DATA[hid]
		var sn: String = String(d.get("short", d["name"]))
		var props: Array = []
		for p in d["props"]:
			props.append(String(p[0]).to_lower())
		out.append({"id": "hw_" + hid, "cat": "herb", "target": hid, "text": "«%s» растёт тут: %s." % [sn, String(d["where"]).to_lower()]})
		out.append({"id": "hp_" + hid, "cat": "herb", "target": hid, "text": "В котле «%s» даёт: %s." % [sn, ", ".join(props)]})
		out.append({"id": "hm_" + hid, "cat": "herb", "target": hid, "text": "За «%s» торговки дают около %d монет." % [sn, int(d.get("price", 3))]})
		if d.has("hours"):
			var hr: Array = d["hours"]
			out.append({"id": "hh_" + hid, "cat": "herb", "target": hid, "text": "«%s» показывается только в свои часы: с %d до %d." % [sn, int(hr[0]), int(hr[1])]})
		var q: Dictionary = HV.q(hid)
		if String(q.get("text", "")) != "":
			out.append({"id": "hq_" + hid, "cat": "herb", "target": hid, "text": "Про «%s» знаю вот что: %s" % [sn, String(q["text"])]})
		if String(d.get("desc", "")) != "":
			out.append({"id": "hd_" + hid, "cat": "herb", "target": hid, "text": String(d["desc"])})
	# ---- по каждому грибу
	for sid in W.SHROOMS.keys():
		var sd: Dictionary = W.SHROOMS[sid]
		var nm: String = String(sd["name"])
		out.append({"id": "sw_" + sid, "cat": "shroom", "target": sid, "text": "«%s»: %s." % [nm, String(sd["need"])]})
		out.append({"id": "sp_" + sid, "cat": "shroom", "target": sid, "text": "«%s» торговки берут за %d монет." % [nm, int(sd["price"])]})
		var pr: Dictionary = RDB.SHROOM_PROPS.get(sid, {})
		if not pr.is_empty():
			var pl: Array = []
			for k in pr.keys():
				pl.append(String(k).to_lower())
			out.append({"id": "sk_" + sid, "cat": "shroom", "target": sid, "text": "В котле «%s» даёт: %s." % [nm, ", ".join(pl)]})
		if float(sd["food"]) > 0.0:
			out.append({"id": "se_" + sid, "cat": "shroom", "target": sid, "text": "«%s» можно есть: сытость около %d%%." % [nm, int(float(sd["food"]) * 100.0)]})
		else:
			out.append({"id": "se_" + sid, "cat": "shroom", "target": sid, "text": "«%s» есть нельзя, он вредный. Лучше в котёл." % nm})
	# ---- по каждой еде
	for fk in FD.ORDER:
		var fd: Array = FD.DATA[fk]
		out.append({"id": "fs_" + fk, "cat": "food", "target": "food_" + fk, "text": "«%s»: %s." % [String(fd[0]), String(fd[5])]})
		out.append({"id": "fd_" + fk, "cat": "food", "target": "food_" + fk, "text": String(fd[6])})
		out.append({"id": "fp_" + fk, "cat": "food", "target": "food_" + fk, "text": "«%s» стоит около %d монет и даёт %d%% сытости." % [String(fd[0]), int(fd[4]), int(float(fd[2]) * 100.0)]})
	# ---- рецепты кухни
	var ri: int = 0
	for r in FD.RECIPES:
		var names: Array = []
		for nd in (r[0] as Array):
			names.append(_ing_name(String(nd)))
		out.append({"id": "fr%d" % ri, "cat": "food", "target": "food_" + String(r[1]), "text": "Чтобы приготовить «%s», возьми: %s. Готовят на костре: подкинь бревно, чтобы горел, и нажми E рядом." % [FD.name("food_" + String(r[1])), ", ".join(names)]})
		ri += 1
	# ---- деревья: листья и плоды
	for tex in TD.TREES.keys():
		var tr: Array = TD.TREES[tex]
		var tn: String = TD.tree_name(tex)
		var fruit: String = ""
		if not (tr[2] as Array).is_empty():
			fruit = "food_" + String(((tr[2] as Array)[0] as Array)[0])
		var txt: String = "С дерева (%s) можно сорвать листья. Подойди и нажми E." % tn
		if fruit != "":
			txt = "На дереве (%s) растут плоды: «%s». Подойди, нажми E и сорви." % [tn, FD.name(fruit)]
		out.append({"id": "tr_" + tex, "cat": "food" if fruit != "" else "craft", "target": fruit, "text": txt})
		out.append({"id": "tl_" + tex, "cat": "craft", "target": "", "text": "%s пойдёт в котёл: %s." % [TD.leaf_name(TD.leaf_id(tex)), ", ".join(_prop_names(tr[1]))]})
	_cache = out
	for t in out:
		_by_id[String(t["id"])] = t
	return out


static func _prop_names(d: Dictionary) -> Array:
	var a: Array = []
	for k in d.keys():
		a.append(String(k).to_lower())
	return a


static func _ing_name(n: String) -> String:
	if FD.DATA.has(n):
		return FD.name("food_" + n)
	if n.begins_with("bug_"):
		var INS = preload("res://insects_db.gd")
		return String(INS.title(n.substr(4))).to_lower()
	if W.is_shroom(n):
		return W.shroom_name(n).to_lower()
	if n == "honey":
		return "мёд"
	if n == "water_cold":
		return "бутылочку холодной воды"
	if DB.DATA.has(n):
		return DB.short(n).to_lower()
	return n


# ------------------------------------------------------------------ выбор совета для жителя

const LAND_PREFIX: Dictionary = {
	"cats": ["Мяу! ", "Мррр... ", "Послушай, ня: "],
	"spider": ["Ш-ш-ш... ", "Тихонько скажу: "],
	"gothic": ["Тсс... ", "Между нами: "],
	"knights": ["Скажу как есть: ", "Честно говоря, "],
	"elves": ["Лес шепчет: ", "Слушай внимательно: "],
	"mages": ["Любопытный факт: ", "Я читала, что "],
	"orcs": ["Слушай сюда: ", "ГРА! Запомни: "],
	"goblins": ["Хе-хе! ", "Псст, дылда! "],
	"dwarves": ["Хо-хо! ", "Знай, малявка: "],
	"japan": ["Фыр-фыр. ", "Лисы знают: "],
	"sea": ["Буль! ", "Плюх-плюх, слушай: "],
}


## Какие категории любит эта жительница (по занятию и по имени)
static func favourites(tex: String, job: String, role: String) -> Array:
	var fav: Array = []
	match job:
		"bake", "dessert", "cook", "ale", "farm":
			fav = ["food", "food", "herb"]
		"brew", "garden", "read", "spell":
			fav = ["herb", "herb", "shroom", "craft"]
		"smith", "smith2", "sharpen", "mine", "dig", "tinker":
			fav = ["craft", "life", "place"]
		"archer", "chop", "train":
			fav = ["animal", "life", "place"]
	if tex.begins_with("hermit") or tex.begins_with("outcast") or tex.begins_with("hunter"):
		fav.append_array(["shroom", "shroom", "animal"])
	if tex.begins_with("fishgirl"):
		fav.append_array(["food", "place", "animal"])
	if tex.begins_with("elf"):
		fav.append_array(["herb", "shroom", "animal"])
	if tex.begins_with("mage") or tex == "archmage":
		fav.append_array(["herb", "craft"])
	if tex.begins_with("catgirl"):
		fav.append_array(["food", "animal"])
	if tex.begins_with("dwarf"):
		fav.append_array(["food", "shroom"])
	if role == "торговец":
		fav.append_array(["food", "herb"])
	if role == "лидер" or role == "заместитель":
		fav.append_array(["place", "life"])
	# личные пристрастия по хэшу имени
	var cats: Array = ["herb", "shroom", "food", "animal", "place", "life", "craft"]
	fav.append(cats[abs(hash(tex)) % cats.size()])
	fav.append(cats[abs(hash(tex + "x")) % cats.size()])
	return fav


## Знает ли эта жительница данный совет (у каждой — своя четверть)
static func knows(tex: String, tid: String) -> bool:
	return abs(hash(tex + "|" + tid)) % 100 < 27


## Выбрать совет для жительницы. avoid — недавно сказанные ею id. Возвращает {} если выбрать нечего.
static func pick_for(tex: String, job: String, role: String, land: String, avoid: Array = []) -> Dictionary:
	var all_t: Array = all()
	var fav: Array = favourites(tex, job, role)
	var cands: Array = []
	var weights: Array = []
	var tot: float = 0.0
	for t in all_t:
		var tid: String = String(t["id"])
		if avoid.has(tid) or not knows(tex, tid):
			continue
		var w: float = 1.0
		if fav.has(String(t["cat"])):
			w += 1.5 * float(fav.count(String(t["cat"])))
		if not Game.tips_heard.has(tid):
			w *= 6.0
		cands.append(t)
		weights.append(w)
		tot += w
	if cands.is_empty():
		return {}
	var x: float = randf() * tot
	for i in range(cands.size()):
		x -= float(weights[i])
		if x <= 0.0:
			return _flavor(cands[i], land)
	return _flavor(cands[cands.size() - 1], land)


static func _flavor(t: Dictionary, land: String) -> Dictionary:
	var c: Dictionary = t.duplicate()
	if LAND_PREFIX.has(land) and randf() < 0.35:
		var pre: String = String((LAND_PREFIX[land] as Array).pick_random())
		var tx: String = String(c["text"])
		# после префикса фраза начинается с маленькой буквы, если префикс не заканчивается на знак
		if pre.ends_with(": ") or pre.ends_with(", "):
			tx = tx.substr(0, 1).to_lower() + tx.substr(1)
		c["text"] = pre + tx
	return c


static func get_tip(tid: String) -> Dictionary:
	all()
	return _by_id.get(tid, {})


static func count() -> int:
	return all().size()

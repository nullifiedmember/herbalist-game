extends RefCounted
## Разговорные пункты v18: услуги клиентам, задания, письма, воровство и тюремщица.
## Подключается из dialog_ui.gd (_talk_menu → extra_options, _choose → handles/handle).

const DB = preload("res://herbs_db.gd")
const RDB = preload("res://recipes_db.gd")
const IT = preload("res://items_db.gd")

## Услуги, которые можно предложить жителям: id -> название
const SERVICES: Dictionary = {
	"herbs3": "Травяной сбор на заказ (3 травы)",
	"potion": "Лечебное зелье с собой",
	"bouquet": "Букет полевых цветов (3 цветка)",
	"water": "Принести чистой воды (бутылка)",
	"work": "Помочь по хозяйству (2 часа)",
	"fortune": "Погадать на травах (1 трава)",
	"story": "Рассказать сказку или спеть",
	"stone": "Камни для сада (1 средний или 3 маленьких)",
}
const SERVICE_ORDER: Array = ["herbs3", "potion", "bouquet", "water", "work", "fortune", "story", "stone"]
const FLOWERS: Array = ["lavender", "chamomile", "cornflower", "calendula", "dandelion", "clover", "pink_clover", "yarrow", "plantain", "strawberry"]
const FORTUNES: Array = [
	"Вижу тёплый ужин и добрую весть. А ещё — потерянная вещь найдётся под кроватью.",
	"Трава говорит: скоро встретишь друга. Или кота. Скорее кота.",
	"Лист лёг острием вниз — не принимай сегодня скоропалительных решений.",
	"Тебя ждёт дорога. Возьми тёплый плащ и бутылку воды.",
	"Ромашка не врёт: тебе будут рады там, где ты давно не была.",
	"Две веточки сошлись — значит, помиритесь. И пирог будет вкусным.",
	"Вижу монетки. Много. Правда, придётся немного поработать.",
	"Мята шепчет: пей больше воды и не бойся ночного леса.",
	"К весне будет перемена. К хорошему. Но это не точно.",
	"Дым ушёл вправо — не ходи сегодня на болото без сапог.",
]
const WANT_TEXT: Dictionary = {"herbs3": "травяной сбор", "potion": "лечебное зелье", "bouquet": "букет цветов", "water": "чистая вода", "work": "помощь по хозяйству", "fortune": "гадание", "story": "сказка", "stone": "камни для сада"}

static var done: Dictionary = {}       # "имя:день" -> сколько услуг сегодня оказано

static var stay_price: int = 0         # сколько хозяйка просит за ночлег

const ACTS: Array = ["st_ask", "st_pay", "st_no", "sh_menu", "sv_menu", "sv_back", "sv_exit", "sv_ask", "sv_steal", "qv_ask", "qv_accept", "qv_no", "qv_letter", "pj_info", "pj_wait", "pj_bail", "pj_plead", "pj_who", "pj_back"]


static func handles(act: String) -> bool:
	return act in ACTS or act.begins_with("sv:") or act.begins_with("sh:")


static func _qn(d: Node) -> Node:
	return d.get_tree().get_first_node_in_group("quests18")


static func _law(d: Node) -> Node:
	return d.get_tree().get_first_node_in_group("law18")


static func _key(npc: Node) -> String:
	return "%s:%d" % [String(npc.get("npc_name")), Game.day]


## Что житель хочет сегодня: три услуги (от имени и дня)
static func wants(npc: Node) -> Array:
	var r: RandomNumberGenerator = RandomNumberGenerator.new()
	r.seed = hash(String(npc.get("npc_name"))) * 17 + Game.day * 131 + 5
	var pool: Array = SERVICE_ORDER.duplicate()
	var out: Array = []
	for i in range(3):
		var k: int = r.randi_range(0, pool.size() - 1)
		out.append(pool[k])
		pool.remove_at(k)
	return out


## Дополнительные пункты разговора. opts — обычное меню; возвращает меню целиком.
static func extra_options(d: Node, opts: Array) -> Array:
	var npc: Node = d.get("npc")
	if npc == null:
		return opts
	var lw: Node = _law(d)
	if npc.has_meta("shelter"):
		opts.insert(0, ["Хочу взять питомца", "sh_menu"])
		return opts
	if npc.has_meta("jailer"):
		if lw != null and bool(lw.get("jailed")):
			return [["Когда меня выпустят?", "pj_info"], ["Отсидеть срок до конца", "pj_wait"], ["Заплатить залог", "pj_bail"], ["Попросить о снисхождении", "pj_plead"], ["Молчать", "bye"]]
		opts.insert(0, ["Кто сидит в камерах?", "pj_who"])
		return opts
	# ночёвка: в гостях у хозяйки личного дома можно попроситься переночевать
	var mn: Node = d.get_tree().current_scene
	if mn != null and mn.get("visiting") != null and npc == mn.get("room_owner") and String((mn.get("visiting") as Node).get("kind")) == "home":
		var tail0: Array = opts.pop_back() if not opts.is_empty() else ["Пока!", "bye"]
		opts.append(["Можно у вас переночевать?", "st_ask"])
		opts.append(tail0)
		return opts
	var land: String = String(npc.get("land"))
	var role: String = String(npc.get("role"))
	if land == "" or String(npc.get("npc_name")) == "":
		return opts
	var qn: Node = _qn(d)
	var extra: Array = []
	if role != "стража":
		extra.append(["Предложить услугу", "sv_menu"])
	if qn != null:
		var mine: Dictionary = qn.call("active_from", String(npc.get("npc_name")))
		if not mine.is_empty():
			extra.append(["Сдать задание" if bool(qn.call("can_turn_in", mine)) else "Про твоё поручение", "qv_ask"])
		elif not (qn.call("offer_for", npc) as Dictionary).is_empty():
			extra.append(["Нет ли для меня дела?", "qv_ask"])
		if bool(qn.call("letter_for", npc)):
			extra.append(["Передать письмо", "qv_letter"])
	if role in ["житель", "торговец", "кузнец"]:
		extra.append(["Стащить кошелёк (воровство)", "sv_steal"])
	# перед «Пока!» (последний пункт)
	var tail: Array = opts.pop_back() if not opts.is_empty() else ["Пока!", "bye"]
	opts.append_array(extra)
	opts.append(tail)
	return opts


static func handle(d: Node, act: String) -> void:
	var npc: Node = d.get("npc")
	match act:
		"sv_menu", "sv_back":
			_service_menu(d)
		"sv_exit":
			d.call("_talk_menu")
		"sh_menu":
			_shelter_menu(d)
		"st_ask":
			_stay_ask(d)
		"st_no":
			d.call("_say", "Как хочешь. Если передумаешь — скажи.")
			d.call("_talk_menu")
		"st_pay":
			if Game.coins < stay_price:
				d.call("_say", "Тут не хватает монет: нужно %d, а у тебя %d." % [stay_price, Game.coins])
				d.call("_talk_menu")
			else:
				Game.add_coins(-stay_price)
				d.call("close")
				d.get_tree().current_scene.call("guest_sleep")
		"sv_ask":
			var w: Array = wants(npc)
			var names: Array = []
			for k in w:
				names.append(String(WANT_TEXT[k]))
			d.call("_say", "Сегодня мне пригодились бы: %s. Остальное — не обижайся — не нужно." % ", ".join(names))
			_service_menu(d)
		"sv_steal":
			_steal(d)
		"qv_ask":
			_quest_ask(d)
		"qv_accept":
			var qn: Node = _qn(d)
			var q: Dictionary = qn.call("offer_for", npc)
			if not q.is_empty():
				qn.call("accept", q)
				var extra: String = ""
				if String(q["type"]) == "letter":
					extra = " Письмо у тебя в сумке."
				d.call("_say", "Спасибо! Награда: %s.%s" % [String(qn.call("reward_text", q)), extra])
			d.call("_talk_menu")
		"qv_no":
			d.call("_say", "Хорошо, ничего страшного. Заходи ещё.")
			d.call("_talk_menu")
		"qv_letter":
			var qn2: Node = _qn(d)
			var q2: Dictionary = qn2.call("deliver_to", npc)
			if q2.is_empty():
				d.call("_say", "Мне? Нет, это не мне.")
			else:
				d.call("_say", "Письмо от %s! Спасибо, что передала. Я так ждала!" % String(q2["giver"]))
				Game.rep_add(String(q2["land"]), 1, true)
				Game.toast.emit("Письмо передано. Вернись за наградой.", load("res://art/icon_letter.png"))
			d.call("_talk_menu")
		"pj_who":
			d.call("_say", "Редко кто. Тех, кто нарушил закон, держат здесь. Спроси лучше у жителей, как не попадать сюда.")
			d.call("_talk_menu")
		"pj_info", "pj_back":
			var lw: Node = _law(d)
			d.call("_say", "Тебе сидеть ещё %d ч. Залог — %d монет. Или уговори меня, если тебя здесь уважают." % [int(ceil(float(lw.get("sentence_h")))), int(lw.call("bail_cost"))])
			d.call("_talk_menu")
		"pj_wait":
			d.call("close")
			_law(d).call("serve")
		"pj_bail":
			var lw2: Node = _law(d)
			var cost: int = int(lw2.call("bail_cost"))
			if Game.coins < cost:
				d.call("_say", "Залог — %d монет, а у тебя только %d." % [cost, Game.coins])
				d.call("_talk_menu")
			else:
				d.call("close")
				lw2.call("pay_bail")
		"pj_plead":
			var lw3: Node = _law(d)
			if bool(lw3.get("pleaded")):
				d.call("_say", "Я уже ответила. Больше не проси.")
				d.call("_talk_menu")
			else:
				d.call("close")
				var ok: bool = bool(lw3.call("plead"))
				if not ok:
					var hud: Node = d.get_tree().get_first_node_in_group("hud")
					if hud != null:
						hud.call("say", String(lw3.call("prison", lw3.get("jail_land"))["jailer"]), "Нет. Срок продлён на час — за настойчивость.")
		_:
			if act.begins_with("sv:"):
				_do_service(d, act.substr(3))
			elif act.begins_with("sh:"):
				var shn: Node = d.get_tree().get_first_node_in_group("shelters18")
				var kind: String = act.substr(3)
				var land: String = String(npc.get("land"))
				if shn != null and bool(shn.call("adopt", land, kind)):
					d.call("_say", "Береги %s! Если увидит загон у твоего дома — поселится там. А кошки всегда будут рядом." % String(preload("res://shelter.gd").title(kind)))
					npc.call("react", "happy", 2.5)
					d.call("_talk_menu")
				else:
					d.call("_say", "Не хватает монет. Приходи, когда накопишь.")
					_shelter_menu(d)


## Попросилась переночевать: хозяйка (от имени и дня) откажет, пустит бесплатно или попросит монеты
static func _stay_ask(d: Node) -> void:
	var door: Node = d.get_tree().current_scene.get("visiting")
	var r: RandomNumberGenerator = RandomNumberGenerator.new()
	r.seed = hash(String(door.get("owner_name"))) * 7 + Game.day * 31 + 11
	var roll: float = r.randf()
	if roll < 0.25:
		d.call("_say", "Ой, сегодня никак: у меня тесно и постелить негде. Загляни в другой раз.")
		d.call("_talk_menu")
	elif roll < 0.6:
		d.call("_say", "Конечно, оставайся! Постелю у печки. Денег не надо — гостям рады.")
		d.call("close")
		d.get_tree().current_scene.call("guest_sleep")
	else:
		stay_price = 5 + r.randi_range(0, 10)
		d.call("_say", "Переночевать можно, но за %d монет — дрова, постель, завтрак. Идёт?" % stay_price)
		d.set("mode", "talk")
		d.call("_set_options", [["Заплатить %d монет" % stay_price, "st_pay"], ["Не надо", "st_no"]])


static func _service_menu(d: Node) -> void:
	var npc: Node = d.get("npc")
	var opts: Array = []
	var left: int = 3 - int(done.get(_key(npc), 0))
	for id in SERVICE_ORDER:
		opts.append([String(SERVICES[id]), "sv:" + String(id)])
	opts.append(["Что вам сегодня нужно?", "sv_ask"])
	opts.append(["Назад", "sv_exit"])
	d.set("mode", "talk")
	if left <= 0:
		d.call("_say", "Спасибо, на сегодня услуг хватит.")
	else:
		d.call("_say", "Чем можешь помочь? Выбирай — я посмотрю, что мне нужно.")
	d.call("_set_options", opts)


static func _pay_factor(npc: Node, wanted: bool) -> float:
	var f: float = 1.0 + 0.04 * float(Game.rep_tier(String(npc.get("land"))))
	return f * (1.5 if wanted else 1.0)


static func _do_service(d: Node, id: String) -> void:
	var npc: Node = d.get("npc")
	var land: String = String(npc.get("land"))
	var wanted: bool = id in wants(npc)
	if int(done.get(_key(npc), 0)) >= 3:
		d.call("_say", "Спасибо, на сегодня услуг хватит.")
		_service_menu(d)
		return
	if not wanted:
		d.call("_say", "Мило, но мне сегодня это не нужно. Спроси, что нужно, — подскажу.")
		npc.call("react", "shy", 1.2)
		_service_menu(d)
		return
	var f: float = _pay_factor(npc, wanted)
	var pay: int = 0
	var msg: String = ""
	match id:
		"herbs3":
			var picked: Array = _take_herbs(3, false)
			if picked.is_empty():
				d.call("_say", "У тебя нет трёх трав. Набери и приходи.")
				_service_menu(d)
				return
			var sum: int = 0
			for h in picked:
				sum += DB.price(String(h))
			pay = int((sum * 1.3 + 3.0) * f)
			msg = "Какой душистый сбор! Держи %d монет." % pay
		"potion":
			var pid: String = ""
			for k in Game.inventory.keys():
				if int(Game.inventory[k]) > 0 and RDB.is_product(String(k)) and String(k) != "murky":
					pid = String(k)
					break
			if pid == "":
				d.call("_say", "Зелья у тебя нет. Свари что-нибудь и приходи.")
				_service_menu(d)
				return
			Game.take_item(pid)
			pay = int((float(RDB.price(pid)) * 1.2 + 4.0) * f)
			msg = "Как раз то, что нужно! Спасибо. Вот %d монет." % pay
		"bouquet":
			var fl: Array = _take_from(FLOWERS, 3)
			if fl.is_empty():
				d.call("_say", "Для букета нужны три цветка: лаванда, ромашка, василёк... Принеси.")
				_service_menu(d)
				return
			pay = int(16.0 * f)
			msg = "Какой красивый букет! Спасибо. %d монет." % pay
		"water":
			if Game.get_count("water_cold") < 1:
				d.call("_say", "Нужна бутылка холодной воды — набери у колодца.")
				_service_menu(d)
				return
			Game.take_item("water_cold")
			Game.add_item("bottle")
			pay = int(6.0 * f)
			msg = "Водичка! Выручила. %d монет." % pay
		"work":
			if Game.tired() or Game.hour() > 20.0:
				d.call("_say", "Ты устала, да и поздно. Приходи в другой раз.")
				_service_menu(d)
				return
			d.call("close")
			Game.minutes += 120.0
			Game.fatigue = minf(1.0, Game.fatigue + 0.12)
			Game.hunger = minf(1.0, Game.hunger + 0.04)
			pay = int(randf_range(9.0, 15.0) * f)
			Game.add_coins(pay)
			_finish(d, npc, land, wanted)
			Game.toast.emit("Помогала два часа по хозяйству", load("res://art/coin.png"))
			return
		"fortune":
			var herb: Array = _take_herbs(1, true)
			if herb.is_empty():
				d.call("_say", "Для гадания нужна хоть одна травинка.")
				_service_menu(d)
				return
			pay = int(randf_range(3.0, 9.0) * f)
			msg = "%s ... Ой, как интересно! Вот тебе %d монет за гадание." % [String(FORTUNES[randi() % FORTUNES.size()]), pay]
		"story":
			pay = int(randf_range(2.0, 6.0) * f * (1.5 if land in ["cats", "elves", "japan"] else 1.0))
			msg = "Ах, как мило! Рассказывай ещё когда-нибудь. Вот тебе %d монет на чай." % pay
		"stone":
			if Game.get_count("stone_m") >= 1:
				Game.take_item("stone_m")
			elif Game.get_count("stone_s") >= 3:
				Game.take_item("stone_s", 3)
			else:
				d.call("_say", "Нужен один средний камень или три маленьких.")
				_service_menu(d)
				return
			pay = int(7.0 * f * (1.5 if land in ["dwarves", "knights", "orcs"] else 1.0))
			msg = "Камни для сада — то, что нужно! Держи %d монет." % pay
		_:
			return
	Game.add_coins(pay)
	Sound.play("coin", -4.0)
	npc.call("react", "happy", 2.0)
	_finish(d, npc, land, wanted)
	d.call("_say", msg)
	_service_menu(d)


static func _finish(d: Node, npc: Node, land: String, wanted: bool) -> void:
	done[_key(npc)] = int(done.get(_key(npc), 0)) + 1
	Game.rep_add(land, 2 if wanted else 1, true)


## Забрать до n любых трав (самых дешёвых, если cheapest). Если не хватило — ничего не берёт.
static func _take_herbs(n: int, cheapest: bool) -> Array:
	var have: Array = []
	for k in Game.inventory.keys():
		if DB.DATA.has(String(k)) and int(Game.inventory[k]) > 0:
			for i in range(int(Game.inventory[k])):
				have.append(String(k))
	if have.size() < n:
		return []
	if cheapest:
		have.sort_custom(func(a: Variant, b: Variant) -> bool: return DB.price(String(a)) < DB.price(String(b)))
	var picked: Array = have.slice(0, n)
	for h in picked:
		Game.take_item(String(h))
	return picked


static func _take_from(list: Array, n: int) -> Array:
	var have: Array = []
	for k in list:
		for i in range(Game.get_count(String(k))):
			have.append(String(k))
	if have.size() < n:
		return []
	var picked: Array = have.slice(0, n)
	for h in picked:
		Game.take_item(String(h))
	return picked


static func _steal(d: Node) -> void:
	var npc: Node = d.get("npc")
	var land: String = String(npc.get("land"))
	var role: String = String(npc.get("role"))
	var lw: Node = _law(d)
	d.call("close")
	var chance: float = 0.55 if role != "лидер" else 0.1
	if randf() < chance:
		var loot: int = randi_range(5, 22)
		Game.add_coins(loot)
		get_tree_toast("Кошелёк потихоньку перекочевал к тебе", "res://art/coin.png")
		get_tree_react(d, "shy")
		if randf() < 0.25 and lw != null:
			lw.call("report", land, "theft", 1)
	else:
		var hud: Node = d.get_tree().get_first_node_in_group("hud")
		if hud != null:
			hud.call("say", String(npc.get("npc_name")), "Эй! Ты что делаешь?! Стража!")
		Sound.play("guard", -2.0)
		if lw != null:
			lw.call("report", land, "theft", 3)


static func get_tree_toast(text: String, icon_path: String) -> void:
	Game.toast.emit(text, load(icon_path))


static func get_tree_react(d: Node, kind: String) -> void:
	d.get_tree().call_group("player", "react", kind, 1.2)


static func _quest_ask(d: Node) -> void:
	var npc: Node = d.get("npc")
	var qn: Node = _qn(d)
	var nm: String = String(npc.get("npc_name"))
	var mine: Dictionary = qn.call("active_from", nm)
	if not mine.is_empty():
		if bool(qn.call("can_turn_in", mine)):
			var rw: String = String(qn.call("reward_text", mine))
			qn.call("turn_in", mine)
			d.call("_say", "Ты справилась! Спасибо огромное. Вот награда: %s." % rw)
			npc.call("react", "happy", 2.5)
			d.call("_talk_menu")
		else:
			d.call("_say", "Как моё поручение? Пока так: %s. Жду!" % String(qn.call("progress_text", mine)))
			d.call("_talk_menu")
		return
	var q: Dictionary = qn.call("offer_for", npc)
	if q.is_empty():
		d.call("_say", "Сегодня у меня всё хорошо, помощь не нужна. Заходи завтра!")
		d.call("_talk_menu")
		return
	d.call("_say", "%s\nНаграда: %s." % [String(q["text"]), String(qn.call("reward_text", q))])
	d.call("_set_options", [["Возьмусь!", "qv_accept"], ["Не сейчас", "qv_no"]])


static func _shelter_menu(d: Node) -> void:
	var npc: Node = d.get("npc")
	var land: String = String(npc.get("land"))
	var SH = preload("res://shelter.gd")
	var opts: Array = []
	for a in SH.list_for(land):
		opts.append(["%s — %d монет" % [String(SH.title(String(a[0]))), Game.rep_price(land, int(a[1]))], "sh:" + String(a[0])])
	opts.append(["Назад", "sv_exit"])
	d.call("_say", "Кого возьмёшь? Все добрые, привиты и любят гладиться." if land != "cats" else "У нас только кошечки! Выбирай — они уже мурчат.")
	d.call("_set_options", opts)
extends CanvasLayer
## Разговор с жителем: имя, реплика (печатается по буквам) и варианты ответа.
## Выбор: цифры 1-6, W/S + E/Enter или мышкой. Торговцы открывают лавку:
## купить местную еду и питьё (сразу утоляет голод и жажду) или продать травы, зелья, рыбу.

const NPC = preload("res://npc_db.gd")
const TALK = preload("res://talk_db.gd")
const DB = preload("res://herbs_db.gd")
const RDB = preload("res://recipes_db.gd")
const FDB = preload("res://fish_db.gd")
const FD = preload("res://food_db.gd")
const TIPS = preload("res://tips_db.gd")
const RECR = preload("res://recruit.gd")
const SVD = preload("res://svc_dialog.gd")
const TUT = preload("res://tutor27.gd")
const MD = preload("res://mining_db.gd")
const INK: Color = Color("3a2718")
const PX: float = 3.0
# смущённые ответы кошкодевочек на неловкий вопрос
const POOP_1: Array = [
	"Ч-что?! З-зачем ты такое спрашиваешь?! ...Мяу. Это вообще не твоё дело!",
	"Мя-а-а?! *уши прижались* Т-ты что, такое нельзя спрашивать у девушки!",
	"Ой... *краснеет до кончиков ушей* Зачем тебе это знать?! Фыр!",
	"Н-ну... мы же девочки! Девочки о таком не говорят! *прячет лицо в лапки*",
]
const POOP_2: Array = [
	"Опять?! Ну... как все, наверное... Только не смотри на меня так! Мяу...",
	"Ну... у нас есть лоток. ОЧЕНЬ красивый лоток! Всё, забудь, что я сказала!",
	"Ты правда хочешь это знать? *хвост дёргается* ...Да. Иногда. Доволь-на?!",
]
const POOP_3: Array = [
	"Всё! Я больше не разговариваю на эту тему! *отворачивается, хвост трубой*",
	"Фш-ш-ш! Ещё раз спросишь — расскажу всей деревне, какая ты странная!",
	"Мя-а-ау! Уйди-и! Мне стыдно! *закрывает уши лапками*",
]

var hud: CanvasLayer
var root: Control
var name_label: Label
var text_label: Label
var opts_box: Container
var npc: Node2D = null
var options: Array = []          # [текст, действие]
var sel: int = 0
var full_text: String = ""
var shown: float = 0.0
var open: bool = false
var mode: String = "talk"        # talk / buy / sell


func setup(h: CanvasLayer) -> void:
	hud = h
	layer = 25
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.visible = false
	add_child(root)
	var p: Control = Control.new()
	p.position = Vector2(300, 600)
	root.add_child(p)
	hud.call("panel", p, Vector2.ZERO, Vector2(1320, 440))
	name_label = Label.new()
	name_label.add_theme_font_override("font", hud.get("font_title"))
	name_label.add_theme_font_size_override("font_size", 44)
	name_label.add_theme_color_override("font_color", INK)
	name_label.position = Vector2(40, 8)
	p.add_child(name_label)
	text_label = Label.new()
	text_label.add_theme_font_override("font", hud.get("font_body"))
	text_label.add_theme_font_size_override("font_size", 28)
	text_label.add_theme_color_override("font_color", INK)
	text_label.position = Vector2(40, 72)
	text_label.size = Vector2(1240, 120)
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p.add_child(text_label)
	opts_box = GridContainer.new()
	(opts_box as GridContainer).columns = 2
	opts_box.position = Vector2(60, 196)
	opts_box.size = Vector2(1200, 220)
	opts_box.add_theme_constant_override("h_separation", 30)
	opts_box.add_theme_constant_override("v_separation", 0)
	p.add_child(opts_box)


func is_open() -> bool:
	return open


## Начать разговор с жителем (catgirl.gd и похожие)
func start(who: Node2D) -> void:
	npc = who
	if int(who.get("met_day")) != Game.day:
		who.set("asked", {})
	open = true
	Game.ui_open = true
	root.visible = true
	if who.has_meta("tutor"):
		who.set("met_day", Game.day)
		TUT.menu(self)
		return
	if int(who.get("met_day")) != Game.day:
		Game.rep_add(String(who.get("land")), 1, true)   # поздоровалась — уже приятно
	_say(_greeting())
	who.set("met_day", Game.day)
	_talk_menu()


func _land() -> Dictionary:
	return NPC.land(String(npc.get("land")))


func _greeting() -> String:
	var role: String = String(npc.get("role"))
	var l: Dictionary = _land()
	if role == "лидер":
		return "Добро пожаловать в %s, травница." % String(l.get("name", "наши края"))
	if role == "торговец":
		return "О, покупательница! Заходи, смотри, всё свежее."
	if role == "стража":
		return "Стой! А, ты травница. Проходи, только не шуми."
	if role == "кузнец":
		return ["Привет! Осторожно, искры летят.", "Дзынь! Ой, привет!", "Здравствуй! Руки в саже, обниматься не буду."].pick_random()
	if role == "заместитель":
		return "Здравствуй. Я помогаю управлять этими землями."
	# виделись ли сегодня; тон зависит от репутации с землёй
	var again: bool = int(npc.get("met_day")) == Game.day
	var lid0: String = String(npc.get("land"))
	if lid0 == "":
		return TALK.greet("", again)
	return TALK.greet_rep(lid0, Game.rep_tier(lid0), again)


func _talk_menu() -> void:
	mode = "talk"
	var role: String = String(npc.get("role"))
	var opts: Array = [["Кто ты?", "who"], ["Кто ваш лидер?", "leader"], ["Чем занимаешься?", "job"], ["Как дела?", "mood"], ["Расскажи об этих землях", "about"], ["Что нового?", "news"], ["Дай совет", "advice"], ["Ты милая!", "nice"]]
	if role == "торговец":
		# v16: покупают только с полок в лавке; хозяйке можно продать травы и зелья
		opts.insert(0, ["Хочу продать", "sell"])
	if role == "лидер":
		opts.append(["Можно попросить о помощи?", "help"])
	if String(npc.get("tex_name")).begins_with("catgirl") and role != "лидер":
		opts.append(["Погладить", "pet"])
	if String(npc.get("tex_name")).begins_with("catgirl"):
		opts.append(["А кошкодевочки... какают?", "poop"])
	# v17: вербовка — позвать с собой; у спутниц — свои вопросы
	var rcn: Node = get_tree().get_first_node_in_group("recruit")
	var tx: String = String(npc.get("tex_name"))
	if rcn != null and bool(RECR.profile(tx, role, String(npc.get("land")))["can"]):
		if bool(rcn.call("is_follower", tx)):
			for k in range(opts.size() - 1, -1, -1):
				if String(opts[k][1]) in ["leader", "about"]:
					opts.remove_at(k)
			opts.insert(1, ["Чего ты хочешь?", "wants"])
			opts.insert(2, ["Угостить", "feed"])
			opts.insert(3, ["Иди домой, я справлюсь", "dismiss"])
		else:
			opts.insert(1, ["Пойдёшь со мной?", "recruit"])
	opts.append(["Пока!", "bye"])
	opts = SVD.extra_options(self, opts)   # v18: услуги, задания, воровство, тюремщица
	var pth: Node = get_tree().get_first_node_in_group("paths")
	if pth != null:
		opts = pth.call("extra_options", self, opts)   # ранний доступ: союзы, кузница, фракции, лечение
	var k23: Node = get_tree().get_first_node_in_group("kingdom23")
	if k23 != null:
		opts = k23.call("extra_options", self, opts)   # v23: работницы и приказы
	_set_options(opts)


func _say(t: String) -> void:
	full_text = t
	shown = 0.0
	text_label.text = ""
	if npc != null and npc.has_method("react"):
		npc.call("react", "talk", minf(3.0, float(t.length()) * 0.03))
	name_label.text = _display_name()


func _display_name() -> String:
	var lid: String = String(npc.get("land"))
	var base: String = _display_name0()
	if lid == "":
		return base
	return "%s  · %s" % [base, Game.rep_name(lid)]


func _display_name0() -> String:
	var role: String = String(npc.get("role"))
	var n: String = String(npc.get("npc_name"))
	if npc.has_meta("tutor"):
		return n
	if role == "лидер":
		return String(_land().get("leader", n))
	if role == "торговец":
		return n + ", торговка"
	if role in ["кузнец", "стража", "заместитель"]:
		return n + ", " + {"кузнец": "кузнечиха", "стража": "стражница", "заместитель": "заместительница"}[role]
	return n


func _set_options(opts: Array) -> void:
	options = opts
	sel = 0
	for c in opts_box.get_children():
		opts_box.remove_child(c)
		c.queue_free()
	for i in range(opts.size()):
		var b: Button = Button.new()
		b.flat = true
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_override("font", hud.get("font_body"))
		b.add_theme_font_size_override("font_size", 24)
		b.custom_minimum_size = Vector2(580, 0)
		b.add_theme_color_override("font_color", Color("6a5038"))
		b.add_theme_color_override("font_hover_color", INK)
		b.text = "%d. %s" % [i + 1, String(opts[i][0])]
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(_choose.bind(i))
		b.mouse_entered.connect(func() -> void:
			sel = i
			_mark())
		opts_box.add_child(b)
	_mark()


func _mark() -> void:
	var kids: Array = opts_box.get_children()
	for i in range(kids.size()):
		var b: Button = kids[i]
		b.add_theme_color_override("font_color", INK if i == sel else Color("8a7058"))
		b.text = ("▸ " if i == sel else "   ") + "%d. %s" % [i + 1, String(options[i][0])]


func _choose(i: int) -> void:
	if i < 0 or i >= options.size():
		return
	Sound.play("ui_click", -6.0)
	# сначала договорить фразу, если она ещё печатается
	if shown < float(full_text.length()):
		shown = float(full_text.length())
		text_label.text = full_text
	var act: String = String(options[i][1])
	if TUT.handles(act):
		TUT.handle(self, act)
		return
	if SVD.handles(act):
		SVD.handle(self, act)
		return
	var k23b: Node = get_tree().get_first_node_in_group("kingdom23")
	if k23b != null and bool(k23b.call("handles", act)):
		k23b.call("handle", self, act)
		return
	var pth2: Node = get_tree().get_first_node_in_group("paths")
	if pth2 != null and bool(pth2.call("handles", act)):
		pth2.call("handle", self, act)
		return
	var l: Dictionary = _land()
	var role: String = String(npc.get("role"))
	var tex: String = String(npc.get("tex_name"))
	var asked: Dictionary = npc.get("asked")
	asked[act] = int(asked.get(act, 0)) + 1
	var cnt: int = int(asked[act])
	var lid: String = String(npc.get("land"))
	var tier: int = Game.rep_tier(lid)
	if tier == 0 and act in ["who", "leader", "about", "job", "mood", "advice", "news", "buy", "sell", "help", "pet"]:
		_say(String(TALK.REFUSE.pick_random()))
		npc.call("react", "pout", 2.0)
		_talk_menu()
		return
	var recr_act: bool = act in ["recruit", "wants", "feed", "dismiss", "pay_join"] or act.begins_with("joinfeed:") or act.begins_with("givefeed:")
	if cnt == 3 and not recr_act:
		Game.rep_add(lid, -2)
	elif cnt >= 4 and act != "nice" and not recr_act:
		Game.rep_add(lid, -1)
	if act in ["who", "leader", "about"] and cnt >= 3:
		_say(TALK.repeat("", cnt, lid))
		npc.call("react", "pout" if cnt == 3 else "disgust", 2.0)
		_talk_menu()
		return
	match act:
		"job":
			_say(TALK.repeat(_job_fresh(role), mini(cnt, 1) if cnt < 5 else cnt - 2, lid))
		"mood":
			_say(_mood_fresh(lid) if cnt < 5 else TALK.repeat("", cnt, lid))
		"advice":
			if cnt < 9:
				_give_advice(tex, role, lid)
			else:
				_say("Хватит советов на сегодня. Иди и пробуй сама!")
		"nice":
			if cnt < 4:
				if cnt == 1:
					Game.rep_add(lid, 2, true)
				_say(TALK.pick(TALK.COMPLIMENT, lid))
				npc.call("react", ["shy", "happy", "wink"].pick_random(), 2.0)
				_talk_menu()
				return
			_say("Ты это уже говорила... Подлизываешься, да?")
		"who":
			var p: Array = NPC.person(tex)
			if cnt == 2:
				_say(TALK.repeat("я %s. Запомни, пожалуйста!" % String(p[0]), 2, lid))
			elif role == "лидер":
				_say("Я %s, %s. %s" % [String(l.get("leader", p[0])), String(l.get("title", "")), String(p[1])])
			elif role == "торговец":
				_say("Я %s. Торгую тем, что любят в %s. %s" % [String(p[0]), String(l.get("name", "")), String(p[1])])
			elif role == "кузнец":
				_say("Я %s, здешняя кузнечиха. Кую подковы, ножи и котлы — для травниц тоже!" % String(p[0]))
			elif role == "стража":
				_say("Я %s, стражница %s. Слежу, чтобы никто не входил в чужие дома без приглашения." % [String(p[0]), String(l.get("name", ""))])
			elif role == "заместитель":
				_say("Я %s, заместительница. Помогаю: %s. Когда её нет — решаю я." % [String(p[0]), String(l.get("leader", ""))])
			else:
				_say("Я %s. %s" % [String(p[0]), String(p[1])])
		"leader":
			if cnt == 2 and not l.is_empty() and role != "лидер":
				_say(TALK.repeat("наш лидер — %s." % String(l.get("leader", "")), 2, lid))
			elif l.is_empty():
				_say("Лидер? Я живу сама по себе. Никто мне не указ — только лес да ветер.")
			elif role == "лидер":
				_say("Это я и есть! Если что-то нужно — спрашивай, помогу.")
			else:
				_say("Наш лидер — %s, %s. Найти её можно %s." % [String(l.get("leader", "")), String(l.get("title", "")), String(l.get("where", ""))])
		"about":
			_say(TALK.repeat(String(l.get("about", NPC.wild_about(tex))), cnt, lid))
		"news":
			if cnt >= 8:
				_say("Новостей больше нет! Все новости кончились!")
			else:
				var np: Array = TALK.NEWS_GENERIC.duplicate()
				np.append(NPC.gossip(String(npc.get("land"))))
				if lid != "":
					np.append_array(TALK.LAND_LINES.get(lid, []))
					np.append_array(TALK.LAND_LINES.get(lid, []))
				_say(TALK.fresh(np, npc))
		"poop":
			# смущается до кончиков ушей
			npc.call("react", "shy", 3.5)
			Sound.play("hiss" if cnt >= 3 else "ui_click", -10.0, 0.1, npc.global_position)
			if cnt == 1:
				_say(String(POOP_1.pick_random()))
			elif cnt == 2:
				_say(String(POOP_2.pick_random()))
			else:
				Game.rep_add(lid, -1)
				_say(String(POOP_3.pick_random()))
			_talk_menu()
			return
		"pet":
			if cnt <= 4:
				if cnt == 1:
					Game.rep_add(lid, 1, true)
				npc.call("pet_me")
				_say(String(TALK.PET_MORE.pick_random()))
			else:
				npc.call("react", "pout", 2.0)
				Sound.play("hiss", -8.0, 0.1, npc.global_position)
				Game.rep_add(lid, -3)
				_say(String(TALK.PET_TOO_MUCH.pick_random()))
		"help":
			var key: String = "gift_" + String(npc.get("land"))
			if int(Game.gifts.get(key, -1)) == Game.day:
				_say("Сегодня я уже помогла. Приходи завтра!")
			elif tier <= 1:
				_say("Помогать тебе? Сначала заслужи доверие нашей земли.")
			else:
				Game.gifts[key] = Game.day
				var gift: int = [0, 0, 15, 25, 40, 60][tier]
				Game.add_coins(gift)
				_say("Держи %d монет на дорогу. Путь у травницы долгий!" % gift if tier < 4 else "Ты наш друг! Вот %d монет, и приходи ещё!" % gift)
		"buy":
			_say("Что возьмёшь? У тебя %d монет." % Game.coins)
			_buy_menu()
			return
		"sell":
			_say("Что продашь? Беру травы, зелья и рыбу.")
			_sell_menu()
			return
		"recruit":
			_recruit_start(tex, role, lid, tier)
			return
		"pay_join":
			var pf1: Dictionary = RECR.profile(tex, role, lid)
			if Game.coins < int(pf1["fee"]):
				_say("Не хватает монет: нужно %d, а у тебя %d." % [int(pf1["fee"]), Game.coins])
				_talk_menu()
			else:
				Game.coins -= int(pf1["fee"])
				Game.inventory_changed.emit()
				_do_join(pf1)
			return
		"wants":
			_say(_wants_text())
			_talk_menu()
			return
		"feed":
			_feed_menu()
			return
		"dismiss":
			var rc2: Node = get_tree().get_first_node_in_group("recruit")
			rc2.call("leave", int(rc2.call("find", tex)), "")
			_say("Хорошо. Береги себя, а если что — зови, я приду!")
			_talk_menu()
			return
		"back":
			_talk_menu()
			_say("Что-нибудь ещё?")
			return
		"bye":
			close()
			return
	if act.begins_with("joinfeed:"):
		var jf: String = act.substr(9)
		var pf2: Dictionary = RECR.profile(tex, role, lid)
		if Game.take_item(jf):
			_do_join(pf2, 0.95)
		return
	if act.begins_with("givefeed:"):
		var rc3: Node = get_tree().get_first_node_in_group("recruit")
		if bool(rc3.call("feed", int(rc3.call("find", tex)), act.substr(9))):
			_say(["Ммм, как вкусно! Спасибо!", "Ой, мне? Спасибо, ты чудо!", "Вот это да! Люблю такое!"].pick_random())
		_feed_menu()
		return
	if act.begins_with("buy:"):
		var g: Array = _goods()[int(act.substr(4))]
		var cost: int = Game.rep_price(lid, int(g[1]))
		if Game.coins < cost:
			_say("Ой, не хватает монет. Это стоит %d." % cost)
		else:
			Game.coins -= cost
			Game.rep_add(lid, 1, true)
			Game.inventory_changed.emit()
			get_tree().call_group("player", "react", "happy", 1.6)
			if g.size() > 4:
				# v17: еда попадает в сумку — съесть можно позже (ПКМ по ней)
				Game.add_item(String(g[4]))
				_say("Держи «%s». Съешь, когда проголодаешься!" % String(g[0]))
			else:
				Game.hunger = maxf(0.0, Game.hunger - float(g[2]))
				Game.thirst = maxf(0.0, Game.thirst - float(g[3]))
				Game.food_load = minf(2.0, Game.food_load + float(g[2]))
				Game.drink_load = minf(2.0, Game.drink_load + float(g[3]))
				_say("Приятного аппетита! «%s» — лучшее, что у нас есть." % String(g[0]))
		_buy_menu()
		return
	if act == "sellherbs":
		var got: int = 0
		var k_rep: float = [0.6, 0.8, 1.0, 1.1, 1.2, 1.3][Game.rep_tier(lid)] * (1.0 + Game.stat("sell") / 100.0)
		for hid in Game.inventory.keys():
			var hs: String = String(hid)
			if DB.DATA.has(hs) and int(Game.inventory[hs]) > 0:
				got += maxi(1, int(round(_price(hs) * k_rep))) * int(Game.inventory[hs])
				Game.inventory[hs] = 0
		Game.inventory_changed.emit()
		Game.rep_add(lid, 2, true)
		Game.add_coins(got)
		_say("Какие травы! Беру все. Вот %d монет." % got)
		_sell_menu()
		return
	if act.begins_with("sell:"):
		var id: String = act.substr(5)
		if Game.take_item(id):
			var pr: int = maxi(1, int(round(_price(id) * [0.6, 0.8, 1.0, 1.1, 1.2, 1.3][Game.rep_tier(lid)] * (1.0 + Game.stat("sell") / 100.0))))
			Game.rep_add(lid, 1, true)
			Game.add_coins(pr)
			_say("Беру! Вот %d монет." % pr)
		_sell_menu()
		return
	_talk_menu()


# ------------------------------------------------------------------ v17: вербовка

func _recruit_start(tex: String, role: String, lid: String, tier: int) -> void:
	var rc: Node = get_tree().get_first_node_in_group("recruit")
	var pf: Dictionary = RECR.profile(tex, role, lid)
	if Game.team.size() >= Game.TEAM_MAX:
		_say("Вас уже и так %d. Больше я за тобой не успею." % (Game.team.size() + 1))
		_talk_menu()
		return
	if lid != "" and tier < int(pf["tier"]):
		_say("Мы ещё слишком мало знакомы. Подружись с нашей землёй — хотя бы до «%s». Тогда поговорим." % RECR.tier_name(int(pf["tier"])))
		_talk_menu()
		return
	match String(pf["type"]):
		"free":
			_do_join(pf)
		"money":
			_say(RECR.terms_text(pf, lid) + " (у тебя %d монет)" % Game.coins)
			_set_options([["Заплатить %d монет" % int(pf["fee"]), "pay_join"], ["Не сейчас", "back"]])
		"food":
			_say(RECR.terms_text(pf, lid) + " Угостишь меня сейчас?")
			_food_options(pf, "joinfeed:")


## Выбор еды из сумки: любимая жительницы сначала
func _food_options(pf: Dictionary, prefix: String) -> void:
	var opts: Array = []
	var seen: Dictionary = {}
	var kinds_first: Array = [String(pf["likes"])]
	for pass_i in range(2):
		for k in FD.ORDER:
			var fid: String = "food_" + String(k)
			if Game.get_count(fid) <= 0 or seen.has(fid) or FD.is_drink(fid):
				continue
			if (pass_i == 0) != (FD.kind(fid) in kinds_first):
				continue
			seen[fid] = true
			if opts.size() < 6:
				opts.append(["%s%s (%d)" % ["Угостить: ", FD.name(fid), Game.get_count(fid)], prefix + fid])
	if opts.is_empty():
		_say("У тебя нечем меня угостить. Принеси что-нибудь вкусное, особенно — %s." % String(RECR.LIKE_NAME.get(String(pf["likes"]), "вкусное")))
		_talk_menu()
		return
	opts.append(["Назад", "back"])
	_set_options(opts)


func _feed_menu() -> void:
	var rc: Node = get_tree().get_first_node_in_group("recruit")
	var i: int = int(rc.call("find", String(npc.get("tex_name"))))
	if i < 0:
		_talk_menu()
		return
	_say("Чем угостишь? Люблю: %s." % String(RECR.LIKE_NAME.get(String((Game.team[i] as Dictionary)["likes"]), "вкусное")))
	_food_options(Game.team[i], "givefeed:")


func _do_join(pf: Dictionary, loyal: float = 0.8) -> void:
	var rc: Node = get_tree().get_first_node_in_group("recruit")
	if bool(rc.call("join", npc, pf)):
		(Game.team[Game.team.size() - 1] as Dictionary)["loyalty"] = loyal
		Game.rep_add(String(npc.get("land")), 2, true)
		_say(["Договорились! Идём вместе.", "Ура, приключения! Я с тобой.", "Хорошо. Но помни про наш уговор!"].pick_random())
		npc.call("react", "happy", 2.0)
		Game.toast.emit("%s теперь с тобой. %s" % [String(npc.get("npc_name")), String(pf["perk_text"])], null)
		Sound.play("pickup", -4.0)
	else:
		_say("Что-то не вышло. Попробуй ещё раз.")
	_talk_menu()


func _wants_text() -> String:
	var rc: Node = get_tree().get_first_node_in_group("recruit")
	var i: int = int(rc.call("find", String(npc.get("tex_name"))))
	if i < 0:
		return "Я свободна."
	var m: Dictionary = Game.team[i]
	var lo: float = float(m["loyalty"])
	var mood: String = "Мне с тобой хорошо." if lo > 0.7 else ("Нормально, но можно лучше." if lo > 0.4 else "Мне тяжело. Я думаю уйти.")
	var need: String = ""
	match String(m["req"]):
		"money":
			need = "Мне нужно %d монет в день (у тебя %d)." % [int(m["wage"]), Game.coins]
		"food":
			need = "Каждый день мне нужно поесть, особенно — %s." % String(RECR.LIKE_NAME.get(String(m["likes"]), "вкусное"))
		_:
			need = "Мне ничего не нужно, только не ссорься с моей землёй."
	return "%s %s %s" % [mood, need, String(m["perk_text"]) + "."]


## Что делает житель: своё занятие или просто чем-то занята (без повторов)
func _job_fresh(role: String) -> String:
	var job: String = String(npc.get("job"))
	var pool: Array = []
	if TALK.JOB_TALK.has(job) and job != "":
		pool.append_array(TALK.JOB_TALK[job])
	elif TALK.JOB_TALK.has(role):
		pool.append_array(TALK.JOB_TALK[role])
	pool.append_array(TALK.JOB_TALK[""])
	return TALK.fresh(pool, npc)


func _mood_fresh(lid: String) -> String:
	var pool: Array = (TALK.MOOD[""] as Array).duplicate()
	for src in [TALK.MOOD, TALK.MOOD_MORE]:
		if (src as Dictionary).has(lid):
			pool.append_array((src as Dictionary)[lid])
			pool.append_array((src as Dictionary)[lid])
	return TALK.fresh(pool, npc)


## Совет: у каждой жительницы свои, а новый тут же записывается в книгу (на страничку травы, гриба, еды или в «Заметки»)
func _give_advice(tex: String, role: String, lid: String) -> void:
	var said: Array = npc.get_meta("said_ids") if npc.has_meta("said_ids") else []
	var tip: Dictionary = TIPS.pick_for(tex, String(npc.get("job")), role, lid, said)
	if tip.is_empty():
		_say(String(TALK.ADVICE.pick_random()))
		return
	said.append(String(tip["id"]))
	while said.size() > 14:
		said.pop_front()
	npc.set_meta("said_ids", said)
	_say(String(tip["text"]))
	if Game.learn_tip(tip):
		Sound.play("page", -6.0, 0.15)
		Game.toast.emit("Записано в книгу: %s" % String(TIPS.SECTION.get(String(tip["cat"]), "Заметки")), null)


func _buy_menu() -> void:
	mode = "buy"
	var opts: Array = []
	var goods: Array = _goods()
	var lb: String = String(npc.get("land"))
	for i in range(goods.size()):
		var g: Array = goods[i]
		opts.append(["%s — %d монет" % [String(g[0]), Game.rep_price(lb, int(g[1]))], "buy:%d" % i])
	opts.append(["Назад", "back"])
	_set_options(opts)


## Товары: у пекарни, таверны и лавки — свои, иначе — еда земли
func _goods() -> Array:
	var raw: Array = npc.get_meta("goods") if npc.has_meta("goods") else _land().get("goods", [])
	var out: Array = []
	for g in raw:
		if g is String and FD.DATA.has(String(g)):
			var k: String = String(g)
			out.append([FD.name(k), FD.price(k), FD.hunger_of(k), FD.juicy_of(k), "food_" + k])
		elif g is Array:
			out.append(g)
	return out


func _price(id: String) -> int:
	if MD.is_mineral(id):
		return MD.price(id)
	if id.begins_with("dry:") and DB.DATA.has(id.substr(4)):
		return int(round(DB.price(id.substr(4)) * 1.4))
	if preload("res://wild_db.gd").is_shroom(id):
		return int((preload("res://wild_db.gd").SHROOMS[id] as Dictionary)["price"])
	if FDB.is_fish(id):
		return int((FDB.DATA[id] as Dictionary).get("price", 4))
	if RDB.is_product(id):
		return 6 if id == "murky" else 14
	if DB.DATA.has(id):
		var hp: int = DB.price(id)
		return int(round(hp * 1.5)) if Game.researched.has(id) else hp
	return 3


func _item_name(id: String) -> String:
	if preload("res://wild_db.gd").is_shroom(id):
		return preload("res://wild_db.gd").shroom_name(id)
	if FDB.is_fish(id):
		return FDB.title(id)
	if RDB.is_product(id):
		return RDB.name(id)
	if not DB.DATA.has(id):
		return preload("res://items_db.gd").name(id)
	return DB.short(id)


func _sell_menu() -> void:
	mode = "sell"
	var opts: Array = []
	var herbs_total: int = 0
	var herbs_n: int = 0
	for id in Game.inventory.keys():
		var sid: String = String(id)
		var n: int = int(Game.inventory[id])
		if n <= 0 or (preload("res://items_db.gd").is_new(sid) and not MD.is_mineral(sid) and not sid.begins_with("dry:")):
			continue
		if DB.DATA.has(sid):
			herbs_total += _price(sid) * n
			herbs_n += n
		if opts.size() < 7:
			opts.append(["%s (%d шт.) — %d монет" % [_item_name(sid), n, _price(sid)], "sell:" + sid])
	if herbs_n > 1:
		opts.insert(0, ["Все травы (%d шт.) — около %d монет" % [herbs_n, herbs_total], "sellherbs"])
	if opts.is_empty():
		_say("Тебе нечего продать. Принеси травы, зелья, грибы или рыбу!")
	opts.append(["Назад", "back"])
	_set_options(opts)


func close() -> void:
	open = false
	root.visible = false
	Game.ui_open = false
	npc = null


func _process(delta: float) -> void:
	if not open:
		return
	if shown < float(full_text.length()):
		var before: int = int(shown)
		shown = minf(float(full_text.length()), shown + delta * 55.0)
		text_label.text = full_text.substr(0, int(shown))
		# голос: слог на каждые 3 буквы, у каждого жителя своя высота
		if npc != null and int(shown) / 3 != before / 3:
			var h: int = abs(hash(String(npc.get("tex_name"))))
			Sound.talk(h % 4, 0.85 + float(h % 7) * 0.06)


func _input(event: InputEvent) -> void:
	if not open:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var k: Key = (event as InputEventKey).physical_keycode
		if k >= KEY_1 and k <= KEY_9:
			_choose(int(k - KEY_1))
		elif KB.is_key("move_up", k) or k == KEY_UP:
			sel = posmod(sel - 1, options.size())
			_mark()
		elif KB.is_key("move_down", k) or k == KEY_DOWN:
			sel = posmod(sel + 1, options.size())
			_mark()
		elif KB.is_key("interact", k) or k == KEY_ENTER or k == KEY_SPACE:
			_choose(sel)
		elif k == KEY_ESCAPE:
			close()
		get_viewport().set_input_as_handled()

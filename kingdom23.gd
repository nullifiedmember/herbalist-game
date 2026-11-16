extends Node
## v23: работники и своё королевство. Полная свобода: можно жить одинокой варщицей, а можно набрать людей.
## Нанять — в разговоре с жительницей («Пойдёшь ко мне работать?»). Приказы — в разговоре с работницей или окно O.
## Работа идёт каждый игровой час, добыча — в сундук. Когда работниц 10 — одна предложит основать королевство
## (можно отказаться, можно потом распустить). В королевстве нужны дома (где спать), развлечения и мастерские.

const IT = preload("res://items_db.gd")
const NPC = preload("res://npc_db.gd")
const DB = preload("res://herbs_db.gd")
const W = preload("res://wild_db.gd")
const V = preload("res://v23_data.gd")
const PROPOSE_AT: int = 10
const MAX_NO_KINGDOM: int = 12
const HIRE_FEE: int = 30
const SETTLERS: Array = ["catgirl_mira", "catgirl_ryzhik", "catgirl_snow", "catgirl_choco", "catgirl_cream", "catgirl_smoky", "catgirl_vanilla", "catgirl_maple",
	"elf_lirael", "elf_sylwen", "elf_thalia", "knight_aria", "knight_sera", "knight_vera", "mage_aurel", "mage_fenna", "mage_ilka", "mage_lisel", "mage_noa",
	"kitsune_aka", "kitsune_hana", "kitsune_kuro", "kitsune_sakura", "adv_elma", "adv_rina", "hunter_vesna", "orc_grasha", "orc_ruzga"]
## приказ: название, значок, занятие (анимация), сдвиг места работы от дома
const ORDERS: Dictionary = {
	"rest": ["Отдыхать", "ord_rest", "chat", Vector2(0, 160)],
	"wood": ["Рубить лес", "ord_wood", "chop", Vector2(-320, 120)],
	"herb": ["Собирать травы", "ord_herb", "garden", Vector2(260, 200)],
	"shroom": ["Искать грибы", "ord_shroom", "dig", Vector2(-260, -160)],
	"stone": ["Добывать камень", "ord_stone", "dig", Vector2(340, -140)],
	"fish": ["Рыбачить", "ord_fish", "farm", Vector2(200, 340)],
	"farm": ["Смотреть за зверями", "ord_farm", "farm", Vector2(-200, 300)],
	"guard": ["Охранять дом", "ord_guard", "train", Vector2(0, 260)],
	"brew": ["Варить зелья", "ord_brew", "brew", Vector2(120, -220)],
	"build": ["Помогать строить", "ord_build", "tinker", Vector2(-120, -240)],
}
const ORDER_KEYS: Array = ["rest", "wood", "herb", "shroom", "stone", "fish", "farm", "guard", "brew", "build"]
const NAME_A: Array = ["Травяное", "Лунное", "Мурлыкающее", "Тихое", "Звёздное", "Медовое", "Туманное", "Зелёное", "Котелковое", "Ромашковое"]
const NAME_B: Array = ["королевство", "княжество", "царство", "королевство Ветров", "королевство Котла", "королевство Рассвета"]

var main: Node2D
var v23: Node
var nodes: Dictionary = {}          # индекс работницы -> узел
var last_min: float = -1.0
var t: float = 0.0
var spawned: bool = false
var win: Control
var win_list: VBoxContainer
var win_info: Label
var propose_t: float = -1.0


func setup(m: Node2D, v: Node) -> void:
	main = m
	v23 = v
	add_to_group("kingdom23")
	Game.day_changed.connect(_on_day)
	win = v.call("_panel", v.get("ui"), Rect2(260, 80, 1400, 920))
	win.visible = false
	var ttl: Label = v.call("_label", win, "Работники и королевство", "font_title", 40, Color("f0d89a"))
	ttl.position = Vector2(0, 24)
	ttl.size = Vector2(1400, 50)
	ttl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	win_info = v.call("_label", win, "", "font_body", 22, Color("e8dcc4"))
	win_info.position = Vector2(50, 84)
	win_info.size = Vector2(1300, 90)
	win_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var sc: ScrollContainer = ScrollContainer.new()
	sc.position = Vector2(50, 190)
	sc.size = Vector2(1300, 700)
	win.add_child(sc)
	win_list = VBoxContainer.new()
	win_list.add_theme_constant_override("separation", 6)
	sc.add_child(win_list)


func home() -> Vector2:
	return Game.home_pos + Vector2(0, 60)


# ------------------------------------------------------------------ найм (через разговор)

func handles(act: String) -> bool:
	return act.begins_with("k23_")


func extra_options(d: Node, opts: Array) -> Array:
	var npc: Node = d.get("npc")
	if npc == null or Game.SOLO:     # v29: нанимать работниц нельзя
		return opts
	if npc.has_meta("worker23"):
		# работница: только приказы
		var out: Array = []
		for k in ORDER_KEYS:
			if k == "brew" and _count_kind("kg_brewery") == 0 and not Game.god_mode:
				continue
			out.append(["Приказ: " + String(ORDERS[k][0]).to_lower(), "k23_order:" + String(k)])
		out.append(["Как ты? Всё хорошо?", "k23_mood"])
		out.append(["Ты свободна, иди домой", "k23_fire"])
		out.append(["Пока!", "bye"])
		return out
	var role: String = String(npc.get("role"))
	if role in ["лидер", "стража", "торговец", "заместитель", "тюремщица"] or String(npc.get("npc_name")) == "":
		return opts
	var tex: String = String(npc.get("tex_name"))
	for wk in Game.workers:
		if String(wk["tex"]) == tex:
			return opts
	var i: int = maxi(0, opts.size() - 1)
	opts.insert(i, ["Пойдёшь ко мне работать? (%d монет)" % HIRE_FEE, "k23_hire"])
	return opts


func handle(d: Node, act: String) -> void:
	var npc: Node2D = d.get("npc")
	if act == "k23_hire":
		var lid: String = String(npc.get("land"))
		if Game.workers.size() >= max_workers():
			d.call("_say", "Ой, у тебя и так полно работниц. Им негде спать! Построй ещё домик.")
		elif lid != "" and Game.rep_tier(lid) < 2:
			d.call("_say", "Я тебя почти не знаю... Может, когда-нибудь потом.")
		elif Game.coins < HIRE_FEE and not Game.god_mode:
			d.call("_say", "Работать задаром? Ну уж нет. Приходи с монетками!")
		else:
			if not Game.god_mode:
				Game.coins -= HIRE_FEE
				Game.inventory_changed.emit()
			hire(String(npc.get("tex_name")), String(npc.get("npc_name")), lid)
			d.call("_say", "Договорились! Иду к твоему дому. Скажешь, что делать.")
			npc.call("react", "happy", 2.0)
			npc.visible = false
			npc.set_process(false)
			npc.remove_from_group("interactables")
		d.call("_talk_menu")
		return
	var idx: int = int(npc.get_meta("worker23", -1))
	if idx < 0 or idx >= Game.workers.size():
		d.call("close")
		return
	if act.begins_with("k23_order:"):
		give_order(idx, act.substr(10))
		d.call("_say", ["Будет сделано!", "Уже бегу!", "Поняла, хозяйка!", "Хорошо, займусь."].pick_random())
	elif act == "k23_mood":
		var h: float = happiness()
		d.call("_say", "Всё чудесно! Мне тут нравится." if h > 0.8 else ("Неплохо... но спать тесновато и скучновато." if h > 0.5 else "Честно? Устала. Нам нужны кровати и хоть какие-то развлечения."))
	elif act == "k23_fire":
		fire(idx)
		d.call("_say", "Ладно... Если что — зови!")
		d.call("close")
		return
	d.call("_talk_menu")


func max_workers() -> int:
	if Game.kingdom.is_empty():
		return MAX_NO_KINGDOM
	return clampi(beds() + 2, MAX_NO_KINGDOM, 60)


func hire(tex: String, nm: String, land: String) -> void:
	Game.workers.append({"tex": tex, "name": nm, "land": land, "order": "rest", "since": Game.day})
	Game.skill_xp("lead", 15.0)
	Game.toast.emit("%s теперь работает на тебя!" % nm, load("res://art/icon_worker.png"))
	_spawn_worker(Game.workers.size() - 1)
	if Game.workers.size() >= PROPOSE_AT and Game.kingdom.is_empty() and not Game.kingdom_refused:
		propose_t = 4.0


func god_hire(n: int) -> void:
	for i in range(n):
		var tex: String = String(SETTLERS[(Game.workers.size() + i) % SETTLERS.size()])
		hire(tex, String(NPC.person(tex)[0]), "")


func fire(idx: int) -> void:
	if nodes.has(idx) and is_instance_valid(nodes[idx]):
		(nodes[idx] as Node).queue_free()
	Game.workers.remove_at(idx)
	_respawn_all()
	var v24n: Node = get_tree().get_first_node_in_group("v24")
	if v24n != null:
		v24n.call("refresh_residents")


func give_order(idx: int, order: String) -> void:
	if idx < 0 or idx >= Game.workers.size() or not ORDERS.has(order):
		return
	Game.workers[idx]["order"] = order
	var n: Node2D = nodes.get(idx)
	if n != null and is_instance_valid(n):
		_apply_order(n, order, idx)


# ------------------------------------------------------------------ работницы в мире

func _respawn_all() -> void:
	for k in nodes.keys():
		if is_instance_valid(nodes[k]):
			(nodes[k] as Node).queue_free()
	nodes.clear()
	for i in range(Game.workers.size()):
		_spawn_worker(i)


func _spawn_worker(i: int) -> void:
	var w: Dictionary = Game.workers[i]
	var tex: String = String(w["tex"])
	if not ResourceLoader.exists("res://art/%s.png" % tex) or not ResourceLoader.exists("res://art/faces_%s.png" % tex):
		tex = "catgirl_mira"
	var n: Node2D = Node2D.new()
	n.set_script(load("res://catgirl.gd"))
	(main.get("objects") as Node).add_child(n)
	var at: Vector2 = main.call("free_near", home() + Vector2(randf_range(-120, 120), randf_range(60, 160)))
	n.call("setup", tex, at)
	n.set("land", "")
	n.set("role", "работница")
	n.set("npc_name", String(w["name"]))
	n.set("blocked", Callable(main, "is_blocked"))
	n.set_meta("worker23", i)
	main.call("add_caster", n.get("spr") as Sprite2D, true)
	nodes[i] = n
	_apply_order(n, String(w.get("order", "rest")), i)
	var w24: Node = get_tree().get_first_node_in_group("workers24")
	if w24 != null:
		w24.call("adopt", n, i)


func _apply_order(n: Node2D, order: String, i: int) -> void:
	var o: Array = ORDERS.get(order, ORDERS["rest"])
	var spread: Vector2 = Vector2(float((i * 37) % 120) - 60.0, float((i * 53) % 80) - 40.0)
	var spot: Vector2 = main.call("free_near", home() + (o[3] as Vector2) + spread)
	n.set("home", spot)
	n.set("roam", 50.0 if order != "rest" else 140.0)
	n.set("job", String(o[2]))
	n.set("job_at", spot + Vector2(-18, 0))
	n.set("route", [spot])
	n.set("walking", true)


# ------------------------------------------------------------------ работа каждый час

func _process(delta: float) -> void:
	t += delta
	if not spawned and t > 0.4:
		spawned = true
		_respawn_all()
	if propose_t > 0.0 and not Game.SOLO:
		propose_t -= delta
		if propose_t <= 0.0:
			propose()
	var abs_min: float = float(Game.day) * 1440.0 + Game.minutes
	if last_min < 0.0:
		last_min = abs_min
	if abs_min - last_min >= 60.0:
		var hours: int = int((abs_min - last_min) / 60.0)
		last_min += float(hours) * 60.0
		for h in range(mini(hours, 12)):
			_work_hour()
	if win.visible:
		info_t -= delta
		if info_t <= 0.0:
			info_t = 0.5
			win_info.text = _info_text()


var info_t: float = 0.0


func happiness() -> float:
	var n: int = Game.workers.size()
	if n == 0:
		return 1.0
	if Game.kingdom.is_empty():
		return 0.9
	var bed_k: float = clampf(float(beds()) / float(n), 0.0, 1.0)
	var fun_k: float = clampf(float(fun()) / float(maxi(1, n)) * 1.5, 0.0, 1.0)
	return clampf(0.25 + bed_k * 0.45 + fun_k * 0.35, 0.0, 1.0)


func _count_kind(kind: String) -> int:
	var hs: Node = get_tree().get_first_node_in_group("homestead")
	var c: int = 0
	if hs != null:
		for pl in (hs.get("placed") as Array):
			if String(pl[0]) == kind:
				c += 1
	return c


func _sum(kind_type: String) -> int:
	var hs: Node = get_tree().get_first_node_in_group("homestead")
	var c: int = 0
	if hs != null:
		for pl in (hs.get("placed") as Array):
			var k: String = String(pl[0])
			if IT.KBUILD.has(k) and String(IT.KBUILD[k][7]) == kind_type:
				c += int(IT.KBUILD[k][8])
	return c


func beds() -> int:
	return _sum("house")


func fun() -> int:
	return _sum("fun")


var _cur_worker: Variant = null


## v24: добыча работницы — к ней в охапку (сама отнесёт в подходящий сундук); мастерские — сразу в сундуки
func _store(id: String, n: int) -> void:
	if n <= 0:
		return
	var w24: Node = get_tree().get_first_node_in_group("workers24")
	if w24 != null and _cur_worker != null and is_instance_valid(_cur_worker):
		w24.call("load_up", _cur_worker, id, n)
		return
	var cu: Node = get_tree().get_first_node_in_group("chest_ui")
	if cu != null and not Game.chests.is_empty():
		var left: int = int(cu.call("deposit", id, n, home()))
		if left > 0:
			Game.ground.append([id, left, home().x, home().y + 30.0])
	else:
		Game.ground.append([id, n, home().x, home().y + 30.0])


func _work_hour() -> void:
	var h: float = Game.hour()
	if h < 7.0 or h > 20.0:
		return            # ночью спят
	var k: float = happiness() * (1.0 + Game.stat("lead") / 100.0)
	var herbs: Array = []
	for hid in DB.ORDER:
		if int((DB.DATA[hid] as Dictionary).get("rare", 0)) == 0:
			herbs.append(String(hid))
	for wi in range(Game.workers.size()):
		var w: Dictionary = Game.workers[wi]
		_cur_worker = nodes.get(wi)
		var o: String = String(w.get("order", "rest"))
		if randf() > k:
			continue
		match o:
			"wood":
				pass      # v24: рубят настоящие деревья (workers24.gd)
			"herb":
				if randf() < 0.6 and not herbs.is_empty():
					_store(String(herbs.pick_random()), 1)
			"shroom":
				if randf() < 0.3:
					_store(String(W.SHROOMS.keys().pick_random()), 1)
			"stone":
				if randf() < 0.5:
					_store("stone_m" if randf() < 0.6 else "stone_s", 1)
				if randf() < 0.04:
					_store(["ore_mana", "ore_frost", "ore_ember", "ore_verdant"].pick_random(), 1)
			"fish":
				if randf() < 0.3:
					_store(String(preload("res://fish_db.gd").roll(h, randf(), 0.6)), 1)
			"brew":
				if randf() < 0.15 * float(maxi(1, _count_kind("kg_brewery"))):
					_store(["sleep_tea", "vigor_tea", "calm_tea", "mint_tea", "warm_tea"].pick_random(), 1)
			"farm":
				var fm: Node = get_tree().get_first_node_in_group("farm23")
				if fm != null and randf() < 0.2:
					for e in Game.farm:
						if int(e.get("ready", 0)) > 0:
							var pr: Array = preload("res://farm23.gd").ZOO[String(e["kind"])][3]
							_store(String(pr[0]), int(pr[1]) * int(e["ready"]))
							e["ready"] = 0
		Game.skill_xp("lead", 0.3)
	_cur_worker = null


# ------------------------------------------------------------------ королевство

func propose() -> void:
	if not Game.kingdom.is_empty() or Game.workers.is_empty():
		return
	Game.kingdom_asked = Game.day
	var w: Dictionary = Game.workers[0]
	var face: Texture2D = _face(String(w["tex"]))
	v23.call("talk", face, String(w["name"]),
		"Хозяйка... нас уже %d! Мы тут посовещались у костра. А давай построим своё королевство? Домики, таверну, зельеварню... А ты будешь королевой! Но если хочешь и дальше жить тихо — мы поймём." % Game.workers.size(),
		[["Да! Основать королевство", func() -> void: _choose_name()],
		 ["Нет. Я одинокая варщица, мне так хорошо", func() -> void: refuse()],
		 ["Дай подумать (спросите позже)", func() -> void: Game.toast.emit("Работницы спросят через пару дней", load("res://art/icon_worker.png"))]])


func _choose_name() -> void:
	var opts: Array = []
	var used: Dictionary = {}
	for i in range(4):
		var nm: String = "%s %s" % [String(NAME_A.pick_random()), String(NAME_B.pick_random())]
		if used.has(nm):
			continue
		used[nm] = true
		opts.append([nm, func() -> void: found(nm)])
	opts.push_front(["Придумать своё название…", func() -> void: ask_name()])
	v23.call("talk", load("res://art/icon_crown23.png"), "Имя королевства", "Как назовём наше королевство?", opts)


## v24: название королевства — какое захочется
func ask_name() -> void:
	var v24n: Node = get_tree().get_first_node_in_group("v24")
	if v24n == null:
		return
	var def: String = String(Game.kingdom.get("name", "")) if not Game.kingdom.is_empty() else ""
	v24n.call("ask_text", "Как назовём королевство?", def, func(s: String) -> void:
		if Game.kingdom.is_empty():
			found(s)
		else:
			var old: String = String(Game.kingdom.get("name", ""))
			Game.kingdom["name"] = s
			Game.chron("Королевство «%s» теперь зовётся «%s»." % [old, s], "kingdom")
			Game.toast.emit("Теперь королевство зовётся «%s»" % s, load("res://art/icon_crown23.png"))
			if win.visible:
				open_window())


func found(nm: String) -> void:
	if nm == "":
		nm = "%s %s" % [String(NAME_A.pick_random()), String(NAME_B[0])]
	Game.kingdom = {"name": nm, "day": Game.day, "level": 1}
	Game.kingdom_refused = false
	Game.chron("Основано королевство «%s». Ты — королева!" % nm, "kingdom")
	Game.toast.emit("Да здравствует королева! «%s»" % nm, load("res://art/icon_crown23.png"))
	Game.skill_xp("lead", 100.0)
	Sound.play("magic", -2.0)
	for n in nodes.values():
		if is_instance_valid(n):
			(n as Node).call("react", "happy", 3.0)
			Game.fx.emit((n as Node2D).global_position + Vector2(0, -40), "sparkle")


func refuse() -> void:
	Game.kingdom_refused = true
	Game.toast.emit("Ты осталась одинокой варщицей. Это твой выбор.", load("res://art/fx_heart.png"))
	Game.chron("Отказалась строить королевство — свобода дороже короны.", "kingdom")


func abdicate() -> void:
	if Game.kingdom.is_empty():
		return
	Game.chron("Королевство «%s» распущено. Снова сама по себе." % String(Game.kingdom["name"]), "kingdom")
	Game.kingdom = {}
	Game.kingdom_refused = true
	Game.toast.emit("Королевство распущено. Ты снова одинокая варщица.", load("res://art/fx_heart.png"))


func _on_day() -> void:
	# повторно спросить о королевстве (если не отказалась насовсем)
	if Game.kingdom.is_empty() and not Game.kingdom_refused and Game.workers.size() >= PROPOSE_AT and Game.day - Game.kingdom_asked >= 2:
		propose_t = 6.0
	if Game.kingdom.is_empty():
		return
	var hp: float = happiness()
	# мастерские королевства работают сами
	for i in range(_count_kind("kg_brewery") * 2):
		_store(["sleep_tea", "vigor_tea", "calm_tea", "mint_tea", "warm_tea"].pick_random(), 1)
	for i in range(_count_kind("kg_forge")):
		var cheap: Array = []
		for wid in V.WEAPON_ORDER:
			if int(V.WEAPONS[wid]["tier"]) <= 3:
				cheap.append(String(wid))
		_store(String(cheap.pick_random()), 1)
	var breads: Array = []
	var FDB2 = preload("res://food_db.gd")
	for fk in FDB2.ORDER:
		if FDB2.kind("food_" + String(fk)) == "bread":
			breads.append("food_" + String(fk))
	for i in range(_count_kind("kg_bakery") * 3):
		if not breads.is_empty():
			_store(String(breads.pick_random()), 1)
	_store("plank_tree_a", _count_kind("kg_sawmill") * 6)
	for i in range(_count_kind("kg_mine") * 3):
		_store(["stone_m", "stone_s", "ore_iron", "ore_copper", "coal"].pick_random(), 1)
	_store("linen", _count_kind("kg_tailor") * 2)
	# налоги и новые поселенцы
	var tax: int = int(float(Game.workers.size()) * 2.0 * hp)
	if tax > 0:
		Game.add_coins(tax)
	if hp > 0.7 and beds() > Game.workers.size() and Game.workers.size() < max_workers():
		var tex: String = String(SETTLERS.pick_random())
		hire(tex, String(NPC.person(tex)[0]), "")
		Game.toast.emit("В королевство пришла новая жительница!", load("res://art/icon_worker.png"))
	Game.kingdom["level"] = 1 + int((_sum("house") + _sum("fun") + _sum("work")) / 10) + _count_kind("kg_palace") * 3
	# несчастные уходят
	if hp < 0.35 and not Game.workers.is_empty() and randf() < 0.5:
		var who: String = String(Game.workers[Game.workers.size() - 1]["name"])
		fire(Game.workers.size() - 1)
		Game.toast.emit("%s ушла: негде спать и скучно..." % who, load("res://art/icon_worker.png"))


func _face(tex: String) -> Texture2D:
	var p: String = "res://art/%s.png" % tex
	if not ResourceLoader.exists(p):
		return load("res://art/icon_worker.png")
	var src: Texture2D = load(p)
	var at: AtlasTexture = AtlasTexture.new()
	at.atlas = src
	at.region = Rect2(0, 0, src.get_width() / 8.0, src.get_height() / 8.0 * 0.55)
	return at


# ------------------------------------------------------------------ окно O

func _info_text() -> String:
	var s: String = "%s.   Работниц: %d / %d.   Довольство: %d%%." % [Game.status_text(), Game.workers.size(), max_workers(), int(happiness() * 100.0)]
	if not Game.kingdom.is_empty():
		s += "\nКоролевство, уровень %d.   Кроватей: %d.   Развлечений: %d.   Мастерских: %d.   Постройки — на верстаке, вкладка с короной." % [int(Game.kingdom.get("level", 1)), beds(), fun(), _sum("work")]
	elif Game.workers.size() >= PROPOSE_AT and Game.kingdom_refused:
		s += "\nТы отказалась от короны. Если передумаешь — кнопка ниже."
	else:
		s += "\nНанимай жительниц в городах (нужна хорошая репутация и %d монет). Добыча складывается в сундук." % HIRE_FEE
	return s


func open_window() -> void:
	for c in win_list.get_children():
		c.queue_free()
	var bulk: HBoxContainer = HBoxContainer.new()
	bulk.add_theme_constant_override("separation", 6)
	win_list.add_child(bulk)
	v23.call("_label", bulk, "Всем:", "font_bold", 20, Color("f0d89a"))
	for k in ORDER_KEYS:
		var key: String = String(k)
		var b: Button = v23.call("_button", bulk, "", func() -> void:
			for i in range(Game.workers.size()):
				give_order(i, key)
			open_window(), 16)
		b.icon = load("res://art/%s.png" % String(ORDERS[key][1]))
		b.expand_icon = true
		b.custom_minimum_size = Vector2(52, 52)
		b.tooltip_text = String(ORDERS[key][0])
	for i in range(Game.workers.size()):
		var w: Dictionary = Game.workers[i]
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		win_list.add_child(row)
		var face: TextureRect = TextureRect.new()
		face.texture = _face(String(w["tex"]))
		face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		face.custom_minimum_size = Vector2(52, 52)
		row.add_child(face)
		var nl: Label = v23.call("_label", row, "%s — %s" % [String(w["name"]), String(ORDERS[String(w.get("order", "rest"))][0]).to_lower()], "font_body", 20, Color("e8dcc4"))
		nl.custom_minimum_size = Vector2(400, 0)
		for k2 in ORDER_KEYS:
			var key2: String = String(k2)
			var idx: int = i
			var b2: Button = v23.call("_button", row, "", func() -> void:
				give_order(idx, key2)
				open_window(), 14)
			b2.icon = load("res://art/%s.png" % String(ORDERS[key2][1]))
			b2.expand_icon = true
			b2.custom_minimum_size = Vector2(44, 44)
			b2.tooltip_text = String(ORDERS[key2][0])
			if String(w.get("order", "rest")) == key2:
				b2.modulate = Color(1.4, 1.3, 0.8)
	var foot: HBoxContainer = HBoxContainer.new()
	foot.add_theme_constant_override("separation", 12)
	win_list.add_child(foot)
	if Game.kingdom.is_empty() and Game.workers.size() >= PROPOSE_AT:
		v23.call("_button", foot, "Основать королевство", func() -> void:
			close_window()
			_choose_name(), 20)
	if not Game.kingdom.is_empty():
		v23.call("_button", foot, "Переименовать", func() -> void:
			close_window()
			ask_name(), 20)
		v23.call("_button", foot, "Распустить королевство", func() -> void:
			abdicate()
			open_window(), 20)
	v23.call("_button", foot, "Закрыть", close_window, 20)
	win_info.text = _info_text()
	win.visible = true
	Game.ui_open = true


func close_window() -> void:
	win.visible = false
	Game.ui_open = false


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var k: Key = (event as InputEventKey).physical_keycode
	if KB.is_key("kingdom", k) and not Game.SOLO:
		if win.visible:
			close_window()
		elif not Game.ui_open and not Game.busy:
			open_window()
		get_viewport().set_input_as_handled()
	elif k == KEY_ESCAPE and win.visible:
		close_window()
		get_viewport().set_input_as_handled()

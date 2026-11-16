extends Node
## v23: всё новое одним узлом-хозяином: статус, здоровье, навыки (K), разговоры, книги и приколы,
## выброшенные вещи, верстак (мебель, оружие, королевство), режим бога «Чудеса».
## Части: chest_ui.gd (сундук PoE), house23.gd (дом), farm23.gd (звери), kingdom23.gd (работники и королевство),
## dungeon23.gd (пещеры, монстры, бой, ад), sea23.gd (морские рыбы, акулы, говорящие рыбы).

const V = preload("res://v23_data.gd")
const IT = preload("res://items_db.gd")
const RDB = preload("res://recipes_db.gd")
const FD = preload("res://food_db.gd")
const INK: Color = Color("3a2718")
const GOLD: Color = Color("f0d89a")

var main: Node2D
var hud: CanvasLayer
var ui: CanvasLayer
var status_l: Label
var crown: TextureRect
var hearts: HBoxContainer
var skills_root: Control
var skills_box: VBoxContainer
var talk_root: Control
var talk_face: TextureRect
var talk_name: Label
var talk_text: Label
var talk_opts: VBoxContainer
var god_root: Control
var chest_ui: CanvasLayer
var farm: Node
var kingdom: Node
var dungeon: Node
var sea: Node
var t: float = 0.0


func setup(m: Node2D, h: CanvasLayer) -> void:
	main = m
	hud = h
	add_to_group("v23")
	chest_ui = CanvasLayer.new()
	chest_ui.set_script(load("res://chest_ui.gd"))
	add_child(chest_ui)
	chest_ui.call("setup", m, h)
	_build_ui()
	for part in [["farm", "res://farm23.gd"], ["kingdom", "res://kingdom23.gd"], ["dungeon", "res://dungeon23.gd"], ["sea", "res://sea23.gd"]]:
		var n: Node = Node.new()
		n.set_script(load(String(part[1])))
		n.name = String(part[0]).capitalize() + "23"
		add_child(n)
		n.call("setup", m, self)
		set(String(part[0]), n)
	# выброшенные вещи — на свои места
	for g in Game.ground:
		_spawn_ground(String(g[0]), int(g[1]), Vector2(float(g[2]), float(g[3])))
	Game.hp = minf(Game.hp, Game.hp_max()) if Game.hp > 0.0 else Game.hp_max()


# ------------------------------------------------------------------ интерфейс

func _font(k: String) -> Font:
	return hud.get(k)


func _label(parent: Node, text: String, fk: String, size: int, col: Color) -> Label:
	var l: Label = Label.new()
	l.text = text
	l.add_theme_font_override("font", _font(fk))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l


func _panel(parent: Node, r: Rect2) -> Control:
	var c: Control = Control.new()
	c.position = r.position
	c.size = r.size
	c.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(c)
	var bg: TextureRect = TextureRect.new()
	bg.texture = load("res://art/inv_bg.png")
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.size = r.size
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(bg)
	return c


func _button(parent: Node, text: String, cb: Callable, size: int = 20) -> Button:
	var b: Button = Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_override("font", _font("font_body"))
	b.add_theme_font_size_override("font_size", size)
	b.pressed.connect(func() -> void:
		Sound.play("ui_click", -6.0)
		cb.call())
	parent.add_child(b)
	return b


func _build_ui() -> void:
	ui = CanvasLayer.new()
	ui.layer = 21
	add_child(ui)
	# статус: кто ты в этом мире
	var top: HBoxContainer = HBoxContainer.new()
	top.position = Vector2(760, 6)
	top.size = Vector2(400, 34)
	top.alignment = BoxContainer.ALIGNMENT_CENTER
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(top)
	crown = TextureRect.new()
	crown.texture = load("res://art/icon_crown23.png")
	crown.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	crown.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	crown.custom_minimum_size = Vector2(36, 30)
	crown.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	crown.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(crown)
	status_l = _label(top, "", "font_bold", 22, Color("f4ecd8"))
	status_l.add_theme_color_override("font_outline_color", Color(0.1, 0.07, 0.05))
	status_l.add_theme_constant_override("outline_size", 7)
	hearts = HBoxContainer.new()
	hearts.position = Vector2(800, 44)
	hearts.size = Vector2(320, 30)
	hearts.alignment = BoxContainer.ALIGNMENT_CENTER
	hearts.add_theme_constant_override("separation", 2)
	hearts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(hearts)
	# навыки (K)
	skills_root = _panel(ui, Rect2(560, 120, 800, 760))
	skills_root.visible = false
	var st: Label = _label(skills_root, "Навыки", "font_title", 40, GOLD)
	st.position = Vector2(0, 26)
	st.size = Vector2(800, 50)
	st.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	skills_box = VBoxContainer.new()
	skills_box.position = Vector2(40, 96)
	skills_box.size = Vector2(720, 620)
	skills_box.add_theme_constant_override("separation", 6)
	skills_root.add_child(skills_box)
	# разговор (рыбы, работники, королевство)
	talk_root = _panel(ui, Rect2(380, 620, 1160, 420))
	talk_root.visible = false
	talk_face = TextureRect.new()
	talk_face.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	talk_face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	talk_face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	talk_face.position = Vector2(40, 60)
	talk_face.size = Vector2(200, 200)
	talk_root.add_child(talk_face)
	talk_name = _label(talk_root, "", "font_title", 34, GOLD)
	talk_name.position = Vector2(270, 34)
	talk_text = _label(talk_root, "", "font_body", 24, Color("e8dcc4"))
	talk_text.position = Vector2(270, 86)
	talk_text.size = Vector2(840, 150)
	talk_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	talk_opts = VBoxContainer.new()
	talk_opts.position = Vector2(270, 240)
	talk_opts.size = Vector2(840, 160)
	talk_root.add_child(talk_opts)
	# чудеса бога
	god_root = _panel(ui, Rect2(360, 80, 1200, 900))
	god_root.visible = false


func _process(delta: float) -> void:
	t += delta
	status_l.text = Game.status_text()
	crown.visible = not Game.kingdom.is_empty()
	# сердечки здоровья: видны в подземелье и пока не восстановилась
	var mx: float = Game.hp_max()
	var show: bool = Game.hp < mx - 0.5 or (dungeon != null and bool(dungeon.get("active")))
	hearts.visible = show
	if show:
		var want: int = int(ceil(mx / 20.0))
		while hearts.get_child_count() < want:
			var hr: TextureRect = TextureRect.new()
			hr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			hr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			hr.custom_minimum_size = Vector2(28, 26)
			hr.mouse_filter = Control.MOUSE_FILTER_IGNORE
			hearts.add_child(hr)
		while hearts.get_child_count() > want:
			var last: Node = hearts.get_child(hearts.get_child_count() - 1)
			hearts.remove_child(last)
			last.queue_free()
		for i in range(want):
			var full: bool = Game.hp >= float(i) * 20.0 + 10.0
			(hearts.get_child(i) as TextureRect).texture = load("res://art/hp_heart.png" if full else "res://art/hp_heart_empty.png")
	# вне подземелья здоровье само понемногу возвращается
	if Game.hp < mx and not (dungeon != null and bool(dungeon.get("active"))):
		Game.hp = minf(mx, Game.hp + delta * 2.0)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var k: Key = (event as InputEventKey).physical_keycode
	if KB.is_key("skills", k):
		if skills_root.visible:
			skills_root.visible = false
			Game.ui_open = false
		elif not Game.ui_open and not Game.busy:
			open_skills()
		get_viewport().set_input_as_handled()
	elif k == KEY_ESCAPE and (skills_root.visible or god_root.visible):
		skills_root.visible = false
		god_root.visible = false
		Game.ui_open = false
		get_viewport().set_input_as_handled()
	elif talk_root.visible and k >= KEY_1 and k <= KEY_9:
		var i: int = int(k - KEY_1)
		if i < talk_opts.get_child_count():
			(talk_opts.get_child(i) as Button).pressed.emit()
		get_viewport().set_input_as_handled()


func open_skills() -> void:
	for c in skills_box.get_children():
		c.queue_free()
	for key in Game.SKILL_ORDER:
		if Game.SOLO and key in ["combat", "lead"]:
			continue     # v29: драки и работниц пока нет
		var sk: Array = Game.SKILLS[key]
		var lv: int = Game.skill_level(String(key))
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		skills_box.add_child(row)
		var nm: Label = _label(row, String(sk[0]), "font_bold", 22, GOLD)
		nm.custom_minimum_size = Vector2(220, 0)
		var lvl: Label = _label(row, "%d / %d" % [lv, Game.SKILL_MAX], "font_body", 22, Color("e8dcc4"))
		lvl.custom_minimum_size = Vector2(80, 0)
		var bar: ProgressBar = ProgressBar.new()
		bar.custom_minimum_size = Vector2(220, 22)
		bar.show_percentage = false
		var xp: float = float(Game.skills.get(key, 0.0))
		var a: float = Game.skill_need(lv)
		var b: float = Game.skill_need(lv + 1)
		bar.value = 100.0 if lv >= Game.SKILL_MAX else (xp - a) / maxf(1.0, b - a) * 100.0
		row.add_child(bar)
		var bonus: String = {"herb": "двойная трава +%d%%", "shroom": "двойной гриб +%d%%", "mine": "сила +%d к весу", "chop": "сила +%d к весу",
			"fish": "клюёт проще +%d%%", "tame": "звери идут охотнее +%d%%", "brew": "два зелья +%d%%", "cook": "голод медленнее %d%%",
			"craft": "двойное ремесло +%d%%", "combat": "сила удара +%d%%", "trade": "дороже продаёшь +%d%%", "lead": "работники +%d%%"}[key]
		_label(row, bonus % int(absf(float(sk[2]) * float(lv))), "font_body", 18, Color("8ea8ff"))
	skills_root.visible = true
	Game.ui_open = true
	Sound.play("page", -8.0)


## Разговор: портрет, имя, текст и до 9 ответов [[надпись, Callable], ...]. Пустой список — «Пока!»
func talk(face: Texture2D, who: String, text: String, opts: Array = []) -> void:
	talk_face.texture = face
	talk_name.text = who
	talk_text.text = text
	for c in talk_opts.get_children():
		talk_opts.remove_child(c)
		c.queue_free()
	if opts.is_empty():
		opts = [["Пока!", func() -> void: pass]]
	for i in range(opts.size()):
		var o: Array = opts[i]
		var cb: Callable = o[1]
		var b: Button = Button.new()
		b.text = "%d. %s" % [i + 1, String(o[0])]
		b.flat = true
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_override("font", _font("font_body"))
		b.add_theme_font_size_override("font_size", 22)
		b.add_theme_color_override("font_color", Color("c8b898"))
		b.add_theme_color_override("font_hover_color", GOLD)
		b.pressed.connect(func() -> void:
			Sound.play("ui_click", -6.0)
			talk_root.visible = false
			Game.ui_open = false
			cb.call())
		talk_opts.add_child(b)
	talk_root.visible = true
	Game.ui_open = true
	Sound.play("page", -8.0)


func talking() -> bool:
	return talk_root.visible


# ------------------------------------------------------------------ книги, приколы, продукты (ПКМ в сумке)

func use_item(id: String) -> bool:
	# v24: длинную ветку ломаешь руками на короткие палки
	if id == "branch_long":
		if not Game.take_item(id):
			return false
		Game.add_item("stick", 3)
		Sound.play("branch_snap", -4.0, 0.15)
		get_tree().call_group("player", "react", "pout", 0.6)
		return true
	if V.BOOKS.has(id):
		read_book(id)
		return true
	if V.JOKES.has(id):
		Game.toast.emit(String(V.JOKES[id]["desc"]), IT.icon(id))
		get_tree().call_group("player", "react", ["happy", "smile", "surprised"].pick_random(), 1.6)
		Sound.play(["squeak", "quack", "magic", "ui_select"].pick_random(), -4.0, 0.3)
		Game.fx.emit((main.get("player") as Node2D).global_position + Vector2(0, -50), "sparkle")
		return true
	if V.PRODUCTS.has(id) and id in ["egg", "egg_duck", "egg_goose", "milk", "milk_goat", "milk_rainbow", "hp_potion"]:
		if not Game.take_item(id):
			return false
		if id.begins_with("milk"):
			Game.drink(0.5)
			Game.eat(0.15)
		else:
			Game.eat(0.35)
		if id == "hp_potion" or id == "milk_rainbow":
			Game.hp = Game.hp_max()
		get_tree().call_group("player", "react", "happy", 1.2)
		return true
	return false


func read_book(id: String) -> void:
	var b: Dictionary = V.BOOKS[id]
	if not Game.take_item(id):
		return
	Game.books_read[id] = int(Game.books_read.get(id, 0)) + 1
	Sound.play("page", -2.0)
	var msg: String = ""
	match String(b["kind"]):
		"magic":
			var sk: String = String(b["skill"])
			Game.skill_xp(sk, 160.0)
			msg = "Прочитала «%s». Навык «%s» вырос!" % [String(b["name"]), String(Game.SKILLS[sk][0])]
		"recipe":
			var unknown: Array = []
			for pid in RDB.PRODUCTS.keys():
				if not Game.known_recipes.has(pid) and (RDB.PRODUCTS[pid] as Dictionary).has("ex"):
					unknown.append(String(pid))
			if unknown.is_empty():
				msg = "Все рецепты из этой книги ты уже знаешь."
			else:
				var pid2: String = String(unknown.pick_random())
				var ex: Array = RDB.PRODUCTS[pid2]["ex"]
				var ings: Array = []
				for ig in (ex[2] as Array):
					ings.append({"id": String(ig[0]), "procs": (ig[1] as Array).duplicate()})
				Game.known_recipes[pid2] = {"base": String(ex[0]), "temp": String(ex[1]), "ings": ings}
				Game.discovered[pid2] = true
				msg = "Новый рецепт зелья: %s!" % RDB.name(pid2)
		"food":
			var opts: Array = []
			for r in FD.RECIPES:
				var res: String = "food_" + String(r[1])
				if not Game.discovered.has(res):
					opts.append(r)
			if opts.is_empty():
				msg = "Ты и так знаешь все блюда из этой книги."
			else:
				var r2: Array = opts.pick_random()
				var res2: String = "food_" + String(r2[1])
				Game.discovered[res2] = true
				var parts: Array = []
				for ing in (r2[0] as Array):
					parts.append(IT.name("food_" + String(ing)) if FD.is_food("food_" + String(ing)) else IT.name(String(ing)))
				Game.misc_notes.append({"cat": "food", "text": "Рецепт: %s → %s" % [" + ".join(parts), IT.name(res2)]})
				msg = "Новый рецепт блюда: %s!" % IT.name(res2)
		"lore":
			Game.chron("Прочитала старую летопись — теперь знаю, кто построил подземелья.", "lore")
			Game.skill_xp("lead", 40.0)
			msg = "Старая летопись: подземелья построили гномы-шутники, чтобы прятать от скуки свои приколы."
		"spell":
			var sp: String = String(b["skill"])
			Game.spells[sp] = true
			match sp:
				"light":
					Game.perm["light"] = float(Game.perm.get("light", 0.0)) + 1.0
				"speed":
					Game.perm["speed"] = float(Game.perm.get("speed", 0.0)) + 8.0
				"hp":
					Game.perm["hp"] = float(Game.perm.get("hp", 0.0)) + 30.0
			msg = "Выучено заклинание: %s. Это навсегда!" % String(b["name"]).replace("Заклинание: ", "")
	Game.toast.emit(msg, IT.icon(id))
	get_tree().call_group("player", "react", "surprised", 1.4)


# ------------------------------------------------------------------ выбросить на землю

func drop_ground(id: String, n: int) -> bool:
	n = mini(n, Game.get_count(id))
	if n <= 0:
		return false
	var pl: Node2D = main.get("player")
	var at: Vector2 = pl.global_position + Vector2(randf_range(-16, 16), randf_range(6, 14))
	if bool(main.call("is_blocked", at)):
		at = pl.global_position + Vector2(0, 2)
	Game.inventory[id] = Game.get_count(id) - n
	var hi: int = Game.hotbar.find(id)
	if hi >= 0 and Game.get_count(id) <= 0:
		Game.hotbar[hi] = ""
	Game.ground.append([id, n, at.x, at.y])
	_spawn_ground(id, n, at)
	Game.inventory_changed.emit()
	Sound.play("pickup", -10.0, 0.2)
	return true


func _spawn_ground(id: String, n: int, at: Vector2) -> void:
	var g: Node2D = Node2D.new()
	g.set_script(load("res://ground_item.gd"))
	(main.get("objects") as Node).add_child(g)
	g.call("setup", id, n, at)


# ------------------------------------------------------------------ верстак: мебель, оружие, королевство

func bench_tabs() -> Array:
	var out: Array = ["furn", "wpn"]
	if not Game.SOLO and (not Game.kingdom.is_empty() or Game.god_mode):
		out.append("kingdom")
	return out


const STYLE_NEED: Dictionary = {
	"straw": {"straw": 6}, "rough": {}, "simple": {"nail": 2}, "cozy": {"linen": 1, "nail": 2}, "cat": {"cat_fur": 1, "cotton_cloth": 1},
	"japan": {"paper": 2}, "dwarf": {"bar_copper": 1, "stone_block": 1}, "elven": {"fairy_dust": 1, "linen": 1}, "sea": {"shell": 2, "driftwood": 1},
	"gothic": {"cloth_black": 1, "sheet_iron": 1}, "mage": {"mana_dust": 2, "crystal_shard": 1}, "royal": {"bar_gold": 2, "cloth_red": 2},
	"village": {"nail": 1}, "special": {"nail": 4, "glass": 1},
}
const MAT_NEED: Dictionary = {
	"wood": "@plank", "bone": "antler_shed", "copper": "bar_copper", "bronze": "bar_bronze", "iron": "iron_bar", "steel": "bar_steel",
	"silver": "bar_silver", "gold": "bar_gold", "crystal": "crystal_shard", "frost": "bar_frost", "ember": "bar_ember", "verdant": "bar_verdant",
	"moonsilver": "bar_moonsilver", "void": "bar_void", "star": "bar_starsteel", "candy": "honey",
}


static func furn_need(id: String) -> Dictionary:
	var d: Dictionary = V.FURN[id]
	var out: Dictionary = {}
	var cat: String = String(d["cat"])
	var planks: int = {"bed": 8, "table": 6, "chair": 3, "wardrobe": 8, "bookcase": 8, "lamp": 2, "rug": 0, "dresser": 6, "plant": 1, "cabinet": 3}.get(cat, 4)
	if String(d["style"]) != "straw" and planks > 0:
		out["@plank"] = planks
	if cat == "rug":
		out["@yarn"] = 3
	if cat == "plant":
		out["clay"] = 2
	for k in (STYLE_NEED.get(String(d["style"]), {}) as Dictionary).keys():
		out[k] = int(STYLE_NEED[String(d["style"])][k])
	return out


static func wpn_need(id: String) -> Dictionary:
	var w: Dictionary = V.WEAPONS[id]
	var key: String = String(MAT_NEED.get(String(w["mat"]), "@plank"))
	var n: int = maxi(1, int(round(float(w["w"]) / 1.2)))
	var out: Dictionary = {key: n}
	if key != "@plank":
		out["@plank"] = 1
	if String(w["type"]) == "pillow":
		out = {"@yarn": 2, key: 1}
	return out


func bench_cards(tab: String) -> Array:
	var hs: Node = get_tree().get_first_node_in_group("homestead")
	var out: Array = []
	match tab:
		"furn":
			for fid in V.FURN.keys():
				var need: Dictionary = furn_need(String(fid))
				out.append([IT.icon("furn:" + String(fid)), hs.call("_need_costs", need), String(V.FURN[fid]["name"]) + "\n" + String(hs.call("_need_text", need)), "v23:furn:" + String(fid), not bool(hs.call("_can_pay", need))])
		"wpn":
			var rn: Dictionary = {"stick": 2, "twine": 1}
			out.append([IT.icon("rod"), hs.call("_need_costs", rn), "Удочка\n" + String(hs.call("_need_text", rn)), "v23:rod", not bool(hs.call("_can_pay", rn))])
			# v29: садовые инструменты для заднего дворика
			for tl in TOOLS29.keys():
				var tn: Dictionary = TOOLS29[tl]
				out.append([IT.icon(String(tl)), hs.call("_need_costs", tn), IT.name(String(tl)) + "\n" + String(hs.call("_need_text", tn)), "v23:" + String(tl), not bool(hs.call("_can_pay", tn))])
			for wid in ([] if Game.SOLO else V.WEAPON_ORDER):     # v29: оружия в одиночной игре нет
				if String(V.WEAPONS[wid]["mat"]) == "legend":
					continue      # легендарное — только из подземелий
				var need2: Dictionary = wpn_need(String(wid))
				out.append([IT.icon(String(wid)), hs.call("_need_costs", need2), "%s (удар %d)\n%s" % [IT.name(String(wid)), int(V.WEAPONS[wid]["atk"]), String(hs.call("_need_text", need2))], "v23:wpn:" + String(wid), not bool(hs.call("_can_pay", need2))])
		"kingdom":
			for kk in IT.KBUILD.keys():
				var need3: Dictionary = IT.build_need(String(kk))
				var kb: Array = IT.KBUILD[kk]
				var what: String = {"house": "спят %d", "fun": "радость +%d", "work": "выработка %d", "palace": "уровень королевства +%d", "shop": "магазин, слава +%d"}[String(kb[7])] % int(kb[8])
				out.append([IT.icon("kit:" + String(kk)), hs.call("_need_costs", need3), "%s (%s)\n%s" % [String(kb[0]), what, String(hs.call("_need_text", need3))], "make:" + String(kk), not bool(hs.call("_can_pay", need3))])
	return out


const TOOLS29: Dictionary = {"hoe": {"stick": 2, "stone_s": 2}, "watering_can": {"stick": 1, "clay": 3}}


func bench_craft(key: String) -> bool:
	var hs: Node = get_tree().get_first_node_in_group("homestead")
	var need: Dictionary = {}
	var item: String = ""
	if key == "rod":
		need = {"stick": 2, "twine": 1}
		item = "rod"
	elif TOOLS29.has(key):
		need = TOOLS29[key]
		item = key
	elif key.begins_with("furn:"):
		need = furn_need(key.substr(5))
		item = key
	elif key.begins_with("wpn:"):
		need = wpn_need(key.substr(4))
		item = key.substr(4)
	if item == "" or not bool(hs.call("_pay", need)):
		return false
	Game.add_item(item)
	Game.skill_xp("craft", 4.0)
	return true


# ------------------------------------------------------------------ режим бога: «Чудеса»

func open_god() -> void:
	for c in god_root.get_children():
		if c is TextureRect:
			continue
		c.queue_free()
	var ttl: Label = _label(god_root, "Чудеса бога", "font_title", 40, GOLD)
	ttl.position = Vector2(0, 24)
	ttl.size = Vector2(1200, 50)
	ttl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var sc: ScrollContainer = ScrollContainer.new()
	sc.position = Vector2(40, 90)
	sc.size = Vector2(1120, 780)
	god_root.add_child(sc)
	var grid: GridContainer = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 8)
	sc.add_child(grid)
	var acts: Array = [
		["Все навыки на максимум", func() -> void:
			for k in Game.SKILL_ORDER:
				Game.skills[k] = Game.skill_need(Game.SKILL_MAX)
			Game.toast.emit("Все навыки — 10!", load("res://art/fx_heart.png"))],
		["Здоровье полностью", func() -> void: Game.hp = Game.hp_max()],
		["Вся мебель (по 1)", func() -> void:
			for fid in V.FURN.keys():
				Game.inventory["furn:" + String(fid)] = Game.get_count("furn:" + String(fid)) + 1
			Game.inventory_changed.emit()],
		["Всё оружие (по 1)", func() -> void:
			for wid in V.WEAPON_ORDER:
				Game.inventory[String(wid)] = Game.get_count(String(wid)) + 1
			Game.inventory_changed.emit()],
		["Легендарное оружие", func() -> void:
			for wid in V.WEAPON_ORDER:
				if String(V.WEAPONS[wid]["mat"]) == "legend":
					Game.inventory[String(wid)] = Game.get_count(String(wid)) + 1
			Game.inventory_changed.emit()],
		["Все книги и приколы", func() -> void:
			for bid in V.BOOKS.keys():
				Game.inventory[String(bid)] = Game.get_count(String(bid)) + 1
			for jid in V.JOKES.keys():
				Game.inventory[String(jid)] = Game.get_count(String(jid)) + 1
			Game.inventory_changed.emit()],
		["Комнату справа", func() -> void:
			var h: Node = main.get_node("House23")
			h.call("build_room", int(h.call("max_slot")) + 1)],
		["Комнату слева", func() -> void:
			var h2: Node = main.get_node("House23")
			h2.call("build_room", int(h2.call("min_slot")) - 1)],
		["Нанять 10 работников", func() -> void: kingdom.call("god_hire", 10)],
		["Основать королевство", func() -> void: kingdom.call("found", "")],
		["Распустить королевство", func() -> void: kingdom.call("abdicate")],
		["Предложение о королевстве", func() -> void: kingdom.call("propose")],
		["Все постройки королевства", func() -> void:
			for kk in IT.KBUILD.keys():
				Game.inventory["kit:" + String(kk)] = Game.get_count("kit:" + String(kk)) + 1
			Game.inventory_changed.emit()],
		["Призвать домашних зверей", func() -> void: farm.call("god_spawn_farm")],
		["Зверей сразу в загон", func() -> void: farm.call("god_fill_pens")],
		["Потомство за ночь", func() -> void: farm.call("night_breed", true)],
		["Ближайшее подземелье", func() -> void: dungeon.call("god_enter", "")],
		["Портал в ад (сразу в пекло)", func() -> void: dungeon.call("god_enter", "hell")],
		["Где пещера с порталом?", func() -> void: dungeon.call("god_hell_where")],
		["Призвать монстра", func() -> void: dungeon.call("god_monster", "")],
		["Призвать босса", func() -> void: dungeon.call("god_monster", "slime_king")],
		["Призвать Дьявола", func() -> void: dungeon.call("god_monster", "devil")],
		["Говорящая рыба", func() -> void: sea.call("god_talk", "")],
		["Золотая рыбка", func() -> void: sea.call("god_talk", "sea_golden")],
		["Все морские рыбы", func() -> void:
			for fid2 in V.SEA_ORDER:
				Game.inventory[String(fid2)] = Game.get_count(String(fid2)) + 1
			Game.inventory_changed.emit()],
		["Удочка", func() -> void: Game.add_item("rod")],
		["Открыть страницу зверей", func() -> void: farm.call("god_unlock_book")],
		["Продукты ферм (по 5)", func() -> void:
			for pid in V.PRODUCTS.keys():
				Game.inventory[String(pid)] = Game.get_count(String(pid)) + 5
			Game.inventory_changed.emit()],
	]
	for a in acts:
		var cb: Callable = a[1]
		var b: Button = _button(grid, String(a[0]), func() -> void:
			cb.call()
			Sound.play("magic", -6.0), 20)
		b.custom_minimum_size = Vector2(360, 44)
	var close_b: Button = _button(god_root, "Закрыть", func() -> void:
		god_root.visible = false
		Game.ui_open = false, 22)
	close_b.position = Vector2(540, 840)
	god_root.visible = true
	Game.ui_open = true

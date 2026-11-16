extends Node
## v28/v31: обучение у гида — цепочка заданий от Миры.
## 1 «Дровосек» (если топора нет — сначала палки и камушки с земли, топор руками), 2 «Верстак», 3 «Травы», 4 «Зелье», 5 «Продажа», 99 — готово.
## Слева на экране список шагов (текущий — жёлтый со стрелкой, сделанные — зелёные) и подсказка с подробным описанием.
## Дерево / палка / камушек, которые нужны сейчас, подсвечиваются стрелкой. Состояние — Game.tut_step.
## Ветки и камушки иногда лежат на земле у дома (раз в день, пока их мало), чтобы топор можно было сделать без рубки.

const IT = preload("res://items_db.gd")
const TUT = preload("res://tutor27.gd")
const LOGS_NEED: int = 6
const HERBS_NEED: int = 3
const REWARD: int = 25
const LINES: int = 4

var main: Node2D
var home: Node
var hud: CanvasLayer
var root: Control
var title_l: Label
var hint_l: Label
var lines: Array = []          # Label
var arrow: Polygon2D
var t: float = 0.0
var tick: float = 0.0
var target: Sprite2D = null
var last_target: Sprite2D = null
var gtarget: Node2D = null     # палка/камушек на земле, на которые показывает стрелка


func setup(m: Node2D, h: Node, ui: CanvasLayer, hd: CanvasLayer) -> void:
	main = m
	home = h
	hud = hd
	add_to_group("tutq28")
	root = Control.new()
	root.position = Vector2(28, 262)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.visible = false
	ui.add_child(root)
	hud.call("panel", root, Vector2.ZERO, Vector2(700, 64 + LINES * 44 + 108))
	title_l = hud.call("label", root, "", hud.get("font_bold"), 30, Color("5a3414"), Vector2(22, 12))
	for i in range(LINES):
		var l: Label = hud.call("label", root, "", hud.get("font_body"), 26, Color("5a3414"), Vector2(22, 62 + i * 44))
		lines.append(l)
	hint_l = hud.call("label", root, "", hud.get("font_body"), 21, Color("7a5a30"), Vector2(22, 62 + LINES * 44 + 6))
	hint_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_l.custom_minimum_size = Vector2(656, 96)
	hint_l.size = Vector2(656, 96)
	arrow = Polygon2D.new()
	arrow.polygon = PackedVector2Array([Vector2(-11, -16), Vector2(11, -16), Vector2(0, 2)])
	arrow.color = Color("ffd84a")
	arrow.z_index = 90
	arrow.visible = false
	(main.get("objects") as Node).add_child(arrow)
	Game.day_changed.connect(_on_day)
	get_tree().create_timer(3.0).timeout.connect(func() -> void: scatter(false))


func _logs() -> int:
	return int((home.call("pool") as Dictionary).get("log", 0))


func _has_axe() -> bool:
	return Game.get_count("axe") > 0 or Game.worn("main1") == "axe" or Game.worn("main2") == "axe"


func _noaxe() -> bool:
	return int(Game.counters.get("tut_noaxe", 0)) == 1


## Список шагов текущего задания: [текст, сделано]
func _steps() -> Array:
	var k_craft: String = KB.key_name("craft")
	var k_use: String = KB.key_name("interact")
	var st: int = Game.tut_step
	if st == 1:
		var out: Array = []
		if _noaxe():
			var sticks: int = Game.get_count("stick")
			var stones: int = Game.get_count("stone_s")
			out.append(["Подбери с земли (%s) палки %d/2 и камушки %d/2" % [k_use, mini(sticks, 2), mini(stones, 2)], _has_axe() or (sticks >= 2 and stones >= 2)])
			out.append(["Сделай топор (%s): 2 палки и 2 камушка" % k_craft, _has_axe()])
		out.append(["Возьми топор в руку (клавиши 1–9 или %s)" % KB.key_name("inventory"), String(home.call("in_hand")) == "axe"])
		out.append(["Руби деревья мышью: %d/%d брёвен" % [mini(_logs(), LOGS_NEED), LOGS_NEED], _logs() >= LOGS_NEED])
		return out
	if st == 2:
		return [
			["Сделай верстак (%s): %d брёвен" % [k_craft, LOGS_NEED], Game.get_count("kit:workbench") > 0 or bool(home.call("has_built", "workbench"))],
			["Возьми верстак в руку и поставь на участке", bool(home.call("has_built", "workbench"))],
		]
	if st == 3:
		var got: int = int(Game.counters.get("herbs", 0)) - int(Game.counters.get("tut_h0", 0))
		return [["Собери травы (%s у растения): %d/%d" % [k_use, clampi(got, 0, HERBS_NEED), HERBS_NEED], got >= HERBS_NEED]]
	if st == 4:
		return [
			["Налей воды в котёл и брось в него травы", Game.known_recipes.size() > int(Game.counters.get("tut_r0", 0))],
			["Свари любое зелье — оно запишется в книгу (%s)" % KB.key_name("book"), Game.known_recipes.size() > int(Game.counters.get("tut_r0", 0))],
		]
	return [["Отдай зелье жителю по заказу или продай торговцу", int(Game.counters.get("sold", 0)) > int(Game.counters.get("tut_s0", 0)) or Game.orders_done > int(Game.counters.get("tut_o0", 0))]]


func _process(delta: float) -> void:
	t += delta
	tick -= delta
	if tick <= 0.0:
		tick = 0.2
		_update()
	_pulse()


func _update() -> void:
	var step: int = Game.tut_step
	var active: bool = step >= 1 and step <= 5
	root.visible = active and not bool(main.get("inside"))
	target = null
	gtarget = null
	if not active:
		return
	var st: Array = _steps()
	var all_done: bool = true
	var cur: int = -1
	for i in range(st.size()):
		if not bool(st[i][1]) and cur < 0:
			cur = i
		all_done = all_done and bool(st[i][1])
	title_l.text = "Задание: " + String(["", "Дровосек", "Верстак", "Травы", "Зелье", "Продажа"][step])
	hint_l.text = TUT.hint(step, _noaxe())
	for i in range(lines.size()):
		var l: Label = lines[i]
		if i >= st.size():
			l.text = ""
			continue
		var done: bool = bool(st[i][1])
		l.text = ("✓ " if done else ("▶ " if i == cur else "· ")) + String(st[i][0])
		l.add_theme_color_override("font_color", Color("3f8a2a") if done else (Color("c47a00") if i == cur else Color("8a7a5c")))
	if all_done:
		_next(step)
		return
	if step == 1:
		if _noaxe() and cur == 0:
			_ensure_materials()
			gtarget = _nearest_needed()
		elif cur == st.size() - 1:
			target = home.call("_nearest_tree", 1400.0) as Sprite2D


func _next(step: int) -> void:
	Sound.play("coin", -6.0)
	if step == 1:
		Game.tut_step = 2
		Game.toast.emit("Брёвна есть! Теперь верстак", IT.icon("log"))
	elif step == 2:
		Game.tut_step = 3
		Game.counters["tut_h0"] = int(Game.counters.get("herbs", 0))
		Game.coins += 10
		Game.toast.emit("Верстак стоит! Теперь травы (+10 монет)", IT.icon("log"))
	elif step == 3:
		Game.tut_step = 4
		Game.counters["tut_r0"] = Game.known_recipes.size()
		Game.toast.emit("Травы собраны! Теперь зелье", load("res://art/coin.png"))
	elif step == 4:
		Game.tut_step = 5
		Game.counters["tut_s0"] = int(Game.counters.get("sold", 0))
		Game.counters["tut_o0"] = Game.orders_done
		Game.toast.emit("Первое зелье сварено! Осталось продать", load("res://art/coin.png"))
	else:
		Game.tut_step = 99
		Game.coins += REWARD
		Game.toast.emit("Обучение пройдено! +%d монет" % REWARD, load("res://art/coin.png"))
		Game.chron("Мира научила рубить дрова, собирать травы, варить зелья и продавать их.", "quest")
		root.visible = false


# ---------------------------------------------------------------- ветки и камушки на земле

func _on_day() -> void:
	scatter(true)


func _lying(id: String) -> int:
	var n: int = 0
	for g in Game.ground:
		if String(g[0]) == id:
			n += int(g[1])
	return n


## Положить на землю у дома палку или камушек. Возвращает true, если положено.
func _drop_one(id: String) -> bool:
	var v23: Node = get_tree().get_first_node_in_group("v23")
	if v23 == null:
		return false
	var centre: Vector2 = Game.home_pos
	for _try in range(12):
		var a: float = randf() * TAU
		var at: Vector2 = centre + Vector2(cos(a), sin(a) * 0.7) * randf_range(180.0, 620.0)
		if bool(main.call("is_blocked", at)):
			continue
		Game.ground.append([id, 1, at.x, at.y])
		v23.call("_spawn_ground", id, 1, at)
		return true
	return false


## Раз в день (и при старте), пока на земле мало: иногда ложатся 1–2 ветки и камушек.
## by_day = false — при запуске игры: докладываем только если совсем пусто.
func scatter(by_day: bool) -> void:
	if bool(main.get("inside")):
		return
	var need_stick: bool = _lying("stick") < (4 if by_day else 2)
	if need_stick and (not by_day or randf() < 0.7):
		for i in range(randi_range(1, 2)):
			_drop_one("stick")
	if _lying("stone_s") < 2 and (not by_day or randf() < 0.4):
		_drop_one("stone_s")


## Обучение без топора: гарантируем 2 палки и 2 камушка где-то рядом
func _ensure_materials() -> void:
	for pair in [["stick", 2], ["stone_s", 2]]:
		var id: String = String(pair[0])
		var need: int = int(pair[1]) - Game.get_count(id)
		var short: int = need - _lying(id)
		for i in range(maxi(short, 0)):
			_drop_one(id)


func _nearest_needed() -> Node2D:
	var pl: Node2D = main.get("player") as Node2D
	if pl == null:
		return null
	var best: Node2D = null
	var bd: float = 1e9
	for gi in get_tree().get_nodes_in_group("ground_items"):
		var gid: String = String(gi.get("id"))
		var want: bool = (gid == "stick" and Game.get_count("stick") < 2) or (gid == "stone_s" and Game.get_count("stone_s") < 2)
		if not want:
			continue
		var d: float = (gi as Node2D).global_position.distance_to(pl.global_position)
		if d < bd:
			bd = d
			best = gi as Node2D
	return best


## Пульсация: стрелка над целью и ячейка топора на панели
func _pulse() -> void:
	var on: bool = Game.tut_step == 1
	var pl: Node2D = main.get("player") as Node2D
	if last_target != target:
		if last_target != null and is_instance_valid(last_target):
			last_target.self_modulate = Color.WHITE
		last_target = target
	if target != null and is_instance_valid(target) and on and pl != null:
		var top: float = target.global_position.y - float(target.texture.get_height()) * absf(target.scale.y) - 18.0
		arrow.visible = true
		arrow.global_position = Vector2(target.global_position.x, top + sin(t * 6.0) * 6.0)
		target.self_modulate = Color(1.12, 1.12, 1.0).lerp(Color(1.3, 1.25, 0.9), 0.5 + 0.5 * sin(t * 6.0))
	elif gtarget != null and is_instance_valid(gtarget) and on:
		arrow.visible = true
		arrow.global_position = gtarget.global_position + Vector2(0, -30.0 + sin(t * 6.0) * 6.0)
	else:
		arrow.visible = false
	var hb: Control = home.get("hot_box") as Control
	var ai: int = Game.hotbar.find("axe")
	if on and hb != null and ai >= 0 and ai < hb.get_child_count() and String(home.call("in_hand")) != "axe":
		(hb.get_child(ai) as Control).modulate = Color(1.3, 1.25, 0.8).lerp(Color.WHITE, 0.5 + 0.5 * sin(t * 6.0))

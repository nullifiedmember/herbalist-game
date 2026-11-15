extends Node
## v28: обучение у гида — как задание. Мира даёт «Дровосек»: топор → в руку → 6 брёвен → верстак → поставить.
## Слева на экране список шагов: текущий — жёлтый со стрелкой, сделанные — зелёные с галочкой.
## Дерево, которое надо рубить, и ячейка с топором подсвечиваются. Состояние — Game.tut_step (0 не взято, 1, 2, 99 готово).

const IT = preload("res://items_db.gd")
const LOGS_NEED: int = 6
const REWARD: int = 25

var main: Node2D
var home: Node
var hud: CanvasLayer
var root: Control
var title_l: Label
var lines: Array = []          # Label
var arrow: Polygon2D
var t: float = 0.0
var tick: float = 0.0
var target: Sprite2D = null
var last_target: Sprite2D = null


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
	hud.call("panel", root, Vector2.ZERO, Vector2(700, 64 + 3 * 44))
	title_l = hud.call("label", root, "", hud.get("font_bold"), 30, Color("5a3414"), Vector2(22, 12))
	for i in range(3):
		var l: Label = hud.call("label", root, "", hud.get("font_body"), 26, Color("5a3414"), Vector2(22, 62 + i * 44))
		lines.append(l)
	arrow = Polygon2D.new()
	arrow.polygon = PackedVector2Array([Vector2(-11, -16), Vector2(11, -16), Vector2(0, 2)])
	arrow.color = Color("ffd84a")
	arrow.z_index = 90
	arrow.visible = false
	(main.get("objects") as Node).add_child(arrow)


func _logs() -> int:
	return int((home.call("pool") as Dictionary).get("log", 0))


func _has_axe() -> bool:
	return Game.get_count("axe") > 0 or Game.worn("main1") == "axe" or Game.worn("main2") == "axe"


## Список шагов текущего задания: [текст, сделано]
func _steps() -> Array:
	var k_craft: String = KB.key_name("craft")
	if Game.tut_step == 1:
		return [
			["Сделай топор (%s): 2 палки и 2 камушка" % k_craft, _has_axe()],
			["Возьми топор в руку (клавиши 1–9 или %s)" % KB.key_name("inventory"), String(home.call("in_hand")) == "axe"],
			["Руби деревья мышью: %d/%d брёвен" % [mini(_logs(), LOGS_NEED), LOGS_NEED], _logs() >= LOGS_NEED],
		]
	return [
		["Сделай верстак (%s): %d брёвен" % [k_craft, LOGS_NEED], Game.get_count("kit:workbench") > 0 or bool(home.call("has_built", "workbench"))],
		["Возьми верстак в руку и поставь на участке", bool(home.call("has_built", "workbench"))],
	]


func _process(delta: float) -> void:
	t += delta
	tick -= delta
	if tick <= 0.0:
		tick = 0.2
		_update()
	_pulse()


func _update() -> void:
	var step: int = Game.tut_step
	root.visible = (step == 1 or step == 2) and not bool(main.get("inside"))
	target = null
	if step != 1 and step != 2:
		return
	var st: Array = _steps()
	var all_done: bool = true
	var cur: int = -1
	for i in range(st.size()):
		if not bool(st[i][1]) and cur < 0:
			cur = i
		all_done = all_done and bool(st[i][1])
	title_l.text = "Задание: Дровосек" if step == 1 else "Задание: Верстак"
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
	# что подсвечивать: на шаге «руби» — дерево
	if step == 1 and cur == 2:
		target = home.call("_nearest_tree", 1400.0) as Sprite2D


func _next(step: int) -> void:
	Sound.play("coin", -6.0)
	if step == 1:
		Game.tut_step = 2
		Game.toast.emit("Брёвна есть! Теперь верстак", IT.icon("log"))
	else:
		Game.tut_step = 99
		Game.coins += REWARD
		Game.toast.emit("Обучение пройдено! +%d монет" % REWARD, load("res://art/coin.png"))
		Game.chron("Мира научила рубить дрова и ставить верстак.", "quest")
		root.visible = false


## Пульсация: стрелка над деревом и ячейка топора на панели
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
	else:
		arrow.visible = false
	var hb: Control = home.get("hot_box") as Control
	var ai: int = Game.hotbar.find("axe")
	if on and hb != null and ai >= 0 and ai < hb.get_child_count() and String(home.call("in_hand")) != "axe":
		(hb.get_child(ai) as Control).modulate = Color(1.3, 1.25, 0.8).lerp(Color.WHITE, 0.5 + 0.5 * sin(t * 6.0))

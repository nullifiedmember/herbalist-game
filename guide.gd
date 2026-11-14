extends Node2D
## Первые шаги без единого слова (этап 4 плана). Над героиней время от времени всплывает «мысль»
## с картинкой того, что нужно сделать, а над целью мерцает золотая стрелка. Шаги идут сами:
## травы → брёвна → верстак → котёл → вода → первое зелье → продать в городе. Сделала шаг — следующий.
## Шаги, которые уже сделаны (сценарий дал котёл, травница опытная), пропускаются.

const DB = preload("res://herbs_db.gd")
const RDB = preload("res://recipes_db.gd")
const WD = preload("res://world_data.gd")
const IT = preload("res://items_db.gd")
const STEPS: int = 7
const GOLD: Color = Color("ffd86a")

var main: Node2D
var t: float = 0.0
var target: Vector2 = Vector2.INF
var arrow_dir: Vector2 = Vector2.ZERO
var bubble_tex: Texture2D
var coins0: int = -1
var check_t: float = 0.0


func setup(m: Node2D) -> void:
	main = m
	z_index = 200
	z_as_relative = false
	if OS.get_cmdline_user_args().has("--test") or bool(main.get("classic_yard")):
		Game.guide_step = STEPS
	coins0 = Game.coins


func _herbs() -> int:
	var n: int = 0
	for id in Game.inventory.keys():
		if DB.DATA.has(String(id)):
			n += Game.get_count(String(id))
	return n


func _built(kind: String) -> bool:
	var hs: Node = main.get("homestead")
	return hs != null and bool(hs.call("has_built", kind))


func _water() -> bool:
	return Game.get_count("water_cold") + Game.get_count("water_warm") + Game.get_count("water_hot") > 0


func _potion() -> bool:
	if not Game.known_recipes.is_empty():
		return true
	for id in Game.inventory.keys():
		if RDB.is_product(String(id)) and String(id) != "murky":
			return true
	return false


## Сделан ли шаг i
func done(i: int) -> bool:
	match i:
		0:
			return _herbs() >= 3 or _potion()
		1:
			return Game.get_count("log") >= 6 or Game.get_count("kit:workbench") > 0 or _built("workbench") or _built("cauldron")
		2:
			return _built("workbench") or _built("cauldron")
		3:
			return _built("cauldron")
		4:
			return _water() or _potion()
		5:
			return _potion()
		6:
			return Game.coins > coins0 or int(Game.counters.get("sold", 0)) > 0 or Game.orders_done > 0
	return true


func _nearest(group: String, from: Vector2, max_d: float, filter: Callable = Callable()) -> Node2D:
	var best: Node2D = null
	var bd: float = max_d
	for n in get_tree().get_nodes_in_group(group):
		var nn: Node2D = n as Node2D
		if nn == null or not nn.is_visible_in_tree():
			continue
		if filter.is_valid() and not bool(filter.call(nn)):
			continue
		var d: float = nn.global_position.distance_to(from)
		if d < bd:
			bd = d
			best = nn
	return best


func _update_step() -> void:
	# шаги идут по порядку; сделанные — пропускаются
	while Game.guide_step < STEPS and done(Game.guide_step):
		Game.guide_step += 1
		coins0 = Game.coins if Game.guide_step == 6 else coins0
		if Game.guide_step < STEPS:
			Sound.play("ui_select", -14.0)
	target = Vector2.INF
	arrow_dir = Vector2.ZERO
	bubble_tex = null
	if Game.guide_step >= STEPS:
		return
	var pl: Node2D = main.get("player")
	var p: Vector2 = pl.global_position
	match Game.guide_step:
		0:
			bubble_tex = DB.icon("chamomile") if DB.DATA.has("chamomile") else load("res://art/fx_leaf.png")
			var h: Node2D = _nearest("wild_herbs", p, 900.0)
			if h != null:
				target = h.global_position
		1:
			bubble_tex = load("res://art/icon_log.png")
		2:
			bubble_tex = load("res://art/workbench.png")
		3:
			bubble_tex = load("res://art/cauldron.png")
			var wb: Node2D = _nearest("interactables", p, 1400.0, func(n: Node2D) -> bool: return String(n.get("kind")) == "workbench")
			if wb != null:
				target = wb.global_position
		4:
			bubble_tex = load("res://art/icon_water_cold.png")
			var wl: Node2D = _nearest("consumables", p, 1400.0, func(n: Node2D) -> bool: return String(n.get("kind")) == "well")
			if wl != null:
				target = wl.global_position
		5:
			bubble_tex = load("res://art/potion_heal_salve.png") if ResourceLoader.exists("res://art/potion_heal_salve.png") else load("res://art/icon_bottle.png")
			var cn: Node2D = _nearest("interactables", p, 1400.0, func(n: Node2D) -> bool: return n.get_script() == load("res://cauldron.gd"))
			if cn != null:
				target = cn.global_position
		6:
			bubble_tex = load("res://art/coin.png")
			var best: Vector2 = Vector2.INF
			for land in WD.TOWN_C.keys():
				var c: Vector2 = WD.TOWN_C[land]
				if best == Vector2.INF or c.distance_to(p) < best.distance_to(p):
					best = c
			if best != Vector2.INF and best.distance_to(p) > 700.0:
				arrow_dir = (best - p).normalized()


func _process(delta: float) -> void:
	t += delta
	check_t -= delta
	if check_t <= 0.0:
		check_t = 0.5
		_update_step()
	visible = Game.guide_step < STEPS and not bool(main.get("inside")) and not Game.ui_open and not Game.busy
	queue_redraw()


func _draw() -> void:
	if Game.guide_step >= STEPS:
		return
	var pl: Node2D = main.get("player")
	var p: Vector2 = pl.global_position
	# золотая стрелка над целью
	if target != Vector2.INF:
		var bob: float = absf(sin(t * 3.0)) * 6.0
		var a: Vector2 = target + Vector2(0, -46 - bob)
		draw_colored_polygon(PackedVector2Array([a + Vector2(-7, -9), a + Vector2(7, -9), a + Vector2(0, 2)]), Color(0.23, 0.15, 0.09, 0.9))
		draw_colored_polygon(PackedVector2Array([a + Vector2(-5, -8), a + Vector2(5, -8), a + Vector2(0, -1)]), GOLD)
		var r: float = 10.0 + fmod(t * 14.0, 16.0)
		draw_arc(target + Vector2(0, -6), r, 0.0, TAU, 24, Color(1.0, 0.85, 0.4, 0.6 * (1.0 - (r - 10.0) / 16.0)), 1.0)
	# стрелка к ближайшему городу — у ног героини
	if arrow_dir != Vector2.ZERO:
		var c: Vector2 = p + arrow_dir * (34.0 + sin(t * 4.0) * 3.0) + Vector2(0, -8)
		var n: Vector2 = arrow_dir.orthogonal()
		draw_colored_polygon(PackedVector2Array([c + arrow_dir * 8.0, c - arrow_dir * 4.0 + n * 6.0, c - arrow_dir * 4.0 - n * 6.0]), GOLD)
	# «мысль» над головой: 2,5 секунды из каждых 7
	var ph: float = fmod(t, 7.0)
	if bubble_tex != null and ph < 2.5:
		var al: float = clampf(minf(ph, 2.5 - ph) * 4.0, 0.0, 1.0)
		var b: Vector2 = p + Vector2(14, -62 - sin(t * 2.0) * 1.5)
		draw_circle(b + Vector2(-8, 14), 1.5, Color(1, 1, 1, 0.85 * al))
		draw_circle(b + Vector2(-4, 10), 2.2, Color(1, 1, 1, 0.85 * al))
		draw_rect(Rect2(b + Vector2(-1, -12), Vector2(22, 20)), Color(0.23, 0.15, 0.09, 0.85 * al))
		draw_rect(Rect2(b + Vector2(0, -11), Vector2(20, 18)), Color(1.0, 0.97, 0.88, 0.95 * al))
		var ts: Vector2 = bubble_tex.get_size()
		var k: float = minf(16.0 / ts.x, 14.0 / ts.y)
		var sz: Vector2 = ts * k
		draw_texture_rect(bubble_tex, Rect2(b + Vector2(10, -2) - sz / 2.0, sz), false, Color(1, 1, 1, al))

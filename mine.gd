extends Node
## Пещера-шахта (v19). Вход — пещеры в гротах и наверху карты (cave_door.gd), внутри — шахта:
## зал у лестницы, главный штрек с рельсами, большой зал, западная пещера летучих мышей,
## восточный склеп и юго-восточная выработка с рудой. Темно — фонари и свой факел (T).
## Каждый раз внизу кто-то есть: чаще вампирша, иногда дворфийка-шахтёрка или гоблинша.

const ORG: Vector2 = Vector2(0, 130000)
const SIZE: Vector2 = Vector2(2400, 1500)
const ARRIVE: Vector2 = Vector2(1200, 1230)
const LADDER: Vector2 = Vector2(1200, 1150)
## Проходы (в координатах шахты)
const AREAS: Array = [
	Rect2(1000, 1100, 400, 300),     # зал у лестницы
	Rect2(1140, 520, 120, 600),      # главный штрек
	Rect2(800, 260, 800, 280),       # большой зал
	Rect2(320, 360, 500, 110),       # западный штрек
	Rect2(120, 200, 300, 420),       # пещера летучих мышей
	Rect2(1580, 380, 440, 110),      # восточный штрек
	Rect2(2000, 180, 340, 420),      # склеп
	Rect2(1380, 1190, 520, 100),     # юго-восточный штрек
	Rect2(1880, 1000, 380, 380),     # выработка
]
const VISITORS: Array = [["vampire_carmilla", 0.35], ["vampire_mina", 0.25], ["dwarf_tova", 0.2], ["goblin_snik", 0.2]]

var main: Node2D
var world: Node2D
var root: Node2D
var inside: bool = false
var back_to: Vector2 = Vector2.ZERO
var circles: Array = []          # Vector3: преграды (ящики, вагонетки, глыбы)
var visitor: Node2D = null
var built: bool = false
var lamps: Array = []


func setup(m: Node2D, w: Node2D) -> void:
	main = m
	world = w
	add_to_group("mine18")


func _build() -> void:
	if built:
		return
	built = true
	root = Node2D.new()
	root.y_sort_enabled = true
	root.name = "MineRoot"
	(main.get("objects") as Node).add_child(root)
	# темнота вокруг и пол
	var void_r: ColorRect = ColorRect.new()
	void_r.color = Color("0c0b10")
	void_r.position = ORG - Vector2(600, 600)
	void_r.size = SIZE + Vector2(1200, 1200)
	void_r.z_index = -12
	main.add_child(void_r)
	var ftex: Texture2D = load("res://art/mine_floor.png")
	var wtex: Texture2D = load("res://art/mine_wall.png")
	for a in AREAS:
		var r: Rect2 = a
		var fl: Sprite2D = Sprite2D.new()
		fl.texture = ftex
		fl.centered = false
		fl.region_enabled = true
		fl.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		fl.region_rect = Rect2(Vector2.ZERO, r.size + Vector2(0, 8))
		fl.position = ORG + r.position
		fl.z_index = -10
		main.add_child(fl)
		# скальная стенка над проходом
		var wl: Sprite2D = Sprite2D.new()
		wl.texture = wtex
		wl.centered = false
		wl.region_enabled = true
		wl.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		wl.region_rect = Rect2(r.position.x, 0, r.size.x, 64)
		wl.position = ORG + r.position - Vector2(0, 62)
		wl.z_index = -9
		main.add_child(wl)
	# глыбы по краям проходов — стены
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 4242
	for a2 in AREAS:
		var r2: Rect2 = a2
		var n: int = int(r2.size.x / 70.0)
		for k in range(n):
			var x: float = r2.position.x + 20.0 + float(k) * 70.0 + rng.randf_range(-10, 10)
			_put("rock18_l_%d" % rng.randi_range(0, 2), Vector2(x, r2.end.y + 20.0), 0.0, Color(0.55, 0.52, 0.65))
		var m2: int = int(r2.size.y / 80.0)
		for k2 in range(m2):
			var y: float = r2.position.y + 40.0 + float(k2) * 80.0
			for sx in [r2.position.x - 14.0, r2.end.x + 14.0]:
				if not _walkable(Vector2(sx, y)):
					_put("rock18_m_%d" % rng.randi_range(0, 2), Vector2(sx, y + 10.0), 0.0, Color(0.5, 0.48, 0.6))
	# лестница наверх
	_put("mine_ladder", LADDER + Vector2(0, 10), 0.0, Color.WHITE, false)
	var ex: Node2D = Node2D.new()
	ex.set_script(load("res://cave_door.gd"))
	ex.set("up", true)
	ex.position = ORG + LADDER + Vector2(0, 20)
	root.add_child(ex)
	# крепь вдоль штреков, рельсы, вагонетка
	for y2 in range(560, 1100, 150):
		_put("mine_beam", Vector2(1200, float(y2)), 0.0, Color.WHITE, false)
	for bp in [Vector2(380, 470), Vector2(560, 470), Vector2(740, 470), Vector2(1640, 490), Vector2(1800, 490), Vector2(1960, 490), Vector2(1460, 1290), Vector2(1640, 1290), Vector2(1820, 1290)]:
		_put("mine_beam", bp, 0.0, Color.WHITE, false)
	var rt: Texture2D = load("res://art/mine_rail.png")
	var rl: Sprite2D = Sprite2D.new()
	rl.texture = rt
	rl.region_enabled = true
	rl.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	rl.region_rect = Rect2(0, 0, 640, 16)
	rl.rotation = PI / 2.0
	rl.position = ORG + Vector2(1200, 820)
	rl.z_index = -9
	main.add_child(rl)
	var rl2: Sprite2D = rl.duplicate() as Sprite2D
	rl2.rotation = 0.0
	rl2.region_rect = Rect2(0, 0, 760, 16)
	rl2.position = ORG + Vector2(1200, 420)
	main.add_child(rl2)
	_put("mine_cart", Vector2(1140, 420), 26.0)
	_put("mine_cart", Vector2(2060, 1330), 26.0)
	for cp in [Vector2(1930, 1060), Vector2(1966, 1072), Vector2(2210, 1340), Vector2(860, 300), Vector2(1560, 520)]:
		_put("mine_crate", cp, 14.0)
	# фонари
	for lp in [Vector2(1060, 1120), Vector2(1340, 1120), Vector2(1170, 760), Vector2(860, 280), Vector2(1540, 280), Vector2(2280, 220), Vector2(1900, 1030), Vector2(460, 380)]:
		_put("mine_lamp", lp, 0.0, Color.WHITE, false)
		var lt: Node2D = Node2D.new()
		lt.set_script(load("res://mine_light.gd"))
		lt.position = ORG + lp + Vector2(0, -30)
		root.add_child(lt)
		lamps.append(lt)
		main.call("add_glow", ORG + lp + Vector2(0, -30), 0.55, 0.6)
	# руда и валуны
	var rk: Node = get_tree().get_first_node_in_group("rocks18")
	if rk != null:
		var reg: Vector2i = Vector2i(-99, -99)
		var ores: Array = [["mana", Vector2(2080, 1150)], ["ember", Vector2(2200, 1220)], ["void", Vector2(2100, 300)], ["moonsilver", Vector2(1000, 330)], ["star", Vector2(1460, 340)], ["frost", Vector2(250, 300)], ["sunstone", Vector2(1960, 1300)]]
		for o in ores:
			rk.call("add_ore", root, reg, String(o[0]), ORG + (o[1] as Vector2), rng.randi_range(0, 1))
		for hp in [Vector2(980, 480), Vector2(1580, 470), Vector2(180, 560), Vector2(2300, 540)]:
			rk.call("add_rock", root, reg, "h", ORG + hp, "rock18_h_%d" % rng.randi_range(0, 2), "")
		for sp in [Vector2(1080, 1300), Vector2(1310, 1330), Vector2(900, 420), Vector2(1300, 300), Vector2(300, 520), Vector2(2150, 450), Vector2(1700, 1240)]:
			rk.call("add_rock", root, reg, "s" if int(sp.x) % 3 == 0 else "m", ORG + sp, "rock18_%s_%d" % ["s" if int(sp.x) % 3 == 0 else "m", rng.randi_range(0, 2)], "")
	# летучие мыши: больше всего — в западной пещере
	for bc in [[Vector2(270, 380), 6], [Vector2(1200, 400), 3], [Vector2(2170, 380), 3], [Vector2(2060, 1180), 2]]:
		for i in range(int(bc[1])):
			var b: Node2D = Node2D.new()
			b.set_script(load("res://bat.gd"))
			root.add_child(b)
			b.call("setup", ORG + (bc[0] as Vector2) + Vector2(rng.randf_range(-60, 60), rng.randf_range(-40, 40)), rng.randf_range(50.0, 110.0), false)
			b.add_to_group("mine_bats")
	# светящиеся грибы в склепе
	for gp in [Vector2(2040, 560), Vector2(2300, 580), Vector2(160, 600)]:
		_put("giant_shroom_blue", gp, 8.0)
		main.call("add_glow", ORG + gp + Vector2(0, -50), 0.5, 0.5)


func _put(tex: String, p: Vector2, block: float, tint: Color = Color.WHITE, cast: bool = true) -> Sprite2D:
	var s: Sprite2D = main.call("spr", tex, ORG + p, 0.0, false, root, false)
	s.modulate = tint
	if block > 0.0:
		circles.append(Vector3(p.x, p.y - 2.0, block))
	return s


func _walkable(l: Vector2) -> bool:
	for a in AREAS:
		if (a as Rect2).grow(-8.0).has_point(l):
			return true
	return false


func is_blocked(p: Vector2) -> bool:
	var l: Vector2 = p - ORG
	if not _walkable(l):
		return true
	for c in circles:
		var cv: Vector3 = c
		if (l.x - cv.x) * (l.x - cv.x) + (l.y - cv.y) * (l.y - cv.y) < cv.z * cv.z:
			return true
	# валуны и руда, поставленные через мир
	var blocks: Dictionary = world.get("blocks")
	var k: Vector2i = Vector2i(int(floor(p.x / 96.0)), int(floor(p.y / 96.0)))
	for c2 in blocks.get(k, []):
		var v: Vector3 = c2
		if (p.x - v.x) * (p.x - v.x) + (p.y - v.y) * (p.y - v.y) < v.z * v.z:
			return true
	return false


func enter(from: Vector2) -> void:
	if inside or Game.busy:
		return
	_build()
	back_to = from
	await main.call("_transition", func() -> void:
		set_inside(true)
		var pl: Node2D = main.get("player")
		pl.position = ORG + ARRIVE
		pl.set("facing", 1)
		_spawn_visitor())
	Sound.play("door", -6.0)
	Game.toast.emit("Заброшенная шахта", load("res://art/mine_lamp.png"))


func leave() -> void:
	if not inside or Game.busy:
		return
	await main.call("_transition", func() -> void:
		set_inside(false)
		var pl: Node2D = main.get("player")
		pl.position = main.call("free_near", back_to + Vector2(0, 46))
		pl.set("facing", 0))
	Sound.play("door", -6.0)


func set_inside(on: bool) -> void:
	inside = on
	var cam: Camera2D = main.get("cam")
	if on:
		cam.limit_left = int(ORG.x)
		cam.limit_top = int(ORG.y) - 80
		cam.limit_right = int(ORG.x + SIZE.x)
		cam.limit_bottom = int(ORG.y + SIZE.y)
	else:
		main.call("_world_limits")
	cam.reset_smoothing()
	if root != null:
		root.visible = on
		root.process_mode = Node.PROCESS_MODE_INHERIT if on else Node.PROCESS_MODE_DISABLED


## Кто сегодня внизу: вампирша (чаще), дворфийка-шахтёрка или гоблинша
func _spawn_visitor() -> void:
	if visitor != null and is_instance_valid(visitor):
		visitor.queue_free()
	var roll: float = randf()
	var tex: String = "vampire_carmilla"
	var acc: float = 0.0
	for v in VISITORS:
		acc += float(v[1])
		if roll <= acc:
			tex = String(v[0])
			break
	var at: Vector2 = ORG + (Vector2(2170, 420) if tex.begins_with("vampire") else Vector2(1990, 1180))
	visitor = main.call("_room_npc", tex, at)
	visitor.set("roam", 90.0)
	visitor.set("role", "житель")
	visitor.set_meta("mine_visitor", true)


func visitor_tex() -> String:
	return String(visitor.get("tex_name")) if visitor != null and is_instance_valid(visitor) else ""

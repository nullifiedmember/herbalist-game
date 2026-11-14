extends Node
## Горы дворфов — регионы (-3,-2), (-2,-2), (-2,-1) на северо-западе, за лесом эльфов.
## Врата подгорного чертога в скале (статуи, резной лик, руны), жаровни с огнём, скалы со снегом,
## таверна-пивоварня с бочками эля и столами, кузница, вагонетки с рудой, жилы с золотом.
## Дворфийки с косами: трактирщица, гуляка с кружкой, кузнечиха с молотом.

const GATE: Vector2 = Vector2(-10560, -3260)
const TAVERN: Vector2 = Vector2(-10010, -3110)
const FORGE: Vector2 = Vector2(-10940, -3040)

var main: Node2D
var world: Node2D


func setup(m: Node2D, w: Node2D) -> void:
	main = m
	world = w
	var b: Dictionary = world.get("builders")
	b[Vector2i(-6, -3)] = Callable(self, "build_hall")
	b[Vector2i(-5, -3)] = Callable(self, "build_mines")
	b[Vector2i(-5, -2)] = Callable(self, "build_mines")


func _put(node: Node2D, r: Vector2i, tex: String, p: Vector2, block: float = 0.0, flip: int = 0) -> Sprite2D:
	var s: Sprite2D = world.call("put", node, r, tex, p, 0.0, block, Color.WHITE, true)
	if flip >= 0:
		s.flip_h = flip == 1
	return s


func build_hall(node: Node2D, r: Vector2i) -> void:
	# врата в скале и скалы вокруг
	world.call("reserve", Rect2(GATE - Vector2(260, 330), Vector2(520, 400)))
	_put(node, r, "dwarf_gate", GATE)
	world.call("add_block_rect", Rect2(GATE.x - 200, GATE.y - 160, 400, 150))
	for cp in [[Vector2(-370, -40), 0], [Vector2(370, -30), 1], [Vector2(-640, 120), 1], [Vector2(620, 140), 0]]:
		var p: Vector2 = GATE + (cp[0] as Vector2)
		_put(node, r, "cliff", p, 0.0, int(cp[1]))
		world.call("add_block_rect", Rect2(p.x - 110, p.y - 80, 220, 74))
	for bp in [GATE + Vector2(-100, 40), GATE + Vector2(100, 40)]:
		_put(node, r, "brazier", bp, 8.0)
		_flame(node, bp + Vector2(0, -36))
	_glows(GATE, [Vector2(-16, -120), Vector2(16, -120), Vector2(-16, -66), Vector2(16, -66)], Color(0.45, 0.85, 1.0), 0.22)
	for mc in [GATE + Vector2(-190, 70), GATE + Vector2(170, 90)]:
		_put(node, r, "mine_cart", mc, 14.0, 1 if mc.x > GATE.x else 0)
	# таверна-пивоварня
	world.call("reserve", Rect2(TAVERN - Vector2(220, 260), Vector2(440, 360)))
	_put(node, r, "dwarf_tavern", TAVERN)
	world.call("add_block_rect", Rect2(TAVERN.x - 110, TAVERN.y - 86, 220, 80))
	_glows(TAVERN, [Vector2(-62, -114), Vector2(54, -114), Vector2(-58, -48), Vector2(50, -48), Vector2(0, -30)], Color(1.0, 0.72, 0.38), 0.35)
	for tp in [Vector2(-120, 70), Vector2(30, 80), Vector2(170, 60)]:
		_put(node, r, "ale_table", TAVERN + tp, 0.0)
		world.call("add_block_rect", Rect2(TAVERN.x + tp.x - 34, TAVERN.y + tp.y - 22, 68, 18))
	var kp: Vector2 = TAVERN + Vector2(190, -10)
	_put(node, r, "ale_kegs", kp, 0.0)
	world.call("add_block_rect", Rect2(kp.x - 34, kp.y - 24, 68, 22))
	var keg: Node2D = Node2D.new()
	keg.set_script(load("res://ale_keg.gd"))
	keg.position = kp
	node.add_child(keg)
	_girl(node, "dwarf_tova", TAVERN + Vector2(-20, 40), 90.0)
	_girl(node, "dwarf_hilda", TAVERN + Vector2(60, 120), 130.0)
	# кузница
	world.call("reserve", Rect2(FORGE - Vector2(120, 120), Vector2(240, 190)))
	_put(node, r, "forge", FORGE)
	world.call("add_block_rect", Rect2(FORGE.x - 42, FORGE.y - 40, 50, 36))
	world.call("add_block", FORGE + Vector2(25, -8), 12.0)
	_flame(node, FORGE + Vector2(-18, -26))
	_put(node, r, "ore_rock", FORGE + Vector2(90, 40), 16.0)
	_girl(node, "dwarf_greta", FORGE + Vector2(30, 50), 100.0)


## Рудники: жилы с золотом, вагонетки, жаровни, скалы
func build_mines(node: Node2D, r: Vector2i) -> void:
	var rng: RandomNumberGenerator = world.get("rng")
	var rect: Rect2 = Rect2(Vector2(r.x * 1920, r.y * 1280), Vector2(1920, 1280))
	var made: int = 0
	for i in range(80):
		var p: Vector2 = Vector2(rng.randf_range(rect.position.x + 140, rect.end.x - 140), rng.randf_range(rect.position.y + 200, rect.end.y - 60))
		if preload("res://world_data.gd").biome_at(p) != 8:
			continue
		if Rect2(-9760, -3900, 2000, 1400).has_point(p):
			continue   # здесь город дворфов
		if made < 3 and bool(world.call("free_at", p, 130.0, 70.0)):
			_put(node, r, "cliff", p, 0.0, rng.randi_range(0, 1))
			world.call("add_block_rect", Rect2(p.x - 110, p.y - 80, 220, 74))
			made += 1
		elif bool(world.call("free_at", p, 30.0, 30.0)):
			_put(node, r, "ore_rock" if i % 3 != 0 else "mine_cart", p, 16.0, rng.randi_range(0, 1))


## Живое пламя (жаровня, горн)
func _flame(node: Node2D, at: Vector2) -> void:
	var f: CPUParticles2D = CPUParticles2D.new()
	f.texture = load("res://art/fx_soft.png")
	f.amount = 16
	f.lifetime = 0.6
	f.position = at
	f.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	f.emission_rect_extents = Vector2(5, 2)
	f.direction = Vector2(0, -1)
	f.spread = 12.0
	f.gravity = Vector2(0, -40)
	f.initial_velocity_min = 8.0
	f.initial_velocity_max = 18.0
	f.scale_amount_min = 0.05
	f.scale_amount_max = 0.1
	var g: Gradient = Gradient.new()
	g.set_color(0, Color(1.0, 0.95, 0.6, 1.0))
	g.set_color(1, Color(0.9, 0.2, 0.05, 0.0))
	g.add_point(0.4, Color(1.0, 0.55, 0.15, 0.9))
	f.color_ramp = g
	f.material = main.call("_additive")
	f.z_index = 5
	node.add_child(f)
	_glows(at, [Vector2.ZERO], Color(1.0, 0.6, 0.3), 0.7)


func _glows(at: Vector2, offs: Array, col: Color, k: float) -> void:
	for o in offs:
		var s: Sprite2D = Sprite2D.new()
		s.texture = load("res://art/fx_glow.png")
		s.position = at + (o as Vector2)
		s.scale = Vector2.ONE * k
		s.modulate = Color(col.r, col.g, col.b, 0.0)
		s.material = main.call("_additive")
		(main.get("fx_layer") as Node).add_child(s)
		(main.get("glows") as Array).append([s, 0.7])


func _girl(node: Node2D, name: String, at: Vector2, roam: float) -> void:
	var c: Node2D = Node2D.new()
	c.set_script(load("res://catgirl.gd"))
	node.add_child(c)
	c.call("setup", name, at)
	c.set("roam", roam)
	c.set("blocked", Callable(main, "is_blocked"))
	var sp: Sprite2D = c.get("spr") as Sprite2D
	sp.scale = Vector2(0.28, 0.28)   # дворфийки ниже ростом
	c.set("interact_offset", Vector2(0, -23))
	main.call("add_caster", sp, true)
	sp.material = main.call("char_light_mat", Vector2(8, 8), sp)
	var fm: ShaderMaterial = main.call("char_light_mat", Vector2(1, 1), sp)
	fm.set_shader_parameter("region_mode", true)
	(c.get("face") as Sprite2D).material = fm
	c.set("face_mat", fm)

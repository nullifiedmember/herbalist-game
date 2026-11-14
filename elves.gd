extends Node
## Лес эльфов — регионы (-2,0), (-3,0), (-3,-1), (-3,1) на западе, за паутинным лесом.
## Великое древо-дом с настилами и фонариками, домики в стволах, лунный родник,
## белые арки над дорогами, фонари-листья вдоль пути, светящиеся колокольчики,
## огоньки-феи; эльфийки: лучница, травница в венке, стражница с копьём.

const GREAT_TREE: Vector2 = Vector2(-7060, 3030)
const SPRING: Vector2 = Vector2(-6960, 3490)
const GATE_W: Vector2 = Vector2(-6090, 3210)      # арка на западной дороге (вход в лес)
const GATE_N: Vector2 = Vector2(-6730, 2680)      # арка на дороге к дворфам
const HOUSES: Array = [Vector2(-6400, 2980), Vector2(-6360, 3520), Vector2(-7380, 3550), Vector2(-7490, 2940)]

var main: Node2D
var world: Node2D


func setup(m: Node2D, w: Node2D) -> void:
	main = m
	world = w
	var b: Dictionary = world.get("builders")
	b[Vector2i(-4, 2)] = Callable(self, "build_heart")
	for r in [Vector2i(-5, 2), Vector2i(-5, 1), Vector2i(-5, 3)]:
		b[r] = Callable(self, "build_outer")
	var pb: Dictionary = world.get("post_builders")
	for r2 in [Vector2i(-4, 2), Vector2i(-5, 2), Vector2i(-5, 1), Vector2i(-5, 3)]:
		pb[r2] = Callable(self, "decorate")


func _put(node: Node2D, r: Vector2i, tex: String, p: Vector2, block: float = 0.0, flip: int = -1) -> Sprite2D:
	var s: Sprite2D = world.call("put", node, r, tex, p, 0.0, block, Color.WHITE, true)
	if flip >= 0:
		s.flip_h = flip == 1
	return s


## Сердце леса: древо, домики, родник, арки, фонари вдоль дорог, эльфийки
func build_heart(node: Node2D, r: Vector2i) -> void:
	world.call("reserve", Rect2(GREAT_TREE - Vector2(260, 480), Vector2(520, 640)))
	_put(node, r, "elf_great_tree", GREAT_TREE, 0.0, 0)
	world.call("add_block", GREAT_TREE + Vector2(0, -16), 42.0)
	# окошки, дверь и фонарики древа светятся ночью
	_glows(GREAT_TREE, [Vector2(-4, -32), Vector2(14, -130), Vector2(-18, -210), Vector2(10, -48)], Color(1.0, 0.78, 0.45), 0.4)
	_glows(GREAT_TREE, [Vector2(-110, -200), Vector2(-60, -195), Vector2(70, -200), Vector2(120, -190)], Color(0.45, 0.95, 0.95), 0.3)
	_fairies(node, GREAT_TREE + Vector2(0, -150), Vector2(220, 170), 40)
	for hp in HOUSES:
		_house(node, r, hp)
	world.call("reserve", Rect2(SPRING - Vector2(240, 230), Vector2(480, 380)))
	_put(node, r, "elf_spring", SPRING, 0.0, 0)
	world.call("add_block", SPRING + Vector2(0, -38), 46.0)
	_glows(SPRING, [Vector2(0, -40)], Color(0.45, 0.95, 0.95), 0.9)
	_fairies(node, SPRING + Vector2(0, -40), Vector2(90, 40), 14)
	for gp in [GATE_W, GATE_N]:
		_put(node, r, "elf_arch", gp, 0.0, 0)
		world.call("add_block", gp + Vector2(-35, -4), 8.0)
		world.call("add_block", gp + Vector2(35, -4), 8.0)
		_glows(gp, [Vector2(-35, -50), Vector2(35, -50)], Color(0.45, 0.95, 0.95), 0.25)
	_road_lanterns(node, r)
	_girl(node, "elf_sylwen", SPRING + Vector2(60, 50), 120.0)
	_girl(node, "elf_lirael", GREAT_TREE + Vector2(60, 60), 150.0)
	_girl(node, "elf_thalia", GATE_W + Vector2(-20, 50), 90.0)


## Окраины: несколько домиков, фонари вдоль дороги, огоньки
func build_outer(node: Node2D, r: Vector2i) -> void:
	var rng: RandomNumberGenerator = world.get("rng")
	var rect: Rect2 = Rect2(Vector2(r.x * 1920, r.y * 1280), Vector2(1920, 1280))
	var n: int = 0
	var tries: int = 0
	while n < 3 and tries < 80:
		tries += 1
		var p: Vector2 = Vector2(rng.randf_range(rect.position.x + 150, rect.end.x - 150), rng.randf_range(rect.position.y + 250, rect.end.y - 80))
		if bool(world.call("free_at", p, 110.0, 90.0)):
			_house(node, r, p)
			n += 1
	_road_lanterns(node, r)
	_fairies(node, rect.get_center(), Vector2(700, 450), 30)
	if r == Vector2i(-5, 2):
		_girl(node, "elf_lirael", Vector2(-8440, 3420), 160.0)


func _house(node: Node2D, r: Vector2i, p: Vector2) -> void:
	world.call("reserve", Rect2(p - Vector2(100, 240), Vector2(200, 290)))
	_put(node, r, "elf_house", p, 0.0)
	world.call("add_block", p + Vector2(0, -14), 30.0)
	_glows(p, [Vector2(0, -26), Vector2(-10, -80)], Color(1.0, 0.78, 0.45), 0.35)


## Фонари-листья по обе стороны дорог региона
func _road_lanterns(node: Node2D, r: Vector2i) -> void:
	var rect: Rect2 = Rect2(Vector2(r.x * 1920, r.y * 1280), Vector2(1920, 1280))
	const WD = preload("res://world_data.gd")
	for pn in WD.road_points(220.0):
		var c: Vector2 = pn[0]
		var nrm: Vector2 = pn[1]
		for side in [-1.0, 1.0]:
			var lp: Vector2 = c + nrm * 40.0 * float(side)
			if rect.has_point(lp) and WD.biome_at(lp) == WD.ELF and bool(world.call("free_at", lp, 10.0, 6.0)):
				_put(node, r, "elf_lantern", lp, 4.0, 0 if side > 0.0 else 1)
				_glows(lp, [Vector2(10 if side > 0.0 else -10, -58)], Color(0.45, 0.95, 0.95), 0.3)


## После природы: светящиеся колокольчики и грибы по всему лесу
func decorate(node: Node2D, r: Vector2i) -> void:
	var rng: RandomNumberGenerator = world.get("rng")
	for i in range(60):
		var q: Vector2 = Vector2(rng.randf_range(r.x * 1920 + 20, r.x * 1920 + 1900), rng.randf_range(r.y * 1280 + 20, r.y * 1280 + 1260))
		if bool(world.call("free_at", q, 12.0, 14.0)):
			world.call("put", node, r, "elf_flowers" if i % 4 != 0 else "glow_shrooms", q, 0.0, 0.0, Color.WHITE, false)


func _glows(at: Vector2, offs: Array, col: Color, k: float) -> void:
	for o in offs:
		var s: Sprite2D = Sprite2D.new()
		s.texture = load("res://art/fx_glow.png")
		s.position = at + (o as Vector2)
		s.scale = Vector2.ONE * k
		s.modulate = Color(col.r, col.g, col.b, 0.0)
		s.material = main.call("_additive")
		(main.get("fx_layer") as Node).add_child(s)
		(main.get("glows") as Array).append([s, 0.6])


## Огоньки-феи: медленно плывут и мерцают (видны и днём, ночью ярче — их подсвечивает свет фонарей)
func _fairies(node: Node2D, at: Vector2, ext: Vector2, amount: int) -> void:
	var p: CPUParticles2D = CPUParticles2D.new()
	p.texture = load("res://art/fx_firefly.png")
	p.amount = amount
	p.lifetime = 5.0
	p.preprocess = 5.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = ext
	p.position = at
	p.direction = Vector2(0, -1)
	p.spread = 180.0
	p.gravity = Vector2(0, -3)
	p.initial_velocity_min = 3.0
	p.initial_velocity_max = 10.0
	p.color = Color(0.6, 1.0, 0.95)
	p.material = main.call("_additive")
	p.z_index = 30
	var ramp: Gradient = Gradient.new()
	ramp.set_color(0, Color(1, 1, 1, 0))
	ramp.set_color(1, Color(1, 1, 1, 0))
	ramp.add_point(0.3, Color(1, 1, 1, 1))
	ramp.add_point(0.7, Color(1, 1, 1, 0.8))
	p.color_ramp = ramp
	node.add_child(p)


func _girl(node: Node2D, name: String, at: Vector2, roam: float) -> void:
	var c: Node2D = Node2D.new()
	c.set_script(load("res://catgirl.gd"))
	node.add_child(c)
	c.call("setup", name, at)
	c.set("roam", roam)
	c.set("blocked", Callable(main, "is_blocked"))
	var sp: Sprite2D = c.get("spr") as Sprite2D
	main.call("add_caster", sp, true)
	sp.material = main.call("char_light_mat", Vector2(8, 8), sp)
	var fm: ShaderMaterial = main.call("char_light_mat", Vector2(1, 1), sp)
	fm.set_shader_parameter("region_mode", true)
	(c.get("face") as Sprite2D).material = fm
	c.set("face_mat", fm)

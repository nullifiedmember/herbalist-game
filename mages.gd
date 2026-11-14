extends Node
## Долина магов — регионы (2,-2), (3,-2), (2,-1) на северо-востоке.
## Белая башня магов с летающими кристаллами, обсерватория с телескопом, магические круги
## на земле в кольце рунных камней, кристаллы, поле лунных цветов, сундук-мимик.
## Девушки-маги с посохами (без шляп): гуляют, вокруг них искрится магия.

const TOWER: Vector2 = Vector2(8240, -3360)
const OBSERV: Vector2 = Vector2(9240, -3430)
const CIRCLE: Vector2 = Vector2(8940, -2960)
const FIELD: Vector2 = Vector2(8090, -2800)
const MIMIC: Vector2 = Vector2(9460, -2880)

var main: Node2D
var world: Node2D


func setup(m: Node2D, w: Node2D) -> void:
	main = m
	world = w
	var b: Dictionary = world.get("builders")
	b[Vector2i(4, -3)] = Callable(self, "build_valley")
	b[Vector2i(5, -3)] = Callable(self, "build_outer")
	b[Vector2i(4, -2)] = Callable(self, "build_outer")


func _put(node: Node2D, r: Vector2i, tex: String, p: Vector2, block: float = 0.0, flip: int = 0, cast: bool = true) -> Sprite2D:
	var s: Sprite2D = world.call("put", node, r, tex, p, 0.0, block, Color.WHITE, cast)
	if flip >= 0:
		s.flip_h = flip == 1
	return s


func build_valley(node: Node2D, r: Vector2i) -> void:
	# башня
	world.call("reserve", Rect2(TOWER - Vector2(160, 480), Vector2(320, 540)))
	_put(node, r, "mage_tower", TOWER)
	world.call("add_block", TOWER + Vector2(0, -20), 50.0)
	_glows(TOWER, [Vector2(0, -397), Vector2(0, -318), Vector2(0, -228), Vector2(0, -26)], Color(0.55, 0.7, 1.0), 0.35)
	_glows(TOWER, [Vector2(-72, -240), Vector2(70, -200), Vector2(-64, -100), Vector2(66, -320)], Color(0.7, 0.55, 1.0), 0.25)
	_girl(node, "mage_aurel", TOWER + Vector2(30, 60), 120.0)
	# обсерватория
	world.call("reserve", Rect2(OBSERV - Vector2(170, 280), Vector2(340, 320)))
	_put(node, r, "observatory", OBSERV)
	world.call("add_block_rect", Rect2(OBSERV.x - 92, OBSERV.y - 100, 184, 92))
	_glows(OBSERV, [Vector2(-58, -76), Vector2(58, -76), Vector2(0, -24)], Color(0.55, 0.7, 1.0), 0.35)
	_girl(node, "mage_noa", OBSERV + Vector2(0, 60), 110.0)
	# магический круг в кольце рунных камней
	_circle(node, r, CIRCLE, 6)
	# поле лунных цветов
	var rng: RandomNumberGenerator = world.get("rng")
	world.call("reserve", Rect2(FIELD - Vector2(280, 120), Vector2(560, 240)))
	for i in range(90):
		var p: Vector2 = FIELD + Vector2(rng.randf_range(-260, 260), rng.randf_range(-100, 100))
		if Vector2((p.x - FIELD.x) / 260.0, (p.y - FIELD.y) / 100.0).length() < 1.0:
			_put(node, r, "moon_flowers", p, 0.0, rng.randi_range(0, 1), false)
	for k in range(6):
		_glows(FIELD + Vector2(-200 + k * 80, rng.randf_range(-50, 50)), [Vector2(0, -10)], Color(0.7, 0.8, 1.0), 0.6)
	_girl(node, "mage_ilka", FIELD + Vector2(0, 20), 200.0)
	# мимик среди кристаллов
	world.call("reserve", Rect2(MIMIC - Vector2(140, 160), Vector2(280, 240)))
	for cp in [MIMIC + Vector2(-60, -20), MIMIC + Vector2(50, 10)]:
		_crystal(node, r, cp)
	var m: Node2D = Node2D.new()
	m.set_script(load("res://mimic.gd"))
	node.add_child(m)
	m.call("setup", MIMIC)
	main.call("add_caster", m.get("spr") as Sprite2D, true)
	world.call("add_block", MIMIC + Vector2(0, -6), 14.0)
	for k2 in range(8):
		var q: Vector2 = Vector2(rng.randf_range(7740, 9540), rng.randf_range(-3780, -2630))
		if bool(world.call("free_at", q, 30.0, 30.0)):
			_crystal(node, r, q)


func build_outer(node: Node2D, r: Vector2i) -> void:
	var rng: RandomNumberGenerator = world.get("rng")
	var rect: Rect2 = Rect2(Vector2(r.x * 1920, r.y * 1280), Vector2(1920, 1280))
	var placed: bool = false
	for i in range(40):
		var p: Vector2 = Vector2(rng.randf_range(rect.position.x + 200, rect.end.x - 200), rng.randf_range(rect.position.y + 200, rect.end.y - 150))
		if not placed and bool(world.call("free_at", p, 140.0, 60.0)):
			_circle(node, r, p, 5)
			placed = true
	for k in range(10):
		var q: Vector2 = Vector2(rng.randf_range(rect.position.x + 40, rect.end.x - 40), rng.randf_range(rect.position.y + 40, rect.end.y - 40))
		if bool(world.call("free_at", q, 30.0, 30.0)):
			_crystal(node, r, q)
	for k2 in range(40):
		var f: Vector2 = Vector2(rng.randf_range(rect.position.x + 20, rect.end.x - 20), rng.randf_range(rect.position.y + 20, rect.end.y - 20))
		if bool(world.call("free_at", f, 10.0, 12.0)):
			_put(node, r, "moon_flowers", f, 0.0, rng.randi_range(0, 1), false)


## Светящийся круг на земле и рунные камни по кольцу
func _circle(node: Node2D, r: Vector2i, c: Vector2, stones: int) -> void:
	world.call("reserve", Rect2(c - Vector2(150, 100), Vector2(300, 200)))
	var d: Sprite2D = Sprite2D.new()
	d.texture = load("res://art/magic_circle.png")
	d.position = c
	d.z_index = -10
	d.material = main.call("_additive")
	node.add_child(d)
	# круг медленно «дышит»
	var tw: Tween = d.create_tween().set_loops()
	tw.tween_property(d, "modulate:a", 0.45, 2.2)
	tw.tween_property(d, "modulate:a", 1.0, 2.2)
	for k in range(stones):
		var a: float = TAU * float(k) / float(stones) - PI / 2.0
		_put(node, r, "rune_stone", c + Vector2(cos(a) * 120.0, sin(a) * 70.0 + 8.0), 9.0)
	_glows(c, [Vector2.ZERO], Color(0.5, 0.55, 1.0), 1.2)


func _crystal(node: Node2D, r: Vector2i, p: Vector2) -> void:
	_put(node, r, "crystal_cluster", p, 14.0, (world.get("rng") as RandomNumberGenerator).randi_range(0, 1))
	_glows(p, [Vector2(0, -24)], Color(0.7, 0.5, 1.0), 0.45)


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
	# искорки магии вокруг
	var p: CPUParticles2D = CPUParticles2D.new()
	p.texture = load("res://art/fx_firefly.png")
	p.amount = 8
	p.lifetime = 1.6
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(14, 22)
	p.position = Vector2(0, -26)
	p.direction = Vector2(0, -1)
	p.spread = 30.0
	p.gravity = Vector2(0, -6)
	p.initial_velocity_min = 2.0
	p.initial_velocity_max = 8.0
	p.color = Color(0.75, 0.8, 1.0)
	p.scale_amount_min = 0.5
	p.scale_amount_max = 0.8
	p.material = main.call("_additive")
	var ramp: Gradient = Gradient.new()
	ramp.set_color(0, Color(1, 1, 1, 0))
	ramp.set_color(1, Color(1, 1, 1, 0))
	ramp.add_point(0.3, Color(1, 1, 1, 1))
	p.color_ramp = ramp
	c.add_child(p)

extends Node
## Степь орков и гоблинов — регионы (2,2), (3,2), (1,2), (3,1) на юго-востоке.
## Становище орков: длинный дом из брёвен под шкурами, шатры, тотемы, частокол, барабан,
## костёр с вертелом (живой огонь). Деревня гоблинов: кривые домики на сваях с лоскутными
## крышами, шаткая вышка, кучи хлама, барахолка. Орочки с клыками и маленькие гоблинши.

const CAMP: Vector2 = Vector2(8990, 5360)
const GOBLINS: Vector2 = Vector2(10170, 5560)

var main: Node2D
var world: Node2D


func setup(m: Node2D, w: Node2D) -> void:
	main = m
	world = w
	var b: Dictionary = world.get("builders")
	b[Vector2i(4, 4)] = Callable(self, "build_camp")
	b[Vector2i(5, 4)] = Callable(self, "build_goblins")
	b[Vector2i(3, 4)] = Callable(self, "build_outpost")
	b[Vector2i(5, 3)] = Callable(self, "build_outpost")


func _put(node: Node2D, r: Vector2i, tex: String, p: Vector2, block: float = 0.0, flip: int = 0) -> Sprite2D:
	var s: Sprite2D = world.call("put", node, r, tex, p, 0.0, block, Color.WHITE, true)
	if flip >= 0:
		s.flip_h = flip == 1
	return s


func build_camp(node: Node2D, r: Vector2i) -> void:
	world.call("reserve", Rect2(CAMP - Vector2(330, 380), Vector2(660, 640)))
	_put(node, r, "orc_longhouse", CAMP + Vector2(0, -90))
	world.call("add_block_rect", Rect2(CAMP.x - 116, CAMP.y - 168, 232, 76))
	for tp in [[Vector2(-210, 30), 0], [Vector2(210, 40), 1], [Vector2(-170, 190), 0], [Vector2(190, 200), 1]]:
		var p: Vector2 = CAMP + (tp[0] as Vector2)
		_put(node, r, "orc_tent", p, 0.0, int(tp[1]))
		world.call("add_block_rect", Rect2(p.x - 44, p.y - 36, 88, 32))
	for tt in [Vector2(-80, -40), Vector2(80, -40), Vector2(0, 230)]:
		_put(node, r, "totem", CAMP + tt, 8.0)
	_put(node, r, "war_drum", CAMP + Vector2(110, 120), 12.0)
	_put(node, r, "weapon_rack", CAMP + Vector2(-110, 120), 10.0)
	_put(node, r, "hay_bale", CAMP + Vector2(-250, 120), 9.0)
	_fire(node, r, CAMP + Vector2(0, 90))
	# частокол: ряд сзади и ряд спереди с воротами посередине
	for k in range(6):
		var x: float = CAMP.x - 288.0 + k * 96.0 + 48.0
		_put(node, r, "palisade", Vector2(x, CAMP.y - 260.0))
		world.call("add_block_rect", Rect2(x - 48, CAMP.y - 268.0, 96, 10))
		if absf(x - CAMP.x) > 60.0:
			_put(node, r, "palisade", Vector2(x, CAMP.y + 300.0))
			world.call("add_block_rect", Rect2(x - 48, CAMP.y + 292.0, 96, 10))
	_girl(node, "orc_grasha", CAMP + Vector2(-40, 140), 150.0, 0.3333)
	_girl(node, "orc_ruzga", CAMP + Vector2(90, 170), 150.0, 0.3333)


func build_goblins(node: Node2D, r: Vector2i) -> void:
	world.call("reserve", Rect2(GOBLINS - Vector2(330, 300), Vector2(660, 520)))
	var huts: Array = [[Vector2(-210, -90), "goblin_hut_a", 0], [Vector2(160, -110), "goblin_hut_b", 1], [Vector2(-150, 170), "goblin_hut_b", 0], [Vector2(230, 160), "goblin_hut_a", 1]]
	for h in huts:
		var p: Vector2 = GOBLINS + (h[0] as Vector2)
		_put(node, r, String(h[1]), p, 0.0, int(h[2]))
		world.call("add_block_rect", Rect2(p.x - 40, p.y - 34, 80, 30))
		_glow(p + Vector2(20 if int(h[2]) == 0 else -20, -62), Color(1.0, 0.8, 0.4), 0.3)
	_put(node, r, "goblin_tower", GOBLINS + Vector2(-20, -200))
	world.call("add_block", GOBLINS + Vector2(-20, -206), 22.0)
	_glow(GOBLINS + Vector2(-20, -340), Color(1.0, 0.8, 0.4), 0.35)
	_put(node, r, "goblin_stall", GOBLINS + Vector2(40, 40))
	world.call("add_block_rect", Rect2(GOBLINS.x - 4, GOBLINS.y + 14, 88, 24))
	for jp in [Vector2(-60, 60), Vector2(300, 20), Vector2(-300, 40)]:
		_put(node, r, "junk_pile", GOBLINS + jp, 18.0)
	for lp in [Vector2(-90, -20), Vector2(110, -10)]:
		_put(node, r, "lantern", GOBLINS + lp, 6.0)
		_glow(GOBLINS + lp + Vector2(8, -46), Color(1.0, 0.72, 0.38), 0.6)
	_fire(node, r, GOBLINS + Vector2(-20, 100))
	_girl(node, "goblin_pip", GOBLINS + Vector2(0, 60), 160.0, 0.27)
	_girl(node, "goblin_zix", GOBLINS + Vector2(-120, 20), 160.0, 0.27)
	_girl(node, "goblin_pip", GOBLINS + Vector2(140, 90), 120.0, 0.27)


## Маленькие стоянки в степи: шатёр, тотем, костёр
func build_outpost(node: Node2D, r: Vector2i) -> void:
	var rng: RandomNumberGenerator = world.get("rng")
	var rect: Rect2 = Rect2(Vector2(r.x * 1920, r.y * 1280), Vector2(1920, 1280))
	for i in range(30):
		var p: Vector2 = Vector2(rng.randf_range(rect.position.x + 200, rect.end.x - 200), rng.randf_range(rect.position.y + 200, rect.end.y - 150))
		if bool(world.call("free_at", p, 160.0, 60.0)) and WD_biome(p) == 7:
			world.call("reserve", Rect2(p - Vector2(170, 150), Vector2(340, 260)))
			_put(node, r, "orc_tent", p + Vector2(-60, -10), 0.0, 0)
			world.call("add_block_rect", Rect2(p.x - 104, p.y - 46, 88, 32))
			_put(node, r, "totem", p + Vector2(70, -20), 8.0)
			_fire(node, r, p + Vector2(20, 60))
			break


func WD_biome(p: Vector2) -> int:
	return preload("res://world_data.gd").biome_at(p)


## Костёр: камни и вертел (спрайт) + живой огонь частицами, искры, дым, свет ночью
func _fire(node: Node2D, r: Vector2i, at: Vector2) -> void:
	_put(node, r, "campfire", at, 16.0)
	var f: CPUParticles2D = CPUParticles2D.new()
	f.texture = load("res://art/fx_soft.png")
	f.amount = 22
	f.lifetime = 0.7
	f.position = at + Vector2(0, -12)
	f.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	f.emission_rect_extents = Vector2(6, 2)
	f.direction = Vector2(0, -1)
	f.spread = 12.0
	f.gravity = Vector2(0, -40)
	f.initial_velocity_min = 8.0
	f.initial_velocity_max = 20.0
	f.scale_amount_min = 0.06
	f.scale_amount_max = 0.12
	var g: Gradient = Gradient.new()
	g.set_color(0, Color(1.0, 0.95, 0.6, 1.0))
	g.set_color(1, Color(0.9, 0.2, 0.05, 0.0))
	g.add_point(0.4, Color(1.0, 0.55, 0.15, 0.9))
	f.color_ramp = g
	f.material = main.call("_additive")
	f.z_index = 5
	node.add_child(f)
	var sm: CPUParticles2D = CPUParticles2D.new()
	sm.texture = load("res://art/fx_soft.png")
	sm.amount = 10
	sm.lifetime = 2.6
	sm.position = at + Vector2(0, -30)
	sm.direction = Vector2(0.2, -1)
	sm.spread = 15.0
	sm.gravity = Vector2(4, -6)
	sm.initial_velocity_min = 8.0
	sm.initial_velocity_max = 14.0
	sm.scale_amount_min = 0.1
	sm.scale_amount_max = 0.2
	var g2: Gradient = Gradient.new()
	g2.set_color(0, Color(0.6, 0.58, 0.55, 0.35))
	g2.set_color(1, Color(0.6, 0.58, 0.55, 0.0))
	sm.color_ramp = g2
	sm.z_index = 5
	node.add_child(sm)
	_glow(at + Vector2(0, -14), Color(1.0, 0.6, 0.3), 0.9)


func _glow(at: Vector2, col: Color, k: float) -> void:
	var s: Sprite2D = Sprite2D.new()
	s.texture = load("res://art/fx_glow.png")
	s.position = at
	s.scale = Vector2.ONE * k
	s.modulate = Color(col.r, col.g, col.b, 0.0)
	s.material = main.call("_additive")
	(main.get("fx_layer") as Node).add_child(s)
	(main.get("glows") as Array).append([s, 0.7])


func _girl(node: Node2D, name: String, at: Vector2, roam: float, sc: float) -> void:
	var c: Node2D = Node2D.new()
	c.set_script(load("res://catgirl.gd"))
	node.add_child(c)
	c.call("setup", name, at)
	c.set("roam", roam)
	c.set("blocked", Callable(main, "is_blocked"))
	var sp: Sprite2D = c.get("spr") as Sprite2D
	sp.scale = Vector2(sc, sc)   # гоблинши ниже ростом
	if sc < 0.3:
		c.set("interact_offset", Vector2(0, -22))
	main.call("add_caster", sp, true)
	sp.material = main.call("char_light_mat", Vector2(8, 8), sp)
	var fm: ShaderMaterial = main.call("char_light_mat", Vector2(1, 1), sp)
	fm.set_shader_parameter("region_mode", true)
	(c.get("face") as Sprite2D).material = fm
	c.set("face_mat", fm)

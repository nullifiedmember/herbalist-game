extends Node
## Готика — регионы (-1,-2), (0,-2), (1,-2) на севере. Сумрачные земли:
## замок вампиров у дороги, кладбище со склепом и кованой оградой, особняк вампирш на западе,
## мёртвый лес оборотней на востоке, фонари с огнём, кусты роз, летучие мыши.

const CASTLE: Vector2 = Vector2(60, -4550)
const GRAVE_C: Vector2 = Vector2(700, -4760)
const MANOR: Vector2 = Vector2(-1900, -4580)
const WOLF_GLADE: Vector2 = Vector2(2700, -4680)

var main: Node2D
var world: Node2D


func setup(m: Node2D, w: Node2D) -> void:
	main = m
	world = w
	var b: Dictionary = world.get("builders")
	b[Vector2i(0, -4)] = Callable(self, "build_castle")
	b[Vector2i(-1, -4)] = Callable(self, "build_manor")
	b[Vector2i(1, -4)] = Callable(self, "build_wolves")


func _put(node: Node2D, r: Vector2i, tex: String, p: Vector2, block: float = 0.0, cast: bool = true) -> Sprite2D:
	return world.call("put", node, r, tex, p, 0.0, block, Color.WHITE, cast)


## Замок у дороги и кладбище за ним
func build_castle(node: Node2D, r: Vector2i) -> void:
	world.call("reserve", Rect2(CASTLE - Vector2(230, 420), Vector2(460, 470)))
	var cs: Sprite2D = _put(node, r, "goth_castle", CASTLE)
	cs.flip_h = false
	world.call("add_block_rect", Rect2(CASTLE.x - 176, CASTLE.y - 130, 352, 112))
	_windows(CASTLE, [Vector2(0, -196), Vector2(-40, -142), Vector2(40, -142), Vector2(-126, -165), Vector2(-126, -61), Vector2(126, -165), Vector2(126, -113), Vector2(126, -61)])
	for lp in [CASTLE + Vector2(-70, 30), CASTLE + Vector2(70, 30)]:
		_lamp(node, r, lp)
	for rp in [CASTLE + Vector2(-140, 10), CASTLE + Vector2(140, 14)]:
		_put(node, r, "rose_bush", rp)
	_girl(node, "vampire_lilith", CASTLE + Vector2(0, 50), 90.0)
	for i in range(4):
		_bat(node, CASTLE + Vector2(0, -260), randf_range(90.0, 170.0), i >= 2)
	# кладбище: кованая ограда сверху и снизу (ворота посередине), склеп, ряды надгробий
	world.call("reserve", Rect2(GRAVE_C - Vector2(290, 190), Vector2(580, 360)))
	var fx: float = GRAVE_C.x - 256.0
	while fx < GRAVE_C.x + 256.0:
		_put(node, r, "iron_fence", Vector2(fx + 32.0, GRAVE_C.y - 150.0))
		world.call("add_block_rect", Rect2(fx, GRAVE_C.y - 158.0, 64, 10))
		if absf(fx + 32.0 - GRAVE_C.x) > 50.0:
			_put(node, r, "iron_fence", Vector2(fx + 32.0, GRAVE_C.y + 150.0))
			world.call("add_block_rect", Rect2(fx, GRAVE_C.y + 142.0, 64, 10))
		fx += 64.0
	_put(node, r, "crypt", GRAVE_C + Vector2(0, -62))
	world.call("add_block_rect", Rect2(GRAVE_C.x - 46, GRAVE_C.y - 100, 92, 40))
	var kinds: Array = ["grave_a", "grave_b", "grave_c"]
	var rng: RandomNumberGenerator = world.get("rng")
	for row in range(3):
		var gx: float = GRAVE_C.x - 220.0
		while gx < GRAVE_C.x + 230.0:
			if absf(gx - GRAVE_C.x) > 70.0 or row == 2:
				if absf(gx - GRAVE_C.x) > 34.0:
					var gp: Vector2 = Vector2(gx + rng.randf_range(-4, 4), GRAVE_C.y - 10.0 + row * 52.0)
					_put(node, r, String(kinds[rng.randi_range(0, 2)]), gp, 7.0)
			gx += 52.0
	for tp in [GRAVE_C + Vector2(-250, -110), GRAVE_C + Vector2(250, -100), GRAVE_C + Vector2(-240, 110), GRAVE_C + Vector2(236, 120)]:
		_put(node, r, "dead_tree_a" if tp.x < GRAVE_C.x else "dead_tree_b", tp, 10.0)
	for lp2 in [GRAVE_C + Vector2(-60, 170), GRAVE_C + Vector2(60, 170)]:
		_lamp(node, r, lp2)
	_girl(node, "vampire_carmilla", GRAVE_C + Vector2(0, 40), 120.0)
	for j in range(3):
		_bat(node, GRAVE_C + Vector2(0, -60), randf_range(80.0, 140.0), true)


## Особняк вампирш на западе
func build_manor(node: Node2D, r: Vector2i) -> void:
	world.call("reserve", Rect2(MANOR - Vector2(170, 300), Vector2(340, 360)))
	_put(node, r, "goth_manor", MANOR)
	world.call("add_block_rect", Rect2(MANOR.x - 118, MANOR.y - 120, 236, 100))
	_windows(MANOR, [Vector2(0, -106), Vector2(-40, -52), Vector2(40, -52), Vector2(0, -50), Vector2(76, -123), Vector2(76, -71)])
	for lp in [MANOR + Vector2(-56, 34), MANOR + Vector2(56, 34)]:
		_lamp(node, r, lp)
	for k in range(6):
		_put(node, r, "rose_bush", MANOR + Vector2(-150 + k * 60, 70 + (k % 2) * 10))
	_girl(node, "vampire_mina", MANOR + Vector2(10, 70), 110.0)
	for i in range(3):
		_bat(node, MANOR + Vector2(0, -180), randf_range(70.0, 130.0), i > 0)


## Мёртвый лес оборотней: поляна с камнями, девушки-волчицы
func build_wolves(node: Node2D, r: Vector2i) -> void:
	world.call("reserve", Rect2(WOLF_GLADE - Vector2(200, 140), Vector2(400, 280)))
	for k in range(7):
		var a: float = TAU * k / 7.0
		_put(node, r, "rock_big" if k % 2 == 0 else "rock", WOLF_GLADE + Vector2(cos(a) * 150.0, sin(a) * 80.0), 12.0)
	_girl(node, "werewolf_luna", WOLF_GLADE + Vector2(-40, 0), 140.0)
	_girl(node, "werewolf_rua", WOLF_GLADE + Vector2(50, 20), 140.0)
	_lamp(node, r, Vector2(2200, -4200))
	_lamp(node, r, Vector2(3100, -4280))
	for i in range(3):
		_bat(node, WOLF_GLADE + Vector2(0, -120), randf_range(100.0, 200.0), true)


## Ночью окна светятся тёплым светом
func _windows(at: Vector2, offs: Array) -> void:
	for o in offs:
		var s: Sprite2D = Sprite2D.new()
		s.texture = load("res://art/fx_glow.png")
		s.position = at + (o as Vector2)
		s.scale = Vector2.ONE * 0.32
		s.modulate = Color(1.0, 0.62, 0.32, 0.0)
		s.material = main.call("_additive")
		(main.get("fx_layer") as Node).add_child(s)
		(main.get("glows") as Array).append([s, 0.7])


func _lamp(node: Node2D, r: Vector2i, at: Vector2) -> void:
	_put(node, r, "goth_lamp", at, 5.0)
	var s: Sprite2D = Sprite2D.new()
	s.texture = load("res://art/fx_glow.png")
	s.position = at + Vector2(0, -78)
	s.scale = Vector2.ONE * 0.7
	s.modulate = Color(1.0, 0.55, 0.3, 0.0)
	s.material = main.call("_additive")
	(main.get("fx_layer") as Node).add_child(s)
	(main.get("glows") as Array).append([s, 0.65])


func _bat(node: Node2D, at: Vector2, rad: float, night: bool) -> void:
	var b: Node2D = Node2D.new()
	b.set_script(load("res://bat.gd"))
	node.add_child(b)
	b.call("setup", at, rad, night)


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

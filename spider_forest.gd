extends Node
## Паутинный лес — регионы (-1, 0) и (-1, -1), сразу к западу от двора.
## Тёмный сиреневый лес в паутине: шёлковое логово девочки-паука на поляне, кладки коконов,
## светящиеся грибы, паутинки на деревьях и в траве, добрые пушистые паучки.

const REGIONS: Array = [Vector2i(-2, -1), Vector2i(-2, -2)]
const NEST_REGION: Vector2i = Vector2i(-2, -1)
const NEST: Vector2 = Vector2(-3170, -720)       # «ноги» логова (низ купола)
const SPIDERS: Array = ["spider_lilac", "spider_tan", "spider_ink"]

var main: Node2D
var world: Node2D


func setup(m: Node2D, w: Node2D) -> void:
	main = m
	world = w
	var b: Dictionary = world.get("builders")
	var pb: Dictionary = world.get("post_builders")
	for r in REGIONS:
		b[r] = Callable(self, "build")
		pb[r] = Callable(self, "decorate")


## До природы: поляна с логовом (на ней деревья не растут)
func build(node: Node2D, r: Vector2i) -> void:
	var rng: RandomNumberGenerator = world.get("rng")
	if r == NEST_REGION:
		world.call("reserve", Rect2(NEST - Vector2(190, 200), Vector2(380, 290)))
		world.call("put", node, r, "spider_nest", NEST, 0.0, 0.0)
		world.call("add_block_rect", Rect2(NEST.x - 62, NEST.y - 60, 124, 52))
		# тёплый свет из дверцы и окошек логова
		_glow(NEST + Vector2(0, -38), 0.8, Color(1.0, 0.72, 0.38))
		_glow(NEST + Vector2(-38, -74), 0.35, Color(1.0, 0.72, 0.38))
		_glow(NEST + Vector2(38, -72), 0.35, Color(1.0, 0.72, 0.38))
		for k in range(7):
			var a: float = TAU * float(k) / 7.0 + 0.4
			var gp: Vector2 = NEST + Vector2(cos(a) * 130.0, 30.0 + sin(a) * 60.0)
			world.call("put", node, r, "glow_shrooms", gp, 0.0, 0.0, Color.WHITE, false)
			_glow(gp + Vector2(0, -12), 0.45)
		for ep in [NEST + Vector2(-110, 10), NEST + Vector2(104, 20), NEST + Vector2(-60, 70)]:
			world.call("put", node, r, "egg_sacs", ep, 0.0, 8.0)
		for wp in [NEST + Vector2(-150, 80), NEST + Vector2(40, 90), NEST + Vector2(150, -20)]:
			world.call("put", node, r, "web_ground", wp, 0.0, 0.0, Color.WHITE, false)
		_girl(node, NEST + Vector2(10, 60))
	# пауки гуляют по всему лесу
	var rect: Rect2 = Rect2(Vector2(r.x * 1920, r.y * 1280), Vector2(1920, 1280))
	var n: int = 0
	var tries: int = 0
	while n < 9 and tries < 200:
		tries += 1
		var p: Vector2 = Vector2(rng.randf_range(rect.position.x + 60, rect.end.x - 60), rng.randf_range(rect.position.y + 60, rect.end.y - 60))
		if r == NEST_REGION and n < 3:
			p = NEST + Vector2(rng.randf_range(-150, 150), rng.randf_range(40, 110))
		if bool(main.call("is_blocked", p)):
			continue
		_spider(node, SPIDERS[n % SPIDERS.size()], p)
		n += 1


## После природы: на деревьях паутина, в траве паутинки, коконы и светящиеся грибы
func decorate(node: Node2D, r: Vector2i) -> void:
	var rng: RandomNumberGenerator = world.get("rng")
	var trees: Array = []
	for c in node.get_children():
		if c is Sprite2D and String((c as Sprite2D).texture.resource_path).contains("tree"):
			trees.append(c)
	var glows: int = 0
	for tr in trees:
		var tp: Vector2 = (tr as Sprite2D).position
		var roll: float = rng.randf()
		if roll < 0.28:
			# паутина между стволом и землёй, сбоку от дерева
			var left: bool = rng.randf() < 0.5
			var ws: Sprite2D = world.call("put", node, r, "web_side", tp + Vector2(-38.0 if left else 38.0, 2.0), 0.0, 0.0, Color.WHITE, false)
			ws.flip_h = left
		elif roll < 0.45:
			var wh: Sprite2D = world.call("put", node, r, "web_hang", tp + Vector2(rng.randf_range(-20, 20), -60.0), 0.0, 0.0, Color.WHITE, false)
			wh.z_index = 1
		elif roll < 0.55:
			world.call("put", node, r, "egg_sacs", tp + Vector2(rng.randf_range(-16, 16), 8.0), 0.0, 0.0)
		elif roll < 0.68:
			var gp: Vector2 = tp + Vector2(rng.randf_range(-22, 22), 10.0)
			world.call("put", node, r, "glow_shrooms", gp, 0.0, 0.0, Color.WHITE, false)
			if glows < 8:
				_glow(gp + Vector2(0, -12), 0.35)
				glows += 1
	for i in range(26):
		var q: Vector2 = Vector2(rng.randf_range(r.x * 1920 + 20, r.x * 1920 + 1900), rng.randf_range(r.y * 1280 + 20, r.y * 1280 + 1260))
		if bool(world.call("free_at", q, 14.0, 10.0)):
			world.call("put", node, r, "web_ground", q, 0.0, 0.0, Color.WHITE, false)


## Тёплое сияние ночью (грибы, окошки логова)
func _glow(at: Vector2, k: float, col: Color = Color(0.7, 0.55, 1.0)) -> void:
	var s: Sprite2D = Sprite2D.new()
	s.texture = load("res://art/fx_glow.png")
	s.position = at
	s.scale = Vector2.ONE * k
	s.modulate = Color(col.r, col.g, col.b, 0.0)
	s.material = main.call("_additive")
	(main.get("fx_layer") as Node).add_child(s)
	(main.get("glows") as Array).append([s, 0.5])


func _spider(node: Node2D, tex: String, at: Vector2) -> void:
	var sp: Node2D = Node2D.new()
	sp.set_script(load("res://spider_friend.gd"))
	node.add_child(sp)
	sp.call("setup", tex, at)
	sp.set("blocked", Callable(main, "is_blocked"))
	main.call("add_caster", sp.get("spr") as Sprite2D, true)


## Девочка-паук: живёт в логове, гуляет по поляне (поведение как у жителей-кошек)
func _girl(node: Node2D, at: Vector2) -> void:
	var c: Node2D = Node2D.new()
	c.set_script(load("res://catgirl.gd"))
	node.add_child(c)
	c.call("setup", "spidergirl", at)
	c.set("roam", 170.0)
	c.set("blocked", Callable(main, "is_blocked"))
	var sp: Sprite2D = c.get("spr") as Sprite2D
	main.call("add_caster", sp, true)
	sp.material = main.call("char_light_mat", Vector2(8, 8), sp)
	var fm: ShaderMaterial = main.call("char_light_mat", Vector2(1, 1), sp)
	fm.set_shader_parameter("region_mode", true)
	(c.get("face") as Sprite2D).material = fm
	c.set("face_mat", fm)

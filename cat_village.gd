extends Node
## Деревня кошкодевочек — регион (0, 1), сразу к югу от двора по тропе.
## Площадь с фонтаном-кошкой, домики с ушками на крыше, рыба сушится, клубки, когтеточки,
## лавка с рыбой и молоком, фонари. Кошкодевочки гуляют у своих домиков.

const REGION: Vector2i = Vector2i(-1, 3)
const PLAZA: Vector2 = Vector2(-940, 4470)
# дом: [картинка, точка «ног» (низ фундамента)]
const HOUSES: Array = [
	["cat_house_a", Vector2(-1220, 4260)], ["cat_house_b", Vector2(-650, 4260)],
	["cat_house_c", Vector2(-1380, 4550)], ["cat_house_d", Vector2(-1190, 4820)],
	["cat_house_b", Vector2(-670, 4820)], ["cat_house_d", Vector2(-380, 4280)],
	["cat_house_c", Vector2(-360, 4850)],
]
const GIRLS: Array = [
	["catgirl_mira", Vector2(-1020, 4440)], ["catgirl_ryzhik", Vector2(-850, 4520)],
	["catgirl_snow", Vector2(-1220, 4330)], ["catgirl_smoky", Vector2(-650, 4330)],
	["catgirl_choco", Vector2(-1360, 4620)], ["catgirl_cream", Vector2(-670, 4890)],
]

var main: Node2D
var world: Node2D


func setup(m: Node2D, w: Node2D) -> void:
	main = m
	world = w
	var b: Dictionary = world.get("builders")
	b[REGION] = Callable(self, "build")


func build(node: Node2D, r: Vector2i) -> void:
	# площадь — плоская, под всеми
	var pl: Sprite2D = Sprite2D.new()
	pl.texture = load("res://art/cat_plaza.png")
	pl.position = PLAZA
	pl.z_index = -10
	node.add_child(pl)
	world.call("reserve", Rect2(PLAZA - Vector2(200, 120), Vector2(400, 240)))
	# фонтан с каменной кошкой
	world.call("put", node, r, "cat_fountain", PLAZA + Vector2(0, 20), 0.0, 0.0)
	world.call("add_block", PLAZA + Vector2(0, 8), 40.0)
	# домики: стены и фундамент — препятствие, перед дверью место свободно
	for h in HOUSES:
		var hp: Vector2 = h[1]
		world.call("put", node, r, String(h[0]), hp, 0.0, 0.0)
		world.call("add_block_rect", Rect2(hp.x - 76, hp.y - 66, 152, 64))
		world.call("reserve", Rect2(hp.x - 110, hp.y - 200, 220, 260))
	# лавка с рыбой и молоком на краю площади
	world.call("put", node, r, "cat_stall", PLAZA + Vector2(150, -70), 0.0, 0.0)
	world.call("add_block_rect", Rect2(PLAZA.x + 104, PLAZA.y - 96, 92, 26))
	world.call("put", node, r, "milk_cans", PLAZA + Vector2(206, -66), 0.0, 9.0)
	# скамейки и фонари вокруг площади
	for bp in [PLAZA + Vector2(-120, 62), PLAZA + Vector2(120, 62)]:
		world.call("put", node, r, "bench", bp, 0.0, 0.0)
		world.call("add_block_rect", Rect2((bp as Vector2).x - 30, (bp as Vector2).y - 18, 60, 18))
	for lp in [PLAZA + Vector2(-70, -110), PLAZA + Vector2(70, -110), PLAZA + Vector2(-170, 30), PLAZA + Vector2(170, 30)]:
		world.call("put", node, r, "lantern", lp, 0.0, 6.0)
		_glow((lp as Vector2) + Vector2(8, -46))
	# мелочи у домиков
	var props: Array = [
		["fish_rack", Vector2(-1080, 4290), 0.0], ["fish_rack", Vector2(-510, 4650), 0.0],
		["yarn_basket", Vector2(-1280, 4290), 0.0], ["yarn_basket", Vector2(-590, 4300), 0.0], ["yarn_basket", Vector2(-1310, 4580), 0.0],
		["cat_tower", Vector2(-1100, 4850), 8.0], ["cat_tower", Vector2(-770, 4850), 8.0], ["cat_tower", Vector2(-470, 4320), 8.0],
		["cushion", Vector2(-1050, 4550), 0.0], ["cushion", Vector2(-820, 4420), 0.0],
		["barrel", Vector2(-300, 4300), 9.0], ["barrel", Vector2(-1460, 4570), 9.0],
	]
	for pr in props:
		world.call("put", node, r, String(pr[0]), pr[1], 0.0, float(pr[2]))
	# цветущие деревья вокруг деревни
	for tp in [Vector2(-1450, 4180), Vector2(-460, 4160), Vector2(-1540, 4790), Vector2(-200, 4640), Vector2(-820, 4120), Vector2(-1360, 4980), Vector2(-540, 5000)]:
		world.call("put", node, r, "tree_blossom", tp, 0.5, 12.0)
	# кошкодевочки
	for g in GIRLS:
		_girl(node, String(g[0]), g[1])


func _glow(at: Vector2) -> void:
	var s: Sprite2D = Sprite2D.new()
	s.texture = load("res://art/fx_glow.png")
	s.position = at
	s.scale = Vector2.ONE * 0.75
	s.modulate = Color(1.0, 0.72, 0.38, 0.0)
	s.material = main.call("_additive")
	(main.get("fx_layer") as Node).add_child(s)
	(main.get("glows") as Array).append([s, 0.55])


func _girl(node: Node2D, name: String, at: Vector2) -> void:
	var c: Node2D = Node2D.new()
	c.set_script(load("res://catgirl.gd"))
	node.add_child(c)
	c.call("setup", name, at)
	c.set("blocked", Callable(main, "is_blocked"))
	var sp: Sprite2D = c.get("spr") as Sprite2D
	main.call("add_caster", sp, true)
	sp.material = main.call("char_light_mat", Vector2(8, 8), sp)
	var fm: ShaderMaterial = main.call("char_light_mat", Vector2(1, 1), sp)
	fm.set_shader_parameter("region_mode", true)
	(c.get("face") as Sprite2D).material = fm
	c.set("face_mat", fm)

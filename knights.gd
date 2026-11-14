extends Node
## Рыцарские земли — регионы (2,0), (3,0), (2,1), (3,-1) к востоку.
## Большой замок у дороги, аллея знамён, турнирное поле с барьером и шатрами,
## тренировочный двор (чучела, мишени, стойки с оружием, сено), лагерь, северный форт.
## Девушки-рыцари в латах и оруженосец гуляют у своих мест.

const CASTLE: Vector2 = Vector2(6720, 1870)
const YARD: Vector2 = Vector2(6270, 2290)
const JOUST: Vector2 = Vector2(7240, 2280)
const CAMP: Vector2 = Vector2(8920, 2180)
const FORT: Vector2 = Vector2(8520, 760)

var main: Node2D
var world: Node2D


func setup(m: Node2D, w: Node2D) -> void:
	main = m
	world = w
	var b: Dictionary = world.get("builders")
	b[Vector2i(3, 1)] = Callable(self, "build_castle")
	b[Vector2i(4, 1)] = Callable(self, "build_camp")
	b[Vector2i(4, 0)] = Callable(self, "build_fort")
	b[Vector2i(3, 2)] = Callable(self, "build_road")


func _put(node: Node2D, r: Vector2i, tex: String, p: Vector2, block: float = 0.0, flip: int = -1) -> Sprite2D:
	var s: Sprite2D = world.call("put", node, r, tex, p, 0.0, block, Color.WHITE, true)
	if flip >= 0:
		s.flip_h = flip == 1
	return s


func build_castle(node: Node2D, r: Vector2i) -> void:
	# замок
	world.call("reserve", Rect2(CASTLE - Vector2(260, 420), Vector2(520, 470)))
	_put(node, r, "knight_castle", CASTLE, 0.0, 0)
	world.call("add_block_rect", Rect2(CASTLE.x - 214, CASTLE.y - 160, 428, 150))
	_windows(CASTLE, [Vector2(-40, -230), Vector2(0, -230), Vector2(40, -230)])
	_girl(node, "knight_sera", CASTLE + Vector2(-60, 50), 80.0)
	# аллея знамён по дороге к воротам
	for k in range(4):
		for sx in [-48, 48]:
			_put(node, r, "banner_pole", Vector2(CASTLE.x + float(sx), CASTLE.y + 170.0 + k * 150.0), 4.0, 0 if sx > 0 else 1)
	# тренировочный двор
	world.call("reserve", Rect2(YARD - Vector2(220, 150), Vector2(440, 300)))
	for dp in [Vector2(-140, -60), Vector2(-60, -70), Vector2(20, -60)]:
		_put(node, r, "dummy", YARD + dp, 7.0, 0)
	for tp in [Vector2(120, -80), Vector2(170, 10)]:
		_put(node, r, "archery_target", YARD + tp, 8.0, 0)
	for wp in [Vector2(-170, 70), Vector2(-90, 90)]:
		_put(node, r, "weapon_rack", YARD + wp, 10.0, 0)
	for hp in [Vector2(30, 80), Vector2(70, 96), Vector2(50, 60)]:
		_put(node, r, "hay_bale", YARD + hp, 9.0)
	_girl(node, "squire_tilly", YARD + Vector2(-40, 10), 110.0)
	# турнирное поле: барьер посередине, шатры по краям, знамёна по углам
	world.call("reserve", Rect2(JOUST - Vector2(330, 170), Vector2(660, 340)))
	for k2 in range(3):
		_put(node, r, "tilt_fence", JOUST + Vector2(-120 + k2 * 120, 0), 0.0, 0)
		world.call("add_block_rect", Rect2(JOUST.x - 180 + k2 * 120, JOUST.y - 12, 120, 12))
	_put(node, r, "tent_red", JOUST + Vector2(-270, -40), 0.0, 0)
	world.call("add_block_rect", Rect2(JOUST.x - 308, JOUST.y - 80, 76, 34))
	_put(node, r, "tent_blue", JOUST + Vector2(270, 40), 0.0, 0)
	world.call("add_block_rect", Rect2(JOUST.x + 232, JOUST.y, 76, 34))
	for bp in [Vector2(-200, -120), Vector2(200, -120), Vector2(-200, 130), Vector2(200, 130)]:
		_put(node, r, "banner_pole", JOUST + bp, 4.0, 0)
	_put(node, r, "hay_bale", JOUST + Vector2(-260, 60), 9.0)
	_put(node, r, "weapon_rack", JOUST + Vector2(250, -60), 10.0, 0)
	_girl(node, "knight_aria", JOUST + Vector2(-60, -50), 150.0)


func build_camp(node: Node2D, r: Vector2i) -> void:
	world.call("reserve", Rect2(CAMP - Vector2(220, 160), Vector2(440, 320)))
	for tp in [[Vector2(-130, -50), "tent_red"], [Vector2(20, -90), "tent_blue"], [Vector2(150, -30), "tent_red"]]:
		var p: Vector2 = CAMP + (tp[0] as Vector2)
		_put(node, r, String(tp[1]), p, 0.0, 0)
		world.call("add_block_rect", Rect2(p.x - 38, p.y - 40, 76, 34))
	_put(node, r, "banner_pole", CAMP + Vector2(-40, 40), 4.0, 0)
	_put(node, r, "weapon_rack", CAMP + Vector2(110, 70), 10.0, 0)
	_put(node, r, "hay_bale", CAMP + Vector2(-150, 70), 9.0)
	_put(node, r, "barrel", CAMP + Vector2(-110, 90), 9.0)
	_girl(node, "knight_sera", CAMP + Vector2(0, 40), 140.0)


func build_fort(node: Node2D, r: Vector2i) -> void:
	world.call("reserve", Rect2(FORT - Vector2(160, 330), Vector2(320, 380)))
	_put(node, r, "knight_fort", FORT, 0.0, 0)
	world.call("add_block_rect", Rect2(FORT.x - 104, FORT.y - 120, 208, 110))
	_windows(FORT, [Vector2(-26, -158), Vector2(26, -158)])
	for sx in [-70, 70]:
		_put(node, r, "banner_pole", FORT + Vector2(sx, 70), 4.0, 0)
	_girl(node, "knight_vera", FORT + Vector2(0, 60), 110.0)


func build_road(node: Node2D, r: Vector2i) -> void:
	# знамёна вдоль дороги от деревни кошек к замку
	for p in [Vector2(6220, 2730), Vector2(6420, 2680)]:
		_put(node, r, "banner_pole", p, 4.0, 0)


func _windows(at: Vector2, offs: Array) -> void:
	for o in offs:
		var s: Sprite2D = Sprite2D.new()
		s.texture = load("res://art/fx_glow.png")
		s.position = at + (o as Vector2)
		s.scale = Vector2.ONE * 0.3
		s.modulate = Color(1.0, 0.68, 0.36, 0.0)
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
	main.call("add_caster", sp, true)
	sp.material = main.call("char_light_mat", Vector2(8, 8), sp)
	var fm: ShaderMaterial = main.call("char_light_mat", Vector2(1, 1), sp)
	fm.set_shader_parameter("region_mode", true)
	(c.get("face") as Sprite2D).material = fm
	c.set("face_mat", fm)

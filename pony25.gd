extends Node
## v25: Эквестрия на севере (регионы (2..4,-7..-5)). В центре — город Понивилль (towns.gd, земля "ponies"),
## вокруг — ферма Эпплов с садом, коттедж Флаттершай со зверьками, библиотека-дерево, Кантерлот,
## облачный домик и стадион Чудо-молний, хижина Зекоры в лесу Вечнодиком, каменная ферма Пай.
## Пони живут здесь в облике девушек. Подружись со всей шестёркой — принцесса Селестия откроет стихию «Тайна».

const WD = preload("res://world_data.gd")
const TOWN: Vector2 = Vector2(6100, -7000)
const MANE6: Array = ["pony_twilight", "pony_rarity", "pony_pinkie", "pony_applejack", "pony_rainbow", "pony_fluttershy"]
const LIBRARY: Vector2 = Vector2(7450, -6500)
const BARN: Vector2 = Vector2(4560, -6720)
const COTTAGE: Vector2 = Vector2(4380, -7480)
const CANTERLOT: Vector2 = Vector2(6700, -8300)
const CLOUD: Vector2 = Vector2(5000, -8380)
const HUT: Vector2 = Vector2(4300, -8760)
const ROCKS: Vector2 = Vector2(8500, -6900)

var main: Node2D
var world: Node2D


func setup(m: Node2D, w: Node2D) -> void:
	main = m
	world = w
	var b: Dictionary = world.get("builders")
	for r in [Vector2i(2, -6), Vector2i(3, -7), Vector2i(2, -7), Vector2i(4, -6), Vector2i(3, -6)]:
		if b.has(r):
			var old: Callable = b[r]
			var mine: Callable = Callable(self, "build")
			b[r] = func(node: Node2D, rr: Vector2i) -> void:
				old.call(node, rr)
				mine.call(node, rr)
		else:
			b[r] = Callable(self, "build")


func _put(node: Node2D, r: Vector2i, tex: String, p: Vector2, block: float = 0.0, tint: Color = Color.WHITE) -> Sprite2D:
	return world.call("put", node, r, tex, p, 0.0, block, tint, true)


func _house(node: Node2D, r: Vector2i, tex: String, p: Vector2) -> void:
	var t: Texture2D = load("res://art/%s.png" % tex)
	var w: float = float(t.get_width())
	world.call("reserve", Rect2(p - Vector2(w * 0.5 + 40, t.get_height() + 20), Vector2(w + 80, t.get_height() + 120)))
	_put(node, r, tex, p)
	world.call("add_block_rect", Rect2(p.x - w * 0.5 + 12, p.y - 60, w - 24, 56))


func _girl(node: Node2D, name: String, at: Vector2, roam: float) -> Node2D:
	if not ResourceLoader.exists("res://art/%s.png" % name):
		return null
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
	return c


func build(node: Node2D, r: Vector2i) -> void:
	var rng: RandomNumberGenerator = world.get("rng")
	match r:
		Vector2i(2, -6):
			# ферма Эпплов: красный амбар, яблоневый сад рядами, стога, забор — на расчищенной поляне
			world.call("reserve", Rect2(3760, -7200, 1140, 620))
			world.call("reserve", Rect2(COTTAGE.x - 300, COTTAGE.y - 200, 600, 460))
			_house(node, r, "pony_barn", BARN)
			for row in range(3):
				for col in range(5):
					var tp: Vector2 = Vector2(3880 + col * 120 + (row % 2) * 60, -7020 + row * 150)
					world.call("reserve", Rect2(tp - Vector2(50, 140), Vector2(100, 150)))
					_put(node, r, "tree_apple", tp, 10.0)
			for k in range(6):
				_put(node, r, "fence", BARN + Vector2(-200 + k * 34, 70), 0.0)
			for hb in [BARN + Vector2(170, 40), BARN + Vector2(210, 70), BARN + Vector2(-190, 20)]:
				_put(node, r, "hay_bale", hb, 9.0)
			_girl(node, "pony_applejack", BARN + Vector2(-40, 60), 140.0)
			_girl(node, "pony_applebloom", BARN + Vector2(40, 80), 160.0)
			_girl(node, "pony_babs", Vector2(4200, -6800), 160.0)
			_girl(node, "pony_cherry", Vector2(4000, -6560), 120.0)
			# коттедж Флаттершай: вокруг много зверушек
			_house(node, r, "pony_cottage", COTTAGE)
			for fb in [COTTAGE + Vector2(-120, 30), COTTAGE + Vector2(110, 40)]:
				_put(node, r, "flower_bed", fb, 0.0)
			_girl(node, "pony_fluttershy", COTTAGE + Vector2(0, 60), 120.0)
			var wl: Node = main.get_node_or_null("Wilds")
			for k2 in range(8):
				var kind: String = ["rabbit", "squirrel", "duck", "hedgehog", "lop_rabbit", "chipmunk", "frog", "otter"][k2]
				var ap: Vector2 = COTTAGE + Vector2(rng.randf_range(-220, 220), rng.randf_range(40, 200))
				if wl != null and wl.has_method("_animal"):
					wl.call("_animal", node, kind, ap)
		Vector2i(3, -6):
			# библиотека в дереве (как «Золотой дуб»)
			world.call("reserve", Rect2(LIBRARY - Vector2(200, 470), Vector2(400, 560)))
			_put(node, r, "elf_great_tree", LIBRARY, 0.0, Color(1.04, 1.0, 0.92))
			world.call("add_block", LIBRARY + Vector2(0, -16), 42.0)
			_girl(node, "pony_twilight", LIBRARY + Vector2(-30, 60), 120.0)
			_girl(node, "pony_starlight", LIBRARY + Vector2(60, 70), 150.0)
			_girl(node, "pony_sunset", LIBRARY + Vector2(-110, 90), 160.0)
			_girl(node, "pony_moondancer", LIBRARY + Vector2(120, 40), 100.0)
			_girl(node, "pony_trixie", LIBRARY + Vector2(-200, 160), 220.0)
			# у лавок и кондитерской Понивилля — Рарити, Пинки и пекари
			var hw: float = 18.0
			var shop: Vector2 = TOWN + Vector2(330, 50 - hw - 16)
			var tav: Vector2 = TOWN + Vector2(-420, 70 - hw - 16)
			_girl(node, "pony_rarity", shop + Vector2(-40, 50), 80.0)
			_girl(node, "pony_coco", shop + Vector2(40, 60), 80.0)
			_girl(node, "pony_sapphire", shop + Vector2(260, 60), 120.0)
			_girl(node, "pony_photo", shop + Vector2(200, 90), 120.0)
			_girl(node, "pony_pinkie", tav + Vector2(0, 50), 160.0)
			_girl(node, "pony_cake", tav + Vector2(-50, 60), 60.0)
			_girl(node, "pony_sugarbelle", tav + Vector2(60, 70), 80.0)
			_girl(node, "pony_redheart", TOWN + Vector2(-300, 360), 120.0)
			for k3 in range(4):
				_girl(node, ["pony_sweetie", "pony_diamond", "pony_silver", "pony_cozy"][k3], TOWN + Vector2(-220 + k3 * 60, 520), 200.0)
		Vector2i(3, -7):
			# Кантерлот: белый замок принцесс
			world.call("reserve", Rect2(CANTERLOT - Vector2(260, 400), Vector2(520, 500)))
			_put(node, r, "knight_castle", CANTERLOT, 0.0, Color(1.12, 1.05, 1.18))
			world.call("add_block_rect", Rect2(CANTERLOT.x - 200, CANTERLOT.y - 90, 400, 86))
			_girl(node, "pony_luna", CANTERLOT + Vector2(-40, 70), 80.0)
			_girl(node, "pony_cadance", CANTERLOT + Vector2(40, 70), 80.0)
			_girl(node, "pony_tempest", CANTERLOT + Vector2(-160, 110), 140.0)
			_girl(node, "pony_coloratura", CANTERLOT + Vector2(160, 110), 140.0)
		Vector2i(2, -7):
			# облачный домик Рейнбоу и Чудо-молнии
			_house(node, r, "pony_cloud_house", CLOUD)
			_girl(node, "pony_rainbow", CLOUD + Vector2(0, 60), 180.0)
			_girl(node, "pony_scootaloo", CLOUD + Vector2(60, 80), 200.0)
			_girl(node, "pony_spitfire", CLOUD + Vector2(-90, 70), 160.0)
			_girl(node, "pony_gilda", CLOUD + Vector2(140, 40), 160.0)
			# лес Вечнодикий: мёртвые деревья и хижина Зекоры
			_house(node, r, "pony_hut", HUT)
			for k4 in range(14):
				var dp: Vector2 = HUT + Vector2(rng.randf_range(-600, 600), rng.randf_range(-500, 300))
				if dp.distance_to(HUT) > 180.0 and bool(world.call("free_at", dp, 30.0, 16.0)):
					_put(node, r, "dead_tree_a" if k4 % 2 == 0 else "dead_tree_b", dp, 8.0)
			_girl(node, "pony_zecora", HUT + Vector2(0, 60), 80.0)
			_girl(node, "pony_daring", HUT + Vector2(-300, 120), 300.0)
			_girl(node, "pony_chrysalis", HUT + Vector2(380, -200), 200.0)
		Vector2i(4, -6):
			# каменная ферма сестёр Пай
			for k5 in range(10):
				var rp: Vector2 = ROCKS + Vector2(rng.randf_range(-260, 260), rng.randf_range(-160, 160))
				if bool(world.call("free_at", rp, 26.0, 16.0)):
					_put(node, r, "rock_big" if k5 % 3 == 0 else "ore_rock", rp, 14.0)
			_girl(node, "pony_maud", ROCKS + Vector2(0, 40), 120.0)
			_girl(node, "pony_limestone", ROCKS + Vector2(80, 60), 140.0)
			_girl(node, "pony_marble", ROCKS + Vector2(-80, 60), 100.0)


## Подружилась с пони (поговорила): вся шестёрка — Селестия дарит стихию «Тайна»
func met(tex: String) -> void:
	if not tex.begins_with("pony_") or Game.ponies_met.has(tex):
		return
	Game.ponies_met[tex] = Game.day
	var n: int = 0
	for m in MANE6:
		if Game.ponies_met.has(m):
			n += 1
	if MANE6.has(tex):
		Game.toast.emit("Подружилась: %s (%d из 6)" % [String(preload("res://npc_db.gd").person(tex)[0]), n], load("res://art/fx_heart.png"))
	if n >= 6 and not Game.orbs_open.has("arcane"):
		Game.orbs_open.append("arcane")
		Sound.play("cast_arcane", -2.0)
		Game.toast.emit("Магия дружбы! Принцесса Селестия дарит стихию «Тайна».", load("res://art/orb25_arcane.png"))
		Game.chron("Подружилась со всей шестёркой Понивилля. Принцесса Селестия подарила стихию Тайны.", "magic")

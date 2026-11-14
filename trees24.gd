extends Node
## v24: деревья падают целиком. Пень остаётся, дерево с ветками лежит (felled24.gd). Обрубить ветки → длинные
## ветки (из них на пилораме/верстаке — короткие палки), хворост, листья. Голый ствол: порубить на поленья
## или поднять и нести. Ствол тяжёлый: одной не поднять, вдвоём — медленно, впятером — легко.
## Стволы складываются в штабель (pile24.gd) — как на лесном складе.

const IT = preload("res://items_db.gd")
const MT = preload("res://mats_db.gd")
const TD = preload("res://tree_db.gd")

var main: Node2D
var v24: Node
var objs: Node
# переноска
var carry_src: Dictionary = {}       # что несём: {"fam"}
var carry_spr: Sprite2D = null
var crew: Array = []                 # работницы, что несут вместе с героиней
var gathering: float = 0.0           # ждём, пока помощницы подойдут
var gather_rec: Dictionary = {}
var gather_node: Node2D = null
var t: float = 0.0


func setup(m: Node2D, v: Node) -> void:
	main = m
	v24 = v
	objs = main.get("objects")
	add_to_group("trees24")
	for r in Game.felled:
		_spawn_felled(r, false, false)
	for p in Game.piles:
		_spawn_pile(p)


func foot(tex: String, t2: Texture2D) -> float:
	var F: Dictionary = main.get("FOOT")
	return float(F.get(tex, t2.get_height()))


static func fam_of(tex: String) -> String:
	if tex.begins_with("pine"):
		return "pine"
	if tex == "tree_birch":
		return "birch"
	if tex.begins_with("dead"):
		return "dead"
	if tex in ["tree_blossom", "tree_unicorn"]:
		return "pink"
	return "oak"


# ------------------------------------------------------------------ падение

## Дерево срублено: вместо исчезновения — падает целиком. dir: 1 вправо, -1 влево.
func fell(t2: Sprite2D, dir: float) -> Node2D:
	var base: Vector2 = t2.global_position
	var tex: String = t2.texture.resource_path.get_file().get_basename()
	var r: Dictionary = {"tex": tex, "fam": fam_of(tex), "x": base.x, "y": base.y + 2.0, "dir": dir, "state": "crown", "hits": 0}
	Game.felled.append(r)
	var flip: bool = t2.flip_h
	t2.queue_free()
	return _spawn_felled(r, true, flip)


func _spawn_felled(r: Dictionary, animate: bool, flip: bool) -> Node2D:
	var n: Node2D = Node2D.new()
	n.set_script(load("res://felled24.gd"))
	objs.add_child(n)
	n.call("setup", r, self, animate, flip)
	return n


func _spawn_pile(p: Dictionary) -> Node2D:
	var n: Node2D = Node2D.new()
	n.set_script(load("res://pile24.gd"))
	objs.add_child(n)
	n.call("setup", p, self)
	return n


func _forget_felled(n: Node2D) -> void:
	Game.felled.erase(n.get("rec"))
	n.queue_free()


## Ветки обрублены: длинные ветки, хворост, листья (кто рубил — тому и в руки, работница несёт в сундук)
func drop_trim(n: Node2D, by: Node2D) -> void:
	var r: Dictionary = n.get("rec")
	var got: Array = [["branch_long", randi_range(2, 4)], ["twig", randi_range(1, 3)]]
	var tree: String = String(r["tex"])
	var leaf: String = "leaf_" + tree
	if IT.is_leaf(leaf):
		got.append([leaf, randi_range(2, 5)])
	if tree.begins_with("pine"):
		got.append(["resin", randi_range(0, 2)])
	_give(got, n, by)


## Ствол порублен на поленья
func drop_logs(n: Node2D, by: Node2D) -> void:
	var r: Dictionary = n.get("rec")
	var got: Array = [["log", randi_range(3, 5)]]
	for ex in MT.CHOP_EXTRA.get(String(r["tex"]), []):
		if String(ex[0]) == "twig":
			continue
		if randf() <= float(ex[3]):
			got.append([String(ex[0]), randi_range(int(ex[1]), int(ex[2]))])
	Sound.play("tree_thud", -10.0, 0.2, n.global_position)
	Game.fx.emit(n.call("center"), "chips")
	_give(got, n, by)
	_forget_felled(n)


func _give(got: Array, n: Node2D, by: Node2D) -> void:
	var pl: Node2D = main.get("player")
	if by == pl or by == null:
		var hs: Node = main.get("homestead")
		var i: int = 0
		for g in got:
			for k in range(int(g[1])):
				var id: String = String(g[0])
				hs.call("_drop", id, String(IT.icon(id).resource_path.get_file().get_basename()) if IT.icon(id) != null else "icon_pack", (n.call("point_near", pl.global_position) as Vector2) + Vector2(randf_range(-20, 20), 6), 0.2 + i * 0.07)
				i += 1
	else:
		# работница: кладёт себе в охапку, потом несёт в сундук
		var w24: Node = get_tree().get_first_node_in_group("workers24")
		if w24 != null:
			for g in got:
				w24.call("load_up", by, String(g[0]), int(g[1]))


# ------------------------------------------------------------------ героиня у дерева / ствола / штабеля

func _has_axe() -> bool:
	return Game.worn("main1") == "axe" or Game.worn("main2") == "axe" or Game.get_count("axe") > 0 or (main.get("homestead") as Node).call("in_hand") == "axe"


func on_felled_interact(n: Node2D) -> void:
	var r: Dictionary = n.get("rec")
	var pl: Node2D = main.get("player")
	if String(r["state"]) == "crown":
		if not _has_axe():
			pl.call("react", "pout", 0.8)
			n.set("shake_t", 0.25)
			return
		_swing(pl)
		n.call("hit", pl)
		return
	# голый ствол: меню
	var face: Texture2D = load("res://art/trunk24_%s.png" % String(r["fam"]))
	var opts: Array = []
	if _has_axe():
		opts.append(["Рубить на поленья", func() -> void: _chop_trunk(n)])
	opts.append(["Поднять и нести (%s)" % _crew_word(), func() -> void: try_lift(n, {})])
	opts.append(["Оставить", func() -> void: pass])
	v24.call("talk_menu", face, "Ствол", "", opts)


func on_pile_interact(p: Node2D) -> void:
	var r: Dictionary = p.get("rec")
	var face: Texture2D = load("res://art/logpile24_%d.png" % clampi(int(r["n"]), 1, 10))
	var opts: Array = []
	if _has_axe():
		opts.append(["Взять ствол и порубить на поленья", func() -> void:
			_take_from_pile(p)
			var tmp: Dictionary = {"tex": "tree_a", "fam": String(r.get("fam", "oak")), "x": p.global_position.x + 30.0, "y": p.global_position.y + 30.0, "dir": 1.0, "state": "trunk", "hits": 0}
			Game.felled.append(tmp)
			_spawn_felled(tmp, false, false)])
	opts.append(["Снять ствол и нести (%s)" % _crew_word(), func() -> void: try_lift(p, r)])
	opts.append(["Оставить", func() -> void: pass])
	v24.call("talk_menu", face, "Штабель брёвен", "", opts)


func _crew_word() -> String:
	var n: int = helpers_near(main.get("player").global_position).size()
	if n == 0:
		return "одной не поднять"
	return "вас будет %d" % (n + 1)


func _swing(pl: Node2D) -> void:
	var hs: Node = main.get("homestead")
	hs.set("swing_t", 0.32)
	pl.call("react", "pout", 0.4)


func _chop_trunk(n: Node2D) -> void:
	# несколько ударов подряд
	var pl: Node2D = main.get("player")
	Game.busy = true
	for i in range(6):
		await get_tree().create_timer(0.42).timeout
		if not is_instance_valid(n):
			break
		_swing(pl)
		if bool(n.call("hit", pl)):
			break
	Game.busy = false


func _take_from_pile(p: Node2D) -> void:
	var r: Dictionary = p.get("rec")
	r["n"] = int(r["n"]) - 1
	if int(r["n"]) <= 0:
		Game.piles.erase(r)
		p.queue_free()
	else:
		p.call("refresh")


# ------------------------------------------------------------------ переноска

## Свободные работницы рядом (не спят, не несут уже, недалеко)
func helpers_near(at: Vector2) -> Array:
	var out: Array = []
	var w24: Node = get_tree().get_first_node_in_group("workers24")
	if w24 == null:
		return out
	for w in (w24.call("free_workers") as Array):
		if (w as Node2D).global_position.distance_to(at) < 900.0:
			out.append(w)
	out.sort_custom(func(a: Node2D, b: Node2D) -> bool: return a.global_position.distance_to(at) < b.global_position.distance_to(at))
	return out.slice(0, 5)


func carrying() -> bool:
	return carry_spr != null


## Поднять ствол (src — лежащий ствол или штабель). Одной нельзя.
func try_lift(src: Node2D, pile_rec: Dictionary) -> void:
	if carrying() or gathering > 0.0:
		return
	var pl: Node2D = main.get("player")
	var hp: Array = helpers_near(pl.global_position)
	if hp.is_empty():
		# пыжится, ствол даже не шелохнулся
		pl.call("react", "pout", 1.4)
		Sound.play("grunt", -6.0, 0.15)
		if src.has_method("hit"):
			src.set("shake_t", 0.4)
		Game.fx.emit(pl.global_position + Vector2(10, -56), "water")
		return
	crew = hp
	gathering = 6.0
	gather_node = src
	gather_rec = pile_rec
	var w24: Node = get_tree().get_first_node_in_group("workers24")
	var at: Vector2 = src.global_position
	for i in range(crew.size()):
		var w: Node2D = crew[i]
		w24.call("summon", w, at + Vector2(randf_range(-30, 30) + float(i) * 18.0, 14.0), "carry")
		w24.call("say_line", w, "help_carry")


func _start_carry() -> void:
	gathering = 0.0
	var fam: String = "oak"
	if is_instance_valid(gather_node):
		if gather_node.has_method("hit"):
			fam = String((gather_node.get("rec") as Dictionary)["fam"])
			_forget_felled(gather_node)
		else:
			fam = String(gather_rec.get("fam", "oak"))
			_take_from_pile(gather_node)
	gather_node = null
	carry_src = {"fam": fam}
	carry_spr = Sprite2D.new()
	carry_spr.texture = load("res://art/trunk24_%s.png" % fam)
	carry_spr.centered = true
	carry_spr.z_index = 3
	objs.add_child(carry_spr)
	Sound.play("grunt", -8.0, 0.2)
	var w24: Node = get_tree().get_first_node_in_group("workers24")
	for w in crew:
		w24.call("set_busy", w, "carry")
	Game.set("carry_speed", carry_speed())


## Скорость с бревном: вдвоём еле идут, впятером — почти как обычно
func carry_speed() -> float:
	var n: int = crew.size() + 1
	return [0.0, 0.0, 0.32, 0.48, 0.66, 0.85, 0.9][clampi(n, 0, 6)]


func _process(delta: float) -> void:
	t += delta
	var pl: Node2D = main.get("player")
	if gathering > 0.0:
		gathering -= delta
		var ready: int = 0
		for w in crew:
			if is_instance_valid(w) and (w as Node2D).global_position.distance_to(pl.global_position) < 130.0:
				ready += 1
		if not is_instance_valid(gather_node):
			gathering = 0.0
			_release()
		elif ready >= crew.size() or gathering <= 0.0:
			# кто не дошёл — догонит
			_start_carry()
	if carry_spr == null:
		return
	# ствол на плечах: поперёк (влево-вправо), чуть покачивается в такт шагам
	var moving: bool = (pl.get("vel") as Vector2).length() > 4.0
	var bob: float = sin(t * 7.0) * (1.5 if moving else 0.3)
	carry_spr.global_position = pl.global_position + Vector2(0, -34 + bob)
	carry_spr.z_index = 3
	var len2: float = carry_spr.texture.get_width() * 0.5 - 6.0
	var slots: Array = []
	var n: int = crew.size()
	for i in range(n):
		var side: float = -1.0 if i % 2 == 0 else 1.0
		var k: float = (1.0 - float(i / 2) * 0.35)
		slots.append(Vector2(side * len2 * k, 4.0 + float(i / 2) * 6.0))
	var w24: Node = get_tree().get_first_node_in_group("workers24")
	for i2 in range(n):
		var w: Node2D = crew[i2]
		if is_instance_valid(w):
			w24.call("hold_at", w, pl.global_position + (slots[i2] as Vector2), moving, pl.get("vel"))
	Game.set("carry_speed", carry_speed())


func _input(event: InputEvent) -> void:
	if carry_spr == null:
		return
	if event is InputEventKey and event.pressed and not event.echo and KB.is_key("interact", (event as InputEventKey).physical_keycode):
		get_viewport().set_input_as_handled()
		drop_carry()


## Положить ствол: рядом штабель — наверх штабеля; рядом лежит другой ствол — начать штабель; иначе на землю
func drop_carry() -> void:
	if carry_spr == null:
		return
	var pl: Node2D = main.get("player")
	var at: Vector2 = pl.global_position + Vector2(0, 26)
	var fam: String = String(carry_src.get("fam", "oak"))
	carry_spr.queue_free()
	carry_spr = null
	Game.set("carry_speed", 1.0)
	Sound.play("tree_thud", -6.0, 0.15, at)
	Game.fx.emit(at, "dust")
	var done: bool = false
	for p in get_tree().get_nodes_in_group("piles24"):
		var pr: Dictionary = (p as Node).get("rec")
		if (p as Node2D).global_position.distance_to(at) < 110.0 and int(pr["n"]) < 10:
			pr["n"] = int(pr["n"]) + 1
			(p as Node).call("refresh")
			done = true
			break
	if not done:
		for f in get_tree().get_nodes_in_group("felled24"):
			var fr: Dictionary = (f as Node).get("rec")
			if String(fr["state"]) == "trunk" and ((f as Node).call("center") as Vector2).distance_to(at) < 90.0:
				var np: Dictionary = {"x": at.x, "y": at.y, "n": 2, "fam": fam}
				Game.piles.append(np)
				_spawn_pile(np)
				_forget_felled(f)
				done = true
				break
	if not done:
		var r: Dictionary = {"tex": "tree_a", "fam": fam, "x": at.x - 52.0, "y": at.y, "dir": 1.0, "state": "trunk", "hits": 0}
		Game.felled.append(r)
		_spawn_felled(r, false, false)
	_release()
	Game.skill_xp("lead", 2.0)


func _release() -> void:
	var w24: Node = get_tree().get_first_node_in_group("workers24")
	for w in crew:
		if is_instance_valid(w) and w24 != null:
			w24.call("set_busy", w, "")
			if randf() < 0.6:
				w24.call("say_line", w, "carry_done")
	crew.clear()


## Работницы сами: штабель у дома (если нет — заводим рядом с первым сундуком/домом)
func pile_spot() -> Vector2:
	for p in get_tree().get_nodes_in_group("piles24"):
		if int(((p as Node).get("rec") as Dictionary)["n"]) < 10:
			return (p as Node2D).global_position
	return Game.home_pos + Vector2(-260, 150)


func add_to_pile(at: Vector2, fam: String) -> void:
	for p in get_tree().get_nodes_in_group("piles24"):
		var pr: Dictionary = (p as Node).get("rec")
		if (p as Node2D).global_position.distance_to(at) < 110.0 and int(pr["n"]) < 10:
			pr["n"] = int(pr["n"]) + 1
			(p as Node).call("refresh")
			return
	var np: Dictionary = {"x": at.x, "y": at.y, "n": 1, "fam": fam}
	Game.piles.append(np)
	_spawn_pile(np)

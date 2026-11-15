extends Node
## Птицы вокруг героини (v20). Каждые пару секунд: сколько птиц должно быть рядом (днём больше, утром — больше всего,
## ночью — совы, козодои, лунные вьюрки), какие виды живут в этом краю (birds_db.for_biome), прилёт новых
## и уход далёких. Кормушки, купалки и присады на дворе приманивают ещё. Перья иногда остаются на земле.

const BDB = preload("res://birds_db.gd")
const WD = preload("res://world_data.gd")

var main: Node2D
var world: Node2D
var tick: float = 0.0
var holder: Node2D


func setup(m: Node2D, w: Node2D) -> void:
	main = m
	world = w
	holder = Node2D.new()
	holder.y_sort_enabled = true
	holder.name = "Birds20"
	(main.get("objects") as Node).add_child(holder)


## Птицы живут только на улице: в шахте, подземельях, аду, пещерах, мирах-сферах, клубе и под водой их нет
func _underground() -> bool:
	if String(Game.realm) != "":
		return true
	var mn: Node = main.get("mine") as Node
	if mn != null and bool(mn.get("inside")):
		return true
	var lv: Node = main.get("live") as Node
	if lv != null and bool(lv.get("active")):
		return true
	var sea: Node = main.get("sea") as Node
	if sea != null and bool(sea.get("diving")):
		return true
	var dn: Node = main.get_node_or_null("V23/Dungeon23")
	if dn != null and bool(dn.get("active")):
		return true
	return false


func _biome(p: Vector2) -> int:
	if Rect2(0, 0, WD.RW, WD.RH).has_point(p):
		return WD.MEADOW
	return WD.biome_at(p)


func _process(delta: float) -> void:
	tick -= delta
	if tick > 0.0:
		return
	tick = 1.5
	var pl: Node2D = main.get("player") as Node2D
	if pl == null:
		return
	var away: bool = bool(main.get("inside")) or main.get("visiting") != null or pl.global_position.y > 90000.0 or pl.global_position.y < -150000.0 or Game.busy or _underground()
	var birds: Array = holder.get_children()
	if away:
		for b in birds:
			(b as Node).queue_free()
		return
	var pp: Vector2 = pl.global_position
	var night: bool = Game.night_factor() > 0.55
	var dusk: bool = Game.golden() > 0.35 and Game.hour() > 15.0
	var biome: int = _biome(pp)
	# далёкие и «не своего времени» улетают
	var alive: int = 0
	for b in birds:
		var bn: Node2D = b as Node2D
		if not bn.is_in_group("birds20"):
			continue   # перья на земле — не птицы
		if bool(bn.get("gone")) or String(bn.get("state")) == "flee":
			continue
		var d: float = bn.global_position.distance_to(pp)
		var bd: Dictionary = BDB.DATA[String(bn.get("bid"))]
		var w: String = String(bd["when"])
		var ok: bool = (w == "day" and not night) or (w == "night" and night) or (w == "dusk" and (dusk or night))
		if d > 1000.0:
			bn.queue_free()
			continue
		if not ok and d > 200.0:
			bn.call("fly_off", pp)
			continue
		alive += 1
	var lst: Array = BDB.for_biome(biome, night, dusk)
	if lst.is_empty():
		return
	var h: float = Game.hour()
	# v25: птиц заметно больше — утром целый хор, днём стайки, ночью пара сов
	var want: int = 2 if night else (8 if (h > 5.0 and h < 10.0) else (6 if h < 18.0 else 5))
	if biome in [WD.SEA, WD.GROTTO]:
		want = mini(want, 3)
	want += int(round(_attract(pp) * 0.7))
	if alive >= want:
		return
	# пусто вокруг (пришла в новый край, начало дня) — сразу несколько, иначе по одной-две
	var n: int = mini(want - alive, 4 if alive == 0 else 2)
	for i in range(n):
		_spawn(lst, pp, night)


## Сколько ещё птиц приманивают кормушки, купалки, присады рядом
func _attract(pp: Vector2) -> float:
	var s: float = 0.0
	for y in get_tree().get_nodes_in_group("yard20"):
		if (y as Node2D).global_position.distance_to(pp) < 600.0:
			s += float(y.call("attracts"))
	return minf(s, 6.0)


func _pick(lst: Array) -> String:
	var tot: float = 0.0
	for e in lst:
		tot += float(e[1])
	var x: float = randf() * tot
	for e in lst:
		x -= float(e[1])
		if x <= 0.0:
			return String(e[0])
	return String(lst[0][0])


## Найти дерево поблизости: [точка ствола, высота кроны] или []
func _tree_near(p: Vector2) -> Array:
	var tall: Dictionary = world.get("tall")
	var c0: Vector2i = Vector2i(int(floor(p.x / 256.0)), int(floor(p.y / 256.0)))
	var cands: Array = []
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			for sv in tall.get(c0 + Vector2i(dx, dy), []):
				if is_instance_valid(sv):
					var s: Sprite2D = sv
					if s.texture != null and preload("res://items_db.gd").is_tree_tex(s.texture.resource_path.get_file().get_basename()):
						cands.append(s)
	for ys in main.get("yard_trees"):
		if is_instance_valid(ys) and (ys as Node2D).global_position.distance_to(p) < 500.0:
			cands.append(ys)
	if cands.is_empty():
		return []
	var s2: Sprite2D = cands[randi() % cands.size()]
	var hh: float = float(s2.texture.get_height()) * s2.scale.y
	return [s2.global_position + Vector2(randf_range(-0.22, 0.22) * float(s2.texture.get_width()), 1.0), hh * randf_range(0.5, 0.75), s2]


## v25: насест поблизости — забор, крыша дома или ветка дерева: [точка у основания, высота]
const ROOF_WORDS: Array = ["house", "hall", "hut", "tavern", "bakery", "palace", "shop", "manor", "minka", "teahouse", "forge", "barn", "cottage", "longhouse", "castle", "tower", "chapel", "mill", "pony_", "boutique", "library"]


func _perch_near(pp: Vector2) -> Array:
	var cands: Array = []
	for f in get_tree().get_nodes_in_group("perch_fence"):
		var fs: Sprite2D = f as Sprite2D
		if is_instance_valid(fs) and fs.is_visible_in_tree():
			var d: float = fs.global_position.distance_to(pp)
			if d > 90.0 and d < 420.0:
				cands.append([fs, "fence"])
	var tall: Dictionary = world.get("tall")
	var c0: Vector2i = Vector2i(int(floor(pp.x / 256.0)), int(floor(pp.y / 256.0)))
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			for sv in tall.get(c0 + Vector2i(dx, dy), []):
				if not is_instance_valid(sv):
					continue
				var s: Sprite2D = sv
				if s.texture == null:
					continue
				var nm: String = s.texture.resource_path.get_file().get_basename()
				var d2: float = s.global_position.distance_to(pp)
				if d2 < 90.0 or d2 > 460.0:
					continue
				if preload("res://items_db.gd").is_tree_tex(nm):
					cands.append([s, "tree"])
				else:
					for w in ROOF_WORDS:
						if nm.contains(String(w)):
							cands.append([s, "roof"])
							break
	if cands.is_empty():
		return []
	var c: Array = cands[randi() % cands.size()]
	var sp: Sprite2D = c[0]
	var tw: float = float(sp.texture.get_width()) * sp.scale.x
	var th: float = float(sp.texture.get_height()) * sp.scale.y
	match String(c[1]):
		"fence":
			return [sp.global_position + Vector2(randf_range(-0.35, 0.35) * tw, 1.0), th * 0.86]
		"roof":
			# конёк и скаты: чем ближе к середине, тем выше
			var k: float = randf_range(-0.28, 0.28)
			return [sp.global_position + Vector2(k * tw, 2.0), th * (0.9 - absf(k) * 0.55)]
		_:
			return [sp.global_position + Vector2(randf_range(-0.22, 0.22) * tw, 1.0), th * randf_range(0.5, 0.75)]


func _spawn(lst: Array, pp: Vector2, night: bool) -> void:
	var id: String = _pick(lst)
	var bd: Dictionary = BDB.DATA[id]
	var perch: String = String(bd["perch"])
	var owl: bool = bool(bd["owl"])
	var at: Vector2 = Vector2.INF
	var h: float = 0.0
	var tree_spr: Sprite2D = null
	# совы ночью — на присаде у дома, если она рядом
	if owl:
		for y in get_tree().get_nodes_in_group("yard20"):
			if String(y.get("kind")) == "owl_post" and (y as Node2D).global_position.distance_to(pp) < 700.0 and randf() < 0.6:
				at = (y as Node2D).global_position + Vector2(randf_range(-6, 6), 1)
				h = 46.0
	if at == Vector2.INF and (perch == "tree" or owl) and randf() < 0.8:
		var a0: float = randf() * TAU
		var tr: Array = _tree_near(pp + Vector2(cos(a0), sin(a0) * 0.6) * randf_range(120.0, 360.0))
		if not tr.is_empty() and (tr[0] as Vector2).distance_to(pp) > 90.0:
			at = tr[0]
			h = float(tr[1])
			tree_spr = tr[2] as Sprite2D
	# v25: и наземные птицы часто садятся повыше — на ветки, заборы, крыши домов
	if at == Vector2.INF and randf() < (0.55 if not owl else 0.4):
		var pr: Array = _perch_near(pp)
		if not pr.is_empty():
			at = pr[0]
			h = float(pr[1])
	if at == Vector2.INF:
		for i in range(10):
			var a: float = randf() * TAU
			# на экране видно ~320 пикселей мира в стороны и ~180 вверх-вниз: садятся и в кадре, и за краем
			var q: Vector2 = (pp + Vector2(cos(a), sin(a) * 0.55) * randf_range(110.0, 380.0)).round()
			if not bool(main.call("is_blocked", q)):
				at = q
				break
	if at == Vector2.INF:
		return
	if at.distance_to(pp) < 100.0:
		return
	var b: Node2D = Node2D.new()
	b.set_script(load("res://bird.gd"))
	b.position = at
	holder.add_child(b)
	# половина прилетает на глазах (из-за края экрана), остальные уже сидят
	var from: Vector2 = Vector2.INF
	if randf() < 0.55:
		from = at + Vector2(randf_range(-1.0, 1.0) * 260.0, -220.0)
	b.call("setup", id, self, from, h)
	if tree_spr != null:
		b.call("tuck_into_tree", tree_spr)


## Перо на земле: подобрать на E
func drop_feather(id: String, at: Vector2) -> void:
	var f: Node2D = Node2D.new()
	f.set_script(load("res://feather_drop.gd"))
	f.position = at + Vector2(randf_range(-6, 6), randf_range(-2, 4))
	holder.add_child(f)
	f.call("setup", id)

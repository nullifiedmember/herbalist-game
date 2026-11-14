extends Node2D
## Камни и руды на земле (v18). Маленькие и средние поднимаются руками (E), большие — руками или киркой,
## огромные валуны и месторождения магических руд ломает только кирка (ЛКМ по камню или E рядом).
## Сам узел — «приманка» для E: подставляет ближайший камень как цель взаимодействия.

const WD = preload("res://world_data.gd")
const MD = preload("res://mining_db.gd")
const IT = preload("res://items_db.gd")

var main: Node2D
var world: Node2D
var hs: Node
var cells: Dictionary = {}          # клетка 256 -> Array[rec]; rec — Dictionary
var ores: Array = []                # месторождения (для мерцания)
var respawns: Array = []            # {due, node, region, id, p}
var interact_offset: Vector2 = Vector2(0, 100000)
var cur: Dictionary = {}
var t: float = 0.0
var scan_t: float = 0.0
var hits_done: int = 0              # для тестов


func setup(m: Node2D, w: Node2D) -> void:
	main = m
	world = w
	add_to_group("interactables")
	add_to_group("rocks18")
	(world.get("region_hooks") as Array).append(Callable(self, "populate"))
	Game.day_changed.connect(_on_new_day)


func _ensure_hs() -> void:
	if hs == null or not is_instance_valid(hs):
		hs = get_tree().get_first_node_in_group("homestead")


# ------------------------------------------------------------------ расстановка

func _cell(p: Vector2) -> Vector2i:
	return Vector2i(int(floor(p.x / 256.0)), int(floor(p.y / 256.0)))


func _near_town(p: Vector2) -> bool:
	for tc in WD.TOWN_C.values():
		if p.distance_to(tc) < WD.TOWN_R + 80.0:
			return true
	return false


func _tex_for(kind: String, biome: int, rng: RandomNumberGenerator) -> String:
	if kind == "h" and biome in [MD.GROTTO, MD.GOTHIC, MD.MAGE, MD.SPIDER]:
		return "rock18_h_%d" % rng.randi_range(0, 2)
	if biome in MD.WARM:
		return "rock18_%s_w%d" % [kind, rng.randi_range(0, 1)]
	return "rock18_%s_%d" % [kind, rng.randi_range(0, 2)]


## Каждая область: камни по плотности биома, потом месторождения руды
func populate(node: Node2D, r: Vector2i) -> void:
	var biome: int = WD.biome_of_region(r)
	if r == Vector2i.ZERO or biome < 0 or biome == WD.SEA:
		return
	var rng: RandomNumberGenerator = world.get("rng")
	var rect: Rect2 = WD.region_rect(r)
	var dens: Array = MD.DENSITY.get(biome, MD.DENSITY_DEFAULT)
	var kinds: Array = ["s", "m", "l", "h"]
	for ki in range(kinds.size()):
		var kind: String = kinds[ki]
		var rad: float = float((MD.SIZES[kind] as Dictionary)["r"])
		var made: int = 0
		var tries: int = 0
		while made < int(dens[ki]) and tries < int(dens[ki]) * 10:
			tries += 1
			var p: Vector2 = Vector2(rng.randf_range(rect.position.x + 40, rect.end.x - 40), rng.randf_range(rect.position.y + 60, rect.end.y - 40)).round()
			if _near_town(p) or not world.call("free_at", p, rad + 10.0, 34.0):
				continue
			add_rock(node, r, kind, p, _tex_for(kind, WD.biome_at(p), rng), "")
			made += 1
	var made_o: int = 0
	var tries_o: int = 0
	while made_o < int(dens[4]) and tries_o < int(dens[4]) * 12:
		tries_o += 1
		var q: Vector2 = Vector2(rng.randf_range(rect.position.x + 60, rect.end.x - 60), rng.randf_range(rect.position.y + 80, rect.end.y - 40)).round()
		if _near_town(q) or not world.call("free_at", q, 40.0, 40.0):
			continue
		var id: String = MD.pick_ore(WD.biome_at(q), rng)
		if id == "":
			continue
		add_ore(node, r, id, q, rng.randi_range(0, 1))
		made_o += 1


## Один камень: спрайт мира + запись для взаимодействия. Возвращает запись.
func add_rock(node: Node2D, r: Vector2i, kind: String, p: Vector2, tex: String, ore_hint: String) -> Dictionary:
	var rad: float = float((MD.SIZES[kind] as Dictionary)["r"])
	var blk: float = rad * 0.8 if kind in ["l", "h"] else 0.0
	var s: Sprite2D = world.call("put", node, r, tex, p, 0.0, blk, Color.WHITE, true)
	var rec: Dictionary = {"spr": s, "kind": kind, "id": ore_hint, "p": p, "hp": int((MD.SIZES[kind] as Dictionary)["hits"]), "r": r, "node": node, "blk": blk, "ore": false}
	_register(rec)
	return rec


func add_ore(node: Node2D, r: Vector2i, id: String, p: Vector2, variant: int) -> Dictionary:
	var s: Sprite2D = world.call("put", node, r, "ore18_%s_%d" % [id, variant], p, 0.0, 22.0, Color.WHITE, true)
	var rec: Dictionary = {"spr": s, "kind": "ore", "id": id, "p": p, "hp": MD.ore_hits(id), "r": r, "node": node, "blk": 22.0, "ore": true, "ph": randf() * 6.28, "var": variant}
	_register(rec)
	ores.append(rec)
	return rec


func _register(rec: Dictionary) -> void:
	var k: Vector2i = _cell(rec["p"])
	if not cells.has(k):
		cells[k] = []
	(cells[k] as Array).append(rec)


## Всё рядом с точкой: записи в радиусе
func near(p: Vector2, rad: float) -> Array:
	var out: Array = []
	var c0: Vector2i = _cell(p)
	var span: int = int(ceil(rad / 256.0))
	for dy in range(-span, span + 1):
		for dx in range(-span, span + 1):
			for rec in cells.get(c0 + Vector2i(dx, dy), []):
				if (rec["p"] as Vector2).distance_to(p) <= rad and is_instance_valid(rec["spr"]):
					out.append(rec)
	return out


# ------------------------------------------------------------------ цель для E

func _process(delta: float) -> void:
	_ensure_hs()
	t += delta
	scan_t -= delta
	if scan_t > 0.0:
		return
	scan_t = 0.1
	var pl: Node2D = main.get("player") as Node2D
	if pl == null or bool(main.get("inside")) or main.get("visiting") != null or (pl.global_position.y > 90000.0 and pl.global_position.y < 120000.0):
		interact_offset = Vector2(0, 100000)
		cur = {}
		return
	# мерцание руды рядом
	var pp: Vector2 = pl.global_position
	for rec in ores:
		if is_instance_valid(rec["spr"]) and (rec["p"] as Vector2).distance_squared_to(pp) < 640000.0:
			(rec["spr"] as Sprite2D).self_modulate = Color.WHITE.lerp(Color(1.25, 1.25, 1.35), 0.5 + 0.5 * sin(t * 2.2 + float(rec["ph"])))
	var best: Dictionary = {}
	var bd: float = 1e9
	for rec in near(pp, 64.0):
		var reach: float = 36.0 + float((MD.SIZES.get(String(rec["kind"]), {"r": 24.0}) as Dictionary)["r"]) * 0.8
		var d: float = (rec["p"] as Vector2).distance_to(pp)
		if d < reach and d < bd:
			bd = d
			best = rec
	cur = best
	if best.is_empty():
		interact_offset = Vector2(0, 100000)
	else:
		interact_offset = (best["p"] as Vector2) + Vector2(0, -8)


func get_prompt() -> String:
	if cur.is_empty():
		return ""
	var k: String = String(cur["kind"])
	if bool(cur["ore"]):
		return "Добыть руду (кирка)" if Game.has_tool("pickaxe") else "Месторождение (нужна кирка)"
	if k == "h":
		return "Расколоть валун (кирка)" if Game.has_tool("pickaxe") else "Огромный валун (нужна кирка)"
	if Game.has_tool("pickaxe") and k == "l":
		return "Раскрошить камень (кирка)"
	return "Поднять камень"


func interact() -> void:
	if cur.is_empty():
		return
	act(cur, false)


## Действие над камнем: кирка бьёт, иначе — поднять руками (если можно)
func act(rec: Dictionary, by_click: bool) -> void:
	var k: String = String(rec["kind"])
	var has_pick: bool = Game.has_tool("pickaxe")
	if has_pick and (k in ["l", "h", "ore"] or by_click):
		hit(rec)
		return
	if bool(rec["ore"]) or k == "h":
		Game.toast.emit("Без кирки не взять", IT.icon("pickaxe"))
		Sound.play("ui_click", -4.0, 0.0)
		get_tree().call_group("player", "react", "pout", 0.8)
		return
	_pick_up(rec)


func _pick_up(rec: Dictionary) -> void:
	var k: String = String(rec["kind"])
	_remove(rec)
	var pl: Node2D = main.get("player") as Node2D
	Sound.play("dig", -8.0, 0.15, rec["p"])
	get_tree().call_group("player", "react", "happy", 0.6)
	Game.add_item("stone_" + k)
	if pl != null:
		Game.fx.emit(rec["p"], "dust")


## Удар киркой
func hit(rec: Dictionary) -> void:
	_ensure_hs()
	if Game.tired():
		get_tree().call_group("player", "react", "sad", 1.4)
		return
	if hs != null:
		hs.set("swing_t", 0.32)
		hs.set("cool", 0.5)
	hits_done += 1
	rec["hp"] = int(rec["hp"]) - 1
	var s: Sprite2D = rec["spr"]
	Sound.play("pick", -2.0, 0.12, rec["p"])
	Game.fx.emit((rec["p"] as Vector2) + Vector2(0, -14), "chips")
	get_tree().call_group("player", "react", "pout", 0.35)
	var tw: Tween = create_tween()
	tw.tween_property(s, "scale", Vector2(1.06, 0.94), 0.05)
	tw.tween_property(s, "scale", Vector2(0.97, 1.03), 0.07)
	tw.tween_property(s, "scale", Vector2.ONE, 0.06)
	if int(rec["hp"]) > 0:
		return
	_break(rec)


func _break(rec: Dictionary) -> void:
	_ensure_hs()
	var k: String = String(rec["kind"])
	var p: Vector2 = rec["p"]
	var biome: int = WD.biome_at(p)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	_remove(rec)
	Sound.play("drum", -6.0, 0.1, p)
	Game.fx.emit(p + Vector2(0, -6), "dust")
	Game.fx.emit(p + Vector2(8, -10), "chips")
	var drops: Array = []     # [предмет, значок, сколько]
	if bool(rec["ore"]):
		var id: String = String(rec["id"])
		drops.append(["ore_" + id, "icon_ore_" + id, rng.randi_range(2, 3) + (1 if rng.randf() < 0.3 else 0)])
		drops.append(["stone_m", "icon_stone_m", 1])
		# месторождение отрастает через несколько дней
		respawns.append({"due": Game.day + rng.randi_range(4, 7), "node": rec["node"], "region": rec["r"], "id": id, "p": p})
	elif k == "h":
		drops.append(["stone_l", "icon_stone_l", rng.randi_range(1, 2)])
		drops.append(["stone_m", "icon_stone_m", rng.randi_range(2, 3)])
		drops.append(["stone_s", "icon_stone_s", rng.randi_range(2, 4)])
		if rng.randf() < 0.14:
			var oid: String = MD.pick_ore(biome, rng)
			if oid != "":
				drops.append(["ore_" + oid, "icon_ore_" + oid, 1])
	elif k == "l":
		drops.append(["stone_m", "icon_stone_m", 2])
		drops.append(["stone_s", "icon_stone_s", rng.randi_range(1, 3)])
	# v20: в больших камнях и валунах — породы своего края, самородки и самоцветы
	if k in ["l", "h"] or bool(rec["ore"]):
		var MT = preload("res://mats_db.gd")
		for ex in MT.ROCK_EXTRA.get(biome, []):
			if rng.randf() < float(ex[1]) * (2.0 if k == "h" else 1.0):
				drops.append([String(ex[0]), String((MT.MATS[String(ex[0])] as Array)[3]), 1])
	var n: int = 0
	for d in drops:
		for i in range(int(d[2])):
			var ang: float = TAU * float(n) / 6.0
			if hs != null:
				hs.call("_drop", String(d[0]), String(d[1]), p + Vector2(cos(ang), sin(ang) * 0.5) * (14.0 + float(i) * 4.0), 0.5 + float(n) * 0.07)
			else:
				Game.add_item(String(d[0]))
			n += 1


## Убрать камень: спрайт, тень и преграду
func _remove(rec: Dictionary) -> void:
	_ensure_hs()
	var s: Sprite2D = rec["spr"]
	var base: Vector2 = rec["p"]
	var k: Vector2i = _cell(base)
	if cells.has(k):
		(cells[k] as Array).erase(rec)
	ores.erase(rec)
	if hs != null and is_instance_valid(s):
		hs.call("_remove_tree", s)
	var wb: Dictionary = world.get("blocks")
	var bk: Vector2i = Vector2i(int(floor(base.x / 96.0)), int(floor(base.y / 96.0)))
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var lst: Array = wb.get(bk + Vector2i(dx, dy), [])
			for i in range(lst.size() - 1, -1, -1):
				var cv: Vector3 = lst[i]
				if Vector2(cv.x, cv.y).distance_to(base + Vector2(0, -2)) < 3.0:
					lst.remove_at(i)
	if is_instance_valid(s):
		var tw: Tween = create_tween()
		tw.tween_property(s, "modulate:a", 0.0, 0.15)
		tw.tween_callback(s.queue_free)
	cur = {}
	interact_offset = Vector2(0, 100000)


func _on_new_day() -> void:
	for i in range(respawns.size() - 1, -1, -1):
		var rs: Dictionary = respawns[i]
		if Game.day < int(rs["due"]):
			continue
		var nd: Node2D = rs["node"]
		if not is_instance_valid(nd):
			respawns.remove_at(i)
			continue
		var pl: Node2D = main.get("player") as Node2D
		if pl != null and pl.global_position.distance_to(rs["p"]) < 260.0:
			continue
		add_ore(nd, rs["region"], String(rs["id"]), rs["p"], randi_range(0, 1))
		respawns.remove_at(i)


## Камень под точкой мира (для клика киркой): по прямоугольнику спрайта, рядом с героиней
func rock_at(wp: Vector2) -> Dictionary:
	var pl: Node2D = main.get("player") as Node2D
	var best: Dictionary = {}
	var bd: float = 1e9
	for rec in near(wp, 70.0):
		var s: Sprite2D = rec["spr"]
		var rc: Rect2 = s.get_rect()
		rc.position += s.global_position
		if rc.grow(2.0).has_point(wp) and (rec["p"] as Vector2).distance_to(pl.global_position) <= 70.0 + float((MD.SIZES.get(String(rec["kind"]), {"r": 24.0}) as Dictionary)["r"]):
			var d: float = wp.distance_to(rec["p"])
			if d < bd:
				bd = d
				best = rec
	return best


func mine_at(wp: Vector2) -> bool:
	var rec: Dictionary = rock_at(wp)
	if rec.is_empty():
		return false
	act(rec, true)
	return true

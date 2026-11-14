extends Node
## v24: работницы работают по-настоящему. Лесорубки идут к настоящему дереву, рубят его (оно падает целиком),
## обрубают ветки, рубят ствол на поленья или вдвоём несут ствол в штабель. Всё добытое они несут в охапке
## и сами раскладывают по сундукам с подходящим назначением (chest_ui.deposit). Некуда класть — подходят
## к героине и просят построить ещё сундуков. Ночью спят в домах королевства. Разговор — окно с лицом и выбором.

const T = preload("res://talk24_db.gd")
const IT = preload("res://items_db.gd")
const NPC = preload("res://npc_db.gd")
const CAP: int = 8                 # сколько вещей в охапке — потом несёт в сундук
const HIT_GAP: float = 1.15

var main: Node2D
var v24: Node
var k23: Node
var st: Dictionary = {}             # узел работницы -> состояние
var t: float = 0.0
var claimed: Dictionary = {}        # дерево (Sprite2D) -> работница
var pair_trunks: Array = []         # [ведущая, вторая, спрайт ствола, порода]


func setup(m: Node2D, v: Node) -> void:
	main = m
	v24 = v
	add_to_group("workers24")


func _k23() -> Node:
	if k23 == null or not is_instance_valid(k23):
		k23 = get_tree().get_first_node_in_group("kingdom23")
	return k23


## kingdom23 создал узел работницы — берём под управление
func adopt(w: Node2D, idx: int) -> void:
	w.set("ctrl", true)
	w.set("spd_k", 1.7)
	w.set("on_interact", Callable(self, "talk"))
	w.set_meta("w24", idx)
	var bag: Sprite2D = Sprite2D.new()
	bag.texture = load("res://art/icon_log.png")
	bag.position = Vector2(0, -60)
	bag.visible = false
	bag.z_index = 2
	w.add_child(bag)
	st[w] = {"s": "idle", "t": randf_range(0.5, 3.0), "load": {}, "bag": bag, "hits": 0, "tree": null, "felled": null, "cd": 0.0, "busy": "", "goal": Vector2.ZERO, "said": 0.0}


func _idx(w: Node2D) -> int:
	return int(w.get_meta("w24", w.get_meta("worker23", -1)))


func _order(w: Node2D) -> String:
	var i: int = _idx(w)
	if i < 0 or i >= Game.workers.size():
		return "rest"
	return String(Game.workers[i].get("order", "rest"))


func _name(w: Node2D) -> String:
	return String(w.get("npc_name"))


# ------------------------------------------------------------------ для trees24

func free_workers() -> Array:
	var out: Array = []
	for w in st.keys():
		if not is_instance_valid(w) or not (w as Node2D).visible:
			continue
		var d: Dictionary = st[w]
		if String(d["busy"]) != "" or String(d["s"]) in ["sleep", "to_bed", "pcarry", "pcarry_f"]:
			continue
		out.append(w)
	return out


func summon(w: Node2D, at: Vector2, why: String) -> void:
	if not st.has(w):
		return
	var d: Dictionary = st[w]
	d["busy"] = "summoned"
	d["goal"] = at
	_go(w, at, 2.4)


func set_busy(w: Node2D, b: String) -> void:
	if not st.has(w):
		return
	var d: Dictionary = st[w]
	d["busy"] = b
	if b == "":
		w.set("spd_k", 1.7)
		d["s"] = "idle"
		d["t"] = 1.0


func hold_at(w: Node2D, p: Vector2, moving: bool, vel: Variant) -> void:
	var gp: Vector2 = w.global_position
	w.global_position = gp.lerp(p, 0.35)
	w.set("walking", moving)
	if moving:
		w.set("dist", float(w.get("dist")) + gp.distance_to(w.global_position) + 0.6)
		w.set("row", 2 if (vel as Vector2).x < -2.0 else (3 if (vel as Vector2).x > 2.0 else int(w.get("row"))))
	w.set("route", [])


func load_up(w: Node2D, id: String, n: int) -> void:
	if not st.has(w) or n <= 0:
		# узла нет (далеко) — сразу в сундук
		var cu: Node = get_tree().get_first_node_in_group("chest_ui")
		if cu != null:
			var left: int = int(cu.call("deposit", id, n, Game.home_pos))
			if left > 0:
				Game.ground.append([id, left, Game.home_pos.x, Game.home_pos.y + 40.0])
		return
	var ld: Dictionary = st[w]["load"]
	ld[id] = int(ld.get(id, 0)) + n
	_show_bag(w)


func _load_n(w: Node2D) -> int:
	var c: int = 0
	for v in (st[w]["load"] as Dictionary).values():
		c += int(v)
	return c


func _show_bag(w: Node2D) -> void:
	var d: Dictionary = st[w]
	var bag: Sprite2D = d["bag"]
	var ld: Dictionary = d["load"]
	bag.visible = not ld.is_empty()
	if not ld.is_empty():
		var first: String = String(ld.keys()[0])
		var ic: Texture2D = IT.icon(first)
		bag.texture = ic
		bag.scale = Vector2.ONE * (14.0 / maxf(1.0, float(ic.get_height()))) * 1.6 if ic != null else Vector2.ONE


# ------------------------------------------------------------------ речь

func say_line(w: Node2D, key: String) -> void:
	say(w, T.line(key))


func say(w: Node2D, text: String) -> void:
	if not is_instance_valid(w):
		return
	var pl: Node2D = main.get("player")
	if pl != null and pl.global_position.distance_to(w.global_position) > 700.0:
		return
	var old: Node = w.get_node_or_null("Bubble24")
	if old != null:
		old.queue_free()
	var hud: CanvasLayer = main.get("hud")
	var l: Label = Label.new()
	l.name = "Bubble24"
	l.text = text
	l.add_theme_font_override("font", hud.get("font_body"))
	l.add_theme_font_size_override("font_size", 22)
	l.add_theme_color_override("font_color", Color("fff4d8"))
	l.add_theme_color_override("font_outline_color", Color("1a1008"))
	l.add_theme_constant_override("outline_size", 6)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size = Vector2(420, 60)
	l.scale = Vector2.ONE / 3.0
	l.position = Vector2(-70, -86)
	l.z_index = 50
	w.add_child(l)
	var tw: Tween = l.create_tween()
	tw.tween_interval(3.2 + text.length() * 0.03)
	tw.tween_property(l, "modulate:a", 0.0, 0.6)
	tw.tween_callback(l.queue_free)
	w.call("react", "talk", 1.2)
	st.get(w, {})["said"] = t


# ------------------------------------------------------------------ движение

func _go(w: Node2D, at: Vector2, spd: float = 1.7) -> void:
	w.set("spd_k", spd)
	w.set("route", [at])
	w.set("walking", true)
	w.set("dist", 0.0)


func _arrived(w: Node2D) -> bool:
	return not bool(w.get("walking"))


# ------------------------------------------------------------------ главный цикл

func _process(delta: float) -> void:
	t += delta
	_pairs(delta)
	for w in st.keys():
		if not is_instance_valid(w):
			st.erase(w)
			continue
		_tick(w as Node2D, st[w], delta)


func _tick(w: Node2D, d: Dictionary, delta: float) -> void:
	if String(d["busy"]) == "carry":
		return
	if String(d["busy"]) == "summoned":
		return
	d["t"] = float(d["t"]) - delta
	d["cd"] = maxf(0.0, float(d["cd"]) - delta)
	var h: float = Game.hour()
	var night: bool = h >= 21.0 or h < 6.0
	var s: String = String(d["s"])
	# ночь: спать
	if night and s not in ["sleep", "to_bed", "pcarry", "pcarry_f"]:
		_release_tree(w, d)
		d["s"] = "to_bed"
		var door: Vector2 = v24.call("bed_for", _idx(w))
		d["goal"] = door
		_go(w, door, 1.4)
		if randf() < 0.5:
			say_line(w, "night")
		return
	if s == "to_bed":
		if _arrived(w):
			d["s"] = "sleep"
			if bool(v24.call("has_house")):
				w.visible = false
				Sound.play("door", -14.0, 0.2, w.global_position)
		return
	if s == "sleep":
		if not night:
			w.visible = true
			w.global_position = Vector2(d["goal"]) + Vector2(0, 14)
			d["s"] = "idle"
			d["t"] = randf_range(0.5, 3.0)
			if randf() < 0.35:
				say_line(w, "morning")
		return
	# охапка полная — в сундук
	if s in ["idle", "job", "rest"] and _load_n(w) >= CAP:
		d["s"] = "to_chest"
		s = "to_chest"
	if s in ["idle", "job", "rest"] and _load_n(w) > 0 and _order(w) == "rest":
		d["s"] = "to_chest"
		s = "to_chest"
	match s:
		"idle":
			if float(d["t"]) > 0.0:
				return
			_decide(w, d)
		"rest":
			if _arrived(w) and float(d["t"]) <= 0.0:
				d["t"] = randf_range(3.0, 9.0)
				var hp: Vector2 = Vector2(_k23().call("home")) + Vector2(randf_range(-160, 160), randf_range(80, 220))
				# дешёвый выбор места: несколько попыток вместо тяжёлого поиска свободного места по кольцам
				for _try in range(6):
					var cand: Vector2 = Vector2(_k23().call("home")) + Vector2(randf_range(-160, 160), randf_range(80, 220))
					if not bool(main.call("is_blocked", cand)):
						_go(w, cand, 1.0)
						break
				if _order(w) != "rest":
					d["s"] = "idle"
		"job":
			# работа на своём месте (травы, камни, рыба...): добыча приходит раз в час (kingdom23)
			if _order(w) == "wood" or _order(w) == "rest":
				d["s"] = "idle"
				return
			if _arrived(w) and float(d["t"]) <= 0.0:
				d["t"] = randf_range(1.2, 2.4)
				var job: String = String(w.get("job"))
				var jb: Array = (preload("res://catgirl.gd").JOBS as Dictionary).get(job, [])
				if not jb.is_empty():
					w.call("react", String((jb[5] as Array).pick_random()), 0.5)
					if String(jb[3]) != "":
						Game.fx.emit(w.global_position + (jb[4] as Vector2), String(jb[3]))
					var pl: Node2D = main.get("player")
					if pl.global_position.distance_to(w.global_position) < 500.0 and String(jb[2]) != "":
						Sound.play(String(jb[2]), -14.0, 0.1, w.global_position)
				# иногда переходит на соседнее место
				if randf() < 0.12:
					_go(w, Vector2(w.get("home")) + Vector2(randf_range(-50, 50), randf_range(-30, 30)), 1.0)
		"to_tree":
			var tr: Sprite2D = d["tree"]
			if tr == null or not is_instance_valid(tr):
				_release_tree(w, d)
				d["s"] = "idle"
				return
			if _arrived(w):
				d["s"] = "chop"
				d["t"] = 0.8
				d["hits"] = 0
				w.set("row", 3 if tr.global_position.x > w.global_position.x else 2)
				if randf() < 0.4:
					say_line(w, "chop_start")
		"chop":
			var tr2: Sprite2D = d["tree"]
			if tr2 == null or not is_instance_valid(tr2):
				_release_tree(w, d)
				d["s"] = "idle"
				return
			if float(d["t"]) > 0.0:
				return
			d["t"] = HIT_GAP + randf_range(-0.15, 0.2)
			d["hits"] = int(d["hits"]) + 1
			_swing_fx(w, tr2.global_position + Vector2(0, -14))
			var tw: Tween = tr2.create_tween()
			tw.tween_property(tr2, "rotation", 0.04, 0.05)
			tw.tween_property(tr2, "rotation", -0.03, 0.07)
			tw.tween_property(tr2, "rotation", 0.0, 0.06)
			if int(d["hits"]) >= 7:
				var dir: float = 1.0 if w.global_position.x < tr2.global_position.x else -1.0
				var hs: Node = main.get("homestead")
				hs.call("_remove_tree", tr2)
				claimed.erase(tr2)
				var tn: Node = get_tree().get_first_node_in_group("trees24")
				var f: Node2D = tn.call("fell", tr2, dir)
				f.set("claim", w)
				d["felled"] = f
				d["tree"] = null
				d["s"] = "fall_wait"
				d["t"] = 1.8
				say_line(w, "tree_fall")
				# пенёк
				var stp: Sprite2D = main.call("spr", "stump_cut", f.global_position, 0.0, false, null, false)
				(hs.get("stumps") as Array).append([stp, hs.call("_abs_minutes")])
		"fall_wait":
			if float(d["t"]) <= 0.0:
				var f2: Node2D = d["felled"]
				if f2 == null or not is_instance_valid(f2):
					d["s"] = "idle"
					return
				d["s"] = "trim"
				_go(w, (f2.call("point_near", w.global_position) as Vector2) + Vector2(0, 12), 1.4)
				d["t"] = 0.6
				if randf() < 0.3:
					say_line(w, "trim")
		"trim", "cut":
			var f3: Node2D = d["felled"]
			if f3 == null or not is_instance_valid(f3):
				d["s"] = "idle" if _load_n(w) == 0 else "to_chest"
				return
			if not _arrived(w) or float(d["t"]) > 0.0:
				return
			d["t"] = HIT_GAP
			_swing_fx(w, Vector2.INF)
			var done: bool = bool(f3.call("hit", w))
			if done and s == "trim":
				# ствол: вдвоём — в штабель, одна — на поленья
				var mate: Node2D = _free_mate(w)
				if mate != null and randf() < 0.7:
					_start_pair(w, mate, f3)
				else:
					d["s"] = "cut"
					if randf() < 0.4:
						say_line(w, "cut_logs")
			elif done:
				d["felled"] = null
				d["s"] = "to_chest"
		"to_chest":
			var cu: Node = get_tree().get_first_node_in_group("chest_ui")
			var ld: Dictionary = d["load"]
			if ld.is_empty():
				d["s"] = "idle"
				return
			if cu == null or Game.chests.is_empty():
				_complain(w, d, "no_chest")
				return
			var key: String = String(cu.call("room_for", String(ld.keys()[0]), w.global_position))
			if key == "":
				# может, для другой вещи из охапки место есть
				for id in ld.keys():
					key = String(cu.call("room_for", String(id), w.global_position))
					if key != "":
						break
			if key == "":
				_complain(w, d, "no_room" if randf() < 0.7 else "no_room_kind")
				return
			d["goal"] = cu.call("_key_pos", key)
			_go(w, Vector2(d["goal"]) + Vector2(0, 16), 1.7)
			d["s"] = "depositing"
		"depositing":
			if not _arrived(w):
				return
			var cu2: Node = get_tree().get_first_node_in_group("chest_ui")
			var ld2: Dictionary = d["load"]
			var rest: Dictionary = {}
			for id2 in ld2.keys():
				var left: int = int(cu2.call("deposit", String(id2), int(ld2[id2]), w.global_position))
				if left > 0:
					rest[id2] = left
			d["load"] = rest
			_show_bag(w)
			Sound.play("door", -14.0, 0.2, w.global_position)
			if rest.is_empty():
				if randf() < 0.35:
					say_line(w, "deposit")
				d["s"] = "idle"
				d["t"] = randf_range(0.5, 2.0)
			else:
				d["s"] = "to_chest"
				d["t"] = 0.5
		"to_player":
			var pl2: Node2D = main.get("player")
			if float(d["t"]) <= 0.0:
				d["t"] = 0.8
				_go(w, pl2.global_position + Vector2(24, 10), 2.0)
			if w.global_position.distance_to(pl2.global_position) < 60.0:
				d["s"] = "wait_room"
				d["t"] = 90.0
				w.set("walking", false)
				w.set("route", [])
				if not Game.ui_open and not Game.busy:
					_complaint_talk(w, String(d["why"]))
				else:
					say_line(w, String(d["why"]))
			elif float(d.get("chase", 0.0)) > 40.0:
				# так и не догнала — скажет, когда увидит
				d["s"] = "wait_room"
				d["t"] = 60.0
			d["chase"] = float(d.get("chase", 0.0)) + delta
		"wait_room":
			if float(d["t"]) <= 0.0:
				d["s"] = "to_chest"
			elif _arrived(w) and randf() < delta * 0.2:
				_go(w, Vector2(_k23().call("home")) + Vector2(randf_range(-120, 120), randf_range(60, 200)), 1.0)
		"pcarry", "pcarry_f":
			pass


func _decide(w: Node2D, d: Dictionary) -> void:
	var o: String = _order(w)
	if o == "rest":
		d["s"] = "rest"
		d["t"] = 0.0
		return
	if o == "wood":
		var tr: Sprite2D = _find_tree(w)
		if tr == null:
			# деревьев рядом нет — хоть сучья соберёт
			d["t"] = 6.0
			return
		claimed[tr] = w
		d["tree"] = tr
		var side: float = -1.0 if w.global_position.x < tr.global_position.x else 1.0
		_go(w, tr.global_position + Vector2(side * 16.0, 4.0), 1.7)
		d["s"] = "to_tree"
		return
	# прочие приказы: идёт на своё место и работает там
	d["s"] = "job"
	d["t"] = 1.0
	var spot: Vector2 = Vector2(w.get("home"))
	_go(w, spot, 1.6)


func _release_tree(w: Node2D, d: Dictionary) -> void:
	var tr: Variant = d.get("tree")
	if tr != null and is_instance_valid(tr):
		claimed.erase(tr)
	d["tree"] = null


func _swing_fx(w: Node2D, at: Vector2) -> void:
	var sp: Sprite2D = w.get("spr")
	if sp != null:
		var tw: Tween = w.create_tween()
		tw.tween_property(sp, "position:y", 2.0, 0.08)
		tw.tween_property(sp, "position:y", 0.0, 0.14)
	w.call("react", ["pout", "surprised", "pout", "neutral"].pick_random(), 0.5)
	var pl: Node2D = main.get("player")
	var near: bool = pl.global_position.distance_to(w.global_position) < 620.0
	if at != Vector2.INF:
		if near:
			Sound.play("chop", -9.0, 0.12, at)
		Game.fx.emit(at, "chips")


## Ближайшее настоящее дерево у дома (не в городах, не занятое другой)
func _find_tree(w: Node2D) -> Sprite2D:
	var home: Vector2 = Vector2(_k23().call("home"))
	var from: Vector2 = w.global_position
	var best: Sprite2D = null
	var bd: float = 1e9
	# список подходящих деревьев общий для всех и обновляется раз в 20 секунд (раньше каждый поиск перебирал сотни деревьев)
	if t - tree_cache_t > 20.0 or tree_cache_home.distance_to(home) > 1.0:
		_rebuild_tree_cache(home)
	for sv in tree_cache:
		if not is_instance_valid(sv) or claimed.has(sv):
			continue
		var s: Sprite2D = sv
		var p: Vector2 = s.global_position
		var dd: float = p.distance_to(from) + p.distance_to(home) * 0.3
		if dd < bd:
			bd = dd
			best = s
	for yt in (main.get("yard_trees") as Array):
		if is_instance_valid(yt) and not claimed.has(yt) and (yt as Node2D).global_position.distance_to(from) < bd * 0.5:
			best = yt
			bd = (yt as Node2D).global_position.distance_to(from)
	return best


var tree_cache: Array = []
var tree_cache_t: float = -100.0
var tree_cache_home: Vector2 = Vector2(-1e9, -1e9)


func _rebuild_tree_cache(home: Vector2) -> void:
	tree_cache.clear()
	tree_cache_t = t
	tree_cache_home = home
	var world: Node = main.get("world")
	var tall: Dictionary = world.get("tall")
	var c0: Vector2i = Vector2i(int(floor(home.x / 256.0)), int(floor(home.y / 256.0)))
	var WD = preload("res://world_data.gd")
	var town_r2: float = (WD.TOWN_R + 200.0) * (WD.TOWN_R + 200.0)
	var towns: Array = WD.TOWN_C.values()
	for dy in range(-4, 5):
		for dx in range(-4, 5):
			for sv in tall.get(c0 + Vector2i(dx, dy), []):
				if not is_instance_valid(sv):
					continue
				var s: Sprite2D = sv
				if s.texture == null or not s.is_visible_in_tree():
					continue
				var p: Vector2 = s.global_position
				if p.distance_squared_to(home) > 1210000.0:
					continue
				var in_town: bool = false
				for tc in towns:
					if p.distance_squared_to(tc) < town_r2:
						in_town = true
						break
				if in_town:
					continue
				if not IT.is_tree_tex(s.texture.resource_path.get_file().get_basename()):
					continue
				tree_cache.append(s)


func _free_mate(w: Node2D) -> Node2D:
	for o in st.keys():
		if o == w or not is_instance_valid(o) or not (o as Node2D).visible:
			continue
		var d: Dictionary = st[o]
		if String(d["busy"]) != "" or _order(o) != "wood":
			continue
		if String(d["s"]) in ["idle", "to_tree", "rest"] and (o as Node2D).global_position.distance_to(w.global_position) < 700.0 and _load_n(o) < CAP:
			return o
	return null


# ------------------------------------------------------------------ вдвоём несут ствол в штабель

func _start_pair(a: Node2D, b: Node2D, f: Node2D) -> void:
	var da: Dictionary = st[a]
	var db: Dictionary = st[b]
	_release_tree(b, db)
	da["s"] = "pcarry"
	db["s"] = "pcarry_f"
	say_line(a, "carry_pair")
	var fam: String = String((f.get("rec") as Dictionary)["fam"])
	var at: Vector2 = f.call("center")
	Game.felled.erase(f.get("rec"))
	f.queue_free()
	da["felled"] = null
	var sp: Sprite2D = Sprite2D.new()
	sp.texture = load("res://art/trunk24_%s.png" % fam)
	sp.position = at + Vector2(0, -6)
	sp.z_index = 2
	main.get("objects").add_child(sp)
	var tn: Node = get_tree().get_first_node_in_group("trees24")
	var goal: Vector2 = tn.call("pile_spot")
	# сначала вторая подходит к стволу
	_go(b, at + Vector2(46, 8), 2.0)
	_go(a, at + Vector2(-46, 8), 1.4)
	pair_trunks.append({"a": a, "b": b, "spr": sp, "fam": fam, "goal": goal, "phase": 0, "t": 0.0})


func _pairs(delta: float) -> void:
	for i in range(pair_trunks.size() - 1, -1, -1):
		var pt: Dictionary = pair_trunks[i]
		var a: Node2D = pt["a"]
		var b: Node2D = pt["b"]
		var sp: Sprite2D = pt["spr"]
		if not is_instance_valid(a) or not is_instance_valid(b):
			if is_instance_valid(sp):
				sp.queue_free()
			pair_trunks.remove_at(i)
			continue
		pt["t"] = float(pt["t"]) + delta
		if int(pt["phase"]) == 0:
			if (_arrived(a) and _arrived(b)) or float(pt["t"]) > 12.0:
				pt["phase"] = 1
				Sound.play("grunt", -10.0, 0.2, a.global_position)
				_go(a, Vector2(pt["goal"]) + Vector2(-46, 30), 0.55)
			continue
		# несут: вторая держится за другой конец
		b.global_position = b.global_position.lerp(a.global_position + Vector2(92, 0), 0.3)
		b.set("walking", bool(a.get("walking")))
		b.set("dist", float(a.get("dist")))
		b.set("row", int(a.get("row")))
		sp.global_position = (a.global_position + b.global_position) / 2.0 + Vector2(0, -30 + sin(float(pt["t"]) * 7.0) * 1.2)
		if _arrived(a):
			var tn: Node = get_tree().get_first_node_in_group("trees24")
			tn.call("add_to_pile", Vector2(pt["goal"]), String(pt["fam"]))
			Sound.play("tree_thud", -8.0, 0.15, a.global_position)
			Game.fx.emit(Vector2(pt["goal"]), "dust")
			sp.queue_free()
			for w in [a, b]:
				var d: Dictionary = st[w]
				d["s"] = "idle"
				d["t"] = randf_range(1.0, 3.0)
				w.set("spd_k", 1.7)
			if randf() < 0.6:
				say_line(b, "carry_done")
			Game.skill_xp("lead", 1.0)
			pair_trunks.remove_at(i)


# ------------------------------------------------------------------ жалобы и разговор

func _complain(w: Node2D, d: Dictionary, why: String) -> void:
	d["why"] = why
	if float(d["cd"]) > 0.0:
		d["s"] = "wait_room"
		d["t"] = 30.0
		return
	d["cd"] = 240.0
	d["s"] = "to_player"
	d["t"] = 0.0
	d["chase"] = 0.0


func _face(w: Node2D) -> Texture2D:
	return _k23().call("_face", String(w.get("tex_name")))


func _complaint_talk(w: Node2D, why: String) -> void:
	w.set("row", 0)
	v24.call("talk_menu", _face(w), _name(w), T.line(why), [
		["Хорошо, построю ещё сундук", func() -> void: say_line(w, "thanks")],
		["Сложи пока у дома на землю", func() -> void:
			var d: Dictionary = st[w]
			for id in (d["load"] as Dictionary).keys():
				Game.ground.append([String(id), int(d["load"][id]), w.global_position.x, w.global_position.y + 10.0])
				var v23n: Node = get_tree().get_first_node_in_group("v23")
				if v23n != null:
					v23n.call("_spawn_ground", String(id), int(d["load"][id]), w.global_position + Vector2(randf_range(-16, 16), 10))
			d["load"] = {}
			_show_bag(w)
			d["s"] = "idle"],
		["Отдай мне, я сама разберусь", func() -> void:
			var d2: Dictionary = st[w]
			for id2 in (d2["load"] as Dictionary).keys():
				Game.add_item(String(id2), int(d2["load"][id2]))
			d2["load"] = {}
			_show_bag(w)
			d2["s"] = "idle"],
	])


## Разговор с работницей (как предложение о королевстве: лицо, имя, выбор)
func talk(w: Node2D) -> void:
	var pl: Node2D = main.get("player")
	w.set("walking", false)
	w.set("route", [])
	w.set("row", w.call("_facing_for", pl.global_position - w.global_position))
	pl.call("react", "talk", 1.0)
	var greet: String = "greet"
	if not Game.kingdom.is_empty() and randf() < 0.5:
		greet = "greet_queen"
	elif float(_k23().call("happiness")) < 0.45:
		greet = "greet_tired"
	_menu(w, T.line(greet))


func _menu(w: Node2D, text: String) -> void:
	var opts: Array = []
	opts.append(["Приказы…", func() -> void: _orders_menu(w)])
	opts.append(["Как ты? Всё хорошо?", func() -> void:
		var h: float = float(_k23().call("happiness"))
		_menu(w, T.line("mood_good" if h > 0.8 else ("mood_mid" if h > 0.5 else "mood_bad")))])
	opts.append(["Расскажи о себе", func() -> void:
		var i: int = _idx(w)
		var land: String = String(Game.workers[i].get("land", "")) if i >= 0 and i < Game.workers.size() else ""
		var lname: String = String(NPC.LANDS.get(land, {}).get("name", "")) if NPC.LANDS.has(land) else ""
		if lname != "":
			_menu(w, T.line("about_me") % lname)
		else:
			_menu(w, T.line("about_me_none"))])
	if st.has(w) and _load_n(w) > 0:
		opts.append(["Отнеси, что несёшь, в сундук", func() -> void:
			st[w]["s"] = "to_chest"
			say_line(w, "order_ok")])
	opts.append(["Ты свободна, иди домой", func() -> void:
		v24.call("talk_menu", _face(w), _name(w), "Правда? Ты меня отпускаешь?", [
			["Да, спасибо за работу", func() -> void:
				say_line(w, "fire")
				var i2: int = _idx(w)
				if i2 >= 0:
					_k23().call("fire", i2)],
			["Нет-нет, я пошутила", func() -> void: _menu(w, T.line("thanks"))]])])
	opts.append(["Пока!", func() -> void: pass])
	v24.call("talk_menu", _face(w), _name(w), text, opts)


func _orders_menu(w: Node2D) -> void:
	var opts: Array = []
	var ORD: Dictionary = _k23().get("ORDERS")
	for k in (_k23().get("ORDER_KEYS") as Array):
		if k == "brew" and int(_k23().call("_count_kind", "kg_brewery")) == 0 and not Game.god_mode:
			continue
		var key: String = String(k)
		opts.append([String(ORD[key][0]) + (" ✓" if _order(w) == key else ""), func() -> void:
			var i: int = _idx(w)
			_k23().call("give_order", i, key)
			if st.has(w):
				st[w]["s"] = "idle"
				st[w]["t"] = 0.3
				_release_tree(w, st[w])
			var lk: String = "order_" + key
			say(w, T.line(lk) if T.L.has(lk) else T.line("order_ok"))])
	opts.append(["Назад", func() -> void: _menu(w, "Что-то ещё?")])
	v24.call("talk_menu", _face(w), _name(w), "Чем мне заняться?", opts)

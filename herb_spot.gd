extends Node2D
const PG27 = preload("res://plant_ground27.gd")
## Место, где растут дикие травы своего биома (v16). Каждый день решается, выросло ли здесь что-то:
## всегда кучка (v20: минимум 2 растения, часто 3), а иногда — СКОПЛЕНИЕ (4–8 растений, одного-двух видов).
## Некоторые видны только в свои часы (лунноцвет, светомох — ночью). E — окно сбора (harvest_ui.gd).

const DB = preload("res://herbs_db.gd")
const CLUSTER_CHANCE: float = 0.22

var interact_offset: Vector2 = Vector2(0, -14)
var options: Array = []          # [[id, вес], ...]
var chance: float = 0.6
var key: String = ""
var today: Array = []            # что растёт сегодня (id по растениям)
var day_seen: int = -1
var sprs: Array = []
var wmat: Material
var sparkle: Sprite2D
var phase: float = 0.0
var check_t: float = 0.0
var shown: bool = false
var crown_checked: bool = false
var crown_ver: int = -1
var sea_spot: bool = false      # v22: подводное место (растёт на дне моря)


func setup(at: Vector2, opts: Array, ch: float, wind_mat: Material) -> void:
	add_to_group("herb_spots25")
	position = at.round()
	options = opts
	chance = ch
	wmat = wind_mat
	key = "h%d,%d" % [int(at.x), int(at.y)]
	sparkle = Sprite2D.new()
	sparkle.texture = load("res://art/fx_firefly.png")
	var add: CanvasItemMaterial = CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	sparkle.material = add
	sparkle.visible = false
	add_child(sparkle)
	phase = randf() * TAU
	check_t = randf()


func _pick(r: RandomNumberGenerator) -> String:
	var total: float = 0.0
	for o in options:
		total += float(o[1])
	var pick: float = r.randf() * total
	for o2 in options:
		pick -= float(o2[1])
		if pick <= 0.0:
			return String(o2[0])
	return String(options[0][0]) if not options.is_empty() else ""


func _roll() -> void:
	day_seen = Game.day
	today = []
	var left: Variant = Game.picked.get(key, -1)
	if left is Array:
		# сегодня уже собирала часть скопления — остаток растёт до завтра
		var la: Array = left
		if la.size() >= 2 and int(la[0]) == Game.day:
			today = (la[1] as Array).duplicate()
			_make_sprites()
			return
	elif int(left) == Game.day:
		_make_sprites()
		return
	var r: RandomNumberGenerator = RandomNumberGenerator.new()
	r.seed = hash(key + "/" + str(Game.day))
	var gm: float = 1.0 + Game.stat("sea_grow" if sea_spot else "herb_grow") / 100.0
	if r.randf() > chance * gm:
		_make_sprites()
		return
	var first: String = _pick(r)
	if first == "":
		_make_sprites()
		return
	today.append(first)
	# v20: травы никогда не растут по одной — всегда кучкой, минимум две
	today.append(first)
	var rare: float = float(DB.DATA[first].get("rare", 1.0))
	if rare >= 0.5 and r.randf() < 0.45:
		today.append(first)
	if rare >= 0.5 and r.randf() < CLUSTER_CHANCE:
		var n: int = r.randi_range(4, 8)
		var second: String = _pick(r) if r.randf() < 0.35 else first
		if float(DB.DATA.get(second, {}).get("rare", 1.0)) < 0.5:
			second = first
		for i in range(n - today.size()):
			today.append(first if r.randf() < 0.65 else second)
	_make_sprites()


## Растения вокруг места: в скоплении — россыпью
func _make_sprites() -> void:
	for s in sprs:
		(s as Node).queue_free()
	sprs.clear()
	# v24: новые спрайты скрыты — пусть следующая проверка покажет их заново (иначе метка есть, травы не видно)
	shown = false
	check_t = minf(check_t, 0.05)
	# v24: травы без «кочки» земли (herbw_*), каждая чуть своя: размер, отражение, наклон, россыпь без узора
	var r: RandomNumberGenerator = RandomNumberGenerator.new()
	r.seed = hash(key) + Game.day * 13
	var used: Array = [Vector2.ZERO]
	for i in range(today.size()):
		var s: Sprite2D = Sprite2D.new()
		s.centered = false
		s.offset = Vector2(-16, -45)
		s.material = wmat
		var hid: String = String(today[i])
		var wp: String = "res://art/herbw_%s.png" % hid
		s.texture = load(wp) if ResourceLoader.exists(wp) else DB.icon(hid)
		s.flip_h = r.randf() < 0.5
		var k: float = r.randf_range(0.82, 1.06)
		s.scale = Vector2(k, k)
		if i > 0:
			var best: Vector2 = Vector2.ZERO
			for tries in range(14):
				var a: float = r.randf() * TAU
				var rr: float = r.randf_range(9.0, 14.0 + 7.0 * sqrt(float(i)))
				var c: Vector2 = Vector2(cos(a) * rr * 1.5, sin(a) * rr * 0.62).round()
				var ok: bool = true
				for u in used:
					if (u as Vector2).distance_to(c) < 9.0:
						ok = false
				if ok:
					best = c
					break
				best = c
			used.append(best)
			s.position = best
			s.z_index = int(s.position.y)
		s.modulate = Color(1, 1, 1).lerp(Color(0.92, 0.98, 0.9), r.randf())
		s.visible = false
		add_child(s)
		sprs.append(s)
		if is_inside_tree():
			PG27.attach(s, global_position + s.position)   # v27: растёт из земли биома


func _process(delta: float) -> void:
	var w: Node = get_tree().current_scene.get("world") if get_tree().current_scene != null else null
	if w != null and (not crown_checked or int(w.get("tall_ver")) != crown_ver):
		# v21: построено позже деревьев/крыш — если оказались под кроной или на крыше, место убираем
		# v24: и когда рядом поставили новый дом
		crown_checked = true
		crown_ver = int(w.get("tall_ver"))
		var bad: bool = bool(w.call("under_crown", global_position))
		for sp in sprs:
			if bad:
				break
			bad = bool(w.call("under_crown", (sp as Node2D).global_position))
		if bad:
			queue_free()
			return
	check_t -= delta
	if check_t <= 0.0:
		check_t = 1.0
		if day_seen != Game.day:
			_roll()
		var vis: bool = not today.is_empty() and DB.hour_ok(String(today[0]), Game.hour())
		if vis and not shown:
			var w2: Node = get_tree().current_scene.get("world") if get_tree().current_scene != null else null
			if w2 != null and bool(w2.call("under_crown", global_position)):
				queue_free()
				return
		if vis != shown:
			shown = vis
			for s in sprs:
				(s as Sprite2D).visible = vis
		sparkle.visible = vis
		if vis and not is_in_group("interactables"):
			add_to_group("interactables")
		elif not vis and is_in_group("interactables"):
			remove_from_group("interactables")
		# ночные и огненные травы светятся сами
		if vis:
			var d: Dictionary = DB.DATA[String(today[0])]
			var glow: bool = d.has("hours") and Game.night_factor() > 0.5
			if String(today[0]) in ["fire_lily", "phoenix_grass", "sunflower_gold", "glowmoss", "pearl_flower", "siren_lily", "pearl_moss"]:
				glow = true
			var base_c: Color = Color(0.80, 0.96, 1.06, 0.93) if sea_spot else Color.WHITE
			for s2 in sprs:
				if not sea_spot and not (s2 as Node).has_node("PlantBaseBack"):
					PG27.attach(s2 as Sprite2D, global_position + (s2 as Node2D).position)   # v27: растёт из земли биома
				(s2 as Sprite2D).modulate = (Color(1.3, 1.4, 1.3) if sea_spot else Color(1.35, 1.25, 1.2)) if glow else base_c
	if sparkle.visible:
		phase += delta * 1.7
		var k: float = maxf(0.0, sin(phase))
		sparkle.modulate = Color(1, 1, 0.85, k * k)
		if k < 0.02:
			sparkle.position = Vector2(randf_range(-8, 8), randf_range(-36, -22))


func get_prompt() -> String:
	if today.is_empty():
		return ""
	return ("Собрать: " + DB.short(String(today[0]))) + ("  ×%d" % today.size() if today.size() > 1 else "")


func interact() -> void:
	if today.is_empty():
		return
	var hu: Node = get_tree().get_first_node_in_group("harvest_ui")
	if hu != null:
		hu.call("open", self, today.duplicate())


## Окно сбора закрыто: что осталось в земле — растёт до завтра
func harvest_done(got: Array, left: Array) -> void:
	if not got.is_empty():
		Game.fx.emit(global_position + Vector2(0, -16), "leaves")
		for id in got:
			if DB.price(String(id)) >= 14:
				Sound.play("magic", -8.0)
				break
	today = left.duplicate()
	Game.picked[key] = [Game.day, today.duplicate()] if not today.is_empty() else Game.day
	_make_sprites()
	shown = false
	check_t = 0.0

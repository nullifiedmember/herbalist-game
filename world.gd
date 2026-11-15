extends Node2D
## Большой открытый мир вокруг двора: земля биомов, леса и камни по регионам,
## препятствия (сетка-хэш), тени, туман карты. Регионы строятся, когда героиня подходит
## к ним, и прячутся, когда она уходит далеко.

const WD = preload("res://world_data.gd")
const GROUND_SHADER = preload("res://world_ground.gdshader")
const HASH: float = 96.0                 # клетка сетки препятствий
const ACTIVE_MARGIN: float = 760.0       # насколько заранее строить/показывать соседний регион

var main: Node2D
var built: Dictionary = {}               # Vector2i -> Node2D (контейнер региона)
var casters: Dictionary = {}             # Vector2i -> Array [[спрайт, тень]]
var active: Array = []                   # видимые сейчас регионы
var blocks: Dictionary = {}              # Vector2i клетки -> Array[Vector3] круги
var block_rects: Array = []              # большие прямоугольники (дома)
var walk_rects: Array = []               # где можно ходить даже по морю (пирс)
var reserved: Array = []                 # места, где природа не растёт (площади, дворики)
var basis: Vector2 = Vector2(0.3, 0.5)
var check_t: float = 0.0
var fog_t: float = 0.0
var builders: Dictionary = {}            # Vector2i -> Callable(container, rng) особые регионы
var town_builders: Dictionary = {}       # Vector2i -> Callable: города (после особых построек, до природы)
var region_hooks: Array = []             # Callable(node, r) для каждой области (звери, грибы)
var post_builders: Dictionary = {}       # Vector2i -> Callable: украшения поверх природы региона
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var ground_mat: ShaderMaterial
var tall: Dictionary = {}                # клетка 256 -> высокие спрайты (деревья, дома): прозрачнеют, когда героиня за ними
var faded: Array = []
var lens_on: bool = false                # «взгляд» (V) включён
var eye_icon: Control


## V — включить/выключить взгляд (одно нажатие)
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and KB.is_key("lens", (event as InputEventKey).physical_keycode):
		if Game.ui_open:
			return
		lens_on = not lens_on
		if eye_icon != null:
			eye_icon.call("set_shown", lens_on)


func setup(m: Node2D) -> void:
	main = m
	var eye_layer: CanvasLayer = CanvasLayer.new()
	eye_layer.layer = 50
	add_child(eye_layer)
	eye_icon = Control.new()
	eye_icon.set_script(load("res://eye_icon.gd"))
	eye_layer.add_child(eye_icon)
	_build_ground()
	if Game.explored.is_empty():
		Game.explored.resize(int(WD.SIZE.x) / WD.FOG_CELL * int(WD.SIZE.y) / WD.FOG_CELL)


## Земля под всем миром (двор рисуется поверх своей картинкой)
func _build_ground() -> void:
	var poly: Polygon2D = Polygon2D.new()
	var o: Vector2 = WD.ORIGIN
	var e: Vector2 = WD.ORIGIN + WD.SIZE
	poly.polygon = PackedVector2Array([o, Vector2(e.x, o.y), e, Vector2(o.x, e.y)])
	poly.z_index = -11
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = GROUND_SHADER
	mat.set_shader_parameter("biome_map", load("res://art/world_biome.png"))
	mat.set_shader_parameter("world_origin", WD.ORIGIN)
	mat.set_shader_parameter("world_size", WD.SIZE)
	mat.set_shader_parameter("cell", float(WD.CELL))
	mat.set_shader_parameter("atlas", load("res://art/wt_atlas.png"))
	mat.set_shader_parameter("nb", float(WD.BIOMES))
	mat.set_shader_parameter("troad", load("res://art/wt_road.png"))
	ground_mat = mat
	mat.set_shader_parameter("road_map", load("res://art/world_road.png"))
	poly.material = mat
	add_child(poly)


# ------------------------------------------------------------------ препятствия

func add_block(p: Vector2, r: float) -> void:
	var c0: Vector2i = Vector2i(int(floor((p.x - r) / HASH)), int(floor((p.y - r) / HASH)))
	var c1: Vector2i = Vector2i(int(floor((p.x + r) / HASH)), int(floor((p.y + r) / HASH)))
	for cy in range(c0.y, c1.y + 1):
		for cx in range(c0.x, c1.x + 1):
			var k: Vector2i = Vector2i(cx, cy)
			if not blocks.has(k):
				blocks[k] = []
			(blocks[k] as Array).append(Vector3(p.x, p.y, r))


func add_block_rect(r: Rect2) -> void:
	block_rects.append(r)


func reserve(r: Rect2) -> void:
	reserved.append(r)


func is_blocked(p: Vector2) -> bool:
	var m: float = 8.0
	if p.x < WD.ORIGIN.x + m or p.y < WD.ORIGIN.y + m or p.x > WD.ORIGIN.x + WD.SIZE.x - m or p.y > WD.ORIGIN.y + WD.SIZE.y - m:
		return true
	if p.y > 7400.0 and WD.biome_at(p) == WD.SEA:
		var on_walk: bool = Game.mermaid_t > 0.0     # v22: в хвосте русалки по морю можно плавать
		for wr in walk_rects:
			if (wr as Rect2).has_point(p):
				on_walk = true
		if not on_walk:
			return true
	var k: Vector2i = Vector2i(int(floor(p.x / HASH)), int(floor(p.y / HASH)))
	if blocks.has(k):
		for c in blocks[k]:
			var cv: Vector3 = c
			if (p.x - cv.x) * (p.x - cv.x) + (p.y - cv.y) * (p.y - cv.y) < cv.z * cv.z:
				return true
	for r in block_rects:
		if (r as Rect2).has_point(p):
			return true
	return false


## Свободно ли место для нового предмета (не на дороге, не во дворе, не на другом предмете)
func free_at(p: Vector2, r: float, road_margin: float = 16.0) -> bool:
	if Rect2(-40, -40, WD.RW + 80, WD.RH + 80).has_point(p):
		return false
	if WD.road_value(p) < road_margin:
		return false
	var k: Vector2i = Vector2i(int(floor(p.x / HASH)), int(floor(p.y / HASH)))
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var kk: Vector2i = k + Vector2i(dx, dy)
			if blocks.has(kk):
				for c in blocks[kk]:
					var cv: Vector3 = c
					if Vector2(cv.x, cv.y).distance_to(p) < r + cv.z:
						return false
	for rr in block_rects:
		if (rr as Rect2).grow(r).has_point(p):
			return false
	for rv in reserved:
		if (rv as Rect2).has_point(p):
			return false
	return true


# ------------------------------------------------------------------ тени

## Тень предмета региона: как main.add_caster, но в списке региона
func add_caster(reg: Vector2i, src: Sprite2D) -> void:
	var sh: Sprite2D = Sprite2D.new()
	sh.material = main.get("shadow_mat")
	sh.centered = false
	(main.get("shadow_group") as Node).add_child(sh)
	main.call("_copy_look", src, sh)
	if not casters.has(reg):
		casters[reg] = []
	(casters[reg] as Array).append([src, sh])
	_place_shadow(src, sh)


func _place_shadow(src: Sprite2D, sh: Sprite2D) -> void:
	var vis: bool = src.is_visible_in_tree()
	sh.visible = vis
	if vis:
		var sc: Vector2 = src.global_scale
		sh.transform = Transform2D(Vector2(sc.x, 0), basis * sc.y, src.global_position)


## Солнце сдвинулось: тени видимых регионов ложатся заново
func update_shadows(basis_y: Vector2) -> void:
	basis = basis_y
	for reg in active:
		for pair in casters.get(reg, []):
			if is_instance_valid(pair[0]):
				_place_shadow(pair[0], pair[1])


## Предметы рядом с точкой — для теней на персонажах
func casters_near(p: Vector2) -> Array:
	var res: Array = []
	for reg in active:
		if WD.region_rect(reg).grow(340.0).has_point(p):
			res.append_array(casters.get(reg, []))
	return res


# ------------------------------------------------------------------ регионы

func _process(delta: float) -> void:
	var pl: Node2D = main.get("player") as Node2D
	if pl == null:
		return
	if bool(main.get("inside")):
		return
	check_t -= delta
	if check_t <= 0.0:
		check_t = 0.25
		_update_active(pl.global_position, false)
	_load_step()
	_update_fade(pl.global_position, delta)
	fog_t -= delta
	if fog_t <= 0.0:
		fog_t = 0.2
		reveal(pl.global_position, 5.5 * (1.0 + Game.stat("reveal") / 100.0))


## v28: загрузка областей «как в Майнкрафте»: дальняя зона подгрузки строится заранее, по одной области за раз и по кусочкам
## (по одному шагу на кадр), ближайшие — первыми; видимыми области становятся только когда достроены
const LOAD_MARGIN: float = 1300.0         # подгрузка: дальше, чем показ (ACTIVE_MARGIN)
var ready_regions: Dictionary = {}        # Vector2i -> true: область достроена
var load_queue: Array = []                # Vector2i: очередь на постройку (ближние впереди)
var loading: Vector2i = Vector2i(-99999, -99999)
var rng_state: Dictionary = {}            # Vector2i -> состояние генератора между шагами (мир один и тот же, как при цельной постройке)
var hooks_snap: Dictionary = {}


func _regions_near(p: Vector2, margin: float) -> Array:
	var out: Array = []
	var r0: Vector2i = WD.region_of(p)
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var r: Vector2i = r0 + Vector2i(dx, dy)
			if r == Vector2i.ZERO or WD.biome_of_region(r) < 0:
				continue
			if WD.region_rect(r).grow(margin).has_point(p):
				out.append(r)
	return out


func _update_active(p: Vector2, sync: bool = true) -> void:
	var want: Array = _regions_near(p, ACTIVE_MARGIN)
	if sync:
		for r in want:
			if not ready_regions.has(r):
				_build_region(r)
	else:
		# область, в которой стоит героиня, достраиваем сразу (чтобы не стоять посреди пустоты)
		for r in want:
			if not ready_regions.has(r) and WD.region_rect(r).has_point(p):
				_build_region(r)
		# остальные — в очередь, ближайшие первыми (зона подгрузки шире зоны показа)
		for r in _regions_near(p, LOAD_MARGIN):
			if not ready_regions.has(r) and r != loading and not load_queue.has(r):
				load_queue.append(r)
		load_queue.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
			return WD.region_rect(a).get_center().distance_squared_to(p) < WD.region_rect(b).get_center().distance_squared_to(p))
	var changed: bool = false
	for r in built.keys():
		if not ready_regions.has(r):
			continue
		var on: bool = want.has(r)
		var node: Node2D = built[r]
		if node.visible != on:
			node.visible = on
			# спрятанные области не тратят время: жители и звери в них «замирают»
			node.process_mode = Node.PROCESS_MODE_INHERIT if on else Node.PROCESS_MODE_DISABLED
			changed = true
			# тени пересчитываем только у тех областей, что включились
			if on:
				for pair in casters.get(r, []):
					if is_instance_valid(pair[0]):
						_place_shadow(pair[0], pair[1])
	active = want
	if sync:
		load_queue.clear()


## Один шаг фоновой подгрузки (вызывается каждый кадр): строится максимум один кусочек одной области
func _load_step() -> void:
	if loading != Vector2i(-99999, -99999) or load_queue.is_empty():
		return
	var r: Vector2i = load_queue.pop_front()
	if ready_regions.has(r):
		return
	loading = r
	var node: Node2D = _region_begin(r)
	var total: int = 4 + (hooks_snap[r] as Array).size()
	for i in range(total):
		if ready_regions.has(r):
			break           # её уже достроили вручную (героиня вошла)
		_region_stage(r, node, i)
		await get_tree().process_frame
	_region_end(r)
	loading = Vector2i(-99999, -99999)


## Построить область сразу целиком (для проверок, телепортов и скриншотов)
func build_around(p: Vector2) -> void:
	_update_active(p, true)


func _build_region(r: Vector2i) -> void:
	if ready_regions.has(r):
		return
	var node: Node2D = _region_begin(r) if not built.has(r) else (built[r] as Node2D)
	var first: int = int(stage_done.get(r, 0))
	var total: int = 4 + (hooks_snap[r] as Array).size()
	for i in range(first, total):
		_region_stage(r, node, i)
	_region_end(r)


var stage_done: Dictionary = {}           # Vector2i -> сколько шагов области уже сделано


func _region_begin(r: Vector2i) -> Node2D:
	var node: Node2D = Node2D.new()
	node.y_sort_enabled = true
	node.visible = false
	node.process_mode = Node.PROCESS_MODE_DISABLED
	(main.get("objects") as Node).add_child(node)
	built[r] = node
	stage_done[r] = 0
	hooks_snap[r] = region_hooks.duplicate()
	rng.seed = hash(r) + 777
	rng_state[r] = rng.state
	return node


## Шаги: 0 — особые постройки и города, 1 — деревья и цветы, 2 — трава, 3 — украшения, дальше — по одному хуку (звери, грибы, камни...)
func _region_stage(r: Vector2i, node: Node2D, i: int) -> void:
	if int(stage_done.get(r, 0)) > i:
		return
	rng.state = int(rng_state[r])
	match i:
		0:
			if builders.has(r):
				(builders[r] as Callable).call(node, r)
			if town_builders.has(r):
				(town_builders[r] as Callable).call(node, r)
		1:
			_flora(node, r)
		2:
			_grass(node, r)
		3:
			if post_builders.has(r):
				(post_builders[r] as Callable).call(node, r)
		_:
			var hk: Callable = (hooks_snap[r] as Array)[i - 4]
			hk.call(node, r)
	rng_state[r] = rng.state
	stage_done[r] = i + 1


func _region_end(r: Vector2i) -> void:
	ready_regions[r] = true
	rng_state.erase(r)
	hooks_snap.erase(r)
	stage_done.erase(r)


## Спрайт предмета в регионе: с тенью, препятствием и оттенком биома
## v21: точка под кроной дерева или на крыше (внутри «тела» высокой картинки) — туда нельзя ставить растения
var tall_ver: int = 0            # v24: растёт при каждой новой постройке — места трав перепроверяют крыши


func register_tall(s: Sprite2D) -> void:
	var p: Vector2 = s.global_position
	var ck: Vector2i = Vector2i(int(floor(p.x / 256.0)), int(floor(p.y / 256.0)))
	if not tall.has(ck):
		tall[ck] = []
	if not (tall[ck] as Array).has(s):
		(tall[ck] as Array).append(s)
	tall_ver += 1


func under_crown(p: Vector2) -> bool:
	var c0: Vector2i = Vector2i(int(floor(p.x / 256.0)), int(floor(p.y / 256.0)))
	for dy in range(0, 3):
		for dx in range(-1, 2):
			for sv in tall.get(c0 + Vector2i(dx, dy), []):
				if not is_instance_valid(sv):
					continue
				var s: Sprite2D = sv
				if s.z_index < 0:
					continue
				var sc: Vector2 = s.global_scale.abs()
				var r: Rect2 = Rect2(s.global_position + s.offset * sc, Vector2(s.texture.get_width(), s.texture.get_height()) * sc)
				r = r.grow_individual(-r.size.x * 0.08, -r.size.y * 0.04, -r.size.x * 0.08, 0.0)
				if r.has_point(p) and p.y < s.global_position.y + 6.0:
					return true
	return false


func put(node: Node2D, r: Vector2i, tex: String, p: Vector2, wind: float = 0.0, block: float = 0.0, tint: Color = Color.WHITE, cast: bool = true) -> Sprite2D:
	var s: Sprite2D = main.call("spr", tex, p, wind, rng.randf() < 0.5, node, false) as Sprite2D
	s.modulate = tint
	if cast:
		add_caster(r, s)
	if s.texture.get_height() >= 80:
		var ck: Vector2i = Vector2i(int(floor(p.x / 256.0)), int(floor(p.y / 256.0)))
		if not tall.has(ck):
			tall[ck] = []
		(tall[ck] as Array).append(s)
	if block > 0.0:
		add_block(p + Vector2(0, -2), block)
	return s


const FLORA: Dictionary = {
	# биом: [деревья, их число, оттенок деревьев, кусты, камни, цветы, грибы]
	1: [["tree_a", "tree_b", "tree_c", "tree_d", "pine_a", "tree_blossom", "tree_autumn"], 70, Color(1, 1, 1), 34, 18, 60, 10],
	2: [["tree_c", "tree_a", "pine_b", "tree_d", "pine_a"], 300, Color(0.66, 0.62, 0.84), 30, 14, 0, 40],
	3: [["dead_tree_a", "dead_tree_b", "dead_tree_a", "pine_b"], 120, Color(0.84, 0.8, 0.9), 26, 30, 0, 14],
	4: [["tree_a", "tree_b", "tree_d", "pine_a"], 45, Color(1, 1, 1), 30, 16, 50, 6],
	5: [["tree_blossom", "tree_c", "tree_a", "tree_blossom", "pine_b"], 260, Color(0.84, 1.04, 0.98), 40, 10, 120, 20],
	6: [["tree_c", "pine_b", "tree_blossom"], 60, Color(0.8, 0.8, 1.08), 20, 34, 40, 8],
	7: [["pine_a", "tree_autumn"], 22, Color(1.06, 0.94, 0.7), 10, 60, 0, 0],
	8: [["pine_a", "pine_b"], 60, Color(0.8, 0.82, 0.86), 6, 120, 0, 6],
	9: [["tree_blossom", "tree_a", "tree_apple", "tree_b"], 26, Color(1, 1, 1), 24, 8, 90, 4],
	10: [["tree_unicorn", "tree_unicorn", "tree_blossom", "tree_birch"], 230, Color(1, 1, 1), 30, 6, 160, 0],
	11: [["pine_b", "tree_c"], 30, Color(0.7, 0.72, 0.85), 10, 90, 0, 0],
	12: [["tree_birch", "tree_birch", "tree_birch", "tree_a"], 230, Color(1, 1, 1), 30, 10, 80, 0],
	13: [["pine_a", "pine_b", "pine_a", "pine_b", "tree_c"], 340, Color(0.92, 0.96, 0.94), 24, 20, 10, 0],
	14: [["tree_autumn", "tree_autumn2", "tree_autumn2", "tree_d"], 260, Color(1, 1, 1), 30, 12, 30, 0],
	15: [["willow_a", "willow_b", "swamp_cypress", "willow_a", "willow_b", "tree_c"], 150, Color(1, 1, 1), 34, 6, 10, 0],   # v19: ивы и болотные кипарисы
	16: [["tree_a", "tree_blossom"], 14, Color(1, 1, 1), 10, 4, 260, 0],
	17: [["tree_blossom", "tree_blossom", "bamboo", "bamboo", "pine_b"], 200, Color(1, 1, 1), 20, 18, 60, 0],
	18: [["palm"], 10, Color(1, 1, 1), 0, 14, 0, 0],
	19: [[], 0, Color(1, 1, 1), 0, 0, 0, 0],
}


## Природа региона по биому: деревья рощами (по шуму), кусты, камни, цветы, грибы
func _flora(node: Node2D, r: Vector2i) -> void:
	var rect: Rect2 = WD.region_rect(r)
	var nz: FastNoiseLite = FastNoiseLite.new()
	nz.seed = 5
	nz.frequency = 0.0022
	var b0: int = WD.biome_of_region(r)
	var tries: int = 0
	var spec0: Array = FLORA.get(b0, FLORA[1])
	var want: int = int(spec0[1])
	var made: int = 0
	while made < want and tries < want * 8:
		tries += 1
		var p: Vector2 = Vector2(rng.randf_range(rect.position.x + 10, rect.end.x - 10), rng.randf_range(rect.position.y + 10, rect.end.y - 10))
		var b: int = WD.biome_at(p)
		var spec: Array = FLORA.get(b, FLORA[1])
		# рощи: на «светлых» местах шума деревьев больше
		var dense: float = nz.get_noise_2d(p.x, p.y) * 0.5 + 0.5
		if rng.randf() > 0.25 + dense * 0.9:
			continue
		if not free_at(p, 26.0, 40.0):
			continue
		# крона высокая: дерево ниже дороги не должно закрывать её листвой
		if WD.road_value(p + Vector2(0, -55)) < 34.0 or WD.road_value(p + Vector2(0, -100)) < 26.0:
			continue
		var names: Array = spec[0]
		if names.is_empty():
			continue
		put(node, r, String(names[rng.randi_range(0, names.size() - 1)]), p, 0.5, 6.0, spec[2])   # преграда — только ствол
		made += 1
	var plan: Array = [["bush", int(spec0[3]), 0.0, 22.0], ["rock", int(spec0[4]), 10.0, 18.0], ["flower", int(spec0[5]), 0.0, 8.0], ["mush", int(spec0[6]), 0.0, 8.0]]
	for it in plan:
		for i in range(int(it[1])):
			var q: Vector2 = Vector2(rng.randf_range(rect.position.x + 10, rect.end.x - 10), rng.randf_range(rect.position.y + 10, rect.end.y - 10))
			if not free_at(q, float(it[3]), 12.0):
				continue
			if String(it[0]) in ["flower", "mush", "bush"] and under_crown(q):
				continue
			var bq: int = WD.biome_at(q)
			var tint: Color = (FLORA.get(bq, FLORA[1]) as Array)[2]
			match String(it[0]):
				"bush":
					if bq == 3:
						put(node, r, "rose_bush", q, 0.0, 0.0)
					elif bq == 15:
						put(node, r, "swamp_bush", q, 0.6, 0.0)
					else:
						put(node, r, ["bush_a", "bush_b", "bush_c"][rng.randi_range(0, 2)], q, 0.6, 0.0, tint)
				"rock":
					var big: bool = rng.randf() < 0.3
					put(node, r, "rock_big" if big else "rock", q, 0.0, 14.0 if big else 0.0, Color(1, 1, 1) if bq != 2 else Color(0.8, 0.78, 0.9))
				"flower":
					var fl: Array = ["flowers_pink", "flowers_white", "flowers_blue", "flowers_yellow"]
					if bq == 9:
						fl = ["flowers_pink", "flowers_pink", "flowers_white", "flowers_yellow"]
					put(node, r, String(fl[rng.randi_range(0, fl.size() - 1)]), q, 0.9, 0.0, Color.WHITE, false)
				"mush":
					put(node, r, "mushrooms", q, 0.0, 0.0, tint, false)


# ------------------------------------------------------------------ трава

const GRASS_TINT: Dictionary = {
	2: Color(0.7, 0.68, 0.85), 3: Color(0.72, 0.66, 0.78), 5: Color(0.85, 1.05, 0.95), 6: Color(0.88, 0.9, 1.05),
	7: Color(1.15, 1.0, 0.62), 8: Color(0.85, 0.85, 0.8), 9: Color(1.05, 1.02, 0.9), 10: Color(1.15, 0.86, 1.05),
	11: Color(0.75, 0.78, 0.9), 12: Color(1.05, 1.08, 0.9), 13: Color(0.8, 0.95, 0.85), 14: Color(1.2, 0.95, 0.6),
	15: Color(0.75, 0.88, 0.75), 16: Color(1.15, 1.08, 0.75),
}
const GRASS_NONE: Array = [18, 19]
const GRASS_SHORT: Dictionary = {2: 1300, 3: 1200, 7: 2400, 8: 700, 11: 800, 13: 1800}
const GRASS_TALL: Dictionary = {1: 260, 2: 80, 3: 80, 7: 200, 8: 40, 10: 260, 11: 40, 12: 260, 15: 320, 16: 420}


## Трава области: короткие пучки — одной пачкой (MultiMesh, быстро), высокая — спрайтами на ветру
func _grass(node: Node2D, r: Vector2i) -> void:
	var rect: Rect2 = WD.region_rect(r)
	var b0: int = WD.biome_of_region(r)
	var nz: FastNoiseLite = FastNoiseLite.new()
	nz.seed = 17
	nz.frequency = 0.004
	var groups: Array = [[], [], [], [], [], []]
	if b0 in GRASS_NONE:
		return
	var want: int = int(GRASS_SHORT.get(b0, 3200))
	for i in range(want):
		var q: Vector2 = Vector2(rng.randf_range(rect.position.x, rect.end.x), rng.randf_range(rect.position.y, rect.end.y))
		if not free_at(q, 4.0, 6.0):
			continue
		var bq: int = WD.biome_at(q)
		var v: int = rng.randi_range(0, 5)
		if bq == 7 or bq == 14:
			v = 5 if rng.randf() < 0.6 else v
		(groups[v] as Array).append([q, GRASS_TINT.get(bq, Color(1, 1, 1))])
	for v2 in range(6):
		var lst: Array = groups[v2]
		if lst.is_empty():
			continue
		mm_batch(node, "grass_s%d" % v2, lst)
	# высокая трава — кучками там, где шум «гуще»
	var tall_n: int = int(GRASS_TALL.get(b0, 180))
	var made: int = 0
	var tries: int = 0
	while made < tall_n and tries < tall_n * 6:
		tries += 1
		var p: Vector2 = Vector2(rng.randf_range(rect.position.x + 10, rect.end.x - 10), rng.randf_range(rect.position.y + 10, rect.end.y - 10))
		if nz.get_noise_2d(p.x, p.y) < -0.1:
			continue
		if not free_at(p, 10.0, 14.0):
			continue
		var bp: int = WD.biome_at(p)
		var s: Sprite2D = main.call("spr", "grass_t%d" % rng.randi_range(0, 4), p, 1.0, rng.randf() < 0.5, node, false) as Sprite2D
		s.modulate = GRASS_TINT.get(bp, Color(1, 1, 1))
		made += 1


## Много одинаковых картинок на земле одной пачкой: items — [[точка ног, цвет], ...]
func mm_batch(node: Node2D, texname: String, items: Array) -> void:
	var tex: Texture2D = load("res://art/%s.png" % texname)
	var mm: MultiMesh = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_2D
	mm.use_colors = true
	var qm: QuadMesh = QuadMesh.new()
	qm.size = Vector2(tex.get_width(), -tex.get_height())
	mm.mesh = qm
	mm.instance_count = items.size()
	for k in range(items.size()):
		var it: Array = items[k]
		var pos: Vector2 = (it[0] as Vector2).round() + Vector2(0, -tex.get_height() / 2.0)
		mm.set_instance_transform_2d(k, Transform2D(0.0, Vector2(1.0 if k % 2 == 0 else -1.0, 1.0), 0.0, pos))
		mm.set_instance_color(k, it[1])
	var mi: MultiMeshInstance2D = MultiMeshInstance2D.new()
	mi.multimesh = mm
	mi.texture = tex
	mi.z_index = -10
	node.add_child(mi)


# ------------------------------------------------------------------ оттенок света по биому

## Сумрачные края темнее и лиловее: готика, паутинный лес
func ambient_tint(p: Vector2) -> Color:
	if p.y > 120000.0:
		return Color(0.66, 0.62, 0.82)     # v19: шахта
	if p.y > 90000.0:
		return Color(0.5, 0.78, 1.14)      # под водой всё голубое
	if p.y > 7640.0 and Game.mermaid_t > 0.0 and WD.biome_at(p) == WD.SEA:
		return Color(0.60, 0.86, 1.10)     # v22: под толщей воды всё голубое
	match WD.biome_at(p):
		3:
			return Color(0.76, 0.70, 0.90)
		2:
			return Color(0.90, 0.86, 0.97)
		6:
			return Color(0.94, 0.93, 1.0)
		10:
			return Color(1.0, 0.94, 1.0)
		11:
			return Color(0.80, 0.80, 0.94)
		15:
			return Color(0.88, 0.94, 0.88)
	return Color(1, 1, 1)


# ------------------------------------------------------------------ туман карты

func fog_w() -> int:
	return int(WD.SIZE.x) / WD.FOG_CELL


func fog_h() -> int:
	return int(WD.SIZE.y) / WD.FOG_CELL


## Открыть карту вокруг точки (радиус в клетках тумана)
func reveal(p: Vector2, rad: float) -> void:
	var w: int = fog_w()
	var h: int = fog_h()
	var c: Vector2 = (p - WD.ORIGIN) / float(WD.FOG_CELL)
	for y in range(int(c.y - rad) - 1, int(c.y + rad) + 2):
		if y < 0 or y >= h:
			continue
		for x in range(int(c.x - rad) - 1, int(c.x + rad) + 2):
			if x < 0 or x >= w:
				continue
			var d: float = Vector2(x + 0.5, y + 0.5).distance_to(c)
			if d > rad:
				continue
			var v: int = int(clampf((rad - d) / 2.0, 0.0, 1.0) * 255.0)
			var i: int = y * w + x
			if v > Game.explored[i]:
				Game.explored[i] = v


# ------------------------------------------------------------------ прозрачность за деревьями

## Героиня зашла за дерево или дом — он становится полупрозрачным, чтобы её было видно
func _update_fade(p: Vector2, delta: float) -> void:
	var want: Dictionary = {}
	# героиня за деревом/домом
	_fade_pick(p, [Vector2(0, -8), Vector2(0, -22), Vector2(0, -36), Vector2(-8, -22), Vector2(8, -22)], 2, true, want)
	# курсор мыши: большая «линза» радиусом FADE_R — прозрачнеют все деревья и дома, которых она касается,
	# в середине почти насквозь, к краю линзы — слабее
	# работает, пока включён взгляд (V нажать — включить, ещё раз — выключить)
	if (DisplayServer.get_name() != "headless" and not SHOT_MODE and lens_on) or FADE_TEST != Vector2.ZERO:
		var mp: Vector2 = get_global_mouse_position() if FADE_TEST == Vector2.ZERO else FADE_TEST
		_fade_lens(mp, want)
	for s2 in want.keys():
		if not faded.has(s2):
			faded.append(s2)
	var i: int = faded.size() - 1
	while i >= 0:
		var fs: Variant = faded[i]
		if not is_instance_valid(fs):
			faded.remove_at(i)
			i -= 1
			continue
		var sp: Sprite2D = fs
		var target: float = float(want.get(sp, 1.0))
		sp.modulate.a = move_toward(sp.modulate.a, target, delta * 4.0)
		if target >= 1.0 and sp.modulate.a >= 1.0:
			faded.remove_at(i)
		i -= 1


const FADE_R: float = 190.0
var FADE_TEST: Vector2 = Vector2.ZERO
var SHOT_MODE: bool = OS.get_cmdline_user_args().has("--shotmode") or "--shot=" in " ".join(OS.get_cmdline_user_args())


func _fade_lens(mp: Vector2, want: Dictionary) -> void:
	var c0: Vector2i = Vector2i(int(floor(mp.x / 256.0)), int(floor(mp.y / 256.0)))
	for dy in range(-1, 4):
		for dx in range(-2, 3):
			for sv in tall.get(c0 + Vector2i(dx, dy), []):
				if not is_instance_valid(sv):
					continue
				var s: Sprite2D = sv
				if not s.is_visible_in_tree() or s.z_index < 0:
					continue
				var sc: Vector2 = s.global_scale.abs()
				var r: Rect2 = Rect2(s.global_position + s.offset * sc, Vector2(s.texture.get_width(), s.texture.get_height()) * sc)
				# только «тело» картинки: прозрачные поля вокруг кроны не считаем
				r = r.grow_individual(-r.size.x * 0.12, -r.size.y * 0.05, -r.size.x * 0.12, 0.0)
				var cx: float = clampf(mp.x, r.position.x, r.end.x)
				var cy: float = clampf(mp.y, r.position.y, r.end.y)
				var d: float = Vector2(cx, cy).distance_to(mp)
				if d > FADE_R:
					continue
				var a: float = lerpf(0.1, 0.55, pow(d / FADE_R, 1.4))
				want[s] = minf(float(want.get(s, 1.0)), a)


func _fade_pick(p: Vector2, pts: Array, need: int, behind_only: bool, want: Dictionary) -> void:
	var c0: Vector2i = Vector2i(int(floor(p.x / 256.0)), int(floor(p.y / 256.0)))
	for dy in range(-1 if not behind_only else 0, 3 if not behind_only else 2):
		for dx in range(-1 if behind_only else -2, 2 if behind_only else 3):
			for sv in tall.get(c0 + Vector2i(dx, dy), []):
				if not is_instance_valid(sv):
					continue
				var s: Sprite2D = sv
				if not s.is_visible_in_tree():
					continue
				if behind_only and s.global_position.y <= p.y + 2.0:
					continue
				var tw: float = float(s.texture.get_width()) * absf(s.global_scale.x)
				if absf(p.x - s.global_position.x) > tw * 0.5 + (0.0 if behind_only else 120.0):
					continue
				var img: Image = main.call("_tex_img", s.texture)
				var hits: int = 0
				for q in pts:
					var lp: Vector2 = (p + (q as Vector2) - s.global_position) / s.global_scale - s.offset
					var u: int = int(lp.x)
					if s.flip_h:
						u = s.texture.get_width() - 1 - u
					if u >= 0 and lp.y >= 0 and u < img.get_width() and lp.y < img.get_height() and img.get_pixel(u, int(lp.y)).a > 0.5:
						hits += 1
				if hits >= need:
					want[s] = minf(float(want.get(s, 1.0)), 0.3)

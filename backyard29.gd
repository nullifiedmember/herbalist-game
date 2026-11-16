extends Node
## v29/v30: дворик-огород справа от дома, прямо в мире (без перехода). Вокруг штакетник, вход — открытая
## арка в нижнем заборе. Внутри большое старое дерево с трутовиками, три лунки для грибных деревьев,
## бочка дождевой воды, а грядки игрок делает сам где хочет: мотыгой по траве — новая грядка
## (по сетке, чтобы ряды были ровные), мотыгой по пустой грядке — засыпать её обратно.
## Грядка: мотыга -> вскопано -> семя -> полить лейкой -> за ночь растёт (3 ночи) -> собрать.
## Посев «взмахом»: зажми ЛКМ и веди по грядкам — семена летят дугой, каждая грядка звенит нотой выше;
## 4+ грядки одного ряда за один взмах — «ровная борозда», урожай больше. Пугало рядом — ещё +1.
## Лейку наполняют у колодца и в бочке; дождь (weather29.gd) сам поливает грядки и наполняет бочку.

const DB = preload("res://herbs_db.gd")
const IT = preload("res://items_db.gd")
const WILD = preload("res://wild_db.gd")
const OFF: Vector2 = Vector2(118, -290)       # левый верх дворика от Game.home_pos (левый забор вплотную к стене дома)
const SIZE: Vector2 = Vector2(630, 284)
const FENCE_TOP: float = 40.0                 # ноги заднего забора (локально)
const FENCE_Y: float = 284.0                  # ноги переднего забора
const ARCH_X: float = 60.0                    # арка-вход в переднем заборе
const SEG: float = 30.0                       # ширина звена штакетника
const GX0: float = 34.0                       # сетка грядок: центр первой, шаг 44 x 32
const GY0: float = 76.0
const CW: float = 44.0
const CH: float = 32.0
const GW: int = 14
const GH: int = 6
const CAN_MAX: int = 10
const BARREL_MAX: int = 40
const RIPE: int = 3
const ROW_BONUS: int = 4
const BARREL: Vector2 = Vector2(108, 268)
const BIG_TREE: Vector2 = Vector2(520, 150)
const TREES: Array = [Vector2(572, 112)]       # v31: одно большое грибное дерево в правом углу
const TREE_SCALE: float = 1.0      # v31: новое дерево (tools/art_v31_bigtree.gd) нарисовано в размер мира — без дробного масштаба пиксели ровные
const UP_STEP: float = 96.0                   # на сколько уходит задний забор за одно расширение (3 ряда грядок)
const UP_MAX: int = 4
# v31: по краям ствола нового большого дерева (tools/art_v31_bigtree.gd: ствол ~±16 px у земли, ~±10 px на высоте 80)
const SHROOM_AT: Array = [Vector2(-18, -16), Vector2(17, -28), Vector2(-14, -50), Vector2(13, -62), Vector2(-12, -84), Vector2(12, -40)]
const NOTES: Array = [1.0, 1.122, 1.26, 1.335, 1.498, 1.682, 1.888, 2.0, 2.245, 2.52, 2.67, 2.997, 3.364, 3.776, 4.0]
const WELL_OFF: Vector2 = Vector2(190, 70)

var main: Node2D
var hud: CanvasLayer
var org: Vector2 = Vector2.ZERO
var active: bool = false        # героиня внутри забора
var root: Node2D
var cells: Array = []        # узлы by29_thing (kind "cell"), параллельно Game.yard29.cells
var trees: Array = []        # узлы (kind "tree")
var up: int = 0                       # сколько раз двор расширили вверх
var fence_nodes: Array = []
var fence_rects: Array = []
var expand_node: Node2D
var tree_spr: Sprite2D
var barrel_spr: Sprite2D
var tree_blocked: Array = []
var well_fill: Node2D
var ghost: Sprite2D
# взмах мышью
var stroke: bool = false
var stroke_mode: String = ""          # для мотыги: "make" — копаем новые, "del" — засыпаем
var stroke_done: Dictionary = {}
var stroke_n: int = 0
var stroke_rows: Dictionary = {}     # ряд -> [ключи грядок, засеянных этим взмахом]
var stroke_cd: float = 0.0
var note_p: AudioStreamPlayer
# полоска семян и лейки
var bar_layer: CanvasLayer
var bar_root: Control
var bar_sig: String = ""
var t: float = 0.0


func setup(m: Node2D, h: CanvasLayer) -> void:
	main = m
	hud = h
	org = (Game.home_pos + OFF).round()
	add_to_group("backyard29")
	Game.day_changed.connect(on_new_day)
	_init_state()
	_build_yard()
	note_p = AudioStreamPlayer.new()
	note_p.bus = "SFX"
	note_p.stream = load("res://audio/seed29.wav")
	add_child(note_p)
	_build_bar()


func _init_state() -> void:
	var y: Dictionary = Game.yard29
	if not y.has("cells"):
		y["cells"] = []
	# v30: старые 15 клеток 5x3 -> свободные грядки на тех же местах (пустые травяные — убираем)
	var old: Array = y["cells"]
	if old.size() > 0 and not (old[0] as Dictionary).has("gx"):
		var cs: Array = []
		for i in range(old.size()):
			var d: Dictionary = old[i]
			if int(d.get("s", 0)) > 0:
				d["gx"] = 1 + i % 5
				d["gy"] = 2 + i / 5
				cs.append(d)
		y["cells"] = cs
	# v31: одно большое дерево (старые три лунки убраны; привитую грибницу переносим)
	var keep: Dictionary = {"s": 2, "age": 9, "sh": "", "n": 0}
	for od in y.get("trees", []):
		if String((od as Dictionary).get("sh", "")) != "":
			keep = {"s": 2, "age": 9, "sh": od["sh"], "n": int(od.get("n", 0))}
			break
	y["trees"] = [keep]
	if not y.has("up"):
		y["up"] = 0
	up = clampi(int(y["up"]), 0, UP_MAX)
	if not y.has("barrel"):
		y["barrel"] = 20
	# подарок: мотыга и лейка с водой — у каждой травницы (и в старых сохранениях)
	if not y.has("gift"):
		y["gift"] = true
		for id in ["hoe", "watering_can"]:
			if Game.get_count(id) <= 0:
				Game.add_item(id)
			if not Game.hotbar.has(id):
				var e: int = Game.hotbar.find("")
				if e >= 0:
					Game.hotbar[e] = id
		Game.can_water = maxi(Game.can_water, 5)
	Game.yard29 = y


# ------------------------------------------------------------------ постройка

func _thing(kind: String, idx: int, p: Vector2, off: Vector2) -> Node2D:
	var n: Node2D = Node2D.new()
	n.set_script(load("res://by29_thing.gd"))
	n.set("kind", kind)
	n.set("idx", idx)
	n.set("mgr", self)
	n.set("interact_offset", off)
	n.position = p
	(main.get("objects") as Node).add_child(n)
	return n


func _sp(parent: Node, tex: String, off: Vector2, z: int = 0) -> Sprite2D:
	var s: Sprite2D = Sprite2D.new()
	s.texture = load("res://art/%s.png" % tex)
	s.centered = false
	s.offset = off
	s.z_index = z
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	parent.add_child(s)
	return s


## Преграда в мировых координатах (во дворе старой игры — списки main, иначе — сетка мира)
func _blk_rect(r: Rect2, track: bool = false) -> void:
	if track:
		fence_rects.append(r)
	if bool(main.call("home_in_yard")):
		(main.get("block_rects") as Array).append(r)
	else:
		(main.get("world") as Node).call("add_block_rect", r)


func _blk_circle(p: Vector2, r: float) -> void:
	if bool(main.call("home_in_yard")):
		main.call("block_circle", p, r)
	else:
		(main.get("world") as Node).call("add_block", p, r)


func _build_yard() -> void:
	root = Node2D.new()
	root.name = "Backyard29Root"
	main.add_child(root)
	# лес и травы на огороде не растут
	_apply_zone()
	_build_fence()
	# (v31: большое дерево убрано — на огороде деревья не растут, только грибные в лунках)
	# бочка
	var bn: Node2D = _thing("barrel", 0, org + BARREL, Vector2(0, -8))
	barrel_spr = _sp(bn, "by29_barrel_full", Vector2(-14, -35))
	_blk_rect(Rect2(org + BARREL + Vector2(-13, -8), Vector2(26, 9)))
	# грядки — сколько накопала травница
	for i in range((Game.yard29["cells"] as Array).size()):
		cells.append(_make_cell_node(i))
		_refresh_cell(i)
	# одно большое грибное дерево в правом углу
	tree_spr = main.call("spr", _tree_tex(), org + (TREES[0] as Vector2), 0.0, false, null, true)
	tree_spr.scale = Vector2.ONE * TREE_SCALE
	tree_spr.material = main.call("wind_mat", 0.25)
	var tn: Node2D = _thing("tree", 0, org + (TREES[0] as Vector2), Vector2(0, -10))
	for k in range(SHROOM_AT.size()):
		var ms: Sprite2D = Sprite2D.new()
		ms.name = "M%d" % k
		ms.position = SHROOM_AT[k]
		ms.scale = Vector2.ONE * 0.55
		ms.z_index = 1
		ms.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tn.add_child(ms)
	trees.append(tn)
	_refresh_tree(0)
	# столбик на заднем заборе: тут двор расширяют вверх
	expand_node = _thing("expand", 0, org + Vector2(SIZE.x * 0.5, _top() + 14.0), Vector2(0, -6))
	var ep: Sprite2D = _sp(expand_node, "by30_post", Vector2(-5, -30))
	ep.modulate = Color(1.15, 1.05, 0.8)
	_refresh_barrel()
	# у колодца: набрать воды в лейку (видно, только когда лейка в руке)
	well_fill = _thing("well", 0, (Game.home_pos + WELL_OFF).round(), Vector2(0, -6))
	well_fill.visible = false
	# призрак грядки под мышкой, когда в руке мотыга
	ghost = Sprite2D.new()
	ghost.texture = load("res://art/by29_soil_till_s.png")
	ghost.centered = false
	ghost.offset = Vector2(-22, -27)
	ghost.z_index = 2
	ghost.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ghost.visible = false
	root.add_child(ghost)


func _top() -> float:
	return FENCE_TOP - UP_STEP * float(up)


func _fs(tex: String, p: Vector2, cast: bool = true) -> void:
	fence_nodes.append(main.call("spr", tex, p, 0.0, false, null, cast))


func _clear_fence() -> void:
	var cs: Array = main.get("casters_static")
	for n in fence_nodes:
		if not is_instance_valid(n):
			continue
		for i in range(cs.size() - 1, -1, -1):
			if cs[i][0] == n:
				if is_instance_valid(cs[i][1]):
					(cs[i][1] as Node).queue_free()
				cs.remove_at(i)
		(n as Node).queue_free()
	fence_nodes.clear()
	var arr: Array = main.get("block_rects") if bool(main.call("home_in_yard")) else (main.get("world") as Node).get("block_rects")
	for r in fence_rects:
		arr.erase(r)
	fence_rects.clear()


## Земля двора: лес, травы и грибные места тут не появляются (вместе с расширением вверх)
func _apply_zone() -> void:
	var top: float = _top()
	var w: Node = main.get("world")
	if w != null and not bool(main.call("home_in_yard")):
		var zone: Rect2 = Rect2(org + Vector2(-24, top - 120), Vector2(SIZE.x + 48, FENCE_Y - top + 240))
		w.call("reserve", zone)
		w.call("clear_trees", zone)
		var ban: Rect2 = Rect2(org + Vector2(-8, top - 10), Vector2(SIZE.x + 16, FENCE_Y - top + 20))
		w.call("ban_plants", ban)
		for grp in ["herb_spots25", "forage", "wild_herbs"]:
			for nd in get_tree().get_nodes_in_group(grp):
				if ban.has_point((nd as Node2D).global_position):
					nd.queue_free()
	for yy in range(int(top), int(FENCE_Y) + 60, 70):
		for xx in range(0, int(SIZE.x) + 60, 70):
			main.call("mark", org + Vector2(xx, yy), 50.0)


func _build_fence() -> void:
	var top: float = _top()
	var nseg: int = int(SIZE.x / SEG)
	for k in range(nseg):
		var cx: float = SEG * k + SEG / 2.0
		# задний забор целиком, передний — с проёмом под арку
		_fs("by30_fence_h", org + Vector2(cx, top))
		if k == 0 or absf(cx - ARCH_X) > SEG:
			_fs("by30_fence_h", org + Vector2(cx, FENCE_Y))
	# боковые стороны: штакетины торцом
	var y: float = top + 6.0
	while y < FENCE_Y - 2.0:
		_fs("by30_fence_s", org + Vector2(0, y), false)
		_fs("by30_fence_s", org + Vector2(SIZE.x, y), false)
		y += 9.0
	for c in [Vector2(0, top), Vector2(SIZE.x, top), Vector2(0, FENCE_Y), Vector2(SIZE.x, FENCE_Y)]:
		_fs("by30_post", org + (c as Vector2) + Vector2(0, 1))
	_fs("by30_arch_open", org + Vector2(ARCH_X, FENCE_Y + 1))
	# преграды: забор по периметру, проход только через арку
	var gap_l: float = ARCH_X - 17.0
	var gap_r: float = ARCH_X + 17.0
	_blk_rect(Rect2(org + Vector2(-5, top - 7), Vector2(SIZE.x + 10, 8)), true)
	_blk_rect(Rect2(org + Vector2(-5, FENCE_Y - 7), Vector2(gap_l + 5, 8)), true)
	_blk_rect(Rect2(org + Vector2(gap_r, FENCE_Y - 7), Vector2(SIZE.x - gap_r + 5, 8)), true)
	_blk_rect(Rect2(org + Vector2(-5, top), Vector2(9, FENCE_Y - top)), true)
	_blk_rect(Rect2(org + Vector2(SIZE.x - 4, top), Vector2(9, FENCE_Y - top)), true)


## Расширить двор вверх на один шаг
func expand_up() -> bool:
	if up >= UP_MAX:
		return false
	up += 1
	Game.yard29["up"] = up
	_clear_fence()
	_build_fence()
	_apply_zone()
	expand_node.position = org + Vector2(SIZE.x * 0.5, _top() + 14.0)
	Sound.play("dig", -2.0, 0.1, expand_node.global_position)
	Game.fx.emit(expand_node.global_position + Vector2(0, -10), "dirt")
	Game.toast.emit("Двор стал больше: забор отодвинут вверх (%d/%d)" % [up, UP_MAX], null)
	return true


## Где можно копать: внутри забора (мировые координаты)
func yard_rect() -> Rect2:
	return Rect2(org + Vector2(4, _top() + 2), Vector2(SIZE.x - 8, FENCE_Y - _top() - 4))


static func grid_pos(gx: int, gy: int) -> Vector2:
	return Vector2(GX0 + gx * CW, GY0 + gy * CH)


func cell_pos(i: int) -> Vector2:
	var d: Dictionary = _cell(i)
	return grid_pos(int(d["gx"]), int(d["gy"]))


func _make_cell_node(i: int) -> Node2D:
	var cn: Node2D = _thing("cell", i, org + cell_pos(i), Vector2(0, -12))
	var soil: Sprite2D = _sp(cn, "by29_soil_till_s", Vector2(-22, -27), -1)
	soil.name = "Soil"
	var crop: Sprite2D = _sp(cn, "by29_sprout_0", Vector2.ZERO)
	crop.name = "Crop"
	return cn


func _key(gx: int, gy: int) -> String:
	return "%d,%d" % [gx, gy]


func _cell_index(gx: int, gy: int) -> int:
	var cs: Array = Game.yard29["cells"]
	for i in range(cs.size()):
		if int(cs[i]["gx"]) == gx and int(cs[i]["gy"]) == gy:
			return i
	return -1


## Клетка сетки под точкой мира (или (-1,-1), если вне сетки)
func grid_at(p: Vector2) -> Vector2i:
	var l: Vector2 = p - org
	var gx: int = roundi((l.x - GX0) / CW)
	var gy: int = roundi((l.y + 12.0 - GY0) / CH)
	if gx < 0 or gy < -3 * up or gx >= GW or gy >= GH:
		return Vector2i(-1, -1)
	return Vector2i(gx, gy)


## Можно ли вскопать здесь новую грядку
func can_make(g: Vector2i) -> bool:
	if g.x < 0 or _cell_index(g.x, g.y) >= 0:
		return false
	var lp: Vector2 = grid_pos(g.x, g.y)
	if lp.x + 20.0 > SIZE.x - 4.0 or lp.y - 24.0 < _top() + 6.0:
		return false
	var c: Vector2 = org + lp + Vector2(0, -12)
	for o in [Vector2.ZERO, Vector2(-16, 0), Vector2(16, 0), Vector2(0, -10), Vector2(0, 10)]:
		if bool(main.call("is_blocked", c + (o as Vector2))):
			return false
	for tp in TREES:
		if (lp + Vector2(0, -12)).distance_to((tp as Vector2) + Vector2(0, -6)) < 36.0:
			return false
	if (lp - BARREL).length() < 34.0:
		return false
	var hs: Node = main.get("homestead")
	if hs != null:
		for pe in hs.get("placed"):
			if c.distance_to((pe as Array)[1] as Vector2) < 26.0:
				return false
	return true


func make_cell(g: Vector2i) -> bool:
	if not can_make(g):
		return false
	var cs: Array = Game.yard29["cells"]
	cs.append({"gx": g.x, "gy": g.y, "s": 1, "c": "", "st": 0, "w": false, "b": 0})
	var i: int = cs.size() - 1
	cells.append(_make_cell_node(i))
	_refresh_cell(i)
	_refresh_sides(g.x, g.y)
	var at: Vector2 = org + grid_pos(g.x, g.y) + Vector2(0, -12)
	Sound.play("hoe29", -2.0, 0.12, at)
	Game.fx.emit(at, "dirt")
	get_tree().call_group("player", "react", "happy", 0.4)
	return true


## Засыпать пустую грядку — снова трава
func remove_cell(i: int) -> bool:
	var cs: Array = Game.yard29["cells"]
	if i < 0 or i >= cs.size() or String(cs[i]["c"]) != "":
		return false
	var n: Node2D = cells[i]
	var at: Vector2 = n.global_position + Vector2(0, -12)
	var rgx: int = int(cs[i]["gx"])
	var rgy: int = int(cs[i]["gy"])
	cs.remove_at(i)
	cells.remove_at(i)
	n.queue_free()
	for k in range(cells.size()):
		(cells[k] as Node2D).set("idx", k)
	_refresh_sides(rgx, rgy)
	Sound.play("dig", -4.0, 0.12, at)
	Game.fx.emit(at, "leaves")
	return true


# ------------------------------------------------------------------ вид

func _cell(i: int) -> Dictionary:
	return (Game.yard29["cells"] as Array)[i]


## v31: большое дерево в цветах биома, где стоит дом (tools/art_v31_bigtree.gd рисует все варианты)
func _tree_tex() -> String:
	var WD = preload("res://world_data.gd")
	var b: int = WD.biome_at(Game.home_pos)
	var look: String = String({WD.FIELD: "field", WD.BEACH: "beach", WD.BIRCH: "birch", WD.PINE: "pine", WD.AUTUMN: "autumn",
		WD.UNICORN: "pink", WD.GROTTO: "grotto", WD.SWAMP: "swamp"}.get(b, ""))
	var tex: String = "by29_big_tree" + ("" if look == "" else "_" + look)
	return tex if ResourceLoader.exists("res://art/%s.png" % tex) else "by29_big_tree"


func _tree(i: int) -> Dictionary:
	return (Game.yard29["trees"] as Array)[i]


## Соседи слева и справа перерисовывают концы ряда
func _refresh_sides(gx: int, gy: int) -> void:
	for dx in [-1, 1]:
		var j: int = _cell_index(gx + dx, gy)
		if j >= 0 and j < cells.size():
			_refresh_cell(j)


func _refresh_cell(i: int) -> void:
	var d: Dictionary = _cell(i)
	var n: Node2D = cells[i]
	var soil: Sprite2D = n.get_node("Soil")
	var crop: Sprite2D = n.get_node("Crop")
	# v31: ряды как на грядках с соломой — концы и середина ряда рисуются по соседям слева и справа
	var nl: bool = _cell_index(int(d["gx"]) - 1, int(d["gy"])) >= 0
	var nr: bool = _cell_index(int(d["gx"]) + 1, int(d["gy"])) >= 0
	var part: String = "m" if nl and nr else ("r" if nl else ("l" if nr else "s"))
	var wetness: String = "wet" if bool(d["w"]) else "till"
	soil.texture = load("res://art/by29_soil_%s_%s.png" % [wetness, part])
	var c: String = String(d["c"])
	crop.visible = c != ""
	crop.modulate = Color(1, 1, 1)
	if c == "":
		return
	var st: int = int(d["st"])
	var path: String = "res://art/%s_%d.png" % [c, st]
	var tex: Texture2D
	var k: float = 0.8
	if st == 0:
		tex = load("res://art/by29_sprout_0.png")
		k = 1.0
	elif ResourceLoader.exists(path):
		tex = load(path)
	elif st == 1:
		tex = load("res://art/by29_sprout_1.png")
		k = 1.0
	else:
		tex = DB.icon(c)
		k = 0.62 if st == 2 else 0.9
	crop.texture = tex
	crop.scale = Vector2.ONE * k
	crop.offset = Vector2(-floorf(tex.get_width() / 2.0), -float(tex.get_height()))
	crop.position = Vector2(0, -9)
	if int(d["b"]) > 0 and st >= RIPE:
		crop.modulate = Color(1.08, 1.06, 0.92)


func _refresh_tree(i: int) -> void:
	var d: Dictionary = _tree(i)
	var n: Node2D = trees[i]
	var sh: String = String(d["sh"])
	for k in range(SHROOM_AT.size()):
		var ms: Sprite2D = n.get_node("M%d" % k)
		ms.visible = sh != "" and k < int(d["n"])
		if ms.visible:
			ms.texture = IT.icon(sh)
			ms.flip_h = k % 2 == 1
	# ствол — преграда (один раз)
	if not tree_blocked.has(i):
		tree_blocked.append(i)
		_blk_circle(org + (TREES[i] as Vector2) + Vector2(0, -4), 16.0)


func _refresh_barrel() -> void:
	barrel_spr.texture = load("res://art/by29_barrel_%s.png" % ("full" if int(Game.yard29["barrel"]) > 0 else "low"))


# ------------------------------------------------------------------ подсказки и действия

func _seed() -> String:
	var s: String = Game.seed_sel
	if s != "" and int(Game.seeds.get(s, 0)) > 0:
		return s
	for id in Game.seeds.keys():
		if int(Game.seeds[id]) > 0 and DB.DATA.has(String(id)):
			Game.seed_sel = String(id)
			return String(id)
	return ""


func prompt(n: Node2D) -> String:
	var held: String = Game.held()
	match String(n.get("kind")):
		"well":
			return "Набрать воды в лейку (%d/%d)" % [Game.can_water, CAN_MAX]
		"barrel":
			var b: int = int(Game.yard29["barrel"])
			if held == "watering_can":
				return "Набрать воды в лейку (%d/%d)" % [Game.can_water, CAN_MAX] if b > 0 else "Бочка пуста — ждёт дождя"
			return "Дождевая бочка: %d" % b
		"tree":
			return _tree_prompt(int(n.get("idx")), held)
		"expand":
			return "Расширить двор вверх (%d/%d)" % [up, UP_MAX] if up < UP_MAX else "Двор расширен до предела"
		"cell":
			return _cell_prompt(int(n.get("idx")), held)
	return ""


func _cell_prompt(i: int, held: String) -> String:
	var d: Dictionary = _cell(i)
	var c: String = String(d["c"])
	if c == "":
		if held == "hoe":
			return "Засыпать грядку"
		var sd: String = _seed()
		return "Посеять: %s (%d)" % [DB.short(sd), int(Game.seeds.get(sd, 0))] if sd != "" else "Нет семян"
	if int(d["st"]) >= RIPE:
		return "Собрать: %s" % DB.short(c)
	if bool(d["w"]):
		return "%s растёт... до завтра" % DB.short(c)
	if held == "watering_can":
		return "Полить (в лейке %d)" % Game.can_water if Game.can_water > 0 else "Лейка пуста — набери воды"
	return "Полей из лейки: %s" % DB.short(c)


func _tree_prompt(i: int, held: String) -> String:
	var d: Dictionary = _tree(i)
	var sh: String = String(d["sh"])
	if sh == "":
		return "Привить грибницу: %s" % WILD.shroom_name(held) if WILD.is_shroom(held) else "Возьми гриб в руку — привить грибницу"
	if int(d["n"]) > 0:
		return "Собрать грибы: %s ×%d" % [WILD.shroom_name(sh), int(d["n"])]
	return "Грибы прорастут к утру"


## Действие. mouse — от клика/взмаха мышью (тогда без лишних «нельзя»)
func use(n: Node2D, mouse: bool) -> bool:
	var held: String = Game.held()
	match String(n.get("kind")):
		"well":
			if Game.can_water < CAN_MAX:
				Game.can_water = CAN_MAX
				Sound.play("pour", -4.0, 0.1, n.global_position)
				Game.fx.emit(n.global_position + Vector2(0, -16), "water")
		"barrel":
			var b: int = int(Game.yard29["barrel"])
			if held == "watering_can" and b > 0 and Game.can_water < CAN_MAX:
				var take: int = mini(b, CAN_MAX - Game.can_water)
				Game.can_water += take
				Game.yard29["barrel"] = b - take
				Sound.play("pour", -4.0, 0.1, n.global_position)
				Game.fx.emit(n.global_position + Vector2(0, -30), "water")
				_refresh_barrel()
		"tree":
			return _use_tree(int(n.get("idx")), held)
		"expand":
			return expand_up()
		"cell":
			return _use_cell(int(n.get("idx")), held, mouse)
	return true


## Пугало рядом с грядкой (поставлено через B) — птицы не клюют, урожай больше
func scarecrow_near(p: Vector2) -> bool:
	var hs: Node = main.get("homestead")
	if hs == null:
		return false
	for pe in hs.get("placed"):
		if String((pe as Array)[0]) == "scarecrow" and p.distance_to((pe as Array)[1] as Vector2) < 150.0:
			return true
	return false


func _use_cell(i: int, held: String, mouse: bool) -> bool:
	var d: Dictionary = _cell(i)
	var at: Vector2 = (cells[i] as Node2D).global_position + Vector2(0, -12)
	if String(d["c"]) == "":
		if held == "hoe":
			return remove_cell(i)
		var sd: String = _seed()
		if sd == "":
			if not mouse:
				Game.toast.emit("Семена закончились", null)
			return false
		Game.seeds[sd] = int(Game.seeds[sd]) - 1
		d["c"] = sd
		d["st"] = 0
		d["b"] = 0
		Game.inventory_changed.emit()
		_throw_seed(at, sd)
		Game.skill_xp("herb", 0.5)
		if not mouse:
			_note(0)
	elif int(d["st"]) >= RIPE:
		var c: String = String(d["c"])
		var n: int = 2 + int(d["b"]) + (1 if randf() < 0.15 * Game.skill_level("herb") / 3.0 else 0)
		if scarecrow_near(at):
			n += 1
		Game.add_item(c, n)
		if randf() < 0.6:
			Game.seeds[c] = int(Game.seeds.get(c, 0)) + 1
		Game.skill_xp("herb", 2.0)
		Game.fx.emit(at, "leaves")
		Sound.play("pick", -4.0, 0.1, at)
		d["c"] = ""
		d["st"] = 0
		d["b"] = 0
		d["w"] = false
		Game.inventory_changed.emit()
	elif not bool(d["w"]):
		if held != "watering_can" or Game.can_water <= 0:
			if held == "watering_can" and not mouse:
				Game.toast.emit("Лейка пуста — набери воды в колодце или бочке", load("res://art/icon_watering_can.png"))
			return false
		Game.can_water -= 1
		d["w"] = true
		Sound.play("sprinkle29", -4.0, 0.1, at)
		Game.fx.emit(at, "water")
	else:
		return false
	_refresh_cell(i)
	return true


func _use_tree(i: int, held: String) -> bool:
	var d: Dictionary = _tree(i)
	var at: Vector2 = (trees[i] as Node2D).global_position + Vector2(0, -20)
	if String(d["sh"]) == "":
		if not WILD.is_shroom(held) or not Game.take_item(held):
			return false
		d["sh"] = held
		d["n"] = 0
		Sound.play("magic", -8.0, 0.1, at)
		Game.fx.emit(at, "sparkle")
		Game.toast.emit("Грибница прижилась: %s" % WILD.shroom_name(held), IT.icon(held))
	elif int(d["n"]) > 0:
		var sh: String = String(d["sh"])
		Game.add_item(sh, int(d["n"]))
		Game.skill_xp("shroom", 1.5 * float(d["n"]))
		d["n"] = 0
		Sound.play("pick", -4.0, 0.1, at)
		Game.fx.emit(at, "leaves")
	else:
		return false
	_refresh_tree(i)
	return true


## Семечко летит дугой из руки героини в грядку
func _throw_seed(to: Vector2, sd: String) -> void:
	var pl: Node2D = main.get("player")
	var s: Sprite2D = Sprite2D.new()
	s.texture = load("res://art/by29_sprout_0.png")
	s.region_enabled = true
	s.region_rect = Rect2(4, 10, 4, 3)
	s.z_index = 20
	s.position = pl.global_position + Vector2(0, -22)
	main.add_child(s)
	var from: Vector2 = s.position
	var tw: Tween = create_tween()
	tw.tween_method(func(k: float) -> void:
		s.position = from.lerp(to, k) + Vector2(0, -sin(k * PI) * 26.0)
		s.rotation = k * 8.0, 0.0, 1.0, 0.28)
	tw.tween_callback(func() -> void:
		Game.fx.emit(to, "dirt")
		s.queue_free())


func _note(k: int) -> void:
	note_p.pitch_scale = float(NOTES[clampi(k, 0, NOTES.size() - 1)])
	note_p.play()


## Совместимость со старым кодом (раньше двор был отдельным местом)
func set_active(on: bool) -> void:
	active = on


func is_blocked(_p: Vector2) -> bool:
	return false


# ------------------------------------------------------------------ день, дождь

func on_new_day() -> void:
	var rained: bool = Game.rain_today >= 2.0
	for i in range(cells.size()):
		var d: Dictionary = _cell(i)
		if String(d["c"]) != "" and bool(d["w"]) and int(d["st"]) < RIPE:
			d["st"] = int(d["st"]) + 1
			# после дождя растения тянутся быстрее
			if rained and int(d["st"]) < RIPE and randf() < 0.5:
				d["st"] = int(d["st"]) + 1
		d["w"] = false
		_refresh_cell(i)
	for i in range(trees.size()):
		var d2: Dictionary = _tree(i)
		if String(d2["sh"]) != "":
			d2["n"] = mini(SHROOM_AT.size(), int(d2["n"]) + 1 + (1 if rained else 0) + (1 if randf() < 0.3 else 0))
		_refresh_tree(i)
	Game.rain_today = 0.0


## Час дождя (weather29.gd): грядки политы, бочка полнее
func rain29() -> void:
	for i in range(cells.size()):
		var d: Dictionary = _cell(i)
		if String(d["c"]) != "" and int(d["st"]) < RIPE and not bool(d["w"]):
			d["w"] = true
			_refresh_cell(i)
	Game.yard29["barrel"] = mini(BARREL_MAX, int(Game.yard29["barrel"]) + 4)
	_refresh_barrel()


# ------------------------------------------------------------------ мышь: клик и взмах

func _cell_at(p: Vector2) -> int:
	for i in range(cells.size()):
		var c: Vector2 = (cells[i] as Node2D).global_position
		if absf(p.x - c.x) <= 21.0 and p.y <= c.y + 1.0 and p.y >= c.y - 27.0:
			return i
	return -1


func _tree_at(p: Vector2) -> int:
	var l: Vector2 = p - org
	for i in range(TREES.size()):
		var c: Vector2 = TREES[i]
		if absf(l.x - c.x) <= 36.0 and l.y <= c.y + 4.0 and l.y >= c.y - 120.0:
			return i
	return -1


func _near(p: Vector2) -> bool:
	var pl: Node2D = main.get("player")
	return pl.global_position.distance_to(p) < 130.0


func _unhandled_input(event: InputEvent) -> void:
	if Game.ui_open or Game.busy:
		return
	if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var mb: InputEventMouseButton = event
		if mb.pressed:
			var mp: Vector2 = main.get_global_mouse_position()
			if not yard_rect().has_point(mp):
				return
			var ti: int = _tree_at(mp)
			if ti >= 0 and _near(mp):
				_use_tree(ti, Game.held())
				get_viewport().set_input_as_handled()
				return
			var ci: int = _cell_at(mp)
			var held: String = Game.held()
			if ci >= 0 or held in ["hoe", "watering_can"]:
				stroke = true
				stroke_mode = ""
				stroke_done.clear()
				stroke_rows.clear()
				stroke_n = 0
				stroke_cd = 0.0
				_stroke_at(mp)
				get_viewport().set_input_as_handled()
		elif stroke:
			_end_stroke()
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and stroke:
		_stroke_at(main.get_global_mouse_position())


func _stroke_at(mp: Vector2) -> void:
	if not _near(mp) or not yard_rect().has_point(mp):
		return
	var held: String = Game.held()
	var ci: int = _cell_at(mp)
	if held == "hoe":
		# мотыга — с маленькой паузой (замах); первый удар решает: копаем новые или засыпаем пустые
		if stroke_cd > 0.0:
			return
		if ci < 0:
			var g: Vector2i = grid_at(mp)
			if stroke_mode != "del" and make_cell(g):
				stroke_mode = "make"
				stroke_done[_key(g.x, g.y)] = true
				stroke_cd = 0.18
				_face(mp)
		else:
			var d0: Dictionary = _cell(ci)
			var k0: String = _key(int(d0["gx"]), int(d0["gy"]))
			if stroke_done.has(k0):
				return
			if String(d0["c"]) == "":
				if stroke_mode != "make" and remove_cell(ci):
					stroke_mode = "del"
					stroke_done[k0] = true
					stroke_cd = 0.18
					_face(mp)
			elif _use_cell(ci, held, true):
				stroke_done[k0] = true
				_face(mp)
		return
	if ci < 0:
		return
	var d: Dictionary = _cell(ci)
	var key: String = _key(int(d["gx"]), int(d["gy"]))
	if stroke_done.has(key):
		return
	var sowing: bool = String(d["c"]) == ""
	if _use_cell(ci, held, true):
		stroke_done[key] = true
		_face(mp)
		if sowing:
			_note(stroke_n)
			stroke_n += 1
			var row: int = int(d["gy"])
			if not stroke_rows.has(row):
				stroke_rows[row] = []
			(stroke_rows[row] as Array).append(key)


func _end_stroke() -> void:
	stroke = false
	# ровная борозда: 4+ грядки одного ряда засеяны одним взмахом — урожай этих грядок больше
	for row in stroke_rows.keys():
		var ks: Array = stroke_rows[row]
		if ks.size() >= ROW_BONUS:
			for kk in ks:
				var parts: PackedStringArray = String(kk).split(",")
				var i: int = _cell_index(int(parts[0]), int(parts[1]))
				if i >= 0:
					_cell(i)["b"] = 1
					Game.fx.emit((cells[i] as Node2D).global_position + Vector2(0, -16), "sparkle")
			Sound.play("magic", -6.0)
			Game.toast.emit("Ровная борозда! Урожай этого ряда будет больше", load("res://art/by29_sprout_1.png"))
			get_tree().call_group("player", "react", "happy", 1.2)
	stroke_done.clear()
	stroke_rows.clear()
	stroke_n = 0
	stroke_mode = ""


func _face(p: Vector2) -> void:
	var pl: Node2D = main.get("player")
	var d: Vector2 = p - pl.global_position
	var f: int = (2 if d.x < 0 else 3) if absf(d.x) > absf(d.y) else (1 if d.y < 0 else 0)
	pl.set("want_facing", f)


# ------------------------------------------------------------------ полоска: лейка и семена

func _build_bar() -> void:
	bar_layer = CanvasLayer.new()
	bar_layer.layer = 5
	add_child(bar_layer)
	bar_root = Control.new()
	bar_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar_root.position = Vector2(700, 990)
	bar_layer.add_child(bar_root)


func _rebuild_bar() -> void:
	for c in bar_root.get_children():
		c.queue_free()
	var ids: Array = []
	for id in Game.seeds.keys():
		if int(Game.seeds[id]) > 0 and DB.DATA.has(String(id)):
			ids.append(String(id))
	ids.sort_custom(func(a: String, b: String) -> bool: return DB.ORDER.find(a) < DB.ORDER.find(b))
	var cw: float = 70.0
	var w: float = 96.0 + cw * mini(ids.size(), 12) + 16.0
	hud.call("panel", bar_root, Vector2.ZERO, Vector2(w, 76))
	# лейка: значок и сколько воды
	var ci: TextureRect = _icon(load("res://art/icon_watering_can.png"), Vector2(14, 10), Vector2(44, 44))
	bar_root.add_child(ci)
	var wl: Label = Label.new()
	wl.text = "%d/%d" % [Game.can_water, CAN_MAX]
	wl.add_theme_font_override("font", hud.get("font_bold"))
	wl.add_theme_font_size_override("font_size", 20)
	wl.add_theme_color_override("font_color", Color("3a5a78"))
	wl.position = Vector2(60, 40)
	bar_root.add_child(wl)
	var sel: String = _seed()
	for k in range(mini(ids.size(), 12)):
		var id: String = ids[k]
		var c: Control = Control.new()
		c.position = Vector2(96 + k * cw, 4)
		c.size = Vector2(cw - 4, 68)
		c.mouse_filter = Control.MOUSE_FILTER_STOP
		c.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		c.tooltip_text = "Семена: " + DB.title(id)
		bar_root.add_child(c)
		if id == sel:
			var hl: ColorRect = ColorRect.new()
			hl.color = Color(1.0, 0.86, 0.45, 0.45)
			hl.position = Vector2(2, 2)
			hl.size = Vector2(cw - 8, 64)
			hl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			c.add_child(hl)
		var sp: String = "res://art/seeds_%s.png" % id
		var tex: Texture2D = load(sp) if ResourceLoader.exists(sp) else DB.icon(id)
		c.add_child(_icon(tex, Vector2(10, 4), Vector2(46, 46)))
		var nl: Label = Label.new()
		nl.text = str(int(Game.seeds[id]))
		nl.add_theme_font_override("font", hud.get("font_bold"))
		nl.add_theme_font_size_override("font_size", 20)
		nl.add_theme_color_override("font_color", Color("4a3220"))
		nl.position = Vector2(40, 44)
		nl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		c.add_child(nl)
		c.gui_input.connect(func(ev: InputEvent) -> void:
			if ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed and (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
				Game.seed_sel = id
				Sound.play("ui_click", -8.0)
				bar_sig = ""
				c.accept_event())


func _icon(tex: Texture2D, pos: Vector2, sz: Vector2) -> TextureRect:
	var r: TextureRect = TextureRect.new()
	r.texture = tex
	r.position = pos
	r.size = sz
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


func _process(delta: float) -> void:
	t += delta
	stroke_cd = maxf(0.0, stroke_cd - delta)
	var pl: Node2D = main.get("player")
	var was: bool = active
	active = pl != null and yard_rect().grow(6).has_point(pl.global_position)
	if active and not was and not bool(Game.yard29.get("hint30", false)):
		Game.yard29["hint30"] = true
		Game.toast.emit("Огород: мотыгой (ЛКМ) копай грядки где хочешь, по пустой грядке — засыпать", load("res://art/icon_hoe.png") if ResourceLoader.exists("res://art/icon_hoe.png") else null)
	if well_fill != null:
		well_fill.visible = Game.held() == "watering_can" and not active
	# призрак новой грядки под мышкой
	var gv: bool = false
	if active and not Game.ui_open and Game.held() == "hoe":
		var mp: Vector2 = main.get_global_mouse_position()
		if yard_rect().has_point(mp) and _cell_at(mp) < 0:
			var g: Vector2i = grid_at(mp)
			if g.x >= 0:
				gv = true
				ghost.position = org + grid_pos(g.x, g.y)
				var ok: bool = can_make(g) and _near(mp)
				ghost.modulate = Color(0.75, 1.0, 0.7, 0.5) if ok else Color(1.0, 0.5, 0.45, 0.35)
	ghost.visible = gv
	var show: bool = active and not Game.ui_open
	bar_layer.visible = show
	if show:
		var sig: String = "%d|%s|%s" % [Game.can_water, _seed(), str(Game.seeds)]
		if sig != bar_sig:
			bar_sig = sig
			_rebuild_bar()
	# спелые травы чуть покачиваются — их видно издалека
	if active:
		for i in range(cells.size()):
			var d: Dictionary = _cell(i)
			if String(d["c"]) != "" and int(d["st"]) >= RIPE:
				var cr: Sprite2D = (cells[i] as Node2D).get_node("Crop")
				cr.rotation = sin(t * 2.4 + i) * 0.05

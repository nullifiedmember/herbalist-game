extends CanvasLayer
## Стол зельевара (v16). Всё руками, без подсказок:
##  • травы и грибы лежат в шкафу слева — тащишь мышкой на инструмент или прямо в котёл;
##  • ступка: держи кнопку и крути пестиком по кругу — «растереть»;
##  • доска: стучи ножом — «нарезать»;
##  • жаровня: трава греется сама — снимешь вовремя: подсохла → обожглась → пепел;
##  • миска холодной воды — «замочить»;
##  • основы (вода холодная/тёплая/горячая, воск, спирт, мёд, лунная роса) — тащишь бутылочку к котлу,
##    держишь кнопку — она наклоняется и льётся;
##  • половник: держи кнопку в котле и мешай по кругу — зелье готово. Правая кнопка по котлу — вылить.
## Esc — выйти. Книжка справа вверху — все зелья (открытые и нет).

const DB = preload("res://herbs_db.gd")
const RDB = preload("res://recipes_db.gd")
const IT = preload("res://items_db.gd")
const W = preload("res://wild_db.gd")
const PH = preload("res://phys2d.gd")
const TABLE_Y: float = 990.0          # v19: пол стола — сюда падают брошенные травы
const INK: Color = Color("3a2718")
const PAPER: Color = Color("f4e8c8")

const SHELF: Rect2 = Rect2(32, 108, 420, 652)
const CELL0: Vector2 = Vector2(52, 136)
const CELL_STEP: Vector2 = Vector2(96, 156)
const CELL_SIZE: Vector2 = Vector2(88, 144)
const POT_R: Rect2 = Rect2(800, 420, 400, 316)        # котёл на экране
const MOUTH: Rect2 = Rect2(850, 420, 300, 90)         # горловина: сюда кидают и льют
const LIQ_Y: float = 470.0
const ST: Dictionary = {                               # инструменты на столе
	"mortar": Rect2(470, 846, 128, 104),
	"board": Rect2(630, 900, 220, 100),
	"brazier": Rect2(880, 800, 144, 140),
	"bowl": Rect2(1070, 900, 160, 80),
}
const BASES_R: Rect2 = Rect2(1280, 800, 600, 240)
const BOOK_R: Rect2 = Rect2(1780, 24, 112, 92)
const MAX_INGS: int = 4
const MAX_LIQ: float = 3.0
const BASE_ORDER: Array = ["water_cold", "water_warm", "water_hot", "spirit", "wax", "honey", "moon_dew", "bottle"]
const PROP_COL: Dictionary = {"Свежесть": Color("5cc88c"), "Покой": Color("7cb8c8"), "Сон": Color("8a78d0"), "Тепло": Color("e8a040"),
	"Исцеление": Color("f2d684"), "Сила": Color("6e963c"), "Жгучесть": Color("c8503c"), "Холод": Color("96d2f5"),
	"Огонь": Color("fa6e1e"), "Свет": Color("fff0aa"), "Тьма": Color("3c1e5a"), "Чары": Color("be5ae6")}

var root: Control
var ui: Control
var font_title: Font
var font_body: Font
var font_bold: Font
var is_open: bool = false
var tex: Dictionary = {}
var t: float = 0.0
var shelf_page: int = 0
var mouse: Vector2 = Vector2.ZERO
var held: bool = false

# на инструментах: {"ing": {id, procs}, "t": время/прогресс}
var station: Dictionary = {"mortar": {}, "board": {}, "brazier": {}, "bowl": {}}
var carry: Dictionary = {}          # {"ing": .., "from": "shelf"/инструмент}  или  {"base": предмет, "left": 0..1}
var grind_ang: float = 0.0          # угол пестика (для счёта оборотов)
var grind_last: float = 0.0
var stir: float = 0.0               # 0..1 — сколько намешано
var stir_last: float = 0.0
var stir_on: bool = false
var tilt: float = 0.0               # наклон бутылки, градусы
var knife_t: float = 0.0
var shake_t: float = 0.0
var result_id: String = ""
var result_t: float = 0.0
var result_new: bool = false
var book_open: bool = false
var tip_id: String = ""
var float_ings: Array = []          # [угол, радиус] для плавающих в котле
var loose: Array = []               # v19: брошенные на стол: {"ing", "body", "sz"}
var trail: Array = []               # последние положения мыши — для броска

var fire: CPUParticles2D
var steam: CPUParticles2D
var bubbles: CPUParticles2D
var frost: CPUParticles2D
var coals: CPUParticles2D
var stream_fx: CPUParticles2D


func _ready() -> void:
	layer = 30
	add_to_group("brew_ui")
	# v31: пиксельный шрифт (ui31.gd)
	font_title = preload("res://ui31.gd").title_font()
	font_body = preload("res://ui31.gd").pixel_font(400)
	font_bold = preload("res://ui31.gd").pixel_font(600)
	for n in ["alch_room", "st_mortar", "st_pestle", "st_board", "st_knife", "st_brazier", "st_bowl", "st_ladle", "cauldron_big", "fx_soft", "st_hearth", "icon_potionbook"]:
		tex[n] = load("res://art/%s.png" % n)
	for i in range(RDB.PROPS.size()):
		tex["prop_" + String(RDB.PROPS[i])] = load("res://art/prop_%d.png" % i)
	for b in BASE_ORDER:
		tex["icon_" + String(b)] = load("res://art/icon_%s.png" % b)
		var pp: String = "res://art/pour_%s.png" % b
		if ResourceLoader.exists(pp):
			tex["pour_" + String(b)] = load(pp)
	for id in RDB.PRODUCTS.keys():
		tex["p_" + String(id)] = RDB.icon(String(id))
	_build()
	root.visible = false


func _font(names: Array) -> SystemFont:
	var f: SystemFont = SystemFont.new()
	f.font_names = PackedStringArray(names)
	return f


func _particles(pos: Vector2, amount: int, life: float, ext: Vector2, vel: Vector2, grav: Vector2, sc: Vector2, c0: Color, c1: Color, add: bool) -> CPUParticles2D:
	var p: CPUParticles2D = CPUParticles2D.new()
	p.texture = tex["fx_soft"]
	p.amount = amount
	p.lifetime = life
	p.preprocess = life
	p.position = pos
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = ext
	p.direction = Vector2(0, -1)
	p.spread = 16.0
	p.gravity = grav
	p.initial_velocity_min = vel.x
	p.initial_velocity_max = vel.y
	p.scale_amount_min = sc.x
	p.scale_amount_max = sc.y
	var g: Gradient = Gradient.new()
	g.set_color(0, c0)
	g.set_color(1, c1)
	p.color_ramp = g
	if add:
		var m: CanvasItemMaterial = CanvasItemMaterial.new()
		m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		p.material = m
	return p


func _build() -> void:
	root = Control.new()
	root.size = Vector2(1920, 1080)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)
	var bg: TextureRect = TextureRect.new()
	bg.texture = tex["alch_room"]
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.size = Vector2(1920, 1080)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bg)
	# огонь под котлом — под самим котлом
	ui = Control.new()
	ui.size = Vector2(1920, 1080)
	ui.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(ui)
	ui.draw.connect(_draw_ui)
	ui.gui_input.connect(_on_input)
	fire = _particles(Vector2(1000, 768), 70, 0.7, Vector2(110, 6), Vector2(30, 90), Vector2(0, -80), Vector2(0.5, 1.2),
		Color(1.0, 0.9, 0.5, 0.9), Color(0.8, 0.2, 0.1, 0.0), true)
	root.add_child(fire)
	steam = _particles(Vector2(1000, LIQ_Y - 10), 18, 3.0, Vector2(130, 6), Vector2(20, 45), Vector2(0, -14), Vector2(1.4, 2.4),
		Color(1, 1, 1, 0.3), Color(1, 1, 1, 0.0), false)
	root.add_child(steam)
	frost = _particles(Vector2(1000, LIQ_Y + 4), 14, 2.4, Vector2(130, 4), Vector2(4, 12), Vector2(30, 6), Vector2(1.2, 2.2),
		Color(0.85, 0.95, 1.0, 0.35), Color(0.85, 0.95, 1.0, 0.0), false)
	frost.direction = Vector2(1, 0)
	root.add_child(frost)
	bubbles = _particles(Vector2(1000, LIQ_Y + 6), 16, 1.0, Vector2(120, 8), Vector2(20, 50), Vector2(0, 30), Vector2(0.25, 0.5),
		Color(1, 1, 1, 0.9), Color(1, 1, 1, 0.0), false)
	root.add_child(bubbles)
	coals = _particles(ST["brazier"].position + Vector2(72, 50), 22, 0.8, Vector2(48, 4), Vector2(20, 50), Vector2(0, -40), Vector2(0.3, 0.7),
		Color(1.0, 0.8, 0.4, 0.9), Color(0.9, 0.2, 0.05, 0.0), true)
	root.add_child(coals)
	stream_fx = _particles(Vector2.ZERO, 30, 0.35, Vector2(3, 2), Vector2(0, 10), Vector2(0, 900), Vector2(0.25, 0.45),
		Color(1, 1, 1, 0.9), Color(1, 1, 1, 0.6), false)
	stream_fx.direction = Vector2(0, 1)
	stream_fx.emitting = false
	root.add_child(stream_fx)


# ============================================================ открыть / закрыть
func open() -> void:
	if is_open:
		return
	if Game.tired():
		get_tree().call_group("player", "react", "sad", 1.6)
		return
	is_open = true
	Game.ui_open = true
	result_id = ""
	book_open = false
	carry = {}
	root.visible = true
	root.modulate.a = 0.0
	_sync_float()
	var tw: Tween = create_tween()
	tw.tween_property(root, "modulate:a", 1.0, 0.3)


func close() -> void:
	# всё, что лежит на инструментах и в руках, возвращается в сумку (обработка пропадает)
	_cancel_carry()
	for lo in loose:
		_give_back(String((lo["ing"] as Dictionary)["id"]))
	loose.clear()
	for k in station.keys():
		var s: Dictionary = station[k]
		if s.has("ing"):
			_give_back(String((s["ing"] as Dictionary)["id"]))
		station[k] = {}
	is_open = false
	var tw: Tween = create_tween()
	tw.tween_property(root, "modulate:a", 0.0, 0.2)
	tw.tween_callback(func() -> void:
		root.visible = false
		Game.ui_open = false)


func _input(event: InputEvent) -> void:
	if not is_open:
		return
	if event is InputEventKey and (event as InputEventKey).pressed and not (event as InputEventKey).echo:
		var k: Key = (event as InputEventKey).physical_keycode
		if k == KEY_ESCAPE or KB.is_key("interact", k) or KB.is_key("inventory", k):
			if book_open:
				book_open = false
			else:
				close()
			get_viewport().set_input_as_handled()


# ============================================================ данные
func _give_back(id: String) -> void:
	Game.inventory[id] = int(Game.inventory.get(id, 0)) + 1
	Game.inventory_changed.emit()


func _shelf_items() -> Array:
	var out: Array = []
	for id in DB.ORDER:
		if Game.get_count(String(id)) > 0:
			out.append(String(id))
	for id in W.SHROOMS.keys():
		if Game.get_count(String(id)) > 0:
			out.append(String(id))
	# v19: сушёные травы с сушилки — уже «подсушены»
	for id3 in DB.ORDER:
		if Game.get_count("dry:" + String(id3)) > 0:
			out.append("dry:" + String(id3))
	# v17: листья деревьев и пойманные насекомые тоже идут в котёл
	for id2 in Game.inventory.keys():
		var s2: String = String(id2)
		if Game.get_count(s2) > 0 and preload("res://tree_db.gd").is_ingredient(s2) and not out.has(s2):
			out.append(s2)
	return out


func _base_items() -> Array:
	var out: Array = []
	for b in BASE_ORDER:
		if Game.get_count(String(b)) > 0:
			out.append(String(b))
	return out


func _cell_rect(k: int) -> Rect2:
	return Rect2(CELL0 + Vector2(float(k % 4) * CELL_STEP.x, float(k / 4) * CELL_STEP.y), CELL_SIZE)


func _base_rect(k: int) -> Rect2:
	return Rect2(BASES_R.position + Vector2(float(k % 4) * 150.0, float(k / 4) * 120.0), Vector2(140, 112))


func _icon(id: String) -> Texture2D:
	if id.begins_with("dry:"):
		return IT.icon(id)
	if not tex.has("i_" + id):
		tex["i_" + id] = W.shroom_icon(id) if W.is_shroom(id) else (IT.icon(id) if IT.is_leaf(id) or IT.is_bug(id) or IT.MT.has(id) else DB.icon(id))
	return tex["i_" + id]


func _name(id: String) -> String:
	if id.begins_with("dry:"):
		return IT.name(id)
	return W.shroom_name(id) if W.is_shroom(id) else (IT.name(id) if IT.is_leaf(id) or IT.is_bug(id) or IT.MT.has(id) else DB.short(id))


## Свойства смеси в котле (с основой и температурой), для значков над котлом
func _pot_props() -> Dictionary:
	var ings: Array = Game.cauldron["ings"]
	var base: String = Game.cauldron_base()
	var m: Dictionary = RDB.mix_list(ings)
	if base != "":
		m = RDB.finish(m, base, Game.cauldron_temp())
	return m


func _liquid_color() -> Color:
	var base: String = Game.cauldron_base()
	var c: Color = RDB.color(base if base != "" else "water")
	if base == "water":
		c = c.lerp(Color("b8e4ff"), 0.3) if Game.cauldron_temp() == "cold" else (c.lerp(Color("5a8ab0"), 0.25) if Game.cauldron_temp() == "hot" else c)
	var m: Dictionary = RDB.mix_list(Game.cauldron["ings"])
	var tot: float = 0.0
	var mixc: Color = Color(0, 0, 0)
	for k in m.keys():
		var n: float = float(m[k])
		mixc += PROP_COL.get(k, Color.GRAY) * n
		tot += n
	if tot > 0.0:
		c = c.lerp(mixc / tot, minf(0.85, 0.25 + tot * 0.07))
	return c


func _sync_float() -> void:
	float_ings.clear()
	var ings: Array = Game.cauldron["ings"]
	for i in range(ings.size()):
		float_ings.append([TAU * float(i) / maxf(1.0, float(ings.size())) + 0.4, 70.0 + 30.0 * float(i % 2)])


# ============================================================ действия (их же зовёт автотест)
## Бросить ингредиент в котёл
func put_in_cauldron(ing: Dictionary) -> bool:
	var ings: Array = Game.cauldron["ings"]
	if ings.size() >= MAX_INGS:
		return false
	ings.append(ing.duplicate(true))
	_sync_float()
	_splash(PROP_COL.get(RDB.strongest(RDB.ing_props(ing)), Color.WHITE))
	Sound.play("bubble", -6.0)
	return true


## Влить основу из предмета целиком (для автотеста и мгновенного налива)
func pour(item: String, amount: float = 1.0) -> bool:
	if not IT.BASE_ITEMS.has(item) or Game.cauldron_amount() >= MAX_LIQ:
		return false
	var b: Array = IT.BASE_ITEMS[item]
	var liq: Dictionary = Game.cauldron["liq"]
	var a: float = minf(amount, MAX_LIQ - Game.cauldron_amount())
	liq[String(b[0])] = float(liq.get(String(b[0]), 0.0)) + a
	if float(b[1]) >= 0.0:
		Game.cauldron["heat"] = float(Game.cauldron["heat"]) + float(b[1]) * a
	return true


## Совместимость: старый автотест кладёт траву сразу в котёл
func add_herb(id: String) -> void:
	if Game.get_count(id) <= 0:
		return
	Game.take_item(id)
	put_in_cauldron({"id": id, "procs": []})


func can_brew() -> bool:
	return Game.cauldron_amount() >= 0.5 and not (Game.cauldron["ings"] as Array).is_empty()


## Сварить сразу (без помешивания)
func do_brew() -> String:
	if not can_brew():
		return ""
	var base: String = Game.cauldron_base()
	var temp: String = Game.cauldron_temp() if base == "water" else "warm"
	var ings: Array = (Game.cauldron["ings"] as Array).duplicate(true)
	var known_before: bool = Game.known_recipes.has(RDB.brew_mix(base, temp, ings))
	var res: String = Game.brew_mix(base, temp, ings)
	Game.cauldron_clear()
	float_ings.clear()
	stir = 0.0
	result_id = res
	result_t = 0.0
	result_new = res != "murky" and not known_before
	var burst: CPUParticles2D = _particles(Vector2(1000, LIQ_Y), 60, 1.2, Vector2(110, 10), Vector2(80, 220), Vector2(0, 200), Vector2(0.4, 1.0),
		RDB.color(res).lightened(0.4), Color(RDB.color(res), 0.0), true)
	burst.one_shot = true
	burst.preprocess = 0.0
	burst.explosiveness = 0.85
	root.add_child(burst)
	burst.emitting = true
	get_tree().create_timer(2.0).timeout.connect(burst.queue_free)
	Sound.play("magic" if RDB.rarity(res) >= 1 else ("coin" if res != "murky" else "bubble"), -4.0)
	return res


func _splash(c: Color) -> void:
	var p: CPUParticles2D = _particles(Vector2(1000, LIQ_Y), 24, 0.7, Vector2(30, 4), Vector2(80, 180), Vector2(0, 420), Vector2(0.25, 0.5),
		c.lightened(0.3), Color(c, 0.0), false)
	p.one_shot = true
	p.preprocess = 0.0
	p.explosiveness = 0.9
	p.spread = 50.0
	root.add_child(p)
	p.emitting = true
	get_tree().create_timer(1.2).timeout.connect(p.queue_free)


## Обработка, которую даст инструмент (или "" — нельзя)
func _station_proc(k: String, s: Dictionary) -> String:
	match k:
		"mortar":
			return "grind" if float(s.get("t", 0.0)) >= 1.0 else ""
		"board":
			return "cut" if float(s.get("t", 0.0)) >= 1.0 else ""
		"bowl":
			return "soak" if float(s.get("t", 0.0)) >= 3.0 else ""
		"brazier":
			var bt: float = float(s.get("t", 0.0))
			return "ash" if bt >= 7.0 else ("burn" if bt >= 4.5 else ("dry" if bt >= 2.0 else ""))
	return ""


func _can_take(ing: Dictionary, k: String) -> bool:
	var pr: Array = ing.get("procs", [])
	if pr.has("ash") or pr.size() >= 2:
		return false
	var want: Array = {"mortar": ["grind"], "board": ["cut"], "bowl": ["soak"], "brazier": ["dry", "burn"]}[k]
	for w in want:
		if pr.has(w):
			return false
	return true


## Снять с инструмента: применить обработку
func _take_from(k: String) -> Dictionary:
	var s: Dictionary = station[k]
	var ing: Dictionary = (s["ing"] as Dictionary).duplicate(true)
	var p: String = _station_proc(k, s)
	if p == "ash":
		ing["procs"] = ["ash"]
	elif p != "":
		(ing["procs"] as Array).append(p)
	station[k] = {}
	return ing


# ============================================================ ввод
func _station_at(p: Vector2) -> String:
	for k in ST.keys():
		if (ST[k] as Rect2).has_point(p):
			return String(k)
	return ""


func _on_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse = (event as InputEventMouseMotion).position
		trail.append([mouse, t])
		while trail.size() > 2 and t - float(trail[0][1]) > 0.1:
			trail.pop_front()
		_hover_tip()
		return
	if not (event is InputEventMouseButton):
		return
	var mb: InputEventMouseButton = event
	mouse = mb.position
	if mb.pressed and (mb.button_index == MOUSE_BUTTON_WHEEL_DOWN or mb.button_index == MOUSE_BUTTON_WHEEL_UP):
		if SHELF.has_point(mb.position):
			shelf_page += 1 if mb.button_index == MOUSE_BUTTON_WHEEL_DOWN else -1
			var n: int = _shelf_items().size()
			shelf_page = clampi(shelf_page, 0, maxi(0, (n - 1) / 16))
		return
	if mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
		if POT_R.has_point(mb.position) and carry.is_empty():
			_dump()
		var sk2: String = _station_at(mb.position)
		if sk2 != "" and carry.is_empty() and (station[sk2] as Dictionary).has("ing"):
			_give_back(String(((station[sk2] as Dictionary)["ing"] as Dictionary)["id"]))
			station[sk2] = {}
		return
	if mb.button_index != MOUSE_BUTTON_LEFT:
		return
	if mb.pressed:
		held = true
		_press(mb.position)
	else:
		held = false
		_release(mb.position)


func _press(p: Vector2) -> void:
	if result_id != "":
		if result_t > 0.4:
			result_id = ""
		return
	if book_open:
		book_open = false
		return
	if BOOK_R.has_point(p):
		book_open = true
		return
	# брошенное на столе — поднять (сверху то, что брошено позже)
	for li in range(loose.size() - 1, -1, -1):
		if PH.has_point(loose[li]["body"], p, 12.0):
			carry = {"ing": loose[li]["ing"], "from": "table"}
			loose.remove_at(li)
			Sound.play("pick", -10.0)
			return
	# шкаф с травами
	var items: Array = _shelf_items()
	for k in range(16):
		var gi: int = shelf_page * 16 + k
		if gi < items.size() and _cell_rect(k).has_point(p):
			var id: String = String(items[gi])
			Game.take_item(id)
			if id.begins_with("dry:"):
				carry = {"ing": {"id": id.substr(4), "procs": ["dry"]}, "from": "shelf", "dry": true}
			else:
				carry = {"ing": {"id": id, "procs": []}, "from": "shelf"}
			return
	# основы на столе
	var bs: Array = _base_items()
	for k in range(bs.size()):
		if _base_rect(k).has_point(p) and String(bs[k]) != "bottle":
			Game.take_item(String(bs[k]))
			carry = {"base": String(bs[k]), "left": 1.0}
			tilt = 0.0
			return
	# инструменты
	var sk: String = _station_at(p)
	if sk != "":
		var s: Dictionary = station[sk]
		if s.has("ing"):
			if sk == "board" and float(s.get("t", 0.0)) < 1.0:
				_knife_hit()
				return   # стучит ножом
			if sk == "mortar" and float(s.get("t", 0.0)) < 1.0:
				grind_last = (p - (ST["mortar"] as Rect2).get_center()).angle()
				return   # держит — значит толчёт
			carry = {"ing": _take_from(sk), "from": sk}
		return
	# котёл: мешать
	if POT_R.has_point(p) and can_brew():
		stir_on = true
		stir_last = (p - POT_R.get_center()).angle()


## Удар ножом по доске
func _knife_hit() -> bool:
	var s: Dictionary = station["board"]
	if not s.has("ing") or float(s.get("t", 0.0)) >= 1.0:
		return false
	s["t"] = minf(1.0, float(s.get("t", 0.0)) + 0.2)
	knife_t = 0.18
	Sound.play("chop", -8.0)
	return true


func _release(p: Vector2) -> void:
	stir_on = false
	if carry.is_empty():
		return
	if carry.has("base"):
		var item: String = String(carry["base"])
		var left: float = float(carry["left"])
		if left >= 0.999:
			_give_back(item)
		else:
			var after: String = String((IT.BASE_ITEMS[item] as Array)[2])
			if after != "":
				_give_back(after)
		carry = {}
		tilt = 0.0
		stream_fx.emitting = false
		return
	var ing: Dictionary = carry["ing"]
	var from: String = String(carry["from"])
	carry = {}
	if MOUTH.has_point(p) or POT_R.has_point(p):
		if put_in_cauldron(ing):
			return
	var sk: String = _station_at(p)
	if sk != "" and not (station[sk] as Dictionary).has("ing") and _can_take(ing, sk):
		station[sk] = {"ing": ing, "t": 0.0}
		if sk == "bowl":
			_splash(Color("8ac0e8"))
		return
	if SHELF.has_point(p):
		_give_back(String(ing["id"]))   # обработка пропадает, трава — обратно в шкаф
		return
	# v19: всё остальное — бросок: трава летит, крутится и падает на стол
	throw_ing(ing, p, PH.throw_vel(trail))


## Бросить ингредиент из руки (его же зовёт автотест)
func throw_ing(ing: Dictionary, at: Vector2, vel: Vector2) -> void:
	var ic: Texture2D = _icon(String(ing["id"]))
	var sz: Vector2 = Vector2(ic.get_width(), ic.get_height()) * 2.0
	var bd: Dictionary = PH.make(at, Vector2(sz.x * 0.6, sz.y * 0.8), vel, vel.x * 0.008 + randf_range(-2.0, 2.0), randf_range(-0.2, 0.2))
	loose.append({"ing": ing, "body": bd, "sz": sz, "age": 0.0})


## Брошенные травы: падают, крутятся; влетели в котёл — в котле, легли на инструмент — на нём
func _step_loose(delta: float) -> void:
	var bodies: Array = []
	for i in range(loose.size() - 1, -1, -1):
		var lo: Dictionary = loose[i]
		var bd: Dictionary = lo["body"]
		lo["age"] = float(lo["age"]) + delta
		if PH.step(bd, delta, TABLE_Y, 8.0, 1912.0):
			Sound.play("pick", -18.0, 0.25)
		var c: Vector2 = bd["pos"]
		# в горловину котла (падая сверху)
		if MOUTH.grow(20).has_point(c) and Vector2(bd["vel"]).y > 0.0:
			if put_in_cauldron(lo["ing"]):
				loose.remove_at(i)
				_splash(_liquid_color())
				continue
		# в шкаф
		if SHELF.has_point(c) and PH.resting(bd):
			_give_back(String((lo["ing"] as Dictionary)["id"]))
			loose.remove_at(i)
			continue
		# легло на инструмент
		if PH.resting(bd):
			var sk: String = _station_at(c)
			if sk == "":
				sk = _station_at(c + Vector2(0, float(bd["hy"])))
			if sk != "" and not (station[sk] as Dictionary).has("ing") and _can_take(lo["ing"], sk):
				station[sk] = {"ing": lo["ing"], "t": 0.0}
				loose.remove_at(i)
				if sk == "bowl":
					_splash(Color("8ac0e8"))
				continue
		bodies.append(bd)
	PH.collide_all(bodies)


func _cancel_carry() -> void:
	if carry.has("ing"):
		_give_back(String((carry["ing"] as Dictionary)["id"]))
	elif carry.has("base"):
		_release(Vector2(-100, -100))
	carry = {}


func _dump() -> void:
	if Game.cauldron_amount() <= 0.0 and (Game.cauldron["ings"] as Array).is_empty():
		return
	_splash(_liquid_color())
	Game.cauldron_clear()
	float_ings.clear()
	stir = 0.0


func _hover_tip() -> void:
	tip_id = ""
	var items: Array = _shelf_items()
	for k in range(16):
		var gi: int = shelf_page * 16 + k
		if gi < items.size() and _cell_rect(k).has_point(mouse):
			tip_id = String(items[gi])


# ============================================================ кадр
func _process(delta: float) -> void:
	if not is_open:
		return
	t += delta
	knife_t = maxf(0.0, knife_t - delta)
	shake_t = maxf(0.0, shake_t - delta)
	if result_id != "":
		result_t += delta
	_step_loose(delta)
	# инструменты сами: жаровня и миска — по времени
	for k in ["brazier", "bowl"]:
		var s: Dictionary = station[k]
		if s.has("ing"):
			s["t"] = float(s["t"]) + delta
	# ступка: крутить пестиком, держа кнопку
	var ms: Dictionary = station["mortar"]
	if held and carry.is_empty() and ms.has("ing") and float(ms["t"]) < 1.0 and (ST["mortar"] as Rect2).grow(40).has_point(mouse):
		var a: float = (mouse - (ST["mortar"] as Rect2).get_center()).angle()
		var d: float = absf(wrapf(a - grind_last, -PI, PI))
		grind_last = a
		if d < 1.2:
			ms["t"] = minf(1.0, float(ms["t"]) + d / (TAU * 4.0))
			grind_ang += d
			if grind_ang > 2.5:
				grind_ang = 0.0
				Sound.play("grind", -8.0)
	# котёл: мешать половником
	if stir_on and held and can_brew():
		var a2: float = (mouse - POT_R.get_center()).angle()
		var d2: float = absf(wrapf(a2 - stir_last, -PI, PI))
		stir_last = a2
		if d2 < 1.2:
			stir += d2 / (TAU * 3.0)
			for f in float_ings:
				f[0] = float(f[0]) + d2 * 0.8
				f[1] = maxf(10.0, float(f[1]) - d2 * 6.0)
		if stir >= 1.0:
			stir_on = false
			do_brew()
	# наливание: бутылка над горловиной, кнопка зажата — наклоняется и льётся
	if carry.has("base"):
		var over: bool = MOUTH.grow(60).has_point(mouse) and held
		tilt = move_toward(tilt, -110.0 if over else 0.0, delta * 260.0)
		var pouring: bool = tilt < -70.0 and float(carry["left"]) > 0.0 and Game.cauldron_amount() < MAX_LIQ
		if pouring and not stream_fx.emitting:
			Sound.play("pour", -4.0)
		stream_fx.emitting = pouring
		if pouring:
			var a3: float = minf(delta * 0.7, float(carry["left"]))
			pour(String(carry["base"]), a3)
			carry["left"] = float(carry["left"]) - a3
			stream_fx.position = _bottle_mouth()
			stream_fx.color = RDB.color(String((IT.BASE_ITEMS[String(carry["base"])] as Array)[0]))
	else:
		stream_fx.emitting = false
	# частицы котла
	var amt: float = Game.cauldron_amount()
	var temp: String = Game.cauldron_temp()
	var water: bool = Game.cauldron_base() == "water"
	steam.emitting = amt > 0.0 and not (water and temp == "cold")
	steam.amount = 26 if (water and temp == "hot") else 14
	frost.emitting = amt > 0.0 and water and temp == "cold"
	bubbles.emitting = amt > 0.0
	bubbles.color = _liquid_color().lightened(0.4)
	for f in float_ings:
		f[0] = float(f[0]) + delta * 0.25
	coals.emitting = true
	var calm: bool = not book_open
	for pn in [fire, steam, frost, bubbles, coals, stream_fx]:
		(pn as CPUParticles2D).visible = calm
	ui.queue_redraw()


func _bottle_mouth() -> Vector2:
	var r: float = deg_to_rad(tilt)
	return mouse + Vector2(0, -36).rotated(r) * 2.0


# ============================================================ рисование
func _draw_ui() -> void:
	# --- шкаф: травы и грибы
	var items: Array = _shelf_items()
	for k in range(16):
		var gi: int = shelf_page * 16 + k
		var r: Rect2 = _cell_rect(k)
		if gi >= items.size():
			continue
		var id: String = String(items[gi])
		var hov: bool = r.has_point(mouse) and carry.is_empty()
		var ic: Texture2D = _icon(id)
		var isz: Vector2 = Vector2(ic.get_width(), ic.get_height()) * 2.0
		var at: Vector2 = r.position + Vector2((r.size.x - isz.x) / 2.0, r.size.y - 14.0 - isz.y - (4.0 if hov else 0.0))
		ui.draw_texture_rect(ic, Rect2(at, isz), false)
		_draw_count(r.position + Vector2(r.size.x - 8, r.size.y - 4), Game.get_count(id))
	# листание шкафа — точки
	var pages: int = (items.size() + 15) / 16
	if pages > 1:
		for i in range(pages):
			ui.draw_rect(Rect2(SHELF.get_center().x - pages * 10 + i * 20, 768, 10, 10), Color("f0d8a0") if i == shelf_page else Color(0.2, 0.12, 0.06, 0.8))
	# --- котёл
	_draw_cauldron()
	# --- инструменты
	_draw_stations()
	# --- основы
	var bs: Array = _base_items()
	for k in range(bs.size()):
		var br: Rect2 = _base_rect(k)
		var b: String = String(bs[k])
		var it: Texture2D = tex["icon_" + b]
		var lift: float = 4.0 if br.has_point(mouse) and carry.is_empty() and b != "bottle" else 0.0
		ui.draw_texture_rect(it, Rect2(br.position + Vector2(38, 18 - lift), Vector2(64, 64)), false)
		_draw_count(br.position + Vector2(118, 104), Game.get_count(b))
	# --- книжка зелий
	_draw_book_icon()
	# --- брошенные на стол (v19)
	for lo in loose:
		var bd2: Dictionary = lo["body"]
		ui.draw_set_transform(Vector2(bd2["pos"]), float(bd2["ang"]), Vector2.ONE)
		_draw_ing(lo["ing"], Vector2(0, -4), 2.0)
		ui.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# --- в руках
	if carry.has("ing"):
		var off: Vector2 = Vector2(sin(shake_t * 60.0) * 6.0, 0) if shake_t > 0.0 else Vector2.ZERO
		_draw_ing(carry["ing"], mouse + off + Vector2(0, -10), 2.0)
	elif carry.has("base"):
		_draw_bottle()
	elif tip_id != "":
		_draw_tip(tip_id)
	if book_open:
		_draw_book()
	if result_id != "":
		_draw_result()


func _draw_count(br: Vector2, n: int) -> void:
	var s: String = str(n)
	ui.draw_string_outline(font_bold, br - Vector2(14 * s.length(), 0), s, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, 6, Color("1a0e08"))
	ui.draw_string(font_bold, br - Vector2(14 * s.length(), 0), s, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, PAPER)


## Ингредиент с видом обработки: растёртый — горка порошка, резаный — ломтики, сушёный — бурый,
## обожжённый — тёмный с угольками, пепел — серая горка, замоченный — голубоватый и блестит
func _draw_ing(ing: Dictionary, c: Vector2, sc: float) -> void:
	var id: String = String(ing["id"])
	var pr: Array = ing.get("procs", [])
	var ic: Texture2D = _icon(id)
	var sz: Vector2 = Vector2(ic.get_width(), ic.get_height()) * sc
	var mod: Color = Color.WHITE
	if pr.has("dry"):
		mod = mod * Color(0.95, 0.8, 0.55)
	if pr.has("burn"):
		mod = mod * Color(0.45, 0.32, 0.28)
	if pr.has("soak"):
		mod = mod * Color(0.75, 0.9, 1.15)
	if pr.has("ash"):
		_pile(c + Vector2(0, sz.y * 0.2), 22.0 * sc / 2.0, Color("8a8580"))
		return
	if pr.has("grind"):
		var main: Color = PROP_COL.get(RDB.strongest(RDB.ing_props(ing)), Color("6aa852"))
		_pile(c + Vector2(0, sz.y * 0.2), 24.0 * sc / 2.0, main.lerp(Color("6a8a4a"), 0.3) * mod)
		ui.draw_texture_rect(ic, Rect2(c - sz * 0.25 + Vector2(0, -sz.y * 0.1), sz * 0.5), false, mod)
		return
	if pr.has("cut"):
		# три ломтика со сдвигом
		var src_h: float = float(ic.get_height()) / 3.0
		for i in range(3):
			var dst: Rect2 = Rect2(c - sz / 2.0 + Vector2(float(i - 1) * 6.0 * sc / 2.0, float(i) * sz.y / 3.0 + float(i) * 3.0), Vector2(sz.x, sz.y / 3.0))
			ui.draw_texture_rect_region(ic, dst, Rect2(0, src_h * float(i), ic.get_width(), src_h), mod)
		return
	ui.draw_texture_rect(ic, Rect2(c - sz / 2.0, sz), false, mod)
	if pr.has("burn"):
		for i in range(5):
			var e: Vector2 = c + Vector2(sin(t * 3.0 + i * 2.1) * sz.x * 0.3, cos(t * 2.0 + i) * sz.y * 0.3)
			ui.draw_rect(Rect2(e, Vector2(4, 4)), Color(1.0, 0.55 + 0.3 * sin(t * 9.0 + i), 0.1))
	if pr.has("soak"):
		for i in range(3):
			var e2: Vector2 = c + Vector2(float(i - 1) * sz.x * 0.3, -sz.y * 0.2 + float(i % 2) * 14.0)
			ui.draw_rect(Rect2(e2, Vector2(4, 4)), Color(0.9, 0.97, 1.0, 0.8))


## Горка порошка/пепла пикселями
func _pile(c: Vector2, r: float, col: Color) -> void:
	var px: float = 4.0
	var ny: int = int(r / px)
	for yi in range(ny):
		var w: int = int((r - float(yi) * px * 0.9) / px)
		for xi in range(-w, w + 1):
			var k: float = 0.15 if xi < -w / 3 else (-0.2 if xi > w / 3 else 0.0)
			var cc: Color = col.lightened(k) if k > 0.0 else col.darkened(-k)
			ui.draw_rect(Rect2(c + Vector2(float(xi) * px, -float(yi) * px), Vector2(px, px)), cc)


func _draw_cauldron() -> void:
	var amt: float = Game.cauldron_amount()
	# жидкость рисуется в котле: эллипс, уровень от объёма
	ui.draw_texture_rect(tex["st_hearth"], Rect2(770, 724, 460, 128), false)
	ui.draw_texture_rect(tex["cauldron_big"], Rect2(POT_R.position.x - 40, POT_R.position.y - 20, 480, 380), false)
	if amt > 0.0:
		var col: Color = _liquid_color()
		var lvl: float = LIQ_Y + 26.0 - amt / MAX_LIQ * 26.0
		var rx: float = 150.0
		var ry: float = 30.0
		var pts: PackedVector2Array = PackedVector2Array()
		for i in range(40):
			var a: float = TAU * float(i) / 40.0
			pts.append(Vector2(1000 + cos(a) * rx, lvl + sin(a) * ry + sin(t * 2.0 + a * 3.0) * 1.5))
		ui.draw_colored_polygon(pts, col.darkened(0.2))
		var pts2: PackedVector2Array = PackedVector2Array()
		for i in range(40):
			var a2: float = TAU * float(i) / 40.0
			pts2.append(Vector2(1000 - 14 + cos(a2) * (rx - 26.0), lvl - 4 + sin(a2) * (ry - 9.0)))
		ui.draw_colored_polygon(pts2, col)
		# блики-рябь
		for i in range(6):
			var bx: float = 1000.0 + sin(t * 0.7 + float(i) * 1.7) * 100.0
			var by: float = lvl + cos(t * 0.9 + float(i)) * 14.0
			ui.draw_rect(Rect2(bx, by, 12, 3), col.lightened(0.45))
		# плавающие травы
		var ings: Array = Game.cauldron["ings"]
		for i in range(mini(ings.size(), float_ings.size())):
			var f: Array = float_ings[i]
			var p: Vector2 = Vector2(1000 + cos(float(f[0])) * float(f[1]), lvl + sin(float(f[0])) * float(f[1]) * 0.22 - 12.0)
			_draw_ing(ings[i], p, 1.2)
		# половник — в котле, наклонён по ходу помешивания
		var la: float = (stir_last if stir_on else sin(t * 0.6) * 0.3)
		var lp: Vector2 = Vector2(1000 + cos(la) * 60.0, lvl + sin(la) * 12.0)
		ui.draw_set_transform(lp + Vector2(0, -140), 0.25 + cos(la) * 0.2, Vector2(2, 2))
		ui.draw_texture(tex["st_ladle"], Vector2(-12, 0))
		ui.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		# сколько намешано — кольцо из точек вокруг котла
		if stir > 0.0:
			var n: int = 24
			for i in range(n):
				var a3: float = -PI / 2.0 + TAU * float(i) / float(n)
				var on: bool = float(i) / float(n) < stir
				ui.draw_rect(Rect2(Vector2(1000 + cos(a3) * 230.0, 580 + sin(a3) * 190.0) - Vector2(5, 5), Vector2(10, 10)),
					Color("f8d870") if on else Color(0.1, 0.06, 0.03, 0.5))
	# свойства смеси: значок + столько точек, какова сила
	var m: Dictionary = _pot_props()
	var keys: Array = []
	for k in RDB.PROPS:
		if int(m.get(k, 0)) > 0:
			keys.append(String(k))
	var x0: float = 1000.0 - float(keys.size()) * 46.0
	for i in range(keys.size()):
		var k2: String = keys[i]
		var px: Vector2 = Vector2(x0 + float(i) * 92.0, 330.0)
		ui.draw_rect(Rect2(px - Vector2(6, 6), Vector2(84, 74)), Color(0.12, 0.07, 0.04, 0.55))
		ui.draw_texture_rect(tex["prop_" + k2], Rect2(px + Vector2(24, 0), Vector2(36, 36)), false)
		var n2: int = int(m[k2])
		for d in range(n2):
			var dx: float = float(d % 5) * 14.0 + 8.0
			var dy: float = 44.0 + float(d / 5) * 12.0
			ui.draw_rect(Rect2(px + Vector2(dx, dy), Vector2(10, 10)), PROP_COL[k2])
			ui.draw_rect(Rect2(px + Vector2(dx, dy), Vector2(10, 2)), Color(PROP_COL[k2]).lightened(0.4))
	# основа: значок того, что налито, и градусник у воды
	var base: String = Game.cauldron_base()
	if base != "":
		var bi: String = {"water": "water_" + Game.cauldron_temp(), "wax": "wax", "spirit": "spirit", "honey": "honey", "moon_dew": "moon_dew"}[base]
		ui.draw_texture_rect(tex["icon_" + bi], Rect2(1196, 640, 64, 64), false)
		# сколько налито — три капли
		for i in range(3):
			var full: float = clampf(amt - float(i), 0.0, 1.0)
			var r: Rect2 = Rect2(1270, 690 - i * 26, 16, 20)
			ui.draw_rect(r, Color(0.1, 0.06, 0.03, 0.6))
			ui.draw_rect(Rect2(r.position.x, r.end.y - r.size.y * full, r.size.x, r.size.y * full), RDB.color(base))


func _draw_stations() -> void:
	# ступка с пестиком
	var mr: Rect2 = ST["mortar"]
	ui.draw_texture_rect(tex["st_mortar"], mr, false)
	var ms: Dictionary = station["mortar"]
	if ms.has("ing"):
		var g: float = float(ms["t"])
		var ing: Dictionary = (ms["ing"] as Dictionary).duplicate(true)
		if g >= 1.0:
			(ing["procs"] as Array).append("grind")
			_draw_ing(ing, mr.position + Vector2(64, 30), 1.2)
		else:
			_draw_ing(ing, mr.position + Vector2(64, 24 + g * 10.0), 1.4 - g * 0.4)
		_progress(mr, g)
	var pa: float = (grind_last if held and ms.has("ing") else -2.2)
	var pp: Vector2 = mr.position + Vector2(64, 26) + Vector2(cos(pa), sin(pa) * 0.4) * 30.0
	ui.draw_set_transform(pp, 0.35 + cos(pa) * 0.25, Vector2(2, 2))
	ui.draw_texture(tex["st_pestle"], Vector2(-8, -40))
	ui.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# доска и нож
	var brd: Rect2 = ST["board"]
	ui.draw_texture_rect(tex["st_board"], brd, false)
	var bsd: Dictionary = station["board"]
	if bsd.has("ing"):
		var ing2: Dictionary = (bsd["ing"] as Dictionary).duplicate(true)
		if float(bsd["t"]) >= 1.0:
			(ing2["procs"] as Array).append("cut")
		_draw_ing(ing2, brd.position + Vector2(90, 44), 1.4)
		_progress(brd, float(bsd["t"]))
	var ky: float = -30.0 if knife_t <= 0.0 else -30.0 + (0.18 - knife_t) / 0.18 * 40.0
	var kr: Rect2 = Rect2(brd.position + Vector2(60, 30 + ky + (0.0 if bsd.has("ing") else 40.0)), Vector2(112, 32))
	ui.draw_texture_rect(tex["st_knife"], kr, false)
	# жаровня
	var zr: Rect2 = ST["brazier"]
	ui.draw_texture_rect(tex["st_brazier"], zr, false)
	var zs: Dictionary = station["brazier"]
	if zs.has("ing"):
		var ing3: Dictionary = (zs["ing"] as Dictionary).duplicate(true)
		var p3: String = _station_proc("brazier", zs)
		if p3 == "ash":
			ing3["procs"] = ["ash"]
		elif p3 != "":
			(ing3["procs"] as Array).append(p3)
		_draw_ing(ing3, zr.position + Vector2(72, 20 + sin(t * 3.0) * 2.0), 1.3)
		# дымок сильнее со временем
		var bt: float = float(zs["t"])
		for i in range(int(clampf(bt, 0.0, 8.0))):
			var sy: float = fmod(t * 40.0 + float(i) * 23.0, 90.0)
			ui.draw_rect(Rect2(zr.position + Vector2(60 + sin(t + i) * 14.0, -sy), Vector2(10, 10)), Color(0.75, 0.72, 0.7, 0.35 * (1.0 - sy / 90.0)))
	# миска
	var wr: Rect2 = ST["bowl"]
	ui.draw_texture_rect(tex["st_bowl"], wr, false)
	var ws: Dictionary = station["bowl"]
	if ws.has("ing"):
		var ing4: Dictionary = (ws["ing"] as Dictionary).duplicate(true)
		if float(ws["t"]) >= 3.0:
			(ing4["procs"] as Array).append("soak")
		_draw_ing(ing4, wr.position + Vector2(80, 10 + sin(t * 2.5) * 3.0), 1.1)
		_progress(wr, minf(1.0, float(ws["t"]) / 3.0))


## Готовность на инструменте — ряд пиксельных квадратиков под ним
func _progress(r: Rect2, v: float) -> void:
	var n: int = 8
	for i in range(n):
		var on: bool = float(i) / float(n) < v
		ui.draw_rect(Rect2(r.position.x + r.size.x / 2.0 - n * 7 + i * 14, r.end.y + 6, 10, 8), Color("f8d870") if on else Color(0.1, 0.06, 0.03, 0.55))


func _draw_bottle() -> void:
	var b: String = String(carry["base"])
	var tx: Texture2D = tex.get("pour_" + b, tex["icon_" + b])
	var sz: Vector2 = Vector2(tx.get_width(), tx.get_height()) * 2.0
	ui.draw_set_transform(mouse, deg_to_rad(tilt), Vector2.ONE)
	ui.draw_texture_rect(tx, Rect2(-sz / 2.0, sz), false)
	ui.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if stream_fx.emitting:
		var m0: Vector2 = _bottle_mouth()
		var col: Color = RDB.color(String((IT.BASE_ITEMS[b] as Array)[0]))
		var y1: float = LIQ_Y + 10.0
		for i in range(int((y1 - m0.y) / 6.0)):
			var yy: float = m0.y + float(i) * 6.0
			ui.draw_rect(Rect2(m0.x - 3 + sin(t * 20.0 + float(i)) * 1.5, yy, 6, 6), col.lightened(0.15 if i % 3 == 0 else 0.0))


## v29: что делает каждое свойство травы (подпись в подсказке котла)
const PROP_WORD: Dictionary = {
	"Свежесть": "бодрит, утоляет жажду", "Покой": "успокаивает", "Сон": "клонит в сон",
	"Тепло": "согревает", "Исцеление": "лечит", "Сила": "придаёт сил",
	"Жгучесть": "жжёт, острое", "Холод": "студит", "Огонь": "пылает",
	"Свет": "светится", "Тьма": "прячет в тени", "Чары": "волшебство",
}


func _draw_tip(id: String) -> void:
	var nm: String = _name(id)
	var m: Dictionary = RDB.herb_props(id)
	var w: float = maxf(220.0, font_bold.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x + 28.0)
	var keys: Array = []
	for k in RDB.PROPS:
		if int(m.get(k, 0)) > 0:
			keys.append(String(k))
	for k3 in keys:
		w = maxf(w, font_bold.get_string_size("%s — %s" % [k3, PROP_WORD.get(k3, "")], HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x + 28.0)
	var r: Rect2 = Rect2(mouse + Vector2(24, 10), Vector2(w, 52 + 40 + 24 * keys.size()))
	if r.end.x > 1900:
		r.position.x -= r.size.x + 48
	ui.draw_rect(r, Color(0.13, 0.08, 0.05, 0.92))
	ui.draw_rect(r, Color("c8a96e"), false, 2.0)
	ui.draw_string(font_bold, r.position + Vector2(14, 32), nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, PAPER)
	for i in range(keys.size()):
		var k2: String = keys[i]
		var p: Vector2 = r.position + Vector2(14 + i * 64, 46)
		ui.draw_texture_rect(tex["prop_" + k2], Rect2(p, Vector2(30, 30)), false)
		for d in range(int(m[k2])):
			ui.draw_rect(Rect2(p + Vector2(34, 22 - d * 9), Vector2(8, 7)), PROP_COL[k2])
		ui.draw_string(font_bold, r.position + Vector2(14, 104 + i * 24), "%s — %s" % [k2, PROP_WORD.get(k2, "")], HORIZONTAL_ALIGNMENT_LEFT, -1, 22, PROP_COL[k2].lightened(0.35))


func _draw_book_icon() -> void:
	var r: Rect2 = BOOK_R
	var hov: bool = r.has_point(mouse)
	ui.draw_texture_rect(tex["icon_potionbook"], Rect2(r.position + Vector2(16, 4 - (4 if hov else 0)), Vector2(80, 68)), false)
	var known: int = Game.known_recipes.size()
	_draw_count(r.position + Vector2(104, 92), known)


## Все зелья: открытые цветом, остальные — силуэтом. Наведи — что это и как варила.
func _draw_book() -> void:
	ui.draw_rect(Rect2(0, 0, 1920, 1080), Color(0, 0, 0, 0.6))
	var R: Rect2 = Rect2(160, 60, 1600, 960)
	ui.draw_rect(R, Color("e8d8b0"))
	ui.draw_rect(R, Color("5a2a1a"), false, 8.0)
	ui.draw_rect(Rect2(R.position.x + R.size.x / 2.0 - 3, R.position.y, 6, R.size.y), Color(0.55, 0.42, 0.28, 0.6))
	var ids: Array = []
	for id in RDB.PRODUCTS.keys():
		if String(id) != "murky":
			ids.append(String(id))
	var cols: int = 11
	var hover_id: String = ""
	for i in range(ids.size()):
		var id2: String = ids[i]
		var col: int = i % cols
		var row: int = i / cols
		var page_x: float = R.position.x + 40.0 if col < 6 else R.position.x + R.size.x / 2.0 + 30.0
		var cx: int = col if col < 6 else col - 6
		var p: Vector2 = Vector2(page_x + float(cx) * 120.0, R.position.y + 30.0 + float(row) * 78.0)
		var known: bool = Game.known_recipes.has(id2)
		var rr: int = RDB.rarity(id2)
		ui.draw_rect(Rect2(p, Vector2(76, 76)), Color(RDB.RARITY_COL[rr], 0.35 if known else 0.12))
		ui.draw_texture_rect(tex["p_" + id2], Rect2(p + Vector2(6, 6), Vector2(64, 64)), false, Color.WHITE if known else Color(0.12, 0.08, 0.06, 0.55))
		if Rect2(p, Vector2(76, 76)).has_point(mouse):
			hover_id = id2
	var shown: String = "Открыто %d из %d" % [Game.known_recipes.size(), ids.size()]
	ui.draw_string(font_title, R.position + Vector2(40, R.size.y - 18), shown, HORIZONTAL_ALIGNMENT_LEFT, -1, 44, INK)
	if hover_id != "":
		var d: Dictionary = RDB.PRODUCTS[hover_id]
		var known2: bool = Game.known_recipes.has(hover_id)
		var lines: Array = []
		lines.append([RDB.name(hover_id) if known2 else "???", 28, RDB.RARITY_COL[RDB.rarity(hover_id)]])
		lines.append([RDB.RARITY_NAME[RDB.rarity(hover_id)] + " · " + String(RDB.BASE_KIND[String(d["base"])]), 20, Color("c8b898")])
		if known2:
			lines.append([String(d["use"]), 20, PAPER])
			var kr: Dictionary = Game.known_recipes[hover_id] if Game.known_recipes[hover_id] is Dictionary else {}
			if not kr.is_empty():
				var parts: Array = []
				for ing in kr.get("ings", []):
					var nm: String = _name(String(ing["id"]))
					var pr: Array = ing.get("procs", [])
					for p2 in pr:
						nm += " (" + String(RDB.PROC_NAME.get(String(p2), "пепел")).to_lower() + ")"
					parts.append(nm)
				var bn: String = String(RDB.BASE_NAME[String(kr["base"])])
				if String(kr["base"]) == "water":
					bn = String(RDB.TEMP_NAME[String(kr["temp"])]).capitalize() + " вода"
				lines.append([bn + ": " + ", ".join(parts), 18, Color("e8d090")])
		var h: float = 24.0
		for l in lines:
			h += float(l[1]) * 1.5
		var w: float = 560.0
		var r: Rect2 = Rect2(mouse + Vector2(24, 24), Vector2(w, h))
		if r.end.x > 1900:
			r.position.x -= w + 48
		if r.end.y > 1060:
			r.position.y -= h + 48
		ui.draw_rect(r, Color(0.13, 0.08, 0.05, 0.95))
		ui.draw_rect(r, Color("c8a96e"), false, 2.0)
		var y: float = r.position.y + 12.0
		for l in lines:
			y += float(l[1]) * 1.2
			ui.draw_string(font_bold if int(l[1]) >= 28 else font_body, Vector2(r.position.x + 16, y), String(l[0]), HORIZONTAL_ALIGNMENT_LEFT, w - 32, 22, l[2])
			y += float(l[1]) * 0.3


func _draw_result() -> void:
	var k: float = clampf(result_t / 0.35, 0.0, 1.0)
	var r: Rect2 = Rect2(660, 170, 600, 440)
	ui.draw_rect(Rect2(0, 0, 1920, 1080), Color(0, 0, 0, 0.35 * k))
	var rr: int = RDB.rarity(result_id)
	var rc: Color = RDB.RARITY_COL[rr]
	# лучи за зельем у редких
	if rr >= 1 and result_id != "murky":
		for i in range(12 + rr * 6):
			var a: float = t * 0.3 + TAU * float(i) / float(12 + rr * 6)
			var c0: Vector2 = Vector2(960, 300)
			ui.draw_line(c0, c0 + Vector2(cos(a), sin(a)) * (220.0 + 40.0 * rr) * k, Color(rc, 0.25), 6.0)
	ui.draw_rect(r, Color(0.13, 0.08, 0.05, 0.94 * k))
	ui.draw_rect(r, Color(rc, k), false, 4.0)
	var ic: Texture2D = tex["p_" + result_id]
	var bob: float = sin(t * 2.0) * 6.0
	ui.draw_texture_rect(ic, Rect2(Vector2(960 - 80, 210 + bob), Vector2(160, 160) * k), false)
	var nm: String = RDB.name(result_id)
	var sz: Vector2 = font_title.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 56)
	ui.draw_string(font_title, Vector2(960 - sz.x / 2.0, 430), nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 44, Color(rc if result_id != "murky" else PAPER, k))
	var sub: String = RDB.RARITY_NAME[rr] if result_id != "murky" else ""
	if result_new:
		sub = "Новое зелье! · " + sub
	var sz2: Vector2 = font_body.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 24)
	ui.draw_string(font_body, Vector2(960 - sz2.x / 2.0, 470), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("e8d090", k))
	var use: String = String(RDB.PRODUCTS[result_id]["use"])
	ui.draw_multiline_string(font_body, Vector2(700, 515), use, HORIZONTAL_ALIGNMENT_CENTER, 520, 22, 3, Color(PAPER, k))

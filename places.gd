extends CanvasLayer
## Название места крупно на экране, когда героиня входит в новый край или город:
## у каждого места свой шрифт (системный, с кириллицей), цвет и короткая мелодия.

const WD = preload("res://world_data.gd")
const NPC = preload("res://npc_db.gd")

# место: [название, шрифты (первый найденный), цвет, жирный?, мелодия]
const PLACES: Dictionary = {
	"home": ["Дом травницы", ["Gabriola", "Georgia"], Color("fff2c8"), false, "jingle_home"],
	"meadow": ["Луга", ["Gabriola", "Georgia"], Color("e8f4c0"), false, "jingle_meadow"],
	"b10": ["Розовый лес единорогов", ["Segoe Script", "Gabriola"], Color("ffb8e0"), false, "jingle_unicorn"],
	"b11": ["Светящиеся гроты", ["Constantia", "Georgia"], Color("a8d8ff"), false, "jingle_grotto"],
	"b12": ["Берёзовая роща", ["Gabriola", "Georgia"], Color("f4f8e8"), false, "jingle_birch"],
	"b13": ["Хвойная тайга", ["Georgia", "Cambria"], Color("b8e0c0"), true, "jingle_taiga"],
	"b14": ["Осенний лес", ["Monotype Corsiva", "Georgia"], Color("ffb060"), false, "jingle_autumn"],
	"b15": ["Туманное болото", ["Ink Free", "Georgia"], Color("b8c890"), false, "jingle_swamp"],
	"b16": ["Цветочные поля", ["Segoe Print", "Georgia"], Color("ffe080"), false, "jingle_flowers"],
	"b17": ["Земли Восходящего Солнца", ["Yu Mincho", "MS Mincho", "Georgia"], Color("ff6a6a"), true, "jingle_japan"],
	"b18": ["Солнечное побережье", ["Segoe Script", "Georgia"], Color("ffe6a0"), false, "jingle_beach"],
	"b19": ["Открытое море", ["Constantia", "Georgia"], Color("6ac8ff"), false, "jingle_opensea"],
	"cats": ["", ["Segoe Print", "Comic Sans MS"], Color("ff9ac8"), true, "jingle_cats"],
	"spider": ["", ["Ink Free", "Georgia"], Color("c8a8ff"), false, "jingle_spider"],
	"gothic": ["", ["Monotype Corsiva", "Georgia"], Color("e0304a"), true, "jingle_gothic"],
	"knights": ["", ["Book Antiqua", "Palatino Linotype", "Georgia"], Color("f0c850"), true, "jingle_knights"],
	"elves": ["", ["Gabriola", "Georgia"], Color("8af0a0"), false, "jingle_elves"],
	"mages": ["", ["Constantia", "Georgia"], Color("a8c8ff"), false, "jingle_mages"],
	"orcs": ["", ["Impact", "Arial Black"], Color("e0783a"), false, "jingle_orcs"],
	"goblins": ["", ["Comic Sans MS", "Ink Free"], Color("a8d050"), true, "jingle_goblins"],
	"dwarves": ["", ["Bookman Old Style", "Georgia"], Color("f0a840"), true, "jingle_dwarves"],
	"japan": ["", ["Yu Mincho", "MS Mincho", "Georgia"], Color("ff5a5a"), true, "jingle_japan"],
	"ponies": ["", ["Segoe Script", "Comic Sans MS"], Color("e070d0"), true, "jingle_unicorn"],
	"club": ["Клуб «Старлит»", ["Impact", "Arial Black"], Color("ff5fa8"), false, "jingle_town_cats"],
	"under": ["Жемчужная Бухта", ["Segoe Script", "Georgia"], Color("7ae8ff"), false, "jingle_under"],
}
const LAND_BIOME: Dictionary = {2: "spider", 3: "gothic", 4: "knights", 5: "elves", 6: "mages", 7: "orcs", 8: "dwarves", 9: "cats"}

var main: Node2D
var title: Label
var sub: Label
var cur: String = ""
var check_t: float = 0.0
var tw: Tween
var fonts: Dictionary = {}
var orn: Control
var orn_col: Color = Color.WHITE
var orn_kind: String = "leaf"
var orn_w: float = 0.0


func setup(m: Node2D) -> void:
	main = m
	layer = 22
	title = Label.new()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size = Vector2(1920, 140)
	title.position = Vector2(0, 150)
	title.modulate.a = 0.0
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title)
	sub = Label.new()
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.size = Vector2(1920, 50)
	sub.position = Vector2(0, 290)
	sub.modulate.a = 0.0
	sub.add_theme_font_size_override("font_size", 30)
	sub.add_theme_color_override("font_outline_color", Color(0.1, 0.06, 0.08, 0.9))
	sub.add_theme_constant_override("outline_size", 8)
	add_child(sub)
	orn = Control.new()
	orn.size = Vector2(1920, 40)
	orn.position = Vector2(0, 262)
	orn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	orn.modulate.a = 0.0
	orn.draw.connect(_draw_orn)
	add_child(orn)
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("--place="):
			var key: String = String(a).substr(8)
			get_tree().create_timer(0.3).timeout.connect(func() -> void:
				cur = key
				show_place(key))


func _font(names: Array, bold: bool) -> Font:
	var key: String = ",".join(names) + str(bold)
	if not fonts.has(key):
		var f: SystemFont = SystemFont.new()
		f.font_names = PackedStringArray(names)
		f.font_weight = 700 if bold else 400
		f.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
		fonts[key] = f
	return fonts[key]


## Где сейчас героиня: город, край земли или дикий край
func place_at(p: Vector2) -> String:
	if bool(main.get("inside")):
		return cur
	if main.get("visiting") != null:
		return cur
	if p.x < -50000.0:
		return "club"
	if p.y > 90000.0:
		return "under"
	for land in WD.TOWN_C.keys():
		if p.distance_to(WD.TOWN_C[land]) < WD.TOWN_R:
			return "town:" + String(land)
	if p.distance_to(Game.home_pos + Vector2(0, 200)) < 560.0:
		return "home"
	if Rect2(0, 0, WD.RW, WD.RH).has_point(p):
		return "meadow" if Game.home_pos != Vector2(960, 358) else "home"
	var b: int = WD.biome_at(p)
	if LAND_BIOME.has(b):
		return "land:" + String(LAND_BIOME[b])
	if b == 1 or b == 0:
		return "meadow"
	return "b%d" % b


## Пиксельный узор под названием: линии расходятся от середины, в центре — знак места
func _draw_orn() -> void:
	var c: Vector2 = Vector2(960, 20)
	var col: Color = orn_col
	var dark: Color = Color(0.08, 0.05, 0.1, 0.85)
	var w: float = orn_w
	for sd in [-1.0, 1.0]:
		var s: float = sd
		orn.draw_rect(Rect2(c.x + (s * 34.0 if s > 0.0 else -34.0 - w), c.y - 2, w, 6), dark)
		orn.draw_rect(Rect2(c.x + (s * 34.0 if s > 0.0 else -34.0 - w), c.y - 1, w, 3), col)
		# бусинки на концах линий
		var ex: float = c.x + s * (34.0 + w + 8.0)
		orn.draw_rect(Rect2(ex - 5, c.y - 5, 10, 10), dark)
		orn.draw_rect(Rect2(ex - 3, c.y - 3, 6, 6), col)
		for k in range(3):
			var bx: float = c.x + s * (40.0 + w * (0.25 + k * 0.25))
			if absf(bx - c.x) < 34.0 + w:
				orn.draw_rect(Rect2(bx - 3, c.y - 6, 6, 3), col.darkened(0.2))
	# знак места в центре
	var P: float = 4.0
	var pat: Array = []
	match orn_kind:
		"sakura":
			pat = ["..#.#..", ".#####.", "##.#.##", ".##o##.", "##.#.##", ".#####.", "..#.#.."]
		"wave":
			pat = ["..###..", ".#...#.", "#..#..#", "..#.#..", ".#...#.", "#.....#", "......."]
		"star":
			pat = ["...#...", "...#...", ".#####.", "###o###", ".#####.", "...#...", "...#..."]
		"crown":
			pat = ["#..#..#", "##.#.##", "#######", "#o#o#o#", "#######", ".......", "......."]
		"moon":
			pat = ["..###..", ".##....", "##.....", "##.....", "##.....", ".##....", "..###.."]
		_:
			pat = ["...#...", "..###..", ".##o##.", "###o###", ".##o##.", "..###..", "...#..."]
	for y in range(pat.size()):
		var row: String = pat[y]
		for x in range(row.length()):
			var ch: String = row[x]
			if ch == ".":
				continue
			var r: Rect2 = Rect2(c.x - 3.5 * P + x * P, c.y - 3.5 * P + y * P, P, P)
			orn.draw_rect(r.grow(2.0), dark)
	for y2 in range(pat.size()):
		var row2: String = pat[y2]
		for x2 in range(row2.length()):
			var ch2: String = row2[x2]
			if ch2 == ".":
				continue
			orn.draw_rect(Rect2(c.x - 3.5 * P + x2 * P, c.y - 3.5 * P + y2 * P, P, P), col.lightened(0.45) if ch2 == "o" else col)


func _orn_kind(key: String) -> String:
	if "japan" in key or key == "b17":
		return "sakura"
	if key == "club":
		return "star"
	if key in ["b18", "b19", "under"]:
		return "wave"
	if "mages" in key or key == "b11":
		return "star"
	if key.begins_with("town:"):
		return "crown"
	if "gothic" in key or "spider" in key or key == "b15":
		return "moon"
	return "leaf"


func _set_orn_w(v: float) -> void:
	orn_w = v
	orn.queue_redraw()


func _process(delta: float) -> void:
	var pl: Node2D = main.get("player") as Node2D
	if pl == null:
		return
	check_t -= delta
	if check_t > 0.0:
		return
	check_t = 0.4
	var now: String = place_at(pl.global_position)
	if now == cur:
		return
	var first: bool = cur == ""
	cur = now
	if first:
		# место, где героиня начала игру (или загрузилась), уже знакомо
		Game.places_seen[now] = true
	else:
		show_place(now)


## v20: в новом месте — название и музыка; если уже бывала — только название (тише и короче), без музыки
func show_place(key: String) -> void:
	var fresh: bool = not Game.places_seen.has(key)
	Game.places_seen[key] = true
	var name: String = ""
	var subtitle: String = ""
	var spec: Array
	if key.begins_with("town:"):
		var land: String = key.substr(5)
		spec = PLACES.get(land, PLACES["meadow"])
		name = String(NPC.land(land).get("name", land))
		subtitle = "город · репутация: " + Game.rep_name(land)
		spec = spec.duplicate()
		spec[4] = "jingle_town_" + land
	elif key.begins_with("land:"):
		var land2: String = key.substr(5)
		spec = PLACES.get(land2, PLACES["meadow"])
		name = "Земли: " + String(NPC.land(land2).get("name", land2))
	else:
		spec = PLACES.get(key, PLACES["meadow"])
		name = String(spec[0])
	title.text = name
	title.add_theme_font_override("font", _font(spec[1], bool(spec[3])))
	title.add_theme_font_size_override("font_size", 92)
	title.add_theme_color_override("font_color", spec[2])
	title.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.1, 0.92))
	title.add_theme_constant_override("outline_size", 14)
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
	title.add_theme_constant_override("shadow_offset_y", 5)
	sub.text = subtitle
	sub.add_theme_font_override("font", _font(spec[1], false))
	sub.add_theme_color_override("font_color", (spec[2] as Color).lightened(0.3))
	if tw != null:
		tw.kill()
	orn_col = spec[2]
	orn_kind = _orn_kind(key)
	_set_orn_w(0.0)
	sub.position.y = 314.0
	tw = create_tween()
	title.position.y = 170.0
	tw.set_parallel(true)
	tw.tween_property(title, "modulate:a", 1.0, 0.8)
	tw.tween_property(title, "position:y", 150.0, 0.8).set_ease(Tween.EASE_OUT)
	tw.tween_property(sub, "modulate:a", 1.0, 1.0).set_delay(0.3)
	tw.tween_property(orn, "modulate:a", 1.0, 0.6).set_delay(0.2)
	tw.tween_method(_set_orn_w, 0.0, clampf(float(name.length()) * 17.0, 160.0, 520.0), 1.2).set_delay(0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.chain().tween_interval(2.6 if fresh else 1.6)
	tw.chain().set_parallel(true)
	tw.tween_property(title, "modulate:a", 0.0, 1.2)
	tw.tween_property(sub, "modulate:a", 0.0, 1.2)
	tw.tween_property(orn, "modulate:a", 0.0, 1.2)
	if fresh:
		Sound.place_theme(String(spec[4]))
	else:
		# знакомое место: без музыки, только тихий шелест страницы
		Sound.play("page", -16.0, 0.05)

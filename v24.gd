extends Node
## v24 (main/V24): деревья падают целиком и стволы носят вместе (trees24.gd), работницы работают по-настоящему
## и раскладывают добычу по сундукам (workers24.gd), сундуки разных размеров (chest_ui.gd + storage_db.gd),
## своё название королевства, в дома королевства можно заходить, диалоги с лицом и выбором.

const IT = preload("res://items_db.gd")
const SDB = preload("res://storage_db.gd")
const T = preload("res://talk24_db.gd")

var main: Node2D
var hud: CanvasLayer
var v23: Node
var trees: Node
var workers: Node
var ui: CanvasLayer
var ask_root: Control
var ask_edit: LineEdit
var ask_cb: Callable
var doors: Dictionary = {}          # "x,y" -> дверь дома королевства


func setup(m: Node2D, h: CanvasLayer) -> void:
	main = m
	hud = h
	add_to_group("v24")
	v23 = m.get_node("V23")
	ui = CanvasLayer.new()
	ui.layer = 31
	add_child(ui)
	_build_ask()
	trees = Node.new()
	trees.set_script(load("res://trees24.gd"))
	trees.name = "Trees24"
	add_child(trees)
	trees.call("setup", m, self)
	workers = Node.new()
	workers.set_script(load("res://workers24.gd"))
	workers.name = "Workers24"
	add_child(workers)
	workers.call("setup", m, self)
	# сундуки и дома, построенные до появления V24 (загрузка сохранения)
	var cu: Node = get_tree().get_first_node_in_group("chest_ui")
	var hs: Node = m.get("homestead")
	for pl in (hs.get("placed") as Array):
		var kind: String = String(pl[0])
		var p: Vector2 = pl[1]
		if SDB.is_chest(kind) and cu != null:
			cu.call("register", "%d,%d" % [int(p.x), int(p.y)], kind)
		on_built(kind, p)
	# работницы, которых kingdom23 уже создал
	var k: Node = get_tree().get_first_node_in_group("kingdom23")
	if k != null:
		for i in (k.get("nodes") as Dictionary).keys():
			var n: Node2D = (k.get("nodes") as Dictionary)[i]
			if is_instance_valid(n):
				workers.call("adopt", n, int(i))


# ------------------------------------------------------------------ диалог с лицом и выбором (как у предложения королевства)

func talk_menu(face: Texture2D, who: String, text: String, opts: Array) -> void:
	v23.call("talk", face, who, text, opts)


# ------------------------------------------------------------------ ввод текста (название королевства)

func _build_ask() -> void:
	ask_root = Control.new()
	ask_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	ask_root.visible = false
	ask_root.mouse_filter = Control.MOUSE_FILTER_STOP
	ui.add_child(ask_root)
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.5)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	ask_root.add_child(dim)
	var pn: Control = v23.call("_panel", ask_root, Rect2(560, 360, 800, 300))
	var ttl: Label = v23.call("_label", pn, "", "font_title", 36, Color("f0d89a"))
	ttl.name = "Title"
	ttl.position = Vector2(0, 26)
	ttl.size = Vector2(800, 50)
	ttl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ask_edit = LineEdit.new()
	ask_edit.position = Vector2(80, 110)
	ask_edit.size = Vector2(640, 56)
	ask_edit.max_length = 40
	ask_edit.add_theme_font_override("font", hud.get("font_body"))
	ask_edit.add_theme_font_size_override("font_size", 28)
	ask_edit.text_submitted.connect(func(_s: String) -> void: _ask_ok())
	pn.add_child(ask_edit)
	var bx: HBoxContainer = HBoxContainer.new()
	bx.position = Vector2(80, 200)
	bx.add_theme_constant_override("separation", 20)
	pn.add_child(bx)
	v23.call("_button", bx, "Готово", _ask_ok, 24)
	v23.call("_button", bx, "Отмена", func() -> void:
		ask_root.visible = false
		Game.ui_open = false, 24)


func ask_text(title: String, def: String, cb: Callable) -> void:
	(ask_root.find_child("Title", true, false) as Label).text = title
	ask_edit.text = def
	ask_cb = cb
	ask_root.visible = true
	Game.ui_open = true
	ask_edit.grab_focus()
	ask_edit.select_all()


func _ask_ok() -> void:
	var s: String = ask_edit.text.strip_edges()
	if s == "":
		return
	ask_root.visible = false
	Game.ui_open = false
	if ask_cb.is_valid():
		ask_cb.call(s)


# ------------------------------------------------------------------ дома королевства: можно зайти, там спят работницы

const DOOR_KIND: Dictionary = {
	"kg_house_a": "home", "kg_house_b": "home", "kg_house_c": "home", "kg_house_elf": "home", "kg_house_jp": "home",
	"kg_tavern": "tavern", "kg_teahouse": "tavern", "kg_brewery": "shop", "kg_bakery": "bakery", "kg_mine": "shop",
	"kg_palace": "palace",
}


func on_built(kind: String, p: Vector2) -> void:
	if not DOOR_KIND.has(kind):
		return
	var key: String = "%d,%d" % [int(p.x), int(p.y)]
	if doors.has(key) and is_instance_valid(doors[key]):
		return
	var d: Node2D = Node2D.new()
	d.set_script(load("res://house_door.gd"))
	d.position = p + Vector2(0, 6)
	d.set("kind", String(DOOR_KIND[kind]))
	d.set("private", false)
	d.set("land", "")
	d.set("open_from", 0.0)
	d.set("open_to", 24.0)
	d.set("seed_k", int(p.x) * 7 + int(p.y))
	d.set_meta("own24", kind)
	var who: Array = _resident(key)
	d.set("owner_tex", String(who[0]))
	d.set("owner_name", String(who[1]))
	(main.get("objects") as Node).add_child(d)
	doors[key] = d


## Кто живёт в доме: работница, которой этот дом достался (по порядку), иначе первая
func _resident(key: String) -> Array:
	var keys: Array = doors.keys()
	var idx: int = keys.find(key)
	if idx < 0:
		idx = keys.size()
	if Game.workers.is_empty():
		return ["catgirl_mira", "Мира"]
	var w: Dictionary = Game.workers[idx % Game.workers.size()]
	return [String(w["tex"]), String(w["name"])]


func has_house() -> bool:
	for k in doors.keys():
		if is_instance_valid(doors[k]) and String((doors[k] as Node).get("kind")) == "home":
			return true
	return false


## Куда идёт спать работница: в дом королевства (по кругу), иначе к дому героини
func bed_for(idx: int) -> Vector2:
	var homes: Array = []
	for k in doors.keys():
		if is_instance_valid(doors[k]) and String((doors[k] as Node).get("kind")) == "home":
			homes.append(doors[k])
	if homes.is_empty():
		return Game.home_pos + Vector2(float((idx * 37) % 200) - 100.0, 140.0 + float((idx * 23) % 60))
	return (homes[idx % homes.size()] as Node2D).global_position + Vector2(0, 4)


func refresh_residents() -> void:
	for k in doors.keys():
		if is_instance_valid(doors[k]):
			var who: Array = _resident(String(k))
			(doors[k] as Node).set("owner_tex", String(who[0]))
			(doors[k] as Node).set("owner_name", String(who[1]))

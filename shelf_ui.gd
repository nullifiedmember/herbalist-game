extends CanvasLayer
## Полка крупно: деревянные доски, на них вещи с ценниками. Клик по вещи — купить (если хватает монет).
## Наведение — табличка со свойствами. E / Esc — отойти от полки.

const IT = preload("res://items_db.gd")
const INK: Color = Color("3a2718")

var hud: CanvasLayer
var root: Control
var board: Control
var shelf: Node2D = null
var info: Label
var coins_l: Label
var open: bool = false


func setup(h: CanvasLayer) -> void:
	hud = h
	layer = 24
	add_to_group("shelf_ui")
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.visible = false
	add_child(root)
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0.05, 0.03, 0.02, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed:
			close())
	root.add_child(dim)
	var p: Control = Control.new()
	p.position = Vector2(520, 120)
	root.add_child(p)
	hud.call("panel", p, Vector2.ZERO, Vector2(880, 840))
	# крупная полка — та же картинка, что в лавке, в 6 раз больше
	var big: TextureRect = TextureRect.new()
	big.texture = load("res://art/shelf14.png") if ResourceLoader.exists("res://art/shelf14.png") else null
	big.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	big.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	big.stretch_mode = TextureRect.STRETCH_SCALE
	big.size = Vector2(84, 96) * 6.0
	big.position = Vector2((880 - big.size.x) / 2.0, 40)
	big.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(big)
	board = Control.new()
	board.position = big.position
	board.size = big.size
	p.add_child(board)
	info = Label.new()
	info.add_theme_font_override("font", hud.get("font_body"))
	info.add_theme_font_size_override("font_size", 24)
	info.add_theme_color_override("font_color", INK)
	info.position = Vector2(50, 640)
	info.size = Vector2(780, 140)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p.add_child(info)
	coins_l = Label.new()
	coins_l.add_theme_font_override("font", hud.get("font_bold"))
	coins_l.add_theme_font_size_override("font_size", 28)
	coins_l.add_theme_color_override("font_color", Color("8a6a20"))
	coins_l.position = Vector2(50, 780)
	coins_l.size = Vector2(780, 40)
	coins_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p.add_child(coins_l)


func open_shelf(s: Node2D) -> void:
	if Game.ui_open or Game.busy:
		return
	shelf = s
	open = true
	root.visible = true
	Game.ui_open = true
	Sound.play("page", -8.0)
	_fill()


func close() -> void:
	open = false
	root.visible = false
	Game.ui_open = false
	shelf = null


func _fill() -> void:
	for c in board.get_children():
		board.remove_child(c)
		c.queue_free()
	info.text = "Выбери, что взять с полки."
	coins_l.text = "У тебя %d монет" % Game.coins
	var spots: Array = preload("res://shop_shelf.gd").SPOTS
	var its: Array = shelf.call("items")
	for k in range(its.size()):
		var gi: int = int(its[k][0])
		var id: String = String(its[k][1])
		var sp: Vector2 = (spots[k] as Vector2) + Vector2(42, 96)   # от левого верхнего угла картинки полки
		var b: Button = Button.new()
		b.flat = true
		b.focus_mode = Control.FOCUS_NONE
		b.position = (sp + Vector2(-13, -25)) * 6.0
		b.size = Vector2(26, 34) * 6.0
		board.add_child(b)
		if bool(shelf.call("sold", gi)):
			continue
		var ic: TextureRect = TextureRect.new()
		ic.texture = IT.icon(id)
		ic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.position = Vector2(6, 6)
		ic.size = Vector2(144, 144)
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(ic)
		# ценник: бумажка с монеткой и ценой
		var pr: int = int(shelf.call("price", id))
		var tag: ColorRect = ColorRect.new()
		tag.color = Color("f4e8c8")
		tag.position = Vector2(30, 150)
		tag.size = Vector2(96, 40)
		tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(tag)
		var ci: TextureRect = TextureRect.new()
		ci.texture = load("res://art/coin.png")
		ci.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		ci.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ci.position = Vector2(6, 6)
		ci.size = Vector2(28, 28)
		ci.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tag.add_child(ci)
		var pl: Label = Label.new()
		pl.text = str(pr)
		pl.add_theme_font_override("font", hud.get("font_bold"))
		pl.add_theme_font_size_override("font_size", 26)
		pl.add_theme_color_override("font_color", INK if Game.coins >= pr else Color("b03a2a"))
		pl.position = Vector2(40, 2)
		pl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tag.add_child(pl)
		b.mouse_entered.connect(func() -> void:
			info.text = _describe(id)
			ic.modulate = Color(1.25, 1.2, 1.0))
		b.mouse_exited.connect(func() -> void: ic.modulate = Color.WHITE)
		b.pressed.connect(func() -> void:
			if bool(shelf.call("buy", gi, id)):
				get_tree().call_group("player", "react", "happy", 1.4)
				_fill()
				info.text = "Куплено: %s!" % IT.name(id)
			else:
				Sound.play("ui_click", -2.0)
				info.text = "Не хватает монет: нужно %d." % pr)


func _describe(id: String) -> String:
	var g: Dictionary = IT.gear(id)
	var s: String = IT.name(id)
	var st: Dictionary = g.get("stats", {})
	var bits: Array = []
	for k in st.keys():
		bits.append(_stat(String(k), float(st[k])))
	if g.has("rows"):
		bits.append("%d ряда сумки" % int(g["rows"]))
	if g.has("flasks"):
		bits.append("%d ячеек зелий" % int(g["flasks"]))
	if not bits.is_empty():
		s += " — " + ", ".join(PackedStringArray(bits))
	return s + ".\n" + String(g.get("desc", IT.DESC.get(id, "")))


func _stat(k: String, v: float) -> String:
	match k:
		"cap": return "+%d к весу" % int(v)
		"speed": return "+%d%% скорости" % int(v)
		"herb": return "%d%% две травы" % int(v)
		"shroom": return "%d%% два гриба" % int(v)
		"seed": return "%d%% семена" % int(v)
		"sell": return "+%d%% к продаже" % int(v)
		"brew": return "%d%% два зелья" % int(v)
		"hunger": return "голод медленнее на %d%%" % int(-v)
		"thirst": return "жажда медленнее на %d%%" % int(-v)
		"light": return "светит ночью"
		"shroom_w": return "грибы невесомы"
		"herb_w": return "травы вдвое легче"
		"fish_w": return "рыба втрое легче"
		"potion_w": return "зелья невесомы"
	return k


func _input(event: InputEvent) -> void:
	if not open:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var k: Key = (event as InputEventKey).physical_keycode
		if k == KEY_ESCAPE or KB.is_key("interact", k):
			close()
			get_viewport().set_input_as_handled()

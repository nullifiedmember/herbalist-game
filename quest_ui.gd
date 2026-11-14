extends CanvasLayer
## Журнал заданий (клавиша Q): что взято, как идёт, награда, где искать кошку.

const INK: Color = Color("3a2718")
var hud: CanvasLayer
var root: Control
var list: VBoxContainer
var open: bool = false
var qn: Node
var info: Label


func setup(h: CanvasLayer) -> void:
	hud = h
	layer = 36
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.visible = false
	add_child(root)
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0.10, 0.08, 0.14, 0.45)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var p: Control = Control.new()
	p.position = Vector2(360, 90)
	root.add_child(p)
	hud.call("panel", p, Vector2.ZERO, Vector2(1200, 900))
	var tl: Label = Label.new()
	tl.text = "Задания"
	tl.add_theme_font_override("font", hud.get("font_title"))
	tl.add_theme_font_size_override("font_size", 60)
	tl.add_theme_color_override("font_color", INK)
	tl.position = Vector2(40, 16)
	p.add_child(tl)
	info = Label.new()
	info.add_theme_font_override("font", hud.get("font_body"))
	info.add_theme_font_size_override("font_size", 24)
	info.add_theme_color_override("font_color", Color("7a5a3a"))
	info.position = Vector2(300, 44)
	p.add_child(info)
	var sc: ScrollContainer = ScrollContainer.new()
	sc.position = Vector2(40, 100)
	sc.size = Vector2(1120, 740)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	p.add_child(sc)
	list = VBoxContainer.new()
	list.custom_minimum_size = Vector2(1100, 0)
	list.add_theme_constant_override("separation", 14)
	sc.add_child(list)


func _ready() -> void:
	qn = get_tree().get_first_node_in_group("quests18")


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var k: int = (event as InputEventKey).physical_keycode
		if KB.is_key("quests", k) and (open or (not Game.ui_open and not Game.busy)):
			toggle()
			get_viewport().set_input_as_handled()
		elif k == KEY_ESCAPE and open:
			toggle()
			get_viewport().set_input_as_handled()


func toggle() -> void:
	if qn == null or not is_instance_valid(qn):
		qn = get_tree().get_first_node_in_group("quests18")
	open = not open
	root.visible = open
	Game.ui_open = open
	if open:
		Sound.play("page", -4.0)
		refresh()


func _label(text: String, size: int, col: Color, bold: bool) -> Label:
	var l: Label = Label.new()
	l.text = text
	l.add_theme_font_override("font", hud.get("font_bold") if bold else hud.get("font_body"))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(1080, 0)
	return l


func refresh() -> void:
	for c in list.get_children():
		list.remove_child(c)
		c.queue_free()
	if qn == null:
		return
	var act: Array = qn.get("active")
	info.text = "Выполнено: %d   ·   В работе: %d" % [int(qn.get("done_count")), act.size()]
	if act.is_empty():
		list.add_child(_label("Заданий пока нет. Поговори с жителями городов: у них бывают поручения.", 28, Color("6a5038"), false))
		return
	for q in act:
		var box: VBoxContainer = VBoxContainer.new()
		box.add_theme_constant_override("separation", 2)
		var ready: bool = bool(qn.call("can_turn_in", q))
		box.add_child(_label(("[готово] " if ready else "• ") + String(q["title"]), 32, Color("2f6a2a") if ready else INK, true))
		box.add_child(_label(String(q["text"]), 24, Color("5a4028"), false))
		box.add_child(_label("Дело: " + String(qn.call("progress_text", q)), 24, Color("6a5038"), false))
		box.add_child(_label("Награда: " + String(qn.call("reward_text", q)) + "   ·   Кому: " + String(q["giver"]), 24, Color("8a6a1a"), false))
		var b: Button = Button.new()
		b.text = "Отказаться"
		b.flat = true
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_override("font", hud.get("font_body"))
		b.add_theme_font_size_override("font_size", 22)
		b.add_theme_color_override("font_color", Color("9a5a4a"))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.pressed.connect(func() -> void:
			qn.call("abandon", q)
			refresh())
		box.add_child(b)
		list.add_child(box)

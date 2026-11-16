extends CanvasLayer
## Интерфейс: часы, подсказка действия, всплывающие сообщения, затемнение при сне.

const PX: float = 2.0
const RDB = preload("res://recipes_db.gd")
const U31 = preload("res://ui31.gd")
const INK: Color = Color("3a2718")
const INK_SOFT: Color = Color("6b4f36")

var font_title: Font
var font_body: Font
var font_bold: Font

var clock_root: Control
var sun_icon: TextureRect
var day_label: Label
var time_label: Label
var wind_label: Label
var prompt_root: Control
var prompt_panel: NinePatchRect
var prompt_label: Label
var prompt_key: TextureRect
var toasts: Array = []
var fade: ColorRect
var fade_label: Label
var arc: Control
var tex_sun: Texture2D
var tex_moon: Texture2D


func _ready() -> void:
	layer = 5
	# v31: пиксельный шрифт во всей игре (ui31.gd): заголовки и жирный — толще, размеры — чёткие (кратные 11)
	font_title = U31.title_font()
	font_body = U31.pixel_font(400)
	font_bold = U31.pixel_font(600)
	U31.install(get_tree())
	tex_sun = load("res://art/ui_sun.png")
	tex_moon = load("res://art/ui_moon.png")
	_build_clock()
	_build_hint()
	_build_order()
	_build_prompt()
	_build_say()
	_build_fade()
	Game.toast.connect(show_toast)


## Шкалы потребностей: 10 блоков, на пределе мигают красным
func _draw_needs(nb: Control) -> void:
	var levels: Array = [Game.thirst, Game.hunger, Game.fatigue, Game.pee, Game.poo, Game.shame]
	var cols: Array = [Color("5aa8e8"), Color("e09a48"), Color("8a78d0"), Color("e8c84a"), Color("8a5a34"), Color("e86a90")]
	if not Game.TOILET_ENABLED:
		levels = [Game.thirst, Game.hunger, Game.fatigue]
		cols = [cols[0], cols[1], cols[2]]
	for i in range(levels.size()):
		var lv: float = float(levels[i])
		var n: int = int(ceil(lv * 10.0))
		var warn: bool = i < 5 and lv > 0.8 and int(Time.get_ticks_msec() / 250) % 2 == 0
		# v31: шкала в стиле яблока — цветной контур, свет сверху, пустые клетки как вдавленный пергамент
		var c: Color = Color("e8605a") if warn else (cols[i] as Color)
		var y0: float = 14.0 + i * 44.0
		nb.draw_rect(Rect2(56, y0 - 4, 124, 28), Color("6e4636"))
		nb.draw_rect(Rect2(58, y0 - 2, 120, 24), Color("e2cba0"))
		nb.draw_rect(Rect2(58, y0 - 2, 120, 2), Color("c9ab7e"))
		for k in range(10):
			var r: Rect2 = Rect2(60 + k * 12, y0, 10, 20)
			if k < n:
				nb.draw_rect(r, c.darkened(0.42))
				nb.draw_rect(r.grow(-2), c)
				nb.draw_rect(Rect2(r.position + Vector2(2, 2), Vector2(6, 4)), c.lightened(0.35))
				nb.draw_rect(Rect2(r.position + Vector2(2, 16), Vector2(6, 2)), c.darkened(0.18))
			else:
				nb.draw_rect(Rect2(r.position + Vector2(0, 4), Vector2(10, 14)), Color("d6bc90"))


func panel(parent: Node, pos: Vector2, size: Vector2) -> NinePatchRect:
	var np: NinePatchRect = NinePatchRect.new()
	np.texture = load("res://art/ui_panel.png")
	np.patch_margin_left = 12
	np.patch_margin_top = 12
	np.patch_margin_right = 12
	np.patch_margin_bottom = 12
	np.position = pos
	np.size = size / PX
	np.scale = Vector2(PX, PX)
	np.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	np.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(np)
	return np


func label(parent: Node, text: String, font: Font, size: int, color: Color, pos: Vector2) -> Label:
	var l: Label = Label.new()
	l.text = text
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.position = pos
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l


func _build_clock() -> void:
	clock_root = Control.new()
	clock_root.position = Vector2(28, 24)
	clock_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(clock_root)
	panel(clock_root, Vector2.ZERO, Vector2(384, 150 if Game.WIND_ENABLED else 116))
	day_label = label(clock_root, "День 1", font_title, 52, INK, Vector2(26, 6))
	time_label = label(clock_root, "08:00", font_bold, 40, INK_SOFT, Vector2(30, 62))
	wind_label = label(clock_root, "Ветер: штиль", font_bold, 24, INK_SOFT, Vector2(30, 104))
	arc = Control.new()
	arc.position = Vector2(0, 0)
	arc.size = Vector2(384, 116)
	arc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clock_root.add_child(arc)
	arc.draw.connect(_draw_arc)
	sun_icon = TextureRect.new()
	sun_icon.texture = tex_sun
	sun_icon.size = Vector2(26, 26)
	sun_icon.scale = Vector2(1.6, 1.6)
	sun_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	clock_root.add_child(sun_icon)


func _build_hint() -> void:
	# v27: ряд значков меню с буквой клавиши (вместо одной плашки «Книга травника»)
	var items: Array = [
		["book", "icon_potionbook", "Книга травника"], ["craft", "icon_bottle", "Крафт"], ["build", "icon_log", "Мебель и комнаты"],
		["map", "icon_scroll", "Карта"], ["quests", "icon_book_lore", "Задания"], ["chronicle", "icon_book_recipe", "Летопись"],
		["skills", "icon_star_blade", "Навыки"],
	]
	if not Game.SOLO:
		items.append(["kingdom", "icon_crown23", "Королевство"])
	var cw: float = 74.0
	var root: Control = Control.new()
	root.position = Vector2(1920 - 24 - cw * items.size(), 20)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	for i in range(items.size()):
		var it: Array = items[i]
		var c: Control = Control.new()
		c.position = Vector2(i * cw, 0)
		c.size = Vector2(cw - 6, 72)
		c.tooltip_text = String(it[2])
		c.mouse_filter = Control.MOUSE_FILTER_STOP     # кнопка нажимается и не пропускает клик в мир
		c.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var act: String = String(it[0])
		c.gui_input.connect(func(ev: InputEvent) -> void:
			if ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed and (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
				_press_action(act)
				c.accept_event())
		root.add_child(c)
		panel(c, Vector2.ZERO, Vector2(cw - 6, 72))
		var ic: TextureRect = TextureRect.new()
		ic.texture = load("res://art/%s.png" % String(it[1]))
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		ic.position = Vector2(10, 6)
		ic.size = Vector2(48, 40)
		c.add_child(ic)
		var k: Label = label(c, "", font_bold, 22, INK, Vector2(0, 44))
		key_labels.append([k, String(it[0]), 22])
		k.size = Vector2(cw - 6, 26)
		k.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


## Нажатие значка мышью = нажатие клавиши этого действия (все окна открываются как с клавиатуры)
func _press_action(action: String) -> void:
	Sound.play("ui_click", -8.0)
	var kc: int = KB.code(action)
	for down in [true, false]:
		var ev: InputEventKey = InputEventKey.new()
		ev.physical_keycode = kc as Key
		ev.keycode = kc as Key
		ev.pressed = down
		Input.parse_input_event(ev)


var key_labels: Array = []          # v24: [Label, действие] — подпись меняется вместе с клавишей
var coin_label: Label
var rod_root: Control
var needs_root: Control
var order_root: Control
var order_text: Label
var order_who: Label
var say_root: Control
var say_name: Label
var say_text: Label
var say_tw: Tween


## Монеты и текущий заказ под часами
func _build_order() -> void:
	var croot: Control = Control.new()
	croot.position = Vector2(28, 184 if Game.WIND_ENABLED else 150)
	croot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(croot)
	panel(croot, Vector2.ZERO, Vector2(160, 60))
	var ci: TextureRect = TextureRect.new()
	ci.texture = load("res://art/coin.png")
	ci.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ci.position = Vector2(16, 10)
	ci.size = Vector2(20, 20)
	ci.scale = Vector2(2, 2)
	croot.add_child(ci)
	coin_label = label(croot, "0", font_bold, 40, INK, Vector2(64, 6))
	# потребности: два значка с шкалами из блоков, без подписей
	needs_root = Control.new()
	needs_root.position = Vector2(1920 - 28 - 190, 100)
	needs_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(needs_root)
	var icons: Array = ["res://art/need_thirst.png", "res://art/need_hunger.png", "res://art/need_sleep.png", "res://art/need_pee.png", "res://art/need_poo.png", "res://art/need_shame.png"]
	if not Game.TOILET_ENABLED:
		icons = icons.slice(0, 3)   # нужды в туалет выключены: только жажда и голод
	panel(needs_root, Vector2.ZERO, Vector2(190, 16 + icons.size() * 44))
	for i in range(icons.size()):
		var ni: TextureRect = TextureRect.new()
		ni.texture = load(String(icons[i]))
		ni.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		ni.position = Vector2(14, 10 + i * 44)
		ni.size = Vector2(12, 12)
		ni.scale = Vector2(3, 3)
		needs_root.add_child(ni)
	var nb: Control = Control.new()
	nb.size = Vector2(190, 236)
	nb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	nb.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	nb.draw.connect(_draw_needs.bind(nb))
	needs_root.add_child(nb)
	# удочка из шкафа: просто картинка, без подписи
	rod_root = Control.new()
	rod_root.position = Vector2(28 + 176, 184 if Game.WIND_ENABLED else 150)
	rod_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rod_root.visible = false
	add_child(rod_root)
	panel(rod_root, Vector2.ZERO, Vector2(72, 60))
	var ri: TextureRect = TextureRect.new()
	ri.texture = load("res://art/rod_icon.png")
	ri.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ri.position = Vector2(12, 6)
	ri.size = Vector2(16, 16)
	ri.scale = Vector2(3, 3)
	rod_root.add_child(ri)
	order_root = Control.new()
	order_root.position = Vector2(28, 254 if Game.WIND_ENABLED else 220)
	order_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	order_root.visible = false
	add_child(order_root)
	panel(order_root, Vector2.ZERO, Vector2(384, 150))
	order_who = label(order_root, "", font_bold, 22, INK, Vector2(22, 12))
	order_text = label(order_root, "", font_body, 20, INK_SOFT, Vector2(22, 46))
	order_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	order_text.size = Vector2(340, 96)


## Реплика жителя внизу экрана
func _build_say() -> void:
	say_root = Control.new()
	say_root.position = Vector2(460, 790)
	say_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	say_root.visible = false
	add_child(say_root)
	panel(say_root, Vector2.ZERO, Vector2(1000, 150))
	say_name = label(say_root, "", font_title, 40, INK, Vector2(32, 6))
	say_text = label(say_root, "", font_body, 28, INK, Vector2(32, 62))
	say_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	say_text.size = Vector2(940, 80)


func say(who: String, text: String) -> void:
	say_name.text = who
	say_text.text = text
	say_root.visible = true
	say_root.modulate.a = 0.0
	if say_tw != null and say_tw.is_valid():
		say_tw.kill()
	say_tw = create_tween()
	say_tw.tween_property(say_root, "modulate:a", 1.0, 0.2)
	say_tw.tween_interval(4.5)
	say_tw.tween_property(say_root, "modulate:a", 0.0, 0.5)
	say_tw.tween_callback(func() -> void: say_root.visible = false)


func _build_prompt() -> void:
	prompt_root = Control.new()
	prompt_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prompt_root.visible = false
	add_child(prompt_root)
	prompt_panel = panel(prompt_root, Vector2.ZERO, Vector2(300, 76))
	prompt_key = TextureRect.new()
	prompt_key.texture = load("res://art/ui_key.png")
	prompt_key.position = Vector2(18, 12)
	prompt_key.size = Vector2(22, 22)
	prompt_key.scale = Vector2(2.3, 2.3)
	prompt_key.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	prompt_root.add_child(prompt_key)
	var e: Label = label(prompt_root, "E", font_bold, 26, INK, Vector2(18, 15))
	key_labels.append([e, "interact", 26])
	e.size = Vector2(50, 34)
	e.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label = label(prompt_root, "", font_body, 22, INK, Vector2(86, 22))


func _build_fade() -> void:
	fade = ColorRect.new()
	fade.color = Color(0.05, 0.04, 0.08, 0.0)
	fade.size = Vector2(1920, 1080)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fade)
	fade_label = label(self, "", font_title, 110, Color("f4e8c8"), Vector2(0, 440))
	fade_label.size = Vector2(1920, 160)
	fade_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fade_label.modulate.a = 0.0


const TOAST_MAX: float = 1000.0      # v31: левая кромка ≥ 888 — правее панели быстрого доступа
const TOAST_BOTTOM: float = 1080.0 - 112.0
const ARC_C: Vector2 = Vector2(290, 92)
const ARC_R: float = 64.0


func _arc_point(t: float) -> Vector2:
	var a: float = PI + t * PI
	return ARC_C + Vector2(cos(a), sin(a) * 0.95) * ARC_R


func _draw_arc() -> void:
	var col: Color = Color(INK_SOFT, 0.55)
	for i in range(19):
		var t: float = i / 18.0
		arc.draw_circle(_arc_point(t), 2.0 if i % 3 == 0 else 1.3, col)
	arc.draw_line(ARC_C + Vector2(-ARC_R - 10, 0), ARC_C + Vector2(ARC_R + 10, 0), Color(INK_SOFT, 0.7), 2.0)
	# мягкое свечение заката на горизонте
	var g: float = Game.golden()
	if g > 0.05:
		var side: float = -1.0 if Game.sun_t() > 0.5 else 1.0
		arc.draw_circle(ARC_C + Vector2(side * ARC_R, -2), 10.0 * g, Color(1.0, 0.6, 0.35, 0.35 * g))


func _process(_delta: float) -> void:
	for kl in key_labels:
		var kt: String = KB.key_name(String(kl[1]))
		if (kl[0] as Label).text != kt:
			(kl[0] as Label).text = kt
			(kl[0] as Label).add_theme_font_size_override("font_size", int(kl[2]) if kt.length() <= 2 else int(int(kl[2]) * 0.6))
	day_label.text = "День %d" % Game.day
	time_label.text = Game.clock_text()
	wind_label.visible = Game.WIND_ENABLED
	if Game.WIND_ENABLED:
		wind_label.text = "Ветер: " + Game.wind_text()
	var night: bool = Game.night_factor() > 0.5
	sun_icon.texture = tex_moon if night else tex_sun
	var t: float
	var h: float = Game.hour()
	if night:
		var hn: float = h + 24.0 if h < 6.0 else h
		t = clampf((hn - 20.0) / 10.0, 0.0, 1.0)
	else:
		t = 1.0 - Game.sun_t()
	sun_icon.position = _arc_point(t) - Vector2(13, 13) * 1.6
	arc.queue_redraw()
	coin_label.text = str(Game.coins)
	rod_root.visible = Game.rod_ok()
	needs_root.get_child(needs_root.get_child_count() - 1).queue_redraw()
	var has_order: bool = not Game.order.is_empty()
	order_root.visible = has_order and not Game.ui_open
	if has_order:
		order_who.text = "Заказ: " + String(Game.order.get("name", ""))
		if bool(Game.order.get("met", false)):
			order_text.text = "«" + String(RDB.ASKS.get(String(Game.order.get("product", "")), "")) + "»"
		else:
			order_text.text = "Ждёт у тропинки. Подойди и поговори."


func set_prompt(text: String) -> void:
	if text == "":
		prompt_root.visible = false
		return
	prompt_label.text = text
	var w: float = font_body.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x + 116.0
	w = ceilf(w / 2.0) * 2.0
	prompt_panel.size = Vector2(w, 76) / PX
	prompt_root.position = Vector2(roundf((1920.0 - w) / 2.0), 960)
	prompt_root.visible = true


func show_toast(text: String, icon: Texture2D) -> void:
	var root: Control = Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	# v31: ширина не больше TOAST_MAX — длинный текст переносится, плашка растёт вниз
	var pad: float = 110.0 if icon else 50.0
	var tw_full: float = font_bold.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
	var w: float = minf(tw_full + pad, TOAST_MAX)
	w = ceilf(w / 2.0) * 2.0
	var lines: int = int(ceilf(tw_full / maxf(w - pad, 1.0) * 1.12)) if tw_full + pad > TOAST_MAX else 1
	var h: float = 72.0 + float(maxi(lines, 1) - 1) * 24.0
	root.set_meta("w", w)
	root.set_meta("h", h)
	panel(root, Vector2.ZERO, Vector2(w, h))
	var x: float = 24.0
	if icon:
		var tr: TextureRect = TextureRect.new()
		tr.texture = icon
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.position = Vector2(14, (h - 60.0) / 2.0)
		tr.size = Vector2(60, 60)
		root.add_child(tr)
		x = 84.0
	var tl: Label = label(root, text, font_bold, 22, INK, Vector2(x, 24 if lines <= 1 else 14))
	if lines > 1:
		tl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		tl.custom_minimum_size = Vector2(w - x - 24.0, 0.0)
		tl.size = Vector2(w - x - 24.0, h - 24.0)
	toasts.push_front(root)
	_layout_toasts()
	root.modulate.a = 0.0
	var tw: Tween = create_tween()
	tw.tween_property(root, "modulate:a", 1.0, 0.2)
	tw.tween_interval(2.2)
	tw.tween_property(root, "modulate:a", 0.0, 0.5)
	tw.tween_callback(func() -> void:
		toasts.erase(root)
		root.queue_free())


func _layout_toasts() -> void:
	# v31: стопка справа над нижней кромкой — не налезает на панель быстрого доступа и полоску семян
	var y: float = TOAST_BOTTOM
	for i in range(toasts.size()):
		var r: Control = toasts[i]
		var w: float = float(r.get_meta("w", 300.0))
		var h: float = float(r.get_meta("h", 72.0))
		y -= h
		r.position = Vector2(1920.0 - 32.0 - w, y)
		y -= 12.0
		r.visible = i <= 4 and y > 300.0


func fade_out(text: String) -> Tween:
	fade_label.text = text
	var tw: Tween = create_tween()
	tw.tween_property(fade, "color:a", 1.0, 0.9)
	tw.parallel().tween_property(fade_label, "modulate:a", 1.0, 0.9)
	return tw


func fade_in() -> Tween:
	var tw: Tween = create_tween()
	tw.tween_interval(0.6)
	tw.tween_property(fade_label, "modulate:a", 0.0, 0.5)
	tw.tween_property(fade, "color:a", 0.0, 0.9)
	return tw

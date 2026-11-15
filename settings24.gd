extends Control
## v24: полноценные настройки, как в настоящей игре. Вкладки: Звук, Экран, Игра, Управление.
## Всё сохраняется в user://settings.cfg (Saves.save_settings) и общее для всех сохранений.
## Управление: нажать на клавишу действия -> нажать новую клавишу (Esc — отмена).
## Если клавиша занята другим действием — они меняются местами.

const INK: Color = Color("3a2718")
const INK2: Color = Color("7a5a3a")
const W: float = 1240.0
const H: float = 820.0
const TABS: Array = [["sound", "Звук"], ["video", "Экран"], ["game", "Игра"], ["keys", "Управление"]]

var hud: CanvasLayer
var on_close: Callable
var tab: String = "sound"
var tab_btns: Dictionary = {}
var body: VBoxContainer
var scroll: ScrollContainer
var waiting: String = ""              # действие, которому ждём новую клавишу
var key_btns: Dictionary = {}         # действие -> Button


func setup(h: CanvasLayer, close_cb: Callable) -> void:
	hud = h
	on_close = close_cb
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	var p: Control = Control.new()
	p.position = Vector2((1920.0 - W) / 2.0, (1080.0 - H) / 2.0)
	add_child(p)
	hud.call("panel", p, Vector2.ZERO, Vector2(W, H))
	var tl: Label = _lbl(p, "Настройки", hud.get("font_title"), 64, INK)
	tl.position = Vector2(0, 22)
	tl.size = Vector2(W, 80)
	tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var tabs: HBoxContainer = HBoxContainer.new()
	tabs.position = Vector2(70, 110)
	tabs.size = Vector2(W - 140, 60)
	tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	tabs.add_theme_constant_override("separation", 40)
	p.add_child(tabs)
	for td in TABS:
		var tid: String = String(td[0])
		var b: Button = _btn(tabs, String(td[1]), 40, func() -> void: _open_tab(tid))
		tab_btns[tid] = b
	var line: ColorRect = ColorRect.new()
	line.color = Color(INK2, 0.5)
	line.position = Vector2(70, 176)
	line.size = Vector2(W - 140, 3)
	p.add_child(line)
	scroll = ScrollContainer.new()
	scroll.position = Vector2(90, 195)
	scroll.size = Vector2(W - 180, H - 320)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	p.add_child(scroll)
	body = VBoxContainer.new()
	body.custom_minimum_size = Vector2(W - 200, 0)
	body.add_theme_constant_override("separation", 14)
	scroll.add_child(body)
	var bottom: HBoxContainer = HBoxContainer.new()
	bottom.position = Vector2(70, H - 110)
	bottom.size = Vector2(W - 140, 70)
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.add_theme_constant_override("separation", 80)
	p.add_child(bottom)
	_btn(bottom, "Сбросить вкладку", 40, _reset_tab)
	_btn(bottom, "Готово", 44, close)


func open() -> void:
	visible = true
	waiting = ""
	_open_tab(tab)


func close() -> void:
	waiting = ""
	visible = false
	Saves.save_settings()
	if on_close.is_valid():
		on_close.call()


func _input(event: InputEvent) -> void:
	if not visible or not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var k: int = int((event as InputEventKey).physical_keycode)
	if waiting != "":
		if k != KEY_ESCAPE:
			KB.assign(waiting, k)
			Sound.play("ui_select")
		waiting = ""
		_fill()
		get_viewport().set_input_as_handled()
	elif k == KEY_ESCAPE:
		close()
		get_viewport().set_input_as_handled()


# ------------------------------------------------------------------ вкладки

func _open_tab(tid: String) -> void:
	tab = tid
	waiting = ""
	for t in tab_btns:
		var b: Button = tab_btns[t]
		b.add_theme_color_override("font_color", INK if t == tab else Color(INK2, 0.75))
		b.text = (("· " + _tab_name(t) + " ·") if t == tab else _tab_name(t))
	_fill()
	scroll.scroll_vertical = 0


func _tab_name(tid: String) -> String:
	for td in TABS:
		if String(td[0]) == tid:
			return String(td[1])
	return tid


func _fill() -> void:
	for c in body.get_children():
		body.remove_child(c)
		c.queue_free()
	key_btns.clear()
	match tab:
		"sound":
			_slider_row("Общая громкость", float(Saves.opt["master"]), func(v: float) -> void:
				Saves.opt["master"] = v
				Saves.apply_settings())
			_slider_row("Музыка", Sound.music_vol, func(v: float) -> void:
				Sound.music_vol = v
				Sound.apply_volume())
			_slider_row("Звуки", Sound.sfx_vol, func(v: float) -> void:
				Sound.sfx_vol = v
				Sound.apply_volume()
				Sound.play("ui_click"))
			_toggle_row("Без звука, когда окно свёрнуто", "mute_unfocus")
		"video":
			_toggle_row("Полный экран", "fullscreen")
			_choice_row("Разрешение окна", "res", [[0, "авто"], [1280, "1280x720"], [1366, "1366x768"], [1600, "1600x900"],
					[1920, "1920x1080"], [2048, "2048x1152"], [2560, "2560x1440"]])
			_toggle_row("Вертикальная синхронизация", "vsync")
			_choice_row("Ограничение кадров", "fps", [[0, "нет"], [30, "30"], [60, "60"], [120, "120"], [144, "144"]])
			_choice_row("Размер интерфейса", "ui_scale", [[0.85, "мелкий"], [1.0, "обычный"], [1.15, "крупный"]])
			_slider_row("Яркость", (float(Saves.opt["brightness"]) - 0.6) / 0.8, func(v: float) -> void:
				Saves.opt["brightness"] = 0.6 + v * 0.8
				Saves.apply_settings())
		"game":
			_choice_row("Бег", "run_toggle", [[false, "держать клавишу"], [true, "нажать один раз"]])
			_choice_row("Автосохранение", "autosave", [[0, "выкл"], [1, "1 мин"], [3, "3 мин"], [5, "5 мин"], [10, "10 мин"]])
			_toggle_row("Пауза, когда окно свёрнуто", "pause_unfocus")
		"keys":
			var hint: Label = _lbl(body, "Нажмите на клавишу, потом новую. Esc — отмена.", hud.get("font_body"), 26, INK2)
			hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			for a in KB.ACTIONS:
				_key_row(String(a[0]), String(a[1]))
			var fixed: Label = _lbl(body, "Всегда: Esc — меню, 1–8 — пояс, колесо мыши — пояс, ЛКМ — удар/взять, ПКМ — использовать.",
					hud.get("font_body"), 24, Color(INK2, 0.8))
			fixed.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			fixed.custom_minimum_size = Vector2(W - 220, 0)


func _reset_tab() -> void:
	var d: Dictionary = Saves.defaults_opt()
	match tab:
		"sound":
			Saves.opt["master"] = d["master"]
			Saves.opt["mute_unfocus"] = d["mute_unfocus"]
			Sound.music_vol = 0.7
			Sound.sfx_vol = 0.8
		"video":
			for k in ["fullscreen", "res", "vsync", "fps", "ui_scale", "brightness"]:
				Saves.opt[k] = d[k]
		"game":
			for k2 in ["run_toggle", "autosave", "pause_unfocus"]:
				Saves.opt[k2] = d[k2]
		"keys":
			KB.reset_all()
	Saves.apply_settings()
	Sound.play("ui_select")
	_fill()


# ------------------------------------------------------------------ строки

func _row(text: String) -> HBoxContainer:
	var hb: HBoxContainer = HBoxContainer.new()
	hb.custom_minimum_size = Vector2(W - 220, 52)
	body.add_child(hb)
	var l: Label = _lbl(hb, text, hud.get("font_body"), 32, INK)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return hb


func _slider_row(text: String, val: float, cb: Callable) -> void:
	var hb: HBoxContainer = _row(text)
	var s: HSlider = HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = clampf(val, 0.0, 1.0)
	s.custom_minimum_size = Vector2(420, 40)
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	s.focus_mode = Control.FOCUS_NONE
	s.value_changed.connect(cb)
	hb.add_child(s)


func _toggle_row(text: String, key: String) -> void:
	_choice_row(text, key, [[false, "выкл"], [true, "вкл"]])


## Выбор из нескольких значений: стрелки ‹ значение ›, клик по значению — следующее
func _choice_row(text: String, key: String, vals: Array) -> void:
	var hb: HBoxContainer = _row(text)
	var cur: int = 0
	for i in vals.size():
		if _same(vals[i][0], Saves.opt.get(key)):
			cur = i
	var box: HBoxContainer = HBoxContainer.new()
	box.custom_minimum_size = Vector2(420, 0)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_child(box)
	var shown: Array = [cur, null]        # [индекс, кнопка] — массив, чтобы лямбды видели изменения
	var step: Callable = func(d: int) -> void:
		shown[0] = posmod(int(shown[0]) + d, vals.size())
		Saves.opt[key] = vals[int(shown[0])][0]
		(shown[1] as Button).text = String(vals[int(shown[0])][1])
		Saves.apply_settings()
	_btn(box, "‹", 36, func() -> void: step.call(-1))
	var val_btn: Button = _btn(box, String(vals[cur][1]), 34, func() -> void: step.call(1))
	shown[1] = val_btn
	val_btn.custom_minimum_size = Vector2(300, 0)
	val_btn.add_theme_color_override("font_color", INK)
	_btn(box, "›", 36, func() -> void: step.call(1))


func _same(a: Variant, b: Variant) -> bool:
	if typeof(a) == TYPE_BOOL or typeof(b) == TYPE_BOOL:
		return (a == true) == (b == true)
	return absf(float(a) - float(b)) < 0.001


func _key_row(action: String, text: String) -> void:
	var hb: HBoxContainer = _row(text)
	var b: Button = _btn(hb, "", 32, func() -> void:
		waiting = action
		_refresh_keys())
	b.custom_minimum_size = Vector2(300, 0)
	b.add_theme_color_override("font_color", INK)
	key_btns[action] = b
	_refresh_keys()


func _refresh_keys() -> void:
	for a in key_btns:
		var b: Button = key_btns[a]
		if a == waiting:
			b.text = "[ … ]"
		else:
			var alt: int = KB.alt_of(a)
			var t: String = "[ " + KB.key_name(a) + " ]"
			if alt != KEY_NONE and not Game.keybinds.has(a) and not Game.keybinds.values().has(alt):
				t += "  или  " + OS.get_keycode_string(alt as Key)
			b.text = t


# ------------------------------------------------------------------ мелочи

func _lbl(parent: Control, text: String, font: Font, size: int, col: Color) -> Label:
	var l: Label = Label.new()
	l.text = text
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l


func _btn(parent: Control, text: String, size: int, cb: Callable) -> Button:
	var b: Button = Button.new()
	b.text = text
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_override("font", hud.get("font_title"))
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_color_override("font_color", INK2)
	b.add_theme_color_override("font_hover_color", INK)
	b.add_theme_color_override("font_pressed_color", INK)
	b.mouse_entered.connect(func() -> void: Sound.play("ui_click", -8.0))
	b.pressed.connect(func() -> void:
		Sound.play("ui_click")
		cb.call())
	parent.add_child(b)
	return b

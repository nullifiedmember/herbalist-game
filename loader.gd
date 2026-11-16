extends CanvasLayer
## v37: экран загрузки. Вечерний фон как в меню (menu32_*), кипящий котёл (art/load37_pot.png, 8 кадров,
## рисует tools/loading37.py), «Загрузка…» и случайный совет.
## Вместо get_tree().reload_current_scene() звать Loader.reload() — экран закроет подвисание.

const U31 = preload("res://ui31.gd")
const TIPS = preload("res://tips_db.gd")
const INK: Color = Color(1.0, 0.95, 0.84)
const MIN_SHOW: float = 1.1

var root: Control
var pot: Sprite2D
var label: Label
var tip: Label
var clouds: Array = []
var t: float = 0.0
var shown_at: float = 0.0
var busy: bool = false


func _ready() -> void:
	layer = 120
	process_mode = Node.PROCESS_MODE_ALWAYS
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.visible = false
	add_child(root)
	var fill: ColorRect = ColorRect.new()
	fill.color = Color(0.09, 0.15, 0.11)
	fill.size = Vector2(1920, 1080)
	root.add_child(fill)
	_tex("menu32_sky_dusk")
	for i in 4:
		var c: TextureRect = _tex("menu32_cloud_%d" % i, Vector2(-200.0 + i * 560.0, 40.0 + float(i % 2) * 70.0))
		clouds.append([c, 9.0 + float(i) * 3.0])
	for nm in ["menu32_far", "menu32_mid", "menu32_near", "menu32_front", "menu32_windows"]:
		_tex(nm)
	# тёмная полоса снизу (плавный край) — чтобы буквы читались
	for i in 12:
		var band: ColorRect = ColorRect.new()
		band.color = Color(0.16, 0.10, 0.2, 0.05 + 0.05 * float(i))
		band.position = Vector2(0, 760.0 + float(i) * 12.0)
		band.size = Vector2(1920, 12)
		root.add_child(band)
	var base: ColorRect = ColorRect.new()
	base.color = Color(0.16, 0.10, 0.2, 0.62)
	base.position = Vector2(0, 904)
	base.size = Vector2(1920, 176)
	root.add_child(base)
	var title: Label = _label("Лесной травник", 86, Vector2(0, 40))
	title.size = Vector2(960, 80)
	title.scale = Vector2(2, 2)
	title.add_theme_color_override("font_outline_color", Color(0.36, 0.22, 0.42))
	title.add_theme_constant_override("outline_size", 14)
	pot = Sprite2D.new()
	pot.texture = load("res://art/load37_pot.png")
	pot.hframes = 8
	pot.scale = Vector2(3, 3)
	pot.position = Vector2(960, 790)
	root.add_child(pot)
	label = _label("Загрузка", 52, Vector2(0, 900))
	label.size = Vector2(1280, 60)
	label.scale = Vector2(1.5, 1.5)
	tip = _label("", 30, Vector2(260, 985))
	tip.add_theme_constant_override("line_spacing", -18)
	tip.size.x = 1400
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tip.add_theme_color_override("font_color", Color(0.95, 0.9, 1.0, 0.9))
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("--loadshot="):
			open.call_deferred()


func _tex(nm: String, pos: Vector2 = Vector2(-40, -20)) -> TextureRect:
	var r: TextureRect = TextureRect.new()
	r.texture = load("res://art/%s.png" % nm)
	r.position = pos
	r.scale = Vector2(2, 2)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(r)
	return r


func _label(text: String, fs: int, pos: Vector2) -> Label:
	var l: Label = Label.new()
	l.text = text
	l.add_theme_font_override("font", U31.title_font())
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", INK)
	l.add_theme_color_override("font_outline_color", Color(0.24, 0.15, 0.3))
	l.add_theme_constant_override("outline_size", 8)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.position = pos
	l.size = Vector2(1920, 80)
	root.add_child(l)
	return l


func open() -> void:
	var h: Array = TIPS.HAND
	if not h.is_empty():
		tip.text = "Совет: " + String((h[randi() % h.size()] as Array)[2])
	root.modulate.a = 1.0
	root.visible = true
	shown_at = t


func close() -> void:
	var wait: float = MIN_SHOW - (t - shown_at)
	if wait > 0.0:
		await get_tree().create_timer(wait, true, false, true).timeout
	var tw: Tween = create_tween()
	tw.tween_property(root, "modulate:a", 0.0, 0.45)
	await tw.finished
	root.visible = false


## Перезагрузить сцену под экраном загрузки
func reload() -> void:
	if busy:
		return
	busy = true
	open()
	await get_tree().process_frame
	await get_tree().process_frame       # кадр с экраном успел нарисоваться
	get_tree().reload_current_scene()
	for i in 4:
		await get_tree().process_frame   # новая сцена построилась
	busy = false
	await close()


func _process(delta: float) -> void:
	t += delta
	if not root.visible:
		return
	pot.frame = int(t * 9.0) % 8
	label.text = "Загрузка" + ".".repeat(int(t * 2.5) % 4)
	for c in clouds:
		var r: TextureRect = c[0]
		r.position.x += float(c[1]) * delta
		if r.position.x > 1960.0:
			r.position.x = -500.0
	# --loadshot=путь.png — снимок экрана загрузки (проверка)
	for a in OS.get_cmdline_user_args():
		var s: String = String(a)
		if s.begins_with("--loadshot=") and t - shown_at > 0.6 and not has_meta("shot"):
			set_meta("shot", true)
			get_viewport().get_texture().get_image().save_png(s.substr(11))
			get_tree().quit()

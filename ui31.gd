extends RefCounted
## v31: общие детали интерфейса в стиле яблока (картинки рисует tools/ui31.py).
## Подключение: const U31 = preload("res://ui31.gd"), дальше U31.np(...), U31.style_button(...).

const INK: Color = Color("3a2718")        # основной текст на пергаменте
const INK_SOFT: Color = Color("6b4f36")   # второстепенный текст
const INK_GOLD: Color = Color("a0601e")   # выделенное (активный набор, заголовок)
const INK_MAGIC: Color = Color("3a62a8")  # свойства вещей
const INK_BAD: Color = Color("c0392b")


static func tex(name: String) -> Texture2D:
	var p: String = "res://art/%s.png" % name
	return load(p) if ResourceLoader.exists(p) else null


## Девятисегментная картинка: margin — поля в пикселях картинки, k — размер пикселя на экране
static func np(name: String, margin: int, k: float, size: Vector2) -> NinePatchRect:
	var r: NinePatchRect = NinePatchRect.new()
	r.texture = tex(name)
	r.patch_margin_left = margin
	r.patch_margin_top = margin
	r.patch_margin_right = margin
	r.patch_margin_bottom = margin
	r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	r.size = size / k
	r.scale = Vector2(k, k)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


## Кнопка: кремовая клавиша, при наведении медовая, при нажатии вдавлена; текст тёмный
static func style_button(b: Control, font: Font, size: int) -> void:
	# StyleBoxTexture не умеет «пиксель ×2», поэтому берём картинки, увеличенные заранее (ui31_btn*_x2)
	for st in [["normal", "ui31_btn_x2", 6.0, 10.0], ["hover", "ui31_btn_hover_x2", 6.0, 10.0],
			["pressed", "ui31_btn_pressed_x2", 10.0, 6.0], ["focus", "", 0.0, 0.0], ["disabled", "ui31_btn_x2", 6.0, 10.0]]:
		if String(st[1]) == "":
			b.add_theme_stylebox_override(String(st[0]), StyleBoxEmpty.new())
			continue
		var sb: StyleBoxTexture = StyleBoxTexture.new()
		sb.texture = tex(String(st[1]))
		sb.texture_margin_left = 10.0
		sb.texture_margin_top = 10.0
		sb.texture_margin_right = 10.0
		sb.texture_margin_bottom = 10.0
		sb.content_margin_left = 16.0
		sb.content_margin_right = 16.0
		sb.content_margin_top = float(st[2])
		sb.content_margin_bottom = float(st[3])
		b.add_theme_stylebox_override(String(st[0]), sb)
	b.add_theme_font_override("font", font)
	b.add_theme_font_size_override("font_size", size)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(c, INK)
	b.add_theme_color_override("font_disabled_color", Color(INK_SOFT, 0.5))
	b.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


## Выпадающий список: кнопка как выше + всплывающее меню на пергаменте
static func style_option(o: OptionButton, font: Font, size: int) -> void:
	style_button(o, font, size)
	var pm: PopupMenu = o.get_popup()
	var sb: StyleBoxTexture = StyleBoxTexture.new()
	sb.texture = tex("ui31_panel_x2")
	sb.texture_margin_left = 24.0
	sb.texture_margin_top = 24.0
	sb.texture_margin_right = 24.0
	sb.texture_margin_bottom = 24.0
	sb.content_margin_left = 14.0
	sb.content_margin_right = 14.0
	sb.content_margin_top = 12.0
	sb.content_margin_bottom = 12.0
	pm.add_theme_stylebox_override("panel", sb)
	var hv: StyleBoxFlat = StyleBoxFlat.new()
	hv.bg_color = Color("f4d488")
	hv.set_corner_radius_all(0)
	pm.add_theme_stylebox_override("hover", hv)
	pm.add_theme_color_override("font_color", INK)
	pm.add_theme_color_override("font_hover_color", INK)
	pm.add_theme_font_override("font", font)
	pm.add_theme_font_size_override("font_size", size)


## Число из пиксельных цифр ui31_dg_* (k — размер пикселя)
static func pix_count(n: int, k: float) -> Control:
	var s: String = str(n)
	var root: Control = Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in range(s.length()):
		var tr: TextureRect = TextureRect.new()
		tr.texture = tex("ui31_dg_" + s[i])
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.size = Vector2(6, 8) * k
		tr.position = Vector2(i * 5, 0) * k
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(tr)
	root.size = Vector2(s.length() * 5 + 1, 8) * k
	return root


## Полоса-шкала на пергаменте: тёплый контур, вдавленное дно, заливка с бликом
static func draw_bar(ci: CanvasItem, r: Rect2, frac: float, col: Color) -> void:
	ci.draw_rect(r.grow(4), Color("6e4636"))
	ci.draw_rect(r.grow(2), Color("e2cba0"))
	ci.draw_rect(Rect2(r.position - Vector2(2, 2), Vector2(r.size.x + 4, 2)), Color("c9ab7e"))
	var f: float = clampf(frac, 0.0, 1.0) * r.size.x
	if f > 0.0:
		ci.draw_rect(Rect2(r.position, Vector2(f, r.size.y)), col.darkened(0.4))
		ci.draw_rect(Rect2(r.position + Vector2(2, 2), Vector2(maxf(f - 4.0, 0.0), r.size.y - 4)), col)
		ci.draw_rect(Rect2(r.position + Vector2(2, 2), Vector2(maxf(f - 4.0, 0.0), 4)), col.lightened(0.35))


# ------------------------------------------------------------------ пиксельный шрифт (v31)
## DotGothic16 (fonts/DotGothic16.ttf, лицензия OFL — fonts/OFL_DotGothic16.txt): нормальная кириллица.
## Сетка шрифта — 16 пикселей на кегль, поэтому чётко он выглядит на 16, 32, 48…: размеры подгоняет snap_size().
## Русские буквы в нём по японской привычке во всю клетку, поэтому tools/font31.py собирает из его букв
## растровый шрифт herb16 (BMFont) с плотной расстановкой — его и используем.
## (Pixelify Sans скачан первым, но у него неудачная кириллица: «в» как «е», «д» как «а» — не используется.)
const FONT_PATH: String = "res://fonts/herb16.fnt"
const FONT_GRID: int = 16
## v31b: пиксель текста = пиксель рисунков (2×2). Поэтому шрифты выводятся только ровно ×2:
##   текст — свой шрифт herb7 (tools/font31b.py, строка 11 → размер 22), жирный — herb7b,
##   заголовки — herb14 (буквы herb7, увеличенные Scale2x; строка 22 → размер 44).
const BODY_PATH: String = "res://fonts/herb7.fnt"
const BOLD_PATH: String = "res://fonts/herb7b.fnt"
const BODY_SIZE: int = 22
const TITLE_SIZE: int = 44
const TITLE_PATH: String = "res://fonts/herb14.fnt"
const FONT_SIZE_PROPS: Array = ["font_size", "normal_font_size", "bold_font_size", "italics_font_size",
	"bold_italics_font_size", "mono_font_size", "title_font_size"]
const FONT_PROPS: Array = ["font", "normal_font", "bold_font", "italics_font", "bold_italics_font", "mono_font", "title_font"]
static var _fonts: Dictionary = {}


static func _bitmap(path: String, px: int) -> FontFile:
	var f: FontFile = load(path)
	f.fixed_size = px
	f.fixed_size_scale_mode = TextServer.FIXED_SIZE_SCALE_INTEGER_ONLY   # только целое увеличение — пиксели ровные
	f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	f.generate_mipmaps = false
	return f


## 400 — обычный текст, 600 — жирный, 700 — заголовки
static func pixel_font(weight: int = 400) -> Font:
	if _fonts.has(weight):
		return _fonts[weight]
	var t16: FontFile = _bitmap(FONT_PATH, FONT_GRID)
	var dg: FontFile = load("res://fonts/DotGothic16.ttf")    # редкие символы
	dg.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	dg.hinting = TextServer.HINTING_NONE
	t16.fallbacks = [dg]
	var base: FontFile
	if weight >= 700:
		base = _bitmap(TITLE_PATH, 22)
		base.fallbacks = [t16]
	else:
		base = _bitmap(BOLD_PATH if weight >= 600 else BODY_PATH, 11)
		base.fallbacks = [t16]
	var fv: FontVariation = FontVariation.new()
	fv.base_font = base
	_fonts[weight] = fv
	return fv


## Размер всегда один: текст 22 (herb7 ×2), заголовки 44 (herb14 ×2) — у всех букв пиксель 2×2
static func snap_size(_s: int, title: bool = false) -> int:
	return TITLE_SIZE if title else BODY_SIZE


## Шрифт заголовков (отдельный объект — по нему snap_node узнаёт заголовок)
static func title_font() -> Font:
	return pixel_font(700)


## Заменить системный шрифт на пиксельный и подогнать размеры у одного узла
static func snap_node(n: Node) -> void:
	if not (n is Control):
		return
	var c: Control = n
	for fp in FONT_PROPS:
		if c.has_theme_font_override(fp):
			var f: Font = c.get_theme_font(fp)
			if f is SystemFont:
				var w: int = (f as SystemFont).font_weight
				c.add_theme_font_override(fp, pixel_font(600 if w >= 600 else 400))
	var is_title: bool = c.has_theme_font_override("font") and c.get_theme_font("font") == title_font()
	for sp in FONT_SIZE_PROPS:
		if c.has_theme_font_size_override(sp):
			var v: int = c.get_theme_font_size(sp)
			# уже подогнанный размер второй раз не трогаем (узел могли добавить в дерево повторно)
			if int(c.get_meta("px_" + sp, -1)) == v:
				continue
			var nv: int = snap_size(v, is_title)
			c.set_meta("px_" + sp, nv)
			if nv != v:
				c.add_theme_font_size_override(sp, nv)


static func snap_tree(n: Node) -> void:
	snap_node(n)
	for ch in n.get_children():
		snap_tree(ch)


## Тема всего окна: пиксельный шрифт (22 = herb7 ×2) для текста без своих настроек
static func install(tree: SceneTree) -> void:
	var th: Theme = Theme.new()
	th.default_font = pixel_font(400)
	th.default_font_size = BODY_SIZE
	tree.root.theme = th
	ThemeDB.fallback_font = pixel_font(400)      # и для draw_string(ThemeDB.fallback_font, …)
	ThemeDB.fallback_font_size = BODY_SIZE
	tree.node_added.connect(func(n: Node) -> void:
		# размеры часто задаются сразу после add_child — проверяем в конце кадра
		(func() -> void:
			if is_instance_valid(n):
				snap_node(n)).call_deferred())
	snap_tree(tree.root)

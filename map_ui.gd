extends CanvasLayer
## Карта мира на M. Сначала всё под облаками-туманом; открывается там, где прошла героиня.
## Без надписей: только рисунок, значки мест и отметка героини.
## v20: колесо мыши (или + / −) — приблизить/отдалить к курсору, ЛКМ тянуть — двигать карту, Пробел — к героине.
## Отметка героини большая и заметная (пульсирует, с лучом взгляда); при приближении становится меньше.

const WD = preload("res://world_data.gd")
const FOG_SHADER: String = """
shader_type canvas_item;
uniform sampler2D fog : filter_linear;
uniform vec2 px_size = vec2(840.0, 400.0);
uniform float time = 0.0;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vnoise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}
void fragment() {
	// пиксели тумана — по сетке карты, край рваный, облака медленно плывут
	vec2 cell = floor(UV * px_size);
	vec2 uv = (cell + 0.5) / px_size;
	float n = vnoise(cell / 34.0 + vec2(time * 0.08, 0.0)) * 0.6 + vnoise(cell / 13.0 - vec2(0.0, time * 0.05)) * 0.3 + vnoise(cell / 4.0) * 0.1;
	float open = texture(fog, uv).r;
	float a = smoothstep(0.30, 0.62, open + (n - 0.5) * 0.45);
	// облака плоскими пятнами: тень, основной, свет (как пиксельные облака)
	vec3 cloud = vec3(0.86, 0.82, 0.76);
	if (n > 0.56) cloud = vec3(0.95, 0.93, 0.88);
	if (n > 0.70) cloud = vec3(0.99, 0.98, 0.95);
	if (n < 0.40) cloud = vec3(0.76, 0.72, 0.68);
	float edge = smoothstep(0.0, 0.25, a) * (1.0 - smoothstep(0.25, 0.6, a));
	cloud = mix(cloud, vec3(0.55, 0.48, 0.40), edge * 0.6);
	COLOR = vec4(cloud, 1.0 - a);
}
"""
const VIEW: Rect2 = Rect2(70, 50, 1780, 980)      # окно карты на экране
const ZOOM_MAX: float = 6.0

var main: Node2D
var world: Node2D
var root: Control
var view: Control            # окно с обрезкой
var canvas: Control          # сама карта (масштабируется)
var map_rect: TextureRect
var fog_rect: TextureRect
var fog_img: Image
var fog_tex: ImageTexture
var fog_mat: ShaderMaterial
var marker: Control
var home_mark: Control      # v29: значок дома на карте
var home_map: Vector2 = Vector2.ZERO
var open: bool = false
var t: float = 0.0
var map_size: Vector2 = Vector2.ONE
var fit: float = 1.0          # масштаб, при котором видна вся карта
var zoom: float = 1.0         # во сколько раз ближе, чем «вся карта»
var zoom_target: float = 1.0
var pan: Vector2 = Vector2.ZERO   # точка карты (в пикселях карты) в центре окна
var pan_target: Vector2 = Vector2.ZERO
var dragging: bool = false
var hero_map: Vector2 = Vector2.ZERO
var hero_dir: Vector2 = Vector2.DOWN


func setup(m: Node2D, w: Node2D) -> void:
	main = m
	world = w
	layer = 30
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.visible = false
	add_child(root)
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0.08, 0.06, 0.10, 0.78)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(dim)
	# рамка: тёмное дерево и кант
	for k in [[14, Color("2a1a12")], [10, Color("6a4428")], [6, Color("a07040")], [3, Color("3a2416")]]:
		var fr: ColorRect = ColorRect.new()
		fr.color = k[1]
		fr.position = VIEW.position - Vector2(int(k[0]), int(k[0]))
		fr.size = VIEW.size + Vector2(int(k[0]), int(k[0])) * 2.0
		fr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(fr)
	view = Control.new()
	view.position = VIEW.position
	view.size = VIEW.size
	view.clip_contents = true
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(view)
	var bg: ColorRect = ColorRect.new()
	bg.color = Color("3a3226")
	bg.size = VIEW.size
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	view.add_child(bg)
	var tex: Texture2D = load("res://art/world_map.png")
	map_size = Vector2(tex.get_width(), tex.get_height())
	fit = minf(VIEW.size.x / map_size.x, VIEW.size.y / map_size.y)
	canvas = Control.new()
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	view.add_child(canvas)
	map_rect = TextureRect.new()
	map_rect.texture = tex
	map_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	map_rect.size = map_size
	map_rect.stretch_mode = TextureRect.STRETCH_SCALE
	map_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(map_rect)
	fog_img = Image.create_empty(world.call("fog_w"), world.call("fog_h"), false, Image.FORMAT_L8)
	fog_tex = ImageTexture.create_from_image(fog_img)
	fog_rect = TextureRect.new()
	fog_rect.texture = fog_tex
	fog_rect.size = map_size
	fog_rect.stretch_mode = TextureRect.STRETCH_SCALE
	fog_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh: Shader = Shader.new()
	sh.code = FOG_SHADER
	fog_mat = ShaderMaterial.new()
	fog_mat.shader = sh
	fog_mat.set_shader_parameter("fog", fog_tex)
	fog_mat.set_shader_parameter("px_size", map_size)
	fog_rect.material = fog_mat
	canvas.add_child(fog_rect)
	# отметка героини — в окне (не масштабируется вместе с картой)
	marker = Control.new()
	marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marker.draw.connect(_draw_marker)
	view.add_child(marker)
	home_mark = Control.new()
	home_mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	home_mark.draw.connect(_draw_home)
	view.add_child(home_mark)
	view.move_child(home_mark, marker.get_index())      # дом под отметкой героини
	zoom = clampf(Game.map_zoom, 1.0, ZOOM_MAX)
	zoom_target = zoom


## Размер отметки: при всей карте — крупная (видно сразу), при приближении — меньше, чтобы не закрывала
func _marker_k() -> float:
	return clampf(2.6 / pow(zoom, 0.55), 0.85, 2.6)


## Отметка героини: яркая капля-стрелка с белой каймой, лучом взгляда и расходящимися кругами
func _draw_marker() -> void:
	var k: float = _marker_k()
	var pulse: float = fmod(t * 0.9, 1.0)
	# расходящиеся круги — видно издалека
	for i in range(2):
		var p: float = fmod(pulse + float(i) * 0.5, 1.0)
		marker.draw_arc(Vector2.ZERO, (10.0 + p * 34.0) * k, 0.0, TAU, 40, Color(1.0, 0.85, 0.3, 0.75 * (1.0 - p)), 3.0 * k)
	# тень
	marker.draw_circle(Vector2(0, 2.0 * k), 9.0 * k, Color(0, 0, 0, 0.35))
	# стрелка-указатель направления взгляда
	var d: Vector2 = hero_dir.normalized()
	var side: Vector2 = Vector2(-d.y, d.x)
	var tip: Vector2 = d * 17.0 * k
	var pts: PackedVector2Array = PackedVector2Array([tip, side * 8.0 * k - d * 4.0 * k, -d * 1.0 * k, -side * 8.0 * k - d * 4.0 * k])
	var outline: PackedVector2Array = PackedVector2Array()
	for q in pts:
		outline.append(q * 1.0)
	marker.draw_colored_polygon(_grow(pts, 3.0 * k), Color("2a1418"))
	marker.draw_colored_polygon(_grow(pts, 1.6 * k), Color("fff6e0"))
	marker.draw_colored_polygon(pts, Color("e83a4a"))
	# кружок героини
	marker.draw_circle(Vector2.ZERO, 7.5 * k, Color("2a1418"))
	marker.draw_circle(Vector2.ZERO, 6.0 * k, Color("fff6e0"))
	marker.draw_circle(Vector2.ZERO, 4.4 * k, Color("e83a4a"))
	marker.draw_circle(Vector2(-1.4, -1.4) * k, 1.6 * k, Color(1, 1, 1, 0.8))


## v29: домик травницы — значок на карте (виден всегда, туман его не закрывает)
func _draw_home() -> void:
	var k: float = _marker_k() * 0.8
	var o: Color = Color("2a1418")
	home_mark.draw_circle(Vector2(0, 3.0 * k), 11.0 * k, Color(0, 0, 0, 0.3))
	var roof: PackedVector2Array = PackedVector2Array([Vector2(-11, -2), Vector2(0, -12), Vector2(11, -2)]) 
	var roof_o: PackedVector2Array = PackedVector2Array()
	var roof_i: PackedVector2Array = PackedVector2Array()
	for q in roof:
		roof_o.append(q * k * 1.25 + Vector2(0, -1) * k)
		roof_i.append(q * k)
	home_mark.draw_rect(Rect2(Vector2(-8.5, -3.5) * k, Vector2(17, 13) * k), o)
	home_mark.draw_colored_polygon(roof_o, o)
	home_mark.draw_rect(Rect2(Vector2(-7, -2) * k, Vector2(14, 10.5) * k), Color("f4e2b8"))
	home_mark.draw_colored_polygon(roof_i, Color("c8503c"))
	home_mark.draw_rect(Rect2(Vector2(-2, 2.5) * k, Vector2(4, 6) * k), Color("6a4428"))


func _grow(pts: PackedVector2Array, by: float) -> PackedVector2Array:
	var c: Vector2 = Vector2.ZERO
	for p in pts:
		c += p
	c /= float(pts.size())
	var out: PackedVector2Array = PackedVector2Array()
	for p in pts:
		out.append(p + (p - c).normalized() * by)
	return out


func _refresh_fog() -> void:
	var w: int = fog_img.get_width()
	var data: PackedByteArray = Game.explored
	if data.size() == fog_img.get_width() * fog_img.get_height():
		fog_img.set_data(w, fog_img.get_height(), false, Image.FORMAT_L8, data)
		fog_tex.update(fog_img)


func toggle() -> void:
	if not open and (Game.ui_open or Game.busy):
		return
	open = not open
	root.visible = open
	Game.ui_open = open
	if open:
		_refresh_fog()
		_update_hero()
		pan = hero_map
		pan_target = pan
		_apply()


func _update_hero() -> void:
	var hp: Vector2 = preload("res://world_layout.gd").DOOR_POS + (main.call("home_off") as Vector2)
	home_map = (hp - WD.ORIGIN) / float(WD.CELL)
	var pl: Node2D = main.get("player") as Node2D
	var wp: Vector2 = pl.global_position
	if bool(main.get("inside")):
		wp = Vector2(960, 372)
	hero_map = (wp - WD.ORIGIN) / float(WD.CELL)
	var f: int = int(pl.get("facing"))
	var dirs: Array = pl.get("FACE_DIRS")
	if f >= 0 and f < dirs.size():
		hero_dir = dirs[f]


func _scale() -> float:
	return fit * zoom


## Не уводить карту за край: при всей карте — по центру
func _clamp_pan(p: Vector2, z: float) -> Vector2:
	var s: float = fit * z
	var half: Vector2 = VIEW.size / (2.0 * s)
	var out: Vector2 = p
	for ax in [0, 1]:
		var lo: float = half[ax]
		var hi: float = map_size[ax] - half[ax]
		out[ax] = map_size[ax] / 2.0 if lo > hi else clampf(p[ax], lo, hi)
	return out


func _apply() -> void:
	pan = _clamp_pan(pan, zoom)
	var s: float = _scale()
	canvas.scale = Vector2(s, s)
	canvas.position = (VIEW.size / 2.0 - pan * s).round()
	marker.position = canvas.position + hero_map * s
	marker.queue_redraw()
	home_mark.position = canvas.position + home_map * s
	home_mark.queue_redraw()


func _process(delta: float) -> void:
	if not open:
		return
	t += delta
	fog_mat.set_shader_parameter("time", t)
	_update_hero()
	# плавное приближение
	var old_z: float = zoom
	zoom = lerpf(zoom, zoom_target, minf(1.0, delta * 12.0))
	if absf(zoom - zoom_target) < 0.002:
		zoom = zoom_target
	if not dragging:
		pan = pan.lerp(pan_target, minf(1.0, delta * 12.0))
	if old_z != zoom:
		Game.map_zoom = zoom_target
	_apply()


## Приблизить к точке окна: эта точка карты остаётся под курсором
func _zoom_at(view_pt: Vector2, factor: float) -> void:
	var s0: float = fit * zoom_target
	var map_pt: Vector2 = pan_target + (view_pt - VIEW.size / 2.0) / s0
	zoom_target = clampf(zoom_target * factor, 1.0, ZOOM_MAX)
	var s1: float = fit * zoom_target
	pan_target = _clamp_pan(map_pt - (view_pt - VIEW.size / 2.0) / s1, zoom_target)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var k: Key = (event as InputEventKey).physical_keycode
		if KB.is_key("map", k) or (open and k == KEY_ESCAPE):
			toggle()
			get_viewport().set_input_as_handled()
			return
		if open:
			if k == KEY_EQUAL or k == KEY_KP_ADD:
				_zoom_at(VIEW.size / 2.0, 1.4)
			elif k == KEY_MINUS or k == KEY_KP_SUBTRACT:
				_zoom_at(VIEW.size / 2.0, 1.0 / 1.4)
			elif k == KEY_SPACE:
				pan_target = hero_map
			get_viewport().set_input_as_handled()
		return
	if not open:
		return
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		var vp: Vector2 = mb.position - VIEW.position
		if mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_at(vp, 1.25)
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_at(vp, 1.0 / 1.25)
		elif mb.button_index == MOUSE_BUTTON_LEFT:
			dragging = mb.pressed
			if not dragging:
				pan_target = pan
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and dragging:
		pan -= (event as InputEventMouseMotion).relative / _scale()
		pan = _clamp_pan(pan, zoom)
		pan_target = pan
		get_viewport().set_input_as_handled()

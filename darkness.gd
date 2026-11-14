extends CanvasLayer
## Ночная тьма (v16). Поверх мира — тёмный слой с «дырами» света: факел или фонарь героини, костры,
## фонари и светящиеся окна. В лесах и диких краях ночью почти полная темень, в городах и у дома — мягче,
## в доме и под водой тьмы нет. Края света — ступеньками в пиксель мира.
## Факел есть всегда (T — зажечь / погасить), фонарь в руке или лунный амулет светят шире и ровнее.

const WD = preload("res://world_data.gd")
const MAX_L: int = 24
const TORCH_R: float = 96.0       # радиус в пикселях мира
const LANTERN_R: float = 150.0

var main: Node2D
var rect: ColorRect
var mat: ShaderMaterial
var dark_now: float = 0.0
var torch_on: bool = true          # F переключает
var t: float = 0.0
var held: Sprite2D
var flame: CPUParticles2D

const SHADER: String = """
shader_type canvas_item;
render_mode blend_premul_alpha;
// v24: мягкий свет — тёплое ядро, широкий слабый ореол, синие лунные сумерки вместо чёрной заливки
uniform float dark = 0.0;
uniform int n = 0;
uniform vec4 lights[24];
uniform vec4 cols[24];
uniform vec2 screen = vec2(1920.0, 1080.0);
uniform float px = 3.0;
float bayer(vec2 q) {
	int x = int(mod(q.x, 4.0));
	int y = int(mod(q.y, 4.0));
	int m[16] = int[16](0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5);
	return (float(m[y * 4 + x]) + 0.5) / 16.0;
}
void fragment() {
	vec2 cell = floor(UV * screen / px);
	vec2 p = cell * px + px * 0.5;
	float lit = 0.0;
	vec3 glow = vec3(0.0);
	for (int i = 0; i < 24; i++) {
		if (i >= n) break;
		float d = distance(p, lights[i].xy);
		float r = lights[i].z;
		float x = clamp(d / (r * 1.35), 0.0, 1.0);
		// ядро ярче, края длиннее (почти как обратный квадрат, но конечный)
		float k = (1.0 - x) * (1.0 - x) / (1.0 + 6.0 * x * x);
		k *= lights[i].w;
		lit = 1.0 - (1.0 - lit) * (1.0 - k);
		glow += cols[i].rgb * k;
	}
	// пиксельные ступени света (без шахматной ряби)
	float steps = 10.0;
	lit = clamp(floor(lit * steps + 0.5) / steps, 0.0, 1.0);
	vec3 night = vec3(0.012, 0.02, 0.06);
	vec3 warm = glow / max(max(glow.r, max(glow.g, glow.b)), 0.001);
	float a = dark * (1.0 - lit);
	// тёплый отсвет сложением (premul): у огня сильнее, к краю света затухает
	float add = dark * lit * 0.5;
	// у огня чуть «съедаем» синеву ночи и кладём тёплый цвет — освещённое выглядит тёплым, а не серым
	float eat = dark * lit * 0.28;
	COLOR = vec4(night * a + warm * vec3(1.0, 0.7, 0.42) * add, a + eat);
}
"""


func setup(m: Node2D) -> void:
	main = m
	layer = 2
	add_to_group("darkness")
	rect = ColorRect.new()
	rect.size = Vector2(1920, 1080)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh: Shader = Shader.new()
	sh.code = SHADER
	mat = ShaderMaterial.new()
	mat.shader = sh
	rect.material = mat
	add_child(rect)
	# факел / фонарь в руке героини
	held = Sprite2D.new()
	held.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	held.centered = false
	held.visible = false
	var pl: Node2D = main.get("player")
	pl.add_child(held)
	flame = CPUParticles2D.new()
	flame.texture = load("res://art/fx_soft.png")
	flame.amount = 14
	flame.lifetime = 0.45
	flame.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	flame.emission_rect_extents = Vector2(1.5, 1)
	flame.direction = Vector2(0, -1)
	flame.spread = 14.0
	flame.gravity = Vector2(0, -30)
	flame.initial_velocity_min = 6.0
	flame.initial_velocity_max = 14.0
	flame.scale_amount_min = 0.03
	flame.scale_amount_max = 0.07
	var g: Gradient = Gradient.new()
	g.set_color(0, Color(1.0, 0.95, 0.6, 1.0))
	g.set_color(1, Color(0.9, 0.2, 0.05, 0.0))
	g.add_point(0.4, Color(1.0, 0.55, 0.15, 0.9))
	flame.color_ramp = g
	var add: CanvasItemMaterial = CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	flame.material = add
	flame.emitting = false
	held.add_child(flame)


## v24: свет только от того, что в руке: фонарь (light >= 1) или факел (light 0.5)
func has_lantern() -> bool:
	return Game.stat("light") >= 1.0


func has_light() -> bool:
	return Game.stat("light") > 0.0


## Насколько темно должно быть здесь (0 — светло, ~0.97 — темень)
func want_dark() -> float:
	if bool(main.get("inside")) or main.get("visiting") != null:
		return 0.0
	var pos: Vector2 = (main.get("player") as Node2D).global_position
	if pos.x < -50000.0:
		return 0.0     # клуб «Старлит»: свои прожекторы
	if pos.y < -150000.0:
		return 0.32 if Game.realm == "hell" else 0.0     # v24: в Аду вечные сумерки, в Раю всегда светло
	if pos.x > 150000.0:
		return 0.55    # v23: подземелья — светят факелы на стенах
	if pos.y > 120000.0:
		return 0.72    # v19: в шахте темно всегда — светят фонари и факел
	if pos.y > 90000.0:
		return 0.0     # под водой свой свет
	var n: float = Game.night_factor()
	if n <= 0.0:
		return 0.0
	var k: float = 0.97
	if pos.distance_to(Game.home_pos) < 700.0 or main.get("classic_yard") == true and pos.distance_to(Vector2(960, 600)) < 900.0:
		k = 0.86
	for tc in _town_centers():
		if pos.distance_to(tc) < 1100.0:
			k = 0.78
			break
	return n * k * 0.95


func _town_centers() -> Array:
	var out: Array = []
	var TW = preload("res://towns.gd")
	for land in TW.TOWNS.keys():
		var d: Dictionary = TW.TOWNS[land]
		if d.has("c"):
			out.append(d["c"])
		elif d.has("center"):
			out.append(d["center"])
	return out




func _process(delta: float) -> void:
	t += delta
	var want: float = want_dark()
	dark_now = move_toward(dark_now, want, delta * 0.5) if t > 0.5 else want
	if (main.get("player") as Node2D).global_position.x < -50000.0:
		dark_now = 0.0
	var in_mine: bool = (main.get("player") as Node2D).global_position.y > 120000.0 or (main.get("player") as Node2D).global_position.x > 150000.0
	var night_light: bool = (Game.night_factor() > 0.35 or in_mine) and not bool(main.get("inside"))
	Game.light_on = night_light and has_light()
	_update_held()
	rect.visible = dark_now > 0.01
	if not rect.visible:
		return
	var ct: Transform2D = get_viewport().get_canvas_transform()
	var zoom: float = ct.get_scale().x
	var lights: Array = []
	var pl: Node2D = main.get("player")
	if Game.light_on:
		var lan: bool = has_lantern()
		var r: float = (LANTERN_R if lan else TORCH_R + sin(t * 11.0) * 4.0 + sin(t * 23.0) * 2.0)
		lights.append([ct * (pl.global_position + Vector2(0, -16)), r * zoom, 1.0, Color(1.0, 0.75, 0.45) if not lan else Color(1.0, 0.92, 0.7)])
	for cf in get_tree().get_nodes_in_group("campfires"):
		var lr: float = float(cf.call("light_radius"))
		if lr > 0.0:
			lights.append([ct * ((cf as Node2D).global_position + Vector2(0, -10)), (lr + sin(t * 9.0 + 1.0) * 4.0) * zoom, 1.0, Color(1.0, 0.7, 0.4)])
	# огоньки фонарей и окон (слой свечения)
	var fl: Variant = main.get("fx_layer")
	if fl != null:
		for s in (fl as Node).get_children():
			if s is Sprite2D and (s as Sprite2D).visible and (s as Sprite2D).modulate.a > 0.05:
				var sp: Sprite2D = s
				lights.append([ct * sp.global_position, 46.0 * sp.scale.x * zoom, clampf(sp.modulate.a * 1.4, 0.0, 0.9), Color(1.0, 0.75, 0.45)])
	# ближние к героине — первыми
	var me: Vector2 = ct * pl.global_position
	lights.sort_custom(func(a: Array, b: Array) -> bool: return (a[0] as Vector2).distance_to(me) < (b[0] as Vector2).distance_to(me))
	var arr: PackedVector4Array = PackedVector4Array()
	var cols: PackedVector4Array = PackedVector4Array()
	for i in range(MAX_L):
		if i < lights.size() and (lights[i][0] as Vector2).distance_to(Vector2(960, 540)) < 1500.0:
			var L: Array = lights[i]
			arr.append(Vector4((L[0] as Vector2).x, (L[0] as Vector2).y, float(L[1]), float(L[2])))
			var c: Color = L[3]
			cols.append(Vector4(c.r, c.g, c.b, 1.0))
		else:
			arr.append(Vector4(-9999, -9999, 1, 0))
			cols.append(Vector4(0, 0, 0, 0))
	mat.set_shader_parameter("lights", arr)
	mat.set_shader_parameter("cols", cols)
	mat.set_shader_parameter("n", mini(lights.size(), MAX_L))
	mat.set_shader_parameter("dark", dark_now)
	mat.set_shader_parameter("px", maxf(1.0, zoom))


func _update_held() -> void:
	var show: bool = Game.light_on
	held.visible = show
	flame.emitting = show and not has_lantern()
	if not show:
		return
	var lan: bool = has_lantern()
	held.texture = load("res://art/lantern_held.png" if lan else "res://art/torch_held.png")
	var fc: int = int((main.get("player") as Node2D).get("facing"))
	var left: bool = fc in [2, 4, 5]
	held.scale = Vector2(0.5, 0.5)
	held.position = Vector2(-9.0 if left else 5.0, -24.0)
	held.flip_h = left
	held.show_behind_parent = fc in [1, 5, 7]
	flame.position = Vector2(4, 0)

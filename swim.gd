extends Node2D
## v22: хвост русалки и вода вокруг пояса, пока героиня плывёт по морю (Game.mermaid_t > 0 и Game.in_sea).
## Весь рисунок собирается пикселями в коде: хвост (8 кадров качания), полупрозрачная вода и кольцо пены.

const TAIL_W: int = 32
const TAIL_H: int = 46
const TAIL_FRAMES: int = 8
const RAMP: Array = ["0b3a46", "126a70", "1f9a96", "3cc4b0", "7ae8cc", "c8fff0"]

var tail: Sprite2D
var water: Sprite2D
var foam: Sprite2D
var bubbles: CPUParticles2D
var tail_tex: Array = []
var foam_tex: Array = []
var amount: float = 0.0
var t: float = 0.0
var player: Node2D


func _ready() -> void:
	player = get_parent() as Node2D
	z_index = 1
	for i in range(TAIL_FRAMES):
		tail_tex.append(_make_tail(float(i) / float(TAIL_FRAMES) * TAU))
	for j in range(4):
		foam_tex.append(_make_foam(j))
	water = Sprite2D.new()
	water.texture = _make_water()
	water.centered = false
	water.position = Vector2(-18, -31)
	add_child(water)
	tail = Sprite2D.new()
	tail.texture = tail_tex[0]
	tail.centered = false
	tail.position = Vector2(-16, -31)
	add_child(tail)
	foam = Sprite2D.new()
	foam.texture = foam_tex[0]
	foam.centered = false
	foam.position = Vector2(-19, -34)
	add_child(foam)
	bubbles = CPUParticles2D.new()
	bubbles.texture = load("res://art/fx_firefly.png")
	bubbles.amount = 6
	bubbles.lifetime = 1.6
	bubbles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	bubbles.emission_rect_extents = Vector2(6, 2)
	bubbles.gravity = Vector2(0, -26)
	bubbles.initial_velocity_min = 2.0
	bubbles.initial_velocity_max = 8.0
	bubbles.direction = Vector2(0, -1)
	bubbles.spread = 25.0
	bubbles.scale_amount_min = 0.35
	bubbles.scale_amount_max = 0.8
	bubbles.color = Color(0.9, 0.98, 1.0, 0.75)
	bubbles.position = Vector2(0, -24)
	bubbles.emitting = false
	add_child(bubbles)
	visible = false


func _process(delta: float) -> void:
	var on: bool = Game.mermaid_t > 0.0 and Game.in_sea
	amount = move_toward(amount, 1.0 if on else 0.0, delta * 4.0)
	visible = amount > 0.01
	bubbles.emitting = on
	if not visible:
		return
	t += delta
	var sp: float = (player.get("vel") as Vector2).length() if player != null and player.get("vel") != null else 0.0
	# чем быстрее плывёт, тем быстрее машет хвостом
	t += delta * clampf(sp / 60.0, 0.0, 1.0) * 1.4
	tail.texture = tail_tex[int(t * 7.0) % TAIL_FRAMES]
	foam.texture = foam_tex[int(t * 3.0) % 4]
	modulate.a = amount


## Хвост от пояса до плавника. phase — фаза качания (0..TAU)
func _make_tail(phase: float) -> ImageTexture:
	var im: Image = Image.create_empty(TAIL_W, TAIL_H, false, Image.FORMAT_RGBA8)
	var ramp: Array = []
	for c in RAMP:
		ramp.append(Color(String(c)))
	var body_h: int = 28
	var amp: float = 2.6
	var tip_x: float = 16.0
	for y in range(body_h):
		var s: float = float(y) / float(body_h - 1)
		var cx: float = 16.0 + sin(s * 2.8 - phase) * amp * s
		var hw: float = lerpf(8.6, 2.6, pow(s, 0.85))
		tip_x = cx
		for x in range(TAIL_W):
			var d: float = (float(x) + 0.5 - cx) / hw
			if absf(d) > 1.0:
				continue
			var k: int = 3 - int(round(d * 1.6))
			if (x + y * 2) % 5 == 0 and y % 2 == 0:
				k += 1                       # чешуйки
			if y < 3:
				k = 2
			im.set_pixel(x, y, ramp[clampi(k, 1, 5)])
	# плавник: веер с вырезом на конце
	for y in range(body_h, TAIL_H):
		var u: float = float(y - body_h) / float(TAIL_H - body_h)
		var fw: float = 2.4 + 9.5 * sin(u * 1.5)
		var cxf: float = tip_x + sin(phase + 1.3) * 3.2 * u
		for x in range(TAIL_W):
			var dd: float = absf(float(x) + 0.5 - cxf)
			if dd > fw:
				continue
			if u > 0.62 and dd < (u - 0.62) * 15.0:
				continue                     # вырез между лопастями
			var k2: int = 2 + int(dd / fw * 2.4)
			if int(dd) % 3 == 0:
				k2 -= 1                      # лучи плавника
			im.set_pixel(x, y, ramp[clampi(k2, 1, 5)])
	# обводка
	var out: Image = im.duplicate()
	var dark: Color = Color(ramp[0])
	for y in range(TAIL_H):
		for x in range(TAIL_W):
			if im.get_pixel(x, y).a > 0.0:
				continue
			for o in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var q: Vector2i = Vector2i(x, y) + (o as Vector2i)
				if q.x < 0 or q.y < 0 or q.x >= TAIL_W or q.y >= TAIL_H:
					continue
				if q.y > 0 and im.get_pixel(q.x, q.y).a > 0.0:
					out.set_pixel(x, y, dark)
					break
	return ImageTexture.create_from_image(out)


## Вода вокруг ног: бледное полупрозрачное пятно, чтобы подол казался под водой
func _make_water() -> ImageTexture:
	var im: Image = Image.create_empty(36, 24, false, Image.FORMAT_RGBA8)
	for y in range(24):
		for x in range(36):
			var d: float = Vector2((float(x) + 0.5 - 18.0) / 17.5, (float(y) + 0.5 - 12.0) / 11.5).length()
			if d <= 1.0:
				var a: float = 0.55 if d < 0.85 else 0.38
				im.set_pixel(x, y, Color(0.35, 0.72, 0.9, a))
	return ImageTexture.create_from_image(im)


## Кольцо пены у пояса (4 кадра: пена бежит по кругу)
func _make_foam(frame: int) -> ImageTexture:
	var im: Image = Image.create_empty(38, 14, false, Image.FORMAT_RGBA8)
	for i in range(48):
		var a: float = TAU * float(i) / 48.0
		var x: int = 19 + int(round(cos(a) * 16.5))
		var y: int = 7 + int(round(sin(a) * 4.8))
		var on: bool = (i + frame * 3) % 6 < 3
		im.set_pixel(x, y, Color(0.95, 1.0, 1.0, 0.95 if on else 0.4))
		if on and sin(a) > 0.0:
			im.set_pixel(x, mini(13, y + 1), Color(0.8, 0.95, 1.0, 0.5))
	return ImageTexture.create_from_image(im)

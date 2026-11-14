extends Control
## Пиксельный глаз сверху по центру экрана: появляется, когда включён «взгляд» (клавиша V).
## Зрачок плавно блуждает из стороны в сторону, веки чуть сужаются — как будто вглядывается.

const PX: int = 3                 # размер пикселя на экране
const W: int = 21                 # ширина глаза в пикселях
const H: int = 11                 # высота
var t: float = 0.0
var appear: float = 0.0           # 0..1 — плавное появление
var shown: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(W * PX, H * PX)
	visible = false


func set_shown(v: bool) -> void:
	shown = v
	if v:
		visible = true


func _process(delta: float) -> void:
	t += delta
	appear = move_toward(appear, 1.0 if shown else 0.0, delta * 5.0)
	if appear <= 0.0 and not shown:
		visible = false
		return
	var vs: Vector2 = get_viewport_rect().size
	position = Vector2((vs.x - W * PX) * 0.5, 14.0)
	modulate.a = appear
	queue_redraw()


func _draw() -> void:
	var cx: float = (W - 1) * 0.5
	var cy: float = (H - 1) * 0.5
	# веки сужаются и раскрываются (щурится), в начале раскрывается из закрытого
	var open: float = (0.78 + 0.16 * sin(t * 2.3)) * appear
	var look: float = sin(t * 1.1) * 4.0 + sin(t * 2.9) * 1.0   # куда смотрит зрачок
	var ink := Color(0.10, 0.07, 0.10)
	var white := Color(0.95, 0.92, 0.82)
	var iris := Color(0.30, 0.62, 0.38)
	var pupil := Color(0.05, 0.05, 0.08)
	for y in range(H):
		var ny: float = (y - cy) / (cy * open + 0.01)
		if absf(ny) > 1.0:
			continue
		var hw: float = (W * 0.5) * sqrt(1.0 - ny * ny)
		for x in range(W):
			var dx: float = x - cx
			if absf(dx) > hw:
				continue
			var edge: bool = absf(dx) > hw - 1.0 or absf(ny) > 1.0 - 1.2 / (cy * open + 0.01)
			var col: Color = white
			var ix: float = x - (cx + look)
			var iy: float = y - cy
			var d: float = sqrt(ix * ix + iy * iy)
			if d <= 3.6:
				col = iris
			if d <= 1.8:
				col = pupil
			if d > 3.6 and d <= 4.6 and edge == false:
				col = white
			if edge:
				col = ink
			if d <= 1.0 and not edge and x == int(cx + look) - 1 and y == int(cy) - 1:
				col = Color(1, 1, 1)   # блик
			draw_rect(Rect2(x * PX, y * PX, PX, PX), col)

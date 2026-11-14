extends Node2D
## Покупательница лавки зелий: приходит издалека, стоит у прилавка, платит (монетка над головой) и уходит.

const SHEETS: Array = ["res://art/villager_marta.png", "res://art/villager_lina.png", "res://art/villager_tim.png"]
const SPEED: float = 46.0
const STRIDE: float = 9.0

var target: Vector2 = Vector2.ZERO
var away: Vector2 = Vector2.ZERO
var on_buy: Callable
var spr: Sprite2D
var state: int = 0          # 0 идёт к лавке, 1 стоит и выбирает, 2 уходит
var wait: float = 0.0
var dist: float = 0.0
var row: int = 0
var t: float = 0.0
var coin: Sprite2D


func setup(from: Vector2, to: Vector2, cb: Callable, seed_v: int) -> void:
	position = from
	away = from
	target = to
	on_buy = cb
	spr = Sprite2D.new()
	spr.texture = load(String(SHEETS[absi(seed_v) % SHEETS.size()]))
	spr.hframes = 8
	spr.vframes = 8
	spr.centered = false
	spr.offset = Vector2(-40, -157)
	spr.scale = Vector2(0.3333, 0.3333)
	add_child(spr)
	coin = Sprite2D.new()
	coin.texture = load("res://art/coin.png")
	coin.position = Vector2(0, -62)
	coin.scale = Vector2(0.5, 0.5)
	coin.visible = false
	add_child(coin)
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.8)


func _row_for(v: Vector2) -> int:
	if absf(v.x) < absf(v.y) * 0.6:
		return 0 if v.y > 0.0 else 1
	return 2 if v.x < 0.0 else 3


func _process(delta: float) -> void:
	t += delta
	match state:
		0:
			if _go(target, delta):
				state = 1
				wait = 2.2
				row = 1
		1:
			wait -= delta
			if wait < 1.2 and not coin.visible:
				coin.visible = true
				if on_buy.is_valid():
					on_buy.call()
			if coin.visible:
				coin.position.y = -62.0 - (1.2 - maxf(wait, 0.0)) * 14.0
				coin.modulate.a = clampf(wait, 0.0, 1.0)
			if wait <= 0.0:
				state = 2
		2:
			if _go(away, delta) or position.distance_to(away) < 20.0:
				var tw: Tween = create_tween()
				tw.tween_property(self, "modulate:a", 0.0, 0.6)
				tw.tween_callback(queue_free)
				state = 3
	if spr != null:
		if state == 0 or state == 2:
			spr.frame = row * 8 + int(dist / STRIDE) % 4
		else:
			spr.frame = row * 8


## Шаг к точке; true — дошла
func _go(p: Vector2, delta: float) -> bool:
	var to: Vector2 = p - position
	var d: float = to.length()
	if d < 2.0:
		return true
	var step: float = minf(d, SPEED * delta)
	position += to / d * step
	dist += step
	row = _row_for(to)
	return false

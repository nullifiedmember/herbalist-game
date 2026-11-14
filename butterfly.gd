extends Node2D
## Бабочка порхает днём вокруг своей точки.

var home: Vector2
var seed_f: float = 0.0
var t: float = 0.0
var spr: Sprite2D


func _ready() -> void:
	home = position
	seed_f = randf() * 100.0
	spr = Sprite2D.new()
	spr.texture = load("res://art/fx_butterfly.png")
	spr.hframes = 2
	add_child(spr)
	z_index = 5


func _process(delta: float) -> void:
	t += delta
	var k: float = t + seed_f
	position = home + Vector2(sin(k * 0.6) * 46.0 + sin(k * 1.7) * 12.0, cos(k * 0.45) * 28.0 + sin(k * 2.6) * 6.0)
	spr.frame = int(k * 9.0) % 2
	spr.position.y = -14.0 + sin(k * 4.0) * 2.0
	spr.flip_h = cos(k * 0.6) < 0.0
	var h: float = Game.hour()
	visible = h > 7.0 and h < 19.0

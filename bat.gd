extends Node2D
## Летучая мышь: кружит восьмёркой над замком или кладбищем, машет крыльями.
## night_only — днём прячется (прозрачная), появляется в сумерки.

var spr: Sprite2D
var center: Vector2 = Vector2.ZERO
var radius: float = 80.0
var speed: float = 1.0
var phase: float = 0.0
var night_only: bool = false
var t: float = 0.0


func setup(at: Vector2, r: float, night: bool) -> void:
	center = at
	radius = r
	night_only = night
	phase = randf() * TAU
	speed = randf_range(0.6, 1.2) * (1.0 if randf() < 0.5 else -1.0)
	spr = Sprite2D.new()
	spr.texture = load("res://art/bat.png")
	spr.hframes = 4
	add_child(spr)
	z_index = 20


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	t += delta
	var a: float = phase + t * speed
	position = center + Vector2(cos(a) * radius, sin(a * 2.0) * radius * 0.35 - 40.0 + sin(t * 3.1) * 6.0)
	spr.frame = int(t * 12.0 + phase * 3.0) % 4
	spr.flip_h = -sin(a) * speed > 0.0
	if night_only:
		var n: float = Game.night_factor()
		var h: float = Game.hour()
		var dusk: float = 1.0 if (h > 18.5 or h < 6.0) else 0.0
		modulate.a = move_toward(modulate.a, maxf(n, dusk), delta)

extends Node2D
## Добрый пушистый паучок: семенит по лесу короткими перебежками, иногда замирает и моргает.
## E — погладить: подпрыгивает от радости, сердечко.

var interact_offset: Vector2 = Vector2(0, -10)
var spr: Sprite2D
var home: Vector2 = Vector2.ZERO
var blocked: Callable
var goal: Vector2 = Vector2.ZERO
var moving: bool = false
var wait_t: float = 1.0
var t: float = 0.0
var dist: float = 0.0
var hop_t: float = 0.0
var blink_t: float = 2.0
var speed: float = 34.0


func setup(tex: String, at: Vector2) -> void:
	home = at
	position = at
	spr = Sprite2D.new()
	spr.texture = load("res://art/%s.png" % tex)
	spr.hframes = 6
	spr.centered = false
	spr.offset = Vector2(-spr.texture.get_width() / 12.0, -spr.texture.get_height() + 2.0)
	add_child(spr)
	wait_t = randf_range(0.2, 3.0)
	speed = randf_range(28.0, 42.0)


func _ready() -> void:
	add_to_group("interactables")
	add_to_group("spiders")


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	t += delta
	if moving:
		var to: Vector2 = goal - position
		var step: float = speed * delta
		if to.length() <= step:
			position = goal
			moving = false
			wait_t = randf_range(0.6, 3.5)
		else:
			var np: Vector2 = position + to.normalized() * step
			if blocked.is_valid() and bool(blocked.call(np)):
				moving = false
				wait_t = 0.4
			else:
				position = np
				dist += step
				spr.flip_h = to.x > 0.0
	else:
		wait_t -= delta
		if wait_t <= 0.0:
			var a: float = randf() * TAU
			goal = home + Vector2(cos(a), sin(a) * 0.7) * randf_range(10.0, 110.0)
			moving = true
	# кадр: шаг по пройденному пути, стоя — моргает
	blink_t -= delta
	if blink_t <= 0.0:
		blink_t = randf_range(1.8, 4.0)
	if moving:
		spr.frame = int(dist / 5.0) % 4
	else:
		spr.frame = 5 if blink_t < 0.14 else 4
	# прыжок радости
	if hop_t > 0.0:
		hop_t -= delta
		spr.position.y = -absf(sin(hop_t * 9.0)) * 6.0
	else:
		spr.position.y = 0.0


func get_prompt() -> String:
	return "Погладить"


func interact() -> void:
	moving = false
	wait_t = 1.5
	hop_t = 1.05
	Game.fx.emit(global_position + Vector2(0, -30), "heart")
	get_tree().call_group("player", "react", "happy", 1.4)

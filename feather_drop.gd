extends Node2D
## Перо, обронённое вспугнутой птицей (v20). Лежит до следующего дня; E — подобрать.

var bid: String = ""
var day0: int = 0
var interact_offset: Vector2 = Vector2(0, -2)
var spr: Sprite2D
var t: float = 0.0


func setup(id: String) -> void:
	bid = id
	day0 = Game.day
	spr = Sprite2D.new()
	spr.texture = load("res://art/icon_feather_%s.png" % id)
	spr.scale = Vector2(0.4, 0.4)
	spr.rotation = randf_range(-0.6, 0.6)
	add_child(spr)
	add_to_group("interactables")
	# плавно падает
	spr.position = Vector2(0, -26)
	var tw: Tween = create_tween()
	tw.tween_property(spr, "position", Vector2(0, -3), 1.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)


func _process(delta: float) -> void:
	t += delta
	if Game.day != day0:
		queue_free()


func get_prompt() -> String:
	return "Подобрать перо"


func interact() -> void:
	Game.add_item("feather_" + bid)
	queue_free()

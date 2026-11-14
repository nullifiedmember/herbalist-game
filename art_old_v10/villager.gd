extends Node2D
## Житель деревни с заказом. Приходит утром, ждёт до вечера.
## E — поговорить (узнать, что болит) или отдать нужное зелье.

const RDB = preload("res://recipes_db.gd")

var interact_offset: Vector2 = Vector2(0, -40)
var spr: Sprite2D
var bubble: Label
var t: float = 0.0
var info: Dictionary = {}
var leaving: bool = false


func setup(v: Dictionary) -> void:
	info = v
	spr = Sprite2D.new()
	spr.texture = load(String(v["tex"]))
	spr.hframes = 2
	spr.centered = false
	spr.offset = Vector2(-40, -157)
	spr.scale = Vector2(0.5, 0.5)
	add_child(spr)
	bubble = Label.new()
	bubble.text = "!"
	bubble.add_theme_font_size_override("font_size", 18)
	bubble.add_theme_color_override("font_color", Color("fff4c8"))
	bubble.add_theme_color_override("font_outline_color", Color("3a2718"))
	bubble.add_theme_constant_override("outline_size", 6)
	bubble.position = Vector2(-4, -82)
	add_child(bubble)


func _ready() -> void:
	add_to_group("interactables")
	add_to_group("villagers")


func _process(delta: float) -> void:
	t += delta
	if spr != null:
		spr.frame = int(t / 0.8) % 2
	if bubble != null:
		bubble.position.y = -82.0 - absf(sin(t * 3.0)) * 3.0
		bubble.visible = not leaving


func _wanted() -> String:
	return String(Game.order.get("product", ""))


func get_prompt() -> String:
	if leaving:
		return ""
	if Game.get_count(_wanted()) > 0:
		return "Отдать: " + RDB.name(_wanted())
	return "Поговорить"


func interact() -> void:
	if leaving:
		return
	var hud: Node = get_tree().get_first_node_in_group("hud")
	var p: String = _wanted()
	if Game.get_count(p) > 0:
		Game.take_item(p)
		var reward: int = int(Game.order.get("reward", 10))
		Game.orders_done += 1
		Game.order = {}
		if hud != null:
			hud.call("say", String(info["name"]), "Спасибо тебе, травница! Вот, возьми за труды.")
		Game.add_coins(reward)
		for i in range(3):
			Game.fx.emit(global_position + Vector2(randf_range(-8, 8), -50 - i * 6), "heart")
		leave()
	else:
		Game.order["met"] = true
		if hud != null:
			hud.call("say", String(info["name"]), String(RDB.ASKS.get(p, "")))


func leave() -> void:
	leaving = true
	remove_from_group("interactables")
	var tw: Tween = create_tween()
	tw.tween_interval(2.5)
	tw.tween_property(self, "modulate:a", 0.0, 1.2)
	tw.tween_callback(queue_free)

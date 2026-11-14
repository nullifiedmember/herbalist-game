extends Node2D
## v23: выброшенная вещь на земле. Лежит, чуть поблёскивает; E — поднять обратно.

const IT = preload("res://items_db.gd")

var id: String = ""
var n: int = 1
var interact_offset: Vector2 = Vector2(0, -2)
var spr: Sprite2D
var t: float = 0.0


func setup(item: String, count: int, at: Vector2) -> void:
	id = item
	n = count
	position = at
	spr = Sprite2D.new()
	spr.texture = IT.icon(id)
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var big: float = maxf(spr.texture.get_width(), spr.texture.get_height())
	spr.scale = Vector2.ONE * clampf(14.0 / big, 0.25, 0.7)
	spr.offset = Vector2(0, -spr.texture.get_height() * 0.5)
	add_child(spr)
	t = randf() * 6.0


func _ready() -> void:
	add_to_group("interactables")
	add_to_group("ground_items")


func get_prompt() -> String:
	return ""


func interact() -> void:
	Game.add_item(id, n)
	for i in range(Game.ground.size()):
		var g: Array = Game.ground[i]
		if String(g[0]) == id and Vector2(float(g[2]), float(g[3])).distance_to(position) < 1.0:
			Game.ground.remove_at(i)
			break
	Sound.play("pickup", -6.0)
	queue_free()


func _process(delta: float) -> void:
	t += delta
	spr.position.y = -1.0 - absf(sin(t * 2.0)) * 1.5
	spr.modulate = Color(1, 1, 1).lerp(Color(1.3, 1.25, 1.0), 0.5 + 0.5 * sin(t * 3.0))

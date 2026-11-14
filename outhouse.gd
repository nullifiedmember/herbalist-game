extends Node2D
## Деревенский сортир. E — зайти, если приспичило. Без подсказок.

var interact_offset: Vector2 = Vector2(0, 2)
var sprite: Sprite2D


func _ready() -> void:
	add_to_group("interactables")
	add_to_group("outhouses")


func get_prompt() -> String:
	return ""


func interact() -> void:
	var m: Node = get_tree().current_scene
	if m != null and m.has_method("use_outhouse"):
		m.call("use_outhouse", self)

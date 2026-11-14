extends Node2D
## Дверь домика: E — войти. Без подсказок (ещё входят, просто подойдя к двери вплотную).

var interact_offset: Vector2 = Vector2.ZERO


func _ready() -> void:
	add_to_group("interactables")
	add_to_group("doors")


func get_prompt() -> String:
	return ""


func interact() -> void:
	var m: Node = get_tree().current_scene
	if m != null and m.has_method("enter_house"):
		m.call("enter_house")

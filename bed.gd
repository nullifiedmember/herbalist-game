extends Node2D
## Кровать: E — лечь спать до утра. Без подсказок.

var interact_offset: Vector2 = Vector2(0, -6)


func _ready() -> void:
	add_to_group("interactables")
	add_to_group("beds")


func get_prompt() -> String:
	return ""


func interact() -> void:
	Game.sleep_requested.emit()

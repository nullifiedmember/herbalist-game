extends Node2D
## Лестница клуба «Старлит»: вниз с улицы или вверх обратно.

var kind: String = "down"
var club: Node = null
var interact_offset: Vector2 = Vector2(0, -6)


func _ready() -> void:
	add_to_group("interactables")


func get_prompt() -> String:
	return "Спуститься в клуб" if kind == "down" else "Подняться на улицу"


func interact() -> void:
	if club == null:
		return
	if kind == "down":
		club.call("enter")
	else:
		club.call("leave")

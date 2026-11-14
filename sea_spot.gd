extends Node2D
## Водолазный колокол на пирсе (спуститься под воду) или столб пузырей на дне (подняться).

var kind: String = "down"
var sea: Node = null
var interact_offset: Vector2 = Vector2(0, -30)


func _ready() -> void:
	add_to_group("interactables")


func get_prompt() -> String:
	return "Спуститься под воду" if kind == "down" else "Подняться на пирс"


func interact() -> void:
	if sea == null:
		return
	if kind == "down":
		sea.call("dive")
	else:
		sea.call("surface")

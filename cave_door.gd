extends Node2D
## Вход в пещеру (снаружи) или лестница наверх (в шахте). E — спуститься / подняться.

var up: bool = false
var interact_offset: Vector2 = Vector2(0, -20)


func _ready() -> void:
	add_to_group("interactables")
	add_to_group("cave_doors")


func get_prompt() -> String:
	return "Подняться наверх" if up else "Войти в пещеру"


func interact() -> void:
	var m: Node = get_tree().get_first_node_in_group("mine18")
	if m == null:
		return
	if up:
		m.call("leave")
	else:
		m.call("enter", global_position)

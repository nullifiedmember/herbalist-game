extends Node2D
## Котёл во дворе. E — открыть сцену варки.

var interact_offset: Vector2 = Vector2(0, -30)


func _ready() -> void:
	add_to_group("interactables")


func get_prompt() -> String:
	return "Варить зелье"


func interact() -> void:
	var b: Node = get_tree().get_first_node_in_group("brew_ui")
	if b != null:
		b.call("open")

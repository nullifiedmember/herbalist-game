extends Node2D
## v23: вещь подземелья — вход снаружи, лестница наверх, сундук, портал в ад. E — использовать.

var kind: String = ""          # entry / stairs / chest / portal
var key: String = ""           # какое подземелье (для входа)
var theme: String = "cave"
var index: int = 0             # номер сундука
var interact_offset: Vector2 = Vector2(0, -10)
var spr: Sprite2D


func _ready() -> void:
	add_to_group("interactables")
	add_to_group("dun_things")


func get_prompt() -> String:
	return ""


func interact() -> void:
	var d: Node = get_tree().get_first_node_in_group("dungeon23")
	if d != null:
		d.call("use_thing", self)


## Факелы подземелья светят сквозь темноту (darkness.gd ищет группу campfires)
func light_radius() -> float:
	return 0.0

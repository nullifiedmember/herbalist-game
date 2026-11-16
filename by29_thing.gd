extends Node2D
## v29: вещь заднего двора (грядка, лунка деревца, бочка, калитки, колодец для лейки).
## Подсказку и действие даёт backyard29.gd.

var kind: String = ""
var idx: int = 0
var mgr: Node = null
var interact_offset: Vector2 = Vector2(0, -6)


func _ready() -> void:
	add_to_group("interactables")


func get_prompt() -> String:
	return String(mgr.call("prompt", self)) if mgr != null else ""


func interact() -> void:
	if mgr != null:
		mgr.call("use", self, false)

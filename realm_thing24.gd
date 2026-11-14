extends Node2D
## v24: предмет в мирах Ада и Рая, с которым можно что-то сделать по E (фонтан, облако-батут, портал назад).

var kind: String = ""
var mgr: Node = null
var interact_offset: Vector2 = Vector2(0, -12)


func _ready() -> void:
	add_to_group("interactables")


func get_prompt() -> String:
	return {"portal_back": "Шагнуть в портал", "fountain_heaven": "Бросить монетку", "fountain_hell": "Глотнуть из фонтана", "cloud": "Попрыгать на облаке"}.get(kind, "")


func interact() -> void:
	if mgr != null:
		mgr.call("use_thing", self)

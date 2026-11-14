extends Node2D
## Скупка рыбы у вывески: появляется подсказка, только когда в сумке есть рыба.

const FDB = preload("res://fish_db.gd")

var interact_offset: Vector2 = Vector2(0, -6)


func _ready() -> void:
	add_to_group("interactables")
	add_to_group("fish_buyers")


func _process(_delta: float) -> void:
	visible = total_value() > 0


func total_count() -> int:
	var n: int = 0
	for id in FDB.ORDER:
		n += Game.get_count(String(id))
	return n


func total_value() -> int:
	var v: int = 0
	for id in FDB.ORDER:
		v += Game.get_count(String(id)) * int(FDB.DATA[id]["price"])
	return v


func get_prompt() -> String:
	return ""


## Продаёт всю рыбу из сумки, возвращает выручку
func interact() -> int:
	var v: int = total_value()
	if v <= 0:
		return 0
	for id in FDB.ORDER:
		var c: int = Game.get_count(String(id))
		if c > 0:
			Game.take_item(String(id), c)
	Game.add_coins(v)
	return v

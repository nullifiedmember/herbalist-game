extends Node2D
## Бочки с элем у таверны дворфов. E — выпить кружку: героиня довольна,
## выпитое считается как питьё (по-маленькому захочется быстрее).

var interact_offset: Vector2 = Vector2(0, -26)
var cd: float = 0.0


func _ready() -> void:
	add_to_group("interactables")


func _process(delta: float) -> void:
	cd = maxf(0.0, cd - delta)


func get_prompt() -> String:
	return "" if cd > 0.0 else "Выпить эля"


func interact() -> void:
	if cd > 0.0:
		return
	cd = 4.0
	Game.drink(0.8)
	get_tree().call_group("player", "react", "happy", 2.0)
	Game.fx.emit(global_position + Vector2(0, -40), "heart")

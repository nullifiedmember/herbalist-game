extends Node2D
## Место на берегу пруда, откуда можно закинуть удочку. Ничего не рисует и ничего не подсказывает:
## без удочки из шкафа E здесь не делает ничего.

var interact_offset: Vector2 = Vector2.ZERO
var shore: Vector2 = Vector2.ZERO    # где стоит героиня (мировые координаты)
var sea: bool = false                # v23: морское место (пирс) — морские рыбы и акулы


func _ready() -> void:
	add_to_group("interactables")
	add_to_group("fishing_spots")


func get_prompt() -> String:
	return ""


func interact() -> void:
	if not Game.rod_ok():
		return
	var ui: Node = get_tree().get_first_node_in_group("fishing_ui")
	if ui != null:
		ui.call("open", self)

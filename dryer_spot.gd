extends Node2D
## Сушилка во дворе (v19): E — открыть окно сушки (dry_ui.gd).

var interact_offset: Vector2 = Vector2(0, -20)


func _ready() -> void:
	add_to_group("interactables")


func get_prompt() -> String:
	var ready: int = 0
	for h in Game.dryer:
		if preload("res://dry_ui.gd").dryness(float(h["t0"])) >= 1.0:
			ready += 1
	return "Сушилка (готово: %d)" % ready if ready > 0 else "Сушилка для трав"


func interact() -> void:
	var d: Node = get_tree().get_first_node_in_group("dry_ui")
	if d != null:
		d.call("open")

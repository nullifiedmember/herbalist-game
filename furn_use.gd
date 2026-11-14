extends Node2D
## v23: что делает мебель по E — кровать (сон), сундук/шкаф/комод (сундук как в PoE), книжный шкаф (книга),
## умывальник (попить), корзина (поесть), пианино (музыка), печка (согреть воду). Без подсказок.

var use: String = ""
var fid: String = ""
var interact_offset: Vector2 = Vector2(0, -4)


func _ready() -> void:
	add_to_group("interactables")
	add_to_group("furn_use")
	if use == "sleep":
		add_to_group("beds")


func get_prompt() -> String:
	return ""


func interact() -> void:
	match use:
		"sleep":
			Game.sleep_requested.emit()
		"chest":
			var cu: Node = get_tree().get_first_node_in_group("chest_ui")
			if cu != null:
				var gp: Vector2 = (self as Node2D).global_position if self is Node2D else Vector2.ZERO
				cu.call("open_chest", "f:%d,%d" % [int(gp.x), int(gp.y)], "chest_mid")
		"book":
			var bk: Node = get_tree().current_scene.get("book")
			if bk != null:
				bk.call("open")
		"water":
			if Game.consume_cd <= 0.0:
				Game.drink(0.5)
				Sound.play("water", -4.0)
				Game.fx.emit(global_position + Vector2(0, -18), "water")
		"food":
			if Game.consume_cd <= 0.0 and Game.hunger > 0.15:
				Game.eat(0.4, 0.2)
				get_tree().call_group("player", "react", "smile", 1.2)
		"music":
			Sound.play(["ui_select", "page", "magic"].pick_random(), -4.0, 0.3)
			Game.fx.emit(global_position + Vector2(0, -30), "sparkle")
			get_tree().call_group("player", "react", "happy", 1.6)
		"stove":
			# печка греет бутылочки с холодной водой, как костёр
			var n: int = Game.get_count("water_cold")
			if n > 0:
				Game.take_item("water_cold", n)
				Game.add_item("water_hot", n)
				Sound.play("fire", -6.0)
				Game.fx.emit(global_position + Vector2(0, -20), "steam")
		"light":
			Sound.play("fire", -10.0)

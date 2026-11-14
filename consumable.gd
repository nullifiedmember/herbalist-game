extends Node2D
## Место, где можно попить или поесть. E — без подсказок.
## well, sink — вода; table — чай из сумки, а если чая нет — хлеб; apples — яблоко;
## stove — просто плита (готовят на костре, см. campfire.gd).

const FDB = preload("res://fish_db.gd")
const RDB = preload("res://recipes_db.gd")
const FD = preload("res://food_db.gd")

var kind: String = "well"
var interact_offset: Vector2 = Vector2.ZERO


func _ready() -> void:
	add_to_group("interactables")
	add_to_group("consumables")


func get_prompt() -> String:
	return ""


func _first_tea() -> String:
	for id in RDB.PRODUCTS.keys():
		var s: String = String(id)
		if s.ends_with("_tea") and Game.get_count(s) > 0:
			return s
	return ""


func _first_fish() -> String:
	for id in FDB.ORDER:
		if Game.get_count(String(id)) > 0:
			return String(id)
	return ""


## Возвращает, что съела или выпила (пусто, если ничего не вышло)
func interact() -> String:
	if Game.consume_cd > 0.0:
		return ""
	var done: String = ""
	match kind:
		"well", "sink":
			# пустые бутылочки — набрать студёной воды (по 5 за раз), иначе — попить
			var nb: int = mini(5, Game.get_count("bottle")) if kind == "well" else 0
			if nb > 0:
				Game.take_item("bottle", nb)
				Game.add_item("water_cold", nb)
				Sound.play("water", -2.0)
				done = "fill"
			else:
				Game.drink(0.5)
				done = "water"
		"table":
			var tea: String = _first_tea()
			if tea != "":
				Game.take_item(tea)
				Game.drink(0.8)
				done = "tea"
			else:
				return ""      # v23: просто стол — ничего не происходит (раньше «хлеб из воздуха» с сердечками)
		"apples":
			Game.eat(0.5, 0.3)
			done = "apple"
		"stove":
			# v17: на плите дома не готовят — только на костре во дворе
			return ""
	if done != "":
		get_tree().call_group("player", "react", "smile", 1.6)
		Game.fx.emit(global_position + Vector2(0, -18), "water" if done in ["water", "tea", "fill"] else "heart")
	return done

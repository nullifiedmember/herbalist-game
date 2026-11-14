extends Node
## Приюты (v19). В каждом городе свой приют: у кошкодевочек — только кошки, в других — свои звери.
## Взять питомца у хозяйки приюта (разговор → «Хочу взять питомца»); он ходит за героиней, а увидит
## загон у дома — поселится там. Кошки — как домашний кот: всегда рядом.

const W = preload("res://wild_db.gd")

## Земля -> [[вид, цена], ...]. Вид кошки — "cat:<окрас>".
const ANIMALS: Dictionary = {
	"cats": [["cat:ginger", 30], ["cat:white", 35], ["cat:gray", 25], ["cat:calico", 40], ["cat:black", 30]],
	"knights": [["rabbit", 18], ["duck", 14], ["deer", 60]],
	"elves": [["deer", 55], ["rabbit", 16], ["squirrel", 20], ["golden_deer", 260]],
	"mages": [["sapphire_hare", 220], ["rabbit", 16], ["hedgehog", 18]],
	"orcs": [["boar", 40], ["flat_boar", 34]],
	"goblins": [["flat_boar", 28], ["hedgehog", 14], ["duck", 12]],
	"dwarves": [["boar", 38], ["hedgehog", 16], ["flat_boar", 30]],
	"gothic": [["fox", 45], ["ember_fox", 240], ["hedgehog", 16]],
	"spider": [["hedgehog", 15], ["squirrel", 22]],
	"japan": [["fox", 42], ["squirrel", 18], ["duck", 14]],
}
const CAT_NAMES: Dictionary = {"ginger": "Рыжий котик", "white": "Белая кошечка", "gray": "Серый котик", "calico": "Трёхцветная кошка", "black": "Чёрный котёнок"}

var main: Node2D
var pets: Array = []          # узлы питомцев


func setup(m: Node2D) -> void:
	main = m
	add_to_group("shelters18")


static func list_for(land: String) -> Array:
	return ANIMALS.get(land, ANIMALS["knights"])


static func title(kind: String) -> String:
	if kind.begins_with("cat:"):
		return String(CAT_NAMES.get(kind.substr(4), preload("res://cats26_db.gd").title(kind.substr(4))))
	return String((W.ANIMALS.get(kind, {}) as Dictionary).get("name", kind))


static func price(land: String, kind: String) -> int:
	for a in list_for(land):
		if String(a[0]) == kind:
			return int(a[1])
	return 999


## Взять питомца: платим, он появляется рядом с героиней и идёт за ней
func adopt(land: String, kind: String) -> bool:
	var pr: int = Game.rep_price(land, price(land, kind)) if Game.has_method("rep_price") else price(land, kind)
	if Game.coins < pr:
		return false
	Game.coins -= pr
	Game.inventory_changed.emit()
	Game.pets.append({"kind": kind, "land": land, "day": Game.day})
	var pl: Node2D = main.get("player") as Node2D
	spawn_pet(kind, pl.global_position + Vector2(26, 18))
	Sound.play("purr" if kind.begins_with("cat:") else "ui_select", -4.0)
	Game.toast.emit("Новый друг: " + title(kind), load("res://art/fx_heart.png"))
	return true


func spawn_pet(kind: String, at: Vector2) -> Node2D:
	var n: Node2D = Node2D.new()
	if kind.begins_with("cat:"):
		n.set_script(load("res://cat.gd"))
		n.set("skin", kind.substr(4))
		n.set("is_pet", true)
		n.set("main", main)
		n.set("blocked", Callable(main, "is_blocked"))
		n.set("keep", 56.0 + 22.0 * float(pets.size() + 1))
		n.position = at
		(main.get("objects") as Node).add_child(n)
	else:
		n.set_script(load("res://animal.gd"))
		(main.get("objects") as Node).add_child(n)
		n.call("setup", kind, at)
		var inf: Dictionary = (n.get("info") as Dictionary).duplicate()
		inf["shy"] = false
		n.set("info", inf)
		n.set("follow", true)
		n.set("roam", 0.0)
		n.add_to_group("followers")
		n.set("blocked", Callable(main, "is_blocked"))
	n.add_to_group("pets18")
	pets.append(n)
	return n


func _process(_delta: float) -> void:
	var pl: Node2D = main.get("player") as Node2D if main != null else null
	if pl == null:
		return
	var pp: Vector2 = pl.global_position
	for i in range(pets.size() - 1, -1, -1):
		var n: Node2D = pets[i]
		if not is_instance_valid(n):
			pets.remove_at(i)
			continue
		if n.get("follow") != null and not bool(n.get("follow")):
			continue    # поселился в загоне
		n.visible = pp.y < 90000.0 or pp.y > 120000.0
		if n.global_position.distance_to(pp) > 620.0:
			n.global_position = main.call("free_near", pp + Vector2(randf_range(-40, 40), randf_range(16, 40)))

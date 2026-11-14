extends Node2D
## Дворовые постройки v20, с которыми можно что-то делать (E):
## улей — соты раз в день; бочка для дождя — наполнить бутылочки; компост — травяной мусор в чернозём;
## скворечник — перья жильцов; кормушка (насыпать зерно) и купалка — птиц вокруг больше; присада — ночью садятся совы.

const IT = preload("res://items_db.gd")
const BDB = preload("res://birds_db.gd")
const WD = preload("res://world_data.gd")

var kind: String = ""
var key: String = ""
var interact_offset: Vector2 = Vector2(0, -16)
const COMPOST_IN: Array = ["plant_fiber", "straw", "twig", "sawdust", "reed", "wood_ash"]


func _ready() -> void:
	add_to_group("interactables")
	add_to_group("yard20")
	key = "%s:%d,%d" % [kind, int(position.x), int(position.y)]
	if not Game.yard20.has(key):
		Game.yard20[key] = {"day": Game.day - 1, "n": 0, "until": -1}


func _st() -> Dictionary:
	return Game.yard20[key]


## Привлекает ли эта постройка птиц прямо сейчас (для birds.gd)
func attracts() -> float:
	match kind:
		"bird_feeder":
			return 2.5 if int(_st()["until"]) >= Game.day else 0.6
		"bird_bath":
			return 1.4
		"birdhouse":
			return 1.0
		"owl_post":
			return 2.0 if Game.night_factor() > 0.5 else 0.0
	return 0.0


func get_prompt() -> String:
	var st: Dictionary = _st()
	match kind:
		"beehive":
			return "Улей: взять соты" if int(st["day"]) < Game.day else "Улей: пчёлы работают"
		"rain_barrel":
			return "Наполнить бутылочки" if _water() > 0 else "Бочка пустая — ждать дождя"
		"compost":
			if int(st["n"]) >= 4 and int(st["day"]) < Game.day:
				return "Забрать чернозём"
			return "Положить травяной мусор (%d/4)" % int(st["n"])
		"birdhouse":
			return "Скворечник: подобрать перья" if int(st["day"]) < Game.day else "Скворечник: тихо"
		"bird_feeder":
			return "Насыпать зерно в кормушку" if int(st["until"]) < Game.day else "Кормушка полна"
		"bird_bath":
			return "Купалка для птиц"
		"owl_post":
			return "Присада для сов"
	return ""


func _water() -> int:
	var st: Dictionary = _st()
	# за каждый прошедший день набирается по 3 бутылочки, всего до 6
	var days: int = Game.day - int(st["day"])
	return mini(6, int(st["n"]) + days * 3)


func interact() -> void:
	var st: Dictionary = _st()
	match kind:
		"beehive":
			if int(st["day"]) >= Game.day:
				_nope()
				return
			st["day"] = Game.day
			Game.add_item("honeycomb", randi_range(1, 2))
			if randf() < 0.4:
				Game.add_item("wax")
			if randf() < 0.15:
				Game.add_item("propolis")
			if randf() < 0.04:
				Game.add_item("royal_jelly")
			Sound.play("bubble", -14.0)
		"rain_barrel":
			var w: int = _water()
			var n: int = mini(w, Game.get_count("bottle"))
			if n <= 0:
				_nope()
				return
			Game.take_item("bottle", n)
			Game.add_item("water_cold", n)
			st["n"] = w - n
			st["day"] = Game.day
			Sound.play("water", -6.0)
		"compost":
			if int(st["n"]) >= 4 and int(st["day"]) < Game.day:
				st["n"] = 0
				Game.add_item("loam", 3)
				Sound.play("dig", -6.0)
				return
			var put: bool = false
			while int(st["n"]) < 4:
				var found: String = ""
				for id in COMPOST_IN:
					if Game.get_count(String(id)) > 0:
						found = String(id)
						break
				if found == "":
					for id2 in Game.inventory.keys():
						if Game.get_count(String(id2)) > 0 and (IT.is_leaf(String(id2)) or String(id2).begins_with("bark_")):
							found = String(id2)
							break
				if found == "":
					break
				Game.take_item(found)
				st["n"] = int(st["n"]) + 1
				put = true
			if put:
				st["day"] = Game.day
				Sound.play("dig", -8.0)
			else:
				_nope()
		"birdhouse":
			if int(st["day"]) >= Game.day:
				_nope()
				return
			st["day"] = Game.day
			var biome: int = WD.biome_at(global_position)
			if Rect2(0, 0, WD.RW, WD.RH).has_point(global_position):
				biome = WD.MEADOW
			var lst: Array = BDB.for_biome(biome, false, false)
			if lst.is_empty():
				lst = [["sparrow", 1.0]]
			var bid: String = String(lst[randi() % lst.size()][0])
			Game.add_item("feather_" + bid, randi_range(1, 2))
		"bird_feeder":
			if int(st["until"]) >= Game.day:
				_nope()
				return
			for b in ["seed_mix", "grain", "food_pine_nut", "food_hazelnut"]:
				if Game.take_item(String(b)):
					st["until"] = Game.day + 2
					Sound.play("pickup", -8.0)
					return
			Game.toast.emit("Нужно зерно или семена", IT.icon("seed_mix"))
			_nope()
		_:
			pass


func _nope() -> void:
	get_tree().call_group("player", "react", "pout", 0.6)

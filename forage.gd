extends Node2D
## Место, где растут грибы. Каждый день решается, вырос ли здесь гриб (шанс вида),
## а виден он только в свои часы (лисички утром, светящиеся — ночью). E — сорвать.

const W = preload("res://wild_db.gd")

var interact_offset: Vector2 = Vector2(0, -6)
var options: Array = []          # какие грибы могут расти здесь
var key: String = ""
var today: String = ""           # что выросло сегодня ("" — ничего)
var day_seen: int = -1
var spr: Sprite2D
var glow: Sprite2D
var check_t: float = 0.0


func setup(at: Vector2, opts: Array) -> void:
	position = at
	options = opts
	key = "%d,%d" % [int(at.x), int(at.y)]
	spr = Sprite2D.new()
	spr.centered = false
	spr.offset = Vector2(-12, -22)
	add_child(spr)
	spr.visible = false


func _ready() -> void:
	add_to_group("forage")


func _roll() -> void:
	day_seen = Game.day
	today = ""
	if int(Game.picked.get(key, -1)) == Game.day:
		return
	var r: RandomNumberGenerator = RandomNumberGenerator.new()
	r.seed = hash(key + str(Game.day))
	for id in options:
		if r.randf() < float((W.SHROOMS[id] as Dictionary)["chance"]):
			today = String(id)
			spr.texture = W.shroom_icon(today)
			return


func _process(delta: float) -> void:
	check_t -= delta
	if check_t > 0.0:
		return
	check_t = 1.0
	if day_seen != Game.day:
		_roll()
	var vis: bool = today != "" and W.hour_ok(today, Game.hour())
	spr.visible = vis
	if vis and not is_in_group("interactables"):
		add_to_group("interactables")
	elif not vis and is_in_group("interactables"):
		remove_from_group("interactables")
	if vis and today in ["glow_cap", "moon_shroom", "elf_star"]:
		spr.modulate = Color(1.3, 1.3, 1.5) if Game.night_factor() > 0.5 else Color.WHITE


func get_prompt() -> String:
	return "Сорвать: " + W.shroom_name(today) if today != "" else ""


func interact() -> void:
	if today == "":
		return
	# нож грибника, корзина для грибов: шанс срезать два гриба
	Game.add_item(today, 2 if randf() * 100.0 < Game.stat("shroom") else 1)
	Game.picked[key] = Game.day
	if (W.SHROOMS[today] as Dictionary)["price"] >= 30:
		Sound.play("magic", -6.0)
	today = ""
	spr.visible = false
	remove_from_group("interactables")

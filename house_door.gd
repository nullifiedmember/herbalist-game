extends Node2D
## Дверь дома в городе. У дома есть хозяйка; днём (если она открыла дом) можно войти.
## Личный дом — хозяйка попросит уйти, не уйдёшь — выведет стража. Лавка/таверна — гостям рады.

var interact_offset: Vector2 = Vector2(0, -14)
var owner_tex: String = ""
var owner_name: String = ""
var private: bool = true
var kind: String = "home"        # home / shop / tavern / bakery / palace
var land: String = ""
var open_from: float = 8.0
var open_to: float = 20.0
var seed_k: int = 0
var knock_t: float = 0.0


func _ready() -> void:
	add_to_group("interactables")
	add_to_group("house_doors")


## Открыт ли дом сейчас: хозяйка открывает его днём, но не каждый день
func is_open() -> bool:
	if has_meta("own24"):
		return true          # v24: свои дома королевства открыты всегда
	var h: float = Game.hour()
	if h < open_from or h >= open_to:
		return false
	var r: RandomNumberGenerator = RandomNumberGenerator.new()
	r.seed = seed_k * 131 + Game.day
	if kind != "home":
		return true
	return r.randf() < (0.95 if not private else 0.7)


func _process(delta: float) -> void:
	knock_t = maxf(0.0, knock_t - delta)


func get_prompt() -> String:
	if is_open():
		if kind != "home":
			return "Войти (%s)" % {"shop": "лавка", "tavern": "таверна", "bakery": "пекарня", "palace": "дворец", "prison": "тюрьма", "shelter": "приют"}.get(kind, "лавка")
		return "Войти" if private else "Войти (лавка)"
	return "Заперто"


func interact() -> void:
	if not is_open():
		if knock_t <= 0.0:
			knock_t = 1.5
			Sound.play("door", -10.0, 0.2, global_position)
			Game.toast.emit("Заперто. %s сейчас не принимает гостей." % owner_name, load("res://art/ui_moon.png"))
		return
	var m: Node = get_tree().current_scene
	if m != null:
		m.call("visit_house", self)

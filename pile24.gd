extends Node2D
## v24: штабель стволов (как на фото со склада леса): торцы пирамидой. До 10 стволов.
## E — взять ствол (снова нести вместе с помощницами) или порубить верхний на поленья (с топором).

var rec: Dictionary = {}
var mgr: Node = null
var spr: Sprite2D
var interact_offset: Vector2 = Vector2(0, -14)


func setup(r: Dictionary, m: Node) -> void:
	rec = r
	mgr = m
	position = Vector2(float(r["x"]), float(r["y"]))
	spr = Sprite2D.new()
	spr.centered = false
	add_child(spr)
	refresh()
	add_to_group("interactables")
	add_to_group("piles24")


func refresh() -> void:
	var n: int = clampi(int(rec["n"]), 1, 10)
	var t: Texture2D = load("res://art/logpile24_%d.png" % n)
	spr.texture = t
	spr.offset = Vector2(-floorf(t.get_width() / 2.0), -t.get_height() + 2.0)


func get_prompt() -> String:
	return "Штабель брёвен ×%d" % int(rec["n"])


func interact() -> void:
	if mgr != null:
		mgr.call("on_pile_interact", self)

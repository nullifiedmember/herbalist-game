extends Node2D
## v24: врата в другой мир (в обычном мире): огненные — в Пеклоград, светлые — в Облакоград.
## Портал переливается и светится; E — шагнуть.

var realm: String = "hell"
var mgr: Node = null
var interact_offset: Vector2 = Vector2(0, -20)
var spr: Sprite2D
var t: float = 0.0


func _ready() -> void:
	add_to_group("interactables")
	spr = Sprite2D.new()
	spr.texture = load("res://art/realm_portal_%s.png" % realm)
	spr.centered = false
	spr.offset = Vector2(-32, -96)
	add_child(spr)
	var m: Node = get_tree().current_scene
	if m != null and m.has_method("add_glow"):
		m.call("add_glow", position + Vector2(0, -46), 1.3, 0.75)
	var w: Node = m.get("world") if m != null else null
	if w != null and w.has_method("add_block"):
		w.call("add_block", position + Vector2(-14, -2), 8.0)
		w.call("add_block", position + Vector2(14, -2), 8.0)


func _process(delta: float) -> void:
	t += delta
	spr.modulate = Color(1, 1, 1).lerp(Color(1.3, 1.1, 1.0) if realm == "hell" else Color(1.1, 1.2, 1.35), 0.5 + 0.5 * sin(t * 2.0))


func get_prompt() -> String:
	return "Огненные врата" if realm == "hell" else "Светлые врата"


func interact() -> void:
	if mgr != null:
		mgr.call("enter", realm, global_position + Vector2(0, 20))

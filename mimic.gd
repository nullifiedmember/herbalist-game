extends Node2D
## Сундук-мимик: выглядит как обычный сундук. Открыть (E) — он раскрывает пасть
## с зубами и языком, «кусает» героиню (она пугается), потом снова прикидывается сундуком.

var interact_offset: Vector2 = Vector2(0, -12)
var spr: Sprite2D
var open_t: float = 0.0
var t: float = 0.0


func setup(at: Vector2) -> void:
	position = at
	spr = Sprite2D.new()
	spr.texture = load("res://art/mimic.png")
	spr.hframes = 2
	spr.centered = false
	spr.offset = Vector2(-22, -38)
	add_child(spr)


func _ready() -> void:
	add_to_group("interactables")


func _process(delta: float) -> void:
	t += delta
	if open_t > 0.0:
		open_t -= delta
		spr.frame = 1
		# клацает и подпрыгивает
		spr.position = Vector2(sin(t * 50.0) * 1.0, -absf(sin(t * 14.0)) * 3.0)
	else:
		spr.frame = 0
		spr.position = Vector2.ZERO


func get_prompt() -> String:
	return "" if open_t > 0.0 else "Открыть"


func interact() -> void:
	open_t = 1.6
	Sound.play("chomp", 0.0, 0.05, global_position)
	Game.fx.emit(global_position + Vector2(0, -20), "dust")
	get_tree().call_group("player", "react", "surprised", 1.8)
	var pl: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if pl != null:
		# героиня отскакивает
		var away: Vector2 = (pl.global_position - global_position).normalized()
		pl.set("vel", away * 140.0)

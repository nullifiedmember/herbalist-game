extends Sprite2D
## v23: факел на стене подземелья — мерцает и светит сквозь темноту.

var t: float = 0.0
var r: float = 110.0


func _ready() -> void:
	add_to_group("campfires")
	t = randf() * 3.0


func light_radius() -> float:
	return r if is_visible_in_tree() else 0.0


func _process(delta: float) -> void:
	t += delta
	texture = load("res://art/dun_torch_%d.png" % (int(t * 6.0) % 2))

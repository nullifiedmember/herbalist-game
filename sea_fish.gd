extends Node2D
## v22: стайка рыбок над дном открытого моря. Плавает кругами; рядом с героиней расступается.
## Двигается только когда героиня недалеко (экономия).

var center: Vector2 = Vector2.ZERO
var radius: float = 100.0
var speed: float = 0.2
var phase: float = 0.0
var kind: int = 0
var fish: Array = []
var t: float = 0.0


func setup(c: Vector2, k: int, rad: float, seed_v: int) -> void:
	center = c
	kind = k
	radius = rad
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_v
	speed = rng.randf_range(0.12, 0.26) * (1.0 if rng.randf() < 0.5 else -1.0)
	phase = rng.randf() * TAU
	for i in range(rng.randi_range(6, 10)):
		var f: Sprite2D = Sprite2D.new()
		f.texture = load("res://art/sea_fish.png")
		f.region_enabled = true
		f.region_rect = Rect2(0, kind * 10, 16, 10)
		f.z_index = 25
		f.modulate = Color(1, 1, 1, 0.9)
		f.set_meta("off", Vector2(rng.randf_range(-26, 26), rng.randf_range(-14, 14)))
		add_child(f)
		fish.append(f)


func _process(delta: float) -> void:
	var pl: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if pl == null or pl.global_position.distance_to(center) > 1100.0:
		return
	t += delta
	phase += speed * delta
	var lead: Vector2 = center + Vector2(cos(phase) * radius, sin(phase) * radius * 0.5)
	var vel: Vector2 = Vector2(-sin(phase), cos(phase) * 0.5) * speed
	for f in fish:
		var fs: Sprite2D = f
		var off: Vector2 = fs.get_meta("off")
		var pos: Vector2 = lead + off + Vector2(sin(t * 1.3 + off.x) * 3.0, cos(t * 1.1 + off.y) * 2.0)
		# от героини в хвосте рыбки шарахаются
		var away: Vector2 = pos - pl.global_position
		if away.length() < 60.0:
			pos += away.normalized() * (60.0 - away.length()) * 0.8
		fs.global_position = pos.round()
		fs.flip_h = vel.x > 0.0
		var fr: int = int(t * 6.0 + off.x) % 2
		fs.region_rect = Rect2(fr * 16, kind * 10, 16, 10)

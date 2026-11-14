extends Node2D
## Одно насекомое. Летающие порхают вокруг своего места, иногда садятся (крылья складываются),
## у них тень на земле. Ползающие ползают, кузнечик прыгает. Улетают/уходят, когда их время кончилось.

const IDB = preload("res://insects_db.gd")

var kind: String = "bee"
var d: Dictionary
var home: Vector2 = Vector2.ZERO
var radius: float = 60.0
var target: Vector2 = Vector2.ZERO
var alt: float = 0.0
var state: String = "fly"            # fly, land, leave, walk, hop, sit
var timer: float = 0.0
var t: float = 0.0
var seed_f: float = 0.0
var spr: Sprite2D
var mgr: Node                        # менеджер насекомых (эффекты: сел на грядку, укусил и т.п.)
var follow                           # (без типа: цель может быть удалена) за кем идёт (жук — к кучке, тля — на грядке)
var hop_from: Vector2 = Vector2.ZERO
var hop_to: Vector2 = Vector2.ZERO
var hop_t: float = 0.0
var bite_cd: float = 0.0


func setup(k: String, at: Vector2, r: float, manager: Node) -> void:
	kind = k
	d = IDB.DATA[k]
	home = at
	radius = r
	mgr = manager
	position = at + Vector2(randf_range(-r, r), randf_range(-r, r) * 0.6)
	target = position
	seed_f = randf() * 100.0
	if bool(d["fly"]):
		alt = float(d["alt"]) + 20.0
		state = "fly"
	elif kind == "grasshopper":
		state = "sit"
		timer = randf_range(0.5, 2.0)
	elif kind == "aphid":
		state = "sit"
	else:
		state = "walk"


func _ready() -> void:
	add_to_group("insects")
	spr = Sprite2D.new()
	spr.texture = load("res://art/insects.png")
	spr.hframes = 4
	spr.vframes = 13
	spr.frame = int(d["row"]) * 4
	spr.offset = Vector2(0, -6)
	spr.scale = Vector2(0.5, 0.5)       # насекомые совсем маленькие рядом с героиней
	add_child(spr)
	if kind == "firefly":
		var m: CanvasItemMaterial = CanvasItemMaterial.new()
		spr.material = m


## Пора улетать или уходить
func leave() -> void:
	if state == "leave":
		return
	state = "leave"
	var a: float = randf() * TAU
	target = position + Vector2(cos(a), sin(a)) * 260.0


func _pick_target() -> void:
	if mgr != null and mgr.has_method("pick_target"):
		target = mgr.call("pick_target", self)
	else:
		target = home + Vector2(randf_range(-radius, radius), randf_range(-radius, radius) * 0.6)


func _process(delta: float) -> void:
	t += delta
	bite_cd = maxf(0.0, bite_cd - delta)
	var row: int = int(d["row"]) * 4
	if bool(d["fly"]):
		_fly(delta)
		# крылья: сидит — сложены, летит — машут (вверх, середина, вниз, середина)
		if state == "land":
			spr.frame = row
		else:
			var ph: int = int((t + seed_f) * float(d["flap"])) % 4
			spr.frame = row + [1, 2, 3, 2][ph]
		if kind == "firefly":
			var glow: float = 0.55 + 0.45 * sin(t * 2.4 + seed_f)
			spr.modulate = Color(1.0 + glow * 0.6, 1.0 + glow * 0.6, 0.7 + glow * 0.3, 1.0)
	elif kind == "grasshopper":
		_hop(delta)
	elif kind == "aphid":
		spr.frame = row + (int(t * 1.5 + seed_f) % 2)
		if follow != null and not is_instance_valid(follow):
			queue_free()
	else:
		_walk(delta)
		spr.frame = row + (int(t * 8.0) % 2)
	spr.position = Vector2(0, -alt)
	queue_redraw()


func _fly(delta: float) -> void:
	var sp: float = float(d["speed"])
	match state:
		"fly":
			var to: Vector2 = target - position
			# порхание: у бабочек и мотыльков путь волнистый, у стрекоз — рывками
			var wob: Vector2 = Vector2(sin(t * 3.1 + seed_f), cos(t * 2.3 + seed_f)) * (6.0 if kind.begins_with("butterfly") or kind == "moth" else 2.0)
			if kind == "dragonfly":
				sp *= 0.4 + 1.4 * maxf(0.0, sin(t * 2.0 + seed_f))
			if to.length() < 3.0:
				if mgr != null and bool(mgr.call("wants_land", self)):
					state = "land"
					timer = randf_range(1.5, 4.0)
					mgr.call("on_land", self)
				else:
					_pick_target()
			else:
				position += (to.normalized() * sp + wob) * delta
			if absf(to.x) > 0.5:
				spr.flip_h = to.x > 0.0
			var want_alt: float = float(d["alt"]) + sin(t * 2.0 + seed_f) * 2.5
			alt = lerpf(alt, want_alt, 1.0 - exp(-3.0 * delta))
			if kind == "mosquito" and mgr != null:
				mgr.call("mosquito_tick", self)
		"land":
			alt = lerpf(alt, 0.0, 1.0 - exp(-8.0 * delta))
			timer -= delta
			if timer <= 0.0:
				state = "fly"
				_pick_target()
		"leave":
			var to2: Vector2 = target - position
			position += to2.normalized() * sp * 1.4 * delta
			alt += 14.0 * delta
			spr.flip_h = to2.x > 0.0
			modulate.a = clampf(modulate.a - delta * 0.35, 0.0, 1.0)
			if to2.length() < 6.0 or modulate.a <= 0.01:
				queue_free()


func _walk(delta: float) -> void:
	var sp: float = float(d["speed"])
	if state == "leave":
		var to0: Vector2 = target - position
		position += to0.normalized() * sp * 2.0 * delta
		spr.flip_h = to0.x > 0.0
		modulate.a = clampf(modulate.a - delta * 0.3, 0.0, 1.0)
		if modulate.a <= 0.01:
			queue_free()
		return
	# жук ползёт к своей кучке и катает её
	if follow != null and is_instance_valid(follow) and not follow.is_queued_for_deletion():
		target = follow.global_position + Vector2(-7.0 + sin(t * 0.8) * 2.0, 2.0)
	elif follow != null:
		leave()
		return
	var to: Vector2 = target - position
	if to.length() > 1.5:
		position += to.normalized() * sp * delta
		spr.flip_h = to.x > 0.0
	elif mgr != null:
		mgr.call("on_beetle_push", self, delta)


func _hop(delta: float) -> void:
	var row: int = int(d["row"]) * 4
	if state == "leave":
		modulate.a = clampf(modulate.a - delta * 0.5, 0.0, 1.0)
		if modulate.a <= 0.01:
			queue_free()
	if state == "hop":
		hop_t += delta / 0.5
		var k: float = clampf(hop_t, 0.0, 1.0)
		position = hop_from.lerp(hop_to, k)
		alt = sin(k * PI) * 12.0
		spr.frame = row + (3 if k < 0.5 else 2)
		if k >= 1.0:
			state = "sit"
			alt = 0.0
			timer = randf_range(1.0, 3.5)
			if mgr != null:
				mgr.call("on_hop", self)
		return
	timer -= delta
	spr.frame = row + (1 if timer < 0.25 else 0)
	if timer <= 0.0 and state == "sit":
		state = "hop"
		hop_t = 0.0
		hop_from = position
		var a: float = randf() * TAU
		hop_to = home + Vector2(randf_range(-radius, radius), randf_range(-radius, radius) * 0.6)
		if hop_to.distance_to(position) > 45.0:
			hop_to = position + (hop_to - position).normalized() * 45.0
		spr.flip_h = hop_to.x > position.x
		a = a


func _draw() -> void:
	# тень на земле под летящим
	if alt > 2.0 and modulate.a > 0.1:
		var w: float = 3.0 if alt < 14.0 else 2.0
		draw_rect(Rect2(-floorf(w / 2.0), 0, w, 1), Color(0.12, 0.10, 0.18, 0.22 * modulate.a))

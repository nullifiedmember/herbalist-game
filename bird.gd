extends Node2D
## Одна птица (v20): прилетает, сидит на земле или на кроне дерева, клюёт, прыгает и поёт.
## Голос звучит ОТ НЕЁ (AudioStreamPlayer2D): слева — в левом ухе, справа — в правом, далеко — тише.
## Пугается, если подойти (бегом — издалека). С сачком в руках (E) можно поймать: перья, и птица улетает.

const BDB = preload("res://birds_db.gd")

var bid: String = "sparrow"
var sex: String = preload("res://sex27.gd").roll("bird")   # v27: пол особи
var data: Dictionary = {}
var mgr: Node = null
var spr: Sprite2D
var voice: AudioStreamPlayer2D
var atlas: AtlasTexture
var fw: float = 24.0
var fh: float = 20.0
var state: String = "idle"
var st_t: float = 0.0
var sing_t: float = 3.0
var t: float = 0.0
var perch_h: float = 0.0          # высота над землёй (на кроне дерева)
var fly_from: Vector2 = Vector2.ZERO
var fly_to: Vector2 = Vector2.ZERO
var fly_k: float = 1.0
var interact_offset: Vector2 = Vector2(0, -6)
var pl_last: Vector2 = Vector2.ZERO
var gone: bool = false


func setup(id: String, m: Node, arrive_from: Vector2, h: float) -> void:
	bid = id
	mgr = m
	data = BDB.DATA[id]
	var fr: Array = data["frame"]
	fw = float(fr[0])
	fh = float(fr[1])
	perch_h = h
	spr = Sprite2D.new()
	atlas = AtlasTexture.new()
	atlas.atlas = load("res://art/bird_%s.png" % id)
	atlas.region = Rect2(0, 0, fw, fh)
	spr.texture = atlas
	spr.centered = false
	spr.offset = Vector2(-fw / 2.0, -fh)
	spr.scale = Vector2(0.5, 0.5)
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(spr)
	voice = AudioStreamPlayer2D.new()
	voice.bus = "SFX"
	voice.stream = load("res://audio/bird_%s.wav" % id)
	voice.max_distance = 1500.0
	voice.attenuation = 0.9
	voice.panning_strength = 1.6
	add_child(voice)
	sing_t = randf_range(0.3, 4.0)
	if arrive_from != Vector2.INF:
		state = "arrive"
		fly_from = arrive_from - global_position
		fly_k = 0.0
		spr.position = fly_from
	else:
		spr.position = Vector2(0, -perch_h)
	add_to_group("birds20")


var cover: Sprite2D = null        # листва поверх птицы: она сидит В кроне, а не поверх неё


## Птица в кроне: кусок самой кроны рисуется перед её нижней половиной
func tuck_into_tree(tree: Sprite2D) -> void:
	if tree == null or tree.texture == null or spr == null:
		return
	perch_h = maxf(perch_h - 3.0, 4.0)
	if state != "arrive":
		spr.position = Vector2(0, -perch_h)
	var tex: Texture2D = tree.texture
	var sc: Vector2 = tree.scale.abs()
	var tw: float = float(tex.get_width())
	var th: float = float(tex.get_height())
	# мировой прямоугольник, который закрываем: нижние ~45% птицы + чуть ниже лапок
	var feet: Vector2 = global_position + Vector2(0, -perch_h)
	var wr: Rect2 = Rect2(feet + Vector2(-fw * 0.3, -fh * 0.5 * 0.45), Vector2(fw * 0.6, fh * 0.5 * 0.45 + 5.0))
	# в координаты текстуры дерева
	var u0: float = (wr.position.x - tree.global_position.x) / sc.x - tree.offset.x
	var v0: float = (wr.position.y - tree.global_position.y) / sc.y - tree.offset.y
	var uw: float = wr.size.x / sc.x
	var vh: float = wr.size.y / sc.y
	if tree.flip_h:
		u0 = tw - u0 - uw
	u0 = clampf(u0, 0.0, tw - 1.0)
	v0 = clampf(v0, 0.0, th - 1.0)
	uw = minf(uw, tw - u0)
	vh = minf(vh, th - v0)
	if uw < 2.0 or vh < 2.0:
		return
	var at: AtlasTexture = AtlasTexture.new()
	at.atlas = tex
	at.region = Rect2(u0, v0, uw, vh)
	cover = Sprite2D.new()
	cover.texture = at
	cover.centered = false
	cover.flip_h = tree.flip_h
	cover.scale = sc
	cover.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	cover.modulate = tree.modulate
	if tree.material != null:
		cover.material = tree.material
	# левый верх закрывающего куска в мире -> локально
	var ru: float = (tw - u0 - uw) if tree.flip_h else u0
	var wx: float = tree.global_position.x + (tree.offset.x + ru) * sc.x
	var wy: float = tree.global_position.y + (tree.offset.y + v0) * sc.y
	cover.position = Vector2(wx, wy) - global_position
	add_child(cover)


func _frame(i: int) -> void:
	atlas.region = Rect2(fw * float(i), 0, fw, fh)


func is_owl() -> bool:
	return bool(data.get("owl", false))


func _player() -> Node2D:
	return get_tree().get_first_node_in_group("player") as Node2D


## С какого расстояния улетает
func flee_dist(pl: Node2D) -> float:
	var shy: float = float(data["shy"])
	var d: float = shy * 110.0 + 30.0
	if state == "peck":
		d *= 0.5
	if bool(pl.get("running")):
		return d * 1.3
	if Game.has_tool("net"):
		d *= 0.45
	if perch_h > 0.0:
		d *= 0.6      # на дереве сидят смелее
	return d


func _process(delta: float) -> void:
	if gone:
		return
	t += delta
	st_t -= delta
	if cover != null:
		cover.visible = state != "arrive" and state != "flee"
	var pl: Node2D = _player()
	# прилёт: дуга сверху к месту посадки
	if state == "arrive":
		fly_k = minf(1.0, fly_k + delta / 1.6)
		var k: float = 1.0 - pow(1.0 - fly_k, 2.0)
		spr.position = fly_from.lerp(Vector2(0, -perch_h), k) + Vector2(0, -sin(k * PI) * 40.0)
		spr.flip_h = fly_from.x > 0.0
		_frame(6 + int(t * 12.0) % 4)
		if fly_k >= 1.0:
			state = "idle"
			st_t = randf_range(1.0, 3.0)
		return
	if state == "flee":
		fly_k += delta
		spr.position += fly_to * delta
		_frame(6 + int(t * 14.0) % 4)
		spr.modulate.a = clampf(2.2 - fly_k, 0.0, 1.0)
		if fly_k > 2.2:
			gone = true
			queue_free()
		return
	# испуг
	if pl != null:
		var d: float = pl.global_position.distance_to(global_position)
		var moved: float = pl.global_position.distance_to(pl_last)
		pl_last = pl.global_position
		if d < flee_dist(pl) and (moved > 0.2 or d < 16.0):
			fly_off(pl.global_position)
			return
		spr.flip_h = pl.global_position.x < global_position.x if d < 200.0 and state == "idle" else spr.flip_h
	# ловить можно только с сачком в руках и только тех, кто на земле
	var cc: bool = can_catch()
	if cc and not is_in_group("interactables"):
		add_to_group("interactables")
	elif not cc and is_in_group("interactables"):
		remove_from_group("interactables")
	# пение
	sing_t -= delta
	if sing_t <= 0.0:
		var night: bool = Game.night_factor() > 0.5
		sing_t = randf_range(25.0, 50.0) if is_owl() else (randf_range(15.0, 35.0) if Game.hour() < 10.0 else randf_range(25.0, 60.0))
		if not night or is_owl() or String(data["when"]) != "day":
			if not Sound.muted and randf() < 0.6:
				voice.pitch_scale = randf_range(0.95, 1.05)
				voice.volume_db = -14.0 if not is_owl() else -8.0
				voice.play()
			state = "sing"
			st_t = 1.4
	# поведение
	match state:
		"idle":
			_frame(1 if fmod(t, 3.1) < 0.12 else 0)
			if st_t <= 0.0:
				var r: float = randf()
				if perch_h > 0.0 or is_owl():
					state = "idle"
					st_t = randf_range(1.5, 4.0)
					if randf() < 0.3:
						spr.flip_h = not spr.flip_h
				elif r < 0.45:
					state = "peck"
					st_t = randf_range(0.6, 1.6)
				elif r < 0.8:
					state = "hop"
					st_t = 0.25
					fly_to = Vector2(randf_range(-10, 10), randf_range(-4, 4))
					spr.flip_h = fly_to.x < 0.0
				else:
					st_t = randf_range(1.0, 2.5)
		"peck":
			_frame(2 + int(t * 6.0) % 2)
			if st_t <= 0.0:
				state = "idle"
				st_t = randf_range(0.8, 2.0)
		"hop":
			_frame(4)
			position += fly_to * delta * 4.0
			spr.position.y = -perch_h - sin((0.25 - st_t) / 0.25 * PI) * 3.0
			if st_t <= 0.0:
				spr.position.y = -perch_h
				state = "idle"
				st_t = randf_range(0.3, 1.2)
		"sing":
			_frame(10 + int(t * 8.0) % 2)
			if st_t <= 0.0:
				state = "idle"
				st_t = randf_range(1.0, 2.0)


## Улететь от точки (и иногда обронить перо)
func fly_off(from: Vector2) -> void:
	if state == "flee":
		return
	state = "flee"
	fly_k = 0.0
	Game.birds_met[bid] = true          # v24: видела вблизи — страница в книге
	var dir: Vector2 = (global_position - from)
	if dir.length() < 1.0:
		dir = Vector2(1, 0)
	fly_to = dir.normalized() * 170.0 + Vector2(0, -90)
	spr.flip_h = fly_to.x < 0.0
	if is_in_group("interactables"):
		remove_from_group("interactables")
	if randf() < 0.22 and perch_h <= 0.0 and mgr != null:
		mgr.call("drop_feather", bid, global_position)
	Sound.play("whisk", -18.0, 0.2, global_position)


func can_catch() -> bool:
	return state != "flee" and state != "arrive" and perch_h <= 0.0 and Game.has_tool("net")


func get_prompt() -> String:
	return "Поймать сачком: %s (%s)" % [String(data["name"]).to_lower(), preload("res://sex27.gd").label(bid, sex)] if can_catch() else ""


func interact() -> void:
	if not can_catch():
		return
	var pl: Node2D = _player()
	var chance: float = clampf(1.0 - float(data["shy"]) * 0.7 + (0.15 if state == "peck" else 0.0), 0.15, 0.95)
	get_tree().call_group("player", "react", "pout", 0.3)
	Sound.play("whisk", -6.0, 0.15)
	if randf() < chance:
		var n: int = randi_range(1, 3) if not bool(data.get("magic", false)) else 1
		Game.add_item("feather_" + bid, n)
		Game.birds_seen[bid] = int(Game.birds_seen.get(bid, 0)) + 1
		Game.fx.emit(global_position + Vector2(0, -10), "heart")
		get_tree().call_group("player", "react", "happy", 1.0)
	fly_off(pl.global_position if pl != null else global_position + Vector2(-10, 0))

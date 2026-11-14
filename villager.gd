extends Node2D
## Житель деревни с заказом. Приходит утром, ждёт до вечера.
## E — поговорить (узнать, что болит) или отдать нужное зелье.

const RDB = preload("res://recipes_db.gd")

var interact_offset: Vector2 = Vector2(0, -27)
var spr: Sprite2D
var bubble: Label
var t: float = 0.0
var info: Dictionary = {}
var leaving: bool = false
# ходьба: приходит по тропе от калитки к дому и так же уходит
const WALK_SPEED: float = 45.0
const STRIDE: float = 9.0
var route: Array = []            # точки, по которым идёт (по очереди)
var walking: bool = false
var arrived: bool = true         # дошла до дома (с ней можно говорить)
var row: int = 0                 # ракурс, как у героини: 0 спереди, 1 сзади, 2 влево, 3 вправо, 4-7 по диагонали
var dist: float = 0.0
var last_walk: int = 0
var leave_wait: float = -1.0     # пауза перед уходом (пока она прощается)
# лицо: тот же атлас выражений, что у героини
const EXPR: Dictionary = {
	"neutral": 0, "blink_half": 1, "blink": 2, "smile": 3, "happy": 4, "surprised": 5,
	"look_left": 6, "look_right": 7, "sleepy": 8, "talk_a": 9, "talk_b": 10, "shy": 11,
	"sad": 12, "pout": 13, "wink": 14, "disgust": 15, "sick": 16,
}
const B_OFF: Array = [0, -1, 0, -1, 0, 0, -1, -1]   # как кадр поднимает голову
const IDLE_SEQ: Array = [4, 4, 4, 5, 5, 6, 7, 6, 5, 5, 4, 4, 4, 4]
var face: Sprite2D
var face_mat: ShaderMaterial
var expr: String = ""
var expr_t: float = 0.0
var blink_t: float = 2.0
var blink_p: float = -1.0
var blink_len: float = 0.26
var blink_twice: bool = false
var mood_t: float = 3.0
var mood: String = "neutral"
var gag_t: float = 0.0           # время отвращения (для приступов тошноты)
var sick_k: float = 0.0          # насколько позеленела (плавно)


func setup(v: Dictionary) -> void:
	info = v
	spr = Sprite2D.new()
	spr.texture = load(String(v["tex"]))
	spr.hframes = 8
	spr.vframes = 8
	spr.centered = false
	spr.offset = Vector2(-40, -157)
	spr.scale = Vector2(0.3333, 0.3333)
	add_child(spr)
	face = Sprite2D.new()
	face.texture = load(String(v["tex"]).replace("villager_", "faces_villager_"))
	face.centered = false
	face.region_enabled = true
	spr.add_child(face)
	bubble = Label.new()
	bubble.text = "!"
	bubble.add_theme_font_size_override("font_size", 18)
	bubble.add_theme_color_override("font_color", Color("fff4c8"))
	bubble.add_theme_color_override("font_outline_color", Color("3a2718"))
	bubble.add_theme_constant_override("outline_size", 6)
	bubble.position = Vector2(-3, -65)
	add_child(bubble)


func _ready() -> void:
	add_to_group("interactables")
	add_to_group("villagers")


func _process(delta: float) -> void:
	t += delta
	if leave_wait >= 0.0:
		leave_wait -= delta
		if leave_wait < 0.0:
			_start_walk([Vector2(960, 700), EXIT_POS])
	if walking:
		_walk(delta)
	if spr != null:
		if walking:
			spr.frame = row * 8 + int(dist / STRIDE) % 4
		else:
			spr.frame = row * 8 + int(IDLE_SEQ[int(t / 0.3) % IDLE_SEQ.size()])
		_update_face(delta)
	if bubble != null:
		bubble.position.y = -65.0 - absf(sin(t * 3.0)) * 2.0
		bubble.visible = not leaving and arrived


## Куда уходит и откуда приходит (за калиткой, на тропе)
const EXIT_POS: Vector2 = Vector2(960, 1250)
const HOME_POS: Vector2 = Vector2(992, 650)


## Идёт к дому по тропе
func arrive_walking() -> void:
	arrived = false
	position = EXIT_POS
	_start_walk([Vector2(960, 700), HOME_POS])


## Ракурс по направлению шага (8 сторон, как у героини)
func _facing_for(v: Vector2) -> int:
	var ax: float = absf(v.x)
	var ay: float = absf(v.y)
	if ax < ay * 0.4:
		return 0 if v.y > 0.0 else 1
	if ay < ax * 0.4:
		return 2 if v.x < 0.0 else 3
	if v.y > 0.0:
		return 4 if v.x < 0.0 else 6
	return 5 if v.x < 0.0 else 7


func _start_walk(points: Array) -> void:
	route = points.duplicate()
	walking = true
	dist = 0.0


func _walk(delta: float) -> void:
	var left: float = WALK_SPEED * delta
	while left > 0.0 and not route.is_empty():
		var to: Vector2 = (route[0] as Vector2) - position
		var d: float = to.length()
		if d <= left:
			position = route[0]
			route.pop_front()
			dist += d
			left -= d
		else:
			position += to / d * left
			dist += left
			left = 0.0
		if d > 0.5:
			row = _facing_for(to)
	if route.is_empty():
		walking = false
		if leaving:
			queue_free()
		else:
			arrived = true
			row = 0


func react(kind: String, dur: float) -> void:
	expr = kind
	expr_t = dur


## Лицо: ждёт с бедой (то грустит, то оглядывается), смотрит на героиню рядом, моргает
func _update_face(delta: float) -> void:
	if face == null:
		return
	var name: String = mood
	mood_t -= delta
	if mood_t <= 0.0:
		mood_t = randf_range(2.5, 5.0)
		mood = ["neutral", "sad", "neutral", "look_left", "look_right", "sleepy" if String(Game.order.get("product", "")) == "sleep_tea" else "sad"].pick_random()
	var pl: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if pl != null and pl.global_position.distance_to(global_position) < 70.0 and not leaving:
		var dx: float = pl.global_position.x - global_position.x
		name = "look_left" if dx < -12.0 else ("look_right" if dx > 12.0 else "neutral")
	if leaving:
		name = "smile"
	if expr_t > 0.0:
		expr_t -= delta
		name = expr
		if expr == "talk":
			name = ["talk_a", "neutral", "talk_b", "talk_a"][int(expr_t / 0.13) % 4]
	# отвращение: рядом героиня, которая не успела в туалет, или её лужа/кучка — лицо перекашивает, тошнит
	var disg: bool = _disgusted()
	if disg:
		gag_t += delta
		var ph2: float = fmod(gag_t, 2.4)
		# 0-1.4 с брезгливая гримаса, 1.4-2.4 приступ: рот «о», зажмуренные глаза, дрожь
		if ph2 < 1.4:
			name = "disgust"
		else:
			name = "sick" if int(ph2 / 0.14) % 2 == 0 else "disgust"
		blink_p = -1.0
		blink_t = 1.0
	else:
		gag_t = 0.0
	sick_k = move_toward(sick_k, 1.0 if disg else 0.0, delta * 1.5)
	var retch: bool = disg and fmod(gag_t, 2.4) >= 1.4
	spr.position = Vector2(sin(t * 60.0) * 0.6, 0.4) if retch else (Vector2(0, 0.3) if disg else Vector2.ZERO)
	for m in [spr.material, face_mat]:
		if m is ShaderMaterial:
			(m as ShaderMaterial).set_shader_parameter("sick", sick_k)
	# моргание: каждые 1.5-3.5 с, глаза закрыты ~0.25 с, иногда двойное, сонная моргает медленно
	blink_t -= delta
	if blink_t <= 0.0:
		blink_t = randf_range(1.5, 3.5)
		blink_p = 0.0
		blink_len = 0.42 if name == "sleepy" else 0.26
		blink_twice = randf() < 0.25
	if blink_p >= 0.0:
		blink_p += delta
		var ph: float = blink_p / blink_len
		if not (name in ["happy", "blink", "wink"]):
			if ph < 0.25 or (ph >= 0.75 and ph < 1.0):
				name = "blink_half"
			elif ph < 0.75:
				name = "blink"
		if ph >= 1.0:
			if blink_twice:
				blink_twice = false
				blink_p = -0.08
				blink_t = 0.08
			else:
				blink_p = -1.0
	var idx: int = int(EXPR.get(name, 0))
	var region: Rect2
	var bx: float
	var flip: bool = row in [3, 6]
	if row == 0:
		region = Rect2(0, idx * 15, 20, 15)
		bx = 30.0
	elif row == 4 or row == 6:
		region = Rect2(31, idx * 15, 20, 15)
		bx = 29.0 if row == 4 else 31.0
	else:
		region = Rect2(20, idx * 15, 11, 15)
		bx = 29.0 if row == 2 else 40.0
	var by: float = 18.0 + float(B_OFF[spr.frame % 8])
	face.visible = not (row in [1, 5, 7])
	face.flip_h = flip
	face.region_rect = region
	face.position = Vector2(-40.0 + bx, -157.0 + by)
	if face_mat != null:
		var asz: Vector2 = Vector2(face.texture.get_width(), face.texture.get_height())
		face_mat.set_shader_parameter("reg_uv_pos", region.position / asz)
		face_mat.set_shader_parameter("reg_uv_size", region.size / asz)
		face_mat.set_shader_parameter("reg_body_px", Vector2(bx, by))
		face_mat.set_shader_parameter("reg_px_size", region.size)
		face_mat.set_shader_parameter("reg_flip", flip)


## Отвращение: героиня со стыдом (не успела в туалет) близко или рядом лужа/кучка
func _disgusted() -> bool:
	var pl: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if pl != null and Game.shame > 0.25 and pl.global_position.distance_to(global_position) < 160.0:
		return true
	for m in get_tree().get_nodes_in_group("messes"):
		if is_instance_valid(m) and not (m as Node).is_queued_for_deletion() and (m as Node2D).global_position.distance_to(global_position) < 110.0:
			return true
	return false


func _wanted() -> String:
	return String(Game.order.get("product", ""))


func get_prompt() -> String:
	if leaving or not arrived:
		return ""
	if Game.get_count(_wanted()) > 0:
		return "Отдать: " + RDB.name(_wanted())
	return "Поговорить"


func interact() -> void:
	if leaving or not arrived:
		return
	var hud: Node = get_tree().get_first_node_in_group("hud")
	var p: String = _wanted()
	if Game.get_count(p) > 0:
		Game.take_item(p)
		var reward: int = int(Game.order.get("reward", 10))
		Game.orders_done += 1
		Game.order = {}
		if hud != null:
			hud.call("say", String(info["name"]), "Спасибо тебе, травница! Вот, возьми за труды.")
		Game.add_coins(reward)
		get_tree().call_group("player", "react", "shy", 2.0)
		react("happy", 2.5)
		for i in range(3):
			Game.fx.emit(global_position + Vector2(randf_range(-8, 8), -50 - i * 6), "heart")
		leave()
	else:
		Game.order["met"] = true
		if hud != null:
			hud.call("say", String(info["name"]), String(RDB.ASKS.get(p, "")))
		get_tree().call_group("player", "react", "talk", 1.6)
		react("talk", 2.4)


func leave() -> void:
	leaving = true
	remove_from_group("interactables")
	if walking:
		# ещё не дошла — разворачивается и идёт обратно
		_start_walk([EXIT_POS])
	else:
		leave_wait = 1.2   # сначала прощается, потом уходит по тропе

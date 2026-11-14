extends Node2D
## Кошкодевочка из деревни: гуляет у своего дома и по площади, отдыхает, оглядывается.
## Подойти и нажать E — она радуется, мурлычет (сердечки), ушки и хвост уже нарисованы в листе.

var interact_offset: Vector2 = Vector2(0, -27)
var spr: Sprite2D
var face: Sprite2D
var face_mat: ShaderMaterial
var tex_name: String = ""
var prompt: String = "Поговорить"
var npc_name: String = ""
var job: String = ""                 # занятие (см. JOBS): печёт, куёт, рубит дрова, болтает...
var job_at: Vector2 = Vector2.INF    # где стоит рабочее место (печь, наковальня, грядка)
var job_home: Vector2 = Vector2.INF  # где стоит сама работница
var break_t: float = 0.0             # через сколько секунд передохнуть и прогуляться
var on_break: float = 0.0
var meow_t: float = 0.0
var asked: Dictionary = {}           # сколько раз сегодня спрашивали одно и то же
var bed_h: float = 22.0              # когда уходит спать и когда просыпается (у каждой чуть по-своему)
var wake_h: float = 6.0
var home_door: Vector2 = Vector2.INF
var going_home: bool = false
var sleeping: bool = false
var met_day: int = -1
var patrol: Array = []               # дозор стражи: ходит между точками
var patrol_i: int = 0
var job_t: float = 0.0
var role: String = "житель"          # житель / торговец / лидер / кузнец / пекарь / стража...
var land: String = ""
const NPC = preload("res://npc_db.gd")
var home: Vector2 = Vector2.ZERO
var roam: float = 150.0
var blocked: Callable
var t: float = 0.0
var row: int = 0
var dist: float = 0.0
var route: Array = []
var walking: bool = false
var wait_t: float = 2.0
var happy_t: float = 0.0
var follower: bool = false           # v17: идёт за героиней (вербовка)
var ctrl: bool = false               # v24: работницей управляет workers24.gd (сама не гуляет)
var spd_k: float = 1.0               # v24: множитель скорости шага
var anim_job: String = ""            # v24: что изображает на месте (chop, dig, carry...)
var on_interact: Callable            # v24: свой разговор вместо обычного окна
var follow_slot: int = 0
var follow_react_t: float = 0.0
const SPEED: float = 30.0
const STRIDE: float = 9.0
const B_OFF: Array = [0, -1, 0, -1, 0, 0, -1, -1]
const IDLE_SEQ: Array = [4, 4, 4, 5, 5, 6, 7, 6, 5, 5, 4, 4, 4, 4]
const EXPR: Dictionary = {
	"neutral": 0, "blink_half": 1, "blink": 2, "smile": 3, "happy": 4, "surprised": 5,
	"look_left": 6, "look_right": 7, "sleepy": 8, "talk_a": 9, "talk_b": 10, "shy": 11,
	"sad": 12, "pout": 13, "wink": 14, "disgust": 15, "sick": 16,
}
var expr: String = ""
var expr_t: float = 0.0
var mood: String = "smile"
var mood_t: float = 2.0
var blink_t: float = 2.0
var blink_p: float = -1.0


func setup(name: String, at: Vector2) -> void:
	tex_name = name
	land = NPC.land_of(name)
	npc_name = String(NPC.person(name)[0])
	if name in ["spidergirl", "vampire_lilith", "catgirl_queen", "knight_queen", "elf_queen", "archmage", "orc_chief", "goblin_boss", "dwarf_queen"]:
		role = "лидер"
	home = at
	position = at
	spr = Sprite2D.new()
	spr.texture = load("res://art/%s.png" % name)
	spr.hframes = 8
	spr.vframes = 8
	spr.centered = false
	spr.offset = Vector2(-40, -157)
	spr.scale = Vector2(0.3333, 0.3333)
	add_child(spr)
	face = Sprite2D.new()
	face.texture = load("res://art/faces_%s.png" % name)
	face.centered = false
	face.region_enabled = true
	spr.add_child(face)
	t = randf() * 10.0
	wait_t = randf_range(0.5, 4.0)
	break_t = randf_range(40.0, 110.0)
	bed_h = randf_range(21.0, 23.0)
	wake_h = randf_range(5.5, 7.5)
	meow_t = randf_range(4.0, 20.0)
	row = [0, 2, 3, 4, 6][randi() % 5]


func _ready() -> void:
	add_to_group("interactables")
	add_to_group("catgirls")


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	t += delta
	var dlg: Node = get_tree().get_first_node_in_group("dialog_ui")
	if dlg != null and dlg.get("npc") == self:
		walking = false
		happy_t = 0.5
	if follower:
		_follow(delta, dlg != null and dlg.get("npc") == self)
		return
	if ctrl:
		_ctrl_tick(delta)
		return
	if _night(delta):
		return
	_meow(delta)
	if job != "" and job != "chat" and job != "post":
		if job_home == Vector2.INF:
			job_home = position
		# иногда отходит передохнуть, потом возвращается к работе
		break_t -= delta
		if break_t <= 0.0 and on_break <= 0.0 and not walking:
			on_break = randf_range(10.0, 22.0)
			break_t = randf_range(50.0, 120.0)
			_pick_walk()
		if on_break > 0.0:
			on_break -= delta
			if on_break <= 0.0:
				route = [job_home]
				walking = true
	if happy_t > 0.0:
		happy_t -= delta
	elif walking:
		_walk(delta)
	elif not patrol.is_empty():
		patrol_i = (patrol_i + 1) % patrol.size()
		route = [patrol[patrol_i]]
		walking = true
	elif job == "post":
		row = 0
	elif job != "" and on_break <= 0.0:
		if job_home != Vector2.INF and position.distance_to(job_home) > 4.0 and job != "farm":
			route = [job_home]
			walking = true
		else:
			_do_job(delta)
	elif job != "":
		wait_t -= delta
		if wait_t <= 0.0:
			_pick_walk()
	else:
		wait_t -= delta
		if wait_t <= 0.0:
			_pick_walk()
	if walking:
		spr.frame = row * 8 + int(dist / STRIDE) % 4
	else:
		spr.frame = row * 8 + int(IDLE_SEQ[int(t / 0.3) % IDLE_SEQ.size()])
	_update_face(delta)


## Новая прогулка: точка рядом с домом, куда можно дойти по прямой
## Работа: кузнец бьёт молотом (искры и звон), соседки болтают
# занятие: [пауза от, до, звук, эффект, сдвиг эффекта от места работы, лица]
const JOBS: Dictionary = {
	"smith": [1.0, 1.2, "anvil", "sparks", Vector2(0, -30), ["pout", "neutral"]],
	"smith2": [1.4, 2.2, "sword", "sparks", Vector2(0, -26), ["pout", "smile"]],
	"bake": [2.5, 4.5, "bake", "steam", Vector2(0, -60), ["happy", "smile", "wink"]],
	"farm": [1.2, 2.0, "scythe", "chaff", Vector2(0, -10), ["smile", "neutral", "happy"]],
	"dessert": [1.6, 3.0, "whisk", "cream", Vector2(0, -36), ["happy", "smile", "wink"]],
	"knit": [2.0, 3.5, "knit", "", Vector2.ZERO, ["smile", "sleepy", "happy"]],
	"train": [0.8, 1.4, "sword", "dust", Vector2(0, -30), ["pout", "surprised"]],
	"sharpen": [1.0, 1.8, "grind", "sparks", Vector2(0, -24), ["pout", "neutral"]],
	"brew": [2.0, 4.0, "bubble", "steam_green", Vector2(0, -44), ["smile", "wink", "surprised"]],
	"chop": [1.1, 1.7, "chop", "chips", Vector2(0, -16), ["pout", "surprised"]],
	"garden": [2.5, 4.5, "water", "water", Vector2(0, -10), ["smile", "happy"]],
	"archer": [1.8, 2.8, "bow", "dust", Vector2(0, -40), ["neutral", "wink", "happy"]],
	"weave": [0.7, 1.3, "loom", "", Vector2.ZERO, ["neutral", "smile"]],
	"read": [3.0, 5.0, "page", "", Vector2.ZERO, ["neutral", "surprised", "smile", "sleepy"]],
	"spell": [1.6, 3.0, "magic", "sparkle", Vector2(0, -60), ["happy", "surprised", "wink"]],
	"cook": [2.0, 3.5, "fire", "steam", Vector2(0, -40), ["happy", "smile"]],
	"drum": [0.55, 0.65, "drum", "", Vector2.ZERO, ["happy", "pout"]],
	"tinker": [0.6, 1.4, "tinker", "sparks", Vector2(0, -26), ["surprised", "happy", "pout"]],
	"dig": [1.4, 2.4, "dig", "dust", Vector2(0, -12), ["surprised", "happy"]],
	"ale": [2.5, 4.0, "pour", "foam", Vector2(0, -40), ["happy", "smile"]],
	"mine": [1.0, 1.6, "pick", "dust", Vector2(0, -20), ["pout", "neutral"]],
}


func _do_job(delta: float) -> void:
	job_t -= delta
	if job_t > 0.0:
		return
	if job == "chat":
		job_t = randf_range(1.5, 3.5)
		react("talk" if randf() < 0.6 else ["smile", "happy", "surprised"].pick_random(), 1.4)
		return
	var jb: Array = JOBS.get(job, [])
	if jb.is_empty():
		return
	job_t = randf_range(float(jb[0]), float(jb[1]))
	react(String((jb[5] as Array).pick_random()), 0.5)
	# телом — «удар» или наклон к работе
	if spr != null:
		var tw: Tween = create_tween()
		tw.tween_property(spr, "position:y", 2.0, 0.08)
		tw.tween_property(spr, "position:y", 0.0, 0.14)
	var at: Vector2 = job_at if job_at != Vector2.INF else global_position + Vector2(-20, 0)
	if String(jb[3]) != "" and (String(jb[3]) != "water" or randf() < 0.5):
		Game.fx.emit(at + (jb[4] as Vector2), String(jb[3]))
	var pl: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if pl != null and pl.global_position.distance_to(global_position) < 520.0 and String(jb[2]) != "" and String(jb[3]) != "water":
		Sound.play(String(jb[2]), -13.0, 0.1, global_position)
	# фермерша ходит вдоль грядки
	if job == "farm" and job_at != Vector2.INF:
		route = [job_at + Vector2(randf_range(-46, 46), 14)]
		walking = true


## Кошкодевочки сами иногда мяукают (если героиня рядом)
func _meow(delta: float) -> void:
	if not tex_name.begins_with("catgirl"):
		return
	meow_t -= delta
	if meow_t > 0.0:
		return
	meow_t = randf_range(9.0, 26.0)
	var pl: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if pl != null and pl.global_position.distance_to(global_position) < 420.0:
		Sound.play("meow_%d" % (randi() % 4), -9.0, 0.12, global_position)
		react(["happy", "talk", "wink"].pick_random(), 0.6)


## Идёт за героиней: держится рядом сбоку, догоняет бегом, при большом отрыве — телепортируется к ней
func _follow(delta: float, talking: bool) -> void:
	var pl: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if pl == null:
		return
	var offs: Array = [Vector2(-28, 12), Vector2(28, 16), Vector2(0, 34)]
	var goal: Vector2 = pl.global_position + (offs[follow_slot % 3] as Vector2)
	var gp: Vector2 = global_position
	var d: float = gp.distance_to(goal)
	walking = false
	if talking:
		d = 0.0
	if d > 460.0:
		global_position = goal
	elif d > 20.0:
		var spd: float = clampf(34.0 + (d - 20.0) * 1.7, 34.0, 150.0)
		var dir: Vector2 = (goal - gp) / d
		var step: Vector2 = dir * minf(spd * delta, d)
		var np: Vector2 = gp + step
		if blocked.is_valid() and bool(blocked.call(np)):
			var sx: Vector2 = gp + Vector2(step.x, 0.0)
			var sy: Vector2 = gp + Vector2(0.0, step.y)
			if not bool(blocked.call(sx)) and absf(step.x) > 0.01:
				np = sx
			elif not bool(blocked.call(sy)) and absf(step.y) > 0.01:
				np = sy
			else:
				np = gp
		if np != gp:
			global_position = np
			dist += gp.distance_to(np)
			row = _facing_for(np - gp)
			walking = true
	if walking:
		spr.frame = row * 8 + int(dist / STRIDE) % 4
	else:
		if d <= 20.0 and not talking:
			row = _facing_for(pl.global_position - gp) if randf() < 0.01 else row
		spr.frame = row * 8 + int(IDLE_SEQ[int(t / 0.3) % IDLE_SEQ.size()])
	# если ей плохо (голодна, нет денег) — грустит
	follow_react_t -= delta
	if follow_react_t <= 0.0:
		follow_react_t = randf_range(8.0, 16.0)
		var rn: Node = get_tree().get_first_node_in_group("recruit")
		if rn != null:
			var i: int = int(rn.call("find", tex_name))
			if i >= 0 and float((Game.team[i] as Dictionary)["loyalty"]) < 0.4:
				react("sad", 2.0)
			elif randf() < 0.4:
				react(["smile", "happy", "wink"].pick_random(), 1.2)
	_update_face(delta)


func _pick_walk() -> void:
	for i in range(12):
		var a: float = randf() * TAU
		var goal: Vector2 = home + Vector2(cos(a), sin(a) * 0.7) * randf_range(30.0, roam)
		if _path_free(position, goal):
			route = [goal]
			walking = true
			dist = 0.0
			return
	wait_t = 1.5


func _path_free(a: Vector2, b: Vector2) -> bool:
	if not blocked.is_valid():
		return true
	var n: int = int(a.distance_to(b) / 8.0) + 1
	for i in range(1, n + 1):
		if bool(blocked.call(a.lerp(b, float(i) / float(n)))):
			return false
	return true


## v24: под управлением хозяйства — только идёт по маршруту и изображает работу
func _ctrl_tick(delta: float) -> void:
	if happy_t > 0.0:
		happy_t -= delta
	elif walking:
		_walk(delta)
	if walking:
		spr.frame = row * 8 + int(dist / STRIDE) % 4
	else:
		spr.frame = row * 8 + int(IDLE_SEQ[int(t / 0.3) % IDLE_SEQ.size()])
	_update_face(delta)


func _walk(delta: float) -> void:
	var left: float = SPEED * spd_k * delta
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
		wait_t = randf_range(2.0, 7.0)


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


func get_prompt() -> String:
	if sleeping or going_home:
		return ""
	return prompt


## Ночью все, кроме стражи, уходят домой спать (прячутся за дверью), утром выходят
func _night(delta: float) -> bool:
	if role == "стража" or land == "":
		return false
	var h: float = Game.hour()
	var bed: bool = h >= bed_h or h < wake_h
	if sleeping:
		if not bed:
			sleeping = false
			going_home = false
			spr.visible = true
			position = home_door + Vector2(0, 12)
			Sound.play("door", -16.0, 0.2, global_position)
		return true
	if not bed:
		going_home = false
		return false
	if not going_home:
		if home_door == Vector2.INF:
			var best: float = 1100.0
			for d in get_tree().get_nodes_in_group("house_doors"):
				var dd: float = (d as Node2D).global_position.distance_to(global_position)
				if dd < best:
					best = dd
					home_door = (d as Node2D).global_position
		if home_door == Vector2.INF:
			return false       # дома нет — дремлет где стоит
		going_home = true
		route = [home_door + Vector2(0, 10)]
		walking = true
		happy_t = 0.0
	if walking:
		_walk(delta)
		spr.frame = row * 8 + int(dist / STRIDE) % 4
		_update_face(delta)
	else:
		sleeping = true
		spr.visible = false
		Sound.play("door", -16.0, 0.2, global_position)
	return true


## Героиня подошла: поворачивается к ней и начинает разговор
func interact() -> void:
	if on_interact.is_valid():
		on_interact.call(self)
		return
	var pl: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	walking = false
	route.clear()
	if pl != null:
		row = _facing_for(pl.global_position - global_position)
	var dlg: Node = get_tree().get_first_node_in_group("dialog_ui")
	if dlg != null:
		dlg.call("start", self)
		get_tree().call_group("player", "react", "talk", 1.2)


func react(kind: String, dur: float) -> void:
	expr = kind
	expr_t = dur


## Погладить (кошкодевочки): жмурится от удовольствия, сердечки
func pet_me() -> void:
	var pl: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	walking = false
	route.clear()
	if pl != null:
		row = _facing_for(pl.global_position - global_position)
	happy_t = 2.2
	wait_t = 2.5
	expr = "happy"
	expr_t = 2.2
	if tex_name.begins_with("catgirl"):
		Sound.play("purr", -4.0, 0.05, global_position)
	for i in range(2):
		Game.fx.emit(global_position + Vector2(randf_range(-6, 6), -52 - i * 7), "heart")
	get_tree().call_group("player", "react", "happy", 1.6)


func _update_face(delta: float) -> void:
	var name: String = mood
	mood_t -= delta
	if mood_t <= 0.0:
		mood_t = randf_range(2.5, 6.0)
		mood = ["smile", "neutral", "look_left", "look_right", "smile", "wink", "happy"].pick_random()
	var pl: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if pl != null and pl.global_position.distance_to(global_position) < 70.0:
		var dx: float = pl.global_position.x - global_position.x
		name = "look_left" if dx < -12.0 else ("look_right" if dx > 12.0 else "smile")
	if expr_t > 0.0:
		expr_t -= delta
		name = expr
		if expr == "talk":
			name = ["talk_a", "neutral", "talk_b", "talk_a"][int(expr_t / 0.13) % 4]
	blink_t -= delta
	if blink_t <= 0.0:
		blink_t = randf_range(1.5, 3.5)
		blink_p = 0.0
	if blink_p >= 0.0:
		blink_p += delta
		var ph: float = blink_p / 0.26
		if not (name in ["happy", "blink", "wink"]):
			if ph < 0.25 or (ph >= 0.75 and ph < 1.0):
				name = "blink_half"
			elif ph < 0.75:
				name = "blink"
		if ph >= 1.0:
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

extends Node2D
## Травница. WASD/стрелки — ходить, E — действие.

signal target_changed(target: Node2D)

const SPEED: float = 78.0      # спокойный шаг
const REACH: float = 46.0
const ACCEL: float = 520.0      # разгон (пикс/с²)
const DECEL: float = 620.0      # торможение
const TURN_STEP: float = 0.07   # сколько держится промежуточный поворот
const FRAMES: int = 8           # 0-3 ходьба, 4-7 стойка с ветром и дыханием
const STRIDE: float = 12.5      # пикселей пути на один кадр шага (шаг ~0.65 с на цикл)
# стойка: спокойно, порыв ветра (накидка и волосы колышутся), вдох
const IDLE_SEQ: Array = [4, 4, 4, 5, 5, 6, 7, 6, 5, 5, 4, 4, 4, 4]

var sprite: Sprite2D
var facing: int = 0          # 0 вниз, 1 вверх, 2 влево, 3 вправо
var want_facing: int = 0
var turn_t: float = 0.0
var vel: Vector2 = Vector2.ZERO
var anim_t: float = 0.0
var idle_t: float = 0.0
var dist: float = 0.0
var stop_t: float = 0.0
var last_walk: int = 1
var target: Node2D = null
var blocked: Callable        # func(p: Vector2) -> bool

# ---- лицо: слой выражений поверх головы ----
const B_OFF: Array = [0, -1, 0, -1, 0, 0, -1, -1]   # как кадр поднимает голову
const EXPR: Dictionary = {
	"neutral": 0, "blink_half": 1, "blink": 2, "smile": 3, "happy": 4, "surprised": 5,
	"look_left": 6, "look_right": 7, "sleepy": 8, "talk_a": 9, "talk_b": 10, "shy": 11,
	"sad": 12, "pout": 13, "wink": 14,
}
const EYES_SHUT: Array = ["happy", "blink", "wink"]
var face: Sprite2D
var face_mat: ShaderMaterial
# грудь: слой поверх тела, смещение считается пружиной (инерция + затухание)
var bust: Sprite2D
var bust_mat: ShaderMaterial
var bust_d: float = 0.0
var bust_v: float = 0.0
var prev_bob: float = 0.0
var prev_speed: float = 0.0
var expr: String = ""
var expr_t: float = 0.0
var blink_t: float = 3.0
var blink_p: float = -1.0
var blink_len: float = 0.26
var blink_twice: bool = false
var look_t: float = 4.0
var idle_look: String = ""
var idle_look_t: float = 0.0
var bump_t: float = 0.0


func _ready() -> void:
	sprite = Sprite2D.new()
	sprite.texture = load("res://art/player.png")
	sprite.hframes = FRAMES
	sprite.vframes = 4
	sprite.centered = false
	# героиня нарисована вдвое мельче по пикселю (кадр 80x160), поэтому масштаб 0.5
	sprite.offset = Vector2(-40, -157)
	sprite.scale = Vector2(0.5, 0.5)
	add_child(sprite)
	bust = Sprite2D.new()
	bust.texture = load("res://art/bust.png")
	bust.centered = false
	bust.region_enabled = true
	sprite.add_child(bust)
	face = Sprite2D.new()
	face.texture = load("res://art/faces.png")
	face.centered = false
	face.region_enabled = true
	sprite.add_child(face)
	add_to_group("player")
	Game.toast.connect(func(_text: String, _icon: Texture2D) -> void: react("smile", 1.2))


func _physics_process(delta: float) -> void:
	var dir: Vector2 = Vector2.ZERO
	if not Game.ui_open and not Game.busy:
		if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
			dir.y -= 1.0
		if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
			dir.y += 1.0
		if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
			dir.x -= 1.0
		if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
			dir.x += 1.0
	# плавный разгон и торможение
	var was_still: bool = vel.length() < 4.0
	var old_pos: Vector2 = position
	if dir != Vector2.ZERO:
		vel = vel.move_toward(dir.normalized() * SPEED, ACCEL * delta)
	else:
		vel = vel.move_toward(Vector2.ZERO, DECEL * delta)
	var step: Vector2 = vel * delta
	var nx: Vector2 = position + Vector2(step.x, 0.0)
	if not _is_blocked(nx):
		position = nx
	else:
		vel.x = 0.0
	var ny: Vector2 = position + Vector2(0.0, step.y)
	if not _is_blocked(ny):
		position = ny
	else:
		vel.y = 0.0
	# куда хочет смотреть
	if dir != Vector2.ZERO:
		if absf(dir.x) > absf(dir.y):
			want_facing = 2 if dir.x < 0.0 else 3
		else:
			want_facing = 0 if dir.y > 0.0 else 1
	_update_turn(delta, dir)
	# анимация шага по пройденному пути: короткое нажатие = маленький шажок,
	# в начале сразу поднимает ногу, при остановке сводит ноги, потом стойка с ветром
	var moved: float = (position - old_pos).length()
	var frame: int
	if moved > 0.02:
		if was_still and dist < 0.01:
			dist = STRIDE
		dist += moved
		frame = int(dist / STRIDE) % 4
		last_walk = frame
		stop_t = 0.0
		idle_t = 0.0
	else:
		dist = 0.0
		stop_t += delta
		if stop_t < 0.1 and (last_walk == 0 or last_walk == 2):
			frame = 1 if last_walk == 0 else 3
		else:
			last_walk = 1
			idle_t += delta
			frame = IDLE_SEQ[int(idle_t / 0.3) % IDLE_SEQ.size()]
	sprite.frame = facing * FRAMES + frame
	# упёрлась в препятствие — надулась
	if dir != Vector2.ZERO and moved < 0.02:
		bump_t += delta
		if bump_t > 0.5 and expr_t <= 0.0:
			react("pout", 1.2)
	else:
		bump_t = 0.0
	_update_face(delta, frame)
	_update_bust(delta, frame)
	_update_target()


## Физика груди: когда тело подпрыгивает при шаге или дыхании, грудь запаздывает
## и мягко покачивается (пружина с затуханием). Резкий старт/остановка тоже толкают.
func _update_bust(delta: float, frame: int) -> void:
	if bust == null:
		return
	var bob: float = float(B_OFF[frame])
	var jump: float = bob - prev_bob
	prev_bob = bob
	bust_v -= jump * 10.0
	var sp: float = vel.length()
	bust_v += clampf((prev_speed - sp) * 0.06, -3.0, 3.0)
	prev_speed = sp
	bust_v += (-160.0 * bust_d - 6.5 * bust_v) * delta
	bust_d += bust_v * delta
	bust_d = clampf(bust_d, -1.4, 2.4)
	var k: int = clampi(int(round(bust_d)), -1, 2)
	bust.visible = facing == 0 or facing == 2 or facing == 3
	var region: Rect2
	var bx: float
	if facing == 0:
		region = Rect2(0, (k + 1) * 18, 19, 18)
		bx = 31.0
	else:
		region = Rect2(19, (k + 1) * 18, 12, 18)
		bx = 26.0 if facing == 2 else 42.0
	var by: float = 50.0 + bob
	bust.region_rect = region
	bust.flip_h = facing == 3
	bust.position = Vector2(-40.0 + bx, -157.0 + by)
	if bust_mat != null:
		var asz: Vector2 = Vector2(bust.texture.get_width(), bust.texture.get_height())
		bust_mat.set_shader_parameter("reg_uv_pos", region.position / asz)
		bust_mat.set_shader_parameter("reg_uv_size", region.size / asz)
		bust_mat.set_shader_parameter("reg_body_px", Vector2(bx, by))
		bust_mat.set_shader_parameter("reg_px_size", region.size)
		bust_mat.set_shader_parameter("reg_flip", facing == 3)


## Показать выражение на время: smile, happy, surprised, sad, pout, shy, wink, talk
func react(kind: String, dur: float = 1.2) -> void:
	expr = kind
	expr_t = dur


func _update_face(delta: float, frame: int) -> void:
	if face == null:
		return
	var h: float = Game.hour()
	var name: String = "sleepy" if (h >= 21.5 or h < 6.0) else "neutral"
	# долго стоит — оглядывается, улыбается, иногда подмигивает
	if idle_t > 4.0:
		look_t -= delta
		if look_t <= 0.0:
			look_t = randf_range(2.5, 5.5)
			idle_look = ["look_left", "look_right", "smile", "look_left", "look_right", "wink", "shy"].pick_random()
			idle_look_t = 1.3
	else:
		idle_look_t = 0.0
	if idle_look_t > 0.0:
		idle_look_t -= delta
		name = idle_look
	if expr_t > 0.0:
		expr_t -= delta
		name = expr
		if expr == "talk":
			name = ["talk_a", "neutral", "talk_b", "talk_a"][int(expr_t / 0.13) % 4]
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
	face.visible = facing != 1
	var region: Rect2
	var bx: float
	if facing == 0:
		region = Rect2(0, idx * 15, 20, 15)
		bx = 30.0
	else:
		region = Rect2(20, idx * 15, 11, 15)
		bx = 30.0 if facing == 2 else 39.0
	var by: float = 20.0 + float(B_OFF[frame])
	face.region_rect = region
	face.flip_h = facing == 3
	face.position = Vector2(-40.0 + bx, -157.0 + by)
	if face_mat != null:
		var asz: Vector2 = Vector2(face.texture.get_width(), face.texture.get_height())
		face_mat.set_shader_parameter("reg_uv_pos", region.position / asz)
		face_mat.set_shader_parameter("reg_uv_size", region.size / asz)
		face_mat.set_shader_parameter("reg_body_px", Vector2(bx, by))
		face_mat.set_shader_parameter("reg_px_size", region.size)
		face_mat.set_shader_parameter("reg_flip", facing == 3)


## Разворот: при смене стороны на противоположную — через промежуточную (лицом к камере / боком)
func _update_turn(delta: float, dir: Vector2) -> void:
	if facing == want_facing:
		turn_t = 0.0
		return
	turn_t += delta
	if turn_t < TURN_STEP:
		return
	turn_t = 0.0
	var opposite: bool = (facing == 0 and want_facing == 1) or (facing == 1 and want_facing == 0) or (facing == 2 and want_facing == 3) or (facing == 3 and want_facing == 2)
	if opposite:
		if facing == 2 or facing == 3:
			facing = 0
		else:
			facing = 2 if dir.x < 0.0 else 3
	else:
		facing = want_facing


func _is_blocked(p: Vector2) -> bool:
	if blocked.is_valid():
		return bool(blocked.call(p))
	return false


func _update_target() -> void:
	var best: Node2D = null
	var best_score: float = REACH
	var face_dir: Vector2 = [Vector2.DOWN, Vector2.UP, Vector2.LEFT, Vector2.RIGHT][facing]
	for node in get_tree().get_nodes_in_group("interactables"):
		var n: Node2D = node as Node2D
		if n == null or not n.is_visible_in_tree():
			continue
		var ip: Vector2 = n.global_position + Vector2(n.get("interact_offset"))
		var to: Vector2 = ip - (global_position + Vector2(0, -10))
		var d: float = to.length()
		if d > REACH:
			continue
		var score: float = d - (to.normalized().dot(face_dir) * 10.0 if d > 0.1 else 0.0)
		if score < best_score:
			best_score = score
			best = n
	if best != target:
		target = best
		target_changed.emit(target)


func _unhandled_input(event: InputEvent) -> void:
	if Game.ui_open or Game.busy:
		return
	if event is InputEventKey and event.pressed and not event.echo and (event as InputEventKey).physical_keycode == KEY_E:
		if target != null and is_instance_valid(target):
			target.call("interact")
			target = null
			_update_target()
			get_viewport().set_input_as_handled()

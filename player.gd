extends Node2D
## Травница. WASD/стрелки — ходить, Shift — бежать, E — действие.

signal target_changed(target: Node2D)

const SPEED: float = 58.0      # спокойный шаг
const RUN_SPEED: float = 132.0  # бег на Shift
const RUN_ACCEL: float = 230.0  # бег набирается не сразу (инерция)
const RUN_DECEL: float = 300.0  # с бега тормозит дольше — проскальзывает
const RUN_STRIDE: float = 13.0  # пикселей пути на кадр бега
const RUN_FROM: float = 84.0    # с какой скорости ноги переходят на бег
const HERO_SCALE: float = 0.3333   # размер героини в мире (кадр 80x160): под рост двери и дома
const REACH: float = 46.0
const ACCEL: float = 520.0      # разгон (пикс/с²)
const DECEL: float = 620.0      # торможение
const TURN_STEP: float = 0.06   # сколько держится промежуточный ракурс при повороте
const CAT_K: float = 0.6667        # во сколько раз кот уменьшен вместе с героиней (поза глажки остаётся той же)
const FRAMES: int = 28          # 24-27 бег, 0-3 ходьба, 4-7 стойка, 10-18 на колене (глажка), 19-23 плавно опускается на колени
# глажка: по голове, под подбородком, по всей спине
const PET_SEQ: Array = [[10, 11, 12, 13, 14, 15, 14, 13, 12, 11], [10, 11, 12, 13, 14, 15, 14, 13, 12, 11], [10, 11, 12, 13, 14, 15, 14, 13, 12, 11]]
const PET_STEP: Array = [0.16, 0.16, 0.16]
const PET_LEN: float = 4.2
# опускание на колено: 19 → 20 → 18 (рука на колене), вставание — обратно
const KNEEL_IN: Array = [19, 20, 21, 22, 23, 18]
const KNEEL_STEP: float = 0.11
# длительность каждого кадра опускания: сначала плавно трогается, в конце мягко оседает
const KNEEL_DUR: Array = [0.08, 0.09, 0.11, 0.13, 0.16, 0.20]
const STRIDE: float = 7.5      # пикселей пути на один кадр шага (шаг ~0.65 с на цикл)
# стойка: спокойно, порыв ветра (накидка и волосы колышутся), вдох
const IDLE_SEQ: Array = [4, 4, 4, 5, 5, 6, 7, 6, 5, 5, 4, 4, 4, 4]

var sprite: Sprite2D
var facing: int = 0          # 0 вниз, 1 вверх, 2 влево, 3 вправо, 4 вниз-влево, 5 вверх-влево, 6 вниз-вправо, 7 вверх-вправо
# порядок по кругу: поворот идёт через соседние ракурсы
const RING: Array = [0, 4, 2, 5, 1, 7, 3, 6]
const FACE_DIRS: Array = [Vector2.DOWN, Vector2.UP, Vector2.LEFT, Vector2.RIGHT, Vector2(-0.7, 0.7), Vector2(-0.7, -0.7), Vector2(0.7, 0.7), Vector2(0.7, -0.7)]
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
var slow_at: Callable        # func(p: Vector2) -> int: куст под ногами (-1 — нет)
var in_bush: bool = false
var last_frame: int = -1
var running: bool = false      # держит Shift и бежит
var run_dust_t: float = 0.0
var pet_t: float = 0.0        # гладит животное (сколько осталось)
var pet_kind: int = 2          # 0 по голове, 1 под подбородком, 2 по спине
var pet_walk: bool = false     # сначала подходит к коту шагами
var pet_goal: Vector2 = Vector2.ZERO
var pet_walk_t: float = 0.0     # сколько уже идёт к коту (страховка от зависания)

# ---- лицо: слой выражений поверх головы ----
const B_OFF: Array = [0, -1, 0, -1, 0, 0, -1, -1, 4, 4, 34, 34, 34, 34, 34, 34, 34, 34, 34, 5, 11, 17, 23, 29, 1, -2, 1, -2]   # как кадр поднимает голову
const EXPR: Dictionary = {
	"neutral": 0, "blink_half": 1, "blink": 2, "smile": 3, "happy": 4, "surprised": 5,
	"look_left": 6, "look_right": 7, "sleepy": 8, "talk_a": 9, "talk_b": 10, "shy": 11,
	"sad": 12, "pout": 13, "wink": 14, "disgust": 15, "sick": 16,
}
const EYES_SHUT: Array = ["happy", "blink", "wink"]
var speed_mul: float = 1.0            # v25: скакун, облик зверя, бодрость
var form_hook: Callable                 # v25: верхом / в облике зверя — свой вид (frame, moved, delta)
var face: Sprite2D
var face_mat: ShaderMaterial
var blush: Sprite2D
var blush_level: float = 0.0          # насколько покраснела кожа (для проверок)
var blush_front: ImageTexture
var blush_side: ImageTexture
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
	sprite.vframes = 8
	sprite.centered = false
	# кадр 80x160; масштаб подобран так, чтобы героиня была ниже двери дома
	sprite.offset = Vector2(-40, -157)
	sprite.scale = Vector2(HERO_SCALE, HERO_SCALE)
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
	# румянец стыда поверх лица: розовеет всё лицо, особенно щёки и переносица
	blush_front = _make_blush(22, 17, false)
	blush_side = _make_blush(13, 17, true)
	blush = Sprite2D.new()
	blush.centered = false
	blush.visible = false
	sprite.add_child(blush)
	add_to_group("player")
	Game.toast.connect(func(_text: String, _icon: Texture2D) -> void: react("smile", 1.2))


func _physics_process(delta: float) -> void:
	var dir: Vector2 = Vector2.ZERO
	# после глажки (или чего-то ещё) оказалась в стене/кусте-преграде — вытолкнуть наружу
	if not pet_walk and pet_t <= 0.0 and _is_blocked(position):
		_unstick()
	if pet_walk:
		pet_walk_t += delta
		var to_goal: Vector2 = pet_goal - position
		if pet_walk_t > 5.0:
			pet_walk = false   # не дошла за 5 секунд — отменяем, управление возвращается
			pet_t = 0.0
		elif to_goal.length() < 1.0:
			position = pet_goal
			pet_walk = false
			vel = Vector2.ZERO
			pet_t = PET_LEN
			facing = 2
			want_facing = 2
		else:
			dir = to_goal.normalized()
	elif not Game.ui_open and not Game.busy and pet_t <= 0.0:
		if KB.down("move_up"):
			dir.y -= 1.0
		if KB.down("move_down"):
			dir.y += 1.0
		if KB.down("move_left"):
			dir.x -= 1.0
		if KB.down("move_right"):
			dir.x += 1.0
		# v24: проделки монстров — сонные споры (стоит), призрак напугал (всё наоборот)
		if Game.mon_sleep > 0.0:
			dir = Vector2.ZERO
		elif Game.mon_confuse > 0.0:
			dir = -dir
	_mon_effects(delta)
	# плавный разгон и торможение
	var was_still: bool = vel.length() < 4.0
	var old_pos: Vector2 = position
	# в кустах идёт вдвое медленнее, мелкими шагами, раздвигая ветки
	in_bush = slow_at.is_valid() and int(slow_at.call(position)) >= 0
	var heavy: bool = Game.overloaded()
	Game.running_now = running
	var want_run: bool = dir != Vector2.ZERO and not pet_walk and not in_bush and not heavy 			and KB.down("run") and Game.carry_speed >= 1.0 and not Game.ui_open and not Game.busy
	running = want_run
	var max_sp: float = (RUN_SPEED if want_run else SPEED) * (0.5 if in_bush else 1.0) * (0.6 if pet_walk else 1.0) * (0.75 if Game.weak() else 1.0) * (0.55 if heavy else 1.0) * (0.6 if Game.sleepy() else 1.0) * (0.75 if position.y > 90000.0 else 1.0) * (1.0 + Game.stat("speed") / 100.0) * Game.carry_speed * (0.4 if Game.mon_sticky > 0.0 else 1.0) * speed_mul
	var fast: bool = vel.length() > SPEED + 4.0
	if dir != Vector2.ZERO:
		# на бегу разгон и повороты плавнее: героиня по инерции описывает дугу
		vel = vel.move_toward(dir.normalized() * max_sp, (RUN_ACCEL if (want_run or fast) else ACCEL) * delta)
		if vel.length() > max_sp:
			vel = vel.move_toward(vel.normalized() * max_sp, (RUN_DECEL if fast else DECEL) * delta)
	else:
		vel = vel.move_toward(Vector2.ZERO, (RUN_DECEL if fast else DECEL) * delta)
	var step: Vector2 = vel * delta
	if pet_walk and step.length() > (pet_goal - position).length():
		step = pet_goal - position
	var nx: Vector2 = position + Vector2(step.x, 0.0)
	if pet_walk or not _is_blocked(nx):
		position = nx
	else:
		vel.x = 0.0
	var ny: Vector2 = position + Vector2(0.0, step.y)
	if pet_walk or not _is_blocked(ny):
		position = ny
	else:
		vel.y = 0.0
	# куда хочет смотреть
	if dir != Vector2.ZERO:
		if dir.x != 0.0 and dir.y != 0.0:
			if dir.y > 0.0:
				want_facing = 4 if dir.x < 0.0 else 6
			else:
				want_facing = 5 if dir.x < 0.0 else 7
		elif dir.x != 0.0:
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
		if vel.length() > RUN_FROM:
			frame = 24 + int(dist / RUN_STRIDE) % 4
			# пыль из-под ботинок в момент толчка
			run_dust_t -= delta
			if run_dust_t <= 0.0 and (frame == 24 or frame == 26):
				run_dust_t = 0.22
				Game.fx.emit(position + Vector2(randf_range(-3, 3), -1), "dust")
		else:
			frame = int(dist / (STRIDE * (0.62 if in_bush else 1.0))) % 4
		last_walk = frame
		stop_t = 0.0
		idle_t = 0.0
	else:
		dist = 0.0
		stop_t += delta
		if stop_t < 0.1 and (last_walk == 0 or last_walk == 2 or last_walk == 24 or last_walk == 26):
			frame = 1 if (last_walk == 0 or last_walk == 24) else 3
		else:
			last_walk = 1
			idle_t += delta
			frame = IDLE_SEQ[int(idle_t / 0.3) % IDLE_SEQ.size()]
	if pet_t > 0.0:
		pet_t -= delta
		var el: float = PET_LEN - pet_t
		var tin: float = 0.0
		for d in KNEEL_DUR:
			tin += float(d)
		if el < tin:
			frame = int(KNEEL_IN[_kneel_idx(el)])
		elif pet_t < tin:
			frame = int(KNEEL_IN[KNEEL_IN.size() - 1 - _kneel_idx(tin - pet_t)])
		else:
			var seq: Array = PET_SEQ[pet_kind]
			frame = int(seq[int((el - tin) / float(PET_STEP[pet_kind])) % seq.size()])
		idle_t = 0.0
	if frame != last_frame and (frame == 0 or frame == 2 or frame == 24 or frame == 26) and not form_hook.is_valid():
		_step_sound()
	last_frame = frame
	sprite.frame = facing * FRAMES + frame
	if form_hook.is_valid():
		form_hook.call(frame, moved, delta)
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


## v24: шаг звучит по тому, что под ногами: трава, камень, дерево, гравий, песок, грязь, листва, снег, вода
func surface() -> String:
	var WD = preload("res://world_data.gd")
	var m: Node = get_tree().current_scene
	var p: Vector2 = global_position
	if m != null and (bool(m.get("inside")) or m.get("visiting") != null):
		return "wood"
	if p.x > 150000.0 or p.y > 120000.0 or p.x < -50000.0:
		return "stone"      # подземелья, шахта, клуб
	if p.y > 90000.0:
		return "sand"       # дно моря
	if Game.in_sea:
		return "water"
	var w: Node = m.get("world") if m != null else null
	if w != null:
		for wr in (w.get("walk_rects") as Array):
			if (wr as Rect2).has_point(p):
				return "wood"     # пирс
	var tn: Node = get_tree().get_first_node_in_group("towns")
	if tn != null and bool(tn.call("on_street", p)):
		return "stone"
	if WD.road_value(p) < 0.0 or preload("res://world_layout.gd").is_path(p):
		return "gravel"
	var b: int = WD.biome_at(p)
	if b == WD.BEACH:
		return "sand"
	if b == WD.SWAMP:
		return "mud"
	if b == WD.AUTUMN:
		return "leaves"
	if b == WD.GROTTO or b == WD.DWARF:
		return "stone"
	if b == WD.PINE and (int(p.x / 40.0) + int(p.y / 40.0)) % 3 == 0:
		return "leaves"
	if Game.has_method("weather_now") and String(Game.call("weather_now")) == "snow":
		return "snow"
	return "grass"


func _step_sound() -> void:
	var sf: String = surface()
	var vol: float = {"grass": -15.0, "stone": -14.0, "wood": -13.0, "gravel": -14.0, "sand": -15.0, "mud": -13.0, "leaves": -14.0, "snow": -14.0, "water": -12.0}.get(sf, -15.0)
	Sound.play("step_%s_%d" % [sf, randi_range(0, 3)], vol + (3.0 if running else 0.0), 0.08)


## Румянец: розовая заливка лица, тёмно-розовые щёки под глазами и полоса на переносице
func _make_blush(w: int, h: int, side: bool) -> ImageTexture:
	var im: Image = Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	for y in range(h):
		for x in range(w):
			var nx: float = (float(x) + 0.5 - float(w) / 2.0) / (float(w) / 2.0)
			var ny: float = (float(y) + 0.5 - float(h) / 2.0) / (float(h) / 2.0)
			var d: float = sqrt(nx * nx + ny * ny * 0.9)
			if d > 1.0:
				continue
			var c: Color = Color(1.0, 0.50, 0.62, 0.50)
			if d > 0.82:
				c = Color(1.0, 0.58, 0.68, 0.36)
			# щёки: ниже глаз, по бокам
			var cheek: bool = ny > -0.05 and ny < 0.78 and (absf(nx) > 0.30 or side)
			if cheek:
				c = Color(1.0, 0.24, 0.42, 0.78)
				if absf(nx) > 0.62 or ny > 0.55:
					c = Color(1.0, 0.34, 0.50, 0.62)
			# глаза остаются видны: на их полосе заливка слабее
			if not cheek and ny > -0.62 and ny < 0.02:
				c.a *= 0.5
			# полоса румянца через переносицу
			if not side and absf(ny - 0.08) < 0.14 and absf(nx) < 0.34:
				c = Color(1.0, 0.36, 0.52, 0.62)
			im.set_pixel(x, y, c)
	return ImageTexture.create_from_image(im)


## Физика груди: когда тело подпрыгивает при шаге или дыхании, грудь запаздывает
## и мягко покачивается (пружина с затуханием). Резкий старт/остановка тоже толкают.
func _update_bust(delta: float, frame: int) -> void:
	if bust == null:
		return
	var bob: float = float(B_OFF[frame])
	var jump: float = bob - prev_bob
	prev_bob = bob
	bust_v -= jump * 17.0
	var sp: float = vel.length()
	bust_v += clampf((prev_speed - sp) * 0.10, -5.0, 5.0)
	prev_speed = sp
	bust_v += (-115.0 * bust_d - 3.6 * bust_v) * delta
	bust_d += bust_v * delta
	bust_d = clampf(bust_d, -2.4, 3.4)
	var k: int = clampi(int(round(bust_d)), -2, 3)
	bust.visible = not (facing in [1, 5, 7]) and (frame < 8 or frame >= 24)
	var region: Rect2
	var bx: float
	var flip: bool = facing in [3, 6]
	if facing == 0:
		region = Rect2(0, (k + 2) * 18, 19, 18)
		bx = 31.0
	elif facing == 4 or facing == 6:
		region = Rect2(31, (k + 2) * 18, 19, 18)
		bx = 29.0 if facing == 4 else 32.0
	else:
		region = Rect2(19, (k + 2) * 18, 12, 18)
		bx = 26.0 if facing == 2 else 42.0
	var by: float = 40.0 + bob
	bust.region_rect = region
	bust.flip_h = flip
	bust.position = Vector2(-40.0 + bx, -157.0 + by)
	if bust_mat != null:
		var asz: Vector2 = Vector2(bust.texture.get_width(), bust.texture.get_height())
		bust_mat.set_shader_parameter("reg_uv_pos", region.position / asz)
		bust_mat.set_shader_parameter("reg_uv_size", region.size / asz)
		bust_mat.set_shader_parameter("reg_body_px", Vector2(bx, by))
		bust_mat.set_shader_parameter("reg_px_size", region.size)
		bust_mat.set_shader_parameter("reg_flip", flip)


## Если стоит в непроходимом месте — переставить в ближайшее свободное
func _unstick() -> void:
	for r in range(3, 91, 3):
		for k in range(16):
			var a: float = TAU * float(k) / 16.0
			var q: Vector2 = position + Vector2(cos(a), sin(a)) * float(r)
			if not _is_blocked(q):
				position = q
				vel = Vector2.ZERO
				return


## Какой кадр опускания на колени соответствует времени t от начала (по KNEEL_DUR)
func _kneel_idx(t: float) -> int:
	var acc: float = 0.0
	for i in range(KNEEL_DUR.size()):
		acc += float(KNEEL_DUR[i])
		if t < acc:
			return i
	return KNEEL_DUR.size() - 1


## Гладит животное: поворачивается к нему боком, присаживается, рука ходит туда-сюда
func start_pet(at: Vector2, on_cushion: bool = true) -> void:
	pet_kind = 0   # теперь всегда гладит по голове
	# всегда справа от кота, вплотную: так рука точно попадает по голове, подбородку и спине.
	# Подушка не мешает (это не стена). Если кот сидит не на подушке — он ниже, садимся ниже.
	pet_goal = Vector2(at.x + 11.0 * CAT_K, at.y + (3.0 + (7.0 if not on_cushion else 0.0)) * CAT_K)
	pet_walk = true
	pet_walk_t = 0.0
	pet_t = 0.0
	want_facing = facing
	react("happy", PET_LEN)


## Показать выражение на время: smile, happy, surprised, sad, pout, shy, wink, talk
## v24: проделки монстров тикают и видны на героине (без надписей)
var mon_fx_t: float = 0.0


func _mon_effects(delta: float) -> void:
	Game.mon_sticky = maxf(0.0, Game.mon_sticky - delta)
	Game.mon_sleep = maxf(0.0, Game.mon_sleep - delta)
	Game.mon_confuse = maxf(0.0, Game.mon_confuse - delta)
	mon_fx_t -= delta
	if mon_fx_t > 0.0:
		return
	mon_fx_t = 0.5
	if Game.mon_sleep > 0.0:
		Game.fx.emit(global_position + Vector2(4, -40), "zzz")
		react("sleepy", 0.6)
	elif Game.mon_confuse > 0.0:
		Game.fx.emit(global_position + Vector2(0, -42), "sparkle")
		react("surprised", 0.6)
	elif Game.mon_sticky > 0.0:
		Game.fx.emit(global_position + Vector2(0, -2), "steam_green")


var voice_cd: float = 0.0


## v29: голос героини — звук к эмоции (не чаще раза в 3 секунды)
const VOICE: Dictionary = {"happy": "hero_giggle", "pout": "hero_hm", "sad": "hero_sigh", "surprised": "hero_oh"}


func react(kind: String, dur: float = 1.2) -> void:
	expr = kind
	expr_t = dur
	var now: float = float(Time.get_ticks_msec()) / 1000.0
	if VOICE.has(kind) and now - voice_cd > 3.0 and not Game.busy:
		voice_cd = now
		Sound.play(String(VOICE[kind]), -8.0, 0.06)


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
	face.visible = not (facing in [1, 5, 7])
	var region: Rect2
	var bx: float
	var flip: bool = facing in [3, 6]
	if facing == 0:
		region = Rect2(0, idx * 15, 20, 15)
		bx = 30.0
	elif facing == 4 or facing == 6:
		region = Rect2(31, idx * 15, 20, 15)
		bx = 29.0 if facing == 4 else 31.0
	else:
		region = Rect2(20, idx * 15, 11, 15)
		bx = 29.0 if facing == 2 else 40.0
	var by: float = 18.0 + float(B_OFF[frame])
	face.region_rect = region
	face.flip_h = flip
	face.position = Vector2(-40.0 + bx, -157.0 + by)
	if blush != null:
		blush.visible = false
	# стыд: краснеет сама кожа лица и шеи (шейдер героини), щёки сильнее; на пределе пульсирует
	var sh: float = Game.shame
	var pulse: float = 0.0 if sh < 0.7 else 0.08 * sin(Time.get_ticks_msec() * 0.008)
	blush_level = clampf(sh * 1.3 + pulse, 0.0, 1.0) if sh > 0.05 else 0.0
	var bym: float = 40.0 + float(B_OFF[frame])
	for m in [sprite.material, face_mat]:
		if m is ShaderMaterial:
			(m as ShaderMaterial).set_shader_parameter("blush", blush_level)
			(m as ShaderMaterial).set_shader_parameter("blush_ymax", bym)
	if face_mat != null:
		var asz: Vector2 = Vector2(face.texture.get_width(), face.texture.get_height())
		face_mat.set_shader_parameter("reg_uv_pos", region.position / asz)
		face_mat.set_shader_parameter("reg_uv_size", region.size / asz)
		face_mat.set_shader_parameter("reg_body_px", Vector2(bx, by))
		face_mat.set_shader_parameter("reg_px_size", region.size)
		face_mat.set_shader_parameter("reg_flip", flip)


## Разворот: по кругу через соседние ракурсы, кратчайшим путём (как будто вертится)
func _update_turn(delta: float, _dir: Vector2) -> void:
	if facing == want_facing:
		turn_t = 0.0
		return
	turn_t += delta
	if turn_t < TURN_STEP:
		return
	turn_t = 0.0
	var a: int = RING.find(facing)
	var b2: int = RING.find(want_facing)
	var d: int = posmod(b2 - a, 8)
	var step: int = 1 if d <= 4 else -1
	facing = int(RING[posmod(a + step, 8)])


func _is_blocked(p: Vector2) -> bool:
	if blocked.is_valid():
		return bool(blocked.call(p))
	return false


var low_block_until: int = 0


## Спутники: кот, что ходит следом, питомцы из приюта и завербованные жительницы
func _low_priority(n: Node) -> bool:
	if n.get("follower") == true or n.get("is_pet") == true:
		return true
	var sc: Script = n.get_script() as Script
	return sc != null and sc.resource_path.ends_with("/cat.gd")


func _update_target() -> void:
	if target != null and (not is_instance_valid(target) or target.is_queued_for_deletion()):
		target = null
		target_changed.emit(null)
	var best: Node2D = null
	var best_score: float = REACH
	var face_dir: Vector2 = FACE_DIRS[facing]
	for node in get_tree().get_nodes_in_group("interactables"):
		if not is_instance_valid(node) or (node as Node).is_queued_for_deletion():
			continue
		var n: Node2D = node as Node2D
		if n == null or not n.is_visible_in_tree():
			continue
		var ip: Vector2 = n.global_position + Vector2(n.get("interact_offset"))
		var to: Vector2 = ip - (global_position + Vector2(0, -10))
		var d: float = to.length()
		if d > REACH:
			continue
		var score: float = d - (to.normalized().dot(face_dir) * 10.0 if d > 0.1 else 0.0)
		# v20: кот-спутник, питомцы и завербованные — только если рядом нет ничего другого,
		# героиня смотрит на них, стоит близко и не жала E только что (чтобы не гладить случайно)
		if _low_priority(n):
			if Time.get_ticks_msec() < low_block_until or d > REACH * 0.7:
				continue
			if d > 0.1 and to.normalized().dot(face_dir) < 0.35:
				continue
			score += 1000.0
		if score < best_score or (best == null and score < 2000.0):
			best_score = score
			best = n
	if best != target:
		target = best
		target_changed.emit(target)


func _unhandled_input(event: InputEvent) -> void:
	if Game.ui_open or Game.busy:
		return
	if event is InputEventKey and event.pressed and not event.echo and KB.is_key("interact", (event as InputEventKey).physical_keycode):
		low_block_until = Time.get_ticks_msec() + 1600
		if target != null and is_instance_valid(target):
			target.call("interact")
			target = null
			_update_target()
			get_viewport().set_input_as_handled()
		else:
			# рядом нет ничего интересного — может, дерево: окно веточек
			var hs: Node = get_tree().get_first_node_in_group("homestead")
			if hs != null and not Game.has_tool("net") and bool(hs.call("try_tree", false)):
				get_viewport().set_input_as_handled()

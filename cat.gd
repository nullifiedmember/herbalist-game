extends Node2D
## Чёрный кот травницы (v18): ходит за героиней везде — по лесу, дорогам, домам и городам.
## Отстаёт — догоняет бегом, потерялся или телепорт — сам появляется рядом. Дома, когда пора спать,
## сворачивается на подушке. Мяукает. E — погладить: героиня присаживается и гладит, кот жмурится и мурчит.

var interact_offset: Vector2 = Vector2(0, -14)
var spr: Sprite2D
var cushion_pos: Vector2 = Vector2.INF   # где лежит подушка дома
var blocked: Callable                    # func(p: Vector2) -> bool — куда нельзя
var main: Node2D
var t: float = 0.0
var awake: float = 0.0                   # после глажки не засыпает
var pet_t: float = 0.0                   # сколько ещё жмурится
var heart_cd: float = 0.0
var state: String = "follow"             # follow, nap (спит на подушке)
var still_t: float = 0.0                 # как долго героиня стоит
var stuck_t: float = 0.0
var meow_t: float = 6.0
var last_pp: Vector2 = Vector2.INF
var moving: bool = false
var snaps: int = 0                       # сколько раз догонял телепортом (для проверки)
var skin: String = ""                    # v19: окрас кошки из приюта (cat_lost_<окрас>); "" — свой чёрный кот
var is_pet: bool = false                 # кошка из приюта
var keep: float = 56.0
const CAT_K: float = 0.6667              # кот уменьшен вместе с героиней
const WALK: float = 58.0
const RUN: float = 118.0

const SNAP_DIST: float = 640.0


func _ready() -> void:
	add_to_group("interactables")
	if not is_pet:
		add_to_group("companion_cat")
	y_sort_enabled = true
	spr = Sprite2D.new()
	spr.texture = load(preload("res://cats26_db.gd").tex_path(skin))   # v26: пушистые окрасы и котята
	if skin == "black":
		spr.modulate = Color(0.85, 0.85, 0.95)
		spr.scale = Vector2(0.8, 0.8)   # чиби-лист: пиксель 1:1
	spr.hframes = 10
	spr.centered = false
	spr.offset = Vector2(-spr.texture.get_width() / 20.0, -spr.texture.get_height() + 2.0)
	if spr.scale == Vector2.ONE:
		spr.scale = Vector2.ONE
	add_child(spr)


func _sleep_time() -> bool:
	var h: float = Game.hour()
	return h < 9.0 or h > 19.5 or (h > 13.0 and h < 15.0)


func _player() -> Node2D:
	return main.get("player") as Node2D if main != null else null


func _process(delta: float) -> void:
	t += delta
	awake = maxf(0.0, awake - delta)
	pet_t = maxf(0.0, pet_t - delta)
	var pl: Node2D = _player()
	if pl == null:
		return
	var pp: Vector2 = pl.global_position
	var lw: Node = get_tree().get_first_node_in_group("law18")
	# под водой и в камере кот ждёт снаружи
	var hidden_now: bool = (pp.y > 90000.0 and pp.y < 120000.0) or (lw != null and bool(lw.get("jailed")))
	visible = not hidden_now
	if hidden_now:
		last_pp = pp
		return
	if last_pp == Vector2.INF or pp.distance_to(last_pp) > 400.0:
		# перенеслась (дом, гости, телепорт): кот тут как тут
		if last_pp != Vector2.INF or global_position.distance_to(pp) > SNAP_DIST:
			snap_to(pp)
	if pp.distance_to(last_pp) < 0.4:
		still_t += delta
	else:
		still_t = 0.0
	last_pp = pp
	var dist: float = global_position.distance_to(pp)
	if dist > SNAP_DIST or (stuck_t > 2.2 and dist > 140.0):
		snap_to(pp)
		dist = global_position.distance_to(pp)
	moving = false
	if pet_t > 0.0:
		pass
	elif state == "nap":
		# уснул на подушке; героиня ушла или проснулись — снова за ней
		if cushion_pos == Vector2.INF or pp.distance_to(cushion_pos) > 320.0 or not _sleep_time() or awake > 0.0 or still_t < 1.0:
			state = "follow"
	else:
		if _sleep_time() and still_t > 4.0 and cushion_pos != Vector2.INF and pp.distance_to(cushion_pos) < 240.0 and awake <= 0.0:
			# дома пора спать — идёт на подушку
			var to: Vector2 = cushion_pos - global_position
			if to.length() < 3.0:
				global_position = cushion_pos
				state = "nap"
			else:
				_step(to.normalized(), minf(WALK, to.length() / maxf(delta, 0.001)), delta)
		elif dist > keep + 16.0:
			var dir: Vector2 = (pp - global_position).normalized()
			var sp: float = clampf((dist - keep) * 1.8, WALK, RUN)
			_step(dir, sp, delta)
		elif dist < keep - 24.0 and still_t < 0.3:
			# героиня наступает — отходит в сторонку
			_step((global_position - pp).normalized(), WALK * 0.8, delta)
	_animate(pp, dist)
	# мяукает, когда не спит
	if not _sleeping():
		meow_t -= delta
		if meow_t <= 0.0:
			meow_t = randf_range(10.0, 22.0)
			_say("Мяу!" if randf() < 0.8 else "Мррр?")
	if pet_t > 0.0:
		heart_cd -= delta
		if heart_cd <= 0.0:
			heart_cd = 0.7
			Game.fx.emit(global_position + Vector2(randf_range(-8, 3), -35), "heart")


func _sleeping() -> bool:
	return state == "nap" and awake <= 0.0 and pet_t <= 0.0


func _animate(pp: Vector2, dist: float) -> void:
	# кадр: 0-1 сидит, 2-3 спит, 4-5 жмурится, 6-9 идёт
	if pet_t > 0.0:
		spr.frame = 4 + (int(t / 0.5) % 2)
	elif moving:
		spr.frame = 6 + (int(t / (0.13 if dist < 200.0 else 0.09)) % 4)
	elif state == "nap" or (_sleep_time() and still_t > 8.0 and awake <= 0.0):
		spr.frame = 2 + (int(t / 1.4) % 2)
	else:
		spr.frame = 1 if fmod(t, 3.2) < 0.45 else 0
	var napping: bool = state == "nap" and not moving
	spr.offset = Vector2(-spr.texture.get_width() / 20.0, -spr.texture.get_height() + 2.0)   # чиби: лёжа кадр уже на земле
	if not moving and pet_t <= 0.0 and state != "nap":
		# сидя смотрит на героиню
		spr.flip_h = pp.x > global_position.x
	if state == "nap":
		spr.flip_h = false


## Шаг в сторону dir; упёрся — пробует обойти
func _step(dir: Vector2, speed: float, delta: float) -> void:
	for ang in [0.0, 0.7, -0.7, 1.4, -1.4]:
		var d: Vector2 = dir.rotated(ang)
		var nxt: Vector2 = global_position + d * speed * delta
		if not (blocked.is_valid() and bool(blocked.call(nxt))):
			global_position = nxt
			moving = true
			spr.flip_h = d.x > 0.0
			stuck_t = maxf(0.0, stuck_t - delta)
			return
	stuck_t += delta


## Оказаться рядом с героиней (на свободном месте)
func snap_to(pp: Vector2) -> void:
	snaps += 1
	var want: Vector2 = pp + Vector2(randf_range(-28.0, 28.0), randf_range(10.0, 30.0))
	if main != null and main.has_method("free_near"):
		want = main.call("free_near", want)
	global_position = want
	stuck_t = 0.0
	if state == "nap":
		state = "follow"


## Надпись над котом: всплывает и тает
func _say(text: String) -> void:
	var l: Label = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 9)
	l.add_theme_color_override("font_color", Color("fff4e0"))
	l.add_theme_color_override("font_outline_color", Color("2a1622"))
	l.add_theme_constant_override("outline_size", 5)
	l.position = Vector2(-8, -46)
	l.z_index = 60
	add_child(l)
	var tw: Tween = create_tween().set_parallel(true)
	tw.tween_property(l, "position:y", l.position.y - 12.0, 1.4)
	tw.tween_property(l, "modulate:a", 0.0, 0.6).set_delay(0.9)
	tw.chain().tween_callback(l.queue_free)


func get_prompt() -> String:
	return "Погладить кота"


func interact() -> void:
	awake = 6.0
	pet_t = 3.8
	heart_cd = 0.0
	Game.toast.emit("Мурр-мурр...", load("res://art/fx_heart.png"))
	_say("Мурр...")
	var pl: Node = get_tree().get_first_node_in_group("player")
	if pl != null:
		pl.call("start_pet", global_position, state == "nap")
	if state == "nap":
		state = "follow"
	# v20: кот линяет — иногда на ладони остаётся шерсть, а раз в несколько дней и выпавший ус
	if randf() < 0.35:
		Game.add_item("cat_fur")
	if Game.whisker_day < 0 or Game.day - Game.whisker_day >= 3:
		if randf() < 0.5:
			Game.whisker_day = Game.day
			Game.add_item("cat_whisker")

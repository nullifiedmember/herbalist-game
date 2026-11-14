extends Node2D
## v26: бродячий кот или котёнок. Тот же спрайт, что у чёрного кота травницы, только другой окрас.
## Сидит, гуляет вокруг своего места, дремлет. Котята бегают за мамой.
## E — погладить (иногда остаётся шерсть). Погладишь несколько раз — кот пойдёт жить к героине.

const DB = preload("res://cats26_db.gd")
const CAT_K: float = 0.6667
const MAX_PETS: int = 12

var skin: String = "ginger"
var home: Vector2 = Vector2.ZERO
var main: Node2D
var mom: Node2D                         # у котёнка — мама
var kit_off: Vector2 = Vector2(14, 6)  # где котёнок держится возле мамы
var interact_offset: Vector2 = Vector2(0, -12)
var spr: Sprite2D
var state: String = "sit"               # sit, walk, nap
var state_t: float = 0.0
var goal: Vector2 = Vector2.ZERO
var t: float = 0.0
var pet_t: float = 0.0
var heart_cd: float = 0.0
var meow_t: float = 5.0
var petted: int = 0
var moving: bool = false


func _ready() -> void:
	add_to_group("interactables")
	add_to_group("stray_cats26")
	y_sort_enabled = true
	spr = Sprite2D.new()
	spr.texture = load(DB.tex_path(skin))
	spr.hframes = 10
	spr.centered = false
	spr.offset = Vector2(-18, -30)
	spr.scale = Vector2(CAT_K, CAT_K)
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(spr)
	if DB.is_kit(skin):
		interact_offset = Vector2(0, -8)
	t = randf() * 4.0
	state_t = randf_range(1.0, 5.0)
	if home == Vector2.ZERO:
		home = position
	if main != null and main.has_method("add_caster"):
		main.call("add_caster", spr, true)


## сколько раз погладить, чтобы кот пошёл с тобой: редких дольше уговаривать
func need_pets() -> int:
	return 3 + DB.tier(skin) * 2


func _night() -> bool:
	var h: float = Game.hour()
	return h < 6.0 or h > 21.0


func _process(delta: float) -> void:
	t += delta
	pet_t = maxf(0.0, pet_t - delta)
	state_t -= delta
	moving = false
	var pl: Node2D = main.get("player") as Node2D if main != null else null
	if pet_t > 0.0:
		pass
	elif mom != null and is_instance_valid(mom):
		_follow_mom(delta)
	else:
		mom = null
		_wander(delta)
	_animate(pl)
	if pl != null and pet_t <= 0.0 and state != "nap" and pl.global_position.distance_to(global_position) < 200.0:
		meow_t -= delta
		if meow_t <= 0.0:
			meow_t = randf_range(9.0, 20.0)
			Sound.play("meow_%d" % randi_range(0, 3), -10.0 if DB.is_kit(skin) else -8.0, 0.18 if DB.is_kit(skin) else 0.1, global_position)
			_say("Мяу!" if not DB.is_kit(skin) else "Мя!")
	if pet_t > 0.0:
		heart_cd -= delta
		if heart_cd <= 0.0:
			heart_cd = 0.7
			Game.fx.emit(global_position + Vector2(randf_range(-8, 3), -28), "heart")


func _wander(delta: float) -> void:
	if state == "walk":
		var to: Vector2 = goal - global_position
		if to.length() < 3.0 or state_t <= 0.0:
			state = "sit"
			state_t = randf_range(3.0, 8.0)
		else:
			_step(to.normalized(), 26.0 if not DB.is_kit(skin) else 20.0, delta)
		return
	if state_t > 0.0:
		return
	var r: float = randf()
	var nap_p: float = 0.55 if _night() else 0.22
	if r < nap_p:
		state = "nap"
		state_t = randf_range(10.0, 26.0)
	elif r < nap_p + 0.4:
		state = "walk"
		var a: float = randf() * TAU
		goal = home + Vector2(cos(a), sin(a) * 0.7) * randf_range(20.0, 110.0)
		state_t = 8.0
	else:
		state = "sit"
		state_t = randf_range(3.0, 9.0)


func _follow_mom(delta: float) -> void:
	var want: Vector2 = mom.global_position + kit_off
	var d: float = global_position.distance_to(want)
	if d > 260.0:
		global_position = want
		return
	if d > 10.0:
		state = "walk"
		_step((want - global_position).normalized(), clampf(d * 1.5, 22.0, 70.0), delta)
	else:
		# возле мамы делает то же, что она: спит, когда спит мама
		state = "nap" if String(mom.get("state")) == "nap" else "sit"


func _animate(pl: Node2D) -> void:
	# кадр: 0-1 сидит, 2-3 спит, 4-5 жмурится, 6-9 идёт (как у кота травницы)
	if pet_t > 0.0:
		spr.frame = 4 + (int(t / 0.5) % 2)
	elif moving:
		spr.frame = 6 + (int(t / 0.13) % 4)
	elif state == "nap":
		spr.frame = 2 + (int(t / 1.4) % 2)
		spr.flip_h = false
	else:
		spr.frame = 1 if fmod(t, 3.2) < 0.45 else 0
		if pl != null and pl.global_position.distance_to(global_position) < 140.0:
			spr.flip_h = pl.global_position.x > global_position.x
	spr.offset = Vector2(-18, -26) if (state == "nap" and not moving and pet_t <= 0.0) else Vector2(-18, -30)


func _step(dir: Vector2, speed: float, delta: float) -> void:
	for ang in [0.0, 0.7, -0.7, 1.4, -1.4]:
		var d: Vector2 = dir.rotated(float(ang))
		var nxt: Vector2 = global_position + d * speed * delta
		if main == null or not bool(main.call("is_blocked", nxt)):
			global_position = nxt
			moving = true
			spr.flip_h = d.x > 0.0
			return
	state_t = 0.0
	if state == "walk" and mom == null:
		state = "sit"


func _say(text: String) -> void:
	var l: Label = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 9)
	l.add_theme_color_override("font_color", Color("fff4e0"))
	l.add_theme_color_override("font_outline_color", Color("2a1622"))
	l.add_theme_constant_override("outline_size", 5)
	l.position = Vector2(-8, -40)
	l.z_index = 60
	add_child(l)
	var tw: Tween = create_tween().set_parallel(true)
	tw.tween_property(l, "position:y", l.position.y - 12.0, 1.2)
	tw.tween_property(l, "modulate:a", 0.0, 0.5).set_delay(0.7)
	tw.chain().tween_callback(l.queue_free)


func get_prompt() -> String:
	return "Погладить: " + DB.title(skin)


func interact() -> void:
	pet_t = 3.2
	heart_cd = 0.0
	petted += 1
	if state == "nap":
		state = "sit"
	state_t = randf_range(4.0, 8.0)
	Sound.play("purr", -6.0, 0.05, global_position)
	_say("Мурр...")
	var pl: Node = get_tree().get_first_node_in_group("player")
	if pl != null and pl.has_method("start_pet"):
		pl.call("start_pet", global_position, false)
	if randf() < 0.3 + 0.1 * float(DB.tier(skin)):
		Game.add_item("cat_fur")
	if petted >= need_pets():
		adopt()


## Кот привязался: дальше живёт у героини и ходит за ней (как кошки из приюта)
func adopt() -> bool:
	if (Game.pets as Array).size() >= MAX_PETS:
		Game.toast.emit("Котик мурчит, но у тебя и так много питомцев", load("res://art/fx_heart.png"))
		return false
	var sh: Node = get_tree().get_first_node_in_group("shelters18")
	if sh == null:
		return false
	Game.pets.append({"kind": "cat:" + skin, "land": "stray", "day": Game.day})
	sh.call("spawn_pet", "cat:" + skin, global_position)
	Game.toast.emit("Пошёл с тобой: " + DB.title(skin), load("res://art/fx_heart.png"))
	# котята этой кошки остаются без мамы — просто гуляют сами
	for k in get_tree().get_nodes_in_group("stray_cats26"):
		if k.get("mom") == self:
			k.set("mom", null)
			k.set("home", (k as Node2D).global_position)
	queue_free()
	return true

extends Node
## v23: море. С конца пирса — рыбалка на морских рыб и акул (3 места). Когда героиня плывёт в хвосте русалки,
## вокруг плавают рыбы и акулы (добрые — только толкаются), а иногда подплывает говорящая волшебная рыба.

const V = preload("res://v23_data.gd")
const PIER_END: Vector2 = Vector2(960, 8060)
const SHORE_Y: float = 7592.0
const SWIMMERS: Array = ["sea_sardine", "sea_mackerel", "sea_clown", "sea_angel", "sea_puffer", "sea_jelly", "sea_ray", "sea_tuna", "shark_reef", "shark_hammer", "shark_whale", "sea_seahorse", "sea_octopus", "shark_tiger"]

var main: Node2D
var v23: Node
var spots_done: bool = false
var swimmers: Array = []          # [спрайт, скорость, фаза, вид]
var t: float = 0.0
var talk_t: float = 30.0
var visitor: Sprite2D = null
var visitor_id: String = ""


func setup(m: Node2D, v: Node) -> void:
	main = m
	v23 = v
	add_to_group("sea23")


func _process(delta: float) -> void:
	t += delta
	if not spots_done and t > 1.0:
		spots_done = true
		_make_spots()
	var pl: Node2D = main.get("player")
	if pl == null:
		return
	if Game.in_sea:
		_update_swimmers(delta, pl)
		talk_t -= delta
		if talk_t <= 0.0 and visitor == null and not Game.ui_open:
			talk_t = randf_range(60.0, 140.0)
			if randf() < 0.55:
				_send_visitor(_pick_talker(), pl)
	elif not swimmers.is_empty():
		for s in swimmers:
			(s[0] as Node).queue_free()
		swimmers.clear()
	if visitor != null:
		if not Game.in_sea:
			visitor.queue_free()
			visitor = null
		else:
			var to: Vector2 = pl.global_position + Vector2(-26, -10) - visitor.global_position
			visitor.flip_h = to.x > 0.0
			visitor.global_position += to.normalized() * minf(to.length(), 70.0 * delta)
			visitor.frame = int(t * 5.0) % 2
			if to.length() < 8.0 and not Game.ui_open:
				var id: String = visitor_id
				visitor.queue_free()
				visitor = null
				talk(id)


func _make_spots() -> void:
	var objs: Node = main.get("objects")
	for d in [[Vector2(-34, -20), Vector2(-90, 30)], [Vector2(34, -20), Vector2(90, 30)], [Vector2(0, 24), Vector2(0, 110)]]:
		var shore: Vector2 = PIER_END + (d[0] as Vector2)
		var sp: Node2D = Node2D.new()
		sp.set_script(load("res://fishing_spot.gd"))
		sp.position = shore + (d[1] as Vector2)
		sp.set("shore", shore)
		sp.set("sea", true)
		sp.set("interact_offset", (shore - sp.position) * 0.9)
		objs.add_child(sp)


# ------------------------------------------------------------------ плавающие рыбы и акулы

func _update_swimmers(delta: float, pl: Node2D) -> void:
	while swimmers.size() < 10:
		var id: String = String(SWIMMERS.pick_random())
		var s: Sprite2D = Sprite2D.new()
		s.texture = load("res://art/swim_%s.png" % id)
		s.hframes = 2
		var big: float = float(V.SEA_FISH[id]["len"])
		s.scale = Vector2.ONE * clampf(0.25 + big * 0.18, 0.3, 0.75)
		s.modulate = Color(0.85, 0.95, 1.0, 0.85)
		s.z_index = 3
		var a: float = randf() * TAU
		s.global_position = pl.global_position + Vector2(cos(a), sin(a) * 0.6) * randf_range(200, 380)
		main.add_child(s)
		swimmers.append([s, randf_range(18, 46) * (1.0 if not id.begins_with("shark") else 0.8), randf() * TAU, id])
	for i in range(swimmers.size() - 1, -1, -1):
		var e: Array = swimmers[i]
		var s2: Sprite2D = e[0]
		e[2] = float(e[2]) + delta * 0.25
		var dir: Vector2 = Vector2(cos(float(e[2])), sin(float(e[2]) * 1.3) * 0.4)
		var to_pl: Vector2 = pl.global_position - s2.global_position
		# акулы любопытные — кружат рядом, остальные держатся подальше
		if String(e[3]).begins_with("shark"):
			dir += to_pl.normalized() * 0.4 if to_pl.length() > 90.0 else -to_pl.normalized() * 0.6
		elif to_pl.length() < 70.0:
			dir -= to_pl.normalized()
		s2.global_position += dir.normalized() * float(e[1]) * delta
		s2.flip_h = dir.x > 0.0
		s2.frame = int(t * 3.0 + float(e[2])) % 2
		# акула ткнулась носом — смешно толкает
		if String(e[3]).begins_with("shark") and to_pl.length() < 18.0:
			pl.position += to_pl.normalized() * 10.0
			pl.call("react", "surprised", 0.8)
		if s2.global_position.distance_to(pl.global_position) > 700.0 or s2.global_position.y < SHORE_Y + 40.0:
			s2.queue_free()
			swimmers.remove_at(i)


func _pick_talker() -> String:
	var night: bool = Game.night_factor() > 0.5
	var opts: Array = []
	for id in V.TALKING:
		if String(id) == "sea_moon" and not night:
			continue
		if int(Game.fish_talked.get(id, -1)) == Game.day:
			continue
		opts.append(String(id))
	return String(opts.pick_random()) if not opts.is_empty() else ""


func _send_visitor(id: String, pl: Node2D) -> void:
	if id == "":
		return
	visitor_id = id
	visitor = Sprite2D.new()
	visitor.texture = load("res://art/swim_%s.png" % id)
	visitor.hframes = 2
	visitor.scale = Vector2(0.45, 0.45)
	visitor.z_index = 4
	visitor.global_position = pl.global_position + Vector2(260, -40)
	main.add_child(visitor)
	Sound.play("magic", -8.0)


# ------------------------------------------------------------------ разговоры

func _face(id: String) -> Texture2D:
	return load("res://art/fish_%s.png" % id)


func talk(id: String) -> void:
	if id == "":
		return
	var nm: String = String(V.SEA_FISH[id]["name"])
	var again: bool = int(Game.fish_talked.get(id, -1)) == Game.day
	Game.fish_talked[id] = Game.day
	if again:
		v23.call("talk", _face(id), nm, "Мы же сегодня уже виделись! Приплывай завтра.", [])
		return
	match id:
		"sea_golden":
			v23.call("talk", _face(id), nm,
				"Эй, ты чего тут гуляешь? Только сразу: я НЕ та типичная золотая рыбка, которая исполняет три желания! У меня выходной уже лет триста. Но раз уж приплыла... чего тебе?",
				[["Хочу три желания!", func() -> void:
					v23.call("talk", _face(id), nm, "Ох, все вы одинаковые... Ладно. ОДНО маленькое желание. И не рассказывай никому!", [
						["Монетки!", func() -> void: Game.add_coins(randi_range(40, 90))],
						["Сил побольше!", func() -> void:
							Game.hp = Game.hp_max()
							Game.fatigue = 0.0
							Game.hunger = 0.0
							Game.thirst = 0.0],
						["Мудрости!", func() -> void: Game.skill_xp(String(Game.SKILL_ORDER.pick_random()), 120.0)]])],
				 ["Можно жемчужинку?", func() -> void:
					Game.add_item("pearl", randi_range(1, 3))
					Game.toast.emit("Рыбка фыркнула и выплюнула жемчуг", _face(id))],
				 ["Просто поболтать", func() -> void:
					v23.call("talk", _face(id), nm, String(["Знаешь, сколько рыбаков меня ловили? Двести семнадцать. И каждый просил новое корыто. Корыто! Скука.", "У акул сегодня день рождения. Не мешай им, они стесняются.", "Если увидишь мегалодона — помаши. Он добрый, просто очень большой.", "Говорят, в одной из пещер есть портал прямо в пекло. Я бы туда не плавала — там нет воды!"].pick_random()), [])],
				 ["Извини, уплываю", func() -> void: pass]])
		"sea_wise_cat":
			v23.call("talk", _face(id), nm,
				"Мррр... Я старый морской сом. Помню всех капитанов этого берега. Хочешь, научу рыбацким секретам? Или покажу, где растут морские травы?",
				[["Научи секретам рыбалки", func() -> void:
					Game.skill_xp("fish", 150.0)
					Game.toast.emit("Сом рассказал про приманки и течения", _face(id))],
				 ["Покажи морские травы", func() -> void:
					Game.add_item("kelp_dried", 3)
					Game.add_item("sea_salt", 2)],
				 ["Спасибо, дедушка сом", func() -> void: pass]])
		"sea_bard":
			v23.call("talk", _face(id), nm,
				"Ля-ля-ля! Я рыба-бард! Спеть тебе балладу о краб-рыцаре, который потерял клешню в споре с медузой? Это очень грустно и очень смешно!",
				[["Спой!", func() -> void:
					Sound.play("ui_select", -2.0, 0.3)
					Game.buff_t = maxf(Game.buff_t, 180.0)
					Game.add_item(String(V.JOKES.keys().pick_random()))
					Game.toast.emit("От песни стало легко-легко! (бодрость)", _face(id))],
				 ["Расскажи анекдот", func() -> void:
					v23.call("talk", _face(id), nm, "Почему рыбы не играют в теннис? Боятся сетки! Буль-буль-буль!", [])],
				 ["В другой раз", func() -> void: pass]])
		"sea_moon":
			v23.call("talk", _face(id), nm,
				"Тссс... Ночь — моё время. Луна просила передать тебе подарок. Протяни ладони.",
				[["Протянуть ладони", func() -> void:
					Game.add_item("moon_dew", 2)
					if randf() < 0.3:
						Game.add_item("book_spell_light")
					Game.toast.emit("В ладонях — лунная роса", _face(id))],
				 ["Спасибо, луна", func() -> void: pass]])


func god_talk(id: String) -> void:
	if id == "":
		id = String(V.TALKING.pick_random())
	Game.fish_talked.erase(id)
	talk(id)

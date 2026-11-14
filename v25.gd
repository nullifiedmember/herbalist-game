extends Node
## v25 (main/V25): Книга сфер (как Magicka / Инвокер), скакуны (приручение и езда), облик зверя (уникальное:
## превращение в любого поглаженного зверя, звери говорят с тобой), переезд в другой край, алтари стихий, дружба с пони.
## Клавиши (KB): C — режим заклинаний (1-8 — сферы), R или ПКМ — произнести, H — гримуар, N — сесть/слезть, P — переезд.

const SP = preload("res://spells25_db.gd")
const W = preload("res://wild_db.gd")
const WD = preload("res://world_data.gd")
const SCN = preload("res://scenarios_db.gd")
const FRAMES_A: int = 12
const MANA_MAX: float = 100.0
const MOVE_COST: int = 60
const RIDE_SCALE: float = 0.62        # под седлом скакун крупнее, чем бродит по лесу (как настоящий конь рядом с всадницей)
## старые звери, на которых тоже можно ездить: скорость, сколько угощений до приручения, высота спины
const MOUNT_EXTRA: Dictionary = {
	"unicorn": {"ride_speed": 2.4, "tame": 6, "back": 22.0},
	"golden_deer": {"ride_speed": 2.3, "tame": 6, "back": 21.0},
	"deer": {"ride_speed": 2.0, "tame": 5, "back": 20.0},
	"boar": {"ride_speed": 1.6, "tame": 4, "back": 11.0},
	"cow": {"ride_speed": 1.3, "tame": 3, "back": 14.0},
}
## что говорят звери героине в облике зверя
const BEAST_TALK: Array = [
	"Ты пахнешь травами. Ты точно не человек?", "Видела, где растут грибы? Я — да. Но не скажу.", "Тут недавно пробегала лиса. Очень важная.",
	"Если пойдёт дождь — прячься под ёлку. Проверено.", "Самые вкусные ягоды — у старого пня. Только тс-с!", "Люди такие большие и шумные...",
	"Ой, а ты новенькая в лесу? Добро пожаловать!", "Ночью тут ходит кто-то со светящимися глазами. Наверное, сова.",
	"У меня сегодня отличный день: я нашла жёлудь!", "Говорят, у травницы на опушке вкусная морковка.", "Хочешь, побегаем наперегонки?",
	"Зимой я сплю. Летом тоже сплю. Иногда ем.", "Вон за тем холмом — водопой. Вода холодная-холодная.", "Не ходи в тёмную пещеру, там шуршит.",
]
const BEAST_KIND_TALK: Dictionary = {
	"fox": "Я не хитрая. Я — предусмотрительная.", "rabbit": "Морковка! У тебя есть морковка?", "wolf": "Стая — это семья. Ты теперь тоже немножко наша.",
	"bear": "Мёд. Где-то рядом мёд. Я чую.", "hedgehog": "Фыр! Не трогай колючки, я просто так.", "squirrel": "Я спрятала сто орехов. Где — не помню.",
	"horse": "Хочешь, прокачу? Только сначала угости яблочком.", "unicorn": "Мой рог светится, когда рядом добрые люди. Сейчас светится.",
	"capybara": "Всё хорошо. Всё спокойно. Садись рядом.", "frog": "Ква. Ква-ква. Это значит «привет».", "owl": "Угу.",
	"raccoon": "Я не ворую. Я одалживаю навсегда.", "beaver": "Плотину видела? Это я построил. Сам.", "cat": "Мяу. Ты понимаешь меня? Наконец-то!",
}

var main: Node2D
var hud: CanvasLayer
var v23: Node
var pony: Node
var ui: CanvasLayer
var spell_mode: bool = false
var orbs: Array = []
var cast_cd: float = 0.0
var hud_root: Control
var slot_spr: Array = []
var key_icons: Array = []
var mana_bar: ColorRect
var mana_back: ColorRect
var name_lbl: Label
var grim_root: Control
var grim_list: VBoxContainer
var move_root: Control
var projs: Array = []                # [{node, vel, dmg, fx, life, seek, aoe, col}]
var auras: Array = []                # [{t, dmg, r, col, tick}]
var rider: Sprite2D
var mount_spr: Sprite2D
var form_spr: Sprite2D
var ride_dist: float = 0.0
var ride_left: bool = true
var companion: Node2D = null
var comp_t: float = 2.0
var light: PointLight2D = null
var talk_seen: Object = null
var intro_t: float = 3.0
var t: float = 0.0


func setup(m: Node2D, h: CanvasLayer) -> void:
	main = m
	hud = h
	add_to_group("v25")
	v23 = m.get_node("V23")
	pony = m.get_node_or_null("Pony25")
	ui = CanvasLayer.new()
	ui.layer = 32
	add_child(ui)
	_build_hud()
	_build_grimoire()
	_build_move()
	var w: Node2D = m.get("world")
	(w.get("region_hooks") as Array).append(Callable(self, "_region"))
	if Game.shape_form != "":
		Game.shape_form = ""


# ================================================================== интерфейс: сферы и сила

func _build_hud() -> void:
	hud_root = Control.new()
	hud_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_root.visible = false
	ui.add_child(hud_root)
	var pn: Control = v23.call("_panel", hud_root, Rect2(610, 905, 700, 150))
	pn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# три гнезда для сфер
	for i in range(3):
		var bg: ColorRect = ColorRect.new()
		bg.color = Color(0.08, 0.06, 0.12, 0.7)
		bg.position = Vector2(30 + i * 58, 20)
		bg.size = Vector2(52, 52)
		pn.add_child(bg)
		var s: TextureRect = TextureRect.new()
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		s.position = Vector2(36 + i * 58, 26)
		s.size = Vector2(40, 40)
		s.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pn.add_child(s)
		slot_spr.append(s)
	# восемь стихий с цифрами
	for k in range(8):
		var el: String = SP.ORDER[k]
		var ic: TextureRect = TextureRect.new()
		ic.texture = SP.icon(el)
		ic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.position = Vector2(220 + (k % 4) * 116, 14 + (k / 4) * 48)
		ic.size = Vector2(30, 30)
		pn.add_child(ic)
		var l: Label = v23.call("_label", pn, "%d %s" % [k + 1, String((SP.EL[el] as Array)[0])], "font_body", 15, Color("f0e6d0"))
		l.position = Vector2(252 + (k % 4) * 116, 18 + (k / 4) * 48)
		key_icons.append([ic, l, el])
	mana_back = ColorRect.new()
	mana_back.color = Color(0.1, 0.08, 0.16, 0.9)
	mana_back.position = Vector2(30, 84)
	mana_back.size = Vector2(640, 14)
	pn.add_child(mana_back)
	mana_bar = ColorRect.new()
	mana_bar.color = Color("6a8af0")
	mana_bar.position = Vector2(30, 84)
	mana_bar.size = Vector2(640, 14)
	pn.add_child(mana_bar)
	name_lbl = v23.call("_label", pn, "", "font_title", 22, Color("f0d89a"))
	name_lbl.position = Vector2(30, 104)
	name_lbl.size = Vector2(640, 30)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func _update_hud() -> void:
	hud_root.visible = spell_mode and not Game.ui_open
	if not hud_root.visible:
		return
	for i in range(3):
		(slot_spr[i] as TextureRect).texture = SP.icon(String(orbs[i])) if i < orbs.size() else null
	for e in key_icons:
		var open: bool = Game.orbs_open.has(String(e[2]))
		(e[0] as TextureRect).modulate = Color.WHITE if open else Color(0.25, 0.25, 0.3, 0.6)
		(e[1] as Label).modulate = Color.WHITE if open else Color(0.5, 0.5, 0.5, 0.6)
	mana_bar.size.x = 640.0 * Game.mana / MANA_MAX
	if orbs.is_empty():
		name_lbl.text = "Сферы: 1-8 · произнести: %s или ПКМ · гримуар: %s" % [KB.key_name("cast"), KB.key_name("grimoire")]
	else:
		var sp: Array = SP.spell_of(orbs)
		var known: bool = Game.spells_known.has(SP.key_of(orbs))
		name_lbl.text = (String(sp[1]) if (not sp.is_empty() and known) else ("??? — попробуй!" if not sp.is_empty() else "Смесь стихий")) + "  ·  сила %d" % _cost(orbs)


# ================================================================== ввод

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey) and not (event is InputEventMouseButton):
		return
	if not bool(main.get("playing")) and not OS.get_cmdline_user_args().has("--test"):
		return
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if spell_mode and mb.pressed and mb.button_index == MOUSE_BUTTON_RIGHT and not Game.ui_open:
			cast()
			get_viewport().set_input_as_handled()
		return
	var k: InputEventKey = event
	if not k.pressed or k.echo:
		return
	var kc: int = k.physical_keycode
	if grim_root.visible:
		if kc == KEY_ESCAPE or KB.is_key("grimoire", kc):
			toggle_grimoire()
			get_viewport().set_input_as_handled()
		return
	if move_root.visible:
		if kc == KEY_ESCAPE or KB.is_key("move_home", kc):
			_close_move()
			get_viewport().set_input_as_handled()
		return
	if Game.ui_open or Game.busy:
		return
	if KB.is_key("spell_mode", kc):
		spell_mode = not spell_mode
		orbs.clear()
		Sound.play("ui_click", -6.0)
		get_viewport().set_input_as_handled()
	elif KB.is_key("grimoire", kc):
		toggle_grimoire()
		get_viewport().set_input_as_handled()
	elif KB.is_key("ride", kc):
		toggle_ride()
		get_viewport().set_input_as_handled()
	elif KB.is_key("move_home", kc):
		open_move()
		get_viewport().set_input_as_handled()
	elif spell_mode and kc >= KEY_1 and kc <= KEY_8:
		add_orb(String(SP.ORDER[kc - KEY_1]))
		get_viewport().set_input_as_handled()
	elif spell_mode and KB.is_key("cast", kc):
		cast()
		get_viewport().set_input_as_handled()


# ================================================================== сферы и заклинания

## Положить сферу: противоположная гасит последнюю противницу, больше трёх — самая старая уходит
func add_orb(el: String) -> bool:
	if not Game.orbs_open.has(el):
		Sound.play("spell_fizzle", -10.0)
		Game.toast.emit("Стихия «%s» ещё закрыта: %s" % [String((SP.EL[el] as Array)[0]), String((SP.EL[el] as Array)[2])], SP.icon(el))
		return false
	var op: String = String(SP.OPPOSE.get(el, ""))
	if op != "" and orbs.has(op):
		orbs.erase(op)
		Sound.play("spell_fizzle", -12.0)
		_burst(_pp() + Vector2(0, -30), (SP.EL[el] as Array)[1], 8, 30.0)
		return true
	orbs.append(el)
	if orbs.size() > 3:
		orbs.pop_front()
	Sound.play("orb_add", -12.0, 0.1)
	return true


func _cost(o: Array) -> int:
	var sp: Array = SP.spell_of(o)
	return int(sp[3]) if not sp.is_empty() else 8 * o.size()


func _pl() -> Node2D:
	return main.get("player") as Node2D


func _pp() -> Vector2:
	return _pl().global_position


func _aim() -> Vector2:
	var d: Vector2 = main.get_global_mouse_position() - (_pp() + Vector2(0, -14))
	if d.length() < 4.0:
		d = Vector2(-1, 0) if int(_pl().get("facing")) in [2, 4, 5] else Vector2(1, 0)
	return d.normalized()


## Произнести то, что лежит в очереди сфер
func cast() -> bool:
	if orbs.is_empty() or cast_cd > 0.0:
		return false
	var cost: int = _cost(orbs)
	if Game.mana < cost and not Game.god_mode:
		Sound.play("spell_fizzle", -6.0)
		Game.toast.emit("Не хватает силы. Она понемногу возвращается сама.", SP.icon(String(orbs[0])))
		return false
	var key: String = SP.key_of(orbs)
	var sp: Array = SP.spell_of(orbs)
	if not Game.god_mode:
		Game.mana -= cost
	cast_cd = 0.35
	var main_el: String = String(orbs[orbs.size() - 1])
	Sound.play("cast_" + main_el, -4.0, 0.1)
	_pl().call("react", "happy", 0.6)
	if not sp.is_empty() and not Game.spells_known.has(key):
		Game.spells_known[key] = Game.day
		Game.toast.emit("Новое заклинание: %s!" % String(sp[1]), SP.icon(main_el))
		Game.chron("Нашла заклинание «%s»." % String(sp[1]), "magic")
	var used: Array = orbs.duplicate()
	orbs.clear()
	if sp.is_empty():
		_generic(used)
	else:
		do_spell(String(sp[0]), used)
	return true


func _col(o: Array) -> Color:
	var c: Color = Color(0, 0, 0)
	for e in o:
		c += (SP.EL[String(e)] as Array)[1]
	return c / float(maxi(1, o.size()))


## Неизвестное сочетание — снаряд цвета смеси, сила по числу сфер
func _generic(o: Array) -> void:
	var fx: String = ""
	if o.has("fire"):
		fx = "fire"
	elif o.has("cold"):
		fx = "frost"
	elif o.has("arcane"):
		fx = "void"
	_bolt(_aim(), 6.0 * o.size() + 2.0, fx, _col(o), 240.0, 0.0, false)


func do_spell(id: String, o: Array) -> void:
	var pp: Vector2 = _pp()
	var aim: Vector2 = _aim()
	var col: Color = _col(o)
	match id:
		"splash":
			_cone(aim, 90.0, 0.7, 4.0, "", col)
			_water_plots(pp + aim * 50.0, 80.0)
		"heal":
			_heal(25.0, 0.15)
		"shield":
			_shield(8.0)
		"frost":
			_cone(aim, 90.0, 0.7, 6.0, "frost", col)
		"spark":
			_bolt(aim, 10.0, "", col, 420.0)
		"beam":
			_bolt(aim, 14.0, "void", col, 520.0)
		"rock":
			_bolt(aim, 12.0, "", col, 200.0)
		"flame":
			_cone(aim, 80.0, 0.6, 9.0, "fire", col)
		"rain":
			_rain(7.0)
			_water_plots(pp, 420.0)
			_regrow(pp, 420.0, 0.5)
		"great_heal":
			_heal(100.0, 1.0)
		"dome":
			_shield(20.0)
		"blizzard":
			_nova(170.0, 6.0, "frost", col)
		"chain":
			var hit: int = 0
			for mn in _monsters_sorted(pp, 380.0):
				if hit >= 4:
					break
				(mn as Node).call("take_hit", 12.0, pp, "")
				_line(pp + Vector2(0, -20), (mn as Node2D).global_position + Vector2(0, -10), col)
				hit += 1
		"blast":
			_nova(130.0, 18.0, "void", col)
		"quake":
			_nova(210.0, 6.0, "sleep", col)
			_shake_trees(pp, 260.0)
		"fireball":
			_bolt(aim, 22.0, "fire", col, 300.0, 70.0)
		"living_water":
			_grow_plots(pp, 320.0, 1)
			_regrow(pp, 320.0, 1.0)
		"bubble":
			_shield(10.0)
			_heal(10.0, 0.05)
		"ice_shards":
			for a in [-0.25, 0.0, 0.25]:
				_bolt(aim.rotated(float(a)), 8.0, "frost", col, 380.0)
		"mud":
			_nova(150.0, 0.0, "frost", Color("6a4a2a"))
		"pull":
			_pull(pp, 360.0)
		"steam":
			var n: int = Game.get_count("water_cold") + Game.get_count("water_warm")
			if n > 0:
				for wid in ["water_cold", "water_warm"]:
					var c: int = Game.get_count(wid)
					if c > 0:
						Game.take_item(wid, c)
						Game.add_item("water_hot", c)
				Game.toast.emit("Вода в бутылочках закипела: %d шт." % n, load("res://art/fx_heart.png"))
			_burst(pp + Vector2(0, -20), Color(1, 1, 1, 0.8), 30, 60.0)
		"ward":
			Game.spell_regen = 30.0
		"fresh":
			Game.fatigue = maxf(0.0, Game.fatigue - 0.3)
			_burst(pp + Vector2(0, -24), col, 20, 40.0)
		"haste":
			Game.spell_speed = 30.0
		"bloom":
			_bloom(pp, 160.0)
			_regrow(pp, 260.0, 0.8)
		"warm_light":
			Game.spell_light = 90.0
		"ice_armor":
			_shield(12.0)
			_nova(90.0, 4.0, "frost", col)
		"storm_shield":
			_shield(10.0)
			auras.append({"t": 10.0, "dmg": 5.0, "r": 60.0, "col": col, "tick": 0.0, "fx": ""})
		"mirror":
			_shield(15.0)
		"stone_skin":
			_shield(25.0)
			Game.spell_speed = -25.0
		"fire_aura":
			auras.append({"t": 8.0, "dmg": 6.0, "r": 80.0, "col": col, "tick": 0.0, "fx": "fire"})
		"ice_bolt":
			_bolt(aim, 16.0, "frost", col, 420.0)
		"star_frost":
			_nova(150.0, 10.0, "frost", col)
		"boulder":
			_bolt(aim, 20.0, "frost", col, 180.0, 40.0)
		"blink":
			_blink(aim, 140.0)
		"thunder":
			_nova(130.0, 12.0, "sleep", col)
		"ball_lightning":
			_bolt(aim, 20.0, "", col, 160.0, 0.0, true)
		"rune_stones":
			for a2 in [-0.3, 0.0, 0.3]:
				_bolt(aim.rotated(float(a2)), 10.0, "void", col, 260.0)
		"arcane_flame":
			_cone(aim, 140.0, 0.35, 16.0, "fire", col)
		"meteor":
			_meteor(main.get_global_mouse_position(), 26.0, 70.0)
		"storm":
			_rain(10.0)
			_water_plots(pp, 620.0)
			_regrow(pp, 620.0, 1.0)
			for mn2 in _monsters_sorted(pp, 400.0):
				(mn2 as Node).call("take_hit", 20.0, pp, "")
				_line((mn2 as Node2D).global_position + Vector2(0, -200), (mn2 as Node2D).global_position, Color("e0d0ff"))
		"garden":
			_grow_plots(pp, 420.0, 9)
			_water_plots(pp, 420.0)
			_regrow(pp, 420.0, 1.0)
			_bloom(pp, 200.0)
		"call_mount":
			call_mount()
		"beast_form":
			toggle_form()
		"home":
			main.call("teleport_to", Game.home_pos + Vector2(0, 60))
		"far_blink":
			_blink(aim, 380.0)
		"fortress":
			_shield(40.0)
		"starfall":
			var mp: Vector2 = main.get_global_mouse_position()
			for i in range(6):
				var off: Vector2 = Vector2(randf_range(-120, 120), randf_range(-80, 80))
				get_tree().create_timer(0.15 * i).timeout.connect(func() -> void: _meteor(mp + off, 18.0, 50.0))
		"winter":
			_nova(320.0, 8.0, "frost", col)
			for mn3 in _monsters_sorted(pp, 320.0):
				(mn3 as Node).set("stun_t", 4.0)
		"rebirth":
			_heal(100.0, 1.0)
			Game.spell_regen = 60.0
		"animal_call":
			_animal_call(pp, 520.0)
		"hot_spring":
			Game.fatigue = 0.0
			_burst(pp + Vector2(0, -16), Color(1, 1, 1, 0.8), 40, 70.0)
		"dew":
			var b: int = Game.get_count("bottle")
			if b > 0:
				Game.take_item("bottle", b)
				Game.add_item("water_cold", b)
				Game.toast.emit("Бутылочки наполнились росой: %d шт." % b, load("res://art/fx_heart.png"))
			_burst(pp + Vector2(0, -20), col, 24, 50.0)
		"healing_bubble":
			_shield(15.0)
			Game.spell_regen = 30.0
		"firestorm":
			_nova(200.0, 20.0, "fire", col)
		"big_meteor":
			_meteor(main.get_global_mouse_position(), 40.0, 110.0)


# ------------------------------------------------------------------ действия заклинаний

func _monsters_sorted(at: Vector2, r: float) -> Array:
	var out: Array = []
	for m in get_tree().get_nodes_in_group("monsters23"):
		var mn: Node2D = m as Node2D
		if mn.global_position.distance_to(at) <= r:
			out.append(mn)
	out.sort_custom(func(a, b): return (a as Node2D).global_position.distance_to(at) < (b as Node2D).global_position.distance_to(at))
	return out


func _cone(dir: Vector2, reach: float, half: float, dmg: float, fx: String, col: Color) -> void:
	var pp: Vector2 = _pp()
	for mn in _monsters_sorted(pp, reach):
		var d: Vector2 = (mn as Node2D).global_position - pp
		if absf(d.angle_to(dir)) < half:
			if dmg > 0.0:
				(mn as Node).call("take_hit", dmg, pp, fx)
			else:
				(mn as Node).set("knock", d.normalized() * 160.0)
	var p: CPUParticles2D = _particles(pp + Vector2(0, -16), col, 40, 0.6)
	p.direction = dir
	p.spread = rad_to_deg(half)
	p.initial_velocity_min = reach * 0.9
	p.initial_velocity_max = reach * 1.5
	p.gravity = Vector2.ZERO


func _nova(r: float, dmg: float, fx: String, col: Color) -> void:
	var pp: Vector2 = _pp()
	for mn in _monsters_sorted(pp, r):
		if dmg > 0.0:
			(mn as Node).call("take_hit", dmg, pp, fx)
		elif fx == "frost":
			(mn as Node).set("slow_t", 5.0)
	var p: CPUParticles2D = _particles(pp + Vector2(0, -10), col, 60, 0.7)
	p.spread = 180.0
	p.initial_velocity_min = r * 0.9
	p.initial_velocity_max = r * 1.3
	p.gravity = Vector2.ZERO
	p.damping_min = r * 0.6
	p.damping_max = r * 0.9


func _bolt(dir: Vector2, dmg: float, fx: String, col: Color, speed: float, aoe: float = 0.0, seek: bool = false) -> void:
	var s: Sprite2D = Sprite2D.new()
	s.texture = load("res://art/fx_orb25.png")
	s.modulate = col
	s.scale = Vector2(1.4, 1.4) if aoe > 0.0 else Vector2(1.0, 1.0)
	s.z_index = 40
	s.global_position = _pp() + Vector2(0, -16)
	(main.get("objects") as Node).add_child(s)
	var tr: CPUParticles2D = CPUParticles2D.new()
	tr.texture = load("res://art/fx_orb25.png")
	tr.amount = 14
	tr.lifetime = 0.35
	tr.local_coords = false
	tr.gravity = Vector2.ZERO
	tr.scale_amount_min = 0.4
	tr.scale_amount_max = 0.8
	tr.color = col
	tr.color_ramp = _fade()
	s.add_child(tr)
	projs.append({"node": s, "vel": dir * speed, "dmg": dmg, "fx": fx, "life": 1.6, "aoe": aoe, "seek": seek, "col": col})


func _meteor(at: Vector2, dmg: float, r: float) -> void:
	var s: Sprite2D = Sprite2D.new()
	s.texture = load("res://art/orb25_fire.png")
	s.z_index = 40
	s.global_position = at + Vector2(-80, -260)
	(main.get("objects") as Node).add_child(s)
	var tw: Tween = create_tween()
	tw.tween_property(s, "global_position", at, 0.45).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void:
		s.queue_free()
		Sound.play("cast_earth", -4.0, 0.1, at)
		for mn in _monsters_sorted(at, r):
			(mn as Node).call("take_hit", dmg, at, "fire")
		var p: CPUParticles2D = _particles(at, Color("f08a2a"), 50, 0.6)
		p.spread = 180.0
		p.initial_velocity_min = r * 0.8
		p.initial_velocity_max = r * 1.4
		p.gravity = Vector2(0, 120))


func _line(a: Vector2, b: Vector2, col: Color) -> void:
	var l: Line2D = Line2D.new()
	var pts: PackedVector2Array = PackedVector2Array()
	for i in range(7):
		var k: float = float(i) / 6.0
		var q: Vector2 = a.lerp(b, k)
		if i > 0 and i < 6:
			q += Vector2(randf_range(-7, 7), randf_range(-7, 7))
		pts.append(q)
	l.points = pts
	l.width = 2.0
	l.default_color = col.lightened(0.4)
	l.z_index = 41
	(main.get("objects") as Node).add_child(l)
	var tw: Tween = create_tween()
	tw.tween_property(l, "modulate:a", 0.0, 0.35)
	tw.tween_callback(l.queue_free)


func _heal(hp: float, fat: float) -> void:
	Game.hp = minf(100.0, Game.hp + hp)
	Game.fatigue = maxf(0.0, Game.fatigue - fat)
	_burst(_pp() + Vector2(0, -24), Color("8af0a0"), 26, 40.0)
	Game.fx.emit(_pp() + Vector2(0, -44), "heart")


func _shield(sec: float) -> void:
	Game.spell_shield = maxf(Game.spell_shield, sec)


func _blink(dir: Vector2, dist: float) -> void:
	var pl: Node2D = _pl()
	var best: Vector2 = pl.position
	var k: float = dist
	while k > 10.0:
		var q: Vector2 = pl.position + dir * k
		if not bool(main.call("is_blocked", q)):
			best = q
			break
		k -= 20.0
	_burst(pl.global_position + Vector2(0, -20), Color("f05ab0"), 24, 40.0)
	pl.position = best
	_burst(pl.global_position + Vector2(0, -20), Color("b070f0"), 24, 40.0)


func _water_plots(at: Vector2, r: float) -> void:
	var n: int = 0
	for p in get_tree().get_nodes_in_group("plots"):
		var pn: Node2D = p as Node2D
		if pn.global_position.distance_to(at) <= r and String(pn.get("crop")) != "" and not bool(pn.get("watered")):
			pn.set("watered", true)
			pn.call("refresh")
			n += 1
	if n > 0:
		Game.fx.emit(at, "water")


func _grow_plots(at: Vector2, r: float, steps: int) -> void:
	for p in get_tree().get_nodes_in_group("plots"):
		var pn: Node2D = p as Node2D
		if pn.global_position.distance_to(at) <= r and String(pn.get("crop")) != "":
			pn.set("stage", mini(3, int(pn.get("stage")) + steps))
			pn.set("watered", true)
			pn.call("refresh")
			Game.fx.emit(pn.global_position + Vector2(0, -10), "leaves")


## Пустые места трав снова растят травы (только сегодня)
func _regrow(at: Vector2, r: float, chance: float) -> void:
	for h in get_tree().get_nodes_in_group("herb_spots25"):
		var hn: Node2D = h as Node2D
		if hn.global_position.distance_to(at) > r or randf() > chance:
			continue
		if (hn.get("today") as Array).is_empty() and not (hn.get("options") as Array).is_empty():
			var rr: RandomNumberGenerator = RandomNumberGenerator.new()
			rr.randomize()
			var id: String = String(hn.call("_pick", rr))
			if id != "":
				hn.set("today", [id, id])
				Game.picked.erase(String(hn.get("key")))
				hn.call("_make_sprites")
				Game.fx.emit(hn.global_position + Vector2(0, -8), "leaves")


func _bloom(at: Vector2, r: float) -> void:
	var objs: Node = main.get("objects")
	for i in range(14):
		var a: float = randf() * TAU
		var q: Vector2 = at + Vector2(cos(a), sin(a) * 0.6) * randf_range(30.0, r)
		if bool(main.call("is_blocked", q)):
			continue
		var s: Sprite2D = Sprite2D.new()
		s.texture = load("res://art/%s.png" % ["flowers_pink", "flowers_blue", "flowers_white", "flowers_yellow"][i % 4])
		s.centered = false
		s.offset = Vector2(-s.texture.get_width() / 2.0, -s.texture.get_height())
		s.position = q
		s.scale = Vector2(0.1, 0.1)
		objs.add_child(s)
		var tw: Tween = create_tween()
		tw.tween_property(s, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK)
		tw.tween_interval(240.0)
		tw.tween_property(s, "modulate:a", 0.0, 3.0)
		tw.tween_callback(s.queue_free)


func _shake_trees(at: Vector2, r: float) -> void:
	var tall: Dictionary = (main.get("world") as Node).get("tall")
	var c0: Vector2i = Vector2i(int(floor(at.x / 256.0)), int(floor(at.y / 256.0)))
	var got: int = 0
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			for sv in tall.get(c0 + Vector2i(dx, dy), []):
				if is_instance_valid(sv) and (sv as Node2D).global_position.distance_to(at) < r:
					Game.fx.emit((sv as Node2D).global_position + Vector2(0, -60), "leaves")
					got += 1
	if got > 0:
		Game.add_item("twig", mini(got, 4))
		Game.add_item("stick", mini(got / 2, 2))


func _pull(at: Vector2, r: float) -> void:
	var n: int = 0
	for g in get_tree().get_nodes_in_group("interactables"):
		var gn: Node2D = g as Node2D
		if gn == null or gn.global_position.distance_to(at) > r:
			continue
		if gn.is_in_group("ground_items") or String(gn.get_script().resource_path).ends_with("feather_drop.gd"):
			gn.call("interact")
			n += 1
	if n > 0:
		Game.toast.emit("Притянула вещей: %d" % n, load("res://art/fx_heart.png"))


func _animal_call(at: Vector2, r: float) -> void:
	var n: int = 0
	for a in get_tree().get_nodes_in_group("animals"):
		var an: Node2D = a as Node2D
		if an.global_position.distance_to(at) > r:
			continue
		var k: String = String(an.get("kind"))
		an.set("fleeing", 0.0)
		an.set("goal", at + Vector2(randf_range(-50, 50), randf_range(10, 40)))
		an.set("moving", true)
		Game.trust[k] = int(Game.trust.get(k, 0)) + 1
		if not Game.forms_known.has(k):
			Game.forms_known.append(k)
		n += 1
	Game.toast.emit("Звери услышали зов: %d" % n, load("res://art/fx_heart.png"))


func _rain(sec: float) -> void:
	var p: CPUParticles2D = CPUParticles2D.new()
	p.texture = load("res://art/fx_drop.png")
	p.amount = 160
	p.lifetime = 0.9
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(340, 10)
	p.position = Vector2(0, -260)
	p.direction = Vector2(0.1, 1)
	p.spread = 4.0
	p.initial_velocity_min = 260.0
	p.initial_velocity_max = 320.0
	p.gravity = Vector2.ZERO
	p.z_index = 46
	p.modulate = Color(0.75, 0.85, 1.0, 0.8)
	_pl().add_child(p)
	Sound.play("cast_water", -6.0)
	get_tree().create_timer(sec).timeout.connect(func() -> void:
		p.emitting = false
		get_tree().create_timer(1.0).timeout.connect(p.queue_free))


func _fade() -> Gradient:
	var g: Gradient = Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	return g


func _particles(at: Vector2, col: Color, n: int, life: float) -> CPUParticles2D:
	var p: CPUParticles2D = CPUParticles2D.new()
	p.texture = load("res://art/fx_orb25.png")
	p.one_shot = true
	p.explosiveness = 0.95
	p.amount = n
	p.lifetime = life
	p.global_position = at
	p.color = col
	p.color_ramp = _fade()
	p.scale_amount_min = 0.3
	p.scale_amount_max = 0.9
	p.z_index = 45
	(main.get("objects") as Node).add_child(p)
	p.emitting = true
	get_tree().create_timer(life + 0.5).timeout.connect(p.queue_free)
	return p


func _burst(at: Vector2, col: Color, n: int, spd: float) -> void:
	var p: CPUParticles2D = _particles(at, col, n, 0.8)
	p.spread = 180.0
	p.initial_velocity_min = spd * 0.4
	p.initial_velocity_max = spd
	p.gravity = Vector2(0, -20)


# ================================================================== кадр

func _process(delta: float) -> void:
	t += delta
	var pl: Node2D = _pl()
	if pl == null:
		return
	cast_cd = maxf(0.0, cast_cd - delta)
	Game.mana = minf(MANA_MAX, Game.mana + delta * (5.0 if not Game.night_factor() > 0.6 else 7.0))
	# временные чары
	for k in ["spell_shield", "spell_regen", "spell_light"]:
		var v: float = float(Game.get(k))
		if v > 0.0:
			Game.set(k, maxf(0.0, v - delta))
	if Game.spell_speed > 0.0:
		Game.spell_speed = maxf(0.0, Game.spell_speed - delta)
	elif Game.spell_speed < 0.0:
		Game.spell_speed = minf(0.0, Game.spell_speed + delta)
	if Game.spell_regen > 0.0:
		Game.hp = minf(100.0, Game.hp + delta * 3.0)
		Game.fatigue = maxf(0.0, Game.fatigue - delta * 0.004)
	_update_speed(pl)
	_update_shield(pl, delta)
	_update_light(pl)
	_update_projs(delta)
	_update_auras(delta)
	_update_hud()
	_watch_talk()
	# в домах, подземельях и под водой верхом не ездят и зверем не бегают
	var away: bool = bool(main.get("inside")) or main.get("visiting") != null or pl.global_position.y > 90000.0 or pl.global_position.y < -150000.0 or pl.global_position.x > 150000.0 or pl.global_position.x < -50000.0
	if away:
		if Game.riding:
			dismount(false)
		if Game.shape_form != "":
			end_form()
	if Game.shape_form != "":
		Game.shape_t -= delta
		if Game.shape_t <= 0.0:
			end_form()
	_companion_tick(delta, away)
	if intro_t > 0.0:
		intro_t -= delta
		if intro_t <= 0.0 and Game.spells_known.is_empty() and bool(main.get("playing")):
			Game.toast.emit("У тебя есть Книга сфер! %s — режим заклинаний, %s — гримуар." % [KB.key_name("spell_mode"), KB.key_name("grimoire")], load("res://art/icon_spellbook25.png"))


func _update_speed(pl: Node2D) -> void:
	var m: float = 1.0
	if Game.riding:
		m = _mount_speed(Game.mount_kind) * (0.75 if bool(pl.get("running")) else 1.0)
	elif Game.shape_form != "":
		m = clampf(float((W.ANIMALS.get(Game.shape_form, {}) as Dictionary).get("speed", 40.0)) / 40.0, 0.4, 1.6)
	if Game.spell_speed > 0.0:
		m *= 1.4
	elif Game.spell_speed < 0.0:
		m *= 0.8
	pl.set("speed_mul", m)


var shield_spr: Sprite2D = null


func _update_shield(pl: Node2D, delta: float) -> void:
	if Game.spell_shield > 0.0:
		if shield_spr == null or not is_instance_valid(shield_spr):
			shield_spr = Sprite2D.new()
			shield_spr.texture = load("res://art/fx_orb25.png")
			shield_spr.scale = Vector2(6.0, 7.0)
			shield_spr.position = Vector2(0, -26)
			shield_spr.z_index = 30
			pl.add_child(shield_spr)
		shield_spr.modulate = Color(1.0, 0.9, 0.5, 0.28 + sin(t * 4.0) * 0.06 if Game.spell_shield > 2.0 else 0.15 + 0.15 * float(int(t * 8.0) % 2))
	elif shield_spr != null and is_instance_valid(shield_spr):
		shield_spr.queue_free()
		shield_spr = null


func _update_light(pl: Node2D) -> void:
	if Game.spell_light > 0.0:
		if light == null or not is_instance_valid(light):
			light = PointLight2D.new()
			var gt: GradientTexture2D = GradientTexture2D.new()
			gt.fill = GradientTexture2D.FILL_RADIAL
			gt.fill_from = Vector2(0.5, 0.5)
			gt.fill_to = Vector2(1.0, 0.5)
			gt.width = 256
			gt.height = 256
			gt.gradient = _fade()
			light.texture = gt
			light.texture_scale = 2.4
			light.energy = 0.9
			light.color = Color(1.0, 0.85, 0.6)
			light.position = Vector2(0, -20)
			pl.add_child(light)
	elif light != null and is_instance_valid(light):
		light.queue_free()
		light = null


func _update_projs(delta: float) -> void:
	for i in range(projs.size() - 1, -1, -1):
		var pr: Dictionary = projs[i]
		var s: Sprite2D = pr["node"]
		if not is_instance_valid(s):
			projs.remove_at(i)
			continue
		pr["life"] = float(pr["life"]) - delta
		if bool(pr["seek"]):
			var near: Array = _monsters_sorted(s.global_position, 300.0)
			if not near.is_empty():
				var to: Vector2 = ((near[0] as Node2D).global_position + Vector2(0, -10) - s.global_position).normalized()
				pr["vel"] = (pr["vel"] as Vector2).lerp(to * (pr["vel"] as Vector2).length(), minf(1.0, delta * 4.0))
		s.global_position += (pr["vel"] as Vector2) * delta
		var hit: bool = false
		for mn in _monsters_sorted(s.global_position + Vector2(0, 12), 22.0):
			(mn as Node).call("take_hit", float(pr["dmg"]), s.global_position, String(pr["fx"]))
			hit = true
			break
		if hit or float(pr["life"]) <= 0.0:
			var aoe: float = float(pr["aoe"])
			if aoe > 0.0:
				for mn2 in _monsters_sorted(s.global_position, aoe):
					(mn2 as Node).call("take_hit", float(pr["dmg"]) * 0.6, s.global_position, String(pr["fx"]))
				var p: CPUParticles2D = _particles(s.global_position, pr["col"], 40, 0.5)
				p.spread = 180.0
				p.initial_velocity_min = aoe
				p.initial_velocity_max = aoe * 1.4
			else:
				_burst(s.global_position, pr["col"], 10, 40.0)
			s.queue_free()
			projs.remove_at(i)


func _update_auras(delta: float) -> void:
	for i in range(auras.size() - 1, -1, -1):
		var a: Dictionary = auras[i]
		a["t"] = float(a["t"]) - delta
		a["tick"] = float(a["tick"]) - delta
		if float(a["tick"]) <= 0.0:
			a["tick"] = 1.0
			for mn in _monsters_sorted(_pp(), float(a["r"])):
				(mn as Node).call("take_hit", float(a["dmg"]), _pp(), String(a["fx"]))
			var p: CPUParticles2D = _particles(_pp() + Vector2(0, -10), a["col"], 20, 0.6)
			p.spread = 180.0
			p.initial_velocity_min = float(a["r"]) * 0.6
			p.initial_velocity_max = float(a["r"])
		if float(a["t"]) <= 0.0:
			auras.remove_at(i)


## разговор с пони — дружба (для стихии «Тайна»)
func _watch_talk() -> void:
	var dlg: Node = get_tree().get_first_node_in_group("dialog_ui")
	if dlg == null:
		return
	var npc: Object = dlg.get("npc")
	if npc == talk_seen:
		return
	talk_seen = npc
	if npc != null and is_instance_valid(npc) and pony != null:
		pony.call("met", String(npc.get("tex_name")))


# ================================================================== звери: приручение, езда, облик

func _mount_speed(kind: String) -> float:
	var a: Dictionary = W.ANIMALS.get(kind, {})
	if a.has("ride_speed"):
		return float(a["ride_speed"])
	return float((MOUNT_EXTRA.get(kind, {}) as Dictionary).get("ride_speed", 1.8))


func _tame_need(kind: String) -> int:
	var a: Dictionary = W.ANIMALS.get(kind, {})
	if a.has("tame"):
		return int(a["tame"])
	return int((MOUNT_EXTRA.get(kind, {}) as Dictionary).get("tame", 4))


func _back(kind: String) -> float:
	var a: Dictionary = W.ANIMALS.get(kind, {})
	if a.has("back"):
		return float(a["back"])
	return float((MOUNT_EXTRA.get(kind, {}) as Dictionary).get("back", 18.0))


func can_ride(kind: String) -> bool:
	return W.rideable(kind) or MOUNT_EXTRA.has(kind)


func animal_prompt(an: Node2D) -> String:
	var kind: String = String(an.get("kind"))
	if Game.shape_form != "":
		return "Поговорить"
	if an == companion:
		return "Сесть верхом (%s)" % KB.key_name("ride")
	if can_ride(kind) and Game.held().begins_with("food_") and not Game.mounts.has(kind):
		return "Угостить (доверие %d/%d)" % [int(Game.trust.get(kind, 0)), _tame_need(kind)]
	return ""


## E по зверю: в облике зверя — разговор, свой скакун — сесть, еда в руке — приручение скакуна
func animal_interact(an: Node2D) -> bool:
	var kind: String = String(an.get("kind"))
	if Game.shape_form != "":
		var line: String = String(BEAST_KIND_TALK.get(kind, BEAST_TALK.pick_random()))
		if randf() < 0.4:
			line = String(BEAST_TALK.pick_random())
		Game.toast.emit("%s: «%s»" % [String((W.ANIMALS.get(kind, {}) as Dictionary).get("name", kind)), line], load("res://art/fx_heart.png"))
		an.set("happy_t", 1.4)
		Game.trust[kind] = int(Game.trust.get(kind, 0)) + 0
		return true
	if an == companion:
		mount()
		return true
	var held: String = Game.held()
	if can_ride(kind) and held.begins_with("food_") and not Game.mounts.has(kind):
		if not Game.take_item(held):
			return false
		var fm: Node = get_tree().get_first_node_in_group("farm23")
		var liked: bool = fm != null and bool(fm.call("likes", kind, held))
		Game.trust[kind] = int(Game.trust.get(kind, 0)) + (2 if liked else 1)
		an.set("happy_t", 1.4)
		an.set("fleeing", 0.0)
		Game.fx.emit(an.global_position + Vector2(0, -30), "heart")
		var need: int = _tame_need(kind)
		var nm: String = String((W.ANIMALS.get(kind, {}) as Dictionary).get("name", kind))
		if int(Game.trust[kind]) >= need:
			Game.mounts.append(kind)
			if companion != null and is_instance_valid(companion):
				companion.queue_free()
			Game.mount_kind = kind
			_adopt(an)
			Sound.play("magic", -4.0)
			Game.toast.emit("%s приручен(а)! Подойди и нажми %s — сесть верхом." % [nm, KB.key_name("ride")], load("res://art/fx_heart.png"))
			Game.chron("Приручила скакуна: %s." % nm.to_lower(), "farm")
		else:
			Game.toast.emit("%s доверяет тебе чуть больше (%d/%d)%s" % [nm, int(Game.trust[kind]), need, " — любимое угощение!" if liked else ""], load("res://art/fx_heart.png"))
		return true
	return false


## этот зверь теперь твой скакун: ходит следом
func _adopt(an: Node2D) -> void:
	companion = an
	an.set_meta("mount25", true)
	an.set("follow", true)
	an.set("roam", 30.0)
	var info: Dictionary = (an.get("info") as Dictionary).duplicate()
	info["shy"] = false
	an.set("info", info)
	var objs: Node = main.get("objects")
	if an.get_parent() != objs:
		var keep: Vector2 = an.global_position
		an.get_parent().remove_child(an)
		objs.add_child(an)
		an.global_position = keep


func _spawn_companion(at: Vector2) -> void:
	if Game.mount_kind == "" or not ResourceLoader.exists("res://art/animal_%s.png" % Game.mount_kind):
		return
	var a: Node2D = Node2D.new()
	a.set_script(load("res://animal.gd"))
	(main.get("objects") as Node).add_child(a)
	a.call("setup", Game.mount_kind, at)
	a.set("blocked", Callable(main, "is_blocked"))
	main.call("add_caster", a.get("spr") as Sprite2D, true)
	_adopt(a)


func _companion_tick(delta: float, away: bool) -> void:
	if Game.mount_kind == "" or Game.riding or away:
		return
	if companion != null and is_instance_valid(companion):
		# отстал совсем — догоняет «тропинкой»
		if companion.global_position.distance_to(_pp()) > 900.0:
			companion.global_position = _pp() + Vector2(-40, 20)
		return
	comp_t -= delta
	if comp_t <= 0.0:
		comp_t = 2.0
		_spawn_companion(_pp() + Vector2(-50, 24))


func call_mount() -> void:
	if Game.mount_kind == "":
		Game.toast.emit("Пока нет скакуна. Приручи коня, единорога или другого зверя угощениями.", load("res://art/fx_heart.png"))
		return
	if companion != null and is_instance_valid(companion):
		companion.global_position = _pp() + Vector2(-40, 20)
	else:
		_spawn_companion(_pp() + Vector2(-40, 20))
	Sound.play(String((W.ANIMALS.get(Game.mount_kind, {}) as Dictionary).get("sound", "magic")), -4.0)


func toggle_ride() -> void:
	if Game.riding:
		dismount(true)
		return
	if companion != null and is_instance_valid(companion) and companion.global_position.distance_to(_pp()) < 90.0:
		mount()
	elif Game.mount_kind != "":
		Game.toast.emit("Скакун далеко. Подойди к нему или позови заклинанием «Зов скакуна».", load("res://art/fx_heart.png"))
	else:
		Game.toast.emit("Скакуна пока нет: держи еду в руке и угощай коня, единорога, лося, медведя...", load("res://art/fx_heart.png"))


func mount() -> void:
	if Game.riding or Game.mount_kind == "":
		return
	if Game.shape_form != "":
		end_form()
	var pl: Node2D = _pl()
	if companion != null and is_instance_valid(companion):
		pl.position = companion.global_position
		companion.queue_free()
		companion = null
	Game.riding = true
	var hero: Sprite2D = pl.get("sprite")
	hero.visible = false
	rider = Sprite2D.new()
	rider.centered = false
	rider.texture = AtlasTexture.new()
	rider.scale = hero.scale
	pl.add_child(rider)
	mount_spr = Sprite2D.new()
	mount_spr.texture = load("res://art/animal_%s.png" % Game.mount_kind)
	mount_spr.hframes = FRAMES_A
	mount_spr.centered = false
	var fw: float = float(mount_spr.texture.get_width()) / FRAMES_A
	var fh: float = float(mount_spr.texture.get_height())
	mount_spr.offset = Vector2(-fw / 2.0, -fh + 2.0)
	mount_spr.scale = Vector2(RIDE_SCALE, RIDE_SCALE)
	pl.add_child(mount_spr)
	pl.set("form_hook", Callable(self, "_ride_hook"))
	Sound.play(String((W.ANIMALS.get(Game.mount_kind, {}) as Dictionary).get("sound", "neigh")), -4.0)


func dismount(spawn: bool) -> void:
	if not Game.riding:
		return
	Game.riding = false
	var pl: Node2D = _pl()
	(pl.get("sprite") as Sprite2D).visible = true
	pl.set("form_hook", Callable())
	if rider != null:
		rider.queue_free()
		rider = null
	if mount_spr != null:
		mount_spr.queue_free()
		mount_spr = null
	if spawn:
		var at: Vector2 = pl.global_position
		pl.position += Vector2(24 if ride_left else -24, 6)
		if bool(main.call("is_blocked", pl.position)):
			pl.position = at
		_spawn_companion(at)


func _ride_hook(_frame: int, moved: float, _delta: float) -> void:
	var pl: Node2D = _pl()
	var vel: Vector2 = pl.get("vel")
	if absf(vel.x) > 4.0:
		ride_left = vel.x < 0.0
	pl.set("facing", 2 if ride_left else 3)
	ride_dist += moved
	var hero: Sprite2D = pl.get("sprite")
	var fl: int = 0
	var walking: bool = moved > 0.02
	if walking:
		fl = int(ride_dist / (9.0 if vel.length() < 150.0 else 14.0)) % 4
	else:
		fl = 5 if fmod(Time.get_ticks_msec() / 1000.0, 3.2) < 0.15 else 4
	mount_spr.frame = fl
	mount_spr.flip_h = not ride_left
	# всадница: верх кадра стойки (до середины бедра), сидит на спине скакуна
	var at: AtlasTexture = rider.texture
	at.atlas = hero.texture
	var row: int = 2 if ride_left else 3
	at.region = Rect2(4 * 80, row * 160, 80, 104)
	rider.offset = Vector2(-40, -157)
	var bob: float = (-1.0 if fl % 2 == 1 else 0.0) if walking else 0.0
	var back: float = _back(Game.mount_kind) * RIDE_SCALE / 0.5
	rider.position = Vector2(4.0 if ride_left else -4.0, -(back - 8.0) + 53.0 * hero.scale.y + bob)


## Облик зверя (заклинание жизнь+земля+земля): выбранный в гримуаре или последний поглаженный
func toggle_form() -> void:
	if Game.shape_form != "":
		end_form()
		return
	var f: String = Game.form_pick if Game.forms_known.has(Game.form_pick) else String(Game.forms_known[Game.forms_known.size() - 1])
	start_form(f)


func start_form(kind: String) -> void:
	if not ResourceLoader.exists("res://art/animal_%s.png" % kind):
		return
	if Game.riding:
		dismount(true)
	var pl: Node2D = _pl()
	Game.shape_form = kind
	Game.shape_t = 180.0
	(pl.get("sprite") as Sprite2D).visible = false
	form_spr = Sprite2D.new()
	form_spr.texture = load("res://art/animal_%s.png" % kind)
	form_spr.hframes = FRAMES_A
	form_spr.centered = false
	var fw: float = float(form_spr.texture.get_width()) / FRAMES_A
	var fh: float = float(form_spr.texture.get_height())
	form_spr.offset = Vector2(-fw / 2.0, -fh + 2.0)
	form_spr.scale = Vector2(0.5, 0.5)
	pl.add_child(form_spr)
	pl.set("form_hook", Callable(self, "_form_hook"))
	_burst(pl.global_position + Vector2(0, -16), Color("8af0a0"), 40, 60.0)
	Game.toast.emit("Облик зверя: %s. Звери тебя понимают — нажми E рядом с ними." % String((W.ANIMALS.get(kind, {}) as Dictionary).get("name", kind)), load("res://art/fx_heart.png"))


func end_form() -> void:
	if Game.shape_form == "":
		return
	Game.shape_form = ""
	var pl: Node2D = _pl()
	(pl.get("sprite") as Sprite2D).visible = true
	pl.set("form_hook", Callable())
	if form_spr != null:
		form_spr.queue_free()
		form_spr = null
	_burst(pl.global_position + Vector2(0, -24), Color("8af0a0"), 30, 50.0)


func _form_hook(frame: int, moved: float, _delta: float) -> void:
	var pl: Node2D = _pl()
	var vel: Vector2 = pl.get("vel")
	if absf(vel.x) > 4.0:
		ride_left = vel.x < 0.0
	ride_dist += moved
	if moved > 0.02:
		form_spr.frame = int(ride_dist / 6.0) % 4
	elif frame >= 4 and frame <= 7:
		var it: float = fmod(Time.get_ticks_msec() / 1000.0, 9.0)
		form_spr.frame = 6 + int(it * 5.0) % 4 if it > 6.0 else (5 if fmod(it, 3.1) < 0.15 else 4)
	else:
		form_spr.frame = 4
	form_spr.flip_h = not ride_left


# ================================================================== алтари стихий в мире

func _region(node: Node2D, r: Vector2i) -> void:
	for el in SP.ALTARS.keys():
		var p: Vector2 = SP.ALTARS[el]
		if WD.region_of(p) == r:
			var w: Node2D = main.get("world")
			w.call("reserve", Rect2(p - Vector2(60, 90), Vector2(120, 120)))
			var a: Node2D = Node2D.new()
			a.set_script(load("res://altar25.gd"))
			node.add_child(a)
			a.call("setup", String(el), p)
			w.call("add_block", p + Vector2(0, -6), 14.0)


# ================================================================== гримуар (H)

func _build_grimoire() -> void:
	grim_root = Control.new()
	grim_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	grim_root.visible = false
	grim_root.mouse_filter = Control.MOUSE_FILTER_STOP
	ui.add_child(grim_root)
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	grim_root.add_child(dim)
	var pn: Control = v23.call("_panel", grim_root, Rect2(310, 70, 1300, 940))
	var ttl: Label = v23.call("_label", pn, "Гримуар сфер", "font_title", 40, Color("f0d89a"))
	ttl.position = Vector2(0, 18)
	ttl.size = Vector2(1300, 50)
	ttl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var sc: ScrollContainer = ScrollContainer.new()
	sc.position = Vector2(40, 84)
	sc.size = Vector2(1220, 820)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	pn.add_child(sc)
	grim_list = VBoxContainer.new()
	grim_list.custom_minimum_size = Vector2(1200, 0)
	grim_list.add_theme_constant_override("separation", 6)
	sc.add_child(grim_list)


func toggle_grimoire() -> void:
	grim_root.visible = not grim_root.visible
	Game.ui_open = grim_root.visible
	Sound.play("ui_click", -6.0)
	if grim_root.visible:
		_fill_grimoire()


func _row(icons: Array, text: String, col: Color, size: int = 20) -> HBoxContainer:
	var h: HBoxContainer = HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	for ic in icons:
		var tr: TextureRect = TextureRect.new()
		tr.texture = ic
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.custom_minimum_size = Vector2(28, 28)
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		h.add_child(tr)
	var l: Label = v23.call("_label", h, text, "font_body", size, col)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(1100 - icons.size() * 34, 0)
	return h


func _fill_grimoire() -> void:
	for c in grim_list.get_children():
		c.queue_free()
	var head: Label = v23.call("_label", grim_list, "Стихии (в режиме заклинаний %s — клавиши 1-8). Противоположные гасят друг друга: огонь—холод, вода—молния, жизнь—тайна." % KB.key_name("spell_mode"), "font_body", 19, Color("d8c8a8"))
	head.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	head.custom_minimum_size = Vector2(1180, 0)
	for i in range(8):
		var el: String = SP.ORDER[i]
		var open: bool = Game.orbs_open.has(el)
		grim_list.add_child(_row([SP.icon(el)], "%d · %s — %s" % [i + 1, String((SP.EL[el] as Array)[0]), "открыта" if open else "закрыта: " + String((SP.EL[el] as Array)[2])], Color("f0e6d0") if open else Color("8a8090")))
	var total: int = SP.SPELLS.size()
	var sep: Label = v23.call("_label", grim_list, "\nЗаклинания: найдено %d из %d. Пробуй сочетания из 1-3 сфер — неизвестные тоже работают!" % [Game.spells_known.size(), total], "font_title", 26, Color("f0d89a"))
	sep.custom_minimum_size = Vector2(1180, 0)
	for key in SP.SPELLS.keys():
		var sp: Array = SP.SPELLS[key]
		var ics: Array = []
		for e in String(key).split("+"):
			ics.append(SP.icon(String(e)))
		if Game.spells_known.has(key):
			grim_list.add_child(_row(ics, "%s — %s (сила %d)" % [String(sp[1]), String(sp[2]), int(sp[3])], Color("f0e6d0"), 18))
		else:
			var hidden: Array = []
			for k in range(ics.size()):
				hidden.append(load("res://art/fx_orb25.png"))
			grim_list.add_child(_row(hidden, "??? — ещё не найдено (%d сферы)" % ics.size(), Color("6a6478"), 18))
	# облики зверей: клик — выбрать
	var fl: Label = v23.call("_label", grim_list, "\nОблик зверя (заклинание Жизнь+Земля+Земля). Погладь зверя — и узнаешь его облик. Нажми, чтобы выбрать:", "font_title", 24, Color("f0d89a"))
	fl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fl.custom_minimum_size = Vector2(1180, 0)
	var flow: HFlowContainer = HFlowContainer.new()
	flow.custom_minimum_size = Vector2(1180, 0)
	grim_list.add_child(flow)
	for f in Game.forms_known:
		var b: Button = v23.call("_button", flow, ("● " if Game.form_pick == f else "") + String((W.ANIMALS.get(f, {}) as Dictionary).get("name", f)), func() -> void:
			Game.form_pick = String(f)
			_fill_grimoire(), 17)
		b.custom_minimum_size = Vector2(0, 34)
	var ml: Label = v23.call("_label", grim_list, "\nСкакуны: %s. Как приручить: возьми еду в руку, подойди шагом (не бегом) и угощай (E). Любимая еда — вдвое быстрее. %s — сесть и слезть." % [", ".join(PackedStringArray(Game.mounts.map(func(k): return String((W.ANIMALS.get(k, {}) as Dictionary).get("name", k))))) if not Game.mounts.is_empty() else "пока нет", KB.key_name("ride")], "font_body", 19, Color("d8c8a8"))
	ml.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ml.custom_minimum_size = Vector2(1180, 0)
	var rl: Array = []
	for k2 in W.ANIMALS.keys():
		if can_ride(String(k2)):
			rl.append("%s (%d)" % [String((W.ANIMALS[k2] as Dictionary)["name"]), _tame_need(String(k2))])
	var rlab: Label = v23.call("_label", grim_list, "На ком можно ездить (сколько угощений): " + ", ".join(PackedStringArray(rl)), "font_body", 17, Color("b8a888"))
	rlab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rlab.custom_minimum_size = Vector2(1180, 0)
	if Game.mounts.size() > 1:
		var flow2: HFlowContainer = HFlowContainer.new()
		flow2.custom_minimum_size = Vector2(1180, 0)
		grim_list.add_child(flow2)
		for mk in Game.mounts:
			v23.call("_button", flow2, ("● " if Game.mount_kind == mk else "") + "Скакун: " + String((W.ANIMALS.get(mk, {}) as Dictionary).get("name", mk)), func() -> void:
				if Game.riding:
					dismount(false)
				if companion != null and is_instance_valid(companion):
					companion.queue_free()
				companion = null
				Game.mount_kind = String(mk)
				comp_t = 0.1
				_fill_grimoire(), 17)


# ================================================================== переезд (P)

func _build_move() -> void:
	move_root = Control.new()
	move_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	move_root.visible = false
	move_root.mouse_filter = Control.MOUSE_FILTER_STOP
	ui.add_child(move_root)
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	move_root.add_child(dim)


func open_move() -> void:
	for c in move_root.get_children():
		if c is Control and not (c is ColorRect):
			c.queue_free()
	var pn: Control = v23.call("_panel", move_root, Rect2(460, 90, 1000, 900))
	var ttl: Label = v23.call("_label", pn, "Переезд", "font_title", 40, Color("f0d89a"))
	ttl.position = Vector2(0, 18)
	ttl.size = Vector2(1000, 50)
	ttl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var info: Label = v23.call("_label", pn, "Надоело жить в одном краю? Повозка перевезёт дом, сундуки, грядки, постройки и зверей из загона. Стоит %d монет (у тебя %d). " % [MOVE_COST, Game.coins], "font_body", 20, Color("e8dcc4"))
	info.position = Vector2(40, 74)
	info.size = Vector2(920, 60)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var v: VBoxContainer = VBoxContainer.new()
	v.position = Vector2(60, 150)
	v.size = Vector2(880, 700)
	v.add_theme_constant_override("separation", 6)
	pn.add_child(v)
	for key in SCN.SPAWN_ORDER:
		var sp: Dictionary = SCN.SPAWNS.get(key, {})
		if sp.is_empty() or String(key) == Game.home_biome:
			continue
		var b: Button = v23.call("_button", v, "%s — %s" % [String(sp.get("name", key)), String(sp.get("text", ""))], func() -> void: relocate(String(key)), 18)
		b.custom_minimum_size = Vector2(880, 32)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	move_root.visible = true
	Game.ui_open = true


func _close_move() -> void:
	move_root.visible = false
	Game.ui_open = false


## Переехать: дом встаёт на новое место, всё нажитое сдвигается вместе с ним
func relocate(key: String) -> bool:
	if Game.coins < MOVE_COST and not Game.god_mode:
		Game.toast.emit("Нужно %d монет на повозку." % MOVE_COST, load("res://art/fx_heart.png"))
		return false
	if not Game.god_mode:
		Game.coins -= MOVE_COST
	if Game.riding:
		dismount(false)
	end_form()
	var old: Vector2 = Game.home_pos
	var np: Vector2 = SCN.find_home(key)
	var d: Vector2 = (np - old).round()
	var w: Dictionary = main.call("save_world")
	var pl: Array = []
	for p in (w.get("placed", []) as Array):
		pl.append([String(p[0]), (p[1] as Vector2) + d])
	w["placed"] = pl
	for pd in (w.get("plots", []) as Array):
		(pd as Dictionary)["pos"] = ((pd as Dictionary)["pos"] as Vector2) + d
	w["player"] = np + Vector2(0, 60)
	w["inside"] = false
	# сундуки и звери в загонах — по координатам
	var ch: Dictionary = {}
	for ck in Game.chests.keys():
		var parts: PackedStringArray = String(ck).split(",")
		if parts.size() == 2:
			ch["%d,%d" % [int(parts[0]) + int(d.x), int(parts[1]) + int(d.y)]] = Game.chests[ck]
		else:
			ch[ck] = Game.chests[ck]
	Game.chests = ch
	for fa in Game.farm:
		if fa is Dictionary and (fa as Dictionary).has("x"):
			(fa as Dictionary)["x"] = float((fa as Dictionary)["x"]) + d.x
			(fa as Dictionary)["y"] = float((fa as Dictionary)["y"]) + d.y
	Game.home_pos = np
	Game.home_biome = key
	Game.moved_times += 1
	Game.chron("Переехала: %s." % String((SCN.SPAWNS.get(key, {}) as Dictionary).get("name", key)), "start")
	move_root.visible = false
	Game.ui_open = false
	if OS.get_cmdline_user_args().has("--test"):
		return true
	Saves.pending_world = w
	Saves.loaded = true
	get_tree().reload_current_scene()
	return true

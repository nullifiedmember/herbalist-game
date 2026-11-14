extends Node2D
## Костёр у дома (v16). Горит, пока есть дрова: E с бревном — подкинуть (одно бревно ≈ 4 игровых часа, до 12).
## E с бутылочками воды, пока горит — поставить до 3 бутылочек на огонь; E ещё раз — снять.
## На огне вода греется: тёплая через ~20 с, горячая через ~45 с. Без дров огонь гаснет — вода остывает обратно.
## Ночью костёр светит вокруг.

const LOG_HOURS: float = 4.0
const MAX_HOURS: float = 12.0
const WARM_T: float = 20.0
const HOT_T: float = 45.0

var fuel: float = 0.0                 # игровых часов горения
var pots: Array = []                  # [[температура 0..2, сек на огне]]
var interact_offset: Vector2 = Vector2(0, -14)
var fire: CPUParticles2D
var smoke: CPUParticles2D
var glow: Sprite2D
var t: float = 0.0
var icons: Dictionary = {}


func _ready() -> void:
	add_to_group("interactables")
	add_to_group("campfires")
	for k in ["water_cold", "water_warm", "water_hot"]:
		icons[k] = load("res://art/icon_%s.png" % k)
	fire = CPUParticles2D.new()
	fire.texture = load("res://art/fx_soft.png")
	fire.amount = 26
	fire.lifetime = 0.7
	fire.position = Vector2(0, -10)
	fire.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	fire.emission_rect_extents = Vector2(6, 2)
	fire.direction = Vector2(0, -1)
	fire.spread = 12.0
	fire.gravity = Vector2(0, -40)
	fire.initial_velocity_min = 8.0
	fire.initial_velocity_max = 22.0
	fire.scale_amount_min = 0.06
	fire.scale_amount_max = 0.13
	var g: Gradient = Gradient.new()
	g.set_color(0, Color(1.0, 0.95, 0.6, 1.0))
	g.set_color(1, Color(0.9, 0.2, 0.05, 0.0))
	g.add_point(0.4, Color(1.0, 0.55, 0.15, 0.9))
	fire.color_ramp = g
	var add: CanvasItemMaterial = CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	fire.material = add
	fire.z_index = 5
	add_child(fire)
	smoke = CPUParticles2D.new()
	smoke.texture = load("res://art/fx_soft.png")
	smoke.amount = 8
	smoke.lifetime = 2.6
	smoke.position = Vector2(0, -26)
	smoke.direction = Vector2(0.2, -1)
	smoke.spread = 15.0
	smoke.gravity = Vector2(4, -8)
	smoke.initial_velocity_min = 6.0
	smoke.initial_velocity_max = 12.0
	smoke.scale_amount_min = 0.1
	smoke.scale_amount_max = 0.25
	var sg: Gradient = Gradient.new()
	sg.set_color(0, Color(0.6, 0.6, 0.6, 0.0))
	sg.set_color(1, Color(0.6, 0.6, 0.6, 0.0))
	sg.add_point(0.3, Color(0.55, 0.55, 0.55, 0.35))
	smoke.color_ramp = sg
	smoke.z_index = 6
	add_child(smoke)
	glow = Sprite2D.new()
	glow.texture = load("res://art/fx_glow.png")
	glow.position = Vector2(0, -12)
	glow.material = add
	glow.z_index = 4
	add_child(glow)


func burning() -> bool:
	return fuel > 0.0


## Сколько света даёт костёр (для ночной тьмы): радиус в пикселях мира
func light_radius() -> float:
	return 0.0 if fuel <= 0.0 else 70.0 + 50.0 * clampf(fuel / 4.0, 0.0, 1.0)


func get_prompt() -> String:
	return ""


func _water_in_bag() -> String:
	for k in ["water_cold", "water_warm"]:
		if Game.get_count(k) > 0:
			return k
	return ""


## Готовка на огне: сперва рыба (жарится целиком), иначе первый рецепт, на который хватает продуктов
func _cook() -> String:
	var FD = preload("res://food_db.gd")
	for fid in preload("res://fish_db.gd").ORDER:
		if Game.get_count(String(fid)) > 0:
			Game.take_item(String(fid))
			Game.add_item("food_grilled_fish")
			Game.cooked["food_grilled_fish"] = true
			return "cook"
	var rc: Dictionary = FD.find_recipe(func(rid: String) -> int: return Game.get_count(rid))
	if rc.is_empty():
		return ""
	for nd in rc["need"]:
		Game.take_item(String(nd[0]), int(nd[1]))
	Game.add_item(String(rc["res"]))
	Game.cooked[String(rc["res"])] = true
	return "cook"


func interact() -> String:
	if not pots.is_empty():
		for p in pots:
			var tp: float = float(p[0])
			Game.add_item("water_cold" if tp < 0.5 else ("water_warm" if tp < 1.5 else "water_hot"))
		pots.clear()
		queue_redraw()
		return "take"
	if burning():
		var cooked: String = _cook()
		if cooked != "":
			Sound.play("fire", -6.0)
			Game.fx.emit(global_position + Vector2(0, -30), "steam")
			get_tree().call_group("player", "react", "happy", 1.2)
			return cooked
	if burning() and _water_in_bag() != "":
		while pots.size() < 3:
			var w: String = _water_in_bag()
			if w == "":
				break
			Game.take_item(w)
			pots.append([0.0 if w == "water_cold" else 1.0, 0.0])
		Sound.play("pickup", -6.0)
		queue_redraw()
		return "put"
	if Game.get_count("log") > 0 and fuel < MAX_HOURS - 1.0:
		Game.take_item("log")
		fuel = minf(MAX_HOURS, fuel + LOG_HOURS)
		Sound.play("fire", -4.0)
		Game.fx.emit(global_position + Vector2(0, -16), "dust")
		return "log"
	get_tree().call_group("player", "react", "sad", 1.0)
	return ""


func _process(delta: float) -> void:
	t += delta
	if fuel > 0.0 and not Game.time_frozen:
		fuel = maxf(0.0, fuel - delta * Game.MIN_PER_SEC / 60.0)
	var on: bool = fuel > 0.0
	var k: float = clampf(fuel / 4.0, 0.25, 1.0) if on else 0.0
	fire.emitting = on
	fire.amount = 14 + int(k * 18.0)
	smoke.emitting = on or fmod(t, 6.0) < 0.1
	glow.visible = on
	glow.scale = Vector2.ONE * (0.6 + 0.5 * k + sin(t * 9.0) * 0.04)
	glow.modulate = Color(1.0, 0.68, 0.32, (0.35 + 0.45 * Game.night_factor()) * k)
	# вода на огне
	for p in pots:
		p[1] = float(p[1]) + delta
		if on:
			var tgt: float = 2.0 if float(p[1]) >= HOT_T else (1.0 if float(p[1]) >= WARM_T else float(p[0]))
			p[0] = maxf(float(p[0]), tgt)
		else:
			p[1] = 0.0
	if not pots.is_empty():
		queue_redraw()


func _draw() -> void:
	# перекладина над огнём и бутылочки на ней; горячие парят
	if pots.is_empty():
		return
	draw_line(Vector2(-16, -30), Vector2(16, -30), Color("4a2e1c"), 2.0)
	draw_line(Vector2(-16, -30), Vector2(-14, -8), Color("3a2414"), 2.0)
	draw_line(Vector2(16, -30), Vector2(14, -8), Color("3a2414"), 2.0)
	for i in range(pots.size()):
		var tp: float = float(pots[i][0])
		var key: String = "water_cold" if tp < 0.5 else ("water_warm" if tp < 1.5 else "water_hot")
		var x: float = -12.0 + float(i) * 12.0 - 6.0
		draw_texture_rect(icons[key], Rect2(x, -44, 12, 12), false)
		if tp >= 1.5:
			for j in range(2):
				var sy: float = fmod(t * 10.0 + float(j) * 6.0, 12.0)
				draw_rect(Rect2(x + 5 + sin(t * 3.0 + j) * 1.5, -46 - sy, 1, 1), Color(1, 1, 1, 0.6 * (1.0 - sy / 12.0)))

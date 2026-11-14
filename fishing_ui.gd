extends CanvasLayer
const V23D = preload("res://v23_data.gd")
## Рыбалка. Ни одной надписи: всё видно по картинке.
## E — бросить (прицел ходит по воде туда-сюда: чем дальше, тем глубже), A/D — повернуть удочку.
## Поплавок дёрнулся — E, потом E в зелёной полосе. Esc — смотать удочку.
## Чем дальше от берега, тем глубже: у берега клюёт редко и мелочь, на глубине чаще и крупнее.

const FDB = preload("res://fish_db.gd")
const LAY = preload("res://world_layout.gd")
const FX = preload("res://fishing_fx.gd")

enum S { IDLE, AIM, CAST, WAIT, BITE, REEL, CATCH, FAIL, BACK }

const MIN_DIST: float = 10.0
const MAX_DIST: float = 250.0
const DARK: Color = Color("3a2718")
const TAN: Color = Color("c4a478")

var state: int = S.IDLE
var spot: Node2D
var fx: Node2D
var canvas: Control
var panel: NinePatchRect
var shore_p: Vector2 = Vector2.ZERO
var aim_a: float = 0.0              # поворот в сторону от центра пруда
var aim_u: float = 0.0              # где прицел на шкале дальности 0..1
var t_state: float = 0.0
var t_aim: float = 0.0
var wait_left: float = 0.0
var will_bite: bool = false
var depth: float = 0.0
var bite_left: float = 0.0
var reel_t: float = 0.0
var fish_id: String = ""
var zone_c: float = 0.5
var zone_w: float = 0.25
var fish_speed: float = 1.0


func _ready() -> void:
	layer = 12
	panel = NinePatchRect.new()
	panel.texture = load("res://art/ui_panel.png")
	panel.patch_margin_left = 12
	panel.patch_margin_top = 12
	panel.patch_margin_right = 12
	panel.patch_margin_bottom = 12
	panel.scale = Vector2(2, 2)
	panel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.visible = false
	add_child(panel)
	canvas = Control.new()
	canvas.size = Vector2(1920, 1080)
	canvas.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.draw.connect(_draw_canvas)
	add_child(canvas)
	fx = Node2D.new()
	fx.set_script(FX)
	fx.set("ui", self)
	fx.visible = false
	get_parent().add_child.call_deferred(fx)


func is_open() -> bool:
	return state != S.IDLE


func open(sp: Node2D) -> void:
	if Game.busy or Game.ui_open or state != S.IDLE or not Game.rod_ok():
		return
	spot = sp
	Game.ui_open = true
	var pl: Node2D = get_tree().get_first_node_in_group("player")
	shore_p = pl.global_position
	aim_a = 0.0
	t_aim = 0.0
	_set_state(S.AIM)
	_face()


func close() -> void:
	if state == S.IDLE:
		return
	state = S.IDLE
	Game.ui_open = false
	panel.visible = false
	canvas.queue_redraw()


func _set_state(s: int) -> void:
	state = s
	t_state = 0.0
	panel.visible = s == S.REEL or s == S.CATCH
	if s == S.REEL:
		panel.position = Vector2(480, 790)
		panel.size = Vector2(480, 80)
	elif s == S.CATCH:
		panel.position = Vector2(822, 730)
		panel.size = Vector2(138, 138)


## Куда смотрит удочка: к центру пруда плюс поворот
func aim_dir() -> Vector2:
	if spot != null and bool(spot.get("sea")):
		return (spot.global_position - shore_p).normalized().rotated(aim_a)
	return (LAY.POND_C - shore_p).normalized().rotated(aim_a)


## v23: море у пирса — вода ниже берега и не на самом пирсе
func _sea_water(p: Vector2) -> bool:
	if p.y < 7592.0 + 24.0:
		return false
	var wld: Node = get_tree().current_scene.get("world")
	if wld != null:
		for wr in (wld.get("walk_rects") as Array):
			if (wr as Rect2).has_point(p):
				return false
	return true


func aim_dist() -> float:
	return lerpf(MIN_DIST, MAX_DIST, aim_u)


func landing() -> Vector2:
	return shore_p + aim_dir() * aim_dist()


## Глубина в точке: 0 — суша или самый берег, 1 — середина пруда
static func depth_at(p: Vector2) -> float:
	var pv: float = LAY.pond_value(p)
	if pv >= -0.03:
		return 0.0
	return clampf(-pv / 0.85, 0.0, 1.0)


static func is_water(p: Vector2) -> bool:
	return LAY.pond_value(p) < -0.03


## Героиня поворачивается лицом, куда смотрит удочка
func _face() -> void:
	var pl: Node = get_tree().get_first_node_in_group("player")
	if pl == null:
		return
	var best: int = 0
	var best_d: float = -2.0
	var dirs: Array = pl.get("FACE_DIRS")
	var ad: Vector2 = aim_dir()
	for i in range(dirs.size()):
		var d: float = (dirs[i] as Vector2).dot(ad)
		if d > best_d:
			best_d = d
			best = i
	pl.set("facing", best)
	pl.set("want_facing", best)


func cast() -> void:
	if state != S.AIM:
		return
	_set_state(S.CAST)


func _land() -> void:
	var p: Vector2 = landing()
	var sea_spot: bool = spot != null and bool(spot.get("sea"))
	if not (_sea_water(p) if sea_spot else is_water(p)):
		_set_state(S.BACK)
		return
	depth = clampf((p.y - 7592.0) / 420.0, 0.1, 1.0) if sea_spot else depth_at(p)
	will_bite = randf() < FDB.bite_chance(depth)
	wait_left = randf_range(1.8, 4.5)
	Game.fx.emit(p, "water")
	_set_state(S.WAIT)


func _process(delta: float) -> void:
	if state == S.IDLE:
		return
	t_state += delta
	match state:
		S.AIM:
			t_aim += delta
			aim_u = pingpong(t_aim * 0.75, 1.0)
			var turn: float = 0.0
			if KB.down("move_left"):
				turn -= 1.0
			if KB.down("move_right"):
				turn += 1.0
			if turn != 0.0:
				aim_a = clampf(aim_a + turn * delta * 1.2, -0.8, 0.8)
				_face()
		S.CAST:
			if t_state >= 0.55:
				_land()
		S.WAIT:
			wait_left -= delta
			if wait_left <= 0.0:
				if will_bite:
					_bite()
				else:
					_set_state(S.BACK)
		S.BITE:
			bite_left -= delta
			if bite_left <= 0.0:
				_set_state(S.BACK)
		S.REEL:
			reel_t += delta
			if reel_t > 7.0:
				_fail()
		S.CATCH:
			if t_state > 2.0:
				close()
		S.FAIL, S.BACK:
			if t_state >= 0.5:
				close()
	canvas.queue_redraw()


func _bite() -> void:
	if spot != null and bool(spot.get("sea")):
		fish_id = FDB.roll_sea(Game.hour(), randf(), depth)
	else:
		fish_id = FDB.roll(Game.hour(), randf(), depth)
	bite_left = 1.1
	_set_state(S.BITE)
	Game.fx.emit(landing(), "water")


func marker() -> float:
	return pingpong(reel_t * 0.9 * fish_speed, 1.0)


func press() -> void:
	match state:
		S.AIM:
			cast()
		S.WAIT:
			_set_state(S.BACK)
		S.BITE:
			var d: Dictionary = FDB.DATA[fish_id]
			zone_w = float(d["zone"]) * (1.0 + Game.stat("fish") / 100.0)
			fish_speed = float(d["speed"])
			zone_c = randf_range(zone_w / 2.0 + 0.08, 1.0 - zone_w / 2.0 - 0.08)
			reel_t = 0.0
			_set_state(S.REEL)
		S.REEL:
			if absf(marker() - zone_c) <= zone_w / 2.0:
				_catch()
			else:
				_fail()
		S.CATCH:
			close()


func _catch() -> void:
	# v23: говорящая рыба не ловится — она сама заводит разговор
	if V23D.TALKING.has(fish_id):
		_set_state(S.BACK)
		var s23: Node = get_tree().get_first_node_in_group("sea23")
		if s23 != null:
			s23.call("talk", fish_id)
		return
	_set_state(S.CATCH)
	Game.add_item(fish_id)
	Game.fx.emit(landing(), "water")
	get_tree().call_group("player", "react", "happy", 2.5)


func _fail() -> void:
	_set_state(S.FAIL)
	get_tree().call_group("player", "react", "sad", 1.5)


func _input(event: InputEvent) -> void:
	if state == S.IDLE or not (event is InputEventKey):
		return
	var k: InputEventKey = event
	if not k.pressed or k.echo:
		return
	if KB.is_key("interact", k.physical_keycode) or k.physical_keycode == KEY_SPACE:
		press()
		get_viewport().set_input_as_handled()
	elif k.physical_keycode == KEY_ESCAPE:
		close()
		get_viewport().set_input_as_handled()


func _blk(r: Rect2, c: Color) -> void:
	canvas.draw_rect(r, c)


func _draw_canvas() -> void:
	if state == S.REEL:
		# шкала: тёмная рамка, песочный фон, зелёная полоса, белый ползунок (всё кратно 6 пикселям)
		var bar: Rect2 = Rect2(528, 822, 384, 24)
		_blk(bar.grow(6), DARK)
		_blk(bar, TAN)
		_blk(Rect2(bar.position.x, bar.position.y, bar.size.x, 6), Color("d8c090"))
		var zw: float = roundf(zone_w * bar.size.x / 6.0) * 6.0
		var zx: float = bar.position.x + roundf((zone_c * bar.size.x - zw / 2.0) / 6.0) * 6.0
		_blk(Rect2(zx, bar.position.y, zw, bar.size.y), Color("5aa040"))
		_blk(Rect2(zx, bar.position.y, zw, 6), Color("8ad060"))
		var mx: float = bar.position.x + roundf(marker() * (bar.size.x - 12.0) / 6.0) * 6.0
		_blk(Rect2(mx - 6, bar.position.y - 12, 24, bar.size.y + 24), DARK)
		_blk(Rect2(mx, bar.position.y - 6, 12, bar.size.y + 12), Color("fdf6e0"))
	elif state == S.CATCH:
		var ic: Texture2D = FDB.icon(fish_id)
		canvas.draw_texture_rect(ic, Rect2(864, 772, 192, 192), false)

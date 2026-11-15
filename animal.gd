extends Node2D
## Зверь: бродит у своего места и занимается своими делами (кадры 6-9 листа):
## кролик роет норку, лиса охотится прыжком, олень щиплет траву, кабан роет землю пятачком,
## ёжик принюхивается, белка грызёт орешек, утка чистит пёрышки, единорог встаёт на дыбы.
## Ночью дневные звери спят (кадры 10-11), лиса и ёжик — наоборот, ночью бодрее.
## Пугливые убегают от героини; ёжик не бежит, а сворачивается клубком.
## E — погладить (если зверь ручной). Мифические звери светятся, звенят и запоминаются.

const W = preload("res://wild_db.gd")
const F25 = preload("res://fauna25_db.gd")
const FRAMES: int = 12

# занятие зверя: [звук, эффект, сдвиг эффекта (доля ширины, доля высоты), длительность от/до]
const ACTS_BASE: Dictionary = {
	"rabbit": ["squeak", "dust", Vector2(-0.4, 0.0), 2.0, 4.0],
	"sapphire_hare": ["magic", "sparkle", Vector2(-0.3, -0.5), 2.0, 3.5],
	"fox": ["sniff", "dust", Vector2(-0.5, 0.0), 1.6, 1.6],
	"ember_fox": ["fire", "sparks", Vector2(0.4, -0.6), 1.6, 1.6],
	"deer": ["", "", Vector2.ZERO, 3.0, 6.0],
	"golden_deer": ["magic", "sparkle", Vector2(-0.3, -0.3), 3.0, 6.0],
	"boar": ["grunt", "dust", Vector2(-0.5, 0.0), 2.5, 4.5],
	"hedgehog": ["sniff", "", Vector2.ZERO, 2.0, 4.0],
	"squirrel": ["squeak", "", Vector2.ZERO, 2.5, 5.0],
	"duck": ["quack", "", Vector2.ZERO, 2.0, 4.0],
	"unicorn": ["neigh", "sparkle", Vector2(-0.3, -0.8), 1.6, 1.6],
	"flat_boar": ["grunt", "", Vector2.ZERO, 1.6, 3.0],
	"chicken": ["squeak", "chaff", Vector2(0.3, 0.0), 1.2, 2.5],
	"goose": ["quack", "", Vector2.ZERO, 1.5, 3.0],
	"cow": ["grunt", "", Vector2.ZERO, 3.0, 6.0],
	"sheep": ["squeak", "", Vector2.ZERO, 3.0, 5.0],
	"goat": ["squeak", "dust", Vector2(0.4, 0.0), 2.0, 4.0],
	"pig": ["grunt", "dust", Vector2(0.4, 0.0), 2.0, 4.0],
}
const NIGHT_OWLS_BASE: Array = ["fox", "ember_fox", "hedgehog"]
static var NIGHT_OWLS: Array = NIGHT_OWLS_BASE + F25.NIGHT_OWLS

static var ACTS: Dictionary = W._merge(ACTS_BASE, F25.ACTS)

var kind: String = ""
var info: Dictionary = {}
var interact_offset: Vector2 = Vector2(0, -10)
var spr: Sprite2D
var home: Vector2
var blocked: Callable
var goal: Vector2
var moving: bool = false
var fleeing: float = 0.0
var wait_t: float = 1.0
var dist: float = 0.0
var t: float = 0.0
var happy_t: float = 0.0
var sound_t: float = 4.0
var state: String = "idle"       # idle / act / rest / curl
var state_t: float = 0.0
var hw: float = 10.0
var hh: float = 10.0
var player_ref: Node2D = null
var pets: int = 0                # сколько раз погладили (трижды — пойдёт в загон)
var follow: bool = false         # идёт за героиней в загон
var roam: float = 160.0
var sex: String = "f"            # v27: пол особи ("f" самка / "m" самец)


func setup(k: String, at: Vector2) -> void:
	kind = k
	sex = preload("res://sex27.gd").roll(k)
	info = W.ANIMALS[k]
	home = at
	position = at
	spr = Sprite2D.new()
	spr.hframes = FRAMES
	spr.centered = false
	spr.scale = Vector2(0.5, 0.5)
	add_child(spr)
	_apply_sheet("res://art/animal_%s.png" % k)
	wait_t = randf_range(0.0, 3.0)
	sound_t = randf_range(3.0, 12.0)
	if info.get("mythic", false):
		var p: CPUParticles2D = CPUParticles2D.new()
		p.texture = load("res://art/fx_firefly.png")
		p.amount = 6
		p.lifetime = 1.4
		p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		p.emission_rect_extents = Vector2(hw * 0.8, hh * 0.3)
		p.position = Vector2(0, -hh * 0.5)
		p.gravity = Vector2(0, -8)
		p.initial_velocity_max = 6.0
		var c: Color = {"sapphire_hare": Color(0.5, 0.75, 1.0), "unicorn": Color(1.0, 0.7, 0.95), "golden_deer": Color(1.0, 0.9, 0.5), "ember_fox": Color(1.0, 0.6, 0.3),
			"pegasus": Color(0.7, 0.85, 1.0), "kirin": Color(0.6, 1.0, 0.8), "nightmare": Color(0.75, 0.4, 1.0), "moon_wolf": Color(0.6, 0.85, 1.0),
			"forest_stag": Color(0.7, 1.0, 0.6), "jackalope": Color(1.0, 0.9, 0.6), "griffin": Color(1.0, 0.85, 0.5), "dragonling": Color(1.0, 0.5, 0.2),
			"salamander": Color(1.0, 0.6, 0.2), "crystal_tortoise": Color(0.6, 0.85, 1.0), "white_tiger": Color(0.8, 0.9, 1.0)}.get(k, Color.WHITE)
		p.color = c
		add_child(p)


## Лист зверя: смещение и размер тела считаются по картинке (в кадре большие прозрачные отступы)
func _apply_sheet(path: String) -> void:
	spr.texture = load(path)
	var fw: float = float(spr.texture.get_width()) / FRAMES
	var fh: float = float(spr.texture.get_height())
	spr.offset = Vector2(-fw / 2.0, -fh + 2.0)
	var used: Rect2i = Rect2i(0, 0, int(fw), int(fh))
	var img: Image = spr.texture.get_image()
	if img != null:
		if img.is_compressed():
			img.decompress()
		var ur: Rect2i = img.get_region(Rect2i(int(fw) * 4, 0, int(fw), int(fh))).get_used_rect()
		if ur.size.x > 0:
			used = ur
	hw = float(used.size.x) * 0.25
	hh = float(used.size.y) * 0.5
	interact_offset = Vector2(0, -hh * 0.6)


## Малыш: свой детский лист (жёлтые утята, полосатые кабанята…); вырос — снова взрослый
func set_baby(b: bool) -> void:
	var p: String = "res://art/animal_%s_baby.png" % kind
	if b and ResourceLoader.exists(p):
		_apply_sheet(p)
	else:
		_apply_sheet("res://art/animal_%s.png" % kind)


func _ready() -> void:
	add_to_group("interactables")
	add_to_group("animals")


func _sleepy() -> bool:
	var night: bool = Game.night_factor() > 0.6
	return night != (kind in NIGHT_OWLS)


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	t += delta
	if player_ref == null or not is_instance_valid(player_ref):
		player_ref = get_tree().get_first_node_in_group("player") as Node2D
	var pl: Node2D = player_ref
	var spd: float = float(info["speed"])
	var d: float = 9999.0
	if pl != null:
		d = pl.global_position.distance_to(global_position)
	# ёжик не убегает — сворачивается клубком
	if kind == "hedgehog" and d < 50.0 and happy_t <= 0.0 and state != "curl":
		state = "curl"
		state_t = 4.0
		moving = false
		Sound.play("sniff", -10.0, 0.2, global_position)
	# пугливые убегают, если героиня бежит рядом или подошла вплотную (кроме момента, когда их гладят)
	elif pl != null and bool(info["shy"]) and happy_t <= 0.0 and state != "rest" and not _calm(pl):
		var pl_run: bool = bool(pl.get("running"))
		if d < 55.0 or (pl_run and d < 140.0):
			fleeing = 2.0
			state = "idle"
			var away: Vector2 = (global_position - pl.global_position).normalized()
			goal = global_position + away.rotated(randf_range(-0.6, 0.6)) * 160.0
			moving = true
	if follow and pl != null and happy_t <= 0.0:
		var to_pl: Vector2 = pl.global_position - global_position
		if to_pl.length() > 34.0:
			global_position += to_pl.normalized() * minf(to_pl.length() - 30.0, maxf(spd, 70.0) * delta)
			dist += spd * delta
			spr.flip_h = to_pl.x > 0.0
			spr.frame = int(dist / 6.0) % 4
		else:
			spr.frame = 4
		return
	if happy_t > 0.0:
		happy_t -= delta
		moving = false
		spr.frame = 4
		spr.position.y = -absf(sin(happy_t * 9.0)) * 3.0
		return
	spr.position.y = 0.0
	if fleeing > 0.0:
		fleeing -= delta
		spd *= 2.4
	if moving:
		var to: Vector2 = goal - position
		var step: float = spd * delta
		if to.length() <= step:
			moving = false
			wait_t = randf_range(1.0, 4.0)
			_pick_state()
		else:
			var np: Vector2 = position + to.normalized() * step
			if blocked.is_valid() and bool(blocked.call(np)):
				moving = false
				wait_t = 0.5
			else:
				position = np
				dist += step
				spr.flip_h = to.x > 0.0
		spr.frame = int(dist / (4.0 if spd < 30.0 else 7.0)) % 4
	else:
		_still(delta, d)
	# голоса зверей рядом с героиней
	sound_t -= delta
	if sound_t <= 0.0:
		sound_t = randf_range(7.0, 18.0)
		if d < 300.0 and String(info["sound"]) != "" and state != "rest":
			Sound.play(String(info["sound"]), -14.0, 0.15, global_position)


## Стоит на месте: занимается делом, отдыхает или просто оглядывается
func _still(delta: float, d: float) -> void:
	state_t -= delta
	match state:
		"act":
			var k: int = int(t * 5.0) % 4
			spr.frame = 6 + k
			# каждый «такт» занятия — звук и эффект (земля, искры, пар)
			var a: Array = ACTS.get(kind, [])
			if not a.is_empty() and int(t * 5.0) != int((t - delta) * 5.0) and k == 1:
				var fx: String = String(a[1])
				var off: Vector2 = a[2]
				if fx != "" and randf() < 0.6:
					Game.fx.emit(global_position + Vector2(off.x * hw * 2.0 * (-1.0 if spr.flip_h else 1.0), off.y * hh * 2.0), fx)
				if String(a[0]) != "" and d < 260.0 and randf() < 0.35:
					Sound.play(String(a[0]), -16.0, 0.15, global_position)
			if state_t <= 0.0:
				state = "idle"
				wait_t = randf_range(1.0, 3.0)
		"rest", "curl":
			spr.frame = 10 + int(t * 0.8) % 2
			if state_t <= 0.0:
				if state == "rest" and _sleepy():
					state_t = randf_range(6.0, 12.0)
				else:
					state = "idle"
					wait_t = 1.0
		_:
			spr.frame = 5 if fmod(t, 3.2) < 0.15 else 4
			wait_t -= delta
			if wait_t <= 0.0:
				if _sleepy() and randf() < 0.7:
					state = "rest"
					state_t = randf_range(8.0, 16.0)
					return
				var a2: float = randf() * TAU
				goal = home + Vector2(cos(a2), sin(a2) * 0.7) * randf_range(20.0, roam)
				moving = true


func _pick_state() -> void:
	if fleeing > 0.0:
		return
	var a: Array = ACTS.get(kind, [])
	if not a.is_empty() and randf() < 0.55:
		state = "act"
		state_t = randf_range(float(a[3]), float(a[4]))


## v25: не боится героиню в облике зверя, а скакунов можно спокойно приманить едой (если не бежать)
func _calm(pl: Node2D) -> bool:
	if Game.shape_form != "" or Game.riding:
		return true
	if W.rideable(kind) and Game.held().begins_with("food_") and not bool(pl.get("running")):
		return true
	return Game.mount_kind == kind and Game.mounts.has(kind) and has_meta("mount25")


func get_prompt() -> String:
	var v25: Node = get_tree().get_first_node_in_group("v25")
	if v25 != null:
		var vp: String = String(v25.call("animal_prompt", self))
		if vp != "":
			return vp
	if not bool(info["pet"]) or fleeing > 0.0:
		return ""
	return "Погладить (%s)" % preload("res://sex27.gd").label(kind, sex)


func interact() -> void:
	var v25: Node = get_tree().get_first_node_in_group("v25")
	if v25 != null and bool(v25.call("animal_interact", self)):
		return
	# v23: еда в руке — приманить в загон
	var held: String = Game.held()
	if held.begins_with("food_") and not follow:
		var fm: Node = get_tree().get_first_node_in_group("farm23")
		if fm != null and bool(fm.call("lure", self, held)):
			happy_t = 1.4
			moving = false
			return
	if not bool(info["pet"]):
		return
	happy_t = 1.4
	moving = false
	state = "idle"
	if not Game.forms_known.has(kind):
		Game.forms_known.append(kind)          # v25: погладила — теперь знает этот облик
	Game.fx.emit(global_position + Vector2(0, -hh - 6.0), "heart")
	get_tree().call_group("player", "react", "happy", 1.4)
	if String(info["sound"]) != "":
		Sound.play(String(info["sound"]), -6.0, 0.1, global_position)
	# трижды погладили и дома есть место в загоне — идёт за героиней
	pets += 1
	var hs: Node = get_tree().get_first_node_in_group("homestead")
	if pets >= 3 and not follow and roam > 60.0 and hs != null and bool(hs.call("pen_free")):
		follow = true
		add_to_group("followers")
		var keep: Vector2 = global_position
		var objs: Node = get_tree().current_scene.get("objects")
		get_parent().remove_child(self)
		objs.add_child(self)
		global_position = keep
		Game.toast.emit("%s идёт за тобой в загон!" % String(info["name"]), load("res://art/fx_heart.png"))
	if info.get("mythic", false) and not Game.met.has(kind):
		Game.met[kind] = Game.day
		Game.toast.emit("Встреча: %s!" % String(info["name"]), load("res://art/fx_heart.png"))


## Дошёл до загона: живёт в нём, не пугается
func settle(c: Vector2) -> void:
	follow = false
	remove_from_group("followers")
	home = c
	roam = 40.0
	info = info.duplicate()
	info["shy"] = false

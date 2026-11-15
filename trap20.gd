extends Node2D
## Ловушка (v20). E: положить приманку из сумки -> через несколько игровых часов в ловушке сидит зверь своего края
## (птица, рыба, летучая мышь...). E ещё раз: вычесать шерсть / собрать перья, пух, чешую — и отпустить зверя.
## Сами звери в котёл не идут: только то, что с них можно взять без вреда.

const MT = preload("res://mats_db.gd")
const IT = preload("res://items_db.gd")
const WDB = preload("res://wild_db.gd")
const BDB = preload("res://birds_db.gd")
const WD = preload("res://world_data.gd")

var kind: String = "trap_small"
var main: Node2D
var key: String = ""
var interact_offset: Vector2 = Vector2(0, -10)
var base_spr: Sprite2D
var bars: Sprite2D
var catch_spr: Sprite2D
var bait_spr: Sprite2D
var check_t: float = 0.0
var t: float = 0.0


func _ready() -> void:
	add_to_group("interactables")
	add_to_group("traps20")
	key = "%d,%d" % [int(position.x), int(position.y)]
	base_spr = Sprite2D.new()
	base_spr.texture = load("res://art/%s.png" % String((MT.BUILD[kind] as Array)[1]))
	base_spr.centered = false
	base_spr.offset = Vector2(-floorf(base_spr.texture.get_width() / 2.0), -float(base_spr.texture.get_height()))
	add_child(base_spr)
	catch_spr = Sprite2D.new()
	catch_spr.visible = false
	catch_spr.z_index = 1
	add_child(catch_spr)
	bait_spr = Sprite2D.new()
	bait_spr.scale = Vector2(0.35, 0.35)
	bait_spr.position = Vector2(0, -4)
	bait_spr.visible = false
	bait_spr.z_index = 1
	add_child(bait_spr)
	var bp: String = "res://art/%s_bars.png" % String((MT.BUILD[kind] as Array)[1])
	if ResourceLoader.exists(bp):
		bars = Sprite2D.new()
		bars.texture = load(bp)
		bars.centered = false
		bars.offset = base_spr.offset
		bars.z_index = 2
		add_child(bars)
	if not Game.traps20.has(key):
		Game.traps20[key] = {"bait": "", "caught": "", "due": 0.0}
	_show()
	check_t = randf()


func _st() -> Dictionary:
	return Game.traps20[key]


func _abs_min() -> float:
	return float(Game.day) * 1440.0 + Game.minutes


## Кто может попасться здесь (по краю, где стоит ловушка, и по времени суток)
func candidates() -> Array:
	var biome: int = WD.biome_at(global_position)
	if Rect2(0, 0, WD.RW, WD.RH).has_point(global_position):
		biome = WD.MEADOW
	var want: Array = (MT.TRAPS[kind] as Array)[1]
	var out: Array = []
	for w in want:
		var ws: String = String(w)
		if ws == "*bird":
			var night: bool = Game.night_factor() > 0.5
			for b in BDB.for_biome(biome, night, Game.golden() > 0.3):
				if not bool((BDB.DATA[String(b[0])] as Dictionary)["owl"]):
					out.append("bird:" + String(b[0]))
		elif ws == "*fish":
			out.append("*fish")
		elif ws == "*bat":
			if biome in [WD.GOTHIC, WD.SPIDER, WD.GROTTO] or Game.night_factor() > 0.5:
				out.append("*bat")
		else:
			var fauna: Array = WDB.FAUNA.get(biome, [])
			for f in fauna:
				if String(f[0]) == ws:
					out.append(ws)
			for m in WDB.MYTHIC_SPAWN.get(biome, []):
				if String(m[0]) == ws:
					out.append(ws)
	return out


func _process(delta: float) -> void:
	t += delta
	check_t -= delta
	if catch_spr.visible:
		# пойманный зверёк шевелится
		catch_spr.position.x = float(catch_spr.get_meta("x0", 0.0)) + (sin(t * 7.0) * 0.6 if fmod(t, 3.0) < 0.8 else 0.0)
	if check_t > 0.0:
		return
	check_t = 1.0
	var st: Dictionary = _st()
	if String(st["bait"]) == "" or String(st["caught"]) != "":
		return
	if _abs_min() < float(st["due"]):
		return
	var cands: Array = candidates()
	if cands.is_empty():
		# никого подходящего рядом сейчас — попробуем позже
		st["due"] = _abs_min() + 60.0
		return
	st["caught"] = String(cands[randi() % cands.size()])
	_show()
	Sound.play("door", -14.0, 0.2, global_position)


func _show() -> void:
	var st: Dictionary = _st()
	var c: String = String(st["caught"])
	bait_spr.visible = String(st["bait"]) != "" and c == ""
	if bait_spr.visible:
		bait_spr.texture = IT.icon(String(st["bait"]))
	if c == "":
		catch_spr.visible = false
		return
	catch_spr.visible = true
	var at: AtlasTexture = AtlasTexture.new()
	var sc: float = 0.5
	if c.begins_with("bird:"):
		var bid: String = c.substr(5)
		var fr: Array = (BDB.DATA[bid] as Dictionary)["frame"]
		at.atlas = load("res://art/bird_%s.png" % bid)
		at.region = Rect2(0, 0, float(fr[0]), float(fr[1]))
	elif c == "*fish":
		at.atlas = load("res://art/fish_perch.png")
		at.region = Rect2(Vector2.ZERO, at.atlas.get_size())
		sc = 0.6
	elif c == "*bat":
		at.atlas = load("res://art/bat.png")
		at.region = Rect2(0, 0, at.atlas.get_width() / 4.0, at.atlas.get_height())
		sc = 1.0
	else:
		var a: Dictionary = WDB.ANIMALS.get(c, {"w": 22, "h": 18})
		at.atlas = load("res://art/animal_%s.png" % c)
		at.region = Rect2(0, 0, float(a["w"]) * 2.0, float(a["h"]) * 2.0)
		var hh: float = float(base_spr.texture.get_height())
		sc = minf(0.5, (hh - 4.0) / (float(a["h"]) * 2.0))
	catch_spr.texture = at
	catch_spr.scale = Vector2(sc, sc)
	catch_spr.centered = true
	catch_spr.position = Vector2(0, -at.region.size.y * sc * 0.5 - 2.0)
	catch_spr.set_meta("x0", 0.0)


func get_prompt() -> String:
	var st: Dictionary = _st()
	var c: String = String(st["caught"])
	if c != "":
		return "Взять %s и отпустить" % _what(c)
	if String(st["bait"]) != "":
		return "%s: приманка лежит" % String((MT.TRAPS[kind] as Array)[0])
	return "Положить приманку"


func _what(c: String) -> String:
	if c.begins_with("bird:"):
		return "перья"
	if c == "*fish":
		return "чешую"
	if c in ["hedgehog"]:
		return "иголки"
	if c in ["deer", "golden_deer"]:
		return "шерсть"
	if c in ["unicorn"]:
		return "волосы из гривы"
	if c in ["boar", "flat_boar"]:
		return "щетину"
	if c in ["duck", "rabbit", "squirrel", "sapphire_hare"]:
		return "пух"
	return "шерсть"


func _bait_list() -> Array:
	var b: String = String((MT.TRAPS[kind] as Array)[2])
	if b == "magic":
		return MT.BAIT_MAGIC
	if b == "seed":
		return MT.BAIT_SEED
	var out: Array = []
	for id in Game.inventory.keys():
		if Game.get_count(String(id)) > 0 and IT.is_food(String(id)):
			out.append(String(id))
	return out


func interact() -> void:
	var st: Dictionary = _st()
	var c: String = String(st["caught"])
	if c != "":
		_harvest(c)
		return
	if String(st["bait"]) != "":
		get_tree().call_group("player", "react", "smile", 0.6)
		return
	for b in _bait_list():
		if Game.get_count(String(b)) > 0 and Game.take_item(String(b)):
			st["bait"] = String(b)
			var mean: float = float((MT.TRAPS[kind] as Array)[3]) * 60.0
			st["due"] = _abs_min() + mean * randf_range(0.5, 1.5)
			Sound.play("pickup", -8.0)
			_show()
			return
	Game.toast.emit("Нужна приманка", IT.icon(String(_bait_hint())))
	get_tree().call_group("player", "react", "pout", 0.8)


func _bait_hint() -> String:
	var b: String = String((MT.TRAPS[kind] as Array)[2])
	return "moon_dew" if b == "magic" else ("seed_mix" if b == "seed" else "food_apple")


## Взять, что можно, и отпустить: зверь убегает, птица улетает
func _harvest(c: String) -> void:
	var st: Dictionary = _st()
	var loot: Array = []
	if c.begins_with("bird:"):
		var bid: String = c.substr(5)
		loot.append(["feather_" + bid, 1, 3, 1.0])
		Game.birds_seen[bid] = int(Game.birds_seen.get(bid, 0)) + 1
	else:
		loot = MT.LOOT.get(c, [])
	var got: int = 0
	for l in loot:
		if randf() <= float(l[3]):
			var n: int = randi_range(int(l[1]), int(l[2]))
			Game.add_item(String(l[0]), n)
			got += n
	Sound.play("purr" if not c.begins_with("bird:") else "pickup", -10.0)
	get_tree().call_group("player", "react", "happy", 1.2)
	Game.fx.emit(global_position + Vector2(0, -16), "heart")
	# отпустить: копия спрайта убегает/улетает и тает
	var run: Sprite2D = catch_spr.duplicate() as Sprite2D
	run.global_position = catch_spr.global_position
	main.add_child(run)
	run.z_index = 5
	var dir: float = -1.0 if randf() < 0.5 else 1.0
	run.flip_h = dir < 0.0
	var tw: Tween = run.create_tween().set_parallel(true)
	var up: float = -90.0 if c.begins_with("bird:") or c == "*bat" else -6.0
	tw.tween_property(run, "position", run.position + Vector2(dir * 140.0, up), 1.4)
	tw.tween_property(run, "modulate:a", 0.0, 1.4).set_delay(0.5)
	tw.chain().tween_callback(run.queue_free)
	st["caught"] = ""
	st["bait"] = ""
	_show()

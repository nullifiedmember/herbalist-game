extends Node
## Насекомые мира. Каждую секунду решает, сколько каких сейчас должно быть
## (время суток, есть ли цветы, грядки, тля, кучки, пруд), и считает их пользу и вред.

const IDB = preload("res://insects_db.gd")
const LAY = preload("res://world_layout.gd")
const INSECT = preload("res://insect.gd")

var main: Node2D
var fly_layer: Node2D
var tick: float = 0.0
var aphid_chance: float = 0.3                # шанс, что утром на растущей грядке заведётся тля
var stats: Dictionary = {"flower_visits": 0.0, "grass_bites": 0, "dragonflies": 2}
var dragonflies_today: int = 2


func setup(m: Node2D) -> void:
	main = m
	fly_layer = Node2D.new()
	fly_layer.z_index = 4
	main.add_child(fly_layer)
	Game.day_changed.connect(_on_new_day)
	dragonflies_today = randi_range(1, 4)


func _process(delta: float) -> void:
	if main == null:
		return
	tick -= delta
	if tick <= 0.0:
		tick = 1.0
		balance()
	fireflies_calm(delta)


func bugs(kind: String, include_leaving: bool = false) -> Array:
	var out: Array = []
	for b in get_tree().get_nodes_in_group("insects"):
		if not is_instance_valid(b) or (b as Node).is_queued_for_deletion():
			continue
		if String(b.get("kind")) != kind:
			continue
		if not include_leaving and String(b.get("state")) == "leave":
			continue
		out.append(b)
	return out


func _plots() -> Array:
	return get_tree().get_nodes_in_group("plots")


func _outdoor_poos(min_age: float) -> Array:
	var out: Array = []
	for m in get_tree().get_nodes_in_group("messes"):
		if String(m.get("kind")) == "poo" and not bool(m.get("indoor")) and float(m.get("age_min")) >= min_age:
			out.append(m)
	return out


## Сколько насекомых этого вида должно быть сейчас
func want(kind: String) -> int:
	var h: float = Game.hour()
	var night: bool = h >= 19.5 or h < 5.5
	match kind:
		"bee":
			var crops: int = 0
			for p in _plots():
				if String(p.get("crop")) != "":
					crops += 1
			return mini(6, 2 + crops) if (h >= 8.0 and h < 18.0) else 0
		"butterfly_white":
			return 2 if (h >= 9.0 and h < 17.0) else 0
		"butterfly_orange", "butterfly_blue":
			return 1 if (h >= 9.0 and h < 17.0) else 0
		"butterfly_yellow":
			return 1 if (h >= 10.0 and h < 16.0) else 0
		"ladybug":
			var ap: int = 0
			for p2 in _plots():
				if int(p2.get("aphids")) > 0:
					ap += 1
			return mini(4, 1 + ap) if (h >= 8.0 and h < 18.0) else 0
		"dung_beetle":
			return mini(3, _outdoor_poos(60.0).size()) if (h >= 7.0 and h < 20.0) else 0
		"mosquito":
			return maxi(1, 6 - int(stats["dragonflies"])) if (h >= 19.0 or h < 6.0) else 0
		"dragonfly":
			return dragonflies_today if (h >= 9.0 and h < 18.0) else 0
		"firefly":
			return 8 if (h >= 20.5 or h < 5.0) else 0
		"grasshopper":
			return 4 if (h >= 10.0 and h < 18.0) else 0
		"moth":
			return 2 * main.get("lantern_spots").size() if night else 0
	return 0


## Довести число насекомых до нужного: прилетают и улетают по одному
func balance() -> void:
	for kind in IDB.DATA.keys():
		var k: String = String(kind)
		if k == "aphid":
			continue
		var live: Array = bugs(k)
		var n: int = want(k)
		if live.size() < n:
			spawn(k)
		elif live.size() > n:
			live[0].call("leave")
	# тля сидит на своих грядках
	for p in _plots():
		var has: Node = null
		for a in bugs("aphid"):
			if a.get("follow") == p:
				has = a
		if int(p.get("aphids")) > 0 and has == null:
			var b: Node2D = spawn("aphid")
			b.set("follow", p)
			b.position = (p as Node2D).global_position + Vector2(randf_range(-14.0, 14.0), 1.0)
			b.set("alt", 16.0)
		elif int(p.get("aphids")) <= 0 and has != null:
			has.queue_free()


func spawn(kind: String) -> Node2D:
	var b: Node2D = Node2D.new()
	b.set_script(INSECT)
	var home: Vector2 = Vector2(LAY.GARDEN_RECT.get_center())
	var r: float = 100.0
	var flowers: Array = main.get("flower_spots")
	match kind:
		"butterfly_white", "butterfly_orange", "butterfly_blue", "butterfly_yellow", "firefly", "grasshopper":
			if flowers.size() > 0:
				home = flowers[randi() % flowers.size()]
			r = 60.0 if kind.begins_with("butterfly") else 90.0
		"ladybug":
			r = 80.0
		"mosquito":
			home = LAY.POND_C
			r = 140.0
		"dragonfly":
			home = LAY.POND_C
			r = 150.0
			stats["dragonflies"] = int(stats["dragonflies"]) + 1
		"moth":
			var ls: Array = main.get("lantern_spots")
			home = ls[randi() % ls.size()]
			r = 14.0
		"dung_beetle":
			var poos: Array = _outdoor_poos(60.0)
			if poos.size() > 0:
				var pz: Node2D = poos[randi() % poos.size()]
				home = pz.global_position + Vector2(randf_range(-1.0, 1.0), randf_range(-0.4, 0.4)).normalized() * 120.0
				b.set("follow", pz)
			r = 1.0
	b.call("setup", kind, home, r, self)
	if bool(IDB.DATA[kind]["fly"]):
		# прилетают издалека
		b.position = home + Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized() * 220.0
		fly_layer.add_child(b)
	else:
		main.get("objects").add_child(b)
	return b


## Куда лететь дальше
func pick_target(b: Node2D) -> Vector2:
	var kind: String = String(b.get("kind"))
	var home: Vector2 = b.get("home")
	var r: float = float(b.get("radius"))
	var flowers: Array = main.get("flower_spots")
	match kind:
		"bee":
			var crops: Array = []
			for p in _plots():
				if String(p.get("crop")) != "":
					crops.append(p)
			if crops.size() > 0 and randf() < 0.6:
				var pc: Node2D = crops[randi() % crops.size()]
				return pc.global_position + Vector2(randf_range(-18.0, 18.0), -10.0)
			if flowers.size() > 0:
				return flowers[randi() % flowers.size()] + Vector2(0, -6)
		"ladybug":
			var ap: Array = []
			for p2 in _plots():
				if int(p2.get("aphids")) > 0:
					ap.append(p2)
			var src: Array = ap if ap.size() > 0 else _plots()
			if src.size() > 0:
				var pl: Node2D = src[randi() % src.size()]
				return pl.global_position + Vector2(randf_range(-14.0, 14.0), -8.0)
		"butterfly_white", "butterfly_orange", "butterfly_blue", "butterfly_yellow":
			if flowers.size() > 0 and randf() < 0.7:
				var near: Array = []
				for fl in flowers:
					if (fl as Vector2).distance_to(home) < 160.0:
						near.append(fl)
				if near.size() > 0:
					return near[randi() % near.size()] + Vector2(0, -6)
		"moth":
			for p3 in _plots():
				if String(p3.get("crop")) == "lavender" and randf() < 0.3:
					return (p3 as Node2D).global_position + Vector2(randf_range(-14.0, 14.0), -10.0)
			var a: float = randf() * TAU
			return home + Vector2(cos(a), sin(a) * 0.7) * randf_range(6.0, 16.0)
		"dragonfly", "mosquito":
			var a2: float = randf() * TAU
			var rr: float = randf_range(0.2, 1.15)
			return LAY.POND_C + Vector2(cos(a2) * LAY.POND_R.x * rr, sin(a2) * LAY.POND_R.y * rr)
	return home + Vector2(randf_range(-r, r), randf_range(-r, r) * 0.6)


func wants_land(b: Node2D) -> bool:
	match String(b.get("kind")):
		"bee":
			return randf() < 0.7
		"ladybug":
			return randf() < 0.85
		"butterfly_white", "butterfly_orange", "butterfly_blue", "butterfly_yellow":
			return randf() < 0.6
		"moth", "dragonfly":
			return randf() < 0.3
		"firefly":
			return randf() < 0.2
	return false


func _plot_near(p: Vector2, r: float) -> Node2D:
	var best: Node2D = null
	var bd: float = r
	for pl in _plots():
		var dd: float = (pl as Node2D).global_position.distance_to(p + Vector2(0, 10))
		if dd < bd:
			bd = dd
			best = pl
	return best


## Насекомое село: опыление, поедание тли и т.п.
func on_land(b: Node2D) -> void:
	var kind: String = String(b.get("kind"))
	var pl: Node2D = _plot_near(b.position, 34.0)
	match kind:
		"bee":
			if pl != null and String(pl.get("crop")) != "" and int(pl.get("stage")) < 3:
				pl.set("pollinated", true)
			elif pl == null:
				stats["flower_visits"] = float(stats["flower_visits"]) + 0.5
		"butterfly_white", "butterfly_orange", "butterfly_blue", "butterfly_yellow":
			stats["flower_visits"] = float(stats["flower_visits"]) + 1.0
		"ladybug":
			if pl != null and int(pl.get("aphids")) > 0:
				pl.set("aphids", int(pl.get("aphids")) - 1)
		"moth":
			if pl != null and String(pl.get("crop")) == "lavender" and int(pl.get("stage")) < 3:
				pl.set("pollinated", true)


## Кузнечик прыгнул: если рядом дикая трава — откусил
func on_hop(b: Node2D) -> void:
	for h in get_tree().get_nodes_in_group("wild_herbs"):
		if (h as Node2D).global_position.distance_to(b.position) < 26.0:
			stats["grass_bites"] = int(stats["grass_bites"]) + 1
			return


## Комар: если героиня рядом и на улице — летит к ней и кусает
func mosquito_tick(b: Node2D) -> void:
	var pl: Node2D = main.get("player")
	if pl == null or bool(main.get("inside")):
		return
	var dist: float = b.position.distance_to(pl.position)
	if dist < 140.0:
		b.set("target", pl.position + Vector2(randf_range(-4.0, 4.0), 0.0))
	if dist < 10.0 and float(b.get("bite_cd")) <= 0.0:
		b.set("bite_cd", 6.0)
		bite()


func bite() -> void:
	Game.bites += 1
	var pl: Node2D = main.get("player")
	pl.call("react", "pout", 1.6)
	if not Game.busy and not Game.ui_open:
		# укус: героиня останавливается почесаться
		Game.busy = true
		pl.set("vel", Vector2.ZERO)
		await get_tree().create_timer(0.5).timeout
		Game.busy = false


## Жук-навозник катает кучку: она исчезает гораздо быстрее
func on_beetle_push(b: Node2D, delta: float) -> void:
	var pz = b.get("follow")   # без типа: кучка могла уже быть удалена
	if pz != null and is_instance_valid(pz) and not (pz as Node).is_queued_for_deletion():
		pz.call("advance", delta * 8.0)


## Светлячки рядом — стыд проходит быстрее
func fireflies_calm(delta: float) -> void:
	if Game.shame <= 0.0 or Game.busy or Game.ui_open or bool(main.get("inside")):
		return
	var pl: Node2D = main.get("player")
	for f in bugs("firefly"):
		if (f as Node2D).position.distance_to(pl.position) < 90.0:
			Game.shame = maxf(0.0, Game.shame - delta * Game.MIN_PER_SEC * Game.SHAME_DECAY_PER_MIN * 1.5)
			return


## Новый день: итог пользы и вреда за вчера; на растущих грядках может завестись тля
func _on_new_day() -> void:
	var good: int = clampi(int(float(stats["flower_visits"]) / 3.0), 0, 4)
	var bad: int = clampi(int(stats["grass_bites"]) / 2, 0, 6)
	Game.herb_bonus = good - bad
	for p in _plots():
		if String(p.get("crop")) != "" and int(p.get("stage")) < 3 and randf() < aphid_chance:
			p.set("aphids", randi_range(2, 4))
	stats["flower_visits"] = 0.0
	stats["grass_bites"] = 0
	stats["dragonflies"] = 0
	dragonflies_today = randi_range(1, 4)

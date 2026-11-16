extends Node
## v23: подземелья во всех краях мира (не только в пещерном): вход — каменная арка своего вида по биому.
## Внутри — комнаты и коридоры, монстры, сундуки с книгами, оружием и приколами, в последней комнате — босс.
## В одной случайной пещере (выбирается при первых заходах) — портал в ад с демонами и Дьяволом.
## Бой без крови: ЛКМ — удар оружием из руки (или толчок без оружия), побеждённые исчезают облачком звёзд.

const V = preload("res://v23_data.gd")
const WD = preload("res://world_data.gd")
const IT = preload("res://items_db.gd")
const MT = preload("res://mats_db.gd")
const ORG: Vector2 = Vector2(200000, 0)
const CS: int = 32
const GW: int = 46
const GH: int = 32
const BIOME_THEME: Dictionary = {
	WD.MEADOW: "forest", WD.FIELD: "forest", WD.BEACH: "sand", WD.PINE: "ice", WD.BIRCH: "forest", WD.AUTUMN: "forest",
	WD.SWAMP: "swamp", WD.UNICORN: "crystal", WD.GROTTO: "cave", WD.ELF: "elven", WD.KNIGHT: "crypt", WD.ORC: "lava",
	WD.SPIDER: "forest", WD.MAGE: "crystal", WD.DWARF: "lava", WD.GOTHIC: "crypt", WD.CATS: "cave", WD.JAPAN: "elven",
}
const TIER: Dictionary = {"cave": 1, "forest": 1, "sand": 2, "swamp": 2, "ice": 2, "elven": 3, "crypt": 3, "crystal": 4, "lava": 4, "hell": 6}
const MONS: Dictionary = {
	"cave": ["slime", "bat_m", "golem"], "forest": ["mushroom", "spiderling", "slime_pink"], "ice": ["slime_blue", "ice_imp"],
	"sand": ["slime_sand", "scarab"], "swamp": ["frog", "mushroom_blue", "slime"], "crystal": ["crystal_golem", "wisp", "slime_blue"],
	"crypt": ["skeleton", "ghost", "bat_m"], "lava": ["salamander", "golem", "imp"], "elven": ["wisp", "mushroom", "spiderling"],
	"hell": ["imp", "demon", "hellhound"],
}
const BOSS: Dictionary = {"cave": "golem_king", "forest": "slime_king", "ice": "golem_king", "sand": "lich", "swamp": "slime_king",
	"crystal": "golem_king", "crypt": "lich", "lava": "golem_king", "elven": "slime_king", "hell": "devil"}
const AMBIENT: Dictionary = {"cave": Color(0.62, 0.6, 0.7), "forest": Color(0.6, 0.66, 0.55), "ice": Color(0.66, 0.76, 0.9), "sand": Color(0.8, 0.7, 0.55),
	"swamp": Color(0.55, 0.65, 0.5), "crystal": Color(0.6, 0.55, 0.85), "crypt": Color(0.55, 0.5, 0.62), "lava": Color(0.8, 0.55, 0.45),
	"elven": Color(0.62, 0.75, 0.6), "hell": Color(0.95, 0.45, 0.38)}

var main: Node2D
var v23: Node
var world: Node2D
var active: bool = false
var key: String = ""
var theme: String = "cave"
var floor_cells: Dictionary = {}     # Vector2i -> true
var root: Node2D                     # картинка подземелья
var things: Array = []               # узлы подземелья (сундуки, факелы, монстры, лестница)
var back_to: Vector2 = Vector2.ZERO
var atk_cd: float = 0.0
var swing: Sprite2D
var swing_t: float = 0.0
var rooms: Array = []
var hurt_cd: float = 0.0


func setup(m: Node2D, v: Node) -> void:
	main = m
	v23 = v
	add_to_group("dungeon23")
	process_priority = 100        # после main: свет подземелья поверх дневного
	world = m.get("world")
	if world != null and not Game.SOLO:     # v29: в одиночной игре входов в подземелья нет
		(world.get("region_hooks") as Array).append(Callable(self, "_region_hook"))
	swing = Sprite2D.new()
	swing.visible = false
	swing.z_index = 6
	swing.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	(m.get("player") as Node2D).add_child(swing)


# ------------------------------------------------------------------ входы в мире

func _region_hook(node: Node2D, r: Vector2i) -> void:
	if r == Vector2i.ZERO:
		return
	var biome: int = WD.biome_of_region(r)
	if not BIOME_THEME.has(biome):
		return
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = hash(r) + 2323
	if rng.randf() > 0.3:
		return
	var rect: Rect2 = WD.region_rect(r)
	for i in range(24):
		var p: Vector2 = Vector2(rng.randf_range(rect.position.x + 120, rect.end.x - 120), rng.randf_range(rect.position.y + 160, rect.end.y - 80)).round()
		var near_town: bool = false
		for tc in WD.TOWN_C.values():
			if p.distance_to(tc) < WD.TOWN_R + 300.0:
				near_town = true
		if near_town or not bool(world.call("free_at", p, 70.0, 40.0)) or bool(main.call("is_blocked", p)):
			continue
		var th: String = String(BIOME_THEME[biome])
		world.call("reserve", Rect2(p - Vector2(80, 90), Vector2(160, 120)))
		world.call("put", node, r, "dun_entry_" + th, p, 0.0, 0.0, Color.WHITE, true)
		world.call("add_block_rect", Rect2(p.x - 28, p.y - 40, 16, 36))
		world.call("add_block_rect", Rect2(p.x + 12, p.y - 40, 16, 36))
		var d: Node2D = Node2D.new()
		d.set_script(load("res://dun_thing.gd"))
		d.set("kind", "entry")
		d.set("key", "%d,%d" % [r.x, r.y])
		d.set("theme", th)
		d.position = p + Vector2(0, -2)
		node.add_child(d)
		return


# ------------------------------------------------------------------ вход и выход

func use_thing(n: Node2D) -> void:
	match str(n.get("kind")):
		"entry":
			enter(String(n.get("key")), String(n.get("theme")), n.global_position)
		"stairs":
			leave()
		"portal":
			_go_hell()
		"chest":
			_open_chest(n)


func enter(k: String, th: String, from: Vector2) -> void:
	if Game.busy:
		return
	# одна случайная пещера станет пещерой с порталом в ад
	if Game.hell_key == "" and k != "hell":
		var seen: int = Game.dungeons.size()
		if randf() < 0.3 or seen >= 3:
			Game.hell_key = k
			Game.hell_pos = from
	if not active:
		back_to = from
	await main.call("_transition", func() -> void:
		main.call("_leave_special_states")
		_build(k, th)
		active = true
		var pl: Node2D = main.get("player")
		var c: Rect2i = rooms[0]
		pl.position = ORG + Vector2((c.position.x + c.size.x / 2) * CS + 16, (c.position.y + c.size.y / 2 + 1) * CS)
		pl.set("facing", 0)
		_cam())
	if not Game.dungeons.has(k):
		Game.dungeons[k] = {"chests": {}, "boss": false}
	Game.toast.emit(String(V.THEMES[th]["name"]) if th != "hell" else "ПЕКЛО", load("res://art/dun_entry_%s.png" % (th if th != "hell" else "lava")))
	Sound.play("door", -4.0)


func leave() -> void:
	if not active or Game.busy:
		return
	await main.call("_transition", func() -> void:
		_clear()
		active = false
		var pl: Node2D = main.get("player")
		world.call("build_around", back_to)
		pl.position = main.call("free_near", back_to + Vector2(0, 30))
		pl.set("facing", 0)
		main.call("_world_limits")
		(main.get("cam") as Camera2D).reset_smoothing())
	Sound.play("door", -4.0)


func _go_hell() -> void:
	# v24: портал ведёт не в подземелье, а в другой мир — Пеклоград, город демониц
	var rl: Node = get_tree().get_first_node_in_group("realm24")
	if rl != null:
		var from: Vector2 = back_to
		_clear()
		active = false
		rl.set("back_to", from)
		rl.set("active", "")
		await rl.call("enter", "hell", from)
		if not Game.dungeons.has("hell"):
			Game.dungeons["hell"] = {"chests": {}, "boss": false}
		return
	Sound.play("fire", -2.0)
	Game.toast.emit("Ты шагнула в портал... Жарко!", load("res://art/dun_portal_0.png"))
	await main.call("_transition", func() -> void:
		_build("hell", "hell")
		var pl: Node2D = main.get("player")
		var c: Rect2i = rooms[0]
		pl.position = ORG + Vector2((c.position.x + c.size.x / 2) * CS + 16, (c.position.y + c.size.y / 2 + 1) * CS)
		_cam())
	if not Game.dungeons.has("hell"):
		Game.dungeons["hell"] = {"chests": {}, "boss": false}
		Game.chron("Побывала в самом пекле. Демоны оказались... вежливыми.", "dungeon")


func _cam() -> void:
	var cam: Camera2D = main.get("cam")
	cam.limit_left = int(ORG.x) - 200
	cam.limit_top = int(ORG.y) - 200
	cam.limit_right = int(ORG.x) + GW * CS + 200
	cam.limit_bottom = int(ORG.y) + GH * CS + 200
	cam.reset_smoothing()


## Блокировка: в подземелье ходить можно только по полу
func is_blocked(p: Vector2) -> bool:
	var l: Vector2 = p - ORG
	var c: Vector2i = Vector2i(int(floor(l.x / CS)), int(floor((l.y - 2.0) / CS)))
	return not floor_cells.has(c)


# ------------------------------------------------------------------ генерация

func _clear() -> void:
	for n in things:
		if is_instance_valid(n):
			(n as Node).queue_free()
	things.clear()
	for m in get_tree().get_nodes_in_group("monsters23"):
		if (m as Node2D).global_position.x > 150000.0:
			m.call("give_back", true)          # v24: утащенное — в тайник монстров
			(m as Node).queue_free()
	if root != null:
		root.queue_free()
		root = null
	floor_cells.clear()


func _build(k: String, th: String) -> void:
	_clear()
	key = k
	theme = th
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = hash(k) + 99
	rooms.clear()
	var tries: int = 0
	var want: int = rng.randi_range(7, 10)
	while rooms.size() < want and tries < 400:
		tries += 1
		var w: int = rng.randi_range(5, 10)
		var h: int = rng.randi_range(4, 7)
		var r: Rect2i = Rect2i(rng.randi_range(2, GW - w - 2), rng.randi_range(2, GH - h - 2), w, h)
		var ok: bool = true
		for o in rooms:
			if (o as Rect2i).grow(2).intersects(r):
				ok = false
				break
		if ok:
			rooms.append(r)
	# комнаты по порядку слева направо — путь от входа к боссу
	rooms.sort_custom(func(a: Rect2i, b: Rect2i) -> bool: return a.position.x + a.position.y * 0.3 < b.position.x + b.position.y * 0.3)
	for r2 in rooms:
		var rr: Rect2i = r2
		for y in range(rr.position.y, rr.end.y):
			for x in range(rr.position.x, rr.end.x):
				floor_cells[Vector2i(x, y)] = true
	for i in range(1, rooms.size()):
		var a: Vector2i = (rooms[i - 1] as Rect2i).get_center()
		var b: Vector2i = (rooms[i] as Rect2i).get_center()
		var corner: Vector2i = Vector2i(b.x, a.y) if rng.randf() < 0.5 else Vector2i(a.x, b.y)
		_carve(a, corner)
		_carve(corner, b)
	# лишний коридор-петля
	if rooms.size() > 4:
		_carve((rooms[1] as Rect2i).get_center(), (rooms[rooms.size() - 2] as Rect2i).get_center())
	_draw_map()
	# содержимое
	var data: Dictionary = Game.dungeons.get(k, {"chests": {}, "boss": false})
	var tier: int = int(TIER.get(th, 1))
	var r0: Rect2i = rooms[0]
	_thing("stairs", "dun_stairs", _cell_pos(r0.get_center() + Vector2i(0, -1)), 0)
	var ci: int = 0
	for i in range(1, rooms.size()):
		var rm: Rect2i = rooms[i]
		var last: bool = i == rooms.size() - 1
		# факелы
		for k2 in range(2):
			var tp: Vector2 = _cell_pos(Vector2i(rm.position.x + 1 + k2 * maxi(1, rm.size.x - 3), rm.position.y))
			var tor: Sprite2D = Sprite2D.new()
			tor.set_script(load("res://dun_torch.gd"))
			tor.texture = load("res://art/dun_torch_0.png")
			tor.position = tp + Vector2(0, -6)
			tor.z_index = 2
			main.add_child(tor)
			things.append(tor)
		# сундуки
		var nch: int = 1 if rng.randf() < 0.6 else (2 if rng.randf() < 0.4 else 0)
		if last:
			nch = 2
		for c in range(nch):
			var cp: Vector2i = Vector2i(rng.randi_range(rm.position.x + 1, rm.end.x - 2), rng.randi_range(rm.position.y + 1, rm.end.y - 2))
			var kind2: String = "gold" if last else ("iron" if rng.randf() < 0.35 else "wood")
			if th == "hell":
				kind2 = "hell"
			var opened: bool = (data["chests"] as Dictionary).has(str(ci)) or (data["chests"] as Dictionary).has(ci)
			var ch: Node2D = _thing("chest", "dun_chest_%s%s" % [kind2, "_open" if opened else ""], _cell_pos(cp), ci)
			ch.set_meta("ckind", kind2)
			ci += 1
		# монстры
		var list: Array = MONS.get(th, MONS["cave"])
		var nm: int = rng.randi_range(2, 3 + tier / 2)
		for m in range(nm):
			var mp: Vector2i = Vector2i(rng.randi_range(rm.position.x + 1, rm.end.x - 2), rng.randi_range(rm.position.y + 1, rm.end.y - 2))
			spawn_monster(String(list[rng.randi() % list.size()]), _cell_pos(mp), tier)
		if last and not bool(data.get("boss", false)):
			var bm: Node2D = spawn_monster(String(BOSS.get(th, "slime_king")), _cell_pos(rm.get_center()), tier)
			bm.set("on_defeat", Callable(self, "_boss_down"))
	# портал в ад — в пещере, которой выпала эта судьба
	if k == Game.hell_key and th != "hell" and rooms.size() > 3:
		var pr: Rect2i = rooms[rooms.size() - 2]
		_thing("portal", "dun_portal_0", _cell_pos(Vector2i(pr.get_center().x, pr.position.y + 1)), 0)


func _carve(a: Vector2i, b: Vector2i) -> void:
	var p: Vector2i = a
	while p != b:
		for dx in range(2):
			for dy in range(2):
				floor_cells[p + Vector2i(dx, dy)] = true
		if p.x != b.x:
			p.x += signi(b.x - p.x)
		else:
			p.y += signi(b.y - p.y)
	floor_cells[b] = true


func _cell_pos(c: Vector2i) -> Vector2:
	return ORG + Vector2(c.x * CS + CS / 2, c.y * CS + CS - 4)


func _draw_map() -> void:
	var img: Image = Image.create(GW * CS, (GH + 1) * CS, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.03, 0.02, 0.04))
	var fl: Image = (load("res://art/dun_floor_%s.png" % theme) as Texture2D).get_image()
	var wl: Image = (load("res://art/dun_wall_%s.png" % theme) as Texture2D).get_image()
	fl.convert(Image.FORMAT_RGBA8)
	wl.convert(Image.FORMAT_RGBA8)
	for y in range(GH):
		for x in range(GW):
			var c: Vector2i = Vector2i(x, y)
			if floor_cells.has(c):
				img.blit_rect(fl, Rect2i(0, 0, CS, CS), Vector2i(x * CS, y * CS + CS))
			elif floor_cells.has(c + Vector2i(0, 1)):
				img.blit_rect(wl, Rect2i(0, 0, CS, CS), Vector2i(x * CS, y * CS + CS))
	root = Node2D.new()
	root.z_index = -10
	main.add_child(root)
	var s: Sprite2D = Sprite2D.new()
	s.texture = ImageTexture.create_from_image(img)
	s.centered = false
	s.position = ORG - Vector2(0, CS)
	root.add_child(s)


func _thing(kind: String, tex: String, p: Vector2, idx: int) -> Node2D:
	var n: Node2D = Node2D.new()
	n.set_script(load("res://dun_thing.gd"))
	n.set("kind", kind)
	n.set("index", idx)
	n.position = p
	(main.get("objects") as Node).add_child(n)
	var s: Sprite2D = Sprite2D.new()
	s.texture = load("res://art/%s.png" % tex)
	s.centered = false
	s.offset = Vector2(-floorf(s.texture.get_width() / 2.0), -float(s.texture.get_height()))
	n.add_child(s)
	n.set("spr", s)
	things.append(n)
	return n


func spawn_monster(kind: String, at: Vector2, tier: int) -> Node2D:
	var m: Node2D = Node2D.new()
	m.set_script(load("res://monster23.gd"))
	(main.get("objects") as Node).add_child(m)
	m.call("setup", kind, at, tier)
	m.set("blocked", Callable(main, "is_blocked"))
	m.set("on_defeat", Callable(self, "_mon_down"))
	if active:
		things.append(m)
	return m


# ------------------------------------------------------------------ добыча

func _mon_down(m: Node2D) -> void:
	var tier: int = int(m.get("tier"))
	var coins: int = randi_range(1, 4) * tier
	if randf() < 0.5:
		Game.add_coins(coins)
	if randf() < 0.18:
		_give(_loot_item(tier, false))
	Game.skill_xp("combat", 4.0 * float(tier))


func _boss_down(m: Node2D) -> void:
	_mon_down(m)
	if Game.dungeons.has(key):
		Game.dungeons[key]["boss"] = true
	Game.add_coins(60 * int(m.get("tier")))
	_give(_loot_item(int(m.get("tier")) + 2, true))
	Game.skill_xp("combat", 60.0)
	var nm: String = String(V.MONSTERS[String(m.get("kind"))]["name"])
	Game.chron("Победила босса: %s. Он ушёл спать, обиженно сопя." % nm, "dungeon")
	Game.toast.emit("%s повержен(а)! Без единой царапины." % nm, load("res://art/icon_crown23.png"))
	if String(m.get("kind")) == "devil":
		Game.add_item("lgd_hell")


func _give(id: String) -> void:
	if id != "":
		Game.add_item(id)


## Случайная находка: книга, оружие, прикол, камень или монеты
func _loot_item(tier: int, rich: bool) -> String:
	var r: float = randf()
	if rich and r < 0.25:
		var lg: Array = []
		for wid in V.WEAPON_ORDER:
			if String(V.WEAPONS[wid]["mat"]) == "legend" and wid != "lgd_hell":
				lg.append(String(wid))
		return String(lg.pick_random())
	if r < 0.32:
		return String(V.BOOKS.keys().pick_random())
	if r < 0.55:
		var ws: Array = []
		for wid2 in V.WEAPON_ORDER:
			var wt: int = int(V.WEAPONS[wid2]["tier"])
			if wt <= tier and wt >= tier - 2 and String(V.WEAPONS[wid2]["mat"]) != "legend":
				ws.append(String(wid2))
		return String(ws.pick_random()) if not ws.is_empty() else "wpn_sword_iron"
	if r < 0.75:
		return String(V.JOKES.keys().pick_random())
	var gems: Array = []
	for mid in MT.ORDER:
		if String(mid).begins_with("gem_raw") or String(mid).begins_with("nugget_"):
			gems.append(String(mid))
	return String(gems.pick_random())


func _open_chest(n: Node2D) -> void:
	var idx: int = int(n.get("index"))
	var data: Dictionary = Game.dungeons.get(key, {})
	if data.is_empty():
		return
	if (data["chests"] as Dictionary).has(str(idx)):
		return
	data["chests"][str(idx)] = true
	var ck: String = String(n.get_meta("ckind", "wood"))
	(n.get("spr") as Sprite2D).texture = load("res://art/dun_chest_%s_open.png" % ck)
	var tier: int = int(TIER.get(theme, 1)) + {"wood": 0, "iron": 1, "gold": 2, "hell": 3}.get(ck, 0)
	var nloot: int = {"wood": 2, "iron": 3, "gold": 4, "hell": 5}.get(ck, 2)
	Game.add_coins(randi_range(5, 15) * tier)
	for i in range(nloot):
		_give(_loot_item(tier, ck in ["gold", "hell"] and i == 0))
	open_stash()
	Sound.play("ui_select", -2.0)
	Game.fx.emit(n.global_position + Vector2(0, -16), "sparkle")
	get_tree().call_group("player", "react", "happy", 1.6)


# ------------------------------------------------------------------ бой

func _weapon() -> String:
	var h: String = Game.held()
	if IT.is_weapon(h):
		return h
	var w: String = Game.worn(Game.hand_slot(false))
	return w if IT.is_weapon(w) else ""


func _monsters_near(r: float) -> bool:
	var pl: Node2D = main.get("player")
	for m in get_tree().get_nodes_in_group("monsters23"):
		if (m as Node2D).global_position.distance_to(pl.global_position) < r:
			return true
	return false


func _unhandled_input(event: InputEvent) -> void:
	if Game.ui_open or Game.busy or Game.SOLO:
		return
	var press: bool = false
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		press = true
	if event is InputEventKey and event.pressed and not event.echo and KB.is_key("attack", (event as InputEventKey).physical_keycode):
		press = true
	if not press or not (active or _monsters_near(320.0)):
		return
	attack()
	get_viewport().set_input_as_handled()


func attack() -> void:
	if atk_cd > 0.0:
		return
	var pl: Node2D = main.get("player")
	var wid: String = _weapon()
	var w: Dictionary = V.WEAPONS.get(wid, {"atk": 3, "cd": 0.45, "range": 26, "ranged": false, "fx": "", "type": "fist"})
	atk_cd = float(w["cd"])
	var dmg: float = float(w["atk"]) * (1.0 + Game.stat("atk") / 100.0)
	var aim: Vector2 = (main.get_global_mouse_position() - pl.global_position)
	if aim.length() < 4.0 or DisplayServer.get_name() == "headless":
		aim = pl.get("FACE_DIRS")[int(pl.get("facing"))]
	aim = aim.normalized()
	var fx: String = String(w["fx"])
	if fx == "heal":
		Game.hp = minf(Game.hp_max(), Game.hp + 1.5)
	# взмах: значок оружия у руки
	swing.texture = IT.icon(wid) if wid != "" else load("res://art/fx_heart.png")
	swing.visible = true
	swing_t = 0.22
	swing.rotation = aim.angle() + PI / 4.0
	swing.position = aim * 12.0 + Vector2(0, -16)
	Sound.play("chop" if not bool(w["ranged"]) else "magic", -8.0, 0.2)
	if bool(w["ranged"]):
		_shoot(pl.global_position + Vector2(0, -16), aim, dmg, float(w["range"]), fx, String(w["type"]))
		return
	var reach: float = float(w["range"])
	var hit_any: bool = false
	for m in get_tree().get_nodes_in_group("monsters23"):
		var mn: Node2D = m
		var to: Vector2 = mn.global_position + Vector2(0, -8) - pl.global_position
		if to.length() <= reach + 10.0 and (to.normalized().dot(aim) > 0.25 or to.length() < 14.0 or fx == "star"):
			mn.call("take_hit", dmg, pl.global_position, fx)
			hit_any = true
	if hit_any:
		Game.skill_xp("combat", 0.5)


func _shoot(from: Vector2, dir: Vector2, dmg: float, reach: float, fx: String, wtype: String) -> void:
	var p: Sprite2D = Sprite2D.new()
	p.texture = load("res://art/fx_soft.png")
	p.modulate = {"bubble": Color(0.7, 0.9, 1.0, 0.9), "bow": Color(1, 0.95, 0.8), "crossbow": Color(1, 0.95, 0.8), "boomerang": Color(0.9, 0.7, 0.4), "slingshot": Color(0.8, 0.8, 0.8)}.get(wtype, Color(0.75, 0.85, 1.0))
	p.scale = Vector2.ONE * (0.6 if wtype != "bubble" else 0.9)
	p.position = from
	p.z_index = 8
	var add: CanvasItemMaterial = CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	p.material = add
	main.add_child(p)
	var dist: float = 0.0
	var spd: float = 340.0
	var tw: Tween = create_tween()
	tw.tween_method(func(k: float) -> void:
		if not is_instance_valid(p) or not p.visible:
			return
		dist = k
		p.position = from + dir * k
		if bool(main.call("is_blocked", p.position + Vector2(0, 16))):
			p.visible = false
			return
		for m in get_tree().get_nodes_in_group("monsters23"):
			var mn: Node2D = m
			if mn.global_position.distance_to(p.position + Vector2(0, 8)) < 14.0:
				mn.call("take_hit", dmg, from, fx)
				Game.skill_xp("combat", 0.5)
				p.visible = false
				return, 0.0, reach, reach / spd)
	tw.tween_callback(p.queue_free)


## Монстр коснулся героини: она устаёт (сердечки). Без сил — выбирается наружу (ничего не теряет).
func hurt_player(dmg: float, from: Vector2) -> void:
	if Game.god_mode or hurt_cd > 0.0 or Game.busy or Game.spell_shield > 0.0:
		return
	hurt_cd = 0.5
	Game.hp -= dmg
	var pl: Node2D = main.get("player")
	pl.call("react", "pout", 0.8)
	Sound.play("ui_click", -2.0, 0.3)
	var push: Vector2 = (pl.global_position - from).normalized() * 14.0
	if not bool(main.call("is_blocked", pl.position + push)):
		pl.position += push
	if Game.hp <= 0.0:
		faint()


## v24: тайник монстров — всё, что они утащили раньше, находится в сундуке подземелья
func open_stash() -> void:
	for sid in Game.mon_stash.keys():
		if String(sid) == "coins":
			Game.add_coins(int(Game.mon_stash[sid]))
		else:
			Game.add_item(String(sid), int(Game.mon_stash[sid]))
	Game.mon_stash.clear()


## v24: без сил — монстры утаскивают часть вещей в свой тайник, героиня приходит в себя у входа уставшая
func faint() -> Array:
	Game.hp = Game.hp_max() * 0.4
	var taken: Array = []
	var can: Array = preload("res://monster23.gd").stealable(false)
	can.shuffle()
	for i in range(mini(can.size(), randi_range(1, 3))):
		var id: String = String(can[i])
		var n: int = maxi(1, int(ceil(float(Game.inventory[id]) * 0.3)))
		if Game.take_item(id, n):
			Game.mon_stash[id] = int(Game.mon_stash.get(id, 0)) + n
			taken.append(id)
	var cn: int = int(float(Game.coins) * 0.15)
	if cn > 0:
		Game.coins -= cn
		Game.mon_stash["coins"] = int(Game.mon_stash.get("coins", 0)) + cn
	Game.fatigue = minf(1.0, Game.fatigue + 0.35)
	Game.mon_sleep = 0.0
	Game.mon_confuse = 0.0
	Game.mon_sticky = 0.0
	Game.toast.emit("Совсем без сил... Монстры утащили часть вещей в свой тайник.", load("res://art/hp_heart_empty.png"))
	if active:
		leave()
	return taken


func _process(delta: float) -> void:
	atk_cd = maxf(0.0, atk_cd - delta)
	hurt_cd = maxf(0.0, hurt_cd - delta)
	if swing_t > 0.0:
		swing_t -= delta
		swing.rotation += delta * 9.0
		if swing_t <= 0.0:
			swing.visible = false
	if active:
		var cm: CanvasModulate = main.get("canvas_mod")
		if cm != null:
			cm.color = AMBIENT.get(theme, Color(0.6, 0.6, 0.7))
		# портал мерцает
		for n in things:
			if is_instance_valid(n) and n is Node2D and (n as Node2D).get("kind") == "portal":
				((n as Node2D).get("spr") as Sprite2D).texture = load("res://art/dun_portal_%d.png" % (int(Time.get_ticks_msec() / 150) % 4))


# ------------------------------------------------------------------ режим бога

func god_enter(which: String) -> void:
	var pl: Node2D = main.get("player")
	if which == "hell":
		if not active:
			back_to = pl.global_position
			await enter("god_hell_gate", "crypt", pl.global_position)
		_go_hell()
		return
	var b: int = WD.biome_at(pl.global_position) if not active else WD.CATS
	enter("god:%d" % randi(), String(BIOME_THEME.get(b, "cave")), pl.global_position)


func god_hell_where() -> void:
	if Game.hell_key == "":
		Game.toast.emit("Портал в ад ещё прячется: он появится в одной из первых пещер, куда ты войдёшь.", load("res://art/dun_portal_0.png"))
	else:
		Game.toast.emit("Портал в ад — в пещере региона %s. Переношу к ней!" % Game.hell_key, load("res://art/dun_portal_0.png"))
		main.call("teleport_to", Game.hell_pos + Vector2(0, 40))


func god_monster(kind: String) -> void:
	var pl: Node2D = main.get("player")
	if kind == "":
		var ks: Array = V.MONSTERS.keys()
		kind = String(ks.pick_random())
	var at: Vector2 = main.call("free_near", pl.global_position + Vector2(randf_range(-80, 80), randf_range(-60, -30)))
	spawn_monster(kind, at, 1)

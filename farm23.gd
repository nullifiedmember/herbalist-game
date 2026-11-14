extends Node
## v23: звери на ферме. Еда в руке + E у зверя — приманить (идёт за тобой в загон).
## В загоне (до 6 зверей) каждый день — свой толк (яйца, молоко, шерсть, трюфели, пух...), ночью — потомство.
## Справочник ZOO — его же показывает книга (страница «Звери»).

const W = preload("res://wild_db.gd")
const FD = preload("res://food_db.gd")
const F25 = preload("res://fauna25_db.gd")
const PEN_MAX: int = 6
const GROW_DAYS: int = 3

## вид: описание, где живёт, что любит (ключи вкуса food_db.kind или id еды), что даёт [предмет, сколько], шанс потомства
const ZOO_BASE: Dictionary = {
	"rabbit": ["Пушистый непоседа. Ушки слышат шаги за сто шагов.", "Луга, поля, эльфийский лес", ["veg", "berry"], ["rabbit_fluff", 2], 0.5],
	"fox": ["Рыжая хитрюга. Днём спит, ночью охотится на мышей.", "Берёзовые и сосновые леса, Сакураяма", ["meat", "fish"], ["fox_tuft", 1], 0.3],
	"deer": ["Стройный и пугливый. Рога сбрасывает каждую весну.", "Леса и поляны", ["veg", "fruit"], ["deer_fur", 1], 0.25],
	"boar": ["Сильный и упрямый. Носом находит трюфели под землёй.", "Сосновые и осенние леса, орочьи земли", ["veg", "mushroom", "nut"], ["truffle", 1], 0.35],
	"flat_boar": ["Кабан, на которого однажды сел великан. С тех пор плоский и очень спокойный.", "Поля, гроты, болота", ["veg", "bread"], ["boar_bristle", 2], 0.4],
	"hedgehog": ["Колючий клубочек. Фыркает, если подойти, и сворачивается.", "Луга, леса, паучий край", ["fruit", "berry", "mushroom"], ["hedgehog_quill", 2], 0.4],
	"squirrel": ["Рыжая прыгунья. Прячет орехи и забывает где.", "Берёзовые и сосновые леса", ["nut", "berry"], ["squirrel_fluff", 1], 0.4],
	"duck": ["Важная крякуша. Любит пруды и булочки.", "Болота, луга, побережье", ["bread", "veg"], ["egg_duck", 1], 0.45],
	"sapphire_hare": ["Заяц из лунного света. Шёрстка звенит, как колокольчик.", "Поляны единорогов, долина магов", ["sweet", "berry"], ["sapphire_fluff", 1], 0.15],
	"unicorn": ["Сама доброта. Даёт радужное молоко, если её любить.", "Поляны единорогов", ["sweet", "fruit"], ["milk_rainbow", 1], 0.1],
	"golden_deer": ["Олень с золотой шерстью. Его видят только честные люди.", "Эльфийский и берёзовый лес", ["fruit", "sweet"], ["golden_fur", 1], 0.1],
	"ember_fox": ["Лиса с хвостом-угольком. Тёплая, как печка.", "Гроты, осенний лес", ["meat", "fish"], ["ember_tuft", 1], 0.15],
	"chicken": ["Хлопотливая курочка. Каждое утро — тёплое яичко.", "Луга, деревни кошек, Сакураяма", ["bread", "veg", "nut"], ["egg", 1], 0.6],
	"cow": ["Добрая бурёнка. Молоко, сливки, а значит — пироги.", "Поля и рыцарские земли", ["veg", "bread"], ["milk", 1], 0.3],
	"sheep": ["Облачко на ножках. Шерсть отрастает за пару дней.", "Луга, рыцарские земли", ["veg", "bread"], ["wool_raw", 2], 0.45],
	"goat": ["Бородатая озорница. Залезет куда угодно и всё попробует.", "Поля, эльфийские холмы", ["veg", "fruit", "bread"], ["milk_goat", 1], 0.45],
	"pig": ["Розовая и умная. Тоже ищет трюфели, но делится.", "Поля", ["veg", "bread", "fruit", "soup"], ["truffle", 1], 0.5],
	"goose": ["Белый гусь. Шипит на чужих, охраняет загон.", "Поля, болота", ["bread", "veg"], ["egg_goose", 1], 0.45],
}
const ORDER_BASE: Array = ["chicken", "goose", "duck", "cow", "sheep", "goat", "pig", "rabbit", "hedgehog", "squirrel", "fox", "deer", "boar", "flat_boar", "sapphire_hare", "golden_deer", "ember_fox", "unicorn"]
# v25: + новые звери
static var ZOO: Dictionary = W._merge(ZOO_BASE, F25.ZOO)
static var ORDER: Array = ORDER_BASE + F25.ORDER

var main: Node2D
var v23: Node
var t: float = 0.0
var spawned: bool = false


func setup(m: Node2D, v: Node) -> void:
	main = m
	v23 = v
	add_to_group("farm23")
	Game.day_changed.connect(_on_day)


func _process(delta: float) -> void:
	t += delta
	if not spawned and t > 0.3:
		spawned = true
		_respawn()
	if fmod(t, 1.0) < delta:
		_mark_seen()


## После загрузки: звери из Game.farm встают в свои загоны
func _respawn() -> void:
	var hs: Node = get_tree().get_first_node_in_group("homestead")
	if hs == null:
		return
	var pens: Array = hs.get("pens")
	for e in Game.farm:
		var c: Vector2 = Vector2(float(e["x"]), float(e["y"]))
		var an: Node2D = _spawn(String(e["kind"]), c + Vector2(randf_range(-30, 30), randf_range(10, 40)))
		an.call("settle", c)
		_baby_look(an, e)
		for pn in pens:
			if (pn[0] as Vector2).distance_to(c) < 80.0:
				pn[1] = int(pn[1]) + 1


func _spawn(kind: String, at: Vector2) -> Node2D:
	var an: Node2D = Node2D.new()
	an.set_script(load("res://animal.gd"))
	(main.get("objects") as Node).add_child(an)
	an.call("setup", kind, at)
	an.set("blocked", Callable(main, "is_blocked"))
	main.call("add_caster", an.get("spr") as Sprite2D, true)
	return an


func _baby_look(an: Node2D, e: Dictionary) -> void:
	var sp: Sprite2D = an.get("spr")
	if sp != null:
		sp.scale = Vector2(0.5, 0.5) * (0.6 if bool(e.get("baby", false)) else 1.0)


func _mark_seen() -> void:
	var pl: Node2D = main.get("player")
	if pl == null:
		return
	for a in get_tree().get_nodes_in_group("animals"):
		var an: Node2D = a
		if an.global_position.distance_to(pl.global_position) < 160.0:
			var k: String = String(an.get("kind"))
			if not Game.animals_seen.has(k):
				Game.animals_seen[k] = Game.day


# ------------------------------------------------------------------ приманка едой

## Нравится ли зверю эта еда
static func likes(kind: String, food_id: String) -> bool:
	if not ZOO.has(kind) or not FD.is_food(food_id):
		return false
	var want: Array = ZOO[kind][2]
	return want.has(FD.kind(food_id)) or want.has(food_id.substr(5))


## Вызывает animal.gd: в руке еда — зверь съедает и идёт следом (если есть место в загоне)
func lure(an: Node2D, food_id: String) -> bool:
	var kind: String = String(an.get("kind"))
	var hs: Node = get_tree().get_first_node_in_group("homestead")
	if hs == null or not bool(hs.call("pen_free")) or bool(an.get("follow")):
		return false
	if not Game.take_item(food_id):
		return false
	Game.animals_seen[kind] = Game.day
	var chance: float = (0.85 if likes(kind, food_id) else 0.3) + Game.stat("tame") / 100.0
	if bool(W.ANIMALS[kind].get("mythic", false)):
		chance *= 0.5
	Game.fx.emit(an.global_position + Vector2(0, -20), "heart")
	if randf() > chance:
		Game.toast.emit("%s съел(а) угощение, но пока сомневается..." % String(W.ANIMALS[kind]["name"]), FD.icon(food_id))
		Game.skill_xp("tame", 2.0)
		return true
	an.set("follow", true)
	an.add_to_group("followers")
	var keep: Vector2 = an.global_position
	var objs: Node = main.get("objects")
	if an.get_parent() != objs:
		an.get_parent().remove_child(an)
		objs.add_child(an)
		an.global_position = keep
	Game.skill_xp("tame", 10.0)
	Game.toast.emit("%s идёт за тобой в загон!" % String(W.ANIMALS[kind]["name"]), load("res://art/fx_heart.png"))
	return true


## Зверь дошёл до загона (homestead._follow_animals)
func on_settle(an: Node2D, c: Vector2) -> void:
	Game.farm.append({"kind": String(an.get("kind")), "x": c.x, "y": c.y, "born": Game.day, "baby": false, "id": an.get_instance_id()})
	Game.skill_xp("tame", 15.0)


# ------------------------------------------------------------------ продукты и потомство

func _on_day() -> void:
	night_breed(false)
	for e in Game.farm:
		var d: Dictionary = e
		if bool(d.get("baby", false)) and Game.day - int(d.get("born", 0)) >= GROW_DAYS:
			d["baby"] = false
		if not bool(d.get("baby", false)):
			d["ready"] = mini(3, int(d.get("ready", 0)) + 1)
	for a in get_tree().get_nodes_in_group("animals"):
		var an: Node2D = a
		for e2 in Game.farm:
			if int(e2.get("id", -1)) == an.get_instance_id():
				_baby_look(an, e2)


## Ночью: в загоне два взрослых зверя одного вида — может родиться малыш
func night_breed(force: bool) -> int:
	var born: int = 0
	var hs: Node = get_tree().get_first_node_in_group("homestead")
	if hs == null:
		return 0
	for pn in (hs.get("pens") as Array):
		var c: Vector2 = pn[0]
		var by_kind: Dictionary = {}
		var total: int = 0
		for e in Game.farm:
			if Vector2(float(e["x"]), float(e["y"])).distance_to(c) < 80.0:
				total += 1
				if not bool(e.get("baby", false)):
					by_kind[String(e["kind"])] = int(by_kind.get(String(e["kind"]), 0)) + 1
		for k in by_kind.keys():
			if total >= PEN_MAX or int(by_kind[k]) < 2:
				continue
			var ch: float = float(ZOO.get(String(k), ["", "", [], [], 0.3])[4])
			if force or randf() < ch:
				var an: Node2D = _spawn(String(k), c + Vector2(randf_range(-30, 30), randf_range(10, 40)))
				an.call("settle", c)
				var e2: Dictionary = {"kind": String(k), "x": c.x, "y": c.y, "born": Game.day, "baby": true, "id": an.get_instance_id()}
				Game.farm.append(e2)
				_baby_look(an, e2)
				pn[1] = int(pn[1]) + 1
				total += 1
				born += 1
				Game.toast.emit("В загоне родился малыш: %s!" % String(W.ANIMALS[k]["name"]).to_lower(), load("res://art/fx_heart.png"))
				Game.chron("В загоне родился малыш — %s." % String(W.ANIMALS[k]["name"]).to_lower(), "farm")
	return born


## E у загона: забрать всё, что звери дали за эти дни
func collect_at(c: Vector2) -> int:
	var got: int = 0
	for e in Game.farm:
		var d: Dictionary = e
		if Vector2(float(d["x"]), float(d["y"])).distance_to(c) >= 80.0:
			continue
		var r: int = int(d.get("ready", 0))
		if r <= 0 or not ZOO.has(String(d["kind"])):
			continue
		var pr: Array = ZOO[String(d["kind"])][3]
		Game.add_item(String(pr[0]), int(pr[1]) * r)
		got += int(pr[1]) * r
		d["ready"] = 0
	if got > 0:
		Game.skill_xp("tame", float(got))
		Sound.play("ui_select", -6.0)
	return got


func pen_animals(c: Vector2) -> Array:
	var out: Array = []
	for e in Game.farm:
		if Vector2(float(e["x"]), float(e["y"])).distance_to(c) < 80.0:
			out.append(e)
	return out


# ------------------------------------------------------------------ режим бога

func god_spawn_farm() -> void:
	var pl: Node2D = main.get("player")
	if bool(main.get("inside")):
		return
	for k in ["chicken", "cow", "sheep", "goat", "pig", "goose"]:
		var at: Vector2 = main.call("free_near", pl.position + Vector2(randf_range(-90, 90), randf_range(-50, 60)))
		_spawn(String(k), at)


func god_fill_pens() -> void:
	var hs: Node = get_tree().get_first_node_in_group("homestead")
	if hs == null or (hs.get("pens") as Array).is_empty():
		Game.toast.emit("Сначала построй загон на верстаке", load("res://art/animal_pen.png"))
		return
	var pn: Array = (hs.get("pens") as Array)[0]
	for k in ["chicken", "chicken", "sheep", "sheep"]:
		if int(pn[1]) >= PEN_MAX:
			break
		var an: Node2D = _spawn(String(k), (pn[0] as Vector2) + Vector2(randf_range(-30, 30), 30))
		an.call("settle", pn[0])
		Game.farm.append({"kind": String(k), "x": (pn[0] as Vector2).x, "y": (pn[0] as Vector2).y, "born": Game.day, "baby": false, "id": an.get_instance_id(), "ready": 1})
		pn[1] = int(pn[1]) + 1


func god_unlock_book() -> void:
	for k in ORDER:
		Game.animals_seen[String(k)] = Game.day
	Game.toast.emit("Страница зверей открыта", load("res://art/fx_heart.png"))

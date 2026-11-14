extends Node
## v26: магазины королевства. Построила лавку (верстак → вкладка с короной) — выложила товар,
## и жители сами приходят и покупают. Деньги копятся в кассе лавки: E у лавки → «Забрать выручку».
## Чем больше работников, выше уровень королевства и слава лавки — тем больше покупателей.
## Данные: Game.shops["x,y"] = {"kind", "goods": {id: n}, "cash", "sold", "fame"} (сохраняется само).

const IT = preload("res://items_db.gd")
const PDB = preload("res://paths_db.gd")
const RDB = preload("res://recipes_db.gd")
const FD = preload("res://food_db.gd")
const FISH = preload("res://fish_db.gd")
const MIN = preload("res://mining_db.gd")
const HERBS = preload("res://herbs_db.gd")
const W = preload("res://wild_db.gd")
const OPEN_FROM: float = 8.0
const OPEN_TO: float = 21.0
const RESTOCK_PER_ID: int = 10

## вид постройки -> [название, наценка, что берёт]
const KINDS: Dictionary = {
	"kg_shop_potion": ["Лавка зелий", 1.35, "potion"],
	"kg_shop_food": ["Лавка снеди", 1.3, "food"],
	"kg_shop_smith": ["Лавка кованого", 1.4, "smith"],
	"kg_shop_general": ["Лавка трав и руд", 1.25, "general"],
}
## что за товар в этой лавке (для подсказки на карточке)
const KIND_ICON: Dictionary = {"potion": "icon_bottle", "food": "icon_pack", "smith": "st20_anvil", "general": "icon_log"}

var main: Node2D
var last_hour: int = -1
var instant: bool = false


func setup(m: Node2D) -> void:
	main = m
	name = "Shops26"
	add_to_group("shops26")
	last_hour = int(Game.hour())
	instant = DisplayServer.get_name() == "headless" or OS.get_cmdline_user_args().has("--test")


static func is_shop(kind: String) -> bool:
	return KINDS.has(kind)


static func shop_name(kind: String) -> String:
	return String((KINDS[kind] as Array)[0]) if KINDS.has(kind) else ""


## Берёт ли лавка такого вида эту вещь
static func accepts(kind: String, id: String) -> bool:
	if not KINDS.has(kind) or id == "murky":
		return false
	match String((KINDS[kind] as Array)[2]):
		"potion":
			return RDB.is_product(id)
		"food":
			return FD.is_food(id)
		"smith":
			return PDB.is_smith(id) or IT.is_gear(id)
		"general":
			return HERBS.DATA.has(id) or MIN.is_mineral(id) or FISH.is_fish(id) or W.is_shroom(id)
	return false


## Завести лавку в Game.shops (если ещё нет)
static func register(key: String, kind: String) -> void:
	if not Game.shops.has(key):
		Game.shops[key] = {"kind": kind, "goods": {}, "cash": 0, "sold": 0, "fame": 0}


static func goods_count(key: String) -> int:
	var n: int = 0
	if Game.shops.has(key):
		for v in (Game.shops[key]["goods"] as Dictionary).values():
			n += int(v)
	return n


## Сколько штук подходящего товара у героини в сумке (не считая панель быстрого доступа)
static func bag_count(kind: String) -> int:
	var n: int = 0
	for id in Game.inventory.keys():
		var sid: String = String(id)
		if Game.get_count(sid) > 0 and accepts(kind, sid) and not Game.hotbar.has(sid):
			n += Game.get_count(sid)
	return n


## Сколько штук подходящего товара можно подвезти из сундуков базы (по RESTOCK_PER_ID каждого вида)
func chest_count(kind: String) -> int:
	var cu: Node = get_tree().get_first_node_in_group("chest_ui")
	if cu == null:
		return 0
	var n: int = 0
	var bt: Dictionary = cu.call("base_totals")
	for id in bt.keys():
		if accepts(kind, String(id)):
			n += mini(int(bt[id]), RESTOCK_PER_ID)
	return n


# ------------------------------------------------------------------ действия с карточек лавки

func act(key: String, a: String) -> bool:
	if not Game.shops.has(key):
		return false
	var sh: Dictionary = Game.shops[key]
	var kind: String = String(sh["kind"])
	var goods: Dictionary = sh["goods"]
	match a:
		"put":
			var n: int = 0
			for id in Game.inventory.keys():
				var sid: String = String(id)
				var c: int = Game.get_count(sid)
				if c > 0 and accepts(kind, sid) and not Game.hotbar.has(sid):
					goods[sid] = int(goods.get(sid, 0)) + c
					Game.inventory[sid] = 0
					n += c
			if n == 0:
				return false
			Game.inventory_changed.emit()
			Sound.play("pickup", -6.0)
			return true
		"restock":
			var cu: Node = get_tree().get_first_node_in_group("chest_ui")
			if cu == null:
				return false
			var got: int = 0
			var bt: Dictionary = cu.call("base_totals")
			for id2 in bt.keys():
				var s2: String = String(id2)
				if accepts(kind, s2):
					var t: int = int(cu.call("base_take", s2, mini(int(bt[id2]), RESTOCK_PER_ID)))
					if t > 0:
						goods[s2] = int(goods.get(s2, 0)) + t
						got += t
			if got == 0:
				return false
			Sound.play("pickup", -6.0)
			return true
		"take":
			if goods.is_empty():
				return false
			for id3 in goods.keys():
				Game.inventory[String(id3)] = Game.get_count(String(id3)) + int(goods[id3])
			goods.clear()
			Game.inventory_changed.emit()
			Sound.play("pickup", -6.0)
			return true
		"cash":
			var cash: int = int(sh["cash"])
			if cash <= 0:
				return false
			sh["cash"] = 0
			Game.add_coins(cash)
			return true
	return false


# ------------------------------------------------------------------ покупатели

func _process(_delta: float) -> void:
	var h: int = int(Game.hour())
	if h != last_hour:
		last_hour = h
		_hour_tick(float(h))


## Шанс за час, что придёт покупатель: жители королевства, слава, день недели не важен
func customer_chance(key: String) -> float:
	var sh: Dictionary = Game.shops[key]
	var lvl: int = int(Game.kingdom.get("level", 0)) if not Game.kingdom.is_empty() else 0
	var c: float = 0.12 + 0.02 * float(Game.workers.size()) + 0.04 * float(lvl) + minf(0.25, float(int(sh.get("fame", 0))) * 0.004)
	return minf(c, 0.9)


func _hour_tick(h: float) -> void:
	if h < OPEN_FROM or h >= OPEN_TO:
		return
	var keys: Array = Game.shops.keys()
	for k in keys:
		var key: String = String(k)
		if goods_count(key) <= 0:
			continue
		var tries: int = 1 + Game.workers.size() / 8
		for i in range(tries):
			if randf() < customer_chance(key):
				send_customer(key)


func shop_pos(key: String) -> Vector2:
	var pp: PackedStringArray = key.split(",")
	return Vector2(float(pp[0]), float(pp[1])) if pp.size() >= 2 else Game.home_pos


func send_customer(key: String) -> void:
	if instant:
		sell_one(key)
		return
	var cu: Node2D = Node2D.new()
	cu.set_script(load("res://customer.gd"))
	var at: Vector2 = shop_pos(key)
	var ang: float = randf_range(0.2, PI - 0.2)
	var from: Vector2 = at + Vector2(cos(ang) * 340.0, sin(ang) * 260.0)
	cu.call("setup", from, at + Vector2(randf_range(-22.0, 22.0), 34.0), Callable(self, "sell_one").bind(key), randi())
	(main.get("objects") as Node).add_child(cu)


## Купили одну вещь. Возвращает цену (0 — товара уже нет)
func sell_one(key: String) -> int:
	if not Game.shops.has(key):
		return 0
	var sh: Dictionary = Game.shops[key]
	var goods: Dictionary = sh["goods"]
	var ids: Array = []
	for k in goods.keys():
		if int(goods[k]) > 0:
			ids.append(String(k))
	if ids.is_empty():
		return 0
	var id: String = String(ids.pick_random())
	var mark: float = float((KINDS[String(sh["kind"])] as Array)[1])
	var pr: int = maxi(1, int(round(float(PDB.price(id)) * mark * (1.0 + Game.stat("sell") / 100.0))))
	goods[id] = int(goods[id]) - 1
	if int(goods[id]) <= 0:
		goods.erase(id)
	sh["cash"] = int(sh["cash"]) + pr
	sh["fame"] = int(sh.get("fame", 0)) + 1
	sh["sold"] = int(sh.get("sold", 0)) + 1
	Game.count_add("sold")
	Sound.play("coin", -10.0, 0.08, shop_pos(key))
	return pr

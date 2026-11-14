extends Node
## Глобальное состояние: сумка, семена, день и время суток.

signal inventory_changed
signal day_changed
signal toast(text: String, icon: Texture2D)
signal fx(pos: Vector2, kind: String)
signal sleep_requested
signal mermaid_ended               # хвост исчез
signal midnight                    # наступил новый день, а героиня не спит
signal accident(kind: String)       # не добежала: "pee" или "poo"

const DB = preload("res://herbs_db.gd")
const RDB = preload("res://recipes_db.gd")
const FDB = preload("res://fish_db.gd")
const MIN_PER_SEC: float = 1.6     # игровых минут за секунду: час = 37,5 сек

var inventory: Dictionary = {}
var seeds: Dictionary = {"mint": 4, "lavender": 3, "chamomile": 3}
var discovered: Dictionary = {}
var day: int = 1
var minutes: float = 8.0 * 60.0
var coins: int = 0
var journal: Array = []             # попытки варки: {base, a, b, result}
var known_recipes: Dictionary = {}  # id зелья -> {base, temp, ings} (первый удачный рецепт)
## Котёл дома: что налито (основа -> сколько бутылочек), тепло воды (сумма температур × объём), что брошено
var cauldron: Dictionary = {"liq": {}, "heat": 0.0, "ings": []}
var order: Dictionary = {}          # текущий заказ жителя
var orders_done: int = 0
# потребности: 0 — всё хорошо, 1 — терпеть уже нельзя
const PEE_PER_MIN: float = 1.0 / 1500.0  # по-маленькому: полный пузырь за ~25 игровых часов (больше суток)
const POO_PER_MIN: float = 1.0 / 3000.0  # по-большому: за ~50 игровых часов (двое суток)
const HUNGER_PER_MIN: float = 1.0 / 1800.0  # голод: от сытой до очень голодной за ~30 игровых часов
const THIRST_PER_MIN: float = 1.0 / 1320.0  # жажда: за ~22 игровых часа
var hunger: float = 0.15             # 0 — сыта, 1 — очень голодна
## v16: усталость. 0 — выспалась, 0.8+ — так устала, что ничего не может (ни собирать, ни рубить, ни варить),
## 1 — падает без сил и просыпается дома. Полная за ~19 игровых часов без сна, бег утомляет вдвое быстрее.
const FATIGUE_PER_MIN: float = 1.0 / 2400.0   # можно не спать больше суток (было 1/1140 — падала через 19 ч)
const TIRED_AT: float = 0.8
var fatigue: float = 0.1
var running_now: bool = false
var thirst: float = 0.15             # 0 — напилась, 1 — очень хочет пить
var shame: float = 0.0               # стыд после конфуза: 1 — сгорает со стыда, спадает за ~4 игровых часа
const SHAME_DECAY_PER_MIN: float = 1.0 / 240.0
var pee: float = 0.1
var poo: float = 0.05
const LOAD_BOOST: float = 1.5            # во сколько раз быстрее копится, пока внутри много жидкости или еды
var drink_load: float = 0.0              # выпитое: ускоряет по-маленькому, уходит за ~2 игровых часа
var food_load: float = 0.0               # съеденное: ускоряет по-большому, уходит за ~5 игровых часов
var consume_cd: float = 0.0              # чтобы не съесть сто яблок за секунду
var has_rod: bool = false
var has_mop: bool = false
var has_net: bool = false
var caught: Dictionary = {}        # вид -> сколько поймано сачком
var herb_bonus: int = 0             # сколько диких трав больше/меньше наутро (бабочки опыляют, кузнечики объедают)
var bites: int = 0                  # сколько раз кусали комары           # швабра в руках (берётся в ведре на кухне)           # удочка и снасти взяты из шкафа
var fish_caught: Dictionary = {}    # id рыбы -> сколько поймано за всё время
var ui_open: bool = false
var busy: bool = false              # сон/переходы
var time_frozen: bool = false
var met: Dictionary = {}              # встреченные мифические звери: вид -> день
var picked: Dictionary = {}           # сорванные грибы: место -> день
var gifts: Dictionary = {}            # подарки лидеров: земля -> день
var hotbar: Array = ["axe", "", "", "", "", "", "", "", ""]   # панель (9 ячеек, клавиши 1-9) быстрого доступа: что в каких ячейках
var hot_sel: int = 0                  # какая ячейка в руках
var plot_level: int = 0               # сколько раз расширяла участок
var researched: Dictionary = {}       # изученные травы (дороже продаются)
var dryer: Array = []                 # v19: пучки на сушилке: {id, hook, t0 (игровые минуты)}
var pets: Array = []                  # v19: питомцы из приютов: {kind, name}
var chest: Dictionary = {}            # содержимое сундуков: предмет -> сколько
var rep: Dictionary = {}              # репутация с землями: земля -> -100..100
var rep_today: Dictionary = {}        # сколько репутации уже набрано разговорами сегодня: земля -> число
var explored: PackedByteArray = PackedByteArray()   # туман карты: 0 — не была, 255 — открыто

# ---- v20: места, птицы, ловушки, двор
var places_seen: Dictionary = {}        # место (ключ places.gd) -> true: мелодия места звучит только в первый раз
var traps20: Dictionary = {}            # "x,y" -> {bait, caught, since (игровые минуты)}
var yard20: Dictionary = {}             # "вид:x,y" -> состояние улья, бочки, компоста, кормушки...
var birds_seen: Dictionary = {}         # вид птицы -> сколько раз поймала (для книги)
var birds_met: Dictionary = {}          # v24: птицы, которых видела вблизи (страница в книге открывается)
var whisker_day: int = -1               # когда кот последний раз оставил ус
var map_zoom: float = 1.0               # приближение карты на M

# ---- v17: записи в книге, деревья, спутники
var notes: Dictionary = {}              # id травы/гриба/еды -> [строки, что рассказали жители]
var misc_notes: Array = []              # советы без привязки к странице: звери, места, жизнь [{"cat","text"}]
var tips_heard: Dictionary = {}         # id подсказки -> true (чтобы не повторяться)
var tree_state: Dictionary = {}         # "дерево:x,y" -> {"leaf": {индекс: день}, "fruit": {индекс: день}}
var team: Array = []                    # спутники: [{tex, name, land, req, fee, wage, perk, loyalty, ...}]
signal note_added(cat: String)
signal team_changed
const TEAM_MAX: int = 3

# ---- ранний доступ: свои пути (paths.gd, paths_db.gd). Всё здесь сохраняется само (saves.gd).
var stall: Dictionary = {"goods": {}, "cash": 0, "lure_until": -1.0, "lure_cd": -1.0, "fame": 0, "sold": 0}
var pacts: Dictionary = {}              # земля -> {"since", "earned"} — торговый союз с королевством
var caravans: Array = []                # караваны: {"land", "due" (день), "coins", "goods"}
var royal: Dictionary = {}              # земля -> королевский заказ {"item", "n", "due", "reward"}
var smith_orders: Dictionary = {}       # земля -> заказ кузнецу {"item", "n", "due", "reward"}
var court: Dictionary = {}              # земля -> с какого дня придворная травница
var factions: Dictionary = {}           # id -> {"favor", "rank", "task": {}, "since"}
var counters: Dictionary = {}           # sold, forged, healed, donated, caravans, orders...
var chronicle: Array = []               # летопись: [{"day", "text", "kind"}]
var titles: Array = []                  # титулы (paths_db.TITLES)
var guide_step: int = 0                 # первые шаги без текста (guide.gd)
var healed_today: Dictionary = {}       # имя -> день, когда вылечила
var paths_day: int = 1                  # последний день, за который начислены зарплаты и караваны


## Летопись: запомнить событие своей истории
func chron(text: String, kind: String = "") -> void:
	chronicle.append({"day": day, "text": text, "kind": kind})


func count_add(key: String, n: int = 1) -> void:
	counters[key] = int(counters.get(key, 0)) + n


func add_title(id: String) -> void:
	if titles.has(id):
		return
	titles.append(id)
	var nm: String = String(preload("res://paths_db.gd").TITLES.get(id, id))
	chron("Новый титул: %s" % nm, "title")
	toast.emit("✦ %s" % nm, load("res://art/fx_heart.png"))


## Запомнить совет в книге. Возвращает true, если он новый.
func learn_tip(tip: Dictionary) -> bool:
	var tid: String = String(tip.get("id", ""))
	if tid == "" or tips_heard.has(tid):
		return false
	tips_heard[tid] = true
	var target: String = String(tip.get("target", ""))
	var text: String = String(tip.get("text", ""))
	if target != "":
		var arr: Array = notes.get(target, [])
		arr.append(text)
		notes[target] = arr
	else:
		misc_notes.append({"cat": String(tip.get("cat", "life")), "text": text})
	note_added.emit(String(tip.get("cat", "")))
	return true


## Съесть или выпить еду из сумки
func eat_item(id: String) -> bool:
	var FD = preload("res://food_db.gd")
	if not FD.is_food(id) or get_count(id) <= 0 or consume_cd > 0.0:
		return false
	take_item(id)
	var h: float = FD.hunger_of(id)
	var j: float = FD.juicy_of(id)
	if FD.is_drink(id):
		Sound.play("gulp", -4.0)
	else:
		Sound.play("munch", -4.0)
	hunger = maxf(0.0, hunger - h)
	thirst = maxf(0.0, thirst - j)
	food_load = minf(2.0, food_load + h)
	drink_load = minf(2.0, drink_load + j)
	if TOILET_ENABLED:
		poo = minf(0.97, poo + 0.03 * h * 2.0)
		pee = minf(0.97, pee + 0.04 * j * 2.0)
	consume_cd = 0.8
	eaten[id] = int(eaten.get(id, 0)) + 1
	discovered[id] = true
	return true


var eaten: Dictionary = {}              # id еды -> сколько съедено
var cooked: Dictionary = {}             # id блюд, которые уже готовила

# ---- нужды в туалет выключены (код оставлен; в автотесте --test включаются, чтобы старые проверки работали)
var TOILET_ENABLED: bool = OS.get_cmdline_user_args().has("--test")

# ---- снаряжение (инвентарь на Tab в духе Path of Exile)
# слоты: main1/off1 и main2/off2 — два набора рук (I/II, переключение X), head, body, hands, feet,
# neck, ring1, ring2, belt, pack (рюкзак), flask0..flask4 (зелья на поясе, пьются клавишами Z / по клику)
var equip: Dictionary = {}
var weapon_set: int = 0                 # 0 — набор I, 1 — набор II
var buff_t: float = 0.0                 # сколько ещё действует выпитое зелье (бодрость: +скорость)
var scenario: String = "herbalist"     # сценарий новой игры (scenarios_db.gd)
var home_pos: Vector2 = Vector2(960, 358)   # где стоит дом (ноги дома); по умолчанию — старый двор
var home_biome: String = "home"
var new_game_ready: bool = false        # сценарий и место выбраны — после перезапуска сцены сразу играть
var shop_sold: Dictionary = {}          # купленное с полок лавок: "лавка:номер" -> день
var light_on: bool = false              # в руке горит факел/фонарь (ночью — свет вокруг)
var in_sea: bool = false                # v22: героиня сейчас плывёт по морю (ставит main)
var mermaid_t: float = 0.0              # v22: сколько игровых минут ещё держится хвост русалки
var mermaid_ever: int = 0               # сколько раз пила эликсир русалочьего хвоста
var event_done_day: int = 0             # v22: за какой день уже выданы подарки события
var goals_done: Dictionary = {}         # v22: выполненные цели (goals_db.gd) -> день
var day_log: Dictionary = {}            # v22: итоги вчерашнего дня и счётчики на сегодня
var god_mode: bool = false             # режим бога: голод/жажда не растут, перегруза нет, предметы из меню
signal equip_changed


## Что надето в слоте ("" — пусто)
func worn(slot: String) -> String:
	return String(equip.get(slot, ""))


## Слот руки в текущем наборе
func hand_slot(off: bool) -> String:
	return ("off" if off else "main") + str(weapon_set + 1)


## Инструмент в руках по набору (или в панели быстрого доступа)
func has_tool(id: String) -> bool:
	return worn(hand_slot(false)) == id or worn(hand_slot(true)) == id or held() == id


## Сумма свойства по надетым вещам и сценарию: cap, speed, herb, shroom, sell, brew, hunger, thirst, light
func stat(key: String) -> float:
	var IT = preload("res://items_db.gd")
	var s: float = float((preload("res://scenarios_db.gd").get_s(scenario).get("stats", {}) as Dictionary).get(key, 0.0))
	for slot in equip.keys():
		var sl: String = String(slot)
		if sl.begins_with("flask"):
			continue
		if (sl.begins_with("main") or sl.begins_with("off")) and not sl.ends_with(str(weapon_set + 1)):
			continue
		var g: Dictionary = IT.gear(String(equip[slot]))
		s += float((g.get("stats", {}) as Dictionary).get(key, 0.0))
	if key == "speed" and buff_t > 0.0:
		s += 20.0
	if pbuff_t > 0.0:
		s += float(pbuff.get(key, 0.0))   # v26: эффект выпитого зелья (item_info.POTION_FX)
	if key == "speed" and mermaid_t > 0.0 and in_sea:
		s += 35.0                      # хвост: в воде плывёт быстрее, чем ходит
	s += preload("res://events_db.gd").mod(day, key)
	for m in team:
		s += float(((m as Dictionary).get("perk", {}) as Dictionary).get(key, 0.0))
	s += skill_bonus(key) + float(perm.get(key, 0.0))
	# фракции: прибавка за каждое звание (0-е звание — уже +1 шаг)
	for fid in factions.keys():
		var fr: Dictionary = factions[fid]
		var fd: Dictionary = preload("res://paths_db.gd").faction(String(fid))
		if not fd.is_empty():
			s += float((fd["perk"] as Dictionary).get(key, 0.0)) * float(int(fr.get("rank", 0)) + 1)
	return s


## Надеть предмет из сумки в слот. Старое возвращается в сумку.
func equip_item(id: String, slot: String) -> bool:
	var IT = preload("res://items_db.gd")
	if not IT.fits(id, slot) or get_count(id) <= 0:
		return false
	var old: String = worn(slot)
	inventory[id] = get_count(id) - 1
	equip[slot] = id
	if old != "":
		inventory[old] = get_count(old) + 1
	inventory_changed.emit()
	equip_changed.emit()
	return true


func unequip(slot: String) -> void:
	var old: String = worn(slot)
	if old == "":
		return
	equip.erase(slot)
	inventory[old] = get_count(old) + 1
	inventory_changed.emit()
	equip_changed.emit()


## Сколько ячеек зелий на поясе: без пояса 2, верёвочный 3, кожаный 5
func flask_slots() -> int:
	var b: String = worn("belt")
	return int((preload("res://items_db.gd").gear(b).get("flasks", 2)) if b != "" else 2)


var last_drink: String = ""

## Эликсир русалочьего хвоста: 8 игровых часов
const MERMAID_MIN: float = 480.0


func drink_mermaid() -> void:
	mermaid_t = MERMAID_MIN
	mermaid_ever += 1
	count_add("mermaid")
	toast.emit("Ноги слились в хвост!", load("res://art/fx_heart.png"))


## Выпить зелье из ячейки пояса: жажда проходит, минуту бодрость (+20% к скорости)
func drink_flask(i: int) -> bool:
	if i >= flask_slots():
		return false
	var slot: String = "flask%d" % i
	var id: String = worn(slot)
	if id == "":
		return false
	equip.erase(slot)
	# следующее такое же зелье из сумки само встаёт на пояс
	if get_count(id) > 0:
		inventory[id] = get_count(id) - 1
		equip[slot] = id
	drink(0.6)
	hunger = maxf(0.0, hunger - 0.1)
	buff_t = 60.0
	last_drink = id
	_potion_fx(id)
	if id == "mermaid_tail":
		drink_mermaid()
	inventory_changed.emit()
	equip_changed.emit()
	return true


## v26: у каждого зелья свой эффект — по главному свойству (item_info.gd)
var pbuff: Dictionary = {}
var pbuff_t: float = 0.0


func _potion_fx(id: String) -> void:
	var fx: Array = preload("res://item_info.gd").potion_fx(id)
	if fx.is_empty():
		return
	match String(fx[3]):
		"fresh":
			thirst = 0.0
			hunger = maxf(0.0, hunger - 0.3)
		"calm":
			shame = 0.0
		"heal":
			hp = hp_max()
		"heal_half":
			hp = minf(hp_max(), hp + hp_max() * 0.5)
	if float(fx[2]) > 0.0 and not (fx[1] as Dictionary).is_empty():
		pbuff = (fx[1] as Dictionary).duplicate()
		pbuff_t = float(fx[2])
	toast.emit(String(fx[0]), load("res://art/fx_heart.png"))


## ---- ветер ----
## wind: 0 — почти штиль, 1 — очень сильный ветер. wind_dir: -1 влево, +1 вправо.
## Всё остальное (растения, волосы, плащ, листья) читает эти числа.
const WIND_ENABLED: bool = false   # переменный ветер выключен по просьбе; true — включить обратно
var wind: float = 0.0
var wind_dir: float = 1.0
var wind_override: float = -1.0     # для проверок: --wind=0.8 фиксирует силу
var _wind_level: float = 0.1        # «погода»: к ней плавно тянется ветер
var _wind_dir_goal: float = 1.0
var _wind_hold: float = 4.0
var _gust: float = 0.0
var _gust_timer: float = 3.0


func _ready() -> void:
	inventory_changed.connect(layout_sync)
	equip_changed.connect(layout_sync)
	RenderingServer.global_shader_parameter_add("wind_force", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, wind)
	RenderingServer.global_shader_parameter_add("wind_dir", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, wind_dir)
	for a in OS.get_cmdline_user_args():
		var s: String = String(a)
		if s.begins_with("--wind="):
			wind_override = clampf(s.substr(7).to_float(), 0.0, 1.0)
			wind = wind_override


## Словами: какой сейчас ветер и куда дует
func wind_text() -> String:
	var name: String = "штиль"
	if wind >= 0.92:
		name = "ураган"
	elif wind >= 0.75:
		name = "очень сильный"
	elif wind >= 0.5:
		name = "сильный"
	elif wind >= 0.25:
		name = "умеренный"
	elif wind >= 0.08:
		name = "слабый"
	if wind < 0.08:
		return name
	return name + (", вправо" if wind_dir >= 0.0 else ", влево")


func _update_wind(delta: float) -> void:
	if not WIND_ENABLED:
		return
	if wind_override >= 0.0:
		wind = wind_override
	else:
		_wind_hold -= delta
		if _wind_hold <= 0.0:
			# новая «погода»: то штиль, то ровный ветер, то буря
			var r: float = randf()
			if r < 0.28:
				_wind_level = randf_range(0.0, 0.06)
				if randf() < 0.4:
					_wind_dir_goal = -_wind_dir_goal   # направление меняется только в тишину
			elif r < 0.62:
				_wind_level = randf_range(0.25, 0.5)
			elif r < 0.85:
				_wind_level = randf_range(0.6, 0.8)
			else:
				_wind_level = randf_range(0.9, 1.0)
			_wind_hold = randf_range(14.0, 40.0)
		_gust_timer -= delta
		if _gust_timer <= 0.0:
			_gust = randf_range(0.15, 0.5) * (0.4 + _wind_level)
			_gust_timer = randf_range(2.5, 8.0)
		_gust = maxf(0.0, _gust - delta * 0.35)
		wind = lerpf(wind, clampf(_wind_level + _gust, 0.0, 1.0), 1.0 - exp(-0.55 * delta))
	wind_dir = lerpf(wind_dir, _wind_dir_goal, 1.0 - exp(-0.5 * delta))
	RenderingServer.global_shader_parameter_set("wind_force", wind)
	RenderingServer.global_shader_parameter_set("wind_dir", wind_dir)


## Вода в сумке остывает: горячая -> тёплая -> холодная, раз в 3 игровых часа
const COOL_MIN: float = 180.0
var cool_t: float = 0.0


func _cool_water(dm: float) -> void:
	if get_count("water_hot") <= 0 and get_count("water_warm") <= 0:
		cool_t = 0.0
		return
	cool_t += dm
	if cool_t < COOL_MIN:
		return
	cool_t = 0.0
	var w: int = get_count("water_warm")
	var h: int = get_count("water_hot")
	inventory["water_warm"] = h
	inventory["water_cold"] = get_count("water_cold") + w
	inventory["water_hot"] = 0
	inventory_changed.emit()


func _process(delta: float) -> void:
	_update_wind(delta)
	if ui_open or busy or time_frozen:
		return
	minutes += delta * MIN_PER_SEC
	_cool_water(delta * MIN_PER_SEC)
	if not god_mode:
		fatigue = minf(1.0, fatigue + delta * MIN_PER_SEC * FATIGUE_PER_MIN * (2.0 if running_now else 1.0))
	shame = maxf(0.0, shame - delta * MIN_PER_SEC * SHAME_DECAY_PER_MIN)
	if TOILET_ENABLED:
		pee += delta * MIN_PER_SEC * pee_rate()
		poo += delta * MIN_PER_SEC * poo_rate()
	else:
		pee = 0.0
		poo = 0.0
	buff_t = maxf(0.0, buff_t - delta)
	pbuff_t = maxf(0.0, pbuff_t - delta)
	if mermaid_t > 0.0:
		mermaid_t = maxf(0.0, mermaid_t - delta * MIN_PER_SEC)
		if mermaid_t <= 0.0:
			mermaid_ended.emit()
	if not god_mode:
		hunger = minf(1.0, hunger + delta * MIN_PER_SEC * HUNGER_PER_MIN * (1.0 + stat("hunger") / 100.0))
		thirst = minf(1.0, thirst + delta * MIN_PER_SEC * THIRST_PER_MIN * (1.0 + stat("thirst") / 100.0))
	drink_load = maxf(0.0, drink_load - delta * MIN_PER_SEC / 120.0)
	food_load = maxf(0.0, food_load - delta * MIN_PER_SEC / 300.0)
	consume_cd = maxf(0.0, consume_cd - delta)
	if TOILET_ENABLED and pee >= 1.0:
		pee = 0.15
		accident.emit("pee")
	if TOILET_ENABLED and poo >= 1.0:
		poo = 0.1
		accident.emit("poo")
	if minutes >= 24.0 * 60.0:
		# полночь: новый день наступает там, где стоит героиня (без переноса домой)
		minutes -= 24.0 * 60.0
		day += 1
		get_tree().call_group("plots", "on_new_day")
		day_changed.emit()
		midnight.emit()


## Скорость наполнения шкал: любая жидкость ускоряет по-маленькому, еда — по-большому
func pee_rate() -> float:
	return PEE_PER_MIN * (1.0 + LOAD_BOOST * drink_load)


func poo_rate() -> float:
	return POO_PER_MIN * (1.0 + LOAD_BOOST * food_load)


## Выпила: s — сколько (вода 0.5, чай 0.8)
func drink(s: float) -> void:
	Sound.play("gulp", -4.0)
	thirst = maxf(0.0, thirst - 0.5 * s)
	drink_load = minf(2.0, drink_load + s)
	if TOILET_ENABLED:
		pee = minf(0.97, pee + 0.04 * s)
	consume_cd = 1.2


## Поела: s — насколько сытно, juicy — сколько в еде жидкости (яблоко сочное)
func eat(s: float, juicy: float = 0.0) -> void:
	Sound.play("munch", -4.0)
	hunger = maxf(0.0, hunger - 0.45 * s)
	thirst = maxf(0.0, thirst - 0.5 * juicy)
	food_load = minf(2.0, food_load + s)
	drink_load = minf(2.0, drink_load + juicy)
	if TOILET_ENABLED:
		poo = minf(0.97, poo + 0.03 * s)
		pee = minf(0.97, pee + 0.01 + 0.03 * juicy)
	consume_cd = 1.2


## Сильно голодна или хочет пить — идёт медленнее и грустит
func weak() -> bool:
	return hunger > 0.85 or thirst > 0.85


## Сколько сидит в туалете: по-маленькому от 3 секунд, по-большому от 6; чем полнее шкала, тем дольше
func toilet_big() -> bool:
	return poo >= 0.3


func toilet_seconds() -> float:
	if toilet_big():
		return 6.0 + 6.0 * clampf((poo - 0.3) / 0.7, 0.0, 1.0)
	return 3.0 + 3.0 * clampf((pee - 0.15) / 0.85, 0.0, 1.0)


func hour() -> float:
	return minutes / 60.0


func clock_text() -> String:
	var m: int = int(minutes)
	return "%02d:%02d" % [(m / 60) % 24, (m % 60) / 10 * 10]


## 0 днём, 1 глубокой ночью
func night_factor() -> float:
	var h: float = hour()
	if h < 5.0:
		return 1.0
	if h < 6.5:
		return 1.0 - (h - 5.0) / 1.5
	if h < 19.3:
		return 0.0
	if h < 21.3:
		return (h - 19.3) / 2.0
	return 1.0


## Солнце: t = 0 восход (восток, справа), 0.5 полдень, 1 закат (запад, слева)
func sun_t() -> float:
	return clampf((hour() - 6.0) / 14.0, 0.0, 1.0)


## Высота солнца 0..1 (0 — у горизонта или ночь)
func sun_elevation() -> float:
	var h: float = hour()
	if h < 6.0 or h > 20.0:
		return 0.0
	return sin(sun_t() * PI)


## Сила «золотого часа»: утро и вечер
func golden() -> float:
	var h: float = hour()
	var m: float = clampf(1.0 - absf(h - 7.3) / 1.8, 0.0, 1.0)
	var e: float = clampf(1.0 - absf(h - 18.0) / 2.0, 0.0, 1.0)
	return maxf(m, e)


func add_item(item_id: String, count: int = 1) -> void:
	Sound.play("pickup", -6.0)
	var current: int = int(inventory.get(item_id, 0))
	inventory[item_id] = current + count
	discovered[item_id] = true
	var hd: Dictionary = preload("res://herbs_db.gd").DATA
	if hd.has(item_id) and count > 0:
		count_add("herbs", count)                    # v22: для целей и итогов дня
		if ((hd[item_id] as Dictionary).get("biomes", []) as Array).has(19):
			count_add("sea_herbs", count)
	inventory_changed.emit()
	if count > 0:
		_skill_from_item(item_id, count)
	if FDB.is_fish(item_id):
		fish_caught[item_id] = int(fish_caught.get(item_id, 0)) + count
		toast.emit("+%d %s" % [count, FDB.title(item_id)], FDB.icon(item_id))
	elif RDB.is_product(item_id):
		toast.emit("+%d %s" % [count, RDB.name(item_id)], RDB.icon(item_id))
	elif preload("res://wild_db.gd").is_shroom(item_id):
		toast.emit("+%d %s" % [count, preload("res://wild_db.gd").shroom_name(item_id)], preload("res://wild_db.gd").shroom_icon(item_id))
	elif preload("res://items_db.gd").is_new(item_id):
		toast.emit("+%d %s" % [count, preload("res://items_db.gd").name(item_id)], preload("res://items_db.gd").icon(item_id))
		# новое в руки: инструменты, саженцы, постройки сами встают на свободную ячейку панели
		var gs: String = String(preload("res://items_db.gd").gear(item_id).get("slot", "tool"))
		if not hotbar.has(item_id) and (not preload("res://items_db.gd").ITEMS.has(item_id) or item_id == "axe") and not item_id.begins_with("bug_") and not item_id.begins_with("food_") and not item_id.begins_with("leaf_") and not preload("res://mats_db.gd").has(item_id) and not preload("res://items_db.gd").v23_item(item_id) and gs == "tool" and not ([worn("main1"), worn("off1"), worn("main2"), worn("off2")].has(item_id)):
			var free_i: int = hotbar.find("")
			if free_i >= 0:
				hotbar[free_i] = item_id
	else:
		toast.emit("+%d %s" % [count, DB.short(item_id)], DB.icon(item_id))


## Тратит предмет. true, если хватило.
func take_item(item_id: String, count: int = 1) -> bool:
	var c: int = get_count(item_id)
	if c < count:
		return false
	inventory[item_id] = c - count
	inventory_changed.emit()
	return true


func add_coins(n: int) -> void:
	Sound.play("coin", -4.0)
	coins += n
	if n > 0:
		count_add("earned", n)
		skill_xp("trade", float(n) / 10.0)
	inventory_changed.emit()
	toast.emit("+%d монет" % n, load("res://art/coin.png"))


## Варка: тратит две травы, возвращает id результата (или "" если трав нет)
func brew(base: String, a: String, b: String) -> String:
	if a == b and get_count(a) < 2:
		return ""
	if get_count(a) < 1 or get_count(b) < 1:
		return ""
	take_item(a)
	take_item(b)
	return brew_mix(base, "warm", [{"id": a, "procs": []}, {"id": b, "procs": []}])


## Что налито в котёл больше всего
func cauldron_base() -> String:
	var best: String = ""
	var bv: float = 0.0
	var liq: Dictionary = cauldron["liq"]
	for k in liq.keys():
		if float(liq[k]) > bv:
			bv = float(liq[k])
			best = String(k)
	return best


## Температура воды в котле: 0 холодная, 1 тёплая, 2 горячая (в среднем)
func cauldron_temp() -> String:
	var w: float = float((cauldron["liq"] as Dictionary).get("water", 0.0))
	if w <= 0.0:
		return "warm"
	var t: float = float(cauldron["heat"]) / w
	return "cold" if t < 0.5 else ("hot" if t > 1.5 else "warm")


func cauldron_amount() -> float:
	var s: float = 0.0
	for v in (cauldron["liq"] as Dictionary).values():
		s += float(v)
	return s


func cauldron_clear() -> void:
	cauldron = {"liq": {}, "heat": 0.0, "ings": []}


## Сварить: ингредиенты [{id, procs}] уже потрачены (лежат в котле)
func brew_mix(base: String, temp: String, ings: Array) -> String:
	var res: String = RDB.brew_mix(base, temp, ings)
	journal.push_front({"base": base, "temp": temp, "ings": ings.duplicate(true), "result": res})
	if journal.size() > 60:
		journal.resize(60)
	var fresh: bool = res != "murky" and not known_recipes.has(res)
	if fresh:
		known_recipes[res] = {"base": base, "temp": temp, "ings": ings.duplicate(true)}
	add_item(res, 2 if (res != "murky" and randf() * 100.0 < stat("brew")) else 1)
	get_tree().call_group("player", "react", "sad" if res == "murky" else "happy", 2.0)
	return res


func get_count(item_id: String) -> int:
	return int(inventory.get(item_id, 0))


## Берёт одно семечко (первого типа, который есть). Возвращает id или "".
func take_seed() -> String:
	for id in DB.SEEDS:
		if int(seeds.get(id, 0)) > 0:
			seeds[id] = int(seeds[id]) - 1
			inventory_changed.emit()
			return String(id)
	return ""


func next_seed() -> String:
	for id in DB.SEEDS:
		if int(seeds.get(id, 0)) > 0:
			return String(id)
	return ""


## Раньше: «слишком устала, чтобы работать». Теперь собирать, рубить, добывать и варить можно всегда;
## усталость только замедляет шаг (sleepy()) и в конце концов валит с ног (main._faint).
func tired() -> bool:
	return false


func sleepy() -> bool:
	return fatigue >= TIRED_AT and not god_mode


func next_day() -> void:
	day += 1
	mermaid_t = 0.0                 # за ночь хвост уходит
	minutes = 6.5 * 60.0
	fatigue = 0.0
	shame = maxf(0.0, shame - 0.5)
	drink_load *= 0.3
	food_load *= 0.3
	if TOILET_ENABLED:
		pee = minf(pee + 0.25, 0.9)    # за ночь хочется, но не до конфуза
		poo = minf(poo + 0.25, 0.9)
	get_tree().call_group("plots", "on_new_day")
	hp = hp_max()
	day_changed.emit()


# ------------------------------------------------------------------ репутация

const REP_TIERS: Array = [[-40, "враждебная"], [-10, "холодная"], [15, "нейтральная"], [50, "дружеская"], [80, "уважаемая"], [999, "тебя обожают"]]


func rep_of(land: String) -> int:
	return int(rep.get(land, 0))


## Уровень: 0 враждебная, 1 холодная, 2 нейтральная, 3 дружеская, 4 уважаемая, 5 обожают
func rep_tier(land: String) -> int:
	var v: int = rep_of(land)
	for i in range(REP_TIERS.size()):
		if v < int(REP_TIERS[i][0]):
			return i
	return REP_TIERS.size() - 1


func rep_name(land: String) -> String:
	return String(REP_TIERS[rep_tier(land)][1])


## Изменить репутацию. small — мелочь от разговоров (не больше +6 за день с одной землёй)
func rep_add(land: String, d: int, small: bool = false) -> void:
	if land == "":
		return
	if small and d > 0:
		var key: String = "%s_%d" % [land, day]
		var got: int = int(rep_today.get(key, 0))
		if got >= 6:
			return
		rep_today[key] = got + d
	var before: int = rep_tier(land)
	rep[land] = clampi(rep_of(land) + d, -100, 100)
	var after: int = rep_tier(land)
	var nm: String = String(preload("res://npc_db.gd").land(land).get("name", land))
	if after != before:
		toast.emit("%s: репутация теперь %s" % [nm, rep_name(land)], null)
	elif absi(d) >= 3:
		toast.emit("%s: репутация %s%d" % [nm, "+" if d > 0 else "", d], null)


## Цена у торговцев: друзьям скидка, недругам дороже
func rep_price(land: String, base: int) -> int:
	var k: float = [1.5, 1.25, 1.0, 0.9, 0.8, 0.7][rep_tier(land)]
	if god_mode:
		return 0
	return maxi(1, int(round(base * k * (1.0 - stat("buy") / 100.0))))


# ------------------------------------------------------------------ вес и руки

func carried() -> float:
	var w: float = 0.0
	var pk: String = worn("pack")
	for id in inventory.keys():
		w += float(inventory[id]) * preload("res://items_db.gd").weight_in(String(id), pk)
	return w


# ================================================================== сумка как в PoE (v16)
## Раскладка поверх inventory (там — сколько всего): где что лежит и сколько в стопке/пучке.
const GRID_COLS: int = 16
const GRID_MAX_ROWS: int = 7
var layout: Array = []          # [{"id", "n", "x", "y"}]
var overflow: Dictionary = {}   # id -> сколько штук не влезло (героиня перегружена, пока не разберёт)
var hold: Dictionary = {}       # что сейчас «в курсоре» из сумки: {"id", "n"} — не раскладывать заново


func grid_rows() -> int:
	var pk: String = worn("pack")
	return mini(GRID_MAX_ROWS, (int(preload("res://items_db.gd").gear(pk).get("rows", 3)) if pk != "" else 3) + 2)   # v17: клетки мельче — рядов больше


func _cells(skip: int = -1) -> Array:
	var g: Array = []
	for y in range(GRID_MAX_ROWS):
		var row: Array = []
		row.resize(GRID_COLS)
		row.fill(-1)
		g.append(row)
	for i in range(layout.size()):
		if i == skip:
			continue
		var e: Dictionary = layout[i]
		var sz: Vector2i = esize(e)
		for yy in range(int(e["y"]), int(e["y"]) + sz.y):
			for xx in range(int(e["x"]), int(e["x"]) + sz.x):
				if yy < GRID_MAX_ROWS and xx < GRID_COLS:
					g[yy][xx] = i
	return g


## Размер вещи в сумке с учётом поворота (ключ "r" — повёрнута на 90°, как в Таркове)
func rsize(id: String, rot: bool) -> Vector2i:
	var s: Vector2i = preload("res://items_db.gd").size(id)
	return Vector2i(s.y, s.x) if rot else s


func esize(e: Dictionary) -> Vector2i:
	return rsize(String(e["id"]), bool(e.get("r", false)))


## Что лежит под клетками места (x, y) для вещи id: [] — свободно, иначе индексы
func covered(id: String, x: int, y: int, skip: int = -1, rot: bool = false) -> Array:
	var sz: Vector2i = rsize(id, rot)
	if x < 0 or y < 0 or x + sz.x > GRID_COLS or y + sz.y > grid_rows():
		return [-2]
	var g: Array = _cells(skip)
	var out: Array = []
	for yy in range(y, y + sz.y):
		for xx in range(x, x + sz.x):
			var v: int = int(g[yy][xx])
			if v >= 0 and not out.has(v):
				out.append(v)
	return out


## v26: «Сортировать» в сумке — слить стопки и разложить по порядку: большие вещи первыми, дальше по названию
func sort_layout() -> void:
	var IT = preload("res://items_db.gd")
	layout_sync()
	var all: Dictionary = {}
	for e in layout:
		all[String(e["id"])] = int(all.get(String(e["id"]), 0)) + int(e["n"])
	layout.clear()
	var ids: Array = all.keys()
	ids.sort_custom(func(a: Variant, b: Variant) -> bool:
		var sa: Vector2i = IT.size(String(a))
		var sb: Vector2i = IT.size(String(b))
		if sa.x * sa.y != sb.x * sb.y:
			return sa.x * sa.y > sb.x * sb.y
		return IT.name(String(a)) < IT.name(String(b)))
	for id in ids:
		var left: int = int(all[id])
		var st: int = maxi(1, IT.stack(String(id)))
		while left > 0:
			var sp: Vector2i = _free_spot(String(id))
			if sp.x < 0:
				overflow[String(id)] = int(overflow.get(String(id), 0)) + left
				break
			var put: int = mini(left, st)
			layout.append({"id": String(id), "n": put, "x": sp.x, "y": sp.y})
			left -= put
	inventory_changed.emit()


func _free_spot(id: String) -> Vector2i:
	for x in range(GRID_COLS):
		for y in range(grid_rows()):
			if covered(id, x, y).is_empty():
				return Vector2i(x, y)
	return Vector2i(-1, -1)


## Свести раскладку с количеством в сумке: новое — на свободное место (или в пучок), лишнее — убрать
func layout_sync() -> void:
	var IT = preload("res://items_db.gd")
	var have: Dictionary = {}
	for i in range(layout.size() - 1, -1, -1):
		var e: Dictionary = layout[i]
		var id: String = String(e["id"])
		# ряд закрылся (сняла рюкзак) — вещь за краем уходит в «не влезло»
		var sz: Vector2i = esize(e)
		if int(e["y"]) + sz.y > grid_rows():
			overflow[id] = int(overflow.get(id, 0)) + int(e["n"])
			layout.remove_at(i)
			continue
		have[id] = int(have.get(id, 0)) + int(e["n"])
	for id in overflow.keys():
		have[id] = int(have.get(id, 0)) + int(overflow[id])
	if not hold.is_empty():
		have[String(hold["id"])] = int(have.get(String(hold["id"]), 0)) + int(hold["n"])
	var ids: Dictionary = have.duplicate()
	for id in inventory.keys():
		ids[id] = true
	for id0 in ids.keys():
		var id: String = String(id0)
		var want: int = maxi(0, int(inventory.get(id, 0)))
		var diff: int = want - int(have.get(id, 0))
		# убрать лишнее: сперва из «не влезло», потом из самых маленьких стопок
		while diff < 0:
			if int(overflow.get(id, 0)) > 0:
				overflow[id] = int(overflow[id]) - 1
				if int(overflow[id]) <= 0:
					overflow.erase(id)
				diff += 1
				continue
			var best: int = -1
			for i in range(layout.size()):
				if String(layout[i]["id"]) == id and (best < 0 or int(layout[i]["n"]) < int(layout[best]["n"])):
					best = i
			if best < 0:
				break
			layout[best]["n"] = int(layout[best]["n"]) - 1
			if int(layout[best]["n"]) <= 0:
				layout.remove_at(best)
			diff += 1
		# разложить новое
		var st: int = IT.stack(id)
		var herb: bool = DB.DATA.has(id)
		var fresh: Dictionary = {}      # собранное за один раз ложится одним пучком
		while diff > 0:
			var placed: bool = false
			if herb and not fresh.is_empty() and int(fresh["n"]) < st:
				fresh["n"] = int(fresh["n"]) + 1
				diff -= 1
				continue
			# грибы, бутылочки — сразу в неполную стопку; цветы — в пучок, только если места нет
			if not herb:
				for e2 in layout:
					if String(e2["id"]) == id and int(e2["n"]) < st:
						e2["n"] = int(e2["n"]) + 1
						placed = true
						break
			if not placed:
				var sp: Vector2i = _free_spot(id)
				if sp.x >= 0:
					fresh = {"id": id, "n": 1, "x": sp.x, "y": sp.y}
					layout.append(fresh)
					placed = true
			if not placed and herb:
				for e3 in layout:
					if String(e3["id"]) == id and int(e3["n"]) < st:
						e3["n"] = int(e3["n"]) + 1
						placed = true
						break
			if not placed:
				overflow[id] = int(overflow.get(id, 0)) + 1
			diff -= 1
	# из «не влезло» — на освободившиеся места
	for id4 in overflow.keys():
		while int(overflow.get(id4, 0)) > 0:
			var sp2: Vector2i = _free_spot(String(id4))
			if sp2.x < 0:
				break
			layout.append({"id": String(id4), "n": 1, "x": sp2.x, "y": sp2.y})
			overflow[id4] = int(overflow[id4]) - 1
		if int(overflow.get(id4, 0)) <= 0:
			overflow.erase(id4)


## Положить взятую из сумки стопку (id, n) в клетку (x, y). Возвращает, что осталось в руке:
## {} — положила; {"id", "n"} — то, что было под ней (обмен) или остаток пучка.
func layout_place(id: String, n: int, x: int, y: int, rot: bool = false) -> Dictionary:
	var IT = preload("res://items_db.gd")
	var cov: Array = covered(id, x, y, -1, rot)
	if cov.has(-2):
		return {"id": id, "n": n, "r": rot}
	if cov.is_empty():
		layout.append({"id": id, "n": n, "x": x, "y": y, "r": rot})
		return {}
	if cov.size() == 1:
		var e: Dictionary = layout[int(cov[0])]
		if String(e["id"]) == id and IT.stack(id) > 1:
			# в пучок
			var room: int = IT.stack(id) - int(e["n"])
			var put: int = mini(room, n)
			e["n"] = int(e["n"]) + put
			return {} if put >= n else {"id": id, "n": n - put, "r": rot}
		# обмен: старое — в руку
		var old: Dictionary = {"id": String(e["id"]), "n": int(e["n"]), "r": bool(e.get("r", false))}
		layout.remove_at(int(cov[0]))
		layout.append({"id": id, "n": n, "x": x, "y": y, "r": rot})
		return old
	return {"id": id, "n": n, "r": rot}


func overloaded() -> bool:
	if not overflow.is_empty() and not god_mode:
		return true
	return not god_mode and carried() > capacity()


## Сколько можно нести без перегруза: своя сила + рюкзак, пояс, плащ
func capacity() -> float:
	return preload("res://items_db.gd").CAPACITY + stat("cap")


## Что сейчас в руках ("" — пусто)
func held() -> String:
	var id: String = String(hotbar[hot_sel])
	if id == "" or get_count(id) <= 0:
		return ""
	return id


# ================================================================== v23: дом, навыки, бой, работники, королевство, ферма
var furniture: Array = []               # мебель в доме: [id, x, y, flip] (координаты от IN_ORG)
var rooms: Array = [0]                  # комнаты дома: номера слотов (0 — главная, -1 слева, 1 справа...)
var house_init: bool = false            # обстановка дома уже расставлена (для старых сохранений)
var chest_layout: Array = []            # сундук как в PoE: [{"id", "n", "x", "y"}]
var chests: Dictionary = {}             # v24: сундуки по местам "x,y" -> {"kind", "layout", "filter"}
var felled: Array = []                  # v24: поваленные деревья/стволы на земле: {"tex", "fam", "x", "y", "dir", "state", "hits"}
var piles: Array = []                   # v24: штабели стволов: {"x", "y", "n", "fam"}
var kingdom_houses: Dictionary = {}     # v24: дома королевства "x,y" -> кто живёт (индексы работниц)
var keybinds: Dictionary = {}           # v24: свои горячие клавиши (действие -> physical keycode)
var monster_marks: Dictionary = {}      # v24: что монстры сделали с героиней (проклятия, кражи)
var carry_speed: float = 1.0            # v24: несёт ствол — идёт медленнее (не сохраняется)
var realm: String = ""                  # v24: "" — обычный мир, "hell" / "heaven" — другой мир за порталом
var ground: Array = []                  # выброшенные вещи на земле: [id, n, x, y]
var skills: Dictionary = {}             # навык -> опыт
var perm: Dictionary = {}               # навсегда выученные прибавки из магических книг: свойство -> число
var spells: Dictionary = {}             # выученные заклинания
var books_read: Dictionary = {}         # прочитанные книги -> сколько раз
## v24: проделки монстров (секунды, не сохраняются): липкая слизь, сонные споры, путаница
var mon_sticky: float = 0.0
var mon_sleep: float = 0.0
var mon_confuse: float = 0.0
var mon_stash: Dictionary = {}          # v24: что монстры утащили (id -> кол-во); найдётся в сундуке подземелья
var hp: float = 100.0                   # здоровье (только в подземельях и стычках; без крови — просто устала)
var shops: Dictionary = {}              # v26: магазины королевства "x,y" -> {"kind", "goods", "cash", "sold", "fame"}
var workers: Array = []              # работники: {"tex", "name", "land", "order", "since", "happy"}
var kingdom: Dictionary = {}            # своё королевство: {"name", "day", "level"}; пусто — его нет
var kingdom_refused: bool = false       # отказалась строить королевство
var kingdom_asked: int = 0              # в какой день спросили последний раз
var farm: Array = []                    # звери в загонах: {"kind", "x", "y", "born", "baby", "fed"}
var farm_last: int = 0                  # за какой день собраны продукты
var dungeons: Dictionary = {}           # подземелья: ключ -> {"chests": {i: true}, "boss": bool}
var animals_seen: Dictionary = {}       # звери, которых видела (страница книги)
var fish_talked: Dictionary = {}        # говорящие рыбы -> день последней встречи
var hell_key: String = ""              # в какой пещере портал в ад (выбирается случайно при первых заходах)
var hell_pos: Vector2 = Vector2.ZERO

const SKILLS: Dictionary = {
	"herb": ["Травничество", "herb", 3.0], "shroom": ["Грибничество", "shroom", 3.0], "mine": ["Шахтёрство", "cap", 1.0],
	"chop": ["Лесорубство", "cap", 1.0], "fish": ["Рыбалка", "fish", 4.0], "tame": ["Приручение", "tame", 6.0],
	"brew": ["Зельеварение", "brew", 2.0], "cook": ["Кулинария", "hunger", -2.0], "craft": ["Ремесло", "craft", 4.0],
	"combat": ["Добрая драка", "atk", 5.0], "trade": ["Торговля", "sell", 2.0], "lead": ["Лидерство", "lead", 5.0],
}
const SKILL_ORDER: Array = ["herb", "shroom", "mine", "chop", "fish", "tame", "brew", "cook", "craft", "combat", "trade", "lead"]
const SKILL_MAX: int = 10
signal skill_up(key: String, level: int)


func skill_level(key: String) -> int:
	return mini(SKILL_MAX, int(floor(sqrt(float(skills.get(key, 0.0)) / 25.0))))


## Сколько опыта нужно до уровня lv
static func skill_need(lv: int) -> float:
	return 25.0 * float(lv * lv)


func skill_xp(key: String, xp: float) -> void:
	if not SKILLS.has(key) or xp <= 0.0:
		return
	var before: int = skill_level(key)
	skills[key] = float(skills.get(key, 0.0)) + xp
	var after: int = skill_level(key)
	if after > before:
		skill_up.emit(key, after)
		toast.emit("%s: уровень %d!" % [String(SKILLS[key][0]), after], load("res://art/fx_heart.png"))


## Прибавка свойства от навыков (herb, shroom, cap, fish, tame, brew, hunger, craft, atk, sell, lead)
func skill_bonus(stat_key: String) -> float:
	var out: float = 0.0
	for k in SKILLS.keys():
		var sk: Array = SKILLS[k]
		if String(sk[1]) == stat_key:
			out += float(sk[2]) * float(skill_level(String(k)))
	if stat_key == "hp":
		out += 10.0 * float(skill_level("combat"))
	return out


func hp_max() -> float:
	return 100.0 + stat("hp")


func _skill_from_item(id: String, n: int) -> void:
	if god_mode:
		return
	var k: float = float(n)
	if preload("res://herbs_db.gd").DATA.has(id):
		skill_xp("herb", 3.0 * k)
	elif preload("res://wild_db.gd").is_shroom(id):
		skill_xp("shroom", 4.0 * k)
	elif FDB.is_fish(id):
		skill_xp("fish", 6.0 * k)
	elif id.begins_with("stone_") or id.begins_with("ore_") or id.begins_with("nugget_") or id.begins_with("gem_raw"):
		skill_xp("mine", 4.0 * k)
	elif id == "log" or id.begins_with("wood_") or id.begins_with("bark_"):
		skill_xp("chop", 3.0 * k)
	elif RDB.is_product(id):
		skill_xp("brew", 5.0 * k)
	elif id.begins_with("food_") and cooked.has(id.substr(5)):
		skill_xp("cook", 2.0 * k)


## Статус героини: одинокая варщица / хозяйка артели / королева
func status_text() -> String:
	if not kingdom.is_empty():
		return "Королева «%s»" % String(kingdom.get("name", ""))
	if workers.size() >= 3:
		return "Хозяйка артели · %d работников" % workers.size()
	if kingdom_refused:
		return "Одинокая варщица (по своей воле)"
	return "Одинокая варщица"


## Удочка: сделана на верстаке (предмет rod) или есть со старых времён
func rod_ok() -> bool:
	return has_rod or get_count("rod") > 0 or worn("main1") == "rod" or worn("main2") == "rod"


# ------------------------------------------------------------------ v25: сферы, скакуны, облик зверя, переезд, Эквестрия
var mana: float = 100.0                     # сила для заклинаний (книга сфер)
var orbs_open: Array = ["water", "life", "earth", "fire"]   # открытые стихии (остальные — на алтарях и у пони)
var spells_known: Dictionary = {}           # найденные заклинания: ключ сочетания -> день
var trust: Dictionary = {}                  # доверие зверей к героине: вид -> очки (приручение скакуна)
var mounts: Array = []                      # прирученные скакуны (виды)
var mount_kind: String = ""                 # скакун, который ходит рядом / под седлом
var riding: bool = false                    # сидит верхом
var forms_known: Array = ["rabbit", "fox", "deer"]   # в кого умеет превращаться
var form_pick: String = ""                  # облик, выбранный в гримуаре
var shape_form: String = ""                 # сейчас в облике зверя
var shape_t: float = 0.0                    # сколько ещё (секунды)
var moved_times: int = 0                    # сколько раз переезжала
var ponies_met: Dictionary = {}             # подружилась с пони: лист -> день
var spell_shield: float = 0.0               # защитный купол (секунды)
var spell_speed: float = 0.0                # бодрость (секунды)
var spell_regen: float = 0.0                # оберег (секунды)
var spell_light: float = 0.0                # тёплый свет (секунды)

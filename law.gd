extends Node
## Закон и тюрьма (v18). В каждом городе своя тюрьма: свой вид, срок, штраф, залог и тюремщица.
## Проступки копят «жар» (heat) в земле; набралось LIMIT — стража арестовывает: героиня в камере,
## отсидеть срок (время пролетает), заплатить залог или попросить о снисхождении (если земля уважает).
## Арт: tools/aseprite/gen_prison.lua (prison_<земля>, pr18_cell_<земля>). Тюремная комната — та же гостевая (ROOM_ORG).

const WD = preload("res://world_data.gd")
const NPC = preload("res://npc_db.gd")
const TW = preload("res://towns.gd")

const LIMIT: int = 3

## Тюрьмы по землям: название, срок (часов), штраф, множитель залога, оттенок пола, реплики
const PRISONS: Dictionary = {
	"cats": {"name": "Кошачья клетка", "hours": 4, "fine": 4, "bail_k": 0.8, "tint": Color(1.0, 0.88, 0.92), "jailer": "Тюремщица Пушинка",
		"arrest": "Мяу-мяу! Так нельзя! Пойдём в клетку, посидишь и подумаешь.",
		"intro": "Садись на подушку. Тут тепло, только скучно. Клубочек вон там, если хочешь.",
		"release": "Ну всё, иди. И больше не шали, ладно? Мур."},
	"knights": {"name": "Темница Кронхольма", "hours": 10, "fine": 12, "bail_k": 1.3, "tint": Color(0.62, 0.66, 0.78), "jailer": "Сержант Брана",
		"arrest": "Именем королевы Кронхольма — ты арестована! Следуй за мной.",
		"intro": "Порядок такой: срок отбывается полностью. Или залог. Закон один для всех.",
		"release": "Свободна. Запомни: рыцари ничего не забывают."},
	"gothic": {"name": "Подземелье Сумеречья", "hours": 12, "fine": 10, "bail_k": 1.5, "tint": Color(0.5, 0.44, 0.62), "jailer": "Смотрительница Морвен",
		"arrest": "Ах, какая неосторожность... Графиня не любит нарушителей. В подземелье!",
		"intro": "Здесь тихо. Крысы не кусаются. Почти. Цепи — для красоты.",
		"release": "Можешь идти. Подземелье всегда помнит гостей."},
	"spider": {"name": "Кокон-камера", "hours": 8, "fine": 6, "bail_k": 1.0, "tint": Color(0.7, 0.68, 0.84), "jailer": "Тихая Тара",
		"arrest": "Тш-ш. Паутина всё чувствует. Пойдём в кокон — полежишь, подумаешь.",
		"intro": "Не дёргайся: паутинка липкая, но добрая. Она сама отпустит, когда срок выйдет.",
		"release": "Нить разошлась. Иди. Только не наступай больше на чужие нити."},
	"elves": {"name": "Корневая клеть", "hours": 6, "fine": 8, "bail_k": 1.1, "tint": Color(0.68, 0.86, 0.66), "jailer": "Страж Ирис",
		"arrest": "Лес видел, что ты сделала. Прости, но придётся посидеть в клети.",
		"intro": "Корни не ранят — просто не отпускают. Дыши глубоко, слушай листья.",
		"release": "Корни разошлись. Иди с миром и береги лес."},
	"mages": {"name": "Хрустальная камера", "hours": 8, "fine": 14, "bail_k": 1.4, "tint": Color(0.66, 0.62, 1.0), "jailer": "Надзирательница Сольвейг",
		"arrest": "Нарушение зафиксировано в Книге Долины. Камера, будь добра.",
		"intro": "Прутья — чистая энергия. Не трогай, щиплются. Срок идёт по часам.",
		"release": "Заклятие снято. Следующий раз будет дороже."},
	"orcs": {"name": "Костяная яма", "hours": 10, "fine": 8, "bail_k": 0.9, "tint": Color(0.8, 0.66, 0.52), "jailer": "Тюремщица Груша",
		"arrest": "Гррр! Вождь сказал: нарушила — в яму! Шагай, травница!",
		"intro": "Сиди тихо. Кости не кусаются. Еду приносят, когда не забывают.",
		"release": "Всё. Сроку конец. Не серди вождя, ясно? Гр."},
	"goblins": {"name": "Клетка Хламбурга", "hours": 5, "fine": 5, "bail_k": 0.6, "tint": Color(0.82, 0.76, 0.6), "jailer": "Сторожиха Шестерёнка",
		"arrest": "Хи-хи! Попалась! Босс Зигги просила посадить в клетку из кроватей!",
		"intro": "Не скучай: тут железки, можно покрутить. Залог у нас дешёвый — торгуемся!",
		"release": "Выходи! Только в мои шестерёнки не лазь, ага?"},
	"dwarves": {"name": "Каменный штрек", "hours": 9, "fine": 10, "bail_k": 1.2, "tint": Color(0.66, 0.6, 0.55), "jailer": "Надзирательница Грета",
		"arrest": "Закон гор суров, но справедлив. Идём в штрек, нарушительница.",
		"intro": "Камень холодный, зато крепкий. Срок отсидишь — выйдешь с чистой совестью.",
		"release": "Срок отбыт. Дворфы долги помнят — и добро тоже."},
	"japan": {"name": "Бамбуковая клеть", "hours": 7, "fine": 7, "bail_k": 1.0, "tint": Color(0.95, 0.88, 0.78), "jailer": "Наставница Хару",
		"arrest": "Прошу прощения, но в Сакурояме так нельзя. Пройдёмте в бамбуковую клеть.",
		"intro": "Выпей чаю, подумай о проступке. Время в клети течёт спокойно.",
		"release": "Вы свободны. Пусть сакура напомнит вам о добре."},
}

var main: Node2D
var heat: Dictionary = {}        # земля -> сколько накопила проступков
var jailed: bool = false
var jail_land: String = ""
var sentence_h: float = 0.0
var fine_taken: int = 0
var arrests: int = 0
var pleaded: bool = false


func setup(m: Node2D) -> void:
	main = m
	add_to_group("law18")
	Game.day_changed.connect(_decay)


func prison(land: String) -> Dictionary:
	return PRISONS.get(land, PRISONS["knights"])


func _hud() -> Node:
	return get_tree().get_first_node_in_group("hud")


func _decay() -> void:
	for k in heat.keys():
		heat[k] = maxi(0, int(heat[k]) - 1)


## В каком городе стоит точка (или "")
func land_at(p: Vector2, extra: float = 200.0) -> String:
	for land in WD.TOWN_C.keys():
		if p.distance_to(WD.TOWN_C[land]) < WD.TOWN_R + extra:
			return String(land)
	return ""


## Проступок в земле: копится «жар»; набрала LIMIT — арест
func report(land: String, kind: String, pts: int = 1) -> void:
	if land == "" or jailed or not PRISONS.has(land):
		return
	heat[land] = int(heat.get(land, 0)) + pts
	Game.rep_add(land, -2 * pts)
	if int(heat[land]) >= LIMIT:
		arrest(land, kind)
	else:
		Game.toast.emit("Стража запомнила тебя. Лучше не повторять.", load("res://art/icon_scroll.png"))
		get_tree().call_group("player", "react", "shy", 1.6)


## Тюрьма города: дверь здания; если здания нет — временная дверь у центра города
func door_for(land: String) -> Node2D:
	for d in get_tree().get_nodes_in_group("house_doors"):
		if String(d.get("kind")) == "prison" and String(d.get("land")) == land and is_instance_valid(d):
			return d as Node2D
	var door: Node2D = Node2D.new()
	door.set_script(load("res://house_door.gd"))
	door.set("kind", "prison")
	door.set("land", land)
	door.set("private", false)
	door.set("owner_tex", String(TW.TOWNS.get(land, {}).get("guard", "knight_sera")))
	door.set("owner_name", String(prison(land)["jailer"]))
	door.set("open_from", 0.0)
	door.set("open_to", 25.0)
	door.set("seed_k", hash(land) % 9973)
	door.position = (WD.TOWN_C.get(land, Vector2.ZERO) as Vector2) + Vector2(430, 330)
	(main.get("objects") as Node).add_child(door)
	return door


func arrest(land: String, reason: String) -> void:
	if jailed:
		return
	jailed = true
	jail_land = land
	arrests += 1
	pleaded = false
	var P: Dictionary = prison(land)
	var n: int = maxi(LIMIT, int(heat.get(land, LIMIT)))
	sentence_h = clampf(float(P["hours"]) + 2.0 * float(n - LIMIT), 2.0, 14.0)
	fine_taken = mini(Game.coins, int(P["fine"]) + 4 * n)
	Game.coins -= fine_taken
	Game.inventory_changed.emit()
	heat[land] = 0
	var hud: Node = _hud()
	if hud != null:
		hud.call("say", "Стража", String(P["arrest"]))
	Sound.play("guard", -2.0)
	while Game.busy:
		await get_tree().process_frame
	await get_tree().create_timer(1.3).timeout
	if not jailed:
		return
	var door: Node2D = door_for(land)
	await main.call("visit_house", door)
	if hud != null:
		hud.call("say", String(P["jailer"]), "%s Срок — %d ч. Штраф: %d монет." % [String(P["intro"]), int(ceil(sentence_h)), fine_taken])


## Залог за выход сейчас
func bail_cost() -> int:
	var P: Dictionary = prison(jail_land)
	var base: float = sentence_h * 5.0 + float(P["fine"])
	return maxi(8, int(base * float(P["bail_k"]) * (1.0 - 0.05 * float(Game.rep_tier(jail_land)))))


func pay_bail() -> bool:
	if not jailed:
		return false
	var c: int = bail_cost()
	if Game.coins < c:
		return false
	Game.coins -= c
	Game.inventory_changed.emit()
	Sound.play("coin", -4.0)
	release(true)
	return true


## Уговорить: шанс зависит от уважения земли. Один раз за арест.
func plead() -> bool:
	if not jailed or pleaded:
		return false
	pleaded = true
	var tier: int = Game.rep_tier(jail_land)
	var chance: float = [0.0, 0.05, 0.2, 0.45, 0.7, 0.95][clampi(tier, 0, 5)]
	if randf() < chance:
		release(false)
		return true
	sentence_h += 1.0
	return false


## Отсидеть срок: время летит, голод и жажда растут
func serve() -> void:
	if not jailed or Game.busy:
		return
	Game.busy = true
	var hud: Node = _hud()
	var tw: Tween = hud.call("fade_out", "Время идёт...")
	await tw.finished
	advance_hours(sentence_h)
	sentence_h = 0.0
	await get_tree().create_timer(0.6).timeout
	var tw2: Tween = hud.call("fade_in")
	await tw2.finished
	Game.busy = false
	release(false)


func advance_hours(h: float) -> void:
	var total: float = Game.minutes + h * 60.0
	Game.hunger = minf(1.0, Game.hunger + h * 60.0 * Game.HUNGER_PER_MIN * 0.6)
	Game.thirst = minf(1.0, Game.thirst + h * 60.0 * Game.THIRST_PER_MIN * 0.6)
	if total >= 1440.0:
		Game.next_day()
		Game.minutes = fmod(total, 1440.0)
		main.call("_spawn_herbs")
	else:
		Game.minutes = total


func release(paid: bool) -> void:
	if not jailed:
		return
	var land: String = jail_land
	jailed = false
	sentence_h = 0.0
	var P: Dictionary = prison(land)
	await main.call("leave_house")
	var hud: Node = _hud()
	if hud != null:
		hud.call("say", String(P["jailer"]), String(P["release"]))
	Game.toast.emit("Ты на свободе", load("res://art/icon_scroll.png"))


func on_teleport() -> void:
	jailed = false
	sentence_h = 0.0

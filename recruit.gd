extends Node
## Вербовка жителей v17. Каждая жительница ставит свои условия:
##   free  — пойдёт бесплатно, если с её землёй вы в хороших отношениях (репутация);
##   money — за плату при найме и жалованье каждый день (не хватит денег — обидится и уйдёт);
##   food  — пойдёт, если кормить: раз в день ей нужно любимое блюдо (иначе голодает и уходит).
## Спутницы идут следом, помогают (бонусы к сбору, весу, скорости...) и могут уйти сами.
## Лидеры, стража, заместители и торговки на посту — не идут.

const FD = preload("res://food_db.gd")
const NPC = preload("res://npc_db.gd")

const LIKES: Array = ["sweet", "meat", "fish", "fruit", "veg", "bread", "berry", "soup", "dairy", "mushroom", "drink", "nut"]
const LIKE_NAME: Dictionary = {
	"sweet": "сладкое", "meat": "мясное", "fish": "рыбное", "fruit": "фрукты", "veg": "овощи", "bread": "выпечку",
	"berry": "ягоды", "soup": "супы", "dairy": "молочное", "mushroom": "грибное", "drink": "напитки", "nut": "орехи",
}
# [стат, величина, как написано]
const PERKS: Array = [
	["cap", 5, "Носит часть вещей: +5 к весу"],
	["herb", 10, "Острый глаз на травы: +10% к двойному сбору"],
	["shroom", 12, "Знает грибные места: +12% к двойному грибу"],
	["speed", 4, "Подбадривает в пути: +4% к скорости"],
	["sell", 6, "Торгуется за тебя: +6% к цене продажи"],
	["brew", 7, "Помогает у котла: +7% шанс двух зелий"],
	["seed", 14, "Находит семена: +14% к семечкам"],
	["light", 1, "Носит фонарик: ночью светлее"],
]
const NO_ROLES: Array = ["лидер", "стража", "заместитель", "торговец"]


## Условия найма этой жительницы: {can, type, tier, fee, wage, likes, perk (стат -> число), perk_text}
static func profile(tex: String, role: String, land: String) -> Dictionary:
	var h: int = abs(hash(tex))
	var can: bool = not NO_ROLES.has(role)
	var kinds: Array = ["free", "free", "free", "free", "money", "money", "money", "food", "food", "food"]
	var tp: String = String(kinds[h % 10])
	var pk: Array = PERKS[(h / 13) % PERKS.size()]
	var tier_need: int = [2, 3, 3, 4][(h / 10) % 4]
	if land == "":
		tier_need = 0
	if tp == "money":
		tier_need = mini(tier_need, 2)
	if tp == "food":
		tier_need = mini(tier_need, 2)
	var likes: String = String(LIKES[(h / 7) % LIKES.size()])
	return {
		"can": can, "type": tp, "tier": tier_need,
		"fee": 30 + ((h / 100) % 9) * 20, "wage": 3 + (h / 1000) % 10,
		"likes": likes, "perk": {String(pk[0]): float(pk[1])}, "perk_text": String(pk[2]),
	}


static func tier_name(t: int) -> String:
	return String(Game.REP_TIERS[clampi(t, 0, Game.REP_TIERS.size() - 1)][1])


## Что она говорит об условиях
static func terms_text(pf: Dictionary, land: String) -> String:
	match String(pf["type"]):
		"free":
			if land == "" or int(pf["tier"]) <= 0:
				return "Я пойду с тобой просто так, мне всё равно скучно. Только не обижай меня."
			return "Я пойду с тобой бесплатно — но только если с нашей землёй вы друзья. Хотя бы «%s»." % tier_name(int(pf["tier"]))
		"money":
			return "Я пойду с тобой за %d монет сразу и по %d монет в день. Не будет денег — уйду." % [int(pf["fee"]), int(pf["wage"])]
		"food":
			return "Я пойду, если будешь меня кормить. Каждый день мне нужно что-нибудь вкусное, особенно — %s. Голодать не буду: уйду." % String(LIKE_NAME.get(String(pf["likes"]), "вкусное"))
	return ""


## Спутница по имени листа
func find(tex: String) -> int:
	for i in range(Game.team.size()):
		if String((Game.team[i] as Dictionary)["tex"]) == tex:
			return i
	return -1


func is_follower(tex: String) -> bool:
	return find(tex) >= 0


## Взять в команду (условия уже выполнены)
func join(npc: Node2D, pf: Dictionary) -> bool:
	if Game.team.size() >= Game.TEAM_MAX:
		return false
	var tex: String = String(npc.get("tex_name"))
	if find(tex) >= 0:
		return false
	var m: Dictionary = {
		"tex": tex, "name": String(npc.get("npc_name")), "land": String(npc.get("land")), "req": String(pf["type"]),
		"fee": int(pf["fee"]), "wage": int(pf["wage"]), "likes": String(pf["likes"]), "perk": (pf["perk"] as Dictionary).duplicate(),
		"perk_text": String(pf["perk_text"]), "loyalty": 0.8, "id": npc.get_instance_id(), "since": Game.day,
	}
	Game.team.append(m)
	# с этого мига она ходит за героиней, а не за своим домом
	var main: Node = get_tree().current_scene
	var objs: Node = main.get("objects") if main != null else null
	if objs != null and npc.get_parent() != objs:
		npc.reparent(objs, true)
	npc.set("follower", true)
	npc.set("follow_slot", Game.team.size() - 1)
	npc.set("going_home", false)
	npc.set("sleeping", false)
	npc.set("route", [])
	npc.set("walking", false)
	if (npc.get("spr") as Sprite2D) != null:
		(npc.get("spr") as Sprite2D).visible = true
	Game.team_changed.emit()
	Game.inventory_changed.emit()
	return true


func node_of(m: Dictionary) -> Node2D:
	var n: Object = instance_from_id(int(m["id"]))
	return n as Node2D if n != null and is_instance_valid(n) else null


## Спутница уходит (сама или её отпустили): возвращается к своему дому
func leave(i: int, reason: String) -> void:
	if i < 0 or i >= Game.team.size():
		return
	var m: Dictionary = Game.team[i]
	Game.team.remove_at(i)
	var n: Node2D = node_of(m)
	if n != null:
		n.set("follower", false)
		n.set("route", [n.get("home")])
		n.set("walking", true)
		n.call("react", "sad" if reason != "" else "smile", 2.5)
	for j in range(Game.team.size()):
		var nn: Node2D = node_of(Game.team[j])
		if nn != null:
			nn.set("follow_slot", j)
	if reason != "":
		Game.toast.emit("%s ушла: %s" % [String(m["name"]), reason], null)
	Game.team_changed.emit()
	Game.inventory_changed.emit()


## Любимое блюдо в сумке (id) или любое съедобное; "" если ничего нет
func food_for(m: Dictionary, only_liked: bool = false) -> String:
	var liked: Array = FD.of_kind(String(m["likes"]))
	for id in liked:
		if Game.get_count(String(id)) > 0:
			return String(id)
	if only_liked:
		return ""
	for k in FD.ORDER:
		var fid: String = "food_" + String(k)
		if Game.get_count(fid) > 0 and not FD.is_drink(fid) and FD.kind(fid) != "drink":
			return fid
	return ""


## Накормить прямо сейчас
func feed(i: int, fid: String) -> bool:
	if i < 0 or i >= Game.team.size() or Game.get_count(fid) <= 0:
		return false
	var m: Dictionary = Game.team[i]
	Game.take_item(fid)
	var liked: bool = FD.kind(fid) == String(m["likes"])
	m["loyalty"] = minf(1.0, float(m["loyalty"]) + (0.3 if liked else 0.12))
	var n: Node2D = node_of(m)
	if n != null:
		n.call("react", "happy", 2.0)
		Game.fx.emit(n.global_position + Vector2(0, -50), "heart")
	return true


# ------------------------------------------------------------------ каждое утро

func _ready() -> void:
	add_to_group("recruit")
	Game.day_changed.connect(on_new_day)


func on_new_day() -> void:
	for i in range(Game.team.size() - 1, -1, -1):
		if i >= Game.team.size():
			continue
		var m: Dictionary = Game.team[i]
		var lid: String = String(m["land"])
		match String(m["req"]):
			"money":
				if Game.coins >= int(m["wage"]):
					Game.coins -= int(m["wage"])
					m["loyalty"] = minf(1.0, float(m["loyalty"]) + 0.1)
					Game.toast.emit("%s: жалованье %d монет" % [String(m["name"]), int(m["wage"])], load("res://art/coin.png"))
					Game.inventory_changed.emit()
				else:
					m["loyalty"] = float(m["loyalty"]) - 0.4
					Game.toast.emit("%s: нечем платить жалованье!" % String(m["name"]), null)
			"food":
				var fid: String = food_for(m)
				if fid != "":
					var liked: bool = FD.kind(fid) == String(m["likes"])
					Game.take_item(fid)
					m["loyalty"] = minf(1.0, float(m["loyalty"]) + (0.15 if liked else 0.02))
					Game.toast.emit("%s поела: %s" % [String(m["name"]), FD.name(fid)], FD.icon(fid))
				else:
					m["loyalty"] = float(m["loyalty"]) - 0.4
					Game.toast.emit("%s голодает!" % String(m["name"]), null)
			_:
				m["loyalty"] = minf(1.0, float(m["loyalty"]) + 0.02)
		if lid != "" and Game.rep_tier(lid) <= 1:
			leave(i, "её земля тебя не любит")
		elif float(m["loyalty"]) <= 0.0:
			leave(i, {"money": "не получила денег", "food": "осталась голодной"}.get(String(m["req"]), "ей надоело"))

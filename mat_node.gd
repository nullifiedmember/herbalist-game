extends Node2D
## Место добычи материалов (v20): глина, песок, лён, хлопок, ракушки, улей, уголь... (mats_db.NODES)
## E — собрать (вылетает в руки), потом место «отрастает» через несколько дней.
## Уголь, сера, селитра, обсидиан и кристаллы — только киркой.

const MT = preload("res://mats_db.gd")
const NEED_PICK: Array = ["coal", "sulfur", "saltpeter", "obsidian", "crystals"]

var kind: String = ""
var key: String = ""
var spr: Sprite2D
var interact_offset: Vector2 = Vector2(0, -8)
var check_t: float = 0.0
var shown: bool = true


func setup(k: String, s: Sprite2D) -> void:
	kind = k
	spr = s
	key = "n20:%s:%d,%d" % [k, int(position.x), int(position.y)]
	add_to_group("matnodes20")
	check_t = randf()
	_refresh()


func ready_now() -> bool:
	var d: int = int(Game.picked.get(key, -100))
	return Game.day >= d + int((MT.NODES[kind] as Array)[4])


func _refresh() -> void:
	var r: bool = ready_now()
	if r != shown or (r and not is_in_group("interactables")) or (not r and is_in_group("interactables")):
		shown = r
		if spr != null and is_instance_valid(spr):
			spr.modulate.a = 1.0 if r else 0.0
		if r and not is_in_group("interactables"):
			add_to_group("interactables")
		elif not r and is_in_group("interactables"):
			remove_from_group("interactables")


func _process(delta: float) -> void:
	check_t -= delta
	if check_t <= 0.0:
		check_t = 2.0
		_refresh()


func get_prompt() -> String:
	var nm: String = String((MT.NODES[kind] as Array)[0])
	if kind in NEED_PICK and not Game.has_tool("pickaxe"):
		return nm + " (нужна кирка)"
	return "Собрать: " + nm.to_lower()


func interact() -> void:
	if not ready_now():
		return
	if kind in NEED_PICK and not Game.has_tool("pickaxe"):
		Game.toast.emit("Без кирки не взять", preload("res://items_db.gd").icon("pickaxe"))
		get_tree().call_group("player", "react", "pout", 0.8)
		return
	if Game.tired():
		get_tree().call_group("player", "react", "sad", 1.2)
		return
	var nd: Array = MT.NODES[kind]
	var hs: Node = get_tree().get_first_node_in_group("homestead")
	var n: int = 0
	var bonus: bool = Game.has_tool("sickle") or Game.has_tool("gold_sickle") or Game.has_tool("shovel")
	for g in nd[3]:
		if randf() > float(g[3]):
			continue
		var cnt: int = randi_range(int(g[1]), int(g[2])) + (1 if bonus and randf() < 0.4 else 0)
		var id: String = String(g[0])
		for i in range(cnt):
			var ang: float = TAU * float(n) / 7.0
			if hs != null:
				hs.call("_drop", id, String((MT.MATS[id] as Array)[3]) if MT.MATS.has(id) else "icon_pack", global_position + Vector2(cos(ang) * 14.0, sin(ang) * 6.0), 0.2 + float(n) * 0.06)
			else:
				Game.add_item(id)
			n += 1
	Sound.play(String(nd[5]), -6.0, 0.12, global_position)
	Game.fx.emit(global_position + Vector2(0, -6), "dust")
	get_tree().call_group("player", "react", "happy", 0.6)
	Game.picked[key] = Game.day
	Game.fatigue = minf(1.0, Game.fatigue + 0.004)
	_refresh()

import sys
sys.path.insert(0, "tools")
from edit29 import apply

apply("game_state.gd", [(
"""extends Node
## Глобальное состояние: сумка, семена, день и время суток.
""",
"""extends Node
## Глобальное состояние: сумка, семена, день и время суток.

const SOLO: bool = true   # v29: одиночная игра — своя зельеварня. Без королевства, вербовки, оружия, подземелий и врагов (вернуть: false)
""")])

apply("dungeon23.gd", [
("""	if world != null:
		(world.get("region_hooks") as Array).append(Callable(self, "_region_hook"))""",
"""	if world != null and not Game.SOLO:     # v29: в одиночной игре входов в подземелья нет
		(world.get("region_hooks") as Array).append(Callable(self, "_region_hook"))"""),
("""func _unhandled_input(event: InputEvent) -> void:
	if Game.ui_open or Game.busy:
		return
	var press: bool = false""",
"""func _unhandled_input(event: InputEvent) -> void:
	if Game.ui_open or Game.busy or Game.SOLO:
		return
	var press: bool = false"""),
])

apply("realm24.gd", [(
"""	for k in GATES.keys():
		var g: Node2D = Node2D.new()""",
"""	for k in ([] if Game.SOLO else GATES.keys()):     # v29: врат в Ад и Рай пока нет
		var g: Node2D = Node2D.new()""")])

apply("mages.gd", [(
"""	var m: Node2D = Node2D.new()
	m.set_script(load("res://mimic.gd"))
	node.add_child(m)
	m.call("setup", MIMIC)
	main.call("add_caster", m.get("spr") as Sprite2D, true)
	world.call("add_block", MIMIC + Vector2(0, -6), 14.0)""",
"""	if not Game.SOLO:     # v29: кусачий мимик — враг, пока убран
		var m: Node2D = Node2D.new()
		m.set_script(load("res://mimic.gd"))
		node.add_child(m)
		m.call("setup", MIMIC)
		main.call("add_caster", m.get("spr") as Sprite2D, true)
		world.call("add_block", MIMIC + Vector2(0, -6), 14.0)""")])

apply("kingdom23.gd", [
("""	if KB.is_key("kingdom", k):""", """	if KB.is_key("kingdom", k) and not Game.SOLO:"""),
("""func extra_options(d: Node, opts: Array) -> Array:
	var npc: Node = d.get("npc")
	if npc == null:""",
"""func extra_options(d: Node, opts: Array) -> Array:
	var npc: Node = d.get("npc")
	if npc == null or Game.SOLO:     # v29: нанимать работниц нельзя"""),
("""	if propose_t > 0.0:
		propose_t -= delta""", """	if propose_t > 0.0 and not Game.SOLO:
		propose_t -= delta"""),
])

apply("dialog_ui.gd", [(
"""	if rcn != null and bool(RECR.profile(""",
"""	if rcn != null and not Game.SOLO and bool(RECR.profile(""")])

apply("hud.gd", [(
"""		["skills", "icon_star_blade", "Навыки"],["kingdom", "icon_crown23", "Королевство"],
	]
""",
"""		["skills", "icon_star_blade", "Навыки"],
	]
	if not Game.SOLO:
		items.append(["kingdom", "icon_crown23", "Королевство"])
""")])

apply("v23.gd", [
("""	var out: Array = ["furn", "wpn"]
	if not Game.kingdom.is_empty() or Game.god_mode:""",
"""	var out: Array = ["furn", "wpn"]
	if not Game.SOLO and (not Game.kingdom.is_empty() or Game.god_mode):"""),
("""			out.append([IT.icon("rod"), hs.call("_need_costs", rn), "Удочка\\n" + String(hs.call("_need_text", rn)), "v23:rod", not bool(hs.call("_can_pay", rn))])
			for wid in V.WEAPON_ORDER:""",
"""			out.append([IT.icon("rod"), hs.call("_need_costs", rn), "Удочка\\n" + String(hs.call("_need_text", rn)), "v23:rod", not bool(hs.call("_can_pay", rn))])
			# v29: садовые инструменты для заднего дворика
			for tl in TOOLS29.keys():
				var tn: Dictionary = TOOLS29[tl]
				out.append([IT.icon(String(tl)), hs.call("_need_costs", tn), IT.name(String(tl)) + "\\n" + String(hs.call("_need_text", tn)), "v23:" + String(tl), not bool(hs.call("_can_pay", tn))])
			for wid in ([] if Game.SOLO else V.WEAPON_ORDER):     # v29: оружия в одиночной игре нет"""),
("""	if key == "rod":
		need = {"stick": 2, "twine": 1}
		item = "rod"
	elif key.begins_with("furn:"):""",
"""	if key == "rod":
		need = {"stick": 2, "twine": 1}
		item = "rod"
	elif TOOLS29.has(key):
		need = TOOLS29[key]
		item = key
	elif key.begins_with("furn:"):"""),
("""func bench_craft(key: String) -> bool:""",
"""const TOOLS29: Dictionary = {"hoe": {"stick": 2, "stone_s": 2}, "watering_can": {"stick": 1, "clay": 3}}


func bench_craft(key: String) -> bool:"""),
("""	for key in Game.SKILL_ORDER:
		var sk: Array = Game.SKILLS[key]""",
"""	for key in Game.SKILL_ORDER:
		if Game.SOLO and key in ["combat", "lead"]:
			continue     # v29: драки и работниц пока нет
		var sk: Array = Game.SKILLS[key]"""),
])

apply("homestead.gd", [(
"""				tbtn.tooltip_text = {"furn": "Мебель", "wpn": "Оружие и удочка",""",
"""				if Game.SOLO and String(tb) == "wpn":
					tic.texture = load("res://art/icon_hoe.png")
				tbtn.tooltip_text = {"furn": "Мебель", "wpn": "Садовые инструменты и удочка" if Game.SOLO else "Оружие и удочка",""")])

apply("paths.gd", [
("""	if role in ["кузнец", "стража", "заместитель"] and PDB.LAND_WEAPONS.has(land):""",
"""	if not Game.SOLO and role in ["кузнец", "стража", "заместитель"] and PDB.LAND_WEAPONS.has(land):"""),
("""	for w in PDB.LAND_WEAPONS.get(land, []):
		pool.append(String(w))""",
"""	for w in ([] if Game.SOLO else PDB.LAND_WEAPONS.get(land, [])):
		pool.append(String(w))"""),
])

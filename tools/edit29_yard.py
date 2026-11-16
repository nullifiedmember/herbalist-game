import sys
sys.path.insert(0, "tools")
from edit29 import apply

apply("game_state.gd", [(
"""var plot_level: int = 0               # сколько раз расширяла участок
""",
"""var plot_level: int = 0               # сколько раз расширяла участок
# v29: задний двор, лейка, погода
var yard29: Dictionary = {}           # грядки cells, грибные деревья trees, вода в бочке barrel (backyard29.gd)
var can_water: int = 0                # поливов в лейке
var seed_sel: String = ""             # какие семена сеять
var weather: String = "clear"         # clear / cloudy / rain / storm / fog (weather29.gd)
var weather_h: float = 5.0            # часов до смены погоды
var rain_today: float = 0.0           # сколько часов шёл дождь с прошлого утра
""")])

apply("items_db.gd", [(
"""	"shovel": {"name": "Лопата",""",
"""	"hoe": {"name": "Мотыга", "slot": "tool", "w": 1.5, "price": 20, "stats": {}, "desc": "Вскапывает грядки на заднем дворе. Можно вести мышью по грядкам — вскопает подряд."},
	"watering_can": {"name": "Лейка", "slot": "tool", "w": 1.2, "price": 18, "stats": {}, "desc": "Набери воды у колодца или в дождевой бочке. Хватает на 10 грядок."},
	"shovel": {"name": "Лопата",""")])

apply("plot.gd", [(
"""## Только для скриншотов и проверок.""",
"""## v29: дождь поливает грядку сам
func rain29() -> void:
	if crop != "" and not watered:
		watered = true
		refresh()


## Только для скриншотов и проверок.""")])

apply("homestead.gd", [(
"""				if k == "outhouse" and not Game.TOILET_ENABLED:""",
"""				if k == "plot" and Game.SOLO:
					continue   # v29: старый огород убран — грядки теперь на заднем дворе
				if k == "outhouse" and not Game.TOILET_ENABLED:""")])

apply("main.gd", [
# барьер на Родном лугу: весь двор проходим, деревья леса — преграды
("""	if not LAY.WALK_RECT.has_point(p) and not _in_exit(p):
		return true""",
"""	if classic_yard and not LAY.WALK_RECT.has_point(p) and not _in_exit(p):
		return true     # v29: в новой игре двор открыт со всех сторон (был невидимый барьер у дома)"""),
("""			if LAY.WALK_RECT.grow(20).has_point(p):
				block_circle(p + Vector2(0, -4), 7)""",
"""			if LAY.WALK_RECT.grow(20).has_point(p) or Rect2(0, 0, LAY.W, LAY.H).has_point(p):
				block_circle(p + Vector2(0, -4), 7)"""),
# задний двор: свои преграды
("""	if p.y > 120000.0 and mine != null:
		return bool(mine.call("is_blocked", p))""",
"""	if p.x > 80000.0 and p.x < 120000.0 and absf(p.y) < 5000.0:
		var by29: Node = get_node_or_null("Backyard29")
		return by29 == null or bool(by29.call("is_blocked", p))     # v29: задний двор
	if p.y > 120000.0 and mine != null:
		return bool(mine.call("is_blocked", p))"""),
# узлы двора и погоды — после магазинов (ввод мыши раньше хозяйства)
("""	var s26: Node = Node.new()
	s26.set_script(load("res://shops26.gd"))
	add_child(s26)
	s26.call("setup", self)""",
"""	var s26: Node = Node.new()
	s26.set_script(load("res://shops26.gd"))
	add_child(s26)
	s26.call("setup", self)
	# v29: задний двор с грядками и грибными деревьями, погода с дождём
	var by29: Node = Node.new()
	by29.set_script(load("res://backyard29.gd"))
	by29.name = "Backyard29"
	add_child(by29)
	by29.call("setup", self, hud)
	var wx29: Node2D = Node2D.new()
	wx29.set_script(load("res://weather29.gd"))
	wx29.name = "Weather29"
	add_child(wx29)
	wx29.call("setup", self, hud)"""),
("""	if live != null and bool(live.get("active")):
		return false
	if mine != null and bool(mine.get("inside")):
		return false
	if player.position.y < -150000.0:""",
"""	if live != null and bool(live.get("active")):
		return false
	if mine != null and bool(mine.get("inside")):
		return false
	var by29s: Node = get_node_or_null("Backyard29")
	if by29s != null and bool(by29s.get("active")):
		return false
	if player.position.y < -150000.0:"""),
("""	if live != null and bool(live.get("active")):
		live.call("set_active", false)""",
"""	if live != null and bool(live.get("active")):
		live.call("set_active", false)
	var by29l: Node = get_node_or_null("Backyard29")
	if by29l != null and bool(by29l.get("active")):
		by29l.set("active", false)"""),
])

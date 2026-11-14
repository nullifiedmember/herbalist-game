extends Node2D
## Постройка на участке, с которой можно поговорить: верстак, сундук, стол изучения, загон, межевой столб.

var kind: String = ""
var home: Node = null
var interact_offset: Vector2 = Vector2(0, -24)


func _ready() -> void:
	add_to_group("interactables")
	if kind == "stall":
		add_to_group("stall_ea")
	elif kind == "forge":
		add_to_group("forge_ea")


func get_prompt() -> String:
	var MT = preload("res://mats_db.gd")
	if has_meta("chest_kind"):
		return String((preload("res://storage_db.gd").KINDS.get(String(get_meta("chest_kind")), ["Сундук"]) as Array)[0])
	if kind == "shop26":
		return preload("res://shops26.gd").shop_name(String(get_meta("shop_kind", "")))
	if MT.STATIONS.has(kind):
		return String((MT.STATIONS[kind] as Array)[0])
	return {"workbench": "Верстак", "chest": "Сундук", "research": "Изучать травы", "pen": "Загон", "post": "Межевой столб", "stall": "Лавка", "forge": "Кузница"}.get(kind, "")


func interact() -> void:
	if home != null:
		home.call("open_menu", kind, self)

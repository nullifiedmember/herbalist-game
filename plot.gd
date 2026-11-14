extends Node2D
## Грядка: пусто -> посадить -> полить -> (за ночь растёт) -> собрать.

const DB = preload("res://herbs_db.gd")
const WIND = preload("res://wind.gdshader")
const RIPE: int = 3

var crop: String = ""
var stage: int = 0
var watered: bool = false
var pollinated: bool = false        # пчела или мотылёк опылили — урожай на одну траву больше
var aphids: int = 0                 # тля: пока она есть, грядка за ночь не растёт
var interact_offset: Vector2 = Vector2(0, -22)

var bed: Sprite2D
var plants: Array = []


func _ready() -> void:
	add_to_group("plots")
	add_to_group("interactables")
	bed = Sprite2D.new()
	bed.centered = false
	bed.offset = Vector2(-40, -56)
	add_child(bed)
	for i in range(3):
		var s: Sprite2D = Sprite2D.new()
		s.centered = false
		s.offset = Vector2(-16, -45)
		s.position = Vector2(-22 + i * 22, -12 - (i % 2) * 6)
		var m: ShaderMaterial = ShaderMaterial.new()
		m.shader = WIND
		m.set_shader_parameter("strength", 0.8)
		s.material = m
		add_child(s)
		plants.append(s)
	# средний рисуем позади
	move_child(plants[1], 1)
	refresh()


func refresh() -> void:
	bed.texture = load("res://art/bed_wet.png") if watered else load("res://art/bed_dry.png")
	for p in plants:
		var s: Sprite2D = p
		s.visible = crop != ""
		if crop != "":
			s.texture = load("res://art/%s_%d.png" % [crop, stage])


func get_prompt() -> String:
	if crop == "":
		var sid: String = Game.next_seed()
		if sid == "":
			return "Нет семян"
		return "Посадить: %s" % DB.short(sid)
	if stage >= RIPE:
		return "Собрать урожай"
	if not watered:
		return "Полить грядку"
	return "Растёт... до завтра"


func interact() -> void:
	var p: Vector2 = global_position + Vector2(0, -24)
	if crop == "":
		var seed_id: String = Game.take_seed()
		if seed_id == "":
			Game.toast.emit("Семена закончились", null)
			return
		crop = seed_id
		stage = 0
		watered = false
		Game.fx.emit(p, "dirt")
		Game.toast.emit("Посажено: %s" % DB.short(seed_id), DB.seed_icon(seed_id))
	elif stage >= RIPE:
		Game.add_item(crop, 3 + (1 if pollinated else 0))
		pollinated = false
		aphids = 0
		Game.fx.emit(p, "leaves")
		crop = ""
		stage = 0
		watered = false
	elif not watered:
		watered = true
		Game.fx.emit(p, "water")
	refresh()


func on_new_day() -> void:
	if crop != "" and watered and stage < RIPE and aphids <= 0:
		stage += 1
	watered = false
	refresh()


## Только для скриншотов и проверок.
func debug_set(new_crop: String, new_stage: int, new_watered: bool) -> void:
	crop = new_crop
	stage = new_stage
	watered = new_watered
	refresh()

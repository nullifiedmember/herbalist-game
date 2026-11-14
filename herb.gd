extends Node2D
## Дикая трава: подойти и нажать E.

const DB = preload("res://herbs_db.gd")
const WIND = preload("res://wind.gdshader")

var herb_id: String = "mint"
var interact_offset: Vector2 = Vector2(0, -14)
var sparkle: Sprite2D
var phase: float = 0.0


func _ready() -> void:
	add_to_group("interactables")
	add_to_group("wild_herbs")
	var s: Sprite2D = Sprite2D.new()
	var wp: String = "res://art/herbw_%s.png" % herb_id
	s.texture = load(wp) if ResourceLoader.exists(wp) else DB.icon(herb_id)   # v24: без кочки земли
	s.flip_h = randf() < 0.5
	s.centered = false
	s.offset = Vector2(-16, -45)
	var m: ShaderMaterial = ShaderMaterial.new()
	m.shader = WIND
	m.set_shader_parameter("strength", 1.0)
	s.material = m
	add_child(s)
	# искорка: эту траву можно собрать
	sparkle = Sprite2D.new()
	sparkle.texture = load("res://art/fx_firefly.png")
	var add: CanvasItemMaterial = CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	sparkle.material = add
	sparkle.position = Vector2(randf_range(-8, 8), randf_range(-36, -22))
	add_child(sparkle)
	phase = randf() * TAU


func _process(delta: float) -> void:
	phase += delta * 1.7
	var k: float = maxf(0.0, sin(phase))
	sparkle.modulate = Color(1, 1, 0.85, k * k)
	if k < 0.02:
		sparkle.position = Vector2(randf_range(-8, 8), randf_range(-36, -22))


func get_prompt() -> String:
	return "Собрать: %s" % DB.short(herb_id)


func interact() -> void:
	var hu: Node = get_tree().get_first_node_in_group("harvest_ui")
	if hu != null:
		hu.call("open", self, [herb_id])
		return
	collect_now()


## Окно сбора закрыто: собрала — трава исчезает; осталась в земле — растёт дальше
func harvest_done(got: Array, left: Array) -> void:
	if left.is_empty():
		remove_from_group("interactables")
		remove_from_group("wild_herbs")
		Game.fx.emit(global_position + Vector2(0, -16), "leaves")
		queue_free()


func collect_now() -> void:
	# сразу убираем из выбираемых, чтобы героиня не взяла удалённую траву целью
	remove_from_group("interactables")
	remove_from_group("wild_herbs")
	# серп, венок, перчатки: шанс срезать вдвое больше; совок и лопата: шанс выкопать семечко
	Game.add_item(herb_id, 2 if randf() * 100.0 < Game.stat("herb") else 1)
	if preload("res://herbs_db.gd").SEEDS.has(herb_id) and randf() * 100.0 < Game.stat("seed"):
		Game.seeds[herb_id] = int(Game.seeds.get(herb_id, 0)) + 1
		Game.toast.emit("+1 семечко", preload("res://herbs_db.gd").seed_icon(herb_id))
	Game.fx.emit(global_position + Vector2(0, -16), "leaves")
	queue_free()

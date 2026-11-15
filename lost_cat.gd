extends Node2D
## Потерявшаяся кошка (задание «найти кошку»): сидит где-то в лесу, мяукает. E — взять на руки.

var quest_id: int = 0
var skin: String = "ginger"
var cat_name: String = "Пуся"
var main: Node2D
var interact_offset: Vector2 = Vector2(0, -12)
var spr: Sprite2D
var t: float = 0.0
var meow_t: float = 4.0
var snapped: bool = false
var shelter: bool = false              # v19: кошка в приюте (просто живёт там)
const CAT_K: float = 0.6667


func _ready() -> void:
	add_to_group("interactables")
	y_sort_enabled = true
	spr = Sprite2D.new()
	spr.texture = load(preload("res://cats26_db.gd").tex_path(skin))   # v26: пушистые окрасы
	spr.hframes = 10
	spr.centered = false
	spr.offset = Vector2(-21, -35)
	spr.scale = Vector2(CAT_K, CAT_K)
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(spr)
	t = randf() * 3.0


func _process(delta: float) -> void:
	t += delta
	var pl: Node2D = main.get("player") as Node2D if main != null else null
	if pl != null and not snapped and not shelter and pl.global_position.distance_to(global_position) < 800.0:
		# область рядом уже построена: сдвигаем кошку из дерева или камня на свободное место
		snapped = true
		position = main.call("free_near", position)
	var flick: bool = fmod(t, 3.4) < 0.4
	spr.frame = (1 if flick else 0)
	if pl != null and pl.global_position.distance_to(global_position) < 180.0:
		meow_t -= delta
		if meow_t <= 0.0:
			meow_t = randf_range(3.0, 6.0)
			Sound.play("meow_%d" % randi_range(0, 3), -6.0, 0.1, global_position)
			_say("Мяу!")


func _say(text: String) -> void:
	var l: Label = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 9)
	l.add_theme_color_override("font_color", Color("fff4e0"))
	l.add_theme_color_override("font_outline_color", Color("2a1622"))
	l.add_theme_constant_override("outline_size", 5)
	l.position = Vector2(-8, -40)
	l.z_index = 60
	add_child(l)
	var tw: Tween = create_tween().set_parallel(true)
	tw.tween_property(l, "position:y", l.position.y - 12.0, 1.2)
	tw.tween_property(l, "modulate:a", 0.0, 0.5).set_delay(0.7)
	tw.chain().tween_callback(l.queue_free)


func get_prompt() -> String:
	if shelter:
		return "Погладить: %s" % cat_name
	return "Взять кошку %s" % cat_name


func interact() -> void:
	if shelter:
		Sound.play("purr", -6.0)
		Game.fx.emit(global_position + Vector2(0, -30), "heart")
		_say("Мрр!")
		return
	Sound.play("purr", -6.0)
	Game.fx.emit(global_position + Vector2(0, -30), "heart")
	var qn: Node = get_tree().get_first_node_in_group("quests18")
	if qn != null:
		qn.call("cat_found", quest_id)

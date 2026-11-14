extends Node2D
## v24: поваленное дерево на земле. Сначала лежит целиком с ветками («crown»): топором обрубаешь ветки —
## выпадают длинные ветки, хворост, листья. Потом остаётся голый ствол («trunk»): топором рубишь на поленья
## или поднимаешь и несёшь — одной не поднять, нужны помощницы (2 человека — медленно, 5 — легко).
## Данные — запись в Game.felled (rec); trees24.gd создаёт и сохраняет.

const TRIM_HITS: int = 4
const CUT_HITS: int = 6
const TRUNK_LEN: float = 104.0

var rec: Dictionary = {}
var mgr: Node = null
var spr: Sprite2D
var interact_offset: Vector2 = Vector2(0, -8)
var shake_t: float = 0.0
var carried: bool = false
var claim: Node = null             # работница, которая занялась этим деревом


func setup(r: Dictionary, m: Node, animate: bool, flip: bool) -> void:
	rec = r
	mgr = m
	position = Vector2(float(r["x"]), float(r["y"]))
	spr = Sprite2D.new()
	spr.centered = false
	add_child(spr)
	_apply_look()
	if String(rec["state"]) == "crown":
		spr.flip_h = flip
		if animate:
			spr.rotation = 0.0
			var dir: float = float(rec["dir"])
			var tw: Tween = create_tween()
			tw.tween_property(spr, "rotation", dir * 0.18, 0.55).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
			tw.tween_property(spr, "rotation", dir * PI / 2.0, 0.75).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
			tw.tween_property(spr, "rotation", dir * (PI / 2.0 - 0.07), 0.12).set_ease(Tween.EASE_OUT)
			tw.tween_property(spr, "rotation", dir * PI / 2.0, 0.14).set_ease(Tween.EASE_IN)
			Sound.play("tree_crack", -4.0, 0.08, global_position)
			get_tree().create_timer(1.3).timeout.connect(func() -> void:
				Sound.play("tree_thud", -2.0, 0.08, global_position)
				Game.fx.emit(global_position + Vector2(dir * 60.0, -6), "dust")
				Game.fx.emit(global_position + Vector2(dir * 90.0, -12), "leaves")
				Game.fx.emit(global_position + Vector2(dir * 40.0, -4), "dust"))
	add_to_group("interactables")
	add_to_group("felled24")


func _apply_look() -> void:
	var dir: float = float(rec["dir"])
	if String(rec["state"]) == "crown":
		var t: Texture2D = load("res://art/%s.png" % String(rec["tex"]))
		spr.texture = t
		var foot: float = float(mgr.call("foot", String(rec["tex"]), t)) if mgr != null else float(t.get_height())
		spr.offset = Vector2(-floorf(t.get_width() / 2.0), -foot)
		spr.rotation = dir * PI / 2.0
		spr.position = Vector2.ZERO
	else:
		var tt: Texture2D = load("res://art/trunk24_%s.png" % String(rec["fam"]))
		spr.texture = tt
		spr.rotation = 0.0
		spr.flip_h = dir < 0.0
		# срез у пня (слева при падении вправо), ствол лежит в сторону падения
		spr.offset = Vector2(-2.0 if dir > 0.0 else -tt.get_width() + 2.0, -tt.get_height() + 3.0)
		spr.position = Vector2(dir * 10.0, 0.0)


## Точка ствола, ближайшая к героине — сюда смотрит подсказка E и сюда подходят работницы
func point_near(p: Vector2) -> Vector2:
	var dir: float = float(rec["dir"])
	var a: Vector2 = global_position + Vector2(dir * 8.0, -6)
	var b: Vector2 = global_position + Vector2(dir * (TRUNK_LEN - 6.0), -6)
	var ab: Vector2 = b - a
	var k: float = clampf((p - a).dot(ab) / maxf(ab.length_squared(), 1.0), 0.0, 1.0)
	return a + ab * k


func center() -> Vector2:
	return global_position + Vector2(float(rec["dir"]) * TRUNK_LEN * 0.5, -6)


func _process(delta: float) -> void:
	if carried:
		return
	var pl: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if pl != null:
		interact_offset = point_near(pl.global_position + Vector2(0, -10)) - global_position + Vector2(0, -4)
	if shake_t > 0.0:
		shake_t -= delta
		spr.position.x = (float(rec["dir"]) * 10.0 if String(rec["state"]) == "trunk" else 0.0) + sin(shake_t * 60.0) * 1.5 * shake_t * 4.0


func get_prompt() -> String:
	if carried:
		return ""
	if String(rec["state"]) == "crown":
		return "Обрубить ветки"
	return "Ствол"


func interact() -> void:
	if mgr != null:
		mgr.call("on_felled_interact", self)


## Удар топором: по веткам или по стволу. by — кто бьёт (героиня или работница). true — дело сделано.
func hit(by: Node2D) -> bool:
	shake_t = 0.25
	rec["hits"] = int(rec.get("hits", 0)) + 1
	var at: Vector2 = point_near(by.global_position if by != null else global_position)
	if String(rec["state"]) == "crown":
		Sound.play("chop", -7.0, 0.15, at)
		Game.fx.emit(at + Vector2(0, -10), "leaves" if randf() < 0.6 else "chips")
		if int(rec["hits"]) >= TRIM_HITS:
			rec["hits"] = 0
			rec["state"] = "trunk"
			Sound.play("branch_snap", -4.0, 0.1, at)
			Game.fx.emit(center() + Vector2(0, -16), "leaves")
			_apply_look()
			# срезанные ветки лежат кучкой рядом
			var heap: Sprite2D = Sprite2D.new()
			heap.texture = load("res://art/branch_heap24.png")
			heap.position = global_position + Vector2(float(rec["dir"]) * 70.0, 10.0)
			heap.z_index = -2
			get_parent().add_child(heap)
			var tw: Tween = heap.create_tween()
			tw.tween_interval(6.0)
			tw.tween_property(heap, "modulate:a", 0.0, 2.0)
			tw.tween_callback(heap.queue_free)
			mgr.call("drop_trim", self, by)
			return true
	else:
		Sound.play("chop", -4.0, 0.12, at)
		Game.fx.emit(at + Vector2(0, -8), "chips")
		if int(rec["hits"]) >= CUT_HITS:
			mgr.call("drop_logs", self, by)
			return true
	return false

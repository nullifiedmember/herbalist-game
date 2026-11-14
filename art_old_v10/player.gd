extends Node2D
## Травница. WASD/стрелки — ходить, E — действие.

signal target_changed(target: Node2D)

const SPEED: float = 92.0
const REACH: float = 46.0

var sprite: Sprite2D
var facing: int = 0          # 0 вниз, 1 вверх, 2 влево, 3 вправо
var anim_t: float = 0.0
var target: Node2D = null
var blocked: Callable        # func(p: Vector2) -> bool


func _ready() -> void:
	sprite = Sprite2D.new()
	sprite.texture = load("res://art/player.png")
	sprite.hframes = 4
	sprite.vframes = 4
	sprite.centered = false
	# героиня нарисована вдвое мельче по пикселю (кадр 80x160), поэтому масштаб 0.5
	sprite.offset = Vector2(-40, -157)
	sprite.scale = Vector2(0.5, 0.5)
	add_child(sprite)


func _physics_process(delta: float) -> void:
	var dir: Vector2 = Vector2.ZERO
	if not Game.ui_open and not Game.busy:
		if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
			dir.y -= 1.0
		if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
			dir.y += 1.0
		if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
			dir.x -= 1.0
		if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
			dir.x += 1.0
	if dir != Vector2.ZERO:
		var step: Vector2 = dir.normalized() * SPEED * delta
		var nx: Vector2 = position + Vector2(step.x, 0.0)
		if not _is_blocked(nx):
			position = nx
		var ny: Vector2 = position + Vector2(0.0, step.y)
		if not _is_blocked(ny):
			position = ny
		if absf(dir.x) > absf(dir.y):
			facing = 2 if dir.x < 0.0 else 3
		else:
			facing = 0 if dir.y > 0.0 else 1
		anim_t += delta * 7.0
	else:
		anim_t = 0.0
	var frame: int = int(anim_t) % 4
	sprite.frame = facing * 4 + frame
	_update_target()


func _is_blocked(p: Vector2) -> bool:
	if blocked.is_valid():
		return bool(blocked.call(p))
	return false


func _update_target() -> void:
	var best: Node2D = null
	var best_score: float = REACH
	var face_dir: Vector2 = [Vector2.DOWN, Vector2.UP, Vector2.LEFT, Vector2.RIGHT][facing]
	for node in get_tree().get_nodes_in_group("interactables"):
		var n: Node2D = node as Node2D
		if n == null or not n.is_visible_in_tree():
			continue
		var ip: Vector2 = n.global_position + Vector2(n.get("interact_offset"))
		var to: Vector2 = ip - (global_position + Vector2(0, -10))
		var d: float = to.length()
		if d > REACH:
			continue
		var score: float = d - (to.normalized().dot(face_dir) * 10.0 if d > 0.1 else 0.0)
		if score < best_score:
			best_score = score
			best = n
	if best != target:
		target = best
		target_changed.emit(target)


func _unhandled_input(event: InputEvent) -> void:
	if Game.ui_open or Game.busy:
		return
	if event is InputEventKey and event.pressed and not event.echo and (event as InputEventKey).physical_keycode == KEY_E:
		if target != null and is_instance_valid(target):
			target.call("interact")
			target = null
			_update_target()
			get_viewport().set_input_as_handled()

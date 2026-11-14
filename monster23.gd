extends Node2D
## v23: монстр подземелья. Добрые битвы без крови: побеждённый монстр исчезает облачком звёздочек
## (сонный, смеётся или просто «пуф» — и домой к маме), оставляя монетки и добычу.

const V = preload("res://v23_data.gd")

var kind: String = "slime"
var info: Dictionary = {}
var hp: float = 10.0
var hp_max: float = 10.0
var dmg: float = 4.0
var speed: float = 30.0
var boss: bool = false
var tier: int = 1
var spr: Sprite2D
var bar: Node2D
var blocked: Callable
var home: Vector2
var t: float = 0.0
var hit_cd: float = 0.0
var flash_t: float = 0.0
var knock: Vector2 = Vector2.ZERO
var stun_t: float = 0.0          # спит или смеётся — не дерётся
var slow_t: float = 0.0
var wander_to: Vector2
var wait_t: float = 1.0
var dead: bool = false
var fx_word: String = ""
var on_defeat: Callable
## v24: проделки — монстры тоже кое-что могут сделать с героиней (без крови)
const IT = preload("res://items_db.gd")
var trick_cd: float = 2.0
var loot: Dictionary = {}          # утащенное: id -> кол-во, "coins" -> монеты
var flee_t: float = 0.0            # убегает с добычей
var loot_icon: Sprite2D


func setup(k: String, at: Vector2, tr: int = 1) -> void:
	kind = k
	info = V.MONSTERS[k]
	tier = tr
	position = at
	home = at
	wander_to = at
	boss = String(info["home"]).begins_with("boss")
	var mult: float = 1.0 + 0.35 * float(tier - 1)
	hp_max = float(info["hp"]) * mult
	hp = hp_max
	dmg = float(info["dmg"]) * (1.0 + 0.2 * float(tier - 1))
	speed = float(info["speed"])
	spr = Sprite2D.new()
	spr.texture = load("res://art/mon_%s.png" % k)
	spr.hframes = 4
	spr.centered = false
	var sz: float = float(info["size"])
	spr.offset = Vector2(-sz / 2.0, -sz + 1.0)
	add_child(spr)
	bar = Node2D.new()
	bar.position = Vector2(0, -sz - 4.0)
	bar.draw.connect(_draw_bar)
	add_child(bar)
	t = randf() * 4.0


func _ready() -> void:
	add_to_group("monsters23")


func _draw_bar() -> void:
	if hp >= hp_max and not boss:
		return
	var w: float = 18.0 if not boss else 40.0
	bar.draw_rect(Rect2(-w / 2.0 - 1, -1, w + 2, 4), Color(0.1, 0.06, 0.1))
	bar.draw_rect(Rect2(-w / 2.0, 0, w * clampf(hp / hp_max, 0.0, 1.0), 2), Color(1.0, 0.75, 0.3) if not boss else Color(1.0, 0.4, 0.5))


func _free(p: Vector2) -> bool:
	return not blocked.is_valid() or not bool(blocked.call(p))


func _process(delta: float) -> void:
	if dead:
		return
	t += delta
	hit_cd = maxf(0.0, hit_cd - delta)
	trick_cd = maxf(0.0, trick_cd - delta)
	flee_t = maxf(0.0, flee_t - delta)
	if loot_icon != null:
		loot_icon.position.y = -float(info["size"]) - 12.0 + sin(t * 5.0) * 2.0
	stun_t = maxf(0.0, stun_t - delta)
	slow_t = maxf(0.0, slow_t - delta)
	flash_t = maxf(0.0, flash_t - delta)
	spr.frame = int(t * (6.0 if stun_t <= 0.0 else 1.5)) % 4
	spr.modulate = Color(3, 3, 3) if flash_t > 0.0 else (Color(0.7, 0.85, 1.2) if slow_t > 0.0 else Color.WHITE)
	if knock.length() > 1.0:
		var kp: Vector2 = position + knock * delta
		if _free(kp):
			position = kp
		knock = knock.move_toward(Vector2.ZERO, 600.0 * delta)
		return
	if stun_t > 0.0:
		if fmod(t, 1.2) < delta:
			Game.fx.emit(global_position + Vector2(0, -float(info["size"])), "zzz" if fx_word == "sleep" else "sparkle")
		return
	var pl: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if pl == null:
		return
	var to: Vector2 = pl.global_position - global_position
	var d: float = to.length()
	var spd: float = speed * (0.5 if slow_t > 0.0 else 1.0)
	var aggro: float = 170.0 if not boss else 260.0
	var goal: Vector2 = wander_to
	if flee_t > 0.0 and not loot.is_empty():
		goal = global_position - to.normalized() * 80.0     # удирает с добычей
		spd *= 1.6
	elif d < aggro:
		goal = pl.global_position
	else:
		wait_t -= delta
		if wait_t <= 0.0 or global_position.distance_to(wander_to) < 4.0:
			wait_t = randf_range(1.0, 3.0)
			wander_to = home + Vector2(randf_range(-70, 70), randf_range(-50, 50))
	var dir: Vector2 = goal - global_position
	if dir.length() > 6.0:
		var step: Vector2 = dir.normalized() * spd * delta
		if _free(position + step):
			position += step
		elif _free(position + Vector2(step.x, 0)):
			position.x += step.x
		elif _free(position + Vector2(0, step.y)):
			position.y += step.y
		spr.flip_h = dir.x < 0.0
	# касание — героиня устаёт (без ран)
	if d < 14.0 + float(info["size"]) * 0.25 and hit_cd <= 0.0:
		hit_cd = 1.1
		var dn: Node = get_tree().get_first_node_in_group("dungeon23")
		if dn != null:
			dn.call("hurt_player", dmg, global_position)
		if trick_cd <= 0.0 and randf() < (0.55 if not boss else 0.35):
			trick(pl)
	bar.queue_redraw()


func shape() -> String:
	return String(info.get("shape", "slime"))


## Проделка по виду монстра. Возвращает, что сделал (для автотеста).
func trick(pl: Node2D) -> String:
	if Game.god_mode or dead or Game.spell_shield > 0.0:
		return ""
	trick_cd = randf_range(5.0, 8.0)
	var top: Vector2 = pl.global_position + Vector2(0, -40)
	var done: String = ""
	match shape():
		"slime", "bug":                       # липкая слизь — еле идёт
			Game.mon_sticky = maxf(Game.mon_sticky, 3.5)
			Game.fx.emit(pl.global_position, "steam_green")
			Sound.play("squeak", -4.0, 0.3, global_position)
			done = "sticky"
		"shroom":                             # сонные споры — задремала на месте
			Game.mon_sleep = maxf(Game.mon_sleep, 1.8)
			Game.fx.emit(top, "zzz")
			done = "sleep"
		"ghost", "bat":                       # напугал — всё наоборот
			Game.mon_confuse = maxf(Game.mon_confuse, 2.5 if shape() == "ghost" else 1.5)
			done = "confuse"
		"golem":                              # швырнул в сторону и оглушил
			_push(pl, (pl.global_position - global_position).normalized() * 46.0)
			Game.mon_sleep = maxf(Game.mon_sleep, 0.7)
			Sound.play("grunt", -2.0, 0.2, global_position)
			done = "throw"
		"frog":                               # язык — притянул к себе
			_push(pl, (global_position - pl.global_position) * 0.6)
			done = "pull"
		"skel", "hound":                      # стащил вещь из сумки и удирает
			done = "steal" if _steal_item(shape() == "hound") else ""
		"imp", "demon":                       # стащил монетки и удирает
			var n: int = mini(Game.coins, randi_range(3, 12) * tier)
			if n > 0:
				Game.coins -= n
				loot["coins"] = int(loot.get("coins", 0)) + n
				Sound.play("coin", -6.0, 0.3, global_position)
				_show_loot(load("res://art/coin.png"))
				flee_t = 6.0
				done = "coins"
			else:
				done = "steal" if _steal_item(false) else ""
	if done != "":
		pl.call("react", "pout" if done in ["steal", "coins"] else "surprised", 1.0)
	return done


func _push(pl: Node2D, by: Vector2) -> void:
	var mn: Node = get_tree().current_scene
	for i in range(6, 0, -1):
		var p: Vector2 = pl.position + by * (float(i) / 6.0)
		if mn == null or not mn.has_method("is_blocked") or not bool(mn.call("is_blocked", p)):
			pl.position = p
			return


## Что можно утащить: из сумки, кроме того, что в руках и на поясе
static func stealable(food_only: bool) -> Array:
	var out: Array = []
	var held: Array = Game.hotbar.duplicate()
	for sl in ["main1", "off1", "main2", "off2"]:
		held.append(Game.worn(sl))
	for id in Game.inventory:
		if int(Game.inventory[id]) <= 0 or held.has(id):
			continue
		if food_only and not String(id).begins_with("food_"):
			continue
		out.append(id)
	return out


func _steal_item(food_only: bool) -> bool:
	var can: Array = stealable(food_only)
	if can.is_empty() and food_only:
		can = stealable(false)
	if can.is_empty():
		return false
	var id: String = String(can[randi() % can.size()])
	var n: int = mini(int(Game.inventory[id]), randi_range(1, 3))
	if not Game.take_item(id, n):
		return false
	loot[id] = int(loot.get(id, 0)) + n
	_show_loot(IT.icon(id))
	flee_t = 6.0
	Sound.play("ui_click", -4.0, 0.4, global_position)
	return true


func _show_loot(tex: Texture2D) -> void:
	if loot_icon == null:
		loot_icon = Sprite2D.new()
		loot_icon.scale = Vector2(0.6, 0.6)
		add_child(loot_icon)
	loot_icon.texture = tex


## Вернуть утащенное: героине (победила) или в тайник монстров (ушла из подземелья)
func give_back(to_stash: bool) -> void:
	for id in loot:
		var n: int = int(loot[id])
		if to_stash:
			Game.mon_stash[id] = int(Game.mon_stash.get(id, 0)) + n
		elif String(id) == "coins":
			Game.add_coins(n)
		else:
			Game.add_item(String(id), n)
	loot.clear()
	if loot_icon != null:
		loot_icon.queue_free()
		loot_icon = null


## Удар героини. fx — особое свойство оружия.
func take_hit(amount: float, from: Vector2, fx: String) -> void:
	if dead:
		return
	if fx == "fire":
		amount *= 1.3
	elif fx == "void":
		amount *= 1.2
	hp -= amount
	flash_t = 0.1
	knock = (global_position - from).normalized() * (160.0 if not boss else 60.0)
	Sound.play("squeak" if kind.begins_with("slime") else "grunt", -8.0, 0.3, global_position)
	match fx:
		"frost":
			slow_t = 3.0
		"sleep", "holy":
			if randf() < (0.35 if fx == "sleep" else 0.2) and not boss:
				stun_t = 3.0
				fx_word = "sleep"
		"fun":
			if randf() < 0.4:
				stun_t = 2.5
				fx_word = "fun"
				if randf() < 0.2:
					Game.toast.emit("Ха-ха-ха! Монстр смеётся и забыл, что дерётся.", load("res://art/fx_heart.png"))
	bar.queue_redraw()
	if hp <= 0.0:
		defeat()


func defeat() -> void:
	if dead:
		return
	dead = true
	remove_from_group("monsters23")
	Game.fx.emit(global_position + Vector2(0, -float(info["size"]) * 0.5), "sparkle")
	Game.fx.emit(global_position + Vector2(0, -float(info["size"]) * 0.5), "cream")
	Sound.play("magic", -6.0, 0.2, global_position)
	give_back(false)
	if on_defeat.is_valid():
		on_defeat.call(self)
	var tw: Tween = create_tween()
	tw.tween_property(self, "scale", Vector2(1.3, 0.2), 0.2)
	tw.parallel().tween_property(self, "modulate:a", 0.0, 0.25)
	tw.tween_callback(queue_free)

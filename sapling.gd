extends Node2D
## Посаженный саженец: каждый новый день подрастает, на четвёртый — становится деревом.

var tree: String = "tree_a"
var planted: int = 1
var main: Node2D
var home: Node
var spr: Sprite2D
var stage: int = -1


func _ready() -> void:
	spr = Sprite2D.new()
	spr.centered = false
	add_child(spr)
	Game.day_changed.connect(_grow)
	_grow()


func _grow() -> void:
	var age: int = Game.day - planted
	if age >= 3:
		home.call("grow_tree", tree, global_position)
		queue_free()
		return
	if age != stage:
		stage = age
		var own: String = "res://art/sapling_%s_%d.png" % [tree, clampi(age, 0, 2)]
		spr.texture = load(own if ResourceLoader.exists(own) else "res://art/sapling_%d.png" % clampi(age, 0, 2))
		spr.offset = Vector2(-20, -48)

extends Node2D
## Ведро со шваброй в углу кухни. E — взять швабру (или поставить обратно). Без подсказок.

var interact_offset: Vector2 = Vector2(0, -4)
var sprite: Sprite2D
var tex_full: Texture2D
var tex_empty: Texture2D


func _ready() -> void:
	add_to_group("interactables")
	add_to_group("mop_stands")
	tex_full = load("res://art/in_mop.png")
	tex_empty = load("res://art/in_bucket.png")


func get_prompt() -> String:
	return ""


func interact() -> void:
	Game.has_mop = not Game.has_mop
	refresh()


func refresh() -> void:
	if sprite != null:
		sprite.texture = tex_empty if Game.has_mop else tex_full

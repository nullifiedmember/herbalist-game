extends Node2D
## Шкаф в спальне. E — открыть и взять удочку со снастями (один раз). Без подсказок.

var interact_offset: Vector2 = Vector2(0, 4)
var sprite: Sprite2D
var tex_open: Texture2D


func _ready() -> void:
	add_to_group("interactables")
	add_to_group("wardrobes")
	tex_open = load("res://art/dp_wardrobe.png")


func get_prompt() -> String:
	return ""


func interact() -> void:
	if sprite != null and tex_open != null:
		sprite.texture = tex_open
	if not Game.has_rod:
		Game.has_rod = true
		Game.fx.emit(global_position + Vector2(0, -40), "dust")

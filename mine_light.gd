extends Node2D
## Фонарь в шахте: светит в темноте (слой darkness.gd берёт свет у группы campfires).


func _ready() -> void:
	add_to_group("campfires")


func light_radius() -> float:
	return 270.0 if is_visible_in_tree() else 0.0

extends Node
## Быстрая проверка: все скрипты игры компилируются (с автозагрузками, поэтому запускается сценой check14.tscn)

func _ready() -> void:
	var bad: int = 0
	var dir: DirAccess = DirAccess.open("res://")
	for f in dir.get_files():
		if not f.ends_with(".gd"):
			continue
		var s: Script = load("res://" + f)
		if s == null or not s.can_instantiate():
			print("BAD ", f)
			bad += 1
	print("bad=", bad)
	get_tree().quit()

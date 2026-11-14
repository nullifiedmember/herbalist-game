extends SceneTree
## Быстрая проверка: все скрипты игры загружаются без ошибок.
## godot --headless --path game -s res://tools/check_compile.gd


func _init() -> void:
	var bad: int = 0
	var d: DirAccess = DirAccess.open("res://")
	for f in d.get_files():
		if not String(f).ends_with(".gd"):
			continue
		var s: Script = load("res://" + String(f)) as Script
		if s == null or not s.can_instantiate():
			print("BAD ", f)
			bad += 1
	print("bad=", bad)
	quit()

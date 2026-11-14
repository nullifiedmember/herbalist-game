extends SceneTree
## Проверка физики окон: печатает, как падает и ложится предмет


func _init() -> void:
	var PH = load("res://phys2d.gd")
	var b: Dictionary = PH.make(Vector2(500, 200), Vector2(40, 120), Vector2(300, -200), 6.0)
	for i in range(300):
		PH.step(b, 1.0 / 60.0, 800.0, 0.0, 1920.0)
		if i % 30 == 0 or i > 290:
			var low: float = -1e9
			for c in PH.corners(b):
				low = maxf(low, (c as Vector2).y)
			print("%d pos=%s vel=%s ang=%.2f av=%.2f low=%.1f sleep=%.2f" % [i, str(b["pos"]), str(b["vel"]), float(b["ang"]), float(b["av"]), low, float(b["sleep"])])
	quit()

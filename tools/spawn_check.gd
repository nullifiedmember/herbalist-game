extends SceneTree
## Где встанет дом в каждом биоме старта: точка, расстояние до дороги, биом в углах двора

func _init() -> void:
	var SCN = load("res://scenarios_db.gd")
	var WD = load("res://world_data.gd")
	for key in SCN.SPAWN_ORDER:
		var t0: int = Time.get_ticks_msec()
		var p: Vector2 = SCN.find_home(String(key))
		var road: float = 9999.0
		for gy in range(-3, 4):
			for gx in range(-4, 5):
				road = minf(road, WD.road_value(p + Vector2(gx * 90.0, gy * 100.0)))
		var bs: Array = []
		for q in [Vector2(-300, -250), Vector2(300, -250), Vector2(-300, 250), Vector2(300, 250), Vector2.ZERO]:
			bs.append(WD.biome_at(p + (q as Vector2)))
		print("%-14s %s road=%d town=%d biomes=%s want=%d  %d ms" % [key, str(p), int(road), int(SCN.town_dist(p)), str(bs), int(SCN.SPAWNS[key]["biome"]), Time.get_ticks_msec() - t0])
	quit()

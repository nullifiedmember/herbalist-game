extends RefCounted
## v27: растение «растёт из земли» — под ним тень-лунка и травинки цвета земли того биома, где оно стоит,
## а само растение чуть подкрашено в тон земли. Арт основания: tools/apple_art/plant_base.py.

const WD = preload("res://world_data.gd")
const BACK = preload("res://art/plant_base_back.png")
const FRONT = preload("res://art/plant_base_front.png")
# средний цвет земли каждого биома (из wt_atlas.png)
const COL: Dictionary = {
	0: Color("99c582"), 1: Color("99c582"), 2: Color("606078"), 3: Color("655b59"), 4: Color("95c475"),
	5: Color("469d75"), 6: Color("7c82b1"), 7: Color("bb9d5d"), 8: Color("7e776d"), 9: Color("accd7a"),
	10: Color("d9a5bc"), 11: Color("504e67"), 12: Color("acce78"), 13: Color("487850"), 14: Color("c69150"),
	15: Color("546a54"), 16: Color("c2c966"), 17: Color("80aa6d"), 18: Color("edd9af"), 19: Color("3e7db3"),
}
# травинки — как короткая трава биома (world.gd GRASS_TINT), а не как голая земля, иначе их не видно
const GRASS_BASE: Color = Color("6f9a55")
const GRASS_TINT: Dictionary = {
	2: Color(0.7, 0.68, 0.85), 3: Color(0.72, 0.66, 0.78), 5: Color(0.85, 1.05, 0.95), 6: Color(0.88, 0.9, 1.05),
	7: Color(1.15, 1.0, 0.62), 8: Color(0.85, 0.85, 0.8), 9: Color(1.05, 1.02, 0.9), 10: Color(1.15, 0.86, 1.05),
	11: Color(0.75, 0.78, 0.9), 12: Color(1.05, 1.08, 0.9), 13: Color(0.8, 0.95, 0.85), 14: Color(1.2, 0.95, 0.6),
	15: Color(0.75, 0.88, 0.75), 16: Color(1.15, 1.08, 0.75),
}
const NO_BLADES: Array = [18, 19]   # песок и море — только тень


static func ground_color(p: Vector2) -> Color:
	return COL.get(WD.biome_at(p), COL[1])


## s — спрайт растения (начало координат — у корня), p — где он стоит в мире
static func attach(s: Sprite2D, p: Vector2, tint_plant: float = 0.12) -> void:
	if s == null or not WD.in_world(p):
		return   # под водой, в пещерах и домах — без основания
	var b: int = WD.biome_at(p)
	var c: Color = COL.get(b, COL[1])
	var bk: Sprite2D = Sprite2D.new()
	bk.name = "PlantBaseBack"
	bk.texture = BACK
	bk.position = Vector2(0, -3)
	bk.show_behind_parent = true
	var gt: Color = GRASS_BASE * (GRASS_TINT.get(b, Color.WHITE) as Color)
	bk.modulate = Color(c.r * 0.85, c.g * 0.85, c.b * 0.85, 1.0).lerp(Color(gt.r, gt.g, gt.b, 1.0), 0.35)
	s.add_child(bk)
	if not b in NO_BLADES:
		var fr: Sprite2D = Sprite2D.new()
		fr.name = "PlantBaseFront"
		fr.texture = FRONT
		fr.position = Vector2(0, -2)
		fr.modulate = Color(gt.r * 1.12, gt.g * 1.12, gt.b * 1.12, 1.0)
		s.add_child(fr)
	# само растение — чуть в тон земли (тёплая земля — теплее, сумрачная — темнее)
	var lum: float = (c.r + c.g + c.b) / 3.0
	var tone: Color = Color(c.r / maxf(lum, 0.01), c.g / maxf(lum, 0.01), c.b / maxf(lum, 0.01)) * clampf(0.75 + lum * 0.45, 0.8, 1.05)
	s.self_modulate = s.self_modulate * Color.WHITE.lerp(Color(tone.r, tone.g, tone.b, 1.0), tint_plant)

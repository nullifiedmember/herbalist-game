extends SceneTree


func _init() -> void:
	for n in ["seeds_mint", "mint_3", "ui_key"]:
		var t: Texture2D = load("res://art/%s.png" % n)
		var im: Image = t.get_image()
		print(n, " size=", t.get_size(), " px(16,20)=", im.get_pixel(mini(16, im.get_width() - 1), mini(20, im.get_height() - 1)), " px(0,0)=", im.get_pixel(0, 0), " fmt=", im.get_format())
	quit()

extends SceneTree
## Проверка: у каждого зверя есть 3 загружаемых голоса.
## godot --headless --path . -s res://tools/check_voices.gd
const AV = preload("res://animal_voices_db.gd")


func _init() -> void:
	var bad: int = 0
	for id in AV.VOICE:
		for v in ["0", "1", "pet"]:
			var p: String = "res://audio/av_%s_%s.wav" % [id, v]
			if not (load(p) is AudioStream):
				print("BAD ", p)
				bad += 1
	print("voices: %d зверей, плохих %d" % [AV.VOICE.size(), bad])
	quit()

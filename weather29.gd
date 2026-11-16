extends Node2D
## v29: погода. Ясно, облачно, дождь, гроза, туман — меняется через несколько часов.
## Дождь поливает грядки (все группы «plots»: задний двор и старые грядки), наполняет бочку,
## после дождливого дня растения растут быстрее. Капли косые — по ветру (Game.wind).
## Рисуется в мире вокруг камеры (под интерфейсом); в домах и подземельях не видно, только слышно тише.

const NAMES: Dictionary = {"clear": "Ясно", "cloudy": "Облачно", "rain": "Дождь", "storm": "Гроза", "fog": "Туман"}
const NEXT: Dictionary = {
	"clear": [["clear", 45], ["cloudy", 38], ["rain", 10], ["fog", 7]],
	"cloudy": [["clear", 30], ["cloudy", 22], ["rain", 36], ["storm", 12]],
	"rain": [["cloudy", 42], ["rain", 28], ["storm", 12], ["clear", 18]],
	"storm": [["rain", 60], ["cloudy", 40]],
	"fog": [["clear", 55], ["cloudy", 45]],
}

var main: Node2D
var hud: CanvasLayer
var last_min: float = -1.0
var amount: float = 0.0          # видимая сила дождя 0..1 (плавно)
var dim: float = 0.0             # затемнение неба
var fog: float = 0.0
var flash: float = 0.0
var thunder_t: float = 8.0
var drops: Array = []            # [Vector2 (0..1 в кадре), скорость, длина]
var puffs: Array = []
var rain_p: AudioStreamPlayer
var thunder_p: AudioStreamPlayer
var outdoor: bool = true
var label_icon: TextureRect
var label_text: Label


func setup(m: Node2D, h: CanvasLayer) -> void:
	main = m
	hud = h
	add_to_group("weather29")
	z_index = 60
	for i in range(260):
		drops.append([Vector2(randf(), randf()), randf_range(0.9, 1.3), randf_range(6.0, 11.0)])
	for i in range(16):
		puffs.append([Vector2(randf(), randf()), randf_range(60.0, 130.0), randf_range(0.3, 1.0)])
	rain_p = AudioStreamPlayer.new()
	rain_p.bus = "SFX"
	var st: AudioStreamWAV = (load("res://audio/rain29.wav") as AudioStreamWAV).duplicate()
	st.loop_mode = AudioStreamWAV.LOOP_FORWARD
	st.loop_begin = 0
	st.loop_end = st.data.size() / 2
	rain_p.stream = st
	rain_p.volume_db = -80.0
	add_child(rain_p)
	thunder_p = AudioStreamPlayer.new()
	thunder_p.bus = "SFX"
	thunder_p.stream = load("res://audio/thunder29.wav")
	add_child(thunder_p)
	if not NAMES.has(Game.weather):
		Game.weather = "clear"
	amount = 1.0 if Game.weather in ["rain", "storm"] else 0.0
	# значок погоды в табличке часов
	var cr: Control = hud.get("clock_root")
	if cr != null:
		label_icon = TextureRect.new()
		label_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		label_icon.size = Vector2(26, 26)
		label_icon.scale = Vector2(1.4, 1.4)
		label_icon.position = Vector2(104, 56)
		label_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cr.add_child(label_icon)
		label_text = Label.new()
		label_text.add_theme_font_override("font", hud.get("font_bold"))
		label_text.add_theme_font_size_override("font_size", 22)
		label_text.add_theme_color_override("font_color", Color("6b5440"))
		label_text.position = Vector2(144, 62)
		label_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cr.add_child(label_text)


func text() -> String:
	return String(NAMES.get(Game.weather, ""))


func raining() -> bool:
	return Game.weather in ["rain", "storm"]


## Сменить погоду (и для проверок/режима бога)
func set_weather(w: String, hours: float = -1.0) -> void:
	Game.weather = w
	Game.weather_h = hours if hours > 0.0 else randf_range(2.0, 6.0)
	if w == "storm":
		thunder_t = 2.0


func _roll() -> void:
	var opts: Array = NEXT.get(Game.weather, NEXT["clear"])
	var tot: float = 0.0
	for o in opts:
		tot += float(o[1])
	var r: float = randf() * tot
	var pick: String = "clear"
	for o in opts:
		r -= float(o[1])
		if r <= 0.0:
			pick = String(o[0])
			break
	# туман — только утром и вечером
	var h: float = Game.hour()
	if pick == "fog" and not (h < 10.0 or h > 19.0):
		pick = "cloudy"
	set_weather(pick)


func _hour() -> void:
	Game.weather_h -= 1.0
	if Game.weather_h <= 0.0:
		_roll()
	if raining():
		Game.rain_today += 1.0
		get_tree().call_group("plots", "rain29")
		get_tree().call_group("backyard29", "rain29")


func _is_outdoor() -> bool:
	if main == null:
		return false
	if bool(main.get("inside")) or main.get("visiting") != null:
		return false
	var live: Node = main.get("live")
	if live != null and bool(live.get("active")):
		return false
	var pl: Node2D = main.get("player")
	if pl == null:
		return false
	var p: Vector2 = pl.position
	return p.y < 90000.0 and p.y > -150000.0 and p.x < 150000.0 and p.x > -50000.0


func _process(delta: float) -> void:
	var abs_min: float = float(Game.day) * 1440.0 + Game.minutes
	if last_min < 0.0 or abs_min < last_min:
		last_min = abs_min
	while abs_min - last_min >= 60.0:
		last_min += 60.0
		_hour()
	outdoor = _is_outdoor()
	var want_rain: float = 1.0 if Game.weather == "storm" else (0.7 if Game.weather == "rain" else 0.0)
	amount = move_toward(amount, want_rain, delta * 0.25)
	var want_dim: float = {"clear": 0.0, "cloudy": 0.10, "rain": 0.2, "storm": 0.32, "fog": 0.06}.get(Game.weather, 0.0)
	dim = move_toward(dim, want_dim, delta * 0.08)
	fog = move_toward(fog, 1.0 if Game.weather == "fog" else 0.0, delta * 0.1)
	flash = maxf(0.0, flash - delta * 3.0)
	if Game.weather == "storm":
		thunder_t -= delta
		if thunder_t <= 0.0:
			thunder_t = randf_range(7.0, 18.0)
			if outdoor:
				flash = 1.0
			if not Sound.muted:
				thunder_p.volume_db = -2.0 if outdoor else -12.0
				thunder_p.pitch_scale = randf_range(0.85, 1.1)
				thunder_p.play()
	# звук дождя: на улице громко, под крышей глуше
	var vol: float = -80.0 if amount < 0.02 else linear_to_db(amount) + (-4.0 if outdoor else -16.0)
	rain_p.volume_db = move_toward(rain_p.volume_db, vol, delta * 30.0)
	if amount > 0.02 and not rain_p.playing and not Sound.muted:
		rain_p.play()
	elif amount <= 0.02 and rain_p.playing and rain_p.volume_db < -60.0:
		rain_p.stop()
	# надпись и значок у часов
	if label_text != null:
		label_text.text = text()
	if label_icon != null:
		label_icon.texture = load("res://art/wx29_%s.png" % Game.weather)
	var cam: Camera2D = main.get("cam")
	if cam != null:
		position = cam.get_screen_center_position()
	visible = outdoor and (amount > 0.01 or dim > 0.005 or fog > 0.01 or flash > 0.0)
	if visible:
		queue_redraw()


func _draw() -> void:
	var view: Vector2 = Vector2(660, 380)
	var tl: Vector2 = -view / 2.0
	if dim > 0.0:
		draw_rect(Rect2(tl, view), Color(0.22, 0.26, 0.36, dim))
	if fog > 0.0:
		var tt: float = Time.get_ticks_msec() / 1000.0
		for p in puffs:
			var q: Vector2 = p[0]
			var x: float = fposmod(q.x * view.x + tt * 6.0 * float(p[2]), view.x + 200.0) - 100.0
			draw_circle(tl + Vector2(x, q.y * view.y), float(p[1]), Color(0.95, 0.95, 0.92, 0.10 * fog))
		draw_rect(Rect2(tl, view), Color(0.92, 0.92, 0.9, 0.22 * fog))
	if amount > 0.0:
		var tt2: float = Time.get_ticks_msec() / 1000.0
		var slant: float = 0.25 + clampf(float(Game.get("wind")) if Game.get("wind") != null else 0.0, 0.0, 1.0) * 0.5
		var n: int = int(drops.size() * amount)
		var col: Color = Color(0.78, 0.84, 0.95, 0.55)
		for i in range(n):
			var d: Array = drops[i]
			var q: Vector2 = d[0]
			var sp: float = float(d[1])
			var y: float = fposmod(q.y * view.y + tt2 * 420.0 * sp, view.y)
			var x: float = fposmod(q.x * view.x + y * slant, view.x)
			var a: Vector2 = tl + Vector2(x, y)
			var ln: float = float(d[2])
			draw_line(a, a + Vector2(slant * ln, ln), col, 1.0)
			# брызги у земли
			if y > view.y * 0.6 and fposmod(tt2 * 3.0 + q.x * 13.0, 1.0) < 0.06:
				draw_rect(Rect2(a + Vector2(-1, ln), Vector2(3, 1)), Color(0.85, 0.9, 1.0, 0.5))
	if flash > 0.0:
		draw_rect(Rect2(tl, view), Color(1, 1, 0.96, 0.55 * flash))

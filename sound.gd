extends Node
## Звук всей игры (автозагрузка Sound): музыка с плавной сменой (меню / день / город / ночь),
## фон природы (ветер днём, сверчки ночью), птицы днём и совы ночью вокруг героини,
## короткие звуки: шаги, голоса, монеты, двери, вода, еда, звери.

const DIR: String = "res://audio/"
var music_a: AudioStreamPlayer
var music_b: AudioStreamPlayer
var cur_track: String = ""
var amb_day: AudioStreamPlayer
var amb_night: AudioStreamPlayer
var cache: Dictionary = {}
var music_vol: float = 0.7
var sfx_vol: float = 0.8
var bird_t: float = 3.0
var owl_t: float = 10.0
var mode: String = "menu"        # menu / game
var forced: String = ""          # трек, заданный местом (город)
var muted: bool = false
var theme_p: AudioStreamPlayer
var duck_tw: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for b in ["Music", "SFX", "BGM"]:
		if AudioServer.get_bus_index(b) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, b)
			AudioServer.set_bus_send(AudioServer.bus_count - 1, "Master" if b != "BGM" else "Music")
	muted = DisplayServer.get_name() == "headless"
	# v20: фоновая музыка — на шине BGM (внутри Music): её приглушает тема нового места
	music_a = _player("BGM")
	music_b = _player("BGM")
	theme_p = _player("Music")
	amb_day = _player("SFX")
	amb_night = _player("SFX")
	amb_day.stream = _loop("wind")
	amb_night.stream = _loop("crickets")
	amb_day.volume_db = -80
	amb_night.volume_db = -80
	if not muted:
		amb_day.play()
		amb_night.play()
	apply_volume()


func _player(bus: String) -> AudioStreamPlayer:
	var p: AudioStreamPlayer = AudioStreamPlayer.new()
	p.bus = bus
	add_child(p)
	return p


func _load(name: String) -> AudioStream:
	if not cache.has(name):
		cache[name] = load(DIR + name + ".wav")
	return cache[name]


func _loop(name: String) -> AudioStream:
	var s: AudioStreamWAV = (_load(name) as AudioStreamWAV).duplicate()
	s.loop_mode = AudioStreamWAV.LOOP_FORWARD
	s.loop_begin = 0
	var frames: int = s.data.size() / 2 if s.format == AudioStreamWAV.FORMAT_16_BITS else s.data.size()
	if s.stereo:
		frames /= 2
	s.loop_end = frames
	return s


func apply_volume() -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(maxf(music_vol, 0.0001)))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(maxf(sfx_vol, 0.0001)))


## v21: плейлисты. В каждом настроении (меню / день / город / ночь) по два трека — новый струнный и прежний.
## Трек играет один раз, за FADE секунд до конца плавно переходит в следующий (другой) из того же плейлиста.
const POOLS: Dictionary = {
	"menu": ["music_menu", "music_old_menu"],
	"day": ["music_day", "music_old_day"],
	"town": ["music_town", "music_old_town"],
	"night": ["music_night", "music_old_night"],
	"club": ["music_rock"],
}
const FADE: float = 6.0
var pool_name: String = ""
var cur_p: AudioStreamPlayer
var cur_len: float = 0.0
var fades: Dictionary = {}


func _once(name: String) -> AudioStream:
	var s: AudioStreamWAV = (_load(name) as AudioStreamWAV).duplicate()
	s.loop_mode = AudioStreamWAV.LOOP_DISABLED
	return s


func _fade(p: AudioStreamPlayer, to_db: float, dur: float, stop_after: bool) -> void:
	if fades.has(p) and fades[p] != null:
		(fades[p] as Tween).kill()
	var tw: Tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(p, "volume_db", to_db, dur)
	if stop_after:
		tw.tween_callback(p.stop)
	fades[p] = tw


## Сменить музыку: имя вида music_day выбирает плейлист «day»; переход плавный
func music(track: String) -> void:
	if muted:
		return
	var key: String = track.trim_prefix("music_")
	if not POOLS.has(key):
		key = "day"
	if key == pool_name:
		return
	pool_name = key
	_play_next()


func _play_next() -> void:
	var pool: Array = POOLS[pool_name]
	var opts: Array = []
	for t in pool:
		if String(t) != cur_track:
			opts.append(t)
	if opts.is_empty():
		opts = pool
	cur_track = String(opts[randi() % opts.size()])
	var old: AudioStreamPlayer = cur_p
	var nw: AudioStreamPlayer = music_b if old == music_a else music_a
	nw.stream = _once(cur_track)
	nw.volume_db = -80.0
	nw.play()
	cur_len = nw.stream.get_length()
	_fade(nw, -6.0, FADE, false)
	if old != null and old.playing:
		_fade(old, -80.0, FADE, true)
	cur_p = nw


## Пора ли переходить к следующему треку (вызывается каждый кадр)
func _music_tick() -> void:
	if cur_p == null or pool_name == "" or not cur_p.playing:
		return
	if cur_p.get_playback_position() >= cur_len - FADE - 0.3:
		_play_next()


## Короткий звук. at — позиция в мире (тогда звук тише вдали), pitch — разброс высоты
func play(name: String, vol_db: float = 0.0, pitch_rand: float = 0.08, at: Variant = null) -> void:
	if muted:
		return
	var st: AudioStream = _load(name)
	if st == null:
		return
	if at != null:
		var p2: AudioStreamPlayer2D = AudioStreamPlayer2D.new()
		p2.bus = "SFX"
		p2.stream = st
		p2.volume_db = vol_db
		p2.pitch_scale = 1.0 + randf_range(-pitch_rand, pitch_rand)
		p2.max_distance = 700.0
		p2.attenuation = 1.6
		p2.position = at
		var scene: Node = get_tree().current_scene
		if scene == null:
			return
		scene.add_child(p2)
		p2.play()
		p2.finished.connect(p2.queue_free)
		return
	var p: AudioStreamPlayer = AudioStreamPlayer.new()
	p.bus = "SFX"
	p.stream = st
	p.volume_db = vol_db
	p.pitch_scale = 1.0 + randf_range(-pitch_rand, pitch_rand)
	add_child(p)
	p.play()
	p.finished.connect(p.queue_free)


## v20: тема нового места (струнные, 10-14 с). Фоновая музыка на это время плавно стихает.
func place_theme(name: String) -> void:
	if muted:
		return
	var st: AudioStream = _load(name)
	if st == null:
		return
	theme_p.stream = st
	theme_p.volume_db = -3.0
	theme_p.play()
	var bus: int = AudioServer.get_bus_index("BGM")
	if duck_tw != null:
		duck_tw.kill()
	duck_tw = create_tween()
	var len_s: float = st.get_length()
	duck_tw.tween_method(func(v: float) -> void: AudioServer.set_bus_volume_db(bus, v), AudioServer.get_bus_volume_db(bus), -22.0, 1.2)
	duck_tw.tween_interval(maxf(1.0, len_s - 3.5))
	duck_tw.tween_method(func(v: float) -> void: AudioServer.set_bus_volume_db(bus, v), -22.0, 0.0, 3.0)


## Голос при разговоре: у каждого жителя своя высота
func talk(voice: int, pitch: float) -> void:
	if muted:
		return
	var p: AudioStreamPlayer = AudioStreamPlayer.new()
	p.bus = "SFX"
	p.stream = _load("talk_%d" % posmod(voice, 4))
	p.volume_db = -10
	p.pitch_scale = pitch * randf_range(0.92, 1.1)
	add_child(p)
	p.play()
	p.finished.connect(p.queue_free)


func _process(delta: float) -> void:
	if muted:
		return
	_music_tick()
	if mode != "game":
		return
	var n: float = Game.night_factor()
	var main: Node = get_tree().current_scene
	var inside: bool = main != null and bool(main.get("inside"))
	var lh: Node = get_tree().get_first_node_in_group("livehouse")
	var in_club: bool = lh != null and bool(lh.get("active"))
	if in_club:
		inside = true
	# музыка: клуб / ночь / город / день
	if in_club:
		music("music_club")
	elif n > 0.6:
		music("music_night")
	elif forced != "":
		music(forced)
	else:
		music("music_day")
	# фон: ветер в листве днём, сверчки ночью; в доме тише
	var k: float = 0.25 if inside else 1.0
	amb_day.volume_db = linear_to_db(maxf(0.0001, (1.0 - n) * 0.22 * k))
	amb_night.volume_db = linear_to_db(maxf(0.0001, n * 0.14 * k))
	if inside or main == null:
		return
	# v20: птицы и совы теперь живые (birds.gd) — каждая поёт своим голосом со своей стороны

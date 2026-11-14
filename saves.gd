extends Node
## Сохранения (автозагрузка Saves). Файл: user://save_<слот>.sav — текст var_to_str (читается глазами,
## понимает Vector2 и PackedByteArray, в отличие от голого JSON).
## Что пишется: все переменные Game (кроме временных), плюс мир от main.save_world():
## постройки, грядки, позиция героини, задания, закон, пути и фракции (paths.gd).
## Когда: после сна, при выходе из дома, раз в AUTOSAVE_SEC секунд игры и при закрытии окна.
## Без надписей: в углу экрана на миг появляется значок книжки с пером.

const VERSION: int = 1
const SLOTS: int = 3
const TEST_SLOT: int = 99            # автотест пишет только сюда — сохранения игрока не трогает
const AUTOSAVE_SEC: float = 180.0
## Переменные Game, которые не сохраняются: состояние окон, ветра, временные таймеры
const SKIP: Array = [
	"ui_open", "busy", "time_frozen", "running_now", "consume_cd", "hold", "wind", "wind_dir",
	"wind_override", "_wind_level", "_wind_dir_goal", "_wind_hold", "_gust", "_gust_timer",
	"TOILET_ENABLED", "new_game_ready", "cool_t", "in_sea", "last_drink", "carry_speed",
	"mon_sticky", "mon_sleep", "mon_confuse", "spell_shield", "spell_speed", "spell_regen", "spell_light",
	"keybinds",                       # v24: клавиши — общие для всех сохранений (settings.cfg)
]

var slot: int = 0                    # текущий слот
var pending_world: Dictionary = {}   # мир, который main должен восстановить после перезапуска сцены
var loaded: bool = false             # игра продолжена из сохранения (меню сразу закрыто)
var defaults: Dictionary = {}        # значения Game на старте программы — для «Новой игры»
var t: float = 0.0
var icon_layer: CanvasLayer
var icon: TextureRect
var icon_t: float = 0.0
var lt_started: bool = false       # автотест перезапуска (--loadtest)
## v24: настройки игры (settings.cfg). Окно — settings24.gd
var opt_defaults: Dictionary = {}
var bright: ColorRect                # яркость: затемнение (умножение) или осветление (сложение) поверх всего
var opt: Dictionary = {
	"master": 1.0, "fullscreen": false, "vsync": true, "fps": 0, "ui_scale": 1.0,
	"run_toggle": false, "autosave": 3, "pause_unfocus": true, "mute_unfocus": false,
	"brightness": 1.0,
}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	defaults = game_vars()
	opt_defaults = opt.duplicate()
	load_settings()
	get_tree().set_auto_accept_quit(false)
	icon_layer = CanvasLayer.new()
	icon_layer.layer = 90
	add_child(icon_layer)
	icon = TextureRect.new()
	icon.texture = load("res://art/icon_scroll.png") if ResourceLoader.exists("res://art/icon_scroll.png") else null
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.size = Vector2(72, 72)
	icon.position = Vector2(1920 - 110, 1080 - 110)
	icon.modulate.a = 0.0
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_layer.add_child(icon)


func path(s: int) -> String:
	return "user://save_%d.sav" % s


func has_save(s: int = -1) -> bool:
	return FileAccess.file_exists(path(slot if s < 0 else s))


## Есть ли хоть одно сохранение (для кнопки «Продолжить»)
func any_save() -> bool:
	for i in range(SLOTS):
		if has_save(i):
			return true
	return false


## Последний по времени слот с сохранением (-1 — нет)
func latest_slot() -> int:
	var best: int = -1
	var bt: int = -1
	for i in range(SLOTS):
		if has_save(i):
			var mt: int = int(FileAccess.get_modified_time(path(i)))
			if mt > bt:
				bt = mt
				best = i
	return best


## Короткие сведения о слоте для меню: день, монеты, сценарий, когда сохранено
func info(s: int) -> Dictionary:
	var d: Dictionary = _read(s)
	if d.is_empty():
		return {}
	return d.get("meta", {})


# ------------------------------------------------------------------ переменные Game

func game_vars() -> Dictionary:
	var out: Dictionary = {}
	for p in Game.get_property_list():
		var pd: Dictionary = p
		if int(pd["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE == 0:
			continue
		var n: String = String(pd["name"])
		if SKIP.has(n):
			continue
		var v: Variant = Game.get(n)
		if v is Object:
			continue
		if v is Dictionary or v is Array:
			out[n] = v.duplicate(true)
		elif typeof(v) >= TYPE_PACKED_BYTE_ARRAY and typeof(v) <= TYPE_PACKED_VECTOR4_ARRAY:
			out[n] = v.duplicate()     # v24: туман карты (PackedByteArray) делился по ссылке — новая игра видела старую карту
		else:
			out[n] = v
	return out


func _apply_vars(vars: Dictionary) -> void:
	var have: Dictionary = {}
	for p in Game.get_property_list():
		have[String((p as Dictionary)["name"])] = true
	for k in vars.keys():
		var n: String = String(k)
		if not have.has(n) or SKIP.has(n):
			continue
		var v: Variant = vars[k]
		var cur: Variant = Game.get(n)
		# тип должен совпасть (старый файл после обновления игры не должен ломать переменные)
		if cur != null and typeof(cur) != typeof(v):
			if typeof(cur) == TYPE_FLOAT and typeof(v) == TYPE_INT:
				v = float(v)
			elif typeof(cur) == TYPE_INT and typeof(v) == TYPE_FLOAT:
				v = int(v)
			else:
				continue
		if v is Dictionary or v is Array:
			Game.set(n, v.duplicate(true))
		elif typeof(v) >= TYPE_PACKED_BYTE_ARRAY and typeof(v) <= TYPE_PACKED_VECTOR4_ARRAY:
			Game.set(n, v.duplicate())
		else:
			Game.set(n, v)
	while Game.hotbar.size() < 9:     # старые сохранения: было 8 ячеек
		Game.hotbar.append("")


## «Новая игра»: Game как при запуске программы
func reset_game() -> void:
	_apply_vars(defaults)
	Game.explored = PackedByteArray()
	Game.hold = {}
	Game.ui_open = false
	Game.busy = false
	Game.time_frozen = false
	pending_world = {}
	loaded = false


# ------------------------------------------------------------------ запись и чтение

## Можно ли сейчас сохраняться (не в тюрьме, не в гостях, не под водой, не в шахте, не во время перехода)
func can_save() -> bool:
	var m: Node = get_tree().current_scene
	if m == null or not m.has_method("save_world") or Game.busy:
		return false
	return bool(m.call("can_save"))


func save_game(s: int = -1, show_icon: bool = true) -> bool:
	if s < 0:
		s = slot
	var m: Node = get_tree().current_scene
	if m == null or not m.has_method("save_world"):
		return false
	var data: Dictionary = {
		"v": VERSION,
		"game": game_vars(),
		"world": m.call("save_world"),
		"meta": {
			"day": Game.day, "coins": Game.coins, "scenario": Game.scenario, "home": Game.home_biome,
			"time": Time.get_datetime_string_from_system(false, true), "clock": Game.clock_text(),
		},
	}
	var tmp: String = path(s) + ".tmp"
	var f: FileAccess = FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		push_warning("Сохранение: не открыть %s" % tmp)
		return false
	f.store_string(var_to_str(data))
	f.close()
	var dir: DirAccess = DirAccess.open("user://")
	if dir.file_exists(path(s).get_file()):
		dir.remove(path(s).get_file())
	dir.rename(tmp.get_file(), path(s).get_file())
	slot = s
	t = 0.0
	if show_icon:
		icon_t = 1.6
	return true


func _read(s: int) -> Dictionary:
	if not FileAccess.file_exists(path(s)):
		return {}
	var txt: String = FileAccess.get_file_as_string(path(s))
	var v: Variant = str_to_var(txt)
	if not (v is Dictionary):
		return {}
	return v


## Загрузить слот: Game — сразу, мир — после перезапуска сцены (main._ready читает pending_world)
func load_game(s: int) -> bool:
	var d: Dictionary = _read(s)
	if d.is_empty():
		return false
	reset_game()
	_apply_vars(d.get("game", {}))
	pending_world = d.get("world", {})
	if pending_world.is_empty():
		pending_world = {"_": true}
	slot = s
	loaded = true
	Game.new_game_ready = false
	Game.ui_open = false
	get_tree().paused = false
	Sound.mode = "game"
	Sound.cur_track = ""
	get_tree().reload_current_scene()
	return true


## Только прочитать данные (автотест: сравнить с тем, что было)
func peek(s: int) -> Dictionary:
	return _read(s)


func delete_slot(s: int) -> void:
	# по правилам проекта файлы игрока не удаляются: старое сохранение уходит в .bak
	if not has_save(s):
		return
	var dir: DirAccess = DirAccess.open("user://")
	var bak: String = path(s).get_file() + ".%d.bak" % int(Time.get_unix_time_from_system())
	dir.rename(path(s).get_file(), bak)


# ------------------------------------------------------------------ настройки (громкость)

const SETTINGS: String = "user://settings.cfg"


func save_settings() -> void:
	var c: ConfigFile = ConfigFile.new()
	c.set_value("audio", "music", Sound.music_vol)
	c.set_value("audio", "sfx", Sound.sfx_vol)
	for k in opt:
		c.set_value("game", String(k), opt[k])
	for a in Game.keybinds:
		c.set_value("keys", String(a), int(Game.keybinds[a]))
	c.save(SETTINGS)


func load_settings() -> void:
	var c: ConfigFile = ConfigFile.new()
	if c.load(SETTINGS) == OK:
		Sound.music_vol = float(c.get_value("audio", "music", Sound.music_vol))
		Sound.sfx_vol = float(c.get_value("audio", "sfx", Sound.sfx_vol))
		for k in opt.keys():
			opt[k] = c.get_value("game", String(k), opt[k])
		Game.keybinds.clear()
		if c.has_section("keys"):
			for a in c.get_section_keys("keys"):
				Game.keybinds[a] = int(c.get_value("keys", a))
	apply_settings()


func defaults_opt() -> Dictionary:
	return opt_defaults


## Применить громкость, экран и т.п. (зовут при загрузке и из окна настроек)
func apply_settings() -> void:
	Sound.apply_volume()
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(float(opt.get("master", 1.0)), 0.0001)))
	if OS.get_cmdline_user_args().has("--test") or DisplayServer.get_name() == "headless":
		return
	var fs: bool = bool(opt.get("fullscreen", false))
	var want: int = DisplayServer.WINDOW_MODE_FULLSCREEN if fs else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != want and not (not fs and DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_MAXIMIZED):
		DisplayServer.window_set_mode(want)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if bool(opt.get("vsync", true)) else DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = int(opt.get("fps", 0))
	get_tree().root.content_scale_factor = float(opt.get("ui_scale", 1.0))
	_apply_bright()


func _apply_bright() -> void:
	var b: float = float(opt.get("brightness", 1.0))
	if bright == null:
		var cl: CanvasLayer = CanvasLayer.new()
		cl.layer = 120
		add_child(cl)
		bright = ColorRect.new()
		bright.set_anchors_preset(Control.PRESET_FULL_RECT)
		bright.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bright.material = CanvasItemMaterial.new()
		cl.add_child(bright)
	var m: CanvasItemMaterial = bright.material
	bright.visible = absf(b - 1.0) > 0.01
	if b < 1.0:
		m.blend_mode = CanvasItemMaterial.BLEND_MODE_MUL
		bright.color = Color(b, b, b)
	else:
		m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		var a: float = (b - 1.0) * 0.35
		bright.color = Color(a, a, a)


# ------------------------------------------------------------------ автосохранение

func _process(delta: float) -> void:
	if icon_t > 0.0:
		icon_t -= delta
		icon.modulate.a = clampf(minf(icon_t, 1.6 - icon_t) * 3.0, 0.0, 0.9)
		icon.rotation = sin(icon_t * 8.0) * 0.08
		icon.pivot_offset = icon.size / 2.0
	if OS.get_cmdline_user_args().has("--test") or get_tree().paused or Game.ui_open:
		return
	var m: Node = get_tree().current_scene
	if m == null or not m.has_method("save_world") or not bool(m.get("playing")):
		return
	t += delta
	var as_min: int = int(opt.get("autosave", 3))
	if as_min > 0 and t >= float(as_min) * 60.0 and can_save():
		save_game()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		quit_game()
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if bool(opt.get("mute_unfocus", false)):
			AudioServer.set_bus_mute(0, true)
		if bool(opt.get("pause_unfocus", true)) and not OS.get_cmdline_user_args().has("--test"):
			var mn: Node = get_tree().get_first_node_in_group("menu")
			if mn != null and not bool(mn.get("open")) and not Game.ui_open and not Game.busy:
				mn.call("show_menu")
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		AudioServer.set_bus_mute(0, false)


## Выход: сохранить (если идёт игра и можно) и закрыть
func quit_game() -> void:
	var m: Node = get_tree().current_scene
	if m != null and m.has_method("save_world") and bool(m.get("playing")) and can_save() and not OS.get_cmdline_user_args().has("--test"):
		save_game(-1, false)
	get_tree().quit()

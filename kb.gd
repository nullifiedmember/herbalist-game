class_name KB
extends RefCounted
## v24: горячие клавиши. Действие -> клавиша по умолчанию; свои клавиши игрока — Game.keybinds (сохраняются в
## настройках, saves.gd). Везде в коде вместо KEY_E писать KB.code("interact"), вместо проверки нажатия — KB.down("run").

## порядок — как в окне настроек: [действие, название, клавиша по умолчанию, запасная]
const ACTIONS: Array = [
	["move_up", "Идти вверх", KEY_W, KEY_UP],
	["move_down", "Идти вниз", KEY_S, KEY_DOWN],
	["move_left", "Идти влево", KEY_A, KEY_LEFT],
	["move_right", "Идти вправо", KEY_D, KEY_RIGHT],
	["run", "Бежать", KEY_SHIFT, KEY_NONE],
	["interact", "Действие / поговорить", KEY_E, KEY_NONE],
	["attack", "Удар", KEY_SPACE, KEY_NONE],
	["inventory", "Сумка", KEY_TAB, KEY_NONE],
	["craft", "Окно крафта", KEY_I, KEY_NONE],
	["book", "Книга травника", KEY_J, KEY_NONE],
	["map", "Карта", KEY_M, KEY_NONE],
	["quests", "Задания", KEY_Q, KEY_NONE],
	["kingdom", "Работники и королевство", KEY_O, KEY_NONE],
	["skills", "Навыки", KEY_K, KEY_NONE],
	["build", "Мебель и комнаты", KEY_B, KEY_NONE],
	["eat", "Съесть то, что в руке", KEY_F, KEY_NONE],
	["swap", "Сменить оружие", KEY_X, KEY_NONE],
	["potion", "Выпить зелье с пояса", KEY_Z, KEY_NONE],
	["chronicle", "Летопись", KEY_L, KEY_NONE],
	["lens", "Взгляд сквозь деревья", KEY_V, KEY_NONE],
	["spell_mode", "Книга сфер: режим заклинаний (сферы на 1-8)", KEY_C, KEY_NONE],
	["cast", "Произнести заклинание", KEY_R, KEY_NONE],
	["grimoire", "Гримуар: стихии и заклинания", KEY_H, KEY_NONE],
	["ride", "Сесть на скакуна / слезть", KEY_N, KEY_NONE],
	["move_home", "Переезд в другой край", KEY_P, KEY_NONE],
]

static var run_latched: bool = false      # бег «переключением»: нажал — бежишь, нажал ещё — идёшь


static func default_of(action: String) -> int:
	for a in ACTIONS:
		if String(a[0]) == action:
			return int(a[2])
	return KEY_NONE


static func alt_of(action: String) -> int:
	for a in ACTIONS:
		if String(a[0]) == action:
			return int(a[3])
	return KEY_NONE


## Основная клавиша действия (своя или по умолчанию)
static func code(action: String) -> int:
	return int(Game.keybinds.get(action, default_of(action)))


## Подходит ли нажатая клавиша под действие (основная или запасная)
static func is_key(action: String, keycode: int) -> bool:
	if keycode == KEY_NONE:
		return false
	if keycode == code(action):
		return true
	var alt: int = alt_of(action)
	return alt != KEY_NONE and keycode == alt and not Game.keybinds.values().has(alt)


## Событие — нажатие клавиши действия
static func pressed(action: String, event: InputEvent) -> bool:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return false
	return is_key(action, int((event as InputEventKey).physical_keycode))


## Клавиша действия зажата сейчас (бег в режиме «переключать» — включён ли)
static func down(action: String) -> bool:
	if action == "run" and bool(Saves.opt.get("run_toggle", false)):
		return run_latched
	if Input.is_physical_key_pressed(code(action) as Key):
		return true
	var alt: int = alt_of(action)
	return alt != KEY_NONE and Input.is_physical_key_pressed(alt as Key)


static func key_name(action: String) -> String:
	var c: int = code(action)
	if c == KEY_NONE:
		return "—"
	return OS.get_keycode_string(c as Key)


## Назначить клавишу. Если она уже занята другим действием — они меняются клавишами.
static func assign(action: String, keycode: int) -> void:
	var old: int = code(action)
	for a in ACTIONS:
		var other: String = String(a[0])
		if other != action and code(other) == keycode:
			Game.keybinds[other] = old
	if keycode == default_of(action):
		Game.keybinds.erase(action)
	else:
		Game.keybinds[action] = keycode
	for a2 in ACTIONS:   # убрать записи, совпавшие с умолчанием
		var n: String = String(a2[0])
		if Game.keybinds.has(n) and int(Game.keybinds[n]) == default_of(n):
			Game.keybinds.erase(n)


static func reset_all() -> void:
	Game.keybinds.clear()
	run_latched = false

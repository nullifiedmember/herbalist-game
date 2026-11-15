extends RefCounted
## v27: Обучение. У дома стоит девушка-гид (как гид в Террарии): рассказывает про основные механики.
## Подключается из dialog_ui.gd: start → menu, _choose → handles/handle. Она — catgirl.gd с метой "tutor".

const TEX: String = "catgirl_mira"
const NAME: String = "Мира, гид"

# темы: [id, пункт меню, текст (%s — клавиши подставляются)]
static func topics() -> Array:
	return [
		["move", "Как ходить и бегать?", "Ходи на %s, %s, %s, %s. Держи %s — побежишь, но быстрее устанешь. Усталость видно на шкале, отдыхай и спи в кровати." % [
			KB.key_name("move_up"), KB.key_name("move_left"), KB.key_name("move_down"), KB.key_name("move_right"), KB.key_name("run")]],
		["herbs", "Как собирать травы?", "Подойди к траве и нажми %s — откроется окно сбора. Тяни растение мышью вверх вместе с корешком или срежь ножом у самой земли. Неси в корзинку справа. Когда всё собрано, окно закроется само." % KB.key_name("interact")],
		["bag", "Сумка и пояс", "Сумка — %s, пояс — клавиши 1–8 или колесо мыши. Предмет в руке можно использовать правой кнопкой мыши. Еду ешь на %s." % [KB.key_name("inventory"), KB.key_name("eat")]],
		["brew", "Зелья и котёл", "Принеси воды, брось травы в котёл и вари. Рецепты открываются, когда изучаешь травы; окно крафта — %s, книга травника — %s." % [KB.key_name("craft"), KB.key_name("book")]],
		["sell", "Как заработать монеты?", "Варить зелья и продавать их жителям и торговцам, ловить рыбу, добывать камни и руды. Жители приходят к дому с заказами — отдай им нужное зелье."],
		["home", "Дом и мебель", "Мебель и комнаты — %s. Сундуки дома пригодятся для крафта. Спать — в кровати: время идёт, силы возвращаются, травы отрастают." % KB.key_name("build")],
		["world", "Мир, карта и задания", "Карта — %s (она открывается по мере прогулок), задания — %s, летопись — %s, навыки — %s. За пределами двора живут другие народы, у каждого свои дела." % [
			KB.key_name("map"), KB.key_name("quests"), KB.key_name("chronicle"), KB.key_name("skills")]],
		["animals", "Звери и птицы", "Зверей можно гладить (%s). Самка или самец — видно в подсказке. Птиц ловят сачком ради перьев. Некоторых зверей можно приручить и ездить верхом (%s)." % [KB.key_name("interact"), KB.key_name("ride")]],
		["save", "Сохранение и настройки", "Esc — меню: там сохранение, настройки, полный экран и разрешение окна. Игра сама сохраняется, как настроено."],
	]


static func greeting() -> String:
	return "Привет, я Мира! Я здесь, чтобы помочь освоиться. Про что рассказать?"


static func menu(d: Node) -> void:
	d.call("_say", greeting())
	d.call("_set_options", options())


static func options() -> Array:
	var o: Array = []
	# v28: обучение как задание
	if Game.tut_step == 0:
		o.append(["Научи меня! (задание)", "tut:quest"])
	elif Game.tut_step < 99:
		o.append(["Напомни, что делать", "tut:quest"])
	for t in topics():
		o.append([String(t[1]), "tut:" + String(t[0])])
	o.append(["Пока!", "bye"])
	return o


static func handles(act: String) -> bool:
	return act.begins_with("tut:")


static func handle(d: Node, act: String) -> void:
	var id: String = act.substr(4)
	if id == "quest":
		if Game.tut_step == 0:
			Game.tut_step = 1
			Sound.play("page", -6.0)
			Game.toast.emit("Задание получено: Дровосек", null)
			d.call("_say", "Первое дело — дрова! Из брёвен выйдут верстак и всё остальное. Задание появилось слева на экране: я подсвечиваю, что делать, и стрелкой показываю дерево. Топор не забудь взять в руку!")
		else:
			d.call("_say", "Смотри на задание слева: жёлтая строчка — то, что делать сейчас. Дерево, которое нужно рубить, отмечено стрелкой.")
		d.call("_set_options", options())
		return
	for t in topics():
		if String(t[0]) == id:
			d.call("_say", String(t[2]))
			d.call("_set_options", options())
			return

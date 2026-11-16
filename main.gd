extends Node2D
## Лесной травник — сборка мира: земля, дом, огород, лес, свет, частицы, интерфейс.

const LAY = preload("res://world_layout.gd")
const DB = preload("res://herbs_db.gd")
const WIND = preload("res://wind.gdshader")

const FOOT: Dictionary = {
	"tree_a": 152, "tree_b": 160, "tree_c": 144, "tree_d": 180, "pine_a": 149, "pine_b": 125,
	"tree_blossom": 152, "tree_autumn": 148, "tree_apple": 142,
	"bush_a": 42, "bush_b": 42, "bush_c": 42,
	"flowers_pink": 26, "flowers_white": 26, "flowers_blue": 26, "flowers_yellow": 26,
	"house": 236, "well": 92, "lantern": 82, "fence": 36, "pillar": 82, "bench": 42,
	"tea_table": 56, "barrel": 43, "sign": 62, "rock": 36, "rock_big": 47, "mushrooms": 27, "stump": 31,
	"cauldron": 56, "outhouse": 78,
}
const RDB = preload("res://recipes_db.gd")
const FD = preload("res://fish_db.gd")
const WD = preload("res://world_data.gd")
const SCN = preload("res://scenarios_db.gd")
const IT = preload("res://items_db.gd")
const IN_ORG: Vector2 = Vector2(30000, 0)
const ROOM_ORG: Vector2 = Vector2(60000, 0)       # комната чужого дома (одна на все дома, меняется хозяйка)         # где в мире лежит комната дома (далеко от улицы)
const IN_WAKE: Vector2 = Vector2(370, 224)       # утром встаёт у кровати
const IN_DOOR_IN: Vector2 = Vector2(320, 262)    # у двери внутри
const CAULDRON_POS: Vector2 = Vector2(1156, 446)
const VISIT_POS: Vector2 = Vector2(992, 650)

# цвет мира по часам: [час, цвет]
const SKY: Array = [
	[0.0, Color(0.40, 0.44, 0.74)],
	[5.0, Color(0.44, 0.47, 0.76)],
	[6.0, Color(0.96, 0.74, 0.76)],
	[7.0, Color(1.0, 0.88, 0.80)],
	[8.5, Color(1.0, 0.97, 0.91)],
	[15.5, Color(1.0, 0.98, 0.92)],
	[17.3, Color(1.0, 0.88, 0.72)],
	[18.6, Color(1.0, 0.77, 0.64)],
	[19.6, Color(0.93, 0.66, 0.74)],
	[20.6, Color(0.68, 0.59, 0.85)],
	[21.8, Color(0.47, 0.49, 0.79)],
	[24.0, Color(0.40, 0.44, 0.74)],
]
const SHADOW_SHADER = preload("res://shadow.gdshader")
const GRADE_SHADER = preload("res://grade.gdshader")
const CHAR_LIGHT = preload("res://char_light.gdshader")

var objects: Node2D
var fx_layer: CanvasLayer
var canvas_mod: CanvasModulate
var player: Node2D
var cam: Camera2D
var zoom_target: float = 3.0      # приближение камеры колёсиком мыши
const ZOOM_MIN: float = 2.0
const ZOOM_MAX: float = 9.0
const ZOOM_STEP: float = 0.25
var hud: CanvasLayer
var book: CanvasLayer
var arrow: Sprite2D
var glows: Array = []            # [Sprite2D, сила]
var fireflies: CPUParticles2D
var leaves: CPUParticles2D
var smoke: CPUParticles2D
var block_rects: Array = []
var block_circles: Array = []
var placed: Array = []           # занятые точки декора (Vector3 x, y, r)
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var t_arrow: float = 0.0
var shadow_group: CanvasGroup
var shadow_mat: ShaderMaterial
var casters_static: Array = []   # [источник, тень]
var casters_dyn: Array = []
var rays: TextureRect
var grade_mat: ShaderMaterial
var wind_layers: Array = []       # [спрайт героя, слой] — кадр слоя = кадр спрайта
var char_mats: Array = []        # солнце на персонажах
var char_targets: Array = []     # [спрайт, материал] — на них падают тени
var img_cache: Dictionary = {}
var sun_cache: Vector3 = Vector3(-99, -99, -99)
var shade_t: float = 0.0          # тени на персонажах считаются не каждый кадр
const SHADE_BUDGET: int = 5       # сколько персонажей пересчитывать за один проход
var shade_pos: Dictionary = {}    # спрайт -> где стоял при последнем расчёте тени
var shade_basis: Vector2 = Vector2(-9, -9)
var shade_kk: float = -9.0
var sun_t2: float = 0.0
var sun_key: Vector4 = Vector4(-9, -9, -9, -9)
var brew_ui: CanvasLayer
var fishing_ui: CanvasLayer
var inside: bool = false                         # героиня в доме
var in_blocks: Array = []
var in_glows: Array = []                         # тёплые пятна света в доме: [спрайт, днём, ночью, мерцание]
var in_beam: Node2D                              # луч из окна с пылинками (только днём)
var in_rays: Array = []                          # отдельные солнечные лучи (мерцают)                        # занятые места в комнатах (локальные координаты)
var wardrobe_spr: Sprite2D
var messes: Array = []                           # лужи и кучки после конфуза (живут, пока не высохнут или не уберут)
var mop_stand: Node2D
var insects: Node                                # насекомые мира
var flower_spots: Array = []                      # где растут цветы (к ним летят бабочки и пчёлы)
var lantern_spots: Array = []                     # где светят фонари (к ним летят мотыльки)
var net_stand: Node2D
var net_spr: Sprite2D                             # сачок в руках героини
var mop_spr: Sprite2D                             # швабра в руках героини
const PEOPLE_R: float = 350.0                    # так близко люди — уже «при людях»
var bushes: Array = []          # [спрайт, точка] — сквозь кусты можно идти, но медленнее
var bush_shake: Dictionary = {}
var bush_fx_t: float = 0.0
var last_order_day: int = 0
var world: Node2D                  # большой открытый мир вокруг двора (world.gd)
var map_ui: CanvasLayer            # карта на M
var jail_msg_ms: int = 0
var visiting: Node2D = null            # дверь дома, в котором героиня в гостях
var visit_t: float = 0.0
var visit_warned: int = 0
var guest_stay: bool = false           # героиня ночевала в этом доме — хозяйка больше не гонит
var room_blocks: Array = []
var room_props: Array = []
var yard_trees: Array = []          # деревья двора (их можно срубить)
var classic_yard: bool = false      # старый двор со всеми постройками (для автотеста и --classic)
var homestead: Node
var sea: Node                       # пирс, колокол и подводный город (sea.gd)
var live: Node                      # клуб «Старлит» (livehouse.gd)
var mine: Node                      # v19: шахта под пещерами (mine.gd)
var room_floor: Sprite2D
var room_owner: Node2D = null
var room_guard: Node2D = null
var biome_tint: Color = Color(1, 1, 1)   # оттенок света края, где стоит героиня
var playing: bool = false                # игра идёт (не главное меню при запуске) — можно автосохраняться
var paths: Node                          # ранний доступ: свои пути (paths.gd)
var guide: Node                          # ранний доступ: первые шаги картинками (guide.gd)


func _ready() -> void:
	rng.seed = 2024
	# проверка картинкой: --scen=alchemist --spawn=birch — как будто так выбрано в новой игре
	for a0 in OS.get_cmdline_user_args():
		var s0: String = String(a0)
		if s0.begins_with("--scen="):
			Game.scenario = s0.substr(7)
			Game.new_game_ready = true
		elif s0.begins_with("--spawn="):
			Game.home_biome = s0.substr(8)
			Game.home_pos = SCN.find_home(Game.home_biome)
			Game.new_game_ready = true
	_build_ground()
	shadow_group = CanvasGroup.new()
	shadow_group.z_index = -9   # мостовые и круги на земле — ниже (-10), иначе закрывают тени
	add_child(shadow_group)
	shadow_mat = ShaderMaterial.new()
	shadow_mat.shader = SHADOW_SHADER
	objects = Node2D.new()
	objects.y_sort_enabled = true
	add_child(objects)
	world = Node2D.new()
	world.set_script(load("res://world.gd"))
	add_child(world)
	world.call("setup", self)
	var cv: Node = Node.new()
	cv.set_script(load("res://cat_village.gd"))
	cv.name = "CatVillage"
	add_child(cv)
	cv.call("setup", self, world)
	var sf: Node = Node.new()
	sf.set_script(load("res://spider_forest.gd"))
	sf.name = "SpiderForest"
	add_child(sf)
	sf.call("setup", self, world)
	var gt: Node = Node.new()
	gt.set_script(load("res://gothic.gd"))
	gt.name = "Gothic"
	add_child(gt)
	gt.call("setup", self, world)
	var kn: Node = Node.new()
	kn.set_script(load("res://knights.gd"))
	kn.name = "Knights"
	add_child(kn)
	kn.call("setup", self, world)
	var el: Node = Node.new()
	el.set_script(load("res://elves.gd"))
	el.name = "Elves"
	add_child(el)
	el.call("setup", self, world)
	var mg: Node = Node.new()
	mg.set_script(load("res://mages.gd"))
	mg.name = "Mages"
	add_child(mg)
	mg.call("setup", self, world)
	var oc: Node = Node.new()
	oc.set_script(load("res://orcs.gd"))
	oc.name = "Orcs"
	add_child(oc)
	oc.call("setup", self, world)
	var dw: Node = Node.new()
	dw.set_script(load("res://dwarves.gd"))
	dw.name = "Dwarves"
	add_child(dw)
	dw.call("setup", self, world)
	var wl: Node = Node.new()
	wl.set_script(load("res://wilds.gd"))
	wl.name = "Wilds"
	add_child(wl)
	wl.call("setup", self, world)
	# v26: бродячие коты разных окрасов и котята
	var sc26: Node = Node.new()
	sc26.set_script(load("res://stray_cats26.gd"))
	sc26.name = "StrayCats26"
	add_child(sc26)
	sc26.call("setup", self, world)
	var rk: Node2D = Node2D.new()
	rk.set_script(load("res://rocks.gd"))
	rk.name = "Rocks"
	add_child(rk)
	rk.call("setup", self, world)
	# v20: места добычи материалов (глина, песок, лён, улья, ракушки...)
	var nd20: Node = Node.new()
	nd20.set_script(load("res://nodes20.gd"))
	nd20.name = "Nodes20"
	add_child(nd20)
	nd20.call("setup", self, world)
	var tw: Node = Node.new()
	tw.set_script(load("res://towns.gd"))
	tw.name = "Towns"
	add_child(tw)
	tw.call("setup", self, world)
	# v25: Эквестрия — места вокруг Понивилля (ферма, коттедж, библиотека, Кантерлот...)
	var pn25: Node = Node.new()
	pn25.set_script(load("res://pony25.gd"))
	pn25.name = "Pony25"
	add_child(pn25)
	pn25.call("setup", self, world)
	# в новой игре во дворе только дом и немного украшений — остальное героиня строит сама
	classic_yard = OS.get_cmdline_user_args().has("--test") or OS.get_cmdline_user_args().has("--classic")
	_build_house_area()
	if classic_yard:
		_build_garden()
		_build_well_and_fence()
	_build_fishing()
	_build_interior()
	_build_guest_room()
	if classic_yard and Game.TOILET_ENABLED:
		_build_outhouse()
	_build_consumables()
	_build_forest()
	_build_decor()
	_spawn_herbs()
	_build_creatures()
	_build_player()
	_build_fx()
	canvas_mod = CanvasModulate.new()
	add_child(canvas_mod)
	hud = CanvasLayer.new()
	hud.set_script(load("res://hud.gd"))
	hud.add_to_group("hud")
	add_child(hud)
	map_ui = CanvasLayer.new()
	map_ui.set_script(load("res://map_ui.gd"))
	add_child(map_ui)
	map_ui.call("setup", self, world)
	var dlg: CanvasLayer = CanvasLayer.new()
	dlg.set_script(load("res://dialog_ui.gd"))
	dlg.add_to_group("dialog_ui")
	add_child(dlg)
	dlg.call("setup", hud)
	var shelf_ui: CanvasLayer = CanvasLayer.new()
	shelf_ui.set_script(load("res://shelf_ui.gd"))
	add_child(shelf_ui)
	shelf_ui.call("setup", hud)
	book = CanvasLayer.new()
	book.set_script(load("res://book.gd"))
	add_child(book)
	brew_ui = CanvasLayer.new()
	brew_ui.set_script(load("res://brew.gd"))
	brew_ui.add_to_group("brew_ui")
	add_child(brew_ui)
	var hv: CanvasLayer = CanvasLayer.new()
	hv.set_script(load("res://harvest_ui.gd"))
	add_child(hv)
	var dry_win: CanvasLayer = CanvasLayer.new()
	dry_win.set_script(load("res://dry_ui.gd"))
	dry_win.name = "DryUI"
	add_child(dry_win)
	var recruit_node: Node = Node.new()
	recruit_node.set_script(load("res://recruit.gd"))
	add_child(recruit_node)
	var tree_win: CanvasLayer = CanvasLayer.new()
	tree_win.set_script(load("res://tree_ui.gd"))
	add_child(tree_win)
	insects = Node.new()
	insects.set_script(load("res://insects.gd"))
	add_child(insects)
	insects.call("setup", self)
	# v20: птицы и совы вокруг героини (поют каждая со своей стороны)
	var birds_n: Node = Node.new()
	birds_n.set_script(load("res://birds.gd"))
	birds_n.name = "Birds"
	add_child(birds_n)
	birds_n.call("setup", self, world)
	fishing_ui = CanvasLayer.new()
	fishing_ui.set_script(load("res://fishing_ui.gd"))
	fishing_ui.add_to_group("fishing_ui")
	add_child(fishing_ui)
	# v18: закон и тюрьмы, задания, журнал заданий, кот-спутник
	var law_n: Node = Node.new()
	law_n.set_script(load("res://law.gd"))
	law_n.name = "Law"
	add_child(law_n)
	law_n.call("setup", self)
	var shelter_n: Node = Node.new()
	shelter_n.set_script(load("res://shelter.gd"))
	shelter_n.name = "Shelters"
	add_child(shelter_n)
	shelter_n.call("setup", self)
	var quests_n: Node = Node.new()
	quests_n.set_script(load("res://quests.gd"))
	quests_n.name = "Quests"
	add_child(quests_n)
	quests_n.call("setup", self)
	var quest_win: CanvasLayer = CanvasLayer.new()
	quest_win.set_script(load("res://quest_ui.gd"))
	quest_win.name = "QuestUI"
	add_child(quest_win)
	quest_win.call("setup", hud)
	var places: CanvasLayer = CanvasLayer.new()
	places.set_script(load("res://places.gd"))
	add_child(places)
	places.call("setup", self)
	homestead = Node.new()
	homestead.set_script(load("res://homestead.gd"))
	homestead.add_to_group("homestead")
	add_child(homestead)
	var from_save: Dictionary = Saves.pending_world
	if not classic_yard and from_save.is_empty():
		Game.inventory["axe"] = 1
	if Game.new_game_ready and from_save.is_empty():
		_apply_scenario()
	homestead.call("setup", self, hud, world)
	if not from_save.is_empty():
		_load_world_early(from_save)
	if not classic_yard and not bool(homestead.call("has_built", "well")):
		# колодец у дома есть с самого начала — из него набирают воду в бутылочки
		homestead.call("build", "well", LAY.HOUSE_POS + home_off() + Vector2(190, 70))
	var inv: CanvasLayer = CanvasLayer.new()
	inv.set_script(load("res://inventory_ui.gd"))
	inv.name = "InventoryUI"
	inv.add_to_group("inventory_ui")
	add_child(inv)
	inv.call("setup", self, hud)
	sea = Node.new()
	sea.set_script(load("res://sea.gd"))
	sea.name = "Sea"
	add_child(sea)
	sea.call("setup", self, world)
	live = Node.new()
	live.set_script(load("res://livehouse.gd"))
	live.name = "LiveHouse"
	add_child(live)
	live.call("setup", self, world)
	mine = Node.new()
	mine.set_script(load("res://mine.gd"))
	mine.name = "Mine"
	add_child(mine)
	mine.call("setup", self, world)
	paths = Node.new()
	paths.set_script(load("res://paths.gd"))
	add_child(paths)
	paths.call("setup", self, hud)
	guide = Node2D.new()
	guide.set_script(load("res://guide.gd"))
	guide.name = "Guide"
	add_child(guide)
	guide.call("setup", self)
	var v22: Node = Node.new()
	v22.set_script(load("res://v22.gd"))
	v22.name = "V22"
	add_child(v22)
	v22.call("setup", self, hud)
	# v23: дом с мебелью и комнатами, сундук как в PoE, бой, работники, королевство, ферма, подземелья, море
	var h23: Node = Node.new()
	h23.set_script(load("res://house23.gd"))
	h23.name = "House23"
	add_child(h23)
	h23.call("setup", self)
	var v23: Node = Node.new()
	v23.set_script(load("res://v23.gd"))
	v23.name = "V23"
	add_child(v23)
	v23.call("setup", self, hud)
	# v24: падающие деревья и стволы, настоящие работницы, сундуки по назначению, дома королевства
	var v24: Node = Node.new()
	v24.set_script(load("res://v24.gd"))
	v24.name = "V24"
	add_child(v24)
	v24.call("setup", self, hud)
	# v24: Ад и Рай — свои миры за порталами
	var rl: Node = Node.new()
	rl.set_script(load("res://realm24.gd"))
	rl.name = "Realm24"
	add_child(rl)
	rl.call("setup", self)
	# v25: книга сфер, скакуны, облик зверя, переезд
	var v25: Node = Node.new()
	v25.set_script(load("res://v25.gd"))
	v25.name = "V25"
	add_child(v25)
	v25.call("setup", self, hud)
	# v26: магазины королевства — покупатели приходят сами
	var s26: Node = Node.new()
	s26.set_script(load("res://shops26.gd"))
	add_child(s26)
	s26.call("setup", self)
	# v29: задний двор с грядками и грибными деревьями, погода с дождём
	var by29: Node = Node.new()
	by29.set_script(load("res://backyard29.gd"))
	by29.name = "Backyard29"
	add_child(by29)
	by29.call("setup", self, hud)
	var wx29: Node2D = Node2D.new()
	wx29.set_script(load("res://weather29.gd"))
	wx29.name = "Weather29"
	add_child(wx29)
	wx29.call("setup", self, hud)
	if not from_save.is_empty():
		_load_world_late(from_save)
		Saves.pending_world = {}
	player.connect("target_changed", _on_target_changed)
	Game.sleep_requested.connect(_on_sleep)
	Game.midnight.connect(func() -> void:
		_spawn_herbs()
		hud.call("show_toast", "Наступил день %d" % Game.day, load("res://art/ui_moon.png")))
	Game.accident.connect(_on_accident)
	Game.fx.connect(_on_fx)
	_update_light()
	var shot: String = ""
	var test: bool = false
	for a in OS.get_cmdline_user_args():
		var s: String = String(a)
		if s.begins_with("--shot="):
			shot = s.substr(7)
		elif s == "--test":
			test = true
	var perfk: String = ""
	for a2 in OS.get_cmdline_user_args():
		if String(a2).begins_with("--perfk="):
			perfk = String(a2).substr(8)
	if perfk != "":
		var pk: Node = Node.new()
		pk.set_script(load("res://perfk.gd"))
		add_child(pk)
		pk.call("start", self, int(perfk))
	if OS.get_cmdline_user_args().has("--loadtest"):
		_loadtest()
	elif test:
		_run_tests()
	elif shot != "":
		_screenshot_mode(shot)
	else:
		_place_window()
		var mn: CanvasLayer = CanvasLayer.new()
		mn.set_script(load("res://menu.gd"))
		mn.add_to_group("menu")
		add_child(mn)
		mn.call("setup", hud)
		if Saves.loaded:
			mn.set("started", true)
			playing = true
			Saves.loaded = false
			Sound.mode = "game"
		elif Game.new_game_ready:
			# сценарий и место уже выбраны — сразу в игру
			mn.set("started", true)
			playing = true
			Game.chron("Начало пути: %s. Дом — %s." % [String(SCN.get_s(Game.scenario)["name"]), String((SCN.SPAWNS.get(Game.home_biome, {}) as Dictionary).get("name", ""))], "start")
			Game.new_game_ready = false
			Saves.save_game(-1, false)
			hud.call("show_toast", String(SCN.get_s(Game.scenario)["name"]) + " · " + String((SCN.SPAWNS.get(Game.home_biome, {}) as Dictionary).get("name", "")), IT.icon(String(SCN.get_s(Game.scenario)["icon"]).substr(5)))
		else:
			mn.call("show_menu")
	if not test and shot == "" and not OS.get_cmdline_user_args().has("--loadtest"):
		_spawn_tutor()
	if OS.get_cmdline_user_args().has("--autoplay"):
		# автоигра: бот сам играет на ускорении и пишет сохранение (autoplay.gd)
		var ap: Node = Node.new()
		ap.set_script(load("res://autoplay.gd"))
		ap.name = "Autoplay"
		add_child(ap)
		ap.call("start", self)


## v27: девушка-гид у дома (обучение, tutor27.gd)
func _spawn_tutor() -> void:
	var at: Vector2 = LAY.DOOR_POS + home_off() + Vector2(-110, 44)
	var g: Node2D = _room_npc(String(preload("res://tutor27.gd").TEX), at)
	g.set_meta("tutor", true)
	g.set("job", "post")
	g.set("role", "житель")
	g.set("roam", 24.0)
	g.set("npc_name", "Мира, гид")


## Новая игра: что надето, что в сумке, монеты и семена — по выбранному сценарию
func _apply_scenario() -> void:
	var sc: Dictionary = SCN.get_s(Game.scenario)
	Game.inventory.clear()
	Game.equip.clear()
	Game.hotbar = ["", "", "", "", "", "", "", "", ""]
	Game.coins = int(sc["coins"])
	Game.seeds = (sc["seeds"] as Dictionary).duplicate()
	var wear: Dictionary = sc["wear"]
	for slot in wear.keys():
		Game.equip[String(slot)] = String(wear[slot])
	var items: Dictionary = sc["items"]
	var hi: int = 0
	for id in items.keys():
		Game.inventory[String(id)] = int(items[id])
		var sid: String = String(id)
		if hi < 9 and (sid.begins_with("kit:") or String(IT.gear(sid).get("slot", "")) == "tool"):
			Game.hotbar[hi] = sid
			hi += 1
	# у каждой травницы с собой пара пустых бутылочек
	Game.inventory["bottle"] = int(Game.inventory.get("bottle", 0)) + 3
	# v24: факел с самого начала (его берут во вторую руку); у кого фонарь — тому не нужен
	if not items.has("lantern_hand"):
		Game.inventory["torch"] = int(Game.inventory.get("torch", 0)) + 1
	if sc.has("recipes"):
		var rc: Dictionary = sc["recipes"]
		for k in rc.keys():
			Game.known_recipes[String(k)] = rc[k]
	if Game.scenario == "scholar":
		for h in DB.DATA.keys():
			Game.researched[String(h)] = true
	Game.inventory_changed.emit()
	Game.equip_changed.emit()


## Окно игры: на основной монитор, по центру, чтобы влезало вместе с заголовком
func _place_window() -> void:
	if DisplayServer.get_name() == "headless":
		return
	# v27: полный экран, включённый в настройках, не сбрасывается при старте новой игры
	if bool(Saves.opt.get("fullscreen", false)):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		return
	var scr: int = DisplayServer.get_primary_screen()
	var area: Rect2i = DisplayServer.screen_get_usable_rect(scr)
	var w: int = mini(1600, int(area.size.x * 0.9))
	var h: int = int(w * 9.0 / 16.0)
	if h > int(area.size.y * 0.88):
		h = int(area.size.y * 0.88)
		w = int(h * 16.0 / 9.0)
	var rs: int = int(Saves.opt.get("res", 0))
	if rs > 0:
		w = rs
		h = int(rs * 9.0 / 16.0)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_current_screen(scr)
	DisplayServer.window_set_size(Vector2i(w, h))
	DisplayServer.window_set_position(area.position + (area.size - Vector2i(w, h)) / 2)


# ------------------------------------------------------------------ постройка

## Тень от солнца для спрайта: копия силуэта, лежащая на земле
func add_caster(src: Sprite2D, dynamic: bool = false) -> void:
	var sh: Sprite2D = Sprite2D.new()
	sh.material = shadow_mat
	sh.centered = false
	shadow_group.add_child(sh)
	_copy_look(src, sh)
	if dynamic:
		casters_dyn.append([src, sh])
	else:
		casters_static.append([src, sh])
	sun_cache = Vector3(-99, -99, -99)


func _copy_look(src: Sprite2D, sh: Sprite2D) -> void:
	sh.texture = src.texture
	if sh.hframes != src.hframes:
		sh.frame = 0      # лист сменился (зверь пошёл вниз/вверх) — сначала сброс кадра
	sh.hframes = src.hframes
	sh.vframes = src.vframes
	sh.frame = src.frame
	sh.offset = src.offset
	sh.flip_h = src.flip_h
	sh.centered = src.centered


var wind_mats: Dictionary = {}


## Общий материал ветра (фаза качания берётся из места спрайта) — спрайты рисуются пачками
func wind_mat(strength: float) -> ShaderMaterial:
	var k: float = snappedf(strength, 0.1)
	if not wind_mats.has(k):
		var m: ShaderMaterial = ShaderMaterial.new()
		m.shader = WIND
		m.set_shader_parameter("strength", k)
		wind_mats[k] = m
	return wind_mats[k]


func spr(tex: String, pos: Vector2, wind: float = 0.0, flip: bool = false, parent: Node = null, cast: bool = true) -> Sprite2D:
	var s: Sprite2D = Sprite2D.new()
	var t: Texture2D = load("res://art/%s.png" % tex)
	s.texture = t
	s.centered = false
	s.offset = Vector2(-floorf(t.get_width() / 2.0), -float(FOOT.get(tex, t.get_height())))
	s.position = pos.round()
	s.flip_h = flip
	if preload("res://mats_db.gd").SHRINK.has(tex):
		s.scale = Vector2.ONE * float(preload("res://mats_db.gd").SHRINK[tex])
	if wind > 0.0:
		s.material = wind_mat(wind)
	(parent if parent != null else objects).add_child(s)
	# v27b: низкие луговые цветы и грибы — без падающей тени-силуэта (торчала серыми пятнами по бокам), им хватает лунки
	if cast and not (tex.begins_with("flowers_") or tex == "mushrooms"):
		add_caster(s)
	# v24: постройки и высокие вещи — в сетку крон/крыш мира, чтобы травы на них не росли
	if cast and world != null and t.get_height() >= 80:
		world.call("register_tall", s)
	# v25: заборы и плетни — насесты для птиц
	if tex.contains("fence") or tex.contains("wicker") or tex.contains("palisade") or tex.contains("railing"):
		s.add_to_group("perch_fence")
	# v27: луговые цветы и грибы растут из земли биома (тень-лунка, травинки в цвет земли)
	if tex.begins_with("flowers_") or tex == "mushrooms":
		preload("res://plant_ground27.gd").attach(s, s.position, 0.08)
	return s


## Куст под ногами: индекс или -1 (след куста на земле — овал)
func bush_at(p: Vector2) -> int:
	for i in range(bushes.size()):
		var bp: Vector2 = bushes[i][1]
		var dx: float = (p.x - bp.x) / 25.0
		var dy: float = (p.y - (bp.y - 5.0)) / 11.0
		if dx * dx + dy * dy <= 1.0:
			return i
	return -1


## Куст шелестит и качается, пока сквозь него идёт героиня; из него летят листики
func _update_bushes(delta: float) -> void:
	var moving: bool = (player.get("vel") as Vector2).length() > 6.0
	var bi: int = bush_at(player.position)
	if bi >= 0 and moving:
		bush_shake[bi] = 1.0
		bush_fx_t -= delta
		if bush_fx_t <= 0.0:
			bush_fx_t = 0.35
			Game.fx.emit(player.position + Vector2(randf_range(-8, 8), -10), "leaves")
	for k in bush_shake.keys():
		var s: float = maxf(0.0, float(bush_shake[k]) - delta * 1.4)
		var sp: Sprite2D = bushes[int(k)][0]
		var mat: ShaderMaterial = sp.material as ShaderMaterial
		if mat != null:
			mat.set_shader_parameter("strength", 0.6 + s * 2.6)
		if s <= 0.0:
			bush_shake.erase(k)
		else:
			bush_shake[k] = s


func block_circle(p: Vector2, r: float) -> void:
	block_circles.append(Vector3(p.x, p.y, r))


## Внутри дома: стены, перегородка с проёмом, мебель. l — локальные координаты комнаты.
func _in_blocked(l: Vector2) -> bool:
	var h23: Node = get_node_or_null("House23")
	if h23 != null:
		return bool(h23.call("blocked", l))
	if l.y < 150.0 or l.y > 300.0 or l.x < 232.0 or l.x > 408.0:
		return true
	if l.y > 278.0 and (l.x < 306.0 or l.x > 334.0):
		return true
	for r in in_blocks:
		if (r as Rect2).has_point(l):
			return true
	return false


## Безопасно читает флаг: если у объекта нет такого поля — false (bool(null) падает)
func _flag(o: Object, prop: String) -> bool:
	if o == null:
		return false
	var v: Variant = o.get(prop)
	return v != null and bool(v)


func is_blocked(p: Vector2) -> bool:
	if p.y < -150000.0:
		var rl: Node = get_node_or_null("Realm24")
		return rl == null or bool(rl.call("is_blocked", p))     # v24: Ад и Рай
	if p.x > 150000.0:
		var dn: Node = get_node_or_null("V23/Dungeon23")
		return dn == null or bool(dn.call("is_blocked", p))     # v23: подземелья
	if visiting != null:
		var l: Vector2 = p - ROOM_ORG
		if l.y < 150.0 or l.y > 300.0 or l.x < 232.0 or l.x > 408.0:
			return true
		if l.y > 278.0 and (l.x < 306.0 or l.x > 334.0):
			return true
		for r in room_blocks:
			if (r as Rect2).has_point(l):
				return true
		return false
	if inside:
		return _in_blocked(p - IN_ORG)
	if p.x > 80000.0 and p.x < 120000.0 and absf(p.y) < 5000.0:
		var by29: Node = get_node_or_null("Backyard29")
		return by29 == null or bool(by29.call("is_blocked", p))     # v29: задний двор
	if p.y > 120000.0 and mine != null:
		return bool(mine.call("is_blocked", p))
	if p.x < -50000.0 and live != null:
		return bool(live.call("is_blocked", p))
	if p.y > 90000.0 and sea != null:
		return bool(sea.call("is_blocked", p))
	if not Rect2(0, 0, LAY.W, LAY.H).has_point(p):
		return bool(world.call("is_blocked", p))
	if classic_yard and not LAY.WALK_RECT.has_point(p) and not _in_exit(p):
		return true     # v29: в новой игре двор открыт со всех сторон (был невидимый барьер у дома)
	if LAY.pond_value(p) < 0.06:
		return true
	for r in block_rects:
		if (r as Rect2).has_point(p):
			return true
	for c in block_circles:
		var cv: Vector3 = c
		if p.distance_squared_to(Vector2(cv.x, cv.y)) < cv.z * cv.z:
			return true
	return false


## Выходы со двора в большой мир: на юг (к кошкодевочкам) и на запад (к паутинному лесу)
func _in_exit(p: Vector2) -> bool:
	return Rect2(140, 1170, 1640, 120).has_point(p) or Rect2(-10, 578, 160, 38).has_point(p)


func _world_limits() -> void:
	# v28: в Аду и Раю после выхода из дома камера должна вернуться в границы города-мира, а не большого мира (иначе картинка сходила с ума)
	var rl28: Node = get_node_or_null("Realm24")
	if rl28 != null and String(rl28.get("active")) != "":
		rl28.call("_cam")
		return
	cam.limit_left = int(WD.ORIGIN.x)
	cam.limit_top = int(WD.ORIGIN.y)
	cam.limit_right = int(WD.ORIGIN.x + WD.SIZE.x)
	cam.limit_bottom = int(WD.ORIGIN.y + WD.SIZE.y)


func free_spot(p: Vector2, r: float) -> bool:
	for q in placed:
		var qv: Vector3 = q
		if p.distance_to(Vector2(qv.x, qv.y)) < r + qv.z:
			return false
	return true


func mark(p: Vector2, r: float) -> void:
	placed.append(Vector3(p.x, p.y, r))


func _build_ground() -> void:
	var g: Sprite2D = Sprite2D.new()
	g.texture = load("res://art/ground.png")
	g.centered = false
	g.z_index = -10
	add_child(g)


## Сдвиг дома от старого двора: дом стоит там, где выбран биом в новой игре
func home_off() -> Vector2:
	return (Game.home_pos - LAY.HOUSE_POS).round()


func home_in_yard() -> bool:
	return home_off() == Vector2.ZERO


## Преграда у дома: во дворе — свои списки, в большом мире — сетка мира
func _home_rect(r: Rect2) -> void:
	if home_in_yard():
		block_rects.append(r)
	else:
		world.call("add_block_rect", Rect2(r.position + home_off(), r.size))


func _home_circle(p: Vector2, r: float) -> void:
	if home_in_yard():
		block_circle(p, r)
	else:
		world.call("add_block", p + home_off(), r)


func _build_house_area() -> void:
	var ho: Vector2 = home_off()
	if not home_in_yard():
		# поляна вокруг дома: деревья и кусты мира тут не растут
		world.call("reserve", Rect2(Game.home_pos + Vector2(-460, -330), Vector2(920, 720)))
		# v30: огород справа от дома (backyard29.gd) — тоже без леса
		world.call("reserve", yard30_rect())
	# точка сортировки дома — у низа стены, чтобы героиня вплотную к стене была перед домом
	var hs: Sprite2D = spr("house", LAY.HOUSE_POS + ho, 0.0, false, null, false)
	hs.position.y -= 10.0
	hs.offset.y += 10.0
	add_caster(hs)
	if world != null:
		world.call("register_tall", hs)     # v31: дом прозрачнеет, когда заходишь за него; на нём не растут травы
	_home_rect(Rect2(846, 226, 228, 124))
	mark(LAY.HOUSE_POS + Vector2(0, -60), 150)
	var door: Node2D = Node2D.new()
	door.set_script(load("res://door.gd"))
	door.position = LAY.DOOR_POS + ho
	objects.add_child(door)
	# уют у входа
	spr("bench", Vector2(792, 392) + ho)
	_home_rect(Rect2(758, 370, 68, 22))
	spr("tea_table", Vector2(706, 410) + ho)
	_home_circle(Vector2(706, 402), 18)
	if not home_in_yard():
		# тропинка от крыльца и клумбы — чтобы дом не стоял голым в лесу
		spr("flowers_pink", Vector2(842, 372) + ho, 0.8)
		spr("flowers_white", Vector2(864, 380) + ho, 0.8)
		spr("flowers_yellow", Vector2(1150, 380) + ho, 0.8)
		flower_spots.append_array([Vector2(842, 372) + ho, Vector2(1150, 380) + ho])
		return
	if classic_yard:
		spr("sign", Vector2(1066, 380))
		block_circle(Vector2(1049, 378), 5)
		var buyer: Node2D = Node2D.new()
		buyer.set_script(load("res://fish_buyer.gd"))
		buyer.position = Vector2(1066, 392)
		objects.add_child(buyer)
		spr("barrel", Vector2(1100, 356))
		spr("barrel", Vector2(1126, 368), 0.0, true)
		block_circle(Vector2(1112, 356), 22)
	spr("flowers_pink", Vector2(842, 372), 0.8)
	flower_spots.append_array([Vector2(842, 372), Vector2(864, 380), Vector2(1150, 380)])
	spr("flowers_white", Vector2(864, 380), 0.8)
	spr("flowers_yellow", Vector2(1150, 380), 0.8)
	for p in [Vector2(746, 392), Vector2(700, 410), Vector2(1100, 360), Vector2(1060, 380), Vector2(850, 376)]:
		mark(p, 40)
	if not classic_yard:
		return
	# котёл во дворе
	spr("cauldron", CAULDRON_POS)
	var cn: Node2D = Node2D.new()
	cn.set_script(load("res://cauldron.gd"))
	cn.position = CAULDRON_POS
	objects.add_child(cn)
	block_circle(CAULDRON_POS + Vector2(0, -6), 20)
	mark(CAULDRON_POS, 44)
	glows.append([CAULDRON_POS + Vector2(0, -8), 0.6, 0.7])
	# лампы
	for lp in [Vector2(1030, 452), Vector2(1186, 552), Vector2(906, 1120)]:
		var l: Sprite2D = spr("lantern", lp)
		block_circle(lp + Vector2(-2, -2), 5)
		mark(lp, 24)
		glows.append([lp + Vector2(8, -46), 0.75, 0.55])
		lantern_spots.append(lp + Vector2(8, -40))


func _build_garden() -> void:
	for y in LAY.PLOT_ROWS:
		for x in LAY.PLOT_COLS:
			var plot: Node2D = Node2D.new()
			plot.set_script(load("res://plot.gd"))
			plot.position = Vector2(float(x), float(y))
			objects.add_child(plot)
			for pl in plot.get("plants"):
				add_caster(pl as Sprite2D, true)
	var x0: float = LAY.GARDEN_RECT.position.x - 6
	while x0 < LAY.GARDEN_RECT.end.x:
		spr("fence", Vector2(x0 + 16, LAY.GARDEN_RECT.position.y - 4))
		x0 += 32.0


func _build_well_and_fence() -> void:
	spr("well", LAY.WELL_POS)
	block_circle(LAY.WELL_POS + Vector2(0, -12), 32)
	mark(LAY.WELL_POS, 60)
	var x: float = 16.0
	while x < LAY.W:
		if x < 870.0 or x > 1050.0:
			spr("fence", Vector2(x, LAY.GATE_Y))
		x += 32.0
	spr("pillar", Vector2(884, LAY.GATE_Y + 4))
	spr("pillar", Vector2(1036, LAY.GATE_Y + 4))


## Места для рыбалки вокруг пруда: круги на воде, E — закинуть удочку
func _build_fishing() -> void:
	for deg_i in range(0, 360, 20):
		var a: float = deg_to_rad(float(deg_i))
		var edge: Vector2 = Vector2(cos(a) * LAY.POND_R.x, sin(a) * LAY.POND_R.y)
		var shore: Vector2 = Vector2(-1, -1)
		var rr: float = 1.1
		while rr < 1.7:
			var q: Vector2 = LAY.POND_C + edge * rr
			if not is_blocked(q):
				shore = q
				break
			rr += 0.03
		if shore.x < 0.0:
			continue
		var water: Vector2 = (LAY.POND_C + edge * 0.8).round()
		var sp: Node2D = Node2D.new()
		sp.set_script(load("res://fishing_spot.gd"))
		sp.position = water
		sp.set("shore", shore)
		sp.set("interact_offset", (shore - water) * 0.85)
		objects.add_child(sp)
		mark(shore, 14)


## Комната чужого дома: тот же размер, что у героини, но своя обстановка
func _build_guest_room() -> void:
	var fl: Sprite2D = Sprite2D.new()
	fl.texture = load("res://art/interior_floor.png")
	fl.centered = false
	fl.position = ROOM_ORG
	fl.z_index = -10
	add_child(fl)
	var void_r: ColorRect = ColorRect.new()
	void_r.color = Color("1a1620")
	void_r.position = ROOM_ORG + Vector2(-400, -300)
	void_r.size = Vector2(1440, 900)
	void_r.z_index = -11
	add_child(void_r)
	room_floor = fl


# Обстановка домов по землям: [у стены], кровать, ковёр, стол, [мелочи на полу], [на стене]
const ROOM_SETS: Dictionary = {
	"cats": [["in9_cat_tree", "dp_wardrobe", "in9_cake_stand", "dp_bookcase"], "in9_cat_bed", "in9_rug_cats", "dp_table_round", ["in9_yarn", "dp_pot_pink", "dp_basket_carrots"], ["dp_pic_land", "dp_window_blue"], Color(1.0, 0.92, 0.94)],
	"orcs": [["in9_skull_shelf", "in9_orc_table", "dp_chest_small"], "in9_orc_bed", "in9_rug_orcs", "in9_orc_table", ["dp_chest_small", "dp_basket_carrots"], ["in9_weapon_wall"], Color(0.86, 0.76, 0.66)],
	"goblins": [["in9_gears", "dp_chest_small", "in9_skull_shelf"], "in9_junk_bed", "in9_rug_goblins", "in9_orc_table", ["in9_gears", "dp_basket_carrots"], ["dp_pic_land"], Color(0.9, 0.86, 0.72)],
	"gothic": [["in9_coffin", "in9_candelabra", "in9_goth_mirror", "dp_bookcase"], "dp_bed", "in9_rug_gothic", "dp_table_round", ["in9_candelabra", "dp_chest_small"], ["in9_portrait"], Color(0.7, 0.66, 0.8)],
	"knights": [["in9_armor", "dp_wardrobe", "dp_bookcase", "dp_clock"], "dp_bed", "in9_rug_knights", "dp_table_round", ["dp_chest_small", "dp_basket_carrots"], ["in9_banner", "dp_window_blue"], Color(1, 1, 1)],
	"elves": [["in9_plant", "in9_moon_lamp", "dp_bookcase", "in9_plant"], "in9_leaf_bed", "in9_rug_elves", "dp_table_round", ["in9_plant", "dp_pot_pink"], ["dp_window_blue"], Color(0.9, 1.0, 0.92)],
	"mages": [["in9_potion_shelf", "dp_bookcase", "in9_crystal_ball", "dp_clock"], "dp_bed", "in9_rug_mages", "dp_table_round", ["in9_books", "in9_crystal_ball"], ["dp_pic_land", "dp_window_blue"], Color(0.88, 0.88, 1.04)],
	"dwarves": [["in9_hearth", "in9_keg", "dp_chest_small"], "dp_bed", "in9_rug_dwarves", "in9_orc_table", ["in9_keg", "dp_basket_carrots"], ["in9_picks"], Color(0.9, 0.84, 0.78)],
	"spider": [["in9_web", "dp_wardrobe", "in9_plant"], "in9_cocoon_bed", "in9_rug_spider", "dp_table_round", ["dp_pot_pink"], ["in9_web"], Color(0.86, 0.84, 0.94)],
	"japan": [["in9_plant", "dp_wardrobe", "dp_bookcase"], "dp_bed", "in9_rug_elves", "dp_table_round", ["dp_pot_pink", "in9_plant"], ["dp_window_blue"], Color(1.0, 0.94, 0.9)],
	"sea": [["in9_plant", "dp_chest_small", "in9_crystal_ball"], "in9_leaf_bed", "in9_rug_mages", "dp_table_round", ["in9_plant", "dp_pot_pink"], ["dp_window_blue"], Color(0.8, 0.92, 1.05)],
}


## Обставить комнату: свой набор у земли, своя расстановка у каждого дома
func _furnish(land: String, seed_v: int) -> void:
	for n in room_props:
		if is_instance_valid(n):
			(n as Node).queue_free()
	room_props.clear()
	room_blocks.clear()
	var rs: Array = ROOM_SETS.get({"hell": "gothic", "heaven": "elves"}.get(land, land), ROOM_SETS["knights"])
	var r: RandomNumberGenerator = RandomNumberGenerator.new()
	r.seed = seed_v
	room_floor.modulate = rs[6]
	var mirror: bool = r.randf() < 0.5
	var mx: Callable = func(x: float) -> float: return 640.0 - x if mirror else x
	var walls: Array = (rs[0] as Array).duplicate()
	walls.shuffle()
	var wall_x: Array = [250.0, 300.0, 346.0, 392.0]
	for i in range(mini(walls.size(), wall_x.size())):
		if String(walls[i]) == "in9_web":
			_room_put("in9_web", Vector2(mx.call(226.0), 150.0), false)
			continue
		_room_put(String(walls[i]), Vector2(mx.call(float(wall_x[i]) + r.randf_range(-4, 4)), 156.0), true)
	var deco: Array = rs[5]
	for j in range(deco.size()):
		_room_put(String(deco[j]), Vector2(mx.call([300.0, 380.0][j % 2]), [128.0, 110.0][j % 2]), false)
	_room_put(String(rs[2]), Vector2(mx.call(326.0 + r.randf_range(-10, 10)), 252.0), false)
	_room_put(String(rs[1]), Vector2(mx.call(256.0), 214.0), true)
	_room_put(String(rs[3]), Vector2(mx.call(372.0), 232.0), true)
	var low: Array = (rs[4] as Array).duplicate()
	low.shuffle()
	var low_p: Array = [Vector2(254, 272), Vector2(392, 276), Vector2(404, 200)]
	for k in range(mini(low.size(), low_p.size())):
		_room_put(String(low[k]), Vector2(mx.call((low_p[k] as Vector2).x), (low_p[k] as Vector2).y), true)


# Товары лавок, таверн и пекарни: id еды из food_db.gd
const NPC17 = preload("res://npc_db.gd")
const RECR17 = preload("res://recruit.gd")
const SHOP_GOODS: Dictionary = {
	"bakery": ["cinnamon_bun", "cake_strawberry", "muffin", "croissant", "cookie", "pie_apple", "baguette", "gingerbread", "pancakes", "cocoa"],
	"tavern_cats": ["milk", "pie_fish", "dried_fish", "yogurt", "fish_soup", "cinnamon_bun"],
	"tavern_knights": ["cider", "roast_meat", "cheese_sandwich", "stew", "mead", "sausage"],
	"tavern_gothic": ["pomegranate_juice", "pie_pumpkin", "black_bread", "ham", "pomegranate", "onion_soup"],
	"tavern_elves": ["flower_nectar", "forest_cracker", "veg_soup", "honeycomb", "birch_sap", "wild_strawberry"],
	"tavern_mages": ["star_tea", "pie_blueberry", "sugar_cookie", "lemonade", "muffin"],
	"tavern_orcs": ["kumis", "roast_meat", "flatbread", "kebab", "jerky"],
	"tavern_goblins": ["goblin_fizz", "caramel_bug", "goblin_stew", "potato"],
	"tavern_dwarves": ["ale", "stew", "mushroom_skewer", "cheese_flatbread", "mead", "onion_soup"],
	"tavern_spider": ["dew_honey", "mushroom_soup", "fried_mushrooms"],
	"tavern_japan": ["miso_soup", "onigiri", "green_tea", "sushi_roll", "mochi", "dango"],
	"tavern_sea": ["seaweed_salad", "pearl_pudding", "coral_morse", "fish_skewer", "fish_soup"],
}


## Обстановка лавки, таверны, пекарни, дворца
func _furnish_kind(kind: String, land: String, seed_v: int) -> void:
	for n in room_props:
		if is_instance_valid(n):
			(n as Node).queue_free()
	room_props.clear()
	room_blocks.clear()
	var rs: Array = ROOM_SETS.get({"hell": "gothic", "heaven": "elves"}.get(land, land), ROOM_SETS["knights"])
	room_floor.modulate = rs[6]
	if kind != "prison":
		_room_put(String(rs[2]), Vector2(320, 252), false)
	match kind:
		"shelter":
			# приют: лежанки, миски, корзинки — и звери, которых можно забрать домой
			for bx in [256.0, 384.0]:
				_room_put("in9_cat_bed" if land == "cats" else "in9_leaf_bed", Vector2(bx, 164), true)
			_room_put("in10_counter", Vector2(320, 210), true)
			_room_put("dp_basket_carrots", Vector2(252, 274), true)
			_room_put("in9_yarn" if land == "cats" else "dp_pot_pink", Vector2(398, 276), false)
			var SH = preload("res://shelter.gd")
			var spots: Array = [Vector2(258, 196), Vector2(384, 198), Vector2(286, 250), Vector2(360, 252), Vector2(320, 268)]
			var ani: Array = SH.list_for(land)
			for ai in range(mini(ani.size(), spots.size())):
				var ak: String = String(ani[ai][0])
				var an: Node2D = Node2D.new()
				if ak.begins_with("cat:"):
					an.set_script(load("res://lost_cat.gd"))
					an.set("skin", ak.substr(4) if ak != "cat:black" else "gray")
					an.set("cat_name", SH.title(ak))
					an.set("shelter", true)
					an.set("main", self)
					an.position = ROOM_ORG + (spots[ai] as Vector2)
					objects.add_child(an)
				else:
					an.set_script(load("res://animal.gd"))
					objects.add_child(an)
					an.call("setup", ak, ROOM_ORG + (spots[ai] as Vector2))
					an.set("roam", 26.0)
					an.set("blocked", Callable(self, "is_blocked"))
				room_props.append(an)
		"prison":
			# две камеры у задней стены (каждая тюрьма — в стиле своего города), стол тюремщицы по центру
			var pt: Color = (preload("res://law.gd").PRISONS.get(land, {}) as Dictionary).get("tint", Color(0.7, 0.7, 0.75))
			room_floor.modulate = pt
			_room_put("pr18_cell_" + land, Vector2(274, 160), true)
			_room_put("pr18_cell_" + land, Vector2(366, 160), true, true)
			_room_put("in10_counter", Vector2(320, 236), true)
			_room_put("dp_chest_small", Vector2(250, 274), true)
			_room_put("in9_keg", Vector2(402, 274), true)
		"bakery":
			_room_put("in10_vitrine", Vector2(320, 232), true)
			_room_put("in9_cake_stand", Vector2(254, 160), true)
			_room_put("in9_cake_stand", Vector2(392, 160), true)
			_room_put("dp_table_round", Vector2(252, 250), true)
			_room_put("dp_table_round", Vector2(398, 256), true)
			_room_put("in9_yarn", Vector2(404, 200), false)
			_room_put("dp_window_blue", Vector2(320, 128), false)
		"tavern":
			_room_put("in10_bar", Vector2(320, 164), true)
			_room_put("in10_counter", Vector2(320, 228), true)
			_room_put("in10_tavern_table", Vector2(250, 262), true)
			_room_put("in10_tavern_table", Vector2(400, 266), true)
			_room_put("in9_keg", Vector2(410, 200), true)
			_room_put(String((rs[5] as Array)[0]), Vector2(240, 120), false)
		"shop":
			# полки с товаром: значки и ценники видны прямо на досках, E — подойти и выбрать
			for si in range(3):
				var sx: float = [244.0, 320.0, 396.0][si]
				_room_put("shelf14" if ResourceLoader.exists("res://art/shelf14.png") else "in10_shelf", Vector2(sx, 166), true)
				var sh: Node2D = Node2D.new()
				sh.set_script(load("res://shop_shelf.gd"))
				sh.set("land", land)
				sh.set("shelf_i", si)
				sh.set("shop_key", "%s_%d" % [land, seed_v])
				sh.position = ROOM_ORG + Vector2(sx, 166)
				sh.z_index = 0
				objects.add_child(sh)
				room_props.append(sh)
			_room_put("in10_counter", Vector2(320, 240), true)
			_room_put("dp_chest_small", Vector2(254, 272), true)
			_room_put("dp_basket_carrots", Vector2(392, 276), true)
		"palace":
			_room_put("in10_carpet", Vector2(320, 300), false)
			_room_put("in10_throne", Vector2(320, 176), true)
			for sx in [-1.0, 1.0]:
				_room_put(String((rs[0] as Array)[0]), Vector2(320 + sx * 90.0, 160), true)
			_room_put(String((rs[5] as Array)[0]), Vector2(250, 118), false)
			_room_put(String((rs[5] as Array)[0]), Vector2(390, 118), false)
			# стража во дворце
			for sx2 in [-1.0, 1.0]:
				var g: Node2D = _room_npc(String(preload("res://towns.gd").TOWNS.get(land, {}).get("guard", "knight_sera")), ROOM_ORG + Vector2(320 + sx2 * 60.0, 220))
				g.set("job", "post")
				g.set("role", "стража")
				room_props.append(g)


func _room_put(tex: String, p: Vector2, block: bool, flip: bool = false) -> void:
	var s: Sprite2D = spr(tex, ROOM_ORG + p, 0.0, flip, null, false)
	room_props.append(s)
	if block:
		var w: float = float(s.texture.get_width())
		room_blocks.append(Rect2(p.x - w / 2.0 + 4.0, p.y - 10.0, w - 8.0, 12.0))
	if tex.begins_with("in9_rug") or tex == "dp_rug" or tex == "in10_carpet":
		s.z_index = -9


## Зайти в гости через дверь дома
func visit_house(door: Node2D) -> void:
	await _transition(func() -> void:
		for old_n in [room_owner, room_guard]:
			if old_n != null and is_instance_valid(old_n):
				(old_n as Node).queue_free()
		room_guard = null
		visiting = door
		visit_t = 0.0
		visit_warned = 0
		guest_stay = false
		player.position = ROOM_ORG + Vector2(320, 262)
		player.set("facing", 1)
		player.set("want_facing", 1)
		cam.limit_left = int(ROOM_ORG.x)
		cam.limit_top = 0
		cam.limit_right = int(ROOM_ORG.x) + 640
		cam.limit_bottom = 360
		cam.reset_smoothing()
		var kind: String = String(door.get("kind")) if door.get("kind") != null else "home"
		var land: String = String(door.get("land"))
		if kind == "home":
			_furnish(land, int(door.get("seed_k")))
		else:
			_furnish_kind(kind, land, int(door.get("seed_k")))
		var at: Vector2 = ROOM_ORG + (Vector2(320, 196) if kind != "palace" else Vector2(320, 190))
		room_owner = _room_npc(String(door.get("owner_tex")), at)
		if kind != "home":
			room_owner.set("job", "post")
			room_owner.set("role", "лидер" if kind == "palace" else ("стража" if kind == "prison" else "торговец"))
			if kind == "shelter":
				room_owner.set("role", "житель")
				room_owner.set_meta("shelter", true)
				room_owner.set("land", land)
			if kind == "prison":
				room_owner.set_meta("jailer", true)
				room_owner.set("land", land)
				room_owner.set("npc_name", String(door.get("owner_name")))
			if SHOP_GOODS.has(kind + "_" + land):
				room_owner.set_meta("goods", SHOP_GOODS[kind + "_" + land])
			elif SHOP_GOODS.has(kind):
				room_owner.set_meta("goods", SHOP_GOODS[kind]))
	Sound.play("door", -4.0)
	var who: String = String(door.get("owner_name"))
	var kind2: String = String(door.get("kind")) if door.get("kind") != null else "home"
	if door.has_meta("own24"):
		hud.call("say", who, preload("res://talk24_db.gd").line("house_in"))
	elif _flag(door, "private") and kind2 == "home":
		hud.call("say", who, "Ой! Это мой дом... Пожалуйста, выйди, я не звала гостей.")
	else:
		hud.call("say", who, {
			"bakery": "Ня! Добро пожаловать в пекарню! Булочки только из печки — выбирай с витрины!",
			"tavern": "Заходи, садись! Кружку? Песню? Всё есть!",
			"shop": "Добро пожаловать в лавку! Всё на полках — бери, что нравится, цены на ценниках.",
			"palace": "Ты во дворце. Подойди, если есть дело.",
			"prison": "Это тюрьма. Посетителям можно, но не шуми и не лезь к решёткам.",
			"shelter": "Добро пожаловать в приют! Тут живут те, кому нужен дом. Хочешь взять кого-нибудь — скажи мне.",
		}.get(kind2, "Добро пожаловать! Заходи, грейся, чувствуй себя как дома."))


func leave_house(by_guard: bool = false) -> void:
	var door: Node2D = visiting
	await _transition(func() -> void:
		visiting = null
		player.position = door.global_position + Vector2(0, 22)
		player.set("facing", 0)
		player.set("want_facing", 0)
		_world_limits()
		cam.reset_smoothing()
		for n in [room_owner, room_guard]:
			if n != null and is_instance_valid(n):
				n.queue_free()
		room_owner = null
		room_guard = null)
	Sound.play("door", -4.0)
	if by_guard:
		hud.call("say", "Стража", "Не входи в чужие дома без приглашения. На первый раз — просто предупреждение.")
		player.call("react", "shy", 2.5)


func _room_npc(tex: String, at: Vector2) -> Node2D:
	var c: Node2D = Node2D.new()
	c.set_script(load("res://catgirl.gd"))
	objects.add_child(c)
	c.call("setup", tex, at)
	c.set("roam", 30.0)
	c.set("row", 0)
	c.set("wait_t", 6.0)
	c.set("blocked", Callable(self, "is_blocked"))
	var sp: Sprite2D = c.get("spr") as Sprite2D
	sp.material = char_light_mat(Vector2(8, 8), sp)
	var fm: ShaderMaterial = char_light_mat(Vector2(1, 1), sp)
	fm.set_shader_parameter("region_mode", true)
	(c.get("face") as Sprite2D).material = fm
	c.set("face_mat", fm)
	return c


## В гостях: выход — к двери внизу; в личном доме хозяйка просит уйти, потом зовёт стражу
func _update_visit(delta: float) -> void:
	if visiting == null or Game.busy:
		return
	if player.position.y - ROOM_ORG.y > 288.0:
		var lw0: Node = get_tree().get_first_node_in_group("law18")
		if lw0 != null and bool(lw0.get("jailed")):
			# арестованную не выпускают: дверь заперта
			player.position.y = ROOM_ORG.y + 270.0
			if Time.get_ticks_msec() - jail_msg_ms > 3500:
				jail_msg_ms = Time.get_ticks_msec()
				Sound.play("door", -8.0)
				hud.call("say", String(visiting.get("owner_name")), "Дверь заперта. Срок не вышел. Поговори со мной — решим.")
			return
		leave_house()
		return
	if not _flag(visiting, "private") or Game.ui_open:
		return
	# пока идёт разговор про ночлёг и после ночёвки хозяйка не гонит
	if guest_stay:
		return
	visit_t += delta
	var who: String = String(visiting.get("owner_name"))
	if visit_t > 7.0 and visit_warned == 0:
		visit_warned = 1
		hud.call("say", who, "Я серьёзно, выйди, пожалуйста! Иначе позову стражу.")
		if room_owner != null:
			room_owner.call("react", "pout", 3.0)
	elif visit_t > 14.0 and visit_warned == 1:
		visit_warned = 2
		hud.call("say", who, "Стража! Тут чужая в доме!")
		Game.rep_add(String(visiting.get("land")), -4)
		room_guard = _room_npc("knight_sera", ROOM_ORG + Vector2(320, 270))
		Sound.play("guard", -2.0)
		var lw1: Node = get_tree().get_first_node_in_group("law18")
		if lw1 != null:
			lw1.call("report", String(visiting.get("land")), "trespass", 1)
	elif visit_t > 17.0 and visit_warned == 2:
		visit_warned = 3
		Game.rep_add(String(visiting.get("land")), -8)
		var land_t: String = String(visiting.get("land"))
		var lw2: Node = get_tree().get_first_node_in_group("law18")
		if lw2 != null and int((lw2.get("heat") as Dictionary).get(land_t, 0)) + 1 >= int(lw2.get("LIMIT")):
			lw2.call("report", land_t, "trespass", 1)      # повторный проступок — арест
			return
		if lw2 != null:
			lw2.call("report", land_t, "trespass", 1)
		leave_house(true)


## Домик внутри: кухня слева, спальня справа (вид сверху). Лежит далеко от улицы, камера туда переезжает.
func _build_interior() -> void:
	var fl: Sprite2D = Sprite2D.new()
	fl.texture = load("res://art/interior_floor.png")
	fl.centered = false
	fl.position = IN_ORG
	fl.z_index = -10
	add_child(fl)
	var void_r: ColorRect = ColorRect.new()    # темнота вокруг домика
	void_r.color = Color("1a1620")
	void_r.position = IN_ORG + Vector2(-400, -300)
	void_r.size = Vector2(1440, 900)
	void_r.z_index = -11
	add_child(void_r)
	# v23: обстановка — мебель из house23.gd (Game.furniture); тут только пол, стены и свет
	in_blocks = []
	if not classic_yard:
		_build_in_lights()
		return
	var ms_spr: Sprite2D = spr("in_mop", IN_ORG + Vector2(240, 282), 0.0, false, null, false)
	in_blocks.append(Rect2(232, 272, 16, 10))
	mop_stand = Node2D.new()
	mop_stand.set_script(load("res://mop_stand.gd"))
	mop_stand.position = IN_ORG + Vector2(240, 280)
	mop_stand.set("sprite", ms_spr)
	objects.add_child(mop_stand)
	_build_in_lights()


## Тёплый свет в доме: луч из окна на пол (с пылинками), огонь в печке, свеча на столе, фонарик у кровати.
## Всё рисуется сложением цвета поверх комнаты, ступеньками — как пиксель-арт.
func _build_in_lights() -> void:
	var add_mat: CanvasItemMaterial = CanvasItemMaterial.new()
	add_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	var lay: Node2D = Node2D.new()
	lay.z_index = 30
	lay.position = IN_ORG
	add_child(lay)
	# луч из окна: от стекла вниз-вправо на пол, к полу гаснет
	in_beam = Node2D.new()
	lay.add_child(in_beam)
	var beam: Polygon2D = Polygon2D.new()
	beam.polygon = PackedVector2Array([Vector2(304, 128), Vector2(336, 128), Vector2(376, 252), Vector2(336, 252)])
	beam.vertex_colors = PackedColorArray([Color(1, 0.86, 0.6, 0.20), Color(1, 0.86, 0.6, 0.20), Color(1, 0.8, 0.5, 0.0), Color(1, 0.8, 0.5, 0.0)])
	beam.material = add_mat
	in_beam.add_child(beam)
	# солнечные лучи: светлые полосы из стекла наискосок до пола, каждая чуть «дышит»
	in_rays.clear()
	var shafts: Array = [[306.0, 4.0, 0.26], [313.0, 6.0, 0.20], [321.0, 3.0, 0.30], [326.0, 7.0, 0.18], [333.0, 4.0, 0.24]]
	for sh in shafts:
		var tx: float = float(sh[0])
		var tw: float = float(sh[1])
		var ray: Polygon2D = Polygon2D.new()
		ray.polygon = PackedVector2Array([Vector2(tx, 104), Vector2(tx + tw, 104), Vector2(tx + tw * 1.8 + 44.0, 256), Vector2(tx + 44.0, 256)])
		var a0: float = float(sh[2])
		ray.vertex_colors = PackedColorArray([Color(1, 0.9, 0.62, a0), Color(1, 0.9, 0.62, a0), Color(1, 0.78, 0.45, 0.0), Color(1, 0.78, 0.45, 0.0)])
		ray.material = add_mat
		in_beam.add_child(ray)
		in_rays.append(ray)
	# свечение самого окна
	var wg: Polygon2D = Polygon2D.new()
	wg.polygon = PackedVector2Array([Vector2(303, 102), Vector2(337, 102), Vector2(337, 126), Vector2(303, 126)])
	wg.color = Color(1, 0.92, 0.7, 0.22)
	wg.material = add_mat
	in_beam.add_child(wg)
	# на полу — светлые «стёкла» окна с тенью от крестовины
	for pane in [Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(1, 1)]:
		var pv: Vector2 = pane
		var x0: float = 314.0 + pv.x * 17.0 + pv.y * 7.0
		var y0: float = 164.0 + pv.y * 15.0
		var q: Polygon2D = Polygon2D.new()
		q.polygon = PackedVector2Array([Vector2(x0, y0), Vector2(x0 + 15, y0), Vector2(x0 + 21, y0 + 13), Vector2(x0 + 6, y0 + 13)])
		q.color = Color(1, 0.84, 0.56, 0.16)
		q.material = add_mat
		in_beam.add_child(q)
	# пылинки в луче
	var dust: CPUParticles2D = CPUParticles2D.new()
	dust.amount = 16
	dust.lifetime = 7.0
	dust.preprocess = 7.0
	dust.position = Vector2(336, 190)
	dust.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	dust.emission_rect_extents = Vector2(18, 50)
	dust.direction = Vector2(0.3, -1)
	dust.spread = 60.0
	dust.gravity = Vector2(0, 0.6)
	dust.initial_velocity_min = 1.0
	dust.initial_velocity_max = 3.0
	dust.color = Color(1, 0.92, 0.7, 0.55)
	var ramp: Gradient = Gradient.new()
	ramp.set_color(0, Color(1, 1, 1, 0))
	ramp.add_point(0.3, Color(1, 1, 1, 1))
	ramp.set_color(ramp.get_point_count() - 1, Color(1, 1, 1, 0))
	dust.color_ramp = ramp
	dust.material = add_mat
	in_beam.add_child(dust)
	# круглые пятна света: [место, радиус, цвет, днём, ночью, мерцание]
	var glow_tex: Texture2D = load("res://art/cz_glow.png")
	var spots: Array = [
		[Vector2(268, 206), 26.0, Color(1.0, 0.75, 0.40), 0.10, 0.75, 0.6],   # свеча на столе
		[Vector2(397, 214), 26.0, Color(1.0, 0.78, 0.45), 0.08, 0.75, 0.4],   # фонарик у кровати
		[Vector2(320, 216), 90.0, Color(1.0, 0.80, 0.55), 0.10, 0.22, 0.0],   # общий тёплый свет комнаты
	]
	if not classic_yard:
		spots = [spots[2]]          # v23: свечи и фонарики теперь у своей мебели
	for sp in spots:
		var g: Sprite2D = Sprite2D.new()
		g.texture = glow_tex
		g.position = sp[0]
		g.scale = Vector2.ONE * float(sp[1]) / 32.0
		g.material = add_mat
		lay.add_child(g)
		in_glows.append([g, sp[2], float(sp[3]), float(sp[4]), float(sp[5])])


## Свет в доме: днём солнце из окна, вечером и ночью — огонь, свеча и фонарик ярче
func _update_in_lights(n: float) -> void:
	var tm: float = Time.get_ticks_msec() * 0.001
	var gold: float = Game.golden()
	if in_beam != null:
		in_beam.visible = inside and n < 0.95
		in_beam.modulate = Color(1.0, 1.0 - gold * 0.12, 1.0 - gold * 0.3, (1.0 - n) * (0.85 + gold * 0.4))
		for i in range(in_rays.size()):
			var r: Polygon2D = in_rays[i]
			# лучи медленно дышат, каждый в своём ритме; иногда по ним «пробегает» облачко
			r.modulate.a = 0.65 + 0.35 * sin(tm * (0.5 + 0.17 * float(i)) + float(i) * 1.7)
	for gl in in_glows:
		var g: Sprite2D = gl[0]
		g.visible = inside
		var fl: float = float(gl[4])
		var flick: float = 1.0 + fl * (0.10 * sin(tm * 9.0 + g.position.x) + 0.06 * sin(tm * 23.0 + g.position.y))
		var a: float = lerpf(float(gl[2]), float(gl[3]), n) * flick
		var c: Color = gl[1]
		g.modulate = Color(c.r * a, c.g * a, c.b * a, 1.0)


## Попить и поесть: колодец, яблоня, раковина, плита, корзина с яблоками, стол. Без подсказок.
func _make_consumable(kind: String, pos: Vector2, off: Vector2 = Vector2.ZERO) -> void:
	var n: Node2D = Node2D.new()
	n.set_script(load("res://consumable.gd"))
	n.set("kind", kind)
	n.set("interact_offset", off)
	n.position = pos
	objects.add_child(n)


func _build_consumables() -> void:
	if classic_yard:
		_make_consumable("well", LAY.WELL_POS + Vector2(0, 32), Vector2(0, -4))
	_make_consumable("apples", Vector2(1640, 622), Vector2(0, -4))
	if not classic_yard:
		return                     # v23: в доме пьют и едят у своей мебели (умывальник, корзина)
	_make_consumable("sink", IN_ORG + Vector2(322, 160), Vector2(0, 2))
	_make_consumable("stove", IN_ORG + Vector2(288, 160), Vector2(0, 2))
	_make_consumable("apples", IN_ORG + Vector2(260, 276), Vector2(0, -2))
	_make_consumable("table", IN_ORG + Vector2(298, 238), Vector2(0, 0))


## Деревенский сортир на краю луга: E — зайти. Без подсказок.
func _build_outhouse() -> void:
	var p: Vector2 = Vector2(1470, 1010)
	var s: Sprite2D = spr("outhouse", p)
	block_rects.append(Rect2(1448, 998, 44, 14))
	mark(p, 60)
	var n: Node2D = Node2D.new()
	n.set_script(load("res://outhouse.gd"))
	n.position = p + Vector2(0, 2)
	n.set("sprite", s)
	objects.add_child(n)


## Зайти в будку: героиня скрывается, будка слегка трясётся, потом выходит. Если не приспичило — ничего не происходит.
func use_outhouse(node: Node2D) -> void:
	if Game.busy or Game.ui_open or inside:
		return
	if Game.pee < 0.15 and Game.poo < 0.15:
		return
	# при людях ей стыдно: не идёт, краснеет и терпит
	if _people_near(player.position, PEOPLE_R):
		player.call("react", "shy", 2.5)
		Game.shame = minf(1.0, Game.shame + 0.15)
		return
	var big: bool = Game.toilet_big()
	var secs: float = Game.toilet_seconds()
	Game.busy = true
	player.visible = false
	var sp: Sprite2D = node.get("sprite")
	var base_x: float = sp.position.x
	var tw: Tween = create_tween().set_loops(maxi(1, int(secs / 0.36)))
	tw.tween_property(sp, "position:x", base_x + 1.0, 0.12)
	tw.tween_property(sp, "position:x", base_x - 1.0, 0.12)
	tw.tween_property(sp, "position:x", base_x, 0.12)
	await get_tree().create_timer(secs).timeout
	tw.kill()
	sp.position.x = base_x
	Game.pee = 0.0
	if big:
		Game.poo = 0.0
	player.visible = true
	Game.busy = false


## Есть ли рядом люди (жители)
func _people_near(p: Vector2, r: float) -> bool:
	for v in get_tree().get_nodes_in_group("villagers"):
		if not is_instance_valid(v) or (v as Node).is_queued_for_deletion():
			continue
		var vn: Node2D = v as Node2D
		if vn != null and vn.visible and vn.global_position.distance_to(p) < r:
			return true
	return false


## Не добежала до туалета
func _on_accident(kind: String) -> void:
	var seen: bool = _people_near(player.position, PEOPLE_R)
	# сгорает со стыда; при людях — сильнее всего
	Game.shame = 1.0 if seen else (0.9 if kind == "poo" else 0.8)
	Game.busy = true
	player.call("react", "shy", 3.0)
	# не привязано к сетке: прямо под героиней, как есть
	spawn_mess(kind, player.position + (Vector2(randf_range(-5.0, 5.0), randf_range(5.0, 8.0)) if kind == "poo" else Vector2(randf_range(-1.5, 1.5), randf_range(-1.0, 1.0))))
	await get_tree().create_timer(4.5 if kind == "pee" else 2.8).timeout
	Game.busy = false


func spawn_mess(kind: String, pos: Vector2) -> Node2D:
	var ms: Node2D = Node2D.new()
	ms.set_script(load("res://mess.gd"))
	ms.set("kind", kind)
	ms.position = pos
	add_child(ms)
	messes.append(ms)
	return ms


## Лужи и кучки, которые ещё не высохли и не убраны
func live_messes() -> Array:
	var out: Array = []
	for m in messes:
		if is_instance_valid(m) and not (m as Node).is_queued_for_deletion():
			out.append(m)
	messes = out
	return out


## Убрать шваброй: героиня трёт пол, лужа или кучка понемногу исчезает
func clean_mess(m: Node2D) -> void:
	if not Game.has_mop or Game.busy or Game.ui_open or not is_instance_valid(m):
		return
	Game.busy = true
	m.set("cleaning", true)
	var to: Vector2 = m.global_position - player.position
	var tw: Tween = create_tween().set_loops(5)
	tw.tween_property(mop_spr, "rotation", 0.35, 0.18)
	tw.tween_property(mop_spr, "rotation", -0.35, 0.18)
	var tw2: Tween = create_tween()
	tw2.tween_property(m, "amount", 0.0, 1.8)
	await tw2.finished
	tw.kill()
	mop_spr.rotation = 0.0
	if is_instance_valid(m):
		m.call("_vanish")
	live_messes()
	if to.length() > 0.0:
		pass
	Game.busy = false


## Швабра в руках: стоит рядом с героиней с той стороны, куда она смотрит
func _update_mop() -> void:
	if mop_spr == null:
		return
	mop_spr.visible = Game.has_mop
	if not Game.has_mop:
		return
	var fc: int = int(player.get("facing"))
	var left: bool = fc in [2, 4, 5]
	mop_spr.position = Vector2(-9.0 if left else 9.0, 1.0)
	mop_spr.flip_h = left
	mop_spr.show_behind_parent = fc in [1, 5, 7]


## Сачок в руках: рядом с героиней с той стороны, куда она смотрит
func _update_net() -> void:
	if net_spr == null:
		return
	var hn: bool = Game.has_tool("net") and not inside
	net_spr.visible = hn
	if not hn:
		return
	var fc: int = int(player.get("facing"))
	var left: bool = fc in [2, 4, 5]
	net_spr.position = Vector2(-9.0 if left else 9.0, 1.0)
	net_spr.flip_h = left
	net_spr.show_behind_parent = fc in [1, 5, 7]


## Вернуть сачок на место (при выходе из дома и во сне)
func _return_net() -> void:
	pass   # v16: сачок — обычный инструмент в руках, на подставку не возвращается


## Взмах сачком: ловит ближайшее насекомое рядом (кроме тли)
func swing_net() -> void:
	if not Game.has_tool("net") or Game.busy or Game.ui_open or inside:
		return
	Game.busy = true
	var tw: Tween = create_tween()
	tw.tween_property(net_spr, "rotation", 0.9 * (-1.0 if net_spr.flip_h else 1.0), 0.14)
	tw.tween_property(net_spr, "rotation", 0.0, 0.18)
	var best: Node2D = null
	var bd: float = 26.0
	for b in get_tree().get_nodes_in_group("insects"):
		if not is_instance_valid(b) or (b as Node).is_queued_for_deletion():
			continue
		if String(b.get("kind")) == "aphid":
			continue
		var bn: Node2D = b as Node2D
		var dd: float = (bn.global_position + Vector2(0, -float(b.get("alt")))).distance_to(player.global_position + Vector2(0, -10))
		if dd < bd:
			bd = dd
			best = bn
	await tw.finished
	if best != null and is_instance_valid(best):
		var k: String = String(best.get("kind"))
		Game.caught[k] = int(Game.caught.get(k, 0)) + 1
		Game.add_item("bug_" + k)
		best.queue_free()
	Game.busy = false


## Вернуть швабру в ведро (при выходе из дома и во сне)
func _return_mop() -> void:
	if Game.has_mop:
		Game.has_mop = false
		if mop_stand != null:
			mop_stand.call("refresh")


## Перенос героини в дом или на улицу
func _set_inside(on: bool, pos: Vector2) -> void:
	inside = on
	player.position = pos
	player.set("facing", 1 if on else 0)
	player.set("want_facing", 1 if on else 0)
	if on:
		cam.limit_left = int(IN_ORG.x)
		cam.limit_top = 0
		cam.limit_right = int(IN_ORG.x) + 640
		cam.limit_bottom = 360
	else:
		_world_limits()
	cam.reset_smoothing()


## Быстрое затемнение: вышла из кадра — сменили место — вернулась
func _transition(change: Callable) -> void:
	Game.busy = true
	var f: ColorRect = hud.get("fade")
	var tw: Tween = create_tween()
	tw.tween_property(f, "color:a", 1.0, 0.18)
	await tw.finished
	change.call()
	await get_tree().create_timer(0.05).timeout
	var tw2: Tween = create_tween()
	tw2.tween_property(f, "color:a", 0.0, 0.18)
	await tw2.finished
	Game.busy = false


## Выйти из «особых» мест без двери: гости, дом, тюрьма, морское дно (для телепорта и побега)
func _leave_special_states() -> void:
	var rl24: Node = get_node_or_null("Realm24")
	if rl24 != null and String(rl24.get("active")) != "":
		for rn in (rl24.get("roots") as Dictionary).values():
			(rn as Node2D).visible = false
			(rn as Node2D).process_mode = Node.PROCESS_MODE_DISABLED
		rl24.set("active", "")
		Game.realm = ""
	var dn23: Node = get_node_or_null("V23/Dungeon23")
	if dn23 != null and bool(dn23.get("active")):
		dn23.call("_clear")
		dn23.set("active", false)
	if visiting != null:
		visiting = null
		for n in [room_owner, room_guard]:
			if n != null and is_instance_valid(n):
				n.queue_free()
		room_owner = null
		room_guard = null
	inside = false
	if sea != null and bool(sea.get("diving")):
		sea.call("set_diving", false)
	if live != null and bool(live.get("active")):
		live.call("set_active", false)
	var by29l: Node = get_node_or_null("Backyard29")
	if by29l != null and bool(by29l.get("active")):
		by29l.set("active", false)
	if mine != null and bool(mine.get("inside")):
		mine.call("set_inside", false)
	var lw: Node = get_tree().get_first_node_in_group("law18")
	if lw != null:
		lw.call("on_teleport")


## Ближайшая свободная точка к p (по спирали)
func free_near(p: Vector2) -> Vector2:
	if not is_blocked(p):
		return p
	for ring in range(1, 40):
		for k in range(ring * 6):
			var a: float = TAU * float(k) / float(ring * 6)
			var q: Vector2 = (p + Vector2(cos(a), sin(a) * 0.8) * float(ring) * 20.0).round()
			if not is_blocked(q):
				return q
	return p


## v21: режим бога — зверь или птица появляется рядом с героиней
func god_spawn(kind: String, is_bird: bool) -> void:
	if player == null or inside or visiting != null:
		return
	var a: float = randf() * TAU
	var at: Vector2 = free_near((player.position + Vector2(cos(a) * 60.0, sin(a) * 30.0 + 10.0)).round())
	if is_bird:
		var bm: Node = get_node_or_null("Birds")
		if bm == null:
			return
		var b: Node2D = Node2D.new()
		b.set_script(load("res://bird.gd"))
		b.position = at
		(bm.get("holder") as Node2D).add_child(b)
		b.call("setup", kind, bm, Vector2.INF, 0.0)
	else:
		var an: Node2D = Node2D.new()
		an.set_script(load("res://animal.gd"))
		objects.add_child(an)
		an.call("setup", kind, at)
		an.set("blocked", Callable(self, "is_blocked"))
		add_caster(an.get("spr") as Sprite2D, true)
	Sound.play("magic", -6.0)


## Телепорт (режим бога и игровые события): в любую точку большого мира
func teleport_to(p: Vector2) -> void:
	if Game.busy:
		return
	await _transition(func() -> void:
		_leave_special_states()
		world.call("build_around", p)
		player.position = free_near(p)
		player.set("facing", 0)
		player.set("want_facing", 0)
		_world_limits()
		cam.reset_smoothing()
		world.call("reveal", player.position, 6.0))
	Sound.play("magic", -4.0)


func enter_house() -> void:
	Sound.play("door", -4.0)
	if inside or Game.busy:
		return
	await _transition(func() -> void: _set_inside(true, IN_ORG + IN_DOOR_IN))


func exit_house() -> void:
	Sound.play("door", -4.0)
	if not inside or Game.busy:
		return
	await _transition(func() -> void:
		_return_mop()
		_return_net()
		_set_inside(false, LAY.DOOR_POS + home_off() + Vector2(0, 40)))
	_autosave()


func _build_forest() -> void:
	var names: Array = ["tree_a", "tree_b", "tree_c", "tree_d", "tree_a", "tree_b", "tree_c", "pine_a", "pine_b", "tree_a", "tree_autumn", "tree_blossom"]
	var gy: int = -1
	while gy < 17:
		var gx: int = -1
		while gx < 23:
			var p: Vector2 = Vector2(gx * 88.0 + rng.randf_range(-30, 30) + (44.0 if gy % 2 == 0 else 0.0), gy * 84.0 + rng.randf_range(-24, 24))
			gx += 1
			var band: bool = p.y < 318.0 or p.x < 150.0 or p.x > 1772.0 or p.y > 1300.0
			if not band:
				continue
			if p.y > 1280.0 and absf(p.x - 960.0) < 90.0:
				continue
			# проход на запад, к паутинному лесу
			if p.x < 260.0 and p.y > 540.0 and p.y < 720.0:
				continue
			if p.y > 150.0 and p.y < 318.0 and absf(p.x - 960.0) < 210.0:
				continue
			var n: String = names[rng.randi_range(0, names.size() - 1)]
			if yard30_rect().has_point(p):
				continue     # v30: на огороде справа от дома лес не растёт
			yard_trees.append(spr(n, p, 0.5, rng.randf() < 0.5))
			if LAY.WALK_RECT.grow(20).has_point(p) or Rect2(0, 0, LAY.W, LAY.H).has_point(p):
				block_circle(p + Vector2(0, -4), 7)
			elif not Rect2(0, 0, LAY.W, LAY.H).has_point(p):
				world.call("add_block", p + Vector2(0, -4), 7.0)
		gy += 1
	# одиночные деревья на полянах
	for p2 in [Vector2(300, 470), Vector2(1660, 470), Vector2(1700, 980), Vector2(250, 1130), Vector2(1560, 1130), Vector2(700, 1140)]:
		var pv: Vector2 = p2
		if LAY.is_busy(pv, 30.0) or yard30_rect().has_point(pv):
			continue
		yard_trees.append(spr(["tree_blossom", "tree_autumn", "tree_d", "tree_c", "tree_a", "pine_a"][posmod(int(pv.x + pv.y), 6)], pv, 0.5))
		block_circle(pv + Vector2(0, -4), 13)
		mark(pv, 70)
	# яблоня у огорода
	yard_trees.append(spr("tree_apple", Vector2(1640, 600), 0.4))
	block_circle(Vector2(1640, 596), 13)
	mark(Vector2(1640, 600), 60)
	# кусты вдоль кромки леса
	var bx: float = 170.0
	while bx < 1760.0:
		var bp: Vector2 = Vector2(bx + rng.randf_range(-16, 16), 340.0 + rng.randf_range(-8, 10))
		if absf(bp.x - 960.0) > 230.0 and free_spot(bp, 26) and not yard30_rect().grow(20).has_point(bp):
			bushes.append([spr(["bush_a", "bush_b", "bush_c", "bush_a"][rng.randi_range(0, 3)], bp, 0.6, rng.randf() < 0.5), bp])
			mark(bp, 26)
		bx += rng.randf_range(60, 110)
	for side in [158.0, 1764.0]:
		var by: float = 340.0
		while by < 1180.0:
			var sp: Vector2 = Vector2(side + rng.randf_range(-10, 10), by)
			if not LAY.is_busy(sp, 10.0) and free_spot(sp, 26):
				bushes.append([spr(["bush_a", "bush_b", "bush_c"][rng.randi_range(0, 2)], sp, 0.6, rng.randf() < 0.5), sp])
				mark(sp, 26)
			by += rng.randf_range(80, 140)


## v30: огород справа от дома (backyard29.gd) с запасом — тут не сажаем лес и кусты
func yard30_rect() -> Rect2:
	return Rect2(Game.home_pos + Vector2(94, -380), Vector2(764, 420))


func _rand_meadow(margin: float, r: float) -> Vector2:
	for i in range(80):
		var p: Vector2 = Vector2(rng.randf_range(LAY.WALK_RECT.position.x + 30, LAY.WALK_RECT.end.x - 30), rng.randf_range(LAY.WALK_RECT.position.y + 20, LAY.WALK_RECT.end.y - 10))
		if LAY.is_busy(p, margin):
			continue
		if not free_spot(p, r):
			continue
		return p
	return Vector2(-1, -1)


func _build_decor() -> void:
	var plan: Array = [["bush_b", 6, 26, 0], ["bush_c", 5, 26, 0], ["bush_a", 4, 26, 0], ["rock", 7, 18, 0], ["rock_big", 3, 26, 0], ["stump", 3, 20, 12], ["mushrooms", 7, 10, 0]]
	for item in plan:
		for i in range(int(item[1])):
			var p: Vector2 = _rand_meadow(24.0, float(item[2]))
			if p.x < 0.0:
				continue
			var ds: Sprite2D = spr(String(item[0]), p, 0.6 if String(item[0]).begins_with("bush") else 0.0, rng.randf() < 0.5)
			if String(item[0]).begins_with("bush"):
				bushes.append([ds, p])
			if int(item[3]) > 0:
				block_circle(p + Vector2(0, -4), float(item[3]))
			mark(p, float(item[2]))
	var fl: Array = ["flowers_pink", "flowers_white", "flowers_blue", "flowers_yellow"]
	for i in range(46):
		var p2: Vector2 = _rand_meadow(12.0, 14.0)
		if p2.x < 0.0:
			continue
		spr(fl[rng.randi_range(0, 3)], p2, 0.9, rng.randf() < 0.5)
		flower_spots.append(p2)
		mark(p2, 14)


func _spawn_herbs() -> void:
	for h in get_tree().get_nodes_in_group("wild_herbs"):
		h.queue_free()
	var count: int = 0
	var tries: int = 0
	var want_herbs: int = maxi(8, (18 if classic_yard else 30) + Game.herb_bonus)
	while count < want_herbs and tries < 600:
		tries += 1
		var p: Vector2 = Vector2(rng.randf_range(180, 1740), rng.randf_range(330, 1170))
		if LAY.is_busy(p, 14.0) or is_blocked(p) or not free_spot(p, 16):
			continue
		var ed: float = minf(minf(p.x - 140.0, 1780.0 - p.x), minf(p.y - 300.0, 1180.0 - p.y))
		var id: String
		if ed < 150.0 and rng.randf() < 0.6:
			id = "nettle"
		elif LAY.pond_value(p) < 0.6 and rng.randf() < 0.6:
			id = "mint"
		elif classic_yard:
			id = ["mint", "lavender", "chamomile", "chamomile"][rng.randi_range(0, 3)]
		else:
			# родной луг — самый щедрый: и огородные травы, и все луговые
			var pool: Array = ["mint", "lavender", "chamomile", "chamomile", "plantain", "plantain", "clover", "dandelion", "yarrow", "calendula", "thyme", "cornflower"]
			id = String(pool[rng.randi_range(0, pool.size() - 1)])
		var herb: Node2D = Node2D.new()
		herb.set_script(load("res://herb.gd"))
		herb.set("herb_id", id)
		herb.position = p.round()
		objects.add_child(herb)   # v27b: без тени-силуэта — травы стоят на мягкой лунке (plant_ground27.gd)
		count += 1


func _build_creatures() -> void:
	# подушка дома — кот спит на ней, когда дома пора спать; а так кот всегда ходит за героиней (cat.gd)
	var home_c: Vector2 = Vector2(892, 380) + home_off()
	var cu: Sprite2D = Sprite2D.new()
	cu.texture = load("res://art/cushion.png")
	cu.centered = false
	cu.offset = Vector2(-27, -21)
	cu.scale = Vector2(0.6667, 0.6667)
	cu.position = home_c + Vector2(0, -1)
	objects.add_child(cu)
	add_caster(cu)
	var cat: Node2D = Node2D.new()
	cat.set_script(load("res://cat.gd"))
	cat.name = "Cat"
	cat.position = Vector2(930, 450) + home_off()
	cat.set("main", self)
	cat.set("cushion_pos", home_c)
	cat.set("blocked", Callable(self, "is_blocked"))
	objects.add_child(cat)
	add_caster(cat.get("spr") as Sprite2D, true)


func _build_player() -> void:
	player = Node2D.new()
	player.set_script(load("res://player.gd"))
	player.position = Vector2(960, 430) + home_off()
	objects.add_child(player)
	player.set("blocked", Callable(self, "is_blocked"))
	player.set("slow_at", Callable(self, "bush_at"))
	add_caster(player.get("sprite") as Sprite2D, true)
	(player.get("sprite") as Sprite2D).material = char_light_mat(Vector2(28, 8), player.get("sprite") as Sprite2D)
	build_wind_layers(player.get("sprite") as Sprite2D, "res://art/player.png", Vector2(28, 8))
	Game.equip_changed.connect(apply_outfit)
	apply_outfit()
	var dk: CanvasLayer = CanvasLayer.new()
	dk.set_script(load("res://darkness.gd"))
	add_child(dk)
	dk.call("setup", self)
	var fm: ShaderMaterial = char_light_mat(Vector2(1, 1), player.get("sprite") as Sprite2D)
	fm.set_shader_parameter("region_mode", true)
	(player.get("face") as Sprite2D).material = fm
	player.set("face_mat", fm)
	var bm: ShaderMaterial = char_light_mat(Vector2(1, 1), player.get("sprite") as Sprite2D)
	bm.set_shader_parameter("region_mode", true)
	(player.get("bust") as Sprite2D).material = bm
	player.set("bust_mat", bm)
	mop_spr = Sprite2D.new()
	mop_spr.texture = load("res://art/mop_held.png")
	mop_spr.centered = false
	mop_spr.offset = Vector2(-6, -42)
	mop_spr.visible = false
	player.add_child(mop_spr)
	net_spr = Sprite2D.new()
	net_spr.texture = load("res://art/net_held.png")
	net_spr.centered = false
	net_spr.offset = Vector2(-8, -42)
	net_spr.visible = false
	player.add_child(net_spr)
	cam = Camera2D.new()
	cam.zoom = Vector2(3, 3)
	_world_limits()
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 7.0
	cam.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	cam.offset = Vector2(0, -20)
	player.add_child(cam)
	arrow = Sprite2D.new()
	arrow.texture = load("res://art/ui_arrow.png")
	arrow.z_index = 50
	arrow.visible = false
	add_child(arrow)


func _additive() -> CanvasItemMaterial:
	var m: CanvasItemMaterial = CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return m


func _fade_ramp(peak: float = 1.0) -> Gradient:
	var g: Gradient = Gradient.new()
	g.set_color(0, Color(1, 1, 1, 0))
	g.set_color(1, Color(1, 1, 1, 0))
	g.add_point(0.2, Color(1, 1, 1, peak))
	g.add_point(0.75, Color(1, 1, 1, peak))
	return g


## Новое свечение уже в игре (котёл, фонарь с верстака): делает спрайт и кладёт в glows
func add_glow(pos: Vector2, size: float, k: float) -> void:
	var s: Sprite2D = Sprite2D.new()
	s.texture = load("res://art/fx_glow.png")
	s.position = pos
	s.scale = Vector2.ONE * size
	s.modulate = Color(1.0, 0.72, 0.38, 0.0)
	s.material = _additive()
	fx_layer.add_child(s)
	glows.append([s, k])


func _build_fx() -> void:
	fx_layer = CanvasLayer.new()
	fx_layer.layer = 1
	fx_layer.follow_viewport_enabled = true
	add_child(fx_layer)
	# свечение окон
	var top_left: Vector2 = LAY.HOUSE_POS + home_off() - Vector2(144, 236)
	glows.append([top_left + Vector2(62, 158), 1.0, 0.8])
	glows.append([top_left + Vector2(226, 158), 1.0, 0.8])
	glows.append([top_left + Vector2(144, 74), 0.7, 0.55])
	var glow_tex: Texture2D = load("res://art/fx_glow.png")
	var built: Array = []
	for g in glows:
		var s: Sprite2D = Sprite2D.new()
		s.texture = glow_tex
		s.position = g[0]
		s.scale = Vector2.ONE * float(g[1])
		s.modulate = Color(1.0, 0.72, 0.38, 0.0)
		s.material = _additive()
		fx_layer.add_child(s)
		built.append([s, float(g[2])])
	glows = built
	# светлячки
	fireflies = CPUParticles2D.new()
	fireflies.texture = load("res://art/fx_firefly.png")
	fireflies.amount = 90
	fireflies.lifetime = 6.0
	fireflies.preprocess = 6.0
	fireflies.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	fireflies.emission_rect_extents = Vector2(820, 440)
	fireflies.position = Vector2(960, 740)
	fireflies.direction = Vector2(0, -1)
	fireflies.spread = 180.0
	fireflies.gravity = Vector2.ZERO
	fireflies.initial_velocity_min = 3.0
	fireflies.initial_velocity_max = 10.0
	fireflies.color = Color(0.85, 1.0, 0.55)
	fireflies.color_ramp = _fade_ramp()
	fireflies.material = _additive()
	fx_layer.add_child(fireflies)
	# опадающие листья
	leaves = CPUParticles2D.new()
	leaves.texture = load("res://art/fx_leaf.png")
	leaves.amount = 34
	leaves.lifetime = 12.0
	leaves.preprocess = 12.0
	leaves.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	leaves.emission_rect_extents = Vector2(980, 600)
	leaves.position = Vector2(900, 600)
	leaves.direction = Vector2(1, 0.3)
	leaves.spread = 30.0
	leaves.gravity = Vector2(4, 9)
	leaves.initial_velocity_min = 8.0
	leaves.initial_velocity_max = 18.0
	leaves.angular_velocity_min = -140.0
	leaves.angular_velocity_max = 140.0
	leaves.angle_min = 0.0
	leaves.angle_max = 360.0
	leaves.color_ramp = _fade_ramp()
	leaves.z_index = 40
	add_child(leaves)
	# дым из трубы
	smoke = CPUParticles2D.new()
	smoke.texture = load("res://art/fx_soft.png")
	smoke.amount = 16
	smoke.lifetime = 5.0
	smoke.preprocess = 5.0
	smoke.position = top_left + Vector2(213, 4)
	smoke.direction = Vector2(0.25, -1)
	smoke.spread = 12.0
	smoke.gravity = Vector2(5, -3)
	smoke.initial_velocity_min = 9.0
	smoke.initial_velocity_max = 15.0
	smoke.scale_amount_min = 0.35
	smoke.scale_amount_max = 0.5
	var sc: Curve = Curve.new()
	sc.add_point(Vector2(0, 0.6))
	sc.add_point(Vector2(1, 2.6))
	smoke.scale_amount_curve = sc
	var sg: Gradient = Gradient.new()
	sg.set_color(0, Color(0.92, 0.9, 0.9, 0.0))
	sg.set_color(1, Color(0.85, 0.85, 0.9, 0.0))
	sg.add_point(0.15, Color(0.92, 0.9, 0.9, 0.55))
	smoke.color_ramp = sg
	smoke.z_index = 40
	add_child(smoke)
	# искорки на воде
	var spark: CPUParticles2D = CPUParticles2D.new()
	spark.texture = load("res://art/fx_firefly.png")
	spark.amount = 14
	spark.lifetime = 1.4
	spark.preprocess = 1.4
	spark.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	spark.emission_rect_extents = Vector2(130, 70)
	spark.position = LAY.POND_C
	spark.gravity = Vector2.ZERO
	spark.initial_velocity_max = 0.0
	spark.color = Color(1, 1, 1, 0.9)
	spark.color_ramp = _fade_ramp()
	spark.z_index = -5
	add_child(spark)
	# солнечные лучи и тёплая цветокоррекция (поверх мира, под интерфейсом)
	var rays_layer: CanvasLayer = CanvasLayer.new()
	rays_layer.layer = 2
	add_child(rays_layer)
	rays = TextureRect.new()
	rays.texture = load("res://art/fx_rays.png")
	rays.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	rays.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rays.stretch_mode = TextureRect.STRETCH_SCALE
	rays.size = Vector2(2100, 1180)
	rays.position = Vector2(-90, -50)
	rays.pivot_offset = rays.size / 2.0
	rays.material = _additive()
	rays.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rays_layer.add_child(rays)
	var grade_layer: CanvasLayer = CanvasLayer.new()
	grade_layer.layer = 3
	add_child(grade_layer)
	var grade: ColorRect = ColorRect.new()
	grade.size = Vector2(1920, 1080)
	grade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grade_mat = ShaderMaterial.new()
	grade_mat.shader = GRADE_SHADER
	grade.material = grade_mat
	grade_layer.add_child(grade)


# ------------------------------------------------------------------ каждый кадр

## Колёсико мыши: приблизить / отдалить камеру (когда не открыта книга или котёл)
func _unhandled_input(event: InputEvent) -> void:
	if Game.ui_open:
		return
	if event is InputEventKey and event.pressed and not event.echo and KB.is_key("interact", (event as InputEventKey).physical_keycode) and Game.has_tool("net") and player.get("target") == null:
		swing_net()
		return
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		var mb: InputEventMouseButton = event
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_target = minf(ZOOM_MAX, zoom_target * 1.15)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_target = maxf(ZOOM_MIN, zoom_target / 1.15)


func _process(delta: float) -> void:
	# совсем без сил — падает и просыпается дома
	if Game.fatigue >= 1.0 and not Game.busy and not Game.ui_open and not Game.god_mode:
		_faint()
	# плавное приближение к выбранному масштабу
	if cam != null and absf(cam.zoom.x - zoom_target) > 0.001:
		var zn: float = lerpf(cam.zoom.x, zoom_target, 1.0 - exp(-14.0 * delta))
		if absf(zn - zoom_target) < 0.01:
			zn = zoom_target
		cam.zoom = Vector2(zn, zn)
	_update_light()
	_update_visit(delta)
	_update_visitors()
	_update_bushes(delta)
	_update_mop()
	_update_net()
	# стыдно — лицо смущённое, пока не пройдёт
	if Game.shame > 0.3 and float(player.get("expr_t")) <= 0.0:
		player.call("react", "shy", 0.6)
	# дверь: войти — подойти к ней вплотную; выйти — шагнуть к двери внутри
	if not Game.busy and not Game.ui_open:
		if inside:
			if player.position.y - IN_ORG.y > 288.0:
				exit_house()
		elif player.position.y - home_off().y > 340.0 and player.position.y - home_off().y < 358.0 and absf(player.position.x - LAY.DOOR_POS.x - home_off().x) < 14.0 \
				and KB.down("move_up"):
			enter_house()
	t_arrow += delta
	var tgv: Variant = player.get("target")
	if tgv != null and is_instance_valid(tgv) and not (tgv as Node).is_queued_for_deletion() and not Game.ui_open and not Game.busy:
		var tg: Node2D = tgv
		arrow.visible = String(tg.call("get_prompt")) != ""
		var off: Vector2 = Vector2(tg.get("interact_offset"))
		arrow.position = (tg.global_position + off + Vector2(0, -34 - absf(sin(t_arrow * 4.0)) * 5.0)).round()
	else:
		arrow.visible = false


func _sky_color(h: float) -> Color:
	for i in range(SKY.size() - 1):
		var a: Array = SKY[i]
		var b: Array = SKY[i + 1]
		if h >= float(a[0]) and h <= float(b[0]):
			var t: float = (h - float(a[0])) / maxf(0.001, float(b[0]) - float(a[0]))
			return (a[1] as Color).lerp(b[1], t)
	return Color.WHITE


func char_light_mat(frames: Vector2, spr: Sprite2D) -> ShaderMaterial:
	var m: ShaderMaterial = ShaderMaterial.new()
	m.shader = CHAR_LIGHT
	m.set_shader_parameter("frames", frames)
	char_mats.append(m)
	char_targets.append([spr, m])
	return m


## Волосы и плащ — отдельные слои-спрайты над/под телом, качаются ветром (см. char_light.gdshader).
## Исходный спрайт остаётся для теней, но сам невидим: тело рисует слой _body.
## v16: одежда на героине — лист кадров по надетому: тело (без одежды — бельё) и обувь (без неё — босиком)
const OUTFIT_KEYS: Array = ["none", "rags", "dress", "cloak_travel", "lab_coat", "apron"]
var outfit_now: String = ""


func outfit_key() -> String:
	var body: String = Game.worn("body")
	var key: String = "none" if body == "" else (body if OUTFIT_KEYS.has(body) else "dress")
	return key + ("_bare" if Game.worn("feet") == "" else "")


func apply_outfit() -> void:
	if player == null:
		return
	var key: String = outfit_key()
	if key == outfit_now:
		return
	var path: String = "res://art/player_%s.png" % key
	if not ResourceLoader.exists(path):
		return
	outfit_now = key
	var spr0: Sprite2D = player.get("sprite") as Sprite2D
	spr0.texture = load(path)
	var bust_key: String = key.trim_suffix("_bare")
	var bp: String = "res://art/bust_%s.png" % bust_key
	var bs: Variant = player.get("bust")
	if bs != null and ResourceLoader.exists(bp):
		(bs as Sprite2D).texture = load(bp)
	for pair in wind_layers:
		if pair[0] == spr0:
			var l: Sprite2D = pair[1]
			for part in ["cape", "body", "hair"]:
				if String(l.texture.resource_path).ends_with("_%s.png" % part):
					l.texture = load("res://art/player_%s_%s.png" % [key, part])
					break


func build_wind_layers(base: Sprite2D, sheet: String, frames: Vector2) -> void:
	if not Game.WIND_ENABLED:
		return
	var stem: String = sheet.trim_suffix(".png")
	if not ResourceLoader.exists(stem + "_body.png"):
		return
	var parts: Array = [["cape", 2, true], ["body", 0, false], ["hair", 1, false]]
	var idx: int = 0
	for pr in parts:
		var l: Sprite2D = Sprite2D.new()
		l.texture = load("%s_%s.png" % [stem, pr[0]])
		l.hframes = base.hframes
		l.vframes = base.vframes
		l.centered = base.centered
		l.offset = base.offset
		if int(pr[1]) > 0:
			l.offset.x -= 48.0   # у слоёв ветра с каждой стороны поля 48 пикселей
		l.show_behind_parent = bool(pr[2])
		var lm: ShaderMaterial = char_light_mat(frames, base)
		lm.set_shader_parameter("wind_part", int(pr[1]))
		if int(pr[1]) > 0:
			lm.set_shader_parameter("frame_w", 176.0)
		l.material = lm
		base.add_child(l)
		base.move_child(l, idx)
		idx += 1
		wind_layers.append([base, l])
	base.self_modulate = Color(1, 1, 1, 0)


func _sync_wind_layers() -> void:
	for pair in wind_layers:
		var b: Variant = pair[0]
		if is_instance_valid(b):
			(pair[1] as Sprite2D).frame = (b as Sprite2D).frame


func _tex_img(t: Texture2D) -> Image:
	if not img_cache.has(t):
		img_cache[t] = t.get_image()
	return img_cache[t]


## Закрывает ли предмет src точку тела на высоте h, чья тень падает в Q
func _blocks(src: Sprite2D, q: Vector2, h: float, basis_y: Vector2) -> bool:
	var sc: Vector2 = src.global_scale
	var tr: Transform2D = Transform2D(Vector2(sc.x, 0), basis_y * sc.y, src.global_position)
	var lp: Vector2 = tr.affine_inverse() * q
	if -lp.y * sc.y <= h + 2.0:
		return false
	var tex: Texture2D = src.texture
	var fw: int = tex.get_width() / src.hframes
	var fh: int = tex.get_height() / src.vframes
	var u: int = int(floor(lp.x - src.offset.x))
	var v: int = int(floor(lp.y - src.offset.y))
	if u < 0 or v < 0 or u >= fw or v >= fh:
		return false
	if src.flip_h:
		u = fw - 1 - u
	var img: Image = _tex_img(tex)
	var fx: int = (src.frame % src.hframes) * fw
	var fy: int = (src.frame / src.hframes) * fh
	return img.get_pixel(fx + u, fy + v).a > 0.5


## Тени от предметов на персонажах: сетка 8 точек по высоте x 3 по ширине
func _char_shadows(basis_y: Vector2, k: float) -> void:
	var pp: Vector2 = player.global_position
	# предметы рядом с героиней (один проход по спискам вместо прохода на каждого персонажа)
	var pool: Array = []
	if k > 0.01:
		for lst in [casters_static, casters_dyn, world.call("casters_near", pp)]:
			for c in lst:
				var cr: Variant = c[0]
				if not is_instance_valid(cr):
					continue
				var cs0: Sprite2D = cr
				if absf(cs0.global_position.x - pp.x) < 1300.0 and absf(cs0.global_position.y - pp.y) < 900.0 and cs0.is_visible_in_tree():
					pool.append(cs0)
	var done: Dictionary = {}
	# лаги: раньше тени пересчитывались всем персонажам каждые 0,12 с. Теперь — только сдвинувшимся (или при смене солнца)
	# и не больше SHADE_BUDGET за один раз; остальные досчитаются на следующих проходах
	var sun_changed: bool = basis_y.distance_to(shade_basis) > 0.02 or absf(k - shade_kk) > 0.05
	if sun_changed:
		shade_basis = basis_y
		shade_kk = k
		shade_pos.clear()
	var budget: int = SHADE_BUDGET
	var pi: int = char_targets.size() - 1
	while pi >= 0:
		if not is_instance_valid((char_targets[pi] as Array)[0]):
			char_targets.remove_at(pi)
		pi -= 1
	for dead in shade_pos.keys():
		if not is_instance_valid(dead):
			shade_pos.erase(dead)
	var n_t: int = char_targets.size()
	var start: int = randi() % maxi(1, n_t)
	var step_i: int = 0
	while step_i < n_t:
		var i0: int = (start + step_i) % n_t
		step_i += 1
		if i0 >= char_targets.size():
			continue
		var pair: Array = char_targets[i0]
		var raw: Variant = pair[0]
		if not is_instance_valid(raw):
			continue
		var spr: Sprite2D = raw
		var mat: ShaderMaterial = pair[1]
		if not spr.is_visible_in_tree() or absf(spr.global_position.x - pp.x) > 1000.0 or absf(spr.global_position.y - pp.y) > 700.0:
			continue
		if done.has(spr):
			mat.set_shader_parameter("shade", done[spr])
			mat.set_shader_parameter("shade_k", k)
			continue
		var sp_pos: Vector2 = spr.global_position
		if shade_pos.has(spr) and (shade_pos[spr] as Vector2).distance_to(sp_pos) < 5.0:
			continue          # не двигалась — старые тени остаются
		if budget <= 0:
			continue
		budget -= 1
		shade_pos[spr] = sp_pos
		var vals: PackedFloat32Array = PackedFloat32Array()
		vals.resize(24)
		if k > 0.01:
			var p: Vector2 = spr.global_position
			var near: Array = []
			for cs1 in pool:
				if cs1 != spr and (cs1 as Sprite2D).global_position.distance_to(p) < 340.0:
					near.append(cs1)
			var ks: float = spr.scale.x / 0.5   # масштаб персонажа относительно «большого» (0.5)
			for row in range(8):
				var hh: float = lerpf(74.0, 3.0, row / 7.0) * ks
				for col in range(3):
					var q: Vector2 = p + Vector2((col - 1) * 7.0 * ks, 0.0) - hh * basis_y
					for cs2 in near:
						if _blocks(cs2, q, hh, basis_y):
							vals[row * 3 + col] = 1.0
							break
		done[spr] = vals
		mat.set_shader_parameter("shade", vals)
		mat.set_shader_parameter("shade_k", k)


func _update_light() -> void:
	var h: float = Game.hour()
	var in_club: bool = live != null and bool(live.get("active"))
	var in_realm: bool = player.position.y < -150000.0
	var out: float = 0.0 if (inside or in_club or in_realm or player.position.x > 150000.0 or player.position.y > 120000.0) else 1.0     # дома, в подземелье и шахте нет солнца, теней и лучей
	var n: float = Game.night_factor()
	if in_realm and not inside and visiting == null:
		# v24: в Аду — багровый отсвет лавы, в Раю — светлое золотистое сияние; солнца там нет
		canvas_mod.color = Color(1.0, 0.72, 0.66) if Game.realm == "hell" else Color(1.04, 1.02, 1.06)
	elif in_club:
		canvas_mod.color = Color(1.0, 0.93, 1.06)     # клуб: светлый, тёплый, прожекторы сверху
	elif inside:
		canvas_mod.color = Color(1.0, 0.92, 0.80).lerp(Color(0.52, 0.44, 0.54), n)
		_update_in_lights(n)
	else:
		# в сумрачных краях (готика, паутинный лес) свет плавно темнеет и лиловеет
		var want_tint: Color = (world.call("ambient_tint", player.position) as Color) * preload("res://events_db.gd").tint(Game.day)
		biome_tint = biome_tint.lerp(want_tint, clampf(get_process_delta_time() * 1.2, 0.0, 1.0))
		canvas_mod.color = _sky_color(h) * biome_tint
		if Game.in_sea:
			canvas_mod.color = canvas_mod.color.lerp(Color(0.52, 0.70, 1.0), n * 0.62)    # v22: ночью под водой светлее, чтобы видеть травы
	var st: float = Game.sun_t()
	var el: float = Game.sun_elevation()
	var gold: float = Game.golden()
	# тени: утром на запад, днём короткие, вечером длинные на восток
	var dir: Vector2 = Vector2(-cos(st * PI) * 0.9 + 0.3, -0.55).normalized()
	var L: float = 0.55 + (1.0 - el) * 0.95
	var basis_y: Vector2 = Vector2(-L * dir.x, -L * dir.y)
	var alpha: float = 0.40 * smoothstep(0.0, 0.22, el) * out
	shadow_group.modulate = Color(1, 1, 1, alpha)
	shadow_group.visible = alpha > 0.01
	shadow_mat.set_shader_parameter("shadow_rgb", Color(0.30, 0.24, 0.48).lerp(Color(0.40, 0.22, 0.42), gold))
	var key: Vector3 = Vector3(snappedf(basis_y.x, 0.01), snappedf(basis_y.y, 0.01), 0)
	if key != sun_cache:
		sun_cache = key
		_update_casters(casters_static, basis_y, false)
		world.call("update_shadows", basis_y)
	_update_casters(casters_dyn, basis_y, true)
	# лучи и тёплое свечение со стороны солнца
	var ray_a: float = (gold * 0.42 + (1.0 - gold) * 0.10 * el) * (1.0 - n) * out
	rays.modulate = Color(1.0, 0.86, 0.62, ray_a * (0.9 + sin(Time.get_ticks_msec() * 0.0007) * 0.1))
	rays.flip_h = st < 0.5
	rays.position.x = -90.0 + sin(Time.get_ticks_msec() * 0.00025) * 40.0
	grade_mat.set_shader_parameter("sun_pos", Vector2(1.15 - st * 1.3, 0.08 - 0.42 * el))
	grade_mat.set_shader_parameter("sun_glow", (0.16 + gold * 0.22) * (1.0 - n) * out)
	grade_mat.set_shader_parameter("sun_color", Color(1.0, 0.86, 0.62).lerp(Color(1.0, 0.66, 0.56), gold * 0.6))
	# солнце на персонажах: с той же стороны, откуда падают тени
	var sun_x: float = clampf(cos(st * PI) * 0.9 - 0.3, -1.0, 1.0)
	var sun_k: float = smoothstep(0.0, 0.2, el) * (1.0 - n) * out
	var sun_c: Color = Color(1.0, 0.9, 0.72).lerp(Color(1.0, 0.68, 0.5), gold * 0.8)
	var sk: Vector4 = Vector4(snappedf(sun_x, 0.02), snappedf(el, 0.02), snappedf(sun_k, 0.02), snappedf(gold, 0.02))
	sun_t2 -= get_process_delta_time()
	var mats_now: Array = char_mats if sk != sun_key or sun_t2 <= 0.0 else []
	if not mats_now.is_empty():
		sun_key = sk
		sun_t2 = 1.0
	for cm in mats_now:
		var mat: ShaderMaterial = cm
		mat.set_shader_parameter("sun_x", sun_x)
		mat.set_shader_parameter("elevation", el)
		mat.set_shader_parameter("strength", sun_k)
		mat.set_shader_parameter("golden", gold)
		mat.set_shader_parameter("sun_color", sun_c)
	shade_t -= get_process_delta_time()
	if shade_t <= 0.0:
		shade_t = 0.12
		_char_shadows(basis_y, alpha / 0.40)
	grade_mat.set_shader_parameter("lift", Color(0.10, 0.07, 0.13).lerp(Color(0.06, 0.07, 0.16), n))
	var flick: float = 0.94 + sin(Time.get_ticks_msec() * 0.011) * 0.03 + sin(Time.get_ticks_msec() * 0.027) * 0.03
	var lamp: float = maxf(n, smoothstep(18.6, 20.0, h) * 0.8 if h > 12.0 else 0.0)
	grade_mat.set_shader_parameter("pastel", lerpf(0.12, 0.05, smoothstep(18.5, 20.5, h) * (1.0 - n * 0.5)))
	for g in glows:
		var s: Sprite2D = g[0]
		s.modulate.a = lamp * float(g[1]) * flick
	fireflies.modulate.a = n
	leaves.modulate.a = 1.0 - n * 0.7
	_update_wind_fx()
	_sync_wind_layers()


## Листья и дым летят по ветру: сильный ветер — быстрее и ниже, дым наклоняется
func _update_wind_fx() -> void:
	if not Game.WIND_ENABLED:
		return
	var w: float = Game.wind
	var d: float = Game.wind_dir
	leaves.gravity = Vector2(4.0 + d * w * 120.0, 9.0 + w * 8.0)
	leaves.direction = Vector2(d, 0.3)
	leaves.initial_velocity_min = 8.0 + w * 40.0
	leaves.initial_velocity_max = 18.0 + w * 90.0
	leaves.angular_velocity_max = 140.0 + w * 420.0
	leaves.angular_velocity_min = -leaves.angular_velocity_max
	if smoke != null:
		smoke.gravity = Vector2(5.0 + d * w * 70.0, -3.0)


func _update_casters(list: Array, basis_y: Vector2, dynamic: bool) -> void:
	var i: int = list.size() - 1
	while i >= 0:
		var pair: Array = list[i]
		var raw: Variant = pair[0]
		var sh: Sprite2D = pair[1]
		if not is_instance_valid(raw) or (raw as Node).is_queued_for_deletion():
			sh.queue_free()
			list.remove_at(i)
			i -= 1
			continue
		var src: Sprite2D = raw
		var vis: bool = src.is_visible_in_tree()
		sh.visible = vis
		if vis:
			if dynamic:
				_copy_look(src, sh)
			var sc: Vector2 = src.global_scale
			sh.transform = Transform2D(Vector2(sc.x, 0), basis_y * sc.y, src.global_position)
		i -= 1


# ------------------------------------------------------------------ жители и заказы

## Утром приходит житель с бедой, вечером уходит домой.
func _update_visitors() -> void:
	if Game.busy:
		return
	var h: float = Game.hour()
	var v: Node = get_tree().get_first_node_in_group("villagers")
	# заказчицы ходят по тропе старого двора — к дому в другом биоме они не приходят
	if v == null and Game.order.is_empty() and home_in_yard() and h >= 8.5 and h < 17.5 and last_order_day != Game.day:
		spawn_visitor()
	elif v != null and h >= 19.0 and not bool(v.get("leaving")):
		v.call("leave")
		Game.order = {}
		hud.call("say", String(v.get("info")["name"]), "Уже темнеет, пойду домой. Загляну в другой раз!")


func spawn_visitor(product: String = "", walk_in: bool = true) -> Node2D:
	last_order_day = Game.day
	var vi: Dictionary = RDB.VILLAGERS[rng.randi_range(0, RDB.VILLAGERS.size() - 1)]
	var keys: Array = RDB.ASKS.keys()
	var p: String = product if product != "" else String(keys[rng.randi_range(0, keys.size() - 1)])
	Game.order = {"who": vi["id"], "name": vi["name"], "product": p, "reward": 10 + rng.randi_range(0, 3) * 4, "day": Game.day}
	var v: Node2D = Node2D.new()
	v.set_script(load("res://villager.gd"))
	v.position = VISIT_POS
	objects.add_child(v)
	v.call("setup", vi)
	add_caster(v.get("spr") as Sprite2D, true)
	(v.get("spr") as Sprite2D).material = char_light_mat(Vector2(8, 8), v.get("spr") as Sprite2D)
	build_wind_layers(v.get("spr") as Sprite2D, String((v.get("info") as Dictionary)["tex"]), Vector2(8, 8))
	var vfm: ShaderMaterial = char_light_mat(Vector2(1, 1), v.get("spr") as Sprite2D)
	vfm.set_shader_parameter("region_mode", true)
	(v.get("face") as Sprite2D).material = vfm
	v.set("face_mat", vfm)
	if walk_in:
		# приходит по тропе от калитки к дому
		v.call("arrive_walking")
		Game.toast.emit("К дому идёт %s" % String(vi["name"]).split(",")[0], load("res://art/fx_heart.png"))
	else:
		v.modulate.a = 0.0
		create_tween().tween_property(v, "modulate:a", 1.0, 1.0)
		Game.toast.emit("Пришла %s" % String(vi["name"]).split(",")[0], load("res://art/fx_heart.png"))
		player.call("react", "surprised", 1.0)
	return v


func _on_target_changed(t: Node2D) -> void:
	if t == null or not is_instance_valid(t):
		hud.call("set_prompt", "")
	else:
		hud.call("set_prompt", String(t.call("get_prompt")))


# ------------------------------------------------------------------ события

func _faint() -> void:
	Game.busy = true
	hud.call("set_prompt", "")
	get_tree().call_group("player", "react", "sad", 2.0)
	await get_tree().create_timer(0.6).timeout
	var tw: Tween = hud.call("fade_out", "Без сил...")
	await tw.finished
	Game.next_day()
	Game.minutes = 10.0 * 60.0        # проспала дольше обычного
	Game.hunger = minf(1.0, Game.hunger + 0.15)
	_spawn_herbs()
	_return_mop()
	_set_inside(true, IN_ORG + IN_WAKE)
	(hud.get("fade_label") as Label).text = "День %d" % Game.day
	await get_tree().create_timer(0.8).timeout
	var tw2: Tween = hud.call("fade_in")
	await tw2.finished
	Game.busy = false


## Ночёвка в гостях: утром героиня просыпается в комнате хозяйки, хозяйка желает доброго утра
func guest_sleep() -> void:
	if Game.busy or visiting == null:
		return
	Game.busy = true
	guest_stay = true
	hud.call("set_prompt", "")
	var tw: Tween = hud.call("fade_out", "Доброй ночи...")
	await tw.finished
	Game.next_day()
	_sea_gifts()
	_spawn_herbs()
	_return_mop()
	_return_net()
	visit_t = 0.0
	visit_warned = 0
	player.position = ROOM_ORG + Vector2(320, 262)
	(hud.get("fade_label") as Label).text = "День %d" % Game.day
	await get_tree().create_timer(0.8).timeout
	var tw2: Tween = hud.call("fade_in")
	await tw2.finished
	Game.busy = false
	if visiting != null:
		hud.call("say", String(visiting.get("owner_name")), "Доброе утро! Выспалась? Позавтракай и заходи ещё.")
	_autosave()


func _on_sleep() -> void:
	if Game.busy:
		return
	Game.busy = true
	hud.call("set_prompt", "")
	var tw: Tween = hud.call("fade_out", "Доброй ночи...")
	await tw.finished
	Game.next_day()
	_spawn_herbs()
	_return_mop()
	_return_net()
	_set_inside(true, IN_ORG + IN_WAKE)
	(hud.get("fade_label") as Label).text = "День %d" % Game.day
	await get_tree().create_timer(0.8).timeout
	var tw2: Tween = hud.call("fade_in")
	await tw2.finished
	Game.busy = false
	_autosave()


## v29: пока спишь, море приносит подарки: ракушки, стёклышки, иногда жемчужина
func _sea_gifts() -> void:
	var pool: Array = [["shell", 1.0], ["sea_glass", 0.6], ["starfish", 0.4], ["conch", 0.35], ["coral_piece", 0.25], ["sea_salt", 0.5], ["pearl", 0.06]]
	for g in pool:
		if randf() < float(g[1]) * 0.6:
			Game.add_item(String(g[0]), 1)


# ------------------------------------------------------------------ ранний доступ: сохранения

func _autosave() -> void:
	if playing and Saves.can_save() and not OS.get_cmdline_user_args().has("--test"):
		Saves.save_game()


## Можно сохраняться: не в гостях, не под водой, не в шахте, не в тюрьме
func can_save() -> bool:
	if not playing or Game.busy or visiting != null:
		return false
	if sea != null and bool(sea.get("diving")):
		return false
	if live != null and bool(live.get("active")):
		return false
	if mine != null and bool(mine.get("inside")):
		return false
	if player.position.y < -150000.0:
		return false
	var dn23: Node = get_node_or_null("V23/Dungeon23")
	if dn23 != null and bool(dn23.get("active")):
		return false
	var lw: Node = get_tree().get_first_node_in_group("law18")
	if lw != null and bool(lw.get("jailed")):
		return false
	return true


## Мир для сохранения (Game сохраняется отдельно — в saves.gd)
func save_world() -> Dictionary:
	var w: Dictionary = {}
	w["player"] = player.position
	w["inside"] = inside
	w["last_order_day"] = last_order_day
	var pl: Array = []
	for p in (homestead.get("placed") as Array):
		pl.append([String(p[0]), p[1]])
	w["placed"] = pl
	var plots: Array = []
	for n in get_tree().get_nodes_in_group("plots"):
		var pn: Node2D = n
		plots.append({"pos": pn.position, "crop": String(pn.get("crop")), "stage": int(pn.get("stage")), "watered": bool(pn.get("watered")),
			"pollinated": bool(pn.get("pollinated")), "aphids": int(pn.get("aphids"))})
	w["plots"] = plots
	var qn: Node = get_tree().get_first_node_in_group("quests18")
	if qn != null:
		var act: Array = []
		for q in (qn.get("active") as Array):
			var qd: Dictionary = {}
			for k in (q as Dictionary).keys():
				if not ((q as Dictionary)[k] is Object):
					qd[k] = (q as Dictionary)[k]
			act.append(qd.duplicate(true))
		w["quests"] = {"active": act, "done_count": int(qn.get("done_count")), "cooldown": (qn.get("cooldown") as Dictionary).duplicate(true), "next_id": int(qn.get("next_id"))}
	var lw: Node = get_tree().get_first_node_in_group("law18")
	if lw != null:
		w["law"] = {"heat": (lw.get("heat") as Dictionary).duplicate(true), "arrests": int(lw.get("arrests"))}
	return w


## Сразу после homestead.setup: постройки и грядки (до того, как двор достроит колодец)
func _load_world_early(w: Dictionary) -> void:
	for p in (w.get("placed", []) as Array):
		var kind: String = String(p[0])
		if IT.BUILD.has(kind):
			homestead.call("build", kind, p[1])
	restore_plots(w)
	last_order_day = int(w.get("last_order_day", 0))


func restore_plots(w: Dictionary) -> void:
	for pd in (w.get("plots", []) as Array):
		var d: Dictionary = pd
		var best: Node2D = null
		var bd: float = 12.0
		for n in get_tree().get_nodes_in_group("plots"):
			var dd: float = (n as Node2D).position.distance_to(d["pos"])
			if dd < bd:
				bd = dd
				best = n
		if best != null:
			best.set("crop", String(d["crop"]))
			best.set("stage", int(d["stage"]))
			best.set("watered", bool(d["watered"]))
			best.set("pollinated", bool(d.get("pollinated", false)))
			best.set("aphids", int(d.get("aphids", 0)))
			best.call("refresh")


## В конце _ready: где стоит героиня, задания, закон, питомцы
func _load_world_late(w: Dictionary) -> void:
	var pos: Vector2 = w.get("player", player.position)
	if bool(w.get("inside", false)):
		_set_inside(true, pos)
	else:
		world.call("build_around", pos)
		player.position = free_near(pos)
		_world_limits()
		cam.reset_smoothing()
	var qn: Node = get_tree().get_first_node_in_group("quests18")
	var qd: Dictionary = w.get("quests", {})
	if qn != null and not qd.is_empty():
		qn.set("active", (qd.get("active", []) as Array).duplicate(true))
		qn.set("done_count", int(qd.get("done_count", 0)))
		qn.set("cooldown", (qd.get("cooldown", {}) as Dictionary).duplicate(true))
		qn.set("next_id", int(qd.get("next_id", 1)))
		for q in (qn.get("active") as Array):
			if String((q as Dictionary).get("type", "")) == "cat" and not bool((q as Dictionary).get("found", false)) and (q as Dictionary).has("cat_pos"):
				qn.call("_spawn_cat", q)
	var lw: Node = get_tree().get_first_node_in_group("law18")
	var ld: Dictionary = w.get("law", {})
	if lw != null and not ld.is_empty():
		lw.set("heat", (ld.get("heat", {}) as Dictionary).duplicate(true))
		lw.set("arrests", int(ld.get("arrests", 0)))
	var sh: Node = get_tree().get_first_node_in_group("shelters18")
	if sh != null:
		var i: int = 0
		for pt in Game.pets:
			sh.call("spawn_pet", String((pt as Dictionary).get("kind", "cat:ginger")), player.position + Vector2(26 + i * 14, 18))
			i += 1
	# спутницы — жительницы городов: после загрузки они дома, их можно позвать снова
	if not Game.team.is_empty():
		Game.team.clear()
		Game.team_changed.emit()
	Game.inventory_changed.emit()
	Game.equip_changed.emit()
	apply_outfit()
	_update_light()


func _on_fx(pos: Vector2, kind: String) -> void:
	if kind == "zzz":
		# зевает: значок сна всплывает над головой
		var z: Sprite2D = Sprite2D.new()
		z.texture = load("res://art/need_sleep.png")
		z.position = pos
		z.z_index = 45
		add_child(z)
		var tz: Tween = create_tween().set_parallel(true)
		tz.tween_property(z, "position:y", pos.y - 20.0, 1.4)
		tz.tween_property(z, "modulate:a", 0.0, 1.4).set_delay(0.5)
		tz.chain().tween_callback(z.queue_free)
		return
	if kind == "water":
		Sound.play("water", -6.0, 0.1, pos)
	if kind == "heart":
		var h: Sprite2D = Sprite2D.new()
		h.texture = load("res://art/fx_heart.png")
		h.position = pos
		h.z_index = 45
		add_child(h)
		var tw: Tween = create_tween().set_parallel(true)
		tw.tween_property(h, "position:y", pos.y - 26.0, 1.4)
		tw.tween_property(h, "modulate:a", 0.0, 1.4).set_delay(0.4)
		tw.chain().tween_callback(h.queue_free)
		return
	var p: CPUParticles2D = CPUParticles2D.new()
	p.position = pos
	p.one_shot = true
	p.explosiveness = 0.9
	p.z_index = 45
	p.color_ramp = _fade_ramp()
	match kind:
		"leaves":
			p.texture = load("res://art/fx_leaf.png")
			p.amount = 14
			p.lifetime = 0.9
			p.spread = 180.0
			p.direction = Vector2(0, -1)
			p.initial_velocity_min = 30.0
			p.initial_velocity_max = 60.0
			p.gravity = Vector2(0, 90)
			p.angular_velocity_min = -300.0
			p.angular_velocity_max = 300.0
		"water":
			p.texture = load("res://art/fx_drop.png")
			p.amount = 16
			p.lifetime = 0.7
			p.spread = 50.0
			p.direction = Vector2(0, -1)
			p.initial_velocity_min = 30.0
			p.initial_velocity_max = 55.0
			p.gravity = Vector2(0, 180)
			p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
			p.emission_rect_extents = Vector2(28, 6)
		"sparks":
			p.texture = load("res://art/fx_soft.png")
			p.amount = 10
			p.lifetime = 0.4
			p.spread = 70.0
			p.direction = Vector2(0, -1)
			p.initial_velocity_min = 40.0
			p.initial_velocity_max = 80.0
			p.gravity = Vector2(0, 200)
			p.scale_amount_min = 0.02
			p.scale_amount_max = 0.04
			p.color = Color(1.0, 0.75, 0.3)
			p.material = _additive()
		"steam", "steam_green", "foam":
			# пар из печи, котла и кружки: поднимается и тает
			p.texture = load("res://art/fx_soft.png")
			p.amount = 8
			p.lifetime = 1.4
			p.explosiveness = 0.3
			p.spread = 25.0
			p.direction = Vector2(0, -1)
			p.initial_velocity_min = 10.0
			p.initial_velocity_max = 22.0
			p.gravity = Vector2(Game.wind_dir * 6.0, -8)
			p.scale_amount_min = 0.12
			p.scale_amount_max = 0.24
			p.color = {"steam": Color(1, 0.97, 0.92, 0.55), "steam_green": Color(0.62, 1.0, 0.6, 0.6), "foam": Color(1, 1, 0.94, 0.8)}[kind]
			p.z_index = 0
		"chaff", "chips":
			# колоски из-под серпа, щепки из-под топора
			p.texture = load("res://art/fx_leaf.png")
			p.amount = 7
			p.lifetime = 0.7
			p.spread = 80.0
			p.direction = Vector2(0, -1)
			p.initial_velocity_min = 25.0
			p.initial_velocity_max = 55.0
			p.gravity = Vector2(0, 160)
			p.angular_velocity_min = -400.0
			p.angular_velocity_max = 400.0
			p.scale_amount_min = 0.5
			p.scale_amount_max = 0.8
			p.color = Color(0.96, 0.84, 0.42) if kind == "chaff" else Color(0.78, 0.58, 0.36)
		"cream", "sparkle":
			# сливочные брызги и волшебные искорки
			p.texture = load("res://art/fx_soft.png")
			p.amount = 9
			p.lifetime = 0.8
			p.spread = 180.0
			p.direction = Vector2(0, -1)
			p.initial_velocity_min = 12.0
			p.initial_velocity_max = 30.0
			p.gravity = Vector2(0, 20 if kind == "cream" else -10)
			p.scale_amount_min = 0.03
			p.scale_amount_max = 0.06
			p.color = Color(1.0, 0.86, 0.92) if kind == "cream" else Color(0.7, 0.8, 1.0)
			p.material = _additive()
		"dust":
			# облачко пыли из-под ботинок на бегу: бледное, стелется по земле
			p.texture = load("res://art/fx_soft.png")
			p.amount = 5
			p.lifetime = 0.5
			p.spread = 60.0
			p.direction = Vector2(0, -1)
			p.initial_velocity_min = 6.0
			p.initial_velocity_max = 14.0
			p.gravity = Vector2(0, 10)
			p.scale_amount_min = 0.05
			p.scale_amount_max = 0.09
			p.color = Color(0.86, 0.78, 0.62, 0.55)
			p.z_index = 0
		_:
			p.texture = load("res://art/fx_soft.png")
			p.amount = 12
			p.lifetime = 0.6
			p.spread = 70.0
			p.direction = Vector2(0, -1)
			p.initial_velocity_min = 20.0
			p.initial_velocity_max = 40.0
			p.gravity = Vector2(0, 120)
			p.scale_amount_min = 0.08
			p.scale_amount_max = 0.14
			p.color = Color("6e4729")
	add_child(p)
	p.emitting = true
	get_tree().create_timer(2.0).timeout.connect(p.queue_free)


# ------------------------------------------------------------------ автотест

func _check(ok: bool, name: String, fails: Array) -> void:
	print(("  OK   " if ok else "  FAIL ") + name)
	if not ok:
		fails.append(name)


func _run_tests() -> void:
	var fails: Array = []
	await get_tree().process_frame
	print("TEST: начало")
	if OS.get_cmdline_user_args().has("--only28"):
		await get_tree().create_timer(0.5).timeout
		await preload("res://test28.gd").new().run(self, fails)
		print("TEST: итого ошибок %d" % fails.size())
		get_tree().quit(1 if fails.size() > 0 else 0)
		return
	if OS.get_cmdline_user_args().has("--only26cats"):
		await get_tree().create_timer(0.5).timeout
		await preload("res://test26cats.gd").new().run(self, fails)
		print("TEST: итого ошибок %d" % fails.size())
		get_tree().quit(1 if fails.size() > 0 else 0)
		return
	if OS.get_cmdline_user_args().has("--only26"):
		await get_tree().create_timer(0.5).timeout
		await preload("res://test26.gd").new().run(self, fails)
		print("TEST: итого ошибок %d" % fails.size())
		get_tree().quit(1 if fails.size() > 0 else 0)
		return
	if OS.get_cmdline_user_args().has("--only25"):
		await get_tree().create_timer(0.5).timeout
		await preload("res://test25.gd").new().run(self, fails)
		print("TEST: итого ошибок %d" % fails.size())
		get_tree().quit(1 if fails.size() > 0 else 0)
		return
	if OS.get_cmdline_user_args().has("--only24"):
		await get_tree().create_timer(0.5).timeout
		await preload("res://test24.gd").new().run(self, fails)
		print("TEST: итого ошибок %d" % fails.size())
		get_tree().quit(1 if fails.size() > 0 else 0)
		return
	if OS.get_cmdline_user_args().has("--only23"):
		await get_tree().create_timer(0.5).timeout
		await _test_v23(fails)
		print("TEST: итого ошибок %d" % fails.size())
		get_tree().quit(1 if fails.size() > 0 else 0)
		return
	insects.set("aphid_chance", 0.0)
	# огород: посадить, полить, вырастить, собрать
	var plot: Node2D = get_tree().get_nodes_in_group("plots")[0]
	var seeds_before: int = int(Game.seeds["mint"])
	plot.call("interact")
	_check(String(plot.get("crop")) == "mint", "посадка мяты", fails)
	_check(int(Game.seeds["mint"]) == seeds_before - 1, "семя потрачено", fails)
	for d in range(3):
		plot.call("interact")
		_check(bool(plot.get("watered")), "полив, день %d" % (d + 1), fails)
		Game.next_day()
	_check(int(plot.get("stage")) == 3, "мята созрела за 3 дня", fails)
	_check(String(plot.call("get_prompt")) == "Собрать урожай", "подсказка «Собрать урожай»", fails)
	var mint_before: int = Game.get_count("mint")
	plot.call("interact")
	_check(Game.get_count("mint") == mint_before + 3, "урожай +3 мяты", fails)
	_check(String(plot.get("crop")) == "", "грядка снова пустая", fails)
	# без полива не растёт
	plot.call("interact")
	Game.next_day()
	_check(int(plot.get("stage")) == 0, "без полива не растёт", fails)
	# дикая трава
	var herbs: Array = get_tree().get_nodes_in_group("wild_herbs")
	_check(herbs.size() >= 10, "дикие травы появились (%d)" % herbs.size(), fails)
	if herbs.size() > 0:
		var h: Node2D = herbs[0]
		var hid: String = String(h.get("herb_id"))
		var c0: int = Game.get_count(hid)
		h.call("interact")
		var hvu: Node = get_tree().get_first_node_in_group("harvest_ui")
		_check(bool(hvu.get("is_open")), "окно сбора открылось", fails)
		hvu.call("auto_collect_all")
		await get_tree().process_frame
		_check(Game.get_count(hid) >= c0 + 1, "сбор дикой травы", fails)
		# особые травы: без огнеупорных перчаток огненную лилию не взять
		_check(preload("res://harvest_db.gd").missing("fire_lily") == "gloves_fire", "огненной лилии нужны огнеупорные перчатки", fails)
		Game.equip["hands"] = "gloves_fire"
		_check(preload("res://harvest_db.gd").missing("fire_lily") == "", "в огнеупорных перчатках — можно", fails)
		Game.equip.erase("hands")
		var hq: int = 0
		for hid2 in DB.ORDER:
			if preload("res://harvest_db.gd").Q.has(String(hid2)):
				hq += 1
		_check(hq == DB.ORDER.size(), "у каждой травы своя особенность (%d)" % hq, fails)
		_check(Game.discovered.has(hid), "трава записана в книгу", fails)
	# книга
	book.call("open")
	_check(Game.ui_open, "книга открывается", fails)
	book.call("_step", 1)
	book.call("close")
	_check(not Game.ui_open, "книга закрывается", fails)
	# столкновения
	_check(is_blocked(Vector2(960, 300)), "в дом не пройти", fails)
	_check(is_blocked(LAY.POND_C), "в пруд не пройти", fails)
	_check(not is_blocked(Vector2(960, 500)), "по тропе пройти можно", fails)
	_check(not is_blocked(Vector2(960, 400)), "к двери подойти можно", fails)
	# варка v16: все зелья достижимы по своим примерам-рецептам
	var reach_ok: int = 0
	for pid in RDB.PRODUCTS.keys():
		var ex: Array = RDB.PRODUCTS[pid]["ex"]
		if ex.is_empty():
			continue
		var ings_ex: Array = []
		for e in ex[2]:
			ings_ex.append({"id": String(e[0]), "procs": e[1]})
		if RDB.brew_mix(String(ex[0]), String(ex[1]), ings_ex) == String(pid):
			reach_ok += 1
		else:
			print("  не выходит: ", pid)
	_check(reach_ok == RDB.PRODUCTS.size() - 1, "все зелья достижимы (%d из %d)" % [reach_ok, RDB.PRODUCTS.size() - 1], fails)
	_check(RDB.brew_mix("water", "hot", [{"id": "phoenix_grass", "procs": []}, {"id": "phoenix_grass", "procs": []}]) == "phoenix_brew", "отвар феникса из перьев феникса", fails)
	_check(RDB.brew_mix("water", "hot", [{"id": "fire_pepper", "procs": []}, {"id": "fire_pepper", "procs": []}]) != "phoenix_brew", "без пера феникса легенды нет", fails)
	_check(int(RDB.ing_props({"id": "mint", "procs": ["dry"]}).get("Тепло", 0)) == 2, "сушка: свежесть мяты стала теплом", fails)
	Game.inventory["mint"] = 4
	Game.inventory["chamomile"] = 2
	Game.inventory["nettle"] = 2
	_check(Game.brew("water", "mint", "mint") == "clear_tea", "тёплая вода + мята + мята = чай ясной головы", fails)
	_check(Game.get_count("mint") == 2 and Game.get_count("clear_tea") == 1, "травы потрачены, чай в сумке", fails)
	_check(Game.brew("spirit", "mint", "chamomile") == "murky", "неудача = мутный отвар", fails)
	_check(RDB.hint("spirit", "mint", "chamomile") != "", "подсказка после неудачи", fails)
	_check(Game.journal.size() == 2, "журнал попыток записан", fails)
	# сцена варки: наливаем, обрабатываем, мешаем
	brew_ui.call("open")
	_check(Game.ui_open, "котёл открывается", fails)
	Game.cauldron_clear()
	Game.inventory["spirit"] = 1
	Game.inventory["water_hot"] = 1
	for _n in range(2):
		Game.take_item("nettle")
		brew_ui.call("put_in_cauldron", {"id": "nettle", "procs": ["cut"]})
	_check(bool(brew_ui.call("pour", "spirit")), "спирт налит", fails)
	_check(String(brew_ui.call("do_brew")) == "strength_tinct", "спирт + резаная крапива ×2 = крапивная настойка", fails)
	Game.inventory["fire_pepper"] = 2
	brew_ui.call("add_herb", "fire_pepper")
	brew_ui.call("pour", "water_hot")
	_check(Game.cauldron_temp() == "hot", "горячая вода в котле", fails)
	_check(String(brew_ui.call("do_brew")) == "fire_brew", "горячая вода + огнецвет = огненный отвар", fails)
	brew_ui.call("close")
	await get_tree().create_timer(0.4).timeout
	_check(not Game.ui_open, "котёл закрывается", fails)
	# застряла в препятствии (например после глажки) — должна вытолкнуться наружу
	if block_rects.size() > 0:
		var br: Rect2 = block_rects[0]
		player.position = br.position + br.size / 2.0
		await get_tree().physics_frame
		await get_tree().physics_frame
		_check(not is_blocked(player.position), "из препятствия выталкивает наружу", fails)
	# колёсико мыши приближает камеру
	var wev: InputEventMouseButton = InputEventMouseButton.new()
	wev.button_index = MOUSE_BUTTON_WHEEL_UP
	wev.pressed = true
	var z0: float = zoom_target
	_unhandled_input(wev)
	_check(zoom_target > z0, "колёсико вверх приближает камеру", fails)
	wev.button_index = MOUSE_BUTTON_WHEEL_DOWN
	_unhandled_input(wev)
	_check(is_equal_approx(zoom_target, z0), "колёсико вниз отдаляет камеру", fails)
	# заказ жителя
	var vis: Node2D = spawn_visitor("mint_tea", false)
	Game.inventory["mint_tea"] = 0
	vis.call("interact")
	Game.inventory["mint_tea"] = 1
	_check(bool(Game.order.get("met", false)), "житель рассказал, что болит", fails)
	var coins0: int = Game.coins
	_check(String(vis.call("get_prompt")).begins_with("Отдать"), "подсказка «Отдать»", fails)
	vis.call("interact")
	_check(Game.coins > coins0 and Game.order.is_empty(), "заказ выполнен, монеты получены", fails)
	_check(Game.get_count("mint_tea") == 0, "чай отдан", fails)
	# в проверках время бежит быстро — чтобы потребности не мешали, обнуляем
	Game.pee = 0.1
	Game.poo = 0.1
	Game.shame = 0.0
	# маленький шажок: короткое нажатие D
	player.position = Vector2(960, 520)
	await get_tree().physics_frame
	var x0: float = player.position.x
	var ev: InputEventKey = InputEventKey.new()
	ev.physical_keycode = KEY_D
	ev.pressed = true
	Input.parse_input_event(ev)
	for hold_i in range(15):
		await get_tree().physics_frame
	var ev2: InputEventKey = InputEventKey.new()
	ev2.physical_keycode = KEY_D
	ev2.pressed = false
	Input.parse_input_event(ev2)
	for rest_i in range(30):
		await get_tree().physics_frame
	var stepped: float = player.position.x - x0
	_check(stepped > 2.0 and stepped < 16.0, "маленький шажок (%.1f пикс.)" % stepped, fails)
	var sfr: int = int((player.get("sprite") as Sprite2D).frame) % 28
	_check(sfr >= 4 and sfr <= 7, "после шажка — стойка", fails)
	# лицо: выражение меняет кусок атласа
	player.call("react", "happy", 1.0)
	await get_tree().physics_frame
	await get_tree().physics_frame
	_check((player.get("face") as Sprite2D).region_rect.position.y == 4 * 15, "выражение «радость» на лице", fails)
	# диагональ: W+A — ракурс вполоборота вверх-влево
	player.position = Vector2(960, 560)
	for kc in [KEY_W, KEY_A]:
		var e1: InputEventKey = InputEventKey.new()
		e1.physical_keycode = kc
		e1.pressed = true
		Input.parse_input_event(e1)
	await get_tree().create_timer(0.6).timeout
	for kc2 in [KEY_W, KEY_A]:
		var e2: InputEventKey = InputEventKey.new()
		e2.physical_keycode = kc2
		e2.pressed = false
		Input.parse_input_event(e2)
	_check(int(player.get("facing")) == 5, "W+A: идёт вполоборота вверх-влево (ракурс %d)" % int(player.get("facing")), fails)
	await get_tree().create_timer(0.3).timeout
	# кусты и камни проходимы, в кусте героиня медленнее
	var bi0: int = -1
	for bi in range(bushes.size()):
		var bq: Vector2 = bushes[bi][1]
		if LAY.WALK_RECT.grow(-40).has_point(bq) and bq.y > 420.0:
			bi0 = bi
			break
	if bi0 >= 0:
		var bpos: Vector2 = bushes[bi0][1]
		_check(not is_blocked(bpos + Vector2(0, -5)), "сквозь куст можно пройти", fails)
		_check(bush_at(bpos + Vector2(0, -5)) == bi0, "куст под ногами распознаётся", fails)
	# кот: глажка и прогулка
	var catn: Node2D = null
	for it in get_tree().get_nodes_in_group("interactables"):
		if String((it as Node).call("get_prompt")) == "Погладить кота":
			catn = it
	if catn != null:
		var mins0: float = Game.minutes
		Game.minutes = 11.0 * 60.0
		player.position = catn.global_position + Vector2(30, 6)
		catn.call("interact")
		var wt: float = 0.0
		while float(player.get("pet_t")) <= 0.0 and wt < 4.0:
			await get_tree().create_timer(0.05).timeout
			wt += 0.05
		await get_tree().create_timer(0.12).timeout
		var pf: int = int((player.get("sprite") as Sprite2D).frame) % 28
		_check(float(player.get("pet_t")) > 0.0 and pf >= 10 and pf <= 23, "героиня на колене гладит кота (кадр %d)" % pf, fails)
		_check(int(player.get("facing")) == 2, "повернулась к коту боком", fails)
		await get_tree().create_timer(1.2).timeout
		var pf2: int = int((player.get("sprite") as Sprite2D).frame) % 28
		_check(pf2 >= 10 and pf2 <= 17, "гладит рукой (кадр %d)" % pf2, fails)
		await get_tree().create_timer(3.2).timeout
		# v18: кот ходит за героиней, куда бы она ни пошла
		var p_before: Vector2 = player.position
		player.position = p_before + Vector2(0, -90)
		await get_tree().create_timer(2.5).timeout
		var cd: float = catn.global_position.distance_to(player.global_position)
		_check(cd < 140.0, "кот идёт за героиней (расстояние %d)" % int(cd), fails)
		Game.minutes = mins0
	# подбор на E: после подбора героиня не держит удалённую траву целью
	var hs2: Array = get_tree().get_nodes_in_group("wild_herbs")
	if hs2.size() > 0:
		var hh: Node2D = hs2[0]
		player.position = hh.global_position + Vector2(0, 14)
		player.set("facing", 1)
		player.set("want_facing", 1)
		await get_tree().physics_frame
		await get_tree().physics_frame
		var ek: InputEventKey = InputEventKey.new()
		ek.physical_keycode = KEY_E
		ek.pressed = true
		Input.parse_input_event(ek)
		var ek2: InputEventKey = InputEventKey.new()
		ek2.physical_keycode = KEY_E
		ek2.pressed = false
		Input.parse_input_event(ek2)
		for i3 in range(4):
			await get_tree().physics_frame
		var hvu2: Node = get_tree().get_first_node_in_group("harvest_ui")
		_check(bool(hvu2.get("is_open")), "E у травы — окно сбора", fails)
		hvu2.call("auto_collect_all")
		await get_tree().process_frame
		var tv: Variant = player.get("target")
		_check(not is_instance_valid(hh) or hh.is_queued_for_deletion(), "трава подобрана на E", fails)
		_check(tv == null or (is_instance_valid(tv) and tv != hh), "после подбора цель не «удалённая трава»", fails)
	# моргание: за 6 секунд глаза хоть раз закрылись
	player.set("expr_t", 0.0)
	player.set("facing", 0)
	player.set("want_facing", 0)
	var blinked: bool = false
	var t_end: int = Time.get_ticks_msec() + 6000
	while Time.get_ticks_msec() < t_end:
		await get_tree().physics_frame
		if int((player.get("face") as Sprite2D).region_rect.position.y) == 2 * 15:
			blinked = true
			break
	_check(blinked, "героиня моргает", fails)
	# дом: дверь, комнаты, шкаф
	var door: Node = get_tree().get_first_node_in_group("doors")
	_check(String(door.call("get_prompt")) == "", "дверь без подсказок", fails)
	_check(not Game.has_rod, "удочки сначала нет", fails)
	player.position = LAY.DOOR_POS + Vector2(0, 30)
	await enter_house()
	_check(inside, "вошла в дом", fails)
	_check(not is_blocked(IN_ORG + IN_DOOR_IN), "у двери внутри можно стоять", fails)
	_check(not is_blocked(IN_ORG + IN_WAKE), "у кровати можно стоять", fails)
	_check(is_blocked(IN_ORG + Vector2(394, 190)), "в кровать не пройти", fails)
	_check(is_blocked(IN_ORG + Vector2(298, 238)), "в стол не пройти", fails)
	_check(not is_blocked(IN_ORG + Vector2(345, 238)), "на ковре посередине свободно", fails)
	_check(is_blocked(IN_ORG + Vector2(226, 200)), "в левую стену не пройти", fails)
	_check(is_blocked(IN_ORG + Vector2(200, 296)), "сквозь стену дома не выйти", fails)
	_check(cam.limit_left == int(IN_ORG.x), "камера в комнате", fails)
	var bd: Node2D = get_tree().get_first_node_in_group("beds")
	_check(bd != null and get_tree().get_first_node_in_group("wardrobes") == null, "кровать на месте, шкафа с удочкой больше нет (v23)", fails)
	_check(String(bd.call("get_prompt")) == "", "кровать без подсказок", fails)
	Game.has_rod = true      # v23: удочку теперь делают на верстаке
	_check(Game.rod_ok(), "удочка есть", fails)
	# выход: шагнуть к двери
	player.position = IN_ORG + Vector2(320, 296)
	await get_tree().create_timer(0.9).timeout
	_check(not inside, "вышла на улицу", fails)
	_check(not is_blocked(player.position), "на улице стоит на свободном месте", fails)
	# заход, просто подойдя к двери
	player.position = Vector2(LAY.DOOR_POS.x, 354.0)
	var kw: InputEventKey = InputEventKey.new()
	kw.physical_keycode = KEY_W
	kw.pressed = true
	Input.parse_input_event(kw)
	await get_tree().create_timer(0.9).timeout
	var kw2: InputEventKey = InputEventKey.new()
	kw2.physical_keycode = KEY_W
	kw2.pressed = false
	Input.parse_input_event(kw2)
	_check(inside, "дверь сама впустила, когда шагнула к ней", fails)
	player.position = IN_ORG + Vector2(320, 296)
	await get_tree().create_timer(0.9).timeout
	_check(not inside, "снова на улице", fails)
	# рыбалка
	var spots: Array = get_tree().get_nodes_in_group("fishing_spots")
	_check(spots.size() >= 8, "места для рыбалки есть (%d)" % spots.size(), fails)
	var seen: Dictionary = {}
	for ri in range(1000):
		seen[FD.roll(12.0, ri / 1000.0, 0.6)] = true
	_check(seen.size() >= 6, "на глубине днём клюёт много видов (%d)" % seen.size(), fails)
	_check(FD.weights(2.0)["loach"] > FD.weights(12.0)["loach"], "вьюн чаще клюёт ночью", fails)
	_check(FD.weights(12.0, 1.0)["perch"] > FD.weights(12.0, 0.0)["perch"] * 2.0, "окунь любит глубину", fails)
	_check(FD.weights(12.0, 0.0)["minnow"] > FD.weights(12.0, 1.0)["minnow"] * 2.0, "гольян — у берега", fails)
	_check(FD.weights(12.0, 0.0)["golden"] == 0.0 and FD.weights(12.0, 1.0)["golden"] > 0.0, "золотой карась только на глубине", fails)
	_check(FD.bite_chance(0.9) > FD.bite_chance(0.05) + 0.5, "у берега клюёт редко, на глубине часто", fails)
	var art_ok: bool = true
	for fid in FD.ORDER:
		art_ok = art_ok and ResourceLoader.exists("res://art/fish_%s.png" % fid)
	_check(art_ok, "картинки всех рыб есть", fails)
	var sp0: Node2D = spots[0]
	_check(not is_blocked(sp0.get("shore")), "на берегу у места можно стоять", fails)
	player.position = sp0.get("shore")
	await get_tree().physics_frame
	await get_tree().physics_frame
	var tg2: Node2D = player.get("target")
	_check(tg2 != null and String(tg2.call("get_prompt")) == "", "у берега есть место, но без подсказки", fails)
	Game.has_rod = false
	sp0.call("interact")
	_check(int(fishing_ui.get("state")) == 0 and not Game.ui_open, "без удочки ничего не происходит", fails)
	Game.has_rod = true
	sp0.call("interact")
	_check(int(fishing_ui.get("state")) == 1 and Game.ui_open, "с удочкой — целимся", fails)
	var shp: Vector2 = fishing_ui.get("shore_p")
	# слишком близко — упало на траву
	fishing_ui.set("aim_u", 0.0)
	fishing_ui.call("cast")
	var near_water: bool = bool(fishing_ui.call("is_water", fishing_ui.call("landing")))
	_check(not near_water, "короткий бросок падает на берег", fails)
	await get_tree().create_timer(0.75).timeout
	_check(int(fishing_ui.get("state")) == 8, "на траве рыбы нет, леска возвращается", fails)
	await get_tree().create_timer(0.7).timeout
	_check(int(fishing_ui.get("state")) == 0 and not Game.ui_open, "удочка смотана", fails)
	# далеко и глубоко
	sp0.call("interact")
	fishing_ui.set("aim_u", clampf((shp.distance_to(LAY.POND_C) - 10.0) / 240.0, 0.0, 1.0))
	fishing_ui.call("cast")
	_check(float(fishing_ui.call("depth_at", fishing_ui.call("landing"))) > 0.9, "дальний бросок — на глубине", fails)
	await get_tree().create_timer(0.75).timeout
	_check(int(fishing_ui.get("state")) == 3, "поплавок на воде, ждём", fails)
	fishing_ui.set("will_bite", true)
	fishing_ui.set("wait_left", 0.0)
	await get_tree().create_timer(0.1).timeout
	_check(int(fishing_ui.get("state")) == 4, "клюёт", fails)
	fishing_ui.set("fish_id", "perch")
	fishing_ui.call("press")
	_check(int(fishing_ui.get("state")) == 5, "подсекла, тянем", fails)
	var perch0: int = Game.get_count("perch")
	fishing_ui.set("zone_c", fishing_ui.call("marker"))
	fishing_ui.call("press")
	_check(int(fishing_ui.get("state")) == 6, "поймала в зелёной полосе", fails)
	_check(Game.get_count("perch") == perch0 + 1, "окунь в сумке", fails)
	_check(int(Game.fish_caught.get("perch", 0)) >= 1, "улов записан", fails)
	fishing_ui.call("press")
	_check(int(fishing_ui.get("state")) == 0, "после улова удочка убрана", fails)
	# мимо полосы
	sp0.call("interact")
	fishing_ui.set("aim_u", clampf((shp.distance_to(LAY.POND_C) - 10.0) / 240.0, 0.0, 1.0))
	fishing_ui.call("cast")
	await get_tree().create_timer(0.75).timeout
	fishing_ui.set("will_bite", true)
	fishing_ui.set("wait_left", 0.0)
	await get_tree().create_timer(0.1).timeout
	fishing_ui.set("fish_id", "crucian")
	fishing_ui.call("press")
	fishing_ui.set("zone_w", 0.1)
	fishing_ui.set("zone_c", fmod(float(fishing_ui.call("marker")) + 0.5, 1.0))
	fishing_ui.call("press")
	_check(int(fishing_ui.get("state")) == 7, "мимо полосы — рыба сорвалась", fails)
	await get_tree().create_timer(0.7).timeout
	_check(int(fishing_ui.get("state")) == 0, "после промаха удочка убрана", fails)
	# рыба не подошла
	sp0.call("interact")
	fishing_ui.set("aim_u", clampf((shp.distance_to(LAY.POND_C) - 10.0) / 240.0, 0.0, 1.0))
	fishing_ui.call("cast")
	await get_tree().create_timer(0.75).timeout
	fishing_ui.set("will_bite", false)
	fishing_ui.set("wait_left", 0.0)
	await get_tree().create_timer(0.1).timeout
	_check(int(fishing_ui.get("state")) == 8, "не клюнуло — леска возвращается", fails)
	fishing_ui.call("close")
	_check(not Game.ui_open, "рыбалка закрывается", fails)
	# продажа рыбы и страница в книге
	var buyer0: Node2D = get_tree().get_first_node_in_group("fish_buyers")
	Game.inventory["perch"] = 2
	Game.inventory["roach"] = 1
	var want: int = 2 * int(FD.DATA["perch"]["price"]) + int(FD.DATA["roach"]["price"])
	_check(int(buyer0.call("total_value")) == want, "скупщик считает цену улова (%d)" % want, fails)
	_check(String(buyer0.call("get_prompt")) == "", "скупщик без подсказок", fails)
	var coins1: int = Game.coins
	_check(int(buyer0.call("interact")) == want and Game.coins == coins1 + want, "рыба продана за монеты", fails)
	_check(Game.get_count("perch") == 0 and Game.get_count("roach") == 0, "рыбы в сумке не осталось", fails)
	book.call("open")
	book.set("selected", "perch")
	book.call("refresh")
	_check(String((book.get("title_l") as Label).text) == "Окунь", "в книге страница окуня", fails)
	book.set("selected", "loach")
	book.call("refresh")
	_check(String((book.get("title_l") as Label).text) == "???", "ненайденная рыба скрыта", fails)
	book.call("_step", 1)
	_check(String(book.get("selected")) == "golden", "листание идёт по страницам рыб", fails)
	book.set("selected", String(DB.ORDER[DB.ORDER.size() - 1]))
	book.call("_step", 1)
	_check(String(book.get("selected")) == "minnow", "после трав идут страницы рыб", fails)
	# ---- v15: дикие травы во всех краях
	_check(DB.ORDER.size() >= 40 and DB.ORDER.size() == DB.DATA.size(), "трав много (%d), у всех есть описание" % DB.ORDER.size(), fails)
	var no_herbs: Array = []
	for bi in [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18]:
		if DB.wild_for(int(bi)).size() < 3:
			no_herbs.append(bi)
	_check(no_herbs.is_empty(), "в каждом биоме растут хотя бы 3 травы (пусто: %s)" % str(no_herbs), fails)
	var no_icon: Array = []
	for hid in DB.ORDER:
		if DB.icon(String(hid)) == null:
			no_icon.append(hid)
	_check(no_icon.is_empty(), "у всех трав есть картинка (%s)" % str(no_icon), fails)
	_check(not DB.hour_ok("moonbloom", 12.0) and DB.hour_ok("moonbloom", 23.0), "лунноцвет виден только ночью", fails)
	book.call("close")
	await get_tree().create_timer(0.4).timeout
	# туалет, стыд, люди
	for vv in get_tree().get_nodes_in_group("villagers"):
		(vv as Node).queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	var oh: Node2D = get_tree().get_first_node_in_group("outhouses")
	_check(oh != null and String(oh.call("get_prompt")) == "", "туалет на месте, без подсказок", fails)
	Game.pee = 0.15
	Game.poo = 0.0
	_check(absf(Game.toilet_seconds() - 3.0) < 0.01, "по-маленькому минимум 3 секунды", fails)
	Game.pee = 1.0
	_check(absf(Game.toilet_seconds() - 6.0) < 0.01, "по-маленькому на пределе 6 секунд", fails)
	Game.poo = 0.3
	_check(absf(Game.toilet_seconds() - 6.0) < 0.01, "по-большому минимум 6 секунд", fails)
	Game.poo = 1.0
	_check(absf(Game.toilet_seconds() - 12.0) < 0.01, "по-большому на пределе 12 секунд", fails)
	Game.pee = 0.0
	Game.poo = 0.0
	oh.call("interact")
	_check(player.visible and not Game.busy, "когда не хочется — в туалет не идёт", fails)
	# при людях стыдно: не идёт
	Game.pee = 0.7
	var vis2: Node2D = spawn_visitor("mint_tea", false)
	vis2.position = player.position + Vector2(60, 0)
	var sh0: float = Game.shame
	oh.call("interact")
	_check(player.visible and not Game.busy, "при людях в туалет не идёт", fails)
	_check(Game.shame > sh0, "при людях ей стыдно", fails)
	vis2.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	# по-маленькому: сидит около 3 секунд
	Game.pee = 0.2
	Game.poo = 0.1
	oh.call("interact")
	await get_tree().process_frame
	_check(not player.visible and Game.busy, "зашла в туалет", fails)
	await get_tree().create_timer(3.5).timeout
	_check(player.visible and not Game.busy, "по-маленькому вышла через ~3 секунды", fails)
	_check(Game.pee < 0.02 and Game.poo > 0.05, "сброшено только по-маленькому", fails)
	# по-большому: сидит дольше
	Game.pee = 0.6
	Game.poo = 0.5
	oh.call("interact")
	await get_tree().process_frame
	await get_tree().create_timer(4.5).timeout
	_check(not player.visible, "по-большому всё ещё сидит после 4,5 секунд", fails)
	await get_tree().create_timer(3.5).timeout
	_check(player.visible and not Game.busy, "по-большому вышла через ~7 секунд", fails)
	_check(Game.pee < 0.02 and Game.poo < 0.02, "и по-маленькому, и по-большому сброшено", fails)
	Game.call("_process", 10.0)
	_check(Game.pee > 0.0 and Game.poo > 0.0, "со временем снова хочется", fails)
	# не добежала: под себя и сильный стыд
	var acc: Array = []
	Game.accident.connect(func(k: String) -> void: acc.append(k))
	Game.shame = 0.0
	Game.pee = 0.999
	Game.call("_process", 1.0)
	_check(acc.size() == 1 and String(acc[0]) == "pee" and Game.pee < 0.5, "не добежала — конфуз", fails)
	_check(Game.shame >= 0.8, "сильное чувство стыда", fails)
	_check(messes.size() == 1 and String(messes[0].get("kind")) == "pee", "на земле лужа", fails)
	await get_tree().create_timer(1.0).timeout
	var g1: float = float(messes[0].get("g"))
	_check(g1 > 0.1 and g1 < 0.9, "моча растекается понемногу, а не появляется сразу (%.2f)" % g1, fails)
	await get_tree().create_timer(4.0).timeout
	_check(float(messes[0].get("g")) > 0.99, "лужа растеклась полностью", fails)
	_check(not Game.busy, "после конфуза снова можно ходить", fails)
	# при людях стыд полный
	var vis3: Node2D = spawn_visitor("mint_tea", false)
	vis3.position = player.position + Vector2(60, 0)
	Game.shame = 0.0
	Game.poo = 0.9999
	Game.call("_process", 1.0)
	_check(Game.shame >= 0.999 and messes.size() == 2, "при людях стыд на максимум", fails)
	vis3.queue_free()
	await get_tree().create_timer(3.2).timeout
	_check(String(messes[1].get("kind")) == "poo" and (messes[1].get("poo_sprite") as Sprite2D).visible, "кучка плюхнулась", fails)
	await get_tree().create_timer(2.0).timeout
	_check(int(messes[1].call("fly_count")) == 0, "сразу мух у кучки нет", fails)
	# новый день: лужа и кучка не пропали (за ночь только подсохли), стыд спал
	var lm0: int = live_messes().size()
	Game.minutes = 22.0 * 60.0
	for lm in live_messes():
		lm.set("last_min", Game.minutes)
	await get_tree().process_frame
	Game.next_day()
	await get_tree().process_frame
	await get_tree().process_frame
	_check(live_messes().size() == lm0 and lm0 == 2, "с новым днём лужа и кучка не пропали", fails)
	_check(float(live_messes()[0].get("amount")) < 0.9, "за ночь лужа подсохла", fails)
	_check(Game.shame < 0.6, "за ночь стыд спал", fails)
	# на улице понемногу высыхает и исчезает
	var pe: Node2D = live_messes()[0]
	var a0: float = float(pe.get("amount"))
	pe.call("advance", 20.0)
	await get_tree().process_frame
	_check(is_instance_valid(pe) and float(pe.get("amount")) < a0 - 0.02, "лужа становится всё меньше", fails)
	pe.call("advance", 2000.0)
	await get_tree().process_frame
	_check(not is_instance_valid(pe) or pe.is_queued_for_deletion(), "лужа на улице высохла совсем", fails)
	var pp: Node2D = live_messes()[0]
	var st0: int = int(pp.get("poo_stage"))
	pp.call("advance", 900.0)
	await get_tree().process_frame
	_check(int(pp.get("poo_stage")) > st0, "кучка подсыхает и становится меньше", fails)
	pp.call("advance", 3000.0)
	await get_tree().process_frame
	_check(live_messes().is_empty(), "кучка на улице со временем исчезла", fails)
	# мухи слетаются не сразу
	var fresh: Node2D = spawn_mess("poo", player.position + Vector2(40, 0))
	await get_tree().process_frame
	_check(int(fresh.call("fly_count")) == 0, "сначала мух нет", fails)
	fresh.call("advance", 50.0)
	_check(int(fresh.call("fly_count")) >= 3, "со временем мухи слетаются", fails)
	fresh.call("_vanish")
	# в доме само не высыхает — только шваброй
	await enter_house()
	var inm: Node2D = spawn_mess("pee", IN_ORG + Vector2(380, 230))
	await get_tree().process_frame
	inm.call("advance", 5000.0)
	await get_tree().process_frame
	_check(is_instance_valid(inm) and not inm.is_queued_for_deletion(), "в доме лужа сама не пропадает", fails)
	clean_mess(inm)
	_check(is_instance_valid(inm) and not Game.busy, "без швабры не убрать", fails)
	_check(String(mop_stand.call("get_prompt")) == "", "ведро со шваброй без подсказок", fails)
	mop_stand.call("interact")
	_check(Game.has_mop, "швабра взята", fails)
	await get_tree().process_frame
	_check(mop_spr.visible, "швабра в руках видна", fails)
	clean_mess(inm)
	await get_tree().create_timer(2.3).timeout
	_check(not is_instance_valid(inm) or inm.is_queued_for_deletion(), "шваброй убрала лужу", fails)
	_check(not Game.busy, "после уборки можно ходить", fails)
	player.position = IN_ORG + Vector2(320, 296)
	await get_tree().create_timer(0.9).timeout
	_check(not inside and not Game.has_mop, "выходя из дома, швабру оставила дома", fails)
	Game.pee = 0.2
	Game.poo = 0.2
	Game.shame = 0.0
	# насекомые: виды, время, место, польза и вред, крылья
	var IDB = load("res://insects_db.gd")
	_check(IDB.DATA.size() >= 12, "много видов насекомых (%d)" % IDB.DATA.size(), fails)
	var all_eff: bool = true
	for ik in IDB.DATA.keys():
		var ef: String = String(IDB.DATA[ik]["effect"])
		all_eff = all_eff and (ef.begins_with("Польза") or ef.begins_with("Вред"))
	_check(all_eff, "у каждого вида своя польза или вред", fails)
	var mins_keep: float = Game.minutes
	Game.minutes = 12.0 * 60.0
	for bi in range(15):
		insects.call("balance")
	_check(insects.call("bugs", "bee").size() > 0 and insects.call("bugs", "butterfly_white").size() > 0, "днём летают пчёлы и бабочки", fails)
	_check(insects.call("bugs", "dragonfly").size() > 0 and insects.call("bugs", "grasshopper").size() > 0, "днём стрекозы над прудом и кузнечики на лугу", fails)
	_check(insects.call("bugs", "mosquito").is_empty() and insects.call("bugs", "firefly").is_empty() and insects.call("bugs", "moth").is_empty(), "днём нет комаров, светлячков и мотыльков", fails)
	var bee0: Node2D = insects.call("bugs", "bee")[0]
	bee0.set("state", "fly")
	var frames_seen: Dictionary = {}
	for fi in range(20):
		await get_tree().process_frame
		frames_seen[int((bee0.get("spr") as Sprite2D).frame)] = true
	_check(frames_seen.size() >= 2, "у пчелы машут крылья (%d кадра)" % frames_seen.size(), fails)
	Game.minutes = 22.0 * 60.0
	for bi2 in range(15):
		insects.call("balance")
	_check(insects.call("bugs", "mosquito").size() > 0 and insects.call("bugs", "firefly").size() > 0 and insects.call("bugs", "moth").size() > 0, "ночью комары, светлячки и мотыльки", fails)
	_check(insects.call("bugs", "bee").size() < 6, "ночью пчёлы улетают", fails)
	# пчела опыляет грядку: урожай больше
	var gp: Node2D = get_tree().get_nodes_in_group("plots")[1]
	gp.call("debug_set", "mint", 1, false)
	var fb: Node2D = insects.call("spawn", "bee")
	fb.position = gp.global_position + Vector2(0, -10)
	insects.call("on_land", fb)
	_check(bool(gp.get("pollinated")), "пчела опылила грядку", fails)
	gp.call("debug_set", "mint", 3, false)
	var m0: int = Game.get_count("mint")
	gp.call("interact")
	_check(Game.get_count("mint") == m0 + 4, "с опылённой грядки на одну траву больше", fails)
	# тля мешает расти, божья коровка ест тлю
	gp.call("debug_set", "mint", 1, true)
	gp.set("aphids", 2)
	gp.call("on_new_day")
	_check(int(gp.get("stage")) == 1, "грядка с тлёй не выросла", fails)
	var lb: Node2D = insects.call("spawn", "ladybug")
	lb.position = gp.global_position + Vector2(0, -8)
	insects.call("on_land", lb)
	insects.call("on_land", lb)
	_check(int(gp.get("aphids")) == 0, "божьи коровки съели тлю", fails)
	gp.set("watered", true)
	gp.call("on_new_day")
	_check(int(gp.get("stage")) == 2, "без тли грядка снова растёт", fails)
	gp.call("debug_set", "", 0, false)
	# комар кусает
	var mq: Node2D = insects.call("spawn", "mosquito")
	mq.position = player.position
	var bites0: int = Game.bites
	insects.call("mosquito_tick", mq)
	_check(Game.bites == bites0 + 1, "комар укусил героиню", fails)
	await get_tree().create_timer(0.7).timeout
	# жук-навозник укатывает кучку
	var dp: Node2D = spawn_mess("poo", player.position + Vector2(60, 0))
	await get_tree().process_frame
	var bt: Node2D = insects.call("spawn", "dung_beetle")
	bt.set("follow", dp)
	var age0: float = float(dp.get("age_min"))
	insects.call("on_beetle_push", bt, 1.0)
	_check(float(dp.get("age_min")) >= age0 + 7.9, "жук-навозник ускоряет исчезновение кучки", fails)
	dp.call("_vanish")
	# бабочки — больше трав, кузнечики — меньше
	insects.get("stats")["flower_visits"] = 9.0
	insects.get("stats")["grass_bites"] = 0
	insects.call("_on_new_day")
	_check(Game.herb_bonus == 3, "бабочки опылили цветы — наутро трав больше", fails)
	insects.get("stats")["flower_visits"] = 0.0
	insects.get("stats")["grass_bites"] = 8
	insects.call("_on_new_day")
	_check(Game.herb_bonus == -4, "кузнечики объели травы — наутро их меньше", fails)
	Game.herb_bonus = 0
	# светлячки успокаивают
	var ff: Node2D = insects.call("spawn", "firefly")
	ff.position = player.position + Vector2(20, 0)
	Game.shame = 0.5
	insects.call("fireflies_calm", 1.0)
	_check(Game.shame < 0.5, "рядом со светлячками стыд проходит быстрее", fails)
	Game.shame = 0.0
	Game.minutes = mins_keep
	for ib in get_tree().get_nodes_in_group("insects"):
		ib.queue_free()
	insects.set("aphid_chance", 0.0)
	# еда и питьё: любая жидкость ускоряет «по-маленькому», еда — «по-большому»
	player.set("facing", 0)
	player.set("want_facing", 0)
	Game.drink_load = 0.0
	Game.food_load = 0.0
	Game.pee = 0.1
	Game.poo = 0.1
	var base_pee: float = Game.pee_rate()
	var base_poo: float = Game.poo_rate()
	var cons: Dictionary = {}
	for cn in get_tree().get_nodes_in_group("consumables"):
		cons[String(cn.get("kind"))] = cn
	_check(cons.size() == 5 and String((cons["well"] as Node2D).call("get_prompt")) == "", "колодец, раковина, стол, плита, яблоки на месте, без подсказок", fails)
	Game.consume_cd = 0.0
	_check(String((cons["well"] as Node2D).call("interact")) == "water", "из колодца можно попить", fails)
	_check(Game.pee_rate() > base_pee * 1.5, "выпила воду — по-маленькому копится быстрее", fails)
	_check(Game.poo_rate() == base_poo, "вода не ускоряет по-большому", fails)
	_check(String((cons["well"] as Node2D).call("interact")) == "", "подряд пить нельзя", fails)
	Game.consume_cd = 0.0
	Game.inventory["mint_tea"] = 1
	var dl0: float = Game.drink_load
	_check(String((cons["table"] as Node2D).call("interact")) == "tea" and Game.get_count("mint_tea") == 0, "чай выпит, из сумки ушёл", fails)
	_check(Game.drink_load > dl0 + 0.7, "чай — жидкость посильнее воды", fails)
	# v16: сумка как в PoE — формы, пучки, не влезло
	var inv_save: Dictionary = Game.inventory.duplicate()
	var eq_save: Dictionary = Game.equip.duplicate()
	Game.inventory = {}
	Game.equip.erase("pack")
	Game.layout = []
	Game.overflow = {}
	Game.layout_sync()
	_check(preload("res://items_db.gd").size("lavender") == Vector2i(1, 3) and preload("res://items_db.gd").size("bug_bee") == Vector2i(1, 1), "трава 1×3, насекомое 1×1", fails)
	Game.add_item("lavender", 1)
	Game.add_item("bug_ladybug", 1)
	_check(Game.layout.size() == 2, "лаванда и божья коровка легли в сумку", fails)
	var lav_i: int = -1
	for li in range(Game.layout.size()):
		if String(Game.layout[li]["id"]) == "lavender":
			lav_i = li
	var lav: Dictionary = Game.layout[lav_i]
	Game.add_item("lavender", 1)
	var second: Dictionary = Game.layout[Game.layout.size() - 1]
	_check(String(second["id"]) == "lavender" and Game.layout.size() == 3, "вторая лаванда — на своё место", fails)
	Game.layout.remove_at(Game.layout.size() - 1)
	var rest_l: Dictionary = Game.layout_place("lavender", 1, int(lav["x"]), int(lav["y"]))
	_check(rest_l.is_empty() and int(lav["n"]) == 2, "положила лаванду на лаванду — пучок из двух", fails)
	Game.add_item("lavender", 20)
	var maxn: int = 0
	for e5 in Game.layout:
		maxn = maxi(maxn, int(e5["n"]))
	_check(maxn <= 10, "в пучке не больше 10 цветков", fails)
	for k5 in range(40):
		Game.add_item("bottle", 5)
	_check(not Game.overflow.is_empty() and Game.overloaded(), "не влезло — перегруз", fails)
	Game.inventory = inv_save
	Game.equip = eq_save
	Game.layout = []
	Game.overflow = {}
	Game.layout_sync()
	# v16: усталость и ночная тьма
	Game.fatigue = 0.9
	var hv3: Node = get_tree().get_first_node_in_group("harvest_ui")
	hv3.call("open", null, ["mint"])
	_check(bool(hv3.get("is_open")), "очень устала — всё равно может собирать", fails)
	hv3.call("close")
	Game.ui_open = false
	Game.next_day()
	_check(Game.fatigue == 0.0, "поспала — усталость прошла", fails)
	var dk2: Node = get_tree().get_first_node_in_group("darkness")
	var min_save: float = Game.minutes
	Game.minutes = 1.0 * 60.0
	var pp0: Vector2 = player.position
	player.position = Vector2(-5200, 2600)
	_check(float(dk2.call("want_dark")) > 0.9, "ночью в лесу — полная темень", fails)
	player.position = pp0
	Game.minutes = min_save
	# v16: одежда видна на героине
	var eq0: Dictionary = Game.equip.duplicate()
	Game.equip.erase("body")
	Game.equip.erase("feet")
	Game.equip_changed.emit()
	_check(outfit_key() == "none_bare" and String((player.get("sprite") as Sprite2D).texture.resource_path).ends_with("player_none_bare.png"), "без одежды — в белье и босиком", fails)
	Game.equip["body"] = "cloak_travel"
	Game.equip["feet"] = "boots_old"
	Game.equip_changed.emit()
	_check(String((player.get("sprite") as Sprite2D).texture.resource_path).ends_with("player_cloak_travel.png"), "надела плащ и сапоги — видно на ней", fails)
	Game.equip = eq0
	Game.equip_changed.emit()
	# v16: колодец наполняет бутылочки, костёр греет воду, вода остывает
	Game.consume_cd = 0.0
	Game.inventory["bottle"] = 2
	for wk in ["water_cold", "water_warm", "water_hot"]:
		Game.inventory[wk] = 0
	_check(String((cons["well"] as Node2D).call("interact")) == "fill" and Game.get_count("water_cold") == 2 and Game.get_count("bottle") == 0, "колодец: две бутылочки студёной воды", fails)
	var cf: Node2D = Node2D.new()
	cf.set_script(load("res://campfire.gd"))
	objects.add_child(cf)
	Game.inventory["log"] = 2
	_check(String(cf.call("interact")) == "log" and bool(cf.call("burning")), "в костёр подкинуто бревно — горит", fails)
	_check(String(cf.call("interact")) == "put" and Game.get_count("water_cold") == 0, "бутылочки на огне", fails)
	for pt in cf.get("pots"):
		pt[1] = 50.0
	cf.call("_process", 0.1)
	_check(String(cf.call("interact")) == "take" and Game.get_count("water_hot") == 2, "сняла горячую воду", fails)
	Game.call("_cool_water", 200.0)
	_check(Game.get_count("water_warm") == 2 and Game.get_count("water_hot") == 0, "горячая вода остыла до тёплой", fails)
	cf.queue_free()
	Game.consume_cd = 0.0
	for pid2 in RDB.PRODUCTS.keys():
		Game.inventory.erase(String(pid2))
	var fl0: float = Game.food_load
	_check(String((cons["table"] as Node2D).call("interact")) == "" and Game.food_load == fl0, "v23: без чая стол ничего не даёт (нет сердечек из воздуха)", fails)
	Game.eat(0.7)
	_check(Game.poo_rate() > base_poo * 1.5, "поела — по-большому копится быстрее", fails)
	Game.consume_cd = 0.0
	_check(String((cons["apples"] as Node2D).call("interact")) == "apple", "яблоко съедено", fails)
	Game.hunger = 0.6
	Game.thirst = 0.6
	Game.consume_cd = 0.0
	(cons["well"] as Node2D).call("interact")
	_check(Game.thirst < 0.45, "попила — жажда меньше", fails)
	Game.consume_cd = 0.0
	(cons["apples"] as Node2D).call("interact")
	_check(Game.hunger < 0.45, "поела — голод меньше", fails)
	_check(Game.PEE_PER_MIN <= 1.0 / 1200.0 and Game.POO_PER_MIN <= 1.0 / 2400.0, "нужды копятся долго (больше суток)", fails)
	Game.consume_cd = 0.0
	Game.inventory["perch"] = 0
	Game.inventory["perch"] = 1
	_check(String((cons["stove"] as Node2D).call("interact")) == "" and Game.get_count("perch") == 1, "на плите дома не готовят", fails)
	var cf17: Node2D = Node2D.new()
	cf17.set_script(load("res://campfire.gd"))
	add_child(cf17)
	cf17.set("fuel", 4.0)
	_check(String(cf17.call("interact")) == "cook" and Game.get_count("perch") == 0 and Game.get_count("food_grilled_fish") == 1, "на костре рыба жарится", fails)
	Game.add_item("food_apple")
	Game.add_item("honey")
	_check(String(cf17.call("interact")) == "cook" and Game.get_count("food_pie_apple") == 1, "на костре печётся яблочный пирог", fails)
	cf17.set("fuel", 0.0)
	Game.add_item("food_apple")
	Game.add_item("honey")
	_check(String(cf17.call("interact")) != "cook", "на потухшем костре не готовят", fails)
	cf17.queue_free()
	Game.inventory.erase("food_apple")
	Game.inventory.erase("honey")
	# скорость реально выше: за те же минуты шкала подрастает сильнее
	Game.pee = 0.1
	Game.drink_load = 0.0
	Game.call("_process", 20.0)
	var rise_dry: float = Game.pee - 0.1
	Game.pee = 0.1
	Game.drink_load = 1.0
	Game.call("_process", 20.0)
	_check(Game.pee - 0.1 > rise_dry * 1.8, "после питья шкала растёт заметно быстрее", fails)
	Game.drink_load = 0.0
	Game.food_load = 0.0
	Game.pee = 0.2
	Game.poo = 0.2
	# розовое лицо стыда
	Game.shame = 0.9
	await get_tree().physics_frame
	await get_tree().physics_frame
	var smat: ShaderMaterial = (player.get("sprite") as Sprite2D).material as ShaderMaterial
	_check(float(player.get("blush_level")) > 0.9 and float(smat.get_shader_parameter("blush")) > 0.9, "при стыде кожа лица сильно розовеет", fails)
	_check(not (player.get("blush") as Sprite2D).visible, "розовеет сама кожа, без наложенного пятна", fails)
	Game.shame = 0.35
	await get_tree().physics_frame
	await get_tree().physics_frame
	_check(float(player.get("blush_level")) > 0.2 and float(player.get("blush_level")) < 0.6, "лёгкий стыд — лёгкий румянец", fails)
	Game.shame = 0.0
	await get_tree().physics_frame
	await get_tree().physics_frame
	_check(float(smat.get_shader_parameter("blush")) == 0.0, "стыда нет — лицо обычное", fails)
	# сон
	var day0: int = Game.day
	_on_sleep()
	await get_tree().create_timer(4.5).timeout
	_check(Game.day == day0 + 1, "сон: наступил новый день", fails)
	_check(not Game.busy, "после сна можно играть", fails)
	_check(absf(Game.hour() - 6.5) < 0.2, "утро в 6:30", fails)
	_check(inside and not is_blocked(player.position), "утром проснулась в спальне", fails)
	# ---- v14: снаряжение, рюкзаки, зелья на поясе, инструменты, режим бога
	Game.equip.clear()
	var cap0: float = Game.capacity()
	Game.add_item("pack_travel")
	_check(Game.equip_item("pack_travel", "pack"), "рюкзак надевается", fails)
	_check(absf(Game.capacity() - cap0 - 25.0) < 0.01, "рюкзак странницы: +25 к весу", fails)
	_check(not Game.equip_item("pack_travel", "head"), "рюкзак на голову не надеть", fails)
	Game.add_item("pack_basket")
	Game.add_item("porcini", 10)
	var w_before: float = Game.carried()
	Game.equip_item("pack_basket", "pack")
	_check(Game.get_count("pack_travel") == 1, "старый рюкзак вернулся в сумку", fails)
	_check(Game.carried() < w_before - 2.0, "в корзине грибы ничего не весят", fails)
	Game.add_item("sickle")
	Game.equip_item("sickle", "main1")
	_check(Game.stat("herb") >= 35.0 and Game.has_tool("sickle"), "серп в руке: шанс двух трав", fails)
	Game.weapon_set = 1
	_check(Game.stat("herb") < 35.0, "второй набор рук — серпа нет", fails)
	Game.weapon_set = 0
	Game.add_item("belt_leather")
	Game.equip_item("belt_leather", "belt")
	_check(Game.flask_slots() == 5, "кожаный пояс: 5 ячеек зелий", fails)
	Game.add_item("vigor_tea", 2)
	_check(Game.equip_item("vigor_tea", "flask0"), "зелье вешается на пояс", fails)
	Game.thirst = 0.8
	_check(Game.drink_flask(0) and Game.thirst < 0.8 and Game.buff_t > 0.0, "выпила зелье с пояса: бодрость", fails)
	_check(Game.worn("flask0") == "vigor_tea", "на пояс встало следующее такое же зелье", fails)
	Game.god_mode = true
	_check(not Game.overloaded() and Game.rep_price("cats", 50) == 0, "режим бога: без перегруза и бесплатно", fails)
	Game.god_mode = false
	Game.equip.clear()
	_check(SCN.find_home("birch").distance_to(Vector2(960, 358)) > 2000.0, "дом в берёзовой роще — далеко от старого двора", fails)
	await _test_v17(fails)
	await _test_v18(fails)
	await _test_v19(fails)
	await _test_ea(fails)
	await _test_v20(fails)
	await _test_v21(fails)
	await _test_v22(fails)
	await _test_live(fails)
	await _test_v23(fails)
	await preload("res://test24.gd").new().run(self, fails)
	await preload("res://test25.gd").new().run(self, fails)
	await preload("res://test26.gd").new().run(self, fails)
	await preload("res://test26ui.gd").new().run(self, fails)
	await preload("res://test26cats.gd").new().run(self, fails)
	await preload("res://test28.gd").new().run(self, fails)
	print("TEST: итого ошибок %d" % fails.size())
	get_tree().quit(1 if fails.size() > 0 else 0)


## v22: подводные травы, эликсир русалочьего хвоста, плавание, события дней, цели
## v23: сцены для скриншотов: house, dungeon:<тема>, hell, kingdom, skills, chest, talk, god, farm, bench
func _shot23(what: String) -> void:
	var v23: Node = get_node("V23")
	var V = preload("res://v23_data.gd")
	Game.god_mode = true
	match what.get_slice(":", 0):
		"house":
			await enter_house()
			var h23: Node = get_node("House23")
			h23.call("build_room", 1)
			h23.call("build_room", -1)
			Game.furniture = [["royal_bed", 600.0, 212.0, false], ["royal_wardrobe", 470.0, 158.0, false], ["royal_table", 520.0, 250.0, false], ["royal_rug", 560.0, 262.0, false],
				["royal_lamp", 450.0, 230.0, false], ["throne", 600.0, 160.0, false],
				["cat_bed", 386.0, 212.0, false], ["cat_bookcase", 252.0, 156.0, false], ["cat_rug", 330.0, 240.0, false], ["cat_table", 300.0, 200.0, false],
				["cat_tree", 252.0, 250.0, false], ["cat_basket", 360.0, 270.0, false], ["cat_lamp", 404.0, 160.0, false],
				["gothic_bed", 200.0, 212.0, false], ["gothic_bookcase", 60.0, 156.0, false], ["gothic_rug", 130.0, 250.0, false], ["gothic_lamp", 210.0, 160.0, false],
				["gothic_dresser", 120.0, 160.0, false], ["gothic_plant", 50.0, 250.0, false]]
			h23.call("_build_furniture")
			player.position = IN_ORG + Vector2(330, 262)
			zoom_target = 2.0
			cam.zoom = Vector2(2, 2)
			h23.set("decor", true)
		"dungeon":
			await get_node("V23/Dungeon23").call("enter", "shot:" + what.get_slice(":", 1), what.get_slice(":", 1), player.position)
			Game.god_mode = false
		"hell":
			await get_node("V23/Dungeon23").call("god_enter", "hell")
			await get_tree().create_timer(1.0).timeout
		"kingdom":
			get_node("V23/Kingdom23").call("god_hire", 10)
			get_node("V23/Kingdom23").set("propose_t", 0.3)
			await get_tree().create_timer(1.6).timeout
		"skills":
			for k in Game.SKILL_ORDER:
				Game.skills[k] = randf_range(0.0, 900.0)
			v23.call("open_skills")
		"chest":
			for id in ["stone_m", "log", "wpn_sword_gold", "lgd_dawn", "book_magic_herb", "joke_duck", "egg", "furn:royal_bed", "sea_tuna", "shark_hammer", "mint"]:
				Game.chest[id] = 3
			get_tree().get_first_node_in_group("chest_ui").call("open_chest")
		"talk":
			get_node("V23/Sea23").call("god_talk", "sea_golden")
		"god":
			v23.call("open_god")
		"farm":
			get_node("V23/Farm23").call("god_spawn_farm")
		"bench":
			homestead.set("menu_tab", what.get_slice(":", 1))
			homestead.call("open_menu", "workbench", player)
		"book":
			get_node("V23/Farm23").call("god_unlock_book")
			book.call("open")
			book.call("set_tab", "animal")
			book.set("selected", "chicken")
			book.call("refresh")
	await get_tree().create_timer(1.2).timeout


## v23: мебель и комнаты, сундук PoE, выбросить вещь, оружие и бой, навыки, звери и загон, работники и королевство,
## подземелья и ад, морские рыбы и говорящие рыбы, книга зверей, баги (стол, пирс, удочка)
func _test_v23(fails: Array) -> void:
	print("TEST: v23")
	_leave_special_states()
	if inside:
		_set_inside(false, LAY.DOOR_POS + home_off() + Vector2(0, 40))
	Game.busy = false
	Game.ui_open = false
	var V = preload("res://v23_data.gd")
	var IT23 = preload("res://items_db.gd")
	var v23: Node = get_node("V23")
	var h23: Node = get_node("House23")
	# данные и картинки
	_check(V.FURN.size() >= 120, "мебели много (%d)" % V.FURN.size(), fails)
	var beds: int = 0
	var fart: bool = true
	for fid in V.FURN.keys():
		if String(V.FURN[fid]["cat"]) == "bed":
			beds += 1
		fart = fart and ResourceLoader.exists("res://art/%s.png" % String(V.FURN[fid]["tex"]))
	_check(fart, "у всей мебели есть картинка", fails)
	_check(beds >= 12, "кроватей разных стилей >= 12 (%d)" % beds, fails)
	_check(V.FURN.has("cat_bed") and V.FURN.has("gothic_bed") and V.FURN.has("royal_bed") and V.FURN.has("straw_bed"), "есть кошачья, готическая, королевская, соломенная кровати", fails)
	_check(V.WEAPONS.size() >= 250, "оружия очень много (%d)" % V.WEAPONS.size(), fails)
	var wart: bool = true
	for wid in V.WEAPON_ORDER:
		wart = wart and ResourceLoader.exists("res://art/gear_%s.png" % String(wid)) and IT23.is_gear(String(wid))
	_check(wart, "у всего оружия есть значок и оно надевается в руку", fails)
	_check(V.SEA_FISH.size() >= 30 and V.SEA_FISH.has("shark_white") and V.SEA_FISH.has("shark_hammer") and V.SEA_FISH.has("sea_golden"), "морских рыб и акул много, есть золотая рыбка", fails)
	_check(V.MONSTERS.has("devil") and V.MONSTERS.has("demon"), "в аду есть демоны и дьявол", fails)
	# дом: мебель и комнаты
	await enter_house()
	await get_tree().create_timer(0.3).timeout
	_check(inside, "в доме", fails)
	var nf0: int = Game.furniture.size()
	_check(bool(h23.call("put", "cat_bed", Vector2(260, 200), false)), "поставила кошачью лежанку", fails)
	_check(Game.furniture.size() == nf0 + 1, "мебель записана", fails)
	_check(not bool(h23.call("put", "gothic_bed", Vector2(320, 290), false)), "дверь загородить нельзя", fails)
	var cb0: int = Game.get_count("furn:cat_bed")
	h23.call("pick", Game.furniture.size() - 1)
	_check(Game.furniture.size() == nf0 and Game.get_count("furn:cat_bed") == cb0 + 1, "мебель взята обратно в сумку", fails)
	var god0: bool = Game.god_mode
	Game.god_mode = true
	_check(bool(h23.call("build_room", 1)), "пристроила комнату справа", fails)
	Game.god_mode = god0
	_check(Game.rooms.has(1), "комната записана", fails)
	_check(not is_blocked(IN_ORG + Vector2(416, 212)), "в проём между комнатами можно пройти", fails)
	_check(not is_blocked(IN_ORG + Vector2(520, 220)), "в новой комнате можно ходить", fails)
	_check(is_blocked(IN_ORG + Vector2(416, 170)), "стена между комнатами выше проёма", fails)
	_check(bool(h23.call("put", "royal_bed", Vector2(560, 210), false)), "в новой комнате стоит королевская кровать", fails)
	player.position = IN_ORG + Vector2(320, 296)
	await get_tree().create_timer(0.9).timeout
	_check(not inside, "вышла из дома", fails)
	var cs: Array = h23.call("classic_set")
	_check(cs.size() > 10, "у старых сохранений обстановка как была", fails)
	# сундук PoE
	var cu: Node = get_tree().get_first_node_in_group("chest_ui")
	Game.chest.clear()
	Game.chest_layout.clear()
	Game.chests.clear()
	Game.add_item("stone_m", 3)
	cu.call("open_chest", "1,1", "chest_mid")
	_check(bool(cu.get("open")), "сундук открыт", fails)
	_check(bool(cu.call("store", "stone_m", 3)) and int(Game.chest.get("stone_m", 0)) == 3 and not (cu.call("L") as Array).is_empty(), "камни легли в сетку сундука", fails)
	cu.call("_take_all")
	_check(Game.get_count("stone_m") >= 3 and (cu.call("L") as Array).is_empty(), "забрала всё из сундука", fails)
	cu.call("close_chest")
	# выбросить на землю
	var ng: int = get_tree().get_nodes_in_group("ground_items").size()
	_check(bool(v23.call("drop_ground", "stone_m", 2)), "выбросила камни", fails)
	await get_tree().process_frame
	var gi: Array = get_tree().get_nodes_in_group("ground_items")
	_check(gi.size() == ng + 1 and Game.ground.size() >= 1, "камни лежат на земле", fails)
	(gi[gi.size() - 1] as Node).call("interact")
	_check(Game.get_count("stone_m") >= 3, "подняла обратно", fails)
	# навыки
	var lv0: int = Game.skill_level("herb")
	Game.skill_xp("herb", Game.skill_need(lv0 + 1))
	_check(Game.skill_level("herb") > lv0, "навык травничества растёт", fails)
	_check(Game.stat("herb") >= 3.0, "навык даёт прибавку", fails)
	# книги
	Game.add_item("book_magic_mine")
	var mx0: float = float(Game.skills.get("mine", 0.0))
	_check(bool(v23.call("use_item", "book_magic_mine")) and float(Game.skills.get("mine", 0.0)) > mx0, "магическая книга учит шахтёрству", fails)
	Game.add_item("book_recipe")
	var kr0: int = Game.known_recipes.size()
	v23.call("use_item", "book_recipe")
	_check(Game.known_recipes.size() == kr0 + 1, "книга рецептов дала новый рецепт зелья", fails)
	# удочка на верстаке
	var cards: Array = v23.call("bench_cards", "wpn")
	_check(cards.size() > 200 and String(cards[0][3]) == "v23:rod", "на верстаке — удочка и оружие", fails)
	Game.add_item("stick", 2)
	Game.add_item("twine", 1)
	var had_rod: int = Game.get_count("rod")
	_check(bool(v23.call("bench_craft", "rod")) and Game.get_count("rod") == had_rod + 1, "сделала удочку на верстаке", fails)
	_check((v23.call("bench_cards", "furn") as Array).size() >= 120, "на верстаке — вся мебель", fails)
	# звери
	var fm: Node = get_node("V23/Farm23")
	var FM = preload("res://farm23.gd")
	_check(FM.likes("chicken", "food_bread"), "курочка любит хлеб", fails)
	var zoo_ok: bool = true
	for k in FM.ORDER:
		zoo_ok = zoo_ok and preload("res://wild_db.gd").ANIMALS.has(String(k)) and ResourceLoader.exists("res://art/animal_%s.png" % String(k))
	_check(zoo_ok, "все звери справочника есть в мире и нарисованы", fails)
	if not bool(homestead.call("has_built", "pen")):
		homestead.call("build", "pen", Game.home_pos + Vector2(420, 240))
	fm.call("god_fill_pens")
	_check(Game.farm.size() >= 2, "звери в загоне", fails)
	var born: int = int(fm.call("night_breed", true))
	_check(born >= 1, "в загоне родился малыш", fails)
	for e in Game.farm:
		e["ready"] = 1
	var pc: Vector2 = Vector2(float(Game.farm[0]["x"]), float(Game.farm[0]["y"]))
	_check(int(fm.call("collect_at", pc)) > 0 and Game.get_count("egg") + Game.get_count("wool_raw") > 0, "из загона — яйца и шерсть", fails)
	fm.call("god_unlock_book")
	book.call("set_tab", "animal")
	_check(String(book.get("tab")) == "animal", "в книге есть страница зверей", fails)
	book.call("set_tab", "herb")
	# работники и королевство
	var kg: Node = get_node("V23/Kingdom23")
	var w0: int = Game.workers.size()
	kg.call("god_hire", 10)
	_check(Game.workers.size() == w0 + 10, "наняла 10 работниц", fails)
	kg.set("propose_t", -1.0)
	kg.call("give_order", 0, "wood")
	_check(String(Game.workers[0]["order"]) == "wood", "приказ: рубить лес", fails)
	for i in range(Game.workers.size()):
		kg.call("give_order", i, "herb")
	Game.minutes = 10.0 * 60.0
	await get_tree().create_timer(0.6).timeout
	for i in range(12):
		kg.call("_work_hour")
	var w24t: Node = get_tree().get_first_node_in_group("workers24")
	var carried: int = 0
	for wn in (w24t.get("st") as Dictionary).keys():
		carried += int(w24t.call("_load_n", wn))
	_check(carried > 0, "v24: работницы набрали трав в охапку (%d)" % carried, fails)
	Game.kingdom = {}
	Game.kingdom_refused = false
	kg.call("propose")
	_check(bool(v23.call("talking")), "работница предложила королевство", fails)
	((v23.get("talk_opts") as Node).get_child(1) as Button).pressed.emit()
	_check(Game.kingdom.is_empty() and Game.kingdom_refused and not Game.status_text().begins_with("Королева"), "можно отказаться — без короны", fails)
	kg.call("found", "Травяное королевство")
	_check(not Game.kingdom.is_empty() and Game.status_text().begins_with("Королева"), "основала королевство, статус — королева", fails)
	_check((v23.call("bench_tabs") as Array).has("kingdom"), "на верстаке вкладка королевства", fails)
	kg.call("abdicate")
	_check(Game.kingdom.is_empty(), "королевство можно распустить", fails)
	# подземелье и бой
	var dn: Node = get_node("V23/Dungeon23")
	Game.hell_key = "test_cave"
	await dn.call("enter", "test_cave", "cave", Game.home_pos + Vector2(0, 200))
	await get_tree().create_timer(0.3).timeout
	_check(bool(dn.get("active")) and player.position.x > 150000.0, "спустилась в подземелье", fails)
	_check(not is_blocked(player.position), "в подземелье стоит на полу", fails)
	_check(not can_save(), "в подземелье не сохраняемся", fails)
	var mons: Array = get_tree().get_nodes_in_group("monsters23")
	_check(mons.size() >= 5, "в подземелье есть монстры (%d)" % mons.size(), fails)
	var portal: bool = false
	var chest_n: Node2D = null
	for th in (dn.get("things") as Array):
		if is_instance_valid(th) and th is Node2D and (th as Node2D).get("kind") != null:
			if String((th as Node2D).get("kind")) == "portal":
				portal = true
			if String((th as Node2D).get("kind")) == "chest" and chest_n == null:
				chest_n = th
	_check(portal, "в этой пещере — портал в ад", fails)
	_check(chest_n != null, "есть сундук", fails)
	if chest_n != null:
		var c0: int = Game.coins
		chest_n.call("interact")
		_check(Game.coins > c0, "сундук открыт — монеты и находки", fails)
	if not mons.is_empty():
		var mon: Node2D = mons[0]
		mon.global_position = player.global_position + Vector2(10, 0)
		mon.set("knock", Vector2.ZERO)
		Game.add_item("wpn_sword_iron")
		Game.hotbar[7] = "wpn_sword_iron"
		Game.hot_sel = 7
		var hp0: float = float(mon.get("hp"))
		dn.set("atk_cd", 0.0)
		dn.call("attack")
		_check(float(mon.get("hp")) < hp0, "удар мечом попал", fails)
		mon.call("take_hit", 9999.0, player.global_position, "")
		await get_tree().create_timer(0.4).timeout
		_check(not is_instance_valid(mon) or bool(mon.get("dead")), "монстр побеждён без крови (облачко звёзд)", fails)
	Game.hp = 3.0
	dn.set("hurt_cd", 0.0)
	dn.call("hurt_player", 10.0, player.global_position + Vector2(5, 0))
	await get_tree().create_timer(0.9).timeout
	_check(not bool(dn.get("active")) and Game.hp > 0.0, "без сил — выбралась наружу (вещи — в тайнике монстров)", fails)
	Game.busy = false
	await dn.call("god_enter", "hell")
	await get_tree().create_timer(1.2).timeout
	# v24: ад — не подземелье, а отдельный мир Пеклоград с городом демониц
	var rl24: Node = get_tree().get_first_node_in_group("realm24")
	var demons24: int = 0
	if rl24 != null and String(rl24.get("active")) == "hell":
		for c24 in (rl24.get("roots") as Dictionary)["hell"].get_children():
			if String(c24.get("tex_name") if c24.get("tex_name") != null else "").begins_with("demon_"):
				demons24 += 1
	_check(rl24 != null and String(rl24.get("active")) == "hell" and demons24 >= 5 and not bool(dn.get("active")), "портал ведёт в Пеклоград — город демониц (%d)" % demons24, fails)
	if rl24 != null:
		await rl24.call("leave")
	await get_tree().create_timer(0.9).timeout
	_check(not bool(dn.get("active")) and (rl24 == null or String(rl24.get("active")) == ""), "вернулась из ада", fails)
	Game.hp = Game.hp_max()
	Game.busy = false
	# море
	var seen: Dictionary = {}
	for ri in range(2000):
		seen[FD.roll_sea(13.0, ri / 2000.0, 0.95)] = true
	_check(seen.has("shark_white") or seen.has("shark_hammer") or seen.has("shark_tiger"), "на глубине клюют акулы", fails)
	var sea_spots: int = 0
	for sp in get_tree().get_nodes_in_group("fishing_spots"):
		if (sp as Node).get("sea") == true:
			sea_spots += 1
	_check(sea_spots == 3, "три места для морской рыбалки на пирсе", fails)
	var s23: Node = get_node("V23/Sea23")
	s23.call("god_talk", "sea_golden")
	_check(bool(v23.call("talking")) and String((v23.get("talk_text") as Label).text).find("НЕ") >= 0, "золотая рыбка заговорила: она НЕ та самая", fails)
	((v23.get("talk_opts") as Node).get_child(3) as Button).pressed.emit()
	_check(not Game.ui_open, "разговор закрыт", fails)
	# баг пирса: на настиле хвоста нет
	var wrs: Array = world.get("walk_rects")
	if not wrs.is_empty():
		var wr0: Rect2 = wrs[0]
		world.call("build_around", wr0.get_center())
		Game.mermaid_t = 100.0
		player.position = wr0.get_center() + Vector2(0, wr0.size.y * 0.3)
		await get_tree().process_frame
		await get_tree().process_frame
		_check(not Game.in_sea, "на пирсе с зельем русалки хвост не появляется", fails)
		Game.mermaid_t = 0.0
	await teleport_to(Game.home_pos + Vector2(0, 120))
	await get_tree().create_timer(0.3).timeout
	Game.busy = false
	Game.ui_open = false


func _test_live(fails: Array) -> void:
	print("TEST: клуб Старлит")
	if inside:
		_set_inside(false, LAY.DOOR_POS + home_off() + Vector2(0, 40))
	_leave_special_states()
	Game.busy = false
	Game.ui_open = false
	var LH = preload("res://livehouse.gd")
	_check(ResourceLoader.exists("res://art/live_entrance.png") and ResourceLoader.exists("res://art/live_room.png"), "картинки клуба на месте", fails)
	for nm in ["rock_bokki", "rock_niko", "rock_rio", "rock_ikka", "rock_seiko", "rock_pei", "rock_kuki"]:
		_check(ResourceLoader.exists("res://art/%s.png" % nm) and ResourceLoader.exists("res://art/faces_%s.png" % nm), "лист и лица " + nm, fails)
		_check(String(preload("res://npc_db.gd").person(nm)[0]) != "Незнакомка", "у " + nm + " есть имя и реплика", fails)
		_check(preload("res://npc_db.gd").land_of(nm) == "live", nm + " — жительница клуба", fails)
	_check(ResourceLoader.exists("res://audio/music_rock.wav"), "рок-трек есть", fails)
	live.call("enter")
	await get_tree().create_timer(0.8).timeout
	_check(bool(live.get("active")), "вошла в клуб", fails)
	_check(player.position.x < -50000.0, "героиня внизу, в клубе", fails)
	_check(not is_blocked(player.position), "на лестничной площадке можно стоять", fails)
	_check(is_blocked(LH.ORG + Vector2(300, 100)), "на сцену не залезть", fails)
	_check(not can_save(), "в клубе не сохраняемся", fails)
	live.call("leave")
	await get_tree().create_timer(0.8).timeout
	_check(not bool(live.get("active")), "вышла на улицу", fails)
	_check(player.position.x > -50000.0, "героиня снова наверху", fails)
	Game.busy = false


func _test_v22(fails: Array) -> void:
	print("TEST: v22")
	var HDB22 = preload("res://herbs_db.gd")
	var RDB22 = preload("res://recipes_db.gd")
	var EDB22 = preload("res://events_db.gd")
	if inside:
		_set_inside(false, LAY.DOOR_POS + home_off() + Vector2(0, 40))
	_leave_special_states()
	Game.busy = false
	Game.ui_open = false
	# травы
	var sea_ids: Array = []
	for hid in HDB22.ORDER:
		if ((HDB22.DATA[hid] as Dictionary).get("biomes", []) as Array).has(19):
			sea_ids.append(hid)
	_check(sea_ids.size() == 16, "16 подводных трав (%d)" % sea_ids.size(), fails)
	var icons_ok: bool = true
	for sid in sea_ids:
		if not ResourceLoader.exists("res://art/herb14_%s.png" % String(sid)):
			icons_ok = false
		if not (RDB22.herb_props(String(sid)) as Dictionary).size() > 0:
			icons_ok = false
	_check(icons_ok, "у всех подводных трав есть картинка и свойства", fails)
	_check((HDB22.wild_for(19) as Array).size() == 16, "в море растут все 16", fails)
	# рецепт
	_check(RDB22.PRODUCTS.has("mermaid_tail") and RDB22.rarity("mermaid_tail") >= 2, "эликсир хвоста — редкий", fails)
	_check(ResourceLoader.exists("res://art/potion_mermaid_tail.png"), "у эликсира есть значок", fails)
	var r1: String = RDB22.brew_mix("moon_dew", "warm", [{"id": "sea_lavender", "procs": []}, {"id": "sea_kale", "procs": []}, {"id": "elf_leaf", "procs": []}, {"id": "crystal_root", "procs": []}])
	_check(r1 == "mermaid_tail", "рецепт с суши даёт эликсир хвоста (%s)" % r1, fails)
	var r2: String = RDB22.brew_mix("moon_dew", "warm", [{"id": "siren_lily", "procs": []}, {"id": "ice_algae", "procs": []}, {"id": "sea_lettuce", "procs": []}])
	_check(r2 == "mermaid_tail", "рецепт из морских трав даёт эликсир хвоста (%s)" % r2, fails)
	var r3: String = RDB22.brew_mix("moon_dew", "warm", [{"id": "sea_lavender", "procs": ["cut", "grind"]}, {"id": "elf_leaf", "procs": ["dry", "soak"]}])
	_check(r3 == "sea_elixir", "старый морской эликсир всё ещё варится (%s)" % r3, fails)
	# выпить и поплыть
	Game.equip.clear()
	Game.add_item("mermaid_tail", 1)
	_check(Game.equip_item("mermaid_tail", "flask0"), "эликсир вешается на пояс", fails)
	Game.mermaid_t = 0.0
	_check(is_blocked(Vector2(3000, 8200)), "без хвоста в море не пройти", fails)
	_check(Game.drink_flask(0) and Game.mermaid_t >= 400.0, "выпила — хвост на 8 часов", fails)
	_check(not is_blocked(Vector2(3000, 8200)), "в хвосте море проходимо", fails)
	_check(is_blocked(Vector2(3000, 8990)), "дальше края мира не уплыть", fails)
	player.position = Vector2(3000, 8100)
	await get_tree().create_timer(0.3).timeout
	_check(Game.in_sea, "на глубине героиня плывёт", fails)
	_check(Game.stat("speed") >= 35.0, "в воде быстрее", fails)
	# подводные места растут
	world.call("build_around", player.position)
	await get_tree().create_timer(0.5).timeout
	var spots: int = 0
	var clams: int = 0
	for n in get_tree().root.find_children("*", "Node2D", true, false):
		if n.get_script() != null and String((n.get_script() as Script).resource_path).ends_with("herb_spot.gd") and bool(n.get("sea_spot")):
			spots += 1
		elif n.is_in_group("matnodes20") and String(n.get("kind")) == "clam":
			clams += 1
	_check(spots >= 20, "вокруг в море есть места трав (%d)" % spots, fails)
	_check(clams >= 3, "есть жемчужницы (%d)" % clams, fails)
	var seen: Dictionary = {}
	var rng22: RandomNumberGenerator = RandomNumberGenerator.new()
	for dd in range(1, 6):
		for n2 in get_tree().root.find_children("*", "Node2D", true, false):
			if n2.get_script() != null and String((n2.get_script() as Script).resource_path).ends_with("herb_spot.gd") and bool(n2.get("sea_spot")):
				Game.day = 100 + dd
				n2.call("_roll")
				for tid in (n2.get("today") as Array):
					seen[String(tid)] = true
	_check(seen.size() >= 6, "в море вырастает разное (%d видов за 5 дней)" % seen.size(), fails)
	# счётчики
	var sc0: int = int(Game.counters.get("sea_herbs", 0))
	Game.add_item("kelp_gold", 2)
	_check(int(Game.counters.get("sea_herbs", 0)) == sc0 + 2, "морские травы считаются для целей", fails)
	# хвост кончился в воде — выносит на берег
	Game.mermaid_t = 0.5
	await get_tree().create_timer(1.2).timeout
	_check(Game.mermaid_t <= 0.0 and player.position.y < 7592.0, "хвост исчез — волна вынесла на берег (y=%d)" % int(player.position.y), fails)
	_check(not Game.in_sea, "не плывёт", fails)
	# события дней
	var kinds: Dictionary = {}
	var all_ok: bool = true
	for d in range(1, 201):
		var ev: String = EDB22.for_day(d)
		kinds[ev] = int(kinds.get(ev, 0)) + 1
		if not EDB22.DATA.has(ev):
			all_ok = false
	_check(all_ok, "все события известны", fails)
	_check(kinds.size() >= 14, "за 200 дней %d разных событий" % kinds.size(), fails)
	_check(EDB22.for_day(7) == "bazaar" and EDB22.for_day(14) == "harvest_fair" and EDB22.for_day(20) == "sea_feast", "праздники по календарю", fails)
	_check(EDB22.for_day(33) == EDB22.for_day(33) and EDB22.for_day(1) == "calm", "одно и то же событие в один день, первый день тихий", fails)
	var sell_day: int = 7
	Game.day = sell_day
	_check(Game.stat("sell") >= 25.0, "в базарный день продажа выгоднее", fails)
	Game.day = 4
	# цели убраны: список и награды не выдаются
	Game.goals_done.clear()
	Game.counters["herbs"] = 11
	var c_goal: int = Game.coins
	(get_node("V22") as Node).call("check_goals")
	_check(Game.goals_done.is_empty() and Game.coins == c_goal, "цели не выдаются (убраны из игры)", fails)
	Game.equip.clear()
	Game.mermaid_t = 0.0
	Game.day = 4



## v20: птицы, материалы, мастерские, ловушки, участок за материалы, E по спутникам, карта, места, спавн
func _test_v21(fails: Array) -> void:
	print("TEST: v21")
	if inside:
		_set_inside(false, LAY.DOOR_POS + home_off() + Vector2(0, 40))
	_leave_special_states()
	Game.busy = false
	Game.ui_open = false
	# спавн зверей и птиц в режиме бога
	var WDB = preload("res://wild_db.gd")
	var n0: int = get_tree().get_nodes_in_group("animals").size()
	var made: int = 0
	for k in (WDB.ANIMALS as Dictionary).keys():
		god_spawn(String(k), false)
		made += 1
	_check(made >= 10, "бог может призвать любого зверя (%d видов)" % made, fails)
	var BD21 = preload("res://birds_db.gd")
	god_spawn("sparrow", true)
	god_spawn("firebird", true)
	_check(BD21.DATA.has("firebird"), "бог может призвать птицу", fails)
	# плейлисты музыки: по 2+ трека в каждом, файлы на месте
	var tr: int = 0
	for pn in Sound.POOLS.keys():
		for t in (Sound.POOLS[pn] as Array):
			tr += 1
			_check(ResourceLoader.exists("res://audio/%s.wav" % String(t)), "музыка есть: %s" % String(t), fails)
	_check(tr >= 8, "треков не меньше 8 (%d)" % tr, fails)
	# травы не стоят под кронами и на крышах
	var bad: int = 0
	var total: int = 0
	for nd in get_tree().get_nodes_in_group("interactables"):
		if (nd as Node).get_script() != null and ((nd as Node).get_script() as Script).resource_path.ends_with("/herb_spot.gd"):
			total += 1
			if bool(world.call("under_crown", (nd as Node2D).global_position)):
				bad += 1
	print("  herb spots visible: ", total, " under crown: ", bad)


func _test_v20(fails: Array) -> void:
	print("TEST: v20")
	if inside:
		_set_inside(false, LAY.DOOR_POS + home_off() + Vector2(0, 40))
	_leave_special_states()
	Game.busy = false
	Game.ui_open = false
	Game.god_mode = false
	var MT = preload("res://mats_db.gd")
	var BDB = preload("res://birds_db.gd")
	var IT20 = preload("res://items_db.gd")
	# ---- данные и картинки
	_check(MT.ORDER.size() >= 300, "материалов больше 300 (%d)" % MT.ORDER.size(), fails)
	var no_icon: Array = []
	for mid in MT.ORDER:
		if not ResourceLoader.exists("res://art/%s.png" % String((MT.MATS[mid] as Array)[3])):
			no_icon.append(mid)
	_check(no_icon.is_empty(), "у всех материалов есть значки %s" % str(no_icon.slice(0, 5)), fails)
	_check(BDB.ORDER.size() >= 45, "видов птиц много (%d)" % BDB.ORDER.size(), fails)
	var no_bird: Array = []
	for bid in BDB.ORDER:
		if not ResourceLoader.exists("res://art/bird_%s.png" % bid) or not ResourceLoader.exists("res://audio/bird_%s.wav" % bid):
			no_bird.append(bid)
	_check(no_bird.is_empty(), "у всех птиц есть спрайт и голос %s" % str(no_bird), fails)
	var owls: int = 0
	for bid2 in BDB.ORDER:
		if bool((BDB.DATA[bid2] as Dictionary)["owl"]):
			owls += 1
	_check(owls >= 4 and not BDB.for_biome(WD.PINE, true, false).is_empty(), "ночью в тайге есть совы (%d видов сов)" % owls, fails)
	# все рецепты из известных предметов
	var unknown: Array = []
	for st in MT.RECIPES.keys():
		for rc in MT.RECIPES[st]:
			var ids: Array = [String(rc[0])]
			for k in (rc[2] as Dictionary).keys():
				ids.append(String(k))
			for id in ids:
				if id.begins_with("@"):
					continue
				var known: bool = MT.has(id) or IT20.ITEMS.has(id) or DB.DATA.has(id) or IT20.is_food(id) or id in ["stone_s", "stone_m", "stone_l"] or IT20.BASE_ITEMS.has(id) or id == "bottle"
				if not known:
					unknown.append(id)
	_check(unknown.is_empty(), "в рецептах только настоящие предметы %s" % str(unknown.slice(0, 8)), fails)
	var no_tex: Array = []
	for bk in IT20.BUILD.keys():
		var tx: String = String((IT20.BUILD[bk] as Array)[1])
		if tx != "" and not ResourceLoader.exists("res://art/%s.png" % tx):
			no_tex.append(bk)
	_check(no_tex.is_empty(), "у всех построек есть картинки %s" % str(no_tex), fails)
	_check(IT20.MT.props("feather_great_tit").size() > 0 and preload("res://recipes_db.gd").is_ingredient("feather_great_tit") and preload("res://recipes_db.gd").is_ingredient("cat_whisker"), "перья и кошачий ус идут в котёл", fails)
	# ---- участок растёт за материалы, не за деньги
	var lvl0: int = Game.plot_level
	var coins0: int = Game.coins
	if lvl0 < 6:
		var need: Dictionary = MT.PLOT_NEED[lvl0]
		for k2 in need.keys():
			Game.add_item(MT.need_icon(Game.inventory, String(k2)), int(need[k2]))
		homestead.call("open_menu", "post", null)
		homestead.call("_menu_choose", 0)
		_check(Game.plot_level == lvl0 + 1 and Game.coins == coins0, "участок расширен материалами, монеты целы", fails)
	# ---- мастерская: пилорама делает доски
	Game.add_item("wood_tree_a", 1)
	var pl0: int = Game.get_count("plank_tree_a")
	homestead.call("open_menu", "sawmill", null)
	homestead.call("_menu_choose", 0)
	homestead.call("_close_menu")
	_check(Game.get_count("plank_tree_a") == pl0 + 2 and Game.get_count("wood_tree_a") == 0, "пилорама: чурка -> 2 доски", fails)
	# ---- верстак: мастерская за материалы (любые доски — группа)
	for it in [["log", 8], ["stone_m", 2], ["flint", 2]]:
		Game.add_item(String(it[0]), int(it[1]))
	homestead.set("menu_tab", "work")
	homestead.call("open_menu", "workbench", null)
	var opts: Array = homestead.get("menu_opts")
	var si: int = -1
	for i in range(opts.size()):
		if String(opts[i][3]) == "make:sawmill":
			si = i
	_check(si >= 0, "на верстаке есть вкладка мастерских с пилорамой", fails)
	if si >= 0:
		homestead.call("_menu_choose", si)
	homestead.call("_close_menu")
	_check(Game.get_count("kit:sawmill") >= 1, "собран набор пилорамы", fails)
	# ---- ловушка: приманка -> зверь -> пух, зверь отпущен
	var tp: Vector2 = Vector2(-2 * WD.RW + 400, 1 * WD.RH + 300)
	var tr: Node2D = Node2D.new()
	tr.set_script(load("res://trap20.gd"))
	tr.set("kind", "trap_small")
	tr.set("main", self)
	tr.position = tp
	objects.add_child(tr)
	Game.add_item("food_apple", 1)
	tr.call("interact")
	var tst: Dictionary = Game.traps20["%d,%d" % [int(tp.x), int(tp.y)]]
	_check(String(tst["bait"]) == "food_apple", "в ловушку положена приманка", fails)
	tst["due"] = 0.0
	tst["caught"] = "rabbit"
	tr.call("_show")
	var fl0: int = Game.get_count("rabbit_fluff")
	tr.call("interact")
	_check(Game.get_count("rabbit_fluff") > fl0 and String(tst["caught"]) == "" and String(tst["bait"]) == "", "кролика вычесали (пух) и отпустили", fails)
	tr.queue_free()
	# ---- E: рядом трава и кот — берётся трава, кот не гладится
	var catn: Node2D = null
	for it2 in get_tree().get_nodes_in_group("interactables"):
		if (it2 as Node).get_script() != null and ((it2 as Node).get_script() as Script).resource_path.ends_with("/cat.gd"):
			catn = it2
	if catn != null:
		_check(bool(player.call("_low_priority", catn)), "кот-спутник — низкий приоритет для E", fails)
		player.set("low_block_until", Time.get_ticks_msec() + 5000)
		catn.global_position = player.global_position + Vector2(0, 8)
		player.call("_update_target")
		_check(player.get("target") != catn, "сразу после E кот не становится целью", fails)
	# ---- травы растут кучками (минимум 2)
	var singles: int = 0
	var spots: int = 0
	for hs in get_tree().get_nodes_in_group("interactables"):
		if (hs as Node).get_script() != null and ((hs as Node).get_script() as Script).resource_path.ends_with("/herb_spot.gd"):
			var td: Array = hs.get("today")
			if not td.is_empty():
				spots += 1
				if td.size() < 2:
					singles += 1
	_check(singles == 0, "нет одиночных трав (мест с травами %d)" % spots, fails)
	# ---- место: в первый раз — музыка, во второй — только название
	var plc: Node = null
	for ch in get_children():
		if ch.get_script() != null and (ch.get_script() as Script).resource_path.ends_with("/places.gd"):
			plc = ch
	if plc != null:
		Game.places_seen.erase("b12")
		plc.call("show_place", "b12")
		_check(Game.places_seen.has("b12"), "новое место запомнено", fails)
	# ---- карта: приближается, отметка при этом меньше
	map_ui.call("toggle")
	var k1: float = float(map_ui.call("_marker_k"))
	map_ui.set("zoom", 4.0)
	var k2: float = float(map_ui.call("_marker_k"))
	_check(k1 > 2.0 and k2 < k1, "на карте отметка крупная, при приближении меньше (%.2f -> %.2f)" % [k1, k2], fails)
	map_ui.set("zoom", 1.0)
	map_ui.set("zoom_target", 1.0)
	map_ui.call("toggle")
	# ---- спавн не впритык к стоянке изгоев и другим местам
	var hf: Vector2 = SCN.find_home("field")
	_check(hf.distance_to(Vector2(-2880, 1920)) > 1000.0, "дом в полях далеко от стоянки изгоев (%.0f)" % hf.distance_to(Vector2(-2880, 1920)), fails)
	# ---- птицы и места добычи появляются в мире
	var was: Vector2 = player.global_position
	player.global_position = Vector2(2 * WD.RW + 900, 2 * WD.RH + 640)
	Game.minutes = 8.0 * 60.0
	for i3 in range(40):
		await get_tree().process_frame
	await get_tree().create_timer(4.0).timeout
	_check(get_tree().get_nodes_in_group("birds20").size() > 0, "вокруг героини летают птицы (%d)" % get_tree().get_nodes_in_group("birds20").size(), fails)
	_check(get_tree().get_nodes_in_group("matnodes20").size() > 0, "в мире есть места добычи материалов (%d)" % get_tree().get_nodes_in_group("matnodes20").size(), fails)
	player.global_position = was


## Ранний доступ: сохранения, меню, лавка, кузница, королевства, фракции, лечение, первые шаги
func _test_ea(fails: Array) -> void:
	print("TEST: ранний доступ")
	if inside:
		_set_inside(false, LAY.DOOR_POS + home_off() + Vector2(0, 40))
	_leave_special_states()
	Game.god_mode = false
	Game.busy = false
	Game.ui_open = false
	playing = true
	var PDB = preload("res://paths_db.gd")
	# ---- сохранение: записать, испортить, прочитать обратно
	Game.coins = 777
	Game.inventory["mint"] = 5
	Game.counters["lt_marker"] = 12345
	var plot0: Node2D = get_tree().get_nodes_in_group("plots")[0]
	plot0.call("debug_set", "lavender", 2, true)
	player.position = Vector2(1000, 600)
	_check(Saves.can_save(), "сохраняться можно (во дворе)", fails)
	_check(Saves.save_game(Saves.TEST_SLOT, false), "сохранение записано в ячейку автотеста", fails)
	var data: Dictionary = Saves.peek(Saves.TEST_SLOT)
	_check(int((data.get("game", {}) as Dictionary).get("coins", -1)) == 777, "в файле монеты 777", fails)
	_check(((data.get("world", {}) as Dictionary).get("plots", []) as Array).size() == get_tree().get_nodes_in_group("plots").size(), "в файле все грядки", fails)
	_check(int((data.get("meta", {}) as Dictionary).get("day", -1)) == Game.day, "в файле день для меню", fails)
	Game.coins = 1
	Game.inventory["mint"] = 0
	plot0.call("debug_set", "", 0, false)
	Saves.call("_apply_vars", data["game"])
	restore_plots(data["world"])
	_check(Game.coins == 777 and Game.get_count("mint") == 5, "прочитано: монеты и травы вернулись", fails)
	_check(String(plot0.get("crop")) == "lavender" and int(plot0.get("stage")) == 2 and bool(plot0.get("watered")), "прочитано: грядка вернулась", fails)
	visiting = Node2D.new()
	_check(not Saves.can_save(), "в гостях сохраняться нельзя", fails)
	visiting.free()
	visiting = null
	var keep: Dictionary = Saves.game_vars()
	Saves.reset_game()
	_check(Game.coins == 0 and Game.chronicle.is_empty() and Game.factions.is_empty(), "новая игра: всё прошлое забыто", fails)
	Saves.call("_apply_vars", keep)
	playing = true
	_check(Game.coins == 777, "после сброса состояние вернули для тестов", fails)
	# ---- меню: «Продолжить» видно, когда есть сохранение
	var mn: CanvasLayer = CanvasLayer.new()
	mn.set_script(load("res://menu.gd"))
	add_child(mn)
	mn.call("setup", hud)
	_check(mn.get("cont_btn") != null and mn.get("sl_root") != null and mn.get("cf_root") != null, "меню: есть «Продолжить», ячейки и подтверждение", fails)
	mn.queue_free()
	Game.ui_open = false
	get_tree().paused = false
	# ---- кузница
	Game.inventory["stone_m"] = 4
	Game.inventory["log"] = 3
	_check(bool(paths.call("forge", "iron_bar")) and bool(paths.call("forge", "iron_bar")), "кузница: два бруска из камня", fails)
	_check(Game.get_count("iron_bar") == 2 and Game.get_count("stone_m") == 0, "бруски в сумке, камни потрачены", fails)
	Game.inventory["log"] = 0
	_check(not bool(paths.call("forge", "guard_sword")), "на меч не хватает брёвен — не куётся", fails)
	_check(bool(paths.call("forge", "horseshoe")) and Game.get_count("horseshoe") == 2, "подковы: из бруска две", fails)
	# ---- лавка у дома
	homestead.call("build", "stall", Game.home_pos + Vector2(-260, 160))
	await get_tree().process_frame
	_check(paths.call("stall_node") != null, "лавка зелий построена", fails)
	Game.add_item("calm_tea", 4)
	_check(bool(paths.call("stall_act", "put")) and int(paths.call("stall_count")) >= 4, "товар выставлен на прилавок", fails)
	_check(Game.get_count("calm_tea") == 0, "из сумки товар ушёл", fails)
	var pr: int = int(paths.call("sell_one"))
	_check(pr > 0 and int(Game.stall["cash"]) == pr, "покупательница заплатила в кассу", fails)
	var c0: int = Game.coins
	_check(bool(paths.call("stall_act", "cash")) and Game.coins == c0 + pr, "выручка забрана", fails)
	_check(bool(paths.call("stall_act", "lure")) and bool(paths.call("lured")), "зазывать: покупательниц станет больше", fails)
	_check(float(paths.call("customer_chance")) > 0.6, "шанс покупки с зазыванием высокий", fails)
	_check(not bool(paths.call("stall_act", "lure")), "зазывать снова сразу нельзя", fails)
	var sold0: int = int(Game.stall["sold"])
	for i in range(30):
		paths.call("_hour_tick", 10)
	_check(int(Game.stall["sold"]) > sold0, "за часы в лавке что-то купили", fails)
	# ---- разговоры: поддельная жительница и окно разговора
	var npc_s: GDScript = GDScript.new()
	npc_s.source_code = "extends Node2D\nvar npc_name: String = \"\"\nvar land: String = \"\"\nvar role: String = \"житель\"\nvar tex_name: String = \"catgirl_a\"\nfunc react(_a: String, _b: float = 1.0) -> void:\n\tpass\n"
	npc_s.reload()
	var dlg_s: GDScript = GDScript.new()
	dlg_s.source_code = "extends Node\nvar npc: Node = null\nvar said: String = \"\"\nvar opts: Array = []\nfunc _say(t: String) -> void:\n\tsaid = t\nfunc _talk_menu() -> void:\n\tpass\nfunc _set_options(o: Array) -> void:\n\topts = o\n"
	dlg_s.reload()
	var npc: Node2D = Node2D.new()
	npc.set_script(npc_s)
	add_child(npc)
	var dl: Node = Node.new()
	dl.set_script(dlg_s)
	add_child(dl)
	dl.set("npc", npc)
	# фракция: секта Великой Спящей Кошки
	npc.set("land", "cats")
	npc.set("role", "житель")
	var nm_found: String = ""
	for i in range(200):
		npc.set("npc_name", "Мурка%d" % i)
		if String(paths.call("faction_of", npc)) == "cat_cult":
			nm_found = "Мурка%d" % i
			break
	_check(nm_found != "", "в Мурлыкино есть сектантки Спящей Кошки", fails)
	var fopts: Array = paths.call("extra_options", dl, [["Пока!", "bye"]])
	var has_info: bool = false
	for o in fopts:
		if String(o[1]) == "fc_info:cat_cult":
			has_info = true
	_check(has_info, "в разговоре можно спросить про знак секты", fails)
	paths.call("handle", dl, "fc_info:cat_cult")
	_check(String(dl.get("said")).contains("Спящей Кошки"), "сектантка рассказала о секте", fails)
	var fish_id: String = String(FD.ORDER[0])
	Game.add_item(fish_id, 6)
	var hunger_k0: float = Game.stat("hunger")
	paths.call("handle", dl, "fc_join:cat_cult")
	_check(Game.factions.has("cat_cult"), "вступила в секту", fails)
	_check(Game.stat("hunger") < hunger_k0, "звание секты: голод медленнее", fails)
	paths.call("handle", dl, "fc_task:cat_cult")
	var task: Dictionary = (Game.factions["cat_cult"] as Dictionary)["task"]
	_check(not task.is_empty(), "секта дала дело", fails)
	Game.add_item(fish_id, 6)
	Game.add_item("sleep_tea", 2)
	Game.add_item("food_" + String(preload("res://food_db.gd").DATA.keys()[0]), 3)
	paths.call("handle", dl, "fc_task:cat_cult")
	_check(int((Game.factions["cat_cult"] as Dictionary)["favor"]) > 0, "дело сдано: доверие секты выросло", fails)
	# соперницы: Орден Щита и Ковен не уживаются
	Game.factions["shield"] = {"favor": 0, "rank": 0, "task": {}, "since": Game.day}
	npc.set("land", "gothic")
	Game.add_item("calm_tea", 3)
	paths.call("handle", dl, "fc_join:coven")
	_check(not Game.factions.has("coven"), "в Ковен не берут рыцарей Щита", fails)
	Game.factions.erase("shield")
	# королевство: торговый союз, караван, королевский заказ, придворная
	npc.set("land", "cats")
	npc.set("role", "лидер")
	npc.set("npc_name", "Мурлин")
	Game.rep["cats"] = 85
	Game.coins = 300
	var lopts: Array = paths.call("extra_options", dl, [["Пока!", "bye"]])
	_check(String(lopts[0][1]) == "pk_offer", "королева: можно предложить союз", fails)
	paths.call("handle", dl, "pk_offer")
	_check(Game.pacts.has("cats") and Game.coins == 200, "союз заключён за 100 монет", fails)
	Game.add_item("calm_tea", 5)
	Game.add_item("guard_sword", 1)
	paths.call("handle", dl, "pk_caravan")
	_check(Game.caravans.size() == 1 and Game.get_count("calm_tea") == 0, "караван ушёл с товаром", fails)
	var cc: int = Game.coins
	Game.next_day()
	Game.next_day()
	_check(Game.caravans.is_empty() and Game.coins > cc, "караван вернулся с деньгами (+%d)" % (Game.coins - cc), fails)
	paths.call("handle", dl, "pk_royal")
	_check(Game.royal.has("cats"), "королевский заказ получен", fails)
	var ro: Dictionary = Game.royal["cats"]
	if String(ro["item"]).ends_with("_any") or String(ro["item"]) == "ore":
		pass
	else:
		Game.add_item(String(ro["item"]), int(ro["n"]))
	var cr: int = Game.coins
	paths.call("handle", dl, "pk_royal")
	_check(not Game.royal.has("cats") and Game.coins > cr, "королевский заказ сдан", fails)
	paths.call("handle", dl, "pk_court")
	_check(Game.court.has("cats") and Game.titles.has("court"), "придворная травница", fails)
	var cs: int = Game.coins
	Game.next_day()
	_check(Game.coins >= cs + 15, "жалованье придворной за день", fails)
	# заказ оружия у кузнечихи Кронхольма
	npc.set("land", "knights")
	npc.set("role", "кузнец")
	npc.set("npc_name", "Хильда")
	paths.call("handle", dl, "sm_ask")
	_check(Game.smith_orders.has("knights"), "кузнечиха заказала оружие для города", fails)
	var so: Dictionary = Game.smith_orders["knights"]
	Game.add_item(String(so["item"]), int(so["n"]))
	var cw: int = Game.coins
	paths.call("handle", dl, "sm_ask")
	_check(not Game.smith_orders.has("knights") and Game.coins > cw, "оружие сдано городу", fails)
	# лечение больной жительницы
	npc.set("land", "cats")
	npc.set("role", "житель")
	Game.healed_today.clear()
	var sick: String = ""
	for i in range(300):
		npc.set("npc_name", "Ласка%d" % i)
		if bool(paths.call("is_sick", npc)):
			sick = "Ласка%d" % i
			break
	_check(sick != "", "есть больная жительница", fails)
	var need: String = String(paths.call("sick_need", npc))
	Game.add_item(need, 1)
	var ch: int = Game.coins
	paths.call("handle", dl, "hl_give")
	_check(Game.coins > ch and int(Game.counters.get("healed", 0)) == 1 and not bool(paths.call("is_sick", npc)), "вылечила: монеты и спасибо", fails)
	# летопись
	var txt: String = String(paths.call("chronicle_text"))
	_check(txt.contains("История") and txt.contains("союз"), "летопись помнит союз и историю", fails)
	_check(Game.chronicle.size() >= 4, "в летописи записи (%d)" % Game.chronicle.size(), fails)
	npc.queue_free()
	dl.queue_free()
	# ---- первые шаги картинками
	var keep_inv: Dictionary = Game.inventory.duplicate()
	var keep_rec: Dictionary = Game.known_recipes.duplicate(true)
	Game.inventory.clear()
	Game.known_recipes.clear()
	_check(not bool(guide.call("done", 0)), "первый шаг: трав ещё нет", fails)
	Game.inventory["chamomile"] = 3
	_check(bool(guide.call("done", 0)), "первый шаг сделан: три травы", fails)
	Game.inventory = keep_inv
	Game.known_recipes = keep_rec
	Game.inventory_changed.emit()
	# ---- сохранить итог для второго запуска (--loadtest)
	Game.coins = 777
	Game.counters["lt_marker"] = 12345
	plot0.call("debug_set", "lavender", 2, true)
	player.position = Vector2(1000, 600)
	_check(Saves.save_game(Saves.TEST_SLOT, false), "сохранение для проверки перезапуска", fails)


## Второй запуск: загрузить ячейку автотеста, сравнить, выйти. godot --headless --path . -- --loadtest
func _loadtest() -> void:
	await get_tree().process_frame
	if not bool(Saves.get("lt_started")):
		Saves.set("lt_started", true)
		if not Saves.load_game(Saves.TEST_SLOT):
			print("LOADTEST: FAIL нет файла")
			get_tree().quit(1)
		return
	await get_tree().create_timer(0.5).timeout
	var fails: Array = []
	_check(Game.coins == 777, "после перезапуска: монеты 777", fails)
	_check(int(Game.counters.get("lt_marker", 0)) == 12345, "после перезапуска: счётчики путей", fails)
	_check(Game.factions.has("cat_cult") and Game.pacts.has("cats"), "после перезапуска: фракция и союз", fails)
	_check(not Game.chronicle.is_empty(), "после перезапуска: летопись", fails)
	var lav: bool = false
	for n in get_tree().get_nodes_in_group("plots"):
		if String(n.get("crop")) == "lavender" and int(n.get("stage")) == 2:
			lav = true
	_check(lav, "после перезапуска: грядка с лавандой", fails)
	_check(get_tree().get_first_node_in_group("stall_ea") != null, "после перезапуска: лавка стоит", fails)
	_check(player.position.distance_to(Vector2(1000, 600)) < 120.0, "после перезапуска: героиня на месте", fails)
	print("LOADTEST: итого ошибок %d" % fails.size())
	get_tree().quit(1 if fails.size() > 0 else 0)


## v19: физика в окнах, сушилка, книга в режиме бога, приюты, шахта, болото с ивами
func _test_v19(fails: Array) -> void:
	var PH19 = preload("res://phys2d.gd")
	# ---- физика: падает, крутится, ложится
	var b: Dictionary = PH19.make(Vector2(500, 200), Vector2(40, 120), Vector2(300, -200), 6.0)
	var a0: float = float(b["ang"])
	for i in range(240):
		PH19.step(b, 1.0 / 60.0, 800.0, 0.0, 1920.0)
	var low: float = -1e9
	for c in PH19.corners(b):
		low = maxf(low, (c as Vector2).y)
	_check(absf(float(b["ang"]) - a0) > 0.5 and low <= 801.5 and PH19.resting(b), "физика: предмет летит, крутится и ложится на пол (угол %.2f)" % float(b["ang"]), fails)
	var lie: float = fmod(absf(float(b["ang"])), PI)
	_check(lie > 1.2 and lie < 1.95 or lie < 0.35 or lie > 2.8, "лёг устойчиво: на бок или на основание (%.2f)" % lie, fails)
	# ---- стол зельевара: бросок в котёл и на стол
	Game.fatigue = 0.0
	Game.inventory.clear()
	Game.cauldron_clear()
	brew_ui.call("open")
	await get_tree().create_timer(0.4).timeout
	var mouth: Rect2 = preload("res://brew.gd").MOUTH
	brew_ui.call("throw_ing", {"id": "mint", "procs": []}, mouth.get_center() + Vector2(0, -160), Vector2(0, 200))
	await get_tree().create_timer(1.0).timeout
	_check((Game.cauldron["ings"] as Array).size() == 1, "брошенная в котёл трава попала в котёл", fails)
	brew_ui.call("throw_ing", {"id": "lavender", "procs": []}, Vector2(1650, 600), Vector2(160, -300))
	await get_tree().create_timer(3.5).timeout
	var lo: Array = brew_ui.get("loose")
	_check(lo.size() == 1 and PH19.resting(lo[0]["body"]), "брошенная мимо — упала и лежит на столе (%d %s)" % [lo.size(), str(lo[0]["body"]) if lo.size() > 0 else ""], fails)
	brew_ui.call("close")
	await get_tree().create_timer(0.4).timeout
	_check(Game.get_count("lavender") == 1, "закрыла стол — трава со стола вернулась в сумку", fails)
	Game.cauldron_clear()
	# ---- сушилка
	var dry: Node = get_tree().get_first_node_in_group("dry_ui")
	Game.dryer.clear()
	_check(bool(dry.call("hang", "mint", 0)) and not bool(dry.call("hang", "chamomile", 0)), "трава висит на крючке, занятый крючок не даёт второй", fails)
	_check(preload("res://dry_ui.gd").dryness(float(Game.dryer[0]["t0"])) < 0.1, "свежая трава ещё не сухая", fails)
	Game.dryer[0]["t0"] = float(Game.dryer[0]["t0"]) - 7.0 * 60.0
	_check(preload("res://dry_ui.gd").dryness(float(Game.dryer[0]["t0"])) >= 1.0, "через 7 часов трава высохла", fails)
	var hh: Dictionary = dry.call("unhang", 0)
	dry.call("stash", String(hh["id"]), float(hh["t0"]))
	_check(Game.get_count("dry:mint") == 1 and preload("res://items_db.gd").name("dry:mint").begins_with("Сушёная"), "в сумке «%s»" % preload("res://items_db.gd").name("dry:mint"), fails)
	_check((brew_ui.call("_shelf_items") as Array).has("dry:mint"), "сушёная трава есть в шкафу зельевара", fails)
	_check(preload("res://items_db.gd").BUILD.has("dryer") and ResourceLoader.exists("res://art/dryer.png") and ResourceLoader.exists("res://art/dry_room.png"), "сушилку можно построить, нарисована", fails)
	dry.call("open")
	await get_tree().create_timer(0.3).timeout
	dry.call("close")
	await get_tree().create_timer(0.3).timeout
	# ---- режим бога: открыть всё в книге
	Game.discovered.clear()
	var nb: int = preload("res://god.gd").unlock_book()
	var all_ok: bool = true
	for hid in DB.DATA.keys():
		if not Game.discovered.has(hid):
			all_ok = false
	for sid in preload("res://wild_db.gd").SHROOMS.keys():
		if not Game.discovered.has(sid):
			all_ok = false
	for fk in preload("res://food_db.gd").DATA.keys():
		if not Game.discovered.has("food_" + String(fk)):
			all_ok = false
	_check(all_ok and nb > 150, "режим бога: в книге открыто всё (%d)" % nb, fails)
	# ---- приюты
	Game.god_mode = true
	await teleport_to((WD.TOWN_C["cats"] as Vector2) + Vector2(0, 150))
	await get_tree().create_timer(0.3).timeout
	var sh_door: Node2D = null
	for dd in get_tree().get_nodes_in_group("house_doors"):
		if String(dd.get("kind")) == "shelter" and String(dd.get("land")) == "cats":
			sh_door = dd
	_check(sh_door != null, "в городе кошек стоит кошачий приют", fails)
	if sh_door != null:
		await visit_house(sh_door)
		await get_tree().create_timer(0.3).timeout
		_check(room_owner != null and room_owner.has_meta("shelter"), "в приюте есть хозяйка", fails)
		var cats_in: int = 0
		for rp in room_props:
			if is_instance_valid(rp) and (rp as Node).get_script() != null and String((rp as Node).get_script().resource_path).ends_with("lost_cat.gd"):
				cats_in += 1
		_check(cats_in >= 4, "в кошачьем приюте живут кошки (%d)" % cats_in, fails)
		var dlg19: Node = get_tree().get_first_node_in_group("dialog_ui")
		dlg19.call("start", room_owner)
		var acts19: Array = []
		for op in (dlg19.get("options") as Array):
			acts19.append(String(op[1]))
		_check("sh_menu" in acts19, "у хозяйки приюта есть «Хочу взять питомца»", fails)
		dlg19.call("close")
		await leave_house()
	var shn: Node = get_tree().get_first_node_in_group("shelters18")
	Game.coins = 500
	var pets0: int = (Game.pets as Array).size()
	_check(bool(shn.call("adopt", "cats", "cat:ginger")) and bool(shn.call("adopt", "knights", "rabbit")), "взяла рыжего котика и кролика", fails)
	_check((Game.pets as Array).size() == pets0 + 2 and get_tree().get_nodes_in_group("pets18").size() >= 2, "питомцы появились рядом", fails)
	_check(preload("res://shelter.gd").list_for("cats").size() >= 4 and String(preload("res://shelter.gd").list_for("cats")[0][0]).begins_with("cat:") and not String(preload("res://shelter.gd").list_for("orcs")[0][0]).begins_with("cat:"), "у кошек в приюте только кошки, у других — другие звери", fails)
	await teleport_to((WD.TOWN_C["knights"] as Vector2) + Vector2(0, 150))
	await get_tree().create_timer(0.4).timeout
	var near_pets: int = 0
	for pn in get_tree().get_nodes_in_group("pets18"):
		if (pn as Node2D).global_position.distance_to(player.global_position) < 200.0:
			near_pets += 1
	_check(near_pets >= 2, "питомцы догнали после телепорта (%d)" % near_pets, fails)
	# ---- шахта
	await teleport_to(SCN.find_home("grotto"))
	await get_tree().create_timer(0.4).timeout
	_check(get_tree().get_nodes_in_group("cave_doors").size() >= 1, "в гротах есть вход в пещеру", fails)
	_check(WD.LANDMARKS.has([-10560, -8320, "cave"]), "вход в пещеру наверху карты", fails)
	var cave_from: Vector2 = player.position
	await mine.call("enter", cave_from)
	await get_tree().create_timer(0.3).timeout
	_check(bool(mine.get("inside")) and player.position.y > 120000.0 and not is_blocked(player.position), "спустилась в шахту", fails)
	_check(get_tree().get_nodes_in_group("mine_bats").size() >= 10, "в шахте летают летучие мыши", fails)
	_check(String(mine.call("visitor_tex")) != "", "в шахте кто-то есть: %s" % String(mine.call("visitor_tex")), fails)
	var dk: Node = get_tree().get_first_node_in_group("darkness")
	_check(dk == null or float(dk.call("want_dark")) > 0.5, "в шахте темно", fails)
	var rk19: Node = get_tree().get_first_node_in_group("rocks18")
	var mine_ores: int = 0
	for rec in (rk19.call("near", player.position, 1800.0) as Array):
		if bool(rec["ore"]):
			mine_ores += 1
	_check(mine_ores >= 5, "в шахте есть руда (%d)" % mine_ores, fails)
	_check(is_blocked(preload("res://mine.gd").ORG + Vector2(50, 1450)), "сквозь скалу в шахте не пройти", fails)
	await mine.call("leave")
	await get_tree().create_timer(0.3).timeout
	_check(not bool(mine.get("inside")) and player.position.distance_to(cave_from) < 300.0, "выбралась наверх у пещеры", fails)
	# ---- болото
	var swp: Vector2 = SCN.find_home("swamp")
	await teleport_to(swp)
	await get_tree().create_timer(0.4).timeout
	var willows: int = 0
	var pools: int = 0
	for reg in world.get("built").keys():
		for ch in (world.get("built")[reg] as Node).get_children():
			if ch is Sprite2D and (ch as Sprite2D).texture != null:
				var tn: String = (ch as Sprite2D).texture.resource_path.get_file().get_basename()
				if tn.begins_with("willow_"):
					willows += 1
				elif tn.begins_with("bog_pool"):
					pools += 1
	_check(willows >= 10 and pools >= 5, "на болоте растут ивы (%d) и есть окна воды (%d)" % [willows, pools], fails)
	Game.god_mode = false


## v18: камни и руды, кирка, режим бога (все предметы, телепорт), тюрьмы, услуги, задания, кот-спутник, карта и места старта
func _test_v18(fails: Array) -> void:
	var GOD18 = preload("res://god.gd")
	var MD18 = preload("res://mining_db.gd")
	var IT18 = preload("res://items_db.gd")
	var SVD18 = preload("res://svc_dialog.gd")
	var LAW18 = preload("res://law.gd")
	# ---- карта и места старта
	_check(WD.GRID.size() == WD.ROWS, "сетка карты: %d рядов" % WD.GRID.size(), fails)
	var rows_ok: bool = true
	for gr in WD.GRID:
		if (gr as Array).size() != WD.COLS:
			rows_ok = false
	_check(rows_ok, "в каждом ряду карты %d столбцов" % WD.COLS, fails)
	_check(WD.COLS * WD.RW > 40000 and WD.biome_of_region(Vector2i(-9, -7)) == WD.PINE, "карта расширена лесами", fails)
	_check(SCN.SPAWN_ORDER.size() >= 19, "мест старта: %d" % SCN.SPAWN_ORDER.size(), fails)
	for key in SCN.SPAWN_ORDER:
		var kp: Vector2 = SCN.find_home(String(key))
		var td: float = SCN.town_dist(kp)
		_check(td >= 2200.0, "старт «%s»: до города %d (не ближе 2200)" % [key, int(td)], fails)
		if bool((SCN.SPAWNS[key] as Dictionary).get("wild", false)):
			_check(td <= 6000.0, "старт «%s» не на краю света: %d" % [key, int(td)], fails)
			_check(WD.biome_at(kp) == int(SCN.SPAWNS[key]["biome"]), "старт «%s» — в своём биоме" % key, fails)
	# ---- арт, нарисованный в Aseprite
	var art_ok: bool = true
	for fname in ["gear_pickaxe", "icon_stone_s", "icon_stone_m", "icon_stone_l", "icon_scroll", "icon_letter", "cat_lost_ginger", "cat_lost_white", "cat_lost_gray", "cat_lost_calico"]:
		if not ResourceLoader.exists("res://art/%s.png" % fname):
			art_ok = false
			print("  нет картинки ", fname)
	for k in ["s", "m", "l", "h"]:
		for v in ["0", "1", "2", "w0", "w1"]:
			if v in ["2"] and false:
				continue
			if not ResourceLoader.exists("res://art/rock18_%s_%s.png" % [k, v]):
				art_ok = false
				print("  нет картинки rock18_%s_%s" % [k, v])
	for oid in MD18.ORE_ORDER:
		for v2 in ["0", "1"]:
			if not ResourceLoader.exists("res://art/ore18_%s_%s.png" % [oid, v2]):
				art_ok = false
		if not ResourceLoader.exists("res://art/icon_ore_%s.png" % oid):
			art_ok = false
	for land in ["cats", "spider", "gothic", "knights", "elves", "mages", "orcs", "goblins", "dwarves", "japan"]:
		if not ResourceLoader.exists("res://art/prison_%s.png" % land) or not ResourceLoader.exists("res://art/pr18_cell_%s.png" % land):
			art_ok = false
			print("  нет тюрьмы ", land)
		if not LAW18.PRISONS.has(land):
			art_ok = false
	_check(art_ok, "нарисованы все камни, руды, тюрьмы, кошки и значки", fails)
	var tints: Dictionary = {}
	for pl0 in LAW18.PRISONS.keys():
		tints[str((LAW18.PRISONS[pl0] as Dictionary)["tint"])] = true
	_check(tints.size() == 10 and LAW18.PRISONS.size() == 10, "у каждого города своя тюрьма (10 разных)", fails)
	# ---- предметы: режим бога
	var cats18: Dictionary = GOD18.by_category()
	var all18: Array = GOD18.all_items()
	var expect: Dictionary = {}
	for dbk in [preload("res://herbs_db.gd").DATA.keys(), preload("res://recipes_db.gd").PRODUCTS.keys(), preload("res://wild_db.gd").SHROOMS.keys(), preload("res://fish_db.gd").DATA.keys(), IT18.GEAR.keys(), IT18.ITEMS.keys(), MD18.all_item_ids()]:
		for ik in dbk:
			expect[String(ik)] = true
	for fk in preload("res://food_db.gd").DATA.keys():
		expect["food_" + String(fk)] = true
	for bk in IT18.BUILD.keys():
		expect["kit:" + String(bk)] = true
	for tk in IT18.TREE_NAMES.keys():
		expect["sapling:" + String(tk)] = true
	for lk in preload("res://tree_db.gd").TREES.keys():
		expect["leaf_" + String(lk)] = true
	for ink in preload("res://insects_db.gd").DATA.keys():
		expect["bug_" + String(ink)] = true
	for dk in preload("res://herbs_db.gd").DATA.keys():
		expect["dry:" + String(dk)] = true
	for mk in preload("res://mats_db.gd").ORDER:
		expect[String(mk)] = true     # v20: материалы и перья
	var V23E = preload("res://v23_data.gd")
	for wk in V23E.WEAPON_ORDER:      # v23: оружие, мебель, книги, приколы, поделки
		expect[String(wk)] = true
	for fuk in V23E.FURN.keys():
		expect["furn:" + String(fuk)] = true
	for bk2 in V23E.BOOKS.keys() + V23E.JOKES.keys() + V23E.PRODUCTS.keys():
		expect[String(bk2)] = true
	for vk in preload("res://v24_data.gd").ITEMS.keys():   # v24
		expect[String(vk)] = true
	var not_given: Array = []
	for ek in expect.keys():
		if not all18.has(ek):
			not_given.append(ek)
	_check(not_given.is_empty() and all18.size() == expect.size(), "режим бога выдаёт ВСЕ предметы игры: %d из %d (нет: %s)" % [all18.size(), expect.size(), str(not_given.slice(0, 5))], fails)
	var miss: int = 0
	for iid in all18:
		var sid: String = String(iid)
		if IT18.name(sid) == "" or IT18.icon(sid) == null:
			miss += 1
			print("  предмет без имени или значка: ", sid)
	_check(miss == 0, "у всех предметов есть имя и значок", fails)
	var need_ids: Array = ["pickaxe", "stone_s", "stone_m", "stone_l", "ore_star", "ore_mana", "quest_letter", "axe", "log", "bottle", "kit:well", "sapling:tree_a", "mint", "leaf_tree_a", "bug_bee", "murky"]
	for nid in need_ids:
		_check(all18.has(nid), "режим бога выдаёт «%s»" % nid, fails)
	_check(all18.has("food_" + String(preload("res://food_db.gd").DATA.keys()[0])), "режим бога выдаёт еду", fails)
	_check((cats18["Всё"] as Array).size() == all18.size() and (cats18["Камни и руды"] as Array).size() == 11, "категории режима бога сходятся", fails)
	var tg: Array = GOD18.targets()
	var groups18: Dictionary = {}
	for tt in tg:
		groups18[String((tt as Dictionary)["group"])] = int(groups18.get(String((tt as Dictionary)["group"]), 0)) + 1
	_check(int(groups18.get("Города", 0)) == WD.TOWN_C.size() and int(groups18.get("Тюрьмы", 0)) == WD.TOWN_C.size() and int(groups18.get("Места", 0)) >= 20 and int(groups18.get("Леса и биомы", 0)) >= 17, "цели телепорта: %s" % str(groups18), fails)
	_check(preload("res://shop_shelf.gd").STOCK["dwarves"].has("pickaxe"), "кирка продаётся у дворфов", fails)
	# ---- телепорт и кот-спутник
	Game.god_mode = true
	var cat_n: Node2D = get_tree().get_first_node_in_group("companion_cat") as Node2D
	_check(cat_n != null, "кот-спутник есть", fails)
	var town_t: Vector2 = (WD.TOWN_C["knights"] as Vector2) + Vector2(0, 150)
	await teleport_to(town_t)
	_check(player.position.distance_to(town_t) < 300.0 and not is_blocked(player.position), "телепорт в город рыцарей (%s)" % str(player.position), fails)
	await get_tree().create_timer(0.7).timeout
	_check(cat_n.global_position.distance_to(player.global_position) < 160.0, "кот сразу рядом после телепорта (%d)" % int(cat_n.global_position.distance_to(player.global_position)), fails)
	var prison_door: Node2D = null
	for dd in get_tree().get_nodes_in_group("house_doors"):
		if String(dd.get("kind")) == "prison" and String(dd.get("land")) == "knights":
			prison_door = dd
	_check(prison_door != null, "в городе рыцарей стоит тюрьма", fails)
	inside = true
	await teleport_to((WD.TOWN_C["cats"] as Vector2) + Vector2(0, 150))
	_check(not inside, "телепорт выводит из дома", fails)
	# ---- камни и руды
	var rk: Node = get_tree().get_first_node_in_group("rocks18")
	var gp: Vector2 = SCN.find_home("grotto")
	await teleport_to(gp)
	await get_tree().create_timer(0.3).timeout
	var kinds: Dictionary = {}
	var rec_h: Dictionary = {}
	var rec_s: Dictionary = {}
	var rec_o: Dictionary = {}
	var rec_l: Dictionary = {}
	var best_h: float = 1e9
	for rec in (rk.call("near", gp, 2800.0) as Array):
		var kd: String = String(rec["kind"])
		kinds[kd] = int(kinds.get(kd, 0)) + 1
		var dist_r: float = (rec["p"] as Vector2).distance_to(gp)
		if kd == "h" and dist_r < best_h:
			best_h = dist_r
			rec_h = rec
		if kd == "s" and rec_s.is_empty():
			rec_s = rec
		if kd == "ore" and rec_o.is_empty():
			rec_o = rec
		if kd == "l" and rec_l.is_empty():
			rec_l = rec
	_check(kinds.has("s") and kinds.has("m") and kinds.has("l") and kinds.has("h") and kinds.has("ore"), "в гротах лежат камни всех размеров и руда: %s" % str(kinds), fails)
	Game.fatigue = 0.0
	Game.inventory.clear()
	Game.hotbar = ["", "", "", "", "", "", "", "", ""]
	if not rec_s.is_empty():
		player.position = (rec_s["p"] as Vector2) + Vector2(0, 14)
		rk.call("act", rec_s, false)
		_check(Game.get_count("stone_s") == 1 and not is_instance_valid(rec_s["spr"]) or Game.get_count("stone_s") == 1, "маленький камушек поднимается руками", fails)
	if not rec_h.is_empty():
		player.position = (rec_h["p"] as Vector2) + Vector2(0, 24)
		rk.call("act", rec_h, false)
		_check(int(rec_h["hp"]) == 9, "огромный валун руками не берётся и не ломается", fails)
		Game.add_item("pickaxe")
		Game.hotbar[0] = "pickaxe"
		Game.hot_sel = 0
		_check(Game.has_tool("pickaxe"), "кирка в руках", fails)
		var hits0: int = 0
		while int(rec_h["hp"]) > 0 and hits0 < 12:
			rk.call("hit", rec_h)
			hits0 += 1
		_check(hits0 == 9, "огромный валун ломается за 9 ударов киркой (%d)" % hits0, fails)
		await get_tree().create_timer(3.5).timeout
		_check(Game.get_count("stone_l") >= 1 and Game.get_count("stone_m") >= 2, "из валуна выпали камни (б: %d, с: %d)" % [Game.get_count("stone_l"), Game.get_count("stone_m")], fails)
	if not rec_o.is_empty():
		player.position = (rec_o["p"] as Vector2) + Vector2(0, 26)
		var oid2: String = "ore_" + String(rec_o["id"])
		var hit_o: int = 0
		while int(rec_o["hp"]) > 0 and hit_o < 12:
			rk.call("hit", rec_o)
			hit_o += 1
		await get_tree().create_timer(3.0).timeout
		_check(Game.get_count(oid2) >= 2, "из месторождения добыта руда «%s» ×%d" % [oid2, Game.get_count(oid2)], fails)
	if not rec_l.is_empty():
		player.position = (rec_l["p"] as Vector2) + Vector2(0, 22)
		rk.call("act", rec_l, false)
		await get_tree().create_timer(0.5).timeout
		_check(not is_instance_valid(rec_l["spr"]) or int(rec_l["hp"]) < 4, "большой камень поддаётся кирке", fails)
	# ---- закон и тюрьма
	var lw: Node = get_tree().get_first_node_in_group("law18")
	await teleport_to((WD.TOWN_C["cats"] as Vector2) + Vector2(0, 150))
	Game.coins = 120
	Game.rep["cats"] = 10
	lw.call("report", "cats", "тест", 1)
	_check(not bool(lw.get("jailed")), "первый проступок — только предупреждение", fails)
	lw.call("report", "cats", "тест", 2)
	await get_tree().create_timer(3.6).timeout
	_check(bool(lw.get("jailed")) and visiting != null and String(visiting.get("kind")) == "prison", "арест: героиня в тюрьме города", fails)
	_check(Game.coins < 120, "штраф удержан (монет %d)" % Game.coins, fails)
	_check(room_owner != null and room_owner.has_meta("jailer"), "в тюрьме есть тюремщица", fails)
	player.position = ROOM_ORG + Vector2(320, 296)
	await get_tree().create_timer(0.4).timeout
	_check(visiting != null and player.position.y - ROOM_ORG.y < 290.0, "дверь заперта: арестованную не выпускают", fails)
	var bail: int = int(lw.call("bail_cost"))
	_check(bail > 0 and float(lw.get("sentence_h")) > 0.0, "залог %d, срок %d ч" % [bail, int(lw.get("sentence_h"))], fails)
	Game.coins = 1
	_check(not bool(lw.call("pay_bail")), "без денег залог не внести", fails)
	Game.coins = 500
	lw.call("pay_bail")
	await get_tree().create_timer(2.0).timeout
	_check(not bool(lw.get("jailed")) and visiting == null, "залог внесён — героиня на свободе", fails)
	# второй арест: отсидеть срок
	var day0: int = Game.day
	var min0: float = Game.minutes
	lw.call("report", "knights", "тест", 3)
	await get_tree().create_timer(3.6).timeout
	_check(bool(lw.get("jailed")) and String(visiting.get("land")) == "knights", "арест в Кронхольме — своя тюрьма", fails)
	lw.call("serve")
	await get_tree().create_timer(5.5).timeout
	_check(not bool(lw.get("jailed")) and visiting == null and (Game.day > day0 or Game.minutes > min0 + 300.0), "срок отсижен, время прошло", fails)
	# ---- услуги, задания и письма (жительница города кошек)
	await teleport_to((WD.TOWN_C["cats"] as Vector2) + Vector2(0, 150))
	await get_tree().create_timer(0.3).timeout
	var npc18: Node = null
	for itn in get_tree().get_nodes_in_group("interactables"):
		if itn.get("npc_name") != null and String(itn.get("land")) == "cats" and String(itn.get("role")) == "житель" and String(itn.get("npc_name")) != "":
			npc18 = itn
			break
	_check(npc18 != null, "в городе кошек есть жительницы", fails)
	var dlg: Node = get_tree().get_first_node_in_group("dialog_ui")
	if npc18 != null and dlg != null:
		Game.rep["cats"] = 20
		Game.minutes = 10.0 * 60.0
		Game.fatigue = 0.0
		Game.inventory.clear()
		Game.add_item("mint", 6)
		Game.add_item("lavender", 3)
		Game.add_item("vigor_tea", 2)
		Game.add_item("water_cold", 1)
		Game.add_item("stone_m", 1)
		dlg.call("start", npc18)
		var acts: Array = []
		for op in (dlg.get("options") as Array):
			acts.append(String(op[1]))
		_check("sv_menu" in acts and "sv_steal" in acts, "в разговоре есть «Предложить услугу» и воровство", fails)
		var wants: Array = SVD18.wants(npc18)
		_check(wants.size() == 3 and wants[0] != wants[1] and wants[1] != wants[2], "жительница хочет 3 разные услуги: %s" % str(wants), fails)
		var all_sv: Array = SVD18.SERVICE_ORDER
		var paid_ok: bool = true
		for sv in all_sv:
			var c0: int = Game.coins
			Game.minutes = 10.0 * 60.0
			SVD18.done.clear()
			SVD18.handle(dlg, "sv:" + String(sv))
			if String(sv) in wants:
				if Game.coins <= c0:
					paid_ok = false
					print("  услуга не оплачена: ", sv)
				Game.add_item("mint", 3)
				Game.add_item("lavender", 3)
				Game.add_item("vigor_tea", 1)
				Game.add_item("water_cold", 1)
				Game.add_item("stone_m", 1)
			else:
				if Game.coins != c0:
					paid_ok = false
					print("  ненужная услуга оплачена: ", sv)
		_check(paid_ok, "нужные услуги оплачиваются, ненужные — вежливо отклоняются", fails)
		dlg.call("close")
		# задания (v24: их дают только торговки — на время проверки она хозяйка лавки)
		npc18.set("role", "торговец")
		var qn: Node = get_tree().get_first_node_in_group("quests18")
		var offer: Dictionary = {}
		var d_try: int = 0
		while offer.is_empty() and d_try < 30:
			Game.day += 1
			d_try += 1
			offer = qn.call("offer_for", npc18)
		_check(not offer.is_empty(), "торговка предлагает задание (через %d дн.)" % d_try, fails)
		if not offer.is_empty():
			var offer2: Dictionary = qn.call("offer_for", npc18)
			_check(String(offer["title"]) == String(offer2["title"]), "предложение на день не меняется", fails)
			var rep0: int = Game.rep_of("cats")
			var coins0: int = Game.coins
			qn.call("accept", offer)
			_check((qn.get("active") as Array).size() == 1 and not bool(qn.call("can_turn_in", offer)), "задание принято: «%s»" % String(offer["title"]), fails)
			qn.call("cheat_complete", offer)
			_check(bool(qn.call("can_turn_in", offer)), "условие выполнено", fails)
			dlg.call("start", npc18)
			SVD18.handle(dlg, "qv_ask")
			dlg.call("close")
			_check((qn.get("active") as Array).is_empty() and int(qn.get("done_count")) == 1 and Game.coins > coins0 and Game.rep_of("cats") > rep0, "награда выдана: монеты и уважение", fails)
		npc18.set("role", "житель")
		# все виды заданий строятся
		var rr: RandomNumberGenerator = RandomNumberGenerator.new()
		rr.seed = 5
		for qt in ["herbs", "shrooms", "cat", "stone", "ore", "star", "food", "potion", "bugs"]:
			for ql in ["cats", "dwarves", "mages", "gothic"]:
				var qq: Dictionary = qn.call("_build", qt, "Проверка", ql, "житель", "catgirl_choco", rr)
				_check(not qq.is_empty() and qq.has("reward") and String(qq["text"]) != "", "задание «%s» в «%s»: %s" % [qt, ql, String(qq.get("title", "?"))], fails)
		# потерявшаяся кошка
		var cq: Dictionary = qn.call("_build", "cat", "Проверка", "cats", "житель", "catgirl_choco", rr)
		qn.call("accept", cq)
		_check((qn.get("cats") as Dictionary).has(int(cq["id"])), "потерявшаяся кошка появилась в лесу", fails)
		_check(String(cq["text"]).contains("Искать"), "в задании указано, где искать", fails)
		qn.call("cat_found", int(cq["id"]))
		_check(bool(qn.call("can_turn_in", cq)), "кошка найдена — можно сдавать", fails)
		qn.call("abandon", cq)
	# ---- дальше по карте: большой мир собирается из новых лесов
	await teleport_to(SCN.find_home("wild_pine_nw"))
	_check(WD.in_world(player.position) and not is_blocked(player.position), "дремучий бор на севере-западе: можно стоять", fails)
	Game.god_mode = false


## v17: еда, листья деревьев, насекомые в котёл, советы -> книга, вербовка, пеньки, мелкая сетка сумки
func _test_v17(fails: Array) -> void:
	var FD17 = preload("res://food_db.gd")
	var TD17 = preload("res://tree_db.gd")
	var TP17 = preload("res://tips_db.gd")
	var IT17 = preload("res://items_db.gd")
	# ---- еда
	_check(FD17.ORDER.size() >= 100, "еды в игре: %d (>=100)" % FD17.ORDER.size(), fails)
	var missing: int = 0
	for fk in FD17.ORDER:
		if not ResourceLoader.exists("res://art/food_%s.png" % String(fk)):
			missing += 1
	_check(missing == 0, "у всей еды есть значки", fails)
	Game.inventory.clear()
	Game.equip.clear()
	Game.consume_cd = 0.0
	Game.hunger = 0.8
	Game.add_item("food_apple", 2)
	_check(Game.eat_item("food_apple") and Game.hunger < 0.8 and Game.get_count("food_apple") == 1, "яблоко из сумки съедено", fails)
	Game.consume_cd = 0.0
	Game.thirst = 0.8
	Game.add_item("food_milk")
	_check(Game.eat_item("food_milk") and Game.thirst < 0.8, "молоко выпито — жажда меньше", fails)
	_check(IT17.size("food_apple") == Vector2i(1, 1) and IT17.stack("food_apple") == 5, "еда 1×1, до 5 в клетке", fails)
	# рецепт на плите
	Game.inventory.clear()
	Game.add_item("food_apple")
	Game.add_item("honey")
	var rc17: Dictionary = FD17.find_recipe(func(rid: String) -> int: return Game.get_count(rid))
	_check(String(rc17.get("res", "")) == "food_pie_apple", "яблоко + мёд -> яблочный пирог", fails)
	# ---- сетка сумки
	_check(Game.GRID_COLS == 16 and Game.GRID_MAX_ROWS == 7, "сетка сумки 16×7 (клетки мельче)", fails)
	Game.equip.clear()
	_check(Game.grid_rows() == 5, "без рюкзака 5 рядов", fails)
	# ---- листья и насекомые в котле
	_check(TD17.is_leaf("leaf_tree_apple") and ResourceLoader.exists("res://art/leaf_tree_apple.png"), "лист яблони — предмет со значком", fails)
	var RDB17 = preload("res://recipes_db.gd")
	_check(RDB17.is_ingredient("leaf_tree_a") and RDB17.is_ingredient("bug_bee"), "лист и пчела — ингредиенты котла", fails)
	_check(not RDB17.herb_props("bug_firefly").is_empty() and not RDB17.herb_props("leaf_pine_a").is_empty(), "у них есть свойства", fails)
	Game.inventory.clear()
	Game.cauldron_clear()
	Game.add_item("bug_firefly", 2)
	Game.add_item("leaf_tree_birch", 2)
	var bu: Node = get_tree().get_first_node_in_group("brew_ui")
	_check((bu.call("_shelf_items") as Array).has("bug_firefly") and (bu.call("_shelf_items") as Array).has("leaf_tree_birch"), "насекомое и лист лежат на полке стола зельевара", fails)
	_check(bool(bu.call("put_in_cauldron", {"id": "bug_firefly", "procs": []})), "светлячок брошен в котёл", fails)
	Game.take_item("bug_firefly")
	_check(int(RDB17.mix_list(Game.cauldron["ings"]).get("Свет", 0)) >= 2, "светлячок даёт Свет", fails)
	Game.cauldron_clear()
	# ---- окно веточек
	var tu: Node = get_tree().get_first_node_in_group("tree_ui")
	_check(tu != null, "окно веточек создано", fails)
	Game.ui_open = false
	Game.busy = false
	Game.tree_state.clear()
	Game.inventory.clear()
	Game.day = 10
	_check(bool(tu.call("open_tree", "tree_apple", "tree_apple:1,1")), "окно веточек открылось у яблони", fails)
	var nl0: int = int(tu.call("available", "leaf"))
	var nf0: int = int(tu.call("available", "fruit"))
	_check(nl0 >= 25, "на ветках много листьев (%d)" % nl0, fails)
	_check(nf0 >= 4, "на яблоне висят яблоки (%d)" % nf0, fails)
	tu.call("pick_first", "leaf")
	tu.call("pick_first", "fruit")
	_check(int(tu.call("available", "leaf")) == nl0 - 1 and int(tu.call("available", "fruit")) == nf0 - 1, "сорванное с ветки пропадает", fails)
	tu.call("close")
	_check(Game.get_count("leaf_tree_apple") == 1, "листик в сумке", fails)
	_check(Game.get_count("food_apple") + Game.get_count("food_apple_green") + Game.get_count("food_apple_golden") == 1, "яблоко в сумке", fails)
	_check(not Game.ui_open, "окно закрылось", fails)
	# то же дерево позже: сорванное ещё не выросло, потом отрастает
	tu.call("open_tree", "tree_apple", "tree_apple:1,1")
	_check(int(tu.call("available", "leaf")) == nl0 - 1, "в тот же день листья не отросли", fails)
	tu.call("close")
	Game.day = 13
	tu.call("open_tree", "tree_apple", "tree_apple:1,1")
	_check(int(tu.call("available", "leaf")) == nl0 and int(tu.call("available", "fruit")) == nf0, "через 3 дня листья и яблоки отросли", fails)
	tu.call("close")
	_check(not bool(tu.call("open_tree", "dead_tree_a", "x")), "у сухого дерева нечего брать", fails)
	# ---- пенёк тает за 5 дней
	var hs17: Node = homestead
	var fake_st: Sprite2D = Sprite2D.new()
	fake_st.texture = load("res://art/stump_cut.png")
	add_child(fake_st)
	(hs17.get("stumps") as Array).append([fake_st, float(Game.day) * 1440.0 + Game.minutes])
	hs17.set("_stump_t", 5.0)
	hs17.call("_update_stumps", 0.0)
	_check(is_instance_valid(fake_st) and fake_st.modulate.a > 0.95, "свежий пенёк виден", fails)
	Game.day += 2
	hs17.set("_stump_t", 5.0)
	hs17.call("_update_stumps", 0.0)
	_check(fake_st.modulate.a < 0.8 and fake_st.modulate.a > 0.1 and fake_st.scale.x < 1.0, "через 2 дня пенёк тает понемногу", fails)
	Game.day += 4
	hs17.set("_stump_t", 5.0)
	hs17.call("_update_stumps", 0.0)
	await get_tree().process_frame
	_check(not is_instance_valid(fake_st) or fake_st.is_queued_for_deletion(), "через 5 дней пенька нет", fails)
	# ---- советы -> записи в книге
	_check(TP17.count() >= 400, "советов в игре: %d (>=400)" % TP17.count(), fails)
	Game.notes.clear()
	Game.misc_notes.clear()
	Game.tips_heard.clear()
	var tip_sh: Dictionary = TP17.get_tip("sw_chanterelle")
	_check(Game.learn_tip(tip_sh) and (Game.notes.get("chanterelle", []) as Array).size() == 1, "совет о лисичках записан на страничку гриба", fails)
	_check(not Game.learn_tip(tip_sh), "тот же совет второй раз не пишется", fails)
	Game.learn_tip(TP17.get_tip("hw_mint"))
	_check((Game.notes.get("mint", []) as Array).size() == 1, "совет о мяте — в страничку травы", fails)
	Game.learn_tip(TP17.get_tip("fs_apple"))
	_check((Game.notes.get("food_apple", []) as Array).size() == 1, "совет об яблоке — в страничку еды", fails)
	Game.learn_tip(TP17.get_tip("h40"))
	_check(Game.misc_notes.size() == 1, "совет без страницы — в «Заметки»", fails)
	# разные жительницы знают разное
	var said: Dictionary = {}
	for tn in ["catgirl_mira", "catgirl_ryzhik", "elf_lirael", "orc_grasha", "dwarf_tova", "mage_aurel", "goblin_pip", "kitsune_hana"]:
		var tp: Dictionary = TP17.pick_for(tn, "", "житель", NPC17.land_of(tn))
		said[String(tp.get("id", ""))] = true
	_check(said.size() >= 6, "жительницы советуют разное (%d разных из 8)" % said.size(), fails)
	# книга
	var bk17: CanvasLayer = book
	bk17.call("open")
	bk17.call("set_tab", "shroom")
	bk17.set("selected", "chanterelle")
	bk17.call("refresh")
	_check(String((bk17.get("title_l") as Label).text) == "Лисичка", "в книге страница гриба: слышала о лисичке — имя открыто", fails)
	_check((bk17.get("notes_l") as Label).text.contains("✎"), "на страничке гриба — запись жителя", fails)
	bk17.call("set_tab", "food")
	bk17.set("selected", "apple")
	bk17.call("refresh")
	_check(String((bk17.get("title_l") as Label).text) == "Яблоко" and (bk17.get("notes_l") as Label).text.contains("✎"), "страничка еды с записью", fails)
	_check((bk17.get("slots") as Array).size() == FD17.ORDER.size(), "в книге вся еда: %d клеток" % (bk17.get("slots") as Array).size(), fails)
	bk17.call("set_tab", "notes")
	_check((bk17.get("notes_a") as Label).text.contains("•") or (bk17.get("notes_b") as Label).text.contains("•"), "вкладка «Заметки» показывает записи", fails)
	bk17.call("set_tab", "herb")
	bk17.call("close")
	# ---- вербовка
	var rn: Node = get_tree().get_first_node_in_group("recruit")
	_check(rn != null, "менеджер вербовки есть", fails)
	var n_free: int = 0
	var n_money: int = 0
	var n_food: int = 0
	for tex in NPC17.PEOPLE.keys():
		var pf: Dictionary = RECR17.profile(String(tex), "житель", NPC17.land_of(String(tex)))
		match String(pf["type"]):
			"free":
				n_free += 1
			"money":
				n_money += 1
			"food":
				n_food += 1
	_check(n_free > 5 and n_money > 5 and n_food > 5, "есть три вида условий: бесплатно %d, за деньги %d, за еду %d" % [n_free, n_money, n_food], fails)
	_check(not bool(RECR17.profile("catgirl_queen", "лидер", "cats")["can"]), "лидер не вербуется", fails)
	var test_npc: Node2D = Node2D.new()
	test_npc.set_script(load("res://catgirl.gd"))
	objects.add_child(test_npc)
	test_npc.call("setup", "catgirl_mira", player.position + Vector2(40, 0))
	var pfm: Dictionary = RECR17.profile("catgirl_mira", "житель", "cats")
	Game.team.clear()
	_check(bool(rn.call("join", test_npc, pfm)) and Game.team.size() == 1 and bool(test_npc.get("follower")), "жительница пошла за героиней", fails)
	var sp0: float = Game.stat("speed")
	(Game.team[0] as Dictionary)["perk"] = {"speed": 9.0}
	_check(Game.stat("speed") >= sp0 + 8.0 or Game.stat("speed") >= 9.0, "бонус спутницы прибавляется к характеристикам", fails)
	test_npc.global_position = player.global_position + Vector2(300, 0)
	for i17 in range(40):
		await get_tree().physics_frame
	_check(test_npc.global_position.distance_to(player.global_position) < 280.0, "спутница догоняет героиню", fails)
	# голодает и уходит
	(Game.team[0] as Dictionary)["req"] = "food"
	(Game.team[0] as Dictionary)["likes"] = "fruit"
	(Game.team[0] as Dictionary)["loyalty"] = 0.3
	Game.inventory.clear()
	rn.call("on_new_day")
	_check(Game.team.is_empty() and not bool(test_npc.get("follower")), "без еды спутница голодает и уходит", fails)
	# за деньги: платит жалованье
	rn.call("join", test_npc, pfm)
	(Game.team[0] as Dictionary)["req"] = "money"
	(Game.team[0] as Dictionary)["wage"] = 7
	(Game.team[0] as Dictionary)["loyalty"] = 0.5
	Game.coins = 20
	rn.call("on_new_day")
	_check(Game.coins == 13 and float((Game.team[0] as Dictionary)["loyalty"]) > 0.5, "жалованье выплачено, лояльность выросла", fails)
	Game.coins = 0
	rn.call("on_new_day")
	rn.call("on_new_day")
	_check(Game.team.is_empty(), "не платишь — уходит", fails)
	# за еду: любимое блюдо кормит
	rn.call("join", test_npc, pfm)
	(Game.team[0] as Dictionary)["req"] = "food"
	(Game.team[0] as Dictionary)["likes"] = "fruit"
	(Game.team[0] as Dictionary)["loyalty"] = 0.5
	Game.add_item("food_apple")
	rn.call("on_new_day")
	_check(Game.get_count("food_apple") == 0 and float((Game.team[0] as Dictionary)["loyalty"]) > 0.55, "любимый фрукт съеден — лояльность выросла", fails)
	Game.team.clear()
	test_npc.queue_free()
	Game.coins = 0
	# ---- вербовка через диалог: три вида условий
	var dlg17: Node = get_tree().get_first_node_in_group("dialog_ui")
	Game.team.clear()
	Game.rep.clear()
	Game.coins = 500
	var by_type: Dictionary = {}
	for tex2 in NPC17.PEOPLE.keys():
		var p2: Dictionary = RECR17.profile(String(tex2), "житель", NPC17.land_of(String(tex2)))
		if not by_type.has(String(p2["type"])) and String(tex2).begins_with("catgirl"):
			by_type[String(p2["type"])] = String(tex2)
	for tp2 in ["free", "money", "food"]:
		if not by_type.has(tp2):
			for tex3 in NPC17.PEOPLE.keys():
				var p3: Dictionary = RECR17.profile(String(tex3), "житель", NPC17.land_of(String(tex3)))
				if String(p3["type"]) == tp2 and not by_type.values().has(String(tex3)):
					by_type[tp2] = String(tex3)
					break
	for tp3 in ["free", "money", "food"]:
		Game.team.clear()
		var tx3: String = String(by_type[tp3])
		var dn: Node2D = Node2D.new()
		dn.set_script(load("res://catgirl.gd"))
		objects.add_child(dn)
		dn.call("setup", tx3, player.position + Vector2(50, 0))
		var pf3: Dictionary = RECR17.profile(tx3, "житель", NPC17.land_of(tx3))
		Game.rep[NPC17.land_of(tx3)] = 90      # дружба: условия по репутации выполнены
		Game.ui_open = false
		dlg17.call("start", dn)
		var idx_r: int = -1
		for oi in range((dlg17.get("options") as Array).size()):
			if String((dlg17.get("options") as Array)[oi][1]) == "recruit":
				idx_r = oi
		_check(idx_r >= 0, "в разговоре есть «Пойдёшь со мной?» (%s: %s)" % [tx3, tp3], fails)
		dlg17.call("_choose", idx_r)
		if tp3 == "money":
			_check(String((dlg17.get("options") as Array)[0][1]) == "pay_join", "за деньги: предлагает заплатить %d" % int(pf3["fee"]), fails)
			var c0: int = Game.coins
			dlg17.call("_choose", 0)
			_check(Game.team.size() == 1 and Game.coins == c0 - int(pf3["fee"]), "за деньги: заплатила и пошла", fails)
		elif tp3 == "food":
			Game.inventory.clear()
			Game.add_item("food_" + String(FD17.ORDER[0]))
			# нужной еды нет — отказывает, угостить нечем; кладём любимую
			var liked: Array = FD17.of_kind(String(pf3["likes"]))
			Game.add_item(String(liked[0]))
			dlg17.call("start", dn)
			var idx_r2: int = -1
			for oi2 in range((dlg17.get("options") as Array).size()):
				if String((dlg17.get("options") as Array)[oi2][1]) == "recruit":
					idx_r2 = oi2
					break
			dlg17.call("_choose", idx_r2)
			var n_opts: Array = dlg17.get("options") as Array
			var jf: int = -1
			for oi3 in range(n_opts.size()):
				if String(n_opts[oi3][1]).begins_with("joinfeed:"):
					jf = oi3
					break
			_check(jf >= 0, "за еду: предлагает угостить", fails)
			dlg17.call("_choose", jf)
			_check(Game.team.size() == 1, "за еду: поела и пошла", fails)
		else:
			_check(Game.team.size() == 1, "бесплатно: пошла сразу", fails)
		dlg17.call("close")
		Game.ui_open = false
		Game.team.clear()
		dn.queue_free()
	Game.coins = 0
	Game.rep.clear()


# ------------------------------------------------------------------ скриншоты

func _screenshot_mode(path: String) -> void:
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	var hour_v: float = 10.0
	var open_book: bool = false
	var open_brew: bool = false
	var harvest_ids: PackedStringArray = PackedStringArray()
	var visitor: bool = false
	var bugs_shot: bool = false
	var go_inside: bool = false
	var mess_kind: String = ""
	var mess_wait: float = 3.0
	var cast_u: float = -1.0
	var walkin: bool = false
	var turn_from: int = -1
	var turn_to: int = 0
	var at: Vector2 = Vector2(1120, 600) + home_off()
	var day_v: int = 4
	for a in OS.get_cmdline_user_args():
		var s: String = String(a)
		if s == "--mermaid":
			Game.mermaid_t = Game.MERMAID_MIN
		elif s.begins_with("--day="):
			day_v = int(s.substr(6))
		elif s == "--club":
			get_tree().create_timer(1.0).timeout.connect(func() -> void:
				live.call("enter"))
		elif s == "--goals":
			get_tree().create_timer(1.5).timeout.connect(func() -> void:
				(get_node("V22") as Node).call("toggle_window"))
		elif s.begins_with("--time="):
			hour_v = float(s.substr(7))
		elif s == "--book":
			open_book = true
		elif s.begins_with("--bookpage="):
			open_book = true
			book.set("selected", s.substr(11))
			Game.fish_caught = {"perch": 3, "crucian": 1}
			Game.inventory["perch"] = 2
		elif s.begins_with("--mess="):
			mess_kind = s.substr(7)
		elif s.begins_with("--messwait="):
			mess_wait = float(s.substr(11))
		elif s.begins_with("--shame="):
			Game.shame = float(s.substr(8))
		elif s == "--bugs":
			bugs_shot = true
		elif s == "--inside":
			go_inside = true
		elif s.begins_with("--cast="):
			cast_u = float(s.substr(7))
		elif s == "--brew":
			open_brew = true
		elif s.begins_with("--wear="):
			for wp in s.substr(7).split(","):
				var kv: PackedStringArray = String(wp).split(":")
				if kv.size() == 2:
					Game.equip[kv[0]] = kv[1]
			Game.equip_changed.emit()
		elif s.begins_with("--harvest="):
			harvest_ids = s.substr(10).split(",")
		elif s == "--visitor":
			visitor = true
		elif s.begins_with("--turn="):
			var tt: PackedStringArray = s.substr(7).split(",")
			turn_from = int(tt[0])
			turn_to = int(tt[1])
		elif s.begins_with("--fade="):
			var fp: PackedStringArray = s.substr(7).split(",")
			world.set("FADE_TEST", Vector2(float(fp[0]), float(fp[1])))
		elif s.begins_with("--zoom="):
			zoom_target = float(s.substr(7))
			cam.zoom = Vector2(zoom_target, zoom_target)
		elif s == "--walkin":
			walkin = true
		elif s.begins_with("--face="):
			player.call("react", s.substr(7), 99.0)
			player.set("blink_t", 99.0)
		elif s.begins_with("--petkind="):
			player.set("pet_kind", (int(s.substr(10)) + 2) % 3)
		elif s == "--pet":
			get_tree().create_timer(0.6).timeout.connect(func() -> void:
				for it in get_tree().get_nodes_in_group("interactables"):
					if String((it as Node).call("get_prompt")) == "Погладить кота":
						player.position = (it as Node2D).global_position + Vector2(28, 4)
						it.call("interact"))
		elif s.begins_with("--facing="):
			player.set("facing", int(s.substr(9)))
			player.set("want_facing", int(s.substr(9)))
		elif s.begins_with("--pos="):
			var xy: PackedStringArray = s.substr(6).split(",")
			at = Vector2(float(xy[0]), float(xy[1]))
	Game.time_frozen = true
	Game.minutes = hour_v * 60.0
	Game.day = day_v
	Game.day_changed.emit()
	var plots: Array = get_tree().get_nodes_in_group("plots")
	var states: Array = [["mint", 3, false], ["lavender", 3, false], ["chamomile", 3, true], ["mint", 1, true], ["lavender", 2, true], ["", 0, false], ["chamomile", 2, false], ["mint", 0, true]]
	for i in range(mini(plots.size(), states.size())):
		plots[i].call("debug_set", states[i][0], states[i][1], states[i][2])
	if Game.new_game_ready:
		for hk in ["mint", "lavender", "chamomile"]:
			Game.inventory[hk] = int(Game.inventory.get(hk, 0)) + 3
		Game.inventory["porcini"] = 2
		Game.inventory["vigor_tea"] = 2
	else:
		Game.inventory = {"mint": 5, "lavender": 2, "chamomile": 3}
	Game.discovered = {"mint": true, "lavender": true, "chamomile": true}
	player.position = at
	if at.y > 90000.0:
		sea.call("set_diving", true)
	cam.reset_smoothing()
	world.call("build_around", at)
	biome_tint = world.call("ambient_tint", at)
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.has("--run"):
		# бежит вправо-вниз: держим скорость бега и снимаем кадр посреди шага
		for kc in [KEY_SHIFT, KEY_D]:
			var ev: InputEventKey = InputEventKey.new()
			ev.physical_keycode = kc
			ev.keycode = kc
			ev.pressed = true
			Input.parse_input_event(ev)
		await get_tree().create_timer(float(OS.get_environment("RUN_T")) if OS.get_environment("RUN_T") != "" else 0.9).timeout
	if args.has("--chop"):
		# проверка хозяйства: срубить дерево, посадить саженец, собрать верстак и поставить его
		await get_tree().create_timer(0.5).timeout
		var tr: Sprite2D = null
		for t in yard_trees:
			if is_instance_valid(t) and (tr == null or (t as Sprite2D).global_position.distance_to(at) < tr.global_position.distance_to(at)):
				tr = t
		player.position = tr.global_position + Vector2(0, 8)
		Game.inventory["axe"] = 1
		Game.hotbar[0] = "axe"
		Game.hot_sel = 0
		await get_tree().process_frame
		for i in range(6):
			homestead.set("cool", 0.0)
			homestead.call("chop_at", tr.global_position + Vector2(0, -20))
			await get_tree().create_timer(0.1).timeout
		await get_tree().create_timer(2.0).timeout
		print("CHOP logs=%d saplings=%s valid=%s" % [Game.get_count("log"), str(Game.inventory.keys()), str(is_instance_valid(tr))])
		Game.inventory["log"] = 20
		Game.coins = 100
		Game.take_item("log", 6)
		Game.add_item("kit:workbench")
		player.position = Vector2(960, 560)
		Game.hot_sel = Game.hotbar.find("kit:workbench")
		homestead.set("cool", 0.0)
		homestead.call("_use", false)
		var sap: String = ""
		for k in Game.inventory.keys():
			if String(k).begins_with("sapling:"):
				sap = k
		Game.hot_sel = Game.hotbar.find(sap)
		player.position = Vector2(1200, 700)
		homestead.set("cool", 0.0)
		homestead.call("_use", false)
		print("BUILD placed=%s" % str(homestead.get("placed")))
		await get_tree().create_timer(0.8).timeout
	if args.has("--buildall"):
		# проверка: поставить каждую постройку по очереди и вывести, что получилось
		await get_tree().create_timer(0.5).timeout
		var pr: Rect2 = homestead.call("plot_rect")
		var bi: int = 0
		for bk in (preload("res://items_db.gd").BUILD as Dictionary).keys():
			var bp: Vector2 = pr.position + Vector2(60.0 + float(bi % 5) * 90.0, 60.0 + float(bi / 5) * 90.0)
			bi += 1
			var why: String = homestead.call("_can_place", bk, bp)
			print("BUILDALL %s at %s can=%s" % [bk, str(bp), why])
			homestead.call("build", bk, bp)
			await get_tree().process_frame
			await get_tree().process_frame
		print("BUILDALL done placed=%d" % (homestead.get("placed") as Array).size())
		await get_tree().create_timer(1.0).timeout
	if args.has("--perf"):
		# замер скорости: героиня бежит 6 секунд, считаем кадры без вертикальной синхронизации
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		if OS.get_environment("PERF_TOUR") != "":
			# сначала «обойти» все города — так, будто героиня долго путешествовала
			for land in (preload("res://towns.gd").TOWNS as Dictionary).keys():
				var tc: Vector2 = (preload("res://towns.gd").TOWNS[land] as Dictionary)["c"]
				player.position = tc
				world.call("build_around", tc)
				await get_tree().process_frame
			player.position = at
			world.call("build_around", at)
		await get_tree().create_timer(1.0).timeout
		for kc2 in [KEY_SHIFT, KEY_D]:
			var ev2: InputEventKey = InputEventKey.new()
			ev2.physical_keycode = kc2
			ev2.keycode = kc2
			ev2.pressed = true
			Input.parse_input_event(ev2)
		var f0: int = Engine.get_process_frames()
		var t0: int = Time.get_ticks_msec()
		var worst: float = 0.0
		while Time.get_ticks_msec() - t0 < 6000:
			await get_tree().process_frame
			worst = maxf(worst, get_process_delta_time())
		var fps: float = float(Engine.get_process_frames() - f0) / ((Time.get_ticks_msec() - t0) / 1000.0)
		print("PERF fps=%.1f worst_ms=%.1f nodes=%d" % [fps, worst * 1000.0, get_tree().get_node_count()])
		get_tree().quit()
		return
	for a2 in args:
		if String(a2).begins_with("--talk="):
			# разговор с ближайшим жителем; число — какой вариант выбрать (0 — только приветствие)
			await get_tree().create_timer(0.6).timeout
			var best: Node2D = null
			for n in get_tree().get_nodes_in_group("catgirls"):
				if (n as Node2D).is_visible_in_tree() and (best == null or (n as Node2D).global_position.distance_to(at) < best.global_position.distance_to(at)):
					best = n
			var dlg2: Node = get_tree().get_first_node_in_group("dialog_ui")
			if best != null:
				dlg2.call("start", best)
				for ch in String(a2).substr(7).split(","):
					if int(ch) > 0:
						await get_tree().create_timer(0.3).timeout
						dlg2.call("_choose", int(ch) - 1)
				await get_tree().create_timer(2.5).timeout
	# v19: сушилка (--dry), шахта (--mine), брошенные травы на столе зельевара (--brewthrow)
	if args.has("--dry"):
		Game.time_frozen = false
		for k19 in range(9):
			Game.dryer.append({"id": ["mint", "lavender", "chamomile", "nettle", "thyme", "calendula", "yarrow", "mint", "lavender"][k19], "hook": [0, 2, 3, 5, 7, 9, 12, 14, 19][k19], "t0": float(Game.day) * 1440.0 + Game.minutes - float(k19) * 50.0})
		Game.inventory["mint"] = 4
		Game.inventory["lavender"] = 2
		Game.inventory["chamomile"] = 3
		get_tree().get_first_node_in_group("dry_ui").call("open")
		get_tree().get_first_node_in_group("dry_ui").call("_release", Vector2(900, 400))
		await get_tree().create_timer(0.8).timeout
	if args.has("--mine"):
		Game.time_frozen = false
		await mine.call("enter", at)
		player.position = preload("res://mine.gd").ORG + Vector2(float(OS.get_environment("MX")) if OS.get_environment("MX") != "" else 1200.0, float(OS.get_environment("MY")) if OS.get_environment("MY") != "" else 400.0)
		cam.reset_smoothing()
		get_tree().get_first_node_in_group("darkness").set("torch_on", true)
		await get_tree().create_timer(1.2).timeout
	if args.has("--brewthrow"):
		Game.time_frozen = false
		Game.fatigue = 0.0
		brew_ui.call("open")
		for k20 in range(5):
			brew_ui.call("throw_ing", {"id": ["mint", "lavender", "chamomile", "nettle", "thyme"][k20], "procs": []}, Vector2(1350 + k20 * 90, 500), Vector2(randf_range(-200, 200), -300))
		await get_tree().create_timer(0.55).timeout
	# v18: тюрьма (--jail=земля), журнал заданий (--questlog), телепорт (--tele), камни (--rocks=ore|h|l)
	for a18 in args:
		if String(a18).begins_with("--rocks="):
			var want18: String = String(a18).substr(8)
			var rk18: Node = get_tree().get_first_node_in_group("rocks18")
			var best18: Dictionary = {}
			var bd18: float = 1e9
			for rec18 in (rk18.call("near", at, 3200.0) as Array):
				if String(rec18["kind"]) == want18 and (rec18["p"] as Vector2).distance_to(at) < bd18:
					bd18 = (rec18["p"] as Vector2).distance_to(at)
					best18 = rec18
			if not best18.is_empty():
				player.position = (best18["p"] as Vector2) + Vector2(40, 30)
				cam.reset_smoothing()
				world.call("build_around", player.position)
				print("ROCK %s at %s id=%s" % [want18, str(best18["p"]), str(best18["id"])])
		if String(a18).begins_with("--jail="):
			Game.time_frozen = false
			Game.coins = 90
			Game.busy = false
			get_tree().get_first_node_in_group("law18").call("arrest", String(a18).substr(7), "тест")
			await get_tree().create_timer(3.4).timeout
			Game.time_frozen = true
	if args.has("--questlog"):
		var qn18: Node = get_tree().get_first_node_in_group("quests18")
		var rr18: RandomNumberGenerator = RandomNumberGenerator.new()
		rr18.seed = 11
		for qt18 in ["cat", "herbs", "ore", "potion"]:
			var q18: Dictionary = qn18.call("_build", qt18, "Королева Мурлин" if qt18 == "ore" else "Тесса", "cats", "лидер" if qt18 == "ore" else "житель", "catgirl_queen", rr18)
			qn18.call("accept", q18)
		get_tree().get_first_node_in_group("quests18").get_parent().get_node("QuestUI").call("toggle")
	if args.has("--menu") or args.has("--newgame") or args.has("--newgame2") or args.has("--giver") or args.has("--tele"):
		var mn2: CanvasLayer = CanvasLayer.new()
		mn2.set_script(load("res://menu.gd"))
		add_child(mn2)
		mn2.call("setup", hud)
		mn2.call("show_menu")
		if args.has("--newgame") or args.has("--newgame2"):
			mn2.call("_open_newgame")
			if args.has("--newgame2"):
				mn2.set("ng_step", 1)
				mn2.call("_fill_newgame")
		if args.has("--giver"):
			Game.god_mode = true
			mn2.call("_update_god")
			mn2.call("_open_giver")
		if args.has("--tele"):
			Game.god_mode = true
			mn2.call("_update_god")
			mn2.call("_open_tp")
		if args.has("--godmenu"):
			Game.god_mode = true
			mn2.call("_update_god")
		if args.has("--slots"):
			mn2.call("_open_slots", "new")
		get_tree().paused = false
		await get_tree().create_timer(0.5).timeout
	# ранний доступ: --forgeui / --stallui (карточки), --stallshot (покупательница), --chron (летопись), --guide
	if args.has("--forgeui") or args.has("--stallui"):
		var kk: String = "forge" if args.has("--forgeui") else "stall"
		homestead.call("build", kk, at + Vector2(90, -30))
		for it_ea in [["stone_m", 4], ["log", 5], ["iron_bar", 3], ["ore_ember", 1], ["calm_tea", 3], ["mint_tea", 2]]:
			Game.add_item(String(it_ea[0]), int(it_ea[1]))
		Game.stall["cash"] = 42
		Game.stall["fame"] = 7
		await get_tree().process_frame
		homestead.call("open_menu", kk, get_tree().get_first_node_in_group(kk + "_ea"))
		await get_tree().create_timer(0.4).timeout
	if args.has("--stallshot"):
		homestead.call("build", "stall", at + Vector2(90, -30))
		Game.stall["goods"] = {"calm_tea": 3}
		await get_tree().process_frame
		paths.set("instant_customers", false)
		paths.call("send_customer", get_tree().get_first_node_in_group("stall_ea"))
		await get_tree().create_timer(4.0).timeout
	if args.has("--chron"):
		Game.chron("Начало пути: Травница. Дом — Старый двор.", "start")
		Game.chron("Открыла свою лавку зелий у дома.", "stall")
		Game.factions["cat_cult"] = {"favor": 12, "rank": 1, "task": {"item": "fish_any", "n": 2}, "since": 2}
		Game.pacts["cats"] = {"since": 3, "earned": 120}
		Game.chron("Заключила торговый союз с землёй Мурлыкино.", "pact")
		Game.add_title("partner")
		Game.smith_orders["knights"] = {"item": "guard_sword", "n": 3, "due": 9, "reward": 216}
		Game.counters["stall_open"] = 1
		paths.call("toggle_ui")
		await get_tree().create_timer(0.4).timeout
	if args.has("--guide"):
		Game.guide_step = 0
		Game.inventory.clear()
		Game.known_recipes.clear()
		await get_tree().create_timer(1.2).timeout
	if args.has("--shelf"):
		# лавка изнутри; с --shelfui — полка крупно
		await get_tree().create_timer(0.5).timeout
		var sd: Node2D = null
		for d2 in get_tree().get_nodes_in_group("house_doors"):
			if String((d2 as Node).get("kind")) == "shop" and (sd == null or (d2 as Node2D).global_position.distance_to(at) < sd.global_position.distance_to(at)):
				sd = d2
		Game.time_frozen = false
		Game.coins = 60
		await visit_house(sd)
		player.position = ROOM_ORG + Vector2(300, 196)
		player.set("facing", 1)
		cam.reset_smoothing()
		await get_tree().create_timer(0.6).timeout
		if args.has("--shelfui"):
			var sh0: Node = null
			for n0 in get_tree().get_nodes_in_group("interactables"):
				if String((n0 as Node).get_script().resource_path).ends_with("shop_shelf.gd"):
					sh0 = n0
					break
			if sh0 != null:
				sh0.call("interact")
			await get_tree().create_timer(0.4).timeout
	if args.has("--visit"):
		# зайти в ближайший дом (даже если он заперт) и подождать стражу
		await get_tree().create_timer(0.5).timeout
		var bd: Node2D = null
		for d in get_tree().get_nodes_in_group("house_doors"):
			var want_kind: String = OS.get_environment("VISIT_KIND")
			var okk: bool = bool((d as Node).get("private")) if want_kind == "" else String((d as Node).get("kind")) == want_kind
			if okk and (bd == null or (d as Node2D).global_position.distance_to(at) < bd.global_position.distance_to(at)):
				bd = d
		Game.time_frozen = false
		await visit_house(bd)
		await get_tree().create_timer(float(OS.get_environment("VISIT_T")) if OS.get_environment("VISIT_T") != "" else 2.0).timeout
	if args.has("--mimic"):
		await get_tree().create_timer(0.6).timeout
		for it in get_tree().get_nodes_in_group("interactables"):
			if String((it as Node).get_script().resource_path).ends_with("mimic.gd"):
				it.call("interact")
	if args.has("--map"):
		# прошла от дома на юг, в деревню кошек, и чуть на запад
		var trail: Array = [Vector2(960, 500), Vector2(960, 1200), Vector2(980, 1900), Vector2(1400, 1950), Vector2(400, 600), Vector2(-500, 620), Vector2(-960, 700)]
		for i in range(trail.size() - 1):
			for k in range(20):
				world.call("reveal", (trail[i] as Vector2).lerp(trail[i + 1], k / 20.0), 5.5)
		map_ui.call("toggle")
	if go_inside:
		_set_inside(true, IN_ORG + Vector2(330, 214))
		await get_tree().create_timer(0.3).timeout
		if OS.get_cmdline_user_args().has("--rod"):
			Game.has_rod = true
	if cast_u >= 0.0:
		var sps: Array = get_tree().get_nodes_in_group("fishing_spots")
		var sp1: Node2D = sps[0]
		Game.has_rod = true
		player.position = sp1.get("shore")
		cam.reset_smoothing()
		await get_tree().create_timer(0.3).timeout
		fishing_ui.call("open", sp1)
		fishing_ui.set("aim_u", cast_u)
		fishing_ui.set("t_aim", 99.0)
		fishing_ui.call("cast")
		await get_tree().create_timer(0.9).timeout
	last_order_day = Game.day
	if args.has("--allherbs") and open_book:
		# в книге: две трети трав найдены, остальные — тенью
		for i9 in range(DB.ORDER.size()):
			if i9 % 3 != 2:
				Game.inventory[String(DB.ORDER[i9])] = 1 + i9 % 4
				Game.discovered[String(DB.ORDER[i9])] = true
		book.set("selected", "moonbloom")
	# v17: книга по вкладкам, окно веточек, спутницы
	var FD17s = preload("res://food_db.gd")
	var TP17s = preload("res://tips_db.gd")
	for a17 in args:
		var s17: String = String(a17)
		if s17.begins_with("--booktab="):
			open_book = true
			var tb: String = s17.substr(10)
			for fk in FD17s.ORDER:
				if int(hash(fk)) % 3 != 0:
					Game.discovered["food_" + String(fk)] = true
			for sk in preload("res://wild_db.gd").SHROOMS.keys():
				if int(hash(sk)) % 3 != 0:
					Game.discovered[String(sk)] = true
			for tid in ["sw_chanterelle", "se_chanterelle", "sk_porcini", "fs_apple", "fd_apple", "fr0", "hw_mint", "hp_moonbloom", "h40", "h41", "h42", "h44", "h45", "h50", "h56", "h57", "h60", "h62", "h70"]:
				Game.learn_tip(TP17s.get_tip(tid))
			book.call("set_tab", tb)
			if tb == "shroom":
				book.set("selected", "chanterelle")
			elif tb == "food":
				book.set("selected", "apple")
	if open_book:
		book.call("open")
		book.call("refresh")
	for a18 in args:
		var s18: String = String(a18)
		if s18.begins_with("--twig="):
			var tu2: Node = get_tree().get_first_node_in_group("tree_ui")
			tu2.call("open_tree", s18.substr(7), s18.substr(7) + ":10,10")
			await get_tree().create_timer(0.3).timeout
			tu2.call("pick_first", "leaf")
			tu2.call("pick_first", "leaf")
			tu2.call("pick_first", "fruit")
			tu2.set("hover", 3)
			await get_tree().create_timer(0.25).timeout
	if args.has("--team"):
		# три спутницы идут за героиней
		var rn2: Node = get_tree().get_first_node_in_group("recruit")
		for tnm in ["catgirl_mira", "elf_lirael", "dwarf_tova"]:
			var cn: Node2D = Node2D.new()
			cn.set_script(load("res://catgirl.gd"))
			objects.add_child(cn)
			cn.call("setup", tnm, player.position + Vector2(60 + randf() * 30.0, 10))
			cn.set("blocked", Callable(self, "is_blocked"))
			var sp2: Sprite2D = cn.get("spr") as Sprite2D
			add_caster(sp2, true)
			sp2.material = char_light_mat(Vector2(8, 8), sp2)
			var fm2: ShaderMaterial = char_light_mat(Vector2(1, 1), sp2)
			fm2.set_shader_parameter("region_mode", true)
			(cn.get("face") as Sprite2D).material = fm2
			cn.set("face_mat", fm2)
			rn2.call("join", cn, RECR17.profile(tnm, "житель", NPC17.land_of(tnm)))
		await get_tree().create_timer(2.5).timeout
	if not harvest_ids.is_empty():
		var hvu: Node = get_tree().get_first_node_in_group("harvest_ui")
		if args.has("--knife"):
			Game.inventory["knife"] = 1
			Game.equip["main1"] = "knife"
		hvu.call("open", null, Array(harvest_ids))
		await get_tree().create_timer(0.5).timeout
		var pl: Array = hvu.get("plants")
		if pl.size() > 1 and not args.has("--knife"):
			hvu.set("grab", 1)
			pl[1]["pull"] = 0.6
			pl[1]["lift"] = 42.0
		hvu.set("mouse", Vector2(900, 520))
		hvu.set("prev_mouse", Vector2(900, 520))
		hvu.set("held", not args.has("--knife"))
		await get_tree().create_timer(0.3).timeout
	if open_brew:
		Game.inventory = {"mint": 6, "lavender": 4, "chamomile": 5, "nettle": 3}
		Game.discovered = {"mint": true, "lavender": true, "chamomile": true, "nettle": true}
		if args.has("--allherbs"):
			for hid in DB.ORDER:
				Game.inventory[String(hid)] = 2
				Game.discovered[String(hid)] = true
		for bi in ["water_cold", "water_warm", "water_hot", "spirit", "wax", "honey", "moon_dew", "bottle"]:
			Game.inventory[bi] = 2
		Game.known_recipes = {"warm_tea": {"base": "water", "temp": "warm", "ings": [{"id": "mint", "procs": ["dry"]}, {"id": "chamomile", "procs": []}]},
			"sleep_tea": {"base": "water", "temp": "warm", "ings": [{"id": "lavender", "procs": []}]}, "fire_brew": {}}
		brew_ui.call("open")
		Game.cauldron_clear()
		brew_ui.call("pour", "water_hot", 2.0)
		brew_ui.call("add_herb", "mint")
		Game.take_item("lavender")
		brew_ui.call("put_in_cauldron", {"id": "lavender", "procs": ["grind"]})
		Game.take_item("chamomile")
		(brew_ui.get("station") as Dictionary)["brazier"] = {"ing": {"id": "chamomile", "procs": []}, "t": 3.0}
		Game.take_item("nettle")
		(brew_ui.get("station") as Dictionary)["board"] = {"ing": {"id": "nettle", "procs": []}, "t": 0.6}
		Game.take_item("mint")
		(brew_ui.get("station") as Dictionary)["mortar"] = {"ing": {"id": "mint", "procs": []}, "t": 1.0}
		Game.take_item("lavender")
		(brew_ui.get("station") as Dictionary)["bowl"] = {"ing": {"id": "lavender", "procs": []}, "t": 1.5}
		await get_tree().create_timer(0.8).timeout
		if args.has("--book2"):
			brew_ui.set("book_open", true)
			brew_ui.set("mouse", Vector2(330, 120))
		if args.has("--brewres"):
			brew_ui.call("do_brew")
	if visitor:
		var v: Node2D = spawn_visitor("sleep_tea", false)
		await get_tree().create_timer(1.2).timeout
		v.call("interact")
	if turn_from >= 0:
		# разворот героини: снимаем голову на каждом промежуточном ракурсе
		player.set("facing", turn_from)
		player.set("want_facing", turn_to)
		await get_tree().create_timer(0.1).timeout
		player.set("facing", turn_from)
		var strip: Image = Image.create(9 * 120, 200, false, Image.FORMAT_RGBA8)
		for ti in range(9):
			await get_tree().create_timer(0.058).timeout
			var fr: Image = get_viewport().get_texture().get_image()
			strip.blit_rect(fr, Rect2i(900, 420, 120, 200), Vector2i(ti * 120, 0))
		strip.save_png(path)
		get_tree().quit()
		return
	if walkin:
		# житель посреди пути к дому (для проверки анимации ходьбы)
		var wv: Node2D = spawn_visitor("sleep_tea")
		wv.position = Vector2(900, 800)
		wv.set("route", [Vector2(1100, 650)])
	if bugs_shot:
		for bk in range(14):
			insects.call("balance")
		for ib in get_tree().get_nodes_in_group("insects"):
			if String(ib.get("state")) != "leave" and String(ib.get("kind")) not in ["aphid", "dung_beetle"]:
				var hm: Vector2 = ib.get("home")
				var rr: float = float(ib.get("radius")) * 0.6
				ib.position = hm + Vector2(randf_range(-rr, rr), randf_range(-rr, rr) * 0.6)
				ib.set("target", ib.position)
				ib.set("alt", float((ib.get("d") as Dictionary)["alt"]))
		await get_tree().create_timer(1.2).timeout
	if mess_kind != "":
		_on_accident(mess_kind)
		await get_tree().create_timer(mess_wait).timeout
	for a23 in OS.get_cmdline_user_args():
		if String(a23).begins_with("--v23="):
			await _shot23(String(a23).substr(6))
		if String(a23).begins_with("--v24="):
			await preload("res://test24.gd").new().shot(self, String(a23).substr(6))
		if String(a23).begins_with("--v25="):
			await preload("res://test25.gd").new().shot(self, String(a23).substr(6))
		if String(a23).begins_with("--v26ui="):
			await preload("res://test26ui.gd").new().shot(self, String(a23).substr(8))
		if String(a23).begins_with("--v29="):
			await preload("res://test29.gd").new().shot(self, String(a23).substr(6))
		if String(a23).begins_with("--v28="):
			await preload("res://test28.gd").new().shot(self, String(a23).substr(6))
		if String(a23).begins_with("--v26cats="):
			await preload("res://test26cats.gd").new().shot(self, String(a23).substr(10))
	await get_tree().create_timer(1.6).timeout
	for a27 in OS.get_cmdline_user_args():
		if String(a27).begins_with("--shotwait="):   # v27: подождать, пока травы мира проверят время и покажутся
			await get_tree().create_timer(float(String(a27).substr(11))).timeout
	var img: Image = get_viewport().get_texture().get_image()
	img.save_png(path)
	get_tree().quit()

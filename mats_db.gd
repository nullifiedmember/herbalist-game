extends RefCounted
## Материалы, мастерские, ловушки, постройки и места добычи (v20) — СГЕНЕРИРОВАНО tools/mats_design.py.
## Правки — в mats_design.py, потом `python tools/mats_design.py --write` (значки: --art).
## MATS: id -> [имя, вес, цена, значок, раздел, свойства для котла, [ширина, высота] в сумке, стопка]

const MATS: Dictionary = {
	"wood_tree_a": ["Дубовая чурка", 1.2, 3, "m20_wood_tree_a", "wood", {}, [2, 1], 5],
	"plank_tree_a": ["Дубовая доска", 0.8, 5, "m20_plank_tree_a", "wood", {}, [2, 1], 10],
	"bark_tree_a": ["Дубовая кора", 0.1, 2, "m20_bark_tree_a", "wood", {"Сила": 1}, [1, 1], 10],
	"wood_tree_b": ["Липовая чурка", 1.2, 3, "m20_wood_tree_b", "wood", {}, [2, 1], 5],
	"plank_tree_b": ["Липовая доска", 0.8, 5, "m20_plank_tree_b", "wood", {}, [2, 1], 10],
	"bark_tree_b": ["Липовая кора", 0.1, 2, "m20_bark_tree_b", "wood", {"Покой": 1}, [1, 1], 10],
	"wood_tree_c": ["Вязовая чурка", 1.2, 3, "m20_wood_tree_c", "wood", {}, [2, 1], 5],
	"plank_tree_c": ["Вязовая доска", 0.8, 5, "m20_plank_tree_c", "wood", {}, [2, 1], 10],
	"bark_tree_c": ["Вязовая кора", 0.1, 2, "m20_bark_tree_c", "wood", {"Исцеление": 1}, [1, 1], 10],
	"wood_tree_d": ["Ясеневая чурка", 1.2, 3, "m20_wood_tree_d", "wood", {}, [2, 1], 5],
	"plank_tree_d": ["Ясеневая доска", 0.8, 5, "m20_plank_tree_d", "wood", {}, [2, 1], 10],
	"bark_tree_d": ["Ясеневая кора", 0.1, 2, "m20_bark_tree_d", "wood", {"Свежесть": 1}, [1, 1], 10],
	"wood_pine_a": ["Сосновая чурка", 1.2, 3, "m20_wood_pine_a", "wood", {}, [2, 1], 5],
	"plank_pine_a": ["Сосновая доска", 0.8, 5, "m20_plank_pine_a", "wood", {}, [2, 1], 10],
	"bark_pine_a": ["Сосновая кора", 0.1, 2, "m20_bark_pine_a", "wood", {"Свежесть": 1, "Тепло": 1}, [1, 1], 10],
	"wood_pine_b": ["Еловая чурка", 1.2, 3, "m20_wood_pine_b", "wood", {}, [2, 1], 5],
	"plank_pine_b": ["Еловая доска", 0.8, 5, "m20_plank_pine_b", "wood", {}, [2, 1], 10],
	"bark_pine_b": ["Еловая кора", 0.1, 2, "m20_bark_pine_b", "wood", {"Холод": 1}, [1, 1], 10],
	"wood_tree_blossom": ["Сакуровая чурка", 1.2, 3, "m20_wood_tree_blossom", "wood", {}, [2, 1], 5],
	"plank_tree_blossom": ["Сакуровая доска", 0.8, 5, "m20_plank_tree_blossom", "wood", {}, [2, 1], 10],
	"bark_tree_blossom": ["Сакуровая кора", 0.1, 2, "m20_bark_tree_blossom", "wood", {"Чары": 1}, [1, 1], 10],
	"wood_tree_autumn": ["Кленовая чурка", 1.2, 3, "m20_wood_tree_autumn", "wood", {}, [2, 1], 5],
	"plank_tree_autumn": ["Кленовая доска", 0.8, 5, "m20_plank_tree_autumn", "wood", {}, [2, 1], 10],
	"bark_tree_autumn": ["Кленовая кора", 0.1, 2, "m20_bark_tree_autumn", "wood", {"Огонь": 1}, [1, 1], 10],
	"wood_tree_autumn2": ["Рябиновая чурка", 1.2, 3, "m20_wood_tree_autumn2", "wood", {}, [2, 1], 5],
	"plank_tree_autumn2": ["Рябиновая доска", 0.8, 5, "m20_plank_tree_autumn2", "wood", {}, [2, 1], 10],
	"bark_tree_autumn2": ["Рябиновая кора", 0.1, 2, "m20_bark_tree_autumn2", "wood", {"Жгучесть": 1}, [1, 1], 10],
	"wood_tree_apple": ["Яблоневая чурка", 1.2, 3, "m20_wood_tree_apple", "wood", {}, [2, 1], 5],
	"plank_tree_apple": ["Яблоневая доска", 0.8, 5, "m20_plank_tree_apple", "wood", {}, [2, 1], 10],
	"bark_tree_apple": ["Яблоневая кора", 0.1, 2, "m20_bark_tree_apple", "wood", {"Свежесть": 1}, [1, 1], 10],
	"wood_tree_birch": ["Берёзовая чурка", 1.2, 3, "m20_wood_tree_birch", "wood", {}, [2, 1], 5],
	"plank_tree_birch": ["Берёзовая доска", 0.8, 5, "m20_plank_tree_birch", "wood", {}, [2, 1], 10],
	"bark_tree_birch": ["Берёзовая кора", 0.1, 2, "m20_bark_tree_birch", "wood", {"Свежесть": 1, "Исцеление": 1}, [1, 1], 10],
	"wood_tree_unicorn": ["Розовая чурка", 1.2, 3, "m20_wood_tree_unicorn", "wood", {}, [2, 1], 5],
	"plank_tree_unicorn": ["Розовая доска", 0.8, 5, "m20_plank_tree_unicorn", "wood", {}, [2, 1], 10],
	"bark_tree_unicorn": ["Розовая кора", 0.1, 2, "m20_bark_tree_unicorn", "wood", {"Свет": 1, "Чары": 1}, [1, 1], 10],
	"wood_dead": ["Сухая чурка", 1.2, 3, "m20_wood_dead", "wood", {}, [2, 1], 5],
	"plank_dead": ["Сухая доска", 0.8, 5, "m20_plank_dead", "wood", {}, [2, 1], 10],
	"bark_dead": ["Сухая кора", 0.1, 2, "m20_bark_dead", "wood", {"Тьма": 1}, [1, 1], 10],
	"stick": ["Палка", 0.2, 1, "m20_stick", "wood", {}, [1, 2], 10],
	"twig": ["Хворост", 0.1, 1, "m20_twig", "wood", {}, [1, 1], 10],
	"sawdust": ["Опилки", 0.1, 1, "m20_sawdust", "wood", {}, [1, 1], 20],
	"charcoal": ["Древесный уголь", 0.3, 3, "m20_charcoal", "wood", {"Огонь": 1, "Тьма": 1}, [1, 1], 20],
	"wood_ash": ["Зола", 0.1, 1, "m20_wood_ash", "wood", {"Сила": 1}, [1, 1], 20],
	"resin": ["Смола", 0.1, 4, "m20_resin", "wood", {"Тепло": 1, "Исцеление": 1}, [1, 1], 10],
	"tar": ["Дёготь", 0.6, 6, "m20_tar", "wood", {}, [1, 1], 5],
	"beam": ["Брус", 2.5, 12, "m20_beam", "wood", {}, [3, 1], 5],
	"shingle": ["Дранка", 0.2, 3, "m20_shingle", "wood", {}, [1, 1], 20],
	"stave": ["Клёпка для бочки", 0.4, 3, "m20_stave", "wood", {}, [1, 2], 10],
	"wood_glue": ["Столярный клей", 0.4, 6, "m20_wood_glue", "wood", {}, [1, 1], 5],
	"wood_gear": ["Деревянная шестерня", 0.5, 8, "m20_wood_gear", "wood", {}, [1, 1], 5],
	"driftwood": ["Плавник", 0.8, 3, "m20_driftwood", "wood", {"Холод": 1, "Свежесть": 1}, [2, 1], 5],
	"wicker": ["Ивовые прутья", 0.2, 2, "m20_wicker", "wood", {}, [1, 1], 20],
	"clay": ["Глина", 0.5, 2, "m20_clay", "earth", {"Исцеление": 1}, [1, 1], 20],
	"red_clay": ["Красная глина", 0.5, 2, "m20_red_clay", "earth", {"Тепло": 1}, [1, 1], 20],
	"white_clay": ["Белая глина (каолин)", 0.5, 2, "m20_white_clay", "earth", {"Свет": 1}, [1, 1], 20],
	"sand": ["Песок", 0.5, 2, "m20_sand", "earth", {}, [1, 1], 20],
	"black_sand": ["Чёрный песок", 0.5, 2, "m20_black_sand", "earth", {"Тьма": 1}, [1, 1], 20],
	"quartz_sand": ["Кварцевый песок", 0.5, 2, "m20_quartz_sand", "earth", {"Свет": 1}, [1, 1], 20],
	"gravel": ["Гравий", 0.5, 2, "m20_gravel", "earth", {}, [1, 1], 20],
	"peat": ["Торф", 0.5, 2, "m20_peat", "earth", {"Огонь": 1, "Тьма": 1}, [1, 1], 20],
	"loam": ["Чернозём", 0.5, 2, "m20_loam", "earth", {"Сила": 1}, [1, 1], 20],
	"salt": ["Соль", 0.5, 4, "m20_salt", "earth", {"Свежесть": 1, "Холод": 1}, [1, 1], 20],
	"sulfur": ["Сера", 0.5, 4, "m20_sulfur", "earth", {"Огонь": 1, "Жгучесть": 1}, [1, 1], 20],
	"saltpeter": ["Селитра", 0.5, 4, "m20_saltpeter", "earth", {"Огонь": 1}, [1, 1], 20],
	"coal": ["Каменный уголь", 0.5, 2, "m20_coal", "earth", {"Огонь": 1}, [1, 1], 20],
	"flint": ["Кремень", 1.2, 3, "m20_flint", "stone", {"Сила": 1}, [1, 1], 10],
	"slate": ["Сланец", 1.2, 3, "m20_slate", "stone", {"Сила": 1}, [1, 1], 10],
	"marble": ["Мрамор", 1.2, 7, "m20_marble", "stone", {"Сила": 1}, [1, 1], 10],
	"granite": ["Гранит", 1.2, 3, "m20_granite", "stone", {"Сила": 1}, [1, 1], 10],
	"basalt": ["Базальт", 1.2, 3, "m20_basalt", "stone", {"Сила": 1}, [1, 1], 10],
	"limestone": ["Известняк", 1.2, 3, "m20_limestone", "stone", {"Сила": 1}, [1, 1], 10],
	"chalk": ["Мел", 1.2, 3, "m20_chalk", "stone", {"Сила": 1}, [1, 1], 10],
	"sandstone": ["Песчаник", 1.2, 3, "m20_sandstone", "stone", {"Сила": 1}, [1, 1], 10],
	"obsidian": ["Обсидиан", 1.2, 7, "m20_obsidian", "stone", {"Тьма": 1, "Сила": 1}, [1, 1], 10],
	"pumice": ["Пемза", 1.2, 3, "m20_pumice", "stone", {"Сила": 1}, [1, 1], 10],
	"brick": ["Кирпич", 1.2, 4, "m20_brick", "stone", {}, [1, 1], 10],
	"red_brick": ["Тёмно-красный кирпич", 1.2, 5, "m20_red_brick", "stone", {}, [1, 1], 10],
	"roof_tile": ["Черепица", 0.4, 3, "m20_roof_tile", "stone", {}, [1, 1], 20],
	"porcelain": ["Фарфор", 0.4, 8, "m20_porcelain", "stone", {}, [1, 1], 10],
	"pot_clay": ["Глиняный горшок", 1.0, 6, "m20_pot_clay", "stone", {}, [1, 1], 3],
	"lime": ["Известь", 1.0, 4, "m20_lime", "stone", {}, [1, 1], 10],
	"mortar": ["Строительный раствор", 1.5, 5, "m20_mortar", "stone", {}, [1, 1], 10],
	"stone_block": ["Тёсаный камень", 2.0, 5, "m20_stone_block", "stone", {}, [1, 1], 10],
	"marble_block": ["Мраморный блок", 2.0, 14, "m20_marble_block", "stone", {}, [1, 1], 10],
	"granite_block": ["Гранитный блок", 2.0, 8, "m20_granite_block", "stone", {}, [1, 1], 10],
	"sandstone_block": ["Блок песчаника", 2.0, 6, "m20_sandstone_block", "stone", {}, [1, 1], 10],
	"basalt_block": ["Базальтовый блок", 2.0, 7, "m20_basalt_block", "stone", {}, [1, 1], 10],
	"slate_tile": ["Сланцевая плитка", 0.5, 4, "m20_slate_tile", "stone", {}, [1, 1], 20],
	"cobble": ["Булыжник", 1.0, 2, "m20_cobble", "stone", {}, [1, 1], 20],
	"glass": ["Стекло", 0.6, 6, "m20_glass", "glass", {}, [1, 1], 10],
	"glass_clear": ["Прозрачное стекло", 0.6, 9, "m20_glass_clear", "glass", {"Свет": 1}, [1, 1], 10],
	"glass_smoky": ["Дымчатое стекло", 0.6, 9, "m20_glass_smoky", "glass", {"Тьма": 1}, [1, 1], 10],
	"bottle_glass": ["Стеклянный флакон", 0.3, 5, "m20_bottle_glass", "glass", {}, [1, 1], 5],
	"ore_copper": ["Медная руда", 1.0, 3, "m20_ore_copper", "metal", {"Сила": 1}, [1, 1], 5],
	"nugget_copper": ["Медный самородок", 0.1, 2, "m20_nugget_copper", "metal", {}, [1, 1], 20],
	"bar_copper": ["Медный слиток", 1.5, 10, "m20_bar_copper", "metal", {}, [1, 1], 5],
	"ore_tin": ["Оловянная руда", 1.0, 3, "m20_ore_tin", "metal", {"Сила": 1}, [1, 1], 5],
	"nugget_tin": ["Оловянный самородок", 0.1, 2, "m20_nugget_tin", "metal", {}, [1, 1], 20],
	"bar_tin": ["Оловянный слиток", 1.5, 9, "m20_bar_tin", "metal", {}, [1, 1], 5],
	"ore_iron": ["Железная руда", 1.0, 4, "m20_ore_iron", "metal", {"Сила": 1}, [1, 1], 5],
	"nugget_iron": ["Железный самородок", 0.1, 2, "m20_nugget_iron", "metal", {}, [1, 1], 20],
	"ore_silver": ["Серебряная руда", 1.0, 8, "m20_ore_silver", "metal", {"Сила": 1}, [1, 1], 5],
	"nugget_silver": ["Серебряный самородок", 0.1, 4, "m20_nugget_silver", "metal", {}, [1, 1], 20],
	"bar_silver": ["Серебряный слиток", 1.5, 24, "m20_bar_silver", "metal", {}, [1, 1], 5],
	"ore_gold": ["Золотая руда", 1.0, 12, "m20_ore_gold", "metal", {"Сила": 1}, [1, 1], 5],
	"nugget_gold": ["Золотый самородок", 0.1, 7, "m20_nugget_gold", "metal", {}, [1, 1], 20],
	"bar_gold": ["Золотой слиток", 1.5, 36, "m20_bar_gold", "metal", {}, [1, 1], 5],
	"ore_zinc": ["Цинковая руда", 1.0, 3, "m20_ore_zinc", "metal", {"Сила": 1}, [1, 1], 5],
	"nugget_zinc": ["Цинковый самородок", 0.1, 2, "m20_nugget_zinc", "metal", {}, [1, 1], 20],
	"bar_zinc": ["Цинковый слиток", 1.5, 10, "m20_bar_zinc", "metal", {}, [1, 1], 5],
	"ore_lead": ["Свинцовая руда", 1.0, 3, "m20_ore_lead", "metal", {"Сила": 1}, [1, 1], 5],
	"nugget_lead": ["Свинцовый самородок", 0.1, 2, "m20_nugget_lead", "metal", {}, [1, 1], 20],
	"bar_lead": ["Свинцовый слиток", 1.5, 9, "m20_bar_lead", "metal", {}, [1, 1], 5],
	"ore_nickel": ["Никелевая руда", 1.0, 4, "m20_ore_nickel", "metal", {"Сила": 1}, [1, 1], 5],
	"nugget_nickel": ["Никелевый самородок", 0.1, 2, "m20_nugget_nickel", "metal", {}, [1, 1], 20],
	"bar_nickel": ["Никелевый слиток", 1.5, 14, "m20_bar_nickel", "metal", {}, [1, 1], 5],
	"ore_cobalt": ["Кобальтовая руда", 1.0, 9, "m20_ore_cobalt", "metal", {"Сила": 1}, [1, 1], 5],
	"nugget_cobalt": ["Кобальтовый самородок", 0.1, 5, "m20_nugget_cobalt", "metal", {}, [1, 1], 20],
	"bar_cobalt": ["Кобальтовый слиток", 1.5, 28, "m20_bar_cobalt", "metal", {}, [1, 1], 5],
	"ore_mithril": ["Мифриловая руда", 1.0, 20, "m20_ore_mithril", "metal", {"Сила": 1}, [1, 1], 5],
	"nugget_mithril": ["Мифриловый самородок", 0.1, 12, "m20_nugget_mithril", "metal", {}, [1, 1], 20],
	"bar_mithril": ["Мифриловый слиток", 1.5, 60, "m20_bar_mithril", "metal", {}, [1, 1], 5],
	"ore_adamant": ["Адамантовая руда", 1.0, 23, "m20_ore_adamant", "metal", {"Сила": 1}, [1, 1], 5],
	"nugget_adamant": ["Адамантовый самородок", 0.1, 14, "m20_nugget_adamant", "metal", {}, [1, 1], 20],
	"bar_adamant": ["Адамантовый слиток", 1.5, 70, "m20_bar_adamant", "metal", {}, [1, 1], 5],
	"ore_orichalcum": ["Орихалковая руда", 1.0, 22, "m20_ore_orichalcum", "metal", {"Сила": 1}, [1, 1], 5],
	"nugget_orichalcum": ["Орихалковый самородок", 0.1, 13, "m20_nugget_orichalcum", "metal", {}, [1, 1], 20],
	"bar_orichalcum": ["Орихалковый слиток", 1.5, 66, "m20_bar_orichalcum", "metal", {}, [1, 1], 5],
	"bar_bronze": ["Бронзовый слиток", 1.5, 16, "m20_bar_bronze", "metal", {}, [1, 1], 5],
	"bar_brass": ["Латунный слиток", 1.5, 15, "m20_bar_brass", "metal", {}, [1, 1], 5],
	"bar_steel": ["Стальной слиток", 1.5, 26, "m20_bar_steel", "metal", {}, [1, 1], 5],
	"bar_electrum": ["Электрум", 1.5, 34, "m20_bar_electrum", "metal", {}, [1, 1], 5],
	"bar_pewter": ["Пьютер", 1.5, 12, "m20_bar_pewter", "metal", {}, [1, 1], 5],
	"bar_rose_gold": ["Розовое золото", 1.5, 32, "m20_bar_rose_gold", "metal", {}, [1, 1], 5],
	"bar_starsteel": ["Звёздная сталь", 1.5, 120, "m20_bar_starsteel", "metal", {}, [1, 1], 5],
	"bar_mana": ["Мана-слиток", 1.2, 120, "m20_bar_mana", "metal", {"Чары": 2}, [1, 1], 5],
	"bar_frost": ["Ледяной слиток", 1.2, 120, "m20_bar_frost", "metal", {"Холод": 2}, [1, 1], 5],
	"bar_ember": ["Огненный слиток", 1.2, 120, "m20_bar_ember", "metal", {"Огонь": 2}, [1, 1], 5],
	"bar_verdant": ["Живой слиток", 1.2, 120, "m20_bar_verdant", "metal", {"Исцеление": 2}, [1, 1], 5],
	"bar_void": ["Слиток бездны", 1.2, 120, "m20_bar_void", "metal", {"Тьма": 2}, [1, 1], 5],
	"bar_moonsilver": ["Лунный слиток", 1.2, 120, "m20_bar_moonsilver", "metal", {"Свет": 1, "Сон": 1}, [1, 1], 5],
	"bar_sunstone": ["Солнечный слиток", 1.2, 120, "m20_bar_sunstone", "metal", {"Свет": 2}, [1, 1], 5],
	"nail": ["Гвозди", 0.05, 1, "m20_nail", "metal", {}, [1, 1], 50],
	"hinge": ["Дверная петля", 0.2, 4, "m20_hinge", "metal", {}, [1, 1], 10],
	"chain": ["Цепь", 0.8, 8, "m20_chain", "metal", {}, [1, 1], 5],
	"wire_copper": ["Медная проволока", 0.2, 5, "m20_wire_copper", "metal", {}, [1, 1], 10],
	"wire_silver": ["Серебряная проволока", 0.2, 12, "m20_wire_silver", "metal", {}, [1, 1], 10],
	"wire_gold": ["Золотая проволока", 0.2, 18, "m20_wire_gold", "metal", {}, [1, 1], 10],
	"sheet_copper": ["Медный лист", 0.8, 9, "m20_sheet_copper", "metal", {}, [1, 1], 5],
	"sheet_tin": ["Жесть", 0.8, 8, "m20_sheet_tin", "metal", {}, [1, 1], 5],
	"sheet_iron": ["Железный лист", 1.0, 13, "m20_sheet_iron", "metal", {}, [1, 1], 5],
	"gear_bronze": ["Бронзовая шестерня", 0.4, 10, "m20_gear_bronze", "metal", {}, [1, 1], 10],
	"spring": ["Пружина", 0.1, 9, "m20_spring", "metal", {}, [1, 1], 10],
	"needle": ["Игла", 0.02, 3, "m20_needle", "metal", {}, [1, 1], 20],
	"bell": ["Колокольчик", 0.4, 12, "m20_bell", "metal", {}, [1, 1], 5],
	"lantern_frame": ["Каркас фонаря", 0.8, 10, "m20_lantern_frame", "metal", {}, [1, 1], 5],
	"gem_raw_amethyst": ["Аметист (необработанный)", 0.3, 9, "m20_gem_raw_amethyst", "gem", {"Чары": 1, "Покой": 1}, [1, 1], 5],
	"gem_amethyst": ["Аметист", 0.1, 18, "m20_gem_amethyst", "gem", {"Чары": 1, "Покой": 1}, [1, 1], 5],
	"gem_raw_topaz": ["Топаз (необработанный)", 0.3, 9, "m20_gem_raw_topaz", "gem", {"Тепло": 1, "Свет": 1}, [1, 1], 5],
	"gem_topaz": ["Топаз", 0.1, 18, "m20_gem_topaz", "gem", {"Тепло": 1, "Свет": 1}, [1, 1], 5],
	"gem_raw_garnet": ["Гранат (необработанный)", 0.3, 9, "m20_gem_raw_garnet", "gem", {"Огонь": 1, "Сила": 1}, [1, 1], 5],
	"gem_garnet": ["Гранат", 0.1, 18, "m20_gem_garnet", "gem", {"Огонь": 1, "Сила": 1}, [1, 1], 5],
	"gem_raw_opal": ["Опал (необработанный)", 0.3, 9, "m20_gem_raw_opal", "gem", {"Чары": 2}, [1, 1], 5],
	"gem_opal": ["Опал", 0.1, 18, "m20_gem_opal", "gem", {"Чары": 2}, [1, 1], 5],
	"gem_raw_jade": ["Нефрит (необработанный)", 0.3, 9, "m20_gem_raw_jade", "gem", {"Исцеление": 1, "Покой": 1}, [1, 1], 5],
	"gem_jade": ["Нефрит", 0.1, 18, "m20_gem_jade", "gem", {"Исцеление": 1, "Покой": 1}, [1, 1], 5],
	"gem_raw_peridot": ["Перидот (необработанный)", 0.3, 9, "m20_gem_raw_peridot", "gem", {"Свежесть": 1, "Исцеление": 1}, [1, 1], 5],
	"gem_peridot": ["Перидот", 0.1, 18, "m20_gem_peridot", "gem", {"Свежесть": 1, "Исцеление": 1}, [1, 1], 5],
	"gem_raw_citrine": ["Цитрин (необработанный)", 0.3, 9, "m20_gem_raw_citrine", "gem", {"Свет": 1, "Тепло": 1}, [1, 1], 5],
	"gem_citrine": ["Цитрин", 0.1, 18, "m20_gem_citrine", "gem", {"Свет": 1, "Тепло": 1}, [1, 1], 5],
	"gem_raw_aquamarine": ["Аквамарин (необработанный)", 0.3, 9, "m20_gem_raw_aquamarine", "gem", {"Холод": 1, "Свежесть": 1}, [1, 1], 5],
	"gem_aquamarine": ["Аквамарин", 0.1, 18, "m20_gem_aquamarine", "gem", {"Холод": 1, "Свежесть": 1}, [1, 1], 5],
	"gem_raw_moonstone": ["Лунный камень (необработанный)", 0.3, 9, "m20_gem_raw_moonstone", "gem", {"Сон": 1, "Свет": 1}, [1, 1], 5],
	"gem_moonstone": ["Лунный камень", 0.1, 18, "m20_gem_moonstone", "gem", {"Сон": 1, "Свет": 1}, [1, 1], 5],
	"gem_raw_onyx": ["Оникс (необработанный)", 0.3, 9, "m20_gem_raw_onyx", "gem", {"Тьма": 1, "Сила": 1}, [1, 1], 5],
	"gem_onyx": ["Оникс", 0.1, 18, "m20_gem_onyx", "gem", {"Тьма": 1, "Сила": 1}, [1, 1], 5],
	"gem_raw_lapis": ["Лазурит (необработанный)", 0.3, 9, "m20_gem_raw_lapis", "gem", {"Чары": 1, "Холод": 1}, [1, 1], 5],
	"gem_lapis": ["Лазурит", 0.1, 18, "m20_gem_lapis", "gem", {"Чары": 1, "Холод": 1}, [1, 1], 5],
	"gem_raw_diamond": ["Алмаз (необработанный)", 0.3, 20, "m20_gem_raw_diamond", "gem", {"Свет": 2, "Сила": 1}, [1, 1], 5],
	"gem_diamond": ["Алмаз", 0.1, 40, "m20_gem_diamond", "gem", {"Свет": 2, "Сила": 1}, [1, 1], 5],
	"gem_raw_tourmaline": ["Турмалин (необработанный)", 0.3, 9, "m20_gem_raw_tourmaline", "gem", {"Чары": 1, "Жгучесть": 1}, [1, 1], 5],
	"gem_tourmaline": ["Турмалин", 0.1, 18, "m20_gem_tourmaline", "gem", {"Чары": 1, "Жгучесть": 1}, [1, 1], 5],
	"gem_raw_rose_quartz": ["Розовый кварц (необработанный)", 0.3, 9, "m20_gem_raw_rose_quartz", "gem", {"Покой": 1, "Исцеление": 1}, [1, 1], 5],
	"gem_rose_quartz": ["Розовый кварц", 0.1, 18, "m20_gem_rose_quartz", "gem", {"Покой": 1, "Исцеление": 1}, [1, 1], 5],
	"gem_raw_smoky_quartz": ["Дымчатый кварц (необработанный)", 0.3, 9, "m20_gem_raw_smoky_quartz", "gem", {"Тьма": 1, "Покой": 1}, [1, 1], 5],
	"gem_smoky_quartz": ["Дымчатый кварц", 0.1, 18, "m20_gem_smoky_quartz", "gem", {"Тьма": 1, "Покой": 1}, [1, 1], 5],
	"gem_raw_jet": ["Гагат (необработанный)", 0.3, 9, "m20_gem_raw_jet", "gem", {"Тьма": 2}, [1, 1], 5],
	"gem_jet": ["Гагат", 0.1, 18, "m20_gem_jet", "gem", {"Тьма": 2}, [1, 1], 5],
	"gem_raw_amber": ["Янтарь (необработанный)", 0.3, 9, "m20_gem_raw_amber", "gem", {"Тепло": 1, "Исцеление": 1}, [1, 1], 5],
	"gem_amber": ["Янтарь", 0.1, 18, "m20_gem_amber", "gem", {"Тепло": 1, "Исцеление": 1}, [1, 1], 5],
	"gem_raw_malachite": ["Малахит (необработанный)", 0.3, 9, "m20_gem_raw_malachite", "gem", {"Исцеление": 1, "Сила": 1}, [1, 1], 5],
	"gem_malachite": ["Малахит", 0.1, 18, "m20_gem_malachite", "gem", {"Исцеление": 1, "Сила": 1}, [1, 1], 5],
	"plant_fiber": ["Растительное волокно", 0.05, 1, "m20_plant_fiber", "fiber", {}, [1, 1], 30],
	"flax": ["Лён", 0.1, 2, "m20_flax", "fiber", {}, [1, 1], 20],
	"hemp": ["Конопля (волокно)", 0.1, 2, "m20_hemp", "fiber", {}, [1, 1], 20],
	"cotton": ["Хлопок", 0.05, 3, "m20_cotton", "fiber", {}, [1, 1], 20],
	"nettle_fiber": ["Крапивное волокно", 0.05, 2, "m20_nettle_fiber", "fiber", {"Жгучесть": 1}, [1, 1], 20],
	"reed": ["Тростник", 0.1, 1, "m20_reed", "fiber", {}, [1, 1], 20],
	"straw": ["Солома", 0.05, 1, "m20_straw", "fiber", {}, [1, 1], 30],
	"silk_cocoon": ["Шёлковый кокон", 0.05, 6, "m20_silk_cocoon", "fiber", {"Покой": 1, "Сон": 1}, [1, 1], 10],
	"spider_silk": ["Паучий шёлк", 0.02, 5, "m20_spider_silk", "fiber", {"Тьма": 1, "Сила": 1}, [1, 1], 20],
	"thread_linen": ["Льняная нить", 0.1, 4, "m20_thread_linen", "cloth", {}, [1, 1], 10],
	"thread_hemp": ["Пеньковая нить", 0.1, 4, "m20_thread_hemp", "cloth", {}, [1, 1], 10],
	"thread_cotton": ["Хлопковая нить", 0.1, 4, "m20_thread_cotton", "cloth", {}, [1, 1], 10],
	"thread_silk": ["Шёлковая нить", 0.1, 10, "m20_thread_silk", "cloth", {}, [1, 1], 10],
	"thread_spider": ["Нить паучьего шёлка", 0.1, 10, "m20_thread_spider", "cloth", {}, [1, 1], 10],
	"thread_nettle": ["Крапивная нить", 0.1, 4, "m20_thread_nettle", "cloth", {}, [1, 1], 10],
	"linen": ["Льняное полотно", 0.6, 12, "m20_linen", "cloth", {}, [2, 1], 5],
	"canvas": ["Парусина", 0.6, 12, "m20_canvas", "cloth", {}, [2, 1], 5],
	"cotton_cloth": ["Хлопковая ткань", 0.6, 12, "m20_cotton_cloth", "cloth", {}, [2, 1], 5],
	"silk_cloth": ["Шёлк", 0.6, 30, "m20_silk_cloth", "cloth", {}, [2, 1], 5],
	"spider_cloth": ["Паутинная ткань", 0.6, 30, "m20_spider_cloth", "cloth", {}, [2, 1], 5],
	"nettle_cloth": ["Крапивное полотно", 0.6, 12, "m20_nettle_cloth", "cloth", {}, [2, 1], 5],
	"wool_cloth": ["Шерстяная ткань", 0.6, 12, "m20_wool_cloth", "cloth", {}, [2, 1], 5],
	"felt": ["Войлок", 0.6, 12, "m20_felt", "cloth", {}, [2, 1], 5],
	"twine": ["Бечёвка", 0.1, 2, "m20_twine", "cloth", {}, [1, 1], 10],
	"rope": ["Верёвка", 0.5, 5, "m20_rope", "cloth", {}, [1, 1], 5],
	"net_mesh": ["Сеть", 0.6, 9, "m20_net_mesh", "cloth", {}, [1, 1], 5],
	"straw_mat": ["Соломенный мат", 0.6, 4, "m20_straw_mat", "cloth", {}, [2, 1], 5],
	"basket": ["Плетёная корзинка", 0.5, 6, "m20_basket", "cloth", {}, [1, 1], 3],
	"rabbit_fluff": ["Кроличий пух", 0.05, 3, "m20_rabbit_fluff", "animal", {"Покой": 1, "Сон": 1}, [1, 1], 20],
	"fox_tuft": ["Лисья шерсть", 0.05, 6, "m20_fox_tuft", "animal", {"Огонь": 1, "Чары": 1}, [1, 1], 20],
	"deer_fur": ["Оленья шерсть", 0.05, 5, "m20_deer_fur", "animal", {"Сила": 1, "Исцеление": 1}, [1, 1], 20],
	"antler_shed": ["Сброшенный рог оленя", 0.05, 14, "m20_antler_shed", "animal", {"Сила": 2}, [1, 1], 20],
	"boar_bristle": ["Кабанья щетина", 0.05, 4, "m20_boar_bristle", "animal", {"Сила": 1, "Жгучесть": 1}, [1, 1], 20],
	"hedgehog_quill": ["Иголки ежа", 0.05, 5, "m20_hedgehog_quill", "animal", {"Жгучесть": 2}, [1, 1], 20],
	"squirrel_fluff": ["Беличий пух", 0.05, 5, "m20_squirrel_fluff", "animal", {"Свежесть": 1, "Тепло": 1}, [1, 1], 20],
	"duck_down": ["Утиный пух", 0.05, 4, "m20_duck_down", "animal", {"Покой": 1, "Тепло": 1}, [1, 1], 20],
	"sapphire_fluff": ["Сапфировый пух", 0.05, 30, "m20_sapphire_fluff", "animal", {"Холод": 1, "Чары": 2}, [1, 1], 20],
	"unicorn_hair": ["Волос из гривы единорога", 0.05, 40, "m20_unicorn_hair", "animal", {"Свет": 2, "Исцеление": 1}, [1, 1], 20],
	"horn_shaving": ["Стружка рога единорога", 0.05, 60, "m20_horn_shaving", "animal", {"Свет": 2, "Чары": 2}, [1, 1], 20],
	"golden_fur": ["Золотая шерсть", 0.05, 30, "m20_golden_fur", "animal", {"Свет": 1, "Тепло": 1}, [1, 1], 20],
	"golden_antler": ["Золотой рог (сброшенный)", 0.05, 70, "m20_golden_antler", "animal", {"Свет": 2, "Сила": 1}, [1, 1], 20],
	"ember_tuft": ["Угольная шерсть", 0.05, 30, "m20_ember_tuft", "animal", {"Огонь": 2}, [1, 1], 20],
	"cat_whisker": ["Кошачий ус", 0.05, 8, "m20_cat_whisker", "animal", {"Чары": 1, "Свет": 1}, [1, 1], 20],
	"cat_fur": ["Кошачья шерсть", 0.05, 3, "m20_cat_fur", "animal", {"Покой": 2}, [1, 1], 20],
	"fish_scale": ["Рыбья чешуя", 0.05, 2, "m20_fish_scale", "animal", {"Холод": 1, "Свежесть": 1}, [1, 1], 20],
	"goose_down": ["Гусиный пух", 0.05, 5, "m20_goose_down", "animal", {"Покой": 1, "Сон": 1}, [1, 1], 20],
	"bat_fluff": ["Мех летучей мыши", 0.05, 6, "m20_bat_fluff", "animal", {"Тьма": 1, "Сон": 1}, [1, 1], 20],
	"yarn_rabbit": ["Пуховая пряжа", 0.2, 8, "m20_yarn_rabbit", "cloth", {}, [1, 1], 10],
	"yarn_fox": ["Рыжая пряжа", 0.2, 8, "m20_yarn_fox", "cloth", {}, [1, 1], 10],
	"yarn_deer": ["Оленья пряжа", 0.2, 8, "m20_yarn_deer", "cloth", {}, [1, 1], 10],
	"yarn_cat": ["Кошачья пряжа", 0.2, 8, "m20_yarn_cat", "cloth", {}, [1, 1], 10],
	"yarn_sapphire": ["Сапфировая пряжа", 0.2, 45, "m20_yarn_sapphire", "cloth", {}, [1, 1], 10],
	"yarn_unicorn": ["Единорожья пряжа", 0.2, 45, "m20_yarn_unicorn", "cloth", {}, [1, 1], 10],
	"yarn_golden": ["Золотая пряжа", 0.2, 45, "m20_yarn_golden", "cloth", {}, [1, 1], 10],
	"yarn_ember": ["Тлеющая пряжа", 0.2, 45, "m20_yarn_ember", "cloth", {}, [1, 1], 10],
	"yarn_down": ["Пряжа из пуха", 0.2, 8, "m20_yarn_down", "cloth", {}, [1, 1], 10],
	"honeycomb": ["Соты", 0.3, 6, "m20_honeycomb", "animal", {"Тепло": 1, "Исцеление": 1}, [1, 1], 10],
	"royal_jelly": ["Маточное молочко", 0.2, 30, "m20_royal_jelly", "animal", {"Исцеление": 2, "Сила": 1}, [1, 1], 5],
	"propolis": ["Прополис", 0.1, 10, "m20_propolis", "animal", {"Исцеление": 1, "Жгучесть": 1}, [1, 1], 10],
	"shell": ["Ракушка", 0.1, 2, "m20_shell", "sea", {"Холод": 1}, [1, 1], 20],
	"conch": ["Рапана", 0.4, 9, "m20_conch", "sea", {"Холод": 1, "Покой": 1}, [1, 1], 5],
	"sea_glass": ["Морское стёклышко", 0.05, 6, "m20_sea_glass", "sea", {"Свежесть": 1}, [1, 1], 20],
	"coral_piece": ["Веточка коралла", 0.2, 8, "m20_coral_piece", "sea", {"Исцеление": 1, "Холод": 1}, [1, 1], 10],
	"pearl": ["Жемчужина", 0.02, 25, "m20_pearl", "sea", {"Свет": 1, "Покой": 1}, [1, 1], 10],
	"starfish": ["Морская звезда (сухая)", 0.1, 7, "m20_starfish", "sea", {"Исцеление": 1}, [1, 1], 10],
	"sea_salt": ["Морская соль", 0.3, 4, "m20_sea_salt", "sea", {"Холод": 1, "Свежесть": 1}, [1, 1], 20],
	"kelp_dried": ["Сушёная ламинария", 0.1, 3, "m20_kelp_dried", "sea", {"Свежесть": 1, "Исцеление": 1}, [1, 1], 20],
	"dye_red": ["Красная краска", 0.3, 6, "m20_dye_red", "dye", {}, [1, 1], 10],
	"cloth_red": ["Красная ткань", 0.6, 16, "m20_cloth_red", "dye", {}, [2, 1], 5],
	"dye_orange": ["Оранжевая краска", 0.3, 6, "m20_dye_orange", "dye", {}, [1, 1], 10],
	"cloth_orange": ["Оранжевая ткань", 0.6, 16, "m20_cloth_orange", "dye", {}, [2, 1], 5],
	"dye_yellow": ["Жёлтая краска", 0.3, 6, "m20_dye_yellow", "dye", {}, [1, 1], 10],
	"cloth_yellow": ["Жёлтая ткань", 0.6, 16, "m20_cloth_yellow", "dye", {}, [2, 1], 5],
	"dye_green": ["Зелёная краска", 0.3, 6, "m20_dye_green", "dye", {}, [1, 1], 10],
	"cloth_green": ["Зелёная ткань", 0.6, 16, "m20_cloth_green", "dye", {}, [2, 1], 5],
	"dye_cyan": ["Бирюзовая краска", 0.3, 6, "m20_dye_cyan", "dye", {}, [1, 1], 10],
	"cloth_cyan": ["Бирюзовая ткань", 0.6, 16, "m20_cloth_cyan", "dye", {}, [2, 1], 5],
	"dye_blue": ["Синяя краска", 0.3, 6, "m20_dye_blue", "dye", {}, [1, 1], 10],
	"cloth_blue": ["Синяя ткань", 0.6, 16, "m20_cloth_blue", "dye", {}, [2, 1], 5],
	"dye_purple": ["Фиолетовая краска", 0.3, 6, "m20_dye_purple", "dye", {}, [1, 1], 10],
	"cloth_purple": ["Фиолетовая ткань", 0.6, 16, "m20_cloth_purple", "dye", {}, [2, 1], 5],
	"dye_pink": ["Розовая краска", 0.3, 6, "m20_dye_pink", "dye", {}, [1, 1], 10],
	"cloth_pink": ["Розовая ткань", 0.6, 16, "m20_cloth_pink", "dye", {}, [2, 1], 5],
	"dye_brown": ["Коричневая краска", 0.3, 6, "m20_dye_brown", "dye", {}, [1, 1], 10],
	"cloth_brown": ["Коричневая ткань", 0.6, 16, "m20_cloth_brown", "dye", {}, [2, 1], 5],
	"dye_black": ["Чёрная краска", 0.3, 6, "m20_dye_black", "dye", {}, [1, 1], 10],
	"cloth_black": ["Чёрная ткань", 0.6, 16, "m20_cloth_black", "dye", {}, [2, 1], 5],
	"dye_white": ["Белая краска", 0.3, 6, "m20_dye_white", "dye", {}, [1, 1], 10],
	"cloth_white": ["Белая ткань", 0.6, 16, "m20_cloth_white", "dye", {}, [2, 1], 5],
	"dye_gold": ["Золотая краска", 0.3, 30, "m20_dye_gold", "dye", {}, [1, 1], 10],
	"cloth_gold": ["Золотая ткань", 0.6, 50, "m20_cloth_gold", "dye", {}, [2, 1], 5],
	"glass_red": ["Красное стекло", 0.6, 12, "m20_glass_red", "glass", {}, [1, 1], 10],
	"glass_yellow": ["Жёлтое стекло", 0.6, 12, "m20_glass_yellow", "glass", {}, [1, 1], 10],
	"glass_green": ["Зелёное стекло", 0.6, 12, "m20_glass_green", "glass", {}, [1, 1], 10],
	"glass_blue": ["Синяя стекло", 0.6, 12, "m20_glass_blue", "glass", {}, [1, 1], 10],
	"glass_purple": ["Фиолетовое стекло", 0.6, 12, "m20_glass_purple", "glass", {}, [1, 1], 10],
	"glass_pink": ["Розовое стекло", 0.6, 12, "m20_glass_pink", "glass", {}, [1, 1], 10],
	"ink": ["Чернила", 0.3, 6, "m20_ink", "paper", {"Тьма": 1}, [1, 1], 5],
	"paper": ["Бумага", 0.05, 3, "m20_paper", "paper", {}, [1, 1], 30],
	"book_blank": ["Чистая книга", 0.8, 25, "m20_book_blank", "paper", {}, [1, 1], 3],
	"candle": ["Свеча", 0.2, 4, "m20_candle", "paper", {"Свет": 1}, [1, 1], 10],
	"candle_scented": ["Душистая свеча", 0.2, 10, "m20_candle_scented", "paper", {"Свет": 1, "Покой": 1}, [1, 1], 10],
	"soap": ["Мыло", 0.2, 5, "m20_soap", "paper", {"Свежесть": 1}, [1, 1], 10],
	"plant_oil": ["Растительное масло", 0.5, 5, "m20_plant_oil", "paper", {"Тепло": 1}, [1, 1], 5],
	"lamp_oil": ["Лампадное масло", 0.5, 7, "m20_lamp_oil", "paper", {"Огонь": 1}, [1, 1], 5],
	"varnish": ["Лак", 0.5, 9, "m20_varnish", "paper", {}, [1, 1], 5],
	"glue": ["Клей", 0.4, 5, "m20_glue", "paper", {}, [1, 1], 5],
	"flour": ["Мука", 1.0, 3, "m20_flour", "paper", {}, [1, 1], 10],
	"grain": ["Зерно", 0.1, 1, "m20_grain", "paper", {}, [1, 1], 30],
	"seed_mix": ["Семена для птиц", 0.1, 2, "m20_seed_mix", "paper", {}, [1, 1], 30],
	"mana_dust": ["Мана-пыль", 0.02, 20, "m20_mana_dust", "magic", {"Чары": 2}, [1, 1], 20],
	"star_dust": ["Звёздная пыль", 0.02, 40, "m20_star_dust", "magic", {"Свет": 2, "Чары": 1}, [1, 1], 20],
	"moon_essence": ["Лунная эссенция", 0.2, 45, "m20_moon_essence", "magic", {"Сон": 2, "Свет": 1}, [1, 1], 5],
	"fairy_dust": ["Пыльца фей", 0.02, 35, "m20_fairy_dust", "magic", {"Чары": 2, "Свежесть": 1}, [1, 1], 20],
	"void_dust": ["Пыль бездны", 0.02, 40, "m20_void_dust", "magic", {"Тьма": 2, "Чары": 1}, [1, 1], 20],
	"ember_dust": ["Тлеющая пыль", 0.02, 30, "m20_ember_dust", "magic", {"Огонь": 2}, [1, 1], 20],
	"frost_dust": ["Иней в склянке", 0.02, 30, "m20_frost_dust", "magic", {"Холод": 2}, [1, 1], 20],
	"rune_blank": ["Чистая руна", 0.6, 15, "m20_rune_blank", "magic", {}, [1, 1], 5],
	"rune_lit": ["Светящаяся руна", 0.6, 60, "m20_rune_lit", "magic", {"Чары": 2, "Свет": 1}, [1, 1], 5],
	"crystal_shard": ["Осколок кристалла", 0.1, 12, "m20_crystal_shard", "magic", {"Чары": 1}, [1, 1], 20],
	"feather_sparrow": ["Перо: воробей", 0.01, 2, "icon_feather_sparrow", "feather", {"Сила": 1}, [1, 1], 20],
	"feather_great_tit": ["Перо: большая синица", 0.01, 3, "icon_feather_great_tit", "feather", {"Свежесть": 1, "Сила": 1}, [1, 1], 20],
	"feather_blue_tit": ["Перо: лазоревка", 0.01, 3, "icon_feather_blue_tit", "feather", {"Холод": 1, "Свежесть": 1}, [1, 1], 20],
	"feather_robin": ["Перо: зарянка", 0.01, 3, "icon_feather_robin", "feather", {"Тепло": 1, "Исцеление": 1}, [1, 1], 20],
	"feather_chaffinch": ["Перо: зяблик", 0.01, 3, "icon_feather_chaffinch", "feather", {"Свежесть": 1, "Тепло": 1}, [1, 1], 20],
	"feather_goldfinch": ["Перо: щегол", 0.01, 6, "icon_feather_goldfinch", "feather", {"Свет": 1, "Чары": 1}, [1, 1], 20],
	"feather_bullfinch": ["Перо: снегирь", 0.01, 5, "icon_feather_bullfinch", "feather", {"Холод": 1, "Тепло": 1}, [1, 1], 20],
	"feather_wren": ["Перо: крапивник", 0.01, 4, "icon_feather_wren", "feather", {"Сила": 2}, [1, 1], 20],
	"feather_nightingale": ["Перо: соловей", 0.01, 8, "icon_feather_nightingale", "feather", {"Покой": 1, "Сон": 1}, [1, 1], 20],
	"feather_lark": ["Перо: жаворонок", 0.01, 4, "icon_feather_lark", "feather", {"Свет": 1, "Свежесть": 1}, [1, 1], 20],
	"feather_swallow": ["Перо: ласточка", 0.01, 4, "icon_feather_swallow", "feather", {"Свежесть": 1, "Свет": 1}, [1, 1], 20],
	"feather_starling": ["Перо: скворец", 0.01, 3, "icon_feather_starling", "feather", {"Чары": 1, "Тьма": 1}, [1, 1], 20],
	"feather_thrush": ["Перо: певчий дрозд", 0.01, 4, "icon_feather_thrush", "feather", {"Исцеление": 1, "Покой": 1}, [1, 1], 20],
	"feather_blackbird": ["Перо: чёрный дрозд", 0.01, 4, "icon_feather_blackbird", "feather", {"Тьма": 1, "Покой": 1}, [1, 1], 20],
	"feather_wagtail": ["Перо: трясогузка", 0.01, 3, "icon_feather_wagtail", "feather", {"Свежесть": 2}, [1, 1], 20],
	"feather_oriole": ["Перо: иволга", 0.01, 10, "icon_feather_oriole", "feather", {"Свет": 2, "Тепло": 1}, [1, 1], 20],
	"feather_waxwing": ["Перо: свиристель", 0.01, 7, "icon_feather_waxwing", "feather", {"Холод": 1, "Чары": 1}, [1, 1], 20],
	"feather_kingfisher": ["Перо: зимородок", 0.01, 12, "icon_feather_kingfisher", "feather", {"Холод": 1, "Свет": 1, "Свежесть": 1}, [1, 1], 20],
	"feather_hoopoe": ["Перо: удод", 0.01, 9, "icon_feather_hoopoe", "feather", {"Огонь": 1, "Сила": 1}, [1, 1], 20],
	"feather_jay": ["Перо: сойка", 0.01, 6, "icon_feather_jay", "feather", {"Чары": 1, "Холод": 1}, [1, 1], 20],
	"feather_magpie": ["Перо: сорока", 0.01, 4, "icon_feather_magpie", "feather", {"Чары": 1, "Тьма": 1}, [1, 1], 20],
	"feather_crow": ["Перо: серая ворона", 0.01, 2, "icon_feather_crow", "feather", {"Тьма": 1, "Сила": 1}, [1, 1], 20],
	"feather_raven": ["Перо: ворон", 0.01, 8, "icon_feather_raven", "feather", {"Тьма": 2, "Чары": 1}, [1, 1], 20],
	"feather_cuckoo": ["Перо: кукушка", 0.01, 7, "icon_feather_cuckoo", "feather", {"Сон": 1, "Чары": 1}, [1, 1], 20],
	"feather_woodpecker": ["Перо: пёстрый дятел", 0.01, 5, "icon_feather_woodpecker", "feather", {"Сила": 2}, [1, 1], 20],
	"feather_dove": ["Перо: горлица", 0.01, 3, "icon_feather_dove", "feather", {"Покой": 2}, [1, 1], 20],
	"feather_pheasant": ["Перо: фазан", 0.01, 9, "icon_feather_pheasant", "feather", {"Огонь": 1, "Тепло": 1, "Сила": 1}, [1, 1], 20],
	"feather_quail": ["Перо: перепел", 0.01, 4, "icon_feather_quail", "feather", {"Сила": 1, "Тепло": 1}, [1, 1], 20],
	"feather_partridge": ["Перо: серая куропатка", 0.01, 5, "icon_feather_partridge", "feather", {"Тепло": 1, "Сила": 1}, [1, 1], 20],
	"feather_heron": ["Перо: серая цапля", 0.01, 8, "icon_feather_heron", "feather", {"Холод": 1, "Покой": 1, "Свежесть": 1}, [1, 1], 20],
	"feather_crane": ["Перо: японский журавль", 0.01, 18, "icon_feather_crane", "feather", {"Чары": 1, "Покой": 1, "Свет": 1}, [1, 1], 20],
	"feather_swan": ["Перо: лебедь-шипун", 0.01, 14, "icon_feather_swan", "feather", {"Свет": 1, "Покой": 1, "Исцеление": 1}, [1, 1], 20],
	"feather_goose": ["Перо: серый гусь", 0.01, 5, "icon_feather_goose", "feather", {"Сила": 1, "Тепло": 1}, [1, 1], 20],
	"feather_gull": ["Перо: чайка", 0.01, 3, "icon_feather_gull", "feather", {"Свежесть": 1, "Холод": 1}, [1, 1], 20],
	"feather_sandpiper": ["Перо: кулик-перевозчик", 0.01, 3, "icon_feather_sandpiper", "feather", {"Свежесть": 1}, [1, 1], 20],
	"feather_bee_eater": ["Перо: золотистая щурка", 0.01, 11, "icon_feather_bee_eater", "feather", {"Огонь": 1, "Свет": 1, "Жгучесть": 1}, [1, 1], 20],
	"feather_crossbill": ["Перо: клёст-еловик", 0.01, 6, "icon_feather_crossbill", "feather", {"Огонь": 1, "Холод": 1}, [1, 1], 20],
	"feather_nuthatch": ["Перо: поползень", 0.01, 4, "icon_feather_nuthatch", "feather", {"Сила": 1, "Свежесть": 1}, [1, 1], 20],
	"feather_white_eye": ["Перо: белоглазка мэдзиро", 0.01, 6, "icon_feather_white_eye", "feather", {"Свежесть": 1, "Чары": 1}, [1, 1], 20],
	"feather_rosefinch": ["Перо: розовый чечевичник", 0.01, 9, "icon_feather_rosefinch", "feather", {"Чары": 1, "Исцеление": 1}, [1, 1], 20],
	"feather_mandarin_duck": ["Перо: утка-мандаринка", 0.01, 12, "icon_feather_mandarin_duck", "feather", {"Чары": 1, "Тепло": 1, "Свет": 1}, [1, 1], 20],
	"feather_nightjar": ["Перо: козодой", 0.01, 9, "icon_feather_nightjar", "feather", {"Сон": 2, "Тьма": 1}, [1, 1], 20],
	"feather_tawny_owl": ["Перо: серая неясыть", 0.01, 6, "icon_feather_tawny_owl", "feather", {"Сон": 1, "Тьма": 1, "Покой": 1}, [1, 1], 20],
	"feather_eagle_owl": ["Перо: филин", 0.01, 12, "icon_feather_eagle_owl", "feather", {"Тьма": 2, "Сила": 1}, [1, 1], 20],
	"feather_barn_owl": ["Перо: сипуха", 0.01, 8, "icon_feather_barn_owl", "feather", {"Сон": 1, "Свет": 1, "Покой": 1}, [1, 1], 20],
	"feather_scops_owl": ["Перо: сплюшка", 0.01, 7, "icon_feather_scops_owl", "feather", {"Сон": 2}, [1, 1], 20],
	"feather_snowy_owl": ["Перо: белая сова", 0.01, 16, "icon_feather_snowy_owl", "feather", {"Холод": 2, "Свет": 1}, [1, 1], 20],
	"feather_firebird": ["Перо: жар-птица", 0.01, 60, "icon_feather_firebird", "feather", {"Огонь": 2, "Свет": 2, "Исцеление": 1}, [1, 1], 20],
	"feather_moon_finch": ["Перо: лунный вьюрок", 0.01, 30, "icon_feather_moon_finch", "feather", {"Чары": 2, "Свет": 1, "Холод": 1}, [1, 1], 20],
	"feather_fairy_wren": ["Перо: фейный крапивник", 0.01, 26, "icon_feather_fairy_wren", "feather", {"Чары": 2, "Свежесть": 1}, [1, 1], 20],
	"feather_shadow_crow": ["Перо: теневой ворон", 0.01, 34, "icon_feather_shadow_crow", "feather", {"Тьма": 3, "Чары": 1}, [1, 1], 20],
}
const ORDER: Array = ["wood_tree_a", "plank_tree_a", "bark_tree_a", "wood_tree_b", "plank_tree_b", "bark_tree_b", "wood_tree_c", "plank_tree_c", "bark_tree_c", "wood_tree_d", "plank_tree_d", "bark_tree_d", "wood_pine_a", "plank_pine_a", "bark_pine_a", "wood_pine_b", "plank_pine_b", "bark_pine_b", "wood_tree_blossom", "plank_tree_blossom", "bark_tree_blossom", "wood_tree_autumn", "plank_tree_autumn", "bark_tree_autumn", "wood_tree_autumn2", "plank_tree_autumn2", "bark_tree_autumn2", "wood_tree_apple", "plank_tree_apple", "bark_tree_apple", "wood_tree_birch", "plank_tree_birch", "bark_tree_birch", "wood_tree_unicorn", "plank_tree_unicorn", "bark_tree_unicorn", "wood_dead", "plank_dead", "bark_dead", "stick", "twig", "sawdust", "charcoal", "wood_ash", "resin", "tar", "beam", "shingle", "stave", "wood_glue", "wood_gear", "driftwood", "wicker", "clay", "red_clay", "white_clay", "sand", "black_sand", "quartz_sand", "gravel", "peat", "loam", "salt", "sulfur", "saltpeter", "coal", "flint", "slate", "marble", "granite", "basalt", "limestone", "chalk", "sandstone", "obsidian", "pumice", "brick", "red_brick", "roof_tile", "porcelain", "pot_clay", "lime", "mortar", "stone_block", "marble_block", "granite_block", "sandstone_block", "basalt_block", "slate_tile", "cobble", "glass", "glass_clear", "glass_smoky", "bottle_glass", "ore_copper", "nugget_copper", "bar_copper", "ore_tin", "nugget_tin", "bar_tin", "ore_iron", "nugget_iron", "ore_silver", "nugget_silver", "bar_silver", "ore_gold", "nugget_gold", "bar_gold", "ore_zinc", "nugget_zinc", "bar_zinc", "ore_lead", "nugget_lead", "bar_lead", "ore_nickel", "nugget_nickel", "bar_nickel", "ore_cobalt", "nugget_cobalt", "bar_cobalt", "ore_mithril", "nugget_mithril", "bar_mithril", "ore_adamant", "nugget_adamant", "bar_adamant", "ore_orichalcum", "nugget_orichalcum", "bar_orichalcum", "bar_bronze", "bar_brass", "bar_steel", "bar_electrum", "bar_pewter", "bar_rose_gold", "bar_starsteel", "bar_mana", "bar_frost", "bar_ember", "bar_verdant", "bar_void", "bar_moonsilver", "bar_sunstone", "nail", "hinge", "chain", "wire_copper", "wire_silver", "wire_gold", "sheet_copper", "sheet_tin", "sheet_iron", "gear_bronze", "spring", "needle", "bell", "lantern_frame", "gem_raw_amethyst", "gem_amethyst", "gem_raw_topaz", "gem_topaz", "gem_raw_garnet", "gem_garnet", "gem_raw_opal", "gem_opal", "gem_raw_jade", "gem_jade", "gem_raw_peridot", "gem_peridot", "gem_raw_citrine", "gem_citrine", "gem_raw_aquamarine", "gem_aquamarine", "gem_raw_moonstone", "gem_moonstone", "gem_raw_onyx", "gem_onyx", "gem_raw_lapis", "gem_lapis", "gem_raw_diamond", "gem_diamond", "gem_raw_tourmaline", "gem_tourmaline", "gem_raw_rose_quartz", "gem_rose_quartz", "gem_raw_smoky_quartz", "gem_smoky_quartz", "gem_raw_jet", "gem_jet", "gem_raw_amber", "gem_amber", "gem_raw_malachite", "gem_malachite", "plant_fiber", "flax", "hemp", "cotton", "nettle_fiber", "reed", "straw", "silk_cocoon", "spider_silk", "thread_linen", "thread_hemp", "thread_cotton", "thread_silk", "thread_spider", "thread_nettle", "linen", "canvas", "cotton_cloth", "silk_cloth", "spider_cloth", "nettle_cloth", "wool_cloth", "felt", "twine", "rope", "net_mesh", "straw_mat", "basket", "rabbit_fluff", "fox_tuft", "deer_fur", "antler_shed", "boar_bristle", "hedgehog_quill", "squirrel_fluff", "duck_down", "sapphire_fluff", "unicorn_hair", "horn_shaving", "golden_fur", "golden_antler", "ember_tuft", "cat_whisker", "cat_fur", "fish_scale", "goose_down", "bat_fluff", "yarn_rabbit", "yarn_fox", "yarn_deer", "yarn_cat", "yarn_sapphire", "yarn_unicorn", "yarn_golden", "yarn_ember", "yarn_down", "honeycomb", "royal_jelly", "propolis", "shell", "conch", "sea_glass", "coral_piece", "pearl", "starfish", "sea_salt", "kelp_dried", "dye_red", "cloth_red", "dye_orange", "cloth_orange", "dye_yellow", "cloth_yellow", "dye_green", "cloth_green", "dye_cyan", "cloth_cyan", "dye_blue", "cloth_blue", "dye_purple", "cloth_purple", "dye_pink", "cloth_pink", "dye_brown", "cloth_brown", "dye_black", "cloth_black", "dye_white", "cloth_white", "dye_gold", "cloth_gold", "glass_red", "glass_yellow", "glass_green", "glass_blue", "glass_purple", "glass_pink", "ink", "paper", "book_blank", "candle", "candle_scented", "soap", "plant_oil", "lamp_oil", "varnish", "glue", "flour", "grain", "seed_mix", "mana_dust", "star_dust", "moon_essence", "fairy_dust", "void_dust", "ember_dust", "frost_dust", "rune_blank", "rune_lit", "crystal_shard", "feather_sparrow", "feather_great_tit", "feather_blue_tit", "feather_robin", "feather_chaffinch", "feather_goldfinch", "feather_bullfinch", "feather_wren", "feather_nightingale", "feather_lark", "feather_swallow", "feather_starling", "feather_thrush", "feather_blackbird", "feather_wagtail", "feather_oriole", "feather_waxwing", "feather_kingfisher", "feather_hoopoe", "feather_jay", "feather_magpie", "feather_crow", "feather_raven", "feather_cuckoo", "feather_woodpecker", "feather_dove", "feather_pheasant", "feather_quail", "feather_partridge", "feather_heron", "feather_crane", "feather_swan", "feather_goose", "feather_gull", "feather_sandpiper", "feather_bee_eater", "feather_crossbill", "feather_nuthatch", "feather_white_eye", "feather_rosefinch", "feather_mandarin_duck", "feather_nightjar", "feather_tawny_owl", "feather_eagle_owl", "feather_barn_owl", "feather_scops_owl", "feather_snowy_owl", "feather_firebird", "feather_moon_finch", "feather_fairy_wren", "feather_shadow_crow"]
## Мастерские: вид -> [название, звук работы]; рецепты RECIPES[вид] = [[что, сколько, {что нужно: сколько}], ...]
## "@plank" — любая доска, "@wood" — любая чурка, "@yarn" — любая пряжа, "@fur" — любой пух/шерсть
const STATIONS: Dictionary = {"sawmill": ["Пилорама", "chop"], "kiln": ["Печь для обжига", "fire"], "smelter": ["Плавильня", "fire"], "anvil": ["Наковальня", "anvil"], "spinning": ["Прялка", "loom"], "loom": ["Ткацкий станок", "loom"], "dye_vat": ["Красильный чан", "bubble"], "mason": ["Каменотёсный стол", "pick"], "jeweler": ["Стол ювелира", "tinker"], "press": ["Пресс и котелок", "pour"]}
const RECIPES: Dictionary = {
	"sawmill": [["plank_tree_a", 2, {"wood_tree_a": 1}], ["plank_tree_b", 2, {"wood_tree_b": 1}], ["plank_tree_c", 2, {"wood_tree_c": 1}], ["plank_tree_d", 2, {"wood_tree_d": 1}], ["plank_pine_a", 2, {"wood_pine_a": 1}], ["plank_pine_b", 2, {"wood_pine_b": 1}], ["plank_tree_blossom", 2, {"wood_tree_blossom": 1}], ["plank_tree_autumn", 2, {"wood_tree_autumn": 1}], ["plank_tree_autumn2", 2, {"wood_tree_autumn2": 1}], ["plank_tree_apple", 2, {"wood_tree_apple": 1}], ["plank_tree_birch", 2, {"wood_tree_birch": 1}], ["plank_tree_unicorn", 2, {"wood_tree_unicorn": 1}], ["plank_dead", 2, {"wood_dead": 1}], ["stick", 4, {"log": 1}], ["plank_tree_a", 2, {"log": 1}], ["beam", 1, {"@plank": 3}], ["shingle", 4, {"@plank": 1}], ["stave", 3, {"@plank": 1}], ["wood_gear", 1, {"@plank": 1, "stick": 1}], ["sawdust", 4, {"@wood": 1}], ["twig", 3, {"stick": 1}], ["plank_dead", 2, {"driftwood": 1}]],
	"kiln": [["brick", 2, {"clay": 2}], ["red_brick", 2, {"red_clay": 2}], ["roof_tile", 3, {"clay": 2}], ["porcelain", 2, {"white_clay": 2}], ["pot_clay", 1, {"clay": 3}], ["glass", 1, {"sand": 2}], ["glass_clear", 1, {"quartz_sand": 2}], ["glass_smoky", 1, {"black_sand": 2}], ["bottle_glass", 2, {"glass": 1}], ["lime", 2, {"limestone": 1}], ["lime", 1, {"chalk": 1}], ["charcoal", 3, {"log": 1}], ["charcoal", 2, {"@wood": 1}], ["wood_ash", 2, {"twig": 2}], ["coal", 1, {"peat": 3}], ["sea_salt", 2, {"water_cold": 1, "salt": 1}]],
	"smelter": [["bar_copper", 1, {"ore_copper": 2, "charcoal": 1}], ["bar_tin", 1, {"ore_tin": 2, "charcoal": 1}], ["iron_bar", 1, {"ore_iron": 2, "charcoal": 1}], ["bar_silver", 1, {"ore_silver": 2, "charcoal": 1}], ["bar_gold", 1, {"ore_gold": 2, "charcoal": 1}], ["bar_zinc", 1, {"ore_zinc": 2, "charcoal": 1}], ["bar_lead", 1, {"ore_lead": 2, "charcoal": 1}], ["bar_nickel", 1, {"ore_nickel": 2, "charcoal": 1}], ["bar_cobalt", 1, {"ore_cobalt": 2, "charcoal": 1}], ["bar_mithril", 1, {"ore_mithril": 2, "charcoal": 1}], ["bar_adamant", 1, {"ore_adamant": 2, "charcoal": 1}], ["bar_orichalcum", 1, {"ore_orichalcum": 2, "charcoal": 1}], ["bar_copper", 1, {"nugget_copper": 5}], ["bar_tin", 1, {"nugget_tin": 5}], ["iron_bar", 1, {"nugget_iron": 5}], ["bar_silver", 1, {"nugget_silver": 5}], ["bar_gold", 1, {"nugget_gold": 5}], ["bar_zinc", 1, {"nugget_zinc": 5}], ["bar_lead", 1, {"nugget_lead": 5}], ["bar_nickel", 1, {"nugget_nickel": 5}], ["bar_cobalt", 1, {"nugget_cobalt": 5}], ["bar_mithril", 1, {"nugget_mithril": 5}], ["bar_adamant", 1, {"nugget_adamant": 5}], ["bar_orichalcum", 1, {"nugget_orichalcum": 5}], ["bar_bronze", 4, {"bar_copper": 3, "bar_tin": 1}], ["bar_brass", 3, {"bar_copper": 2, "bar_zinc": 1}], ["bar_steel", 2, {"iron_bar": 2, "coal": 1}], ["bar_electrum", 2, {"bar_silver": 1, "bar_gold": 1}], ["bar_pewter", 4, {"bar_tin": 3, "bar_lead": 1}], ["bar_rose_gold", 3, {"bar_gold": 2, "bar_copper": 1}], ["bar_starsteel", 2, {"bar_steel": 2, "ore_star": 1}], ["bar_mana", 1, {"ore_mana": 2, "coal": 1}], ["bar_frost", 1, {"ore_frost": 2, "coal": 1}], ["bar_ember", 1, {"ore_ember": 2, "coal": 1}], ["bar_verdant", 1, {"ore_verdant": 2, "coal": 1}], ["bar_void", 1, {"ore_void": 2, "coal": 1}], ["bar_moonsilver", 1, {"ore_moonsilver": 2, "coal": 1}], ["bar_sunstone", 1, {"ore_sunstone": 2, "coal": 1}], ["glass", 2, {"sand": 3, "coal": 1}]],
	"anvil": [["nail", 8, {"iron_bar": 1}], ["hinge", 2, {"iron_bar": 1}], ["chain", 1, {"iron_bar": 2}], ["wire_copper", 3, {"bar_copper": 1}], ["wire_silver", 2, {"bar_silver": 1}], ["wire_gold", 2, {"bar_gold": 1}], ["sheet_copper", 1, {"bar_copper": 1}], ["sheet_tin", 1, {"bar_tin": 1}], ["sheet_iron", 1, {"iron_bar": 1}], ["gear_bronze", 2, {"bar_bronze": 1}], ["spring", 2, {"bar_steel": 1}], ["needle", 6, {"bar_steel": 1}], ["bell", 1, {"bar_bronze": 2}], ["bell", 1, {"bar_brass": 2}], ["lantern_frame", 1, {"iron_bar": 1, "sheet_tin": 1}], ["iron_pot", 1, {"iron_bar": 2}], ["horseshoe", 2, {"iron_bar": 1}]],
	"spinning": [["twine", 1, {"plant_fiber": 3}], ["thread_linen", 2, {"flax": 2}], ["thread_hemp", 2, {"hemp": 2}], ["thread_cotton", 2, {"cotton": 2}], ["thread_silk", 2, {"silk_cocoon": 1}], ["thread_spider", 1, {"spider_silk": 3}], ["nettle_fiber", 2, {"nettle": 2}], ["thread_nettle", 1, {"nettle_fiber": 2}], ["yarn_rabbit", 1, {"rabbit_fluff": 3}], ["yarn_fox", 1, {"fox_tuft": 3}], ["yarn_deer", 1, {"deer_fur": 3}], ["yarn_cat", 1, {"cat_fur": 3}], ["yarn_sapphire", 1, {"sapphire_fluff": 3}], ["yarn_unicorn", 1, {"unicorn_hair": 3}], ["yarn_golden", 1, {"golden_fur": 3}], ["yarn_ember", 1, {"ember_tuft": 3}], ["yarn_down", 1, {"duck_down": 2, "goose_down": 1}], ["yarn_rabbit", 1, {"squirrel_fluff": 3}]],
	"loom": [["linen", 1, {"thread_linen": 3}], ["canvas", 1, {"thread_hemp": 3}], ["cotton_cloth", 1, {"thread_cotton": 3}], ["silk_cloth", 1, {"thread_silk": 3}], ["spider_cloth", 1, {"thread_spider": 3}], ["nettle_cloth", 1, {"thread_nettle": 3}], ["wool_cloth", 1, {"@yarn": 3}], ["felt", 1, {"@fur": 4}], ["rope", 1, {"twine": 3}], ["net_mesh", 1, {"rope": 2}], ["straw_mat", 1, {"straw": 6}], ["basket", 1, {"wicker": 5}], ["basket", 1, {"reed": 6}]],
	"dye_vat": [["dye_red", 2, {"poppy": 2, "water_cold": 1}], ["dye_orange", 2, {"calendula": 2, "water_cold": 1}], ["dye_yellow", 2, {"dandelion": 2, "water_cold": 1}], ["dye_green", 2, {"nettle": 2, "water_cold": 1}], ["dye_cyan", 2, {"glowmoss": 2, "water_cold": 1}], ["dye_blue", 2, {"cornflower": 2, "water_cold": 1}], ["dye_purple", 2, {"lavender": 2, "water_cold": 1}], ["dye_pink", 2, {"pink_clover": 2, "water_cold": 1}], ["dye_brown", 2, {"bark_tree_a": 2, "water_cold": 1}], ["dye_black", 2, {"charcoal": 1, "water_cold": 1}], ["dye_white", 2, {"chalk": 1, "water_cold": 1}], ["dye_gold", 2, {"sunflower_gold": 1, "water_cold": 1}], ["cloth_red", 1, {"cotton_cloth": 1, "dye_red": 1}], ["cloth_orange", 1, {"cotton_cloth": 1, "dye_orange": 1}], ["cloth_yellow", 1, {"cotton_cloth": 1, "dye_yellow": 1}], ["cloth_green", 1, {"cotton_cloth": 1, "dye_green": 1}], ["cloth_cyan", 1, {"cotton_cloth": 1, "dye_cyan": 1}], ["cloth_blue", 1, {"cotton_cloth": 1, "dye_blue": 1}], ["cloth_purple", 1, {"cotton_cloth": 1, "dye_purple": 1}], ["cloth_pink", 1, {"cotton_cloth": 1, "dye_pink": 1}], ["cloth_brown", 1, {"cotton_cloth": 1, "dye_brown": 1}], ["cloth_black", 1, {"cotton_cloth": 1, "dye_black": 1}], ["cloth_white", 1, {"cotton_cloth": 1, "dye_white": 1}], ["cloth_gold", 1, {"cotton_cloth": 1, "dye_gold": 1}], ["glass_red", 1, {"glass": 1, "dye_red": 1}], ["glass_yellow", 1, {"glass": 1, "dye_yellow": 1}], ["glass_green", 1, {"glass": 1, "dye_green": 1}], ["glass_blue", 1, {"glass": 1, "dye_blue": 1}], ["glass_purple", 1, {"glass": 1, "dye_purple": 1}], ["glass_pink", 1, {"glass": 1, "dye_pink": 1}]],
	"mason": [["stone_block", 1, {"stone_m": 2}], ["stone_block", 3, {"stone_l": 1}], ["marble_block", 1, {"marble": 2}], ["granite_block", 1, {"granite": 2}], ["sandstone_block", 1, {"sandstone": 2}], ["basalt_block", 1, {"basalt": 2}], ["slate_tile", 3, {"slate": 1}], ["gravel", 2, {"stone_s": 3}], ["cobble", 2, {"stone_m": 1}], ["mortar", 2, {"sand": 1, "lime": 1, "water_cold": 1}], ["rune_blank", 1, {"stone_block": 1}], ["sand", 2, {"sandstone": 1}]],
	"jeweler": [["gem_amethyst", 1, {"gem_raw_amethyst": 1}], ["gem_topaz", 1, {"gem_raw_topaz": 1}], ["gem_garnet", 1, {"gem_raw_garnet": 1}], ["gem_opal", 1, {"gem_raw_opal": 1}], ["gem_jade", 1, {"gem_raw_jade": 1}], ["gem_peridot", 1, {"gem_raw_peridot": 1}], ["gem_citrine", 1, {"gem_raw_citrine": 1}], ["gem_aquamarine", 1, {"gem_raw_aquamarine": 1}], ["gem_moonstone", 1, {"gem_raw_moonstone": 1}], ["gem_onyx", 1, {"gem_raw_onyx": 1}], ["gem_lapis", 1, {"gem_raw_lapis": 1}], ["gem_diamond", 1, {"gem_raw_diamond": 1}], ["gem_tourmaline", 1, {"gem_raw_tourmaline": 1}], ["gem_rose_quartz", 1, {"gem_raw_rose_quartz": 1}], ["gem_smoky_quartz", 1, {"gem_raw_smoky_quartz": 1}], ["gem_jet", 1, {"gem_raw_jet": 1}], ["gem_amber", 1, {"gem_raw_amber": 1}], ["gem_malachite", 1, {"gem_raw_malachite": 1}], ["mana_dust", 2, {"ore_mana": 1}], ["star_dust", 2, {"ore_star": 1}], ["void_dust", 2, {"ore_void": 1}], ["ember_dust", 2, {"ore_ember": 1}], ["frost_dust", 2, {"ore_frost": 1}], ["fairy_dust", 1, {"crystal_shard": 1, "pink_clover": 2}], ["moon_essence", 1, {"moon_dew": 1, "ore_moonsilver": 1}], ["rune_lit", 1, {"rune_blank": 1, "mana_dust": 2}], ["gem_raw_amber", 1, {"resin": 5}], ["pearl", 1, {"conch": 2}]],
	"press": [["plant_oil", 1, {"food_hazelnut": 3}], ["plant_oil", 1, {"food_walnut": 2}], ["plant_oil", 1, {"food_pine_nut": 3}], ["plant_oil", 1, {"food_acorn": 5}], ["paper", 3, {"sawdust": 3, "water_cold": 1}], ["paper", 2, {"reed": 3, "water_cold": 1}], ["book_blank", 1, {"paper": 8, "thread_linen": 1}], ["candle", 2, {"wax": 1, "twine": 1}], ["candle_scented", 1, {"candle": 1, "lavender": 1}], ["soap", 2, {"wood_ash": 2, "plant_oil": 1}], ["varnish", 1, {"plant_oil": 1, "resin": 1}], ["glue", 1, {"resin": 2}], ["wood_glue", 1, {"sawdust": 2, "glue": 1}], ["lamp_oil", 1, {"plant_oil": 2}], ["ink", 2, {"charcoal": 1, "bottle": 1}], ["honey", 1, {"honeycomb": 2}], ["wax", 1, {"honeycomb": 1}], ["flour", 1, {"grain": 6}], ["seed_mix", 4, {"grain": 3}], ["tar", 1, {"@wood": 2}]],
}
const GROUPS: Dictionary = {"@plank": "plank_", "@wood": "wood_", "@yarn": "yarn_", "@dye": "dye_"}
const FUR_IDS: Array = ["rabbit_fluff", "fox_tuft", "deer_fur", "squirrel_fluff", "duck_down", "sapphire_fluff", "unicorn_hair", "golden_fur", "ember_tuft", "cat_fur", "goose_down", "bat_fluff"]
## Ловушки: вид -> [название, кого ловит, приманка, часов до поимки в среднем]
const TRAPS: Dictionary = {"trap_small": ["Клетка для зверьков", ["rabbit", "squirrel", "hedgehog"], "food", 5.0], "trap_cage": ["Большая клетка", ["fox", "flat_boar", "duck"], "food", 7.0], "trap_pen": ["Ловчий загон", ["deer", "boar"], "food", 10.0], "trap_bird": ["Птичья корзинка", ["*bird"], "seed", 3.0], "trap_fish": ["Верша", ["*fish"], "food", 4.0], "trap_magic": ["Волшебная ловушка", ["sapphire_hare", "unicorn", "golden_deer", "ember_fox"], "magic", 14.0], "trap_bat": ["Сетка для летучих мышей", ["*bat"], "food", 6.0]}
const BAIT_MAGIC: Array = ["moon_dew", "food_pink_apple", "food_apple_golden", "mana_dust", "star_dust", "fairy_dust"]
const BAIT_SEED: Array = ["seed_mix", "grain", "food_pine_nut", "food_hazelnut", "food_acorn"]
## Что даёт пойманный зверь (вычесать / подобрать сброшенное — и отпустить): [[предмет, от, до, шанс]]
const LOOT: Dictionary = {"rabbit": [["rabbit_fluff", 2, 3, 1.0]], "squirrel": [["squirrel_fluff", 1, 2, 1.0]], "hedgehog": [["hedgehog_quill", 2, 4, 1.0]], "fox": [["fox_tuft", 1, 3, 1.0]], "flat_boar": [["boar_bristle", 3, 4, 1.0]], "duck": [["duck_down", 2, 3, 1.0]], "deer": [["deer_fur", 1, 3, 1.0], ["antler_shed", 1, 1, 0.3]], "boar": [["boar_bristle", 2, 3, 1.0]], "sapphire_hare": [["sapphire_fluff", 1, 2, 1.0]], "unicorn": [["unicorn_hair", 1, 2, 1.0], ["horn_shaving", 1, 1, 0.3]], "golden_deer": [["golden_fur", 1, 2, 1.0], ["golden_antler", 1, 1, 0.35]], "ember_fox": [["ember_tuft", 1, 2, 1.0]], "*fish": [["fish_scale", 2, 4, 1.0]], "*bat": [["bat_fluff", 1, 2, 1.0]]}
## Места добычи: вид -> [название, картинка, {биом: сколько на регион}, [[предмет, от, до, шанс]], дней до нового, звук]
const NODES: Dictionary = {
	"clay": ["Глиняный берег", "node_clay", {15: 5, 1: 2, 16: 2, 0: 2, 2: 1, 3: 1, 4: 2, 5: 1, 6: 1, 7: 1, 9: 1, 10: 1, 12: 2, 13: 1, 14: 1, 17: 1, 18: 1}, [["clay", 2, 3, 1.0]], 2, "dig"],
	"red_clay": ["Красная глина", "node_red_clay", {7: 4, 14: 2, 8: 2}, [["red_clay", 2, 3, 1.0]], 2, "dig"],
	"white_clay": ["Каолин", "node_white_clay", {11: 3, 6: 2, 17: 2}, [["white_clay", 1, 3, 1.0]], 3, "dig"],
	"sand": ["Песок", "node_sand", {18: 7, 16: 1, 7: 1}, [["sand", 2, 4, 1.0], ["shell", 1, 1, 0.2]], 1, "dig"],
	"black_sand": ["Чёрный песок", "node_black_sand", {18: 2, 11: 2, 8: 1}, [["black_sand", 2, 3, 1.0]], 2, "dig"],
	"quartz_sand": ["Кварцевый песок", "node_quartz_sand", {18: 1, 11: 2, 6: 1, 10: 1}, [["quartz_sand", 1, 3, 1.0]], 3, "dig"],
	"gravel": ["Осыпь", "node_gravel", {11: 3, 13: 2, 8: 3, 7: 1}, [["gravel", 2, 3, 1.0], ["flint", 1, 1, 0.35], ["nugget_copper", 1, 1, 0.12], ["nugget_tin", 1, 1, 0.1]], 2, "dig"],
	"flint": ["Кремни в траве", "node_flint", {1: 2, 16: 2, 12: 1, 13: 1, 0: 1}, [["flint", 1, 2, 1.0]], 3, "pick"],
	"peat": ["Торфяник", "node_peat", {15: 4}, [["peat", 2, 3, 1.0]], 3, "dig"],
	"salt": ["Соляная корка", "node_salt", {18: 3}, [["salt", 1, 3, 1.0]], 2, "pick"],
	"sulfur": ["Серный выход", "node_sulfur", {11: 2, 8: 2, 7: 1}, [["sulfur", 1, 3, 1.0]], 3, "pick"],
	"saltpeter": ["Селитра на камне", "node_saltpeter", {11: 1, 8: 1, 3: 1}, [["saltpeter", 1, 2, 1.0]], 4, "pick"],
	"coal": ["Угольный пласт", "node_coal", {8: 3, 11: 2, 13: 1, 7: 1}, [["coal", 2, 3, 1.0]], 3, "pick"],
	"obsidian": ["Обсидиановые осколки", "node_obsidian", {8: 2, 7: 1, 11: 1}, [["obsidian", 1, 2, 1.0]], 5, "pick"],
	"stones": ["Каменная россыпь", "node_stones", {1: 1, 13: 2, 12: 1, 14: 1, 3: 1, 4: 1, 6: 1}, [["limestone", 1, 1, 0.4], ["granite", 1, 1, 0.3], ["slate", 1, 1, 0.25], ["chalk", 1, 1, 0.2], ["marble", 1, 1, 0.08]], 3, "pick"],
	"flax": ["Лён", "node_flax", {16: 5, 1: 2, 0: 1}, [["flax", 2, 4, 1.0]], 3, "scythe"],
	"cotton": ["Хлопчатник", "node_cotton", {16: 3, 17: 2, 7: 1, 9: 1}, [["cotton", 2, 3, 1.0]], 3, "scythe"],
	"hemp": ["Дикая конопля", "node_hemp", {1: 3, 7: 2, 16: 2, 4: 1}, [["hemp", 2, 3, 1.0]], 3, "scythe"],
	"fiber": ["Сухая осока", "node_fiber", {1: 4, 16: 3, 12: 3, 13: 2, 14: 3, 15: 2, 0: 3, 5: 2, 10: 2}, [["plant_fiber", 2, 4, 1.0], ["twig", 1, 2, 0.4]], 1, "scythe"],
	"reeds": ["Тростник", "reeds", {15: 6, 18: 1}, [["reed", 2, 4, 1.0], ["wicker", 1, 2, 0.4]], 2, "scythe"],
	"straw": ["Дикая пшеница", "wheat_patch", {16: 4, 4: 1}, [["straw", 3, 5, 1.0], ["grain", 2, 4, 1.0]], 3, "scythe"],
	"cocoon": ["Шелкопряды", "node_cocoon", {2: 3, 5: 1, 17: 2}, [["silk_cocoon", 1, 2, 1.0]], 3, "pickup"],
	"web": ["Паутина", "web_ground", {2: 5, 3: 1}, [["spider_silk", 2, 3, 1.0]], 1, "pickup"],
	"shells": ["Ракушки", "beach_shells", {18: 5}, [["shell", 1, 3, 1.0], ["conch", 1, 1, 0.15], ["sea_glass", 1, 1, 0.25], ["starfish", 1, 1, 0.15], ["pearl", 1, 1, 0.03]], 1, "pickup"],
	"driftwood": ["Плавник", "driftwood", {18: 3, 15: 1}, [["driftwood", 1, 2, 1.0], ["kelp_dried", 1, 2, 0.4]], 3, "pickup"],
	"clam": ["Раковина-жемчужница", "giant_clam", {}, [["shell", 1, 2, 1.0], ["pearl", 1, 1, 0.3], ["conch", 1, 1, 0.15], ["sea_glass", 1, 1, 0.2]], 3, "pickup"],
	"hive": ["Дикий улей", "node_hive", {12: 2, 1: 1, 16: 2, 5: 1, 0: 1, 10: 1}, [["honeycomb", 1, 2, 1.0], ["propolis", 1, 1, 0.3], ["royal_jelly", 1, 1, 0.05]], 3, "pickup"],
	"crystals": ["Кристаллы", "crystal_cluster", {6: 2, 11: 2, 10: 1}, [["crystal_shard", 1, 2, 1.0], ["gem_raw_amethyst", 1, 1, 0.2], ["gem_raw_moonstone", 1, 1, 0.08]], 4, "pick"],
	"amber": ["Смоляной натёк", "node_amber", {13: 2, 18: 1}, [["resin", 2, 3, 1.0], ["gem_raw_amber", 1, 1, 0.25]], 3, "pickup"],
}
## Камни: что ещё выпадает по биому [[предмет, шанс]]
const ROCK_EXTRA: Dictionary = {6: [["gem_raw_amethyst", 0.075], ["gem_raw_opal", 0.05], ["gem_raw_moonstone", 0.05], ["gem_raw_lapis", 0.025], ["marble", 0.3], ["nugget_silver", 0.1], ["nugget_cobalt", 0.05], ["nugget_mithril", 0.05]], 11: [["gem_raw_amethyst", 0.075], ["gem_raw_moonstone", 0.025], ["gem_raw_lapis", 0.025], ["gem_raw_diamond", 0.025], ["gem_raw_smoky_quartz", 0.025], ["gem_raw_malachite", 0.025], ["pumice", 0.3], ["nugget_copper", 0.1], ["nugget_tin", 0.1], ["nugget_silver", 0.1], ["nugget_zinc", 0.1], ["nugget_nickel", 0.05], ["nugget_cobalt", 0.1], ["nugget_adamant", 0.05]], 10: [["gem_raw_amethyst", 0.025], ["gem_raw_opal", 0.05], ["gem_raw_moonstone", 0.05], ["gem_raw_tourmaline", 0.05], ["gem_raw_rose_quartz", 0.05], ["nugget_mithril", 0.05]], 8: [["gem_raw_topaz", 0.05], ["gem_raw_garnet", 0.05], ["gem_raw_citrine", 0.025], ["gem_raw_lapis", 0.05], ["gem_raw_diamond", 0.025], ["gem_raw_malachite", 0.05], ["granite", 0.3], ["basalt", 0.3], ["pumice", 0.3], ["nugget_copper", 0.15], ["nugget_tin", 0.1], ["nugget_iron", 0.15], ["nugget_gold", 0.1], ["nugget_zinc", 0.05], ["nugget_lead", 0.05], ["nugget_nickel", 0.05], ["nugget_cobalt", 0.05], ["nugget_adamant", 0.05]], 16: [["gem_raw_topaz", 0.025], ["gem_raw_citrine", 0.025], ["limestone", 0.3], ["sandstone", 0.3], ["flint", 0.3], ["nugget_gold", 0.05]], 7: [["gem_raw_topaz", 0.025], ["gem_raw_malachite", 0.025], ["basalt", 0.3], ["sandstone", 0.3], ["nugget_copper", 0.1], ["nugget_iron", 0.15], ["nugget_adamant", 0.05]], 3: [["gem_raw_garnet", 0.05], ["gem_raw_onyx", 0.075], ["gem_raw_jet", 0.05], ["slate", 0.3], ["nugget_iron", 0.05], ["nugget_silver", 0.1], ["nugget_lead", 0.1]], 17: [["gem_raw_jade", 0.075], ["gem_raw_tourmaline", 0.025], ["nugget_gold", 0.05], ["nugget_orichalcum", 0.1]], 5: [["gem_raw_jade", 0.025], ["gem_raw_peridot", 0.05], ["gem_raw_rose_quartz", 0.025], ["marble", 0.3], ["nugget_mithril", 0.1]], 15: [["gem_raw_peridot", 0.025], ["gem_raw_jet", 0.025], ["nugget_zinc", 0.05]], 12: [["gem_raw_peridot", 0.025], ["chalk", 0.3], ["flint", 0.3], ["nugget_tin", 0.05]], 14: [["gem_raw_citrine", 0.05], ["gem_raw_smoky_quartz", 0.025], ["flint", 0.3], ["nugget_copper", 0.05]], 18: [["gem_raw_aquamarine", 0.05], ["gem_raw_amber", 0.05], ["sandstone", 0.3], ["nugget_orichalcum", 0.05]], 19: [["gem_raw_aquamarine", 0.05], ["nugget_orichalcum", 0.05]], 13: [["gem_raw_aquamarine", 0.025], ["gem_raw_smoky_quartz", 0.05], ["gem_raw_amber", 0.075], ["granite", 0.3], ["slate", 0.3], ["nugget_tin", 0.05], ["nugget_iron", 0.05], ["nugget_silver", 0.05], ["nugget_nickel", 0.1]], 2: [["gem_raw_onyx", 0.05], ["slate", 0.3], ["nugget_lead", 0.05]], 9: [["gem_raw_rose_quartz", 0.025], ["limestone", 0.3]], 4: [["granite", 0.3], ["marble", 0.3], ["nugget_iron", 0.1]], 1: [["limestone", 0.3], ["chalk", 0.3], ["flint", 0.3], ["nugget_copper", 0.05]], 0: [["limestone", 0.3], ["chalk", 0.3]]}
## Новые руды для mining_db.ORES: металл -> {биом: вес}; названия руд — в MATS (ore_<металл>)
const ORE_DEPOSITS: Dictionary = {"copper": {8: 3, 7: 2, 11: 2, 14: 1, 1: 1}, "tin": {8: 2, 11: 2, 13: 1, 12: 1}, "iron": {8: 3, 7: 3, 4: 2, 13: 1, 3: 1}, "silver": {11: 2, 6: 2, 3: 2, 13: 1}, "gold": {8: 2, 16: 1, 17: 1}, "zinc": {11: 2, 8: 1, 15: 1}, "lead": {3: 2, 8: 1, 2: 1}, "nickel": {13: 2, 8: 1, 11: 1}, "cobalt": {11: 2, 6: 1, 8: 1}, "mithril": {5: 2, 6: 1, 10: 1}, "adamant": {8: 1, 7: 1, 11: 1}, "orichalcum": {17: 2, 19: 1, 18: 1}}
## Рубка: порода -> [[предмет, от, до, шанс]] (кроме брёвен и саженцев)
const CHOP_EXTRA: Dictionary = {"tree_a": [["wood_tree_a", 1, 2, 1.0], ["bark_tree_a", 1, 2, 0.6], ["twig", 1, 2, 0.5]], "tree_b": [["wood_tree_b", 1, 2, 1.0], ["bark_tree_b", 1, 2, 0.6], ["twig", 1, 2, 0.5]], "tree_c": [["wood_tree_c", 1, 2, 1.0], ["bark_tree_c", 1, 2, 0.6], ["twig", 1, 2, 0.5]], "tree_d": [["wood_tree_d", 1, 2, 1.0], ["bark_tree_d", 1, 2, 0.6], ["twig", 1, 2, 0.5]], "pine_a": [["wood_pine_a", 1, 2, 1.0], ["bark_pine_a", 1, 2, 0.6], ["twig", 1, 2, 0.5], ["resin", 1, 2, 0.6]], "pine_b": [["wood_pine_b", 1, 2, 1.0], ["bark_pine_b", 1, 2, 0.6], ["twig", 1, 2, 0.5], ["resin", 1, 2, 0.5]], "tree_blossom": [["wood_tree_blossom", 1, 2, 1.0], ["bark_tree_blossom", 1, 2, 0.6], ["twig", 1, 2, 0.5]], "tree_autumn": [["wood_tree_autumn", 1, 2, 1.0], ["bark_tree_autumn", 1, 2, 0.6], ["twig", 1, 2, 0.5]], "tree_autumn2": [["wood_tree_autumn2", 1, 2, 1.0], ["bark_tree_autumn2", 1, 2, 0.6], ["twig", 1, 2, 0.5]], "tree_apple": [["wood_tree_apple", 1, 2, 1.0], ["bark_tree_apple", 1, 2, 0.6], ["twig", 1, 2, 0.5]], "tree_birch": [["wood_tree_birch", 1, 2, 1.0], ["bark_tree_birch", 1, 2, 0.6], ["twig", 1, 2, 0.5]], "tree_unicorn": [["wood_tree_unicorn", 1, 2, 1.0], ["bark_tree_unicorn", 1, 2, 0.6], ["twig", 1, 2, 0.5]], "dead_tree_a": [["wood_dead", 1, 2, 1.0], ["bark_dead", 1, 2, 0.6], ["twig", 1, 2, 0.5]], "dead_tree_b": [["wood_dead", 1, 2, 1.0], ["bark_dead", 1, 2, 0.6], ["twig", 1, 2, 0.5]]}
## Постройки: вид -> [название, картинка, вес набора, преграда [x, y, w, h], вкладка, {материалы}]
const BUILD: Dictionary = {
	"workbench": ["Верстак", "workbench", 8.0, [-32, -18, 64, 16], "home", {"log": 6}],
	"table": ["Стол", "dp_table_round", 5.0, [-16, -16, 32, 14], "home", {"log": 4}],
	"research": ["Стол изучения трав", "research_table", 7.0, [-30, -18, 60, 16], "home", {"log": 6, "plant_fiber": 6}],
	"pen": ["Загон для зверей", "animal_pen", 10.0, [0, 0, 0, 0], "home", {"log": 10, "twine": 2}],
	"chest": ["Сундук", "dp_chest_small", 5.0, [-14, -12, 28, 12], "home", {"log": 5}],
	"plot": ["Грядка", "", 2.0, [0, 0, 0, 0], "home", {"log": 2}],
	"cauldron": ["Котёл для зелий", "cauldron", 8.0, [-20, -14, 40, 14], "home", {"log": 4, "stone_m": 6, "clay": 2}],
	"outhouse": ["Туалет", "outhouse", 9.0, [-22, -12, 44, 12], "home", {"log": 6}],
	"well": ["Колодец", "well", 10.0, [-30, -28, 60, 28], "home", {"log": 8, "stone_m": 10}],
	"lantern": ["Фонарь", "lantern", 2.0, [-5, -6, 10, 6], "home", {"log": 2, "resin": 1}],
	"fence": ["Забор", "fence", 1.0, [-16, -6, 32, 6], "wall", {"log": 1}],
	"bench": ["Скамейка", "bench", 4.0, [-30, -14, 60, 12], "deco", {"log": 3}],
	"campfire": ["Костёр", "campfire", 3.0, [-12, -8, 24, 8], "home", {"log": 3, "stone_s": 4}],
	"dryer": ["Сушилка для трав", "dryer", 6.0, [-30, -10, 60, 10], "home", {"log": 5, "twine": 2}],
	"stall": ["Лавка зелий", "stall_purple", 8.0, [-44, -14, 88, 14], "home", {"log": 6, "@plank": 4, "linen": 1}],
	"forge": ["Кузница", "forge", 12.0, [-42, -18, 84, 18], "home", {"log": 8, "stone_block": 6, "brick": 6}],
	"sawmill": ["Пилорама", "st20_sawmill", 10.0, [-34, -16, 68, 16], "work", {"log": 8, "stone_m": 2, "flint": 2}],
	"kiln": ["Печь для обжига", "st20_kiln", 12.0, [-26, -18, 52, 18], "work", {"stone_m": 10, "clay": 8}],
	"smelter": ["Плавильня", "st20_smelter", 14.0, [-28, -20, 56, 20], "work", {"brick": 10, "stone_block": 4, "clay": 4}],
	"anvil": ["Наковальня", "st20_anvil", 10.0, [-18, -10, 36, 10], "work", {"iron_bar": 4, "log": 2}],
	"spinning": ["Прялка", "st20_spinning", 5.0, [-18, -10, 36, 10], "work", {"@plank": 4, "stick": 4, "twine": 1}],
	"loom": ["Ткацкий станок", "loom", 8.0, [-30, -14, 60, 14], "work", {"@plank": 8, "stick": 6, "twine": 4}],
	"dye_vat": ["Красильный чан", "st20_dye_vat", 8.0, [-22, -12, 44, 12], "work", {"stave": 8, "iron_bar": 1, "stone_s": 4}],
	"mason": ["Каменотёсный стол", "st20_mason", 10.0, [-30, -14, 60, 14], "work", {"stone_l": 1, "@plank": 4, "flint": 3}],
	"jeweler": ["Стол ювелира", "st20_jeweler", 6.0, [-26, -14, 52, 14], "work", {"@plank": 6, "glass": 2, "bar_copper": 2}],
	"press": ["Пресс и котелок", "st20_press", 8.0, [-24, -14, 48, 14], "work", {"beam": 2, "@plank": 4, "pot_clay": 1}],
	"trap_small": ["Клетка для зверьков", "trap20_small", 2.0, [-10, -6, 20, 6], "trap", {"stick": 6, "twine": 2}],
	"trap_cage": ["Большая клетка", "trap20_cage", 5.0, [-16, -8, 32, 8], "trap", {"@plank": 3, "stick": 8, "rope": 1}],
	"trap_pen": ["Ловчий загон", "trap20_pen", 10.0, [-30, -10, 60, 10], "trap", {"log": 6, "rope": 2, "hinge": 1}],
	"trap_bird": ["Птичья корзинка", "trap20_bird", 1.0, [-8, -4, 16, 4], "trap", {"wicker": 4, "twine": 1}],
	"trap_fish": ["Верша", "trap20_fish", 2.0, [0, 0, 0, 0], "trap", {"wicker": 6, "twine": 2}],
	"trap_magic": ["Волшебная ловушка", "trap20_magic", 4.0, [-14, -8, 28, 8], "trap", {"wire_silver": 2, "gem_moonstone": 1, "@plank": 2}],
	"trap_bat": ["Сетка для летучих мышей", "trap20_bat", 2.0, [-12, -6, 24, 6], "trap", {"net_mesh": 1, "stick": 4}],
	"bird_feeder": ["Кормушка", "b20_feeder", 2.0, [-6, -4, 12, 4], "bird", {"@plank": 2, "stick": 2}],
	"birdhouse": ["Скворечник", "b20_birdhouse", 2.0, [-5, -4, 10, 4], "bird", {"@plank": 3, "nail": 4}],
	"bird_bath": ["Купалка для птиц", "b20_bath", 4.0, [-12, -6, 24, 6], "bird", {"stone_block": 2, "mortar": 1}],
	"owl_post": ["Присада для сов", "b20_owlpost", 3.0, [-4, -4, 8, 4], "bird", {"log": 2, "rope": 1}],
	"beehive": ["Улей", "b20_beehive", 4.0, [-12, -8, 24, 8], "home", {"@plank": 4, "honeycomb": 1, "nail": 4}],
	"compost": ["Компостный ящик", "b20_compost", 4.0, [-16, -10, 32, 10], "home", {"@plank": 4, "nail": 4}],
	"rain_barrel": ["Бочка для дождя", "b20_rain_barrel", 4.0, [-12, -8, 24, 8], "home", {"stave": 6, "iron_bar": 1}],
	"scarecrow": ["Пугало", "b20_scarecrow", 2.0, [-4, -4, 8, 4], "home", {"stick": 3, "straw": 6, "linen": 1}],
	"woodpile": ["Поленница", "woodpile", 6.0, [-30, -12, 60, 12], "home", {"log": 8}],
	"hay": ["Стог сена", "hay_bale", 4.0, [-20, -10, 40, 10], "home", {"straw": 12}],
	"planter": ["Ящик с цветами", "dp_flowerbox", 2.0, [-14, -6, 28, 6], "deco", {"@plank": 2, "loam": 2}],
	"clothesline": ["Бельевая верёвка", "b20_clothesline", 2.0, [-30, -4, 60, 4], "home", {"stick": 4, "rope": 1, "linen": 2}],
	"storage_crate": ["Ящик для материалов", "mine_crate", 4.0, [-14, -10, 28, 10], "home", {"@plank": 4, "nail": 4}],
	"barrel": ["Бочонок", "barrel", 3.0, [-10, -8, 20, 8], "home", {"stave": 6, "hinge": 1}],
	"flower_bed": ["Клумба", "flower_bed", 2.0, [0, 0, 0, 0], "deco", {"loam": 3, "stone_s": 4}],
	"rose_bush": ["Куст роз", "rose_bush", 2.0, [-10, -6, 20, 6], "deco", {"loam": 2, "rosehip": 2}],
	"pot_pink": ["Горшок с цветком", "dp_pot_pink", 1.0, [-6, -4, 12, 4], "deco", {"pot_clay": 1, "loam": 1}],
	"pot_red": ["Горшок с геранью", "dp_pot_red", 1.0, [-6, -4, 12, 4], "deco", {"pot_clay": 1, "loam": 1}],
	"stone_lantern": ["Каменный фонарь", "stone_lantern", 6.0, [-10, -6, 20, 6], "deco", {"stone_block": 3, "candle": 1}],
	"elf_lantern": ["Эльфийский фонарь", "elf_lantern", 3.0, [-5, -4, 10, 4], "deco", {"@plank": 1, "glass_green": 1, "candle": 1}],
	"goth_lamp": ["Кованый фонарь", "goth_lamp", 4.0, [-5, -4, 10, 4], "deco", {"lantern_frame": 1, "glass": 1, "lamp_oil": 1}],
	"sign": ["Указатель", "sign", 1.0, [-4, -3, 8, 3], "deco", {"@plank": 2, "stick": 1}],
	"banner": ["Знамя", "banner_pole", 2.0, [-4, -3, 8, 3], "deco", {"stick": 2, "cloth_red": 1}],
	"fountain": ["Фонтан", "cat_fountain", 20.0, [-40, -20, 80, 20], "deco", {"marble_block": 8, "mortar": 4, "sheet_copper": 2}],
	"pillar": ["Колонна", "pillar", 8.0, [-10, -6, 20, 6], "deco", {"marble_block": 3}],
	"tea_table": ["Чайный столик", "tea_table", 4.0, [-16, -8, 32, 8], "deco", {"@plank": 3, "porcelain": 2}],
	"yarn_basket": ["Корзина с пряжей", "yarn_basket", 1.0, [-6, -4, 12, 4], "deco", {"basket": 1, "@yarn": 2}],
	"star_globe": ["Звёздный глобус", "star_globe", 4.0, [-10, -6, 20, 6], "deco", {"bar_brass": 2, "glass_clear": 1, "star_dust": 1}],
	"rune_stone": ["Рунный камень", "rune_stone", 8.0, [-10, -6, 20, 6], "deco", {"stone_block": 2, "rune_lit": 1}],
	"archery": ["Мишень", "archery_target", 3.0, [-10, -4, 20, 4], "deco", {"straw": 6, "@plank": 2}],
	"torii": ["Тории", "torii", 14.0, [-50, -6, 100, 6], "deco", {"beam": 4, "dye_red": 2}],
	"totem": ["Тотем", "totem", 6.0, [-8, -6, 16, 6], "deco", {"log": 3, "dye_red": 1, "feather_crow": 2}],
	"pumpkins": ["Корзина с зеленью", "dp_basket_greens", 1.0, [-8, -4, 16, 4], "deco", {"basket": 1}],
	"stone_wall": ["Каменная стена", "w20_stone_wall", 6.0, [-16, -8, 32, 8], "wall", {"stone_block": 3, "mortar": 1}],
	"brick_wall": ["Кирпичная стена", "w20_brick_wall", 6.0, [-16, -8, 32, 8], "wall", {"brick": 4, "mortar": 1}],
	"hedge": ["Живая изгородь", "w20_hedge", 3.0, [-16, -8, 32, 8], "wall", {"sapling:tree_b": 1, "loam": 2}],
	"wicker_fence": ["Плетень", "w20_wicker", 2.0, [-16, -5, 32, 5], "wall", {"wicker": 4, "stick": 2}],
	"iron_fence": ["Кованая ограда", "iron_fence", 4.0, [-24, -6, 48, 6], "wall", {"iron_bar": 2, "chain": 1}],
	"palisade": ["Частокол", "palisade", 6.0, [-30, -8, 60, 8], "wall", {"log": 6}],
	"path_stone": ["Каменная дорожка", "w20_path_stone", 2.0, [0, 0, 0, 0], "wall", {"cobble": 4}],
	"path_brick": ["Кирпичная дорожка", "w20_path_brick", 2.0, [0, 0, 0, 0], "wall", {"brick": 3}],
	"path_wood": ["Деревянный настил", "w20_path_wood", 2.0, [0, 0, 0, 0], "wall", {"@plank": 3}],
	"path_gravel": ["Гравийная дорожка", "w20_path_gravel", 2.0, [0, 0, 0, 0], "wall", {"gravel": 4}],
	"path_marble": ["Мраморная плитка", "w20_path_marble", 2.0, [0, 0, 0, 0], "wall", {"marble_block": 1}],
}
const TABS: Array = ["home", "work", "trap", "bird", "deco", "wall"]
const FLAT: Array = ["path_stone", "path_brick", "path_wood", "path_gravel", "path_marble", "flower_bed"]
## Расширение участка — материалами (колышки, верёвка, камни), а не деньгами
const PLOT_NEED: Array = [{"stick": 8, "twine": 2}, {"stick": 12, "rope": 1, "stone_s": 6}, {"log": 6, "rope": 2, "stone_m": 6}, {"@plank": 8, "rope": 3, "stone_block": 4}, {"beam": 4, "chain": 1, "stone_block": 8}, {"beam": 6, "chain": 2, "brick": 12, "mortar": 4}]


static func has(id: String) -> bool:
	return MATS.has(id)


static func name(id: String) -> String:
	return String((MATS[id] as Array)[0]) if MATS.has(id) else id


static func weight(id: String) -> float:
	return float((MATS[id] as Array)[1])


static func price(id: String) -> int:
	return int((MATS[id] as Array)[2])


static var _icons: Dictionary = {}


static func icon(id: String) -> Texture2D:
	if not _icons.has(id):
		var p: String = "res://art/%s.png" % String((MATS[id] as Array)[3])
		_icons[id] = load(p) if ResourceLoader.exists(p) else load("res://art/icon_pack.png")
	return _icons[id]


static func cat(id: String) -> String:
	return String((MATS[id] as Array)[4])


static func props(id: String) -> Dictionary:
	return ((MATS[id] as Array)[5] as Dictionary).duplicate() if MATS.has(id) else {}


static func is_ingredient(id: String) -> bool:
	return MATS.has(id) and not ((MATS[id] as Array)[5] as Dictionary).is_empty()


static func cell_size(id: String) -> Vector2i:
	var s: Array = (MATS[id] as Array)[6]
	return Vector2i(int(s[0]), int(s[1]))


static func stack(id: String) -> int:
	return int((MATS[id] as Array)[7])


## Подходит ли предмет под «группу» в рецепте (@plank — любая доска и т.п.)
static func in_group(id: String, g: String) -> bool:
	if g == "@fur":
		return FUR_IDS.has(id)
	return GROUPS.has(g) and id.begins_with(String(GROUPS[g])) and MATS.has(id)


## Сколько у героини того, что нужно (с учётом групп)
static func have(inv: Dictionary, need: String) -> int:
	if not need.begins_with("@"):
		return int(inv.get(need, 0))
	var n: int = 0
	for k in inv.keys():
		if in_group(String(k), need):
			n += int(inv[k])
	return n


## Значок для того, что нужно: у группы — первая подходящая вещь (из сумки, если есть)
static func need_icon(inv: Dictionary, need: String) -> String:
	if not need.begins_with("@"):
		return need
	for k in inv.keys():
		if int(inv[k]) > 0 and in_group(String(k), need):
			return String(k)
	match need:
		"@plank":
			return "plank_tree_a"
		"@wood":
			return "wood_tree_a"
		"@yarn":
			return "yarn_rabbit"
		"@fur":
			return "rabbit_fluff"
	return "dye_red"


static func need_name(need: String) -> String:
	return {"@plank": "любые доски", "@wood": "любые чурки", "@yarn": "любая пряжа", "@fur": "любой пух или шерсть", "@dye": "любая краска"}.get(need, need)

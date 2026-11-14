extends RefCounted
## Справочник трав для книги травника. Свойства складываются в котле (recipes_db.gd).
## biomes — где растёт дикой (номера биомов из world_data.gd), price — цена у торговок,
## hours — только в эти часы (как у грибов), rare — насколько реже других на своём месте (1 — обычная).

const ORDER: Array = [
	"mint", "lavender", "chamomile", "nettle",
	"plantain", "clover", "dandelion", "yarrow", "thyme", "calendula",
	"cornflower", "poppy", "st_john", "oregano",
	"lungwort", "lily_valley", "strawberry",
	"lingonberry", "fern", "club_moss", "heather",
	"rosehip", "sage", "valerian", "wormwood",
	"moonbloom", "unicorn_mane", "pink_clover",
	"glowmoss", "stonecrop", "crystal_root",
	"calamus", "marsh_tea", "sundew", "cloudberry",
	"sea_buckthorn", "sea_lavender", "sea_kale",
	"nightshade", "mandrake", "elf_leaf", "shiso", "ginseng", "fire_pepper", "catnip", "star_bell", "web_grass", "arnica",
	"fire_lily", "frost_lotus", "shadow_orchid", "sunflower_gold", "dragon_root", "void_bloom", "phoenix_grass", "world_leaf",
	"sea_lettuce", "eelgrass", "kelp_gold", "sea_grape", "storm_weed", "sea_anemone", "pearl_moss", "coral_bloom", "ice_algae", "star_coral", "glow_algae", "mermaid_hair", "abyss_kelp", "siren_lily", "tide_orchid", "pearl_flower",
]
const SEEDS: Array = ["mint", "lavender", "chamomile"]

# Номера биомов (как в world_data.gd): 1 луг, 2 паутинный лес, 3 готика, 4 рыцари, 5 эльфы, 6 маги, 7 орки,
# 8 дворфы, 9 кошки, 10 розовый лес, 11 гроты, 12 берёзы, 13 тайга, 14 осень, 15 болото, 16 поля, 17 Япония, 18 побережье

const DATA: Dictionary = {
	"mint": {"name": "Мята перечная", "short": "Мята", "latin": "Mentha piperita", "props": [["Свежесть", "II"], ["Покой", "I"]],
		"desc": "Холодит язык и проясняет голову. Деревенские берут её от жара и тяжёлых снов.",
		"where": "Огород, сырые места у воды", "biomes": [1, 15], "price": 3},
	"lavender": {"name": "Лаванда", "short": "Лаванда", "latin": "Lavandula angustifolia", "props": [["Покой", "II"], ["Сон", "I"]],
		"desc": "Пахнет летним вечером. Мешочек под подушкой прогоняет кошмары, а настой утихомирит даже гнома.",
		"where": "Огород, солнечные поляны", "biomes": [1, 16, 6], "price": 3},
	"chamomile": {"name": "Ромашка аптечная", "short": "Ромашка", "latin": "Matricaria chamomilla", "props": [["Тепло", "I"], ["Исцеление", "I"]],
		"desc": "Маленькое солнце на тонком стебле. Первый чай, который варит любой травник для озябших детей.",
		"where": "Огород, луговые опушки", "biomes": [1, 16, 9], "price": 3},
	"nettle": {"name": "Крапива двудомная", "short": "Крапива", "latin": "Urtica dioica", "props": [["Сила", "II"], ["Жгучесть", "I"]],
		"desc": "Кусается, но лечит. Отвар возвращает силы после долгой зимы. Рвать бережно, в перчатках.",
		"where": "Лесная кромка", "biomes": [1, 12, 4], "price": 3},
	# ---- луга и поля у дома
	"plantain": {"name": "Подорожник большой", "short": "Подорожник", "latin": "Plantago major", "props": [["Исцеление", "I"], ["Свежесть", "I"]],
		"desc": "Растёт у каждой тропинки. Лист к ссадине — и боль уходит. Его знает каждый ребёнок.",
		"where": "Тропинки и луга", "biomes": [1, 16, 9, 4], "price": 2},
	"clover": {"name": "Клевер луговой", "short": "Клевер", "latin": "Trifolium pratense", "props": [["Покой", "I"], ["Исцеление", "I"]],
		"desc": "Сладкие розовые головки, которые обожают шмели. Чай из клевера мягко успокаивает.",
		"where": "Луга и поля", "biomes": [1, 16, 9], "price": 2},
	"dandelion": {"name": "Одуванчик", "short": "Одуванчик", "latin": "Taraxacum officinale", "props": [["Сила", "I"], ["Тепло", "I"]],
		"desc": "Жёлтый, как цыплёнок, а потом — белый и пушистый. Горький корень бодрит после болезни.",
		"where": "Луга, обочины", "biomes": [1, 16, 4, 9], "price": 2},
	"yarrow": {"name": "Тысячелистник", "short": "Тысячелистник", "latin": "Achillea millefolium", "props": [["Исцеление", "II"]],
		"desc": "Резные листья и белые зонтики. Им останавливали кровь ещё древние воины.",
		"where": "Сухие луга", "biomes": [1, 16, 4], "price": 4},
	"thyme": {"name": "Чабрец", "short": "Чабрец", "latin": "Thymus serpyllum", "props": [["Тепло", "II"]],
		"desc": "Стелется ковриком по пригоркам. Чай с чабрецом греет лучше печки.",
		"where": "Пригорки, степь", "biomes": [1, 16, 7], "price": 4},
	"calendula": {"name": "Календула", "short": "Календула", "latin": "Calendula officinalis", "props": [["Исцеление", "II"], ["Тепло", "I"]],
		"desc": "Ноготки — рыжие, как закат. Мазь из них затягивает любую ранку.",
		"where": "Луга у жилья", "biomes": [1, 9, 16], "price": 4},
	"cornflower": {"name": "Василёк синий", "short": "Василёк", "latin": "Centaurea cyanus", "props": [["Свежесть", "I"], ["Покой", "I"]],
		"desc": "Синие звёздочки среди колосьев. Примочки из васильков снимают усталость глаз.",
		"where": "Поля", "biomes": [16, 1], "price": 3},
	"poppy": {"name": "Мак полевой", "short": "Мак", "latin": "Papaver rhoeas", "props": [["Сон", "II"]],
		"desc": "Алый, как капля вина. Даже лепесток в чае клонит в сон.",
		"where": "Поля, земли Восходящего Солнца", "biomes": [16, 17], "price": 5},
	"st_john": {"name": "Зверобой", "short": "Зверобой", "latin": "Hypericum perforatum", "props": [["Тепло", "II"], ["Сила", "I"]],
		"desc": "Траву от девяноста девяти болезней собирают в самый солнечный день лета.",
		"where": "Поля, светлые рощи", "biomes": [16, 12], "price": 5},
	"oregano": {"name": "Душица", "short": "Душица", "latin": "Origanum vulgare", "props": [["Покой", "I"], ["Тепло", "I"]],
		"desc": "Пахнет пирогами и летом. Сиреневые метёлки любят пчёлы.",
		"where": "Опушки берёзовых рощ", "biomes": [12, 16], "price": 4},
	# ---- берёзовая роща
	"lungwort": {"name": "Медуница", "short": "Медуница", "latin": "Pulmonaria officinalis", "props": [["Свежесть", "I"], ["Исцеление", "I"]],
		"desc": "Цветы на одном стебле и розовые, и синие. Из неё пьют сладкий нектар шмели и дети.",
		"where": "Берёзовые рощи, эльфийский лес, розовый лес", "biomes": [12, 5, 10], "price": 4},
	"lily_valley": {"name": "Ландыш майский", "short": "Ландыш", "latin": "Convallaria majalis", "props": [["Покой", "II"]],
		"desc": "Белые колокольчики звенят без звука. В малой капле — покой сердцу, в большой — беда.",
		"where": "Тенистые рощи, розовый лес", "biomes": [12, 5, 10], "price": 6},
	"strawberry": {"name": "Земляника лесная", "short": "Земляника", "latin": "Fragaria vesca", "props": [["Свежесть", "II"], ["Тепло", "I"]],
		"desc": "Пахнет так, что слышно за десять шагов. Листья — для чая, ягоды — для радости.",
		"where": "Берёзовые, осенние и розовые опушки", "biomes": [12, 14, 10], "price": 4},
	# ---- тайга
	"lingonberry": {"name": "Брусника", "short": "Брусника", "latin": "Vaccinium vitis-idaea", "props": [["Свежесть", "II"], ["Сила", "I"]],
		"desc": "Кислые красные бусинки под соснами. Лист брусники — лучший друг почек.",
		"where": "Хвойная тайга", "biomes": [13], "price": 5},
	"fern": {"name": "Папоротник мужской", "short": "Папоротник", "latin": "Dryopteris filix-mas", "props": [["Сила", "II"]],
		"desc": "Говорят, он цветёт одну ночь в году. Цветка никто не видел, а силу корень даёт исправно.",
		"where": "Тайга, паутинная чаща", "biomes": [13, 2], "price": 5},
	"club_moss": {"name": "Плаун булавовидный", "short": "Плаун", "latin": "Lycopodium clavatum", "props": [["Сила", "I"], ["Жгучесть", "I"]],
		"desc": "Зелёные цепочки по земле. Его пыльца вспыхивает искрами — фокусники это любят.",
		"where": "Тайга, каменистые гроты", "biomes": [13, 11], "price": 5},
	"heather": {"name": "Вереск", "short": "Вереск", "latin": "Calluna vulgaris", "props": [["Покой", "II"], ["Сон", "I"]],
		"desc": "Сиреневые пустоши под осенним небом. Вересковый мёд — лучшее снотворное.",
		"where": "Тайга, сумрачные земли", "biomes": [13, 3], "price": 6},
	# ---- осенний лес
	"rosehip": {"name": "Шиповник", "short": "Шиповник", "latin": "Rosa canina", "props": [["Сила", "II"], ["Исцеление", "I"]],
		"desc": "Колючий куст с рыжими ягодами. Отвар из них зимой стоит дороже золота.",
		"where": "Осенний лес, рыцарские земли", "biomes": [14, 4], "price": 5},
	"sage": {"name": "Шалфей", "short": "Шалфей", "latin": "Salvia officinalis", "props": [["Исцеление", "II"], ["Свежесть", "I"]],
		"desc": "Бархатные серебристые листья. Полощут горло, прогоняют простуду.",
		"where": "Осенний лес, долина магов", "biomes": [14, 6], "price": 5},
	"valerian": {"name": "Валериана", "short": "Валериана", "latin": "Valeriana officinalis", "props": [["Сон", "II"], ["Покой", "I"]],
		"desc": "Розовые зонтики и корень, от которого сходят с ума кошки. Лучший сон в лесу.",
		"where": "Осенний лес, долина магов", "biomes": [14, 6], "price": 6},
	"wormwood": {"name": "Полынь горькая", "short": "Полынь", "latin": "Artemisia absinthium", "props": [["Жгучесть", "II"]],
		"desc": "Серебристая и горькая-прегорькая. Отпугивает моль, комаров и злых духов.",
		"where": "Осенние пустоши, степь орков", "biomes": [14, 7], "price": 4},
	# ---- розовый лес единорогов
	"moonbloom": {"name": "Лунноцвет", "short": "Лунноцвет", "latin": "Selene noctiflora", "props": [["Сон", "III"]],
		"desc": "Раскрывается только под луной и светится, как маленький фонарик. Один лепесток — и ночь без снов-кошмаров.",
		"where": "Розовый лес, только ночью", "biomes": [10], "price": 18, "hours": [20, 5], "rare": 0.6},
	"unicorn_mane": {"name": "Единорожья грива", "short": "Грива", "latin": "Crinis unicornis", "props": [["Исцеление", "III"]],
		"desc": "Шёлковые перламутровые пряди растут там, где пили единороги. Заживляет даже старые шрамы.",
		"where": "Розовый лес", "biomes": [10], "price": 20, "rare": 0.5},
	"pink_clover": {"name": "Клевер розовый", "short": "Розовый клевер", "latin": "Trifolium roseum", "props": [["Покой", "II"], ["Исцеление", "I"]],
		"desc": "Крупный, как пион, и пахнет сахарной ватой. Единороги едят его на десерт.",
		"where": "Розовый лес", "biomes": [10], "price": 8},
	# ---- гроты
	"glowmoss": {"name": "Светомох", "short": "Светомох", "latin": "Muscus lucens", "props": [["Свежесть", "II"], ["Сила", "II"]],
		"desc": "Голубой мох светится в темноте пещер. Днём его почти не видно.",
		"where": "Гроты, только ночью", "biomes": [11], "price": 12, "hours": [19, 6], "rare": 0.8},
	"stonecrop": {"name": "Очиток едкий", "short": "Очиток", "latin": "Sedum acre", "props": [["Жгучесть", "I"], ["Исцеление", "I"]],
		"desc": "Жёлтые звёздочки прямо на голом камне. Пить нельзя, а мазь из него хороша.",
		"where": "Камни гротов, горы дворфов", "biomes": [11, 8], "price": 6},
	"crystal_root": {"name": "Кристальный корень", "short": "Кристальный корень", "latin": "Radix crystallina", "props": [["Сила", "III"]],
		"desc": "Корень, проросший сквозь кристалл, сам наполовину кристалл. Звенит, если по нему постучать.",
		"where": "Глубокие гроты", "biomes": [11], "price": 22, "rare": 0.4},
	# ---- болото
	"calamus": {"name": "Аир болотный", "short": "Аир", "latin": "Acorus calamus", "props": [["Тепло", "II"], ["Сила", "I"]],
		"desc": "Длинные мечи-листья у воды. Корень пахнет мандарином и греет живот.",
		"where": "Болото", "biomes": [15], "price": 7},
	"marsh_tea": {"name": "Багульник", "short": "Багульник", "latin": "Rhododendron tomentosum", "props": [["Сон", "II"], ["Жгучесть", "I"]],
		"desc": "Его дурман висит над болотом белым облачком. Немного — сон, много — голова кругом.",
		"where": "Болото", "biomes": [15], "price": 8},
	"sundew": {"name": "Росянка", "short": "Росянка", "latin": "Drosera rotundifolia", "props": [["Жгучесть", "II"], ["Исцеление", "I"]],
		"desc": "Красные ресницы в капельках сладкой росы. Ловит комаров — и правильно делает.",
		"where": "Болото", "biomes": [15], "price": 14, "rare": 0.5},
	"cloudberry": {"name": "Морошка", "short": "Морошка", "latin": "Rubus chamaemorus", "props": [["Свежесть", "II"], ["Исцеление", "I"]],
		"desc": "Янтарная ягода северных болот. Одна ягода на стебель — потому так ценится.",
		"where": "Болото", "biomes": [15], "price": 9, "rare": 0.8},
	# ---- побережье
	"sea_buckthorn": {"name": "Облепиха", "short": "Облепиха", "latin": "Hippophae rhamnoides", "props": [["Тепло", "II"], ["Сила", "II"]],
		"desc": "Ветки облеплены оранжевыми ягодами. Масло облепихи лечит обветренную кожу моряков.",
		"where": "Побережье", "biomes": [18], "price": 10},
	"sea_lavender": {"name": "Кермек морской", "short": "Кермек", "latin": "Limonium vulgare", "props": [["Покой", "II"], ["Свежесть", "I"]],
		"desc": "Сухие сиреневые облачка над песком. Не вянет даже зимой в букете.",
		"where": "Побережье", "biomes": [18], "price": 8},
	"sea_kale": {"name": "Катран морской", "short": "Катран", "latin": "Crambe maritima", "props": [["Свежесть", "I"], ["Сила", "I"]],
		"desc": "Сизая морская капуста с белыми цветами. Соль ей нипочём.",
		"where": "Побережье", "biomes": [18], "price": 6},
	# ---- земли народов
	"nightshade": {"name": "Белладонна", "short": "Белладонна", "latin": "Atropa belladonna", "props": [["Сон", "III"], ["Жгучесть", "I"]],
		"desc": "Чёрные блестящие ягоды. Вампирши капают её сок в глаза ради красоты. Травнице — только для зелий.",
		"where": "Сумрачные земли, паутинная чаща, ночью", "biomes": [3, 2], "price": 16, "hours": [18, 6], "rare": 0.6},
	"mandrake": {"name": "Мандрагора", "short": "Мандрагора", "latin": "Mandragora officinarum", "props": [["Сила", "II"], ["Сон", "II"]],
		"desc": "Корень похож на маленького человечка и, говорят, пищит, когда его вынимают.",
		"where": "Сумрачные земли, долина магов", "biomes": [3, 6], "price": 18, "rare": 0.5},
	"elf_leaf": {"name": "Эльфийский лист", "short": "Эльфийский лист", "latin": "Folium elvorum", "props": [["Исцеление", "II"], ["Свежесть", "II"]],
		"desc": "Эльфийки заворачивают в него дорожный хлеб. Свежесть держится неделями.",
		"where": "Лес эльфов", "biomes": [5], "price": 12},
	"shiso": {"name": "Перилла", "short": "Перилла", "latin": "Perilla frutescens", "props": [["Свежесть", "II"], ["Тепло", "I"]],
		"desc": "Резные пурпурные листья, пахнут мятой и корицей сразу. Любимая приправа кицунэ.",
		"where": "Земли Восходящего Солнца", "biomes": [17], "price": 8},
	"ginseng": {"name": "Женьшень", "short": "Женьшень", "latin": "Panax ginseng", "props": [["Сила", "III"], ["Тепло", "I"]],
		"desc": "Корень жизни. Растёт десятки лет и прячется от того, кто ищет его с жадностью.",
		"where": "Земли Восходящего Солнца", "biomes": [17], "price": 24, "rare": 0.4},
	"fire_pepper": {"name": "Огнецвет", "short": "Огнецвет", "latin": "Capsicum ignis", "props": [["Жгучесть", "III"], ["Тепло", "II"]],
		"desc": "Стручки горят изнутри, как угольки. Орки едят его сырым на спор.",
		"where": "Степь орков, горы дворфов", "biomes": [7, 8], "price": 14, "rare": 0.7},
	"catnip": {"name": "Котовник", "short": "Котовник", "latin": "Nepeta cataria", "props": [["Покой", "II"], ["Сон", "I"]],
		"desc": "Кошкодевочки делают вид, что он им безразличен. Но мурлычут, проходя мимо.",
		"where": "Деревня кошкодевочек", "biomes": [9], "price": 6},
	"star_bell": {"name": "Звёздный колокольчик", "short": "Колокольчик", "latin": "Campanula stellaris", "props": [["Покой", "I"], ["Сон", "I"], ["Свежесть", "I"]],
		"desc": "Синие колокольчики со звёздочкой внутри. Маги слушают их звон в полнолуние.",
		"where": "Долина магов", "biomes": [6], "price": 9},
	"web_grass": {"name": "Паутинная трава", "short": "Паутинная трава", "latin": "Herba araneae", "props": [["Покой", "I"], ["Жгучесть", "I"]],
		"desc": "Тонкие травинки, оплетённые серебряной паутинкой. Паучихи вяжут из неё нитки.",
		"where": "Паутинная чаща", "biomes": [2], "price": 6},
	"arnica": {"name": "Арника горная", "short": "Арника", "latin": "Arnica montana", "props": [["Исцеление", "II"], ["Сила", "I"]],
		"desc": "Жёлтая ромашка гор. Дворфы и рыцари мажут ею ушибы после драк и турниров.",
		"where": "Горы дворфов, рыцарские земли", "biomes": [8, 4], "price": 8},
	# ---- v16: особые травы (нужна подготовка) и мега-редкие
	"fire_lily": {"name": "Огненная лилия", "short": "Огн. лилия", "latin": "Lilium ignifer", "props": [["Огонь", "III"], ["Свет", "I"]],
		"desc": "Лепестки тлеют, как угли, и светятся в темноте. Голой рукой не взять — обожжёт.",
		"where": "Степь орков и горы дворфов, ночью", "biomes": [7, 8], "price": 45, "hours": [20, 4], "rare": 0.25},
	"frost_lotus": {"name": "Ледяной лотос", "short": "Лотос", "latin": "Nymphaea glacialis", "props": [["Холод", "III"], ["Покой", "I"]],
		"desc": "Растёт на студёных озёрах тайги. Тает в тёплых руках, если медлить.",
		"where": "Тайга, на рассвете", "biomes": [13], "price": 40, "hours": [4, 9], "rare": 0.3},
	"shadow_orchid": {"name": "Теневая орхидея", "short": "Орхидея", "latin": "Orchis umbrae", "props": [["Тьма", "III"], ["Чары", "I"]],
		"desc": "Раскрывается только в полной темноте. Свет факела — и она прячется.",
		"where": "Сумрачные земли и паутинная чаща, глубокой ночью", "biomes": [3, 2], "price": 42, "hours": [22, 4], "rare": 0.25},
	"sunflower_gold": {"name": "Солнечник", "short": "Солнечник", "latin": "Helianthus aureus", "props": [["Свет", "III"], ["Тепло", "I"]],
		"desc": "Золотой цветок полей. Смотрит на солнце и в полдень сияет сам.",
		"where": "Поля, только в полдень", "biomes": [16], "price": 38, "hours": [11, 14], "rare": 0.3},
	"dragon_root": {"name": "Драконий корень", "short": "Драк. корень", "latin": "Radix draconis", "props": [["Огонь", "II"], ["Сила", "II"]],
		"desc": "Корень в чешуйках, тёплый на ощупь. Сидит глубоко — без лопаты не достать.",
		"where": "Степь орков", "biomes": [7], "price": 36, "rare": 0.3},
	"void_bloom": {"name": "Бездноцвет", "short": "Бездноцвет", "latin": "Flos abyssi", "props": [["Тьма", "III"], ["Чары", "II"], ["Жгучесть", "I"]],
		"desc": "Чёрный цветок с глазом посередине. Глядит в ответ. Говорят, его видели в гротах раз в несколько лет.",
		"where": "Гроты и Сумрачные земли, полночь", "biomes": [11, 3], "price": 400, "hours": [23, 2], "rare": 0.04},
	"phoenix_grass": {"name": "Перо феникса", "short": "Перо феникса", "latin": "Herba phoenicis", "props": [["Огонь", "III"], ["Исцеление", "III"], ["Свет", "II"]],
		"desc": "Огненная трава, что сгорает и вырастает из пепла. Видят её раз в жизни.",
		"where": "Горы дворфов, на рассвете", "biomes": [8, 7], "price": 500, "hours": [5, 7], "rare": 0.03},
	"world_leaf": {"name": "Лист Великого древа", "short": "Лист древа", "latin": "Folium mundi", "props": [["Исцеление", "III"], ["Чары", "III"], ["Свежесть", "I"]],
		"desc": "Падает с древа эльфов раз в сто лет. Тёплый и тихо звенит.",
		"where": "Лес эльфов", "biomes": [5], "price": 450, "rare": 0.03},
	# ---- v22: подводные травы (растут на дне моря, собирать можно только в хвосте русалки)
	"sea_lettuce": {"name": "Морской салат", "short": "Салат", "latin": "Ulva lactuca", "props": [["Свежесть", "II"]],
		"desc": "Тонкие зелёные листья, как мокрый шёлк. Русалки заворачивают в них рыбу.",
		"where": "Мелководье у берега", "biomes": [19], "price": 3},
	"eelgrass": {"name": "Взморник", "short": "Взморник", "latin": "Zostera marina", "props": [["Покой", "II"]],
		"desc": "Длинные ленты качаются в такт течению. Подушка из взморника отгоняет бессонницу.",
		"where": "Песчаное дно", "biomes": [19], "price": 4},
	"kelp_gold": {"name": "Золотая ламинария", "short": "Ламинария", "latin": "Laminaria aurea", "props": [["Свежесть", "II"], ["Сила", "I"]],
		"desc": "Бурые ленты с золотым отливом. Сушёная — лучшая подкормка для усталых мышц.",
		"where": "Каменистое дно", "biomes": [19], "price": 6},
	"sea_grape": {"name": "Морской виноград", "short": "Мор. виноград", "latin": "Caulerpa racemosa", "props": [["Свежесть", "I"], ["Исцеление", "I"]],
		"desc": "Зелёные шарики на ползучем стебле. Лопаются на языке, как икринки, и пахнут йодом.",
		"where": "Среди кораллов", "biomes": [19], "price": 5},
	"storm_weed": {"name": "Штормовая трава", "short": "Штормовка", "latin": "Fucus tempestas", "props": [["Сила", "II"], ["Жгучесть", "I"]],
		"desc": "Жёсткая, с пузырьками воздуха. Выживает даже там, где волны ломают камни.",
		"where": "Дно у скал", "biomes": [19], "price": 10},
	"sea_anemone": {"name": "Цветок-анемон", "short": "Анемон", "latin": "Actinia florida", "props": [["Жгучесть", "II"], ["Исцеление", "I"]],
		"desc": "Не цветок и не зверь. Щупальца жгут, зато сок — лучшее средство от ран.",
		"where": "Среди кораллов", "biomes": [19], "price": 9},
	"pearl_moss": {"name": "Жемчужный мох", "short": "Жемч. мох", "latin": "Bryum margarita", "props": [["Покой", "I"], ["Исцеление", "I"], ["Свет", "I"]],
		"desc": "Мягкий мох, усыпанный мелкими белыми шариками. Тихо мерцает у самого дна.",
		"where": "Дно, рядом с раковинами", "biomes": [19], "price": 12, "rare": 0.6},
	"coral_bloom": {"name": "Коралловый цвет", "short": "Кор. цвет", "latin": "Corallium florens", "props": [["Тепло", "II"], ["Чары", "I"]],
		"desc": "Розовые веточки, тёплые даже в глубине. Русалки плетут из них венки на праздник.",
		"where": "Коралловые сады", "biomes": [19], "price": 14, "rare": 0.6},
	"ice_algae": {"name": "Ледяная водоросль", "short": "Лед. водоросль", "latin": "Chondrus glacialis", "props": [["Холод", "II"], ["Свежесть", "I"]],
		"desc": "Голубые кружевные лопасти. Холодные, как зимняя прорубь, даже летом.",
		"where": "Глубокое дно", "biomes": [19], "price": 18, "rare": 0.5},
	"star_coral": {"name": "Звёздный коралл", "short": "Зв. коралл", "latin": "Astrocoenia lucida", "props": [["Сила", "II"], ["Свет", "I"]],
		"desc": "Каждая ячейка — маленькая звёздочка. Измельчённый, он даёт силу, как дневной свет.",
		"where": "Коралловые сады", "biomes": [19], "price": 22, "rare": 0.4},
	"glow_algae": {"name": "Световодоросль", "short": "Световодор.", "latin": "Noctiluca viridis", "props": [["Свет", "II"], ["Свежесть", "I"]],
		"desc": "Днём — бледная нить, ночью — изумрудный фонарик. Русалки зажигают ею свои домики.",
		"where": "Дно, только ночью", "biomes": [19], "price": 16, "hours": [19, 5], "rare": 0.5},
	"mermaid_hair": {"name": "Волосы русалки", "short": "Вол. русалки", "latin": "Cladophora sirena", "props": [["Исцеление", "II"], ["Чары", "I"]],
		"desc": "Тонкие зелёные пряди. Русалки уверяют, что это просто водоросль. Не верь.",
		"where": "Глубокое дно", "biomes": [19], "price": 30, "rare": 0.25},
	"abyss_kelp": {"name": "Глубинная ламинария", "short": "Глуб. ламинария", "latin": "Laminaria abyssalis", "props": [["Тьма", "II"], ["Сила", "II"]],
		"desc": "Чёрные ленты с синими прожилками. Растёт там, куда не доходит солнце.",
		"where": "Самое глубокое дно", "biomes": [19], "price": 28, "rare": 0.3},
	"siren_lily": {"name": "Лилия сирен", "short": "Лилия сирен", "latin": "Nymphaea sirena", "props": [["Чары", "II"], ["Покой", "II"]],
		"desc": "Поёт, когда на неё смотрят. Тот, кто послушает, надолго забывает дорогу домой.",
		"where": "Глубокое дно", "biomes": [19], "price": 40, "rare": 0.2},
	"tide_orchid": {"name": "Приливная орхидея", "short": "Прил. орхидея", "latin": "Orchis aestus", "props": [["Чары", "II"], ["Свежесть", "II"], ["Холод", "I"]],
		"desc": "Раскрывается раз в сутки, в час большого прилива. Даже русалки встречают её редко.",
		"where": "Глубокое дно", "biomes": [19], "price": 55, "rare": 0.12},
	"pearl_flower": {"name": "Жемчужный цветок", "short": "Жемч. цветок", "latin": "Flos margaritae", "props": [["Свет", "III"], ["Чары", "II"], ["Исцеление", "I"]],
		"desc": "В сердце цветка растёт настоящая жемчужина. Говорят, это слеза морской принцессы.",
		"where": "Самая глубина", "biomes": [19], "price": 120, "rare": 0.05},
}


static func title(id: String) -> String:
	return String(DATA[id]["name"]) if DATA.has(id) else id


static func short(id: String) -> String:
	return String(DATA[id].get("short", DATA[id]["name"])) if DATA.has(id) else id


static func icon(id: String) -> Texture2D:
	var p: String = "res://art/%s_3.png" % id
	if ResourceLoader.exists(p):
		return load(p)
	return load("res://art/herb14_%s.png" % id)


static func seed_icon(id: String) -> Texture2D:
	return load("res://art/seeds_%s.png" % id)


## Какие травы растут в этом биоме дико: [[id, вес], ...]
static func wild_for(biome: int) -> Array:
	var out: Array = []
	for id in ORDER:
		var d: Dictionary = DATA[id]
		if (d.get("biomes", []) as Array).has(biome):
			out.append([String(id), float(d.get("rare", 1.0))])
	return out


## Растёт ли трава сейчас (некоторые показываются только ночью)
static func hour_ok(id: String, h: float) -> bool:
	var hr: Array = DATA[id].get("hours", [])
	if hr.is_empty():
		return true
	var a: float = float(hr[0])
	var b: float = float(hr[1])
	return (h >= a and h < b) if a < b else (h >= a or h < b)


static func price(id: String) -> int:
	return int(DATA[id].get("price", 3)) if DATA.has(id) else 3

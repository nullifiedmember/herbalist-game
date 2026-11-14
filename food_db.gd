extends RefCounted
## Еда v17 (СГЕНЕРИРОВАНО tools/food_design.py — правь там и запускай с --write).
## Каждая еда — предмет в сумке с id "food_<id>". Есть: ПКМ в сумке или в руки (панель 1-8) и ЛКМ.

const KINDS: Dictionary = {"fruit": "Фрукты", "berry": "Ягоды", "veg": "Овощи", "nut": "Орехи", "bread": "Выпечка", "sweet": "Сладости", "dairy": "Молочное и яйца", "meat": "Мясо", "fish": "Рыба и море", "soup": "Супы", "mushroom": "Грибное", "drink": "Напитки"}
const ORDER: Array = ["apple", "apple_green", "apple_golden", "pink_apple", "cherry", "sakura_plum", "rowan", "acorn", "hazelnut", "walnut", "pine_nut", "birch_sap", "maple_syrup", "spruce_tips", "raspberry", "blueberry", "blackberry", "blackcurrant", "redcurrant", "gooseberry", "wild_strawberry", "cranberry", "pear", "plum", "peach", "grapes", "lemon", "orange", "watermelon", "pomegranate", "coconut", "fig", "carrot", "potato", "cabbage", "tomato", "cucumber", "onion", "pumpkin", "corn", "beet", "radish", "bell_pepper", "pea_pod", "bread", "black_bread", "baguette", "cinnamon_bun", "pie_fish", "pie_apple", "pie_blueberry", "pie_pumpkin", "cookie", "sugar_cookie", "gingerbread", "croissant", "flatbread", "cake_strawberry", "muffin", "pancakes", "forest_cracker", "cheese_sandwich", "milk", "cheese", "cheese_flatbread", "butter", "egg_boiled", "omelet", "yogurt", "roast_meat", "sausage", "ham", "kebab", "jerky", "chicken_leg", "stew", "dried_fish", "grilled_fish", "fish_soup", "sushi_roll", "fish_skewer", "seaweed_salad", "pearl_pudding", "mushroom_soup", "veg_soup", "pumpkin_soup", "onion_soup", "goblin_stew", "miso_soup", "fried_mushrooms", "mushroom_skewer", "mochi", "dango", "onigiri", "cider", "apple_juice", "berry_compote", "lemonade", "cocoa", "kumis", "ale", "mead", "pomegranate_juice", "star_tea", "green_tea", "flower_nectar", "dew_honey", "goblin_fizz", "coral_morse", "honeycomb", "caramel_bug", "jam_jar", "chocolate", "lollipop", "toffee"]

# id: [название, вид, сытность, питьё (сочность), цена, где взять, описание]
const DATA: Dictionary = {
	"apple": ["Яблоко", "fruit", 0.25, 0.25, 3, "яблоня", "Хрустящее, сочное. Классика любого двора."],
	"apple_green": ["Зелёное яблоко", "fruit", 0.22, 0.3, 3, "яблоня", "Кисловатое, бодрит лучше любого чая."],
	"apple_golden": ["Золотое яблоко", "fruit", 0.35, 0.25, 12, "яблоня (редко)", "Медовое, с золотистой кожицей. Находка для хозяйки."],
	"pink_apple": ["Розовое яблочко", "fruit", 0.3, 0.3, 15, "розовое древо", "С розового дерева единорогов. Пахнет сладкой жвачкой и чуточку магией."],
	"cherry": ["Вишня", "fruit", 0.12, 0.15, 4, "вишня-сакура", "Две вишенки на одном черенке."],
	"sakura_plum": ["Слива сакуры", "fruit", 0.15, 0.15, 6, "сакура", "Мелкая, терпкая, с цветочным привкусом."],
	"rowan": ["Рябина", "berry", 0.1, 0.1, 2, "рябина", "Горькая, пока не прихватит морозом. Птицы обожают."],
	"acorn": ["Жёлудь", "nut", 0.08, 0, 1, "дуб", "Сырым не очень вкусный, зато из него выйдет отличный кофе."],
	"hazelnut": ["Лесной орех", "nut", 0.12, 0, 3, "ясень, лещина", "Орешек с зелёной юбочкой. Белки подкупаются на него."],
	"walnut": ["Грецкий орех", "nut", 0.18, 0, 4, "вяз и ясень", "Морщинистый, как мозг. Кормит надолго."],
	"pine_nut": ["Кедровый орех", "nut", 0.15, 0, 5, "сосна", "Мелкие, жирные и ужасно вкусные."],
	"birch_sap": ["Берёзовый сок", "drink", 0, 0.6, 3, "берёза", "Прозрачный и чуть сладкий. Пей весной."],
	"maple_syrup": ["Кленовый сироп", "sweet", 0.2, 0, 8, "клён", "Густой, янтарный. На блины — самое то."],
	"spruce_tips": ["Хвойные побеги", "veg", 0.05, 0.1, 2, "ель", "Нежные салатовые кончики. Кисленькие, полны витаминов."],
	"raspberry": ["Малина", "berry", 0.1, 0.1, 4, "ягодник, лавка", "Нежная, тает во рту."],
	"blueberry": ["Черника", "berry", 0.1, 0.12, 4, "ягодник, лавка", "Синие губы и пальцы обеспечены."],
	"blackberry": ["Ежевика", "berry", 0.1, 0.1, 4, "ягодник, лавка", "Колючая, зато сладкая как мёд."],
	"blackcurrant": ["Чёрная смородина", "berry", 0.08, 0.12, 3, "лавка", "Терпкая, ароматная, вся в витаминах."],
	"redcurrant": ["Красная смородина", "berry", 0.08, 0.15, 3, "лавка", "Кисленькая, как маленькие бусины."],
	"gooseberry": ["Крыжовник", "berry", 0.1, 0.15, 3, "лавка", "Прозрачный и полосатый, как маленькие арбузики."],
	"wild_strawberry": ["Земляника", "berry", 0.08, 0.1, 5, "луг, лавка", "Пахнет летом на километр вокруг."],
	"cranberry": ["Клюква", "berry", 0.08, 0.1, 4, "болото, лавка", "Кислая-прекислая. Лучше с мёдом."],
	"pear": ["Груша", "fruit", 0.25, 0.25, 4, "лавка", "Сладкая и мягкая, сок течёт по подбородку."],
	"plum": ["Слива", "fruit", 0.15, 0.15, 3, "лавка", "Тёмная, с сизым налётом."],
	"peach": ["Персик", "fruit", 0.25, 0.25, 5, "лавка", "Бархатный и душистый."],
	"grapes": ["Виноград", "fruit", 0.2, 0.25, 6, "лавка", "Гроздь сочных ягод."],
	"lemon": ["Лимон", "fruit", 0.05, 0.3, 4, "лавка", "Кислый. Зато чай с ним — песня."],
	"orange": ["Апельсин", "fruit", 0.22, 0.35, 5, "лавка", "Солнце, которое можно съесть."],
	"watermelon": ["Ломоть арбуза", "fruit", 0.3, 0.5, 6, "лавка", "Красный, сочный, с косточками."],
	"pomegranate": ["Гранат", "fruit", 0.2, 0.25, 8, "Сумеречье", "Рубиновые зёрна. Вампирши говорят, что это просто фрукт."],
	"coconut": ["Кокос", "fruit", 0.3, 0.4, 8, "море", "С молоком внутри. Растёт на пальмах у пирса."],
	"fig": ["Инжир", "fruit", 0.2, 0.15, 6, "лавка", "Тягучий, как мёд, внутри полно семечек."],
	"carrot": ["Морковь", "veg", 0.2, 0.1, 2, "грядка, лавка", "Хрустит громче, чем кролик."],
	"potato": ["Картофель", "veg", 0.3, 0, 2, "грядка, лавка", "Скромный, но кормит народы."],
	"cabbage": ["Капуста", "veg", 0.25, 0.1, 3, "грядка, лавка", "Круглая, как голова, и хрустящая."],
	"tomato": ["Помидор", "veg", 0.15, 0.3, 3, "грядка, лавка", "Красный и сочный. Брызгает при укусе."],
	"cucumber": ["Огурец", "veg", 0.1, 0.35, 2, "грядка, лавка", "Свежий, холодный, на девяносто процентов вода."],
	"onion": ["Лук", "veg", 0.1, 0.05, 2, "грядка, лавка", "Режешь — плачешь, варишь — радуешься."],
	"pumpkin": ["Тыква", "veg", 0.4, 0.05, 6, "грядка, лавка", "Круглая и громкая, как оркестровый барабан."],
	"corn": ["Кукуруза", "veg", 0.3, 0.05, 3, "грядка, лавка", "Золотой початок в зелёных листьях."],
	"beet": ["Свёкла", "veg", 0.2, 0.1, 2, "грядка, лавка", "Фиолетовые пальцы после неё — не к чему стыдиться."],
	"radish": ["Редис", "veg", 0.08, 0.1, 2, "грядка, лавка", "Острый, маленький и хрустящий."],
	"bell_pepper": ["Сладкий перец", "veg", 0.12, 0.2, 4, "лавка", "Сладкий, как фрукт, хрустящий, как огурец."],
	"pea_pod": ["Стручок гороха", "veg", 0.1, 0.1, 2, "грядка, лавка", "Щёлк — и горошинки в ладони."],
	"bread": ["Хлеб", "bread", 0.35, 0, 4, "лавка, пекарня", "Ржаной, тёплый, с хрустящей корочкой."],
	"black_bread": ["Чёрный хлеб", "bread", 0.35, 0, 4, "Сумеречье", "Плотный, тёмный, с тмином. Не черствеет неделями."],
	"baguette": ["Белый батон", "bread", 0.3, 0, 5, "пекарня", "Золотой, длинный, с надрезами."],
	"cinnamon_bun": ["Булочка с корицей", "bread", 0.3, 0, 6, "Мурлыкино, пекарня", "Улитка с корицей — запах слышен через три дома."],
	"pie_fish": ["Пирожок с рыбой", "bread", 0.5, 0, 8, "Мурлыкино", "Главная гордость Шоколадки. Кошки в обмороке."],
	"pie_apple": ["Яблочный пирог", "bread", 0.5, 0.05, 9, "пекарня", "С корицей и румяной решёткой."],
	"pie_blueberry": ["Черничный пирог", "bread", 0.45, 0.05, 10, "Долина Звёзд", "Фиолетовая начинка течёт из-под корочки."],
	"pie_pumpkin": ["Тыквенный пирог", "bread", 0.55, 0.05, 12, "Сумеречье", "Пряный, оранжевый, с кружком сливок."],
	"cookie": ["Печенье", "bread", 0.12, 0, 3, "пекарня", "С шоколадными крошками."],
	"sugar_cookie": ["Сахарное печенье", "bread", 0.2, 0, 6, "Долина Звёзд", "Белое, посыпано звёздочками сахара."],
	"gingerbread": ["Пряник", "bread", 0.2, 0, 5, "пекарня", "Человечек с глазурью. Не смотри ему в глаза."],
	"croissant": ["Круассан", "bread", 0.25, 0, 6, "пекарня", "Слоёный, масляный, хрустит на весь дом."],
	"flatbread": ["Лепёшка", "bread", 0.3, 0, 5, "орки, лавка", "Плоская, с пузырьками, прямо с огня."],
	"cake_strawberry": ["Торт с клубникой", "sweet", 0.45, 0, 14, "кондитерская", "Взбитые сливки и клубника. Клёна старалась."],
	"muffin": ["Маффин", "bread", 0.25, 0, 6, "кондитерская", "С высокой шапочкой и изюмом."],
	"pancakes": ["Блинчики", "bread", 0.35, 0.05, 8, "кухня", "Стопка с маслом сверху."],
	"forest_cracker": ["Лесной хлебец", "bread", 0.25, 0, 9, "Элиарис", "Хрусткий, с семенами и сушёными травами."],
	"cheese_sandwich": ["Хлеб с сыром", "bread", 0.4, 0, 8, "Кронхольм", "Простая рыцарская закуска."],
	"milk": ["Молоко", "drink", 0.05, 0.35, 6, "Мурлыкино", "Свежее и тёплое. Кошки пьют его вместо воды."],
	"cheese": ["Сыр", "dairy", 0.25, 0, 7, "лавка", "С дырочками и острым запахом."],
	"cheese_flatbread": ["Сырная лепёшка", "bread", 0.45, 0, 8, "Подгорье", "Расплавленный сыр на жаркой лепёшке."],
	"butter": ["Масло", "dairy", 0.1, 0, 4, "лавка", "Кусочек солнечного масла."],
	"egg_boiled": ["Варёное яйцо", "dairy", 0.15, 0, 2, "кухня", "Сваренное вкрутую, с щепоткой соли."],
	"omelet": ["Омлет", "dairy", 0.35, 0, 6, "кухня", "Пышный, золотистый, с зеленью."],
	"yogurt": ["Йогурт", "dairy", 0.15, 0.2, 4, "лавка", "Густой, прохладный, с ягодкой."],
	"roast_meat": ["Жареное мясо", "meat", 0.6, 0, 11, "орки, рыцари", "Сочный кусок, шипящий жир."],
	"sausage": ["Колбаска", "meat", 0.3, 0, 6, "лавка", "Лопается, когда жаришь."],
	"ham": ["Окорок", "meat", 0.55, 0, 14, "лавка", "Копчёный, с розовой каёмкой."],
	"kebab": ["Шашлык", "meat", 0.5, 0, 9, "орки", "Мясо, лук и перец на палке."],
	"jerky": ["Вяленое мясо", "meat", 0.25, 0, 6, "лавка", "Жёсткое, солёное, в дорогу — самое то."],
	"chicken_leg": ["Куриная ножка", "meat", 0.4, 0, 7, "кухня", "Золотая корочка, косточка торчит."],
	"stew": ["Тушёное мясо с картошкой", "meat", 0.7, 0.1, 12, "кухня, трактир", "Густое, наваристое, на целый день сил."],
	"dried_fish": ["Сушёная рыбка", "fish", 0.35, 0, 8, "Мурлыкино", "Висела на солнышке. Кошки кружат вокруг стойки."],
	"grilled_fish": ["Жареная рыба", "fish", 0.5, 0.05, 9, "костёр", "С хрустящей корочкой и долькой лимона."],
	"fish_soup": ["Уха", "soup", 0.55, 0.2, 10, "кухня", "Прозрачный бульон с лавровым листом."],
	"sushi_roll": ["Роллы", "fish", 0.4, 0, 11, "Сакураяма", "Рис, водоросли и ломтик рыбы."],
	"fish_skewer": ["Рыба на палочке", "fish", 0.35, 0, 7, "костёр", "Жарится на углях, пахнет дымком."],
	"seaweed_salad": ["Морская капуста", "fish", 0.3, 0.05, 5, "Жемчужная Бухта", "Хрусткая, солёная, с кунжутом."],
	"pearl_pudding": ["Жемчужный пудинг", "sweet", 0.45, 0, 10, "Жемчужная Бухта", "Нежный, переливается как перламутр."],
	"mushroom_soup": ["Грибной суп", "soup", 0.45, 0.2, 9, "кухня", "Густой, сливочный, с лесным ароматом."],
	"veg_soup": ["Овощной суп", "soup", 0.4, 0.25, 7, "кухня", "Морковка, картошка и зелень."],
	"pumpkin_soup": ["Тыквенный суп", "soup", 0.45, 0.2, 9, "кухня", "Бархатный, оранжевый, с сухариками."],
	"onion_soup": ["Луковый суп", "soup", 0.4, 0.2, 8, "кухня", "С гренкой и тягучим сыром."],
	"goblin_stew": ["Грибная похлёбка", "soup", 0.35, 0.1, 6, "Хламбург", "Варят гоблины из того, что нашли. Есть можно."],
	"miso_soup": ["Мисо-суп", "soup", 0.3, 0.25, 8, "Сакураяма", "Тёплый, солоноватый, с кубиками тофу."],
	"fried_mushrooms": ["Жареные грибы", "mushroom", 0.35, 0, 8, "кухня", "Румяные, с луком. Дух стоит на весь двор."],
	"mushroom_skewer": ["Грибы на углях", "mushroom", 0.35, 0, 7, "Подгорье", "Нанизаны на прутик и обжарены над огнём."],
	"mochi": ["Моти", "sweet", 0.3, 0, 7, "Сакураяма", "Мягкий рисовый колобок, нежнее облака."],
	"dango": ["Данго", "sweet", 0.3, 0, 6, "Сакураяма", "Три шарика на палочке — розовый, белый, зелёный."],
	"onigiri": ["Онигири", "fish", 0.35, 0, 6, "Сакураяма", "Рисовый треугольник в водорослях."],
	"cider": ["Яблочный сидр", "drink", 0.05, 0.4, 7, "Кронхольм", "Игристый, с лёгкой кислинкой."],
	"apple_juice": ["Яблочный сок", "drink", 0.05, 0.45, 5, "кухня", "Мутноватый, прямо с пресса."],
	"berry_compote": ["Ягодный компот", "drink", 0.05, 0.45, 5, "кухня", "Тёмно-красный, с ягодками на дне."],
	"lemonade": ["Лимонад", "drink", 0, 0.5, 5, "лавка", "Кислый, сладкий и ледяной."],
	"cocoa": ["Какао", "drink", 0.1, 0.35, 7, "лавка", "Густое, с белой шапкой сливок."],
	"kumis": ["Кумыс", "drink", 0.05, 0.4, 7, "Степь Красной Лапы", "Кисловатый, шипучий, орки его обожают."],
	"ale": ["Эль", "drink", 0.05, 0.4, 6, "Подгорье", "Пенистый, золотой, по бабушкиному рецепту."],
	"mead": ["Медовуха", "drink", 0.05, 0.35, 9, "трактир", "Тёплая, сладкая, с пряным привкусом."],
	"pomegranate_juice": ["Гранатовый сок", "drink", 0, 0.5, 8, "Сумеречье", "Тёмный, как кровь. Не бойся, это сок."],
	"star_tea": ["Звёздный чай", "drink", 0, 0.55, 9, "Долина Звёзд", "Мерцает, как ночное небо. Чашка с блюдцем."],
	"green_tea": ["Зелёный чай", "drink", 0, 0.5, 6, "Сакураяма", "Пахнет свежескошенной травой и ритуалом."],
	"flower_nectar": ["Цветочный нектар", "drink", 0.05, 0.55, 8, "Элиарис", "Сладкий нектар в тонком бокале."],
	"dew_honey": ["Медовая роса", "drink", 0.05, 0.45, 7, "Паутинная чаща", "Роса с паутинок, смешанная с мёдом."],
	"goblin_fizz": ["Шипучка из банки", "drink", 0, 0.4, 5, "Хламбург", "Шипит и стреляет в нос. Банка настоящая."],
	"coral_morse": ["Коралловый морс", "drink", 0, 0.5, 7, "Жемчужная Бухта", "Розовый, с кусочками кораллового фрукта."],
	"honeycomb": ["Медовые соты", "sweet", 0.3, 0.15, 10, "Элиарис", "Сот с густым мёдом. Липкий, пальцы не отмоешь."],
	"caramel_bug": ["Жук в карамели", "sweet", 0.2, 0, 4, "Хламбург", "Гоблинский деликатес: хрустит и тянется."],
	"jam_jar": ["Варенье", "sweet", 0.25, 0, 8, "кухня", "Банка со льняной крышечкой."],
	"chocolate": ["Шоколад", "sweet", 0.2, 0, 9, "лавка", "Тёмный, горький и тающий."],
	"lollipop": ["Леденец", "sweet", 0.08, 0, 3, "лавка", "Спираль на палочке."],
	"toffee": ["Ириска", "sweet", 0.1, 0, 2, "лавка", "Липнет к зубам."],
}

# Рецепты кухни: [что нужно] -> блюдо. Готовка — на костре (E): берёт первый рецепт, для которого всё есть в сумке.
const RECIPES: Array = [
	[["apple", "honey"], "pie_apple"],
	[["apple_green", "honey"], "pie_apple"],
	[["apple", "water_cold"], "apple_juice"],
	[["blueberry", "honey"], "pie_blueberry"],
	[["raspberry", "honey"], "jam_jar"],
	[["blackberry", "honey"], "jam_jar"],
	[["wild_strawberry", "honey"], "jam_jar"],
	[["cranberry", "honey", "water_cold"], "berry_compote"],
	[["redcurrant", "honey", "water_cold"], "berry_compote"],
	[["pumpkin", "water_cold"], "pumpkin_soup"],
	[["carrot", "potato", "water_cold"], "veg_soup"],
	[["cabbage", "potato", "water_cold"], "veg_soup"],
	[["onion", "bread", "cheese"], "onion_soup"],
	[["porcini", "water_cold"], "mushroom_soup"],
	[["chanterelle", "water_cold"], "mushroom_soup"],
	[["birch_bolete", "water_cold"], "mushroom_soup"],
	[["porcini", "onion"], "fried_mushrooms"],
	[["chanterelle", "butter"], "fried_mushrooms"],
	[["morel", "butter"], "fried_mushrooms"],
	[["field_champignon", "butter"], "fried_mushrooms"],
	[["swamp_honey", "onion"], "fried_mushrooms"],
	[["egg_boiled", "butter"], "omelet"],
	[["lemon", "honey", "water_cold"], "lemonade"],
	[["orange", "honey", "water_cold"], "lemonade"],
	[["bread", "cheese"], "cheese_sandwich"],
	[["potato", "roast_meat", "water_cold"], "stew"],
	[["sausage", "bread"], "stew"],
	[["honey", "bread"], "cinnamon_bun"],
	[["milk", "honey"], "yogurt"],
	[["acorn", "honey"], "toffee"],
	[["maple_syrup", "flatbread"], "pancakes"],
	[["corn", "butter"], "pancakes"],
	[["bug_ladybug", "honey"], "caramel_bug"],
	[["bug_grasshopper", "honey"], "caramel_bug"],
	[["bug_dung_beetle", "honey"], "caramel_bug"],
]


static func is_food(id: String) -> bool:
	return id.begins_with("food_") and DATA.has(id.substr(5))


static func key(id: String) -> String:
	return id.substr(5) if id.begins_with("food_") else id


static func name(id: String) -> String:
	var k: String = key(id)
	return String((DATA[k] as Array)[0]) if DATA.has(k) else id


static func kind(id: String) -> String:
	var k: String = key(id)
	return String((DATA[k] as Array)[1]) if DATA.has(k) else ""


static func hunger_of(id: String) -> float:
	return float((DATA[key(id)] as Array)[2])


static func juicy_of(id: String) -> float:
	return float((DATA[key(id)] as Array)[3])


static func price(id: String) -> int:
	return int((DATA[key(id)] as Array)[4]) if DATA.has(key(id)) else 3


static func source(id: String) -> String:
	return String((DATA[key(id)] as Array)[5])


static func desc(id: String) -> String:
	return String((DATA[key(id)] as Array)[6])


static func icon(id: String) -> Texture2D:
	return load("res://art/food_%s.png" % key(id))


## Напиток? (пьётся: утоляет жажду)
static func is_drink(id: String) -> bool:
	return kind(id) == "drink"


## Предмет по названию (для старых списков товаров), "" — если такой еды нет
static func id_by_name(nm: String) -> String:
	for k in ORDER:
		if String((DATA[k] as Array)[0]) == nm:
			return "food_" + String(k)
	return ""


## Все блюда вида
static func of_kind(kd: String) -> Array:
	var out: Array = []
	for k in ORDER:
		if String((DATA[k] as Array)[1]) == kd:
			out.append("food_" + String(k))
	return out


## Первый рецепт, который можно приготовить из того, что в сумке: {"need": [...], "res": "food_x"} или {}
static func find_recipe(have: Callable) -> Dictionary:
	for r in RECIPES:
		var ok: bool = true
		var counts: Dictionary = {}
		for n in (r[0] as Array):
			var nid: String = _item_id(String(n))
			counts[nid] = int(counts.get(nid, 0)) + 1
		for nid in counts.keys():
			if int(have.call(nid)) < int(counts[nid]):
				ok = false
				break
		if ok:
			var needs: Array = []
			for nid2 in counts.keys():
				needs.append([nid2, counts[nid2]])
			return {"need": needs, "res": "food_" + String(r[1])}
	return {}


## Как называется предмет в сумке для ингредиента рецепта: еда — food_, остальное (травы, грибы, вода, мёд, жуки) как есть
static func _item_id(n: String) -> String:
	return "food_" + n if DATA.has(n) else n

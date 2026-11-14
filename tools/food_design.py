# -*- coding: utf-8 -*-
"""Еда v17: ЕДИНЫЙ источник данных. Запуск (из папки game):  python tools/food_design.py --write
Пишет food_db.gd (данные + функции) и значки art/food_<id>.png (32x32, пиксель-арт с обводкой и 4 тонами света),
контактный лист screenshots/v17_food.png.
Поля еды: id, название, вид, сытность h (0..1), сочность/питьё j, цена, форма значка, цвета, где взять, описание.
"""
import os, sys, math, colorsys
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
GAME = os.path.dirname(HERE)
ART = os.path.join(GAME, "art")
OUTLINE = (34, 22, 18, 255)

KINDS = {"fruit": "Фрукты", "berry": "Ягоды", "veg": "Овощи", "nut": "Орехи", "bread": "Выпечка", "sweet": "Сладости",
         "dairy": "Молочное и яйца", "meat": "Мясо", "fish": "Рыба и море", "soup": "Супы", "mushroom": "Грибное", "drink": "Напитки"}

# ---- (id, название, вид, h, j, цена, форма, [цвета], где взять, описание)
F = []
def f(i, n, k, h, j, p, shape, cols, src, desc):
    F.append((i, n, k, h, j, p, shape, cols, src, desc))

# ---- плоды деревьев (собираются с веток) ----
f("apple", "Яблоко", "fruit", .25, .25, 3, "ball", ["c8342a", "5a9a3a"], "яблоня", "Хрустящее, сочное. Классика любого двора.")
f("apple_green", "Зелёное яблоко", "fruit", .22, .30, 3, "ball", ["8cc23a", "4a8a2a"], "яблоня", "Кисловатое, бодрит лучше любого чая.")
f("apple_golden", "Золотое яблоко", "fruit", .35, .25, 12, "ball", ["e8b830", "5a9a3a"], "яблоня (редко)", "Медовое, с золотистой кожицей. Находка для хозяйки.")
f("pink_apple", "Розовое яблочко", "fruit", .30, .30, 15, "ball", ["f08ab0", "7ab04a"], "розовое древо", "С розового дерева единорогов. Пахнет сладкой жвачкой и чуточку магией.")
f("cherry", "Вишня", "fruit", .12, .15, 4, "cherries", ["b01830", "4a8a2a"], "вишня-сакура", "Две вишенки на одном черенке.")
f("sakura_plum", "Слива сакуры", "fruit", .15, .15, 6, "ball", ["b0508a", "5a9a3a"], "сакура", "Мелкая, терпкая, с цветочным привкусом.")
f("rowan", "Рябина", "berry", .10, .10, 2, "cluster", ["e0501e"], "рябина", "Горькая, пока не прихватит морозом. Птицы обожают.")
f("acorn", "Жёлудь", "nut", .08, 0, 1, "acorn", ["9a6a30", "6a4a22"], "дуб", "Сырым не очень вкусный, зато из него выйдет отличный кофе.")
f("hazelnut", "Лесной орех", "nut", .12, 0, 3, "nut", ["c89a58"], "ясень, лещина", "Орешек с зелёной юбочкой. Белки подкупаются на него.")
f("walnut", "Грецкий орех", "nut", .18, 0, 4, "walnut", ["b88a50"], "вяз и ясень", "Морщинистый, как мозг. Кормит надолго.")
f("pine_nut", "Кедровый орех", "nut", .15, 0, 5, "nut", ["e0c890"], "сосна", "Мелкие, жирные и ужасно вкусные.")
f("birch_sap", "Берёзовый сок", "drink", 0, .6, 3, "glass", ["d8e8d8", "9acf9a"], "берёза", "Прозрачный и чуть сладкий. Пей весной.")
f("maple_syrup", "Кленовый сироп", "sweet", .20, 0, 8, "jar", ["c88020", "a85a18"], "клён", "Густой, янтарный. На блины — самое то.")
f("spruce_tips", "Хвойные побеги", "veg", .05, .10, 2, "sprig", ["5a9a4a"], "ель", "Нежные салатовые кончики. Кисленькие, полны витаминов.")
# ---- ягоды ----
f("raspberry", "Малина", "berry", .10, .10, 4, "cluster", ["d02850"], "ягодник, лавка", "Нежная, тает во рту.")
f("blueberry", "Черника", "berry", .10, .12, 4, "cluster", ["4a5ab0"], "ягодник, лавка", "Синие губы и пальцы обеспечены.")
f("blackberry", "Ежевика", "berry", .10, .10, 4, "cluster", ["3a2a50"], "ягодник, лавка", "Колючая, зато сладкая как мёд.")
f("blackcurrant", "Чёрная смородина", "berry", .08, .12, 3, "cluster", ["2a2040"], "лавка", "Терпкая, ароматная, вся в витаминах.")
f("redcurrant", "Красная смородина", "berry", .08, .15, 3, "cluster", ["d03030"], "лавка", "Кисленькая, как маленькие бусины.")
f("gooseberry", "Крыжовник", "berry", .10, .15, 3, "cluster", ["a0c860"], "лавка", "Прозрачный и полосатый, как маленькие арбузики.")
f("wild_strawberry", "Земляника", "berry", .08, .10, 5, "cluster", ["e03040"], "луг, лавка", "Пахнет летом на километр вокруг.")
f("cranberry", "Клюква", "berry", .08, .10, 4, "cluster", ["c01828"], "болото, лавка", "Кислая-прекислая. Лучше с мёдом.")
# ---- фрукты (лавки) ----
f("pear", "Груша", "fruit", .25, .25, 4, "pear", ["b8c83a", "5a9a3a"], "лавка", "Сладкая и мягкая, сок течёт по подбородку.")
f("plum", "Слива", "fruit", .15, .15, 3, "ball", ["6a3a90", "5a9a3a"], "лавка", "Тёмная, с сизым налётом.")
f("peach", "Персик", "fruit", .25, .25, 5, "ball", ["f0a060", "5a9a3a"], "лавка", "Бархатный и душистый.")
f("grapes", "Виноград", "fruit", .20, .25, 6, "cluster", ["7a4aa0"], "лавка", "Гроздь сочных ягод.")
f("lemon", "Лимон", "fruit", .05, .30, 4, "lemon", ["f0d830"], "лавка", "Кислый. Зато чай с ним — песня.")
f("orange", "Апельсин", "fruit", .22, .35, 5, "ball", ["f08820", "4a8a2a"], "лавка", "Солнце, которое можно съесть.")
f("watermelon", "Ломоть арбуза", "fruit", .30, .50, 6, "melon", ["e83a4a", "4a9a3a"], "лавка", "Красный, сочный, с косточками.")
f("pomegranate", "Гранат", "fruit", .20, .25, 8, "ball", ["a81830", "7a1020"], "Сумеречье", "Рубиновые зёрна. Вампирши говорят, что это просто фрукт.")
f("coconut", "Кокос", "fruit", .30, .40, 8, "coconut", ["7a5a38", "f0f0e8"], "море", "С молоком внутри. Растёт на пальмах у пирса.")
f("fig", "Инжир", "fruit", .20, .15, 6, "pear", ["7a4a70", "5a9a3a"], "лавка", "Тягучий, как мёд, внутри полно семечек.")
# ---- овощи ----
f("carrot", "Морковь", "veg", .20, .10, 2, "long", ["f08a20", "4a9a3a"], "грядка, лавка", "Хрустит громче, чем кролик.")
f("potato", "Картофель", "veg", .30, 0, 2, "potato", ["b8924a"], "грядка, лавка", "Скромный, но кормит народы.")
f("cabbage", "Капуста", "veg", .25, .10, 3, "cabbage", ["8ac85a"], "грядка, лавка", "Круглая, как голова, и хрустящая.")
f("tomato", "Помидор", "veg", .15, .30, 3, "ball", ["e0301f", "4a9a3a"], "грядка, лавка", "Красный и сочный. Брызгает при укусе.")
f("cucumber", "Огурец", "veg", .10, .35, 2, "long", ["4a9a3a", "7ac85a"], "грядка, лавка", "Свежий, холодный, на девяносто процентов вода.")
f("onion", "Лук", "veg", .10, .05, 2, "onion", ["e0b060"], "грядка, лавка", "Режешь — плачешь, варишь — радуешься.")
f("pumpkin", "Тыква", "veg", .40, .05, 6, "pumpkin", ["f08020"], "грядка, лавка", "Круглая и громкая, как оркестровый барабан.")
f("corn", "Кукуруза", "veg", .30, .05, 3, "corn", ["f0d030", "6aaa3a"], "грядка, лавка", "Золотой початок в зелёных листьях.")
f("beet", "Свёкла", "veg", .20, .10, 2, "onion", ["8a1a48", "4a9a3a"], "грядка, лавка", "Фиолетовые пальцы после неё — не к чему стыдиться.")
f("radish", "Редис", "veg", .08, .10, 2, "onion", ["e83a5a", "4a9a3a"], "грядка, лавка", "Острый, маленький и хрустящий.")
f("bell_pepper", "Сладкий перец", "veg", .12, .20, 4, "pepper", ["e0301f", "4a9a3a"], "лавка", "Сладкий, как фрукт, хрустящий, как огурец.")
f("pea_pod", "Стручок гороха", "veg", .10, .10, 2, "pod", ["6ac84a"], "грядка, лавка", "Щёлк — и горошинки в ладони.")
# ---- выпечка ----
f("bread", "Хлеб", "bread", .35, 0, 4, "loaf", ["c8883a"], "лавка, пекарня", "Ржаной, тёплый, с хрустящей корочкой.")
f("black_bread", "Чёрный хлеб", "bread", .35, 0, 4, "loaf", ["6a4228"], "Сумеречье", "Плотный, тёмный, с тмином. Не черствеет неделями.")
f("baguette", "Белый батон", "bread", .30, 0, 5, "baguette", ["e0b060"], "пекарня", "Золотой, длинный, с надрезами.")
f("cinnamon_bun", "Булочка с корицей", "bread", .30, 0, 6, "bun", ["d89a58", "8a4a22"], "Мурлыкино, пекарня", "Улитка с корицей — запах слышен через три дома.")
f("pie_fish", "Пирожок с рыбой", "bread", .50, 0, 8, "pie", ["d8a058", "b8c8d0"], "Мурлыкино", "Главная гордость Шоколадки. Кошки в обмороке.")
f("pie_apple", "Яблочный пирог", "bread", .50, .05, 9, "pie", ["d89a48", "c8342a"], "пекарня", "С корицей и румяной решёткой.")
f("pie_blueberry", "Черничный пирог", "bread", .45, .05, 10, "pie", ["d09848", "4a5ab0"], "Долина Звёзд", "Фиолетовая начинка течёт из-под корочки.")
f("pie_pumpkin", "Тыквенный пирог", "bread", .55, .05, 12, "pie", ["d89a48", "f08020"], "Сумеречье", "Пряный, оранжевый, с кружком сливок.")
f("cookie", "Печенье", "bread", .12, 0, 3, "cookie", ["d8a050", "5a3a22"], "пекарня", "С шоколадными крошками.")
f("sugar_cookie", "Сахарное печенье", "bread", .20, 0, 6, "cookie", ["f0d8a0", "f0f0f0"], "Долина Звёзд", "Белое, посыпано звёздочками сахара.")
f("gingerbread", "Пряник", "bread", .20, 0, 5, "gingerman", ["a8602a", "f0f0e0"], "пекарня", "Человечек с глазурью. Не смотри ему в глаза.")
f("croissant", "Круассан", "bread", .25, 0, 6, "croissant", ["e0a040"], "пекарня", "Слоёный, масляный, хрустит на весь дом.")
f("flatbread", "Лепёшка", "bread", .30, 0, 5, "flat", ["d8a860"], "орки, лавка", "Плоская, с пузырьками, прямо с огня.")
f("cake_strawberry", "Торт с клубникой", "sweet", .45, 0, 14, "cake", ["f0c8d0", "e03040"], "кондитерская", "Взбитые сливки и клубника. Клёна старалась.")
f("muffin", "Маффин", "bread", .25, 0, 6, "muffin", ["c88a48", "f0c8d0"], "кондитерская", "С высокой шапочкой и изюмом.")
f("pancakes", "Блинчики", "bread", .35, .05, 8, "stack", ["e0a850", "f0d860"], "кухня", "Стопка с маслом сверху.")
f("forest_cracker", "Лесной хлебец", "bread", .25, 0, 9, "flat", ["a88858"], "Элиарис", "Хрусткий, с семенами и сушёными травами.")
f("cheese_sandwich", "Хлеб с сыром", "bread", .40, 0, 8, "sandwich", ["d8a050", "f0d040"], "Кронхольм", "Простая рыцарская закуска.")
# ---- молочное, яйца ----
f("milk", "Молоко", "drink", .05, .35, 6, "glass", ["f8f8f0", "d8d8d0"], "Мурлыкино", "Свежее и тёплое. Кошки пьют его вместо воды.")
f("cheese", "Сыр", "dairy", .25, 0, 7, "cheese", ["f0c030"], "лавка", "С дырочками и острым запахом.")
f("cheese_flatbread", "Сырная лепёшка", "bread", .45, 0, 8, "flat", ["f0d040", "d8a050"], "Подгорье", "Расплавленный сыр на жаркой лепёшке.")
f("butter", "Масло", "dairy", .10, 0, 4, "butter", ["f8e060"], "лавка", "Кусочек солнечного масла.")
f("egg_boiled", "Варёное яйцо", "dairy", .15, 0, 2, "egg", ["f4ecd8", "f0b840"], "кухня", "Сваренное вкрутую, с щепоткой соли.")
f("omelet", "Омлет", "dairy", .35, 0, 6, "omelet", ["f8d848", "d8a830"], "кухня", "Пышный, золотистый, с зеленью.")
f("yogurt", "Йогурт", "dairy", .15, .20, 4, "jar", ["f8f8f0", "e0e0e0"], "лавка", "Густой, прохладный, с ягодкой.")
# ---- мясо ----
f("roast_meat", "Жареное мясо", "meat", .60, 0, 11, "drum", ["a8602a"], "орки, рыцари", "Сочный кусок, шипящий жир.")
f("sausage", "Колбаска", "meat", .30, 0, 6, "sausage", ["c8603a"], "лавка", "Лопается, когда жаришь.")
f("ham", "Окорок", "meat", .55, 0, 14, "ham", ["d86a5a", "f0d8c8"], "лавка", "Копчёный, с розовой каёмкой.")
f("kebab", "Шашлык", "meat", .50, 0, 9, "skewer", ["a05028", "d0a050"], "орки", "Мясо, лук и перец на палке.")
f("jerky", "Вяленое мясо", "meat", .25, 0, 6, "jerky", ["6a3a22"], "лавка", "Жёсткое, солёное, в дорогу — самое то.")
f("chicken_leg", "Куриная ножка", "meat", .40, 0, 7, "drum", ["d8883a"], "кухня", "Золотая корочка, косточка торчит.")
f("stew", "Тушёное мясо с картошкой", "meat", .70, .10, 12, "bowl", ["a8602a", "d8b058"], "кухня, трактир", "Густое, наваристое, на целый день сил.")
# ---- рыба и море ----
f("dried_fish", "Сушёная рыбка", "fish", .35, 0, 8, "fishdry", ["c8a870"], "Мурлыкино", "Висела на солнышке. Кошки кружат вокруг стойки.")
f("grilled_fish", "Жареная рыба", "fish", .50, .05, 9, "fish", ["c88a3a", "f0d890"], "костёр", "С хрустящей корочкой и долькой лимона.")
f("fish_soup", "Уха", "soup", .55, .20, 10, "bowl", ["e8b050", "c8d8d0"], "кухня", "Прозрачный бульон с лавровым листом.")
f("sushi_roll", "Роллы", "fish", .40, 0, 11, "roll", ["f0f0e8", "e87060"], "Сакураяма", "Рис, водоросли и ломтик рыбы.")
f("fish_skewer", "Рыба на палочке", "fish", .35, 0, 7, "skewer", ["d89a40", "e0c890"], "костёр", "Жарится на углях, пахнет дымком.")
f("seaweed_salad", "Морская капуста", "fish", .30, .05, 5, "salad", ["2a7a5a", "9ad8a0"], "Жемчужная Бухта", "Хрусткая, солёная, с кунжутом.")
f("pearl_pudding", "Жемчужный пудинг", "sweet", .45, 0, 10, "pudding", ["f0e8f8", "c0a8e0"], "Жемчужная Бухта", "Нежный, переливается как перламутр.")
# ---- супы ----
f("mushroom_soup", "Грибной суп", "soup", .45, .20, 9, "bowl", ["b8905a", "e8d8b0"], "кухня", "Густой, сливочный, с лесным ароматом.")
f("veg_soup", "Овощной суп", "soup", .40, .25, 7, "bowl", ["e08a3a", "7ab04a"], "кухня", "Морковка, картошка и зелень.")
f("pumpkin_soup", "Тыквенный суп", "soup", .45, .20, 9, "bowl", ["f09a30", "f8e8c8"], "кухня", "Бархатный, оранжевый, с сухариками.")
f("onion_soup", "Луковый суп", "soup", .40, .20, 8, "bowl", ["b8803a", "f0d060"], "кухня", "С гренкой и тягучим сыром.")
f("goblin_stew", "Грибная похлёбка", "soup", .35, .10, 6, "bowl", ["6a8a4a", "a8a060"], "Хламбург", "Варят гоблины из того, что нашли. Есть можно.")
f("miso_soup", "Мисо-суп", "soup", .30, .25, 8, "bowl", ["c8a060", "e8c88a"], "Сакураяма", "Тёплый, солоноватый, с кубиками тофу.")
# ---- грибное ----
f("fried_mushrooms", "Жареные грибы", "mushroom", .35, 0, 8, "mush", ["b88858"], "кухня", "Румяные, с луком. Дух стоит на весь двор.")
f("mushroom_skewer", "Грибы на углях", "mushroom", .35, 0, 7, "skewer", ["a87848", "e8d0a0"], "Подгорье", "Нанизаны на прутик и обжарены над огнём.")
# ---- Япония ----
f("mochi", "Моти", "sweet", .30, 0, 7, "mochi", ["f8f0f0", "f0a0b8"], "Сакураяма", "Мягкий рисовый колобок, нежнее облака.")
f("dango", "Данго", "sweet", .30, 0, 6, "dango", ["f0a0b8", "f8f8f0", "a0d090"], "Сакураяма", "Три шарика на палочке — розовый, белый, зелёный.")
f("onigiri", "Онигири", "fish", .35, 0, 6, "onigiri", ["f8f8f0", "2a3a2a"], "Сакураяма", "Рисовый треугольник в водорослях.")
# ---- напитки ----
f("cider", "Яблочный сидр", "drink", .05, .40, 7, "mug", ["e0b040", "f0e8b8"], "Кронхольм", "Игристый, с лёгкой кислинкой.")
f("apple_juice", "Яблочный сок", "drink", .05, .45, 5, "glass", ["e8c840", "c8a020"], "кухня", "Мутноватый, прямо с пресса.")
f("berry_compote", "Ягодный компот", "drink", .05, .45, 5, "glass", ["b02848", "801838"], "кухня", "Тёмно-красный, с ягодками на дне.")
f("lemonade", "Лимонад", "drink", 0, .50, 5, "glass", ["f0e060", "f8f0a0"], "лавка", "Кислый, сладкий и ледяной.")
f("cocoa", "Какао", "drink", .10, .35, 7, "mug", ["6a3a22", "f0f0e8"], "лавка", "Густое, с белой шапкой сливок.")
f("kumis", "Кумыс", "drink", .05, .40, 7, "mug", ["f0f0e0", "d8d8c0"], "Степь Красной Лапы", "Кисловатый, шипучий, орки его обожают.")
f("ale", "Эль", "drink", .05, .40, 6, "mug", ["d8901a", "f8f0d8"], "Подгорье", "Пенистый, золотой, по бабушкиному рецепту.")
f("mead", "Медовуха", "drink", .05, .35, 9, "mug", ["e8a820", "f0d880"], "трактир", "Тёплая, сладкая, с пряным привкусом.")
f("pomegranate_juice", "Гранатовый сок", "drink", 0, .50, 8, "glass", ["a01830", "701020"], "Сумеречье", "Тёмный, как кровь. Не бойся, это сок.")
f("star_tea", "Звёздный чай", "drink", 0, .55, 9, "mug", ["5a3a90", "f0e0f8"], "Долина Звёзд", "Мерцает, как ночное небо. Чашка с блюдцем.")
f("green_tea", "Зелёный чай", "drink", 0, .50, 6, "mug", ["8ab048", "c8e8a0"], "Сакураяма", "Пахнет свежескошенной травой и ритуалом.")
f("flower_nectar", "Цветочный нектар", "drink", .05, .55, 8, "glass", ["f0b8d8", "d890b8"], "Элиарис", "Сладкий нектар в тонком бокале.")
f("dew_honey", "Медовая роса", "drink", .05, .45, 7, "glass", ["f0e8a0", "d8c860"], "Паутинная чаща", "Роса с паутинок, смешанная с мёдом.")
f("goblin_fizz", "Шипучка из банки", "drink", 0, .40, 5, "can", ["60c8a8", "a8e8d0"], "Хламбург", "Шипит и стреляет в нос. Банка настоящая.")
f("coral_morse", "Коралловый морс", "drink", 0, .50, 7, "glass", ["f07a8a", "c85068"], "Жемчужная Бухта", "Розовый, с кусочками кораллового фрукта.")
# ---- сладости ----
f("honeycomb", "Медовые соты", "sweet", .30, .15, 10, "comb", ["e8a828", "f8d868"], "Элиарис", "Сот с густым мёдом. Липкий, пальцы не отмоешь.")
f("caramel_bug", "Жук в карамели", "sweet", .20, 0, 4, "bugcandy", ["c8782a", "3a2a1a"], "Хламбург", "Гоблинский деликатес: хрустит и тянется.")
f("jam_jar", "Варенье", "sweet", .25, 0, 8, "jar", ["b02848", "d8a0a0"], "кухня", "Банка со льняной крышечкой.")
f("chocolate", "Шоколад", "sweet", .20, 0, 9, "bar", ["5a3220", "f0d8b0"], "лавка", "Тёмный, горький и тающий.")
f("lollipop", "Леденец", "sweet", .08, 0, 3, "lolly", ["e8409a", "f0f0f0"], "лавка", "Спираль на палочке.")
f("toffee", "Ириска", "sweet", .10, 0, 2, "toffee", ["c8883a", "f8f0e0"], "лавка", "Липнет к зубам.")

ORDER = [x[0] for x in F]
assert len(ORDER) == len(set(ORDER)), "повтор id"

# ---- рецепты кухни: [список нужного] -> блюдо. Едва ли не весь список блюд можно приготовить на плите/костре.
RECIPES = [
    (["apple", "honey"], "pie_apple", "Яблочный пирог"),
    (["apple_green", "honey"], "pie_apple", ""),
    (["apple", "water_cold"], "apple_juice", ""),
    (["blueberry", "honey"], "pie_blueberry", ""),
    (["raspberry", "honey"], "jam_jar", ""),
    (["blackberry", "honey"], "jam_jar", ""),
    (["wild_strawberry", "honey"], "jam_jar", ""),
    (["cranberry", "honey", "water_cold"], "berry_compote", ""),
    (["redcurrant", "honey", "water_cold"], "berry_compote", ""),
    (["pumpkin", "water_cold"], "pumpkin_soup", ""),
    (["carrot", "potato", "water_cold"], "veg_soup", ""),
    (["cabbage", "potato", "water_cold"], "veg_soup", ""),
    (["onion", "bread", "cheese"], "onion_soup", ""),
    (["porcini", "water_cold"], "mushroom_soup", ""),
    (["chanterelle", "water_cold"], "mushroom_soup", ""),
    (["birch_bolete", "water_cold"], "mushroom_soup", ""),
    (["porcini", "onion"], "fried_mushrooms", ""),
    (["chanterelle", "butter"], "fried_mushrooms", ""),
    (["morel", "butter"], "fried_mushrooms", ""),
    (["field_champignon", "butter"], "fried_mushrooms", ""),
    (["swamp_honey", "onion"], "fried_mushrooms", ""),
    (["egg_boiled", "butter"], "omelet", ""),
    (["lemon", "honey", "water_cold"], "lemonade", ""),
    (["orange", "honey", "water_cold"], "lemonade", ""),
    (["bread", "cheese"], "cheese_sandwich", ""),
    (["potato", "roast_meat", "water_cold"], "stew", ""),
    (["sausage", "bread"], "stew", ""),
    (["honey", "bread"], "cinnamon_bun", ""),
    (["milk", "honey"], "yogurt", ""),
    (["acorn", "honey"], "toffee", ""),
    (["maple_syrup", "flatbread"], "pancakes", ""),
    (["corn", "butter"], "pancakes", ""),
    (["bug_ladybug", "honey"], "caramel_bug", ""),
    (["bug_grasshopper", "honey"], "caramel_bug", ""),
    (["bug_dung_beetle", "honey"], "caramel_bug", ""),
]
# Сырое -> готовое на огне (плита / костёр): ингредиент, результат
COOK1 = [
    ("water_cold", "egg_boiled", "egg"),     # заглушка не используется
]
COOK1 = [("egg_boiled", "omelet", "")]
# виды, которые любят вербуемые жители (для «кормить за службу»)
LIKES = ["fruit", "berry", "veg", "bread", "sweet", "meat", "fish", "soup", "dairy", "mushroom", "drink", "nut"]


# ------------------------------------------------------------------ рисование значка
def hexc(s):
    return tuple(int(s[i:i + 2], 16) for i in (0, 2, 4))


def shade(c, k):
    r, g, b = [x / 255 for x in c[:3]]
    h, l, s = colorsys.rgb_to_hls(r, g, b)
    if k < 0:
        h = (h + 0.035 * -k) % 1.0 if 0.1 < h < 0.6 else (h - 0.025 * -k) % 1.0
        l = max(0.05, l * (1 + 0.5 * k))
        s = min(1, s * (1 + 0.15 * -k))
    else:
        h = (h - 0.02 * k) % 1.0 if 0.15 < h < 0.6 else h
        l = min(0.97, l + (1 - l) * 0.5 * k)
        s = s * (1 - 0.15 * k)
    r, g, b = colorsys.hls_to_rgb(h, l, s)
    return (int(r * 255), int(g * 255), int(b * 255), 255)


def ramp(c):
    c = hexc(c) if isinstance(c, str) else c
    return [shade(c, -0.6), shade(c, -0.28), tuple(c[:3]) + (255,), shade(c, 0.5)]


def hsh(*a):
    v = 7
    for x in a:
        for ch in str(x):
            v = (v * 131 + ord(ch)) % 1000003
    return v


class Cv:
    def __init__(self):
        self.p = [[None] * 32 for _ in range(32)]   # (color) или None
        self.mask = [[False] * 32 for _ in range(32)]

    def shape(self, fn, rp, light=(-0.55, -0.7), bands=(0.5, 0.05, -0.45), spec=True):
        """fn(x,y)->None или (nx,ny): нормаль точки; цвет — по освещённости в 4 тонах"""
        for y in range(32):
            for x in range(32):
                n = fn(x + 0.5, y + 0.5)
                if n is None:
                    continue
                nx, ny = n
                d = nx * light[0] + ny * light[1]
                lvl = 3 if d > bands[0] else (2 if d > bands[1] else (1 if d > bands[2] else 0))
                col = rp[lvl]
                if spec and d > 0.82:
                    col = shade(rp[3], 0.7)
                self.p[y][x] = col
                self.mask[y][x] = True

    def put(self, x, y, c, only_inside=False):
        if 0 <= x < 32 and 0 <= y < 32 and (not only_inside or self.mask[int(y)][int(x)]):
            self.p[int(y)][int(x)] = c if len(c) == 4 else tuple(c) + (255,)
            self.mask[int(y)][int(x)] = True

    def px(self, x, y):
        return self.p[y][x] if 0 <= x < 32 and 0 <= y < 32 else None

    def done(self):
        im = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
        q = im.load()
        for y in range(32):
            for x in range(32):
                if self.p[y][x] is not None:
                    q[x, y] = self.p[y][x]
        for y in range(32):
            for x in range(32):
                if self.p[y][x] is None:
                    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                        nx, ny = x + dx, y + dy
                        if 0 <= nx < 32 and 0 <= ny < 32 and self.p[ny][nx] is not None:
                            q[x, y] = OUTLINE
                            break
        return im


def ell(cx, cy, rx, ry):
    def fn(x, y):
        dx, dy = (x - cx) / rx, (y - cy) / ry
        d = dx * dx + dy * dy
        if d > 1:
            return None
        return (dx, dy)
    return fn


def rect(x0, y0, x1, y1, round_n=0.0):
    def fn(x, y):
        if x < x0 or x > x1 or y < y0 or y > y1:
            return None
        w, h = (x1 - x0) / 2, (y1 - y0) / 2
        return ((x - (x0 + x1) / 2) / w * 0.8 + round_n, (y - (y0 + y1) / 2) / h * 0.8)
    return fn


def capsule(x0, y0, x1, y1, r):
    def fn(x, y):
        vx, vy = x1 - x0, y1 - y0
        L = vx * vx + vy * vy
        t = 0 if L == 0 else max(0, min(1, ((x - x0) * vx + (y - y0) * vy) / L))
        px, py = x0 + vx * t, y0 + vy * t
        dx, dy = x - px, y - py
        d = math.hypot(dx, dy)
        if d > r:
            return None
        return (dx / r, dy / r)
    return fn


def poly(pts):
    def fn(x, y):
        inside = False
        n = len(pts)
        j = n - 1
        for i in range(n):
            xi, yi = pts[i]
            xj, yj = pts[j]
            if (yi > y) != (yj > y) and x < (xj - xi) * (y - yi) / (yj - yi + 1e-9) + xi:
                inside = not inside
            j = i
        if not inside:
            return None
        cx = sum(p[0] for p in pts) / n
        cy = sum(p[1] for p in pts) / n
        return ((x - cx) / 10.0, (y - cy) / 10.0)
    return fn


def union(*fns):
    def fn(x, y):
        for f_ in fns:
            r = f_(x, y)
            if r is not None:
                return r
        return None
    return fn


def dots(cv, rp_col, n, seed, box, only_inside=True, size=1):
    x0, y0, x1, y1 = box
    k = 0
    tries = 0
    while k < n and tries < 200:
        tries += 1
        h = hsh(seed, tries)
        x = x0 + h % max(1, x1 - x0)
        y = y0 + (h // 37) % max(1, y1 - y0)
        if cv.mask[y][x] or not only_inside:
            for dx in range(size):
                for dy in range(size):
                    cv.put(x + dx, y + dy, rp_col, only_inside)
            k += 1


def stem(cv, x, y, h, col=(90, 58, 30)):
    for i in range(h):
        cv.put(x, y - i, col + (255,))


def leaf(cv, x, y, col, big=1):
    rp = ramp(col)
    cv.shape(ell(x, y, 3.2 * big, 1.8 * big), rp, spec=False)


def draw(shape, cols, seed):
    cv = Cv()
    c0 = cols[0]
    r0 = ramp(c0)
    r1 = ramp(cols[1]) if len(cols) > 1 else None
    r2 = ramp(cols[2]) if len(cols) > 2 else None
    S = shape
    if S == "ball":
        cv.shape(ell(16, 18, 9.5, 9.0), r0)
        cv.put(16, 8, shade((60, 40, 20), -0.2))
        stem(cv, 16, 9, 3)
        leaf(cv, 20, 7, cols[1] if len(cols) > 1 else "5a9a3a")
        # нижнее углубление
        cv.put(16, 9, shade(hexc(c0), -0.7))
    elif S == "cherries":
        cv.shape(capsule(16, 5, 11, 20, 0.7), ramp("5a8a3a"), spec=False)
        cv.shape(capsule(16, 5, 21, 20, 0.7), ramp("5a8a3a"), spec=False)
        cv.shape(ell(11, 21, 5.5, 5.5), r0)
        cv.shape(ell(21, 21, 5.5, 5.5), r0)
        leaf(cv, 19, 5, cols[1], 1)
    elif S == "cluster":
        pos = [(11, 11), (19, 10), (15, 17), (9, 19), (22, 18), (14, 24), (20, 24)]
        for (px_, py_) in pos:
            cv.shape(ell(px_, py_, 4.4, 4.4), r0)
        leaf(cv, 16, 5, "5a9a3a", 1)
        stem(cv, 16, 8, 3, (70, 90, 40))
    elif S == "acorn":
        cv.shape(ell(16, 20, 6.5, 7.5), r0)
        cv.shape(ell(16, 12, 8.0, 5.0), r1)
        for i in range(8):
            cv.put(9 + i * 2, 12 + (i % 2), shade(hexc(cols[1]), -0.6), True)
        stem(cv, 16, 7, 3)
    elif S == "nut":
        cv.shape(ell(16, 18, 7.5, 8.5), r0)
        cv.put(14, 12, shade(hexc(c0), 0.9))
        for i in range(10):
            cv.put(15, 10 + i, shade(hexc(c0), -0.5), True)
    elif S == "walnut":
        cv.shape(ell(16, 17, 10.0, 8.5), r0)
        for i in range(14):
            cv.put(16, 9 + i, shade(hexc(c0), -0.7), True)
        dots(cv, shade(hexc(c0), -0.5), 10, seed, (8, 10, 24, 24))
    elif S == "sprig":
        cv.shape(capsule(16, 28, 16, 6, 0.9), ramp("6a4a2a"), spec=False)
        for i in range(5):
            y = 24 - i * 4
            cv.shape(capsule(16, y, 8 + i, y - 4, 1.8), r0)
            cv.shape(capsule(16, y, 24 - i, y - 4, 1.8), r0)
    elif S == "pear":
        cv.shape(union(ell(16, 22, 8.5, 7.5), ell(16, 12, 5.5, 7.0)), r0)
        stem(cv, 16, 6, 3)
        leaf(cv, 20, 6, cols[1] if len(cols) > 1 else "5a9a3a")
    elif S == "lemon":
        cv.shape(ell(16, 17, 11, 8), r0)
        cv.shape(ell(6, 17, 2.5, 2.5), r0)
        cv.shape(ell(26, 17, 2.5, 2.5), r0)
    elif S == "melon":
        cv.shape(poly([(3, 9), (29, 9), (16, 28)]), ramp(cols[0]))
        cv.shape(poly([(3, 9), (29, 9), (27, 12), (5, 12)]), ramp("f0f0c8"), spec=False)
        cv.shape(poly([(3, 9), (29, 9), (28, 10.5), (4, 10.5)]), ramp(cols[1]), spec=False)
        for (x, y) in ((11, 15), (16, 14), (21, 15), (14, 19), (18, 19)):
            cv.put(x, y, (30, 20, 20, 255))
            cv.put(x, y + 1, (30, 20, 20, 255))
    elif S == "coconut":
        cv.shape(ell(16, 17, 10, 10), r0)
        dots(cv, shade(hexc(c0), -0.7), 14, seed, (7, 8, 25, 26))
        cv.shape(ell(12, 12, 1.5, 1.5), ramp("2a2018"), spec=False)
        cv.shape(ell(16, 10.5, 1.5, 1.5), ramp("2a2018"), spec=False)
        cv.shape(ell(20, 12, 1.5, 1.5), ramp("2a2018"), spec=False)
    elif S == "long":   # морковь / огурец (по диагонали)
        cv.shape(capsule(25, 6, 8, 25, 3.4), r0)
        if len(cols) > 1 and cols[1] == "4a9a3a" and c0 == "f08a20":
            for i in range(3):
                cv.shape(capsule(26, 6, 22 + i * 3, 1 + i, 1.3), ramp(cols[1]), spec=False)
        for i in range(4):
            cv.put(14 + i * 3, 19 - i * 4, shade(hexc(c0), -0.5), True)
    elif S == "potato":
        cv.shape(ell(16, 18, 11, 8.5), r0)
        dots(cv, shade(hexc(c0), -0.6), 6, seed, (8, 12, 24, 24))
    elif S == "cabbage":
        cv.shape(ell(16, 17, 11, 10), r0)
        cv.shape(ell(16, 18, 7, 7), ramp("a8d878"), spec=False)
        for i in range(10):
            cv.put(9 + i, 17 + int(3 * math.sin(i * 0.8)), shade(hexc(c0), -0.5), True)
        for i in range(8):
            cv.put(16 + int(3 * math.sin(i * 0.9)), 8 + i, shade(hexc(c0), -0.5), True)
    elif S == "onion":   # лук / свёкла / редис
        cv.shape(union(ell(16, 19, 9.0, 8.0), ell(16, 11, 4.0, 5.5)), r0)
        stem(cv, 16, 6, 4, (230, 210, 150))
        if len(cols) > 1:
            cv.shape(capsule(16, 6, 12, 1, 1.3), ramp(cols[1]), spec=False)
            cv.shape(capsule(16, 6, 20, 1, 1.3), ramp(cols[1]), spec=False)
        cv.shape(capsule(16, 27, 15, 30, 0.6), ramp("f0e8d0"), spec=False)
    elif S == "pumpkin":
        cv.shape(ell(10, 18, 7, 9), r0)
        cv.shape(ell(22, 18, 7, 9), r0)
        cv.shape(ell(16, 18, 7, 10), shade_ramp(c0, 0.1))
        stem(cv, 16, 8, 4, (90, 130, 50))
        for xx in (12, 20):
            for i in range(14):
                cv.put(xx, 11 + i, shade(hexc(c0), -0.55), True)
    elif S == "corn":
        cv.shape(capsule(16, 25, 16, 7, 5.2), r0)
        for yy in range(6, 26, 3):
            for xx in range(12, 21, 3):
                cv.put(xx, yy, shade(hexc(c0), -0.55), True)
        cv.shape(poly([(7, 28), (16, 10), (11, 28)]), ramp(cols[1]), spec=False)
        cv.shape(poly([(25, 28), (16, 10), (21, 28)]), ramp(cols[1]), spec=False)
    elif S == "pepper":
        cv.shape(union(ell(12, 16, 6.5, 8.5), ell(20, 16, 6.5, 8.5), ell(16, 20, 8, 7)), r0)
        stem(cv, 16, 8, 4, (60, 110, 40))
        cv.shape(ell(16, 7, 4.5, 2.2), ramp(cols[1]), spec=False)
    elif S == "pod":
        cv.shape(capsule(7, 22, 25, 10, 5), r0)
        for i in range(5):
            x = 10 + i * 3.5
            y = 20 - i * 2.0
            cv.shape(ell(x, y, 2.2, 2.2), ramp(shade(hexc(c0), 0.5)[:3]), spec=False)
    elif S == "loaf":
        cv.shape(union(ell(16, 18, 13, 8), rect(5, 18, 27, 24, 0.0)), r0)
        for i in range(3):
            cv.shape(capsule(9 + i * 6, 13, 12 + i * 6, 17, 0.8), ramp(shade(hexc(c0), 0.55)[:3]), spec=False)
    elif S == "baguette":
        cv.shape(capsule(5, 25, 27, 7, 3.8), r0)
        for i in range(4):
            cv.shape(capsule(9 + i * 4.5, 22 - i * 4, 11 + i * 4.5, 18 - i * 4, 0.8), ramp(shade(hexc(c0), 0.55)[:3]), spec=False)
    elif S == "bun":
        cv.shape(union(ell(16, 18, 11, 8.5), ell(16, 22, 11, 5)), r0)
        # спираль корицы
        for t in range(40):
            a = t * 0.45
            r = 1 + t * 0.2
            cv.put(int(16 + math.cos(a) * r), int(18 + math.sin(a) * r * 0.75), hexc(cols[1]) + (255,), True)
    elif S == "pie":
        cv.shape(ell(16, 18, 13, 9.5), ramp(cols[0]))
        cv.shape(ell(16, 17, 9.5, 6.5), ramp(cols[1]) if len(cols) > 1 else r0, spec=False)
        for i in range(-2, 3):
            cv.shape(capsule(8 + i * 3, 12, 20 + i * 3, 23, 0.8), ramp(shade(hexc(c0), 0.4)[:3]), spec=False)
            cv.shape(capsule(24 + i * 3, 12, 12 + i * 3, 23, 0.8), ramp(shade(hexc(c0), 0.4)[:3]), spec=False)
        cv.shape(ell(16, 17, 9.5, 6.5), ramp(cols[1]) if len(cols) > 1 else r0, spec=False)
        # решётка поверх
        for i in range(-3, 4):
            for t in range(10):
                cv.put(int(16 + i * 3 - 4 + t * 0.8), int(12 + t * 1.0), shade(hexc(c0), 0.5), True)
    elif S == "cookie":
        cv.shape(ell(16, 17, 11.5, 10.5), r0)
        dots(cv, hexc(cols[1]) + (255,), 9, seed, (7, 9, 25, 26), True, 2)
    elif S == "gingerman":
        cv.shape(ell(16, 8, 4.5, 4.5), r0)
        cv.shape(rect(11, 12, 21, 23, 0.0), r0)
        cv.shape(capsule(9, 15, 4, 11, 2.3), r0)
        cv.shape(capsule(23, 15, 28, 11, 2.3), r0)
        cv.shape(capsule(13, 23, 11, 28, 2.5), r0)
        cv.shape(capsule(19, 23, 21, 28, 2.5), r0)
        cv.put(14, 8, (250, 250, 240, 255))
        cv.put(18, 8, (250, 250, 240, 255))
        for yy in (15, 18, 21):
            cv.put(16, yy, (250, 250, 240, 255))
    elif S == "croissant":
        cv.shape(capsule(5, 22, 11, 13, 4.0), r0)
        cv.shape(capsule(11, 13, 21, 13, 5.0), r0)
        cv.shape(capsule(21, 13, 27, 22, 4.0), r0)
        for x in (11, 15, 19, 23):
            for t in range(6):
                cv.put(x - 2 + (t // 2), 9 + t, shade(hexc(c0), -0.5), True)
    elif S == "flat":
        cv.shape(ell(16, 18, 13, 8), r0)
        dots(cv, shade(hexc(c0), -0.6), 10, seed, (6, 13, 26, 23), True, 1)
        dots(cv, shade(hexc(c0), 0.6), 6, seed + 3, (6, 13, 26, 23), True, 2)
    elif S == "cake":
        cv.shape(poly([(4, 26), (28, 26), (28, 14), (4, 14)]), ramp("e8c08a"))
        cv.shape(rect(4, 14, 28, 17, 0.0), ramp(cols[0]), spec=False)
        cv.shape(rect(4, 20, 28, 21, 0.0), ramp(cols[0]), spec=False)
        cv.shape(ell(16, 14, 12.5, 3.5), ramp(cols[0]))
        cv.shape(ell(16, 10, 3.5, 3.5), ramp(cols[1]))
        cv.put(16, 6, (70, 120, 50, 255))
    elif S == "muffin":
        cv.shape(poly([(8, 28), (24, 28), (26, 17), (6, 17)]), ramp("c8884a"))
        for xx in (10, 14, 18, 22):
            for yy in range(18, 28):
                cv.put(xx, yy, shade((200, 136, 74), -0.4), True)
        cv.shape(ell(16, 13, 11.5, 8), r0)
        dots(cv, hexc(cols[1]) + (255,), 6, seed, (8, 7, 24, 17), True, 1)
    elif S == "stack":
        for i in range(4):
            cv.shape(ell(16, 22 - i * 4, 12.5, 4.0), ramp(cols[0]))
        cv.shape(ell(16, 10, 9.0, 2.8), ramp(cols[1]), spec=False)
    elif S == "sandwich":
        cv.shape(ell(16, 22, 13, 5), r0)
        cv.shape(rect(5, 16, 27, 19, 0.0), ramp(cols[1]), spec=False)
        cv.shape(rect(6, 14, 26, 16, 0.0), ramp("6ab04a"), spec=False)
        cv.shape(ell(16, 12, 13, 5), r0)
    elif S == "glass":
        cv.shape(poly([(9, 7), (23, 7), (21, 27), (11, 27)]), ramp(cols[1]), light=(-0.7, -0.3))
        cv.shape(poly([(10, 12), (22, 12), (20.5, 26), (11.5, 26)]), r0, light=(-0.7, -0.3))
        for y in range(8, 26):
            cv.put(11, y, (255, 255, 255, 120) if False else shade(hexc(c0), 0.8))
    elif S == "mug":
        cv.shape(rect(7, 9, 22, 27, 0.0), r1 if r1 else r0, light=(-0.7, -0.2))
        cv.shape(rect(8, 12, 21, 26, 0.0), r0, light=(-0.7, -0.2))
        cv.shape(ell(14.5, 10, 7.5, 2.5), ramp(cols[1]), spec=False)
        for t in range(10):
            a = -1.5 + t * 0.32
            cv.put(int(25 + math.cos(a) * 4), int(18 + math.sin(a) * 5), OUTLINE[:3] + (255,))
        cv.shape(capsule(22, 13, 26, 15, 1.2), ramp("a0a0a0"), spec=False)
        cv.shape(capsule(26, 15, 26, 21, 1.2), ramp("a0a0a0"), spec=False)
        cv.shape(capsule(26, 21, 22, 23, 1.2), ramp("a0a0a0"), spec=False)
    elif S == "can":
        cv.shape(rect(9, 6, 23, 27, 0.0), r0, light=(-0.7, -0.2))
        cv.shape(rect(9, 11, 23, 16, 0.0), ramp(cols[1]), spec=False, light=(-0.7, -0.2))
        cv.shape(ell(16, 6, 7, 2.2), ramp("c0c0c0"), spec=False)
        cv.put(16, 5, (240, 240, 240, 255))
    elif S == "jar":
        cv.shape(rect(8, 12, 24, 28, 0.0), r0, light=(-0.7, -0.2))
        cv.shape(rect(9, 7, 23, 12, 0.0), ramp("b0a080" if len(cols) < 2 else cols[1]), spec=False)
        cv.shape(rect(10, 15, 22, 24, 0.0), r1 if r1 else r0, spec=False, light=(-0.7, -0.2))
    elif S == "bowl":
        cv.shape(poly([(4, 15), (28, 15), (24, 27), (8, 27)]), ramp("e8d8c0"), light=(-0.7, -0.4))
        cv.shape(ell(16, 15, 12, 4.0), ramp(cols[0]))
        dots(cv, hexc(cols[1]) + (255,), 6, seed, (8, 13, 24, 17), True, 2)
        for t in range(5):
            cv.put(12 + (t % 2), 5 + t * 2, (255, 255, 255, 150))
            cv.put(19 + ((t + 1) % 2), 3 + t * 2, (255, 255, 255, 150))
    elif S == "cheese":
        cv.shape(poly([(4, 24), (28, 24), (28, 15), (4, 8)]), r0)
        cv.shape(rect(4, 18, 28, 24, 0.0), r0)
        for (x, y) in ((9, 18), (16, 21), (22, 18), (24, 22)):
            cv.shape(ell(x, y, 1.8, 1.8), ramp(shade(hexc(c0), -0.6)[:3]), spec=False)
    elif S == "butter":
        cv.shape(poly([(5, 24), (22, 24), (28, 19), (11, 19)]), r0)
        cv.shape(rect(5, 14, 22, 24, 0.0), r0)
        cv.shape(poly([(5, 14), (22, 14), (28, 9), (11, 9)]), ramp(shade(hexc(c0), 0.5)[:3]), spec=False)
        cv.shape(poly([(22, 14), (28, 9), (28, 19), (22, 24)]), ramp(shade(hexc(c0), -0.3)[:3]), spec=False)
    elif S == "egg":
        cv.shape(ell(16, 17, 8, 10), ramp(cols[0]))
        cv.shape(ell(16, 20, 3.5, 4), ramp(cols[1]), spec=False)
    elif S == "omelet":
        cv.shape(ell(16, 18, 13, 8.5), ramp("c0c0c0"), spec=False)
        cv.shape(poly([(6, 18), (16, 9), (26, 18), (16, 26)]), r0)
        dots(cv, (90, 170, 70, 255), 5, seed, (8, 13, 24, 24), True, 1)
        cv.shape(ell(16, 18, 13, 8.5), ramp("c0c0c0"), spec=False) if False else None
    elif S == "drum":
        cv.shape(capsule(23, 8, 12, 18, 6.0), r0)
        cv.shape(capsule(12, 18, 8, 22, 2.5), ramp("f0e8d0"), spec=False)
        cv.shape(ell(7, 24, 2.4, 2.4), ramp("f0e8d0"), spec=False)
        cv.shape(ell(10, 26, 2.4, 2.4), ramp("f0e8d0"), spec=False)
    elif S == "sausage":
        cv.shape(capsule(6, 22, 25, 11, 4.5), r0)
        for x in (10, 16, 22):
            cv.put(x, 18 - (x - 10) // 2, shade(hexc(c0), -0.5), True)
        cv.put(7, 21, (60, 40, 30, 255))
    elif S == "ham":
        cv.shape(union(ell(14, 16, 11, 9), capsule(20, 22, 26, 27, 2.6)), r0)
        cv.shape(ell(14, 16, 8, 6), ramp(cols[1]), spec=False)
        cv.shape(ell(27, 28, 2.4, 2.4), ramp("f0e8d0"), spec=False)
    elif S == "skewer":
        cv.shape(capsule(4, 27, 28, 5, 0.9), ramp("c8a060"), spec=False)
        for i, (x, y) in enumerate(((10, 21), (15, 16), (20, 11), (24, 7))):
            cv.shape(ell(x, y, 4.2, 4.2), ramp(cols[i % 2]))
    elif S == "jerky":
        cv.shape(poly([(5, 20), (10, 10), (27, 8), (24, 20), (14, 25)]), r0)
        dots(cv, shade(hexc(c0), 0.5), 6, seed, (8, 11, 24, 22), True, 1)
    elif S == "fishdry":
        cv.shape(union(ell(14, 16, 11, 5.5), poly([(23, 16), (30, 9), (30, 23)])), r0)
        cv.put(8, 15, (20, 20, 20, 255))
        for t in range(6):
            cv.put(12 + t, 14 + t % 2, shade(hexc(c0), -0.45), True)
        cv.shape(capsule(14, 2, 14, 10, 0.6), ramp("a08050"), spec=False)
    elif S == "fish":
        cv.shape(union(ell(14, 17, 11, 6.5), poly([(23, 17), (30, 10), (30, 24)])), r0)
        cv.shape(ell(14, 20, 8, 2.8), ramp(cols[1]), spec=False)
        cv.put(7, 15, (20, 20, 20, 255))
        for t in range(5):
            cv.put(14 + t * 2, 12 + (t % 2), shade(hexc(c0), -0.5), True)
        cv.shape(ell(24, 26, 4, 2.6), ramp("f0d830"), spec=False)
    elif S == "roll":
        cv.shape(ell(16, 18, 11, 8.5), ramp("1e2a22"))
        cv.shape(ell(16, 17, 9.0, 7.0), ramp(cols[0]), spec=False)
        cv.shape(ell(16, 17, 4.2, 3.4), ramp(cols[1]), spec=False)
    elif S == "salad":
        for i, (x, y) in enumerate(((10, 20), (16, 16), (22, 21), (14, 12), (20, 12))):
            cv.shape(ell(x, y, 5.2, 3.4), ramp(cols[i % 2]))
        dots(cv, (240, 240, 220, 255), 6, seed, (6, 9, 26, 24), True, 1)
    elif S == "pudding":
        cv.shape(poly([(8, 28), (24, 28), (26, 14), (6, 14)]), r0)
        cv.shape(ell(16, 14, 10, 3.5), ramp(cols[1]), spec=False)
        cv.shape(ell(16, 9, 3.5, 3.0), ramp("f0f8ff"))
    elif S == "mush":
        cv.shape(ell(10, 17, 5.5, 5.5), r0)
        cv.shape(ell(20, 14, 6, 6), r0)
        cv.shape(ell(15, 22, 6, 4.5), r0)
        dots(cv, shade(hexc(c0), 0.6), 6, seed, (5, 9, 26, 26), True, 1)
    elif S == "mochi":
        cv.shape(ell(16, 19, 11, 8.5), r0)
        cv.shape(ell(16, 13, 5.2, 4.0), ramp(cols[1]))
        cv.shape(ell(16, 12, 1.5, 1.5), ramp("6a9a3a"), spec=False)
    elif S == "dango":
        cv.shape(capsule(16, 4, 16, 29, 0.9), ramp("c8a060"), spec=False)
        for i, y in enumerate((9, 17, 25)):
            cv.shape(ell(16, y, 5.2, 4.4), ramp(cols[i]))
    elif S == "onigiri":
        cv.shape(poly([(16, 5), (28, 26), (4, 26)]), r0)
        cv.shape(rect(9, 20, 23, 27, 0.0), ramp(cols[1]), spec=False)
        dots(cv, (230, 230, 220, 255), 5, seed, (10, 10, 22, 20), True, 1)
    elif S == "comb":
        for (x, y) in ((11, 12), (21, 12), (16, 18), (8, 20), (24, 20), (11, 26), (21, 26)):
            pts = [(x + 5 * math.cos(math.radians(a + 30)), y + 5 * math.sin(math.radians(a + 30))) for a in range(0, 360, 60)]
            cv.shape(poly(pts), r0)
            cv.shape(ell(x, y, 2.4, 2.4), ramp(cols[1]), spec=False)
    elif S == "bugcandy":
        cv.shape(ell(16, 17, 12, 10), ramp("d8982a"))
        cv.shape(ell(16, 18, 5, 6.5), ramp(cols[1]), spec=False)
        for (x, y) in ((13, 22), (19, 22), (11, 17), (21, 17), (12, 13), (20, 13)):
            cv.put(x, y, (50, 36, 24, 255))
        cv.put(14, 11, (255, 255, 255, 200))
    elif S == "bar":
        cv.shape(rect(6, 9, 26, 26, 0.0), r0)
        for x in (12, 17, 22):
            for y in range(9, 27):
                cv.put(x, y, shade(hexc(c0), -0.55), True)
        for y in (14, 20):
            for x in range(6, 27):
                cv.put(x, y, shade(hexc(c0), -0.55), True)
        cv.shape(rect(6, 24, 26, 30, 0.0), ramp(cols[1]), spec=False)
    elif S == "lolly":
        cv.shape(capsule(16, 18, 9, 29, 0.9), ramp("f0e8d0"), spec=False)
        cv.shape(ell(16, 12, 9, 9), r0)
        for t in range(40):
            a = t * 0.5
            r = 1 + t * 0.2
            cv.put(int(16 + math.cos(a) * r), int(12 + math.sin(a) * r), hexc(cols[1]) + (255,), True)
    elif S == "toffee":
        cv.shape(ell(16, 16, 7.5, 5.5), r0)
        cv.shape(poly([(8, 16), (2, 10), (2, 22)]), ramp(cols[1]), spec=False)
        cv.shape(poly([(24, 16), (30, 10), (30, 22)]), ramp(cols[1]), spec=False)
    else:
        cv.shape(ell(16, 16, 9, 9), r0)
    return cv.done()


def shade_ramp(c, k):
    return ramp(shade(hexc(c), k)[:3])


def build_icons():
    os.makedirs(ART, exist_ok=True)
    for (i, n, k, h, j, p, shape, cols, src, desc) in F:
        im = draw(shape, cols, hsh(i))
        im.save(os.path.join(ART, "food_%s.png" % i))


def sheet():
    cols = 14
    rows = (len(F) + cols - 1) // cols
    sh = Image.new("RGBA", (cols * 40, rows * 40), (214, 190, 150, 255))
    for idx, (i, *_rest) in enumerate(F):
        im = Image.open(os.path.join(ART, "food_%s.png" % i))
        sh.alpha_composite(im, ((idx % cols) * 40 + 4, (idx // cols) * 40 + 4))
    sh = sh.resize((sh.width * 3, sh.height * 3), Image.NEAREST)
    os.makedirs(os.path.join(GAME, "screenshots"), exist_ok=True)
    sh.save(os.path.join(GAME, "screenshots", "v17_food.png"))


def q(s):
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


def write_gd():
    out = []
    out.append("extends RefCounted\n## Еда v17 (СГЕНЕРИРОВАНО tools/food_design.py — правь там и запускай с --write).\n"
               "## Каждая еда — предмет в сумке с id \"food_<id>\". Есть: ПКМ в сумке или в руки (панель 1-8) и ЛКМ.\n\n")
    out.append("const KINDS: Dictionary = {" + ", ".join('%s: %s' % (q(a), q(b)) for a, b in KINDS.items()) + "}\n")
    out.append("const ORDER: Array = [" + ", ".join(q(x) for x in ORDER) + "]\n\n")
    out.append("# id: [название, вид, сытность, питьё (сочность), цена, где взять, описание]\n")
    out.append("const DATA: Dictionary = {\n")
    for (i, n, k, h, j, p, shape, cols, src, desc) in F:
        out.append("\t%s: [%s, %s, %s, %s, %d, %s, %s],\n" % (q(i), q(n), q(k), h, j, p, q(src), q(desc)))
    out.append("}\n\n")
    out.append("# Рецепты кухни: [что нужно] -> блюдо. Готовка — на костре (E): берёт первый рецепт, для которого всё есть в сумке.\n")
    out.append("const RECIPES: Array = [\n")
    for need, res, _ in RECIPES:
        out.append("\t[[" + ", ".join(q(x) for x in need) + "], " + q(res) + "],\n")
    out.append("]\n")
    out.append(TAIL)
    with open(os.path.join(GAME, "food_db.gd"), "w", encoding="utf-8", newline="\n") as fh:
        fh.write("".join(out))


TAIL = '''

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
'''

if __name__ == "__main__":
    if "--write" in sys.argv:
        write_gd()
        build_icons()
        sheet()
        print("еды:", len(F), "рецептов:", len(RECIPES))
    else:
        print("python tools/food_design.py --write")

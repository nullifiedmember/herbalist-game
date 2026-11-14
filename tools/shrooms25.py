"""v25: 58 новых грибов «Лесного травника». Значки 24x24 (как старые shroom_*.png) + shrooms25_db.gd.
Рисует тем же движком, что звери (fauna25.Canvas: объём от света, контур, линии между частями).
Запуск из папки game:  python tools/shrooms25.py   -> art/shroom_<id>.png, shrooms25_db.gd, screenshots/shrooms25.png
"""
import os, sys, math
import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from fauna25 import Canvas, ramp, spots, stripes, combo, belly  # noqa: E402

ART = os.path.join(HERE, "..", "art")
SH = os.path.join(HERE, "..", "..", "screenshots")

# Биомы: 1 луг, 2 паучья чаща, 3 готика, 4 рыцари, 5 эльфы, 6 маги, 7 орки, 8 дворфы, 9 кошки, 10 единороги,
# 11 гроты, 12 берёзы, 13 тайга, 14 осень, 15 болото, 16 поля, 17 Сакураяма, 18 побережье
# id: имя, форма, цвета (шляпка, ножка, пластинки/узор), биомы, шанс, часы, цена, сытость, свойства, условие
S = [
    ("oyster", "Вёшенка", "shelf", ("a8a4a0", "e8e4dc", "f0ece4"), [12, 14], 0.4, [0, 24], 7, 0.3, {"Исцеление": 1, "Свежесть": 1}, "растёт ярусами на старых берёзах и дубах"),
    ("honey_fungus", "Опёнок осенний", "cluster", ("c09050", "f0e0c0", "e8d8b0"), [14, 12], 0.45, [0, 24], 6, 0.3, {"Сила": 1, "Тепло": 1}, "семейками на пнях в осеннем и берёзовом лесу"),
    ("red_bolete", "Подосиновик", "dome", ("d0602a", "e8e0d4", "f0e8d8", "scaly_stem"), [12, 14], 0.35, [0, 24], 11, 0.35, {"Исцеление": 1, "Тепло": 1}, "оранжевая шляпка, под осинами и берёзами"),
    ("slippery_jack", "Маслёнок", "flat", ("8a5a30", "f0e0a0", "f0d870", "ring"), [13], 0.45, [0, 24], 6, 0.3, {"Свежесть": 1, "Покой": 1}, "скользкая шляпка, в соснах после дождя"),
    ("saffron_milk", "Рыжик", "funnel", ("e08a3a", "e8a050", "f0b060", "zones"), [13], 0.35, [0, 24], 10, 0.3, {"Тепло": 2}, "рыжий, с кольцами на шляпке, в хвойном лесу"),
    ("milk_cap", "Груздь", "funnel", ("f0ece0", "f4f0e4", "e8dcc4"), [12], 0.35, [0, 24], 9, 0.35, {"Сила": 1, "Свежесть": 1}, "прячется под листьями в берёзовой роще"),
    ("russula_green", "Сыроежка зелёная", "flat", ("7a9a5a", "f4f2ec", "f4f0e8"), [12, 1], 0.45, [0, 24], 4, 0.25, {"Свежесть": 1}, "в берёзах и на опушках"),
    ("russula_yellow", "Сыроежка жёлтая", "flat", ("e0c040", "f4f2ec", "f4f0e8"), [13, 14], 0.45, [0, 24], 4, 0.25, {"Тепло": 1}, "в соснах и осенних лесах"),
    ("parasol", "Гриб-зонтик", "umbrella", ("c8a882", "e8dcc8", "f4ecdc", "scales"), [1, 16], 0.3, [0, 24], 9, 0.35, {"Сила": 1, "Покой": 1}, "высокий, со шляпкой-зонтом, на лугах и полях"),
    ("puffball", "Дождевик", "puff", ("f0ece0", "e8e0d0", "d8ccb8", "warts"), [1, 16, 9], 0.45, [0, 24], 3, 0.2, {"Свежесть": 1, "Сон": 1}, "белый шарик на лугу; старый пылит облачком"),
    ("giant_puffball", "Гигантский головач", "puff_big", ("f4f0e8", "e8e0d0", "d8ccb8"), [16], 0.12, [0, 24], 18, 0.6, {"Сила": 2, "Исцеление": 1}, "редкий великан полей, с голову размером"),
    ("shaggy_ink", "Навозник белый", "bell", ("ece8e0", "f4f0ea", "3a3438", "shaggy"), [1, 9, 4], 0.35, [5, 14], 5, 0.25, {"Сон": 1, "Тьма": 1}, "лохматый колокольчик; к вечеру растекается чернилами"),
    ("chicken_woods", "Серно-жёлтый трутовик", "shelf", ("f0a030", "f8d860", "f8e070", "zones"), [14], 0.25, [0, 24], 12, 0.4, {"Огонь": 1, "Сила": 1}, "яркие оранжевые полки на старых деревьях осенью"),
    ("tinder", "Трутовик", "shelf", ("8a6a4a", "c8b090", "d8c8a8", "zones"), [12, 13], 0.4, [0, 24], 5, 0.0, {"Огонь": 2}, "жёсткий, как копыто; в старину им разжигали огонь"),
    ("lions_mane", "Ежовик гребенчатый", "mane", ("f4f0e8", "e8e0d0", "ffffff"), [14], 0.1, [0, 24], 32, 0.4, {"Исцеление": 2, "Чары": 1}, "белая «борода» на дубах; встречается очень редко"),
    ("coral", "Рогатик", "coral", ("f0c050", "f8d880", "f8e090"), [13], 0.3, [0, 24], 8, 0.25, {"Свет": 1, "Свежесть": 1}, "жёлтые веточки-кораллы во мху тайги"),
    ("truffle_black", "Чёрный трюфель", "truffle", ("2a2228", "3a3036", "5a4a50"), [14], 0.08, [0, 24], 60, 0.4, {"Чары": 2, "Сила": 1}, "под землёй у дубов; виден только кончик"),
    ("death_cap", "Бледная поганка", "dome", ("b8c098", "f0f0e8", "f4f4ec", "ring_volva"), [12, 14], 0.25, [0, 24], 2, -0.6, {"Тьма": 3}, "смертельно ядовита! только для тёмных зелий"),
    ("panther", "Пантерный мухомор", "dome", ("8a6a4a", "f0ece4", "f4f0e8", "spots_white"), [3, 13], 0.25, [0, 24], 5, -0.4, {"Тьма": 2, "Чары": 1}, "ядовитый, в коричневых пятнышках; Сумеречье и тайга"),
    ("royal_agaric", "Королевский мухомор", "dome", ("c8783a", "f0e8d0", "f4ecd8", "spots_yellow"), [13], 0.15, [0, 24], 9, -0.3, {"Жгучесть": 1, "Чары": 2}, "золотисто-рыжий, редкий, в хвойной тайге"),
    ("fairy_ring", "Луговой опёнок", "cluster_small", ("c8a070", "e8d8c0", "e8dcc8"), [1], 0.45, [0, 24], 5, 0.25, {"Чары": 1, "Покой": 1}, "растёт кругами — «ведьмины кольца» на лугах"),
    ("amethyst", "Лаковица аметистовая", "dome_small", ("9a5ac8", "b080d8", "c898e8"), [13, 5], 0.35, [0, 24], 8, 0.2, {"Чары": 1, "Покой": 1}, "фиолетовый малыш во мху; эльфийский лес и тайга"),
    ("velvet_shank", "Зимний опёнок", "cluster", ("e08a30", "6a4a30", "f0c080"), [15], 0.4, [0, 24], 6, 0.25, {"Тепло": 1, "Холод": 1}, "оранжевые семейки на ивах у болота"),
    ("bog_bolete", "Болотный подберёзовик", "dome", ("c8b498", "f0ece4", "f0ece0", "scaly_stem"), [15], 0.4, [0, 24], 6, 0.3, {"Свежесть": 1, "Сон": 1}, "светлая шляпка, на кочках у болотных берёз"),
    ("cauliflower", "Спарассис курчавый", "cauli", ("e8d8a8", "f0e4c0", "f8f0d8"), [13], 0.12, [0, 24], 24, 0.45, {"Исцеление": 1, "Покой": 1}, "кудрявый шар у подножия сосен — грибная капуста"),
    ("jelly_ear", "Иудино ухо", "ear", ("7a4a3a", "9a6050", "b07a68"), [15, 14], 0.4, [0, 24], 5, 0.15, {"Холод": 1, "Исцеление": 1}, "мягкое «ушко» на ветках бузины"),
    ("ghost_cap", "Призрачная шляпка", "bell_glow", ("e0e8f0", "f0f4f8", "c8d8f0"), [3], 0.35, [20, 5], 20, 0.15, {"Тьма": 1, "Свет": 1, "Чары": 1}, "прозрачная, светится ночью в Сумеречье"),
    ("bat_cap", "Мышиный зонтик", "bat", ("3a2a4a", "6a5a7a", "8a6aa0"), [3, 2], 0.3, [18, 6], 14, 0.1, {"Тьма": 2, "Сон": 1}, "шляпка-крылышки, вылезает к ночи"),
    ("bloodfoot", "Кровоножка", "dome_small", ("a02a3a", "c84a4a", "e07070"), [3], 0.35, [0, 24], 9, 0.1, {"Сила": 1, "Жгучесть": 1}, "если надломить — сочится алым соком"),
    ("spider_veil", "Паучья вуаль", "veil", ("8a6aa8", "d8d0e0", "f0eaf4"), [2], 0.4, [0, 24], 11, 0.2, {"Покой": 1, "Чары": 1}, "фиолетовая, под шляпкой — паутинное покрывало"),
    ("silk_puff", "Шёлковый дождевик", "puff", ("ece8f0", "e0d8e8", "c8c0d8", "silk"), [2], 0.35, [0, 24], 8, 0.15, {"Сон": 2}, "белый шарик, обмотанный шёлком паучат"),
    ("crystal_cap", "Хрустальная шляпка", "crystal", ("80c8e8", "d8f0f8", "e8f8ff"), [11], 0.3, [0, 24], 28, 0.1, {"Холод": 1, "Свет": 1, "Чары": 1}, "прозрачная, как лёд; растёт в гротах между кристаллами"),
    ("lantern", "Гриб-фонарик", "lantern", ("f0902a", "f8d8a0", "fff0a0"), [11], 0.35, [19, 6], 16, 0.15, {"Свет": 2, "Тепло": 1}, "светится оранжевым ночью в гротах"),
    ("cave_coral", "Пещерный рогатик", "coral", ("a8b8d8", "c8d8f0", "e0ecff"), [11], 0.35, [0, 24], 10, 0.1, {"Холод": 1, "Свет": 1}, "бледно-голубые веточки на стенах гротов"),
    ("rainbow_cap", "Радужный гриб", "dome", ("e080c0", "f8f0f8", "f8e8f8", "rainbow"), [10], 0.25, [0, 24], 30, 0.2, {"Свет": 2, "Чары": 2}, "переливается всеми цветами; только в розовом лесу"),
    ("candy_cap", "Леденцовый гриб", "dome", ("f0a0c8", "fff0f8", "fff4f8", "swirl"), [10], 0.35, [0, 24], 12, 0.3, {"Покой": 1, "Свежесть": 1}, "пахнет карамелью; розовый лес"),
    ("cloud_puff", "Облачный дождевик", "puff", ("f4f8ff", "e8f0fc", "d8e4f8", "cloud"), [10], 0.3, [6, 18], 14, 0.15, {"Покой": 2, "Свет": 1}, "мягкий, как облачко; розовый лес днём"),
    ("heart_cap", "Сердечный гриб", "heart", ("e04a6a", "f8e8ec", "f8a0b8"), [10], 0.1, [0, 24], 45, 0.2, {"Исцеление": 2, "Чары": 2}, "шляпка-сердечко; дарят тем, кого любят"),
    ("star_puff", "Звёздный дождевик", "earthstar", ("b0a090", "d8c8b8", "8a7a6a"), [6], 0.3, [0, 24], 15, 0.1, {"Свет": 1, "Чары": 2}, "лучи звезды раскрываются в долине магов"),
    ("mana_cap", "Гриб маны", "tall_glow", ("4a7ae8", "c8d8ff", "a0c0ff"), [6], 0.25, [20, 4], 26, 0.15, {"Чары": 3}, "синий, высокий, светится ночью; маги варят из него ману"),
    ("sage_cap", "Гриб мудреца", "dome", ("8a9a7a", "e8e4d4", "f0ece0", "dots"), [5], 0.3, [0, 24], 14, 0.25, {"Покой": 2, "Чары": 1}, "серо-зелёный, в эльфийском лесу; проясняет мысли"),
    ("leaf_shelf", "Листовой трутовик", "shelf", ("6aa060", "c8e0b0", "d8f0c8", "zones"), [5], 0.3, [0, 24], 12, 0.2, {"Свежесть": 2}, "зелёные полки на эльфийских деревьях"),
    ("dwarf_beard", "Борода гнома", "mane", ("a07a4a", "c09a68", "d8b888"), [8], 0.3, [0, 24], 13, 0.3, {"Сила": 2}, "рыжая «борода» на брёвнах у шахт дворфов"),
    ("iron_cap", "Железная шляпка", "helm", ("8a8e98", "b8bcc4", "d8dce4"), [8], 0.3, [0, 24], 15, 0.15, {"Сила": 1, "Холод": 1}, "твёрдая, как железо; растёт у рудных жил"),
    ("ember_cap", "Угольный гриб", "dome", ("3a2a2a", "6a5a50", "f07a2a", "cracks"), [7, 11], 0.3, [0, 24], 16, 0.1, {"Огонь": 2, "Жгучесть": 1}, "чёрный, с тлеющими трещинками; степь и гроты"),
    ("steppe_morel", "Степной сморчок", "morel", ("b8946a", "e8dcc4", "8a6a4a"), [7], 0.3, [5, 11], 12, 0.3, {"Сила": 1, "Тепло": 1}, "сухой степной сморчок, только утром"),
    ("shiitake", "Шиитаке", "flat", ("7a4a2e", "f0e4d0", "f0e4d0", "flecks"), [17], 0.4, [0, 24], 9, 0.35, {"Сила": 1, "Исцеление": 1}, "на дубовых брёвнах в Сакураяме"),
    ("enoki", "Эноки", "enoki", ("f4ecd4", "f8f4e4", "f0e8d0"), [17], 0.4, [0, 24], 7, 0.25, {"Свежесть": 1, "Холод": 1}, "тонкие белые ножки пучком"),
    ("matsutake", "Мацутакэ", "dome", ("8a5a3a", "e8dcc8", "f0e8d8", "scales"), [17], 0.1, [0, 24], 55, 0.45, {"Сила": 1, "Тепло": 1, "Чары": 1}, "редкий сосновый гриб, драгоценный подарок"),
    ("sakura_cap", "Сакуровый гриб", "dome_small", ("f0a8c0", "fff0f4", "fff4f8"), [17], 0.35, [0, 24], 10, 0.2, {"Покой": 1, "Свет": 1}, "розовый, под цветущей сакурой"),
    ("sea_cap", "Береговой шампиньон", "dome", ("e8dcc8", "f4ecdc", "a07a6a"), [18], 0.4, [0, 24], 6, 0.35, {"Свежесть": 1, "Сила": 1}, "в песке у дюн на побережье"),
    ("sea_ear", "Морское ушко", "ear", ("c87a5a", "e8a080", "f0b898"), [18], 0.35, [0, 24], 8, 0.15, {"Холод": 1, "Свежесть": 1}, "на выброшенных морем корягах"),
    ("cat_cap", "Кошачья шляпка", "cat", ("e0a060", "f8f0e0", "f8f0e4"), [9], 0.35, [0, 24], 12, 0.3, {"Покой": 2}, "шляпка с ушками! растёт только в Мурлыкино"),
    ("knight_helm", "Рыцарский шлем", "helm", ("a8acb8", "e0dcd0", "e8e4d8"), [4], 0.35, [0, 24], 10, 0.3, {"Сила": 2}, "серая шляпка-шлем у стен Кронхольма"),
    ("crown_cap", "Королевский венец", "crown", ("e8c040", "f8f0d8", "f8e8a0"), [4], 0.08, [0, 24], 50, 0.3, {"Сила": 1, "Свет": 2, "Чары": 1}, "золотая корона; говорят, вырастает там, где проезжала королева"),
    ("frost_cap", "Морозный гриб", "dome", ("a8d0f0", "e8f4ff", "f0f8ff", "frost"), [13], 0.3, [0, 8], 16, 0.2, {"Холод": 3}, "в инее, только ночью и на рассвете (0-8) в тайге"),
    ("sun_cap", "Солнечный гриб", "dome", ("f0c030", "f8ecc0", "f8f0c8", "rays"), [16], 0.3, [11, 15], 16, 0.3, {"Тепло": 2, "Свет": 1}, "золотой, показывается только в полдень (11-15) на полях"),
]

FOOD_TXT = {}


def shroom(sh, cols, pat=None):
    cv = Canvas(24, 24)
    cap = ramp(cols[0])
    stem = ramp(cols[1])
    gill = ramp(cols[2])
    extra = cols[3] if len(cols) > 3 else ""
    cpat = None
    if extra == "spots_white":
        cpat = spots(3, 7, 0.6, 1.1, ramp("f8f4ec"), (4, 4, 20, 14))
    elif extra == "spots_yellow":
        cpat = spots(5, 7, 0.6, 1.1, ramp("f0e0a0"), (4, 4, 20, 14))
    elif extra == "scales":
        cpat = spots(9, 10, 0.5, 0.9, ramp(cols[0], spread=0.6)[:2] * 3, (4, 4, 20, 14))
    elif extra == "zones":
        cpat = stripes(1.4, 0.14, axis="y", thr=0.6)
    elif extra == "rainbow":
        def cpat(x, y, u, v, lv):
            band = ((x * 0.5 + y * 0.6).astype(int)) % 4
            alts = []
            for i, c in enumerate(["f07090", "f0c050", "70d0a0", "70a0f0"]):
                alts.append(((band == i), ramp(c)))
            return lv, alts
    elif extra == "swirl":
        cpat = stripes(1.1, 0.0, axis="x", thr=0.65, rmp=ramp("fff4fa"))
    elif extra in ("dots", "flecks"):
        cpat = spots(13, 9, 0.4, 0.7, ramp("f0ecdc" if extra == "dots" else "d8b890"), (4, 4, 20, 14))
    elif extra == "cracks":
        cpat = stripes(2.0, 0.0, axis="x", thr=0.86, rmp=ramp("f08a30"))
    elif extra == "frost":
        cpat = spots(17, 9, 0.4, 0.8, ramp("ffffff"), (4, 4, 20, 14))
    elif extra == "rays":
        cpat = stripes(1.6, 0.12, axis="x", thr=0.7)
    elif extra == "shaggy":
        cpat = stripes(1.8, 0.2, axis="y", thr=0.6)
    elif extra == "warts":
        cpat = spots(21, 8, 0.4, 0.7, ramp("ffffff"), (4, 6, 20, 20))
    elif extra == "silk":
        cpat = stripes(1.3, 0.0, axis="y", thr=0.75, rmp=ramp("ffffff"))
    elif extra == "cloud":
        cpat = spots(23, 6, 1.0, 1.6, ramp("ffffff"), (4, 6, 20, 20))
    gy = 21.5
    if sh in ("dome", "flat", "umbrella", "funnel", "dome_small", "bell", "bell_glow", "tall_glow", "veil", "crystal", "lantern", "cat", "helm", "crown", "heart"):
        big = sh not in ("dome_small",)
        sw = 2.4 if big else 1.6
        sh_top = {"dome": 11, "flat": 11, "umbrella": 9, "funnel": 11, "dome_small": 13, "bell": 9, "bell_glow": 10,
                  "tall_glow": 8, "veil": 11, "crystal": 12, "lantern": 11, "cat": 12, "helm": 11, "crown": 12, "heart": 12}[sh]
        cv.limb((12.5, gy - 0.5), (12.0, sh_top + 1), sw + 0.4, sw, stem, sep=True,
                pat=stripes(2.2, 0.15, axis="y", thr=0.6) if extra == "scaly_stem" else None)
        if extra in ("ring", "ring_volva"):
            cv.ell(12.2, sh_top + 4.5, sw + 1.2, 1.0, stem, sep=True)
        if extra == "ring_volva":
            cv.ell(12.5, gy - 0.8, sw + 1.6, 1.6, stem, half="bottom", sep=True)
        if sh == "dome":
            cv.ell(12, sh_top + 0.5, 7.4, 1.6, gill, sep=True)
            cv.ell(12, sh_top, 7.6, 6.2, cap, half="top", pat=cpat)
        elif sh == "dome_small":
            cv.ell(12, sh_top + 0.5, 4.6, 1.2, gill, sep=True)
            cv.ell(12, sh_top, 4.8, 4.2, cap, half="top", pat=cpat)
        elif sh == "flat":
            cv.ell(12, sh_top + 0.8, 8.0, 1.6, gill, sep=True)
            cv.ell(12, sh_top, 8.4, 3.8, cap, half="top", pat=cpat)
        elif sh == "umbrella":
            cv.ell(12, sh_top + 0.6, 9.0, 1.4, gill, sep=True)
            cv.ell(12, sh_top, 9.4, 3.4, cap, half="top", pat=cpat)
            cv.ell(12, sh_top - 2.6, 2.4, 1.8, ramp(cols[0], spread=0.6), sep=False)
        elif sh == "funnel":
            cv.ell(12, sh_top - 0.5, 8.0, 2.6, gill, pat=cpat, sep=True, flat=0.6)
            cv.ell(12, sh_top + 1.2, 7.6, 2.2, cap, half="bottom", sep=True)
        elif sh in ("bell", "bell_glow"):
            cv.ell(12, sh_top + 3.5, 4.8, 8.4, cap, half="top", pat=cpat)
            cv.ell(12, sh_top + 3.4, 4.6, 1.0, gill, sep=True)
        elif sh == "tall_glow":
            cv.ell(12, sh_top + 1.5, 6.2, 5.8, cap, half="top", pat=cpat)
            cv.ell(12, sh_top + 1.6, 6.0, 1.1, gill, sep=True)
        elif sh == "veil":
            cv.ell(12, sh_top, 7.4, 6.0, cap, half="top")
            for i in range(5):
                cv.limb((6 + i * 3, sh_top + 0.5), (10.5 + i * 0.7, sh_top + 5), 0.5, 0.4, ramp("f4f0f8"), sep=False)
        elif sh == "crystal":
            cv.ell(12, sh_top, 7.0, 5.8, cap, half="top")
            cr = ramp("c8f0ff")
            for (dx, h) in ((-3, 7), (1, 9), (4, 6)):
                cv.poly([(12 + dx - 1.4, sh_top - 3), (12 + dx + 1.4, sh_top - 3), (12 + dx + 0.3, sh_top - 3 - h)], cr, (0.4, -0.6, 1), sep=True)
        elif sh == "lantern":
            cv.ell(12, sh_top + 1, 6.4, 6.4, cap, pat=stripes(1.5, 0.0, axis="x", thr=0.7, rmp=gill))
            cv.ell(12, sh_top - 5.5, 2.2, 1.2, ramp("6a4a30"), sep=True)
        elif sh == "cat":
            ec = cap
            cv.poly([(6, sh_top - 3), (9.5, sh_top - 5), (6.5, sh_top - 9.5)], ec, (0, -0.5, 1))
            cv.poly([(18, sh_top - 3), (14.5, sh_top - 5), (17.5, sh_top - 9.5)], ec, (0.3, -0.5, 1))
            cv.ell(12, sh_top + 0.5, 7.2, 1.4, gill, sep=True)
            cv.ell(12, sh_top, 7.4, 6.4, cap, half="top", pat=stripes(1.2, 0.18, axis="x", thr=0.65))
            cv.dot(9, sh_top - 3, (40, 26, 30), 1, 1)
            cv.dot(15, sh_top - 3, (40, 26, 30), 1, 1)
        elif sh == "helm":
            cv.ell(12, sh_top, 7.4, 7.2, cap, half="top")
            cv.ell(12, sh_top + 0.5, 7.2, 1.4, gill, sep=True)
            cv.dot(7, sh_top - 3, (40, 36, 44), 10, 1)
            cv.ell(12, sh_top - 7, 1.4, 1.6, ramp("c84a4a"), sep=True)
        elif sh == "crown":
            cv.ell(12, sh_top + 0.5, 7.2, 1.4, gill, sep=True)
            cv.ell(12, sh_top, 7.4, 5.0, cap, half="top")
            for dx in (-5, -2, 2, 5):
                cv.poly([(12 + dx - 1.4, sh_top - 3), (12 + dx + 1.4, sh_top - 3), (12 + dx, sh_top - 7.5)], cap, (0.3, -0.6, 1))
            cv.dot(11, sh_top - 3, (200, 50, 70), 2, 2)
        elif sh == "heart":
            cv.ell(9.2, sh_top - 2.5, 4.0, 4.0, cap)
            cv.ell(14.8, sh_top - 2.5, 4.0, 4.0, cap, sep=False)
            cv.poly([(5.4, sh_top - 1.5), (18.6, sh_top - 1.5), (12, sh_top + 4.5)], cap, (0, 0.3, 1), sep=False)
            cv.ell(10, sh_top - 4.5, 1.2, 1.0, gill, sep=False)
    elif sh == "cluster" or sh == "cluster_small":
        k = 1.0 if sh == "cluster" else 0.75
        for (dx, top, r) in ((-5, 12, 3.6), (4.5, 10, 4.2), (0, 7, 4.8)):
            x = 12 + dx * k
            t = top + (1 - k) * 6
            cv.limb((x + 0.4, gy - 0.5), (x, t + 1), 1.4 * k + 0.3, 1.2 * k + 0.3, stem, sep=True)
            cv.ell(x, t + 0.4, r * k, 1.0, gill, sep=True)
            cv.ell(x, t, r * k + 0.2, r * k * 0.75, cap, half="top", pat=spots(int(x), 3, 0.4, 0.6, ramp(cols[2]), (x - 4, t - 4, x + 4, t)))
    elif sh in ("puff", "puff_big"):
        r = 6.0 if sh == "puff" else 8.5
        cv.ell(12, gy - r * 0.85, r, r * 0.88, cap, pat=cpat)
        cv.ell(12, gy - 0.8, r * 0.55, 1.2, stem, sep=True)
    elif sh == "shelf":
        bark = ramp("6a5040")
        cv.ell(18.5, 13, 4.2, 9.5, bark, pat=stripes(1.6, 0.18, axis="x", thr=0.5))
        for i, (y, w) in enumerate(((7, 9.0), (12.5, 10.5), (18, 8.0))):
            cv.ell(14.5 - w * 0.25, y + 1.2, w, 1.4, gill, sep=True)
            cv.ell(14.5 - w * 0.25, y, w, 3.0, cap, half="top", pat=cpat)
    elif sh == "mane":
        cv.ell(12, 12, 7.8, 6.6, cap, pat=stripes(2.1, 0.24, axis="x", thr=0.55))
        for i in range(8):
            x = 5.5 + i * 1.9
            cv.limb((x, 15), (x + 0.3, 20 + (i % 3)), 0.9, 0.6, cap, sep=False, shade=-0.1)
    elif sh == "coral":
        for (x0, pts) in ((9, [(9, 21), (8, 16), (5.5, 12), (5, 8)]), (12, [(12, 21), (12.5, 14), (11, 9), (12, 5)]), (15, [(15, 21), (16, 15), (18.5, 11), (19, 7)])):
            cv.chain(pts, 1.6, 0.9, cap, sep=True)
            ex, ey = pts[-1]
            cv.limb((ex, ey), (ex - 1.5, ey - 2.5), 0.8, 0.6, cap, sep=False)
            cv.limb((ex, ey), (ex + 1.5, ey - 2.2), 0.8, 0.6, cap, sep=False)
    elif sh == "truffle":
        soil = ramp("6a4a34")
        cv.ell(12, gy - 1.0, 9.5, 2.6, soil, pat=spots(4, 6, 0.4, 0.8, ramp("4a3424"), (3, 17, 21, 22)))
        cv.ell(12, gy - 4.5, 5.6, 5.0, cap, half="top", pat=spots(7, 14, 0.5, 0.9, ramp(cols[2]), (6, 12, 18, 18)))
    elif sh == "ear":
        bark = ramp("7a6a5a")
        cv.limb((3, 19), (21, 15), 2.6, 2.2, bark)
        cv.ell(11, 12, 6.4, 5.2, cap, rot=-0.3, pat=stripes(1.5, 0.18, axis="y", thr=0.6))
        cv.ell(11.5, 12.5, 3.0, 2.0, gill, rot=-0.3, sep=False)
    elif sh == "earthstar":
        rays = []
        for i in range(8):
            a = i * math.pi / 4 + 0.2
            rays.append((12 + math.cos(a) * 9, gy - 2.5 + math.sin(a) * 2.6))
            rays.append((12 + math.cos(a + 0.39) * 3.4, gy - 2.5 + math.sin(a + 0.39) * 1.6))
        cv.poly(rays, stem, (0, -0.8, 0.6))
        cv.ell(12, gy - 6, 4.4, 4.2, cap)
        cv.dot(11, gy - 10.5, (70, 60, 50), 2, 1)
    elif sh == "morel":
        cv.limb((12.5, gy - 0.5), (12, 12), 2.6, 2.4, stem)
        def honey(x, y, u, v, lv):
            gx = np.floor(x / 2.4 + np.floor(y / 2.2) * 0.5)
            fx = (x / 2.4 + np.floor(y / 2.2) * 0.5) - gx
            fy = (y / 2.2) - np.floor(y / 2.2)
            m = (fx < 0.3) | (fy < 0.3)
            return lv, [(m, ramp(cols[2]))]
        cv.ell(12, 8.5, 4.6, 7.2, cap, pat=honey)
    elif sh == "cauli":
        for (x, y, r) in ((8, 15, 4), (15, 15, 4.2), (11.5, 11, 4.6), (7, 10, 3), (16, 10, 3.2), (12, 17, 4)):
            cv.ell(x, y, r, r * 0.9, cap, pat=stripes(2.4, 0.18, axis="x", thr=0.55))
    elif sh == "enoki":
        for i in range(7):
            x = 7 + i * 1.7
            top = 5 + (i % 3) * 2.5
            cv.limb((12 + (x - 12) * 0.3, gy - 0.5), (x, top + 1), 0.8, 0.7, stem, sep=False)
            cv.ell(x, top, 1.5, 1.2, cap, sep=True)
    elif sh == "bat":
        cv.limb((12.5, gy - 0.5), (12, 12), 2.0, 1.8, stem)
        cv.poly([(3, 9), (7, 7), (9, 9), (12, 5.5), (15, 9), (17, 7), (21, 9), (18, 11), (16, 10), (14, 12), (12, 11), (10, 12), (8, 10), (6, 11)], cap, (0, -0.6, 1))
        cv.dot(10, 8, (240, 210, 90), 1, 1)
        cv.dot(13, 8, (240, 210, 90), 1, 1)
    img = cv.render(noise_seed=3)
    im = Image.fromarray(img, "RGBA")
    # тень на земле
    sh_ = Image.new("RGBA", (24, 24), (0, 0, 0, 0))
    a = np.array(sh_)
    for y in range(21, 24):
        for x in range(24):
            dx = (x + 0.5 - 12.5) / 8.5
            dy = (y + 0.5 - 22.2) / 1.6
            if dx * dx + dy * dy <= 1.0:
                a[y, x] = (20, 24, 30, 70)
    sh_ = Image.fromarray(a, "RGBA")
    sh_.alpha_composite(im)
    return sh_


def main():
    lines = ["extends RefCounted", "## v25: новые грибы (генерирует tools/shrooms25.py — руками не править)", "",
             "const WD = preload(\"res://world_data.gd\")", "", "const SHROOMS: Dictionary = {"]
    props = []
    glow = []
    imgs = []
    for (sid, name, shp, cols, biomes, ch, hours, price, food, pr, need) in S:
        im = shroom(shp, cols)
        im.save(os.path.join(ART, "shroom_%s.png" % sid))
        imgs.append(im)
        lines.append('\t"%s": {"name": "%s", "biomes": [%s], "chance": %.2f, "hours": [%d, %d], "price": %d, "food": %.2f, "need": "%s", "v25": true},' % (
            sid, name, ", ".join(str(b) for b in biomes), ch, hours[0], hours[1], price, food, need))
        props.append('\t"%s": {%s},' % (sid, ", ".join('"%s": %d' % (k, v) for k, v in pr.items())))
        if shp in ("bell_glow", "tall_glow", "lantern", "crystal") or sid in ("ghost_cap", "ember_cap"):
            glow.append(sid)
    lines.append("}")
    lines.append("## свойства для зелий")
    lines.append("const PROPS: Dictionary = {")
    lines += props
    lines.append("}")
    lines.append("## светятся ночью")
    lines.append("const GLOW: Array = [%s]" % ", ".join('"%s"' % g for g in glow))
    open(os.path.join(HERE, "..", "shrooms25_db.gd"), "w", encoding="utf-8", newline="\n").write("\n".join(lines) + "\n")
    n = len(imgs)
    cols_n = 15
    out = Image.new("RGBA", (cols_n * 26, ((n + cols_n - 1) // cols_n) * 26), (96, 128, 104, 255))
    for i, im in enumerate(imgs):
        out.alpha_composite(im, ((i % cols_n) * 26 + 1, (i // cols_n) * 26 + 1))
    out = out.resize((out.width * 4, out.height * 4), Image.NEAREST)
    out.save(os.path.join(SH, "shrooms25.png"))
    print("shrooms:", n)


if __name__ == "__main__":
    main()

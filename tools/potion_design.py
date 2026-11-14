# -*- coding: utf-8 -*-
"""Дизайн алхимии «Лесного травника» (v16): свойства, обработки, основы, 120+ зелий.
Проверяет, что каждое зелье можно сварить (ищет пример рецепта), и пишет game/recipes_db.gd.
Запуск: python tools/potion_design.py  (из папки game)
"""
import itertools, random, json, sys, os
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
GAME = os.path.dirname(HERE)

# ---------------------------------------------------------------- свойства
PROPS = ["Свежесть", "Покой", "Сон", "Тепло", "Исцеление", "Сила", "Жгучесть", "Холод", "Огонь", "Свет", "Тьма", "Чары"]
CODE = {"F": 0, "P": 1, "S": 2, "T": 3, "H": 4, "M": 5, "Z": 6, "C": 7, "O": 8, "L": 9, "D": 10, "A": 11}
RARE_PROPS = {7, 8, 9, 10, 11}
NP = len(PROPS)
ROMAN = {"I": 1, "II": 2, "III": 3}


def vec(s):
    """'M2F2' -> вектор"""
    v = [0] * NP
    i = 0
    while i < len(s):
        k = s[i]; i += 1
        n = ""
        while i < len(s) and s[i].isdigit():
            n += s[i]; i += 1
        v[CODE[k]] += int(n or 1)
    return v


# ---------------------------------------------------------------- травы (из herbs_db.gd) + новые свойства
def read_herbs():
    import re
    s = open(os.path.join(GAME, "herbs_db.gd"), encoding="utf8").read()
    out = {}
    for m in re.finditer(r'"(\w+)": \{"name": "([^"]+)".*?"props": (\[\[.*?\]\])', s):
        props = json.loads(m.group(3))
        v = [0] * NP
        for p, lv in props:
            v[PROPS.index(p)] += ROMAN[lv]
        out[m.group(1)] = v
    return out


HERBS = read_herbs()
# редкие свойства у старых трав (дописываются к их свойствам)
EXTRA = {
    "glowmoss": "L", "moonbloom": "AL", "unicorn_mane": "L2", "crystal_root": "A2", "star_bell": "A",
    "nightshade": "D2", "mandrake": "DA", "fire_pepper": "O2", "elf_leaf": "A", "ginseng": "L",
    "wormwood": "D", "web_grass": "D", "marsh_tea": "D", "sea_lavender": "C", "cloudberry": "C",
    "lily_valley": "C", "heather": "A", "fern": "D", "poppy": "D", "st_john": "L", "calendula": "L",
    "sundew": "A", "catnip": "A", "shiso": "C", "sea_kale": "C", "club_moss": "O",
}
# новые травы (особые, редкие и мега-редкие)
NEW_HERBS = {
    "fire_lily": ("Огненная лилия", "O3L1", "Лепестки тлеют, как угли, и светятся в темноте. Голой рукой не взять — обожжёт."),
    "frost_lotus": ("Ледяной лотос", "C3P1", "Растёт на студёных озёрах тайги. Тает в тёплых руках, если медлить."),
    "shadow_orchid": ("Теневая орхидея", "D3A1", "Раскрывается только в полной темноте. Свет факела — и она прячется."),
    "sunflower_gold": ("Солнечник", "L3T1", "Золотой цветок полей. Смотрит на солнце и в полдень сияет сам."),
    "dragon_root": ("Драконий корень", "O2M2", "Корень в чешуйках, тёплый на ощупь. Сидит глубоко — без лопаты не достать."),
    "void_bloom": ("Бездноцвет", "D3A2Z1", "Чёрный цветок со дна моря. Глядит в ответ."),
    "phoenix_grass": ("Перо феникса", "O3H3L2", "Огненная трава, что сгорает и вырастает из пепла. Видят её раз в жизни."),
    "world_leaf": ("Лист Великого древа", "H3A3F1", "Падает с древа эльфов раз в сто лет. Тёплый и звенящий."),
}
for k, (nm, pv, ds) in NEW_HERBS.items():
    HERBS[k] = vec(pv)
for k, add in EXTRA.items():
    HERBS[k] = [a + b for a, b in zip(HERBS[k], vec(add))]
# грибы — тоже в котёл
SHROOMS = {
    "porcini": "M1H1", "birch_bolete": "H1F1", "chanterelle": "T1F1", "fly_agaric": "A1D1Z1", "glow_cap": "L1F1",
    "moon_shroom": "A2L2S1", "swamp_honey": "S1D1", "web_shroom": "D1P1", "blood_russula": "D2M1", "elf_star": "A1H2",
    "morel": "M2", "field_champignon": "H1M1",
}
ING = dict(HERBS)
for k, s in SHROOMS.items():
    ING[k] = vec(s)

# ---------------------------------------------------------------- обработки (на столе)
PROCS = ["grind", "cut", "dry", "burn", "soak"]
PROC_NAME = {"grind": "Растереть", "cut": "Нарезать", "dry": "Высушить", "burn": "Обжечь", "soak": "Замочить"}
F, P, S, T, H, M, Z, C, O, L, D, A = range(12)


def proc(v, p):
    v = list(v)
    if p == "grind":  # самое сильное свойство крепче
        i = max(range(NP), key=lambda k: (v[k], -k))
        if v[i] > 0:
            v[i] += 1
    elif p == "cut":  # жгучие волоски срезаны, сок свежий
        v[Z] = 0
        v[F] += 1
    elif p == "dry":  # свежесть уходит в тепло, холод пропадает
        v[T] += v[F]; v[F] = 0; v[C] = 0
    elif p == "burn":  # тепло и жгучесть — в огонь, покой и сон — в тьму, свежесть сгорает
        v[O] += (v[T] + v[Z] + 1) // 2; v[T] = 0; v[Z] = 0
        v[D] += (v[P] + v[S] + 1) // 2; v[P] = 0; v[S] = 0
        v[F] = 0; v[H] //= 2
    elif p == "soak":  # тепло — в холод, жгучесть — в покой, огонь гаснет в свет
        v[C] += v[T]; v[T] = 0
        v[P] += v[Z]; v[Z] = 0
        v[L] += v[O] // 2; v[O] = 0
    return v


def variants(v):
    """все состояния травы: без обработки, 1 обработка, 2 разных подряд"""
    out = {(): v}
    for a in PROCS:
        va = proc(v, a)
        out[(a,)] = va
        for b in PROCS:
            if b != a:
                out[(a, b)] = proc(va, b)
    return out


# ---------------------------------------------------------------- основы и температура
BASES = ["water", "wax", "spirit", "honey", "moon_dew"]
BASE_NAME = {"water": "Вода", "wax": "Воск", "spirit": "Спирт", "honey": "Мёд", "moon_dew": "Лунная роса"}
BASE_KIND = {"water": "чай", "wax": "мазь", "spirit": "настойка", "honey": "сироп", "moon_dew": "эликсир"}
TEMPS = ["cold", "warm", "hot"]
TEMP_NAME = {"cold": "холодная", "warm": "тёплая", "hot": "горячая"}


def finish(v, base, temp):
    v = list(v)
    if base == "water":
        if temp == "cold":
            v[C] += 1; v[T] = max(0, v[T] - 1)
        elif temp == "hot":
            i = max(range(NP), key=lambda k: (v[k], -k))
            if v[i] > 0:
                v[i] += 1
            v[F] = max(0, v[F] - 1)
    if base == "moon_dew":
        v[A] += 1
    return v


# ---------------------------------------------------------------- зелья
# id, название, основа, температура (any/cold/warm/hot — только для воды), нужно, польза, [редкость]
# редкость: 0 обычное, 1 редкое, 2 очень редкое, 3 мега-редкое (легенда)
POT = [
    # ---------- вода, любая (старые)
    ("sleep_tea", "Сонный чай", "water", "any", "S2", "Помогает уснуть и прогоняет кошмары."),
    ("vigor_tea", "Бодрящий чай", "water", "any", "M2F2", "Возвращает силы после тяжёлой работы."),
    ("calm_tea", "Успокаивающий чай", "water", "any", "P3", "Унимает тревогу и дрожь в руках."),
    ("mint_tea", "Мятный чай", "water", "any", "F4", "Снимает жар и тошноту после пира."),
    ("warm_tea", "Согревающий чай", "water", "any", "T1F1", "Лечит простуду и озноб."),
    # ---------- вода тёплая
    ("morning_tea", "Чай доброго утра", "water", "warm", "F2T2", "Глаза открываются сами, а день кажется длиннее."),
    ("colic_tea", "Детский чай от колик", "water", "warm", "P2T1H1", "Младенцы засыпают, а мамы выдыхают."),
    ("clear_tea", "Чай ясной головы", "water", "warm", "F2P2", "Мысли раскладываются по полочкам."),
    ("wander_tea", "Чай странника", "water", "warm", "M2T2", "Дорога короче, ноги не ноют."),
    ("meadow_tea", "Луговой сбор", "water", "warm", "H2P1F1", "Всего понемногу — от всего понемногу."),
    ("dream_tea", "Чай сладких снов", "water", "warm", "S3P2", "Снится детство и запах пирогов."),
    ("cough_tea", "Чай от кашля", "water", "warm", "H2T2", "Грудь дышит свободно уже к вечеру."),
    ("chatter_tea", "Чай болтушки", "water", "warm", "Z1T2F1", "Развязывает язык самым молчаливым гостям."),
    ("memory_tea", "Чай памяти", "water", "warm", "F3A1", "Вспоминаются имена, даты и куда положила ключи."),
    ("firefly_tea", "Светлячковый чай", "water", "warm", "L2F1", "Кожа тихо светится до самого утра."),
    ("purr_tea", "Чай кошачьей ласки", "water", "warm", "P2S1A1", "Кошкодевочки мурчат от одного запаха."),
    ("solace_tea", "Чай от тоски", "water", "warm", "P2L1", "Тяжёлое на душе становится лёгким."),
    ("voice_tea", "Чай певуньи", "water", "warm", "H1F2T1", "Голос чистый, как ручей."),
    ("fairy_tea", "Чай лесной феи", "water", "warm", "A1F2P1", "Слышно, о чём шепчутся деревья."),
    ("knight_tea", "Чай рыцаря", "water", "warm", "M2H2", "После турнира — как новенькая."),
    # ---------- вода горячая (отвары)
    ("strong_brew", "Крепкий отвар", "water", "hot", "M3", "Чёрный, как дёготь. Будит даже медведя."),
    ("fire_brew", "Огненный отвар", "water", "hot", "O2T2", "Пьёшь — и внутри разгорается печка."),
    ("bath_brew", "Банный отвар", "water", "hot", "T3H1", "Плеснуть на камни — и любая хворь выходит паром."),
    ("flu_brew", "Отвар от простуды", "water", "hot", "T2H2", "Пот, одеяло, сон — к утру здорова."),
    ("sweat_brew", "Жаропот", "water", "hot", "T3Z1", "Выгоняет лихорадку вместе с потом."),
    ("smith_brew", "Кузнечный отвар", "water", "hot", "M3T2", "Кузнецы пьют его, чтобы молот был лёгким."),
    ("bitter_brew", "Горький отвар", "water", "hot", "Z2H1", "Гадость редкая. Зато живот больше не болит."),
    ("brave_brew", "Отвар храбрости", "water", "hot", "M2Z2", "Колени не дрожат даже перед троллем."),
    ("ache_brew", "Отвар от ломоты", "water", "hot", "H2M2", "Спина гнётся, как в юности."),
    ("hunter_brew", "Охотничий отвар", "water", "hot", "M2D1", "Шаги тише, глаза зорче."),
    ("dragon_blood", "Драконья кровь", "water", "hot", "O4M3", "Густой и алый. Говорят, после него можно дышать дымом.", 2),
    ("sun_brew", "Солнечный отвар", "water", "hot", "L3T3", "В кружке будто плещется кусочек полдня.", 2),
    ("phoenix_brew", "Отвар феникса", "water", "hot", "O6H5L3", "Поднимает даже того, кто уже не дышит. Легенда травников.", 3),
    # ---------- вода холодная (настои)
    ("ice_inf", "Ледяной настой", "water", "cold", "C2F1", "Зубы ломит, а голова — ясная."),
    ("cold_mors", "Холодный морс", "water", "cold", "F3C1", "Лучшее, что можно выпить в жару."),
    ("heat_cure", "Настой от зноя", "water", "cold", "C2P1", "Солнечный удар отступает за минуту."),
    ("burn_inf", "Настой от ожогов", "water", "cold", "C2H2", "Примочка — и кожа больше не горит."),
    ("hush_inf", "Тихий настой", "water", "cold", "P3C1", "Безмолвие внутри. Мысли текут медленно, как река."),
    ("dew_inf", "Утренняя роса", "water", "cold", "F2C2", "Умыться им — и лицо свежее, как после сна."),
    ("night_eye", "Настой ночного зрения", "water", "cold", "D2F2", "В темноте видно, как в сумерках."),
    ("fog_inf", "Настой тумана", "water", "cold", "D2C2", "Вокруг тебя стелется туман — попробуй найди."),
    ("mermaid_inf", "Настой русалки", "water", "cold", "C3F3", "Под водой можно дышать — недолго, но можно."),
    ("winter_sleep", "Зимний сон", "water", "cold", "C3S3", "Спишь, как медведь в берлоге: глубоко и без снов.", 2),
    ("moon_tear", "Слеза луны", "water", "cold", "L3C3A2", "Серебряная капля. Маги платят за неё золотом.", 2),
    ("glacier_heart", "Сердце ледника", "water", "cold", "C6A3P3", "Время вокруг замедляется, как зимой подо льдом.", 3),
    # ---------- воск (мази)
    ("heal_salve", "Заживляющая мазь", "wax", "any", "H2", "Затягивает ссадины и порезы."),
    ("bruise_salve", "Мазь от ушибов", "wax", "any", "M2H1", "Снимает отёк и синяки."),
    ("cool_salve", "Холодящая мазь", "wax", "any", "F2P2", "Успокаивает ожоги."),
    ("bite_salve", "Мазь от укусов", "wax", "any", "Z1F2", "Комары облетают стороной, а укусы не чешутся."),
    ("warm_salve", "Согревающая мазь", "wax", "any", "T3Z1", "Растереть спину — и никакой мороз не страшен."),
    ("joint_salve", "Мазь для суставов", "wax", "any", "T2M2", "Колени больше не скрипят на погоду."),
    ("callus_salve", "Мазь от мозолей", "wax", "any", "H3", "Ноги снова влезают в сапоги."),
    ("frost_salve", "Мазь от обморожения", "wax", "any", "T2H2", "Пальцы оттаивают и розовеют."),
    ("burn_salve", "Мазь от ожогов", "wax", "any", "C2H2", "Кузнецы и пекарши держат её у печи."),
    ("glow_salve", "Мазь сияния", "wax", "any", "L2H1", "Кожа сияет, как жемчуг. Вампирши завидуют."),
    ("stride_salve", "Мазь лёгкой походки", "wax", "any", "F2M2", "Натереть ступни — и шагаешь, будто летишь."),
    ("paw_salve", "Мазь для лапок", "wax", "any", "H2P2", "Мягкие подушечки. Кошкодевочки берут ящиками."),
    ("blade_salve", "Оружейная мазь", "wax", "any", "M3Z2", "Клинок не ржавеет и режет, как новый."),
    ("fireproof", "Огнеупорная мазь", "wax", "any", "C3M2", "Можно взять уголёк голой рукой. Ненадолго."),
    ("shadow_salve", "Теневая мазь", "wax", "any", "D3P1", "Ночью тебя не видно даже кошке."),
    ("curse_salve", "Мазь от проклятий", "wax", "any", "L3A2", "Снимает сглаз, порчу и дурной глаз соседки.", 2),
    ("dragonscale", "Мазь драконьей чешуи", "wax", "any", "O3M3", "Кожа твёрдая, как чешуя. Стрелы отскакивают.", 2),
    ("scar_salve", "Мазь от шрамов", "wax", "any", "H4F1", "Старые шрамы бледнеют и исчезают."),
    ("spider_salve", "Мазь паучьего шага", "wax", "any", "D2M2", "Ладони липнут к стенам. Паучихи одобряют."),
    ("itch_salve", "Мазь от зуда", "wax", "any", "P2C1", "После крапивы и комаров — самое то."),
    ("web_salve", "Мазь от паутины", "wax", "any", "Z2P1", "Паутина сама соскальзывает с волос и одежды."),
    ("youth_salve", "Мазь вечной молодости", "wax", "any", "H6L3A3", "Эльфийки молчат, что знают рецепт. Морщины уходят навсегда.", 3),
    # ---------- спирт (настойки)
    ("strength_tinct", "Крапивная настойка", "spirit", "any", "M4", "Укрепляет после долгой болезни."),
    ("head_tinct", "Настойка от мигрени", "spirit", "any", "P2Z1", "Прогоняет головную боль."),
    ("pepper_tinct", "Перцовка", "spirit", "any", "Z3T1", "Орки пьют на спор. Травница — по капле от простуды."),
    ("insomnia_tinct", "Настойка от бессонницы", "spirit", "any", "S3", "Десять капель — и спишь до петухов."),
    ("heart_drops", "Сердечные капли", "spirit", "any", "P2H2", "Сердце бьётся ровно, как часы."),
    ("battle_tinct", "Боевая настойка", "spirit", "any", "M3Z2", "Рыцарши пьют её перед турниром."),
    ("alert_tinct", "Настойка бодрости", "spirit", "any", "F3M1", "Ночь без сна, а глаза ясные."),
    ("cough_drops", "Капли от кашля", "spirit", "any", "H2F2", "Три капли в тёплую воду — и кашля нет."),
    ("sight_tinct", "Настойка ясновидения", "spirit", "any", "A2L1", "Во сне показывают, что будет завтра."),
    ("witch_tinct", "Ведьмина настойка", "spirit", "any", "A2D2", "Чёрная, с зелёной искрой. Лучше не спрашивать, зачем."),
    ("firewater", "Огненная вода", "spirit", "any", "O3Z2", "Выдохнешь — и свечи загораются сами."),
    ("night_tinct", "Ночная настойка", "spirit", "any", "D3S2", "Спишь днём, бодрствуешь ночью. Как вампирша."),
    ("luck_tinct", "Настойка удачи", "spirit", "any", "L2A1F1", "Монетки находятся, а грибы — белые."),
    ("berserk", "Эликсир берсерка", "spirit", "any", "M5O2", "Ярость без страха и боли. Орочий вождь бы оценил.", 2),
    ("crimson_tinct", "Багровая настойка", "spirit", "any", "D3M2H1", "Вкус железа и ночи. Вампирши покупают тайком.", 2),
    ("star_tinct", "Звёздная настойка", "spirit", "any", "A3L3", "В бутылке кружатся крошечные звёзды.", 2),
    ("invis_tinct", "Настойка невидимости", "spirit", "any", "D4A3", "Тебя не видно. Совсем. Даже в зеркале.", 2),
    ("mandrake_tears", "Слёзы мандрагоры", "spirit", "any", "S3M3D1", "Человечек плакал не зря: сила и сон в одной капле."),
    ("north_tinct", "Северная настойка", "spirit", "any", "C3M2", "Мороз нипочём. Дворфийки пьют её в шахтах."),
    ("balsam", "Травяной бальзам", "spirit", "any", "H2T2M1F1", "Девять трав, сорок капель. От всего на свете."),
    ("pine_tinct", "Хвойная настойка", "spirit", "any", "M2F2", "Пахнет тайгой и смолой. Лёгкие дышат глубже."),
    ("wind_tinct", "Настойка ветра", "spirit", "any", "F4A1", "Бежишь — и ветер подталкивает в спину."),
    ("void_tinct", "Настойка бездны", "spirit", "any", "D6A5", "Смотреть в неё долго нельзя. Бездна смотрит в ответ.", 3),
    # ---------- мёд (сиропы)
    ("throat_syrup", "Сироп для горла", "honey", "any", "H2T1", "Ложечка — и голос вернулся."),
    ("kids_syrup", "Детский сироп", "honey", "any", "P1H1F1", "Сладкий — дети просят ещё и не капризничают."),
    ("sleep_syrup", "Сироп сладкого сна", "honey", "any", "S2P1", "Колыбельная в ложке."),
    ("berry_syrup", "Ягодный сироп", "honey", "any", "F2M1", "Лето в бутылке. Зимой — на вес золота."),
    ("spice_syrup", "Пряный сироп", "honey", "any", "T2Z1", "Корица, перец и мёд. Греет до пяток."),
    ("love_syrup", "Сироп нежности", "honey", "any", "T2L1A1", "Щёки розовеют, слова становятся мягкими."),
    ("laugh_syrup", "Сироп смеха", "honey", "any", "F2A1", "Смешно всё: и коровы, и тучи, и даже налоги."),
    ("might_syrup", "Сироп силы", "honey", "any", "M3T1", "Мешок муки — как пёрышко."),
    ("golden_syrup", "Золотой сироп", "honey", "any", "L3H2", "Густой, как солнечный свет. Лечит тоску и раны.", 2),
    ("courage_syrup", "Сироп отваги", "honey", "any", "M2O1", "Сладкая смелость: и к дракону подойдёшь."),
    ("peace_syrup", "Сироп покоя", "honey", "any", "P3H1", "Буря внутри утихает."),
    ("fairy_syrup", "Сироп цветочной феи", "honey", "any", "A2F2L1", "Пчёлы садятся на плечи и не жалят.", 1),
    ("joy_syrup", "Сироп радости", "honey", "any", "L1T2P1", "Хочется петь и обнимать всех подряд."),
    ("hag_syrup", "Сироп старой ведьмы", "honey", "any", "D2T2", "Тёмный и тягучий. Кошмары больше не приходят."),
    ("ambrosia", "Амброзия", "honey", "any", "L5H5A4", "Пища богов. Одна ложка — и год без болезней.", 3),
    # ---------- лунная роса (эликсиры)
    ("moonlight", "Эликсир лунного света", "moon_dew", "any", "L2A2", "Ночью вокруг тебя светло, как в полнолуние."),
    ("lucid", "Эликсир снов наяву", "moon_dew", "any", "S3A2", "Во сне можно гулять, где захочешь."),
    ("flight", "Эликсир полёта", "moon_dew", "any", "A3F3", "Ноги едва касаются земли.", 2),
    ("beast_talk", "Эликсир звериного языка", "moon_dew", "any", "A2P2", "Лиса рассказывает сплетни, а ёж — жалуется на соседей."),
    ("cat_form", "Эликсир кошачьего облика", "moon_dew", "any", "A3P2S1", "Уши, хвост и непреодолимая тяга к коробкам.", 1),
    ("night_elixir", "Эликсир ночи", "moon_dew", "any", "D3A2", "Тьма становится мягкой и послушной."),
    ("fire_elixir", "Эликсир пламени", "moon_dew", "any", "O3A2", "Огонь не жжёт, а слушается."),
    ("ice_elixir", "Эликсир льда", "moon_dew", "any", "C3A2", "Касание — и вода покрывается льдом."),
    ("life_elixir", "Эликсир жизни", "moon_dew", "any", "H5A3L2", "Возвращает силы самым старым и больным.", 2),
    ("truth", "Эликсир истины", "moon_dew", "any", "L3P2A1", "Кто выпьет — не сможет соврать до заката."),
    ("fortune", "Эликсир фортуны", "moon_dew", "any", "L2A3F1", "Кости падают шестёрками, а кошки — на четыре лапы.", 2),
    ("dragon_elixir", "Эликсир дракона", "moon_dew", "any", "O5M4A2", "Глаза с вертикальным зрачком и пламя в груди.", 3),
    ("unicorn_elixir", "Эликсир единорога", "moon_dew", "any", "L4H4P2", "Чистый, как первый снег. Единороги подходят сами.", 2),
    ("sea_elixir", "Эликсир морской девы", "moon_dew", "any", "C2F3A2", "Русалки принимают тебя за свою.", 1),
    ("time_elixir", "Эликсир времени", "moon_dew", "any", "A5L3D3", "Мир на миг замирает. Часы на башне спорят сами с собой.", 3),
    ("philosopher", "Философский эликсир", "moon_dew", "any", "O3C3L2D3A3", "Огонь и лёд, свет и тьма в одной капле. Говорят, его не варил никто.", 3),
]

# Ключевые травы: зелье выходит, только если в котле есть хоть одна трава из каждой группы
KEYS = {
    "dragon_blood": [["dragon_root", "fire_lily"]], "sun_brew": [["sunflower_gold"]], "winter_sleep": [["frost_lotus"]],
    "moon_tear": [["moonbloom", "moon_shroom"]], "curse_salve": [["unicorn_mane", "sunflower_gold"]], "dragonscale": [["dragon_root"]],
    "berserk": [["dragon_root", "ginseng"]], "crimson_tinct": [["nightshade"]], "star_tinct": [["moonbloom", "crystal_root"]],
    "invis_tinct": [["shadow_orchid"]], "golden_syrup": [["sunflower_gold"]], "fairy_syrup": [["moonbloom", "elf_star", "unicorn_mane"]],
    "flight": [["unicorn_mane", "moonbloom", "crystal_root"]], "cat_form": [["catnip"]], "life_elixir": [["ginseng", "unicorn_mane"]],
    "fortune": [["moon_shroom"]], "unicorn_elixir": [["unicorn_mane"]], "sea_elixir": [["sea_lavender", "sea_kale"]],
    "phoenix_brew": [["phoenix_grass"]], "glacier_heart": [["frost_lotus"], ["world_leaf"]], "youth_salve": [["world_leaf"]],
    "void_tinct": [["void_bloom"]], "ambrosia": [["sunflower_gold"], ["world_leaf", "phoenix_grass"]],
    "dragon_elixir": [["dragon_root"], ["phoenix_grass"]], "time_elixir": [["void_bloom"]],
    "philosopher": [["phoenix_grass"], ["world_leaf"], ["void_bloom"]],
    # редкие с травой-ключом
    "firefly_tea": [["glowmoss", "glow_cap", "fire_lily", "sunflower_gold", "unicorn_mane"]],
    "shadow_salve": [["shadow_orchid", "nightshade", "void_bloom"]], "fireproof": [["frost_lotus", "fire_lily"]],
    "mandrake_tears": [["mandrake"]], "purr_tea": [["catnip"]], "paw_salve": [["catnip"]],
    "spider_salve": [["web_grass", "web_shroom"]], "web_salve": [["web_grass", "web_shroom"]],
    "mermaid_inf": [["sea_lavender", "sea_kale", "frost_lotus"]], "fire_elixir": [["fire_lily", "fire_pepper", "dragon_root"]],
    "ice_elixir": [["frost_lotus", "cloudberry"]], "night_elixir": [["nightshade", "shadow_orchid", "blood_russula"]],
}

# цвета свойств — для цвета жидкости
PCOL = {F: (92, 200, 140), P: (124, 184, 200), S: (138, 120, 208), T: (232, 160, 64), H: (242, 214, 132), M: (110, 150, 60),
        Z: (200, 80, 60), C: (150, 210, 245), O: (250, 110, 30), L: (255, 240, 170), D: (60, 30, 90), A: (190, 90, 230)}
OLD_COL = {"sleep_tea": "8a78d0", "vigor_tea": "c86a32", "calm_tea": "7cc0a0", "mint_tea": "5cc08a", "warm_tea": "e0a040",
           "heal_salve": "f2d684", "bruise_salve": "a8b85a", "cool_salve": "9ccce6", "strength_tinct": "5e9a3a", "head_tinct": "b0589a"}


def color_for(need):
    tot = sum(need)
    r = g = b = 0.0
    for i, n in enumerate(need):
        if n:
            c = PCOL[i]
            r += c[0] * n; g += c[1] * n; b += c[2] * n
    return "%02x%02x%02x" % (int(r / tot), int(g / tot), int(b / tot))


# ---------------------------------------------------------------- проверка
def rules():
    out = []
    for i, p in enumerate(POT):
        need = vec(p[4])
        score = sum(need) + (0.5 if p[3] != "any" else 0)
        out.append((p[0], p[2], p[3], np.array(need), score, i, KEYS.get(p[0], [])))
    return out


def all_states():
    st = []
    for k, v in ING.items():
        for seq, vv in variants(v).items():
            st.append((k, seq, vv))
    # убрать одинаковые векторы одной травы
    seen = set(); out = []
    for k, seq, vv in st:
        key = (k, tuple(vv))
        if key in seen:
            continue
        seen.add(key); out.append((k, seq, vv))
    return out


def winners(vecs, base, temp, R, HM, HIDS):
    """vecs: N×12 -> индексы правил (или -1); HM: N×k номера трав в смеси"""
    best = np.full(len(vecs), -1); bs = np.full(len(vecs), -1.0)
    for (pid, b, t, need, score, idx, keys) in R:
        if b != base or (t != "any" and t != temp):
            continue
        ok = np.all(vecs >= need, axis=1)
        for grp in keys:
            gi = [HIDS[g] for g in grp if g in HIDS]
            ok &= np.isin(HM, gi).any(axis=1)
        better = ok & (score > bs)
        best[better] = idx
        bs = np.where(better, score, bs)
    return best


def finish_np(V, base, temp):
    V = V.copy()
    if base == "water":
        if temp == "cold":
            V[:, C] += 1; V[:, T] = np.maximum(0, V[:, T] - 1)
        elif temp == "hot":
            # самое сильное +1 (первое при равенстве)
            i = np.argmax(V, axis=1)
            rows = np.arange(len(V))
            pos = V[rows, i] > 0
            V[rows[pos], i[pos]] += 1
            V[:, F] = np.maximum(0, V[:, F] - 1)
    if base == "moon_dew":
        V[:, A] += 1
    return V


MEGA = {"phoenix_grass", "world_leaf", "void_bloom"}
RARE_H = MEGA | {"fire_lily", "frost_lotus", "shadow_orchid", "sunflower_gold", "dragon_root", "unicorn_mane", "moonbloom",
                 "crystal_root", "nightshade", "mandrake", "ginseng", "moon_shroom", "glowmoss"}


def search(seed=1, banned=()):
    random.seed(seed)
    np.random.seed(seed)
    R = rules()
    S = [s for s in all_states() if s[0] not in banned]
    SV = np.array([s[2] for s in S])
    HIDS = {k: i for i, k in enumerate(ING.keys())}
    SH = np.array([HIDS[s[0]] for s in S])
    n = len(S)
    found = {}
    count = {p[0]: 0 for p in POT}

    def consider(idxs_list, V):
        mx = max(len(x) for x in idxs_list)
        HM = np.full((len(idxs_list), mx), -1)
        for j, x in enumerate(idxs_list):
            HM[j, :len(x)] = SH[x]
        for base in BASES:
            temps = TEMPS if base == "water" else ["warm"]
            for temp in temps:
                W = winners(finish_np(V, base, temp), base, temp, R, HM, HIDS)
                for j, w in enumerate(W):
                    if w < 0:
                        continue
                    pid = POT[w][0]
                    count[pid] += 1
                    if pid not in found or len(idxs_list[j]) < len(found[pid][2]):
                        found[pid] = (base, temp, idxs_list[j])

    # одиночки
    consider([[i] for i in range(n)], SV)
    # пары
    for i in range(n):
        js = list(range(i, n))
        consider([[i, j] for j in js], SV[i] + SV[i:])
    # тройки и четвёрки — случайно
    for size in (3, 4):
        for _ in range(60):
            idx = np.random.randint(0, n, size=(20000, size))
            V = SV[idx].sum(axis=1)
            consider([list(r) for r in idx], V)
    return found, count, S


def main():
    found, count, S = search()
    miss = [p for p in POT if p[0] not in found]
    print("зелий:", len(POT), "достижимо:", len(found), "нет:", [m[0] for m in miss])
    for p in POT:
        if p[0] in found:
            b, t, ids = found[p[0]]
            print("%-16s %-8s %-5s cnt=%-8d %s" % (p[0], b, t, count[p[0]], " + ".join(S[i][0] + ("(" + ",".join(S[i][1]) + ")" if S[i][1] else "") for i in ids)))
    bad = []
    f2, _, _ = search(2, MEGA)
    for p in POT:
        if rarity(p, 0) == 3 and p[0] in f2:
            bad.append(("легенда без мега-травы", p[0]))
    f3, _, S3 = search(3, RARE_H)
    for p in POT:
        if rarity(p, 0) >= 2 and p[0] in f3:
            b, t, ids = f3[p[0]]
            bad.append(("очень редкое из обычных", p[0], " + ".join(S3[i][0] + str(S3[i][1]) for i in ids)))
    for b in bad:
        print("!!", b)
    if "--write" in sys.argv:
        write(found, count, S)


def rarity(p, cnt):
    if len(p) > 6:
        return p[6]
    need = vec(p[4])
    rare = sum(need[i] for i in RARE_PROPS)
    if rare >= 1 or sum(need) >= 6:
        return 1
    return 0


def gd_str(s):
    return '"' + s.replace('"', '\\"') + '"'


def write(found, count, S):
    L = []
    L.append("extends RefCounted")
    L.append("## Алхимия v16 (СГЕНЕРИРОВАНО tools/potion_design.py — правь там и запускай с --write).")
    L.append("## Свойства трав складываются; травы можно обработать на столе (растереть, нарезать, высушить, обжечь, замочить);")
    L.append("## основа (вода, воск, спирт, мёд, лунная роса) и температура воды решают, что выйдет. Побеждает самое «точное» зелье.")
    L.append("")
    L.append('const HERBS = preload("res://herbs_db.gd")')
    L.append('const W = preload("res://wild_db.gd")')
    L.append("")
    L.append("const PROPS: Array = [%s]" % ", ".join(gd_str(p) for p in PROPS))
    L.append("const RARE_PROPS: Array = [%s]" % ", ".join(gd_str(PROPS[i]) for i in sorted(RARE_PROPS)))
    L.append("const BASES: Array = [%s]" % ", ".join(gd_str(b) for b in BASES))
    L.append("const BASE_NAME: Dictionary = {%s}" % ", ".join("%s: %s" % (gd_str(k), gd_str(v)) for k, v in BASE_NAME.items()))
    L.append("const BASE_KIND: Dictionary = {%s}" % ", ".join("%s: %s" % (gd_str(k), gd_str(v)) for k, v in BASE_KIND.items()))
    L.append("const TEMPS: Array = [\"cold\", \"warm\", \"hot\"]")
    L.append("const TEMP_NAME: Dictionary = {%s}" % ", ".join("%s: %s" % (gd_str(k), gd_str(v)) for k, v in TEMP_NAME.items()))
    L.append("const PROCS: Array = [%s]" % ", ".join(gd_str(p) for p in PROCS))
    L.append("const PROC_NAME: Dictionary = {%s}" % ", ".join("%s: %s" % (gd_str(k), gd_str(v)) for k, v in PROC_NAME.items()))
    L.append("const LEVEL: Dictionary = {\"I\": 1, \"II\": 2, \"III\": 3}")
    L.append("const RARITY_NAME: Array = [\"обычное\", \"редкое\", \"очень редкое\", \"легендарное\"]")
    L.append("const RARITY_COL: Array = [Color(\"c8b898\"), Color(\"7ab0f0\"), Color(\"c890f0\"), Color(\"f8c040\")]")
    L.append("")
    L.append("## Редкие свойства у трав (дописываются к свойствам из herbs_db.gd)")
    L.append("const HERB_EXTRA: Dictionary = {")
    for k, add in EXTRA.items():
        v = vec(add)
        L.append("\t%s: {%s}," % (gd_str(k), ", ".join("%s: %d" % (gd_str(PROPS[i]), n) for i, n in enumerate(v) if n)))
    L.append("}")
    L.append("## Свойства грибов")
    L.append("const SHROOM_PROPS_BASE: Dictionary = {")
    for k, s in SHROOMS.items():
        v = vec(s)
        L.append("\t%s: {%s}," % (gd_str(k), ", ".join("%s: %d" % (gd_str(PROPS[i]), n) for i, n in enumerate(v) if n)))
    L.append("}")
    L.append("")
    L.append("## Зелья. need — минимальные суммы свойств; temp — для воды (any — любая).")
    L.append("## rarity: 0 обычное, 1 редкое, 2 очень редкое, 3 легендарное. hint — пример рецепта (для режима бога и проверок).")
    L.append("const PRODUCTS: Dictionary = {")
    for p in POT:
        need = vec(p[4])
        col = OLD_COL.get(p[0], color_for(need))
        b, t, ids = found[p[0]]
        ex = []
        for i in ids:
            ex.append("[%s, [%s]]" % (gd_str(S[i][0]), ", ".join(gd_str(x) for x in S[i][1])))
        L.append("\t%s: {\"name\": %s, \"use\": %s, \"base\": %s, \"temp\": %s, \"need\": {%s}, \"rarity\": %d, \"col\": Color(\"%s\"), \"keys\": [%s], \"ex\": [%s, %s, [%s]]}," % (
            gd_str(p[0]), gd_str(p[1]), gd_str(p[5]), gd_str(p[2]), gd_str(p[3]),
            ", ".join("%s: %d" % (gd_str(PROPS[i]), n) for i, n in enumerate(need) if n), rarity(p, count[p[0]]), col,
            ", ".join("[" + ", ".join(gd_str(g) for g in grp) + "]" for grp in KEYS.get(p[0], [])),
            gd_str(b), gd_str(t), ", ".join(ex)))
    L.append("\t\"murky\": {\"name\": \"Мутный отвар\", \"use\": \"Ни на что не годится. Но и это опыт.\", \"base\": \"\", \"temp\": \"any\", \"need\": {}, \"rarity\": 0, \"col\": Color(\"6e6650\"), \"ex\": []},")
    L.append("}")
    L.append("")
    L.append(open(os.path.join(HERE, "recipes_tail.gd.txt"), encoding="utf8").read())
    open(os.path.join(GAME, "recipes_db.gd"), "w", encoding="utf8", newline="\n").write("\n".join(L))
    # данные для генератора значков
    icons = {p[0]: {"base": p[2], "col": OLD_COL.get(p[0], color_for(vec(p[4]))), "rarity": rarity(p, 0), "temp": p[3]} for p in POT}
    icons["murky"] = {"base": "water", "col": "6e6650", "rarity": 0, "temp": "any"}
    json.dump(icons, open(os.path.join(HERE, "potion_icons.json"), "w", encoding="utf8"), ensure_ascii=False, indent=0)
    json.dump({k: [v[0], v[1], v[2]] for k, v in NEW_HERBS.items()}, open(os.path.join(HERE, "new_herbs.json"), "w", encoding="utf8"), ensure_ascii=False)
    print("записано recipes_db.gd")


if __name__ == "__main__":
    main()

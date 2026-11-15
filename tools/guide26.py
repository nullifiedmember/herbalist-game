"""Справочник «Где взять и зачем нужно» для «Лесного травника».

Читает данные прямо из .gd-файлов игры (через gdload.py) и собирает один HTML:
по каждому материалу, траве, грибу, перу, насекомому, блюду, зелью и мастерскому рецепту —
ГДЕ взять, КАК добыть, ЗАЧЕМ нужно.

Запуск:  python game/tools/guide26.py            (результат: Справочник/index.html рядом с игрой)
Если в игру добавили новое — просто запусти заново (и обнови бестиарий).
"""
import html
import sys
from collections import defaultdict
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import gdload as g  # noqa: E402

GAME = g.GAME
OUT = GAME.parent / "Справочник"

# ───────────────────────── данные ─────────────────────────
MATS = g.load("mats_db.gd", "MATS")
M_ORDER = g.load("mats_db.gd", "ORDER")
STATIONS = g.load("mats_db.gd", "STATIONS")
SREC = g.load("mats_db.gd", "RECIPES")
TRAPS = g.load("mats_db.gd", "TRAPS")
LOOT = g.load("mats_db.gd", "LOOT")
NODES = g.load("mats_db.gd", "NODES")
ROCK_EXTRA = g.load("mats_db.gd", "ROCK_EXTRA")
ORE_DEP = g.load("mats_db.gd", "ORE_DEPOSITS")
CHOP = g.load("mats_db.gd", "CHOP_EXTRA")
BUILD = dict(g.load("mats_db.gd", "BUILD"))
PLOT = g.load("mats_db.gd", "PLOT_NEED")
FUR = g.load("mats_db.gd", "FUR_IDS")
GROUPS = g.load("mats_db.gd", "GROUPS")
BAIT_MAGIC = g.load("mats_db.gd", "BAIT_MAGIC")
BAIT_SEED = g.load("mats_db.gd", "BAIT_SEED")
HERBS = g.load("herbs_db.gd", "DATA")
H_ORDER = g.load("herbs_db.gd", "ORDER")
HARV = g.load("harvest_db.gd", "Q")
PRODUCTS = g.load("recipes_db.gd", "PRODUCTS")
BASE_NAME = g.load("recipes_db.gd", "BASE_NAME")
TEMP_NAME = g.load("recipes_db.gd", "TEMP_NAME")
PROC_NAME = g.load("recipes_db.gd", "PROC_NAME")
RARITY = g.load("recipes_db.gd", "RARITY_NAME")
HERB_EXTRA = g.load("recipes_db.gd", "HERB_EXTRA")
SH_PROPS = dict(g.load("recipes_db.gd", "SHROOM_PROPS_BASE"))
FOOD = g.load("food_db.gd", "DATA")
F_ORDER = g.load("food_db.gd", "ORDER")
F_KINDS = g.load("food_db.gd", "KINDS")
FREC = g.load("food_db.gd", "RECIPES")
ORES = g.load("mining_db.gd", "ORES")
SHROOMS = dict(g.load("wild_db.gd", "SHROOMS_BASE"))
SHROOMS25 = g.load("shrooms25_db.gd", "SHROOMS")
SH_PROPS.update(g.load("shrooms25_db.gd", "PROPS"))
SHROOMS.update(SHROOMS25)
BIRDS = g.load("birds_db.gd", "DATA")
B_ORDER = g.load("birds_db.gd", "ORDER")
INSECTS = g.load("insects_db.gd", "DATA")
BUG_PROPS = g.load("tree_db.gd", "BUG_PROPS")
TREES = g.load("tree_db.gd", "TREES")
ITEMS = g.load("items_db.gd", "ITEMS")
KBUILD = g.load("items_db.gd", "KBUILD")
BUILD_BASE = g.load("items_db.gd", "BUILD_BASE")
V24_BUILD = g.load("v24_data.gd", "BUILD")
V24_ITEMS = g.load("v24_data.gd", "ITEMS")
V23_PRODUCTS = g.load("v23_data.gd", "PRODUCTS")
try:
    for _k, _v in g.load("fauna25_db.gd", "LOOT").items():
        LOOT.setdefault(_k, _v)
except Exception:
    pass
ANIMALS = {}
for _n in ("ANIMALS_BASE", "FAUNA_BASE", "MYTHIC_BASE"):
    try:
        ANIMALS.update(g.load("wild_db.gd", _n))
    except Exception:
        pass
try:
    ANIMALS.update(g.load("fauna25_db.gd", "ANIMALS"))
except Exception:
    pass

BIOMES = {0: "усадьба и окрестности", 1: "луга", 2: "паутинный лес", 3: "готика (Сумеречье)", 4: "земли рыцарей",
          5: "эльфийский лес", 6: "земли магов", 7: "степь орков", 8: "горы дворфов", 9: "деревня кошек",
          10: "розовый лес единорогов", 11: "гроты", 12: "берёзовая роща", 13: "тайга", 14: "осенний лес",
          15: "болото", 16: "поля", 17: "Сакураяма (Япония)", 18: "побережье"}
TREE_NAMES = {k: v[0].replace(" лист", "").replace("Лепесток сакуры", "сакура") for k, v in TREES.items()}
GROUP_NAME = {"@plank": "любая доска", "@wood": "любая чурка", "@yarn": "любая пряжа",
              "@fur": "любой пух или шерсть", "@dye": "любой краситель"}


# ───────────────────────── имена и значки ─────────────────────────
def esc(s):
    return html.escape(str(s))


def bname(b):
    return BIOMES.get(int(b), f"область {b}")


def biomes_text(d, limit=6):
    """{биом: вес} или [биомы] -> «луга, болото…»"""
    if isinstance(d, dict):
        items = sorted(d.items(), key=lambda kv: -kv[1])
        ids = [k for k, _ in items]
    else:
        ids = list(d)
    names = [bname(b) for b in ids[:limit]]
    more = len(ids) - limit
    return ", ".join(names) + (f" и ещё {more}" if more > 0 else "")


def nm(i):
    i = str(i)
    if i in GROUP_NAME:
        return GROUP_NAME[i]
    if i in MATS:
        return MATS[i][0]
    if i in ITEMS:
        return ITEMS[i][0]
    if i in V24_ITEMS:
        return V24_ITEMS[i][0]
    if i in HERBS:
        return HERBS[i]["name"]
    if i in SHROOMS:
        return SHROOMS[i]["name"]
    if i in PRODUCTS:
        return PRODUCTS[i]["name"]
    if i.startswith("food_") and i[5:] in FOOD:
        return FOOD[i[5:]][0]
    if i in FOOD:
        return FOOD[i][0]
    if i.startswith("bug_") and i[4:] in INSECTS:
        return "Насекомое: " + INSECTS[i[4:]]["name"].lower()
    if i.startswith("leaf_") and i[5:] in TREES:
        return TREES[i[5:]][0]
    if i.startswith("feather_") and i[8:] in BIRDS:
        return "Перо: " + BIRDS[i[8:]]["name"].lower()
    if i in V23_PRODUCTS:
        return V23_PRODUCTS[i]["name"]
    if i in ANIMALS:
        return ANIMALS[i].get("name", i)
    return i


ART = GAME / "art"


def img(*names):
    for n in names:
        if n and (ART / (n + ".png")).exists():
            return "../game/art/" + n + ".png"
    return ""


def icon_of(i):
    i = str(i)
    if i in MATS:
        return img(MATS[i][3])
    if i in ITEMS:
        return img(ITEMS[i][2])
    if i in HERBS:
        return img(i + "_3", "herb14_" + i)
    if i in SHROOMS:
        return img("shroom_" + i)
    if i in PRODUCTS:
        return img("potion_" + i)
    if i.startswith("food_"):
        return img(i)
    if i in FOOD:
        return img("food_" + i)
    if i.startswith("feather_"):
        return img("icon_" + i)
    if i.startswith("leaf_"):
        return img("icon_" + i)
    return ""


# ───────────────────────── «где / как / зачем» ─────────────────────────
def pct(p):
    p = float(p) * 100
    return f"{p:.0f}%" if p >= 1 else f"{p:.1f}%"


def qty(a, b):
    return str(a) if a == b else f"{a}–{b}"


def group_ids(grp):
    if grp == "@fur":
        return list(FUR)
    pre = GROUPS.get(grp, "")
    return [k for k in MATS if k.startswith(pre)] if pre else []


def make_where():
    """id -> список (где, как)."""
    w = defaultdict(list)
    # места добычи
    for k, nd in NODES.items():
        title, _, biomes, drops, days, _snd = nd
        need_pick = k in ("coal", "sulfur", "saltpeter", "obsidian", "crystals")
        for d in drops:
            item, a, b, ch = d
            where = f"«{title}»" + (f" — встречается: {biomes_text(biomes)}" if biomes else " — лежит в море и на отмелях")
            how = ("Подойти и нажать E" + (", нужна кирка" if need_pick else "") +
                   f". Даёт {qty(a, b)} шт" + (f", шанс {pct(ch)}" if ch < 1 else "") +
                   f". Отрастает за {days} дн. Серп, золотой серп или лопата в сумке чаще дают на штуку больше.")
            w[item].append((where, how))
    # рубка
    for k, drops in CHOP.items():
        for d in drops:
            item, a, b, ch = d
            where = f"рубка дерева: {TREE_NAMES.get(k, k)}"
            how = f"Срубить топором. Даёт {qty(a, b)} шт." + (f", шанс {pct(ch)}" if ch < 1 else "")
            w[item].append((where, how))
    # камни
    rx = defaultdict(list)
    for bio, lst in ROCK_EXTRA.items():
        for item, ch in lst:
            rx[item].append((bio, ch))
    for item, lst in rx.items():
        lst.sort(key=lambda t: -t[1])
        where = "большие камни и валуны: " + ", ".join(f"{bname(b)} ({pct(c)})" for b, c in lst[:5]) + (f" и ещё {len(lst) - 5}" if len(lst) > 5 else "")
        w[item].append((where, "Разбить большой камень или валун киркой. У валунов шанс вдвое выше."))
    # руды
    for metal, dep in ORE_DEP.items():
        w["ore_" + metal].append(("месторождение руды: " + biomes_text(dep),
                                   "Разбить жилу киркой (несколько ударов). Через 4–7 дней жила отрастает снова."))
    for k, o in ORES.items():
        w["ore_" + k].append((f"«{o['name']}»: " + biomes_text(o["biomes"]),
                               f"Разбить кристальное месторождение киркой ({o['hits']} ударов). Даёт 2–3 шт."))
    # звери
    for key, drops in LOOT.items():
        for item, a, b, ch in drops:
            who = [t[0] for t in TRAPS.values() if key in t[1]]
            if key.startswith("*"):
                animal = {"*fish": "любая пойманная рыба", "*bird": "любая птица", "*bat": "летучая мышь"}.get(key, key)
            else:
                animal = nm(key).lower()
            where = f"зверь в ловушке: {animal}"
            how = ((f"Поймать в ловушку ({', '.join(who).lower()}), потом" if who else "Если зверь пойман или приручён,") +
                   " вычесать или подобрать сброшенное и отпустить. "
                   f"Даёт {qty(a, b)} шт." + (f", шанс {pct(ch)}" if ch < 1 else ""))
            w[item].append((where, how))
    # особые источники (найдены в коде игры)
    w["loam"].append(("компостная куча на участке", "Класть в компост, а когда он наполнится (не меньше 4 раз) и пройдёт день — открыть (E): получишь 3 шт."))
    w["cat_fur"].append(("кот-спутник (шерсть при линьке)", "Погладить кота (E): с шансом 35% на ладони остаётся шерсть."))
    w["cat_whisker"].append(("кот-спутник (выпавший ус)", "Гладить кота (E): не чаще раза в 3 дня, шанс 50%."))
    # станции
    for st, recs in SREC.items():
        sname = STATIONS[st][0]
        for out, n, needs in recs:
            ing = " + ".join(f"{nm(k)} ×{v}" for k, v in needs.items())
            w[out].append((f"мастерская «{sname}»", f"Положить {ing} и выбрать рецепт (E у станции) — получится {n} шт."))
    # деревья: листья, плоды
    for k, t in TREES.items():
        w["leaf_" + k].append((f"крона дерева: {t[0].lower()}", "Открыть дерево (E) и собрать листья с кроны."))
    # перья
    for bid, b in BIRDS.items():
        when = {"day": "днём", "night": "ночью", "dusk": "в сумерках"}.get(b.get("when"), "")
        w["feather_" + bid].append((f"птица «{b['name']}»: {biomes_text(b['biomes'])}" + (f", {when}" if when else ""),
                                     "Подойти к птице так, чтобы она вспорхнула, — она обронит перо. Перо лежит до следующего дня; подобрать — E."))
    # насекомые
    for iid, ins in INSECTS.items():
        w["bug_" + iid].append((f"«{ins['name']}»: {ins.get('where', '')}, {ins.get('when', '')}",
                                 "Взять сачок в руки и взмахнуть рядом с насекомым (тлю поймать нельзя)."
                                 if iid != "aphid" else "Живёт на грядках; сачком не ловится."))
    # травы, грибы, еда
    for hid, h in HERBS.items():
        w[hid].append((h["where"] + f" (области: {biomes_text(h['biomes'])})", "Собирать в окне сбора (E у растения) — у каждой травы своя особенность, см. раздел «Травы»."))
    for sid, s in SHROOMS.items():
        w[sid].append((s["need"] + f" (области: {biomes_text(s['biomes'])})", "Подойти к грибу и нажать E."))
    for fid, f in FOOD.items():
        w["food_" + fid].append((f[5], "Лавки, кухня, дерево или готовка — см. «Еда и блюда»."))
    return w


WHERE = make_where()


def make_use():
    """id -> список строк «зачем»."""
    u = defaultdict(list)

    def add(i, s):
        if s not in u[i]:
            u[i].append(s)

    for st, recs in SREC.items():
        sname = STATIONS[st][0]
        for out, n, needs in recs:
            for k in needs:
                for kk in (group_ids(k) if k.startswith("@") else [k]):
                    add(kk, f"{sname}: {nm(out)}")
    for src in (BUILD, V24_BUILD):
        for k, b in src.items():
            for need in b[5]:
                for kk in (group_ids(need) if need.startswith("@") else [need]):
                    add(kk, f"постройка: {b[0]}")
    for k, b in KBUILD.items():
        for need in b[6]:
            for kk in (group_ids(need) if need.startswith("@") else [need]):
                add(kk, f"постройка королевства: {b[0]}")
    for step, need in enumerate(PLOT, 1):
        for k in need:
            for kk in (group_ids(k) if k.startswith("@") else [k]):
                add(kk, f"расширение участка (шаг {step})")
    for rec in FREC:
        ings, res = rec
        for n in ings:
            add("food_" + n if n in FOOD else n, f"блюдо: {FOOD[res][0]}")
    for i in BAIT_SEED:
        add(i, "приманка для птичьих и садковых ловушек")
    for i in BAIT_MAGIC:
        add(i, "приманка для волшебной ловушки")
    for pid, p in PRODUCTS.items():
        ex = p.get("ex")
        if ex:
            add(ex[0] if ex[0] != "water" else "water_cold", f"зелье: {p['name']} (основа)")
            for hid, _procs in ex[2]:
                add(hid, f"зелье: {p['name']}")
    return u


USE = make_use()


def props_text(d):
    return ", ".join(f"{k} +{v}" if isinstance(v, int) else f"{k} {v}" for k, v in d.items())


def use_text(i, props=None, limit=10):
    lines = []
    if props:
        lines.append("в котле даёт свойства: " + props_text(props))
    lst = USE.get(i, [])
    if lst:
        shown = lst[:limit]
        more = len(lst) - len(shown)
        lines.append("нужно для: " + "; ".join(shown) + (f"; и ещё {more}" if more > 0 else ""))
    return lines


# ───────────────────────── карточки ─────────────────────────
def card(name, pic, sub="", rows=(), tags=(), rar=0):
    """rows — список (метка, текст). Пустые строки пропускаются."""
    body = "".join(f"<p><b>{esc(lab)}:</b> {esc(t)}</p>" for lab, t in rows if t)
    search = " ".join([name, sub] + [t for _, t in rows]).lower()
    tg = "".join(f'<span class="tag">{esc(t)}</span>' for t in tags if t)
    cls = "card" + (f" rar{rar}" if rar else "")
    im = f'<img class="big" src="{esc(pic)}" alt="" loading="lazy">' if pic else ""
    sb = f'<div class="sub">{esc(sub)}</div>' if sub else ""
    return (f'<div class="{cls}" data-s="{esc(search)}"><div class="pic">{im}</div>'
            f'<div><h4>{esc(name)}{tg}</h4>{sb}{body}</div></div>')


def where_rows(i):
    lst = WHERE.get(i, [])
    if not lst:
        return [("Где", "пока нигде не выпадает: в коде игры источник не задан")]
    ws = list(dict.fromkeys(w for w, _ in lst))
    gt = "; ".join(ws[:5]) + (f"; и ещё {len(ws) - 5}" if len(ws) > 5 else "")
    ht = " • ".join(dict.fromkeys(h for _, h in lst[:3]))
    return [("Где", gt), ("Как", ht)]


CAT_NAME = {"wood": "Дерево", "earth": "Земля и порошки", "stone": "Камень и кирпич", "glass": "Стекло",
            "metal": "Металл", "fiber": "Волокно и ткань", "animal": "Части зверей", "gem": "Самоцветы",
            "dye": "Краски", "food": "Пища", "sea": "Море", "cloth": "Ткани и одежда", "paper": "Бумага, свечи и масла", "feather": "Перья", "misc": "Разное", "magic": "Магия", "kit": "Наборы"}


def sec_mats():
    groups = defaultdict(list)
    for i in M_ORDER:
        m = MATS[i]
        rows = where_rows(i)
        rows.append(("Зачем", " | ".join(use_text(i, m[5])) or "в данных игры не используется в рецептах"))
        rows.append(("Вес и цена", f"вес {m[1]}, цена {m[2]} мон."))
        groups[m[4]].append(card(m[0], icon_of(i), rows=rows))
    return groups


def sec_ores():
    out = []
    for k, o in ORES.items():
        i = "ore_" + k
        rows = where_rows(i)
        rows.append(("Зачем", " | ".join(use_text(i)) or ""))
        rows.insert(0, ("О руде", o["desc"]))
        out.append(card(o["name"], icon_of(i), rows=rows, tags=[f"{o['hits']} ударов"]))
    return out


def sec_herbs():
    out = []
    for hid in H_ORDER:
        h = HERBS[hid]
        q = HARV.get(hid, {})
        pr = [f"{p} {lv}" for p, lv in h["props"]]
        extra = HERB_EXTRA.get(hid)
        rows = [("Где", f"{h['where']} (области: {biomes_text(h['biomes'])})"),
                ("Как добыть", "Нажать E у растения — откроется окно сбора. " + (q.get("text", "")) +
                 (" Лучше с ножом или в перчатках." if "sting" in q.get("tags", []) else "")),
                ("Свойства для котла", ", ".join(pr) + (f"; редкие: {props_text(extra)}" if isinstance(extra, dict) and extra else "")),
                ("Зачем", " | ".join(use_text(hid)) or "для зелий: свойства складываются в котле"),
                ("Цена", f"{h['price']} мон.")]
        out.append(card(h["name"], icon_of(hid), sub=h.get("latin", ""), rows=rows))
    return out


def sec_shrooms():
    out = []
    for sid, s in SHROOMS.items():
        hrs = s.get("hours", [0, 24])
        when = "в любое время" if hrs[0] <= 0 and hrs[1] >= 24 else f"в часы {hrs[0]}–{hrs[1]}"
        pr = SH_PROPS.get(sid, {})
        rows = [("Где", f"{s['need']} (области: {biomes_text(s['biomes'])})"),
                ("Как добыть", f"Подойти и нажать E. Растёт {when}."),
                ("Зачем", " | ".join(use_text(sid, pr)) or "в котёл или на кухню"),
                ("Цена", f"{s['price']} мон.; сытность {s.get('food', 0)}")]
        out.append(card(s["name"], icon_of(sid), rows=rows))
    return out


def sec_feathers():
    out = []
    for bid in B_ORDER:
        b = BIRDS[bid]
        i = "feather_" + bid
        rows = where_rows(i)
        rows.append(("Зачем", " | ".join(use_text(i, b.get("props"))) or ""))
        rows.append(("Цена пера", f"{b['price']} мон."))
        out.append(card("Перо: " + b["name"].lower(), icon_of(i), rows=rows, rar=1 if b.get("magic") else 0))
    return out


def sec_bugs():
    out = []
    for iid, ins in INSECTS.items():
        i = "bug_" + iid
        rows = where_rows(i)
        rows.append(("Зачем", ins.get("effect", "") + (" | " + " | ".join(use_text(i, BUG_PROPS.get(iid))) if BUG_PROPS.get(iid) else "")))
        out.append(card(ins["name"], "", rows=rows))
    return out


def sec_leaves():
    out = []
    for k, t in TREES.items():
        i = "leaf_" + k
        rows = where_rows(i)
        fr = ", ".join(f"{nm('food_' + f)} (шанс {pct(c)})" for f, c in t[2])
        if fr:
            rows.append(("Плоды этого дерева", fr))
        rows.append(("Зачем", " | ".join(use_text(i, t[1]))))
        out.append(card(t[0], icon_of(i), rows=rows))
    return out


def sec_nodes():
    out = []
    for k, nd in NODES.items():
        title, tex, biomes, drops, days, _snd = nd
        need_pick = k in ("coal", "sulfur", "saltpeter", "obsidian", "crystals")
        dr = ", ".join(f"{nm(i)} {qty(a, b)} шт." + (f" ({pct(ch)})" if ch < 1 else "") for i, a, b, ch in drops)
        rows = [("Где", biomes_text(biomes) if biomes else "на отмелях и в море"),
                ("Как добыть", "Нажать E у места." + (" Нужна кирка." if need_pick else "") + f" Отрастает за {days} дн."),
                ("Что даёт", dr),
                ("Зачем", "; ".join(dict.fromkeys(f"{nm(i)} — " + ("; ".join(USE.get(i, [])[:3]) or "в хозяйстве") for i, *_ in drops[:3])))]
        out.append(card(title, img(tex), rows=rows))
    return out


def sec_wood_faq():
    """Вопрос гиду: как добывать дерево."""
    return [card("Как добыть дерево?", "", rows=[
        ("Что нужно", "Топор (он в сумке). Нет топора? Окно крафта (I) → «Топор»: 2 палки (с веток деревьев) и 2 камушка (с земли). Возьми топор в руку — клавиши 1–9."),
        ("1. Срубить", "Подойди к дереву и руби топором (E). Дерево падает целиком, остаётся пень."),
        ("2. Обрубить ветки", "Руби лежащее дерево ещё: получишь длинные ветки, хворост, листья (у сосны — смолу)."),
        ("3. Порубить ствол", "Голый ствол руби на поленья: 3–5 штук «Полено» (log), иногда ещё то, что даёт это дерево."),
        ("Или унести", "Ствол можно поднять и нести: одной он слишком тяжёлый, вдвоём — медленно, впятером — легко. Стволы складываются в штабель."),
        ("Доски и брус", "Поленья пили на пилораме (станция строится из 8 поленьев, 2 камней и 2 кремней): получишь доски и брус."),
        ("Зачем", "Полено нужно для верстака, стола, сундука, колодца, фонаря и почти всех построек."),
        ("Где какое", "Какие деревья что дают — ниже, в группе «Рубка деревьев»."),
    ])]


def sec_trees_chop():
    out = []
    for k, drops in CHOP.items():
        dr = ", ".join(f"{nm(i)} {qty(a, b)} шт." + (f" ({pct(ch)})" if ch < 1 else "") for i, a, b, ch in drops)
        rows = [("Как", "Срубить дерево топором (топор — в сумке)."), ("Что даёт", dr + ", ещё бревно")]
        out.append(card("Рубка: " + TREE_NAMES.get(k, k), "", rows=rows))
    return out


def _animals_data():
    """Звери: имена, где живут, что любят, что дают в загоне, шанс малышей (как в книге и бестиарии)."""
    names = {}
    for f, n in (("wild_db.gd", "ANIMALS_BASE"), ("fauna25_db.gd", "ANIMALS")):
        for k, v in g.load(f, n).items():
            names[k] = v.get("name", k)
    for k, v in g.load("v23_data.gd", "FARM").items():
        names.setdefault(k, v.get("name", k))
    zoo = dict(g.load("farm23.gd", "ZOO_BASE"))
    zoo.update(g.load("fauna25_db.gd", "ZOO"))
    order = list(g.load("farm23.gd", "ORDER_BASE")) + list(g.load("fauna25_db.gd", "ORDER"))
    return names, zoo, order


BABY_LOOK = {
    "duck": "жёлтый пушистый утёнок", "chicken": "жёлтый цыплёнок", "goose": "жёлтый гусёнок",
    "boar": "полосатый кабанёнок", "flat_boar": "полосатый кабанёнок", "deer": "оленёнок в светлых пятнышках",
    "roe_deer": "косулёнок в светлых пятнышках", "seal": "белый пушистый бельк", "elk": "лосёнок без рогов",
}
FOOD_KIND = {"veg": "овощи", "berry": "ягоды", "meat": "мясо", "fish": "рыба", "grain": "зерно", "fruit": "фрукты", "nut": "орехи",
             "herb": "травы", "seed": "семена", "sweet": "сладкое", "mushroom": "грибы", "milk": "молоко", "honey": "мёд", "bug": "жуки"}


def sec_animals():
    global VOICES
    try:   # свой голос каждого зверя (tools/animal_voices.py)
        VOICES = g.load("animal_voices_db.gd", "VOICE")
    except Exception:
        VOICES = {}
    names, zoo, order = _animals_data()
    out = []
    for k in order:
        if k not in zoo:
            continue
        z = zoo[k]
        likes = ", ".join(FOOD_KIND.get(str(x), nm(x)) for x in z[2])
        pr = z[3]
        baby = BABY_LOOK.get(k, "маленький, с большой головой и короткими лапками" + (", без рогов" if k in ("cow", "goat", "ram", "ibex", "yak", "bison", "kirin", "unicorn", "forest_stag", "golden_deer", "jackalope") else ""))
        rows = [("Какой", z[0]), ("Где живёт", z[1]), ("Как приманить", f"взять в руку угощение ({likes}) и подойти — зверь пойдёт за тобой в загон"),
                ("В загоне даёт", f"{nm(pr[0])} ×{pr[1]} в день" if pr else ""),
                ("Голос", VOICES.get(k, "")),
                ("Малыши", f"если в загоне двое взрослых, ночью с шансом {int(float(z[4]) * 100)}% рождается малыш: {baby}. Через несколько дней вырастает.")]
        # картинка зверя — из бестиария (там кадры уже вырезаны из листа)
        bimg = GAME.parent / "Бестиарий" / "img" / ("animal_%s.png" % k)
        pic = "../Бестиарий/img/animal_%s.png" % k if bimg.exists() else ""
        out.append(card(names.get(k, k), pic, rows=rows, tags=["есть малыш"] if (ART / ("animal_%s_baby.png" % k)).exists() else []))
    return out


def sec_traps():
    out = []
    for k, t in TRAPS.items():
        who = ", ".join(nm(a) if not a.startswith("*") else {"*bird": "птицы", "*fish": "рыба", "*bat": "летучие мыши"}.get(a, a) for a in t[1])
        bait = {"food": "еда (фрукты, ягоды, овощи, хлеб)", "seed": "зерно и орехи", "magic": "волшебная приманка (лунная роса, золотое яблоко, звёздная пыль…)"}.get(t[2], t[2])
        b = BUILD.get(k)
        rows = [("Кого ловит", who), ("Приманка", bait), ("Время", f"в среднем {t[3]:g} ч до поимки"),
                ("Как построить", ", ".join(f"{nm(i)} ×{n}" for i, n in b[5].items()) if b else "см. постройки"),
                ("Зачем", "поймав зверя, можно вычесать из него пух, шерсть и перья — основа для пряжи и тканей")]
        out.append(card(t[0], img(b[1]) if b else "", rows=rows))
    return out


def sec_stations():
    groups = []
    for st, recs in SREC.items():
        sname = STATIONS[st][0]
        b = BUILD.get(st)
        entries = []
        for out, n, needs in recs:
            ing = " + ".join(f"{nm(k)} ×{v}" for k, v in needs.items())
            ing_where = "; ".join(f"{nm(k)}: {(WHERE[k][0][0] if k in WHERE and WHERE[k] else 'см. раздел')}" for k in list(needs)[:3] if not k.startswith("@"))
            rows = [("Рецепт", f"{ing} → {nm(out)} ×{n}"),
                    ("Где", f"на станции «{sname}» (построить в хозяйстве: {', '.join(f'{nm(i)} ×{c}' for i, c in b[5].items()) if b else '—'}); E у станции"),
                    ("Где взять составляющие", ing_where),
                    ("Зачем", " | ".join(use_text(out, MATS.get(out, [0] * 6)[5] if out in MATS else None, 6)) or "готовое изделие для хозяйства")]
            entries.append(card(f"{nm(out)} ×{n}", icon_of(out), rows=rows))
        groups.append((sname, entries))
    return groups


def sec_build():
    groups = defaultdict(list)
    tab_name = {"home": "Дом и хозяйство", "work": "Мастерские", "trap": "Ловушки", "bird": "Птицы", "deco": "Украшения", "wall": "Стены и ограды"}
    for k, b in list(BUILD.items()) + list(V24_BUILD.items()):
        ing = ", ".join(f"{nm(i)} ×{n}" for i, n in b[5].items())
        where_ing = "; ".join(f"{nm(i)}: {WHERE[i][0][0]}" for i in list(b[5])[:3] if i in WHERE and WHERE[i] and not i.startswith("@"))
        rows = [("Рецепт", ing), ("Где собрать", "верстак → вкладка «" + tab_name.get(b[4], b[4]) + "»"),
                ("Где взять материалы", where_ing)]
        groups[tab_name.get(b[4], b[4])].append(card(b[0], img(b[1]), rows=rows))
    kb = []
    for k, b in KBUILD.items():
        ing = ", ".join(f"{nm(i)} ×{n}" for i, n in b[6].items())
        kind = {"house": "жилище", "fun": "развлечение", "work": "производство"}.get(b[7], b[7])
        kb.append(card(b[0], img(b[1]), rows=[("Рецепт", ing), ("Что даёт", f"{kind}, сила {b[8]}"), ("Где", "верстак → вкладка с короной (королевство)")]))
    plot = []
    for step, need in enumerate(PLOT, 1):
        plot.append(card(f"Шаг расширения {step}", "", rows=[("Нужно", ", ".join(f"{nm(i)} ×{n}" for i, n in need.items())),
                                                              ("Зачем", "участок становится больше — больше места под грядки и постройки")]))
    return groups, kb, plot


def sec_potions():
    groups = defaultdict(list)
    for pid, p in sorted(PRODUCTS.items(), key=lambda kv: (kv[1]["rarity"], kv[1]["name"])):
        ex = p.get("ex")
        need = props_text(p["need"])
        temp = "любая вода" if p["temp"] == "any" else TEMP_NAME.get(p["temp"], p["temp"]) + " вода"
        rows = [("Зачем", p["use"]),
                ("Что нужно", f"основа «{BASE_NAME.get(p['base'], p['base'])}» ({temp}); сумма свойств: {need}")]
        if ex:
            parts = []
            where = []
            for hid, procs in ex[2]:
                parts.append(nm(hid) + (f" ({', '.join(PROC_NAME[x].lower() for x in procs)})" if procs else ""))
                if hid in WHERE and WHERE[hid]:
                    where.append(f"{nm(hid)}: {WHERE[hid][0][0]}")
            rows.append(("Пример рецепта", f"основа «{BASE_NAME.get(ex[0], ex[0])}», температура воды: {TEMP_NAME.get(ex[1], ex[1])}; ингредиенты: {', '.join(parts)}"))
            rows.append(("Где взять ингредиенты", "; ".join(where)))
        rows.append(("Как варить", "Котёл: выбрать основу и температуру воды, обработать травы на столе, положить в котёл"))
        groups[RARITY[p["rarity"]]].append(card(p["name"], icon_of(pid), rows=rows, rar=p["rarity"]))
    return groups


def food_where(n):
    if n in FOOD:
        return FOOD[n][5]
    if n in HERBS:
        return HERBS[n]["where"]
    if n in SHROOMS:
        return SHROOMS[n]["need"]
    k = n
    if k.startswith("bug_") and k[4:] in INSECTS:
        return "ловить сачком"
    if n in WHERE and WHERE[n]:
        return WHERE[n][0][0]
    return {"water_cold": "колодец, ручей или бутыль воды", "honey": "горшочек мёда в лавке или из сот на прессе"}.get(n, "")


def sec_food():
    by_res = defaultdict(list)
    for ings, res in FREC:
        by_res[res].append(ings)
    groups = defaultdict(list)
    for fid in F_ORDER:
        f = FOOD[fid]
        rows = []
        if fid in by_res:
            variants = " ИЛИ ".join(" + ".join(nm(n) for n in ings) for ings in by_res[fid])
            rows.append(("Рецепт (костёр, E)", variants))
            ingw = {}
            for ings in by_res[fid]:
                for n in ings:
                    if n not in ingw and food_where(n):
                        ingw[n] = f"{nm(n)}: {food_where(n)}"
            rows.append(("Где взять составляющие", "; ".join(list(ingw.values())[:6])))
        else:
            rows.append(("Где", f[5]))
            rows.append(("Как", "Собрать, найти или купить (место указано выше)"))
        use = use_text("food_" + fid)
        rows.append(("Зачем", f"еда: сытость {f[2]}" + (f", питьё {f[3]}" if f[3] else "") + (" | " + " | ".join(use) if use else "")))
        rows.append(("Цена", f"{f[4]} мон."))
        groups[F_KINDS.get(f[1], f[1])].append(card(f[0], icon_of("food_" + fid), sub=f[6], rows=rows))
    return groups


# ───────────────────────── HTML ─────────────────────────
CSS = """
:root { --paper:#f3e6c4; --ink:#3a2718; --soft:#6b4f36; --faint:rgba(58,39,24,.25); }
* { box-sizing:border-box; }
body { margin:0; background:#2b2118; color:var(--ink); font-family:'Palatino Linotype',Georgia,serif; }
header { background:linear-gradient(#3a2a1c,#2b2118); color:#f3e6c4; text-align:center; padding:28px 16px 18px; border-bottom:4px solid #8a6a3a; }
header h1 { font-family:Gabriola,'Palatino Linotype',serif; font-size:56px; margin:0; font-weight:normal; }
header p { margin:6px 0 14px; color:#d8c39a; font-style:italic; }
#q { width:min(560px,90vw); padding:10px 16px; font-size:18px; border-radius:22px; border:2px solid #8a6a3a; background:#f3e6c4; color:var(--ink); font-family:inherit; }
nav { display:flex; flex-wrap:wrap; justify-content:center; gap:8px; padding:12px; background:#2b2118; position:sticky; top:0; z-index:5; border-bottom:2px solid #5a4028; }
nav a { padding:5px 12px; border-radius:10px; background:var(--paper); color:var(--ink); text-decoration:none; font-size:16px; border:2px solid #8a6a3a; }
nav a:hover { background:#fff3d4; }
nav small { color:var(--soft); }
main { max-width:1400px; margin:0 auto; padding:18px; }
section.sec { background:var(--paper); border:3px solid #8a6a3a; border-radius:6px; margin:26px 0; padding:22px 28px 30px; box-shadow:0 6px 24px rgba(0,0,0,.45), inset 0 0 60px rgba(150,110,50,.25); }
section.sec > h2 { font-family:Gabriola,'Palatino Linotype',serif; font-weight:normal; font-size:46px; margin:0; text-align:center; }
.intro { text-align:center; font-style:italic; color:var(--soft); max-width:900px; margin:4px auto 14px; }
h3 { font-size:24px; margin:24px 0 4px; border-bottom:1px solid var(--faint); padding-bottom:4px; }
.grid { display:grid; grid-template-columns:repeat(auto-fill,minmax(420px,1fr)); gap:12px; margin-top:12px; }
.card { display:flex; gap:12px; background:rgba(255,250,235,.55); border:1px solid var(--faint); border-radius:6px; padding:10px; }
.card .pic { flex:0 0 64px; height:64px; display:flex; align-items:center; justify-content:center; background:radial-gradient(circle,#fff6dc 30%,#ead7a8 100%); border:1px solid var(--faint); border-radius:10px; }
.card .pic img { max-width:52px; max-height:52px; image-rendering:pixelated; }
.card h4 { margin:0; font-size:19px; }
.card .sub { font-style:italic; color:var(--soft); font-size:13px; }
.card p { margin:3px 0 0; font-size:14.5px; line-height:1.3; }
.card p b { color:#7a2a32; }
.tag { display:inline-block; font-size:12px; padding:1px 7px; border-radius:9px; background:#5a7a4a; color:#fff; margin-left:6px; vertical-align:middle; }
.rar1 { box-shadow:inset 3px 0 0 #7ab0f0; } .rar2 { box-shadow:inset 3px 0 0 #c890f0; } .rar3 { box-shadow:inset 3px 0 0 #f8c040; background:rgba(255,240,190,.7); }
.hide { display:none !important; }
footer { color:#b8a07a; text-align:center; padding:20px; font-style:italic; }
.top { position:fixed; right:18px; bottom:18px; background:var(--paper); border:2px solid #8a6a3a; border-radius:50%; width:48px; height:48px; display:flex; align-items:center; justify-content:center; text-decoration:none; color:var(--ink); font-size:24px; }
"""

JS = """
const q = document.getElementById('q');
q.addEventListener('input', () => {
  const t = q.value.trim().toLowerCase();
  document.querySelectorAll('.card').forEach(c => c.classList.toggle('hide', t && !c.dataset.s.includes(t)));
  document.querySelectorAll('.grp').forEach(g => g.classList.toggle('hide', t && !g.querySelector('.card:not(.hide)')));
  document.querySelectorAll('section.sec').forEach(s => s.classList.toggle('hide', t && !s.querySelector('.card:not(.hide)')));
});
"""


TREES27 = [("tree_a", "Дуб", "луга у дома, светлые рощи, земли рыцарей"), ("tree_b", "Клён", "луга, светлые рощи"),
           ("tree_c", "Липа", "сумрачные леса, луга, болота"), ("tree_d", "Вяз", "луга, рощи, осенний лес"),
           ("tree_apple", "Яблоня", "двор травницы, деревня кошкодевочек"), ("tree_autumn", "Осенний клён", "осенний лес, луга"),
           ("tree_autumn2", "Рыжий клён", "осенний лес"), ("tree_blossom", "Сакура", "цветущие рощи, земли Восходящего Солнца"),
           ("tree_unicorn", "Единорожье дерево", "земли единорогов"), ("tree_birch", "Берёза", "берёзовые рощи, земли единорогов")]
FLOWERS27 = [("flowers_pink", "Розовая гвоздичка", "луга, цветущие рощи, поля"), ("flowers_white", "Нивяник (луговая ромашка)", "луга и поля у дома"),
             ("flowers_blue", "Василёк луговой", "луга, поля, берёзовые рощи"), ("flowers_yellow", "Лютик едкий", "луга и поля")]


def sec_nature27():
    """v27: деревья, луговые цветы и травы так, как они растут в мире."""
    trees = [card(n, img(k), rows=[("Где растёт", w), ("Зачем", "рубить топором: брёвна, кора, листья (см. «Места добычи»)"),
                                   ("Вид", "ствол в стиле яблока: мягкий цветной контур, кора с волокнами, без дупла")]) for k, n, w in TREES27]
    fl = [card(n, img(k), rows=[("Где растёт", w), ("Зачем", "украшение луга, собрать нельзя")]) for k, n, w in FLOWERS27]
    hw = []
    for hid in H_ORDER:
        p = img("herbw_" + hid)
        if p:
            hw.append(card(HERBS[hid]["name"], p, sub="так растёт в мире",
                           rows=[("Где", HERBS[hid]["where"]), ("Как", "подойти и нажать E")]))
    return [("Деревья", trees), ("Луговые цветы", fl), ("Травы в мире", hw)]


def grp(title, cards, about=""):
    if not cards:
        return ""
    ab = f'<p class="intro">{esc(about)}</p>' if about else ""
    return f'<div class="grp"><h3>{esc(title)} <small>({len(cards)})</small></h3>{ab}<div class="grid">{"".join(cards)}</div></div>'


def section(sid, title, intro, groups):
    n = sum(len(c) for _, c in groups)
    body = "".join(grp(t, c) for t, c in groups)
    return sid, title, n, f'<section class="sec" id="{sid}"><h2>{esc(title)}</h2><p class="intro">{esc(intro)}</p>{body}</section>'


def build():
    secs = []
    mg = sec_mats()
    order = ["wood", "earth", "stone", "glass", "metal", "fiber", "animal", "sea", "gem", "misc"]
    keys = [k for k in order if k in mg] + [k for k in mg if k not in order]
    secs.append(section("mats", "Материалы", "Каждый материал: где его взять, как добыть и для чего он нужен. «Нужно для» — мастерские, постройки, блюда и зелья.",
                        [(CAT_NAME.get(k, k), mg[k]) for k in keys]))
    secs.append(section("ores", "Руды и самоцветы силы", "Магические руды — только киркой.", [("Магические руды", sec_ores())]))
    secs.append(section("nodes", "Места добычи", "Что лежит в мире и как это собрать. Все места со временем отрастают.",
                        [("Вопрос гиду: как добывать дерево", sec_wood_faq()), ("Места добычи", sec_nodes()), ("Рубка деревьев", sec_trees_chop())]))
    secs.append(section("herbs", "Травы", "Где растёт, как сорвать и для чего нужна каждая трава.", [("Травы", sec_herbs())]))
    secs.append(section("shrooms", "Грибы", "Где растёт каждый гриб и что с ним делать.", [("Грибы", sec_shrooms())]))
    secs.append(section("feathers", "Перья птиц", "Перья дают свойства для котла. Птицу надо вспугнуть, а перо — подобрать.", [("Перья", sec_feathers())]))
    secs.append(section("bugs", "Насекомые и листья", "Насекомых ловят сачком, листья собирают с крон. Всё идёт в котёл.",
                        [("Насекомые", sec_bugs()), ("Листья деревьев", sec_leaves())]))
    secs.append(section("animals", "Звери и малыши", "Где живёт каждый зверь, чем его приманить, что он даёт в загоне и как выглядит его малыш.",
                        [("Звери", sec_animals())]))
    secs.append(section("traps", "Ловушки и добыча со зверей", "Поймай зверя — и вычеши из него пух для пряжи.", [("Ловушки", sec_traps())]))
    pg = sec_potions()
    secs.append(section("potions", "Рецепты зелий", "Как сварить каждое зелье. Пример — один из способов, получить можно и по-другому: смотри «Что нужно».",
                        [(k, pg[k]) for k in RARITY if k in pg]))
    fg = sec_food()
    secs.append(section("food", "Еда и блюда", "Где взять каждый продукт и как приготовить блюдо (на костре: E, берётся первый подходящий рецепт).",
                        list(fg.items())))
    secs.append(section("stations", "Рецепты мастерских", "Станция строится в хозяйстве; кладёшь материалы — получаешь изделие.", sec_stations()))
    bg, kb, plot = sec_build()
    secs.append(section("build", "Постройки", "Что нужно для каждой постройки. Строить — через верстак.",
                        list(bg.items()) + [("Постройки королевства", kb), ("Расширение участка", plot)]))
    secs.append(section("nature", "Деревья, луговые цветы и травы в мире",
                        "Как всё выглядит в мире (стиль яблока). Травы и цветы растут прямо из земли: под ними тень-лунка и травинки в цвет травы своего края.",
                        sec_nature27()))
    ctl = [
        ("B", "Мебель и комнаты", "Строительство внутри дома."), ("J", "Книга травника", "Травы, рецепты, птицы."),
        ("I", "Крафт", "Окно крафта."), ("M", "Карта", "Открывается по мере прогулок."), ("Q", "Задания", "Список заданий."),
        ("L", "Летопись", "Что с тобой случилось."), ("K", "Навыки", "Прокачка."), ("H", "Гримуар", "Стихии и заклинания."),
        ("O", "Королевство", "Работники и приказы."), ("T", "Убрать свою постройку", "Зажми T и кликни по своей постройке рядом: она исчезнет, а вещь вернётся в сумку (вещи из сундука — тоже)."), ("E", "Действие / поговорить", "У трав, зверей, жителей, станций."),
        ("Shift", "Бег", "Быстрее, но сильнее устаёшь."), ("Tab", "Сумка", "Пояс — клавиши 1–8."),
    ]
    cc = [card(f"[{k}] {n}", "", rows=[("Что это", d), ("Как", "значок с этой буквой всегда виден справа вверху экрана; клавишу можно сменить в Esc → Настройки → Управление")]) for k, n, d in ctl]
    cc.append(card("Мира, гид", "", rows=[("Где", "стоит у входа в дом"), ("Зачем", "E — расскажет про ходьбу, сбор трав, зелья, дом, карту, зверей и сохранение"),
        ("Обучение-задание", "«Научи меня!» — задание «Дровосек»: сделать топор, взять в руку, нарубить 6 брёвен, потом сделать и поставить верстак. Слева на экране список шагов (текущий — жёлтый), дерево подсвечивается стрелкой. Награда — 25 монет.")]))
    cc.append(card("Значки меню справа вверху", "", rows=[("Как", "значки книги, крафта, мебели, карты, заданий, летописи, навыков и королевства нажимаются мышью — как клавиши")]))
    cc.append(card("Столы и станки", "", rows=[("Размер", "верстак, стол изучения, кузница, пилорама, ткацкий станок и другие станки теперь рисуются меньше — по росту героини")]))
    cc.append(card("Полный экран и разрешение", "", rows=[("Где", "Esc → Настройки → Видео"), ("Что", "полный экран не сбрасывается при старте игры; разрешение окна от 1280x720 до 2560x1440")]))
    cc.append(card("Сбор трав", "", rows=[("Что", "когда все растения в окне собраны или потеряны, окно закрывается само")]))
    secs.append(section("controls", "Управление и обучение", "Все клавиши и подсказки; значки меню видны на экране.", [("Клавиши и обучение", cc)]))
    nav = "".join(f'<a href="#{sid}">{esc(t)} <small>{n}</small></a>' for sid, t, n, _ in secs)
    total = sum(n for _, _, n, _ in secs)
    page = f"""<!DOCTYPE html>
<html lang="ru"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Лесной травник — где взять и зачем</title><style>{CSS}</style></head>
<body id="up"><header><h1>Где взять и зачем нужно</h1>
<p>Справочник по добыче и рецептам: {total} записей. Для каждого материала — где, как и зачем.</p>
<input id="q" type="search" placeholder="Поиск: глина, мята, кирка, брус…"></header>
<nav>{nav}</nav><main>{"".join(b for *_, b in secs)}</main>
<footer>Собрано из файлов игры автоматически: game/tools/guide26.py. Чтобы обновить — запусти скрипт заново.</footer>
<a class="top" href="#up" title="наверх">↑</a><script>{JS}</script></body></html>"""
    OUT.mkdir(exist_ok=True)
    (OUT / "index.html").write_text(page, encoding="utf-8")
    print(f"{OUT / 'index.html'}: {total} записей, {len(secs)} разделов")
    for sid, t, n, _ in secs:
        print(f"  {t}: {n}")
    nowhere = [i for i in M_ORDER if not WHERE.get(i)]
    print(f"материалов без найденного источника: {len(nowhere)}")
    if nowhere:
        print("  ", ", ".join(nowhere[:60]))


if __name__ == "__main__":
    build()

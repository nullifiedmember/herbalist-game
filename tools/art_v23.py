"""v23: мебель (много стилей), оружие (сотни), монстры, домашние звери, морские рыбы и акулы,
плитки подземелий, книги, приколы. Рисует картинки в art/ и пишет данные в v23_data.gd —
один источник правды для игры и для арта.

Запуск: python tools/art_v23.py [furn|wpn|mon|farm|fish|dun|misc|data|all]
"""
import os
import sys
import json
import math
import numpy as np
from PIL import Image
sys.path.insert(0, os.path.dirname(__file__))
from px import Canvas, ramp, hx, mix, sheet, OUTLINE

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ART = os.path.join(ROOT, "art")


def R(c):
    return ramp(c)


def dark(c, k=0.35):
    return mix(c if len(c) == 4 else tuple(c) + (255,), (20, 14, 30, 255), k)


def C(s):
    return hx(s) + (255,)


# =====================================================================================  МЕБЕЛЬ
# стиль: название (род. падеж прилагательного по родам), дерево, ткань, металл, акцент, цена-множитель, уровень
STYLES = {
    "straw": {"adj": ["Соломенная", "Соломенный", "Соломенное"], "wood": "b89a58", "fab": "d8c070", "met": "6a5a40", "acc": "a08040", "tier": 0},
    "rough": {"adj": ["Грубая", "Грубый", "Грубое"], "wood": "8a6a48", "fab": "b0a080", "met": "6a6a70", "acc": "7a5a3a", "tier": 1},
    "simple": {"adj": ["Простая", "Простой", "Простое"], "wood": "b07a48", "fab": "e0d8c8", "met": "8a8a90", "acc": "c09060", "tier": 2},
    "cozy": {"adj": ["Уютная", "Уютный", "Уютное"], "wood": "c08850", "fab": "e07890", "met": "b08040", "acc": "f0c060", "tier": 3},
    "cat": {"adj": ["Кошачья", "Кошачий", "Кошачье"], "wood": "d8a070", "fab": "f0b0c8", "met": "c09060", "acc": "fff0f4", "tier": 4},
    "japan": {"adj": ["Японская", "Японский", "Японское"], "wood": "9a5a3a", "fab": "e8dcc0", "met": "3a2a2a", "acc": "c0302a", "tier": 4},
    "dwarf": {"adj": ["Дворфийская", "Дворфийский", "Дворфийское"], "wood": "7a5a3a", "fab": "8a4a2a", "met": "c07a3a", "acc": "9a9aa0", "tier": 4},
    "elven": {"adj": ["Эльфийская", "Эльфийский", "Эльфийское"], "wood": "e0d0a8", "fab": "6aa05a", "met": "d8c070", "acc": "a0e080", "tier": 5},
    "sea": {"adj": ["Морская", "Морской", "Морское"], "wood": "7a9ab0", "fab": "3a7ab8", "met": "d8c8a0", "acc": "f0a8a8", "tier": 5},
    "gothic": {"adj": ["Готическая", "Готический", "Готическое"], "wood": "3e2c40", "fab": "8a1a30", "met": "a0a0b0", "acc": "c03040", "tier": 5},
    "mage": {"adj": ["Магическая", "Магический", "Магическое"], "wood": "4a3a70", "fab": "5a4ab0", "met": "e0c060", "acc": "80e8ff", "tier": 6},
    "royal": {"adj": ["Королевская", "Королевский", "Королевское"], "wood": "7a3424", "fab": "b01e34", "met": "f0c840", "acc": "fff4c0", "tier": 7},
}
# категория: название, род (0 ж, 1 м, 2 ср), размер холста, что делает, преграда (x0,y0,w,h от ног), базовая цена
CATS = {
    "bed": ["кровать", 0, (44, 46), "sleep", (-20, -30, 40, 28), 30],
    "table": ["стол", 1, (48, 32), "", (-22, -14, 44, 12), 20],
    "chair": ["стул", 1, (18, 28), "", (-7, -6, 14, 5), 8],
    "wardrobe": ["шкаф", 1, (34, 46), "chest", (-16, -10, 32, 9), 26],
    "bookcase": ["книжный шкаф", 1, (40, 52), "book", (-19, -10, 38, 9), 28],
    "lamp": ["лампа", 0, (14, 34), "light", (-4, -4, 8, 4), 12],
    "rug": ["ковёр", 1, (64, 38), "flat", (0, 0, 0, 0), 14],
    "dresser": ["комод", 1, (36, 30), "chest", (-17, -9, 34, 8), 22],
    "plant": ["горшок с цветком", 1, (18, 26), "", (-6, -5, 12, 4), 9],
    "cabinet": ["тумбочка", 0, (22, 24), "", (-10, -6, 20, 5), 10],
}
CAT_STYLES = {k: [s for s in STYLES if s != "straw"] for k in CATS}
CAT_STYLES["bed"] = list(STYLES.keys())
CAT_STYLES["rug"] = list(STYLES.keys())


def motif(c, st, x, y, kind=None, col=None):
    """Маленький узор стиля в точке."""
    a = C(STYLES[st]["acc"]) if col is None else col
    if st == "cat":       # лапка
        c.dot(x, y + 1, a); c.dot(x + 1, y + 1, a); c.dot(x, y + 2, a); c.dot(x + 1, y + 2, a)
        c.dot(x - 1, y - 1, a); c.dot(x + 2, y - 1, a); c.dot(x + 0, y - 1, a) if False else None
        c.dot(x + 1, y - 2, a); c.dot(x, y - 2, a)
    elif st == "gothic":  # крестик-ромб
        for d in range(-2, 3):
            c.dot(x + d, y, a); c.dot(x, y + d, a)
    elif st == "elven":   # листок
        for d in range(3):
            c.dot(x + d, y - d, a); c.dot(x + d + 1, y - d, a)
        c.dot(x, y + 1, dark(a, 0.3))
    elif st == "royal":   # корона-лилия
        c.dot(x, y - 2, a); c.dot(x - 2, y - 1, a); c.dot(x + 2, y - 1, a)
        for d in range(-2, 3):
            c.dot(x + d, y, a)
        c.dot(x, y - 1, a)
    elif st == "mage":    # звёздочка
        c.dot(x, y, (255, 255, 255, 255)); c.dot(x - 1, y, a); c.dot(x + 1, y, a); c.dot(x, y - 1, a); c.dot(x, y + 1, a)
    elif st == "sea":     # ракушка
        for d in range(-2, 3):
            c.dot(x + d, y, a)
        c.dot(x - 1, y - 1, a); c.dot(x, y - 1, a); c.dot(x + 1, y - 1, a); c.dot(x, y - 2, a); c.dot(x, y + 1, dark(a))
    elif st == "cozy":    # сердечко
        for dx, dy in [(-1, -1), (1, -1), (-2, 0), (-1, 0), (0, 0), (1, 0), (2, 0), (-1, 1), (0, 1), (1, 1), (0, 2)]:
            c.dot(x + dx, y + dy, a)
    elif st == "japan":   # кружок-мон
        for dx, dy in [(-1, -1), (0, -1), (1, -1), (-1, 0), (1, 0), (-1, 1), (0, 1), (1, 1)]:
            c.dot(x + dx, y + dy, a)
    elif st == "dwarf":   # заклёпки
        c.dot(x - 2, y, a); c.dot(x + 2, y, a); c.dot(x, y, C(STYLES[st]["met"]))
    elif st in ("rough", "straw"):  # заплатка
        for dx in range(-1, 2):
            for dy in range(-1, 2):
                c.dot(x + dx, y + dy, dark(a, 0.15) if (dx + dy) % 2 else a)
    else:
        c.dot(x, y, a)


def wood_grain(c, m, st, seed=1):
    r = np.random.default_rng(seed)
    rw = R(STYLES[st]["wood"])
    ys, xs = np.nonzero(m)
    for y, x in zip(ys, xs):
        if r.random() < 0.10:
            c.px[y, x] = rw[1] if r.random() < 0.6 else rw[3]


def top_crest(c, st, x0, x1, y):
    """Навершие: ушки, шпили, листья, корона, кристалл, ракушка."""
    s = STYLES[st]
    w, mtl, a = s["wood"], C(s["met"]), C(s["acc"])
    cx = (x0 + x1) // 2
    if st == "cat":
        for ex in (x0 + 2, x1 - 7):
            m = c.poly([(ex, y + 1), (ex + 2.5, y - 6), (ex + 5, y + 1)])
            c.shade(m, R(w))
            c.dot(ex + 2, y - 2, C("f0a0b8")); c.dot(ex + 2, y - 1, C("f0a0b8")); c.dot(ex + 3, y - 1, C("f0a0b8"))
    elif st == "gothic":
        for k, sx in enumerate([x0 + 1, cx - 1, x1 - 3]):
            hgt = 9 if sx == cx - 1 else 6
            m = c.poly([(sx - 1, y + 1), (sx + 1.5, y - hgt), (sx + 4, y + 1)])
            c.shade(m, R(s["wood"]))
            c.dot(sx + 1, y - hgt + 1, mtl)
    elif st == "elven":
        m = c.ellipse(cx, y + 1, (x1 - x0) / 2 - 1, 5)
        m &= c.rect(0, 0, c.w, y + 1)
        c.shade(m, R(s["wood"]))
        for k in range(4):
            motif(c, st, x0 + 3 + k * max(3, (x1 - x0 - 6) // 4), y - 1)
    elif st == "royal":
        m = c.rect(cx - 5, y - 4, cx + 6, y + 1)
        m |= c.poly([(cx - 5, y - 4), (cx - 4, y - 8), (cx - 2, y - 4)])
        m |= c.poly([(cx - 1, y - 4), (cx + 0.5, y - 9), (cx + 2, y - 4)])
        m |= c.poly([(cx + 3, y - 4), (cx + 5, y - 8), (cx + 6, y - 4)])
        c.shade(m, R(s["met"]))
        c.dot(cx, y - 2, C("e02040")); c.dot(cx - 3, y - 2, C("40a0f0")); c.dot(cx + 3, y - 2, C("40c060"))
    elif st == "mage":
        m = c.poly([(cx - 2, y + 1), (cx, y - 8), (cx + 2, y + 1)])
        c.shade(m, R(s["acc"]))
        c.dot(cx, y - 6, (255, 255, 255, 255))
        motif(c, st, x0 + 3, y - 2); motif(c, st, x1 - 4, y - 2)
    elif st == "sea":
        m = c.ellipse(cx, y, 6, 5) & c.rect(0, 0, c.w, y + 1)
        c.shade(m, R(s["acc"]))
        for k in range(-2, 3):
            c.line([(cx, y), (cx + k * 2.5, y - 4)], dark(C(s["acc"]), 0.25))
    elif st == "dwarf":
        m = c.rect(x0, y - 3, x1, y + 1)
        c.shade(m, R(s["acc"]))
        for k in range(x0 + 2, x1 - 1, 4):
            c.dot(k, y - 2, mtl)
    elif st == "japan":
        m = c.rect(x0 - 1, y - 2, x1 + 1, y + 1)
        c.shade(m, R(s["met"]))
    elif st == "cozy":
        motif(c, st, cx, y - 3)


def draw_bed(st):
    s = STYLES[st]
    W, H = CATS["bed"][2]
    c = Canvas(W, H)
    if st == "straw":
        # куча соломы с мешковиной
        m = c.ellipse(22, 30, 20, 13)
        c.shade(m, R(s["wood"]))
        r = np.random.default_rng(3)
        for i in range(70):
            x, y = r.integers(4, 40), r.integers(19, 42)
            if m[y, x]:
                c.line([(x, y), (x + r.integers(-3, 4), y - r.integers(1, 3))], R(s["fab"])[r.integers(1, 5)])
        sack = c.poly([(9, 22), (33, 20), (36, 34), (11, 37)])
        c.shade(sack, R("b8a888"), flat=0.3)
        for (x, y) in [(15, 26), (24, 28), (30, 24), (18, 33)]:
            c.dot(x, y, R("b8a888")[1])
        pil = c.ellipse(14, 22, 6, 3.5)
        c.shade(pil, R("d8d0b8"))
        c.outline()
        return c
    low = st == "japan"
    top = 14 if not low else 18
    if not low:
        hb = c.rect(3, 6, 41, top + 6)
        c.shade(hb, R(s["wood"]), gy=0.2)
        wood_grain(c, hb, st, 7)
        motif(c, st, 22, 11)
        top_crest(c, st, 3, 41, 6)
        for px_ in (3, 38):
            p = c.rect(px_, 6, px_ + 3, 44)
            c.shade(p, R(s["wood"]))
    frame = c.rect(4, top + 18, 40, 44 if not low else 42)
    c.shade(frame, R(s["wood"]))
    mat = c.rect(5, top, 39, 40 if not low else 39)
    c.shade(mat, R(s["fab"]), gy=0.25)
    # подушки
    for px_ in ([10, 34] if st in ("royal", "gothic", "mage") else [22]):
        pil = c.ellipse(px_ if px_ != 22 else 22, top + 4, 6 if px_ != 22 else 12, 3.5)
        c.shade(pil, R("f4f0e8" if st not in ("gothic",) else "c8c0d0"))
    # одеяло с отворотом и узором
    bl = c.rect(5, top + 10, 39, 40 if not low else 39)
    c.shade(bl, R(s["fab"]), gy=0.3)
    fold = c.rect(5, top + 9, 39, top + 12)
    c.shade(fold, R(s["acc"] if st not in ("simple", "rough") else "f0ece0"), flat=0.4)
    for k, x in enumerate(range(10, 36, 8)):
        motif(c, st, x, top + 19 + (k % 2) * 6)
    if st == "royal":
        c.line([(5, top + 26), (38, top + 26)], C(s["met"]))
    if st in ("royal", "gothic"):
        # балдахин-столбики
        for px_ in (3, 38):
            p = c.rect(px_, 0, px_ + 3, 8)
            c.shade(p, R(s["wood"]))
            c.dot(px_ + 1, 0, C(s["met"]))
    c.outline()
    return c


def draw_table(st):
    s = STYLES[st]
    W, H = CATS["table"][2]
    c = Canvas(W, H)
    low = st == "japan"
    ty = 8 if not low else 14
    for lx in (5, 39):
        leg = c.rect(lx, ty + 6, lx + 4, H - 1)
        c.shade(leg, R(s["wood"]))
    if st in ("royal", "mage", "gothic", "elven"):
        cloth = c.rect(3, ty + 4, 45, ty + 16)
        c.shade(cloth, R(s["fab"]), gy=0.3)
        for x in range(4, 45, 4):
            c.dot(x, ty + 16, C(s["acc"] if st != "royal" else s["met"]))
    ap = c.rect(4, ty + 6, 44, ty + 11)
    if st not in ("royal", "mage", "gothic", "elven"):
        c.shade(ap, R(s["wood"]))
        motif(c, st, 24, ty + 8)
    topm = c.ellipse(24, ty + 2, 22, 6) if st in ("elven", "sea", "cozy") else c.rect(2, ty - 3, 46, ty + 6)
    c.shade(topm, R(s["wood"]), gy=0.15)
    wood_grain(c, topm, st, 11)
    if st == "dwarf":
        for x in range(4, 46, 6):
            c.dot(x, ty, C(s["met"]))
    # на столе: свеча / ваза / чашка
    item = {"royal": "candle", "gothic": "candle", "mage": "orb", "elven": "vase", "cat": "cup", "sea": "shell", "cozy": "vase", "japan": "cup"}.get(st, "")
    if item == "candle":
        c.fill(c.rect(23, ty - 9, 25, ty - 2), C("f4ecd0")); c.dot(23, ty - 10, C("ffc040")); c.dot(24, ty - 11, C("ffe080"))
        c.fill(c.rect(21, ty - 3, 27, ty - 1), C(s["met"]))
    elif item == "orb":
        c.shade(c.ellipse(24, ty - 4, 3.5, 3.5), R(s["acc"]))
        c.dot(23, ty - 6, (255, 255, 255, 255))
    elif item == "vase":
        c.shade(c.ellipse(24, ty - 3, 2.5, 3), R(s["acc"]))
        for dx in (-2, 0, 2):
            c.dot(24 + dx, ty - 7, C("e05070")); c.dot(24 + dx, ty - 6, C("60a040"))
    elif item == "cup":
        c.shade(c.rect(22, ty - 4, 26, ty), R("f4f0e8")); c.dot(27, ty - 3, C("f4f0e8"))
    elif item == "shell":
        motif(c, "sea", 24, ty - 2)
    c.outline()
    return c


def draw_chair(st):
    s = STYLES[st]
    W, H = CATS["chair"][2]
    c = Canvas(W, H)
    if st == "japan":
        cush = c.ellipse(9, 22, 7, 4)
        c.shade(cush, R(s["fab"]))
        motif(c, st, 9, 21)
        c.outline()
        return c
    back = c.rect(3, 4, 15, 16)
    c.shade(back, R(s["wood"]))
    if st == "cat":
        for ex in (3, 11):
            c.shade(c.poly([(ex, 5), (ex + 2, 0), (ex + 4, 5)]), R(s["wood"]))
    elif st == "gothic":
        c.shade(c.poly([(3, 5), (9, -2), (15, 5)]), R(s["wood"]))
    elif st == "royal":
        c.shade(c.rect(3, 2, 15, 5), R(s["met"]))
    inner = c.rect(5, 6, 13, 14)
    c.shade(inner, R(s["fab"] if st not in ("rough", "simple") else s["wood"]), flat=0.3)
    motif(c, st, 9, 10)
    seat = c.rect(2, 15, 16, 19)
    c.shade(seat, R(s["fab"] if st not in ("rough",) else s["wood"]))
    for lx in (2, 14):
        c.shade(c.rect(lx, 19, lx + 2, H - 1), R(s["wood"]))
    c.outline()
    return c


def draw_wardrobe(st):
    s = STYLES[st]
    W, H = CATS["wardrobe"][2]
    c = Canvas(W, H)
    body = c.rect(2, 8, 32, H - 2)
    c.shade(body, R(s["wood"]), gy=0.2)
    wood_grain(c, body, st, 5)
    for x0 in (4, 18):
        d = c.rect(x0, 11, x0 + 12, H - 6)
        c.shade(d, R(s["wood"]), flat=0.5)
        c.inner_line(d, dark(C(s["wood"]), 0.4))
        motif(c, st, x0 + 6, 20)
    c.dot(16, 26, C(s["met"])); c.dot(18, 26, C(s["met"]))
    c.shade(c.rect(1, 6, 33, 10), R(s["wood"]))
    top_crest(c, st, 2, 32, 6)
    c.shade(c.rect(3, H - 2, 6, H), R(s["wood"])); c.shade(c.rect(28, H - 2, 31, H), R(s["wood"]))
    c.outline()
    return c


BOOK_COLS = ["c03838", "3858c0", "38a048", "d0a030", "8040b0", "e07030", "40a0a0", "a03070"]


def draw_bookcase(st):
    s = STYLES[st]
    W, H = CATS["bookcase"][2]
    c = Canvas(W, H)
    body = c.rect(2, 8, 38, H - 1)
    c.shade(body, R(s["wood"]), gy=0.15)
    r = np.random.default_rng(len(st) * 13)
    for row in range(4):
        y0 = 11 + row * 10
        sh = c.rect(5, y0, 35, y0 + 8)
        c.fill(sh, dark(C(s["wood"]), 0.55))
        x = 5
        while x < 34:
            bw = int(r.integers(2, 4))
            bh = int(r.integers(5, 9))
            col = BOOK_COLS[int(r.integers(0, len(BOOK_COLS)))]
            if st == "mage" and r.random() < 0.3:
                col = s["acc"]
            if st == "gothic":
                col = ["5a1a2a", "2a2a3a", "4a3a5a", "8a7a6a"][int(r.integers(0, 4))]
            bm = c.rect(x, y0 + 8 - bh, min(35, x + bw), y0 + 8)
            c.shade(bm, R(col), light=(-1, 0), gy=0.0)
            c.dot(x, y0 + 8 - bh + 1, C("f0d890"))
            x += bw + (1 if r.random() < 0.2 else 0)
        c.shade(c.rect(4, y0 + 8, 36, y0 + 10), R(s["wood"]))
    top_crest(c, st, 2, 38, 8)
    c.shade(c.rect(1, 6, 39, 9), R(s["wood"]))
    c.outline()
    return c


def draw_lamp(st):
    s = STYLES[st]
    W, H = CATS["lamp"][2]
    c = Canvas(W, H)
    c.shade(c.rect(3, H - 3, 11, H), R(s["met"] if st not in ("rough", "simple") else s["wood"]))
    c.shade(c.rect(6, 12, 8, H - 2), R(s["met"] if st not in ("rough", "simple", "japan") else s["wood"]))
    if st == "japan":
        sh = c.rect(2, 2, 12, 16)
        c.shade(sh, R("f4e8c8"), flat=0.5)
        for y in (5, 9, 13):
            c.line([(2, y), (11, y)], C("c8b088"))
        motif(c, st, 7, 9)
    elif st in ("gothic", "royal"):
        for x in (2, 7, 12):
            c.shade(c.rect(x - 1, 6, x + 1, 12), R("f4ecd0"))
            c.dot(x - 1, 4, C("ffb040")); c.dot(x, 3, C("ffe080")); c.dot(x, 5, C("ffd060"))
        c.shade(c.rect(0, 11, 14, 13), R(s["met"]))
    elif st == "mage":
        c.shade(c.ellipse(7, 6, 5, 5), R(s["acc"]))
        c.dot(5, 4, (255, 255, 255, 255)); c.dot(6, 4, (255, 255, 255, 255))
    else:
        sh = c.poly([(1, 13), (4, 3), (10, 3), (13, 13)])
        c.shade(sh, R(s["fab"]))
        motif(c, st, 7, 8)
        c.fill(c.rect(4, 13, 10, 15), C("fff0b0"))
    c.outline()
    return c


def draw_rug(st):
    s = STYLES[st]
    W, H = CATS["rug"][2]
    c = Canvas(W, H)
    oval = st in ("cozy", "cat", "elven", "sea", "straw")
    m = c.ellipse(32, 19, 31, 18) if oval else c.rect(1, 2, 63, 36)
    base = s["fab"] if st != "straw" else "c8b070"
    c.shade(m, R(base), flat=0.6)
    inner = c.ellipse(32, 19, 25, 13) if oval else c.rect(6, 6, 58, 32)
    c.fill(inner & ~(c.ellipse(32, 19, 23, 11) if oval else c.rect(8, 8, 56, 30)), C(s["acc"]))
    if st == "straw":
        for y in range(4, 36, 3):
            c.line([(4, y), (60, y)], R(base)[1])
    for k, (x, y) in enumerate([(20, 19), (32, 19), (44, 19), (26, 13), (38, 25)]):
        motif(c, st, x, y)
    if not oval:
        for x in range(2, 63, 3):
            c.dot(x, 1, C(s["acc"])); c.dot(x, 37, C(s["acc"]))
    c.outline()
    return c


def draw_dresser(st):
    s = STYLES[st]
    W, H = CATS["dresser"][2]
    c = Canvas(W, H)
    body = c.rect(2, 5, 34, H - 2)
    c.shade(body, R(s["wood"]), gy=0.2)
    for k in range(3):
        d = c.rect(4, 8 + k * 6, 32, 13 + k * 6)
        c.shade(d, R(s["wood"]), flat=0.5)
        c.inner_line(d, dark(C(s["wood"]), 0.4))
        c.dot(17, 10 + k * 6, C(s["met"])); c.dot(18, 10 + k * 6, C(s["met"]))
    c.shade(c.rect(1, 3, 35, 6), R(s["wood"]))
    top_crest(c, st, 6, 30, 3)
    motif(c, st, 8, 22)
    c.shade(c.rect(3, H - 2, 6, H), R(s["wood"])); c.shade(c.rect(30, H - 2, 33, H), R(s["wood"]))
    c.outline()
    return c


def draw_plant(st):
    s = STYLES[st]
    W, H = CATS["plant"][2]
    c = Canvas(W, H)
    pot = c.poly([(4, 15), (14, 15), (12, H - 1), (6, H - 1)])
    c.shade(pot, R(s["acc"] if st in ("cat", "sea", "mage", "royal", "cozy") else s["wood"]))
    motif(c, st, 9, 19, col=C(s["met"]))
    lv = "4a9a40" if st != "gothic" else "3a5a3a"
    for (x, y, rx, ry) in [(9, 9, 3, 6), (5, 11, 3, 3), (13, 11, 3, 3), (7, 6, 2, 3), (11, 5, 2, 3)]:
        c.shade(c.ellipse(x, y, rx, ry), R(lv))
    fl = {"gothic": "802040", "mage": "80e8ff", "sea": "f08080", "royal": "f0c840", "elven": "f0f0a0", "japan": "f0a0c0"}.get(st, "e05070")
    for (x, y) in [(9, 3), (5, 8), (13, 7)]:
        c.dot(x, y, C(fl)); c.dot(x + 1, y, C(fl)); c.dot(x, y + 1, dark(C(fl), 0.2))
    c.outline()
    return c


def draw_cabinet(st):
    s = STYLES[st]
    W, H = CATS["cabinet"][2]
    c = Canvas(W, H)
    body = c.rect(2, 6, 20, H - 2)
    c.shade(body, R(s["wood"]))
    d = c.rect(4, 9, 18, H - 5)
    c.shade(d, R(s["wood"]), flat=0.5)
    c.inner_line(d, dark(C(s["wood"]), 0.4))
    motif(c, st, 11, 14)
    c.dot(16, 15, C(s["met"]))
    c.shade(c.rect(1, 4, 21, 7), R(s["wood"]))
    c.shade(c.ellipse(15, 2, 2.5, 2.5), R("fff0b0"))     # ночник
    c.shade(c.rect(3, H - 2, 5, H), R(s["wood"])); c.shade(c.rect(17, H - 2, 19, H), R(s["wood"]))
    c.outline()
    return c


DRAW = {"bed": draw_bed, "table": draw_table, "chair": draw_chair, "wardrobe": draw_wardrobe, "bookcase": draw_bookcase,
        "lamp": draw_lamp, "rug": draw_rug, "dresser": draw_dresser, "plant": draw_plant, "cabinet": draw_cabinet}

# старая обстановка из пака (dp_*) — тоже мебель «Деревенская»
DP_FURN = {
    "dp_bed": ["Деревенская кровать", "sleep", (-20, -30, 40, 28), 40, 3], "dp_bookcase": ["Деревенский книжный шкаф", "book", (-23, -14, 46, 14), 40, 3],
    "dp_cupboard": ["Буфет", "", (-11, -12, 22, 12), 25, 2], "dp_dresser": ["Деревенский комод", "chest", (-18, -12, 36, 12), 30, 3],
    "dp_wardrobe": ["Деревенский шкаф", "chest", (-16, -12, 32, 12), 30, 3], "dp_pot_red": ["Красный цветок", "", (-5, -5, 10, 5), 8, 2],
    "dp_pot_pink": ["Розовый цветок", "", (-6, -5, 12, 5), 8, 2], "dp_flowerbox": ["Ящик с цветами", "", (-17, -6, 34, 6), 14, 2],
    "dp_clock": ["Часы", "", (0, 0, 0, 0), 20, 3], "dp_shelf": ["Стеллаж", "", (-15, -10, 30, 10), 22, 2],
    "dp_nightstand": ["Деревенская тумбочка", "", (-12, -8, 24, 8), 14, 2], "dp_table": ["Длинный стол", "", (-34, -14, 68, 14), 30, 2],
    "dp_table_round": ["Круглый стол", "", (-20, -14, 40, 12), 24, 2], "dp_cushions": ["Подушки для сидения", "", (0, 0, 0, 0), 10, 2],
    "dp_basket_oranges": ["Корзина апельсинов", "food", (-8, -6, 16, 6), 10, 2], "dp_basket_greens": ["Корзина зелени", "", (-8, -6, 16, 6), 10, 2],
    "dp_basket_carrots": ["Корзина моркови", "", (-8, -6, 16, 6), 10, 2], "dp_horse": ["Деревянная лошадка", "", (-8, -6, 16, 6), 18, 3],
    "dp_chest": ["Деревенский сундук", "chest", (-9, -8, 18, 8), 20, 2], "dp_chest_small": ["Маленький сундучок", "chest", (-8, -8, 16, 8), 14, 1],
    "dp_barrel": ["Бочка", "", (-8, -8, 16, 8), 12, 1], "dp_rug": ["Красный ковёр", "flat", (0, 0, 0, 0), 20, 2],
    "dp_sink_table": ["Умывальник", "water", (-16, -10, 32, 10), 24, 2], "dp_pic_land": ["Картина: горы", "wall", (0, 0, 0, 0), 30, 3],
    "dp_pic_a": ["Картинка с тыквой", "wall", (0, 0, 0, 0), 12, 2], "dp_pic_b": ["Картинка с цветами", "wall", (0, 0, 0, 0), 12, 2],
    "dp_window_blue": ["Шторы синие", "wall", (0, 0, 0, 0), 16, 2],
}
# особые штуки
EXTRA_FURN = {
    "stove": ["Печка", "stove", (-14, -10, 28, 10), 40, 2], "cat_tree": ["Кошачье дерево", "", (-10, -6, 20, 6), 30, 4],
    "cat_basket": ["Кошачья корзинка-лежанка", "", (0, 0, 0, 0), 14, 3], "aquarium": ["Аквариум", "", (-14, -8, 28, 8), 60, 5],
    "piano": ["Пианино", "music", (-20, -10, 40, 10), 120, 6], "fireplace": ["Камин", "light", (-22, -10, 44, 10), 80, 5],
    "armor_stand": ["Стойка с доспехом", "", (-8, -6, 16, 6), 50, 5], "globe": ["Глобус", "", (-6, -5, 12, 5), 36, 4],
    "potion_rack": ["Стеллаж для зелий", "", (-14, -8, 28, 8), 34, 4], "throne": ["Трон", "", (-14, -8, 28, 8), 300, 8],
}


def draw_extra(k):
    if k == "stove":
        c = Canvas(30, 34)
        b = c.rect(1, 8, 29, 34)
        c.shade(b, R("8a8a90"))
        for y in range(10, 33, 4):
            for x in range(2 + (y // 4) % 2 * 3, 28, 6):
                c.dot(x, y, R("8a8a90")[1])
        mo = c.ellipse(15, 24, 7, 6) & c.rect(0, 18, 30, 30)
        c.fill(mo, C("2a1a18"))
        c.fill(c.ellipse(15, 27, 5, 3), C("f08030")); c.dot(15, 25, C("ffd060")); c.dot(13, 26, C("ffb040"))
        c.shade(c.rect(11, 0, 19, 9), R("6a6a70"))
        c.outline(); return c
    if k == "cat_tree":
        c = Canvas(24, 44)
        c.shade(c.rect(9, 6, 14, 42), R("d8c098"))
        for y in range(8, 42, 2):
            c.line([(9, y), (13, y + 1)], C("b8a070"))
        c.shade(c.ellipse(12, 6, 10, 4), R("e0a0b8")); c.shade(c.ellipse(12, 24, 8, 3), R("e0a0b8"))
        c.shade(c.rect(2, 40, 22, 44), R("e0a0b8"))
        c.fill(c.ellipse(19, 27, 1.5, 1.5), C("f0d040")); c.line([(19, 25), (19, 22)], C("a08060"))
        c.outline(); return c
    if k == "cat_basket":
        c = Canvas(26, 16)
        c.shade(c.ellipse(13, 9, 12, 6), R("e090a8"))
        c.shade(c.ellipse(13, 9, 8, 3.5), R("fff0f4"), flat=0.5)
        motif(c, "cat", 13, 9, col=C("e090a8"))
        c.outline(); return c
    if k == "aquarium":
        c = Canvas(32, 30)
        c.shade(c.rect(2, 22, 30, 30), R("6a4a3a"))
        g = c.rect(3, 3, 29, 22)
        c.fill(g, (120, 190, 230, 200))
        c.fill(c.rect(3, 18, 29, 22), C("d8c890"))
        c.shade(c.ellipse(10, 12, 3, 1.8), R("f08030")); c.dot(7, 12, C("f08030"))
        c.shade(c.ellipse(22, 9, 2.5, 1.5), R("40a0f0"))
        c.line([(16, 18), (16, 11)], C("40a040")); c.line([(18, 18), (19, 13)], C("40a040"))
        c.dot(12, 6, (255, 255, 255, 255)); c.dot(13, 4, (255, 255, 255, 255))
        c.outline(); return c
    if k == "piano":
        c = Canvas(44, 34)
        b = c.rect(2, 2, 42, 30)
        c.shade(b, R("2a2030"))
        c.fill(c.rect(4, 18, 40, 22), C("f4f0e8"))
        for x in range(5, 40, 3):
            c.fill(c.rect(x, 18, x + 1, 20), C("1a1420"))
        c.shade(c.rect(4, 30, 7, 34), R("2a2030")); c.shade(c.rect(37, 30, 40, 34), R("2a2030"))
        c.fill(c.rect(16, 6, 28, 13), C("f4ecd8"))
        c.outline(); return c
    if k == "fireplace":
        c = Canvas(48, 40)
        b = c.rect(2, 6, 46, 40)
        c.shade(b, R("a07060"))
        for y in range(8, 40, 4):
            for x in range(3 + (y // 4) % 2 * 4, 45, 8):
                c.line([(x, y), (x + 6, y)], R("a07060")[1])
        mo = c.rect(12, 18, 36, 40)
        c.fill(mo, C("1a1012"))
        c.fill(c.ellipse(24, 36, 9, 5), C("f07020")); c.fill(c.ellipse(24, 35, 5, 4), C("ffc040")); c.dot(24, 32, C("fff0a0"))
        c.shade(c.rect(0, 4, 48, 8), R("6a4a3a"))
        c.outline(); return c
    if k == "armor_stand":
        c = Canvas(22, 44)
        c.shade(c.rect(10, 26, 12, 42), R("7a5a3a")); c.shade(c.rect(4, 41, 18, 44), R("7a5a3a"))
        c.shade(c.ellipse(11, 7, 5, 6), R("b8b8c8"))
        c.fill(c.rect(9, 7, 13, 8), C("1a1a24"))
        c.shade(c.poly([(3, 13), (19, 13), (17, 30), (5, 30)]), R("b8b8c8"))
        c.line([(11, 14), (11, 28)], C("e8c040"))
        c.outline(); return c
    if k == "globe":
        c = Canvas(16, 26)
        c.shade(c.rect(7, 16, 9, 24), R("7a5a3a")); c.shade(c.rect(3, 23, 13, 26), R("7a5a3a"))
        g = c.ellipse(8, 9, 6.5, 6.5)
        c.shade(g, R("4080c0"))
        for (x, y) in [(6, 7), (7, 7), (10, 10), (11, 11), (5, 11), (9, 5)]:
            c.dot(x, y, C("60a050"))
        c.outline(); return c
    if k == "potion_rack":
        c = Canvas(32, 36)
        c.shade(c.rect(1, 2, 31, 36), R("7a5a3a"))
        cols = ["e04060", "40c060", "4080f0", "f0c040", "a050e0", "40d0d0"]
        for row in range(3):
            c.fill(c.rect(3, 4 + row * 11, 29, 13 + row * 11), dark(C("7a5a3a"), 0.5))
            for i in range(4):
                x = 5 + i * 6
                c.shade(c.ellipse(x + 1.5, 10 + row * 11, 2.2, 2.5), R(cols[(row * 4 + i) % 6]))
                c.dot(x + 1, 6 + row * 11, C("e0d0b0"))
        c.outline(); return c
    if k == "throne":
        c = Canvas(34, 46)
        c.shade(c.rect(4, 2, 30, 30), R("f0c840"))
        c.shade(c.rect(8, 6, 26, 28), R("b01e34"), flat=0.3)
        top_crest(c, "royal", 4, 30, 4)
        c.shade(c.rect(2, 26, 32, 34), R("b01e34"))
        c.shade(c.rect(1, 22, 6, 40), R("f0c840")); c.shade(c.rect(28, 22, 33, 40), R("f0c840"))
        c.shade(c.rect(3, 34, 31, 46), R("f0c840"))
        motif(c, "royal", 17, 16)
        c.outline(); return c


def furn_list():
    out = {}
    for cat, info in CATS.items():
        for st in CAT_STYLES[cat]:
            fid = "%s_%s" % (st, cat)
            s = STYLES[st]
            nm = "%s %s" % (s["adj"][info[1]], info[0])
            if cat == "bed" and st == "straw":
                nm = "Соломенная лежанка"
            tier = s["tier"]
            price = int(info[5] * [0.25, 0.6, 1.0, 1.8, 3.0, 4.5, 7.0, 12.0][tier])
            out[fid] = {"name": nm, "tex": "fu_" + fid, "use": info[3], "foot": list(info[4]), "price": max(3, price), "tier": tier, "style": st, "cat": cat}
    for k, v in DP_FURN.items():
        out[k] = {"name": v[0], "tex": k, "use": v[1], "foot": list(v[2]), "price": v[3], "tier": v[4], "style": "village", "cat": "misc"}
    for k, v in EXTRA_FURN.items():
        out[k] = {"name": v[0], "tex": "fu_" + k, "use": v[1], "foot": list(v[2]), "price": v[3], "tier": v[4], "style": "special", "cat": "misc"}
    return out


def gen_furn():
    for cat in CATS:
        for st in CAT_STYLES[cat]:
            DRAW[cat](st).save(os.path.join(ART, "fu_%s_%s.png" % (st, cat)))
    for k in EXTRA_FURN:
        draw_extra(k).save(os.path.join(ART, "fu_%s.png" % k))
    # стрелка «пристроить комнату» и проём между комнатами
    a = Canvas(20, 20)
    m = a.poly([(4, 6), (12, 6), (12, 2), (18, 10), (12, 18), (12, 14), (4, 14)])
    a.shade(m, R("f0c860"))
    a.outline()
    a.save(os.path.join(ART, "room_add.png"))
    floor = Image.open(os.path.join(ART, "interior_floor.png")).convert("RGBA")
    room = floor.crop((220, 88, 420, 290))
    # боковая комната: внизу стена без двери
    side = room.copy()
    wall_piece = room.crop((40, 194, 80, 202))
    side.paste(wall_piece, (82, 194))
    side.paste(wall_piece, (100, 194))
    side.save(os.path.join(ART, "room_side.png"))
    gap = room.crop((20, 110, 30, 150))     # кусок пола — проём в боковой стене
    gap.save(os.path.join(ART, "room_gap.png"))


# =====================================================================================  ОРУЖИЕ
# Тип: название, род, базовая атака, скорость (с между ударами), дальность (px), ranged, размер в сумке, вес
WTYPES = {
    "sword": ["меч", 1, 10, 0.45, 34, False, (1, 3), 2.5],
    "dagger": ["кинжал", 1, 6, 0.28, 26, False, (1, 2), 0.8],
    "greatsword": ["двуручный меч", 1, 18, 0.8, 42, False, (2, 3), 5.0],
    "rapier": ["рапира", 0, 9, 0.32, 38, False, (1, 3), 1.5],
    "katana": ["катана", 0, 13, 0.4, 38, False, (1, 3), 2.0],
    "axe": ["боевой топор", 1, 14, 0.65, 32, False, (2, 3), 3.5],
    "hammer": ["молот", 1, 16, 0.75, 32, False, (2, 3), 5.0],
    "mace": ["булава", 0, 12, 0.55, 30, False, (1, 3), 3.0],
    "spear": ["копьё", 2, 11, 0.5, 50, False, (1, 4), 3.0],
    "trident": ["трезубец", 1, 12, 0.55, 48, False, (1, 4), 3.2],
    "scythe": ["коса", 0, 15, 0.7, 44, False, (2, 3), 3.5],
    "club": ["дубинка", 0, 8, 0.5, 28, False, (1, 3), 2.0],
    "flail": ["цеп", 1, 13, 0.6, 36, False, (2, 3), 3.0],
    "whip": ["хлыст", 1, 7, 0.35, 56, False, (2, 2), 0.8],
    "staff": ["посох", 1, 9, 0.5, 220, True, (1, 4), 2.0],
    "wand": ["жезл", 1, 7, 0.32, 200, True, (1, 2), 0.5],
    "bow": ["лук", 1, 9, 0.55, 260, True, (1, 3), 1.2],
    "crossbow": ["арбалет", 1, 14, 0.9, 280, True, (2, 2), 3.0],
    "boomerang": ["бумеранг", 1, 8, 0.6, 180, True, (2, 2), 0.8],
    "slingshot": ["рогатка", 0, 5, 0.35, 200, True, (1, 2), 0.4],
    "pillow": ["боевая подушка", 0, 4, 0.3, 30, False, (2, 2), 0.6],
    "squeaky": ["пищащий молоток", 1, 6, 0.4, 30, False, (1, 3), 0.8],
    "bubble": ["пузырный жезл", 1, 5, 0.3, 190, True, (1, 2), 0.4],
    "fan": ["боевой веер", 1, 8, 0.35, 40, False, (2, 2), 0.6],
}
# Материал: прилагательное [ж, м, ср], цвет лезвия, цвет рукояти, множитель атаки, цена, уровень, особый эффект
MATS = {
    "wood": [["Деревянная", "Деревянный", "Деревянное"], "b08050", "7a5030", 0.7, 6, 1, ""],
    "bone": [["Костяная", "Костяной", "Костяное"], "e8e0c8", "8a6a48", 0.8, 9, 1, ""],
    "copper": [["Медная", "Медный", "Медное"], "d8884a", "6a4a30", 0.9, 12, 1, ""],
    "bronze": [["Бронзовая", "Бронзовый", "Бронзовое"], "c89a48", "5a3a28", 1.0, 18, 2, ""],
    "iron": [["Железная", "Железный", "Железное"], "a8a8b4", "5a3a28", 1.15, 26, 2, ""],
    "steel": [["Стальная", "Стальной", "Стальное"], "c8d0dc", "3a2a24", 1.35, 40, 3, ""],
    "silver": [["Серебряная", "Серебряный", "Серебряное"], "e0e4f0", "4a3a5a", 1.45, 60, 3, "holy"],
    "gold": [["Золотая", "Золотой", "Золотое"], "f0c840", "8a2a2a", 1.4, 90, 3, "luck"],
    "crystal": [["Хрустальная", "Хрустальный", "Хрустальное"], "a8e8ff", "4a5a8a", 1.6, 110, 4, "mana"],
    "frost": [["Морозная", "Морозный", "Морозное"], "90d0ff", "305080", 1.7, 130, 4, "frost"],
    "ember": [["Огненная", "Огненный", "Огненное"], "ff7a30", "5a2018", 1.75, 140, 4, "fire"],
    "verdant": [["Живая", "Живой", "Живое"], "60d870", "4a3020", 1.7, 130, 4, "heal"],
    "moonsilver": [["Лунная", "Лунный", "Лунное"], "d8e0ff", "2a2a50", 1.9, 170, 5, "sleep"],
    "void": [["Бездонная", "Бездонный", "Бездонное"], "7a40c0", "1a1028", 2.1, 200, 5, "void"],
    "star": [["Звёздная", "Звёздный", "Звёздное"], "fff4b0", "3a3070", 2.3, 260, 6, "star"],
    "candy": [["Леденцовая", "Леденцовый", "Леденцовое"], "ff90c0", "f4f0f0", 1.2, 40, 2, "fun"],
}
TYPE_MATS = {
    "pillow": ["candy", "wood", "silver", "gold", "star"],
    "squeaky": ["candy", "wood", "gold", "star"],
    "bubble": ["candy", "crystal", "frost", "star"],
    "slingshot": ["wood", "bone", "copper", "iron", "gold", "verdant"],
    "boomerang": ["wood", "bone", "copper", "iron", "gold", "ember", "frost", "star"],
    "bow": ["wood", "bone", "copper", "iron", "steel", "silver", "gold", "crystal", "frost", "ember", "verdant", "moonsilver", "void", "star"],
    "staff": ["wood", "bone", "copper", "iron", "silver", "gold", "crystal", "frost", "ember", "verdant", "moonsilver", "void", "star", "candy"],
    "wand": ["wood", "bone", "copper", "silver", "gold", "crystal", "frost", "ember", "verdant", "moonsilver", "void", "star", "candy"],
    "club": ["wood", "bone", "copper", "iron", "candy"],
    "whip": ["wood", "copper", "iron", "silver", "ember", "void"],
    "fan": ["wood", "bone", "copper", "steel", "gold", "frost", "ember", "moonsilver"],
}
LEGENDS = {
    "lgd_dawn": ["Клинок Рассвета", "sword", "fff0a0", "e0a040", 32, 900, "holy", "Меч, что светится в темноте пещер. Монстры от него засыпают с улыбкой."],
    "lgd_purr": ["Мурчалка", "squeaky", "ffb0d0", "ffffff", 26, 600, "fun", "Пищит мяу-голосом. Ни один монстр не может драться, пока смеётся."],
    "lgd_tide": ["Трезубец Прилива", "trident", "60c0ff", "2a5080", 30, 800, "frost", "Подарок морского царя. Пахнет солью и победой."],
    "lgd_hearth": ["Молот Очага", "hammer", "ff9040", "5a3020", 36, 950, "fire", "Тёплый, как печка. Демоны уважают."],
    "lgd_whisper": ["Посох Шёпота Леса", "staff", "80f090", "6a4a30", 28, 850, "heal", "Деревья шепчут ему ответы."],
    "lgd_moon": ["Лунная Коса", "scythe", "e0e8ff", "2a2050", 34, 1000, "sleep", "Не режет — укладывает спать. Сладких снов, чудище."],
    "lgd_star": ["Звездопад", "bow", "fff8c0", "3a3070", 30, 1100, "star", "Стреляет падающими звёздами. Загадай желание."],
    "lgd_void": ["Пустотный Жезл", "wand", "a060ff", "100818", 27, 950, "void", "Монстры исчезают в никуда — и появляются дома, у мамы."],
    "lgd_fluff": ["Подушка Тысячи Снов", "pillow", "fff0f8", "f0b0d0", 22, 700, "sleep", "Мягче облака. Удар — и все спят."],
    "lgd_dragon": ["Драконий Зуб", "greatsword", "f0e0c0", "8a2020", 40, 1300, "fire", "Дракон сам отдал его. Сказал, что зуб всё равно шатался."],
    "lgd_sakura": ["Сакура-но-Кадзэ", "katana", "ffc0d8", "3a2030", 33, 1000, "luck", "С каждым взмахом облетают лепестки."],
    "lgd_hell": ["Вилы Владыки Ада", "trident", "ff4030", "2a0a0a", 42, 1600, "fire", "Трофей из самого пекла. Чертовски хороши."],
    "lgd_bubble": ["Королевский Пузырь", "bubble", "c0f0ff", "f0c840", 24, 750, "fun", "Монстры улетают в пузырях. Очень вежливо."],
    "lgd_frost": ["Вечная Зима", "rapier", "c0f0ff", "2a4a7a", 31, 950, "frost", "Укол — и чудище застывает ледяной статуей. Потом оттает."],
    "lgd_gold": ["Цеп Скупого Короля", "flail", "f0c840", "6a2a2a", 30, 1200, "luck", "Из побеждённых сыплются монеты."],
}
FX_NAME = {"holy": "Свет: монстры засыпают", "luck": "Удача: больше добычи", "mana": "Мана: быстрее заклинания", "frost": "Мороз: замедляет",
           "fire": "Огонь: жжёт сильнее", "heal": "Жизнь: лечит при ударе", "sleep": "Сон: усыпляет", "void": "Пустота: пробивает защиту",
           "star": "Звёзды: удар по кругу", "fun": "Смех: монстры смеются и не дерутся"}


def wpn_list():
    out = {}
    order = []
    for t, ti in WTYPES.items():
        mats = TYPE_MATS.get(t, ["wood", "bone", "copper", "bronze", "iron", "steel", "silver", "gold", "crystal", "frost", "ember", "verdant", "moonsilver", "void", "star"])
        for mk in mats:
            mi = MATS[mk]
            wid = "wpn_%s_%s" % (t, mk)
            atk = int(round(ti[2] * mi[3]))
            nm = "%s %s" % (mi[0][ti[1]], ti[0])
            out[wid] = {"name": nm, "type": t, "mat": mk, "atk": atk, "cd": ti[3], "range": ti[4], "ranged": ti[5], "size": list(ti[6]),
                        "w": ti[7], "price": int(mi[4] * (1 + ti[2] / 12.0)), "tier": mi[5], "fx": mi[6], "blade": mi[1], "grip": mi[2]}
            order.append(wid)
    for lid, l in LEGENDS.items():
        ti = WTYPES[l[1]]
        out[lid] = {"name": l[0], "type": l[1], "mat": "legend", "atk": l[4], "cd": ti[3] * 0.85, "range": ti[4], "ranged": ti[5], "size": list(ti[6]),
                    "w": ti[7], "price": l[5], "tier": 7, "fx": l[6], "blade": l[2], "grip": l[3], "desc": l[7]}
        order.append(lid)
    return out, order


def draw_weapon(t, blade, grip, legend=False):
    c = Canvas(24, 24)
    B, G = R(blade), R(grip)

    def diag(a, b, w, rmp):
        m = c.line_mask([a, b], w)
        c.shade(m, rmp)
        return m
    if t in ("sword", "greatsword", "rapier", "katana", "dagger"):
        L = {"sword": 15, "greatsword": 17, "rapier": 17, "katana": 16, "dagger": 9}[t]
        wdt = {"sword": 3, "greatsword": 4, "rapier": 1, "katana": 2, "dagger": 3}[t]
        x0, y0 = 7, 17
        diag((x0, y0), (x0 + L * 0.8, y0 - L * 0.8), wdt, B)
        c.line([(x0 + 1, y0 - 2), (x0 + L * 0.75, y0 - L * 0.78)], B[4])
        if t == "katana":
            c.line([(x0 - 2, y0 + 2), (x0 + 1, y0 - 1)], C("f0e0c0"))
        diag((x0 - 4, y0 + 4), (x0, y0), 2, G)
        diag((x0 - 3, y0 - 3), (x0 + 3, y0 + 3), 2 if t != "rapier" else 1, R("e0c060") if legend or t != "katana" else G)
        c.dot(x0 - 5, y0 + 5, C("e0c060"))
    elif t in ("axe", "hammer", "mace", "club", "squeaky", "flail"):
        diag((4, 21), (15, 8), 2, G)
        if t == "axe":
            m = c.poly([(13, 4), (21, 6), (21, 15), (15, 13), (13, 9)])
            c.shade(m, B)
            c.line([(21, 6), (21, 15)], B[4])
        elif t in ("hammer", "squeaky"):
            m = c.poly([(10, 6), (17, 0), (23, 6), (16, 13)])
            c.shade(m, B)
            if t == "squeaky":
                c.dot(20, 3, (255, 255, 255, 255)); c.dot(19, 4, (255, 255, 255, 255))
        elif t == "mace":
            c.shade(c.ellipse(17, 6, 5, 5), B)
            for (x, y) in [(17, 0), (23, 6), (12, 4), (21, 1), (21, 11)]:
                c.dot(x, y, B[3])
        elif t == "club":
            c.shade(c.line_mask([(10, 14), (19, 4)], 5), B)
        elif t == "flail":
            c.line([(15, 8), (18, 6), (19, 9)], C("8a8a90"))
            c.shade(c.ellipse(19, 13, 4, 4), B)
            for (x, y) in [(19, 8), (23, 13), (15, 13), (19, 17)]:
                c.dot(x, y, B[3])
    elif t in ("spear", "trident", "scythe", "staff"):
        diag((2, 22), (18, 6), 2, G)
        if t == "spear":
            c.shade(c.poly([(17, 7), (19, 1), (23, 0), (22, 4), (20, 8)]), B)
        elif t == "trident":
            for (a, b2) in [((16, 8), (16, 2)), ((18, 6), (22, 6)), ((17, 7), (21, 2))]:
                c.line([a, b2], B[3])
            c.dot(16, 1, B[4]); c.dot(23, 6, B[4]); c.dot(22, 1, B[4])
        elif t == "scythe":
            c.shade(c.poly([(17, 6), (21, 3), (14, 1), (6, 3), (14, 3)]), B)
            c.line([(6, 3), (14, 2)], B[4])
        elif t == "staff":
            c.shade(c.ellipse(19, 5, 3.5, 3.5), B)
            c.dot(18, 4, (255, 255, 255, 255))
            c.line([(16, 8), (17, 6)], G[1])
    elif t in ("wand", "bubble"):
        diag((5, 20), (15, 10), 2, G)
        c.shade(c.ellipse(17, 8, 3.5, 3.5) if t == "wand" else c.ellipse(17, 7, 4.5, 4.5), B)
        c.dot(16, 6, (255, 255, 255, 255))
        if t == "bubble":
            c.dot(21, 2, B[4]); c.dot(22, 1, B[3]); c.dot(12, 3, B[4])
    elif t == "bow":
        m = c.line_mask([(6, 3), (13, 6), (18, 11), (21, 18)], 2)
        c.shade(m, B)
        c.line([(6, 3), (21, 18)], C("f4ecd8"))
        c.shade(c.rect(11, 9, 14, 12), G)
    elif t == "crossbow":
        diag((3, 20), (16, 7), 3, G)
        c.shade(c.line_mask([(8, 4), (14, 9), (20, 14)], 2), B)
        c.line([(8, 4), (20, 14)], C("f4ecd8"))
        c.line([(12, 11), (18, 5)], B[3])
    elif t == "boomerang":
        m = c.line_mask([(4, 8), (12, 16), (21, 6)], 4)
        c.shade(m, B)
        c.line([(5, 7), (12, 14), (20, 5)], B[4])
    elif t == "slingshot":
        diag((6, 21), (11, 13), 2, G)
        c.shade(c.line_mask([(11, 13), (7, 4)], 2), G)
        c.shade(c.line_mask([(11, 13), (17, 6)], 2), G)
        c.line([(7, 4), (12, 9), (17, 6)], C(blade[:6]) if False else B[3])
    elif t == "whip":
        c.line([(4, 20), (7, 15), (12, 14), (16, 10), (15, 5), (19, 3)], B[2], 2)
        c.line([(19, 3), (22, 4)], B[4])
        diag((2, 22), (5, 19), 3, G)
    elif t == "pillow":
        m = c.rect(3, 6, 21, 19)
        c.shade(m, B)
        for (x, y) in [(3, 6), (20, 6), (3, 18), (20, 18)]:
            c.dot(x, y, B[1])
        c.line([(6, 12), (18, 12)], B[1])
        c.dot(12, 9, (255, 255, 255, 255))
    elif t == "fan":
        m = c.poly([(5, 19), (2, 7), (8, 3), (15, 3), (21, 8), (19, 14)])
        c.shade(m, B)
        for k in range(5):
            a = math.radians(200 + k * 22)
            c.line([(6, 18), (6 + math.cos(a) * -14, 18 + math.sin(a) * 14)], B[1])
        c.shade(c.rect(4, 18, 8, 22), G)
    if legend:
        c.dot(2, 2, C("fff8c0")); c.dot(3, 1, C("ffffff")); c.dot(21, 21, C("fff8c0"))
    c.outline()
    return c


def gen_wpn():
    out, order = wpn_list()
    for wid in order:
        w = out[wid]
        draw_weapon(w["type"], w["blade"], w["grip"], w["mat"] == "legend").save(os.path.join(ART, "gear_%s.png" % wid))
    # удочка
    c = Canvas(24, 24)
    c.shade(c.line_mask([(3, 22), (21, 2)], 2), R("a07040"))
    c.shade(c.ellipse(7, 17, 2.5, 2.5), R("8a8a90"))
    c.line([(21, 2), (22, 9), (22, 14)], C("e0e0e8"))
    c.dot(22, 15, C("e04040")); c.dot(22, 16, C("f4f0e8"))
    c.outline()
    c.save(os.path.join(ART, "gear_rod.png"))


# =====================================================================================  МОНСТРЫ
# вид: имя, размер кадра, HP, урон, скорость, где, цвет, форма, награда
MONS = {
    "slime": ["Слизень", 20, 18, 4, 30, "cave", "60c060", "slime"],
    "slime_blue": ["Ледяной слизень", 20, 24, 5, 28, "ice", "70b8f0", "slime"],
    "slime_pink": ["Желейный слизень", 20, 22, 4, 32, "meadow", "f090c0", "slime"],
    "slime_sand": ["Песчаный слизень", 20, 22, 5, 30, "sand", "e0c070", "slime"],
    "slime_king": ["Король Слизней", 44, 160, 9, 22, "boss", "50d060", "slime"],
    "mushroom": ["Грибочек-драчун", 20, 20, 5, 34, "forest", "d04040", "shroom"],
    "mushroom_blue": ["Светогриб", 20, 26, 6, 32, "swamp", "4080f0", "shroom"],
    "skeleton": ["Скелетик-задира", 22, 30, 6, 36, "crypt", "e8e0c8", "skel"],
    "ghost": ["Привиденьице", 20, 22, 6, 44, "crypt", "d8e8ff", "ghost"],
    "golem": ["Каменный голем", 28, 60, 9, 22, "cave", "8a8a90", "golem"],
    "crystal_golem": ["Хрустальный голем", 28, 70, 10, 24, "crystal", "a8e8ff", "golem"],
    "ice_imp": ["Ледяной бесёнок", 20, 26, 6, 46, "ice", "a0d8ff", "imp"],
    "scarab": ["Жук-скарабей", 20, 26, 6, 40, "sand", "40a0a0", "bug"],
    "frog": ["Болотная жаба", 22, 30, 6, 38, "swamp", "6a9a3a", "frog"],
    "bat_m": ["Нетопырь", 24, 14, 4, 60, "cave", "6a4a7a", "bat"],
    "spiderling": ["Паучок", 20, 20, 5, 50, "forest", "4a3a4a", "bug"],
    "salamander": ["Саламандра", 22, 34, 7, 42, "lava", "ff7030", "frog"],
    "wisp": ["Блуждающий огонёк", 16, 18, 5, 52, "elven", "a0ffb0", "ghost"],
    "imp": ["Бесёнок", 20, 36, 7, 50, "hell", "e04030", "imp"],
    "demon": ["Демон", 28, 80, 11, 38, "hell", "c02030", "demon"],
    "hellhound": ["Адская гончая", 26, 60, 10, 62, "hell", "802020", "hound"],
    "devil": ["Дьявол", 44, 400, 14, 34, "boss_hell", "d02020", "demon"],
    "golem_king": ["Древний Голем", 44, 260, 12, 20, "boss", "7a7a84", "golem"],
    "lich": ["Сонный Лич", 32, 220, 11, 30, "boss", "8060c0", "skel"],
}


def draw_mon(shape, col, sz, f):
    W = sz
    c = Canvas(W, W)
    rr = R(col)
    s = W / 20.0
    bob = [0, 1, 0, -1][f]
    if shape == "slime":
        sq = [0, 1, 0, -1][f]
        m = c.ellipse(W / 2, W * 0.66 + sq * 0.5, W * 0.42 + sq * 0.6, W * 0.30 - sq * 0.6)
        m |= c.ellipse(W / 2, W * 0.5 + sq * 0.5, W * 0.30, W * 0.30)
        m &= c.rect(0, 0, W, int(W * 0.9))
        c.shade(m, rr)
        c.dot(int(W * 0.36), int(W * 0.42), (255, 255, 255, 255)); c.dot(int(W * 0.37), int(W * 0.43), (255, 255, 255, 220))
        ey = int(W * 0.58 + sq * 0.5)
        c.fill(c.rect(int(W * 0.38), ey, int(W * 0.38) + max(1, int(s)), ey + max(2, int(2 * s))), OUTLINE)
        c.fill(c.rect(int(W * 0.58), ey, int(W * 0.58) + max(1, int(s)), ey + max(2, int(2 * s))), OUTLINE)
        if sz > 30:   # корона короля
            m2 = c.poly([(W * 0.35, W * 0.28), (W * 0.38, W * 0.12), (W * 0.45, W * 0.22), (W * 0.5, W * 0.08), (W * 0.55, W * 0.22), (W * 0.62, W * 0.12), (W * 0.65, W * 0.28)])
            c.shade(m2, R("f0c840"))
    elif shape == "shroom":
        c.shade(c.rect(int(W * 0.38), int(W * 0.48) + bob, int(W * 0.62), int(W * 0.92)), R("f0e4c8"))
        cap = c.ellipse(W / 2, W * 0.42 + bob, W * 0.42, W * 0.26) & c.rect(0, 0, W, int(W * 0.52) + bob)
        c.shade(cap, rr)
        for (x, y) in [(0.35, 0.3), (0.6, 0.26), (0.5, 0.4)]:
            c.dot(int(W * x), int(W * y) + bob, (255, 255, 255, 255))
        c.fill(c.rect(int(W * 0.42), int(W * 0.6) + bob, int(W * 0.42) + 1, int(W * 0.66) + bob), OUTLINE)
        c.fill(c.rect(int(W * 0.56), int(W * 0.6) + bob, int(W * 0.56) + 1, int(W * 0.66) + bob), OUTLINE)
        legs = [0, 1, 0, -1][f]
        c.fill(c.rect(int(W * 0.36) - legs, int(W * 0.9), int(W * 0.46) - legs, W), C("6a4a30"))
        c.fill(c.rect(int(W * 0.54) + legs, int(W * 0.9), int(W * 0.64) + legs, W), C("6a4a30"))
    elif shape == "skel":
        c.shade(c.ellipse(W / 2, W * 0.24 + bob, W * 0.2, W * 0.18), rr)
        c.fill(c.rect(int(W * 0.40), int(W * 0.22) + bob, int(W * 0.40) + max(1, int(s * 1.4)), int(W * 0.27) + bob), OUTLINE)
        c.fill(c.rect(int(W * 0.54), int(W * 0.22) + bob, int(W * 0.54) + max(1, int(s * 1.4)), int(W * 0.27) + bob), OUTLINE)
        body = c.rect(int(W * 0.42), int(W * 0.42) + bob, int(W * 0.58), int(W * 0.7) + bob)
        c.shade(body, rr)
        for k in range(3):
            c.line([(W * 0.34, W * (0.46 + k * 0.08) + bob), (W * 0.66, W * (0.46 + k * 0.08) + bob)], rr[2])
        sw = [0, 2, 0, -2][f]
        c.line([(W * 0.42, W * 0.72), (W * 0.36 - sw * 0.3, W * 0.98)], rr[2], max(1, int(s * 1.2)))
        c.line([(W * 0.58, W * 0.72), (W * 0.64 + sw * 0.3, W * 0.98)], rr[2], max(1, int(s * 1.2)))
        c.line([(W * 0.4, W * 0.46 + bob), (W * 0.24, W * 0.62 + bob)], rr[2], max(1, int(s)))
        c.line([(W * 0.6, W * 0.46 + bob), (W * 0.78, W * 0.58 + bob)], rr[2], max(1, int(s)))
        if sz > 24:   # лич: мантия и шапочка с помпоном
            robe = c.poly([(W * 0.3, W * 0.44 + bob), (W * 0.7, W * 0.44 + bob), (W * 0.8, W * 0.98), (W * 0.2, W * 0.98)])
            c.shade(robe, R("6040a0"))
            c.shade(c.poly([(W * 0.3, W * 0.14 + bob), (W * 0.7, W * 0.14 + bob), (W * 0.62, W * 0.02 + bob)]), R("6040a0"))
            c.shade(c.ellipse(W * 0.64, W * 0.03 + bob, 2, 2), R("ffffff"))
    elif shape == "ghost":
        m = c.ellipse(W / 2, W * 0.42 + bob, W * 0.34, W * 0.32)
        m |= c.rect(int(W * 0.16), int(W * 0.42) + bob, int(W * 0.84), int(W * 0.82) + bob)
        for k in range(4):
            m &= ~c.ellipse(W * (0.25 + k * 0.17) + (f % 2), W * 0.86 + bob, W * 0.06, W * 0.07)
        c.shade(m, rr)
        c.fill(c.ellipse(W * 0.4, W * 0.42 + bob, max(1, s), max(1.5, s * 1.4)), OUTLINE)
        c.fill(c.ellipse(W * 0.6, W * 0.42 + bob, max(1, s), max(1.5, s * 1.4)), OUTLINE)
        c.fill(c.ellipse(W * 0.5, W * 0.56 + bob, max(1, s * 0.9), max(1, s * 0.9)), OUTLINE)
    elif shape == "golem":
        m = c.rect(int(W * 0.24), int(W * 0.3) + bob, int(W * 0.76), int(W * 0.78) + bob)
        c.shade(m, rr)
        c.shade(c.rect(int(W * 0.36), int(W * 0.12) + bob, int(W * 0.64), int(W * 0.32) + bob), rr)
        arm = [0, 1, 0, -1][f]
        c.shade(c.rect(int(W * 0.08), int(W * 0.34) + arm, int(W * 0.24), int(W * 0.66) + arm), rr)
        c.shade(c.rect(int(W * 0.76), int(W * 0.34) - arm, int(W * 0.92), int(W * 0.66) - arm), rr)
        c.shade(c.rect(int(W * 0.28), int(W * 0.78), int(W * 0.44), W), rr)
        c.shade(c.rect(int(W * 0.56), int(W * 0.78), int(W * 0.72), W), rr)
        glow = C("80f0ff") if col != "8a8a90" else C("f0c040")
        c.fill(c.rect(int(W * 0.4), int(W * 0.2) + bob, int(W * 0.46), int(W * 0.24) + bob), glow)
        c.fill(c.rect(int(W * 0.54), int(W * 0.2) + bob, int(W * 0.6), int(W * 0.24) + bob), glow)
        for (x, y) in [(0.34, 0.45), (0.6, 0.6), (0.45, 0.7)]:
            c.dot(int(W * x), int(W * y) + bob, rr[1])
    elif shape in ("imp", "demon"):
        body = c.ellipse(W / 2, W * 0.58 + bob, W * 0.24, W * 0.26)
        c.shade(body, rr)
        head = c.ellipse(W / 2, W * 0.3 + bob, W * 0.2, W * 0.18)
        c.shade(head, rr)
        hc = R("f0e0c0") if shape == "imp" else R("2a1a1a")
        c.shade(c.poly([(W * 0.34, W * 0.2 + bob), (W * 0.28, W * 0.02 + bob), (W * 0.42, W * 0.16 + bob)]), hc)
        c.shade(c.poly([(W * 0.66, W * 0.2 + bob), (W * 0.72, W * 0.02 + bob), (W * 0.58, W * 0.16 + bob)]), hc)
        ey = C("fff060")
        c.fill(c.rect(int(W * 0.4), int(W * 0.28) + bob, int(W * 0.4) + max(1, int(s)), int(W * 0.31) + bob + 1), ey)
        c.fill(c.rect(int(W * 0.56), int(W * 0.28) + bob, int(W * 0.56) + max(1, int(s)), int(W * 0.31) + bob + 1), ey)
        wing = [0, 2, 0, -2][f]
        wc = R(dark(C(col), 0.35)[:3] and "%02x%02x%02x" % dark(C(col), 0.35)[:3])
        c.shade(c.poly([(W * 0.3, W * 0.5), (W * 0.02, W * 0.3 - wing), (W * 0.12, W * 0.62)]), wc)
        c.shade(c.poly([(W * 0.7, W * 0.5), (W * 0.98, W * 0.3 - wing), (W * 0.88, W * 0.62)]), wc)
        c.line([(W * 0.62, W * 0.78), (W * 0.82, W * 0.9), (W * 0.9, W * 0.8)], rr[1])
        c.fill(c.rect(int(W * 0.38), int(W * 0.82), int(W * 0.46), W), rr[1])
        c.fill(c.rect(int(W * 0.54), int(W * 0.82), int(W * 0.62), W), rr[1])
        if sz > 30:   # дьявол: вилы и плащ
            c.line([(W * 0.86, W * 0.15), (W * 0.86, W * 0.95)], C("3a2a2a"), 2)
            for dx in (-3, 0, 3):
                c.line([(W * 0.86 + dx, W * 0.15), (W * 0.86 + dx, W * 0.05)], C("c0c0c8"))
    elif shape == "hound":
        c.shade(c.ellipse(W * 0.48, W * 0.55 + bob, W * 0.32, W * 0.18), rr)
        c.shade(c.ellipse(W * 0.78, W * 0.42 + bob, W * 0.16, W * 0.14), rr)
        c.fill(c.rect(int(W * 0.8), int(W * 0.38) + bob, int(W * 0.84), int(W * 0.42) + bob), C("fff060"))
        lg = [0, 2, 0, -2][f]
        for x in (0.28, 0.4, 0.58, 0.68):
            c.fill(c.rect(int(W * x) + (lg if x < 0.5 else -lg) // 2, int(W * 0.66), int(W * x) + 2 + (lg if x < 0.5 else -lg) // 2, int(W * 0.86)), rr[1])
        for k in range(3):
            c.dot(int(W * (0.3 + k * 0.1)), int(W * 0.38) + bob - (f + k) % 2, C("ff9030"))
    elif shape == "frog":
        c.shade(c.ellipse(W / 2, W * 0.62 + bob, W * 0.38, W * 0.26), rr)
        for ex in (0.34, 0.66):
            c.shade(c.ellipse(W * ex, W * 0.38 + bob, W * 0.11, W * 0.11), rr)
            c.fill(c.rect(int(W * ex), int(W * 0.36) + bob, int(W * ex) + 1, int(W * 0.4) + bob), OUTLINE)
        c.line([(W * 0.36, W * 0.7 + bob), (W * 0.64, W * 0.7 + bob)], dark(C(col), 0.5))
        if col == "ff7030":
            for k in range(3):
                c.dot(int(W * (0.4 + k * 0.1)), int(W * 0.5) + bob, C("ffe060"))
    elif shape == "bat":
        wing = [-4, 0, 4, 0][f]
        c.shade(c.poly([(W * 0.42, W * 0.42), (W * 0.02, W * 0.3 + wing), (W * 0.1, W * 0.62), (W * 0.24, W * 0.56), (W * 0.42, W * 0.66)]), rr)
        c.shade(c.poly([(W * 0.58, W * 0.42), (W * 0.98, W * 0.3 + wing), (W * 0.9, W * 0.62), (W * 0.76, W * 0.56), (W * 0.58, W * 0.66)]), rr)
        c.shade(c.ellipse(W / 2, W / 2 + bob, W * 0.18, W * 0.2), rr)
        c.shade(c.poly([(W * 0.38, W * 0.36 + bob), (W * 0.4, W * 0.22 + bob), (W * 0.46, W * 0.34 + bob)]), rr)
        c.shade(c.poly([(W * 0.62, W * 0.36 + bob), (W * 0.6, W * 0.22 + bob), (W * 0.54, W * 0.34 + bob)]), rr)
        c.dot(int(W * 0.44), int(W * 0.48) + bob, C("ffe060")); c.dot(int(W * 0.56), int(W * 0.48) + bob, C("ffe060"))
    elif shape == "bug":
        c.shade(c.ellipse(W / 2, W * 0.56, W * 0.3, W * 0.26), rr)
        c.shade(c.ellipse(W / 2, W * 0.28, W * 0.16, W * 0.12), R("%02x%02x%02x" % dark(C(col), 0.3)[:3]))
        c.line([(W / 2, W * 0.34), (W / 2, W * 0.8)], dark(C(col), 0.5))
        lg = [0, 1, 0, -1][f]
        for k in range(3):
            y = W * (0.46 + k * 0.12)
            c.line([(W * 0.22, y), (W * 0.06, y + lg)], OUTLINE)
            c.line([(W * 0.78, y), (W * 0.94, y - lg)], OUTLINE)
        c.dot(int(W * 0.44), int(W * 0.26), C("ffe060")); c.dot(int(W * 0.56), int(W * 0.26), C("ffe060"))
    c.outline()
    return c


def gen_mon():
    for k, m in MONS.items():
        frames = [draw_mon(m[7], m[6], m[1], f) for f in range(4)]
        sheet(frames, os.path.join(ART, "mon_%s.png" % k))


# =====================================================================================  ДОМАШНИЕ ЗВЕРИ (12 кадров как у зверей мира)
FARM = {
    "chicken": ["Курочка", 22, 22, "f4f0e8", "e04030", "bird"],
    "cow": ["Корова", 46, 34, "f4f0e8", "3a2a2a", "quad"],
    "sheep": ["Овечка", 34, 28, "f0ece4", "3a3030", "wool"],
    "goat": ["Козочка", 32, 30, "d8c8b0", "6a5a48", "quad"],
    "pig": ["Свинка", 34, 24, "f0b0b0", "d07878", "quad"],
    "goose": ["Гусь", 24, 26, "f4f4f4", "f09030", "bird"],
}


def draw_farm(kind, f):
    nm, W, H, body, acc, shape = FARM[kind]
    W2, H2 = W * 2, H * 2
    c = Canvas(W2, H2)
    rb = R(body)
    walk = f < 4
    ph = f % 4 if walk else 0
    leg = [0, 2, 0, -2][ph] if walk else 0
    act = 6 <= f <= 9
    rest = f >= 10
    if shape == "bird":
        cy = H2 * 0.55 + (2 if rest else 0)
        c.shade(c.ellipse(W2 * 0.48, cy, W2 * 0.3, H2 * 0.24), rb)
        hy = H2 * 0.28 + (8 if act and f % 2 == 0 else 0) + (4 if rest else 0)
        c.shade(c.ellipse(W2 * 0.68, hy, W2 * 0.14, H2 * 0.13), rb)
        c.shade(c.poly([(W2 * 0.8, hy - 1), (W2 * 0.95, hy + 2), (W2 * 0.8, hy + 4)]), R("f0b030" if kind == "chicken" else acc))
        c.fill(c.rect(int(W2 * 0.7), int(hy) - 2, int(W2 * 0.7) + 2, int(hy)), OUTLINE)
        if kind == "chicken":
            c.shade(c.ellipse(W2 * 0.66, hy - H2 * 0.12, 3, 3), R(acc))
        c.shade(c.poly([(W2 * 0.2, cy - 6), (W2 * 0.06, cy - 14), (W2 * 0.22, cy + 2)]), rb)
        c.shade(c.ellipse(W2 * 0.42, cy, W2 * 0.14, H2 * 0.12), R("e8e0d0" if kind == "chicken" else "e0e0e8"))
        if not rest:
            for lx, d in ((0.42, leg), (0.54, -leg)):
                c.line([(W2 * lx, cy + H2 * 0.2), (W2 * lx + d, H2 - 2)], C("e0a030"), 2)
    else:
        cy = H2 * 0.5 + (4 if rest else 0)
        bw = W2 * 0.36
        bm = c.ellipse(W2 * 0.46, cy, bw, H2 * 0.22)
        if shape == "wool":
            for k in range(8):
                bm |= c.ellipse(W2 * (0.18 + k * 0.08), cy - H2 * 0.14 + (k % 2) * 4, 7, 7)
        c.shade(bm, rb)
        if kind == "cow":
            for (x, y, r_) in [(0.36, 0.45, 6), (0.58, 0.55, 7), (0.25, 0.55, 4)]:
                c.fill(c.ellipse(W2 * x, H2 * y + (4 if rest else 0), r_, r_ * 0.8) & bm, C(acc))
        if kind == "pig":
            c.line([(W2 * 0.1, cy - 2), (W2 * 0.06, cy - 6), (W2 * 0.1, cy - 8)], C(acc), 2)
        hy = cy - H2 * 0.12 + (10 if act and f % 2 == 0 else 0) + (6 if rest else 0)
        hx_ = W2 * 0.8
        hm = c.ellipse(hx_, hy, W2 * 0.13, H2 * 0.15)
        c.shade(hm, R(body if kind != "sheep" else acc))
        c.fill(c.rect(int(hx_ + 1), int(hy - 3), int(hx_ + 3), int(hy - 1)), OUTLINE if not rest else R(body)[1])
        if kind == "pig":
            c.shade(c.ellipse(hx_ + W2 * 0.1, hy + 2, 4, 3.5), R(acc))
        if kind in ("cow", "goat"):
            c.line([(hx_ - 4, hy - H2 * 0.12), (hx_ - 7, hy - H2 * 0.24)], C("e8e0c8"), 2)
            c.line([(hx_ + 2, hy - H2 * 0.12), (hx_ + 3, hy - H2 * 0.24)], C("e8e0c8"), 2)
        c.shade(c.ellipse(hx_ - 6, hy - H2 * 0.06, 4, 2.5), R(body if kind != "sheep" else acc))
        if kind == "goat":
            c.line([(hx_ + 4, hy + H2 * 0.12), (hx_ + 5, hy + H2 * 0.2)], C("e8e0c8"), 2)
        if not rest:
            lc = R(acc if kind in ("sheep",) else body)[1]
            for lx, d in ((0.24, leg), (0.34, -leg), (0.58, -leg), (0.68, leg)):
                c.line([(W2 * lx, cy + H2 * 0.14), (W2 * lx + d, H2 - 2)], lc, 3)
                c.dot(int(W2 * lx + d), H2 - 2, OUTLINE)
    if f in (5,):     # моргание: ничего, просто тот же кадр
        pass
    c.outline()
    return c


def gen_farm():
    for k, v in FARM.items():
        frames = [draw_farm(k, f) for f in range(12)]
        sheet(frames, os.path.join(ART, "animal_%s.png" % k))


# =====================================================================================  МОРСКИЕ РЫБЫ
# id: имя, описание, вес (шанс), зона, скорость, цена, длина (от 1), цвет, узор, глубина (0..1 где чаще), говорящая
SEA = {
    "sea_sardine": ["Сардинка", "Серебристая крошка, ходит огромными стаями.", 30, 0.30, 1.2, 4, 0.6, "a8c0d8", "stripe", 0.2],
    "sea_mackerel": ["Скумбрия", "Полосатая и быстрая. Жирненькая — вкусная на углях.", 24, 0.24, 1.4, 8, 0.9, "3a8a8a", "zebra", 0.4],
    "sea_herring": ["Сельдь", "Морская серебрянка. Солят бочками.", 26, 0.26, 1.2, 6, 0.8, "b0c8e0", "plain", 0.3],
    "sea_flounder": ["Камбала", "Плоская, оба глаза на одном боку. Лежит на дне и притворяется песком.", 16, 0.2, 0.9, 12, 0.9, "c0a070", "dots", 0.7],
    "sea_bass": ["Морской окунь", "Красный, глазастый, колючий.", 16, 0.2, 1.3, 14, 1.0, "e05040", "plain", 0.6],
    "sea_tuna": ["Тунец", "Торпеда океана. Тянет леску, как лошадь телегу.", 8, 0.14, 1.9, 40, 1.6, "3a4a8a", "plain", 0.9],
    "sea_swordfish": ["Рыба-меч", "Нос — настоящая шпага. Дуэлянтка морей.", 4, 0.11, 2.0, 70, 1.8, "5a6aa0", "sword", 0.95],
    "sea_clown": ["Рыба-клоун", "Оранжевая с белыми полосками. Живёт в анемонах.", 12, 0.2, 1.5, 18, 0.5, "f08020", "clown", 0.3],
    "sea_puffer": ["Рыба-фугу", "Надувается шариком, если испугать. Не ешь без повара!", 10, 0.2, 1.1, 22, 0.6, "e0c060", "dots", 0.4],
    "sea_angel": ["Рыба-ангел", "Жёлто-синяя красавица рифов.", 9, 0.18, 1.4, 26, 0.6, "f0d040", "angel", 0.4],
    "sea_moray": ["Мурена", "Длинная, зубастая, живёт в норе. Улыбается жутко, но вежливо.", 7, 0.15, 1.6, 32, 1.4, "6a8a3a", "dots", 0.8],
    "sea_ray": ["Скат", "Плывёт, как ковёр-самолёт.", 6, 0.16, 1.2, 36, 1.4, "7a7a90", "ray", 0.7],
    "sea_octopus": ["Осьминог", "Восемь лап и все хватаются за леску.", 6, 0.15, 1.5, 34, 1.0, "d06060", "octo", 0.6],
    "sea_squid": ["Кальмар", "Пускает чернила и обиженно уплывает.", 8, 0.17, 1.6, 24, 1.0, "f0c0b0", "squid", 0.6],
    "sea_lobster": ["Омар", "Клешни как кузнечные клещи. Аристократ морского дна.", 6, 0.16, 1.1, 38, 0.9, "c03020", "crab", 0.8],
    "sea_crab": ["Краб", "Ходит боком и щёлкает клешнями.", 14, 0.22, 1.0, 12, 0.6, "e06030", "crab", 0.3],
    "sea_jelly": ["Медуза", "Прозрачный зонтик. Не трогай руками.", 10, 0.2, 0.8, 10, 0.6, "c0a0f0", "jelly", 0.5],
    "sea_seahorse": ["Морской конёк", "Крошечная лошадка с хвостиком-крючком.", 7, 0.14, 1.3, 30, 0.4, "f0a040", "horse", 0.3],
    "sea_lantern": ["Удильщик", "С фонариком на лбу. Живёт там, где всегда ночь.", 4, 0.12, 1.5, 60, 1.0, "3a3a4a", "lantern", 1.0],
    "sea_oarfish": ["Сельдяной король", "Длинная серебряная лента с красным гребнем. Говорят — к удаче.", 2, 0.1, 1.9, 120, 2.2, "d0d8e8", "oar", 1.0],
    "shark_reef": ["Рифовая акула", "Небольшая и любопытная. Кусает только наживку.", 5, 0.13, 1.8, 60, 1.6, "8a9aa8", "shark", 0.7],
    "shark_hammer": ["Акула-молот", "Голова как молот у кузнеца. Видит всё вокруг.", 3, 0.11, 2.0, 110, 2.0, "8a94a0", "hammer", 0.85],
    "shark_tiger": ["Тигровая акула", "Полосатая обжора. Ест даже старые сапоги.", 3, 0.1, 2.1, 120, 2.1, "7a8070", "tiger", 0.85],
    "shark_white": ["Большая белая акула", "Королева моря. Огромная, но сегодня в хорошем настроении.", 1.5, 0.08, 2.3, 220, 2.4, "8090a0", "shark", 0.95],
    "shark_whale": ["Китовая акула", "Самая большая рыба на свете — и самая добрая. Ест планктон.", 1.2, 0.09, 1.4, 260, 2.5, "4a5a7a", "whale", 0.95],
    "shark_mako": ["Акула-мако", "Самая быстрая акула. Прыгает выше пирса!", 2, 0.08, 2.5, 160, 1.9, "4a6aa0", "shark", 0.9],
    "shark_goblin": ["Акула-домовой", "Розовая, носатая, глубоководная. Странная, но милая.", 1, 0.08, 2.0, 240, 1.9, "e0a0a0", "goblin", 1.0],
    "shark_mega": ["Мегалодон", "Его считали вымершим. Он просто был занят.", 0.3, 0.06, 2.6, 900, 2.8, "5a6a7a", "shark", 1.0],
    "sea_golden": ["Золотая рыбка", "Особенная. Разговаривает и терпеть не может, когда её путают со сказочной.", 0.6, 0.08, 2.2, 0, 0.6, "f0b820", "golden", 0.6],
    "sea_wise_cat": ["Старый морской сом", "Усатый мудрец. Помнит всех капитанов этого берега.", 0.6, 0.1, 1.2, 0, 1.4, "6a5a48", "cat", 0.9],
    "sea_bard": ["Рыба-бард", "Поёт под водой баллады о кораблекрушениях. Смешные.", 0.6, 0.12, 1.4, 0, 0.7, "a060e0", "angel", 0.5],
    "sea_moon": ["Лунная рыба", "Светится серебром. Приплывает только ночью.", 0.6, 0.1, 1.6, 0, 1.0, "e0e8ff", "moon", 0.8],
}
TALKING = ["sea_golden", "sea_wise_cat", "sea_bard", "sea_moon"]


def draw_fish(fid, big=False):
    v = SEA[fid]
    col, pat, L = v[7], v[8], v[6]
    W = 32 if not big else 64
    c = Canvas(W, W)
    rb = R(col)
    s = W / 32.0
    cx, cy = W / 2, W / 2
    ln = min(14.0, 6 + L * 3.0) * s
    hgt = (4.0 if pat not in ("angel", "ray", "golden", "moon", "dots") else 6.5) * s
    if pat in ("octo", "squid", "jelly"):
        hm = c.ellipse(cx, cy - 4 * s, 7 * s, 6 * s)
        c.shade(hm, rb)
        for k in range(5 if pat != "squid" else 4):
            x = cx - 6 * s + k * 3 * s
            c.line([(x, cy), (x + (k % 2 * 2 - 1) * 2 * s, cy + 9 * s)], rb[1], max(1, int(1.5 * s)))
        if pat != "jelly":
            c.dot(int(cx - 2 * s), int(cy - 4 * s), OUTLINE); c.dot(int(cx + 2 * s), int(cy - 4 * s), OUTLINE)
        c.outline(); return c
    if pat == "crab":
        c.shade(c.ellipse(cx, cy + 2 * s, 8 * s, 5 * s), rb)
        for sx in (-1, 1):
            c.shade(c.ellipse(cx + sx * 10 * s, cy - 4 * s, 3 * s, 3 * s), rb)
            c.line([(cx + sx * 6 * s, cy), (cx + sx * 9 * s, cy - 2 * s)], rb[1], max(1, int(s)))
            for k in range(3):
                c.line([(cx + sx * 5 * s, cy + (2 + k * 2) * s), (cx + sx * 10 * s, cy + (4 + k * 2) * s)], rb[1])
        c.dot(int(cx - 2 * s), int(cy - 2 * s), OUTLINE); c.dot(int(cx + 2 * s), int(cy - 2 * s), OUTLINE)
        c.outline(); return c
    if pat == "horse":
        m = c.ellipse(cx, cy - 6 * s, 3 * s, 3 * s)
        m |= c.ellipse(cx + 1 * s, cy + 1 * s, 3 * s, 6 * s)
        m |= c.line_mask([(cx, cy + 6 * s), (cx - 3 * s, cy + 10 * s), (cx - 1 * s, cy + 12 * s)], max(1, int(2 * s)))
        m |= c.line_mask([(cx + 2 * s, cy - 6 * s), (cx + 6 * s, cy - 5 * s)], max(1, int(2 * s)))
        c.shade(m, rb)
        c.dot(int(cx + 1 * s), int(cy - 7 * s), OUTLINE)
        c.outline(); return c
    if pat == "ray":
        m = c.poly([(cx - 11 * s, cy), (cx, cy - 7 * s), (cx + 11 * s, cy), (cx, cy + 6 * s)])
        c.shade(m, rb)
        c.line([(cx, cy + 5 * s), (cx + 1 * s, cy + 14 * s)], rb[1])
        c.dot(int(cx - 2 * s), int(cy - 2 * s), OUTLINE); c.dot(int(cx + 2 * s), int(cy - 2 * s), OUTLINE)
        c.outline(); return c
    body = c.ellipse(cx - 1 * s, cy, ln, hgt)
    if pat in ("oar",):
        body = c.ellipse(cx, cy, 15 * s, 2.2 * s)
    if pat == "whale":
        body = c.ellipse(cx - 1 * s, cy, ln, hgt + 1.5 * s)
    c.shade(body, rb)
    tail = c.poly([(cx + ln - 2 * s, cy), (cx + ln + 5 * s, cy - (6 if "shark" in fid or pat in ("hammer", "tiger", "whale", "goblin", "sword") else 4) * s), (cx + ln + 4 * s, cy + 4 * s)])
    c.shade(tail, rb)
    if "shark" in fid or pat in ("shark", "hammer", "tiger", "whale", "goblin"):
        c.shade(c.poly([(cx - 2 * s, cy - hgt + 1), (cx + 3 * s, cy - hgt - 6 * s), (cx + 5 * s, cy - hgt + 1)]), rb)
        belly = c.ellipse(cx - 2 * s, cy + hgt * 0.5, ln * 0.8, hgt * 0.45) & body
        c.fill(belly, C("e8ecf0"))
        for k in range(3):
            c.line([(cx - ln * 0.45 + k * 1.5 * s, cy - 1 * s), (cx - ln * 0.45 + k * 1.5 * s, cy + 1 * s)], rb[1])
        if pat == "hammer":
            c.shade(c.rect(int(cx - ln - 2 * s), int(cy - 5 * s), int(cx - ln + 2 * s), int(cy + 5 * s)), rb)
        if pat == "tiger":
            for k in range(5):
                c.line([(cx - ln * 0.4 + k * 3 * s, cy - hgt + 1), (cx - ln * 0.4 + k * 3 * s + 1, cy)], rb[1])
        if pat == "whale":
            r2 = np.random.default_rng(5)
            for k in range(14):
                x, y = int(cx - ln + r2.random() * ln * 1.8), int(cy - hgt + r2.random() * hgt)
                if 0 <= x < W and 0 <= y < W and body[y, x]:
                    c.dot(x, y, C("e8ecf0"))
        if pat == "goblin":
            c.shade(c.poly([(cx - ln - 4 * s, cy - 2 * s), (cx - ln + 2 * s, cy - 3 * s), (cx - ln + 2 * s, cy)]), rb)
    if pat == "sword":
        c.line([(cx - ln, cy), (cx - ln - 10 * s, cy - 1)], rb[3], max(1, int(s)))
    if pat == "zebra":
        for k in range(5):
            c.line([(cx - ln * 0.6 + k * 3 * s, cy - hgt + 1), (cx - ln * 0.6 + k * 3 * s + 2, cy)], rb[0])
    if pat == "stripe":
        c.line([(cx - ln, cy), (cx + ln, cy)], rb[4])
    if pat == "dots":
        r2 = np.random.default_rng(len(fid))
        for k in range(10):
            x, y = int(cx - ln + r2.random() * ln * 2), int(cy - hgt + r2.random() * hgt * 2)
            if 0 <= x < W and 0 <= y < W and body[y, x]:
                c.dot(x, y, rb[0])
    if pat == "clown":
        for k in (-0.5, 0.1, 0.6):
            c.fill(c.rect(int(cx + k * ln), int(cy - hgt), int(cx + k * ln + 2 * s), int(cy + hgt)) & body, C("f8f8f8"))
    if pat == "angel":
        c.shade(c.poly([(cx - 2 * s, cy - hgt + 1), (cx + 4 * s, cy - hgt - 6 * s), (cx + 6 * s, cy - 2 * s)]), R("3060c0"))
        c.shade(c.poly([(cx - 2 * s, cy + hgt - 1), (cx + 4 * s, cy + hgt + 6 * s), (cx + 6 * s, cy + 2 * s)]), R("3060c0"))
    if pat == "lantern":
        c.line([(cx - ln * 0.5, cy - hgt), (cx - ln - 2 * s, cy - hgt - 6 * s)], rb[3])
        c.shade(c.ellipse(cx - ln - 2 * s, cy - hgt - 6 * s, 2 * s, 2 * s), R("f0f080"))
        for k in range(4):
            c.dot(int(cx - ln + 1 + k * s), int(cy + 1 * s), (255, 255, 255, 255))
    if pat == "oar":
        for k in range(10):
            c.dot(int(cx - 14 * s + k * 3 * s), int(cy - 3 * s), C("e04040"))
    if pat in ("golden", "moon"):
        c.shade(c.poly([(cx + ln - 2 * s, cy), (cx + ln + 8 * s, cy - 8 * s), (cx + ln + 6 * s, cy), (cx + ln + 8 * s, cy + 8 * s)]), rb)
        c.shade(c.poly([(cx - 3 * s, cy - hgt + 1), (cx + 3 * s, cy - hgt - 5 * s), (cx + 5 * s, cy - hgt + 2)]), rb)
        if pat == "golden":   # корона? нет — бантик: «я не та рыбка»
            c.shade(c.ellipse(cx - 2 * s, cy - hgt - 1 * s, 2 * s, 1.5 * s), R("e04060"))
            c.shade(c.ellipse(cx + 2 * s, cy - hgt - 1 * s, 2 * s, 1.5 * s), R("e04060"))
        else:
            for k in range(4):
                c.dot(int(cx - ln + 3 * k * s + 2), int(cy - 1 * s), (255, 255, 255, 255))
    if pat == "cat":
        for sy in (-1, 1):
            c.line([(cx - ln + 1 * s, cy + 1 * s), (cx - ln - 5 * s, cy + sy * 3 * s + 2 * s)], C("e0d8c0"))
    # глаз
    ex, ey = int(cx - ln * 0.6), int(cy - hgt * 0.25)
    c.dot(ex, ey, (255, 255, 255, 255))
    c.dot(ex, ey + 1 if big else ey, OUTLINE) if not big else c.fill(c.rect(ex, ey, ex + 2, ey + 2), OUTLINE)
    c.outline()
    return c


def gen_fish():
    for fid in SEA:
        draw_fish(fid).save(os.path.join(ART, "fish_%s.png" % fid))
    # плавающие под водой (для героини в хвосте): 2 кадра, крупно, без значка
    for fid in SEA:
        a = draw_fish(fid, True)
        b = Canvas(64, 64)
        b.px[1:, :] = a.px[:-1, :]
        sheet([a, b], os.path.join(ART, "swim_%s.png" % fid))


# =====================================================================================  ПОДЗЕМЕЛЬЯ
THEMES = {
    "cave": ["Пещера", "6a6670", "3a3640", "8a8478"],
    "forest": ["Корневой грот", "6a5a3a", "3a2e20", "5a8a3a"],
    "ice": ["Ледяная пещера", "a8c8e0", "4a6a90", "e0f0ff"],
    "sand": ["Песчаная гробница", "d8b878", "8a6a3a", "f0d8a0"],
    "swamp": ["Топкая нора", "5a6a3a", "2a3420", "7a9a4a"],
    "crystal": ["Хрустальный грот", "6a5a90", "302850", "a8e8ff"],
    "crypt": ["Склеп", "5a5060", "2a2430", "8a7a8a"],
    "lava": ["Огненные недра", "5a3a30", "2a1a18", "ff7030"],
    "elven": ["Древние руины", "8a9a7a", "3a4a3a", "a0e080"],
    "hell": ["Пекло", "7a2a24", "2a0a0a", "ff4020"],
}


def gen_dun():
    for th, v in THEMES.items():
        fl = Canvas(32, 32)
        rr = R(v[1])
        r = np.random.default_rng(len(th) * 7)
        fl.px[:, :] = rr[2]
        # плиты/камешки
        for k in range(14):
            x, y = r.integers(0, 32), r.integers(0, 32)
            rad = r.integers(2, 5)
            m = fl.ellipse(x, y, rad, rad * 0.7)
            fl.fill(m, rr[int(r.integers(1, 4))])
        for k in range(30):
            fl.dot(int(r.integers(0, 32)), int(r.integers(0, 32)), rr[int(r.integers(0, 5))])
        if th in ("crypt", "elven", "sand", "hell"):
            for y in (0, 16):
                fl.line([(0, y), (31, y)], rr[0])
            for x in (0, 16):
                fl.line([(x, 0), (x, 31)], rr[0])
        if th in ("lava", "hell"):
            for k in range(4):
                x, y = r.integers(2, 30), r.integers(2, 30)
                fl.line([(x, y), (x + r.integers(-5, 6), y + r.integers(-5, 6))], C(v[3]))
        fl.save(os.path.join(ART, "dun_floor_%s.png" % th))
        wl = Canvas(32, 32)
        wr = R(v[2])
        wl.px[:, :] = wr[1]
        for k in range(10):
            x, y = r.integers(0, 32), r.integers(0, 32)
            m = wl.ellipse(x, y, r.integers(3, 7), r.integers(2, 5))
            wl.shade(m, wr, flat=0.3)
        wl.fill(wl.rect(0, 26, 32, 32), wr[0])
        for k in range(6):
            wl.dot(int(r.integers(0, 32)), int(r.integers(2, 24)), C(v[3]))
        wl.save(os.path.join(ART, "dun_wall_%s.png" % th))
    # сундуки трёх видов (закрыт / открыт)
    for kind, col, met in [("wood", "8a5a30", "a0a0a8"), ("iron", "6a6a78", "e0c040"), ("gold", "c89a30", "fff0a0"), ("hell", "6a1a1a", "ff6030")]:
        for opened in (0, 1):
            c = Canvas(26, 24)
            body = c.rect(2, 10, 24, 23)
            c.shade(body, R(col))
            if opened:
                c.fill(c.rect(4, 8, 22, 12), C("1a1010"))
                c.shade(c.rect(2, 0, 24, 8), R(col))
                c.dot(12, 9, C("fff080")); c.dot(15, 10, C("f0c040")); c.dot(9, 10, C("80e0ff"))
            else:
                c.shade(c.ellipse(13, 10, 11, 6) & c.rect(0, 0, 26, 11), R(col))
                c.shade(c.rect(11, 9, 15, 14), R(met))
            for x in (4, 21):
                c.shade(c.rect(x, 9 if not opened else 10, x + 2, 23), R(met))
            c.outline()
            c.save(os.path.join(ART, "dun_chest_%s%s.png" % (kind, "_open" if opened else "")))
    # лестница наверх, портал в ад, факел, кости-украшения
    c = Canvas(32, 32)
    for k in range(5):
        c.shade(c.rect(4 + k, 4 + k * 5, 28 - k, 9 + k * 5), R("8a8478"))
    c.outline(); c.save(os.path.join(ART, "dun_stairs.png"))
    for f in range(4):
        c = Canvas(48, 64)
        c.shade(c.rect(2, 4, 46, 64), R("3a1a1a"))
        hole = c.ellipse(24, 34, 16, 26)
        c.fill(hole, C("2a0606"))
        for k in range(5):
            m = c.ellipse(24, 34, 16 - k * 3, 26 - k * 5)
            m &= ~c.ellipse(24, 34, 14 - k * 3, 24 - k * 5)
            c.fill(m, R("ff4020")[(k + f) % 5])
        for (x, y) in [(10, 8), (38, 8), (24, 2)]:
            c.shade(c.poly([(x - 3, y + 6), (x, y - 4), (x + 3, y + 6)]), R("e0d8c0"))
        c.outline()
        c.save(os.path.join(ART, "dun_portal_%d.png" % f))
    sheet([Canvas(1, 1)], os.path.join(ART, "dun_tmp.png"))
    os.remove(os.path.join(ART, "dun_tmp.png"))
    for f in range(2):
        c = Canvas(10, 22)
        c.shade(c.rect(4, 8, 7, 22), R("6a4a30"))
        c.fill(c.ellipse(5, 5 - f, 3, 4 + f), C("ff8030"))
        c.fill(c.ellipse(5, 6, 1.5, 2), C("fff080"))
        c.outline()
        c.save(os.path.join(ART, "dun_torch_%d.png" % f))
    # вход в подземелье (на поверхности): каменная арка с тёмным провалом, по биомам — цвет
    for th, v in THEMES.items():
        if th == "hell":
            continue
        c = Canvas(56, 48)
        rock = c.ellipse(28, 30, 27, 20)
        c.shade(rock, R(v[2] if th not in ("ice", "sand") else v[1]))
        hole = c.ellipse(28, 34, 12, 12) & c.rect(0, 0, 56, 47)
        c.fill(hole, C("140e16"))
        c.fill(c.rect(16, 40, 40, 48) & rock, R(v[1])[1])
        for k in range(6):
            c.dot(10 + k * 7, 20 + (k % 3) * 4, C(v[3]))
        if th == "crystal":
            for x in (8, 46):
                c.shade(c.poly([(x - 3, 24), (x, 10), (x + 3, 24)]), R("a8e8ff"))
        if th == "forest":
            c.line([(6, 18), (16, 26), (14, 34)], C("6a4a30"), 2)
            c.line([(50, 16), (42, 26)], C("6a4a30"), 2)
        c.outline()
        c.save(os.path.join(ART, "dun_entry_%s.png" % th))


# =====================================================================================  ПРОЧЕЕ: книги, приколы, продукты
BOOKS = {
    # id: название, цвет, вид (magic — навык, recipe — рецепт зелья, food — рецепт блюда, lore — история)
    "book_magic_herb": ["Гримуар травницы", "40a050", "magic", "herb"],
    "book_magic_shroom": ["Тайная книга грибника", "a04040", "magic", "shroom"],
    "book_magic_mine": ["Руны глубин", "6a6a80", "magic", "mine"],
    "book_magic_chop": ["Сказ о лесорубе", "8a5a30", "magic", "chop"],
    "book_magic_fish": ["Песни рыбаков", "3a70b0", "magic", "fish"],
    "book_magic_tame": ["Язык зверей", "c08040", "magic", "tame"],
    "book_magic_brew": ["Свиток алхимика", "8040b0", "magic", "brew"],
    "book_magic_combat": ["Наука доброй драки", "c03030", "magic", "combat"],
    "book_magic_cook": ["Поваренная магия", "e0a030", "magic", "cook"],
    "book_magic_craft": ["Секреты мастеров", "707070", "magic", "craft"],
    "book_magic_trade": ["Золотая книга торговки", "f0c840", "magic", "trade"],
    "book_magic_lead": ["Наставление правительнице", "b01e34", "magic", "lead"],
    "book_recipe": ["Книга рецептов зелий", "5a3a80", "recipe", ""],
    "book_food": ["Книга рецептов блюд", "c07030", "food", ""],
    "book_lore": ["Старая летопись", "6a5038", "lore", ""],
    "book_spell_light": ["Заклинание: Светлячок", "f0e080", "spell", "light"],
    "book_spell_speed": ["Заклинание: Ветер в пятках", "80d0f0", "spell", "speed"],
    "book_spell_heart": ["Заклинание: Тёплое сердце", "f08090", "spell", "hp"],
}
JOKES = {
    "joke_duck": ["Резиновая уточка", "Пищит, если сжать. Монстры её боятся. Наверное.", "f0d020"],
    "joke_cushion": ["Подушка-пукалка", "Положи на стул лидеру. Только не говори, что от меня.", "e05050"],
    "joke_mustache": ["Накладные усы", "Теперь тебя никто не узнает. Даже кот.", "3a2a20"],
    "joke_sock": ["Одинокий носок", "Пара от него сбежала ещё в прошлом веке.", "a0a0f0"],
    "joke_glasses": ["Очки с глазами на пружинках", "Бзынь-бзынь.", "40a040"],
    "joke_crown": ["Бумажная корона", "Почти настоящая. Если не присматриваться.", "f0c840"],
    "joke_note": ["Записка «Здесь был Гоблин»", "Спасибо, Гоблин.", "f0e8d0"],
    "joke_teeth": ["Заводная челюсть", "Клацает сама. Жуть и прелесть.", "f4f0e8"],
    "joke_horn": ["Дудка-пищалка", "Пииииу!", "e080f0"],
    "joke_snowglobe": ["Снежный шар с монстром", "Внутри маленький слизень. Он машет.", "a0d8ff"],
    "joke_cheese": ["Подозрительный сыр", "Пахнет приключениями.", "f0d060"],
    "joke_mirror": ["Кривое зеркальце", "Покажет тебя смешной. Ты и так милая.", "c0c8d8"],
}
PRODUCTS = {
    "egg": ["Яйцо", "f4ecd8", "egg"], "egg_duck": ["Утиное яйцо", "c8e0d0", "egg"], "egg_goose": ["Гусиное яйцо", "f8f4f0", "egg"],
    "milk": ["Кувшин молока", "f8f8f4", "jug"], "milk_goat": ["Козье молоко", "f4f0e0", "jug"], "milk_rainbow": ["Радужное молоко", "f0b0f0", "jug"],
    "wool_raw": ["Овечья шерсть", "f0ece4", "fluff"], "truffle": ["Трюфель", "4a3a30", "lump"], "manure": ["Навоз для грядок", "6a4a2a", "lump"],
    "hp_potion": ["Целебный пирожок", "e0a050", "pie"],
}


def gen_misc():
    for bid, b in BOOKS.items():
        c = Canvas(24, 24)
        rb = R(b[1])
        c.shade(c.poly([(4, 5), (17, 3), (20, 19), (7, 21)]), rb)
        c.fill(c.line_mask([(7, 21), (20, 19)], 2), C("f4ecd8"))
        c.line([(5, 6), (8, 20)], rb[0])
        if b[2] == "magic":
            c.dot(12, 11, C("fff080")); c.dot(11, 11, C("f0c040")); c.dot(13, 11, C("f0c040")); c.dot(12, 10, C("f0c040")); c.dot(12, 12, C("f0c040"))
        elif b[2] == "recipe":
            c.shade(c.ellipse(12, 12, 2.5, 3), R("60e080")); c.dot(12, 8, C("e0d0b0"))
        elif b[2] == "food":
            c.shade(c.ellipse(12, 12, 3.5, 2.5), R("e08040"))
        elif b[2] == "spell":
            for k in range(4):
                c.dot(9 + k * 2, 9 + (k % 2) * 4, C("ffffff"))
        else:
            c.line([(9, 9), (15, 8)], rb[4]); c.line([(9, 12), (15, 11)], rb[4])
        c.outline()
        c.save(os.path.join(ART, "icon_%s.png" % bid))
    shapes = ["duck", "cushion", "mustache", "sock", "glasses", "crown", "note", "teeth", "horn", "snowglobe", "cheese", "mirror"]
    for jid, j in JOKES.items():
        c = Canvas(24, 24)
        rr = R(j[2])
        sh = jid[5:]
        if sh == "duck":
            c.shade(c.ellipse(11, 15, 8, 5), rr); c.shade(c.ellipse(15, 8, 4.5, 4.5), rr)
            c.shade(c.poly([(18, 8), (23, 9), (18, 11)]), R("f08020")); c.dot(16, 7, OUTLINE)
        elif sh == "cushion":
            c.shade(c.ellipse(12, 13, 9, 7), rr); c.shade(c.rect(19, 11, 23, 15), rr); c.line([(8, 10), (14, 12)], rr[4])
        elif sh == "mustache":
            c.shade(c.ellipse(7, 12, 6, 3), rr); c.shade(c.ellipse(17, 12, 6, 3), rr); c.shade(c.ellipse(12, 11, 2, 2), rr)
        elif sh == "sock":
            c.shade(c.poly([(8, 2), (15, 2), (15, 14), (21, 17), (19, 22), (8, 18)]), rr); c.fill(c.rect(8, 2, 15, 5), C("f4f0e8"))
        elif sh == "glasses":
            for x in (7, 17):
                c.shade(c.ellipse(x, 14, 4, 4), R("e0f0f8")); c.line([(x, 14), (x + 1, 6)], C("8a8a90"))
                c.shade(c.ellipse(x + 1, 5, 2.5, 2.5), R("f4f4f4")); c.dot(x + 1, 5, OUTLINE)
            c.line([(11, 14), (13, 14)], rr[1])
        elif sh == "crown":
            c.shade(c.poly([(3, 18), (3, 7), (8, 12), (12, 5), (16, 12), (21, 7), (21, 18)]), rr)
        elif sh == "note":
            c.shade(c.rect(4, 4, 20, 20), rr, flat=0.6)
            for y in (8, 11, 14):
                c.line([(7, y), (17, y)], C("6a5a48"))
        elif sh == "teeth":
            c.shade(c.ellipse(12, 10, 8, 4), R("e06070")); c.shade(c.ellipse(12, 15, 8, 4), R("e06070"))
            for x in range(6, 19, 3):
                c.fill(c.rect(x, 9, x + 2, 12), C("f4f0e8")); c.fill(c.rect(x, 13, x + 2, 16), C("f4f0e8"))
        elif sh == "horn":
            c.shade(c.poly([(3, 12), (14, 9), (21, 4), (21, 20), (14, 15)]), rr)
        elif sh == "snowglobe":
            c.shade(c.rect(5, 18, 19, 22), R("8a5a30")); c.fill(c.ellipse(12, 11, 8, 8), (200, 230, 250, 220))
            c.shade(c.ellipse(12, 14, 3, 2.5), R("60c060")); c.dot(9, 7, (255, 255, 255, 255)); c.dot(15, 9, (255, 255, 255, 255))
        elif sh == "cheese":
            c.shade(c.poly([(3, 17), (20, 8), (21, 18), (4, 21)]), rr)
            for (x, y) in [(9, 16), (15, 13), (17, 17)]:
                c.dot(x, y, rr[0])
        elif sh == "mirror":
            c.shade(c.ellipse(12, 10, 7, 8), R("c8a060")); c.fill(c.ellipse(12, 10, 5, 6), C(j[2])); c.shade(c.rect(11, 17, 13, 23), R("c8a060"))
        c.outline()
        c.save(os.path.join(ART, "icon_%s.png" % jid))
    for pid, p in PRODUCTS.items():
        c = Canvas(24, 24)
        rr = R(p[1])
        if p[2] == "egg":
            c.shade(c.ellipse(12, 13, 6, 7.5), rr)
            if pid == "egg_duck":
                for (x, y) in [(10, 10), (14, 14), (11, 17)]:
                    c.dot(x, y, rr[1])
        elif p[2] == "jug":
            c.shade(c.poly([(7, 6), (17, 6), (19, 21), (5, 21)]), R("c89060"))
            c.fill(c.ellipse(12, 7, 5, 1.5), C(p[1]))
            c.line([(18, 9), (21, 12), (18, 16)], C("c89060"))
        elif p[2] == "fluff":
            for (x, y) in [(8, 12), (12, 9), (16, 12), (10, 15), (14, 15)]:
                c.shade(c.ellipse(x, y, 4.5, 4), rr)
        elif p[2] == "lump":
            c.shade(c.ellipse(12, 14, 7, 5.5), rr)
            for (x, y) in [(10, 12), (14, 15)]:
                c.dot(x, y, rr[1])
        elif p[2] == "pie":
            c.shade(c.ellipse(12, 14, 9, 5), rr); c.shade(c.ellipse(12, 12, 7, 3), R("f0c080"))
            c.dot(12, 10, C("e04060")); c.dot(11, 10, C("e04060"))
        c.outline()
        c.save(os.path.join(ART, "icon_%s.png" % pid))
    # значки HUD: сердечко здоровья, корона статуса, работник, навыки
    for name, col in [("hp_heart", "e04050"), ("hp_heart_empty", "4a3a40")]:
        c = Canvas(14, 13)
        m = c.ellipse(4, 4, 3.5, 3.5) | c.ellipse(10, 4, 3.5, 3.5) | c.poly([(1, 5), (13, 5), (7, 12)])
        c.shade(m, R(col))
        c.outline()
        c.save(os.path.join(ART, "%s.png" % name))
    c = Canvas(24, 20)
    c.shade(c.poly([(2, 18), (2, 6), (7, 11), (12, 3), (17, 11), (22, 6), (22, 18)]), R("f0c840"))
    c.dot(12, 12, C("e02040")); c.dot(7, 14, C("40a0f0")); c.dot(17, 14, C("40c060"))
    c.outline(); c.save(os.path.join(ART, "icon_crown23.png"))
    c = Canvas(24, 24)
    c.shade(c.ellipse(12, 8, 5, 5), R("f0c8a8")); c.shade(c.poly([(5, 22), (7, 13), (17, 13), (19, 22)]), R("6a8a4a"))
    c.shade(c.rect(15, 8, 22, 10), R("8a5a30")); c.shade(c.poly([(19, 4), (23, 8), (19, 12)]), R("a8a8b4"))
    c.outline(); c.save(os.path.join(ART, "icon_worker.png"))
    # знаки приказов
    for name, col, sh in [("ord_rest", "8aa0d0", "z"), ("ord_wood", "8a5a30", "log"), ("ord_herb", "4a9a40", "leaf"), ("ord_shroom", "d04040", "cap"),
                          ("ord_stone", "8a8a90", "rock"), ("ord_fish", "4a80c0", "fish"), ("ord_guard", "a8a8b4", "shield"), ("ord_build", "c09060", "hammer"),
                          ("ord_brew", "8040b0", "pot"), ("ord_farm", "d0b040", "wheat")]:
        c = Canvas(24, 24)
        rr = R(col)
        if sh == "z":
            for k, (x, y) in enumerate([(6, 16), (12, 10), (17, 5)]):
                c.line([(x, y), (x + 4, y), (x, y + 4), (x + 4, y + 4)], rr[2 + k % 2])
        elif sh == "log":
            c.shade(c.line_mask([(4, 16), (19, 9)], 6), rr); c.shade(c.ellipse(19, 9, 3, 3.5), R("e0c090"))
        elif sh == "leaf":
            c.shade(c.poly([(5, 19), (9, 7), (19, 4), (16, 15)]), rr); c.line([(5, 19), (16, 8)], rr[0])
        elif sh == "cap":
            c.shade(c.rect(10, 12, 14, 20), R("f0e4c8")); c.shade(c.ellipse(12, 11, 8, 5) & c.rect(0, 0, 24, 13), rr)
        elif sh == "rock":
            c.shade(c.poly([(4, 18), (7, 9), (14, 6), (20, 11), (19, 19)]), rr)
        elif sh == "fish":
            c.shade(c.ellipse(11, 12, 7, 4), rr); c.shade(c.poly([(17, 12), (22, 8), (22, 16)]), rr); c.dot(7, 11, OUTLINE)
        elif sh == "shield":
            c.shade(c.poly([(5, 4), (19, 4), (19, 12), (12, 21), (5, 12)]), rr); c.line([(12, 5), (12, 19)], C("e0c040"))
        elif sh == "hammer":
            c.shade(c.line_mask([(5, 20), (14, 10)], 2), R("8a5a30")); c.shade(c.poly([(10, 6), (15, 2), (21, 7), (16, 12)]), R("8a8a90"))
        elif sh == "pot":
            c.shade(c.ellipse(12, 15, 8, 6), R("3a3a40")); c.fill(c.ellipse(12, 11, 7, 2), C("80e080")); c.dot(10, 7, C("a0f0a0")); c.dot(14, 5, C("a0f0a0"))
        elif sh == "wheat":
            c.line([(12, 21), (12, 6)], rr[1])
            for y in range(5, 15, 3):
                c.shade(c.ellipse(10, y, 2, 1.5), rr); c.shade(c.ellipse(14, y + 1, 2, 1.5), rr)
        c.outline()
        c.save(os.path.join(ART, "%s.png" % name))


# =====================================================================================  ДАННЫЕ ДЛЯ ИГРЫ
def gd(v):
    """Python -> текст GDScript."""
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, (int, np.integer)):
        return str(int(v))
    if isinstance(v, float):
        return repr(round(v, 4))
    if isinstance(v, str):
        return json.dumps(v, ensure_ascii=False)
    if isinstance(v, (list, tuple)):
        return "[" + ", ".join(gd(x) for x in v) + "]"
    if isinstance(v, dict):
        return "{" + ", ".join("%s: %s" % (gd(k), gd(x)) for k, x in v.items()) + "}"
    raise TypeError(type(v))


def gen_data():
    furn = furn_list()
    wpn, worder = wpn_list()
    mons = {k: {"name": m[0], "size": m[1], "hp": m[2], "dmg": m[3], "speed": m[4], "home": m[5], "shape": m[7]} for k, m in MONS.items()}
    sea = {k: {"name": v[0], "desc": v[1], "weight": v[2], "zone": v[3], "speed": v[4], "price": v[5], "len": v[6], "depth": v[9], "talk": k in TALKING} for k, v in SEA.items()}
    farm = {k: {"name": v[0], "w": v[1], "h": v[2]} for k, v in FARM.items()}
    books = {k: {"name": v[0], "kind": v[2], "skill": v[3]} for k, v in BOOKS.items()}
    jokes = {k: {"name": v[0], "desc": v[1]} for k, v in JOKES.items()}
    prods = {k: {"name": v[0]} for k, v in PRODUCTS.items()}
    themes = {k: {"name": v[0], "light": v[3]} for k, v in THEMES.items()}
    lines = [
        "extends RefCounted",
        "## СГЕНЕРИРОВАНО tools/art_v23.py — не править руками (правь таблицы в скрипте и запускай `python tools/art_v23.py data`).",
        "",
        "const FURN: Dictionary = " + gd(furn),
        "const FURN_STYLES: Array = " + gd(list(STYLES.keys()) + ["village", "special"]),
        "const FURN_CATS: Array = " + gd(list(CATS.keys()) + ["misc"]),
        "const WEAPONS: Dictionary = " + gd(wpn),
        "const WEAPON_ORDER: Array = " + gd(worder),
        "const WEAPON_FX: Dictionary = " + gd(FX_NAME),
        "const MONSTERS: Dictionary = " + gd(mons),
        "const SEA_FISH: Dictionary = " + gd(sea),
        "const SEA_ORDER: Array = " + gd(list(SEA.keys())),
        "const TALKING: Array = " + gd(TALKING),
        "const FARM: Dictionary = " + gd(farm),
        "const BOOKS: Dictionary = " + gd(books),
        "const JOKES: Dictionary = " + gd(jokes),
        "const PRODUCTS: Dictionary = " + gd(prods),
        "const THEMES: Dictionary = " + gd(themes),
        "",
    ]
    with open(os.path.join(ROOT, "v23_data.gd"), "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines))
    print("data:", len(furn), "furniture,", len(wpn), "weapons,", len(mons), "monsters,", len(sea), "sea fish")


if __name__ == "__main__":
    what = sys.argv[1] if len(sys.argv) > 1 else "all"
    for name, fn in [("furn", gen_furn), ("wpn", gen_wpn), ("mon", gen_mon), ("farm", gen_farm), ("fish", gen_fish), ("dun", gen_dun), ("misc", gen_misc), ("data", gen_data)]:
        if what in (name, "all"):
            fn()
            print("ok", name)

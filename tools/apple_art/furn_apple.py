# -*- coding: utf-8 -*-
"""Мебель травника в стиле зелёного яблока и чиби-зверей (с нуля, v34).

Как яблоко/чиби: крупные пиксели (холст = старый логический размер, ×1), пухлые круглые формы,
широкое светлое пятно сверху-слева (режим dome), блик, цветной контур у каждой детали,
никаких волокон/царапин/шума. Детали — крупные и милые.

Запуск: python -I furn_apple.py  -> herbalist_game/art_apple/furn_apple/<tex>.png, _x8.png, _proba.png
"""
import os
import sys
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from apple_engine import Canvas, ell, tube, stroke, poly, rect, up

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
OUT = os.path.join(ROOT, "art_apple", "furn_apple")
OLD = os.path.join(ROOT, "art_real_furn")


def rr(x0, y0, x1, y1, p=4.0):
    """Пухлый прямоугольник (суперэллипс) по пиксельным границам x0..x1, y0..y1 включительно."""
    return ell((x0 + x1 + 1) / 2, (y0 + y1 + 1) / 2, (x1 - x0 + 1) / 2, (y1 - y0 + 1) / 2, p=p)


def puff(c, m, col, shine=True, bias=0):
    return c.add(m, col, mode="dome", shine=shine, tone_bias=bias)


def flat(c, m, col, bias=0, shine=False):
    return c.add(m, col, mode="cel", shine=shine, tone_bias=bias)


def dot(c, x, y, col):
    c.mark(x, y, col)


def mirror(m, cx2):
    """Отразить маску по вертикали x = cx2/2 (cx2 = x0 + x1 для симметрии)."""
    return {(cx2 - x, y) for (x, y) in m}


# ------------------------------------------------------------------ 1. уютная кровать 44x46
def cozy_bed(W=44, H=46):
    c = Canvas(W, H)
    wood = "#d8945a"
    # изголовье: пухлая арка
    puff(c, ell(22, 13, 18, 11, p=2.4) & rect(0, 0, 43, 16) | rr(4, 10, 39, 18), wood)
    puff(c, ell(22, 14, 13, 7, p=2.4) & rect(0, 0, 43, 17), "#b8784a", shine=False)
    # сердечко
    heart = ell(19.5, 10, 2.8, 2.6) | ell(24.5, 10, 2.8, 2.6) | poly([(16.6, 10.5), (27.4, 10.5), (22, 16.2)])
    puff(c, heart, "#f07c9a")
    # столбики-шарики
    for x in (1, 38):
        puff(c, rr(x, 9, x + 4, 43, p=6), wood)
        puff(c, ell(x + 2.5, 8, 3.2, 3.2), "#e8a868")
    # матрас и пухлые подушки
    puff(c, rr(5, 16, 38, 40, p=5), "#f8ecd8", shine=False)
    for x in (7, 22):
        puff(c, rr(x, 16, x + 14, 24, p=3.2), "#fff6e8")
    # отворот простыни
    puff(c, rr(5, 24, 38, 28, p=5), "#f8ecd8", shine=False)
    # одеяло: пухлое, с волнистым краем
    q = rr(4, 27, 39, 40, p=6)
    for k in range(6):
        q |= ell(7.5 + k * 6, 40, 3.2, 2.6)
    puff(c, q, "#f08aa4")
    # лоскуты-сердечки и горошек крупно
    for x, y, col in ((9, 31, "#fff0f4"), (21, 31, "#fff0f4"), (33, 31, "#fff0f4"), (15, 36, "#fff0f4"), (27, 36, "#fff0f4")):
        for dx, dy in ((0, 0), (1, 0), (0, 1), (1, 1)):
            dot(c, x + dx, y + dy, col)
    # изножье
    puff(c, rr(2, 41, 41, 45, p=5), wood)
    return c


# ------------------------------------------------------------------ 2. королевский шкаф 34x46
def royal_wardrobe(W=34, H=46):
    c = Canvas(W, H)
    wood = "#a8483a"
    gold = "#f4c848"
    # корона
    crown = poly([(10, 9), (10.5, 2), (13.5, 5.5), (17, 0.5), (20.5, 5.5), (23.5, 2), (24, 9)])
    puff(c, crown, gold)
    for x, col in ((13, "#f0506a"), (17, "#58b0f8"), (21, "#5cd070")):
        dot(c, x, 6, col)
    # корпус пухлый
    puff(c, rr(2, 8, 31, 41, p=4.5), wood)
    # двери-подушки с бархатом
    for x0 in (5, 17):
        puff(c, rr(x0, 12, x0 + 11, 38, p=3.6), "#c85a48", shine=False)
        arch = ell(x0 + 6, 18, 4.2, 4.5) & rect(0, 0, 40, 18) | rect(x0 + 2, 18, x0 + 9, 34)
        puff(c, arch, "#d83850")
        # лилия
        puff(c, ell(x0 + 6, 24, 2.2, 2.2), gold)   # золотой медальон
        dot(c, x0 + 6, 24, "#f0506a")
    # ручки-шарики
    for x in (15, 18):
        puff(c, ell(x + 0.5, 27, 1.6, 1.6), gold)
    # золотые лапки
    for x in (3, 26):
        puff(c, ell(x + 2.5, 43, 3, 2.6), gold)
    return c


# ------------------------------------------------------------------ 3. эльфийский книжный шкаф 40x52
BOOK = ["#78c068", "#f4cc58", "#e86a5c", "#5c94d8", "#b484d8", "#f4e8d0", "#48a898", "#f09a62"]


def shelf_books(c, x0, x1, ybot, h, seed):
    import random
    r = random.Random(seed)
    x = x0
    while x <= x1:
        w = r.choice([2, 2, 3])
        if x + w - 1 > x1:
            w = x1 - x + 1
        hh = h - r.choice([0, 0, 1, 2])
        col = r.choice(BOOK)
        flat(c, rect(x, ybot - hh + 1, x + w - 1, ybot), col)
        x += w


def elven_bookcase(W=40, H=52):
    c = Canvas(W, H)
    wood = "#ecdcb0"
    leaf = "#84c070"
    # задник
    flat(c, ell(20, 14, 14, 11) & rect(0, 0, 39, 14) | rect(6, 14, 33, 47), "#9c8c68", bias=1)
    for y in (21, 31, 41):
        shelf_books(c, 7, 32, y - 1, 7, seed=y)
        puff(c, rr(5, y, 34, y + 2, p=6), wood, shine=False)
    # горшочек с ростком и баночка-светлячок
    puff(c, rr(8, 25, 12, 30, p=3), "#e08a5c")
    puff(c, ell(10, 23.5, 2.6, 2.2), leaf)
    puff(c, rr(27, 35, 31, 40, p=3), "#c8f4d0")
    c.spark(29, 37, "#fffad0")
    # рама — гладкие пухлые ветви-стволы
    frame = tube([(3, 51), (3, 25), (5, 10), (13, 3)], 3.2, 2.2) | tube([(36, 51), (36, 25), (34, 10), (26, 3)], 3.2, 2.2)
    frame |= ell(20, 3.5, 9, 3)
    puff(c, frame, wood)
    # корни
    for x in (3, 36):
        puff(c, ell(x, 50, 4, 2), "#c8b48a", shine=False)
    # листья по раме — крупные
    for (x, y, a) in ((5, 44, 30), (2, 34, -30), (6, 22, 30), (8, 9, -40), (16, 2, 0), (24, 2, 0), (32, 9, 40), (34, 22, -30), (38, 34, 30), (35, 44, -30)):
        puff(c, ell(x, y, 2.6, 1.6, ang=a), leaf)
    # цветочки
    for (x, y) in ((12, 3), (28, 4), (3, 28), (37, 39)):
        puff(c, ell(x, y, 1.6, 1.6), "#f8b4d0", shine=False)
        dot(c, x, y, "#ffe080")
    return c


# ------------------------------------------------------------------ 4. кошачий стул 18x28
def cat_chair(W=18, H=28):
    c = Canvas(W, H)
    wood = "#e8a870"
    # хвостик
    c.add(tube([(15, 21), (17, 16), (16, 12)], 1.1), wood)
    # спинка — круглая кошачья голова с ушками
    ears = poly([(2.5, 7), (3.5, 0.5), (8, 4)]) | poly([(15.5, 7), (14.5, 0.5), (10, 4)])
    puff(c, ears | ell(9, 8.5, 7, 6, p=2.3), wood)
    flat(c, poly([(4, 5.5), (4.3, 2.5), (6.6, 4.3)]) | poly([(14, 5.5), (13.7, 2.5), (11.4, 4.3)]), "#f6a8c0")
    # мордочка: закрытые глазки-дужки и носик
    for x in (5, 11):
        for p in ((x, 8), (x + 1, 9), (x + 2, 8)):
            dot(c, p[0], p[1], "#7a4a3a")
    dot(c, 8, 10, "#f07a9a"); dot(c, 9, 10, "#f07a9a")
    dot(c, 4, 11, "#f8b0b8"); dot(c, 13, 11, "#f8b0b8")
    # подушка-сиденье
    puff(c, rr(1, 15, 16, 20, p=3), "#f8b4c8")
    for p in ((8, 17), (9, 17), (7, 16), (10, 16)):
        dot(c, p[0], p[1], "#fff4f6")
    # ножки и лапки
    for x in (2, 13):
        puff(c, rr(x, 20, x + 2, 25, p=6), wood, shine=False)
        puff(c, ell(x + 1.5, 26, 2, 1.4), "#fff0f2", shine=False)
    return c


# ------------------------------------------------------------------ 5. лампа мага 14x34
def mage_lamp(W=14, H=34):
    c = Canvas(W, H)
    puff(c, ell(7, 32, 6, 2), "#6a58b0")
    c.add(rect(6, 10, 7, 31), "#6a58b0", mode="cel")
    for y in range(12, 31, 3):
        dot(c, 6, y, "#f4cc58"); dot(c, 7, y + 1, "#f4cc58")
    moon = ell(6, 6, 5, 5) - ell(8, 4.5, 4.2, 4.2)
    puff(c, moon, "#f4d060")
    # фонарик с кристаллом
    c.add(rect(11, 3, 11, 5), "#c8a040", mode="flat", outline=False)
    puff(c, rr(9, 5, 13, 12, p=3), "#4a3c7a", shine=False)
    puff(c, poly([(11, 6), (12.6, 8.6), (11, 11.6), (9.4, 8.6)]) | {(11, 6)}, "#9cecff")
    c.spark(11, 8, "#ffffff")
    for (x, y) in ((2, 15), (12, 19), (3, 23)):
        c.spark(x, y, "#c8f4ff", size=0)
    return c


# ------------------------------------------------------------------ 6. уютный чайный стол 48x32
def cozy_table(W=48, H=32):
    c = Canvas(W, H)
    wood = "#d8945a"
    for x in (8, 37):
        puff(c, rr(x, 18, x + 3, 30, p=5), wood, shine=False)
        puff(c, ell(x + 2, 30, 2.6, 1.4), wood, shine=False)
    puff(c, ell(24, 13, 23, 9, p=2.3), "#b8784a", shine=False)   # кромка
    puff(c, ell(24, 11.5, 23, 8.5, p=2.3), wood)                 # столешница
    # кружевная салфетка с волнами
    cl = ell(24, 12, 15, 6, p=2.2)
    for k in range(-5, 6):
        x = 24 + k * 2.7
        cl |= ell(x, 12 + 5.7 * max(0, 1 - ((x - 24) / 15.5) ** 2) ** 0.5, 1.5, 1.5)
    puff(c, cl, "#fff8ec", shine=False)
    # чайник пухлый
    c.add(tube([(16, 9), (13, 6)], 1.0), "#f08aa4")
    c.add(ell(24.5, 8.5, 2, 2.4) - ell(24.5, 8.5, 0.9, 1.2), "#f08aa4")
    puff(c, ell(20, 8.5, 4.5, 3.8), "#f8a0b8")
    puff(c, ell(20, 5, 2.4, 1.2), "#f8a0b8", shine=False)
    puff(c, ell(20, 3.5, 1, 1), "#f4cc58", shine=False)
    for x in (18, 21):
        dot(c, x, 9, "#fff0f4"); dot(c, x + 1, 9, "#fff0f4")
    # чашки
    for x, col in ((30, "#f8a0b8"), (36, "#98d088")):
        puff(c, ell(x, 13, 2.8, 1.1), "#fff8ec", shine=False)
        c.add(ell(x + 2.6, 10.5, 1.5, 1.5) - {(x + 2, 10)}, col)
        puff(c, rr(x - 2, 8, x + 2, 12, p=3), col)
        for xx in (x - 1, x, x + 1):
            dot(c, xx, 8, "#a8683a")
    # вазочка с цветком
    puff(c, rr(10, 8, 12, 12, p=3), "#8cc8e0")
    c.add(stroke([(11, 8), (11, 6)]), "#68a858", mode="flat", outline=False)
    puff(c, ell(11, 4.5, 2, 2), "#f8a4c4", shine=False)
    dot(c, 11, 4, "#ffe080")
    return c


PROBA = {"fu_cozy_bed": cozy_bed, "fu_royal_wardrobe": royal_wardrobe, "fu_elven_bookcase": elven_bookcase,
         "fu_cat_chair": cat_chair, "fu_mage_lamp": mage_lamp, "fu_cozy_table": cozy_table}


def main():
    os.makedirs(OUT, exist_ok=True)
    pairs = []
    for tex, fn in PROBA.items():
        im = fn().render()
        im.save(os.path.join(OUT, tex + ".png"))
        up(im, 8).save(os.path.join(OUT, tex + "_x8.png"))
        pairs.append((Image.open(os.path.join(OLD, tex + ".png")).convert("RGBA"), im))
    z = 6
    cw = max(max(o.width, n.width) for o, n in pairs) * z + 24
    ch = max(max(o.height, n.height) for o, n in pairs) * z + 24
    sh = Image.new("RGBA", (cw * len(pairs), ch * 2), (240, 232, 214, 255))
    for i, (o, n) in enumerate(pairs):
        for j, im in enumerate((o, n)):
            b = up(im, z)
            sh.alpha_composite(b, (i * cw + (cw - b.width) // 2, (j + 1) * ch - 12 - b.height))
    sh.save(os.path.join(OUT, "_proba.png"))
    print("готово:", OUT)


if __name__ == "__main__":
    main()

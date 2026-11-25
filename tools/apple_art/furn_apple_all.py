# -*- coding: utf-8 -*-
"""Вся мебель «Мебель и дом» в стиле зелёного яблока / чиби (v34), с нуля.

10 видов × стили (кровать, стол, стул, шкаф, книжный шкаф, лампа, ковёр, комод, растение, тумбочка)
+ деревенское (dp_*) и особое (furn_apple_misc.py). Шесть одобренных проб — из furn_apple.py.
Холсты = старые логические размеры (×1), пиксели крупные, формы пухлые, свет сверху-слева.

Запуск: python -I furn_apple_all.py [фильтр...]
  -> herbalist_game/art_apple/furn_apple/<tex>.png, _x8.png; листы _all_new_x3.png, _all_compare.png
"""
import os
import re
import sys
import json
import random
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from apple_engine import Canvas, ell, tube, stroke, poly, rect, up
import furn_apple as FA
from furn_apple import rr, puff, flat, dot, shelf_books

ROOT = FA.ROOT
OUT = FA.OUT
OLD = FA.OLD
GAME = os.path.join(ROOT, "game")

# ------------------------------------------------------------------ стили
ST = {
    "straw":  dict(wood="#d8b870", fab="#ecd490", met="#b89a60", acc="#c8a050", dark="#a88a50"),
    "rough":  dict(wood="#a8805a", fab="#d0c09c", met="#9a9aa4", acc="#8a6444", dark="#806040"),
    "simple": dict(wood="#cc9460", fab="#f6efe2", met="#b0b0b8", acc="#e0b078", dark="#a87448"),
    "cozy":   dict(wood="#d8945a", fab="#f08aa4", met="#f4c858", acc="#fff0f4", dark="#b8784a"),
    "cat":    dict(wood="#e8a870", fab="#f8b4c8", met="#f4c858", acc="#fff0f4", dark="#c88a5a"),
    "japan":  dict(wood="#b0643e", fab="#f6ecd2", met="#5a4646", acc="#e8503e", dark="#8a4a30"),
    "dwarf":  dict(wood="#946646", fab="#c0603c", met="#e09450", acc="#aeb0bc", dark="#744e36"),
    "elven":  dict(wood="#eedfb4", fab="#88c470", met="#f4d878", acc="#f8b4d0", dark="#c8b48a"),
    "sea":    dict(wood="#8eb0c4", fab="#4c90d8", met="#f6e4b8", acc="#f8a8a0", dark="#6a8ca4"),
    "gothic": dict(wood="#64486c", fab="#c82c4c", met="#c0c0d0", acc="#e85068", dark="#4a3454"),
    "mage":   dict(wood="#6050a0", fab="#7060d8", met="#f4d060", acc="#9cecff", dark="#463a80"),
    "royal":  dict(wood="#a8483a", fab="#d83850", met="#f4c848", acc="#fff4c8", dark="#843428"),
}
INK = "#6a4040"


def S(st, k):
    return ST[st][k]


# ------------------------------------------------------------------ значки и навершия
def emblem(c, st, x, y, big=False):
    """Значок стиля с центром (x, y), ~3-5 px."""
    m, a = S(st, "met"), S(st, "acc")
    if st == "cozy":
        h = ell(x - 1, y - 0.5, 1.4, 1.3) | ell(x + 1, y - 0.5, 1.4, 1.3) | poly([(x - 2.4, y - 0.2), (x + 2.4, y - 0.2), (x, y + 2.4)])
        puff(c, h, "#f07c9a", shine=False)
    elif st == "cat":
        puff(c, ell(x, y + 0.8, 1.6, 1.2), "#f6a8c0", shine=False)
        for dx in (-1.6, 0, 1.6):
            dot(c, int(x + dx), int(y - 1.2), "#f6a8c0")
    elif st == "japan":
        puff(c, ell(x, y, 1.8, 1.8), a, shine=False)
    elif st == "dwarf":
        puff(c, poly([(x, y - 2.2), (x + 2.2, y), (x, y + 2.2), (x - 2.2, y)]), m)
    elif st == "elven":
        puff(c, ell(x, y, 1.2, 2.4, ang=35), S(st, "fab"), shine=False)
    elif st == "sea":
        sh = ell(x, y + 0.5, 2.2, 1.8) & rect(0, 0, 999, int(y + 1))
        puff(c, sh | rect(int(x) - 1, int(y) + 1, int(x), int(y) + 1), "#f8b0a8", shine=False)
    elif st == "gothic":
        puff(c, poly([(x - 1.6, y + 2.2), (x - 1.6, y - 0.4), (x, y - 2.6), (x + 1.6, y - 0.4), (x + 1.6, y + 2.2)]), a, shine=False)
    elif st == "mage":
        c.spark(int(x), int(y), "#f8e070", size=1)
    elif st == "royal":
        puff(c, ell(x, y, 1.8, 1.8), m)
        dot(c, int(x), int(y), "#f0506a")
    # rough / simple / straw — без значка


def topper(c, st, x0, x1, y):
    """Навершие над верхней кромкой y (растёт вверх), x0..x1 — ширина предмета."""
    cx = (x0 + x1) / 2
    w, m, a, f = S(st, "wood"), S(st, "met"), S(st, "acc"), S(st, "fab")
    if st == "cat":
        for ex, s in ((x0 + 1, 1), (x1 - 6, -1)):
            puff(c, poly([(ex, y + 1), (ex + 2.5 + s * 0.5, y - 5), (ex + 5.5, y + 1)]), w)
            flat(c, poly([(ex + 1.5, y + 1), (ex + 2.8 + s * 0.4, y - 2.5), (ex + 4.2, y + 1)]), "#f6a8c0")
    elif st == "gothic":
        for sx, hgt in ((x0 + 1, 5), (cx - 2, 8), (x1 - 4, 5)):
            puff(c, poly([(sx, y + 1), (sx + 2, y - hgt), (sx + 4, y + 1)]), w)
            dot(c, int(sx + 2), int(y - hgt + 1), m)
    elif st == "elven":
        puff(c, ell(cx - 2.5, y - 1.5, 3, 1.6, ang=-30), f)
        puff(c, ell(cx + 2.5, y - 1.5, 3, 1.6, ang=30), f)
        puff(c, ell(cx, y - 2, 1.4, 1.4), a, shine=False)
    elif st == "royal":
        puff(c, poly([(cx - 5, y + 1), (cx - 5, y - 4), (cx - 2.5, y - 1.5), (cx, y - 5.5), (cx + 2.5, y - 1.5), (cx + 5, y - 4), (cx + 5, y + 1)]), m)
        dot(c, int(cx), int(y - 2), "#f0506a")
    elif st == "mage":
        puff(c, poly([(cx - 2.2, y + 1), (cx, y - 6), (cx + 2.2, y + 1)]), a)
        c.spark(int(cx), int(y - 3), "#ffffff", size=0)
    elif st == "sea":
        sh = ell(cx, y + 1, 5, 4.5) & rect(0, 0, 999, int(y))
        puff(c, sh, "#f8b0a8")
        for k in (-2, 0, 2):
            dot(c, int(cx + k), int(y - 1), "#e08a88")
    elif st == "cozy":
        emblem(c, "cozy", cx, y - 2)
    elif st == "japan":
        puff(c, rr(int(x0) - 2, int(y) - 2, int(x1) + 2, int(y) + 1, p=6), S(st, "dark"))
    elif st == "dwarf":
        puff(c, rr(int(x0), int(y) - 3, int(x1), int(y) + 1, p=6), S(st, "acc"))
        for xx in range(int(x0) + 2, int(x1) - 1, 4):
            dot(c, xx, int(y) - 1, "#f0c080")


def knob(c, st, x, y):
    puff(c, ell(x + 0.5, y + 0.5, 1.2, 1.2), S(st, "met"), shine=False)


# ------------------------------------------------------------------ КРОВАТЬ 44x46
def bed(st, W=44, H=46):
    c = Canvas(W, H)
    w, f, dk = S(st, "wood"), S(st, "fab"), S(st, "dark")
    if st == "straw":
        puff(c, ell(22, 31, 20, 13, p=2.2), "#e4c878")
        for (x, y) in ((8, 26), (14, 36), (30, 38), (36, 28), (20, 41), (26, 22)):
            c.add(stroke([(x, y), (x + 3, y - 2)]), "#c8a858", mode="flat", outline=False)
        puff(c, rr(9, 18, 30, 30, p=3), "#c8b890")
        puff(c, rr(10, 19, 24, 25, p=3), "#f0e4c0")
        return c
    if st == "japan":
        puff(c, rr(1, 14, 42, 45, p=8), "#d8c890")          # татами
        for y in (22, 30, 38):
            c.add(stroke([(3, y), (40, y)]), "#c0ae74", mode="flat", outline=False)
        puff(c, rr(5, 16, 38, 43, p=5), f)                   # футон
        puff(c, rr(12, 17, 31, 23, p=4), "#fffaf0")          # подушка
        puff(c, rr(5, 26, 38, 43, p=5), "#e8706a")           # одеяло
        for x in (12, 22, 32):
            emblem(c, "japan", x, 34)
            puff(c, ell(x, 34, 1.4, 1.4), "#fff4e8", shine=False)
        return c
    # изголовье
    if st in ("cozy", "elven", "sea", "cat", "mage"):
        hb = ell(22, 13, 18, 10, p=2.4) & rect(0, 0, 43, 15) | rr(4, 10, 39, 18)
    elif st == "gothic":
        hb = poly([(4, 18), (4, 9), (13, 9), (22, 1), (31, 9), (40, 9), (40, 18)])
    elif st == "royal":
        hb = ell(22, 10, 18, 7) & rect(0, 0, 43, 11) | rr(4, 9, 39, 18)
    else:
        hb = rr(4, 7, 39, 18, p=6)
    puff(c, hb, w)
    if st in ("royal", "gothic", "mage"):
        inner = rr(9, 9, 34, 17, p=4) if st != "gothic" else poly([(10, 17), (10, 11), (22, 4), (34, 11), (34, 17)])
        puff(c, inner, f, shine=False)
    elif st not in ("rough", "simple", "dwarf"):
        puff(c, ell(22, 14, 13, 6, p=2.4) & rect(0, 0, 43, 16), dk, shine=False)
    if st == "dwarf":
        for x in range(7, 38, 5):
            dot(c, x, 10, S(st, "met")); dot(c, x, 15, S(st, "met"))
    emblem(c, st, 22, 11)
    if st in ("cat", "gothic", "royal", "elven", "mage", "sea"):
        topper(c, st, 8, 36, 4 if st != "gothic" else 9) if st != "gothic" else None
    # столбики
    for x in (1, 38):
        puff(c, rr(x, 9, x + 4, 43, p=6), w)
        if st in ("cozy", "cat", "simple", "elven"):
            puff(c, ell(x + 2.5, 8, 3, 3), w)
        elif st in ("gothic",):
            puff(c, poly([(x, 10), (x + 2.5, 3), (x + 5, 10)]), w)
        elif st == "royal":
            puff(c, ell(x + 2.5, 8, 3, 3), S(st, "met"))
        elif st == "mage":
            puff(c, poly([(x + 0.5, 9), (x + 2.5, 3), (x + 4.5, 9)]), S(st, "acc"))
        elif st == "sea":
            puff(c, ell(x + 2.5, 8, 3, 2.6), "#f8b0a8")
    # матрас, подушки, отворот, одеяло
    puff(c, rr(5, 16, 38, 40, p=5), "#f8ecd8", shine=False)
    pil = "#fff6e8" if st not in ("gothic", "mage") else "#e8e0f4"
    for x in (7, 22):
        puff(c, rr(x, 16, x + 14, 24, p=3.2), pil)
    puff(c, rr(5, 24, 38, 28, p=5), "#f8ecd8" if st not in ("rough",) else "#e8dcc4", shine=False)
    q = rr(4, 27, 39, 40, p=6)
    if st in ("cozy", "cat", "elven", "royal"):
        for k in range(6):
            q |= ell(7.5 + k * 6, 40, 3.2, 2.6)
    puff(c, q, f if st != "simple" else "#a8c8e8")
    # узор одеяла
    pat = {"rough": None, "simple": "stripe", "cozy": "dots", "cat": "paws", "dwarf": "stripe", "elven": "leaf",
           "sea": "wave", "gothic": "emb", "mage": "stars", "royal": "emb"}.get(st)
    if pat == "dots":
        for x, y in ((9, 31), (21, 31), (33, 31), (15, 36), (27, 36)):
            for dx, dy in ((0, 0), (1, 0), (0, 1), (1, 1)):
                dot(c, x + dx, y + dy, "#fff0f4")
    elif pat == "stripe":
        for y in (31, 35):
            c.add(stroke([(6, y), (37, y)]), "#fff6e8" if st == "simple" else "#e8b060", mode="flat", outline=False)
    elif pat in ("paws", "emb", "leaf"):
        for x, y in ((12, 33), (22, 34), (32, 33)):
            emblem(c, st if pat != "paws" else "cat", x, y)
    elif pat == "wave":
        for y in (31, 36):
            for x in range(6, 38):
                if (x // 2) % 3 == 0:
                    dot(c, x, y - (x // 2) % 2, "#b8dcf8")
    elif pat == "stars":
        for x, y in ((10, 31), (20, 35), (30, 31), (34, 37)):
            c.spark(x, y, "#f8e070", size=0)
            dot(c, x, y, "#fff4b0")
    if st == "rough":
        for x in (13, 25):
            dot(c, x, 33, "#a89878"); dot(c, x + 1, 33, "#a89878")
    # изножье
    puff(c, rr(2, 41, 41, 45, p=5), w)
    if st == "dwarf":
        for x in range(5, 40, 5):
            dot(c, x, 43, S(st, "met"))
    if st == "gothic":
        topper(c, "gothic", 8, 36, 9)
    return c


# ------------------------------------------------------------------ СТОЛ 48x32
def table_deco(c, st, x, y):
    """Вещица на столе, (x, y) — низ."""
    if st == "rough":
        puff(c, rr(x - 2, y - 4, x + 1, y, p=3), "#b88a5a"); c.add(ell(x + 2.5, y - 2, 1.4, 1.4) - {(x + 2, y - 2)}, "#b88a5a")
    elif st == "simple":
        puff(c, rr(x - 4, y - 2, x + 3, y, p=4), "#5c94d8"); puff(c, rr(x - 3, y - 4, x + 2, y - 2, p=4), "#e86a5c")
    elif st == "cat":
        puff(c, ell(x, y - 2, 3, 2.6), "#f6a0b8"); c.add(stroke([(x - 2, y - 3), (x + 2, y - 1)]), "#d86a88", mode="flat", outline=False)
    elif st == "japan":
        puff(c, rr(x - 2, y - 4, x + 2, y, p=3), "#8ab070"); dot(c, x, y - 4, "#c8e0a8")
    elif st == "dwarf":
        puff(c, rr(x - 2, y - 5, x + 2, y, p=3), "#c0c4cc"); puff(c, rr(x - 2, y - 6, x + 2, y - 5, p=3), "#fff8e8", shine=False)
    elif st == "elven":
        puff(c, rr(x - 1, y - 4, x + 1, y, p=3), "#a8e0f0"); puff(c, ell(x, y - 6, 2, 2), "#f8b4d0"); dot(c, x, y - 6, "#ffe080")
    elif st == "sea":
        puff(c, ell(x, y - 2, 3, 2.4) & rect(0, 0, 99, y - 1), "#f8b0a8")
    elif st in ("gothic", "royal"):
        puff(c, rr(x - 2, y - 2, x + 2, y, p=4), S(st, "met"))
        c.add(rect(x - 1, y - 7, x, y - 3), "#fff4e0", mode="cel")
        c.spark(x, y - 9, "#ffd060", size=0); dot(c, x, y - 8, "#f8a040")
    elif st == "mage":
        puff(c, rr(x - 2, y - 2, x + 2, y, p=4), S(st, "met")); puff(c, ell(x, y - 5, 3, 3), "#9cecff"); c.spark(x - 1, y - 6, "#ffffff", size=0)


def table(st, W=48, H=32):
    if st == "cozy":
        return FA.cozy_table(W, H)
    c = Canvas(W, H)
    w, f, dk = S(st, "wood"), S(st, "fab"), S(st, "dark")
    low = st == "japan"
    oval = st in ("cat", "elven", "sea")
    top_y0, top_y1 = (12, 24) if low else (4, 19)
    # ножки
    legs = (4, 41) if not oval else (8, 37)
    for x in legs:
        if st == "gothic":
            puff(c, poly([(x, top_y1 - 1), (x + 3, top_y1 - 1), (x + 2.5, 29), (x + 3.5, 31), (x - 0.5, 31), (x + 0.5, 29)]), w)
        elif st == "royal":
            puff(c, rr(x, top_y1 - 1, x + 3, 28, p=5), w); puff(c, ell(x + 2, 29.5, 2.6, 1.8), S(st, "met"))
        elif st == "cat":
            puff(c, rr(x, top_y1 - 1, x + 3, 28, p=5), w); puff(c, ell(x + 2, 29.5, 2.6, 1.6), "#fff0f2", shine=False)
        else:
            puff(c, rr(x, top_y1 - 1, x + 3, 31 if not low else 30, p=5), w, shine=False)
    if oval:
        puff(c, ell(24, top_y0 + 9, 23, 8.5, p=2.4), dk, shine=False)
        puff(c, ell(24, top_y0 + 7.5, 23, 8, p=2.4), w)
    else:
        puff(c, rr(0, top_y0 + 3, 47, top_y1, p=5), dk, shine=False)
        puff(c, rr(0, top_y0, 47, top_y1 - 3, p=5), w)
    if st == "dwarf":
        puff(c, rr(1, top_y1 - 4, 46, top_y1 - 1, p=6), S(st, "acc"), shine=False)
        for x in range(4, 46, 6):
            dot(c, x, top_y1 - 3, S(st, "met"))
    if st in ("gothic", "mage", "royal"):     # дорожка-скатерть
        run = rr(17, top_y0, 30, top_y1 + 3, p=5)
        puff(c, run, f)
        emblem(c, st, 23.5, top_y1)
    if st == "sea":
        for x in (8, 38):
            emblem(c, "sea", x, top_y0 + 7)
    if st == "elven":
        for x, y in ((6, top_y0 + 8), (42, top_y0 + 8)):
            puff(c, ell(x, y, 2.4, 1.4, ang=30), f)
    table_deco(c, st, 24 if st not in ("gothic", "mage", "royal") else 23, top_y0 + 7)
    return c


# ------------------------------------------------------------------ СТУЛ 18x28
def chair(st, W=18, H=28):
    if st == "cat":
        return FA.cat_chair(W, H)
    c = Canvas(W, H)
    w, f = S(st, "wood"), S(st, "fab")
    if st == "japan":       # дзаису — стул без ножек на подушке
        puff(c, rr(3, 6, 14, 20, p=5), w)
        puff(c, rr(5, 8, 12, 17, p=4), S(st, "fab"), shine=False)
        emblem(c, "japan", 8.5, 12.5)
        puff(c, rr(1, 19, 16, 26, p=3), "#e8706a")
        dot(c, 8, 22, "#fff4e8"); dot(c, 9, 22, "#fff4e8")
        return c
    # спинка
    if st in ("cozy", "elven", "sea"):
        back = ell(9, 9, 7, 7, p=2.2) | rr(3, 8, 14, 16)
    elif st in ("gothic",):
        back = poly([(3, 16), (3, 5), (9, 0), (15, 5), (15, 16)])
    elif st == "royal":
        back = ell(9, 7, 7, 5.5) | rr(2, 6, 15, 16)
    elif st == "mage":
        back = poly([(3, 16), (3, 6), (9, 1), (15, 6), (15, 16)])
    else:
        back = rr(3, 3, 14, 16, p=6)
    puff(c, back, w)
    if st in ("rough", "simple", "dwarf"):
        for y in (6, 10):
            flat(c, rect(5, y, 12, y + 1), S(st, "dark"))
    else:
        inner = {"cozy": ell(9, 10, 4.5, 4.5) | rr(5, 9, 12, 14), "gothic": poly([(5, 14), (5, 6), (9, 3), (13, 6), (13, 14)]),
                 "royal": rr(5, 5, 12, 14, p=3), "mage": poly([(5, 14), (5, 7), (9, 4), (13, 7), (13, 14)]),
                 "elven": ell(9, 10, 4.5, 4.5), "sea": ell(9, 10, 4.5, 4.5)}[st]
        puff(c, inner, f, shine=False)
        emblem(c, st, 9, 9)
    if st == "royal":
        topper(c, "royal", 4, 13, 1.5)
    elif st == "elven":
        topper(c, "elven", 4, 13, 2.5)
    elif st == "sea":
        topper(c, "sea", 4, 13, 3)
    elif st == "dwarf":
        dot(c, 4, 4, S(st, "met")); dot(c, 13, 4, S(st, "met"))
    # сиденье
    puff(c, rr(1, 15, 16, 19, p=4), w)
    if st not in ("rough", "dwarf"):
        puff(c, rr(2, 13, 15, 17, p=3), f)
    # ножки
    for x in (2, 13):
        if st == "royal":
            puff(c, rr(x, 19, x + 2, 25, p=6), w, shine=False); puff(c, ell(x + 1.5, 26, 2, 1.4), S(st, "met"), shine=False)
        else:
            puff(c, rr(x, 19, x + 2, 26, p=6), w, shine=False)
    return c


# ------------------------------------------------------------------ ШКАФ 34x46
def wardrobe(st, W=34, H=46):
    if st == "royal":
        return FA.royal_wardrobe(W, H)
    c = Canvas(W, H)
    w, f, dk, m = S(st, "wood"), S(st, "fab"), S(st, "dark"), S(st, "met")
    top = 8
    if st in ("elven", "sea", "cozy", "cat"):
        body = ell(17, top + 6, 15, 7, p=2.2) & rect(0, 0, 33, top + 6) | rr(2, top + 4, 31, 41, p=4.5)
    elif st == "gothic":
        body = poly([(2, 41), (2, 12), (17, 4), (31, 12), (31, 41)])
    else:
        body = rr(2, top, 31, 41, p=4.5)
    puff(c, body, w)
    if st not in ("gothic",):
        topper(c, st, 4, 29, top + (0 if st not in ("elven", "sea", "cozy", "cat") else -0.5))
    else:
        topper(c, "gothic", 6, 27, 9)
    # двери
    for x0 in (5, 17):
        if st == "japan":
            puff(c, rr(x0, 12, x0 + 11, 38, p=6), "#fbf4e0", shine=False)
            for y in (18, 25, 32):
                c.add(stroke([(x0 + 1, y), (x0 + 10, y)]), dk, mode="flat", outline=False)
            c.add(stroke([(x0 + 5, 13), (x0 + 5, 37)]), dk, mode="flat", outline=False)
            continue
        if st == "gothic":
            d = poly([(x0, 38), (x0, 16), (x0 + 5.5, 11), (x0 + 11, 16), (x0 + 11, 38)])
        elif st in ("elven", "sea", "cozy", "cat"):
            d = ell(x0 + 5.5, 17, 5.5, 5) & rect(0, 0, 99, 17) | rr(x0, 15, x0 + 11, 38, p=4)
        else:
            d = rr(x0, 12, x0 + 11, 38, p=9)
        puff(c, d, dk if st not in ("mage", "gothic") else w, shine=False, bias=0)
        pan = rr(x0 + 2, 16, x0 + 9, 34, p=4 if st in ("cozy", "cat", "elven", "sea", "mage") else 9) if st not in ("gothic",) else poly([(x0 + 2, 35), (x0 + 2, 18), (x0 + 5.5, 14), (x0 + 9, 18), (x0 + 9, 35)])
        puff(c, pan, f if st in ("cozy", "cat", "gothic", "mage", "elven", "sea") else w, shine=True)
        emblem(c, st, x0 + 5.5, 24)
        if st == "dwarf":
            for yy in (15, 36):
                puff(c, rr(x0, yy - 1, x0 + 11, yy + 1, p=6), S(st, "acc"), shine=False)
    for x in (14, 19):
        knob(c, st, x, 27)
    if st == "dwarf":
        for y in (12, 39):
            for x in (4, 29):
                dot(c, x, y, m)
    # ножки
    for x in (3, 27):
        if st in ("cat",):
            puff(c, ell(x + 2, 43, 2.6, 1.8), "#fff0f2", shine=False)
        else:
            puff(c, rr(x, 41, x + 3, 45, p=5), dk if st != "mage" else m, shine=False)
    return c


# ------------------------------------------------------------------ КНИЖНЫЙ ШКАФ 40x52
def bookcase(st, W=40, H=52):
    if st == "elven":
        return FA.elven_bookcase(W, H)
    c = Canvas(W, H)
    w, f, dk, m = S(st, "wood"), S(st, "fab"), S(st, "dark"), S(st, "met")
    if st in ("sea", "cozy", "cat"):
        frame = ell(20, 14, 18, 10, p=2.2) & rect(0, 0, 39, 14) | rr(2, 10, 37, 48, p=5)
        back = ell(20, 15, 14, 7) & rect(0, 0, 39, 15) | rect(6, 15, 33, 45)
    elif st == "gothic":
        frame = poly([(2, 48), (2, 14), (20, 3), (37, 14), (37, 48)])
        back = poly([(6, 45), (6, 16), (20, 8), (33, 16), (33, 45)])
    else:
        frame = rr(2, 8, 37, 48, p=5)
        back = rect(6, 12, 33, 45)
    puff(c, frame, w)
    flat(c, back, dk if st != "japan" else "#e8dcc0", bias=1)
    rows = (22, 33, 44) if st not in ("rough", "dwarf", "simple", "mage", "royal", "japan") else (19, 28, 37, 45)
    for i, y in enumerate(rows):
        if st == "japan" and i % 2 == 1:   # ниша с вазой
            puff(c, rr(16, y - 6, 22, y - 1, p=3), "#a8c8e0"); dot(c, 19, y - 7, "#88b070")
            shelf_books(c, 7, 13, y - 1, 6, seed=y)
            shelf_books(c, 26, 32, y - 1, 6, seed=y + 1)
        elif st == "mage" and i == 1:
            shelf_books(c, 7, 20, y - 1, 6, seed=y)
            puff(c, ell(27, y - 3.5, 3, 3), "#9cecff"); c.spark(26, y - 5, "#ffffff", size=0)
        elif st == "cat" and i == 1:
            shelf_books(c, 7, 22, y - 1, 7, seed=y)
            puff(c, ell(28.5, y - 3, 3.2, 2.6), "#f6a0b8")
        else:
            shelf_books(c, 7, 32, y - 1, 7 if len(rows) == 3 else 6, seed=y * 3 + len(st))
        puff(c, rr(4, y, 35, y + 1, p=8), w, shine=False)
    if st == "dwarf":
        for y in (10, 46):
            for x in range(4, 37, 5):
                dot(c, x, y, m)
    if st == "gothic":
        topper(c, "gothic", 8, 32, 6)
    elif st in ("rough", "simple"):
        pass
    elif st in ("sea", "cozy", "cat"):
        topper(c, st, 8, 32, 5)
    else:
        topper(c, st, 6, 33, 8)
    for x in (3, 33):
        puff(c, rr(x, 48, x + 3, 51, p=5), dk, shine=False)
    return c


# ------------------------------------------------------------------ ЛАМПА 14x34
def lamp(st, W=14, H=34):
    if st == "mage":
        return FA.mage_lamp(W, H)
    c = Canvas(W, H)
    w, f, m = S(st, "wood"), S(st, "fab"), S(st, "met")
    glow = "#fff4c0"
    if st == "japan":   # бумажный фонарь-андон
        puff(c, rr(4, 29, 9, 33, p=4), w)
        c.add(rect(6, 20, 7, 30), w, mode="cel")
        puff(c, rr(2, 8, 11, 22, p=3), "#fff2d0")
        for y in (12, 16):
            c.add(stroke([(3, y), (10, y)]), "#d8c098", mode="flat", outline=False)
        puff(c, rr(2, 6, 11, 8, p=6), w); puff(c, rr(2, 22, 11, 23, p=6), w)
        c.spark(6, 14, "#ffffff", size=0)
        return c
    if st in ("gothic", "royal", "rough"):   # подсвечник
        puff(c, ell(7, 32, 5.5, 2), m if st != "rough" else w)
        c.add(rect(6, 12, 7, 31), m if st != "rough" else w, mode="cel")
        if st != "rough":
            c.add(tube([(2, 12), (2, 15), (7, 17), (12, 15), (12, 12)], 0.7), m)
            xs = (2, 7, 12)
        else:
            xs = (7,)
        for x in xs:
            puff(c, rr(x - 1, 9 if x == 7 else 10, x + 1, 13, p=6), "#fff4e0", shine=False)
            puff(c, ell(x, 6.5 if x == 7 else 7.5, 1.2, 1.8), "#ffc850", shine=False)
            dot(c, x, 7 if x == 7 else 8, "#fff8d0")
        return c
    if st == "sea":    # фонарь на верёвке-столбе
        puff(c, ell(7, 32, 5, 2), w)
        c.add(rect(6, 6, 7, 31), w, mode="cel")
        c.add(stroke([(7, 5), (10, 4), (11, 7)]), m, mode="flat")
        puff(c, rr(8, 8, 13, 16, p=3), "#5a7488", shine=False)
        puff(c, rr(9, 9, 12, 15, p=3), glow)
        dot(c, 10, 11, "#ffffff")
        return c
    if st == "dwarf":
        puff(c, rr(3, 29, 10, 33, p=4), S(st, "acc"))
        c.add(rect(6, 12, 7, 29), m, mode="cel")
        puff(c, rr(3, 4, 10, 13, p=3), m)
        puff(c, rr(4, 6, 9, 11, p=3), glow)
        for x in (4, 9):
            dot(c, x, 4, "#f0c080")
        return c
    if st == "elven":  # цветок-бутон
        puff(c, ell(7, 32, 5, 2), w)
        c.add(tube([(7, 31), (6, 22), (7, 13)], 0.8), "#78b860")
        puff(c, ell(4, 23, 2.4, 1.4, ang=-30), f)
        puff(c, ell(9.5, 19, 2.4, 1.4, ang=30), f)
        puff(c, poly([(2, 8), (7, 2), (12, 8), (10, 13), (4, 13)]), "#f8c0d8")
        puff(c, ell(7, 9, 2.2, 2.6), glow)
        c.spark(7, 9, "#ffffff", size=0)
        return c
    # абажур (простой, уютный, кошачий)
    puff(c, ell(7, 32, 5.5, 2), w)
    c.add(rect(6, 13, 7, 31), w, mode="cel")
    shade = poly([(3.5, 4), (10.5, 4), (13, 14), (1, 14)])
    if st == "cat":
        shade |= poly([(3, 6), (3.5, 0.5), (6.5, 4)]) | poly([(11, 6), (10.5, 0.5), (7.5, 4)])
    col = {"simple": "#f8f0e0", "cozy": "#f8a8bc", "cat": "#f8c4d4"}.get(st, f)
    puff(c, shade, col)
    if st == "cozy":
        for x in (4, 7, 10):
            dot(c, x, 12, "#fff0f4")
        puff(c, rr(1, 13, 12, 14, p=8), "#f07c9a", shine=False)
    if st == "cat":
        for x in (5, 9):
            dot(c, x, 9, "#7a4a3a")
        dot(c, 7, 10, "#f07a9a")
    puff(c, ell(7, 15.5, 2.5, 1.2), glow, shine=False)
    return c


# ------------------------------------------------------------------ КОВЁР 64x38
def rug(st, W=64, H=38):
    c = Canvas(W, H)
    f, a, m, w = S(st, "fab"), S(st, "acc"), S(st, "met"), S(st, "wood")
    if st == "straw":
        puff(c, ell(32, 19, 30, 17), "#e4c878")
        for r in (10, 18, 25):
            ring = ell(32, 19, r + 1, r * 0.56 + 1) - ell(32, 19, r, r * 0.56)
            c.add(ring, "#c8a858", mode="flat", outline=False)
        return c
    if st == "japan":   # татами
        puff(c, rr(2, 3, 61, 34, p=10), "#d8cc90")
        puff(c, rr(2, 3, 61, 6, p=10), "#4a6a50", shine=False); puff(c, rr(2, 31, 61, 34, p=10), "#4a6a50", shine=False)
        for y in range(9, 30, 3):
            c.add(stroke([(4, y), (59, y)]), "#c8b878", mode="flat", outline=False)
        puff(c, ell(32, 18.5, 6, 6), "#e8503e", shine=False)
        return c
    oval = st in ("cozy", "cat", "elven", "sea", "simple")
    main = ell(32, 19, 30.5, 17.5, p=2.4) if oval else rr(2, 3, 61, 34, p=8)
    border = {"rough": "#8a7a64", "simple": "#9cc0e0", "cozy": "#f8c4d4", "cat": "#fff0f4", "dwarf": m,
              "elven": "#f4ecc8", "sea": "#f6e4b8", "gothic": "#2c2034", "mage": m, "royal": m}[st]
    puff(c, main, border)
    inner = ell(32, 19, 26, 14, p=2.4) if oval else rr(6, 6, 57, 31, p=8)
    puff(c, inner, f if st != "rough" else "#b8a888", shine=st != "gothic")
    if not oval:   # бахрома
        for y in range(5, 33, 2):
            dot(c, 0, y, border); dot(c, 63, y, border)
    # центральный рисунок
    if st == "rough":
        for y in (14, 19, 24):
            c.add(stroke([(10, y), (53, y)]), "#9a8a6c", mode="flat", outline=False)
    elif st == "simple":
        puff(c, ell(32, 19, 14, 7), "#f6efe2", shine=False)
    elif st == "cozy":
        for x, y in ((18, 15), (32, 12), (46, 15), (24, 24), (40, 24)):
            emblem(c, "cozy", x, y)
    elif st == "cat":
        puff(c, ell(32, 21, 6, 4.5), "#fff0f4", shine=False)
        for dx in (-5, -2, 2, 5):
            puff(c, ell(32 + dx, 14.5 + abs(dx) * 0.3, 1.8, 1.6), "#fff0f4", shine=False)
    elif st == "dwarf":
        for k, cx in enumerate((18, 32, 46)):
            puff(c, poly([(cx, 12), (cx + 6, 18.5), (cx, 25), (cx - 6, 18.5)]), S(st, "acc"), shine=False)
            dot(c, cx, 18, m)
    elif st == "elven":
        for x, y, ang in ((20, 15, 30), (28, 23, -30), (36, 15, 30), (44, 23, -30)):
            puff(c, ell(x, y, 4, 2.2, ang=ang), "#b8e098", shine=False)
        puff(c, ell(32, 19, 2, 2), a, shine=False)
    elif st == "sea":
        for y in (14, 19, 24):
            for x in range(10, 54):
                if x % 6 in (0, 1, 2):
                    dot(c, x, y - (1 if x % 6 == 1 else 0), "#a8d4f8")
        puff(c, ell(32, 19, 3, 2.4), a, shine=False)
    elif st == "gothic":
        puff(c, poly([(32, 9), (44, 19), (32, 29), (20, 19)]), a, shine=False)
        puff(c, poly([(32, 14), (37, 19), (32, 24), (27, 19)]), "#2c2034", shine=False)
    elif st == "mage":
        puff(c, ell(32, 19, 10, 9), "#4a3c98", shine=False)
        for k in range(8):
            import math
            x = 32 + 13 * math.cos(k * math.pi / 4); y = 19 + 9 * math.sin(k * math.pi / 4)
            c.spark(int(x), int(y), "#f8e070", size=0)
        c.spark(32, 19, "#9cecff", size=2)
    elif st == "royal":
        puff(c, ell(32, 19, 9, 7), m, shine=False)
        puff(c, ell(32, 19, 6.5, 4.5), "#fff4c8", shine=False)
        topper(c, "royal", 27, 37, 20)
    return c


# ------------------------------------------------------------------ КОМОД 36x30
def dresser(st, W=36, H=30):
    c = Canvas(W, H)
    w, f, dk, m = S(st, "wood"), S(st, "fab"), S(st, "dark"), S(st, "met")
    body = rr(1, 7, 34, 26, p=4.5) if st != "gothic" else poly([(1, 26), (1, 9), (6, 6), (30, 6), (35, 9), (35, 26)])
    puff(c, body, w)
    puff(c, rr(0, 5, 35, 9, p=6), dk if st not in ("mage",) else w)
    if st == "dwarf":
        puff(c, rr(0, 5, 35, 9, p=6), S(st, "acc"))
    for i, y in enumerate((11, 16, 21)):
        if st == "japan":
            for x0 in (3, 18):
                puff(c, rr(x0, y, x0 + 14, y + 3, p=4), dk, shine=False)
                dot(c, x0 + 7, y + 1, m); dot(c, x0 + 7, y + 2, m)
            continue
        dr = rr(3, y, 32, y + 3, p=4)
        puff(c, dr, f if st in ("cozy", "cat", "mage", "royal", "elven", "sea") and i == 1 else dk, shine=False)
        if st in ("cozy", "cat", "gothic", "elven", "sea", "royal", "mage", "dwarf") and i == 1:
            emblem(c, st, 17.5, y + 1.5)
            knob(c, st, 7, y + 1); knob(c, st, 27, y + 1)
        else:
            knob(c, st, 17, y + 1)
    for x in (2, 30):
        if st == "cat":
            puff(c, ell(x + 2, 27.5, 2.4, 1.6), "#fff0f2", shine=False)
        else:
            puff(c, rr(x, 26, x + 3, 29, p=5), dk, shine=False)
    # на комоде
    on = {"rough": "jug", "simple": "frame", "cozy": "bow", "cat": "yarn", "japan": "vase", "dwarf": "mug", "elven": "flower",
          "sea": "bottle", "gothic": "candle", "mage": "orb", "royal": "box"}.get(st, "frame")
    x = 26
    if on == "jug":
        puff(c, rr(x - 2, 0, x + 2, 5, p=3), "#b88a5a")
    elif on == "frame":
        puff(c, rr(x - 3, 0, x + 2, 5, p=4), "#cc9460"); puff(c, rr(x - 2, 1, x + 1, 4, p=4), "#a8d8f0", shine=False)
    elif on == "bow":
        emblem(c, "cozy", x, 2.5)
    elif on == "yarn":
        puff(c, ell(x, 3, 2.8, 2.4), "#f6a0b8")
    elif on == "vase":
        puff(c, rr(x - 1, 0, x + 1, 5, p=3), "#a8c8e0")
    elif on == "mug":
        puff(c, rr(x - 2, 1, x + 1, 5, p=3), "#c0c4cc"); puff(c, rr(x - 2, 0, x + 1, 1, p=3), "#fff8e8", shine=False)
    elif on == "flower":
        puff(c, rr(x - 1, 2, x + 1, 5, p=3), "#a8e0f0"); puff(c, ell(x, 1, 1.8, 1.4), "#f8b4d0", shine=False)
    elif on == "bottle":
        puff(c, rr(x - 1, 0, x + 1, 5, p=3), "#88d0b8")
    elif on == "candle":
        c.add(rect(x, 0, x, 4), "#fff4e0", mode="cel"); dot(c, x, 0, "#ffc850")
    elif on == "orb":
        puff(c, ell(x, 2.5, 2.6, 2.6), "#9cecff"); dot(c, x - 1, 1, "#ffffff")
    elif on == "box":
        puff(c, rr(x - 3, 1, x + 2, 5, p=4), m); dot(c, x, 3, "#f0506a")
    return c


# ------------------------------------------------------------------ РАСТЕНИЕ 18x26
def plant(st, W=18, H=26):
    c = Canvas(W, H)
    pot = {"rough": "#b8785a", "simple": "#f6f0e6", "cozy": "#f8a8bc", "cat": "#fff0f4", "japan": "#5a6a7a", "dwarf": "#aeb0bc",
           "elven": "#eedfb4", "sea": "#7cc0d8", "gothic": "#5a4060", "mage": "#6050a0", "royal": "#f4c848"}[st]
    g = "#78b860"
    if st == "japan":   # бонсай в плоской чаше
        c.add(tube([(9, 19), (7, 14), (10, 10), (8, 6)], 1.4, 0.8), "#8a5a40")
        for x, y, r in ((5, 8, 3.2), (11, 5, 3), (12, 11, 2.6)):
            puff(c, ell(x, y, r, r * 0.7), "#58a058")
        puff(c, rr(2, 19, 15, 23, p=4), pot)
        return c
    if st == "dwarf":   # кактус
        puff(c, rr(6, 4, 11, 17, p=3), "#68a860")
        puff(c, rr(2, 9, 5, 14, p=3), "#68a860"); puff(c, rr(12, 7, 15, 12, p=3), "#68a860")
        puff(c, ell(8.5, 4, 1.8, 1.4), "#f8a0b8", shine=False)
        for (x, y) in ((7, 8), (9, 11), (7, 14), (3, 11), (13, 9)):
            dot(c, x, y, "#d8f0c0")
    elif st == "gothic":   # тёмные розы
        c.add(stroke([(9, 17), (8, 10)]) | stroke([(9, 17), (12, 9)]) | stroke([(9, 17), (5, 11)]), "#4a6a48", mode="flat")
        for x, y in ((8, 8), (12.5, 7.5), (4.5, 9.5)):
            puff(c, ell(x, y, 2.4, 2.2), "#b02040")
            dot(c, int(x), int(y), "#701830")
        puff(c, ell(10, 13, 2, 1.2, ang=30), "#4a7048", shine=False)
    elif st == "mage":   # светящиеся грибочки
        for x, y, r, col in ((6, 9, 3.2, "#9cecff"), (12, 6, 3.6, "#c8a8ff"), (10, 12, 2.4, "#9cecff")):
            c.add(rect(int(x), int(y), int(x), 17), "#e8e0f4", mode="cel")
            puff(c, ell(x, y, r, r * 0.65) & rect(0, 0, 99, int(y)), col)
        c.spark(14, 2, "#ffffff", size=0); c.spark(3, 5, "#c8f4ff", size=0)
    elif st == "sea":   # водоросли-алоэ
        for pts in ([(9, 17), (6, 10), (4, 4)], [(9, 17), (9, 8), (10, 2)], [(9, 17), (12, 10), (15, 5)]):
            c.add(tube(pts, 1.6, 0.6), "#5cb0a0")
        puff(c, ell(9, 15, 2, 1.4), "#f8b0a8", shine=False)
    elif st == "cat":   # кошачья травка
        for k in range(7):
            x = 4 + k * 1.6
            c.add(tube([(x + 1, 18), (x + (k - 3) * 0.6, 8 + (k % 2) * 2)], 0.9, 0.4), "#88cc68")
    elif st == "elven":   # белые цветы-колокольчики на лозе
        c.add(tube([(9, 17), (7, 10), (10, 4)], 0.8), g)
        for x, y in ((6, 8), (11, 5), (12, 11), (5, 13)):
            puff(c, ell(x, y, 2, 1.8), "#fffaf0")
            dot(c, x, y + 1, "#f8e080")
        puff(c, ell(10, 9, 2.2, 1.2, ang=-30), g, shine=False)
    elif st == "royal":   # золотой цветок
        c.add(stroke([(9, 17), (9, 9)]), "#58a058", mode="flat")
        puff(c, ell(6, 13, 2.6, 1.4, ang=-30), "#68b060"); puff(c, ell(12, 12, 2.6, 1.4, ang=30), "#68b060")
        for dx, dy in ((-2.4, 0), (2.4, 0), (0, -2.4), (0, 2.4), (-1.7, -1.7), (1.7, -1.7), (-1.7, 1.7), (1.7, 1.7)):
            puff(c, ell(9 + dx, 6 + dy, 1.6, 1.6), "#f8d050", shine=False)
        puff(c, ell(9, 6, 1.6, 1.6), "#f08a3a", shine=False)
    elif st == "cozy":   # розовые цветы
        for (x, y) in ((5, 9), (9, 5), (13, 9), (9, 11)):
            puff(c, ell(x, y, 3, 2.6), "#5aa858")
        for (x, y) in ((5, 7), (10, 4), (13, 8), (8, 10)):
            puff(c, ell(x, y, 1.8, 1.8), "#f88aa8", shine=False)
            dot(c, x, y, "#ffe080")
    elif st == "simple":   # фикус-шарик
        c.add(rect(8, 10, 9, 17), "#8a5a40", mode="cel")
        puff(c, ell(9, 8, 6.5, 6), "#5aa858")
        for (x, y) in ((6, 6), (11, 9), (8, 11), (12, 5)):
            dot(c, x, y, "#88cc78")
    else:   # rough — папоротник
        for pts in ([(9, 17), (4, 10), (1, 8)], [(9, 17), (8, 6), (7, 1)], [(9, 17), (13, 8), (16, 5)], [(9, 17), (5, 6), (4, 3)], [(9, 17), (12, 5), (13, 2)]):
            c.add(tube(pts, 1.8, 0.4, profile="lin"), "#58a050")
    # горшок
    if st != "japan":
        puff(c, poly([(3, 17), (15, 17), (13.5, 25), (4.5, 25)]), pot)
        puff(c, rr(2, 16, 15, 18, p=6), pot)
        if st == "cat":
            emblem(c, "cat", 9, 21)
        elif st in ("cozy", "royal", "gothic", "elven", "sea", "mage"):
            emblem(c, st, 9, 21)
    return c


# ------------------------------------------------------------------ ТУМБОЧКА 22x24
def cabinet(st, W=22, H=24):
    c = Canvas(W, H)
    w, f, dk, m = S(st, "wood"), S(st, "fab"), S(st, "dark"), S(st, "met")
    body = rr(1, 7, 20, 20, p=4.5) if st != "gothic" else poly([(1, 20), (1, 9), (5, 6), (16, 6), (20, 9), (20, 20)])
    puff(c, body, w)
    puff(c, rr(0, 6, 21, 9, p=6), dk if st != "dwarf" else S(st, "acc"))
    if st == "japan":
        puff(c, rr(3, 10, 18, 18, p=6), "#fbf4e0", shine=False)
        c.add(stroke([(10, 10), (10, 18)]) | stroke([(3, 14), (18, 14)]), dk, mode="flat", outline=False)
    else:
        puff(c, rr(3, 10, 18, 12, p=4), dk, shine=False)
        knob(c, st, 10, 10)
        puff(c, rr(3, 14, 18, 18, p=4), f if st in ("cozy", "cat", "mage", "royal", "gothic", "elven", "sea") else dk, shine=False)
        if st in ("rough", "simple", "dwarf", "straw"):
            knob(c, st, 10, 15)
        else:
            emblem(c, st, 10.5, 16)
    for x in (2, 17):
        if st == "cat":
            puff(c, ell(x + 1.5, 21.5, 2, 1.4), "#fff0f2", shine=False)
        else:
            puff(c, rr(x, 20, x + 2, 23, p=5), dk, shine=False)
    # на тумбочке
    x = 11
    if st in ("rough", "cozy", "gothic", "royal"):
        puff(c, rr(x - 2, 4, x + 1, 6, p=4), m if st != "rough" else "#b88a5a")
        c.add(rect(x - 1, 0, x, 3), "#fff4e0", mode="cel"); dot(c, x - 1, 0, "#ffc850")
    elif st == "simple":
        puff(c, rr(x - 4, 3, x + 3, 6, p=4), "#e86a5c")
    elif st == "cat":
        puff(c, ell(x, 4, 3, 2.4), "#f6a0b8")
    elif st == "japan":
        puff(c, rr(x - 2, 2, x + 1, 6, p=3), "#8ab070")
    elif st == "dwarf":
        puff(c, rr(x - 2, 1, x + 1, 6, p=3), "#c0c4cc"); puff(c, rr(x - 2, 0, x + 1, 1, p=3), "#fff8e8", shine=False)
    elif st == "elven":
        puff(c, rr(x - 1, 3, x + 1, 6, p=3), "#a8e0f0"); puff(c, ell(x, 1.5, 1.8, 1.4), "#f8b4d0", shine=False)
    elif st == "sea":
        puff(c, ell(x, 4.5, 2.6, 2) & rect(0, 0, 99, 5), "#f8b0a8")
    elif st == "mage":
        puff(c, ell(x, 3, 2.6, 2.6), "#9cecff"); dot(c, x - 1, 2, "#ffffff")
    return c


DRAW = {"bed": bed, "table": table, "chair": chair, "wardrobe": wardrobe, "bookcase": bookcase, "lamp": lamp,
        "rug": rug, "dresser": dresser, "plant": plant, "cabinet": cabinet}


def furn_table():
    src = open(os.path.join(GAME, "v23_data.gd"), encoding="utf-8").read()
    return json.loads(re.search(r"const FURN: Dictionary = (\{.*?\})\n", src).group(1))


def render_all(only=None):
    import furn_apple_misc as MISC
    os.makedirs(OUT, exist_ok=True)
    done = []
    for k, v in furn_table().items():
        tex = v["tex"]
        if only and not any(o in k for o in only):
            continue
        W, H = Image.open(os.path.join(OLD, tex + ".png")).size
        if v["cat"] in DRAW and v["style"] in ST:
            cnv = DRAW[v["cat"]](v["style"], W, H)
        elif k in MISC.MISC:
            cnv = MISC.MISC[k](W, H)
        else:
            print("нет рисовалки:", k)
            continue
        im = cnv.render()
        im.save(os.path.join(OUT, tex + ".png"))
        up(im, 8).save(os.path.join(OUT, tex + "_x8.png"))
        done.append((k, tex))
    return done


def sheets(done, cols=10, z=3):
    cw, ch = 80 * z, 60 * z
    rows = (len(done) + cols - 1) // cols
    new = Image.new("RGBA", (cols * cw, rows * ch), (0, 0, 0, 0))
    cmp_ = Image.new("RGBA", (cols * cw, rows * ch * 2), (240, 232, 214, 255))
    for i, (k, tex) in enumerate(done):
        b = Image.open(os.path.join(OUT, tex + ".png")).convert("RGBA")
        a = Image.open(os.path.join(OLD, tex + ".png")).convert("RGBA")
        x, y = (i % cols) * cw, (i // cols) * ch
        for im, dst, yy in ((b, new, y), (a, cmp_, 2 * y), (b, cmp_, 2 * y + ch)):
            u = up(im, z)
            if u.width > cw - 4:
                u = up(im, 2)
            dst.alpha_composite(u, (x + (cw - u.width) // 2, yy + ch - 6 - u.height))
    new.save(os.path.join(OUT, "_all_new_x3.png"))
    cmp_.save(os.path.join(OUT, "_all_compare.png"))


if __name__ == "__main__":
    only = [a for a in sys.argv[1:] if not a.startswith("--")] or None
    d = render_all(only)
    sheets(d)
    print("готово:", len(d))

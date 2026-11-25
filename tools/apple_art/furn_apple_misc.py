# -*- coding: utf-8 -*-
"""Деревенская мебель (dp_*) и особые предметы в стиле зелёного яблока / чиби (v34)."""
import math
from PIL import Image

from apple_engine import Canvas, ell, tube, stroke, poly, rect
from furn_apple import rr, puff, flat, dot, shelf_books
import furn_apple_all as A

A.ST["village"] = dict(wood="#cc9a64", fab="#ec8e9e", met="#b0b0b8", acc="#f6e8c8", dark="#a8784a")
WOOD, DARK, PINK, CREAM = "#cc9a64", "#a8784a", "#ec8e9e", "#f6e8c8"
GLASS = "#b8e4f4"


class Ready:
    """Готовая картинка вместо Canvas (render() отдаёт её)."""

    def __init__(self, im):
        self.im = im

    def render(self):
        return self.im


def fit(cnv, W, H):
    """Поставить нарисованное по низу и центру на холст W×H (лишние пустые поля срезаются)."""
    im = cnv.render()
    bb = im.getbbox()
    im = im.crop(bb) if bb else im
    out = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    out.alpha_composite(im.crop((max(0, (im.width - W) // 2), max(0, im.height - H), max(0, (im.width - W) // 2) + min(W, im.width), im.height)),
                        (max(0, (W - im.width) // 2), max(0, H - im.height)))
    return Ready(out)


def V(fn, w0, h0):
    return lambda W, H: fit(fn("village", w0, h0), W, H)


# ------------------------------------------------------------------ деревенское
def cupboard(W, H):
    c = Canvas(W, H)
    puff(c, rr(1, 3, W - 2, H - 4, p=4.5), WOOD)
    puff(c, rr(0, 1, W - 1, 4, p=6), DARK)
    puff(c, rr(3, 6, W - 4, 20, p=4), "#9ad0e8", shine=False)     # стекло
    for y in (12, 19):
        puff(c, rr(3, y, W - 4, y + 1, p=8), WOOD, shine=False)
    for k, x in enumerate(range(5, W - 5, 5)):   # тарелки
        puff(c, ell(x + 1.5, 9.5, 2.2, 2.2), "#fffaf0"); dot(c, x + 1, 9, "#7aa8e0")
        puff(c, rr(x, 14, x + 3, 18, p=3), "#f4b0a0" if k % 2 else "#a8c8f0")
    c.add(stroke([(W // 2, 6), (W // 2, 20)]), DARK, mode="flat", outline=False)
    for x0 in (3, W // 2 + 1):
        puff(c, rr(x0, 23, x0 + W // 2 - 5, H - 7, p=4), DARK, shine=False)
        puff(c, rr(x0 + 2, 26, x0 + W // 2 - 7, H - 10, p=4), WOOD)
    puff(c, ell(W / 2 - 1.5, 30, 1.2, 1.2), "#c8c8d0", shine=False); puff(c, ell(W / 2 + 1.5, 30, 1.2, 1.2), "#c8c8d0", shine=False)
    for x in (2, W - 5):
        puff(c, rr(x, H - 4, x + 2, H - 1, p=5), DARK, shine=False)
    return c


def pot(col, flower):
    def f(W, H):
        c = Canvas(W, H)
        cx = W / 2
        for (x, y) in ((cx - 3.5, 9), (cx, 5.5), (cx + 3.5, 9), (cx, 11)):
            puff(c, ell(x, y, 3.2, 2.8), "#5aa858")
        for (x, y) in ((cx - 3, 7), (cx + 1, 4), (cx + 3.5, 8.5), (cx - 0.5, 10)):
            puff(c, ell(x, y, 2, 2), flower, shine=False)
            dot(c, int(x), int(y), "#ffe080")
        puff(c, poly([(cx - 5.5, 14), (cx + 5.5, 14), (cx + 4, H - 1), (cx - 4, H - 1)]), col)
        puff(c, rr(int(cx - 6.5), 13, int(cx + 5.5), 15, p=6), col)
        return c
    return f


def flowerbox(W, H):
    c = Canvas(W, H)
    for k, x in enumerate(range(4, W - 3, 5)):
        puff(c, ell(x, 10, 3.4, 3), "#5aa858")
    for k, x in enumerate(range(4, W - 3, 5)):
        puff(c, ell(x + 0.5, 7.5 + (k % 2) * 2, 1.9, 1.9), ["#f88aa8", "#fff4a0", "#c8a0f0", "#ffffff"][k % 4], shine=False)
        dot(c, x, 8 + (k % 2) * 2, "#ffe080")
    puff(c, rr(0, 12, W - 1, H - 1, p=5), WOOD)
    c.add(stroke([(2, 17), (W - 3, 17)]), DARK, mode="flat", outline=False)
    return c


def clock(W, H):
    c = Canvas(W, H)
    puff(c, ell(W / 2, H / 2, W / 2 - 0.5, H / 2 - 0.5), "#9a6a48")
    puff(c, ell(W / 2, H / 2, W / 2 - 2.5, H / 2 - 2.5), "#fffaf0")
    cx, cy = int(W / 2), int(H / 2)
    for a in range(12):
        x = cx + round((W / 2 - 4) * math.cos(a * math.pi / 6)); y = cy + round((H / 2 - 4) * math.sin(a * math.pi / 6))
        if a % 3 == 0:
            dot(c, x, y, "#a8846a")
    for y in range(cy - 4, cy + 1):
        dot(c, cx, y, "#6a4a44")
    for x in range(cx, cx + 4):
        dot(c, x, cy, "#6a4a44")
    dot(c, cx, cy, "#e86a5c")
    return c


def shelf(W, H):
    c = Canvas(W, H)
    puff(c, rr(1, 2, W - 2, H - 3, p=5), WOOD)
    c.add(rect(4, 5, W - 5, H - 7), DARK, mode="cel", tone_bias=1)
    cols = ["#f4b0a0", "#a8d8a0", "#f8d878", "#a8c8f0", "#e8b0e0"]
    ys = list(range(14, H - 6, 10))
    for i, y in enumerate(ys):
        x = 5
        k = i
        while x < W - 8:
            col = cols[k % len(cols)]
            puff(c, rr(x, y - 6, x + 4, y - 1, p=3), col)
            puff(c, rr(x, y - 7, x + 4, y - 6, p=6), "#d8b890", shine=False)
            x += 6; k += 2
        puff(c, rr(3, y, W - 4, y + 1, p=8), WOOD, shine=False)
    for x in (2, W - 5):
        puff(c, rr(x, H - 3, x + 2, H - 1, p=5), DARK, shine=False)
    return c


def long_table(W, H):
    c = Canvas(W, H)
    for x in (4, W - 8):
        puff(c, rr(x, 15, x + 3, H - 1, p=5), WOOD, shine=False)
    puff(c, rr(0, 7, W - 1, 19, p=5), DARK, shine=False)
    puff(c, rr(0, 4, W - 1, 16, p=5), WOOD)
    puff(c, rr(10, 6, W - 11, 14, p=6), CREAM, shine=False)   # дорожка
    for x in range(14, W - 12, 6):
        dot(c, x, 10, PINK)
    # тарелка с пирогом, кувшин, хлеб
    puff(c, ell(24, 10, 5, 2.4), "#fffaf0"); puff(c, ell(24, 9, 3.6, 2), "#e8a860")
    puff(c, rr(36, 4, 40, 10, p=3), "#a8c8f0"); dot(c, 37, 5, "#ffffff")
    puff(c, ell(48, 9.5, 4, 2.2), "#d89858")
    return c


def round_table(W, H):
    c = Canvas(W, H)
    cx = W / 2
    puff(c, rr(int(cx) - 2, 18, int(cx) + 1, H - 4, p=5), WOOD, shine=False)
    puff(c, ell(cx, H - 3, 9, 2.4), WOOD, shine=False)
    puff(c, ell(cx, 14, W / 2 - 0.5, 9, p=2.3), DARK, shine=False)
    puff(c, ell(cx, 12.5, W / 2 - 0.5, 8.5, p=2.3), WOOD)
    puff(c, ell(cx, 12.5, 11, 5.5), CREAM, shine=False)
    for k in range(-4, 5):
        puff(c, ell(cx + k * 2.6, 12.5 + 5 * (1 - (k / 4.5) ** 2) ** 0.5, 1.3, 1.3), CREAM, shine=False)
    puff(c, rr(int(cx) - 1, 6, int(cx) + 1, 11, p=3), "#a8c8f0")
    puff(c, ell(cx, 4.5, 2.2, 2), PINK, shine=False); dot(c, int(cx), 4, "#ffe080")
    return c


def cushions(W, H):
    c = Canvas(W, H)
    puff(c, rr(1, 6, 16, 20, p=3), "#f4a0b8")
    puff(c, rr(11, 1, 26, 15, p=3), "#a8c8f0")
    for (x, y) in ((8, 13), (18, 8)):
        dot(c, x, y, "#ffffff"); dot(c, x + 1, y, "#ffffff")
    return c


def basket(fill):
    def f(W, H):
        c = Canvas(W, H)
        top = H - 13
        if fill == "oranges":
            for (x, y) in ((6, top), (11, top - 2), (16, top - 1), (21, top), (9, top + 1), (19, top + 1)):
                puff(c, ell(x, y, 3, 3), "#f89a3a")
                dot(c, int(x), int(y - 3), "#68a858")
        elif fill == "greens":
            for k in range(9):
                x = 3 + k * (W - 6) / 8
                c.add(tube([(x, top + 2), (x + (k - 4) * 0.4, top - 10 + (k % 2) * 3)], 1.4, 0.4), "#68b860" if k % 2 else "#88cc70")
        else:   # морковки
            for k, x in enumerate(range(5, W - 4, 5)):
                c.add(tube([(x + 1, top - 6), (x - 1, top - 11), (x + 2, top - 12)], 0.8), "#68b860")
                puff(c, poly([(x - 2, top - 6), (x + 3, top - 6), (x + 0.5, top + 3)]), "#f88a3a")
        body = poly([(1, top), (W - 2, top), (W - 5, H - 1), (4, H - 1)])
        puff(c, body, "#d8a868")
        for y in range(top + 3, H - 1, 3):
            for x in range(3, W - 3):
                if (x + y // 3) % 4 == 0 and (x, y) in body:
                    dot(c, x, y, "#b8844a")
        puff(c, rr(0, top - 1, W - 1, top + 2, p=6), "#e8bc80")
        return c
    return f


def horse(W, H):
    c = Canvas(W, H)
    rock = tube([(2, H - 5), (8, H - 1), (20, H - 1), (27, H - 5)], 1.2)
    c.add(rock, DARK)
    for x in (8, 19):
        puff(c, rr(x, 13, x + 2, H - 3, p=6), WOOD, shine=False)
    puff(c, ell(14, 12, 9, 4.5), WOOD)
    puff(c, ell(23, 6, 4, 3.4), WOOD)                       # голова
    puff(c, poly([(19, 4), (20, 0), (22, 3)]), WOOD)          # ушко
    c.add(tube([(20, 3), (17, 8), (16, 10)], 1.6), "#8a5a3c")  # грива
    c.add(tube([(5, 10), (2, 12), (1, 16)], 1.2), "#8a5a3c")  # хвост
    puff(c, rr(10, 8, 17, 11, p=4), "#e86a5c")                # седло
    dot(c, 24, 5, "#4a3038"); dot(c, 24, 4, "#ffffff")
    dot(c, 26, 8, "#f4a0a8")
    return c


def chest(W, H):
    c = Canvas(W, H)
    puff(c, rr(1, 8, W - 2, H - 1, p=4), WOOD)
    puff(c, ell(W / 2, 8, W / 2 - 1, 6) & rect(0, 0, 99, 9) | rr(1, 5, W - 2, 9, p=6), "#b8844e")
    for x in (3, W - 5):
        puff(c, rr(x, 2, x + 1, H - 2, p=8), "#8a8a98", shine=False)
    puff(c, rr(int(W / 2) - 2, 7, int(W / 2) + 1, 12, p=3), "#f4c848")
    dot(c, int(W / 2) - 1, 10, "#6a4a30")
    return c


def barrel(W, H):
    c = Canvas(W, H)
    puff(c, ell(W / 2, H / 2 + 1, W / 2 - 0.5, H / 2 - 1, p=3), WOOD)
    for y in (5, H - 5):
        puff(c, rr(1, y - 1, W - 2, y, p=8), "#8a8a98", shine=False)
    puff(c, ell(W / 2, 2.5, W / 2 - 1.5, 2), "#b8844e", shine=False)
    for x in (6, 12):
        c.add(stroke([(x, 7), (x, H - 6)]), DARK, mode="flat", outline=False)
    return c


def braided_rug(W, H):
    c = Canvas(W, H)
    cols = ["#ec8e9e", "#f6e8c8", "#f4b878", "#a8c8e8", "#ec8e9e", "#f6e8c8"]
    for k, col in enumerate(cols):
        f = 1 - k * 0.16
        puff(c, ell(W / 2, H / 2, (W / 2 - 1) * f, (H / 2 - 1) * f, p=2.2), col, shine=k == 0)
    return c


def sink_table(W, H):
    c = Canvas(W, H)
    for x in (3, W - 6):
        puff(c, rr(x, 20, x + 2, H - 1, p=6), WOOD, shine=False)
    puff(c, rr(1, 24, W - 2, 26, p=6), WOOD, shine=False)
    puff(c, rr(0, 14, W - 1, 21, p=5), WOOD)
    puff(c, ell(13, 15, 9, 3.4), "#e8eef4")
    puff(c, ell(13, 15, 7, 2.2), "#9ad4f0", shine=False)
    c.spark(10, 14, "#ffffff", size=0)
    puff(c, rr(25, 6, 31, 15, p=3), "#a8c8f0")                   # кувшин
    c.add(ell(32, 10, 1.6, 2.2) - {(32, 10)}, "#a8c8f0")
    puff(c, rr(4, 0, 22, 11, p=4), "#c8a878")                    # зеркало
    puff(c, rr(6, 2, 20, 9, p=4), GLASS)
    c.spark(9, 4, "#ffffff", size=0)
    return c


def picture(kind):
    def f(W, H):
        c = Canvas(W, H)
        y0 = 4 if kind != "land" else 0
        if kind != "land":
            c.add(stroke([(W // 2, 0), (2, y0 + 1)]) | stroke([(W // 2, 0), (W - 3, y0 + 1)]), "#6a5a50", mode="flat", outline=False)
        puff(c, rr(0, y0, W - 1, H - 1, p=5), "#f0c860" if kind == "land" else "#c89a64")
        puff(c, rr(2, y0 + 2, W - 3, H - 3, p=6), "#b8e0f8", shine=False)
        if kind == "land":
            puff(c, poly([(3, 18), (12, 6), (20, 18)]), "#9aa8c8", shine=False)
            puff(c, poly([(14, 18), (24, 4), (33, 18)]), "#8a9ac0", shine=False)
            puff(c, rr(2, 17, W - 3, H - 3, p=6), "#78c068", shine=False)
            puff(c, ell(29, 5, 2, 2), "#fff4a0", shine=False)
        elif kind == "a":
            puff(c, ell(W / 2, H - 8, 4, 3.4), "#f89a3a")
            dot(c, W // 2, H - 12, "#68a858")
        else:
            c.add(stroke([(W // 2, H - 4), (W // 2, y0 + 8)]), "#68a858", mode="flat", outline=False)
            for (dx, dy, col) in ((-2.5, 0, "#f88aa8"), (2.5, 2, "#c8a0f0")):
                puff(c, ell(W / 2 + dx, y0 + 7 + dy, 2, 2), col, shine=False)
        return c
    return f


def window(W, H):
    c = Canvas(W, H)
    puff(c, rr(5, 3, W - 6, H - 5, p=6), "#f6f0e4")
    puff(c, rr(7, 5, W - 8, H - 8, p=6), "#a8dcf8", shine=False)
    puff(c, ell(15, 13, 4, 2), "#ffffff", shine=False); puff(c, ell(25, 9, 3, 1.6), "#ffffff", shine=False)
    puff(c, rr(7, H - 12, W - 8, H - 8, p=6), "#88c870", shine=False)
    c.add(stroke([(W // 2, 5), (W // 2, H - 8)]) | stroke([(7, (H - 4) // 2), (W - 8, (H - 4) // 2)]), "#f6f0e4", mode="flat", outline=False)
    for x0, x1 in ((0, 8), (W - 9, W - 1)):
        puff(c, poly([(x0, 1), (x1, 1), (x1 - 1, H - 6), (x0 + 1, H - 3)]), "#5a90d8")
    puff(c, rr(0, 0, W - 1, 3, p=8), "#c89a64")
    puff(c, rr(3, H - 5, W - 4, H - 2, p=6), "#f6f0e4")
    return c


# ------------------------------------------------------------------ особое
def stove(W, H):
    c = Canvas(W, H)
    c.add(rect(12, 0, 16, 10), "#7a7a88", mode="cel")
    puff(c, rr(1, 9, W - 2, H - 4, p=4), "#6a6a7a")
    puff(c, rr(0, 8, W - 1, 12, p=6), "#8a8a9a")
    puff(c, rr(7, 16, W - 8, H - 8, p=3), "#3a3040", shine=False)
    puff(c, ell(W / 2, H - 11, 5, 3.4), "#f8a040")
    puff(c, ell(W / 2, H - 11, 2.6, 2), "#fff080", shine=False)
    for x in (3, W - 6):
        puff(c, rr(x, H - 4, x + 2, H - 1, p=5), "#5a5a68", shine=False)
    puff(c, rr(18, 3, 26, 8, p=3), "#e8706a"); dot(c, 20, 4, "#ffffff")   # чайник
    return c


def cat_tree(W, H):
    c = Canvas(W, H)
    c.add(rect(10, 8, 13, H - 4), "#e8d0a8", mode="cel")
    for y in range(10, H - 4, 3):
        c.add(stroke([(10, y), (13, y - 1)]), "#c8a878", mode="flat", outline=False)
    puff(c, rr(1, H - 5, W - 2, H - 1, p=5), "#f6a8c0")
    puff(c, rr(2, 18, 15, 22, p=5), "#f6a8c0")
    puff(c, rr(9, 4, W - 2, 9, p=5), "#f6a8c0")
    puff(c, rr(3, H - 16, 15, H - 6, p=4), "#f6a8c0")                    # домик
    puff(c, ell(9, H - 10, 3, 3), "#c06888", shine=False)
    c.add(stroke([(18, 9), (18, 14)]), "#e8c8a0", mode="flat", outline=False)
    puff(c, ell(18, 15.5, 1.8, 1.8), "#f8d050")                          # мячик
    return c


def cat_basket(W, H):
    c = Canvas(W, H)
    puff(c, ell(W / 2, H / 2 + 1, W / 2 - 0.5, H / 2 - 1.5), "#d8a868")
    puff(c, ell(W / 2, H / 2, W / 2 - 3.5, H / 2 - 4), "#f6a8c0")
    puff(c, ell(W / 2 + 4, H / 2 - 1, 2.4, 1.8), "#ffffff", shine=False)
    return c


def aquarium(W, H):
    c = Canvas(W, H)
    puff(c, rr(1, 2, W - 2, 19, p=6), "#7ccce8")
    puff(c, rr(2, 15, W - 3, 18, p=6), "#f0dca8", shine=False)
    for x in (6, 24):
        c.add(tube([(x, 17), (x - 1, 11), (x + 1, 7)], 0.9), "#58b070")
    for (x, y, col) in ((13, 8, "#f89a3a"), (20, 12, "#f8d050")):
        puff(c, ell(x, y, 2.6, 1.6), col)
        puff(c, poly([(x + 2, y), (x + 4, y - 2), (x + 4, y + 2)]), col, shine=False)
        dot(c, x - 1, y - 1, "#4a3038")
    for (x, y) in ((9, 5), (10, 3), (17, 4)):
        dot(c, x, y, "#ffffff")
    puff(c, rr(0, 0, W - 1, 2, p=8), "#a8784a")
    puff(c, rr(0, 19, W - 1, H - 1, p=5), "#a8784a")
    puff(c, rr(4, 22, W - 5, H - 3, p=5), "#8a5a3a", shine=False)
    return c


def piano(W, H):
    c = Canvas(W, H)
    puff(c, rr(1, 1, W - 2, 18, p=5), "#5a3a4a")
    puff(c, rr(14, 3, 29, 9, p=4), "#fff6e0", shine=False)   # ноты
    for y in (5, 7):
        c.add(stroke([(16, y), (27, y)]), "#a8a0a8", mode="flat", outline=False)
    puff(c, rr(0, 17, W - 1, 24, p=5), "#4a3040")
    puff(c, rr(2, 18, W - 3, 22, p=6), "#fffaf0", shine=False)
    for x in range(4, W - 3, 3):
        if x % 7 != 0:
            c.add(rect(x, 18, x, 20), "#3a2838", mode="flat", outline=False)
    for x in (2, W - 5):
        puff(c, rr(x, 24, x + 2, H - 1, p=6), "#4a3040", shine=False)
    return c


def fireplace(W, H):
    c = Canvas(W, H)
    puff(c, rr(1, 6, W - 2, H - 1, p=5), "#d8806a")
    for y in range(9, H - 2, 4):
        for x in range(3 + (y // 4 % 2) * 3, W - 3, 6):
            dot(c, x, y, "#c06a58")
    puff(c, rr(0, 3, W - 1, 8, p=6), "#d8c0a0")
    puff(c, ell(W / 2, 22, 13, 12) & rect(0, 0, 99, 22) | rect(int(W / 2) - 13, 22, int(W / 2) + 12, H - 3), "#3a2830", shine=False)
    puff(c, poly([(W / 2 - 9, H - 4), (W / 2 - 4, 22), (W / 2, 16), (W / 2 + 4, 22), (W / 2 + 9, H - 4)]), "#f88a3a")
    puff(c, poly([(W / 2 - 5, H - 4), (W / 2, 24), (W / 2 + 5, H - 4)]), "#fff080", shine=False)
    for x in (W / 2 - 7, W / 2 + 7):
        puff(c, rr(int(x) - 4, H - 5, int(x) + 3, H - 3, p=6), "#8a5a3a", shine=False)
    for (x, col) in ((8, "#a8c8f0"), (39, "#f4b0a0")):
        puff(c, rr(x - 2, 0, x + 2, 4, p=3), col)
    return c


def armor_stand(W, H):
    c = Canvas(W, H)
    puff(c, rr(3, H - 4, W - 4, H - 1, p=5), WOOD)
    c.add(rect(10, 30, 11, H - 4), WOOD, mode="cel")
    for x in (6, 13):
        puff(c, rr(x, 26, x + 3, 36, p=4), "#c0c4d0")
    puff(c, rr(4, 12, W - 5, 28, p=3), "#c8ccd8")             # кираса
    puff(c, ell(4, 13, 3, 2.6), "#b0b4c4"); puff(c, ell(W - 5, 13, 3, 2.6), "#b0b4c4")
    puff(c, ell(W / 2, 7, 5, 5.5), "#c8ccd8")                  # шлем
    puff(c, rr(7, 6, 14, 7, p=8), "#4a4858", shine=False)
    puff(c, poly([(10, 2), (11, -2), (13, 0), (12, 3)]) | ell(11, 0.5, 1.6, 2), "#e8504e")   # перо
    emblem_x = W / 2
    puff(c, ell(emblem_x, 19, 2.2, 2.2), "#f4c848"); dot(c, int(emblem_x), 19, "#e8504e")
    return c


def globe(W, H):
    c = Canvas(W, H)
    puff(c, ell(W / 2, H - 2, 5, 1.8), "#c89a64")
    c.add(rect(7, 15, 8, H - 3), "#c89a64", mode="cel")
    c.add(tube([(2, 10), (3, 3), (8, 1), (13, 4), (14, 11)], 0.6), "#f4c848")
    puff(c, ell(W / 2, 8, 6, 6), "#68b0e8")
    for (x, y, r) in ((6, 6, 2.4), (10, 10, 2), (11, 5, 1.4)):
        puff(c, ell(x, y, r, r * 0.8), "#78c068", shine=False)
    return c


def potion_rack(W, H):
    c = Canvas(W, H)
    puff(c, rr(1, 2, W - 2, H - 3, p=5), WOOD)
    c.add(rect(4, 5, W - 5, H - 7), DARK, mode="cel", tone_bias=1)
    cols = ["#e8504e", "#58b0f0", "#78d068", "#c890f0", "#f8c848", "#f890b8"]
    for i, y in enumerate((15, 26)):
        for k, x in enumerate(range(6, W - 6, 5)):
            col = cols[(k + i * 2) % len(cols)]
            puff(c, ell(x + 1.5, y - 3, 2.2, 2.4), col)
            c.add(rect(x + 1, y - 8, x + 2, y - 6), "#e8f4f8", mode="cel")
            dot(c, x + 1, y - 9, "#a8784a"); dot(c, x + 2, y - 9, "#a8784a")
        puff(c, rr(3, y, W - 4, y + 1, p=8), WOOD, shine=False)
    for x in (2, W - 5):
        puff(c, rr(x, H - 3, x + 2, H - 1, p=5), DARK, shine=False)
    return c


def throne(W, H):
    c = Canvas(W, H)
    gold, red = "#f4c848", "#d83850"
    puff(c, ell(W / 2, 14, 13, 13, p=2.2) & rect(0, 0, 99, 16) | rr(4, 12, W - 5, 34, p=4), gold)
    puff(c, ell(W / 2, 15, 9.5, 10) & rect(0, 0, 99, 16) | rr(8, 14, W - 9, 32, p=4), red)
    A.topper(c, "royal", W / 2 - 4, W / 2 + 4, 3)
    for x in (1, W - 7):
        puff(c, rr(x, 24, x + 5, 38, p=4), gold)
        puff(c, ell(x + 3, 24, 3.4, 2.6), gold)
    puff(c, rr(5, 31, W - 6, 37, p=4), red)
    for x in (10, W / 2, W - 11):
        dot(c, int(x), 34, "#fff4c8")
    puff(c, rr(3, 37, W - 4, 41, p=5), gold)
    for x in (4, W - 8):
        puff(c, ell(x + 2, 43, 2.8, 2.4), gold)
    puff(c, ell(W / 2, 20, 2.2, 2.2), gold); dot(c, int(W / 2), 20, "#58b0f0")
    return c


emblem = A.emblem

MISC = {
    "dp_bed": V(A.bed, 44, 46), "dp_bookcase": V(A.bookcase, 40, 52), "dp_cupboard": cupboard,
    "dp_dresser": V(A.dresser, 36, 30), "dp_wardrobe": V(A.wardrobe, 34, 46),
    "dp_pot_red": pot("#d86a4a", "#f05a6a"), "dp_pot_pink": pot("#f8a8bc", "#f8f0ff"),
    "dp_flowerbox": flowerbox, "dp_clock": clock, "dp_shelf": shelf, "dp_nightstand": V(A.cabinet, 22, 24),
    "dp_table": long_table, "dp_table_round": round_table, "dp_cushions": cushions,
    "dp_basket_oranges": basket("oranges"), "dp_basket_greens": basket("greens"), "dp_basket_carrots": basket("carrots"),
    "dp_horse": horse, "dp_chest": chest, "dp_chest_small": chest, "dp_barrel": barrel, "dp_rug": braided_rug,
    "dp_sink_table": sink_table, "dp_pic_land": picture("land"), "dp_pic_a": picture("a"), "dp_pic_b": picture("b"),
    "dp_window_blue": window,
    "stove": stove, "cat_tree": cat_tree, "cat_basket": cat_basket, "aquarium": aquarium, "piano": piano,
    "fireplace": fireplace, "armor_stand": armor_stand, "globe": globe, "potion_rack": potion_rack, "throne": throne,
}

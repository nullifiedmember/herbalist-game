# -*- coding: utf-8 -*-
"""Травы в стиле яблока (32x48, как в игре).

Запуск:  python herbs.py            -> все травы
         python herbs.py mint poppy -> только эти
Выход:   C:/Claude/herbalist_game/art_apple/herbs/  (herb14_<id>.png, <id>_0..3.png)
         + лист сравнения herbs_compare_x4.png
Старые картинки игры НЕ трогаются.
"""
import math, os, sys, random
from PIL import Image, ImageDraw
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from apple_engine import Canvas, ell, tube, stroke, poly, rect, ramp, hx, up

GAME = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.abspath(os.path.join(GAME, "..", "art_apple", "herbs"))

# --- базовые цвета ---
LEAF = "#72b556"; LEAF_D = "#559a4f"; LEAF_L = "#9acb6a"; STEM = "#5f9c48"
SAGE = "#94b48c"; GREY = "#a9b8a6"; EARTH = "#a26a48"; SAND = "#e2c290"; GRASS = "#7fbf5c"
SEA = "#5fb5a0"


# ---------------- помощники ----------------
def soil(c, kind="earth"):
    if kind == "sand":
        c.add(ell(16, 44.2, 12.2, 2.5), SAND)
        for x, y in ((9, 44), (20, 45), (14, 45)):
            c.mark(x, y, ramp(SAND)[0][1])
        return
    c.add(ell(16, 44.2, 12.2, 2.5), EARTH)
    c.mark(10, 45, ramp(EARTH)[0][3]); c.mark(21, 45, ramp(EARTH)[0][3]); c.mark(15, 46, ramp(EARTH)[0][3])


def tufts(c, xs=(6, 25), color=GRASS):
    for x in xs:
        c.add(stroke([(x, 43), (x - 1, 40)]), color, "flat")
        c.add(stroke([(x + 1, 43), (x + 2, 41)]), color, "flat")


def stem(c, pts, color=STEM, w=None):
    if w is None:
        return c.add(stroke(pts), color, "flat")
    return c.add(tube(pts, w, w * 0.8), color)


def leaf(c, base, tip, w, color=LEAF, bend=0.0, mode="cel", shine=False):
    bx, by = base; tx, ty = tip
    mx, my = (bx + tx) / 2, (by + ty) / 2
    dx, dy = tx - bx, ty - by
    ln = math.hypot(dx, dy) or 1
    mx += -dy / ln * bend; my += dx / ln * bend
    return c.add(tube([base, (mx, my), tip], w, profile="leaf"), color, mode, shine=shine)


def blade(c, base, tip, w, color=LEAF, bend=0.0):
    bx, by = base; tx, ty = tip
    mx, my = (bx + tx) / 2, (by + ty) / 2
    dx, dy = tx - bx, ty - by
    ln = math.hypot(dx, dy) or 1
    mx += -dy / ln * bend; my += dx / ln * bend
    return c.add(tube([base, (mx, my), tip], w, 0.35), color)


def berry(c, x, y, r, color, shine=True):
    return c.add(ell(x, y, r, r), color, "dome", shine=shine)


def daisy(c, x, y, r, petal, center, cr=None):
    c.add(ell(x, y, r, r * 0.8), petal, "cel")
    cr = cr or max(1.0, r * 0.42)
    c.add(ell(x + 0.2, y - 0.2, cr, cr * 0.9), center, "dome", shine=True)


def spike(c, x, y_top, y_bot, color, r=1.4, step=2.2, sway=0.0):
    y = y_bot
    k = 0
    while y >= y_top:
        t = (y_bot - y) / max(1, (y_bot - y_top))
        rr = r * (1 - 0.35 * t)
        c.add(ell(x + sway * t + (0.6 if k % 2 else -0.6), y, rr + 0.3, rr), color, "dome", shine=(k % 2 == 0))
        y -= step; k += 1


def cup(c, x, y, w, h, color, center=None):
    """Чашечка цветка (мак, тюльпан)."""
    c.add(ell(x, y, w, h, 0, 2.3), color, "dome", shine=True)
    c.add(ell(x - w * 0.55, y - h * 0.35, w * 0.55, h * 0.7), color, "cel")
    c.add(ell(x + w * 0.55, y - h * 0.35, w * 0.55, h * 0.7), color, "cel", tone_bias=1)
    if center:
        c.mark(int(x), int(y - h * 0.2), hx(center)); c.mark(int(x) + 1, int(y - h * 0.2), hx(center))


def star(c, x, y, r, color, n=6, center=None, rot=0):
    m = set()
    for k in range(n):
        a = math.radians(rot + k * 360 / n)
        m |= tube([(x, y), (x + math.cos(a) * r, y + math.sin(a) * r)], 1.5, 0.5)
    m |= ell(x, y, r * 0.5, r * 0.5)
    c.add(m, color, "cel", shine=True)
    if center:
        c.add(ell(x, y, max(1.0, r * 0.3), max(1.0, r * 0.3)), center, "dome")


def frond(c, base, tip, w, color, bend=0.0):
    bx, by = base; tx, ty = tip
    mx, my = (bx + tx) / 2, (by + ty) / 2
    dx, dy = tx - bx, ty - by
    ln = math.hypot(dx, dy) or 1
    nx, ny = -dy / ln, dx / ln
    mx += nx * bend; my += ny * bend
    m = tube([base, (mx, my), tip], 0.7, 0.4)
    from apple_engine import bez
    pts = bez([base, (mx, my), tip], 10)
    for i in range(1, 10):
        t = i / 10
        px, py = pts[i]
        ww = w * math.sin(math.pi * (0.15 + t * 0.85)) + 0.6
        for sgn in (-1, 1):
            m |= tube([(px, py), (px + nx * sgn * ww + dx / ln * 1.2, py + ny * sgn * ww + dy / ln * 1.2)], 1.1, 0.5)
    return c.add(m, color, "cel")


def bell(c, x, y, r, color):
    c.add(ell(x, y, r, r * 1.1, 0, 2.4), color, "dome", shine=True)
    c.mark(int(x), int(y + r), ramp(color)[0][3])


def bush(c, blobs, color, mode="dome"):
    m = set()
    for (x, y, rx, ry) in blobs:
        m |= ell(x, y, rx, ry)
    return c.add(m, color, mode, shine=True)


def lumps(c, blobs, color):
    for (x, y, r) in blobs:
        c.add(ell(x, y, r, r * 0.9), color, "dome", shine=True, inner=False)


# ---------------- травы ----------------
H = {}


def herb(fn):
    H[fn.__name__[2:]] = fn
    return fn


@herb
def h_mint(c, st=3):
    soil(c)
    k = [0.35, 0.6, 0.85, 1.0][st]
    stems = [(-7, 0.75), (0, 1.0), (7, 0.8), (-3, 0.55), (4, 0.6)][: 2 + st]
    for dx, hk in stems:
        top = 43 - 30 * k * hk
        stem(c, [(16 + dx * 0.3, 43), (16 + dx, top)], STEM)
    for dx, hk in stems:
        top = 43 - 30 * k * hk
        n = max(1, int(5 * k * hk))
        for i in range(n):
            y = 41 - i * (43 - top - 2) / max(1, n)
            x = 16 + dx * (0.3 + 0.7 * (i + 1) / n)
            sc = 1 - i / (n + 2) * 0.4
            c.add(ell(x - 2.8 * sc, y - 1.2, 3.5 * sc, 2.3 * sc, -25), LEAF, "dome", shine=True)
            c.add(ell(x + 2.8 * sc, y - 1.8, 3.5 * sc, 2.3 * sc, 25), LEAF, "dome", shine=True)
        c.add(ell(16 + dx, top, 1.8, 2.4), LEAF_L, "dome", shine=True)
    if st == 3:
        spike(c, 16, 9, 13, "#c7a6e8", r=1.2, step=2.0)


@herb
def h_lavender(c, st=3):
    soil(c)
    k = [0.3, 0.55, 0.8, 1.0][st]
    for dx, hk in ((-7, 0.85), (0, 1.0), (7, 0.9)):
        top = 43 - 36 * k * hk
        x_top = 16 + dx * k
        stem(c, [(16 + dx * 0.2, 43), (16 + dx * 0.6, 32), (x_top, top + 9 * k)], SAGE)
        if st >= 2:
            y = top + 10 * k; n = 0
            while y >= top:
                c.add(ell(x_top + (0.5 if n % 2 else -0.5), y, 1.6, 1.2), "#9a7fd8", "dome", shine=(n % 2 == 0))
                y -= 2.0; n += 1
    for dx in (-6, -3, 3, 6):
        leaf(c, (16, 42), (16 + dx * 1.5, 35 - abs(dx) * 0.5), 1.4, SAGE, bend=dx * 0.2)


@herb
def h_chamomile(c, st=3):
    soil(c)
    k = [0.3, 0.55, 0.8, 1.0][st]
    heads = [(10, 18, -1), (16, 10, 0), (22, 16, 1), (13, 27, -1), (20, 25, 1)]
    for hx_, hy, s in heads:
        y = 43 - (43 - hy) * k
        stem(c, [(16 + s, 43), (16 + s * 2, 35), (hx_, y)], STEM)
    for dx in (-6, -3, 3, 6):
        blade(c, (16, 43), (16 + dx, 36), 1.0, LEAF_L, bend=dx * 0.3)
    if st >= 2:
        for hx_, hy, s in heads:
            y = 43 - (43 - hy) * k
            daisy(c, hx_, y - 1, 3.0 if st == 3 else 2.0, "#fbf6ec", "#f2c33c", 1.2)


@herb
def h_nettle(c, st=3):
    soil(c)
    k = [0.3, 0.55, 0.8, 1.0][st]
    top = 43 - 36 * k
    stem(c, [(16, 43), (16, top)], STEM)
    n = int(3 + 4 * k)
    for i in range(n):
        y = 41 - i * ((43 - top - 4) / n)
        s = (1 - i / n) * 0.8 + 0.3
        leaf(c, (16, y), (16 - 9 * s, y - 2), 2.4 * s + 0.6, LEAF_D, bend=-0.8)
        leaf(c, (16, y - 1), (16 + 9 * s, y - 3), 2.4 * s + 0.6, LEAF_D, bend=0.8)
    leaf(c, (16, top + 4), (16, top - 2), 2.0, LEAF)


@herb
def h_plantain(c):
    soil(c); tufts(c)
    for x, top in ((12, 8), (20, 6)):
        stem(c, [(16, 41), (x, 20), (x, top + 6)], STEM)
        c.add(tube([(x, top), (x, top + 8)], 1.6, 1.6), "#b8a25e", "cel", shine=True)
    for base, tip, b in (((16, 42), (5, 34), -1.5), ((16, 42), (27, 34), 1.5), ((16, 42), (10, 30), -1), ((16, 42), (22, 30), 1)):
        leaf(c, base, tip, 3.6, LEAF, bend=b, shine=True)


@herb
def h_clover(c):
    soil(c); tufts(c)
    for x, y in ((11, 14), (21, 12), (16, 9)):
        stem(c, [(16, 42), (x, y + 8), (x, y + 2)], STEM)
    for (x, y) in ((8, 30), (24, 30), (16, 26)):
        stem(c, [(16, 42), (x, y + 2)], STEM)
        for dx, dy in ((-2, 0), (2, 0), (0, -2)):
            c.add(ell(x + dx, y + dy, 2.2, 1.9), LEAF, "dome", shine=True)
        c.mark(x, y, "#d8f0c0")
    for x, y in ((11, 14), (21, 12), (16, 9)):
        c.add(ell(x, y, 3.2, 3.4, 0, 2.2), "#ec8fb0", "dome", shine=True)
        for k in range(3):
            c.mark(x - 1 + k, y - 2 + k, "#f9c8d8")


@herb
def h_dandelion(c):
    soil(c)
    for base, tip, b in (((16, 42), (4, 37), -1.4), ((16, 42), (28, 37), 1.4), ((16, 42), (9, 32), -1), ((16, 42), (23, 33), 1)):
        leaf(c, base, tip, 2.8, LEAF, bend=b, shine=True)
    stem(c, [(14, 41), (12, 26), (11, 14)], "#8fbf5c")
    stem(c, [(18, 41), (21, 28), (22, 12)], "#8fbf5c")
    # жёлтый цветок
    c.add(ell(11, 12, 3.6, 3.0), "#f6c73a", "cel")
    c.add(ell(11, 11.5, 2.2, 1.8), "#ffe170", "dome", shine=True)
    # пушистый шар
    c.add(ell(22, 9, 4.4, 4.4), "#f4f0ea", "dome", shine=True)
    for a in range(0, 360, 45):
        x = 22 + math.cos(math.radians(a)) * 2.6; y = 9 + math.sin(math.radians(a)) * 2.6
        c.mark(int(x), int(y), "#d8d0cc")
    c.mark(22, 9, "#c9b98a")


@herb
def h_yarrow(c):
    soil(c); tufts(c)
    stem(c, [(16, 43), (16, 12)], STEM)
    for i in range(6):
        y = 40 - i * 4.4
        s = 1 - i / 7
        side = -1 if i % 2 else 1
        c.add(tube([(16, y), (16 + side * 7 * s, y - 3)], 1.6 * s + 0.6, 0.6), LEAF)
        for k in range(1, 4):
            c.mark(int(16 + side * k * 2 * s), int(y - k * 0.9), ramp(LEAF)[0][3])
    m = set()
    for dx, dy in ((-4, 1), (-2, -1), (0, 0), (2, -1), (4, 1), (-1, 2), (2, 2), (0, -2)):
        m |= ell(16 + dx, 9 + dy, 1.8, 1.5)
    c.add(m, "#f8f2e8", "dome", shine=True)
    for dx, dy in ((-4, 1), (-1, 0), (2, -1), (4, 1), (0, 2)):
        c.mark(16 + dx, 9 + dy, "#e8d8a8")


@herb
def h_thyme(c):
    soil(c)
    bush(c, [(16, 37, 10.5, 5.5), (10, 39, 5, 3.5), (22, 39, 5, 3.5)], "#6e9e5c", "cel")
    lumps(c, [(11, 36, 2.2), (16, 34, 2.4), (21, 36, 2.2), (14, 38, 1.8), (19, 38, 1.8)], "#86b46c")
    for x, y in ((9, 33), (13, 31), (18, 31), (23, 33), (16, 30), (11, 36), (21, 35)):
        c.add(ell(x, y, 1.4, 1.2), "#d79ad8", "dome", shine=True)


@herb
def h_calendula(c):
    soil(c); tufts(c)
    for (x, y, s) in ((10, 14, -1), (17, 9, 0), (23, 16, 1)):
        stem(c, [(16 + s, 43), (16 + s * 3, 30), (x, y + 2)], STEM)
    for dx in (-7, -4, 4, 7):
        leaf(c, (16, 41), (16 + dx, 33), 2.0, LEAF, bend=dx * 0.2)
    for (x, y) in ((10, 14), (17, 9), (23, 16)):
        daisy(c, x, y, 3.6, "#f49a2e", "#d06a1e", 1.4)


@herb
def h_cornflower(c):
    soil(c); tufts(c)
    for (x, y, s) in ((10, 13, -1), (17, 8, 0), (23, 14, 1), (13, 21, -1)):
        stem(c, [(16 + s, 43), (16 + s * 2, 30), (x, y + 2)], "#7aa65a")
    for dx in (-6, -3, 3, 6):
        blade(c, (16, 42), (16 + dx, 32), 1.0, "#88b070", bend=dx * 0.2)
    for (x, y) in ((10, 13), (17, 8), (23, 14), (13, 21)):
        star(c, x, y, 3.4, "#5584e6", 7, "#2f3f98", rot=10)


@herb
def h_poppy(c):
    soil(c); tufts(c)
    stem(c, [(14, 43), (12, 28), (10, 14)], STEM)
    stem(c, [(18, 43), (20, 28), (22, 10)], STEM)
    stem(c, [(16, 43), (16, 34), (15, 27)], STEM)
    c.add(ell(15, 26, 1.5, 2.0), LEAF, "dome")
    for dx in (-5, 5):
        leaf(c, (16, 41), (16 + dx * 1.6, 35), 1.8, LEAF, bend=dx * 0.2)
    cup(c, 10, 12, 4.2, 3.4, "#ec4a3c", "#3a2238")
    cup(c, 22, 8, 4.4, 3.6, "#ec4a3c", "#3a2238")


exec(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "herbs_more.py"), encoding="utf-8").read(), globals())


def game_order():
    import re
    src = open(os.path.join(GAME, "herbs_db.gd"), encoding="utf-8").read()
    m = re.search(r'const ORDER\s*[:=][^\[]*\[(.*?)\]', src, re.S)
    return re.findall(r'"([a-z0-9_]+)"', m.group(1))


# ---------------- вывод ----------------
STAGED = ("mint", "lavender", "chamomile", "nettle")


def render(id_, st=3):
    c = Canvas(32, 48)
    fn = H[id_]
    if id_ in STAGED:
        fn(c, st)
    else:
        fn(c)
    return c.render()


def main(ids):
    os.makedirs(OUT, exist_ok=True)
    done = []
    for i in ids:
        if i not in H:
            continue
        if i in STAGED:
            for st in range(4):
                render(i, st).save(os.path.join(OUT, "%s_%d.png" % (i, st)))
        img = render(i)
        img.save(os.path.join(OUT, "herb14_%s.png" % i))
        done.append(i)
    compare(done)
    print("готово:", len(done), "трав ->", OUT)


def old_path(i):
    p = os.path.join(GAME, "art", "%s_3.png" % i)
    return p if os.path.exists(p) else os.path.join(GAME, "art", "herb14_%s.png" % i)


def compare(ids, cols=8, k=4):
    """Лист «было / стало»: в каждой ячейке старая и новая картинки."""
    cw, ch = 70, 58
    rows = (len(ids) + cols - 1) // cols
    sheet = Image.new("RGBA", (cols * cw * k, rows * ch * k), (246, 241, 230, 255))
    d = ImageDraw.Draw(sheet)
    for n, i in enumerate(ids):
        x = (n % cols) * cw * k; y = (n // cols) * ch * k
        old = Image.open(old_path(i)).convert("RGBA")
        new = Image.open(os.path.join(OUT, "herb14_%s.png" % i)).convert("RGBA")
        sheet.alpha_composite(up(old, k), (x + 2 * k, y + 2 * k))
        sheet.alpha_composite(up(new, k), (x + 36 * k, y + 2 * k))
        d.text((x + 4 * k, y + 51 * k), i, fill=(60, 40, 40, 255))
    sheet.save(os.path.join(OUT, "..", "herbs_compare_x4.png"))


if __name__ == "__main__":
    main(sys.argv[1:] or game_order())

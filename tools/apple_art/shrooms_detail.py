# -*- coding: utf-8 -*-
"""Детальные грибы «в стиле яблока» (32x32 вместо старых 24x24).
Пластинки под шляпкой, сеточка/чешуйки на ножке, бородавки, кольца, юбочки, вольвы, свечение.
Запуск:  python -I shrooms_detail.py [id ...]
Выход:   herbalist_game/art_apple/shrooms_detail/shroom_<id>.png (+ _x8 превью) и лист shrooms_detail_compare.png
Старые game/art/shroom_*.png НЕ трогает."""
import math, os, random, sys
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
from apple_engine import Canvas, ramp, hx, ell, tube, stroke, poly, rect, bez, up

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
OLD = os.path.join(ROOT, "backup_shrooms24_20261117")   # старые 24x24 (для сравнения и KEEP_OLD)
OUT = os.path.join(ROOT, "art_apple", "shrooms_detail")
W = H = 32
BASE = 29      # низ ножки
CX = 16


def T(col, k):
    return ramp(hx(col))[0][k]


def OL(col, k):
    return ramp(hx(col))[1][k]


# ------------------------------------------------------------------ гриб-холст
class Shroom:
    def __init__(s):
        s.c = Canvas(W, H)
        s.glow = None          # (цвет, радиус) — мягкий ореол
        s.shadow = (CX, BASE + 0.6, 8.5, 1.9)
        s.alpha = {}           # (x,y) -> альфа (полупрозрачные грибы)
        s.over = []            # пиксели поверх контура (x, y, rgba)
        s.gm = set()           # пластинки: ножка всегда позади них

    # ---- затенение по строкам: цилиндр (ножка) ----
    def cyl(s, mask, col, hi=True, bias=0):
        rows = {}
        for (x, y) in mask:
            rows.setdefault(y, []).append(x)
        for y, xs in rows.items():
            x0, x1 = min(xs), max(xs)
            n = x1 - x0 + 1
            for x in xs:
                f = (x - x0 + 0.5) / n
                t = 1 if f < 0.28 else 2 if f < 0.62 else 3 if f < 0.86 else 4
                if hi and n >= 4 and x == x0 + max(1, round(n * 0.2)) - 1:
                    t = 0 if n >= 5 else 1
                t = max(0, min(4, t + bias))
                s.c.mark(x, y, T(col, t))

    def stem(s, xb, yt, wb, wt, col, bend=0.0, yb=BASE, hi=True, bias=0):
        """Ножка от низа (xb, yb) до (xb+bend, yt); wb/wt — полуширины."""
        # построчно: центр по плавной кривой, ширина целая и одинаковая с обеих сторон -> ровные края, плоский низ
        m = set()
        y0, y1 = int(math.floor(yt - 1)), int(yb)
        for y in range(y0, y1 + 1):
            f = (y1 - y) / max(1, y1 - y0)                 # 0 внизу, 1 вверху
            c = xb + bend * (f * f * 0.65 + f * 0.35)
            hw = wb + (wt - wb) * f
            n = max(2, 2 * int(round(hw)))                 # чётная ширина: сужается сразу с двух сторон
            x0 = int(math.floor(c - n / 2 + 0.5))
            for x in range(x0, x0 + n):
                m.add((x, y))
        # без одиночных ступенек: ширина меняется не чаще, чем через 2 строки
        rows = {}
        for (x, y) in m:
            rows.setdefault(y, []).append(x)
        m -= s.gm
        s.c.add(m, col)
        s.cyl(m, col, hi, bias)
        return m

    def bulb(s, x, y, rx, ry, col):
        m = s.c.add(ell(x, y, rx, ry, p=2.2), col)
        s.cyl(m, col)
        return m

    # ---- шляпка-купол ----
    def cap(s, cx, cy, rx, ry, col, p=2.0, cut=0.5, shine=True, tilt=0.0):
        """Верхняя часть суперэллипса (ниже cy+cut обрезано)."""
        m = ell(cx, cy, rx, ry, tilt, p)
        m = {(x, y) for (x, y) in m if y <= cy + cut}
        return s.c.add(m, col, "dome", shine=shine)

    def gills(s, cx, y, rx, h, col, step=2, pores=False):
        """Низ шляпки: пластинки (полоски, сходятся к ножке) или губка-поры."""
        m = ell(cx, y, rx, h + 0.6)
        m = {(px, py) for (px, py) in m if py >= y - 0.5}
        m = s.c.add(m, col)
        s.gm = set(m)       # только последние (свои) пластинки
        light = sum(hx(col)) / 3 > 215          # светлые пластинки на тон темнее, чтобы не сливались с ножкой
        for (px, py) in m:
            dx = px + 0.5 - cx
            depth = (py - (y - 0.5)) / max(1, h)
            if pores:
                t = 3 if (px + py * 2) % 3 == 0 else 2
                if depth > 0.6:
                    t = 3
            else:
                # пластинки: линии, сходящиеся к центру
                k = round(dx * (1.0 - depth * 0.45))
                t = 3 if k % step == 0 else 2
                if depth < 0.3 and abs(dx) > rx * 0.55:
                    t = 2
            if dx > rx * 0.35:
                t = min(4, t + 1)
            if light:
                t = min(4, t + 1)
            s.c.mark(px, py, T(col, t))
        return m

    # ---- детали поверх ----
    def warts(s, pts, col="#fbf4ea", under=None):
        """Бородавки/пятна: ((x, y, r)...). r=1 — 1 пиксель, 2 — 2x2, 3 — плюсик."""
        for (x, y, r) in pts:
            if r <= 1:
                s.c.mark(x, y, T(col, 1))
            elif r == 2:
                s.c.mark(x, y, T(col, 0)); s.c.mark(x + 1, y, T(col, 1))
                s.c.mark(x, y + 1, T(col, 1)); s.c.mark(x + 1, y + 1, T(col, 2))
                if under:
                    s.c.mark(x + 1, y + 2, under)
            else:
                for (dx, dy) in ((0, 0), (1, 0), (-1, 0), (0, -1), (0, 1)):
                    s.c.mark(x + dx, y + dy, T(col, 1))
                s.c.mark(x - 1, y - 1, T(col, 1)); s.c.mark(x, y - 1, T(col, 0))
                s.c.mark(x + 1, y + 1, T(col, 2))
                if under:
                    s.c.mark(x + 1, y + 2, under); s.c.mark(x + 2, y + 1, under)

    def dots(s, pts, col):
        for (x, y) in pts:
            s.c.mark(x, y, hx(col) if isinstance(col, str) else col)

    def ring(s, cx, y, rx, col, h=1.6):
        """Кольцо-юбочка на ножке: висит вниз."""
        m = ell(cx, y, rx, h)
        m = {(x, yy) for (x, yy) in m if yy >= y - 1}
        m = s.c.add(m, col)
        for (x, yy) in m:
            t = 1 if yy < y else 2 if x < cx + rx * 0.3 else 3
            if yy == max(q[1] for q in m if q[0] == x) and (x % 2 == 0):
                t = 3
            s.c.mark(x, yy, T(col, t))
        return m

    def spark(s, x, y, col, size=1):
        s.c.spark(x, y, col, size)

    def leaf(s, a, b, w, col):
        return s.c.add(tube([a, ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2 - 1), b], w, profile="leaf"), col, shine=True)

    def grass(s, xs, col="#6aa858", base=BASE + 1):
        for (x, h, lean) in xs:
            s.c.add(stroke([(x, base), (x + lean * 0.5, base - h * 0.6), (x + lean, base - h)]), col, outline=False)

    # ---- итог ----
    def render(s):
        img = s.c.render()
        for (xy, a) in s.alpha.items():
            if 0 <= xy[0] < W and 0 <= xy[1] < H:
                r, g, b, aa = img.getpixel(xy)
                if aa:
                    img.putpixel(xy, (r, g, b, a))
        for (x, y, c) in s.over:
            if 0 <= x < W and 0 <= y < H:
                img.putpixel((x, y), c)
        out = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        px = out.load()
        if s.shadow:
            cx, cy, rx, ry = s.shadow
            for y in range(H):
                for x in range(W):
                    d = ((x + 0.5 - cx) / rx) ** 2 + ((y + 0.5 - cy) / ry) ** 2
                    a = 95 if d < 0.45 else 65 if d < 0.8 else (38 if d < 1.0 and (x + y) % 2 == 0 else 0)
                    if a:
                        px[x, y] = (62, 42, 58, a)
        if s.glow:
            gc, R, gx, gy = s.glow
            gc = hx(gc)
            for y in range(H):
                for x in range(W):
                    d = math.hypot(x + 0.5 - gx, (y + 0.5 - gy) * 1.1) / R
                    if d < 1.0:
                        a = 70 if d < 0.55 else 42 if d < 0.8 else (24 if (x + y) % 2 == 0 else 0)
                        if a:
                            r0, g0, b0, a0 = px[x, y]
                            px[x, y] = gc + (max(a, a0),)
        out.alpha_composite(img)
        return out


REG = {}
KEEP_OLD = {"tinder", "leaf_shelf"}   # старые лучше (замечание пользователя 17.11)


def shroom(fn):
    REG[fn.__name__[2:]] = fn
    return fn


# ------------------------------------------------------------------ общие формы
def classic(s, capc, stemc, gillc, *, cx=CX, cy=14, rx=10, ry=7, p=2.2, cut=1.0, sb=3.0, st=2.4,
            under=2.2, bend=0.0, pores=False, step=2, top=None, shine=True, tilt=0.0):
    """Классический гриб: пластинки -> ножка -> шляпка. Возвращает маску шляпки."""
    gy = cy + cut
    s.gills(cx + bend, gy, rx - 0.8, under, gillc, step=step, pores=pores)
    s.stem(cx, (top if top is not None else gy + 1), sb, st, stemc, bend=bend)
    return s.cap(cx + bend, cy, rx, ry, capc, p=p, cut=cut, shine=shine, tilt=tilt)


def funnel(s, col, stemc=None, *, cx=CX, top=11, rx=10, ry=3.0, neck=19, sb=2.6, wavy=True, inner=None, gillc=None):
    """Воронка (лисичка, груздь, рыжик): нисходящие пластинки + край шляпки + вогнутый центр."""
    stemc = stemc or col
    gillc = gillc or col
    # тело воронки (низ шляпки с пластинками, сужается в ножку)
    body = poly([(cx - rx + 0.5, top + 0.5), (cx + rx - 0.5, top + 0.5), (cx + sb + 0.6, neck + 1), (cx - sb - 0.6, neck + 1)])
    s.stem(cx, neck, sb, sb + 0.4, stemc)
    body = s.c.add(body, gillc)
    for (x, y) in body:
        dx = (x + 0.5 - cx) / max(1, rx)
        t = 3 if (round((x + 0.5 - cx) * (neck + 2 - y) / (neck + 2 - top) * 1.6)) % 2 == 0 else 2
        if dx > 0.25:
            t += 1
        s.c.mark(x, y, T(gillc, min(4, t)))
    # край-обод
    m = ell(cx, top, rx, ry, p=2.0)
    if wavy:
        m = {(x, y) for (x, y) in m if not (y <= top - ry + 1.2 and (x // 3) % 2 == 1)}
    m = s.c.add(m, col, "dome", shine=True)
    # вогнутый центр
    ic = inner or T(col, 2)
    cm = ell(cx + 0.6, top + 0.2, rx * 0.62, ry * 0.52)
    for (x, y) in cm:
        if (x, y) in m:
            s.c.mark(x, y, ic if (x + 0.5 - cx) > -rx * 0.35 else T(col, 1))
    return m


def bracket(s, x, y, rx, ry, col, ang=0.0, bands=True, edge=None):
    """Полка трутовика: полуэллипс, тёмный низ, концентрические полосы."""
    m = ell(x, y, rx, ry, ang, p=2.3)
    m = {(px, py) for (px, py) in m if py <= y + ry * 0.35}
    m = s.c.add(m, col, "dome", shine=True)
    if bands:
        for (px, py) in m:
            d = math.hypot((px + 0.5 - x) / rx, (py + 0.5 - y) / ry)
            if 0.62 < d < 0.74 or 0.36 < d < 0.46:
                s.c.mark(px, py, T(col, 3) if px > x - rx * 0.4 else T(col, 2))
    if edge:
        ys = {}
        for (px, py) in m:
            ys[px] = max(ys.get(px, -1), py)
        for px, py in ys.items():
            s.c.mark(px, py, T(edge, 1))
    # нижняя тень (поры)
    under = {(px, py) for (px, py) in ell(x + 0.5, y + ry * 0.35 + 0.6, rx * 0.88, 1.2) if py > y + ry * 0.35}
    u = s.c.add(under, col, tone_bias=1)
    for (px, py) in u:
        s.c.mark(px, py, T(col, 3) if (px + py) % 2 else T(col, 4))
    return m


def log(s, x0, x1, y, r, col="#8a6648"):
    """Кусок бревна/коряги (основа для трутовиков, вёшенок)."""
    m = s.c.add(tube([(x0, y), (x1, y)], r), col)
    for (x, yy) in m:
        t = 1 if yy <= y - r + 1 else 3 if yy >= y + r - 1 else 2
        if (x * 3 + yy) % 7 == 0:
            t = 3
        s.c.mark(x, yy, T(col, t))
    # срез с кольцами
    e = s.c.add(ell(x1, y, 1.6, r), "#d8b080")
    for (x, yy) in e:
        s.c.mark(x, yy, T("#d8b080", 2 if (x + yy) % 2 else 1))
    s.c.mark(round(x1 - 0.5), round(y - 0.5), T("#d8b080", 3))
    return m


def morel_cone(s, cx, top, bot, rx, col, stemc):
    s.stem(cx, bot - 1, 2.6, 2.4, stemc)
    m = ell(cx, (top + bot) / 2, rx, (bot - top) / 2, p=1.7)
    m = {(x, y) for (x, y) in m if y <= bot}
    m = s.c.add(m, col, "dome", shine=True)
    # ячейки-соты
    for (x, y) in m:
        r = (y - top)
        if (y % 3 == 0) or ((x + (y // 3) * 2) % 3 == 0):
            s.c.mark(x, y, T(col, 4) if x > cx - 1 else T(col, 3))
        elif x < cx - rx * 0.3 and y < bot - 3:
            s.c.mark(x, y, T(col, 1))
    return m


def ball(s, cx, cy, rx, ry, col, warts=True, base=None):
    if base:
        s.c.add(ell(cx, cy + ry * 0.7, rx * 0.55, ry * 0.45), base)
    m = s.c.add(ell(cx, cy, rx, ry, p=2.1), col, "dome", shine=True)
    if warts:
        r = random.Random(int(cx * 7 + cy))
        for (x, y) in m:
            if y < cy - ry * 0.2 and r.random() < 0.10:
                s.c.mark(x, y, T(col, 0) if x < cx else T(col, 2))
                if (x + 1, y + 1) in m:
                    s.c.mark(x + 1, y + 1, T(col, 3))
    return m


def coral(s, cx, col, branches, base_w=2.4):
    """Рогатик: ветки-трубочки с раздвоенными кончиками."""
    for (pts, w) in branches:
        m = s.c.add(tube(pts, w, w * 0.6), col)
        s.cyl(m, col)
    s.stem(cx, BASE - 4, base_w, base_w, col)


def cluster(s, items, capc, stemc, gillc, ring_col=None):
    """Семейка: [(x основания, высота шляпки y, rx, наклон)] — рисуется сзади вперёд."""
    for (x, cy, rx, bend) in items:
        ry = rx * 0.62
        s.gills(x + bend, cy + 0.8, rx - 0.6, 1.4, gillc)
        s.stem(x, cy + 1.6, 1.5, 1.2, stemc, bend=bend)
        if ring_col:
            s.ring(x + bend * 0.75, cy + 4.5, 1.8, ring_col, 1.0)
        s.cap(x + bend, cy, rx, ry, capc, p=2.0, cut=0.8)


# ------------------------------------------------------------------ грибы
@shroom
def g_porcini(s):
    s.stem(CX, 15, 4.6, 3.2, "#ece0c4")
    s.bulb(CX + 0.3, 25, 5.2, 4.2, "#ece0c4")
    # сеточка на ножке
    for (x, y) in ((13, 18), (15, 17), (14, 20), (16, 19), (13, 22), (15, 21), (17, 22), (14, 24), (16, 23), (18, 25), (13, 26), (15, 25)):
        s.c.mark(x, y, "#c8a87c")
    s.gills(CX, 14, 9.2, 2.0, "#e8d088", pores=True)
    s.cap(CX, 13, 11.5, 8.5, "#8a5634", p=2.3, cut=1.0)
    s.c.mark(10, 13, T("#8a5634", 1)); s.c.mark(12, 14, T("#8a5634", 1))   # светлая кромка края


@shroom
def g_birch_bolete(s):
    m = s.stem(CX, 15, 3.0, 2.2, "#f2ece0")
    r = random.Random(3)
    for (x, y) in m:
        if y > 16 and r.random() < 0.22:
            s.c.mark(x, y, "#5a4a48" if x > CX - 1 else "#8a7a70")
    s.gills(CX, 14.5, 8.8, 1.8, "#e8e0cc", pores=True)
    s.cap(CX, 13, 10.5, 7.5, "#b07a4c", p=2.4, cut=1.4)


@shroom
def g_chanterelle(s):
    funnel(s, "#f2a632", "#f0b448", top=12, rx=10.5, ry=3.2, neck=20, sb=2.4)


@shroom
def g_fly_agaric(s):
    s.bulb(CX, 26.5, 4.2, 2.8, "#f6f0e4")
    for (x, y) in ((12, 26), (14, 27), (19, 26), (20, 27)):
        s.c.mark(x, y, T("#f6f0e4", 3))
    s.stem(CX, 13, 2.8, 2.2, "#f6f0e4", yb=26)
    s.gills(CX, 13.2, 9.5, 2.1, "#f8f2e6")
    s.ring(CX, 17.5, 3.6, "#f8f2e6", 1.8)
    s.cap(CX, 12, 11.5, 8.2, "#de3a32", p=2.2, cut=1.0)
    s.warts([(10, 8, 2), (15, 5, 3), (20, 7, 2), (23, 10, 1), (12, 11, 1), (17, 10, 2), (8, 11, 1), (24, 12, 1), (13, 6, 1)],
            under=T("#de3a32", 3))


@shroom
def g_parasol(s):
    s.stem(CX, 11, 2.0, 1.5, "#e8dcc4")
    s.bulb(CX, 26.5, 3.0, 2.5, "#e8dcc4")
    for y in range(13, 26, 2):                      # змеиный узор
        s.c.mark(CX - 1 + (y // 2) % 2, y, "#a88a68")
    s.ring(CX, 15, 3.0, "#f2ead8", 1.5)
    s.gills(CX, 10.5, 12, 1.6, "#f4eee2")
    s.cap(CX, 10, 14, 5.5, "#eadcc0", p=2.0, cut=0.5)
    s.c.add(ell(CX, 5.2, 3.2, 2.0), "#8a5a38", "dome", shine=True)   # бугорок
    for (x, y) in ((8, 7), (11, 6), (20, 6), (23, 7), (5, 9), (13, 8), (18, 8), (26, 9), (9, 9), (22, 9), (15, 8)):
        s.c.mark(x, y, T("#9a6a44", 2)); s.c.mark(x + 1, y, T("#9a6a44", 3))


@shroom
def g_glow_cap(s):
    s.glow = ("#7ef0e0", 13, CX, 11)
    classic(s, "#3cc6bc", "#d8f0e8", "#b8f0e4", cy=13, rx=9.5, ry=7.5, sb=2.4, st=1.9, bend=0.5)
    s.warts([(11, 9, 2), (16, 7, 3), (21, 10, 2), (13, 12, 1), (19, 13, 1)], "#f0fff8")
    s.spark(7, 5, "#c8fff4", 1); s.spark(26, 4, "#c8fff4", 0); s.spark(25, 17, "#c8fff4", 0)


@shroom
def g_moon_shroom(s):
    s.glow = ("#c8c8ff", 12, CX, 11)
    classic(s, "#b4b6ea", "#ecebfa", "#dcdaf6", cy=12, rx=9, ry=7.5, p=2.0, sb=1.9, st=1.5, bend=-0.6)
    # серп луны на шляпке
    for (x, y) in ((14, 6), (13, 7), (13, 8), (13, 9), (14, 10), (15, 10)):
        s.c.mark(x, y, "#fffbe0")
    s.c.mark(15, 6, "#f0e8b8"); s.c.mark(16, 10, "#f0e8b8")
    s.spark(7, 4, "#fff6c8", 1); s.spark(25, 6, "#e8e8ff", 0); s.spark(23, 18, "#fff6c8", 0)


@shroom
def g_swamp_honey(s):
    s.grass([(8, 5, -1), (24, 6, 1), (21, 4, 0)], "#6a9a58")
    cluster(s, [(11, 15, 5.0, -2), (21, 13, 5.0, 2), (16, 10, 5.8, 0)], "#c48a3c", "#e2c58c", "#e8d4a4", ring_col="#f0e2c0")
    s.dots([(14, 7), (17, 7), (16, 6), (19, 8), (9, 12), (20, 10), (23, 11)], T("#c48a3c", 3))


@shroom
def g_web_shroom(s):
    classic(s, "#8a7aa6", "#d8d0e0", "#a890c0", cy=12, rx=10, ry=7.5, sb=2.6, st=2.2)
    # паутинная вуаль от края шляпки к ножке
    for (a, b) in (((8, 15), (14, 19)), ((10, 16), (14, 21)), ((24, 15), (18, 19)), ((22, 16), (18, 21))):
        for (x, y) in stroke([a, ((a[0] + b[0]) / 2, b[1] - 0.5), b]):
            s.over.append((x, y, (246, 244, 252, 200)))
    for (x, y) in stroke([(6, 4), (11, 2), (16, 3)]):
        s.over.append((x, y, (240, 240, 250, 150)))
    s.dots([(12, 7), (19, 8), (15, 9)], T("#8a7aa6", 1))


@shroom
def g_blood_russula(s):
    classic(s, "#b42444", "#f4ecec", "#f6eee8", cy=14, rx=10.5, ry=6, p=2.6, cut=0.6, sb=3.0, st=2.7, step=1)
    s.dots([(18, 24), (18, 25), (13, 21)], "#d84a60")


@shroom
def g_elf_star(s):
    s.glow = ("#d8ffb0", 11, CX, 12)
    classic(s, "#8ad08c", "#f2f6e4", "#e8f4d8", cy=13, rx=9, ry=7, p=2.0, sb=1.8, st=1.4, bend=1)
    # звёздочка на шляпке
    for (x, y) in ((17, 6), (17, 7), (17, 8), (17, 9), (17, 10), (15, 8), (16, 8), (18, 8), (19, 8), (16, 7), (18, 9)):
        s.c.mark(x, y, "#fffbd0")
    s.c.mark(17, 8, "#ffffff")
    s.spark(6, 6, "#fff6a8", 1); s.spark(27, 9, "#e8ffc8", 0); s.spark(9, 19, "#fff6a8", 0)


@shroom
def g_morel(s):
    morel_cone(s, CX, 4, 21, 6.5, "#a87a4c", "#ece2c8")


@shroom
def g_field_champignon(s):
    classic(s, "#f2ede2", "#f4f0e8", "#c48a8a", cy=14, rx=10, ry=7.5, p=2.1, sb=2.8, st=2.4)
    s.ring(CX, 18, 3.2, "#f6f2ea", 1.4)
    s.dots([(12, 9), (19, 10), (15, 11), (21, 12)], T("#e8dcc8", 2))


@shroom
def g_oyster(s):
    s.shadow = (CX, BASE + 0.6, 11, 1.8)
    log(s, 3, 27, 25, 3.6)
    for (x, y, rx, ry, a) in ((10, 11, 7, 4.4, -12), (20, 14, 7.5, 4.6, 10), (13, 18, 7, 4.2, -6)):
        m = bracket(s, x, y, rx, ry, "#b8b2a6", ang=a, bands=False)
        for (px, py) in m:     # пластинки веером
            if py > y and (px + 2 * py) % 3 == 0:
                s.c.mark(px, py, T("#b8b2a6", 3))


@shroom
def g_honey_fungus(s):
    s.shadow = (CX, BASE + 0.6, 10.5, 2)
    cluster(s, [(9, 16, 5.2, -2.5), (23, 15, 5.0, 2.5), (14, 11, 5.6, -1), (19, 10, 5.4, 1.2)], "#c99a50", "#e8d6a8", "#eee0bc", ring_col="#f6ecd2")
    # тёмные чешуйки у центра шляпок
    s.dots([(13, 6), (14, 7), (18, 5), (19, 6), (20, 5), (8, 12), (9, 11), (23, 11), (24, 10)], T("#8a5a30", 2))


@shroom
def g_red_bolete(s):
    m = s.stem(CX, 15, 3.0, 2.4, "#f2ece2")
    r = random.Random(5)
    for (x, y) in m:
        if y > 16 and r.random() < 0.25:
            s.c.mark(x, y, "#5c4848" if x > CX - 1 else "#8a7a70")
    s.gills(CX, 14.5, 8.6, 1.8, "#ece4d4", pores=True)
    s.cap(CX, 13, 10.5, 8.5, "#e06a32", p=2.2, cut=1.4)


@shroom
def g_slippery_jack(s):
    classic(s, "#8c5426", "#ecd690", "#e8c860", cy=14, rx=10.5, ry=6.5, p=2.4, sb=2.8, st=2.4, pores=True)
    s.ring(CX, 18.5, 3.3, "#d8c8b0", 1.3)
    # мокрый блик-полоса
    for (x, y) in ((9, 11), (10, 10), (11, 10), (12, 9), (13, 9), (14, 9)):
        s.c.mark(x, y, "#f6e2c8")
    s.dots([(18, 20), (14, 21), (17, 24)], T("#ecd690", 3))


@shroom
def g_saffron_milk(s):
    m = funnel(s, "#e8843e", "#eca060", top=12, rx=10.5, ry=3.6, neck=20, sb=2.8, wavy=False, gillc="#f0a258")
    for (x, y) in m:      # концентрические кольца
        d = math.hypot((x + 0.5 - CX) / 10.5, (y + 0.5 - 12) / 3.6)
        if 0.72 < d < 0.86 or 0.38 < d < 0.5:
            s.c.mark(x, y, T("#e8843e", 3))
    s.dots([(15, 23), (17, 25), (14, 26)], T("#e8843e", 3))


@shroom
def g_milk_cap(s):
    funnel(s, "#ece4c8", "#f2ecdc", top=13, rx=10, ry=3.4, neck=21, sb=2.8, wavy=False, gillc="#f0e8d2")
    # пушистый край
    for x in range(7, 26, 2):
        s.c.mark(x, 15 if 9 < x < 23 else 14, "#fffaf0")
    s.leaf((5, 29), (12, 22), 2.3, "#c88a3a")
    s.leaf((27, 29), (21, 24), 2.0, "#d8a040")
    s.leaf((10, 30), (19, 27), 1.8, "#a87a3a")


@shroom
def g_russula_green(s):
    classic(s, "#8ab070", "#f4f0e6", "#f6f2e6", cy=14, rx=10.5, ry=6, p=2.6, cut=0.6, sb=3.0, st=2.7, step=1)
    s.dots([(12, 10), (14, 9), (17, 10), (20, 11), (11, 12), (22, 12), (15, 11)], T("#8ab070", 3))


@shroom
def g_russula_yellow(s):
    classic(s, "#ecc848", "#f6f2e6", "#f8f2e0", cy=14, rx=10.5, ry=6, p=2.6, cut=0.6, sb=3.0, st=2.7, step=1)


@shroom
def g_puffball(s):
    m = ball(s, CX, 20, 7.5, 7.0, "#efe8d6", base="#e0d4b8")
    for (x, y) in ((13, 15), (16, 14), (19, 16), (14, 18), (18, 18), (11, 17), (21, 19), (16, 17)):
        s.c.mark(x, y, T("#efe8d6", 0)); s.c.mark(x + 1, y + 1, T("#efe8d6", 3))
    s.c.add(ell(CX + 0.5, 13.6, 1.2, 0.8), "#c0a880", "flat")   # макушка-поросль


@shroom
def g_giant_puffball(s):
    s.shadow = (CX, BASE + 0.6, 12, 2.2)
    s.grass([(4, 4, -1), (6, 6, 0), (27, 5, 1), (25, 3, 0)], "#6aa858")
    m = ball(s, CX, 18, 12.5, 10.5, "#f2ecdc", warts=False)
    # трещины-плитки
    for (a, b) in (((9, 10), (13, 13)), ((13, 13), (18, 11)), ((13, 13), (12, 17)), ((18, 11), (22, 14)), ((22, 14), (21, 19)), ((12, 17), (17, 19)), ((17, 19), (21, 19))):
        for (x, y) in stroke([a, b]):
            if (x, y) in m:
                s.c.mark(x, y, T("#f2ecdc", 3))


@shroom
def g_shaggy_ink(s):
    s.stem(CX, 19, 2.2, 1.8, "#f6f2ea")
    m = s.c.add(ell(CX, 12, 6.2, 10, p=2.4), "#f4f0e6", "dome", shine=True)
    m2 = {(x, y) for (x, y) in m if y > 18}
    # лохмотья-чешуйки
    for (x, y) in m:
        if y > 4 and (x + (y // 2) * 3) % 4 == 0 and y % 2 == 0:
            s.c.mark(x, y, T("#d8c8b0", 2)); s.c.mark(x, y + 1, T("#d8c8b0", 3))
    s.c.add(ell(CX, 3.6, 3, 1.6), "#c8a888", "dome", shine=True)
    # чернильный низ и капли
    for (x, y) in m:
        if y >= 19:
            s.c.mark(x, y, "#4a3a58" if (x + y) % 2 else "#5c4a6a")
    for (x, y) in ((11, 22), (11, 23), (20, 22), (20, 23), (20, 24), (14, 23)):
        s.over.append((x, y, (74, 58, 92, 255)))


@shroom
def g_chicken_woods(s):
    s.shadow = (CX, BASE + 0.6, 11, 1.8)
    for (x, y, rx, ry, a) in ((15, 8, 9, 4.5, -4), (18, 14, 10, 4.8, 3), (14, 20, 11, 4.8, -2), (17, 25, 9, 3.6, 0)):
        bracket(s, x, y, rx, ry, "#f2a020", ang=a, bands=True, edge="#f8e060")


@shroom
def g_tinder(s):
    s.shadow = (CX, BASE + 0.6, 11, 1.8)
    s.c.add(rect(22, 2, 30, 30), "#7a5a44")
    for y in range(2, 31):
        for x in range(22, 31):
            s.c.mark(x, y, T("#7a5a44", 3 if (x * 2 + y // 3) % 5 == 0 else 1 if x == 22 else 2))
    m = s.c.add(ell(22, 15, 15, 9, p=2.0), "#9a9288", "dome", shine=True)
    for (x, y) in m:   # полосы-годы копыта
        d = math.hypot((x + 0.5 - 22) / 15, (y + 0.5 - 15) / 9)
        if any(abs(d - r) < 0.045 for r in (0.55, 0.7, 0.84)):
            s.c.mark(x, y, T("#9a9288", 3))
        if d > 0.92 and y > 15:
            s.c.mark(x, y, T("#c8a878", 2))
    s.c.add(rect(22, 2, 30, 30) - m, "#7a5a44")


@shroom
def g_lions_mane(s):
    s.shadow = (CX, BASE + 0.6, 10, 1.8)
    s.c.add(ell(CX, 9, 10, 6.5, p=2.3), "#f4efe2", "dome", shine=True)
    r = random.Random(11)
    for i, x in enumerate(range(6, 27)):
        L = 10 + int(5 * math.sin(i * 0.9) ** 2) + r.randint(0, 3)
        top = 12 if 8 < x < 24 else 11
        for y in range(top, min(top + L, 28)):
            col = T("#f4efe2", 1 if i % 2 == 0 else 2) if y < top + L - 2 else T("#f4efe2", 3)
            if x > 21:
                col = T("#f4efe2", 3)
            s.over.append((x, y, col + (255,)))
    for x in range(6, 27, 2):
        s.over.append((x, 12, T("#f4efe2", 3) + (255,)))


@shroom
def g_coral(s):
    coral(s, CX, "#f0c040", [
        ([(16, 25), (11, 16), (8, 8)], 2.0), ([(16, 25), (21, 15), (24, 7)], 2.0), ([(16, 25), (15, 14), (16, 5)], 2.2),
        ([(10, 14), (6, 10), (5, 6)], 1.4), ([(22, 13), (26, 11), (27, 7)], 1.4), ([(15, 12), (12, 7), (12, 4)], 1.3),
        ([(16, 9), (19, 5), (20, 2)], 1.3)])
    for (x, y) in ((8, 7), (24, 6), (16, 4), (5, 5), (27, 6), (12, 3), (20, 2)):
        s.c.mark(x, y, "#f8b030")


@shroom
def g_truffle_black(s):
    s.shadow = None
    m = s.c.add(ell(CX, 25, 13, 5, p=2.0), "#8a6448")      # бугорок земли
    for (x, y) in m:
        if (x * 5 + y * 3) % 7 == 0:
            s.c.mark(x, y, T("#8a6448", 3))
    t = s.c.add(ell(CX + 1, 18, 7.5, 7, p=2.0), "#4c3a44", "dome", shine=True)
    for (x, y) in t:      # бородавки-многоугольнички
        if (x + y * 2) % 4 == 0 and y < 23:
            s.c.mark(x, y, T("#4c3a44", 1 if x < CX + 1 else 3))
    # срез рядом: мраморная мякоть
    sl = s.c.add(ell(8, 25.5, 4, 3), "#6a4c48")
    s.c.add(ell(8, 25.3, 3, 2.1), "#c8a898", outline=False)
    for (x, y) in ((6, 25), (7, 24), (8, 25), (9, 26), (10, 25)):
        s.c.mark(x, y, "#f0dcd0")
    s.leaf((22, 29), (28, 24), 2.0, "#a87038")


@shroom
def g_death_cap(s):
    s.c.add(ell(CX, 27, 4.8, 2.6), "#f2efe0")       # вольва-мешочек
    s.c.add(poly([(10.5, 27), (11.5, 23), (13, 25), (16, 24), (19, 25), (20.5, 23), (21.5, 27)]), "#ecead8")
    s.stem(CX, 13, 2.6, 2.0, "#f4f2e8", yb=26)
    s.gills(CX, 13.2, 9.5, 2.0, "#f8f6ee")
    s.ring(CX, 17, 3.6, "#f6f4ea", 1.9)
    s.cap(CX, 12, 11, 7.5, "#b8c094", p=2.2, cut=1.0)
    for (x, y) in stroke([(9, 10), (12, 8)]) | stroke([(20, 8), (23, 10)]):    # волоконца
        s.c.mark(x, y, T("#b8c094", 3))


@shroom
def g_panther(s):
    s.bulb(CX, 26, 3.8, 2.6, "#f2ece0")
    s.c.add(ell(CX, 24.4, 4.2, 0.9), "#f8f4ea", "flat")    # ободок вольвы
    s.stem(CX, 13, 2.6, 2.0, "#f2ece0", yb=25)
    s.gills(CX, 13.2, 9.5, 2.0, "#f6f2e8")
    s.ring(CX, 17.5, 3.4, "#f6f2e8", 1.6)
    s.cap(CX, 12, 11, 7.5, "#8c6a48", p=2.2, cut=1.0)
    s.warts([(10, 9, 2), (15, 6, 2), (20, 8, 2), (23, 11, 1), (12, 12, 1), (17, 10, 1), (8, 12, 1), (19, 5, 1), (13, 9, 1)], "#f8f2e4")


@shroom
def g_royal_agaric(s):
    s.bulb(CX, 26.4, 4.4, 2.8, "#f4e8cc")
    s.stem(CX, 13, 2.9, 2.3, "#f4e8cc", yb=26)
    s.gills(CX, 13.2, 9.8, 2.1, "#f6ecd2")
    s.ring(CX, 17.5, 3.8, "#f8eed8", 1.9)
    s.cap(CX, 12, 11.5, 8.2, "#d8902e", p=2.2, cut=1.0)
    s.warts([(10, 8, 2), (15, 5, 3), (20, 7, 2), (23, 11, 1), (12, 11, 1), (17, 10, 2), (8, 11, 1)], "#f6dc94",
            under=T("#d8902e", 3))
    for (x, y) in ((15, 3), (14, 4), (16, 4)):   # корона-искра
        s.c.mark(x, y, "#fff4b8")


@shroom
def g_fairy_ring(s):
    s.shadow = (CX, BASE + 0.6, 13, 2)
    s.grass([(3, 4, -1), (8, 5, 0), (13, 3, 1), (19, 4, 0), (25, 5, 1), (29, 3, 0)], "#78b05e")
    for (x, cy, rx, b) in ((6, 20, 3.8, -1), (26, 20, 3.8, 1), (11, 16, 4.2, 0), (21, 16, 4.2, 0), (16, 19, 4.6, 0)):
        s.gills(x + b, cy + 0.8, rx - 0.6, 1.2, "#f0e2c4")
        s.stem(x, cy + 1.6, 1.2, 0.9, "#ecdcbc", bend=b, yb=BASE - (1 if x in (11, 21) else 0))
        s.cap(x + b, cy, rx, rx * 0.72, "#d8b07c", p=2.0, cut=0.8)
        s.c.mark(round(x + b) - 1, round(cy - rx * 0.55), T("#d8b07c", 3))


@shroom
def g_amethyst(s):
    s.shadow = (CX, BASE + 0.6, 7, 1.6)
    s.grass([(9, 4, -1), (23, 5, 1)], "#5e9c64")
    classic(s, "#9a62c6", "#b88ad8", "#8a52b4", cy=15, rx=7.5, ry=6, p=2.0, sb=1.8, st=1.5, bend=-1, step=1)
    for y in range(18, 28, 2):
        s.c.mark(CX - 1 + (y // 2) % 2, y, "#d8b8f0")


@shroom
def g_velvet_shank(s):
    s.shadow = (CX, BASE + 0.6, 10, 1.9)
    for (x, cy, rx, b) in ((10, 14, 4.8, -2.5), (22, 13, 4.8, 2.5), (16, 9, 5.4, 0)):
        s.gills(x + b, cy + 0.8, rx - 0.6, 1.4, "#f6e2b4")
        m = s.stem(x, cy + 1.6, 1.5, 1.2, "#e09a50", bend=b)
        for (px, py) in m:            # бархатный тёмный низ
            if py > cy + 7:
                s.c.mark(px, py, T("#5a3a2c", 2 if px <= x else 3))
        s.cap(x + b, cy, rx, rx * 0.6, "#e88a2c", p=2.0, cut=0.8)
        s.c.mark(round(x + b) - 2, round(cy - rx * 0.4), "#ffe8b0")


@shroom
def g_bog_bolete(s):
    s.c.add(ell(CX, 28, 11, 3.2), "#6a9c5c")             # кочка мха
    for x in range(6, 27, 2):
        s.c.mark(x, 26 if 9 < x < 23 else 27, "#9ccc80")
    m = s.stem(CX, 15, 2.6, 2.0, "#f2eee6", yb=27)
    for (x, y) in m:
        if y > 16 and (x * 3 + y) % 5 == 0:
            s.c.mark(x, y, "#9a9088")
    s.gills(CX, 14.5, 8.6, 1.8, "#eee8dc", pores=True)
    s.cap(CX, 13, 10, 7, "#dccaa6", p=2.3, cut=1.4)


@shroom
def g_cauliflower(s):
    s.shadow = (CX, BASE + 0.6, 11, 2)
    r = random.Random(4)
    lobes = [(16, 8, 5.5), (10, 11, 5), (22, 11, 5), (7, 18, 4.5), (25, 18, 4.5), (12, 18, 5.5), (20, 18, 5.5), (16, 14, 5.5), (16, 22, 6), (10, 24, 4.5), (22, 24, 4.5)]
    for (x, y, rr) in lobes:
        m = s.c.add(ell(x, y, rr, rr * 0.8), "#ead494", "dome", shine=True)
        for (px, py) in m:     # курчавые ленты
            if (px * 2 + py * 3 + int(x)) % 5 == 0:
                s.c.mark(px, py, T("#ead494", 3))


@shroom
def g_jelly_ear(s):
    s.c.add(tube([(2, 22), (14, 21), (30, 18)], 2.2), "#8a6a4c")    # веточка бузины
    for x in (8, 18, 25):
        s.c.mark(x, 20, T("#8a6a4c", 1))
    m = s.c.add(ell(14, 13, 8, 7, -15, p=2.0), "#a8483c", "dome", shine=True)
    for (x, y) in ell(15, 13.5, 4.5, 3.8, -15):      # внутренность ушка
        if (x, y) in m:
            s.c.mark(x, y, T("#a8483c", 3))
    for (x, y) in stroke([(12, 11), (15, 14), (17, 13)]):   # складка
        s.c.mark(x, y, T("#a8483c", 4))
    s.c.mark(9, 9, "#f8c8b8"); s.c.mark(10, 8, "#f0a898")   # мокрый блик
    m2 = s.c.add(ell(23, 13, 4, 3.6, 20), "#b05040", "dome", shine=True)


@shroom
def g_ghost_cap(s):
    s.glow = ("#d8ecff", 12, CX, 12)
    m1 = s.stem(CX, 14, 2.2, 1.8, "#e8f2fa", bend=0.8)
    m2 = s.gills(CX + 0.8, 14, 8.5, 1.8, "#d8e8f6")
    m3 = s.cap(CX + 0.8, 13, 9.5, 9, "#d4e8f8", p=1.9, cut=1.0)
    for (x, y) in m1 | m3:
        s.alpha[(x, y)] = 205
    s.dots([(12, 8), (13, 7), (19, 10)], "#ffffff")
    s.spark(6, 6, "#ffffff", 0); s.spark(26, 8, "#e0f0ff", 1); s.spark(8, 20, "#ffffff", 0)


@shroom
def g_bat_cap(s):
    s.gills(CX, 14, 8, 1.8, "#7a6088")
    s.stem(CX, 15, 2.3, 1.8, "#c8b8d0")
    wing = poly([(1, 9), (5, 7), (9, 8), (12, 11), (8, 12), (6, 15), (4, 12)])
    s.c.add(wing, "#4c3a5c")
    s.c.add({(31 - x, y) for (x, y) in wing}, "#4c3a5c")
    s.cap(CX, 13, 7.5, 7, "#5c4870", p=2.0, cut=1.0)
    for (x, y) in ((12, 5), (12, 4), (13, 5), (19, 5), (19, 4), (18, 5)):    # ушки
        s.over.append((x, y, T("#5c4870", 2) + (255,)))
    s.over.append((12, 3, OL("#5c4870", 0) + (255,))); s.over.append((19, 3, OL("#5c4870", 1) + (255,)))
    for (x, y) in ((4, 9), (7, 9), (27, 9), (24, 9)):
        s.c.mark(x, y, T("#4c3a5c", 1))


@shroom
def g_bloodfoot(s):
    m = s.stem(CX, 14, 2.4, 2.0, "#c88a7c", bend=-1)
    for (x, y) in m:
        if y > 18:
            s.c.mark(x, y, T("#b03048", 2 if x < CX - 1 else 3))
    s.gills(CX - 1, 13.8, 8.4, 1.8, "#e8d8c8")
    s.cap(CX - 1, 12.5, 9.5, 8.5, "#9a5848", p=1.9, cut=1.2)
    for (x, y) in ((19, 21), (19, 22), (19, 24), (13, 27)):     # алые капли
        s.over.append((x, y, (214, 40, 72, 255)))
    s.over.append((20, 23, (180, 30, 60, 255)))
    s.dots([(12, 8), (11, 9)], T("#9a5848", 0))


@shroom
def g_spider_veil(s):
    classic(s, "#8c58b8", "#dccbe8", "#7a4aa0", cy=12, rx=10, ry=7.5, sb=2.6, st=2.2)
    for (a, b) in (((7, 15), (14, 20)), ((9, 16), (14, 23)), ((12, 16), (15, 21)), ((25, 15), (18, 20)), ((23, 16), (18, 23)), ((20, 16), (17, 21))):
        for (x, y) in stroke([a, ((a[0] + b[0]) / 2, b[1]), b]):
            s.over.append((x, y, (248, 244, 255, 215)))
    for (x, y) in stroke([(10, 17), (16, 18), (22, 17)]):
        s.over.append((x, y, (248, 244, 255, 170)))
    s.dots([(12, 7), (19, 8)], T("#8c58b8", 1))


@shroom
def g_silk_puff(s):
    m = ball(s, CX, 19, 8, 7.5, "#f6f2ea", warts=False, base="#e8e0d0")
    for (a, b, c) in (((8, 15), (16, 22), (24, 17)), ((9, 21), (16, 12), (23, 21)), ((10, 13), (18, 18), (23, 13)), ((8, 19), (15, 26), (24, 22))):
        for (x, y) in stroke([a, b, c]):
            if (x, y) in m:
                s.c.mark(x, y, (255, 255, 255) if x < CX else T("#e8e4f0", 2))
    s.spark(25, 10, "#ffffff", 0)


@shroom
def g_crystal_cap(s):
    s.glow = ("#bff0ff", 12, CX, 12)
    m1 = s.stem(CX, 14, 2.2, 1.7, "#d8f2fa")
    m2 = s.cap(CX, 13, 10, 8.5, "#a8e0f2", p=1.5, cut=1.0)
    for (x, y) in m2:     # грани
        u = x + 0.5 - CX
        if abs(u) < 0.8 or abs(u - (y - 6) * 0.7) < 0.5 or abs(u + (y - 6) * 0.7) < 0.5:
            s.c.mark(x, y, T("#a8e0f2", 0) if u <= 0 else T("#a8e0f2", 3))
    for (x, y) in m1 | m2:
        s.alpha[(x, y)] = 225
    s.spark(10, 7, "#ffffff", 1); s.spark(25, 4, "#e8fbff", 0); s.spark(6, 18, "#e8fbff", 0)


@shroom
def g_lantern(s):
    s.glow = ("#ffb050", 14, CX, 12)
    s.stem(CX, 18, 2.0, 1.6, "#7a5848")
    m = s.c.add(ell(CX, 12, 7.5, 8, p=2.6), "#ffa040", "dome", shine=True)
    for (x, y) in m:
        if x in (12, 16, 20) and 6 < y < 19:      # рёбра фонарика
            s.c.mark(x, y, T("#ffa040", 3))
        if abs(x + 0.5 - CX) < 2 and 9 < y < 15:
            s.c.mark(x, y, "#fff2a0")
    s.c.add(ell(CX, 4.4, 4.5, 1.6), "#7a5848")       # крышечка
    s.c.add(ell(CX, 19.6, 5.5, 1.4), "#7a5848")
    s.c.add(ell(CX, 2.4, 1.2, 1.2), "#7a5848")
    s.spark(5, 8, "#ffe0a0", 0); s.spark(27, 14, "#ffe0a0", 1)


@shroom
def g_cave_coral(s):
    s.glow = ("#bcd8ff", 10, CX, 14)
    coral(s, CX, "#94bce6", [
        ([(16, 25), (10, 17), (7, 9)], 1.9), ([(16, 25), (22, 16), (25, 8)], 1.9), ([(16, 25), (16, 14), (15, 5)], 2.0),
        ([(9, 15), (5, 12), (4, 8)], 1.3), ([(23, 14), (27, 11), (28, 7)], 1.3), ([(16, 12), (19, 7), (20, 4)], 1.2)])
    for (x, y) in ((7, 8), (25, 7), (15, 4), (4, 7), (28, 6), (20, 3)):
        s.c.mark(x, y, "#e8f6ff")


@shroom
def g_rainbow_cap(s):
    classic(s, "#e8a8d8", "#f4eef8", "#f2e8f6", cy=13, rx=10.5, ry=8, p=2.1, sb=2.6, st=2.2)
    cols = ["#f06a6a", "#f8a850", "#f8e070", "#8ad88a", "#78b8f0", "#b090f0"]
    for (x, y) in ell(CX, 13, 10.5, 8, p=2.1):
        if y <= 14 and 0 <= x < W and 0 <= y < H:
            k = int((x + 0.5 - 5.5 + (13 - y) * 0.6) / 2.2)
            if 0 <= k < 6 and not (x <= 5 or x >= 27):
                c = cols[k]
                s.c.mark(x, y, T(c, 1 if y < 9 and x < 18 else 2 if x < 21 else 3))
    s.spark(10, 6, "#ffffff", 1); s.spark(26, 4, "#fff6c8", 0)


@shroom
def g_candy_cap(s):
    m = classic(s, "#f094b4", "#f8eef2", "#f8dce6", cy=13, rx=10, ry=8, p=2.0, sb=2.4, st=2.0)
    for (x, y) in m:      # спираль-леденец
        a = math.atan2(y + 0.5 - 9, x + 0.5 - CX)
        r = math.hypot(x + 0.5 - CX, (y + 0.5 - 9) * 1.4)
        if (a * 1.6 + r * 0.55) % 2.0 < 0.7:
            s.c.mark(x, y, "#fff4f8" if x < 18 and y < 11 else "#f8dce8")
    s.dots([(10, 8), (11, 7)], "#ffffff")
    for y in range(17, 28, 3):
        s.c.mark(CX - 1, y, "#f094b4"); s.c.mark(CX, y + 1, "#f094b4")


@shroom
def g_cloud_puff(s):
    for (x, y, r, c) in ((10, 20, 5.5, "#f4f0fa"), (22, 20, 5.5, "#f4f0fa"), (16, 15, 7.5, "#faf8ff"), (16, 22, 7, "#f8f4ff")):
        s.c.add(ell(x, y, r, r * 0.85), c, "dome", shine=True)
    s.dots([(13, 21), (14, 22), (19, 21)], "#f8d0e0")
    s.spark(26, 8, "#d8e8ff", 1); s.spark(5, 12, "#ffe0f0", 0)


@shroom
def g_heart_cap(s):
    s.gills(CX, 15, 7.5, 1.6, "#f8d8e0")
    s.stem(CX, 16, 2.4, 2.0, "#f8eef0")
    m = s.c.add(ell(11.5, 9, 5.5, 5.5) | ell(20.5, 9, 5.5, 5.5) | poly([(6, 10.5), (26, 10.5), (16, 18)]), "#ec4868", "dome", shine=True)
    s.dots([(9, 6), (10, 6), (9, 7), (19, 6)], "#ffd0dc")
    s.spark(26, 3, "#ffd8e8", 0); s.spark(4, 4, "#ffd8e8", 1)


@shroom
def g_star_puff(s):
    s.glow = ("#d8c0ff", 13, CX, 19)
    s.shadow = (CX, BASE - 0.5, 12, 2.2)
    n = 7
    for i in range(n):          # лучи-звезда (земляная звёздочка)
        a = math.radians(-90 + i * 360 / n + 26)
        ex, ey = CX + math.cos(a) * 14.5, 22 + math.sin(a) * 6.5
        m = s.c.add(tube([(CX, 22), (ex, ey)], 3.4, profile="drop"), "#d0a878" if ey > 21 else "#c09068")
    ball(s, CX, 17, 6, 5.6, "#b8a8d0", warts=False)
    for (x, y) in ((13, 15), (18, 14), (15, 19), (19, 18)):
        s.c.mark(x, y, T("#b8a8d0", 3))
    s.c.mark(CX, 11, T("#b8a8d0", 4)); s.c.mark(CX - 1, 12, T("#b8a8d0", 3))   # устье
    s.spark(7, 8, "#f0e0ff", 1); s.spark(25, 7, "#fff6c8", 1); s.spark(16, 4, "#f0e0ff", 0)


@shroom
def g_mana_cap(s):
    s.glow = ("#80b0ff", 13, CX, 11)
    s.stem(CX, 13, 2.2, 1.6, "#c8d8f8", bend=0.6)
    s.gills(CX + 0.6, 12.5, 7.5, 1.6, "#a0c0f0")
    s.cap(CX + 0.6, 11, 8.5, 9, "#3a72e0", p=1.8, cut=1.0)
    s.warts([(13, 6, 2), (17, 4, 1), (19, 8, 2), (12, 10, 1), (16, 9, 1)], "#c8e8ff")
    for (x, y) in ((15, 19), (16, 22), (15, 25)):
        s.c.mark(x, y, "#e8f4ff")
    s.spark(6, 7, "#d8f0ff", 1); s.spark(27, 12, "#d8f0ff", 0); s.spark(24, 3, "#ffffff", 0)


@shroom
def g_sage_cap(s):
    m = classic(s, "#98aa88", "#e8ecdc", "#d8e0c8", cy=13, rx=10, ry=7.5, p=2.1, sb=2.6, st=2.2)
    for (pts) in ([(11, 11), (14, 8), (17, 6)], [(17, 6), (20, 9), (22, 12)]):   # листок-узор
        for (x, y) in stroke(pts):
            s.c.mark(x, y, T("#6a8a5c", 2))
    for (x, y) in ((13, 9), (15, 8), (19, 8), (21, 10)):
        s.c.mark(x, y, T("#6a8a5c", 1))
    s.spark(26, 5, "#f0ffe0", 0)


@shroom
def g_leaf_shelf(s):
    s.shadow = (CX, BASE + 0.6, 11, 1.8)
    s.c.add(rect(1, 1, 7, 30), "#8a6c4c")
    for y in range(1, 31):
        for x in range(1, 8):
            s.c.mark(x, y, T("#8a6c4c", 3 if (x + y // 3) % 4 == 0 else 1 if x == 1 else 2))
    for (x, y, rx, ry) in ((13, 8, 9.5, 4), (16, 15, 11, 4.4), (14, 22, 10, 4.2)):
        m = bracket(s, x, y, rx, ry, "#86b862", bands=True, edge="#d0ec98")
        for (px, py) in stroke([(x - rx * 0.6, y), (x + rx * 0.7, y - 0.5)]):   # прожилка
            if (px, py) in m:
                s.c.mark(px, py, T("#86b862", 3))


@shroom
def g_dwarf_beard(s):
    s.shadow = (CX, BASE + 0.6, 12, 1.8)
    log(s, 2, 28, 8, 4.0)
    r = random.Random(9)
    for i, x in enumerate(range(5, 27)):
        L = 9 + int(7 * math.sin((x - 5) / 21 * math.pi)) + r.randint(0, 2)
        for y in range(12, 12 + L):
            t = 1 if (i % 3 == 0) else 2 if i % 3 == 1 else 3
            if y > 12 + L - 3:
                t = min(4, t + 1)
            if x > 21:
                t = min(4, t + 1)
            s.over.append((x, y, T("#d86a30", t) + (255,)))
    # кончик-косичка
    for y in range(22, 28):
        s.over.append((16, y, T("#d86a30", 2) + (255,)))
    s.over.append((16, 25, (240, 200, 90, 255)))


@shroom
def g_iron_cap(s):
    classic(s, "#9aa2b2", "#b8bcc6", "#8a8e9c", cy=13, rx=10.5, ry=7.5, p=2.4, sb=2.8, st=2.4)
    for (x, y) in ((9, 11), (13, 8), (18, 8), (22, 11), (16, 6)):      # заклёпки
        s.c.mark(x, y, "#f0f4fa"); s.c.mark(x + 1, y + 1, T("#9aa2b2", 4))
    for (x, y) in stroke([(7, 12), (16, 10), (25, 12)]):
        s.c.mark(x, y, T("#9aa2b2", 3))
    s.c.mark(11, 6, "#ffffff")


@shroom
def g_ember_cap(s):
    s.glow = ("#ff8a40", 10, CX, 11)
    classic(s, "#4c3c44", "#6a5a5c", "#3a2e34", cy=13, rx=10, ry=7.5, p=2.2, sb=2.6, st=2.2)
    for (pts) in ([(10, 10), (13, 8), (15, 11)], [(15, 11), (19, 7), (21, 10)], [(15, 11), (16, 14)], [(21, 10), (24, 12)]):
        for (x, y) in stroke(pts):
            s.c.mark(x, y, "#ffa040")
    for (x, y) in ((13, 8), (19, 7), (16, 13)):
        s.c.mark(x, y, "#fff0a0")
    s.spark(8, 4, "#ffb060", 0); s.spark(24, 3, "#ffd080", 0); s.spark(27, 9, "#ff9a50", 0)


@shroom
def g_steppe_morel(s):
    s.grass([(7, 5, -1), (9, 3, 0), (24, 6, 1), (26, 4, 0)], "#b0a858")
    morel_cone(s, CX, 5, 21, 6.2, "#cba868", "#efe4c8")


@shroom
def g_shiitake(s):
    s.shadow = (CX, BASE + 0.6, 12, 1.8)
    log(s, 2, 28, 26, 3.2, "#7a5a40")
    classic(s, "#7c4a30", "#ecdcc0", "#f4eadc", cy=14, rx=10.5, ry=6.5, p=2.3, sb=2.4, st=2.0, top=15)
    for (x, y) in ((10, 11), (13, 9), (17, 8), (21, 10), (12, 13), (19, 12), (15, 11), (23, 13), (8, 13)):   # белые хлопья
        s.c.mark(x, y, "#f6ead8")
    for x in range(7, 26, 3):
        s.c.mark(x, 15, "#f0e2cc")


@shroom
def g_enoki(s):
    s.shadow = (CX, BASE + 0.6, 8, 1.8)
    stems = [(13, 10, 5), (19, 10, 27), (14, 6, 10), (18, 6, 22), (16, 3, 16)]
    for (bx, top, ex) in stems:
        line = stroke([(bx, BASE - 1), (bx + (ex - bx) * 0.2, 19), (ex, top + 2)])
        for (x, y) in line:
            s.over.append((x, y, T("#f2ecd8", 1 if y < 20 else 2) + (255,)))
            if (x + 1, y) not in line:
                s.over.append((x + 1, y, T("#f2ecd8", 3) + (255,)))
    for (bx, top, ex) in stems:
        cap = s.c.add(ell(ex + 0.5, top + 1, 2.2, 1.6), "#f6eed6", "dome", shine=True)
    s.c.add(ell(16, 27.6, 4.2, 2.4), "#d8c49c")   # общее основание
    for x in range(13, 20, 2):
        s.c.mark(x, 27, T("#d8c49c", 1))


@shroom
def g_matsutake(s):
    for (a, b) in (((3, 29), (12, 26)), ((5, 30), (13, 29)), ((20, 29), (29, 27)), ((19, 30), (27, 30))):   # хвоинки
        s.c.add(stroke([a, b]), "#a07040", outline=False)
    m = s.stem(CX, 15, 3.6, 3.0, "#f0e6d4")
    for (x, y) in m:     # коричневые волокнистые пояски
        if y > 16 and (y % 4 == 0 or (y % 4 == 1 and x % 2 == 0)):
            s.c.mark(x, y, T("#a07850", 2 if x < CX else 3))
    s.gills(CX, 14.4, 8.8, 1.7, "#f2ead8")
    s.cap(CX, 13.2, 10, 7, "#8a6040", p=2.3, cut=1.2)
    for (x, y) in ((10, 10), (13, 8), (17, 7), (20, 9), (12, 12), (16, 10), (22, 12), (9, 13)):
        s.c.mark(x, y, T("#8a6040", 3)); s.c.mark(x + 1, y, T("#8a6040", 1))


@shroom
def g_sakura_cap(s):
    classic(s, "#f2a6c4", "#faf0f4", "#f8dce8", cy=13, rx=10, ry=7.5, p=2.1, sb=2.4, st=2.0)
    for (cx, cy) in ((12, 9), (19, 8)):         # цветочки сакуры
        for (dx, dy) in ((0, -1), (-1, 0), (1, 0), (-1, 1), (1, 1)):
            s.c.mark(cx + dx, cy + dy, "#fff4f8")
        s.c.mark(cx, cy, "#f8c040")
    for (x, y, c) in ((5, 22, (250, 196, 216, 255)), (25, 24, (246, 180, 206, 255)), (23, 4, (250, 206, 224, 255))):   # лепестки
        s.over.append((x, y, c)); s.over.append((x + 1, y, c))


@shroom
def g_sea_cap(s):
    s.shadow = None
    m = s.c.add(ell(CX, 28, 14, 4), "#e8d4a0")   # песок
    for (x, y) in m:
        if (x * 7 + y * 3) % 5 == 0:
            s.c.mark(x, y, T("#e8d4a0", 3 if x > CX else 1))
    classic(s, "#dcc8a0", "#f2ece0", "#c89a8a", cy=14, rx=9.5, ry=7, p=2.2, sb=2.8, st=2.4)
    s.dots([(12, 10), (18, 9), (15, 12)], T("#dcc8a0", 3))
    sh = s.c.add(ell(25, 26, 2.8, 2.2), "#f4b8a0", "dome", shine=True)   # ракушка
    for (x, y) in ((24, 25), (25, 25), (26, 26), (24, 27)):
        s.c.mark(x, y, T("#f4b8a0", 3))


@shroom
def g_sea_ear(s):
    s.shadow = (CX, BASE + 0.6, 12, 1.8)
    m = s.c.add(tube([(2, 25), (12, 23), (22, 25), (30, 22)], 3.2), "#c8b8a4")   # коряга, выбеленная морем
    for (x, y) in m:
        if (x + y * 2) % 6 == 0:
            s.c.mark(x, y, T("#c8b8a4", 3))
    for (x, y, rx, a) in ((11, 16, 6, -20), (21, 15, 5, 15)):
        e = s.c.add(ell(x, y, rx, rx * 0.85, a), "#8c6a5c", "dome", shine=True)
        for (px, py) in ell(x + 0.8, y + 0.6, rx * 0.55, rx * 0.45, a):
            if (px, py) in e:
                s.c.mark(px, py, T("#8c6a5c", 3))
    s.c.mark(8, 13, "#f0d8c8"); s.dots([(26, 21), (6, 21)], "#a8d0d8")


@shroom
def g_cat_cap(s):
    PINK = "#f2a2c2"
    s.gills(CX, 14.2, 8.5, 1.8, "#fae0ea")
    s.stem(CX, 15, 2.6, 2.2, "#faf0f2")
    # ушки: левое рисуем, правое — точное зеркало (x -> 31 - x)
    ear = poly([(12, 8), (6.5, 1.5), (6.5, 10)])
    inner = poly([(10.2, 7.5), (7.3, 3.5), (7.3, 8)])
    s.c.add(ear | {(31 - x, y) for (x, y) in ear}, PINK)
    m = s.cap(CX, 13, 10, 8.5, PINK, p=2.0, cut=1.0)
    for (x, y) in inner | {(31 - x, y) for (x, y) in inner}:
        if (x, y) not in m:
            s.c.mark(x, y, "#fde4ee")
    for (x, y) in ((15, 6), (15, 7), (12, 7), (12, 8), (11, 9)):   # узор табби «М», зеркально
        for xx in (x, 31 - x):
            if (xx, y) in m:
                s.c.mark(xx, y, T(PINK, 3))
    for (x, y) in ((7, 11), (8, 11)):
        s.c.mark(x, y, T(PINK, 3)); s.c.mark(31 - x, y, T(PINK, 3))
    s.dots([(9, 8)], "#fff0f6")


@shroom
def g_knight_helm(s):
    s.stem(CX, 18, 2.6, 2.2, "#b8b0a4")
    m = s.c.add(ell(CX, 11, 9, 9, p=2.3) - rect(0, 18, 31, 31) | rect(7, 11, 24, 18), "#a8b0bc", "dome", shine=True)
    for x in range(9, 24):      # смотровая щель
        if x != 16:
            s.c.mark(x, 12, "#4a4c60")
    s.c.mark(16, 12, T("#a8b0bc", 3))
    for y in range(4, 18):      # гребень-ребро
        s.c.mark(16, y, T("#a8b0bc", 1) if y < 11 else T("#a8b0bc", 2))
    for (x, y) in ((10, 15), (13, 15), (19, 15), (22, 15)):   # дырочки забрала
        s.c.mark(x, y, T("#a8b0bc", 4))
    s.c.add(tube([(16, 3), (12, 0.5), (8, 2)], 1.6, 0.8), "#d84a4a")    # плюмаж


@shroom
def g_crown_cap(s):
    s.glow = ("#ffe080", 11, CX, 11)
    s.stem(CX, 17, 2.6, 2.2, "#f8eed4")
    band = s.c.add(rect(7, 13, 24, 17), "#f0b830")
    for (x, y) in band:
        s.c.mark(x, y, T("#f0b830", 1 if y == 13 else 3 if y == 17 or x > 21 else 2))
    pts = [(7, 13), (7, 5), (10, 9), (13, 3), (16, 8), (19, 3), (22, 9), (25, 5), (25, 13)]
    s.c.add(poly(pts), "#f4c430", "cel", shine=True)
    for (x, y, c) in ((10, 15, "#e04050"), (16, 15, "#4080e0"), (21, 15, "#40b060")):    # самоцветы
        s.c.mark(x, y, T(c, 1)); s.c.mark(x + 1, y, T(c, 2))
    for (x, y) in ((7, 4), (13, 2), (19, 2), (25, 4)):
        s.over.append((x, y, (255, 246, 200, 255)))
    s.spark(28, 10, "#fff6c0", 1)


@shroom
def g_frost_cap(s):
    s.glow = ("#d0ecff", 12, CX, 12)
    classic(s, "#c4dcf6", "#eef6fc", "#dce8f6", cy=13, rx=10.5, ry=7.5, p=2.2, sb=2.4, st=2.0)
    for (x, y) in ((8, 15), (11, 16), (21, 16), (24, 15)):     # сосульки
        s.over.append((x, y, (230, 246, 255, 255))); s.over.append((x, y + 1, (200, 228, 250, 255)))
    s.over.append((11, 17, (180, 214, 246, 255)))
    for (cx, cy) in ((12, 8), (19, 9)):       # снежинки
        for (dx, dy) in ((0, 0), (1, 0), (-1, 0), (0, 1), (0, -1)):
            s.c.mark(cx + dx, cy + dy, "#ffffff")
    s.spark(26, 5, "#ffffff", 1); s.spark(5, 10, "#e8f8ff", 0)


@shroom
def g_sun_cap(s):
    s.glow = ("#fff0a0", 14, CX, 11)
    for i in range(10):          # лучи
        a = math.radians(i * 36 - 90)
        x0, y0 = CX + math.cos(a) * 12, 11 + math.sin(a) * 10
        x1, y1 = CX + math.cos(a) * 14.5, 11 + math.sin(a) * 12
        if y1 < 18:
            for (x, y) in stroke([(x0, y0), (x1, y1)]):
                s.over.append((x, y, (255, 226, 110, 230)))
    classic(s, "#f8c838", "#fbf2d8", "#f8e4a0", cy=13, rx=10, ry=8, p=2.1, sb=2.4, st=2.0)
    s.c.add(ell(CX, 8.5, 3.5, 2.5), "#ffe680", "dome", shine=True, outline=False)


if __name__ == "__main__":
    ids = sys.argv[1:] or list(REG)
    os.makedirs(OUT, exist_ok=True)
    pairs = []
    for sid in ids:
        if sid in KEEP_OLD:      # старый спрайт 24x24 по центру холста 32x32, низ на месте
            o = Image.open(os.path.join(OLD, "shroom_%s.png" % sid)).convert("RGBA")
            img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
            img.alpha_composite(o, ((W - o.width) // 2, H - o.height - 1))
        else:
            s = Shroom()
            REG[sid](s)
            img = s.render()
        img.save(os.path.join(OUT, "shroom_%s.png" % sid))
        up(img, 8).save(os.path.join(OUT, "shroom_%s_x8.png" % sid))
        oldp = os.path.join(OLD, "shroom_%s.png" % sid)
        old = Image.open(oldp).convert("RGBA") if os.path.exists(oldp) else Image.new("RGBA", (24, 24))
        pairs.append((old, img))
    # лист «было / стало»
    k, cols = 4, 6
    cw = (24 + 32 + 10) * k
    rows = (len(pairs) + cols - 1) // cols
    sheet = Image.new("RGBA", (cols * cw + 8, rows * 36 * k + 8), (236, 226, 200, 255))
    for i, (o, n) in enumerate(pairs):
        x = (i % cols) * cw + 8; y = (i // cols) * 36 * k + 8
        sheet.alpha_composite(up(o, k), (x, y + 8 * k))
        sheet.alpha_composite(up(n, k), (x + 26 * k, y))
    sheet.save(os.path.join(OUT, "..", "shrooms_detail_compare.png"))
    print("готово:", len(pairs))

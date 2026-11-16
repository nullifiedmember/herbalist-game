# -*- coding: utf-8 -*-
"""Детальные зелья «в стиле яблока» (32x32, посуда на всю картинку).
Данные: game/tools/potion_icons.json (основа, цвет, редкость, температура).
  вода — колбы (круглая, коническая, груша), бечёвка с биркой
  спирт — бутылки (квадратная, высокая, фляжка), ярлык с веточкой, сургуч
  воск — стеклянная баночка под тканью с верёвкой / открытая жестянка с крышкой
  мёд — глиняный горшочек под тканью с потёком / кувшинчик с ручкой
  лунная роса — гранёный кристальный флакон с серебряной пробкой
Запуск:  python -I potions_detail.py [id ...]
Выход:   herbalist_game/art_apple/potions_detail/potion_<id>.png (+_x8) и лист potions_detail_compare.png
Старые game/art/potion_*.png НЕ трогает."""
import json, math, os, sys, zlib
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
from apple_engine import Canvas, ramp, hx, ell, tube, stroke, poly, rect, up

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
OLD = os.path.join(ROOT, "backup_potions_20261117")   # старые зелья (для листа сравнения)
OUT = os.path.join(ROOT, "art_apple", "potions_detail")
DATA = os.path.join(ROOT, "game", "tools", "potion_icons.json")
W = H = 32
CX = 16
GLASS = "#cfe6ea"
CORK = "#b98250"
TWINE = "#c8a070"
LINEN = "#f2e8d2"
CLAY = "#c27a48"
TIN = "#a8b0bc"


def T(col, k):
    return ramp(hx(col))[0][max(0, min(4, k))]


def mix(a, b, t):
    a, b = hx(a), hx(b)
    return tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(3))


def hsh(*a):
    return zlib.crc32("|".join(map(str, a)).encode())


def erode(m, k=1):
    for _ in range(k):
        m = {(x, y) for (x, y) in m if all((x + dx, y + dy) in m for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))}
    return m


def rows(m):
    r = {}
    for (x, y) in m:
        r.setdefault(y, []).append(x)
    return r


class Pot:
    def __init__(s):
        s.c = Canvas(W, H)
        s.alpha = {}
        s.over = []
        s.shadow = (CX, 29.6, 9.5, 1.7)

    def add(s, m, col, mode="cel", **kw):
        return s.c.add(m, col, mode, **kw)

    def mark(s, x, y, col):
        s.c.mark(x, y, hx(col) if isinstance(col, str) else col)

    def cyl(s, m, col, lo=1, bottom=True):
        """Объём по строкам: светлый слева, тень справа и снизу."""
        r = rows(m)
        ymax = max(r) if r else 0
        for y, xs in r.items():
            x0, x1 = min(xs), max(xs)
            n = x1 - x0 + 1
            for x in xs:
                f = (x - x0 + 0.5) / n
                t = lo if f < 0.22 else 2 if f < 0.64 else 3 if f < 0.87 else 4
                if bottom and y >= ymax - 1 and t < 4:
                    t += 1
                s.mark(x, y, T(col, t))

    def liquid(s, m, col, bubbles=True, seed=0):
        """Жидкость: объём + светлая поверхность (мениск) + пузырьки."""
        s.add(m, col, outline=False, inner=False)
        s.cyl(m, col)
        r = rows(m)
        if not r:
            return
        top = min(r)
        for x in r[top]:
            s.mark(x, y=top, col=T(col, 0) if x < CX + 3 else T(col, 1))
        if top + 1 in r:
            for x in r[top + 1]:
                if x < CX + 4:
                    s.mark(x, top + 1, T(col, 1))
        if bubbles:
            ys = sorted(r)
            for i in range(3):
                y = ys[min(len(ys) - 1, 3 + (seed >> (i * 3)) % max(1, len(ys) - 5))]
                xs = r[y]
                x = xs[len(xs) // 3 + (seed >> (i * 5)) % max(1, len(xs) // 2)]
                s.mark(x, y, T(col, 0))
                if i == 0 and (x + 1, y - 1) in m:
                    s.mark(x + 1, y - 1, T(col, 1))

    def glass(s, body, liq, col, level, seed=0):
        """Стеклянный сосуд: стекло -> жидкость (на 1 пиксель внутри) -> блики; пустая часть полупрозрачная."""
        s.add(body, GLASS)
        inner = erode(body, 1)
        lq = {(x, y) for (x, y) in inner if y >= level} if liq is None else liq
        s.liquid(lq, col, seed=seed)
        r = rows(body)
        for y, xs in r.items():
            for x in xs:
                if (x, y) not in lq:
                    edge = x == min(xs) or x == max(xs)
                    s.mark(x, y, T(GLASS, 1 if x < CX else 3) if edge else T(GLASS, 0 if x < CX - 2 else 2))
                    s.alpha[(x, y)] = 235 if edge else 120
        # блик: вертикальная полоска слева + точка
        for y, xs in r.items():
            x0, x1 = min(xs), max(xs)
            if x1 - x0 >= 6 and y % 6 != 5:
                s.over.append((x0 + 2, y, (255, 255, 255, 190)))
        ys = sorted(r)
        if len(ys) > 8:
            y = ys[len(ys) // 2 - 1]
            s.over.append((max(r[y]) - 2, y, (255, 255, 255, 150)))
        return lq

    def cork(s, x0, x1, y0, y1, col=CORK):
        m = s.add(rect(x0, y0, x1, y1), col)
        s.cyl(m, col, bottom=False)
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                if (x * 3 + y * 5) % 7 == 0:
                    s.mark(x, y, T(col, 3))
        for x in range(x0, x1 + 1):
            s.mark(x, y0, T(col, 1 if x < x1 - 1 else 2))
        return m

    def twine(s, xa, xb, y, tag_col=None, tag_side=1):
        for x in range(xa, xb + 1):
            s.mark(x, y, T(TWINE, 1 if (x - xa) % 2 == 0 else 2))
        if tag_col:
            x = xb if tag_side > 0 else xa
            for (px, py) in stroke([(x, y), (x + 2 * tag_side, y + 3)]):
                s.over.append((px, py, T(TWINE, 2) + (255,)))
            tx = x + 2 * tag_side - (0 if tag_side > 0 else 3)
            tg = s.add(rect(tx, y + 4, tx + 3, y + 7), LINEN)
            s.cyl(tg, LINEN, bottom=False)
            s.mark(tx + 1, y + 5, T(tag_col, 2)); s.mark(tx + 2, y + 6, T(tag_col, 3))

    def spark(s, x, y, col, size=1):
        s.c.spark(x, y, col, size)

    def render(s):
        img = s.c.render()
        for (xy, a) in s.alpha.items():
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
                    a = 90 if d < 0.45 else 60 if d < 0.8 else (34 if d < 1.0 and (x + y) % 2 == 0 else 0)
                    if a:
                        px[x, y] = (62, 42, 58, a)
        out.alpha_composite(img)
        return out


# ------------------------------------------------------------------ посуда
def neck(x0, x1, y0, y1):
    return rect(x0, y0, x1, y1)


def flask_round(s, col, seed):
    body = ell(CX, 20.5, 10.2, 9.2) | neck(13, 18, 6, 13)
    body |= rect(12, 6, 19, 7)                     # губа горлышка
    s.glass(body, None, col, 14, seed)
    s.cork(13, 18, 2, 6)
    s.twine(13, 18, 9, col, 1)
    return 6


def flask_cone(s, col, seed):
    body = poly([(5, 29.5), (27, 29.5), (19.5, 13), (19, 6), (13, 6), (12.5, 13)])
    body -= {(5, 29), (26, 29), (5, 28), (26, 28), (6, 29), (25, 29)}
    body |= rect(12, 6, 19, 7)
    s.glass(body, None, col, 17, seed)
    s.cork(13, 18, 2, 6)
    s.twine(13, 18, 10, col, -1)
    return 6


def flask_pear(s, col, seed):
    body = ell(CX, 21.5, 9.5, 8.2) | ell(CX, 14, 5.6, 5.5) | neck(13, 18, 5, 11)
    body |= rect(12, 5, 19, 6)
    s.glass(body, None, col, 15, seed)
    s.cork(13, 18, 1, 5)
    s.twine(13, 18, 8, col, 1)
    return 5


def label(s, x0, y0, x1, y1, col, kind):
    m = s.add(rect(x0, y0, x1, y1), LINEN, inner=False)
    s.cyl(m, LINEN, bottom=False)
    for x in range(x0, x1 + 1):
        s.mark(x, y0, T(LINEN, 2)); s.mark(x, y1, T(LINEN, 3))
    cx = (x0 + x1) // 2
    if kind % 3 == 0:          # веточка
        for y in range(y0 + 2, y1):
            s.mark(cx, y, T("#6a9a58", 2))
        for (dx, dy) in ((-1, 2), (1, 3), (-1, 4), (1, 5)):
            if y0 + dy < y1:
                s.mark(cx + dx, y0 + dy, T("#6a9a58", 1))
    elif kind % 3 == 1:        # капля цвета зелья
        for (dx, dy) in ((0, 2), (-1, 3), (0, 3), (1, 3), (-1, 4), (0, 4), (1, 4)):
            if y0 + dy < y1:
                s.mark(cx + dx, y0 + dy, T(col, 1 if dx < 0 else 2 if dx == 0 else 3))
    else:                      # «строчки» надписи
        for (yy, a, b) in ((y0 + 2, x0 + 2, x1 - 2), (y0 + 4, x0 + 2, x1 - 3)):
            if yy < y1:
                for x in range(a, b + 1):
                    s.mark(x, yy, T(col, 3))


def seal(s, x0, x1, y, col):
    """Сургуч поверх пробки с потёком."""
    m = s.add(rect(x0, y, x1, y + 2) | {(x0 + 1, y + 3), (x1 - 1, y + 3), (x1 - 1, y + 4)}, col, inner=False)
    s.cyl(m, col, bottom=False)
    s.mark(x0 + 1, y, T(col, 0))


def bottle_square(s, col, seed):
    body = (ell(CX, 19.5, 8.5, 10, p=4.5) & rect(0, 12, 31, 29)) | poly([(8, 14), (24, 14), (19, 9), (13, 9)]) | neck(13, 18, 4, 9)
    s.glass(body, None, col, 12, seed)
    s.cork(13, 18, 1, 4)
    seal(s, 12, 19, 1, mix(col, "#b03040", 0.55))
    label(s, 11, 19, 20, 25, col, seed)
    return 4


def bottle_tall(s, col, seed):
    body = (ell(CX, 20, 6.5, 10.5, p=5) & rect(0, 12, 31, 29)) | ell(CX, 12, 6.2, 3.2) | neck(14, 17, 2, 11)
    body |= rect(13, 2, 18, 3)
    s.glass(body, None, col, 13, seed)
    s.cork(14, 17, -1, 2)
    seal(s, 13, 18, 0, mix(col, "#b03040", 0.55))
    label(s, 11, 18, 20, 25, col, seed + 1)
    return 2


def bottle_hip(s, col, seed):
    body = ell(CX, 20, 10.5, 9.5, p=3.2) | neck(13, 18, 5, 11)
    body |= rect(12, 5, 19, 6)
    s.glass(body, None, col, 15, seed)
    s.cork(13, 18, 1, 5)
    # кожаный ремешок поперёк
    for x in range(6, 27):
        for y in (22, 23):
            if (x, y) in body:
                s.mark(x, y, T("#8a5a3a", 2 if y == 22 else 3))
    s.mark(16, 22, T("#e8c060", 1)); s.mark(17, 22, T("#e8c060", 2))
    return 5


def wax_jar(s, col, seed):
    body = ell(CX, 21, 9.5, 8.8, p=4)
    s.glass(body, {(x, y) for (x, y) in erode(body) if y >= 15}, col, 15, seed)
    # мазь: завиток на поверхности
    for (x, y) in ((12, 16), (13, 15), (15, 15), (16, 16), (18, 15)):
        s.mark(x, y, T(col, 0))
    # ткань-крышка
    cloth = ell(CX, 12, 11, 3.4) | {(x, y) for x in range(5, 27) for y in range(12, 16) if y < 15 + (1 if (x // 2) % 2 == 0 else 0)}
    s.add(cloth, LINEN)
    for (x, y) in cloth:
        t = 1 if y <= 10 else 2 if x < 22 else 3
        if y >= 14:
            t = 3
        if (x + y) % 4 == 0 and y > 10:
            t = min(4, t + 1)
        s.mark(x, y, T(LINEN, t))
    # клетка цвета зелья на ткани
    for (x, y) in cloth:
        if (x % 4 == 0 or y == 12) and y > 9:
            s.mark(x, y, T(col, 2 if x < 22 else 3))
    s.twine(6, 25, 15, None)
    s.over.append((25, 16, T(TWINE, 2) + (255,))); s.over.append((26, 17, T(TWINE, 3) + (255,)))
    s.over.append((24, 17, T(TWINE, 2) + (255,)))
    return 9


def wax_tin(s, col, seed):
    s.shadow = (CX, 29.6, 12, 1.8)
    # крышка, прислонённая сзади
    lid = s.add(ell(21, 13, 8, 7.5), TIN, "dome", shine=True)
    for (x, y) in lid:          # выпуклый ободок крышки
        d = math.hypot((x + 0.5 - 21) / 8, (y + 0.5 - 13) / 7.5)
        if 0.66 < d < 0.8:
            s.mark(x, y, T(TIN, 3) if x + y > 34 else T(TIN, 0))
    for (x, y) in ((20, 11), (21, 12), (22, 13), (21, 14), (20, 13)):     # выбитый листик цвета зелья
        s.mark(x, y, T(col, 2))
    # банка
    side = s.add(ell(14, 25, 11, 4.5) | rect(3, 20, 25, 25), TIN)
    s.cyl(side, TIN)
    top = s.add(ell(14, 20, 11, 3.6), TIN)
    for (x, y) in top:
        s.mark(x, y, T(TIN, 1))
    oint = s.add(ell(14, 20.2, 9.8, 2.7), col, inner=False, outline=False)
    for (x, y) in oint:
        s.mark(x, y, T(col, 1 if x < 12 else 2 if x < 19 else 3))
    for (x, y) in ((10, 20), (11, 19), (13, 19), (14, 20), (16, 20), (17, 19)):   # след пальца
        s.mark(x, y, T(col, 0))
    s.mark(18, 21, T(col, 3)); s.mark(12, 21, T(col, 3))
    for x in range(4, 25, 3):
        s.mark(x, 24, T(TIN, 3))
    return 9


def honey_pot(s, col, seed):
    body = ell(CX, 21, 10.5, 8.5, p=2.3) | ell(CX, 13.5, 6.5, 2.2) | rect(10, 11, 21, 14)
    m = s.add(body, CLAY)
    s.cyl(m, CLAY)
    for x in range(7, 26):         # поясок-узор
        if (x, 21) in m:
            s.mark(x, 21, T(CLAY, 3)); s.mark(x, 22, T("#f0d8a8", 1 if x < 18 else 2) if x % 2 == 0 else T(CLAY, 3))
    # ткань цвета зелья сверху + верёвочка
    cloth = ell(CX, 11, 8.5, 3) | {(x, y) for x in range(8, 24) for y in range(11, 15) if y < 14 + (1 if x % 3 == 0 else 0)}
    s.add(cloth, col)
    for (x, y) in cloth:
        s.mark(x, y, T(col, 1 if y <= 9 else 2 if x < 20 else 3))
    for (x, y) in cloth:
        if (x + y) % 3 == 0 and y > 9:
            s.mark(x, y, T(col, 0 if x < 14 else 2))
    s.twine(9, 22, 13, None)
    # потёк сиропа по боку
    sy = mix(col, "#f0a830", 0.35)
    for y in range(15, 22):
        s.mark(20, y, T(sy, 1 if y < 18 else 2))
    for y in range(15, 19):
        s.mark(21, y, T(sy, 2))
    s.mark(20, 22, T(sy, 2)); s.mark(20, 23, T(sy, 3))
    s.mark(9, 18, T(CLAY, 0)); s.mark(10, 17, T(CLAY, 0))
    return 8


def honey_jug(s, col, seed):
    body = ell(15, 21.5, 9, 8, p=2.2) | rect(11, 8, 19, 14) | ell(15, 8, 5, 1.6)
    s.add(tube([(21, 10), (28, 12), (26, 21), (21, 22)], 1.3), CLAY)         # ручка
    m = s.add(body, CLAY)
    s.cyl(m, CLAY)
    s.add(poly([(9, 7), (11, 9), (8.5, 9.5)]), CLAY)                     # носик
    top = ell(15, 8, 4, 1.2)
    sy = mix(col, "#f0a830", 0.3)
    for (x, y) in top:
        s.mark(x, y, T(sy, 1 if x < 16 else 3))
    for x in range(8, 23):           # глазурь цвета зелья по верху
        for y in range(10, 15):
            if (x, y) in m:
                s.mark(x, y, T(col, 1 if x < 13 else 2 if x < 18 else 3))
    for x in range(7, 24):
        if (x, 15) in m and x % 2 == 0:
            s.mark(x, 15, T(col, 3))
    for y in range(9, 14):           # капля из носика
        pass
    s.over.append((8, 10, T(sy, 1) + (255,))); s.over.append((8, 11, T(sy, 2) + (255,)))
    s.mark(9, 18, T(CLAY, 0)); s.mark(10, 17, T(CLAY, 0))
    return 7


def crystal(s, col, seed, tall=False):
    if tall:
        body = poly([(10, 12), (22, 12), (23, 15), (23, 26), (16, 30), (9, 26), (9, 15)])
    else:
        body = poly([(16, 9), (27, 18), (16, 30), (5, 18)])
    s.add(body, mix(col, "#e8f4ff", 0.25))
    lq = erode(body, 1)
    s.add(lq, col, outline=False, inner=False)
    # грани
    for (x, y) in lq:
        u = x + 0.5 - CX
        if tall:
            face = 0 if u < -3.5 else 1 if u < 0 else 2 if u < 3.5 else 3
            t = (1, 0, 2, 3)[face] if y < 25 else (2, 1, 3, 4)[face]
        else:
            v = y + 0.5 - 18
            t = 0 if (u < 0 and v < 0) else 2 if (u >= 0 and v < 0) else 1 if u < 0 else 3
            if abs(u) < 0.6:
                t = 1
        s.mark(x, y, T(col, t))
    r = rows(body)
    for y, xs in r.items():         # кромки граней светлые
        x0 = min(xs)
        s.mark(x0, y, T(mix(col, "#ffffff", 0.5), 1))
    s.over.append((12 if not tall else 11, 16, (255, 255, 255, 230)))
    s.over.append((12 if not tall else 11, 17, (255, 255, 255, 160)))
    # серебряная пробка-капелька
    top = 9 if not tall else 12
    ring = s.add(rect(13, top - 2, 18, top - 1), "#c8d0e8")
    s.cyl(ring, "#c8d0e8", bottom=False)
    st = s.add(ell(15.5, top - 5, 2.6, 3), "#d8def0", "dome", shine=True)
    s.over.append((15, top - 9, (255, 255, 255, 255)))
    return top - 8


SHAPES = {
    "water": [flask_round, flask_cone, flask_pear],
    "spirit": [bottle_square, bottle_tall, bottle_hip],
    "wax": [wax_jar, wax_tin],
    "honey": [honey_pot, honey_jug],
    "moon_dew": [lambda s, c, sd: crystal(s, c, sd), lambda s, c, sd: crystal(s, c, sd, tall=True)],
}


def draw(pid, d):
    s = Pot()
    col = "#" + d["col"]
    seed = hsh(pid)
    sh = SHAPES[d["base"]]
    fn = sh[hsh(pid, "shape") % len(sh)]
    top = fn(s, col, seed)
    rar = int(d["rarity"])
    temp = d["temp"]
    if rar >= 3:     # золотой ободок/пробка
        for c in s.c.shapes:
            if c["color"] in (hx(CORK), hx("#d8def0"), hx("#c8d0e8")):
                c["color"] = hx("#f0c040")
    if temp == "cold":
        for (x, y) in ((5, 27), (6, 28), (25, 26), (26, 28), (7, 29), (24, 29), (4, 25)):
            s.over.append((x, y, (232, 248, 255, 255)))
        s.spark(27, 23, "#e8f8ff", 0); s.spark(4, 21, "#e8f8ff", 0)
    elif temp == "hot":
        for (x, y, a) in ((13, top - 2, 200), (12, top - 3, 170), (13, top - 4, 140), (19, top - 1, 190), (20, top - 2, 160), (19, top - 3, 120)):
            if y >= 0:
                s.over.append((x, y, (246, 246, 250, a)))
    elif temp == "warm":
        s.over.append((20, max(0, top - 1), (250, 240, 230, 150))); s.over.append((21, max(0, top - 2), (250, 240, 230, 110)))
    if rar >= 1:
        gc = "#fff0a0" if rar >= 3 else "#e0c8ff" if rar == 2 else "#d0eaff"
        pts = [(27, 8), (4, 13), (28, 18), (5, 22), (23, 3)][: rar + 1 if rar < 3 else 5]
        for i, (x, y) in enumerate(pts):
            s.spark(x, y, gc, 1 if i == 0 or rar >= 2 else 0)
    return s.render()


if __name__ == "__main__":
    data = json.load(open(DATA, encoding="utf-8"))
    ids = sys.argv[1:] or list(data)
    os.makedirs(OUT, exist_ok=True)
    pairs = []
    for pid in ids:
        img = draw(pid, data[pid])
        img.save(os.path.join(OUT, "potion_%s.png" % pid))
        up(img, 8).save(os.path.join(OUT, "potion_%s_x8.png" % pid))
        op = os.path.join(OLD, "potion_%s.png" % pid)
        old = Image.open(op).convert("RGBA") if os.path.exists(op) else Image.new("RGBA", (32, 32))
        pairs.append((old, img))
    k, cols = 3, 8
    cw = (32 + 32 + 10) * k
    rws = (len(pairs) + cols - 1) // cols
    sheet = Image.new("RGBA", (cols * cw + 8, rws * 36 * k + 8), (236, 226, 200, 255))
    for i, (o, n) in enumerate(pairs):
        x = (i % cols) * cw + 8; y = (i // cols) * 36 * k + 8
        sheet.alpha_composite(up(o, k), (x, y))
        sheet.alpha_composite(up(n, k), (x + 34 * k, y))
    sheet.save(os.path.join(OUT, "..", "potions_detail_compare.png"))
    print("готово:", len(pairs))

# -*- coding: utf-8 -*-
"""v31: подробный фон окна сумки (inventory_ui.gd) в стиле яблока.
Картинка 384x520, в игре рисуется ×2 (768x1040) — места совпадают с раскладкой окна:
  резная рама с латунными уголками и вьюнком, пергамент с фактурой и тенью к краям,
  табличка на верёвках, пучки лаванды и мяты, рисунки трав чернилами в пустых местах,
  кожаный пояс под ячейками зелий, записка с булавкой под свойства, деревянный лоток под сетку.
Запуск: python -I tools/ui31_inv.py  (из папки game)
"""
import math
import os
import random
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ART = os.path.join(HERE, "..", "art")
PREV = os.path.join(HERE, "..", "..", "screenshots")
W, H = 384, 520
K = 2          # пиксель картинки = 2 пикселя экрана
XO = 32        # сдвиг слотов в inventory_ui.gd


def hx(s):
    s = s.lstrip("#")
    return (int(s[0:2], 16), int(s[2:4], 16), int(s[4:6], 16), 255)


T = (0, 0, 0, 0)
WOOD = dict(o=hx("6e4636"), hi=hx("ecc48e"), lt=hx("d9a873"), md=hx("bf8a58"), dk=hx("9c6a48"), dd=hx("845a40"))
BRASS = dict(o=hx("7a4a2c"), hi=hx("fff0b8"), lt=hx("ffd978"), md=hx("f0b44c"), dk=hx("cf8a3a"))
LEAF = dict(o=hx("3f6a4a"), lt=hx("a8d47a"), md=hx("74b05a"), dk=hx("4f8a4c"), st=hx("5a7a3a"))
PAPER = [hx("e9d4ac"), hx("f1e0bd"), hx("f6e9cc"), hx("fbf1dc")]   # тень → свет
EDGE = [hx("dcc297"), hx("e6cfa6")]
INK = hx("c4a47c")        # бледные чернила рисунков
INK2 = hx("b08e66")
LEATHER = dict(o=hx("5e3a2c"), lt=hx("b07650"), md=hx("94603e"), dk=hx("7a4c32"), st=hx("e8cfa0"))

rnd = random.Random(31)
im = Image.new("RGBA", (W, H), T)
px = im.load()


def put(x, y, c):
    if 0 <= x < W and 0 <= y < H:
        px[x, y] = c


# ------------------------------------------------------------- пергамент
def value_noise(seed, cell):
    r = random.Random(seed)
    gw, gh = W // cell + 2, H // cell + 2
    g = [[r.random() for _ in range(gw)] for _ in range(gh)]

    def f(x, y):
        gx, gy = x / cell, y / cell
        x0, y0 = int(gx), int(gy)
        tx, ty = gx - x0, gy - y0
        tx = tx * tx * (3 - 2 * tx)
        ty = ty * ty * (3 - 2 * ty)
        a = g[y0][x0] * (1 - tx) + g[y0][x0 + 1] * tx
        b = g[y0 + 1][x0] * (1 - tx) + g[y0 + 1][x0 + 1] * tx
        return a * (1 - ty) + b * ty
    return f


n1 = value_noise(1, 22)
n2 = value_noise(2, 7)
BAYER = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]
FR = 9    # толщина рамы
for y in range(H):
    for x in range(W):
        v = n1(x, y) * 0.7 + n2(x, y) * 0.3
        d = min(x, y, W - 1 - x, H - 1 - y) - FR
        v -= max(0.0, (14 - d) / 14.0) * 0.45            # тень к краям
        v += (BAYER[y % 4][x % 4] / 16.0 - 0.5) * 0.16     # мягкий пиксельный дизеринг
        i = 0 if v < 0.28 else (1 if v < 0.45 else (2 if v < 0.68 else 3))
        px[x, y] = PAPER[i]
# волокна бумаги
for _ in range(260):
    x, y = rnd.randrange(FR, W - FR), rnd.randrange(FR, H - FR)
    L = rnd.randint(2, 4)
    c = PAPER[0] if rnd.random() < 0.6 else PAPER[3]
    for k in range(L):
        put(x + k, y, c)
# два бледных «чайных» кружка
for (cx, cy, r) in [(28, 455, 8)]:
    for a in range(0, 360, 4):
        if rnd.random() < 0.8:
            put(int(cx + r * math.cos(math.radians(a))), int(cy + r * math.sin(math.radians(a)) * 0.9), EDGE[1])


# ------------------------------------------------------------- рисунки чернилами
def line(x0, y0, x1, y1, c, dash=0):
    n = int(max(abs(x1 - x0), abs(y1 - y0))) + 1
    for i in range(n):
        if dash and (i // dash) % 2:
            continue
        t = i / max(n - 1, 1)
        put(round(x0 + (x1 - x0) * t), round(y0 + (y1 - y0) * t), c)


def curve(pts, c, steps=60):
    out = []
    for i in range(steps + 1):
        t = i / steps
        # квадратичная/кубическая Безье
        p = list(pts)
        while len(p) > 1:
            p = [(p[j][0] + (p[j + 1][0] - p[j][0]) * t, p[j][1] + (p[j + 1][1] - p[j][1]) * t) for j in range(len(p) - 1)]
        q = (round(p[0][0]), round(p[0][1]))
        if not out or out[-1] != q:
            out.append(q)
            put(q[0], q[1], c)
    return out


def fern(x, y, h, lean=1):
    stem = curve([(x, y + h), (x + 4 * lean, y + h * 0.5), (x + 9 * lean, y)], INK2)
    for i, (sx, sy) in enumerate(stem[4::4]):
        L = max(2, int(9 * (1 - i / (len(stem) / 4 + 1))))
        line(sx, sy, sx - L, sy - L // 2, INK)
        line(sx, sy, sx + L, sy - L // 2, INK)


def chamomile(x, y):
    curve([(x, y + 34), (x - 3, y + 18), (x, y)], INK2)
    curve([(x - 1, y + 22), (x - 8, y + 18), (x - 12, y + 20)], INK)
    for a in range(0, 360, 30):
        ca, sa = math.cos(math.radians(a)), math.sin(math.radians(a))
        line(x + round(ca * 3), y + round(sa * 3), x + round(ca * 7), y + round(sa * 7), INK)
    for dx in (-1, 0, 1):
        for dy in (-1, 0, 1):
            put(x + dx, y + dy, INK2)


def mushroom(x, y):
    for xx in range(-11, 12):
        top = int(9 * math.sqrt(max(0.0, 1 - (xx / 11.5) ** 2)))
        put(x + xx, y - top, INK2)
        if abs(xx) < 10 and xx % 3 == 0:
            put(x + xx, y - top // 2, INK)
    line(x - 11, y, x + 11, y, INK2)
    line(x - 3, y + 1, x - 4, y + 16, INK2)
    line(x + 3, y + 1, x + 4, y + 16, INK2)
    line(x - 5, y + 16, x + 5, y + 16, INK2)
    for (sx, sy) in [(x - 6, y - 5), (x + 2, y - 7), (x + 7, y - 3)]:
        put(sx, sy, INK2)
        put(sx + 1, sy, INK2)


def sprig(x, y):
    st = curve([(x, y + 30), (x + 6, y + 15), (x + 2, y)], INK2)
    for i, (sx, sy) in enumerate(st[3::5]):
        s = 1 if i % 2 else -1
        for k in range(1, 6):
            put(sx + s * k, sy - k // 2 - (1 if k in (2, 3, 4) else 0), INK)
            put(sx + s * k, sy - k // 2 + (1 if k in (2, 3) else 0), INK)


# v31b: вместо рисунков чернилами — гербарий: засушенные растения (tools/ui31_herbarium.py),
# приклеенные полосками бумажной ленты, с лёгкой тенью на бумаге
import sys as _sys  # noqa: E402
_sys.path.insert(0, HERE)
from ui31_herbarium import specimens  # noqa: E402


def blend(c, d, k):
    return (int(c[0] + (d[0] - c[0]) * k), int(c[1] + (d[1] - c[1]) * k), int(c[2] + (d[2] - c[2]) * k), 255)


def paste_specimen(sp, x0, y0):
    sp_px = sp.load()
    # тень: силуэт со сдвигом вниз-вправо, чуть темнее бумаги
    for y in range(sp.height):
        for x in range(sp.width):
            if sp_px[x, y][3] and 0 <= x0 + x + 1 < W and 0 <= y0 + y + 1 < H:
                px[x0 + x + 1, y0 + y + 1] = blend(px[x0 + x + 1, y0 + y + 1], (190, 160, 120), 0.35)
    for y in range(sp.height):
        for x in range(sp.width):
            if sp_px[x, y][3]:
                put(x0 + x, y0 + y, sp_px[x, y])


def tape(cx, cy, w=11, h=4, lean=1):
    """Полоска бумажной ленты наискосок: полупрозрачная, рваные концы."""
    for j in range(h):
        for i in range(w):
            x = cx - w // 2 + i + (j if lean > 0 else -j) - h // 2
            y = cy - h // 2 + j
            if (i == 0 or i == w - 1) and (j % 2 == 1):
                continue                                   # рваный край
            if 0 <= x < W and 0 <= y < H:
                edge = j in (0, h - 1)
                px[x, y] = blend(px[x, y], (252, 246, 228), 0.55 if not edge else 0.4)
                if j == h - 1:
                    put(x + 1, y + 1, blend(px[x + 1, y + 1] if 0 <= x + 1 < W and 0 <= y + 1 < H else PAPER[2], (200, 172, 130), 0.25))


SP = specimens()
paste_specimen(SP["fern"], 117, 60)          # между основной рукой и шляпой
tape(134, 118, 13, 4, 1)
paste_specimen(SP["chamomile"], 238, 52)     # справа от шляпы
tape(253, 96, 11, 4, -1)
paste_specimen(SP["maple"], 32, 198)         # под основной рукой, слева от перчаток
tape(50, 226, 11, 4, 1)
paste_specimen(SP["lavender"], 318, 186)     # справа от сапог
tape(330, 228, 11, 4, -1)



# ------------------------------------------------------------- кожаный пояс под зельями
def belt(x0, x1, y0):
    for y in range(y0, y0 + 11):
        for x in range(x0, x1):
            if y in (y0, y0 + 10):
                c = LEATHER["o"]
            elif y == y0 + 1:
                c = LEATHER["lt"]
            elif y == y0 + 9:
                c = LEATHER["dk"]
            else:
                c = LEATHER["md"]
            if y in (y0 + 2, y0 + 8) and (x // 2) % 2 == 0:
                c = LEATHER["st"]          # строчка
            put(x, y, c)
    # закруглённый конец справа
    for y in range(y0, y0 + 11):
        put(x1, y, LEATHER["o"] if y in (y0 + 1, y0 + 9) else (T if y in (y0, y0 + 10) else LEATHER["dk"]))
        put(x1 + 1, y, LEATHER["o"] if y0 + 2 <= y <= y0 + 8 else T)
    # пряжка
    bx = x0 - 6
    for y in range(y0 - 3, y0 + 14):
        for x in range(bx, bx + 9):
            edge = x in (bx, bx + 8) or y in (y0 - 3, y0 + 13)
            inner = bx + 2 <= x <= bx + 6 and y0 <= y <= y0 + 10
            if edge:
                put(x, y, BRASS["o"])
            elif inner:
                put(x, y, LEATHER["md"] if y0 + 1 < y < y0 + 9 else LEATHER["o"])
            else:
                put(x, y, BRASS["hi"] if (x == bx + 1 or y == y0 - 2) else BRASS["md"])
    for y in range(y0 + 2, y0 + 9):
        put(bx + 4, y, BRASS["dk"])        # язычок


def bandolier(x0, y0, x1, y1):
    """Кожаная перевязь для зелий: подложка со строчкой, ремешки сверху и снизу каждой ячейки."""
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            d = min(x - x0, y - y0, x1 - x, y1 - y)
            if d == 0:
                c = LEATHER["o"]
            elif d == 1:
                c = LEATHER["lt"] if (y - y0 == 1 or x - x0 == 1) else LEATHER["dk"]
            elif d == 3 and ((x + y) // 2) % 2 == 0:
                c = LEATHER["st"]
            else:
                c = LEATHER["md"]
            if (x - x0 < 1 or x1 - x < 1) and (y - y0 < 1 or y1 - y < 1):
                c = T
            put(x, y, c)
    # заклёпки по углам
    for (x, y) in [(x0 + 3, y0 + 3), (x1 - 3, y0 + 3), (x0 + 3, y1 - 3), (x1 - 3, y1 - 3)]:
        put(x, y, BRASS["lt"])
        put(x + 1, y, BRASS["dk"])
        put(x, y + 1, BRASS["dk"])


bandolier(113, 254, 266, 321)


# ------------------------------------------------------------- записка с булавкой под свойства
def note(x0, y0, x1, y1):
    """Листок из тетради травницы: линейка, красное поле, рваный верх, загнутый уголок, булавка, клевер."""
    nr = random.Random(5)
    tear = [nr.choice([0, 0, 1, 1, 2]) for _ in range(x1 - x0)]   # рваный верхний край
    paper, paper2, line_c, margin_c, edge = hx("fff6e2"), hx("fbeed3"), hx("c6d6dc"), hx("e8a0a0"), hx("d8bf92")
    for x in range(x0, x1):
        for y in range(y0 + tear[x - x0], y1):
            fx, fy = x1 - 1 - x, y1 - 1 - y
            if fx + fy < 7:
                continue                                   # место под загнутый уголок
            c = paper if (x * 7 + y * 3) % 11 else paper2  # лёгкая неровность бумаги
            if y == y0 + tear[x - x0]:
                c = hx("fffbee")                           # светлая кромка надрыва
            elif x == x0 or x == x1 - 1 or y == y1 - 1:
                c = edge
            elif y >= RULE0 and (y - RULE0) % 11 == 0:
                c = line_c                                 # линейка: шаг 11 = строка текста (22 px), буквы стоят на ней
            elif x == x0 + 8:
                c = margin_c                               # поле
            put(x, y, c)
    # загнутый уголок: отогнутый треугольник лежит на листе, оборот темнее, кромки цвета края
    for fx in range(0, 7):
        for fy in range(0, 7):
            x, y = x1 - 1 - fx, y1 - 1 - fy
            if fx + fy == 7:
                put(x, y, edge)                            # линия сгиба
            elif 7 < fx + fy <= 12 and (fx == 6 or fy == 6):
                put(x, y, hx("c9ab7e"))                    # край отогнутого клапана
            elif 7 < fx + fy <= 12:
                put(x, y, hx("ecd8b0") if fx > fy else hx("e2cba0"))
    # тень листка на бумаге
    for x in range(x0 + 2, x1 - 6):
        put(x, y1, blend(px[x, y1], (190, 160, 120), 0.3))
    for y in range(y0 + 3, y1 - 6):
        put(x1, y, blend(px[x1, y], (190, 160, 120), 0.3))
    # булавка
    cx = (x0 + x1) // 2
    for (dx, dy, c) in [(0, -1, hx("8a3038")), (-1, 0, hx("d8505a")), (0, 0, hx("f07a6e")), (1, 0, hx("b03c4a")),
                        (0, 1, hx("b03c4a")), (-1, -1, hx("8a3038")), (1, -1, hx("8a3038")), (-1, 1, hx("8a3038")),
                        (1, 1, hx("8a3038")), (-2, 0, hx("8a3038")), (2, 0, hx("8a3038")), (0, -2, hx("8a3038")),
                        (0, 2, hx("8a3038"))]:
        put(cx + dx, y0 + 2 + dy, c)
    put(cx - 1, y0 + 1, hx("ffb0a0"))
    put(cx + 2, y0 + 4, blend(px[cx + 2, y0 + 4], (190, 160, 120), 0.4))


def blend(c, d, k):
    return (int(c[0] + (d[0] - c[0]) * k), int(c[1] + (d[1] - c[1]) * k), int(c[2] + (d[2] - c[2]) * k), 255)


RULE0 = 268    # первая линейка: текст свойств начинается с y=520 px, линия письма шрифта — 16 px ниже
note(272, 252, 366, 318)


# ------------------------------------------------------------- разделитель над сеткой
def divider(x0, x1, y):
    for x in range(x0, x1):
        put(x, y, WOOD["dk"])
        put(x, y + 1, PAPER[3])
    mid = (x0 + x1) // 2
    pat = ["..oo..", ".oLMo.", "oLMMDo", ".oMDo.", "..oo.."]
    cm = {"o": LEAF["o"], "L": LEAF["lt"], "M": LEAF["md"], "D": LEAF["dk"]}
    for j, row in enumerate(pat):
        for i, ch in enumerate(row):
            if ch != ".":
                put(mid - 3 + i, y - 2 + j, cm[ch])
    for s in (-1, 1):
        put(mid + s * 8, y - 1, WOOD["dk"])
        put(mid + s * 8, y + 1, WOOD["dk"])
        put(mid + s * 9, y, PAPER[0])


divider(20, 276, 325)


# ------------------------------------------------------------- деревянный лоток под сеткой
def tray(x0, y0, x1, y1):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            d = min(x - x0, y - y0, x1 - x, y1 - y)
            if d > 3:
                continue
            if (x - x0 < 1 or x1 - x < 1) and (y - y0 < 1 or y1 - y < 1):
                continue
            lit = (y - y0 <= 3 and y - y0 <= x1 - x) or (x - x0 <= 3 and x - x0 <= y1 - y)
            if d == 0:
                c = WOOD["o"]
            elif d == 1:
                c = WOOD["hi"] if lit else WOOD["dk"]
            elif d == 2:
                c = WOOD["lt"] if lit else WOOD["dd"]
            else:
                c = WOOD["o"]
            put(x, y, c)


tray(12, 328, 371, 489)


# ------------------------------------------------------------- резная рама
def rr_in(x, y, ins, r):
    x0, y0, x1, y1 = ins, ins, W - 1 - ins, H - 1 - ins
    if x < x0 or y < y0 or x > x1 or y > y1:
        return False
    prof = {0: [], 1: [1], 2: [2, 1], 3: [3, 1, 1], 4: [4, 2, 1, 1]}[max(0, r)]
    dy = min(y - y0, y1 - y)
    dx = min(x - x0, x1 - x)
    return not (dy < len(prof) and dx < prof[dy])


grain = {}
for _ in range(220):
    # прожилки: вдоль верха/низа — горизонтальные, вдоль боков — вертикальные
    if rnd.random() < 0.5:
        x, y = rnd.randrange(4, W - 4), rnd.choice([rnd.randrange(2, 7), rnd.randrange(H - 7, H - 2)])
        for k in range(rnd.randint(4, 12)):
            grain[(x + k, y)] = 1
    else:
        x, y = rnd.choice([rnd.randrange(2, 7), rnd.randrange(W - 7, W - 2)]), rnd.randrange(4, H - 4)
        for k in range(rnd.randint(4, 12)):
            grain[(x, y + k)] = 1

for y in range(H):
    for x in range(W):
        if not rr_in(x, y, 0, 4):
            px[x, y] = T
            continue
        if rr_in(x, y, FR, 1):
            continue
        d = min(x, y, W - 1 - x, H - 1 - y)
        s = min((y, "t"), (x, "l"), (H - 1 - y, "b"), (W - 1 - x, "r"))[1]
        lit = s in ("t", "l")
        if not rr_in(x, y, 1, 3):
            c = WOOD["o"]
        elif d == 1:
            c = WOOD["hi"] if lit else WOOD["dk"]
        elif d == 7:
            c = WOOD["dd"]                       # внутренняя кромка
        elif d == 8:
            c = WOOD["o"]                        # шов с пергаментом
        elif d in (3, 4) and (x + y) % 2 == 0 and False:
            c = WOOD["md"]
        else:
            c = WOOD["lt"] if (lit and d == 2) else WOOD["md"]
            if (x, y) in grain:
                c = WOOD["dk"] if lit else WOOD["dd"]
        # резной желобок посередине рамы
        if d == 5:
            c = WOOD["dk"] if lit else WOOD["dd"]
        if d == 6:
            c = WOOD["hi"] if not lit else WOOD["lt"]
        px[x, y] = c
# тень от рамы на пергаменте
for y in range(H):
    for x in range(W):
        d = min(x, y, W - 1 - x, H - 1 - y)
        if d == FR and (y == FR or x == FR):
            px[x, y] = EDGE[0]
        elif d == FR + 1 and (y == FR + 1 or x == FR + 1):
            px[x, y] = EDGE[1]


# латунные уголки с листом
def plate(x0, y0, fx, fy):
    pat = [
        "ooooooooooo.",
        "oHHHHHHHHHo.",
        "oHLLLLLLLMDo",
        "oHLnLLgLLMDo",
        "oHLLLggGLMDo",
        "oHLLgGGgLMDo",
        "oHLLLgGLLMDo",
        "oHLgLLLLnMDo",
        "oHLLLLLLLMDo",
        "oHMMMMMMMMDo",
        "ooDDDDDDDDDo",
        ".ooooooooooo",
    ]
    cm = {"o": BRASS["o"], "H": BRASS["hi"], "L": BRASS["lt"], "M": BRASS["md"], "D": BRASS["dk"],
          "g": hx("cf8a3a"), "G": hx("b06e32"), "n": hx("fff8d8")}
    n = len(pat) - 1
    for j, row in enumerate(pat):
        for i, ch in enumerate(row):
            if ch == ".":
                continue
            xx = x0 + (n - i if fx else i)
            yy = y0 + (n - j if fy else j)
            c = cm[ch]
            if fx and ch in "HD":
                c = cm["D" if ch == "H" else "H"] if False else c
            put(xx, yy, c)


plate(1, 1, False, False)
plate(W - 13, 1, True, False)
plate(1, H - 13, False, True)
plate(W - 13, H - 13, True, True)


# вьюнок по раме: стебель, листья, цветочки
def vine(path, flowers):
    pts = curve(path, LEAF["st"], steps=160)
    for i, (x, y) in enumerate(pts):
        put(x, y + 1, LEAF["o"])
        if i % 9 == 4:
            s = 1 if (i // 9) % 2 else -1
            for (dx, dy, c) in [(1, s, LEAF["o"]), (2, s, LEAF["md"]), (3, s, LEAF["lt"]), (2, 2 * s, LEAF["o"]),
                                (3, 2 * s, LEAF["md"]), (4, s, LEAF["o"]), (3, 0, LEAF["o"]), (4, 2 * s, LEAF["o"]),
                                (2, 0, LEAF["dk"])]:
                put(x + dx, y + dy, c)
    for k in flowers:
        x, y = pts[k]
        pink, pk2, ctr = hx("f4a8b8"), hx("e07a94"), hx("ffe08a")
        for (dx, dy, c) in [(0, -2, pink), (-2, 0, pink), (2, 0, pk2), (0, 2, pk2), (-1, -1, pink), (1, -1, pink),
                            (-1, 1, pk2), (1, 1, pk2), (0, 0, ctr), (0, -3, hx("a8506a")), (-3, 0, hx("a8506a")),
                            (3, 0, hx("a8506a")), (0, 3, hx("a8506a"))]:
            put(x + dx, y + dy, c)


vine([(12, 4), (40, 1), (70, 7), (110, 3)], [30, 95])
vine([(4, 12), (1, 50), (7, 90), (3, 130)], [40, 110])
vine([(W - 12, H - 4), (W - 50, H - 1), (W - 90, H - 7), (W - 130, H - 3)], [35, 100])
vine([(W - 4, H - 12), (W - 1, H - 50), (W - 7, H - 80), (W - 3, H - 112)], [60])


# ------------------------------------------------------------- табличка на верёвках и пучки трав
def rope(x, y0, y1):
    for y in range(y0, y1):
        put(x, y, hx("c9a27a") if y % 3 else hx("8a6440"))
        put(x + 1, y, hx("a87c54"))
    for (dx, dy) in [(0, 0), (1, 0), (0, 1), (1, 1)]:
        put(x + dx, y0 - 2 + dy, BRASS["md"] if dy == 0 else BRASS["dk"])


rope(134, 9, 17)
rope(249, 9, 17)


def bundle(x, y, kind):
    """Пучок трав вверх ногами на бечёвке (15x34): лаванда — колоски, мята — листья."""
    rope(x + 7, FR, y)
    for s_ in range(7):                                  # стебли расходятся веером вниз
        sx = x + 4 + s_
        for k in range(0, 14):
            put(sx + (k * (s_ - 3)) // 9, y + 2 + k, LEAF["st"] if s_ % 2 else LEAF["dk"])
    for dx in range(-1, 12):                             # перевязь с бантиком
        put(x + 2 + dx, y + 3, hx("d9b88a"))
        put(x + 2 + dx, y + 4, hx("8a6440"))
    for (dx, dy) in [(-2, 1), (-3, 2), (-2, 5), (-3, 6), (14, 1), (15, 2), (14, 5), (15, 6)]:
        put(x + 2 + dx, y + 1 + dy, hx("c9a27a"))
    if kind == "lavender":
        for s_ in range(7):
            bx = x + 4 + s_ + (14 * (s_ - 3)) // 9
            for k in range(0, 14):
                xx = bx + (k * (s_ - 3)) // 14
                yy = y + 16 + k
                c = hx("c0a6ec") if (k + s_) % 3 == 0 else (hx("9a7ad0") if k % 2 else hx("8668c0"))
                put(xx, yy, c)
                if k % 2 == 0:
                    put(xx + (1 if s_ >= 3 else -1), yy, hx("6a52a0") if k > 8 else hx("b096e0"))
    else:
        # ромашка: белые цветки с жёлтой серединкой на концах стеблей (вверх ногами), между ними листики
        heads = [(1, 17), (8, 15), (13, 19), (4, 24), (10, 26)]
        for (dx, dy) in heads:
            cx, cy = x + 2 + dx, y + dy
            for ey in range(-4, 5):
                for ex in range(-4, 5):
                    d2 = ex * ex + ey * ey
                    if d2 <= 6:
                        put(cx + ex, cy + ey, hx("fffaf0") if ey < 0 or (ex < 0 and ey == 0) else hx("ece2d2"))
                    elif d2 <= 12:
                        put(cx + ex, cy + ey, hx("9a8468"))     # контур лепестков
            for (ex, ey, c) in [(0, 0, hx("f0b830")), (-1, 0, hx("ffd860")), (0, -1, hx("ffd860")), (-1, -1, hx("fff0a0")),
                                (1, 0, hx("d89820")), (0, 1, hx("d89820")), (1, 1, hx("c08018"))]:
                put(cx + ex, cy + ey, c)
        for (dx, dy, s_) in [(-1, 12, -1), (13, 12, 1), (-1, 20, -1), (13, 20, 1)]:
            for k in range(3):
                put(x + 2 + dx + s_ * k, y + dy + k, LEAF["md"])
                put(x + 2 + dx + s_ * k, y + dy + k + 1, LEAF["dk"])


bundle(34, 14, "lavender")
bundle(306, 14, "chamomile")

im.save(os.path.join(ART, "ui31_inv_bg.png"))
im.resize((W * K, H * K), Image.NEAREST).save(os.path.join(PREV, "ui31_inv_bg_x2.png"))
print("ok ui31_inv_bg", im.size)

# ------------------------------------------------------------- пучки отдельно (для склада и сундуков)
for kind in ("lavender", "chamomile"):
    im = Image.new("RGBA", (24, 48), T)
    px = im.load()
    FR = 0
    bundle(3, 8, kind)
    box = im.getbbox()
    im = im.crop(box)
    im.save(os.path.join(ART, "ui31_bundle_%s.png" % kind))
    print("ok bundle", kind, im.size)

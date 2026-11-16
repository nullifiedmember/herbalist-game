# -*- coding: utf-8 -*-
"""Степь Красной Лапы (город орков) в стиле яблока: дорожка, тюрьма, шатёр, хижина,
таверна, лавка, дворец вождя, приют, тотем-фонарь.

Запуск: python -I town_orcs.py  → herbalist_game/art_apple_town/orcs/*.png (+ листы для осмотра).
Размеры и «ноги» (низ-центр = дверь) как у старых картинок, чтобы город строился так же.
"""
import math, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from town_kit import Pic, sheet, ell, poly, rect, tube, up, col
from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
OUT = os.path.join(ROOT, "art_apple_town", "orcs")

WOOD = "#9c6c48"      # брёвна
WOOD_D = "#86583e"    # тёмные брёвна
PLANK = "#b07c50"     # доски дверей
HIDE = "#d2b083"      # шкуры шатров
HIDE_D = "#b89068"
RED = "#c8524a"       # краска Красной Лапы
THATCH = "#d0a65e"    # солома
BONE = "#efe2c4"      # клыки, рога
IRON = "#8e8ca4"
ROPE = "#c39a62"
PLUM = "#5e3c4e"      # темнота внутри проёмов
STONE = "#b4a894"
FIRE = "#ffb04a"
TEAL = "#5aa69a"
OCHRE = "#d8a040"


def paw(p, cx, cy, base=RED, s=1):
    """Знак Красной Лапы: подушечка + 3 пальца."""
    p.blob(ell(cx + 0.5, cy + 2.5, 3.2 * s, 2.6 * s), base, line=False)
    for dx, dy in ((-3, -2), (0, -3.5), (3, -2)):
        p.blob(ell(cx + 0.5 + dx * s, cy + 0.5 + dy * s, 1.3 * s, 1.5 * s), base, line=False)


def torch(p, x, y):
    """Факел на скобе: x,y — низ ручки."""
    p.log_v(x - 1, x + 1, y - 9, y, WOOD_D, grain=False)
    p.blob(rect(x - 2, y - 11, x + 2, y - 9), IRON)
    p.blob(ell(x + 0.5, y - 14.5, 3, 4.2), FIRE, shine=True, line=False)
    p.blob(ell(x + 0.5, y - 14, 1.4, 2.2), "#ffe9a0", line=False)
    p.put(x, y - 19, FIRE, 1)


# ---------------------------------------------------------------- дорожка
def path_tile(N=128, base="#b98058", seed="orc_path"):
    """N×N бесшовная утоптанная земля: ровный тон, редкие плоские камушки, мелкие крошки (без пятен-горошка)."""
    p = Pic(N, N, seed)
    B = (0xb9, 0x80, 0x58) if base == "#b98058" else None
    for y in range(N):
        for x in range(N):
            p.put(x, y, base, 2)
    bb = p.px[(0, 0)][0]
    # еле заметные вмятины-трещинки (короткие тёмные чёрточки по 2-4 px)
    for _ in range(N // 3):
        x, y = p.rng.randrange(N), p.rng.randrange(N)
        L = p.rng.randint(2, 4)
        horiz = p.rng.random() < 0.7
        for k in range(L):
            q = ((x + k) % N, y) if horiz else (x, (y + k) % N)
            p.put(q[0], q[1], base, 3)
        # светлая кромка над трещинкой (свет сверху)
        for k in range(L):
            q = ((x + k) % N, (y - 1) % N) if horiz else ((x - 1) % N, (y + k) % N)
            if p.px[q][0] == bb and p.px[q][1] == 2:
                p.put(q[0], q[1], base, 1)
    # камушки: разные по размеру и цвету, стоят вразброс
    cols = [STONE, "#c2ae96", "#a89884", "#c9a888", "#9e8c7c"]
    placed = []
    tries = 0
    while len(placed) < N * N // 700 and tries < 2000:
        tries += 1
        rx = p.rng.choice((1.6, 2, 2, 2.5, 3, 3.5, 4.5))
        ry = max(1.3, rx * p.rng.uniform(0.55, 0.75))
        cx, cy = p.rng.uniform(0, N), p.rng.uniform(0, N)
        if any(min(abs(cx - a), N - abs(cx - a)) < 10 and min(abs(cy - b), N - abs(cy - b)) < 8 for a, b in placed):
            continue
        placed.append((cx, cy))
        m = ell(cx + 10, cy + 10, rx, ry, p=2.3)
        sub = Pic(N + 40, N + 40)
        sub.blob(m, p.rng.choice(cols), shine=rx >= 3)
        mm = {((x - 10) % N, (y - 10) % N) for (x, y) in m}
        for (x, y), v in sub.px.items():
            p.px[((x - 10) % N, (y - 10) % N)] = v
        for (x, y) in mm:
            q = ((x + 1) % N, (y + 1) % N)
            if q not in mm and p.px[q][0] == bb:
                p.put(q[0], q[1], base, 3)
    # крошки
    for _ in range(N * N // 180):
        x, y = p.rng.randrange(N), p.rng.randrange(N)
        if p.px[(x, y)][0] == bb and p.px[(x, y)][1] == 2:
            p.put(x, y, base, p.rng.choice((1, 3)))
    return p.render(outline=False)


# ---------------------------------------------------------------- тюрьма
def prison():
    W, H = 200, 176
    p = Pic(W, H, "orc_prison")
    yb = H - 3
    # частокол
    x = 30
    while x < W - 32:
        w = 8
        top = 64 + p.rng.randint(-3, 3)
        p.log_v(x, x + w - 1, top, yb, WOOD if (x // 8) % 2 else WOOD_D, point=6)
        x += w
    # верёвочные обвязки
    for ry in (84, 140):
        for xx in range(30, W - 32):
            k = (xx + ry) % 4
            p.put(xx, ry, ROPE, 1 if k == 0 else 2)
            p.put(xx, ry + 1, ROPE, 3 if k != 3 else 6)
    # башни по краям
    for tx in (4, W - 38):
        for i in range(4):
            p.log_v(tx + i * 9, tx + i * 9 + 8, 40, yb, WOOD_D if i % 2 else WOOD, grain=True)
        # площадка
        p.log_h(tx - 2, tx + 37, 36, 42, WOOD)
        # крыша-конус из шкур
        cx = tx + 17.5
        roof = poly([(cx - 1, 6), (cx + 1, 6), (tx + 40, 36), (tx - 4, 36)])
        def rt(xx, yy, cx=cx):
            half = (yy - 6) / 30 * 22 + 1
            u = (xx + 0.5 - cx) / max(1, half)
            return 1 if u < -0.45 else 2 if u < 0.15 else 3 if u < 0.65 else 4
        p.fill(roof, HIDE_D, rt)
        for k in (-0.5, 0.0, 0.5):
            p.line([(cx, 7), (cx + k * 22, 35)], HIDE_D, 6)
        p.hline(tx - 4, tx + 39, 35, HIDE_D, 7)
        for k in range(tx - 3, tx + 40, 3):
            p.put(k, 34, RED, 2)
            p.put(k + 1, 34, RED, 3)
        # шесты над крышей
        p.line([(cx - 1, 7), (cx - 5, 1)], WOOD_D, 6)
        p.line([(cx + 1, 7), (cx + 5, 1)], WOOD_D, 6)
        # окошко-бойница
        p.blob(rect(tx + 13, 52, tx + 22, 60), PLUM)
        p.vline(tx + 17, 53, 59, IRON, 1)
        # знамя
        bx = tx + 10
        ban = poly([(bx, 70), (bx + 16, 70), (bx + 16, 98), (bx + 8, 92), (bx, 98)])
        p.blob(ban, RED, shine=True)
        p.blob(rect(bx - 2, 68, bx + 18, 70), WOOD_D)
        paw(p, bx + 8, 80, "#f2d2a0")
    # ворота: столбы, перекладина, решётка
    gx0, gx1 = 74, 125
    gy0 = 100
    for (a, b) in ((gx0 - 12, gx0 - 1), (gx1 + 1, gx1 + 12)):
        p.log_v(a, b, 52, yb, WOOD_D, point=8)
    # проём
    arch = rect(gx0, gy0, gx1, yb) | {(x, y) for (x, y) in ell((gx0 + gx1 + 1) / 2, gy0 + 1, (gx1 - gx0 + 1) / 2, 12) if y < gy0}
    def at(xx, yy):
        return 4 if yy < gy0 + 6 or xx > gx1 - 4 else 3
    p.fill(arch, PLUM, at)
    for bx in range(gx0 + 3, gx1 - 1, 7):
        for yy in range(gy0 - 10, yb + 1):
            if (bx, yy) in arch:
                p.put(bx, yy, IRON, 1)
                p.put(bx + 1, yy, IRON, 3)
    for cy in (gy0 + 16, gy0 + 46):
        p.blob(rect(gx0, cy, gx1, cy + 3), IRON)
        for rx in range(gx0 + 4, gx1, 7):
            p.put(rx, cy + 1, IRON, 0)
    # перекладина и табличка с лапой
    p.log_h(gx0 - 16, gx1 + 16, 76, 85, WOOD)
    for ex in (gx0 - 16, gx1 + 16):
        p.log_end(ex, 80, 5, "#c99a68")
    p.blob(rect(88, 56, 111, 73), PLANK, shine=True)
    p.line([(92, 56), (96, 48)], ROPE, 2)
    p.line([(107, 56), (103, 48)], ROPE, 2)
    p.put(100, 47, IRON, 2)
    paw(p, 99, 63, RED)
    # факелы у ворот
    torch(p, gx0 - 6, 108)
    torch(p, gx1 + 7, 108)
    # камни у подножия
    p.stones(28, W - 30, yb - 3, yb, STONE)
    return p.render()


# ---------------------------------------------------------------- шатёр (чум)
def tent():
    W, H = 120, 112
    p = Pic(W, H, "orc_tent")
    cx, top, yb = 59.5, 18, H - 4
    xl, xr = 8, W - 9
    cone = poly([(cx - 2, top), (cx + 2, top), (xr, yb), (xl, yb)])
    def half(yy):
        return 2 + (yy - top) / (yb - top) * ((xr - xl) / 2 - 2)
    def ct(xx, yy):
        u = (xx + 0.5 - cx) / half(yy)
        t = 1 if u < -0.5 else 2 if u < 0.2 else 3 if u < 0.7 else 4
        if yy >= yb - 1:
            t = min(4, t + 1)
        return t
    p.fill(cone, HIDE, ct)
    # швы полотнищ от верха вниз и стежки
    for k in (-0.62, -0.25, 0.12, 0.48, 0.8):
        pts = [(cx + k * 2, top + 2), (cx + k * ((xr - xl) / 2), yb)]
        p.line(pts, HIDE, 6)
        for yy in range(top + 8, yb - 2, 7):
            xx = int(round(cx + k * half(yy)))
            p.put(xx - 1, yy, HIDE, 0)
            p.put(xx + 1, yy, HIDE, 0)
    # красный пояс с треугольниками
    for yy in range(70, 78):
        for xx in range(xl, xr + 1):
            if (xx, yy) in cone:
                tt = ct(xx, yy)
                p.put(xx, yy, RED, tt)
        if yy == 77:
            for xx in range(xl, xr + 1):
                if (xx, yy) in cone:
                    p.put(xx, yy, RED, 7)
    for xx in range(xl, xr, 8):
        for d in range(3):
            for e in range(-d, d + 1):
                q = (xx + 4 + e, 71 + d)
                if q in cone:
                    p.put(q[0], q[1], "#f2d2a0", 1 if xx < cx else 2)
    paw(p, int(cx) - 22, 52, RED)
    # дверь: треугольный проём и откинутые края
    dt = 62
    door = poly([(cx, dt), (cx + 15, yb + 1), (cx - 15, yb + 1)])
    p.fill(door, PLUM, lambda xx, yy: 4 if yy < dt + 14 else 3)
    for yy in range(dt + 2, yb + 1):
        hw = (yy - dt) / (yb - dt) * 15
        for s, t in ((-1, 1), (1, 3)):
            xx = int(round(cx + s * hw))
            p.put(xx, yy, HIDE, t)
            p.put(xx + s, yy, HIDE, 0 if s < 0 else 2)
            p.put(xx + 2 * s, yy, HIDE, 6)
    # шесты сверху
    for (ex, ey) in ((-12, 2), (-6, 0), (1, 1), (8, 0), (13, 3)):
        p.line([(cx + ex * 0.2, top + 3), (cx + ex, ey + 1)], WOOD, 6)
        p.put(int(cx + ex), ey + 1, WOOD, 2)
    p.blob(rect(int(cx) - 3, top - 2, int(cx) + 3, top + 2), ROPE)
    return p.render()


# ---------------------------------------------------------------- хижина-купол
def hut():
    W, H = 130, 120
    p = Pic(W, H, "orc_hut")
    cx, yb = 64.5, H - 4
    rx, ry = 58, 80
    dome = {(x, y) for (x, y) in ell(cx, yb, rx, ry) if y <= yb and y >= 30}
    top = min(y for _, y in dome)
    def dt(xx, yy):
        u = (xx + 0.5 - cx) / rx
        v = (yy + 0.5 - yb) / ry
        nz = math.sqrt(max(0.0, 1 - u * u - v * v))
        it = -0.62 * u * 0.9 - 0.78 * v * 0.9 + nz * 0.5
        t = 1 if it > 0.78 else 2 if it > 0.5 else 3 if it > 0.28 else 4
        return t
    p.fill(dome, THATCH, dt)
    p.thatch(dome, THATCH, top + 3, step=8)
    # верх: пучок и шесты
    p.blob(ell(cx, top + 3, 9, 5), HIDE_D, shine=True)
    p.blob(rect(int(cx) - 7, top + 4, int(cx) + 8, top + 7), ROPE)
    p.line([(cx - 2, top + 2), (cx - 8, top - 10)], WOOD, 6)
    p.line([(cx + 2, top + 2), (cx + 7, top - 9)], WOOD, 6)
    # красная полоса-оберег
    for (xx, yy) in dome:
        if 70 <= yy <= 73 and not (cx - 18 < xx < cx + 18):
            p.put(xx, yy, RED, max(1, dt(xx, yy)))
    # дверь-арка
    dw, dh = 26, 38
    x0 = int(cx) - dw // 2
    frame = rect(x0 - 4, yb - dh - 1, x0 + dw + 3, yb) | {(x, y) for (x, y) in ell(cx, yb - dh, dw / 2 + 4, 14) if y < yb - dh}
    p.blob(frame, WOOD)
    hole = rect(x0, yb - dh + 3, x0 + dw - 1, yb) | {(x, y) for (x, y) in ell(cx, yb - dh + 3, dw / 2, 11) if y < yb - dh + 3}
    p.fill(hole, PLUM, lambda xx, yy: 4 if yy < yb - dh + 8 else 3)
    # шкура-занавесь, откинутая влево
    flap = poly([(x0, yb - dh - 4), (x0 + 12, yb - dh - 4), (x0 + 4, yb - 6), (x0, yb)])
    p.blob(flap, HIDE, shine=True)
    # клыки над дверью
    for s in (-1, 1):
        pts = [(cx + s * 10, yb - dh - 8), (cx + s * 22, yb - dh - 14), (cx + s * 26, yb - dh - 26)]
        p.blob(tube(pts, 3.2, 0.8), BONE, shine=s < 0)
    p.blob(ell(cx, yb - dh - 8, 5, 4), RED, shine=True)
    paw(p, int(cx), yb - dh - 9, "#f2d2a0", 0.6)
    p.stones(int(cx - rx) + 4, int(cx + rx) - 4, yb - 2, yb + 1, STONE)
    return p.render()


# ---------------------------------------------------------------- длинный дом
def longhouse(W, H, kind, seed):
    p = Pic(W, H, seed)
    yb = H - 3
    wall_top = H - 62
    eave = wall_top + 6
    roof_top = 16 if kind == "palace" else 22
    cx = W // 2
    # стены из горизонтальных брёвен
    for r, y in enumerate(range(wall_top, yb - 3, 8)):
        p.log_h(12, W - 13, y, min(y + 7, yb - 4), WOOD if r % 2 else WOOD_D)
    # торцы брёвен на углах
    for r, y in enumerate(range(wall_top, yb - 3, 8)):
        for ex in (10, W - 11):
            p.log_end(ex, y + 3, 4, "#c99a68")
    p.stones(10, W - 11, yb - 4, yb, STONE)
    # крыша: соломенный скат, светлый левый край, тёмный правый
    rl, rr = 40, W - 41
    roof = poly([(rl, roof_top), (rr, roof_top), (W - 2, eave + 2), (1, eave + 2)])
    def rt(xx, yy):
        f = (yy - roof_top) / max(1, eave + 2 - roof_top)
        lx = rl + (1 - rl) * f
        rx_ = rr + (W - 2 - rr) * f
        u = (xx - lx) / max(1, rx_ - lx)
        t = 2
        if u < 0.08 + 0.05 * (1 - f):
            t = 1
        if u > 0.9:
            t = 3
        if yy < roof_top + 3:
            t = 1
        return t
    p.fill(roof, THATCH, rt)
    p.thatch(roof, THATCH, roof_top + 4)
    # кромка стрехи: бахрома
    for xx in range(1, W - 1):
        if (xx, eave + 2) in roof or (xx, eave + 1) in roof:
            p.put(xx, eave + 3, THATCH, 3 if xx % 3 else 4)
            if xx % 3 == 0:
                p.put(xx, eave + 4, THATCH, 6)
    # тень от крыши на стене
    for xx in range(12, W - 12):
        for yy in (eave + 4, eave + 5):
            p.dark(xx, yy, 1, 4)
    # конёк-бревно
    p.log_h(rl - 2, rr + 2, roof_top - 4, roof_top, WOOD)
    for ex in (rl - 2, rr + 2):
        p.log_end(ex, roof_top - 2, 3, "#c99a68")
    # рога на концах конька
    for (ex, s) in ((rl - 2, -1), (rr + 2, 1)):
        pts = [(ex, roof_top - 4), (ex + s * 6, roof_top - 10), (ex + s * 4, roof_top - 18)]
        p.blob(tube(pts, 2.6, 0.7), BONE, shine=s < 0)
    # окна по бокам от двери
    ww = 16
    n_side = max(1, (W // 2 - 50) // 44)
    for s in (-1, 1):
        for i in range(n_side):
            wx = cx + s * (48 + i * 44) - ww // 2
            p.window(wx, wall_top + 18, ww, 16, WOOD_D)
    # дверь по центру
    p.door(cx, yb - 4, 22 if kind != "palace" else 30, 36 if kind != "palace" else 42, PLANK)
    # вывески и украшения
    if kind == "tavern":
        bx = cx + 14
        p.blob(rect(bx, wall_top + 10, bx + 12, wall_top + 12), WOOD_D)
        p.blob(rect(bx + 2, wall_top + 13, bx + 22, wall_top + 29), PLANK, shine=True)
        # кружка
        p.blob(rect(bx + 7, wall_top + 16, bx + 14, wall_top + 26), OCHRE, shine=True)
        p.blob(rect(bx + 7, wall_top + 15, bx + 14, wall_top + 17), "#fff4dc", line=False)
        p.blob(rect(bx + 15, wall_top + 18, bx + 17, wall_top + 23), OCHRE)
    elif kind == "shop":
        bx = cx + 12
        p.blob(rect(bx + 2, wall_top + 12, bx + 22, wall_top + 28), PLANK, shine=True)
        p.blob(ell(bx + 12.5, wall_top + 22, 6, 5), HIDE_D, shine=True)
        p.blob(rect(bx + 10, wall_top + 15, bx + 15, wall_top + 17), ROPE)
        p.blob(ell(bx + 12.5, wall_top + 22.5, 2.2, 2.2), OCHRE, line=False)
    elif kind == "shelter":
        bx = cx + 12
        p.blob(rect(bx + 2, wall_top + 12, bx + 24, wall_top + 30), PLANK, shine=True)
        paw(p, bx + 13, wall_top + 20, "#7a5a44")
    elif kind == "palace":
        # фронтон над дверью
        gl, gr, gt = cx - 46, cx + 46, roof_top - 6
        gab = poly([(cx, gt), (gr, eave + 4), (gl, eave + 4)])
        def gtone(xx, yy):
            return 1 if xx < cx - 4 else 2 if xx < cx + 18 else 3
        p.fill(gab, THATCH, gtone)
        p.thatch(gab, THATCH, gt + 4)
        p.line([(cx, gt), (gl - 2, eave + 5)], WOOD_D, 6)
        p.line([(cx, gt), (gr + 2, eave + 5)], WOOD_D, 7)
        p.line([(cx, gt + 1), (gl - 1, eave + 5)], WOOD, 1)
        # большой клык-оберег на фронтоне
        p.blob(ell(cx, eave - 12, 9, 8), RED, shine=True)
        paw(p, cx, eave - 13, "#f2d2a0", 0.9)
        for s in (-1, 1):
            pts = [(cx + s * 8, eave - 6), (cx + s * 18, eave - 10), (cx + s * 20, eave - 22)]
            p.blob(tube(pts, 3.0, 0.8), BONE, shine=s < 0)
        # знамёна и щиты
        for s in (-1, 1):
            bx = cx + s * 34 - 7
            ban = poly([(bx, wall_top + 10), (bx + 14, wall_top + 10), (bx + 14, wall_top + 40), (bx + 7, wall_top + 34), (bx, wall_top + 40)])
            p.blob(ban, RED, shine=True)
            p.blob(rect(bx - 2, wall_top + 8, bx + 16, wall_top + 10), WOOD_D)
            paw(p, bx + 7, wall_top + 20, "#f2d2a0", 0.8)
        for s in (-1, 1):
            sx = cx + s * (W // 2 - 26)
            p.blob(ell(sx, wall_top + 26, 9, 10), HIDE_D, shine=True)
            p.blob(ell(sx, wall_top + 26, 4, 4.5), RED, line=False)
            p.put(sx, wall_top + 26, BONE, 0)
        torch(p, cx - 22, yb - 12)
        torch(p, cx + 23, yb - 12)
    return p.render()


# ---------------------------------------------------------------- тотем-фонарь
def totem():
    W, H = 44, 120
    p = Pic(W, H, "orc_totem")
    yb = H - 3
    x0, x1 = 15, 28
    p.log_v(x0, x1, 18, yb, WOOD)
    # крылья наверху
    wing = poly([(3, 16), (40, 16), (36, 24), (7, 24)])
    p.blob(wing, PLANK, shine=True)
    paw(p, 22, 18, RED, 0.7)
    # голова-верхушка
    p.blob(ell(21.5, 10, 8, 8), RED, shine=True)
    for s in (-1, 1):
        pts = [(21.5 + s * 6, 8), (21.5 + s * 11, 4), (21.5 + s * 11, -1)]
        p.blob(tube(pts, 2.0, 0.7), BONE, shine=s < 0)
    p.put(19, 10, PLUM, 3); p.put(24, 10, PLUM, 3)
    p.put(19, 9, "#ffffff", 0); p.put(24, 9, "#ffffff", 0)
    # резные лица
    for i, (fy, c) in enumerate(((38, TEAL), (64, OCHRE), (90, RED))):
        face = rect(x0 - 1, fy, x1 + 1, fy + 18)
        p.blob(face, c, shine=True)
        p.blob(rect(x0 + 1, fy + 4, x1 - 1, fy + 5), c, bias=1, line=False)
        for ex in (x0 + 3, x1 - 4):
            p.blob(rect(ex, fy + 7, ex + 1, fy + 8), PLUM, line=False)
            p.put(ex, fy + 7, "#ffffff", 0)
        p.blob(rect(x0 + 4, fy + 12, x1 - 4, fy + 14), PLUM, line=False)
        p.put(x0 + 5, fy + 11, BONE, 1)
        p.put(x1 - 5, fy + 11, BONE, 1)
    # фонарь на рукояти (свет игры — на 8 px правее центра и 46 px выше низа)
    p.blob(rect(x1, 64, x1 + 8, 66), WOOD_D)
    p.vline(x1 + 6, 67, 68, ROPE, 3)
    lx = x1 + 3
    p.blob(rect(lx, 69, lx + 7, 80), IRON)
    p.blob(rect(lx + 2, 71, lx + 5, 78), FIRE, line=False)
    p.blob(rect(lx + 3, 72, lx + 4, 76), "#ffe9a0", line=False)
    p.blob(rect(lx - 1, 68, lx + 8, 69), WOOD_D)
    p.stones(12, 31, yb - 3, yb, STONE)
    return p.render()


def main():
    os.makedirs(OUT, exist_ok=True)
    out = {
        "st10_orcs": path_tile(),
        "prison_orcs": prison(),
        "orc_tent": tent(),
        "orc_hut": hut(),
        "tavern_orcs": longhouse(248, 146, "tavern", "orc_tavern"),
        "shop_orcs": longhouse(178, 140, "shop", "orc_shop"),
        "palace_orcs": longhouse(308, 160, "palace", "orc_palace"),
        "shelter_orcs": longhouse(200, 150, "shelter", "orc_shelter"),
        "totem": totem(),
    }
    for n, im in out.items():
        im.save(os.path.join(OUT, n + ".png"))
        up(im, 8).save(os.path.join(OUT, n + "_x8.png"))
    order = ["prison_orcs", "orc_tent", "orc_hut", "tavern_orcs", "shop_orcs", "palace_orcs", "shelter_orcs", "totem"]
    sheet([out[n] for n in order], k=2).save(os.path.join(ROOT, "art_apple_town", "orcs_sheet_x2.png"))
    # пример на земле степи: дорожка + постройки
    tile = out["st10_orcs"]
    bg = Image.new("RGBA", (520, 300), (214, 180, 120, 255))
    for y in range(160, 230):
        for x in range(0, 520):
            bg.putpixel((x, y), tile.getpixel((x % tile.width, y % tile.height)))
    for (n, x) in (("orc_tent", 10), ("prison_orcs", 150), ("orc_hut", 370)):
        im = out[n]
        bg.alpha_composite(im, (x, 168 - im.height))
    up(bg, 2).save(os.path.join(ROOT, "art_apple_town", "orcs_scene_x2.png"))
    print("ok", OUT)


if __name__ == "__main__":
    main()

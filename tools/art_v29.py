"""v29: арт заднего дворика (как сад в Potion Craft: холмы за забором, большое дерево, грядки),
грибные деревья, бочка для дождевой воды, калитки, мотыга и лейка.
Запуск из папки game:  python tools/art_v29.py   -> art/*.png  (потом godot --headless --import)
"""
import math, os, sys
import numpy as np
from PIL import Image
sys.path.insert(0, os.path.dirname(__file__))
from px import Canvas, ramp, hx, mix, OUTLINE

ART = os.path.join(os.path.dirname(__file__), "..", "art")
BROWN_OL = (52, 34, 24, 255)
R = np.random.default_rng(29)


def save(c, name):
    c.save(os.path.join(ART, name + ".png"))
    print("art/" + name + ".png", c.w, c.h)


def noise(w, h, scale, seed):
    """Плавный шум 0..1 (сумма синусов) — для пятен травы и неба."""
    rg = np.random.default_rng(seed)
    yy, xx = np.mgrid[0:h, 0:w].astype(float)
    out = np.zeros((h, w))
    for k in range(6):
        a = rg.uniform(0, math.tau)
        f = rg.uniform(0.6, 1.6) / scale
        ph = rg.uniform(0, math.tau)
        out += np.sin((xx * math.cos(a) + yy * math.sin(a)) * f + ph)
    out = (out - out.min()) / (out.max() - out.min())
    return out


def crown(c, clumps, base="6f9a4c", seed=1):
    """Крона из клубов листвы: у каждого клуба светлая макушка слева-сверху, тень снизу-справа,
    листовая крапинка; без колец-контуров внутри — только общий силуэт."""
    rg = np.random.default_rng(seed)
    leaf = ramp(base, 5, 0.55)
    allm = c.mask()
    for x, y, r in sorted(clumps, key=lambda q: q[1]):
        cm = c.ellipse(x, y, r, r * 0.85)
        lit = c.ellipse(x - r * 0.28, y - r * 0.3, r * 0.72, r * 0.6)
        top = c.ellipse(x - r * 0.4, y - r * 0.45, r * 0.38, r * 0.3)
        sh = cm & ~c.ellipse(x - 1.5, y - 2.5, r, r * 0.85)
        c.fill(cm, leaf[2])
        c.fill(cm & lit, leaf[3])
        c.fill(cm & top, leaf[4])
        c.fill(sh, leaf[1])
        ys, xs = np.nonzero(cm)
        for yy, xx in zip(ys, xs):
            v = rg.random()
            if v < 0.07:
                c.px[yy, xx] = leaf[1]
                if yy + 1 < c.h and cm[yy + 1, xx]:
                    c.px[yy + 1, xx] = leaf[0]
            elif v < 0.11 and lit[yy, xx]:
                c.px[yy, xx] = leaf[4]
        allm |= cm
    return allm


# ============================================================ фон дворика 640x360
def backyard_bg():
    W, H = 640, 360
    c = Canvas(W, H)
    px = c.px
    # --- небо: тёплый пергамент, к горизонту светлее
    sky_top, sky_bot = np.array(hx("e6d6ae")), np.array(hx("f4ead0"))
    for y in range(0, 120):
        t = min(1.0, y / 70.0)
        px[y, :, :3] = (sky_top * (1 - t) + sky_bot * t).astype(np.uint8)
        px[y, :, 3] = 255
    # облака — светлые валики с тёплой тенью снизу
    for (cx, cy, n) in [(90, 22, 5), (300, 14, 6), (500, 30, 4), (610, 12, 3)]:
        m = c.mask()
        for k in range(n):
            c.ellipse(cx + k * 13 - n * 6, cy - (4 if k % 2 else 0), 12, 7, m)
        sh = c.mask()
        for k in range(n):
            c.ellipse(cx + k * 13 - n * 6 + 2, cy + 3 - (4 if k % 2 else 0), 12, 6, sh)
        c.fill(sh & ~m, hx("dccaa0"))
        c.fill(m, hx("fbf4e2"))
    # --- холмы: три слоя, как акварель с тушью
    xs = np.arange(W)
    layers = [
        (62, 10, 0.011, 1.2, "d6c79c", "c7b78a"),
        (84, 12, 0.017, 0.4, "c2b47e", "ad9f69"),
        (104, 9, 0.023, 2.2, "a9a466", "938f55"),
    ]
    hill_y = []
    for li, (base, amp, fr, ph, col, dark) in enumerate(layers):
        top = base + amp * np.sin(xs * fr + ph) + amp * 0.5 * np.sin(xs * fr * 2.3 + ph * 1.7)
        hill_y.append(top)
        for x in range(W):
            t0 = int(top[x])
            for y in range(max(0, t0), 152):
                d = y - t0
                cc = hx(col) if d > 1 else mix(hx(col), (255, 250, 230), 0.35)[:3]
                px[y, x, :3] = cc
                px[y, x, 3] = 255
            # штриховка тушью — короткие косые чёрточки по склону
            if x % 5 == (li * 2) % 5:
                for k in range(2):
                    yy = t0 + 4 + k * 6 + (x * 7 % 5)
                    if 0 <= yy < 150 and yy + 2 < 150:
                        px[yy, x, :3] = hx(dark)
                        if x + 1 < W:
                            px[yy + 1, x + 1, :3] = hx(dark)
    # дальний замок и мельница на дальнем холме
    def sil(x0, ytop_arr, pts, col):
        m = c.poly([(x0 + a, int(ytop_arr[x0]) + b) for a, b in pts])
        c.fill(m, hx(col))
    t = hill_y[0]
    sil(150, t, [(0, 2), (0, -10), (2, -10), (2, -14), (4, -10), (8, -10), (8, -18), (10, -22), (12, -18), (12, -10), (16, -10), (16, 2)], "b9a77c")
    # мельница
    mx, my = 470, int(hill_y[0][470])
    c.fill(c.poly([(mx - 3, my + 2), (mx - 2, my - 12), (mx + 2, my - 12), (mx + 3, my + 2)]), hx("b4a275"))
    for a in range(4):
        ang = a * math.pi / 2 + 0.4
        c.line([(mx, my - 12), (mx + math.cos(ang) * 9, my - 12 + math.sin(ang) * 9)], hx("a8966a"), 1)
    # рощицы на среднем холме — круглые кроны с тенью
    for (gx, n) in [(40, 4), (230, 3), (380, 5), (560, 3)]:
        gy = int(hill_y[1][gx]) + 2
        for k in range(n):
            x = gx + k * 7
            m = c.ellipse(x, gy - 3 - (k % 2) * 2, 5, 5)
            c.fill(m, hx("96935a"))
            c.fill(c.ellipse(x - 1, gy - 5 - (k % 2) * 2, 3, 3) & m, hx("aaa86c"))
    # поле полосами на ближнем холме
    for x in range(W):
        t2 = int(hill_y[2][x])
        for y in range(t2 + 5, 150):
            if ((x + (y - t2) * 2) // 6) % 2 == 0 and 180 < x < 420:
                px[y, x, :3] = hx("b5ae6c")
    # --- земля двора (ниже забора)
    g = noise(W, H, 26.0, 3)
    g2 = noise(W, H, 7.0, 9)
    grass = [hx("70aa72"), hx("84b979"), hx("98c780"), hx("acd38a")]
    for y in range(150, H):
        for x in range(W):
            v = g[y, x] * 0.7 + g2[y, x] * 0.3
            i = min(3, int(v * 4.2))
            px[y, x, :3] = grass[i]
            px[y, x, 3] = 255
    # травинки
    for k in range(1600):
        x = int(R.integers(2, W - 2)); y = int(R.integers(182, H - 2))
        col = grass[0] if R.random() < 0.6 else grass[3]
        px[y, x, :3] = col
        px[y - 1, x + (1 if R.random() < 0.5 else 0), :3] = col
    # тропинка от калитки слева вниз и к центру
    path_m = c.mask()
    pts = [(40, 182), (46, 210), (70, 228), (300, 238), (320, 260), (318, 300), (322, 360)]
    for i in range(len(pts) - 1):
        c.line_mask([pts[i], pts[i + 1]], 16, path_m)
    pn = noise(W, H, 4.0, 5)
    for y, x in zip(*np.nonzero(path_m)):
        v = pn[y, x]
        px[y, x, :3] = hx("d8b98a") if v > 0.55 else (hx("c9a777") if v > 0.25 else hx("e4c99c"))
    edge = path_m & ~np.roll(path_m, 1, 0) | path_m & ~np.roll(path_m, -1, 0) | path_m & ~np.roll(path_m, 1, 1) | path_m & ~np.roll(path_m, -1, 1)
    px[edge, :3] = hx("b39066")
    # камни-плитки по тропинке
    for (sx, sy) in [(46, 204), (64, 224), (318, 272), (322, 300), (318, 328)]:
        m = c.ellipse(sx, sy, 6, 3.5)
        c.fill(m, hx("b9b2a6"))
        c.fill(c.ellipse(sx - 1, sy - 1, 4, 2) & m, hx("d4cdc0"))
        c.inner_line(m, (*hx("8c857b"), 255))
    # --- забор-штакетник через весь задний край, тень на траву
    top_y, bot_y = 120, 176
    for y in range(bot_y, bot_y + 9):
        k = 1.0 - (y - bot_y) / 9.0
        px[y, :, :3] = (px[y, :, :3] * (1 - 0.28 * k)).astype(np.uint8)
    wood = ramp("c7a473", 5, 0.5)
    rails = [138, 162]
    for ry in rails:
        m = c.rect(0, ry, W, ry + 5)
        c.fill(m, wood[1])
        c.fill(c.rect(0, ry, W, ry + 1), wood[3])
        c.fill(c.rect(0, ry + 4, W, ry + 5), BROWN_OL)
    x = 2
    i = 0
    while x < W - 10:
        w = 9
        h_off = (i * 37) % 3
        tip = top_y + h_off
        m = c.poly([(x, tip + 5), (x + w / 2, tip), (x + w, tip + 5), (x + w, bot_y), (x, bot_y)])
        c.shade(m, wood, light=(-1, -1), gy=0.25)
        # волокна и сучки
        for k in range(3):
            yy = tip + 10 + ((i * 13 + k * 17) % (bot_y - tip - 14))
            px[yy, x + 2 + (k % 3) * 2, :3] = wood[1][:3]
        if i % 4 == 1:
            px[tip + 22, x + 4, :3] = wood[0][:3]
        # контур штакетины
        e = m & ~(np.roll(m, 1, 0) & np.roll(m, -1, 0) & np.roll(m, 1, 1) & np.roll(m, -1, 1))
        px[e] = BROWN_OL
        x += w + 3
        i += 1
    # плющ по забору местами
    for (vx, n) in [(120, 7), (250, 5), (600, 6)]:
        for k in range(n):
            lx = vx + int(math.sin(k * 1.3) * 6) + k * 2
            ly = top_y + 14 + k * 7
            m = c.ellipse(lx, ly, 3, 2)
            c.fill(m, hx("5d8f4e"))
            c.dot(lx - 1, ly - 1, hx("8cbf68"))
    # калитка слева (выход) рисуется отдельным спрайтом — здесь проём в заборе
    c.fill(c.rect(26, top_y - 2, 56, bot_y + 1), (0, 0, 0, 0))
    gap = c.rect(26, top_y + 10, 56, bot_y + 1)
    for y, x in zip(*np.nonzero(gap)):
        px[y, x] = (*hx("8fae62"), 255) if y > 150 else px[y, x]
    # за калиткой — кусочек дорожки вдаль (зелёный проём)
    for y in range(top_y - 2, bot_y + 1):
        for x in range(26, 56):
            if y < 150:
                px[y, x, :3] = (hx("a9a466") if y > 108 else hx("f0e5c6"))
                px[y, x, 3] = 255
            else:
                px[y, x, :3] = hx("cdb184") if 34 < x < 48 else hx("84b979")
                px[y, x, 3] = 255
    # кусты по бокам у забора
    for (bx, by, s) in [(8, 186, 1.0), (628, 190, 1.1), (200, 180, 0.7), (612, 330, 1.2), (6, 340, 1.0)]:
        m = c.mask()
        for k in range(5):
            c.ellipse(bx + (k - 2) * 7 * s, by - (k % 2) * 4 * s, 9 * s, 8 * s, m)
        c.shade(m, ramp("5f9a58", 5, 0.5), gy=0.3)
        e = m & ~(np.roll(m, 1, 0) & np.roll(m, -1, 0) & np.roll(m, 1, 1) & np.roll(m, -1, 1))
        px[e] = (*hx("2f4a2c"), 255)
        for k in range(6):
            fx_, fy_ = int(bx + R.integers(-12, 12) * s), int(by + R.integers(-8, 4) * s)
            if 0 <= fx_ < W and 0 <= fy_ < H and m[fy_, fx_]:
                c.dot(fx_, fy_, hx("f3c6d6") if k % 2 else hx("fff3c4"))
    # цветочки в траве
    for k in range(70):
        fx_, fy_ = int(R.integers(10, W - 10)), int(R.integers(186, H - 6))
        if path_m[fy_, fx_]:
            continue
        col = [hx("f6e7a1"), hx("f2b7c8"), hx("c9d8f6"), hx("ffffff")][k % 4]
        c.dot(fx_, fy_, col)
        c.dot(fx_, fy_ + 1, hx("4f8a4c"))
    save(c, "by29_bg")


# ============================================================ большое старое дерево (как в саду Potion Craft)
def big_tree():
    W, H = 290, 330
    c = Canvas(W, H)
    cx, base = 145, H - 4
    bark = ramp("8a6243", 5, 0.5)
    # корни и ствол
    m = c.poly([(cx - 34, base), (cx - 22, base - 14), (cx - 18, base - 120), (cx - 22, base - 170), (cx - 8, base - 185),
                (cx + 10, base - 185), (cx + 24, base - 168), (cx + 20, base - 120), (cx + 24, base - 14), (cx + 38, base)])
    c.poly([(cx - 50, base), (cx - 30, base - 8), (cx - 20, base - 4)], m)
    c.poly([(cx + 52, base + 1), (cx + 30, base - 8), (cx + 22, base - 3)], m)
    # ветви
    br = c.mask()
    for pts, wd in [([(cx - 6, base - 170), (cx - 40, base - 215), (cx - 80, base - 230)], 12),
                    ([(cx + 8, base - 172), (cx + 46, base - 205), (cx + 92, base - 214)], 12),
                    ([(cx, base - 180), (cx - 4, base - 230), (cx + 6, base - 262)], 12),
                    ([(cx - 30, base - 204), (cx - 56, base - 196)], 6),
                    ([(cx + 40, base - 200), (cx + 60, base - 238)], 6)]:
        c.line_mask(pts, wd, br)
    trunk = m | br
    c.shade(trunk, bark, light=(-1, 0), gy=0.15)
    # кора — вертикальные бороздки
    ys, xs = np.nonzero(m)
    for y, x in zip(ys, xs):
        if (x * 3 + (y // 9)) % 7 == 0 and y < base - 6:
            c.px[y, x] = bark[0]
        elif (x * 5 + y // 13) % 11 == 0:
            c.px[y, x] = bark[3]
    # дупло
    h = c.ellipse(cx + 2, base - 112, 8, 13)
    c.fill(h, hx("2e1d16"))
    c.fill(c.ellipse(cx + 3, base - 108, 5, 8) & h, hx("1c120e"))
    c.inner_line(c.ellipse(cx + 2, base - 112, 9, 14) & ~h, bark[3])
    # крона: клубы листвы, закрывают концы ветвей
    clumps = []
    for k in range(30):
        a = R.uniform(0, math.tau)
        rr = R.uniform(0, 1) ** 0.55
        clumps.append((cx + math.cos(a) * 92 * rr, 104 + math.sin(a) * 62 * rr, R.uniform(22, 32)))
    for (x, y) in [(cx - 92, 100), (cx + 96, 104), (cx, 40), (cx - 50, 60), (cx + 52, 58), (cx - 60, 150), (cx + 66, 150), (cx, 160)]:
        clumps.append((x, y, R.uniform(24, 30)))
    crown(c, clumps, "6f9a4c", 7)
    # свисающая лоза
    for k in range(40):
        c.dot(cx - 50 + int(math.sin(k * 0.3) * 2), 150 + k, hx("4f7a3c"))
        if k % 6 == 0:
            c.dot(cx - 49, 150 + k, hx("8cbf68"))
    # грибы-трутовики оранжевыми полками на стволе
    for (fx_, fy_, s) in [(cx - 20, base - 70, 1.0), (cx - 24, base - 60, 0.8), (cx + 20, base - 92, 0.9), (cx + 22, base - 82, 0.7), (cx - 14, base - 24, 0.8)]:
        fm = c.mask()
        c.ellipse(fx_, fy_, 11 * s, 4 * s, fm)
        c.shade(fm, ramp("d9813e", 5, 0.55), light=(0, -1), gy=0.5)
        c.line([(fx_ - 8 * s, fy_ + 1), (fx_ + 8 * s, fy_ + 1)], hx("a8562a"))
        c.dot(fx_ - 3, fy_ - 2, hx("f6c48a"))
    # трава у корней
    for k in range(40):
        x = cx - 48 + k * 2.4
        hh = int(3 + (k * 7 % 5))
        c.line([(x, base + 1), (x + (1 if k % 2 else -1), base + 1 - hh)], hx("4f8a4c") if k % 3 else hx("8cbf68"))
    c.outline(BROWN_OL)
    save(c, "by29_big_tree")


# ============================================================ грядки
def soil():
    W, H = 40, 26
    for kind in ["grass", "till", "wet"]:
        c = Canvas(W, H)
        if kind == "grass":
            m = c.rect(1, 2, W - 1, H - 2)
            c.fill(m, (0, 0, 0, 0))
            # колышки по углам и бечёвка — видно, где можно вскопать
            for (x, y) in [(2, 4), (W - 3, 4), (2, H - 4), (W - 3, H - 4)]:
                c.fill(c.rect(x - 1, y - 4, x + 1, y + 1), hx("a87b4f"))
                c.dot(x - 1, y - 4, hx("d0a774"))
            for x in range(3, W - 3):
                if x % 2 == 0:
                    c.dot(x, 1, hx("e9dcc0"))
                    c.dot(x, H - 5, hx("e9dcc0"))
            for y in range(1, H - 4):
                if y % 2 == 0:
                    c.dot(1, y, hx("e9dcc0"))
                    c.dot(W - 2, y, hx("e9dcc0"))
            save(c, "by29_soil_grass")
            continue
        base = "8c5f3b" if kind == "till" else "5a3a26"
        rp = ramp(base, 5, 0.5)
        m = c.poly([(2, 6), (5, 3), (W - 5, 3), (W - 2, 6), (W - 2, H - 4), (W - 5, H - 1), (5, H - 1), (2, H - 4)])
        c.shade(m, rp, light=(-1, -1), gy=0.3)
        # три борозды
        for r in range(3):
            y = 7 + r * 6
            c.line([(5, y), (W - 6, y)], rp[0])
            c.line([(5, y - 1), (W - 6, y - 1)], rp[3])
            for x in range(6, W - 6, 4):
                c.dot(x + (r % 2), y - 2, rp[4] if kind == "till" else (*hx("9fb9c9"), 255))
        # комочки
        for k in range(10):
            x, y = int(R.integers(5, W - 5)), int(R.integers(5, H - 3))
            c.dot(x, y, rp[1])
        if kind == "wet":
            for k in range(6):
                x, y = int(R.integers(6, W - 6)), int(R.integers(6, H - 4))
                c.dot(x, y, (*hx("c6dfe8"), 255))
        c.outline((*hx("3b2618"), 255))
        save(c, "by29_soil_" + kind)


def sprouts():
    # 0 — посеяно: семечки и крошечный росток; 1 — два листочка
    c = Canvas(20, 16)
    for (x, y) in [(5, 11), (10, 12), (15, 11)]:
        c.dot(x, y, hx("e8d29a"))
        c.dot(x + 1, y, hx("b48a50"))
    c.line([(10, 12), (10, 8)], hx("5c9a46"))
    c.dot(9, 7, hx("8cd06a")); c.dot(11, 7, hx("8cd06a"))
    save(c, "by29_sprout_0")
    c = Canvas(24, 22)
    for (x, s) in [(6, 0.8), (12, 1.0), (18, 0.8)]:
        c.line([(x, 20), (x, 20 - 8 * s)], hx("4f8a3c"))
        for d in (-1, 1):
            m = c.ellipse(x + d * 3 * s, 20 - 9 * s, 3 * s, 1.8 * s)
            c.shade(m, ramp("6fb455", 5, 0.5))
    c.outline((*hx("2d4a26"), 255))
    save(c, "by29_sprout_1")


# ============================================================ грибные деревья
def mush_trees():
    # лунка с камушками
    c = Canvas(34, 16)
    m = c.ellipse(17, 8, 13, 5.5)
    c.shade(m, ramp("6e4a30", 5, 0.4), light=(0, -1))
    for k in range(9):
        a = k / 9 * math.tau
        x, y = 17 + math.cos(a) * 15, 8 + math.sin(a) * 6.5
        sm = c.ellipse(x, y, 2.4, 1.8)
        c.fill(sm, hx("b5ada0"))
        c.dot(int(x) - 1, int(y) - 1, hx("dcd5c8"))
    c.outline((*hx("3b2618"), 255))
    save(c, "by29_mt_hole")
    # 0 — саженец у колышка
    c = Canvas(26, 40)
    c.fill(c.rect(17, 6, 19, 38), hx("a87b4f"))
    c.dot(17, 6, hx("d0a774"))
    c.line([(12, 38), (13, 20), (12, 12)], hx("7a5a3a"))
    c.line([(13, 22), (18, 21)], hx("e9dcc0"))
    for (x, y, d) in [(12, 12, -1), (13, 16, 1), (12, 20, -1), (13, 26, 1)]:
        lm = c.ellipse(x + d * 4, y, 4, 2.2)
        c.shade(lm, ramp("6fb455", 5, 0.5))
    m = c.ellipse(13, 37, 9, 3)
    c.fill(m & (c.alpha() == False), hx("6e4a30"))
    c.outline((*hx("2d2418"), 255))
    save(c, "by29_mt_0")
    # 1 — молодое деревце
    c = Canvas(46, 70)
    bark = ramp("7d5a3c", 5, 0.5)
    t = c.poly([(20, 68), (21, 34), (25, 34), (26, 68)])
    c.line_mask([(23, 40), (13, 28)], 3, t)
    c.line_mask([(23, 38), (33, 26)], 3, t)
    c.shade(t, bark, light=(-1, 0))
    crown(c, [(14, 24, 10), (32, 22, 10), (23, 14, 12), (23, 26, 9)], "6f9a4c", 3)
    c.outline((*hx("2d2418"), 255))
    save(c, "by29_mt_1")
    # 2 — взрослое: толстый корявый ствол (на нём растут грибы) и пышная шапка
    c = Canvas(84, 112)
    bx, base = 42, 110
    t = c.poly([(bx - 20, base), (bx - 12, base - 8), (bx - 11, base - 54), (bx - 15, base - 66), (bx - 4, base - 70),
                (bx + 6, base - 70), (bx + 16, base - 64), (bx + 12, base - 52), (bx + 13, base - 8), (bx + 22, base)])
    c.shade(t, ramp("7a5636", 5, 0.5), light=(-1, 0), gy=0.1)
    ys, xs = np.nonzero(t)
    for y, x in zip(ys, xs):
        if (x * 3 + y // 7) % 6 == 0:
            c.px[y, x] = (*hx("4e3524"), 255)
    # мох внизу ствола
    for k in range(40):
        x = int(R.integers(bx - 14, bx + 14)); y = int(R.integers(base - 26, base - 2))
        if t[y, x]:
            c.dot(x, y, hx("7aa250") if k % 2 else hx("9cc06a"))
    crown(c, [(22, 30, 16), (60, 28, 16), (42, 16, 19), (30, 40, 13), (55, 42, 13), (42, 36, 14), (12, 38, 9), (72, 38, 9)], "6a9548", 5)
    c.outline((*hx("2d2418"), 255))
    save(c, "by29_mt_2")


# ============================================================ бочка, калитки
def props():
    for kind in ["full", "low"]:
        c = Canvas(28, 36)
        wood = ramp("9a6b42", 5, 0.5)
        m = c.poly([(4, 6), (24, 6), (26, 18), (24, 33), (4, 33), (2, 18)])
        c.shade(m, wood, light=(-1, 0), gy=0.1)
        for x in range(6, 24, 4):
            c.line([(x, 8), (x, 32)], wood[1])
        for y in (11, 26):
            c.line([(3, y), (25, y)], (*hx("5c5c66"), 255))
            c.line([(3, y - 1), (25, y - 1)], (*hx("9a9aa6"), 255))
        top = c.ellipse(14, 6, 10, 3.5)
        c.fill(top, wood[3])
        inner = c.ellipse(14, 6, 8, 2.5)
        c.fill(inner, hx("6fa6c8") if kind == "full" else hx("2b1d14"))
        if kind == "full":
            c.dot(11, 5, hx("c9e6f4")); c.dot(12, 5, hx("c9e6f4"))
        c.outline(BROWN_OL)
        save(c, "by29_barrel_" + kind)
    # калитка в заборе дворика (выход), как штакетник
    c = Canvas(34, 62)
    wood = ramp("c7a473", 5, 0.5)
    for x0 in (0, 29):
        m = c.poly([(x0, 8), (x0 + 2.5, 3), (x0 + 5, 8), (x0 + 5, 61), (x0, 61)])
        c.shade(m, ramp("a8835a", 5, 0.5))
    for x in range(6, 28, 6):
        m = c.poly([(x, 16), (x + 2.5, 12), (x + 5, 16), (x + 5, 54), (x, 54)])
        c.shade(m, wood, gy=0.25)
    c.fill(c.rect(6, 22, 28, 25), wood[1])
    c.fill(c.rect(6, 44, 28, 47), wood[1])
    c.line([(7, 45), (27, 24)], wood[0], 2)
    c.dot(25, 35, hx("4a4a52")); c.dot(25, 36, hx("8a8a96"))
    c.outline(BROWN_OL)
    save(c, "by29_gate_back")
    # калитка-арка с вьюнком во дворе у дома (вход на задний двор)
    c = Canvas(52, 66)
    wood = ramp("b08356", 5, 0.5)
    for x0 in (4, 42):
        c.shade(c.rect(x0, 14, x0 + 6, 64), wood, light=(-1, 0))
    arch = c.mask()
    for k in range(40):
        a = math.pi + k / 39 * math.pi
        x, y = 26 + math.cos(a) * 20, 18 + math.sin(a) * 12
        c.ellipse(x, y, 3.2, 3.2, arch)
    c.shade(arch, wood)
    # дверца-штакетник
    for x in range(12, 40, 6):
        m = c.poly([(x, 30), (x + 2.5, 26), (x + 5, 30), (x + 5, 60), (x, 60)])
        c.shade(m, ramp("c7a473", 5, 0.5), gy=0.25)
    c.fill(c.rect(11, 36, 41, 38), wood[1])
    c.fill(c.rect(11, 52, 41, 54), wood[1])
    # вьюнок с цветами по арке
    for k in range(26):
        a = math.pi + k / 25 * math.pi
        x, y = 26 + math.cos(a) * 21 + math.sin(k) * 2, 18 + math.sin(a) * 13
        lm = c.ellipse(x, y, 2.6, 2)
        c.fill(lm, hx("5d8f4e"))
        if k % 4 == 1:
            c.dot(int(x), int(y) - 1, hx("f2b7c8")); c.dot(int(x) + 1, int(y) - 1, hx("fbe0e8"))
        if k % 4 == 3:
            c.dot(int(x), int(y) - 1, hx("f6e7a1"))
    for side in (6, 44):
        for k in range(12):
            y = 22 + k * 3.4
            c.fill(c.ellipse(side + (2 if k % 2 else 0), y, 2.4, 1.8), hx("5d8f4e"))
    c.outline(BROWN_OL)
    save(c, "by29_gate_front")


# ============================================================ инструменты: мотыга и лейка
def tools():
    def hoe(size, name):
        k = size / 24.0
        c = Canvas(size, size)
        c.line([(4 * k, 21 * k), (17 * k, 6 * k)], hx("9a6b42"), max(2, int(2 * k)))
        c.line([(5 * k, 21 * k), (17 * k, 7 * k)], hx("c9955e"), 1)
        blade = c.poly([(14 * k, 3 * k), (21 * k, 4 * k), (22 * k, 10 * k), (18 * k, 11 * k), (17 * k, 7 * k)])
        c.shade(blade, ramp("9aa0ad", 5, 0.5))
        c.outline((*hx("2a2430"), 255))
        save(c, name)
    def can(size, name):
        k = size / 24.0
        c = Canvas(size, size)
        body = c.poly([(6 * k, 9 * k), (17 * k, 9 * k), (18 * k, 21 * k), (5 * k, 21 * k)])
        c.shade(body, ramp("6c9fb8", 5, 0.5), light=(-1, -1), gy=0.2)
        c.line([(6 * k, 14 * k), (17 * k, 14 * k)], hx("4b7a92"))
        spout = c.line_mask([(16 * k, 17 * k), (22 * k, 8 * k)], max(2, int(2 * k)))
        c.fill(spout, hx("5a8ca6"))
        c.fill(c.ellipse(22 * k, 7.5 * k, 2 * k, 1.5 * k), hx("8fc0d6"))
        handle = c.line_mask([(7 * k, 9 * k), (9 * k, 4 * k), (15 * k, 4 * k), (16 * k, 9 * k)], max(1, int(1.5 * k)))
        c.fill(handle & ~body, hx("4b7a92"))
        c.dot(8 * k, 11 * k, hx("d6eef8"))
        c.outline((*hx("23303a"), 255))
        save(c, name)
    hoe(24, "icon_hoe"); hoe(32, "gear_hoe")
    can(24, "icon_watering_can"); can(32, "gear_watering_can")
    # лейка в руке над головой для полива — маленькая
    can(16, "by29_can_small")


# ============================================================ значки погоды
def weather_icons():
    def sun(c):
        m = c.ellipse(13, 13, 6, 6)
        c.shade(m, ramp("f2c14e", 5, 0.5))
        for a in range(8):
            ang = a * math.pi / 4
            c.line([(13 + math.cos(ang) * 8, 13 + math.sin(ang) * 8), (13 + math.cos(ang) * 11, 13 + math.sin(ang) * 11)], hx("e9a23b"))
    def cloud(c, col="e8e4dc", dy=0):
        m = c.mask()
        for (x, y, r) in [(9, 14 + dy, 5), (15, 11 + dy, 6), (20, 15 + dy, 4.5), (13, 16 + dy, 5)]:
            c.ellipse(x, y, r, r * 0.9, m)
        c.shade(m, ramp(col, 5, 0.4), light=(0, -1))
    for kind in ["clear", "cloudy", "rain", "storm", "fog"]:
        c = Canvas(26, 26)
        if kind == "clear":
            sun(c)
        elif kind == "cloudy":
            c2 = Canvas(26, 26); sun(c2)
            c.px[:] = c2.px
            c.px[:, :, :] = np.roll(c.px, (-4, -4), (0, 1))
            cloud(c, dy=3)
        elif kind == "rain":
            cloud(c, "b9bcc4", -3)
            for x in (8, 13, 18):
                c.line([(x, 19), (x - 1, 23)], hx("6fa6d8"))
        elif kind == "storm":
            cloud(c, "8e909c", -3)
            c.fill(c.poly([(14, 15), (10, 21), (13, 21), (11, 25), (17, 18), (14, 18), (16, 15)]), hx("ffe37a"))
        elif kind == "fog":
            for y in (8, 13, 18):
                c.line([(4, y), (22, y)], hx("d8d4cc"), 2)
        c.outline((*hx("3a3440"), 255))
        save(c, "wx29_" + kind)


if __name__ == "__main__":
    backyard_bg()
    big_tree()
    soil()
    sprouts()
    mush_trees()
    props()
    tools()
    weather_icons()

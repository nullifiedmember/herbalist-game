# -*- coding: utf-8 -*-
"""v32: главное меню — живой фон-пейзаж и колонка меню слева, в стиле яблока.
Свет сверху-слева, плоские ступени тонов, цветной контур без чёрного.
Слои (холст 1000x560, в игре ×2, двигаются от мыши — параллакс):
  menu32_sky / _sky_dusk / _sky_night.png  небо днём, на закате, ночью (полосами); menu32_stars.png звёзды
  menu32_sun / _moon.png  солнце и луна — как кроны: клубы + мазки (их можно таскать мышкой)
  menu32_rays.png лучи-мазки (вращаются), menu32_sun_glow / _moon_glow.png сияние
  menu32_cloud_0..3.png  облака-кроны (плывут)
  menu32_far.png  дальние горы в дымке               menu32_mid.png  кромка леса за поляной
  menu32_near.png поляна: дом героини, пруд с мостками и кувшинками, деревья, тропинка
  menu32_windows.png свет в окнах дома (ночью)
  menu32_front.png большое дерево справа и кусты внизу (сильнее всех двигаются)
  menu32_bird_0/1.png  птичка (2 кадра)   menu32_smoke.png  клуб дыма из трубы
  menu32_panel.png колонка меню: пергамент, деревянная рейка с лозой (в игре ×2)
Запуск (из папки game):  python -I tools/menu32.py
"""
import json
import math
import os
import random
import sys

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ART = os.path.join(HERE, "..", "art")
sys.path.insert(0, os.path.join(os.path.expanduser("~"), ".claude", "skills", "apple-pixel-style", "scripts", "trees"))
import forest_tree as ft  # noqa: E402

W, H = 1000, 560
T = (0, 0, 0, 0)


def hx(s):
    s = s.lstrip("#")
    return (int(s[0:2], 16), int(s[2:4], 16), int(s[4:6], 16), 255)


def mix(a, b, t):
    return tuple(int(round(a[i] + (b[i] - a[i]) * t)) for i in range(3)) + (255,)


def new(w=W, h=H):
    return ft.Img(w, h)


def ridge(pts, w=W, wob=0.0, seed=0):
    """Высота гребня для каждого x: плавная (косинусная) линия через точки + мелкая волна."""
    ys = []
    for x in range(w):
        for i in range(len(pts) - 1):
            (x0, y0), (x1, y1) = pts[i], pts[i + 1]
            if x0 <= x <= x1:
                t = (x - x0) / float(x1 - x0)
                t = (1 - math.cos(t * math.pi)) / 2
                y = y0 + (y1 - y0) * t
                break
        else:
            y = pts[-1][1]
        y += wob * math.sin(x * 0.09 + seed) + wob * 0.5 * math.sin(x * 0.23 + seed * 2)
        ys.append(int(round(y)))
    return ys


def shade_ground(img, ys, rp, rim=True, depth_k=1.0, seed=0, top_t=None):
    """Земля под гребнем: тон по сглаженному наклону (подъём вправо смотрит на свет) и глубине.
    Полосы тонов идут вдоль гребня; светлая кромка сверху."""
    n = len(rp)
    w = img.w
    lits = []
    for x in range(w):
        a, b = max(0, x - 14), min(w - 1, x + 14)
        lits.append(max(-1.0, min(1.0, -(ys[b] - ys[a]) / float(b - a) * 1.6)))
    sm = []
    for x in range(w):
        a, b = max(0, x - 10), min(w, x + 11)
        sm.append(sum(lits[a:b]) / float(b - a))
    for x in range(w):
        y0 = ys[x]
        lit = sm[x]
        for y in range(max(0, y0), img.h):
            d = y - y0
            v = 0.60 + lit * 0.22 - d * 0.0011 * depth_k
            v += 0.018 * math.sin(x * 0.010 + y * 0.012 + seed) + 0.015 * math.sin(x * 0.004 - y * 0.008 + seed * 3)
            t = int(max(0, min(n - 2, round(v * (n - 1)))))
            if rim and d < 2:
                t = min(n - 1, t + 2) if lit > -0.2 else min(n - 1, t + 1)
            elif rim and d < 5 and lit > 0.05:
                t = min(n - 1, t + 1)
            if top_t is not None:
                t = min(t, top_t)
            img.px(x, y, rp[t])


def grass_texture(img, ys, rp, rng, count, y_lo=3, y_hi=200):
    """Травинки-мазки: короткие вертикальные штрихи на тон светлее/темнее (не пупырышки)."""
    for _ in range(count):
        x = rng.randrange(2, img.w - 2)
        y = ys[x] + rng.randint(y_lo, y_hi)
        if y >= img.h - 1 or img.a(x, y) < 0.5:
            continue
        c = img.p[x, y]
        try:
            t = rp.index(c)
        except ValueError:
            continue
        up = rng.random() < 0.55
        tt = max(0, min(len(rp) - 1, t + (1 if up else -1)))
        L = rng.randint(2, 4)
        lean = rng.choice((-1, 0, 0, 1))
        for k in range(L):
            xx = x + (lean if k == L - 1 else 0)
            if img.a(xx, y - k) > 0.5:
                img.px(xx, y - k, rp[tt])


def flower(img, x, y, kind):
    pal = {
        "white": ("fffaf4", "f0e2ea", "f6c85a"), "pink": ("ffc8d8", "e892b0", "fff2b0"),
        "yellow": ("ffe880", "f0b84a", "fff8d0"), "lilac": ("dcc4f4", "b090d8", "fff2b0"),
        "blue": ("b8d8ff", "7aa2e0", "fff6c0"),
    }[kind]
    lt, dk, mid = hx(pal[0]), hx(pal[1]), hx(pal[2])
    img.px(x, y + 1, hx("3a7a52"))
    img.px(x, y + 2, hx("3a7a52"))
    img.px(x - 1, y, lt)
    img.px(x, y - 1, lt)
    img.px(x + 1, y, dk)
    img.px(x, y + 1, dk)
    img.px(x, y, mid)


def paste(dst, src, x, y):
    """Наложить картинку (низ-центр в x,y) с учётом прозрачности."""
    sx, sy = int(x - src.width / 2), int(y - src.height)
    dst.im.alpha_composite(src, (max(0, sx), max(0, sy)), (max(0, -sx), max(0, -sy)))


# ------------------------------------------------------------------ небо и солнце

# ------------------------------------------------------------------ небо: день, закат, ночь, звёзды
def sky_bands(cols, y_end=390):
    img = new()
    bands = [hx(c) for c in cols]
    for y in range(H):
        f = min(1.0, y / float(y_end)) * (len(bands) - 1)
        i = int(f)
        fr = f - i
        for x in range(W):
            c = bands[min(i, len(bands) - 1)]
            if fr > 0.82 and i + 1 < len(bands) and (x + y) % 2 == 0:   # граница полос — шахматкой
                c = bands[i + 1]
            img.p[x, y] = c
    return img.im


def sky_day():
    return sky_bands(("74acd8", "82b8de", "92c4e4", "a4cfe8", "b8daea", "cde3ea", "e2eae2", "f4ecd4", "fde6c4"))


def sky_dusk():
    return sky_bands(("4a4c8c", "604f98", "7c56a0", "9e5ea2", "c46c98", "e2808c", "f49c80", "fcbc84", "ffd896"))


def sky_night():
    return sky_bands(("0c1230", "111a3c", "162246", "1c2a52", "22335c", "2a3c66", "33466e", "3d5076", "4a5a7c"))


def stars():
    img = new()
    rng = random.Random(17)
    for _ in range(260):
        x, y = rng.randrange(W), rng.randrange(0, 330)
        c = rng.choice(("fffbe6", "e6ecff", "fff0c8", "d8e2ff"))
        img.px(x, y, hx(c))
        if rng.random() < 0.18:                         # звёздочка-крестик
            for (dx, dy) in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                img.px(x + dx, y + dy, hx("a8b4e8"))
    return img.im


def glow(r_outer, col, ks=(0.5, 0.32, 0.18, 0.08)):
    S = r_outer * 2 + 2
    img = new(S, S)
    c = S / 2.0
    rings = [r_outer * f for f in (0.48, 0.65, 0.84, 1.0)]
    base = hx(col)
    for y in range(S):
        for x in range(S):
            d = math.hypot(x + 0.5 - c, y + 0.5 - c)
            for rr, k in zip(rings, ks):
                if d <= rr:
                    img.px(x, y, (base[0], base[1], base[2], int(255 * k)))
                    break
    return img.im


# ------------------------------------------------------------------ солнце и луна — как кроны: клубы + мазки
def round_canopy(S, R, rp, seed, nring=8, L=5.6, W_=4.4, sp=3.0, droop=0.0):
    img = new(S, S)
    c = S / 2.0
    cl = []
    for i in range(nring):
        a = i / float(nring) * math.tau + 0.4
        k = 0.9 + 0.2 * ft.h01(i, seed, 1)
        cl.append((c + math.cos(a) * R * 0.52, c + math.sin(a) * R * 0.52, R * 0.5 * k, R * 0.5 * k))
    cl.append((c, c, R * 0.64, R * 0.64))
    cl.sort(key=lambda q: q[1])
    ft.leaf_canopy(img, cl, rp, seed, L, W_, sp, droop)
    return img


def sun():
    rp = ft.ramp("b8484a", "dc6a48", "f09048", "f8b84e", "fcd866", "fff0a0", "fffbe2")
    img = round_canopy(100, 36, rp, 7)
    ft.clean_specks(img)
    ft.outline_auto(img, 0.4)
    return img.im


def moon():
    rp = ft.ramp("4a4a7a", "62669a", "7e86b6", "a0a8cc", "c4cae0", "e2e4ee", "fbf8f0")
    img = round_canopy(84, 29, rp, 23, nring=7, L=5.0, W_=4.0, sp=2.8)
    for (x, y, r) in ((36, 38, 5.0), (50, 48, 3.6), (40, 54, 2.6), (52, 32, 2.2)):   # кратеры
        for yy in range(int(y - r) - 1, int(y + r) + 2):
            for xx in range(int(x - r) - 1, int(x + r) + 2):
                d = math.hypot(xx + 0.5 - x, yy + 0.5 - y)
                if d <= r and img.a(xx, yy) > 0.5:
                    side = (xx - x) * 0.6 + (yy - y) * 0.8
                    img.px(xx, yy, rp[5] if (d > r - 1.2 and side > 0) else rp[2] if (d > r - 1.2) else rp[3])
    ft.clean_specks(img)
    ft.outline_auto(img, 0.4)
    return img.im


def rays():
    """Лучи-мазки вокруг солнца: заострённые листья-штрихи наружу, длинные и короткие."""
    S = 200
    img = new(S, S)
    c = S / 2.0
    rp = ft.ramp("f09048", "f8b84e", "fcd866", "fde58a", "fff0a8", "fff7cc", "fffbe2")
    n = 14
    for i in range(n):
        a = i / float(n) * math.tau
        long_ = i % 2 == 0
        L = 26.0 if long_ else 17.0
        r0 = 41.0
        d = (math.cos(a), math.sin(a))
        ctr = (c + d[0] * (r0 + L * 0.45), c + d[1] * (r0 + L * 0.45))
        lit = -(d[0] * 0.62 + d[1] * 0.78)
        ft.draw_leaf(img, ctr, d, L, 6.0 if long_ else 5.0, 4 if lit > 0 else 3, rp)
    ft.outline_auto(img, 0.25)
    return img.im


def cloud(w, h, seed):
    """Облако как крона: нижний ряд плоских клубов + пышные верхние, мазки-завитки, без плоского дна."""
    rng = random.Random(seed)
    pad = 12
    img = new(w + pad * 2, h + pad * 2)
    cl = []
    n = max(3, w // 30)
    for i in range(n):
        t = (i + 0.5) / n
        cl.append((pad + t * w + rng.uniform(-3, 3), pad + h * 0.70 + rng.uniform(-2, 2),
                   w / n * 0.78, h * rng.uniform(0.24, 0.32)))
    m = max(2, w // 60)
    for i in range(m):
        t = (i + 0.5) / m
        tt = 0.22 + 0.56 * t
        hh = 1.0 - abs(tt - 0.5) * 1.1
        cl.append((pad + tt * w + rng.uniform(-6, 6), pad + h * (0.52 - 0.12 * hh), w * rng.uniform(0.16, 0.22),
                   h * (0.30 + 0.16 * hh)))
    cl.sort(key=lambda q: q[1])
    rp = ft.ramp("7a7cb4", "9498c8", "b2b8dc", "ced4ec", "e6eaf6", "f6f8fd", "ffffff")
    ft.leaf_canopy(img, cl, rp, seed, 7.0, 5.6, 3.5, 0.12)
    ft.clean_specks(img)
    ft.outline_auto(img, 0.3)
    return img.im


# ------------------------------------------------------------------ дальние горы
def far():
    img = new()
    ys1 = ridge([(0, 296), (120, 268), (230, 290), (350, 246), (470, 284), (600, 258), (720, 292), (850, 262), (1000, 286)],
                wob=1.2, seed=1)
    rp1 = [hx(c) for c in ("a4a8d4", "b2b8de", "c0c8e6", "cfd6ec", "dde3f0")]
    shade_ground(img, ys1, rp1, depth_k=0.6, seed=2)
    ys2 = ridge([(0, 334), (180, 320), (340, 336), (520, 316), (700, 332), (880, 318), (1000, 328)], wob=1.5, seed=4)
    rp2 = [hx(c) for c in ("86a8b8", "94b6c0", "a4c4c8", "b6d2cc", "c8ded2")]
    shade_ground(img, ys2, rp2, depth_k=0.6, seed=5)
    return img.im


# ------------------------------------------------------------------ кромка леса за поляной
def mid():
    img = new()
    ys = ridge([(0, 388), (300, 384), (600, 390), (1000, 386)], wob=1.0, seed=9)
    haze = hx("cfe0d4")
    rp = [mix(c, haze, 0.25) for c in ft.LEAF["green"]]
    shade_ground(img, ys, rp, depth_k=0.8, seed=3)
    rng = random.Random(31)
    lay = new()
    row = []
    x = 280
    i = 0
    while x < 1030:                                  # задний ряд: ели и липы, плотно
        if i % 3 == 1:
            tim = ft.broad_tree(84, 106, "deep", 100 + i)
        else:
            tim = ft.pine_tree(rng.choice((46, 52, 58)), rng.choice((92, 104, 116)), "pine", 200 + i)
        row.append((ys[min(W - 1, x)] + 2 + rng.randint(-3, 3), tim, x))
        x += rng.randint(26, 38)
        i += 1
    row.sort(key=lambda r: r[0])
    for (by, tim, xx) in row:
        paste(lay, tim, xx, by)
    px = lay.im.load()
    for yy in range(H):                               # дымка на заднем ряду
        for xx in range(W):
            c = px[xx, yy]
            if c[3]:
                px[xx, yy] = mix(c, haze, 0.22)[:3] + (c[3],)
    img.im.alpha_composite(lay.im)
    return img.im


# ------------------------------------------------------------------ поляна: дом, пруд с мостками, тропинка
def house_small(width):
    src = Image.open(os.path.join(ART, "house.png")).convert("RGBA")
    k = width / src.width
    sm = src.resize((width, int(src.height * k)), Image.BOX)
    px = sm.load()
    for y in range(sm.height):
        for x in range(sm.width):
            c = px[x, y]
            px[x, y] = (c[0], c[1], c[2], 255) if c[3] >= 110 else T
    return sm, k


POND = (724, 482, 168, 44)


def in_pond(x, y, wob=True):
    cx, cy, rx, ry = POND
    e = 1.0 + (0.05 * math.sin(x * 0.07) + 0.03 * math.sin(x * 0.19 + 1) if wob else 0.0)
    return ((x + 0.5 - cx) / rx) ** 2 + ((y + 0.5 - cy) / ry) ** 2 <= e


def near():
    img = new()
    ys = ridge([(260, 404), (420, 398), (620, 404), (820, 398), (1000, 402)], wob=0.8, seed=13)
    rp = ft.LEAF["green"]
    shade_ground(img, ys, rp, depth_k=1.0, seed=7)
    rng = random.Random(21)
    grass_texture(img, ys, rp, rng, 4200, 3, 160)
    # пруд: у дальнего берега — отражение леса, дальше небо, рябь, блики
    water = [hx(c) for c in ("2e5a6e", "3e7290", "4f8aac", "68a4c6", "8cc0dc", "b8dcec", "e6f6fa")]
    refl = [hx(c) for c in ("2a4a4a", "345a52", "3f6a5a")]
    sand = [hx(c) for c in ("8e6a54", "b08a66", "cfae80", "e6cc9c")]
    cx, cy, rx, ry = POND
    for y in range(cy - ry - 6, cy + ry + 6):
        for x in range(cx - rx - 10, cx + rx + 10):
            if in_pond(x, y):
                f = (y - (cy - ry)) / (2.0 * ry)
                if f < 0.18:
                    c = refl[int(f / 0.18 * 3) % 3]
                else:
                    t = 2 + int((f - 0.18) / 0.82 * 3.2)
                    c = water[min(4, t)]
                img.px(x, y, c)
    for _ in range(90):                                # рябь — короткие светлые штрихи
        x, y = rng.randrange(cx - rx, cx + rx), rng.randrange(cy - ry + 10, cy + ry)
        L = rng.randint(3, 9)
        if all(in_pond(x + k, y) for k in range(L)):
            for k in range(L):
                img.px(x + k, y, water[5] if k not in (0, L - 1) else water[4])
    src = img.im.copy().load()
    for y in range(cy - ry - 8, cy + ry + 8):          # берег: песок, светлый сверху-слева
        for x in range(cx - rx - 12, cx + rx + 12):
            if in_pond(x, y):
                continue
            near_w = any(in_pond(x + dx, y + dy) for (dx, dy) in ((1, 0), (-1, 0), (0, 1), (0, -1), (0, 2), (0, -2)))
            if near_w:
                below = in_pond(x, y + 1) or in_pond(x, y + 2)
                img.px(x, y, sand[3] if below else sand[1])
    # кувшинки
    for (lx, ly) in ((660, 492), (700, 504), (800, 470), (770, 512), (846, 494)):
        for yy in range(ly - 3, ly + 4):
            for xx in range(lx - 6, lx + 7):
                d = ((xx + 0.5 - lx) / 6.0) ** 2 + ((yy + 0.5 - ly) / 3.0) ** 2
                notch = xx > lx and abs(yy - ly) <= (xx - lx) * 0.4 and yy <= ly
                if d <= 1.0 and not notch:
                    v = -(xx - lx) * 0.1 - (yy - ly) * 0.3
                    img.px(xx, yy, hx("8cc46a") if v > 0.3 else hx("5aa05a") if v > -0.4 else hx("3f7a4e"))
        if (lx + ly) % 3 == 0:
            flower(img, lx - 2, ly - 2, "pink")
    # мостки: доски от левого берега
    wood = [hx(c) for c in ("5c3c34", "7a5444", "9c6e52", "bc8c64", "d8ac7c")]
    for x in range(560, 640):
        for y in range(470, 482):
            u = (x - 560) % 8
            t = 4 if y == 470 else 1 if y == 481 else (3 if u < 6 else 2)
            if u == 7:
                t = 1
            img.px(x, y, wood[t])
    for px_ in (566, 598, 632):
        for y in range(482, 494):
            img.px(px_, y, wood[1])
            img.px(px_ + 1, y, wood[0])
    # тропинка от двери к мосткам и вниз
    dirt = [hx(c) for c in ("6e4a44", "8e6250", "b08060", "cca276", "e4c494")]
    door = (452, 400)
    for pts in ([(452, 402), (470, 430), (520, 452), (566, 474)], [(470, 430), (440, 480), (420, 530), (412, 566)]):
        for i in range(len(pts) - 1):
            (x0, y0), (x1, y1) = pts[i], pts[i + 1]
            steps = int(math.hypot(x1 - x0, y1 - y0) * 2)
            for s in range(steps):
                t = s / float(steps)
                x, y = x0 + (x1 - x0) * t, y0 + (y1 - y0) * t
                wdt = 5 + (y - 400) / 166.0 * 9
                hgt = max(2.0, wdt * 0.45)
                for yy in range(int(y - hgt), int(y + hgt) + 1):
                    for xx in range(int(x - wdt), int(x + wdt) + 1):
                        dx, dy = (xx + 0.5 - x) / wdt, (yy + 0.5 - y) / hgt
                        if dx * dx + dy * dy <= 1.0 and not in_pond(xx, yy):
                            img.px(xx, yy, dirt[2] if (-dx * 0.5 - dy * 0.8) < 0.2 else dirt[3])
    objs = []
    hs, k = house_small(150)
    objs.append((door[1], hs, door[0]))
    chim = (door[0] - hs.width / 2 + 214 * k, door[1] - hs.height + 6 * k)
    for (tim, x, dy) in ((ft.broad_tree(120, 150, "field", 71, extra="apples"), 330, 4),
                         (ft.pine_tree(60, 116, "pine", 5), 560, 0), (ft.broad_tree(100, 128, "pink", 51, extra="blossom"), 610, 2),
                         (ft.pine_tree(52, 100, "pine", 15), 900, -2)):
        objs.append((ys[x] + 6 + dy, tim, x))
    for (x, seed, look) in ((372, 3, "meadow"), (520, 8, "meadow"), (944, 4, "field")):
        objs.append((ys[x] + 12, ft.bush(look, seed), x))
    objs.sort(key=lambda o: o[0])
    for (by, im, x) in objs:
        paste(img, im, x, by)
    # окна дома для ночного света (маска того же размера, что слой)
    glow_l = new()
    hx0, hy0 = int(door[0] - hs.width / 2), int(door[1] - hs.height)
    win = {(239, 170, 68), (252, 198, 96), (220, 140, 48)}        # стёкла окон в house.png (солома крыши — другие цвета)
    src_h = Image.open(os.path.join(ART, "house.png")).convert("RGBA")
    sp_ = src_h.load()
    m = Image.new("L", src_h.size, 0)
    mp_ = m.load()
    for y in range(src_h.height):
        for x in range(src_h.width):
            if sp_[x, y][3] and sp_[x, y][:3] in win:
                mp_[x, y] = 255
    m = m.resize(hs.size, Image.BOX).load()
    for y in range(hs.height):
        for x in range(hs.width):
            if m[x, y] >= 90:
                for (dx, dy, a) in ((0, 0, 255), (1, 0, 110), (-1, 0, 110), (0, 1, 110), (0, -1, 110)):
                    xx, yy = hx0 + x + dx, hy0 + y + dy
                    if glow_l.a(xx, yy) * 255 < a:
                        glow_l.px(xx, yy, (255, 196, 110, a))
    # цветы кучками
    kinds = ["white", "pink", "yellow", "lilac", "blue", "white", "yellow"]
    for _ in range(50):
        cx0 = rng.randrange(300, W - 10)
        cy0 = ys[cx0] + rng.randint(14, 160)
        kind = rng.choice(kinds)
        for _ in range(rng.randint(3, 7)):
            x, y = cx0 + rng.randint(-9, 9), cy0 + rng.randint(-4, 4)
            if 0 < x < W - 2 and 3 < y < H - 3 and all(img.p[x + dx, y + dy] in rp for (dx, dy) in ((0, 0), (0, -2), (1, 0), (-1, 0))):
                flower(img, x, y, kind)
    # камыш у правого берега
    for i in range(16):
        x = 866 + i * 2 + rng.randint(-1, 1)
        L = rng.randint(14, 26)
        for k2 in range(L):
            img.px(x, 490 - k2, rp[3] if k2 < L - 5 else rp[4])
        if i % 3 == 0:
            for k2 in range(4):
                img.px(x, 490 - L - k2, hx("8a5a40"))
                img.px(x + 1, 490 - L - k2, hx("6a4434"))
    return img.im, glow_l.im, chim


def front():
    """Передний план: большое дерево справа (рамка) и кусты с травой внизу."""
    img = new()
    paste(img, ft.broad_tree(232, 300, "meadow", 41, big=True), 992, 592)
    paste(img, ft.bush("meadow", 12, 150, 96), 330, H + 26)
    paste(img, ft.bush("deep", 5, 110, 74), 880, H + 24)
    rng = random.Random(5)
    rp = ft.LEAF["green"]
    for _ in range(90):
        x = rng.choice((rng.randrange(290, 470), rng.randrange(800, W)))
        L = rng.randint(12, 30)
        lean = rng.uniform(-0.5, 0.25)
        t = rng.choice((2, 3, 4, 5))
        for k in range(L):
            xx = int(x + lean * k * k / L)
            img.px(xx, H - 1 - k, rp[t if k < L - 3 else t + 1])
            if k < L * 0.6:
                img.px(xx + 1, H - 1 - k, rp[t - 1])
    return img.im


def bird(frame):
    img = new(11, 6)
    c, cl = hx("5a4a72"), hx("7a6a94")
    if frame == 0:
        pts = [(0, 1), (1, 1), (2, 2), (3, 2), (4, 3), (5, 3), (6, 3), (7, 2), (8, 2), (9, 1), (10, 1), (5, 4)]
    else:
        pts = [(0, 4), (1, 4), (2, 3), (3, 3), (4, 3), (5, 3), (6, 3), (7, 3), (8, 3), (9, 4), (10, 4), (5, 4)]
    for (x, y) in pts:
        img.px(x, y, c)
    img.px(5, 2, cl)
    return img.im


def smoke():
    img = new(12, 12)
    rp = [hx(c) for c in ("c8c4dc", "e2e0ee", "f6f6fc")]
    for y in range(12):
        for x in range(12):
            dx, dy = (x + 0.5 - 6) / 5.5, (y + 0.5 - 6) / 5.5
            if dx * dx + dy * dy <= 1.0:
                v = -dx * 0.6 - dy * 0.8
                img.px(x, y, rp[0] if v < -0.3 else rp[1] if v < 0.35 else rp[2])
    return img.im


# ------------------------------------------------------------------ колонка меню
def panel():
    PW, PH = 296, 540
    img = new(PW, PH)
    paper = [hx(c) for c in ("dcc297", "e9d4ac", "f6e9cc", "fff7e4")]
    wood = [hx(c) for c in ("6e4636", "845a40", "9c6a48", "bf8a58", "d9a873", "ecc48e")]
    edge = 280
    rng = random.Random(3)
    for y in range(PH):
        for x in range(edge):
            c = paper[2]
            if x > edge - 8 or y < 4 or y > PH - 5:
                c = paper[1]
            img.p[x, y] = c
    for _ in range(320):                               # волокна бумаги — короткие штрихи
        x, y, L = rng.randrange(4, edge - 12), rng.randrange(6, PH - 6), rng.randint(3, 7)
        for k in range(L):
            img.px(x + k, y, paper[1] if rng.random() < 0.85 else paper[3])
    # деревянная рейка справа
    for y in range(PH):
        for x in range(edge, edge + 12):
            u = x - edge
            t = 5 if u == 1 else 4 if u < 4 else 3 if u < 8 else 2 if u < 11 else 1
            if u == 0 or u == 11:
                t = 0
            g = math.sin(y * 0.11 + u * 0.9 + math.sin(y * 0.031) * 3)
            if 2 <= u <= 10 and g > 0.93:
                t = max(1, t - 1)
            img.p[x, y] = wood[t]
    for y in range(0, PH, 90):                         # сучки
        y2 = y + 40
        for (dx, dy, t) in ((5, 0, 1), (6, 0, 2), (5, 1, 2), (6, 1, 3), (4, 0, 2)):
            img.px(edge + dx, y2 + dy, wood[t])
    # тень рейки на картину
    for y in range(PH):
        for (x, a) in ((edge + 12, 90), (edge + 13, 60), (edge + 14, 34), (edge + 15, 16)):
            img.px(x, y, (51, 41, 82, a))
    # лоза по рейке: стебель, листики (мазки как в кроне), цветочки
    leaf = ft.LEAF["green"]
    stem = hx("4f7a48")
    prev = None
    for y in range(PH):
        x = edge + 6 + 5.5 * math.sin(y / 23.0) + 1.5 * math.sin(y / 7.0)
        img.px(int(x), y, stem)
        img.px(int(x) + 1, y, hx("365e40"))
        prev = (x, y)
    for i, y in enumerate(range(8, PH - 6, 15)):
        x = edge + 6 + 5.5 * math.sin(y / 23.0) + 1.5 * math.sin(y / 7.0)
        side = -1 if i % 2 == 0 else 1
        d = (side * 1.0, 0.55)
        ft.draw_leaf(img, (x + side * 4.5, y + 2.5), d, 8.0, 5.2, 4 if side < 0 else 3, leaf)
        if i % 3 == 1:
            fx, fy = int(x + side * 2), y - 4
            flower(img, fx, fy, "pink" if i % 2 else "white")
    # верхний угол: пучок листьев
    for (cx, cy, dx, dy, t) in ((edge - 4, 6, -1, 0.3, 4), (edge - 10, 12, -1, 0.7, 3), (edge + 2, 14, 0.2, 1, 5),
                                (edge - 2, 20, -0.6, 1, 4), (edge - 4, PH - 10, -1, -0.4, 3), (edge - 9, PH - 4, -1, -0.1, 4)):
        ft.draw_leaf(img, (cx, cy), (dx, dy), 9.0, 6.0, t, leaf)
    # разделитель под названием: веточка с листиком
    yd = 128
    for x in range(40, 240):
        y = yd + int(round(1.2 * math.sin((x - 40) / 32.0)))
        img.px(x, y, wood[2])
        img.px(x, y + 1, wood[3] if x % 9 else wood[2])
    for (cx, side) in ((90, -1), (190, 1)):
        ft.draw_leaf(img, (cx, yd - 4), (side * 0.6, -1), 8.0, 5.0, 4, leaf)
        ft.draw_leaf(img, (cx + side * 8, yd + 5), (side * 0.7, 1), 7.0, 4.6, 3, leaf)
    for (dx, dy, c) in ((-1, 0, "ffc8d8"), (1, 0, "e892b0"), (0, -1, "ffe0ea"), (0, 1, "e892b0"), (0, 0, "fff2b0")):
        img.px(140 + dx, yd - 1 + dy, hx(c))
    return img.im


def main():
    def save(name, im):
        im.save(os.path.join(ART, name + ".png"))
        print("ok", name, im.size)

    save("menu32_sky", sky_day())
    save("menu32_sky_dusk", sky_dusk())
    save("menu32_sky_night", sky_night())
    save("menu32_stars", stars())
    save("menu32_sun_glow", glow(110, "fff4cc"))
    save("menu32_moon_glow", glow(80, "d8e0ff", (0.30, 0.18, 0.10, 0.05)))
    save("menu32_sun", sun())
    save("menu32_moon", moon())
    save("menu32_rays", rays())
    for i, (w, h, s) in enumerate(((150, 50, 1), (110, 40, 2), (190, 58, 3), (90, 34, 4))):
        save("menu32_cloud_%d" % i, cloud(w, h, s))
    save("menu32_far", far())
    save("menu32_mid", mid())
    n, g, chim = near()
    save("menu32_near", n)
    save("menu32_windows", g)
    save("menu32_front", front())
    save("menu32_bird_0", bird(0))
    save("menu32_bird_1", bird(1))
    save("menu32_smoke", smoke())
    save("menu32_panel", panel())
    print(json.dumps({"chimney": [round(chim[0], 1), round(chim[1], 1)]}))
    prev = os.environ.get("MENU32_PREVIEW")
    if prev:
        full = Image.open(os.path.join(ART, "menu32_sky.png")).convert("RGBA")
        sun_c = (560, 120)
        for nm, c in (("sun_glow", sun_c), ("rays", sun_c), ("sun", sun_c)):
            im = Image.open(os.path.join(ART, "menu32_%s.png" % nm))
            full.alpha_composite(im, (c[0] - im.width // 2, c[1] - im.height // 2))
        for i, (x, y) in enumerate(((380, 60), (760, 170), (640, 40), (880, 90))):
            full.alpha_composite(Image.open(os.path.join(ART, "menu32_cloud_%d.png" % i)), (x, y))
        for nm in ("far", "mid", "near", "front"):
            full.alpha_composite(Image.open(os.path.join(ART, "menu32_%s.png" % nm)))
        full.alpha_composite(Image.open(os.path.join(ART, "menu32_panel.png")), (0, 10))
        full.resize((W * 2, H * 2), Image.NEAREST).save(prev)
        big = Image.new("RGBA", (300, 110), (120, 170, 220, 255))
        for i, nm in enumerate(("sun", "moon")):
            im = Image.open(os.path.join(ART, "menu32_%s.png" % nm))
            big.alpha_composite(im, (10 + i * 110, 5))
        big.alpha_composite(Image.open(os.path.join(ART, "menu32_cloud_1.png")), (200, 30))
        big.resize((1200, 440), Image.NEAREST).save(prev.replace(".png", "_x4.png"))


if __name__ == "__main__":
    main()

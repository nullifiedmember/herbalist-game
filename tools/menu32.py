# -*- coding: utf-8 -*-
"""v32: главное меню — живой фон-пейзаж и колонка меню слева, в стиле яблока.
Свет сверху-слева, плоские ступени тонов, цветной контур без чёрного.
Слои (холст 1000x560, в игре ×2, всё в одной плоскости — без параллакса):
  menu32_sky / _sky_dusk / _sky_night.png  небо днём, на закате, ночью (полосами); menu32_stars.png звёзды
  menu32_sun / _moon.png  солнце и луна — как кроны: клубы + мазки (их можно таскать мышкой)
  menu32_rays.png лучи-мазки (вращаются), menu32_sun_glow / _moon_glow.png сияние
  menu32_cloud_0..3.png  облака-кроны (плывут)
  menu32_far.png  дальние горы в дымке               menu32_mid.png  кромка леса за поляной
  menu32_near.png поляна: земля, тропа и пруд берутся из игры (art/ground.png), дом героини, деревья, цветы
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


def BT(*a, **k):
    return ft.broad_tree(*a, pad=18, **k)      # запас по бокам — крона не обрезается


def PT(*a, **k):
    return ft.pine_tree(*a, pad=14, **k)


def BU(*a, **k):
    return ft.bush(*a, pad=10, **k)

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


def rays(n=16, seed=5, S=320, r0=30.0, lmin=48.0, lmax=118.0, w0=7.5, amax=150, col="fff1a8", core="fffbe6", phase=0.0):
    """v36: лучи солнца — длинные клинья разной длины, сужаются к концу и тают ступенями
    с пиксельным дизерингом (шахматка на границе ступеней), у длинных — светлая сердцевина.
    Два таких слоя крутятся навстречу друг другу — свет «переливается»."""
    img = new(S, S)
    c = S / 2.0
    rnd = random.Random(seed)
    specs = []
    for i in range(n):
        a = (i + phase + rnd.uniform(-0.22, 0.22)) / float(n) * math.tau
        k = rnd.uniform(0.82, 1.08)
        L = (lmax if i % 2 == 0 else lmin * rnd.uniform(0.9, 1.5)) * k
        specs.append((a, L, w0 * (1.0 if i % 2 == 0 else 0.7)))
    base, cr = hx(col), hx(core)
    for y in range(S):
        for x in range(S):
            dx, dy = x + 0.5 - c, y + 0.5 - c
            d = math.hypot(dx, dy)
            if d < r0:
                continue
            ang = math.atan2(dy, dx)
            best = None
            for (a, L, w) in specs:
                t = (d - r0) / L
                if t > 1.0:
                    continue
                da = (ang - a + math.pi) % math.tau - math.pi
                lat = abs(da) * d
                wl = w * (1.0 - t) ** 0.8 + 0.6
                if lat > wl:
                    continue
                v = (1.0 - t) * 4.0                      # 4 ступени яркости
                lv = int(v)
                if v - lv > 0.5 and (x + y) % 2 == 0:   # шахматка между ступенями
                    lv += 1
                lv = min(4, lv + 1)
                is_core = lat < wl * 0.32 and t < 0.55 and L > lmax * 0.7
                q = (lv, is_core)
                if best is None or q > best:
                    best = q
            if best is None:
                continue
            lv, is_core = best
            al = int(amax * lv / 4.0)
            if is_core:
                img.px(x, y, (cr[0], cr[1], cr[2], min(255, al + 50)))
            else:
                img.px(x, y, (base[0], base[1], base[2], al))
    return img.im


def rays_inner():
    """Второй слой: короткие тонкие лучи между длинными, бледнее."""
    return rays(n=12, seed=9, S=220, r0=30.0, lmin=22.0, lmax=50.0, w0=4.5, amax=115, col="ffe9a0", phase=0.5)


def sparkle(frame):
    """Искорка у конца луча: точка → крестик → звёздочка с косыми лучиками (кадры 0..2)."""
    S = 9
    img = new(S, S)
    c = 4
    wht, yel, gold = hx("fffdf0"), hx("fff0a0"), hx("f8c860")
    arm = (1, 2, 4)[frame]
    for i in range(1, arm + 1):
        col = yel if i < arm else gold
        for (sx, sy) in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            img.px(c + sx * i, c + sy * i, col)
    if frame == 2:
        for (sx, sy) in ((1, 1), (-1, 1), (1, -1), (-1, -1)):
            img.px(c + sx, c + sy, yel)
    img.px(c, c, wht)
    return img.im


def chimney_front(chim):
    """Верх трубы отдельной картинкой (те же пиксели, что в menu32_near) — в игре рисуется поверх дыма,
    и клубы выходят ИЗ трубы. Возвращает картинку и её левый верхний угол на холсте."""
    near_im = Image.open(os.path.join(ART, "menu32_near.png")).convert("RGBA")
    x0, y0 = int(chim[0]) - 16, int(chim[1]) - 6
    return near_im.crop((x0, y0, x0 + 32, y0 + 30)), (x0, y0)


def cloud(w, h, seed):
    """Облако как крона: нижний ряд плоских клубов + пышные верхние, мазки-завитки, без плоского дна."""
    rng = random.Random(seed)
    pad = 28
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
    rp = [mix(c, haze, 0.12) for c in ft.LEAF["green"]]
    shade_ground(img, ys, rp, depth_k=0.8, seed=3, top_t=3)    # земля за поляной — зелёная, без светлой полосы
    # чаща под кронами: тёмная тень леса между стволами (иначе там просвечивает светлая дымка)
    # земля под лесом — та же трава игры 1:1, что и на поляне; глубже — темнее и в дымке
    gp = Image.open(os.path.join(ART, "ground.png")).convert("RGBA").load()
    shade = hx("2f5a48")
    for x in range(260, W):
        top = ys[x] - 40
        for y in range(top, H):
            if y == top and x % 2:
                continue                                  # верхний край — шахматкой, не линейкой
            g = grass_1to1(gp, x + 211, y + 37)
            g = (g[0], g[1], g[2], 255)
            k = 0.42 if y < ys[x] - 14 else 0.18 + 0.12 * max(0.0, (NEAR_YS[x] - y) / 30.0)
            img.px(x, y, mix(mix(g, shade, k), haze, 0.12))
    # кустики травы из игры на лесной земле (между стволами), тоже чуть в тени
    srng = random.Random(91)
    short = [Image.open(os.path.join(ART, "grass_s%d.png" % i)).convert("RGBA") for i in range(6)]
    for _ in range(170):
        x = srng.randrange(262, W - 4)
        y = srng.randint(ys[x] - 8, NEAR_YS[x] + 2)
        im = srng.choice(short).copy()
        ip = im.load()
        for yy in range(im.height):
            for xx in range(im.width):
                c = ip[xx, yy]
                if c[3]:
                    ip[xx, yy] = mix(mix(c, shade, 0.2), haze, 0.12)[:3] + (c[3],)
        paste(img, im, x, y)
    # густой лес вглубь: два дальних ряда — чем дальше, тем выше, мельче, плотнее и сильнее в дымке
    for (lift, sc, step, hz, seed0) in ((30, 0.62, (12, 18), 0.50, 500), (16, 0.80, (16, 24), 0.34, 400)):
        frng = random.Random(seed0)
        flay = new()
        frow = []
        x = 262 + frng.randint(0, 8)
        j = 0
        while x < 1040:
            if frng.random() < 0.38:
                w_, h_ = int(84 * sc), int(104 * sc)
                tim = BT(w_, h_, "deep", seed0 + j)
            else:
                w_ = int(frng.choice((46, 52, 58)) * sc)
                tim = PT(w_, int(frng.choice((96, 108, 120)) * sc), "pine", seed0 + 100 + j)
            frow.append((ys[min(W - 1, x)] - lift + frng.randint(-4, 4), tim, x))
            x += frng.randint(*step)
            j += 1
        frow.sort(key=lambda r: r[0])
        for (by, tim, xx) in frow:
            paste(flay, tim, xx, by)
        fp = flay.im.load()
        for yy in range(H):
            for xx in range(W):
                c = fp[xx, yy]
                if c[3]:
                    fp[xx, yy] = mix(c, haze, hz)[:3] + (c[3],)
        img.im.alpha_composite(flay.im)
    rng = random.Random(31)
    lay = new()
    row = []
    x = 280
    i = 0
    while x < 1030:                                  # задний ряд: ели и липы, плотно
        if i % 3 == 1:
            tim = BT(84, 106, "deep", 100 + i)
        else:
            tim = PT(rng.choice((46, 52, 58)), rng.choice((92, 104, 116)), "pine", 200 + i)
        # низ ствола — ровно на краю поляны (линия near): корни видны, деревья стоят на земле, не висят и не прячутся
        row.append((NEAR_YS[min(W - 1, x)] + 2 + rng.randint(-1, 1), tim, x))
        x += rng.randint(26, 38)
        i += 1
    row.sort(key=lambda r: r[0])
    for (by, tim, xx) in row:
        paste(lay, tim, xx, by)
        SHADOW_OBJS.append((tim, xx, by))
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


# ---- земля из самой игры: art/ground.png (трава, тропинка, пруд с камнями и кувшинками) ----
# Картинку игры (вид сверху) кладём на поляну: по горизонтали ×0.5, по вертикали ×0.5 (как будто смотрим вдоль земли),
# зеркально — тропа от двери слева, пруд справа. Цвета берём как есть (самый частый цвет в блоке — палитра не мутнеет).
GKX, GKY = 0.5, 0.5
G_DOOR_X, G_TOP_Y, G_SRC_Y0 = 452, 404, 698
GAME_PATHS = (((960, 350), (960, 1400), 30.0), ((960, 600), (1186, 594), 22.0), ((960, 760), (712, 826), 22.0),
              ((960, 940), (1160, 904), 18.0), ((960, 600), (-60, 596), 20.0))


def _seg(px, py, a, b):
    abx, aby = b[0] - a[0], b[1] - a[1]
    t = max(0.0, min(1.0, ((px - a[0]) * abx + (py - a[1]) * aby) / float(abx * abx + aby * aby)))
    return math.hypot(px - (a[0] + abx * t), py - (a[1] + aby * t))


def g_path(sx, sy):
    best = min(_seg(sx, sy, a, b) - r for (a, b, r) in GAME_PATHS)
    return best + math.sin(sx * 0.115) * 2.4 + math.cos(sy * 0.095) * 2.4 + math.sin((sx + sy) * 0.035) * 3.2


def g_pond(sx, sy):
    qx, qy = (sx - 500) / 196.0, (sy - 860) / 122.0
    ang = math.atan2(qy, qx)
    return math.hypot(qx, qy) - 1.0 - (math.sin(ang * 3.0 + 0.6) * 0.07 + math.sin(ang * 5.0 + 2.0) * 0.04)


def to_game(x, y):
    return 960 - (x + 0.5 - G_DOOR_X) / GKX, G_SRC_Y0 + (y + 0.5 - G_TOP_Y) / GKY


def on_grass(x, y):
    sx, sy = to_game(x, y)
    return g_pond(sx, sy) > 0.22 and g_path(sx, sy) > 14.0 and sx > 120


GRASS_SRC = (1250, 60, 620, 1160)    # чистая трава в ground.png (без тропы и пруда): x, y, ширина, высота


def _reflect(v, n):
    v = v % (2 * n)
    return v if v < n else 2 * n - 1 - v


def grass_1to1(gp, x, y):
    """Трава игры пиксель в пиксель (без сжатия): участок справа от тропы, зеркальная плитка без шва."""
    gx, gy, gw, gh = GRASS_SRC
    return gp[gx + _reflect(x + 31, gw), gy + _reflect(y + 140, gh)]


def ground_from_game(img, ys):
    gi = Image.open(os.path.join(ART, "ground.png")).convert("RGBA")
    gp = gi.load()
    rim = hx("e4f0bc")
    for x in range(W):
        for y in range(max(0, ys[x]), H):
            sx, sy = to_game(x, y)
            # трава — 1:1 как в игре; тропа и пруд (и полоска у их края) — из той же картинки игры
            if g_pond(sx, sy) > 0.24 and g_path(sx, sy) > 13.0:
                c = grass_1to1(gp, x, y)              # без светлой кромки сверху — край поляны не выглядит обрывом
                img.px(x, y, (c[0], c[1], c[2], 255))
                continue
            sx = max(40.0, min(gi.width - 41.0, sx))       # край ground.png рваный и прозрачный — туда не лезем
            sy = max(40.0, min(gi.height - 41.0, sy))
            cnt = {}
            for yy in range(int(sy - 1), int(sy + 1)):
                for xx in range(int(round(sx - 1.0)), int(round(sx + 1.0)) + 1):
                    c = gp[min(gi.width - 1, max(0, xx)), min(gi.height - 1, max(0, yy))]
                    cnt[c] = cnt.get(c, 0) + 1
            c = max(cnt, key=lambda k: cnt[k])
            if c[2] > c[0] + 8 and abs(c[0] - c[1]) < 8 and g_pond(*to_game(x, y)) > 0.5:
                c = (237, 216, 176, 255)              # камни на тропе убраны — просто песок (у пруда камни остаются)
            elif c[:3] in ((110, 90, 64), (143, 118, 80), (192, 158, 124)) and g_path(*to_game(x, y)) < -5.0 and g_pond(*to_game(x, y)) > 0.5:
                c = (237, 216, 176, 255)              # коричневые контуры камней внутри тропы
            if y - ys[x] < 2:
                c = mix(c, rim, 0.35)
            img.px(x, y, (c[0], c[1], c[2], 255))


NEAR_YS = ridge([(260, 404), (420, 398), (620, 404), (820, 398), (1000, 402)], wob=0.8, seed=13)   # край поляны


def near():
    img = new()
    ys = NEAR_YS
    rp = ft.LEAF["green"]
    rng = random.Random(21)
    ground_from_game(img, ys)
    door = (452, 412)          # дом стоит ниже края поляны — фундамент на траве, а не над дымкой
    objs = []
    hs, k = house_small(150)
    objs.append((door[1], hs, door[0]))
    chim = (door[0] - hs.width / 2 + 214 * k, door[1] - hs.height + 6 * k)
    for (tim, x, dy) in ((BT(120, 150, "field", 71, extra="apples"), 330, 4),
                         (PT(60, 116, "pine", 5), 560, 0), (BT(100, 128, "pink", 51, extra="blossom"), 610, 2),
                         (PT(52, 100, "pine", 15), 900, -2)):
        objs.append((ys[x] + 6 + dy, tim, x))
    for (x, seed, look) in ((372, 3, "meadow"), (520, 8, "meadow"), (944, 4, "field")):
        objs.append((ys[x] + 12, BU(look, seed), x))
    # кустики травы из игры (grass_s0..5 низкая, grass_t0..4 высокая) — как они растут в мире, 1:1
    short = [Image.open(os.path.join(ART, "grass_s%d.png" % i)).convert("RGBA") for i in range(6)]
    tall = [Image.open(os.path.join(ART, "grass_t%d.png" % i)).convert("RGBA") for i in range(5)]
    grng = random.Random(77)
    hx_l, hx_r = door[0] - hs.width / 2 - 4, door[0] + hs.width / 2 + 4

    def tuft_ok(x, y, r):
        if hx_l < x < hx_r and y < door[1] + 1:
            return False
        return all(on_grass(x + dx, y + dy) for (dx, dy) in ((0, 0), (-r, 0), (r, 0), (0, -r // 2), (0, 3)))

    tufts = []
    for _ in range(420):
        x = grng.randrange(270, W - 4)
        y = grng.randrange(ys[x] + 6, H + 6)
        if tuft_ok(x, y, 8):
            im = grng.choice(short)
            tufts.append((y, im.transpose(Image.FLIP_LEFT_RIGHT) if grng.random() < 0.5 else im, x))
    made = 0
    for _ in range(600):
        if made >= 55:
            break
        x = grng.randrange(270, W - 4)
        y = grng.randrange(ys[x] + 10, H + 10)
        if math.sin(x * 0.021) + math.sin(y * 0.05 + x * 0.007) < 0.1 or not tuft_ok(x, y, 12):
            continue
        im = grng.choice(tall)
        tufts.append((y, im.transpose(Image.FLIP_LEFT_RIGHT) if grng.random() < 0.5 else im, x))
        made += 1
    # трава вдоль фундамента — закрывает низ дома, он «врастает» в землю (тропу у двери не трогаем)
    xx = int(hx_l) + 6
    while xx < hx_r - 4:
        if abs(xx - door[0]) > 16:
            im = grng.choice(short)
            tufts.append((door[1] + grng.randint(2, 4), im.transpose(Image.FLIP_LEFT_RIGHT) if grng.random() < 0.5 else im, xx))
        xx += grng.randint(9, 15)
    big_ids = {id(o[1]) for o in objs}                 # дом, деревья, кусты — отбрасывают тень
    objs += tufts
    objs.sort(key=lambda o: o[0])
    for (by, im, x) in objs:
        paste(img, im, x, by)
        if id(im) in big_ids:
            SHADOW_OBJS.append((im, x, by))
            paste(OBJ_MASK, im, x, by - 3)              # где стоят предметы — тени на них не ложатся
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
    # цветы кучками — только на траве (не на тропе и не у воды)
    kinds = ["white", "pink", "yellow", "lilac", "blue", "white", "yellow"]
    for _ in range(50):
        cx0 = rng.randrange(300, W - 10)
        cy0 = ys[cx0] + rng.randint(14, 150)
        kind = rng.choice(kinds)
        for _ in range(rng.randint(3, 7)):
            x, y = cx0 + rng.randint(-9, 9), cy0 + rng.randint(-4, 4)
            if 0 < x < W - 2 and 3 < y < H - 3 and all(on_grass(x + dx, y + dy) for (dx, dy) in ((0, 0), (0, -2), (1, 0), (-1, 0))):
                flower(img, x, y, kind)
    return img.im, glow_l.im, chim


def front():
    """Передний план: большое дерево справа (рамка) и кусты с травой внизу."""
    img = new()
    paste(img, BT(232, 300, "meadow", 41, big=True), 992, 592)
    paste(img, BU("meadow", 12, 150, 96), 330, H + 26)
    paste(img, BU("deep", 5, 110, 74), 880, H + 24)
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


def ring(frame):
    """Круг на воде от всплеска: эллипс-кольцо растёт и бледнеет (4 кадра)."""
    rx = (5, 10, 15, 20)[frame]
    ry = max(2, rx // 3)
    img = new(46, 18)
    col = [hx(c) for c in ("f2fbfc", "d4eff2", "b9e2ec", "9dd2e4")][frame]
    for a in range(0, 360, 2):
        x = int(round(23 + math.cos(math.radians(a)) * rx))
        y = int(round(9 + math.sin(math.radians(a)) * ry))
        img.px(x, y, col)
    return img.im


def drop():
    img = new(3, 3)
    img.px(1, 0, hx("eef9f8"))
    img.px(0, 1, hx("b9e2ec"))
    img.px(1, 1, hx("d4eff2"))
    img.px(2, 1, hx("9dd2e4"))
    img.px(1, 2, hx("82bfd9"))
    return img.im


def smoke(r=5.5):
    """Клуб дыма — пиксельный кружок в стиле яблока: свет сверху-слева, цветной контур (рисуется ×2 без размытия)."""
    S = int(r * 2) + 2
    img = new(S, S)
    rp = [hx(c) for c in ("8e88aa", "b4b0cc", "d6d4e6", "eeeef6", "ffffff")]
    c = S / 2.0
    for y in range(S):
        for x in range(S):
            dx, dy = (x + 0.5 - c) / r, (y + 0.5 - c) / r
            d = dx * dx + dy * dy
            if d <= 1.0:
                v = -dx * 0.6 - dy * 0.8
                t = 1 if v < -0.35 else 2 if v < 0.15 else 3 if v < 0.6 else 4
                if d > 0.72:                       # кромка — на тон темнее (контур без чёрного)
                    t = max(0, t - 1) if v < 0.3 else t
                img.px(x, y, rp[t])
    return img.im


def splash(frame):
    """Всплеск воды там, где рыба выпрыгнула/нырнула: столбик брызг растёт и опадает (3 кадра)."""
    img = new(16, 14)
    cols = [hx(c) for c in ("6fb0d6", "a8d8ee", "e6f8fc", "ffffff")]
    hts = (5, 9, 4)[frame]
    for x in range(16):
        dx = abs(x + 0.5 - 8) / 8.0
        hh = int(round(hts * (1.0 - dx * dx * 1.2)))
        for k in range(max(0, hh)):
            y = 13 - k
            t = 3 if k >= hh - 1 else 2 if k >= hh - 3 else 1
            if x in (0, 15):
                t = 0
            img.px(x, y, cols[t])
    if frame == 1:                                # летящие капли
        for (x, y) in ((2, 2), (13, 1), (5, 0), (11, 3)):
            img.px(x, y, cols[3])
            img.px(x, y + 1, cols[1])
    for x in range(1, 15):                        # тёмная «дырка» в воде у основания
        img.px(x, 13, hx("3d7fae") if 3 < x < 12 else cols[0])
    return img.im


def hole(frame):
    """Место в воде, откуда выпрыгнула рыба: тёмное пятно + светлое кольцо (видно, пока рыба в воздухе)."""
    rx = (6, 8, 10)[frame]
    ry = max(2, rx // 3)
    img = new(26, 10)
    for y in range(10):
        for x in range(26):
            d = ((x + 0.5 - 13) / rx) ** 2 + ((y + 0.5 - 5) / ry) ** 2
            if d <= 0.45:
                img.px(x, y, hx("173f66"))
            elif d <= 0.75:
                img.px(x, y, hx("2a5e8c"))
            elif d <= 1.15:
                img.px(x, y, hx("f2fbfc") if y < 5 else hx("bfe6f2"))
    return img.im


# ---- звери и птицы из игры, уменьшенные под масштаб меню (дом 288 -> 150 px, зверь в игре ×0.5) ----
def _shrink(fr, k):
    w, h = max(1, int(round(fr.width * k))), max(1, int(round(fr.height * k)))
    sm = fr.resize((w, h), Image.BOX)
    p = sm.load()
    for y in range(h):
        for x in range(w):
            c = p[x, y]
            p[x, y] = (c[0], c[1], c[2], 255) if c[3] >= 120 else T
    return sm


def bird_fw(bid):
    """Ширина кадра птицы из birds_db.gd (листы птиц разной длины — делить на 12 нельзя)."""
    import re
    s = open(os.path.join(HERE, "..", "birds_db.gd"), encoding="utf-8").read()
    m = re.search(r'"%s": \{[^\n]*?"frame": \[(\d+), (\d+)\]' % bid, s)
    return int(m.group(1))


def _lum(c):
    return 0.3 * c[0] + 0.59 * c[1] + 0.11 * c[2]


def _wing_ramp(up, down):
    """4 тона крыла (контур, тень, середина, свет) — из поднятого крыла кадра 'вверх'."""
    W, H = up.size
    pu, pd = up.load(), down.load()
    cols = []
    for x in range(W):
        t = next((y for y in range(H) if pd[x, y][3] > 0), H)
        for y in range(min(t - 1, H)):
            if pu[x, y][3] > 0:
                cols.append(pu[x, y])
    if len(cols) < 4:
        cols = [pd[x, y] for x in range(W) for y in range(H) if pd[x, y][3] > 0]
    cols.sort(key=_lum)
    q = lambda f: cols[min(len(cols) - 1, int(f * len(cols)))]
    return [q(0.05), q(0.42), q(0.72), q(0.94)]


def _draw_wing(img, root, ang_deg, L, Wd, ramp, behind=False, shade=1.0):
    """Раскрытое крыло: ровная передняя кромка, зубчики маховых сзади, цветной контур, свет сверху."""
    p = img.load()
    W, H = img.size
    a = math.radians(ang_deg)
    d = (math.cos(a), -math.sin(a))
    n = (-d[1], d[0])
    if n[1] < 0:
        n = (-n[0], -n[1])
    ramp = [tuple(int(c[i] * shade) for i in range(3)) + (255,) for c in ramp]
    inside = {}
    for y in range(H):
        for x in range(W):
            vx, vy = x + 0.5 - root[0], y + 0.5 - root[1]
            u = (vx * d[0] + vy * d[1]) / L
            v = vx * n[0] + vy * n[1]
            if u < -0.05 or u > 1.0:
                continue
            uu = max(0.0, u)
            lead = Wd * 0.45 * (1 - uu ** 2.2)
            feath = 0.5 + 0.5 * math.cos(uu * L / 2.6 * math.pi)
            trail = Wd * (1 - uu ** 2.4) * 0.9 + Wd * 0.3 * feath * (0.3 + uu) * (1 - uu * 0.6) + 0.8
            if -lead <= v <= trail:
                inside[(x, y)] = (v + lead) / max(0.01, lead + trail)
    for (x, y), t in inside.items():
        if behind and p[x, y][3] > 0:
            continue
        edge = any((x + dx, y + dy) not in inside for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))
        p[x, y] = ramp[0] if edge else (ramp[3] if t < 0.22 else ramp[2] if t < 0.55 else ramp[1])


def glide_frame(up, down):
    """Кадр парения: тело со сложенными крыльями + оба крыла раскрыты пологой V (дальнее темнее, за телом)."""
    pad = 12
    def padf(f):
        o = Image.new("RGBA", (f.width + pad * 2, f.height + pad), T)
        o.alpha_composite(f, (pad, pad))
        return o
    up, down = padf(up), padf(down)
    out = down.copy()
    bb = down.getbbox()
    bw = bb[2] - bb[0]
    pd = down.load()
    sx = int(bb[0] + bw * 0.52)
    top = next(y for y in range(down.height) if pd[sx, y][3] > 0)
    root = (sx + 0.5, top + 2.5)
    ramp = _wing_ramp(up, down)
    L, Wd = bw * 0.58, bw * 0.21
    _draw_wing(out, (root[0] + 3, root[1]), 180 - 48, L * 0.8, Wd * 0.8, ramp, behind=True, shade=0.72)
    _draw_wing(out, root, 180 - 18, L, Wd, ramp)
    return out


def game_strip(path, nframes, picks, k, fw=None, glide=False):
    """Лист игры (nframes кадров в ряд) -> полоска выбранных кадров, уменьшенных в k раз, обрезанных по общему краю.
    glide=True: последним кадром добавляется парение (крылья раскрыты) из кадров picks[0] (вверх) и picks[2] (вниз)."""
    src = Image.open(path).convert("RGBA")
    fw = fw or src.width // nframes
    raw = [src.crop((fw * i, 0, fw * (i + 1), src.height)) for i in picks]
    if glide:
        pad = 12
        def padf(f):
            o = Image.new("RGBA", (f.width + pad * 2, f.height + pad), T)
            o.alpha_composite(f, (pad, pad))
            return o
        raw = [padf(f) for f in raw] + [glide_frame(raw[0], raw[2])]
    frs = [_shrink(f, k) for f in raw]
    box = None
    for f in frs:
        b = f.getbbox()
        if b:
            box = b if box is None else (min(box[0], b[0]), min(box[1], b[1]), max(box[2], b[2]), max(box[3], b[3]))
    frs = [f.crop(box) for f in frs]
    out = Image.new("RGBA", (frs[0].width * len(frs), frs[0].height), T)
    for i, f in enumerate(frs):
        out.alpha_composite(f, (i * frs[0].width, 0))
    return out


MENU_BIRDS = ("sparrow", "great_tit", "blue_tit", "robin", "chaffinch", "goldfinch", "bullfinch", "wren", "lark", "swallow",
              "starling", "thrush", "blackbird", "wagtail", "oriole", "waxwing", "kingfisher", "hoopoe", "jay", "magpie",
              "crow", "raven", "cuckoo", "woodpecker", "dove", "gull",
              "sandpiper", "bee_eater", "crossbill", "nuthatch", "white_eye", "rosefinch", "fairy_wren",
              "firebird")
FLOCK_BIRDS = ("starling", "swallow", "gull", "crow")      # стаи вдалеке — мелкие, в дымке


def heaven_cloud():
    """Редкое облако-«рай»: пышное золотисто-розовое облако, на нём ворота из белого мрамора с золотом, сияние и искры."""
    w, h = 170, 58
    pad = 34
    S_w, S_h = w + pad * 2, h + pad * 2 + 40
    img = new(S_w, S_h)
    gx, gy = S_w / 2.0, pad + 40 + h * 0.36           # низ ворот — на макушке облака
    # сияние за воротами: лучи-клинья полупрозрачные
    for i in range(11):
        a = math.pi + (i + 0.5) / 11.0 * math.pi
        for r in range(18, 62):
            for k in (-1, 0, 1):
                x = int(round(gx + math.cos(a) * r - math.sin(a) * k * (1 + r * 0.04)))
                y = int(round(gy - 16 + math.sin(a) * r * 0.9 + math.cos(a) * k))
                al = int(150 * (1.0 - (r - 18) / 44.0))
                if al > 0 and img.a(x, y) * 255 < al:
                    img.px(x, y, (255, 240, 170, al))
    # облако (как обычное, но тёплое)
    rng = random.Random(77)
    cl = []
    n = 6
    oy = 40
    for i in range(n):
        t = (i + 0.5) / n
        cl.append((pad + t * w + rng.uniform(-3, 3), pad + oy + h * 0.70, w / n * 0.8, h * rng.uniform(0.26, 0.32)))
    for i in range(3):
        t = (i + 0.5) / 3
        tt = 0.2 + 0.6 * t
        hh = 1.0 - abs(tt - 0.5) * 1.1
        cl.append((pad + tt * w, pad + oy + h * (0.50 - 0.12 * hh), w * 0.2, h * (0.32 + 0.16 * hh)))
    cl.sort(key=lambda q: q[1])
    cimg = new(S_w, S_h)
    rp = ft.ramp("b88aa8", "d6a8bc", "eec8cc", "fbe2d6", "fff1e2", "fffaf2", "ffffff")
    ft.leaf_canopy(cimg, cl, rp, 9, 7.0, 5.6, 3.5, 0.12)
    ft.clean_specks(cimg)
    ft.outline_auto(cimg, 0.3)
    # ворота: две колонны, арка, золотые прутья
    marble = [hx(c) for c in ("8a86a8", "b4b2cc", "dcdaea", "f4f2fa", "ffffff")]
    gold = [hx(c) for c in ("9a6420", "c88a2c", "eab448", "fcd870", "fff2b0")]
    gate = new(S_w, S_h)
    for side in (-1, 1):
        px0 = int(gx + side * 17) - 3
        for y in range(int(gy) - 30, int(gy) + 1):
            for x in range(px0, px0 + 6):
                u = x - px0
                t = 0 if u == 0 or u == 5 else 3 if u == 1 else 2 if u < 4 else 1
                if y < gy - 28 or y > gy - 3:                 # капитель и база шире
                    t = 4 if u < 3 else 2
                gate.px(x, y, marble[t])
            for x in (px0 - 1, px0 + 6):
                if y < gy - 27 or y > gy - 3:
                    gate.px(x, y, marble[1])
        for (dx, dy) in ((0, -32), (1, -33), (-1, -33), (0, -34)):    # золотой шарик на колонне
            gate.px(int(gx + side * 17) + dx, int(gy) + dy, gold[3] if dy < -33 else gold[2])
    for a in range(0, 181, 2):                                        # арка
        r = 17.0
        x = gx + math.cos(math.radians(180 + a)) * r
        y = gy - 30 + math.sin(math.radians(180 + a)) * r * 0.75
        for k in range(3):
            gate.px(int(round(x)), int(round(y)) + k, [gold[4], gold[2], gold[0]][k])
    for i in range(7):                                                # прутья
        x = int(gx - 11 + i * 3.7)
        top = int(gy - 30 - math.sqrt(max(0.0, 17.0 ** 2 - (x + 0.5 - gx) ** 2)) * 0.75) + 3
        for y in range(top, int(gy) - 2):
            gate.px(x, y, gold[2] if (y + i) % 7 else gold[4])
    for x in range(int(gx) - 13, int(gx) + 14):                       # перекладина
        gate.px(x, int(gy) - 16, gold[3])
        gate.px(x, int(gy) - 15, gold[1])
    cimg.im.alpha_composite(gate.im)
    # облако спереди прикрывает низ ворот (они стоят В облаке)
    front = new(S_w, S_h)
    cl2 = [c for c in cl if c[1] > pad + oy + h * 0.6]
    ft.leaf_canopy(front, cl2, rp, 19, 7.0, 5.6, 3.5, 0.12)
    ft.outline_auto(front, 0.3)
    fp = front.im.load()
    for y in range(S_h):
        for x in range(S_w):
            if y < gy - 4:
                fp[x, y] = T
    cimg.im.alpha_composite(front.im)
    img.im.alpha_composite(cimg.im)
    srng = random.Random(5)                                           # искорки
    for _ in range(26):
        x, y = srng.randrange(20, S_w - 20), srng.randrange(10, int(gy) + 20)
        if img.a(x, y) < 0.6:
            img.px(x, y, hx("fff6c8"))
            if srng.random() < 0.35:
                for (dx, dy) in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    img.px(x + dx, y + dy, (255, 230, 150, 170))
    return img.im
MENU_ANIMALS = (("rabbit", 0.17), ("fox", 0.17), ("deer", 0.16), ("hedgehog", 0.17), ("squirrel", 0.16))


# ---- тени от солнца: силуэты деревьев/дома, отброшенные по земле к зрителю, влево/прямо/вправо ----
SHADOW_OBJS = []        # (картинка, x центра, y основания)
OBJ_MASK = ft.Img(W, H)  # силуэты предметов поляны (чтобы тень не ложилась на дом и кусты)


def shadows(shear):
    img = new()
    m = Image.new("L", (W, H), 0)
    mp = m.load()
    for (im, cx, by) in SHADOW_OBJS:
        a = im.getchannel("A").load()
        x0, y0 = int(cx - im.width / 2), int(by - im.height)
        for v in range(im.height):
            hgt = (im.height - 1 - v) - 6           # высота точки над землёй (низ картинки — тень/трава)
            if hgt < 0:
                continue
            for u in range(im.width):
                if a[u, v] < 128:
                    continue
                sx = x0 + u + hgt * shear
                sy = by - 4 + hgt * 0.2
                for (ox, oy) in ((0, 0), (1, 0)):
                    xx, yy = int(round(sx)) + ox, int(round(sy)) + oy
                    if 0 <= xx < W and 0 <= yy < H and yy >= NEAR_YS[xx] - 12 and OBJ_MASK.a(xx, yy) < 0.5:
                        mp[xx, yy] = 255
    p = img.p
    for y in range(H):
        for x in range(W):
            if mp[x, y]:
                p[x, y] = (40, 46, 92, 92)
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
    save("menu32_rays_inner", rays_inner())
    for i in range(3):
        save("menu32_sparkle_%d" % i, sparkle(i))
    for i, (w, h, s) in enumerate(((150, 50, 1), (110, 40, 2), (190, 58, 3), (90, 34, 4))):
        save("menu32_cloud_%d" % i, cloud(w, h, s))
    save("menu32_far", far())
    save("menu32_mid", mid())
    n, g, chim = near()
    save("menu32_near", n)
    save("menu32_windows", g)
    cf, cpos = chimney_front(chim)
    save("menu32_chimney_front", cf)
    print(json.dumps({"chimney_front": cpos}))
    save("menu32_front", front())
    save("menu32_bird_0", bird(0))
    save("menu32_bird_1", bird(1))
    save("menu32_smoke", smoke())
    for i, r in enumerate((2.5, 3.5, 4.5, 5.5)):          # клубы дыма растут, пока поднимаются
        save("menu32_smoke_%d" % i, smoke(r))
    for i in range(3):
        save("menu32_splash_%d" % i, splash(i))
        save("menu32_hole_%d" % i, hole(i))
    for b in MENU_BIRDS:                                   # кадры полёта 6..9 из листа птицы игры
        save("menu32_fly_" + b, game_strip(os.path.join(ART, "bird_%s.png" % b), 12, (6, 7, 8, 9), 0.46, bird_fw(b), glide=True))
    for b in FLOCK_BIRDS:                                  # стаи вдалеке — те же птицы, но совсем мелкие
        save("menu32_flock_" + b, game_strip(os.path.join(ART, "bird_%s.png" % b), 12, (6, 7, 8, 9), 0.22, bird_fw(b), glide=True))
    save("menu32_cloud_heaven", heaven_cloud())
    for (a, k) in MENU_ANIMALS:                            # кадры ходьбы 0..3 из листа зверя игры
        save("menu32_walk_" + a, game_strip(os.path.join(ART, "animal_%s.png" % a), 12, (0, 1, 2, 3), k))
    for nm, sh in (("left", -0.55), ("mid", 0.0), ("right", 0.55)):   # тень влево/прямо/вправо (солнце справа/сверху/слева)
        save("menu32_shadow_" + nm, shadows(sh))
    for i in range(4):
        save("menu32_ring_%d" % i, ring(i))
    save("menu32_drop", drop())
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

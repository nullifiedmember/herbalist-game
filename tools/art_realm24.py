"""v24: арт двух миров за порталами — Ад (город демониц) и Рай (город ангелиц).
Земля-плитки, дома, дворцы, фонтаны, лавки, украшения, порталы. python tools/art_realm24.py"""
import os
import math
import random
from PIL import Image

ART = os.path.join(os.path.dirname(__file__), "..", "art")
OUT = (26, 14, 12, 255)


def hx(h, a=255):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


def mix(a, b, k):
    return tuple(int(a[i] + (b[i] - a[i]) * k) for i in range(3)) + (255,)


def ramp(lst):
    return [hx(c) for c in lst]


def outline(im, col=OUT):
    px = im.load()
    w, h = im.size
    add = []
    for y in range(h):
        for x in range(w):
            if px[x, y][3] == 0:
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    q = (x + dx, y + dy)
                    if 0 <= q[0] < w and 0 <= q[1] < h and px[q][3] > 200:
                        add.append((x, y))
                        break
    for p in add:
        px[p] = col


def save(im, name):
    im.save(os.path.join(ART, name + ".png"))


def noise2(x, y, s):
    return (math.sin(x * 12.9898 + y * 78.233 + s * 37.719) * 43758.5453) % 1.0


# ------------------------------------------------------------------ земля
def tile_hell():
    W = 128
    im = Image.new("RGBA", (W, W))
    px = im.load()
    rock = ramp(["1a1012", "261618", "321e20", "40282a", "503436"])
    lava = ramp(["8a1a08", "c83a0c", "f06a14", "ffa830", "ffe070"])
    rnd = random.Random(5)
    # плиты базальта (ячейки Вороного)
    pts = [(rnd.uniform(0, W), rnd.uniform(0, W)) for _ in range(14)]
    for y in range(W):
        for x in range(W):
            ds = []
            for (cx, cy) in pts:
                for ox in (-W, 0, W):
                    for oy in (-W, 0, W):
                        ds.append(math.hypot(x - cx - ox, y - cy - oy))
            ds.sort()
            edge = ds[1] - ds[0]
            v = noise2(x // 2, y // 2, 1)
            c = rock[2] if v < 0.6 else (rock[3] if v < 0.85 else rock[1])
            if edge < 1.6:
                # трещина со светящейся лавой
                c = lava[1] if noise2(x // 6, y // 6, 3) < 0.5 else rock[0]
                if edge < 0.8 and noise2(x // 6, y // 6, 3) < 0.35:
                    c = lava[3]
            elif edge < 3.0:
                c = rock[1]
            elif edge < 4.0 and noise2(x // 6, y // 6, 3) < 0.5:
                c = mix(c, lava[0], 0.35)   # отсвет от трещины
            px[x, y] = c
    save(im, "realm_hell_ground")


def tile_heaven():
    W = 128
    im = Image.new("RGBA", (W, W))
    px = im.load()
    cl = ramp(["c8cce6", "d8dcf0", "e6e8f6", "f2f3fb", "ffffff"])
    for y in range(W):
        for x in range(W):
            v = 0.0
            for k, f in ((1.0, 0.05), (0.5, 0.11), (0.25, 0.23)):
                v += k * (math.sin(x * f * 6.28 / 6.4 + math.sin(y * f * 3.0)) * 0.5 + 0.5) * (math.sin(y * f * 6.28 / 6.4 + 1.3) * 0.5 + 0.5)
            v = v / 1.75
            i = min(4, int(v * 5.2))
            c = cl[i]
            # мягкие голубые тени между клубами
            if v < 0.18:
                c = hx("b4bce0")
            px[x, y] = c
    save(im, "realm_heaven_ground")


def tile_paving(name, base, joint, accent):
    W = 64
    im = Image.new("RGBA", (W, W))
    px = im.load()
    for y in range(W):
        for x in range(W):
            row = y // 16
            off = 8 if row % 2 else 0
            bx = (x + off) % 16
            by = y % 16
            c = base[2]
            if bx == 0 or by == 0:
                c = joint
            elif by == 1 or bx == 1:
                c = base[3]
            elif by == 15 or bx == 15:
                c = base[1]
            elif noise2((x + off) // 16, row, 9) < 0.25:
                c = base[1] if noise2(x, y, 4) < 0.3 else base[2]
            if accent and (bx, by) in ((8, 8), (7, 8), (8, 7)) and noise2((x + off) // 16, row, 2) < 0.3:
                c = accent
            px[x, y] = c
    save(im, name)


# ------------------------------------------------------------------ дома
def building(name, W, H, wall, roof, trim, win_glow, style, seed):
    rnd = random.Random(seed)
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    px = im.load()
    wall_top = int(H * 0.46)
    wall_bot = H - 10
    x0, x1 = 10, W - 10
    # стены: кладка
    for y in range(wall_top, wall_bot):
        for x in range(x0, x1):
            row = (y - wall_top) // 7
            off = 6 if row % 2 else 0
            jx = (x + off) % 12 == 0
            jy = (y - wall_top) % 7 == 0
            c = wall[2]
            if jx or jy:
                c = wall[1]
            elif (y - wall_top) % 7 == 1:
                c = wall[3]
            if x < x0 + 3:
                c = wall[3] if not (jx or jy) else wall[2]
            if x > x1 - 4:
                c = wall[1]
            if noise2(x // 12, row, seed) < 0.15 and not (jx or jy):
                c = wall[1]
            px[x, y] = c
    # цоколь
    for y in range(wall_bot, H - 2):
        for x in range(x0 - 3, x1 + 3):
            px[x, y] = trim[1] if (x % 10 == 0 or y == wall_bot) else trim[2]
    # пилястры/колонны
    cols = [x0 + 2, x1 - 7] if style != "palace" else [x0 + 2, x0 + (x1 - x0) // 4, (x0 + x1) // 2 - 3, x0 + 3 * (x1 - x0) // 4, x1 - 7]
    for cx in cols:
        for y in range(wall_top, wall_bot):
            for k in range(6):
                c = trim[4] if k == 1 else (trim[3] if k < 3 else (trim[2] if k < 5 else trim[1]))
                px[cx + k, y] = c
        for k in range(-1, 7):
            px[cx + k, wall_top] = trim[4]
            px[cx + k, wall_top + 1] = trim[3]
            px[cx + k, wall_bot - 1] = trim[2]
    # окна (арочные, светятся)
    nwin = 2 if W < 150 else 4
    span = (x1 - x0)
    door_x = (x0 + x1) // 2
    for i in range(nwin):
        wx = x0 + int(span * (i + 0.5) / nwin) - 5
        if abs(wx + 5 - door_x) < 18:
            continue
        wy = wall_top + 10
        for y in range(wy, wy + 18):
            for x in range(wx, wx + 10):
                ax = x - wx - 4.5
                ay = y - wy - 5
                if ay < 0 and ax * ax + ay * ay > 25:
                    continue
                c = win_glow[1] if y > wy + 9 else win_glow[2]
                if x == wx + 5 or y == wy + 10:
                    c = trim[1]
                if x < wx + 3 and y < wy + 8:
                    c = win_glow[3]
                px[x, y] = c
        for x in range(wx - 1, wx + 11):
            px[x, wy + 18] = trim[3]
    # дверь
    dw = 12
    for y in range(wall_bot - 26, wall_bot):
        for x in range(door_x - dw, door_x + dw):
            ax = x - door_x + 0.5
            ay = y - (wall_bot - 26 + dw)
            if ay < 0 and ax * ax + ay * ay > dw * dw:
                continue
            c = trim[1] if (abs(ax) > dw - 2 or (ay < 0 and ax * ax + ay * ay > (dw - 2) ** 2)) else (hx("3a1a10") if style.startswith("hell") else hx("a88a50"))
            if abs(ax) < dw - 2 and int(ax) % 5 == 0 and not (ay < 0 and ax * ax + ay * ay > (dw - 2) ** 2):
                c = mix(c, OUT, 0.35)
            px[x, y] = c
    px[door_x + 5, wall_bot - 12] = trim[4]
    # крыша
    if style.startswith("hell"):
        # острая шиферная крыша со шпилями
        apex_y = 6
        for y in range(apex_y, wall_top + 2):
            k = (y - apex_y) / (wall_top + 2 - apex_y)
            half = int(4 + k * (W / 2 - 4))
            for x in range(W // 2 - half, W // 2 + half + 1):
                if 0 <= x < W:
                    rr = (y - apex_y) // 4
                    off = 2 if rr % 2 else 0
                    c = roof[2]
                    if (y - apex_y) % 4 == 3:
                        c = roof[0]
                    elif (x + off) % 5 == 0:
                        c = roof[1]
                    if x < W // 2 and (y - apex_y) % 4 == 0:
                        c = roof[3]
                    px[x, y] = c
        # шпили по краям
        for sx in (14, W - 15):
            for y in range(wall_top - 22, wall_top + 2):
                k = (y - (wall_top - 22)) / 24.0
                hw = int(1 + k * 4)
                for x in range(sx - hw, sx + hw + 1):
                    px[x, y] = roof[3] if x < sx else roof[1]
            px[sx, wall_top - 23] = trim[4]
        # рога на коньке
        for d in (-1, 1):
            for k in range(7):
                x = W // 2 + d * (2 + k // 2)
                y = apex_y - k
                px[x, y] = hx("e8dcc8") if k > 4 else hx("8a7a68")
                px[x + d, y] = hx("5a4a3e")
    else:
        # купол / покатая крыша из белого мрамора с золотом
        cx = W // 2
        r = (x1 - x0) // 2 + 4
        top = wall_top - int(r * 0.75)
        for y in range(top, wall_top + 2):
            for x in range(cx - r, cx + r + 1):
                ny = (wall_top + 2 - y) / max(1, (wall_top + 2 - top))
                nx = (x - cx) / r
                if nx * nx + ny * ny > 1.0:
                    continue
                l = -nx * 0.6 + ny * 0.5
                i = 2 + int(round(l * 2))
                c = roof[max(0, min(4, i))]
                if abs((x - cx) % 9) == 0:
                    c = mix(c, roof[0], 0.3)
                px[x, y] = c
        # шпиль со звездой
        for y in range(top - 12, top + 1):
            px[cx, y] = trim[3]
            px[cx + 1, y] = trim[2]
        for (dx, dy) in ((0, -15), (-1, -14), (1, -14), (0, -14), (0, -13), (-2, -14), (2, -14)):
            px[cx + dx, top + dy] = trim[4]
        # карниз
        for x in range(x0 - 4, x1 + 4):
            px[x, wall_top] = trim[4]
            px[x, wall_top + 1] = trim[3]
            px[x, wall_top + 2] = trim[1]
    if style == "heaven_house":
        # облачко у основания
        for y in range(H - 12, H):
            for x in range(0, W):
                d = ((x - W / 2) / (W / 2)) ** 2 + ((y - (H - 4)) / 8.0) ** 2
                if d < 1.0 and px[x, y][3] == 0:
                    px[x, y] = hx("eef0fa") if y < H - 5 else hx("cfd4ec")
    outline(im)
    save(im, name)


# ------------------------------------------------------------------ украшения
def lava_pool():
    W, H = 72, 34
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    px = im.load()
    lava = ramp(["7a1606", "b8320a", "e85c12", "ff9a26", "ffd660"])
    rock = ramp(["1a1012", "2e1c1e", "443032"])
    for y in range(H):
        for x in range(W):
            d = ((x - W / 2) / (W / 2 - 1)) ** 2 + ((y - H / 2) / (H / 2 - 1)) ** 2
            if d > 1.0:
                continue
            if d > 0.72:
                px[x, y] = rock[1] if y > H / 2 else rock[2]
            else:
                v = math.sin(x * 0.35 + y * 0.6) * 0.5 + noise2(x // 3, y // 3, 7) * 0.5
                px[x, y] = lava[min(4, int(1 + v * 3.5 + (0.6 - d) * 2))]
    outline(im)
    save(im, "realm_lava_pool")


def spike(name, H, base_c):
    W = 22
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    px = im.load()
    r = ramp(base_c)
    for y in range(H):
        k = y / (H - 1)
        hw = 1 + k * 9
        for x in range(W):
            dx = x - W / 2 + 0.5
            if abs(dx) <= hw:
                c = r[3] if dx < -hw * 0.3 else (r[2] if dx < hw * 0.4 else r[1])
                if dx < -hw * 0.7:
                    c = r[4]
                px[x, y] = c
    outline(im)
    save(im, name)


def brazier():
    im = Image.new("RGBA", (22, 40), (0, 0, 0, 0))
    px = im.load()
    iron = ramp(["1a1818", "2c2a2c", "424046", "5c5a62", "7a7882"])
    for y in range(18, 40):
        for x in range(9, 13):
            px[x, y] = iron[2] if x < 11 else iron[1]
    for x in range(5, 17):
        px[x, 38] = iron[1]
        px[x, 39] = iron[0]
    for y in range(12, 19):
        hw = 9 - (y - 12)
        for x in range(11 - hw, 11 + hw):
            px[x, y] = iron[3] if x < 11 else iron[1]
    fire = ramp(["c82a0a", "f05a14", "ff9a2a", "ffd660", "fff6c0"])
    for y in range(0, 13):
        hw = int(6 * math.sin(y / 13 * math.pi * 0.9))
        for x in range(11 - hw, 11 + hw):
            d = abs(x - 10.5) / max(1, hw)
            px[x, y] = fire[max(0, min(4, int((1 - d) * 3 + y / 6)))]
    outline(im)
    save(im, "realm_brazier")


def fountain(name, stone, liquid, glow):
    W, H = 96, 80
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    px = im.load()
    s = ramp(stone)
    lq = ramp(liquid)
    # чаша
    for y in range(44, 72):
        for x in range(4, W - 4):
            d = ((x - W / 2) / (W / 2 - 4)) ** 2 + ((y - 58) / 14.0) ** 2
            if d > 1.0:
                continue
            if d > 0.62 or y > 64:
                c = s[3] if y < 52 else (s[2] if y < 64 else s[1])
                if (x // 8) % 2 == 0 and y > 60:
                    c = s[1]
            else:
                v = math.sin(x * 0.4 + y * 0.9) * 0.5 + 0.5
                c = lq[2 + int(v * 2)]
            px[x, y] = c
    # колонна и верхняя чаша
    for y in range(18, 52):
        for x in range(W // 2 - 4, W // 2 + 4):
            px[x, y] = s[3] if x < W // 2 - 1 else s[1]
    for y in range(16, 26):
        for x in range(W // 2 - 16, W // 2 + 16):
            d = ((x - W / 2) / 16.0) ** 2 + ((y - 21) / 5.0) ** 2
            if d <= 1.0:
                px[x, y] = s[3] if y < 21 else s[2]
                if d < 0.5 and y < 21:
                    px[x, y] = lq[3]
    # струи
    for k in (-1, 1):
        for t in range(26):
            x = int(W / 2 + k * (4 + t * 0.9))
            y = int(16 + t * t * 0.05 + t * 0.9)
            if 0 <= x < W and y < H:
                px[x, y] = lq[4]
                px[x, y + 1] = lq[3]
    for (dx, dy) in ((0, -8), (0, -7), (-1, -6), (1, -6), (0, -5), (0, -4)):
        px[W // 2 + dx, 16 + dy] = glow
    outline(im)
    save(im, name)


def portal(name, frame, swirl):
    W, H = 64, 96
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    px = im.load()
    fr = ramp(frame)
    sw = ramp(swirl)
    cx, cy = W / 2, 52
    for y in range(H):
        for x in range(W):
            nx = (x + 0.5 - cx) / 26
            ny = (y + 0.5 - cy) / 40
            d = math.sqrt(nx * nx + ny * ny)
            if y > 90:
                if 6 < x < W - 6:
                    px[x, y] = fr[1] if y > 93 else fr[3]
                continue
            if d < 0.82:
                a = math.atan2(ny, nx)
                v = (math.sin(a * 3 + d * 9) * 0.5 + 0.5) * (1 - d * 0.6)
                px[x, y] = sw[min(4, int(v * 5))]
            elif d < 1.0:
                c = fr[3] if nx < 0 else fr[1]
                if abs(d - 0.9) < 0.04:
                    c = fr[4]
                # руны
                if int(math.atan2(ny, nx) * 8) % 3 == 0 and abs(d - 0.91) < 0.05:
                    c = sw[4]
                px[x, y] = c
    outline(im)
    save(im, name)


def stall(name, cloth, wood):
    W, H = 64, 60
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    px = im.load()
    c = ramp(cloth)
    w = ramp(wood)
    for x in (6, 7, W - 8, W - 7):
        for y in range(14, 56):
            px[x, y] = w[2] if x % 2 == 0 else w[1]
    for y in range(36, 50):
        for x in range(4, W - 4):
            px[x, y] = w[3] if y < 38 else (w[2] if (x // 6) % 2 else w[1])
    for y in range(4, 18):
        for x in range(2, W - 2):
            stripe = (x // 8) % 2
            px[x, y] = c[3 if stripe else 1] if y < 15 else c[2 if stripe else 0]
    for x in range(2, W - 2, 8):
        for k in range(4):
            if 0 <= x + k < W:
                px[x + k, 18 + (1 if k in (1, 2) else 0)] = c[1]
    # товары на прилавке
    rnd = random.Random(hash(name) & 0xff)
    for i in range(6):
        gx = 10 + i * 8
        col = rnd.choice([hx("e04030"), hx("f0c040"), hx("8040c0"), hx("40a0e0"), hx("f080b0"), hx("60c060")])
        for (dx, dy) in ((0, 0), (1, 0), (0, -1), (1, -1), (2, 0)):
            px[gx + dx, 35 + dy] = col
    outline(im)
    save(im, name)


def cloud_bush():
    W, H = 56, 34
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    px = im.load()
    cl = ramp(["b8bedc", "d0d6ee", "e4e8f6", "f4f6fc", "ffffff"])
    for (bx, by, r) in ((16, 20, 11), (30, 15, 13), (42, 21, 10), (26, 24, 10)):
        for y in range(H):
            for x in range(W):
                d = math.hypot(x - bx, (y - by) * 1.1)
                if d < r:
                    l = (-(x - bx) * 0.5 - (y - by)) / r
                    px[x, y] = cl[max(0, min(4, 2 + int(round(l * 1.8))))]
    outline(im, hx("8890b8"))
    save(im, "realm_cloud_bush")


def harp_statue():
    W, H = 34, 64
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    px = im.load()
    g = ramp(["8a6a10", "b48c18", "d8ae28", "f0cc44", "fff0a8"])
    m = ramp(["a8aac0", "c4c6d8", "dcdeec", "eeeff6", "ffffff"])
    for y in range(50, 64):
        for x in range(4, 30):
            px[x, y] = m[3] if y < 53 else (m[2] if y < 60 else m[1])
    # арфа
    for t in range(40):
        a = t / 39
        x = int(8 + math.sin(a * math.pi) * 18)
        y = int(10 + a * 40)
        px[x, y] = g[3]
        px[x + 1, y] = g[2]
    for y in range(8, 50):
        px[8, y] = g[2]
        px[9, y] = g[1]
    for k in range(6):
        for y in range(12 + k * 2, 48):
            px[11 + k * 3, y] = g[4] if k % 2 == 0 else g[3]
    outline(im)
    save(im, "realm_harp")


def rainbow():
    W, H = 160, 84
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    px = im.load()
    cols = [hx("f06a6a"), hx("f4a454"), hx("f6dc5c"), hx("7ad07a"), hx("6ab4ea"), hx("9a7ae0")]
    for y in range(H):
        for x in range(W):
            d = math.hypot(x - W / 2, (y - H + 2) * 1.0)
            for i, c in enumerate(cols):
                r0 = 76 - i * 5
                if r0 - 5 < d <= r0:
                    px[x, y] = c
    save(im, "realm_rainbow")


def imp_sheet():
    """бесёнок-проказник: 4 кадра бега (бегает по аду и ворует мелочи)"""
    W, H = 24, 24
    im = Image.new("RGBA", (W * 4, H), (0, 0, 0, 0))
    px = im.load()
    skin = ramp(["5a1014", "8a1c20", "b8302c", "dc4e40", "f07a60"])
    for f in range(4):
        ox = f * W
        b = -1 if f % 2 else 0
        # тело-шарик
        for y in range(8, 18):
            for x in range(6, 18):
                d = ((x - 12) / 6) ** 2 + ((y - 13 - b) / 5) ** 2
                if d < 1:
                    px[ox + x, y] = skin[3] if x < 11 and y < 13 else skin[2]
        # рожки
        for (x, y) in ((8, 7), (8, 6), (7, 5), (15, 7), (15, 6), (16, 5)):
            px[ox + x, y + b] = hx("e8dcc8")
        # глаза
        px[ox + 10, 11 + b] = hx("fff060")
        px[ox + 14, 11 + b] = hx("fff060")
        # ножки
        lx = [0, 2, 0, -2][f]
        for y in range(18, 22):
            px[ox + 9 + (lx if y > 19 else 0) // 2, y] = skin[1]
            px[ox + 14 - (lx if y > 19 else 0) // 2, y] = skin[1]
        # хвостик
        for k in range(5):
            px[ox + 18 + k // 2, 14 - k + b] = skin[2]
        px[ox + 21, 9 + b] = skin[4]
    outline(im)
    save(im, "realm_imp")


if __name__ == "__main__":
    random.seed(24)
    tile_hell()
    tile_heaven()
    tile_paving("realm_hell_street", ramp(["1e1416", "2e2022", "3e2c2e", "52393a", "6a4a4a"]), hx("120a0c"), hx("e05a14"))
    tile_paving("realm_heaven_street", ramp(["b0a888", "cec6a6", "e4dcc0", "f2ecd6", "fffaee"]), hx("a89870"), hx("f0cc44"))
    hw = ramp(["1e1416", "2c1e20", "3c2a2c", "4e3638", "644446"])
    hroof = ramp(["120c10", "1e1418", "2c1e24", "3c2a32", "523a44"])
    htrim = ramp(["2a0a0a", "4a1010", "6e1a16", "962a1e", "c8462a"])
    hglow = ramp(["8a1a08", "e05a14", "ffa030", "ffe080"])
    building("realm_hell_house_a", 130, 150, hw, hroof, htrim, hglow, "hell_house", 1)
    building("realm_hell_house_b", 150, 160, ramp(["241418", "34202a", "462c38", "5a3a48", "74505e"]), hroof, htrim, ramp(["5a0a6a", "a020c0", "e070ff", "ffc0ff"]), "hell_house", 2)
    building("realm_hell_palace", 260, 230, hw, hroof, ramp(["3a2a06", "6a4a0a", "9a6e10", "c89a1e", "f0cc44"]), hglow, "hell_palace", 3)
    building("realm_hell_tavern", 170, 160, hw, hroof, htrim, hglow, "hell_house", 4)
    mw = ramp(["b8b4c8", "d0cee0", "e4e2f0", "f2f1f8", "ffffff"])
    groof = ramp(["9a7418", "c09a24", "e0bc3a", "f4d870", "fff0b0"])
    gtrim = ramp(["8a7a5a", "b8aa88", "dcd0b0", "f0e8d0", "fffaee"])
    sglow = ramp(["4a6aa0", "88b0e8", "c8e0ff", "ffffff"])
    building("realm_heaven_house_a", 130, 150, mw, groof, gtrim, sglow, "heaven_house", 5)
    building("realm_heaven_house_b", 150, 160, mw, ramp(["5a7ab0", "7a9ad0", "9ab8e8", "c0d6f6", "e6f0ff"]), gtrim, sglow, "heaven_house", 6)
    building("realm_heaven_palace", 260, 230, mw, groof, gtrim, sglow, "heaven_palace", 7)
    building("realm_heaven_tavern", 170, 160, mw, groof, gtrim, sglow, "heaven_house", 8)
    lava_pool()
    spike("realm_obsidian", 46, ["0a0810", "16121e", "241e30", "3a3248", "6a5e88"])
    spike("realm_crystal", 40, ["6a8ab8", "8aaad4", "aac8ea", "cce2f8", "f4faff"])
    brazier()
    fountain("realm_hell_fountain", ["1a1012", "2c1e20", "40302e", "584440", "705a54"], ["8a1a08", "c83a0c", "f06a14", "ffa830", "ffe070"], hx("ffe070"))
    fountain("realm_heaven_fountain", ["a8aac0", "c4c6d8", "dcdeec", "eeeff6", "ffffff"], ["4a8ac8", "6aaae0", "8ac8f0", "b8e2fa", "eef8ff"], hx("fff0a8"))
    portal("realm_portal_hell", ["1a0a0a", "2e1212", "4a1c1c", "6a2a26", "e05a14"], ["3a0606", "7a1206", "c03a0a", "f07a14", "ffd060"])
    portal("realm_portal_heaven", ["a8a090", "c8c0a8", "e0d8c0", "f4ecd8", "f0cc44"], ["8ab0e8", "b0cef4", "d4e6fa", "eef6ff", "ffffff"])
    stall("realm_hell_stall", ["4a0a10", "7a1418", "aa2420", "d8402c", "f07050"], ["1e1416", "2e2022", "3e2c2e", "52393a", "6a4a4a"])
    stall("realm_heaven_stall", ["7a9ad0", "9ab8e8", "c0d6f6", "e6f0ff", "ffffff"], ["b0a888", "cec6a6", "e4dcc0", "f2ecd6", "fffaee"])
    cloud_bush()
    harp_statue()
    rainbow()
    imp_sheet()
    print("ok")

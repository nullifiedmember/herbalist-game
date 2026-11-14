"""v24: арт — сундуки разных размеров, склад, лежащие стволы, ветки, штабели брёвен.
Стиль как у игры: тёмный контур, плоские полосы света (тень / основной / свет / блик), тёплый свет сверху-слева.
python tools/art_v24.py  ->  art/*.png"""
import os
import math
import random
from PIL import Image

ART = os.path.join(os.path.dirname(__file__), "..", "art")


def hx(h, a=255):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


def mix(c1, c2, k):
    return tuple(int(c1[i] + (c2[i] - c1[i]) * k) for i in range(3)) + (255,)


OUT = hx("1e130c")


def outline(im, col=OUT):
    """контур снаружи непрозрачных пикселей"""
    px = im.load()
    w, h = im.size
    add = []
    for y in range(h):
        for x in range(w):
            if px[x, y][3] == 0:
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    q = (x + dx, y + dy)
                    if 0 <= q[0] < w and 0 <= q[1] < h and px[q][3] > 0 and px[q] != col:
                        add.append((x, y))
                        break
    for p in add:
        px[p] = col
    return im


def rect(px, x0, y0, x1, y1, c):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            px[x, y] = c


def save(im, name):
    im.save(os.path.join(ART, name + ".png"))


# ------------------------------------------------------------------ сундуки
WOOD = [hx("4a2c18"), hx("6e4428"), hx("8e5c36"), hx("b07a48"), hx("d09a62")]
IRON = [hx("2e2c34"), hx("4c4a56"), hx("6e6c7a"), hx("9a98a8"), hx("c8c6d4")]
GOLD = [hx("6a4a10"), hx("a07818"), hx("d0a428"), hx("f0d060"), hx("fff0a8")]


def chest(w, h, lid_h, wood=WOOD, band=IRON, lock=GOLD, bands=2, rivets=True, name="chest"):
    im = Image.new("RGBA", (w + 2, h + 2), (0, 0, 0, 0))
    px = im.load()
    ox, oy = 1, 1
    # крышка (полукруглая сверху) и корпус
    for y in range(h):
        for x in range(w):
            top = y < lid_h
            if top:
                # скругление крышки
                r = lid_h * 0.9
                dx = min(x, w - 1 - x)
                if dx < 3 and y < 3 - dx:
                    continue
            # доски: горизонтальные полосы на корпусе, вертикальные на крышке
            if top:
                k = y / max(1, lid_h - 1)
                c = wood[3] if k < 0.25 else (wood[2] if k < 0.8 else wood[1])
                if y == 0 or (y == 1 and 2 < x < w - 3):
                    c = wood[4] if 1 < x < w // 2 else wood[3]
            else:
                yy = y - lid_h
                hh = h - lid_h
                plank = (yy * 3) // max(1, hh)
                c = wood[2] if plank % 2 == 0 else wood[1]
                if yy % max(2, hh // 3) == 0 and yy > 0:
                    c = wood[0]
                if x < 2:
                    c = wood[3] if not top else c
                if x > w - 3:
                    c = wood[0]
            # древесные волокна
            if random.random() < 0.08 and c not in (wood[0],):
                c = mix(c, wood[0], 0.35)
            px[ox + x, oy + y] = c
    # щель между крышкой и корпусом
    for x in range(w):
        px[ox + x, oy + lid_h] = wood[0]
        if 0 < x < w - 1:
            px[ox + x, oy + lid_h + 1] = mix(wood[1], wood[0], 0.4)
    # оковки
    if bands:
        pos = [3, w - 5] if bands == 2 else [3, w // 2 - 1, w - 5]
        for bx in pos:
            for y in range(h):
                if px[ox + bx, oy + y][3] == 0:
                    continue
                px[ox + bx, oy + y] = band[2] if y < lid_h else band[1]
                px[ox + bx + 1, oy + y] = band[3] if y < lid_h else band[2]
                if rivets and y % 4 == 2:
                    px[ox + bx, oy + y] = band[4]
    # нижняя оковка
    for x in range(w):
        if px[ox + x, oy + h - 1][3]:
            px[ox + x, oy + h - 1] = band[0]
            px[ox + x, oy + h - 2] = band[1] if x % 3 else band[3]
    # замок
    cx = w // 2
    ly = lid_h - 1
    rect(px, ox + cx - 2, oy + ly, ox + cx + 1, oy + ly + 4, lock[2])
    px[ox + cx - 2, oy + ly] = lock[4]
    px[ox + cx - 1, oy + ly] = lock[3]
    px[ox + cx + 1, oy + ly + 4] = lock[0]
    px[ox + cx, oy + ly + 2] = OUT
    px[ox + cx - 1, oy + ly + 2] = OUT
    px[ox + cx - 1, oy + ly + 3] = lock[1]
    outline(im)
    # мягкая тень под сундуком внутри картинки не рисуем — тени даёт игра
    save(im, name)


# ------------------------------------------------------------------ склад
def warehouse():
    W, H = 132, 112
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    px = im.load()
    roof = [hx("3a2420"), hx("5a3428"), hx("7a4832"), hx("9a5e3e"), hx("bc7a4e")]
    plank = [hx("3e2616"), hx("5e3a20"), hx("7c5030"), hx("9c6a40"), hx("c08a56")]
    stone = [hx("3c3a40"), hx("5a5862"), hx("7a7884"), hx("9c9aa6"), hx("c4c2cc")]
    wall_top, wall_bot = 46, 104
    # каменный цоколь
    for y in range(92, 106):
        for x in range(6, W - 6):
            row = (y - 92) // 5
            off = 6 if row % 2 else 0
            if (x + off) % 12 == 0 or (y - 92) % 5 == 0:
                c = stone[0]
            else:
                c = stone[2] if (y - 92) % 5 in (1, 2) else stone[1]
                if (x + off) % 12 in (1, 2) and (y - 92) % 5 == 1:
                    c = stone[3]
            px[x, y] = c
    # дощатые стены (вертикальные доски)
    for y in range(wall_top, 92):
        for x in range(8, W - 8):
            b = (x - 8) % 7
            c = plank[2]
            if b == 0:
                c = plank[0]
            elif b == 1:
                c = plank[3]
            elif b == 6:
                c = plank[1]
            if random.random() < 0.05:
                c = mix(c, plank[0], 0.4)
            # гвозди
            if b == 3 and y in (wall_top + 4, 86):
                c = IRON[3]
            px[x, y] = c
    # тень под крышей
    for y in range(wall_top, wall_top + 5):
        for x in range(8, W - 8):
            px[x, y] = mix(px[x, y], plank[0], 0.6 - (y - wall_top) * 0.1)
    # большие ворота с крестом
    gx0, gx1, gy0 = 44, W - 45, 58
    for y in range(gy0, 104):
        for x in range(gx0, gx1 + 1):
            b = (x - gx0) % 6
            c = plank[1] if b else plank[0]
            if b == 1:
                c = plank[2]
            px[x, y] = c
    for x in range(gx0, gx1 + 1):
        for yy in (gy0, gy0 + 1, 103, 102):
            px[x, yy] = plank[3] if yy in (gy0, 102) else plank[0]
    mid = (gx0 + gx1) // 2
    for y in range(gy0, 104):
        px[mid, y] = OUT
        px[mid + 1, y] = plank[0]
    # косые перекладины
    for i in range(0, 44):
        for side in (0, 1):
            x0 = gx0 + 2 + int(i * (mid - gx0 - 4) / 43) if side == 0 else gx1 - 2 - int(i * (gx1 - mid - 4) / 43)
            y0 = gy0 + 2 + i
            if y0 < 102:
                px[x0, y0] = plank[3]
                px[x0 + (1 if side == 0 else -1), y0] = plank[1]
    # кольца-ручки
    for hxp in (mid - 4, mid + 5):
        for (dx, dy) in ((0, 0), (1, 0), (-1, 1), (2, 1), (-1, 2), (2, 2), (0, 3), (1, 3)):
            px[hxp + dx - 1, 78 + dy] = IRON[3] if dy < 2 else IRON[1]
    # окошки под крышей
    for wx in (20, W - 32):
        rect(px, wx, 62, wx + 11, 72, hx("1a1820"))
        rect(px, wx + 1, 63, wx + 10, 71, hx("2a3448"))
        rect(px, wx + 1, 63, wx + 4, 65, hx("4a6080"))
        for y in range(62, 73):
            px[wx + 6, y] = plank[1]
        for x in range(wx, wx + 12):
            px[x, 67] = plank[1]
            px[x, 73] = plank[3]
    # крыша двускатная (вид спереди со щипцом и черепицей-гонтом)
    apex = (W // 2, 6)
    for y in range(4, wall_top + 4):
        half = int((y - 4) * (W / 2 + 2) / (wall_top))
        for x in range(W // 2 - half, W // 2 + half + 1):
            if 0 <= x < W:
                row = (y - 4) // 4
                off = 3 if row % 2 else 0
                c = roof[2]
                if (y - 4) % 4 == 3:
                    c = roof[0]
                elif (x + off) % 6 == 0:
                    c = roof[1]
                elif (y - 4) % 4 == 0:
                    c = roof[3]
                if x < W // 2 - half + 3 or x > W // 2 + half - 3:
                    c = roof[0] if (y % 2) else roof[1]
                # свет на левом скате
                if x < W // 2 and (y - 4) % 4 in (0, 1) and (x + off) % 6 in (2, 3):
                    c = roof[4]
                px[x, y] = c
    # конёк
    for y in range(4, 10):
        for x in range(W // 2 - 2, W // 2 + 3):
            px[x, y] = roof[3] if x < W // 2 else roof[1]
    # слуховое окно в щипце
    rect(px, W // 2 - 7, 22, W // 2 + 6, 34, plank[1])
    rect(px, W // 2 - 5, 24, W // 2 + 4, 33, hx("1a1820"))
    for x in range(W // 2 - 5, W // 2 + 5):
        px[x, 28] = plank[2]
    # стопка ящиков и мешков сбоку
    for (bx, by, bw, bh) in ((2, 86, 14, 12), (4, 76, 11, 10)):
        for y in range(by, by + bh):
            for x in range(bx, bx + bw):
                c = plank[2] if (y - by) % 4 else plank[0]
                if x in (bx, bx + bw - 1):
                    c = plank[1]
                px[x, y] = c
    for y in range(90, 104):
        for x in range(W - 18, W - 3):
            d = ((x - (W - 10.5)) / 7.5) ** 2 + ((y - 97) / 7.0) ** 2
            if d < 1.0:
                px[x, y] = hx("d8c08a") if d < 0.35 and x < W - 11 else (hx("b89a64") if d < 0.75 else hx("8a7044"))
    outline(im)
    save(im, "warehouse24")


# ------------------------------------------------------------------ лежащие стволы
BARK = {
    "oak": [hx("2e1c10"), hx("4a2e1a"), hx("664226"), hx("865a34"), hx("a87648")],
    "pine": [hx("2e1610"), hx("52281a"), hx("743c24"), hx("945232"), hx("b26c42")],
    "birch": [hx("3a3430"), hx("8a8478"), hx("c8c2b4"), hx("e4dfd2"), hx("f8f6ee")],
    "dead": [hx("2c2a28"), hx("4c4844"), hx("6a6560"), hx("8a847c"), hx("aaa49a")],
    "pink": [hx("3a1e1c"), hx("5e3030"), hx("7e4440"), hx("a05e56"), hx("c27a70")],
}
RINGS = [hx("7a5232"), hx("b08050"), hx("d4a870"), hx("ecca94")]


def trunk(fam, L=104, T=16, branches=False):
    b = BARK[fam]
    im = Image.new("RGBA", (L + 6, T + 6), (0, 0, 0, 0))
    px = im.load()
    rnd = random.Random(hash(fam) & 0xffff)
    ox, oy = 2, 2
    for x in range(L):
        # ствол немного сужается к верхушке (вправо)
        th = T - int(4 * x / L)
        y0 = (T - th) // 2
        for y in range(th):
            k = y / max(1, th - 1)
            c = b[3] if k < 0.18 else (b[2] if k < 0.62 else (b[1] if k < 0.88 else b[0]))
            if k < 0.08:
                c = b[4]
            # кора: продольные борозды
            if fam != "birch":
                if (y * 7 + (x // 9) * 3) % 5 == 0 and 0.15 < k < 0.85:
                    c = mix(c, b[0], 0.45)
                if rnd.random() < 0.07:
                    c = mix(c, b[4], 0.3)
            else:
                # берёза: чёрные чечевички поперёк
                if (x % 11 in (0, 1)) and rnd.random() < 0.6 and 0.1 < k < 0.9:
                    c = b[0] if rnd.random() < 0.7 else b[1]
            px[ox + x, oy + y0 + y] = c
    # срез (кольца) слева — эллипс
    ew = 5
    for y in range(T):
        for x in range(-ew, ew + 1):
            d = (x / ew) ** 2 + ((y - (T - 1) / 2) / (T / 2)) ** 2
            if d <= 1.0:
                r = math.sqrt(d)
                c = RINGS[3] if r < 0.25 else (RINGS[2] if r < 0.55 else (RINGS[1] if r < 0.82 else RINGS[0]))
                if abs(r - 0.4) < 0.07 or abs(r - 0.7) < 0.06:
                    c = RINGS[1]
                xx = ox + x + ew - 2
                if 0 <= xx < im.width:
                    px[xx, oy + y] = c
    # обрубки сучков
    for i in range(5):
        x = 22 + i * 16 + rnd.randint(-3, 3)
        if x >= L - 6:
            continue
        top = rnd.random() < 0.5
        th = T - int(4 * x / L)
        y0 = (T - th) // 2
        yy = oy + y0 + (0 if top else th - 1)
        px[ox + x, yy] = b[3]
        px[ox + x + 1, yy] = b[2]
        px[ox + x, yy + (-1 if top else 1)] = RINGS[2]
        px[ox + x + 1, yy + (-1 if top else 1)] = RINGS[1]
    outline(im)
    return im


def branch_icon():
    im = Image.new("RGBA", (16, 32), (0, 0, 0, 0))
    px = im.load()
    b = BARK["oak"]
    for y in range(2, 30):
        x = 8 + int(math.sin(y * 0.35) * 1.5)
        px[x, y] = b[3]
        px[x + 1, y] = b[2]
        if y % 7 == 3:
            # отросток
            d = 1 if (y // 7) % 2 else -1
            for k in range(1, 4):
                px[x + d * k + (1 if d > 0 else 0), y - k] = b[3] if k < 3 else b[2]
            # листик
            lx = x + d * 4 + (1 if d > 0 else 0)
            for (dx, dy) in ((0, -4), (0, -5), (d, -5), (d, -4), (0, -3)):
                q = (lx + dx, y + dy)
                if 0 <= q[0] < 16 and 0 <= q[1] < 32:
                    px[q] = hx("5a9a3e") if dy < -4 else hx("3e7a2e")
    px[8, 29] = RINGS[2]
    px[9, 29] = RINGS[1]
    outline(im)
    save(im, "icon_branch_long")


# ------------------------------------------------------------------ штабель брёвен (1..10 стволов)
def log_end(T, body, fam="oak", rnd=None):
    """бревно, лежащее торцом к зрителю: круглый срез снизу, тело уходит вверх-назад (вид 3/4)"""
    b = BARK[fam]
    W, H = T + 2, T + body + 2
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    px = im.load()
    r = T / 2.0
    cx = 1 + r - 0.5
    # тело (верх бревна, уходит назад)
    for y in range(1, 1 + body + int(r)):
        for x in range(1, 1 + T):
            k = (x - 1) / max(1, T - 1)
            c = b[3] if k < 0.2 else (b[2] if k < 0.6 else (b[1] if k < 0.85 else b[0]))
            if k < 0.1:
                c = b[4]
            if (x * 5 + y // 3) % 7 == 0 and 0.15 < k < 0.85:
                c = mix(c, b[0], 0.4)
            px[x, y] = c
    # торец
    cy = 1 + body + r - 0.5
    for y in range(H):
        for x in range(W):
            d = ((x - cx) / r) ** 2 + ((y - cy) / r) ** 2
            if d <= 1.0:
                rr = math.sqrt(d)
                c = RINGS[3] if rr < 0.22 else (RINGS[2] if rr < 0.5 else (RINGS[1] if rr < 0.8 else RINGS[0]))
                if abs(rr - 0.36) < 0.06 or abs(rr - 0.65) < 0.05:
                    c = RINGS[1]
                if rr > 0.88:
                    c = b[2] if y < cy else b[1]
                if rnd is not None and rr < 0.7 and rnd.random() < 0.03:
                    c = RINGS[0]
                px[x, y] = c
    outline(im)
    return im


def pile(n, fam="oak"):
    """штабель как на фото: торцы кругами пирамидой (снизу больше), тела брёвен уходят назад"""
    T = 15
    body = 12
    rows = []
    left = n
    for p in (4, 3, 2, 1):
        k = min(p, left)
        if k <= 0:
            break
        rows.append(k)
        left -= k
    while left > 0:
        rows[0] += 1
        left -= 1
    W = max(rows) * (T + 1) + 10
    H = body + 4 + T + (T - 3) * len(rows) + 10
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    rnd = random.Random(n * 7)
    base_y = H - 3
    # подкладки
    for x in range(2, W - 2):
        for y in range(base_y - 2, base_y + 1):
            im.putpixel((x, y), BARK["dead"][2] if y > base_y - 2 else BARK["dead"][3])
    # снизу вверх: верхний ряд лежит на нижних и закрывает их тела
    for r in range(len(rows)):
        cnt = rows[r]
        row_w = cnt * (T + 1)
        x0 = (W - row_w) // 2
        for i in range(cnt):
            lg = log_end(T, body + rnd.randint(-3, 3), fam, rnd)
            x = x0 + i * (T + 1) + rnd.randint(0, 1)
            y = base_y - 2 - lg.height - r * (T - 3) + rnd.randint(0, 1)
            im.alpha_composite(lg, (x - 1, y))
    save(im, "logpile24_%d" % n)


def stump_branches():
    """куча срезанных веток рядом с бревном (эффект на земле)"""
    im = Image.new("RGBA", (40, 18), (0, 0, 0, 0))
    px = im.load()
    rnd = random.Random(7)
    for i in range(9):
        x0 = rnd.randint(2, 20)
        y0 = rnd.randint(4, 14)
        ln = rnd.randint(10, 18)
        ang = rnd.uniform(-0.5, 0.5)
        for k in range(ln):
            x = int(x0 + math.cos(ang) * k)
            y = int(y0 + math.sin(ang) * k * 0.5)
            if 0 <= x < 40 and 0 <= y < 18:
                px[x, y] = BARK["oak"][3] if k % 3 else BARK["oak"][2]
        for k in range(3):
            x = int(x0 + math.cos(ang) * (ln - 2)) + rnd.randint(-2, 2)
            y = int(y0 + math.sin(ang) * ln * 0.5) + rnd.randint(-2, 1)
            if 0 <= x < 40 and 0 <= y < 18:
                px[x, y] = hx("4e8a36") if k else hx("6aa848")
    outline(im)
    save(im, "branch_heap24")


if __name__ == "__main__":
    random.seed(24)
    chest(14, 11, 5, name="chest_small24", bands=0)
    chest(20, 14, 6, name="chest_mid24", bands=2)
    chest(28, 17, 7, wood=[hx("3a2214"), hx("5a361e"), hx("7a4c2a"), hx("9a663a"), hx("bc8452")], name="chest_big24", bands=3)
    warehouse()
    for fam in BARK:
        save(trunk(fam), "trunk24_" + fam)
    branch_icon()
    for n in range(1, 11):
        pile(n)
    stump_branches()
    print("ok")

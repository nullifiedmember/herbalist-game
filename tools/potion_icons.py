# -*- coding: utf-8 -*-
"""Значки зелий v16 (32×32) по данным tools/potion_icons.json (пишет potion_design.py --write).
Основа задаёт посуду: вода — колбы, воск — баночки, спирт — бутылки, мёд — горшочки, лунная роса — кристальные флаконы.
Редкость: 1 — искорка, 2 — сияние, 3 — золото и ореол. Холодные — иней, горячие — пар.
Запуск: python tools/potion_icons.py  (из папки game). Превью: screenshots/v16_potions.png
"""
import json, os, math, colorsys
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
GAME = os.path.dirname(HERE)
ART = os.path.join(GAME, "art")
OUTLINE = (34, 22, 18, 255)


def hexc(s):
    return tuple(int(s[i:i + 2], 16) for i in (0, 2, 4))


def shade(c, k):
    """k<0 темнее и холоднее, k>0 светлее и теплее (сдвиг тона, как в остальном арте)"""
    r, g, b = [x / 255 for x in c]
    h, l, s = colorsys.rgb_to_hls(r, g, b)
    if k < 0:
        h = (h + 0.04 * -k) % 1.0 if 0.1 < h < 0.6 else (h - 0.03 * -k) % 1.0
        l = max(0.04, l * (1 + 0.42 * k))
        s = min(1, s * (1 + 0.15 * -k))
    else:
        h = (h - 0.025 * k) % 1.0 if 0.15 < h < 0.6 else h
        l = min(0.97, l + (1 - l) * 0.45 * k)
        s = s * (1 - 0.2 * k)
    r, g, b = colorsys.hls_to_rgb(h, l, s)
    return (int(r * 255), int(g * 255), int(b * 255), 255)


def hsh(*a):
    v = 0
    for x in a:
        v = (v * 131 + hash(str(x)) % 100003) % 1000003
    return v


class Canvas:
    def __init__(self):
        self.im = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
        self.p = self.im.load()

    def put(self, x, y, c):
        if 0 <= x < 32 and 0 <= y < 32:
            self.p[x, y] = c if len(c) == 4 else c + (255,)

    def get(self, x, y):
        return self.p[x, y] if 0 <= x < 32 and 0 <= y < 32 else (0, 0, 0, 0)


# ---------------------------------------------------------------- формы: функция (x,y)->(inside, nx) где nx — «нормаль» по x (-1..1)
def flask_round(x, y):  # круглая колба с горлышком
    cx, cy, r = 15.5, 21.0, 8.6
    d = math.hypot(x - cx, (y - cy) * 1.02)
    if d <= r:
        return True, (x - cx) / r, (y - cy) / r
    if 11 <= y <= 13.5 and abs(x - cx) <= 3.0:
        return True, (x - cx) / 3.0, -1
    return False, 0, 0


def flask_cone(x, y):  # коническая колба
    cx = 15.5
    if 11 <= y <= 29:
        t = (y - 11) / 18.0
        w = 2.6 + t * 9.5 if y < 28 else 11.6
        if abs(x - cx) <= w:
            return True, (x - cx) / w, t * 2 - 1
    return False, 0, 0


def flask_pear(x, y):  # грушевидная
    cx = 15.5
    if 11 <= y <= 29:
        t = (y - 11) / 18.0
        w = 2.6 + 7.4 * math.sin(min(1.0, t * 1.15) * math.pi * 0.62) ** 1.6
        if y > 26:
            w *= 1 - (y - 26) / 6.5
        if abs(x - cx) <= w:
            return True, (x - cx) / max(w, 1), t * 2 - 1
    return False, 0, 0


def bottle_square(x, y):  # квадратная бутылка
    cx = 15.5
    if 13 <= y <= 29 and abs(x - cx) <= 6.6:
        return True, (x - cx) / 6.6, (y - 21) / 8
    if 10 <= y < 13:
        w = 2.4 + (y - 10) * 1.4
        if abs(x - cx) <= w:
            return True, (x - cx) / w, -1
    if 7 <= y < 10 and abs(x - cx) <= 2.1:
        return True, (x - cx) / 2.1, -1
    return False, 0, 0


def bottle_tall(x, y):  # высокая узкая бутылка с плечиками
    cx = 15.5
    if 14 <= y <= 29:
        w = 4.8 if y < 28 else 4.4
        if abs(x - cx) <= w:
            return True, (x - cx) / w, (y - 21) / 8
    if 10 <= y < 14:
        w = 1.9 + (y - 10) * 0.8
        if abs(x - cx) <= w:
            return True, (x - cx) / w, -1
    if 6 <= y < 10 and abs(x - cx) <= 1.9:
        return True, (x - cx) / 1.9, -1
    return False, 0, 0


def bottle_hip(x, y):  # плоская фляжка
    cx, cy = 15.5, 21.5
    d = ((x - cx) / 9.0) ** 2 + ((y - cy) / 7.6) ** 2
    if d <= 1.0:
        return True, (x - cx) / 9.0, (y - cy) / 7.6
    if 11 <= y < 15 and abs(x - cx) <= 2.4:
        return True, (x - cx) / 2.4, -1
    return False, 0, 0


def jar(x, y):  # баночка
    cx = 15.5
    if 14 <= y <= 29:
        w = 8.6 if 15 <= y <= 28 else 8.0
        if abs(x - cx) <= w:
            return True, (x - cx) / w, (y - 22) / 7
    return False, 0, 0


def tin(x, y):  # низкая круглая жестянка
    cx = 15.5
    if 18 <= y <= 29 and abs(x - cx) <= 10.5:
        return True, (x - cx) / 10.5, (y - 23) / 6
    return False, 0, 0


def pot(x, y):  # пузатый горшочек
    cx, cy = 15.5, 22.0
    d = ((x - cx) / 10.0) ** 2 + ((y - cy) / 7.8) ** 2
    if d <= 1.0 and y <= 29:
        return True, (x - cx) / 10.0, (y - cy) / 7.8
    if 12 <= y < 16 and abs(x - cx) <= 6.4:
        return True, (x - cx) / 6.4, -1
    return False, 0, 0


def jug(x, y):  # кувшинчик
    cx = 15.5
    if 13 <= y <= 29:
        t = (y - 13) / 16.0
        w = 4.4 + 4.6 * math.sin(t * math.pi * 0.85)
        if abs(x - cx) <= w:
            return True, (x - cx) / w, t * 2 - 1
    if 10 <= y < 13 and abs(x - cx) <= 4.6:
        return True, (x - cx) / 4.6, -1
    return False, 0, 0


def crystal(x, y):  # граненый кристальный флакон
    cx = 15.5
    if 12 <= y <= 30:
        t = (y - 12) / 18.0
        w = 8.4 * (t / 0.45) if t < 0.45 else 8.4 * (1 - (t - 0.45) / 0.55) ** 0.8
        w = max(w, 2.2 if t < 0.1 else 0.6)
        if abs(x - cx) <= w:
            return True, (x - cx) / max(w, 1), t * 2 - 1
    return False, 0, 0


def crystal_tall(x, y):  # высокий шестигранный
    cx = 15.5
    if 10 <= y <= 30:
        t = (y - 10) / 20.0
        w = 3.0 + 3.8 * math.sin(t * math.pi) ** 0.6
        if abs(x - cx) <= w:
            return True, (x - cx) / w, t * 2 - 1
    return False, 0, 0


SHAPES = {
    "water": [(flask_round, 13.5), (flask_cone, 15.0), (flask_pear, 15.5)],
    "spirit": [(bottle_square, 16.0), (bottle_tall, 17.0), (bottle_hip, 17.0)],
    "wax": [(jar, 15.5), (tin, 19.5)],
    "honey": [(pot, 16.5), (jug, 16.0)],
    "moon_dew": [(crystal, 15.5), (crystal_tall, 14.0)],
}


def draw_icon(pid, d):
    base = d["base"]
    col = hexc(d["col"])
    rar = int(d["rarity"])
    temp = d["temp"]
    sh_list = SHAPES[base]
    shape, level = sh_list[hsh(pid, "shape") % len(sh_list)]
    c = Canvas()
    glass = base in ("water", "spirit", "moon_dew")
    inside = [[False] * 32 for _ in range(32)]
    for y in range(32):
        for x in range(32):
            ok, nx, ny = shape(x + 0.5, y + 0.5)
            if not ok:
                continue
            inside[y][x] = True
            lit = -nx * 0.7 - ny * 0.3
            if glass:
                if y + 0.5 >= level:
                    # жидкость: темнее к краям и вниз, светлее слева
                    k = 0.0
                    if lit > 0.45:
                        k = 0.35
                    elif lit < -0.35:
                        k = -0.55
                    if ny > 0.75:
                        k -= 0.3
                    if abs(y + 0.5 - level) < 1.0:
                        k = 0.55  # мениск
                    cc = shade(col, k)
                else:
                    # пустое стекло: прозрачное, с бликом
                    a = 70 if abs(nx) < 0.75 else 150
                    gl = (200, 225, 235)
                    cc = (gl[0], gl[1], gl[2], a)
                c.put(x, y, cc)
            else:
                # глиняная или жестяная посуда
                if base == "wax":
                    body = (226, 214, 190) if shape is jar else (160, 168, 178)
                else:
                    body = (176, 104, 58) if shape is pot else (196, 132, 78)
                k = 0.3 if lit > 0.4 else (-0.5 if lit < -0.35 else 0.0)
                if ny > 0.8:
                    k -= 0.25
                c.put(x, y, shade(body, k))
    # ярлык / пояс у глиняной посуды
    if base == "wax":
        top = 14 if shape is jar else 18
        # крышка-тряпочка цвета зелья + верёвочка
        for x in range(4, 28):
            for y in range(top - 3, top + 2):
                if inside[min(31, top)][x] or abs(x - 15.5) <= 9.5:
                    if abs(x - 15.5) <= (9.6 if shape is jar else 11.2) and y <= top + 1:
                        k = 0.3 if x < 12 else (-0.45 if x > 21 else 0.0)
                        c.put(x, y, shade(col, k + (-0.2 if y == top + 1 else 0)))
        for x in range(6, 26):
            if abs(x - 15.5) <= (9.0 if shape is jar else 10.5):
                c.put(x, top + 2, (120, 84, 50, 255))
        # окошко с мазью
        if shape is jar:
            for y in range(19, 26):
                for x in range(11, 21):
                    c.put(x, y, shade(col, 0.15 if x < 15 else -0.2))
            for x in range(11, 21):
                c.put(x, 18, shade((226, 214, 190), -0.6))
        else:
            for x in range(8, 24):
                c.put(x, 23, shade(col, -0.2))
                c.put(x, 24, shade(col, 0.1))
    elif base == "honey":
        # крышечка и капля мёда по боку
        topy = 12 if shape is pot else 10
        for x in range(9, 23):
            for y in range(topy - 2, topy + 1):
                if abs(x - 15.5) <= 6.8:
                    c.put(x, y, shade((120, 80, 44), 0.3 if x < 13 else (-0.4 if x > 19 else 0)))
        c.put(15, topy - 3, (90, 60, 34, 255)); c.put(16, topy - 3, (120, 80, 44, 255))
        for y in range(topy + 1, topy + 7):
            c.put(20, y, shade(col, 0.2 if y < topy + 5 else -0.2))
        c.put(19, topy + 1, shade(col, 0.4))
        # пояс-ярлык цвета зелья
        for x in range(4, 28):
            for y in (21, 22, 23):
                ok, nx, ny = shape(x + 0.5, y + 0.5)
                if ok:
                    c.put(x, y, shade(col, 0.25 if nx < -0.3 else (-0.35 if nx > 0.5 else 0.0)))
    else:
        # пробка
        tops = [y for y in range(32) if any(inside[y])]
        ty = tops[0]
        xs = [x for x in range(32) if inside[ty][x]]
        cw = max(2, (xs[-1] - xs[0]) // 2 + 1)
        cork = (150, 100, 56)
        if rar >= 3:
            cork = (232, 184, 58)
        elif base == "moon_dew":
            cork = (190, 200, 236)
        for y in range(ty - 3, ty + 1):
            for x in range(16 - cw, 16 + cw):
                k = 0.35 if x < 15 else (-0.45 if x >= 16 + cw - 1 else 0.0)
                c.put(x, y, shade(cork, k + (-0.2 if y == ty else 0)))
        if base == "moon_dew":
            c.put(15, ty - 4, shade(cork, 0.5)); c.put(16, ty - 4, shade(cork, 0.2))
            c.put(15, ty - 5, (255, 255, 255, 255))
        # блики на стекле
        for y in range(32):
            xs2 = [x for x in range(32) if inside[y][x]]
            if len(xs2) > 5 and y > ty + 2:
                c.put(xs2[0] + 1, y, (255, 255, 255, 170) if y % 5 != 0 else c.get(xs2[0] + 1, y))
        # ярлык на бутылках
        if base == "spirit" and shape is not bottle_hip:
            for y in range(20, 26):
                for x in range(12, 20):
                    if inside[y][x]:
                        c.put(x, y, (232, 220, 190, 255) if y not in (20, 25) else (200, 184, 150, 255))
            for x in range(13, 19):
                c.put(x, 22, shade(col, -0.3))
            c.put(13, 23, shade(col, -0.3)); c.put(14, 23, shade(col, -0.3))
        if base == "moon_dew":
            # грани
            for y in range(32):
                for x in range(32):
                    if inside[y][x] and (x == 15 or (x + y) % 9 == 0) and y > ty + 3:
                        px = c.get(x, y)
                        c.put(x, y, shade(px[:3], 0.35))
    # обводка
    out = Canvas()
    for y in range(32):
        for x in range(32):
            if c.get(x, y)[3] > 0:
                out.put(x, y, c.get(x, y))
    for y in range(32):
        for x in range(32):
            if c.get(x, y)[3] == 0 and any(c.get(x + dx, y + dy)[3] > 60 for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                out.put(x, y, OUTLINE)
    # иней / пар
    if temp == "cold":
        for (x, y) in [(6, 27), (8, 28), (24, 26), (26, 28), (7, 30), (25, 30)]:
            if out.get(x, y)[3] > 0:
                out.put(x, y, (230, 246, 255, 255))
    elif temp == "hot":
        for i, (x, y) in enumerate([(13, 4), (14, 3), (14, 2), (18, 5), (19, 4), (18, 3), (18, 2)]):
            if out.get(x, y)[3] == 0:
                out.put(x, y, (240, 240, 240, 150 - i * 10))
    # редкость
    if rar >= 1:
        sparks = [(26, 9), (5, 14), (27, 20), (4, 24), (22, 3)][: rar + 1 if rar < 3 else 5]
        gc = (255, 230, 120) if rar >= 3 else ((214, 170, 255) if rar == 2 else (180, 220, 255))
        for (x, y) in sparks:
            out.put(x, y, (255, 255, 255, 255))
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                if out.get(x + dx, y + dy)[3] == 0:
                    out.put(x + dx, y + dy, gc + (200,))
    if rar >= 2:
        # мягкий ореол по краю обводки
        gc = (255, 210, 90) if rar >= 3 else (190, 140, 255)
        halo = []
        for y in range(32):
            for x in range(32):
                if out.get(x, y)[3] == 0:
                    near = any(out.get(x + dx, y + dy)[:3] == OUTLINE[:3] and out.get(x + dx, y + dy)[3] == 255
                               for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))
                    if near and (x + y) % 2 == 0:
                        halo.append((x, y))
        for x, y in halo:
            out.put(x, y, gc + (110 if rar == 2 else 160,))
    if rar >= 3:
        # золотой ободок у горлышка
        for y in range(32):
            xs3 = [x for x in range(32) if out.get(x, y)[3] == 255 and out.get(x, y)[:3] != OUTLINE[:3]]
            if xs3:
                break
        for x in xs3:
            out.put(x, y, (255, 236, 150, 255))
    return out.im


def main():
    data = json.load(open(os.path.join(HERE, "potion_icons.json"), encoding="utf8"))
    ims = []
    for pid, d in data.items():
        im = draw_icon(pid, d)
        im.save(os.path.join(ART, "potion_%s.png" % pid))
        ims.append(im)
    sc, cols = 4, 16
    rows = (len(ims) + cols - 1) // cols
    big = Image.new("RGBA", (cols * (32 * sc + 6) + 6, rows * (32 * sc + 6) + 6), (52, 44, 40, 255))
    for i, im in enumerate(ims):
        big.alpha_composite(im.resize((32 * sc, 32 * sc), Image.NEAREST), (6 + (i % cols) * (32 * sc + 6), 6 + (i // cols) * (32 * sc + 6)))
    big.save(os.path.join(GAME, "..", "screenshots", "v16_potions.png"))
    print("значков:", len(ims))


if __name__ == "__main__":
    main()

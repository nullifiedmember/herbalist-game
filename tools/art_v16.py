# -*- coding: utf-8 -*-
"""Арт v16: комната зельевара (alch_room 960×540, показывается ×2), инструменты стола,
значки свойств prop_<n>.png 12×12, значки основ и бутылочек (32×32), бутылка для наливания.
Запуск: python tools/art_v16.py  (из папки game). Превью: screenshots/v16_alch_parts.png
"""
import os, math, colorsys, random
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
GAME = os.path.dirname(HERE)
ART = os.path.join(GAME, "art")
OUT = (30, 20, 16, 255)


def H(x, y, s=0):
    v = (x * 374761393 + y * 668265263 + s * 2147483647) & 0xFFFFFFFF
    v = ((v ^ (v >> 13)) * 1274126177) & 0xFFFFFFFF
    return ((v ^ (v >> 16)) & 0xFFFF) / 65535.0


def hx(s):
    return tuple(int(s[i:i + 2], 16) for i in (0, 2, 4)) + (255,)


def ramp(*a):
    return [hx(x) for x in a]


WOOD = ramp("24160e", "34201a", "4a2e1c", "623e24", "7c522e", "98683c", "b8864e", "d4a468")
DWOOD = ramp("1a100a", "261810", "362216", "4a2e1c", "5e3c24", "744c2e")
STONE = ramp("2a2420", "3a322c", "4c423a", "5e5248", "726458", "88786a", "a08e7e")
BRASS = ramp("3a2408", "5a3a10", "84581c", "b07c2c", "d4a044", "ecc870", "fff0b0")
IRON = ramp("16161c", "24242c", "34343e", "4a4a56", "64646e", "8a8a94", "b4b4bc")
CLAY = ramp("3a1e10", "5a2e18", "7a4022", "9a5a30", "b87444", "d49460", "ecb888")
GRANITE = ramp("2e2a2a", "433e3c", "5a5450", "726a64", "8c847c", "a8a098", "c8c0b8")
CERAM = ramp("4a5a6a", "6a7e92", "8ea4b8", "b0c4d4", "d0dee8", "eaf2f6", "ffffff")
LEAFG = ramp("10261a", "1a3a22", "26522c", "346e38", "4a8a44", "6aa852", "96c870")


class Img:
    def __init__(self, w, h, bg=(0, 0, 0, 0)):
        self.im = Image.new("RGBA", (w, h), bg)
        self.p = self.im.load()
        self.w, self.h = w, h

    def put(self, x, y, c):
        x, y = int(x), int(y)
        if 0 <= x < self.w and 0 <= y < self.h:
            if len(c) == 4 and c[3] < 255:
                o = self.p[x, y]
                a = c[3] / 255.0
                self.p[x, y] = (int(o[0] * (1 - a) + c[0] * a), int(o[1] * (1 - a) + c[1] * a), int(o[2] * (1 - a) + c[2] * a), max(o[3], c[3]))
            else:
                self.p[x, y] = c if len(c) == 4 else c + (255,)

    def get(self, x, y):
        return self.p[x, y] if 0 <= x < self.w and 0 <= y < self.h else (0, 0, 0, 0)

    def rect(self, x, y, w, h, c):
        for yy in range(y, y + h):
            for xx in range(x, x + w):
                self.put(xx, yy, c)

    def line(self, x0, y0, x1, y1, c):
        n = int(max(abs(x1 - x0), abs(y1 - y0))) + 1
        for i in range(n + 1):
            t = i / max(1, n)
            self.put(round(x0 + (x1 - x0) * t), round(y0 + (y1 - y0) * t), c)

    def outline(self, col=OUT):
        pts = []
        for y in range(self.h):
            for x in range(self.w):
                if self.p[x, y][3] == 0 and any(self.get(x + dx, y + dy)[3] > 100 for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                    pts.append((x, y))
        for x, y in pts:
            self.p[x, y] = col

    def save(self, name):
        self.im.save(os.path.join(ART, name + ".png"))
        return self.im


def ell(img, cx, cy, rx, ry, rmp, light=(-0.6, -0.7), band=None, k0=0):
    """залитый эллипс со светом: плоские полосы тень/основной/свет/блик"""
    for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
        for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
            dx, dy = (x + 0.5 - cx) / rx, (y + 0.5 - cy) / ry
            d = dx * dx + dy * dy
            if d > 1:
                continue
            nz = math.sqrt(max(0, 1 - d))
            lit = -(dx * light[0] + dy * light[1]) * 0.8 + nz * 0.5
            n = len(rmp)
            k = int(round((lit + 0.4) / 1.4 * (n - 1))) + k0
            img.put(x, y, rmp[max(0, min(n - 1, k))])


def cyl(img, x0, y0, w, h, rmp, k0=0):
    """вертикальный цилиндр: светлее слева"""
    n = len(rmp)
    for x in range(x0, x0 + w):
        t = (x + 0.5 - x0) / w
        lit = math.cos((t - 0.32) * math.pi * 1.1)
        k = int(round((lit + 0.2) / 1.2 * (n - 2))) + k0
        for y in range(y0, y0 + h):
            img.put(x, y, rmp[max(0, min(n - 1, k))])


# ================================================================== комната
def room():
    W, Hh = 960, 540
    im = Img(W, Hh, (20, 14, 10, 255))
    rnd = random.Random(7)
    # каменная стена с кладкой
    by = 0
    row = 0
    while by < 400:
        bh = 22 + int(H(row, 3, 1) * 8)
        bx = -int(H(row, 5, 2) * 40)
        while bx < W:
            bw = 40 + int(H(bx, row, 3) * 36)
            base = 2 + int(H(bx, row, 4) * 2.2)
            for y in range(by, min(400, by + bh)):
                for x in range(max(0, bx), min(W, bx + bw)):
                    if y == by or x == bx:
                        im.put(x, y, STONE[0])
                        continue
                    k = base
                    if y == by + 1 or x == bx + 1:
                        k += 1
                    if y >= by + bh - 2 or x >= bx + bw - 2:
                        k -= 1
                    if H(x // 4, y // 3, 9) < 0.05:
                        k -= 1
                    im.put(x, y, STONE[max(0, min(6, k))])
            bx += bw
        by += bh
        row += 1
    # тёплое освещение стены: от окна (справа) и огня (центр) — затемнение по краям
    for y in range(400):
        for x in range(W):
            c = im.get(x, y)
            fx = (x - 560) / 520.0
            fy = (y - 420) / 420.0
            warm = max(0.0, 1.0 - math.hypot(fx, fy))
            dark = 0.45 + 0.55 * warm
            r = int(c[0] * dark + 60 * warm * warm)
            g = int(c[1] * dark + 30 * warm * warm)
            b = int(c[2] * dark + 6 * warm * warm)
            im.p[x, y] = (min(255, r), min(255, g), min(255, b), 255)
    # балки потолка
    for bx0 in (0, 300, 620, 900):
        for y in range(0, 26):
            for x in range(bx0 - 14, bx0 + 60):
                k = 4 if y < 4 else (3 if y < 20 else 1)
                if (x + int(H(x, 0, 1) * 3)) % 23 == 0:
                    k -= 1
                im.put(x, y, DWOOD[max(0, min(5, k))])
    for x in range(W):
        for y in range(26, 34):
            im.put(x, y, DWOOD[3 if y < 29 else 1])
    # окно справа: ночное небо? — тёплый вечер: закат за переплётом
    wx, wy, ww, wh = 690, 70, 170, 190
    for y in range(wy, wy + wh):
        for x in range(wx, wx + ww):
            t = (y - wy) / wh
            sky = (int(250 - 90 * t), int(190 - 110 * t), int(130 - 40 * t), 255)
            im.put(x, y, sky)
    # силуэт леса в окне
    for layer, (base_h, col) in enumerate([(70, (110, 70, 80, 255)), (44, (62, 40, 54, 255))]):
        for t in range(9):
            tx = wx + 6 + t * 21 + int(H(t, layer, 4) * 10) - layer * 9
            th = base_h * (0.7 + 0.5 * H(t, layer, 5))
            for y in range(int(wy + wh - th), wy + wh):
                w = (y - (wy + wh - th)) / th * 11 + 1
                if (y - int(wy + wh - th)) % 9 > 6:
                    w -= 2
                for x in range(int(tx - w), int(tx + w) + 1):
                    if wx <= x < wx + ww:
                        im.put(x, y, col)
    # солнце
    ell(im, wx + 110, wy + 118, 16, 16, [hx("f8c070"), hx("fcd890"), hx("fff0c0")])
    # рама и переплёт (крест по центру)
    for (x, y, w, h) in [(wx - 8, wy - 8, ww + 16, 8), (wx - 8, wy + wh, ww + 16, 10), (wx - 8, wy, 8, wh), (wx + ww, wy, 8, wh),
                         (wx + ww // 2 - 3, wy, 6, wh), (wx, wy + wh // 2 - 3, ww, 6)]:
        for yy in range(y, y + h):
            for xx in range(x, x + w):
                k = 4 if (yy == y or xx == x) else (2 if (yy == y + h - 1 or xx == x + w - 1) else 3)
                im.put(xx, yy, WOOD[k])
    # подоконник с горшочком
    for y in range(wy + wh + 10, wy + wh + 18):
        for x in range(wx - 20, wx + ww + 20):
            im.put(x, y, WOOD[5 if y < wy + wh + 12 else 3])
    # луч света из окна по стене (мягкий)
    for y in range(wy + wh, 420):
        for x in range(500, wx + ww):
            t = (y - wy - wh) / 230.0
            x0 = wx - t * 190
            x1 = wx + ww - t * 120
            if x0 < x < x1:
                c = im.get(x, y)
                im.p[x, y] = (min(255, c[0] + 26), min(255, c[1] + 16), min(255, c[2] + 4), 255)
    # пучки трав под балкой
    for i, hx0 in enumerate([340, 380, 420, 460, 520, 560, 600]):
        col = [LEAFG, ramp("3a2a4a", "54406a", "70588a", "9070b0", "b090d0", "d0b8ec", "f0e0ff"), ramp("4a3a10", "6a5418", "8e7224", "b49234", "d0b048", "e8cc6a", "f8e8a0")][i % 3]
        im.line(hx0, 34, hx0, 48, (120, 90, 60, 255))
        for k in range(26):
            a = (H(i, k, 2) - 0.5) * 0.9
            ln = 18 + H(i, k, 3) * 22
            for s in range(int(ln)):
                x = hx0 + math.sin(a) * s * 0.6
                y = 50 + s
                im.put(x, y, col[2 + int(H(k, s, 4) * 3)] if s < ln - 3 else col[5])
        im.rect(hx0 - 3, 48, 7, 4, (170, 130, 80, 255))
    # полки слева — шкаф для трав (ячейки)
    cx0, cy0, cw, ch = 16, 54, 210, 330
    for y in range(cy0, cy0 + ch):
        for x in range(cx0, cx0 + cw):
            gr = H(x // 1, y // 7, 5)
            k = 2 + (1 if gr > 0.6 else 0) - (1 if gr < 0.12 else 0)
            im.put(x, y, WOOD[k])
    for x in range(cx0, cx0 + cw):
        for y in range(cy0, cy0 + 8):
            im.put(x, y, WOOD[6 if y == cy0 else 5 if y < cy0 + 3 else 4])
    # 4×4 ячейки 46×74 (на экране 92×148)
    for r in range(4):
        for c in range(4):
            x0 = cx0 + 10 + c * 48
            y0 = cy0 + 14 + r * 78
            for y in range(y0, y0 + 72):
                for x in range(x0, x0 + 44):
                    k = 1 if (x < x0 + 2 or y < y0 + 3) else 2
                    if y > y0 + 64:
                        k = 4 if y == y0 + 65 else 3
                    im.put(x, y, DWOOD[k] if k < 4 else WOOD[k])
    # правая полка с основами
    sx0, sy0 = 760, 300
    for shelf_y in (sy0 + 70, sy0 + 150):
        for y in range(shelf_y, shelf_y + 8):
            for x in range(sx0 - 20, sx0 + 190):
                im.put(x, y, WOOD[6 if y == shelf_y else (5 if y < shelf_y + 3 else 3)])
        for bx in (sx0 - 6, sx0 + 168):
            for y in range(shelf_y + 8, shelf_y + 20):
                for x in range(bx, bx + 8):
                    im.put(x, y, WOOD[3 if x < bx + 4 else 2])
    # стол (нижняя часть): толстые доски
    ty = 392
    for y in range(ty, Hh):
        for x in range(W):
            plank = (y - ty) // 26
            seam = (y - ty) % 26 == 0
            off = int(H(plank, 0, 6) * 300)
            yy = (y - ty) % 26
            gr = H(plank * 31 + yy, (x + off + int(H(plank, yy, 3) * 200)) // 70, 7)
            k = 4 + (1 if gr > 0.82 else 0) - (1 if gr < 0.12 else 0)
            if (y - ty) % 26 == 1:
                k += 1
            if seam:
                k = 1
            # кромка стола
            if y < ty + 10:
                k = 6 if y < ty + 2 else (5 if y < ty + 6 else 3)
            if (x + off) % 197 == 0 and not seam:
                k = 2
            # к краям темнее
            c = WOOD[max(0, min(7, k))]
            fx = abs(x - 520) / 560.0
            m = 1.0 - fx * 0.45 - (y - ty) / 600.0
            im.put(x, y, (int(c[0] * m), int(c[1] * m), int(c[2] * m), 255))
    # тень от котла и пятно тёплого света на столе
    for y in range(ty + 10, Hh):
        for x in range(W):
            d = math.hypot((x - 500) / 330.0, (y - ty - 40) / 120.0)
            if d < 1:
                c = im.get(x, y)
                a = (1 - d) * 0.35
                im.p[x, y] = (min(255, int(c[0] + 90 * a)), min(255, int(c[1] + 50 * a)), min(255, int(c[2] + 10 * a)), 255)
    # мелочи на столе: свеча, свиток, рассыпанные лепестки
    for (px, py) in [(612, 500), (616, 503), (380, 520), (840, 470), (845, 474), (300, 470)]:
        im.put(px, py, (200, 120, 160, 255)); im.put(px + 1, py, (230, 160, 190, 255))
    return im


# ================================================================== инструменты
def mortar():
    im = Img(64, 52)
    # каменная ступка: чаша-полуэллипс
    for y in range(14, 50):
        for x in range(4, 60):
            dx = (x + 0.5 - 32) / 27.0
            dy = (y + 0.5 - 14) / 35.0
            if dx * dx + dy * dy * 1.0 <= 1 and y >= 14:
                lit = -dx * 0.8 - dy * 0.3
                k = 4 if lit > 0.25 else (3 if lit > -0.25 else (2 if lit > -0.6 else 1))
                if H(x, y, 3) < 0.07:
                    k -= 1
                im.put(x, y, GRANITE[max(0, k)])
    # ободок и тёмная внутренность
    ell(im, 32, 14, 27, 8, [GRANITE[3], GRANITE[4], GRANITE[5], GRANITE[6]])
    ell(im, 32, 15, 22, 5.5, [GRANITE[0], GRANITE[1], GRANITE[1], GRANITE[2]], light=(0.6, 0.7))
    # ножка
    for y in range(46, 52):
        for x in range(18, 46):
            im.put(x, y, GRANITE[3 if x < 28 else 2 if x < 40 else 1])
    im.outline()
    return im.save("st_mortar")


def pestle():
    im = Img(16, 44)
    for y in range(2, 42):
        w = 3.2 + (3.6 if y > 30 else (y - 2) / 28.0 * 1.2)
        for x in range(16):
            d = (x + 0.5 - 8) / w
            if abs(d) <= 1:
                k = 5 if d < -0.3 else (4 if d < 0.3 else 2)
                im.put(x, y, GRANITE[k] if y > 26 else WOOD[k + 1])
    im.outline()
    return im.save("st_pestle")


def board():
    im = Img(110, 50)
    # разделочная доска с ручкой
    for y in range(8, 46):
        for x in range(4, 92):
            r = 6
            if (x < 4 + r and y < 8 + r and math.hypot(x - 4 - r, y - 8 - r) > r) or (x < 4 + r and y > 45 - r and math.hypot(x - 4 - r, y - 45 + r) > r) \
                    or (x > 91 - r and y < 8 + r and math.hypot(x - 91 + r, y - 8 - r) > r) or (x > 91 - r and y > 45 - r and math.hypot(x - 91 + r, y - 45 + r) > r):
                continue
            gr = H(x // 6, y, 2)
            k = 5 + (1 if gr > 0.75 else 0) - (1 if gr < 0.2 else 0)
            if y > 40:
                k = 3
            if y < 10:
                k = 6
            im.put(x, y, WOOD[k])
    for y in range(20, 34):
        for x in range(90, 108):
            if math.hypot(x - 100, y - 27) < 8:
                im.put(x, y, WOOD[5 if y < 27 else 3])
    ell(im, 101, 27, 2.5, 2.5, [WOOD[0], WOOD[1]])
    # следы ножа
    for i in range(7):
        x0 = 20 + i * 10
        im.line(x0, 16 + i % 3, x0 + 6, 30 + i % 4, WOOD[4])
    im.outline()
    return im.save("st_board")


def knife():
    im = Img(56, 16)
    for x in range(2, 36):
        top = 4 + (0 if x > 8 else (8 - x) * 0.6)
        for y in range(int(top), 11):
            k = 6 if y == int(top) else (5 if y < 7 else 4)
            if y == 10:
                k = 3
            im.put(x, y, IRON[k])
    for x in range(36, 54):
        for y in range(5, 11):
            im.put(x, y, WOOD[5 if y < 7 else 3])
    for x in (40, 47):
        im.put(x, 7, BRASS[5])
    im.outline()
    return im.save("st_knife")


def brazier():
    im = Img(72, 70)
    # железная жаровня на трёх ножках с решёткой
    for leg in (14, 36, 58):
        for y in range(40, 68):
            im.put(leg + (y - 40) // 9 * (1 if leg > 36 else -1 if leg < 36 else 0), y, IRON[3])
            im.put(leg + 1 + (y - 40) // 9 * (1 if leg > 36 else -1 if leg < 36 else 0), y, IRON[2])
    for y in range(28, 46):
        for x in range(6, 66):
            dx = (x + 0.5 - 36) / 30.0
            dy = (y + 0.5 - 28) / 18.0
            if dx * dx + dy * dy <= 1:
                lit = -dx * 0.7
                im.put(x, y, IRON[4 if lit > 0.3 else (3 if lit > -0.3 else 2)])
    ell(im, 36, 28, 30, 7, [IRON[3], IRON[4], IRON[5], IRON[6]])
    # угли
    ell(im, 36, 29, 25, 5, [hx("3a0a04"), hx("6a1808"), hx("a83010"), hx("e06018"), hx("f8a030")])
    for i in range(30):
        x = 14 + H(i, 1, 2) * 44
        y = 26 + H(i, 2, 3) * 6
        im.put(x, y, hx("fcd060") if i % 3 == 0 else hx("2a1008"))
    # решётка
    for x in range(10, 63, 6):
        im.line(x, 22, x, 24, IRON[5])
    im.line(9, 22, 63, 22, IRON[5])
    im.outline()
    return im.save("st_brazier")


def bowl():
    im = Img(80, 40)
    # керамическая миска с холодной водой
    for y in range(10, 36):
        for x in range(4, 76):
            dx = (x + 0.5 - 40) / 36.0
            dy = (y + 0.5 - 10) / 26.0
            if dx * dx + dy * dy <= 1:
                lit = -dx * 0.8 - dy * 0.2
                k = 5 if lit > 0.35 else (4 if lit > -0.1 else (3 if lit > -0.5 else 2))
                im.put(x, y, CERAM[k])
    # синий поясок
    for x in range(8, 72):
        dx = (x + 0.5 - 40) / 36.0
        y = int(10 + 26 * math.sqrt(max(0, 1 - dx * dx)) * 0.45)
        im.put(x, y, hx("3a5a9a"))
        im.put(x, y + 1, hx("5a7aba"))
    ell(im, 40, 10, 36, 7, [CERAM[4], CERAM[5], CERAM[6]])
    ell(im, 40, 11, 32, 5, [hx("2a5a8a"), hx("3a74a8"), hx("5a98c8"), hx("8ac0e8")], light=(0.5, 0.6))
    for (x, y) in [(28, 9), (29, 9), (46, 12), (47, 12), (52, 10)]:
        im.put(x, y, hx("e0f4ff"))
    im.outline()
    return im.save("st_bowl")


def ladle():
    im = Img(24, 84)
    for y in range(2, 66):
        for x in (11, 12):
            im.put(x, y, WOOD[5 if x == 11 else 3])
    ell(im, 12, 72, 9, 8, [WOOD[1], WOOD[2], WOOD[4], WOOD[5], WOOD[6]])
    ell(im, 12, 70, 6, 4, [WOOD[1], WOOD[2], WOOD[3]], light=(0.6, 0.7))
    im.outline()
    return im.save("st_ladle")


# ================================================================== значки свойств 12×12
PROPS = ["Свежесть", "Покой", "Сон", "Тепло", "Исцеление", "Сила", "Жгучесть", "Холод", "Огонь", "Свет", "Тьма", "Чары"]


def prop_icons():
    ims = []
    for i in range(12):
        im = Img(12, 12)
        if i == 0:   # Свежесть: капля-листик
            for y in range(1, 11):
                for x in range(1, 11):
                    if abs(x - 5.5) + abs(y - 5.5) * 0.8 < 4.8 - (y < 4) * 0.5:
                        im.put(x, y, LEAFG[5] if x < 5 else LEAFG[4])
            im.line(3, 9, 8, 3, LEAFG[2])
        elif i == 1:  # Покой: волна
            for x in range(1, 11):
                y = 6 + round(math.sin(x * 0.9) * 2)
                im.put(x, y, hx("7cc0d8")); im.put(x, y + 1, hx("4a90b0"))
            for x in range(2, 10):
                y = 3 + round(math.sin(x * 0.9 + 1) * 1)
                im.put(x, y, hx("a8e0f0"))
        elif i == 2:  # Сон: полумесяц
            ell(im, 6, 6, 4.5, 4.5, [hx("6a58b0"), hx("8a78d0"), hx("b0a0f0")])
            ell(im, 8, 4.5, 3.6, 3.6, [(0, 0, 0, 0)])
            for y in range(12):
                for x in range(12):
                    if math.hypot(x + 0.5 - 8, y + 0.5 - 4.5) < 3.6:
                        im.p[x, y] = (0, 0, 0, 0)
        elif i == 3:  # Тепло: солнышко
            ell(im, 6, 6, 2.6, 2.6, [hx("e08020"), hx("f8b040"), hx("fcd880")])
            for a in range(8):
                ang = a * math.pi / 4
                im.put(6 + round(math.cos(ang) * 4.6) - 0.5, 6 + round(math.sin(ang) * 4.6) - 0.5, hx("f8a030"))
        elif i == 4:  # Исцеление: крест-сердце
            for y in range(2, 10):
                for x in range(2, 10):
                    if (4 <= x <= 7) or (4 <= y <= 7):
                        im.put(x, y, hx("f0d070") if x < 6 else hx("d0a840"))
            im.put(4, 4, hx("fff4c0"))
        elif i == 5:  # Сила: кулак-гиря (ромб)
            for y in range(1, 11):
                for x in range(1, 11):
                    if abs(x - 5.5) + abs(y - 5.5) < 5:
                        im.put(x, y, hx("8ab050") if x + y < 11 else hx("5e8a3a"))
            im.put(5, 3, hx("c8e890"))
        elif i == 6:  # Жгучесть: колючка
            for k in range(4):
                im.line(2 + k * 2, 10, 4 + k * 2, 2 + (k % 2) * 2, hx("d04a30"))
            im.line(1, 10, 10, 10, hx("8a2a1a"))
        elif i == 7:  # Холод: снежинка
            for a in range(3):
                ang = a * math.pi / 3
                im.line(6 - math.cos(ang) * 4.5, 6 - math.sin(ang) * 4.5, 6 + math.cos(ang) * 4.5, 6 + math.sin(ang) * 4.5, hx("b8e4ff"))
            im.put(6, 6, hx("ffffff"))
        elif i == 8:  # Огонь: язычок
            for y in range(1, 11):
                w = (y - 1) / 9.0 * 3.8
                for x in range(12):
                    if abs(x + 0.5 - 6 - math.sin(y * 0.6) * 0.6) <= w:
                        im.put(x, y, hx("fce060") if abs(x + 0.5 - 6) < w * 0.4 and y > 5 else hx("f06018"))
        elif i == 9:  # Свет: звезда
            for a in range(4):
                ang = a * math.pi / 2
                im.line(6, 6, 6 + math.cos(ang) * 5, 6 + math.sin(ang) * 5, hx("fff0a0"))
            for a in range(4):
                ang = a * math.pi / 2 + math.pi / 4
                im.line(6, 6, 6 + math.cos(ang) * 3, 6 + math.sin(ang) * 3, hx("f8d860"))
            im.put(6, 6, hx("ffffff"))
        elif i == 10:  # Тьма: чёрное солнце с ободком
            ell(im, 6, 6, 4.5, 4.5, [hx("2a1440"), hx("3a2058"), hx("5a3a80")])
            ell(im, 6, 6, 2.5, 2.5, [hx("0a0410")])
        elif i == 11:  # Чары: руна-искра
            for (x, y) in [(6, 1), (6, 2), (5, 3), (7, 3), (4, 5), (8, 5), (6, 5), (6, 6), (5, 8), (7, 8), (6, 10), (3, 7), (9, 7)]:
                im.put(x, y, hx("d090f8"))
            im.put(6, 4, hx("ffffff"))
        im.outline()
        im.save("prop_%d" % i)
        ims.append(im.im)
    return ims


# ================================================================== основы и бутылочки 32×32 + бутылка для наливания
def bottle(kind, big=False):
    w, h = (24, 40) if big else (32, 32)
    im = Img(w, h)
    cx = w / 2
    liq = {"water_cold": (hx("8ac8f0"), "c"), "water_warm": (hx("7ab4d0"), "w"), "water_hot": (hx("6aa0c8"), "h"),
           "spirit": (hx("d8ecd0"), ""), "moon_dew": (hx("b8c8f8"), "m"), "bottle": (None, "")}[kind]
    top = 6 if not big else 4
    body_y = 13 if not big else 14
    for y in range(top, h - 2):
        for x in range(w):
            if y < body_y:
                rw = 2.4 if y >= top + 3 else 2.8
            else:
                R = (h - 2 - body_y) / 2.0
                cyb = body_y + R
                rw = max(2.4, math.sqrt(max(0.0, R * R - (y + 0.5 - cyb) ** 2)) * (w * 0.4 / R))
            d = (x + 0.5 - cx) / rw
            if abs(d) > 1:
                continue
            lvl = body_y + 3
            if liq[0] is not None and y >= lvl:
                k = 0.0
                c = liq[0]
                if d < -0.4:
                    c = tuple(min(255, int(v * 1.18)) for v in c[:3]) + (255,)
                elif d > 0.45:
                    c = tuple(int(v * 0.7) for v in c[:3]) + (255,)
                im.put(x, y, c)
            else:
                im.put(x, y, (210, 230, 238, 90 if abs(d) < 0.7 else 170))
        # блик
    for y in range(body_y + 3, h - 4):
        im.put(int(cx - w * 0.22), y, (255, 255, 255, 190))
    # пробка
    for y in range(top - 3, top + 1):
        for x in range(int(cx - 3), int(cx + 3)):
            im.put(x, y, WOOD[6 if x < cx - 1 else 4] if kind != "moon_dew" else CERAM[5])
    im.outline()
    if liq[1] == "c":
        for (x, y) in [(int(cx - 9), h - 6), (int(cx + 8), h - 8), (int(cx - 6), h - 3)]:
            im.put(x, y, hx("e8f8ff"))
    elif liq[1] == "h":
        for i, (x, y) in enumerate([(int(cx - 2), 2), (int(cx - 3), 1), (int(cx + 2), 2), (int(cx + 3), 0)]):
            im.put(x, y, (245, 245, 245, 170))
    return im


def wax_block():
    im = Img(32, 32)
    for y in range(14, 28):
        for x in range(5, 27):
            k = 4 if x < 10 else (2 if x > 23 else 3)
            if y < 16:
                k = 5
            im.put(x, y, ramp("6a4a10", "9a7020", "c89a38", "e8c060", "f8dc90", "fff0c8")[k])
    # соты-ячейки
    for (x, y) in [(10, 18), (15, 18), (20, 18), (12, 22), (17, 22), (22, 22)]:
        for dx, dy in ((0, 0), (1, 0), (0, 1), (1, 1)):
            im.put(x + dx, y + dy, hx("b8862a"))
    im.outline()
    return im


def honey_pot():
    im = Img(32, 32)
    ell(im, 16, 21, 10, 8, CLAY[1:])
    for y in range(10, 15):
        for x in range(10, 22):
            im.put(x, y, CLAY[4 if x < 14 else 3 if x < 19 else 2])
    ell(im, 16, 10, 6.5, 2.4, [hx("8a5a10"), hx("c88a20"), hx("f0b840")])
    for y in range(11, 18):
        im.put(19, y, hx("f0b030"))
    im.put(19, 18, hx("c88a20"))
    for x in range(7, 26):
        im.put(x, 20, hx("f0b030")); im.put(x, 21, hx("c88a20"))
    im.outline()
    return im


def base_icons():
    out = []
    for k in ("bottle", "water_cold", "water_warm", "water_hot", "spirit", "moon_dew"):
        b = bottle(k)
        b.save("icon_%s" % k)
        out.append(b.im)
        bb = bottle(k, True)
        bb.save("pour_%s" % k)
    w = wax_block(); w.save("icon_wax"); out.append(w.im)
    hp = honey_pot(); hp.save("icon_honey"); out.append(hp.im)
    # большие для наливания: воск и мёд — в виде горшочка
    Image.open(os.path.join(ART, "icon_honey.png")).save(os.path.join(ART, "pour_honey.png"))
    Image.open(os.path.join(ART, "icon_wax.png")).save(os.path.join(ART, "pour_wax.png"))
    return out


def hearth():
    im = Img(230, 64)
    # каменное кольцо очага с поленьями
    for i in range(14):
        a = math.pi + math.pi * i / 13.0
        cx = 115 + math.cos(a) * 100
        cy = 40 + math.sin(a) * 12
    for i in range(16):
        t = i / 15.0
        cx = 14 + t * 202
        cy = 46 + math.sin(t * math.pi) * 6
        ell(im, cx, cy, 9 + H(i, 1, 2) * 3, 7 + H(i, 2, 3) * 2, GRANITE[1:], k0=0)
    # поленья крест-накрест
    for (x0, y0, x1, y1) in [(60, 44, 170, 30), (64, 30, 172, 46), (90, 48, 150, 26)]:
        n = int(math.hypot(x1 - x0, y1 - y0))
        for k in range(n):
            t = k / n
            x = x0 + (x1 - x0) * t
            y = y0 + (y1 - y0) * t
            for d in range(-4, 5):
                c = WOOD[4 if d < -1 else (3 if d < 2 else 1)]
                if abs(d) == 4:
                    c = DWOOD[1]
                im.put(x, y + d, c)
        ell(im, x1, y1, 4, 4.5, [hx("8a5a30"), hx("b07840"), hx("d8a060")])
    # угли
    for i in range(60):
        x = 70 + H(i, 3, 1) * 90
        y = 40 + H(i, 4, 2) * 10
        im.put(x, y, hx("f8a030") if i % 3 else hx("fce070"))
        im.put(x + 1, y, hx("c84a10"))
    im.outline()
    return im.save("st_hearth")


def potion_book():
    im = Img(40, 34)
    for y in range(4, 32):
        for x in range(2, 38):
            im.put(x, y, hx("6a2a1e") if x < 4 or x > 35 or y > 29 else hx("e8dcb8") if x != 19 and x != 20 else hx("9a7a5a"))
    for y in range(8, 28, 3):
        for x in range(6, 17):
            if H(x, y, 2) > 0.3:
                im.put(x, y, hx("8a7a68"))
    ell(im, 28, 18, 5, 6, [hx("4a1a6a"), hx("7a3aa0"), hx("b070e0"), hx("e0b0ff")])
    im.rect(27, 9, 3, 4, hx("8a5a30"))
    im.rect(23, 4, 2, 6, hx("c83030"))
    im.outline()
    return im.save("icon_potionbook")


SKIN = ramp("6a3a2a", "9a5a44", "c8806a", "e8a88c", "f8c8ac", "ffe4d0")


def hand(grab):
    im = Img(26, 26)
    # ладонь
    ell(im, 13, 16, 7.5, 7, SKIN[1:])
    if grab:
        # сжатые пальцы — валик сверху
        for i in range(4):
            ell(im, 7.5 + i * 3.7, 10.5, 2.2, 2.6, SKIN[1:])
        ell(im, 5, 16, 2.4, 3.6, SKIN[1:])
    else:
        for i, ln in enumerate([7, 9, 8.5, 6.5]):
            x = 7.5 + i * 3.7
            for y in range(int(11 - ln), 12):
                for dx in (-1, 0, 1):
                    im.put(x + dx, y, SKIN[4 if dx < 0 else (3 if dx == 0 else 2)])
            im.put(x, 11 - ln, SKIN[5])
        for k in range(6):
            im.put(4 - k * 0.4, 15 - k, SKIN[3]); im.put(5 - k * 0.4, 15 - k, SKIN[2])
    # рукав
    for y in range(21, 26):
        for x in range(8, 19):
            im.put(x, y, hx("5a7a4a") if x < 14 else hx("3e5a34"))
    im.outline()
    return im.save("hand_grab" if grab else "hand_open")


def basket():
    im = Img(76, 52)
    for y in range(14, 50):
        for x in range(4, 72):
            t = (y - 14) / 36.0
            w = 34 - t * 6
            if abs(x + 0.5 - 38) <= w:
                band = (y - 14) // 5
                yy = (y - 14) % 5
                sh = 3 if band % 2 else 0
                strand = ((x + sh) // 7) % 2
                xx = (x + sh) % 7
                k = 4 if strand else 3
                if yy == 0:
                    k = 1
                elif yy == 1:
                    k += 1
                elif yy == 4:
                    k -= 1
                if xx == 0:
                    k -= 1
                if x < 38 - w + 3:
                    k -= 1
                if x > 38 + w - 5:
                    k -= 2
                im.put(x, y, ramp("3a2410", "5a3a18", "7a5424", "9a7034", "b88c48", "d4aa64", "ecc888")[max(0, min(6, k))])
    # ободок
    for x in range(3, 74):
        for y in (13, 14, 15):
            im.put(x, y, ramp("5a3a18", "9a7034", "d4aa64", "ecc888")[3 - (y - 13)])
    # ручка
    for i in range(60):
        a = math.pi + math.pi * i / 59
        x = 38 + math.cos(a) * 30
        y = 14 + math.sin(a) * 13
        im.put(x, y, hx("b88c48")); im.put(x, y + 1, hx("7a5424"))
    im.outline()
    return im.save("harvest_basket")


def critters():
    bee = Img(12, 10)
    ell(bee, 6, 6, 4, 3, [hx("2a2010"), hx("e8b020"), hx("f8d040")])
    for x in (4, 7):
        for y in range(3, 10):
            bee.put(x, y, hx("201810"))
    ell(bee, 5, 2.5, 2.2, 1.6, [hx("c8e0f0"), hx("ffffff")])
    ell(bee, 8, 2.5, 2.2, 1.6, [hx("c8e0f0"), hx("ffffff")])
    bee.outline(); bee.save("fx_bee")
    bf = Img(16, 12)
    for (cx, cy, r) in [(4, 4, 3.5), (12, 4, 3.5), (5, 9, 2.4), (11, 9, 2.4)]:
        ell(bf, cx, cy, r, r, [hx("3a5aa8"), hx("5a8ae0"), hx("9ac0f8")])
    for y in range(2, 11):
        bf.put(8, y, hx("2a2030"))
    bf.outline(); bf.save("fx_butterfly")
    # котёнок: голова с ушами и лапка
    kt = Img(30, 26)
    ell(kt, 15, 16, 10, 8, [hx("8a4a1a"), hx("c8722a"), hx("e8984a"), hx("f8c080")])
    for sx in (-1, 1):
        for i in range(7):
            for j in range(i + 1):
                kt.put(15 + sx * (6 + j - i // 2) , 9 - (6 - i), hx("c8722a") if j else hx("8a4a1a"))
    for ex in (11, 19):
        kt.put(ex, 15, hx("1a1a10")); kt.put(ex, 16, hx("1a1a10")); kt.put(ex - 1, 15, hx("ffffff"))
    kt.put(15, 18, hx("e86a7a"))
    kt.outline(); kt.save("fx_kitten")
    # паутинка
    wb = Img(40, 40)
    for a in range(8):
        ang = a * math.pi / 4
        wb.line(20, 20, 20 + math.cos(ang) * 19, 20 + math.sin(ang) * 19, (240, 240, 250, 200))
    for r in (6, 11, 16):
        for a in range(8):
            a0 = a * math.pi / 4; a1 = a0 + math.pi / 4
            wb.line(20 + math.cos(a0) * r, 20 + math.sin(a0) * r, 20 + math.cos(a1) * r, 20 + math.sin(a1) * r, (230, 230, 245, 170))
    wb.save("fx_web")
    # огнеупорные перчатки
    gl = Img(24, 24)
    GR = ramp("3a0a04", "6a1a08", "a02a0a", "c8401a", "e86a2a", "f8a040", "fce070")
    for ox in (2, 12):
        for y in range(9, 17):
            for x in range(ox, ox + 9):
                gl.put(x, y, GR[4 if x < ox + 3 else (3 if x < ox + 6 else 2)])
        for i in range(4):
            fx = ox + i * 2 + (0 if i < 2 else 1)
            top = 4 + (i % 2) - (1 if i == 1 else 0)
            for y in range(top, 9):
                gl.put(fx, y, GR[4 if i < 2 else 3])
            gl.put(fx, top, GR[5])
        tx = ox - 1 if ox == 2 else ox + 9
        for k in range(4):
            gl.put(tx, 12 - k, GR[3])
        for y in range(17, 22):
            for x in range(ox - 1, ox + 10):
                gl.put(x, y, GR[1] if y == 21 else GR[2])
        for x in range(ox, ox + 9, 2):
            gl.put(x, 18, GR[6]); gl.put(x + 1, 19, GR[5])
    gl.outline(); gl.save("gear_gloves_fire")


def held_lights():
    t = Img(8, 22)
    for y in range(6, 22):
        for x in (3, 4):
            t.put(x, y, WOOD[5] if x == 3 else WOOD[3])
    # обмотка
    for y in (6, 7, 8, 9):
        for x in (2, 3, 4, 5):
            t.put(x, y, hx("8a6a4a") if (x + y) % 2 else hx("6a4a30"))
    t.outline()
    t.save("torch_held")
    L = Img(12, 18)
    for y in range(5, 16):
        for x in range(2, 10):
            edge = x in (2, 9) or y in (5, 15)
            L.put(x, y, IRON[3] if edge else hx("f8d070") if 4 <= x <= 7 and 7 <= y <= 13 else hx("e8a840"))
    for x in range(3, 9):
        L.put(x, 4, IRON[4])
    L.line(4, 1, 7, 1, IRON[3]); L.put(4, 2, IRON[3]); L.put(7, 2, IRON[3]); L.put(4, 3, IRON[3]); L.put(7, 3, IRON[3])
    L.put(5, 9, hx("fffce0")); L.put(6, 10, hx("fffce0"))
    L.outline()
    L.save("lantern_held")
    z = Img(12, 12)
    ell(z, 5, 6, 4.5, 4.5, [hx("6a58b0"), hx("8a78d0"), hx("b0a0f0")])
    for y in range(12):
        for x in range(12):
            if math.hypot(x + 0.5 - 7.5, y + 0.5 - 4.5) < 3.6:
                z.p[x, y] = (0, 0, 0, 0)
    for (x, y) in [(8, 7), (9, 7), (10, 7), (9, 8), (8, 9), (9, 9), (10, 9)]:
        z.put(x, y, hx("f0f0ff"))
    z.outline()
    z.save("need_sleep")


def main():
    held_lights()
    hearth(); potion_book(); hand(False); hand(True); basket(); critters()
    r = room().save("alch_room")
    parts = [mortar(), pestle(), board(), knife(), brazier(), bowl(), ladle()]
    pi = prop_icons()
    bi = base_icons()
    sc = 4
    big = Image.new("RGBA", (2000, 900), (50, 42, 38, 255))
    x = 8
    for p in parts:
        big.alpha_composite(p.resize((p.width * sc, p.height * sc), Image.NEAREST), (x, 8))
        x += p.width * sc + 10
    x = 8
    for p in pi:
        big.alpha_composite(p.resize((p.width * 6, p.height * 6), Image.NEAREST), (x, 380))
        x += 80
    x = 8
    for p in bi:
        big.alpha_composite(p.resize((p.width * sc, p.height * sc), Image.NEAREST), (x, 480))
        x += 140
    big.save(os.path.join(GAME, "..", "screenshots", "v16_alch_parts.png"))
    r.resize((1920, 1080), Image.NEAREST).save(os.path.join(GAME, "..", "screenshots", "v16_alch_room.png"))
    print("ok")


if __name__ == "__main__":
    main()

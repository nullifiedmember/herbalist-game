# -*- coding: utf-8 -*-
"""Набор для рисования построек городов «в стиле яблока».

Pic — холст, где у каждого пикселя есть материал (основной цвет) и тон:
  0 блик, 1 светлый, 2 основной, 3 тень, 4 глубокая тень,
  5/6/7 — цветной контур (светлый / средний / тёмный) того же материала.
Свет сверху-слева. Чёрного нет: самые тёмные места — контур материала.
render() добавляет внешний цветной контур вокруг всей картинки.
"""
import math, os, random, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from apple_engine import ramp, hx, ell, poly, rect, tube, stroke, up  # noqa: F401
from PIL import Image

_l = math.hypot(-0.62, -0.78)
LX, LY = -0.62 / _l, -0.78 / _l


def col(base, t):
    tones, ol = ramp(hx(base))
    return tones[t] if t < 5 else ol[t - 5]


class Pic:
    def __init__(self, w, h, seed="pic"):
        self.w, self.h = w, h
        self.px = {}
        self.rng = random.Random(seed)

    # ---- основа ----
    def put(self, x, y, base, t):
        if 0 <= x < self.w and 0 <= y < self.h:
            self.px[(x, y)] = (hx(base), max(0, min(7, int(t))))

    def has(self, x, y):
        return (x, y) in self.px

    def tone(self, x, y):
        v = self.px.get((x, y))
        return v[1] if v else None

    def dark(self, x, y, d=1, cap=4):
        """Затемнить пиксель на d тонов (в пределах 0..cap), материал тот же."""
        v = self.px.get((x, y))
        if v and v[1] < 5:
            self.px[(x, y)] = (v[0], min(cap, v[1] + d))

    def fill(self, mask, base, t=2):
        for (x, y) in mask:
            tt = t(x, y) if callable(t) else t
            if tt is not None:
                self.put(x, y, base, tt)

    def blob(self, mask, base, shine=False, line=True, bias=0):
        """Фигура как яблочко: свой цветной контур внутри, кромка света сверху-слева, тень снизу-справа."""
        mask = set(mask)
        if not mask:
            return mask
        xs = [p[0] for p in mask]; ys = [p[1] for p in mask]
        edge = {}
        for (x, y) in mask:
            dx = dy = 0
            for ax, ay in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                if (x + ax, y + ay) not in mask:
                    dx += ax; dy += ay
            if dx or dy or any((x + ax, y + ay) not in mask for ax, ay in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                edge[(x, y)] = (dx, dy)
        small = (max(xs) - min(xs)) < 3 or (max(ys) - min(ys)) < 3
        for (x, y) in mask:
            if line and (x, y) in edge and not small:
                dx, dy = edge[(x, y)]
                d = math.hypot(dx, dy) or 1
                s = (dx * LX + dy * LY) / d
                t = 5 if s > 0.3 else (6 if s > -0.3 else 7)
                self.put(x, y, base, t)
                continue
            t = 2
            if (x + 1, y) in edge or (x, y + 1) in edge or (x + 1, y) not in mask or (x, y + 1) not in mask:
                t = 3
            if (x - 1, y) in edge or (x, y - 1) in edge or (x - 1, y) not in mask or (x, y - 1) not in mask:
                t = 1 if t == 2 else t
            self.put(x, y, base, max(0, min(4, t + bias)))
        if shine:
            cx = min(xs) + (max(xs) - min(xs)) * 0.3
            cy = min(ys) + (max(ys) - min(ys)) * 0.3
            bx, by = int(round(cx)), int(round(cy))
            for p in ((bx, by), (bx + 1, by), (bx, by + 1)):
                if p in mask and p not in edge:
                    self.put(p[0], p[1], base, 0)
        return mask

    def line(self, pts, base, t=6):
        for (x, y) in stroke(pts):
            self.put(x, y, base, t)

    def hline(self, x0, x1, y, base, t):
        for x in range(x0, x1 + 1):
            self.put(x, y, base, t)

    def vline(self, x, y0, y1, base, t):
        for y in range(y0, y1 + 1):
            self.put(x, y, base, t)

    # ---- готовые формы ----
    def log_v(self, x0, x1, ytop, ybot, base, point=0, grain=True):
        """Вертикальное бревно: свет слева, тень справа, остриё сверху (point — высота острия)."""
        w = x1 - x0 + 1
        cx = (x0 + x1) / 2
        for y in range(ytop, ybot + 1):
            if point and y < ytop + point:
                half = (w / 2) * (y - ytop + 1) / point
            else:
                half = w / 2
            for x in range(x0, x1 + 1):
                if abs(x + 0.5 - (cx + 0.5)) > half + 0.01:
                    continue
                u = (x - x0) / max(1, w - 1)
                t = 1 if u < 0.25 else 2 if u < 0.62 else 3 if u < 0.86 else 4
                if x == x1:
                    t = 6
                if point and y < ytop + point and u > 0.5:
                    t = max(t, 3)
                self.put(x, y, base, t)
        if grain:
            for _ in range(max(1, (ybot - ytop) // 9)):
                gx = self.rng.randint(x0 + 1, max(x0 + 1, x1 - 2))
                gy = self.rng.randint(ytop + point + 2, max(ytop + point + 3, ybot - 4))
                for k in range(self.rng.randint(2, 4)):
                    self.dark(gx, gy + k, 1, 4)

    def log_h(self, x0, x1, ytop, ybot, base, ends=None, grain=True):
        """Горизонтальное бревно: светлый верх, тёмный низ."""
        h = ybot - ytop + 1
        for y in range(ytop, ybot + 1):
            u = (y - ytop) / max(1, h - 1)
            t = 1 if u < 0.2 else 2 if u < 0.6 else 3 if u < 0.85 else 4
            if y == ybot:
                t = 6
            for x in range(x0, x1 + 1):
                self.put(x, y, base, t)
        if grain:
            for _ in range(max(1, (x1 - x0) // 10)):
                gx = self.rng.randint(x0 + 2, max(x0 + 2, x1 - 6))
                gy = self.rng.randint(ytop + 1, max(ytop + 1, ybot - 2))
                for k in range(self.rng.randint(2, 5)):
                    self.dark(gx + k, gy, 1, 3)
        if ends:
            for ex in ends:
                self.log_end(ex, (ytop + ybot) // 2, (h + 1) // 2, "#c99a68")

    def log_end(self, cx, cy, r, base):
        m = ell(cx + 0.5, cy + 0.5, r, r)
        self.blob(m, base)
        if r >= 3:
            for (x, y) in ell(cx + 0.5, cy + 0.5, max(1, r - 2), max(1, r - 2)):
                if (x - cx) ** 2 + (y - cy) ** 2 >= (r - 2.5) ** 2:
                    self.dark(x, y, 1, 3)

    def window(self, x0, y0, w, h, wood, glow="#ffcf6e"):
        """Окно: рама, тёплое стекло, крест по центру (перекладина на половине высоты)."""
        self.blob(rect(x0, y0, x0 + w - 1, y0 + h - 1), wood)
        gx0, gy0, gx1, gy1 = x0 + 2, y0 + 2, x0 + w - 3, y0 + h - 3
        for y in range(gy0, gy1 + 1):
            for x in range(gx0, gx1 + 1):
                t = 1 if (y - gy0) < (gy1 - gy0 + 1) * 0.45 else 2
                if x == gx1 or y == gy1:
                    t = 3
                self.put(x, y, glow, t)
        mx = (gx0 + gx1) // 2
        my = (gy0 + gy1) // 2
        self.vline(mx, gy0, gy1, wood, 3)
        self.hline(gx0, gx1, my, wood, 3)
        self.put(gx0, gy0, glow, 0)
        self.put(gx0 + 1, gy0, glow, 0)
        # подоконник
        self.blob(rect(x0 - 1, y0 + h - 1, x0 + w, y0 + h + 1), wood)

    def door(self, cx, ybot, w, h, wood, iron="#8c8aa0"):
        """Дощатая дверь по центру низа, рама, петли, ручка."""
        x0 = cx - w // 2
        x1 = x0 + w - 1
        y0 = ybot - h + 1
        self.blob(rect(x0 - 2, y0 - 2, x1 + 2, ybot), wood, bias=1)
        for y in range(y0, ybot + 1):
            for x in range(x0, x1 + 1):
                k = (x - x0) % 5
                t = 2 if k in (1, 2) else 1 if k == 0 else 3
                if k == 4:
                    t = 6
                if y == y0:
                    t = 3
                self.put(x, y, wood, t)
        for hy in (y0 + 4, ybot - 6):
            self.blob(rect(x0, hy, x0 + w // 2 - 2, hy + 1), iron, line=False)
        self.blob(rect(x1 - 4, (y0 + ybot) // 2, x1 - 3, (y0 + ybot) // 2 + 1), iron, line=False)
        self.put(x1 - 4, (y0 + ybot) // 2, iron, 0)

    def thatch(self, mask, base, y0, step=7, strands=True):
        """Солома рядами: у каждого ряда светлый верх, тёмная щель снизу, зубчики."""
        for (x, y) in mask:
            v = self.px.get((x, y))
            if not v or v[1] > 4:
                continue
            t = v[1]
            k = (y - y0 + ((x // 4) % 2)) % step
            if k == 0:
                t = min(4, t + 2)
            elif k == 1:
                t = max(0, t - 1)
            elif k == step - 1:
                t = min(4, t + 1)
            self.px[(x, y)] = (hx(base), t)
        if strands:
            xs = [p[0] for p in mask]; ys = [p[1] for p in mask]
            for _ in range(len(mask) // 40):
                x = self.rng.randint(min(xs), max(xs)); y = self.rng.randint(min(ys), max(ys))
                if (x, y) in mask and (x, y + 1) in mask and (y - y0) % step > 2:
                    self.dark(x, y, 1, 4); self.dark(x, y + 1, 1, 4)

    def stones(self, x0, x1, y0, y1, base):
        """Цоколь из плоских камушков."""
        x = x0
        row = 0
        while x <= x1:
            w = self.rng.randint(6, 10)
            self.blob(ell(x + w / 2, (y0 + y1) / 2 + 0.5, w / 2, (y1 - y0 + 1) / 2, p=2.6) & rect(x0, y0, x1, y1), base)
            x += w - 1
            row += 1

    # ---- вывод ----
    def render(self, outline=True):
        img = Image.new("RGBA", (self.w, self.h), (0, 0, 0, 0))
        for (x, y), (b, t) in self.px.items():
            img.putpixel((x, y), col(b, t) + (255,))
        if outline:
            out = {}
            for y in range(self.h):
                for x in range(self.w):
                    if (x, y) in self.px:
                        continue
                    sx = sy = 0.0
                    best = None
                    for ax in (-1, 0, 1):
                        for ay in (-1, 0, 1):
                            if (ax or ay) and (x + ax, y + ay) in self.px:
                                if abs(ax) + abs(ay) == 1 and best is None:
                                    best = self.px[(x + ax, y + ay)][0]
                                sx -= ax; sy -= ay
                    if best is None:
                        continue
                    d = math.hypot(sx, sy) or 1
                    s = (sx * LX + sy * LY) / d
                    k = 5 if s > 0.35 else (6 if s > -0.3 else 7)
                    out[(x, y)] = col(best, k)
            for (x, y), c in out.items():
                img.putpixel((x, y), c + (255,))
        return img


def ends_base():
    return "#c99a68"


def sheet(imgs, bg=None, pad=12, k=3):
    W = sum(i.width for i in imgs) + pad * (len(imgs) + 1)
    H = max(i.height for i in imgs) + pad * 2
    c = Image.new("RGBA", (W, H), bg if bg else (0, 0, 0, 0))
    x = pad
    for i in imgs:
        c.alpha_composite(i, (x, H - pad - i.height))
        x += i.width + pad
    return up(c, k)

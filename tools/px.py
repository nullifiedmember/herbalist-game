"""Маленькая библиотека пиксель-арта для v20 (птицы, значки материалов, ловушки, постройки).
Рисуем маски фигур, красим их «рампой» из 5 тонов со светом слева-сверху, потом общая тёмная обводка —
так значки получаются в одном стиле с остальной игрой (тёмный контур, 3-5 тонов, блик).
"""
import colorsys
import numpy as np
from PIL import Image

OUTLINE = (30, 24, 38, 255)


def hx(s):
    s = s.lstrip("#")
    return tuple(int(s[i:i + 2], 16) for i in (0, 2, 4))


def ramp(base, n=5, spread=0.62):
    """Рампа от тени к свету: тени холоднее (к фиолетовому), света теплее (к жёлтому)."""
    if isinstance(base, str):
        base = hx(base)
    r, g, b = [c / 255.0 for c in base]
    h, l, s = colorsys.rgb_to_hls(r, g, b)
    out = []
    for i in range(n):
        k = (i - (n - 1) * 0.55) / (n - 1)          # -0.55 .. 0.45
        hh = h + (-0.035 if k < 0 else 0.03) * abs(k) * 2.0
        if s < 0.08:
            hh = h
        warm = 0.66 if s > 0.08 else 0.0
        if k > 0 and s > 0.08:
            # к свету — к жёлтому (h≈0.14)
            hh = h + (0.14 - h) * 0.18 * k * 2.0 if abs(h - 0.14) < 0.5 else h
        ll = min(0.96, max(0.05, l + k * spread * (0.75 if l > 0.6 else 1.0)))
        ss = min(1.0, max(0.0, s * (1.0 + (0.12 if k < 0 else -0.25 * k))))
        rr, gg, bb = colorsys.hls_to_rgb(hh % 1.0, ll, ss)
        out.append((int(rr * 255), int(gg * 255), int(bb * 255), 255))
    return out


def mix(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3)) + (255,)


class Canvas:
    def __init__(self, w, h):
        self.w, self.h = w, h
        self.px = np.zeros((h, w, 4), dtype=np.uint8)

    # ---------------------------------------------------------- маски
    def mask(self):
        return np.zeros((self.h, self.w), dtype=bool)

    def ellipse(self, cx, cy, rx, ry, m=None):
        m = self.mask() if m is None else m
        yy, xx = np.mgrid[0:self.h, 0:self.w]
        m |= ((xx + 0.5 - cx) / max(rx, 0.1)) ** 2 + ((yy + 0.5 - cy) / max(ry, 0.1)) ** 2 <= 1.0
        return m

    def rect(self, x0, y0, x1, y1, m=None):
        m = self.mask() if m is None else m
        m[max(0, y0):max(0, y1), max(0, x0):max(0, x1)] = True
        return m

    def poly(self, pts, m=None):
        m = self.mask() if m is None else m
        from PIL import ImageDraw
        im = Image.new("L", (self.w, self.h), 0)
        ImageDraw.Draw(im).polygon([(float(x), float(y)) for x, y in pts], fill=255)
        m |= np.array(im) > 127
        return m

    def line_mask(self, pts, width=1, m=None):
        m = self.mask() if m is None else m
        from PIL import ImageDraw
        im = Image.new("L", (self.w, self.h), 0)
        ImageDraw.Draw(im).line([(float(x), float(y)) for x, y in pts], fill=255, width=width)
        m |= np.array(im) > 127
        return m

    # ---------------------------------------------------------- краска
    def fill(self, m, col):
        self.px[m] = col if len(col) == 4 else tuple(col) + (255,)

    def shade(self, m, rmp, light=(-1, -1), flat=0.0, gy=0.35):
        """Покрасить маску рампой: блик у края к свету, тень у края от света, лёгкий градиент сверху вниз."""
        h, w = m.shape
        ys, xs = np.nonzero(m)
        if len(ys) == 0:
            return
        y0, y1 = ys.min(), ys.max() + 1
        lx, ly = light
        for y, x in zip(ys, xs):
            t = 2.0  # индекс в рампе 0..4, 2 — основной
            t -= gy * 2.0 * ((y - y0) / max(1, (y1 - y0)) - 0.4)
            # край к свету
            ax, ay = x + lx, y + ly
            if not (0 <= ax < w and 0 <= ay < h) or not m[ay, ax]:
                t += 1.1
            bx, by = x - lx, y - ly
            if not (0 <= bx < w and 0 <= by < h) or not m[by, bx]:
                t -= 1.0
            t = t * (1.0 - flat) + 2.0 * flat
            i = int(round(min(len(rmp) - 1, max(0, t))))
            self.px[y, x] = rmp[i]

    def dot(self, x, y, col):
        if 0 <= x < self.w and 0 <= y < self.h:
            self.px[int(y), int(x)] = col if len(col) == 4 else tuple(col) + (255,)

    def line(self, pts, col, width=1):
        self.fill(self.line_mask(pts, width), col)

    def outline(self, col=OUTLINE, diag=False):
        a = self.px[:, :, 3] > 0
        o = np.zeros_like(a)
        o[1:, :] |= a[:-1, :]
        o[:-1, :] |= a[1:, :]
        o[:, 1:] |= a[:, :-1]
        o[:, :-1] |= a[:, 1:]
        if diag:
            o[1:, 1:] |= a[:-1, :-1]
            o[:-1, :-1] |= a[1:, 1:]
            o[1:, :-1] |= a[:-1, 1:]
            o[:-1, 1:] |= a[1:, :-1]
        o &= ~a
        self.px[o] = col

    def inner_line(self, m, col):
        """Тёмная линия по внешнему краю маски (внутри неё) — отделить детали друг от друга."""
        e = m.copy()
        e[1:-1, 1:-1] = m[1:-1, 1:-1] & ~(m[:-2, 1:-1] & m[2:, 1:-1] & m[1:-1, :-2] & m[1:-1, 2:])
        self.px[e] = col

    def alpha(self):
        return self.px[:, :, 3] > 0

    def image(self):
        return Image.fromarray(self.px, "RGBA")

    def save(self, path):
        self.image().save(path)

    def paste(self, other, ox, oy):
        """Наложить другой холст (непрозрачные пиксели) со сдвигом."""
        for y in range(other.h):
            ty = y + oy
            if ty < 0 or ty >= self.h:
                continue
            for x in range(other.w):
                tx = x + ox
                if 0 <= tx < self.w and other.px[y, x, 3] > 0:
                    self.px[ty, tx] = other.px[y, x]

    def flip(self):
        c = Canvas(self.w, self.h)
        c.px = self.px[:, ::-1].copy()
        return c


def sheet(frames, path):
    w = sum(f.w for f in frames)
    h = max(f.h for f in frames)
    im = Image.new("RGBA", (w, h))
    x = 0
    for f in frames:
        im.paste(f.image(), (x, 0))
        x += f.w
    im.save(path)


def rng(seed):
    return np.random.default_rng(seed)

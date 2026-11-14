# -*- coding: utf-8 -*-
"""Общий движок рисования «в стиле яблока» для всех тем травника.

Идея: картинка собирается из фигур (сзади вперёд). У каждой фигуры — маска пикселей
и ОДИН основной цвет; из него автоматически строится рампа:
  0 блик, 1 светлый, 2 основной, 3 тень, 4 глубокая тень
  + три цвета контура (светлый сверху-слева, средний, тёмный снизу-справа).
Свет всегда сверху-слева. Чёрного нет — контур цветной, как у яблока.
"""
import colorsys, math
from PIL import Image

LIGHT = (-0.62, -0.78)


# ---------------- цвета ----------------
def hx(c):
    if isinstance(c, tuple):
        return c
    c = c.lstrip("#")
    return tuple(int(c[i:i + 2], 16) for i in (0, 2, 4))


def _shift(h, target, amt):
    d = (target - h + 0.5) % 1.0 - 0.5
    step = max(-amt, min(amt, d))
    return (h + step) % 1.0


def _hsv(c):
    return colorsys.rgb_to_hsv(*[v / 255 for v in c])


def _rgb(h, s, v):
    r, g, b = colorsys.hsv_to_rgb(h, max(0, min(1, s)), max(0, min(1, v)))
    return (round(r * 255), round(g * 255), round(b * 255))


_RAMP_CACHE = {}


def ramp(base):
    """Рампа из основного цвета: (tones[5], outline[3])."""
    base = hx(base)
    if base in _RAMP_CACHE:
        return _RAMP_CACHE[base]
    h, s, v = _hsv(base)
    YEL, PUR = 0.14, 0.86
    tones = [
        _rgb(_shift(h, YEL, 0.05), s * 0.40, min(1, v + 0.30)),
        _rgb(_shift(h, YEL, 0.025), s * 0.82, min(1, v + 0.13)),
        base,
        _rgb(_shift(h, PUR, 0.03), min(1, s * 1.06 + 0.04), v - 0.13),
        _rgb(_shift(h, PUR, 0.055), min(1, s * 1.10 + 0.07), v - 0.25),
    ]
    vv = max(v, 0.35)
    outline = [
        _rgb(_shift(h, PUR, 0.05), min(1, s * 1.0 + 0.10), vv * 0.66),
        _rgb(_shift(h, PUR, 0.07), min(1, s * 1.0 + 0.14), vv * 0.51),
        _rgb(_shift(h, PUR, 0.09), min(1, s * 1.0 + 0.18), vv * 0.40),
    ]
    _RAMP_CACHE[base] = (tones, outline)
    return tones, outline


# ---------------- маски (наборы пикселей) ----------------
def ell(cx, cy, rx, ry, ang=0.0, p=2.0):
    a = math.radians(ang)
    ca, sa = math.cos(a), math.sin(a)
    R = max(rx, ry) + 1
    out = set()
    for y in range(int(cy - R) - 1, int(cy + R) + 2):
        for x in range(int(cx - R) - 1, int(cx + R) + 2):
            dx, dy = x + 0.5 - cx, y + 0.5 - cy
            u = abs((dx * ca + dy * sa) / rx)
            v = abs((-dx * sa + dy * ca) / ry)
            if u ** p + v ** p <= 1.0:
                out.add((x, y))
    return out


def bez(pts, n=48):
    """Точки на кривой Безье (2-4 опорные точки)."""
    res = []
    for i in range(n + 1):
        t = i / n
        q = list(pts)
        while len(q) > 1:
            q = [(q[k][0] + (q[k + 1][0] - q[k][0]) * t, q[k][1] + (q[k + 1][1] - q[k][1]) * t) for k in range(len(q) - 1)]
        res.append(q[0])
    return res


def tube(pts, w0, w1=None, profile="lin", n=60):
    """Полоса вдоль кривой. profile: lin (от w0 к w1), leaf (острый с двух концов, w0 = макс. полуширина),
    drop (широкий у основания, острый на конце)."""
    if w1 is None:
        w1 = w0
    cs = bez(pts, n)
    xs = [p[0] for p in cs]; ys = [p[1] for p in cs]
    W = max(w0, w1) + 2
    out = set()
    for y in range(int(min(ys) - W), int(max(ys) + W) + 1):
        for x in range(int(min(xs) - W), int(max(xs) + W) + 1):
            px, py = x + 0.5, y + 0.5
            best, bt = 1e9, 0
            for i, (qx, qy) in enumerate(cs):
                d = (qx - px) ** 2 + (qy - py) ** 2
                if d < best:
                    best, bt = d, i / n
            if profile == "leaf":
                w = w0 * (math.sin(math.pi * bt) ** 0.7)
            elif profile == "drop":
                w = w0 * (1 - bt) ** 0.6 * min(1, bt * 5 + 0.4)
            else:
                w = w0 + (w1 - w0) * bt
            if math.sqrt(best) <= w:
                out.add((x, y))
    return out


def stroke(pts, n=80):
    """Тонкая линия в 1 пиксель вдоль кривой (pixel-perfect, без «ступенек» в 2 пикселя)."""
    cs = bez(pts, n) if len(pts) > 1 else pts
    path = []
    for (x, y) in cs:
        p = (int(math.floor(x)), int(math.floor(y)))
        if not path or path[-1] != p:
            path.append(p)
    # убрать L-уголки
    clean = []
    for i, p in enumerate(path):
        if 0 < i < len(path) - 1 and clean:
            a, b = clean[-1], path[i + 1]
            if abs(a[0] - b[0]) == 1 and abs(a[1] - b[1]) == 1:
                continue
        clean.append(p)
    return set(clean)


def poly(points):
    xs = [p[0] for p in points]; ys = [p[1] for p in points]
    out = set()
    for y in range(int(min(ys)) - 1, int(max(ys)) + 2):
        for x in range(int(min(xs)) - 1, int(max(xs)) + 2):
            px, py = x + 0.5, y + 0.5
            inside = False
            j = len(points) - 1
            for i in range(len(points)):
                xi, yi = points[i]; xj, yj = points[j]
                if (yi > py) != (yj > py) and px < (xj - xi) * (py - yi) / (yj - yi + 1e-9) + xi:
                    inside = not inside
                j = i
            if inside:
                out.add((x, y))
    return out


def rect(x0, y0, x1, y1):
    return {(x, y) for y in range(y0, y1 + 1) for x in range(x0, x1 + 1)}


# ---------------- холст ----------------
class Canvas:
    def __init__(self, w=32, h=48):
        self.w, self.h = w, h
        self.shapes = []   # dict(mask, color, mode, shine, outline, inner)
        self.fx = []       # (x, y, rgb) поверх всего, без контура
        self.marks = []    # (x, y, rgb) поверх заливки фигуры, до контура (глаза, прожилки)

    def add(self, mask, color, mode="cel", shine=False, outline=True, inner=True, tone_bias=0):
        mask = {(x, y) for (x, y) in mask if 0 <= x < self.w and 0 <= y < self.h}
        if mask:
            self.shapes.append(dict(mask=mask, color=hx(color), mode=mode, shine=shine,
                                    outline=outline, inner=inner, bias=tone_bias))
        return mask

    def mark(self, x, y, color):
        self.marks.append((x, y, hx(color)))

    def spark(self, x, y, color, size=1):
        """Искорка-звёздочка (без контура)."""
        c = hx(color)
        self.fx.append((x, y, ramp(c)[0][0]))
        if size >= 1:
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                self.fx.append((x + dx, y + dy, c))
        if size >= 2:
            for dx, dy in ((2, 0), (-2, 0), (0, 2), (0, -2)):
                self.fx.append((x + dx, y + dy, ramp(c)[0][1]))

    # ---- отрисовка ----
    def render(self):
        W, H = self.w, self.h
        owner = [[-1] * W for _ in range(H)]
        for i, s in enumerate(self.shapes):
            for (x, y) in s["mask"]:
                owner[y][x] = i
        img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        filled = [(x, y) for y in range(H) for x in range(W) if owner[y][x] >= 0]
        if not filled:
            return img
        gcx = sum(p[0] for p in filled) / len(filled)
        gcy = sum(p[1] for p in filled) / len(filled)
        # кэш геометрии для dome
        geo = []
        for s in self.shapes:
            xs = [p[0] for p in s["mask"]]; ys = [p[1] for p in s["mask"]]
            geo.append(((min(xs) + max(xs) + 1) / 2, (min(ys) + max(ys) + 1) / 2,
                        max(1.0, (max(xs) - min(xs) + 1) / 2), max(1.0, (max(ys) - min(ys) + 1) / 2),
                        max(xs) - min(xs) + 1, max(ys) - min(ys) + 1))
        lx, ly = LIGHT
        ln = math.hypot(lx, ly); lx, ly = lx / ln, ly / ln
        for (x, y) in filled:
            i = owner[y][x]
            s = self.shapes[i]
            M = s["mask"]
            tones, _ = ramp(s["color"])
            cx, cy, rx, ry, bw, bh = geo[i]
            if s["mode"] == "flat":
                t = 2
            elif s["mode"] == "dome":
                u = (x + 0.5 - cx) / rx; v = (y + 0.5 - cy) / ry
                d = u * u + v * v
                nz = math.sqrt(max(0.0, 1 - min(1.0, d)))
                L3 = (lx * 0.75, ly * 0.75, 0.66)
                it = u * L3[0] + v * L3[1] + nz * L3[2]
                t = 1 if it > 0.62 else 2 if it > 0.30 else 3 if it > 0.02 else 4
                if s["shine"] and it > 0.80 and bw >= 3:
                    t = 0
            else:  # cel
                t = 2
                small = min(bw, bh) <= 2
                if (x + 1, y + 1) not in M or (x, y + 1) not in M:
                    t = 3
                if not small and (x + 1, y + 1) not in M and (x, y + 1) not in M and (x + 1, y) not in M:
                    t = 4
                if ((x - 1, y - 1) not in M or (x, y - 1) not in M) and t == 2:
                    t = 1
                if small and (x - 1, y) not in M and (x, y - 1) in M:
                    t = min(t, 2)
            # линия, где фигура лежит поверх другой
            if s["inner"]:
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < W and 0 <= ny < H:
                        j = owner[ny][nx]
                        if 0 <= j < i and self.shapes[j]["color"] != s["color"]:
                            t = max(t, 4 if (dx, dy) in ((1, 0), (0, 1)) else 3)
            t = max(0, min(4, t + s["bias"]))
            img.putpixel((x, y), tones[t] + (255,))
        # блик на фигурах cel с shine
        for i, s in enumerate(self.shapes):
            if s["shine"] and s["mode"] == "cel":
                cx, cy, rx, ry, bw, bh = geo[i]
                if bw >= 3 and bh >= 3:
                    bx, by = int(cx - rx * 0.45), int(cy - ry * 0.45)
                    if (bx, by) in s["mask"] and owner[by][bx] == i:
                        img.putpixel((bx, by), ramp(s["color"])[0][0] + (255,))
        for (x, y, c) in self.marks:
            if 0 <= x < W and 0 <= y < H:
                img.putpixel((x, y), c + (255,))
        # цветной контур
        for y in range(H):
            for x in range(W):
                if owner[y][x] >= 0:
                    continue
                nb = [owner[y + dy][x + dx] for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))
                      if 0 <= x + dx < W and 0 <= y + dy < H and owner[y + dy][x + dx] >= 0]
                nb = [j for j in nb if self.shapes[j]["outline"]]
                if not nb:
                    continue
                j = max(nb)
                _, ol = ramp(self.shapes[j]["color"])
                dx, dy = x - gcx, y - gcy
                d = math.hypot(dx, dy) or 1
                sdir = (dx * lx + dy * ly) / d
                k = 0 if sdir > 0.35 else (1 if sdir > -0.3 else 2)
                img.putpixel((x, y), ol[k] + (255,))
        for (x, y, c) in self.fx:
            if 0 <= x < W and 0 <= y < H:
                img.putpixel((x, y), c + (255,))
        return img


def up(img, k):
    return img.resize((img.width * k, img.height * k), Image.NEAREST)


# ---------------- перекраска старого спрайта в стиль яблока ----------------
def _lum(c):
    return 0.299 * c[0] + 0.587 * c[1] + 0.114 * c[2]


def soften(c):
    """Цвет заливки -> мягкий тёплый вариант (как у яблока)."""
    h, s, v = _hsv(c)
    if v > 0.55:   # светлые — чуть к жёлтому, мягче
        h = _shift(h, 0.14, 0.02); s *= 0.92; v = min(1, v * 1.04 + 0.02)
    else:          # тёмные — к сиреневому, светлее (без чёрного)
        h = _shift(h, 0.86, 0.03); s = min(1, s * 0.95); v = v * 0.88 + 0.09
    return _rgb(h, s, v)


def restyle(img, dark_lum=70):
    """Старый спрайт -> стиль яблока: форма и детали те же,
    тёмный контур становится цветным (по цвету заливки рядом и по свету), палитра мягче."""
    img = img.convert("RGBA")
    W, H = img.size
    px = img.load()
    A = lambda x, y: 0 <= x < W and 0 <= y < H and px[x, y][3] > 0
    opaque = [(x, y) for y in range(H) for x in range(W) if px[x, y][3] > 0]
    if not opaque:
        return img
    # центр каждой отдельной фигурки (в листах анимации их много) — для стороны света у контура
    comp = {}
    seen = set()
    for p0 in opaque:
        if p0 in seen:
            continue
        stack = [p0]; seen.add(p0); grp = []
        while stack:
            q = stack.pop(); grp.append(q)
            for ddx in (-1, 0, 1):
                for ddy in (-1, 0, 1):
                    r = (q[0] + ddx, q[1] + ddy)
                    if r not in seen and A(*r):
                        seen.add(r); stack.append(r)
        ccx = sum(g[0] for g in grp) / len(grp); ccy = sum(g[1] for g in grp) / len(grp)
        for g in grp:
            comp[g] = (ccx, ccy)
    lx, ly = LIGHT
    ln = math.hypot(lx, ly); lx, ly = lx / ln, ly / ln
    def is_line(x, y):
        l = _lum(px[x, y])
        if l >= dark_lum:
            return False
        # внутри тёмной заливки (чёрная птица, тёмный цветок) — это не линия, а цвет
        nb8 = [(x + dx, y + dy) for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1), (1, 1), (-1, -1), (1, -1), (-1, 1))]
        dark_nb = sum(1 for q in nb8 if A(*q) and _lum(px[q]) < dark_lum)
        if dark_nb >= 7:
            return False
        if l < 42:
            return True
        # тёмный пиксель — линия, только если он заметно темнее соседей (у тёмных растений заливка сама тёмная)
        nb = [_lum(px[x + dx, y + dy]) for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1), (1, 1), (-1, -1), (1, -1), (-1, 1))
              if A(x + dx, y + dy)]
        edge = len(nb) < 8
        brighter = [v for v in nb if v > l + 25]
        return edge and len(brighter) >= 1 or len(brighter) >= 3
    dark = {(x, y) for (x, y) in opaque if is_line(x, y)}
    out = img.copy(); po = out.load()

    def fill_near(x, y, rmax=3):
        best = None
        for r in range(1, rmax + 1):
            for dy in range(-r, r + 1):
                for dx in range(-r, r + 1):
                    q = (x + dx, y + dy)
                    if A(*q) and q not in dark:
                        c = px[q][:3]
                        if best is None or abs(dx) + abs(dy) < best[0]:
                            best = (abs(dx) + abs(dy), c)
            if best:
                return best[1]
        return None

    for (x, y) in opaque:
        c = px[x, y][:3]; a = px[x, y][3]
        edge = any(not A(x + dx, y + dy) for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))
        if (x, y) in dark:
            f = fill_near(x, y)
            if f is None:
                po[x, y] = soften(c) + (a,); continue
            tones, ol = ramp(soften(f))
            if edge:
                gcx, gcy = comp[(x, y)]
                dx, dy = x - gcx, y - gcy
                d = math.hypot(dx, dy) or 1
                sd = (dx * lx + dy * ly) / d
                k = 0 if sd > 0.35 else (1 if sd > -0.3 else 2)
                po[x, y] = ol[k] + (a,)
            else:
                po[x, y] = tones[4] + (a,)   # внутренняя линия — глубокая тень цвета, а не чёрный
        else:
            po[x, y] = soften(c) + (a,)
    return out

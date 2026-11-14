"""v25: новые звери «Лесного травника» — свой стиль, не как у старых 18 зверей.
Реалистичный пиксель-арт по референсу (плотные формы, объём от света сверху-слева, тёмный цветной контур,
внутренние линии между лапами и телом, тёплые блики и холодные тени).

Каждый зверь собирается из частей (эллипсоиды, лапы-капсулы, многоугольники), у каждой части — нормали,
свет считается по нормали и раскладывается по рампе из 6 цветов. Потом контур и линии между частями.

Лист: 12 кадров в ряд (как у старых зверей): 0-3 шаг, 4 стоит, 5 моргает, 6-9 занятие, 10-11 спит.
Смотрит ВЛЕВО (игра отражает при ходьбе вправо). Масштаб в игре 0.5.

Запуск из папки game:  python tools/fauna25.py [id ...]   -> art/animal_<id>.png, fauna25_db.gd, превью в screenshots/.
"""
import math, os, sys, colorsys, random
import numpy as np
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
ART = os.path.join(HERE, "..", "art")
SHOTS = os.path.join(HERE, "..", "..", "screenshots")
OUTLINE = np.array([30, 24, 40], float)
L = np.array([-0.45, -0.78, 0.55])
L = L / np.linalg.norm(L)


# ------------------------------------------------------------------ цвета

def hx(s):
    s = s.lstrip("#")
    return np.array([int(s[i:i + 2], 16) for i in (0, 2, 4)], float)


def ramp(base, n=6, spread=1.0):
    """Рампа от тени к свету: тени холоднее (к сиреневому), свет теплее (к жёлтому)."""
    r, g, b = hx(base) / 255.0
    h, l, s = colorsys.rgb_to_hls(r, g, b)
    out = []
    for i in range(n):
        k = (i - (n - 1) * 0.55) / (n - 1)          # -0.55..0.45
        ll = min(0.97, max(0.04, l + k * 0.62 * spread))
        hh = h
        tgt = 0.72 if k < 0 else 0.13            # тень — к сиреневому, свет — к жёлтому
        dh = ((tgt - h + 0.5) % 1.0) - 0.5
        hh = (h + dh * min(1.0, abs(k)) * (0.22 if k < 0 else 0.10)) % 1.0
        ss = max(0.0, min(1.0, s * (1.0 + (0.12 if k < 0 else -0.25 * k))))
        rr, gg, bb = colorsys.hls_to_rgb(hh, ll, ss)
        out.append(np.array([rr, gg, bb]) * 255.0)
    return out


# ------------------------------------------------------------------ холст с частями

class Canvas:
    def __init__(self, W, H):
        self.W, self.H = W, H
        self.part = -np.ones((H, W), int)
        self.n = np.zeros((H, W, 3))
        self.uv = np.zeros((H, W, 2))
        self.parts = []
        yy, xx = np.mgrid[0:H, 0:W]
        self.xx = xx + 0.5
        self.yy = yy + 0.5
        self.marks = []     # глаза, носы — после света

    def _add(self, m, nx, ny, nz, u, v, mat, shade, sep, pat):
        idx = len(self.parts)
        self.parts.append(dict(mat=mat, shade=shade, sep=sep, pat=pat))
        self.part[m] = idx
        self.n[m, 0] = nx[m]
        self.n[m, 1] = ny[m]
        self.n[m, 2] = nz[m]
        self.uv[m, 0] = u[m]
        self.uv[m, 1] = v[m]

    def ell(self, cx, cy, rx, ry, mat, rot=0.0, shade=0.0, sep=True, pat=None, flat=0.0, half=None):
        if rx < 0.5 or ry < 0.5:
            return
        c, s = math.cos(rot), math.sin(rot)
        dx = self.xx - cx
        dy = self.yy - cy
        lx = dx * c + dy * s
        ly = -dx * s + dy * c
        u = lx / rx
        v = ly / ry
        d = u * u + v * v
        m = d <= 1.0
        if half == "top":
            m &= ly <= 0.3
        elif half == "bottom":
            m &= ly >= -0.3
        nz = np.sqrt(np.clip(1.0 - d, 0.0, 1.0)) + flat
        nlx, nly = u, v
        nx = nlx * c - nly * s
        ny = nlx * s + nly * c
        ln = np.sqrt(nx * nx + ny * ny + nz * nz) + 1e-6
        self._add(m, nx / ln, ny / ln, nz / ln, u, v, mat, shade, sep, pat)

    def limb(self, p0, p1, r0, r1, mat, shade=0.0, sep=True, pat=None):
        x0, y0 = p0
        x1, y1 = p1
        vx, vy = x1 - x0, y1 - y0
        ll = vx * vx + vy * vy + 1e-6
        t = np.clip(((self.xx - x0) * vx + (self.yy - y0) * vy) / ll, 0.0, 1.0)
        px = x0 + vx * t
        py = y0 + vy * t
        dx = self.xx - px
        dy = self.yy - py
        r = r0 + (r1 - r0) * t
        d = np.sqrt(dx * dx + dy * dy)
        m = d <= r
        k = np.clip(d / np.maximum(r, 0.3), 0, 1)
        nx = dx / np.maximum(r, 0.3)
        ny = dy / np.maximum(r, 0.3)
        nz = np.sqrt(np.clip(1 - k * k, 0, 1)) + 0.15
        ln = np.sqrt(nx * nx + ny * ny + nz * nz) + 1e-6
        self._add(m, nx / ln, ny / ln, nz / ln, t, k, mat, shade, sep, pat)

    def chain(self, pts, r0, r1, mat, shade=0.0, sep=True, pat=None):
        n = len(pts) - 1
        for i in range(n):
            ra = r0 + (r1 - r0) * i / n
            rb = r0 + (r1 - r0) * (i + 1) / n
            self.limb(pts[i], pts[i + 1], ra, rb, mat, shade, sep and i == 0, pat)

    def poly(self, pts, mat, normal=(0.0, -0.3, 1.0), shade=0.0, sep=True, pat=None):
        im = Image.new("L", (self.W, self.H), 0)
        ImageDraw.Draw(im).polygon([(float(x), float(y)) for x, y in pts], fill=255)
        m = np.array(im) > 0
        nn = np.array(normal, float)
        nn /= np.linalg.norm(nn)
        z = np.zeros((self.H, self.W))
        self._add(m, z + nn[0], z + nn[1], z + nn[2], z, z, mat, shade, sep, pat)

    def eye(self, x, y, closed=False, size=2, col=(26, 20, 32), shine=True):
        self.marks.append(("eye", x, y, closed, size, col, shine))

    def dot(self, x, y, col, w=1, h=1):
        self.marks.append(("dot", x, y, w, h, col))

    # -------------------------------------------------------------- свет, узоры, контур
    def render(self, noise_seed=1):
        H, W = self.H, self.W
        out = np.zeros((H, W, 4), np.uint8)
        part = self.part
        rng = np.random.RandomState(noise_seed)
        # гладкий шум «шерсти» (не рябь): крупные зёрна 2x2
        nz = rng.rand(H // 2 + 2, W // 2 + 2)
        fur = np.kron(nz, np.ones((2, 2)))[:H, :W] - 0.5
        lvl = np.clip(self.n @ L, -1, 1)
        lvl = lvl * 0.6 + 0.27 + fur * 0.045
        # снизу темнее (окклюзия земли)
        lvl -= np.clip((self.yy / H - 0.75) * 0.5, 0, 0.2)
        for i, p in enumerate(self.parts):
            m = part == i
            if not m.any():
                continue
            mat = p["mat"]
            lv = lvl[m] + p["shade"]
            if p["pat"] is not None:
                lv = p["pat"](self.xx[m], self.yy[m], self.uv[m, 0], self.uv[m, 1], lv)
            if isinstance(lv, tuple):
                lv, alt = lv
            else:
                alt = None
            n = len(mat)
            idx = np.clip((lv * n).astype(int), 0, n - 1)
            cols = np.array(mat)[idx]
            if alt is not None:
                # alt: (маска, рампа) — другая окраска части (брюхо, пятна, носочки)
                for amask, aramp in alt:
                    if amask.any():
                        an = len(aramp)
                        aidx = np.clip((lv[amask] * an).astype(int), 0, an - 1)
                        cols[amask] = np.array(aramp)[aidx]
            sub = out[m]
            sub[:, :3] = np.clip(cols, 0, 255)
            sub[:, 3] = 255
            out[m] = sub
        # внутренние линии: пиксель задней части рядом с передней (sep) — темнее
        line = np.zeros((H, W), bool)
        for dy, dx in ((0, 1), (0, -1), (1, 0), (-1, 0)):
            nb = np.full((H, W), -1)
            ys = slice(max(0, dy), H + min(0, dy))
            yd = slice(max(0, -dy), H + min(0, -dy))
            xs = slice(max(0, dx), W + min(0, dx))
            xd = slice(max(0, -dx), W + min(0, -dx))
            nb[yd, xd] = part[ys, xs]
            front = nb > part
            okp = (part >= 0) & front
            if okp.any():
                sepf = np.array([pp["sep"] for pp in self.parts] + [False])
                okp &= sepf[nb]
            line |= okp
        if line.any():
            c = out[line][:, :3].astype(float)
            out[line, :3] = np.clip(c * 0.45 + OUTLINE * 0.55, 0, 255).astype(np.uint8)
        # метки (глаза и носы)
        for mk in self.marks:
            if mk[0] == "eye":
                _, x, y, closed, size, col, shine = mk
                x, y = int(round(x)), int(round(y))
                if closed:
                    for k in range(size + 1):
                        _px(out, x + k - 1, y + 1, (40, 30, 44))
                else:
                    for yy in range(size):
                        for xx in range(size):
                            _px(out, x + xx - size // 2, y + yy - size // 2, col)
                    if shine and size >= 2:
                        _px(out, x - size // 2, y - size // 2, (250, 248, 240))
            else:
                _, x, y, w, h, col = mk
                for yy in range(h):
                    for xx in range(w):
                        _px(out, int(round(x)) + xx, int(round(y)) + yy, col)
        # внешний контур: цвет — тёмная версия соседа
        a = out[:, :, 3] > 0
        edge = np.zeros((H, W), bool)
        acc = np.zeros((H, W, 3))
        cnt = np.zeros((H, W))
        for dy, dx in ((0, 1), (0, -1), (1, 0), (-1, 0)):
            sh = np.zeros((H, W), bool)
            shc = np.zeros((H, W, 3))
            ys = slice(max(0, dy), H + min(0, dy))
            yd = slice(max(0, -dy), H + min(0, -dy))
            xs = slice(max(0, dx), W + min(0, dx))
            xd = slice(max(0, -dx), W + min(0, -dx))
            sh[yd, xd] = a[ys, xs]
            shc[yd, xd] = out[ys, xs, :3]
            e = sh & ~a
            edge |= e
            acc[e] += shc[e]
            cnt[e] += 1
        cnt = np.maximum(cnt, 1)
        oc = acc / cnt[:, :, None] * 0.28 + OUTLINE * 0.72
        out[edge, :3] = np.clip(oc[edge], 0, 255).astype(np.uint8)
        out[edge, 3] = 255
        return out


def _px(out, x, y, col):
    H, W = out.shape[:2]
    if 0 <= x < W and 0 <= y < H and out[y, x, 3] > 0:
        out[y, x, :3] = col


# ------------------------------------------------------------------ узоры

def belly(rmp, thr=0.25):
    """Светлое брюхо/грудь: нижняя часть эллипса другой рампой."""
    def f(x, y, u, v, lv):
        return lv, [((v > thr), rmp)]
    return f


def stripes(freq, amp=0.25, axis="x", thr=0.55, rmp=None, phase=0.0):
    def f(x, y, u, v, lv):
        k = (np.sin((x if axis == "x" else y) * freq + phase + np.sin((y if axis == "x" else x) * 0.35) * 1.2) * 0.5 + 0.5)
        m = k > thr
        if rmp is not None:
            return lv, [(m, rmp)]
        return lv - m * amp
    return f


def spots(seed, n, rmin, rmax, rmp, area=(0, 0, 999, 999)):
    rs = random.Random(seed)
    pts = [(rs.uniform(area[0], area[2]), rs.uniform(area[1], area[3]), rs.uniform(rmin, rmax)) for _ in range(n)]

    def f(x, y, u, v, lv):
        m = np.zeros(x.shape, bool)
        for (cx, cy, r) in pts:
            m |= (x - cx) ** 2 + (y - cy) ** 2 < r * r
        return lv, [(m, rmp)]
    return f


def combo(*fs):
    def f(x, y, u, v, lv):
        alts = []
        for g in fs:
            r = g(x, y, u, v, lv)
            if isinstance(r, tuple):
                lv, a = r
                alts += a
            else:
                lv = r
        return (lv, alts) if alts else lv
    return f


def mask(rmp, v0, v1, umax):
    """Тёмная маска на морде (енот, тануки): полоса по высоте головы, спереди."""
    def f(x, y, u, v, lv):
        return lv, [(((v > v0) & (v < v1) & (u < umax)), rmp)]
    return f


def band(rmp, u0, u1):
    def f(x, y, u, v, lv):
        return lv, [(((u > u0) & (u < u1)), rmp)]
    return f


def make_pat(d):
    if d is None or callable(d):
        return d
    k = d[0]
    if k == "belly":
        return belly(ramp(d[1]), d[2])
    if k == "stripes":
        return stripes(d[1], d[2], d[3], d[4], ramp(d[5]) if d[5] else None)
    if k == "spots":
        return spots(d[1], d[2], d[3], d[4], ramp(d[5]))
    if k == "mask":
        return mask(ramp(d[1]), d[2], d[3], d[4])
    if k == "band":
        return band(ramp(d[1]), d[2], d[3])
    if k == "combo":
        return combo(*[make_pat(x) for x in d[1]])
    raise ValueError(d)


def tip(rmp, thr=0.7):
    """Кончик (для лапы-капсулы u — вдоль, для хвоста — тоже)."""
    def f(x, y, u, v, lv):
        return lv, [((u > thr), rmp)]
    return f


# ------------------------------------------------------------------ четвероногий зверь

def quad(sp, frame):
    """sp — словарь вида. frame 0..11."""
    W, H = sp["W"], sp["H"]
    cv = Canvas(W, H)
    gy = H - 3.0
    C = sp["cols"]
    main = ramp(C["main"])
    dark = ramp(C.get("dark", C["main"]), spread=0.9)
    bel = ramp(C.get("belly", C["main"]))
    legc = ramp(C.get("legs", C.get("dark", C["main"])))
    paw = ramp(C.get("paw", C.get("legs", C.get("dark", C["main"]))))
    brx, bry = sp["body"]
    leg = sp["leg"]
    lw = sp.get("leg_w", 3.0)
    walk = frame <= 3
    act = 6 <= frame <= 9
    sleep = frame >= 10
    ph = frame * math.pi / 2.0
    bob = (-1.0 if frame in (1, 3) else 0.0) if walk else 0.0
    breath = (0.6 if frame == 11 else 0.0) if sleep else 0.0
    bx = W * 0.5 + sp.get("bx", 0.0)
    by = gy - leg - bry * 0.55 + bob
    if sleep:
        by = gy - bry * 0.95 + 1.0
    sh_x = bx - brx * 0.62      # плечо (голова слева)
    hp_x = bx + brx * 0.6
    body_pat = sp.get("body_pat")
    if body_pat is None and "belly" in C:
        body_pat = belly(bel, sp.get("belly_thr", 0.35))
    actk = sp.get("act", "graze")
    # ---- хвост (сзади всего)
    tail = sp.get("tail", ("thin", 10, 2))
    tx, ty = hp_x + brx * 0.3, by - bry * 0.35
    sw = math.sin(frame * 1.3) * 1.5 if not sleep else 0
    ttype = tail[0]
    tcol = ramp(C.get("tail", C["main"]))
    ttip = ramp(C["tail_tip"]) if "tail_tip" in C else None
    tpat = sp.get("tail_pat")
    def tailpat():
        if tpat and ttip:
            return combo(tpat, tip(ttip, 0.74))
        if tpat:
            return tpat
        return tip(ttip, 0.74) if ttip else None
    def draw_tail(front=False):
        if ttype == "none":
            return
        tl = tail[1]
        if ttype == "bushy":
            ang = math.radians(tail[3] if len(tail) > 3 else 20) + sw * 0.03
            if sleep:
                pts = [(tx, ty + 2), (tx + tl * 0.3, gy - 4), (bx - brx * 0.2, gy - 3), (bx - brx * 0.9, gy - 4)]
            else:
                pts = [(tx, ty), (tx + tl * 0.45 * math.cos(ang), ty - tl * 0.45 * math.sin(ang) + 2),
                       (tx + tl * math.cos(ang), ty - tl * math.sin(ang) + 4 + sw)]
            cv.chain(pts, tail[2] * 0.6, tail[2], tcol, sep=True, pat=tailpat())
        elif ttype in ("thin", "long"):
            ang = math.radians(tail[3] if len(tail) > 3 else -40)
            if sleep:
                pts = [(tx, ty + 3), (tx + 3, gy - 2), (bx - brx * 0.3, gy - 1)]
            else:
                pts = [(tx, ty), (tx + tl * 0.5 * math.cos(ang), ty - tl * 0.5 * math.sin(ang)),
                       (tx + tl * math.cos(ang) + sw, ty - tl * math.sin(ang) + sw * 0.5)]
            cv.chain(pts, tail[2], tail[2] * 0.45, tcol, sep=True, pat=tailpat())
        elif ttype == "short":
            cv.ell(tx + 1, ty - (1 if not sleep else -1), tail[1] * 0.5, tail[2], tcol, rot=-0.5)
        elif ttype == "tuft":
            ang = math.radians(-70)
            pts = [(tx, ty), (tx + 3, ty + tl * 0.5), (tx + 2 + sw * 0.5, ty + tl)]
            if sleep:
                pts = [(tx, ty + 2), (tx + 4, gy - 2), (tx - 4, gy - 1)]
            cv.chain(pts, tail[2] * 0.5, tail[2] * 0.4, tcol, sep=True)
            end = pts[-1]
            cv.ell(end[0], end[1] + 1, tail[2] * 0.9, tail[2] * 1.3, ramp(C.get("tuft", C.get("dark", C["main"]))))
        elif ttype == "horse":
            hc = ramp(C.get("mane", C.get("dark", C["main"])))
            sw2 = math.sin(frame * 1.1) * 2
            pts = [(tx, ty - 1), (tx + 5, ty + tl * 0.3), (tx + 6 + sw2 * 0.5, ty + tl * 0.7), (tx + 4 + sw2, ty + tl)]
            if sleep:
                pts = [(tx, ty), (tx + 6, gy - 3), (tx + 2, gy - 1), (tx - 6, gy - 1)]
            cv.chain(pts, tail[2], tail[2] * 0.7, hc, sep=True, pat=stripes(1.4, 0.18, axis="x"))
        elif ttype == "flat":      # бобр
            ang = 0.2
            cv.ell(tx + tl * 0.55, ty + bry * 0.5 + (2 if not sleep else 0), tl * 0.55, tail[2], tcol, rot=ang,
                   pat=stripes(1.3, 0.2, axis="x", thr=0.6) if True else None)
        elif ttype == "curl":
            cv.chain([(tx, ty), (tx + 3, ty - 3), (tx + 5, ty - 1), (tx + 4, ty + 1)], tail[2], tail[2], tcol)
        elif ttype == "fan":       # павлиний — не нужен
            pass
    draw_tail()
    # ---- лапы
    def leg_pts(x0, y0, phase, hind, near):
        L1 = leg * sp.get("thigh", 0.5)
        L2 = leg - L1
        if sleep:
            # поджаты под телом
            return [(x0, y0), (x0 + (3 if hind else -2), gy - 3), (x0 + (-3 if hind else -5), gy - 1.5)]
        sw_ = math.sin(phase) * sp.get("stride", 0.42) if walk else 0.0
        lift = max(0.0, -math.cos(phase)) * leg * 0.18 if walk else 0.0
        if act and actk in ("dig",) and not hind:
            sw_ = math.sin(frame * 2.0) * 0.5
            lift = max(0, math.sin(frame * 2.0)) * 3
        kx = x0 + math.sin(sw_) * L1 + (2.0 if hind else -0.5) * sp.get("hock", 1.0)
        ky = y0 + math.cos(sw_) * L1
        fx = kx + math.sin(sw_ * 1.3) * L2 - (1.5 if hind else 0.0) * sp.get("hock", 1.0)
        fy = gy - lift
        return [(x0, y0), (kx, ky), (fx, fy)]
    def draw_leg(x0, y0, phase, hind, near):
        p = leg_pts(x0, y0, phase, hind, near)
        shade = 0.0 if near else -0.2
        top_w = lw * (1.5 if hind else 1.25) * sp.get("thigh_w", 1.0)
        cv.limb(p[0], p[1], top_w, lw, legc if not sp.get("leg_main") else main, shade, sep=True,
                pat=None)
        cv.limb(p[1], p[2], lw, lw * sp.get("ankle", 0.85), legc, shade, sep=False,
                pat=tip(paw, sp.get("sock", 0.7)))
        fx, fy = p[2]
        pw = sp.get("paw_w", lw * 1.25)
        if sp.get("hoof"):
            hc = ramp(C.get("hoof", "3a2e2a"))
            cv.ell(fx - 0.5, fy - 1.2, pw * 0.9, 1.8, hc, shade=shade, sep=True)
        else:
            cv.ell(fx - pw * 0.35, fy - pw * 0.4, pw, pw * 0.6, paw, shade=shade, sep=False)
    ly = by + bry * 0.25
    # дальние лапы
    draw_leg(sh_x + 2.5, ly, ph + math.pi, False, False)
    draw_leg(hp_x + 2.5, ly, ph, True, False)
    # ---- тело
    if sp.get("hump"):
        cv.ell(sh_x + 2, by - bry * 0.55, brx * 0.45, bry * 0.75, main, pat=body_pat)
    cv.ell(bx, by + breath * 0.5, brx, bry + breath, main, pat=body_pat)
    cv.ell(sh_x + 1, by + 0.5, bry * sp.get("chest", 0.95), bry * sp.get("chest", 0.95) * 0.98, main, sep=False, pat=body_pat)
    cv.ell(hp_x - 1, by - 0.5, bry * sp.get("hips", 0.9), bry * 0.95, main, sep=False, pat=body_pat)
    if sp.get("mane_body"):          # грива на плечах (зубр, лев)
        mc = ramp(C.get("mane", C.get("dark", C["main"])))
        cv.ell(sh_x + 1, by - 1, bry * 1.05, bry * 1.05, mc, sep=True, pat=stripes(1.1, 0.15, axis="y"))
    # ближние лапы
    draw_leg(sh_x, ly, ph, False, True)
    draw_leg(hp_x, ly, ph + math.pi, True, True)
    # ---- шея и голова
    hrx, hry = sp["head"]
    nl = sp.get("neck", 6.0)
    na = math.radians(sp.get("neck_ang", 35))
    graze = 0.0
    if act:
        k = [0.5, 1.0, 1.0, 0.6][frame - 6]
        if actk == "graze":
            graze = k
        elif actk == "sniff":
            graze = k * 0.55
        elif actk == "look":
            graze = -k * 0.4
        elif actk == "dig":
            graze = k * 0.45
        elif actk == "howl":
            graze = -k * 0.9
    if sleep:
        hx_, hy_ = sh_x - hrx * 0.9, gy - hry * 0.9
        na_ = 0.15
    else:
        a_ = na - graze * 1.25
        hx_ = sh_x - 1 - math.cos(a_) * nl
        hy_ = by - bry * 0.35 - math.sin(a_) * nl + bob
        if graze > 0:
            hy_ = min(hy_, gy - hry * 1.05)
    neck_c = sp.get("neck_w", bry * 0.7)
    if nl > 1:
        cv.limb((sh_x + 1, by - bry * 0.15), (hx_ + hrx * 0.2, hy_ + hry * 0.1), neck_c, hry * 0.8, main, sep=False,
                pat=body_pat if sp.get("neck_belly", True) else None)
    if sp.get("mane"):
        mc = ramp(C.get("mane", C.get("dark", C["main"])))
        nxv = (hx_ - sh_x)
        nyv = (hy_ - by)
        mp = []
        for i in range(5):
            k = i / 4.0
            mp.append((sh_x + 3 + nxv * k * 0.92 + 1.2 * (1 - k), by - bry * 0.62 + nyv * k * 0.92 - 1.4 + math.sin(frame * 1.2 + k * 3) * 0.4))
        cv.chain(mp, 2.6, 2.0, mc, sep=True, pat=stripes(1.3, 0.12, axis="y", thr=0.7))
    # ---- голова
    hpat = sp.get("head_pat")
    head_main = ramp(C.get("head", C["main"]))
    tilt = -0.25 * graze + sp.get("head_tilt", 0.0)
    # уши (дальнее)
    ears = sp.get("ears", ("point", 5))
    ec = ramp(C.get("ear", C.get("head", C["main"])))
    einner = ramp(C.get("ear_in", C.get("ear", C["main"])), spread=0.6)
    def ear(dx, far):
        et, es = ears[0], ears[1]
        ex, ey = hx_ + dx, hy_ - hry * 0.7
        shade = -0.15 if far else 0.0
        if et == "point":
            cv.poly([(ex - es * 0.45, ey + 2), (ex + es * 0.45, ey + 2), (ex + es * 0.15, ey - es)], ec, (0.2, -0.4, 1), shade=shade)
            if not far:
                cv.poly([(ex - es * 0.2, ey + 1), (ex + es * 0.25, ey + 1), (ex + es * 0.12, ey - es * 0.55)], einner, (0.4, 0, 1), sep=False)
        elif et == "round":
            cv.ell(ex + 1, ey - es * 0.25, es * 0.6, es * 0.55, ec, shade=shade)
            if not far:
                cv.ell(ex + 1, ey - es * 0.2, es * 0.32, es * 0.3, einner, sep=False)
        elif et == "long":
            back = 0.35 if not sleep else 1.1
            cv.ell(ex + es * 0.25 + es * back * 0.5, ey - es * 0.45 * (1 - back * 0.4), es * 0.28, es * 0.62, ec, rot=back, shade=shade)
            if not far:
                cv.ell(ex + es * 0.25 + es * back * 0.5, ey - es * 0.45 * (1 - back * 0.4), es * 0.12, es * 0.45, einner, rot=back, sep=False)
        elif et == "droop":
            cv.ell(ex + 2.5, ey + es * 0.5, es * 0.35, es * 0.65, ec, rot=-0.3, shade=shade - 0.05)
        elif et == "side":     # уши в стороны (корова, козёл, лось)
            cv.ell(ex + 3, ey + 1.5, es * 0.62, es * 0.28, ec, rot=-0.25, shade=shade)
            if not far:
                cv.ell(ex + 2.6, ey + 1.6, es * 0.35, es * 0.13, einner, rot=-0.25, sep=False)
        elif et == "tiny":
            cv.ell(ex + 1, ey + 0.5, es * 0.5, es * 0.45, ec, shade=shade)
    if ears[0] != "none":
        ear(hrx * 0.45, True)
    # рога за головой (дальний)
    horns = sp.get("horns")
    if horns and not sleep:
        _horns(cv, sp, hx_, hy_, hrx, hry, far=True)
    cv.ell(hx_, hy_, hrx, hry, head_main, rot=tilt, pat=hpat)
    # морда
    sl, sw_ = sp.get("snout", (5, 3))
    sdrop = sp.get("snout_drop", 0.4)
    snc = ramp(C.get("snout", C.get("head", C["main"])))
    sx = hx_ - hrx * 0.7 - sl * 0.35
    sy = hy_ + hry * sdrop + graze * 1.0
    ma = sp.get("muzzle_ang")
    if ma is not None and sl > 0:
        # длинная морда (кони, олени): клин от головы вниз-вперёд
        a = math.radians(ma) + graze * 0.5
        mx0, my0 = hx_ - hrx * 0.25, hy_ - hry * 0.1
        sx = mx0 - math.cos(a) * sl
        sy = my0 + math.sin(a) * sl
        cv.limb((mx0, my0), (sx, sy), hry * 0.92, sw_, snc, sep=False, pat=sp.get("snout_pat"))
        sl = 0.0001
        sx_tip, sy_tip = sx - math.cos(a) * sw_ * 0.6, sy + math.sin(a) * sw_ * 0.6
    elif sl > 0:
        cv.ell(sx, sy, sl * 0.75, sw_, snc, rot=tilt + sp.get("snout_rot", 0.15), sep=False, pat=sp.get("snout_pat"))
    if sp.get("cheeks"):
        ck = ramp(C.get("cheek", C.get("belly", C["main"])))
        cv.ell(hx_ - hrx * 0.25, hy_ + hry * 0.45, hrx * 0.55, hry * 0.45, ck, sep=False)
    if ears[0] != "none":
        ear(-hrx * 0.05, False)
    if horns and not sleep:
        _horns(cv, sp, hx_, hy_, hrx, hry, far=False)
    if horns and sleep:
        _horns(cv, sp, hx_ + 2, hy_ + 1, hrx, hry, far=False)
    if sp.get("forelock"):
        mc = ramp(C.get("mane", C.get("dark", C["main"])))
        cv.ell(hx_ - hrx * 0.3, hy_ - hry * 0.75, 3, 2.2, mc, rot=0.4)
    # глаз и нос
    ex = hx_ - hrx * sp.get("eye_x", 0.35)
    ey = hy_ - hry * sp.get("eye_y", 0.15) + graze * 0.5
    closed = sleep or frame == 5
    cv.eye(ex, ey, closed, sp.get("eye", 2), col=tuple(int(c) for c in hx(C.get("eye", "1a1420"))))
    if sp.get("mask"):
        pass
    if ma is not None:
        nose = C.get("nose", "2a1e24")
        cv.dot(sx_tip + 0.5, sy_tip - 1.2, tuple(int(c) for c in hx(nose)), 1, 1)
        cv.dot(sx_tip + 1.2, sy_tip + 0.8, tuple(int(c) for c in hx(nose)), 2, 1)
    elif sl > 0:
        nose = C.get("nose", "2a1e24")
        nx_ = sx - sl * 0.72
        ny_ = sy - sw_ * 0.45
        cv.dot(nx_, ny_, tuple(int(c) for c in hx(nose)), 2 if sl >= 4 else 1, 2 if sw_ >= 3 else 1)
    if sp.get("tusks") and not sleep:
        cv.dot(sx - sl * 0.2, sy + sw_ * 0.4, (236, 226, 200), 1, 2)
    if sp.get("wings"):
        _wings(cv, sp, bx, by, brx, bry, frame)
    return cv


def _horns(cv, sp, hx_, hy_, hrx, hry, far):
    C = sp["cols"]
    kind = sp["horns"]
    hc = ramp(C.get("horn", "d8c8a0"))
    shade = -0.18 if far else 0.0
    dx = hrx * 0.4 if far else 0.0
    bx, by = hx_ + dx, hy_ - hry * 0.7
    if kind == "antler":
        s = sp.get("antler_size", 1.0)
        main = [(bx, by), (bx + 3 * s, by - 6 * s), (bx + 6 * s, by - 12 * s), (bx + 4 * s, by - 18 * s)]
        cv.chain(main, 1.1, 0.7, hc, shade=shade)
        for (a, b) in [(1, (-2.5, -4)), (2, (-3, -4)), (2, (4, -3)), (3, (2.5, -3))]:
            p = main[a]
            cv.limb(p, (p[0] + b[0] * s, p[1] + b[1] * s), 0.8, 0.55, hc, shade=shade, sep=False)
    elif kind == "moose":
        s = sp.get("antler_size", 1.0)
        cv.limb((bx, by), (bx + 4 * s, by - 3 * s), 1.2, 1.2, hc, shade=shade)
        cv.ell(bx + 8 * s, by - 6 * s, 6 * s, 3.2 * s, hc, rot=-0.5, shade=shade, sep=False)
        for i in range(4):
            cv.limb((bx + (4 + i * 3) * s, by - (8 + i * 0.5) * s), (bx + (5 + i * 3.2) * s, by - (12 + i * 0.3) * s), 0.8, 0.5, hc, shade=shade, sep=False)
    elif kind == "curl":       # баран
        cv.chain([(bx + 1, by + 1), (bx + 5, by - 3), (bx + 8, by + 1), (bx + 6, by + 5), (bx + 3, by + 4)], 2.4, 1.4, hc, shade=shade, pat=stripes(2.0, 0.15, axis="x"))
    elif kind == "back":       # козёл, ибекс — назад
        s = sp.get("antler_size", 1.0)
        cv.chain([(bx, by + 1), (bx + 4 * s, by - 6 * s), (bx + 10 * s, by - 9 * s), (bx + 15 * s, by - 7 * s)], 1.8, 0.7, hc, shade=shade, pat=stripes(2.2, 0.15, axis="x"))
    elif kind == "bull":       # зубр, як — в стороны и вверх
        cv.chain([(bx + 1, by + 2), (bx - 4, by - 1), (bx - 5, by - 5)], 1.6, 0.8, hc, shade=shade)
    elif kind == "unicorn":
        if not far:
            cv.chain([(hx_ - hrx * 0.25, hy_ - hry * 0.8), (hx_ - hrx * 0.6, hy_ - hry * 1.6), (hx_ - hrx * 0.95, hy_ - hry * 2.4)], 1.5, 0.5, hc, pat=stripes(2.4, 0.2, axis="y"))
    elif kind == "jackalope":
        s = 0.6
        main = [(bx, by), (bx + 1 * s, by - 5 * s), (bx + 2 * s, by - 9 * s)]
        cv.chain(main, 0.8, 0.6, hc, shade=shade)
        cv.limb(main[1], (main[1][0] - 3 * s, main[1][1] - 3 * s), 0.6, 0.5, hc, shade=shade, sep=False)
    elif kind == "kirin":
        if not far:
            cv.chain([(hx_ + 1, hy_ - hry * 0.8), (hx_ + 3, hy_ - hry * 1.6), (hx_ + 6, hy_ - hry * 2.1)], 1.2, 0.5, hc)


def _wings(cv, sp, bx, by, brx, bry, frame):
    """Крыло из перьев: плечо → запястье, от руки веером маховые перья, сверху кроющие."""
    C = sp["cols"]
    wc = ramp(C.get("wing", C["main"]))
    up = [0.25, 0.65, 1.0, 0.6, 0.15, 0.15, 0.45, 1.0, 1.0, 0.45, -0.35, -0.35][frame]
    span = sp.get("wing_span", 18)
    sx0, sy0 = bx - brx * 0.15, by - bry * 0.55
    a = math.radians(20 + up * 55)                # угол руки крыла вверх-назад
    wx, wy = sx0 + math.cos(a) * span * 0.45, sy0 - math.sin(a) * span * 0.45
    n = 7
    for i in range(n):
        k = i / (n - 1)
        # точка на руке крыла
        px_ = sx0 + (wx - sx0) * (0.35 + k * 0.65)
        py_ = sy0 + (wy - sy0) * (0.35 + k * 0.65)
        # перо смотрит назад и вниз, крайние длиннее
        fa = a - math.radians(70 - k * 55)
        fl = span * (0.35 + k * 0.42)
        ex, ey = px_ + math.cos(fa) * fl, py_ - math.sin(fa) * fl
        cv.limb((px_, py_), (ex, ey), 2.0, 1.1, wc, shade=-0.04 * (n - 1 - i) * 0.5, sep=True)
    # кроющие перья — пухлый край руки
    cv.limb((sx0, sy0), (wx, wy), 3.4, 2.4, wc, sep=True)
    cv.ell(sx0 + 1, sy0 + 1, 4.5, 3.4, wc, sep=False)


# ------------------------------------------------------------------ другие строения тела

def lowbody(sp, frame):
    """Ящерица, тритон, саламандра, дракончик-ползун: низкое длинное тело, лапы в стороны, длинный хвост."""
    W, H = sp["W"], sp["H"]
    cv = Canvas(W, H)
    C = sp["cols"]
    gy = H - 3.0
    main = ramp(C["main"])
    bel = ramp(C.get("belly", C["main"]))
    walk = frame <= 3
    sleep = frame >= 10
    act = 6 <= frame <= 9
    brx, bry = sp["body"]
    bx = W * 0.5 + sp.get("bx", 0)
    by = gy - bry - (1.5 if not sleep else 0.0)
    wig = math.sin(frame * math.pi / 2) * 1.6 if walk else 0.0
    pat = sp.get("body_pat") or belly(bel, 0.3)
    # хвост
    tl = sp.get("tail_len", 20)
    pts = [(bx + brx * 0.8, by)]
    for i in range(1, 5):
        k = i / 4
        pts.append((bx + brx * 0.8 + tl * k, by + bry * 0.5 * k + math.sin(k * 3 + frame) * (2 if not sleep else 0.5) + (gy - by - 1.5) * k * 0.8))
    cv.chain(pts, bry * 0.75, 0.8, main, pat=pat)
    # лапы
    ll = sp.get("leg", 4)
    for (x0, ph, near) in ((bx - brx * 0.55, 0, False), (bx + brx * 0.5, math.pi, False), (bx - brx * 0.6, math.pi, True), (bx + brx * 0.45, 0, True)):
        s_ = math.sin(frame * math.pi / 2 + ph) * 2.5 if walk else 0
        cv.limb((x0, by + 1), (x0 + s_ - 1.5, gy - 0.5), 1.6, 1.2, main, shade=0 if near else -0.22)
    cv.ell(bx, by, brx, bry, main, pat=pat)
    # голова
    hrx, hry = sp["head"]
    up = (-2.5 if act and frame in (7, 8) else 0)
    hx_ = bx - brx - hrx * 0.6 + wig * 0.3
    hy_ = by - 0.5 + up + (1.0 if sleep else 0)
    cv.ell(hx_, hy_, hrx, hry, ramp(C.get("head", C["main"])), rot=0.1, pat=sp.get("head_pat") or belly(bel, 0.35))
    if sp.get("crest"):
        cr = ramp(C.get("crest", C["main"]))
        for i in range(5):
            cv.poly([(bx - brx + i * brx * 0.45, by - bry + 1), (bx - brx + i * brx * 0.45 + 2.5, by - bry - 3), (bx - brx + i * brx * 0.45 + 4, by - bry + 1)], cr, (0, -1, 1), sep=False)
    cv.eye(hx_ - hrx * 0.3, hy_ - hry * 0.3, sleep or frame == 5, sp.get("eye", 2), col=tuple(int(c) for c in hx(C.get("eye", "1a1420"))))
    if act and frame in (7, 8) and sp.get("tongue", True):
        cv.dot(hx_ - hrx - 2, hy_ + 1, (220, 90, 110), 3, 1)
    if sp.get("wings"):
        _wings(cv, sp, bx, by, brx, bry, frame)
    return cv


def turtle(sp, frame):
    W, H = sp["W"], sp["H"]
    cv = Canvas(W, H)
    C = sp["cols"]
    gy = H - 3.0
    shell = ramp(C["shell"])
    skin = ramp(C["skin"])
    walk = frame <= 3
    sleep = frame >= 10
    act = 6 <= frame <= 9
    srx, sry = sp["body"]
    bx = W * 0.5
    by = gy - 3.5 - (0 if not sleep else -1.5)
    ph = frame * math.pi / 2
    # лапы
    for (x0, p, near) in ((bx - srx * 0.6, 0, False), (bx + srx * 0.55, math.pi, False), (bx - srx * 0.65, math.pi, True), (bx + srx * 0.5, 0, True)):
        if sleep:
            continue
        s_ = math.sin(ph + p) * 2 if walk else 0
        cv.limb((x0, by - 1), (x0 + s_, gy - 1), 2.6, 2.4, skin, shade=0 if near else -0.2)
    # голова на шее
    out = 0 if sleep else (1.0 if not act else [1.2, 1.6, 1.6, 1.2][frame - 6])
    hrx, hry = sp["head"]
    hx_ = bx - srx * 0.85 - hrx * out
    hy_ = by - 2 - (out - 1) * 3
    if not sleep:
        cv.limb((bx - srx * 0.5, by - 1), (hx_ + 1, hy_), hry * 0.75, hry * 0.7, skin, sep=False)
        cv.ell(hx_, hy_, hrx, hry, skin, pat=sp.get("head_pat"))
    # панцирь
    rs = random.Random(sp.get("seed", 3))
    def shell_pat(x, y, u, v, lv):
        # щитки: шестиугольники по кругу
        cell = sp.get("scute", 6.0)
        gx = np.round((x - bx) / cell)
        gy_ = np.round((y - (by - sry * 0.5)) / (cell * 0.8) + gx * 0.5 * 0)
        cx = gx * cell + bx
        cy = gy_ * cell * 0.8 + by - sry * 0.5
        d = np.maximum(abs(x - cx) / cell, abs(y - cy) / (cell * 0.8))
        edge = d > 0.42
        alt = [(edge, ramp(C.get("scute_line", C["shell"]), spread=0.7))]
        lv = lv + (0.08 - d * 0.3)
        return lv, alt
    cv.ell(bx, by - sry * 0.25, srx, sry, shell, half="top", pat=shell_pat)
    rim = ramp(C.get("rim", C["shell"]))
    cv.ell(bx, by, srx * 1.02, 2.4, rim, sep=False)
    if sp.get("crystal"):
        cr = ramp(C["crystal"])
        for i, (dx, hh) in enumerate([(-6, 9), (0, 13), (6, 10), (-2, 7)]):
            cv.poly([(bx + dx - 3, by - sry * 0.7), (bx + dx + 3, by - sry * 0.7), (bx + dx + 1, by - sry * 0.7 - hh)], cr, (0.4, -0.5, 1), sep=True)
    if not sleep:
        cv.eye(hx_ - hrx * 0.35, hy_ - hry * 0.25, frame == 5, 2)
    return cv


def frog(sp, frame):
    W, H = sp["W"], sp["H"]
    cv = Canvas(W, H)
    C = sp["cols"]
    gy = H - 3.0
    main = ramp(C["main"])
    bel = ramp(C.get("belly", C["main"]))
    hop = [0, 4, 6, 2][frame] if frame <= 3 else 0
    sleep = frame >= 10
    act = 6 <= frame <= 9
    brx, bry = sp["body"]
    bx = W * 0.5
    by = gy - bry * 0.8 - hop
    pat = combo(sp.get("body_pat") or (lambda x, y, u, v, lv: lv), belly(bel, 0.4))
    # задняя лапа (бедро) и стопа
    st = 1.0 if hop < 3 else 0.4
    cv.ell(bx + brx * 0.55, by + bry * 0.3, brx * 0.55, bry * 0.55 * st + 0.5, main, shade=-0.05, pat=sp.get("body_pat"))
    cv.limb((bx + brx * 0.6, by + bry * 0.6), (bx + brx * (0.1 if hop < 3 else 1.2), gy - 0.5), 1.6, 1.4, main)
    cv.ell(bx, by, brx, bry, main, rot=-0.25, pat=pat)
    # передняя лапка
    cv.limb((bx - brx * 0.45, by + bry * 0.2), (bx - brx * 0.65, gy - 0.5), 1.5, 1.3, main, sep=True)
    # голова — бугорки глаз
    ex, ey = bx - brx * 0.55, by - bry * 0.75
    cv.ell(ex, ey, 2.8, 2.6, main)
    if act:
        sac = [0, 2.5, 3.5, 1.5][frame - 6]
        if sac > 0:
            cv.ell(bx - brx * 0.7, by + bry * 0.25, sac + 1, sac, ramp(C.get("sac", "e8d8a0")))
    cv.eye(ex - 0.5, ey - 0.4, sleep or frame == 5, 2, col=tuple(int(c) for c in hx(C.get("eye", "1a1420"))))
    cv.dot(bx - brx * 1.0, by - 0.5, (40, 30, 34), 3, 1)
    return cv


def snake(sp, frame):
    W, H = sp["W"], sp["H"]
    cv = Canvas(W, H)
    C = sp["cols"]
    gy = H - 3.0
    main = ramp(C["main"])
    bel = ramp(C.get("belly", C["main"]))
    sleep = frame >= 10
    act = 6 <= frame <= 9
    n = 14
    L_ = sp.get("len", 46)
    pts = []
    for i in range(n + 1):
        k = i / n
        if sleep:
            a = k * math.pi * 3.2
            r = 3 + k * 9
            pts.append((W * 0.5 + math.cos(a) * r, gy - 4 - math.sin(a) * r * 0.45))
        else:
            x = W * 0.18 + k * L_
            y = gy - 3.5 + math.sin(k * 7.0 + frame * 1.6) * 3.0 * (0.4 + k * 0.6)
            pts.append((x, y))
    if sleep:
        pts = pts[::-1]
    th = sp.get("th", 3.4)
    pat = sp.get("body_pat")
    for i in range(n, 0, -1):
        k = i / n
        r = th * (1.0 - k * 0.75)
        cv.limb(pts[i - 1], pts[i], r, r * 0.95, main, sep=False, pat=pat)
    hx_, hy_ = pts[0]
    if act and frame in (7, 8):
        hy_ -= 4
        cv.limb(pts[1], (hx_, hy_), th, th, main, sep=False, pat=pat)
    cv.ell(hx_ - 1.5, hy_ - 0.5, th * 1.35, th * 1.05, ramp(C.get("head", C["main"])), rot=0.15, pat=sp.get("head_pat"))
    if sp.get("collar"):
        cv.ell(hx_ + 2.5, hy_ - 0.5, 1.8, th * 0.9, ramp(C["collar"]), sep=False)
    cv.eye(hx_ - 2.5, hy_ - 1.2, sleep or frame == 5, 2)
    if act and frame in (7, 8):
        cv.dot(hx_ - th * 1.35 - 3, hy_ + 0.5, (220, 70, 90), 3, 1)
    return cv


def crab(sp, frame):
    W, H = sp["W"], sp["H"]
    cv = Canvas(W, H)
    C = sp["cols"]
    gy = H - 3.0
    main = ramp(C["main"])
    walk = frame <= 3
    sleep = frame >= 10
    act = 6 <= frame <= 9
    brx, bry = sp["body"]
    bx = W * 0.5
    by = gy - 5 - (0 if not sleep else -2.5)
    sh = math.sin(frame * math.pi / 2) * 1.5 if walk else 0
    for i in range(3):
        for side in (-1, 1):
            x0 = bx + side * (brx * 0.5 + i * 2)
            ph = frame * math.pi / 2 + i + (0 if side < 0 else 1.5)
            lift = max(0, math.sin(ph)) * 2 if walk else 0
            cv.chain([(x0, by), (x0 + side * 5, by - 2 - lift), (x0 + side * 7, gy - lift * 0.5)], 1.1, 0.8, main, shade=-0.15 if i == 1 else 0)
    cv.ell(bx + sh, by - bry * 0.3, brx, bry, main, half="top", pat=spots(5, 6, 0.8, 1.6, ramp(C.get("spot", C["main"])), (bx - brx, by - bry, bx + brx, by)))
    snap = (act and frame in (7, 9))
    for side in (-1, 1):
        cx_ = bx + side * (brx + 3) + sh
        cy_ = by - bry * 0.9 - (3 if act else 0)
        cv.limb((bx + side * brx * 0.7 + sh, by - 1), (cx_, cy_ + 2), 1.4, 1.4, main)
        cv.ell(cx_ + side * 1.5, cy_, 3.4, 2.6, main, rot=side * 0.4)
        if not snap:
            cv.poly([(cx_ + side * 2, cy_ - 1), (cx_ + side * 5.5, cy_ - 4), (cx_ + side * 4.5, cy_ + 0.5)], main, (0, -1, 1), sep=True)
    for side in (-1, 1):
        cv.limb((bx + side * 2 + sh, by - bry - 0.5), (bx + side * 3 + sh, by - bry - 4), 0.6, 0.6, main, sep=False)
        cv.eye(bx + side * 3 + sh, by - bry - 4.5, sleep or frame == 5, 2, shine=True)
    return cv


def seal(sp, frame):
    W, H = sp["W"], sp["H"]
    cv = Canvas(W, H)
    C = sp["cols"]
    gy = H - 3.0
    main = ramp(C["main"])
    bel = ramp(C.get("belly", C["main"]))
    walk = frame <= 3
    sleep = frame >= 10
    act = 6 <= frame <= 9
    brx, bry = sp["body"]
    bx = W * 0.5
    hump = [0, 2, 0, 1][frame] if walk else 0
    by = gy - bry + 0.5 - hump * 0.5
    pat = combo(spots(9, 10, 0.8, 1.7, ramp(C.get("spot", C["main"])), (bx - brx, by - bry, bx + brx, by)), belly(bel, 0.45))
    cv.ell(bx + brx * 0.95, gy - 2.5, 5, 2, main, rot=0.3, sep=False)
    cv.ell(bx, by, brx, bry, main, rot=0.05, pat=pat)
    up = [2, 6, 6, 3][frame - 6] if act else 0
    hx_ = bx - brx * 0.95
    hy_ = by - bry * 0.6 - up - (0 if not sleep else -bry * 0.4)
    cv.ell(hx_, hy_, sp["head"][0], sp["head"][1], main, pat=pat)
    cv.ell(bx - brx * 0.25, gy - 2.5, 4.5, 2, main, rot=-0.4, sep=True)
    cv.eye(hx_ - 2, hy_ - 1, sleep or frame == 5, 3)
    cv.dot(hx_ - sp["head"][0] + 0.5, hy_ + 1, (40, 30, 34), 2, 1)
    return cv


def snail(sp, frame):
    W, H = sp["W"], sp["H"]
    cv = Canvas(W, H)
    C = sp["cols"]
    gy = H - 3.0
    skin = ramp(C["skin"])
    shell = ramp(C["shell"])
    sleep = frame >= 10
    stretch = [0, 1, 2, 1][frame] if frame <= 3 else 0
    bx = W * 0.5
    if not sleep:
        cv.limb((bx + 8, gy - 2), (bx - 9 - stretch, gy - 2.5), 2.2, 2.6, skin, pat=belly(ramp(C.get("foot", C["skin"])), 0.4))
        cv.limb((bx - 8 - stretch, gy - 3), (bx - 11 - stretch, gy - 9), 0.8, 0.7, skin, sep=False)
        cv.limb((bx - 6 - stretch, gy - 3), (bx - 7 - stretch, gy - 10), 0.8, 0.7, skin, sep=False, shade=-0.2)
        cv.dot(bx - 11.5 - stretch, gy - 10, (40, 30, 34), 2, 1)
    else:
        cv.limb((bx + 6, gy - 2), (bx - 5, gy - 2), 2, 2, skin)
    def spiral(x, y, u, v, lv):
        a = np.arctan2(y - (gy - 9), x - (bx + 1))
        r = np.sqrt((x - (bx + 1)) ** 2 + (y - (gy - 9)) ** 2)
        k = (r - a * 1.1) % 4.0
        return lv, [((k < 1.0), ramp(C.get("band", C["shell"])))]
    cv.ell(bx + 1, gy - 9, 7, 6.5, shell, pat=spiral)
    return cv


BUILD = {"quad": quad, "low": lowbody, "turtle": turtle, "frog": frog, "snake": snake, "crab": crab, "seal": seal, "snail": snail}


# ------------------------------------------------------------------ виды
# kind: строение; W,H — кадр (пиксели листа; в игре в 2 раза меньше); cols — базовые цвета
from fauna25_species import SPECIES  # noqa: E402


def sheet(sid, sp):
    sp = dict(sp)
    for k in ("body_pat", "head_pat", "snout_pat", "tail_pat"):
        if k in sp:
            sp[k] = make_pat(sp[k])
    build = BUILD[sp.get("kind", "quad")]
    W, H = sp["W"], sp["H"]
    img = np.zeros((H, W * 12, 4), np.uint8)
    for f in range(12):
        cv = build(sp, f)
        fr = cv.render(noise_seed=hash(sid) % 1000 + f // 4)
        img[:, f * W:(f + 1) * W] = fr
    return Image.fromarray(img, "RGBA")


def write_db(ids):
    """fauna25_db.gd — данные новых зверей для игры (руками не править)."""
    lines = ["extends RefCounted", "## v25: новые звери (генерирует tools/fauna25.py — руками не править)", "", "const ANIMALS: Dictionary = {"]
    for sid in ids:
        sp = SPECIES[sid]
        g = sp["game"]
        extra = ""
        for k in ("mythic", "farm", "ride", "night", "fly", "water"):
            if g.get(k):
                extra += ', "%s": true' % k
        if g.get("ride"):
            H = sp["H"]
            gy = H - 3.0
            if sp.get("kind", "quad") == "quad":
                bry = sp["body"][1]
                top = gy - sp["leg"] - bry * 0.55 - bry
            elif sp.get("kind") == "turtle":
                top = gy - 3.5 - sp["body"][1] * 1.25
            else:
                top = gy - sp["body"][1] * 2
            extra += ', "ride_speed": %.2f, "tame": %d, "back": %.1f' % (g.get("ride_speed", 1.8), g.get("tame", 4), (gy - top) / 2.0)
        lines.append('\t"%s": {"name": "%s", "w": %d, "h": %d, "speed": %.1f, "shy": %s, "pet": %s, "sound": "%s"%s, "v25": true},' % (
            sid, g["name"], sp["W"] // 2, sp["H"] // 2, g["speed"], "true" if g["shy"] else "false", "true" if g["pet"] else "false", g.get("sound", ""), extra))
    lines.append("}")
    lines.append("")
    lines.append("## биом: [[зверь, сколько в области]...]")
    fauna = {}
    myth = {}
    for sid in ids:
        g = SPECIES[sid]["game"]
        for b, n in g.get("biomes", {}).items():
            if g.get("mythic"):
                myth.setdefault(b, []).append((sid, n))
            else:
                fauna.setdefault(b, []).append((sid, n))
    lines.append("const FAUNA: Dictionary = {")
    for b in sorted(fauna):
        lines.append("\t%d: [%s]," % (b, ", ".join('["%s", %s]' % (s, n) for s, n in fauna[b])))
    lines.append("}")
    lines.append("const MYTHIC_SPAWN: Dictionary = {")
    for b in sorted(myth):
        lines.append("\t%d: [%s]," % (b, ", ".join('["%s", %s]' % (s, n) for s, n in myth[b])))
    lines.append("}")
    lines.append("")
    lines.append("## занятие: [звук, эффект, сдвиг эффекта, длительность от, до]")
    lines.append("const ACTS: Dictionary = {")
    for sid in ids:
        a = SPECIES[sid]["game"].get("acts", ["", "", 0.0, 0.0, 2.0, 4.0])
        lines.append('\t"%s": ["%s", "%s", Vector2(%.1f, %.1f), %.1f, %.1f],' % (sid, a[0], a[1], a[2], a[3], a[4], a[5]))
    lines.append("}")
    lines.append("const NIGHT_OWLS: Array = [%s]" % ", ".join('"%s"' % s for s in ids if SPECIES[s]["game"].get("night")))
    lines.append("")
    lines.append("## книга: описание, где живёт, что любит, что даёт в загоне, шанс потомства")
    lines.append("const ZOO: Dictionary = {")
    for sid in ids:
        g = SPECIES[sid]["game"]
        z = g["zoo"]
        lines.append('\t"%s": ["%s", "%s", [%s], ["%s", %d], %.2f],' % (sid, z[0], z[1], ", ".join('"%s"' % f for f in z[2]), z[3][0], z[3][1], z[4]))
    lines.append("}")
    lines.append("const ORDER: Array = [%s]" % ", ".join('"%s"' % s for s in ids))
    lines.append("## шерсть/пух, что остаётся в ловушке")
    lines.append("const LOOT: Dictionary = {")
    for sid in ids:
        z = SPECIES[sid]["game"]["zoo"]
        lines.append('\t"%s": [["%s", 1, 2, 1.0]],' % (sid, z[3][0]))
    lines.append("}")
    lines.append("## новые предметы из зверей: id -> [имя, цена]")
    items = {}
    for sid in ids:
        z = SPECIES[sid]["game"]["zoo"]
        if len(z) > 5:
            items[z[3][0]] = z[5]
    lines.append("const ITEMS: Dictionary = {")
    for k, v in items.items():
        lines.append('\t"%s": ["%s", %d],' % (k, v[0], v[1]))
    lines.append("}")
    open(os.path.join(HERE, "..", "fauna25_db.gd"), "w", encoding="utf-8", newline="\n").write("\n".join(lines) + "\n")


def main():
    ids = [a for a in sys.argv[1:] if not a.startswith("-")]
    all_ids = list(SPECIES.keys())
    todo = ids or all_ids
    os.makedirs(SHOTS, exist_ok=True)
    prev = []
    for sid in todo:
        im = sheet(sid, SPECIES[sid])
        im.save(os.path.join(ART, "animal_%s.png" % sid))
        prev.append((sid, im, SPECIES[sid]["W"], SPECIES[sid]["H"]))
        print("ok", sid)
    write_db(all_ids)
    # превью: кадры 0, 2, 4, 7, 10 каждого зверя, x3
    cols = 4
    cw = max(p[2] for p in prev) * 5 + 8
    rows = []
    for sid, im, w, h in prev:
        row = Image.new("RGBA", (cw, h + 4), (86, 116, 150, 255))
        for i, f in enumerate((0, 2, 4, 7, 10)):
            fr = im.crop((f * w, 0, f * w + w, h))
            row.alpha_composite(fr, (i * w, 2))
        rows.append(row)
    n_c = max(1, min(cols, len(rows)))
    per = math.ceil(len(rows) / n_c)
    colh = [sum(r.height for r in rows[c * per:(c + 1) * per]) for c in range(n_c)]
    out = Image.new("RGBA", (cw * n_c, max(colh)), (86, 116, 150, 255))
    for c in range(n_c):
        y = 0
        for r in rows[c * per:(c + 1) * per]:
            out.alpha_composite(r, (c * cw, y))
            y += r.height
    sc = 2 if out.width * 2 < 2600 else 1
    out = out.resize((out.width * sc, out.height * sc), Image.NEAREST)
    out.save(os.path.join(SHOTS, "fauna25_preview.png"))


if __name__ == "__main__":
    sys.path.insert(0, HERE)
    main()

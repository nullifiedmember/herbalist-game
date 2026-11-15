"""Кот «по частям» для v26: силуэт строится из анатомических частей (череп, щёки, мордочка, уши, шея,
грудь, спина, бёдра, лапы со скакательным суставом, хвост дугой), потом затеняется и получает контур.
Выход — словарь пикселей в палитре чёрного кота (как art/cat.png), дальше его перекрашивает cats26.py.

Кадры как у кота травницы: 0 сидит, 1 сидит (моргнул, хвост качнулся), 2-3 спит (дышит),
4-5 жмурится (гладят), 6-9 идёт. Кадр 42x30, земля — нижняя строка, кот стоит в точке x=18.
Котёнок — те же части: голова почти как у взрослого, тело и лапки меньше (без растягивания пикселей).
"""
import math

FW, FH = 42, 30
G = 29.6            # земля (низ лап)
CX = 19.0           # середина тела по x

LV = {0: (12, 10, 22, 255), 1: (23, 19, 38, 255), 2: (33, 26, 48, 255), 3: (46, 39, 72, 255),
      4: (64, 55, 94, 255), 5: (88, 76, 122, 255), 6: (122, 110, 162, 255)}
EYE = [(138, 160, 48, 255), (168, 192, 64, 255), (200, 220, 88, 255), (212, 232, 112, 255), (232, 244, 144, 255)]
PUPIL = (12, 10, 22, 255)
SHINE = (255, 255, 255, 255)
PINK = (200, 120, 140, 255)
PINK_D = (154, 84, 112, 255)
NOSE = (212, 124, 148, 255)
MOUTH = (110, 58, 74, 255)


# ------------------------------------------------------------------ фигуры (в координатах взрослого кота)

def ell(c, rx, ry, rot=0.0):
    ca, sa = math.cos(math.radians(rot)), math.sin(math.radians(rot))

    def f(x, y):
        dx, dy = x - c[0], y - c[1]
        u = dx * ca + dy * sa
        v = -dx * sa + dy * ca
        return (u / rx) ** 2 + (v / ry) ** 2 <= 1.0
    return f


def cap(a, b, ra, rb=None):
    """капсула от a до b, радиус плавно меняется от ra к rb"""
    rb = ra if rb is None else rb

    def f(x, y):
        ax, ay = a
        bx, by = b
        vx, vy = bx - ax, by - ay
        L2 = vx * vx + vy * vy or 1e-9
        t = max(0.0, min(1.0, ((x - ax) * vx + (y - ay) * vy) / L2))
        px, py = ax + vx * t, ay + vy * t
        return math.hypot(x - px, y - py) <= ra + (rb - ra) * t
    return f


def tri(p1, p2, p3):
    def f(x, y):
        def s(a, b, c):
            return (a[0] - c[0]) * (b[1] - c[1]) - (b[0] - c[0]) * (a[1] - c[1])
        d1, d2, d3 = s((x, y), p1, p2), s((x, y), p2, p3), s((x, y), p3, p1)
        neg = d1 < 0 or d2 < 0 or d3 < 0
        pos = d1 > 0 or d2 > 0 or d3 > 0
        return not (neg and pos)
    return f


def bez(p0, p1, p2, p3, n=40):
    pts = []
    for i in range(n + 1):
        t = i / n
        a = (1 - t) ** 3
        b = 3 * (1 - t) ** 2 * t
        c = 3 * (1 - t) * t * t
        d = t ** 3
        pts.append((a * p0[0] + b * p1[0] + c * p2[0] + d * p3[0], a * p0[1] + b * p1[1] + c * p2[1] + d * p3[1]))
    return pts


def tube(pts, r0, r1):
    """хвост: толстая линия по точкам, радиус от r0 к r1; возвращает (внутри?, доля длины 0..1)"""
    n = len(pts) - 1

    def f(x, y):
        best = None
        for i in range(n):
            a, b = pts[i], pts[i + 1]
            vx, vy = b[0] - a[0], b[1] - a[1]
            L2 = vx * vx + vy * vy or 1e-9
            t = max(0.0, min(1.0, ((x - a[0]) * vx + (y - a[1]) * vy) / L2))
            d = math.hypot(x - a[0] - vx * t, y - a[1] - vy * t)
            k = (i + t) / n
            if d <= r0 + (r1 - r0) * k and (best is None or d < best[0]):
                best = (d, k)
        return best
    return f


def rot(p, piv, deg):
    a = math.radians(deg)
    dx, dy = p[0] - piv[0], p[1] - piv[1]
    return (piv[0] + dx * math.cos(a) - dy * math.sin(a), piv[1] + dx * math.sin(a) + dy * math.cos(a))


# ------------------------------------------------------------------ позы

class Layer:
    def __init__(self, name, part_fn, inside, space="body", shade=0, rim=True):
        self.name = name          # группа для теней и контура
        self.part_fn = part_fn    # (x, y) взрослые координаты -> часть тела
        self.inside = inside      # (x, y) -> bool  или для хвоста -> (d, k)/None
        self.space = space        # "body" или "head" (у котёнка разные масштабы)
        self.shade = shade        # -1 для дальних лап
        self.rim = rim


def walk_pose(fr):
    """идёт влево; fr 0..3 — фаза шага"""
    ch = (13.6, 16.4)        # грудь
    ru = (27.4, 16.0)        # круп
    H = (6.6, 8.6)           # центр головы
    s = 1.0
    # шаг: + лапа вперёд (влево)
    nf, ff, nh, fh = [(20, -12, -14, 18), (6, 0, 0, 6), (-14, 20, 18, -12), (0, 6, 6, 0)][fr]
    L = []
    sh = (ch[0] + 0.2, ch[1] + 1.0)
    hip = (ru[0] - 0.6, ru[1] + 0.4)

    def front(piv, ang, dx):
        p0 = (piv[0] + dx, piv[1])
        wr = rot((piv[0] + dx - 0.6, 26.2), p0, ang)
        pw = rot((piv[0] + dx - 1.0, G - 1.0), p0, ang)
        f1 = cap(p0, wr, 2.3, 1.7)
        f2 = cap(wr, (pw[0], min(pw[1], G - 1.0)), 1.7, 1.5)
        toe = ell((pw[0] - 0.6, G - 1.0), 1.9, 1.05)
        return lambda x, y: f1(x, y) or f2(x, y) or toe(x, y)

    def hind(piv, ang, dx):
        p0 = (piv[0] + dx, piv[1])
        th = ell(rot((p0[0] + 0.2, p0[1] + 3.4), p0, ang * 0.5), 3.9, 5.0, -18 + ang * 0.5)
        knee = rot((p0[0] - 1.2, p0[1] + 7.0), p0, ang * 0.6)
        hock = rot((p0[0] + 1.6, 25.6), p0, ang)
        pw = rot((p0[0] + 0.6, G - 1.0), p0, ang)
        a1 = cap(knee, hock, 2.2, 1.6)
        a2 = cap(hock, (pw[0], min(pw[1], G - 1.0)), 1.5, 1.4)
        toe = ell((pw[0] - 0.7, G - 1.0), 1.9, 1.05)
        return lambda x, y: th(x, y) or a1(x, y) or a2(x, y) or toe(x, y)

    def leg_part(x, y):
        return "paw" if y >= G - 2.2 else "leg"

    # дальние лапы
    L.append(Layer("far", leg_part, hind(hip, fh, 1.6), shade=-1))
    L.append(Layer("far2", leg_part, front(sh, ff, 1.6), shade=-1))
    # хвост: от крупа назад и дугой вверх
    wag = [0.0, 0.8, 0.0, -0.8][fr]
    tp = bez((ru[0] + 3.2, ru[1] - 2.0), (ru[0] + 8.5, ru[1] - 2.6), (ru[0] + 12.6 + wag, ru[1] - 8.0),
             (ru[0] + 10.0 + wag, ru[1] - 13.2))
    L.append(Layer("tail", lambda x, y: "tail", tube(tp, 2.1, 1.5)))
    # тело: грудь глубже, прямая спина, круп
    body = cap(ch, ru, 5.4, 4.5)
    neck = cap((H[0] + 2.2, H[1] + 2.4), (ch[0] - 1.0, ch[1] - 1.6), 3.4, 4.2)
    chest = ell((ch[0] - 2.6, ch[1] + 1.2), 3.6, 4.6, 10)

    def body_part(x, y):
        if x < ch[0] + 0.5 and y > ch[1] - 1.0:
            return "chest"
        if y > ch[1] + 3.2:
            return "belly"
        return "body"
    L.append(Layer("body", body_part, lambda x, y: body(x, y) or neck(x, y) or chest(x, y)))
    L.append(Layer("hind", leg_part, hind(hip, nh, 0.0)))
    L.append(Layer("front", leg_part, front(sh, nf, 0.0)))
    # голова: череп, щёки, мордочка, уши
    cran = ell(H, 4.7 * s, 4.4 * s)
    cheek = ell((H[0] + 0.2, H[1] + 1.8), 4.9 * s, 3.1 * s)
    muz = ell((H[0] - 3.7 * s, H[1] + 1.9 * s), 2.2 * s, 1.8 * s)
    ear_f = tri((H[0] - 3.9, H[1] - 2.0), (H[0] - 0.9, H[1] - 3.6), (H[0] - 3.6, H[1] - 8.0))
    ear_n = tri((H[0] - 0.2, H[1] - 3.9), (H[0] + 3.9, H[1] - 2.0), (H[0] + 2.6, H[1] - 8.2))

    def head_part(x, y):
        if ear_n(x, y) or ear_f(x, y):
            if not cran(x, y):
                return "ear"
        if muz(x, y) or (y > H[1] + 2.0 and x < H[0] - 1.0):
            return "face"
        if y < H[1] - 1.8 and abs(x - (H[0] - 1.2)) < 1.0:
            return "blaze"
        return "head"
    L.append(Layer("ear_f", lambda x, y: "ear", ear_f, space="head", shade=-1))
    L.append(Layer("head", head_part, lambda x, y: cran(x, y) or cheek(x, y) or muz(x, y), space="head"))
    L.append(Layer("ear_n", lambda x, y: "ear", ear_n, space="head"))
    feats = {
        "eye_side": (H[0] - 2.2, H[1] - 0.2),
        "nose_side": (H[0] - 5.7, H[1] + 1.2),
        "mouth_side": (H[0] - 4.8, H[1] + 3.0),
        "ear_pink": [(ear_n, (H[0] + 2.0, H[1] - 4.6), 1.4), (ear_f, (H[0] - 3.0, H[1] - 4.6), 0.9)],
    }
    anchors = {"neck": (ch[0] - 1.5, ch[1] - 2.5), "H": H}
    return L, feats, anchors


def sit_pose(fr):
    """сидит к нам мордочкой, тело повёрнуто вправо; fr: 0 обычный, 1 моргнул, 4-5 жмурится"""
    H = (12.6, 8.6)
    s = 1.0
    L = []
    # хвост — знаком вопроса сбоку
    sway = 1.0 if fr in (1, 5) else 0.0
    tp = bez((25.0, 26.0), (31.5, 26.5), (34.5 + sway, 19.5), (31.0 + sway, 14.5))
    L.append(Layer("tail", lambda x, y: "tail", tube(tp, 2.2, 1.5)))
    haunch = ell((20.2, 22.4), 7.2, 6.6, -8)
    back = cap((15.0, 15.0), (21.0, 19.0), 4.6, 5.4)
    hpaw = ell((24.4, G - 1.1), 3.0, 1.2)

    def b_part(x, y):
        if y >= G - 2.0 and x > 21.5:
            return "paw"
        if y > 24.0:
            return "belly"
        return "body"
    L.append(Layer("haunch", b_part, lambda x, y: haunch(x, y) or back(x, y) or hpaw(x, y)))
    chest = ell((12.6, 18.4), 5.4, 6.2)
    neck = cap((12.6, 11.5), (12.6, 15.5), 4.6, 5.0)

    def c_part(x, y):
        return "chest" if (abs(x - 12.6) < 3.6 and y > 13.2) else "body"
    L.append(Layer("chest", c_part, lambda x, y: chest(x, y) or neck(x, y)))
    # передние лапы рядом, у земли — лапки
    for i, lx in enumerate((10.4, 14.9)):
        lg = cap((lx, 20.0), (lx - 0.1, G - 1.2), 1.9, 1.7)
        pw = ell((lx - 0.2, G - 1.0), 2.1, 1.1)
        L.append(Layer("fl%d" % i, (lambda x, y: "paw" if y >= G - 2.2 else "leg"),
                       (lambda lg=lg, pw=pw: (lambda x, y: lg(x, y) or pw(x, y)))()))
    cran = ell((H[0], H[1] - 0.1), 6.2 * s, 5.0 * s)
    cheek = ell((H[0], H[1] + 2.1), 7.1 * s, 3.4 * s)
    muz = ell((H[0], H[1] + 3.1), 2.6 * s, 1.7 * s)
    ear_l = tri((H[0] - 6.3, H[1] - 1.2), (H[0] - 1.2, H[1] - 4.6), (H[0] - 5.8, H[1] - 8.0))
    ear_r = tri((H[0] + 1.2, H[1] - 4.6), (H[0] + 6.3, H[1] - 1.2), (H[0] + 5.8, H[1] - 8.0))

    def h_part(x, y):
        if (ear_l(x, y) or ear_r(x, y)) and not cran(x, y):
            return "ear"
        if muz(x, y) or (y > H[1] + 2.4 and abs(x - H[0]) < 3.5):
            return "face"
        if y < H[1] - 2.0 and abs(x - H[0]) < 1.0:
            return "blaze"
        return "head"
    L.append(Layer("ears", lambda x, y: "ear", lambda x, y: ear_l(x, y) or ear_r(x, y), space="head"))
    L.append(Layer("head", h_part, lambda x, y: cran(x, y) or cheek(x, y) or muz(x, y), space="head"))
    feats = {
        "eyes_front": [(H[0] - 3.0, H[1] + 0.2), (H[0] + 3.0, H[1] + 0.2)],
        "nose_front": (H[0], H[1] + 2.6),
        "mouth_front": (H[0], H[1] + 3.8),
        "ear_pink": [(ear_l, (H[0] - 4.5, H[1] - 4.2), 1.5), (ear_r, (H[0] + 4.5, H[1] - 4.2), 1.5)],
        "eyes_state": "blink" if fr == 1 else ("happy" if fr in (4, 5) else "open"),
    }
    anchors = {"neck": (12.6, 14.0), "H": H}
    return L, feats, anchors


def nap_pose(fr):
    """спит клубком: голова на лапках слева, бёдра горбиком, хвост обвивает спереди"""
    br = 0.5 if fr == 3 else 0.0      # дышит
    H = (8.6, 20.6)
    L = []
    sh = ell((15.6, 24.6 - br * 0.5), 7.2, 4.4 + br * 0.5)
    hip = ell((25.6, 21.8 - br), 8.0, 7.2 + br, -12)

    def b_part(x, y):
        return "belly" if y > 26.0 else "body"
    L.append(Layer("body", b_part, lambda x, y: sh(x, y) or hip(x, y)))
    paws = ell((7.6, G - 1.3), 4.6, 1.6)
    L.append(Layer("paws", lambda x, y: "paw", paws))
    tp = bez((32.0, 25.0), (34.0, 30.5), (22.0, 30.0), (10.0, 28.4))
    L.append(Layer("tail", lambda x, y: "tail", tube(tp, 2.0, 1.6)))
    cran = ell(H, 5.5, 4.6)
    cheek = ell((H[0] - 0.2, H[1] + 1.7), 6.1, 3.0)
    muz = ell((H[0] - 1.0, H[1] + 2.5), 2.4, 1.6)
    ear_l = tri((H[0] - 5.6, H[1] - 1.2), (H[0] - 1.2, H[1] - 4.0), (H[0] - 5.4, H[1] - 7.4))
    ear_r = tri((H[0] + 1.2, H[1] - 4.2), (H[0] + 5.6, H[1] - 1.4), (H[0] + 4.8, H[1] - 7.2))

    def h_part(x, y):
        if (ear_l(x, y) or ear_r(x, y)) and not cran(x, y):
            return "ear"
        if muz(x, y) or y > H[1] + 2.2:
            return "face"
        if y < H[1] - 2.0 and abs(x - H[0]) < 1.0:
            return "blaze"
        return "head"
    L.append(Layer("ears", lambda x, y: "ear", lambda x, y: ear_l(x, y) or ear_r(x, y), space="head"))
    L.append(Layer("head", h_part, lambda x, y: cran(x, y) or cheek(x, y) or muz(x, y), space="head"))
    feats = {
        "eyes_front": [(H[0] - 2.6, H[1] + 0.4), (H[0] + 2.4, H[1] + 0.4)],
        "nose_front": (H[0] - 0.8, H[1] + 2.4),
        "mouth_front": None,
        "ear_pink": [(ear_l, (H[0] - 3.8, H[1] - 3.8), 1.1), (ear_r, (H[0] + 3.4, H[1] - 3.8), 1.1)],
        "eyes_state": "sleep",
    }
    anchors = {"neck": (11.0, 22.0), "H": H}
    return L, feats, anchors


# ------------------------------------------------------------------ рисование

class Space:
    """котёнок: тело сжато к земле, голова почти прежняя и сидит на шее"""

    def __init__(self, kit: bool, anchors: dict, pose: str):
        self.kit = kit
        if not kit:
            self.bx = self.by = self.hk = 1.0
            self.hoff = (0.0, 0.0)
            return
        self.bx = 0.62
        self.by = {"walk": 0.58, "sit": 0.56, "nap": 0.62}[pose]
        self.hk = {"walk": 1.08, "sit": 0.96, "nap": 0.98}[pose]
        nk = anchors["neck"]
        nk2 = self.to_out_body(nk)
        # голова держится на той же точке шеи
        self.hoff = (nk2[0] - nk[0] * self.hk, nk2[1] - nk[1] * self.hk)

    def to_out_body(self, p):
        return (CX + (p[0] - CX) * self.bx, G + (p[1] - G) * self.by)

    def body_src(self, x, y):
        return (CX + (x - CX) / self.bx, G + (y - G) / self.by)

    def head_src(self, x, y):
        return ((x - self.hoff[0]) / self.hk, (y - self.hoff[1]) / self.hk)

    def head_out(self, p):
        return (p[0] * self.hk + self.hoff[0], p[1] * self.hk + self.hoff[1])


def render(pose: str, fr: int, kit: bool):
    if pose == "walk":
        layers, feats, anchors = walk_pose(fr)
    elif pose == "sit":
        layers, feats, anchors = sit_pose(fr)
    else:
        layers, feats, anchors = nap_pose(fr)
    sp = Space(kit, anchors, pose)
    owner = {}        # (x,y) -> индекс слоя
    info = {}         # (x,y) -> (часть, sx, sy)
    for li, ly in enumerate(layers):
        for y in range(FH):
            for x in range(FW):
                px, py = x + 0.5, y + 0.5
                sx, sy = sp.head_src(px, py) if ly.space == "head" else sp.body_src(px, py)
                r = ly.inside(sx, sy)
                if not r and sp.kit and ly.name in ("far", "far2", "hind", "front", "fl0", "fl1"):
                    # у котёнка лапки толще (пухлые)
                    r = ly.inside(sx - 0.9, sy) or ly.inside(sx + 0.9, sy)
                if not r:
                    continue
                part = ly.part_fn(sx, sy)
                isy = int(round(sy))
                if ly.name == "tail":
                    isy = 100 + int(r[1] * 20)          # для колец на хвосте — номер вдоль хвоста
                owner[(x, y)] = li
                info[(x, y)] = (part, int(round(sx)), isy)
    # тени: по каждому слою отдельно, свет сверху-слева
    lev = {}
    for (x, y), li in owner.items():
        same = lambda q: owner.get(q) == li
        up = 0
        while same((x, y - up - 1)):
            up += 1
        dn = 0
        while same((x, y + dn + 1)):
            dn += 1
        t = up / max(1, up + dn)
        lf = 0
        while lf < 3 and same((x - lf - 1, y)):
            lf += 1
        lv = 6 if t < 0.12 else 5 if t < 0.32 else 4 if t < 0.62 else 3 if t < 0.84 else 2
        if lf == 0 and lv >= 4:
            lv -= 1          # край слева-сбоку чуть темнее, объём
        if lf == 1 and t < 0.3:
            lv = min(6, lv + 0)
        ly = layers[li]
        if ly.shade:
            lv = max(1, lv + ly.shade)
        if lv == 6 and ly.name not in ("head", "body", "haunch", "chest"):
            lv = 5
        lev[(x, y)] = lv
    # контур и стыки слоёв
    for (x, y), li in owner.items():
        nb = [(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)]
        if any(q not in owner for q in nb):
            lev[(x, y)] = 0 if (x, y + 1) not in owner else 1
        elif any(owner[q] < li for q in nb):
            # передняя часть на фоне задней — тонкая тёмная граница
            lev[(x, y)] = min(lev[(x, y)], 2)
        elif owner.get((x, y - 1), li) > li:
            # под передней частью (под подбородком, под лапой) — тень
            lev[(x, y)] = max(1, min(lev[(x, y)], 3))
    out = {}
    for q, li in owner.items():
        part, sx, sy = info[q]
        out[q] = (LV[lev[q]], part, sx, sy)
    _features(out, feats, sp, owner, layers)
    return out


def _put(out, x, y, c):
    if (x, y) in out:
        v = out[(x, y)]
        out[(x, y)] = (c,) + v[1:]


def _features(out, feats, sp, owner, layers):
    def hp(p):
        q = sp.head_out(p)
        return int(math.floor(q[0])), int(math.floor(q[1]))
    # розовое в ушах
    for (tri_f, c, r) in feats.get("ear_pink", []):
        for (x, y), v in list(out.items()):
            if v[1] != "ear":
                continue
            sx, sy = sp.head_src(x + 0.5, y + 0.5)
            d = math.hypot(sx - c[0], (sy - c[1]) * 0.7)
            if d < r and v[0] != LV[0] and v[0] != LV[1]:
                out[(x, y)] = (PINK if d < r * 0.55 else PINK_D,) + v[1:]
    st = feats.get("eyes_state", "open")
    if "eye_side" in feats:
        ex, ey = hp(feats["eye_side"])
        # глаз сбоку: миндалина 3x2, зрачок вертикальный, блик
        _put(out, ex - 1, ey, EYE[2]); _put(out, ex, ey, PUPIL); _put(out, ex + 1, ey, EYE[3])
        _put(out, ex - 1, ey + 1, EYE[1]); _put(out, ex, ey + 1, PUPIL); _put(out, ex + 1, ey + 1, EYE[0])
        _put(out, ex + 1, ey, SHINE if not sp.kit else EYE[4])
        _put(out, ex - 1, ey - 1, LV[1]); _put(out, ex, ey - 1, LV[1]); _put(out, ex + 1, ey - 1, LV[1])
        nx, ny = hp(feats["nose_side"])
        _put(out, nx, ny, NOSE)
        mx, my = hp(feats["mouth_side"])
        _put(out, mx, my, MOUTH)
    for i, e in enumerate(feats.get("eyes_front", [])):
        ex, ey = hp(e)
        if st == "open":
            _put(out, ex - 1, ey - 1, LV[1]); _put(out, ex, ey - 1, LV[1]); _put(out, ex + 1, ey - 1, LV[1])
            _put(out, ex - 1, ey, EYE[3]); _put(out, ex, ey, PUPIL); _put(out, ex + 1, ey, EYE[2])
            _put(out, ex - 1, ey + 1, EYE[1]); _put(out, ex, ey + 1, PUPIL); _put(out, ex + 1, ey + 1, EYE[0])
            _put(out, ex - 1 if i == 0 else ex - 1, ey, SHINE)
        elif st == "blink":
            _put(out, ex - 1, ey, LV[1]); _put(out, ex, ey, LV[1]); _put(out, ex + 1, ey, LV[1])
            _put(out, ex - 1, ey + 1, EYE[1]); _put(out, ex, ey + 1, PUPIL); _put(out, ex + 1, ey + 1, EYE[0])
        elif st == "happy":
            # жмурится: дужки ^ ^
            _put(out, ex - 1, ey + 1, LV[1]); _put(out, ex, ey, LV[1]); _put(out, ex + 1, ey + 1, LV[1])
        else:
            # спит: дужки вниз
            _put(out, ex - 1, ey, LV[1]); _put(out, ex, ey + 1, LV[1]); _put(out, ex + 1, ey, LV[1])
    if "nose_front" in feats:
        nx, ny = hp(feats["nose_front"])
        _put(out, nx, ny, NOSE)
        if sp.hk >= 0.95:
            _put(out, nx - 1, ny, PINK_D) if False else None
        if feats.get("mouth_front"):
            mx, my = hp(feats["mouth_front"])
            _put(out, mx - 1, my, MOUTH); _put(out, mx + 1, my, MOUTH)


def frames(kit: bool = False) -> dict:
    """все 10 кадров: {(кадр, x, y): (цвет, часть, sx, sy)}"""
    plan = [("sit", 0), ("sit", 1), ("nap", 2), ("nap", 3), ("sit", 4), ("sit", 5),
            ("walk", 0), ("walk", 1), ("walk", 2), ("walk", 3)]
    out = {}
    for f, (pose, fr) in enumerate(plan):
        for (x, y), v in render(pose, fr, kit).items():
            out[(f, x, y)] = v
    return out

"""Коты v26: перекраска чёрного кота (art/cat.png, 10 кадров 36x30) в разные окрасы и котята.

Котёнок делается из тех же кадров: тело и лапки уменьшаются, голова почти прежняя (крупнее
относительно тела). Потом котёнок перекрашивается так же, как взрослый.

Запуск:  python game/tools/cats26.py            -> game/art/cat26_<окрас>.png, cat26_kit_<окрас>.png
         python game/tools/cats26.py --preview  -> ещё и превью-листы в screenshots/
Старые файлы cat.png и cat_lost_*.png не меняются.
"""
import colorsys
import math
import sys
from pathlib import Path

from PIL import Image

GAME = Path(__file__).resolve().parents[1]
ART = GAME / "art"
SHOTS = GAME.parent / "screenshots"
SRC_FW = 36                      # ширина кадра в cat.png
FW, FH, NF = 42, 30, 10
PAD = 3                          # v26: пустая рамка вокруг каждого кадра, чтобы обводка/уши никогда не обрезались
OW, OH = FW + 2 * PAD, FH + 2 * PAD  # размер кадра в готовом листе
# v26: кадр шире на 6 px справа — хвосту есть куда отойти назад (кот на том же месте)
SIT, NAP, WALK = (0, 1, 4, 5), (2, 3), (6, 7, 8, 9)


# ------------------------------------------------------------------ части тела (в координатах кадра)

def part(f: int, x: int, y: int) -> str:
    """head / ear / face / blaze / chest / belly / leg / paw / tail / body"""
    if f in SIT:
        if y <= 12 and 3 <= x <= 23:
            if y <= 3 and (x <= 10 or x >= 17):
                return "ear"
            if 9 <= y and 9 <= x <= 17:
                return "face"
            if 4 <= y <= 8 and 12 <= x <= 14:
                return "blaze"
            return "head"
        if (x >= 26 and y <= 18) or (x >= 29 and y <= 22):
            return "tail"
        if 13 <= y <= 21 and 7 <= x <= 16:
            return "chest"
        if y >= 27:
            return "paw"
        if y >= 22 and x <= 18:
            return "leg"
        return "body"
    if f in NAP:
        if 2 <= x <= 16 and 11 <= y <= 24:
            if y <= 14:
                return "ear"
            if y >= 20 and 4 <= x <= 13:
                return "face"
            if 16 <= y <= 19 and 8 <= x <= 10:
                return "blaze"
            return "head"
        if y >= 26 or (y >= 25 and x >= 24):
            return "tail"
        if y >= 23 and x <= 18:
            return "paw"
        if y >= 22 and 12 <= x <= 22:
            return "belly"
        return "body"
    # WALK
    if (x <= 15 and y <= 12) or (x <= 9 and y <= 16):
        if y <= 6:
            return "ear"
        if x <= 8 and y >= 10:
            return "face"
        if 6 <= x <= 9 and 5 <= y <= 9:
            return "blaze"
        return "head"
    if x >= 27 and y <= 17:
        return "tail"
    if y >= 27:
        return "paw"
    if y >= 22:
        return "leg"
    if x <= 13 and y >= 12:
        return "chest"
    if y >= 19:
        return "belly"
    return "body"


NECK = {"sit": (13, 13), "nap": (12, 22), "walk": (10, 14)}
LEG_TOP = {"sit": 22, "nap": 26, "walk": 22}


def kind(f: int) -> str:
    return "sit" if f in SIT else ("nap" if f in NAP else "walk")


# ------------------------------------------------------------------ исходник как «карта»

def lum(c) -> float:
    return 0.3 * c[0] + 0.59 * c[1] + 0.11 * c[2]


def special(c) -> bool:
    """глаза, нос, розовое в ушах, блики глаз — не перекрашиваются"""
    r, g, b = c[:3]
    return (g > b + 20) or (r > b + 25) or (r > 240 and g > 240 and b > 240)


def level(c) -> int:
    v = lum(c)
    return 0 if v < 17 else 1 if v < 24 else 2 if v < 35 else 3 if v < 50 else 4 if v < 70 else 5 if v < 100 else 6


def load_src():
    im = Image.open(ART / "cat.png").convert("RGBA")
    px = {}
    for f in range(NF):
        for y in range(FH):
            for x in range(SRC_FW):
                c = im.getpixel((f * SRC_FW + x, y))
                if c[3] > 0:
                    # (цвет, часть тела, исходные x, y)
                    px[(f, x, y)] = (c, part(f, x, y), x, y)
    return px




# ------------------------------------------------------------------ форма тела (не овал)

BODYP = ("body", "belly")


def reshape(px: dict) -> dict:
    """Перестраивает верх силуэта тела по столбцам: у идущего кота прямая спина с лопатками и бёдрами,
    у спящего — спина выгнута горбиком к бёдрам, за головой ямка. Шерсть и тени столбца растягиваются."""
    out = dict(px)
    for f in WALK + NAP:
        cols = {}
        for (ff, x, y), v in px.items():
            if ff == f and v[1] in BODYP:
                t, b = cols.get(x, (99, -1))
                cols[x] = (min(t, y), max(b, y))
        xs = sorted(cols)
        n = len(xs)
        if n < 8:
            continue
        tops = [cols[x][0] for x in xs]
        mid = sorted(tops[n // 4: 3 * n // 4])
        L = mid[len(mid) // 2]
        lmin = min(tops)
        want = {}
        for i, x in enumerate(xs):
            t0 = cols[x][0]
            if f in WALK:
                edge = min(i, n - 1 - i)
                if edge >= 3:
                    t1 = L
                    if n - 7 <= i <= n - 4:      # бёдра чуть выше
                        t1 = L - 1
                    if 3 <= i <= 4:              # лопатки
                        t1 = L - 1
                    if i == 6 or i == 7:         # ложбинка за лопатками
                        t1 = L
                elif edge == 2:
                    t1 = min(t0, L + 1)
                else:
                    t1 = t0
            else:
                pk = int(n * 0.6)
                if i <= pk:
                    k = i / max(1, pk)
                    k = k * k * (3 - 2 * k)
                    t1 = round((lmin + 2) * (1 - k) + (lmin - 1) * k)
                else:
                    k = (i - pk) / max(1, n - 1 - pk)
                    t1 = max(round(lmin - 1 + k * k * (tops[-1] - lmin + 1)), min(t0, lmin - 1 + 1))
                    t1 = max(t1, lmin - 1)
            # не залезать на голову, хвост и прочее
            y = t1
            while y < t0 and (f, x, y) in px and px[(f, x, y)][1] not in BODYP:
                y += 1
            for yy in range(t1, t0):
                q = px.get((f, x, yy))
                if q is not None and q[1] not in BODYP:
                    y = max(y, yy + 1)
            want[x] = y
        for x in xs:
            t0, b0 = cols[x]
            t1 = want[x]
            if t1 == t0:
                continue
            for y in range(min(t0, t1), b0 + 1):
                q = out.get((f, x, y))
                if q is not None and q[1] in BODYP:
                    del out[(f, x, y)]
            for y in range(t1, b0 + 1):
                sy = t0 + round((y - t1) * (b0 - t0) / max(1, b0 - t1))
                q = px.get((f, x, sy))
                if q is not None and q[1] in BODYP and (f, x, y) not in out:
                    out[(f, x, y)] = q
    return out


# ------------------------------------------------------------------ хвост при ходьбе

def bend_tail(px: dict) -> dict:
    """В кадрах ходьбы хвост не торчит палкой вверх: от крупа уходит назад, потом плавно загибается кверху.
    Каждый пиксель хвоста поворачивается вокруг корня: у корня сильнее, к кончику слабее — выходит дуга."""
    out = dict(px)
    for f in WALK:
        tl = [(x, y) for (ff, x, y), v in px.items() if ff == f and v[1] == "tail"]
        if not tl:
            continue
        by = max(y for x, y in tl)
        bx = sum(x for x, y in tl if y >= by - 1) / max(1, len([1 for x, y in tl if y >= by - 1]))
        R0 = max(math.hypot(x - bx, y - by) for x, y in tl) + 1.0
        for (x, y) in tl:
            del out[(f, x, y)]

        def th(r):
            return math.radians(58.0 * (1.0 - 0.75 * min(1.0, r / R0)))

        for oy in range(0, FH - 6):
            for ox in range(int(bx) - 4, FW):
                dx, dy = ox - bx, oy - by
                r = math.hypot(dx, dy)
                if r > R0 + 1:
                    continue
                a = -th(r)
                sx = bx + dx * math.cos(a) - dy * math.sin(a)
                sy = by + dx * math.sin(a) + dy * math.cos(a)
                q = px.get((f, int(round(sx)), int(round(sy))))
                if q is None or q[1] != "tail":
                    continue
                cur = out.get((f, ox, oy))
                if cur is not None and cur[1] != "tail":
                    continue          # хвост позади тела
                out[(f, ox, oy)] = q
        # дырки внутри хвоста после поворота — заполнить соседом
        for _ in range(2):
            for oy in range(FH):
                for ox in range(int(bx) - 4, FW):
                    if (f, ox, oy) in out:
                        continue
                    nb = [out.get((f, ox + dx, oy + dy)) for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))]
                    tails = [v for v in nb if v is not None and v[1] == "tail"]
                    if len(tails) >= 3:
                        out[(f, ox, oy)] = max(tails, key=lambda v: lum(v[0]))
    return out


# ------------------------------------------------------------------ дырки

def fill_holes(px: dict) -> dict:
    """Прозрачные точки внутри силуэта (после уменьшения котёнка и поворота хвоста) заливаются шерстью соседей.
    Дырка — прозрачная точка, до которой нельзя дойти от края кадра, или щель в 1 px между тремя-четырьмя пикселями."""
    out = dict(px)
    for f in range(NF):
        for _ in range(3):
            solid = set((x, y) for (ff, x, y) in out if ff == f)
            # заливка снаружи
            seen = set()
            stack = [(x, y) for x in range(FW) for y in (0, FH - 1)] + [(x, y) for y in range(FH) for x in (0, FW - 1)]
            while stack:
                q = stack.pop()
                if q in seen or q in solid or not (0 <= q[0] < FW and 0 <= q[1] < FH):
                    continue
                seen.add(q)
                stack += [(q[0] + 1, q[1]), (q[0] - 1, q[1]), (q[0], q[1] + 1), (q[0], q[1] - 1)]
            changed = False
            for y in range(FH):
                for x in range(FW):
                    if (x, y) in solid:
                        continue
                    nb = [out.get((f, x + dx, y + dy)) for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))]
                    nb = [v for v in nb if v is not None and not special(v[0])]
                    enclosed = (x, y) not in seen
                    if (enclosed and nb) or (len(nb) >= 3 and y < FH - 1):
                        nb.sort(key=lambda v: lum(v[0]))
                        out[(f, x, y)] = nb[len(nb) // 2]
                        changed = True
            if not changed:
                break
    return out

# ------------------------------------------------------------------ пушистость

LV = {0: (12, 10, 22, 255), 1: (23, 19, 38, 255), 2: (33, 26, 48, 255), 3: (46, 39, 72, 255),
      4: (64, 55, 94, 255), 5: (88, 76, 122, 255), 6: (122, 110, 162, 255)}
FLOW = {"sit": (0, 1), "nap": (1, 1), "walk": (1, 1)}


def _spike_ok(f: int, p: str, d, y: int) -> float:
    """насколько охотно у края этой части растёт пучок шерсти (0 — нет)"""
    k = kind(f)
    dx, dy = d
    if p == "tail":
        return 0.45
    if p == "chest":
        return 0.6 if (dx < 0 or dy > 0) else 0.0
    if p == "belly":
        return 0.6 if dy > 0 else 0.25
    if p in ("head", "face"):
        # щёчки по бокам нижней половины головы
        lowy = {"sit": 7, "nap": 17, "walk": 9}[k]
        return 0.5 if (dx != 0 and y >= lowy) or (dy > 0 and p == "face") else 0.0
    if p == "body":
        if dy > 0:
            return 0.5
        if dy < 0:
            return 0.22
        return 0.3
    return 0.0


def fluff(px: dict, small: bool = False) -> dict:
    out = dict(px)
    for f in range(NF):
        k = kind(f)
        pts = [(x, y) for (ff, x, y) in px if ff == f]
        have = set(pts)
        add = {}
        for (x, y) in pts:
            c, p, sx, sy = px[(f, x, y)]
            if special(c):
                continue
            for d in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                q = (x + d[0], y + d[1])
                if q in have or q in add or not (0 <= q[0] < FW and 0 <= q[1] < FH - 1):
                    continue
                w = _spike_ok(f, p, d, y) * (0.6 if small else 1.0)
                hv = h2(q[0] + d[0] * 7, q[1] + d[1] * 5, 77)
                if w > 0 and hv < w * 0.62:
                    add[q] = (LV[2], p, sx, sy)
                    # длинный пучок
                    q2 = (q[0] + d[0], q[1] + d[1])
                    if not small and hv < w * 0.1 and p in ("chest", "belly") and q2 not in have and 0 <= q2[0] < FW and 0 <= q2[1] < FH - 1:
                        add[q2] = (LV[1], p, sx, sy)
                    # край под пучком — чуть темнее, пучок «растёт» из шерсти
                    if level(c) >= 4:
                        out[(f, x, y)] = (LV[3], p, sx, sy)
        for q, v in add.items():
            out[(f, q[0], q[1])] = v
        # пряди внутри: светлые штрихи на основном тоне, тёмные — в тени, по направлению шерсти
        fx, fy = FLOW[k]
        for (x, y) in pts:
            c, p, sx, sy = out[(f, x, y)]
            if special(c) or p in ("paw", "ear") or (p == "face" and k != "nap"):
                continue
            lv = level(c)
            hv = h2(x, y, 91)
            nxt = (f, x + fx, y + fy)
            if nxt not in out or special(out[nxt][0]):
                continue
            if lv == 4 and hv > 0.88:
                out[(f, x, y)] = (LV[5], p, sx, sy)
                if level(out[nxt][0]) == 4:
                    out[nxt] = (LV[5],) + out[nxt][1:]
            elif lv == 5 and hv > 0.92:
                out[(f, x, y)] = (LV[4], p, sx, sy)
            elif lv == 3 and hv > 0.88:
                out[(f, x, y)] = (LV[2], p, sx, sy)
    return out

# ------------------------------------------------------------------ котёнок

KIT_B = 0.64     # тело
KIT_L = 0.42     # лапки по высоте (короче)
KIT_H = 1.0      # голова как у взрослого: целиком, без среза ушей и щёк (котёнок — большая голова, маленькое тело)


HEADP = ("head", "ear", "face", "blaze")


def _keep_lines(lo: int, hi: int, protect: set, want: int) -> list:
    """какие строки/столбцы головы оставить: выкидываем только «пустую» шерсть, не трогая глаза и нос,
    и не крайние (там контур)"""
    allv = list(range(lo, hi + 1))
    drop_n = len(allv) - want
    cand = [v for v in allv[1:-1] if v not in protect]
    if drop_n <= 0 or not cand:
        return allv
    drop_n = min(drop_n, len(cand))
    drop = set(cand[int((i + 0.5) * len(cand) / drop_n)] for i in range(drop_n))
    return [v for v in allv if v not in drop]


def _head_map(src: dict, f: int):
    """голова котёнка без растягивания: те же пиксели лица, только без нескольких рядов шерсти"""
    hs = [(x, y) for (ff, x, y), v in src.items() if ff == f and v[1] in HEADP]
    xs = [p[0] for p in hs]
    ys = [p[1] for p in hs]
    feat = [(x, y) for (x, y) in hs if special(src[(f, x, y)][0]) and src[(f, x, y)][1] != "ear"
            or (level(src[(f, x, y)][0]) == 0 and any(special(src.get((f, x + dx, y), ((0, 0, 0, 0),))[0]) for dx in (-1, 1)))]
    pc = set()
    pr = set()
    for (x, y) in feat:
        for d in (-1, 0, 1):
            pc.add(x + d)
            pr.add(y + d)
    w = max(xs) - min(xs) + 1
    h = max(ys) - min(ys) + 1
    cols = _keep_lines(min(xs), max(xs), pc, round(w * KIT_H))
    rows = _keep_lines(min(ys), max(ys), pr, round(h * KIT_H))
    return cols, rows


def kitten(src: dict) -> dict:
    out = {}
    for f in range(NF):
        k = kind(f)
        lt = LEG_TOP[k]
        leg_h = 29 - lt

        def body_inv(ox, oy):
            d_out = 29 - oy
            lo = leg_h * KIT_L
            d = d_out / KIT_L if d_out <= lo else leg_h + (d_out - lo) / KIT_B
            return 18 + (ox - 18) / KIT_B, 29 - d

        def body_fwd(sx, sy):
            d = 29 - sy
            d_out = d * KIT_L if d <= leg_h else leg_h * KIT_L + (d - leg_h) * KIT_B
            return 18 + (sx - 18) * KIT_B, 29 - d_out

        ax, ay = NECK[k]
        nx, ny = body_fwd(ax, ay)
        ny -= 0.5
        if k == "walk":
            nx += 1.0
        cols, rows = _head_map(src, f)
        ia = min(range(len(cols)), key=lambda i: abs(cols[i] - ax))
        ja = min(range(len(rows)), key=lambda j: abs(rows[j] - ay))
        bx0, by0 = int(round(nx)) - ia, int(round(ny)) - ja
        for oy in range(FH):
            for ox in range(FW):
                got = None
                # голова сверху: пиксель в пиксель, только без выкинутых рядов
                i, j = ox - bx0, oy - by0
                if 0 <= i < len(cols) and 0 <= j < len(rows):
                    hp = src.get((f, cols[i], rows[j]))
                    if hp is not None and hp[1] in HEADP:
                        got = hp
                if got is None:
                    bx, by = body_inv(ox, oy)
                    bp = src.get((f, int(round(bx)), int(round(by))))
                    if bp is not None and bp[1] not in ("head", "ear", "face", "blaze"):
                        got = bp
                if got is not None:
                    out[(f, ox, oy)] = got
        # морда круглее: нижние углы головы срезаются ступеньками (1-2-3 px к подбородку), как нарисовал пользователь
        hp = [(x, y) for (ff, x, y), v in out.items() if ff == f and v[1] in HEADP]
        if hp:
            hx0 = min(x for x, y in hp)
            hx1 = max(x for x, y in hp)
            hy1 = max(y for x, y in hp)
            for (x, y) in hp:
                up = hy1 - y              # 0 — подбородок
                inset = {0: 4, 1: 3, 2: 2, 3: 1}.get(up, 0)
                if inset and (x < hx0 + inset or x > hx1 - inset) and not special(out[(f, x, y)][0]):
                    bx, by = body_inv(x, y)
                    bp = src.get((f, int(round(bx)), int(round(by))))
                    if bp is not None and bp[1] not in HEADP:
                        out[(f, x, y)] = bp
                    else:
                        del out[(f, x, y)]
        # контур: край силуэта и шея под головой темнее
        for (ff, x, y), v in list(out.items()):
            if ff != f:
                continue
            c = v[0]
            if special(c):
                continue
            edge = any((f, x + dx, y + dy) not in out for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))
            if edge and level(c) > 2:
                out[(f, x, y)] = ((33, 26, 48, 255),) + v[1:]
            elif v[1] in ("head", "face") and level(c) > 3:
                below = out.get((f, x, y + 1))
                if below is not None and below[1] not in ("head", "ear", "face", "blaze"):
                    out[(f, x, y)] = ((46, 39, 72, 255),) + v[1:]
    return out


def kit_nap_shape(px: dict) -> dict:
    """Спящий котёнок: после уменьшения тело было прямоугольным «кирпичиком». Здесь спина делается горбиком,
    круп сзади скругляется (как у взрослого), а «дыхание» — в кадре 3 горб поднимается на 1 px, форма та же."""
    out = dict(px)
    # общие столбцы тела для обоих кадров сна (справа от головы)
    info = {}
    for f in NAP:
        head_x = set(x for (ff, x, y), v in px.items() if ff == f and v[1] in HEADP)
        cols = {}
        for (ff, x, y), v in px.items():
            if ff == f and v[1] in BODYP and x not in head_x:
                t, b = cols.get(x, (99, -1))
                cols[x] = (min(t, y), max(b, y))
        info[f] = cols
    xs = sorted(set(info[NAP[0]]) & set(info[NAP[1]]))
    if len(xs) < 5:
        return out
    tops = sorted(info[f][x][0] for f in NAP for x in xs)
    L = tops[len(tops) // 2]
    bot = sorted(info[NAP[0]][x][1] for x in xs)[len(xs) // 2]
    n = len(xs)
    peak = L - 2                      # спина выше, на уровне щёк — тело продолжает голову, а не «коробка» сбоку
    for f in NAP:
        cols = info[f]
        breath = 1 if f == NAP[1] else 0
        for i, x in enumerate(xs):
            u = i / (n - 1)
            if u < 0.3:
                t1 = peak
            else:
                k = (u - 0.3) / 0.7
                t1 = peak + round((bot - 2 - peak) * k ** 2.2)
            if 0.1 <= u <= 0.7:
                t1 -= breath
            t0, b0 = cols[x]
            b1 = b0 - (1 if i == n - 1 else 0)      # круглый задок снизу
            if t1 >= b1:
                t1 = b1
            col = [px.get((f, x, y)) for y in range(t0, b0 + 1)]
            for y in range(min(t0, t1), b0 + 1):
                q = out.get((f, x, y))
                if q is not None and q[1] in BODYP:
                    del out[(f, x, y)]
            for y in range(t1, b1 + 1):
                if (f, x, y) in out:
                    continue
                sy = round((y - t1) * (len(col) - 1) / max(1, b1 - t1))
                q = col[sy]
                if q is None or q[1] not in BODYP:
                    q = next((c for c in col if c is not None and c[1] in BODYP), None)
                if q is not None:
                    out[(f, x, y)] = q
        # обрывки тела выше спины (лишний «выступ» в кадре вдоха) — убрать
        right = xs[0]
        for (ff, x, y), v in list(out.items()):
            if ff == f and x >= right and v[1] in BODYP and x not in xs:
                del out[(f, x, y)]
    return out


# ------------------------------------------------------------------ цвета

def hx(s: str):
    s = s.lstrip("#")
    return tuple(int(s[i:i + 2], 16) for i in (0, 2, 4))


def ramp(base: str, cool: float = 0.07, dark: float = 1.0):
    """7 тонов: контур, 3 тени, основной, свет, блик. Тени — смешение с холодным сливовым."""
    b = hx(base)
    l = lum(b) / 255.0
    deep = (24, 18, 36)
    # тени светлых котов светлее (белый кот не должен быть в чёрном контуре), у тёмных — глубже
    ts = [0.80, 0.62, 0.44, 0.24] if l < 0.45 else [0.66, 0.48, 0.32, 0.17]
    ts = [min(0.95, t * dark) if dark != 1.0 else t for t in ts]
    # оттенок тени: немного своего цвета, немного сиреневого
    tint = tuple(deep[i] * (1 - cool * 4) + (b[i] * 0.35) * cool * 4 for i in range(3))
    res = []
    for t in ts:
        res.append(tuple(round(b[i] * (1 - t) + tint[i] * t) for i in range(3)))
    res.append(b)
    warm = (255, 250, 236)
    for t in (0.28, 0.55):
        res.append(tuple(round(b[i] * (1 - t) + warm[i] * t) for i in range(3)))
    return res


R = {
    "black": None,  # родной
    "ginger": ramp("#e08a38"),
    "ginger_dk": ramp("#b8602a"),
    "white": ramp("#e8e8f0", cool=0.12),
    "gray": ramp("#8a909c"),
    "gray_dk": ramp("#5e6470"),
    "graybrown": ramp("#8e8274"),
    "brown_dk": ramp("#4e3a2c"),
    "smoke": ramp("#62646e"),
    "smoke_lt": ramp("#a8aab6"),
    "cream": ramp("#ecd2a4"),
    "cream_dk": ramp("#cfa877"),
    "choco": ramp("#6e4630"),
    "choco_lt": ramp("#90603e"),
    "tux": ramp("#33303f", dark=0.6),
    "blue": ramp("#7f8aa6"),
    "seal": ramp("#4a3226"),
    "siam": ramp("#eadfc8", cool=0.1),
    "tort_a": ramp("#3c302c", dark=0.6),
    "tort_b": ramp("#c87a3a"),
    "calico_o": ramp("#d98a3a"),
    "calico_k": ramp("#3e3438", dark=0.6),
    "gold": ramp("#e8b440"),
    "gold_dk": ramp("#b5802a"),
    "moon": ramp("#c8d4ec", cool=0.14),
    "moon_dk": ramp("#9aa8c8", cool=0.14),
    "lav": ramp("#b8a0dc"),
    "lav_dk": ramp("#8c70b8"),
    "night": ramp("#2e3a72", dark=0.7),
    "sakura": ramp("#f2c4d4"),
    "sakura_dk": ramp("#e08aa8"),
    "mint": ramp("#9ee0c8"),
    "rose": ramp("#f0a8c8"),
    "violet": ramp("#a890e8"),
}
# «фрак»: чёрное как у родного кота — ровное, без серых пятен
R["tux"] = [LV[k][:3] for k in range(7)]

EYES = {  # замена жёлто-зелёных глаз (5 тонов от тёмного к светлому)
    "green": None,
    "blue": [(40, 80, 150), (60, 120, 200), (90, 160, 232), (130, 196, 248), (200, 236, 255)],
    "amber": [(150, 90, 30), (196, 128, 40), (230, 168, 60), (246, 206, 100), (255, 240, 170)],
    "violet": [(90, 50, 140), (130, 80, 190), (170, 120, 230), (206, 170, 248), (240, 220, 255)],
    "copper": [(130, 60, 20), (180, 90, 30), (220, 128, 50), (240, 170, 90), (255, 220, 160)],
}
EYE_SRC = [(138, 160, 48), (168, 192, 64), (200, 220, 88), (212, 232, 112), (232, 244, 144)]


def h2(a: int, b: int, seed: int) -> float:
    n = (a * 374761393 + b * 668265263 + seed * 2246822519) & 0xFFFFFFFF
    n = ((n ^ (n >> 13)) * 1274126177) & 0xFFFFFFFF
    return ((n ^ (n >> 16)) & 0xFFFF) / 65535.0


def blob(x: int, y: int, seed: int, cell: int = 6, thr: float = 0.5) -> bool:
    """крупные пятна: шум по клеткам с мягкой границей"""
    gx, gy = x / cell, y / cell
    x0, y0 = math.floor(gx), math.floor(gy)
    fx, fy = gx - x0, gy - y0
    a = h2(x0, y0, seed)
    b = h2(x0 + 1, y0, seed)
    c = h2(x0, y0 + 1, seed)
    d = h2(x0 + 1, y0 + 1, seed)
    v = (a * (1 - fx) + b * fx) * (1 - fy) + (c * (1 - fx) + d * fx) * fy
    return v > thr


def stripe(f: int, p: str, x: int, y: int) -> bool:
    """полоски «табби»: кольца на лапах и хвосте, поперёк спины, буква М на лбу"""
    k = kind(f)
    if p == "blaze":
        return k != "nap" and (x + y) % 2 == 0
    if p in ("leg", "paw"):
        return y % 3 == 0
    if p == "tail":
        return ((x + y) // 2) % 2 == 0 if k == "sit" else ((y if k == "walk" else x) // 2) % 2 == 0
    if p in ("body", "chest", "belly"):
        if k == "walk":
            return ((x + y // 3) // 2) % 3 == 0
        if k == "nap":
            return ((x - y // 2) // 2) % 3 == 0
        return ((y + x // 4) // 2) % 3 == 0
    if p == "head":
        return k != "nap" and (y <= 5 and x % 3 == 0)
    return False


def is_white_bib(f: int, p: str, x: int, y: int, more: bool = False) -> bool:
    """белая манишка, носочки и подбородок (для «фрака» и двухцветных). Без белой «пасти» — иначе похож на волка"""
    k = kind(f)
    if p == "face":
        return y >= {"sit": 11, "nap": 22, "walk": 13}[k] and (k != "walk" or x <= 6)
    if p == "paw":
        return True
    if p == "chest":
        return y >= {"sit": 14, "nap": 0, "walk": 15}[k]
    if p == "belly":
        return k != "walk" or x <= 17
    if p == "blaze":
        return more and k == "sit" and x == 13
    return False


def is_white_calico(f: int, p: str, x: int, y: int, more: bool = False) -> bool:
    """у трёхцветной белого много: грудь, живот, лапы, мордочка"""
    if p in ("chest", "belly", "paw"):
        return True
    if p == "face":
        return True
    if p == "blaze":
        return more
    if more and p == "leg":
        return True
    return False


def siam_point(f: int, p: str, x: int, y: int) -> float:
    """0 — светлое тело, 1 — тёмная «маска» (уши, морда, лапы, хвост)"""
    if p in ("ear", "tail", "paw"):
        return 1.0
    if p == "face":
        return 0.85
    if p == "leg":
        return 0.6
    if p == "blaze":
        return 0.5
    return 0.0


# окрас: функция (кадр, часть, исходные x, y) -> имя палитры, плюс сдвиг уровня
def skin_fn(name: str):
    def solid(r):
        return lambda f, p, x, y: (r, 0)

    if name == "black":
        return None
    if name in ("ginger", "white", "gray", "cream", "choco", "blue", "smoke"):
        if name == "smoke":
            # дымчатый: тёмный сверху, светлеет к брюшку
            return lambda f, p, x, y: ("smoke_lt", 0) if p in ("chest", "belly", "paw") else ("smoke", 0)
        return solid({"cream": "cream", "choco": "choco", "blue": "blue"}.get(name, name))
    if name == "tabby_ginger":
        return lambda f, p, x, y: ("ginger_dk", -1) if stripe(f, p, x, y) else ("ginger", 0)
    if name == "tabby_gray":
        return lambda f, p, x, y: ("gray_dk", -1) if stripe(f, p, x, y) else ("gray", 0)
    if name == "tabby_brown":
        return lambda f, p, x, y: ("brown_dk", -1) if stripe(f, p, x, y) else ("graybrown", 0)
    if name == "cream_tabby":
        return lambda f, p, x, y: ("cream_dk", 0) if stripe(f, p, x, y) else ("cream", 0)
    if name == "tuxedo":
        return lambda f, p, x, y: ("white", 0) if is_white_bib(f, p, x, y) else ("tux", 0)
    if name == "gray_white":
        return lambda f, p, x, y: ("white", 0) if is_white_bib(f, p, x, y, True) else ("gray", 0)
    if name == "ginger_white":
        return lambda f, p, x, y: ("white", 0) if is_white_bib(f, p, x, y, True) else ("ginger", 0)
    if name == "siamese":
        def fn(f, p, x, y):
            v = siam_point(f, p, x, y)
            if v >= 0.8:
                return ("seal", 0)
            if v > 0.0:
                return ("seal", 1)
            return ("siam", 0)
        return fn
    if name == "calico":
        def fn(f, p, x, y):
            if is_white_calico(f, p, x, y, True):
                return ("white", 0)
            if blob(x + 50 * (f in NAP), y, 11, 5, 0.55):
                return ("calico_k", 0)
            if blob(x, y + 9, 23, 6, 0.42):
                return ("calico_o", 0)
            return ("white", 0)
        return fn
    if name == "tortie":
        return lambda f, p, x, y: ("tort_b", 0) if blob(x, y, 31, 4, 0.55) else ("tort_a", 0)
    # ---- редкие
    if name == "golden":
        return lambda f, p, x, y: ("gold_dk", 0) if stripe(f, p, x, y) and p != "blaze" else ("gold", 0)
    if name == "moonsilver":
        return lambda f, p, x, y: ("moon_dk", 0) if p in ("ear", "tail") and (x + y) % 3 == 0 else ("moon", 0)
    if name == "lavender":
        return lambda f, p, x, y: ("white", 0) if p == "paw" else (("lav_dk", 0) if stripe(f, p, x, y) else ("lav", 0))
    if name == "starry":
        return lambda f, p, x, y: ("night", 0)
    if name == "sakura":
        return lambda f, p, x, y: ("sakura_dk", 0) if blob(x, y, 7, 3, 0.68) or p == "ear" else ("sakura", 0)
    if name == "aurora":
        def fn(f, p, x, y):
            # переливается от головы к хвосту: мятный -> розовый -> сиреневый, с мягкой «ступенькой»
            t = 0.75 * x / 36.0 + 0.25 * y / 30.0
            band = t * 4.0
            i = int(band)
            fr = band - i
            cols = ["mint", "mint", "rose", "violet", "violet"]
            c0, c1 = cols[min(i, 4)], cols[min(i + 1, 4)]
            if c0 != c1 and fr > 0.5 and (x + y) % 2 == 0:
                return (c1, 0)
            return (c0 if fr < 0.75 else c1, 0)
        return fn
    raise KeyError(name)


# имя -> (глаза, особые блёстки)
SKINS = {
    "black": ("green", None), "ginger": ("green", None), "white": ("blue", None), "gray": ("amber", None),
    "calico": ("amber", None),
    "tabby_ginger": ("green", None), "tabby_gray": ("green", None), "tabby_brown": ("green", None),
    "cream": ("green", None), "cream_tabby": ("green", None), "choco": ("amber", None),
    "smoke": ("copper", None), "blue": ("green", None), "tuxedo": ("green", None),
    "gray_white": ("amber", None), "ginger_white": ("green", None),
    "siamese": ("blue", None), "tortie": ("green", None),
    "golden": ("green", "gold"), "moonsilver": ("blue", "moon"), "lavender": ("violet", None),
    "starry": ("amber", "stars"), "sakura": ("green", "petals"), "aurora": ("violet", "aurora"),
}
# эти уже есть как взрослые в старых cat_lost_*.png / cat.png — для них делаются только котята
OLD = ("black", "ginger", "white", "gray", "calico")


def recolor(px: dict, name: str) -> Image.Image:
    eyes, fx = SKINS[name]
    fn = skin_fn(name)
    img = Image.new("RGBA", (OW * NF, OH), (0, 0, 0, 0))
    # глаза: где они в каждом кадре — вокруг них тёмный ободок, внутри чёрный зрачок
    eye = set(k for k, v in px.items() if tuple(v[0][:3]) in EYE_SRC)
    def near_eye(f, x, y):
        return any((f, x + dx, y + dy) in eye for dx in (-1, 0, 1) for dy in (-1, 0, 1) if dx or dy)
    for (f, x, y), (c, p, sx, sy) in px.items():
        a = c[3]
        out = c
        if special(c):
            if eyes != "green" and tuple(c[:3]) in EYE_SRC:
                e = EYES[eyes][EYE_SRC.index(tuple(c[:3]))]
                out = (e[0], e[1], e[2], a)
        elif fn is not None:
            rn, sh = fn(f, p, sx, sy)
            lv = level(c)
            idx = max(0, min(6, lv + (sh if lv >= 2 else 0)))
            rr = R[rn][idx]
            out = (rr[0], rr[1], rr[2], a)
            if near_eye(f, x, y):
                # зрачок — почти чёрный; над глазом тёмное веко, по бокам лёгкая тень (иначе глаз тонет в шерсти)
                if lv <= 1:
                    out = (22, 14, 26, a)
                elif (f, x, y + 1) in eye:
                    d = R[rn][0] if lum(R[rn][4]) > 110 else R[rn][1]
                    out = (d[0], d[1], d[2], a)
                elif ((f, x - 1, y) in eye or (f, x + 1, y) in eye) and lum(R[rn][4]) > 110:
                    d = R[rn][2]
                    out = (d[0], d[1], d[2], a)
            # особые узоры редких
            if fx == "stars" and lv >= 3 and p in ("body", "tail", "head", "chest", "belly", "leg") and h2(sx * 3 + f, sy, 5) > 0.93:
                out = (255, 246, 200, a) if h2(sx, sy, 9) > 0.5 else (200, 220, 255, a)
            elif fx == "gold" and lv >= 5 and h2(sx, sy + f, 13) > 0.9:
                out = (255, 250, 220, a)
            elif fx == "moon" and p == "blaze" and lv >= 3:
                out = (240, 250, 255, a)
            elif fx == "petals" and p == "body" and lv >= 4 and h2(sx, sy, 17) > 0.9:
                out = (255, 236, 242, a)
        img.putpixel((f * OW + x + PAD, y + PAD), out)
    # в исходном cat.png кончики ушей упирались в край кадра без обводки — дорисовать её в отступе
    for f in range(NF):
        for x in range(FW):
            for (yy, dy) in ((0, -1), (FH - 1, 1)):
                X, Y = f * OW + x + PAD, yy + PAD
                c = img.getpixel((X, Y))
                if c[3] == 0 or img.getpixel((X, Y + dy))[3] != 0:
                    continue
                nb = [img.getpixel((X + d, Y)) for d in (-1, 1)] + [c]
                nb = [n for n in nb if n[3] > 0]
                dark = min(nb, key=lambda n: lum(n))
                if lum(dark) < lum(c) - 10 or lum(c) > 40:
                    img.putpixel((X, Y + dy), dark if lum(dark) < lum(c) - 10 else (33, 26, 48, 255))
        for y in range(FH):
            for (xx, dx) in ((0, -1), (FW - 1, 1)):
                X, Y = f * OW + xx + PAD, y + PAD
                c = img.getpixel((X, Y))
                if c[3] != 0 and img.getpixel((X + dx, Y))[3] == 0 and lum(c) > 40:
                    img.putpixel((X + dx, Y), (33, 26, 48, 255))
    return img


def main():
    raw = bend_tail(reshape(load_src()))
    src = fill_holes(fluff(fill_holes(raw)))
    kit = fill_holes(fluff(fill_holes(kit_nap_shape(kitten(raw))), small=True))
    made = []
    for name in SKINS:
        recolor(src, name).save(ART / f"cat26_{name}.png")
        made.append(f"cat26_{name}")
        recolor(kit, name).save(ART / f"cat26_kit_{name}.png")
        made.append(f"cat26_kit_{name}")
    print("готово:", len(made), "картинок")
    if "--preview" in sys.argv:
        preview()


def preview():
    """лист всех окрасов: слева взрослые, справа котята (кадры сидит/спит/идёт), прозрачный фон"""
    names = list(SKINS)
    frames = (0, 2, 6, 7)
    cw = OW * len(frames)
    sheet = Image.new("RGBA", (cw * 2 + 12, OH * len(names)), (0, 0, 0, 0))
    for i, n in enumerate(names):
        adult = Image.open(ART / f"cat26_{n}.png")
        kid = Image.open(ART / f"cat26_kit_{n}.png")
        for j, fr in enumerate(frames):
            sheet.alpha_composite(adult.crop((fr * OW, 0, fr * OW + OW, OH)).convert("RGBA"), (j * OW, i * OH))
            sheet.alpha_composite(kid.crop((fr * OW, 0, fr * OW + OW, OH)).convert("RGBA"), (cw + 12 + j * OW, i * OH))
    SHOTS.mkdir(exist_ok=True)
    sheet.save(SHOTS / "cats26_preview.png")
    sheet.resize((sheet.width * 4, sheet.height * 4), Image.NEAREST).save(SHOTS / "cats26_preview_x4.png")
    print("превью:", SHOTS / "cats26_preview_x4.png")


if __name__ == "__main__":
    main()

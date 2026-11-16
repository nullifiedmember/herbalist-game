# Героиня-травница, чиби v6 (стройнее) — пропорции сняты с чиби-спрайта из референса (39x46: голова = 1/2 роста,
# тело 6, юбка 5, ножки 5, обувь 4 ряда), пиксели свои, крупность x2 (78x94).
# Обводка: тёмная 1px только снаружи, внутри — цветные линии.
# Запуск: python -I hero_chibi6.py -> herbalist_game/art_apple/hero_chibi/hero_chibi6*.png
import os
from PIL import Image

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "art_apple", "hero_chibi")
K = 2
W, H = 39 * K, 47 * K
CX = 19.5

def hx(c):
    return tuple(int(c[i:i + 2], 16) for i in (1, 3, 5))

OUTLINE = hx("#2e1a28")
PAL = {
    "hair":  ("#e8c794", "#fbe8c4", "#d2a674", "#a8704e"),
    "hairB": ("#d6ad7a", "#e8c794", "#bf8f62", "#93603f"),
    "skin":  ("#fdeee4", "#fff8f2", "#f4d2c4", "#dca092"),
    "white": ("#fdfaf6", "#ffffff", "#e4dade", "#b8a8b4"),
    "teal":  ("#5cc4b4", "#a8ecdc", "#3a9a92", "#23706e"),
    "belt":  ("#7c4a36", "#a06a4c", "#5e3528", "#46261e"),
    "boot":  ("#94603e", "#c08a5e", "#704428", "#52301e"),
    "bun":   ("#ddb684", "#f2d8aa", "#c6976a", "#a06a48"),
    "pouch": ("#b48a56", "#d6ae78", "#8e6a40", "#6a4a2c"),
}
EXTRA = {"D": "#a8704e", "H": "#fff4da", "p": "#f498a4", "q": "#fac4c4", "m": "#d05c66",
         "e": "#2c1426", "0": "#4e2034", "1": "#74304a", "2": "#a24c5a", "3": "#d27a72", "4": "#f6bc98",
         "x": "#ffffff", "k": "#f2cc64", "K": "#c89a40", "L": "#6fb64e", "l": "#a6dc72", "G": "#3f8a3a",
         "f": "#ffffff", "F": "#e8e0d8"}

reg, col, grp, order = {}, {}, {}, []


def mir(pts):
    return [(2 * CX - x, y) for x, y in pts]


def poly_in(pts, u, v):
    inside = False
    j = len(pts) - 1
    for i in range(len(pts)):
        xi, yi = pts[i]; xj, yj = pts[j]
        if (yi > v) != (yj > v) and u < (xj - xi) * (v - yi) / (yj - yi + 1e-9) + xi:
            inside = not inside
        j = i
    return inside


def P(pts):
    return lambda u, v: poly_in(pts, u, v)


def N(pts, f):
    return [(CX + (x - CX) * f, y) for x, y in pts]


def Psym(left):
    return P(left + mir(left[::-1]))


def E(cx, cy, rx, ry, p=2.0):
    return lambda u, v: abs((u - cx) / rx) ** p + abs((v - cy) / ry) ** p <= 1


def R(x0, y0, x1, y1):
    return lambda u, v: x0 <= u < x1 and y0 <= v < y1


def U(*fs):
    return lambda u, v: any(f(u, v) for f in fs)


def fill(name, f, pal):
    order.append(name)
    for Y in range(H):
        for X in range(W):
            u = (X + 0.5) / K; v = (Y + 0.5) / K
            if f(u, v):
                reg[(X, Y)] = name; grp[(X, Y)] = pal; col[(X, Y)] = hx(PAL[pal][0])


def pix(u, v):
    return int(u * K), int(v * K)


def put(X, Y, c, name=None):
    if 0 <= X < W and 0 <= Y < H:
        col[(X, Y)] = hx(EXTRA.get(c, c)) if isinstance(c, str) else c
        if name:
            reg[(X, Y)] = name


def line(pts, c, only=None):
    for (u0, v0), (u1, v1) in zip(pts, pts[1:]):
        X0, Y0 = pix(u0, v0); X1, Y1 = pix(u1, v1)
        n = max(abs(X1 - X0), abs(Y1 - Y0), 1)
        for i in range(n + 1):
            X = round(X0 + (X1 - X0) * i / n); Y = round(Y0 + (Y1 - Y0) * i / n)
            if only is None or reg.get((X, Y)) in only:
                put(X, Y, c)


# ================= фигуры по меркам спрайта (сзади вперёд) =================
# волосы сзади: у лица ровно, ниже плеч расходятся на всю ширину, волнистые концы
fill("hairB", Psym(N([(19.5, 14), (6.6, 15), (6.4, 21), (7.2, 24.5), (6.4, 27), (4.4, 29), (2.4, 30.6),
                    (2.0, 32.2), (3.4, 32.6), (2.8, 34.0), (5.0, 34.4), (6.4, 35.2), (8.0, 33.8),
                    (10.0, 34.6), (11.4, 33.2), (19.5, 33.2)], 0.82)), "hairB")
fill("legL", R(16.9, 35.0, 18.7, 41.0), "skin"); fill("legR", R(20.3, 35.0, 22.1, 41.0), "skin")
fill("bootL", U(R(16.2, 40.8, 19.2, 44.0), E(17.7, 43.9, 1.5, 0.7)), "boot")
fill("bootR", U(R(19.8, 40.8, 22.8, 44.0), E(21.3, 43.9, 1.5, 0.7)), "boot")
fill("skirt", Psym(N([(19.5, 30.2), (15.2, 30.2), (13.4, 31.8), (12.0, 33.8), (11.6, 35.0), (19.5, 35.0)], 0.72)), "white")
fill("lace", Psym(N([(19.5, 34.8), (11.6, 34.8), (11.4, 35.8), (12.2, 36.4), (19.5, 36.4)], 0.72)), "white")
SLV = N([(14.6, 25.8), (13.4, 26.4), (12.6, 28.0), (11.8, 30.4), (12.4, 31.2), (13.6, 31.0), (14.6, 29.4)], 0.8)
fill("sleeveL", P(SLV), "white"); fill("sleeveR", P(mir(SLV)), "white")
fill("handL", E(14.6, 31.7, 0.8, 0.8), "skin"); fill("handR", E(24.4, 31.7, 0.8, 0.8), "skin")
fill("blouse", R(16.6, 24.6, 22.4, 30.4), "white")
fill("belt", R(16.6, 29.6, 22.4, 30.5), "belt")
fill("pouch", E(22.6, 31.4, 1.0, 1.2), "pouch")
CAPE = [(17.4, 24.4), (14.4, 24.3), (13.2, 25.4), (12.2, 27.0), (11.9, 28.6), (12.8, 29.3), (13.6, 28.7),
        (14.4, 29.4), (15.2, 28.8), (16.0, 29.1), (16.8, 27.6), (17.4, 26.2)]
CAPE = N(CAPE, 0.74)
fill("capeL", P(CAPE), "teal"); fill("capeR", P(mir(CAPE)), "teal")
fill("bun", E(19.5, 4.6, 2.6, 2.0), "bun")
fill("hair", E(19.5, 14.6, 12.2, 10.0, 2.3), "hair")
fill("face", Psym([(19.5, 14.5), (12.0, 14.5), (12.0, 22.2), (12.5, 23.3), (13.6, 24.0), (15.4, 24.5), (19.5, 24.6)]), "skin")
BANG = [(12.2, 19.2), (13.6, 18.7), (15.0, 19.6), (16.1, 18.8), (17.5, 20.8), (18.4, 19.4), (19.6, 18.8),
        (20.7, 20.4), (21.5, 19.2), (22.6, 18.7), (24.0, 19.6), (25.2, 18.6), (26.9, 19.2)]
fill("bang", P([(10, 10), (29, 10), (29, 19.4)] + BANG[::-1] + [(10, 19.4)]), "hair")
LOCK = [(9.6, 14.5), (12.8, 14.5), (13.0, 19.5), (12.8, 22.5), (12.4, 24.6), (12.0, 26.4), (11.4, 28.2),
        (10.6, 28.6), (10.2, 27.0), (9.7, 25.0), (9.3, 22.0), (9.2, 18.0)]
LOCK = N(LOCK, 0.94)
fill("lockL", P(LOCK), "hair"); fill("lockR", P(mir(LOCK)), "hair")
fill("bow", U(P([(19.5, 25.3), (17.4, 24.3), (17.2, 26.4)]), P([(19.5, 25.3), (21.6, 24.3), (21.8, 26.4)]),
              E(19.5, 25.4, 0.8, 0.7), P([(19.2, 25.6), (18.3, 27.4), (18.9, 27.6), (19.5, 26.2)]),
              P([(19.8, 25.6), (20.7, 27.4), (20.1, 27.6), (19.5, 26.2)])), "teal")

HAIRS = ("hair", "bang", "lockL", "lockR", "hairB", "bun")


def same(a, b):
    return ("H" if a in HAIRS else a) == ("H" if b in HAIRS else b)


# ---------------- плоские тени: свет сверху-слева ----------------
for (X, Y), r in list(reg.items()):
    pal = PAL[grp[(X, Y)]]
    n = lambda dx, dy: reg.get((X + dx, Y + dy))
    if any(q is None or not same(q, r) for q in (n(1, 0), n(0, 1))):
        col[(X, Y)] = hx(pal[2])
    elif r != "face" and any(q is None or not same(q, r) for q in (n(2, 0), n(0, 2), n(1, 1))):
        col[(X, Y)] = hx(pal[2])
    elif any(q is None or not same(q, r) for q in (n(-1, 0), n(0, -1))):
        col[(X, Y)] = hx(pal[1])
# низ волос у лица темнее
for (X, Y), r in list(reg.items()):
    v = (Y + 0.5) / K
    if r in ("hair", "lockL", "lockR") and v > 22 and col[(X, Y)] == hx(PAL["hair"][0]):
        if v > 24.5 or (X + Y) % 2 == 0:
            col[(X, Y)] = hx(PAL["hair"][2])
# внутренние линии — цветные (тёмный тон передней области)
z = {name: i for i, name in enumerate(order)}
for (X, Y), r in list(reg.items()):
    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        q = reg.get((X + dx, Y + dy))
        if q and z[q] < z[r] and not same(q, r):
            col[(X, Y)] = hx(PAL[grp[(X, Y)]][3])
            break

# ---------------- волосы: пряди, блики ----------------
HR = ("hair", "bang", "lockL", "lockR")
for pts in ([(22, 6.4), (19.8, 10), (17.6, 14.4), (16.8, 18.6)], [(25.4, 7.6), (23.4, 11.6), (21.8, 16), (21.3, 19)],
            [(17, 6.8), (14.8, 10.4), (13.4, 14.6), (13.0, 18.6)], [(28, 9.6), (26.6, 13.4), (26.0, 18.4)],
            [(12.4, 8.6), (10.6, 13), (10.0, 18), (10.2, 25)], [(29.4, 11.4), (29.0, 17), (28.8, 25)],
            [(20.2, 11), (19.4, 14.4), (18.8, 18.4)], [(8.4, 13), (7.4, 18)], [(30.8, 13), (31.6, 18)],
            [(24.2, 13), (24.0, 18.2)]):
    line(pts, "D", HR)
for pts in ([(22.4, 6.8), (20.2, 10)], [(25.6, 8), (23.8, 11.2)], [(17.4, 7.2), (15.4, 10.2)],
            [(12.0, 9.6), (10.8, 12.6)], [(9.4, 19), (9.6, 25)], [(29.8, 18.6), (30.0, 24.6)]):
    line([(a + 0.5, b) for a, b in pts], "H", HR)
for (a, b, c2) in ((10.8, 8.4, 12.4), (13.6, 7.0, 15.6), (16.6, 6.2, 18.2), (23.2, 6.6, 25.0), (26.2, 7.8, 27.6)):
    line([(a, b), (c2, b - 0.4)], "H", HR + ("bun",))
for pts in ([(6.8, 25), (6.2, 29)], [(32.2, 25), (32.8, 29)], [(3.8, 30.6), (5.2, 33.6)], [(35.2, 30.6), (33.8, 33.6)],
            [(8.8, 31), (9.4, 33.6)], [(30.2, 31), (29.6, 33.6)], [(5.6, 28.6), (7.0, 32.6)], [(33.4, 28.6), (32.0, 32.6)]):
    pts = N(pts, 0.82)
    line(pts, hx(PAL["hairB"][3]), ("hairB",))
# хохолок над пучком
for (u, v) in ((20.2, 2.8), (20.8, 2.0), (21.6, 1.4), (22.6, 1.2), (23.4, 1.6), (23.8, 2.2)):
    X, Y = pix(u, v); put(X, Y, hx(PAL["hair"][2]), "ahoge"); grp[(X, Y)] = "hair"
# ленточка на пучке
Y = pix(0, 5.9)[1]
for i, X in enumerate(range(pix(16.8, 0)[0], pix(22.4, 0)[0])):
    put(X, Y, "#5cc4b4" if i % 3 else "#a8ecdc"); put(X, Y + 1, "#3a9a92")
for (u, v) in ((16.3, 5.4), (15.9, 6.1), (22.8, 5.4), (23.2, 6.1)):
    X, Y = pix(u, v); put(X, Y, "#5cc4b4", "bow2"); grp[(X, Y)] = "teal"
# ромашка-заколка слева
FL = ["..ff.ff..",
      ".fffffff.",
      "ffffkffff",
      ".ffkkKff.",
      "ffffKffFF",
      ".fffFFFF.",
      "..fF.FF..",
      "LL.....lL",
      ".GL...LG."]
fx, fy = pix(11.4, 11.2)
for j, row in enumerate(FL):
    for i, ch in enumerate(row):
        if ch != ".":
            put(fx + i - 4, fy + j - 4, ch, "flower"); grp[(fx + i - 4, fy + j - 4)] = "white"

# ---------------- лицо ----------------
for (X, Y), r in list(reg.items()):
    if r == "face" and reg.get((X, Y - 1)) == "bang":
        put(X, Y, hx(PAL["skin"][2]))
EYE = [".eeeeeee.",
       "eeeeeeeee",
       "0x0000000",
       "0xx000010",
       "1x1100111",
       "222222x22",
       "333333333",
       ".4444444."]
for side, ex in ((-1, 12.9), (1, 21.6)):
    X0, Y0 = pix(ex, 19.2)
    for j, row in enumerate(EYE):
        for i, ch in enumerate(row):
            if ch != ".":
                put(X0 + i, Y0 + j, ch, "eye")
    ox = X0 - 1 if side < 0 else X0 + 9
    sx = -1 if side < 0 else 1
    for (a, b) in ((0, 0), (0, 1), (sx, -1), (sx, 0)):
        put(ox + a, Y0 + b, "e")
    for i in range(2, 7):
        put(X0 + i, Y0 + 8, hx(PAL["skin"][2]))
for ex in (12.6, 21.6):
    X0, Y0 = pix(ex, 23.2)
    for i in range(10):
        put(X0 + i, Y0, "q" if i % 2 else "p")
X, Y = pix(19.4, 22.6); put(X, Y, hx(PAL["skin"][3]))
X, Y = pix(19.0, 23.7); put(X, Y, "m"); put(X + 1, Y, "m")

# ---------------- одежда ----------------
for i, X in enumerate(range(pix(17.0, 0)[0], pix(22.0, 0)[0])):
    put(X, pix(0, 26.6)[1], "#ffffff" if i % 2 else hx(PAL["white"][2]))
for v in (27.6, 28.5):
    X, Y = pix(19.5, v); put(X, Y, "#3a9a92"); put(X - 1, Y, "#5cc4b4")
X, Y = pix(19.0, 29.6)
for dx in range(3):
    put(X + dx, Y, "k"); put(X + dx, Y + 1, "K")
put(X + 1, Y, "#7c4a36")
for u in (16.0, 17.8, 19.5, 21.2, 23.0):
    line([(u + (u - 19.5) * 0.02, 31.4), (u + (u - 19.5) * 0.16, 34.6)], hx(PAL["white"][2]), ("skirt",))
X0, _ = pix(13, 0); X1, _ = pix(26, 0); Y = pix(0, 35.2)[1]
for i, X in enumerate(range(X0, X1)):
    if reg.get((X, Y)) == "lace":
        put(X, Y, "#5cc4b4" if i % 3 == 1 else "#ffffff")
        put(X, Y + 1, "#a8ecdc" if i % 3 != 1 else "#ffffff")
for nm in ("sleeveL", "sleeveR"):
    for (X, Y), r in list(reg.items()):
        if r == nm and reg.get((X, Y + 1)) != nm:
            put(X, Y, "#3a9a92"); put(X, Y - 1, "#5cc4b4")
for nm in ("capeL", "capeR"):
    for (X, Y), r in list(reg.items()):
        if r == nm and reg.get((X, Y + 1)) != nm and reg.get((X, Y - 1)) == nm:
            put(X, Y - 1, "#a8ecdc")
X, Y = pix(22.6, 29.9)
for dx, dy, c in ((-1, 0, "L"), (0, -1, "l"), (1, 0, "G"), (0, 0, "L"), (2, -1, "l")):
    put(X + dx, Y + dy, c)
for dx in range(-2, 3):
    put(X + dx, Y + 2, "#6a4a2c")
for nm in ("legL", "legR"):
    for (X, Y), r in list(reg.items()):
        if r == nm:
            v = (Y + 0.5) / K
            if v >= 37.4:
                c = "#5cc4b4" if 38.4 <= v < 39.4 else "#fdfaf6"
                if reg.get((X + 1, Y)) != nm:
                    c = "#3a9a92" if c == "#5cc4b4" else "#e4dade"
                put(X, Y, c)
for nm, cu in (("bootL", 17.7), ("bootR", 21.3)):
    X, Y = pix(cu, 41.2)
    put(X - 1, Y + 1, "k"); put(X, Y + 2, "k"); put(X - 1, Y + 3, "k")
    for (Xp, Yp), r in list(reg.items()):
        if r == nm and reg.get((Xp, Yp + 1)) != nm:
            put(Xp, Yp, hx(PAL["boot"][3]))

# ---------------- внешний контур 1px ----------------
filled = set(col)
outline = {(X, Y) for Y in range(H) for X in range(W) if (X, Y) not in filled and
           any((X + dx, Y + dy) in filled for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))}


def render(blink=False):
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    for (X, Y), c in col.items():
        im.putpixel((X, Y), c + (255,))
    for (X, Y) in outline:
        im.putpixel((X, Y), OUTLINE + (255,))
    if blink:
        sk = hx(PAL["skin"][0]); e = hx(EXTRA["e"])
        for ex in (12.9, 21.6):
            X0, Y0 = pix(ex, 19.2)
            for j in range(-1, 9):
                for i in range(-2, 11):
                    if reg.get((X0 + i, Y0 + j)) in ("eye", "face"):
                        im.putpixel((X0 + i, Y0 + j), sk + (255,))
            for i in range(9):
                im.putpixel((X0 + i, Y0 + 5 - (1 if i in (0, 8) else 0)), e + (255,))
    return im


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    a = render()
    a.save(os.path.join(OUT, "hero_chibi6.png"))
    a.resize((W * 6, H * 6), Image.NEAREST).save(os.path.join(OUT, "hero_chibi6_x6.png"))
    render(True).save(os.path.join(OUT, "hero_chibi6_blink.png"))
    print("ok", W, H, os.path.abspath(OUT))
